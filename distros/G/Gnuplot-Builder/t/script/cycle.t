use strict;
use warnings FATAL => "all";
use Test::More;
use Test::Memory::Cycle;
use Gnuplot::Builder::Script;

my $builder = Gnuplot::Builder::Script->new;
memory_cycle_ok $builder, "No cyclic refs";
done_testing;

