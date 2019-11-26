###############################################################################
## ----------------------------------------------------------------------------
## Scalar helper class.
##
###############################################################################

package MCE::Shared::Scalar;

use strict;
use warnings;

use 5.010001;

no warnings qw( threads recursion uninitialized numeric );

our $VERSION = '1.863';

## no critic (TestingAndDebugging::ProhibitNoStrict)

use MCE::Shared::Base ();
use bytes;

use overload (
   q("")    => \&MCE::Shared::Base::_stringify,
   q(0+)    => \&MCE::Shared::Base::_numify,
   fallback => 1
);

# Based on Tie::StdScalar from Tie::Scalar.

sub TIESCALAR {
   my $class = shift;
   bless \do{ my $o = defined $_[0] ? shift : undef }, $class;
}

sub STORE { ${ $_[0] } = $_[1] }
sub FETCH { ${ $_[0] } }

###############################################################################
## ----------------------------------------------------------------------------
## Sugar API, mostly resembles http://redis.io/commands#string primitives.
##
###############################################################################

# append ( string )

sub append {
   length( ${ $_[0] } .= $_[1] // '' );
}

# decr
# decrby ( number )
# incr
# incrby ( number )
# getdecr
# getincr

sub decr    { --${ $_[0] }               }
sub decrby  {   ${ $_[0] } -= $_[1] || 0 }
sub incr    { ++${ $_[0] }               }
sub incrby  {   ${ $_[0] } += $_[1] || 0 }
sub getdecr {   ${ $_[0] }--        // 0 }
sub getincr {   ${ $_[0] }++        // 0 }

# getset ( value )

sub getset {
   my $old = ${ $_[0] };
   ${ $_[0] } = $_[1];

   $old;
}

# len ( )

sub len {
   length ${ $_[0] };
}

{
   no strict 'refs';

   *{ __PACKAGE__.'::new' } = \&TIESCALAR;
   *{ __PACKAGE__.'::set' } = \&STORE;
   *{ __PACKAGE__.'::get' } = \&FETCH;
}

1;

__END__

###############################################################################
## ----------------------------------------------------------------------------
## Module usage.
##
###############################################################################

=head1 NAME

MCE::Shared::Scalar - Scalar helper class

=head1 VERSION

This document describes MCE::Shared::Scalar version 1.863

=head1 DESCRIPTION

A scalar helper class for use as a standalone or managed by L<MCE::Shared>.

=head1 SYNOPSIS

 # non-shared or local construction for use by a single process

 use MCE::Shared::Scalar;

 my $var = MCE::Shared::Scalar->new( $val );

 # construction for sharing with other threads and processes

 use MCE::Shared;

 my $var = MCE::Shared->scalar( $val );

 # scalar-like dereferencing

 my $val = ${ $var };
 ${ $var } = $val;

 # OO interface

 $val = $var->set( $val );
 $val = $var->get();
 $len = $var->len();

 # included, sugar methods without having to call set/get explicitly

 $val = $var->append( $string );     #   $val .= $string
 $val = $var->decr();                # --$val
 $val = $var->decrby( $number );     #   $val -= $number
 $val = $var->getdecr();             #   $val--
 $val = $var->getincr();             #   $val++
 $val = $var->incr();                # ++$val
 $val = $var->incrby( $number );     #   $val += $number
 $old = $var->getset( $new );        #   $o = $v, $v = $n, $o

For normal scalar behavior, the TIE interface is supported.

 # non-shared or local construction for use by a single process

 use MCE::Shared::Scalar;

 tie my $var, "MCE::Shared::Scalar";

 # construction for sharing with other threads and processes

 use MCE::Shared;

 tie my $var, "MCE::Shared";

 # usage

 $var = 0;

 tied($var)->incrby(20);

=head1 API DOCUMENTATION

This module may involve TIE when accessing the object via scalar dereferencing.
Only shared instances are impacted if doing so. Although likely fast enough for
many use cases, the OO interface is recommended for best performance.

=head2 MCE::Shared::Scalar->new ( [ value ] )

=head2 MCE::Shared->scalar ( [ value ] )

Constructs a new object. Its value is undefined when C<value> is not specified.

 # non-shared or local construction for use by a single process

 use MCE::Shared::Scalar;

 $var = MCE::Shared::Scalar->new( "foo" );
 $var = MCE::Shared::Scalar->new;

 # construction for sharing with other threads and processes

 use MCE::Shared;

 $var = MCE::Shared->scalar( "bar" );
 $var = MCE::Shared->scalar;

=head2 set ( value )

Preferably, set the value via the OO interface. Otherwise, C<TIE> is activated
on-demand for setting the value. The new value is returned in scalar context.

 $val = $var->set( "baz" );
 $var->set( "baz" );
 ${$var} = "baz";

=head2 get

Likewise, obtain the value via the OO interface. C<TIE> is utilized for
retrieving the value otherwise.

 $val = $var->get;
 $val = ${$var};

=head2 len

Returns the length of the value. It returns the C<undef> value if the value
is not defined.

 $len = $var->len;
 length ${$var};

=head1 SUGAR METHODS

This module is equipped with sugar methods to not have to call C<set>
and C<get> explicitly. In shared context, the benefit is atomicity and
reduction in inter-process communication.

The API resembles a subset of the Redis primitives
L<http://redis.io/commands#strings> without the key argument.

=head2 append ( value )

Appends a value at the end of the current value and returns its new length.

 $len = $var->append( "foo" );

=head2 decr

Decrements the value by one and returns its new value.

 $num = $var->decr;

=head2 decrby ( number )

Decrements the value by the given number and returns its new value.

 $num = $var->decrby( 2 );

=head2 getdecr

Decrements the value by one and returns its old value.

 $old = $var->getdecr;

=head2 getincr

Increments the value by one and returns its old value.

 $old = $var->getincr;

=head2 getset ( value )

Sets the value and returns its old value.

 $old = $var->getset( "baz" );

=head2 incr

Increments the value by one and returns its new value.

 $num = $var->incr;

=head2 incrby ( number )

Increments the value by the given number and returns its new value.

 $num = $var->incrby( 2 );

=head1 CREDITS

The implementation is inspired by L<Tie::StdScalar>.

=head1 INDEX

L<MCE|MCE>, L<MCE::Hobo>, L<MCE::Shared>

=head1 AUTHOR

Mario E. Roy, S<E<lt>marioeroy AT gmail DOT comE<gt>>

=cut

