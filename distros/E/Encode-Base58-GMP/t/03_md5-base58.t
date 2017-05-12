use Test::Base;
use Encode::Base58::GMP qw( md5_base58 );

my $blocks = Test::Base->new;

$blocks->delimiters(qw(=== ---))->spec_file('./t/03_md5-base58.tb');

plan tests => 1 * $blocks->blocks;

for my $block ($blocks->blocks) {
  is md5_base58($block->data), $block->md5_base58;
};

