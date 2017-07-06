# Tests related to set_tIME and get_tIME functions, which set the
# optional "tIME" chunk of a PNG image.

use warnings;
use strict;
use FindBin '$Bin';
use Image::PNG::Libpng ':all';
use Image::PNG::Const ':all';
use Test::More;

my @fields = (
    "year",
    "month",
    "day",
    "hour",
    "minute",
    "second",
);

# Test using the libpng test suite.

my @tests = (
{
    file => 'cm9n0g04',
    year => 1999,
    month => 12,
    day => 31,
    hour => 23,
    minute => 59,
    second => 59,
},
{
    file => 'cm0n0g04',
    year => 2000,
    month => 1,
    day => 1,
    hour => 12,
    minute => 34,
    second => 56,
},
{
    file => 'cm7n0g04',
    year => 1970,
    month => 1,
    day => 1,
    hour => 0,
    minute => 0,
    second => 0,
},
);

for my $test (@tests) {
    my $png = read_png_file ("$Bin/libpng/$test->{file}.png");
    my $time = $png->get_tIME ();
    ok ($time, "Got time from $test->{file}");
    for my $k (@fields) {
	is ($time->{$k}, $test->{$k}, "Same value for $k");
    }
}

my $png = create_write_struct ();
eval {
    set_tIME ($png);
};
ok (! $@, "set_tIME without a time value");

done_testing ();
