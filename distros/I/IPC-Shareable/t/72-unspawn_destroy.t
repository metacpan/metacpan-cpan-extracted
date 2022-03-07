use warnings;
use strict;

use Config;
use Data::Dumper;
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

tie my %h, 'IPC::Shareable', {
    key       => 'aaaa',
    destroy   => 1,
    mode      => 0666,
};

is $h{t70}->[1], 5, "hash element ok";

IPC::Shareable->unspawn('aaaa', 1);

is %h, '', "hash deleted after calling unspawn() with destroy => 1";

done_testing();
