package Google::Cloud::Integrations::V1alpha::ValueType;

use strict;
use warnings;

our $VERSION = '0.14';

use Protobuf::Message;
use Protobuf::DescriptorPool;
use Protobuf::Internal qw(:all);
use MIME::Base64;

BEGIN {
    my $descriptor_b64 = <<'EOF';
CjJnb29nbGUvY2xvdWQvaW50ZWdyYXRpb25zL3YxYWxwaGEvdmFsdWVfdHlwZS5wcm90bxIh
Z29vZ2xlLmNsb3VkLmludGVncmF0aW9ucy52MWFscGhhIrcECglWYWx1ZVR5cGUSIwoMc3Ry
aW5nX3ZhbHVlGAEgASgJSABSC3N0cmluZ1ZhbHVlEh0KCWludF92YWx1ZRgCIAEoA0gAUghp
bnRWYWx1ZRIjCgxkb3VibGVfdmFsdWUYAyABKAFIAFILZG91YmxlVmFsdWUSJQoNYm9vbGVh
bl92YWx1ZRgEIAEoCEgAUgxib29sZWFuVmFsdWUSXAoMc3RyaW5nX2FycmF5GAUgASgLMjcu
Z29vZ2xlLmNsb3VkLmludGVncmF0aW9ucy52MWFscGhhLlN0cmluZ1BhcmFtZXRlckFycmF5
SABSC3N0cmluZ0FycmF5ElMKCWludF9hcnJheRgGIAEoCzI0Lmdvb2dsZS5jbG91ZC5pbnRl
Z3JhdGlvbnMudjFhbHBoYS5JbnRQYXJhbWV0ZXJBcnJheUgAUghpbnRBcnJheRJcCgxkb3Vi
bGVfYXJyYXkYByABKAsyNy5nb29nbGUuY2xvdWQuaW50ZWdyYXRpb25zLnYxYWxwaGEuRG91
YmxlUGFyYW1ldGVyQXJyYXlIAFILZG91YmxlQXJyYXkSXwoNYm9vbGVhbl9hcnJheRgIIAEo
CzI4Lmdvb2dsZS5jbG91ZC5pbnRlZ3JhdGlvbnMudjFhbHBoYS5Cb29sZWFuUGFyYW1ldGVy
QXJyYXlIAFIMYm9vbGVhbkFycmF5Eh8KCmpzb25fdmFsdWUYCSABKAlIAFIJanNvblZhbHVl
QgcKBXZhbHVlIjsKFFN0cmluZ1BhcmFtZXRlckFycmF5EiMKDXN0cmluZ192YWx1ZXMYASAD
KAlSDHN0cmluZ1ZhbHVlcyIyChFJbnRQYXJhbWV0ZXJBcnJheRIdCgppbnRfdmFsdWVzGAEg
AygDUglpbnRWYWx1ZXMiOwoURG91YmxlUGFyYW1ldGVyQXJyYXkSIwoNZG91YmxlX3ZhbHVl
cxgBIAMoAVIMZG91YmxlVmFsdWVzIj4KFUJvb2xlYW5QYXJhbWV0ZXJBcnJheRIlCg5ib29s
ZWFuX3ZhbHVlcxgBIAMoCFINYm9vbGVhblZhbHVlc0KoAQolY29tLmdvb2dsZS5jbG91ZC5p
bnRlZ3JhdGlvbnMudjFhbHBoYUIOVmFsdWVUeXBlUHJvdG9QAVpJY2xvdWQuZ29vZ2xlLmNv
bS9nby9pbnRlZ3JhdGlvbnMvYXBpdjFhbHBoYS9pbnRlZ3JhdGlvbnNwYjtpbnRlZ3JhdGlv
bnNwYqoCIUdvb2dsZS5DbG91ZC5JbnRlZ3JhdGlvbnMuVjFBbHBoYUqsEAoGEgQOAE4BCrwE
CgEMEgMOABIysQQgQ29weXJpZ2h0IDIwMjUgR29vZ2xlIExMQwoKIExpY2Vuc2VkIHVuZGVy
IHRoZSBBcGFjaGUgTGljZW5zZSwgVmVyc2lvbiAyLjAgKHRoZSAiTGljZW5zZSIpOwogeW91
IG1heSBub3QgdXNlIHRoaXMgZmlsZSBleGNlcHQgaW4gY29tcGxpYW5jZSB3aXRoIHRoZSBM
aWNlbnNlLgogWW91IG1heSBvYnRhaW4gYSBjb3B5IG9mIHRoZSBMaWNlbnNlIGF0CgogICAg
IGh0dHA6Ly93d3cuYXBhY2hlLm9yZy9saWNlbnNlcy9MSUNFTlNFLTIuMAoKIFVubGVzcyBy
ZXF1aXJlZCBieSBhcHBsaWNhYmxlIGxhdyBvciBhZ3JlZWQgdG8gaW4gd3JpdGluZywgc29m
dHdhcmUKIGRpc3RyaWJ1dGVkIHVuZGVyIHRoZSBMaWNlbnNlIGlzIGRpc3RyaWJ1dGVkIG9u
IGFuICJBUyBJUyIgQkFTSVMsCiBXSVRIT1VUIFdBUlJBTlRJRVMgT1IgQ09ORElUSU9OUyBP
RiBBTlkgS0lORCwgZWl0aGVyIGV4cHJlc3Mgb3IgaW1wbGllZC4KIFNlZSB0aGUgTGljZW5z
ZSBmb3IgdGhlIHNwZWNpZmljIGxhbmd1YWdlIGdvdmVybmluZyBwZXJtaXNzaW9ucyBhbmQK
IGxpbWl0YXRpb25zIHVuZGVyIHRoZSBMaWNlbnNlLgoKCAoBAhIDEAAqCggKAQgSAxIAPgoJ
CgIIJRIDEgA+CggKAQgSAxMAYAoJCgIICxIDEwBgCggKAQgSAxQAIgoJCgIIChIDFAAiCggK
AQgSAxUALwoJCgIICBIDFQAvCggKAQgSAxYAPgoJCgIIARIDFgA+CigKAgQAEgQZADYBGhwg
VGhlIHR5cGUgb2YgdGhlIHBhcmFtZXRlci4KCgoKAwQAARIDGQgRCgwKBAQACAASBBoCNQMK
DAoFBAAIAAESAxoIDQoWCgQEAAIAEgMcBBwaCSBTdHJpbmcuCgoMCgUEAAIABRIDHAQKCgwK
BQQAAgABEgMcCxcKDAoFBAACAAMSAxwaGwoXCgQEAAIBEgMfBBgaCiBJbnRlZ2VyLgoKDAoF
BAACAQUSAx8ECQoMCgUEAAIBARIDHwoTCgwKBQQAAgEDEgMfFhcKHQoEBAACAhIDIgQcGhAg
RG91YmxlIE51bWJlci4KCgwKBQQAAgIFEgMiBAoKDAoFBAACAgESAyILFwoMCgUEAAICAxID
IhobChcKBAQAAgMSAyUEGxoKIEJvb2xlYW4uCgoMCgUEAAIDBRIDJQQICgwKBQQAAgMBEgMl
CRYKDAoFBAACAwMSAyUZGgocCgQEAAIEEgMoBCoaDyBTdHJpbmcgQXJyYXkuCgoMCgUEAAIE
BhIDKAQYCgwKBQQAAgQBEgMoGSUKDAoFBAACBAMSAygoKQodCgQEAAIFEgMrBCQaECBJbnRl
Z2VyIEFycmF5LgoKDAoFBAACBQYSAysEFQoMCgUEAAIFARIDKxYfCgwKBQQAAgUDEgMrIiMK
IwoEBAACBhIDLgQqGhYgRG91YmxlIE51bWJlciBBcnJheS4KCgwKBQQAAgYGEgMuBBgKDAoF
BAACBgESAy4ZJQoMCgUEAAIGAxIDLigpCh0KBAQAAgcSAzEELBoQIEJvb2xlYW4gQXJyYXku
CgoMCgUEAAIHBhIDMQQZCgwKBQQAAgcBEgMxGicKDAoFBAACBwMSAzEqKwoUCgQEAAIIEgM0
BBoaByBKc29uLgoKDAoFBAACCAUSAzQECgoMCgUEAAIIARIDNAsVCgwKBQQAAggDEgM0GBkK
QQoCBAESBDkAPAEaNSBUaGlzIG1lc3NhZ2Ugb25seSBjb250YWlucyBhIGZpZWxkIG9mIHN0
cmluZyBhcnJheS4KCgoKAwQBARIDOQgcChwKBAQBAgASAzsCJBoPIFN0cmluZyBhcnJheS4K
CgwKBQQBAgAEEgM7AgoKDAoFBAECAAUSAzsLEQoMCgUEAQIAARIDOxIfCgwKBQQBAgADEgM7
IiMKQgoCBAISBD8AQgEaNiBUaGlzIG1lc3NhZ2Ugb25seSBjb250YWlucyBhIGZpZWxkIG9m
IGludGVnZXIgYXJyYXkuCgoKCgMEAgESAz8IGQodCgQEAgIAEgNBAiAaECBJbnRlZ2VyIGFy
cmF5LgoKDAoFBAICAAQSA0ECCgoMCgUEAgIABRIDQQsQCgwKBQQCAgABEgNBERsKDAoFBAIC
AAMSA0EeHwpICgIEAxIERQBIARo8IFRoaXMgbWVzc2FnZSBvbmx5IGNvbnRhaW5zIGEgZmll
bGQgb2YgZG91YmxlIG51bWJlciBhcnJheS4KCgoKAwQDARIDRQgcCiMKBAQDAgASA0cCJBoW
IERvdWJsZSBudW1iZXIgYXJyYXkuCgoMCgUEAwIABBIDRwIKCgwKBQQDAgAFEgNHCxEKDAoF
BAMCAAESA0cSHwoMCgUEAwIAAxIDRyIjCkIKAgQEEgRLAE4BGjYgVGhpcyBtZXNzYWdlIG9u
bHkgY29udGFpbnMgYSBmaWVsZCBvZiBib29sZWFuIGFycmF5LgoKCgoDBAQBEgNLCB0KHQoE
BAQCABIDTQIjGhAgQm9vbGVhbiBhcnJheS4KCgwKBQQEAgAEEgNNAgoKDAoFBAQCAAUSA00L
DwoMCgUEBAIAARIDTRAeCgwKBQQEAgADEgNNISJiBnByb3RvMw==
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Integrations::V1alpha::ValueType::ValueType ===
    # Fields for ValueType
    # Field: string_value Type: 9 ()
    # Field: int_value Type: 3 ()
    # Field: double_value Type: 1 ()
    # Field: boolean_value Type: 8 ()
    # Field: string_array Type: 11 (.google.cloud.integrations.v1alpha.StringParameterArray)
    # Field: int_array Type: 11 (.google.cloud.integrations.v1alpha.IntParameterArray)
    # Field: double_array Type: 11 (.google.cloud.integrations.v1alpha.DoubleParameterArray)
    # Field: boolean_array Type: 11 (.google.cloud.integrations.v1alpha.BooleanParameterArray)
    # Field: json_value Type: 9 ()

# === Message: Google::Cloud::Integrations::V1alpha::ValueType::StringParameterArray ===
    # Fields for StringParameterArray
    # Field: string_values Type: 9 ()

# === Message: Google::Cloud::Integrations::V1alpha::ValueType::IntParameterArray ===
    # Fields for IntParameterArray
    # Field: int_values Type: 3 ()

# === Message: Google::Cloud::Integrations::V1alpha::ValueType::DoubleParameterArray ===
    # Fields for DoubleParameterArray
    # Field: double_values Type: 1 ()

# === Message: Google::Cloud::Integrations::V1alpha::ValueType::BooleanParameterArray ===
    # Fields for BooleanParameterArray
    # Field: boolean_values Type: 8 ()

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Integrations::V1alpha::ValueType - Compiled Protocol Buffers messages for google/cloud/integrations/v1alpha/value_type.proto

=head1 SYNOPSIS

    use Google::Cloud::Integrations::V1alpha::ValueType;

    my $msg = Google::Cloud::Integrations::V1alpha::ValueType::ValueType->new({
        string_value => $string_value,
        int_value => $int_value,
        double_value => $double_value,
        boolean_value => $boolean_value,
    });

    # Read or update a field
    my $val = $msg->string_value();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Integrations::V1alpha::ValueType::ValueType->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/integrations/v1alpha/value_type.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Integrations::V1alpha::ValueType::ValueType

The type of the parameter.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->string_value() >> / C<< $msg->string_value($value) >>

Type: C<String>

String.

=item * C<< $msg->int_value() >> / C<< $msg->int_value($value) >>

Type: C<Int64>

Integer.

=item * C<< $msg->double_value() >> / C<< $msg->double_value($value) >>

Type: C<Double>

Double Number.

=item * C<< $msg->boolean_value() >> / C<< $msg->boolean_value($value) >>

Type: C<Bool>

Boolean.

=item * C<< $msg->string_array() >> / C<< $msg->string_array($value) >>

Type: C<Message> (L<Google::Cloud::Integrations::V1alpha::ValueType::StringParameterArray>)

String Array.

=item * C<< $msg->int_array() >> / C<< $msg->int_array($value) >>

Type: C<Message> (L<Google::Cloud::Integrations::V1alpha::ValueType::IntParameterArray>)

Integer Array.

=item * C<< $msg->double_array() >> / C<< $msg->double_array($value) >>

Type: C<Message> (L<Google::Cloud::Integrations::V1alpha::ValueType::DoubleParameterArray>)

Double Number Array.

=item * C<< $msg->boolean_array() >> / C<< $msg->boolean_array($value) >>

Type: C<Message> (L<Google::Cloud::Integrations::V1alpha::ValueType::BooleanParameterArray>)

Boolean Array.

=item * C<< $msg->json_value() >> / C<< $msg->json_value($value) >>

Type: C<String>

Json.

=back

=head2 Google::Cloud::Integrations::V1alpha::ValueType::StringParameterArray

This message only contains a field of string array.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->string_values() >> / C<< $msg->string_values($value) >>

Type: C<String>

String array.

=back

=head2 Google::Cloud::Integrations::V1alpha::ValueType::IntParameterArray

This message only contains a field of integer array.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->int_values() >> / C<< $msg->int_values($value) >>

Type: C<Int64>

Integer array.

=back

=head2 Google::Cloud::Integrations::V1alpha::ValueType::DoubleParameterArray

This message only contains a field of double number array.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->double_values() >> / C<< $msg->double_values($value) >>

Type: C<Double>

Double number array.

=back

=head2 Google::Cloud::Integrations::V1alpha::ValueType::BooleanParameterArray

This message only contains a field of boolean array.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->boolean_values() >> / C<< $msg->boolean_values($value) >>

Type: C<Bool>

Boolean array.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Integrations::V1alpha::ValueType::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
