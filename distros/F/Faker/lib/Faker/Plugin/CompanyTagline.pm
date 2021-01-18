package Faker::Plugin::CompanyTagline;

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

  return join ' ',
    $faker->company_buzzword_type1,
    $faker->company_buzzword_type2,
    $faker->company_buzzword_type3;
}

1;
