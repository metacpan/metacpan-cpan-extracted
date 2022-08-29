package main;

use 5.018;

use strict;
use warnings;

use Test::More;
use Venus::Test;

my $test = test(__FILE__);
my $seed = 42;

=name

Faker::Plugin::SoftwareSemver

=cut

$test->for('name');

=tagline

Software Semver

=cut

$test->for('tagline');

=abstract

Software Semver for Faker

=cut

$test->for('abstract');

=includes

method: new
method: execute

=cut

$test->for('includes');

=synopsis

  package main;

  use Faker::Plugin::SoftwareSemver;

  my $plugin = Faker::Plugin::SoftwareSemver->new;

  # bless(..., "Faker::Plugin::SoftwareSemver")

=cut

$test->for('synopsis', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  ok $result->isa('Faker::Plugin::SoftwareSemver');

  $result
});

=description

This package provides methods for generating fake data for software semver.

+=encoding utf8

=cut

$test->for('description');

=inherits

Faker::Plugin

=cut

$test->for('inherits');

=method execute

The execute method returns a returns a random fake software semver.

=signature execute

  execute(HashRef $data) (Str)

=metadata execute

{
  since => '1.10',
}

=example-1 execute

  package main;

  use Faker::Plugin::SoftwareSemver;

  my $plugin = Faker::Plugin::SoftwareSemver->new;

  # bless(..., "Faker::Plugin::SoftwareSemver")

  # my $result = $plugin->execute;

  # "1.4.0";

  # my $result = $plugin->execute;

  # "4.6.8";

  # my $result = $plugin->execute;

  # "5.0.7";

=cut

$test->for('example', 1, 'execute', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  ok $result->isa('Faker::Plugin::SoftwareSemver');
  ok $result->faker;
  ok $result->faker->random->reseed($seed);
  ok $result->faker->random->make; # reset randomizer
  is $result->execute, "1.4.0";
  ok $result->faker->random->make; # reset randomizer
  is $result->execute, "4.6.8";
  ok $result->faker->random->make; # reset randomizer
  is $result->execute, "5.0.7";

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

  use Faker::Plugin::SoftwareSemver;

  my $plugin = Faker::Plugin::SoftwareSemver->new;

  # bless(..., "Faker::Plugin::SoftwareSemver")

=cut

$test->for('example', 1, 'new', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  ok $result->isa('Faker::Plugin::SoftwareSemver');
  ok $result->faker;

  $result
});

# END

$test->render('lib/Faker/Plugin/SoftwareSemver.pod') if $ENV{RENDER};

ok 1 and done_testing;
