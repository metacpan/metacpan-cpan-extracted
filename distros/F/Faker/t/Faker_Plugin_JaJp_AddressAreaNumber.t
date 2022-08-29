package main;

use 5.018;

use strict;
use warnings;

use Test::More;
use Venus::Test;

my $test = test(__FILE__);
my $seed = 42;

=name

Faker::Plugin::JaJp::AddressAreaNumber

=cut

$test->for('name');

=tagline

Address Area Number

=cut

$test->for('tagline');

=abstract

Address Area Number for Faker

=cut

$test->for('abstract');

=includes

method: new
method: execute

=cut

$test->for('includes');

=synopsis

  package main;

  use Faker::Plugin::JaJp::AddressAreaNumber;

  my $plugin = Faker::Plugin::JaJp::AddressAreaNumber->new;

  # bless(..., "Faker::Plugin::JaJp::AddressAreaNumber")

=cut

$test->for('synopsis', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  ok $result->isa('Faker::Plugin::JaJp::AddressAreaNumber');

  $result
});

=description

This package provides methods for generating fake data for address area number.

+=encoding utf8

=cut

$test->for('description');

=inherits

Faker::Plugin::JaJp

=cut

$test->for('inherits');

=method execute

The execute method returns a returns a random fake address area number.

=signature execute

  execute(HashRef $data) (Str)

=metadata execute

{
  since => '1.10',
}

=example-1 execute

  package main;

  use Faker::Plugin::JaJp::AddressAreaNumber;

  my $plugin = Faker::Plugin::JaJp::AddressAreaNumber->new;

  # bless(..., "Faker::Plugin::JaJp::AddressAreaNumber")

  # my $result = $plugin->execute;

  # 4;

  # my $result = $plugin->execute;

  # 5;

  # my $result = $plugin->execute;

  # 9;

=cut

$test->for('example', 1, 'execute', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  ok $result->isa('Faker::Plugin::JaJp::AddressAreaNumber');
  ok $result->faker;
  ok $result->faker->random->reseed($seed);
  ok $result->faker->random->make; # reset randomizer
  is $result->execute, 4;
  ok $result->faker->random->make; # reset randomizer
  is $result->execute, 5;
  ok $result->faker->random->make; # reset randomizer
  is $result->execute, 9;

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

  use Faker::Plugin::JaJp::AddressAreaNumber;

  my $plugin = Faker::Plugin::JaJp::AddressAreaNumber->new;

  # bless(..., "Faker::Plugin::JaJp::AddressAreaNumber")

=cut

$test->for('example', 1, 'new', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  ok $result->isa('Faker::Plugin::JaJp::AddressAreaNumber');
  ok $result->faker;

  $result
});

# END

$test->render('lib/Faker/Plugin/JaJp/AddressAreaNumber.pod') if $ENV{RENDER};

ok 1 and done_testing;
