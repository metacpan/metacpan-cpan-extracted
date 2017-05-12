use strict;
use Test::More tests => 2;
use Iterator::Util;

# Check that iappend works as promised.

sub begins_with
{
    my ($actual, $expected, $test_name) = @_;

    $actual = substr($actual, 0, length $expected);
    @_ =  ($actual, $expected, $test_name);
    goto &is;
}

my ($iter, @vals);

# iappend (2)
eval
{
    my $it1 = irange 1,3;
    my $it2 = irange 20,30,8;
    my $it3 = irange 110, 100, -5;
    $iter = iappend $it1, $it2, $it3;

    push @vals, $iter->value  while $iter->isnt_exhausted;
};

is $@, q{},   q{Created iappend iterator, no errors};
is_deeply (\@vals, [1, 2, 3, 20, 28, 110, 105, 100], q{iappend returned expected values});

