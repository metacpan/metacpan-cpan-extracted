use strict;
use Test::Base;
use utf8;
plan tests => 1 * blocks;

use Lingua::AIN::Romanize;

run {
    my $block = shift;
    my ($kana,$option)   = split(/\n/,$block->input);
    my ($roman)          = split(/\n/,$block->expected);

    my $opt = {};
    $opt->{karafuto} = 1 if ($option =~ /karafuto/);

    is ain_kana2roman($kana, $opt), $roman;
};

__END__
===
--- input
アイヌ

--- expected
aynu

===
--- input
イタㇰ

--- expected
itak

===
--- input
イタｸ

--- expected
itak

===
--- input
アイヌ イタㇰ

--- expected
aynu itak

===
--- input
コㇿポックㇽ

--- expected
korpokkur

===
--- input
コﾛポックﾙ

--- expected
korpokkur

===
--- input
レプンカムイ

--- expected
repunkamuy

===
--- input
サッ ポロ ペッ

--- expected
sat poro pet

===
--- input
トゥナカイ

--- expected
tunakay

===
--- input
ラッコ

--- expected
rakko

===
--- input
ユカﾗ

--- expected
yukar

===
--- input
ユカㇻ

--- expected
yukar

===
--- input
ポンペ

--- expected
pompe

===
--- input
タンモシﾘ

--- expected
tammosir

===
--- input
ヒオイオイ

--- expected
hioy'oy

===
--- input
イヤイライケレ

--- expected
iyairaykere
