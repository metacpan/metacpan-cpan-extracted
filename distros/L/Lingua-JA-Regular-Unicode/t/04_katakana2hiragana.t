use utf8;
use strict;
use warnings;
use Test::More;
use Data::Section::TestBase;

use Lingua::JA::Regular::Unicode;

for my $block (blocks) {
    is katakana2hiragana($block->input), $block->expected;
}
done_testing;

__END__

===
--- input:    およよＡＢＣＤＥＦＧｂｆｅge１２３123オヨヨｵﾖﾖ
--- expected: およよＡＢＣＤＥＦＧｂｆｅge１２３123およよおよよ

