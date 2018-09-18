#!/usr/bin/env perl
use strict;
use warnings;

use Test::More;

use_ok 'Math::Partition::Rand';

my $obj = Math::Partition::Rand->new(
    top => 1,
    n   => 3,
);
isa_ok $obj, 'Math::Partition::Rand';

my $x = $obj->choose();

is scalar(@$x), 3, 'partition';

my $y = sum(@$x);
is $y, 1, 'sum to 1';

$obj = Math::Partition::Rand->new(
    top => 10,
    n   => 4,
);

$x = $obj->choose();
is scalar(@$x), 4, 'partition';

$y = sum(@$x);
is $y, 10, 'sum to 10';

done_testing();

sub sum {
    my @numbers = @_;
    my $y = 0;
    $y = $y + $_ for @numbers;
    return $y;
}
