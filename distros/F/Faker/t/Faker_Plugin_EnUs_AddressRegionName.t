package main;

use 5.018;

use strict;
use warnings;

use Test::More;
use Venus::Test;

my $test = test(__FILE__);
my $seed = 42;

=name

Faker::Plugin::EnUs::AddressRegionName

=cut

$test->for('name');

=tagline

Address Region Name

=cut

$test->for('tagline');

=abstract

Address Region Name for Faker

=cut

$test->for('abstract');

=includes

method: new
method: execute

=cut

$test->for('includes');

=synopsis

  package main;

  use Faker::Plugin::EnUs::AddressRegionName;

  my $plugin = Faker::Plugin::EnUs::AddressRegionName->new;

  # bless(..., "Faker::Plugin::EnUs::AddressRegionName")

=cut

$test->for('synopsis', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  ok $result->isa('Faker::Plugin::EnUs::AddressRegionName');

  $result
});

=description

This package provides methods for generating fake data for address region name.

+=encoding utf8

=cut

$test->for('description');

=inherits

Faker::Plugin::EnUs

=cut

$test->for('inherits');

=method execute

The execute method returns a returns a random fake address region name.

=signature execute

  execute(HashRef $data) (Str)

=metadata execute

{
  since => '1.10',
}

=example-1 execute

  package main;

  use Faker::Plugin::EnUs::AddressRegionName;

  my $plugin = Faker::Plugin::EnUs::AddressRegionName->new;

  # bless(..., "Faker::Plugin::EnUs::AddressRegionName")

  # my $result = $plugin->execute;

  # "Massachusetts";

  # my $result = $plugin->execute;

  # "MO";

  # my $result = $plugin->execute;

  # "NE";

=cut

$test->for('example', 1, 'execute', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  ok $result->isa('Faker::Plugin::EnUs::AddressRegionName');
  ok $result->faker;
  ok $result->faker->random->reseed($seed);
  ok $result->faker->random->make; # reset randomizer
  is $result->execute, "Massachusetts";
  ok $result->faker->random->make; # reset randomizer
  is $result->execute, "MO";
  ok $result->faker->random->make; # reset randomizer
  is $result->execute, "NE";

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

  use Faker::Plugin::EnUs::AddressRegionName;

  my $plugin = Faker::Plugin::EnUs::AddressRegionName->new;

  # bless(..., "Faker::Plugin::EnUs::AddressRegionName")

=cut

$test->for('example', 1, 'new', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  ok $result->isa('Faker::Plugin::EnUs::AddressRegionName');
  ok $result->faker;

  $result
});

# END

$test->render('lib/Faker/Plugin/EnUs/AddressRegionName.pod') if $ENV{RENDER};

ok 1 and done_testing;
