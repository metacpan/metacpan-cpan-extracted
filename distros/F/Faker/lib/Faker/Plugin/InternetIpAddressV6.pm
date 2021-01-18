package Faker::Plugin::InternetIpAddressV6;

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

  return join ':',
    sprintf('%04s', sprintf("%02x", $faker->random_between(0, 65535))),
    sprintf('%04s', sprintf("%02x", $faker->random_between(0, 65535))),
    sprintf('%04s', sprintf("%02x", $faker->random_between(0, 65535))),
    sprintf('%04s', sprintf("%02x", $faker->random_between(0, 65535))),
    sprintf('%04s', sprintf("%02x", $faker->random_between(0, 65535))),
    sprintf('%04s', sprintf("%02x", $faker->random_between(0, 65535))),
    sprintf('%04s', sprintf("%02x", $faker->random_between(0, 65535))),
    sprintf('%04s', sprintf("%02x", $faker->random_between(0, 65535)));
}

1;
