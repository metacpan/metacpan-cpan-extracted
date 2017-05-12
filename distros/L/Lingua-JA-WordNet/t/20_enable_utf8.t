use strict;
use warnings;
use utf8;
use Encode qw/encode_utf8/;
use Lingua::JA::WordNet;
use Test::More;


subtest 'enable_utf8' => sub {
    my $wn = Lingua::JA::WordNet->new(
        enable_utf8 => 1,
    );

    my @synsets = $wn->Synset('相撲', 'jpn');
    my @words = $wn->Word($synsets[0], 'jpn');
    is($words[0], '大相撲');

    my @exs = $wn->Ex('00810729-v', 'jpn');
    is($exs[0], '彼女は悪事を見つけられずにすませます！');
    is(length $exs[0], 19);

    my @defs = $wn->Def('00448232-n', 'jpn');
    is($defs[0], '日本版のレスリング');
    is(length $defs[0], 9);

    my @syns = $wn->Synonym('221927');
    is($syns[0], 'リトマス試験紙');
    is(length $syns[0], 7);
};

subtest 'disable_utf8' => sub {
    my $wn =Lingua::JA::WordNet->new;

    my @synsets = $wn->Synset('相撲', 'jpn');
    my @words = $wn->Word($synsets[0], 'jpn');
    is( $words[0], encode_utf8('大相撲') );

    my @exs = $wn->Ex('00810729-v', 'jpn');
    is( $exs[0], encode_utf8('彼女は悪事を見つけられずにすませます！') );
    cmp_ok(length $exs[0], '>', 19);

    my @defs = $wn->Def('00448232-n', 'jpn');
    is( $defs[0], encode_utf8('日本版のレスリング') );
    cmp_ok(length $defs[0], '>', 9);

    my @syns = $wn->Synonym('221927');
    is( $syns[0], encode_utf8('リトマス試験紙') );
    cmp_ok(length $syns[0], '>', 7);
};

subtest 'enable_utf8 and omit $lang' => sub {
    my $wn = Lingua::JA::WordNet->new(
        enable_utf8 => 1,
    );

    my @synsets = $wn->Synset('相撲');
    my @words = $wn->Word($synsets[0]);
    is($words[0], '大相撲');

    my @exs = $wn->Ex('00810729-v');
    is($exs[0], '彼女は悪事を見つけられずにすませます！');
    is(length $exs[0], 19);

    my @defs = $wn->Def('00448232-n');
    is($defs[0], '日本版のレスリング');
    is(length $defs[0], 9);

    my @syns = $wn->Synonym('221927');
    is($syns[0], 'リトマス試験紙');
    is(length $syns[0], 7);
};

done_testing;
