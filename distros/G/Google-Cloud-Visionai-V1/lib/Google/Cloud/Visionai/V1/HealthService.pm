package Google::Cloud::Visionai::V1::HealthService;

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
    eval { require Google::Api::Resource };
    my $descriptor_b64 = <<'EOF';
Ci1nb29nbGUvY2xvdWQvdmlzaW9uYWkvdjEvaGVhbHRoX3NlcnZpY2UucHJvdG8SGGdvb2ds
ZS5jbG91ZC52aXNpb25haS52MRocZ29vZ2xlL2FwaS9hbm5vdGF0aW9ucy5wcm90bxoXZ29v
Z2xlL2FwaS9jbGllbnQucHJvdG8aGWdvb2dsZS9hcGkvcmVzb3VyY2UucHJvdG8iVAoSSGVh
bHRoQ2hlY2tSZXF1ZXN0Ej4KB2NsdXN0ZXIYASABKAlCJPpBIQofdmlzaW9uYWkuZ29vZ2xl
YXBpcy5jb20vQ2x1c3RlclIHY2x1c3RlciKRAQoTSGVhbHRoQ2hlY2tSZXNwb25zZRIYCgdo
ZWFsdGh5GAEgASgIUgdoZWFsdGh5EhYKBnJlYXNvbhgCIAEoCVIGcmVhc29uEkgKDGNsdXN0
ZXJfaW5mbxgDIAEoCzIlLmdvb2dsZS5jbG91ZC52aXNpb25haS52MS5DbHVzdGVySW5mb1IL
Y2x1c3RlckluZm8iWwoLQ2x1c3RlckluZm8SIwoNc3RyZWFtc19jb3VudBgBIAEoBVIMc3Ry
ZWFtc0NvdW50EicKD3Byb2Nlc3Nlc19jb3VudBgCIAEoBVIOcHJvY2Vzc2VzQ291bnQykwIK
EkhlYWx0aENoZWNrU2VydmljZRKvAQoLSGVhbHRoQ2hlY2sSLC5nb29nbGUuY2xvdWQudmlz
aW9uYWkudjEuSGVhbHRoQ2hlY2tSZXF1ZXN0Gi0uZ29vZ2xlLmNsb3VkLnZpc2lvbmFpLnYx
LkhlYWx0aENoZWNrUmVzcG9uc2UiQ4LT5JMCPRI7L3YxL3tjbHVzdGVyPXByb2plY3RzLyov
bG9jYXRpb25zLyovY2x1c3RlcnMvKn06aGVhbHRoQ2hlY2saS8pBF3Zpc2lvbmFpLmdvb2ds
ZWFwaXMuY29t0kEuaHR0cHM6Ly93d3cuZ29vZ2xlYXBpcy5jb20vYXV0aC9jbG91ZC1wbGF0
Zm9ybULHAQocY29tLmdvb2dsZS5jbG91ZC52aXNpb25haS52MUIXSGVhbHRoQ2hlY2tTZXJ2
aWNlUHJvdG9QAVo4Y2xvdWQuZ29vZ2xlLmNvbS9nby92aXNpb25haS9hcGl2MS92aXNpb25h
aXBiO3Zpc2lvbmFpcGKqAhhHb29nbGUuQ2xvdWQuVmlzaW9uQUkuVjHKAhhHb29nbGVcQ2xv
dWRcVmlzaW9uQUlcVjHqAhtHb29nbGU6OkNsb3VkOjpWaXNpb25BSTo6VjFKmQ8KBhIEDgBH
AQq8BAoBDBIDDgASMrEEIENvcHlyaWdodCAyMDI1IEdvb2dsZSBMTEMKCiBMaWNlbnNlZCB1
bmRlciB0aGUgQXBhY2hlIExpY2Vuc2UsIFZlcnNpb24gMi4wICh0aGUgIkxpY2Vuc2UiKTsK
IHlvdSBtYXkgbm90IHVzZSB0aGlzIGZpbGUgZXhjZXB0IGluIGNvbXBsaWFuY2Ugd2l0aCB0
aGUgTGljZW5zZS4KIFlvdSBtYXkgb2J0YWluIGEgY29weSBvZiB0aGUgTGljZW5zZSBhdAoK
ICAgICBodHRwOi8vd3d3LmFwYWNoZS5vcmcvbGljZW5zZXMvTElDRU5TRS0yLjAKCiBVbmxl
c3MgcmVxdWlyZWQgYnkgYXBwbGljYWJsZSBsYXcgb3IgYWdyZWVkIHRvIGluIHdyaXRpbmcs
IHNvZnR3YXJlCiBkaXN0cmlidXRlZCB1bmRlciB0aGUgTGljZW5zZSBpcyBkaXN0cmlidXRl
ZCBvbiBhbiAiQVMgSVMiIEJBU0lTLAogV0lUSE9VVCBXQVJSQU5USUVTIE9SIENPTkRJVElP
TlMgT0YgQU5ZIEtJTkQsIGVpdGhlciBleHByZXNzIG9yIGltcGxpZWQuCiBTZWUgdGhlIExp
Y2Vuc2UgZm9yIHRoZSBzcGVjaWZpYyBsYW5ndWFnZSBnb3Zlcm5pbmcgcGVybWlzc2lvbnMg
YW5kCiBsaW1pdGF0aW9ucyB1bmRlciB0aGUgTGljZW5zZS4KCggKAQISAxAAIQoJCgIDABID
EgAmCgkKAgMBEgMTACEKCQoCAwISAxQAIwoICgEIEgMWADUKCQoCCCUSAxYANQoICgEIEgMX
AE8KCQoCCAsSAxcATwoICgEIEgMYACIKCQoCCAoSAxgAIgoICgEIEgMZADgKCQoCCAgSAxkA
OAoICgEIEgMaADUKCQoCCAESAxoANQoICgEIEgMbADUKCQoCCCkSAxsANQoICgEIEgMcADQK
CQoCCC0SAxwANApiCgIGABIEIAArARpWIEhlYWx0aENoZWNrU2VydmljZSBwcm92aWRlcyBh
biBpbnRlcmZhY2UgZm9yIFZlcnRleCBBSSBWaXNpb24gQ2x1c3RlciBIZWFsdGgKIENoZWNr
LgoKCgoDBgABEgMgCBoKCgoDBgADEgMhAj8KDAoFBgADmQgSAyECPwoLCgMGAAMSBCICIzcK
DQoFBgADmggSBCICIzcKSwoEBgACABIEJgIqAxo9IEhlYWx0aENoZWNrIG1ldGhvZCBjaGVj
a3MgdGhlIGhlYWx0aCBzdGF0dXMgb2YgdGhlIGNsdXN0ZXIuCgoMCgUGAAIAARIDJgYRCgwK
BQYAAgACEgMmEiQKDAoFBgACAAMSAyYvQgoNCgUGAAIABBIEJwQpBgoRCgkGAAIABLDKvCIS
BCcEKQYKQgoCBAASBC4AMwEaNiBIZWFsdGhDaGVja1JlcXVlc3QgaXMgdGhlIHJlcXVlc3Qg
bWVzc2FnZSBmb3IgQ2hlY2suCgoKCgMEAAESAy4IGgorCgQEAAIAEgQwAjIFGh0gVGhlIHBh
cmVudCBvZiB0aGUgcmVzb3VyY2UuCgoMCgUEAAIABRIDMAIICgwKBQQAAgABEgMwCRAKDAoF
BAACAAMSAzATFAoNCgUEAAIACBIEMBUyBAoPCgcEAAIACJ8IEgQwFjIDCkQKAgQBEgQ2AD8B
GjggSGVhbHRoQ2hlY2tSZXNwb25zZSBpcyB0aGUgcmVzcG9uc2UgbWVzc2FnZSBmb3IgQ2hl
Y2suCgoKCgMEAQESAzYIGwpICgQEAQIAEgM4AhMaOyBJbmRpY2F0ZXMgd2hldGhlciB0aGUg
Y2x1c3RlciBpcyBpbiBoZWFsdGh5IHN0YXRlIG9yIG5vdC4KCgwKBQQBAgAFEgM4AgYKDAoF
BAECAAESAzgHDgoMCgUEAQIAAxIDOBESCj8KBAQBAgESAzsCFBoyIFJlYXNvbiBvZiB3aHkg
dGhlIGNsdXN0ZXIgaXMgaW4gdW5oZWFsdGh5IHN0YXRlLgoKDAoFBAECAQUSAzsCCAoMCgUE
AQIBARIDOwkPCgwKBQQBAgEDEgM7EhMKSQoEBAECAhIDPgIfGjwgT3RoZXIgaW5mb3JtYXRp
b24gb2YgdGhlIGNsdXN0ZXIgY2xpZW50IG1heSBiZSBpbnRlcmVzdGVkLgoKDAoFBAECAgYS
Az4CDQoMCgUEAQICARIDPg4aCgwKBQQBAgIDEgM+HR4KCgoCBAISBEEARwEKCgoDBAIBEgNB
CBMKOwoEBAICABIDQwIaGi4gVGhlIG51bWJlciBvZiBhY3RpdmUgc3RyZWFtcyBpbiB0aGUg
Y2x1c3Rlci4KCgwKBQQCAgAFEgNDAgcKDAoFBAICAAESA0MIFQoMCgUEAgIAAxIDQxgZCj0K
BAQCAgESA0YCHBowIFRoZSBudW1iZXIgb2YgYWN0aXZlIHByb2Nlc3NlcyBpbiB0aGUgY2x1
c3Rlci4KCgwKBQQCAgEFEgNGAgcKDAoFBAICAQESA0YIFwoMCgUEAgIBAxIDRhobYgZwcm90
bzM=
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Visionai::V1::HealthService::HealthCheckRequest ===
    # Fields for HealthCheckRequest
    # Field: cluster Type: 9 ()

# === Message: Google::Cloud::Visionai::V1::HealthService::HealthCheckResponse ===
    # Fields for HealthCheckResponse
    # Field: healthy Type: 8 ()
    # Field: reason Type: 9 ()
    # Field: cluster_info Type: 11 (.google.cloud.visionai.v1.ClusterInfo)

# === Message: Google::Cloud::Visionai::V1::HealthService::ClusterInfo ===
    # Fields for ClusterInfo
    # Field: streams_count Type: 5 ()
    # Field: processes_count Type: 5 ()

# === Service Client: Google::Cloud::Visionai::V1::HealthService::HealthCheckServiceClient ===
package Google::Cloud::Visionai::V1::HealthService::HealthCheckServiceClient;

=pod

=head2 Service Client: Google::Cloud::Visionai::V1::HealthService::HealthCheckServiceClient

Client stub representing the remote C<HealthCheckService> gRPC service. Delegates call dispatching to L<Google::gRPC::Client>.

=head3 target

The endpoint target address. Defaults to C<visionai.googleapis.com:443>.

=head3 credentials

The authentication credentials provider. Defaults to application default credentials via L<Google::Auth>.

=cut

use Moo;
use Google::Auth;
use Google::gRPC::Client;

has credentials => ( is => 'ro', default => sub { Google::Auth->default() } );
has target      => ( is => 'ro', default => 'visionai.googleapis.com:443' );

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

sub health_check {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Visionai::V1::HealthService::HealthCheckRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.visionai.v1.HealthCheckService',
        method         => 'HealthCheck',
        request        => $req,
        response_class => 'Google::Cloud::Visionai::V1::HealthService::HealthCheckResponse',
    });
}

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Visionai::V1::HealthService - Compiled Protocol Buffers messages for google/cloud/visionai/v1/health_service.proto

=head1 SYNOPSIS

    use Google::Cloud::Visionai::V1::HealthService;

    my $msg = Google::Cloud::Visionai::V1::HealthService::HealthCheckRequest->new({
        cluster => $cluster,
    });

    # Read or update a field
    my $val = $msg->cluster();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Visionai::V1::HealthService::HealthCheckRequest->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/visionai/v1/health_service.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Visionai::V1::HealthService::HealthCheckRequest

HealthCheckRequest is the request message for Check.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->cluster() >> / C<< $msg->cluster($value) >>

Type: C<String>

The parent of the resource.

=back

=head2 Google::Cloud::Visionai::V1::HealthService::HealthCheckResponse

HealthCheckResponse is the response message for Check.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->healthy() >> / C<< $msg->healthy($value) >>

Type: C<Bool>

Indicates whether the cluster is in healthy state or not.

=item * C<< $msg->reason() >> / C<< $msg->reason($value) >>

Type: C<String>

Reason of why the cluster is in unhealthy state.

=item * C<< $msg->cluster_info() >> / C<< $msg->cluster_info($value) >>

Type: C<Message> (L<Google::Cloud::Visionai::V1::HealthService::ClusterInfo>)

Other information of the cluster client may be interested.

=back

=head2 Google::Cloud::Visionai::V1::HealthService::ClusterInfo

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->streams_count() >> / C<< $msg->streams_count($value) >>

Type: C<Int32>

The number of active streams in the cluster.

=item * C<< $msg->processes_count() >> / C<< $msg->processes_count($value) >>

Type: C<Int32>

The number of active processes in the cluster.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Visionai::V1::HealthService::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
