package Google::Cloud::Dialogflow::V2beta1::EncryptionSpec;

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
    eval { require Google::Longrunning::Operations };
    my $descriptor_b64 = <<'EOF';
CjVnb29nbGUvY2xvdWQvZGlhbG9nZmxvdy92MmJldGExL2VuY3J5cHRpb25fc3BlYy5wcm90
bxIfZ29vZ2xlLmNsb3VkLmRpYWxvZ2Zsb3cudjJiZXRhMRocZ29vZ2xlL2FwaS9hbm5vdGF0
aW9ucy5wcm90bxoXZ29vZ2xlL2FwaS9jbGllbnQucHJvdG8aH2dvb2dsZS9hcGkvZmllbGRf
YmVoYXZpb3IucHJvdG8aGWdvb2dsZS9hcGkvcmVzb3VyY2UucHJvdG8aI2dvb2dsZS9sb25n
cnVubmluZy9vcGVyYXRpb25zLnByb3RvImAKGEdldEVuY3J5cHRpb25TcGVjUmVxdWVzdBJE
CgRuYW1lGAEgASgJQjDgQQL6QSoKKGRpYWxvZ2Zsb3cuZ29vZ2xlYXBpcy5jb20vRW5jcnlw
dGlvblNwZWNSBG5hbWUi0QEKDkVuY3J5cHRpb25TcGVjEhcKBG5hbWUYASABKAlCA+BBBVIE
bmFtZRIcCgdrbXNfa2V5GAIgASgJQgPgQQJSBmttc0tleTqHAepBgwEKKGRpYWxvZ2Zsb3cu
Z29vZ2xlYXBpcy5jb20vRW5jcnlwdGlvblNwZWMSNnByb2plY3RzL3twcm9qZWN0fS9sb2Nh
dGlvbnMve2xvY2F0aW9ufS9lbmNyeXB0aW9uU3BlYyoPZW5jcnlwdGlvblNwZWNzMg5lbmNy
eXB0aW9uU3BlYyKAAQofSW5pdGlhbGl6ZUVuY3J5cHRpb25TcGVjUmVxdWVzdBJdCg9lbmNy
eXB0aW9uX3NwZWMYASABKAsyLy5nb29nbGUuY2xvdWQuZGlhbG9nZmxvdy52MmJldGExLkVu
Y3J5cHRpb25TcGVjQgPgQQJSDmVuY3J5cHRpb25TcGVjIiIKIEluaXRpYWxpemVFbmNyeXB0
aW9uU3BlY1Jlc3BvbnNlIoMBCiBJbml0aWFsaXplRW5jcnlwdGlvblNwZWNNZXRhZGF0YRJf
CgdyZXF1ZXN0GAQgASgLMkAuZ29vZ2xlLmNsb3VkLmRpYWxvZ2Zsb3cudjJiZXRhMS5Jbml0
aWFsaXplRW5jcnlwdGlvblNwZWNSZXF1ZXN0QgPgQQNSB3JlcXVlc3QyjgUKFUVuY3J5cHRp
b25TcGVjU2VydmljZRLFAQoRR2V0RW5jcnlwdGlvblNwZWMSOS5nb29nbGUuY2xvdWQuZGlh
bG9nZmxvdy52MmJldGExLkdldEVuY3J5cHRpb25TcGVjUmVxdWVzdBovLmdvb2dsZS5jbG91
ZC5kaWFsb2dmbG93LnYyYmV0YTEuRW5jcnlwdGlvblNwZWMiRILT5JMCNxI1L3YyYmV0YTEv
e25hbWU9cHJvamVjdHMvKi9sb2NhdGlvbnMvKi9lbmNyeXB0aW9uU3BlY33aQQRuYW1lErIC
ChhJbml0aWFsaXplRW5jcnlwdGlvblNwZWMSQC5nb29nbGUuY2xvdWQuZGlhbG9nZmxvdy52
MmJldGExLkluaXRpYWxpemVFbmNyeXB0aW9uU3BlY1JlcXVlc3QaHS5nb29nbGUubG9uZ3J1
bm5pbmcuT3BlcmF0aW9uIrQBgtPkkwJVIlAvdjJiZXRhMS97ZW5jcnlwdGlvbl9zcGVjLm5h
bWU9cHJvamVjdHMvKi9sb2NhdGlvbnMvKi9lbmNyeXB0aW9uU3BlY306aW5pdGlhbGl6ZToB
KtpBD2VuY3J5cHRpb25fc3BlY8pBRAogSW5pdGlhbGl6ZUVuY3J5cHRpb25TcGVjUmVzcG9u
c2USIEluaXRpYWxpemVFbmNyeXB0aW9uU3BlY01ldGFkYXRhGnjKQRlkaWFsb2dmbG93Lmdv
b2dsZWFwaXMuY29t0kFZaHR0cHM6Ly93d3cuZ29vZ2xlYXBpcy5jb20vYXV0aC9jbG91ZC1w
bGF0Zm9ybSxodHRwczovL3d3dy5nb29nbGVhcGlzLmNvbS9hdXRoL2RpYWxvZ2Zsb3dCqAEK
I2NvbS5nb29nbGUuY2xvdWQuZGlhbG9nZmxvdy52MmJldGExQhNFbmNyeXB0aW9uU3BlY1By
b3RvUAFaQ2Nsb3VkLmdvb2dsZS5jb20vZ28vZGlhbG9nZmxvdy9hcGl2MmJldGExL2RpYWxv
Z2Zsb3dwYjtkaWFsb2dmbG93cGKiAgJERqoCH0dvb2dsZS5DbG91ZC5EaWFsb2dmbG93LlYy
QmV0YTFKthsKBhIEDgB0AQq8BAoBDBIDDgASMrEEIENvcHlyaWdodCAyMDI2IEdvb2dsZSBM
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
AQISAxAAKAoJCgIDABIDEgAmCgkKAgMBEgMTACEKCQoCAwISAxQAKQoJCgIDAxIDFQAjCgkK
AgMEEgMWAC0KCAoBCBIDGAA8CgkKAgglEgMYADwKCAoBCBIDGQBaCgkKAggLEgMZAFoKCAoB
CBIDGgAiCgkKAggKEgMaACIKCAoBCBIDGwA0CgkKAggIEgMbADQKCAoBCBIDHAA8CgkKAggB
EgMcADwKCAoBCBIDHQAgCgkKAggkEgMdACAKTwoCBgASBCAAPwEaQyBNYW5hZ2VzIGVuY3J5
cHRpb24gc3BlYyBzZXR0aW5ncyBmb3IgRGlhbG9nZmxvdyBhbmQgQWdlbnQgQXNzaXN0LgoK
CgoDBgABEgMgCB0KCgoDBgADEgMhAkEKDAoFBgADmQgSAyECQQoLCgMGAAMSBCICJDMKDQoF
BgADmggSBCICJDMKQQoEBgACABIEJwIsAxozIEdldHMgbG9jYXRpb24tbGV2ZWwgZW5jcnlw
dGlvbiBrZXkgc3BlY2lmaWNhdGlvbi4KCgwKBQYAAgABEgMnBhcKDAoFBgACAAISAycYMAoM
CgUGAAIAAxIDJztJCg0KBQYAAgAEEgQoBCoGChEKCQYAAgAEsMq8IhIEKAQqBgoMCgUGAAIA
BBIDKwQyCg8KCAYAAgAEmwgAEgMrBDIK5wIKBAYAAgESBDMCPgMa2AIgSW5pdGlhbGl6ZXMg
YSBsb2NhdGlvbi1sZXZlbCBlbmNyeXB0aW9uIGtleSBzcGVjaWZpY2F0aW9uLiAgQW4gZXJy
b3Igd2lsbAogYmUgdGhyb3duIGlmIHRoZSBsb2NhdGlvbiBoYXMgcmVzb3VyY2VzIGFscmVh
ZHkgY3JlYXRlZCBiZWZvcmUgdGhlCiBpbml0aWFsaXphdGlvbi4gT25jZSB0aGUgZW5jcnlw
dGlvbiBzcGVjaWZpY2F0aW9uIGlzIGluaXRpYWxpemVkIGF0IGEKIGxvY2F0aW9uLCBpdCBp
cyBpbW11dGFibGUgYW5kIGFsbCBuZXdseSBjcmVhdGVkIHJlc291cmNlcyB1bmRlciB0aGUK
IGxvY2F0aW9uIHdpbGwgYmUgZW5jcnlwdGVkIHdpdGggdGhlIGV4aXN0aW5nIHNwZWNpZmlj
YXRpb24uCgoMCgUGAAIBARIDMwYeCgwKBQYAAgECEgMzHz4KDAoFBgACAQMSAzQPKwoNCgUG
AAIBBBIENQQ4BgoRCgkGAAIBBLDKvCISBDUEOAYKDAoFBgACAQQSAzkEPQoPCggGAAIBBJsI
ABIDOQQ9Cg0KBQYAAgEEEgQ6BD0GCg8KBwYAAgEEmQgSBDoEPQYKSQoCBAASBEIASgEaPSBU
aGUgcmVxdWVzdCB0byBnZXQgbG9jYXRpb24tbGV2ZWwgZW5jcnlwdGlvbiBzcGVjaWZpY2F0
aW9uLgoKCgoDBAABEgNCCCAKSgoEBAACABIERAJJBBo8IFJlcXVpcmVkLiBUaGUgbmFtZSBv
ZiB0aGUgZW5jcnlwdGlvbiBzcGVjIHJlc291cmNlIHRvIGdldC4KCgwKBQQAAgAFEgNEAggK
DAoFBAACAAESA0QJDQoMCgUEAAIAAxIDRBARCg0KBQQAAgAIEgREEkkDCg8KCAQAAgAInAgA
EgNFBCoKDwoHBAACAAifCBIERgRIBQqAAQoCBAESBE4AYQEadCBBIGN1c3RvbWVyLW1hbmFn
ZWQgZW5jcnlwdGlvbiBrZXkgc3BlY2lmaWNhdGlvbiB0aGF0IGNhbiBiZSBhcHBsaWVkIHRv
IGFsbAogY3JlYXRlZCByZXNvdXJjZXMgKGUuZy4gQ29udmVyc2F0aW9uKS4KCgoKAwQBARID
TggWCgsKAwQBBxIETwJUBAoNCgUEAQedCBIETwJUBAqbAQoEBAECABIDWQI8Go0BIEltbXV0
YWJsZS4gVGhlIHJlc291cmNlIG5hbWUgb2YgdGhlIGVuY3J5cHRpb24ga2V5IHNwZWNpZmlj
YXRpb24gcmVzb3VyY2UuCiBGb3JtYXQ6CiBwcm9qZWN0cy97cHJvamVjdH0vbG9jYXRpb25z
L3tsb2NhdGlvbn0vZW5jcnlwdGlvblNwZWMKCgwKBQQBAgAFEgNZAggKDAoFBAECAAESA1kJ
DQoMCgUEAQIAAxIDWRARCgwKBQQBAgAIEgNZEjsKDwoIBAECAAicCAASA1kTOgr5AgoEBAEC
ARIDYAI+GusCIFJlcXVpcmVkLiBUaGUgbmFtZSBvZiBjdXN0b21lci1tYW5hZ2VkIGVuY3J5
cHRpb24ga2V5IHRoYXQgaXMgdXNlZCB0bwogc2VjdXJlIGEgcmVzb3VyY2UgYW5kIGl0cyBz
dWItcmVzb3VyY2VzLiBJZiBlbXB0eSwgdGhlIHJlc291cmNlIGlzIHNlY3VyZWQKIGJ5IHRo
ZSBkZWZhdWx0IEdvb2dsZSBlbmNyeXB0aW9uIGtleS4gT25seSB0aGUga2V5IGluIHRoZSBz
YW1lIGxvY2F0aW9uIGFzCiB0aGlzIHJlc291cmNlIGlzIGFsbG93ZWQgdG8gYmUgdXNlZCBm
b3IgZW5jcnlwdGlvbi4gRm9ybWF0OgogYHByb2plY3RzL3twcm9qZWN0fS9sb2NhdGlvbnMv
e2xvY2F0aW9ufS9rZXlSaW5ncy97a2V5UmluZ30vY3J5cHRvS2V5cy97a2V5fWAKCgwKBQQB
AgEFEgNgAggKDAoFBAECAQESA2AJEAoMCgUEAQIBAxIDYBMUCgwKBQQBAgEIEgNgFT0KDwoI
BAECAQicCAASA2AWPApSCgIEAhIEZABqARpGIFRoZSByZXF1ZXN0IHRvIGluaXRpYWxpemUg
YSBsb2NhdGlvbi1sZXZlbCBlbmNyeXB0aW9uIHNwZWNpZmljYXRpb24uCgoKCgMEAgESA2QI
JwqpAgoEBAICABIDaQJOGpsCIFJlcXVpcmVkLiBUaGUgZW5jcnlwdGlvbiBzcGVjIHVzZWQg
Zm9yIENNRUsgZW5jcnlwdGlvbi4gSXQgaXMgcmVxdWlyZWQgdGhhdAogdGhlIGttcyBrZXkg
aXMgaW4gdGhlIHNhbWUgcmVnaW9uIGFzIHRoZSBlbmRwb2ludC4gVGhlIHNhbWUga2V5IHdp
bGwgYmUKIHVzZWQgZm9yIGFsbCBwcm92aXNpb25lZCByZXNvdXJjZXMsIGlmIGVuY3J5cHRp
b24gaXMgYXZhaWxhYmxlLiBJZiB0aGUKIGttc19rZXlfbmFtZSBpcyBsZWZ0IGVtcHR5LCBu
byBlbmNyeXB0aW9uIHdpbGwgYmUgZW5mb3JjZWQuCgoMCgUEAgIABhIDaQIQCgwKBQQCAgAB
EgNpESAKDAoFBAICAAMSA2kjJAoMCgUEAgIACBIDaSVNCg8KCAQCAgAInAgAEgNpJkwKUgoC
BAMSA20AKxpHIFRoZSByZXNwb25zZSB0byBpbml0aWFsaXplIGEgbG9jYXRpb24tbGV2ZWwg
ZW5jcnlwdGlvbiBzcGVjaWZpY2F0aW9uLgoKCgoDBAMBEgNtCCgKUgoCBAQSBHAAdAEaRiBN
ZXRhZGF0YSBmb3IgaW5pdGlhbGl6aW5nIGEgbG9jYXRpb24tbGV2ZWwgZW5jcnlwdGlvbiBz
cGVjaWZpY2F0aW9uLgoKCgoDBAQBEgNwCCgKRQoEBAQCABIEcgJzMho3IE91dHB1dCBvbmx5
LiBUaGUgb3JpZ2luYWwgcmVxdWVzdCBmb3IgaW5pdGlhbGl6YXRpb24uCgoMCgUEBAIABhID
cgIhCgwKBQQEAgABEgNyIikKDAoFBAQCAAMSA3IsLQoMCgUEBAIACBIDcwYxCg8KCAQEAgAI
nAgAEgNzBzBiBnByb3RvMw==
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Dialogflow::V2beta1::EncryptionSpec::GetEncryptionSpecRequest ===
    # Fields for GetEncryptionSpecRequest
    # Field: name Type: 9 ()

# === Message: Google::Cloud::Dialogflow::V2beta1::EncryptionSpec::EncryptionSpec ===
    # Fields for EncryptionSpec
    # Field: name Type: 9 ()
    # Field: kms_key Type: 9 ()

# === Message: Google::Cloud::Dialogflow::V2beta1::EncryptionSpec::InitializeEncryptionSpecRequest ===
    # Fields for InitializeEncryptionSpecRequest
    # Field: encryption_spec Type: 11 (.google.cloud.dialogflow.v2beta1.EncryptionSpec)

# === Message: Google::Cloud::Dialogflow::V2beta1::EncryptionSpec::InitializeEncryptionSpecResponse ===
    # Fields for InitializeEncryptionSpecResponse

# === Message: Google::Cloud::Dialogflow::V2beta1::EncryptionSpec::InitializeEncryptionSpecMetadata ===
    # Fields for InitializeEncryptionSpecMetadata
    # Field: request Type: 11 (.google.cloud.dialogflow.v2beta1.InitializeEncryptionSpecRequest)

# === Service Client: Google::Cloud::Dialogflow::V2beta1::EncryptionSpec::EncryptionSpecServiceClient ===
package Google::Cloud::Dialogflow::V2beta1::EncryptionSpec::EncryptionSpecServiceClient;

=pod

=head2 Service Client: Google::Cloud::Dialogflow::V2beta1::EncryptionSpec::EncryptionSpecServiceClient

Client stub representing the remote C<EncryptionSpecService> gRPC service. Delegates call dispatching to L<Google::gRPC::Client>.

=head3 target

The endpoint target address. Defaults to C<dialogflow.googleapis.com:443>.

=head3 credentials

The authentication credentials provider. Defaults to application default credentials via L<Google::Auth>.

=cut

use Moo;
use Google::Auth;
use Google::gRPC::Client;

has credentials => ( is => 'ro', default => sub { Google::Auth->default() } );
has target      => ( is => 'ro', default => 'dialogflow.googleapis.com:443' );

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

sub get_encryption_spec {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Dialogflow::V2beta1::EncryptionSpec::GetEncryptionSpecRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.dialogflow.v2beta1.EncryptionSpecService',
        method         => 'GetEncryptionSpec',
        request        => $req,
        response_class => 'Google::Cloud::Dialogflow::V2beta1::EncryptionSpec::EncryptionSpec',
    });
}

sub initialize_encryption_spec {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Dialogflow::V2beta1::EncryptionSpec::InitializeEncryptionSpecRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.dialogflow.v2beta1.EncryptionSpecService',
        method         => 'InitializeEncryptionSpec',
        request        => $req,
        response_class => 'Google::Longrunning::Operations::Operation',
    });
}

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Dialogflow::V2beta1::EncryptionSpec - Compiled Protocol Buffers messages for google/cloud/dialogflow/v2beta1/encryption_spec.proto

=head1 SYNOPSIS

    use Google::Cloud::Dialogflow::V2beta1::EncryptionSpec;

    my $msg = Google::Cloud::Dialogflow::V2beta1::EncryptionSpec::GetEncryptionSpecRequest->new({
        name => $name,
    });

    # Read or update a field
    my $val = $msg->name();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Dialogflow::V2beta1::EncryptionSpec::GetEncryptionSpecRequest->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/dialogflow/v2beta1/encryption_spec.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Dialogflow::V2beta1::EncryptionSpec::GetEncryptionSpecRequest

The request to get location-level encryption specification.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. The name of the encryption spec resource to get.

=back

=head2 Google::Cloud::Dialogflow::V2beta1::EncryptionSpec::EncryptionSpec

A customer-managed encryption key specification that can be applied to all
created resources (e.g. Conversation).

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Immutable. The resource name of the encryption key specification resource.
Format:
projects/{project}/locations/{location}/encryptionSpec

=item * C<< $msg->kms_key() >> / C<< $msg->kms_key($value) >>

Type: C<String>

Required. The name of customer-managed encryption key that is used to
secure a resource and its sub-resources. If empty, the resource is secured
by the default Google encryption key. Only the key in the same location as
this resource is allowed to be used for encryption. Format:
`projects/{project}/locations/{location}/keyRings/{keyRing}/cryptoKeys/{key}`

=back

=head2 Google::Cloud::Dialogflow::V2beta1::EncryptionSpec::InitializeEncryptionSpecRequest

The request to initialize a location-level encryption specification.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->encryption_spec() >> / C<< $msg->encryption_spec($value) >>

Type: C<Message> (L<Google::Cloud::Dialogflow::V2beta1::EncryptionSpec::EncryptionSpec>)

Required. The encryption spec used for CMEK encryption. It is required that
the kms key is in the same region as the endpoint. The same key will be
used for all provisioned resources, if encryption is available. If the
kms_key_name is left empty, no encryption will be enforced.

=back

=head2 Google::Cloud::Dialogflow::V2beta1::EncryptionSpec::InitializeEncryptionSpecResponse

The response to initialize a location-level encryption specification.

Inherits from L<Protobuf::Message>.

=head2 Google::Cloud::Dialogflow::V2beta1::EncryptionSpec::InitializeEncryptionSpecMetadata

Metadata for initializing a location-level encryption specification.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->request() >> / C<< $msg->request($value) >>

Type: C<Message> (L<Google::Cloud::Dialogflow::V2beta1::EncryptionSpec::InitializeEncryptionSpecRequest>)

Output only. The original request for initialization.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Dialogflow::V2beta1::EncryptionSpec::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
