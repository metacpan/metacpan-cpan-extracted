use Test::Base;
use Encode::Base32::GMP qw( md5_base32 );

my $blocks = Test::Base->new;

$blocks->delimiters(qw(=== ---))->spec_file('./t/02_md5-base32.tb');

plan tests => 6 * $blocks->blocks;

for my $block ($blocks->blocks) {
  is md5_base32($block->data), $block->b32crockford;
  is md5_base32($block->data,'crockford'), $block->b32crockford;
  is md5_base32($block->data,'rfc4648'), $block->b32rfc;
  is md5_base32($block->data,'zbase32'), $block->b32z32;
  is md5_base32($block->data,'base32hex'), $block->b32gmp;
  is md5_base32($block->data,'gmp'), $block->b32gmp;
};