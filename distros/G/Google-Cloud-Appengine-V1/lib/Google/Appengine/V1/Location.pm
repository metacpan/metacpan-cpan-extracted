package Google::Appengine::V1::Location;

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
CiJnb29nbGUvYXBwZW5naW5lL3YxL2xvY2F0aW9uLnByb3RvEhNnb29nbGUuYXBwZW5naW5l
LnYxGh9nb29nbGUvYXBpL2ZpZWxkX2JlaGF2aW9yLnByb3RvItUBChBMb2NhdGlvbk1ldGFk
YXRhEkQKHnN0YW5kYXJkX2Vudmlyb25tZW50X2F2YWlsYWJsZRgCIAEoCFIcc3RhbmRhcmRF
bnZpcm9ubWVudEF2YWlsYWJsZRJECh5mbGV4aWJsZV9lbnZpcm9ubWVudF9hdmFpbGFibGUY
BCABKAhSHGZsZXhpYmxlRW52aXJvbm1lbnRBdmFpbGFibGUSNQoUc2VhcmNoX2FwaV9hdmFp
bGFibGUYBiABKAhCA+BBA1ISc2VhcmNoQXBpQXZhaWxhYmxlQr4BChdjb20uZ29vZ2xlLmFw
cGVuZ2luZS52MUINTG9jYXRpb25Qcm90b1ABWjtjbG91ZC5nb29nbGUuY29tL2dvL2FwcGVu
Z2luZS9hcGl2MS9hcHBlbmdpbmVwYjthcHBlbmdpbmVwYqoCGUdvb2dsZS5DbG91ZC5BcHBF
bmdpbmUuVjHKAhlHb29nbGVcQ2xvdWRcQXBwRW5naW5lXFYx6gIcR29vZ2xlOjpDbG91ZDo6
QXBwRW5naW5lOjpWMUrVCgoGEgQOACsBCrwECgEMEgMOABIysQQgQ29weXJpZ2h0IDIwMjUg
R29vZ2xlIExMQwoKIExpY2Vuc2VkIHVuZGVyIHRoZSBBcGFjaGUgTGljZW5zZSwgVmVyc2lv
biAyLjAgKHRoZSAiTGljZW5zZSIpOwogeW91IG1heSBub3QgdXNlIHRoaXMgZmlsZSBleGNl
cHQgaW4gY29tcGxpYW5jZSB3aXRoIHRoZSBMaWNlbnNlLgogWW91IG1heSBvYnRhaW4gYSBj
b3B5IG9mIHRoZSBMaWNlbnNlIGF0CgogICAgIGh0dHA6Ly93d3cuYXBhY2hlLm9yZy9saWNl
bnNlcy9MSUNFTlNFLTIuMAoKIFVubGVzcyByZXF1aXJlZCBieSBhcHBsaWNhYmxlIGxhdyBv
ciBhZ3JlZWQgdG8gaW4gd3JpdGluZywgc29mdHdhcmUKIGRpc3RyaWJ1dGVkIHVuZGVyIHRo
ZSBMaWNlbnNlIGlzIGRpc3RyaWJ1dGVkIG9uIGFuICJBUyBJUyIgQkFTSVMsCiBXSVRIT1VU
IFdBUlJBTlRJRVMgT1IgQ09ORElUSU9OUyBPRiBBTlkgS0lORCwgZWl0aGVyIGV4cHJlc3Mg
b3IgaW1wbGllZC4KIFNlZSB0aGUgTGljZW5zZSBmb3IgdGhlIHNwZWNpZmljIGxhbmd1YWdl
IGdvdmVybmluZyBwZXJtaXNzaW9ucyBhbmQKIGxpbWl0YXRpb25zIHVuZGVyIHRoZSBMaWNl
bnNlLgoKCAoBAhIDEAAcCgkKAgMAEgMSACkKCAoBCBIDFAA2CgkKAgglEgMUADYKCAoBCBID
FQBSCgkKAggLEgMVAFIKCAoBCBIDFgAiCgkKAggKEgMWACIKCAoBCBIDFwAuCgkKAggIEgMX
AC4KCAoBCBIDGAAwCgkKAggBEgMYADAKCAoBCBIDGQA2CgkKAggpEgMZADYKCAoBCBIDGgA1
CgkKAggtEgMaADUKZgoCBAASBB0AKwEaWiBNZXRhZGF0YSBmb3IgdGhlIGdpdmVuIFtnb29n
bGUuY2xvdWQubG9jYXRpb24uTG9jYXRpb25dW2dvb2dsZS5jbG91ZC5sb2NhdGlvbi5Mb2Nh
dGlvbl0uCgoKCgMEAAESAx0IGApgCgQEAAIAEgMhAioaUyBBcHAgRW5naW5lIHN0YW5kYXJk
IGVudmlyb25tZW50IGlzIGF2YWlsYWJsZSBpbiB0aGUgZ2l2ZW4gbG9jYXRpb24uCgogQE91
dHB1dE9ubHkKCgwKBQQAAgAFEgMhAgYKDAoFBAACAAESAyEHJQoMCgUEAAIAAxIDISgpCmAK
BAQAAgESAyYCKhpTIEFwcCBFbmdpbmUgZmxleGlibGUgZW52aXJvbm1lbnQgaXMgYXZhaWxh
YmxlIGluIHRoZSBnaXZlbiBsb2NhdGlvbi4KCiBAT3V0cHV0T25seQoKDAoFBAACAQUSAyYC
BgoMCgUEAAIBARIDJgclCgwKBQQAAgEDEgMmKCkKjgEKBAQAAgISAyoCTBqAASBPdXRwdXQg
b25seS4gW1NlYXJjaCBBUEldKGh0dHBzOi8vY2xvdWQuZ29vZ2xlLmNvbS9hcHBlbmdpbmUv
ZG9jcy9zdGFuZGFyZC9weXRob24vc2VhcmNoKQogaXMgYXZhaWxhYmxlIGluIHRoZSBnaXZl
biBsb2NhdGlvbi4KCgwKBQQAAgIFEgMqAgYKDAoFBAACAgESAyoHGwoMCgUEAAICAxIDKh4f
CgwKBQQAAgIIEgMqIEsKDwoIBAACAgicCAASAyohSmIGcHJvdG8z
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Appengine::V1::Location::LocationMetadata ===
    # Fields for LocationMetadata
    # Field: standard_environment_available Type: 8 ()
    # Field: flexible_environment_available Type: 8 ()
    # Field: search_api_available Type: 8 ()

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Appengine::V1::Location - Compiled Protocol Buffers messages for google/appengine/v1/location.proto

=head1 SYNOPSIS

    use Google::Appengine::V1::Location;

    my $msg = Google::Appengine::V1::Location::LocationMetadata->new({
        standard_environment_available => $standard_environment_available,
        flexible_environment_available => $flexible_environment_available,
        search_api_available => $search_api_available,
    });

    # Read or update a field
    my $val = $msg->standard_environment_available();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Appengine::V1::Location::LocationMetadata->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/appengine/v1/location.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Appengine::V1::Location::LocationMetadata

Metadata for the given [google.cloud.location.Location][google.cloud.location.Location].

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->standard_environment_available() >> / C<< $msg->standard_environment_available($value) >>

Type: C<Bool>

App Engine standard environment is available in the given location.

@OutputOnly

=item * C<< $msg->flexible_environment_available() >> / C<< $msg->flexible_environment_available($value) >>

Type: C<Bool>

App Engine flexible environment is available in the given location.

@OutputOnly

=item * C<< $msg->search_api_available() >> / C<< $msg->search_api_available($value) >>

Type: C<Bool>

Output only. [Search API](https://cloud.google.com/appengine/docs/standard/python/search)
is available in the given location.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Appengine::V1::Location::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
