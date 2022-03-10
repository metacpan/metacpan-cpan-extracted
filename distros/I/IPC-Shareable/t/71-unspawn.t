use warnings;
use strict;

use Config;
use IPC::Shareable;
use Test::More;

BEGIN {
    if (! $ENV{CI_TESTING}) {
        plan skip_all => "Not on a legit CI platform...";
    }
    if ($Config{nvsize} != 8) {
        plan skip_all => "Storable not compatible with long doubles";
    }
}

warn "Segs Before: " . IPC::Shareable::ipcs() . "\n" if $ENV{PRINT_SEGS};

system "$^X t/_spawn";

tie my %h, 'IPC::Shareable', {
    key       => 'aaaa',
#    destroy   => 1,
    mode      => 0666,
};

is $h{t70}->[1], 5, "hash element ok";

IPC::Shareable->unspawn('aaaa');

is %h, 1, "hash still exists with unspawn and no destroy";

IPC::Shareable::_end;
warn "Segs After: " . IPC::Shareable::ipcs() . "\n" if $ENV{PRINT_SEGS};

done_testing();
