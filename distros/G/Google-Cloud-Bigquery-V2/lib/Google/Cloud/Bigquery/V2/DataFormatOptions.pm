package Google::Cloud::Bigquery::V2::DataFormatOptions;

use strict;
use warnings;

our $VERSION = '0.04';

use Protobuf::Message;
use Protobuf::DescriptorPool;
use Protobuf::Internal qw(:all);
use MIME::Base64;

BEGIN {
    eval { require Google::Api::FieldBehavior };
    my $descriptor_b64 = <<'EOF';
CjJnb29nbGUvY2xvdWQvYmlncXVlcnkvdjIvZGF0YV9mb3JtYXRfb3B0aW9ucy5wcm90bxIY
Z29vZ2xlLmNsb3VkLmJpZ3F1ZXJ5LnYyGh9nb29nbGUvYXBpL2ZpZWxkX2JlaGF2aW9yLnBy
b3RvIrYCChFEYXRhRm9ybWF0T3B0aW9ucxIzChN1c2VfaW50NjRfdGltZXN0YW1wGAEgASgI
QgPgQQFSEXVzZUludDY0VGltZXN0YW1wEn4KF3RpbWVzdGFtcF9vdXRwdXRfZm9ybWF0GAMg
ASgOMkEuZ29vZ2xlLmNsb3VkLmJpZ3F1ZXJ5LnYyLkRhdGFGb3JtYXRPcHRpb25zLlRpbWVz
dGFtcE91dHB1dEZvcm1hdEID4EEBUhV0aW1lc3RhbXBPdXRwdXRGb3JtYXQibAoVVGltZXN0
YW1wT3V0cHV0Rm9ybWF0EicKI1RJTUVTVEFNUF9PVVRQVVRfRk9STUFUX1VOU1BFQ0lGSUVE
EAASCwoHRkxPQVQ2NBABEgkKBUlOVDY0EAISEgoOSVNPODYwMV9TVFJJTkcQA0JzChxjb20u
Z29vZ2xlLmNsb3VkLmJpZ3F1ZXJ5LnYyQhZEYXRhRm9ybWF0T3B0aW9uc1Byb3RvWjtjbG91
ZC5nb29nbGUuY29tL2dvL2JpZ3F1ZXJ5L3YyL2FwaXYyL2JpZ3F1ZXJ5cGI7YmlncXVlcnlw
YkqMDQoGEgQOADIBCrwECgEMEgMOABIysQQgQ29weXJpZ2h0IDIwMjYgR29vZ2xlIExMQwoK
IExpY2Vuc2VkIHVuZGVyIHRoZSBBcGFjaGUgTGljZW5zZSwgVmVyc2lvbiAyLjAgKHRoZSAi
TGljZW5zZSIpOwogeW91IG1heSBub3QgdXNlIHRoaXMgZmlsZSBleGNlcHQgaW4gY29tcGxp
YW5jZSB3aXRoIHRoZSBMaWNlbnNlLgogWW91IG1heSBvYnRhaW4gYSBjb3B5IG9mIHRoZSBM
aWNlbnNlIGF0CgogICAgIGh0dHA6Ly93d3cuYXBhY2hlLm9yZy9saWNlbnNlcy9MSUNFTlNF
LTIuMAoKIFVubGVzcyByZXF1aXJlZCBieSBhcHBsaWNhYmxlIGxhdyBvciBhZ3JlZWQgdG8g
aW4gd3JpdGluZywgc29mdHdhcmUKIGRpc3RyaWJ1dGVkIHVuZGVyIHRoZSBMaWNlbnNlIGlz
IGRpc3RyaWJ1dGVkIG9uIGFuICJBUyBJUyIgQkFTSVMsCiBXSVRIT1VUIFdBUlJBTlRJRVMg
T1IgQ09ORElUSU9OUyBPRiBBTlkgS0lORCwgZWl0aGVyIGV4cHJlc3Mgb3IgaW1wbGllZC4K
IFNlZSB0aGUgTGljZW5zZSBmb3IgdGhlIHNwZWNpZmljIGxhbmd1YWdlIGdvdmVybmluZyBw
ZXJtaXNzaW9ucyBhbmQKIGxpbWl0YXRpb25zIHVuZGVyIHRoZSBMaWNlbnNlLgoKCAoBAhID
EAAhCgkKAgMAEgMSACkKCAoBCBIDFABSCgkKAggLEgMUAFIKCAoBCBIDFQA3CgkKAggIEgMV
ADcKCAoBCBIDFgA1CgkKAggBEgMWADUKMgoCBAASBBkAMgEaJiBPcHRpb25zIGZvciBkYXRh
IGZvcm1hdCBhZGp1c3RtZW50cy4KCgoKAwQAARIDGQgZCjYKBAQABAASBBsCKAMaKCBUaGUg
QVBJIG91dHB1dCBmb3JtYXQgZm9yIGEgdGltZXN0YW1wLgoKDAoFBAAEAAESAxsHHApOCgYE
AAQAAgASAx0ELBo/IENvcnJlc3BvbmRzIHRvIGRlZmF1bHQgQVBJIG91dHB1dCBiZWhhdmlv
ciwgd2hpY2ggaXMgRkxPQVQ2NC4KCg4KBwQABAACAAESAx0EJwoOCgcEAAQAAgACEgMdKisK
SQoGBAAEAAIBEgMgBBAaOiBUaW1lc3RhbXAgaXMgb3V0cHV0IGFzIGZsb2F0NjQgc2Vjb25k
cyBzaW5jZSBVbml4IGVwb2NoLgoKDgoHBAAEAAIBARIDIAQLCg4KBwQABAACAQISAyAODwpM
CgYEAAQAAgISAyMEDho9IFRpbWVzdGFtcCBpcyBvdXRwdXQgYXMgaW50NjQgbWljcm9zZWNv
bmRzIHNpbmNlIFVuaXggZXBvY2guCgoOCgcEAAQAAgIBEgMjBAkKDgoHBAAEAAICAhIDIwwN
Cl8KBgQABAACAxIDJwQXGlAgVGltZXN0YW1wIGlzIG91dHB1dCBhcyBJU08gODYwMSBTdHJp
bmcKICgiWVlZWS1NTS1ERFRISDpNTTpTUy5GRkZGRkZGRkZGRkZaIikuCgoOCgcEAAQAAgMB
EgMnBBIKDgoHBAAEAAIDAhIDJxUWCkoKBAQAAgASAysCSBo9IE9wdGlvbmFsLiBPdXRwdXQg
dGltZXN0YW1wIGFzIHVzZWMgaW50NjQuIERlZmF1bHQgaXMgZmFsc2UuCgoMCgUEAAIABRID
KwIGCgwKBQQAAgABEgMrBxoKDAoFBAACAAMSAysdHgoMCgUEAAIACBIDKx9HCg8KCAQAAgAI
nAgAEgMrIEYKwAEKBAQAAgESBDACMS8asQEgT3B0aW9uYWwuIFRoZSBBUEkgb3V0cHV0IGZv
cm1hdCBmb3IgYSB0aW1lc3RhbXAuCiBUaGlzIG9mZmVycyBtb3JlIGV4cGxpY2l0IGNvbnRy
b2wgb3ZlciB0aGUgdGltZXN0YW1wIG91dHB1dCBmb3JtYXQKIGFzIGNvbXBhcmVkIHRvIHRo
ZSBleGlzdGluZyBgdXNlX2ludDY0X3RpbWVzdGFtcGAgb3B0aW9uLgoKDAoFBAACAQYSAzAC
FwoMCgUEAAIBARIDMBgvCgwKBQQAAgEDEgMwMjMKDAoFBAACAQgSAzEGLgoPCggEAAIBCJwI
ABIDMQctYgZwcm90bzM=
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Bigquery::V2::DataFormatOptions::DataFormatOptions ===
    # Fields for DataFormatOptions
    # Field: use_int64_timestamp Type: 8 ()
    # Field: timestamp_output_format Type: 14 (.google.cloud.bigquery.v2.DataFormatOptions.TimestampOutputFormat)

=pod

=head1 NAME

Google::Cloud::Bigquery::V2::DataFormatOptions::DataFormatOptions - Compiled Protocol Buffers message class

=head1 SYNOPSIS

    use Google::Cloud::Bigquery::V2::DataFormatOptions;

    my $msg = Google::Cloud::Bigquery::V2::DataFormatOptions::DataFormatOptions->new(
        use_int64_timestamp => $value,
    );

=head1 FIELDS

=over 4

=item * B<use_int64_timestamp>

Type: Bool

=item * B<timestamp_output_format>

Type: Enum (.google.cloud.bigquery.v2.DataFormatOptions.TimestampOutputFormat)

=back

=cut

# Enum: DataFormatOptions::TimestampOutputFormat
our $DataFormatOptions_TIMESTAMP_OUTPUT_FORMAT_UNSPECIFIED = 0;
our $DataFormatOptions_FLOAT64 = 1;
our $DataFormatOptions_INT64 = 2;
our $DataFormatOptions_ISO8601_STRING = 3;

=pod

=head2 Enum: DataFormatOptions::TimestampOutputFormat

Values:

=over 4

=item * C<TIMESTAMP_OUTPUT_FORMAT_UNSPECIFIED> => 0

=item * C<FLOAT64> => 1

=item * C<INT64> => 2

=item * C<ISO8601_STRING> => 3

=back

=cut

1;

__END__

=head1 NAME

Google::Cloud::Bigquery::V2::DataFormatOptions - Protocol Buffers schema definition

=head1 DESCRIPTION

Auto-generated Protocol Buffers schema definition class.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
