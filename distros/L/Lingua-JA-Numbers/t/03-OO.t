#!/usr/local/bin/perl
#
# $Id: 03-OO.t,v 0.2 2006/06/10 16:10:39 dankogai Exp $
#
use strict;
use utf8;
use Lingua::JA::Numbers;
use Test::More tests => 11;

binmode STDOUT, ':utf8';
my $ja = Lingua::JA::Numbers->new("1234567890", {style => "romaji"});
isa_ok($ja, "Lingua::JA::Numbers");
is($ja+0, 1234567890, '$ja+0 == 1234567890');
is(qq($ja), "JuuNiOkuSanzenYonHyakuGoJuuRokuManNanaSenHappyakuKyuuJuu", 
   '"$ja" eq JuuNiOkuSanzenYonHyakuGoJuuRokuManNanaSenHappyakuKyuuJuu');
$ja->opt(style => "kanji");
is(qq($ja), '十二億三千四百五十六万七千八百九十', '"$ja" eq <<Kanji>>');
$ja->opt(daiji => 1);
is(qq($ja), '拾弐億参阡四佰伍拾六萬七阡八佰九拾', '"$ja" eq <<Daiji>>'); 
$ja->opt(daiji => 2);
is(qq($ja), '拾弐億参阡肆佰伍拾陸萬漆阡捌佰玖拾', '"$ja" eq <<Daiji_H>>');
$ja->opt(daiji => 0, with_arabic=>1);
is(qq($ja), '12億3456万7890', '"$ja" eq <<with_arabic>>');
$ja->parse("8623", {style=>"kanji"});
is($ja->ordinal, "八千六百二十三番", "\$ja->ordinal - kanji");
$ja->opt(style => 'romaji');
is($ja->ordinal, "HassenRoppyakuNiJuuSanBan", "\$ja->ordinal - romaji");
$ja->opt(style => 'hiragana');
is($ja->ordinal, "はっせんろっぴゃくにじゅうさんばん", "\$ja->ordinal - hiragana");
$ja->opt(style => 'katakana');
is($ja->ordinal, "ハッセンロッピャクニジュウサンバン", "\$ja->ordinal - katakana");

__END__

