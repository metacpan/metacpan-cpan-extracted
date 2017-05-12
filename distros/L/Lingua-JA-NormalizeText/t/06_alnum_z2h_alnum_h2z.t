use strict;
use warnings;
use utf8;
use Lingua::JA::NormalizeText qw/alnum_z2h alnum_h2z/;
use Test::More;

binmode Test::More->builder->$_ => ':utf8'
    for qw/output failure_output todo_output/;

my $text = 'およよＡＢＣＤＥＦＧｂｆｅge１２３123';

is(alnum_z2h($text), 'およよABCDEFGbfege123123');
is(alnum_h2z($text), 'およよＡＢＣＤＥＦＧｂｆｅｇｅ１２３１２３');

my $nomalizer = Lingua::JA::NormalizeText->new(qw/alnum_z2h/);
is($nomalizer->normalize($text), 'およよABCDEFGbfege123123');

$nomalizer = Lingua::JA::NormalizeText->new(qw/alnum_h2z/);
is($nomalizer->normalize($text), 'およよＡＢＣＤＥＦＧｂｆｅｇｅ１２３１２３');

done_testing;
