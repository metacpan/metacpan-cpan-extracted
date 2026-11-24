package Grafeas::V1::Attestation;

use strict;
use warnings;

our $VERSION = '0.14';

use Protobuf::Message;
use Protobuf::DescriptorPool;
use Protobuf::Internal qw(:all);
use MIME::Base64;

BEGIN {
    eval { require Grafeas::V1::Common };
    my $descriptor_b64 = <<'EOF';
ChxncmFmZWFzL3YxL2F0dGVzdGF0aW9uLnByb3RvEgpncmFmZWFzLnYxGhdncmFmZWFzL3Yx
L2NvbW1vbi5wcm90byJ/Cg9BdHRlc3RhdGlvbk5vdGUSNAoEaGludBgBIAEoCzIgLmdyYWZl
YXMudjEuQXR0ZXN0YXRpb25Ob3RlLkhpbnRSBGhpbnQaNgoESGludBIuChNodW1hbl9yZWFk
YWJsZV9uYW1lGAEgASgJUhFodW1hblJlYWRhYmxlTmFtZSImCgNKd3QSHwoLY29tcGFjdF9q
d3QYASABKAlSCmNvbXBhY3RKd3QiogEKFUF0dGVzdGF0aW9uT2NjdXJyZW5jZRItChJzZXJp
YWxpemVkX3BheWxvYWQYASABKAxSEXNlcmlhbGl6ZWRQYXlsb2FkEjUKCnNpZ25hdHVyZXMY
AiADKAsyFS5ncmFmZWFzLnYxLlNpZ25hdHVyZVIKc2lnbmF0dXJlcxIjCgRqd3RzGAMgAygL
Mg8uZ3JhZmVhcy52MS5Kd3RSBGp3dHNCUQoNaW8uZ3JhZmVhcy52MVABWjhnb29nbGUuZ29s
YW5nLm9yZy9nZW5wcm90by9nb29nbGVhcGlzL2dyYWZlYXMvdjE7Z3JhZmVhc6ICA0dSQUq6
IAoGEgQOAFkBCtoECgEMEgMOABIyzwQgQ29weXJpZ2h0IDIwMTkgVGhlIEdyYWZlYXMgQXV0
aG9ycy4gQWxsIHJpZ2h0cyByZXNlcnZlZC4KCiBMaWNlbnNlZCB1bmRlciB0aGUgQXBhY2hl
IExpY2Vuc2UsIFZlcnNpb24gMi4wICh0aGUgIkxpY2Vuc2UiKTsKIHlvdSBtYXkgbm90IHVz
ZSB0aGlzIGZpbGUgZXhjZXB0IGluIGNvbXBsaWFuY2Ugd2l0aCB0aGUgTGljZW5zZS4KIFlv
dSBtYXkgb2J0YWluIGEgY29weSBvZiB0aGUgTGljZW5zZSBhdAoKICAgIGh0dHA6Ly93d3cu
YXBhY2hlLm9yZy9saWNlbnNlcy9MSUNFTlNFLTIuMAoKIFVubGVzcyByZXF1aXJlZCBieSBh
cHBsaWNhYmxlIGxhdyBvciBhZ3JlZWQgdG8gaW4gd3JpdGluZywgc29mdHdhcmUKIGRpc3Ry
aWJ1dGVkIHVuZGVyIHRoZSBMaWNlbnNlIGlzIGRpc3RyaWJ1dGVkIG9uIGFuICJBUyBJUyIg
QkFTSVMsCiBXSVRIT1VUIFdBUlJBTlRJRVMgT1IgQ09ORElUSU9OUyBPRiBBTlkgS0lORCwg
ZWl0aGVyIGV4cHJlc3Mgb3IgaW1wbGllZC4KIFNlZSB0aGUgTGljZW5zZSBmb3IgdGhlIHNw
ZWNpZmljIGxhbmd1YWdlIGdvdmVybmluZyBwZXJtaXNzaW9ucyBhbmQKIGxpbWl0YXRpb25z
IHVuZGVyIHRoZSBMaWNlbnNlLgoKCAoBAhIDEAATCgkKAgMAEgMSACEKCAoBCBIDFABPCgkK
AggLEgMUAE8KCAoBCBIDFQAiCgkKAggKEgMVACIKCAoBCBIDFgAmCgkKAggBEgMWACYKCAoB
CBIDFwAhCgkKAggkEgMXACEKiAYKAgQAEgQlADUBGq0EIE5vdGUga2luZCB0aGF0IHJlcHJl
c2VudHMgYSBsb2dpY2FsIGF0dGVzdGF0aW9uICJyb2xlIiBvciAiYXV0aG9yaXR5Ii4gRm9y
CiBleGFtcGxlLCBhbiBvcmdhbml6YXRpb24gbWlnaHQgaGF2ZSBvbmUgYEF1dGhvcml0eWAg
Zm9yICJRQSIgYW5kIG9uZSBmb3IKICJidWlsZCIuIFRoaXMgbm90ZSBpcyBpbnRlbmRlZCB0
byBhY3Qgc3RyaWN0bHkgYXMgYSBncm91cGluZyBtZWNoYW5pc20gZm9yCiB0aGUgYXR0YWNo
ZWQgb2NjdXJyZW5jZXMgKEF0dGVzdGF0aW9ucykuIFRoaXMgZ3JvdXBpbmcgbWVjaGFuaXNt
IGFsc28KIHByb3ZpZGVzIGEgc2VjdXJpdHkgYm91bmRhcnksIHNpbmNlIElBTSBBQ0xzIGdh
dGUgdGhlIGFiaWxpdHkgZm9yIGEgcHJpbmNpcGxlCiB0byBhdHRhY2ggYW4gb2NjdXJyZW5j
ZSB0byBhIGdpdmVuIG5vdGUuIEl0IGFsc28gcHJvdmlkZXMgYSBzaW5nbGUgcG9pbnQgb2YK
IGxvb2t1cCB0byBmaW5kIGFsbCBhdHRhY2hlZCBhdHRlc3RhdGlvbiBvY2N1cnJlbmNlcywg
ZXZlbiBpZiB0aGV5IGRvbid0IGFsbAogbGl2ZSBpbiB0aGUgc2FtZSBwcm9qZWN0LgoyywEg
QW4gYXR0ZXN0YXRpb24gd3JhcHBlciB3aXRoIGEgUEdQLWNvbXBhdGlibGUgc2lnbmF0dXJl
LiBUaGlzIG1lc3NhZ2Ugb25seQogc3VwcG9ydHMgYEFUVEFDSEVEYCBzaWduYXR1cmVzLCB3
aGVyZSB0aGUgcGF5bG9hZCB0aGF0IGlzIHNpZ25lZCBpcyBpbmNsdWRlZAogYWxvbmdzaWRl
IHRoZSBzaWduYXR1cmUgaXRzZWxmIGluIHRoZSBzYW1lIGZpbGUuCgoKCgMEAAESAyUIFwrW
AwoEBAADABIELQIxAxrHAyBUaGlzIHN1Ym1lc3NhZ2UgcHJvdmlkZXMgaHVtYW4tcmVhZGFi
bGUgaGludHMgYWJvdXQgdGhlIHB1cnBvc2Ugb2YgdGhlCiBhdXRob3JpdHkuIEJlY2F1c2Ug
dGhlIG5hbWUgb2YgYSBub3RlIGFjdHMgYXMgaXRzIHJlc291cmNlIHJlZmVyZW5jZSwgaXQg
aXMKIGltcG9ydGFudCB0byBkaXNhbWJpZ3VhdGUgdGhlIGNhbm9uaWNhbCBuYW1lIG9mIHRo
ZSBOb3RlICh3aGljaCBtaWdodCBiZSBhCiBVVUlEIGZvciBzZWN1cml0eSBwdXJwb3Nlcykg
ZnJvbSAicmVhZGFibGUiIG5hbWVzIG1vcmUgc3VpdGFibGUgZm9yIGRlYnVnCiBvdXRwdXQu
IE5vdGUgdGhhdCB0aGVzZSBoaW50cyBzaG91bGQgbm90IGJlIHVzZWQgdG8gbG9vayB1cCBh
dXRob3JpdGllcyBpbgogc2VjdXJpdHkgc2Vuc2l0aXZlIGNvbnRleHRzLCBzdWNoIGFzIHdo
ZW4gbG9va2luZyB1cCBhdHRlc3RhdGlvbnMgdG8KIHZlcmlmeS4KCgwKBQQAAwABEgMtCg4K
ZAoGBAADAAIAEgMwBCMaVSBSZXF1aXJlZC4gVGhlIGh1bWFuIHJlYWRhYmxlIG5hbWUgb2Yg
dGhpcyBhdHRlc3RhdGlvbiBhdXRob3JpdHksIGZvcgogZXhhbXBsZSAicWEiLgoKDgoHBAAD
AAIABRIDMAQKCg4KBwQAAwACAAESAzALHgoOCgcEAAMAAgADEgMwISIKRgoEBAACABIDNAIQ
GjkgSGludCBoaW50cyBhdCB0aGUgcHVycG9zZSBvZiB0aGUgYXR0ZXN0YXRpb24gYXV0aG9y
aXR5LgoKDAoFBAACAAYSAzQCBgoMCgUEAAIAARIDNAcLCgwKBQQAAgADEgM0Dg8KCgoCBAES
BDcAPAEKCgoDBAEBEgM3CAsKtwEKBAQBAgASAzsCGRqpASBUaGUgY29tcGFjdCBlbmNvZGlu
ZyBvZiBhIEpXUywgd2hpY2ggaXMgYWx3YXlzIHRocmVlIGJhc2U2NCBlbmNvZGVkIHN0cmlu
Z3MKIGpvaW5lZCBieSBwZXJpb2RzLiBGb3IgZGV0YWlscywgc2VlOgogaHR0cHM6Ly90b29s
cy5pZXRmLm9yZy9odG1sL3JmYzc1MTUuaHRtbCNzZWN0aW9uLTMuMQoKDAoFBAECAAUSAzsC
CAoMCgUEAQIAARIDOwkUCgwKBQQBAgADEgM7FxgKmgQKAgQCEgRGAFkBGo0EIE9jY3VycmVu
Y2UgdGhhdCByZXByZXNlbnRzIGEgc2luZ2xlICJhdHRlc3RhdGlvbiIuIFRoZSBhdXRoZW50
aWNpdHkgb2YgYW4KIGF0dGVzdGF0aW9uIGNhbiBiZSB2ZXJpZmllZCB1c2luZyB0aGUgYXR0
YWNoZWQgc2lnbmF0dXJlLiBJZiB0aGUgdmVyaWZpZXIKIHRydXN0cyB0aGUgcHVibGljIGtl
eSBvZiB0aGUgc2lnbmVyLCB0aGVuIHZlcmlmeWluZyB0aGUgc2lnbmF0dXJlIGlzCiBzdWZm
aWNpZW50IHRvIGVzdGFibGlzaCB0cnVzdC4gSW4gdGhpcyBjaXJjdW1zdGFuY2UsIHRoZSBh
dXRob3JpdHkgdG8gd2hpY2gKIHRoaXMgYXR0ZXN0YXRpb24gaXMgYXR0YWNoZWQgaXMgcHJp
bWFyaWx5IHVzZWZ1bCBmb3IgbG9va3VwIChob3cgdG8gZmluZAogdGhpcyBhdHRlc3RhdGlv
biBpZiB5b3UgYWxyZWFkeSBrbm93IHRoZSBhdXRob3JpdHkgYW5kIGFydGlmYWN0IHRvIGJl
CiB2ZXJpZmllZCkgYW5kIGludGVudCAoZm9yIHdoaWNoIGF1dGhvcml0eSB0aGlzIGF0dGVz
dGF0aW9uIHdhcyBpbnRlbmRlZCB0bwogc2lnbi4KCgoKAwQCARIDRggdCl4KBAQCAgASA0kC
HxpRIFJlcXVpcmVkLiBUaGUgc2VyaWFsaXplZCBwYXlsb2FkIHRoYXQgaXMgdmVyaWZpZWQg
Ynkgb25lIG9yIG1vcmUKIGBzaWduYXR1cmVzYC4KCgwKBQQCAgAFEgNJAgcKDAoFBAICAAES
A0kIGgoMCgUEAgIAAxIDSR0eCqYCCgQEAgIBEgNOAiQamAIgT25lIG9yIG1vcmUgc2lnbmF0
dXJlcyBvdmVyIGBzZXJpYWxpemVkX3BheWxvYWRgLiAgVmVyaWZpZXIgaW1wbGVtZW50YXRp
b25zCiBzaG91bGQgY29uc2lkZXIgdGhpcyBhdHRlc3RhdGlvbiBtZXNzYWdlIHZlcmlmaWVk
IGlmIGF0IGxlYXN0IG9uZQogYHNpZ25hdHVyZWAgdmVyaWZpZXMgYHNlcmlhbGl6ZWRfcGF5
bG9hZGAuICBTZWUgYFNpZ25hdHVyZWAgaW4gY29tbW9uLnByb3RvCiBmb3IgbW9yZSBkZXRh
aWxzIG9uIHNpZ25hdHVyZSBzdHJ1Y3R1cmUgYW5kIHZlcmlmaWNhdGlvbi4KCgwKBQQCAgEE
EgNOAgoKDAoFBAICAQYSA04LFAoMCgUEAgIBARIDThUfCgwKBQQCAgEDEgNOIiMKmwQKBAQC
AgISA1gCGBqNBCBPbmUgb3IgbW9yZSBKV1RzIGVuY29kaW5nIGEgc2VsZi1jb250YWluZWQg
YXR0ZXN0YXRpb24uCiBFYWNoIEpXVCBlbmNvZGVzIHRoZSBwYXlsb2FkIHRoYXQgaXQgdmVy
aWZpZXMgd2l0aGluIHRoZSBKV1QgaXRzZWxmLgogVmVyaWZpZXIgaW1wbGVtZW50YXRpb24g
U0hPVUxEIGlnbm9yZSB0aGUgYHNlcmlhbGl6ZWRfcGF5bG9hZGAgZmllbGQKIHdoZW4gdmVy
aWZ5aW5nIHRoZXNlIEpXVHMuCiBJZiBvbmx5IEpXVHMgYXJlIHByZXNlbnQgb24gdGhpcyBB
dHRlc3RhdGlvbk9jY3VycmVuY2UsIHRoZW4gdGhlCiBgc2VyaWFsaXplZF9wYXlsb2FkYCBT
SE9VTEQgYmUgbGVmdCBlbXB0eS4KIEVhY2ggSldUIFNIT1VMRCBlbmNvZGUgYSBjbGFpbSBz
cGVjaWZpYyB0byB0aGUgYHJlc291cmNlX3VyaWAgb2YgdGhpcwogT2NjdXJyZW5jZSwgYnV0
IHRoaXMgaXMgbm90IHZhbGlkYXRlZCBieSBHcmFmZWFzIG1ldGFkYXRhIEFQSQogaW1wbGVt
ZW50YXRpb25zLiAgVGhlIEpXVCBpdHNlbGYgaXMgb3BhcXVlIHRvIEdyYWZlYXMuCgoMCgUE
AgICBBIDWAIKCgwKBQQCAgIGEgNYCw4KDAoFBAICAgESA1gPEwoMCgUEAgICAxIDWBYXYgZw
cm90bzM=
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Grafeas::V1::Attestation::AttestationNote ===
    # Fields for AttestationNote
    # Field: hint Type: 11 (.grafeas.v1.AttestationNote.Hint)

# === Message: Grafeas::V1::Attestation::Jwt ===
    # Fields for Jwt
    # Field: compact_jwt Type: 9 ()

# === Message: Grafeas::V1::Attestation::AttestationOccurrence ===
    # Fields for AttestationOccurrence
    # Field: serialized_payload Type: 12 ()
    # Field: signatures Type: 11 (.grafeas.v1.Signature)
    # Field: jwts Type: 11 (.grafeas.v1.Jwt)

1;

__END__

=encoding UTF-8

=head1 NAME

Grafeas::V1::Attestation - Compiled Protocol Buffers messages for grafeas/v1/attestation.proto

=head1 SYNOPSIS

    use Grafeas::V1::Attestation;

    my $msg = Grafeas::V1::Attestation::AttestationNote->new({
        hint => $hint,
    });

    # Read or update a field
    my $val = $msg->hint();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Grafeas::V1::Attestation::AttestationNote->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<grafeas/v1/attestation.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Grafeas::V1::Attestation::AttestationNote

Note kind that represents a logical attestation "role" or "authority". For
example, an organization might have one `Authority` for "QA" and one for
"build". This note is intended to act strictly as a grouping mechanism for
the attached occurrences (Attestations). This grouping mechanism also
provides a security boundary, since IAM ACLs gate the ability for a principle
to attach an occurrence to a given note. It also provides a single point of
lookup to find all attached attestation occurrences, even if they don't all
live in the same project.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->hint() >> / C<< $msg->hint($value) >>

Type: C<Message> (L<Grafeas::V1::Attestation::AttestationNote::Hint>)

Hint hints at the purpose of the attestation authority.

=back

=head2 Grafeas::V1::Attestation::Jwt

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->compact_jwt() >> / C<< $msg->compact_jwt($value) >>

Type: C<String>

The compact encoding of a JWS, which is always three base64 encoded strings
joined by periods. For details, see:
https://tools.ietf.org/html/rfc7515.html#section-3.1

=back

=head2 Grafeas::V1::Attestation::AttestationOccurrence

Occurrence that represents a single "attestation". The authenticity of an
attestation can be verified using the attached signature. If the verifier
trusts the public key of the signer, then verifying the signature is
sufficient to establish trust. In this circumstance, the authority to which
this attestation is attached is primarily useful for lookup (how to find
this attestation if you already know the authority and artifact to be
verified) and intent (for which authority this attestation was intended to
sign.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->serialized_payload() >> / C<< $msg->serialized_payload($value) >>

Type: C<Bytes>

Required. The serialized payload that is verified by one or more
`signatures`.

=item * C<< $msg->signatures() >> / C<< $msg->signatures($value) >>

Type: C<Message> (L<Grafeas::V1::Common::Signature>)

One or more signatures over `serialized_payload`.  Verifier implementations
should consider this attestation message verified if at least one
`signature` verifies `serialized_payload`.  See `Signature` in common.proto
for more details on signature structure and verification.

=item * C<< $msg->jwts() >> / C<< $msg->jwts($value) >>

Type: C<Message> (L<Grafeas::V1::Attestation::Jwt>)

One or more JWTs encoding a self-contained attestation.
Each JWT encodes the payload that it verifies within the JWT itself.
Verifier implementation SHOULD ignore the `serialized_payload` field
when verifying these JWTs.
If only JWTs are present on this AttestationOccurrence, then the
`serialized_payload` SHOULD be left empty.
Each JWT SHOULD encode a claim specific to the `resource_uri` of this
Occurrence, but this is not validated by Grafeas metadata API
implementations.  The JWT itself is opaque to Grafeas.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Grafeas::V1::Attestation::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
