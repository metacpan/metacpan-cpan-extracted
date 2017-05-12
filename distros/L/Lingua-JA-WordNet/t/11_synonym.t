use strict;
use warnings;
use Lingua::JA::WordNet;
use Test::More;
use Test::Warn;

my $wn = Lingua::JA::WordNet->new(
    verbose => 1,
);

subtest 'wordID has one synonym' => sub {
    my $wordID   = $wn->WordID('盛り上がり', 'n');
    my @synonyms = $wn->Synonym($wordID);
    is_deeply(\@synonyms, [qw/隆起/]);
};

subtest 'wordID has multiple synonyms' => sub {
    my $wordID   = $wn->WordID('ねんねこ', 'n');
    my @synonyms = $wn->Synonym($wordID);
    is_deeply(\@synonyms, [qw/お休み ねね スリープ 就眠 御休み 眠り 睡り 睡眠/]);

    $wordID = $wn->WordID('勉学', 'n');
    @synonyms  = $wn->Synonym($wordID);
    is_deeply(\@synonyms, [qw/勉強 学 学び 学習/]);

    $wordID = $wn->WordID('勉学', 'v');
    @synonyms  = $wn->Synonym($wordID);
    is_deeply(\@synonyms, [qw/勉強 学ぶ 学習/]);
};

subtest 'wordID has duplicate synonyms' => sub {
    my $wordID   = $wn->WordID('研究', 'n');
    my @synonyms = $wn->Synonym($wordID);
    is_deeply(\@synonyms, [qw/リサーチ 研学 考究/]);

    $wordID   = $wn->WordID('リニューアル', 'n');
    @synonyms = $wn->Synonym($wordID);
    is_deeply(\@synonyms, [qw/一新 刷新 更新/]);
};

subtest 'wordID exists only on the right side of the lines of the tsv file' => sub {
    my $wordID   = $wn->WordID('楽しみ', 'n');
    my @synonyms = $wn->Synonym($wordID);
    is_deeply(\@synonyms,
        [qw/アミューズメント エンタテイメント エンタテインメント エンターテイメント エンターテインメント 娯楽 愉しみ/]
    );
};

subtest "POS is not 'n'" => sub {
    my $wordID   = $wn->WordID('生きる', 'v');
    my @synonyms = $wn->Synonym($wordID);
    is_deeply(\@synonyms, [qw/生存/]);
};

subtest 'wordID has no synonyms' => sub {
    my $wordID   = $wn->WordID('食べる', 'v');
    my @synonyms;

    warning_is { @synonyms = $wn->Synonym($wordID); }
        "Synonyms: there are no Synonyms for 235301";

    is_deeply(\@synonyms, [qw//]);
};

done_testing;
