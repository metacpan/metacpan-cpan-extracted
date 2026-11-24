package Google::Cloud::Bigquery::V2::RestrictionConfig;

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
CjFnb29nbGUvY2xvdWQvYmlncXVlcnkvdjIvcmVzdHJpY3Rpb25fY29uZmlnLnByb3RvEhhn
b29nbGUuY2xvdWQuYmlncXVlcnkudjIaH2dvb2dsZS9hcGkvZmllbGRfYmVoYXZpb3IucHJv
dG8iugEKEVJlc3RyaWN0aW9uQ29uZmlnElQKBHR5cGUYASABKA4yOy5nb29nbGUuY2xvdWQu
YmlncXVlcnkudjIuUmVzdHJpY3Rpb25Db25maWcuUmVzdHJpY3Rpb25UeXBlQgPgQQNSBHR5
cGUiTwoPUmVzdHJpY3Rpb25UeXBlEiAKHFJFU1RSSUNUSU9OX1RZUEVfVU5TUEVDSUZJRUQQ
ABIaChZSRVNUUklDVEVEX0RBVEFfRUdSRVNTEAFCdQocY29tLmdvb2dsZS5jbG91ZC5iaWdx
dWVyeS52MkIWUmVzdHJpY3Rpb25Db25maWdQcm90b1ABWjtjbG91ZC5nb29nbGUuY29tL2dv
L2JpZ3F1ZXJ5L3YyL2FwaXYyL2JpZ3F1ZXJ5cGI7YmlncXVlcnlwYkrGCQoGEgQOACcBCrwE
CgEMEgMOABIysQQgQ29weXJpZ2h0IDIwMjYgR29vZ2xlIExMQwoKIExpY2Vuc2VkIHVuZGVy
IHRoZSBBcGFjaGUgTGljZW5zZSwgVmVyc2lvbiAyLjAgKHRoZSAiTGljZW5zZSIpOwogeW91
IG1heSBub3QgdXNlIHRoaXMgZmlsZSBleGNlcHQgaW4gY29tcGxpYW5jZSB3aXRoIHRoZSBM
aWNlbnNlLgogWW91IG1heSBvYnRhaW4gYSBjb3B5IG9mIHRoZSBMaWNlbnNlIGF0CgogICAg
IGh0dHA6Ly93d3cuYXBhY2hlLm9yZy9saWNlbnNlcy9MSUNFTlNFLTIuMAoKIFVubGVzcyBy
ZXF1aXJlZCBieSBhcHBsaWNhYmxlIGxhdyBvciBhZ3JlZWQgdG8gaW4gd3JpdGluZywgc29m
dHdhcmUKIGRpc3RyaWJ1dGVkIHVuZGVyIHRoZSBMaWNlbnNlIGlzIGRpc3RyaWJ1dGVkIG9u
IGFuICJBUyBJUyIgQkFTSVMsCiBXSVRIT1VUIFdBUlJBTlRJRVMgT1IgQ09ORElUSU9OUyBP
RiBBTlkgS0lORCwgZWl0aGVyIGV4cHJlc3Mgb3IgaW1wbGllZC4KIFNlZSB0aGUgTGljZW5z
ZSBmb3IgdGhlIHNwZWNpZmljIGxhbmd1YWdlIGdvdmVybmluZyBwZXJtaXNzaW9ucyBhbmQK
IGxpbWl0YXRpb25zIHVuZGVyIHRoZSBMaWNlbnNlLgoKCAoBAhIDEAAhCgkKAgMAEgMSACkK
CAoBCBIDFABSCgkKAggLEgMUAFIKCAoBCBIDFQAiCgkKAggKEgMVACIKCAoBCBIDFgA3CgkK
AggIEgMWADcKCAoBCBIDFwA1CgkKAggBEgMXADUKCgoCBAASBBkAJwEKCgoDBAABEgMZCBkK
UAoEBAAEABIEGwIjAxpCIFJlc3RyaWN0aW9uVHlwZSBzcGVjaWZpZXMgdGhlIHR5cGUgb2Yg
ZGF0YXNldC90YWJsZSByZXN0cmljdGlvbi4KCgwKBQQABAABEgMbBxYKJgoGBAAEAAIAEgMd
BCUaFyBTaG91bGQgbmV2ZXIgYmUgdXNlZC4KCg4KBwQABAACAAESAx0EIAoOCgcEAAQAAgAC
EgMdIyQKnAEKBgQABAACARIDIgQfGowBIFJlc3RyaWN0IGRhdGEgZWdyZXNzLiBTZWUgW0Rh
dGEKIGVncmVzc10oaHR0cHM6Ly9jbG91ZC5nb29nbGUuY29tL2JpZ3F1ZXJ5L2RvY3MvYW5h
bHl0aWNzLWh1Yi1pbnRyb2R1Y3Rpb24jZGF0YV9lZ3Jlc3MpCiBmb3IgbW9yZSBkZXRhaWxz
LgoKDgoHBAAEAAIBARIDIgQaCg4KBwQABAACAQISAyIdHgpMCgQEAAIAEgMmAkcaPyBPdXRw
dXQgb25seS4gU3BlY2lmaWVzIHRoZSB0eXBlIG9mIGRhdGFzZXQvdGFibGUgcmVzdHJpY3Rp
b24uCgoMCgUEAAIABhIDJgIRCgwKBQQAAgABEgMmEhYKDAoFBAACAAMSAyYZGgoMCgUEAAIA
CBIDJhtGCg8KCAQAAgAInAgAEgMmHEViBnByb3RvMw==
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Bigquery::V2::RestrictionConfig::RestrictionConfig ===
    # Fields for RestrictionConfig
    # Field: type Type: 14 (.google.cloud.bigquery.v2.RestrictionConfig.RestrictionType)

# Enum: RestrictionConfig::RestrictionType
our $RestrictionConfig_RESTRICTION_TYPE_UNSPECIFIED = 0;
our $RestrictionConfig_RESTRICTED_DATA_EGRESS = 1;

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Bigquery::V2::RestrictionConfig - Compiled Protocol Buffers messages for google/cloud/bigquery/v2/restriction_config.proto

=head1 SYNOPSIS

    use Google::Cloud::Bigquery::V2::RestrictionConfig;

    my $msg = Google::Cloud::Bigquery::V2::RestrictionConfig::RestrictionConfig->new({
        type => $type,
    });

    # Read or update a field
    my $val = $msg->type();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Bigquery::V2::RestrictionConfig::RestrictionConfig->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/bigquery/v2/restriction_config.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Bigquery::V2::RestrictionConfig::RestrictionConfig

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->type() >> / C<< $msg->type($value) >>

Type: C<Enum> (L<Google::Cloud::Bigquery::V2::RestrictionConfig::RestrictionType>)

Output only. Specifies the type of dataset/table restriction.

=back

=head3 Enum: RestrictionConfig::RestrictionType

=over 4

=item * C<RESTRICTION_TYPE_UNSPECIFIED> => C<0>

=item * C<RESTRICTED_DATA_EGRESS> => C<1>

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Bigquery::V2::RestrictionConfig::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
