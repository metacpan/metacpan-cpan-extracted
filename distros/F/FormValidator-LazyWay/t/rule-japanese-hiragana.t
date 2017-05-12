use FindBin;
use File::Spec;
use lib File::Spec->catfile( $FindBin::Bin, 'lib' );
use utf8;

use FormValidator::LazyWay::Rule::Japanese;
use MyTestBase;

plan tests => 1 * blocks;

run {
    my $block  = shift;
    my $result = FormValidator::LazyWay::Rule::Japanese::hiragana( $block->value, $block->args );
    is( $result, $block->result );
}

__END__

=== ok
--- value chomp
あいうえお
--- result chomp
1
=== space ok
--- value chomp
あいう　えお
--- args yaml
allow:
  - '　'
--- result chomp
1
=== KATAKANA-HIRAGANA PROLONGED SOUND MARK ok
--- value chomp
うっうー
--- args yaml
allow:
  - ー
--- result chomp
1
=== numbers not ok
--- value chomp
１２３４５６７８９０
--- args yaml
flagged: 1
allow:
--- result chomp
0
=== katakana not ok
--- value chomp
アイウエオ
--- result chomp
0
=== not ok
--- value  chomp
123 44567
--- result chomp
0

