use strict;
use warnings;
use utf8;
use Lingua::JA::NormalizeText qw/square2katakana/;
use Test::More;

binmode Test::More->builder->$_ => ':utf8'
    for qw/output failure_output todo_output/;

my $normalizer = Lingua::JA::NormalizeText->new(qw/square2katakana/);

is(square2katakana('㌔㍉！'), 'キロミリ！');
is($normalizer->normalize('㌔㍉！' x 2), 'キロミリ！' x 2);

done_testing;
