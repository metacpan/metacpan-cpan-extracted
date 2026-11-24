package Google::Cloud::Servicedirectory::V1beta1::LookupService;

use strict;
use warnings;

our $VERSION = '0.14';

use Protobuf::Message;
use Protobuf::DescriptorPool;
use Protobuf::Internal qw(:all);
use MIME::Base64;

BEGIN {
    eval { require Google::Api::Annotations };
    eval { require Google::Api::Client };
    eval { require Google::Api::FieldBehavior };
    eval { require Google::Api::Resource };
    eval { require Google::Cloud::Servicedirectory::V1beta1::Service };
    my $descriptor_b64 = <<'EOF';
Cjpnb29nbGUvY2xvdWQvc2VydmljZWRpcmVjdG9yeS92MWJldGExL2xvb2t1cF9zZXJ2aWNl
LnByb3RvEiVnb29nbGUuY2xvdWQuc2VydmljZWRpcmVjdG9yeS52MWJldGExGhxnb29nbGUv
YXBpL2Fubm90YXRpb25zLnByb3RvGhdnb29nbGUvYXBpL2NsaWVudC5wcm90bxofZ29vZ2xl
L2FwaS9maWVsZF9iZWhhdmlvci5wcm90bxoZZ29vZ2xlL2FwaS9yZXNvdXJjZS5wcm90bxoz
Z29vZ2xlL2Nsb3VkL3NlcnZpY2VkaXJlY3RvcnkvdjFiZXRhMS9zZXJ2aWNlLnByb3RvIrQB
ChVSZXNvbHZlU2VydmljZVJlcXVlc3QSQwoEbmFtZRgBIAEoCUIv4EEC+kEpCidzZXJ2aWNl
ZGlyZWN0b3J5Lmdvb2dsZWFwaXMuY29tL1NlcnZpY2VSBG5hbWUSKAoNbWF4X2VuZHBvaW50
cxgCIAEoBUID4EEBUgxtYXhFbmRwb2ludHMSLAoPZW5kcG9pbnRfZmlsdGVyGAMgASgJQgPg
QQFSDmVuZHBvaW50RmlsdGVyImIKFlJlc29sdmVTZXJ2aWNlUmVzcG9uc2USSAoHc2Vydmlj
ZRgBIAEoCzIuLmdvb2dsZS5jbG91ZC5zZXJ2aWNlZGlyZWN0b3J5LnYxYmV0YTEuU2Vydmlj
ZVIHc2VydmljZTLHAgoNTG9va3VwU2VydmljZRLgAQoOUmVzb2x2ZVNlcnZpY2USPC5nb29n
bGUuY2xvdWQuc2VydmljZWRpcmVjdG9yeS52MWJldGExLlJlc29sdmVTZXJ2aWNlUmVxdWVz
dBo9Lmdvb2dsZS5jbG91ZC5zZXJ2aWNlZGlyZWN0b3J5LnYxYmV0YTEuUmVzb2x2ZVNlcnZp
Y2VSZXNwb25zZSJRgtPkkwJLIkYvdjFiZXRhMS97bmFtZT1wcm9qZWN0cy8qL2xvY2F0aW9u
cy8qL25hbWVzcGFjZXMvKi9zZXJ2aWNlcy8qfTpyZXNvbHZlOgEqGlPKQR9zZXJ2aWNlZGly
ZWN0b3J5Lmdvb2dsZWFwaXMuY29t0kEuaHR0cHM6Ly93d3cuZ29vZ2xlYXBpcy5jb20vYXV0
aC9jbG91ZC1wbGF0Zm9ybUKTAgopY29tLmdvb2dsZS5jbG91ZC5zZXJ2aWNlZGlyZWN0b3J5
LnYxYmV0YTFCEkxvb2t1cFNlcnZpY2VQcm90b1ABWlVjbG91ZC5nb29nbGUuY29tL2dvL3Nl
cnZpY2VkaXJlY3RvcnkvYXBpdjFiZXRhMS9zZXJ2aWNlZGlyZWN0b3J5cGI7c2VydmljZWRp
cmVjdG9yeXBiqgIlR29vZ2xlLkNsb3VkLlNlcnZpY2VEaXJlY3RvcnkuVjFCZXRhMcoCJUdv
b2dsZVxDbG91ZFxTZXJ2aWNlRGlyZWN0b3J5XFYxYmV0YTHqAihHb29nbGU6OkNsb3VkOjpT
ZXJ2aWNlRGlyZWN0b3J5OjpWMWJldGExStUeCgYSBA4AbQEKvAQKAQwSAw4AEjKxBCBDb3B5
cmlnaHQgMjAyNSBHb29nbGUgTExDCgogTGljZW5zZWQgdW5kZXIgdGhlIEFwYWNoZSBMaWNl
bnNlLCBWZXJzaW9uIDIuMCAodGhlICJMaWNlbnNlIik7CiB5b3UgbWF5IG5vdCB1c2UgdGhp
cyBmaWxlIGV4Y2VwdCBpbiBjb21wbGlhbmNlIHdpdGggdGhlIExpY2Vuc2UuCiBZb3UgbWF5
IG9idGFpbiBhIGNvcHkgb2YgdGhlIExpY2Vuc2UgYXQKCiAgICAgaHR0cDovL3d3dy5hcGFj
aGUub3JnL2xpY2Vuc2VzL0xJQ0VOU0UtMi4wCgogVW5sZXNzIHJlcXVpcmVkIGJ5IGFwcGxp
Y2FibGUgbGF3IG9yIGFncmVlZCB0byBpbiB3cml0aW5nLCBzb2Z0d2FyZQogZGlzdHJpYnV0
ZWQgdW5kZXIgdGhlIExpY2Vuc2UgaXMgZGlzdHJpYnV0ZWQgb24gYW4gIkFTIElTIiBCQVNJ
UywKIFdJVEhPVVQgV0FSUkFOVElFUyBPUiBDT05ESVRJT05TIE9GIEFOWSBLSU5ELCBlaXRo
ZXIgZXhwcmVzcyBvciBpbXBsaWVkLgogU2VlIHRoZSBMaWNlbnNlIGZvciB0aGUgc3BlY2lm
aWMgbGFuZ3VhZ2UgZ292ZXJuaW5nIHBlcm1pc3Npb25zIGFuZAogbGltaXRhdGlvbnMgdW5k
ZXIgdGhlIExpY2Vuc2UuCgoICgECEgMQAC4KCQoCAwASAxIAJgoJCgIDARIDEwAhCgkKAgMC
EgMUACkKCQoCAwMSAxUAIwoJCgIDBBIDFgA9CggKAQgSAxgAQgoJCgIIJRIDGABCCggKAQgS
AxkAbAoJCgIICxIDGQBsCggKAQgSAxoAIgoJCgIIChIDGgAiCggKAQgSAxsAMwoJCgIICBID
GwAzCggKAQgSAxwAQgoJCgIIARIDHABCCggKAQgSAx0AQgoJCgIIKRIDHQBCCggKAQgSAx4A
QQoJCgIILRIDHgBBCksKAgYAEgQhAC8BGj8gU2VydmljZSBEaXJlY3RvcnkgQVBJIGZvciBs
b29raW5nIHVwIHNlcnZpY2UgZGF0YSBhdCBydW50aW1lLgoKCgoDBgABEgMhCBUKCgoDBgAD
EgMiAkcKDAoFBgADmQgSAyICRwoLCgMGAAMSBCMCJDcKDQoFBgADmggSBCMCJDcKtQEKBAYA
AgASBCkCLgMapgEgUmV0dXJucyBhIFtzZXJ2aWNlXVtnb29nbGUuY2xvdWQuc2VydmljZWRp
cmVjdG9yeS52MWJldGExLlNlcnZpY2VdIGFuZCBpdHMKIGFzc29jaWF0ZWQgZW5kcG9pbnRz
LgogUmVzb2x2aW5nIGEgc2VydmljZSBpcyBub3QgY29uc2lkZXJlZCBhbiBhY3RpdmUgZGV2
ZWxvcGVyIG1ldGhvZC4KCgwKBQYAAgABEgMpBhQKDAoFBgACAAISAykVKgoMCgUGAAIAAxID
KTVLCg0KBQYAAgAEEgQqBC0GChEKCQYAAgAEsMq8IhIEKgQtBgrTAQoCBAASBDQAZwEaxgEg
VGhlIHJlcXVlc3QgbWVzc2FnZSBmb3IKIFtMb29rdXBTZXJ2aWNlLlJlc29sdmVTZXJ2aWNl
XVtnb29nbGUuY2xvdWQuc2VydmljZWRpcmVjdG9yeS52MWJldGExLkxvb2t1cFNlcnZpY2Uu
UmVzb2x2ZVNlcnZpY2VdLgogTG9va3MgdXAgYSBzZXJ2aWNlIGJ5IGl0cyBuYW1lLCByZXR1
cm5zIHRoZSBzZXJ2aWNlIGFuZCBpdHMgZW5kcG9pbnRzLgoKCgoDBAABEgM0CB0KPQoEBAAC
ABIENgI7BBovIFJlcXVpcmVkLiBUaGUgbmFtZSBvZiB0aGUgc2VydmljZSB0byByZXNvbHZl
LgoKDAoFBAACAAUSAzYCCAoMCgUEAAIAARIDNgkNCgwKBQQAAgADEgM2EBEKDQoFBAACAAgS
BDYSOwMKDwoIBAACAAicCAASAzcEKgoPCgcEAAIACJ8IEgQ4BDoFCukBCgQEAAIBEgNAAkMa
2wEgT3B0aW9uYWwuIFRoZSBtYXhpbXVtIG51bWJlciBvZiBlbmRwb2ludHMgdG8gcmV0dXJu
LiBEZWZhdWx0cyB0byAyNS4KIE1heGltdW0gaXMgMTAwLiBJZiBhIHZhbHVlIGxlc3MgdGhh
biBvbmUgaXMgc3BlY2lmaWVkLCB0aGUgRGVmYXVsdCBpcyB1c2VkLgogSWYgYSB2YWx1ZSBn
cmVhdGVyIHRoYW4gdGhlIE1heGltdW0gaXMgc3BlY2lmaWVkLCB0aGUgTWF4aW11bSBpcyB1
c2VkLgoKDAoFBAACAQUSA0ACBwoMCgUEAAIBARIDQAgVCgwKBQQAAgEDEgNAGBkKDAoFBAAC
AQgSA0AaQgoPCggEAAIBCJwIABIDQBtBCtkNCgQEAAICEgNmAkYayw0gT3B0aW9uYWwuIFRo
ZSBmaWx0ZXIgYXBwbGllZCB0byB0aGUgZW5kcG9pbnRzIG9mIHRoZSByZXNvbHZlZCBzZXJ2
aWNlLgoKIEdlbmVyYWwgYGZpbHRlcmAgc3RyaW5nIHN5bnRheDoKIGA8ZmllbGQ+IDxvcGVy
YXRvcj4gPHZhbHVlPiAoPGxvZ2ljYWwgY29ubmVjdG9yPilgCgogKiAgIGA8ZmllbGQ+YCBj
YW4gYmUgYG5hbWVgLCBgYWRkcmVzc2AsIGBwb3J0YCwgb3IgYG1ldGFkYXRhLjxrZXk+YCBm
b3IKICAgICBtYXAgZmllbGQKICogICBgPG9wZXJhdG9yPmAgY2FuIGJlIGA8YCwgYD5gLCBg
PD1gLCBgPj1gLCBgIT1gLCBgPWAsIGA6YC4gT2Ygd2hpY2ggYDpgCiAgICAgbWVhbnMgYEhB
U2AsIGFuZCBpcyByb3VnaGx5IHRoZSBzYW1lIGFzIGA9YAogKiAgIGA8dmFsdWU+YCBtdXN0
IGJlIHRoZSBzYW1lIGRhdGEgdHlwZSBhcyBmaWVsZAogKiAgIGA8bG9naWNhbCBjb25uZWN0
b3I+YCBjYW4gYmUgYEFORGAsIGBPUmAsIGBOT1RgCgogRXhhbXBsZXMgb2YgdmFsaWQgZmls
dGVyczoKCiAqICAgYG1ldGFkYXRhLm93bmVyYCByZXR1cm5zIGVuZHBvaW50cyB0aGF0IGhh
dmUgYSBhbm5vdGF0aW9uIHdpdGggdGhlIGtleQogICAgIGBvd25lcmAsIHRoaXMgaXMgdGhl
IHNhbWUgYXMgYG1ldGFkYXRhOm93bmVyYAogKiAgIGBtZXRhZGF0YS5wcm90b2NvbD1nUlBD
YCByZXR1cm5zIGVuZHBvaW50cyB0aGF0IGhhdmUga2V5L3ZhbHVlCiAgICAgYHByb3RvY29s
PWdSUENgCiAqICAgYGFkZHJlc3M9MTkyLjEwOC4xLjEwNWAgcmV0dXJucyBlbmRwb2ludHMg
dGhhdCBoYXZlIHRoaXMgYWRkcmVzcwogKiAgIGBwb3J0PjgwODBgIHJldHVybnMgZW5kcG9p
bnRzIHRoYXQgaGF2ZSBwb3J0IG51bWJlciBsYXJnZXIgdGhhbiA4MDgwCiAqCiBgbmFtZT5w
cm9qZWN0cy9teS1wcm9qZWN0L2xvY2F0aW9ucy91cy1lYXN0MS9uYW1lc3BhY2VzL215LW5h
bWVzcGFjZS9zZXJ2aWNlcy9teS1zZXJ2aWNlL2VuZHBvaW50cy9lbmRwb2ludC1jYAogICAg
IHJldHVybnMgZW5kcG9pbnRzIHRoYXQgaGF2ZSBuYW1lIHRoYXQgaXMgYWxwaGFiZXRpY2Fs
bHkgbGF0ZXIgdGhhbiB0aGUKICAgICBzdHJpbmcsIHNvICJlbmRwb2ludC1lIiBpcyByZXR1
cm5lZCBidXQgImVuZHBvaW50LWEiIGlzIG5vdAogKgogYG5hbWU9cHJvamVjdHMvbXktcHJv
amVjdC9sb2NhdGlvbnMvdXMtY2VudHJhbDEvbmFtZXNwYWNlcy9teS1uYW1lc3BhY2Uvc2Vy
dmljZXMvbXktc2VydmljZS9lbmRwb2ludHMvZXAtMWAKICAgICAgcmV0dXJucyB0aGUgZW5k
cG9pbnQgdGhhdCBoYXMgYW4gZW5kcG9pbnRfaWQgZXF1YWwgdG8gYGVwLTFgCiAqICAgYG1l
dGFkYXRhLm93bmVyIT1zZCBBTkQgbWV0YWRhdGEuZm9vPWJhcmAgcmV0dXJucyBlbmRwb2lu
dHMgdGhhdCBoYXZlCiAgICAgYG93bmVyYCBpbiBhbm5vdGF0aW9uIGtleSBidXQgdmFsdWUg
aXMgbm90IGBzZGAgQU5EIGhhdmUga2V5L3ZhbHVlCiAgICAgIGBmb289YmFyYAogKiAgIGBk
b2Vzbm90ZXhpc3QuZm9vPWJhcmAgcmV0dXJucyBhbiBlbXB0eSBsaXN0LiBOb3RlIHRoYXQg
ZW5kcG9pbnQKICAgICBkb2Vzbid0IGhhdmUgYSBmaWVsZCBjYWxsZWQgImRvZXNub3RleGlz
dCIuIFNpbmNlIHRoZSBmaWx0ZXIgZG9lcyBub3QKICAgICBtYXRjaCBhbnkgZW5kcG9pbnQs
IGl0IHJldHVybnMgbm8gcmVzdWx0cwoKIEZvciBtb3JlIGluZm9ybWF0aW9uIGFib3V0IGZp
bHRlcmluZywgc2VlCiBbQVBJIEZpbHRlcmluZ10oaHR0cHM6Ly9haXAuZGV2LzE2MCkuCgoM
CgUEAAICBRIDZgIICgwKBQQAAgIBEgNmCRgKDAoFBAACAgMSA2YbHAoMCgUEAAICCBIDZh1F
Cg8KCAQAAgIInAgAEgNmHkQKiwEKAgQBEgRrAG0BGn8gVGhlIHJlc3BvbnNlIG1lc3NhZ2Ug
Zm9yCiBbTG9va3VwU2VydmljZS5SZXNvbHZlU2VydmljZV1bZ29vZ2xlLmNsb3VkLnNlcnZp
Y2VkaXJlY3RvcnkudjFiZXRhMS5Mb29rdXBTZXJ2aWNlLlJlc29sdmVTZXJ2aWNlXS4KCgoK
AwQBARIDawgeCgsKBAQBAgASA2wCFgoMCgUEAQIABhIDbAIJCgwKBQQBAgABEgNsChEKDAoF
BAECAAMSA2wUFWIGcHJvdG8z
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Servicedirectory::V1beta1::LookupService::ResolveServiceRequest ===
    # Fields for ResolveServiceRequest
    # Field: name Type: 9 ()
    # Field: max_endpoints Type: 5 ()
    # Field: endpoint_filter Type: 9 ()

# === Message: Google::Cloud::Servicedirectory::V1beta1::LookupService::ResolveServiceResponse ===
    # Fields for ResolveServiceResponse
    # Field: service Type: 11 (.google.cloud.servicedirectory.v1beta1.Service)

# === Service Client: Google::Cloud::Servicedirectory::V1beta1::LookupService::LookupServiceClient ===
package Google::Cloud::Servicedirectory::V1beta1::LookupService::LookupServiceClient;

=pod

=head2 Service Client: Google::Cloud::Servicedirectory::V1beta1::LookupService::LookupServiceClient

Client stub representing the remote C<LookupService> gRPC service. Delegates call dispatching to L<Google::gRPC::Client>.

=head3 target

The endpoint target address. Defaults to C<servicedirectory.googleapis.com:443>.

=head3 credentials

The authentication credentials provider. Defaults to application default credentials via L<Google::Auth>.

=cut

use Moo;
use Google::Auth;
use Google::gRPC::Client;

has credentials => ( is => 'ro', default => sub { Google::Auth->default() } );
has target      => ( is => 'ro', default => 'servicedirectory.googleapis.com:443' );

has _grpc_client => (
    is => 'ro',
    lazy => 1,
    builder => sub {
        my $self = shift;
        return Google::gRPC::Client->new(
            target     => $self->target,
            auth_token => $self->credentials->get_token(),
        );
    }
);

sub resolve_service {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Servicedirectory::V1beta1::LookupService::ResolveServiceRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.servicedirectory.v1beta1.LookupService',
        method         => 'ResolveService',
        request        => $req,
        response_class => 'Google::Cloud::Servicedirectory::V1beta1::LookupService::ResolveServiceResponse',
    });
}

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Servicedirectory::V1beta1::LookupService - Compiled Protocol Buffers messages for google/cloud/servicedirectory/v1beta1/lookup_service.proto

=head1 SYNOPSIS

    use Google::Cloud::Servicedirectory::V1beta1::LookupService;

    my $msg = Google::Cloud::Servicedirectory::V1beta1::LookupService::ResolveServiceRequest->new({
        name => $name,
        max_endpoints => $max_endpoints,
        endpoint_filter => $endpoint_filter,
    });

    # Read or update a field
    my $val = $msg->name();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Servicedirectory::V1beta1::LookupService::ResolveServiceRequest->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/servicedirectory/v1beta1/lookup_service.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Servicedirectory::V1beta1::LookupService::ResolveServiceRequest

The request message for
[LookupService.ResolveService][google.cloud.servicedirectory.v1beta1.LookupService.ResolveService].
Looks up a service by its name, returns the service and its endpoints.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. The name of the service to resolve.

=item * C<< $msg->max_endpoints() >> / C<< $msg->max_endpoints($value) >>

Type: C<Int32>

Optional. The maximum number of endpoints to return. Defaults to 25.
Maximum is 100. If a value less than one is specified, the Default is used.
If a value greater than the Maximum is specified, the Maximum is used.

=item * C<< $msg->endpoint_filter() >> / C<< $msg->endpoint_filter($value) >>

Type: C<String>

Optional. The filter applied to the endpoints of the resolved service.

General `filter` string syntax:
`<field> <operator> <value> (<logical connector>)`

*   `<field>` can be `name`, `address`, `port`, or `metadata.<key>` for
    map field
*   `<operator>` can be `<`, `>`, `<=`, `>=`, `!=`, `=`, `:`. Of which `:`
    means `HAS`, and is roughly the same as `=`
*   `<value>` must be the same data type as field
*   `<logical connector>` can be `AND`, `OR`, `NOT`

Examples of valid filters:

*   `metadata.owner` returns endpoints that have a annotation with the key
    `owner`, this is the same as `metadata:owner`
*   `metadata.protocol=gRPC` returns endpoints that have key/value
    `protocol=gRPC`
*   `address=192.108.1.105` returns endpoints that have this address
*   `port>8080` returns endpoints that have port number larger than 8080
*
`name>projects/my-project/locations/us-east1/namespaces/my-namespace/services/my-service/endpoints/endpoint-c`
    returns endpoints that have name that is alphabetically later than the
    string, so "endpoint-e" is returned but "endpoint-a" is not
*
`name=projects/my-project/locations/us-central1/namespaces/my-namespace/services/my-service/endpoints/ep-1`
     returns the endpoint that has an endpoint_id equal to `ep-1`
*   `metadata.owner!=sd AND metadata.foo=bar` returns endpoints that have
    `owner` in annotation key but value is not `sd` AND have key/value
     `foo=bar`
*   `doesnotexist.foo=bar` returns an empty list. Note that endpoint
    doesn't have a field called "doesnotexist". Since the filter does not
    match any endpoint, it returns no results

For more information about filtering, see
[API Filtering](https://aip.dev/160).

=back

=head2 Google::Cloud::Servicedirectory::V1beta1::LookupService::ResolveServiceResponse

The response message for
[LookupService.ResolveService][google.cloud.servicedirectory.v1beta1.LookupService.ResolveService].

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->service() >> / C<< $msg->service($value) >>

Type: C<Message> (L<Google::Cloud::Servicedirectory::V1beta1::Service::Service>)

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Servicedirectory::V1beta1::LookupService::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
