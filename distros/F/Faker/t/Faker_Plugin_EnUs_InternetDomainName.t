package main;

use 5.018;

use strict;
use warnings;

use Test::More;
use Venus::Test;

my $test = test(__FILE__);
my $seed = 42;

=name

Faker::Plugin::EnUs::InternetDomainName

=cut

$test->for('name');

=tagline

Internet Domain Name

=cut

$test->for('tagline');

=abstract

Internet Domain Name for Faker

=cut

$test->for('abstract');

=includes

method: new
method: execute

=cut

$test->for('includes');

=synopsis

  package main;

  use Faker::Plugin::EnUs::InternetDomainName;

  my $plugin = Faker::Plugin::EnUs::InternetDomainName->new;

  # bless(..., "Faker::Plugin::EnUs::InternetDomainName")

=cut

$test->for('synopsis', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  ok $result->isa('Faker::Plugin::EnUs::InternetDomainName');

  $result
});

=description

This package provides methods for generating fake data for internet domain name.

+=encoding utf8

=cut

$test->for('description');

=inherits

Faker::Plugin::EnUs

=cut

$test->for('inherits');

=method execute

The execute method returns a returns a random fake internet domain name.

=signature execute

  execute(HashRef $data) (Str)

=metadata execute

{
  since => '1.10',
}

=example-1 execute

  package main;

  use Faker::Plugin::EnUs::InternetDomainName;

  my $plugin = Faker::Plugin::EnUs::InternetDomainName->new;

  # bless(..., "Faker::Plugin::EnUs::InternetDomainName")

  # my $result = $plugin->execute;

  # "steuber-krajcik.org";

  # my $result = $plugin->execute;

  # "miller-and-sons.com";

  # my $result = $plugin->execute;

  # "witting-entertainment.com";

=cut

$test->for('example', 1, 'execute', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  ok $result->isa('Faker::Plugin::EnUs::InternetDomainName');
  ok $result->faker;
  ok $result->faker->random->reseed($seed);
  ok $result->faker->random->pick; # reset randomizer
  is $result->execute, "steuber-krajcik.org";
  ok $result->faker->random->pick; # reset randomizer
  is $result->execute, "miller-and-sons.com";
  ok $result->faker->random->pick; # reset randomizer
  is $result->execute, "witting-entertainment.com";

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

  use Faker::Plugin::EnUs::InternetDomainName;

  my $plugin = Faker::Plugin::EnUs::InternetDomainName->new;

  # bless(..., "Faker::Plugin::EnUs::InternetDomainName")

=cut

$test->for('example', 1, 'new', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  ok $result->isa('Faker::Plugin::EnUs::InternetDomainName');
  ok $result->faker;

  $result
});

=partials

t/Faker.t: pdml: authors
t/Faker.t: pdml: license

=cut

$test->for('partials');

# END

$test->render('lib/Faker/Plugin/EnUs/InternetDomainName.pod') if $ENV{RENDER};

ok 1 and done_testing;
