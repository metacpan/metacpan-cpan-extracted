package main;

use 5.018;

use strict;
use warnings;

use Test::More;
use Venus::Test;

my $test = test(__FILE__);
my $seed = 42;

=name

Faker::Plugin::JaJp::AddressStreetName

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

  use Faker::Plugin::JaJp::AddressStreetName;

  my $plugin = Faker::Plugin::JaJp::AddressStreetName->new;

  # bless(..., "Faker::Plugin::JaJp::AddressStreetName")

=cut

$test->for('synopsis', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  ok $result->isa('Faker::Plugin::JaJp::AddressStreetName');

  $result
});

=description

This package provides methods for generating fake data for address street name.

+=encoding utf8

=cut

$test->for('description');

=inherits

Faker::Plugin::JaJp

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

  use Faker::Plugin::JaJp::AddressStreetName;

  my $plugin = Faker::Plugin::JaJp::AddressStreetName->new;

  # bless(..., "Faker::Plugin::JaJp::AddressStreetName")

  # my $result = $plugin->execute;

  # '井上町';

  # my $result = $plugin->execute;

  # '高橋町';

  # my $result = $plugin->execute;

  # '鈴木町';

=cut

$test->for('example', 1, 'execute', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  ok $result->isa('Faker::Plugin::JaJp::AddressStreetName');
  ok $result->faker;
  ok $result->faker->random->reseed($seed);
  ok $result->faker->random->make; # reset randomizer
  is $result->execute, '井上町';
  ok $result->faker->random->make; # reset randomizer
  is $result->execute, '高橋町';
  ok $result->faker->random->make; # reset randomizer
  is $result->execute, '鈴木町';

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

  use Faker::Plugin::JaJp::AddressStreetName;

  my $plugin = Faker::Plugin::JaJp::AddressStreetName->new;

  # bless(..., "Faker::Plugin::JaJp::AddressStreetName")

=cut

$test->for('example', 1, 'new', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  ok $result->isa('Faker::Plugin::JaJp::AddressStreetName');
  ok $result->faker;

  $result
});

# END

$test->render('lib/Faker/Plugin/JaJp/AddressStreetName.pod') if $ENV{RENDER};

ok 1 and done_testing;
