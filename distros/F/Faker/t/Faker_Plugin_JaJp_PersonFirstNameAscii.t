package main;

use 5.018;

use strict;
use warnings;

use Test::More;
use Venus::Test;

my $test = test(__FILE__);
my $seed = 42;

=name

Faker::Plugin::JaJp::PersonFirstNameAscii

=cut

$test->for('name');

=tagline

Person First Name Ascii

=cut

$test->for('tagline');

=abstract

Person First Name Ascii for Faker

=cut

$test->for('abstract');

=includes

method: new
method: execute

=cut

$test->for('includes');

=synopsis

  package main;

  use Faker::Plugin::JaJp::PersonFirstNameAscii;

  my $plugin = Faker::Plugin::JaJp::PersonFirstNameAscii->new;

  # bless(..., "Faker::Plugin::JaJp::PersonFirstNameAscii")

=cut

$test->for('synopsis', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  ok $result->isa('Faker::Plugin::JaJp::PersonFirstNameAscii');

  $result
});

=description

This package provides methods for generating fake data for person first name ascii.

+=encoding utf8

=cut

$test->for('description');

=inherits

Faker::Plugin::JaJp

=cut

$test->for('inherits');

=method execute

The execute method returns a returns a random fake person first name ascii.

=signature execute

  execute(HashRef $data) (Str)

=metadata execute

{
  since => '1.10',
}

=example-1 execute

  package main;

  use Faker::Plugin::JaJp::PersonFirstNameAscii;

  my $plugin = Faker::Plugin::JaJp::PersonFirstNameAscii->new;

  # bless(..., "Faker::Plugin::JaJp::PersonFirstNameAscii")

  # my $result = $plugin->execute;

  # 'taichi';

  # my $result = $plugin->execute;

  # 'tomoya';

  # my $result = $plugin->execute;

  # 'yosuke';

=cut

$test->for('example', 1, 'execute', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  ok $result->isa('Faker::Plugin::JaJp::PersonFirstNameAscii');
  ok $result->faker;
  ok $result->faker->random->reseed($seed);
  ok $result->faker->random->pick; # reset randomizer
  is $result->execute, 'taichi';
  ok $result->faker->random->pick; # reset randomizer
  is $result->execute, 'tomoya';
  ok $result->faker->random->pick; # reset randomizer
  is $result->execute, 'yosuke';

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

  use Faker::Plugin::JaJp::PersonFirstNameAscii;

  my $plugin = Faker::Plugin::JaJp::PersonFirstNameAscii->new;

  # bless(..., "Faker::Plugin::JaJp::PersonFirstNameAscii")

=cut

$test->for('example', 1, 'new', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  ok $result->isa('Faker::Plugin::JaJp::PersonFirstNameAscii');
  ok $result->faker;

  $result
});

# END

$test->render('lib/Faker/Plugin/JaJp/PersonFirstNameAscii.pod') if $ENV{RENDER};

ok 1 and done_testing;
