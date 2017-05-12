use strict;
use warnings;
use utf8;
use Test::More;
use Lingua::JA::NormalizeText qw/nfkc/;
use Lingua::JA::NormalizeText qw/decode_entities/;

binmode Test::More->builder->$_ => ':utf8'
    for qw/output failure_output todo_output/;

is(nfkc('㌔'), 'キロ');
is(decode_entities('&hearts;'), '♥');

done_testing;
