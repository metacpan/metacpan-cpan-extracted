use strict;
use warnings;
use utf8;
use Test::More;
use t::Util;

use Lingua::JA::Dakuon ':all';

subtest "Default" => sub {
    subtest "Prefer single character" => sub {
        is handakuon_normalize("あぱひ\x{309a}ひ゜がま\x{309a}ﾊﾋﾟﾌ\x{309a}"),
           'あぱぴぴがまﾊﾋﾟﾌﾟ';
    };
    subtest "Prefer combining character" => sub {
        local $Lingua::JA::Dakuon::PreferCombining = 1;
        is handakuon_normalize("あぱひ\x{309a}ひ゜がま\x{309a}ﾊﾋﾟﾌ\x{309a}"),
           "あは\x{309a}ひ\x{309a}ひ\x{309a}がま\x{309a}ﾊﾋﾟﾌﾟ";
    };
};

subtest "Allow combining character" => sub {
    local $Lingua::JA::Dakuon::EnableCombining = 1;
    subtest "Prefer single character" => sub {
        is handakuon_normalize("あぱひ\x{309a}ひ゜がま\x{309a}ﾊﾋﾟﾌ\x{309a}"),
           "あぱぴぴがま\x{309a}ﾊﾋﾟﾌﾟ";
    };
    subtest "Prefer combining character" => sub {
        local $Lingua::JA::Dakuon::PreferCombining = 1;
        is handakuon_normalize("あぱひ\x{309a}ひ゜がま\x{309a}ﾊﾋﾟﾌ\x{309a}"),
           "あは\x{309a}ひ\x{309a}ひ\x{309a}がま\x{309a}ﾊﾋﾟﾌﾟ";
    };
};

done_testing;
