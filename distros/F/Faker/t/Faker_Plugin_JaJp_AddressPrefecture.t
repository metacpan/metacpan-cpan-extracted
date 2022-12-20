package main;

use 5.018;

use strict;
use warnings;

use Test::More;
use Venus::Test;

my $test = test(__FILE__);
my $seed = 42;

=name

Faker::Plugin::JaJp::AddressPrefecture

=cut

$test->for('name');

=tagline

Address Prefecture

=cut

$test->for('tagline');

=abstract

Address Prefecture for Faker

=cut

$test->for('abstract');

=includes

method: new
method: execute

=cut

$test->for('includes');

=synopsis

  package main;

  use Faker::Plugin::JaJp::AddressPrefecture;

  my $plugin = Faker::Plugin::JaJp::AddressPrefecture->new;

  # bless(..., "Faker::Plugin::JaJp::AddressPrefecture")

=cut

$test->for('synopsis', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  ok $result->isa('Faker::Plugin::JaJp::AddressPrefecture');

  $result
});

=description

This package provides methods for generating fake data for address prefecture.

+=encoding utf8

=cut

$test->for('description');

=inherits

Faker::Plugin::JaJp

=cut

$test->for('inherits');

=method execute

The execute method returns a returns a random fake address prefecture.

=signature execute

  execute(HashRef $data) (Str)

=metadata execute

{
  since => '1.10',
}

=example-1 execute

  package main;

  use Faker::Plugin::JaJp::AddressPrefecture;

  my $plugin = Faker::Plugin::JaJp::AddressPrefecture->new;

  # bless(..., "Faker::Plugin::JaJp::AddressPrefecture")

  # my $result = $plugin->execute;

  # '石川県';

  # my $result = $plugin->execute;

  # '長野県';

  # my $result = $plugin->execute;

  # '佐賀県';

=cut

$test->for('example', 1, 'execute', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  ok $result->isa('Faker::Plugin::JaJp::AddressPrefecture');
  ok $result->faker;
  ok $result->faker->random->reseed($seed);
  ok $result->faker->random->pick; # reset randomizer
  is $result->execute, '石川県';
  ok $result->faker->random->pick; # reset randomizer
  is $result->execute, '長野県';
  ok $result->faker->random->pick; # reset randomizer
  is $result->execute, '佐賀県';

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

  use Faker::Plugin::JaJp::AddressPrefecture;

  my $plugin = Faker::Plugin::JaJp::AddressPrefecture->new;

  # bless(..., "Faker::Plugin::JaJp::AddressPrefecture")

=cut

$test->for('example', 1, 'new', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  ok $result->isa('Faker::Plugin::JaJp::AddressPrefecture');
  ok $result->faker;

  $result
});

# END

$test->render('lib/Faker/Plugin/JaJp/AddressPrefecture.pod') if $ENV{RENDER};

ok 1 and done_testing;
