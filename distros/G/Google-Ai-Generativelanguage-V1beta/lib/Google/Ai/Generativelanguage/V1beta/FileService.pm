package Google::Ai::Generativelanguage::V1beta::FileService;

use strict;
use warnings;

our $VERSION = '0.14';

use Protobuf::Message;
use Protobuf::DescriptorPool;
use Protobuf::Internal qw(:all);
use MIME::Base64;

BEGIN {
    eval { require Google::Ai::Generativelanguage::V1beta::File };
    eval { require Google::Api::Annotations };
    eval { require Google::Api::Client };
    eval { require Google::Api::FieldBehavior };
    eval { require Google::Api::Resource };
    eval { require Google::Protobuf::Empty };
    my $descriptor_b64 = <<'EOF';
CjZnb29nbGUvYWkvZ2VuZXJhdGl2ZWxhbmd1YWdlL3YxYmV0YS9maWxlX3NlcnZpY2UucHJv
dG8SI2dvb2dsZS5haS5nZW5lcmF0aXZlbGFuZ3VhZ2UudjFiZXRhGi5nb29nbGUvYWkvZ2Vu
ZXJhdGl2ZWxhbmd1YWdlL3YxYmV0YS9maWxlLnByb3RvGhxnb29nbGUvYXBpL2Fubm90YXRp
b25zLnByb3RvGhdnb29nbGUvYXBpL2NsaWVudC5wcm90bxofZ29vZ2xlL2FwaS9maWVsZF9i
ZWhhdmlvci5wcm90bxoZZ29vZ2xlL2FwaS9yZXNvdXJjZS5wcm90bxobZ29vZ2xlL3Byb3Rv
YnVmL2VtcHR5LnByb3RvIlcKEUNyZWF0ZUZpbGVSZXF1ZXN0EkIKBGZpbGUYASABKAsyKS5n
b29nbGUuYWkuZ2VuZXJhdGl2ZWxhbmd1YWdlLnYxYmV0YS5GaWxlQgPgQQFSBGZpbGUiUwoS
Q3JlYXRlRmlsZVJlc3BvbnNlEj0KBGZpbGUYASABKAsyKS5nb29nbGUuYWkuZ2VuZXJhdGl2
ZWxhbmd1YWdlLnYxYmV0YS5GaWxlUgRmaWxlIlgKEExpc3RGaWxlc1JlcXVlc3QSIAoJcGFn
ZV9zaXplGAEgASgFQgPgQQFSCHBhZ2VTaXplEiIKCnBhZ2VfdG9rZW4YAyABKAlCA+BBAVIJ
cGFnZVRva2VuInwKEUxpc3RGaWxlc1Jlc3BvbnNlEj8KBWZpbGVzGAEgAygLMikuZ29vZ2xl
LmFpLmdlbmVyYXRpdmVsYW5ndWFnZS52MWJldGEuRmlsZVIFZmlsZXMSJgoPbmV4dF9wYWdl
X3Rva2VuGAIgASgJUg1uZXh0UGFnZVRva2VuIlQKDkdldEZpbGVSZXF1ZXN0EkIKBG5hbWUY
ASABKAlCLuBBAvpBKAomZ2VuZXJhdGl2ZWxhbmd1YWdlLmdvb2dsZWFwaXMuY29tL0ZpbGVS
BG5hbWUiVwoRRGVsZXRlRmlsZVJlcXVlc3QSQgoEbmFtZRgBIAEoCUIu4EEC+kEoCiZnZW5l
cmF0aXZlbGFuZ3VhZ2UuZ29vZ2xlYXBpcy5jb20vRmlsZVIEbmFtZSJZChNEb3dubG9hZEZp
bGVSZXF1ZXN0EkIKBG5hbWUYASABKAlCLuBBAvpBKAomZ2VuZXJhdGl2ZWxhbmd1YWdlLmdv
b2dsZWFwaXMuY29tL0ZpbGVSBG5hbWUiFgoURG93bmxvYWRGaWxlUmVzcG9uc2UysAYKC0Zp
bGVTZXJ2aWNlEpcBCgpDcmVhdGVGaWxlEjYuZ29vZ2xlLmFpLmdlbmVyYXRpdmVsYW5ndWFn
ZS52MWJldGEuQ3JlYXRlRmlsZVJlcXVlc3QaNy5nb29nbGUuYWkuZ2VuZXJhdGl2ZWxhbmd1
YWdlLnYxYmV0YS5DcmVhdGVGaWxlUmVzcG9uc2UiGILT5JMCEiINL3YxYmV0YS9maWxlczoB
KhKRAQoJTGlzdEZpbGVzEjUuZ29vZ2xlLmFpLmdlbmVyYXRpdmVsYW5ndWFnZS52MWJldGEu
TGlzdEZpbGVzUmVxdWVzdBo2Lmdvb2dsZS5haS5nZW5lcmF0aXZlbGFuZ3VhZ2UudjFiZXRh
Lkxpc3RGaWxlc1Jlc3BvbnNlIhWC0+STAg8SDS92MWJldGEvZmlsZXMSkAEKB0dldEZpbGUS
My5nb29nbGUuYWkuZ2VuZXJhdGl2ZWxhbmd1YWdlLnYxYmV0YS5HZXRGaWxlUmVxdWVzdBop
Lmdvb2dsZS5haS5nZW5lcmF0aXZlbGFuZ3VhZ2UudjFiZXRhLkZpbGUiJYLT5JMCGBIWL3Yx
YmV0YS97bmFtZT1maWxlcy8qfdpBBG5hbWUSgwEKCkRlbGV0ZUZpbGUSNi5nb29nbGUuYWku
Z2VuZXJhdGl2ZWxhbmd1YWdlLnYxYmV0YS5EZWxldGVGaWxlUmVxdWVzdBoWLmdvb2dsZS5w
cm90b2J1Zi5FbXB0eSIlgtPkkwIYKhYvdjFiZXRhL3tuYW1lPWZpbGVzLyp92kEEbmFtZRKz
AQoMRG93bmxvYWRGaWxlEjguZ29vZ2xlLmFpLmdlbmVyYXRpdmVsYW5ndWFnZS52MWJldGEu
RG93bmxvYWRGaWxlUmVxdWVzdBo5Lmdvb2dsZS5haS5nZW5lcmF0aXZlbGFuZ3VhZ2UudjFi
ZXRhLkRvd25sb2FkRmlsZVJlc3BvbnNlIi6C0+STAiESHy92MWJldGEve25hbWU9ZmlsZXMv
Kn06ZG93bmxvYWTaQQRuYW1lGiTKQSFnZW5lcmF0aXZlbGFuZ3VhZ2UuZ29vZ2xlYXBpcy5j
b21CnAEKJ2NvbS5nb29nbGUuYWkuZ2VuZXJhdGl2ZWxhbmd1YWdlLnYxYmV0YUIQRmlsZVNl
cnZpY2VQcm90b1ABWl1jbG91ZC5nb29nbGUuY29tL2dvL2FpL2dlbmVyYXRpdmVsYW5ndWFn
ZS9hcGl2MWJldGEvZ2VuZXJhdGl2ZWxhbmd1YWdlcGI7Z2VuZXJhdGl2ZWxhbmd1YWdlcGJK
ihoKBxIFDgCPAR8KvAQKAQwSAw4AEjKxBCBDb3B5cmlnaHQgMjAyNSBHb29nbGUgTExDCgog
TGljZW5zZWQgdW5kZXIgdGhlIEFwYWNoZSBMaWNlbnNlLCBWZXJzaW9uIDIuMCAodGhlICJM
aWNlbnNlIik7CiB5b3UgbWF5IG5vdCB1c2UgdGhpcyBmaWxlIGV4Y2VwdCBpbiBjb21wbGlh
bmNlIHdpdGggdGhlIExpY2Vuc2UuCiBZb3UgbWF5IG9idGFpbiBhIGNvcHkgb2YgdGhlIExp
Y2Vuc2UgYXQKCiAgICAgaHR0cDovL3d3dy5hcGFjaGUub3JnL2xpY2Vuc2VzL0xJQ0VOU0Ut
Mi4wCgogVW5sZXNzIHJlcXVpcmVkIGJ5IGFwcGxpY2FibGUgbGF3IG9yIGFncmVlZCB0byBp
biB3cml0aW5nLCBzb2Z0d2FyZQogZGlzdHJpYnV0ZWQgdW5kZXIgdGhlIExpY2Vuc2UgaXMg
ZGlzdHJpYnV0ZWQgb24gYW4gIkFTIElTIiBCQVNJUywKIFdJVEhPVVQgV0FSUkFOVElFUyBP
UiBDT05ESVRJT05TIE9GIEFOWSBLSU5ELCBlaXRoZXIgZXhwcmVzcyBvciBpbXBsaWVkLgog
U2VlIHRoZSBMaWNlbnNlIGZvciB0aGUgc3BlY2lmaWMgbGFuZ3VhZ2UgZ292ZXJuaW5nIHBl
cm1pc3Npb25zIGFuZAogbGltaXRhdGlvbnMgdW5kZXIgdGhlIExpY2Vuc2UuCgoICgECEgMQ
ACwKCQoCAwASAxIAOAoJCgIDARIDEwAmCgkKAgMCEgMUACEKCQoCAwMSAxUAKQoJCgIDBBID
FgAjCgkKAgMFEgMXACUKCAoBCBIDGQB0CgkKAggLEgMZAHQKCAoBCBIDGgAiCgkKAggKEgMa
ACIKCAoBCBIDGwAxCgkKAggIEgMbADEKCAoBCBIDHABACgkKAggBEgMcAEAKNgoCBgASBB8A
SAEaKiBBbiBBUEkgZm9yIHVwbG9hZGluZyBhbmQgbWFuYWdpbmcgZmlsZXMuCgoKCgMGAAES
Ax8IEwoKCgMGAAMSAyACSQoMCgUGAAOZCBIDIAJJCiEKBAYAAgASBCMCKAMaEyBDcmVhdGVz
IGEgYEZpbGVgLgoKDAoFBgACAAESAyMGEAoMCgUGAAIAAhIDIxEiCgwKBQYAAgADEgMjLT8K
DQoFBgACAAQSBCQEJwYKEQoJBgACAASwyrwiEgQkBCcGCk8KBAYAAgESBCsCLwMaQSBMaXN0
cyB0aGUgbWV0YWRhdGEgZm9yIGBGaWxlYHMgb3duZWQgYnkgdGhlIHJlcXVlc3RpbmcgcHJv
amVjdC4KCgwKBQYAAgEBEgMrBg8KDAoFBgACAQISAysQIAoMCgUGAAIBAxIDKys8Cg0KBQYA
AgEEEgQsBC4GChEKCQYAAgEEsMq8IhIELAQuBgo3CgQGAAICEgQyAjcDGikgR2V0cyB0aGUg
bWV0YWRhdGEgZm9yIHRoZSBnaXZlbiBgRmlsZWAuCgoMCgUGAAICARIDMgYNCgwKBQYAAgIC
EgMyDhwKDAoFBgACAgMSAzInKwoNCgUGAAICBBIEMwQ1BgoRCgkGAAICBLDKvCISBDMENQYK
DAoFBgACAgQSAzYEMgoPCggGAAICBJsIABIDNgQyCiMKBAYAAgMSBDoCPwMaFSBEZWxldGVz
IHRoZSBgRmlsZWAuCgoMCgUGAAIDARIDOgYQCgwKBQYAAgMCEgM6ESIKDAoFBgACAwMSAzot
QgoNCgUGAAIDBBIEOwQ9BgoRCgkGAAIDBLDKvCISBDsEPQYKDAoFBgACAwQSAz4EMgoPCggG
AAIDBJsIABIDPgQyCiQKBAYAAgQSBEICRwMaFiBEb3dubG9hZCB0aGUgYEZpbGVgLgoKDAoF
BgACBAESA0IGEgoMCgUGAAIEAhIDQhMmCgwKBQYAAgQDEgNCMUUKDQoFBgACBAQSBEMERQYK
EQoJBgACBASwyrwiEgRDBEUGCgwKBQYAAgQEEgNGBDIKDwoIBgACBASbCAASA0YEMgonCgIE
ABIESwBOARobIFJlcXVlc3QgZm9yIGBDcmVhdGVGaWxlYC4KCgoKAwQAARIDSwgZCjkKBAQA
AgASA00CORosIE9wdGlvbmFsLiBNZXRhZGF0YSBmb3IgdGhlIGZpbGUgdG8gY3JlYXRlLgoK
DAoFBAACAAYSA00CBgoMCgUEAAIAARIDTQcLCgwKBQQAAgADEgNNDg8KDAoFBAACAAgSA00Q
OAoPCggEAAIACJwIABIDTRE3CigKAgQBEgRRAFQBGhwgUmVzcG9uc2UgZm9yIGBDcmVhdGVG
aWxlYC4KCgoKAwQBARIDUQgaCi0KBAQBAgASA1MCEBogIE1ldGFkYXRhIGZvciB0aGUgY3Jl
YXRlZCBmaWxlLgoKDAoFBAECAAYSA1MCBgoMCgUEAQIAARIDUwcLCgwKBQQBAgADEgNTDg8K
JgoCBAISBFcAXgEaGiBSZXF1ZXN0IGZvciBgTGlzdEZpbGVzYC4KCgoKAwQCARIDVwgYCoMB
CgQEAgIAEgNaAj8adiBPcHRpb25hbC4gTWF4aW11bSBudW1iZXIgb2YgYEZpbGVgcyB0byBy
ZXR1cm4gcGVyIHBhZ2UuCiBJZiB1bnNwZWNpZmllZCwgZGVmYXVsdHMgdG8gMTAuIE1heGlt
dW0gYHBhZ2Vfc2l6ZWAgaXMgMTAwLgoKDAoFBAICAAUSA1oCBwoMCgUEAgIAARIDWggRCgwK
BQQCAgADEgNaFBUKDAoFBAICAAgSA1oWPgoPCggEAgIACJwIABIDWhc9CkcKBAQCAgESA10C
QRo6IE9wdGlvbmFsLiBBIHBhZ2UgdG9rZW4gZnJvbSBhIHByZXZpb3VzIGBMaXN0RmlsZXNg
IGNhbGwuCgoMCgUEAgIBBRIDXQIICgwKBQQCAgEBEgNdCRMKDAoFBAICAQMSA10WFwoMCgUE
AgIBCBIDXRhACg8KCAQCAgEInAgAEgNdGT8KJwoCBAMSBGEAaAEaGyBSZXNwb25zZSBmb3Ig
YExpc3RGaWxlc2AuCgoKCgMEAwESA2EIGQojCgQEAwIAEgNjAhoaFiBUaGUgbGlzdCBvZiBg
RmlsZWBzLgoKDAoFBAMCAAQSA2MCCgoMCgUEAwIABhIDYwsPCgwKBQQDAgABEgNjEBUKDAoF
BAMCAAMSA2MYGQpeCgQEAwIBEgNnAh0aUSBBIHRva2VuIHRoYXQgY2FuIGJlIHNlbnQgYXMg
YSBgcGFnZV90b2tlbmAgaW50byBhIHN1YnNlcXVlbnQgYExpc3RGaWxlc2AKIGNhbGwuCgoM
CgUEAwIBBRIDZwIICgwKBQQDAgEBEgNnCRgKDAoFBAMCAQMSA2cbHAokCgIEBBIEawB0ARoY
IFJlcXVlc3QgZm9yIGBHZXRGaWxlYC4KCgoKAwQEARIDawgWClIKBAQEAgASBG4CcwQaRCBS
ZXF1aXJlZC4gVGhlIG5hbWUgb2YgdGhlIGBGaWxlYCB0byBnZXQuCiBFeGFtcGxlOiBgZmls
ZXMvYWJjLTEyM2AKCgwKBQQEAgAFEgNuAggKDAoFBAQCAAESA24JDQoMCgUEBAIAAxIDbhAR
Cg0KBQQEAgAIEgRuEnMDCg8KCAQEAgAInAgAEgNvBCoKDwoHBAQCAAifCBIEcARyBQooCgIE
BRIFdwCAAQEaGyBSZXF1ZXN0IGZvciBgRGVsZXRlRmlsZWAuCgoKCgMEBQESA3cIGQpVCgQE
BQIAEgR6An8EGkcgUmVxdWlyZWQuIFRoZSBuYW1lIG9mIHRoZSBgRmlsZWAgdG8gZGVsZXRl
LgogRXhhbXBsZTogYGZpbGVzL2FiYy0xMjNgCgoMCgUEBQIABRIDegIICgwKBQQFAgABEgN6
CQ0KDAoFBAUCAAMSA3oQEQoNCgUEBQIACBIEehJ/AwoPCggEBQIACJwIABIDewQqCg8KBwQF
AgAInwgSBHwEfgUKKwoCBAYSBoMBAIwBARodIFJlcXVlc3QgZm9yIGBEb3dubG9hZEZpbGVg
LgoKCwoDBAYBEgSDAQgbClkKBAQGAgASBoYBAosBBBpJIFJlcXVpcmVkLiBUaGUgbmFtZSBv
ZiB0aGUgYEZpbGVgIHRvIGRvd25sb2FkLgogRXhhbXBsZTogYGZpbGVzL2FiYy0xMjNgCgoN
CgUEBgIABRIEhgECCAoNCgUEBgIAARIEhgEJDQoNCgUEBgIAAxIEhgEQEQoPCgUEBgIACBIG
hgESiwEDChAKCAQGAgAInAgAEgSHAQQqChEKBwQGAgAInwgSBogBBIoBBQoqCgIEBxIEjwEA
HxoeIFJlc3BvbnNlIGZvciBgRG93bmxvYWRGaWxlYC4KCgsKAwQHARIEjwEIHGIGcHJvdG8z

EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Ai::Generativelanguage::V1beta::FileService::CreateFileRequest ===
    # Fields for CreateFileRequest
    # Field: file Type: 11 (.google.ai.generativelanguage.v1beta.File)

# === Message: Google::Ai::Generativelanguage::V1beta::FileService::CreateFileResponse ===
    # Fields for CreateFileResponse
    # Field: file Type: 11 (.google.ai.generativelanguage.v1beta.File)

# === Message: Google::Ai::Generativelanguage::V1beta::FileService::ListFilesRequest ===
    # Fields for ListFilesRequest
    # Field: page_size Type: 5 ()
    # Field: page_token Type: 9 ()

# === Message: Google::Ai::Generativelanguage::V1beta::FileService::ListFilesResponse ===
    # Fields for ListFilesResponse
    # Field: files Type: 11 (.google.ai.generativelanguage.v1beta.File)
    # Field: next_page_token Type: 9 ()

# === Message: Google::Ai::Generativelanguage::V1beta::FileService::GetFileRequest ===
    # Fields for GetFileRequest
    # Field: name Type: 9 ()

# === Message: Google::Ai::Generativelanguage::V1beta::FileService::DeleteFileRequest ===
    # Fields for DeleteFileRequest
    # Field: name Type: 9 ()

# === Message: Google::Ai::Generativelanguage::V1beta::FileService::DownloadFileRequest ===
    # Fields for DownloadFileRequest
    # Field: name Type: 9 ()

# === Message: Google::Ai::Generativelanguage::V1beta::FileService::DownloadFileResponse ===
    # Fields for DownloadFileResponse

# === Service Client: Google::Ai::Generativelanguage::V1beta::FileService::FileServiceClient ===
package Google::Ai::Generativelanguage::V1beta::FileService::FileServiceClient;

=pod

=head2 Service Client: Google::Ai::Generativelanguage::V1beta::FileService::FileServiceClient

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
        ? Google::Ai::Generativelanguage::V1beta::FileService::CreateFileRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.ai.generativelanguage.v1beta.FileService',
        method         => 'CreateFile',
        request        => $req,
        response_class => 'Google::Ai::Generativelanguage::V1beta::FileService::CreateFileResponse',
    });
}

sub list_files {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Ai::Generativelanguage::V1beta::FileService::ListFilesRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.ai.generativelanguage.v1beta.FileService',
        method         => 'ListFiles',
        request        => $req,
        response_class => 'Google::Ai::Generativelanguage::V1beta::FileService::ListFilesResponse',
    });
}

sub get_file {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Ai::Generativelanguage::V1beta::FileService::GetFileRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.ai.generativelanguage.v1beta.FileService',
        method         => 'GetFile',
        request        => $req,
        response_class => 'Google::Ai::Generativelanguage::V1beta::File::File',
    });
}

sub delete_file {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Ai::Generativelanguage::V1beta::FileService::DeleteFileRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.ai.generativelanguage.v1beta.FileService',
        method         => 'DeleteFile',
        request        => $req,
        response_class => 'Google::Protobuf::Empty::Empty',
    });
}

sub download_file {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Ai::Generativelanguage::V1beta::FileService::DownloadFileRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.ai.generativelanguage.v1beta.FileService',
        method         => 'DownloadFile',
        request        => $req,
        response_class => 'Google::Ai::Generativelanguage::V1beta::FileService::DownloadFileResponse',
    });
}

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Ai::Generativelanguage::V1beta::FileService - Compiled Protocol Buffers messages for google/ai/generativelanguage/v1beta/file_service.proto

=head1 SYNOPSIS

    use Google::Ai::Generativelanguage::V1beta::FileService;

    my $msg = Google::Ai::Generativelanguage::V1beta::FileService::CreateFileRequest->new({
        file => $file,
    });

    # Read or update a field
    my $val = $msg->file();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Ai::Generativelanguage::V1beta::FileService::CreateFileRequest->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/ai/generativelanguage/v1beta/file_service.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Ai::Generativelanguage::V1beta::FileService::CreateFileRequest

Request for `CreateFile`.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->file() >> / C<< $msg->file($value) >>

Type: C<Message> (L<Google::Ai::Generativelanguage::V1beta::File::File>)

Optional. Metadata for the file to create.

=back

=head2 Google::Ai::Generativelanguage::V1beta::FileService::CreateFileResponse

Response for `CreateFile`.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->file() >> / C<< $msg->file($value) >>

Type: C<Message> (L<Google::Ai::Generativelanguage::V1beta::File::File>)

Metadata for the created file.

=back

=head2 Google::Ai::Generativelanguage::V1beta::FileService::ListFilesRequest

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

=head2 Google::Ai::Generativelanguage::V1beta::FileService::ListFilesResponse

Response for `ListFiles`.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->files() >> / C<< $msg->files($value) >>

Type: C<Message> (L<Google::Ai::Generativelanguage::V1beta::File::File>)

The list of `File`s.

=item * C<< $msg->next_page_token() >> / C<< $msg->next_page_token($value) >>

Type: C<String>

A token that can be sent as a `page_token` into a subsequent `ListFiles`
call.

=back

=head2 Google::Ai::Generativelanguage::V1beta::FileService::GetFileRequest

Request for `GetFile`.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. The name of the `File` to get.
Example: `files/abc-123`

=back

=head2 Google::Ai::Generativelanguage::V1beta::FileService::DeleteFileRequest

Request for `DeleteFile`.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. The name of the `File` to delete.
Example: `files/abc-123`

=back

=head2 Google::Ai::Generativelanguage::V1beta::FileService::DownloadFileRequest

Request for `DownloadFile`.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. The name of the `File` to download.
Example: `files/abc-123`

=back

=head2 Google::Ai::Generativelanguage::V1beta::FileService::DownloadFileResponse

Response for `DownloadFile`.

Inherits from L<Protobuf::Message>.

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Ai::Generativelanguage::V1beta::FileService::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
