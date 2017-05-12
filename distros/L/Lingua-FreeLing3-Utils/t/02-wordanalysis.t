#!perl -T

use Lingua::FreeLing3::Utils qw/word_analysis/;
use Test::More tests => 13;

use Data::Dumper;

my $cavalo = [
              {
               'tag' => 'VMIP1S0',
               'lemma' => 'cavalar'
              },
              {
               'tag' => 'NCMS000',
               'lemma' => 'cavalo'
              }
             ];

my $analysis = word_analysis({l=>'pt'},"cavalo");
isa_ok $analysis => "ARRAY";
is_deeply($analysis => $cavalo);

my @analysis = word_analysis({l=>'pt'},"cavalo", "alado");
is scalar(@analysis) => 2;
isa_ok $analysis[0] => "ARRAY";
isa_ok $analysis[1] => "ARRAY";
is_deeply($analysis[0] => $cavalo);

my @analysis2 = word_analysis({l=>'pt'},"hdjfhsdf cavalo sdasdas");
is scalar(@analysis2) => 3;
isa_ok $analysis2[0] => "ARRAY";
isa_ok $analysis2[1] => "ARRAY";
isa_ok $analysis2[2] => "ARRAY";

is_deeply $analysis2[0] => [];
is_deeply $analysis2[2] => [];
is_deeply $analysis2[1] => $cavalo;
