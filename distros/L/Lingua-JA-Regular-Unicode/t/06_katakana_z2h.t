use utf8;
use strict;
use warnings;
use Data::Section::TestBase;
use Test::More;
use utf8;
use Lingua::JA::Regular::Unicode;

for my $block (blocks) {
    is katakana_z2h($block->input), $block->expected;
}
done_testing;

__END__

===
--- input:    およよＡＢＣＤＥＦＧｂｆｅge１２３123オヨヨｵﾖﾖ
--- expected: およよＡＢＣＤＥＦＧｂｆｅge１２３123ｵﾖﾖｵﾖﾖ

===
--- input:    ガ
--- expected: ｶﾞ

