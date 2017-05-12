use utf8;
use strict;
use warnings;
use Data::Section::TestBase;
use Test::More;
use Lingua::JA::Regular::Unicode;

for my $block (blocks) {
    is katakana_h2z($block->input), $block->expected;
}
done_testing;

__END__

===
--- input:    およよＡＢＣＤＥＦＧｂｆｅge１２３123オヨヨｵﾖﾖ
--- expected: およよＡＢＣＤＥＦＧｂｆｅge１２３123オヨヨオヨヨ

===
--- input:    ｶﾞ
--- expected: ガ

=== middle dots
--- input:    ・･
--- expected: ・・

===
--- input:    ｳ
--- expected: ウ
