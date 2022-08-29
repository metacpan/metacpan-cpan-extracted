package main;

use 5.018;

use strict;
use warnings;

use Test::More;
use Venus::Test;

my $test = test(__FILE__);
my $seed = 42;

=name

Faker::Plugin::EnUs::AddressStreetAddress

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

  use Faker::Plugin::EnUs::AddressStreetAddress;

  my $plugin = Faker::Plugin::EnUs::AddressStreetAddress->new;

  # bless(..., "Faker::Plugin::EnUs::AddressStreetAddress")

=cut

$test->for('synopsis', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  ok $result->isa('Faker::Plugin::EnUs::AddressStreetAddress');

  $result
});

=description

This package provides methods for generating fake data for address street address.

+=encoding utf8

=cut

$test->for('description');

=inherits

Faker::Plugin::EnUs

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

  use Faker::Plugin::EnUs::AddressStreetAddress;

  my $plugin = Faker::Plugin::EnUs::AddressStreetAddress->new;

  # bless(..., "Faker::Plugin::EnUs::AddressStreetAddress")

  # my $result = $plugin->execute;

  # "4084 Mayer Brook Suite 94";

  # my $result = $plugin->execute;

  # "9908 Mustafa Harbor Suite 828";

  # my $result = $plugin->execute;

  # "958 Greenholt Orchard";

=cut

$test->for('example', 1, 'execute', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  ok $result->isa('Faker::Plugin::EnUs::AddressStreetAddress');
  ok $result->faker;
  ok $result->faker->random->reseed($seed);
  ok $result->faker->random->make; # reset randomizer
  is $result->execute, "4084 Mayer Brook Suite 94";
  ok $result->faker->random->make; # reset randomizer
  is $result->execute, "9908 Mustafa Harbor Suite 828";
  ok $result->faker->random->make; # reset randomizer
  is $result->execute, "958 Greenholt Orchard";

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

  use Faker::Plugin::EnUs::AddressStreetAddress;

  my $plugin = Faker::Plugin::EnUs::AddressStreetAddress->new;

  # bless(..., "Faker::Plugin::EnUs::AddressStreetAddress")

=cut

$test->for('example', 1, 'new', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  ok $result->isa('Faker::Plugin::EnUs::AddressStreetAddress');
  ok $result->faker;

  $result
});

# END

$test->render('lib/Faker/Plugin/EnUs/AddressStreetAddress.pod') if $ENV{RENDER};

ok 1 and done_testing;
