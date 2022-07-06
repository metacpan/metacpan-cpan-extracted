#! perl

use Test::More
    tests => 5;

use Digest::BLAKE3;

my($hasher, $key, $context);

$hasher = Digest::BLAKE3::->new();
$key = "x" x 32;
$context = "context";

#
# hit every croak
#

eval {
    $hasher->new_keyed_hash($key."x");
};
like($@, qr/Invalid key length/,
    "bad key length");

eval {
    $hasher->hashsize(7);
};
like($@, qr/Hash size must be a positive multiple of 8 bits/,
    "bad hash size");

#
# feed wide characters to every SvPVbyte
#

eval {
    $hasher->new_keyed_hash("\x{100}" x 16);
};
like($@, qr/Wide character in subroutine entry/,
    "wide character in key");

eval {
    $hasher->new_derive_key("\x{100}");
};
like($@, qr/Wide character in subroutine entry/,
    "wide character in context");

eval {
    $hasher->new_hash()->add("\x{100}");
};
like($@, qr/Wide character in subroutine entry/,
    "wide character in input");

