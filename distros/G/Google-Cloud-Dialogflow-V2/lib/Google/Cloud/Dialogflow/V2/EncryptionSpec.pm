package Google::Cloud::Dialogflow::V2::EncryptionSpec;

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
CjBnb29nbGUvY2xvdWQvZGlhbG9nZmxvdy92Mi9lbmNyeXB0aW9uX3NwZWMucHJvdG8SGmdv
b2dsZS5jbG91ZC5kaWFsb2dmbG93LnYyGhxnb29nbGUvYXBpL2Fubm90YXRpb25zLnByb3Rv
Ghdnb29nbGUvYXBpL2NsaWVudC5wcm90bxofZ29vZ2xlL2FwaS9maWVsZF9iZWhhdmlvci5w
cm90bxoZZ29vZ2xlL2FwaS9yZXNvdXJjZS5wcm90bxojZ29vZ2xlL2xvbmdydW5uaW5nL29w
ZXJhdGlvbnMucHJvdG8iYAoYR2V0RW5jcnlwdGlvblNwZWNSZXF1ZXN0EkQKBG5hbWUYASAB
KAlCMOBBAvpBKgooZGlhbG9nZmxvdy5nb29nbGVhcGlzLmNvbS9FbmNyeXB0aW9uU3BlY1IE
bmFtZSLRAQoORW5jcnlwdGlvblNwZWMSFwoEbmFtZRgBIAEoCUID4EEFUgRuYW1lEhwKB2tt
c19rZXkYAiABKAlCA+BBAlIGa21zS2V5OocB6kGDAQooZGlhbG9nZmxvdy5nb29nbGVhcGlz
LmNvbS9FbmNyeXB0aW9uU3BlYxI2cHJvamVjdHMve3Byb2plY3R9L2xvY2F0aW9ucy97bG9j
YXRpb259L2VuY3J5cHRpb25TcGVjKg9lbmNyeXB0aW9uU3BlY3MyDmVuY3J5cHRpb25TcGVj
InsKH0luaXRpYWxpemVFbmNyeXB0aW9uU3BlY1JlcXVlc3QSWAoPZW5jcnlwdGlvbl9zcGVj
GAEgASgLMiouZ29vZ2xlLmNsb3VkLmRpYWxvZ2Zsb3cudjIuRW5jcnlwdGlvblNwZWNCA+BB
AlIOZW5jcnlwdGlvblNwZWMiIgogSW5pdGlhbGl6ZUVuY3J5cHRpb25TcGVjUmVzcG9uc2Ui
fgogSW5pdGlhbGl6ZUVuY3J5cHRpb25TcGVjTWV0YWRhdGESWgoHcmVxdWVzdBgEIAEoCzI7
Lmdvb2dsZS5jbG91ZC5kaWFsb2dmbG93LnYyLkluaXRpYWxpemVFbmNyeXB0aW9uU3BlY1Jl
cXVlc3RCA+BBA1IHcmVxdWVzdDL1BAoVRW5jcnlwdGlvblNwZWNTZXJ2aWNlErYBChFHZXRF
bmNyeXB0aW9uU3BlYxI0Lmdvb2dsZS5jbG91ZC5kaWFsb2dmbG93LnYyLkdldEVuY3J5cHRp
b25TcGVjUmVxdWVzdBoqLmdvb2dsZS5jbG91ZC5kaWFsb2dmbG93LnYyLkVuY3J5cHRpb25T
cGVjIj+C0+STAjISMC92Mi97bmFtZT1wcm9qZWN0cy8qL2xvY2F0aW9ucy8qL2VuY3J5cHRp
b25TcGVjfdpBBG5hbWUSqAIKGEluaXRpYWxpemVFbmNyeXB0aW9uU3BlYxI7Lmdvb2dsZS5j
bG91ZC5kaWFsb2dmbG93LnYyLkluaXRpYWxpemVFbmNyeXB0aW9uU3BlY1JlcXVlc3QaHS5n
b29nbGUubG9uZ3J1bm5pbmcuT3BlcmF0aW9uIq8BgtPkkwJQIksvdjIve2VuY3J5cHRpb25f
c3BlYy5uYW1lPXByb2plY3RzLyovbG9jYXRpb25zLyovZW5jcnlwdGlvblNwZWN9OmluaXRp
YWxpemU6ASraQQ9lbmNyeXB0aW9uX3NwZWPKQUQKIEluaXRpYWxpemVFbmNyeXB0aW9uU3Bl
Y1Jlc3BvbnNlEiBJbml0aWFsaXplRW5jcnlwdGlvblNwZWNNZXRhZGF0YRp4ykEZZGlhbG9n
Zmxvdy5nb29nbGVhcGlzLmNvbdJBWWh0dHBzOi8vd3d3Lmdvb2dsZWFwaXMuY29tL2F1dGgv
Y2xvdWQtcGxhdGZvcm0saHR0cHM6Ly93d3cuZ29vZ2xlYXBpcy5jb20vYXV0aC9kaWFsb2dm
bG93QpkBCh5jb20uZ29vZ2xlLmNsb3VkLmRpYWxvZ2Zsb3cudjJCE0VuY3J5cHRpb25TcGVj
UHJvdG9QAVo+Y2xvdWQuZ29vZ2xlLmNvbS9nby9kaWFsb2dmbG93L2FwaXYyL2RpYWxvZ2Zs
b3dwYjtkaWFsb2dmbG93cGKiAgJERqoCGkdvb2dsZS5DbG91ZC5EaWFsb2dmbG93LlYySrYb
CgYSBA4AdAEKvAQKAQwSAw4AEjKxBCBDb3B5cmlnaHQgMjAyNiBHb29nbGUgTExDCgogTGlj
ZW5zZWQgdW5kZXIgdGhlIEFwYWNoZSBMaWNlbnNlLCBWZXJzaW9uIDIuMCAodGhlICJMaWNl
bnNlIik7CiB5b3UgbWF5IG5vdCB1c2UgdGhpcyBmaWxlIGV4Y2VwdCBpbiBjb21wbGlhbmNl
IHdpdGggdGhlIExpY2Vuc2UuCiBZb3UgbWF5IG9idGFpbiBhIGNvcHkgb2YgdGhlIExpY2Vu
c2UgYXQKCiAgICAgaHR0cDovL3d3dy5hcGFjaGUub3JnL2xpY2Vuc2VzL0xJQ0VOU0UtMi4w
CgogVW5sZXNzIHJlcXVpcmVkIGJ5IGFwcGxpY2FibGUgbGF3IG9yIGFncmVlZCB0byBpbiB3
cml0aW5nLCBzb2Z0d2FyZQogZGlzdHJpYnV0ZWQgdW5kZXIgdGhlIExpY2Vuc2UgaXMgZGlz
dHJpYnV0ZWQgb24gYW4gIkFTIElTIiBCQVNJUywKIFdJVEhPVVQgV0FSUkFOVElFUyBPUiBD
T05ESVRJT05TIE9GIEFOWSBLSU5ELCBlaXRoZXIgZXhwcmVzcyBvciBpbXBsaWVkLgogU2Vl
IHRoZSBMaWNlbnNlIGZvciB0aGUgc3BlY2lmaWMgbGFuZ3VhZ2UgZ292ZXJuaW5nIHBlcm1p
c3Npb25zIGFuZAogbGltaXRhdGlvbnMgdW5kZXIgdGhlIExpY2Vuc2UuCgoICgECEgMQACMK
CQoCAwASAxIAJgoJCgIDARIDEwAhCgkKAgMCEgMUACkKCQoCAwMSAxUAIwoJCgIDBBIDFgAt
CggKAQgSAxgANwoJCgIIJRIDGAA3CggKAQgSAxkAVQoJCgIICxIDGQBVCggKAQgSAxoAIgoJ
CgIIChIDGgAiCggKAQgSAxsANAoJCgIICBIDGwA0CggKAQgSAxwANwoJCgIIARIDHAA3CggK
AQgSAx0AIAoJCgIIJBIDHQAgCk8KAgYAEgQgAD8BGkMgTWFuYWdlcyBlbmNyeXB0aW9uIHNw
ZWMgc2V0dGluZ3MgZm9yIERpYWxvZ2Zsb3cgYW5kIEFnZW50IEFzc2lzdC4KCgoKAwYAARID
IAgdCgoKAwYAAxIDIQJBCgwKBQYAA5kIEgMhAkEKCwoDBgADEgQiAiQzCg0KBQYAA5oIEgQi
AiQzCkEKBAYAAgASBCcCLAMaMyBHZXRzIGxvY2F0aW9uLWxldmVsIGVuY3J5cHRpb24ga2V5
IHNwZWNpZmljYXRpb24uCgoMCgUGAAIAARIDJwYXCgwKBQYAAgACEgMnGDAKDAoFBgACAAMS
Ayc7SQoNCgUGAAIABBIEKAQqBgoRCgkGAAIABLDKvCISBCgEKgYKDAoFBgACAAQSAysEMgoP
CggGAAIABJsIABIDKwQyCucCCgQGAAIBEgQzAj4DGtgCIEluaXRpYWxpemVzIGEgbG9jYXRp
b24tbGV2ZWwgZW5jcnlwdGlvbiBrZXkgc3BlY2lmaWNhdGlvbi4gIEFuIGVycm9yIHdpbGwK
IGJlIHRocm93biBpZiB0aGUgbG9jYXRpb24gaGFzIHJlc291cmNlcyBhbHJlYWR5IGNyZWF0
ZWQgYmVmb3JlIHRoZQogaW5pdGlhbGl6YXRpb24uIE9uY2UgdGhlIGVuY3J5cHRpb24gc3Bl
Y2lmaWNhdGlvbiBpcyBpbml0aWFsaXplZCBhdCBhCiBsb2NhdGlvbiwgaXQgaXMgaW1tdXRh
YmxlIGFuZCBhbGwgbmV3bHkgY3JlYXRlZCByZXNvdXJjZXMgdW5kZXIgdGhlCiBsb2NhdGlv
biB3aWxsIGJlIGVuY3J5cHRlZCB3aXRoIHRoZSBleGlzdGluZyBzcGVjaWZpY2F0aW9uLgoK
DAoFBgACAQESAzMGHgoMCgUGAAIBAhIDMx8+CgwKBQYAAgEDEgM0DysKDQoFBgACAQQSBDUE
OAYKEQoJBgACAQSwyrwiEgQ1BDgGCgwKBQYAAgEEEgM5BD0KDwoIBgACAQSbCAASAzkEPQoN
CgUGAAIBBBIEOgQ9BgoPCgcGAAIBBJkIEgQ6BD0GCkkKAgQAEgRCAEoBGj0gVGhlIHJlcXVl
c3QgdG8gZ2V0IGxvY2F0aW9uLWxldmVsIGVuY3J5cHRpb24gc3BlY2lmaWNhdGlvbi4KCgoK
AwQAARIDQgggCkoKBAQAAgASBEQCSQQaPCBSZXF1aXJlZC4gVGhlIG5hbWUgb2YgdGhlIGVu
Y3J5cHRpb24gc3BlYyByZXNvdXJjZSB0byBnZXQuCgoMCgUEAAIABRIDRAIICgwKBQQAAgAB
EgNECQ0KDAoFBAACAAMSA0QQEQoNCgUEAAIACBIERBJJAwoPCggEAAIACJwIABIDRQQqCg8K
BwQAAgAInwgSBEYESAUKgAEKAgQBEgROAGEBGnQgQSBjdXN0b21lci1tYW5hZ2VkIGVuY3J5
cHRpb24ga2V5IHNwZWNpZmljYXRpb24gdGhhdCBjYW4gYmUgYXBwbGllZCB0byBhbGwKIGNy
ZWF0ZWQgcmVzb3VyY2VzIChlLmcuIENvbnZlcnNhdGlvbikuCgoKCgMEAQESA04IFgoLCgME
AQcSBE8CVAQKDQoFBAEHnQgSBE8CVAQKmwEKBAQBAgASA1kCPBqNASBJbW11dGFibGUuIFRo
ZSByZXNvdXJjZSBuYW1lIG9mIHRoZSBlbmNyeXB0aW9uIGtleSBzcGVjaWZpY2F0aW9uIHJl
c291cmNlLgogRm9ybWF0OgogcHJvamVjdHMve3Byb2plY3R9L2xvY2F0aW9ucy97bG9jYXRp
b259L2VuY3J5cHRpb25TcGVjCgoMCgUEAQIABRIDWQIICgwKBQQBAgABEgNZCQ0KDAoFBAEC
AAMSA1kQEQoMCgUEAQIACBIDWRI7Cg8KCAQBAgAInAgAEgNZEzoK+QIKBAQBAgESA2ACPhrr
AiBSZXF1aXJlZC4gVGhlIG5hbWUgb2YgY3VzdG9tZXItbWFuYWdlZCBlbmNyeXB0aW9uIGtl
eSB0aGF0IGlzIHVzZWQgdG8KIHNlY3VyZSBhIHJlc291cmNlIGFuZCBpdHMgc3ViLXJlc291
cmNlcy4gSWYgZW1wdHksIHRoZSByZXNvdXJjZSBpcyBzZWN1cmVkCiBieSB0aGUgZGVmYXVs
dCBHb29nbGUgZW5jcnlwdGlvbiBrZXkuIE9ubHkgdGhlIGtleSBpbiB0aGUgc2FtZSBsb2Nh
dGlvbiBhcwogdGhpcyByZXNvdXJjZSBpcyBhbGxvd2VkIHRvIGJlIHVzZWQgZm9yIGVuY3J5
cHRpb24uIEZvcm1hdDoKIGBwcm9qZWN0cy97cHJvamVjdH0vbG9jYXRpb25zL3tsb2NhdGlv
bn0va2V5UmluZ3Mve2tleVJpbmd9L2NyeXB0b0tleXMve2tleX1gCgoMCgUEAQIBBRIDYAII
CgwKBQQBAgEBEgNgCRAKDAoFBAECAQMSA2ATFAoMCgUEAQIBCBIDYBU9Cg8KCAQBAgEInAgA
EgNgFjwKUgoCBAISBGQAagEaRiBUaGUgcmVxdWVzdCB0byBpbml0aWFsaXplIGEgbG9jYXRp
b24tbGV2ZWwgZW5jcnlwdGlvbiBzcGVjaWZpY2F0aW9uLgoKCgoDBAIBEgNkCCcKqQIKBAQC
AgASA2kCThqbAiBSZXF1aXJlZC4gVGhlIGVuY3J5cHRpb24gc3BlYyB1c2VkIGZvciBDTUVL
IGVuY3J5cHRpb24uIEl0IGlzIHJlcXVpcmVkIHRoYXQKIHRoZSBrbXMga2V5IGlzIGluIHRo
ZSBzYW1lIHJlZ2lvbiBhcyB0aGUgZW5kcG9pbnQuIFRoZSBzYW1lIGtleSB3aWxsIGJlCiB1
c2VkIGZvciBhbGwgcHJvdmlzaW9uZWQgcmVzb3VyY2VzLCBpZiBlbmNyeXB0aW9uIGlzIGF2
YWlsYWJsZS4gSWYgdGhlCiBrbXNfa2V5X25hbWUgaXMgbGVmdCBlbXB0eSwgbm8gZW5jcnlw
dGlvbiB3aWxsIGJlIGVuZm9yY2VkLgoKDAoFBAICAAYSA2kCEAoMCgUEAgIAARIDaREgCgwK
BQQCAgADEgNpIyQKDAoFBAICAAgSA2klTQoPCggEAgIACJwIABIDaSZMClIKAgQDEgNtACsa
RyBUaGUgcmVzcG9uc2UgdG8gaW5pdGlhbGl6ZSBhIGxvY2F0aW9uLWxldmVsIGVuY3J5cHRp
b24gc3BlY2lmaWNhdGlvbi4KCgoKAwQDARIDbQgoClIKAgQEEgRwAHQBGkYgTWV0YWRhdGEg
Zm9yIGluaXRpYWxpemluZyBhIGxvY2F0aW9uLWxldmVsIGVuY3J5cHRpb24gc3BlY2lmaWNh
dGlvbi4KCgoKAwQEARIDcAgoCkUKBAQEAgASBHICczIaNyBPdXRwdXQgb25seS4gVGhlIG9y
aWdpbmFsIHJlcXVlc3QgZm9yIGluaXRpYWxpemF0aW9uLgoKDAoFBAQCAAYSA3ICIQoMCgUE
BAIAARIDciIpCgwKBQQEAgADEgNyLC0KDAoFBAQCAAgSA3MGMQoPCggEBAIACJwIABIDcwcw
YgZwcm90bzM=
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Dialogflow::V2::EncryptionSpec::GetEncryptionSpecRequest ===
    # Fields for GetEncryptionSpecRequest
    # Field: name Type: 9 ()

# === Message: Google::Cloud::Dialogflow::V2::EncryptionSpec::EncryptionSpec ===
    # Fields for EncryptionSpec
    # Field: name Type: 9 ()
    # Field: kms_key Type: 9 ()

# === Message: Google::Cloud::Dialogflow::V2::EncryptionSpec::InitializeEncryptionSpecRequest ===
    # Fields for InitializeEncryptionSpecRequest
    # Field: encryption_spec Type: 11 (.google.cloud.dialogflow.v2.EncryptionSpec)

# === Message: Google::Cloud::Dialogflow::V2::EncryptionSpec::InitializeEncryptionSpecResponse ===
    # Fields for InitializeEncryptionSpecResponse

# === Message: Google::Cloud::Dialogflow::V2::EncryptionSpec::InitializeEncryptionSpecMetadata ===
    # Fields for InitializeEncryptionSpecMetadata
    # Field: request Type: 11 (.google.cloud.dialogflow.v2.InitializeEncryptionSpecRequest)

# === Service Client: Google::Cloud::Dialogflow::V2::EncryptionSpec::EncryptionSpecServiceClient ===
package Google::Cloud::Dialogflow::V2::EncryptionSpec::EncryptionSpecServiceClient;

=pod

=head2 Service Client: Google::Cloud::Dialogflow::V2::EncryptionSpec::EncryptionSpecServiceClient

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
        ? Google::Cloud::Dialogflow::V2::EncryptionSpec::GetEncryptionSpecRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.dialogflow.v2.EncryptionSpecService',
        method         => 'GetEncryptionSpec',
        request        => $req,
        response_class => 'Google::Cloud::Dialogflow::V2::EncryptionSpec::EncryptionSpec',
    });
}

sub initialize_encryption_spec {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Dialogflow::V2::EncryptionSpec::InitializeEncryptionSpecRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.dialogflow.v2.EncryptionSpecService',
        method         => 'InitializeEncryptionSpec',
        request        => $req,
        response_class => 'Google::Longrunning::Operations::Operation',
    });
}

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Dialogflow::V2::EncryptionSpec - Compiled Protocol Buffers messages for google/cloud/dialogflow/v2/encryption_spec.proto

=head1 SYNOPSIS

    use Google::Cloud::Dialogflow::V2::EncryptionSpec;

    my $msg = Google::Cloud::Dialogflow::V2::EncryptionSpec::GetEncryptionSpecRequest->new({
        name => $name,
    });

    # Read or update a field
    my $val = $msg->name();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Dialogflow::V2::EncryptionSpec::GetEncryptionSpecRequest->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/dialogflow/v2/encryption_spec.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Dialogflow::V2::EncryptionSpec::GetEncryptionSpecRequest

The request to get location-level encryption specification.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. The name of the encryption spec resource to get.

=back

=head2 Google::Cloud::Dialogflow::V2::EncryptionSpec::EncryptionSpec

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

=head2 Google::Cloud::Dialogflow::V2::EncryptionSpec::InitializeEncryptionSpecRequest

The request to initialize a location-level encryption specification.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->encryption_spec() >> / C<< $msg->encryption_spec($value) >>

Type: C<Message> (L<Google::Cloud::Dialogflow::V2::EncryptionSpec::EncryptionSpec>)

Required. The encryption spec used for CMEK encryption. It is required that
the kms key is in the same region as the endpoint. The same key will be
used for all provisioned resources, if encryption is available. If the
kms_key_name is left empty, no encryption will be enforced.

=back

=head2 Google::Cloud::Dialogflow::V2::EncryptionSpec::InitializeEncryptionSpecResponse

The response to initialize a location-level encryption specification.

Inherits from L<Protobuf::Message>.

=head2 Google::Cloud::Dialogflow::V2::EncryptionSpec::InitializeEncryptionSpecMetadata

Metadata for initializing a location-level encryption specification.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->request() >> / C<< $msg->request($value) >>

Type: C<Message> (L<Google::Cloud::Dialogflow::V2::EncryptionSpec::InitializeEncryptionSpecRequest>)

Output only. The original request for initialization.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Dialogflow::V2::EncryptionSpec::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
