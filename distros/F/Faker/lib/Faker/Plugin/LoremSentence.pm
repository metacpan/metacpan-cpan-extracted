package Faker::Plugin::LoremSentence;

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

has 'words' => (
  is => 'ro',
  isa => 'Int',
  def => 10,
);

# METHODS

method execute() {
  my $faker = $self->faker;
  my $count = $self->words;

  return $faker->lorem_words(count => $count) . '.';
}

1;
