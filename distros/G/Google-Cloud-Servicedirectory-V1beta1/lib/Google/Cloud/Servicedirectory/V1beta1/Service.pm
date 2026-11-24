package Google::Cloud::Servicedirectory::V1beta1::Service;

use strict;
use warnings;

our $VERSION = '0.14';

use Protobuf::Message;
use Protobuf::DescriptorPool;
use Protobuf::Internal qw(:all);
use MIME::Base64;

BEGIN {
    eval { require Google::Api::FieldBehavior };
    eval { require Google::Api::Resource };
    eval { require Google::Cloud::Servicedirectory::V1beta1::Endpoint };
    eval { require Google::Protobuf::Timestamp };
    my $descriptor_b64 = <<'EOF';
CjNnb29nbGUvY2xvdWQvc2VydmljZWRpcmVjdG9yeS92MWJldGExL3NlcnZpY2UucHJvdG8S
JWdvb2dsZS5jbG91ZC5zZXJ2aWNlZGlyZWN0b3J5LnYxYmV0YTEaH2dvb2dsZS9hcGkvZmll
bGRfYmVoYXZpb3IucHJvdG8aGWdvb2dsZS9hcGkvcmVzb3VyY2UucHJvdG8aNGdvb2dsZS9j
bG91ZC9zZXJ2aWNlZGlyZWN0b3J5L3YxYmV0YTEvZW5kcG9pbnQucHJvdG8aH2dvb2dsZS9w
cm90b2J1Zi90aW1lc3RhbXAucHJvdG8irgQKB1NlcnZpY2USFwoEbmFtZRgBIAEoCUID4EEF
UgRuYW1lEl0KCG1ldGFkYXRhGAIgAygLMjwuZ29vZ2xlLmNsb3VkLnNlcnZpY2VkaXJlY3Rv
cnkudjFiZXRhMS5TZXJ2aWNlLk1ldGFkYXRhRW50cnlCA+BBAVIIbWV0YWRhdGESUgoJZW5k
cG9pbnRzGAMgAygLMi8uZ29vZ2xlLmNsb3VkLnNlcnZpY2VkaXJlY3RvcnkudjFiZXRhMS5F
bmRwb2ludEID4EEDUgllbmRwb2ludHMSQAoLY3JlYXRlX3RpbWUYBiABKAsyGi5nb29nbGUu
cHJvdG9idWYuVGltZXN0YW1wQgPgQQNSCmNyZWF0ZVRpbWUSQAoLdXBkYXRlX3RpbWUYByAB
KAsyGi5nb29nbGUucHJvdG9idWYuVGltZXN0YW1wQgPgQQNSCnVwZGF0ZVRpbWUSFQoDdWlk
GAggASgJQgPgQQNSA3VpZBo7Cg1NZXRhZGF0YUVudHJ5EhAKA2tleRgBIAEoCVIDa2V5EhQK
BXZhbHVlGAIgASgJUgV2YWx1ZToCOAE6f+pBfAonc2VydmljZWRpcmVjdG9yeS5nb29nbGVh
cGlzLmNvbS9TZXJ2aWNlElFwcm9qZWN0cy97cHJvamVjdH0vbG9jYXRpb25zL3tsb2NhdGlv
bn0vbmFtZXNwYWNlcy97bmFtZXNwYWNlfS9zZXJ2aWNlcy97c2VydmljZX1CjQIKKWNvbS5n
b29nbGUuY2xvdWQuc2VydmljZWRpcmVjdG9yeS52MWJldGExQgxTZXJ2aWNlUHJvdG9QAVpV
Y2xvdWQuZ29vZ2xlLmNvbS9nby9zZXJ2aWNlZGlyZWN0b3J5L2FwaXYxYmV0YTEvc2Vydmlj
ZWRpcmVjdG9yeXBiO3NlcnZpY2VkaXJlY3RvcnlwYqoCJUdvb2dsZS5DbG91ZC5TZXJ2aWNl
RGlyZWN0b3J5LlYxQmV0YTHKAiVHb29nbGVcQ2xvdWRcU2VydmljZURpcmVjdG9yeVxWMWJl
dGEx6gIoR29vZ2xlOjpDbG91ZDo6U2VydmljZURpcmVjdG9yeTo6VjFiZXRhMUqQGgoGEgQO
AFYBCrwECgEMEgMOABIysQQgQ29weXJpZ2h0IDIwMjUgR29vZ2xlIExMQwoKIExpY2Vuc2Vk
IHVuZGVyIHRoZSBBcGFjaGUgTGljZW5zZSwgVmVyc2lvbiAyLjAgKHRoZSAiTGljZW5zZSIp
OwogeW91IG1heSBub3QgdXNlIHRoaXMgZmlsZSBleGNlcHQgaW4gY29tcGxpYW5jZSB3aXRo
IHRoZSBMaWNlbnNlLgogWW91IG1heSBvYnRhaW4gYSBjb3B5IG9mIHRoZSBMaWNlbnNlIGF0
CgogICAgIGh0dHA6Ly93d3cuYXBhY2hlLm9yZy9saWNlbnNlcy9MSUNFTlNFLTIuMAoKIFVu
bGVzcyByZXF1aXJlZCBieSBhcHBsaWNhYmxlIGxhdyBvciBhZ3JlZWQgdG8gaW4gd3JpdGlu
Zywgc29mdHdhcmUKIGRpc3RyaWJ1dGVkIHVuZGVyIHRoZSBMaWNlbnNlIGlzIGRpc3RyaWJ1
dGVkIG9uIGFuICJBUyBJUyIgQkFTSVMsCiBXSVRIT1VUIFdBUlJBTlRJRVMgT1IgQ09ORElU
SU9OUyBPRiBBTlkgS0lORCwgZWl0aGVyIGV4cHJlc3Mgb3IgaW1wbGllZC4KIFNlZSB0aGUg
TGljZW5zZSBmb3IgdGhlIHNwZWNpZmljIGxhbmd1YWdlIGdvdmVybmluZyBwZXJtaXNzaW9u
cyBhbmQKIGxpbWl0YXRpb25zIHVuZGVyIHRoZSBMaWNlbnNlLgoKCAoBAhIDEAAuCgkKAgMA
EgMSACkKCQoCAwESAxMAIwoJCgIDAhIDFAA+CgkKAgMDEgMVACkKCAoBCBIDFwBCCgkKAggl
EgMXAEIKCAoBCBIDGABsCgkKAggLEgMYAGwKCAoBCBIDGQAiCgkKAggKEgMZACIKCAoBCBID
GgAtCgkKAggIEgMaAC0KCAoBCBIDGwBCCgkKAggBEgMbAEIKCAoBCBIDHABCCgkKAggpEgMc
AEIKCAoBCBIDHQBBCgkKAggtEgMdAEEKxQEKAgQAEgQjAFYBGrgBIEFuIGluZGl2aWR1YWwg
c2VydmljZS4gQSBzZXJ2aWNlIGNvbnRhaW5zIGEgbmFtZSBhbmQgb3B0aW9uYWwgbWV0YWRh
dGEuCiBBIHNlcnZpY2UgbXVzdCBleGlzdCBiZWZvcmUKIFtlbmRwb2ludHNdW2dvb2dsZS5j
bG91ZC5zZXJ2aWNlZGlyZWN0b3J5LnYxYmV0YTEuRW5kcG9pbnRdIGNhbiBiZQogYWRkZWQg
dG8gaXQuCgoKCgMEAAESAyMIDwoLCgMEAAcSBCQCJwQKDQoFBAAHnQgSBCQCJwQKfAoEBAAC
ABIDKwI8Gm8gSW1tdXRhYmxlLiBUaGUgcmVzb3VyY2UgbmFtZSBmb3IgdGhlIHNlcnZpY2Ug
aW4gdGhlIGZvcm1hdAogYHByb2plY3RzLyovbG9jYXRpb25zLyovbmFtZXNwYWNlcy8qL3Nl
cnZpY2VzLypgLgoKDAoFBAACAAUSAysCCAoMCgUEAAIAARIDKwkNCgwKBQQAAgADEgMrEBEK
DAoFBAACAAgSAysSOwoPCggEAAIACJwIABIDKxM6Cv8HCgQEAAIBEgNBAkwa8QcgT3B0aW9u
YWwuIE1ldGFkYXRhIGZvciB0aGUgc2VydmljZS4gVGhpcyBkYXRhIGNhbiBiZSBjb25zdW1l
ZCBieSBzZXJ2aWNlCiBjbGllbnRzLgoKIFJlc3RyaWN0aW9uczoKCiAqICAgVGhlIGVudGly
ZSBtZXRhZGF0YSBkaWN0aW9uYXJ5IG1heSBjb250YWluIHVwIHRvIDIwMDAgY2hhcmFjdGVy
cywKICAgICBzcHJlYWQgYWNjb3NzIGFsbCBrZXktdmFsdWUgcGFpcnMuIE1ldGFkYXRhIHRo
YXQgZ29lcyBiZXlvbmQgdGhpcwogICAgIGxpbWl0IGFyZSByZWplY3RlZAogKiAgIFZhbGlk
IG1ldGFkYXRhIGtleXMgaGF2ZSB0d28gc2VnbWVudHM6IGFuIG9wdGlvbmFsIHByZWZpeCBh
bmQgbmFtZSwKICAgICBzZXBhcmF0ZWQgYnkgYSBzbGFzaCAoLykuIFRoZSBuYW1lIHNlZ21l
bnQgaXMgcmVxdWlyZWQgYW5kIG11c3QgYmUgNjMKICAgICBjaGFyYWN0ZXJzIG9yIGxlc3Ms
IGJlZ2lubmluZyBhbmQgZW5kaW5nIHdpdGggYW4gYWxwaGFudW1lcmljIGNoYXJhY3Rlcgog
ICAgIChbYS16MC05QS1aXSkgd2l0aCBkYXNoZXMgKC0pLCB1bmRlcnNjb3JlcyAoXyksIGRv
dHMgKC4pLCBhbmQKICAgICBhbHBoYW51bWVyaWNzIGJldHdlZW4uIFRoZSBwcmVmaXggaXMg
b3B0aW9uYWwuIElmIHNwZWNpZmllZCwgdGhlIHByZWZpeAogICAgIG11c3QgYmUgYSBETlMg
c3ViZG9tYWluOiBhIHNlcmllcyBvZiBETlMgbGFiZWxzIHNlcGFyYXRlZCBieSBkb3RzICgu
KSwKICAgICBub3QgbG9uZ2VyIHRoYW4gMjUzIGNoYXJhY3RlcnMgaW4gdG90YWwsIGZvbGxv
d2VkIGJ5IGEgc2xhc2ggKC8pLgogICAgIE1ldGFkYXRhIHRoYXQgZmFpbHMgdG8gbWVldCB0
aGVzZSByZXF1aXJlbWVudHMgYXJlIHJlamVjdGVkCgogTm90ZTogVGhpcyBmaWVsZCBpcyBl
cXVpdmFsZW50IHRvIHRoZSBgYW5ub3RhdGlvbnNgIGZpZWxkIGluIHRoZSB2MSBBUEkuCiBU
aGV5IGhhdmUgdGhlIHNhbWUgc3ludGF4IGFuZCByZWFkL3dyaXRlIHRvIHRoZSBzYW1lIGxv
Y2F0aW9uIGluIFNlcnZpY2UKIERpcmVjdG9yeS4KCgwKBQQAAgEGEgNBAhUKDAoFBAACAQES
A0EWHgoMCgUEAAIBAxIDQSEiCgwKBQQAAgEIEgNBI0sKDwoIBAACAQicCAASA0EkSgrGAgoE
BAACAhIDRwJOGrgCIE91dHB1dCBvbmx5LiBFbmRwb2ludHMgYXNzb2NpYXRlZCB3aXRoIHRo
aXMgc2VydmljZS4gUmV0dXJuZWQgb24KIFtMb29rdXBTZXJ2aWNlLlJlc29sdmVTZXJ2aWNl
XVtnb29nbGUuY2xvdWQuc2VydmljZWRpcmVjdG9yeS52MWJldGExLkxvb2t1cFNlcnZpY2Uu
UmVzb2x2ZVNlcnZpY2VdLgogQ29udHJvbCBwbGFuZSBjbGllbnRzIHNob3VsZCB1c2UKIFtS
ZWdpc3RyYXRpb25TZXJ2aWNlLkxpc3RFbmRwb2ludHNdW2dvb2dsZS5jbG91ZC5zZXJ2aWNl
ZGlyZWN0b3J5LnYxYmV0YTEuUmVnaXN0cmF0aW9uU2VydmljZS5MaXN0RW5kcG9pbnRzXS4K
CgwKBQQAAgIEEgNHAgoKDAoFBAACAgYSA0cLEwoMCgUEAAICARIDRxQdCgwKBQQAAgIDEgNH
ICEKDAoFBAACAggSA0ciTQoPCggEAAICCJwIABIDRyNMCkgKBAQAAgMSBEoCSzIaOiBPdXRw
dXQgb25seS4gVGhlIHRpbWVzdGFtcCB3aGVuIHRoZSBzZXJ2aWNlIHdhcyBjcmVhdGVkLgoK
DAoFBAACAwYSA0oCGwoMCgUEAAIDARIDShwnCgwKBQQAAgMDEgNKKisKDAoFBAACAwgSA0sG
MQoPCggEAAIDCJwIABIDSwcwCtcBCgQEAAIEEgRQAlEyGsgBIE91dHB1dCBvbmx5LiBUaGUg
dGltZXN0YW1wIHdoZW4gdGhlIHNlcnZpY2Ugd2FzIGxhc3QgdXBkYXRlZC4gTm90ZToKIGVu
ZHBvaW50cyBiZWluZyBjcmVhdGVkL2RlbGV0ZWQvdXBkYXRlZCB3aXRoaW4gdGhlIHNlcnZp
Y2UgYXJlIG5vdAogY29uc2lkZXJlZCBzZXJ2aWNlIHVwZGF0ZXMgZm9yIHRoZSBwdXJwb3Nl
IG9mIHRoaXMgdGltZXN0YW1wLgoKDAoFBAACBAYSA1ACGwoMCgUEAAIEARIDUBwnCgwKBQQA
AgQDEgNQKisKDAoFBAACBAgSA1EGMQoPCggEAAIECJwIABIDUQcwCl0KBAQAAgUSA1UCPRpQ
IE91dHB1dCBvbmx5LiBBIGdsb2JhbGx5IHVuaXF1ZSBpZGVudGlmaWVyIChpbiBVVUlENCBm
b3JtYXQpIGZvciB0aGlzCiBzZXJ2aWNlLgoKDAoFBAACBQUSA1UCCAoMCgUEAAIFARIDVQkM
CgwKBQQAAgUDEgNVDxAKDAoFBAACBQgSA1URPAoPCggEAAIFCJwIABIDVRI7YgZwcm90bzM=

EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Servicedirectory::V1beta1::Service::Service ===
    # Fields for Service
    # Field: name Type: 9 ()
    # Field: metadata Type: 11 (.google.cloud.servicedirectory.v1beta1.Service.MetadataEntry)
    # Field: endpoints Type: 11 (.google.cloud.servicedirectory.v1beta1.Endpoint)
    # Field: create_time Type: 11 (.google.protobuf.Timestamp)
    # Field: update_time Type: 11 (.google.protobuf.Timestamp)
    # Field: uid Type: 9 ()

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Servicedirectory::V1beta1::Service - Compiled Protocol Buffers messages for google/cloud/servicedirectory/v1beta1/service.proto

=head1 SYNOPSIS

    use Google::Cloud::Servicedirectory::V1beta1::Service;

    my $msg = Google::Cloud::Servicedirectory::V1beta1::Service::Service->new({
        name => $name,
        metadata => $metadata,
        endpoints => $endpoints,
        create_time => $create_time,
    });

    # Read or update a field
    my $val = $msg->name();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Servicedirectory::V1beta1::Service::Service->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/servicedirectory/v1beta1/service.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Servicedirectory::V1beta1::Service::Service

An individual service. A service contains a name and optional metadata.
A service must exist before
[endpoints][google.cloud.servicedirectory.v1beta1.Endpoint] can be
added to it.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Immutable. The resource name for the service in the format
`projects/*/locations/*/namespaces/*/services/*`.

=item * C<< $msg->metadata() >> / C<< $msg->metadata($value) >>

Type: C<Message> (L<Google::Cloud::Servicedirectory::V1beta1::Service::Service::MetadataEntry>)

Optional. Metadata for the service. This data can be consumed by service
clients.

Restrictions:

*   The entire metadata dictionary may contain up to 2000 characters,
    spread accoss all key-value pairs. Metadata that goes beyond this
    limit are rejected
*   Valid metadata keys have two segments: an optional prefix and name,
    separated by a slash (/). The name segment is required and must be 63
    characters or less, beginning and ending with an alphanumeric character
    ([a-z0-9A-Z]) with dashes (-), underscores (_), dots (.), and
    alphanumerics between. The prefix is optional. If specified, the prefix
    must be a DNS subdomain: a series of DNS labels separated by dots (.),
    not longer than 253 characters in total, followed by a slash (/).
    Metadata that fails to meet these requirements are rejected

Note: This field is equivalent to the `annotations` field in the v1 API.
They have the same syntax and read/write to the same location in Service
Directory.

=item * C<< $msg->endpoints() >> / C<< $msg->endpoints($value) >>

Type: C<Message> (L<Google::Cloud::Servicedirectory::V1beta1::Endpoint::Endpoint>)

Output only. Endpoints associated with this service. Returned on
[LookupService.ResolveService][google.cloud.servicedirectory.v1beta1.LookupService.ResolveService].
Control plane clients should use
[RegistrationService.ListEndpoints][google.cloud.servicedirectory.v1beta1.RegistrationService.ListEndpoints].

=item * C<< $msg->create_time() >> / C<< $msg->create_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Output only. The timestamp when the service was created.

=item * C<< $msg->update_time() >> / C<< $msg->update_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Output only. The timestamp when the service was last updated. Note:
endpoints being created/deleted/updated within the service are not
considered service updates for the purpose of this timestamp.

=item * C<< $msg->uid() >> / C<< $msg->uid($value) >>

Type: C<String>

Output only. A globally unique identifier (in UUID4 format) for this
service.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Servicedirectory::V1beta1::Service::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
