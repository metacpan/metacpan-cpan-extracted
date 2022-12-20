package main;

use 5.018;

use strict;
use warnings;

use Test::More;
use Venus::Test;

my $test = test(__FILE__);
my $seed = 42;

=name

Faker::Plugin::EnUs::AddressStateName

=cut

$test->for('name');

=tagline

Address State Name

=cut

$test->for('tagline');

=abstract

Address State Name for Faker

=cut

$test->for('abstract');

=includes

method: new
method: execute

=cut

$test->for('includes');

=synopsis

  package main;

  use Faker::Plugin::EnUs::AddressStateName;

  my $plugin = Faker::Plugin::EnUs::AddressStateName->new;

  # bless(..., "Faker::Plugin::EnUs::AddressStateName")

=cut

$test->for('synopsis', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  ok $result->isa('Faker::Plugin::EnUs::AddressStateName');

  $result
});

=description

This package provides methods for generating fake data for address state name.

+=encoding utf8

=cut

$test->for('description');

=inherits

Faker::Plugin::EnUs

=cut

$test->for('inherits');

=method execute

The execute method returns a returns a random fake address state name.

=signature execute

  execute(HashRef $data) (Str)

=metadata execute

{
  since => '1.10',
}

=example-1 execute

  package main;

  use Faker::Plugin::EnUs::AddressStateName;

  my $plugin = Faker::Plugin::EnUs::AddressStateName->new;

  # bless(..., "Faker::Plugin::EnUs::AddressStateName")

  # my $result = $plugin->execute;

  # "Kentucky";

  # my $result = $plugin->execute;

  # "Massachusetts";

  # my $result = $plugin->execute;

  # "Texas";

=cut

$test->for('example', 1, 'execute', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  ok $result->isa('Faker::Plugin::EnUs::AddressStateName');
  ok $result->faker;
  ok $result->faker->random->reseed($seed);
  ok $result->faker->random->pick; # reset randomizer
  is $result->execute, "Kentucky";
  ok $result->faker->random->pick; # reset randomizer
  is $result->execute, "Massachusetts";
  ok $result->faker->random->pick; # reset randomizer
  is $result->execute, "Texas";

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

  use Faker::Plugin::EnUs::AddressStateName;

  my $plugin = Faker::Plugin::EnUs::AddressStateName->new;

  # bless(..., "Faker::Plugin::EnUs::AddressStateName")

=cut

$test->for('example', 1, 'new', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  ok $result->isa('Faker::Plugin::EnUs::AddressStateName');
  ok $result->faker;

  $result
});

# END

$test->render('lib/Faker/Plugin/EnUs/AddressStateName.pod') if $ENV{RENDER};

ok 1 and done_testing;
