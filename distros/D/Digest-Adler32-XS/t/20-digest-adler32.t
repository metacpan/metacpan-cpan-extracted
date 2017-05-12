#!perl -w

use strict;
use Test::More tests => 10;

# These tests are copied more or less verbatim from Digest::Adler32, so that we can
# check that the API is more or less correct and unchanged. 

use Digest::Adler32::XS;

my $a32 = Digest::Adler32::XS->new;
is($a32->hexdigest, "00000001");
is($a32->hexdigest, "00000001");

$a32->add("a");
is($a32->hexdigest, "00620062");
is($a32->hexdigest, "00000001"); # reset

$a32->add("abc");
is($a32->hexdigest, "024d0127");

$a32->add("abc");
$a32->add("abc");

is($a32->hexdigest, "080c024d");
$a32->add("abcabc");
is($a32->hexdigest, "080c024d");

$a32->add("base64");
is($a32->b64digest, "B9ICBg");
is($a32->b64digest, "AAAAAQ");  # reset

$a32->add("\xFF" x 32);
is($a32->hexdigest, "0e2e1fe1");
