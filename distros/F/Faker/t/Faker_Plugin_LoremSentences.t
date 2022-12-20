package main;

use 5.018;

use strict;
use warnings;

use Test::More;
use Venus::Test;

my $test = test(__FILE__);
my $seed = 42;

=name

Faker::Plugin::LoremSentences

=cut

$test->for('name');

=tagline

Lorem Sentences

=cut

$test->for('tagline');

=abstract

Lorem Sentences for Faker

=cut

$test->for('abstract');

=includes

method: new
method: execute

=cut

$test->for('includes');

=synopsis

  package main;

  use Faker::Plugin::LoremSentences;

  my $plugin = Faker::Plugin::LoremSentences->new;

  # bless(..., "Faker::Plugin::LoremSentences")

=cut

$test->for('synopsis', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  ok $result->isa('Faker::Plugin::LoremSentences');

  $result
});

=description

This package provides methods for generating fake data for lorem sentences.

+=encoding utf8

=cut

$test->for('description');

=inherits

Faker::Plugin

=cut

$test->for('inherits');

=method execute

The execute method returns a returns a random fake lorem sentences.

=signature execute

  execute(HashRef $data) (Str)

=metadata execute

{
  since => '1.10',
}

=example-1 execute

  package main;

  use Faker::Plugin::LoremSentences;

  my $plugin = Faker::Plugin::LoremSentences->new;

  # bless(..., "Faker::Plugin::LoremSentences")

  # my $result = lplugin $result->execute;

  # "vero deleniti fugiat in accusantium animi c...";

  # my $result = lplugin $result->execute;

  # "enim accusantium aliquid id reprehenderit c...";

  # my $result = lplugin $result->execute;

  # "reprehenderit ut autem cumque ea sint dolor...";

=cut

$test->for('example', 1, 'execute', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  ok $result->isa('Faker::Plugin::LoremSentences');
  ok $result->faker;
  ok $result->faker->random->reseed($seed);
  ok $result->faker->random->pick; # reset randomizer
  like $result->execute, qr/corporis qui illo nostrum error at numquam et/;
  ok $result->faker->random->pick; # reset randomizer
  like $result->execute, qr/sunt ut qui qui eveniet non quaerat et eius nulla/;
  ok $result->faker->random->pick; # reset randomizer
  like $result->execute, qr/dicta magnam ullam reiciendis blanditiis totam quia/;

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

  use Faker::Plugin::LoremSentences;

  my $plugin = Faker::Plugin::LoremSentences->new;

  # bless(..., "Faker::Plugin::LoremSentences")

=cut

$test->for('example', 1, 'new', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  ok $result->isa('Faker::Plugin::LoremSentences');
  ok $result->faker;

  $result
});

# END

$test->render('lib/Faker/Plugin/LoremSentences.pod') if $ENV{RENDER};

ok 1 and done_testing;
