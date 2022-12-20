package main;

use 5.018;

use strict;
use warnings;

use Test::More;
use Venus::Test;

my $test = test(__FILE__);
my $seed = 42;

=name

Faker::Plugin::PaymentCardDiscover

=cut

$test->for('name');

=tagline

Payment Card Discover

=cut

$test->for('tagline');

=abstract

Payment Card Discover for Faker

=cut

$test->for('abstract');

=includes

method: new
method: execute

=cut

$test->for('includes');

=synopsis

  package main;

  use Faker::Plugin::PaymentCardDiscover;

  my $plugin = Faker::Plugin::PaymentCardDiscover->new;

  # bless(..., "Faker::Plugin::PaymentCardDiscover")

=cut

$test->for('synopsis', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  ok $result->isa('Faker::Plugin::PaymentCardDiscover');

  $result
});

=description

This package provides methods for generating fake data for payment card discover.

+=encoding utf8

=cut

$test->for('description');

=inherits

Faker::Plugin

=cut

$test->for('inherits');

=method execute

The execute method returns a returns a random fake payment card discover.

=signature execute

  execute(HashRef $data) (Str)

=metadata execute

{
  since => '1.10',
}

=example-1 execute

  package main;

  use Faker::Plugin::PaymentCardDiscover;

  my $plugin = Faker::Plugin::PaymentCardDiscover->new;

  # bless(..., "Faker::Plugin::PaymentCardDiscover")

  # my $result = $plugin->execute;

  # 601131408446845;

  # my $result = $plugin->execute;

  # 601107694544390;

  # my $result = $plugin->execute;

  # 601198220370225;

=cut

$test->for('example', 1, 'execute', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  ok $result->isa('Faker::Plugin::PaymentCardDiscover');
  ok $result->faker;
  ok $result->faker->random->reseed($seed);
  ok $result->faker->random->pick; # reset randomizer
  is $result->execute, 601131408446845;
  ok $result->faker->random->pick; # reset randomizer
  is $result->execute, 601107694544390;
  ok $result->faker->random->pick; # reset randomizer
  is $result->execute, 601198220370225;

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

  use Faker::Plugin::PaymentCardDiscover;

  my $plugin = Faker::Plugin::PaymentCardDiscover->new;

  # bless(..., "Faker::Plugin::PaymentCardDiscover")

=cut

$test->for('example', 1, 'new', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  ok $result->isa('Faker::Plugin::PaymentCardDiscover');
  ok $result->faker;

  $result
});

# END

$test->render('lib/Faker/Plugin/PaymentCardDiscover.pod') if $ENV{RENDER};

ok 1 and done_testing;
