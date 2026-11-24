package Google::Monitoring::V3::QueryService;

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
    eval { require Google::Monitoring::V3::MetricService };
    my $descriptor_b64 = <<'EOF';
Cihnb29nbGUvbW9uaXRvcmluZy92My9xdWVyeV9zZXJ2aWNlLnByb3RvEhRnb29nbGUubW9u
aXRvcmluZy52MxocZ29vZ2xlL2FwaS9hbm5vdGF0aW9ucy5wcm90bxoXZ29vZ2xlL2FwaS9j
bGllbnQucHJvdG8aKWdvb2dsZS9tb25pdG9yaW5nL3YzL21ldHJpY19zZXJ2aWNlLnByb3Rv
MuECCgxRdWVyeVNlcnZpY2USpAEKD1F1ZXJ5VGltZVNlcmllcxIsLmdvb2dsZS5tb25pdG9y
aW5nLnYzLlF1ZXJ5VGltZVNlcmllc1JlcXVlc3QaLS5nb29nbGUubW9uaXRvcmluZy52My5R
dWVyeVRpbWVTZXJpZXNSZXNwb25zZSI0iAIBgtPkkwIrIiYvdjMve25hbWU9cHJvamVjdHMv
Kn0vdGltZVNlcmllczpxdWVyeToBKhqpAcpBGW1vbml0b3JpbmcuZ29vZ2xlYXBpcy5jb23S
QYkBaHR0cHM6Ly93d3cuZ29vZ2xlYXBpcy5jb20vYXV0aC9jbG91ZC1wbGF0Zm9ybSxodHRw
czovL3d3dy5nb29nbGVhcGlzLmNvbS9hdXRoL21vbml0b3JpbmcsaHR0cHM6Ly93d3cuZ29v
Z2xlYXBpcy5jb20vYXV0aC9tb25pdG9yaW5nLnJlYWRCzAEKGGNvbS5nb29nbGUubW9uaXRv
cmluZy52M0IRUXVlcnlTZXJ2aWNlUHJvdG9QAVpBY2xvdWQuZ29vZ2xlLmNvbS9nby9tb25p
dG9yaW5nL2FwaXYzL3YyL21vbml0b3JpbmdwYjttb25pdG9yaW5ncGKqAhpHb29nbGUuQ2xv
dWQuTW9uaXRvcmluZy5WM8oCGkdvb2dsZVxDbG91ZFxNb25pdG9yaW5nXFYz6gIdR29vZ2xl
OjpDbG91ZDo6TW9uaXRvcmluZzo6VjNK/goKBhIEDgA0AQq8BAoBDBIDDgASMrEEIENvcHly
aWdodCAyMDI1IEdvb2dsZSBMTEMKCiBMaWNlbnNlZCB1bmRlciB0aGUgQXBhY2hlIExpY2Vu
c2UsIFZlcnNpb24gMi4wICh0aGUgIkxpY2Vuc2UiKTsKIHlvdSBtYXkgbm90IHVzZSB0aGlz
IGZpbGUgZXhjZXB0IGluIGNvbXBsaWFuY2Ugd2l0aCB0aGUgTGljZW5zZS4KIFlvdSBtYXkg
b2J0YWluIGEgY29weSBvZiB0aGUgTGljZW5zZSBhdAoKICAgICBodHRwOi8vd3d3LmFwYWNo
ZS5vcmcvbGljZW5zZXMvTElDRU5TRS0yLjAKCiBVbmxlc3MgcmVxdWlyZWQgYnkgYXBwbGlj
YWJsZSBsYXcgb3IgYWdyZWVkIHRvIGluIHdyaXRpbmcsIHNvZnR3YXJlCiBkaXN0cmlidXRl
ZCB1bmRlciB0aGUgTGljZW5zZSBpcyBkaXN0cmlidXRlZCBvbiBhbiAiQVMgSVMiIEJBU0lT
LAogV0lUSE9VVCBXQVJSQU5USUVTIE9SIENPTkRJVElPTlMgT0YgQU5ZIEtJTkQsIGVpdGhl
ciBleHByZXNzIG9yIGltcGxpZWQuCiBTZWUgdGhlIExpY2Vuc2UgZm9yIHRoZSBzcGVjaWZp
YyBsYW5ndWFnZSBnb3Zlcm5pbmcgcGVybWlzc2lvbnMgYW5kCiBsaW1pdGF0aW9ucyB1bmRl
ciB0aGUgTGljZW5zZS4KCggKAQISAxAAHQoJCgIDABIDEgAmCgkKAgMBEgMTACEKCQoCAwIS
AxQAMwoICgEIEgMWADcKCQoCCCUSAxYANwoICgEIEgMXAFgKCQoCCAsSAxcAWAoICgEIEgMY
ACIKCQoCCAoSAxgAIgoICgEIEgMZADIKCQoCCAgSAxkAMgoICgEIEgMaADEKCQoCCAESAxoA
MQoICgEIEgMbADcKCQoCCCkSAxsANwoICgEIEgMcADYKCQoCCC0SAxwANgrBAQoCBgASBCEA
NAEatAEgVGhlIFF1ZXJ5U2VydmljZSBBUEkgaXMgdXNlZCB0byBtYW5hZ2UgdGltZSBzZXJp
ZXMgZGF0YSBpbiBDbG91ZAogTW9uaXRvcmluZy4gVGltZSBzZXJpZXMgZGF0YSBpcyBhIGNv
bGxlY3Rpb24gb2YgZGF0YSBwb2ludHMgdGhhdCBkZXNjcmliZXMKIHRoZSB0aW1lLXZhcnlp
bmcgdmFsdWVzIG9mIGEgbWV0cmljLgoKCgoDBgABEgMhCBQKCgoDBgADEgMiAkEKDAoFBgAD
mQgSAyICQQoLCgMGAAMSBCMCJjgKDQoFBgADmggSBCMCJjgKhwIKBAYAAgASBCwCMwMa+AEg
UXVlcmllcyB0aW1lIHNlcmllcyBieSB1c2luZyBNb25pdG9yaW5nIFF1ZXJ5IExhbmd1YWdl
IChNUUwpLiBXZSByZWNvbW1lbmQKIHVzaW5nIFByb21RTCBpbnN0ZWFkIG9mIE1RTC4gRm9y
IG1vcmUgaW5mb3JtYXRpb24gYWJvdXQgdGhlIHN0YXR1cyBvZiBNUUwsCiBzZWUgdGhlIFtN
UUwgZGVwcmVjYXRpb24KIG5vdGljZV0oaHR0cHM6Ly9jbG91ZC5nb29nbGUuY29tL3N0YWNr
ZHJpdmVyL2RvY3MvZGVwcmVjYXRpb25zL21xbCkuCgoMCgUGAAIAARIDLAYVCgwKBQYAAgAC
EgMsFiwKDAoFBgACAAMSAy0PJgoMCgUGAAIABBIDLgQdCg0KBgYAAgAEIRIDLgQdCg0KBQYA
AgAEEgQvBDIGChEKCQYAAgAEsMq8IhIELwQyBmIGcHJvdG8z
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Service Client: Google::Monitoring::V3::QueryService::QueryServiceClient ===
package Google::Monitoring::V3::QueryService::QueryServiceClient;

=pod

=head2 Service Client: Google::Monitoring::V3::QueryService::QueryServiceClient

Client stub representing the remote C<QueryService> gRPC service. Delegates call dispatching to L<Google::gRPC::Client>.

=head3 target

The endpoint target address. Defaults to C<monitoring.googleapis.com:443>.

=head3 credentials

The authentication credentials provider. Defaults to application default credentials via L<Google::Auth>.

=cut

use Moo;
use Google::Auth;
use Google::gRPC::Client;

has credentials => ( is => 'ro', default => sub { Google::Auth->default() } );
has target      => ( is => 'ro', default => 'monitoring.googleapis.com:443' );

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

sub query_time_series {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Monitoring::V3::MetricService::QueryTimeSeriesRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.monitoring.v3.QueryService',
        method         => 'QueryTimeSeries',
        request        => $req,
        response_class => 'Google::Monitoring::V3::MetricService::QueryTimeSeriesResponse',
    });
}

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Monitoring::V3::QueryService - Compiled Protocol Buffers messages for google/monitoring/v3/query_service.proto

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/monitoring/v3/query_service.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Monitoring::V3::QueryService::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
