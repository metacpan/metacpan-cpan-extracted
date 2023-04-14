package main;

use 5.018;

use strict;
use warnings;

use Test::More;
use Venus::Test;

my $test = test(__FILE__);
my $seed = 42;

=name

Faker::Plugin::EnUs::AddressCountryName

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

  use Faker::Plugin::EnUs::AddressCountryName;

  my $plugin = Faker::Plugin::EnUs::AddressCountryName->new;

  # bless(..., "Faker::Plugin::EnUs::AddressCountryName")

=cut

$test->for('synopsis', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  ok $result->isa('Faker::Plugin::EnUs::AddressCountryName');

  $result
});

=description

This package provides methods for generating fake data for address country name.

+=encoding utf8

=cut

$test->for('description');

=inherits

Faker::Plugin::EnUs

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

  use Faker::Plugin::EnUs::AddressCountryName;

  my $plugin = Faker::Plugin::EnUs::AddressCountryName->new;

  # bless(..., "Faker::Plugin::EnUs::AddressCountryName")

  # my $result = opluginresult->execute;

  # "Greenland"

  # my $result = opluginresult->execute;

  # "Ireland"

  # my $result = opluginresult->execute;

  # "Svalbard & Jan Mayen Islands"

=cut

$test->for('example', 1, 'execute', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  ok $result->isa('Faker::Plugin::EnUs::AddressCountryName');
  ok $result->faker;
  ok $result->faker->random->reseed($seed);
  ok $result->faker->random->pick; # reset randomizer
  is $result->execute, "Greenland";
  ok $result->faker->random->pick; # reset randomizer
  is $result->execute, "Ireland";
  ok $result->faker->random->pick; # reset randomizer
  is $result->execute, "Svalbard & Jan Mayen Islands";

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

  use Faker::Plugin::EnUs::AddressCountryName;

  my $plugin = Faker::Plugin::EnUs::AddressCountryName->new;

  # bless(..., "Faker::Plugin::EnUs::AddressCountryName")

=cut

$test->for('example', 1, 'new', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  ok $result->isa('Faker::Plugin::EnUs::AddressCountryName');
  ok $result->faker;

  $result
});

=partials

t/Faker.t: pdml: authors
t/Faker.t: pdml: license

=cut

$test->for('partials');

# END

$test->render('lib/Faker/Plugin/EnUs/AddressCountryName.pod') if $ENV{RENDER};

ok 1 and done_testing;
