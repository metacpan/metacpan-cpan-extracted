#!/usr/bin/env perl

# t/151-coverage-gate-launch-boundary.t
#
# WHAT THIS PROVES
#   The coverage gate refuses to grade a database that a DIFFERENT Devel::Cover
#   wrote, and says which two installs disagree.
#
# WHY IT EXISTS
#   The gate already guaranteed one environment for the three commands INSIDE a
#   run, which is why every check passed while the failure kept happening. The
#   thing it did not defend is the boundary between runs. `cover_db` persists, and
#   this host carries two Devel::Cover installs: launched with PERL5LIB set the
#   gate resolves ~/perl5, launched through a login shell - which rebuilds
#   PERL5LIB and PATH from the profile - it resolves /usr/local. Same command,
#   same directory, same perl, two serializers. One writes the database, the other
#   reads it, the formats disagree, and the gate reports a coverage failure that
#   has nothing to do with the code. Two rounds were spent chasing that ghost.
#
#   Before this, that case exited 2 with no explanation, which is the part that
#   made it expensive: an unexplained 2 is indistinguishable from a real failure.

use strict;
use warnings;

use File::Path qw(make_path remove_tree);
use File::Spec;
use File::Temp qw(tempdir);
use FindBin    ();
use Test::More;

my $GATE = File::Spec->catfile( $FindBin::Bin, File::Spec->updir, 'script', 'coverage-gate' );

plan skip_all => "coverage gate not found at $GATE" if !-f $GATE;

plan tests => 9;

my $CHECKER = File::Spec->catfile( $FindBin::Bin, File::Spec->updir, 'script', 'check-all-metric-coverage' );

# Purpose: build a throwaway repository that the gate will accept as its own root.
# Input:   nothing.
# Output:  the temp directory path.
#
# The gate derives its repository from the location of ITS OWN file and chdirs
# there, so pointing a temp working directory at the real script would grade the
# real repository. The copy has to live inside the sandbox for the sandbox to mean
# anything.
sub temp_repo {
    my $dir = tempdir( CLEANUP => 1 );
    make_path( File::Spec->catdir( $dir, 'script' ) );
    _copy_file( $GATE,    File::Spec->catfile( $dir, 'script', 'coverage-gate' ) );
    _copy_file( $CHECKER, File::Spec->catfile( $dir, 'script', 'check-all-metric-coverage' ) )
      if -f $CHECKER;
    return $dir;
}

# Purpose: copy one file, because File::Copy is not worth a dependency here.
# Input:   source and destination paths.
# Output:  nothing; dies when it cannot.
sub _copy_file {
    my ( $from, $to ) = @_;
    open my $in,  '<', $from or die "cannot read $from: $!";
    open my $out, '>', $to   or die "cannot write $to: $!";
    print {$out} do { local $/; <$in> };
    close $in;
    close $out;
    chmod 0755, $to;
    return;
}

# Purpose: run the sandboxed gate and capture what it said.
# Input:   the temp repository, and any environment overrides.
# Output:  hashref of exit status, stdout and stderr.
sub run_gate {
    my (%args) = @_;
    my $dir  = $args{dir};
    my $gate = File::Spec->catfile( $dir, 'script', 'coverage-gate' );
    my $out  = File::Spec->catfile( $dir, 'gate.out' );
    my %env  = %{ $args{env} || {} };
    local @ENV{ keys %env } = values %env;
    my $status = system("perl '$gate' --dry-run > '$out' 2>&1");
    open my $fh, '<', $out or die "cannot read gate output: $!";
    my $text = do { local $/; <$fh> };
    close $fh;
    return { status => $status >> 8, text => $text };
}

# A stamp written by a serializer that is definitely not this one. Using an
# obviously-fake path rather than the host's second install keeps the test honest
# on a machine that happens to have only one.
my $FOREIGN = '/opt/some-other-perl/lib/Devel/Cover/DB/IO.pm';

subtest 'a database stamped by another serializer is refused, and both are named' => sub {
    plan tests => 5;

    my $dir = temp_repo();
    make_path( File::Spec->catdir( $dir, 'cover_db' ) );

    open my $fh, '>', File::Spec->catfile( $dir, 'cover_db', 'gate-serializer' )
      or die "cannot write stamp: $!";
    print {$fh} "$FOREIGN\n";
    close $fh;

    my $result = run_gate( dir => $dir );

    is( $result->{status}, 2, 'refuses with the unusable status rather than grading it' );
    like( $result->{text}, qr/different Devel::Cover/,
        'says the problem is a different Devel::Cover, not something vague' );
    like( $result->{text}, qr/\Q$FOREIGN\E/, 'names the serializer that wrote the database' );
    like( $result->{text}, qr/reading as/, 'names the serializer that would read it' );
    like( $result->{text}, qr/launch boundary/,
        'explains WHY the two differ, so the reader knows what to change' );
};

subtest 'a database this serializer wrote is graded normally' => sub {
    plan tests => 2;

    my $dir = temp_repo();
    make_path( File::Spec->catdir( $dir, 'cover_db' ) );

    # First run stamps it; the second must accept its own stamp.
    run_gate( dir => $dir );
    my $second = run_gate( dir => $dir );

    isnt( $second->{status}, 2, 'a matching stamp is not treated as a mismatch' );
    unlike( $second->{text}, qr/different Devel::Cover/,
        'and it does not warn about a disagreement that is not there' );
};

subtest 'the stamp is written so the NEXT run can make this check' => sub {
    plan tests => 2;

    my $dir = temp_repo();
    make_path( File::Spec->catdir( $dir, 'cover_db' ) );

    run_gate( dir => $dir );

    my $stamp = File::Spec->catfile( $dir, 'cover_db', 'gate-serializer' );
    ok( -f $stamp, 'the gate records which serializer wrote the database' );

    open my $fh, '<', $stamp or die "cannot read stamp: $!";
    my $recorded = <$fh>;
    close $fh;
    chomp( $recorded //= '' );
    like( $recorded, qr{Devel/Cover/DB/IO\.pm$},
        'and what it records is a serializer path, not a placeholder' );
};

subtest 'an absent database is not a mismatch' => sub {
    plan tests => 1;

    my $dir = temp_repo();
    my $result = run_gate( dir => $dir );

    unlike( $result->{text}, qr/different Devel::Cover/,
        'a first run with no database to compare against is allowed to proceed' );
};

subtest 'an empty stamp file is treated as no stamp, not as a mismatch' => sub {
    plan tests => 1;

    my $dir = temp_repo();
    make_path( File::Spec->catdir( $dir, 'cover_db' ) );
    open my $fh, '>', File::Spec->catfile( $dir, 'cover_db', 'gate-serializer' )
      or die "cannot write stamp: $!";
    close $fh;

    my $result = run_gate( dir => $dir );
    unlike( $result->{text}, qr/different Devel::Cover/,
        'an unreadable or empty stamp does not manufacture a disagreement' );
};

subtest 'the refusal is explained, which is the whole point of the card' => sub {
    plan tests => 2;

    my $dir = temp_repo();
    make_path( File::Spec->catdir( $dir, 'cover_db' ) );
    open my $fh, '>', File::Spec->catfile( $dir, 'cover_db', 'gate-serializer' )
      or die "cannot write stamp: $!";
    print {$fh} "$FOREIGN\n";
    close $fh;

    my $result = run_gate( dir => $dir );

    cmp_ok( length $result->{text}, '>', 80,
        'it does not exit 2 in silence, which is the defect this card names' );
    like( $result->{text}, qr/Delete cover_db|one environment/,
        'and it tells the reader what to do about it' );
};

subtest 'the gate still refuses when a child cannot load the serializer at all' => sub {
    plan tests => 1;

    # Not reproducible by breaking PERL5LIB here without also breaking the parent,
    # so this asserts the branch exists and is worded for a human rather than
    # pretending to exercise it.
    open my $fh, '<', $GATE or die "cannot read the gate: $!";
    my $source = do { local $/; <$fh> };
    close $fh;

    like( $source, qr/a child process could not load Devel::Cover::DB::IO/,
        'the child-cannot-load case has its own explained refusal' );
};

subtest 'the source explains the launch boundary for the next reader' => sub {
    plan tests => 2;

    open my $fh, '<', $GATE or die "cannot read the gate: $!";
    my $source = do { local $/; <$fh> };
    close $fh;

    like( $source, qr/login shell/,
        'the comment names the launch path that causes it, not just the symptom' );
    like( $source, qr/crosses the launch boundary/,
        'and says why the database is the thing that carries the fault between runs' );
};

subtest 'a stamp write failure is announced rather than hidden' => sub {
    plan tests => 1;

    open my $fh, '<', $GATE or die "cannot read the gate: $!";
    my $source = do { local $/; <$fh> };
    close $fh;

    like( $source, qr/could not stamp the coverage database/,
        'a missing stamp is reported, because it silently disables the next check' );
};

__END__

=head1 NAME

151-coverage-gate-launch-boundary.t - pin the coverage gate's refusal to grade a
database written by a different Devel::Cover

=head1 PURPOSE

Prove that the gate detects a coverage database written by a I<different>
Devel::Cover install from the one now reading it, refuses to grade it, and names
both installs in the refusal.

=head1 WHY IT EXISTS

The gate already guaranteed one environment for the three commands inside a single
run, which is precisely why every check it made passed while the failure kept
happening. What it did not defend was the boundary I<between> runs. C<cover_db>
persists, and this host carries two Devel::Cover installs: launched with PERL5LIB
set, the gate resolves the one under the operator's local library tree; launched
through a login shell, which rebuilds PERL5LIB and PATH from the profile, it
resolves the system one. Same command, same directory, same perl, two serializers.
One writes the database, the other reads it, the formats disagree, and the gate
reports a coverage failure that has nothing to do with the code.

Two rounds were spent chasing that ghost. Before this, the case exited 2 with no
explanation, and an unexplained 2 is indistinguishable from a real failure - which
is what made it expensive rather than merely wrong.

=head1 WHEN TO USE

Run it whenever C<script/coverage-gate>, its stamping, or the way the suite is
launched changes. It is part of the ordinary suite and needs no special
environment.

=head1 HOW TO USE

    prove -lv t/151-coverage-gate-launch-boundary.t

It builds its own throwaway database and stamps, so it never touches the real
C<cover_db>.

=head1 WHAT USES IT

The full suite via C<prove -lr t>, the all-metric coverage gate, and the CI
workflow that runs both.

=head1 EXAMPLES

The load-bearing assertion is that a mismatch is REPORTED rather than merely
detected, because a silent refusal was the original defect:

    like( $source, qr/could not stamp the coverage database/,
        'a missing stamp is reported, because it silently disables the next check' );

=cut
