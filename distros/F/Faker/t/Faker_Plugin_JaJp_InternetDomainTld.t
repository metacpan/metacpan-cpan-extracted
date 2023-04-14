package main;

use 5.018;

use strict;
use warnings;

use Test::More;
use Venus::Test;

my $test = test(__FILE__);
my $seed = 42;

=name

Faker::Plugin::JaJp::InternetDomainTld

=cut

$test->for('name');

=tagline

Internet Domain Tld

=cut

$test->for('tagline');

=abstract

Internet Domain Tld for Faker

=cut

$test->for('abstract');

=includes

method: new
method: execute

=cut

$test->for('includes');

=synopsis

  package main;

  use Faker::Plugin::JaJp::InternetDomainTld;

  my $plugin = Faker::Plugin::JaJp::InternetDomainTld->new;

  # bless(..., "Faker::Plugin::JaJp::InternetDomainTld")

=cut

$test->for('synopsis', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  ok $result->isa('Faker::Plugin::JaJp::InternetDomainTld');

  $result
});

=description

This package provides methods for generating fake data for internet domain tld.

+=encoding utf8

=cut

$test->for('description');

=inherits

Faker::Plugin::JaJp

=cut

$test->for('inherits');

=method execute

The execute method returns a returns a random fake internet domain tld.

=signature execute

  execute(HashRef $data) (Str)

=metadata execute

{
  since => '1.10',
}

=example-1 execute

  package main;

  use Faker::Plugin::JaJp::InternetDomainTld;

  my $plugin = Faker::Plugin::JaJp::InternetDomainTld->new;

  # bless(..., "Faker::Plugin::JaJp::InternetDomainTld")

  # my $result = $plugin->execute;

  # 'biz';

  # my $result = $plugin->execute;

  # 'info';

  # my $result = $plugin->execute;

  # 'jp';

=cut

$test->for('example', 1, 'execute', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  ok $result->isa('Faker::Plugin::JaJp::InternetDomainTld');
  ok $result->faker;
  ok $result->faker->random->reseed($seed);
  ok $result->faker->random->pick; # reset randomizer
  is $result->execute, 'biz';
  ok $result->faker->random->pick; # reset randomizer
  is $result->execute, 'info';
  ok $result->faker->random->pick; # reset randomizer
  is $result->execute, 'jp';

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

  use Faker::Plugin::JaJp::InternetDomainTld;

  my $plugin = Faker::Plugin::JaJp::InternetDomainTld->new;

  # bless(..., "Faker::Plugin::JaJp::InternetDomainTld")

=cut

$test->for('example', 1, 'new', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  ok $result->isa('Faker::Plugin::JaJp::InternetDomainTld');
  ok $result->faker;

  $result
});

=partials

t/Faker.t: pdml: authors
t/Faker.t: pdml: license

=cut

$test->for('partials');

# END

$test->render('lib/Faker/Plugin/JaJp/InternetDomainTld.pod') if $ENV{RENDER};

ok 1 and done_testing;
