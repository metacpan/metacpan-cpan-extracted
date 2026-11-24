package Google::Cloud::Geminidataanalytics::V1::Credentials;

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
CjVnb29nbGUvY2xvdWQvZ2VtaW5pZGF0YWFuYWx5dGljcy92MS9jcmVkZW50aWFscy5wcm90
bxIjZ29vZ2xlLmNsb3VkLmdlbWluaWRhdGFhbmFseXRpY3MudjEaH2dvb2dsZS9hcGkvZmll
bGRfYmVoYXZpb3IucHJvdG8iZAoLQ3JlZGVudGlhbHMSTQoFb2F1dGgYASABKAsyNS5nb29n
bGUuY2xvdWQuZ2VtaW5pZGF0YWFuYWx5dGljcy52MS5PQXV0aENyZWRlbnRpYWxzSABSBW9h
dXRoQgYKBGtpbmQi4gIKEE9BdXRoQ3JlZGVudGlhbHMSWwoGc2VjcmV0GAIgASgLMkEuZ29v
Z2xlLmNsb3VkLmdlbWluaWRhdGFhbmFseXRpY3MudjEuT0F1dGhDcmVkZW50aWFscy5TZWNy
ZXRCYXNlZEgAUgZzZWNyZXQSWAoFdG9rZW4YAyABKAsyQC5nb29nbGUuY2xvdWQuZ2VtaW5p
ZGF0YWFuYWx5dGljcy52MS5PQXV0aENyZWRlbnRpYWxzLlRva2VuQmFzZWRIAFIFdG9rZW4a
WQoLU2VjcmV0QmFzZWQSIAoJY2xpZW50X2lkGAIgASgJQgPgQQJSCGNsaWVudElkEigKDWNs
aWVudF9zZWNyZXQYAyABKAlCA+BBAlIMY2xpZW50U2VjcmV0GjQKClRva2VuQmFzZWQSJgoM
YWNjZXNzX3Rva2VuGAEgASgJQgPgQQJSC2FjY2Vzc1Rva2VuQgYKBGtpbmRCjQIKJ2NvbS5n
b29nbGUuY2xvdWQuZ2VtaW5pZGF0YWFuYWx5dGljcy52MUIQQ3JlZGVudGlhbHNQcm90b1AB
WlljbG91ZC5nb29nbGUuY29tL2dvL2dlbWluaWRhdGFhbmFseXRpY3MvYXBpdjEvZ2VtaW5p
ZGF0YWFuYWx5dGljc3BiO2dlbWluaWRhdGFhbmFseXRpY3NwYqoCI0dvb2dsZS5DbG91ZC5H
ZW1pbmlEYXRhQW5hbHl0aWNzLlYxygIjR29vZ2xlXENsb3VkXEdlbWluaURhdGFBbmFseXRp
Y3NcVjHqAiZHb29nbGU6OkNsb3VkOjpHZW1pbmlEYXRhQW5hbHl0aWNzOjpWMUqqDwoGEgQO
AEABCrwECgEMEgMOABIysQQgQ29weXJpZ2h0IDIwMjYgR29vZ2xlIExMQwoKIExpY2Vuc2Vk
IHVuZGVyIHRoZSBBcGFjaGUgTGljZW5zZSwgVmVyc2lvbiAyLjAgKHRoZSAiTGljZW5zZSIp
OwogeW91IG1heSBub3QgdXNlIHRoaXMgZmlsZSBleGNlcHQgaW4gY29tcGxpYW5jZSB3aXRo
IHRoZSBMaWNlbnNlLgogWW91IG1heSBvYnRhaW4gYSBjb3B5IG9mIHRoZSBMaWNlbnNlIGF0
CgogICAgIGh0dHA6Ly93d3cuYXBhY2hlLm9yZy9saWNlbnNlcy9MSUNFTlNFLTIuMAoKIFVu
bGVzcyByZXF1aXJlZCBieSBhcHBsaWNhYmxlIGxhdyBvciBhZ3JlZWQgdG8gaW4gd3JpdGlu
Zywgc29mdHdhcmUKIGRpc3RyaWJ1dGVkIHVuZGVyIHRoZSBMaWNlbnNlIGlzIGRpc3RyaWJ1
dGVkIG9uIGFuICJBUyBJUyIgQkFTSVMsCiBXSVRIT1VUIFdBUlJBTlRJRVMgT1IgQ09ORElU
SU9OUyBPRiBBTlkgS0lORCwgZWl0aGVyIGV4cHJlc3Mgb3IgaW1wbGllZC4KIFNlZSB0aGUg
TGljZW5zZSBmb3IgdGhlIHNwZWNpZmljIGxhbmd1YWdlIGdvdmVybmluZyBwZXJtaXNzaW9u
cyBhbmQKIGxpbWl0YXRpb25zIHVuZGVyIHRoZSBMaWNlbnNlLgoKCAoBAhIDEAAsCgkKAgMA
EgMSACkKCAoBCBIDFABACgkKAgglEgMUAEAKCAoBCBIDFQBwCgkKAggLEgMVAHAKCAoBCBID
FgAiCgkKAggKEgMWACIKCAoBCBIDFwAxCgkKAggIEgMXADEKCAoBCBIDGABACgkKAggBEgMY
AEAKCAoBCBIDGQBACgkKAggpEgMZAEAKCAoBCBIDGgA/CgkKAggtEgMaAD8KRQoCBAASBB0A
IwEaOSBSZXByZXNlbnRzIGRpZmZlcmVudCBmb3JtcyBvZiBjcmVkZW50aWFsIHNwZWNpZmlj
YXRpb24uCgoKCgMEAAESAx0IEwooCgQEAAgAEgQfAiIDGhogVGhlIGtpbmQgb2YgY3JlZGVu
dGlhbHMuCgoMCgUEAAgAARIDHwgMCiEKBAQAAgASAyEEHxoUIE9BdXRoIGNyZWRlbnRpYWxz
LgoKDAoFBAACAAYSAyEEFAoMCgUEAAIAARIDIRUaCgwKBQQAAgADEgMhHR4KKwoCBAESBCYA
QAEaHyBSZXByZXNlbnRzIE9BdXRoIGNyZWRlbnRpYWxzLgoKCgoDBAEBEgMmCBgKbwoEBAED
ABIEKQIvAxphIFRoZSBuYW1lIG9mIHRoZSBzZWNyZXQgY29udGFpbmluZyB0aGUgYWNjZXNz
IHRva2VuLgogUmVwcmVzZW50cyBzZWNyZXQtYmFzZWQgT0F1dGggY3JlZGVudGlhbHMuCgoM
CgUEAQMAARIDKQoVCi4KBgQBAwACABIDKwRCGh8gUmVxdWlyZWQuIEFuIE9BdXRoIGNsaWVu
dCBJRC4KCg4KBwQBAwACAAUSAysECgoOCgcEAQMAAgABEgMrCxQKDgoHBAEDAAIAAxIDKxcY
Cg4KBwQBAwACAAgSAysZQQoRCgoEAQMAAgAInAgAEgMrGkAKMgoGBAEDAAIBEgMuBEYaIyBS
ZXF1aXJlZC4gQW4gT0F1dGggY2xpZW50IHNlY3JldC4KCg4KBwQBAwACAQUSAy4ECgoOCgcE
AQMAAgEBEgMuCxgKDgoHBAEDAAIBAxIDLhscCg4KBwQBAwACAQgSAy4dRQoRCgoEAQMAAgEI
nAgAEgMuHkQKfQoEBAEDARIEMwI2AxpvIFJlYWQgbW9yZSBhYm91dCBMb29rZXIgYWNjZXNz
IHRva2VucyBoZXJlOgogaHR0cHM6Ly9kZXZlbG9wZXJzLmxvb2tlci5jb20vYXBpL2FkdmFu
Y2VkLXVzYWdlL2xvb2tlci1hcGktb2F1dGgKCgwKBQQBAwEBEgMzChQKTgoGBAEDAQIAEgM1
BEUaPyBSZXF1aXJlZC4gVGhlIG5hbWUgb2YgdGhlIHNlY3JldCBjb250YWluaW5nIHRoZSBh
Y2Nlc3MgdG9rZW4uCgoOCgcEAQMBAgAFEgM1BAoKDgoHBAEDAQIAARIDNQsXCg4KBwQBAwEC
AAMSAzUaGwoOCgcEAQMBAgAIEgM1HEQKEQoKBAEDAQIACJwIABIDNR1DCi4KBAQBCAASBDkC
PwMaICBUaGUga2luZCBvZiBPQXV0aCBjcmVkZW50aWFscy4KCgwKBQQBCAABEgM5CAwKLgoE
BAECABIDOwQbGiEgU2VjcmV0LWJhc2VkIE9BdXRoIGNyZWRlbnRpYWxzLgoKDAoFBAECAAYS
AzsEDwoMCgUEAQIAARIDOxAWCgwKBQQBAgADEgM7GRoKLQoEBAECARIDPgQZGiAgVG9rZW4t
YmFzZWQgT0F1dGggY3JlZGVudGlhbHMuCgoMCgUEAQIBBhIDPgQOCgwKBQQBAgEBEgM+DxQK
DAoFBAECAQMSAz4XGGIGcHJvdG8z
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Geminidataanalytics::V1::Credentials::Credentials ===
    # Fields for Credentials
    # Field: oauth Type: 11 (.google.cloud.geminidataanalytics.v1.OAuthCredentials)

# === Message: Google::Cloud::Geminidataanalytics::V1::Credentials::OAuthCredentials ===
    # Fields for OAuthCredentials
    # Field: secret Type: 11 (.google.cloud.geminidataanalytics.v1.OAuthCredentials.SecretBased)
    # Field: token Type: 11 (.google.cloud.geminidataanalytics.v1.OAuthCredentials.TokenBased)

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Geminidataanalytics::V1::Credentials - Compiled Protocol Buffers messages for google/cloud/geminidataanalytics/v1/credentials.proto

=head1 SYNOPSIS

    use Google::Cloud::Geminidataanalytics::V1::Credentials;

    my $msg = Google::Cloud::Geminidataanalytics::V1::Credentials::Credentials->new({
        oauth => $oauth,
    });

    # Read or update a field
    my $val = $msg->oauth();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Geminidataanalytics::V1::Credentials::Credentials->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/geminidataanalytics/v1/credentials.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Geminidataanalytics::V1::Credentials::Credentials

Represents different forms of credential specification.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->oauth() >> / C<< $msg->oauth($value) >>

Type: C<Message> (L<Google::Cloud::Geminidataanalytics::V1::Credentials::OAuthCredentials>)

OAuth credentials.

=back

=head2 Google::Cloud::Geminidataanalytics::V1::Credentials::OAuthCredentials

Represents OAuth credentials.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->secret() >> / C<< $msg->secret($value) >>

Type: C<Message> (L<Google::Cloud::Geminidataanalytics::V1::Credentials::OAuthCredentials::SecretBased>)

Secret-based OAuth credentials.

=item * C<< $msg->token() >> / C<< $msg->token($value) >>

Type: C<Message> (L<Google::Cloud::Geminidataanalytics::V1::Credentials::OAuthCredentials::TokenBased>)

Token-based OAuth credentials.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Geminidataanalytics::V1::Credentials::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
