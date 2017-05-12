use strict;
use warnings;
use utf8;
use Test::More;
use t::Util;

use Lingua::JA::Dakuon ':all';

subtest "Convert all dakuon to seion" => sub {
    my $string = "あがさ\x{3099}た゛なぱま\x{3099}ゔﾊﾋﾞﾌ\x{3099}";
    $string =~ s{($Lingua::JA::Dakuon::AllDakuonRE)}{seion($1)}ge;
    is $string, 'あかさたなぱまうﾊﾋﾌ';
};

subtest "Convert all handakuon to seion" => sub {
    my $string = "あぱひ\x{309a}ひ゜がま\x{309a}ﾊﾋﾟﾌ\x{309a}";
    $string =~ s{($Lingua::JA::Dakuon::AllHandakuonRE)}{seion($1)}ge;
    is $string, 'あはひひがまﾊﾋﾌ';
};

done_testing;
