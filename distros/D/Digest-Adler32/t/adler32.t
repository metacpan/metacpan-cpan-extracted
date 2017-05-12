#!perl -w

use strict;
use Test qw(plan ok);

plan tests => 10;

use Digest::Adler32;

my $a32 = Digest::Adler32->new;
ok($a32->hexdigest, "00000001");
ok($a32->hexdigest, "00000001");

$a32->add("a");
ok($a32->hexdigest, "00620062");
ok($a32->hexdigest, "00000001"); # reset

$a32->add("abc");
ok($a32->hexdigest, "024d0127");

$a32->add("abc");
$a32->add("abc");
ok($a32->hexdigest, "080c024d");

$a32->add("abcabc");
ok($a32->hexdigest, "080c024d");

$a32->add("base64");
ok($a32->b64digest, "B9ICBg");
ok($a32->b64digest, "AAAAAQ");  # reset

$a32->add("\xFF" x 32);
ok($a32->hexdigest, "0e2e1fe1");
