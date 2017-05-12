use strict;
use warnings;
use Lingua::JA::OkapiBM25;
use Test::More tests => 1;

my $calc = Lingua::JA::OkapiBM25->new();

isa_ok($calc, 'Lingua::JA::OkapiBM25');