package main;

use 5.018;

use strict;
use warnings;

use Test::More;
use Venus::Test;

my $test = test(__FILE__);
my $seed = 42;

=name

Faker::Plugin::EnUs::TelephoneNumber

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

  use Faker::Plugin::EnUs::TelephoneNumber;

  my $plugin = Faker::Plugin::EnUs::TelephoneNumber->new;

  # bless(..., "Faker::Plugin::EnUs::TelephoneNumber")

=cut

$test->for('synopsis', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  ok $result->isa('Faker::Plugin::EnUs::TelephoneNumber');

  $result
});

=description

This package provides methods for generating fake data for telephone number.

+=encoding utf8

=cut

$test->for('description');

=inherits

Faker::Plugin::EnUs

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

  use Faker::Plugin::EnUs::TelephoneNumber;

  my $plugin = Faker::Plugin::EnUs::TelephoneNumber->new;

  # bless(..., "Faker::Plugin::EnUs::TelephoneNumber")

  # my $result = $plugin->execute;

  # "01408446845";

  # my $result = $plugin->execute;

  # "769-454-4390";

  # my $result = $plugin->execute;

  # "1-822-037-0225x82882";

=cut

$test->for('example', 1, 'execute', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  ok $result->isa('Faker::Plugin::EnUs::TelephoneNumber');
  ok $result->faker;
  ok $result->faker->random->reseed($seed);
  ok $result->faker->random->pick; # reset randomizer
  is $result->execute, "01408446845";
  ok $result->faker->random->pick; # reset randomizer
  is $result->execute, "769-454-4390";
  ok $result->faker->random->pick; # reset randomizer
  is $result->execute, "1-822-037-0225x82882";

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

  use Faker::Plugin::EnUs::TelephoneNumber;

  my $plugin = Faker::Plugin::EnUs::TelephoneNumber->new;

  # bless(..., "Faker::Plugin::EnUs::TelephoneNumber")

=cut

$test->for('example', 1, 'new', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  ok $result->isa('Faker::Plugin::EnUs::TelephoneNumber');
  ok $result->faker;

  $result
});

# END

$test->render('lib/Faker/Plugin/EnUs/TelephoneNumber.pod') if $ENV{RENDER};

ok 1 and done_testing;
