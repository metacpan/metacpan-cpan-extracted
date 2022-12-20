package main;

use 5.018;

use strict;
use warnings;

use Test::More;
use Venus::Test;

my $test = test(__FILE__);
my $seed = 42;

=name

Faker::Plugin::JaJp::AddressLines

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

  use Faker::Plugin::JaJp::AddressLines;

  my $plugin = Faker::Plugin::JaJp::AddressLines->new;

  # bless(..., "Faker::Plugin::JaJp::AddressLines")

=cut

$test->for('synopsis', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  ok $result->isa('Faker::Plugin::JaJp::AddressLines');

  $result
});

=description

This package provides methods for generating fake data for address lines.

+=encoding utf8

=cut

$test->for('description');

=inherits

Faker::Plugin::JaJp

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

  use Faker::Plugin::JaJp::AddressLines;

  my $plugin = Faker::Plugin::JaJp::AddressLines->new;

  # bless(..., "Faker::Plugin::JaJp::AddressLines")

  # my $result = $plugin->execute;

  # '1738707  愛知県鈴木市中央杉山町笹田10-9-9';

  # my $result = $plugin->execute;

  # '7551498  神奈川県喜嶋市北山口町田辺3-5-2';

  # my $result = $plugin->execute;

  # '8319487  神奈川県渚市東渚町江古田10-9-7 コーポ渚110号';

=cut

$test->for('example', 1, 'execute', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  ok $result->isa('Faker::Plugin::JaJp::AddressLines');
  ok $result->faker;
  ok $result->faker->random->reseed($seed);
  ok $result->faker->random->pick; # reset randomizer
  is $result->execute, '1738707  愛知県鈴木市中央杉山町笹田10-9-9';
  ok $result->faker->random->pick; # reset randomizer
  is $result->execute, '7551498  神奈川県喜嶋市北山口町田辺3-5-2';
  ok $result->faker->random->pick; # reset randomizer
  is $result->execute, '8319487  神奈川県渚市東渚町江古田10-9-7 コーポ渚110号';

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

  use Faker::Plugin::JaJp::AddressLines;

  my $plugin = Faker::Plugin::JaJp::AddressLines->new;

  # bless(..., "Faker::Plugin::JaJp::AddressLines")

=cut

$test->for('example', 1, 'new', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  ok $result->isa('Faker::Plugin::JaJp::AddressLines');
  ok $result->faker;

  $result
});

# END

$test->render('lib/Faker/Plugin/JaJp/AddressLines.pod') if $ENV{RENDER};

ok 1 and done_testing;
