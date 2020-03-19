use 5.014;

use strict;
use warnings;
use routines;

use Test::Auto;
use Test::More;

=name

Faker::Maker

=cut

=abstract

Utility Role for Generating Fake Data

=cut

=includes

method: format_lex_markers
method: format_line_markers
method: format_number_markers
method: parse_format
method: process
method: process_format
method: process_lookup
method: process_markers
method: random_between
method: random_digit
method: random_digit_not_zero
method: random_float
method: random_item
method: random_array_item
method: random_hash_item
method: random_letter
method: random_number

=cut

=synopsis

  package Example;

  use Data::Object::Class;

  with 'Faker::Maker';

  package main;

  my $example = Example->new;

=cut

=libraries

Types::Standard

=cut

=description

This package provides methods for generating and selecting data randomly.

=cut

=method format_lex_markers

The format_lex_markers method replaces each C<?> character in the string with a
random letter.

=signature format_lex_markers

format_lex_markers(Str $string) : Str

=example-1 format_lex_markers

  # given: synopsis

  $example->format_lex_markers('???')

=cut

=method format_line_markers

The format_line_markers method replaces each escaped C<\n> (newline) character
in the string with a proper newline character.

=signature format_line_markers

format_line_markers(Str $string) : Str

=example-1 format_line_markers

  # given: synopsis

  $example->format_line_markers('foo\nbar')

=cut

=method format_number_markers

The format_number_markers method replaces each C<#> in the string with a random
digit, and each C<%> with a random non-zero digit.

=signature format_number_markers

format_number_markers(Str $string) : Str

=example-1 format_number_markers

  # given: synopsis

  $example->format_number_markers('#-%-#')

=cut

=method parse_format

The parse_format method replaces each C<{{plugin.name}}> in the string with the
result of the evaluation of the plugin specified in the token, e.g.
C<{{person.name}}> is replaced with the result of executing the
L<Faker::Plugin::PersonName> plugin.

=signature parse_format

parse_format(Str $string) : Str

=example-1 parse_format

  # given: synopsis

  $example->parse_format('{{person.name}}')

=cut

=method process

The process method performs a lookup and replacement in the lookup results
based on the options specified. Valid options are C<all_markers>,
C<lex_markers>, C<line_markers>, and C<number_markers>.

=signature process

process(Tuple[Str, Str] $lookup, Maybe[HashRef[Int]] $options) : Str

=example-1 process

  # given: synopsis

  $example->process(['person', 'username'], {
    all_markers => 1
  })

=cut

=method process_format

The process_format method dispatches to a plugin or performs a lookup and
returns the result.

=signature process_format

process_format(Str $format) : Str

=example-1 process_format

  # given: synopsis

  $example->process_format('person.username')

=cut

=method process_lookup

The process_lookup method performs a lookup and returns the result.

=signature process_lookup

process_lookup(Tuple[Str, Str] $lookup) : Str

=example-1 process_lookup

  # given: synopsis

  $example->process(['person', 'username'])

=cut

=method process_markers

The process_markers method replaces all markers, e.g. C<?>, C<#>, C<%>, with
their random character counterparts.

=signature process_markers

process_markers(Str $string) : Str

=example-1 process_markers

  # given: synopsis

  $example->process_markers('#.%.#.?%?')

=cut

=method random_between

The random_between method returns a random number between the integers
provided, or between C<0> and C<2147483647>.

=signature random_between

random_between(Maybe[Int] $from, Maybe[Int] $to) : Int

=example-1 random_between

  # given: synopsis

  $example->random_between

=cut

=method random_digit

The random_digit method returns a random digit betwee C<0> and C<10>.

=signature random_digit

random_digit() : Int

=example-1 random_digit

  # given: synopsis

  $example->random_digit

=cut

=method random_digit_not_zero

The random_digit_not_zero method returns a random digit betwee C<1> and C<10>.

=signature random_digit_not_zero

random_digit_not_zero() : Int

=example-1 random_digit_not_zero

  # given: synopsis

  $example->random_digit_not_zero

=cut

=method random_float

The random_float method returns a random floating-point number between the
integers provided.

=signature random_float

random_float(Maybe[Int] $place, Maybe[Int] $min, Maybe[Int] $max) : Num

=example-1 random_float

  # given: synopsis

  $example->random_float

=example-2 random_float

  # given: synopsis

  $example->random_float(1, 10, 200)

=example-3 random_float

  # given: synopsis

  $example->random_float(2, 10, 200)

=cut

=method random_item

The random_item method returns a random element from the C<arrayref> or
C<hashref> provided.

=signature random_item

random_item(ArrayRef | HashRef $items) : Any

=example-1 random_item

  # given: synopsis

  $example->random_item(['a', 'b', 'c'])

=example-2 random_item

  # given: synopsis

  $example->random_item({'a' => 1, 'b' => 2, 'c' => 3})

=cut

=method random_array_item

The random_array_item method returns a random element from the C<arrayref>
provided.

=signature random_array_item

random_array_item(ArrayRef $items) : Any

=example-1 random_array_item

  # given: synopsis

  $example->random_item(['a', 'b', 'c'])

=cut

=method random_hash_item

The random_hash_item method returns a random element from the C<hashref>
provided.

=signature random_hash_item

random_hash_item(HashRef $items) : Any

=example-1 random_hash_item

  # given: synopsis

  $example->random_item({'a' => 1, 'b' => 2, 'c' => 3})

=cut

=method random_letter

The random_letter method returns a random alphabetic character.

=signature random_letter

random_letter() : Str

=example-1 random_letter

  # given: synopsis

  $example->random_letter

=cut

=method random_number

The random_number method returns a random number.

=signature random_number

random_number() : Num

=example-1 random_number

  # given: synopsis

  $example->random_number

=cut

{
  package Example::Plugin::Person;

  use base 'Faker::Plugin::Person';

  1;
}

{
  package Example::Plugin::PersonName;

  use base 'Faker::Plugin::PersonName';

  1;
}

{
  package Example::Plugin::PersonUsername;

  use base 'Faker::Plugin::PersonUsername';

  1;
}

package main;

my $test = testauto(__FILE__);

my $subs = $test->standard;

$subs->synopsis(fun($tryable) {
  ok my $result = $tryable->result;
  ok $result->does('Faker::Maker');

  $result
});

$subs->example(-1, 'format_lex_markers', 'method', fun($tryable) {
  ok my $result = $tryable->result;

  my $char = qr/[a-zA-Z]/;
  like $result, qr/$char$char$char/;

  $result
});

$subs->example(-1, 'format_line_markers', 'method', fun($tryable) {
  ok my $result = $tryable->result;
  like $result, qr/foo\nbar/;

  $result
});

$subs->example(-1, 'format_number_markers', 'method', fun($tryable) {
  ok my $result = $tryable->result;

  my @parts = split /-/, $result;
  ok $parts[0] >= 0 && $parts[0] <= 9;
  ok $parts[1] >= 1 && $parts[0] <= 9;
  ok $parts[2] >= 0 && $parts[0] <= 9;

  $result
});

$subs->example(-1, 'parse_format', 'method', fun($tryable) {
  ok my $result = $tryable->result;

  $result
});

$subs->example(-1, 'process', 'method', fun($tryable) {
  ok my $result = $tryable->result;

  $result
});

$subs->example(-1, 'process_format', 'method', fun($tryable) {
  ok my $result = $tryable->result;

  $result
});

$subs->example(-1, 'process_lookup', 'method', fun($tryable) {
  ok my $result = $tryable->result;

  $result
});

$subs->example(-1, 'process_markers', 'method', fun($tryable) {
  ok my $result = $tryable->result;

  my @parts = split /\./, $result;
  ok $parts[0] >= 0 && $parts[0] <= 9;
  ok $parts[1] >= 1 && $parts[0] <= 9;
  ok $parts[2] >= 0 && $parts[0] <= 9;
  like $parts[3], qr/^[a-zA-Z][0-9][a-zA-Z]$/;

  $result
});

$subs->example(-1, 'random_between', 'method', fun($tryable) {
  my $result = $tryable->result;
  ok $result =~ /^[\d\.]+$/;
  ok $result >= 0 && $result <= 2147483647;

  $result
});

$subs->example(-1, 'random_digit', 'method', fun($tryable) {
  my $result = $tryable->result;
  ok $result =~ /^[\d\.]+$/;
  ok $result >= 0 && $result <= 9;

  $result
});

$subs->example(-1, 'random_digit_not_zero', 'method', fun($tryable) {
  ok my $result = $tryable->result;
  ok $result >= 1 && $result <= 9;

  $result
});

$subs->example(-1, 'random_float', 'method', fun($tryable) {
  my $result = $tryable->result;
  ok $result =~ /^[\d\.]+$/;

  my @parts = split /\./, $result;
  like $parts[0], qr/^\d+$/;
  like $parts[1], qr/^\d+$/;

  $result
});

$subs->example(-2, 'random_float', 'method', fun($tryable) {
  my $result = $tryable->result;
  ok $result =~ /^[\d\.]+$/;
  ok $result >= 10 && $result <= 200;

  my @parts = split /\./, $result;
  like $parts[1], qr/^\d$/;

  $result
});

$subs->example(-3, 'random_float', 'method', fun($tryable) {
  my $result = $tryable->result;
  ok $result =~ /^[\d\.]+$/;
  ok $result >= 10 && $result <= 200;

  my @parts = split /\./, $result;
  like $parts[1], qr/^\d\d$/;

  $result
});

$subs->example(-1, 'random_item', 'method', fun($tryable) {
  ok my $result = $tryable->result;
  ok $result eq 'a' || $result eq 'b' || $result eq 'c';

  $result
});

$subs->example(-2, 'random_item', 'method', fun($tryable) {
  ok my $result = $tryable->result;
  ok $result == 1 || $result == 2 || $result == 3;

  $result
});

$subs->example(-1, 'random_array_item', 'method', fun($tryable) {
  ok my $result = $tryable->result;
  ok $result eq 'a' || $result eq 'b' || $result eq 'c';

  $result
});

$subs->example(-1, 'random_hash_item', 'method', fun($tryable) {
  ok my $result = $tryable->result;
  ok $result == 1 || $result == 2 || $result == 3;

  $result
});

$subs->example(-1, 'random_letter', 'method', fun($tryable) {
  ok my $result = $tryable->result;
  like $result, qr/[a-zA-Z]/;

  $result
});

$subs->example(-1, 'random_number', 'method', fun($tryable) {
  my $result = $tryable->result;
  ok $result =~ /^[\d\.]+$/;

  $result
});

ok 1 and done_testing;
