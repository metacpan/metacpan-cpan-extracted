#==============================================================================
# LibWeb::Digest -- Digest generation for libweb applications.

package LibWeb::Digest;

# Copyright (C) 2000  Colin Kong
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA  02111-1307, USA.
#=============================================================================

# $Id: Digest.pm,v 1.2 2000/07/18 06:33:30 ckyc Exp $

#-##############################
# Use standard library.
use strict;
use vars qw($VERSION @ISA);
require Digest::HMAC;
require Digest::SHA1;
require Digest::MD5;

#-##############################
# Use custom library.
require LibWeb::Class;

#-##############################
# Version.
$VERSION = '0.02';

#-##############################
# Inheritance.
@ISA = qw(LibWeb::Class);

#-##############################
# Methods.
sub new {
    my ($class, $Class, $self);
    $class = shift; 
    $Class = ref($class) || $class;
    $self = $Class->SUPER::new(shift);
    bless($self, $Class);
}

sub DESTROY {}

sub generate_MAC {
    #
    # Params: -data=>, -key=>, -algorithm=>, -format=>
    # e.g. -algorithm => 'Digest::MD5'
    # e.g. -algorithm => 'Digest::SHA1'
    # e.g. -format => 'binary' or 'hex' or 'b64'.
    #
    my ($self, $data, $key, $algorithm, $format, $hmac);
    $self = shift;
    ($data, $key, $algorithm, $format) =
      $self->rearrange(['DATA', 'KEY', 'ALGORITHM', 'FORMAT'], @_);

    $format = uc($format);
    $hmac = Digest::HMAC->new($key, $algorithm);
    $hmac->add($data);
    return $hmac->digest if ($format eq 'BINARY');
    return $hmac->hexdigest if ($format eq 'HEX');
    return $hmac->b64digest if ($format eq 'B64');
}

sub generate_digest {
    #
    # Params: -data=>, -key=>, -algorithm=>, -format=>
    # e.g. -algorithm => 'Digest::MD5'
    # e.g. -algorithm => 'Digest::SHA1'
    # e.g. -format => 'binary' or 'hex' or 'b64'.
    #
    my ($self, $data, $key, $algorithm, $format, $ctx);
    $self = shift;
    ($data, $key, $algorithm, $format) =
      $self->rearrange(['DATA', 'KEY', 'ALGORITHM', 'FORMAT'], @_);

    $format = uc($format);
    $ctx = $algorithm->new;
    $ctx->add( $data . $key );
    return $ctx->digest if ($format eq 'BINARY');
    return $ctx->hexdigest if ($format eq 'HEX');
    return $ctx->b64digest if ($format eq 'B64');
}

1;
__END__

=head1 NAME

LibWeb::Digest - Digest generation for libweb applications

=head1 SUPPORTED PLATFORMS

=over 2

=item BSD, Linux, Solaris and Windows.

=back

=head1 REQUIRE

=over 2

=item *

Digest::HMAC

=item *

Digest::SHA1

=item *

Digest::MD5

=back

=head1 ISA

=over 2

=item *

LibWeb::Class

=back

=head1 SYNOPSIS

  use LibWeb::Digest;
  my $d = new LibWeb::Digest();

  my $mac = $d->generate_MAC(
			     -data => $data,
			     -key => $key,
			     -algorithm => 'Digest::SHA1',
			     -format => 'b64'
			    );

  my $digest
      = $d->generate_digest(
			    -data => $data,
			    -key => $key,
			    -algorithm => 'Digest::MD5',
			    -format => 'b64'
			   );

=head1 ABSTRACT

This class provides methods to

=over 2

=item *

Generate message authenticity check (MAC) code which is mostly used in
authentication cookies sent to browsers, and

=item *

generate digest code (binary, hex or B64) by using the algorithm
provided by either Digest::MD5 or Digest::SHA1,

=back

The current version of LibWeb::Digest is available at

   http://libweb.sourceforge.net

Several LibWeb applications (LEAPs) have be written, released and are
available at

   http://leaps.sourceforge.net

=head1 DESCRIPTION

=head2 GENERATING A MAC FOR USER/SESSION AUTHENTICATION

The following discussion on MAC is extracted from a WWW security FAQ
written by Lincoln Stein,

  http://www.w3.org/Security/Faq/wwwsf7.html#Q66

``If possible, cookies should contain information that allows the
system to verify that the person using them is authorized to do so. A
popular scheme is to include the following information in cookies:

  1.the session ID or authorization information 
  2.the time and date the cookie was issued 
  3.an expiration time 
  4.the IP address of the browser the cookie was issued to 
  5.a message authenticity check (MAC) code 

By incorporating an expiration date and time into the cookie, system
designers can limit the potential damage that a hijacked cookie can
do. If the cookie is intercepted, it can only be used for a finite
time before it becomes invalid.  The idea of including the browser's
IP address into the cookie is that the cookie will only be accepted if
the stored IP address matches the IP address of the browser submitting
it.  This makes it difficult for an interloper to hijack the cookie,
because it is hard (although not impossible) to spoof an IP address.

The MAC code is there to ensure that none of the fields of the cookie
have been tampered with.  There are many ways to compute a MAC, most
of which rely on one-way hash algorithms such as MD5 or SHA to create
a unique fingerprint for the data within the cookie. Here's a simple
but relatively secure technique that uses MD5:

    MAC = MD5("secret key " +
               MD5("session ID" + "issue date" +
                   "expiration time" + "IP address" +
                   "secret key")
              )

This algorithm first performs a string concatenation of all the data
fields in the cookie, then adds to it a secret string known only to
the Web server. The whole is then passed to the MD5 function to create
a unique hash. This value is again concatenated with the secret key,
and the whole thing is rehashed. (The second round of MD5 hashing is
necessary in order to avoid an attack in which additional data is
appended to the end of the cookie and a new hash recalculated by the
attacker.)

This hash value is now incorporated into the cookie data. Later, when
the cookie is returned to the server, the software should verify that
the cookie hasn't expired and is being returned by the proper IP
address. Then it should regenerate the MAC from the data fields, and
compare that to the MAC in the cookie. If they match, there's little
chance that the cookie has been tampered with.'' -- Lincoln Stein.

In fact, this is the technique used by LibWeb to handle user/session
authentication via cookies.  LibWeb::Admin and LibWeb::Session use
LibWeb::Digest::generate_MAC() to generate MACs.
LibWeb::Digest::generate_MAC() uses Digest::HMAC and uses either
Digest::MD5 or Digest::SHA1 as the digest algorithm.

=head2 METHODS

B<generate_MAC()>

Params:

  -data=>, -key=>, -algorithm=>, -format=>

Pre:

=over 2

=item *

C<-data> is the data from which the MAC is to be generated,

=item *

C<-key> is the private key such that the MAC generated is unique to
that key (sorry, I do not have a rigorous definition for that right
now),

=item *

C<-algorithm> must be either 'Digest::MD5' or 'Digest::SHA1',

=item *

C<-format> is the format of the generated MAC, which must be 'binary',
'hex' or 'b64'.

=back

Post:

=over 2

=item *

Generate a MAC and return it.

=back

B<generate_digest()>

Params:

  -data=>, -key=>, -algorithm=>, -format=>

Pre:

=over 2

=item *

C<-data> is the data from which the digest is to be generated,

=item *

C<-key> is the private key such that the digest generated is unique to
that key (sorry, I do not have a rigorous definition for that right
now),

=item *

C<-algorithm> must be either 'Digest::MD5' or 'Digest::SHA1',

=item *

C<-format> is the format of the digest, which must be 'binary', 'hex'
or 'b64'.

=back

Post:

=over 2

=item *

Generate a digest and return it.

=back

=head1 AUTHORS

=over 2

=item Colin Kong (colin.kong@toronto.edu)

=back

=head1 CREDITS

=over 2

=item Lincoln Stein (lstein@cshl.org)

=back

=head1 BUGS


=head1 SEE ALSO

L<Digest::HMAC>, L<Digest::SHA1>, L<Digest::MD5>, L<Crypt::CBC>,
L<Crypt::Blowfish>, L<Crypt::DES>, L<Crypt::IDEA>, L<LibWeb::Admin>,
L<LibWeb::Crypt>, L<LibWeb::Session>.

=cut
