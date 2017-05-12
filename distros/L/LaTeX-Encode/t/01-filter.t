#!/usr/bin/perl
# $Id: 01-filter.t 17 2012-08-29 06:16:11Z andrew $

use strict;
use warnings;

use Test::More tests => 7;

use blib;
use LaTeX::Encode;

# Basic special characters: \ { } & # ^ _ $ % 

is(latex_encode('AT&T'),         "AT\\&T",                 "'&' - ampersand");
is(latex_encode('\\LaTeX'),      "{\\textbackslash}LaTeX", "'\\' - backslash");
is(latex_encode('$0.01'),        "\\\$0.01",               "'\$' - dollar");
is(latex_encode('10% discount'), '10\\% discount',         "'%' - per cent");
is(latex_encode('mod_perl'),     'mod\\_perl',             "'_' - underscore");
is(latex_encode('Looking after #1'), 'Looking after \\#1', "'#' - hash sign");

is(latex_encode('\\textbf{AT&T}', except => '\\{}'),
   "\\textbf{AT\\&T}", "emboldened text");
