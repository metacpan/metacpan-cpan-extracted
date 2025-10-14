#!/usr/bin/env perl
use strict;
use Test::More;

require_ok('Math::ReedSolomon::Encoder')
   or BAIL_OUT("can't load Math::ReedSolomon::Encoder");

diag("Testing Math::ReedSolomon $Math::ReedSolomon::Encoder::VERSION");
done_testing();
