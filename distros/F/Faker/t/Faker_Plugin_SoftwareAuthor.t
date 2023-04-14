package main;

use 5.018;

use strict;
use warnings;

use Test::More;
use Venus::Test;

my $test = test(__FILE__);
my $seed = 42;

=name

Faker::Plugin::SoftwareAuthor

=cut

$test->for('name');

=tagline

Software Author

=cut

$test->for('tagline');

=abstract

Software Author for Faker

=cut

$test->for('abstract');

=includes

method: new
method: execute

=cut

$test->for('includes');

=synopsis

  package main;

  use Faker::Plugin::SoftwareAuthor;

  my $plugin = Faker::Plugin::SoftwareAuthor->new;

  # bless(..., "Faker::Plugin::SoftwareAuthor")

=cut

$test->for('synopsis', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  ok $result->isa('Faker::Plugin::SoftwareAuthor');

  $result
});

=description

This package provides methods for generating fake data for software author.

+=encoding utf8

=cut

$test->for('description');

=inherits

Faker::Plugin

=cut

$test->for('inherits');

=method execute

The execute method returns a returns a random fake software author.

=signature execute

  execute(HashRef $data) (Str)

=metadata execute

{
  since => '1.10',
}

=example-1 execute

  package main;

  use Faker::Plugin::SoftwareAuthor;

  my $plugin = Faker::Plugin::SoftwareAuthor->new(
    faker => {locales => ['en-us']},
  );

  # bless(..., "Faker::Plugin::SoftwareAuthor")

  # my $result = $plugin->execute;

  # "Jamison Skiles";

  # my $result = $plugin->execute;

  # "Josephine Kunde";

  # my $result = $plugin->execute;

  # "Darby Boyer";

=cut

$test->for('example', 1, 'execute', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  ok $result->isa('Faker::Plugin::SoftwareAuthor');
  ok $result->faker;
  ok $result->faker->random->reseed($seed);
  ok $result->faker->random->pick; # reset randomizer
  is $result->execute, "Jamison Skiles";
  ok $result->faker->random->pick; # reset randomizer
  is $result->execute, "Josephine Kunde";
  ok $result->faker->random->pick; # reset randomizer
  is $result->execute, "Darby Boyer";

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

  use Faker::Plugin::SoftwareAuthor;

  my $plugin = Faker::Plugin::SoftwareAuthor->new;

  # bless(..., "Faker::Plugin::SoftwareAuthor")

=cut

$test->for('example', 1, 'new', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  ok $result->isa('Faker::Plugin::SoftwareAuthor');
  ok $result->faker;

  $result
});

=partials

t/Faker.t: pdml: authors
t/Faker.t: pdml: license

=cut

$test->for('partials');

# END

$test->render('lib/Faker/Plugin/SoftwareAuthor.pod') if $ENV{RENDER};

ok 1 and done_testing;
