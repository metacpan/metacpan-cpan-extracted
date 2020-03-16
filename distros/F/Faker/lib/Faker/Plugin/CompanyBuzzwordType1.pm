package Faker::Plugin::CompanyBuzzwordType1;

use 5.014;

use strict;
use warnings;

use registry;
use routines;

use Data::Object::Class;
use Data::Object::ClassHas;

extends 'Data::Object::Plugin';

our $VERSION = '1.01'; # VERSION

# ATTRIBUTES

has 'faker' => (
  is => 'ro',
  isa => 'InstanceOf["Faker"]',
  req => 1,
);

# METHODS

method execute() {
  my $faker = $self->faker;

  return $faker->process(['company', 'buzzword_type1']);
}

1;

=encoding utf8

=head1 NAME

Faker::Plugin::CompanyBuzzwordType1

=cut

=head1 ABSTRACT

Company Buzzword Type1 Plugin for Faker

=cut

=head1 SYNOPSIS

  package main;

  use Faker;
  use Faker::Plugin::CompanyBuzzwordType1;

  my $f = Faker->new;
  my $p = Faker::Plugin::CompanyBuzzwordType1->new(faker => $f);

  my $plugin = $p;

=cut

=head1 DESCRIPTION

This package provides methods for generating fake company buzzword type1 data.

=cut

=head1 INHERITS

This package inherits behaviors from:

L<Data::Object::Plugin>

=cut

=head1 LIBRARIES

This package uses type constraints from:

L<Types::Standard>

=cut

=head1 ATTRIBUTES

This package has the following attributes:

=cut

=head2 faker

  faker(InstanceOf["Faker"])

This attribute is read-only, accepts C<(InstanceOf["Faker"])> values, and is required.

=cut

=head1 METHODS

This package implements the following methods:

=cut

=head2 execute

  execute() : Str

The execute method returns a random fake company buzzword type1.

=over 4

=item execute example #1

  # given: synopsis

  $p->execute;

=back

=cut

=head1 AUTHOR

Al Newkirk, C<awncorp@cpan.org>

=head1 LICENSE

Copyright (C) 2011-2019, Al Newkirk, et al.

This is free software; you can redistribute it and/or modify it under the terms
of the The Apache License, Version 2.0, as elucidated in the L<"license
file"|https://github.com/iamalnewkirk/faker/blob/master/LICENSE>.

=head1 ACKNOWLEDGEMENTS

Parts of this library were inspired by the following implementations:

L<PHP Faker|https://github.com/fzaninotto/Faker>

L<Ruby Faker|https://github.com/stympy/faker>

L<Python Faker|https://github.com/joke2k/faker>

L<JS Faker|https://github.com/Marak/faker.js>

=head1 PROJECT

L<Wiki|https://github.com/iamalnewkirk/faker/wiki>

L<Project|https://github.com/iamalnewkirk/faker>

L<Initiatives|https://github.com/iamalnewkirk/faker/projects>

L<Milestones|https://github.com/iamalnewkirk/faker/milestones>

L<Contributing|https://github.com/iamalnewkirk/faker/blob/master/CONTRIBUTE.md>

L<Issues|https://github.com/iamalnewkirk/faker/issues>

=cut
