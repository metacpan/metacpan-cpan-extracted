package Grafeas::V1::Sbom;

use strict;
use warnings;

our $VERSION = '0.14';

use Protobuf::Message;
use Protobuf::DescriptorPool;
use Protobuf::Internal qw(:all);
use MIME::Base64;

BEGIN {
    eval { require Grafeas::V1::Common };
    eval { require Grafeas::V1::IntotoStatement };
    my $descriptor_b64 = <<'EOF';
ChVncmFmZWFzL3YxL3Nib20ucHJvdG8SCmdyYWZlYXMudjEaF2dyYWZlYXMvdjEvY29tbW9u
LnByb3RvGiFncmFmZWFzL3YxL2ludG90b19zdGF0ZW1lbnQucHJvdG8iRQoRU0JPTVJlZmVy
ZW5jZU5vdGUSFgoGZm9ybWF0GAEgASgJUgZmb3JtYXQSGAoHdmVyc2lvbhgCIAEoCVIHdmVy
c2lvbiK9AQoXU0JPTVJlZmVyZW5jZU9jY3VycmVuY2USQAoHcGF5bG9hZBgBIAEoCzImLmdy
YWZlYXMudjEuU2JvbVJlZmVyZW5jZUludG90b1BheWxvYWRSB3BheWxvYWQSIQoMcGF5bG9h
ZF90eXBlGAIgASgJUgtwYXlsb2FkVHlwZRI9CgpzaWduYXR1cmVzGAMgAygLMh0uZ3JhZmVh
cy52MS5FbnZlbG9wZVNpZ25hdHVyZVIKc2lnbmF0dXJlcyLPAQoaU2JvbVJlZmVyZW5jZUlu
dG90b1BheWxvYWQSEwoEdHlwZRgBIAEoCVIFX3R5cGUSJQoOcHJlZGljYXRlX3R5cGUYAiAB
KAlSDXByZWRpY2F0ZVR5cGUSLQoHc3ViamVjdBgDIAMoCzITLmdyYWZlYXMudjEuU3ViamVj
dFIHc3ViamVjdBJGCglwcmVkaWNhdGUYBCABKAsyKC5ncmFmZWFzLnYxLlNib21SZWZlcmVu
Y2VJbnRvdG9QcmVkaWNhdGVSCXByZWRpY2F0ZSKBAgocU2JvbVJlZmVyZW5jZUludG90b1By
ZWRpY2F0ZRIfCgtyZWZlcnJlcl9pZBgBIAEoCVIKcmVmZXJyZXJJZBIaCghsb2NhdGlvbhgC
IAEoCVIIbG9jYXRpb24SGwoJbWltZV90eXBlGAMgASgJUghtaW1lVHlwZRJMCgZkaWdlc3QY
BCADKAsyNC5ncmFmZWFzLnYxLlNib21SZWZlcmVuY2VJbnRvdG9QcmVkaWNhdGUuRGlnZXN0
RW50cnlSBmRpZ2VzdBo5CgtEaWdlc3RFbnRyeRIQCgNrZXkYASABKAlSA2tleRIUCgV2YWx1
ZRgCIAEoCVIFdmFsdWU6AjgBQlEKDWlvLmdyYWZlYXMudjFQAVo4Z29vZ2xlLmdvbGFuZy5v
cmcvZ2VucHJvdG8vZ29vZ2xlYXBpcy9ncmFmZWFzL3YxO2dyYWZlYXOiAgNHUkFK8xcKBhIE
DgBNAQraBAoBDBIDDgASMs8EIENvcHlyaWdodCAyMDIzIFRoZSBHcmFmZWFzIEF1dGhvcnMu
IEFsbCByaWdodHMgcmVzZXJ2ZWQuCgogTGljZW5zZWQgdW5kZXIgdGhlIEFwYWNoZSBMaWNl
bnNlLCBWZXJzaW9uIDIuMCAodGhlICJMaWNlbnNlIik7CiB5b3UgbWF5IG5vdCB1c2UgdGhp
cyBmaWxlIGV4Y2VwdCBpbiBjb21wbGlhbmNlIHdpdGggdGhlIExpY2Vuc2UuCiBZb3UgbWF5
IG9idGFpbiBhIGNvcHkgb2YgdGhlIExpY2Vuc2UgYXQKCiAgICBodHRwOi8vd3d3LmFwYWNo
ZS5vcmcvbGljZW5zZXMvTElDRU5TRS0yLjAKCiBVbmxlc3MgcmVxdWlyZWQgYnkgYXBwbGlj
YWJsZSBsYXcgb3IgYWdyZWVkIHRvIGluIHdyaXRpbmcsIHNvZnR3YXJlCiBkaXN0cmlidXRl
ZCB1bmRlciB0aGUgTGljZW5zZSBpcyBkaXN0cmlidXRlZCBvbiBhbiAiQVMgSVMiIEJBU0lT
LAogV0lUSE9VVCBXQVJSQU5USUVTIE9SIENPTkRJVElPTlMgT0YgQU5ZIEtJTkQsIGVpdGhl
ciBleHByZXNzIG9yIGltcGxpZWQuCiBTZWUgdGhlIExpY2Vuc2UgZm9yIHRoZSBzcGVjaWZp
YyBsYW5ndWFnZSBnb3Zlcm5pbmcgcGVybWlzc2lvbnMgYW5kCiBsaW1pdGF0aW9ucyB1bmRl
ciB0aGUgTGljZW5zZS4KCggKAQISAxAAEwoJCgIDABIDEgAhCgkKAgMBEgMTACsKCAoBCBID
FQBPCgkKAggLEgMVAE8KCAoBCBIDFgAiCgkKAggKEgMWACIKCAoBCBIDFwAmCgkKAggBEgMX
ACYKCAoBCBIDGAAhCgkKAggkEgMYACEKNgoCBAASBBsAIQEaKiBUaGUgbm90ZSByZXByZXNl
bnRpbmcgYW4gU0JPTSByZWZlcmVuY2UuCgoKCgMEAAESAxsIGQpOCgQEAAIAEgMdAhQaQSBU
aGUgZm9ybWF0IHRoYXQgU0JPTSB0YWtlcy4gRS5nLiBtYXkgYmUgc3BkeCwgY3ljbG9uZWR4
LCBldGMuLi4KCgwKBQQAAgAFEgMdAggKDAoFBAACAAESAx0JDwoMCgUEAAIAAxIDHRITCnIK
BAQAAgESAyACFRplIFRoZSB2ZXJzaW9uIG9mIHRoZSBmb3JtYXQgdGhhdCB0aGUgU0JPTSB0
YWtlcy4gRS5nLiBpZiB0aGUgZm9ybWF0CiBpcyBzcGR4LCB0aGUgdmVyc2lvbiBtYXkgYmUg
Mi4zLgoKDAoFBAACAQUSAyACCAoMCgUEAAIBARIDIAkQCgwKBQQAAgEDEgMgExQK6gEKAgQB
EgQnADABGt0BIFRoZSBvY2N1cnJlbmNlIHJlcHJlc2VudGluZyBhbiBTQk9NIHJlZmVyZW5j
ZSBhcyBhcHBsaWVkIHRvIGEgc3BlY2lmaWMKIHJlc291cmNlLiBUaGUgb2NjdXJyZW5jZSBm
b2xsb3dzIHRoZSBEU1NFIHNwZWNpZmljYXRpb24uIFNlZQogaHR0cHM6Ly9naXRodWIuY29t
L3NlY3VyZS1zeXN0ZW1zLWxhYi9kc3NlL2Jsb2IvbWFzdGVyL2VudmVsb3BlLm1kIGZvciBt
b3JlCiBkZXRhaWxzLgoKCgoDBAEBEgMnCB8KSAoEBAECABIDKQIpGjsgVGhlIGFjdHVhbCBw
YXlsb2FkIHRoYXQgY29udGFpbnMgdGhlIFNCT00gcmVmZXJlbmNlIGRhdGEuCgoMCgUEAQIA
BhIDKQIcCgwKBQQBAgABEgMpHSQKDAoFBAECAAMSAyknKAqqAQoEBAECARIDLQIaGpwBIFRo
ZSBraW5kIG9mIHBheWxvYWQgdGhhdCBTYm9tUmVmZXJlbmNlSW50b3RvUGF5bG9hZCB0YWtl
cy4gU2luY2UgaXQncyBpbgogdGhlIGludG90byBmb3JtYXQsIHRoaXMgdmFsdWUgaXMgZXhw
ZWN0ZWQgdG8gYmUKICdhcHBsaWNhdGlvbi92bmQuaW4tdG90bytqc29uJy4KCgwKBQQBAgEF
EgMtAggKDAoFBAECAQESAy0JFQoMCgUEAQIBAxIDLRgZCi8KBAQBAgISAy8CLBoiIFRoZSBz
aWduYXR1cmVzIG92ZXIgdGhlIHBheWxvYWQuCgoMCgUEAQICBBIDLwIKCgwKBQQBAgIGEgMv
CxwKDAoFBAECAgESAy8dJwoMCgUEAQICAxIDLyorCuEBCgIEAhIENgBBARrUASBUaGUgYWN0
dWFsIHBheWxvYWQgdGhhdCBjb250YWlucyB0aGUgU0JPTSBSZWZlcmVuY2UgZGF0YS4KIFRo
ZSBwYXlsb2FkIGZvbGxvd3MgdGhlIGludG90byBzdGF0ZW1lbnQgc3BlY2lmaWNhdGlvbi4g
U2VlCiBodHRwczovL2dpdGh1Yi5jb20vaW4tdG90by9hdHRlc3RhdGlvbi9ibG9iL21haW4v
c3BlYy92MS4wL3N0YXRlbWVudC5tZAogZm9yIG1vcmUgZGV0YWlscy4KCgoKAwQCARIDNggi
CjoKBAQCAgASAzgCKBotIElkZW50aWZpZXIgZm9yIHRoZSBzY2hlbWEgb2YgdGhlIFN0YXRl
bWVudC4KCgwKBQQCAgAFEgM4AggKDAoFBAICAAESAzgJDQoMCgUEAgIAAxIDOBARCgwKBQQC
AgAIEgM4EicKDAoFBAICAAoSAzgTJgoMCgUEAgIAChIDOB8mCjkKBAQCAgESAzoCHBosIFVS
SSBpZGVudGlmeWluZyB0aGUgdHlwZSBvZiB0aGUgUHJlZGljYXRlLgoKDAoFBAICAQUSAzoC
CAoMCgUEAgIBARIDOgkXCgwKBQQCAgEDEgM6GhsKfgoEBAICAhIDPQIfGnEgU2V0IG9mIHNv
ZnR3YXJlIGFydGlmYWN0cyB0aGF0IHRoZSBhdHRlc3RhdGlvbiBhcHBsaWVzIHRvLiBFYWNo
IGVsZW1lbnQKIHJlcHJlc2VudHMgYSBzaW5nbGUgc29mdHdhcmUgYXJ0aWZhY3QuCgoMCgUE
AgICBBIDPQIKCgwKBQQCAgIGEgM9CxIKDAoFBAICAgESAz0TGgoMCgUEAgICAxIDPR0eCmAK
BAQCAgMSA0ACLRpTIEFkZGl0aW9uYWwgcGFyYW1ldGVycyBvZiB0aGUgUHJlZGljYXRlLiBJ
bmNsdWRlcyB0aGUgYWN0dWFsIGRhdGEgYWJvdXQgdGhlCiBTQk9NLgoKDAoFBAICAwYSA0AC
HgoMCgUEAgIDARIDQB8oCgwKBQQCAgMDEgNAKywKRAoCBAMSBEQATQEaOCBBIHByZWRpY2F0
ZSB3aGljaCBkZXNjcmliZXMgdGhlIFNCT00gYmVpbmcgcmVmZXJlbmNlZC4KCgoKAwQDARID
RAgkCk0KBAQDAgASA0YCGRpAIFRoZSBwZXJzb24gb3Igc3lzdGVtIHJlZmVycmluZyB0aGlz
IHByZWRpY2F0ZSB0byB0aGUgY29uc3VtZXIuCgoMCgUEAwIABRIDRgIICgwKBQQDAgABEgNG
CRQKDAoFBAMCAAMSA0YXGAooCgQEAwIBEgNIAhYaGyBUaGUgbG9jYXRpb24gb2YgdGhlIFNC
T00uCgoMCgUEAwIBBRIDSAIICgwKBQQDAgEBEgNICREKDAoFBAMCAQMSA0gUFQopCgQEAwIC
EgNKAhcaHCBUaGUgbWltZSB0eXBlIG9mIHRoZSBTQk9NLgoKDAoFBAMCAgUSA0oCCAoMCgUE
AwICARIDSgkSCgwKBQQDAgIDEgNKFRYKSAoEBAMCAxIDTAIhGjsgQSBtYXAgb2YgYWxnb3Jp
dGhtIHRvIGRpZ2VzdCBvZiB0aGUgY29udGVudHMgb2YgdGhlIFNCT00uCgoMCgUEAwIDBhID
TAIVCgwKBQQDAgMBEgNMFhwKDAoFBAMCAwMSA0wfIGIGcHJvdG8z
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Grafeas::V1::Sbom::SBOMReferenceNote ===
    # Fields for SBOMReferenceNote
    # Field: format Type: 9 ()
    # Field: version Type: 9 ()

# === Message: Grafeas::V1::Sbom::SBOMReferenceOccurrence ===
    # Fields for SBOMReferenceOccurrence
    # Field: payload Type: 11 (.grafeas.v1.SbomReferenceIntotoPayload)
    # Field: payload_type Type: 9 ()
    # Field: signatures Type: 11 (.grafeas.v1.EnvelopeSignature)

# === Message: Grafeas::V1::Sbom::SbomReferenceIntotoPayload ===
    # Fields for SbomReferenceIntotoPayload
    # Field: type Type: 9 ()
    # Field: predicate_type Type: 9 ()
    # Field: subject Type: 11 (.grafeas.v1.Subject)
    # Field: predicate Type: 11 (.grafeas.v1.SbomReferenceIntotoPredicate)

# === Message: Grafeas::V1::Sbom::SbomReferenceIntotoPredicate ===
    # Fields for SbomReferenceIntotoPredicate
    # Field: referrer_id Type: 9 ()
    # Field: location Type: 9 ()
    # Field: mime_type Type: 9 ()
    # Field: digest Type: 11 (.grafeas.v1.SbomReferenceIntotoPredicate.DigestEntry)

1;

__END__

=encoding UTF-8

=head1 NAME

Grafeas::V1::Sbom - Compiled Protocol Buffers messages for grafeas/v1/sbom.proto

=head1 SYNOPSIS

    use Grafeas::V1::Sbom;

    my $msg = Grafeas::V1::Sbom::SBOMReferenceNote->new({
        format => $format,
        version => $version,
    });

    # Read or update a field
    my $val = $msg->format();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Grafeas::V1::Sbom::SBOMReferenceNote->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<grafeas/v1/sbom.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Grafeas::V1::Sbom::SBOMReferenceNote

The note representing an SBOM reference.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->format() >> / C<< $msg->format($value) >>

Type: C<String>

The format that SBOM takes. E.g. may be spdx, cyclonedx, etc...

=item * C<< $msg->version() >> / C<< $msg->version($value) >>

Type: C<String>

The version of the format that the SBOM takes. E.g. if the format
is spdx, the version may be 2.3.

=back

=head2 Grafeas::V1::Sbom::SBOMReferenceOccurrence

The occurrence representing an SBOM reference as applied to a specific
resource. The occurrence follows the DSSE specification. See
https://github.com/secure-systems-lab/dsse/blob/master/envelope.md for more
details.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->payload() >> / C<< $msg->payload($value) >>

Type: C<Message> (L<Grafeas::V1::Sbom::SbomReferenceIntotoPayload>)

The actual payload that contains the SBOM reference data.

=item * C<< $msg->payload_type() >> / C<< $msg->payload_type($value) >>

Type: C<String>

The kind of payload that SbomReferenceIntotoPayload takes. Since it's in
the intoto format, this value is expected to be
'application/vnd.in-toto+json'.

=item * C<< $msg->signatures() >> / C<< $msg->signatures($value) >>

Type: C<Message> (L<Grafeas::V1::Common::EnvelopeSignature>)

The signatures over the payload.

=back

=head2 Grafeas::V1::Sbom::SbomReferenceIntotoPayload

The actual payload that contains the SBOM Reference data.
The payload follows the intoto statement specification. See
https://github.com/in-toto/attestation/blob/main/spec/v1.0/statement.md
for more details.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->type() >> / C<< $msg->type($value) >>

Type: C<String>

Identifier for the schema of the Statement.

=item * C<< $msg->predicate_type() >> / C<< $msg->predicate_type($value) >>

Type: C<String>

URI identifying the type of the Predicate.

=item * C<< $msg->subject() >> / C<< $msg->subject($value) >>

Type: C<Message> (L<Grafeas::V1::IntotoStatement::Subject>)

Set of software artifacts that the attestation applies to. Each element
represents a single software artifact.

=item * C<< $msg->predicate() >> / C<< $msg->predicate($value) >>

Type: C<Message> (L<Grafeas::V1::Sbom::SbomReferenceIntotoPredicate>)

Additional parameters of the Predicate. Includes the actual data about the
SBOM.

=back

=head2 Grafeas::V1::Sbom::SbomReferenceIntotoPredicate

A predicate which describes the SBOM being referenced.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->referrer_id() >> / C<< $msg->referrer_id($value) >>

Type: C<String>

The person or system referring this predicate to the consumer.

=item * C<< $msg->location() >> / C<< $msg->location($value) >>

Type: C<String>

The location of the SBOM.

=item * C<< $msg->mime_type() >> / C<< $msg->mime_type($value) >>

Type: C<String>

The mime type of the SBOM.

=item * C<< $msg->digest() >> / C<< $msg->digest($value) >>

Type: C<Message> (L<Grafeas::V1::Sbom::SbomReferenceIntotoPredicate::DigestEntry>)

A map of algorithm to digest of the contents of the SBOM.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Grafeas::V1::Sbom::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
