use warnings;
use strict;

use Config;
use IPC::Shareable;
IPC::Shareable->testing_set('IPC::Shareable');
use Test::More;

use FindBin;
use lib $FindBin::Bin;
use IPCShareableTest qw(assert_clean_process);

BEGIN {
    if ($Config{ivsize} < 8) {
        plan skip_all => "This test script can't be run on a perl < 64-bit";
    }
}


use constant BYTES => 2000000; # ~2MB

# limit
{
    my $size_ok_limit = eval {
        tie my $var, 'IPC::Shareable', {
            create  => 1,
            size    => 2_000_000_000,
            destroy => 1,
            serializer => 'storable',
        };
        1;
    };

    is $size_ok_limit, undef, "size larger than MAX croaks ok";
    like $@, qr/larger than max size/, "...and error is sane";

    if ($ENV{IPC_MEM}) {
        my $size_ok_no_limit = eval {
            tie my $var, 'IPC::Shareable', {
                limit   => 0,
                create  => 1,
                size    => 2_000_000_000,
                destroy => 1,
                serializer => 'storable',
            };
            1;
        };

        is $size_ok_no_limit, 1, "size larger than MAX succeeeds with limit=>0 ok";
    }
    else {
        warn "IPC_MEM env var not set, skipping the exhaust memory test\n";
    }
}

# beyond RAM limits
#
# With limit => 0 the module's own size guard is disabled, so this relies on
# the OS rejecting an absurdly large segment. That only holds where size_t is
# 64-bit: on a 32-bit size_t (eg. i686 perls built with use64bitint, whose
# ivsize is 8 so the skip at the top of this file does not catch them) the
# requested size wraps modulo 2**32 to an allocatable value and the tie
# succeeds, so skip these two checks there.
SKIP: {
    skip "32-bit size_t wraps a > 4 GB segment size instead of failing", 2
        if $Config{sizesize} < 8;

    my $size_ok = eval {
        tie my $var, 'IPC::Shareable', {
            limit   => 0,
            size    => 999999999999,
            destroy => 1,
            serializer => 'storable',
        };
        1;
    };

    is $size_ok, undef, "We croak if size is greater than max RAM";

    like $@, qr/Could not (?:create|acquire) shared memory/, "...and error is sane";
}

my $k = tie my %hv, 'IPC::Shareable', {
    create => 1,
    destroy => 1,
    size => BYTES,
    serializer => 'storable',
};

my $seg = $k->seg;

my $id   = $seg->id;
my $size = $seg->size;

my $actual_size;

if ($^O eq 'linux') {
    my $record = `ipcs -m -i $id`;
    $actual_size = 0;

    if ($record =~ /bytes=(\d+)/s) {
        $actual_size = $1;
    }
}
else {
    $actual_size = 0;
}

is BYTES, $size, "size param is the same as the segment size";

# ipcs -i doesn't work on MacOS or FreeBSD, so skip it for now

TODO: {
    local $TODO = 'Not yet working on FreeBSD or macOS';
};

# ...and only run it on Linux systems

if ($^O eq 'linux') {
    is $size, $actual_size, "actual size in bytes ok if sending in custom size";
}

$k->clean_up_all;

IPC::Shareable::_end;

assert_clean_process();

done_testing();
