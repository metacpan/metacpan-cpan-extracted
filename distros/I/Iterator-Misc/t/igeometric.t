use strict;
use Test::More tests => 10;
use Iterator::Misc;

# Check that igeometric works as promised.

sub begins_with
{
    my ($actual, $expected, $test_name) = @_;

    $actual = substr($actual, 0, length $expected);
    @_ =  ($actual, $expected, $test_name);
    goto &is;
}

my ($iter, $x, @vals);

# Try a factor of 0.   (2)
eval
{
    $iter = igeometric(10, -1, 0);
    push @vals, $iter->value for (1..4);
};

is ($@, q{}, q{igeometric (0) created and executed without error});
is_deeply (\@vals, [10, 0, 0, 0], q{igeometric (0) returned expected values});

# Factor of 1.   (2)
@vals = ();
eval
{
    $iter = igeometric(2, 10, 1);
    push @vals, $iter->value for (1..4);
};

is ($@, q{}, q{igeometric (1) created and executed without error});
is_deeply (\@vals, [2, 2, 2, 2], q{igeometric (1) returned expected values});

# Doubling
@vals = ();
eval
{
    $iter = igeometric(1, 10, 2);
    push @vals, $iter->value while $iter->isnt_exhausted;
};

is ($@, q{}, q{igeometric (2) created and executed without error});
is_deeply (\@vals, [1, 2, 4, 8], q{igeometric (2) returned expected values});

# Halving
@vals = ();
eval
{
    $iter = igeometric(10, 2, 0.5);
    push @vals, $iter->value while $iter->isnt_exhausted;
};

is ($@, q{}, q{igeometric (1/2) created and executed without error});
is_deeply (\@vals, [10, 5, 2.5], q{igeometric (1/2) returned expected values});

# Limitless
@vals = ();
eval
{
    $iter = igeometric(1, undef, 2);
    push @vals, $iter->value for (1..8);
};

is ($@, q{}, q{igeometric (unbounded) created and executed without error});
is_deeply (\@vals, [1, 2, 4, 8, 16, 32, 64, 128], q{igeometric (unbounded) returned expected values});

