package main;

use 5.018;

use strict;
use warnings;

use Test::More;
use Venus::Test;

my $test = test(__FILE__);
my $seed = 42;

=name

Faker::Plugin::ColorName

=cut

$test->for('name');

=tagline

Color Name

=cut

$test->for('tagline');

=abstract

Color Name for Faker

=cut

$test->for('abstract');

=includes

method: new
method: execute

=cut

$test->for('includes');

=synopsis

  package main;

  use Faker::Plugin::ColorName;

  my $plugin = Faker::Plugin::ColorName->new;

  # bless(..., "Faker::Plugin::ColorName")

=cut

$test->for('synopsis', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  ok $result->isa('Faker::Plugin::ColorName');

  $result
});

=description

This package provides methods for generating fake data for color name.

+=encoding utf8

=cut

$test->for('description');

=inherits

Faker::Plugin

=cut

$test->for('inherits');

=method execute

The execute method returns a returns a random fake color name.

=signature execute

  execute(HashRef $data) (Str)

=metadata execute

{
  since => '1.10',
}

=example-1 execute

  package main;

  use Faker::Plugin::ColorName;

  my $plugin = Faker::Plugin::ColorName->new;

  # bless(..., "Faker::Plugin::ColorName")

  # my $result = $plugin->execute;

  # "GhostWhite";

  # my $result = $plugin->execute;

  # "Khaki";

  # my $result = $plugin->execute;

  # "SeaGreen";

=cut

$test->for('example', 1, 'execute', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  ok $result->isa('Faker::Plugin::ColorName');
  ok $result->faker;
  ok $result->faker->random->reseed($seed);
  ok $result->faker->random->pick; # reset randomizer
  is $result->execute, "GhostWhite";
  ok $result->faker->random->pick; # reset randomizer
  is $result->execute, "Khaki";
  ok $result->faker->random->pick; # reset randomizer
  is $result->execute, "SeaGreen";

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

  use Faker::Plugin::ColorName;

  my $plugin = Faker::Plugin::ColorName->new;

  # bless(..., "Faker::Plugin::ColorName")

=cut

$test->for('example', 1, 'new', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  ok $result->isa('Faker::Plugin::ColorName');
  ok $result->faker;

  $result
});

=partials

t/Faker.t: pdml: authors
t/Faker.t: pdml: license

=cut

$test->for('partials');

# END

$test->render('lib/Faker/Plugin/ColorName.pod') if $ENV{RENDER};

ok 1 and done_testing;
