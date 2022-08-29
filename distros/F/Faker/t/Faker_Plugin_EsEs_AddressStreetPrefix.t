package main;

use 5.018;

use strict;
use warnings;

use Test::More;
use Venus::Test;

my $test = test(__FILE__);
my $seed = 42;

=name

Faker::Plugin::EsEs::AddressStreetPrefix

=cut

$test->for('name');

=tagline

Address Street Prefix

=cut

$test->for('tagline');

=abstract

Address Street Prefix for Faker

=cut

$test->for('abstract');

=includes

method: new
method: execute

=cut

$test->for('includes');

=synopsis

  package main;

  use Faker::Plugin::EsEs::AddressStreetPrefix;

  my $plugin = Faker::Plugin::EsEs::AddressStreetPrefix->new;

  # bless(..., "Faker::Plugin::EsEs::AddressStreetPrefix")

=cut

$test->for('synopsis', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  ok $result->isa('Faker::Plugin::EsEs::AddressStreetPrefix');

  $result
});

=description

This package provides methods for generating fake data for address street prefix.

+=encoding utf8

=cut

$test->for('description');

=inherits

Faker::Plugin::EsEs

=cut

$test->for('inherits');

=method execute

The execute method returns a returns a random fake address street prefix.

=signature execute

  execute(HashRef $data) (Str)

=metadata execute

{
  since => '1.10',
}

=example-1 execute

  package main;

  use Faker::Plugin::EsEs::AddressStreetPrefix;

  my $plugin = Faker::Plugin::EsEs::AddressStreetPrefix->new;

  # bless(..., "Faker::Plugin::EsEs::AddressStreetPrefix")

  # my $result = $plugin->execute;

  # 'Travesía';

  # my $result = $plugin->execute;

  # 'Camino';

  # my $result = $plugin->execute;

  # 'Praza';

=cut

$test->for('example', 1, 'execute', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  ok $result->isa('Faker::Plugin::EsEs::AddressStreetPrefix');
  ok $result->faker;
  ok $result->faker->random->reseed($seed);
  ok $result->faker->random->make; # reset randomizer
  is $result->execute, 'Travesía';
  ok $result->faker->random->make; # reset randomizer
  is $result->execute, 'Camino';
  ok $result->faker->random->make; # reset randomizer
  is $result->execute, 'Praza';

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

  use Faker::Plugin::EsEs::AddressStreetPrefix;

  my $plugin = Faker::Plugin::EsEs::AddressStreetPrefix->new;

  # bless(..., "Faker::Plugin::EsEs::AddressStreetPrefix")

=cut

$test->for('example', 1, 'new', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  ok $result->isa('Faker::Plugin::EsEs::AddressStreetPrefix');
  ok $result->faker;

  $result
});

# END

$test->render('lib/Faker/Plugin/EsEs/AddressStreetPrefix.pod') if $ENV{RENDER};

ok 1 and done_testing;
