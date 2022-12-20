package main;

use 5.018;

use strict;
use warnings;

use Test::More;
use Venus::Test;

my $test = test(__FILE__);
my $seed = 42;

=name

Faker::Plugin::EsEs::JargonNoun

=cut

$test->for('name');

=tagline

Jargon Noun

=cut

$test->for('tagline');

=abstract

Jargon Noun for Faker

=cut

$test->for('abstract');

=includes

method: new
method: execute

=cut

$test->for('includes');

=synopsis

  package main;

  use Faker::Plugin::EsEs::JargonNoun;

  my $plugin = Faker::Plugin::EsEs::JargonNoun->new;

  # bless(..., "Faker::Plugin::EsEs::JargonNoun")

=cut

$test->for('synopsis', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  ok $result->isa('Faker::Plugin::EsEs::JargonNoun');

  $result
});

=description

This package provides methods for generating fake data for jargon noun.

+=encoding utf8

=cut

$test->for('description');

=inherits

Faker::Plugin::EsEs

=cut

$test->for('inherits');

=method execute

The execute method returns a returns a random fake jargon noun.

=signature execute

  execute(HashRef $data) (Str)

=metadata execute

{
  since => '1.10',
}

=example-1 execute

  package main;

  use Faker::Plugin::EsEs::JargonNoun;

  my $plugin = Faker::Plugin::EsEs::JargonNoun->new;

  # bless(..., "Faker::Plugin::EsEs::JargonNoun")

  # my $result = $plugin->execute;

  # 'action-items';

  # my $result = $plugin->execute;

  # 'technologies';

  # my $result = $plugin->execute;

  # 'applications';

=cut

$test->for('example', 1, 'execute', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  ok $result->isa('Faker::Plugin::EsEs::JargonNoun');
  ok $result->faker;
  ok $result->faker->random->reseed($seed);
  ok $result->faker->random->pick; # reset randomizer
  is $result->execute, 'action-items';
  ok $result->faker->random->pick; # reset randomizer
  is $result->execute, 'technologies';
  ok $result->faker->random->pick; # reset randomizer
  is $result->execute, 'applications';

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

  use Faker::Plugin::EsEs::JargonNoun;

  my $plugin = Faker::Plugin::EsEs::JargonNoun->new;

  # bless(..., "Faker::Plugin::EsEs::JargonNoun")

=cut

$test->for('example', 1, 'new', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  ok $result->isa('Faker::Plugin::EsEs::JargonNoun');
  ok $result->faker;

  $result
});

# END

$test->render('lib/Faker/Plugin/EsEs/JargonNoun.pod') if $ENV{RENDER};

ok 1 and done_testing;
