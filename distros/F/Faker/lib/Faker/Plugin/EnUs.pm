package Faker::Plugin::EnUs;

use 5.018;

use strict;
use warnings;

use Venus::Class 'base';

base 'Faker::Plugin';

# VERSION

our $VERSION = '1.17';

# MODIFIERS

sub new {
  my ($self, @args) = @_;

  $self = $self->SUPER::new(@args);

  require Faker;

  my $caches = $self->faker->caches;

  $self->faker(Faker->new('en-us'));

  $self->faker->caches($caches) if $caches->count;

  return $self;
}

1;



=head1 NAME

Faker::Plugin::EnUs - En-Us Plugin Superclass

=cut

=head1 ABSTRACT

Fake Data Plugin Superclass (En-Us)

=cut

=head1 VERSION

1.17

=cut

=head1 SYNOPSIS

  package main;

  use Faker::Plugin::EnUs;

  my $plugin = Faker::Plugin::EnUs->new;

  # bless(..., "Faker::Plugin::EnUs")

  # my $result = $plugin->execute;

  # ""

=cut

=head1 DESCRIPTION

This package provides a superclass for en-us based plugins.

=encoding utf8

=cut

=head1 INHERITS

This package inherits behaviors from:

L<Faker::Plugin>

=cut

=head1 METHODS

This package provides the following methods:

=cut

=head2 new

  new(HashRef $data) (Plugin)

The new method returns a new instance of the class.

I<Since C<1.10>>

=over 4

=item new example 1

  package main;

  use Faker::Plugin::EnUs;

  my $plugin = Faker::Plugin::EnUs->new;

  # bless(..., "Faker::Plugin::EnUs")

=back

=over 4

=item new example 2

  package main;

  use Faker::Plugin::EnUs;

  my $plugin = Faker::Plugin::EnUs->new({faker => 'ru-ru'});

  # bless(..., "Faker::Plugin::EnUs")

=back

=over 4

=item new example 3

  package main;

  use Faker::Plugin::EnUs;

  my $plugin = Faker::Plugin::EnUs->new({faker => ['ru-ru', 'sk-sk']});

  # bless(..., "Faker::Plugin::EnUs")

=back

=cut

=head1 FEATURES

This package provides the following features:

=cut

=over 4

=item subclass-feature

This package is meant to be subclassed.

B<example 1>

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

=back