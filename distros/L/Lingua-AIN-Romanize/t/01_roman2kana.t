use strict;
use Test::Base;
use utf8;
plan tests => 1 * blocks;

use Lingua::AIN::Romanize;

run {
    my $block = shift;
    my ($roman,$option)   = split(/\n/,$block->input);
    my ($kana)           = split(/\n/,$block->expected);

    my $opt = {};
    $opt->{hankaku}  = 1 if ($option =~ /hankaku/);
    $opt->{karafuto} = 1 if ($option =~ /karafuto/);

    is ain_roman2kana($roman, $opt), $kana;
};

__END__
===
--- input
aynu

--- expected
アイヌ

===
--- input
itak

--- expected
イタㇰ

===
--- input
itak
hankaku
--- expected
イタｸ

===
--- input
aynu itak

--- expected
アイヌ イタㇰ

===
--- input
korpokkur

--- expected
コㇿポックㇽ

===
--- input
korpokkur
hankaku
--- expected
コﾛポックﾙ

===
--- input
repunkamuy

--- expected
レプンカムイ

===
--- input
sat poro pet

--- expected
サッ ポロ ペッ

===
--- input
tunakay

--- expected
トゥナカイ

===
--- input
rakko

--- expected
ラッコ

===
--- input
yukar
hankaku
--- expected
ユカﾗ

===
--- input
yukar

--- expected
ユカㇻ

===
--- input
pompe

--- expected
ポンペ

===
--- input
tammosir
hankaku
--- expected
タンモシﾘ

===
--- input
hioy'oy

--- expected
ヒオイオイ

===
--- input
a=kore

--- expected
アコレ

===
--- input
eci=kore

--- expected
エチコレ

===
--- input
k=arpa

--- expected
カㇻパ

===
--- input
iyairaykere

--- expected
イヤイライケレ
