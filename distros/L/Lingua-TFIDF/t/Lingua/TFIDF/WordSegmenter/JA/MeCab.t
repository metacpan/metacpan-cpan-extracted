use strict;
use warnings;
use utf8;
use Test::More;

use_ok 'Lingua::TFIDF::WordSegmenter::JA::MeCab';

my $segmenter = new_ok 'Lingua::TFIDF::WordSegmenter::JA::MeCab';

my $document = <<'EOT';
ハンプティ・ダンプティ　塀の上
ハンプティ・ダンプティ　おっこちた
王様の馬みんなと　王様の家来みんなでも
ハンプティを元に　戻せない
EOT

my $iter = $segmenter->segment($document);
my @segmented_words;
while (defined (my $word = $iter->())) { push @segmented_words, $word }

cmp_ok 0+@segmented_words, '>', 1;

my $expected = $document;
$expected =~ s/\n//g;
is join('', @segmented_words), $expected;

done_testing;
