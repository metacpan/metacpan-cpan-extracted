use strict;
use warnings;

use File::Path qw(make_path);
use File::Spec;
use File::Temp qw(tempdir);
use Test::More;
use JSON::XS ();

use lib 'lib';

use Developer::Dashboard::Config;
use Developer::Dashboard::FileRegistry;
use Developer::Dashboard::PathRegistry;

# build_config($home, $config_dir)
# Constructs an isolated Config/PathRegistry/FileRegistry stack rooted at a
# throwaway home and explicit config directory so the tests never read or write
# the real developer runtime tree.
# Input: temporary home directory path and temporary config directory path.
# Output: Developer::Dashboard::Config object bound to those directories.
sub build_config {
    my ( $home, $config_dir ) = @_;
    my $paths = Developer::Dashboard::PathRegistry->new( home => $home, cwd => $home );
    my $files = Developer::Dashboard::FileRegistry->new( paths => $paths );
    return Developer::Dashboard::Config->new( files => $files, paths => $paths );
}

# count_by($items, $key)
# Tallies how many array members carry each value of one identity field so the
# tests can prove logical duplicates were collapsed.
# Input: array reference of hash references and the identity field name.
# Output: hash reference mapping identity value to occurrence count.
sub count_by {
    my ( $items, $key ) = @_;
    my %count;
    for my $item ( @{ $items || [] } ) {
        next if ref($item) ne 'HASH';
        next if !defined $item->{$key};
        $count{ $item->{$key} }++;
    }
    return \%count;
}

# Finding 1: a SINGLE config layer whose collectors/providers arrays each list
# the same logical identity twice must still be deduped in the merged view.
{
    my $home       = tempdir( CLEANUP => 1 );
    my $config_dir = tempdir( CLEANUP => 1 );
    local $ENV{HOME}                        = $home;
    local $ENV{DEVELOPER_DASHBOARD_CONFIGS} = $config_dir;

    my $payload = {
        collectors => [
            { name => 'dup', interval => 10 },
            { name => 'dup', interval => 20 },
            { name => 'solo', interval => 30 },
        ],
        providers => [
            { id => 'p1', title => 'first' },
            { id => 'p1', title => 'second' },
            { id => 'p2', title => 'other' },
        ],
    };

    my $config_file = File::Spec->catfile( $config_dir, 'config.json' );
    open my $fh, '>:raw', $config_file or die "Unable to write $config_file: $!";
    print {$fh} JSON::XS->new->utf8->canonical->encode($payload);
    close $fh or die "Unable to close $config_file: $!";

    my $config = build_config( $home, $config_dir );

    my $merged = $config->merged;

    my $collector_counts = count_by( $merged->{collectors}, 'name' );
    is( $collector_counts->{dup}, 1, 'single-layer duplicate collector name collapses to one entry' );
    is( $collector_counts->{solo}, 1, 'unique collector name is preserved once' );

    my $provider_counts = count_by( $merged->{providers}, 'id' );
    is( $provider_counts->{p1}, 1, 'single-layer duplicate provider id collapses to one entry' );
    is( $provider_counts->{p2}, 1, 'unique provider id is preserved once' );

    # providers() consumes the merged config directly, so it must not surface the
    # duplicate either.
    my $provider_counts_public = count_by( $config->providers, 'id' );
    is( $provider_counts_public->{p1}, 1, 'providers() does not surface duplicate provider ids' );

    # Deeper fields of the last duplicate win the merge, proving dedup merges
    # rather than blindly dropping.
    my ($dup_collector) = grep { ref($_) eq 'HASH' && ( $_->{name} // '' ) eq 'dup' } @{ $merged->{collectors} };
    is( $dup_collector->{interval}, 20, 'deduped collector keeps the last layer field value' );
}

# Finding 2: save_global writes config.json atomically (staged temp + rename)
# rather than truncating the live file in place, and checks close().
{
    my $home       = tempdir( CLEANUP => 1 );
    my $config_dir = tempdir( CLEANUP => 1 );
    local $ENV{HOME}                        = $home;
    local $ENV{DEVELOPER_DASHBOARD_CONFIGS} = $config_dir;

    my $config = build_config( $home, $config_dir );

    my $file = $config->save_global( { marker => 'first', nested => { a => 1 } } );
    ok( -f $file, 'save_global creates config.json' );
    my $inode_before = ( stat $file )[1];

    $config->save_global( { marker => 'second', nested => { a => 2 } } );
    my $inode_after = ( stat $file )[1];

    isnt( $inode_after, $inode_before,
        'save_global replaces config.json via temp+rename (fresh inode), not in-place truncation' );

    my @residue = glob( File::Spec->catfile( $config_dir, 'config.json.tmp*' ) );
    is( scalar(@residue), 0, 'save_global leaves no temp residue after rename' );

    open my $rfh, '<:raw', $file or die "Unable to read $file: $!";
    local $/;
    my $decoded = JSON::XS->new->utf8->decode(<$rfh>);
    close $rfh or die "Unable to close $file: $!";
    is( $decoded->{marker}, 'second', 'save_global persists the latest full payload' );
    is( $decoded->{nested}{a}, 2, 'save_global persists nested payload completely' );
}

# Finding 2: save_writable_api_registry writes api.json atomically as well.
{
    my $home       = tempdir( CLEANUP => 1 );
    my $config_dir = tempdir( CLEANUP => 1 );
    local $ENV{HOME}                        = $home;
    local $ENV{DEVELOPER_DASHBOARD_CONFIGS} = $config_dir;

    my $config = build_config( $home, $config_dir );

    my $file = $config->save_writable_api_registry(
        { first => { secret => 'aaa', ajax => ['/ajax/one'] } },
    );
    ok( -f $file, 'save_writable_api_registry creates api.json' );
    my $inode_before = ( stat $file )[1];

    $config->save_writable_api_registry(
        { second => { secret => 'bbb', ajax => ['/ajax/two'] } },
    );
    my $inode_after = ( stat $file )[1];

    isnt( $inode_after, $inode_before,
        'save_writable_api_registry replaces api.json via temp+rename (fresh inode)' );

    my @residue = glob( File::Spec->catfile( $config_dir, 'api.json.tmp*' ) );
    is( scalar(@residue), 0, 'save_writable_api_registry leaves no temp residue after rename' );

    my $registry = $config->writable_api_registry;
    ok( exists $registry->{second}, 'api.json persists the latest full payload' );
    is( $registry->{second}{secret}, 'bbb', 'api.json persists the secret completely' );
}

done_testing();

__END__

=head1 NAME

t/50-hunt-config.t - regression contract for layered config dedup and atomic config writes

=head1 DESCRIPTION

Exercises two robustness guarantees owned by
L<Developer::Dashboard::Config>: that logical collector (by C<name>) and
provider (by C<id>) identities are collapsed in the merged configuration view
even when a single runtime layer contains the duplicate, and that
C<save_global> and C<save_writable_api_registry> replace their JSON files
atomically through a staged temporary file plus rename instead of truncating
the live file in place.

=for comment FULL-POD-DOC START

=head1 PURPOSE

This test is the executable regression contract for two config-layer defects:
duplicate collector/provider identities leaking out of the merge, and
non-atomic config persistence that could expose a truncated or partially
written config.json/api.json. It pins the fixed behavior so the two bugs cannot
silently return.

=head1 WHY IT EXISTS

It exists because both defects are invisible to a casual read of the module.
The single-layer duplicate only surfaces through the merged view (not through
the collector merge path that already deduped across layers), and the atomic
write only matters when a reader observes the file mid-write. Encoding both as
concrete assertions keeps the TDD loop, coverage loop, and release gate honest.

=head1 WHEN TO USE

Use this file when changing configuration merge semantics, the collector or
provider identity keys, or any code path that writes config.json or api.json.
A focused failure here points directly at the merge dedup pass or the atomic
write helper.

=head1 HOW TO USE

Run it directly with C<prove -lv t/50-hunt-config.t> while iterating, then keep
it green under C<prove -lr t> and the coverage runs before release.

=head1 WHAT USES IT

Developers during TDD, the full C<prove -lr t> suite, the coverage gates, and
the release verification loop all rely on this file to keep config merge and
config persistence behavior from drifting.

=head1 EXAMPLES

Example 1:

  prove -lv t/50-hunt-config.t

Run the focused regression test by itself while you are changing the behavior it owns.

Example 2:

  HARNESS_PERL_SWITCHES=-MDevel::Cover prove -lv t/50-hunt-config.t

Exercise the same focused test while collecting coverage for the library code it reaches.

Example 3:

  prove -lr t

Put the focused fix back through the whole repository suite before calling the work finished.

=for comment FULL-POD-DOC END

=cut
