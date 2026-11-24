package Google::Cloud::Securitycenter::V1::SecurityHealthAnalyticsCustomConfig;

use strict;
use warnings;

our $VERSION = '0.14';

use Protobuf::Message;
use Protobuf::DescriptorPool;
use Protobuf::Internal qw(:all);
use MIME::Base64;

BEGIN {
    eval { require Google::Type::Expr };
    my $descriptor_b64 = <<'EOF';
Ckxnb29nbGUvY2xvdWQvc2VjdXJpdHljZW50ZXIvdjEvc2VjdXJpdHlfaGVhbHRoX2FuYWx5
dGljc19jdXN0b21fY29uZmlnLnByb3RvEh5nb29nbGUuY2xvdWQuc2VjdXJpdHljZW50ZXIu
djEaFmdvb2dsZS90eXBlL2V4cHIucHJvdG8ilQYKDEN1c3RvbUNvbmZpZxIvCglwcmVkaWNh
dGUYASABKAsyES5nb29nbGUudHlwZS5FeHByUglwcmVkaWNhdGUSYgoNY3VzdG9tX291dHB1
dBgCIAEoCzI9Lmdvb2dsZS5jbG91ZC5zZWN1cml0eWNlbnRlci52MS5DdXN0b21Db25maWcu
Q3VzdG9tT3V0cHV0U3BlY1IMY3VzdG9tT3V0cHV0EmoKEXJlc291cmNlX3NlbGVjdG9yGAMg
ASgLMj0uZ29vZ2xlLmNsb3VkLnNlY3VyaXR5Y2VudGVyLnYxLkN1c3RvbUNvbmZpZy5SZXNv
dXJjZVNlbGVjdG9yUhByZXNvdXJjZVNlbGVjdG9yElEKCHNldmVyaXR5GAQgASgOMjUuZ29v
Z2xlLmNsb3VkLnNlY3VyaXR5Y2VudGVyLnYxLkN1c3RvbUNvbmZpZy5TZXZlcml0eVIIc2V2
ZXJpdHkSIAoLZGVzY3JpcHRpb24YBSABKAlSC2Rlc2NyaXB0aW9uEiYKDnJlY29tbWVuZGF0
aW9uGAYgASgJUg5yZWNvbW1lbmRhdGlvbhrYAQoQQ3VzdG9tT3V0cHV0U3BlYxJmCgpwcm9w
ZXJ0aWVzGAEgAygLMkYuZ29vZ2xlLmNsb3VkLnNlY3VyaXR5Y2VudGVyLnYxLkN1c3RvbUNv
bmZpZy5DdXN0b21PdXRwdXRTcGVjLlByb3BlcnR5Ugpwcm9wZXJ0aWVzGlwKCFByb3BlcnR5
EhIKBG5hbWUYASABKAlSBG5hbWUSPAoQdmFsdWVfZXhwcmVzc2lvbhgCIAEoCzIRLmdvb2ds
ZS50eXBlLkV4cHJSD3ZhbHVlRXhwcmVzc2lvbho5ChBSZXNvdXJjZVNlbGVjdG9yEiUKDnJl
c291cmNlX3R5cGVzGAEgAygJUg1yZXNvdXJjZVR5cGVzIlEKCFNldmVyaXR5EhgKFFNFVkVS
SVRZX1VOU1BFQ0lGSUVEEAASDAoIQ1JJVElDQUwQARIICgRISUdIEAISCgoGTUVESVVNEAMS
BwoDTE9XEARCggIKImNvbS5nb29nbGUuY2xvdWQuc2VjdXJpdHljZW50ZXIudjFCKFNlY3Vy
aXR5SGVhbHRoQW5hbHl0aWNzQ3VzdG9tQ29uZmlnUHJvdG9QAVpKY2xvdWQuZ29vZ2xlLmNv
bS9nby9zZWN1cml0eWNlbnRlci9hcGl2MS9zZWN1cml0eWNlbnRlcnBiO3NlY3VyaXR5Y2Vu
dGVycGKqAh5Hb29nbGUuQ2xvdWQuU2VjdXJpdHlDZW50ZXIuVjHKAh5Hb29nbGVcQ2xvdWRc
U2VjdXJpdHlDZW50ZXJcVjHqAiFHb29nbGU6OkNsb3VkOjpTZWN1cml0eUNlbnRlcjo6VjFK
zxwKBhIEDgBkAQq8BAoBDBIDDgASMrEEIENvcHlyaWdodCAyMDI1IEdvb2dsZSBMTEMKCiBM
aWNlbnNlZCB1bmRlciB0aGUgQXBhY2hlIExpY2Vuc2UsIFZlcnNpb24gMi4wICh0aGUgIkxp
Y2Vuc2UiKTsKIHlvdSBtYXkgbm90IHVzZSB0aGlzIGZpbGUgZXhjZXB0IGluIGNvbXBsaWFu
Y2Ugd2l0aCB0aGUgTGljZW5zZS4KIFlvdSBtYXkgb2J0YWluIGEgY29weSBvZiB0aGUgTGlj
ZW5zZSBhdAoKICAgICBodHRwOi8vd3d3LmFwYWNoZS5vcmcvbGljZW5zZXMvTElDRU5TRS0y
LjAKCiBVbmxlc3MgcmVxdWlyZWQgYnkgYXBwbGljYWJsZSBsYXcgb3IgYWdyZWVkIHRvIGlu
IHdyaXRpbmcsIHNvZnR3YXJlCiBkaXN0cmlidXRlZCB1bmRlciB0aGUgTGljZW5zZSBpcyBk
aXN0cmlidXRlZCBvbiBhbiAiQVMgSVMiIEJBU0lTLAogV0lUSE9VVCBXQVJSQU5USUVTIE9S
IENPTkRJVElPTlMgT0YgQU5ZIEtJTkQsIGVpdGhlciBleHByZXNzIG9yIGltcGxpZWQuCiBT
ZWUgdGhlIExpY2Vuc2UgZm9yIHRoZSBzcGVjaWZpYyBsYW5ndWFnZSBnb3Zlcm5pbmcgcGVy
bWlzc2lvbnMgYW5kCiBsaW1pdGF0aW9ucyB1bmRlciB0aGUgTGljZW5zZS4KCggKAQISAxAA
JwoJCgIDABIDEgAgCggKAQgSAxQAOwoJCgIIJRIDFAA7CggKAQgSAxUAYQoJCgIICxIDFQBh
CggKAQgSAxYAIgoJCgIIChIDFgAiCggKAQgSAxcASQoJCgIICBIDFwBJCggKAQgSAxgAOwoJ
CgIIARIDGAA7CggKAQgSAxkAOwoJCgIIKRIDGQA7CggKAQgSAxoAOgoJCgIILRIDGgA6CuQB
CgIEABIEHwBkARrXASBEZWZpbmVzIHRoZSBwcm9wZXJ0aWVzIGluIGEgY3VzdG9tIG1vZHVs
ZSBjb25maWd1cmF0aW9uIGZvciBTZWN1cml0eQogSGVhbHRoIEFuYWx5dGljcy4gVXNlIHRo
ZSBjdXN0b20gbW9kdWxlIGNvbmZpZ3VyYXRpb24gdG8gY3JlYXRlIGN1c3RvbQogZGV0ZWN0
b3JzIHRoYXQgZ2VuZXJhdGUgY3VzdG9tIGZpbmRpbmdzIGZvciByZXNvdXJjZXMgdGhhdCB5
b3Ugc3BlY2lmeS4KCgoKAwQAARIDHwgUCo0CCgQEAAMAEgQkAjIDGv4BIEEgc2V0IG9mIG9w
dGlvbmFsIG5hbWUtdmFsdWUgcGFpcnMgdGhhdCBkZWZpbmUgY3VzdG9tIHNvdXJjZSBwcm9w
ZXJ0aWVzIHRvCiByZXR1cm4gd2l0aCBlYWNoIGZpbmRpbmcgdGhhdCBpcyBnZW5lcmF0ZWQg
YnkgdGhlIGN1c3RvbSBtb2R1bGUuIFRoZSBjdXN0b20KIHNvdXJjZSBwcm9wZXJ0aWVzIHRo
YXQgYXJlIGRlZmluZWQgaGVyZSBhcmUgaW5jbHVkZWQgaW4gdGhlIGZpbmRpbmcgSlNPTgog
dW5kZXIgYHNvdXJjZVByb3BlcnRpZXNgLgoKDAoFBAADAAESAyQKGgpWCgYEAAMAAwASBCYE
LgUaRiBBbiBpbmRpdmlkdWFsIG5hbWUtdmFsdWUgcGFpciB0aGF0IGRlZmluZXMgYSBjdXN0
b20gc291cmNlIHByb3BlcnR5LgoKDgoHBAADAAMAARIDJgwUCj4KCAQAAwADAAIAEgMoBhYa
LSBOYW1lIG9mIHRoZSBwcm9wZXJ0eSBmb3IgdGhlIGN1c3RvbSBvdXRwdXQuCgoQCgkEAAMA
AwACAAUSAygGDAoQCgkEAAMAAwACAAESAygNEQoQCgkEAAMAAwACAAMSAygUFQq2AQoIBAAD
AAMAAgESAy0GLBqkASBUaGUgQ0VMIGV4cHJlc3Npb24gZm9yIHRoZSBjdXN0b20gb3V0cHV0
LiBBIHJlc291cmNlIHByb3BlcnR5IGNhbiBiZQogc3BlY2lmaWVkIHRvIHJldHVybiB0aGUg
dmFsdWUgb2YgdGhlIHByb3BlcnR5IG9yIGEgdGV4dCBzdHJpbmcgZW5jbG9zZWQKIGluIHF1
b3RhdGlvbiBtYXJrcy4KChAKCQQAAwADAAIBBhIDLQYWChAKCQQAAwADAAIBARIDLRcnChAK
CQQAAwADAAIBAxIDLSorCkoKBgQAAwACABIDMQQlGjsgQSBsaXN0IG9mIGN1c3RvbSBvdXRw
dXQgcHJvcGVydGllcyB0byBhZGQgdG8gdGhlIGZpbmRpbmcuCgoOCgcEAAMAAgAEEgMxBAwK
DgoHBAADAAIABhIDMQ0VCg4KBwQAAwACAAESAzEWIAoOCgcEAAMAAgADEgMxIyQKNQoEBAAD
ARIENQI4AxonIFJlc291cmNlIGZvciBzZWxlY3RpbmcgcmVzb3VyY2UgdHlwZS4KCgwKBQQA
AwEBEgM1ChoKOwoGBAADAQIAEgM3BCcaLCBUaGUgcmVzb3VyY2UgdHlwZXMgdG8gcnVuIHRo
ZSBkZXRlY3RvciBvbi4KCg4KBwQAAwECAAQSAzcEDAoOCgcEAAMBAgAFEgM3DRMKDgoHBAAD
AQIAARIDNxQiCg4KBwQAAwECAAMSAzclJgpOCgQEAAQAEgQ7AkoDGkAgRGVmaW5lcyB0aGUg
dmFsaWQgdmFsdWUgb3B0aW9ucyBmb3IgdGhlIHNldmVyaXR5IG9mIGEgZmluZGluZy4KCgwK
BQQABAABEgM7Bw8KJgoGBAAEAAIAEgM9BB0aFyBVbnNwZWNpZmllZCBzZXZlcml0eS4KCg4K
BwQABAACAAESAz0EGAoOCgcEAAQAAgACEgM9GxwKIwoGBAAEAAIBEgNABBEaFCBDcml0aWNh
bCBzZXZlcml0eS4KCg4KBwQABAACAQESA0AEDAoOCgcEAAQAAgECEgNADxAKHwoGBAAEAAIC
EgNDBA0aECBIaWdoIHNldmVyaXR5LgoKDgoHBAAEAAICARIDQwQICg4KBwQABAACAgISA0ML
DAohCgYEAAQAAgMSA0YEDxoSIE1lZGl1bSBzZXZlcml0eS4KCg4KBwQABAACAwESA0YECgoO
CgcEAAQAAgMCEgNGDQ4KHgoGBAAEAAIEEgNJBAwaDyBMb3cgc2V2ZXJpdHkuCgoOCgcEAAQA
AgQBEgNJBAcKDgoHBAAEAAIEAhIDSQoLCpYBCgQEAAIAEgNOAiEaiAEgVGhlIENFTCBleHBy
ZXNzaW9uIHRvIGV2YWx1YXRlIHRvIHByb2R1Y2UgZmluZGluZ3MuIFdoZW4gdGhlIGV4cHJl
c3Npb24KIGV2YWx1YXRlcyB0byB0cnVlIGFnYWluc3QgYSByZXNvdXJjZSwgYSBmaW5kaW5n
IGlzIGdlbmVyYXRlZC4KCgwKBQQAAgAGEgNOAhIKDAoFBAACAAESA04THAoMCgUEAAIAAxID
Th8gCigKBAQAAgESA1ECJRobIEN1c3RvbSBvdXRwdXQgcHJvcGVydGllcy4KCgwKBQQAAgEG
EgNRAhIKDAoFBAACAQESA1ETIAoMCgUEAAIBAxIDUSMkCn0KBAQAAgISA1UCKRpwIFRoZSBy
ZXNvdXJjZSB0eXBlcyB0aGF0IHRoZSBjdXN0b20gbW9kdWxlIG9wZXJhdGVzIG9uLiBFYWNo
IGN1c3RvbSBtb2R1bGUKIGNhbiBzcGVjaWZ5IHVwIHRvIDUgcmVzb3VyY2UgdHlwZXMuCgoM
CgUEAAICBhIDVQISCgwKBQQAAgIBEgNVEyQKDAoFBAACAgMSA1UnKApKCgQEAAIDEgNYAhga
PSBUaGUgc2V2ZXJpdHkgdG8gYXNzaWduIHRvIGZpbmRpbmdzIGdlbmVyYXRlZCBieSB0aGUg
bW9kdWxlLgoKDAoFBAACAwYSA1gCCgoMCgUEAAIDARIDWAsTCgwKBQQAAgMDEgNYFhcKhwIK
BAQAAgQSA14CGRr5ASBUZXh0IHRoYXQgZGVzY3JpYmVzIHRoZSB2dWxuZXJhYmlsaXR5IG9y
IG1pc2NvbmZpZ3VyYXRpb24gdGhhdCB0aGUgY3VzdG9tCiBtb2R1bGUgZGV0ZWN0cy4gVGhp
cyBleHBsYW5hdGlvbiBpcyByZXR1cm5lZCB3aXRoIGVhY2ggZmluZGluZyBpbnN0YW5jZSB0
bwogaGVscCBpbnZlc3RpZ2F0b3JzIHVuZGVyc3RhbmQgdGhlIGRldGVjdGVkIGlzc3VlLiBU
aGUgdGV4dCBtdXN0IGJlIGVuY2xvc2VkCiBpbiBxdW90YXRpb24gbWFya3MuCgoMCgUEAAIE
BRIDXgIICgwKBQQAAgQBEgNeCRQKDAoFBAACBAMSA14XGAruAQoEBAACBRIDYwIcGuABIEFu
IGV4cGxhbmF0aW9uIG9mIHRoZSByZWNvbW1lbmRlZCBzdGVwcyB0aGF0IHNlY3VyaXR5IHRl
YW1zIGNhbiB0YWtlIHRvCiByZXNvbHZlIHRoZSBkZXRlY3RlZCBpc3N1ZS4gVGhpcyBleHBs
YW5hdGlvbiBpcyByZXR1cm5lZCB3aXRoIGVhY2ggZmluZGluZwogZ2VuZXJhdGVkIGJ5IHRo
aXMgbW9kdWxlIGluIHRoZSBgbmV4dFN0ZXBzYCBwcm9wZXJ0eSBvZiB0aGUgZmluZGluZyBK
U09OLgoKDAoFBAACBQUSA2MCCAoMCgUEAAIFARIDYwkXCgwKBQQAAgUDEgNjGhtiBnByb3Rv
Mw==
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Securitycenter::V1::SecurityHealthAnalyticsCustomConfig::CustomConfig ===
    # Fields for CustomConfig
    # Field: predicate Type: 11 (.google.type.Expr)
    # Field: custom_output Type: 11 (.google.cloud.securitycenter.v1.CustomConfig.CustomOutputSpec)
    # Field: resource_selector Type: 11 (.google.cloud.securitycenter.v1.CustomConfig.ResourceSelector)
    # Field: severity Type: 14 (.google.cloud.securitycenter.v1.CustomConfig.Severity)
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

Google::Cloud::Securitycenter::V1::SecurityHealthAnalyticsCustomConfig - Compiled Protocol Buffers messages for google/cloud/securitycenter/v1/security_health_analytics_custom_config.proto

=head1 SYNOPSIS

    use Google::Cloud::Securitycenter::V1::SecurityHealthAnalyticsCustomConfig;

    my $msg = Google::Cloud::Securitycenter::V1::SecurityHealthAnalyticsCustomConfig::CustomConfig->new({
        predicate => $predicate,
        custom_output => $custom_output,
        resource_selector => $resource_selector,
        severity => $severity,
    });

    # Read or update a field
    my $val = $msg->predicate();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Securitycenter::V1::SecurityHealthAnalyticsCustomConfig::CustomConfig->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/securitycenter/v1/security_health_analytics_custom_config.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Securitycenter::V1::SecurityHealthAnalyticsCustomConfig::CustomConfig

Defines the properties in a custom module configuration for Security
Health Analytics. Use the custom module configuration to create custom
detectors that generate custom findings for resources that you specify.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->predicate() >> / C<< $msg->predicate($value) >>

Type: C<Message> (L<Google::Type::Expr::Expr>)

The CEL expression to evaluate to produce findings. When the expression
evaluates to true against a resource, a finding is generated.

=item * C<< $msg->custom_output() >> / C<< $msg->custom_output($value) >>

Type: C<Message> (L<Google::Cloud::Securitycenter::V1::SecurityHealthAnalyticsCustomConfig::CustomConfig::CustomOutputSpec>)

Custom output properties.

=item * C<< $msg->resource_selector() >> / C<< $msg->resource_selector($value) >>

Type: C<Message> (L<Google::Cloud::Securitycenter::V1::SecurityHealthAnalyticsCustomConfig::CustomConfig::ResourceSelector>)

The resource types that the custom module operates on. Each custom module
can specify up to 5 resource types.

=item * C<< $msg->severity() >> / C<< $msg->severity($value) >>

Type: C<Enum> (L<Google::Cloud::Securitycenter::V1::CustomConfig::Severity>)

The severity to assign to findings generated by the module.

=item * C<< $msg->description() >> / C<< $msg->description($value) >>

Type: C<String>

Text that describes the vulnerability or misconfiguration that the custom
module detects. This explanation is returned with each finding instance to
help investigators understand the detected issue. The text must be enclosed
in quotation marks.

=item * C<< $msg->recommendation() >> / C<< $msg->recommendation($value) >>

Type: C<String>

An explanation of the recommended steps that security teams can take to
resolve the detected issue. This explanation is returned with each finding
generated by this module in the `nextSteps` property of the finding JSON.

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

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Securitycenter::V1::SecurityHealthAnalyticsCustomConfig::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
