use strict;
use warnings;
use Test::More;
use List::Flatten::XS 'flatten';

# More return values than the argument stack initially has room for.
my $input = [];
push @$input, $_ for 1 .. 10000;
for my $level (-1, 0, 1) {
    my @got = flatten($input, $level);
    is_deeply(\@got, $input, "large list at level $level");
}

my @nested = flatten([[1 .. 5000], [5001 .. 10000]]);
is_deeply(\@nested, $input, 'large flattened list with default depth');

my @empty = flatten([]);
is_deeply(\@empty, [], 'empty list');
my @single = flatten([42]);
is_deeply(\@single, [42], 'single element');
is_deeply(scalar flatten([[1, 2], [3]]), [1, 2, 3], 'scalar context');

done_testing;
