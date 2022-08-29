package main;

use 5.018;

use strict;
use warnings;

use Test::More;
use Venus::Test;

my $test = test(__FILE__);
my $seed = 42;

=name

Faker::Plugin::EnUs::AddressStateAbbr

=cut

$test->for('name');

=tagline

Address State Abbr

=cut

$test->for('tagline');

=abstract

Address State Abbr for Faker

=cut

$test->for('abstract');

=includes

method: new
method: execute

=cut

$test->for('includes');

=synopsis

  package main;

  use Faker::Plugin::EnUs::AddressStateAbbr;

  my $plugin = Faker::Plugin::EnUs::AddressStateAbbr->new;

  # bless(..., "Faker::Plugin::EnUs::AddressStateAbbr")

=cut

$test->for('synopsis', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  ok $result->isa('Faker::Plugin::EnUs::AddressStateAbbr');

  $result
});

=description

This package provides methods for generating fake data for address state abbr.

+=encoding utf8

=cut

$test->for('description');

=inherits

Faker::Plugin::EnUs

=cut

$test->for('inherits');

=method execute

The execute method returns a returns a random fake address state abbr.

=signature execute

  execute(HashRef $data) (Str)

=metadata execute

{
  since => '1.10',
}

=example-1 execute

  package main;

  use Faker::Plugin::EnUs::AddressStateAbbr;

  my $plugin = Faker::Plugin::EnUs::AddressStateAbbr->new;

  # bless(..., "Faker::Plugin::EnUs::AddressStateAbbr")

  # my $result = $plugin->execute;

  # "KY";

  # my $result = $plugin->execute;

  # "ME";

  # my $result = $plugin->execute;

  # "TX";

=cut

$test->for('example', 1, 'execute', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  ok $result->isa('Faker::Plugin::EnUs::AddressStateAbbr');
  ok $result->faker;
  ok $result->faker->random->reseed($seed);
  ok $result->faker->random->make; # reset randomizer
  is $result->execute, "KY";
  ok $result->faker->random->make; # reset randomizer
  is $result->execute, "ME";
  ok $result->faker->random->make; # reset randomizer
  is $result->execute, "TX";

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

  use Faker::Plugin::EnUs::AddressStateAbbr;

  my $plugin = Faker::Plugin::EnUs::AddressStateAbbr->new;

  # bless(..., "Faker::Plugin::EnUs::AddressStateAbbr")

=cut

$test->for('example', 1, 'new', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  ok $result->isa('Faker::Plugin::EnUs::AddressStateAbbr');
  ok $result->faker;

  $result
});

# END

$test->render('lib/Faker/Plugin/EnUs/AddressStateAbbr.pod') if $ENV{RENDER};

ok 1 and done_testing;
