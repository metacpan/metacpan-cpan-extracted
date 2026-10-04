#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;

use lib 'lib';

use Developer::Dashboard::Zipper;

my $rendered = eval { Developer::Dashboard::Zipper::_render_ajax_code_template( '[% IF %]', { a => 1 } ) };
is( $rendered, undef, 'a malformed Ajax code template does not render' );
like( $@, qr/Unable to render Ajax code template/, 'the template renderer reports the parse failure' );

done_testing;

__END__

=pod

=head1 NAME

t/421-zipper-coverage.t - covers the Ajax code template render failure in Developer::Dashboard::Zipper

=head1 PURPOSE

Feeds _render_ajax_code_template a syntactically invalid Template Toolkit
string so the process() failure path dies with the documented message.

=head1 WHY IT EXISTS

It exists because the mandatory 100 percent lib/ coverage gate (Problem 20) needs every reachable branch exercised, and these paths were only reachable through failure injection or unusual inputs that the broader tests do not produce.

=head1 WHEN TO USE

Use this file when you change the modules it covers, when a coverage run reports one of their branches or conditions as uncovered, or when you want a focused check before running the full suite.

=head1 HOW TO USE

Run it directly with C<prove -lv t/421-zipper-coverage.t> while iterating, then keep it green under C<prove -lr t> and the Devel::Cover run before release. It is hermetic: it uses temporary directories and a local HOME.

=head1 WHAT USES IT

It is used by developers during TDD, by the full C<prove -lr t> suite, by the Devel::Cover coverage gate, and by release verification before commit or push.

=head1 EXAMPLES

Example 1:

  prove -lv t/421-zipper-coverage.t

Run this coverage-gap test by itself while editing the covered modules.

Example 2:

  HARNESS_PERL_SWITCHES=-MDevel::Cover prove -lv t/421-zipper-coverage.t

Confirm the targeted branches and conditions are reported as covered.

=cut
