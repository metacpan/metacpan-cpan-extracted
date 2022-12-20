package main;

use 5.018;

use strict;
use warnings;

use Test::More;
use Venus::Test;

my $test = test(__FILE__);
my $seed = 42;

=name

Faker::Plugin::EsEs::AddressLine1

=cut

$test->for('name');

=tagline

Address Line1

=cut

$test->for('tagline');

=abstract

Address Line1 for Faker

=cut

$test->for('abstract');

=includes

method: new
method: execute

=cut

$test->for('includes');

=synopsis

  package main;

  use Faker::Plugin::EsEs::AddressLine1;

  my $plugin = Faker::Plugin::EsEs::AddressLine1->new;

  # bless(..., "Faker::Plugin::EsEs::AddressLine1")

=cut

$test->for('synopsis', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  ok $result->isa('Faker::Plugin::EsEs::AddressLine1');

  $result
});

=description

This package provides methods for generating fake data for address line1.

+=encoding utf8

=cut

$test->for('description');

=inherits

Faker::Plugin::EsEs

=cut

$test->for('inherits');

=method execute

The execute method returns a returns a random fake address line1.

=signature execute

  execute(HashRef $data) (Str)

=metadata execute

{
  since => '1.10',
}

=example-1 execute

  package main;

  use Faker::Plugin::EsEs::AddressLine1;

  my $plugin = Faker::Plugin::EsEs::AddressLine1->new;

  # bless(..., "Faker::Plugin::EsEs::AddressLine1")

  # my $result = $plugin->execute;

  # 'Praza Rocío, 50, 94º A, 44390, Cornejo del Penedès';

  # my $result = $plugin->execute;

  # 'Plaça Pilar, 558, Entre suelo 5º, 23411, La Vargas';

  # my $result = $plugin->execute;

  # 'Camino Pedro, 15, 9º, 87686, As Mayorga';

=cut

$test->for('example', 1, 'execute', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  ok $result->isa('Faker::Plugin::EsEs::AddressLine1');
  ok $result->faker;
  ok $result->faker->random->reseed($seed);
  ok $result->faker->random->pick; # reset randomizer
  is $result->execute, 'Praza Rocío, 50, 94º A, 44390, Cornejo del Penedès';
  ok $result->faker->random->pick; # reset randomizer
  is $result->execute, 'Plaça Pilar, 558, Entre suelo 5º, 23411, La Vargas';
  ok $result->faker->random->pick; # reset randomizer
  is $result->execute, 'Camino Pedro, 15, 9º, 87686, As Mayorga';

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

  use Faker::Plugin::EsEs::AddressLine1;

  my $plugin = Faker::Plugin::EsEs::AddressLine1->new;

  # bless(..., "Faker::Plugin::EsEs::AddressLine1")

=cut

$test->for('example', 1, 'new', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  ok $result->isa('Faker::Plugin::EsEs::AddressLine1');
  ok $result->faker;

  $result
});

# END

$test->render('lib/Faker/Plugin/EsEs/AddressLine1.pod') if $ENV{RENDER};

ok 1 and done_testing;
