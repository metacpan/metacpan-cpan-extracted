package Faker::Plugin::Payment;

use 5.014;

use strict;
use warnings;

use registry;
use routines;

use Data::Object::Class;
use Data::Object::ClassHas;

extends 'Data::Object::Plugin';

our $VERSION = '1.03'; # VERSION

# ATTRIBUTES

has 'faker' => (
  is => 'ro',
  isa => 'ConsumerOf["Faker::Maker"]',
  req => 1,
);

# METHODS

method data_for_vendor() {
  [
    'Visa',
    'Visa',
    'Visa',
    'Visa',
    'Visa',
    'MasterCard',
    'MasterCard',
    'MasterCard',
    'MasterCard',
    'MasterCard',
    'American Express',
    'Discover Card',
  ]
}

method format_for_americanexpress_card() {
  [
    '34############',
    '37############',
  ]
}

method format_for_discovercard_card() {
  [
    '6011###########',
  ]
}

method format_for_mastercard_card() {
  [
    '51#############',
    '52#############',
    '53#############',
    '54#############',
    '55#############',
  ]
}

method format_for_visa_card() {
  [
    '4539########',
    '4539###########',
    '4556########',
    '4556###########',
    '4916########',
    '4916###########',
    '4532########',
    '4532###########',
    '4929########',
    '4929###########',
    '40240071####',
    '40240071#######',
    '4485########',
    '4485###########',
    '4716########',
    '4716###########',
    '4###########',
    '4##############',
  ]
}

1;
