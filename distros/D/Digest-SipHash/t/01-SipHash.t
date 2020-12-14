#!perl -T
use 5.006;
use strict;
use warnings FATAL => 'all';
use Test::More;
use Digest::SipHash qw/:all/;
use constant USE64BITINT => eval { pack 'Q', 1 };
plan tests => 10;

my $key = pack 'C16', 0..0xf;
my $str = "hello, world!";
is siphash($str, $key), 0x10cf32e0, 'siphash';
is siphash32($str, $key), 0x10cf32e0, 'siphash32';
my ($lo, $hi) = siphash($str, $key); # 0x7da9cd17, 0x10cf32e0
ok $lo == 0x10cf32e0 && $hi == 0x7da9cd17, 'siphash in list context';
my @want=(3953067663,4241456352,381165788,1094629927);
for my $i (0..3) {
    my $hash= siphash($i,$key);
    is $hash, $want[$i];
}
SKIP:{
    skip "64-bit int unsupported", 1 unless USE64BITINT;
    eval {
        my $u64 = siphash64($str, $key);
        # 0x7da9cd1710cf32e0
        is $u64, 9054994024755049184, 'siphash64';
    };
}

# test that we hash utf8 and non-utf8 consistently
my $an_interesting_case= "\xDF";
my $h1= siphash($an_interesting_case,$key);
utf8::upgrade($an_interesting_case);
my $h2= siphash($an_interesting_case,$key);
is $h1,$h2, "We hash consistently regardless of utf8";
my $h3= siphash($an_interesting_case,$key,1);
isnt $h1,$h3, "We hash inconsistently at request";
