use warnings;
use strict;

use IPC::Shareable;
use Test::More;

use constant BYTES => 2000000; # ~2MB

my $k = tie my $sv, 'IPC::Shareable', {
    key => 'TEST',
    create => 1,
    destroy => 1,
    size => BYTES,
};

my $seg = $k->seg;

my $id   = $seg->id;
my $size = $seg->size;

my $record = `ipcs -m -i $id`;
my $actual_size = 0;

if ($record =~ /bytes=(\d+)/s) {
    $actual_size = $1;
}

is BYTES, $size, "size param is the same as the segment size";

# ipcs -i doesn't work on MacOS or FreeBSD, so skip it for now

TODO: {
    local $TODO = 'Not yet working on FreeBSD or macOS';
    is $size, $actual_size, "actual size in bytes ok if sending in custom size";
};

# ...and only run it on Linux systems

if ($^O eq 'linux') {
    is $size, $actual_size, "actual size in bytes ok if sending in custom size";
}

$k->clean_up_all;

done_testing();
