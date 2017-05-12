use utf8;
use strict;
use warnings;
use Data::Section::TestBase;
use Test::More;
use utf8;
use Lingua::JA::Regular::Unicode;

for my $block (blocks) {
    is alnum_h2z($block->input), $block->expected;
}
done_testing;

__END__

===
--- input: およよABCDEFGbfe123123
--- expected:    およよＡＢＣＤＥＦＧｂｆｅ１２３１２３

