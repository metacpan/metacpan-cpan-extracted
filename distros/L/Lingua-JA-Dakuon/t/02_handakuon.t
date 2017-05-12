use strict;
use warnings;
use utf8;
use Test::More;
use t::Util;

use Lingua::JA::Dakuon ':all';

subtest "To handakuon" => sub {
    subtest "Default" => sub {
        is handakuon('は'), 'ぱ';
        is handakuon('か'), 'か';
        is handakuon('ﾋ'), 'ﾋﾟ';
        is handakuon('ｱ'), 'ｱﾟ';
    };
    subtest "Allow combining character" => sub {
        local $Lingua::JA::Dakuon::EnableCombining = 1;
        is handakuon('は'), 'ぱ';
        is handakuon('か'), "か\x{309a}";
        is handakuon('ﾋ'), 'ﾋﾟ';
        is handakuon('ｱ'), 'ｱﾟ';
    };
    subtest "Prefer combining character" => sub {
        local $Lingua::JA::Dakuon::PreferCombining = 1;
        is handakuon('は'), "は\x{309a}";
        is handakuon('ﾋ'), 'ﾋﾟ';
    };

    is handakuon('パ'), 'パ';
    is handakuon('ﾀﾟ'), undef;
    is handakuon('ああ'), undef;
};

subtest "From handakuon" => sub {
    is seion('ぱ'), 'は';
    is seion('か'), 'か';
    is seion("か\x{309a}"), 'か';
    is seion('は゜'), 'は';
    is seion('ﾀﾟ'), 'ﾀ';
    is seion('ｱﾟ'), 'ｱ';
};

subtest "Cover all" => sub {
    my %cases = map { split // } qw{
      はぱ ひぴ ふぷ へぺ ほぽ
      ハパ ヒピ フプ ヘペ ホポ
    };
    while (my ($s, $d) = each %cases) {
        is handakuon($s), $d, "handakuon($s) = $d";
        is seion($d), $s, "seion($d) = $s";
    }
};

done_testing;
