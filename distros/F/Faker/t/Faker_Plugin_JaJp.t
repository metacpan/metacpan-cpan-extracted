package main;

use 5.018;

use strict;
use warnings;

use Test::More;
use Venus::Test;

my $test = test(__FILE__);

=name

Faker::Plugin::JaJp

=cut

$test->for('name');

=tagline

Ja-Jp Plugin Superclass

=cut

$test->for('tagline');

=abstract

Fake Data Plugin Superclass (Ja-Jp)

=cut

$test->for('abstract');

=includes

method: new

=cut

$test->for('includes');

=synopsis

  package main;

  use Faker::Plugin::JaJp;

  my $plugin = Faker::Plugin::JaJp->new;

  # bless(..., "Faker::Plugin::JaJp")

  # my $result = $plugin->execute;

  # ""

=cut

$test->for('synopsis', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  ok $result->isa('Faker::Plugin::JaJp');

  $result
});

=description

This package provides a superclass for ja-jp based plugins.

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

  use Faker::Plugin::JaJp;

  my $plugin = Faker::Plugin::JaJp->new;

  # bless(..., "Faker::Plugin::JaJp")

=cut

$test->for('example', 1, 'new', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  ok $result->isa('Faker::Plugin::JaJp');
  ok $result->faker;
  is $result->faker->locales->count, 1;
  is $result->faker->locales->first, 'ja-jp';

  $result
});

=example-2 new

  package main;

  use Faker::Plugin::JaJp;

  my $plugin = Faker::Plugin::JaJp->new({faker => 'ru-ru'});

  # bless(..., "Faker::Plugin::JaJp")

=cut

$test->for('example', 2, 'new', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  ok $result->isa('Faker::Plugin');
  ok $result->faker;
  is $result->faker->locales->count, 1;
  is $result->faker->locales->first, 'ja-jp';

  $result
});

=example-3 new

  package main;

  use Faker::Plugin::JaJp;

  my $plugin = Faker::Plugin::JaJp->new({faker => ['ru-ru', 'sk-sk']});

  # bless(..., "Faker::Plugin::JaJp")

=cut

$test->for('example', 3, 'new', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  ok $result->isa('Faker::Plugin');
  ok $result->faker;
  is $result->faker->locales->count, 1;
  is $result->faker->locales->first, 'ja-jp';

  $result
});

=feature subclass-feature

This package is meant to be subclassed.

=cut

=example-1 subclass-feature

  package Faker::Plugin::JaJp::UserHandle;

  use base 'Faker::Plugin::JaJp';

  sub execute {
    my ($self) = @_;

    return $self->process('@?{{person_last_name_ascii}}####');
  }

  package main;

  use Faker;

  my $faker = Faker->new('ja-jp');

  # bless(..., "Faker")

  my $result = $faker->user_handle;

  # "\@qkudo7078"

=cut

$test->for('example', 1, 'subclass-feature', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;

  $result
});

=partials

t/Faker.t: pdml: authors
t/Faker.t: pdml: license

=cut

$test->for('partials');

# END

$test->render('lib/Faker/Plugin/JaJp.pod') if $ENV{RENDER};

ok 1 and done_testing;
