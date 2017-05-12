use strict;
use warnings;
use utf8;
use Lingua::JA::NormalizeText qw/katakana2hiragana hiragana2katakana/;
use Test::More;

binmode Test::More->builder->$_ => ':utf8'
    for qw/output failure_output todo_output/;

is(katakana2hiragana('オコジョ'), 'おこじょ');
is(hiragana2katakana('おこじょ'), 'オコジョ');

my $normalizer = Lingua::JA::NormalizeText->new(qw/katakana2hiragana/);
is($normalizer->normalize('パールぱーる'), 'ぱーるぱーる');

$normalizer = Lingua::JA::NormalizeText->new(qw/hiragana2katakana/);
is($normalizer->normalize('パールぱーる'), 'パールパール');

done_testing;
