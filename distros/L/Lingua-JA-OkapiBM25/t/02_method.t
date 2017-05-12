use strict;
use warnings;
use Lingua::JA::OkapiBM25;
use Test::More tests => 2;

my $calc = Lingua::JA::OkapiBM25->new();

can_ok($calc, 'new');
can_ok($calc, 'bm25');