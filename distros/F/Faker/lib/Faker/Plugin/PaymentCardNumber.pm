package Faker::Plugin::PaymentCardNumber;

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

has 'vendor' => (
  is => 'ro',
  isa => 'Str',
  opt => 1,
);

# METHODS

my $vendor_mapping = {
  'Visa' => 'visa',
  'MasterCard' => 'mastercard',
  'American Express' => 'americanexpress',
  'Discover Card' => 'discovercard',
};

method execute() {
  my $faker = $self->faker;
  my $vendor = $self->vendor;

  unless ($vendor && ($vendor = $vendor_mapping->{$vendor})) {
    $vendor = $faker->random_array_item([values %$vendor_mapping]);
  }

  my $options = {
    all_markers => 1
  };

  return $faker->process(["payment", "${vendor}_card"], $options);
}

1;
