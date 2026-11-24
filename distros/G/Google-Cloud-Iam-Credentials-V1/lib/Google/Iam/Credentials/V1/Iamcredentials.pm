package Google::Iam::Credentials::V1::Iamcredentials;

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
    eval { require Google::Iam::Credentials::V1::Common };
    my $descriptor_b64 = <<'EOF';
Ci5nb29nbGUvaWFtL2NyZWRlbnRpYWxzL3YxL2lhbWNyZWRlbnRpYWxzLnByb3RvEhlnb29n
bGUuaWFtLmNyZWRlbnRpYWxzLnYxGhxnb29nbGUvYXBpL2Fubm90YXRpb25zLnByb3RvGhdn
b29nbGUvYXBpL2NsaWVudC5wcm90bxomZ29vZ2xlL2lhbS9jcmVkZW50aWFscy92MS9jb21t
b24ucHJvdG8yrQcKDklBTUNyZWRlbnRpYWxzEuwBChNHZW5lcmF0ZUFjY2Vzc1Rva2VuEjUu
Z29vZ2xlLmlhbS5jcmVkZW50aWFscy52MS5HZW5lcmF0ZUFjY2Vzc1Rva2VuUmVxdWVzdBo2
Lmdvb2dsZS5pYW0uY3JlZGVudGlhbHMudjEuR2VuZXJhdGVBY2Nlc3NUb2tlblJlc3BvbnNl
ImaC0+STAkAiOy92MS97bmFtZT1wcm9qZWN0cy8qL3NlcnZpY2VBY2NvdW50cy8qfTpnZW5l
cmF0ZUFjY2Vzc1Rva2VuOgEq2kEdbmFtZSxkZWxlZ2F0ZXMsc2NvcGUsbGlmZXRpbWUS5AEK
D0dlbmVyYXRlSWRUb2tlbhIxLmdvb2dsZS5pYW0uY3JlZGVudGlhbHMudjEuR2VuZXJhdGVJ
ZFRva2VuUmVxdWVzdBoyLmdvb2dsZS5pYW0uY3JlZGVudGlhbHMudjEuR2VuZXJhdGVJZFRv
a2VuUmVzcG9uc2UiaoLT5JMCPCI3L3YxL3tuYW1lPXByb2plY3RzLyovc2VydmljZUFjY291
bnRzLyp9OmdlbmVyYXRlSWRUb2tlbjoBKtpBJW5hbWUsZGVsZWdhdGVzLGF1ZGllbmNlLGlu
Y2x1ZGVfZW1haWwSuQEKCFNpZ25CbG9iEiouZ29vZ2xlLmlhbS5jcmVkZW50aWFscy52MS5T
aWduQmxvYlJlcXVlc3QaKy5nb29nbGUuaWFtLmNyZWRlbnRpYWxzLnYxLlNpZ25CbG9iUmVz
cG9uc2UiVILT5JMCNSIwL3YxL3tuYW1lPXByb2plY3RzLyovc2VydmljZUFjY291bnRzLyp9
OnNpZ25CbG9iOgEq2kEWbmFtZSxkZWxlZ2F0ZXMscGF5bG9hZBK1AQoHU2lnbkp3dBIpLmdv
b2dsZS5pYW0uY3JlZGVudGlhbHMudjEuU2lnbkp3dFJlcXVlc3QaKi5nb29nbGUuaWFtLmNy
ZWRlbnRpYWxzLnYxLlNpZ25Kd3RSZXNwb25zZSJTgtPkkwI0Ii8vdjEve25hbWU9cHJvamVj
dHMvKi9zZXJ2aWNlQWNjb3VudHMvKn06c2lnbkp3dDoBKtpBFm5hbWUsZGVsZWdhdGVzLHBh
eWxvYWQaUcpBHWlhbWNyZWRlbnRpYWxzLmdvb2dsZWFwaXMuY29t0kEuaHR0cHM6Ly93d3cu
Z29vZ2xlYXBpcy5jb20vYXV0aC9jbG91ZC1wbGF0Zm9ybULKAQojY29tLmdvb2dsZS5jbG91
ZC5pYW0uY3JlZGVudGlhbHMudjFCE0lBTUNyZWRlbnRpYWxzUHJvdG9QAVpFY2xvdWQuZ29v
Z2xlLmNvbS9nby9pYW0vY3JlZGVudGlhbHMvYXBpdjEvY3JlZGVudGlhbHNwYjtjcmVkZW50
aWFsc3Bi+AEBqgIfR29vZ2xlLkNsb3VkLklhbS5DcmVkZW50aWFscy5WMcoCH0dvb2dsZVxD
bG91ZFxJYW1cQ3JlZGVudGlhbHNcVjFKxBAKBhIEDgBOAQq8BAoBDBIDDgASMrEEIENvcHly
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
ciB0aGUgTGljZW5zZS4KCggKAQISAxAAIgoJCgIDABIDEgAmCgkKAgMBEgMTACEKCQoCAwIS
AxQAMAoICgEIEgMWAB8KCQoCCB8SAxYAHwoICgEIEgMXADwKCQoCCCUSAxcAPAoICgEIEgMY
AFwKCQoCCAsSAxgAXAoICgEIEgMZACIKCQoCCAoSAxkAIgoICgEIEgMaADQKCQoCCAgSAxoA
NAoICgEIEgMbADwKCQoCCAESAxsAPAoICgEIEgMcAD0KCQoCCCkSAxwAPQqQBAoCBgASBCcA
TgEagwQgQSBzZXJ2aWNlIGFjY291bnQgaXMgYSBzcGVjaWFsIHR5cGUgb2YgR29vZ2xlIGFj
Y291bnQgdGhhdCBiZWxvbmdzIHRvIHlvdXIKIGFwcGxpY2F0aW9uIG9yIGEgdmlydHVhbCBt
YWNoaW5lIChWTSksIGluc3RlYWQgb2YgdG8gYW4gaW5kaXZpZHVhbCBlbmQgdXNlci4KIFlv
dXIgYXBwbGljYXRpb24gYXNzdW1lcyB0aGUgaWRlbnRpdHkgb2YgdGhlIHNlcnZpY2UgYWNj
b3VudCB0byBjYWxsIEdvb2dsZQogQVBJcywgc28gdGhhdCB0aGUgdXNlcnMgYXJlbid0IGRp
cmVjdGx5IGludm9sdmVkLgoKIFNlcnZpY2UgYWNjb3VudCBjcmVkZW50aWFscyBhcmUgdXNl
ZCB0byB0ZW1wb3JhcmlseSBhc3N1bWUgdGhlIGlkZW50aXR5CiBvZiB0aGUgc2VydmljZSBh
Y2NvdW50LiBTdXBwb3J0ZWQgY3JlZGVudGlhbCB0eXBlcyBpbmNsdWRlIE9BdXRoIDIuMCBh
Y2Nlc3MKIHRva2VucywgT3BlbklEIENvbm5lY3QgSUQgdG9rZW5zLCBzZWxmLXNpZ25lZCBK
U09OIFdlYiBUb2tlbnMgKEpXVHMpLCBhbmQKIG1vcmUuCgoKCgMGAAESAycIFgoKCgMGAAMS
AygCRQoMCgUGAAOZCBIDKAJFCgoKAwYAAxIDKQJWCgwKBQYAA5oIEgMpAlYKSgoEBgACABIE
LAIyAxo8IEdlbmVyYXRlcyBhbiBPQXV0aCAyLjAgYWNjZXNzIHRva2VuIGZvciBhIHNlcnZp
Y2UgYWNjb3VudC4KCgwKBQYAAgABEgMsBhkKDAoFBgACAAISAywaNAoMCgUGAAIAAxIDLD9a
Cg0KBQYAAgAEEgQtBDAGChEKCQYAAgAEsMq8IhIELQQwBgoMCgUGAAIABBIDMQRLCg8KCAYA
AgAEmwgAEgMxBEsKSwoEBgACARIENQI7Axo9IEdlbmVyYXRlcyBhbiBPcGVuSUQgQ29ubmVj
dCBJRCB0b2tlbiBmb3IgYSBzZXJ2aWNlIGFjY291bnQuCgoMCgUGAAIBARIDNQYVCgwKBQYA
AgECEgM1FiwKDAoFBgACAQMSAzU3TgoNCgUGAAIBBBIENgQ5BgoRCgkGAAIBBLDKvCISBDYE
OQYKDAoFBgACAQQSAzoEUwoPCggGAAIBBJsIABIDOgRTClIKBAYAAgISBD4CRAMaRCBTaWdu
cyBhIGJsb2IgdXNpbmcgYSBzZXJ2aWNlIGFjY291bnQncyBzeXN0ZW0tbWFuYWdlZCBwcml2
YXRlIGtleS4KCgwKBQYAAgIBEgM+Bg4KDAoFBgACAgISAz4PHgoMCgUGAAICAxIDPik5Cg0K
BQYAAgIEEgQ/BEIGChEKCQYAAgIEsMq8IhIEPwRCBgoMCgUGAAICBBIDQwRECg8KCAYAAgIE
mwgAEgNDBEQKUQoEBgACAxIERwJNAxpDIFNpZ25zIGEgSldUIHVzaW5nIGEgc2VydmljZSBh
Y2NvdW50J3Mgc3lzdGVtLW1hbmFnZWQgcHJpdmF0ZSBrZXkuCgoMCgUGAAIDARIDRwYNCgwK
BQYAAgMCEgNHDhwKDAoFBgACAwMSA0cnNgoNCgUGAAIDBBIESARLBgoRCgkGAAIDBLDKvCIS
BEgESwYKDAoFBgACAwQSA0wERAoPCggGAAIDBJsIABIDTAREYgZwcm90bzM=
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Service Client: Google::Iam::Credentials::V1::Iamcredentials::IAMCredentialsClient ===
package Google::Iam::Credentials::V1::Iamcredentials::IAMCredentialsClient;

=pod

=head2 Service Client: Google::Iam::Credentials::V1::Iamcredentials::IAMCredentialsClient

Client stub representing the remote C<IAMCredentials> gRPC service. Delegates call dispatching to L<Google::gRPC::Client>.

=head3 target

The endpoint target address. Defaults to C<iam.googleapis.com:443>.

=head3 credentials

The authentication credentials provider. Defaults to application default credentials via L<Google::Auth>.

=cut

use Moo;
use Google::Auth;
use Google::gRPC::Client;

has credentials => ( is => 'ro', default => sub { Google::Auth->default() } );
has target      => ( is => 'ro', default => 'iam.googleapis.com:443' );

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

sub generate_access_token {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Iam::Credentials::V1::Common::GenerateAccessTokenRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.iam.credentials.v1.IAMCredentials',
        method         => 'GenerateAccessToken',
        request        => $req,
        response_class => 'Google::Iam::Credentials::V1::Common::GenerateAccessTokenResponse',
    });
}

sub generate_id_token {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Iam::Credentials::V1::Common::GenerateIdTokenRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.iam.credentials.v1.IAMCredentials',
        method         => 'GenerateIdToken',
        request        => $req,
        response_class => 'Google::Iam::Credentials::V1::Common::GenerateIdTokenResponse',
    });
}

sub sign_blob {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Iam::Credentials::V1::Common::SignBlobRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.iam.credentials.v1.IAMCredentials',
        method         => 'SignBlob',
        request        => $req,
        response_class => 'Google::Iam::Credentials::V1::Common::SignBlobResponse',
    });
}

sub sign_jwt {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Iam::Credentials::V1::Common::SignJwtRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.iam.credentials.v1.IAMCredentials',
        method         => 'SignJwt',
        request        => $req,
        response_class => 'Google::Iam::Credentials::V1::Common::SignJwtResponse',
    });
}

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Iam::Credentials::V1::Iamcredentials - Compiled Protocol Buffers messages for google/iam/credentials/v1/iamcredentials.proto

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/iam/credentials/v1/iamcredentials.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Iam::Credentials::V1::Iamcredentials::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
