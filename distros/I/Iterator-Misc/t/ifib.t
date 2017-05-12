use strict;
use Test::More tests => 6;
use Iterator::Misc;

my ($iter, @vals);

# inth with invalid input
my $countval = 0;
my $count = Iterator->new(sub {$countval++});


# No args

@vals = ();
eval
{
    $iter = ifibonacci();
    push @vals, $iter->value() for 1..10;
};
is ($@, q{}, q{No error in normal operation});
is_deeply (\@vals, [1, 1, 2, 3, 5, 8, 13, 21, 34, 55], q{ifibonacci returned expected values});

# One arg
@vals = ();
eval
{
    $iter = ifibonacci(2);
    push @vals, $iter->value() for 1..10;
};
is ($@, q{}, q{No error in normal operation});
is_deeply (\@vals, [2, 2, 4, 6, 10, 16, 26, 42, 68, 110], q{ifibonacci returned expected values});

# Two args
@vals = ();
eval
{
    $iter = ifibonacci(1,3);
    push @vals, $iter->value() for 1..10;
};
is ($@, q{}, q{No error in normal operation});
is_deeply (\@vals, [1, 3, 4, 7, 11, 18, 29, 47, 76, 123], q{ifibonacci returned expected values});

