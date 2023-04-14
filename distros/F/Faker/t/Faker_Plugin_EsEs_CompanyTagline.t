package main;

use 5.018;

use strict;
use warnings;

use Test::More;
use Venus::Test;

my $test = test(__FILE__);
my $seed = 42;

=name

Faker::Plugin::EsEs::CompanyTagline

=cut

$test->for('name');

=tagline

Company Tagline

=cut

$test->for('tagline');

=abstract

Company Tagline for Faker

=cut

$test->for('abstract');

=includes

method: new
method: execute

=cut

$test->for('includes');

=synopsis

  package main;

  use Faker::Plugin::EsEs::CompanyTagline;

  my $plugin = Faker::Plugin::EsEs::CompanyTagline->new;

  # bless(..., "Faker::Plugin::EsEs::CompanyTagline")

=cut

$test->for('synopsis', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  ok $result->isa('Faker::Plugin::EsEs::CompanyTagline');

  $result
});

=description

This package provides methods for generating fake data for company tagline.

+=encoding utf8

=cut

$test->for('description');

=inherits

Faker::Plugin::EsEs

=cut

$test->for('inherits');

=method execute

The execute method returns a returns a random fake company tagline.

=signature execute

  execute(HashRef $data) (Str)

=metadata execute

{
  since => '1.10',
}

=example-1 execute

  package main;

  use Faker::Plugin::EsEs::CompanyTagline;

  my $plugin = Faker::Plugin::EsEs::CompanyTagline->new;

  # bless(..., "Faker::Plugin::EsEs::CompanyTagline")

  # my $result = $plugin->execute;

  # 'transform revolutionary supply-chains';

  # my $result = $plugin->execute;

  # 'generate front-end web-readiness';

  # my $result = $plugin->execute;

  # 'iterate back-end content';

=cut

$test->for('example', 1, 'execute', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  ok $result->isa('Faker::Plugin::EsEs::CompanyTagline');
  ok $result->faker;
  ok $result->faker->random->reseed($seed);
  ok $result->faker->random->pick; # reset randomizer
  is $result->execute, 'transform revolutionary supply-chains';
  ok $result->faker->random->pick; # reset randomizer
  is $result->execute, 'generate front-end web-readiness';
  ok $result->faker->random->pick; # reset randomizer
  is $result->execute, 'iterate back-end content';

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

  use Faker::Plugin::EsEs::CompanyTagline;

  my $plugin = Faker::Plugin::EsEs::CompanyTagline->new;

  # bless(..., "Faker::Plugin::EsEs::CompanyTagline")

=cut

$test->for('example', 1, 'new', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  ok $result->isa('Faker::Plugin::EsEs::CompanyTagline');
  ok $result->faker;

  $result
});

=partials

t/Faker.t: pdml: authors
t/Faker.t: pdml: license

=cut

$test->for('partials');

# END

$test->render('lib/Faker/Plugin/EsEs/CompanyTagline.pod') if $ENV{RENDER};

ok 1 and done_testing;
