use strict;
use warnings;

use Test::More skip_all => 'unsupported';

use DateTimeX::Moment;

no warnings 'redefine';
local *DateTime::_core_time = sub {0};

my $dt = DateTimeX::Moment->now;

is(
    "$dt",
    '1970-01-01T00:00:00',
    'overriding DateTime::_core_time() works'
);

done_testing();
