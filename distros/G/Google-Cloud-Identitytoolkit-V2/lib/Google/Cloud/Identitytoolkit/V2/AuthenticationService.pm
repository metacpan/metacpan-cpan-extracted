package Google::Cloud::Identitytoolkit::V2::AuthenticationService;

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
    eval { require Google::Cloud::Identitytoolkit::V2::MfaInfo };
    my $descriptor_b64 = <<'EOF';
Cjxnb29nbGUvY2xvdWQvaWRlbnRpdHl0b29sa2l0L3YyL2F1dGhlbnRpY2F0aW9uX3NlcnZp
Y2UucHJvdG8SH2dvb2dsZS5jbG91ZC5pZGVudGl0eXRvb2xraXQudjIaHGdvb2dsZS9hcGkv
YW5ub3RhdGlvbnMucHJvdG8aF2dvb2dsZS9hcGkvY2xpZW50LnByb3RvGh9nb29nbGUvYXBp
L2ZpZWxkX2JlaGF2aW9yLnByb3RvGi5nb29nbGUvY2xvdWQvaWRlbnRpdHl0b29sa2l0L3Yy
L21mYV9pbmZvLnByb3RvIv8BChhGaW5hbGl6ZU1mYVNpZ25JblJlcXVlc3QSOQoWbWZhX3Bl
bmRpbmdfY3JlZGVudGlhbBgCIAEoCUID4EECUhRtZmFQZW5kaW5nQ3JlZGVudGlhbBJ2Chdw
aG9uZV92ZXJpZmljYXRpb25faW5mbxgDIAEoCzI8Lmdvb2dsZS5jbG91ZC5pZGVudGl0eXRv
b2xraXQudjIuRmluYWxpemVNZmFQaG9uZVJlcXVlc3RJbmZvSABSFXBob25lVmVyaWZpY2F0
aW9uSW5mbxIbCgl0ZW5hbnRfaWQYBCABKAlSCHRlbmFudElkQhMKEXZlcmlmaWNhdGlvbl9p
bmZvItsBChlGaW5hbGl6ZU1mYVNpZ25JblJlc3BvbnNlEhkKCGlkX3Rva2VuGAEgASgJUgdp
ZFRva2VuEiMKDXJlZnJlc2hfdG9rZW4YAiABKAlSDHJlZnJlc2hUb2tlbhJnCg9waG9uZV9h
dXRoX2luZm8YAyABKAsyPS5nb29nbGUuY2xvdWQuaWRlbnRpdHl0b29sa2l0LnYyLkZpbmFs
aXplTWZhUGhvbmVSZXNwb25zZUluZm9IAFINcGhvbmVBdXRoSW5mb0IVChNhdXhpbGlhcnlf
YXV0aF9pbmZvIpoCChVTdGFydE1mYVNpZ25JblJlcXVlc3QSOQoWbWZhX3BlbmRpbmdfY3Jl
ZGVudGlhbBgCIAEoCUID4EECUhRtZmFQZW5kaW5nQ3JlZGVudGlhbBIvChFtZmFfZW5yb2xs
bWVudF9pZBgDIAEoCUID4EECUg9tZmFFbnJvbGxtZW50SWQSaAoScGhvbmVfc2lnbl9pbl9p
bmZvGAQgASgLMjkuZ29vZ2xlLmNsb3VkLmlkZW50aXR5dG9vbGtpdC52Mi5TdGFydE1mYVBo
b25lUmVxdWVzdEluZm9IAFIPcGhvbmVTaWduSW5JbmZvEhsKCXRlbmFudF9pZBgFIAEoCVII
dGVuYW50SWRCDgoMc2lnbl9pbl9pbmZvIpcBChZTdGFydE1mYVNpZ25JblJlc3BvbnNlEmwK
E3Bob25lX3Jlc3BvbnNlX2luZm8YASABKAsyOi5nb29nbGUuY2xvdWQuaWRlbnRpdHl0b29s
a2l0LnYyLlN0YXJ0TWZhUGhvbmVSZXNwb25zZUluZm9IAFIRcGhvbmVSZXNwb25zZUluZm9C
DwoNcmVzcG9uc2VfaW5mbzLRAwoVQXV0aGVudGljYXRpb25TZXJ2aWNlErYBChFGaW5hbGl6
ZU1mYVNpZ25JbhI5Lmdvb2dsZS5jbG91ZC5pZGVudGl0eXRvb2xraXQudjIuRmluYWxpemVN
ZmFTaWduSW5SZXF1ZXN0GjouZ29vZ2xlLmNsb3VkLmlkZW50aXR5dG9vbGtpdC52Mi5GaW5h
bGl6ZU1mYVNpZ25JblJlc3BvbnNlIiqC0+STAiQiHy92Mi9hY2NvdW50cy9tZmFTaWduSW46
ZmluYWxpemU6ASoSqgEKDlN0YXJ0TWZhU2lnbkluEjYuZ29vZ2xlLmNsb3VkLmlkZW50aXR5
dG9vbGtpdC52Mi5TdGFydE1mYVNpZ25JblJlcXVlc3QaNy5nb29nbGUuY2xvdWQuaWRlbnRp
dHl0b29sa2l0LnYyLlN0YXJ0TWZhU2lnbkluUmVzcG9uc2UiJ4LT5JMCISIcL3YyL2FjY291
bnRzL21mYVNpZ25JbjpzdGFydDoBKhpSykEeaWRlbnRpdHl0b29sa2l0Lmdvb2dsZWFwaXMu
Y29t0kEuaHR0cHM6Ly93d3cuZ29vZ2xlYXBpcy5jb20vYXV0aC9jbG91ZC1wbGF0Zm9ybULf
AQojY29tLmdvb2dsZS5jbG91ZC5pZGVudGl0eXRvb2xraXQudjJQAVpNY2xvdWQuZ29vZ2xl
LmNvbS9nby9pZGVudGl0eXRvb2xraXQvYXBpdjIvaWRlbnRpdHl0b29sa2l0cGI7aWRlbnRp
dHl0b29sa2l0cGKqAh9Hb29nbGUuQ2xvdWQuSWRlbnRpdHlUb29sa2l0LlYyygIfR29vZ2xl
XENsb3VkXElkZW50aXR5VG9vbGtpdFxWMuoCIkdvb2dsZTo6Q2xvdWQ6OklkZW50aXR5VG9v
bGtpdDo6VjJK4RoKBhIEDgBwAQq8BAoBDBIDDgASMrEEIENvcHlyaWdodCAyMDI1IEdvb2ds
ZSBMTEMKCiBMaWNlbnNlZCB1bmRlciB0aGUgQXBhY2hlIExpY2Vuc2UsIFZlcnNpb24gMi4w
ICh0aGUgIkxpY2Vuc2UiKTsKIHlvdSBtYXkgbm90IHVzZSB0aGlzIGZpbGUgZXhjZXB0IGlu
IGNvbXBsaWFuY2Ugd2l0aCB0aGUgTGljZW5zZS4KIFlvdSBtYXkgb2J0YWluIGEgY29weSBv
ZiB0aGUgTGljZW5zZSBhdAoKICAgICBodHRwOi8vd3d3LmFwYWNoZS5vcmcvbGljZW5zZXMv
TElDRU5TRS0yLjAKCiBVbmxlc3MgcmVxdWlyZWQgYnkgYXBwbGljYWJsZSBsYXcgb3IgYWdy
ZWVkIHRvIGluIHdyaXRpbmcsIHNvZnR3YXJlCiBkaXN0cmlidXRlZCB1bmRlciB0aGUgTGlj
ZW5zZSBpcyBkaXN0cmlidXRlZCBvbiBhbiAiQVMgSVMiIEJBU0lTLAogV0lUSE9VVCBXQVJS
QU5USUVTIE9SIENPTkRJVElPTlMgT0YgQU5ZIEtJTkQsIGVpdGhlciBleHByZXNzIG9yIGlt
cGxpZWQuCiBTZWUgdGhlIExpY2Vuc2UgZm9yIHRoZSBzcGVjaWZpYyBsYW5ndWFnZSBnb3Zl
cm5pbmcgcGVybWlzc2lvbnMgYW5kCiBsaW1pdGF0aW9ucyB1bmRlciB0aGUgTGljZW5zZS4K
CggKAQISAxAAKAoJCgIDABIDEgAmCgkKAgMBEgMTACEKCQoCAwISAxQAKQoJCgIDAxIDFQA4
CggKAQgSAxcAPAoJCgIIJRIDFwA8CggKAQgSAxgAZAoJCgIICxIDGABkCggKAQgSAxkAIgoJ
CgIIChIDGQAiCggKAQgSAxoAPAoJCgIIARIDGgA8CggKAQgSAxsAPAoJCgIIKRIDGwA8CggK
AQgSAxwAOwoJCgIILRIDHAA7CjEKAgYAEgQfADIBGiUgQXV0aGVudGljYXRpb24gZm9yIElk
ZW50aXR5IFRvb2xraXQKCgoKAwYAARIDHwgdCgoKAwYAAxIDIAJGCgwKBQYAA5kIEgMgAkYK
CgoDBgADEgMhAlYKDAoFBgADmggSAyECVgo/CgQGAAIAEgQkAikDGjEgVmVyaWZpZXMgdGhl
IE1GQSBjaGFsbGVuZ2UgYW5kIHBlcmZvcm1zIHNpZ24taW4KCgwKBQYAAgABEgMkBhcKDAoF
BgACAAISAyQYMAoMCgUGAAIAAxIDJDtUCg0KBQYAAgAEEgQlBCgGChEKCQYAAgAEsMq8IhIE
JQQoBgonCgQGAAIBEgQsAjEDGhkgU2VuZHMgdGhlIE1GQSBjaGFsbGVuZ2UKCgwKBQYAAgEB
EgMsBhQKDAoFBgACAQISAywVKgoMCgUGAAIBAxIDLDVLCg0KBQYAAgEEEgQtBDAGChEKCQYA
AgEEsMq8IhIELQQwBgo7CgIEABIENQBCARovIEZpbmFsaXplcyBzaWduLWluIGJ5IHZlcmlm
eWluZyBNRkEgY2hhbGxlbmdlLgoKCgoDBAABEgM1CCAKRgoEBAACABIDNwJNGjkgUmVxdWly
ZWQuIFBlbmRpbmcgY3JlZGVudGlhbCBmcm9tIGZpcnN0IGZhY3RvciBzaWduLWluLgoKDAoF
BAACAAUSAzcCCAoMCgUEAAIAARIDNwkfCgwKBQQAAgADEgM3IiMKDAoFBAACAAgSAzckTAoP
CggEAAIACJwIABIDNyVLCjkKBAQACAASBDoCPQMaKyBQcm9vZiBvZiBjb21wbGV0aW9uIG9m
IHRoZSBNRkEgY2hhbGxlbmdlLgoKDAoFBAAIAAESAzoIGQpCCgQEAAIBEgM8BDwaNSBQcm9v
ZiBvZiBjb21wbGV0aW9uIG9mIHRoZSBTTVMgYmFzZWQgTUZBIGNoYWxsZW5nZS4KCgwKBQQA
AgEGEgM8BB8KDAoFBAACAQESAzwgNwoMCgUEAAIBAxIDPDo7Cp4BCgQEAAICEgNBAhcakAEg
VGhlIElEIG9mIHRoZSBJZGVudGl0eSBQbGF0Zm9ybSB0ZW5hbnQgdGhlIHVzZXIgaXMgc2ln
bmluZyBpbiB0by4gSWYgbm90CiBzZXQsIHRoZSB1c2VyIHdpbGwgc2lnbiBpbiB0byB0aGUg
ZGVmYXVsdCBJZGVudGl0eSBQbGF0Zm9ybSBwcm9qZWN0LgoKDAoFBAACAgUSA0ECCAoMCgUE
AAICARIDQQkSCgwKBQQAAgIDEgNBFRYKKQoCBAESBEUAUQEaHSBGaW5hbGl6ZU1mYVNpZ25J
biByZXNwb25zZS4KCgoKAwQBARIDRQghCjMKBAQBAgASA0cCFhomIElEIHRva2VuIGZvciB0
aGUgYXV0aGVudGljYXRlZCB1c2VyLgoKDAoFBAECAAUSA0cCCAoMCgUEAQIAARIDRwkRCgwK
BQQBAgADEgNHFBUKOAoEBAECARIDSgIbGisgUmVmcmVzaCB0b2tlbiBmb3IgdGhlIGF1dGhl
bnRpY2F0ZWQgdXNlci4KCgwKBQQBAgEFEgNKAggKDAoFBAECAQESA0oJFgoMCgUEAQIBAxID
ShkaCjEKBAQBCAASBE0CUAMaIyBNRkEgdmVyaWZpZWQgc2lnbi1pbiBpbmZvcm1hdGlvbi4K
CgwKBQQBCAABEgNNCBsKSwoEBAECAhIDTwQ1Gj4gRXh0cmEgcGhvbmUgYXV0aCBpbmZvLCBp
bmNsdWRpbmcgYW5kcm9pZCB2ZXJpZmljYXRpb24gcHJvb2YuCgoMCgUEAQICBhIDTwQgCgwK
BQQBAgIBEgNPITAKDAoFBAECAgMSA08zNApVCgIEAhIEVABkARpJIFN0YXJ0cyBtdWx0aS1m
YWN0b3Igc2lnbi1pbiBieSBzZW5kaW5nIHRoZSBtdWx0aS1mYWN0b3IgYXV0aCBjaGFsbGVu
Z2UuCgoKCgMEAgESA1QIHQpGCgQEAgIAEgNWAk0aOSBSZXF1aXJlZC4gUGVuZGluZyBjcmVk
ZW50aWFsIGZyb20gZmlyc3QgZmFjdG9yIHNpZ24taW4uCgoMCgUEAgIABRIDVgIICgwKBQQC
AgABEgNWCR8KDAoFBAICAAMSA1YiIwoMCgUEAgIACBIDViRMCg8KCAQCAgAInAgAEgNWJUsK
WwoEBAICARIDWQJIGk4gUmVxdWlyZWQuIE1GQSBlbnJvbGxtZW50IGlkIGZyb20gdGhlIHVz
ZXIncyBsaXN0IG9mIGN1cnJlbnQgTUZBIGVucm9sbG1lbnRzLgoKDAoFBAICAQUSA1kCCAoM
CgUEAgIBARIDWQkaCgwKBQQCAgEDEgNZHR4KDAoFBAICAQgSA1kfRwoPCggEAgIBCJwIABID
WSBGCjYKBAQCCAASBFwCXwMaKCBNRkEgaW5mb3JtYXRpb24gYnkgdHlwZSBvZiAybmQgZmFj
dG9yLgoKDAoFBAIIAAESA1wIFApUCgQEAgICEgNeBDQaRyBWZXJpZmljYXRpb24gaW5mbyB0
byBhdXRob3JpemUgc2VuZGluZyBhbiBTTVMgZm9yIHBob25lIHZlcmlmaWNhdGlvbi4KCgwK
BQQCAgIGEgNeBBwKDAoFBAICAgESA14dLwoMCgUEAgICAxIDXjIzCp4BCgQEAgIDEgNjAhca
kAEgVGhlIElEIG9mIHRoZSBJZGVudGl0eSBQbGF0Zm9ybSB0ZW5hbnQgdGhlIHVzZXIgaXMg
c2lnbmluZyBpbiB0by4gSWYgbm90CiBzZXQsIHRoZSB1c2VyIHdpbGwgc2lnbiBpbiB0byB0
aGUgZGVmYXVsdCBJZGVudGl0eSBQbGF0Zm9ybSBwcm9qZWN0LgoKDAoFBAICAwUSA2MCCAoM
CgUEAgIDARIDYwkSCgwKBQQCAgMDEgNjFRYKJgoCBAMSBGcAcAEaGiBTdGFydE1mYVNpZ25J
biByZXNwb25zZS4KCgoKAwQDARIDZwgeCkYKBAQDCAASBGkCbwMaOCBNdWx0aUZhY3RvciBz
dGFydCBzaWduLWluIHJlc3BvbnNlIGJ5IDJuZCBmYWN0b3IgdHlwZS4KCgwKBQQDCAABEgNp
CBUKgQIKBAQDAgASA24ENhrzASBNdWx0aUZhY3RvciBzaWduLWluIHNlc3Npb24gaW5mb3Jt
YXRpb24gc3BlY2lmaWMgdG8gU01TLXR5cGUgc2Vjb25kCiBmYWN0b3JzLiBBbG9uZyB3aXRo
IHRoZSBvbmUtdGltZSBjb2RlIHJldHJpZXZlZCBmcm9tIHRoZSBzZW50IFNNUywgdGhlCiBj
b250ZW50cyBvZiB0aGlzIHNlc3Npb24gaW5mb3JtYXRpb24gc2hvdWxkIGJlIHBhc3NlZCB0
bwogRmluYWxpemVNZmFTaWduSW4gdG8gY29tcGxldGUgdGhlIHNpZ24gaW4uCgoMCgUEAwIA
BhIDbgQdCgwKBQQDAgABEgNuHjEKDAoFBAMCAAMSA240NWIGcHJvdG8z
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Identitytoolkit::V2::AuthenticationService::FinalizeMfaSignInRequest ===
    # Fields for FinalizeMfaSignInRequest
    # Field: mfa_pending_credential Type: 9 ()
    # Field: phone_verification_info Type: 11 (.google.cloud.identitytoolkit.v2.FinalizeMfaPhoneRequestInfo)
    # Field: tenant_id Type: 9 ()

# === Message: Google::Cloud::Identitytoolkit::V2::AuthenticationService::FinalizeMfaSignInResponse ===
    # Fields for FinalizeMfaSignInResponse
    # Field: id_token Type: 9 ()
    # Field: refresh_token Type: 9 ()
    # Field: phone_auth_info Type: 11 (.google.cloud.identitytoolkit.v2.FinalizeMfaPhoneResponseInfo)

# === Message: Google::Cloud::Identitytoolkit::V2::AuthenticationService::StartMfaSignInRequest ===
    # Fields for StartMfaSignInRequest
    # Field: mfa_pending_credential Type: 9 ()
    # Field: mfa_enrollment_id Type: 9 ()
    # Field: phone_sign_in_info Type: 11 (.google.cloud.identitytoolkit.v2.StartMfaPhoneRequestInfo)
    # Field: tenant_id Type: 9 ()

# === Message: Google::Cloud::Identitytoolkit::V2::AuthenticationService::StartMfaSignInResponse ===
    # Fields for StartMfaSignInResponse
    # Field: phone_response_info Type: 11 (.google.cloud.identitytoolkit.v2.StartMfaPhoneResponseInfo)

# === Service Client: Google::Cloud::Identitytoolkit::V2::AuthenticationService::AuthenticationServiceClient ===
package Google::Cloud::Identitytoolkit::V2::AuthenticationService::AuthenticationServiceClient;

=pod

=head2 Service Client: Google::Cloud::Identitytoolkit::V2::AuthenticationService::AuthenticationServiceClient

Client stub representing the remote C<AuthenticationService> gRPC service. Delegates call dispatching to L<Google::gRPC::Client>.

=head3 target

The endpoint target address. Defaults to C<identitytoolkit.googleapis.com:443>.

=head3 credentials

The authentication credentials provider. Defaults to application default credentials via L<Google::Auth>.

=cut

use Moo;
use Google::Auth;
use Google::gRPC::Client;

has credentials => ( is => 'ro', default => sub { Google::Auth->default() } );
has target      => ( is => 'ro', default => 'identitytoolkit.googleapis.com:443' );

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

sub finalize_mfa_sign_in {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Identitytoolkit::V2::AuthenticationService::FinalizeMfaSignInRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.identitytoolkit.v2.AuthenticationService',
        method         => 'FinalizeMfaSignIn',
        request        => $req,
        response_class => 'Google::Cloud::Identitytoolkit::V2::AuthenticationService::FinalizeMfaSignInResponse',
    });
}

sub start_mfa_sign_in {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Identitytoolkit::V2::AuthenticationService::StartMfaSignInRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.identitytoolkit.v2.AuthenticationService',
        method         => 'StartMfaSignIn',
        request        => $req,
        response_class => 'Google::Cloud::Identitytoolkit::V2::AuthenticationService::StartMfaSignInResponse',
    });
}

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Identitytoolkit::V2::AuthenticationService - Compiled Protocol Buffers messages for google/cloud/identitytoolkit/v2/authentication_service.proto

=head1 SYNOPSIS

    use Google::Cloud::Identitytoolkit::V2::AuthenticationService;

    my $msg = Google::Cloud::Identitytoolkit::V2::AuthenticationService::FinalizeMfaSignInRequest->new({
        mfa_pending_credential => $mfa_pending_credential,
        phone_verification_info => $phone_verification_info,
        tenant_id => $tenant_id,
    });

    # Read or update a field
    my $val = $msg->mfa_pending_credential();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Identitytoolkit::V2::AuthenticationService::FinalizeMfaSignInRequest->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/identitytoolkit/v2/authentication_service.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Identitytoolkit::V2::AuthenticationService::FinalizeMfaSignInRequest

Finalizes sign-in by verifying MFA challenge.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->mfa_pending_credential() >> / C<< $msg->mfa_pending_credential($value) >>

Type: C<String>

Required. Pending credential from first factor sign-in.

=item * C<< $msg->phone_verification_info() >> / C<< $msg->phone_verification_info($value) >>

Type: C<Message> (L<Google::Cloud::Identitytoolkit::V2::MfaInfo::FinalizeMfaPhoneRequestInfo>)

Proof of completion of the SMS based MFA challenge.

=item * C<< $msg->tenant_id() >> / C<< $msg->tenant_id($value) >>

Type: C<String>

The ID of the Identity Platform tenant the user is signing in to. If not
set, the user will sign in to the default Identity Platform project.

=back

=head2 Google::Cloud::Identitytoolkit::V2::AuthenticationService::FinalizeMfaSignInResponse

FinalizeMfaSignIn response.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->id_token() >> / C<< $msg->id_token($value) >>

Type: C<String>

ID token for the authenticated user.

=item * C<< $msg->refresh_token() >> / C<< $msg->refresh_token($value) >>

Type: C<String>

Refresh token for the authenticated user.

=item * C<< $msg->phone_auth_info() >> / C<< $msg->phone_auth_info($value) >>

Type: C<Message> (L<Google::Cloud::Identitytoolkit::V2::MfaInfo::FinalizeMfaPhoneResponseInfo>)

Extra phone auth info, including android verification proof.

=back

=head2 Google::Cloud::Identitytoolkit::V2::AuthenticationService::StartMfaSignInRequest

Starts multi-factor sign-in by sending the multi-factor auth challenge.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->mfa_pending_credential() >> / C<< $msg->mfa_pending_credential($value) >>

Type: C<String>

Required. Pending credential from first factor sign-in.

=item * C<< $msg->mfa_enrollment_id() >> / C<< $msg->mfa_enrollment_id($value) >>

Type: C<String>

Required. MFA enrollment id from the user's list of current MFA enrollments.

=item * C<< $msg->phone_sign_in_info() >> / C<< $msg->phone_sign_in_info($value) >>

Type: C<Message> (L<Google::Cloud::Identitytoolkit::V2::MfaInfo::StartMfaPhoneRequestInfo>)

Verification info to authorize sending an SMS for phone verification.

=item * C<< $msg->tenant_id() >> / C<< $msg->tenant_id($value) >>

Type: C<String>

The ID of the Identity Platform tenant the user is signing in to. If not
set, the user will sign in to the default Identity Platform project.

=back

=head2 Google::Cloud::Identitytoolkit::V2::AuthenticationService::StartMfaSignInResponse

StartMfaSignIn response.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->phone_response_info() >> / C<< $msg->phone_response_info($value) >>

Type: C<Message> (L<Google::Cloud::Identitytoolkit::V2::MfaInfo::StartMfaPhoneResponseInfo>)

MultiFactor sign-in session information specific to SMS-type second
factors. Along with the one-time code retrieved from the sent SMS, the
contents of this session information should be passed to
FinalizeMfaSignIn to complete the sign in.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Identitytoolkit::V2::AuthenticationService::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
