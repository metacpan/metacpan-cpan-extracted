package main;

use 5.018;

use strict;
use warnings;

use Test::More;
use Venus::Test;

my $test = test(__FILE__);
my $seed = 42;

=name

Faker::Plugin::UserLogin

=cut

$test->for('name');

=tagline

User Login

=cut

$test->for('tagline');

=abstract

User Login for Faker

=cut

$test->for('abstract');

=includes

method: new
method: execute

=cut

$test->for('includes');

=synopsis

  package main;

  use Faker::Plugin::UserLogin;

  my $plugin = Faker::Plugin::UserLogin->new;

  # bless(..., "Faker::Plugin::UserLogin")

=cut

$test->for('synopsis', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  ok $result->isa('Faker::Plugin::UserLogin');

  $result
});

=description

This package provides methods for generating fake data for user login.

+=encoding utf8

=cut

$test->for('description');

=inherits

Faker::Plugin

=cut

$test->for('inherits');

=method execute

The execute method returns a returns a random fake user login.

=signature execute

  execute(HashRef $data) (Str)

=metadata execute

{
  since => '1.10',
}

=example-1 execute

  package main;

  use Faker::Plugin::UserLogin;

  my $plugin = Faker::Plugin::UserLogin->new(
    faker => {locales => ['en-us']},
  );

  # bless(..., "Faker::Plugin::UserLogin")

  # my $result = $plugin->execute;

  # "Russel44";

  # my $result = $plugin->execute;

  # "aMayer7694";

  # my $result = $plugin->execute;

  # "Amalia89";

=cut

$test->for('example', 1, 'execute', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  ok $result->isa('Faker::Plugin::UserLogin');
  ok $result->faker;
  ok $result->faker->random->reseed($seed);
  ok $result->faker->random->pick; # reset randomizer
  is $result->execute, "Russel44";
  ok $result->faker->random->pick; # reset randomizer
  is $result->execute, "aMayer7694";
  ok $result->faker->random->pick; # reset randomizer
  is $result->execute, "Amalia89";

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

  use Faker::Plugin::UserLogin;

  my $plugin = Faker::Plugin::UserLogin->new;

  # bless(..., "Faker::Plugin::UserLogin")

=cut

$test->for('example', 1, 'new', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  ok $result->isa('Faker::Plugin::UserLogin');
  ok $result->faker;

  $result
});

=partials

t/Faker.t: pdml: authors
t/Faker.t: pdml: license

=cut

$test->for('partials');

# END

$test->render('lib/Faker/Plugin/UserLogin.pod') if $ENV{RENDER};

ok 1 and done_testing;
