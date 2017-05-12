use strict;
use Lingua::JA::Categorize::Tokenizer;
use Test::More tests => 3;
use Data::Dumper;

my $tokenizer = Lingua::JA::Categorize::Tokenizer->new;

isa_ok($tokenizer, 'Lingua::JA::Categorize::Tokenizer');
isa_ok($tokenizer->calc, 'Lingua::JA::TFIDF');
can_ok($tokenizer, qw( new tokenize));


