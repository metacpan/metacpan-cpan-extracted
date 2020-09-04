package FIDO::Raw::Assert;
$FIDO::Raw::Assert::VERSION = '0.06';
use strict;
use warnings;

use FIDO::Raw;

=head1 NAME

FIDO::Raw::Assert

=head1 VERSION

version 0.06

=head1 DESCRIPTION

FIDO2 Assertion

=head1 METHODS

=head2 new( )

Create a new instance.

=head2 allow_cred( $cred )

Append the credential C<$cred> to the list of credentials allowed for this
assertion.

=head2 authdata( [$index = 0, $data] )

Get/set the authenticator data. C<$data> must be a CBOR-encoded byte
string. Alternatively, L<C<authdata_raw>|"authdata_raw"> may be used
to set raw binary blob.

=head2 authdata_raw( $data, [$index = 0] )

Set the authenticator data as a raw binary blob.

=head2 clientdata_hash( [$hash] )

Get/set the clientdata hash.

=head2 count( [$total] )

Get/set the number of assertion statements.

=head2 extensions( $flags )

Set the extensions to the bitmask of C<$flags>. At the moment,
only C<EXT_HMAC_SECRET> is supported.

=head2 hmac_salt( $salt )

Set the HMAC salt.

=head2 hmac_secret( [$index = 0] )

Get the HMAC secret.

=head2 rp( [$id] )

Get/set the relying party ID.

=head2 sig( [$index = 0, $signature] )

Get/set the signature.

=head2 sigcount( [$index = 0] )

Get the signature counter.

=head2 up( )

Set the user presence attribute.

=head2 user( [$index = 0] )

Get the user details. Returns a hash reference.

=head2 uv( )

Set the user verification attribute.

=head2 flags( [$index = 0] )

Get the authenticator data flags.

=head2 id( [$index = 0] )

Get the credential ID.

=head2 verify( $index, $alg, $pk )

Verifies whether the signature contained in statement C<$index> matches
the parameters of the assertion. It verifies whether the client data hash,
relying party ID, user presence and user verification attributes of the
assertion have been attested by the holder of the private counterpart of the
public key C<$pk> using the COSE type C<$alg>. C<$alg> is constrained to
C<COSE_ES256>, C<COSE_RS256> and C<COSE_EDDSA>. C<$pk> should be a
L<C<FIDO::Raw::PublicKey::ES256>>, L<C<FIDO::Raw::PublicKey::RS256>>, or a
L<C<FIDO::Raw::PublicKey::EDDSA>>.

This method returns a result code of C<FIDO::Raw::FIDO_OK> on success or an
error result code otherwise.

=head1 AUTHOR

Jacques Germishuys <jacquesg@striata.com>

=head1 LICENSE AND COPYRIGHT

Copyright 2020 Jacques Germishuys.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut

1; # End of FIDO::Raw::Assert
