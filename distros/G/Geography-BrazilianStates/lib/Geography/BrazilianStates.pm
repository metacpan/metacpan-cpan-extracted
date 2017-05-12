package Geography::BrazilianStates;
use 5.008001;
use strict;
use warnings;

our $VERSION = "0.01";

our $STATES = [
  {name => 'Acre', abbreviation => 'AC', capital => 'Rio Branco', region => 'Norte'},
  {name => 'Alagoas', abbreviation => 'AL', capital => 'Maceió', region => 'Nordeste'},
  {name => 'Amapá', abbreviation => 'AP', capital => 'Macapá', region => 'Norte'},
  {name => 'Amazonas', abbreviation => 'AM', capital => 'Manaus', region => 'Norte'},
  {name => 'Bahia', abbreviation => 'BA', capital => 'Salvador', region => 'Nordeste'},
  {name => 'Ceará', abbreviation => 'CE', capital => 'Fortaleza', region => 'Nordeste'},
  {name => 'Distrito Federal', abbreviation => 'DF', capital => 'Brasília', region => 'Centro-Oeste'},
  {name => 'Espírito Santo', abbreviation => 'ES', capital => 'Vitória', region => 'Sudeste'},
  {name => 'Goiás', abbreviation => 'GO', capital => 'Goiânia', region => 'Centro-Oeste'},
  {name => 'Maranhão', abbreviation => 'MA', capital => 'São Luís', region => 'Nordeste'},
  {name => 'Mato Grosso', abbreviation => 'MT', capital => 'Cuiabá', region => 'Centro-Oeste'},
  {name => 'Mato Grosso do Sul', abbreviation => 'MS', capital => 'Campo Grande', region => 'Centro-Oeste'},
  {name => 'Minas Gerais', abbreviation => 'MG', capital => 'Belo Horizonte', region => 'Sudeste'},
  {name => 'Pará', abbreviation => 'PA', capital => 'Belém', region => 'Norte'},
  {name => 'Paraíba', abbreviation => 'PB', capital => 'João Pessoa', region => 'Nordeste'},
  {name => 'Paraná', abbreviation => 'PR', capital => 'Curitiba', region => 'Sul'},
  {name => 'Pernambuco', abbreviation => 'PE', capital => 'Recife', region => 'Nordeste'},
  {name => 'Piauí', abbreviation => 'PI', capital => 'Teresina', region => 'Nordeste'},
  {name => 'Rio de Janeiro', abbreviation => 'RJ', capital => 'Rio de Janeiro', region => 'Sudeste'},
  {name => 'Rio Grande do Norte', abbreviation => 'RN', capital => 'Natal', region => 'Nordeste'},
  {name => 'Rio Grande do Sul', abbreviation => 'RS', capital => 'Porto Alegre', region => 'Sul'},
  {name => 'Rondônia', abbreviation => 'RO', capital => 'Porto Velho', region => 'Norte'},
  {name => 'Roraima', abbreviation => 'RR', capital => 'Boa Vista', region => 'Norte'},
  {name => 'Santa Catarina', abbreviation => 'SC', capital => 'Florianópolis', region => 'Sul'},
  {name => 'São Paulo', abbreviation => 'SP', capital => 'São Paulo', region => 'Sudeste'},
  {name => 'Sergipe', abbreviation => 'SE', capital => 'Aracaju', region => 'Nordeste'},
  {name => 'Tocantins', abbreviation => 'TO', capital => 'Palmas', region => 'Norte'}
];

sub states {
  my $class = shift;
  return map { $_->{name} } @$STATES; 
}

sub abbreviations {
  my $class = shift;
  return map { $_->{abbreviation} } @$STATES; 
}

sub capitals {
  my $class = shift;
  return map { $_->{capital} } @$STATES; 
}

sub regions {
  my $class = shift;
  my %uniq;
  return grep { !$uniq{$_}++ } map { $_->{region} } @$STATES; 
}

sub abbreviation {
  my ($class, $name) = @_;
  for my $state(@$STATES) {
    if ($name eq $state->{name}) {
      return $state->{abbreviation};
    } elsif ($name eq $state->{abbreviation}) {
      return $state->{name};
    }
  }
}

sub capital {
  my ($class, $name) = @_;
  for my $state(@$STATES) {
    if ($name eq $state->{name}) {
      return $state->{capital};
    } elsif ($name eq $state->{capital}) {
      return $state->{name};
    }
  }
}

sub region {
  my ($class, $name) = @_;
  my $regions = [];
  for my $state(@$STATES) {
    if ($name eq $state->{name}) {
      return $state->{region};
    } elsif ($name eq $state->{region}) {
      push @$regions, $state->{name};
    }
  }
  return @$regions;
}

sub states_all {
  my $class = shift;
  return $STATES;
}

1;
__END__

=encoding utf-8

=head1 NAME

Geography::BrazilianStates - get information of Brazilian States

=head1 SYNOPSIS

    use Geography::BrazilianStates;

    Geography::BrazilianStates->states;
    # => get all states

    Geography::BrazilianStates->abbreviations;
    # => get all abbreviations

    Geography::BrazilianStates->capitals;
    # => get all capitals

    Geography::BrazilianStates->regions;
    # => get all regions

    Geography::BrazilianStates->abbreviation('Amazonas');
    # => 'AM'
    Geography::BrazilianStates->abbreviation('AM');
    # => 'Amazonas'

    Geography::BrazilianStates->capital('Amazonas');
    # => 'Manaus'
    Geography::BrazilianStates->capital('Manaus');
    # => 'Amazonas'

    Geography::BrazilianStates->region('Amazonas');
    # => 'Norte'
    Geography::BrazilianStates->region('Norte');
    # => qw(Acre Amapá Amazonas Pará Rondônia Roraima Tocantins)

    Geography::BrazilianStates->states_all;
    # => get all states with full information as ArrayRef

=head1 DESCRIPTION

This module provides you Brazilian States information like name, abbreviation, capital, and region itself.

=head1 Class Methods

=head2 states

    @states = Geography::BrazilianStates->states;

get all states

=head2 abbreviations

    @abbreviations = Geography::BrazilianStates->abbreviations;

get all abbreviations

=head2 capitals

    @capitals = Geography::BrazilianStates->capitals;

get all capitals

=head2 regions

    @regions = Geography::BrazilianStates->regions;

get all regions

=head2 abbreviation

    Geography::BrazilianStates->abbreviation('Amazonas');
    # => 'AM'
    Geography::BrazilianStates->abbreviation('AM');
    # => 'Amazonas'

=head2 capital

    Geography::BrazilianStates->capital('Amazonas');
    # => 'Manaus'
    Geography::BrazilianStates->capital('Manaus');
    # => 'Amazonas'

=head2 region

    Geography::BrazilianStates->region('Amazonas');
    # => 'Norte'
    Geography::BrazilianStates->region('Norte');
    # => qw(Acre Amapá Amazonas Pará Rondônia Roraima Tocantins)

=head2 states_all

    Geography::BrazilianStates->states_all;
    # => get all states with full information as ArrayRef

=head1 LICENSE

Copyright (C) yuzoiwasaki.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

yuzoiwasaki E<lt>a0556017@sophia.jpE<gt>

=cut

