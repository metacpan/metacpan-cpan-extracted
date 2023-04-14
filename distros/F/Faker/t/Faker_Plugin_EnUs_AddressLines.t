package main;

use 5.018;

use strict;
use warnings;

use Test::More;
use Venus::Test;

my $test = test(__FILE__);
my $seed = 42;

=name

Faker::Plugin::EnUs::AddressLines

=cut

$test->for('name');

=tagline

Address Lines

=cut

$test->for('tagline');

=abstract

Address Lines for Faker

=cut

$test->for('abstract');

=includes

method: new
method: execute

=cut

$test->for('includes');

=synopsis

  package main;

  use Faker::Plugin::EnUs::AddressLines;

  my $plugin = Faker::Plugin::EnUs::AddressLines->new;

  # bless(..., "Faker::Plugin::EnUs::AddressLines")

=cut

$test->for('synopsis', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  ok $result->isa('Faker::Plugin::EnUs::AddressLines');

  $result
});

=description

This package provides methods for generating fake data for address lines.

+=encoding utf8

=cut

$test->for('description');

=inherits

Faker::Plugin::EnUs

=cut

$test->for('inherits');

=method execute

The execute method returns a returns a random fake address lines.

=signature execute

  execute(HashRef $data) (Str)

=metadata execute

{
  since => '1.10',
}

=example-1 execute

  package main;

  use Faker::Plugin::EnUs::AddressLines;

  my $plugin = Faker::Plugin::EnUs::AddressLines->new;

  # bless(..., "Faker::Plugin::EnUs::AddressLines")

  # my $result = $plugin->execute;

  # "4 Koelpin Plaza Unit 694\nWest Viviane, IA 37022";

  # my $result = $plugin->execute;

  # "90558 Greenholt Orchard\nApt. 250\nPfannerstillberg, New Mexico 52836";

  # my $result = $plugin->execute;

  # "68768 Weissnat Point\nRitchieburgh, New Mexico 53892";

=cut

$test->for('example', 1, 'execute', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  ok $result->isa('Faker::Plugin::EnUs::AddressLines');
  ok $result->faker;
  ok $result->faker->random->reseed($seed);
  ok $result->faker->random->pick; # reset randomizer
  is $result->execute, "4 Koelpin Plaza Unit 694\nWest Viviane, IA 37022";
  ok $result->faker->random->pick; # reset randomizer
  is $result->execute, "90558 Greenholt Orchard\nApt. 250\nPfannerstillberg, New Mexico 52836";
  ok $result->faker->random->pick; # reset randomizer
  is $result->execute, "68768 Weissnat Point\nRitchieburgh, New Mexico 53892";

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

  use Faker::Plugin::EnUs::AddressLines;

  my $plugin = Faker::Plugin::EnUs::AddressLines->new;

  # bless(..., "Faker::Plugin::EnUs::AddressLines")

=cut

$test->for('example', 1, 'new', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  ok $result->isa('Faker::Plugin::EnUs::AddressLines');
  ok $result->faker;

  $result
});

=partials

t/Faker.t: pdml: authors
t/Faker.t: pdml: license

=cut

$test->for('partials');

# END

$test->render('lib/Faker/Plugin/EnUs/AddressLines.pod') if $ENV{RENDER};

ok 1 and done_testing;
