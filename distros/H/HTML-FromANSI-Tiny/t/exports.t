use strict;
use warnings;
use Test::More 0.96;
use Test::Differences;

use HTML::FromANSI::Tiny qw(
  html_from_ansi
);

eq_or_diff
  scalar html_from_ansi("\e[31mfoo\033[1;32mbar\033[0m"),
  '<span class="red">foo</span><span class="bold green">bar</span>',
  'html_from_ansi exported and working';

eq_or_diff
  [html_from_ansi("foo\e[31mba\e[0mr\033[1;32mbaz")],
  ['<span class="">foo</span>', '<span class="red">ba</span>', '<span class="">r</span>', '<span class="bold green">baz</span>'],
  'html_from_ansi in list context';

done_testing;
