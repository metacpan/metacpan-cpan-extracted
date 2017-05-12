use strict;
use Test::More 0.98;
use MapReduce::Framework::Simple;

my $mfs = MapReduce::Framework::Simple->new;

my $data_map_reduce;
for(1 .. 4){
    my $tmp_data;
    for(1 .. 1000){
	push(@$tmp_data,5.5);
    }
    push(@$data_map_reduce,$tmp_data);
}

# mapper code
my $mapper = sub {
    my $input = shift;
    my $sum = 0;
    my $num = $#$input + 1;
    for(0 .. $#$input){
	$sum += $input->[$_];
    }
    my $avg = $sum / $num;
    return({avg => $avg, sum => $sum, num => $num});
};

# reducer code
my $reducer = sub {
    my $input = shift;
    my $sum = 0;
    my $total_num = 0;
    for(0 .. $#$input){
	$sum += $input->[$_]->{sum};
	$total_num += $input->[$_]->{num};
    }
    my $avg = $sum / $total_num;
    return({avg => $avg, sum => $sum, num => $total_num});
};

my $result = $mfs->map_reduce(
    $data_map_reduce,
    $mapper,
    $reducer,
    4,
    {remote => 0}
   );

cmp_ok($result->{sum},'==', 22000, 'SUM ok');
cmp_ok($result->{avg},'==', 5.5, 'AVG ok');
cmp_ok($result->{num},'==', 4000, 'NUM ok');


done_testing;

