package main;

use 5.018;

use strict;
use warnings;

use Test::More;
use Venus::Test;

my $test = test(__FILE__);
my $seed = 42;

=name

Faker::Plugin::JaJp::AddressCityName

=cut

$test->for('name');

=tagline

Address City Name

=cut

$test->for('tagline');

=abstract

Address City Name for Faker

=cut

$test->for('abstract');

=includes

method: new
method: execute

=cut

$test->for('includes');

=synopsis

  package main;

  use Faker::Plugin::JaJp::AddressCityName;

  my $plugin = Faker::Plugin::JaJp::AddressCityName->new;

  # bless(..., "Faker::Plugin::JaJp::AddressCityName")

=cut

$test->for('synopsis', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  ok $result->isa('Faker::Plugin::JaJp::AddressCityName');

  $result
});

=description

This package provides methods for generating fake data for address city name.

+=encoding utf8

=cut

$test->for('description');

=inherits

Faker::Plugin::JaJp

=cut

$test->for('inherits');

=method execute

The execute method returns a returns a random fake address city name.

=signature execute

  execute(HashRef $data) (Str)

=metadata execute

{
  since => '1.10',
}

=example-1 execute

  package main;

  use Faker::Plugin::JaJp::AddressCityName;

  my $plugin = Faker::Plugin::JaJp::AddressCityName->new;

  # bless(..., "Faker::Plugin::JaJp::AddressCityName")

  # my $result = $plugin->execute;

  # '井上市';

  # my $result = $plugin->execute;

  # '高橋市';

  # my $result = $plugin->execute;

  # '鈴木市';

=cut

$test->for('example', 1, 'execute', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  ok $result->isa('Faker::Plugin::JaJp::AddressCityName');
  ok $result->faker;
  ok $result->faker->random->reseed($seed);
  ok $result->faker->random->pick; # reset randomizer
  is $result->execute, '井上市';
  ok $result->faker->random->pick; # reset randomizer
  is $result->execute, '高橋市';
  ok $result->faker->random->pick; # reset randomizer
  is $result->execute, '鈴木市';

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

  use Faker::Plugin::JaJp::AddressCityName;

  my $plugin = Faker::Plugin::JaJp::AddressCityName->new;

  # bless(..., "Faker::Plugin::JaJp::AddressCityName")

=cut

$test->for('example', 1, 'new', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  ok $result->isa('Faker::Plugin::JaJp::AddressCityName');
  ok $result->faker;

  $result
});

# END

$test->render('lib/Faker/Plugin/JaJp/AddressCityName.pod') if $ENV{RENDER};

ok 1 and done_testing;
