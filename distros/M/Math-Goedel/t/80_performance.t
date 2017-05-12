
use strict;
use warnings;

use Test::More;

plan skip_all => "this test is only for direct execution" if (!@ARGV);

eval "use Benchmark;";
plan skip_all => "Benchmark cannot be used" if ($@);

use Math::Goedel qw/goedel/;

timethis(10, 'goedel($_) for 1 .. 10000;');

