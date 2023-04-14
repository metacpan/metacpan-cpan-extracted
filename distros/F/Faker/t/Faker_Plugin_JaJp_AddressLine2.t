package main;

use 5.018;

use strict;
use warnings;

use Test::More;
use Venus::Test;

my $test = test(__FILE__);
my $seed = 42;

=name

Faker::Plugin::JaJp::AddressLine2

=cut

$test->for('name');

=tagline

Address Line2

=cut

$test->for('tagline');

=abstract

Address Line2 for Faker

=cut

$test->for('abstract');

=includes

method: new
method: execute

=cut

$test->for('includes');

=synopsis

  package main;

  use Faker::Plugin::JaJp::AddressLine2;

  my $plugin = Faker::Plugin::JaJp::AddressLine2->new;

  # bless(..., "Faker::Plugin::JaJp::AddressLine2")

=cut

$test->for('synopsis', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  ok $result->isa('Faker::Plugin::JaJp::AddressLine2');

  $result
});

=description

This package provides methods for generating fake data for address line2.

+=encoding utf8

=cut

$test->for('description');

=inherits

Faker::Plugin::JaJp

=cut

$test->for('inherits');

=method execute

The execute method returns a returns a random fake address line2.

=signature execute

  execute(HashRef $data) (Str)

=metadata execute

{
  since => '1.10',
}

=example-1 execute

  package main;

  use Faker::Plugin::JaJp::AddressLine2;

  my $plugin = Faker::Plugin::JaJp::AddressLine2->new;

  # bless(..., "Faker::Plugin::JaJp::AddressLine2")

  # my $result = $plugin->execute;

  # 'ハイツ佐藤109号';

  # my $result = $plugin->execute;

  # 'ハイツ村山106号';

  # my $result = $plugin->execute;

  # 'ハイツ中村105号';

=cut

$test->for('example', 1, 'execute', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  ok $result->isa('Faker::Plugin::JaJp::AddressLine2');
  ok $result->faker;
  ok $result->faker->random->reseed($seed);
  ok $result->faker->random->pick; # reset randomizer
  is $result->execute, 'ハイツ佐藤109号';
  ok $result->faker->random->pick; # reset randomizer
  is $result->execute, 'ハイツ村山106号';
  ok $result->faker->random->pick; # reset randomizer
  is $result->execute, 'ハイツ中村105号';

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

  use Faker::Plugin::JaJp::AddressLine2;

  my $plugin = Faker::Plugin::JaJp::AddressLine2->new;

  # bless(..., "Faker::Plugin::JaJp::AddressLine2")

=cut

$test->for('example', 1, 'new', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  ok $result->isa('Faker::Plugin::JaJp::AddressLine2');
  ok $result->faker;

  $result
});

=partials

t/Faker.t: pdml: authors
t/Faker.t: pdml: license

=cut

$test->for('partials');

# END

$test->render('lib/Faker/Plugin/JaJp/AddressLine2.pod') if $ENV{RENDER};

ok 1 and done_testing;
