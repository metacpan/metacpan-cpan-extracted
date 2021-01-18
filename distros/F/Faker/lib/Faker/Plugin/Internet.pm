package Faker::Plugin::Internet;

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

method data_for_email_domain() {
  [
    'gmail.com',
    'yahoo.com',
    'hotmail.com',
  ]
}

method data_for_root_domain() {
  [
    'biz',
    'co',
    'co',
    'com',
    'com',
    'com',
    'info',
    'io',
    'net',
    'org',
  ]
}

method format_for_email() {
  [
    '{{person.first_name}}@{{internet.domain_name}}',
    '{{person.first_name}}-{{person.last_name}}@{{internet.email_domain}}',
    '{{person.first_name}}.{{person.last_name}}@{{internet.email_domain}}',
    '{{person.first_name}}@{{company.name}}.{{internet.root_domain}}',
    '{{person.first_name}}{{person.last_name}}@{{company.name}}.{{internet.root_domain}}',
  ]
}

method format_for_url() {
  [
    'https://www.{{internet.domain_name}}/',
    'https://{{internet.domain_name}}/',
    'http://www.{{internet.domain_name}}/',
    'http://{{internet.domain_name}}/',
  ]
}

1;
