package Google::Cloud::Bigquery::V2::LocationMetadata;

use strict;
use warnings;

our $VERSION = '0.14';

use Protobuf::Message;
use Protobuf::DescriptorPool;
use Protobuf::Internal qw(:all);
use MIME::Base64;

BEGIN {
    my $descriptor_b64 = <<'EOF';
CjBnb29nbGUvY2xvdWQvYmlncXVlcnkvdjIvbG9jYXRpb25fbWV0YWRhdGEucHJvdG8SGGdv
b2dsZS5jbG91ZC5iaWdxdWVyeS52MiJAChBMb2NhdGlvbk1ldGFkYXRhEiwKEmxlZ2FjeV9s
b2NhdGlvbl9pZBgBIAEoCVIQbGVnYWN5TG9jYXRpb25JZEJyChxjb20uZ29vZ2xlLmNsb3Vk
LmJpZ3F1ZXJ5LnYyQhVMb2NhdGlvbk1ldGFkYXRhUHJvdG9aO2Nsb3VkLmdvb2dsZS5jb20v
Z28vYmlncXVlcnkvdjIvYXBpdjIvYmlncXVlcnlwYjtiaWdxdWVyeXBiSpgICgYSBA4AHQEK
vAQKAQwSAw4AEjKxBCBDb3B5cmlnaHQgMjAyNiBHb29nbGUgTExDCgogTGljZW5zZWQgdW5k
ZXIgdGhlIEFwYWNoZSBMaWNlbnNlLCBWZXJzaW9uIDIuMCAodGhlICJMaWNlbnNlIik7CiB5
b3UgbWF5IG5vdCB1c2UgdGhpcyBmaWxlIGV4Y2VwdCBpbiBjb21wbGlhbmNlIHdpdGggdGhl
IExpY2Vuc2UuCiBZb3UgbWF5IG9idGFpbiBhIGNvcHkgb2YgdGhlIExpY2Vuc2UgYXQKCiAg
ICAgaHR0cDovL3d3dy5hcGFjaGUub3JnL2xpY2Vuc2VzL0xJQ0VOU0UtMi4wCgogVW5sZXNz
IHJlcXVpcmVkIGJ5IGFwcGxpY2FibGUgbGF3IG9yIGFncmVlZCB0byBpbiB3cml0aW5nLCBz
b2Z0d2FyZQogZGlzdHJpYnV0ZWQgdW5kZXIgdGhlIExpY2Vuc2UgaXMgZGlzdHJpYnV0ZWQg
b24gYW4gIkFTIElTIiBCQVNJUywKIFdJVEhPVVQgV0FSUkFOVElFUyBPUiBDT05ESVRJT05T
IE9GIEFOWSBLSU5ELCBlaXRoZXIgZXhwcmVzcyBvciBpbXBsaWVkLgogU2VlIHRoZSBMaWNl
bnNlIGZvciB0aGUgc3BlY2lmaWMgbGFuZ3VhZ2UgZ292ZXJuaW5nIHBlcm1pc3Npb25zIGFu
ZAogbGltaXRhdGlvbnMgdW5kZXIgdGhlIExpY2Vuc2UuCgoICgECEgMQACEKCAoBCBIDEgBS
CgkKAggLEgMSAFIKCAoBCBIDEwA2CgkKAggIEgMTADYKCAoBCBIDFAA1CgkKAggBEgMUADUK
mgEKAgQAEgQZAB0BGo0BIEJpZ1F1ZXJ5LXNwZWNpZmljIG1ldGFkYXRhIGFib3V0IGEgbG9j
YXRpb24uIFRoaXMgd2lsbCBiZSBzZXQgb24KIGdvb2dsZS5jbG91ZC5sb2NhdGlvbi5Mb2Nh
dGlvbi5tZXRhZGF0YSBpbiBDbG91ZCBMb2NhdGlvbiBBUEkKIHJlc3BvbnNlcy4KCgoKAwQA
ARIDGQgYCrIBCgQEAAIAEgMcAiAapAEgVGhlIGxlZ2FjeSBCaWdRdWVyeSBsb2NhdGlvbiBJ
RCwgZS5nLiDigJxFVeKAnSBmb3IgdGhlIOKAnGV1cm9wZeKAnSBsb2NhdGlvbi4KIFRoaXMg
aXMgZm9yIGFueSBBUEkgY29uc3VtZXJzIHRoYXQgbmVlZCB0aGUgbGVnYWN5IOKAnFVT4oCd
IGFuZCDigJxFVeKAnSBsb2NhdGlvbnMuCgoMCgUEAAIABRIDHAIICgwKBQQAAgABEgMcCRsK
DAoFBAACAAMSAxweH2IGcHJvdG8z
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Bigquery::V2::LocationMetadata::LocationMetadata ===
    # Fields for LocationMetadata
    # Field: legacy_location_id Type: 9 ()

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Bigquery::V2::LocationMetadata - Compiled Protocol Buffers messages for google/cloud/bigquery/v2/location_metadata.proto

=head1 SYNOPSIS

    use Google::Cloud::Bigquery::V2::LocationMetadata;

    my $msg = Google::Cloud::Bigquery::V2::LocationMetadata::LocationMetadata->new({
        legacy_location_id => $legacy_location_id,
    });

    # Read or update a field
    my $val = $msg->legacy_location_id();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Bigquery::V2::LocationMetadata::LocationMetadata->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/bigquery/v2/location_metadata.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Bigquery::V2::LocationMetadata::LocationMetadata

BigQuery-specific metadata about a location. This will be set on
google.cloud.location.Location.metadata in Cloud Location API
responses.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->legacy_location_id() >> / C<< $msg->legacy_location_id($value) >>

Type: C<String>

The legacy BigQuery location ID, e.g. “EU” for the “europe” location.
This is for any API consumers that need the legacy “US” and “EU” locations.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Bigquery::V2::LocationMetadata::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
