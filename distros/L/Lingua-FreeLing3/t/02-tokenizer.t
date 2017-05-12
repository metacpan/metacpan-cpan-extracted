# -*- cperl -*-

use warnings;
use strict;
use utf8;
use Test::More tests => 38;
use Lingua::FreeLing3::Tokenizer;

my $es_tok = Lingua::FreeLing3::Tokenizer->new("es");

# defined
ok($es_tok);

# is a L::FL::Tokenizer
isa_ok($es_tok => 'Lingua::FreeLing3::Tokenizer');

# the tokenizer is of the right class
isa_ok($es_tok => 'Lingua::FreeLing3::Bindings::tokenizer');

# ok, the object can tokenize?
can_ok($es_tok => 'tokenize');

my $words = $es_tok->tokenize("Los sindicatos logran que la reforma de las pensiones acordada hoy con el Gobierno tenga en cuenta la debilidad de dos colectivos clave: mujeres y jóvenes");

is(scalar(@$words) => 27);
for my $word (@$words) {
    isa_ok($word => 'Lingua::FreeLing3::Word');
}

my @real_words = map { $_->form } @$words;

is_deeply(\@real_words, [qw"Los sindicatos logran que la reforma de las pensiones acordada hoy con el Gobierno tenga en cuenta la debilidad de dos colectivos clave : mujeres y jóvenes"]);

my $real_words = $es_tok->tokenize("Los sindicatos logran que la reforma de las pensiones acordada hoy con el Gobierno tenga en cuenta la debilidad de dos colectivos clave: mujeres y jóvenes",
                                   to_text => 1);
is(scalar(@$real_words) => 27);
is_deeply($real_words, [qw"Los sindicatos logran que la reforma de las pensiones acordada hoy con el Gobierno tenga en cuenta la debilidad de dos colectivos clave : mujeres y jóvenes"]);

my $empty = $es_tok->tokenize(" ");
is_deeply $empty => [];

my $empty2 = $es_tok->tokenize("");
is_deeply $empty2 => [];

my $empty3 = $es_tok->tokenize();
is_deeply $empty3 => [];
