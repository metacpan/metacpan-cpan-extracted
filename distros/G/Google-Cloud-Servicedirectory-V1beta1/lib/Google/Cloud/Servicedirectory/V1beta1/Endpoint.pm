package Google::Cloud::Servicedirectory::V1beta1::Endpoint;

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
    eval { require Google::Protobuf::Timestamp };
    my $descriptor_b64 = <<'EOF';
CjRnb29nbGUvY2xvdWQvc2VydmljZWRpcmVjdG9yeS92MWJldGExL2VuZHBvaW50LnByb3Rv
EiVnb29nbGUuY2xvdWQuc2VydmljZWRpcmVjdG9yeS52MWJldGExGh9nb29nbGUvYXBpL2Zp
ZWxkX2JlaGF2aW9yLnByb3RvGhlnb29nbGUvYXBpL3Jlc291cmNlLnByb3RvGh9nb29nbGUv
cHJvdG9idWYvdGltZXN0YW1wLnByb3RvIvcECghFbmRwb2ludBIXCgRuYW1lGAEgASgJQgPg
QQVSBG5hbWUSHQoHYWRkcmVzcxgCIAEoCUID4EEBUgdhZGRyZXNzEhcKBHBvcnQYAyABKAVC
A+BBAVIEcG9ydBJeCghtZXRhZGF0YRgEIAMoCzI9Lmdvb2dsZS5jbG91ZC5zZXJ2aWNlZGly
ZWN0b3J5LnYxYmV0YTEuRW5kcG9pbnQuTWV0YWRhdGFFbnRyeUID4EEBUghtZXRhZGF0YRJJ
CgduZXR3b3JrGAUgASgJQi/gQQX6QSkKJ3NlcnZpY2VkaXJlY3RvcnkuZ29vZ2xlYXBpcy5j
b20vTmV0d29ya1IHbmV0d29yaxJACgtjcmVhdGVfdGltZRgGIAEoCzIaLmdvb2dsZS5wcm90
b2J1Zi5UaW1lc3RhbXBCA+BBA1IKY3JlYXRlVGltZRJACgt1cGRhdGVfdGltZRgHIAEoCzIa
Lmdvb2dsZS5wcm90b2J1Zi5UaW1lc3RhbXBCA+BBA1IKdXBkYXRlVGltZRIVCgN1aWQYCCAB
KAlCA+BBA1IDdWlkGjsKDU1ldGFkYXRhRW50cnkSEAoDa2V5GAEgASgJUgNrZXkSFAoFdmFs
dWUYAiABKAlSBXZhbHVlOgI4ATqWAepBkgEKKHNlcnZpY2VkaXJlY3RvcnkuZ29vZ2xlYXBp
cy5jb20vRW5kcG9pbnQSZnByb2plY3RzL3twcm9qZWN0fS9sb2NhdGlvbnMve2xvY2F0aW9u
fS9uYW1lc3BhY2VzL3tuYW1lc3BhY2V9L3NlcnZpY2VzL3tzZXJ2aWNlfS9lbmRwb2ludHMv
e2VuZHBvaW50fULyAgopY29tLmdvb2dsZS5jbG91ZC5zZXJ2aWNlZGlyZWN0b3J5LnYxYmV0
YTFCDUVuZHBvaW50UHJvdG9QAVpVY2xvdWQuZ29vZ2xlLmNvbS9nby9zZXJ2aWNlZGlyZWN0
b3J5L2FwaXYxYmV0YTEvc2VydmljZWRpcmVjdG9yeXBiO3NlcnZpY2VkaXJlY3RvcnlwYqoC
JUdvb2dsZS5DbG91ZC5TZXJ2aWNlRGlyZWN0b3J5LlYxQmV0YTHKAiVHb29nbGVcQ2xvdWRc
U2VydmljZURpcmVjdG9yeVxWMWJldGEx6gIoR29vZ2xlOjpDbG91ZDo6U2VydmljZURpcmVj
dG9yeTo6VjFiZXRhMepBYQonc2VydmljZWRpcmVjdG9yeS5nb29nbGVhcGlzLmNvbS9OZXR3
b3JrEjZwcm9qZWN0cy97cHJvamVjdH0vbG9jYXRpb25zL2dsb2JhbC9uZXR3b3Jrcy97bmV0
d29ya31KjR0KBhIEDgBtAQq8BAoBDBIDDgASMrEEIENvcHlyaWdodCAyMDI1IEdvb2dsZSBM
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
AQISAxAALgoJCgIDABIDEgApCgkKAgMBEgMTACMKCQoCAwISAxQAKQoICgEIEgMWAEIKCQoC
CCUSAxYAQgoICgEIEgMXAGwKCQoCCAsSAxcAbAoICgEIEgMYACIKCQoCCAoSAxgAIgoICgEI
EgMZAC4KCQoCCAgSAxkALgoICgEIEgMaAEIKCQoCCAESAxoAQgoICgEIEgMbAEIKCQoCCCkS
AxsAQgoICgEIEgMcAEEKCQoCCC0SAxwAQQoJCgEIEgQdACACCgwKBAidCAASBB0AIAIKpwEK
AgQAEgQlAG0BGpoBIEFuIGluZGl2aWR1YWwgZW5kcG9pbnQgdGhhdCBwcm92aWRlcyBhCiBb
c2VydmljZV1bZ29vZ2xlLmNsb3VkLnNlcnZpY2VkaXJlY3RvcnkudjFiZXRhMS5TZXJ2aWNl
XS4gVGhlIHNlcnZpY2UgbXVzdAogYWxyZWFkeSBleGlzdCB0byBjcmVhdGUgYW4gZW5kcG9p
bnQuCgoKCgMEAAESAyUIEAoLCgMEAAcSBCYCKQQKDQoFBAAHnQgSBCYCKQQKiQEKBAQAAgAS
Ay0CPBp8IEltbXV0YWJsZS4gVGhlIHJlc291cmNlIG5hbWUgZm9yIHRoZSBlbmRwb2ludCBp
biB0aGUgZm9ybWF0CiBgcHJvamVjdHMvKi9sb2NhdGlvbnMvKi9uYW1lc3BhY2VzLyovc2Vy
dmljZXMvKi9lbmRwb2ludHMvKmAuCgoMCgUEAAIABRIDLQIICgwKBQQAAgABEgMtCQ0KDAoF
BAACAAMSAy0QEQoMCgUEAAIACBIDLRI7Cg8KCAQAAgAInAgAEgMtEzoK1AEKBAQAAgESAzkC
PhrGASBPcHRpb25hbC4gQW4gSVB2NCBvciBJUHY2IGFkZHJlc3MuIFNlcnZpY2UgRGlyZWN0
b3J5IHJlamVjdHMgYmFkIGFkZHJlc3NlcwogbGlrZToKCiAqICAgYDguOC44YAogKiAgIGA4
LjguOC44OjUzYAogKiAgIGB0ZXN0OmJhZDphZGRyZXNzYAogKiAgIGBbOjoxXWAKICogICBg
Wzo6MV06ODA4MGAKCiBMaW1pdGVkIHRvIDQ1IGNoYXJhY3RlcnMuCgoMCgUEAAIBBRIDOQII
CgwKBQQAAgEBEgM5CRAKDAoFBAACAQMSAzkTFAoMCgUEAAIBCBIDORU9Cg8KCAQAAgEInAgA
EgM5FjwKUgoEBAACAhIDPAI6GkUgT3B0aW9uYWwuIFNlcnZpY2UgRGlyZWN0b3J5IHJlamVj
dHMgdmFsdWVzIG91dHNpZGUgb2YgYFswLCA2NTUzNV1gLgoKDAoFBAACAgUSAzwCBwoMCgUE
AAICARIDPAgMCgwKBQQAAgIDEgM8DxAKDAoFBAACAggSAzwROQoPCggEAAICCJwIABIDPBI4
Cv8HCgQEAAIDEgNSAkwa8QcgT3B0aW9uYWwuIE1ldGFkYXRhIGZvciB0aGUgZW5kcG9pbnQu
IFRoaXMgZGF0YSBjYW4gYmUgY29uc3VtZWQgYnkgc2VydmljZQogY2xpZW50cy4KCiBSZXN0
cmljdGlvbnM6CgogKiAgIFRoZSBlbnRpcmUgbWV0YWRhdGEgZGljdGlvbmFyeSBtYXkgY29u
dGFpbiB1cCB0byA1MTIgY2hhcmFjdGVycywKICAgICBzcHJlYWQgYWNjb3NzIGFsbCBrZXkt
dmFsdWUgcGFpcnMuIE1ldGFkYXRhIHRoYXQgZ29lcyBiZXlvbmQgdGhpcwogICAgIGxpbWl0
IGFyZSByZWplY3RlZAogKiAgIFZhbGlkIG1ldGFkYXRhIGtleXMgaGF2ZSB0d28gc2VnbWVu
dHM6IGFuIG9wdGlvbmFsIHByZWZpeCBhbmQgbmFtZSwKICAgICBzZXBhcmF0ZWQgYnkgYSBz
bGFzaCAoLykuIFRoZSBuYW1lIHNlZ21lbnQgaXMgcmVxdWlyZWQgYW5kIG11c3QgYmUgNjMK
ICAgICBjaGFyYWN0ZXJzIG9yIGxlc3MsIGJlZ2lubmluZyBhbmQgZW5kaW5nIHdpdGggYW4g
YWxwaGFudW1lcmljIGNoYXJhY3RlcgogICAgIChbYS16MC05QS1aXSkgd2l0aCBkYXNoZXMg
KC0pLCB1bmRlcnNjb3JlcyAoXyksIGRvdHMgKC4pLCBhbmQKICAgICBhbHBoYW51bWVyaWNz
IGJldHdlZW4uIFRoZSBwcmVmaXggaXMgb3B0aW9uYWwuIElmIHNwZWNpZmllZCwgdGhlIHBy
ZWZpeAogICAgIG11c3QgYmUgYSBETlMgc3ViZG9tYWluOiBhIHNlcmllcyBvZiBETlMgbGFi
ZWxzIHNlcGFyYXRlZCBieSBkb3RzICguKSwKICAgICBub3QgbG9uZ2VyIHRoYW4gMjUzIGNo
YXJhY3RlcnMgaW4gdG90YWwsIGZvbGxvd2VkIGJ5IGEgc2xhc2ggKC8pLgogICAgIE1ldGFk
YXRhIHRoYXQgZmFpbHMgdG8gbWVldCB0aGVzZSByZXF1aXJlbWVudHMgYXJlIHJlamVjdGVk
CgogTm90ZTogVGhpcyBmaWVsZCBpcyBlcXVpdmFsZW50IHRvIHRoZSBgYW5ub3RhdGlvbnNg
IGZpZWxkIGluIHRoZSB2MSBBUEkuCiBUaGV5IGhhdmUgdGhlIHNhbWUgc3ludGF4IGFuZCBy
ZWFkL3dyaXRlIHRvIHRoZSBzYW1lIGxvY2F0aW9uIGluIFNlcnZpY2UKIERpcmVjdG9yeS4K
CgwKBQQAAgMGEgNSAhUKDAoFBAACAwESA1IWHgoMCgUEAAIDAxIDUiEiCgwKBQQAAgMIEgNS
I0sKDwoIBAACAwicCAASA1IkSgqMAwoEBAACBBIEWwJgBBr9AiBJbW11dGFibGUuIFRoZSBH
b29nbGUgQ29tcHV0ZSBFbmdpbmUgbmV0d29yayAoVlBDKSBvZiB0aGUgZW5kcG9pbnQgaW4g
dGhlCiBmb3JtYXQgYHByb2plY3RzLzxwcm9qZWN0IG51bWJlcj4vbG9jYXRpb25zL2dsb2Jh
bC9uZXR3b3Jrcy8qYC4KCiBUaGUgcHJvamVjdCBtdXN0IGJlIHNwZWNpZmllZCBieSBwcm9q
ZWN0IG51bWJlciAocHJvamVjdCBpZCBpcyByZWplY3RlZCkuCiBJbmNvcnJlY3RseSBmb3Jt
YXR0ZWQgbmV0d29ya3MgYXJlIHJlamVjdGVkLCBidXQgbm8gb3RoZXIgdmFsaWRhdGlvbgog
aXMgcGVyZm9ybWVkIG9uIHRoaXMgZmllbGQgKGV4LiBuZXR3b3JrIG9yIHByb2plY3QgZXhp
c3RlbmNlLCByZWFjaGFiaWxpdHksCiBvciBwZXJtaXNzaW9ucykuCgoMCgUEAAIEBRIDWwII
CgwKBQQAAgQBEgNbCRAKDAoFBAACBAMSA1sTFAoNCgUEAAIECBIEWxVgAwoPCggEAAIECJwI
ABIDXAQrCg8KBwQAAgQInwgSBF0EXwUKSQoEBAACBRIEYwJkMho7IE91dHB1dCBvbmx5LiBU
aGUgdGltZXN0YW1wIHdoZW4gdGhlIGVuZHBvaW50IHdhcyBjcmVhdGVkLgoKDAoFBAACBQYS
A2MCGwoMCgUEAAIFARIDYxwnCgwKBQQAAgUDEgNjKisKDAoFBAACBQgSA2QGMQoPCggEAAIF
CJwIABIDZAcwCk4KBAQAAgYSBGcCaDIaQCBPdXRwdXQgb25seS4gVGhlIHRpbWVzdGFtcCB3
aGVuIHRoZSBlbmRwb2ludCB3YXMgbGFzdCB1cGRhdGVkLgoKDAoFBAACBgYSA2cCGwoMCgUE
AAIGARIDZxwnCgwKBQQAAgYDEgNnKisKDAoFBAACBggSA2gGMQoPCggEAAIGCJwIABIDaAcw
Cl4KBAQAAgcSA2wCPRpRIE91dHB1dCBvbmx5LiBBIGdsb2JhbGx5IHVuaXF1ZSBpZGVudGlm
aWVyIChpbiBVVUlENCBmb3JtYXQpIGZvciB0aGlzCiBlbmRwb2ludC4KCgwKBQQAAgcFEgNs
AggKDAoFBAACBwESA2wJDAoMCgUEAAIHAxIDbA8QCgwKBQQAAgcIEgNsETwKDwoIBAACBwic
CAASA2wSO2IGcHJvdG8z
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Servicedirectory::V1beta1::Endpoint::Endpoint ===
    # Fields for Endpoint
    # Field: name Type: 9 ()
    # Field: address Type: 9 ()
    # Field: port Type: 5 ()
    # Field: metadata Type: 11 (.google.cloud.servicedirectory.v1beta1.Endpoint.MetadataEntry)
    # Field: network Type: 9 ()
    # Field: create_time Type: 11 (.google.protobuf.Timestamp)
    # Field: update_time Type: 11 (.google.protobuf.Timestamp)
    # Field: uid Type: 9 ()

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Servicedirectory::V1beta1::Endpoint - Compiled Protocol Buffers messages for google/cloud/servicedirectory/v1beta1/endpoint.proto

=head1 SYNOPSIS

    use Google::Cloud::Servicedirectory::V1beta1::Endpoint;

    my $msg = Google::Cloud::Servicedirectory::V1beta1::Endpoint::Endpoint->new({
        name => $name,
        address => $address,
        port => $port,
        metadata => $metadata,
    });

    # Read or update a field
    my $val = $msg->name();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Servicedirectory::V1beta1::Endpoint::Endpoint->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/servicedirectory/v1beta1/endpoint.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Servicedirectory::V1beta1::Endpoint::Endpoint

An individual endpoint that provides a
[service][google.cloud.servicedirectory.v1beta1.Service]. The service must
already exist to create an endpoint.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Immutable. The resource name for the endpoint in the format
`projects/*/locations/*/namespaces/*/services/*/endpoints/*`.

=item * C<< $msg->address() >> / C<< $msg->address($value) >>

Type: C<String>

Optional. An IPv4 or IPv6 address. Service Directory rejects bad addresses
like:

*   `8.8.8`
*   `8.8.8.8:53`
*   `test:bad:address`
*   `[::1]`
*   `[::1]:8080`

Limited to 45 characters.

=item * C<< $msg->port() >> / C<< $msg->port($value) >>

Type: C<Int32>

Optional. Service Directory rejects values outside of `[0, 65535]`.

=item * C<< $msg->metadata() >> / C<< $msg->metadata($value) >>

Type: C<Message> (L<Google::Cloud::Servicedirectory::V1beta1::Endpoint::Endpoint::MetadataEntry>)

Optional. Metadata for the endpoint. This data can be consumed by service
clients.

Restrictions:

*   The entire metadata dictionary may contain up to 512 characters,
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

=item * C<< $msg->network() >> / C<< $msg->network($value) >>

Type: C<String>

Immutable. The Google Compute Engine network (VPC) of the endpoint in the
format `projects/<project number>/locations/global/networks/*`.

The project must be specified by project number (project id is rejected).
Incorrectly formatted networks are rejected, but no other validation
is performed on this field (ex. network or project existence, reachability,
or permissions).

=item * C<< $msg->create_time() >> / C<< $msg->create_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Output only. The timestamp when the endpoint was created.

=item * C<< $msg->update_time() >> / C<< $msg->update_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Output only. The timestamp when the endpoint was last updated.

=item * C<< $msg->uid() >> / C<< $msg->uid($value) >>

Type: C<String>

Output only. A globally unique identifier (in UUID4 format) for this
endpoint.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Servicedirectory::V1beta1::Endpoint::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
