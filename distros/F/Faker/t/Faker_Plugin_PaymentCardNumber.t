package main;

use 5.018;

use strict;
use warnings;

use Test::More;
use Venus::Test;

my $test = test(__FILE__);
my $seed = 42;

=name

Faker::Plugin::PaymentCardNumber

=cut

$test->for('name');

=tagline

Payment Card Number

=cut

$test->for('tagline');

=abstract

Payment Card Number for Faker

=cut

$test->for('abstract');

=includes

method: new
method: execute

=cut

$test->for('includes');

=synopsis

  package main;

  use Faker::Plugin::PaymentCardNumber;

  my $plugin = Faker::Plugin::PaymentCardNumber->new;

  # bless(..., "Faker::Plugin::PaymentCardNumber")

=cut

$test->for('synopsis', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  ok $result->isa('Faker::Plugin::PaymentCardNumber');

  $result
});

=description

This package provides methods for generating fake data for payment card number.

+=encoding utf8

=cut

$test->for('description');

=inherits

Faker::Plugin

=cut

$test->for('inherits');

=method execute

The execute method returns a returns a random fake payment card number.

=signature execute

  execute(HashRef $data) (Str)

=metadata execute

{
  since => '1.10',
}

=example-1 execute

  package main;

  use Faker::Plugin::PaymentCardNumber;

  my $plugin = Faker::Plugin::PaymentCardNumber->new;

  # bless(..., "Faker::Plugin::PaymentCardNumber")

  # my $result = $plugin->execute;

  # 453208446845507;

  # my $result = $plugin->execute;

  # 37443908982203;

  # my $result = $plugin->execute;

  # 491658288205589;

=cut

$test->for('example', 1, 'execute', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  ok $result->isa('Faker::Plugin::PaymentCardNumber');
  ok $result->faker;
  ok $result->faker->random->reseed($seed);
  ok $result->faker->random->pick; # reset randomizer
  is $result->execute, 453208446845507;
  ok $result->faker->random->pick; # reset randomizer
  is $result->execute, 37443908982203;
  ok $result->faker->random->pick; # reset randomizer
  is $result->execute, 491658288205589;

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

  use Faker::Plugin::PaymentCardNumber;

  my $plugin = Faker::Plugin::PaymentCardNumber->new;

  # bless(..., "Faker::Plugin::PaymentCardNumber")

=cut

$test->for('example', 1, 'new', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  ok $result->isa('Faker::Plugin::PaymentCardNumber');
  ok $result->faker;

  $result
});

=partials

t/Faker.t: pdml: authors
t/Faker.t: pdml: license

=cut

$test->for('partials');

# END

$test->render('lib/Faker/Plugin/PaymentCardNumber.pod') if $ENV{RENDER};

ok 1 and done_testing;
