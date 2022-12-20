package main;

use 5.018;

use strict;
use warnings;

use Test::More;
use Venus::Test;

my $test = test(__FILE__);
my $seed = 42;

=name

Faker::Plugin::PaymentVendor

=cut

$test->for('name');

=tagline

Payment Vendor

=cut

$test->for('tagline');

=abstract

Payment Vendor for Faker

=cut

$test->for('abstract');

=includes

method: new
method: execute

=cut

$test->for('includes');

=synopsis

  package main;

  use Faker::Plugin::PaymentVendor;

  my $plugin = Faker::Plugin::PaymentVendor->new;

  # bless(..., "Faker::Plugin::PaymentVendor")

=cut

$test->for('synopsis', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  ok $result->isa('Faker::Plugin::PaymentVendor');

  $result
});

=description

This package provides methods for generating fake data for payment vendor.

+=encoding utf8

=cut

$test->for('description');

=inherits

Faker::Plugin

=cut

$test->for('inherits');

=method execute

The execute method returns a returns a random fake payment vendor.

=signature execute

  execute(HashRef $data) (Str)

=metadata execute

{
  since => '1.10',
}

=example-1 execute

  package main;

  use Faker::Plugin::PaymentVendor;

  my $plugin = Faker::Plugin::PaymentVendor->new;

  # bless(..., "Faker::Plugin::PaymentVendor")

  # my $result = $plugin->execute;

  # "Visa";

  # my $result = $plugin->execute;

  # "MasterCard";

  # my $result = $plugin->execute;

  # "American Express";

=cut

$test->for('example', 1, 'execute', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  ok $result->isa('Faker::Plugin::PaymentVendor');
  ok $result->faker;
  ok $result->faker->random->reseed($seed);
  ok $result->faker->random->pick; # reset randomizer
  is $result->execute, "Visa";
  ok $result->faker->random->pick; # reset randomizer
  is $result->execute, "MasterCard";
  ok $result->faker->random->pick; # reset randomizer
  is $result->execute, "American Express";

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

  use Faker::Plugin::PaymentVendor;

  my $plugin = Faker::Plugin::PaymentVendor->new;

  # bless(..., "Faker::Plugin::PaymentVendor")

=cut

$test->for('example', 1, 'new', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  ok $result->isa('Faker::Plugin::PaymentVendor');
  ok $result->faker;

  $result
});

# END

$test->render('lib/Faker/Plugin/PaymentVendor.pod') if $ENV{RENDER};

ok 1 and done_testing;
