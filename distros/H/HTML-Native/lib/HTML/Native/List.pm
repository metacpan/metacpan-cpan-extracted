package HTML::Native::List;

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

HTML::Native::List - List of HTML::Native objects

=head1 SYNOPSIS

    use HTML::Native::List;

    # Create some HTML
    my $list = HTML::Native::List->new (
      [ img => { src => "logo.png" } ],
      [ h1 => "Hello!" ],
      "This is some text",
    );
    print $list;
    # prints "<img src="logo.png" /><h1>Hello!</h1>This is some text"

=head1 DESCRIPTION

An L<HTML::Native::List> object represents a list containing a mixture
of L<HTML::Native> objects (themselves representing HTML elements) and
plain-text content.  L<HTML::Native> uses an L<HTML::Native::List>
object to represent the children of an HTML element.

An L<HTML::Native::List> object is a tied array (see L<perltie>).  You
can treat it as a normal Perl array:

    my $list = HTML::Native::List->new (
      [ img => { src => "logo.png" } ],
      [ h1 => "Hello!" ],
      "This is some text",
    );
    print $list->[1];
    # prints "<h1>Hello!</h1>"

Any anonymous arrays within the contents will be automatically
converted into new L<HTML::Native> objects.  For example:

    my $list = HTML::Native::List->new();
    push @$list, [ p => "Hello world" ];
    print $list;
    # prints "<p>Hello world</p>"

See L<HTML::Native> for more documentation and examples.

=cut

use Scalar::Util qw ( blessed );
use HTML::Entities;
use HTML::Native;
use strict;
use warnings;

use overload
    '""' => sub { my $self = shift; return $self->html; },
    fallback => 1;

sub new {
  my $old = shift;
  $old = tied ( @$old ) // $old if ref $old;
  my $class = ref $old || $old;
  my $self = [ @_ ];

  my $array;
  tie @$array, $class, $self;
  bless $array, $class;
  return $array;
}

sub TIEARRAY {
  my $old = shift;
  my $class = ref $old || $old;
  my $self = shift || [];

  bless $self, $class;

  # Convert plain-array content to HTML::Native
  foreach my $value ( @$self ) {
    if ( ref $value eq "ARRAY" ) {
      $value = $self->new_element ( @$value );
    }
  }

  return $self;
}

sub FETCH {
  my $self = shift;
  my $index = shift;

  return $self->[$index];
}

sub STORE {
  my $self = shift;
  my $index = shift;
  my $value = shift;

  # Convert plain-array content to HTML::Native
  if ( ref $value eq "ARRAY" ) {
    $value = $self->new_element ( @$value );
  }

  $self->[$index] = $value;
}

sub FETCHSIZE {
  my $self = shift;

  return scalar @$self;
}

sub STORESIZE {
  my $self = shift;
  my $count = shift;

  $#$self = ( $count - 1 );
}

sub EXTEND {
  my $self = shift;
  my $count = shift;

  $#$self = ( $count - 1 );
}

sub EXISTS {
  my $self = shift;
  my $index = shift;

  return exists $self->[$index];
}

sub DELETE {
  my $self = shift;
  my $index = shift;

  return delete $self->[$index];
}

sub CLEAR {
  my $self = shift;

  @$self = ();
}

sub PUSH {
  my $self = shift;
  my @list = @_;

  # Convert plain-array content to HTML::Native
  foreach my $value ( @list ) {
    if ( ref $value eq "ARRAY" ) {
      $value = $self->new_element ( @$value );
    }
  }

  push @$self, @list;
}

sub POP {
  my $self = shift;

  return pop @$self;
}

sub SHIFT {
  my $self = shift;

  return shift @$self;
}

sub UNSHIFT {
  my $self = shift;
  my @list = @_;

  # Convert plain-array content to HTML::Native
  foreach my $value ( @list ) {
    if ( ref $value eq "ARRAY" ) {
      $value = $self->new_element ( @$value );
    }
  }

  unshift @$self, @list;
}

sub SPLICE {
  my $self = shift;
  my $offset = shift;
  my $length = shift;
  my @list = @_;

  # Convert plain-array content to HTML::Native
  foreach my $value ( @list ) {
    if ( ref $value eq "ARRAY" ) {
      $value = $self->new_element ( @$value );
    }
  }

  return splice @$self, $offset, $length, @list;
}

sub html {
  my $self = shift;
  $self = tied ( @$self ) // $self if ref $self;
  my $class = ref $self || $self;
  my $html = "";
  my $callback = shift || sub { $html .= shift; };

  foreach my $child ( @$self ) {
    if ( ref $child eq "CODE" ) {
      # Call code ref to generate dynamic content: either a ready-made
      # HTML::Native::List object or a list to be passed to new()
      my @dynamic = &$child;
      my $dynamic = ( ( ( @dynamic == 1 ) && blessed ( $dynamic[0] ) &&
			$dynamic[0]->isa ( "HTML::Native::List" ) )
		      ? $dynamic[0] : $class->new ( @dynamic ) );
      $dynamic->html ( $callback );
    } elsif ( ref $child ) {
      $child->html ( $callback );
    } else {
      &$callback ( defined $child ? encode_entities ( $child ) : "" );
    }
  }
  return $html;
}

=head1 SUBCLASSING

When subclassing L<HTML::Native::List>, you may wish to override the
class that is used by default to hold new elements.  You can do this
by overriding the C<new_element()> method:

=head2 new_element()

    $elem = $self->new_element ( ... )

The default implementation of this method simply calls
C<< HTML::Native->new() >>:

    return HTML::Native->new ( @_ );

=cut

sub new_element {
  my $self = shift;
  $self = tied ( @$self ) // $self if ref $self;
  my @element = @_;

  return HTML::Native->new ( @element );
}

=pod

=head1 ADVANCED

=head2 DYNAMIC GENERATION

You can use anonymous subroutines (closures) to dynamically generate
portions of an L<HTML::Native::List> array.  For example:

    my $message;
    my $list = HTML::Native::List->new (
      [ h1 => "Dynamic content" ],
      sub { return $message; },
    );
    $message = "Hello world!";
    print $list;
    # prints "<h1>Dynamic content</h1>Hello world!"

The subroutine can return either a single fully-constructed
L<HTML::Native::List> object, or a list of arguments ready to be
passed to C<< HTML::Native::List->new() >>.  For example:

    sub {
      return HTML::Native::List->new (
	[ img => { src => $image } ],
	[ p => $message ],
      );
    }

or

    sub {
      return ( [ img => { src => $image } ],
	       [ p => $message ] );
    }

=cut

1;
