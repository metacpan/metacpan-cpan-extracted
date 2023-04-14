package main;

use 5.018;

use strict;
use warnings;

use Test::More;
use Venus::Test;

my $test = test(__FILE__);
my $seed = 42;

=name

Faker::Plugin::ColorRgbColorset

=cut

$test->for('name');

=tagline

Color Rgb Colorset

=cut

$test->for('tagline');

=abstract

Color Rgb Colorset for Faker

=cut

$test->for('abstract');

=includes

method: new
method: execute

=cut

$test->for('includes');

=synopsis

  package main;

  use Faker::Plugin::ColorRgbColorset;

  my $plugin = Faker::Plugin::ColorRgbColorset->new;

  # bless(..., "Faker::Plugin::ColorRgbColorset")

=cut

$test->for('synopsis', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  ok $result->isa('Faker::Plugin::ColorRgbColorset');

  $result
});

=description

This package provides methods for generating fake data for color rgb colorset.

+=encoding utf8

=cut

$test->for('description');

=inherits

Faker::Plugin

=cut

$test->for('inherits');

=method execute

The execute method returns a returns a random fake color rgb colorset.

=signature execute

  execute(HashRef $data) (Str)

=metadata execute

{
  since => '1.10',
}

=example-1 execute

  package main;

  use Faker::Plugin::ColorRgbColorset;

  my $plugin = Faker::Plugin::ColorRgbColorset->new;

  # bless(..., "Faker::Plugin::ColorRgbColorset")

  # my $result = $plugin->execute;

  # [28, 112, 22];

  # my $result = $plugin->execute;

  # [219, 63, 178];

  # my $result = $plugin->execute;

  # [176, 217, 21];

=cut

$test->for('example', 1, 'execute', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  ok $result->isa('Faker::Plugin::ColorRgbColorset');
  ok $result->faker;
  ok $result->faker->random->reseed($seed);
  ok $result->faker->random->pick; # reset randomizer
  is_deeply scalar $result->execute, [28, 112, 22];
  ok $result->faker->random->pick; # reset randomizer
  is_deeply scalar $result->execute, [219, 63, 178];
  ok $result->faker->random->pick; # reset randomizer
  is_deeply scalar $result->execute, [176, 217, 21];

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

  use Faker::Plugin::ColorRgbColorset;

  my $plugin = Faker::Plugin::ColorRgbColorset->new;

  # bless(..., "Faker::Plugin::ColorRgbColorset")

=cut

$test->for('example', 1, 'new', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  ok $result->isa('Faker::Plugin::ColorRgbColorset');
  ok $result->faker;

  $result
});

=partials

t/Faker.t: pdml: authors
t/Faker.t: pdml: license

=cut

$test->for('partials');

# END

$test->render('lib/Faker/Plugin/ColorRgbColorset.pod') if $ENV{RENDER};

ok 1 and done_testing;
