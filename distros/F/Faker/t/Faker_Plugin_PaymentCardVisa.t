package main;

use 5.018;

use strict;
use warnings;

use Test::More;
use Venus::Test;

my $test = test(__FILE__);
my $seed = 42;

=name

Faker::Plugin::PaymentCardVisa

=cut

$test->for('name');

=tagline

Payment Card Visa

=cut

$test->for('tagline');

=abstract

Payment Card Visa for Faker

=cut

$test->for('abstract');

=includes

method: new
method: execute

=cut

$test->for('includes');

=synopsis

  package main;

  use Faker::Plugin::PaymentCardVisa;

  my $plugin = Faker::Plugin::PaymentCardVisa->new;

  # bless(..., "Faker::Plugin::PaymentCardVisa")

=cut

$test->for('synopsis', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  ok $result->isa('Faker::Plugin::PaymentCardVisa');

  $result
});

=description

This package provides methods for generating fake data for payment card visa.

+=encoding utf8

=cut

$test->for('description');

=inherits

Faker::Plugin

=cut

$test->for('inherits');

=method execute

The execute method returns a returns a random fake payment card visa.

=signature execute

  execute(HashRef $data) (Str)

=metadata execute

{
  since => '1.10',
}

=example-1 execute

  package main;

  use Faker::Plugin::PaymentCardVisa;

  my $plugin = Faker::Plugin::PaymentCardVisa->new;

  # bless(..., "Faker::Plugin::PaymentCardVisa")

  # my $result = $plugin->execute;

  # 453214084468;

  # my $result = $plugin->execute;

  # 402400715076;

  # my $result = $plugin->execute;

  # 492954439089;

=cut

$test->for('example', 1, 'execute', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  ok $result->isa('Faker::Plugin::PaymentCardVisa');
  ok $result->faker;
  ok $result->faker->random->reseed($seed);
  ok $result->faker->random->make; # reset randomizer
  is $result->execute, 453214084468;
  ok $result->faker->random->make; # reset randomizer
  is $result->execute, 402400715076;
  ok $result->faker->random->make; # reset randomizer
  is $result->execute, 492954439089;

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

  use Faker::Plugin::PaymentCardVisa;

  my $plugin = Faker::Plugin::PaymentCardVisa->new;

  # bless(..., "Faker::Plugin::PaymentCardVisa")

=cut

$test->for('example', 1, 'new', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  ok $result->isa('Faker::Plugin::PaymentCardVisa');
  ok $result->faker;

  $result
});

# END

$test->render('lib/Faker/Plugin/PaymentCardVisa.pod') if $ENV{RENDER};

ok 1 and done_testing;
