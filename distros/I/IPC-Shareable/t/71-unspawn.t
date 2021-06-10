use warnings;
use strict;

use Data::Dumper;
use IPC::Shareable;
use Test::More;

system "perl t/_spawn";

tie my %h, 'IPC::Shareable', {
    key       => 'aaaa',
#    destroy   => 1,
    mode      => 0666,
};

is $h{t70}->[1], 5, "hash element ok";

IPC::Shareable->unspawn('aaaa');

is %h, 1, "hash still exists with unspawn and no destroy";

done_testing();
