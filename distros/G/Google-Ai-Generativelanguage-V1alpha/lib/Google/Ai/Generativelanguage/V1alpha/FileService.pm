package Google::Ai::Generativelanguage::V1alpha::FileService;

use strict;
use warnings;

our $VERSION = '0.14';

use Protobuf::Message;
use Protobuf::DescriptorPool;
use Protobuf::Internal qw(:all);
use MIME::Base64;

BEGIN {
    eval { require Google::Ai::Generativelanguage::V1alpha::File };
    eval { require Google::Api::Annotations };
    eval { require Google::Api::Client };
    eval { require Google::Api::FieldBehavior };
    eval { require Google::Api::Resource };
    eval { require Google::Protobuf::Empty };
    my $descriptor_b64 = <<'EOF';
Cjdnb29nbGUvYWkvZ2VuZXJhdGl2ZWxhbmd1YWdlL3YxYWxwaGEvZmlsZV9zZXJ2aWNlLnBy
b3RvEiRnb29nbGUuYWkuZ2VuZXJhdGl2ZWxhbmd1YWdlLnYxYWxwaGEaL2dvb2dsZS9haS9n
ZW5lcmF0aXZlbGFuZ3VhZ2UvdjFhbHBoYS9maWxlLnByb3RvGhxnb29nbGUvYXBpL2Fubm90
YXRpb25zLnByb3RvGhdnb29nbGUvYXBpL2NsaWVudC5wcm90bxofZ29vZ2xlL2FwaS9maWVs
ZF9iZWhhdmlvci5wcm90bxoZZ29vZ2xlL2FwaS9yZXNvdXJjZS5wcm90bxobZ29vZ2xlL3By
b3RvYnVmL2VtcHR5LnByb3RvIlgKEUNyZWF0ZUZpbGVSZXF1ZXN0EkMKBGZpbGUYASABKAsy
Ki5nb29nbGUuYWkuZ2VuZXJhdGl2ZWxhbmd1YWdlLnYxYWxwaGEuRmlsZUID4EEBUgRmaWxl
IlQKEkNyZWF0ZUZpbGVSZXNwb25zZRI+CgRmaWxlGAEgASgLMiouZ29vZ2xlLmFpLmdlbmVy
YXRpdmVsYW5ndWFnZS52MWFscGhhLkZpbGVSBGZpbGUiWAoQTGlzdEZpbGVzUmVxdWVzdBIg
CglwYWdlX3NpemUYASABKAVCA+BBAVIIcGFnZVNpemUSIgoKcGFnZV90b2tlbhgDIAEoCUID
4EEBUglwYWdlVG9rZW4ifQoRTGlzdEZpbGVzUmVzcG9uc2USQAoFZmlsZXMYASADKAsyKi5n
b29nbGUuYWkuZ2VuZXJhdGl2ZWxhbmd1YWdlLnYxYWxwaGEuRmlsZVIFZmlsZXMSJgoPbmV4
dF9wYWdlX3Rva2VuGAIgASgJUg1uZXh0UGFnZVRva2VuIlQKDkdldEZpbGVSZXF1ZXN0EkIK
BG5hbWUYASABKAlCLuBBAvpBKAomZ2VuZXJhdGl2ZWxhbmd1YWdlLmdvb2dsZWFwaXMuY29t
L0ZpbGVSBG5hbWUiVwoRRGVsZXRlRmlsZVJlcXVlc3QSQgoEbmFtZRgBIAEoCUIu4EEC+kEo
CiZnZW5lcmF0aXZlbGFuZ3VhZ2UuZ29vZ2xlYXBpcy5jb20vRmlsZVIEbmFtZTKFBQoLRmls
ZVNlcnZpY2USmgEKCkNyZWF0ZUZpbGUSNy5nb29nbGUuYWkuZ2VuZXJhdGl2ZWxhbmd1YWdl
LnYxYWxwaGEuQ3JlYXRlRmlsZVJlcXVlc3QaOC5nb29nbGUuYWkuZ2VuZXJhdGl2ZWxhbmd1
YWdlLnYxYWxwaGEuQ3JlYXRlRmlsZVJlc3BvbnNlIhmC0+STAhMiDi92MWFscGhhL2ZpbGVz
OgEqEpQBCglMaXN0RmlsZXMSNi5nb29nbGUuYWkuZ2VuZXJhdGl2ZWxhbmd1YWdlLnYxYWxw
aGEuTGlzdEZpbGVzUmVxdWVzdBo3Lmdvb2dsZS5haS5nZW5lcmF0aXZlbGFuZ3VhZ2UudjFh
bHBoYS5MaXN0RmlsZXNSZXNwb25zZSIWgtPkkwIQEg4vdjFhbHBoYS9maWxlcxKTAQoHR2V0
RmlsZRI0Lmdvb2dsZS5haS5nZW5lcmF0aXZlbGFuZ3VhZ2UudjFhbHBoYS5HZXRGaWxlUmVx
dWVzdBoqLmdvb2dsZS5haS5nZW5lcmF0aXZlbGFuZ3VhZ2UudjFhbHBoYS5GaWxlIiaC0+ST
AhkSFy92MWFscGhhL3tuYW1lPWZpbGVzLyp92kEEbmFtZRKFAQoKRGVsZXRlRmlsZRI3Lmdv
b2dsZS5haS5nZW5lcmF0aXZlbGFuZ3VhZ2UudjFhbHBoYS5EZWxldGVGaWxlUmVxdWVzdBoW
Lmdvb2dsZS5wcm90b2J1Zi5FbXB0eSImgtPkkwIZKhcvdjFhbHBoYS97bmFtZT1maWxlcy8q
fdpBBG5hbWUaJMpBIWdlbmVyYXRpdmVsYW5ndWFnZS5nb29nbGVhcGlzLmNvbUKeAQooY29t
Lmdvb2dsZS5haS5nZW5lcmF0aXZlbGFuZ3VhZ2UudjFhbHBoYUIQRmlsZVNlcnZpY2VQcm90
b1ABWl5jbG91ZC5nb29nbGUuY29tL2dvL2FpL2dlbmVyYXRpdmVsYW5ndWFnZS9hcGl2MWFs
cGhhL2dlbmVyYXRpdmVsYW5ndWFnZXBiO2dlbmVyYXRpdmVsYW5ndWFnZXBiSsYWCgYSBA4A
eAEKvAQKAQwSAw4AEjKxBCBDb3B5cmlnaHQgMjAyNSBHb29nbGUgTExDCgogTGljZW5zZWQg
dW5kZXIgdGhlIEFwYWNoZSBMaWNlbnNlLCBWZXJzaW9uIDIuMCAodGhlICJMaWNlbnNlIik7
CiB5b3UgbWF5IG5vdCB1c2UgdGhpcyBmaWxlIGV4Y2VwdCBpbiBjb21wbGlhbmNlIHdpdGgg
dGhlIExpY2Vuc2UuCiBZb3UgbWF5IG9idGFpbiBhIGNvcHkgb2YgdGhlIExpY2Vuc2UgYXQK
CiAgICAgaHR0cDovL3d3dy5hcGFjaGUub3JnL2xpY2Vuc2VzL0xJQ0VOU0UtMi4wCgogVW5s
ZXNzIHJlcXVpcmVkIGJ5IGFwcGxpY2FibGUgbGF3IG9yIGFncmVlZCB0byBpbiB3cml0aW5n
LCBzb2Z0d2FyZQogZGlzdHJpYnV0ZWQgdW5kZXIgdGhlIExpY2Vuc2UgaXMgZGlzdHJpYnV0
ZWQgb24gYW4gIkFTIElTIiBCQVNJUywKIFdJVEhPVVQgV0FSUkFOVElFUyBPUiBDT05ESVRJ
T05TIE9GIEFOWSBLSU5ELCBlaXRoZXIgZXhwcmVzcyBvciBpbXBsaWVkLgogU2VlIHRoZSBM
aWNlbnNlIGZvciB0aGUgc3BlY2lmaWMgbGFuZ3VhZ2UgZ292ZXJuaW5nIHBlcm1pc3Npb25z
IGFuZAogbGltaXRhdGlvbnMgdW5kZXIgdGhlIExpY2Vuc2UuCgoICgECEgMQAC0KCQoCAwAS
AxIAOQoJCgIDARIDEwAmCgkKAgMCEgMUACEKCQoCAwMSAxUAKQoJCgIDBBIDFgAjCgkKAgMF
EgMXACUKCAoBCBIDGQB1CgkKAggLEgMZAHUKCAoBCBIDGgAiCgkKAggKEgMaACIKCAoBCBID
GwAxCgkKAggIEgMbADEKCAoBCBIDHABBCgkKAggBEgMcAEEKNgoCBgASBB8AQAEaKiBBbiBB
UEkgZm9yIHVwbG9hZGluZyBhbmQgbWFuYWdpbmcgZmlsZXMuCgoKCgMGAAESAx8IEwoKCgMG
AAMSAyACSQoMCgUGAAOZCBIDIAJJCiEKBAYAAgASBCMCKAMaEyBDcmVhdGVzIGEgYEZpbGVg
LgoKDAoFBgACAAESAyMGEAoMCgUGAAIAAhIDIxEiCgwKBQYAAgADEgMjLT8KDQoFBgACAAQS
BCQEJwYKEQoJBgACAASwyrwiEgQkBCcGCk8KBAYAAgESBCsCLwMaQSBMaXN0cyB0aGUgbWV0
YWRhdGEgZm9yIGBGaWxlYHMgb3duZWQgYnkgdGhlIHJlcXVlc3RpbmcgcHJvamVjdC4KCgwK
BQYAAgEBEgMrBg8KDAoFBgACAQISAysQIAoMCgUGAAIBAxIDKys8Cg0KBQYAAgEEEgQsBC4G
ChEKCQYAAgEEsMq8IhIELAQuBgo3CgQGAAICEgQyAjcDGikgR2V0cyB0aGUgbWV0YWRhdGEg
Zm9yIHRoZSBnaXZlbiBgRmlsZWAuCgoMCgUGAAICARIDMgYNCgwKBQYAAgICEgMyDhwKDAoF
BgACAgMSAzInKwoNCgUGAAICBBIEMwQ1BgoRCgkGAAICBLDKvCISBDMENQYKDAoFBgACAgQS
AzYEMgoPCggGAAICBJsIABIDNgQyCiMKBAYAAgMSBDoCPwMaFSBEZWxldGVzIHRoZSBgRmls
ZWAuCgoMCgUGAAIDARIDOgYQCgwKBQYAAgMCEgM6ESIKDAoFBgACAwMSAzotQgoNCgUGAAID
BBIEOwQ9BgoRCgkGAAIDBLDKvCISBDsEPQYKDAoFBgACAwQSAz4EMgoPCggGAAIDBJsIABID
PgQyCicKAgQAEgRDAEYBGhsgUmVxdWVzdCBmb3IgYENyZWF0ZUZpbGVgLgoKCgoDBAABEgND
CBkKOQoEBAACABIDRQI5GiwgT3B0aW9uYWwuIE1ldGFkYXRhIGZvciB0aGUgZmlsZSB0byBj
cmVhdGUuCgoMCgUEAAIABhIDRQIGCgwKBQQAAgABEgNFBwsKDAoFBAACAAMSA0UODwoMCgUE
AAIACBIDRRA4Cg8KCAQAAgAInAgAEgNFETcKKAoCBAESBEkATAEaHCBSZXNwb25zZSBmb3Ig
YENyZWF0ZUZpbGVgLgoKCgoDBAEBEgNJCBoKLQoEBAECABIDSwIQGiAgTWV0YWRhdGEgZm9y
IHRoZSBjcmVhdGVkIGZpbGUuCgoMCgUEAQIABhIDSwIGCgwKBQQBAgABEgNLBwsKDAoFBAEC
AAMSA0sODwomCgIEAhIETwBWARoaIFJlcXVlc3QgZm9yIGBMaXN0RmlsZXNgLgoKCgoDBAIB
EgNPCBgKgwEKBAQCAgASA1ICPxp2IE9wdGlvbmFsLiBNYXhpbXVtIG51bWJlciBvZiBgRmls
ZWBzIHRvIHJldHVybiBwZXIgcGFnZS4KIElmIHVuc3BlY2lmaWVkLCBkZWZhdWx0cyB0byAx
MC4gTWF4aW11bSBgcGFnZV9zaXplYCBpcyAxMDAuCgoMCgUEAgIABRIDUgIHCgwKBQQCAgAB
EgNSCBEKDAoFBAICAAMSA1IUFQoMCgUEAgIACBIDUhY+Cg8KCAQCAgAInAgAEgNSFz0KRwoE
BAICARIDVQJBGjogT3B0aW9uYWwuIEEgcGFnZSB0b2tlbiBmcm9tIGEgcHJldmlvdXMgYExp
c3RGaWxlc2AgY2FsbC4KCgwKBQQCAgEFEgNVAggKDAoFBAICAQESA1UJEwoMCgUEAgIBAxID
VRYXCgwKBQQCAgEIEgNVGEAKDwoIBAICAQicCAASA1UZPwonCgIEAxIEWQBgARobIFJlc3Bv
bnNlIGZvciBgTGlzdEZpbGVzYC4KCgoKAwQDARIDWQgZCiMKBAQDAgASA1sCGhoWIFRoZSBs
aXN0IG9mIGBGaWxlYHMuCgoMCgUEAwIABBIDWwIKCgwKBQQDAgAGEgNbCw8KDAoFBAMCAAES
A1sQFQoMCgUEAwIAAxIDWxgZCl4KBAQDAgESA18CHRpRIEEgdG9rZW4gdGhhdCBjYW4gYmUg
c2VudCBhcyBhIGBwYWdlX3Rva2VuYCBpbnRvIGEgc3Vic2VxdWVudCBgTGlzdEZpbGVzYAog
Y2FsbC4KCgwKBQQDAgEFEgNfAggKDAoFBAMCAQESA18JGAoMCgUEAwIBAxIDXxscCiQKAgQE
EgRjAGwBGhggUmVxdWVzdCBmb3IgYEdldEZpbGVgLgoKCgoDBAQBEgNjCBYKUgoEBAQCABIE
ZgJrBBpEIFJlcXVpcmVkLiBUaGUgbmFtZSBvZiB0aGUgYEZpbGVgIHRvIGdldC4KIEV4YW1w
bGU6IGBmaWxlcy9hYmMtMTIzYAoKDAoFBAQCAAUSA2YCCAoMCgUEBAIAARIDZgkNCgwKBQQE
AgADEgNmEBEKDQoFBAQCAAgSBGYSawMKDwoIBAQCAAicCAASA2cEKgoPCgcEBAIACJ8IEgRo
BGoFCicKAgQFEgRvAHgBGhsgUmVxdWVzdCBmb3IgYERlbGV0ZUZpbGVgLgoKCgoDBAUBEgNv
CBkKVQoEBAUCABIEcgJ3BBpHIFJlcXVpcmVkLiBUaGUgbmFtZSBvZiB0aGUgYEZpbGVgIHRv
IGRlbGV0ZS4KIEV4YW1wbGU6IGBmaWxlcy9hYmMtMTIzYAoKDAoFBAUCAAUSA3ICCAoMCgUE
BQIAARIDcgkNCgwKBQQFAgADEgNyEBEKDQoFBAUCAAgSBHISdwMKDwoIBAUCAAicCAASA3ME
KgoPCgcEBQIACJ8IEgR0BHYFYgZwcm90bzM=
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Ai::Generativelanguage::V1alpha::FileService::CreateFileRequest ===
    # Fields for CreateFileRequest
    # Field: file Type: 11 (.google.ai.generativelanguage.v1alpha.File)

# === Message: Google::Ai::Generativelanguage::V1alpha::FileService::CreateFileResponse ===
    # Fields for CreateFileResponse
    # Field: file Type: 11 (.google.ai.generativelanguage.v1alpha.File)

# === Message: Google::Ai::Generativelanguage::V1alpha::FileService::ListFilesRequest ===
    # Fields for ListFilesRequest
    # Field: page_size Type: 5 ()
    # Field: page_token Type: 9 ()

# === Message: Google::Ai::Generativelanguage::V1alpha::FileService::ListFilesResponse ===
    # Fields for ListFilesResponse
    # Field: files Type: 11 (.google.ai.generativelanguage.v1alpha.File)
    # Field: next_page_token Type: 9 ()

# === Message: Google::Ai::Generativelanguage::V1alpha::FileService::GetFileRequest ===
    # Fields for GetFileRequest
    # Field: name Type: 9 ()

# === Message: Google::Ai::Generativelanguage::V1alpha::FileService::DeleteFileRequest ===
    # Fields for DeleteFileRequest
    # Field: name Type: 9 ()

# === Service Client: Google::Ai::Generativelanguage::V1alpha::FileService::FileServiceClient ===
package Google::Ai::Generativelanguage::V1alpha::FileService::FileServiceClient;

=pod

=head2 Service Client: Google::Ai::Generativelanguage::V1alpha::FileService::FileServiceClient

Client stub representing the remote C<FileService> gRPC service. Delegates call dispatching to L<Google::gRPC::Client>.

=head3 target

The endpoint target address. Defaults to C<ai.googleapis.com:443>.

=head3 credentials

The authentication credentials provider. Defaults to application default credentials via L<Google::Auth>.

=cut

use Moo;
use Google::Auth;
use Google::gRPC::Client;

has credentials => ( is => 'ro', default => sub { Google::Auth->default() } );
has target      => ( is => 'ro', default => 'ai.googleapis.com:443' );

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

sub create_file {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Ai::Generativelanguage::V1alpha::FileService::CreateFileRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.ai.generativelanguage.v1alpha.FileService',
        method         => 'CreateFile',
        request        => $req,
        response_class => 'Google::Ai::Generativelanguage::V1alpha::FileService::CreateFileResponse',
    });
}

sub list_files {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Ai::Generativelanguage::V1alpha::FileService::ListFilesRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.ai.generativelanguage.v1alpha.FileService',
        method         => 'ListFiles',
        request        => $req,
        response_class => 'Google::Ai::Generativelanguage::V1alpha::FileService::ListFilesResponse',
    });
}

sub get_file {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Ai::Generativelanguage::V1alpha::FileService::GetFileRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.ai.generativelanguage.v1alpha.FileService',
        method         => 'GetFile',
        request        => $req,
        response_class => 'Google::Ai::Generativelanguage::V1alpha::File::File',
    });
}

sub delete_file {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Ai::Generativelanguage::V1alpha::FileService::DeleteFileRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.ai.generativelanguage.v1alpha.FileService',
        method         => 'DeleteFile',
        request        => $req,
        response_class => 'Google::Protobuf::Empty::Empty',
    });
}

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Ai::Generativelanguage::V1alpha::FileService - Compiled Protocol Buffers messages for google/ai/generativelanguage/v1alpha/file_service.proto

=head1 SYNOPSIS

    use Google::Ai::Generativelanguage::V1alpha::FileService;

    my $msg = Google::Ai::Generativelanguage::V1alpha::FileService::CreateFileRequest->new({
        file => $file,
    });

    # Read or update a field
    my $val = $msg->file();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Ai::Generativelanguage::V1alpha::FileService::CreateFileRequest->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/ai/generativelanguage/v1alpha/file_service.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Ai::Generativelanguage::V1alpha::FileService::CreateFileRequest

Request for `CreateFile`.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->file() >> / C<< $msg->file($value) >>

Type: C<Message> (L<Google::Ai::Generativelanguage::V1alpha::File::File>)

Optional. Metadata for the file to create.

=back

=head2 Google::Ai::Generativelanguage::V1alpha::FileService::CreateFileResponse

Response for `CreateFile`.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->file() >> / C<< $msg->file($value) >>

Type: C<Message> (L<Google::Ai::Generativelanguage::V1alpha::File::File>)

Metadata for the created file.

=back

=head2 Google::Ai::Generativelanguage::V1alpha::FileService::ListFilesRequest

Request for `ListFiles`.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->page_size() >> / C<< $msg->page_size($value) >>

Type: C<Int32>

Optional. Maximum number of `File`s to return per page.
If unspecified, defaults to 10. Maximum `page_size` is 100.

=item * C<< $msg->page_token() >> / C<< $msg->page_token($value) >>

Type: C<String>

Optional. A page token from a previous `ListFiles` call.

=back

=head2 Google::Ai::Generativelanguage::V1alpha::FileService::ListFilesResponse

Response for `ListFiles`.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->files() >> / C<< $msg->files($value) >>

Type: C<Message> (L<Google::Ai::Generativelanguage::V1alpha::File::File>)

The list of `File`s.

=item * C<< $msg->next_page_token() >> / C<< $msg->next_page_token($value) >>

Type: C<String>

A token that can be sent as a `page_token` into a subsequent `ListFiles`
call.

=back

=head2 Google::Ai::Generativelanguage::V1alpha::FileService::GetFileRequest

Request for `GetFile`.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. The name of the `File` to get.
Example: `files/abc-123`

=back

=head2 Google::Ai::Generativelanguage::V1alpha::FileService::DeleteFileRequest

Request for `DeleteFile`.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. The name of the `File` to delete.
Example: `files/abc-123`

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Ai::Generativelanguage::V1alpha::FileService::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
