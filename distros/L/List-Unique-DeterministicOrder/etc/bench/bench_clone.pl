
use Benchmark qw {:all};
use 5.016;
use Data::Dumper;
use Test::More;
use Clone qw //;

use rlib '../../lib';

use List::Unique::DeterministicOrder;
use Clone;


my $nreps = $ARGV[0] || -3;
my $data_size = $ARGV[1] || 1000;
my $run_benchmarks = $ARGV[2] || 1;

#  ratio of insertions to deletions
my $insertion_frac = 0.1;
my $insert_count   = $data_size * $insertion_frac;

srand 1534390472;

my @sorted_keys = ('a' .. 'zzz');
my $base_object = List::Unique::DeterministicOrder->new(data => \@sorted_keys);


my $l1 = lu_clone();
my $l2 = xs_clone();


done_testing();

exit if !$run_benchmarks;


cmpthese (
    $nreps,
    {
        xs_clone  => sub {xs_clone()},
        lu_clone  => sub {lu_clone()},
    }
);

sub lu_clone {
    my $c;
    for my $i (1..1000) {
        $c = $base_object->clone;
    }
    return $c;
}

sub xs_clone {
    my $c;
    for my $i (1..1000) {
        $c = Clone::clone $base_object;
    }
    return $c;
}