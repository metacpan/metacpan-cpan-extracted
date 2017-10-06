use strict;
use warnings;
use Benchmark qw/:all/;
use List::ToHash;
use List::Util;

my @ARRAY;
for my $i (1..100) {
    push @ARRAY, {
        id    => $i,
        value => '.' x 100,
    };
}

cmpthese(timethese(0, {
    map => sub {
        my $x = +{map { ($_->{id} => $_) } @ARRAY};
    },
    reduce => sub {
        my $x = List::Util::reduce { $a->{$b->{id}} = $b; $a } ({}, @ARRAY);
    },
    for => sub {
        my $x = {};
        $x->{$_->{id}} = $_ for @ARRAY;
        $x;
    },
    to_hash => sub {
        my $x = List::ToHash::to_hash { $_->{id} } @ARRAY;
    },
}));

__END__
Benchmark: running for, map, reduce, to_hash for at least 3 CPU seconds...
       for:  3 wallclock secs ( 3.18 usr +  0.01 sys =  3.19 CPU) @ 19303.13/s (n=61577)
       map:  3 wallclock secs ( 3.13 usr +  0.02 sys =  3.15 CPU) @ 13437.46/s (n=42328)
    reduce:  3 wallclock secs ( 3.20 usr +  0.02 sys =  3.22 CPU) @ 18504.66/s (n=59585)
   to_hash:  4 wallclock secs ( 3.12 usr +  0.01 sys =  3.13 CPU) @ 26635.78/s (n=83370)
           Rate     map  reduce     for to_hash
map     13437/s      --    -27%    -30%    -50%
reduce  18505/s     38%      --     -4%    -31%
for     19303/s     44%      4%      --    -28%
to_hash 26636/s     98%     44%     38%      --
