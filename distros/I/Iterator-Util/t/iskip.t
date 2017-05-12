use strict;
use Test::More tests => 4;
use Iterator::Util;

# Check that iskip works as promised.

sub begins_with
{
    my ($actual, $expected, $test_name) = @_;

    $actual = substr($actual, 0, length $expected);
    @_ =  ($actual, $expected, $test_name);
    goto &is;
}

my ($iter, @vals);

# iskip (2)
@vals = ();
eval
{
    $iter = iskip 5, irange 8;
    push @vals, $iter->value  for (1..4);
};

is $@, q{},   q{Created iskip iterator, no errors};
is_deeply (\@vals, [13, 14, 15, 16], q{iskip returned expected values.});


# iskip_until (2)
@vals = ();
eval
{
    $iter = iskip_until {$_ % 5 == 0}  irange 8;
    push @vals, $iter->value  for (1..4);
};

is $@, q{},   q{Created iskip_until iterator, no errors};
is_deeply (\@vals, [10, 11, 12, 13], q{iskip_until returned expected values.});

