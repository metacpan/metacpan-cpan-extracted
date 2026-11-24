package Google::Devtools::Resultstore::V2::ResultstoreFileDownload;

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
    my $descriptor_b64 = <<'EOF';
Cj5nb29nbGUvZGV2dG9vbHMvcmVzdWx0c3RvcmUvdjIvcmVzdWx0c3RvcmVfZmlsZV9kb3du
bG9hZC5wcm90bxIeZ29vZ2xlLmRldnRvb2xzLnJlc3VsdHN0b3JlLnYyGhxnb29nbGUvYXBp
L2Fubm90YXRpb25zLnByb3RvGhdnb29nbGUvYXBpL2NsaWVudC5wcm90byKHAQoOR2V0Rmls
ZVJlcXVlc3QSEAoDdXJpGAEgASgJUgN1cmkSHwoLcmVhZF9vZmZzZXQYAiABKANSCnJlYWRP
ZmZzZXQSHQoKcmVhZF9saW1pdBgDIAEoA1IJcmVhZExpbWl0EiMKDWFyY2hpdmVfZW50cnkY
BCABKAlSDGFyY2hpdmVFbnRyeSIlCg9HZXRGaWxlUmVzcG9uc2USEgoEZGF0YRgBIAEoDFIE
ZGF0YSKLAQoSR2V0RmlsZVRhaWxSZXF1ZXN0EhAKA3VyaRgBIAEoCVIDdXJpEh8KC3JlYWRf
b2Zmc2V0GAIgASgDUgpyZWFkT2Zmc2V0Eh0KCnJlYWRfbGltaXQYAyABKANSCXJlYWRMaW1p
dBIjCg1hcmNoaXZlX2VudHJ5GAQgASgJUgxhcmNoaXZlRW50cnkiKQoTR2V0RmlsZVRhaWxS
ZXNwb25zZRISCgRkYXRhGAEgASgMUgRkYXRhMooDChdSZXN1bHRTdG9yZUZpbGVEb3dubG9h
ZBKGAQoHR2V0RmlsZRIuLmdvb2dsZS5kZXZ0b29scy5yZXN1bHRzdG9yZS52Mi5HZXRGaWxl
UmVxdWVzdBovLmdvb2dsZS5kZXZ0b29scy5yZXN1bHRzdG9yZS52Mi5HZXRGaWxlUmVzcG9u
c2UiGILT5JMCEhIQL3YyL3t1cmk9ZmlsZS8qfTABEpUBCgtHZXRGaWxlVGFpbBIyLmdvb2ds
ZS5kZXZ0b29scy5yZXN1bHRzdG9yZS52Mi5HZXRGaWxlVGFpbFJlcXVlc3QaMy5nb29nbGUu
ZGV2dG9vbHMucmVzdWx0c3RvcmUudjIuR2V0RmlsZVRhaWxSZXNwb25zZSIdgtPkkwIXEhUv
djIve3VyaT1maWxlL3RhaWwvKn0aTspBGnJlc3VsdHN0b3JlLmdvb2dsZWFwaXMuY29t0kEu
aHR0cHM6Ly93d3cuZ29vZ2xlYXBpcy5jb20vYXV0aC9jbG91ZC1wbGF0Zm9ybUKPAQoiY29t
Lmdvb2dsZS5kZXZ0b29scy5yZXN1bHRzdG9yZS52MkIcUmVzdWx0U3RvcmVGaWxlRG93bmxv
YWRQcm90b1ABWklnb29nbGUuZ29sYW5nLm9yZy9nZW5wcm90by9nb29nbGVhcGlzL2RldnRv
b2xzL3Jlc3VsdHN0b3JlL3YyO3Jlc3VsdHN0b3JlStghCgYSBA4AfwEKvAQKAQwSAw4AEjKx
BCBDb3B5cmlnaHQgMjAyNSBHb29nbGUgTExDCgogTGljZW5zZWQgdW5kZXIgdGhlIEFwYWNo
ZSBMaWNlbnNlLCBWZXJzaW9uIDIuMCAodGhlICJMaWNlbnNlIik7CiB5b3UgbWF5IG5vdCB1
c2UgdGhpcyBmaWxlIGV4Y2VwdCBpbiBjb21wbGlhbmNlIHdpdGggdGhlIExpY2Vuc2UuCiBZ
b3UgbWF5IG9idGFpbiBhIGNvcHkgb2YgdGhlIExpY2Vuc2UgYXQKCiAgICAgaHR0cDovL3d3
dy5hcGFjaGUub3JnL2xpY2Vuc2VzL0xJQ0VOU0UtMi4wCgogVW5sZXNzIHJlcXVpcmVkIGJ5
IGFwcGxpY2FibGUgbGF3IG9yIGFncmVlZCB0byBpbiB3cml0aW5nLCBzb2Z0d2FyZQogZGlz
dHJpYnV0ZWQgdW5kZXIgdGhlIExpY2Vuc2UgaXMgZGlzdHJpYnV0ZWQgb24gYW4gIkFTIElT
IiBCQVNJUywKIFdJVEhPVVQgV0FSUkFOVElFUyBPUiBDT05ESVRJT05TIE9GIEFOWSBLSU5E
LCBlaXRoZXIgZXhwcmVzcyBvciBpbXBsaWVkLgogU2VlIHRoZSBMaWNlbnNlIGZvciB0aGUg
c3BlY2lmaWMgbGFuZ3VhZ2UgZ292ZXJuaW5nIHBlcm1pc3Npb25zIGFuZAogbGltaXRhdGlv
bnMgdW5kZXIgdGhlIExpY2Vuc2UuCgoICgECEgMQACcKCQoCAwASAxIAJgoJCgIDARIDEwAh
CggKAQgSAxUAYAoJCgIICxIDFQBgCggKAQgSAxYAIgoJCgIIChIDFgAiCggKAQgSAxcAPQoJ
CgIICBIDFwA9CggKAQgSAxgAOwoJCgIIARIDGAA7Cl0KAgYAEgQcADcBGlEgVGhpcyBBUEkg
YWxsb3dzIGRvd25sb2FkIG9mIEZpbGUgbWVzc2FnZXMgcmVmZXJlbmNlZCBpbgogUmVzdWx0
U3RvcmUgcmVzb3VyY2VzLgoKCgoDBgABEgMcCB8KCgoDBgADEgMdAkIKDAoFBgADmQgSAx0C
QgoLCgMGAAMSBB4CHzcKDQoFBgADmggSBB4CHzcK8gEKBAYAAgASBCcCKwMa4wEgUmV0cmll
dmVzIHRoZSBGaWxlIHdpdGggdGhlIGdpdmVuIHVyaS4KIHJldHVybnMgYSBzdHJlYW0gb2Yg
Ynl0ZXMgdG8gYmUgc3RpdGNoZWQgdG9nZXRoZXIgaW4gb3JkZXIuCgogQW4gZXJyb3Igd2ls
bCBiZSByZXBvcnRlZCBpbiB0aGUgZm9sbG93aW5nIGNhc2VzOgogLSBJZiB0aGUgRmlsZSBp
cyBub3QgZm91bmQuCiAtIElmIHRoZSBnaXZlbiBGaWxlIHVyaSBpcyBiYWRseSBmb3JtYXR0
ZWQuCgoMCgUGAAIAARIDJwYNCgwKBQYAAgACEgMnDhwKDAoFBgACAAYSAycnLQoMCgUGAAIA
AxIDJy49Cg0KBQYAAgAEEgQoBCoGChEKCQYAAgAEsMq8IhIEKAQqBgq/AQoEBgACARIEMgI2
AxqwASBSZXRyaWV2ZXMgdGhlIHRhaWwgb2YgYSBGaWxlIHdpdGggdGhlIGdpdmVuIHVyaS4K
CiBBbiBlcnJvciB3aWxsIGJlIHJlcG9ydGVkIGluIHRoZSBmb2xsb3dpbmcgY2FzZXM6CiAt
IElmIHRoZSBGaWxlIGlzIG5vdCBmb3VuZC4KIC0gSWYgdGhlIGdpdmVuIEZpbGUgdXJpIGlz
IGJhZGx5IGZvcm1hdHRlZC4KCgwKBQYAAgEBEgMyBhEKDAoFBgACAQISAzISJAoMCgUGAAIB
AxIDMi9CCg0KBQYAAgEEEgQzBDUGChEKCQYAAgEEsMq8IhIEMwQ1BgooCgIEABIEOgBWARoc
IFJlcXVlc3Qgb2JqZWN0IGZvciBHZXRGaWxlCgoKCgMEAAESAzoIFgqQAgoEBAACABIDQAIR
GoICIFRoaXMgY29ycmVzcG9uZHMgdG8gdGhlIHVyaSBmaWVsZCBpbiB0aGUgRmlsZSBtZXNz
YWdlOiBmb3IgYW4gb2JmdXNjYXRlZAogRmlsZS51cmkgbGlrZQogQ2dsaWRXbHNaQzVzYjJj
U0pESTNZbUk1WldReExUVmpZekV0TkdGbE5pMWlNV1JrTFRWbE9EWTBZV0V6WW1FMlpRLCB0
aGUKIHZhbHVlIGhlcmUgc2hvdWxkIGJlCiBmaWxlcy9DZ2xpZFdsc1pDNXNiMmNTSkRJM1lt
STVaV1F4TFRWall6RXROR0ZsTmkxaU1XUmtMVFZsT0RZMFlXRXpZbUUyWlEKCgwKBQQAAgAF
EgNAAggKDAoFBAACAAESA0AJDAoMCgUEAAIAAxIDQA8QCt0BCgQEAAIBEgNHAhgazwEgVGhl
IG9mZnNldCBmb3IgdGhlIGZpcnN0IGJ5dGUgdG8gcmV0dXJuIGluIHRoZSByZWFkLCByZWxh
dGl2ZSB0byB0aGUgc3RhcnQKIG9mIHRoZSByZXNvdXJjZS4KCiBBIGByZWFkX29mZnNldGAg
dGhhdCBpcyBuZWdhdGl2ZSBvciBncmVhdGVyIHRoYW4gdGhlIHNpemUgb2YgdGhlIHJlc291
cmNlCiB3aWxsIGNhdXNlIGFuIGBPVVRfT0ZfUkFOR0VgIGVycm9yLgoKDAoFBAACAQUSA0cC
BwoMCgUEAAIBARIDRwgTCgwKBQQAAgEDEgNHFhcKlwMKBAQAAgISA1ACFxqJAyBUaGUgbWF4
aW11bSBudW1iZXIgb2YgYGRhdGFgIGJ5dGVzIHRoZSBzZXJ2ZXIgaXMgYWxsb3dlZCB0byBy
ZXR1cm4gaW4gdGhlCiBzdW0gb2YgYWxsIGBSZWFkUmVzcG9uc2VgIG1lc3NhZ2VzLiBBIGBy
ZWFkX2xpbWl0YCBvZiB6ZXJvIGluZGljYXRlcyB0aGF0CiB0aGVyZSBpcyBubyBsaW1pdCwg
YW5kIGEgbmVnYXRpdmUgYHJlYWRfbGltaXRgIHdpbGwgY2F1c2UgYW4gZXJyb3IuCgogSWYg
dGhlIHN0cmVhbSByZXR1cm5zIGZld2VyIGJ5dGVzIHRoYW4gYWxsb3dlZCBieSB0aGUgYHJl
YWRfbGltaXRgIGFuZCBubwogZXJyb3Igb2NjdXJyZWQsIHRoZSBzdHJlYW0gaW5jbHVkZXMg
YWxsIGRhdGEgZnJvbSB0aGUgYHJlYWRfb2Zmc2V0YCB0byB0aGUKIGVuZCBvZiB0aGUgcmVz
b3VyY2UuCgoMCgUEAAICBRIDUAIHCgwKBQQAAgIBEgNQCBIKDAoFBAACAgMSA1AVFgrfAQoE
BAACAxIDVQIbGtEBIE9ubHkgYXBwbGllcyBpZiB0aGUgcmVmZXJlbmNlZCBmaWxlIGlzIGEg
a25vd24gYXJjaGl2ZSB0eXBlIChhciwgamFyLCB6aXApCiBUaGUgYWJvdmUgcmVhZF9vZmZz
ZXQgYW5kIHJlYWRfbGltaXQgZmllbGRzIGFyZSBhcHBsaWVkIHRvIHRoaXMgZW50cnkuCiBJ
ZiB0aGlzIGZpbGUgaXMgbm90IGFuIGFyY2hpdmUsIElOVkFMSURfQVJHVU1FTlQgaXMgdGhy
b3duLgoKDAoFBAACAwUSA1UCCAoMCgUEAAIDARIDVQkWCgwKBQQAAgMDEgNVGRoKKQoCBAES
BFkAXAEaHSBSZXNwb25zZSBvYmplY3QgZm9yIEdldEZpbGUKCgoKAwQBARIDWQgXCh0KBAQB
AgASA1sCERoQIFRoZSBmaWxlIGRhdGEuCgoMCgUEAQIABRIDWwIHCgwKBQQBAgABEgNbCAwK
DAoFBAECAAMSA1sPEAosCgIEAhIEXwB5ARogIFJlcXVlc3Qgb2JqZWN0IGZvciBHZXRGaWxl
VGFpbAoKCgoDBAIBEgNfCBoKkAIKBAQCAgASA2UCERqCAiBUaGlzIGNvcnJlc3BvbmRzIHRv
IHRoZSB1cmkgZmllbGQgaW4gdGhlIEZpbGUgbWVzc2FnZTogZm9yIGFuIG9iZnVzY2F0ZWQK
IEZpbGUudXJpIGxpa2UKIENnbGlkV2xzWkM1c2IyY1NKREkzWW1JNVpXUXhMVFZqWXpFdE5H
RmxOaTFpTVdSa0xUVmxPRFkwWVdFelltRTJaUSwgdGhlCiB2YWx1ZSBoZXJlIHNob3VsZCBi
ZQogZmlsZXMvQ2dsaWRXbHNaQzVzYjJjU0pESTNZbUk1WldReExUVmpZekV0TkdGbE5pMWlN
V1JrTFRWbE9EWTBZV0V6WW1FMlpRCgoMCgUEAgIABRIDZQIICgwKBQQCAgABEgNlCQwKDAoF
BAICAAMSA2UPEArbAQoEBAICARIDbAIYGs0BIFRoZSBvZmZzZXQgZm9yIHRoZSBmaXJzdCBi
eXRlIHRvIHJldHVybiBpbiB0aGUgcmVhZCwgcmVsYXRpdmUgdG8gdGhlIGVuZAogb2YgdGhl
IHJlc291cmNlLgoKIEEgYHJlYWRfb2Zmc2V0YCB0aGF0IGlzIG5lZ2F0aXZlIG9yIGdyZWF0
ZXIgdGhhbiB0aGUgc2l6ZSBvZiB0aGUgcmVzb3VyY2UKIHdpbGwgY2F1c2UgYW4gYE9VVF9P
Rl9SQU5HRWAgZXJyb3IuCgoMCgUEAgIBBRIDbAIHCgwKBQQCAgEBEgNsCBMKDAoFBAICAQMS
A2wWFwqCAgoEBAICAhIDcwIXGvQBIFRoZSBtYXhpbXVtIG51bWJlciBvZiBgZGF0YWAgYnl0
ZXMgdGhlIHNlcnZlciBpcyBhbGxvd2VkIHRvIHJldHVybi4gVGhlCiBzZXJ2ZXIgd2lsbCBy
ZXR1cm4gYnl0ZXMgc3RhcnRpbmcgZnJvbSB0aGUgdGFpbCBvZiB0aGUgZmlsZS4KCiBBIGBy
ZWFkX2xpbWl0YCBvZiB6ZXJvIGluZGljYXRlcyB0aGF0IHRoZXJlIGlzIG5vIGxpbWl0LCBh
bmQgYSBuZWdhdGl2ZQogYHJlYWRfbGltaXRgIHdpbGwgY2F1c2UgYW4gZXJyb3IuCgoMCgUE
AgICBRIDcwIHCgwKBQQCAgIBEgNzCBIKDAoFBAICAgMSA3MVFgrfAQoEBAICAxIDeAIbGtEB
IE9ubHkgYXBwbGllcyBpZiB0aGUgcmVmZXJlbmNlZCBmaWxlIGlzIGEga25vd24gYXJjaGl2
ZSB0eXBlIChhciwgamFyLCB6aXApCiBUaGUgYWJvdmUgcmVhZF9vZmZzZXQgYW5kIHJlYWRf
bGltaXQgZmllbGRzIGFyZSBhcHBsaWVkIHRvIHRoaXMgZW50cnkuCiBJZiB0aGlzIGZpbGUg
aXMgbm90IGFuIGFyY2hpdmUsIElOVkFMSURfQVJHVU1FTlQgaXMgdGhyb3duLgoKDAoFBAIC
AwUSA3gCCAoMCgUEAgIDARIDeAkWCgwKBQQCAgMDEgN4GRoKLQoCBAMSBHwAfwEaISBSZXNw
b25zZSBvYmplY3QgZm9yIEdldEZpbGVUYWlsCgoKCgMEAwESA3wIGwoxCgQEAwIAEgN+AhEa
JCBUaGUgZmlsZSBkYXRhLCBlbmNvZGVkIHdpdGggVVRGLTguCgoMCgUEAwIABRIDfgIHCgwK
BQQDAgABEgN+CAwKDAoFBAMCAAMSA34PEGIGcHJvdG8z
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Devtools::Resultstore::V2::ResultstoreFileDownload::GetFileRequest ===
    # Fields for GetFileRequest
    # Field: uri Type: 9 ()
    # Field: read_offset Type: 3 ()
    # Field: read_limit Type: 3 ()
    # Field: archive_entry Type: 9 ()

# === Message: Google::Devtools::Resultstore::V2::ResultstoreFileDownload::GetFileResponse ===
    # Fields for GetFileResponse
    # Field: data Type: 12 ()

# === Message: Google::Devtools::Resultstore::V2::ResultstoreFileDownload::GetFileTailRequest ===
    # Fields for GetFileTailRequest
    # Field: uri Type: 9 ()
    # Field: read_offset Type: 3 ()
    # Field: read_limit Type: 3 ()
    # Field: archive_entry Type: 9 ()

# === Message: Google::Devtools::Resultstore::V2::ResultstoreFileDownload::GetFileTailResponse ===
    # Fields for GetFileTailResponse
    # Field: data Type: 12 ()

# === Service Client: Google::Devtools::Resultstore::V2::ResultstoreFileDownload::ResultStoreFileDownloadClient ===
package Google::Devtools::Resultstore::V2::ResultstoreFileDownload::ResultStoreFileDownloadClient;

=pod

=head2 Service Client: Google::Devtools::Resultstore::V2::ResultstoreFileDownload::ResultStoreFileDownloadClient

Client stub representing the remote C<ResultStoreFileDownload> gRPC service. Delegates call dispatching to L<Google::gRPC::Client>.

=head3 target

The endpoint target address. Defaults to C<devtools.googleapis.com:443>.

=head3 credentials

The authentication credentials provider. Defaults to application default credentials via L<Google::Auth>.

=cut

use Moo;
use Google::Auth;
use Google::gRPC::Client;

has credentials => ( is => 'ro', default => sub { Google::Auth->default() } );
has target      => ( is => 'ro', default => 'devtools.googleapis.com:443' );

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

sub get_file {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Devtools::Resultstore::V2::ResultstoreFileDownload::GetFileRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.devtools.resultstore.v2.ResultStoreFileDownload',
        method         => 'GetFile',
        request        => $req,
        response_class => 'Google::Devtools::Resultstore::V2::ResultstoreFileDownload::GetFileResponse',
    });
}

sub get_file_tail {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Devtools::Resultstore::V2::ResultstoreFileDownload::GetFileTailRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.devtools.resultstore.v2.ResultStoreFileDownload',
        method         => 'GetFileTail',
        request        => $req,
        response_class => 'Google::Devtools::Resultstore::V2::ResultstoreFileDownload::GetFileTailResponse',
    });
}

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Devtools::Resultstore::V2::ResultstoreFileDownload - Compiled Protocol Buffers messages for google/devtools/resultstore/v2/resultstore_file_download.proto

=head1 SYNOPSIS

    use Google::Devtools::Resultstore::V2::ResultstoreFileDownload;

    my $msg = Google::Devtools::Resultstore::V2::ResultstoreFileDownload::GetFileRequest->new({
        uri => $uri,
        read_offset => $read_offset,
        read_limit => $read_limit,
        archive_entry => $archive_entry,
    });

    # Read or update a field
    my $val = $msg->uri();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Devtools::Resultstore::V2::ResultstoreFileDownload::GetFileRequest->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/devtools/resultstore/v2/resultstore_file_download.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Devtools::Resultstore::V2::ResultstoreFileDownload::GetFileRequest

Request object for GetFile

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->uri() >> / C<< $msg->uri($value) >>

Type: C<String>

This corresponds to the uri field in the File message: for an obfuscated
File.uri like
CglidWlsZC5sb2cSJDI3YmI5ZWQxLTVjYzEtNGFlNi1iMWRkLTVlODY0YWEzYmE2ZQ, the
value here should be
files/CglidWlsZC5sb2cSJDI3YmI5ZWQxLTVjYzEtNGFlNi1iMWRkLTVlODY0YWEzYmE2ZQ

=item * C<< $msg->read_offset() >> / C<< $msg->read_offset($value) >>

Type: C<Int64>

The offset for the first byte to return in the read, relative to the start
of the resource.

A `read_offset` that is negative or greater than the size of the resource
will cause an `OUT_OF_RANGE` error.

=item * C<< $msg->read_limit() >> / C<< $msg->read_limit($value) >>

Type: C<Int64>

The maximum number of `data` bytes the server is allowed to return in the
sum of all `ReadResponse` messages. A `read_limit` of zero indicates that
there is no limit, and a negative `read_limit` will cause an error.

If the stream returns fewer bytes than allowed by the `read_limit` and no
error occurred, the stream includes all data from the `read_offset` to the
end of the resource.

=item * C<< $msg->archive_entry() >> / C<< $msg->archive_entry($value) >>

Type: C<String>

Only applies if the referenced file is a known archive type (ar, jar, zip)
The above read_offset and read_limit fields are applied to this entry.
If this file is not an archive, INVALID_ARGUMENT is thrown.

=back

=head2 Google::Devtools::Resultstore::V2::ResultstoreFileDownload::GetFileResponse

Response object for GetFile

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->data() >> / C<< $msg->data($value) >>

Type: C<Bytes>

The file data.

=back

=head2 Google::Devtools::Resultstore::V2::ResultstoreFileDownload::GetFileTailRequest

Request object for GetFileTail

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->uri() >> / C<< $msg->uri($value) >>

Type: C<String>

This corresponds to the uri field in the File message: for an obfuscated
File.uri like
CglidWlsZC5sb2cSJDI3YmI5ZWQxLTVjYzEtNGFlNi1iMWRkLTVlODY0YWEzYmE2ZQ, the
value here should be
files/CglidWlsZC5sb2cSJDI3YmI5ZWQxLTVjYzEtNGFlNi1iMWRkLTVlODY0YWEzYmE2ZQ

=item * C<< $msg->read_offset() >> / C<< $msg->read_offset($value) >>

Type: C<Int64>

The offset for the first byte to return in the read, relative to the end
of the resource.

A `read_offset` that is negative or greater than the size of the resource
will cause an `OUT_OF_RANGE` error.

=item * C<< $msg->read_limit() >> / C<< $msg->read_limit($value) >>

Type: C<Int64>

The maximum number of `data` bytes the server is allowed to return. The
server will return bytes starting from the tail of the file.

A `read_limit` of zero indicates that there is no limit, and a negative
`read_limit` will cause an error.

=item * C<< $msg->archive_entry() >> / C<< $msg->archive_entry($value) >>

Type: C<String>

Only applies if the referenced file is a known archive type (ar, jar, zip)
The above read_offset and read_limit fields are applied to this entry.
If this file is not an archive, INVALID_ARGUMENT is thrown.

=back

=head2 Google::Devtools::Resultstore::V2::ResultstoreFileDownload::GetFileTailResponse

Response object for GetFileTail

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->data() >> / C<< $msg->data($value) >>

Type: C<Bytes>

The file data, encoded with UTF-8.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Devtools::Resultstore::V2::ResultstoreFileDownload::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
