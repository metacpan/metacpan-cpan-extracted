use strict;
use Lingua::JA::TFIDF;
use Test::More tests => 1;

my $calculator = Lingua::JA::TFIDF->new();

isa_ok($calculator, 'Lingua::JA::TFIDF');
