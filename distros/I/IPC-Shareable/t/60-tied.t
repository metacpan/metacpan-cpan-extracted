use warnings;
use strict;

use IPC::Shareable;
use Test::More;

BEGIN {
    if (! $ENV{CI_TESTING}) {
        plan skip_all => "Not on a legit CI platform...";
    }
}

warn "Segs Before: " . IPC::Shareable::ipcs() . "\n" if $ENV{PRINT_SEGS};

tie my %hv, 'IPC::Shareable', {destroy => 1};

$hv{a} = 'foo';

is $hv{a}, 'foo', "data created and set ok";

tied(%hv)->clean_up;

is %hv, '', "data is removed after tied(\$data)->clean_up()";

IPC::Shareable::_end;
warn "Segs After: " . IPC::Shareable::ipcs() . "\n" if $ENV{PRINT_SEGS};

done_testing();
