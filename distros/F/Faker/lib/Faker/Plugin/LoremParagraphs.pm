package Faker::Plugin::LoremParagraphs;

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
  def => 2,
);

has 'sentences' => (
  is => 'ro',
  isa => 'Int',
  def => 5,
);

# METHODS

method execute() {
  my $faker = $self->faker;
  my $pcount = $self->count;
  my $scount = $self->sentences;

  return join ' ', map {
    $scount > 4 ?
      $faker->lorem_paragraph(sentences => $faker->random_between(4, $scount)) :
      $faker->lorem_paragraph
  } 1..$pcount;
}

1;
