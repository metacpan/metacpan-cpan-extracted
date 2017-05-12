use strict;
use warnings;
use Test::More;
use Geography::BrazilianStates;

subtest 'states' => sub {
  my @states = Geography::BrazilianStates->states;
  is(scalar @states, 27, 'state number is valid');
};

subtest 'abbreviations' => sub {
  my @abbreviations = Geography::BrazilianStates->abbreviations;
  is(scalar @abbreviations, 27, 'abbreviation number is valid');
};

subtest 'capitals' => sub {
  my @capitals = Geography::BrazilianStates->capitals;
  is(scalar @capitals, 27, 'capital number is valid');
};

subtest 'regions' => sub {
  my @regions = Geography::BrazilianStates->regions;
  is(scalar @regions, 5, 'region number is valid');
};

subtest 'abbreviation' => sub {
  my $abbreviation = Geography::BrazilianStates->abbreviation('Amazonas');
  is($abbreviation, 'AM', 'abbreviation is vaild');
  my $name = Geography::BrazilianStates->abbreviation('AM');
  is($name, 'Amazonas', 'abbreviation long name is vaild');
};

subtest 'capital' => sub {
  my $capital = Geography::BrazilianStates->capital('Amazonas');
  is($capital, 'Manaus', 'capital is vaild');
  my $name = Geography::BrazilianStates->capital('Manaus');
  is($name, 'Amazonas', 'capital state is vaild');
};

subtest 'region' => sub {
  my $region = Geography::BrazilianStates->region('Amazonas');
  is($region, 'Norte', 'region is vaild');
  my @states = Geography::BrazilianStates->region('Norte');
  is(scalar @states, 7, 'regional state number is vaild');
};

subtest 'states_all' => sub {
  my $states_all = Geography::BrazilianStates->states_all;
  for my $state(@$states_all) {
    if ($state->{name} eq 'Amazonas') {
      is($state->{abbreviation}, 'AM', 'states_all abbreviation is vaild');
      is($state->{capital}, 'Manaus', 'states_all capital is vaild');
      is($state->{region}, 'Norte', 'states_all region is vaild');
    }
  }
};

done_testing;
