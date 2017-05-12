use utf8;
use strict;
use warnings;
use Lingua::JA::Regular::Unicode;
use Data::Section::TestBase;
use Test::More;

for my $block (blocks()) {
    is alnum_z2h($block->input), $block->expected;
}
done_testing;

__END__

===
--- input:    およよＡＢＣＤＥＦＧｂｆｅge１２３123＞＜’”
--- expected: およよABCDEFGbfege123123><'"

