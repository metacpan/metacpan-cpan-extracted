use strict;
use warnings;
use utf8;

use Markdown::Perl;
use Test2::V0;

sub run {
  &Markdown::Perl::convert;
}

is(run('[foo](/bar) [baz](/bin)'), "<p><a href=\"/bar\">foo</a> <a href=\"/bin\">baz</a></p>\n", 'two_links');

done_testing;
