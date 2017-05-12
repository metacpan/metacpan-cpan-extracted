use Test::Base;
use Encode::Base58::GMP;

plan tests => 2 * blocks;

run {
  my $block = shift;
  is Encode::Base58::GMP::base58_from_to($block->from_base58,$block->from_alphabet,$block->to_alphabet), $block->to_base58;
  is Encode::Base58::GMP::base58_from_to($block->to_base58,$block->to_alphabet,$block->from_alphabet), $block->from_base58;
};

__DATA__
===
--- from_base58: 4ER
--- from_alphabet: flickr
--- to_base58: 3cn
--- to_alphabet: gmp

===
--- from_base58: 4fr
--- from_alphabet: bitcoin
--- to_base58: 3cn
--- to_alphabet: gmp

===
--- from_base58: 4ER
--- from_alphabet: flickr
--- to_base58: 4fr
--- to_alphabet: bitcoin
