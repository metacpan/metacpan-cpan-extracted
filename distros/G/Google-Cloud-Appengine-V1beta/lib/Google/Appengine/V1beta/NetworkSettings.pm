package Google::Appengine::V1beta::NetworkSettings;

use strict;
use warnings;

our $VERSION = '0.14';

use Protobuf::Message;
use Protobuf::DescriptorPool;
use Protobuf::Internal qw(:all);
use MIME::Base64;

BEGIN {
    my $descriptor_b64 = <<'EOF';
Ci5nb29nbGUvYXBwZW5naW5lL3YxYmV0YS9uZXR3b3JrX3NldHRpbmdzLnByb3RvEhdnb29n
bGUuYXBwZW5naW5lLnYxYmV0YSLFAgoPTmV0d29ya1NldHRpbmdzEnYKF2luZ3Jlc3NfdHJh
ZmZpY19hbGxvd2VkGAEgASgOMj4uZ29vZ2xlLmFwcGVuZ2luZS52MWJldGEuTmV0d29ya1Nl
dHRpbmdzLkluZ3Jlc3NUcmFmZmljQWxsb3dlZFIVaW5ncmVzc1RyYWZmaWNBbGxvd2VkIrkB
ChVJbmdyZXNzVHJhZmZpY0FsbG93ZWQSJwojSU5HUkVTU19UUkFGRklDX0FMTE9XRURfVU5T
UEVDSUZJRUQQABIfChtJTkdSRVNTX1RSQUZGSUNfQUxMT1dFRF9BTEwQARIpCiVJTkdSRVNT
X1RSQUZGSUNfQUxMT1dFRF9JTlRFUk5BTF9PTkxZEAISKwonSU5HUkVTU19UUkFGRklDX0FM
TE9XRURfSU5URVJOQUxfQU5EX0xCEANC2gEKG2NvbS5nb29nbGUuYXBwZW5naW5lLnYxYmV0
YUIUTmV0d29ya1NldHRpbmdzUHJvdG9QAVpAZ29vZ2xlLmdvbGFuZy5vcmcvZ2VucHJvdG8v
Z29vZ2xlYXBpcy9hcHBlbmdpbmUvdjFiZXRhO2FwcGVuZ2luZaoCHUdvb2dsZS5DbG91ZC5B
cHBFbmdpbmUuVjFCZXRhygIdR29vZ2xlXENsb3VkXEFwcEVuZ2luZVxWMWJldGHqAiBHb29n
bGU6OkNsb3VkOjpBcHBFbmdpbmU6OlYxYmV0YUqbCwoGEgQOAC8BCrwECgEMEgMOABIysQQg
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
IHVuZGVyIHRoZSBMaWNlbnNlLgoKCAoBAhIDEAAgCggKAQgSAxMAOgoJCgIIJRIDEwA6CggK
AQgSAxQAVwoJCgIICxIDFABXCggKAQgSAxUAIgoJCgIIChIDFQAiCggKAQgSAxYANQoJCgII
CBIDFgA1CggKAQgSAxcANAoJCgIIARIDFwA0CggKAQgSAxgAOgoJCgIIKRIDGAA6CggKAQgS
AxkAOQoJCgIILRIDGQA5CmcKAgQAEgQdAC8BGlsgQSBOZXR3b3JrU2V0dGluZ3MgcmVzb3Vy
Y2UgaXMgYSBjb250YWluZXIgZm9yIGluZ3Jlc3Mgc2V0dGluZ3MgZm9yIGEgdmVyc2lvbgog
b3Igc2VydmljZS4KCgoKAwQAARIDHQgXCkkKBAQABAASBB8CKwMaOyBJZiB1bnNwZWNpZmll
ZCwgSU5HUkVTU19UUkFGRklDX0FMTE9XRURfQUxMIHdpbGwgYmUgdXNlZC4KCgwKBQQABAAB
EgMfBxwKHAoGBAAEAAIAEgMhBCwaDSBVbnNwZWNpZmllZAoKDgoHBAAEAAIAARIDIQQnCg4K
BwQABAACAAISAyEqKwpECgYEAAQAAgESAyQEJBo1IEFsbG93IEhUVFAgdHJhZmZpYyBmcm9t
IHB1YmxpYyBhbmQgcHJpdmF0ZSBzb3VyY2VzLgoKDgoHBAAEAAIBARIDJAQfCg4KBwQABAAC
AQISAyQiIwpCCgYEAAQAAgISAycELhozIEFsbG93IEhUVFAgdHJhZmZpYyBmcm9tIG9ubHkg
cHJpdmF0ZSBWUEMgc291cmNlcy4KCg4KBwQABAACAgESAycEKQoOCgcEAAQAAgICEgMnLC0K
WAoGBAAEAAIDEgMqBDAaSSBBbGxvdyBIVFRQIHRyYWZmaWMgZnJvbSBwcml2YXRlIFZQQyBz
b3VyY2VzIGFuZCB0aHJvdWdoIGxvYWQgYmFsYW5jZXJzLgoKDgoHBAAEAAIDARIDKgQrCg4K
BwQABAACAwISAyouLwo7CgQEAAIAEgMuAjQaLiBUaGUgaW5ncmVzcyBzZXR0aW5ncyBmb3Ig
dmVyc2lvbiBvciBzZXJ2aWNlLgoKDAoFBAACAAYSAy4CFwoMCgUEAAIAARIDLhgvCgwKBQQA
AgADEgMuMjNiBnByb3RvMw==
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Appengine::V1beta::NetworkSettings::NetworkSettings ===
    # Fields for NetworkSettings
    # Field: ingress_traffic_allowed Type: 14 (.google.appengine.v1beta.NetworkSettings.IngressTrafficAllowed)

# Enum: NetworkSettings::IngressTrafficAllowed
our $NetworkSettings_INGRESS_TRAFFIC_ALLOWED_UNSPECIFIED = 0;
our $NetworkSettings_INGRESS_TRAFFIC_ALLOWED_ALL = 1;
our $NetworkSettings_INGRESS_TRAFFIC_ALLOWED_INTERNAL_ONLY = 2;
our $NetworkSettings_INGRESS_TRAFFIC_ALLOWED_INTERNAL_AND_LB = 3;

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Appengine::V1beta::NetworkSettings - Compiled Protocol Buffers messages for google/appengine/v1beta/network_settings.proto

=head1 SYNOPSIS

    use Google::Appengine::V1beta::NetworkSettings;

    my $msg = Google::Appengine::V1beta::NetworkSettings::NetworkSettings->new({
        ingress_traffic_allowed => $ingress_traffic_allowed,
    });

    # Read or update a field
    my $val = $msg->ingress_traffic_allowed();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Appengine::V1beta::NetworkSettings::NetworkSettings->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/appengine/v1beta/network_settings.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Appengine::V1beta::NetworkSettings::NetworkSettings

A NetworkSettings resource is a container for ingress settings for a version
or service.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->ingress_traffic_allowed() >> / C<< $msg->ingress_traffic_allowed($value) >>

Type: C<Enum> (L<Google::Appengine::V1beta::NetworkSettings::IngressTrafficAllowed>)

The ingress settings for version or service.

=back

=head3 Enum: NetworkSettings::IngressTrafficAllowed

=over 4

=item * C<INGRESS_TRAFFIC_ALLOWED_UNSPECIFIED> => C<0>

=item * C<INGRESS_TRAFFIC_ALLOWED_ALL> => C<1>

=item * C<INGRESS_TRAFFIC_ALLOWED_INTERNAL_ONLY> => C<2>

=item * C<INGRESS_TRAFFIC_ALLOWED_INTERNAL_AND_LB> => C<3>

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Appengine::V1beta::NetworkSettings::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
