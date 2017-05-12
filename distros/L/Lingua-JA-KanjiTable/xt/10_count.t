use strict;
use warnings;
use utf8;
use Lingua::JA::KanjiTable qw/InJoyoKanji InJinmeiyoKanji InJinmeiyoKanji20101130/;
use Test::More;

binmode Test::More->builder->$_ => ':utf8'
    for qw/output failure_output todo_output/;

my ($cnt_joyo, $cnt_jinmei, $cnt_jinmei_20101130);

for my $dec ( hex('0000') .. hex('10FFFF') )
{
    next if hex('D800') <= $dec && $dec <= hex('DBFF'); # High Surrogate Area
    next if hex('DC00') <= $dec && $dec <= hex('DFFF'); # Low  Surrogate Area
    next if hex('FDD0') <= $dec && $dec <= hex('FDEF'); # Noncharacters
    next if sprintf("%04X", $dec) =~ /FFF[EF]$/;        # Noncharacters

    my $chara = chr $dec;
    $cnt_joyo++            if $chara =~ /^\p{InJoyoKanji}$/;
    $cnt_jinmei++          if $chara =~ /^\p{InJinmeiyoKanji}$/;
    $cnt_jinmei_20101130++ if $chara =~ /^\p{InJinmeiyoKanji20101130}$/;
}

is($cnt_joyo,           2136,  'Joyo Kanji count');
is($cnt_jinmei,          862,  'latest Jinmei Kanji count');
is($cnt_jinmei_20101130, 861,  'Jinmei Kanji 20101130 count');

done_testing;
