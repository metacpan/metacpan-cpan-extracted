package main;

use 5.018;

use strict;
use warnings;

use Test::More;
use Venus::Test;

my $test = test(__FILE__);
my $seed = 42;

=name

Faker::Plugin::EnUs::CompanyName

=cut

$test->for('name');

=tagline

Company Name

=cut

$test->for('tagline');

=abstract

Company Name for Faker

=cut

$test->for('abstract');

=includes

method: new
method: execute

=cut

$test->for('includes');

=synopsis

  package main;

  use Faker::Plugin::EnUs::CompanyName;

  my $plugin = Faker::Plugin::EnUs::CompanyName->new;

  # bless(..., "Faker::Plugin::EnUs::CompanyName")

=cut

$test->for('synopsis', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  ok $result->isa('Faker::Plugin::EnUs::CompanyName');

  $result
});

=description

This package provides methods for generating fake data for company name.

+=encoding utf8

=cut

$test->for('description');

=inherits

Faker::Plugin::EnUs

=cut

$test->for('inherits');

=method execute

The execute method returns a returns a random fake company name.

=signature execute

  execute(HashRef $data) (Str)

=metadata execute

{
  since => '1.10',
}

=example-1 execute

  package main;

  use Faker::Plugin::EnUs::CompanyName;

  my $plugin = Faker::Plugin::EnUs::CompanyName->new;

  # bless(..., "Faker::Plugin::EnUs::CompanyName")

  # my $result = $plugin->execute;

  # "Johnston-Steuber";

  # my $result = $plugin->execute;

  # "Skiles-Mayer";

  # my $result = $plugin->execute;

  # "Miller and Sons";

=cut

$test->for('example', 1, 'execute', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  ok $result->isa('Faker::Plugin::EnUs::CompanyName');
  ok $result->faker;
  ok $result->faker->random->reseed($seed);
  ok $result->faker->random->pick; # reset randomizer
  is $result->execute, "Johnston-Steuber";
  ok $result->faker->random->pick; # reset randomizer
  is $result->execute, "Skiles-Mayer";
  ok $result->faker->random->pick; # reset randomizer
  is $result->execute, "Miller and Sons";

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

  use Faker::Plugin::EnUs::CompanyName;

  my $plugin = Faker::Plugin::EnUs::CompanyName->new;

  # bless(..., "Faker::Plugin::EnUs::CompanyName")

=cut

$test->for('example', 1, 'new', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  ok $result->isa('Faker::Plugin::EnUs::CompanyName');
  ok $result->faker;

  $result
});

=partials

t/Faker.t: pdml: authors
t/Faker.t: pdml: license

=cut

$test->for('partials');

# END

$test->render('lib/Faker/Plugin/EnUs/CompanyName.pod') if $ENV{RENDER};

ok 1 and done_testing;
