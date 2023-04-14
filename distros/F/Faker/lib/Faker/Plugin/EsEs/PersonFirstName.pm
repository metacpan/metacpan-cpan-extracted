package Faker::Plugin::EsEs::PersonFirstName;

use 5.018;

use strict;
use warnings;

use Venus::Class 'base';

base 'Faker::Plugin::EsEs';

# VERSION

our $VERSION = '1.19';

# METHODS

sub execute {
  my ($self, $data) = @_;

  return (lc($self->faker->person_gender) eq 'male')
    ? $self->faker->random->select(data_for_first_name_male())
    : $self->faker->random->select(data_for_first_name_female());
}

sub data_for_first_name_male {
  state $first_name = [
    'Aaron',
    'Adam',
    'Adrián',
    'Aitor',
    'Alberto',
    'Aleix',
    'Alejandro',
    'Alex',
    'Alonso',
    'Álvaro',
    'Ander',
    'Andrés',
    'Ángel',
    'Antonio',
    'Arnau',
    'Asier',
    'Biel',
    'Bruno',
    'Carlos',
    'César',
    'Cristian',
    'Daniel',
    'Dario',
    'David',
    'Diego',
    'Eduardo',
    'Enrique',
    'Eric',
    'Erik',
    'Fernando',
    'Francisco',
    'Francisco Javier',
    'Gabriel',
    'Gael',
    'Gerard',
    'Gonzalo',
    'Guillem',
    'Guillermo',
    'Héctor',
    'Hugo',
    'Ian',
    'Ignacio',
    'Iker',
    'Isaac',
    'Ismael',
    'Iván',
    'Izan',
    'Jaime',
    'Jan',
    'Javier',
    'Jesús',
    'Joel',
    'Jon',
    'Jordi',
    'Jorge',
    'José',
    'José Antonio',
    'José Manuel',
    'Juan',
    'Juan José',
    'Leo',
    'Lucas',
    'Luis',
    'Manuel',
    'Marc',
    'Marco',
    'Marcos',
    'Mario',
    'Martín',
    'Mateo',
    'Miguel',
    'Miguel Ángel',
    'Nicolás',
    'Oliver',
    'Omar',
    'Oriol',
    'Óscar',
    'Pablo',
    'Pedro',
    'Pol',
    'Rafael',
    'Raúl',
    'Rayan',
    'Roberto',
    'Rodrigo',
    'Rubén',
    'Samuel',
    'Santiago',
    'Saúl',
    'Sergio',
    'Unai',
    'Víctor',
    'Yago',
    'Yeray',
  ]
}

sub data_for_first_name_female {
  state $first_name = [
    'Abril',
    'Adriana',
    'África',
    'Aina',
    'Ainara',
    'Ainhoa',
    'Aitana',
    'Alba',
    'Alejandra',
    'Alexandra',
    'Alexia',
    'Alicia',
    'Alma',
    'Amparo',
    'Ana',
    'Ana Isabel',
    'Ana María',
    'Andrea',
     'Ángela',
    'Ángeles',
    'Antonia',
    'Ariadna',
    'Aurora',
    'Beatriz',
    'Berta',
    'Blanca',
    'Candela',
    'Carla',
    'Carlota',
    'Carmen',
    'Carolina',
    'Celia',
    'Clara',
    'Claudia',
    'Cristina',
    'Daniela',
    'Diana',
    'Elena',
    'Elsa',
    'Emilia',
    'Encarnación',
    'Eva',
    'Esther',
    'Fátima',
    'Francisca',
    'Gabriela',
    'Gloria',
    'Helena',
    'Inés',
    'Inmaculada',
    'Irene',
     'Isabel',
    'Josefa',
    'Jimena',
    'Juana',
    'Julia',
    'Laia',
    'Lara',
    'Laura',
    'Leire',
    'Lorena',
    'Lidia',
    'Lola',
    'Lucía',
    'Luisa',
    'Luna',
    'Malak',
    'Manuela',
    'Mar',
    'Mara',
    'Margarita',
    'María',
    'María Ángeles',
    'María Carmen',
    'María Dolores',
    'María Pilar',
    'Marina',
    'Marta',
     'Martina',
    'Mireia',
    'Miriam',
    'Nadia',
    'Nahia',
    'Naia',
    'Naiara',
    'Natalia',
    'Nayara',
    'Nerea',
    'Nil',
    'Noa',
    'Noelia',
    'Nora',
    'Nuria',
    'Olivia',
    'Olga',
    'Ona',
    'Paola',
    'Patricia',
    'Pau',
    'Paula',
    'Pilar',
    'Raquel',
    'Rocío',
    'Rosa',
    'Rosa María',
    'Rosario',
    'Salma',
    'Sandra',
    'Sara',
    'Silvia',
    'Sofía',
    'Sonia',
    'Teresa',
    'Úrsula',
    'Valentina',
    'Valeria',
    'Vega',
    'Vera',
    'Verónica',
    'Victoria',
    'Yaiza',
    'Yolanda',
    'Zoe',
  ]
}

1;



=head1 NAME

Faker::Plugin::EsEs::PersonFirstName - Person First Name

=cut

=head1 ABSTRACT

Person First Name for Faker

=cut

=head1 VERSION

1.19

=cut

=head1 SYNOPSIS

  package main;

  use Faker::Plugin::EsEs::PersonFirstName;

  my $plugin = Faker::Plugin::EsEs::PersonFirstName->new;

  # bless(..., "Faker::Plugin::EsEs::PersonFirstName")

=cut

=head1 DESCRIPTION

This package provides methods for generating fake data for person first name.

=encoding utf8

=cut

=head1 INHERITS

This package inherits behaviors from:

L<Faker::Plugin::EsEs>

=cut

=head1 METHODS

This package provides the following methods:

=cut

=head2 execute

  execute(HashRef $data) (Str)

The execute method returns a returns a random fake person first name.

I<Since C<1.10>>

=over 4

=item execute example 1

  package main;

  use Faker::Plugin::EsEs::PersonFirstName;

  my $plugin = Faker::Plugin::EsEs::PersonFirstName->new;

  # bless(..., "Faker::Plugin::EsEs::PersonFirstName")

  # my $result = $plugin->execute;

  # 'Hugo';

  # my $result = $plugin->execute;

  # 'Iván';

  # my $result = $plugin->execute;

  # 'Jorge';

=back

=cut

=head2 new

  new(HashRef $data) (Plugin)

The new method returns a new instance of the class.

I<Since C<1.10>>

=over 4

=item new example 1

  package main;

  use Faker::Plugin::EsEs::PersonFirstName;

  my $plugin = Faker::Plugin::EsEs::PersonFirstName->new;

  # bless(..., "Faker::Plugin::EsEs::PersonFirstName")

=back

=cut

=head1 AUTHORS

Awncorp, C<awncorp@cpan.org>

=cut

=head1 LICENSE

Copyright (C) 2000, Al Newkirk.

This program is free software, you can redistribute it and/or modify it under
the terms of the Apache license version 2.0.

=cut