package Mars;

use 5.018;

use strict;
use warnings;

# VERSION

our $VERSION = '0.05';

# AUTHORITY

our $AUTHORITY = 'cpan:AWNCORP';

# IMPORT

sub import {
  my ($self, @args) = @_;

  my $from = caller;

  no strict 'refs';

  if (!*{"${from}::true"}{"CODE"}) {
    *{"${from}::true"} = \&true;
  }
  if (!*{"${from}::false"}{"CODE"}) {
    *{"${from}::false"} = \&false;
  }

  return $self;
}

sub false {
  require Scalar::Util;
  state $false = Scalar::Util::dualvar(0, "0");
}

sub true {
  require Scalar::Util;
  state $true = Scalar::Util::dualvar(1, "1");
}

1;



=head1 NAME

Mars - OO Framework

=cut

=head1 ABSTRACT

OO Framework for Perl 5

=cut

=head1 VERSION

0.05

=cut

=head1 SYNOPSIS

  package User;

  use Mars::Class;

  attr 'fname';
  attr 'lname';
  attr 'email';
  attr 'trust';

  sub BUILD {
    shift->{trust} = true;
  }

  package main;

  my $user = User->new(
    fname => 'Elliot',
    lname => 'Alderson',
  );

  # bless({
  #   'fname' => 'Elliot',
  #   'lname' => 'Alderson',
  #   'trust' => 1
  # }, 'User')

=cut

=head1 DESCRIPTION

Mars is a simple yet powerful framework for object-oriented programming which
lets you hook into all aspects of the L<"class"|Mars::Class>,
L<"role"|Mars::Role>, L<"interface"|Mars::Role>, and object
L<"lifecycle"|Mars::Kind/METHODS>, from class declaration and object
L<"construction"|Mars::Kind/BLESS>, to object
L<"deconstruction"|Mars::Kind/DESTROY>.

=cut

=head1 FUNCTIONS

This package provides the following functions:

=cut

=head2 false

  false() (Bool)

The false function returns a falsy boolean value which is designed to be
practically indistinguishable from the conventional numerical C<0> value. This
function is always exported unless a routine of the same name already exists.

I<Since C<0.01>>

=over 4

=item false example 1

  package main;

  use Mars;

  my $false = false;

  # 0

=back

=over 4

=item false example 2

  package main;

  use Mars;

  my $true = !false;

  # 1

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

  package main;

  use Mars;

  my $true = true;

  # 1

=back

=over 4

=item true example 2

  package main;

  use Mars;

  my $false = !true;

  # 0

=back

=cut

=head1 AUTHORS

Awncorp, C<awncorp@cpan.org>

=cut