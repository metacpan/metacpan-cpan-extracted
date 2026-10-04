#!/usr/bin/env perl

use strict;
use warnings;

use Capture::Tiny qw(capture);
use File::Temp qw(tempdir);
use Test::More;

use lib 'lib';

use Developer::Dashboard::CLI::Skills ();

my @warnings;
local $SIG{__WARN__} = sub { push @warnings, $_[0] };

my $home = tempdir( CLEANUP => 1 );
local $ENV{HOME} = $home;
chdir $home or die "Unable to chdir to $home: $!";

# run_cli(@argv)
# Runs one skills helper command with stdout and stderr captured.
# Input: argv list following the command name.
# Output: hash reference with exit code, stdout and stderr.
sub run_cli {
    my (@argv) = @_;
    my $exit;
    my ( $stdout, $stderr ) = capture {
        $exit = Developer::Dashboard::CLI::Skills::run_skills_command( command => 'skills', args => [@argv] );
    };
    return { exit => $exit, stdout => $stdout, stderr => $stderr };
}

is( run_cli( 'install', '--branch', 'main' )->{exit}, 2, 'the long --branch form without a source reports usage' );
is( run_cli( 'install', '--branch', '--notest', 'alpha' )->{exit}, 2, '--branch followed by another option reports usage' );
is( run_cli( 'install', '-b', '-o', 'json' )->{exit}, 2, '-b followed by another option reports usage' );

my $unknown = run_cli( 'install', '--definitely-not-an-option' );
is( $unknown->{exit}, 2, 'an unknown install option reports usage' );
like( $unknown->{stdout} . $unknown->{stderr}, qr/Usage: dashboard skills install/, 'the usage text is printed' );

is( scalar(@warnings), 1, 'only the Getopt::Long unknown-option warning was emitted' );
like( $warnings[0], qr/Unknown option: definitely-not-an-option/, 'the warning names the unknown option' );

done_testing;

__END__

=pod

=head1 NAME

t/302-cli-skills-full-coverage.t - install option-parsing condition coverage for CLI::Skills

=head1 DESCRIPTION

Covers the C<--branch> long form, a branch flag followed by another option, and
GetOptions failures in C<dashboard skills install> option validation.

=head1 PURPOSE

Test file in the Developer Dashboard codebase. It closes the remaining Devel::Cover branch, condition and statement gaps for: install option-parsing condition coverage for CLI::Skills.

=head1 WHY IT EXISTS

It exists because the mandatory 100 percent lib/ coverage gate (Problem 20) needs every reachable branch exercised, and these paths were only reachable through failure injection or unusual inputs that the broader tests do not produce.

=head1 WHEN TO USE

Use this file when you change the modules it covers, when a coverage run reports one of their branches or conditions as uncovered, or when you want a focused check before running the full suite.

=head1 HOW TO USE

Run it directly with C<prove -lv t/302-cli-skills-full-coverage.t> while iterating, then keep it green under C<prove -lr t> and the Devel::Cover run before release. It is hermetic: it uses temporary directories and a local HOME.

=head1 WHAT USES IT

It is used by developers during TDD, by the full C<prove -lr t> suite, by the Devel::Cover coverage gate, and by release verification before commit or push.

=head1 EXAMPLES

Example 1:

  prove -lv t/302-cli-skills-full-coverage.t

Run this coverage-gap test by itself while editing the covered modules.

Example 2:

  HARNESS_PERL_SWITCHES=-MDevel::Cover prove -lv t/302-cli-skills-full-coverage.t

Confirm the targeted branches and conditions are reported as covered.

=cut
