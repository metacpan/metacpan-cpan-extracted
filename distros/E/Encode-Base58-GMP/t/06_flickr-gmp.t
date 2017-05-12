use Test::Base;
use Encode::Base58::GMP;

plan tests => 2 * blocks;

run {
  my $block = shift;
  is Encode::Base58::GMP::base58_flickr_to_gmp($block->from_base58), $block->to_base58;
  is Encode::Base58::GMP::base58_gmp_to_flickr($block->to_base58), $block->from_base58;
};

__DATA__
===
--- from_base58: 4ER
--- from_alphabet: flickr
--- to_base58: 3cn
--- to_alphabet: gmp
