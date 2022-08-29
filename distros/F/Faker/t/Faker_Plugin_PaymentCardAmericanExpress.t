package main;

use 5.018;

use strict;
use warnings;

use Test::More;
use Venus::Test;

my $test = test(__FILE__);
my $seed = 42;

=name

Faker::Plugin::PaymentCardAmericanExpress

=cut

$test->for('name');

=tagline

Payment Card American Express

=cut

$test->for('tagline');

=abstract

Payment Card American Express for Faker

=cut

$test->for('abstract');

=includes

method: new
method: execute

=cut

$test->for('includes');

=synopsis

  package main;

  use Faker::Plugin::PaymentCardAmericanExpress;

  my $plugin = Faker::Plugin::PaymentCardAmericanExpress->new;

  # bless(..., "Faker::Plugin::PaymentCardAmericanExpress")

=cut

$test->for('synopsis', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  ok $result->isa('Faker::Plugin::PaymentCardAmericanExpress');

  $result
});

=description

This package provides methods for generating fake data for payment card american express.

+=encoding utf8

=cut

$test->for('description');

=inherits

Faker::Plugin

=cut

$test->for('inherits');

=method execute

The execute method returns a returns a random fake payment card american express.

=signature execute

  execute(HashRef $data) (Str)

=metadata execute

{
  since => '1.10',
}

=example-1 execute

  package main;

  use Faker::Plugin::PaymentCardAmericanExpress;

  my $plugin = Faker::Plugin::PaymentCardAmericanExpress->new;

  # bless(..., "Faker::Plugin::PaymentCardAmericanExpress")

  # my $result = $plugin->execute;

  # 34140844684550;

  # my $result = $plugin->execute;

  # 37945443908982;

  # my $result = $plugin->execute;

  # 34370225828820;

=cut

$test->for('example', 1, 'execute', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  ok $result->isa('Faker::Plugin::PaymentCardAmericanExpress');
  ok $result->faker;
  ok $result->faker->random->reseed($seed);
  ok $result->faker->random->make; # reset randomizer
  is $result->execute, 34140844684550;
  ok $result->faker->random->make; # reset randomizer
  is $result->execute, 37945443908982;
  ok $result->faker->random->make; # reset randomizer
  is $result->execute, 34370225828820;

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

  use Faker::Plugin::PaymentCardAmericanExpress;

  my $plugin = Faker::Plugin::PaymentCardAmericanExpress->new;

  # bless(..., "Faker::Plugin::PaymentCardAmericanExpress")

=cut

$test->for('example', 1, 'new', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  ok $result->isa('Faker::Plugin::PaymentCardAmericanExpress');
  ok $result->faker;

  $result
});

# END

$test->render('lib/Faker/Plugin/PaymentCardAmericanExpress.pod') if $ENV{RENDER};

ok 1 and done_testing;
