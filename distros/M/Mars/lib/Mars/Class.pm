package Mars::Class;

use 5.018;

use strict;
use warnings;

# IMPORT

sub import {
  my ($self, @args) = @_;

  my $from = caller;

  require Mars::Kind::Class;

  no strict 'refs';
  no warnings 'redefine';
  no warnings 'once';

  @{"${from}::ISA"} = 'Mars::Kind::Class';

  if (!*{"${from}::attr"}{"CODE"}) {
    *{"${from}::attr"} = sub {@_ = ($from, @_); goto \&attr};
  }
  if (!*{"${from}::base"}{"CODE"}) {
    *{"${from}::base"} = sub {@_ = ($from, @_); goto \&base};
  }
  if (!*{"${from}::false"}{"CODE"}) {
    *{"${from}::false"} = sub {require Mars; Mars::false()};
  }
  if (!*{"${from}::role"}{"CODE"}) {
    *{"${from}::role"} = sub {@_ = ($from, @_); goto \&role};
  }
  if (!*{"${from}::test"}{"CODE"}) {
    *{"${from}::test"} = sub {@_ = ($from, @_); goto \&test};
  }
  if (!*{"${from}::true"}{"CODE"}) {
    *{"${from}::true"} = sub {require Mars; Mars::true()};
  }
  if (!*{"${from}::with"}{"CODE"}) {
    *{"${from}::with"} = sub {@_ = ($from, @_); goto \&role};
  }

  ${"${from}::META"} = {};

  return $self;
}

sub attr {
  my ($from, @args) = @_;

  $from->ATTR(@args);

  return $from;
}

sub base {
  my ($from, @args) = @_;

  $from->BASE(@args);

  return $from;
}

sub role {
  my ($from, @args) = @_;

  $from->ROLE(@args);

  return $from;
}

sub test {
  my ($from, @args) = @_;

  $from->TEST(@args);

  return $from;
}

1;



=head1 NAME

Mars::Class - Class Declaration

=cut

=head1 ABSTRACT

Class Declaration for Perl 5

=cut

=head1 SYNOPSIS

  package Person;

  use Mars::Class;

  attr 'fname';
  attr 'lname';

  package Identity;

  use Mars::Role;

  attr 'id';
  attr 'login';
  attr 'password';

  sub EXPORT {
    # explicitly declare routines to be consumed
    return ['id', 'login', 'password'];
  }

  package Authenticable;

  use Mars::Role;

  sub authenticate {
    return true;
  }

  sub AUDIT {
    my ($self, $from) = @_;
    die "${from} missing Identity role" if !$from->does('Identity');
  }

  sub EXPORT {
    # explicitly declare routines to be consumed
    return ['authenticate'];
  }

  package User;

  use Mars::Class;

  base 'Person';
  with 'Identity';

  attr 'email';

  test 'Authenticable';

  sub valid {
    my ($self) = @_;
    return $self->login && $self->password ? true : false;
  }

  package main;

  my $user = User->new(
    fname => 'Elliot',
    lname => 'Alderson',
  );

  # bless({fname => 'Elliot', lname => 'Alderson'}, 'User')

=cut

=head1 DESCRIPTION

This package provides a class builder which when used causes the consumer to
inherit from L<Mars::Kind::Class> which provides object construction and
lifecycle L<hooks|Mars::Kind>.

=cut

=head1 FUNCTIONS

This package provides the following functions:

=cut

=head2 attr

  attr(Str $name) (Str)

The attr function creates attribute accessors for the calling package. This
function is always exported unless a routine of the same name already exists.

I<Since C<0.01>>

=over 4

=item attr example 1

  package Example;

  use Mars::Class;

  attr 'name';

  # "Example"

=back

=cut

=head2 base

  base(Str $name) (Str)

The base function registers one or more base classes for the calling package.
This function is always exported unless a routine of the same name already
exists.

I<Since C<0.01>>

=over 4

=item base example 1

  package Entity;

  use Mars::Class;

  sub output {
    return;
  }

  package Example;

  use Mars::Class;

  base 'Entity';

  # "Example"

=back

=cut

=head2 false

  false() (Bool)

The false function returns a falsy boolean value which is designed to be
practically indistinguishable from the conventional numerical C<0> value. This
function is always exported unless a routine of the same name already exists.

I<Since C<0.01>>

=over 4

=item false example 1

  package Example;

  use Mars::Class;

  my $false = false;

  # 0

=back

=over 4

=item false example 2

  package Example;

  use Mars::Class;

  my $true = !false;

  # 1

=back

=cut

=head2 role

  role(Str $name) (Str)

The role function registers and consumes roles for the calling package. This
function is always exported unless a routine of the same name already exists.

I<Since C<0.01>>

=over 4

=item role example 1

  package Ability;

  use Mars::Role;

  sub action {
    return;
  }

  package Example;

  use Mars::Class;

  role 'Ability';

  # "Example"

=back

=over 4

=item role example 2

  package Ability;

  use Mars::Role;

  sub action {
    return;
  }

  sub EXPORT {
    return ['action'];
  }

  package Example;

  use Mars::Class;

  role 'Ability';

  # "Example"

=back

=cut

=head2 test

  test(Str $name) (Str)

The test function registers and consumes roles for the calling package and
performs an L<"audit"|Mars::Kind/AUDIT>, effectively allowing a role to act as
an interface. This function is always exported unless a routine of the same
name already exists.

I<Since C<0.01>>

=over 4

=item test example 1

  package Actual;

  use Mars::Role;

  package Example;

  use Mars::Class;

  test 'Actual';

  # "Example"

=back

=over 4

=item test example 2

  package Actual;

  use Mars::Role;

  sub AUDIT {
    die "Example is not an 'actual' thing" if $_[1]->isa('Example');
  }

  package Example;

  use Mars::Class;

  test 'Actual';

  # "Example"

=back

=cut

=head2 true

  true() (Bool)

The true function returns a truthy boolean value which is designed to be
practically indistinguishable from the conventional numerical C<1> value. This
function is always exported unless a routine of the same name already exists.

I<Since C<0.01>>

=over 4

=item true example 1

  package Example;

  use Mars::Class;

  my $true = true;

  # 1

=back

=over 4

=item true example 2

  package Example;

  use Mars::Class;

  my $false = !true;

  # 0

=back

=cut

=head2 with

  with(Str $name) (Str)

The with function registers and consumes roles for the calling package. This
function is an alias of the L</role> function. This function is always exported
unless a routine of the same name already exists.

I<Since C<0.01>>

=over 4

=item with example 1

  package Understanding;

  use Mars::Role;

  sub knowledge {
    return;
  }

  package Example;

  use Mars::Class;

  with 'Understanding';

  # "Example"

=back

=over 4

=item with example 2

  package Understanding;

  use Mars::Role;

  sub knowledge {
    return;
  }

  sub EXPORT {
    return ['knowledge'];
  }

  package Example;

  use Mars::Class;

  with 'Understanding';

  # "Example"

=back

=cut

=head1 AUTHORS

Awncorp, C<awncorp@cpan.org>

=cut