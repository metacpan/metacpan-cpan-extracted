use strict;
use warnings;
use utf8;
use Test::More;
use t::Util;

use Lingua::JA::Dakuon ':all';

subtest "Default" => sub {
    subtest "Prefer single character" => sub {
        is dakuon_normalize("あがさ\x{3099}た゛なぱま\x{3099}ゔﾊﾋﾞﾌ\x{3099}"),
           'あがざだなぱまゔﾊﾋﾞﾌﾞ'
    };
    subtest "Prefer combining character" => sub {
        local $Lingua::JA::Dakuon::PreferCombining = 1;
        is dakuon_normalize("あがさ\x{3099}た゛なぱま\x{3099}ゔﾊﾋﾞﾌ\x{3099}"),
           "あか\x{3099}さ\x{3099}た\x{3099}なぱま\x{3099}う\x{3099}ﾊﾋﾞﾌﾞ"
    };
};

subtest "Allow combining character" => sub {
    local $Lingua::JA::Dakuon::EnableCombining = 1;
    subtest "Prefer single character" => sub {
        is dakuon_normalize("あがさ\x{3099}た゛なぱま\x{3099}ゔﾊﾋﾞﾌ\x{3099}"),
           "あがざだなぱま\x{3099}ゔﾊﾋﾞﾌﾞ";
    };
    subtest "Prefer combining character" => sub {
        local $Lingua::JA::Dakuon::PreferCombining = 1;
        is dakuon_normalize("あがさ\x{3099}た゛なぱま\x{3099}ゔﾊﾋﾞﾌ\x{3099}"),
           "あか\x{3099}さ\x{3099}た\x{3099}なぱま\x{3099}う\x{3099}ﾊﾋﾞﾌﾞ"
    };
};

done_testing;
