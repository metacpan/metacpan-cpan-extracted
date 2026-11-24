package Google::Cloud::Servicedirectory::V1::Service;

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
    eval { require Google::Cloud::Servicedirectory::V1::Endpoint };
    my $descriptor_b64 = <<'EOF';
Ci5nb29nbGUvY2xvdWQvc2VydmljZWRpcmVjdG9yeS92MS9zZXJ2aWNlLnByb3RvEiBnb29n
bGUuY2xvdWQuc2VydmljZWRpcmVjdG9yeS52MRofZ29vZ2xlL2FwaS9maWVsZF9iZWhhdmlv
ci5wcm90bxoZZ29vZ2xlL2FwaS9yZXNvdXJjZS5wcm90bxovZ29vZ2xlL2Nsb3VkL3NlcnZp
Y2VkaXJlY3RvcnkvdjEvZW5kcG9pbnQucHJvdG8irAMKB1NlcnZpY2USFwoEbmFtZRgBIAEo
CUID4EEFUgRuYW1lEmEKC2Fubm90YXRpb25zGAQgAygLMjouZ29vZ2xlLmNsb3VkLnNlcnZp
Y2VkaXJlY3RvcnkudjEuU2VydmljZS5Bbm5vdGF0aW9uc0VudHJ5QgPgQQFSC2Fubm90YXRp
b25zEk0KCWVuZHBvaW50cxgDIAMoCzIqLmdvb2dsZS5jbG91ZC5zZXJ2aWNlZGlyZWN0b3J5
LnYxLkVuZHBvaW50QgPgQQNSCWVuZHBvaW50cxIVCgN1aWQYByABKAlCA+BBA1IDdWlkGj4K
EEFubm90YXRpb25zRW50cnkSEAoDa2V5GAEgASgJUgNrZXkSFAoFdmFsdWUYAiABKAlSBXZh
bHVlOgI4ATp/6kF8CidzZXJ2aWNlZGlyZWN0b3J5Lmdvb2dsZWFwaXMuY29tL1NlcnZpY2US
UXByb2plY3RzL3twcm9qZWN0fS9sb2NhdGlvbnMve2xvY2F0aW9ufS9uYW1lc3BhY2VzL3tu
YW1lc3BhY2V9L3NlcnZpY2VzL3tzZXJ2aWNlfUL0AQokY29tLmdvb2dsZS5jbG91ZC5zZXJ2
aWNlZGlyZWN0b3J5LnYxQgxTZXJ2aWNlUHJvdG9QAVpQY2xvdWQuZ29vZ2xlLmNvbS9nby9z
ZXJ2aWNlZGlyZWN0b3J5L2FwaXYxL3NlcnZpY2VkaXJlY3RvcnlwYjtzZXJ2aWNlZGlyZWN0
b3J5cGKqAiBHb29nbGUuQ2xvdWQuU2VydmljZURpcmVjdG9yeS5WMcoCIEdvb2dsZVxDbG91
ZFxTZXJ2aWNlRGlyZWN0b3J5XFYx6gIjR29vZ2xlOjpDbG91ZDo6U2VydmljZURpcmVjdG9y
eTo6VjFK0BYKBhIEDgBLAQq8BAoBDBIDDgASMrEEIENvcHlyaWdodCAyMDI1IEdvb2dsZSBM
TEMKCiBMaWNlbnNlZCB1bmRlciB0aGUgQXBhY2hlIExpY2Vuc2UsIFZlcnNpb24gMi4wICh0
aGUgIkxpY2Vuc2UiKTsKIHlvdSBtYXkgbm90IHVzZSB0aGlzIGZpbGUgZXhjZXB0IGluIGNv
bXBsaWFuY2Ugd2l0aCB0aGUgTGljZW5zZS4KIFlvdSBtYXkgb2J0YWluIGEgY29weSBvZiB0
aGUgTGljZW5zZSBhdAoKICAgICBodHRwOi8vd3d3LmFwYWNoZS5vcmcvbGljZW5zZXMvTElD
RU5TRS0yLjAKCiBVbmxlc3MgcmVxdWlyZWQgYnkgYXBwbGljYWJsZSBsYXcgb3IgYWdyZWVk
IHRvIGluIHdyaXRpbmcsIHNvZnR3YXJlCiBkaXN0cmlidXRlZCB1bmRlciB0aGUgTGljZW5z
ZSBpcyBkaXN0cmlidXRlZCBvbiBhbiAiQVMgSVMiIEJBU0lTLAogV0lUSE9VVCBXQVJSQU5U
SUVTIE9SIENPTkRJVElPTlMgT0YgQU5ZIEtJTkQsIGVpdGhlciBleHByZXNzIG9yIGltcGxp
ZWQuCiBTZWUgdGhlIExpY2Vuc2UgZm9yIHRoZSBzcGVjaWZpYyBsYW5ndWFnZSBnb3Zlcm5p
bmcgcGVybWlzc2lvbnMgYW5kCiBsaW1pdGF0aW9ucyB1bmRlciB0aGUgTGljZW5zZS4KCggK
AQISAxAAKQoJCgIDABIDEgApCgkKAgMBEgMTACMKCQoCAwISAxQAOQoICgEIEgMWAD0KCQoC
CCUSAxYAPQoICgEIEgMXAGcKCQoCCAsSAxcAZwoICgEIEgMYACIKCQoCCAoSAxgAIgoICgEI
EgMZAC0KCQoCCAgSAxkALQoICgEIEgMaAD0KCQoCCAESAxoAPQoICgEIEgMbAD0KCQoCCCkS
AxsAPQoICgEIEgMcADwKCQoCCC0SAxwAPArAAQoCBAASBCIASwEaswEgQW4gaW5kaXZpZHVh
bCBzZXJ2aWNlLiBBIHNlcnZpY2UgY29udGFpbnMgYSBuYW1lIGFuZCBvcHRpb25hbCBtZXRh
ZGF0YS4KIEEgc2VydmljZSBtdXN0IGV4aXN0IGJlZm9yZQogW2VuZHBvaW50c11bZ29vZ2xl
LmNsb3VkLnNlcnZpY2VkaXJlY3RvcnkudjEuRW5kcG9pbnRdIGNhbiBiZQogYWRkZWQgdG8g
aXQuCgoKCgMEAAESAyIIDwoLCgMEAAcSBCMCJgQKDQoFBAAHnQgSBCMCJgQKfAoEBAACABID
KgI8Gm8gSW1tdXRhYmxlLiBUaGUgcmVzb3VyY2UgbmFtZSBmb3IgdGhlIHNlcnZpY2UgaW4g
dGhlIGZvcm1hdAogYHByb2plY3RzLyovbG9jYXRpb25zLyovbmFtZXNwYWNlcy8qL3NlcnZp
Y2VzLypgLgoKDAoFBAACAAUSAyoCCAoMCgUEAAIAARIDKgkNCgwKBQQAAgADEgMqEBEKDAoF
BAACAAgSAyoSOwoPCggEAAIACJwIABIDKhM6Co0ICgQEAAIBEgNAAk8a/wcgT3B0aW9uYWwu
IEFubm90YXRpb25zIGZvciB0aGUgc2VydmljZS4gVGhpcyBkYXRhIGNhbiBiZSBjb25zdW1l
ZCBieSBzZXJ2aWNlCiBjbGllbnRzLgoKIFJlc3RyaWN0aW9uczoKCiAqICAgVGhlIGVudGly
ZSBhbm5vdGF0aW9ucyBkaWN0aW9uYXJ5IG1heSBjb250YWluIHVwIHRvIDIwMDAgY2hhcmFj
dGVycywKICAgICBzcHJlYWQgYWNjb3NzIGFsbCBrZXktdmFsdWUgcGFpcnMuIEFubm90YXRp
b25zIHRoYXQgZ28gYmV5b25kIHRoaXMKICAgICBsaW1pdCBhcmUgcmVqZWN0ZWQKICogICBW
YWxpZCBhbm5vdGF0aW9uIGtleXMgaGF2ZSB0d28gc2VnbWVudHM6IGFuIG9wdGlvbmFsIHBy
ZWZpeCBhbmQgbmFtZSwKICAgICBzZXBhcmF0ZWQgYnkgYSBzbGFzaCAoLykuIFRoZSBuYW1l
IHNlZ21lbnQgaXMgcmVxdWlyZWQgYW5kIG11c3QgYmUgNjMKICAgICBjaGFyYWN0ZXJzIG9y
IGxlc3MsIGJlZ2lubmluZyBhbmQgZW5kaW5nIHdpdGggYW4gYWxwaGFudW1lcmljIGNoYXJh
Y3RlcgogICAgIChbYS16MC05QS1aXSkgd2l0aCBkYXNoZXMgKC0pLCB1bmRlcnNjb3JlcyAo
XyksIGRvdHMgKC4pLCBhbmQKICAgICBhbHBoYW51bWVyaWNzIGJldHdlZW4uIFRoZSBwcmVm
aXggaXMgb3B0aW9uYWwuIElmIHNwZWNpZmllZCwgdGhlIHByZWZpeAogICAgIG11c3QgYmUg
YSBETlMgc3ViZG9tYWluOiBhIHNlcmllcyBvZiBETlMgbGFiZWxzIHNlcGFyYXRlZCBieSBk
b3RzICguKSwKICAgICBub3QgbG9uZ2VyIHRoYW4gMjUzIGNoYXJhY3RlcnMgaW4gdG90YWws
IGZvbGxvd2VkIGJ5IGEgc2xhc2ggKC8pLgogICAgIEFubm90YXRpb25zIHRoYXQgZmFpbHMg
dG8gbWVldCB0aGVzZSByZXF1aXJlbWVudHMgYXJlIHJlamVjdGVkCgogTm90ZTogVGhpcyBm
aWVsZCBpcyBlcXVpdmFsZW50IHRvIHRoZSBgbWV0YWRhdGFgIGZpZWxkIGluIHRoZSB2MWJl
dGExIEFQSS4KIFRoZXkgaGF2ZSB0aGUgc2FtZSBzeW50YXggYW5kIHJlYWQvd3JpdGUgdG8g
dGhlIHNhbWUgbG9jYXRpb24gaW4gU2VydmljZQogRGlyZWN0b3J5LgoKDAoFBAACAQYSA0AC
FQoMCgUEAAIBARIDQBYhCgwKBQQAAgEDEgNAJCUKDAoFBAACAQgSA0AmTgoPCggEAAIBCJwI
ABIDQCdNCrwCCgQEAAICEgNGAk4argIgT3V0cHV0IG9ubHkuIEVuZHBvaW50cyBhc3NvY2lh
dGVkIHdpdGggdGhpcyBzZXJ2aWNlLiBSZXR1cm5lZCBvbgogW0xvb2t1cFNlcnZpY2UuUmVz
b2x2ZVNlcnZpY2VdW2dvb2dsZS5jbG91ZC5zZXJ2aWNlZGlyZWN0b3J5LnYxLkxvb2t1cFNl
cnZpY2UuUmVzb2x2ZVNlcnZpY2VdLgogQ29udHJvbCBwbGFuZSBjbGllbnRzIHNob3VsZCB1
c2UKIFtSZWdpc3RyYXRpb25TZXJ2aWNlLkxpc3RFbmRwb2ludHNdW2dvb2dsZS5jbG91ZC5z
ZXJ2aWNlZGlyZWN0b3J5LnYxLlJlZ2lzdHJhdGlvblNlcnZpY2UuTGlzdEVuZHBvaW50c10u
CgoMCgUEAAICBBIDRgIKCgwKBQQAAgIGEgNGCxMKDAoFBAACAgESA0YUHQoMCgUEAAICAxID
RiAhCgwKBQQAAgIIEgNGIk0KDwoIBAACAgicCAASA0YjTApfCgQEAAIDEgNKAj0aUiBPdXRw
dXQgb25seS4gVGhlIGdsb2JhbGx5IHVuaXF1ZSBpZGVudGlmaWVyIG9mIHRoZSBzZXJ2aWNl
IGluIHRoZSBVVUlENAogZm9ybWF0LgoKDAoFBAACAwUSA0oCCAoMCgUEAAIDARIDSgkMCgwK
BQQAAgMDEgNKDxAKDAoFBAACAwgSA0oRPAoPCggEAAIDCJwIABIDShI7YgZwcm90bzM=
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Servicedirectory::V1::Service::Service ===
    # Fields for Service
    # Field: name Type: 9 ()
    # Field: annotations Type: 11 (.google.cloud.servicedirectory.v1.Service.AnnotationsEntry)
    # Field: endpoints Type: 11 (.google.cloud.servicedirectory.v1.Endpoint)
    # Field: uid Type: 9 ()

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Servicedirectory::V1::Service - Compiled Protocol Buffers messages for google/cloud/servicedirectory/v1/service.proto

=head1 SYNOPSIS

    use Google::Cloud::Servicedirectory::V1::Service;

    my $msg = Google::Cloud::Servicedirectory::V1::Service::Service->new({
        name => $name,
        annotations => $annotations,
        endpoints => $endpoints,
        uid => $uid,
    });

    # Read or update a field
    my $val = $msg->name();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Servicedirectory::V1::Service::Service->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/servicedirectory/v1/service.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Servicedirectory::V1::Service::Service

An individual service. A service contains a name and optional metadata.
A service must exist before
[endpoints][google.cloud.servicedirectory.v1.Endpoint] can be
added to it.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Immutable. The resource name for the service in the format
`projects/*/locations/*/namespaces/*/services/*`.

=item * C<< $msg->annotations() >> / C<< $msg->annotations($value) >>

Type: C<Message> (L<Google::Cloud::Servicedirectory::V1::Service::Service::AnnotationsEntry>)

Optional. Annotations for the service. This data can be consumed by service
clients.

Restrictions:

*   The entire annotations dictionary may contain up to 2000 characters,
    spread accoss all key-value pairs. Annotations that go beyond this
    limit are rejected
*   Valid annotation keys have two segments: an optional prefix and name,
    separated by a slash (/). The name segment is required and must be 63
    characters or less, beginning and ending with an alphanumeric character
    ([a-z0-9A-Z]) with dashes (-), underscores (_), dots (.), and
    alphanumerics between. The prefix is optional. If specified, the prefix
    must be a DNS subdomain: a series of DNS labels separated by dots (.),
    not longer than 253 characters in total, followed by a slash (/).
    Annotations that fails to meet these requirements are rejected

Note: This field is equivalent to the `metadata` field in the v1beta1 API.
They have the same syntax and read/write to the same location in Service
Directory.

=item * C<< $msg->endpoints() >> / C<< $msg->endpoints($value) >>

Type: C<Message> (L<Google::Cloud::Servicedirectory::V1::Endpoint::Endpoint>)

Output only. Endpoints associated with this service. Returned on
[LookupService.ResolveService][google.cloud.servicedirectory.v1.LookupService.ResolveService].
Control plane clients should use
[RegistrationService.ListEndpoints][google.cloud.servicedirectory.v1.RegistrationService.ListEndpoints].

=item * C<< $msg->uid() >> / C<< $msg->uid($value) >>

Type: C<String>

Output only. The globally unique identifier of the service in the UUID4
format.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Servicedirectory::V1::Service::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
