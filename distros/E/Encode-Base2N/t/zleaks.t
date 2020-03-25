use 5.012;
use warnings;
use Encode::Base2N qw/
    encode_base64 encode_base64url encode_base64pad decode_base64
    encode_base32 encode_base32low decode_base32 encode_base16 encode_base16low decode_base16
/;

use Test::More;

plan skip_all => 'set TEST_FULL=1 to enable leaks test' unless $ENV{TEST_FULL};

my $ok = eval {
    require BSD::Resource;
    1;
};

plan skip_all => 'FreeBSD System and installed BSD::Resource required to test for leaks' unless $ok;

my $measure = 200;
my $leak = 0;

my @a = 1..100;
undef @a;

my $str = join('', map {chr($_)} 0..255);
$str = $str x 100;

for (my $i = 0; $i < 500; $i++) {
    my $t; my $r;

    $t = encode_base64($str);
    $t = encode_base64url($str);
    $t = encode_base64pad($str);
    $r = decode_base64($t);

    $t = encode_base32($str);
    $t = encode_base32low($str);
    $r = decode_base32($t);

    $t = encode_base16($str);
    $t = encode_base16low($str);
    $r = decode_base16($t);

    $measure = BSD::Resource::getrusage()->{"maxrss"} if $i == 100;
}

$leak = BSD::Resource::getrusage()->{"maxrss"} - $measure;
my $leak_ok = $leak < 100;
warn("LEAK DETECTED: ${leak}Kb") unless $leak_ok;
ok($leak_ok);

done_testing();
