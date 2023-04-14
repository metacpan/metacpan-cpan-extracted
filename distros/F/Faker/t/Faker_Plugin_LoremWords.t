package main;

use 5.018;

use strict;
use warnings;

use Test::More;
use Venus::Test;

my $test = test(__FILE__);
my $seed = 42;

=name

Faker::Plugin::LoremWords

=cut

$test->for('name');

=tagline

Lorem Words

=cut

$test->for('tagline');

=abstract

Lorem Words for Faker

=cut

$test->for('abstract');

=includes

method: new
method: execute

=cut

$test->for('includes');

=synopsis

  package main;

  use Faker::Plugin::LoremWords;

  my $plugin = Faker::Plugin::LoremWords->new;

  # bless(..., "Faker::Plugin::LoremWords")

=cut

$test->for('synopsis', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  ok $result->isa('Faker::Plugin::LoremWords');

  $result
});

=description

This package provides methods for generating fake data for lorem words.

+=encoding utf8

=cut

$test->for('description');

=inherits

Faker::Plugin

=cut

$test->for('inherits');

=method execute

The execute method returns a returns a random fake lorem words.

=signature execute

  execute(HashRef $data) (Str)

=metadata execute

{
  since => '1.10',
}

=example-1 execute

  package main;

  use Faker::Plugin::LoremWords;

  my $plugin = Faker::Plugin::LoremWords->new;

  # bless(..., "Faker::Plugin::LoremWords")

  # my $result = $plugin->execute;

  # "aut vitae et eligendi laudantium";

  # my $result = $plugin->execute;

  # "accusantium animi corrupti dolores aliquid";

  # my $result = $plugin->execute;

  # "eos pariatur quia corporis illo";

=cut

$test->for('example', 1, 'execute', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  ok $result->isa('Faker::Plugin::LoremWords');
  ok $result->faker;
  ok $result->faker->random->reseed($seed);
  ok $result->faker->random->pick; # reset randomizer
  is $result->execute, "nisi aut nihil vitae vero";
  ok $result->faker->random->pick; # reset randomizer
  is $result->execute, "deleniti eligendi fugiat laudantium in";
  ok $result->faker->random->pick; # reset randomizer
  is $result->execute, "accusantium assumenda animi voluptates corrupti";

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

  use Faker::Plugin::LoremWords;

  my $plugin = Faker::Plugin::LoremWords->new;

  # bless(..., "Faker::Plugin::LoremWords")

=cut

$test->for('example', 1, 'new', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  ok $result->isa('Faker::Plugin::LoremWords');
  ok $result->faker;

  $result
});

=partials

t/Faker.t: pdml: authors
t/Faker.t: pdml: license

=cut

$test->for('partials');

# END

$test->render('lib/Faker/Plugin/LoremWords.pod') if $ENV{RENDER};

ok 1 and done_testing;
