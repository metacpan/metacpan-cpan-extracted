#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 1;

BEGIN {
    use_ok('Dir::Split');
}

diag("Testing Dir::Split $Dir::Split::VERSION, Perl $], $^X");
