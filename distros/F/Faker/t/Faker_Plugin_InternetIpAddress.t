package main;

use 5.018;

use strict;
use warnings;

use Test::More;
use Venus::Test;

my $test = test(__FILE__);
my $seed = 42;

=name

Faker::Plugin::InternetIpAddress

=cut

$test->for('name');

=tagline

Internet Ip Address

=cut

$test->for('tagline');

=abstract

Internet Ip Address for Faker

=cut

$test->for('abstract');

=includes

method: new
method: execute

=cut

$test->for('includes');

=synopsis

  package main;

  use Faker::Plugin::InternetIpAddress;

  my $plugin = Faker::Plugin::InternetIpAddress->new;

  # bless(..., "Faker::Plugin::InternetIpAddress")

=cut

$test->for('synopsis', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  ok $result->isa('Faker::Plugin::InternetIpAddress');

  $result
});

=description

This package provides methods for generating fake data for internet ip address.

+=encoding utf8

=cut

$test->for('description');

=inherits

Faker::Plugin

=cut

$test->for('inherits');

=method execute

The execute method returns a returns a random fake internet ip address.

=signature execute

  execute(HashRef $data) (Str)

=metadata execute

{
  since => '1.10',
}

=example-1 execute

  package main;

  use Faker::Plugin::InternetIpAddress;

  my $plugin = Faker::Plugin::InternetIpAddress->new;

  # bless(..., "Faker::Plugin::InternetIpAddress")

  # my $result = $plugin->execute;

  # "108.20.219.127";

  # my $result = $plugin->execute;

  # "7680:93e0:88b2:06a0:c512:99e4:e8a9:7d48";

  # my $result = $plugin->execute;

  # "89.236.15.220";

=cut

$test->for('example', 1, 'execute', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  ok $result->isa('Faker::Plugin::InternetIpAddress');
  ok $result->faker;
  ok $result->faker->random->reseed($seed);
  ok $result->faker->random->pick; # reset randomizer
  is $result->execute, "108.20.219.127";
  ok $result->faker->random->pick; # reset randomizer
  is $result->execute, "7680:93e0:88b2:06a0:c512:99e4:e8a9:7d48";
  ok $result->faker->random->pick; # reset randomizer
  is $result->execute, "89.236.15.220";

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

  use Faker::Plugin::InternetIpAddress;

  my $plugin = Faker::Plugin::InternetIpAddress->new;

  # bless(..., "Faker::Plugin::InternetIpAddress")

=cut

$test->for('example', 1, 'new', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  ok $result->isa('Faker::Plugin::InternetIpAddress');
  ok $result->faker;

  $result
});

=partials

t/Faker.t: pdml: authors
t/Faker.t: pdml: license

=cut

$test->for('partials');

# END

$test->render('lib/Faker/Plugin/InternetIpAddress.pod') if $ENV{RENDER};

ok 1 and done_testing;
