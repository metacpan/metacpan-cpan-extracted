#!perl -T
use 5.006;
use strict;
use warnings FATAL => 'all';
use Test::More;
use Digest::SipHash qw/:all/;
use constant USE64BITINT => eval { pack 'Q', 1 };
plan tests => 4;

my $key = pack 'C16', 0..0xf;
my $str = "hello, world!";
is siphash($str, $key), 0x10cf32e0, 'siphash';
is siphash32($str, $key), 0x10cf32e0, 'siphash32';
my ($lo, $hi) = siphash($str, $key); # 0x7da9cd17, 0x10cf32e0
ok $lo == 0x10cf32e0 && $hi == 0x7da9cd17, 'siphash in list context';
SKIP:{
    skip "64-bit int unsupported", 1 unless USE64BITINT;
    eval {
        my $u64 = siphash64($str, $key);
        # 0x7da9cd1710cf32e0
        is $u64, 9054994024755049184, 'siphash64';
    };
}
