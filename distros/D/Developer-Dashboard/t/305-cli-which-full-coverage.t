#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;
use File::Spec;
use File::Temp qw(tempdir);

use lib 'lib';

use Developer::Dashboard::CLI::Which ();

my @warnings;
local $SIG{__WARN__} = sub { push @warnings, $_[0] };

my $missing = File::Spec->catdir( tempdir( CLEANUP => 1 ), 'no-such-hooks-dir' );
my $err = eval { Developer::Dashboard::CLI::Which::_runnable_hook_entries($missing); 1 } ? '' : $@;
like( $err, qr/Unable to read \Q$missing\E/, 'an unreadable or missing hook directory is reported' );

is_deeply( \@warnings, [], 'no warnings escaped' );

done_testing;

__END__

=pod

=head1 NAME

t/305-cli-which-full-coverage.t - hook directory failure coverage for CLI::Which

=head1 DESCRIPTION

Covers the opendir failure branch of the hook-entry scan in
L<Developer::Dashboard::CLI::Which>.

=head1 PURPOSE

Test file in the Developer Dashboard codebase. It closes the remaining Devel::Cover branch, condition and statement gaps for: hook directory failure coverage for CLI::Which.

=head1 WHY IT EXISTS

It exists because the mandatory 100 percent lib/ coverage gate (Problem 20) needs every reachable branch exercised, and these paths were only reachable through failure injection or unusual inputs that the broader tests do not produce.

=head1 WHEN TO USE

Use this file when you change the modules it covers, when a coverage run reports one of their branches or conditions as uncovered, or when you want a focused check before running the full suite.

=head1 HOW TO USE

Run it directly with C<prove -lv t/305-cli-which-full-coverage.t> while iterating, then keep it green under C<prove -lr t> and the Devel::Cover run before release. It is hermetic: it uses temporary directories and a local HOME.

=head1 WHAT USES IT

It is used by developers during TDD, by the full C<prove -lr t> suite, by the Devel::Cover coverage gate, and by release verification before commit or push.

=head1 EXAMPLES

Example 1:

  prove -lv t/305-cli-which-full-coverage.t

Run this coverage-gap test by itself while editing the covered modules.

Example 2:

  HARNESS_PERL_SWITCHES=-MDevel::Cover prove -lv t/305-cli-which-full-coverage.t

Confirm the targeted branches and conditions are reported as covered.

=cut
