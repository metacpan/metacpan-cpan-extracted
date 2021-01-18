package Faker::Plugin::LoremParagraph;

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

has 'sentences' => (
  is => 'ro',
  isa => 'Int',
  def => 4,
);

# METHODS

method execute() {
  my $faker = $self->faker;
  my $count = $self->sentences;

  return $faker->lorem_sentences(count => $count) . "\n\n";
}

1;
