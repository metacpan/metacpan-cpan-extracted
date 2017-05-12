#!/usr/bin/perl

# An HTML-Stripping Filter.

use strict;
use warnings;

use HTML::Strip::Whitespace qw(html_strip_whitespace);

my $buffer = "";
html_strip_whitespace(
    'source' => \*STDIN,
    'out' => \*STDOUT,
);

