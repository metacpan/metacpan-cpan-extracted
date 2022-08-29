package main;

use 5.018;

use strict;
use warnings;

use Test::More;
use Venus::Test;

my $test = test(__FILE__);

=name

Faker::Plugin::EnUs

=cut

$test->for('name');

=tagline

En-Us Plugin Superclass

=cut

$test->for('tagline');

=abstract

Fake Data Plugin Superclass (En-Us)

=cut

$test->for('abstract');

=includes

method: new

=cut

$test->for('includes');

=synopsis

  package main;

  use Faker::Plugin::EnUs;

  my $plugin = Faker::Plugin::EnUs->new;

  # bless(..., "Faker::Plugin::EnUs")

  # my $result = $plugin->execute;

  # ""

=cut

$test->for('synopsis', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  ok $result->isa('Faker::Plugin::EnUs');

  $result
});

=description

This package provides a superclass for en-us based plugins.

+=encoding utf8

=cut

$test->for('description');

=inherits

Faker::Plugin

=cut

$test->for('inherits');

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

  use Faker::Plugin::EnUs;

  my $plugin = Faker::Plugin::EnUs->new;

  # bless(..., "Faker::Plugin::EnUs")

=cut

$test->for('example', 1, 'new', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  ok $result->isa('Faker::Plugin::EnUs');
  ok $result->faker;
  is $result->faker->locales->count, 1;
  is $result->faker->locales->first, 'en-us';

  $result
});

=example-2 new

  package main;

  use Faker::Plugin::EnUs;

  my $plugin = Faker::Plugin::EnUs->new({faker => 'ru-ru'});

  # bless(..., "Faker::Plugin::EnUs")

=cut

$test->for('example', 2, 'new', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  ok $result->isa('Faker::Plugin');
  ok $result->faker;
  is $result->faker->locales->count, 1;
  is $result->faker->locales->first, 'en-us';

  $result
});

=example-3 new

  package main;

  use Faker::Plugin::EnUs;

  my $plugin = Faker::Plugin::EnUs->new({faker => ['ru-ru', 'sk-sk']});

  # bless(..., "Faker::Plugin::EnUs")

=cut

$test->for('example', 3, 'new', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  ok $result->isa('Faker::Plugin');
  ok $result->faker;
  is $result->faker->locales->count, 1;
  is $result->faker->locales->first, 'en-us';

  $result
});

=feature subclass-feature

This package is meant to be subclassed.

=cut

=example-1 subclass-feature

  package Faker::Plugin::EnUs::UserHandle;

  use base 'Faker::Plugin::EnUs';

  sub execute {
    my ($self) = @_;

    return $self->process('@?{{person_last_name}}####');
  }

  package main;

  use Faker;

  my $faker = Faker->new('en-us');

  # bless(..., "Faker")

  my $result = $faker->user_handle;

  # "\@jWolf2469"

=cut

$test->for('example', 1, 'subclass-feature', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;

  $result
});

# END

$test->render('lib/Faker/Plugin/EnUs.pod') if $ENV{RENDER};

ok 1 and done_testing;
