package Hash::Args;

use strict;
use warnings;

use parent       qw( Exporter );
use Carp         ();
use Scalar::Util ();

our $VERSION = '0.02';
our @EXPORT  = qw( hash );


sub hash {
  my $hash;

  if( @_ == 1 && ref $_[0] ne '' ) {
    my $arg = shift;
    my $ref = ref $arg;

    # objects and HASH refs are just pass-throughs
    if( Scalar::Util::blessed( $arg ) || $ref eq 'HASH' ) {
      $hash = $arg;
    }

    # ARRAY refs must be key/value pairs
    elsif( $ref eq 'ARRAY' ) {
      Carp::confess( 'Unable to coerce to HASH reference from ARRAY reference with odd number of elements' )
        if @$arg % 2 == 1;

      $hash = +{ @$arg };
    }

    # i don't even...
    else {
      Carp::confess( 'Unable to coerce to HASH reference from unknown reference type ('. $ref. ')' )
    }
  }
  else {
    Carp::confess( 'Unable to coerce to HASH reference from LIST with odd number of elements' )
      if @_ % 2 == 1;

    $hash = +{ @_ };
  }

  $hash
}


1
__END__

=pod

=head1 NAME

Hash::Args - Coerces argument lists into HASH references for convenience

=head1 SYNOPSIS

  use Hash::Args;

  # ARRAY reference
  my $ref = hash([ foo => 'bar', baz => 'qux' ]);

  # HASH reference
  my $ref = hash({ foo => 'bar', baz => 'qux' });

  # LIST of key/value pairs
  my $ref = hash( foo => 'bar', baz => 'qux' );

  # in a sub-routine
  sub method {
    my ( $self, $param, $args ) = ( shift, shift, hash( @_ ) );
    ...
  }

  # ... or ...
  sub method {
    my $self  = shift;
    my $param = shift;
    my $args  = hash( @_ );
  }

  # ... or ...
  sub method {
    my ( $self, $param, @args ) = @_;

    my $args = hash( @args );
    ...
  }

=head1 DESCRIPTION

The primary purpose of Hash::Args is to provide an easy way to
coerce a list of values into a C<HASH> reference.  It does this in one
of a few ways.  It can accept a plain C<LIST> of key/value pairs, a
C<HASH> reference or an C<ARRAY> reference of key/value pairs.

=head1 EXPORTS

=head2 C<hash( \@ARRAY | \%HASH )>

=head2 C<hash( LIST )>

This sub-routine transforms its arguments into a C<HASH> reference.
It does this by first inspecting C<@_> and then running in one
of two modes of operation.  If there is only one argument and that
argument is a reference, the first mode of operation is selected;
otherwise the second is selected.

In the first mode of operation a check is made to see what type of
reference was passed in.  If it is an C<ARRAY> reference, an exception
is thrown if its length is odd.  Otherwise the array is assumed to
contain key/value pairs and is coerced into a C<HASH> reference as
such.  If the reference passed in is a C<HASH> reference or appears to
be an object, it is simply returned as-is.  If the reference passed in
is none of these an exception is thrown.

In the second mode of operation the C<LIST> that was passed in is
transformed into a C<HASH> reference by treating the list as
key/value pairs.  If the list contains an odd number of elements,
an exception is thrown.

=head1 AUTHOR

jason hord E<lt>pravus@cpan.orgE<gt>

=head1 COPYRIGHT

Copyright (c) 2012-2014, jason hord

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.

=cut
