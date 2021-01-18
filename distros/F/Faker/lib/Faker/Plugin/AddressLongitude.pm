package Faker::Plugin::AddressLongitude;

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
  my $string = (int(rand(90000000)), int(rand(-90000000)))[rand 2];

  $string =~ s/\d*(\d\d)(\d{6})$/$1.$2/;

  return $string;
}

1;
