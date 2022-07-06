#! perl

use Test::More
    tests => 6;

use Digest::BLAKE3;

my($hasher, $key, $context);

$key = "x" x 32;
$context = "context";
$hasher = Digest::BLAKE3::->new_hash();

is($hasher->hashsize(504), 256,
   "default hash size");

is($hasher->hashsize(8), 504,
   "extended hash size");

is($hasher->hashsize(), 8,
   "truncated hash size");

is($hasher->mode(), "hash",
   "hash mode");

$hasher->new_keyed_hash($key);

is($hasher->mode(), "keyed_hash",
   "keyed hash mode");

$hasher->new_derive_key($context);

is($hasher->mode(), "derive_key",
   "key derivation mode");

