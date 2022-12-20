package main;

use 5.018;

use strict;
use warnings;

use Test::More;
use Venus::Test;

my $test = test(__FILE__);
my $seed = 42;

=name

Faker::Plugin::ColorSafeHexCode

=cut

$test->for('name');

=tagline

Color Safe Hex Code

=cut

$test->for('tagline');

=abstract

Color Safe Hex Code for Faker

=cut

$test->for('abstract');

=includes

method: new
method: execute

=cut

$test->for('includes');

=synopsis

  package main;

  use Faker::Plugin::ColorSafeHexCode;

  my $plugin = Faker::Plugin::ColorSafeHexCode->new;

  # bless(..., "Faker::Plugin::ColorSafeHexCode")

=cut

$test->for('synopsis', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  ok $result->isa('Faker::Plugin::ColorSafeHexCode');

  $result
});

=description

This package provides methods for generating fake data for color safe hex code.

+=encoding utf8

=cut

$test->for('description');

=inherits

Faker::Plugin

=cut

$test->for('inherits');

=method execute

The execute method returns a returns a random fake color safe hex code.

=signature execute

  execute(HashRef $data) (Str)

=metadata execute

{
  since => '1.10',
}

=example-1 execute

  package main;

  use Faker::Plugin::ColorSafeHexCode;

  my $plugin = Faker::Plugin::ColorSafeHexCode->new;

  # bless(..., "Faker::Plugin::ColorSafeHexCode")

  # my $result = $plugin->execute;

  # "#ff0057";

  # my $result = $plugin->execute;

  # "#ff006c";

  # my $result = $plugin->execute;

  # "#ff00db";

=cut

$test->for('example', 1, 'execute', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  ok $result->isa('Faker::Plugin::ColorSafeHexCode');
  ok $result->faker;
  ok $result->faker->random->reseed($seed);
  ok $result->faker->random->pick; # reset randomizer
  is $result->execute, "#ff0057";
  ok $result->faker->random->pick; # reset randomizer
  is $result->execute, "#ff006c";
  ok $result->faker->random->pick; # reset randomizer
  is $result->execute, "#ff00db";

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

  use Faker::Plugin::ColorSafeHexCode;

  my $plugin = Faker::Plugin::ColorSafeHexCode->new;

  # bless(..., "Faker::Plugin::ColorSafeHexCode")

=cut

$test->for('example', 1, 'new', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  ok $result->isa('Faker::Plugin::ColorSafeHexCode');
  ok $result->faker;

  $result
});

# END

$test->render('lib/Faker/Plugin/ColorSafeHexCode.pod') if $ENV{RENDER};

ok 1 and done_testing;
