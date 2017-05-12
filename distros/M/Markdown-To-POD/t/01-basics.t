#!perl

use 5.010;
use strict;
use warnings;

use Markdown::To::POD qw(markdown_to_pod);
use Test::More 0.98;

is(markdown_to_pod("a_b and c_d"), "a_b and c_d\n");
is(markdown_to_pod("a _b and c_ d"), "a I<b and c> d\n");
is(markdown_to_pod("`<tag>`"), "C<< E<lt>tagE<gt> >>\n");

DONE_TESTING:
done_testing;
