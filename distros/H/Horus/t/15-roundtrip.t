use 5.008003;
use strict;
use warnings;
use Test::More;
use Horus qw(:all);

# Test round-trip: generate -> format -> parse -> format for multiple versions x formats
my @versions = (
    ['v1',  sub { uuid_v1($_[0]) }],
    ['v4',  sub { uuid_v4($_[0]) }],
    ['v7',  sub { uuid_v7($_[0]) }],
    ['nil', sub { uuid_nil($_[0]) }],
    ['max', sub { uuid_max($_[0]) }],
);

my @formats = (
    ['STR',       UUID_FMT_STR],
    ['HEX',       UUID_FMT_HEX],
    ['BRACES',    UUID_FMT_BRACES],
    ['URN',       UUID_FMT_URN],
    ['BASE64',    UUID_FMT_BASE64],
    ['BINARY',    UUID_FMT_BINARY],
    ['UPPER_STR', UUID_FMT_UPPER_STR],
    ['UPPER_HEX', UUID_FMT_UPPER_HEX],
);

plan tests => scalar(@versions) * scalar(@formats);

for my $v (@versions) {
    my ($vname, $gen) = @$v;
    for my $f (@formats) {
        my ($fname, $fmt) = @$f;
        my $formatted = $gen->($fmt);
        my $binary = uuid_parse($formatted);
        my $reformatted = uuid_convert($binary, $fmt);
        is($reformatted, $formatted, "roundtrip: $vname x $fname");
    }
}
