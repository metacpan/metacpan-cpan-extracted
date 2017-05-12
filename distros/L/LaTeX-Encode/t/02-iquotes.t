#!/usr/bin/perl
# $Id: 02-iquotes.t 17 2012-08-29 06:16:11Z andrew $

use strict;
use warnings;

use Test::More tests => 7;

use blib;
use LaTeX::Encode;

# Basic special characters: \ { } & # ^ _ $ % 

is(latex_encode('blah "double quoted string" blah', { iquotes => 1 }),
   "blah ``double quoted string'' blah",
   "double quoted string");

is(latex_encode("blah\n\"double quoted string\"\nblah", { iquotes => 1 }),
   "blah\n``double quoted string''\nblah",
   "double quoted string on a separate line");

is(latex_encode('blah:"double quoted string" blah', { iquotes => 1 }),
   "blah:``double quoted string'' blah",
   "double quoted string with preceding punctuation");

is(latex_encode("blah 'single quoted string' blah", { iquotes => 1 }),
   "blah `single quoted string' blah",
   "single quoted string");

is(latex_encode("blah\n'single quoted string'\nblah", { iquotes => 1 }),
   "blah\n`single quoted string'\nblah",
   "single quoted string on a separate line");

is(latex_encode("blah:'single quoted string' blah", { iquotes => 1 }),
   "blah:`single quoted string' blah",
   "single quoted string with preceding punctuation");

is(latex_encode("isn't, doesn't", { iquotes => 1 }),
   "isn't, doesn't",
   "abbreviations");

exit(0);
