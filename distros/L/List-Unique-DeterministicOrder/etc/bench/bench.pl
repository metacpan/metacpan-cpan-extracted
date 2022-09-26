
use Benchmark qw {:all};
use 5.016;
use Data::Dumper;
use Test::More;

use rlib '../../lib';

use List::Unique::DeterministicOrder;
use List::BinarySearch::XS qw /binsearch/;
use List::MoreUtils::XS 0.423 qw/bremove binsert/;
use List::MoreUtils;# qw /bremove/;
use Hash::Ordered;

use Clone qw /clone/;


my $nreps = $ARGV[0] || 500;
my $data_size = $ARGV[1] || 1000;
my $run_benchmarks = $ARGV[2];

#  ratio of insertions to deletions
my $insertion_frac = 0.1;
my $insert_count   = $data_size * $insertion_frac;

srand 1534390472;

my %hashbase;
#@hash{1..1000} = (rand()) x 1000;
my $item = 'a';
for my $i (1 .. ($data_size +$insert_count)) {
    $hashbase{$item} = rand() + 1;
    $item ++;
}
my $hashref = \%hashbase;

my @rand_keys    = sort {$hashbase{$a} <=> $hashbase{$b}} keys %hashbase;
my @insertions   = splice @rand_keys, 0, $data_size * $insertion_frac;
my @sorted_keys  = sort @rand_keys;
my @sorted_pairs = map {$_ => 1} @sorted_keys;



my $dds_base = List::Unique::DeterministicOrder->new(data => \@sorted_keys);
my $ho_base  = Hash::Ordered->new (@sorted_pairs);

my %data = (
    lmu => [],
    lbs => [],
    ldd => [],
    lho => [],
    baseline => [],
);

#  make lots of copies to ensure data generation
#  is outside the benchmarking
foreach my $i (0 .. $nreps+1) {
    push @{$data{lmu}}, [@sorted_keys];
    push @{$data{lbs}}, [@sorted_keys];
    push @{$data{ldd}}, clone $dds_base;
    push @{$data{lho}}, clone $ho_base;
    push @{$data{baseline}}, [@sorted_keys];
}




my $l1 = lmu();
my $l2 = lbs();
my $l3 = ldd();
my $l4 = lho();

say 'First few items in each list:';
say join ' ', @$l1[0 .. 5];
say join ' ', @$l2[0 .. 5];
say join ' ', @$l3[0 .. 5];
say join ' ', @$l4[0 .. 5];

is_deeply ($l1, $l2, 'same order');
is_deeply ($l1, [sort @$l3], 'same contents, list-u-det-order');
is_deeply ($l1, [sort @$l4], 'same contents, hash ordered');


done_testing();

exit if !$run_benchmarks;


cmpthese (
    $nreps,
    {
        lmu  => sub {lmu()},
        lbs  => sub {lbs()},
        ldd  => sub {ldd()},
        lho  => sub {lho()},
        baseline => sub {baseline()},
    }
);

sub lbs {
    my $list = shift @{$data{lbs}};
    my $i = -1;
    foreach my $key (@rand_keys) {
        $i++;
        delete_from_sorted_list_aa($key, $list);
        my $insert = $insertions[$i] // next;
        binsert {$_ cmp $insert} $insert, @$list;
    }
    $list;
}

sub delete_from_sorted_list_aa {
    my $idx  = binsearch { $a cmp $b } $_[0], @{$_[1]};
    splice @{$_[1]}, $idx, 1;

    $idx;
}

sub insert_into_sorted_list_aa {
    my $idx  = binsearch_pos { $a cmp $b } $_[1], @{$_[2]};
    splice @{$_[2]}, $idx, 0, $_[1];

    $idx;
}


sub lmu {
    my $list = shift @{$data{lmu}};
    my $i = -1;
    foreach my $key (@rand_keys) {
        $i++;
        bremove {$_ cmp $key} @$list;
        my $insert = $insertions[$i] // next;
        binsert {$_ cmp $insert} $insert, @$list;
    }
    $list;
}

sub ldd {
    #  $dds reflects the old name for the module
    my $dds = shift @{$data{ldd}};
    my $i = -1;
    foreach my $key (@rand_keys) {
        $i++;
        $dds->delete ($key);
        my $insert = $insertions[$i] // next;
        $dds->push ($insert);
    }
    [$dds->keys];
}

sub lho {
    my $ho = shift @{$data{lho}};
    my $i = -1;
    foreach my $key (@rand_keys) {
        $i++;
        $ho->delete ($key);
        my $insert = $insertions[$i] // next;
        $ho->set ($insert => 1);
    }
    [$ho->keys];
}

sub baseline {
    my $list = shift @{$data{baseline}};
    my $i;
    foreach my $key (@rand_keys) {
        $i++;
        my $insert = $insertions[$i] // next;
    }
    $list;
}

__END__

This first test fluctuates a fair bit,
but List::Unique::DeterministicOrder is consistently fastest by ~40% or more.
The others have not been tested with differing PRNG seeds.  

perl etc\bench\bench.pl 5000 1000 1
First few items in each list:
aak aap aas abc abk aby
aak aap aas abc abk aby
fs agm ahh aft tp px
gz aak amq nn cp sb
ok 1 - same order
ok 2 - same contents, list-u-det-order
ok 3 - same contents, hash ordered
1..3
           Rate      lho      lbs      lmu      ldd baseline
lho       284/s       --     -11%     -11%     -73%     -96%
lbs       318/s      12%       --      -0%     -70%     -96%
lmu       319/s      12%       0%       --     -70%     -96%
ldd      1053/s     271%     231%     230%       --     -85%
baseline 7112/s    2405%    2134%    2132%     576%       --


perl etc\bench\bench.pl 500 10000 1
First few items in each list:
aak aap aas abc abk aby
aak aap aas abc abk aby
pau bpx ism hpl blm ofb
ovt loc eug gxs gz biw
ok 1 - same order
ok 2 - same contents, list-u-det-order
ok 3 - same contents, hash ordered
1..3
           Rate      lmu      lbs      lho      ldd baseline
lmu      6.60/s       --     -30%     -62%     -81%     -98%
lbs      9.36/s      42%       --     -45%     -73%     -97%
lho      17.1/s     160%      83%       --     -51%     -95%
ldd      35.1/s     431%     274%     105%       --     -90%
baseline  368/s    5479%    3829%    2047%     950%       --


perl etc\bench\bench.pl 50 50000 1
First few items in each list:
aaan aabb aabq aabx aacz aadd
aaan aabb aabq aabx aacz aadd
ahcx ansq bsir bkss aadw apiq
bmzy ovt anya bclp aijn bqtc
ok 1 - same order
ok 2 - same contents, list-u-det-order
ok 3 - same contents, hash ordered
1..3
            Rate      lmu      lbs      lho      ldd baseline
lmu      0.353/s       --     -18%     -89%     -97%    -100%
lbs      0.428/s      21%       --     -87%     -96%    -100%
lho       3.33/s     843%     678%       --     -71%     -97%
ldd       11.6/s    3168%    2595%     247%       --     -89%
baseline   107/s   30067%   24780%    3098%     823%       --


perl etc\bench\bench.pl 5 100000 1
First few items in each list:
aaan aabb aabq aabx aacz aadd
aaan aabb aabq aabx aacz aadd
cxwa aqvg kpv bfru eiwd nbe
bmzy ovt anya bclp aijn dmmr
ok 1 - same order
ok 2 - same contents, list-u-det-order
ok 3 - same contents, hash ordered
1..3
            (warning: too few iterations for a reliable count)
                Rate      lbs      lmu      lho      ldd baseline
lbs      9.73e-002/s       --      -8%     -94%     -97%    -100%
lmu          0.105/s       8%       --     -94%     -97%    -100%
lho           1.62/s    1570%    1444%       --     -53%     -96%
ldd           3.48/s    3476%    3207%     114%       --     -92%
baseline      45.9/s   47048%   43492%    2724%    1218%       --
