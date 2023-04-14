package main;

use 5.018;

use strict;
use warnings;

use Test::More;
use Venus::Test;

my $test = test(__FILE__);
my $seed = 42;

=name

Faker::Plugin::ColorSafeName

=cut

$test->for('name');

=tagline

Color Safe Name

=cut

$test->for('tagline');

=abstract

Color Safe Name for Faker

=cut

$test->for('abstract');

=includes

method: new
method: execute

=cut

$test->for('includes');

=synopsis

  package main;

  use Faker::Plugin::ColorSafeName;

  my $plugin = Faker::Plugin::ColorSafeName->new;

  # bless(..., "Faker::Plugin::ColorSafeName")

=cut

$test->for('synopsis', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  ok $result->isa('Faker::Plugin::ColorSafeName');

  $result
});

=description

This package provides methods for generating fake data for color safe name.

+=encoding utf8

=cut

$test->for('description');

=inherits

Faker::Plugin

=cut

$test->for('inherits');

=method execute

The execute method returns a returns a random fake color safe name.

=signature execute

  execute(HashRef $data) (Str)

=metadata execute

{
  since => '1.10',
}

=example-1 execute

  package main;

  use Faker::Plugin::ColorSafeName;

  my $plugin = Faker::Plugin::ColorSafeName->new;

  # bless(..., "Faker::Plugin::ColorSafeName")

  # my $result = $plugin->execute;

  # "purple";

  # my $result = $plugin->execute;

  # "teal";

  # my $result = $plugin->execute;

  # "fuchsia";

=cut

$test->for('example', 1, 'execute', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  ok $result->isa('Faker::Plugin::ColorSafeName');
  ok $result->faker;
  ok $result->faker->random->reseed($seed);
  ok $result->faker->random->pick; # reset randomizer
  is $result->execute, "purple";
  ok $result->faker->random->pick; # reset randomizer
  is $result->execute, "teal";
  ok $result->faker->random->pick; # reset randomizer
  is $result->execute, "fuchsia";

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

  use Faker::Plugin::ColorSafeName;

  my $plugin = Faker::Plugin::ColorSafeName->new;

  # bless(..., "Faker::Plugin::ColorSafeName")

=cut

$test->for('example', 1, 'new', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  ok $result->isa('Faker::Plugin::ColorSafeName');
  ok $result->faker;

  $result
});

=partials

t/Faker.t: pdml: authors
t/Faker.t: pdml: license

=cut

$test->for('partials');

# END

$test->render('lib/Faker/Plugin/ColorSafeName.pod') if $ENV{RENDER};

ok 1 and done_testing;
