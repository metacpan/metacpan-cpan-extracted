use 5.014;

use strict;
use warnings;
use routines;

use Test::Auto;
use Test::More;

=name

Faker::Plugin::InternetEmailDomain

=cut

=abstract

Internet Email Domain Plugin for Faker

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
  use Faker::Plugin::InternetEmailDomain;

  my $f = Faker->new;
  my $p = Faker::Plugin::InternetEmailDomain->new(faker => $f);

  my $plugin = $p;

=cut

=inherits

Data::Object::Plugin

=cut

=attributes

faker: ro, req, ConsumerOf["Faker::Maker"]

=cut

=description

This package provides methods for generating fake internet email domain data.

=cut

=method execute

The execute method returns a random fake internet email domain.

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
