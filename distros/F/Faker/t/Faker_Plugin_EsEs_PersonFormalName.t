package main;

use 5.018;

use strict;
use warnings;

use Test::More;
use Venus::Test;

my $test = test(__FILE__);
my $seed = 42;

=name

Faker::Plugin::EsEs::PersonFormalName

=cut

$test->for('name');

=tagline

Person Formal Name

=cut

$test->for('tagline');

=abstract

Person Formal Name for Faker

=cut

$test->for('abstract');

=includes

method: new
method: execute

=cut

$test->for('includes');

=synopsis

  package main;

  use Faker::Plugin::EsEs::PersonFormalName;

  my $plugin = Faker::Plugin::EsEs::PersonFormalName->new;

  # bless(..., "Faker::Plugin::EsEs::PersonFormalName")

=cut

$test->for('synopsis', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  ok $result->isa('Faker::Plugin::EsEs::PersonFormalName');

  $result
});

=description

This package provides methods for generating fake data for person formal name.

+=encoding utf8

=cut

$test->for('description');

=inherits

Faker::Plugin::EsEs

=cut

$test->for('inherits');

=method execute

The execute method returns a returns a random fake person formal name.

=signature execute

  execute(HashRef $data) (Str)

=metadata execute

{
  since => '1.10',
}

=example-1 execute

  package main;

  use Faker::Plugin::EsEs::PersonFormalName;

  my $plugin = Faker::Plugin::EsEs::PersonFormalName->new;

  # bless(..., "Faker::Plugin::EsEs::PersonFormalName")

  # my $result = $plugin->execute;

  # 'Rafael Loera';

  # my $result = $plugin->execute;

  # 'Señora Lorena Lugo';

  # my $result = $plugin->execute;

  # 'Victoria Cornejo';

=cut

$test->for('example', 1, 'execute', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  ok $result->isa('Faker::Plugin::EsEs::PersonFormalName');
  ok $result->faker;
  ok $result->faker->random->reseed($seed);
  ok $result->faker->random->pick; # reset randomizer
  is $result->execute, 'Rafael Loera';
  ok $result->faker->random->pick; # reset randomizer
  is $result->execute, 'Señora Lorena Lugo';
  ok $result->faker->random->pick; # reset randomizer
  is $result->execute, 'Victoria Cornejo';

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

  use Faker::Plugin::EsEs::PersonFormalName;

  my $plugin = Faker::Plugin::EsEs::PersonFormalName->new;

  # bless(..., "Faker::Plugin::EsEs::PersonFormalName")

=cut

$test->for('example', 1, 'new', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  ok $result->isa('Faker::Plugin::EsEs::PersonFormalName');
  ok $result->faker;

  $result
});

# END

$test->render('lib/Faker/Plugin/EsEs/PersonFormalName.pod') if $ENV{RENDER};

ok 1 and done_testing;
