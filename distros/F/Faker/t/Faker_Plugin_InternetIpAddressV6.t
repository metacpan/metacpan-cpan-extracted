package main;

use 5.018;

use strict;
use warnings;

use Test::More;
use Venus::Test;

my $test = test(__FILE__);
my $seed = 42;

=name

Faker::Plugin::InternetIpAddressV6

=cut

$test->for('name');

=tagline

Internet Ip Address V6

=cut

$test->for('tagline');

=abstract

Internet Ip Address V6 for Faker

=cut

$test->for('abstract');

=includes

method: new
method: execute

=cut

$test->for('includes');

=synopsis

  package main;

  use Faker::Plugin::InternetIpAddressV6;

  my $plugin = Faker::Plugin::InternetIpAddressV6->new;

  # bless(..., "Faker::Plugin::InternetIpAddressV6")

=cut

$test->for('synopsis', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  ok $result->isa('Faker::Plugin::InternetIpAddressV6');

  $result
});

=description

This package provides methods for generating fake data for internet ip address v6.

+=encoding utf8

=cut

$test->for('description');

=inherits

Faker::Plugin

=cut

$test->for('inherits');

=method execute

The execute method returns a returns a random fake internet ip address v6.

=signature execute

  execute(HashRef $data) (Str)

=metadata execute

{
  since => '1.10',
}

=example-1 execute

  package main;

  use Faker::Plugin::InternetIpAddressV6;

  my $plugin = Faker::Plugin::InternetIpAddressV6->new;

  # bless(..., "Faker::Plugin::InternetIpAddressV6")

  # my $result = $plugin->execute;

  # "57bb:1c70:6c1e:14c3:db3f:7fb1:7a93:b0d9";

  # my $result = $plugin->execute;

  # "7680:93e0:88b2:06a0:c512:99e4:e8a9:7d48";

  # my $result = $plugin->execute;

  # "7f27:7009:5984:ec03:0f75:dc22:f8d4:d951";

=cut

$test->for('example', 1, 'execute', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  ok $result->isa('Faker::Plugin::InternetIpAddressV6');
  ok $result->faker;
  ok $result->faker->random->reseed($seed);
  ok $result->faker->random->make; # reset randomizer
  is $result->execute, "57bb:1c70:6c1e:14c3:db3f:7fb1:7a93:b0d9";
  ok $result->faker->random->make; # reset randomizer
  is $result->execute, "7680:93e0:88b2:06a0:c512:99e4:e8a9:7d48";
  ok $result->faker->random->make; # reset randomizer
  is $result->execute, "7f27:7009:5984:ec03:0f75:dc22:f8d4:d951";

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

  use Faker::Plugin::InternetIpAddressV6;

  my $plugin = Faker::Plugin::InternetIpAddressV6->new;

  # bless(..., "Faker::Plugin::InternetIpAddressV6")

=cut

$test->for('example', 1, 'new', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  ok $result->isa('Faker::Plugin::InternetIpAddressV6');
  ok $result->faker;

  $result
});

# END

$test->render('lib/Faker/Plugin/InternetIpAddressV6.pod') if $ENV{RENDER};

ok 1 and done_testing;
