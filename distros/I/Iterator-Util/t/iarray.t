use strict;
use Test::More tests => 6;
use Iterator::Util;

# Check that iarray works as promised.

sub begins_with
{
    my ($actual, $expected, $test_name) = @_;

    $actual = substr($actual, 0, length $expected);
    @_ =  ($actual, $expected, $test_name);
    goto &is;
}

my ($iter, $x, @vals, @reported);

@vals = (1, 2, 'foo', [qw/a b c/]);

# basic iarray. (3)
eval
{
    $iter = iarray \@vals;
};

is $@, q{},   q{Created iarray iterator, no errors};
@reported = ();

eval
{
    push @reported, $iter->value  while $iter->isnt_exhausted;
};
is $@, q{},   q{Executed array iterator, no errors};
is_deeply (\@reported, [1, 2, 'foo', [qw/a b c/]], q{iarray returned expected values});


# changing iarray. (3)
eval
{
    $iter = iarray \@vals;
};

is $@, q{},   q{Created iarray iterator, no errors};
@reported = ();

eval
{
    push @reported, $iter->value  for (1..3);
    # Change the underlying array:
    push @vals, 'Mark Jason Dominus is God';
    $vals[0] = '666';
    push @reported, $iter->value  while $iter->isnt_exhausted;
};
is $@, q{},   q{Executed array iterator, no errors};
is_deeply (\@reported, [1, 2, 'foo', [qw/a b c/], q{Mark Jason Dominus is God}],
           q{iarray returned expected values});

