package Google::Cloud::Eventarc::V1::GoogleChannelConfig;

use strict;
use warnings;

our $VERSION = '0.14';

use Protobuf::Message;
use Protobuf::DescriptorPool;
use Protobuf::Internal qw(:all);
use MIME::Base64;

BEGIN {
    eval { require Google::Api::FieldBehavior };
    eval { require Google::Api::Resource };
    eval { require Google::Protobuf::Timestamp };
    my $descriptor_b64 = <<'EOF';
CjRnb29nbGUvY2xvdWQvZXZlbnRhcmMvdjEvZ29vZ2xlX2NoYW5uZWxfY29uZmlnLnByb3Rv
Ehhnb29nbGUuY2xvdWQuZXZlbnRhcmMudjEaH2dvb2dsZS9hcGkvZmllbGRfYmVoYXZpb3Iu
cHJvdG8aGWdvb2dsZS9hcGkvcmVzb3VyY2UucHJvdG8aH2dvb2dsZS9wcm90b2J1Zi90aW1l
c3RhbXAucHJvdG8i8gMKE0dvb2dsZUNoYW5uZWxDb25maWcSFwoEbmFtZRgBIAEoCUID4EEC
UgRuYW1lEkAKC3VwZGF0ZV90aW1lGAYgASgLMhouZ29vZ2xlLnByb3RvYnVmLlRpbWVzdGFt
cEID4EEDUgp1cGRhdGVUaW1lElEKD2NyeXB0b19rZXlfbmFtZRgHIAEoCUIp4EEB+kEjCiFj
bG91ZGttcy5nb29nbGVhcGlzLmNvbS9DcnlwdG9LZXlSDWNyeXB0b0tleU5hbWUSVgoGbGFi
ZWxzGAggAygLMjkuZ29vZ2xlLmNsb3VkLmV2ZW50YXJjLnYxLkdvb2dsZUNoYW5uZWxDb25m
aWcuTGFiZWxzRW50cnlCA+BBAVIGbGFiZWxzGjkKC0xhYmVsc0VudHJ5EhAKA2tleRgBIAEo
CVIDa2V5EhQKBXZhbHVlGAIgASgJUgV2YWx1ZToCOAE6mQHqQZUBCitldmVudGFyYy5nb29n
bGVhcGlzLmNvbS9Hb29nbGVDaGFubmVsQ29uZmlnEjtwcm9qZWN0cy97cHJvamVjdH0vbG9j
YXRpb25zL3tsb2NhdGlvbn0vZ29vZ2xlQ2hhbm5lbENvbmZpZyoUZ29vZ2xlQ2hhbm5lbENv
bmZpZ3MyE2dvb2dsZUNoYW5uZWxDb25maWdCwwIKHGNvbS5nb29nbGUuY2xvdWQuZXZlbnRh
cmMudjFCGEdvb2dsZUNoYW5uZWxDb25maWdQcm90b1ABWjhjbG91ZC5nb29nbGUuY29tL2dv
L2V2ZW50YXJjL2FwaXYxL2V2ZW50YXJjcGI7ZXZlbnRhcmNwYqoCGEdvb2dsZS5DbG91ZC5F
dmVudGFyYy5WMcoCGEdvb2dsZVxDbG91ZFxFdmVudGFyY1xWMeoCG0dvb2dsZTo6Q2xvdWQ6
OkV2ZW50YXJjOjpWMepBeAohY2xvdWRrbXMuZ29vZ2xlYXBpcy5jb20vQ3J5cHRvS2V5ElNw
cm9qZWN0cy97cHJvamVjdH0vbG9jYXRpb25zL3tsb2NhdGlvbn0va2V5UmluZ3Mve2tleV9y
aW5nfS9jcnlwdG9LZXlzL3tjcnlwdG9fa2V5fUr8DwoGEgQOAEcBCrwECgEMEgMOABIysQQg
Q29weXJpZ2h0IDIwMjUgR29vZ2xlIExMQwoKIExpY2Vuc2VkIHVuZGVyIHRoZSBBcGFjaGUg
TGljZW5zZSwgVmVyc2lvbiAyLjAgKHRoZSAiTGljZW5zZSIpOwogeW91IG1heSBub3QgdXNl
IHRoaXMgZmlsZSBleGNlcHQgaW4gY29tcGxpYW5jZSB3aXRoIHRoZSBMaWNlbnNlLgogWW91
IG1heSBvYnRhaW4gYSBjb3B5IG9mIHRoZSBMaWNlbnNlIGF0CgogICAgIGh0dHA6Ly93d3cu
YXBhY2hlLm9yZy9saWNlbnNlcy9MSUNFTlNFLTIuMAoKIFVubGVzcyByZXF1aXJlZCBieSBh
cHBsaWNhYmxlIGxhdyBvciBhZ3JlZWQgdG8gaW4gd3JpdGluZywgc29mdHdhcmUKIGRpc3Ry
aWJ1dGVkIHVuZGVyIHRoZSBMaWNlbnNlIGlzIGRpc3RyaWJ1dGVkIG9uIGFuICJBUyBJUyIg
QkFTSVMsCiBXSVRIT1VUIFdBUlJBTlRJRVMgT1IgQ09ORElUSU9OUyBPRiBBTlkgS0lORCwg
ZWl0aGVyIGV4cHJlc3Mgb3IgaW1wbGllZC4KIFNlZSB0aGUgTGljZW5zZSBmb3IgdGhlIHNw
ZWNpZmljIGxhbmd1YWdlIGdvdmVybmluZyBwZXJtaXNzaW9ucyBhbmQKIGxpbWl0YXRpb25z
IHVuZGVyIHRoZSBMaWNlbnNlLgoKCAoBAhIDEAAhCgkKAgMAEgMSACkKCQoCAwESAxMAIwoJ
CgIDAhIDFAApCggKAQgSAxYANQoJCgIIJRIDFgA1CggKAQgSAxcATwoJCgIICxIDFwBPCggK
AQgSAxgAIgoJCgIIChIDGAAiCggKAQgSAxkAOQoJCgIICBIDGQA5CggKAQgSAxoANQoJCgII
ARIDGgA1CggKAQgSAxsANQoJCgIIKRIDGwA1CggKAQgSAxwANAoJCgIILRIDHAA0CgkKAQgS
BB0AIAIKDAoECJ0IABIEHQAgAgqwAgoCBAASBCcARwEaowIgQSBHb29nbGVDaGFubmVsQ29u
ZmlnIGlzIGEgcmVzb3VyY2UgdGhhdCBzdG9yZXMgdGhlIGN1c3RvbSBzZXR0aW5ncwogcmVz
cGVjdGVkIGJ5IEV2ZW50YXJjIGZpcnN0LXBhcnR5IHRyaWdnZXJzIGluIHRoZSBtYXRjaGlu
ZyByZWdpb24uCiBPbmNlIGNvbmZpZ3VyZWQsIGZpcnN0LXBhcnR5IGV2ZW50IGRhdGEgd2ls
bCBiZSBwcm90ZWN0ZWQKIHVzaW5nIHRoZSBzcGVjaWZpZWQgY3VzdG9tIG1hbmFnZWQgZW5j
cnlwdGlvbiBrZXkgaW5zdGVhZCBvZiBHb29nbGUtbWFuYWdlZAogZW5jcnlwdGlvbiBrZXlz
LgoKCgoDBAABEgMnCBsKCwoDBAAHEgQoAi0ECg0KBQQAB50IEgQoAi0ECpoCCgQEAAIAEgMz
AjsajAIgUmVxdWlyZWQuIFRoZSByZXNvdXJjZSBuYW1lIG9mIHRoZSBjb25maWcuIE11c3Qg
YmUgaW4gdGhlIGZvcm1hdCBvZiwKIGBwcm9qZWN0cy97cHJvamVjdH0vbG9jYXRpb25zL3ts
b2NhdGlvbn0vZ29vZ2xlQ2hhbm5lbENvbmZpZ2AuCiBJbiBBUEkgcmVzcG9uc2VzLCB0aGUg
Y29uZmlnIG5hbWUgYWx3YXlzIGluY2x1ZGVzIHRoZSBwcm9qZWN0SUQsIHJlZ2FyZGxlc3MK
IG9mIHdoZXRoZXIgdGhlIHByb2plY3RJRCBvciBwcm9qZWN0TnVtYmVyIHdhcyBwcm92aWRl
ZC4KCgwKBQQAAgAFEgMzAggKDAoFBAACAAESAzMJDQoMCgUEAAIAAxIDMxARCgwKBQQAAgAI
EgMzEjoKDwoIBAACAAicCAASAzMTOQo0CgQEAAIBEgQ2AjcyGiYgT3V0cHV0IG9ubHkuIFRo
ZSBsYXN0LW1vZGlmaWVkIHRpbWUuCgoMCgUEAAIBBhIDNgIbCgwKBQQAAgEBEgM2HCcKDAoF
BAACAQMSAzYqKwoMCgUEAAIBCBIDNwYxCg8KCAQAAgEInAgAEgM3BzAKzAEKBAQAAgISBD4C
QwQavQEgT3B0aW9uYWwuIFJlc291cmNlIG5hbWUgb2YgYSBLTVMgY3J5cHRvIGtleSAobWFu
YWdlZCBieSB0aGUgdXNlcikgdXNlZCB0bwogZW5jcnlwdC9kZWNyeXB0IHRoZWlyIGV2ZW50
IGRhdGEuCgogSXQgbXVzdCBtYXRjaCB0aGUgcGF0dGVybgogYHByb2plY3RzLyovbG9jYXRp
b25zLyova2V5UmluZ3MvKi9jcnlwdG9LZXlzLypgLgoKDAoFBAACAgUSAz4CCAoMCgUEAAIC
ARIDPgkYCgwKBQQAAgIDEgM+GxwKDQoFBAACAggSBD4dQwMKDwoIBAACAgicCAASAz8EKgoP
CgcEAAICCJ8IEgRABEIFCikKBAQAAgMSA0YCShocIE9wdGlvbmFsLiBSZXNvdXJjZSBsYWJl
bHMuCgoMCgUEAAIDBhIDRgIVCgwKBQQAAgMBEgNGFhwKDAoFBAACAwMSA0YfIAoMCgUEAAID
CBIDRiFJCg8KCAQAAgMInAgAEgNGIkhiBnByb3RvMw==
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Eventarc::V1::GoogleChannelConfig::GoogleChannelConfig ===
    # Fields for GoogleChannelConfig
    # Field: name Type: 9 ()
    # Field: update_time Type: 11 (.google.protobuf.Timestamp)
    # Field: crypto_key_name Type: 9 ()
    # Field: labels Type: 11 (.google.cloud.eventarc.v1.GoogleChannelConfig.LabelsEntry)

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Eventarc::V1::GoogleChannelConfig - Compiled Protocol Buffers messages for google/cloud/eventarc/v1/google_channel_config.proto

=head1 SYNOPSIS

    use Google::Cloud::Eventarc::V1::GoogleChannelConfig;

    my $msg = Google::Cloud::Eventarc::V1::GoogleChannelConfig::GoogleChannelConfig->new({
        name => $name,
        update_time => $update_time,
        crypto_key_name => $crypto_key_name,
        labels => $labels,
    });

    # Read or update a field
    my $val = $msg->name();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Eventarc::V1::GoogleChannelConfig::GoogleChannelConfig->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/eventarc/v1/google_channel_config.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Eventarc::V1::GoogleChannelConfig::GoogleChannelConfig

A GoogleChannelConfig is a resource that stores the custom settings
respected by Eventarc first-party triggers in the matching region.
Once configured, first-party event data will be protected
using the specified custom managed encryption key instead of Google-managed
encryption keys.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. The resource name of the config. Must be in the format of,
`projects/{project}/locations/{location}/googleChannelConfig`.
In API responses, the config name always includes the projectID, regardless
of whether the projectID or projectNumber was provided.

=item * C<< $msg->update_time() >> / C<< $msg->update_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Output only. The last-modified time.

=item * C<< $msg->crypto_key_name() >> / C<< $msg->crypto_key_name($value) >>

Type: C<String>

Optional. Resource name of a KMS crypto key (managed by the user) used to
encrypt/decrypt their event data.

It must match the pattern
`projects/*/locations/*/keyRings/*/cryptoKeys/*`.

=item * C<< $msg->labels() >> / C<< $msg->labels($value) >>

Type: C<Message> (L<Google::Cloud::Eventarc::V1::GoogleChannelConfig::GoogleChannelConfig::LabelsEntry>)

Optional. Resource labels.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Eventarc::V1::GoogleChannelConfig::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
