package Google::Cloud::Ces::V1beta::WidgetService;

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
    eval { require Google::Protobuf::Timestamp };
    my $descriptor_b64 = <<'EOF';
Cixnb29nbGUvY2xvdWQvY2VzL3YxYmV0YS93aWRnZXRfc2VydmljZS5wcm90bxIXZ29vZ2xl
LmNsb3VkLmNlcy52MWJldGEaHGdvb2dsZS9hcGkvYW5ub3RhdGlvbnMucHJvdG8aF2dvb2ds
ZS9hcGkvY2xpZW50LnByb3RvGh9nb29nbGUvYXBpL2ZpZWxkX2JlaGF2aW9yLnByb3RvGhln
b29nbGUvYXBpL3Jlc291cmNlLnByb3RvGh9nb29nbGUvcHJvdG9idWYvdGltZXN0YW1wLnBy
b3RvIv4BChhHZW5lcmF0ZUNoYXRUb2tlblJlcXVlc3QSNgoEbmFtZRgBIAEoCUIi4EEC+kEc
ChpjZXMuZ29vZ2xlYXBpcy5jb20vU2Vzc2lvblIEbmFtZRJFCgpkZXBsb3ltZW50GAIgASgJ
QiXgQQL6QR8KHWNlcy5nb29nbGVhcGlzLmNvbS9EZXBsb3ltZW50UgpkZXBsb3ltZW50EiwK
D3JlY2FwdGNoYV90b2tlbhgDIAEoCUID4EEBUg5yZWNhcHRjaGFUb2tlbhI1ChRsaXZlX2hh
bmRvZmZfZW5hYmxlZBgEIAEoCEID4EEBUhJsaXZlSGFuZG9mZkVuYWJsZWQidwoZR2VuZXJh
dGVDaGF0VG9rZW5SZXNwb25zZRIdCgpjaGF0X3Rva2VuGAEgASgJUgljaGF0VG9rZW4SOwoL
ZXhwaXJlX3RpbWUYAiABKAsyGi5nb29nbGUucHJvdG9idWYuVGltZXN0YW1wUgpleHBpcmVU
aW1lMs4CCg1XaWRnZXRTZXJ2aWNlEtABChFHZW5lcmF0ZUNoYXRUb2tlbhIxLmdvb2dsZS5j
bG91ZC5jZXMudjFiZXRhLkdlbmVyYXRlQ2hhdFRva2VuUmVxdWVzdBoyLmdvb2dsZS5jbG91
ZC5jZXMudjFiZXRhLkdlbmVyYXRlQ2hhdFRva2VuUmVzcG9uc2UiVILT5JMCTiJJL3YxYmV0
YS97bmFtZT1wcm9qZWN0cy8qL2xvY2F0aW9ucy8qL2FwcHMvKi9zZXNzaW9ucy8qfTpnZW5l
cmF0ZUNoYXRUb2tlbjoBKhpqykESY2VzLmdvb2dsZWFwaXMuY29t0kFSaHR0cHM6Ly93d3cu
Z29vZ2xlYXBpcy5jb20vYXV0aC9jZXMsaHR0cHM6Ly93d3cuZ29vZ2xlYXBpcy5jb20vYXV0
aC9jbG91ZC1wbGF0Zm9ybUJiChtjb20uZ29vZ2xlLmNsb3VkLmNlcy52MWJldGFCEldpZGdl
dFNlcnZpY2VQcm90b1ABWi1jbG91ZC5nb29nbGUuY29tL2dvL2Nlcy9hcGl2MWJldGEvY2Vz
cGI7Y2VzcGJKyBIKBhIEDgBRAQq8BAoBDBIDDgASMrEEIENvcHlyaWdodCAyMDI2IEdvb2ds
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
CggKAQISAxAAIAoJCgIDABIDEgAmCgkKAgMBEgMTACEKCQoCAwISAxQAKQoJCgIDAxIDFQAj
CgkKAgMEEgMWACkKCAoBCBIDGABECgkKAggLEgMYAEQKCAoBCBIDGQAiCgkKAggKEgMZACIK
CAoBCBIDGgAzCgkKAggIEgMaADMKCAoBCBIDGwA0CgkKAggBEgMbADQKQgoCBgASBB4ALQEa
NiBQcm92aWRlcyBBUElzIGZvciB3aWRnZXRzIHRvIGludGVyYWN0IHdpdGggQ0VTIEFQSXMu
CgoKCgMGAAESAx4IFQoKCgMGAAMSAx8COgoMCgUGAAOZCBIDHwI6CgsKAwYAAxIEIAIiNwoN
CgUGAAOaCBIEIAIiNwpkCgQGAAIAEgQmAiwDGlYgR2VuZXJhdGVzIGEgc2Vzc2lvbiBzY29w
ZWQgdG9rZW4gZm9yIGNoYXQgd2lkZ2V0IHRvIGF1dGhlbnRpY2F0ZSB3aXRoCiBTZXNzaW9u
IEFQSXMuCgoMCgUGAAIAARIDJgYXCgwKBQYAAgACEgMmGDAKDAoFBgACAAMSAycPKAoNCgUG
AAIABBIEKAQrBgoRCgkGAAIABLDKvCISBCgEKwYKfgoCBAASBDEARwEaciBSZXF1ZXN0IG1l
c3NhZ2UgZm9yCiBbV2lkZ2V0U2VydmljZS5HZW5lcmF0ZUNoYXRUb2tlbl1bZ29vZ2xlLmNs
b3VkLmNlcy52MWJldGEuV2lkZ2V0U2VydmljZS5HZW5lcmF0ZUNoYXRUb2tlbl0uCgoKCgME
AAESAzEIIAqbAQoEBAACABIENQI4BBqMASBSZXF1aXJlZC4gVGhlIHNlc3Npb24gbmFtZSB0
byBnZW5lcmF0ZSB0aGUgY2hhdCB0b2tlbiBmb3IuCiBGb3JtYXQ6CiBwcm9qZWN0cy97cHJv
amVjdH0vbG9jYXRpb25zL3tsb2NhdGlvbn0vYXBwcy97YXBwfS9zZXNzaW9ucy97c2Vzc2lv
bn0KCgwKBQQAAgAFEgM1AggKDAoFBAACAAESAzUJDQoMCgUEAAIAAxIDNRARCg0KBQQAAgAI
EgQ1EjgDCg8KCAQAAgAInAgAEgM2BCoKDgoHBAACAAifCBIDNwRMCqIBCgQEAAIBEgQ9AkAE
GpMBIFJlcXVpcmVkLiBUaGUgZGVwbG95bWVudCBvZiB0aGUgYXBwIHRvIHVzZSBmb3IgdGhl
IHNlc3Npb24uCiBGb3JtYXQ6CiBwcm9qZWN0cy97cHJvamVjdH0vbG9jYXRpb25zL3tsb2Nh
dGlvbn0vYXBwcy97YXBwfS9kZXBsb3ltZW50cy97ZGVwbG95bWVudH0KCgwKBQQAAgEFEgM9
AggKDAoFBAACAQESAz0JEwoMCgUEAAIBAxIDPRYXCg0KBQQAAgEIEgQ9GEADCg8KCAQAAgEI
nAgAEgM+BCoKDgoHBAACAQifCBIDPwRPClYKBAQAAgISA0MCRhpJIE9wdGlvbmFsLiBUaGUg
cmVDQVBUQ0hBIHRva2VuIGdlbmVyYXRlZCBieSB0aGUgY2xpZW50LXNpZGUgY2hhdCB3aWRn
ZXQuCgoMCgUEAAICBRIDQwIICgwKBQQAAgIBEgNDCRgKDAoFBAACAgMSA0MbHAoMCgUEAAIC
CBIDQx1FCg8KCAQAAgIInAgAEgNDHkQKTgoEBAACAxIDRgJJGkEgT3B0aW9uYWwuIEluZGlj
YXRlcyBpZiBsaXZlIGhhbmRvZmYgaXMgZW5hYmxlZCBmb3IgdGhlIHNlc3Npb24uCgoMCgUE
AAIDBRIDRgIGCgwKBQQAAgMBEgNGBxsKDAoFBAACAwMSA0YeHwoMCgUEAAIDCBIDRiBICg8K
CAQAAgMInAgAEgNGIUcKfwoCBAESBEsAUQEacyBSZXNwb25zZSBtZXNzYWdlIGZvcgogW1dp
ZGdldFNlcnZpY2UuR2VuZXJhdGVDaGF0VG9rZW5dW2dvb2dsZS5jbG91ZC5jZXMudjFiZXRh
LldpZGdldFNlcnZpY2UuR2VuZXJhdGVDaGF0VG9rZW5dLgoKCgoDBAEBEgNLCCEKWgoEBAEC
ABIDTQIYGk0gVGhlIHNlc3Npb24gc2NvcGVkIHRva2VuIGZvciBjaGF0IHdpZGdldCB0byBh
dXRoZW50aWNhdGUgd2l0aCBTZXNzaW9uIEFQSXMuCgoMCgUEAQIABRIDTQIICgwKBQQBAgAB
EgNNCRMKDAoFBAECAAMSA00WFwo4CgQEAQIBEgNQAiwaKyBUaGUgdGltZSBhdCB3aGljaCB0
aGUgY2hhdCB0b2tlbiBleHBpcmVzLgoKDAoFBAECAQYSA1ACGwoMCgUEAQIBARIDUBwnCgwK
BQQBAgEDEgNQKitiBnByb3RvMw==
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Ces::V1beta::WidgetService::GenerateChatTokenRequest ===
    # Fields for GenerateChatTokenRequest
    # Field: name Type: 9 ()
    # Field: deployment Type: 9 ()
    # Field: recaptcha_token Type: 9 ()
    # Field: live_handoff_enabled Type: 8 ()

# === Message: Google::Cloud::Ces::V1beta::WidgetService::GenerateChatTokenResponse ===
    # Fields for GenerateChatTokenResponse
    # Field: chat_token Type: 9 ()
    # Field: expire_time Type: 11 (.google.protobuf.Timestamp)

# === Service Client: Google::Cloud::Ces::V1beta::WidgetService::WidgetServiceClient ===
package Google::Cloud::Ces::V1beta::WidgetService::WidgetServiceClient;

=pod

=head2 Service Client: Google::Cloud::Ces::V1beta::WidgetService::WidgetServiceClient

Client stub representing the remote C<WidgetService> gRPC service. Delegates call dispatching to L<Google::gRPC::Client>.

=head3 target

The endpoint target address. Defaults to C<ces.googleapis.com:443>.

=head3 credentials

The authentication credentials provider. Defaults to application default credentials via L<Google::Auth>.

=cut

use Moo;
use Google::Auth;
use Google::gRPC::Client;

has credentials => ( is => 'ro', default => sub { Google::Auth->default() } );
has target      => ( is => 'ro', default => 'ces.googleapis.com:443' );

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

sub generate_chat_token {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Ces::V1beta::WidgetService::GenerateChatTokenRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.ces.v1beta.WidgetService',
        method         => 'GenerateChatToken',
        request        => $req,
        response_class => 'Google::Cloud::Ces::V1beta::WidgetService::GenerateChatTokenResponse',
    });
}

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Ces::V1beta::WidgetService - Compiled Protocol Buffers messages for google/cloud/ces/v1beta/widget_service.proto

=head1 SYNOPSIS

    use Google::Cloud::Ces::V1beta::WidgetService;

    my $msg = Google::Cloud::Ces::V1beta::WidgetService::GenerateChatTokenRequest->new({
        name => $name,
        deployment => $deployment,
        recaptcha_token => $recaptcha_token,
        live_handoff_enabled => $live_handoff_enabled,
    });

    # Read or update a field
    my $val = $msg->name();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Ces::V1beta::WidgetService::GenerateChatTokenRequest->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/ces/v1beta/widget_service.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Ces::V1beta::WidgetService::GenerateChatTokenRequest

Request message for
[WidgetService.GenerateChatToken][google.cloud.ces.v1beta.WidgetService.GenerateChatToken].

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. The session name to generate the chat token for.
Format:
projects/{project}/locations/{location}/apps/{app}/sessions/{session}

=item * C<< $msg->deployment() >> / C<< $msg->deployment($value) >>

Type: C<String>

Required. The deployment of the app to use for the session.
Format:
projects/{project}/locations/{location}/apps/{app}/deployments/{deployment}

=item * C<< $msg->recaptcha_token() >> / C<< $msg->recaptcha_token($value) >>

Type: C<String>

Optional. The reCAPTCHA token generated by the client-side chat widget.

=item * C<< $msg->live_handoff_enabled() >> / C<< $msg->live_handoff_enabled($value) >>

Type: C<Bool>

Optional. Indicates if live handoff is enabled for the session.

=back

=head2 Google::Cloud::Ces::V1beta::WidgetService::GenerateChatTokenResponse

Response message for
[WidgetService.GenerateChatToken][google.cloud.ces.v1beta.WidgetService.GenerateChatToken].

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->chat_token() >> / C<< $msg->chat_token($value) >>

Type: C<String>

The session scoped token for chat widget to authenticate with Session APIs.

=item * C<< $msg->expire_time() >> / C<< $msg->expire_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

The time at which the chat token expires.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Ces::V1beta::WidgetService::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
