package main;

use 5.018;

use strict;
use warnings;

use Test::More;
use Venus::Test;

my $test = test(__FILE__);
my $seed = 42;

=name

Faker::Plugin::InternetIpAddressV4

=cut

$test->for('name');

=tagline

Internet Ip Address V4

=cut

$test->for('tagline');

=abstract

Internet Ip Address V4 for Faker

=cut

$test->for('abstract');

=includes

method: new
method: execute

=cut

$test->for('includes');

=synopsis

  package main;

  use Faker::Plugin::InternetIpAddressV4;

  my $plugin = Faker::Plugin::InternetIpAddressV4->new;

  # bless(..., "Faker::Plugin::InternetIpAddressV4")

=cut

$test->for('synopsis', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  ok $result->isa('Faker::Plugin::InternetIpAddressV4');

  $result
});

=description

This package provides methods for generating fake data for internet ip address v4.

+=encoding utf8

=cut

$test->for('description');

=inherits

Faker::Plugin

=cut

$test->for('inherits');

=method execute

The execute method returns a returns a random fake internet ip address v4.

=signature execute

  execute(HashRef $data) (Str)

=metadata execute

{
  since => '1.10',
}

=example-1 execute

  package main;

  use Faker::Plugin::InternetIpAddressV4;

  my $plugin = Faker::Plugin::InternetIpAddressV4->new;

  # bless(..., "Faker::Plugin::InternetIpAddressV4")

  # my $result = $plugin->execute;

  # "87.28.108.20";

  # my $result = $plugin->execute;

  # "127.122.176.213";

  # my $result = $plugin->execute;

  # "147.136.6.197";

=cut

$test->for('example', 1, 'execute', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  ok $result->isa('Faker::Plugin::InternetIpAddressV4');
  ok $result->faker;
  ok $result->faker->random->reseed($seed);
  ok $result->faker->random->pick; # reset randomizer
  is $result->execute, "87.28.108.20";
  ok $result->faker->random->pick; # reset randomizer
  is $result->execute, "127.122.176.213";
  ok $result->faker->random->pick; # reset randomizer
  is $result->execute, "147.136.6.197";

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

  use Faker::Plugin::InternetIpAddressV4;

  my $plugin = Faker::Plugin::InternetIpAddressV4->new;

  # bless(..., "Faker::Plugin::InternetIpAddressV4")

=cut

$test->for('example', 1, 'new', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  ok $result->isa('Faker::Plugin::InternetIpAddressV4');
  ok $result->faker;

  $result
});

# END

$test->render('lib/Faker/Plugin/InternetIpAddressV4.pod') if $ENV{RENDER};

ok 1 and done_testing;
