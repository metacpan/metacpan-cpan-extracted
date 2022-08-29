package main;

use 5.018;

use strict;
use warnings;

use Test::More;
use Venus::Test;

my $test = test(__FILE__);

=name

Faker::Plugin::EsEs

=cut

$test->for('name');

=tagline

Es-Es Plugin Superclass

=cut

$test->for('tagline');

=abstract

Fake Data Plugin Superclass (Es-Es)

=cut

$test->for('abstract');

=includes

method: new

=cut

$test->for('includes');

=synopsis

  package main;

  use Faker::Plugin::EsEs;

  my $plugin = Faker::Plugin::EsEs->new;

  # bless(..., "Faker::Plugin::EsEs")

  # my $result = $plugin->execute;

  # ""

=cut

$test->for('synopsis', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  ok $result->isa('Faker::Plugin::EsEs');

  $result
});

=description

This package provides a superclass for es-es based plugins.

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

  use Faker::Plugin::EsEs;

  my $plugin = Faker::Plugin::EsEs->new;

  # bless(..., "Faker::Plugin::EsEs")

=cut

$test->for('example', 1, 'new', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  ok $result->isa('Faker::Plugin::EsEs');
  ok $result->faker;
  is $result->faker->locales->count, 1;
  is $result->faker->locales->first, 'es-es';

  $result
});

=example-2 new

  package main;

  use Faker::Plugin::EsEs;

  my $plugin = Faker::Plugin::EsEs->new({faker => 'ru-ru'});

  # bless(..., "Faker::Plugin::EsEs")

=cut

$test->for('example', 2, 'new', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  ok $result->isa('Faker::Plugin');
  ok $result->faker;
  is $result->faker->locales->count, 1;
  is $result->faker->locales->first, 'es-es';

  $result
});

=example-3 new

  package main;

  use Faker::Plugin::EsEs;

  my $plugin = Faker::Plugin::EsEs->new({faker => ['ru-ru', 'sk-sk']});

  # bless(..., "Faker::Plugin::EsEs")

=cut

$test->for('example', 3, 'new', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  ok $result->isa('Faker::Plugin');
  ok $result->faker;
  is $result->faker->locales->count, 1;
  is $result->faker->locales->first, 'es-es';

  $result
});

=feature subclass-feature

This package is meant to be subclassed.

=cut

=example-1 subclass-feature

  package Faker::Plugin::EsEs::UserHandle;

  use base 'Faker::Plugin::EsEs';

  sub execute {
    my ($self) = @_;

    return $self->process('@?{{person_last_name}}####');
  }

  package main;

  use Faker;

  my $faker = Faker->new('es-es');

  # bless(..., "Faker")

  my $result = $faker->user_handle;

  # "\@CJaimes9397"

=cut

$test->for('example', 1, 'subclass-feature', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;

  $result
});

# END

$test->render('lib/Faker/Plugin/EsEs.pod') if $ENV{RENDER};

ok 1 and done_testing;
