package main;

use 5.018;

use strict;
use warnings;

use Test::More;
use Venus::Test;

my $test = test(__FILE__);
my $seed = 42;

=name

Faker::Plugin::EsEs::AddressCountryName

=cut

$test->for('name');

=tagline

Address Country Name

=cut

$test->for('tagline');

=abstract

Address Country Name for Faker

=cut

$test->for('abstract');

=includes

method: new
method: execute

=cut

$test->for('includes');

=synopsis

  package main;

  use Faker::Plugin::EsEs::AddressCountryName;

  my $plugin = Faker::Plugin::EsEs::AddressCountryName->new;

  # bless(..., "Faker::Plugin::EsEs::AddressCountryName")

=cut

$test->for('synopsis', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  ok $result->isa('Faker::Plugin::EsEs::AddressCountryName');

  $result
});

=description

This package provides methods for generating fake data for address country name.

+=encoding utf8

=cut

$test->for('description');

=inherits

Faker::Plugin::EsEs

=cut

$test->for('inherits');

=method execute

The execute method returns a returns a random fake address country name.

=signature execute

  execute(HashRef $data) (Str)

=metadata execute

{
  since => '1.10',
}

=example-1 execute

  package main;

  use Faker::Plugin::EsEs::AddressCountryName;

  my $plugin = Faker::Plugin::EsEs::AddressCountryName->new;

  # bless(..., "Faker::Plugin::EsEs::AddressCountryName")

  # my $result = $plugin->execute;

  # 'Francia';

  # my $result = $plugin->execute;

  # 'India';

  # my $result = $plugin->execute;

  # 'Suazilandia';

=cut

$test->for('example', 1, 'execute', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  ok $result->isa('Faker::Plugin::EsEs::AddressCountryName');
  ok $result->faker;
  ok $result->faker->random->reseed($seed);
  ok $result->faker->random->make; # reset randomizer
  is $result->execute, 'Francia';
  ok $result->faker->random->make; # reset randomizer
  is $result->execute, 'India';
  ok $result->faker->random->make; # reset randomizer
  is $result->execute, 'Suazilandia';

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

  use Faker::Plugin::EsEs::AddressCountryName;

  my $plugin = Faker::Plugin::EsEs::AddressCountryName->new;

  # bless(..., "Faker::Plugin::EsEs::AddressCountryName")

=cut

$test->for('example', 1, 'new', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  ok $result->isa('Faker::Plugin::EsEs::AddressCountryName');
  ok $result->faker;

  $result
});

# END

$test->render('lib/Faker/Plugin/EsEs/AddressCountryName.pod') if $ENV{RENDER};

ok 1 and done_testing;
