use Test::More;
use strict;
use warnings;
use Math::Basic::XS qw/all/;

my $sum = sum { $_ } 1, 2, 3, 4, 5;
is($sum, 15);

$sum = sum { $_ } 1, 2, 3, 4, 5;

is($sum, 15);

$sum = sum { return $_->{inner} } bless({ inner => 1 }, 'Test'), { inner => 2 }, { inner => 3 }, { inner => 4 };

is($sum, 10);

my $min = min { $_ } 1, 2, 3, 4, 5;

is($min, 1);

$min = min { $_->{inner} } { inner => 1 }, { inner => 2 }, { inner => 3 }, { inner => 4 };

is($min, 1);

my $max = max { $_ } 1, 2, 3, 4, 5;

is($max, 5);

$max = max { $_->{inner} } { inner => 1 }, { inner => 2 }, { inner => 3 }, { inner => 4 };

is($max, 4);

my $mean = mean { $_ } 1, 2, 3, 4, 5;

is($mean, 3);

$mean = mean { $_->{inner} } { inner => 1 }, { inner => 2 }, { inner => 3 }, { inner => 4 };

is($mean, 2.5);

my $median = median { $_ } 1, 2, 3, 4, 5;

is($median, 3);

$median = median { $_->{inner} } { inner => 1 }, { inner => 2 }, { inner => 3 }, { inner => 3 };

is($median, 3);

my $mode = mode { $_ } 1, 2, 2, 4, 5;

is($mode, 2);

$mode = mode { $_->{inner} } { inner => 3 }, { inner => 2 }, { inner => 3 }, { inner => 4 };

is($mode, 3);

done_testing();
