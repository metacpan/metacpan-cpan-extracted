package Google::Cloud::Datacatalog::V1::Common;

use strict;
use warnings;

our $VERSION = '0.14';

use Protobuf::Message;
use Protobuf::DescriptorPool;
use Protobuf::Internal qw(:all);
use MIME::Base64;

BEGIN {
    eval { require Google::Protobuf::Timestamp };
    my $descriptor_b64 = <<'EOF';
Cihnb29nbGUvY2xvdWQvZGF0YWNhdGFsb2cvdjEvY29tbW9uLnByb3RvEhtnb29nbGUuY2xv
dWQuZGF0YWNhdGFsb2cudjEaH2dvb2dsZS9wcm90b2J1Zi90aW1lc3RhbXAucHJvdG8iZAoP
UGVyc29uYWxEZXRhaWxzEhgKB3N0YXJyZWQYASABKAhSB3N0YXJyZWQSNwoJc3Rhcl90aW1l
GAIgASgLMhouZ29vZ2xlLnByb3RvYnVmLlRpbWVzdGFtcFIIc3RhclRpbWUqzAEKEEludGVn
cmF0ZWRTeXN0ZW0SIQodSU5URUdSQVRFRF9TWVNURU1fVU5TUEVDSUZJRUQQABIMCghCSUdR
VUVSWRABEhAKDENMT1VEX1BVQlNVQhACEhYKEkRBVEFQUk9DX01FVEFTVE9SRRADEgwKCERB
VEFQTEVYEAQSEQoNQ0xPVURfU1BBTk5FUhAGEhIKDkNMT1VEX0JJR1RBQkxFEAcSDQoJQ0xP
VURfU1FMEAgSCgoGTE9PS0VSEAkSDQoJVkVSVEVYX0FJEAoqagoOTWFuYWdpbmdTeXN0ZW0S
HwobTUFOQUdJTkdfU1lTVEVNX1VOU1BFQ0lGSUVEEAASHAoYTUFOQUdJTkdfU1lTVEVNX0RB
VEFQTEVYEAESGQoVTUFOQUdJTkdfU1lTVEVNX09USEVSEAJCwwEKH2NvbS5nb29nbGUuY2xv
dWQuZGF0YWNhdGFsb2cudjFQAVpBY2xvdWQuZ29vZ2xlLmNvbS9nby9kYXRhY2F0YWxvZy9h
cGl2MS9kYXRhY2F0YWxvZ3BiO2RhdGFjYXRhbG9ncGKqAhtHb29nbGUuQ2xvdWQuRGF0YUNh
dGFsb2cuVjHKAhtHb29nbGVcQ2xvdWRcRGF0YUNhdGFsb2dcVjHqAh5Hb29nbGU6OkNsb3Vk
OjpEYXRhQ2F0YWxvZzo6VjFKzA8KBhIEDgBQAQq8BAoBDBIDDgASMrEEIENvcHlyaWdodCAy
MDI1IEdvb2dsZSBMTEMKCiBMaWNlbnNlZCB1bmRlciB0aGUgQXBhY2hlIExpY2Vuc2UsIFZl
cnNpb24gMi4wICh0aGUgIkxpY2Vuc2UiKTsKIHlvdSBtYXkgbm90IHVzZSB0aGlzIGZpbGUg
ZXhjZXB0IGluIGNvbXBsaWFuY2Ugd2l0aCB0aGUgTGljZW5zZS4KIFlvdSBtYXkgb2J0YWlu
IGEgY29weSBvZiB0aGUgTGljZW5zZSBhdAoKICAgICBodHRwOi8vd3d3LmFwYWNoZS5vcmcv
bGljZW5zZXMvTElDRU5TRS0yLjAKCiBVbmxlc3MgcmVxdWlyZWQgYnkgYXBwbGljYWJsZSBs
YXcgb3IgYWdyZWVkIHRvIGluIHdyaXRpbmcsIHNvZnR3YXJlCiBkaXN0cmlidXRlZCB1bmRl
ciB0aGUgTGljZW5zZSBpcyBkaXN0cmlidXRlZCBvbiBhbiAiQVMgSVMiIEJBU0lTLAogV0lU
SE9VVCBXQVJSQU5USUVTIE9SIENPTkRJVElPTlMgT0YgQU5ZIEtJTkQsIGVpdGhlciBleHBy
ZXNzIG9yIGltcGxpZWQuCiBTZWUgdGhlIExpY2Vuc2UgZm9yIHRoZSBzcGVjaWZpYyBsYW5n
dWFnZSBnb3Zlcm5pbmcgcGVybWlzc2lvbnMgYW5kCiBsaW1pdGF0aW9ucyB1bmRlciB0aGUg
TGljZW5zZS4KCggKAQISAxAAJAoJCgIDABIDEgApCggKAQgSAxQAOAoJCgIIJRIDFAA4CggK
AQgSAxUAWAoJCgIICxIDFQBYCggKAQgSAxYAIgoJCgIIChIDFgAiCggKAQgSAxcAOAoJCgII
ARIDFwA4CggKAQgSAxgAOAoJCgIIKRIDGAA4CggKAQgSAxkANwoJCgIILRIDGQA3CksKAgQA
EgQcACIBGj8gRW50cnkgbWV0YWRhdGEgcmVsZXZhbnQgb25seSB0byB0aGUgdXNlciBhbmQg
cHJpdmF0ZSB0byB0aGVtLgoKCgoDBAABEgMcCBcKSQoEBAACABIDHgITGjwgVHJ1ZSBpZiB0
aGUgZW50cnkgaXMgc3RhcnJlZCBieSB0aGUgdXNlcjsgZmFsc2Ugb3RoZXJ3aXNlLgoKDAoF
BAACAAUSAx4CBgoMCgUEAAIAARIDHgcOCgwKBQQAAgADEgMeERIKPAoEBAACARIDIQIqGi8g
U2V0IGlmIHRoZSBlbnRyeSBpcyBzdGFycmVkOyB1bnNldCBvdGhlcndpc2UuCgoMCgUEAAIB
BhIDIQIbCgwKBQQAAgEBEgMhHCUKDAoFBAACAQMSAyEoKQpQCgIFABIEJQBDARpEIFRoaXMg
ZW51bSBsaXN0cyBhbGwgdGhlIHN5c3RlbXMgdGhhdCBEYXRhIENhdGFsb2cgaW50ZWdyYXRl
cyB3aXRoLgoKCgoDBQABEgMlBRUKJgoEBQACABIDJwIkGhkgRGVmYXVsdCB1bmtub3duIHN5
c3RlbS4KCgwKBQUAAgABEgMnAh8KDAoFBQACAAISAyciIwoYCgQFAAIBEgMqAg8aCyBCaWdR
dWVyeS4KCgwKBQUAAgEBEgMqAgoKDAoFBQACAQISAyoNDgodCgQFAAICEgMtAhMaECBDbG91
ZCBQdWIvU3ViLgoKDAoFBQACAgESAy0CDgoMCgUFAAICAhIDLRESCiIKBAUAAgMSAzACGRoV
IERhdGFwcm9jIE1ldGFzdG9yZS4KCgwKBQUAAgMBEgMwAhQKDAoFBQACAwISAzAXGAoYCgQF
AAIEEgMzAg8aCyBEYXRhcGxleC4KCgwKBQUAAgQBEgMzAgoKDAoFBQACBAISAzMNDgocCgQF
AAIFEgM2AhQaDyBDbG91ZCBTcGFubmVyCgoMCgUFAAIFARIDNgIPCgwKBQUAAgUCEgM2EhMK
HQoEBQACBhIDOQIVGhAgQ2xvdWQgQmlndGFibGUKCgwKBQUAAgYBEgM5AhAKDAoFBQACBgIS
AzkTFAoYCgQFAAIHEgM8AhAaCyBDbG91ZCBTcWwKCgwKBQUAAgcBEgM8AgsKDAoFBQACBwIS
AzwODwoVCgQFAAIIEgM/Ag0aCCBMb29rZXIKCgwKBQUAAggBEgM/AggKDAoFBQACCAISAz8L
DAoYCgQFAAIJEgNCAhEaCyBWZXJ0ZXggQUkKCgwKBQUAAgkBEgNCAgsKDAoFBQACCQISA0IO
EApvCgIFARIERwBQARpjIFRoaXMgZW51bSBkZXNjcmliZXMgYWxsIHRoZSBzeXN0ZW1zIHRo
YXQgbWFuYWdlCiBUYXhvbm9teSBhbmQgUG9saWN5VGFnIHJlc291cmNlcyBpbiBEYXRhQ2F0
YWxvZy4KCgoKAwUBARIDRwUTChwKBAUBAgASA0kCIhoPIERlZmF1bHQgdmFsdWUKCgwKBQUB
AgABEgNJAh0KDAoFBQECAAISA0kgIQoYCgQFAQIBEgNMAh8aCyBEYXRhcGxleC4KCgwKBQUB
AgEBEgNMAhoKDAoFBQECAQISA0wdHgoUCgQFAQICEgNPAhwaByBPdGhlcgoKDAoFBQECAgES
A08CFwoMCgUFAQICAhIDTxobYgZwcm90bzM=
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Datacatalog::V1::Common::PersonalDetails ===
    # Fields for PersonalDetails
    # Field: starred Type: 8 ()
    # Field: star_time Type: 11 (.google.protobuf.Timestamp)

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Datacatalog::V1::Common - Compiled Protocol Buffers messages for google/cloud/datacatalog/v1/common.proto

=head1 SYNOPSIS

    use Google::Cloud::Datacatalog::V1::Common;

    my $msg = Google::Cloud::Datacatalog::V1::Common::PersonalDetails->new({
        starred => $starred,
        star_time => $star_time,
    });

    # Read or update a field
    my $val = $msg->starred();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Datacatalog::V1::Common::PersonalDetails->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/datacatalog/v1/common.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Datacatalog::V1::Common::PersonalDetails

Entry metadata relevant only to the user and private to them.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->starred() >> / C<< $msg->starred($value) >>

Type: C<Bool>

True if the entry is starred by the user; false otherwise.

=item * C<< $msg->star_time() >> / C<< $msg->star_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Set if the entry is starred; unset otherwise.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Datacatalog::V1::Common::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
