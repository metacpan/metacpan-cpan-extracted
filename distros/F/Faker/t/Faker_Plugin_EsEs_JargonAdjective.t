package main;

use 5.018;

use strict;
use warnings;

use Test::More;
use Venus::Test;

my $test = test(__FILE__);
my $seed = 42;

=name

Faker::Plugin::EsEs::JargonAdjective

=cut

$test->for('name');

=tagline

Jargon Adjective

=cut

$test->for('tagline');

=abstract

Jargon Adjective for Faker

=cut

$test->for('abstract');

=includes

method: new
method: execute

=cut

$test->for('includes');

=synopsis

  package main;

  use Faker::Plugin::EsEs::JargonAdjective;

  my $plugin = Faker::Plugin::EsEs::JargonAdjective->new;

  # bless(..., "Faker::Plugin::EsEs::JargonAdjective")

=cut

$test->for('synopsis', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  ok $result->isa('Faker::Plugin::EsEs::JargonAdjective');

  $result
});

=description

This package provides methods for generating fake data for jargon adjective.

+=encoding utf8

=cut

$test->for('description');

=inherits

Faker::Plugin::EsEs

=cut

$test->for('inherits');

=method execute

The execute method returns a returns a random fake jargon adjective.

=signature execute

  execute(HashRef $data) (Str)

=metadata execute

{
  since => '1.10',
}

=example-1 execute

  package main;

  use Faker::Plugin::EsEs::JargonAdjective;

  my $plugin = Faker::Plugin::EsEs::JargonAdjective->new;

  # bless(..., "Faker::Plugin::EsEs::JargonAdjective")

  # my $result = $plugin->execute;

  # 'virtual';

  # my $result = $plugin->execute;

  # 'killer';

  # my $result = $plugin->execute;

  # 'cutting-edge';

=cut

$test->for('example', 1, 'execute', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  ok $result->isa('Faker::Plugin::EsEs::JargonAdjective');
  ok $result->faker;
  ok $result->faker->random->reseed($seed);
  ok $result->faker->random->pick; # reset randomizer
  is $result->execute, 'virtual';
  ok $result->faker->random->pick; # reset randomizer
  is $result->execute, 'killer';
  ok $result->faker->random->pick; # reset randomizer
  is $result->execute, 'cutting-edge';

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

  use Faker::Plugin::EsEs::JargonAdjective;

  my $plugin = Faker::Plugin::EsEs::JargonAdjective->new;

  # bless(..., "Faker::Plugin::EsEs::JargonAdjective")

=cut

$test->for('example', 1, 'new', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  ok $result->isa('Faker::Plugin::EsEs::JargonAdjective');
  ok $result->faker;

  $result
});

# END

$test->render('lib/Faker/Plugin/EsEs/JargonAdjective.pod') if $ENV{RENDER};

ok 1 and done_testing;
