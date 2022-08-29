package main;

use 5.018;

use strict;
use warnings;

use Test::More;
use Venus::Test;

my $test = test(__FILE__);
my $seed = 42;

=name

Faker::Plugin::EsEs::AddressLines

=cut

$test->for('name');

=tagline

Address Lines

=cut

$test->for('tagline');

=abstract

Address Lines for Faker

=cut

$test->for('abstract');

=includes

method: new
method: execute

=cut

$test->for('includes');

=synopsis

  package main;

  use Faker::Plugin::EsEs::AddressLines;

  my $plugin = Faker::Plugin::EsEs::AddressLines->new;

  # bless(..., "Faker::Plugin::EsEs::AddressLines")

=cut

$test->for('synopsis', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  ok $result->isa('Faker::Plugin::EsEs::AddressLines');

  $result
});

=description

This package provides methods for generating fake data for address lines.

+=encoding utf8

=cut

$test->for('description');

=inherits

Faker::Plugin::EsEs

=cut

$test->for('inherits');

=method execute

The execute method returns a returns a random fake address lines.

=signature execute

  execute(HashRef $data) (Str)

=metadata execute

{
  since => '1.10',
}

=example-1 execute

  package main;

  use Faker::Plugin::EsEs::AddressLines;

  my $plugin = Faker::Plugin::EsEs::AddressLines->new;

  # bless(..., "Faker::Plugin::EsEs::AddressLines")

  # my $result = $plugin->execute;

  # "Praza Rocío, 50, 94º A\nEl Apodaca, Zamora 22037";

  # my $result = $plugin->execute;

  # "Paseo Salas, 558, Entre suelo 5º\nLos Blanco del Barco, La Rioja 96220";

  # my $result = $plugin->execute;

  # "Praza Nevárez, 12, 8º\nLas Negrón, Valladolid 56907";

=cut

$test->for('example', 1, 'execute', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  ok $result->isa('Faker::Plugin::EsEs::AddressLines');
  ok $result->faker;
  ok $result->faker->random->reseed($seed);
  ok $result->faker->random->make; # reset randomizer
  is $result->execute, 'Praza Rocío, 50, 94º A
El Apodaca, Zamora 22037';
  ok $result->faker->random->make; # reset randomizer
  is $result->execute, 'Paseo Salas, 558, Entre suelo 5º
Los Blanco del Barco, La Rioja 96220';
  ok $result->faker->random->make; # reset randomizer
  is $result->execute, 'Praza Nevárez, 12, 8º
Las Negrón, Valladolid 56907';

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

  use Faker::Plugin::EsEs::AddressLines;

  my $plugin = Faker::Plugin::EsEs::AddressLines->new;

  # bless(..., "Faker::Plugin::EsEs::AddressLines")

=cut

$test->for('example', 1, 'new', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  ok $result->isa('Faker::Plugin::EsEs::AddressLines');
  ok $result->faker;

  $result
});

# END

$test->render('lib/Faker/Plugin/EsEs/AddressLines.pod') if $ENV{RENDER};

ok 1 and done_testing;
