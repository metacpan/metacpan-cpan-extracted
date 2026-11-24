package Google::Cloud::Servicedirectory::V1::LookupService;

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
    eval { require Google::Cloud::Servicedirectory::V1::Service };
    my $descriptor_b64 = <<'EOF';
CjVnb29nbGUvY2xvdWQvc2VydmljZWRpcmVjdG9yeS92MS9sb29rdXBfc2VydmljZS5wcm90
bxIgZ29vZ2xlLmNsb3VkLnNlcnZpY2VkaXJlY3RvcnkudjEaHGdvb2dsZS9hcGkvYW5ub3Rh
dGlvbnMucHJvdG8aF2dvb2dsZS9hcGkvY2xpZW50LnByb3RvGh9nb29nbGUvYXBpL2ZpZWxk
X2JlaGF2aW9yLnByb3RvGhlnb29nbGUvYXBpL3Jlc291cmNlLnByb3RvGi5nb29nbGUvY2xv
dWQvc2VydmljZWRpcmVjdG9yeS92MS9zZXJ2aWNlLnByb3RvIrQBChVSZXNvbHZlU2Vydmlj
ZVJlcXVlc3QSQwoEbmFtZRgBIAEoCUIv4EEC+kEpCidzZXJ2aWNlZGlyZWN0b3J5Lmdvb2ds
ZWFwaXMuY29tL1NlcnZpY2VSBG5hbWUSKAoNbWF4X2VuZHBvaW50cxgCIAEoBUID4EEBUgxt
YXhFbmRwb2ludHMSLAoPZW5kcG9pbnRfZmlsdGVyGAMgASgJQgPgQQFSDmVuZHBvaW50Rmls
dGVyIl0KFlJlc29sdmVTZXJ2aWNlUmVzcG9uc2USQwoHc2VydmljZRgBIAEoCzIpLmdvb2ds
ZS5jbG91ZC5zZXJ2aWNlZGlyZWN0b3J5LnYxLlNlcnZpY2VSB3NlcnZpY2UyuAIKDUxvb2t1
cFNlcnZpY2US0QEKDlJlc29sdmVTZXJ2aWNlEjcuZ29vZ2xlLmNsb3VkLnNlcnZpY2VkaXJl
Y3RvcnkudjEuUmVzb2x2ZVNlcnZpY2VSZXF1ZXN0GjguZ29vZ2xlLmNsb3VkLnNlcnZpY2Vk
aXJlY3RvcnkudjEuUmVzb2x2ZVNlcnZpY2VSZXNwb25zZSJMgtPkkwJGIkEvdjEve25hbWU9
cHJvamVjdHMvKi9sb2NhdGlvbnMvKi9uYW1lc3BhY2VzLyovc2VydmljZXMvKn06cmVzb2x2
ZToBKhpTykEfc2VydmljZWRpcmVjdG9yeS5nb29nbGVhcGlzLmNvbdJBLmh0dHBzOi8vd3d3
Lmdvb2dsZWFwaXMuY29tL2F1dGgvY2xvdWQtcGxhdGZvcm1C+gEKJGNvbS5nb29nbGUuY2xv
dWQuc2VydmljZWRpcmVjdG9yeS52MUISTG9va3VwU2VydmljZVByb3RvUAFaUGNsb3VkLmdv
b2dsZS5jb20vZ28vc2VydmljZWRpcmVjdG9yeS9hcGl2MS9zZXJ2aWNlZGlyZWN0b3J5cGI7
c2VydmljZWRpcmVjdG9yeXBiqgIgR29vZ2xlLkNsb3VkLlNlcnZpY2VEaXJlY3RvcnkuVjHK
AiBHb29nbGVcQ2xvdWRcU2VydmljZURpcmVjdG9yeVxWMeoCI0dvb2dsZTo6Q2xvdWQ6OlNl
cnZpY2VEaXJlY3Rvcnk6OlYxStceCgYSBA4AbQEKvAQKAQwSAw4AEjKxBCBDb3B5cmlnaHQg
MjAyNSBHb29nbGUgTExDCgogTGljZW5zZWQgdW5kZXIgdGhlIEFwYWNoZSBMaWNlbnNlLCBW
ZXJzaW9uIDIuMCAodGhlICJMaWNlbnNlIik7CiB5b3UgbWF5IG5vdCB1c2UgdGhpcyBmaWxl
IGV4Y2VwdCBpbiBjb21wbGlhbmNlIHdpdGggdGhlIExpY2Vuc2UuCiBZb3UgbWF5IG9idGFp
biBhIGNvcHkgb2YgdGhlIExpY2Vuc2UgYXQKCiAgICAgaHR0cDovL3d3dy5hcGFjaGUub3Jn
L2xpY2Vuc2VzL0xJQ0VOU0UtMi4wCgogVW5sZXNzIHJlcXVpcmVkIGJ5IGFwcGxpY2FibGUg
bGF3IG9yIGFncmVlZCB0byBpbiB3cml0aW5nLCBzb2Z0d2FyZQogZGlzdHJpYnV0ZWQgdW5k
ZXIgdGhlIExpY2Vuc2UgaXMgZGlzdHJpYnV0ZWQgb24gYW4gIkFTIElTIiBCQVNJUywKIFdJ
VEhPVVQgV0FSUkFOVElFUyBPUiBDT05ESVRJT05TIE9GIEFOWSBLSU5ELCBlaXRoZXIgZXhw
cmVzcyBvciBpbXBsaWVkLgogU2VlIHRoZSBMaWNlbnNlIGZvciB0aGUgc3BlY2lmaWMgbGFu
Z3VhZ2UgZ292ZXJuaW5nIHBlcm1pc3Npb25zIGFuZAogbGltaXRhdGlvbnMgdW5kZXIgdGhl
IExpY2Vuc2UuCgoICgECEgMQACkKCQoCAwASAxIAJgoJCgIDARIDEwAhCgkKAgMCEgMUACkK
CQoCAwMSAxUAIwoJCgIDBBIDFgA4CggKAQgSAxgAPQoJCgIIJRIDGAA9CggKAQgSAxkAZwoJ
CgIICxIDGQBnCggKAQgSAxoAIgoJCgIIChIDGgAiCggKAQgSAxsAMwoJCgIICBIDGwAzCggK
AQgSAxwAPQoJCgIIARIDHAA9CggKAQgSAx0APQoJCgIIKRIDHQA9CggKAQgSAx4APAoJCgII
LRIDHgA8CksKAgYAEgQhAC8BGj8gU2VydmljZSBEaXJlY3RvcnkgQVBJIGZvciBsb29raW5n
IHVwIHNlcnZpY2UgZGF0YSBhdCBydW50aW1lLgoKCgoDBgABEgMhCBUKCgoDBgADEgMiAkcK
DAoFBgADmQgSAyICRwoLCgMGAAMSBCMCJDcKDQoFBgADmggSBCMCJDcKsAEKBAYAAgASBCkC
LgMaoQEgUmV0dXJucyBhIFtzZXJ2aWNlXVtnb29nbGUuY2xvdWQuc2VydmljZWRpcmVjdG9y
eS52MS5TZXJ2aWNlXSBhbmQgaXRzCiBhc3NvY2lhdGVkIGVuZHBvaW50cy4KIFJlc29sdmlu
ZyBhIHNlcnZpY2UgaXMgbm90IGNvbnNpZGVyZWQgYW4gYWN0aXZlIGRldmVsb3BlciBtZXRo
b2QuCgoMCgUGAAIAARIDKQYUCgwKBQYAAgACEgMpFSoKDAoFBgACAAMSAyk1SwoNCgUGAAIA
BBIEKgQtBgoRCgkGAAIABLDKvCISBCoELQYKzgEKAgQAEgQ0AGcBGsEBIFRoZSByZXF1ZXN0
IG1lc3NhZ2UgZm9yCiBbTG9va3VwU2VydmljZS5SZXNvbHZlU2VydmljZV1bZ29vZ2xlLmNs
b3VkLnNlcnZpY2VkaXJlY3RvcnkudjEuTG9va3VwU2VydmljZS5SZXNvbHZlU2VydmljZV0u
CiBMb29rcyB1cCBhIHNlcnZpY2UgYnkgaXRzIG5hbWUsIHJldHVybnMgdGhlIHNlcnZpY2Ug
YW5kIGl0cyBlbmRwb2ludHMuCgoKCgMEAAESAzQIHQo9CgQEAAIAEgQ2AjsEGi8gUmVxdWly
ZWQuIFRoZSBuYW1lIG9mIHRoZSBzZXJ2aWNlIHRvIHJlc29sdmUuCgoMCgUEAAIABRIDNgII
CgwKBQQAAgABEgM2CQ0KDAoFBAACAAMSAzYQEQoNCgUEAAIACBIENhI7AwoPCggEAAIACJwI
ABIDNwQqCg8KBwQAAgAInwgSBDgEOgUK6QEKBAQAAgESA0ACQxrbASBPcHRpb25hbC4gVGhl
IG1heGltdW0gbnVtYmVyIG9mIGVuZHBvaW50cyB0byByZXR1cm4uIERlZmF1bHRzIHRvIDI1
LgogTWF4aW11bSBpcyAxMDAuIElmIGEgdmFsdWUgbGVzcyB0aGFuIG9uZSBpcyBzcGVjaWZp
ZWQsIHRoZSBEZWZhdWx0IGlzIHVzZWQuCiBJZiBhIHZhbHVlIGdyZWF0ZXIgdGhhbiB0aGUg
TWF4aW11bSBpcyBzcGVjaWZpZWQsIHRoZSBNYXhpbXVtIGlzIHVzZWQuCgoMCgUEAAIBBRID
QAIHCgwKBQQAAgEBEgNACBUKDAoFBAACAQMSA0AYGQoMCgUEAAIBCBIDQBpCCg8KCAQAAgEI
nAgAEgNAG0EK6g0KBAQAAgISA2YCRhrcDSBPcHRpb25hbC4gVGhlIGZpbHRlciBhcHBsaWVk
IHRvIHRoZSBlbmRwb2ludHMgb2YgdGhlIHJlc29sdmVkIHNlcnZpY2UuCgogR2VuZXJhbCBg
ZmlsdGVyYCBzdHJpbmcgc3ludGF4OgogYDxmaWVsZD4gPG9wZXJhdG9yPiA8dmFsdWU+ICg8
bG9naWNhbCBjb25uZWN0b3I+KWAKCiAqICAgYDxmaWVsZD5gIGNhbiBiZSBgbmFtZWAsIGBh
ZGRyZXNzYCwgYHBvcnRgLCBvciBgYW5ub3RhdGlvbnMuPGtleT5gIGZvcgogICAgIG1hcCBm
aWVsZAogKiAgIGA8b3BlcmF0b3I+YCBjYW4gYmUgYDxgLCBgPmAsIGA8PWAsIGA+PWAsIGAh
PWAsIGA9YCwgYDpgLiBPZiB3aGljaCBgOmAKICAgICBtZWFucyBgSEFTYCwgYW5kIGlzIHJv
dWdobHkgdGhlIHNhbWUgYXMgYD1gCiAqICAgYDx2YWx1ZT5gIG11c3QgYmUgdGhlIHNhbWUg
ZGF0YSB0eXBlIGFzIGZpZWxkCiAqICAgYDxsb2dpY2FsIGNvbm5lY3Rvcj5gIGNhbiBiZSBg
QU5EYCwgYE9SYCwgYE5PVGAKCiBFeGFtcGxlcyBvZiB2YWxpZCBmaWx0ZXJzOgoKICogICBg
YW5ub3RhdGlvbnMub3duZXJgIHJldHVybnMgZW5kcG9pbnRzIHRoYXQgaGF2ZSBhIGFubm90
YXRpb24gd2l0aCB0aGUKICAgICBrZXkgYG93bmVyYCwgdGhpcyBpcyB0aGUgc2FtZSBhcyBg
YW5ub3RhdGlvbnM6b3duZXJgCiAqICAgYGFubm90YXRpb25zLnByb3RvY29sPWdSUENgIHJl
dHVybnMgZW5kcG9pbnRzIHRoYXQgaGF2ZSBrZXkvdmFsdWUKICAgICBgcHJvdG9jb2w9Z1JQ
Q2AKICogICBgYWRkcmVzcz0xOTIuMTA4LjEuMTA1YCByZXR1cm5zIGVuZHBvaW50cyB0aGF0
IGhhdmUgdGhpcyBhZGRyZXNzCiAqICAgYHBvcnQ+ODA4MGAgcmV0dXJucyBlbmRwb2ludHMg
dGhhdCBoYXZlIHBvcnQgbnVtYmVyIGxhcmdlciB0aGFuIDgwODAKICoKIGBuYW1lPnByb2pl
Y3RzL215LXByb2plY3QvbG9jYXRpb25zL3VzLWVhc3QxL25hbWVzcGFjZXMvbXktbmFtZXNw
YWNlL3NlcnZpY2VzL215LXNlcnZpY2UvZW5kcG9pbnRzL2VuZHBvaW50LWNgCiAgICAgcmV0
dXJucyBlbmRwb2ludHMgdGhhdCBoYXZlIG5hbWUgdGhhdCBpcyBhbHBoYWJldGljYWxseSBs
YXRlciB0aGFuIHRoZQogICAgIHN0cmluZywgc28gImVuZHBvaW50LWUiIGlzIHJldHVybmVk
IGJ1dCAiZW5kcG9pbnQtYSIgaXMgbm90CiAqCiBgbmFtZT1wcm9qZWN0cy9teS1wcm9qZWN0
L2xvY2F0aW9ucy91cy1jZW50cmFsMS9uYW1lc3BhY2VzL215LW5hbWVzcGFjZS9zZXJ2aWNl
cy9teS1zZXJ2aWNlL2VuZHBvaW50cy9lcC0xYAogICAgICByZXR1cm5zIHRoZSBlbmRwb2lu
dCB0aGF0IGhhcyBhbiBlbmRwb2ludF9pZCBlcXVhbCB0byBgZXAtMWAKICogICBgYW5ub3Rh
dGlvbnMub3duZXIhPXNkIEFORCBhbm5vdGF0aW9ucy5mb289YmFyYCByZXR1cm5zIGVuZHBv
aW50cyB0aGF0CiAgICAgaGF2ZSBgb3duZXJgIGluIGFubm90YXRpb24ga2V5IGJ1dCB2YWx1
ZSBpcyBub3QgYHNkYCBBTkQgaGF2ZQogICAgIGtleS92YWx1ZSBgZm9vPWJhcmAKICogICBg
ZG9lc25vdGV4aXN0LmZvbz1iYXJgIHJldHVybnMgYW4gZW1wdHkgbGlzdC4gTm90ZSB0aGF0
IGVuZHBvaW50CiAgICAgZG9lc24ndCBoYXZlIGEgZmllbGQgY2FsbGVkICJkb2Vzbm90ZXhp
c3QiLiBTaW5jZSB0aGUgZmlsdGVyIGRvZXMgbm90CiAgICAgbWF0Y2ggYW55IGVuZHBvaW50
LCBpdCByZXR1cm5zIG5vIHJlc3VsdHMKCiBGb3IgbW9yZSBpbmZvcm1hdGlvbiBhYm91dCBm
aWx0ZXJpbmcsIHNlZQogW0FQSSBGaWx0ZXJpbmddKGh0dHBzOi8vYWlwLmRldi8xNjApLgoK
DAoFBAACAgUSA2YCCAoMCgUEAAICARIDZgkYCgwKBQQAAgIDEgNmGxwKDAoFBAACAggSA2Yd
RQoPCggEAAICCJwIABIDZh5ECoYBCgIEARIEawBtARp6IFRoZSByZXNwb25zZSBtZXNzYWdl
IGZvcgogW0xvb2t1cFNlcnZpY2UuUmVzb2x2ZVNlcnZpY2VdW2dvb2dsZS5jbG91ZC5zZXJ2
aWNlZGlyZWN0b3J5LnYxLkxvb2t1cFNlcnZpY2UuUmVzb2x2ZVNlcnZpY2VdLgoKCgoDBAEB
EgNrCB4KCwoEBAECABIDbAIWCgwKBQQBAgAGEgNsAgkKDAoFBAECAAESA2wKEQoMCgUEAQIA
AxIDbBQVYgZwcm90bzM=
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Servicedirectory::V1::LookupService::ResolveServiceRequest ===
    # Fields for ResolveServiceRequest
    # Field: name Type: 9 ()
    # Field: max_endpoints Type: 5 ()
    # Field: endpoint_filter Type: 9 ()

# === Message: Google::Cloud::Servicedirectory::V1::LookupService::ResolveServiceResponse ===
    # Fields for ResolveServiceResponse
    # Field: service Type: 11 (.google.cloud.servicedirectory.v1.Service)

# === Service Client: Google::Cloud::Servicedirectory::V1::LookupService::LookupServiceClient ===
package Google::Cloud::Servicedirectory::V1::LookupService::LookupServiceClient;

=pod

=head2 Service Client: Google::Cloud::Servicedirectory::V1::LookupService::LookupServiceClient

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
        ? Google::Cloud::Servicedirectory::V1::LookupService::ResolveServiceRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.servicedirectory.v1.LookupService',
        method         => 'ResolveService',
        request        => $req,
        response_class => 'Google::Cloud::Servicedirectory::V1::LookupService::ResolveServiceResponse',
    });
}

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Servicedirectory::V1::LookupService - Compiled Protocol Buffers messages for google/cloud/servicedirectory/v1/lookup_service.proto

=head1 SYNOPSIS

    use Google::Cloud::Servicedirectory::V1::LookupService;

    my $msg = Google::Cloud::Servicedirectory::V1::LookupService::ResolveServiceRequest->new({
        name => $name,
        max_endpoints => $max_endpoints,
        endpoint_filter => $endpoint_filter,
    });

    # Read or update a field
    my $val = $msg->name();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Servicedirectory::V1::LookupService::ResolveServiceRequest->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/servicedirectory/v1/lookup_service.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Servicedirectory::V1::LookupService::ResolveServiceRequest

The request message for
[LookupService.ResolveService][google.cloud.servicedirectory.v1.LookupService.ResolveService].
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

*   `<field>` can be `name`, `address`, `port`, or `annotations.<key>` for
    map field
*   `<operator>` can be `<`, `>`, `<=`, `>=`, `!=`, `=`, `:`. Of which `:`
    means `HAS`, and is roughly the same as `=`
*   `<value>` must be the same data type as field
*   `<logical connector>` can be `AND`, `OR`, `NOT`

Examples of valid filters:

*   `annotations.owner` returns endpoints that have a annotation with the
    key `owner`, this is the same as `annotations:owner`
*   `annotations.protocol=gRPC` returns endpoints that have key/value
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
*   `annotations.owner!=sd AND annotations.foo=bar` returns endpoints that
    have `owner` in annotation key but value is not `sd` AND have
    key/value `foo=bar`
*   `doesnotexist.foo=bar` returns an empty list. Note that endpoint
    doesn't have a field called "doesnotexist". Since the filter does not
    match any endpoint, it returns no results

For more information about filtering, see
[API Filtering](https://aip.dev/160).

=back

=head2 Google::Cloud::Servicedirectory::V1::LookupService::ResolveServiceResponse

The response message for
[LookupService.ResolveService][google.cloud.servicedirectory.v1.LookupService.ResolveService].

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->service() >> / C<< $msg->service($value) >>

Type: C<Message> (L<Google::Cloud::Servicedirectory::V1::Service::Service>)

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Servicedirectory::V1::LookupService::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
