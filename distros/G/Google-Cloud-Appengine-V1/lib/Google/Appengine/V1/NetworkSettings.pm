package Google::Appengine::V1::NetworkSettings;

use strict;
use warnings;

our $VERSION = '0.14';

use Protobuf::Message;
use Protobuf::DescriptorPool;
use Protobuf::Internal qw(:all);
use MIME::Base64;

BEGIN {
    my $descriptor_b64 = <<'EOF';
Cipnb29nbGUvYXBwZW5naW5lL3YxL25ldHdvcmtfc2V0dGluZ3MucHJvdG8SE2dvb2dsZS5h
cHBlbmdpbmUudjEiwQIKD05ldHdvcmtTZXR0aW5ncxJyChdpbmdyZXNzX3RyYWZmaWNfYWxs
b3dlZBgBIAEoDjI6Lmdvb2dsZS5hcHBlbmdpbmUudjEuTmV0d29ya1NldHRpbmdzLkluZ3Jl
c3NUcmFmZmljQWxsb3dlZFIVaW5ncmVzc1RyYWZmaWNBbGxvd2VkIrkBChVJbmdyZXNzVHJh
ZmZpY0FsbG93ZWQSJwojSU5HUkVTU19UUkFGRklDX0FMTE9XRURfVU5TUEVDSUZJRUQQABIf
ChtJTkdSRVNTX1RSQUZGSUNfQUxMT1dFRF9BTEwQARIpCiVJTkdSRVNTX1RSQUZGSUNfQUxM
T1dFRF9JTlRFUk5BTF9PTkxZEAISKwonSU5HUkVTU19UUkFGRklDX0FMTE9XRURfSU5URVJO
QUxfQU5EX0xCEANCxQEKF2NvbS5nb29nbGUuYXBwZW5naW5lLnYxQhROZXR3b3JrU2V0dGlu
Z3NQcm90b1ABWjtjbG91ZC5nb29nbGUuY29tL2dvL2FwcGVuZ2luZS9hcGl2MS9hcHBlbmdp
bmVwYjthcHBlbmdpbmVwYqoCGUdvb2dsZS5DbG91ZC5BcHBFbmdpbmUuVjHKAhlHb29nbGVc
Q2xvdWRcQXBwRW5naW5lXFYx6gIcR29vZ2xlOjpDbG91ZDo6QXBwRW5naW5lOjpWMUqbCwoG
EgQOAC4BCrwECgEMEgMOABIysQQgQ29weXJpZ2h0IDIwMjUgR29vZ2xlIExMQwoKIExpY2Vu
c2VkIHVuZGVyIHRoZSBBcGFjaGUgTGljZW5zZSwgVmVyc2lvbiAyLjAgKHRoZSAiTGljZW5z
ZSIpOwogeW91IG1heSBub3QgdXNlIHRoaXMgZmlsZSBleGNlcHQgaW4gY29tcGxpYW5jZSB3
aXRoIHRoZSBMaWNlbnNlLgogWW91IG1heSBvYnRhaW4gYSBjb3B5IG9mIHRoZSBMaWNlbnNl
IGF0CgogICAgIGh0dHA6Ly93d3cuYXBhY2hlLm9yZy9saWNlbnNlcy9MSUNFTlNFLTIuMAoK
IFVubGVzcyByZXF1aXJlZCBieSBhcHBsaWNhYmxlIGxhdyBvciBhZ3JlZWQgdG8gaW4gd3Jp
dGluZywgc29mdHdhcmUKIGRpc3RyaWJ1dGVkIHVuZGVyIHRoZSBMaWNlbnNlIGlzIGRpc3Ry
aWJ1dGVkIG9uIGFuICJBUyBJUyIgQkFTSVMsCiBXSVRIT1VUIFdBUlJBTlRJRVMgT1IgQ09O
RElUSU9OUyBPRiBBTlkgS0lORCwgZWl0aGVyIGV4cHJlc3Mgb3IgaW1wbGllZC4KIFNlZSB0
aGUgTGljZW5zZSBmb3IgdGhlIHNwZWNpZmljIGxhbmd1YWdlIGdvdmVybmluZyBwZXJtaXNz
aW9ucyBhbmQKIGxpbWl0YXRpb25zIHVuZGVyIHRoZSBMaWNlbnNlLgoKCAoBAhIDEAAcCggK
AQgSAxIANgoJCgIIJRIDEgA2CggKAQgSAxMAUgoJCgIICxIDEwBSCggKAQgSAxQAIgoJCgII
ChIDFAAiCggKAQgSAxUANQoJCgIICBIDFQA1CggKAQgSAxYAMAoJCgIIARIDFgAwCggKAQgS
AxcANgoJCgIIKRIDFwA2CggKAQgSAxgANQoJCgIILRIDGAA1CmcKAgQAEgQcAC4BGlsgQSBO
ZXR3b3JrU2V0dGluZ3MgcmVzb3VyY2UgaXMgYSBjb250YWluZXIgZm9yIGluZ3Jlc3Mgc2V0
dGluZ3MgZm9yIGEgdmVyc2lvbgogb3Igc2VydmljZS4KCgoKAwQAARIDHAgXCkkKBAQABAAS
BB4CKgMaOyBJZiB1bnNwZWNpZmllZCwgSU5HUkVTU19UUkFGRklDX0FMTE9XRURfQUxMIHdp
bGwgYmUgdXNlZC4KCgwKBQQABAABEgMeBxwKHAoGBAAEAAIAEgMgBCwaDSBVbnNwZWNpZmll
ZAoKDgoHBAAEAAIAARIDIAQnCg4KBwQABAACAAISAyAqKwpECgYEAAQAAgESAyMEJBo1IEFs
bG93IEhUVFAgdHJhZmZpYyBmcm9tIHB1YmxpYyBhbmQgcHJpdmF0ZSBzb3VyY2VzLgoKDgoH
BAAEAAIBARIDIwQfCg4KBwQABAACAQISAyMiIwpCCgYEAAQAAgISAyYELhozIEFsbG93IEhU
VFAgdHJhZmZpYyBmcm9tIG9ubHkgcHJpdmF0ZSBWUEMgc291cmNlcy4KCg4KBwQABAACAgES
AyYEKQoOCgcEAAQAAgICEgMmLC0KWAoGBAAEAAIDEgMpBDAaSSBBbGxvdyBIVFRQIHRyYWZm
aWMgZnJvbSBwcml2YXRlIFZQQyBzb3VyY2VzIGFuZCB0aHJvdWdoIGxvYWQgYmFsYW5jZXJz
LgoKDgoHBAAEAAIDARIDKQQrCg4KBwQABAACAwISAykuLwo7CgQEAAIAEgMtAjQaLiBUaGUg
aW5ncmVzcyBzZXR0aW5ncyBmb3IgdmVyc2lvbiBvciBzZXJ2aWNlLgoKDAoFBAACAAYSAy0C
FwoMCgUEAAIAARIDLRgvCgwKBQQAAgADEgMtMjNiBnByb3RvMw==
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Appengine::V1::NetworkSettings::NetworkSettings ===
    # Fields for NetworkSettings
    # Field: ingress_traffic_allowed Type: 14 (.google.appengine.v1.NetworkSettings.IngressTrafficAllowed)

# Enum: NetworkSettings::IngressTrafficAllowed
our $NetworkSettings_INGRESS_TRAFFIC_ALLOWED_UNSPECIFIED = 0;
our $NetworkSettings_INGRESS_TRAFFIC_ALLOWED_ALL = 1;
our $NetworkSettings_INGRESS_TRAFFIC_ALLOWED_INTERNAL_ONLY = 2;
our $NetworkSettings_INGRESS_TRAFFIC_ALLOWED_INTERNAL_AND_LB = 3;

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Appengine::V1::NetworkSettings - Compiled Protocol Buffers messages for google/appengine/v1/network_settings.proto

=head1 SYNOPSIS

    use Google::Appengine::V1::NetworkSettings;

    my $msg = Google::Appengine::V1::NetworkSettings::NetworkSettings->new({
        ingress_traffic_allowed => $ingress_traffic_allowed,
    });

    # Read or update a field
    my $val = $msg->ingress_traffic_allowed();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Appengine::V1::NetworkSettings::NetworkSettings->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/appengine/v1/network_settings.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Appengine::V1::NetworkSettings::NetworkSettings

A NetworkSettings resource is a container for ingress settings for a version
or service.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->ingress_traffic_allowed() >> / C<< $msg->ingress_traffic_allowed($value) >>

Type: C<Enum> (L<Google::Appengine::V1::NetworkSettings::IngressTrafficAllowed>)

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

L<Protobuf>, L<Protobuf::Message>, L<Google::Appengine::V1::NetworkSettings::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
