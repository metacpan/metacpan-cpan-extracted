package FIDO::Raw::Cred;
$FIDO::Raw::Cred::VERSION = '0.03';
use strict;
use warnings;

use FIDO::Raw;

=head1 NAME

FIDO::Raw::Cred

=head1 VERSION

version 0.03

=head1 DESCRIPTION

FIDO2 Credential

=head1 METHODS

=head2 new( )

Create a new instance.

=head2 fmt( [$format] )

Get/set the format, where C<$format> must either be C<"packed"> or
C<"fido-u2f">.

=head2 prot( [$protection] )

Get/set the protection. At the moment only C<CRED_PROT_UV_OPTIONAL>,
C<CRED_PROT_UV_OPTIONAL_WITH_ID> and C<FIDO_CRED_PROT_UV_REQUIRED>
protections are supported.

=head2 extensions( $flags )

Set the extensions to the bitmask of C<$flags>. At the moment,
only C<EXT_HMAC_SECRET> and C<EXT_CRED_PROTECT> are supported.

=head2 rp( [$id], $name )

Get/set the the relying party information. C<$id> may be set to C<undef>
if required. Returns a hash reference.

=head2 type ( [$cose_alg] )

Get/set the algorithm, where C<$cose_alg> may be C<COSE_ES256>,
C<COSE_RS256> or C<COSE_EDDSA>. The type of a credential may only be
set once. Not all authenticators support C<COSE_RS256> or C<COSE_EDDSA>.

=head2 user( [$user_id, $name, $display_name, $icon] )

Get/set the user attributes. Returns a hash reference.

=head2 rk( [$opt] )

Get/set the resident key attribute.

=head2 uv( [$opt] )

Get/set the user verification attribute.

=head2 exclude( $cred )

Append the credential ID C<$cred> to the list of excluded credentials.

=head2 authdata( [$data] )

Get/set the authenticator data. C<$data> must be a CBOR-encoded byte
string. Alternatively, L<C<authdata_raw>|"authdata_raw"> may be used
to set raw binary blob.

=head2 authdata_raw( $data )

Set the authenticator data as a raw binary blob.

=head2 clientdata_hash( [$hash] )

Get/set the clientdata hash.

=head2 sig( [$signature] )

Get/set the signature.

=head2 x509( [$cert] )

Get/set the attestation certification.

=head2 flags( )

Get the authenticator data flags.

=head2 id( )

Get the credential ID.

=head2 aaguid( )

Get the authenticator attestation GUID.

=head2 pubkey( )

Get the public key.

=head2 verify( )

Verifies whether the signature matches the attributes of the credential. This method
verifies that the client data hash, relying party ID, credential ID, type, resident key
and user verification attributes have been attested by the holder of the private key
counterpart of the public key contained in the X509 certificate. The certificate itself
is not verified.

The attestation statement formats supported are C<"packed"> and C<"fido-u2f">.  The
attestation type implemented is Basic Attestation. The attestation key pair is assumed
to be of the type C<ES256>. Other attestation formats and types are not supported.

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

1; # End of FIDO::Raw::Cred
