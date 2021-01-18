package Faker::Plugin::PaymentCardExpiration;

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

  my $pad = $faker->random_between(1,3);
  my $month = sprintf('%02d', $faker->random_between(1,12));
  my $year = sprintf('%02d', ((localtime)[5] % 100) + $pad);

  return "$month/$year";
}

1;
