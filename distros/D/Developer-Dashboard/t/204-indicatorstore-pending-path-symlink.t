use strict;
use warnings;
use utf8;

use File::Spec;
use File::Temp qw(tempdir);
use Test::More;

use lib 'lib';

use Developer::Dashboard::IndicatorStore;
use Developer::Dashboard::PathRegistry;

# DD-989: IndicatorStore::set_indicator used to build its staging path from
# the bare literal "$file.pending" with no uniquifier at all, and secured
# permissions only AFTER writing. That combination let a local actor who can
# pre-plant a symlink at the exact, fully predictable staging path clobber an
# arbitrary victim file the dashboard process can write to: open('>:raw',
# $symlink) follows the symlink and overwrites the target, and the
# subsequent rename then moves the symlink itself on top of the real
# status.json. This test pins the fix: the historical predictable path must
# never be written through, whatever is planted there in advance.

local $ENV{HOME} = tempdir( CLEANUP => 1 );
chdir $ENV{HOME} or die "Unable to chdir to $ENV{HOME}: $!";

my $paths = Developer::Dashboard::PathRegistry->new;
my $store = Developer::Dashboard::IndicatorStore->new( paths => $paths );

# ---------------------------------------------------------------------------
# AC-3 / BDD: pre-plant a symlink at the OLD predictable staging path
# ("<indicator_dir>/status.json.pending") pointing at a victim file, then
# call set_indicator. The victim file must be left untouched and the real
# status.json must end up as a REGULAR file with the correct content, not a
# symlink pointing at the victim.
# ---------------------------------------------------------------------------
{
    my $dir  = $paths->indicator_dir('demo');
    my $file = File::Spec->catfile( $dir, 'status.json' );
    my $historical_predictable_pending = "$file.pending";

    my $victim_dir = tempdir( CLEANUP => 1 );
    my $victim = File::Spec->catfile( $victim_dir, 'victim.txt' );
    open my $vfh, '>', $victim or die "Unable to seed $victim: $!";
    print {$vfh} "ORIGINAL VICTIM CONTENT\n";
    close $vfh or die "Unable to close $victim: $!";

    ok(
        symlink( $victim, $historical_predictable_pending ),
        "planted a symlink at the historical predictable staging path $historical_predictable_pending"
    );
    ok( -l $historical_predictable_pending, 'the planted path is really a symlink before the call' );

    $store->set_indicator(
        'demo',
        status => 'ok',
        label  => 'Demo',
    );

    open my $rfh, '<', $victim or die "Unable to reread $victim: $!";
    local $/;
    my $victim_content = <$rfh>;
    close $rfh;

    is(
        $victim_content, "ORIGINAL VICTIM CONTENT\n",
        'the victim file content is untouched by set_indicator'
    );

    ok( -e $file, 'the real status.json now exists' );
    ok( !-l $file, 'the real status.json is a regular file, not a symlink' );

    my $saved = $store->get_indicator('demo');
    is( $saved->{status}, 'ok',    'the indicator was actually saved' );
    is( $saved->{label},  'Demo',  'the indicator label was saved correctly' );

    # The planted symlink at the historical path is untouched by the fixed
    # writer - it never had any reason to look at that path at all.
    ok( -l $historical_predictable_pending, 'the planted symlink at the old predictable path still exists, unused' );
}

# ---------------------------------------------------------------------------
# AC-1: the staging path the fixed writer actually uses is never the bare
# literal "$file.pending" - it must vary per call (pid+time+counter, DD-850
# pattern), which is what makes it unpredictable and therefore un-plantable
# in advance.
# ---------------------------------------------------------------------------
{
    my @seen;
    {
        no strict 'refs';
        no warnings 'redefine';
        my $orig = \&Developer::Dashboard::PathRegistry::atomic_write_secure;
        local *Developer::Dashboard::PathRegistry::atomic_write_secure = sub {
            my ( $self, $tmp, $file, @rest ) = @_;
            push @seen, $tmp;
            return $self->$orig( $tmp, $file, @rest );
        };
        $store->set_indicator( 'seq-a', status => 'ok' );
        $store->set_indicator( 'seq-b', status => 'ok' );
    }

    is( scalar(@seen), 2, 'atomic_write_secure was called once per set_indicator call' );
    for my $tmp (@seen) {
        unlike( $tmp, qr/status\.json\.pending\z/, 'staging path is not the bare literal "$file.pending"' );
        like( $tmp, qr/\.pending\z/, 'staging path still ends in .pending' );
        like( $tmp, qr/\.\d+\.\d+(?:\.\d+)?\.pending\z/, 'staging path carries a numeric uniquifier suffix before .pending' );
    }
    isnt( $seen[0], $seen[1], 'two calls from the same process produce two different staging paths' );
}

done_testing;

__END__

=head1 NAME

204-indicatorstore-pending-path-symlink.t - regression guard for the DD-989 symlink-clobber fix

=head1 DESCRIPTION

Pins the DD-989 fix for C<Developer::Dashboard::IndicatorStore::set_indicator>:
its staging path must be unpredictable (never the bare literal
C<"$file.pending">) and must be secured via
C<Developer::Dashboard::PathRegistry::atomic_write_secure> before the rename,
so a symlink pre-planted at the historical predictable path cannot be used
to clobber an arbitrary victim file.

=for comment FULL-POD-DOC START

=head1 PURPOSE

This test is the executable contract for the DD-989 fix. It proves two
things: first, that pre-planting a symlink at the old, fully predictable
staging path no longer lets an attacker corrupt an unrelated file through
C<set_indicator>; second, that the staging path the fixed writer actually
uses is per-call unique, not a fixed literal, which is what makes the attack
unplantable in the first place.

=head1 WHY IT EXISTS

It exists because C<set_indicator> previously built its staging path from
the bare literal C<"$file.pending"> with no pid/time/counter uniquifier at
all - a strictly worse case than the DD-599/600/601/602/848/850 defect
class this project has already fixed six other times, and one that was
missed by both of those sweeps because neither searched for a pending-file
writer with no uniquifier whatsoever. A live reproduction (recorded on
DD-989) confirmed a pre-planted symlink at that path let the indicator
writer overwrite an arbitrary victim file's content and leave the real
status.json pointing at the victim afterward.

=head1 WHEN TO USE

Use this file when changing C<IndicatorStore::set_indicator>, its staging
path helper, or any other stage-then-rename writer in this codebase, and
whenever a focused failure points here.

=head1 HOW TO USE

Run it directly with C<prove -lv t/204-indicatorstore-pending-path-symlink.t>
while iterating, then keep it green under C<prove -lr t> and the coverage
runs before release.

=head1 WHAT USES IT

Developers during TDD, the full C<prove -lr t> suite, the coverage gates,
and the release verification loop all rely on this file to keep the
IndicatorStore staging-path fix from regressing.

=head1 EXAMPLES

Example 1:

  prove -lv t/204-indicatorstore-pending-path-symlink.t

Run the focused regression test by itself while changing the behavior it owns.

Example 2:

  HARNESS_PERL_SWITCHES=-MDevel::Cover prove -lv t/204-indicatorstore-pending-path-symlink.t

Exercise the same focused test while collecting coverage for the library code it reaches.

Example 3:

  prove -lr t

Put the focused fix back through the whole repository suite before calling the work finished.

=for comment FULL-POD-DOC END

=cut
