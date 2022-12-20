package main;

use 5.018;

use strict;
use warnings;

use Test::More;
use Venus::Test;

my $test = test(__FILE__);
my $seed = 42;

=name

Faker::Plugin::PaymentCardExpiration

=cut

$test->for('name');

=tagline

Payment Card Expiration

=cut

$test->for('tagline');

=abstract

Payment Card Expiration for Faker

=cut

$test->for('abstract');

=includes

method: new
method: execute

=cut

$test->for('includes');

=synopsis

  package main;

  use Faker::Plugin::PaymentCardExpiration;

  my $plugin = Faker::Plugin::PaymentCardExpiration->new;

  # bless(..., "Faker::Plugin::PaymentCardExpiration")

=cut

$test->for('synopsis', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  ok $result->isa('Faker::Plugin::PaymentCardExpiration');

  $result
});

=description

This package provides methods for generating fake data for payment card expiration.

+=encoding utf8

=cut

$test->for('description');

=inherits

Faker::Plugin

=cut

$test->for('inherits');

=method execute

The execute method returns a returns a random fake payment card expiration.

=signature execute

  execute(HashRef $data) (Str)

=metadata execute

{
  since => '1.10',
}

=example-1 execute

  package main;

  use Faker::Plugin::PaymentCardExpiration;

  my $plugin = Faker::Plugin::PaymentCardExpiration->new;

  # bless(..., "Faker::Plugin::PaymentCardExpiration")

  # my $result = $plugin->execute;

  # "02/24";

  # my $result = $plugin->execute;

  # "11/23";

  # my $result = $plugin->execute;

  # "09/24";

=cut

$test->for('example', 1, 'execute', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  ok $result->isa('Faker::Plugin::PaymentCardExpiration');
  ok $result->faker;
  ok $result->faker->random->reseed($seed);
  ok $result->faker->random->pick; # reset randomizer
  is $result->execute, "02/24";
  ok $result->faker->random->pick; # reset randomizer
  is $result->execute, "11/23";
  ok $result->faker->random->pick; # reset randomizer
  is $result->execute, "09/24";

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

  use Faker::Plugin::PaymentCardExpiration;

  my $plugin = Faker::Plugin::PaymentCardExpiration->new;

  # bless(..., "Faker::Plugin::PaymentCardExpiration")

=cut

$test->for('example', 1, 'new', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  ok $result->isa('Faker::Plugin::PaymentCardExpiration');
  ok $result->faker;

  $result
});

# END

$test->render('lib/Faker/Plugin/PaymentCardExpiration.pod') if $ENV{RENDER};

ok 1 and done_testing;
