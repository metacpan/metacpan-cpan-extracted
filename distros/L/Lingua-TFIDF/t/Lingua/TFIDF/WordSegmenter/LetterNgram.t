use strict;
use warnings;
use utf8;
use Test::More;

use_ok 'Lingua::TFIDF::WordSegmenter::LetterNgram';

my $segmenter = new_ok 'Lingua::TFIDF::WordSegmenter::LetterNgram' => [ n => 2 ];

my $iter = $segmenter->segment(<<'EOT');
ハンプティ・ダンプティ　塀の上
ハンプティ・ダンプティ　おっこちた
王様の馬みんなと　王様の家来みんなでも
ハンプティを元に　戻せない
EOT

my @segmented_words;
while (defined (my $word = $iter->())) { push @segmented_words, $word }
is_deeply(
  \@segmented_words,
  [qw/ハン ンプ プテ ティ ィ・ ・ダ ダン ンプ プテ ティ 塀の の上
      ハン ンプ プテ ティ ィ・ ・ダ ダン ンプ プテ ティ おっ っこ こち ちた
      王様 様の の馬 馬み みん んな なと 王様 様の の家 家来 来み みん んな なで でも
      ハン ンプ プテ ティ ィを を元 元に 戻せ せな ない/],
);

done_testing;
