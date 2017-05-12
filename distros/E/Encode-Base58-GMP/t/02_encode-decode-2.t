use Test::Base;
use Encode::Base58::GMP;
use Math::GMPz   qw(:mpz);

plan tests => 3 * blocks;

run {
  my $block = shift;
  is encode_base58($block->number,$block->alphabet), $block->short;
  is encode_base58(Math::GMPz->new($block->number),$block->alphabet), $block->short;
  is '0x'.Rmpz_get_str(decode_base58($block->short,$block->alphabet), 16), $block->number;
};

__DATA__
===
--- short: qiqNGFVCn6XWrbVfDEN8Z6
--- number: 0xc4ca4238a0b923820dcc509a6f75849b

===
--- short: qHgBRE77crtf1qscK1riGQ
--- number: 0xc81e728d9d4c2f636f067f89cc14862c

===
--- short: veXjDd3HMGfqiZFppbjAox
--- number: 0xeccbc87e4b5ce2fe28308fd9f2a7baf3

===
--- short: mNP25cxkn3biDAAvRtEag3
--- number: 0xa87ff679a2f3e71d9181a67b7542122c

===
--- short: ug4yqTNQ9Yi86qiHug6xXc
--- number: 0xe4da3b7fbbce2345d7772b0674a318d5

===
--- short: OHOkedraL5tsPArEbck7v5
--- number: 0xc4ca4238a0b923820dcc509a6f75849b
--- alphabet: gmp

===
--- short: OfFZnc66BPRE0OQBh0PHem
--- number: 0xc81e728d9d4c2f636f067f89cc14862c
--- alphabet: gmp

===
--- short: TDtIbC2fjeEOHvdNNAIYMV
--- number: 0xeccbc87e4b5ce2fe28308fd9f2a7baf3
--- alphabet: gmp

===
--- short: Kkl14BVJL2AHbYYTnRc9F2
--- number: 0xa87ff679a2f3e71d9181a67b7542122c
--- alphabet: gmp

===
--- short: SF3WOpkm8uH75OHfSF5VtB
--- number: 0xe4da3b7fbbce2345d7772b0674a318d5
--- alphabet: gmp
