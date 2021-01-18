package Faker::Plugin::LoremSentences;

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
  def => 3,
);

has 'words' => (
  is => 'ro',
  isa => 'Int',
  def => 10,
);

# METHODS

method execute() {
  my $faker = $self->faker;
  my $words = $self->words;
  my $count = $self->count;

  return join ' ', map {
    $words > 3 ?
      $faker->lorem_sentence(words => $faker->random_between(3, $words)) :
      $faker->lorem_sentence
  } 1..$count;
}

1;
