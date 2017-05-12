use strict;
use warnings;
use utf8;
use Lingua::JA::NormalizeText qw/circled2kana/;
use Test::More;

binmode Test::More->builder->$_ => ':utf8'
    for qw/output failure_output todo_output/;

my $normalizer = Lingua::JA::NormalizeText->new(qw/circled2kana/);

is(circled2kana('㋙㋛㋑㋟㋑！' x 2), 'コシイタイ！' x 2);
is($normalizer->normalize('㋙㋛㋑㋟㋑！'), 'コシイタイ！');

done_testing;
