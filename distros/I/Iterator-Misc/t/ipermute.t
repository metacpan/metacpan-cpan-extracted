use strict;
use Test::More tests => 8;
use Iterator::Misc;

# Check that ilist works as promised.

sub begins_with
{
    my ($actual, $expected, $test_name) = @_;

    $actual = substr($actual, 0, length $expected);
    @_ =  ($actual, $expected, $test_name);
    goto &is;
}

my $iter;

# ipermute
eval
{
    $iter = ipermute ('one', 'two', 'three');
};

is ($@, q{}, q{No exception when creating ipermute iterator});

is_deeply($iter->value, [qw[one two three]], q{1st iteration: correct values});
is_deeply($iter->value, [qw[one three two]], q{2nd iteration: correct values});
is_deeply($iter->value, [qw[two one three]], q{3rd iteration: correct values});
is_deeply($iter->value, [qw[two three one]], q{4th iteration: correct values});
is_deeply($iter->value, [qw[three one two]], q{5th iteration: correct values});
is_deeply($iter->value, [qw[three two one]], q{6th iteration: correct values});

ok ($iter->is_exhausted, q{Iterator all done now.});

