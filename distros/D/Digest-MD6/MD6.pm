package Digest::MD6;

require 5.008;

use strict;
use warnings;

use Carp qw( croak );
use XSLoader;

use base qw( Exporter Digest::base );

=head1 NAME

Digest::MD6 - Perl interface to the MD6 Algorithm

=head1 VERSION

This document describes Digest::MD6 version 0.10

=cut

our $VERSION = '0.11';

our $HASH_LENGTH = 256;

XSLoader::load( 'Digest::MD6', $VERSION );

BEGIN {
  our @EXPORT_OK = qw( md6 md6_hex md6_base64 );

  my @len = ( 224, 256, 384, 512 );
  for my $l ( @len ) {
    no strict 'refs';
    push @EXPORT_OK, "md6_${l}", "md6_${l}_hex", "md6_${l}_base64";
    *{"md6_${l}"} = sub {
      local $Digest::MD6::HASH_LENGTH = $l;
      md6( @_ );
    };
    *{"md6_${l}_hex"} = sub {
      local $Digest::MD6::HASH_LENGTH = $l;
      md6_hex( @_ );
    };
    *{"md6_${l}_base64"} = sub {
      local $Digest::MD6::HASH_LENGTH = $l;
      md6_base64( @_ );
    };
  }
}

sub add_bits {
  my $self = shift;
  my $bits;
  my $nbits;
  if ( @_ == 1 ) {
    my $arg = shift;
    return $self->_add_bits( pack( "B*", $arg ), length $arg );
  }
  else {
    ( $bits, $nbits ) = @_;
    return $self->_add_bits(
      substr( $bits, 0, int( ( $nbits + 7 ) / 8 ) ), $nbits );
  }
}

1;
__END__

=head1 SYNOPSIS

  # Functional style
  use Digest::MD6 qw(md6 md6_hex md6_base64);

  $digest = md6($data);
  $digest = md6_hex($data);
  $digest = md6_base64($data);

  # OO style
  use Digest::MD6;

  $ctx = Digest::MD6->new;

  # Or set the hash length explicitly
  $ctx = Digest::MD6->new( 512 );

  $ctx->add($data);
  $ctx->addfile(*FILE);

  $digest = $ctx->digest;
  $digest = $ctx->hexdigest;
  $digest = $ctx->b64digest;

=head1 DESCRIPTION

The C<Digest::MD6> module allows you to use the MD6 Message Digest
algorithm from within Perl programs. The algorithm takes as input a
message of arbitrary length and produces as output a "fingerprint" or
"message digest" of the input.

=head1 INTERFACE

The C<Digest::MD6> module provide a procedural interface for simple
use, as well as an object oriented interface that can handle messages
of arbitrary length and which can read files directly.

=head2 FUNCTIONS

The following functions are provided by the C<Digest::MD6> module.
None of these functions are exported by default.

The hash size (which defaults to 256 bits, 32 characters) can be set
before calling these functions:

  $Digest::MD6::HASH_LENGTH = 512; 

=head3 md6($data,...)

This function will concatenate all arguments, calculate the MD6 digest
of this " message ", and return it in binary form.  The returned string
will be 16 bytes long.

The result of md6(" a ", " b ", " c ") will be exactly the same as the
result of md6(" abc ").

=head3 md6_hex($data,...)

Same as md6(), but will return the digest in hexadecimal form. The
length of the returned string will be 32 and it will only contain
characters from this set: '0'..'9' and 'a'..'f'.

=head3 md6_base64($data,...)

Same as md6(), but will return the digest as a base64 encoded string.
The length of the returned string will be 22 and it will only contain
characters from this set: 'A'..'Z', 'a'..'z', '0'..'9', '+' and
'/'.

Note that the base64 encoded string returned is not padded to be a
multiple of 4 bytes long.  If you want interoperability with other
base64 encoded md6 digests you might want to append enough '='
characters to make the length a multiple of 4.

=head2 Aliases

As a shorthand for setting the hash length via
C<$Digest::MD6::HASH_LENGTH> a number of exportable aliases are
available:

  md6_224 md6_224_base64 md6_224_hex
  md6_256 md6_256_base64 md6_256_hex
  md6_384 md6_384_base64 md6_384_hex
  md6_512 md6_512_base64 md6_512_hex

These set the hash length before encoding, so instead of writing:

  {
    local $Digest::MD6::HASH_LENGTH = 512;
    my $hash = md6_hex( $data );
  }

you can just:

  my $hash = md6_512_hex( $data );

=head1 METHODS

The object oriented interface to C<Digest::MD6> is described in this
section.  After a C<Digest::MD6> object has been created, you will add
data to it and finally ask for the digest in a suitable format.  A
single object can be used to calculate multiple digests.

The following methods are provided:

=head3 $md6 = Digest::MD6->new

The constructor returns a new C<Digest::MD6> object which encapsulate
the state of the MD6 message-digest algorithm.

If called as an instance method (i.e. $md6->new) it will just reset the
state the object to the state of a newly created object.  No new
object is created in this case.

The hash size will default to C<$Digest::MD6::HASH_LENGTH> but can be
overridden by passing a different value to the constructor:

  my $md6 = Digest::MD6->new( 128 );

=head3 $md6->reset

This is just an alias for $md6->new.

=head3 $md6->clone

This a copy of the $md6 object. It is useful when you do not want to
destroy the digests state, but need an intermediate value of the
digest, e.g. when calculating digests iteratively on a continuous data
stream. Example:

  my $md6 = Digest::MD6->new;
  while (<>) {
    $md6->add($_);
    print " Line $.: ", $md6->clone->hexdigest, " \n ";
  }

=head3 $md6->add($data,...)

The $data provided as argument are appended to the message we
calculate the digest for.  The return value is the $md6 object itself.

All these lines will have the same effect on the state of the $md6
object:

  $md6->add(" a "); $md6->add(" b "); $md6->add(" c ");
  $md6->add(" a ")->add(" b ")->add(" c ");
  $md6->add(" a ", " b ", " c ");
  $md6->add(" abc ");

=head3 $md6->addfile($io_handle)

The $io_handle will be read until EOF and its content appended to the
message we calculate the digest for.  The return value is the $md6
object itself.

The addfile() method will croak() if it fails reading data for some
reason.  If it croaks it is unpredictable what the state of the $md6
object will be in. The addfile() method might have been able to read
the file partially before it failed.  It is probably wise to discard
or reset the $md6 object if this occurs.

In most cases you want to make sure that the $io_handle is in
C<binmode> before you pass it as argument to the addfile() method.

=head3 $md6->add_bits($data, $nbits)

=head3 $md6->add_bits($bitstring)

Since the MD6 algorithm is byte oriented you might only add bits as
multiples of 8, so you probably want to just use add() instead.  The
add_bits() method is provided for compatibility with other digest
implementations.  See L<Digest> for description of the arguments
that add_bits() take.

=head3 $md6->digest

Return the binary digest for the message.  The returned string will be
16 bytes long.

Note that the C<digest> operation is effectively a destructive,
read-once operation. Once it has been performed, the C<Digest::MD6>
object is automatically C<reset> and can be used to calculate another
digest value.  Call $md6->clone->digest if you want to calculate the
digest without resetting the digest state.

=head3 $md6->hexdigest

Same as $md6->digest, but will return the digest in hexadecimal
form. The length of the returned string will be 32 and it will only
contain characters from this set: '0'..'9' and 'a'..'f'.

=head3 $md6->b64digest

Same as $md6->digest, but will return the digest as a base64 encoded
string.  The length of the returned string will be 22 and it will only
contain characters from this set: 'A'..'Z', 'a'..'z', '0'..'9', '+'
and '/'.

The base64 encoded string returned is not padded to be a multiple of 4
bytes long.  If you want interoperability with other base64 encoded
md6 digests you might want to append the string " == " to the result.

L<Digest>,
L<Digest::MD2>,
L<Digest::MD5>,
L<Digest::SHA>,
L<Digest::HMAC>

L<http://en.wikipedia.org/wiki/MD6>

L<http://groups.csail.mit.edu/cis/md6/>

=head1 AUTHOR

Andy Armstrong  C<< <andy@hexten.net> >>

=head1 LICENCE AND COPYRIGHT

Copyright (c) 2009, Andy Armstrong C<< <andy@hexten.net> >>.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.

Based on L<Digest::MD5> by Gisle Aas which carries this copyright
notice:

  Copyright 1998-2003 Gisle Aas.
  Copyright 1995-1996 Neil Winton.
  Copyright 1991-1992 RSA Data Security, Inc.

The MD6 implementation used is 
L<http://groups.csail.mit.edu/cis/md6/code/md6_c_code-2009-04-15.zip> 
which is

  Copyright (c) 2008 Ronald L. Rivest

The MD6 code is licensed under the MIT license.

=cut
