package main;

use 5.018;

use strict;
use warnings;

use Test::More;
use Venus::Test;

my $test = test(__FILE__);
my $seed = 42;

=name

Faker::Plugin::PersonGender

=cut

$test->for('name');

=tagline

Person Gender

=cut

$test->for('tagline');

=abstract

Person Gender for Faker

=cut

$test->for('abstract');

=includes

method: new
method: execute

=cut

$test->for('includes');

=synopsis

  package main;

  use Faker::Plugin::PersonGender;

  my $plugin = Faker::Plugin::PersonGender->new;

  # bless(..., "Faker::Plugin::PersonGender")

=cut

$test->for('synopsis', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  ok $result->isa('Faker::Plugin::PersonGender');

  $result
});

=description

This package provides methods for generating fake data for person gender.

+=encoding utf8

=cut

$test->for('description');

=inherits

Faker::Plugin

=cut

$test->for('inherits');

=method execute

The execute method returns a returns a random fake person gender.

=signature execute

  execute(HashRef $data) (Str)

=metadata execute

{
  since => '1.10',
}

=example-1 execute

  package main;

  use Faker::Plugin::PersonGender;

  my $plugin = Faker::Plugin::PersonGender->new;

  # bless(..., "Faker::Plugin::PersonGender")

  # my $result = $plugin->execute;

  # "male";

  # my $result = $plugin->execute;

  # "male";

  # my $result = $plugin->execute;

  # "female";

=cut

$test->for('example', 1, 'execute', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  ok $result->isa('Faker::Plugin::PersonGender');
  ok $result->faker;
  ok $result->faker->random->reseed($seed);
  ok $result->faker->random->make; # reset randomizer
  is $result->execute, "male";
  ok $result->faker->random->make; # reset randomizer
  is $result->execute, "male";
  ok $result->faker->random->make; # reset randomizer
  is $result->execute, "female";

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

  use Faker::Plugin::PersonGender;

  my $plugin = Faker::Plugin::PersonGender->new;

  # bless(..., "Faker::Plugin::PersonGender")

=cut

$test->for('example', 1, 'new', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  ok $result->isa('Faker::Plugin::PersonGender');
  ok $result->faker;

  $result
});

# END

$test->render('lib/Faker/Plugin/PersonGender.pod') if $ENV{RENDER};

ok 1 and done_testing;
