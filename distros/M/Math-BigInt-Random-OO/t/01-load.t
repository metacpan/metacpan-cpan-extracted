#!perl

use strict;
use warnings;

local $| = 1;                   # disable buffering

use Test::More tests => 1;

BEGIN { use_ok('Math::BigInt::Random::OO') };

diag("Testing Math::BigInt::Random::OO $Math::BigInt::Random::OO::VERSION,",
     " Perl $], $^X");
