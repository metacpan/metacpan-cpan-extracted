package Google::Cloud::Run::V2::SourceUpload;

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
    eval { require Google::Api::Routing };
    eval { require Google::Cloud::Run::V2::K8sMin };
    my $descriptor_b64 = <<'EOF';
Cidnb29nbGUvY2xvdWQvcnVuL3YyL3NvdXJjZV91cGxvYWQucHJvdG8SE2dvb2dsZS5jbG91
ZC5ydW4udjIaHGdvb2dsZS9hcGkvYW5ub3RhdGlvbnMucHJvdG8aF2dvb2dsZS9hcGkvY2xp
ZW50LnByb3RvGh9nb29nbGUvYXBpL2ZpZWxkX2JlaGF2aW9yLnByb3RvGhlnb29nbGUvYXBp
L3Jlc291cmNlLnByb3RvGhhnb29nbGUvYXBpL3JvdXRpbmcucHJvdG8aIWdvb2dsZS9jbG91
ZC9ydW4vdjIvazhzLm1pbi5wcm90byKfAQoTVXBsb2FkU291cmNlUmVxdWVzdBJBCgZwYXJl
bnQYASABKAlCKeBBAvpBIwohbG9jYXRpb25zLmdvb2dsZWFwaXMuY29tL0xvY2F0aW9uUgZw
YXJlbnQSOwoHc2VydmljZRgCIAEoCUIf+kEcChpydW4uZ29vZ2xlYXBpcy5jb20vU2Vydmlj
ZUgAUgdzZXJ2aWNlQggKBnRhcmdldCJ8ChRVcGxvYWRTb3VyY2VSZXNwb25zZRJkChRjbG91
ZF9zdG9yYWdlX3NvdXJjZRgDIAEoCzIyLmdvb2dsZS5jbG91ZC5ydW4udjIuU291cmNlQ29k
ZS5DbG91ZFN0b3JhZ2VTb3VyY2VSEmNsb3VkU3RvcmFnZVNvdXJjZTLZAgoMU291cmNlVXBs
b2FkEtwBCgxVcGxvYWRTb3VyY2USKC5nb29nbGUuY2xvdWQucnVuLnYyLlVwbG9hZFNvdXJj
ZVJlcXVlc3QaKS5nb29nbGUuY2xvdWQucnVuLnYyLlVwbG9hZFNvdXJjZVJlc3BvbnNlIneC
0+STAjUiMC92Mi97cGFyZW50PXByb2plY3RzLyovbG9jYXRpb25zLyp9OnVwbG9hZFNvdXJj
ZToBKorT5JMCLRIrCgZwYXJlbnQSIXByb2plY3RzLyovbG9jYXRpb25zL3tsb2NhdGlvbj0q
fdpBBnBhcmVudBpqykEScnVuLmdvb2dsZWFwaXMuY29t0kFSaHR0cHM6Ly93d3cuZ29vZ2xl
YXBpcy5jb20vYXV0aC9jbG91ZC1wbGF0Zm9ybSxodHRwczovL3d3dy5nb29nbGVhcGlzLmNv
bS9hdXRoL3J1bkJZChdjb20uZ29vZ2xlLmNsb3VkLnJ1bi52MkIRU291cmNlVXBsb2FkUHJv
dG9QAVopY2xvdWQuZ29vZ2xlLmNvbS9nby9ydW4vYXBpdjIvcnVucGI7cnVucGJK3hEKBhIE
DgBUAQq8BAoBDBIDDgASMrEEIENvcHlyaWdodCAyMDI2IEdvb2dsZSBMTEMKCiBMaWNlbnNl
ZCB1bmRlciB0aGUgQXBhY2hlIExpY2Vuc2UsIFZlcnNpb24gMi4wICh0aGUgIkxpY2Vuc2Ui
KTsKIHlvdSBtYXkgbm90IHVzZSB0aGlzIGZpbGUgZXhjZXB0IGluIGNvbXBsaWFuY2Ugd2l0
aCB0aGUgTGljZW5zZS4KIFlvdSBtYXkgb2J0YWluIGEgY29weSBvZiB0aGUgTGljZW5zZSBh
dAoKICAgICBodHRwOi8vd3d3LmFwYWNoZS5vcmcvbGljZW5zZXMvTElDRU5TRS0yLjAKCiBV
bmxlc3MgcmVxdWlyZWQgYnkgYXBwbGljYWJsZSBsYXcgb3IgYWdyZWVkIHRvIGluIHdyaXRp
bmcsIHNvZnR3YXJlCiBkaXN0cmlidXRlZCB1bmRlciB0aGUgTGljZW5zZSBpcyBkaXN0cmli
dXRlZCBvbiBhbiAiQVMgSVMiIEJBU0lTLAogV0lUSE9VVCBXQVJSQU5USUVTIE9SIENPTkRJ
VElPTlMgT0YgQU5ZIEtJTkQsIGVpdGhlciBleHByZXNzIG9yIGltcGxpZWQuCiBTZWUgdGhl
IExpY2Vuc2UgZm9yIHRoZSBzcGVjaWZpYyBsYW5ndWFnZSBnb3Zlcm5pbmcgcGVybWlzc2lv
bnMgYW5kCiBsaW1pdGF0aW9ucyB1bmRlciB0aGUgTGljZW5zZS4KCggKAQISAxAAHAoJCgID
ABIDEgAmCgkKAgMBEgMTACEKCQoCAwISAxQAKQoJCgIDAxIDFQAjCgkKAgMEEgMWACIKCQoC
AwUSAxcAKwoICgEIEgMZAEAKCQoCCAsSAxkAQAoICgEIEgMaACIKCQoCCAoSAxoAIgoICgEI
EgMbADIKCQoCCAgSAxsAMgoICgEIEgMcADAKCQoCCAESAxwAMApuCgIGABIEIAA6ARpiIFRo
ZSBDbG91ZCBSdW4gU291cmNlIFVwbG9hZCBBUEkgYWxsb3dzIHlvdSB0byB1cGxvYWQgc291
cmNlIGNvZGUgdG8gZGVwbG95CiBDbG91ZCBSdW4gcmVzb3VyY2VzLgoKCgoDBgABEgMgCBQK
CgoDBgADEgMhAjoKDAoFBgADmQgSAyECOgoLCgMGAAMSBCICJCwKDQoFBgADmggSBCICJCwK
qAMKBAYAAgASBC0COQMamQMgVXBsb2FkcyBhIHNvdXJjZSBhcmNoaXZlIHRvIGEgR29vZ2xl
IENsb3VkIFN0b3JhZ2UgYnVja2V0IHRocm91Z2ggQ2xvdWQKIFJ1bi4gVGhlIHVwbG9hZGVk
IHNvdXJjZSBvYmplY3Qgc2hvdWxkIGJlIHVzZWQgZm9yIENsb3VkIFJ1biByZXNvdXJjZQog
ZGVwbG95bWVudHMuIFVzZXIgaXMgcmVzcG9uc2libGUgZm9yIG1hbmFnaW5nIHRoZSBsaWZl
Y3ljbGUgb2YgdGhlIHVwbG9hZGVkCiBvYmplY3QuCiBJZiB1cGxvYWRpbmcgdGhyb3VnaCB0
aGUgQ2xvdWQgUnVuIEFQSSB0byBDbG91ZCBTdG9yYWdlIGlzIG5vdCBkZXNpcmVkLCB5b3UK
IGNhbiB1c2UgdGhlIElBTSBEZW55IFBvbGljeSB0byBkZW55IHRoZSBgcnVuLmxvY2F0aW9u
cy51cGxvYWRTb3VyY2VgCiBwZXJtaXNzaW9uIGZvciBhbGwgcHJpbmNpcGFscy4KCgwKBQYA
AgABEgMtBhIKDAoFBgACAAISAy0TJgoMCgUGAAIAAxIDLTFFCg0KBQYAAgAEEgQuBDEGChEK
CQYAAgAEsMq8IhIELgQxBgoNCgUGAAIABBIEMgQ3BgoRCgkGAAIABLHKvCISBDIENwYKDAoF
BgACAAQSAzgENAoPCggGAAIABJsIABIDOAQ0Cj4KAgQAEgQ9AE4BGjIgVGhlIHJlcXVlc3Qg
bWVzc2FnZSBmb3IgdGhlIFVwbG9hZFNvdXJjZSBtZXRob2QuCgoKCgMEAAESAz0IGwqZAQoE
BAACABIEQAJFBBqKASBSZXF1aXJlZC4gVGhlIHByb2plY3QgYW5kIGxvY2F0aW9uIGluIHdo
aWNoIHRoZSBzb3VyY2UgYXJjaGl2ZSBzaG91bGQgYmUKIHVwbG9hZGVkIHRvLCBzcGVjaWZp
ZWQgaW4gdGhlIGZvcm1hdCBgcHJvamVjdHMvKi9sb2NhdGlvbnMvKmAuCgoMCgUEAAIABRID
QAIICgwKBQQAAgABEgNACQ8KDAoFBAACAAMSA0ASEwoNCgUEAAIACBIEQBRFAwoPCggEAAIA
CJwIABIDQQQqCg8KBwQAAgAInwgSBEIERAUKUgoEBAAIABIESAJNAxpEIFRoZSBDbG91ZCBS
dW4gcmVzb3VyY2UgdGhlIHVwbG9hZCBzb3VyY2UgYXJjaGl2ZSB3aWxsIGJlIHVzZWQgZm9y
LgoKDAoFBAAIAAESA0gIDgpVCgQEAAIBEgRKBEwGGkcgVGhlIG5hbWUgb2YgQ2xvdWQgUnVu
IFNlcnZpY2UgdXBsb2FkIHNvdXJjZSBhcmNoaXZlIHdpbGwgYmUgdXNlZCBmb3IuCgoMCgUE
AAIBBRIDSgQKCgwKBQQAAgEBEgNKCxIKDAoFBAACAQMSA0oVFgoNCgUEAAIBCBIEShdMBQoO
CgcEAAIBCJ8IEgNLBk4KPwoCBAESBFEAVAEaMyBUaGUgcmVzcG9uc2UgbWVzc2FnZSBmb3Ig
dGhlIFVwbG9hZFNvdXJjZSBtZXRob2QuCgoKCgMEAQESA1EIHApPCgQEAQIAEgNTAjkaQiBU
aGUgQ2xvdWQgU3RvcmFnZSBvYmplY3QgcGF0aCB0aGUgc291cmNlIGFyY2hpdmUgaXMgdXBs
b2FkZWQgdG8uCgoMCgUEAQIABhIDUwIfCgwKBQQBAgABEgNTIDQKDAoFBAECAAMSA1M3OGIG
cHJvdG8z
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Run::V2::SourceUpload::UploadSourceRequest ===
    # Fields for UploadSourceRequest
    # Field: parent Type: 9 ()
    # Field: service Type: 9 ()

# === Message: Google::Cloud::Run::V2::SourceUpload::UploadSourceResponse ===
    # Fields for UploadSourceResponse
    # Field: cloud_storage_source Type: 11 (.google.cloud.run.v2.SourceCode.CloudStorageSource)

# === Service Client: Google::Cloud::Run::V2::SourceUpload::SourceUploadClient ===
package Google::Cloud::Run::V2::SourceUpload::SourceUploadClient;

=pod

=head2 Service Client: Google::Cloud::Run::V2::SourceUpload::SourceUploadClient

Client stub representing the remote C<SourceUpload> gRPC service. Delegates call dispatching to L<Google::gRPC::Client>.

=head3 target

The endpoint target address. Defaults to C<run.googleapis.com:443>.

=head3 credentials

The authentication credentials provider. Defaults to application default credentials via L<Google::Auth>.

=cut

use Moo;
use Google::Auth;
use Google::gRPC::Client;

has credentials => ( is => 'ro', default => sub { Google::Auth->default() } );
has target      => ( is => 'ro', default => 'run.googleapis.com:443' );

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

sub upload_source {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Run::V2::SourceUpload::UploadSourceRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.run.v2.SourceUpload',
        method         => 'UploadSource',
        request        => $req,
        response_class => 'Google::Cloud::Run::V2::SourceUpload::UploadSourceResponse',
    });
}

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Run::V2::SourceUpload - Compiled Protocol Buffers messages for google/cloud/run/v2/source_upload.proto

=head1 SYNOPSIS

    use Google::Cloud::Run::V2::SourceUpload;

    my $msg = Google::Cloud::Run::V2::SourceUpload::UploadSourceRequest->new({
        parent => $parent,
        service => $service,
    });

    # Read or update a field
    my $val = $msg->parent();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Run::V2::SourceUpload::UploadSourceRequest->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/run/v2/source_upload.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Run::V2::SourceUpload::UploadSourceRequest

The request message for the UploadSource method.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->parent() >> / C<< $msg->parent($value) >>

Type: C<String>

Required. The project and location in which the source archive should be
uploaded to, specified in the format `projects/*/locations/*`.

=item * C<< $msg->service() >> / C<< $msg->service($value) >>

Type: C<String>

The name of Cloud Run Service upload source archive will be used for.

=back

=head2 Google::Cloud::Run::V2::SourceUpload::UploadSourceResponse

The response message for the UploadSource method.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->cloud_storage_source() >> / C<< $msg->cloud_storage_source($value) >>

Type: C<Message> (L<Google::Cloud::Run::V2::K8sMin::SourceCode::CloudStorageSource>)

The Cloud Storage object path the source archive is uploaded to.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Run::V2::SourceUpload::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
