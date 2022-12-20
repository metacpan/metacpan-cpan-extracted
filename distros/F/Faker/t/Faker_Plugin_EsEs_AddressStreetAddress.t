package main;

use 5.018;

use strict;
use warnings;

use Test::More;
use Venus::Test;

my $test = test(__FILE__);
my $seed = 42;

=name

Faker::Plugin::EsEs::AddressStreetAddress

=cut

$test->for('name');

=tagline

Address Street Address

=cut

$test->for('tagline');

=abstract

Address Street Address for Faker

=cut

$test->for('abstract');

=includes

method: new
method: execute

=cut

$test->for('includes');

=synopsis

  package main;

  use Faker::Plugin::EsEs::AddressStreetAddress;

  my $plugin = Faker::Plugin::EsEs::AddressStreetAddress->new;

  # bless(..., "Faker::Plugin::EsEs::AddressStreetAddress")

=cut

$test->for('synopsis', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  ok $result->isa('Faker::Plugin::EsEs::AddressStreetAddress');

  $result
});

=description

This package provides methods for generating fake data for address street address.

+=encoding utf8

=cut

$test->for('description');

=inherits

Faker::Plugin::EsEs

=cut

$test->for('inherits');

=method execute

The execute method returns a returns a random fake address street address.

=signature execute

  execute(HashRef $data) (Str)

=metadata execute

{
  since => '1.10',
}

=example-1 execute

  package main;

  use Faker::Plugin::EsEs::AddressStreetAddress;

  my $plugin = Faker::Plugin::EsEs::AddressStreetAddress->new;

  # bless(..., "Faker::Plugin::EsEs::AddressStreetAddress")

  # my $result = $plugin->execute;

  # 'Avenida Marc, 55, 69º D';

  # my $result = $plugin->execute;

  # 'Travesía Victoria, 203, Ático 2º';

  # my $result = $plugin->execute;

  # 'Rúa Castillo, 58, Entre suelo 5º';

=cut

$test->for('example', 1, 'execute', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  ok $result->isa('Faker::Plugin::EsEs::AddressStreetAddress');
  ok $result->faker;
  ok $result->faker->random->reseed($seed);
  ok $result->faker->random->pick; # reset randomizer
  is $result->execute, 'Avenida Marc, 55, 69º D';
  ok $result->faker->random->pick; # reset randomizer
  is $result->execute, 'Travesía Victoria, 203, Ático 2º';
  ok $result->faker->random->pick; # reset randomizer
  is $result->execute, 'Rúa Castillo, 58, Entre suelo 5º';

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

  use Faker::Plugin::EsEs::AddressStreetAddress;

  my $plugin = Faker::Plugin::EsEs::AddressStreetAddress->new;

  # bless(..., "Faker::Plugin::EsEs::AddressStreetAddress")

=cut

$test->for('example', 1, 'new', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  ok $result->isa('Faker::Plugin::EsEs::AddressStreetAddress');
  ok $result->faker;

  $result
});

# END

$test->render('lib/Faker/Plugin/EsEs/AddressStreetAddress.pod') if $ENV{RENDER};

ok 1 and done_testing;
