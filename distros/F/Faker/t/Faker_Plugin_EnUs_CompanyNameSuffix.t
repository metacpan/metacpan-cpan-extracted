package main;

use 5.018;

use strict;
use warnings;

use Test::More;
use Venus::Test;

my $test = test(__FILE__);
my $seed = 42;

=name

Faker::Plugin::EnUs::CompanyNameSuffix

=cut

$test->for('name');

=tagline

Company Name Suffix

=cut

$test->for('tagline');

=abstract

Company Name Suffix for Faker

=cut

$test->for('abstract');

=includes

method: new
method: execute

=cut

$test->for('includes');

=synopsis

  package main;

  use Faker::Plugin::EnUs::CompanyNameSuffix;

  my $plugin = Faker::Plugin::EnUs::CompanyNameSuffix->new;

  # bless(..., "Faker::Plugin::EnUs::CompanyNameSuffix")

=cut

$test->for('synopsis', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  ok $result->isa('Faker::Plugin::EnUs::CompanyNameSuffix');

  $result
});

=description

This package provides methods for generating fake data for company name suffix.

+=encoding utf8

=cut

$test->for('description');

=inherits

Faker::Plugin::EnUs

=cut

$test->for('inherits');

=method execute

The execute method returns a returns a random fake company name suffix.

=signature execute

  execute(HashRef $data) (Str)

=metadata execute

{
  since => '1.10',
}

=example-1 execute

  package main;

  use Faker::Plugin::EnUs::CompanyNameSuffix;

  my $plugin = Faker::Plugin::EnUs::CompanyNameSuffix->new;

  # bless(..., "Faker::Plugin::EnUs::CompanyNameSuffix")

  # my $result = $plugin->execute;

  # "Inc.";

  # my $result = $plugin->execute;

  # "Incorporated";

  # my $result = $plugin->execute;

  # "Ventures";

=cut

$test->for('example', 1, 'execute', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  ok $result->isa('Faker::Plugin::EnUs::CompanyNameSuffix');
  ok $result->faker;
  ok $result->faker->random->reseed($seed);
  ok $result->faker->random->pick; # reset randomizer
  is $result->execute, "Inc.";
  ok $result->faker->random->pick; # reset randomizer
  is $result->execute, "Incorporated";
  ok $result->faker->random->pick; # reset randomizer
  is $result->execute, "Ventures";

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

  use Faker::Plugin::EnUs::CompanyNameSuffix;

  my $plugin = Faker::Plugin::EnUs::CompanyNameSuffix->new;

  # bless(..., "Faker::Plugin::EnUs::CompanyNameSuffix")

=cut

$test->for('example', 1, 'new', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  ok $result->isa('Faker::Plugin::EnUs::CompanyNameSuffix');
  ok $result->faker;

  $result
});

# END

$test->render('lib/Faker/Plugin/EnUs/CompanyNameSuffix.pod') if $ENV{RENDER};

ok 1 and done_testing;
