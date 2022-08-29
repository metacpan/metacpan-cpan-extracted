package main;

use 5.018;

use strict;
use warnings;

use Test::More;
use Venus::Test;

my $test = test(__FILE__);
my $seed = 42;

=name

Faker::Plugin::EnUs::InternetEmailDomain

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

  use Faker::Plugin::EnUs::InternetEmailDomain;

  my $plugin = Faker::Plugin::EnUs::InternetEmailDomain->new;

  # bless(..., "Faker::Plugin::EnUs::InternetEmailDomain")

=cut

$test->for('synopsis', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  ok $result->isa('Faker::Plugin::EnUs::InternetEmailDomain');

  $result
});

=description

This package provides methods for generating fake data for internet email domain.

+=encoding utf8

=cut

$test->for('description');

=inherits

Faker::Plugin::EnUs

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

  use Faker::Plugin::EnUs::InternetEmailDomain;

  my $plugin = Faker::Plugin::EnUs::InternetEmailDomain->new;

  # bless(..., "Faker::Plugin::EnUs::InternetEmailDomain")

  # my $result = $plugin->execute;

  # "icloud.com";

  # my $result = $plugin->execute;

  # "icloud.com";

  # my $result = $plugin->execute;

  # "yahoo.com";

=cut

$test->for('example', 1, 'execute', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  ok $result->isa('Faker::Plugin::EnUs::InternetEmailDomain');
  ok $result->faker;
  ok $result->faker->random->reseed($seed);
  ok $result->faker->random->make; # reset randomizer
  is $result->execute, "icloud.com";
  ok $result->faker->random->make; # reset randomizer
  is $result->execute, "icloud.com";
  ok $result->faker->random->make; # reset randomizer
  is $result->execute, "yahoo.com";

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

  use Faker::Plugin::EnUs::InternetEmailDomain;

  my $plugin = Faker::Plugin::EnUs::InternetEmailDomain->new;

  # bless(..., "Faker::Plugin::EnUs::InternetEmailDomain")

=cut

$test->for('example', 1, 'new', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  ok $result->isa('Faker::Plugin::EnUs::InternetEmailDomain');
  ok $result->faker;

  $result
});

# END

$test->render('lib/Faker/Plugin/EnUs/InternetEmailDomain.pod') if $ENV{RENDER};

ok 1 and done_testing;
