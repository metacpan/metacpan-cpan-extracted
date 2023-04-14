package main;

use 5.018;

use strict;
use warnings;

use Test::More;
use Venus::Test;

my $test = test(__FILE__);
my $seed = 42;

=name

Faker::Plugin::EsEs::InternetEmailAddress

=cut

$test->for('name');

=tagline

Internet Email Address

=cut

$test->for('tagline');

=abstract

Internet Email Address for Faker

=cut

$test->for('abstract');

=includes

method: new
method: execute

=cut

$test->for('includes');

=synopsis

  package main;

  use Faker::Plugin::EsEs::InternetEmailAddress;

  my $plugin = Faker::Plugin::EsEs::InternetEmailAddress->new;

  # bless(..., "Faker::Plugin::EsEs::InternetEmailAddress")

=cut

$test->for('synopsis', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  ok $result->isa('Faker::Plugin::EsEs::InternetEmailAddress');

  $result
});

=description

This package provides methods for generating fake data for internet email address.

+=encoding utf8

=cut

$test->for('description');

=inherits

Faker::Plugin::EsEs

=cut

$test->for('inherits');

=method execute

The execute method returns a returns a random fake internet email address.

=signature execute

  execute(HashRef $data) (Str)

=metadata execute

{
  since => '1.10',
}

=example-1 execute

  package main;

  use Faker::Plugin::EsEs::InternetEmailAddress;

  my $plugin = Faker::Plugin::EsEs::InternetEmailAddress->new;

  # bless(..., "Faker::Plugin::EsEs::InternetEmailAddress")

  # my $result = $plugin->execute;

  # 'rafael94@montano-y-alcala.org';

  # my $result = $plugin->execute;

  # 'alba82@terra.com';

  # my $result = $plugin->execute;

  # 'quesada.jordi@hotmail.com';

=cut

$test->for('example', 1, 'execute', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  ok $result->isa('Faker::Plugin::EsEs::InternetEmailAddress');
  ok $result->faker;
  ok $result->faker->random->reseed($seed);
  ok $result->faker->random->pick; # reset randomizer
  is $result->execute, 'rafael94@montano-y-alcala.org';
  ok $result->faker->random->pick; # reset randomizer
  is $result->execute, 'alba82@terra.com';
  ok $result->faker->random->pick; # reset randomizer
  is $result->execute, 'quesada.jordi@hotmail.com';

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

  use Faker::Plugin::EsEs::InternetEmailAddress;

  my $plugin = Faker::Plugin::EsEs::InternetEmailAddress->new;

  # bless(..., "Faker::Plugin::EsEs::InternetEmailAddress")

=cut

$test->for('example', 1, 'new', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  ok $result->isa('Faker::Plugin::EsEs::InternetEmailAddress');
  ok $result->faker;

  $result
});

=partials

t/Faker.t: pdml: authors
t/Faker.t: pdml: license

=cut

$test->for('partials');

# END

$test->render('lib/Faker/Plugin/EsEs/InternetEmailAddress.pod') if $ENV{RENDER};

ok 1 and done_testing;
