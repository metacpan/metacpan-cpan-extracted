use strict;
use warnings;
use utf8;
use Lingua::JA::NormalizeText qw/old2new_kana/;
use Test::More;

binmode Test::More->builder->$_ => ':utf8'
    for qw/output failure_output todo_output/;


my $normalizer = Lingua::JA::NormalizeText->new(qw/old2new_kana/);

is(old2new_kana('ヱヴァンゲリオン'), 'エヴァンゲリオン');
is($normalizer->normalize('ゐヰゑヱヸヹ' x 2), 'いイえエイ゙エ゙' x 2);

done_testing;
