package Faker::Plugin::LoremWords;

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

has 'count' => (
  is => 'ro',
  isa => 'Int',
  def => 5,
);

# METHODS

method execute() {
  my $faker = $self->faker;
  my $count = $self->count;

  return join ' ', map { $faker->lorem_word } 1..$count;
}

1;
