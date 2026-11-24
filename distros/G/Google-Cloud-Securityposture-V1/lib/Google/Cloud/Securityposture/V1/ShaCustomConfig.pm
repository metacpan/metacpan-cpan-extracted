package Google::Cloud::Securityposture::V1::ShaCustomConfig;

use strict;
use warnings;

our $VERSION = '0.14';

use Protobuf::Message;
use Protobuf::DescriptorPool;
use Protobuf::Internal qw(:all);
use MIME::Base64;

BEGIN {
    eval { require Google::Api::FieldBehavior };
    eval { require Google::Type::Expr };
    my $descriptor_b64 = <<'EOF';
Cjdnb29nbGUvY2xvdWQvc2VjdXJpdHlwb3N0dXJlL3YxL3NoYV9jdXN0b21fY29uZmlnLnBy
b3RvEh9nb29nbGUuY2xvdWQuc2VjdXJpdHlwb3N0dXJlLnYxGh9nb29nbGUvYXBpL2ZpZWxk
X2JlaGF2aW9yLnByb3RvGhZnb29nbGUvdHlwZS9leHByLnByb3RvIssGCgxDdXN0b21Db25m
aWcSNAoJcHJlZGljYXRlGAEgASgLMhEuZ29vZ2xlLnR5cGUuRXhwckID4EECUglwcmVkaWNh
dGUSaAoNY3VzdG9tX291dHB1dBgCIAEoCzI+Lmdvb2dsZS5jbG91ZC5zZWN1cml0eXBvc3R1
cmUudjEuQ3VzdG9tQ29uZmlnLkN1c3RvbU91dHB1dFNwZWNCA+BBAVIMY3VzdG9tT3V0cHV0
EnAKEXJlc291cmNlX3NlbGVjdG9yGAMgASgLMj4uZ29vZ2xlLmNsb3VkLnNlY3VyaXR5cG9z
dHVyZS52MS5DdXN0b21Db25maWcuUmVzb3VyY2VTZWxlY3RvckID4EECUhByZXNvdXJjZVNl
bGVjdG9yElcKCHNldmVyaXR5GAQgASgOMjYuZ29vZ2xlLmNsb3VkLnNlY3VyaXR5cG9zdHVy
ZS52MS5DdXN0b21Db25maWcuU2V2ZXJpdHlCA+BBAlIIc2V2ZXJpdHkSJQoLZGVzY3JpcHRp
b24YBSABKAlCA+BBAVILZGVzY3JpcHRpb24SKwoOcmVjb21tZW5kYXRpb24YBiABKAlCA+BB
AVIOcmVjb21tZW5kYXRpb24a6AEKEEN1c3RvbU91dHB1dFNwZWMSbAoKcHJvcGVydGllcxgB
IAMoCzJHLmdvb2dsZS5jbG91ZC5zZWN1cml0eXBvc3R1cmUudjEuQ3VzdG9tQ29uZmlnLkN1
c3RvbU91dHB1dFNwZWMuUHJvcGVydHlCA+BBAVIKcHJvcGVydGllcxpmCghQcm9wZXJ0eRIX
CgRuYW1lGAEgASgJQgPgQQJSBG5hbWUSQQoQdmFsdWVfZXhwcmVzc2lvbhgCIAEoCzIRLmdv
b2dsZS50eXBlLkV4cHJCA+BBAVIPdmFsdWVFeHByZXNzaW9uGj4KEFJlc291cmNlU2VsZWN0
b3ISKgoOcmVzb3VyY2VfdHlwZXMYASADKAlCA+BBAlINcmVzb3VyY2VUeXBlcyJRCghTZXZl
cml0eRIYChRTRVZFUklUWV9VTlNQRUNJRklFRBAAEgwKCENSSVRJQ0FMEAESCAoESElHSBAC
EgoKBk1FRElVTRADEgcKA0xPVxAEQowBCiNjb20uZ29vZ2xlLmNsb3VkLnNlY3VyaXR5cG9z
dHVyZS52MUIUU2hhQ3VzdG9tQ29uZmlnUHJvdG9QAVpNY2xvdWQuZ29vZ2xlLmNvbS9nby9z
ZWN1cml0eXBvc3R1cmUvYXBpdjEvc2VjdXJpdHlwb3N0dXJlcGI7c2VjdXJpdHlwb3N0dXJl
cGJK0R8KBhIEDgBlAQq8BAoBDBIDDgASMrEEIENvcHlyaWdodCAyMDI1IEdvb2dsZSBMTEMK
CiBMaWNlbnNlZCB1bmRlciB0aGUgQXBhY2hlIExpY2Vuc2UsIFZlcnNpb24gMi4wICh0aGUg
IkxpY2Vuc2UiKTsKIHlvdSBtYXkgbm90IHVzZSB0aGlzIGZpbGUgZXhjZXB0IGluIGNvbXBs
aWFuY2Ugd2l0aCB0aGUgTGljZW5zZS4KIFlvdSBtYXkgb2J0YWluIGEgY29weSBvZiB0aGUg
TGljZW5zZSBhdAoKICAgICBodHRwOi8vd3d3LmFwYWNoZS5vcmcvbGljZW5zZXMvTElDRU5T
RS0yLjAKCiBVbmxlc3MgcmVxdWlyZWQgYnkgYXBwbGljYWJsZSBsYXcgb3IgYWdyZWVkIHRv
IGluIHdyaXRpbmcsIHNvZnR3YXJlCiBkaXN0cmlidXRlZCB1bmRlciB0aGUgTGljZW5zZSBp
cyBkaXN0cmlidXRlZCBvbiBhbiAiQVMgSVMiIEJBU0lTLAogV0lUSE9VVCBXQVJSQU5USUVT
IE9SIENPTkRJVElPTlMgT0YgQU5ZIEtJTkQsIGVpdGhlciBleHByZXNzIG9yIGltcGxpZWQu
CiBTZWUgdGhlIExpY2Vuc2UgZm9yIHRoZSBzcGVjaWZpYyBsYW5ndWFnZSBnb3Zlcm5pbmcg
cGVybWlzc2lvbnMgYW5kCiBsaW1pdGF0aW9ucyB1bmRlciB0aGUgTGljZW5zZS4KCggKAQIS
AxAAKAoJCgIDABIDEgApCgkKAgMBEgMTACAKCAoBCBIDFQBkCgkKAggLEgMVAGQKCAoBCBID
FgAiCgkKAggKEgMWACIKCAoBCBIDFwA1CgkKAggIEgMXADUKCAoBCBIDGAA8CgkKAggBEgMY
ADwK5AEKAgQAEgQdAGUBGtcBIERlZmluZXMgdGhlIHByb3BlcnRpZXMgaW4gYSBjdXN0b20g
bW9kdWxlIGNvbmZpZ3VyYXRpb24gZm9yIFNlY3VyaXR5CiBIZWFsdGggQW5hbHl0aWNzLiBV
c2UgdGhlIGN1c3RvbSBtb2R1bGUgY29uZmlndXJhdGlvbiB0byBjcmVhdGUgY3VzdG9tCiBk
ZXRlY3RvcnMgdGhhdCBnZW5lcmF0ZSBjdXN0b20gZmluZGluZ3MgZm9yIHJlc291cmNlcyB0
aGF0IHlvdSBzcGVjaWZ5LgoKCgoDBAABEgMdCBQKjQIKBAQAAwASBCICMQMa/gEgQSBzZXQg
b2Ygb3B0aW9uYWwgbmFtZS12YWx1ZSBwYWlycyB0aGF0IGRlZmluZSBjdXN0b20gc291cmNl
IHByb3BlcnRpZXMgdG8KIHJldHVybiB3aXRoIGVhY2ggZmluZGluZyB0aGF0IGlzIGdlbmVy
YXRlZCBieSB0aGUgY3VzdG9tIG1vZHVsZS4gVGhlIGN1c3RvbQogc291cmNlIHByb3BlcnRp
ZXMgdGhhdCBhcmUgZGVmaW5lZCBoZXJlIGFyZSBpbmNsdWRlZCBpbiB0aGUgZmluZGluZyBK
U09OCiB1bmRlciBgc291cmNlUHJvcGVydGllc2AuCgoMCgUEAAMAARIDIgoaClYKBgQAAwAD
ABIEJAQtBRpGIEFuIGluZGl2aWR1YWwgbmFtZS12YWx1ZSBwYWlyIHRoYXQgZGVmaW5lcyBh
IGN1c3RvbSBzb3VyY2UgcHJvcGVydHkuCgoOCgcEAAMAAwABEgMkDBQKSAoIBAADAAMAAgAS
AyYGPxo3IFJlcXVpcmVkLiBOYW1lIG9mIHRoZSBwcm9wZXJ0eSBmb3IgdGhlIGN1c3RvbSBv
dXRwdXQuCgoQCgkEAAMAAwACAAUSAyYGDAoQCgkEAAMAAwACAAESAyYNEQoQCgkEAAMAAwAC
AAMSAyYUFQoQCgkEAAMAAwACAAgSAyYWPgoTCgwEAAMAAwACAAicCAASAyYXPQrBAQoIBAAD
AAMAAgESBCsGLDMargEgT3B0aW9uYWwuIFRoZSBDRUwgZXhwcmVzc2lvbiBmb3IgdGhlIGN1
c3RvbSBvdXRwdXQuIEEgcmVzb3VyY2UgcHJvcGVydHkKIGNhbiBiZSBzcGVjaWZpZWQgdG8g
cmV0dXJuIHRoZSB2YWx1ZSBvZiB0aGUgcHJvcGVydHkgb3IgYSB0ZXh0IHN0cmluZwogZW5j
bG9zZWQgaW4gcXVvdGF0aW9uIG1hcmtzLgoKEAoJBAADAAMAAgEGEgMrBhYKEAoJBAADAAMA
AgEBEgMrFycKEAoJBAADAAMAAgEDEgMrKisKEAoJBAADAAMAAgEIEgMsCjIKEwoMBAADAAMA
AgEInAgAEgMsCzEKVAoGBAADAAIAEgMwBE4aRSBPcHRpb25hbC4gQSBsaXN0IG9mIGN1c3Rv
bSBvdXRwdXQgcHJvcGVydGllcyB0byBhZGQgdG8gdGhlIGZpbmRpbmcuCgoOCgcEAAMAAgAE
EgMwBAwKDgoHBAADAAIABhIDMA0VCg4KBwQAAwACAAESAzAWIAoOCgcEAAMAAgADEgMwIyQK
DgoHBAADAAIACBIDMCVNChEKCgQAAwACAAicCAASAzAmTAo1CgQEAAMBEgQ0AjcDGicgUmVz
b3VyY2UgZm9yIHNlbGVjdGluZyByZXNvdXJjZSB0eXBlLgoKDAoFBAADAQESAzQKGgpFCgYE
AAMBAgASAzYEUBo2IFJlcXVpcmVkLiBUaGUgcmVzb3VyY2UgdHlwZXMgdG8gcnVuIHRoZSBk
ZXRlY3RvciBvbi4KCg4KBwQAAwECAAQSAzYEDAoOCgcEAAMBAgAFEgM2DRMKDgoHBAADAQIA
ARIDNhQiCg4KBwQAAwECAAMSAzYlJgoOCgcEAAMBAgAIEgM2J08KEQoKBAADAQIACJwIABID
NihOCk4KBAQABAASBDoCSQMaQCBEZWZpbmVzIHRoZSB2YWxpZCB2YWx1ZSBvcHRpb25zIGZv
ciB0aGUgc2V2ZXJpdHkgb2YgYSBmaW5kaW5nLgoKDAoFBAAEAAESAzoHDwomCgYEAAQAAgAS
AzwEHRoXIFVuc3BlY2lmaWVkIHNldmVyaXR5LgoKDgoHBAAEAAIAARIDPAQYCg4KBwQABAAC
AAISAzwbHAojCgYEAAQAAgESAz8EERoUIENyaXRpY2FsIHNldmVyaXR5LgoKDgoHBAAEAAIB
ARIDPwQMCg4KBwQABAACAQISAz8PEAofCgYEAAQAAgISA0IEDRoQIEhpZ2ggc2V2ZXJpdHku
CgoOCgcEAAQAAgIBEgNCBAgKDgoHBAAEAAICAhIDQgsMCiEKBgQABAACAxIDRQQPGhIgTWVk
aXVtIHNldmVyaXR5LgoKDgoHBAAEAAIDARIDRQQKCg4KBwQABAACAwISA0UNDgoeCgYEAAQA
AgQSA0gEDBoPIExvdyBzZXZlcml0eS4KCg4KBwQABAACBAESA0gEBwoOCgcEAAQAAgQCEgNI
CgsKoAEKBAQAAgASA00CShqSASBSZXF1aXJlZC4gVGhlIENFTCBleHByZXNzaW9uIHRvIGV2
YWx1YXRlIHRvIHByb2R1Y2UgZmluZGluZ3MuIFdoZW4gdGhlCiBleHByZXNzaW9uIGV2YWx1
YXRlcyB0byB0cnVlIGFnYWluc3QgYSByZXNvdXJjZSwgYSBmaW5kaW5nIGlzIGdlbmVyYXRl
ZC4KCgwKBQQAAgAGEgNNAhIKDAoFBAACAAESA00THAoMCgUEAAIAAxIDTR8gCgwKBQQAAgAI
EgNNIUkKDwoIBAACAAicCAASA00iSAoyCgQEAAIBEgNQAk4aJSBPcHRpb25hbC4gQ3VzdG9t
IG91dHB1dCBwcm9wZXJ0aWVzLgoKDAoFBAACAQYSA1ACEgoMCgUEAAIBARIDUBMgCgwKBQQA
AgEDEgNQIyQKDAoFBAACAQgSA1AlTQoPCggEAAIBCJwIABIDUCZMCogBCgQEAAICEgRUAlUv
GnogUmVxdWlyZWQuIFRoZSByZXNvdXJjZSB0eXBlcyB0aGF0IHRoZSBjdXN0b20gbW9kdWxl
IG9wZXJhdGVzIG9uLiBFYWNoCiBjdXN0b20gbW9kdWxlIGNhbiBzcGVjaWZ5IHVwIHRvIDUg
cmVzb3VyY2UgdHlwZXMuCgoMCgUEAAICBhIDVAISCgwKBQQAAgIBEgNUEyQKDAoFBAACAgMS
A1QnKAoMCgUEAAICCBIDVQYuCg8KCAQAAgIInAgAEgNVBy0KVAoEBAACAxIDWAJBGkcgUmVx
dWlyZWQuIFRoZSBzZXZlcml0eSB0byBhc3NpZ24gdG8gZmluZGluZ3MgZ2VuZXJhdGVkIGJ5
IHRoZSBtb2R1bGUuCgoMCgUEAAIDBhIDWAIKCgwKBQQAAgMBEgNYCxMKDAoFBAACAwMSA1gW
FwoMCgUEAAIDCBIDWBhACg8KCAQAAgMInAgAEgNYGT8KkQIKBAQAAgQSA14CQhqDAiBPcHRp
b25hbC4gVGV4dCB0aGF0IGRlc2NyaWJlcyB0aGUgdnVsbmVyYWJpbGl0eSBvciBtaXNjb25m
aWd1cmF0aW9uIHRoYXQKIHRoZSBjdXN0b20gbW9kdWxlIGRldGVjdHMuIFRoaXMgZXhwbGFu
YXRpb24gaXMgcmV0dXJuZWQgd2l0aCBlYWNoIGZpbmRpbmcKIGluc3RhbmNlIHRvIGhlbHAg
aW52ZXN0aWdhdG9ycyB1bmRlcnN0YW5kIHRoZSBkZXRlY3RlZCBpc3N1ZS4gVGhlIHRleHQg
bXVzdAogYmUgZW5jbG9zZWQgaW4gcXVvdGF0aW9uIG1hcmtzLgoKDAoFBAACBAUSA14CCAoM
CgUEAAIEARIDXgkUCgwKBQQAAgQDEgNeFxgKDAoFBAACBAgSA14ZQQoPCggEAAIECJwIABID
XhpACvkBCgQEAAIFEgNkAkUa6wEgT3B0aW9uYWwuIEFuIGV4cGxhbmF0aW9uIG9mIHRoZSBy
ZWNvbW1lbmRlZCBzdGVwcyB0aGF0IHNlY3VyaXR5IHRlYW1zIGNhbgogdGFrZSB0byByZXNv
bHZlIHRoZSBkZXRlY3RlZCBpc3N1ZS4gVGhpcyBleHBsYW5hdGlvbiBpcyByZXR1cm5lZCB3
aXRoIGVhY2gKIGZpbmRpbmcgZ2VuZXJhdGVkIGJ5IHRoaXMgbW9kdWxlIGluIHRoZSBgbmV4
dFN0ZXBzYCBwcm9wZXJ0eSBvZiB0aGUgZmluZGluZwogSlNPTi4KCgwKBQQAAgUFEgNkAggK
DAoFBAACBQESA2QJFwoMCgUEAAIFAxIDZBobCgwKBQQAAgUIEgNkHEQKDwoIBAACBQicCAAS
A2QdQ2IGcHJvdG8z
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Securityposture::V1::ShaCustomConfig::CustomConfig ===
    # Fields for CustomConfig
    # Field: predicate Type: 11 (.google.type.Expr)
    # Field: custom_output Type: 11 (.google.cloud.securityposture.v1.CustomConfig.CustomOutputSpec)
    # Field: resource_selector Type: 11 (.google.cloud.securityposture.v1.CustomConfig.ResourceSelector)
    # Field: severity Type: 14 (.google.cloud.securityposture.v1.CustomConfig.Severity)
    # Field: description Type: 9 ()
    # Field: recommendation Type: 9 ()

# Enum: CustomConfig::Severity
our $CustomConfig_SEVERITY_UNSPECIFIED = 0;
our $CustomConfig_CRITICAL = 1;
our $CustomConfig_HIGH = 2;
our $CustomConfig_MEDIUM = 3;
our $CustomConfig_LOW = 4;

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Securityposture::V1::ShaCustomConfig - Compiled Protocol Buffers messages for google/cloud/securityposture/v1/sha_custom_config.proto

=head1 SYNOPSIS

    use Google::Cloud::Securityposture::V1::ShaCustomConfig;

    my $msg = Google::Cloud::Securityposture::V1::ShaCustomConfig::CustomConfig->new({
        predicate => $predicate,
        custom_output => $custom_output,
        resource_selector => $resource_selector,
        severity => $severity,
    });

    # Read or update a field
    my $val = $msg->predicate();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Securityposture::V1::ShaCustomConfig::CustomConfig->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/securityposture/v1/sha_custom_config.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Securityposture::V1::ShaCustomConfig::CustomConfig

Defines the properties in a custom module configuration for Security
Health Analytics. Use the custom module configuration to create custom
detectors that generate custom findings for resources that you specify.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->predicate() >> / C<< $msg->predicate($value) >>

Type: C<Message> (L<Google::Type::Expr::Expr>)

Required. The CEL expression to evaluate to produce findings. When the
expression evaluates to true against a resource, a finding is generated.

=item * C<< $msg->custom_output() >> / C<< $msg->custom_output($value) >>

Type: C<Message> (L<Google::Cloud::Securityposture::V1::ShaCustomConfig::CustomConfig::CustomOutputSpec>)

Optional. Custom output properties.

=item * C<< $msg->resource_selector() >> / C<< $msg->resource_selector($value) >>

Type: C<Message> (L<Google::Cloud::Securityposture::V1::ShaCustomConfig::CustomConfig::ResourceSelector>)

Required. The resource types that the custom module operates on. Each
custom module can specify up to 5 resource types.

=item * C<< $msg->severity() >> / C<< $msg->severity($value) >>

Type: C<Enum> (L<Google::Cloud::Securityposture::V1::CustomConfig::Severity>)

Required. The severity to assign to findings generated by the module.

=item * C<< $msg->description() >> / C<< $msg->description($value) >>

Type: C<String>

Optional. Text that describes the vulnerability or misconfiguration that
the custom module detects. This explanation is returned with each finding
instance to help investigators understand the detected issue. The text must
be enclosed in quotation marks.

=item * C<< $msg->recommendation() >> / C<< $msg->recommendation($value) >>

Type: C<String>

Optional. An explanation of the recommended steps that security teams can
take to resolve the detected issue. This explanation is returned with each
finding generated by this module in the `nextSteps` property of the finding
JSON.

=back

=head3 Enum: CustomConfig::Severity

=over 4

=item * C<SEVERITY_UNSPECIFIED> => C<0>

=item * C<CRITICAL> => C<1>

=item * C<HIGH> => C<2>

=item * C<MEDIUM> => C<3>

=item * C<LOW> => C<4>

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Securityposture::V1::ShaCustomConfig::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
