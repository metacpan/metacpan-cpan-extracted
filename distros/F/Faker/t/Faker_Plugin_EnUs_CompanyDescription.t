package main;

use 5.018;

use strict;
use warnings;

use Test::More;
use Venus::Test;

my $test = test(__FILE__);
my $seed = 42;

=name

Faker::Plugin::EnUs::CompanyDescription

=cut

$test->for('name');

=tagline

Company Description

=cut

$test->for('tagline');

=abstract

Company Description for Faker

=cut

$test->for('abstract');

=includes

method: new
method: execute

=cut

$test->for('includes');

=synopsis

  package main;

  use Faker::Plugin::EnUs::CompanyDescription;

  my $plugin = Faker::Plugin::EnUs::CompanyDescription->new;

  # bless(..., "Faker::Plugin::EnUs::CompanyDescription")

=cut

$test->for('synopsis', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  ok $result->isa('Faker::Plugin::EnUs::CompanyDescription');

  $result
});

=description

This package provides methods for generating fake data for company description.

+=encoding utf8

=cut

$test->for('description');

=inherits

Faker::Plugin::EnUs

=cut

$test->for('inherits');

=method execute

The execute method returns a returns a random fake company description.

=signature execute

  execute(HashRef $data) (Str)

=metadata execute

{
  since => '1.10',
}

=example-1 execute

  package main;

  use Faker::Plugin::EnUs::CompanyDescription;

  my $plugin = Faker::Plugin::EnUs::CompanyDescription->new;

  # bless(..., "Faker::Plugin::EnUs::CompanyDescription")

  # my $result = $plugin->execute;

  # "Excels at full-range synchronised implementations";

  # my $result = $plugin->execute;

  # "Provides logistical ameliorated methodologies";

  # my $result = $plugin->execute;

  # "Offering hybrid future-proofed applications";

=cut

$test->for('example', 1, 'execute', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  ok $result->isa('Faker::Plugin::EnUs::CompanyDescription');
  ok $result->faker;
  ok $result->faker->random->reseed($seed);
  ok $result->faker->random->pick; # reset randomizer
  is $result->execute, "Excels at full-range synchronised implementations";
  ok $result->faker->random->pick; # reset randomizer
  is $result->execute, "Provides logistical ameliorated methodologies";
  ok $result->faker->random->pick; # reset randomizer
  is $result->execute, "Offering hybrid future-proofed applications";

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

  use Faker::Plugin::EnUs::CompanyDescription;

  my $plugin = Faker::Plugin::EnUs::CompanyDescription->new;

  # bless(..., "Faker::Plugin::EnUs::CompanyDescription")

=cut

$test->for('example', 1, 'new', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  ok $result->isa('Faker::Plugin::EnUs::CompanyDescription');
  ok $result->faker;

  $result
});

# END

$test->render('lib/Faker/Plugin/EnUs/CompanyDescription.pod') if $ENV{RENDER};

ok 1 and done_testing;
