package main;

use 5.018;

use strict;
use warnings;

use Test::More;
use Venus::Test;

my $test = test(__FILE__);
my $seed = 42;

=name

Faker::Plugin::LoremWord

=cut

$test->for('name');

=tagline

Lorem Word

=cut

$test->for('tagline');

=abstract

Lorem Word for Faker

=cut

$test->for('abstract');

=includes

method: new
method: execute

=cut

$test->for('includes');

=synopsis

  package main;

  use Faker::Plugin::LoremWord;

  my $plugin = Faker::Plugin::LoremWord->new;

  # bless(..., "Faker::Plugin::LoremWord")

=cut

$test->for('synopsis', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  ok $result->isa('Faker::Plugin::LoremWord');

  $result
});

=description

This package provides methods for generating fake data for lorem word.

+=encoding utf8

=cut

$test->for('description');

=inherits

Faker::Plugin

=cut

$test->for('inherits');

=method execute

The execute method returns a returns a random fake lorem word.

=signature execute

  execute(HashRef $data) (Str)

=metadata execute

{
  since => '1.10',
}

=example-1 execute

  package main;

  use Faker::Plugin::LoremWord;

  my $plugin = Faker::Plugin::LoremWord->new;

  # bless(..., "Faker::Plugin::LoremWord")

  # my $result = $plugin->execute;

  # "nisi";

  # my $result = $plugin->execute;

  # "nihil";

  # my $result = $plugin->execute;

  # "vero";

=cut

$test->for('example', 1, 'execute', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  ok $result->isa('Faker::Plugin::LoremWord');
  ok $result->faker;
  ok $result->faker->random->reseed($seed);
  ok $result->faker->random->make; # reset randomizer
  is $result->execute, "nisi";
  ok $result->faker->random->make; # reset randomizer
  is $result->execute, "nihil";
  ok $result->faker->random->make; # reset randomizer
  is $result->execute, "vero";

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

  use Faker::Plugin::LoremWord;

  my $plugin = Faker::Plugin::LoremWord->new;

  # bless(..., "Faker::Plugin::LoremWord")

=cut

$test->for('example', 1, 'new', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  ok $result->isa('Faker::Plugin::LoremWord');
  ok $result->faker;

  $result
});

# END

$test->render('lib/Faker/Plugin/LoremWord.pod') if $ENV{RENDER};

ok 1 and done_testing;
