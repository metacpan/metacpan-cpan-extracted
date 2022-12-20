package main;

use 5.018;

use strict;
use warnings;

use Test::More;
use Venus::Test;

my $test = test(__FILE__);
my $seed = 42;

=name

Faker::Plugin::EsEs::AddressCityName

=cut

$test->for('name');

=tagline

Address City Name

=cut

$test->for('tagline');

=abstract

Address City Name for Faker

=cut

$test->for('abstract');

=includes

method: new
method: execute

=cut

$test->for('includes');

=synopsis

  package main;

  use Faker::Plugin::EsEs::AddressCityName;

  my $plugin = Faker::Plugin::EsEs::AddressCityName->new;

  # bless(..., "Faker::Plugin::EsEs::AddressCityName")

=cut

$test->for('synopsis', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  ok $result->isa('Faker::Plugin::EsEs::AddressCityName');

  $result
});

=description

This package provides methods for generating fake data for address city name.

+=encoding utf8

=cut

$test->for('description');

=inherits

Faker::Plugin::EsEs

=cut

$test->for('inherits');

=method execute

The execute method returns a returns a random fake address city name.

=signature execute

  execute(HashRef $data) (Str)

=metadata execute

{
  since => '1.10',
}

=example-1 execute

  package main;

  use Faker::Plugin::EsEs::AddressCityName;

  my $plugin = Faker::Plugin::EsEs::AddressCityName->new;

  # bless(..., "Faker::Plugin::EsEs::AddressCityName")

  # my $result = $plugin->execute;

  # 'Los Serrato';

  # my $result = $plugin->execute;

  # 'Os Montaño';

  # my $result = $plugin->execute;

  # 'Las Lozano de la Sierra';

=cut

$test->for('example', 1, 'execute', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  ok $result->isa('Faker::Plugin::EsEs::AddressCityName');
  ok $result->faker;
  ok $result->faker->random->reseed($seed);
  ok $result->faker->random->pick; # reset randomizer
  is $result->execute, 'Los Serrato';
  ok $result->faker->random->pick; # reset randomizer
  is $result->execute, 'Os Montaño';
  ok $result->faker->random->pick; # reset randomizer
  is $result->execute, 'Las Lozano de la Sierra';

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

  use Faker::Plugin::EsEs::AddressCityName;

  my $plugin = Faker::Plugin::EsEs::AddressCityName->new;

  # bless(..., "Faker::Plugin::EsEs::AddressCityName")

=cut

$test->for('example', 1, 'new', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  ok $result->isa('Faker::Plugin::EsEs::AddressCityName');
  ok $result->faker;

  $result
});

# END

$test->render('lib/Faker/Plugin/EsEs/AddressCityName.pod') if $ENV{RENDER};

ok 1 and done_testing;
