package Mars::Mixin;

use 5.018;

use strict;
use warnings;

# IMPORT

sub import {
  my ($self, @args) = @_;

  my $from = caller;

  require Mars::Kind::Mixin;

  no strict 'refs';
  no warnings 'redefine';
  no warnings 'once';

  my %exports = map +($_,$_), @args ? @args : qw(
    attr
    base
    false
    from
    mixin
    role
    test
    true
    with
  );

  @{"${from}::ISA"} = 'Mars::Kind::Mixin';

  if ($exports{"attr"} && !*{"${from}::attr"}{"CODE"}) {
    *{"${from}::attr"} = sub {@_ = ($from, @_); goto \&attr};
  }
  if ($exports{"base"} && !*{"${from}::base"}{"CODE"}) {
    *{"${from}::base"} = sub {@_ = ($from, @_); goto \&base};
  }
  if (!*{"${from}::false"}{"CODE"}) {
    *{"${from}::false"} = sub {require Mars; Mars::false()};
  }
  if ($exports{"from"} && !*{"${from}::from"}{"CODE"}) {
    *{"${from}::from"} = sub {@_ = ($from, @_); goto \&from};
  }
  if ($exports{"mixin"} && !*{"${from}::mixin"}{"CODE"}) {
    *{"${from}::mixin"} = sub {@_ = ($from, @_); goto \&mixin};
  }
  if ($exports{"role"} && !*{"${from}::role"}{"CODE"}) {
    *{"${from}::role"} = sub {@_ = ($from, @_); goto \&role};
  }
  if ($exports{"test"} && !*{"${from}::test"}{"CODE"}) {
    *{"${from}::test"} = sub {@_ = ($from, @_); goto \&test};
  }
  if (!*{"${from}::true"}{"CODE"}) {
    *{"${from}::true"} = sub {require Mars; Mars::true()};
  }
  if ($exports{"with"} && !*{"${from}::with"}{"CODE"}) {
    *{"${from}::with"} = sub {@_ = ($from, @_); goto \&test};
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

sub from {
  my ($from, @args) = @_;

  $from->FROM(@args);

  return $from;
}

sub mixin {
  my ($from, @args) = @_;

  $from->MIXIN(@args);

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

Mars::Mixin - Mixin Declaration

=cut

=head1 ABSTRACT

Mixin Declaration for Perl 5

=cut

=head1 SYNOPSIS

  package Person;

  use Mars::Class 'attr';

  attr 'fname';
  attr 'lname';

  package Identity;

  use Mars::Mixin 'attr';

  attr 'id';
  attr 'login';
  attr 'password';

  sub EXPORT {
    # explicitly declare routines to be consumed
    ['id', 'login', 'password']
  }

  package Authenticable;

  use Mars::Role;

  sub authenticate {
    return true;
  }

  sub AUDIT {
    my ($self, $from) = @_;
    # ensure the caller has a login and password when consumed
    die "${from} missing the login attribute" if !$from->can('login');
    die "${from} missing the password attribute" if !$from->can('password');
  }

  sub BUILD {
    my ($self, $data) = @_;
    $self->{auth} = undef;
    return $self;
  }

  sub EXPORT {
    # explicitly declare routines to be consumed
    ['authenticate']
  }

  package User;

  use Mars::Class;

  base 'Person';

  mixin 'Identity';

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

This package provides a mixin builder which when used causes the consumer to
inherit from L<Mars::Kind::Mixin> which provides mixin building and lifecycle
L<hooks|Mars::Kind>. A mixin can do almost everything that a role can do but
differs from a L<"role"|Mars::Role> in that whatever routines are declared
using L<"export"|Mars::Kind/EXPORT> will be exported and will overwrite
routines of the same name in the consumer.

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

=head2 from

  from(Str $name) (Str)

The from function registers one or more base classes for the calling package
and performs an L<"audit"|Mars::Kind/AUDIT>. This function is always exported
unless a routine of the same name already exists.

I<Since C<0.03>>

=over 4

=item from example 1

  package Entity;

  use Mars::Role;

  attr 'startup';
  attr 'shutdown';

  sub EXPORT {
    ['startup', 'shutdown']
  }

  package Record;

  use Mars::Class;

  sub AUDIT {
    my ($self, $from) = @_;
    die "Missing startup" if !$from->can('startup');
    die "Missing shutdown" if !$from->can('shutdown');
  }

  package Example;

  use Mars::Class;

  with 'Entity';

  from 'Record';

  # "Example"

=back

=cut

=head2 mixin

  mixin(Str $name) (Str)

The mixin function registers and consumes mixins for the calling package. This
function is always exported unless a routine of the same name already exists.

I<Since C<0.05>>

=over 4

=item mixin example 1

  package YesNo;

  use Mars::Mixin;

  sub no {
    return 0;
  }

  sub yes {
    return 1;
  }

  sub EXPORT {
    ['no', 'yes']
  }

  package Example;

  use Mars::Class;

  mixin 'YesNo';

  # "Example"

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
function is an alias of the L</test> function and will perform an
L<"audit"|Mars::Kind/AUDIT> if present. This function is always exported unless
a routine of the same name already exists.

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
