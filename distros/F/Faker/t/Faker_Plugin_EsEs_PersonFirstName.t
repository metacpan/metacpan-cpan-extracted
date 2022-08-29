package main;

use 5.018;

use strict;
use warnings;

use Test::More;
use Venus::Test;

my $test = test(__FILE__);
my $seed = 42;

=name

Faker::Plugin::EsEs::PersonFirstName

=cut

$test->for('name');

=tagline

Person First Name

=cut

$test->for('tagline');

=abstract

Person First Name for Faker

=cut

$test->for('abstract');

=includes

method: new
method: execute

=cut

$test->for('includes');

=synopsis

  package main;

  use Faker::Plugin::EsEs::PersonFirstName;

  my $plugin = Faker::Plugin::EsEs::PersonFirstName->new;

  # bless(..., "Faker::Plugin::EsEs::PersonFirstName")

=cut

$test->for('synopsis', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  ok $result->isa('Faker::Plugin::EsEs::PersonFirstName');

  $result
});

=description

This package provides methods for generating fake data for person first name.

+=encoding utf8

=cut

$test->for('description');

=inherits

Faker::Plugin::EsEs

=cut

$test->for('inherits');

=method execute

The execute method returns a returns a random fake person first name.

=signature execute

  execute(HashRef $data) (Str)

=metadata execute

{
  since => '1.10',
}

=example-1 execute

  package main;

  use Faker::Plugin::EsEs::PersonFirstName;

  my $plugin = Faker::Plugin::EsEs::PersonFirstName->new;

  # bless(..., "Faker::Plugin::EsEs::PersonFirstName")

  # my $result = $plugin->execute;

  # 'Hugo';

  # my $result = $plugin->execute;

  # 'Iván';

  # my $result = $plugin->execute;

  # 'Jorge';

=cut

$test->for('example', 1, 'execute', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  ok $result->isa('Faker::Plugin::EsEs::PersonFirstName');
  ok $result->faker;
  ok $result->faker->random->reseed($seed);
  ok $result->faker->random->make; # reset randomizer
  is $result->execute, 'Hugo';
  ok $result->faker->random->make; # reset randomizer
  is $result->execute, 'Iván';
  ok $result->faker->random->make; # reset randomizer
  is $result->execute, 'Jorge';

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

  use Faker::Plugin::EsEs::PersonFirstName;

  my $plugin = Faker::Plugin::EsEs::PersonFirstName->new;

  # bless(..., "Faker::Plugin::EsEs::PersonFirstName")

=cut

$test->for('example', 1, 'new', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  ok $result->isa('Faker::Plugin::EsEs::PersonFirstName');
  ok $result->faker;

  $result
});

# END

$test->render('lib/Faker/Plugin/EsEs/PersonFirstName.pod') if $ENV{RENDER};

ok 1 and done_testing;
