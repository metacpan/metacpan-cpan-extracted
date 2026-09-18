#!/usr/bin/env perl

use strict;
use warnings;
use utf8;

use Test::More;
use File::Temp qw(tempdir);
use File::Spec;
use File::Path qw(make_path);

use Developer::Dashboard::CLI::Source;

my $M = 'Developer::Dashboard::CLI::Source';

# --------------------------------------------------------------------------
# Hermetic runtime: a fake ~/perl5/{lib,bin} tree under a temp HOME, so this
# test never depends on (or is slowed by) the real installed perl5 tree.
# --------------------------------------------------------------------------
my $home = tempdir( CLEANUP => 1 );
make_path( File::Spec->catdir( $home, 'perl5', 'lib', 'Developer', 'Dashboard' ) );
make_path( File::Spec->catdir( $home, 'perl5', 'bin' ) );

my $lib_file = File::Spec->catfile( $home, 'perl5', 'lib', 'Developer', 'Dashboard', 'Fake.pm' );
open my $fh1, '>', $lib_file or die $!;
print {$fh1} "package Developer::Dashboard::Fake;\n1;\n";
close $fh1;

my $bin_file = File::Spec->catfile( $home, 'perl5', 'bin', 'fake-tool' );
open my $fh2, '>', $bin_file or die $!;
print {$fh2} "#!/usr/bin/env perl\n";
close $fh2;

subtest 'command name validation' => sub {
    eval { $M->can('run_source_command')->( command => 'not-source', args => [] ) };
    like( $@, qr/Usage: dashboard source/, 'wrong command name dies with usage' );
};

subtest 'missing --files flag dies with usage' => sub {
    eval { $M->can('run_source_command')->( command => 'source', args => [], home => $home ) };
    like( $@, qr/Usage: dashboard source/, '--files is required' );
};

subtest 'missing command key dies with a clear message' => sub {
    eval { $M->can('run_source_command')->( args => [] ) };
    like( $@, qr/Missing command name/, 'no command key dies clearly' );
};

subtest 'missing args key dies with a clear message' => sub {
    eval { $M->can('run_source_command')->( command => 'source' ) };
    like( $@, qr/Missing command arguments/, 'no args key dies clearly' );
};

subtest 'args must be an array reference' => sub {
    eval { $M->can('run_source_command')->( command => 'source', args => 'not-an-arrayref' ) };
    like( $@, qr/array reference/, 'a non-arrayref args value dies clearly' );
};

subtest 'an unrecognized option dies with usage' => sub {
    eval { $M->can('run_source_command')->( command => 'source', args => ['--bogus'], home => $home ) };
    like( $@, qr/Usage: dashboard source/, 'GetOptionsFromArray failure dies with usage, not a raw Getopt error' );
};

subtest 'HOME truly unset (no override, no $ENV{HOME}) dies clearly' => sub {
    local $ENV{HOME};
    delete $ENV{HOME};
    eval { $M->can('run_source_command')->( command => 'source', args => ['--files'], home => undef ) };
    like( $@, qr/HOME is not set/, 'dies clearly when neither an explicit home nor $ENV{HOME} is available' );
};

subtest '--files lists real installed files, sorted' => sub {
    my $rc = $M->can('run_source_command')->(
        command => 'source', args => ['--files'], home => $home, out => \my $out,
    );
    is( $rc, 0, 'exits 0' );
    my @lines = split /\n/, $out;
    ok( ( grep { $_ eq $lib_file } @lines ), 'lists the fake lib file' );
    ok( ( grep { $_ eq $bin_file } @lines ), 'lists the fake bin file' );
    is_deeply( \@lines, [ sort @lines ], 'output is sorted' );
};

subtest 'missing HOME dies cleanly' => sub {
    eval { $M->can('run_source_command')->( command => 'source', args => ['--files'], home => undef ) };
    like( $@, qr/HOME is not set/, 'undef home dies with a clear message' ) if !defined $ENV{HOME};
    # When $ENV{HOME} genuinely is set (normal test environment), the undef
    # override falls through to it rather than dying - assert that path
    # instead so this subtest is meaningful in both environments.
    if ( defined $ENV{HOME} ) {
        my $rc = $M->can('run_source_command')->( command => 'source', args => ['--files'], home => undef, out => \my $out );
        is( $rc, 0, 'falls through to $ENV{HOME} when no explicit home is given' );
    }
};

subtest '_emit does not double an already-trailing newline' => sub {
    my $out = '';
    $M->can('_emit')->( \$out, "line one\nline two\n" );
    is( $out, "line one\nline two\n", 'a text already ending in a newline is passed through untouched' );
};

subtest '_emit writes to a real filehandle sink' => sub {
    my $buf = '';
    open my $fh, '>', \$buf or die $!;
    $M->can('_emit')->( $fh, 'via filehandle' );
    close $fh;
    is( $buf, "via filehandle\n", '_emit prints to a filehandle ref, not just a SCALAR ref or STDOUT' );
};

subtest 'no matching perl5 dirs produces no output, still exits 0' => sub {
    my $empty_home = tempdir( CLEANUP => 1 );
    my $rc = $M->can('run_source_command')->(
        command => 'source', args => ['--files'], home => $empty_home, out => \my $out,
    );
    is( $rc, 0, 'exits 0 even with nothing installed' );
    is( $out, undef, 'nothing emitted when there is nothing to list' );
};

done_testing;

__END__

=pod

=head1 NAME

t/197-cli-source-coverage.t - coverage for Developer::Dashboard::CLI::Source (DD-938)

=head1 PURPOSE

Exercises C<dashboard source --files>: usage validation, real file listing
against a fake installed tree, and the empty-tree edge case.

=head1 WHY IT EXISTS

DD-938 added C<dashboard source --files> as the fallback deep-dive reference
for C<dashboard ask --docs>'s curated onboarding summary - this file is its
own coverage gate.

=head1 WHEN TO USE

Run whenever C<lib/Developer/Dashboard/CLI/Source.pm> changes.

=head1 HOW TO USE

  PERL5LIB="$HOME/perl5/lib/perl5" prove -lv t/197-cli-source-coverage.t

=head1 WHAT USES IT

Developer::Dashboard::CLI::Source

=head1 EXAMPLES

See the subtests above for the exact scenarios covered.

=cut
