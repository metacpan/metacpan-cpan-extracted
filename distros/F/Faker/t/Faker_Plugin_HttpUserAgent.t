package main;

use 5.018;

use strict;
use warnings;

use Test::More;
use Venus::Test;

my $test = test(__FILE__);
my $seed = 42;

=name

Faker::Plugin::HttpUserAgent

=cut

$test->for('name');

=tagline

HTTP User-Agent

=cut

$test->for('tagline');

=abstract

HTTP User-Agent for Faker

=cut

$test->for('abstract');

=includes

method: new
method: execute

=cut

$test->for('includes');

=synopsis

  package main;

  use Faker::Plugin::HttpUserAgent;

  my $plugin = Faker::Plugin::HttpUserAgent->new;

  # bless(..., "Faker::Plugin::HttpUserAgent")

=cut

$test->for('synopsis', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  ok $result->isa('Faker::Plugin::HttpUserAgent');

  $result
});

=description

This package provides methods for generating fake data for HTTP user-agents.

+=encoding utf8

=cut

$test->for('description');

=inherits

Faker::Plugin

=cut

$test->for('inherits');

=method execute

The execute method returns a returns a random fake HTTP user-agent.

=signature execute

  execute(HashRef $data) (Str)

=metadata execute

{
  since => '1.17',
}

=example-1 execute

  package main;

  use Faker::Plugin::HttpUserAgent;

  my $plugin = Faker::Plugin::HttpUserAgent->new;

  # bless(..., "Faker::Plugin::HttpUserAgent")

  # my $result = $plugin->execute;

  # "Mozilla/6.1 (Windows; U; Windows NT 07.6; rv:0.4.5) ... Windows Firefox/4.4.3";

  # my $result = $plugin->execute;

  # "Mozilla/5.8 (Macintosh; U; Mac OS 58.2; rv:0.02) ... Macintosh Safari/0.5";

  # my $result = $plugin->execute;

  # "Mozilla/9.9 (Macintosh; U; Mac OS 58.9; rv:1.25) ... Macintosh Safari/0.6";

=cut

$test->for('example', 1, 'execute', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  ok $result->isa('Faker::Plugin::HttpUserAgent');
  ok $result->faker;
  ok $result->faker->random->reseed($seed);
  ok $result->faker->random->pick; # reset randomizer
  is $result->execute, 'Mozilla/6.1 (Windows; U; Windows NT 07.6; rv:0.4.5) Gecko/20110124 Windows Firefox/4.4.3';
  ok $result->faker->random->pick; # reset randomizer
  is $result->execute, 'Mozilla/5.8 (Macintosh; U; Mac OS 58.2; rv:0.02) Gecko/20231108 Macintosh Safari/0.5';
  ok $result->faker->random->pick; # reset randomizer
  is $result->execute, 'Mozilla/9.9 (Macintosh; U; Mac OS 58.9; rv:1.25) Gecko/20050715 Macintosh Safari/0.6';

  $result
});

=method new

The new method returns a new instance of the class.

=signature new

  new(HashRef $data) (Plugin)

=metadata new

{
  since => '1.17',
}

=example-1 new

  package main;

  use Faker::Plugin::HttpUserAgent;

  my $plugin = Faker::Plugin::HttpUserAgent->new;

  # bless(..., "Faker::Plugin::HttpUserAgent")

=cut

$test->for('example', 1, 'new', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  ok $result->isa('Faker::Plugin::HttpUserAgent');
  ok $result->faker;

  $result
});

=partials

t/Faker.t: pdml: authors
t/Faker.t: pdml: license

=cut

$test->for('partials');

# END

$test->render('lib/Faker/Plugin/HttpUserAgent.pod') if $ENV{RENDER};

ok 1 and done_testing;
