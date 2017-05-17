#!/usr/bin/perl

use LaTeX::Encode qw(:all);
use Test::More tests => 8;

is(latex_encode('$'), '\\$', 'Dollar Sign');
is(latex_encode('%'), '\\%', 'Percent Sign');
is(latex_encode('\\'), '{\\textbackslash}', 'Backslash');
is(latex_encode('_'), '\\_', 'Underscore');
is(latex_encode('{'), '\\{', 'left brace');
is(latex_encode('}'), '\\}', 'right brace');
is(latex_encode('!'), '!', 'Not escaping !');
is(latex_encode('business!'), 'business!', 'Not escaping ! in a word');
