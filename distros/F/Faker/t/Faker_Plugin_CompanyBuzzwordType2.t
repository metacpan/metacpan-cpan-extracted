use 5.014;

use strict;
use warnings;
use routines;

use Test::Auto;
use Test::More;

=name

Faker::Plugin::CompanyBuzzwordType2

=cut

=abstract

Company Buzzword Type2 Plugin for Faker

=cut

=includes

method: execute

=cut

=libraries

Types::Standard

=cut

=synopsis

  package main;

  use Faker;
  use Faker::Plugin::CompanyBuzzwordType2;

  my $f = Faker->new;
  my $p = Faker::Plugin::CompanyBuzzwordType2->new(faker => $f);

  my $plugin = $p;

=cut

=inherits

Data::Object::Plugin

=cut

=attributes

faker: ro, req, ConsumerOf["Faker::Maker"]

=cut

=description

This package provides methods for generating fake company buzzword type2 data.

=cut

=method execute

The execute method returns a random fake company buzzword type2.

=signature execute

execute() : Str

=example-1 execute

  # given: synopsis

  $p->execute;

=cut

package main;

my $test = testauto(__FILE__);

my $subs = $test->standard;

$subs->synopsis(fun($tryable) {
  ok my $result = $tryable->result;

  $result
});

$subs->example(-1, 'execute', 'method', fun($tryable) {
  ok my $result = $tryable->result;

  $result
});

ok 1 and done_testing;
