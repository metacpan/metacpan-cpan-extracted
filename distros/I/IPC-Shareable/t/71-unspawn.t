use warnings;
use strict;

unless ( $ENV{RELEASE_TESTING} ) {
    # Some systems don't have IPC::Semaphore pre-installed, so
    # because IPC::Shareable isn't installed when this test runs,
    # the former software isn't available for t/_spawm to initiate
    # a shared memory segment
#    plan( skip_all => "Author test: RELEASE_TESTING not set" );
}

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
