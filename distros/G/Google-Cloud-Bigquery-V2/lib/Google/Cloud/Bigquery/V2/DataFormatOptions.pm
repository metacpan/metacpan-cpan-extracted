package Google::Cloud::Bigquery::V2::DataFormatOptions;

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

# Enum: DataFormatOptions::TimestampOutputFormat
our $DataFormatOptions_TIMESTAMP_OUTPUT_FORMAT_UNSPECIFIED = 0;
our $DataFormatOptions_FLOAT64 = 1;
our $DataFormatOptions_INT64 = 2;
our $DataFormatOptions_ISO8601_STRING = 3;

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Bigquery::V2::DataFormatOptions - Compiled Protocol Buffers messages for google/cloud/bigquery/v2/data_format_options.proto

=head1 SYNOPSIS

    use Google::Cloud::Bigquery::V2::DataFormatOptions;

    my $msg = Google::Cloud::Bigquery::V2::DataFormatOptions::DataFormatOptions->new({
        use_int64_timestamp => $use_int64_timestamp,
        timestamp_output_format => $timestamp_output_format,
    });

    # Read or update a field
    my $val = $msg->use_int64_timestamp();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Bigquery::V2::DataFormatOptions::DataFormatOptions->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/bigquery/v2/data_format_options.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Bigquery::V2::DataFormatOptions::DataFormatOptions

Options for data format adjustments.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->use_int64_timestamp() >> / C<< $msg->use_int64_timestamp($value) >>

Type: C<Bool>

Optional. Output timestamp as usec int64. Default is false.

=item * C<< $msg->timestamp_output_format() >> / C<< $msg->timestamp_output_format($value) >>

Type: C<Enum> (L<Google::Cloud::Bigquery::V2::DataFormatOptions::TimestampOutputFormat>)

Optional. The API output format for a timestamp.
This offers more explicit control over the timestamp output format
as compared to the existing `use_int64_timestamp` option.

=back

=head3 Enum: DataFormatOptions::TimestampOutputFormat

=over 4

=item * C<TIMESTAMP_OUTPUT_FORMAT_UNSPECIFIED> => C<0>

=item * C<FLOAT64> => C<1>

=item * C<INT64> => C<2>

=item * C<ISO8601_STRING> => C<3>

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Bigquery::V2::DataFormatOptions::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
