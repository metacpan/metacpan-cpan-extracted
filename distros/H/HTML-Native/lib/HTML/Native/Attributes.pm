package HTML::Native::Attributes;

# Copyright (C) 2011 Michael Brown <mbrown@fensystems.co.uk>.
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License as
# published by the Free Software Foundation; either version 2 of the
# License, or any later version.
#
# This program is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
# General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 675 Mass Ave, Cambridge, MA 02139, USA.

=head1 NAME

HTML::Native::Attributes - HTML element attributes

=head1 SYNOPSIS

    use HTML::Native;

    my $elem = HTML::Native->new (
      a => { class => "active", href => "/home" },
      "Home"
    );
    my $attrs = \%$elem;
    print $attrs;
    # prints " class="active" href="/home""


    use HTML::Native::Attributes;

    my $attrs = HTML::Native::Attributes->new ( {
      class => "active",
      href => "/home",
    } );
    print $attrs;
    # prints " class="active" href="/home""

    $attrs->{class}->{nav} = 1;
    print $attrs;
    # prints " class="active nav" href="/home""

=head1 DESCRIPTION

An L<HTML::Native::Attributes> object represents a set of HTML element
attributes belonging to an L<HTML::Native> object.  It will be created
automatically by L<HTML::Native> as necessary; you probably do B<not>
ever need to manually create an L<HTML::Native::Attributes> object.

An L<HTML::Native::Attributes> object is a tied hash (see L<perltie>).
You can treat it as a normal Perl hash:

    my $attrs = HTML::Native::Attributes->new ( { href => "/home" } );
    print $attrs->{home};
    # prints "/home"

Any value stored in the hash will be automatically converted into a
new L<HTML::Native::Attribute> object, and can be transparently
accessed either as a scalar, or as a hash, or as an array.  For
example:

    my $attrs = HTML::Native::Attributes->new();
    $attrs->{class} = "error";
    $attrs->{class}->{fatal} = 1;
    push @{$attrs->{class}}, "internal";
    print $attrs->{class};
    # prints "error fatal internal";

See L<HTML::Native::Attribute> for more documentation and examples.

=cut

use HTML::Native::Attribute;
use Scalar::Util qw ( blessed );
use strict;
use warnings;

use overload
    '""' => sub { my $self = shift; return $self->attributes; },
    fallback => 1;

sub new {
  my $old = shift;
  $old = tied ( %$old ) // $old if ref $old;
  my $class = ref $old || $old;
  my $self = shift || {};

  my $hash;
  tie %$hash, $class, $self;
  bless $hash, $class;
  return $hash;
}

sub TIEHASH {
  my $old = shift;
  my $class = ref $old || $old;
  my $self = shift || {};

  bless $self, $class;

  # Convert unblessed values to HTML::Native::Attribute
  foreach my $value ( values %$self ) {
    $value = $self->new_attribute ( $value ) unless blessed $value;
  }

  return $self;
}

sub FETCH {
  my $self = shift;
  my $key = shift;

  return $self->{$key};
}

sub STORE {
  my $self = shift;
  my $key = shift;
  my $value = shift;

  # Convert unblessed values to HTML::Native::Attribute
  $value = $self->new_attribute ( $value ) unless blessed $value;

  $self->{$key} = $value;
}

sub DELETE {
  my $self = shift;
  my $key = shift;

  return delete $self->{$key};
}

sub CLEAR {
  my $self = shift;

  %$self = ();
}

sub EXISTS {
  my $self = shift;
  my $key = shift;

  return exists $self->{$key};
}

sub FIRSTKEY {
  my $self = shift;

  keys %$self;
  return each %$self;
}

sub NEXTKEY {
  my $self = shift;

  return each %$self;
}

sub SCALAR {
  my $self = shift;

  return scalar %$self;
}

sub attributes {
  my $self = shift;
  $self = tied ( %$self ) // $self if ref $self;

  return "" unless %$self;
  return " ".join ( " ", map { $_."=\"".$self->{$_}."\"" } sort keys %$self );
}

=head1 SUBCLASSING

When subclassing L<HTML::Native::Attributes>, you may wish to override
the class that is used by default to hold new attributes.  You can do
this by overriding the C<new_attribute()> method:

=head2 new_attribute()

    $attr = $self->new_attribute ( <value> )

The default implementation of this method simply calls
C<< HTML::Native::Attribute->new() >>:

    return HTML::Native::Attribute->new ( shift );

=cut

sub new_attribute {
  my $self = shift;
  $self = tied ( %$self ) // $self if ref $self;
  my $value = shift;

  return HTML::Native::Attribute->new ( $value );
}

1;
