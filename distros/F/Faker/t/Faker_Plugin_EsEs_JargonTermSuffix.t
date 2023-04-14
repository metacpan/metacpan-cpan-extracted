package main;

use 5.018;

use strict;
use warnings;

use Test::More;
use Venus::Test;

my $test = test(__FILE__);
my $seed = 42;

=name

Faker::Plugin::EsEs::JargonTermSuffix

=cut

$test->for('name');

=tagline

Jargon Term Suffix

=cut

$test->for('tagline');

=abstract

Jargon Term Suffix for Faker

=cut

$test->for('abstract');

=includes

method: new
method: execute

=cut

$test->for('includes');

=synopsis

  package main;

  use Faker::Plugin::EsEs::JargonTermSuffix;

  my $plugin = Faker::Plugin::EsEs::JargonTermSuffix->new;

  # bless(..., "Faker::Plugin::EsEs::JargonTermSuffix")

=cut

$test->for('synopsis', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  ok $result->isa('Faker::Plugin::EsEs::JargonTermSuffix');

  $result
});

=description

This package provides methods for generating fake data for jargon term suffix.

+=encoding utf8

=cut

$test->for('description');

=inherits

Faker::Plugin::EsEs

=cut

$test->for('inherits');

=method execute

The execute method returns a returns a random fake jargon term suffix.

=signature execute

  execute(HashRef $data) (Str)

=metadata execute

{
  since => '1.10',
}

=example-1 execute

  package main;

  use Faker::Plugin::EsEs::JargonTermSuffix;

  my $plugin = Faker::Plugin::EsEs::JargonTermSuffix->new;

  # bless(..., "Faker::Plugin::EsEs::JargonTermSuffix")

  # my $result = $plugin->execute;

  # 'flexibilities';

  # my $result = $plugin->execute;

  # 'graphical user interfaces';

  # my $result = $plugin->execute;

  # 'standardization';

=cut

$test->for('example', 1, 'execute', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  ok $result->isa('Faker::Plugin::EsEs::JargonTermSuffix');
  ok $result->faker;
  ok $result->faker->random->reseed($seed);
  ok $result->faker->random->pick; # reset randomizer
  is $result->execute, 'flexibilities';
  ok $result->faker->random->pick; # reset randomizer
  is $result->execute, 'graphical user interfaces';
  ok $result->faker->random->pick; # reset randomizer
  is $result->execute, 'standardization';

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

  use Faker::Plugin::EsEs::JargonTermSuffix;

  my $plugin = Faker::Plugin::EsEs::JargonTermSuffix->new;

  # bless(..., "Faker::Plugin::EsEs::JargonTermSuffix")

=cut

$test->for('example', 1, 'new', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  ok $result->isa('Faker::Plugin::EsEs::JargonTermSuffix');
  ok $result->faker;

  $result
});

=partials

t/Faker.t: pdml: authors
t/Faker.t: pdml: license

=cut

$test->for('partials');

# END

$test->render('lib/Faker/Plugin/EsEs/JargonTermSuffix.pod') if $ENV{RENDER};

ok 1 and done_testing;
