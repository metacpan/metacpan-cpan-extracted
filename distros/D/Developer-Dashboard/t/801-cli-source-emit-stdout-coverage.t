#!/usr/bin/env perl

use strict;
use warnings;

use Capture::Tiny qw(capture);
use Test::More;

use lib 'lib';

use Developer::Dashboard::CLI::Source;

my $emit = \&Developer::Dashboard::CLI::Source::_emit;

my ( $stdout, $stderr ) = capture { $emit->( undef, 'to stdout' ) };
is( $stdout, "to stdout\n", 'a missing sink writes the text to standard output with a trailing newline' );
is( $stderr, '', 'nothing is written to standard error' );

( $stdout, $stderr ) = capture { $emit->( undef, "already terminated\n" ) };
is( $stdout, "already terminated\n", 'a text that already ends in a newline is not given a second one' );

my $scalar = '';
$emit->( \$scalar, 'to scalar' );
is( $scalar, "to scalar\n", 'a scalar reference collects the text' );

my $handle_text = '';
open my $handle, '>', \$handle_text or die "Unable to open in-memory handle: $!";
$emit->( $handle, 'to handle' );
close $handle or die "Unable to close in-memory handle: $!";
is( $handle_text, "to handle\n", 'a filehandle receives the text' );

done_testing;

__END__

=pod

=head1 NAME

t/801-cli-source-emit-stdout-coverage.t - covers every output sink of Developer::Dashboard::CLI::Source::_emit

=head1 PURPOSE

Test file in the Developer Dashboard codebase. It calls C<_emit> in-process with no sink, a scalar reference and a filehandle, so the standard-output branch is exercised directly.

=head1 WHY IT EXISTS

It exists because the standard-output branch was only reached by CLI subprocesses, whose coverage is not recorded the same way on every host, so a non-root CI run reported it uncovered (Problem 20).

=head1 WHEN TO USE

Use this file when you change how the source listing writes its output, or when a coverage run reports a line of C<_emit> as uncovered.

=head1 HOW TO USE

Run it directly with C<prove -lv t/801-cli-source-emit-stdout-coverage.t> while iterating, then keep it green under C<prove -lr t> and the Devel::Cover run before release.

=head1 WHAT USES IT

It is used by developers during TDD, by the full C<prove -lr t> suite, by the Devel::Cover coverage gate, and by release verification before commit or push.

=head1 EXAMPLES

Example 1:

  prove -lv t/801-cli-source-emit-stdout-coverage.t

Run this coverage-gap test by itself while editing the source listing.

Example 2:

  HARNESS_PERL_SWITCHES=-MDevel::Cover prove -lv t/801-cli-source-emit-stdout-coverage.t

Confirm every sink branch is reported as covered.

=cut
