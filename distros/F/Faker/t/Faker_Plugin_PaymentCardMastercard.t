package main;

use 5.018;

use strict;
use warnings;

use Test::More;
use Venus::Test;

my $test = test(__FILE__);
my $seed = 42;

=name

Faker::Plugin::PaymentCardMastercard

=cut

$test->for('name');

=tagline

Payment Card Mastercard

=cut

$test->for('tagline');

=abstract

Payment Card Mastercard for Faker

=cut

$test->for('abstract');

=includes

method: new
method: execute

=cut

$test->for('includes');

=synopsis

  package main;

  use Faker::Plugin::PaymentCardMastercard;

  my $plugin = Faker::Plugin::PaymentCardMastercard->new;

  # bless(..., "Faker::Plugin::PaymentCardMastercard")

=cut

$test->for('synopsis', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  ok $result->isa('Faker::Plugin::PaymentCardMastercard');

  $result
});

=description

This package provides methods for generating fake data for payment card mastercard.

+=encoding utf8

=cut

$test->for('description');

=inherits

Faker::Plugin

=cut

$test->for('inherits');

=method execute

The execute method returns a returns a random fake payment card mastercard.

=signature execute

  execute(HashRef $data) (Str)

=metadata execute

{
  since => '1.10',
}

=example-1 execute

  package main;

  use Faker::Plugin::PaymentCardMastercard;

  my $plugin = Faker::Plugin::PaymentCardMastercard->new;

  # bless(..., "Faker::Plugin::PaymentCardMastercard")

  # my $result = $plugin->execute;

  # 521408446845507;

  # my $result = $plugin->execute;

  # 554544390898220;

  # my $result = $plugin->execute;

  # 540225828820558;

=cut

$test->for('example', 1, 'execute', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  ok $result->isa('Faker::Plugin::PaymentCardMastercard');
  ok $result->faker;
  ok $result->faker->random->reseed($seed);
  ok $result->faker->random->pick; # reset randomizer
  is $result->execute, 521408446845507;
  ok $result->faker->random->pick; # reset randomizer
  is $result->execute, 554544390898220;
  ok $result->faker->random->pick; # reset randomizer
  is $result->execute, 540225828820558;

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

  use Faker::Plugin::PaymentCardMastercard;

  my $plugin = Faker::Plugin::PaymentCardMastercard->new;

  # bless(..., "Faker::Plugin::PaymentCardMastercard")

=cut

$test->for('example', 1, 'new', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  ok $result->isa('Faker::Plugin::PaymentCardMastercard');
  ok $result->faker;

  $result
});

# END

$test->render('lib/Faker/Plugin/PaymentCardMastercard.pod') if $ENV{RENDER};

ok 1 and done_testing;
