package main;

use 5.018;

use strict;
use warnings;

use Test::More;
use Venus::Test;

my $test = test(__FILE__);
my $seed = 42;

=name

Faker::Plugin::AddressLongitude

=cut

$test->for('name');

=tagline

Address Longitude

=cut

$test->for('tagline');

=abstract

Address Longitude for Faker

=cut

$test->for('abstract');

=includes

method: new
method: execute

=cut

$test->for('includes');

=synopsis

  package main;

  use Faker::Plugin::AddressLongitude;

  my $plugin = Faker::Plugin::AddressLongitude->new;

  # bless(..., "Faker::Plugin::AddressLongitude")

=cut

$test->for('synopsis', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  ok $result->isa('Faker::Plugin::AddressLongitude');

  $result
});

=description

This package provides methods for generating fake data for address longitude.

+=encoding utf8

=cut

$test->for('description');

=inherits

Faker::Plugin

=cut

$test->for('inherits');

=method execute

The execute method returns a returns a random fake address longitude.

=signature execute

  execute(HashRef $data) (Str)

=metadata execute

{
  since => '1.10',
}

=example-1 execute

  package main;

  use Faker::Plugin::AddressLongitude;

  my $plugin = Faker::Plugin::AddressLongitude->new;

  # bless(..., "Faker::Plugin::AddressLongitude")

  # my $result = $plugin->execute;

  # 30.843133;

  # my $result = $plugin->execute;

  # 77.079663;

  # my $result = $plugin->execute;

  # -41.660985;

=cut

$test->for('example', 1, 'execute', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  ok $result->isa('Faker::Plugin::AddressLongitude');
  ok $result->faker;
  ok $result->faker->random->reseed($seed);
  ok $result->faker->random->pick; # reset randomizer
  is $result->execute, 30.843133;
  ok $result->faker->random->pick; # reset randomizer
  is $result->execute, 77.079663;
  ok $result->faker->random->pick; # reset randomizer
  is $result->execute, -41.660985;

  $result
});

=method new

The new method returns a new instance of the class.

=signature new

  new(HashRef $data) (Plugin)

=metadata new

{
  since => '1.10',
}

=example-1 new

  package main;

  use Faker::Plugin::AddressLongitude;

  my $plugin = Faker::Plugin::AddressLongitude->new;

  # bless(..., "Faker::Plugin::AddressLongitude")

=cut

$test->for('example', 1, 'new', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  ok $result->isa('Faker::Plugin::AddressLongitude');
  ok $result->faker;

  $result
});

# END

$test->render('lib/Faker/Plugin/AddressLongitude.pod') if $ENV{RENDER};

ok 1 and done_testing;
