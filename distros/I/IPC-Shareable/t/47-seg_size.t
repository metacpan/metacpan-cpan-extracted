use warnings;
use strict;

use Config;
use IPC::Shareable;
use Test::More;

BEGIN {
    if ($Config{ivsize} < 8) {
        plan skip_all => "This test script can't be run on a perl < 64-bit";
    }
}

my $segs_before = IPC::Shareable::seg_count();
my $sems_before = IPC::Shareable::sem_count();
warn "Segs Before: $segs_before\n" if $ENV{PRINT_SEGS};

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
{
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

my $segs_after = IPC::Shareable::seg_count();
warn "Segs After: $segs_after\n" if $ENV{PRINT_SEGS};
is $segs_after, $segs_before, "All segs cleaned up ok";
my $sems_after = IPC::Shareable::sem_count();
is $sems_after, $sems_before, "All semaphore sets cleaned up ok";

done_testing();
