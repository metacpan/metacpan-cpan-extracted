use strict;
use warnings;
use Test::More;
use Digest::GOST qw(gost gost_hex);

my @tests = <DATA>;
push @tests, 'U' x 128 . '|'
    . '53a3a3ed25180cef0c1d85a074273e551c25660a87062a52d926a9e8fe5733a4';
push @tests, 'a' x 1_000_000 . '|'
    . '5c00ccc2734cdd3332d3d4749576e3c1a7dbaf0e7ea74e9fa602413c90a129fa';

for my $test (@tests) {
    chomp $test;
    my ($msg, $digest) = split '\|', $test, 2;
    $digest = lc $digest;

    my $md = Digest::GOST->new()->add($msg)->hexdigest;
    (my $show_msg = $msg) =~ s/^(.{20}).*/$1.../;
    is($md, $digest, "new/add/hexdigest: $show_msg");
    is(gost_hex($msg), $digest, "gost_hex: $show_msg");
    ok(gost($msg) eq pack('H*', $digest), "gost: $show_msg");
}

done_testing;

__DATA__
|ce85b99cc46752fffee35cab9a7b0278abb4c2d2055cff685af4912c49490f8d
a|d42c539e367c66e9c88a801f6649349c21871b4344c6a573f849fdce62f314dd
message digest|ad4434ecb18f2c99b60cbe59ec3d2469582b65273f48de72db2fde16a4889a4d
This is message, length=32 bytes|b1c466d37519b82e8319819ff32595e047a28cb6f83eff1c6916a815a637fffa
The quick brown fox jumps over the lazy cog|a3ebc4daaab78b0be131dab5737a7f67e602670d543521319150d2e14eeec445
The quick brown fox jumps over the lazy dog|77b7fa410c9ac58a25f49bca7d0468c9296529315eaca76bd1a10f376d1f4294
Suppose the original message has length = 50 bytes|471aba57a60a770d3a76130635c1fbea4ef14de51f78b4ae57dd893b62f55208
