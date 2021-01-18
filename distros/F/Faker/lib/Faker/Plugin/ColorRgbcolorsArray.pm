package Faker::Plugin::ColorRgbcolorsArray;

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
  my $color = $faker->color_hex_code;

  return [
    hex(substr($color, 1, 2)),
    hex(substr($color, 3, 2)),
    hex(substr($color, 5, 2)),
  ];
}

1;
