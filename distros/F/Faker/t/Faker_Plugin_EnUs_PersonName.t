package main;

use 5.018;

use strict;
use warnings;

use Test::More;
use Venus::Test;

my $test = test(__FILE__);
my $seed = 42;

=name

Faker::Plugin::EnUs::PersonName

=cut

$test->for('name');

=tagline

Person Name

=cut

$test->for('tagline');

=abstract

Person Name for Faker

=cut

$test->for('abstract');

=includes

method: new
method: execute

=cut

$test->for('includes');

=synopsis

  package main;

  use Faker::Plugin::EnUs::PersonName;

  my $plugin = Faker::Plugin::EnUs::PersonName->new;

  # bless(..., "Faker::Plugin::EnUs::PersonName")

=cut

$test->for('synopsis', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  ok $result->isa('Faker::Plugin::EnUs::PersonName');

  $result
});

=description

This package provides methods for generating fake data for person name.

+=encoding utf8

=cut

$test->for('description');

=inherits

Faker::Plugin::EnUs

=cut

$test->for('inherits');

=method execute

The execute method returns a returns a random fake person name.

=signature execute

  execute(HashRef $data) (Str)

=metadata execute

{
  since => '1.10',
}

=example-1 execute

  package main;

  use Faker::Plugin::EnUs::PersonName;

  my $plugin = Faker::Plugin::EnUs::PersonName->new;

  # bless(..., "Faker::Plugin::EnUs::PersonName")

  # my $result = $plugin->execute;

  # "Russel Krajcik";

  # my $result = $plugin->execute;

  # "Alayna Josephine Kunde";

  # my $result = $plugin->execute;

  # "Viviane Fritsch";

=cut

$test->for('example', 1, 'execute', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  ok $result->isa('Faker::Plugin::EnUs::PersonName');
  ok $result->faker;
  ok $result->faker->random->reseed($seed);
  ok $result->faker->random->make; # reset randomizer
  is $result->execute, "Russel Krajcik";
  ok $result->faker->random->make; # reset randomizer
  is $result->execute, "Alayna Josephine Kunde";
  ok $result->faker->random->make; # reset randomizer
  is $result->execute, "Viviane Fritsch";

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

  use Faker::Plugin::EnUs::PersonName;

  my $plugin = Faker::Plugin::EnUs::PersonName->new;

  # bless(..., "Faker::Plugin::EnUs::PersonName")

=cut

$test->for('example', 1, 'new', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  ok $result->isa('Faker::Plugin::EnUs::PersonName');
  ok $result->faker;

  $result
});

# END

$test->render('lib/Faker/Plugin/EnUs/PersonName.pod') if $ENV{RENDER};

ok 1 and done_testing;
