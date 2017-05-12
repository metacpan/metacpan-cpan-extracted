use strict;
use warnings;
use Test::PerlTidy;

run_tests( exclude =>
      [ qr{Makefile.PL}, qr{blib/}, qr{Games-Dice-Roll20-.*/}, qr{.build/} ] );
