package main;

use 5.018;

use strict;
use warnings;

use Test::More;
use Venus::Test;

my $test = test(__FILE__);
my $seed = 42;

=name

Faker::Plugin::JaJp::CompanyDescription

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

  use Faker::Plugin::JaJp::CompanyDescription;

  my $plugin = Faker::Plugin::JaJp::CompanyDescription->new;

  # bless(..., "Faker::Plugin::JaJp::CompanyDescription")

=cut

$test->for('synopsis', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  ok $result->isa('Faker::Plugin::JaJp::CompanyDescription');

  $result
});

=description

This package provides methods for generating fake data for company description.

+=encoding utf8

=cut

$test->for('description');

=inherits

Faker::Plugin::JaJp

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

  use Faker::Plugin::JaJp::CompanyDescription;

  my $plugin = Faker::Plugin::JaJp::CompanyDescription->new;

  # bless(..., "Faker::Plugin::JaJp::CompanyDescription")

  # my $result = $plugin->execute;

  # '募集明示的互換性アナライザー';

  # my $result = $plugin->execute;

  # '提供する耐障害性アダプティブアプリケーション';

  # my $result = $plugin->execute;

  # '募集にじみ出る同化した能力';

=cut

$test->for('example', 1, 'execute', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  ok $result->isa('Faker::Plugin::JaJp::CompanyDescription');
  ok $result->faker;
  ok $result->faker->random->reseed($seed);
  ok $result->faker->random->pick; # reset randomizer
  is $result->execute, '募集明示的互換性アナライザー';
  ok $result->faker->random->pick; # reset randomizer
  is $result->execute, '提供する耐障害性アダプティブアプリケーション';
  ok $result->faker->random->pick; # reset randomizer
  is $result->execute, '募集にじみ出る同化した能力';

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

  use Faker::Plugin::JaJp::CompanyDescription;

  my $plugin = Faker::Plugin::JaJp::CompanyDescription->new;

  # bless(..., "Faker::Plugin::JaJp::CompanyDescription")

=cut

$test->for('example', 1, 'new', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  ok $result->isa('Faker::Plugin::JaJp::CompanyDescription');
  ok $result->faker;

  $result
});

=partials

t/Faker.t: pdml: authors
t/Faker.t: pdml: license

=cut

$test->for('partials');

# END

$test->render('lib/Faker/Plugin/JaJp/CompanyDescription.pod') if $ENV{RENDER};

ok 1 and done_testing;
