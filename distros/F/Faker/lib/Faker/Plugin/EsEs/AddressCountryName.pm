package Faker::Plugin::EsEs::AddressCountryName;

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

  return $self->faker->random->select(data_for_address_country_name());
}

sub data_for_address_country_name {
  state $address_country_name = [
    'Afganistán',
    'Albania',
    'Alemania',
    'Andorra',
    'Angola',
    'Antigua y Barbuda',
    'Arabia Saudí',
    'Argelia',
    'Argentina',
    'Armenia',
    'Australia',
    'Austria',
    'Azerbaiyán',
    'Bahamas',
    'Bangladés',
    'Barbados',
    'Baréin',
    'Belice',
    'Benín',
    'Bielorrusia',
    'Birmania',
    'Bolivia',
    'Bosnia-Herzegovina',
    'Botsuana',
    'Brasil',
    'Brunéi Darusalam',
    'Bulgaria',
    'Burkina Faso',
    'Burundi',
    'Bután',
    'Bélgica',
    'Cabo Verde',
    'Camboya',
    'Camerún',
    'Canadá',
    'Catar',
    'Chad',
    'Chile',
    'China',
    'Chipre',
    'Ciudad del Vaticano',
    'Colombia',
    'Comoras',
    'Congo',
    'Corea del Norte',
    'Corea del Sur',
    'Costa Rica',
    'Costa de Marfil',
    'Croacia',
    'Cuba',
    'Dinamarca',
    'Dominica',
    'Ecuador',
    'Egipto',
    'El Salvador',
    'Emiratos Árabes Unidos',
    'Eritrea',
    'Eslovaquia',
    'Eslovenia',
    'España',
    'Estados Unidos de América',
    'Estonia',
    'Etiopía',
    'Filipinas',
    'Finlandia',
    'Fiyi',
    'Francia',
    'Gabón',
    'Gambia',
    'Georgia',
    'Ghana',
    'Granada',
    'Grecia',
    'Guatemala',
    'Guinea',
    'Guinea Ecuatorial',
    'Guinea-Bisáu',
    'Guyana',
    'Haití',
    'Honduras',
    'Hungría',
    'India',
    'Indonesia',
    'Irak',
    'Irlanda',
    'Irán',
    'Islandia',
    'Islas Marshall',
    'Islas Salomón',
    'Israel',
    'Italia',
    'Jamaica',
    'Japón',
    'Jordania',
    'Kazajistán',
    'Kenia',
    'Kirguistán',
    'Kiribati',
    'Kuwait',
    'Laos',
    'Lesoto',
    'Letonia',
    'Liberia',
    'Libia',
    'Liechtenstein',
    'Lituania',
    'Luxemburgo',
    'Líbano',
    'Macedonia',
    'Madagascar',
    'Malasia',
    'Malaui',
    'Maldivas',
    'Mali',
    'Malta',
    'Marruecos',
    'Mauricio',
    'Mauritania',
    'Micronesia',
    'Moldavia',
    'Mongolia',
    'Montenegro',
    'Mozambique',
    'México',
    'Mónaco',
    'Namibia',
    'Nauru',
    'Nepal',
    'Nicaragua',
    'Nigeria',
    'Noruega',
    'Nueva Zelanda',
    'Níger',
    'Omán',
    'Pakistán',
    'Palaos',
    'Panamá',
    'Papúa Nueva Guinea',
    'Paraguay',
    'Países Bajos',
    'Perú',
    'Polonia',
    'Portugal',
    'Reino Unido',
    'Reino Unido de Gran Bretaña e Irlanda del Norte',
    'República Centroafricana',
    'República Checa',
    'República Democrática del Congo',
    'República Dominicana',
    'Ruanda',
    'Rumanía',
    'Rusia',
    'Samoa',
    'San Cristóbal y Nieves',
    'San Marino',
    'San Vicente y las Granadinas',
    'Santa Lucía',
    'Santo Tomé y Príncipe',
    'Senegal',
    'Serbia',
    'Seychelles',
    'Sierra Leona',
    'Singapur',
    'Siria',
    'Somalia',
    'Sri Lanka',
    'Suazilandia',
    'Sudáfrica',
    'Sudán',
    'Suecia',
    'Suiza',
    'Surinam',
    'Tailandia',
    'Tanzania',
    'Tayikistán',
    'Timor Oriental',
    'Togo',
    'Tonga',
    'Trinidad y Tobago',
    'Turkmenistán',
    'Turquía',
    'Tuvalu',
    'Túnez',
    'Ucrania',
    'Uganda',
    'Uruguay',
    'Uzbekistán',
    'Vanuatu',
    'Venezuela',
    'Vietnam',
    'Yemen',
    'Yibuti',
    'Zambia',
    'Zimbabue',
  ]
}

1;



=head1 NAME

Faker::Plugin::EsEs::AddressCountryName - Address Country Name

=cut

=head1 ABSTRACT

Address Country Name for Faker

=cut

=head1 VERSION

1.19

=cut

=head1 SYNOPSIS

  package main;

  use Faker::Plugin::EsEs::AddressCountryName;

  my $plugin = Faker::Plugin::EsEs::AddressCountryName->new;

  # bless(..., "Faker::Plugin::EsEs::AddressCountryName")

=cut

=head1 DESCRIPTION

This package provides methods for generating fake data for address country name.

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

The execute method returns a returns a random fake address country name.

I<Since C<1.10>>

=over 4

=item execute example 1

  package main;

  use Faker::Plugin::EsEs::AddressCountryName;

  my $plugin = Faker::Plugin::EsEs::AddressCountryName->new;

  # bless(..., "Faker::Plugin::EsEs::AddressCountryName")

  # my $result = $plugin->execute;

  # 'Francia';

  # my $result = $plugin->execute;

  # 'India';

  # my $result = $plugin->execute;

  # 'Suazilandia';

=back

=cut

=head2 new

  new(HashRef $data) (Plugin)

The new method returns a new instance of the class.

I<Since C<1.10>>

=over 4

=item new example 1

  package main;

  use Faker::Plugin::EsEs::AddressCountryName;

  my $plugin = Faker::Plugin::EsEs::AddressCountryName->new;

  # bless(..., "Faker::Plugin::EsEs::AddressCountryName")

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