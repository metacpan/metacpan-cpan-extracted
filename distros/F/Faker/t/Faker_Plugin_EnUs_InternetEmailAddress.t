package main;

use 5.018;

use strict;
use warnings;

use Test::More;
use Venus::Test;

my $test = test(__FILE__);
my $seed = 42;

=name

Faker::Plugin::EnUs::InternetEmailAddress

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

  use Faker::Plugin::EnUs::InternetEmailAddress;

  my $plugin = Faker::Plugin::EnUs::InternetEmailAddress->new;

  # bless(..., "Faker::Plugin::EnUs::InternetEmailAddress")

=cut

$test->for('synopsis', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  ok $result->isa('Faker::Plugin::EnUs::InternetEmailAddress');

  $result
});

=description

This package provides methods for generating fake data for internet email address.

+=encoding utf8

=cut

$test->for('description');

=inherits

Faker::Plugin::EnUs

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

  use Faker::Plugin::EnUs::InternetEmailAddress;

  my $plugin = Faker::Plugin::EnUs::InternetEmailAddress->new;

  # bless(..., "Faker::Plugin::EnUs::InternetEmailAddress")

  # my $result = $plugin->execute;

  # "russel54\@mayer-balistreri-and-miller.com";

  # my $result = $plugin->execute;

  # "viviane82\@rempel-entertainment.com";

  # my $result = $plugin->execute;

  # "yborer\@outlook.com";

=cut

$test->for('example', 1, 'execute', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  ok $result->isa('Faker::Plugin::EnUs::InternetEmailAddress');
  ok $result->faker;
  ok $result->faker->random->reseed($seed);
  ok $result->faker->random->pick; # reset randomizer
  is $result->execute, "russel54\@mayer-balistreri-and-miller.com";
  ok $result->faker->random->pick; # reset randomizer
  is $result->execute, "viviane82\@rempel-entertainment.com";
  ok $result->faker->random->pick; # reset randomizer
  is $result->execute, "yborer\@outlook.com";

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

  use Faker::Plugin::EnUs::InternetEmailAddress;

  my $plugin = Faker::Plugin::EnUs::InternetEmailAddress->new;

  # bless(..., "Faker::Plugin::EnUs::InternetEmailAddress")

=cut

$test->for('example', 1, 'new', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  ok $result->isa('Faker::Plugin::EnUs::InternetEmailAddress');
  ok $result->faker;

  $result
});

=partials

t/Faker.t: pdml: authors
t/Faker.t: pdml: license

=cut

$test->for('partials');

# END

$test->render('lib/Faker/Plugin/EnUs/InternetEmailAddress.pod') if $ENV{RENDER};

ok 1 and done_testing;
