use strict;
use warnings;
use utf8;
use Lingua::TFIDF::WordSegmenter::LetterNgram;
use List::Util qw/sum/;
use Test::More;

use_ok 'Lingua::TFIDF';

my $tf_idf_calc = new_ok 'Lingua::TFIDF' => [
  word_segmenter => Lingua::TFIDF::WordSegmenter::LetterNgram->new(n => 2),
];

my $document1 = <<'EOT';
ハンプティ・ダンプティ　塀の上
ハンプティ・ダンプティ　おっこちた
王様の馬みんなと　王様の家来みんなでも
ハンプティを元に　戻せない
EOT

my $document2 = <<'EOT';
ハンプティ・ダンプティ　塀の上
ハンプティ・ダンプティ　おっこちた
80人と　さらに80人の男でも
ハンプティを元の場所に　戻せなかった
EOT

my %expected_tf_doc1 = (
  'ハン' => 3, 'ンプ' => 5, 'プテ' => 5, 'ティ' => 5, 'ィ・' => 2,
  '・ダ' => 2, 'ダン' => 2, '塀の' => 1, 'の上' => 1, 'おっ' => 1,
  'っこ' => 1, 'こち' => 1, 'ちた' => 1, '王様' => 2, '様の' => 2,
  'の馬' => 1, '馬み' => 1, 'みん' => 2, 'んな' => 2, 'なと' => 1,
  'の家' => 1, '家来' => 1, '来み' => 1, 'なで' => 1, 'でも' => 1,
  'ィを' => 1, 'を元' => 1, '元に' => 1, '戻せ' => 1, 'せな' => 1,
  'ない' => 1,
);

my @common_bigrams = qw/ハン ンプ プテ ティ ィ・ ・ダ ダン 塀の の上 おっ っこ
                        こち ちた でも ィを を元 戻せ せな/;

subtest 'TF' => sub {
  my $tf = $tf_idf_calc->tf(document => $document1);
  is_deeply $tf, \%expected_tf_doc1;

  my $tf_normalized =
    $tf_idf_calc->tf(document => $document1, normalize => 1);
  my $tf_total = sum values %expected_tf_doc1;
  is_deeply $tf_normalized, +{
    map { ($_ => $expected_tf_doc1{$_} / $tf_total) } keys %expected_tf_doc1,
  };
};

subtest 'IDF' => sub {
  my $idf = $tf_idf_calc->idf(documents => [$document1, $document2]);
  my %expected_idf = map { ($_ => log(2/1)) } keys %$idf;
  $expected_idf{$_} = 0 for @common_bigrams;
  is_deeply $idf, \%expected_idf;
};

subtest 'TF-IDF' => sub {
  my $tf_idfs = $tf_idf_calc->tf_idf(documents => [$document1, $document2]);
  is 0+@$tf_idfs, 2;
  my $tf_idf_doc1 = $tf_idfs->[0];
  my %expected_tf_idf_doc1 =
    map { ($_ => log(2/1) * $expected_tf_doc1{$_}) } keys %$tf_idf_doc1;
  $expected_tf_idf_doc1{$_} = 0 for @common_bigrams;
  is_deeply $tf_idf_doc1, \%expected_tf_idf_doc1;

  my $tf_idfs_normalized = $tf_idf_calc->tf_idf(
    documents => [$document1, $document2],
    normalize => 1,
  );
  is 0+@$tf_idfs_normalized, 2;
  my $tf_idf_doc1_normalized = $tf_idfs_normalized->[0];
  my $tf_total = sum values %expected_tf_doc1;
  is_deeply $tf_idf_doc1_normalized, +{ map {
    ($_ => $expected_tf_idf_doc1{$_} / $tf_total);
  } keys %expected_tf_idf_doc1 };
};

done_testing;
