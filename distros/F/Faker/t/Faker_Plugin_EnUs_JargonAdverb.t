package main;

use 5.018;

use strict;
use warnings;

use Test::More;
use Venus::Test;

my $test = test(__FILE__);
my $seed = 42;

=name

Faker::Plugin::EnUs::JargonAdverb

=cut

$test->for('name');

=tagline

Jargon Adverb

=cut

$test->for('tagline');

=abstract

Jargon Adverb for Faker

=cut

$test->for('abstract');

=includes

method: new
method: execute

=cut

$test->for('includes');

=synopsis

  package main;

  use Faker::Plugin::EnUs::JargonAdverb;

  my $plugin = Faker::Plugin::EnUs::JargonAdverb->new;

  # bless(..., "Faker::Plugin::EnUs::JargonAdverb")

=cut

$test->for('synopsis', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  ok $result->isa('Faker::Plugin::EnUs::JargonAdverb');

  $result
});

=description

This package provides methods for generating fake data for jargon adverb.

+=encoding utf8

=cut

$test->for('description');

=inherits

Faker::Plugin::EnUs

=cut

$test->for('inherits');

=method execute

The execute method returns a returns a random fake jargon adverb.

=signature execute

  execute(HashRef $data) (Str)

=metadata execute

{
  since => '1.10',
}

=example-1 execute

  package main;

  use Faker::Plugin::EnUs::JargonAdverb;

  my $plugin = Faker::Plugin::EnUs::JargonAdverb->new;

  # bless(..., "Faker::Plugin::EnUs::JargonAdverb")

  # my $result = $plugin->execute;

  # "future-proofed";

  # my $result = $plugin->execute;

  # "managed";

  # my $result = $plugin->execute;

  # "synchronised";

=cut

$test->for('example', 1, 'execute', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  ok $result->isa('Faker::Plugin::EnUs::JargonAdverb');
  ok $result->faker;
  ok $result->faker->random->reseed($seed);
  ok $result->faker->random->pick; # reset randomizer
  is $result->execute, "future-proofed";
  ok $result->faker->random->pick; # reset randomizer
  is $result->execute, "managed";
  ok $result->faker->random->pick; # reset randomizer
  is $result->execute, "synchronised";

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

  use Faker::Plugin::EnUs::JargonAdverb;

  my $plugin = Faker::Plugin::EnUs::JargonAdverb->new;

  # bless(..., "Faker::Plugin::EnUs::JargonAdverb")

=cut

$test->for('example', 1, 'new', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  ok $result->isa('Faker::Plugin::EnUs::JargonAdverb');
  ok $result->faker;

  $result
});

=partials

t/Faker.t: pdml: authors
t/Faker.t: pdml: license

=cut

$test->for('partials');

# END

$test->render('lib/Faker/Plugin/EnUs/JargonAdverb.pod') if $ENV{RENDER};

ok 1 and done_testing;
