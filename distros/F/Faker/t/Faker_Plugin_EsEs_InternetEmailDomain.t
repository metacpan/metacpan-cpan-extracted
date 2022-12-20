package main;

use 5.018;

use strict;
use warnings;

use Test::More;
use Venus::Test;

my $test = test(__FILE__);
my $seed = 42;

=name

Faker::Plugin::EsEs::InternetEmailDomain

=cut

$test->for('name');

=tagline

Internet Email Domain

=cut

$test->for('tagline');

=abstract

Internet Email Domain for Faker

=cut

$test->for('abstract');

=includes

method: new
method: execute

=cut

$test->for('includes');

=synopsis

  package main;

  use Faker::Plugin::EsEs::InternetEmailDomain;

  my $plugin = Faker::Plugin::EsEs::InternetEmailDomain->new;

  # bless(..., "Faker::Plugin::EsEs::InternetEmailDomain")

=cut

$test->for('synopsis', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  ok $result->isa('Faker::Plugin::EsEs::InternetEmailDomain');

  $result
});

=description

This package provides methods for generating fake data for internet email domain.

+=encoding utf8

=cut

$test->for('description');

=inherits

Faker::Plugin::EsEs

=cut

$test->for('inherits');

=method execute

The execute method returns a returns a random fake internet email domain.

=signature execute

  execute(HashRef $data) (Str)

=metadata execute

{
  since => '1.10',
}

=example-1 execute

  package main;

  use Faker::Plugin::EsEs::InternetEmailDomain;

  my $plugin = Faker::Plugin::EsEs::InternetEmailDomain->new;

  # bless(..., "Faker::Plugin::EsEs::InternetEmailDomain")

  # my $result = $plugin->execute;

  # 'yahoo.com';

  # my $result = $plugin->execute;

  # 'yahoo.com';

  # my $result = $plugin->execute;

  # 'latinmail.com';

=cut

$test->for('example', 1, 'execute', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  ok $result->isa('Faker::Plugin::EsEs::InternetEmailDomain');
  ok $result->faker;
  ok $result->faker->random->reseed($seed);
  ok $result->faker->random->pick; # reset randomizer
  is $result->execute, 'yahoo.com';
  ok $result->faker->random->pick; # reset randomizer
  is $result->execute, 'yahoo.com';
  ok $result->faker->random->pick; # reset randomizer
  is $result->execute, 'latinmail.com';

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

  use Faker::Plugin::EsEs::InternetEmailDomain;

  my $plugin = Faker::Plugin::EsEs::InternetEmailDomain->new;

  # bless(..., "Faker::Plugin::EsEs::InternetEmailDomain")

=cut

$test->for('example', 1, 'new', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  ok $result->isa('Faker::Plugin::EsEs::InternetEmailDomain');
  ok $result->faker;

  $result
});

# END

$test->render('lib/Faker/Plugin/EsEs/InternetEmailDomain.pod') if $ENV{RENDER};

ok 1 and done_testing;
