package Google::Cloud::Securitycenter::V1::EventThreatDetectionCustomModuleValidationErrors;

use strict;
use warnings;

our $VERSION = '0.14';

use Protobuf::Message;
use Protobuf::DescriptorPool;
use Protobuf::Internal qw(:all);
use MIME::Base64;

BEGIN {
    my $descriptor_b64 = <<'EOF';
Cltnb29nbGUvY2xvdWQvc2VjdXJpdHljZW50ZXIvdjEvZXZlbnRfdGhyZWF0X2RldGVjdGlv
bl9jdXN0b21fbW9kdWxlX3ZhbGlkYXRpb25fZXJyb3JzLnByb3RvEh5nb29nbGUuY2xvdWQu
c2VjdXJpdHljZW50ZXIudjEicwocQ3VzdG9tTW9kdWxlVmFsaWRhdGlvbkVycm9ycxJTCgZl
cnJvcnMYASADKAsyOy5nb29nbGUuY2xvdWQuc2VjdXJpdHljZW50ZXIudjEuQ3VzdG9tTW9k
dWxlVmFsaWRhdGlvbkVycm9yUgZlcnJvcnMi9gEKG0N1c3RvbU1vZHVsZVZhbGlkYXRpb25F
cnJvchIgCgtkZXNjcmlwdGlvbhgBIAEoCVILZGVzY3JpcHRpb24SHQoKZmllbGRfcGF0aBgC
IAEoCVIJZmllbGRQYXRoEkMKBXN0YXJ0GAMgASgLMiguZ29vZ2xlLmNsb3VkLnNlY3VyaXR5
Y2VudGVyLnYxLlBvc2l0aW9uSABSBXN0YXJ0iAEBEj8KA2VuZBgEIAEoCzIoLmdvb2dsZS5j
bG91ZC5zZWN1cml0eWNlbnRlci52MS5Qb3NpdGlvbkgBUgNlbmSIAQFCCAoGX3N0YXJ0QgYK
BF9lbmQiUAoIUG9zaXRpb24SHwoLbGluZV9udW1iZXIYASABKAVSCmxpbmVOdW1iZXISIwoN
Y29sdW1uX251bWJlchgCIAEoBVIMY29sdW1uTnVtYmVyQo8CCiJjb20uZ29vZ2xlLmNsb3Vk
LnNlY3VyaXR5Y2VudGVyLnYxQjVFdmVudFRocmVhdERldGVjdGlvbkN1c3RvbU1vZHVsZVZh
bGlkYXRpb25FcnJvcnNQcm90b1ABWkpjbG91ZC5nb29nbGUuY29tL2dvL3NlY3VyaXR5Y2Vu
dGVyL2FwaXYxL3NlY3VyaXR5Y2VudGVycGI7c2VjdXJpdHljZW50ZXJwYqoCHkdvb2dsZS5D
bG91ZC5TZWN1cml0eUNlbnRlci5WMcoCHkdvb2dsZVxDbG91ZFxTZWN1cml0eUNlbnRlclxW
MeoCIUdvb2dsZTo6Q2xvdWQ6OlNlY3VyaXR5Q2VudGVyOjpWMUq/EAoGEgQOADoBCrwECgEM
EgMOABIysQQgQ29weXJpZ2h0IDIwMjUgR29vZ2xlIExMQwoKIExpY2Vuc2VkIHVuZGVyIHRo
ZSBBcGFjaGUgTGljZW5zZSwgVmVyc2lvbiAyLjAgKHRoZSAiTGljZW5zZSIpOwogeW91IG1h
eSBub3QgdXNlIHRoaXMgZmlsZSBleGNlcHQgaW4gY29tcGxpYW5jZSB3aXRoIHRoZSBMaWNl
bnNlLgogWW91IG1heSBvYnRhaW4gYSBjb3B5IG9mIHRoZSBMaWNlbnNlIGF0CgogICAgIGh0
dHA6Ly93d3cuYXBhY2hlLm9yZy9saWNlbnNlcy9MSUNFTlNFLTIuMAoKIFVubGVzcyByZXF1
aXJlZCBieSBhcHBsaWNhYmxlIGxhdyBvciBhZ3JlZWQgdG8gaW4gd3JpdGluZywgc29mdHdh
cmUKIGRpc3RyaWJ1dGVkIHVuZGVyIHRoZSBMaWNlbnNlIGlzIGRpc3RyaWJ1dGVkIG9uIGFu
ICJBUyBJUyIgQkFTSVMsCiBXSVRIT1VUIFdBUlJBTlRJRVMgT1IgQ09ORElUSU9OUyBPRiBB
TlkgS0lORCwgZWl0aGVyIGV4cHJlc3Mgb3IgaW1wbGllZC4KIFNlZSB0aGUgTGljZW5zZSBm
b3IgdGhlIHNwZWNpZmljIGxhbmd1YWdlIGdvdmVybmluZyBwZXJtaXNzaW9ucyBhbmQKIGxp
bWl0YXRpb25zIHVuZGVyIHRoZSBMaWNlbnNlLgoKCAoBAhIDEAAnCggKAQgSAxIAOwoJCgII
JRIDEgA7CggKAQgSAxMAYQoJCgIICxIDEwBhCggKAQgSAxQAIgoJCgIIChIDFAAiCggKAQgS
AxUAVgoJCgIICBIDFQBWCggKAQgSAxYAOwoJCgIIARIDFgA7CggKAQgSAxcAOwoJCgIIKRID
FwA7CggKAQgSAxgAOgoJCgIILRIDGAA6CpEBCgIEABIEHAAeARqEASBBIGxpc3Qgb2YgemVy
byBvciBtb3JlIGVycm9ycyBlbmNvdW50ZXJlZCB3aGlsZSB2YWxpZGF0aW5nIHRoZSB1cGxv
YWRlZAogY29uZmlndXJhdGlvbiBvZiBhbiBFdmVudCBUaHJlYXQgRGV0ZWN0aW9uIEN1c3Rv
bSBNb2R1bGUuCgoKCgMEAAESAxwIJAoLCgQEAAIAEgMdAjIKDAoFBAACAAQSAx0CCgoMCgUE
AAIABhIDHQsmCgwKBQQAAgABEgMdJy0KDAoFBAACAAMSAx0wMQp7CgIEARIEIgAzARpvIEFu
IGVycm9yIGVuY291bnRlcmVkIHdoaWxlIHZhbGlkYXRpbmcgdGhlIHVwbG9hZGVkIGNvbmZp
Z3VyYXRpb24gb2YgYW4KIEV2ZW50IFRocmVhdCBEZXRlY3Rpb24gQ3VzdG9tIE1vZHVsZS4K
CgoKAwQBARIDIggjClQKBAQBAgASAyQCGRpHIEEgZGVzY3JpcHRpb24gb2YgdGhlIGVycm9y
LCBzdWl0YWJsZSBmb3IgaHVtYW4gY29uc3VtcHRpb24uIFJlcXVpcmVkLgoKDAoFBAECAAUS
AyQCCAoMCgUEAQIAARIDJAkUCgwKBQQBAgADEgMkFxgKmQEKBAQBAgESAygCGBqLASBUaGUg
cGF0aCwgaW4gUkZDIDg5MDEgSlNPTiBQb2ludGVyIGZvcm1hdCwgdG8gdGhlIGZpZWxkIHRo
YXQgZmFpbGVkCiB2YWxpZGF0aW9uLiBUaGlzIG1heSBiZSBsZWZ0IGVtcHR5IGlmIG5vIHNw
ZWNpZmljIGZpZWxkIGlzIGFmZmVjdGVkLgoKDAoFBAECAQUSAygCCAoMCgUEAQIBARIDKAkT
CgwKBQQBAgEDEgMoFhcKuwEKBAQBAgISAy0CHhqtASBUaGUgaW5pdGlhbCBwb3NpdGlvbiBv
ZiB0aGUgZXJyb3IgaW4gdGhlIHVwbG9hZGVkIHRleHQgdmVyc2lvbiBvZiB0aGUKIG1vZHVs
ZS4gVGhpcyBmaWVsZCBtYXkgYmUgb21pdHRlZCBpZiBubyBzcGVjaWZpYyBwb3NpdGlvbiBh
cHBsaWVzLCBvciBpZgogb25lIGNvdWxkIG5vdCBiZSBjb21wdXRlZC4KCgwKBQQBAgIEEgMt
AgoKDAoFBAECAgYSAy0LEwoMCgUEAQICARIDLRQZCgwKBQQBAgIDEgMtHB0KuAEKBAQBAgMS
AzICHBqqASBUaGUgZW5kIHBvc2l0aW9uIG9mIHRoZSBlcnJvciBpbiB0aGUgdXBsb2FkZWQg
dGV4dCB2ZXJzaW9uIG9mIHRoZQogbW9kdWxlLiBUaGlzIGZpZWxkIG1heSBiZSBvbWl0dGVk
IGlmIG5vIHNwZWNpZmljIHBvc2l0aW9uIGFwcGxpZXMsIG9yIGlmCiBvbmUgY291bGQgbm90
IGJlIGNvbXB1dGVkLi4KCgwKBQQBAgMEEgMyAgoKDAoFBAECAwYSAzILEwoMCgUEAQIDARID
MhQXCgwKBQQBAgMDEgMyGhsKQgoCBAISBDYAOgEaNiBBIHBvc2l0aW9uIGluIHRoZSB1cGxv
YWRlZCB0ZXh0IHZlcnNpb24gb2YgYSBtb2R1bGUuCgoKCgMEAgESAzYIEAoLCgQEAgIAEgM3
AhgKDAoFBAICAAUSAzcCBwoMCgUEAgIAARIDNwgTCgwKBQQCAgADEgM3FhcKCwoEBAICARID
OQIaCgwKBQQCAgEFEgM5AgcKDAoFBAICAQESAzkIFQoMCgUEAgIBAxIDORgZYgZwcm90bzM=

EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Securitycenter::V1::EventThreatDetectionCustomModuleValidationErrors::CustomModuleValidationErrors ===
    # Fields for CustomModuleValidationErrors
    # Field: errors Type: 11 (.google.cloud.securitycenter.v1.CustomModuleValidationError)

# === Message: Google::Cloud::Securitycenter::V1::EventThreatDetectionCustomModuleValidationErrors::CustomModuleValidationError ===
    # Fields for CustomModuleValidationError
    # Field: description Type: 9 ()
    # Field: field_path Type: 9 ()
    # Field: start Type: 11 (.google.cloud.securitycenter.v1.Position)
    # Field: end Type: 11 (.google.cloud.securitycenter.v1.Position)

# === Message: Google::Cloud::Securitycenter::V1::EventThreatDetectionCustomModuleValidationErrors::Position ===
    # Fields for Position
    # Field: line_number Type: 5 ()
    # Field: column_number Type: 5 ()

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Securitycenter::V1::EventThreatDetectionCustomModuleValidationErrors - Compiled Protocol Buffers messages for google/cloud/securitycenter/v1/event_threat_detection_custom_module_validation_errors.proto

=head1 SYNOPSIS

    use Google::Cloud::Securitycenter::V1::EventThreatDetectionCustomModuleValidationErrors;

    my $msg = Google::Cloud::Securitycenter::V1::EventThreatDetectionCustomModuleValidationErrors::CustomModuleValidationErrors->new({
        errors => $errors,
    });

    # Read or update a field
    my $val = $msg->errors();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Securitycenter::V1::EventThreatDetectionCustomModuleValidationErrors::CustomModuleValidationErrors->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/securitycenter/v1/event_threat_detection_custom_module_validation_errors.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Securitycenter::V1::EventThreatDetectionCustomModuleValidationErrors::CustomModuleValidationErrors

A list of zero or more errors encountered while validating the uploaded
configuration of an Event Threat Detection Custom Module.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->errors() >> / C<< $msg->errors($value) >>

Type: C<Message> (L<Google::Cloud::Securitycenter::V1::EventThreatDetectionCustomModuleValidationErrors::CustomModuleValidationError>)

=back

=head2 Google::Cloud::Securitycenter::V1::EventThreatDetectionCustomModuleValidationErrors::CustomModuleValidationError

An error encountered while validating the uploaded configuration of an
Event Threat Detection Custom Module.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->description() >> / C<< $msg->description($value) >>

Type: C<String>

A description of the error, suitable for human consumption. Required.

=item * C<< $msg->field_path() >> / C<< $msg->field_path($value) >>

Type: C<String>

The path, in RFC 8901 JSON Pointer format, to the field that failed
validation. This may be left empty if no specific field is affected.

=item * C<< $msg->start() >> / C<< $msg->start($value) >>

Type: C<Message> (L<Google::Cloud::Securitycenter::V1::EventThreatDetectionCustomModuleValidationErrors::Position>)

The initial position of the error in the uploaded text version of the
module. This field may be omitted if no specific position applies, or if
one could not be computed.

=item * C<< $msg->end() >> / C<< $msg->end($value) >>

Type: C<Message> (L<Google::Cloud::Securitycenter::V1::EventThreatDetectionCustomModuleValidationErrors::Position>)

The end position of the error in the uploaded text version of the
module. This field may be omitted if no specific position applies, or if
one could not be computed..

=back

=head2 Google::Cloud::Securitycenter::V1::EventThreatDetectionCustomModuleValidationErrors::Position

A position in the uploaded text version of a module.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->line_number() >> / C<< $msg->line_number($value) >>

Type: C<Int32>

=item * C<< $msg->column_number() >> / C<< $msg->column_number($value) >>

Type: C<Int32>

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Securitycenter::V1::EventThreatDetectionCustomModuleValidationErrors::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
