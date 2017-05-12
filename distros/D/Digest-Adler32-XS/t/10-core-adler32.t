# Test the adler32 implementation extracted from libxdiff.

use strict;
use warnings;

use Test::More tests => 7;

BEGIN {
    use_ok('Digest::Adler32::XS');   
}

is(sprintf("%08x", Digest::Adler32::XS::adler32(1, "")),
   "00000001",
   "Correct digest for empty string");

is(sprintf("%08x", Digest::Adler32::XS::adler32(1, "a")),
   "00620062",
   "Correct digest for string 'a'");

is(sprintf("%08x", Digest::Adler32::XS::adler32(1, "abc")),
   "024d0127",
   "Correct digest for string 'abc'");

is(sprintf("%08x", Digest::Adler32::XS::adler32(1, "abcabc")),
   "080c024d",
   "Correct digest for string 'abcabc'");

is(sprintf("%08x", Digest::Adler32::XS::adler32(1, "\xFF" x 32)),
   "0e2e1fe1",
   "Correct digest for string '\xff' x 32");

my $result = Digest::Adler32::XS::adler32(1, "abc");
$result = Digest::Adler32::XS::adler32($result, "abc");
is(sprintf("%08x", $result), "080c024d", "Correct digest for string 'abcabc'");

1;