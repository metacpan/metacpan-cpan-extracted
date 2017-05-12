# NAME

Geography::BrazilianStates - get information of Brazilian States

# SYNOPSIS

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

# DESCRIPTION

This module provides you Brazilian States information like name, abbreviation, capital, and region itself.

# Class Methods

## states

    @states = Geography::BrazilianStates->states;

get all states

## abbreviations

    @abbreviations = Geography::BrazilianStates->abbreviations;

get all abbreviations

## capitals

    @capitals = Geography::BrazilianStates->capitals;

get all capitals

## regions

    @regions = Geography::BrazilianStates->regions;

get all regions

## abbreviation

    Geography::BrazilianStates->abbreviation('Amazonas');
    # => 'AM'
    Geography::BrazilianStates->abbreviation('AM');
    # => 'Amazonas'

## capital

    Geography::BrazilianStates->capital('Amazonas');
    # => 'Manaus'
    Geography::BrazilianStates->capital('Manaus');
    # => 'Amazonas'

## region

    Geography::BrazilianStates->region('Amazonas');
    # => 'Norte'
    Geography::BrazilianStates->region('Norte');
    # => qw(Acre Amapá Amazonas Pará Rondônia Roraima Tocantins)

## states\_all

    Geography::BrazilianStates->states_all;
    # => get all states with full information as ArrayRef

# LICENSE

Copyright (C) yuzoiwasaki.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

# AUTHOR

yuzoiwasaki <a0556017@sophia.jp>
