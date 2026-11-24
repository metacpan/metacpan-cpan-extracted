package Google::Cloud::Servicedirectory::V1::Endpoint;

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
    my $descriptor_b64 = <<'EOF';
Ci9nb29nbGUvY2xvdWQvc2VydmljZWRpcmVjdG9yeS92MS9lbmRwb2ludC5wcm90bxIgZ29v
Z2xlLmNsb3VkLnNlcnZpY2VkaXJlY3RvcnkudjEaH2dvb2dsZS9hcGkvZmllbGRfYmVoYXZp
b3IucHJvdG8aGWdvb2dsZS9hcGkvcmVzb3VyY2UucHJvdG8i+gMKCEVuZHBvaW50EhcKBG5h
bWUYASABKAlCA+BBBVIEbmFtZRIdCgdhZGRyZXNzGAIgASgJQgPgQQFSB2FkZHJlc3MSFwoE
cG9ydBgDIAEoBUID4EEBUgRwb3J0EmIKC2Fubm90YXRpb25zGAUgAygLMjsuZ29vZ2xlLmNs
b3VkLnNlcnZpY2VkaXJlY3RvcnkudjEuRW5kcG9pbnQuQW5ub3RhdGlvbnNFbnRyeUID4EEB
Ugthbm5vdGF0aW9ucxJJCgduZXR3b3JrGAggASgJQi/gQQX6QSkKJ3NlcnZpY2VkaXJlY3Rv
cnkuZ29vZ2xlYXBpcy5jb20vTmV0d29ya1IHbmV0d29yaxIVCgN1aWQYCSABKAlCA+BBA1ID
dWlkGj4KEEFubm90YXRpb25zRW50cnkSEAoDa2V5GAEgASgJUgNrZXkSFAoFdmFsdWUYAiAB
KAlSBXZhbHVlOgI4ATqWAepBkgEKKHNlcnZpY2VkaXJlY3RvcnkuZ29vZ2xlYXBpcy5jb20v
RW5kcG9pbnQSZnByb2plY3RzL3twcm9qZWN0fS9sb2NhdGlvbnMve2xvY2F0aW9ufS9uYW1l
c3BhY2VzL3tuYW1lc3BhY2V9L3NlcnZpY2VzL3tzZXJ2aWNlfS9lbmRwb2ludHMve2VuZHBv
aW50fULZAgokY29tLmdvb2dsZS5jbG91ZC5zZXJ2aWNlZGlyZWN0b3J5LnYxQg1FbmRwb2lu
dFByb3RvUAFaUGNsb3VkLmdvb2dsZS5jb20vZ28vc2VydmljZWRpcmVjdG9yeS9hcGl2MS9z
ZXJ2aWNlZGlyZWN0b3J5cGI7c2VydmljZWRpcmVjdG9yeXBiqgIgR29vZ2xlLkNsb3VkLlNl
cnZpY2VEaXJlY3RvcnkuVjHKAiBHb29nbGVcQ2xvdWRcU2VydmljZURpcmVjdG9yeVxWMeoC
I0dvb2dsZTo6Q2xvdWQ6OlNlcnZpY2VEaXJlY3Rvcnk6OlYx6kFhCidzZXJ2aWNlZGlyZWN0
b3J5Lmdvb2dsZWFwaXMuY29tL05ldHdvcmsSNnByb2plY3RzL3twcm9qZWN0fS9sb2NhdGlv
bnMvZ2xvYmFsL25ldHdvcmtzL3tuZXR3b3JrfUreGgoGEgQOAGQBCrwECgEMEgMOABIysQQg
Q29weXJpZ2h0IDIwMjUgR29vZ2xlIExMQwoKIExpY2Vuc2VkIHVuZGVyIHRoZSBBcGFjaGUg
TGljZW5zZSwgVmVyc2lvbiAyLjAgKHRoZSAiTGljZW5zZSIpOwogeW91IG1heSBub3QgdXNl
IHRoaXMgZmlsZSBleGNlcHQgaW4gY29tcGxpYW5jZSB3aXRoIHRoZSBMaWNlbnNlLgogWW91
IG1heSBvYnRhaW4gYSBjb3B5IG9mIHRoZSBMaWNlbnNlIGF0CgogICAgIGh0dHA6Ly93d3cu
YXBhY2hlLm9yZy9saWNlbnNlcy9MSUNFTlNFLTIuMAoKIFVubGVzcyByZXF1aXJlZCBieSBh
cHBsaWNhYmxlIGxhdyBvciBhZ3JlZWQgdG8gaW4gd3JpdGluZywgc29mdHdhcmUKIGRpc3Ry
aWJ1dGVkIHVuZGVyIHRoZSBMaWNlbnNlIGlzIGRpc3RyaWJ1dGVkIG9uIGFuICJBUyBJUyIg
QkFTSVMsCiBXSVRIT1VUIFdBUlJBTlRJRVMgT1IgQ09ORElUSU9OUyBPRiBBTlkgS0lORCwg
ZWl0aGVyIGV4cHJlc3Mgb3IgaW1wbGllZC4KIFNlZSB0aGUgTGljZW5zZSBmb3IgdGhlIHNw
ZWNpZmljIGxhbmd1YWdlIGdvdmVybmluZyBwZXJtaXNzaW9ucyBhbmQKIGxpbWl0YXRpb25z
IHVuZGVyIHRoZSBMaWNlbnNlLgoKCAoBAhIDEAApCgkKAgMAEgMSACkKCQoCAwESAxMAIwoI
CgEIEgMVAD0KCQoCCCUSAxUAPQoICgEIEgMWAGcKCQoCCAsSAxYAZwoICgEIEgMXACIKCQoC
CAoSAxcAIgoICgEIEgMYAC4KCQoCCAgSAxgALgoICgEIEgMZAD0KCQoCCAESAxkAPQoICgEI
EgMaAD0KCQoCCCkSAxoAPQoICgEIEgMbADwKCQoCCC0SAxsAPAoJCgEIEgQcAB8CCgwKBAid
CAASBBwAHwIKogEKAgQAEgQkAGQBGpUBIEFuIGluZGl2aWR1YWwgZW5kcG9pbnQgdGhhdCBw
cm92aWRlcyBhCiBbc2VydmljZV1bZ29vZ2xlLmNsb3VkLnNlcnZpY2VkaXJlY3RvcnkudjEu
U2VydmljZV0uIFRoZSBzZXJ2aWNlIG11c3QKIGFscmVhZHkgZXhpc3QgdG8gY3JlYXRlIGFu
IGVuZHBvaW50LgoKCgoDBAABEgMkCBAKCwoDBAAHEgQlAigECg0KBQQAB50IEgQlAigECokB
CgQEAAIAEgMsAjwafCBJbW11dGFibGUuIFRoZSByZXNvdXJjZSBuYW1lIGZvciB0aGUgZW5k
cG9pbnQgaW4gdGhlIGZvcm1hdAogYHByb2plY3RzLyovbG9jYXRpb25zLyovbmFtZXNwYWNl
cy8qL3NlcnZpY2VzLyovZW5kcG9pbnRzLypgLgoKDAoFBAACAAUSAywCCAoMCgUEAAIAARID
LAkNCgwKBQQAAgADEgMsEBEKDAoFBAACAAgSAywSOwoPCggEAAIACJwIABIDLBM6CtQBCgQE
AAIBEgM4Aj4axgEgT3B0aW9uYWwuIEFuIElQdjQgb3IgSVB2NiBhZGRyZXNzLiBTZXJ2aWNl
IERpcmVjdG9yeSByZWplY3RzIGJhZCBhZGRyZXNzZXMKIGxpa2U6CgogKiAgIGA4LjguOGAK
ICogICBgOC44LjguODo1M2AKICogICBgdGVzdDpiYWQ6YWRkcmVzc2AKICogICBgWzo6MV1g
CiAqICAgYFs6OjFdOjgwODBgCgogTGltaXRlZCB0byA0NSBjaGFyYWN0ZXJzLgoKDAoFBAAC
AQUSAzgCCAoMCgUEAAIBARIDOAkQCgwKBQQAAgEDEgM4ExQKDAoFBAACAQgSAzgVPQoPCggE
AAIBCJwIABIDOBY8ClIKBAQAAgISAzsCOhpFIE9wdGlvbmFsLiBTZXJ2aWNlIERpcmVjdG9y
eSByZWplY3RzIHZhbHVlcyBvdXRzaWRlIG9mIGBbMCwgNjU1MzVdYC4KCgwKBQQAAgIFEgM7
AgcKDAoFBAACAgESAzsIDAoMCgUEAAICAxIDOw8QCgwKBQQAAgIIEgM7ETkKDwoIBAACAgic
CAASAzsSOAqNCAoEBAACAxIDUQJPGv8HIE9wdGlvbmFsLiBBbm5vdGF0aW9ucyBmb3IgdGhl
IGVuZHBvaW50LiBUaGlzIGRhdGEgY2FuIGJlIGNvbnN1bWVkIGJ5CiBzZXJ2aWNlIGNsaWVu
dHMuCgogUmVzdHJpY3Rpb25zOgoKICogICBUaGUgZW50aXJlIGFubm90YXRpb25zIGRpY3Rp
b25hcnkgbWF5IGNvbnRhaW4gdXAgdG8gNTEyIGNoYXJhY3RlcnMsCiAgICAgc3ByZWFkIGFj
Y29zcyBhbGwga2V5LXZhbHVlIHBhaXJzLiBBbm5vdGF0aW9ucyB0aGF0IGdvIGJleW9uZCB0
aGlzCiAgICAgbGltaXQgYXJlIHJlamVjdGVkCiAqICAgVmFsaWQgYW5ub3RhdGlvbiBrZXlz
IGhhdmUgdHdvIHNlZ21lbnRzOiBhbiBvcHRpb25hbCBwcmVmaXggYW5kIG5hbWUsCiAgICAg
c2VwYXJhdGVkIGJ5IGEgc2xhc2ggKC8pLiBUaGUgbmFtZSBzZWdtZW50IGlzIHJlcXVpcmVk
IGFuZCBtdXN0IGJlIDYzCiAgICAgY2hhcmFjdGVycyBvciBsZXNzLCBiZWdpbm5pbmcgYW5k
IGVuZGluZyB3aXRoIGFuIGFscGhhbnVtZXJpYyBjaGFyYWN0ZXIKICAgICAoW2EtejAtOUEt
Wl0pIHdpdGggZGFzaGVzICgtKSwgdW5kZXJzY29yZXMgKF8pLCBkb3RzICguKSwgYW5kCiAg
ICAgYWxwaGFudW1lcmljcyBiZXR3ZWVuLiBUaGUgcHJlZml4IGlzIG9wdGlvbmFsLiBJZiBz
cGVjaWZpZWQsIHRoZSBwcmVmaXgKICAgICBtdXN0IGJlIGEgRE5TIHN1YmRvbWFpbjogYSBz
ZXJpZXMgb2YgRE5TIGxhYmVscyBzZXBhcmF0ZWQgYnkgZG90cyAoLiksCiAgICAgbm90IGxv
bmdlciB0aGFuIDI1MyBjaGFyYWN0ZXJzIGluIHRvdGFsLCBmb2xsb3dlZCBieSBhIHNsYXNo
ICgvKQogICAgIEFubm90YXRpb25zIHRoYXQgZmFpbHMgdG8gbWVldCB0aGVzZSByZXF1aXJl
bWVudHMgYXJlIHJlamVjdGVkLgoKIE5vdGU6IFRoaXMgZmllbGQgaXMgZXF1aXZhbGVudCB0
byB0aGUgYG1ldGFkYXRhYCBmaWVsZCBpbiB0aGUgdjFiZXRhMSBBUEkuCiBUaGV5IGhhdmUg
dGhlIHNhbWUgc3ludGF4IGFuZCByZWFkL3dyaXRlIHRvIHRoZSBzYW1lIGxvY2F0aW9uIGlu
IFNlcnZpY2UKIERpcmVjdG9yeS4KCgwKBQQAAgMGEgNRAhUKDAoFBAACAwESA1EWIQoMCgUE
AAIDAxIDUSQlCgwKBQQAAgMIEgNRJk4KDwoIBAACAwicCAASA1EnTQqKAwoEBAACBBIEWgJf
BBr7AiBJbW11dGFibGUuIFRoZSBHb29nbGUgQ29tcHV0ZSBFbmdpbmUgbmV0d29yayAoVlBD
KSBvZiB0aGUgZW5kcG9pbnQgaW4gdGhlCiBmb3JtYXQgYHByb2plY3RzLzxwcm9qZWN0IG51
bWJlcj4vbG9jYXRpb25zL2dsb2JhbC9uZXR3b3Jrcy8qYC4KCiBUaGUgcHJvamVjdCBtdXN0
IGJlIHNwZWNpZmllZCBieSBwcm9qZWN0IG51bWJlciAocHJvamVjdCBpZCBpcyByZWplY3Rl
ZCkuCiBJbmNvcnJlY3RseSBmb3JtYXR0ZWQgbmV0d29ya3MgYXJlIHJlamVjdGVkLCB3ZSBh
bHNvIGNoZWNrIHRvIG1ha2Ugc3VyZQogdGhhdCB5b3UgaGF2ZSB0aGUgc2VydmljZWRpcmVj
dG9yeS5uZXR3b3Jrcy5hdHRhY2ggcGVybWlzc2lvbiBvbiB0aGUKIHByb2plY3Qgc3BlY2lm
aWVkLgoKDAoFBAACBAUSA1oCCAoMCgUEAAIEARIDWgkQCgwKBQQAAgQDEgNaExQKDQoFBAAC
BAgSBFoVXwMKDwoIBAACBAicCAASA1sEKwoPCgcEAAIECJ8IEgRcBF4FCmAKBAQAAgUSA2MC
PRpTIE91dHB1dCBvbmx5LiBUaGUgZ2xvYmFsbHkgdW5pcXVlIGlkZW50aWZpZXIgb2YgdGhl
IGVuZHBvaW50IGluIHRoZSBVVUlENAogZm9ybWF0LgoKDAoFBAACBQUSA2MCCAoMCgUEAAIF
ARIDYwkMCgwKBQQAAgUDEgNjDxAKDAoFBAACBQgSA2MRPAoPCggEAAIFCJwIABIDYxI7YgZw
cm90bzM=
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Servicedirectory::V1::Endpoint::Endpoint ===
    # Fields for Endpoint
    # Field: name Type: 9 ()
    # Field: address Type: 9 ()
    # Field: port Type: 5 ()
    # Field: annotations Type: 11 (.google.cloud.servicedirectory.v1.Endpoint.AnnotationsEntry)
    # Field: network Type: 9 ()
    # Field: uid Type: 9 ()

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Servicedirectory::V1::Endpoint - Compiled Protocol Buffers messages for google/cloud/servicedirectory/v1/endpoint.proto

=head1 SYNOPSIS

    use Google::Cloud::Servicedirectory::V1::Endpoint;

    my $msg = Google::Cloud::Servicedirectory::V1::Endpoint::Endpoint->new({
        name => $name,
        address => $address,
        port => $port,
        annotations => $annotations,
    });

    # Read or update a field
    my $val = $msg->name();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Servicedirectory::V1::Endpoint::Endpoint->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/servicedirectory/v1/endpoint.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Servicedirectory::V1::Endpoint::Endpoint

An individual endpoint that provides a
[service][google.cloud.servicedirectory.v1.Service]. The service must
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

=item * C<< $msg->annotations() >> / C<< $msg->annotations($value) >>

Type: C<Message> (L<Google::Cloud::Servicedirectory::V1::Endpoint::Endpoint::AnnotationsEntry>)

Optional. Annotations for the endpoint. This data can be consumed by
service clients.

Restrictions:

*   The entire annotations dictionary may contain up to 512 characters,
    spread accoss all key-value pairs. Annotations that go beyond this
    limit are rejected
*   Valid annotation keys have two segments: an optional prefix and name,
    separated by a slash (/). The name segment is required and must be 63
    characters or less, beginning and ending with an alphanumeric character
    ([a-z0-9A-Z]) with dashes (-), underscores (_), dots (.), and
    alphanumerics between. The prefix is optional. If specified, the prefix
    must be a DNS subdomain: a series of DNS labels separated by dots (.),
    not longer than 253 characters in total, followed by a slash (/)
    Annotations that fails to meet these requirements are rejected.

Note: This field is equivalent to the `metadata` field in the v1beta1 API.
They have the same syntax and read/write to the same location in Service
Directory.

=item * C<< $msg->network() >> / C<< $msg->network($value) >>

Type: C<String>

Immutable. The Google Compute Engine network (VPC) of the endpoint in the
format `projects/<project number>/locations/global/networks/*`.

The project must be specified by project number (project id is rejected).
Incorrectly formatted networks are rejected, we also check to make sure
that you have the servicedirectory.networks.attach permission on the
project specified.

=item * C<< $msg->uid() >> / C<< $msg->uid($value) >>

Type: C<String>

Output only. The globally unique identifier of the endpoint in the UUID4
format.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Servicedirectory::V1::Endpoint::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
