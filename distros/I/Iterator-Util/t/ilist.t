use strict;
use Test::More tests => 3;
use Iterator::Util;

# Check that ilist works as promised.

sub begins_with
{
    my ($actual, $expected, $test_name) = @_;

    $actual = substr($actual, 0, length $expected);
    @_ =  ($actual, $expected, $test_name);
    goto &is;
}

my ($iter, $x, @vals);

@vals = (1, 2, 'foo', [qw/a b c/]);

# ilist (3)
eval
{
    $iter = ilist @vals;
};

$x = $@;
is $x, q{},   q{Created ilist iterator, no errors};
@vals = ();

eval
{
    push @vals, $iter->value  while $iter->isnt_exhausted;
};
is $x, q{},   q{Executed ilist iterator, no errors};
is_deeply (\@vals, [1, 2, 'foo', [qw/a b c/]], q{ilist returned expected values});

