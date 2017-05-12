use strict;
use warnings;
use utf8;
use Lingua::JA::Regular::Unicode;
use Test::More;
use Data::Section::TestBase;

for my $block (blocks) {
    is hiragana2katakana($block->input), $block->expected;
}
done_testing;

__END__

===
--- input:    およよＡＢＣＤＥＦＧｂｆｅge１２３123オヨヨｵﾖﾖ
--- expected: オヨヨＡＢＣＤＥＦＧｂｆｅge１２３123オヨヨｵﾖﾖ

