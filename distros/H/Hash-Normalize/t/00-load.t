#!perl -T

use strict;
use warnings;

use Test::More tests => 1;

BEGIN {
 use_ok('Hash::Normalize');
}

diag("Testing Hash::Normalize $Hash::Normalize::VERSION, Perl $], $^X");
