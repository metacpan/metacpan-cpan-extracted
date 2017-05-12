use strict;
use warnings;
use utf8;
use Lingua::JA::NormalizeText qw/decode_entities/;
use Test::More;

binmode Test::More->builder->$_ => ':utf8'
    for qw/output failure_output todo_output/;

is(decode_entities('&hearts;'), '♥');

my $normalizer = Lingua::JA::NormalizeText->new(qw/decode_entities/);
is($normalizer->normalize('あ&hearts;あ' x 2), 'あ♥あ'x 2);

done_testing;
