package Google::Cloud::Oracledatabase::V1::LocationMetadata;

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
CjZnb29nbGUvY2xvdWQvb3JhY2xlZGF0YWJhc2UvdjEvbG9jYXRpb25fbWV0YWRhdGEucHJv
dG8SHmdvb2dsZS5jbG91ZC5vcmFjbGVkYXRhYmFzZS52MRofZ29vZ2xlL2FwaS9maWVsZF9i
ZWhhdmlvci5wcm90byJBChBMb2NhdGlvbk1ldGFkYXRhEi0KEGdjcF9vcmFjbGVfem9uZXMY
AiADKAlCA+BBA1IOZ2NwT3JhY2xlWm9uZXNC7wEKImNvbS5nb29nbGUuY2xvdWQub3JhY2xl
ZGF0YWJhc2UudjFCFUxvY2F0aW9uTWV0YWRhdGFQcm90b1ABWkpjbG91ZC5nb29nbGUuY29t
L2dvL29yYWNsZWRhdGFiYXNlL2FwaXYxL29yYWNsZWRhdGFiYXNlcGI7b3JhY2xlZGF0YWJh
c2VwYqoCHkdvb2dsZS5DbG91ZC5PcmFjbGVEYXRhYmFzZS5WMcoCHkdvb2dsZVxDbG91ZFxP
cmFjbGVEYXRhYmFzZVxWMeoCIUdvb2dsZTo6Q2xvdWQ6Ok9yYWNsZURhdGFiYXNlOjpWMUry
BwoGEgQOACEBCrwECgEMEgMOABIysQQgQ29weXJpZ2h0IDIwMjYgR29vZ2xlIExMQwoKIExp
Y2Vuc2VkIHVuZGVyIHRoZSBBcGFjaGUgTGljZW5zZSwgVmVyc2lvbiAyLjAgKHRoZSAiTGlj
ZW5zZSIpOwogeW91IG1heSBub3QgdXNlIHRoaXMgZmlsZSBleGNlcHQgaW4gY29tcGxpYW5j
ZSB3aXRoIHRoZSBMaWNlbnNlLgogWW91IG1heSBvYnRhaW4gYSBjb3B5IG9mIHRoZSBMaWNl
bnNlIGF0CgogICAgIGh0dHA6Ly93d3cuYXBhY2hlLm9yZy9saWNlbnNlcy9MSUNFTlNFLTIu
MAoKIFVubGVzcyByZXF1aXJlZCBieSBhcHBsaWNhYmxlIGxhdyBvciBhZ3JlZWQgdG8gaW4g
d3JpdGluZywgc29mdHdhcmUKIGRpc3RyaWJ1dGVkIHVuZGVyIHRoZSBMaWNlbnNlIGlzIGRp
c3RyaWJ1dGVkIG9uIGFuICJBUyBJUyIgQkFTSVMsCiBXSVRIT1VUIFdBUlJBTlRJRVMgT1Ig
Q09ORElUSU9OUyBPRiBBTlkgS0lORCwgZWl0aGVyIGV4cHJlc3Mgb3IgaW1wbGllZC4KIFNl
ZSB0aGUgTGljZW5zZSBmb3IgdGhlIHNwZWNpZmljIGxhbmd1YWdlIGdvdmVybmluZyBwZXJt
aXNzaW9ucyBhbmQKIGxpbWl0YXRpb25zIHVuZGVyIHRoZSBMaWNlbnNlLgoKCAoBAhIDEAAn
CgkKAgMAEgMSACkKCAoBCBIDFAA7CgkKAgglEgMUADsKCAoBCBIDFQBhCgkKAggLEgMVAGEK
CAoBCBIDFgAiCgkKAggKEgMWACIKCAoBCBIDFwA2CgkKAggIEgMXADYKCAoBCBIDGAA7CgkK
AggBEgMYADsKCAoBCBIDGQA7CgkKAggpEgMZADsKCAoBCBIDGgA6CgkKAggtEgMaADoKTgoC
BAASBB0AIQEaQiBNZXRhZGF0YSBmb3IgYSBnaXZlbiBbTG9jYXRpb25dW2dvb2dsZS5jbG91
ZC5sb2NhdGlvbi5Mb2NhdGlvbl0uCgoKCgMEAAESAx0IGApOCgQEAAIAEgQfAiAyGkAgT3V0
cHV0IG9ubHkuIEdvb2dsZSBDbG91ZCBQbGF0Zm9ybSBPcmFjbGUgem9uZXMgaW4gYSBsb2Nh
dGlvbi4KCgwKBQQAAgAEEgMfAgoKDAoFBAACAAUSAx8LEQoMCgUEAAIAARIDHxIiCgwKBQQA
AgADEgMfJSYKDAoFBAACAAgSAyAGMQoPCggEAAIACJwIABIDIAcwYgZwcm90bzM=
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Oracledatabase::V1::LocationMetadata::LocationMetadata ===
    # Fields for LocationMetadata
    # Field: gcp_oracle_zones Type: 9 ()

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Oracledatabase::V1::LocationMetadata - Compiled Protocol Buffers messages for google/cloud/oracledatabase/v1/location_metadata.proto

=head1 SYNOPSIS

    use Google::Cloud::Oracledatabase::V1::LocationMetadata;

    my $msg = Google::Cloud::Oracledatabase::V1::LocationMetadata::LocationMetadata->new({
        gcp_oracle_zones => $gcp_oracle_zones,
    });

    # Read or update a field
    my $val = $msg->gcp_oracle_zones();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Oracledatabase::V1::LocationMetadata::LocationMetadata->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/oracledatabase/v1/location_metadata.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Oracledatabase::V1::LocationMetadata::LocationMetadata

Metadata for a given [Location][google.cloud.location.Location].

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->gcp_oracle_zones() >> / C<< $msg->gcp_oracle_zones($value) >>

Type: C<String>

Output only. Google Cloud Platform Oracle zones in a location.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Oracledatabase::V1::LocationMetadata::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
