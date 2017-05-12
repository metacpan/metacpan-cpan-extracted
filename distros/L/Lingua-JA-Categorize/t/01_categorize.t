use strict;
use Lingua::JA::Categorize;
use Test::More tests => 4;
use Data::Dumper;

my $c = Lingua::JA::Categorize->new;

isa_ok( $c,              'Lingua::JA::Categorize' );
isa_ok( $c->tokenizer,   'Lingua::JA::Categorize::Tokenizer' );
isa_ok( $c->categorizer, 'Lingua::JA::Categorize::Categorizer' );
can_ok( $c, qw( new categorize) );

