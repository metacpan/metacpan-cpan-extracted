use warnings;
use strict;

use Config;
use IPC::Shareable;
use Test::More;

if ($Config{nvsize} != 8) {
    plan skip_all => "Storable not compatible with long doubles";
}

system "$^X t/_spawn";

tie my %h, 'IPC::Shareable', {
    key       => 'aaaa',
#    destroy   => 1,
    mode      => 0666,
};

is $h{t70}->[1], 5, "hash element ok";

IPC::Shareable->unspawn('aaaa');

is %h, 1, "hash still exists with unspawn and no destroy";

done_testing();
