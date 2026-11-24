package Google::Cloud::Gkeconnect::Gateway::V1::Control;

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
CjBnb29nbGUvY2xvdWQvZ2tlY29ubmVjdC9nYXRld2F5L3YxL2NvbnRyb2wucHJvdG8SImdv
b2dsZS5jbG91ZC5na2Vjb25uZWN0LmdhdGV3YXkudjEaHGdvb2dsZS9hcGkvYW5ub3RhdGlv
bnMucHJvdG8aF2dvb2dsZS9hcGkvY2xpZW50LnByb3RvGh9nb29nbGUvYXBpL2ZpZWxkX2Jl
aGF2aW9yLnByb3RvIowDChpHZW5lcmF0ZUNyZWRlbnRpYWxzUmVxdWVzdBIXCgRuYW1lGAEg
ASgJQgPgQQJSBG5hbWUSKwoPZm9yY2VfdXNlX2FnZW50GAIgASgIQgPgQQFSDWZvcmNlVXNl
QWdlbnQSHQoHdmVyc2lvbhgDIAEoCUID4EEBUgd2ZXJzaW9uEjYKFGt1YmVybmV0ZXNfbmFt
ZXNwYWNlGAQgASgJQgPgQQFSE2t1YmVybmV0ZXNOYW1lc3BhY2USfgoQb3BlcmF0aW5nX3N5
c3RlbRgFIAEoDjJOLmdvb2dsZS5jbG91ZC5na2Vjb25uZWN0LmdhdGV3YXkudjEuR2VuZXJh
dGVDcmVkZW50aWFsc1JlcXVlc3QuT3BlcmF0aW5nU3lzdGVtQgPgQQFSD29wZXJhdGluZ1N5
c3RlbSJRCg9PcGVyYXRpbmdTeXN0ZW0SIAocT1BFUkFUSU5HX1NZU1RFTV9VTlNQRUNJRklF
RBAAEhwKGE9QRVJBVElOR19TWVNURU1fV0lORE9XUxABIlkKG0dlbmVyYXRlQ3JlZGVudGlh
bHNSZXNwb25zZRIeCgprdWJlY29uZmlnGAEgASgMUgprdWJlY29uZmlnEhoKCGVuZHBvaW50
GAIgASgJUghlbmRwb2ludDLJAgoOR2F0ZXdheUNvbnRyb2wS4wEKE0dlbmVyYXRlQ3JlZGVu
dGlhbHMSPi5nb29nbGUuY2xvdWQuZ2tlY29ubmVjdC5nYXRld2F5LnYxLkdlbmVyYXRlQ3Jl
ZGVudGlhbHNSZXF1ZXN0Gj8uZ29vZ2xlLmNsb3VkLmdrZWNvbm5lY3QuZ2F0ZXdheS52MS5H
ZW5lcmF0ZUNyZWRlbnRpYWxzUmVzcG9uc2UiS4LT5JMCRRJDL3YxL3tuYW1lPXByb2plY3Rz
LyovbG9jYXRpb25zLyovbWVtYmVyc2hpcHMvKn06Z2VuZXJhdGVDcmVkZW50aWFscxpRykEd
Y29ubmVjdGdhdGV3YXkuZ29vZ2xlYXBpcy5jb23SQS5odHRwczovL3d3dy5nb29nbGVhcGlz
LmNvbS9hdXRoL2Nsb3VkLXBsYXRmb3JtQu0BCiZjb20uZ29vZ2xlLmNsb3VkLmdrZWNvbm5l
Y3QuZ2F0ZXdheS52MUIMQ29udHJvbFByb3RvUAFaQGNsb3VkLmdvb2dsZS5jb20vZ28vZ2tl
Y29ubmVjdC9nYXRld2F5L2FwaXYxL2dhdGV3YXlwYjtnYXRld2F5cGKqAiJHb29nbGUuQ2xv
dWQuR2tlQ29ubmVjdC5HYXRld2F5LlYxygIiR29vZ2xlXENsb3VkXEdrZUNvbm5lY3RcR2F0
ZXdheVxWMeoCJkdvb2dsZTo6Q2xvdWQ6OkdrZUNvbm5lY3Q6OkdhdGV3YXk6OlYxSuYYCgYS
BA4AXgEKvAQKAQwSAw4AEjKxBCBDb3B5cmlnaHQgMjAyNSBHb29nbGUgTExDCgogTGljZW5z
ZWQgdW5kZXIgdGhlIEFwYWNoZSBMaWNlbnNlLCBWZXJzaW9uIDIuMCAodGhlICJMaWNlbnNl
Iik7CiB5b3UgbWF5IG5vdCB1c2UgdGhpcyBmaWxlIGV4Y2VwdCBpbiBjb21wbGlhbmNlIHdp
dGggdGhlIExpY2Vuc2UuCiBZb3UgbWF5IG9idGFpbiBhIGNvcHkgb2YgdGhlIExpY2Vuc2Ug
YXQKCiAgICAgaHR0cDovL3d3dy5hcGFjaGUub3JnL2xpY2Vuc2VzL0xJQ0VOU0UtMi4wCgog
VW5sZXNzIHJlcXVpcmVkIGJ5IGFwcGxpY2FibGUgbGF3IG9yIGFncmVlZCB0byBpbiB3cml0
aW5nLCBzb2Z0d2FyZQogZGlzdHJpYnV0ZWQgdW5kZXIgdGhlIExpY2Vuc2UgaXMgZGlzdHJp
YnV0ZWQgb24gYW4gIkFTIElTIiBCQVNJUywKIFdJVEhPVVQgV0FSUkFOVElFUyBPUiBDT05E
SVRJT05TIE9GIEFOWSBLSU5ELCBlaXRoZXIgZXhwcmVzcyBvciBpbXBsaWVkLgogU2VlIHRo
ZSBMaWNlbnNlIGZvciB0aGUgc3BlY2lmaWMgbGFuZ3VhZ2UgZ292ZXJuaW5nIHBlcm1pc3Np
b25zIGFuZAogbGltaXRhdGlvbnMgdW5kZXIgdGhlIExpY2Vuc2UuCgoICgECEgMQACsKCQoC
AwASAxIAJgoJCgIDARIDEwAhCgkKAgMCEgMUACkKCAoBCBIDFgA/CgkKAgglEgMWAD8KCAoB
CBIDFwBXCgkKAggLEgMXAFcKCAoBCBIDGAAiCgkKAggKEgMYACIKCAoBCBIDGQAtCgkKAggI
EgMZAC0KCAoBCBIDGgA/CgkKAggBEgMaAD8KCAoBCBIDGwBACgkKAggpEgMbAEAKCAoBCBID
HAA/CgkKAggtEgMcAD8KSgoCBgASBB8ALAEaPiBHYXRld2F5Q29udHJvbCBpcyB0aGUgY29u
dHJvbCBwbGFuZSBBUEkgZm9yIENvbm5lY3QgR2F0ZXdheS4KCgoKAwYAARIDHwgWCgoKAwYA
AxIDIAJFCgwKBQYAA5kIEgMgAkUKCwoDBgADEgQhAiI3Cg0KBQYAA5oIEgQhAiI3CpIBCgQG
AAIAEgQmAisDGoMBIEdlbmVyYXRlQ3JlZGVudGlhbHMgcHJvdmlkZXMgY29ubmVjdGlvbiBp
bmZvcm1hdGlvbiB0aGF0IGFsbG93cyBhIHVzZXIgdG8KIGFjY2VzcyB0aGUgc3BlY2lmaWVk
IG1lbWJlcnNoaXAgdXNpbmcgQ29ubmVjdCBHYXRld2F5LgoKDAoFBgACAAESAyYGGQoMCgUG
AAIAAhIDJho0CgwKBQYAAgADEgMnDyoKDQoFBgACAAQSBCgEKgYKEQoJBgACAASwyrwiEgQo
BCoGCk8KAgQAEgQvAFQBGkMgQSByZXF1ZXN0IGZvciBjb25uZWN0aW9uIGluZm9ybWF0aW9u
IGZvciBhIHBhcnRpY3VsYXIgbWVtYmVyc2hpcC4KCgoKAwQAARIDLwgiCkQKBAQABAASBDEC
OQMaNiBPcGVyYXRpbmcgc3lzdGVtcyByZXF1aXJpbmcgc3BlY2lhbGl6ZWQga3ViZWNvbmZp
Z3MuCgoMCgUEAAQAARIDMQcWCmAKBgQABAACABIDNAQlGlEgR2VuZXJhdGVzIGEga3ViZWNv
bmZpZyB0aGF0IHdvcmtzIGZvciBhbGwgb3BlcmF0aW5nIHN5c3RlbXMgbm90IGRlZmluZWQK
IGJlbG93LgoKDgoHBAAEAAIAARIDNAQgCg4KBwQABAACAAISAzQjJApcCgYEAAQAAgESAzgE
IRpNIEdlbmVyYXRlcyBhIGt1YmVjb25maWcgdGhhdCBpcyBzcGVjaWZpY2FsbHkgZGVzaWdu
ZWQgdG8gd29yayB3aXRoCiBXaW5kb3dzLgoKDgoHBAAEAAIBARIDOAQcCg4KBwQABAACAQIS
AzgfIAo3CgQEAAIAEgM8AjsaKiBSZXF1aXJlZC4gVGhlIEZsZWV0IG1lbWJlcnNoaXAgcmVz
b3VyY2UuCgoMCgUEAAIABRIDPAIICgwKBQQAAgABEgM8CQ0KDAoFBAACAAMSAzwQEQoMCgUE
AAIACBIDPBI6Cg8KCAQAAgAInAgAEgM8EzkK9gIKBAQAAgESA0QCRBroAiBPcHRpb25hbC4g
V2hldGhlciB0byBmb3JjZSB0aGUgdXNlIG9mIENvbm5lY3QgQWdlbnQtYmFzZWQgdHJhbnNw
b3J0LgoKIFRoaXMgd2lsbCByZXR1cm4gYSBjb25maWd1cmF0aW9uIHRoYXQgdXNlcyBDb25u
ZWN0IEFnZW50IGFzIHRoZSB1bmRlcmx5aW5nCiB0cmFuc3BvcnQgbWVjaGFuaXNtIGZvciBj
bHVzdGVyIHR5cGVzIHRoYXQgd291bGQgb3RoZXJ3aXNlIGhhdmUgdXNlZCBhCiBkaWZmZXJl
bnQgdHJhbnNwb3J0LiBSZXF1aXJlcyB0aGF0IENvbm5lY3QgQWdlbnQgYmUgaW5zdGFsbGVk
IG9uIHRoZQogY2x1c3Rlci4gU2V0dGluZyB0aGlzIGZpZWxkIHRvIGZhbHNlIGlzIGVxdWl2
YWxlbnQgdG8gbm90IHNldHRpbmcgaXQuCgoMCgUEAAIBBRIDRAIGCgwKBQQAAgEBEgNEBxYK
DAoFBAACAQMSA0QZGgoMCgUEAAIBCBIDRBtDCg8KCAQAAgEInAgAEgNEHEIKrgEKBAQAAgIS
A0oCPhqgASBPcHRpb25hbC4gVGhlIENvbm5lY3QgR2F0ZXdheSB2ZXJzaW9uIHRvIGJlIHVz
ZWQgaW4gdGhlIHJlc3VsdGluZwogY29uZmlndXJhdGlvbi4KCiBMZWF2ZSB0aGlzIGZpZWxk
IGJsYW5rIHRvIGxldCB0aGUgc2VydmVyIGNob29zZSB0aGUgdmVyc2lvbiAocmVjb21tZW5k
ZWQpLgoKDAoFBAACAgUSA0oCCAoMCgUEAAICARIDSgkQCgwKBQQAAgIDEgNKExQKDAoFBAAC
AggSA0oVPQoPCggEAAICCJwIABIDShY8Ct0BCgQEAAIDEgNQAksazwEgT3B0aW9uYWwuIFRo
ZSBuYW1lc3BhY2UgdG8gdXNlIGluIHRoZSBrdWJlY29uZmlnIGNvbnRleHQuCgogSWYgdGhp
cyBmaWVsZCBpcyBzcGVjaWZpZWQsIHRoZSBzZXJ2ZXIgd2lsbCBzZXQgdGhlIGBuYW1lc3Bh
Y2VgIGZpZWxkIGluCiBrdWJlY29uZmlnIGNvbnRleHQuIElmIG5vdCBzcGVjaWZpZWQsIHRo
ZSBgbmFtZXNwYWNlYCBmaWVsZCBpcyBvbWl0dGVkLgoKDAoFBAACAwUSA1ACCAoMCgUEAAID
ARIDUAkdCgwKBQQAAgMDEgNQICEKDAoFBAACAwgSA1AiSgoPCggEAAIDCJwIABIDUCNJClAK
BAQAAgQSA1MCUBpDIE9wdGlvbmFsLiBUaGUgb3BlcmF0aW5nIHN5c3RlbSB3aGVyZSB0aGUg
a3ViZWNvbmZpZyB3aWxsIGJlIHVzZWQuCgoMCgUEAAIEBhIDUwIRCgwKBQQAAgQBEgNTEiIK
DAoFBAACBAMSA1MlJgoMCgUEAAIECBIDUydPCg8KCAQAAgQInAgAEgNTKE4KQQoCBAESBFcA
XgEaNSBDb25uZWN0aW9uIGluZm9ybWF0aW9uIGZvciBhIHBhcnRpY3VsYXIgbWVtYmVyc2hp
cC4KCgoKAwQBARIDVwgjCjsKBAQBAgASA1kCFxouIEEgZnVsbCBZQU1MIGt1YmVjb25maWcg
aW4gc2VyaWFsaXplZCBmb3JtYXQuCgoMCgUEAQIABRIDWQIHCgwKBQQBAgABEgNZCBIKDAoF
BAECAAMSA1kVFgpdCgQEAQIBEgNdAhYaUCBUaGUgZ2VuZXJhdGVkIFVSSSBvZiB0aGUgY2x1
c3RlciBhcyBhY2Nlc3NlZCB0aHJvdWdoIHRoZSBDb25uZWN0IEdhdGV3YXkKIEFQSS4KCgwK
BQQBAgEFEgNdAggKDAoFBAECAQESA10JEQoMCgUEAQIBAxIDXRQVYgZwcm90bzM=
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Gkeconnect::Gateway::V1::Control::GenerateCredentialsRequest ===
    # Fields for GenerateCredentialsRequest
    # Field: name Type: 9 ()
    # Field: force_use_agent Type: 8 ()
    # Field: version Type: 9 ()
    # Field: kubernetes_namespace Type: 9 ()
    # Field: operating_system Type: 14 (.google.cloud.gkeconnect.gateway.v1.GenerateCredentialsRequest.OperatingSystem)

# Enum: GenerateCredentialsRequest::OperatingSystem
our $GenerateCredentialsRequest_OPERATING_SYSTEM_UNSPECIFIED = 0;
our $GenerateCredentialsRequest_OPERATING_SYSTEM_WINDOWS = 1;

# === Message: Google::Cloud::Gkeconnect::Gateway::V1::Control::GenerateCredentialsResponse ===
    # Fields for GenerateCredentialsResponse
    # Field: kubeconfig Type: 12 ()
    # Field: endpoint Type: 9 ()

# === Service Client: Google::Cloud::Gkeconnect::Gateway::V1::Control::GatewayControlClient ===
package Google::Cloud::Gkeconnect::Gateway::V1::Control::GatewayControlClient;

=pod

=head2 Service Client: Google::Cloud::Gkeconnect::Gateway::V1::Control::GatewayControlClient

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
        ? Google::Cloud::Gkeconnect::Gateway::V1::Control::GenerateCredentialsRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.gkeconnect.gateway.v1.GatewayControl',
        method         => 'GenerateCredentials',
        request        => $req,
        response_class => 'Google::Cloud::Gkeconnect::Gateway::V1::Control::GenerateCredentialsResponse',
    });
}

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Gkeconnect::Gateway::V1::Control - Compiled Protocol Buffers messages for google/cloud/gkeconnect/gateway/v1/control.proto

=head1 SYNOPSIS

    use Google::Cloud::Gkeconnect::Gateway::V1::Control;

    my $msg = Google::Cloud::Gkeconnect::Gateway::V1::Control::GenerateCredentialsRequest->new({
        name => $name,
        force_use_agent => $force_use_agent,
        version => $version,
        kubernetes_namespace => $kubernetes_namespace,
    });

    # Read or update a field
    my $val = $msg->name();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Gkeconnect::Gateway::V1::Control::GenerateCredentialsRequest->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/gkeconnect/gateway/v1/control.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Gkeconnect::Gateway::V1::Control::GenerateCredentialsRequest

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

Type: C<Enum> (L<Google::Cloud::Gkeconnect::Gateway::V1::GenerateCredentialsRequest::OperatingSystem>)

Optional. The operating system where the kubeconfig will be used.

=back

=head3 Enum: GenerateCredentialsRequest::OperatingSystem

=over 4

=item * C<OPERATING_SYSTEM_UNSPECIFIED> => C<0>

=item * C<OPERATING_SYSTEM_WINDOWS> => C<1>

=back

=head2 Google::Cloud::Gkeconnect::Gateway::V1::Control::GenerateCredentialsResponse

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

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Gkeconnect::Gateway::V1::Control::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
