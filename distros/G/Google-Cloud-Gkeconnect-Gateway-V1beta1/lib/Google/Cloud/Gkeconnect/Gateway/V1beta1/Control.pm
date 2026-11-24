package Google::Cloud::Gkeconnect::Gateway::V1beta1::Control;

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
    my $descriptor_b64 = <<'EOF';
CjVnb29nbGUvY2xvdWQvZ2tlY29ubmVjdC9nYXRld2F5L3YxYmV0YTEvY29udHJvbC5wcm90
bxInZ29vZ2xlLmNsb3VkLmdrZWNvbm5lY3QuZ2F0ZXdheS52MWJldGExGhxnb29nbGUvYXBp
L2Fubm90YXRpb25zLnByb3RvGhdnb29nbGUvYXBpL2NsaWVudC5wcm90bxofZ29vZ2xlL2Fw
aS9maWVsZF9iZWhhdmlvci5wcm90byKSAwoaR2VuZXJhdGVDcmVkZW50aWFsc1JlcXVlc3QS
FwoEbmFtZRgBIAEoCUID4EECUgRuYW1lEisKD2ZvcmNlX3VzZV9hZ2VudBgCIAEoCEID4EEB
Ug1mb3JjZVVzZUFnZW50Eh0KB3ZlcnNpb24YAyABKAlCA+BBAVIHdmVyc2lvbhI2ChRrdWJl
cm5ldGVzX25hbWVzcGFjZRgEIAEoCUID4EEBUhNrdWJlcm5ldGVzTmFtZXNwYWNlEoMBChBv
cGVyYXRpbmdfc3lzdGVtGAUgASgOMlMuZ29vZ2xlLmNsb3VkLmdrZWNvbm5lY3QuZ2F0ZXdh
eS52MWJldGExLkdlbmVyYXRlQ3JlZGVudGlhbHNSZXF1ZXN0Lk9wZXJhdGluZ1N5c3RlbUID
4EEBUg9vcGVyYXRpbmdTeXN0ZW0iUQoPT3BlcmF0aW5nU3lzdGVtEiAKHE9QRVJBVElOR19T
WVNURU1fVU5TUEVDSUZJRUQQABIcChhPUEVSQVRJTkdfU1lTVEVNX1dJTkRPV1MQASJZChtH
ZW5lcmF0ZUNyZWRlbnRpYWxzUmVzcG9uc2USHgoKa3ViZWNvbmZpZxgBIAEoDFIKa3ViZWNv
bmZpZxIaCghlbmRwb2ludBgCIAEoCVIIZW5kcG9pbnQy2AIKDkdhdGV3YXlDb250cm9sEvIB
ChNHZW5lcmF0ZUNyZWRlbnRpYWxzEkMuZ29vZ2xlLmNsb3VkLmdrZWNvbm5lY3QuZ2F0ZXdh
eS52MWJldGExLkdlbmVyYXRlQ3JlZGVudGlhbHNSZXF1ZXN0GkQuZ29vZ2xlLmNsb3VkLmdr
ZWNvbm5lY3QuZ2F0ZXdheS52MWJldGExLkdlbmVyYXRlQ3JlZGVudGlhbHNSZXNwb25zZSJQ
gtPkkwJKEkgvdjFiZXRhMS97bmFtZT1wcm9qZWN0cy8qL2xvY2F0aW9ucy8qL21lbWJlcnNo
aXBzLyp9OmdlbmVyYXRlQ3JlZGVudGlhbHMaUcpBHWNvbm5lY3RnYXRld2F5Lmdvb2dsZWFw
aXMuY29t0kEuaHR0cHM6Ly93d3cuZ29vZ2xlYXBpcy5jb20vYXV0aC9jbG91ZC1wbGF0Zm9y
bUKGAgorY29tLmdvb2dsZS5jbG91ZC5na2Vjb25uZWN0LmdhdGV3YXkudjFiZXRhMUIMQ29u
dHJvbFByb3RvUAFaRWNsb3VkLmdvb2dsZS5jb20vZ28vZ2tlY29ubmVjdC9nYXRld2F5L2Fw
aXYxYmV0YTEvZ2F0ZXdheXBiO2dhdGV3YXlwYqoCJ0dvb2dsZS5DbG91ZC5Ha2VDb25uZWN0
LkdhdGV3YXkuVjFCZXRhMcoCJ0dvb2dsZVxDbG91ZFxHa2VDb25uZWN0XEdhdGV3YXlcVjFi
ZXRhMeoCK0dvb2dsZTo6Q2xvdWQ6OkdrZUNvbm5lY3Q6OkdhdGV3YXk6OlYxYmV0YTFK5hgK
BhIEDgBeAQq8BAoBDBIDDgASMrEEIENvcHlyaWdodCAyMDI1IEdvb2dsZSBMTEMKCiBMaWNl
bnNlZCB1bmRlciB0aGUgQXBhY2hlIExpY2Vuc2UsIFZlcnNpb24gMi4wICh0aGUgIkxpY2Vu
c2UiKTsKIHlvdSBtYXkgbm90IHVzZSB0aGlzIGZpbGUgZXhjZXB0IGluIGNvbXBsaWFuY2Ug
d2l0aCB0aGUgTGljZW5zZS4KIFlvdSBtYXkgb2J0YWluIGEgY29weSBvZiB0aGUgTGljZW5z
ZSBhdAoKICAgICBodHRwOi8vd3d3LmFwYWNoZS5vcmcvbGljZW5zZXMvTElDRU5TRS0yLjAK
CiBVbmxlc3MgcmVxdWlyZWQgYnkgYXBwbGljYWJsZSBsYXcgb3IgYWdyZWVkIHRvIGluIHdy
aXRpbmcsIHNvZnR3YXJlCiBkaXN0cmlidXRlZCB1bmRlciB0aGUgTGljZW5zZSBpcyBkaXN0
cmlidXRlZCBvbiBhbiAiQVMgSVMiIEJBU0lTLAogV0lUSE9VVCBXQVJSQU5USUVTIE9SIENP
TkRJVElPTlMgT0YgQU5ZIEtJTkQsIGVpdGhlciBleHByZXNzIG9yIGltcGxpZWQuCiBTZWUg
dGhlIExpY2Vuc2UgZm9yIHRoZSBzcGVjaWZpYyBsYW5ndWFnZSBnb3Zlcm5pbmcgcGVybWlz
c2lvbnMgYW5kCiBsaW1pdGF0aW9ucyB1bmRlciB0aGUgTGljZW5zZS4KCggKAQISAxAAMAoJ
CgIDABIDEgAmCgkKAgMBEgMTACEKCQoCAwISAxQAKQoICgEIEgMWAEQKCQoCCCUSAxYARAoI
CgEIEgMXAFwKCQoCCAsSAxcAXAoICgEIEgMYACIKCQoCCAoSAxgAIgoICgEIEgMZAC0KCQoC
CAgSAxkALQoICgEIEgMaAEQKCQoCCAESAxoARAoICgEIEgMbAEUKCQoCCCkSAxsARQoICgEI
EgMcAEQKCQoCCC0SAxwARApKCgIGABIEHwAsARo+IEdhdGV3YXlDb250cm9sIGlzIHRoZSBj
b250cm9sIHBsYW5lIEFQSSBmb3IgQ29ubmVjdCBHYXRld2F5LgoKCgoDBgABEgMfCBYKCgoD
BgADEgMgAkUKDAoFBgADmQgSAyACRQoLCgMGAAMSBCECIjcKDQoFBgADmggSBCECIjcKkgEK
BAYAAgASBCYCKwMagwEgR2VuZXJhdGVDcmVkZW50aWFscyBwcm92aWRlcyBjb25uZWN0aW9u
IGluZm9ybWF0aW9uIHRoYXQgYWxsb3dzIGEgdXNlciB0bwogYWNjZXNzIHRoZSBzcGVjaWZp
ZWQgbWVtYmVyc2hpcCB1c2luZyBDb25uZWN0IEdhdGV3YXkuCgoMCgUGAAIAARIDJgYZCgwK
BQYAAgACEgMmGjQKDAoFBgACAAMSAycPKgoNCgUGAAIABBIEKAQqBgoRCgkGAAIABLDKvCIS
BCgEKgYKTwoCBAASBC8AVAEaQyBBIHJlcXVlc3QgZm9yIGNvbm5lY3Rpb24gaW5mb3JtYXRp
b24gZm9yIGEgcGFydGljdWxhciBtZW1iZXJzaGlwLgoKCgoDBAABEgMvCCIKRAoEBAAEABIE
MQI5Axo2IE9wZXJhdGluZyBzeXN0ZW1zIHJlcXVpcmluZyBzcGVjaWFsaXplZCBrdWJlY29u
Zmlncy4KCgwKBQQABAABEgMxBxYKYAoGBAAEAAIAEgM0BCUaUSBHZW5lcmF0ZXMgYSBrdWJl
Y29uZmlnIHRoYXQgd29ya3MgZm9yIGFsbCBvcGVyYXRpbmcgc3lzdGVtcyBub3QgZGVmaW5l
ZAogYmVsb3cuCgoOCgcEAAQAAgABEgM0BCAKDgoHBAAEAAIAAhIDNCMkClwKBgQABAACARID
OAQhGk0gR2VuZXJhdGVzIGEga3ViZWNvbmZpZyB0aGF0IGlzIHNwZWNpZmljYWxseSBkZXNp
Z25lZCB0byB3b3JrIHdpdGgKIFdpbmRvd3MuCgoOCgcEAAQAAgEBEgM4BBwKDgoHBAAEAAIB
AhIDOB8gCjcKBAQAAgASAzwCOxoqIFJlcXVpcmVkLiBUaGUgRmxlZXQgbWVtYmVyc2hpcCBy
ZXNvdXJjZS4KCgwKBQQAAgAFEgM8AggKDAoFBAACAAESAzwJDQoMCgUEAAIAAxIDPBARCgwK
BQQAAgAIEgM8EjoKDwoIBAACAAicCAASAzwTOQr2AgoEBAACARIDRAJEGugCIE9wdGlvbmFs
LiBXaGV0aGVyIHRvIGZvcmNlIHRoZSB1c2Ugb2YgQ29ubmVjdCBBZ2VudC1iYXNlZCB0cmFu
c3BvcnQuCgogVGhpcyB3aWxsIHJldHVybiBhIGNvbmZpZ3VyYXRpb24gdGhhdCB1c2VzIENv
bm5lY3QgQWdlbnQgYXMgdGhlIHVuZGVybHlpbmcKIHRyYW5zcG9ydCBtZWNoYW5pc20gZm9y
IGNsdXN0ZXIgdHlwZXMgdGhhdCB3b3VsZCBvdGhlcndpc2UgaGF2ZSB1c2VkIGEKIGRpZmZl
cmVudCB0cmFuc3BvcnQuIFJlcXVpcmVzIHRoYXQgQ29ubmVjdCBBZ2VudCBiZSBpbnN0YWxs
ZWQgb24gdGhlCiBjbHVzdGVyLiBTZXR0aW5nIHRoaXMgZmllbGQgdG8gZmFsc2UgaXMgZXF1
aXZhbGVudCB0byBub3Qgc2V0dGluZyBpdC4KCgwKBQQAAgEFEgNEAgYKDAoFBAACAQESA0QH
FgoMCgUEAAIBAxIDRBkaCgwKBQQAAgEIEgNEG0MKDwoIBAACAQicCAASA0QcQgquAQoEBAAC
AhIDSgI+GqABIE9wdGlvbmFsLiBUaGUgQ29ubmVjdCBHYXRld2F5IHZlcnNpb24gdG8gYmUg
dXNlZCBpbiB0aGUgcmVzdWx0aW5nCiBjb25maWd1cmF0aW9uLgoKIExlYXZlIHRoaXMgZmll
bGQgYmxhbmsgdG8gbGV0IHRoZSBzZXJ2ZXIgY2hvb3NlIHRoZSB2ZXJzaW9uIChyZWNvbW1l
bmRlZCkuCgoMCgUEAAICBRIDSgIICgwKBQQAAgIBEgNKCRAKDAoFBAACAgMSA0oTFAoMCgUE
AAICCBIDShU9Cg8KCAQAAgIInAgAEgNKFjwK3QEKBAQAAgMSA1ACSxrPASBPcHRpb25hbC4g
VGhlIG5hbWVzcGFjZSB0byB1c2UgaW4gdGhlIGt1YmVjb25maWcgY29udGV4dC4KCiBJZiB0
aGlzIGZpZWxkIGlzIHNwZWNpZmllZCwgdGhlIHNlcnZlciB3aWxsIHNldCB0aGUgYG5hbWVz
cGFjZWAgZmllbGQgaW4KIGt1YmVjb25maWcgY29udGV4dC4gSWYgbm90IHNwZWNpZmllZCwg
dGhlIGBuYW1lc3BhY2VgIGZpZWxkIGlzIG9taXR0ZWQuCgoMCgUEAAIDBRIDUAIICgwKBQQA
AgMBEgNQCR0KDAoFBAACAwMSA1AgIQoMCgUEAAIDCBIDUCJKCg8KCAQAAgMInAgAEgNQI0kK
UAoEBAACBBIDUwJQGkMgT3B0aW9uYWwuIFRoZSBvcGVyYXRpbmcgc3lzdGVtIHdoZXJlIHRo
ZSBrdWJlY29uZmlnIHdpbGwgYmUgdXNlZC4KCgwKBQQAAgQGEgNTAhEKDAoFBAACBAESA1MS
IgoMCgUEAAIEAxIDUyUmCgwKBQQAAgQIEgNTJ08KDwoIBAACBAicCAASA1MoTgpBCgIEARIE
VwBeARo1IENvbm5lY3Rpb24gaW5mb3JtYXRpb24gZm9yIGEgcGFydGljdWxhciBtZW1iZXJz
aGlwLgoKCgoDBAEBEgNXCCMKOwoEBAECABIDWQIXGi4gQSBmdWxsIFlBTUwga3ViZWNvbmZp
ZyBpbiBzZXJpYWxpemVkIGZvcm1hdC4KCgwKBQQBAgAFEgNZAgcKDAoFBAECAAESA1kIEgoM
CgUEAQIAAxIDWRUWCl0KBAQBAgESA10CFhpQIFRoZSBnZW5lcmF0ZWQgVVJJIG9mIHRoZSBj
bHVzdGVyIGFzIGFjY2Vzc2VkIHRocm91Z2ggdGhlIENvbm5lY3QgR2F0ZXdheQogQVBJLgoK
DAoFBAECAQUSA10CCAoMCgUEAQIBARIDXQkRCgwKBQQBAgEDEgNdFBViBnByb3RvMw==
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Gkeconnect::Gateway::V1beta1::Control::GenerateCredentialsRequest ===
    # Fields for GenerateCredentialsRequest
    # Field: name Type: 9 ()
    # Field: force_use_agent Type: 8 ()
    # Field: version Type: 9 ()
    # Field: kubernetes_namespace Type: 9 ()
    # Field: operating_system Type: 14 (.google.cloud.gkeconnect.gateway.v1beta1.GenerateCredentialsRequest.OperatingSystem)

# Enum: GenerateCredentialsRequest::OperatingSystem
our $GenerateCredentialsRequest_OPERATING_SYSTEM_UNSPECIFIED = 0;
our $GenerateCredentialsRequest_OPERATING_SYSTEM_WINDOWS = 1;

# === Message: Google::Cloud::Gkeconnect::Gateway::V1beta1::Control::GenerateCredentialsResponse ===
    # Fields for GenerateCredentialsResponse
    # Field: kubeconfig Type: 12 ()
    # Field: endpoint Type: 9 ()

# === Service Client: Google::Cloud::Gkeconnect::Gateway::V1beta1::Control::GatewayControlClient ===
package Google::Cloud::Gkeconnect::Gateway::V1beta1::Control::GatewayControlClient;

=pod

=head2 Service Client: Google::Cloud::Gkeconnect::Gateway::V1beta1::Control::GatewayControlClient

Client stub representing the remote C<GatewayControl> gRPC service. Delegates call dispatching to L<Google::gRPC::Client>.

=head3 target

The endpoint target address. Defaults to C<gkeconnect.googleapis.com:443>.

=head3 credentials

The authentication credentials provider. Defaults to application default credentials via L<Google::Auth>.

=cut

use Moo;
use Google::Auth;
use Google::gRPC::Client;

has credentials => ( is => 'ro', default => sub { Google::Auth->default() } );
has target      => ( is => 'ro', default => 'gkeconnect.googleapis.com:443' );

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

sub generate_credentials {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Gkeconnect::Gateway::V1beta1::Control::GenerateCredentialsRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.gkeconnect.gateway.v1beta1.GatewayControl',
        method         => 'GenerateCredentials',
        request        => $req,
        response_class => 'Google::Cloud::Gkeconnect::Gateway::V1beta1::Control::GenerateCredentialsResponse',
    });
}

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Gkeconnect::Gateway::V1beta1::Control - Compiled Protocol Buffers messages for google/cloud/gkeconnect/gateway/v1beta1/control.proto

=head1 SYNOPSIS

    use Google::Cloud::Gkeconnect::Gateway::V1beta1::Control;

    my $msg = Google::Cloud::Gkeconnect::Gateway::V1beta1::Control::GenerateCredentialsRequest->new({
        name => $name,
        force_use_agent => $force_use_agent,
        version => $version,
        kubernetes_namespace => $kubernetes_namespace,
    });

    # Read or update a field
    my $val = $msg->name();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Gkeconnect::Gateway::V1beta1::Control::GenerateCredentialsRequest->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/gkeconnect/gateway/v1beta1/control.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Gkeconnect::Gateway::V1beta1::Control::GenerateCredentialsRequest

A request for connection information for a particular membership.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. The Fleet membership resource.

=item * C<< $msg->force_use_agent() >> / C<< $msg->force_use_agent($value) >>

Type: C<Bool>

Optional. Whether to force the use of Connect Agent-based transport.

This will return a configuration that uses Connect Agent as the underlying
transport mechanism for cluster types that would otherwise have used a
different transport. Requires that Connect Agent be installed on the
cluster. Setting this field to false is equivalent to not setting it.

=item * C<< $msg->version() >> / C<< $msg->version($value) >>

Type: C<String>

Optional. The Connect Gateway version to be used in the resulting
configuration.

Leave this field blank to let the server choose the version (recommended).

=item * C<< $msg->kubernetes_namespace() >> / C<< $msg->kubernetes_namespace($value) >>

Type: C<String>

Optional. The namespace to use in the kubeconfig context.

If this field is specified, the server will set the `namespace` field in
kubeconfig context. If not specified, the `namespace` field is omitted.

=item * C<< $msg->operating_system() >> / C<< $msg->operating_system($value) >>

Type: C<Enum> (L<Google::Cloud::Gkeconnect::Gateway::V1beta1::GenerateCredentialsRequest::OperatingSystem>)

Optional. The operating system where the kubeconfig will be used.

=back

=head3 Enum: GenerateCredentialsRequest::OperatingSystem

=over 4

=item * C<OPERATING_SYSTEM_UNSPECIFIED> => C<0>

=item * C<OPERATING_SYSTEM_WINDOWS> => C<1>

=back

=head2 Google::Cloud::Gkeconnect::Gateway::V1beta1::Control::GenerateCredentialsResponse

Connection information for a particular membership.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->kubeconfig() >> / C<< $msg->kubeconfig($value) >>

Type: C<Bytes>

A full YAML kubeconfig in serialized format.

=item * C<< $msg->endpoint() >> / C<< $msg->endpoint($value) >>

Type: C<String>

The generated URI of the cluster as accessed through the Connect Gateway
API.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Gkeconnect::Gateway::V1beta1::Control::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
