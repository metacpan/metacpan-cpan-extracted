use strict;
use warnings;
use Test::More;
use Digest::GOST::CryptoPro qw(gost gost_hex);

my @tests = <DATA>;
push @tests, 'U' x 128 . '|'
    . '1c4ac7614691bbf427fa2316216be8f10d92edfd37cd1027514c1008f649c4e8';
push @tests, 'a' x 1_000_000 . '|'
    . '8693287aa62f9478f7cb312ec0866b6c4e4a0f11160441e8f4ffcd2715dd554f';
push @tests, join '', 'A'..'Z', 'a'..'z', 0..9, '|',
    . '73b70a39497de53a6e08c67b6d4db853540f03e9389299d9b0156ef7e85d0f61';
push @tests, 1234567890 x 8 . '|'
    . '6bc7b38989b28cf93ae8842bf9d752905910a7528a61e5bce0782de43e610c90';

for my $test (@tests) {
    chomp $test;
    my ($msg, $digest) = split '\|', $test, 2;
    $digest = lc $digest;

    my $md = Digest::GOST::CryptoPro->new()->add($msg)->hexdigest;
    (my $show_msg = $msg) =~ s/^(.{20}).*/$1.../;
    is($md, $digest, "new/add/hexdigest: $show_msg");
    is(gost_hex($msg), $digest, "gost_hex: $show_msg");
    ok(gost($msg) eq pack('H*', $digest), "gost: $show_msg");
}

done_testing;

__DATA__
|981e5f3ca30c841487830f84fb433e13ac1101569b9c13584ac483234cd656c0
a|e74c52dd282183bf37af0079c9f78055715a103f17e3133ceff1aacf2f403011
abc|b285056dbf18d7392d7677369524dd14747459ed8143997e163b2986f92fd42c
message digest|bc6041dd2aa401ebfa6e9886734174febdb4729aa972d60f549ac39b29721ba0
The quick brown fox jumps over the lazy dog|9004294a361a508c586fe53d1f1b02746765e71b765472786e4770d565830a76
This is message, length=32 bytes|2cefc2f7b7bdc514e18ea57fa74ff357e7fa17d652c75f69cb1be7893ede48eb
Suppose the original message has length = 50 bytes|c3730c5cbccacf915ac292676f21e8bd4ef75331d9405e5f1a61dc3130a65011
