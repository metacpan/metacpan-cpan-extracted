package main;

use 5.018;

use strict;
use warnings;

use Test::More;
use Venus::Test;

my $test = test(__FILE__);
my $seed = 42;

=name

Faker::Plugin::EnUs::AddressStreetName

=cut

$test->for('name');

=tagline

Address Street Name

=cut

$test->for('tagline');

=abstract

Address Street Name for Faker

=cut

$test->for('abstract');

=includes

method: new
method: execute

=cut

$test->for('includes');

=synopsis

  package main;

  use Faker::Plugin::EnUs::AddressStreetName;

  my $plugin = Faker::Plugin::EnUs::AddressStreetName->new;

  # bless(..., "Faker::Plugin::EnUs::AddressStreetName")

=cut

$test->for('synopsis', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  ok $result->isa('Faker::Plugin::EnUs::AddressStreetName');

  $result
});

=description

This package provides methods for generating fake data for address street name.

+=encoding utf8

=cut

$test->for('description');

=inherits

Faker::Plugin::EnUs

=cut

$test->for('inherits');

=method execute

The execute method returns a returns a random fake address street name.

=signature execute

  execute(HashRef $data) (Str)

=metadata execute

{
  since => '1.10',
}

=example-1 execute

  package main;

  use Faker::Plugin::EnUs::AddressStreetName;

  my $plugin = Faker::Plugin::EnUs::AddressStreetName->new;

  # bless(..., "Faker::Plugin::EnUs::AddressStreetName")

  # my $result = $plugin->execute;

  # "Russel Parkway";

  # my $result = $plugin->execute;

  # "Mayer Brook";

  # my $result = $plugin->execute;

  # "Kuhic Path";

=cut

$test->for('example', 1, 'execute', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  ok $result->isa('Faker::Plugin::EnUs::AddressStreetName');
  ok $result->faker;
  ok $result->faker->random->reseed($seed);
  ok $result->faker->random->make; # reset randomizer
  is $result->execute, "Russel Parkway";
  ok $result->faker->random->make; # reset randomizer
  is $result->execute, "Mayer Brook";
  ok $result->faker->random->make; # reset randomizer
  is $result->execute, "Kuhic Path";

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

  use Faker::Plugin::EnUs::AddressStreetName;

  my $plugin = Faker::Plugin::EnUs::AddressStreetName->new;

  # bless(..., "Faker::Plugin::EnUs::AddressStreetName")

=cut

$test->for('example', 1, 'new', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  ok $result->isa('Faker::Plugin::EnUs::AddressStreetName');
  ok $result->faker;

  $result
});

# END

$test->render('lib/Faker/Plugin/EnUs/AddressStreetName.pod') if $ENV{RENDER};

ok 1 and done_testing;
