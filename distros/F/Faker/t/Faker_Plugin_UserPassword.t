package main;

use 5.018;

use strict;
use warnings;

use Test::More;
use Venus::Test;

my $test = test(__FILE__);
my $seed = 42;

=name

Faker::Plugin::UserPassword

=cut

$test->for('name');

=tagline

User Password

=cut

$test->for('tagline');

=abstract

User Password for Faker

=cut

$test->for('abstract');

=includes

method: new
method: execute

=cut

$test->for('includes');

=synopsis

  package main;

  use Faker::Plugin::UserPassword;

  my $plugin = Faker::Plugin::UserPassword->new;

  # bless(..., "Faker::Plugin::UserPassword")

=cut

$test->for('synopsis', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  ok $result->isa('Faker::Plugin::UserPassword');

  $result
});

=description

This package provides methods for generating fake data for user password.

+=encoding utf8

=cut

$test->for('description');

=inherits

Faker::Plugin

=cut

$test->for('inherits');

=method execute

The execute method returns a returns a random fake user password.

=signature execute

  execute(HashRef $data) (Str)

=metadata execute

{
  since => '1.10',
}

=example-1 execute

  package main;

  use Faker::Plugin::UserPassword;

  my $plugin = Faker::Plugin::UserPassword->new;

  # bless(..., "Faker::Plugin::UserPassword")

  # my $result = $plugin->execute;

  # "48R+a}[Lb?&0725";

  # my $result = $plugin->execute;

  # ",0w\$h4155>*0M";

  # my $result = $plugin->execute;

  # ")P2^'q695a}8GX";

=cut

$test->for('example', 1, 'execute', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  ok $result->isa('Faker::Plugin::UserPassword');
  ok $result->faker;
  ok $result->faker->random->reseed($seed);
  ok $result->faker->random->pick; # reset randomizer
  is $result->execute, "48R+a}[Lb?&0725";
  ok $result->faker->random->pick; # reset randomizer
  is $result->execute, ",0w\$h4155>*0M";
  ok $result->faker->random->pick; # reset randomizer
  is $result->execute, ")P2^'q695a}8GX";

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

  use Faker::Plugin::UserPassword;

  my $plugin = Faker::Plugin::UserPassword->new;

  # bless(..., "Faker::Plugin::UserPassword")

=cut

$test->for('example', 1, 'new', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  ok $result->isa('Faker::Plugin::UserPassword');
  ok $result->faker;

  $result
});

# END

$test->render('lib/Faker/Plugin/UserPassword.pod') if $ENV{RENDER};

ok 1 and done_testing;
