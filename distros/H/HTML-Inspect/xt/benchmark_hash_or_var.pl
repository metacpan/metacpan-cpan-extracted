use strict;
use warnings;
use utf8;
use Benchmark;

=pod

Which is  faster, accessing a variable or a hash value by key?
Here is the output on my computer

Benchmark: timing 90000000 iterations of HASH_VALUE, LOCAL_VAR...
HASH_VALUE:  2 wallclock secs ( 1.67 usr +  0.00 sys =  1.67 CPU) @ 53892215.57/s (n=90000000)
 LOCAL_VAR: -1 wallclock secs ( 0.33 usr +  0.00 sys =  0.33 CPU) @ 272727272.73/s (n=90000000)
            (warning: too few iterations for a reliable count)

Below is the benchmark.

=cut

my $hash = {a => 1, b => 2, c => 3, d => 4, e => 5};
my $c    = $hash->{c};
timethese(
    90000000,
    {
        'LOCAL_VAR' => sub {
            return $c;
        },
        'HASH_VALUE' => sub {
            return $hash->{c};
        },
    }
);


