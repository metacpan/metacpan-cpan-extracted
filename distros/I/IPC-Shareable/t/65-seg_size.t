use warnings;
use strict;

use Config;
use IPC::Shareable;
use Test::More;

BEGIN {
    if (! $ENV{CI_TESTING}) {
        plan skip_all => "Not on a legit CI platform...";
    }
    if ($Config{ivsize} < 8) {
        plan skip_all => "This test script can't be run on a perl < 64-bit";
    }
}

warn "Segs Before: " . IPC::Shareable::ipcs() . "\n" if $ENV{PRINT_SEGS};

use constant BYTES => 2000000; # ~2MB

# limit
{
    my $size_ok_limit = eval {
        tie my $var, 'IPC::Shareable', {
            create  => 1,
            size    => 2_000_000_000,
            destroy => 1
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
                destroy => 1
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
            destroy => 1
        };
        1;
    };

    is $size_ok, undef, "We croak if size is greater than max RAM";

    like $@, qr/Cannot allocate memory|Out of memory|Invalid argument/, "...and error is sane";
}

my $k = tie my $sv, 'IPC::Shareable', {
    create => 1,
    destroy => 1,
    size => BYTES,
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
warn "Segs After: " . IPC::Shareable::ipcs() . "\n" if $ENV{PRINT_SEGS};

done_testing();
