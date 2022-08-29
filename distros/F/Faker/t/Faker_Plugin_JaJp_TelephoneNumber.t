package main;

use 5.018;

use strict;
use warnings;

use Test::More;
use Venus::Test;

my $test = test(__FILE__);
my $seed = 42;

=name

Faker::Plugin::JaJp::TelephoneNumber

=cut

$test->for('name');

=tagline

Telephone Number

=cut

$test->for('tagline');

=abstract

Telephone Number for Faker

=cut

$test->for('abstract');

=includes

method: new
method: execute

=cut

$test->for('includes');

=synopsis

  package main;

  use Faker::Plugin::JaJp::TelephoneNumber;

  my $plugin = Faker::Plugin::JaJp::TelephoneNumber->new;

  # bless(..., "Faker::Plugin::JaJp::TelephoneNumber")

=cut

$test->for('synopsis', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  ok $result->isa('Faker::Plugin::JaJp::TelephoneNumber');

  $result
});

=description

This package provides methods for generating fake data for telephone number.

+=encoding utf8

=cut

$test->for('description');

=inherits

Faker::Plugin::JaJp

=cut

$test->for('inherits');

=method execute

The execute method returns a returns a random fake telephone number.

=signature execute

  execute(HashRef $data) (Str)

=metadata execute

{
  since => '1.10',
}

=example-1 execute

  package main;

  use Faker::Plugin::JaJp::TelephoneNumber;

  my $plugin = Faker::Plugin::JaJp::TelephoneNumber->new;

  # bless(..., "Faker::Plugin::JaJp::TelephoneNumber")

  # my $result = $plugin->execute;

  # '01-4084-4684';

  # my $result = $plugin->execute;

  # '00769-4-5443';

  # my $result = $plugin->execute;

  # '080-8982-2037';

=cut

$test->for('example', 1, 'execute', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  ok $result->isa('Faker::Plugin::JaJp::TelephoneNumber');
  ok $result->faker;
  ok $result->faker->random->reseed($seed);
  ok $result->faker->random->make; # reset randomizer
  is $result->execute, '01-4084-4684';
  ok $result->faker->random->make; # reset randomizer
  is $result->execute, '00769-4-5443';
  ok $result->faker->random->make; # reset randomizer
  is $result->execute, '080-8982-2037';

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

  use Faker::Plugin::JaJp::TelephoneNumber;

  my $plugin = Faker::Plugin::JaJp::TelephoneNumber->new;

  # bless(..., "Faker::Plugin::JaJp::TelephoneNumber")

=cut

$test->for('example', 1, 'new', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  ok $result->isa('Faker::Plugin::JaJp::TelephoneNumber');
  ok $result->faker;

  $result
});

# END

$test->render('lib/Faker/Plugin/JaJp/TelephoneNumber.pod') if $ENV{RENDER};

ok 1 and done_testing;
