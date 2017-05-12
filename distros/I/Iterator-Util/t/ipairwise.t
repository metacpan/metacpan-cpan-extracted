use strict;
use Test::More tests => 2;
use Iterator::Util;

# Check that ipairwise works as promised.


sub begins_with
{
    my ($actual, $expected, $test_name) = @_;

    $actual = substr($actual, 0, length $expected);
    @_ =  ($actual, $expected, $test_name);
    goto &is;
}

my ($iter, @vals);

# ipairwise (2)
eval
{
    no warnings 'once';

    my $first  = irange 1;                              # 1,  2,  3,  4, ...
    my $second = irange 4, undef, 2;                    # 4,  6,  8, 10, ...
    my $third  = ipairwise {$a * $b} $first, $second;   # 4, 12, 24, 40, ...

    push @vals, $third->value  for (1..4)
};

is $@, q{},   q{Created ipairwise iterator, no errors};
is_deeply (\@vals, [4, 12, 24, 40], q{ipairwise returned expected values});

