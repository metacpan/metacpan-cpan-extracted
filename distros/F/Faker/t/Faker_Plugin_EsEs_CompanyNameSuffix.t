package main;

use 5.018;

use strict;
use warnings;

use Test::More;
use Venus::Test;

my $test = test(__FILE__);
my $seed = 42;

=name

Faker::Plugin::EsEs::CompanyNameSuffix

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

  use Faker::Plugin::EsEs::CompanyNameSuffix;

  my $plugin = Faker::Plugin::EsEs::CompanyNameSuffix->new;

  # bless(..., "Faker::Plugin::EsEs::CompanyNameSuffix")

=cut

$test->for('synopsis', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  ok $result->isa('Faker::Plugin::EsEs::CompanyNameSuffix');

  $result
});

=description

This package provides methods for generating fake data for company name suffix.

+=encoding utf8

=cut

$test->for('description');

=inherits

Faker::Plugin::EsEs

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

  use Faker::Plugin::EsEs::CompanyNameSuffix;

  my $plugin = Faker::Plugin::EsEs::CompanyNameSuffix->new;

  # bless(..., "Faker::Plugin::EsEs::CompanyNameSuffix")

  # my $result = $plugin->execute;

  # 'e Hijos';

  # my $result = $plugin->execute;

  # 'y Asoc.';

  # my $result = $plugin->execute;

  # 'SA';

=cut

$test->for('example', 1, 'execute', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  ok $result->isa('Faker::Plugin::EsEs::CompanyNameSuffix');
  ok $result->faker;
  ok $result->faker->random->reseed($seed);
  ok $result->faker->random->make; # reset randomizer
  is $result->execute, 'e Hijos';
  ok $result->faker->random->make; # reset randomizer
  is $result->execute, 'y Asoc.';
  ok $result->faker->random->make; # reset randomizer
  is $result->execute, 'SA';

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

  use Faker::Plugin::EsEs::CompanyNameSuffix;

  my $plugin = Faker::Plugin::EsEs::CompanyNameSuffix->new;

  # bless(..., "Faker::Plugin::EsEs::CompanyNameSuffix")

=cut

$test->for('example', 1, 'new', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  ok $result->isa('Faker::Plugin::EsEs::CompanyNameSuffix');
  ok $result->faker;

  $result
});

# END

$test->render('lib/Faker/Plugin/EsEs/CompanyNameSuffix.pod') if $ENV{RENDER};

ok 1 and done_testing;
