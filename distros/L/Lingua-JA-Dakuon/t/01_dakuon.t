use strict;
use warnings;
use utf8;
use Test::More;
use t::Util;

use Lingua::JA::Dakuon ':all';

subtest "To dakuon" => sub {
    subtest "Default" => sub {
        is dakuon('か'), 'が';
        is dakuon('は'), 'ば';
        is dakuon('う'), 'ゔ';
        is dakuon('あ'), 'あ';
        is dakuon('ﾀ'), 'ﾀﾞ';
        is dakuon('ｱ'), 'ｱﾞ';
    };
    subtest "Allow combining character" => sub {
        local $Lingua::JA::Dakuon::EnableCombining = 1;
        is dakuon('か'), 'が';
        is dakuon('は'), 'ば';
        is dakuon('う'), 'ゔ';
        is dakuon('あ'), "あ\x{3099}";
        is dakuon('ﾀ'), 'ﾀﾞ';
        is dakuon('ｱ'), 'ｱﾞ';
    };
    subtest "Prefer combining character" => sub {
        local $Lingua::JA::Dakuon::PreferCombining = 1;
        is dakuon('か'), "か\x{3099}";
        is dakuon('ﾀ'), 'ﾀﾞ';
    };

    is dakuon('が'), 'が';
    is dakuon('ﾀﾞ'), undef;
    is dakuon('ああ'), undef;
};

subtest "From dakuon" => sub {
    is seion('が'), 'か';
    is seion('ば'), 'は';
    is seion('ゔ'), 'う';
    is seion('あ'), 'あ';
    is seion("あ\x{3099}"), 'あ';
    is seion('か゛'), 'か';
    is seion('ﾀﾞ'), 'ﾀ';
    is seion('ｱﾞ'), 'ｱ';

    is seion('だだ'), undef;
    is seion('だだだ'), undef;
};

subtest "Cover all" => sub {
    my %cases = map { split // } qw{
      かが きぎ くぐ けげ こご
      さざ しじ すず せぜ そぞ
      ただ ちぢ つづ てで とど
      はば ひび ふぶ へべ ほぼ
      うゔ ゝゞ
      カガ キギ クグ ケゲ コゴ
      サザ シジ スズ セゼ ソゾ
      タダ チヂ ツヅ テデ トド
      ハバ ヒビ フブ ヘベ ホボ
      ウヴ ワヷ ヰヸ ヱヹ ヲヺ
      ヽヾ
    };
    while (my ($s, $d) = each %cases) {
        is dakuon($s), $d, "dakuon($s) = $d";
        is seion($d), $s, "seion($d) = $s";
    }
};

done_testing;
