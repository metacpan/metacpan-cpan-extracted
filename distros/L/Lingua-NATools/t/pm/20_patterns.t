#!/usr/bin/perl

use warnings;
use strict;

use Data::Dumper;
use Test::More tests => 12 + 2 * (7);

use_ok "Lingua::NATools::PatternRules";

my $rules_file = "t/pm/20_patterns.in";

my $rules = Lingua::NATools::PatternRules->parseFile($rules_file);

# print STDERR Dumper($rules);

isa_ok($rules,"ARRAY");

for (@$rules) {
  if (ref($_) eq "HASH") {
    ok(exists($_->{perl}));
  } else {
    isa_ok($_, "Lingua::NATools::PatternRules");

    my $strings = $_->strings;
    isa_ok($strings, "ARRAY");
  }
}



#### Supondo que a ultima regra é ABBA. Se for mudado, mudar aqui.
my $abba = $rules->[-2];  ### -1 is Perl code.

my $abba_m = $abba->matrix;
is($abba_m->[0][0], 0);
is($abba_m->[0][1], 'P');
is($abba_m->[1][0], 'P');
is($abba_m->[1][1], 0);

my $inf = $abba -> infer("gato gordo","fat cat");
isa_ok($inf, "ARRAY");

is($inf->[0]{gordo}[0]{CAT}, "ADJ");
is($inf->[1]{fat}[0]{CAT}, "ADJ");

#### Suposdo que a POV é a terceira (indice 2)

my $pov = $rules->[2];
$inf = $pov -> infer("ponto de vista neutro","neutral point of view");

is($inf->[0]{"ponto de vista"}[0]{CAT}, "N");
is($inf->[1]{"point of view"}[0]{CAT}, "N");

