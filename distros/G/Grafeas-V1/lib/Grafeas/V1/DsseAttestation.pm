package Grafeas::V1::DsseAttestation;

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
CiFncmFmZWFzL3YxL2Rzc2VfYXR0ZXN0YXRpb24ucHJvdG8SCmdyYWZlYXMudjEaF2dyYWZl
YXMvdjEvY29tbW9uLnByb3RvGiFncmFmZWFzL3YxL2ludG90b19zdGF0ZW1lbnQucHJvdG8i
jwEKE0RTU0VBdHRlc3RhdGlvbk5vdGUSPAoEaGludBgBIAEoCzIoLmdyYWZlYXMudjEuRFNT
RUF0dGVzdGF0aW9uTm90ZS5EU1NFSGludFIEaGludBo6CghEU1NFSGludBIuChNodW1hbl9y
ZWFkYWJsZV9uYW1lGAEgASgJUhFodW1hblJlYWRhYmxlTmFtZSKdAQoZRFNTRUF0dGVzdGF0
aW9uT2NjdXJyZW5jZRIwCghlbnZlbG9wZRgBIAEoCzIULmdyYWZlYXMudjEuRW52ZWxvcGVS
CGVudmVsb3BlEjsKCXN0YXRlbWVudBgCIAEoCzIbLmdyYWZlYXMudjEuSW5Ub3RvU3RhdGVt
ZW50SABSCXN0YXRlbWVudEIRCg9kZWNvZGVkX3BheWxvYWRCUQoNaW8uZ3JhZmVhcy52MVAB
Wjhnb29nbGUuZ29sYW5nLm9yZy9nZW5wcm90by9nb29nbGVhcGlzL2dyYWZlYXMvdjE7Z3Jh
ZmVhc6ICA0dSQUrkDgoGEgQNADMBCtoECgEMEgMNABIazwQgQ29weXJpZ2h0IDIwMjEgVGhl
IEdyYWZlYXMgQXV0aG9ycy4gQWxsIHJpZ2h0cyByZXNlcnZlZC4KCiBMaWNlbnNlZCB1bmRl
ciB0aGUgQXBhY2hlIExpY2Vuc2UsIFZlcnNpb24gMi4wICh0aGUgIkxpY2Vuc2UiKTsKIHlv
dSBtYXkgbm90IHVzZSB0aGlzIGZpbGUgZXhjZXB0IGluIGNvbXBsaWFuY2Ugd2l0aCB0aGUg
TGljZW5zZS4KIFlvdSBtYXkgb2J0YWluIGEgY29weSBvZiB0aGUgTGljZW5zZSBhdAoKICAg
IGh0dHA6Ly93d3cuYXBhY2hlLm9yZy9saWNlbnNlcy9MSUNFTlNFLTIuMAoKIFVubGVzcyBy
ZXF1aXJlZCBieSBhcHBsaWNhYmxlIGxhdyBvciBhZ3JlZWQgdG8gaW4gd3JpdGluZywgc29m
dHdhcmUKIGRpc3RyaWJ1dGVkIHVuZGVyIHRoZSBMaWNlbnNlIGlzIGRpc3RyaWJ1dGVkIG9u
IGFuICJBUyBJUyIgQkFTSVMsCiBXSVRIT1VUIFdBUlJBTlRJRVMgT1IgQ09ORElUSU9OUyBP
RiBBTlkgS0lORCwgZWl0aGVyIGV4cHJlc3Mgb3IgaW1wbGllZC4KIFNlZSB0aGUgTGljZW5z
ZSBmb3IgdGhlIHNwZWNpZmljIGxhbmd1YWdlIGdvdmVybmluZyBwZXJtaXNzaW9ucyBhbmQK
IGxpbWl0YXRpb25zIHVuZGVyIHRoZSBMaWNlbnNlLgoKCAoBAhIDDwATCgkKAgMAEgMRACEK
CQoCAwESAxIAKwoICgEIEgMUAE8KCQoCCAsSAxQATwoICgEIEgMVACIKCQoCCAoSAxUAIgoI
CgEIEgMWACYKCQoCCAESAxYAJgoICgEIEgMXACEKCQoCCCQSAxcAIQoKCgIEABIEGQAoAQoK
CgMEAAESAxkIGwrWAwoEBAADABIEIQIlAxrHAyBUaGlzIHN1Ym1lc3NhZ2UgcHJvdmlkZXMg
aHVtYW4tcmVhZGFibGUgaGludHMgYWJvdXQgdGhlIHB1cnBvc2Ugb2YgdGhlCiBhdXRob3Jp
dHkuIEJlY2F1c2UgdGhlIG5hbWUgb2YgYSBub3RlIGFjdHMgYXMgaXRzIHJlc291cmNlIHJl
ZmVyZW5jZSwgaXQgaXMKIGltcG9ydGFudCB0byBkaXNhbWJpZ3VhdGUgdGhlIGNhbm9uaWNh
bCBuYW1lIG9mIHRoZSBOb3RlICh3aGljaCBtaWdodCBiZSBhCiBVVUlEIGZvciBzZWN1cml0
eSBwdXJwb3NlcykgZnJvbSAicmVhZGFibGUiIG5hbWVzIG1vcmUgc3VpdGFibGUgZm9yIGRl
YnVnCiBvdXRwdXQuIE5vdGUgdGhhdCB0aGVzZSBoaW50cyBzaG91bGQgbm90IGJlIHVzZWQg
dG8gbG9vayB1cCBhdXRob3JpdGllcyBpbgogc2VjdXJpdHkgc2Vuc2l0aXZlIGNvbnRleHRz
LCBzdWNoIGFzIHdoZW4gbG9va2luZyB1cCBhdHRlc3RhdGlvbnMgdG8KIHZlcmlmeS4KCgwK
BQQAAwABEgMhChIKcQoGBAADAAIAEgMkBCMaYiBSZXF1aXJlZC4gVGhlIGh1bWFuIHJlYWRh
YmxlIG5hbWUgb2YgdGhpcyBhdHRlc3RhdGlvbiBhdXRob3JpdHksIGZvcgogZXhhbXBsZSAi
Y2xvdWRidWlsZC1wcm9kIi4KCg4KBwQAAwACAAUSAyQECgoOCgcEAAMAAgABEgMkCx4KDgoH
BAADAAIAAxIDJCEiCkoKBAQAAgASAycCFBo9IERTU0VIaW50IGhpbnRzIGF0IHRoZSBwdXJw
b3NlIG9mIHRoZSBhdHRlc3RhdGlvbiBhdXRob3JpdHkuCgoMCgUEAAIABhIDJwIKCgwKBQQA
AgABEgMnCw8KDAoFBAACAAMSAycSEwp8CgIEARIELAAzARpwIERlcHJlY2F0ZWQuIFByZWZl
ciB0byB1c2UgYSByZWd1bGFyIE9jY3VycmVuY2UsIGFuZCBwb3B1bGF0ZSB0aGUKIEVudmVs
b3BlIGF0IHRoZSB0b3AgbGV2ZWwgb2YgdGhlIE9jY3VycmVuY2UuCgoKCgMEAQESAywIIQpq
CgQEAQIAEgMvAhgaXSBJZiBkb2luZyBzb21ldGhpbmcgc2VjdXJpdHkgY3JpdGljYWwsIG1h
a2Ugc3VyZSB0byB2ZXJpZnkgdGhlIHNpZ25hdHVyZXMgaW4KIHRoaXMgbWV0YWRhdGEuCgoM
CgUEAQIABhIDLwIKCgwKBQQBAgABEgMvCxMKDAoFBAECAAMSAy8WFwoMCgQEAQgAEgQwAjID
CgwKBQQBCAABEgMwCBcKCwoEBAECARIDMQQiCgwKBQQBAgEGEgMxBBMKDAoFBAECAQESAzEU
HQoMCgUEAQIBAxIDMSAhYgZwcm90bzM=
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Grafeas::V1::DsseAttestation::DSSEAttestationNote ===
    # Fields for DSSEAttestationNote
    # Field: hint Type: 11 (.grafeas.v1.DSSEAttestationNote.DSSEHint)

# === Message: Grafeas::V1::DsseAttestation::DSSEAttestationOccurrence ===
    # Fields for DSSEAttestationOccurrence
    # Field: envelope Type: 11 (.grafeas.v1.Envelope)
    # Field: statement Type: 11 (.grafeas.v1.InTotoStatement)

1;

__END__

=encoding UTF-8

=head1 NAME

Grafeas::V1::DsseAttestation - Compiled Protocol Buffers messages for grafeas/v1/dsse_attestation.proto

=head1 SYNOPSIS

    use Grafeas::V1::DsseAttestation;

    my $msg = Grafeas::V1::DsseAttestation::DSSEAttestationNote->new({
        hint => $hint,
    });

    # Read or update a field
    my $val = $msg->hint();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Grafeas::V1::DsseAttestation::DSSEAttestationNote->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<grafeas/v1/dsse_attestation.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Grafeas::V1::DsseAttestation::DSSEAttestationNote

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->hint() >> / C<< $msg->hint($value) >>

Type: C<Message> (L<Grafeas::V1::DsseAttestation::DSSEAttestationNote::DSSEHint>)

DSSEHint hints at the purpose of the attestation authority.

=back

=head2 Grafeas::V1::DsseAttestation::DSSEAttestationOccurrence

Deprecated. Prefer to use a regular Occurrence, and populate the
Envelope at the top level of the Occurrence.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->envelope() >> / C<< $msg->envelope($value) >>

Type: C<Message> (L<Grafeas::V1::Common::Envelope>)

If doing something security critical, make sure to verify the signatures in
this metadata.

=item * C<< $msg->statement() >> / C<< $msg->statement($value) >>

Type: C<Message> (L<Grafeas::V1::IntotoStatement::InTotoStatement>)

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Grafeas::V1::DsseAttestation::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
