package Google::Cloud::Chronicle::V1::Instance;

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
    my $descriptor_b64 = <<'EOF';
Cihnb29nbGUvY2xvdWQvY2hyb25pY2xlL3YxL2luc3RhbmNlLnByb3RvEhlnb29nbGUuY2xv
dWQuY2hyb25pY2xlLnYxGhxnb29nbGUvYXBpL2Fubm90YXRpb25zLnByb3RvGhdnb29nbGUv
YXBpL2NsaWVudC5wcm90bxofZ29vZ2xlL2FwaS9maWVsZF9iZWhhdmlvci5wcm90bxoZZ29v
Z2xlL2FwaS9yZXNvdXJjZS5wcm90byKeAQoISW5zdGFuY2USFwoEbmFtZRgBIAEoCUID4EEI
UgRuYW1lOnnqQXYKIWNocm9uaWNsZS5nb29nbGVhcGlzLmNvbS9JbnN0YW5jZRI8cHJvamVj
dHMve3Byb2plY3R9L2xvY2F0aW9ucy97bG9jYXRpb259L2luc3RhbmNlcy97aW5zdGFuY2V9
KglpbnN0YW5jZXMyCGluc3RhbmNlIlMKEkdldEluc3RhbmNlUmVxdWVzdBI9CgRuYW1lGAEg
ASgJQingQQL6QSMKIWNocm9uaWNsZS5nb29nbGVhcGlzLmNvbS9JbnN0YW5jZVIEbmFtZTKB
AgoPSW5zdGFuY2VTZXJ2aWNlEp8BCgtHZXRJbnN0YW5jZRItLmdvb2dsZS5jbG91ZC5jaHJv
bmljbGUudjEuR2V0SW5zdGFuY2VSZXF1ZXN0GiMuZ29vZ2xlLmNsb3VkLmNocm9uaWNsZS52
MS5JbnN0YW5jZSI8gtPkkwIvEi0vdjEve25hbWU9cHJvamVjdHMvKi9sb2NhdGlvbnMvKi9p
bnN0YW5jZXMvKn3aQQRuYW1lGkzKQRhjaHJvbmljbGUuZ29vZ2xlYXBpcy5jb23SQS5odHRw
czovL3d3dy5nb29nbGVhcGlzLmNvbS9hdXRoL2Nsb3VkLXBsYXRmb3JtQsQBCh1jb20uZ29v
Z2xlLmNsb3VkLmNocm9uaWNsZS52MUINSW5zdGFuY2VQcm90b1ABWjtjbG91ZC5nb29nbGUu
Y29tL2dvL2Nocm9uaWNsZS9hcGl2MS9jaHJvbmljbGVwYjtjaHJvbmljbGVwYqoCGUdvb2ds
ZS5DbG91ZC5DaHJvbmljbGUuVjHKAhlHb29nbGVcQ2xvdWRcQ2hyb25pY2xlXFYx6gIcR29v
Z2xlOjpDbG91ZDo6Q2hyb25pY2xlOjpWMUqaDQoGEgQOAEcBCrwECgEMEgMOABIysQQgQ29w
eXJpZ2h0IDIwMjUgR29vZ2xlIExMQwoKIExpY2Vuc2VkIHVuZGVyIHRoZSBBcGFjaGUgTGlj
ZW5zZSwgVmVyc2lvbiAyLjAgKHRoZSAiTGljZW5zZSIpOwogeW91IG1heSBub3QgdXNlIHRo
aXMgZmlsZSBleGNlcHQgaW4gY29tcGxpYW5jZSB3aXRoIHRoZSBMaWNlbnNlLgogWW91IG1h
eSBvYnRhaW4gYSBjb3B5IG9mIHRoZSBMaWNlbnNlIGF0CgogICAgIGh0dHA6Ly93d3cuYXBh
Y2hlLm9yZy9saWNlbnNlcy9MSUNFTlNFLTIuMAoKIFVubGVzcyByZXF1aXJlZCBieSBhcHBs
aWNhYmxlIGxhdyBvciBhZ3JlZWQgdG8gaW4gd3JpdGluZywgc29mdHdhcmUKIGRpc3RyaWJ1
dGVkIHVuZGVyIHRoZSBMaWNlbnNlIGlzIGRpc3RyaWJ1dGVkIG9uIGFuICJBUyBJUyIgQkFT
SVMsCiBXSVRIT1VUIFdBUlJBTlRJRVMgT1IgQ09ORElUSU9OUyBPRiBBTlkgS0lORCwgZWl0
aGVyIGV4cHJlc3Mgb3IgaW1wbGllZC4KIFNlZSB0aGUgTGljZW5zZSBmb3IgdGhlIHNwZWNp
ZmljIGxhbmd1YWdlIGdvdmVybmluZyBwZXJtaXNzaW9ucyBhbmQKIGxpbWl0YXRpb25zIHVu
ZGVyIHRoZSBMaWNlbnNlLgoKCAoBAhIDEAAiCgkKAgMAEgMSACYKCQoCAwESAxMAIQoJCgID
AhIDFAApCgkKAgMDEgMVACMKCAoBCBIDFwA2CgkKAgglEgMXADYKCAoBCBIDGABSCgkKAggL
EgMYAFIKCAoBCBIDGQAiCgkKAggKEgMZACIKCAoBCBIDGgAuCgkKAggIEgMaAC4KCAoBCBID
GwA2CgkKAggBEgMbADYKCAoBCBIDHAA2CgkKAggpEgMcADYKCAoBCBIDHQA1CgkKAggtEgMd
ADUKUQoCBgASBCAALAEaRSBJbnN0YW5jZVNlcnZpY2UgcHJvdmlkZXMgdGhlIGVudHJ5IGlu
dGVyZmFjZSBmb3IgdGhlIENocm9uaWNsZSBBUEkuCgoKCgMGAAESAyAIFwoKCgMGAAMSAyEC
QAoMCgUGAAOZCBIDIQJACgsKAwYAAxIEIgIjNwoNCgUGAAOaCBIEIgIjNwogCgQGAAIAEgQm
AisDGhIgR2V0cyBhIEluc3RhbmNlLgoKDAoFBgACAAESAyYGEQoMCgUGAAIAAhIDJhIkCgwK
BQYAAgADEgMmLzcKDQoFBgACAAQSBCcEKQYKEQoJBgACAASwyrwiEgQnBCkGCgwKBQYAAgAE
EgMqBDIKDwoIBgACAASbCAASAyoEMgpNCgIEABIELwA6ARpBIEEgSW5zdGFuY2UgcmVwcmVz
ZW50cyBhbiBpbnN0YW50aWF0aW9uIG9mIHRoZSBJbnN0YW5jZSBwcm9kdWN0LgoKCgoDBAAB
EgMvCBAKCwoDBAAHEgQwAjUECg0KBQQAB50IEgQwAjUECoYBCgQEAAIAEgM5Aj0aeSBJZGVu
dGlmaWVyLiBUaGUgcmVzb3VyY2UgbmFtZSBvZiB0aGlzIGluc3RhbmNlLgogRm9ybWF0OiBg
cHJvamVjdHMve3Byb2plY3R9L2xvY2F0aW9ucy97bG9jYXRpb259L2luc3RhbmNlcy97aW5z
dGFuY2V9YAoKDAoFBAACAAUSAzkCCAoMCgUEAAIAARIDOQkNCgwKBQQAAgADEgM5EBEKDAoF
BAACAAgSAzkSPAoPCggEAAIACJwIABIDORM7CigKAgQBEgQ9AEcBGhwgUmVxdWVzdCB0byBn
ZXQgYSBJbnN0YW5jZS4KCgoKAwQBARIDPQgaCosBCgQEAQIAEgRBAkYEGn0gUmVxdWlyZWQu
IFRoZSBuYW1lIG9mIHRoZSBpbnN0YW5jZSB0byByZXRyaWV2ZS4KIEZvcm1hdDoKIGBwcm9q
ZWN0cy97cHJvamVjdF9pZH0vbG9jYXRpb25zL3tsb2NhdGlvbn0vaW5zdGFuY2VzL3tpbnN0
YW5jZX1gCgoMCgUEAQIABRIDQQIICgwKBQQBAgABEgNBCQ0KDAoFBAECAAMSA0EQEQoNCgUE
AQIACBIEQRJGAwoPCggEAQIACJwIABIDQgQqCg8KBwQBAgAInwgSBEMERQViBnByb3RvMw==

EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Chronicle::V1::Instance::Instance ===
    # Fields for Instance
    # Field: name Type: 9 ()

# === Message: Google::Cloud::Chronicle::V1::Instance::GetInstanceRequest ===
    # Fields for GetInstanceRequest
    # Field: name Type: 9 ()

# === Service Client: Google::Cloud::Chronicle::V1::Instance::InstanceServiceClient ===
package Google::Cloud::Chronicle::V1::Instance::InstanceServiceClient;

=pod

=head2 Service Client: Google::Cloud::Chronicle::V1::Instance::InstanceServiceClient

Client stub representing the remote C<InstanceService> gRPC service. Delegates call dispatching to L<Google::gRPC::Client>.

=head3 target

The endpoint target address. Defaults to C<chronicle.googleapis.com:443>.

=head3 credentials

The authentication credentials provider. Defaults to application default credentials via L<Google::Auth>.

=cut

use Moo;
use Google::Auth;
use Google::gRPC::Client;

has credentials => ( is => 'ro', default => sub { Google::Auth->default() } );
has target      => ( is => 'ro', default => 'chronicle.googleapis.com:443' );

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

sub get_instance {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Chronicle::V1::Instance::GetInstanceRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.chronicle.v1.InstanceService',
        method         => 'GetInstance',
        request        => $req,
        response_class => 'Google::Cloud::Chronicle::V1::Instance::Instance',
    });
}

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Chronicle::V1::Instance - Compiled Protocol Buffers messages for google/cloud/chronicle/v1/instance.proto

=head1 SYNOPSIS

    use Google::Cloud::Chronicle::V1::Instance;

    my $msg = Google::Cloud::Chronicle::V1::Instance::Instance->new({
        name => $name,
    });

    # Read or update a field
    my $val = $msg->name();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Chronicle::V1::Instance::Instance->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/chronicle/v1/instance.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Chronicle::V1::Instance::Instance

A Instance represents an instantiation of the Instance product.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Identifier. The resource name of this instance.
Format: `projects/{project}/locations/{location}/instances/{instance}`

=back

=head2 Google::Cloud::Chronicle::V1::Instance::GetInstanceRequest

Request to get a Instance.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. The name of the instance to retrieve.
Format:
`projects/{project_id}/locations/{location}/instances/{instance}`

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Chronicle::V1::Instance::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
