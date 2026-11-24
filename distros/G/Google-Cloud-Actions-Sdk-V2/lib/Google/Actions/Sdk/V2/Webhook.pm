package Google::Actions::Sdk::V2::Webhook;

use strict;
use warnings;

our $VERSION = '0.14';

use Protobuf::Message;
use Protobuf::DescriptorPool;
use Protobuf::Internal qw(:all);
use MIME::Base64;

BEGIN {
    eval { require Google::Api::FieldBehavior };
    my $descriptor_b64 = <<'EOF';
CiNnb29nbGUvYWN0aW9ucy9zZGsvdjIvd2ViaG9vay5wcm90bxIVZ29vZ2xlLmFjdGlvbnMu
c2RrLnYyGh9nb29nbGUvYXBpL2ZpZWxkX2JlaGF2aW9yLnByb3RvIoUFCgdXZWJob29rEkIK
CGhhbmRsZXJzGAEgAygLMiYuZ29vZ2xlLmFjdGlvbnMuc2RrLnYyLldlYmhvb2suSGFuZGxl
clIIaGFuZGxlcnMSVQoOaHR0cHNfZW5kcG9pbnQYAiABKAsyLC5nb29nbGUuYWN0aW9ucy5z
ZGsudjIuV2ViaG9vay5IdHRwc0VuZHBvaW50SABSDWh0dHBzRW5kcG9pbnQSaAoVaW5saW5l
X2Nsb3VkX2Z1bmN0aW9uGAMgASgLMjIuZ29vZ2xlLmFjdGlvbnMuc2RrLnYyLldlYmhvb2su
SW5saW5lQ2xvdWRGdW5jdGlvbkgAUhNpbmxpbmVDbG91ZEZ1bmN0aW9uGiIKB0hhbmRsZXIS
FwoEbmFtZRgBIAEoCUID4EECUgRuYW1lGv4BCg1IdHRwc0VuZHBvaW50EhkKCGJhc2VfdXJs
GAEgASgJUgdiYXNlVXJsEmAKDGh0dHBfaGVhZGVycxgCIAMoCzI9Lmdvb2dsZS5hY3Rpb25z
LnNkay52Mi5XZWJob29rLkh0dHBzRW5kcG9pbnQuSHR0cEhlYWRlcnNFbnRyeVILaHR0cEhl
YWRlcnMSMAoUZW5kcG9pbnRfYXBpX3ZlcnNpb24YAyABKAVSEmVuZHBvaW50QXBpVmVyc2lv
bho+ChBIdHRwSGVhZGVyc0VudHJ5EhAKA2tleRgBIAEoCVIDa2V5EhQKBXZhbHVlGAIgASgJ
UgV2YWx1ZToCOAEaQAoTSW5saW5lQ2xvdWRGdW5jdGlvbhIpChBleGVjdXRlX2Z1bmN0aW9u
GAEgASgJUg9leGVjdXRlRnVuY3Rpb25CDgoMd2ViaG9va190eXBlQmUKGWNvbS5nb29nbGUu
YWN0aW9ucy5zZGsudjJCDFdlYmhvb2tQcm90b1ABWjhnb29nbGUuZ29sYW5nLm9yZy9nZW5w
cm90by9nb29nbGVhcGlzL2FjdGlvbnMvc2RrL3YyO3Nka0r0GAoGEgQOAFEBCrwECgEMEgMO
ABIysQQgQ29weXJpZ2h0IDIwMjUgR29vZ2xlIExMQwoKIExpY2Vuc2VkIHVuZGVyIHRoZSBB
cGFjaGUgTGljZW5zZSwgVmVyc2lvbiAyLjAgKHRoZSAiTGljZW5zZSIpOwogeW91IG1heSBu
b3QgdXNlIHRoaXMgZmlsZSBleGNlcHQgaW4gY29tcGxpYW5jZSB3aXRoIHRoZSBMaWNlbnNl
LgogWW91IG1heSBvYnRhaW4gYSBjb3B5IG9mIHRoZSBMaWNlbnNlIGF0CgogICAgIGh0dHA6
Ly93d3cuYXBhY2hlLm9yZy9saWNlbnNlcy9MSUNFTlNFLTIuMAoKIFVubGVzcyByZXF1aXJl
ZCBieSBhcHBsaWNhYmxlIGxhdyBvciBhZ3JlZWQgdG8gaW4gd3JpdGluZywgc29mdHdhcmUK
IGRpc3RyaWJ1dGVkIHVuZGVyIHRoZSBMaWNlbnNlIGlzIGRpc3RyaWJ1dGVkIG9uIGFuICJB
UyBJUyIgQkFTSVMsCiBXSVRIT1VUIFdBUlJBTlRJRVMgT1IgQ09ORElUSU9OUyBPRiBBTlkg
S0lORCwgZWl0aGVyIGV4cHJlc3Mgb3IgaW1wbGllZC4KIFNlZSB0aGUgTGljZW5zZSBmb3Ig
dGhlIHNwZWNpZmljIGxhbmd1YWdlIGdvdmVybmluZyBwZXJtaXNzaW9ucyBhbmQKIGxpbWl0
YXRpb25zIHVuZGVyIHRoZSBMaWNlbnNlLgoKCAoBAhIDEAAeCgkKAgMAEgMSACkKCAoBCBID
FABPCgkKAggLEgMUAE8KCAoBCBIDFQAiCgkKAggKEgMVACIKCAoBCBIDFgAtCgkKAggIEgMW
AC0KCAoBCBIDFwAyCgkKAggBEgMXADIKnwMKAgQAEgQhAFEBGpIDIE1ldGFkYXRhIGZvciBk
aWZmZXJlbnQgdHlwZXMgb2Ygd2ViaG9va3MuIElmIHlvdSdyZSB1c2luZwogYGlubGluZUNs
b3VkRnVuY3Rpb25gLCB5b3VyIHNvdXJjZSBjb2RlIG11c3QgYmUgaW4gYSBkaXJlY3Rvcnkg
d2l0aCB0aGUgc2FtZQogbmFtZSBhcyB0aGUgdmFsdWUgZm9yIHRoZSBgZXhlY3V0ZUZ1bmN0
aW9uYCBrZXkuCiBGb3IgZXhhbXBsZSwgYSB2YWx1ZSBvZiBgbXlfd2ViaG9va2AgZm9yIHRo
ZWBleGVjdXRlRnVuY3Rpb25gIGtleSB3b3VsZCBoYXZlCiBhIGNvZGUgc3RydWN0dXJlIGxp
a2UgdGhpczoKICAtIGAvd2ViaG9va3MvbXlfd2ViaG9vay55YW1sYAogIC0gYC93ZWJob29r
cy9teV93ZWJob29rL2luZGV4LmpzYAogIC0gYC93ZWJob29rcy9teV93ZWJob29rL3BhY2th
Z2UuanNvbmAKCgoKAwQAARIDIQgPCrkBCgQEAAMAEgQlAioDGqoBIERlY2xhcmVzIHRoZSBu
YW1lIG9mIHRoZSB3ZWJob29vayBoYW5kbGVyLiBBIHdlYmhvb2sgY2FuIGhhdmUKIG11bHRp
cGxlIGhhbmRsZXJzIHJlZ2lzdGVyZWQuIFRoZXNlIGhhbmRsZXJzIGNhbiBiZSBjYWxsZWQg
ZnJvbSBtdWx0aXBsZQogcGxhY2VzIGluIHlvdXIgQWN0aW9ucyBwcm9qZWN0LgoKDAoFBAAD
AAESAyUKEQrRAQoGBAADAAIAEgMpBD0awQEgUmVxdWlyZWQuIE5hbWUgb2YgdGhlIGhhbmRs
ZXIuIE11c3QgYmUgdW5pcXVlIGFjcm9zcyBhbGwgaGFuZGxlcnMgdGhlIEFjdGlvbnMKIHBy
b2plY3QuIFlvdSBjYW4gY2hlY2sgdGhlIG5hbWUgb2YgdGhpcyBoYW5kbGVyIHRvIGludm9r
ZSB0aGUgY29ycmVjdAogZnVuY3Rpb24gaW4geW91ciBmdWxmaWxsbWVudCBzb3VyY2UgY29k
ZS4KCg4KBwQAAwACAAUSAykECgoOCgcEAAMAAgABEgMpCw8KDgoHBAADAAIAAxIDKRITCg4K
BwQAAwACAAgSAykUPAoRCgoEAAMAAgAInAgAEgMpFTsKTgoEBAADARIELQI8AxpAIFJFU1Qg
ZW5kcG9pbnQgdG8gbm90aWZ5IGlmIHlvdSdyZSBub3QgdXNpbmcgdGhlIGlubGluZSBlZGl0
b3IuCgoMCgUEAAMBARIDLQoXCvwCCgYEAAMBAgASAzQEGBrsAiBUaGUgSFRUUFMgYmFzZSBV
UkwgZm9yIHlvdXIgZnVsZmlsbG1lbnQgZW5kcG9pbnQgKEhUVFAgaXMgbm90IHN1cHBvcnRl
ZCkuCiBIYW5kbGVyIG5hbWVzIGFyZSBhcHBlbmRlZCB0byB0aGUgYmFzZSBVUkwgcGF0aCBh
ZnRlciBhIGNvbG9uCiAoZm9sbG93aW5nIHRoZSBzdHlsZSBndWlkZSBpbgogaHR0cHM6Ly9j
bG91ZC5nb29nbGUuY29tL2FwaXMvZGVzaWduL2N1c3RvbV9tZXRob2RzKS4KIEZvciBleGFt
cGxlIGEgYmFzZSBVUkwgb2YgJ2h0dHBzOi8vZ2FjdGlvbnMuc2VydmljZS5jb20vYXBpJyB3
b3VsZAogcmVjZWl2ZSByZXF1ZXN0cyB3aXRoIFVSTCAnaHR0cHM6Ly9nYWN0aW9ucy5zZXJ2
aWNlLmNvbS9hcGk6e21ldGhvZH0nLgoKDgoHBAADAQIABRIDNAQKCg4KBwQAAwECAAESAzQL
EwoOCgcEAAMBAgADEgM0FhcKSwoGBAADAQIBEgM3BCkaPCBNYXAgb2YgSFRUUCBwYXJhbWV0
ZXJzIHRvIGJlIGluY2x1ZGVkIGluIHRoZSBQT1NUIHJlcXVlc3QuCgoOCgcEAAMBAgEGEgM3
BBcKDgoHBAADAQIBARIDNxgkCg4KBwQAAwECAQMSAzcnKAqiAQoGBAADAQICEgM7BCMakgEg
VmVyc2lvbiBvZiB0aGUgcHJvdG9jb2wgdXNlZCBieSB0aGUgZW5kcG9pbnQuIFRoaXMgaXMg
dGhlIHByb3RvY29sIHNoYXJlZAogYnkgYWxsIGZ1bGZpbGxtZW50IHR5cGVzIGFuZCBub3Qg
c3BlY2lmaWMgdG8gR29vZ2xlIGZ1bGZpbGxtZW50IHR5cGUuCgoOCgcEAAMBAgIFEgM7BAkK
DgoHBAADAQICARIDOwoeCg4KBwQAAwECAgMSAzshIgpiCgQEAAMCEgRAAkQDGlQgSG9sZHMg
dGhlIG1ldGFkYXRhIG9mIGFuIGlubGluZSBDbG91ZCBGdW5jdGlvbiBkZXBsb3llZCBmcm9t
IHRoZQogd2ViaG9va3MgZm9sZGVyLgoKDAoFBAADAgESA0AKHQqZAQoGBAADAgIAEgNDBCAa
iQEgVGhlIG5hbWUgb2YgdGhlIENsb3VkIEZ1bmN0aW9uIGVudHJ5IHBvaW50LiBUaGUgdmFs
dWUgb2YgdGhpcyBmaWVsZAogc2hvdWxkIG1hdGNoIHRoZSBuYW1lIG9mIHRoZSBtZXRob2Qg
ZXhwb3J0ZWQgZnJvbSB0aGUgc291cmNlIGNvZGUuCgoOCgcEAAMCAgAFEgNDBAoKDgoHBAAD
AgIAARIDQwsbCg4KBwQAAwICAAMSA0MeHwoxCgQEAAIAEgNHAiAaJCBMaXN0IG9mIGhhbmRs
ZXJzIGZvciB0aGlzIHdlYmhvb2suCgoMCgUEAAIABBIDRwIKCgwKBQQAAgAGEgNHCxIKDAoF
BAACAAESA0cTGwoMCgUEAAIAAxIDRx4fCjMKBAQACAASBEoCUAMaJSBPbmx5IG9uZSB3ZWJo
b29rIHR5cGUgaXMgc3VwcG9ydGVkLgoKDAoFBAAIAAESA0oIFAotCgQEAAIBEgNMBCUaICBD
dXN0b20gd2ViaG9vayBIVFRQUyBlbmRwb2ludC4KCgwKBQQAAgEGEgNMBBEKDAoFBAACAQES
A0wSIAoMCgUEAAIBAxIDTCMkClUKBAQAAgISA08EMhpIIE1ldGFkYXRhIGZvciBjbG91ZCBm
dW5jdGlvbiBkZXBsb3llZCBmcm9tIGNvZGUgaW4gdGhlIHdlYmhvb2tzIGZvbGRlci4KCgwK
BQQAAgIGEgNPBBcKDAoFBAACAgESA08YLQoMCgUEAAICAxIDTzAxYgZwcm90bzM=
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Actions::Sdk::V2::Webhook::Webhook ===
    # Fields for Webhook
    # Field: handlers Type: 11 (.google.actions.sdk.v2.Webhook.Handler)
    # Field: https_endpoint Type: 11 (.google.actions.sdk.v2.Webhook.HttpsEndpoint)
    # Field: inline_cloud_function Type: 11 (.google.actions.sdk.v2.Webhook.InlineCloudFunction)

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Actions::Sdk::V2::Webhook - Compiled Protocol Buffers messages for google/actions/sdk/v2/webhook.proto

=head1 SYNOPSIS

    use Google::Actions::Sdk::V2::Webhook;

    my $msg = Google::Actions::Sdk::V2::Webhook::Webhook->new({
        handlers => $handlers,
        https_endpoint => $https_endpoint,
        inline_cloud_function => $inline_cloud_function,
    });

    # Read or update a field
    my $val = $msg->handlers();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Actions::Sdk::V2::Webhook::Webhook->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/actions/sdk/v2/webhook.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Actions::Sdk::V2::Webhook::Webhook

Metadata for different types of webhooks. If you're using
`inlineCloudFunction`, your source code must be in a directory with the same
name as the value for the `executeFunction` key.
For example, a value of `my_webhook` for the`executeFunction` key would have
a code structure like this:
 - `/webhooks/my_webhook.yaml`
 - `/webhooks/my_webhook/index.js`
 - `/webhooks/my_webhook/package.json`

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->handlers() >> / C<< $msg->handlers($value) >>

Type: C<Message> (L<Google::Actions::Sdk::V2::Webhook::Webhook::Handler>)

List of handlers for this webhook.

=item * C<< $msg->https_endpoint() >> / C<< $msg->https_endpoint($value) >>

Type: C<Message> (L<Google::Actions::Sdk::V2::Webhook::Webhook::HttpsEndpoint>)

Custom webhook HTTPS endpoint.

=item * C<< $msg->inline_cloud_function() >> / C<< $msg->inline_cloud_function($value) >>

Type: C<Message> (L<Google::Actions::Sdk::V2::Webhook::Webhook::InlineCloudFunction>)

Metadata for cloud function deployed from code in the webhooks folder.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Actions::Sdk::V2::Webhook::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
