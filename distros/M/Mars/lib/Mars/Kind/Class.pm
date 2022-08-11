package Mars::Kind::Class;

use 5.018;

use strict;
use warnings;

use base 'Mars::Kind';

# METHODS

sub BUILD {
  my ($self, @data) = @_;

  no strict 'refs';

  my @roles = @{$self->META->roles};

  for my $action (grep defined, map *{"${_}::BUILD"}{"CODE"}, @roles) {
    $self->$action(@data);
  }

  return $self;
}

sub DESTROY {
  my ($self, @data) = @_;

  no strict 'refs';

  my @roles = @{$self->META->roles};

  for my $action (grep defined, map *{"${_}::DESTROY"}{"CODE"}, @roles) {
    $self->$action(@data);
  }

  return $self;
}

sub does {
  my ($self, @args) = @_;

  return $self->DOES(@args);
}

sub meta {
  my ($self) = @_;

  return $self->META;
}

sub new {
  my ($self, @args) = @_;

  return $self->BLESS(@args);
}

1;



=head1 NAME

Mars::Kind::Class - Class Base Class

=cut

=head1 ABSTRACT

Class Base Class for Perl 5

=cut

=head1 SYNOPSIS

  package User;

  use base 'Mars::Kind::Class';

  package main;

  my $user = User->new(
    fname => 'Elliot',
    lname => 'Alderson',
  );

  # bless({fname => 'Elliot', lname => 'Alderson'}, 'User')

=cut

=head1 DESCRIPTION

This package provides a class base class with class building and object
construction lifecycle hooks.

=cut

=head1 INHERITS

This package inherits behaviors from:

L<Mars::Kind>

=cut

=head1 METHODS

This package provides the following methods:

=cut

=head2 does

  does(Str $name) (Bool)

The does method returns true if the object is composed of the role provided.

I<Since C<0.01>>

=over 4

=item does example 1

  # given: synopsis

  my $does = $user->does('Identity');

  # 0

=back

=cut

=head2 meta

  meta() (Meta)

The meta method returns a L<Mars::Meta> objects which describes the package's
configuration.

I<Since C<0.01>>

=over 4

=item meta example 1

  # given: synopsis

  package main;

  my $user = User->new(
    fname => 'Elliot',
    lname => 'Alderson',
  );

  my $meta = $user->meta;

  # bless({...}, 'Mars::Meta')

=back

=cut

=head2 new

  new(Any %args | HashRef $args) (Object)

The new method instantiates the class and returns a new object.

I<Since C<0.01>>

=over 4

=item new example 1

  package main;

  my $user = User->new(
    fname => 'Elliot',
    lname => 'Alderson',
  );

  # bless({fname => 'Elliot', lname => 'Alderson'}, 'User')

=back

=over 4

=item new example 2

  package main;

  my $user = User->new({
    fname => 'Elliot',
    lname => 'Alderson',
  });

  # bless({fname => 'Elliot', lname => 'Alderson'}, 'User')

=back

=cut

=head1 AUTHORS

Awncorp, C<awncorp@cpan.org>

=cut