# -*- cperl -*-

use warnings;
use strict;

use Test::More tests => 31;
use Lingua::FreeLing3;
use Lingua::FreeLing3::Bindings;
use Lingua::FreeLing3::ConfigData;
use File::Spec::Functions 'catfile';

my $fl_datadir = Lingua::FreeLing3::ConfigData->config('fl_datadir');
my $tokenizer = Lingua::FreeLing3::Bindings::tokenizer->new(catfile($fl_datadir,
                                                                   'es','tokenizer.dat'));

isa_ok $tokenizer => 'Lingua::FreeLing3::Bindings::tokenizer';
can_ok $tokenizer => 'tokenize';

my $words = $tokenizer->tokenize("Los sindicatos logran que la reforma de las pensiones acordada hoy con el Gobierno tenga en cuenta la debilidad de dos colectivos clave: mujeres y jóvenes");

is(scalar(@$words) => 27);
for my $word (@$words) {
    isa_ok($word => 'Lingua::FreeLing3::Bindings::word');
}

my @real_words = map { $_->get_form } @$words;

is_deeply(\@real_words, [qw"Los sindicatos logran que la reforma de las pensiones acordada hoy con el Gobierno tenga en cuenta la debilidad de dos colectivos clave : mujeres y jóvenes"]);
