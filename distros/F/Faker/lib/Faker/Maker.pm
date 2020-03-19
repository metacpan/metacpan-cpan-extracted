package Faker::Maker;

use 5.014;

use strict;
use warnings;

use registry;
use routines;

use Data::Object::Role;

with 'Data::Object::Role::Pluggable';
with 'Data::Object::Role::Throwable';

requires 'plugin';
requires 'throw';

method format_lex_markers(Str $string) {
  $string =~ s/\?/$self->random_letter/eg;

  return $string;
}

method format_line_markers(Str $string) {
  $string =~ s/\\n/\n/g;

  return $string;
}

method format_number_markers(Str $string = '###') {
  $string =~ s/\#/$self->random_digit/eg;
  $string =~ s/\%/$self->random_digit_not_zero/eg;

  return $string;
}

method parse_format(Str $string = '') {
  $string =~ s/\{\{\s?([#\.\w]+)\s?\}\}/$self->process_format($1)/eg;

  return $string;
}

method process(Tuple[Str, Str] $lookup, Maybe[HashRef[Int]] $options) {
  my $string;

  $string = $self->process_lookup($lookup);

  if ($options->{all_markers}) {
    $string = $self->process_markers($string);
  }
  if ($options->{lex_markers}) {
    $string = $self->format_lex_markers($string);
  }
  if ($options->{line_markers}) {
    $string = $self->format_line_markers($string);
  }
  if ($options->{number_markers}) {
    $string = $self->format_number_markers($string);
  }

  return $string;
}

method process_format(Str $token) {
  my ($source, $content) = split /[#\.]/, $token;

  my $plugin = $self->plugin($source, faker => $self);

  return $plugin->$content if $plugin->can($content);

  return $self->process_lookup([$source, $content]);
}

method process_lookup(Tuple[Str, Str] $lookup) {
  my ($source, $datatype) = @$lookup;

  my @samples = (
    $datatype,
    "data_for_${datatype}",
    "format_for_${datatype}"
  );

  my $plugin = $self->plugin($source, faker => $self);

  for my $sample (@samples) {
    $plugin->can($sample) or next;

    my $content = $plugin->$sample;
    my $format = $content->[rand @$content];

    $format = join ' ', @$format if ref $format eq 'ARRAY';

    return $self->parse_format($format);
  }

  $plugin = $self->plugin("${source}_${datatype}", faker => $self);

  return $plugin->execute;
}

method process_markers(Str $string = '') {
  my @markers = qw(
    lex_markers
    line_markers
    number_markers
  );

  for my $marker (@markers) {
    my $filter = "format_${marker}";

    $string = $self->$filter($string);
  }

  return $string;
}

method random_between(Maybe[Int] $from, Maybe[Int] $to) {
  my $max = 2147483647;

  $from = 0 if !$from || $from > $max;
  $to = $max if !$to || $to > $max;

  return $from + int rand($to - $from);
}

method random_digit() {

  return int rand(10);
}

method random_digit_not_zero() {

  return 1 + int rand(9);
}

method random_float(Maybe[Int] $place, Maybe[Int] $min, Maybe[Int] $max) {
  $min //= 0;
  $max //= $self->random_number;

  my $tmp; $tmp = $min and $min = $max and $max = $tmp if $min > $max;

  $place //= $self->random_digit_not_zero;

  return sprintf "%.${place}f", $min + rand() * ($max - $min);
}

method random_item(ArrayRef | HashRef $items) {
  return $self->random_array_item($items) if 'ARRAY' eq ref $items;

  return $self->random_hash_item($items) if 'HASH'  eq ref $items;

  return undef;
}

method random_array_item(ArrayRef $items) {

  return $items->[$self->random_between(0, $#{$items})];
}

method random_hash_item(HashRef $items) {

  return $items->{$self->random_item([keys %$items])};
}

method random_letter() {

  return chr $self->random_between(97, 122);
}

method random_number(Maybe[Int] $from, Maybe[Int] $to) {
  $to //= 0;
  $from //= $self->random_digit;

  return $self->random_between($from, $to) if $to;

  return int rand 10 ** $from - 1;
}

1;

=encoding utf8

=head1 NAME

Faker::Maker

=cut

=head1 ABSTRACT

Utility Role for Generating Fake Data

=cut

=head1 SYNOPSIS

  package Example;

  use Data::Object::Class;

  with 'Faker::Maker';

  package main;

  my $example = Example->new;

=cut

=head1 DESCRIPTION

This package provides methods for generating and selecting data randomly.

=cut

=head1 LIBRARIES

This package uses type constraints from:

L<Types::Standard>

=cut

=head1 METHODS

This package implements the following methods:

=cut

=head2 format_lex_markers

  format_lex_markers(Str $string) : Str

The format_lex_markers method replaces each C<?> character in the string with a
random letter.

=over 4

=item format_lex_markers example #1

  # given: synopsis

  $example->format_lex_markers('???')

=back

=cut

=head2 format_line_markers

  format_line_markers(Str $string) : Str

The format_line_markers method replaces each escaped C<\n> (newline) character
in the string with a proper newline character.

=over 4

=item format_line_markers example #1

  # given: synopsis

  $example->format_line_markers('foo\nbar')

=back

=cut

=head2 format_number_markers

  format_number_markers(Str $string) : Str

The format_number_markers method replaces each C<#> in the string with a random
digit, and each C<%> with a random non-zero digit.

=over 4

=item format_number_markers example #1

  # given: synopsis

  $example->format_number_markers('#-%-#')

=back

=cut

=head2 parse_format

  parse_format(Str $string) : Str

The parse_format method replaces each C<{{plugin.name}}> in the string with the
result of the evaluation of the plugin specified in the token, e.g.
C<{{person.name}}> is replaced with the result of executing the
L<Faker::Plugin::PersonName> plugin.

=over 4

=item parse_format example #1

  # given: synopsis

  $example->parse_format('{{person.name}}')

=back

=cut

=head2 process

  process(Tuple[Str, Str] $lookup, Maybe[HashRef[Int]] $options) : Str

The process method performs a lookup and replacement in the lookup results
based on the options specified. Valid options are C<all_markers>,
C<lex_markers>, C<line_markers>, and C<number_markers>.

=over 4

=item process example #1

  # given: synopsis

  $example->process(['person', 'username'], {
    all_markers => 1
  })

=back

=cut

=head2 process_format

  process_format(Str $format) : Str

The process_format method dispatches to a plugin or performs a lookup and
returns the result.

=over 4

=item process_format example #1

  # given: synopsis

  $example->process_format('person.username')

=back

=cut

=head2 process_lookup

  process_lookup(Tuple[Str, Str] $lookup) : Str

The process_lookup method performs a lookup and returns the result.

=over 4

=item process_lookup example #1

  # given: synopsis

  $example->process(['person', 'username'])

=back

=cut

=head2 process_markers

  process_markers(Str $string) : Str

The process_markers method replaces all markers, e.g. C<?>, C<#>, C<%>, with
their random character counterparts.

=over 4

=item process_markers example #1

  # given: synopsis

  $example->process_markers('#.%.#.?%?')

=back

=cut

=head2 random_array_item

  random_array_item(ArrayRef $items) : Any

The random_array_item method returns a random element from the C<arrayref>
provided.

=over 4

=item random_array_item example #1

  # given: synopsis

  $example->random_item(['a', 'b', 'c'])

=back

=cut

=head2 random_between

  random_between(Maybe[Int] $from, Maybe[Int] $to) : Int

The random_between method returns a random number between the integers
provided, or between C<0> and C<2147483647>.

=over 4

=item random_between example #1

  # given: synopsis

  $example->random_between

=back

=cut

=head2 random_digit

  random_digit() : Int

The random_digit method returns a random digit betwee C<0> and C<10>.

=over 4

=item random_digit example #1

  # given: synopsis

  $example->random_digit

=back

=cut

=head2 random_digit_not_zero

  random_digit_not_zero() : Int

The random_digit_not_zero method returns a random digit betwee C<1> and C<10>.

=over 4

=item random_digit_not_zero example #1

  # given: synopsis

  $example->random_digit_not_zero

=back

=cut

=head2 random_float

  random_float(Maybe[Int] $place, Maybe[Int] $min, Maybe[Int] $max) : Num

The random_float method returns a random floating-point number between the
integers provided.

=over 4

=item random_float example #1

  # given: synopsis

  $example->random_float

=back

=over 4

=item random_float example #2

  # given: synopsis

  $example->random_float(1, 10, 200)

=back

=over 4

=item random_float example #3

  # given: synopsis

  $example->random_float(2, 10, 200)

=back

=cut

=head2 random_hash_item

  random_hash_item(HashRef $items) : Any

The random_hash_item method returns a random element from the C<hashref>
provided.

=over 4

=item random_hash_item example #1

  # given: synopsis

  $example->random_item({'a' => 1, 'b' => 2, 'c' => 3})

=back

=cut

=head2 random_item

  random_item(ArrayRef | HashRef $items) : Any

The random_item method returns a random element from the C<arrayref> or
C<hashref> provided.

=over 4

=item random_item example #1

  # given: synopsis

  $example->random_item(['a', 'b', 'c'])

=back

=over 4

=item random_item example #2

  # given: synopsis

  $example->random_item({'a' => 1, 'b' => 2, 'c' => 3})

=back

=cut

=head2 random_letter

  random_letter() : Str

The random_letter method returns a random alphabetic character.

=over 4

=item random_letter example #1

  # given: synopsis

  $example->random_letter

=back

=cut

=head2 random_number

  random_number() : Num

The random_number method returns a random number.

=over 4

=item random_number example #1

  # given: synopsis

  $example->random_number

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

L<Elixir Faker|https://github.com/elixirs/faker>

=head1 PROJECT

L<Wiki|https://github.com/iamalnewkirk/faker/wiki>

L<Project|https://github.com/iamalnewkirk/faker>

L<Initiatives|https://github.com/iamalnewkirk/faker/projects>

L<Milestones|https://github.com/iamalnewkirk/faker/milestones>

L<Contributing|https://github.com/iamalnewkirk/faker/blob/master/CONTRIBUTE.md>

L<Issues|https://github.com/iamalnewkirk/faker/issues>

=cut
