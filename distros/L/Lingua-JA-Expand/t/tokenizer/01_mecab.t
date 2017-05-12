use strict;
use warnings;
use Lingua::JA::Expand::Tokenizer::MeCab;
use Test::More tests => 1;

my $tokenizer = Lingua::JA::Expand::Tokenizer::MeCab->new;

isa_ok($tokenizer, 'Lingua::JA::Expand::Tokenizer::MeCab');

