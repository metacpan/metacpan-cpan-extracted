package Faker::Plugin::CompanyDescription;

use 5.014;

use strict;
use warnings;

use registry;
use routines;

use Data::Object::Class;
use Data::Object::ClassHas;

extends 'Data::Object::Plugin';

our $VERSION = '1.04'; # VERSION

# ATTRIBUTES

has 'faker' => (
  is => 'ro',
  isa => 'ConsumerOf["Faker::Maker"]',
  req => 1,
);

# METHODS

method execute() {
  my $faker = $self->faker;

  my $does = $faker->random_item([
    'Delivers',
    'Excels at',
    'Offering',
    'Best-in-class for'
  ]);

  return join ' ', $does,
    $faker->company_jargon_prop_word,
    $faker->company_jargon_edge_word,
    $faker->company_jargon_buzz_word;
}

1;
