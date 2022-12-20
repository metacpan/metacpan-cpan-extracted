package main;

use 5.018;

use strict;
use warnings;

use Test::More;
use Venus::Test;

my $test = test(__FILE__);
my $seed = 42;

=name

Faker::Plugin::JaJp::JargonVerb

=cut

$test->for('name');

=tagline

Jargon Verb

=cut

$test->for('tagline');

=abstract

Jargon Verb for Faker

=cut

$test->for('abstract');

=includes

method: new
method: execute

=cut

$test->for('includes');

=synopsis

  package main;

  use Faker::Plugin::JaJp::JargonVerb;

  my $plugin = Faker::Plugin::JaJp::JargonVerb->new;

  # bless(..., "Faker::Plugin::JaJp::JargonVerb")

=cut

$test->for('synopsis', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  ok $result->isa('Faker::Plugin::JaJp::JargonVerb');

  $result
});

=description

This package provides methods for generating fake data for jargon verb.

+=encoding utf8

=cut

$test->for('description');

=inherits

Faker::Plugin::JaJp

=cut

$test->for('inherits');

=method execute

The execute method returns a returns a random fake jargon verb.

=signature execute

  execute(HashRef $data) (Str)

=metadata execute

{
  since => '1.10',
}

=example-1 execute

  package main;

  use Faker::Plugin::JaJp::JargonVerb;

  my $plugin = Faker::Plugin::JaJp::JargonVerb->new;

  # bless(..., "Faker::Plugin::JaJp::JargonVerb")

  # my $result = $plugin->execute;

  # '流線型';

  # my $result = $plugin->execute;

  # '最適化';

  # my $result = $plugin->execute;

  # 'オーケストレーションする';

=cut

$test->for('example', 1, 'execute', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  ok $result->isa('Faker::Plugin::JaJp::JargonVerb');
  ok $result->faker;
  ok $result->faker->random->reseed($seed);
  ok $result->faker->random->pick; # reset randomizer
  is $result->execute, '流線型';
  ok $result->faker->random->pick; # reset randomizer
  is $result->execute, '最適化';
  ok $result->faker->random->pick; # reset randomizer
  is $result->execute, 'オーケストレーションする';

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

  use Faker::Plugin::JaJp::JargonVerb;

  my $plugin = Faker::Plugin::JaJp::JargonVerb->new;

  # bless(..., "Faker::Plugin::JaJp::JargonVerb")

=cut

$test->for('example', 1, 'new', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  ok $result->isa('Faker::Plugin::JaJp::JargonVerb');
  ok $result->faker;

  $result
});

# END

$test->render('lib/Faker/Plugin/JaJp/JargonVerb.pod') if $ENV{RENDER};

ok 1 and done_testing;
