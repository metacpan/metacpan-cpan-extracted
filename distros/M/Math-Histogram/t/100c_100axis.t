use strict;
use warnings;
BEGIN {
  push @INC, 't/lib', 'lib';
}
use Math::Histogram::Test;

run_ctest('100axis')
  or Test::More->import(skip_all => "C executable not found");


