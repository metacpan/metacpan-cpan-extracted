package main;

use 5.018;

use strict;
use warnings;

use Test::More;
use Venus::Test;

my $test = test(__FILE__);
my $seed = 42;

=name

Faker::Plugin::SoftwareName

=cut

$test->for('name');

=tagline

Software Name

=cut

$test->for('tagline');

=abstract

Software Name for Faker

=cut

$test->for('abstract');

=includes

method: new
method: execute

=cut

$test->for('includes');

=synopsis

  package main;

  use Faker::Plugin::SoftwareName;

  my $plugin = Faker::Plugin::SoftwareName->new;

  # bless(..., "Faker::Plugin::SoftwareName")

=cut

$test->for('synopsis', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  ok $result->isa('Faker::Plugin::SoftwareName');

  $result
});

=description

This package provides methods for generating fake data for software name.

+=encoding utf8

=cut

$test->for('description');

=inherits

Faker::Plugin

=cut

$test->for('inherits');

=method execute

The execute method returns a returns a random fake software name.

=signature execute

  execute(HashRef $data) (Str)

=metadata execute

{
  since => '1.10',
}

=example-1 execute

  package main;

  use Faker::Plugin::SoftwareName;

  my $plugin = Faker::Plugin::SoftwareName->new;

  # bless(..., "Faker::Plugin::SoftwareName")

  # my $result = $plugin->execute;

  # "Job";

  # my $result = $plugin->execute;

  # "Zamit";

  # my $result = $plugin->execute;

  # "Stronghold";

=cut

$test->for('example', 1, 'execute', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  ok $result->isa('Faker::Plugin::SoftwareName');
  ok $result->faker;
  ok $result->faker->random->reseed($seed);
  ok $result->faker->random->make; # reset randomizer
  is $result->execute, "Job";
  ok $result->faker->random->make; # reset randomizer
  is $result->execute, "Zamit";
  ok $result->faker->random->make; # reset randomizer
  is $result->execute, "Stronghold";

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

  use Faker::Plugin::SoftwareName;

  my $plugin = Faker::Plugin::SoftwareName->new;

  # bless(..., "Faker::Plugin::SoftwareName")

=cut

$test->for('example', 1, 'new', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  ok $result->isa('Faker::Plugin::SoftwareName');
  ok $result->faker;

  $result
});

# END

$test->render('lib/Faker/Plugin/SoftwareName.pod') if $ENV{RENDER};

ok 1 and done_testing;
