package Google::Cloud::Ces::V1::WidgetService;

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
Cihnb29nbGUvY2xvdWQvY2VzL3YxL3dpZGdldF9zZXJ2aWNlLnByb3RvEhNnb29nbGUuY2xv
dWQuY2VzLnYxGhxnb29nbGUvYXBpL2Fubm90YXRpb25zLnByb3RvGhdnb29nbGUvYXBpL2Ns
aWVudC5wcm90bxofZ29vZ2xlL2FwaS9maWVsZF9iZWhhdmlvci5wcm90bxoZZ29vZ2xlL2Fw
aS9yZXNvdXJjZS5wcm90bxofZ29vZ2xlL3Byb3RvYnVmL3RpbWVzdGFtcC5wcm90byL+AQoY
R2VuZXJhdGVDaGF0VG9rZW5SZXF1ZXN0EjYKBG5hbWUYASABKAlCIuBBAvpBHAoaY2VzLmdv
b2dsZWFwaXMuY29tL1Nlc3Npb25SBG5hbWUSRQoKZGVwbG95bWVudBgCIAEoCUIl4EEC+kEf
Ch1jZXMuZ29vZ2xlYXBpcy5jb20vRGVwbG95bWVudFIKZGVwbG95bWVudBIsCg9yZWNhcHRj
aGFfdG9rZW4YAyABKAlCA+BBAVIOcmVjYXB0Y2hhVG9rZW4SNQoUbGl2ZV9oYW5kb2ZmX2Vu
YWJsZWQYBCABKAhCA+BBAVISbGl2ZUhhbmRvZmZFbmFibGVkIncKGUdlbmVyYXRlQ2hhdFRv
a2VuUmVzcG9uc2USHQoKY2hhdF90b2tlbhgBIAEoCVIJY2hhdFRva2VuEjsKC2V4cGlyZV90
aW1lGAIgASgLMhouZ29vZ2xlLnByb3RvYnVmLlRpbWVzdGFtcFIKZXhwaXJlVGltZTLCAgoN
V2lkZ2V0U2VydmljZRLEAQoRR2VuZXJhdGVDaGF0VG9rZW4SLS5nb29nbGUuY2xvdWQuY2Vz
LnYxLkdlbmVyYXRlQ2hhdFRva2VuUmVxdWVzdBouLmdvb2dsZS5jbG91ZC5jZXMudjEuR2Vu
ZXJhdGVDaGF0VG9rZW5SZXNwb25zZSJQgtPkkwJKIkUvdjEve25hbWU9cHJvamVjdHMvKi9s
b2NhdGlvbnMvKi9hcHBzLyovc2Vzc2lvbnMvKn06Z2VuZXJhdGVDaGF0VG9rZW46ASoaaspB
EmNlcy5nb29nbGVhcGlzLmNvbdJBUmh0dHBzOi8vd3d3Lmdvb2dsZWFwaXMuY29tL2F1dGgv
Y2VzLGh0dHBzOi8vd3d3Lmdvb2dsZWFwaXMuY29tL2F1dGgvY2xvdWQtcGxhdGZvcm1CWgoX
Y29tLmdvb2dsZS5jbG91ZC5jZXMudjFCEldpZGdldFNlcnZpY2VQcm90b1ABWiljbG91ZC5n
b29nbGUuY29tL2dvL2Nlcy9hcGl2MS9jZXNwYjtjZXNwYkrAEgoGEgQOAFEBCrwECgEMEgMO
ABIysQQgQ29weXJpZ2h0IDIwMjYgR29vZ2xlIExMQwoKIExpY2Vuc2VkIHVuZGVyIHRoZSBB
cGFjaGUgTGljZW5zZSwgVmVyc2lvbiAyLjAgKHRoZSAiTGljZW5zZSIpOwogeW91IG1heSBu
b3QgdXNlIHRoaXMgZmlsZSBleGNlcHQgaW4gY29tcGxpYW5jZSB3aXRoIHRoZSBMaWNlbnNl
LgogWW91IG1heSBvYnRhaW4gYSBjb3B5IG9mIHRoZSBMaWNlbnNlIGF0CgogICAgIGh0dHA6
Ly93d3cuYXBhY2hlLm9yZy9saWNlbnNlcy9MSUNFTlNFLTIuMAoKIFVubGVzcyByZXF1aXJl
ZCBieSBhcHBsaWNhYmxlIGxhdyBvciBhZ3JlZWQgdG8gaW4gd3JpdGluZywgc29mdHdhcmUK
IGRpc3RyaWJ1dGVkIHVuZGVyIHRoZSBMaWNlbnNlIGlzIGRpc3RyaWJ1dGVkIG9uIGFuICJB
UyBJUyIgQkFTSVMsCiBXSVRIT1VUIFdBUlJBTlRJRVMgT1IgQ09ORElUSU9OUyBPRiBBTlkg
S0lORCwgZWl0aGVyIGV4cHJlc3Mgb3IgaW1wbGllZC4KIFNlZSB0aGUgTGljZW5zZSBmb3Ig
dGhlIHNwZWNpZmljIGxhbmd1YWdlIGdvdmVybmluZyBwZXJtaXNzaW9ucyBhbmQKIGxpbWl0
YXRpb25zIHVuZGVyIHRoZSBMaWNlbnNlLgoKCAoBAhIDEAAcCgkKAgMAEgMSACYKCQoCAwES
AxMAIQoJCgIDAhIDFAApCgkKAgMDEgMVACMKCQoCAwQSAxYAKQoICgEIEgMYAEAKCQoCCAsS
AxgAQAoICgEIEgMZACIKCQoCCAoSAxkAIgoICgEIEgMaADMKCQoCCAgSAxoAMwoICgEIEgMb
ADAKCQoCCAESAxsAMApCCgIGABIEHgAtARo2IFByb3ZpZGVzIEFQSXMgZm9yIHdpZGdldHMg
dG8gaW50ZXJhY3Qgd2l0aCBDRVMgQVBJcy4KCgoKAwYAARIDHggVCgoKAwYAAxIDHwI6CgwK
BQYAA5kIEgMfAjoKCwoDBgADEgQgAiI3Cg0KBQYAA5oIEgQgAiI3CmQKBAYAAgASBCYCLAMa
ViBHZW5lcmF0ZXMgYSBzZXNzaW9uIHNjb3BlZCB0b2tlbiBmb3IgY2hhdCB3aWRnZXQgdG8g
YXV0aGVudGljYXRlIHdpdGgKIFNlc3Npb24gQVBJcy4KCgwKBQYAAgABEgMmBhcKDAoFBgAC
AAISAyYYMAoMCgUGAAIAAxIDJw8oCg0KBQYAAgAEEgQoBCsGChEKCQYAAgAEsMq8IhIEKAQr
Bgp6CgIEABIEMQBHARpuIFJlcXVlc3QgbWVzc2FnZSBmb3IKIFtXaWRnZXRTZXJ2aWNlLkdl
bmVyYXRlQ2hhdFRva2VuXVtnb29nbGUuY2xvdWQuY2VzLnYxLldpZGdldFNlcnZpY2UuR2Vu
ZXJhdGVDaGF0VG9rZW5dLgoKCgoDBAABEgMxCCAKmwEKBAQAAgASBDUCOAQajAEgUmVxdWly
ZWQuIFRoZSBzZXNzaW9uIG5hbWUgdG8gZ2VuZXJhdGUgdGhlIGNoYXQgdG9rZW4gZm9yLgog
Rm9ybWF0OgogcHJvamVjdHMve3Byb2plY3R9L2xvY2F0aW9ucy97bG9jYXRpb259L2FwcHMv
e2FwcH0vc2Vzc2lvbnMve3Nlc3Npb259CgoMCgUEAAIABRIDNQIICgwKBQQAAgABEgM1CQ0K
DAoFBAACAAMSAzUQEQoNCgUEAAIACBIENRI4AwoPCggEAAIACJwIABIDNgQqCg4KBwQAAgAI
nwgSAzcETAqiAQoEBAACARIEPQJABBqTASBSZXF1aXJlZC4gVGhlIGRlcGxveW1lbnQgb2Yg
dGhlIGFwcCB0byB1c2UgZm9yIHRoZSBzZXNzaW9uLgogRm9ybWF0OgogcHJvamVjdHMve3By
b2plY3R9L2xvY2F0aW9ucy97bG9jYXRpb259L2FwcHMve2FwcH0vZGVwbG95bWVudHMve2Rl
cGxveW1lbnR9CgoMCgUEAAIBBRIDPQIICgwKBQQAAgEBEgM9CRMKDAoFBAACAQMSAz0WFwoN
CgUEAAIBCBIEPRhAAwoPCggEAAIBCJwIABIDPgQqCg4KBwQAAgEInwgSAz8ETwpWCgQEAAIC
EgNDAkYaSSBPcHRpb25hbC4gVGhlIHJlQ0FQVENIQSB0b2tlbiBnZW5lcmF0ZWQgYnkgdGhl
IGNsaWVudC1zaWRlIGNoYXQgd2lkZ2V0LgoKDAoFBAACAgUSA0MCCAoMCgUEAAICARIDQwkY
CgwKBQQAAgIDEgNDGxwKDAoFBAACAggSA0MdRQoPCggEAAICCJwIABIDQx5ECk4KBAQAAgMS
A0YCSRpBIE9wdGlvbmFsLiBJbmRpY2F0ZXMgaWYgbGl2ZSBoYW5kb2ZmIGlzIGVuYWJsZWQg
Zm9yIHRoZSBzZXNzaW9uLgoKDAoFBAACAwUSA0YCBgoMCgUEAAIDARIDRgcbCgwKBQQAAgMD
EgNGHh8KDAoFBAACAwgSA0YgSAoPCggEAAIDCJwIABIDRiFHCnsKAgQBEgRLAFEBGm8gUmVz
cG9uc2UgbWVzc2FnZSBmb3IKIFtXaWRnZXRTZXJ2aWNlLkdlbmVyYXRlQ2hhdFRva2VuXVtn
b29nbGUuY2xvdWQuY2VzLnYxLldpZGdldFNlcnZpY2UuR2VuZXJhdGVDaGF0VG9rZW5dLgoK
CgoDBAEBEgNLCCEKWgoEBAECABIDTQIYGk0gVGhlIHNlc3Npb24gc2NvcGVkIHRva2VuIGZv
ciBjaGF0IHdpZGdldCB0byBhdXRoZW50aWNhdGUgd2l0aCBTZXNzaW9uIEFQSXMuCgoMCgUE
AQIABRIDTQIICgwKBQQBAgABEgNNCRMKDAoFBAECAAMSA00WFwo4CgQEAQIBEgNQAiwaKyBU
aGUgdGltZSBhdCB3aGljaCB0aGUgY2hhdCB0b2tlbiBleHBpcmVzLgoKDAoFBAECAQYSA1AC
GwoMCgUEAQIBARIDUBwnCgwKBQQBAgEDEgNQKitiBnByb3RvMw==
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Ces::V1::WidgetService::GenerateChatTokenRequest ===
    # Fields for GenerateChatTokenRequest
    # Field: name Type: 9 ()
    # Field: deployment Type: 9 ()
    # Field: recaptcha_token Type: 9 ()
    # Field: live_handoff_enabled Type: 8 ()

# === Message: Google::Cloud::Ces::V1::WidgetService::GenerateChatTokenResponse ===
    # Fields for GenerateChatTokenResponse
    # Field: chat_token Type: 9 ()
    # Field: expire_time Type: 11 (.google.protobuf.Timestamp)

# === Service Client: Google::Cloud::Ces::V1::WidgetService::WidgetServiceClient ===
package Google::Cloud::Ces::V1::WidgetService::WidgetServiceClient;

=pod

=head2 Service Client: Google::Cloud::Ces::V1::WidgetService::WidgetServiceClient

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
        ? Google::Cloud::Ces::V1::WidgetService::GenerateChatTokenRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.ces.v1.WidgetService',
        method         => 'GenerateChatToken',
        request        => $req,
        response_class => 'Google::Cloud::Ces::V1::WidgetService::GenerateChatTokenResponse',
    });
}

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Ces::V1::WidgetService - Compiled Protocol Buffers messages for google/cloud/ces/v1/widget_service.proto

=head1 SYNOPSIS

    use Google::Cloud::Ces::V1::WidgetService;

    my $msg = Google::Cloud::Ces::V1::WidgetService::GenerateChatTokenRequest->new({
        name => $name,
        deployment => $deployment,
        recaptcha_token => $recaptcha_token,
        live_handoff_enabled => $live_handoff_enabled,
    });

    # Read or update a field
    my $val = $msg->name();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Ces::V1::WidgetService::GenerateChatTokenRequest->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/ces/v1/widget_service.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Ces::V1::WidgetService::GenerateChatTokenRequest

Request message for
[WidgetService.GenerateChatToken][google.cloud.ces.v1.WidgetService.GenerateChatToken].

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

=head2 Google::Cloud::Ces::V1::WidgetService::GenerateChatTokenResponse

Response message for
[WidgetService.GenerateChatToken][google.cloud.ces.v1.WidgetService.GenerateChatToken].

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

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Ces::V1::WidgetService::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
