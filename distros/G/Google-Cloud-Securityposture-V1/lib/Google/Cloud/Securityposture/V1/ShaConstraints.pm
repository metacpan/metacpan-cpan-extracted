package Google::Cloud::Securityposture::V1::ShaConstraints;

use strict;
use warnings;

our $VERSION = '0.14';

use Protobuf::Message;
use Protobuf::DescriptorPool;
use Protobuf::Internal qw(:all);
use MIME::Base64;

BEGIN {
    eval { require Google::Api::FieldBehavior };
    eval { require Google::Cloud::Securityposture::V1::ShaCustomConfig };
    my $descriptor_b64 = <<'EOF';
CjVnb29nbGUvY2xvdWQvc2VjdXJpdHlwb3N0dXJlL3YxL3NoYV9jb25zdHJhaW50cy5wcm90
bxIfZ29vZ2xlLmNsb3VkLnNlY3VyaXR5cG9zdHVyZS52MRofZ29vZ2xlL2FwaS9maWVsZF9i
ZWhhdmlvci5wcm90bxo3Z29vZ2xlL2Nsb3VkL3NlY3VyaXR5cG9zdHVyZS92MS9zaGFfY3Vz
dG9tX2NvbmZpZy5wcm90byKvAQodU2VjdXJpdHlIZWFsdGhBbmFseXRpY3NNb2R1bGUSJAoL
bW9kdWxlX25hbWUYASABKAlCA+BBAlIKbW9kdWxlTmFtZRJoChdtb2R1bGVfZW5hYmxlbWVu
dF9zdGF0ZRgCIAEoDjIwLmdvb2dsZS5jbG91ZC5zZWN1cml0eXBvc3R1cmUudjEuRW5hYmxl
bWVudFN0YXRlUhVtb2R1bGVFbmFibGVtZW50U3RhdGUimwIKI1NlY3VyaXR5SGVhbHRoQW5h
bHl0aWNzQ3VzdG9tTW9kdWxlEhYKAmlkGAEgASgJQgbgQQXgQQNSAmlkEiYKDGRpc3BsYXlf
bmFtZRgCIAEoCUID4EEBUgtkaXNwbGF5TmFtZRJKCgZjb25maWcYAyABKAsyLS5nb29nbGUu
Y2xvdWQuc2VjdXJpdHlwb3N0dXJlLnYxLkN1c3RvbUNvbmZpZ0ID4EECUgZjb25maWcSaAoX
bW9kdWxlX2VuYWJsZW1lbnRfc3RhdGUYBCABKA4yMC5nb29nbGUuY2xvdWQuc2VjdXJpdHlw
b3N0dXJlLnYxLkVuYWJsZW1lbnRTdGF0ZVIVbW9kdWxlRW5hYmxlbWVudFN0YXRlKk4KD0Vu
YWJsZW1lbnRTdGF0ZRIgChxFTkFCTEVNRU5UX1NUQVRFX1VOU1BFQ0lGSUVEEAASCwoHRU5B
QkxFRBABEgwKCERJU0FCTEVEEAJCiwEKI2NvbS5nb29nbGUuY2xvdWQuc2VjdXJpdHlwb3N0
dXJlLnYxQhNTaGFDb25zdHJhaW50c1Byb3RvUAFaTWNsb3VkLmdvb2dsZS5jb20vZ28vc2Vj
dXJpdHlwb3N0dXJlL2FwaXYxL3NlY3VyaXR5cG9zdHVyZXBiO3NlY3VyaXR5cG9zdHVyZXBi
SrkSCgYSBA4ARwEKvAQKAQwSAw4AEjKxBCBDb3B5cmlnaHQgMjAyNSBHb29nbGUgTExDCgog
TGljZW5zZWQgdW5kZXIgdGhlIEFwYWNoZSBMaWNlbnNlLCBWZXJzaW9uIDIuMCAodGhlICJM
aWNlbnNlIik7CiB5b3UgbWF5IG5vdCB1c2UgdGhpcyBmaWxlIGV4Y2VwdCBpbiBjb21wbGlh
bmNlIHdpdGggdGhlIExpY2Vuc2UuCiBZb3UgbWF5IG9idGFpbiBhIGNvcHkgb2YgdGhlIExp
Y2Vuc2UgYXQKCiAgICAgaHR0cDovL3d3dy5hcGFjaGUub3JnL2xpY2Vuc2VzL0xJQ0VOU0Ut
Mi4wCgogVW5sZXNzIHJlcXVpcmVkIGJ5IGFwcGxpY2FibGUgbGF3IG9yIGFncmVlZCB0byBp
biB3cml0aW5nLCBzb2Z0d2FyZQogZGlzdHJpYnV0ZWQgdW5kZXIgdGhlIExpY2Vuc2UgaXMg
ZGlzdHJpYnV0ZWQgb24gYW4gIkFTIElTIiBCQVNJUywKIFdJVEhPVVQgV0FSUkFOVElFUyBP
UiBDT05ESVRJT05TIE9GIEFOWSBLSU5ELCBlaXRoZXIgZXhwcmVzcyBvciBpbXBsaWVkLgog
U2VlIHRoZSBMaWNlbnNlIGZvciB0aGUgc3BlY2lmaWMgbGFuZ3VhZ2UgZ292ZXJuaW5nIHBl
cm1pc3Npb25zIGFuZAogbGltaXRhdGlvbnMgdW5kZXIgdGhlIExpY2Vuc2UuCgoICgECEgMQ
ACgKCQoCAwASAxIAKQoJCgIDARIDEwBBCggKAQgSAxUAZAoJCgIICxIDFQBkCggKAQgSAxYA
IgoJCgIIChIDFgAiCggKAQgSAxcANAoJCgIICBIDFwA0CggKAQgSAxgAPAoJCgIIARIDGAA8
CkAKAgUAEgQbACQBGjQgUG9zc2libGUgZW5hYmxlbWVudCBzdGF0ZXMgb2YgYSBzZXJ2aWNl
IG9yIG1vZHVsZS4KCgoKAwUAARIDGwUUCjMKBAUAAgASAx0CIxomIERlZmF1bHQgdmFsdWUu
IFRoaXMgdmFsdWUgaXMgdW51c2VkLgoKDAoFBQACAAESAx0CHgoMCgUFAAIAAhIDHSEiCiAK
BAUAAgESAyACDhoTIFN0YXRlIGlzIGVuYWJsZWQuCgoMCgUFAAIBARIDIAIJCgwKBQUAAgEC
EgMgDA0KIQoEBQACAhIDIwIPGhQgU3RhdGUgaXMgZGlzYWJsZWQuCgoMCgUFAAICARIDIwIK
CgwKBQUAAgICEgMjDQ4KRgoCBAASBCcALgEaOiBNZXNzYWdlIGZvciBTZWN1cml0eSBIZWFs
dGggQW5hbHl0aWNzIGJ1aWx0LWluIGRldGVjdG9yLgoKCgoDBAABEgMnCCUKUQoEBAACABID
KQJCGkQgUmVxdWlyZWQuIFRoZSBuYW1lIG9mIHRoZSBtb2R1bGUgZWc6IEJJR1FVRVJZX1RB
QkxFX0NNRUtfRElTQUJMRUQuCgoMCgUEAAIABRIDKQIICgwKBQQAAgABEgMpCRQKDAoFBAAC
AAMSAykXGAoMCgUEAAIACBIDKRlBCg8KCAQAAgAInAgAEgMpGkAKXgoEBAACARIDLQIuGlEg
VGhlIHN0YXRlIG9mIGVuYWJsZW1lbnQgZm9yIHRoZSBtb2R1bGUgYXQgaXRzIGxldmVsIG9m
IHRoZSByZXNvdXJjZQogaGllcmFyY2h5LgoKDAoFBAACAQYSAy0CEQoMCgUEAAIBARIDLRIp
CgwKBQQAAgEDEgMtLC0KKwoCBAESBDEARwEaHyBNZXNzYWdlIGZvciBTSEEgQ3VzdG9tIE1v
ZHVsZQoKCgoDBAEBEgMxCCsKrAEKBAQBAgASBDUCOAQanQEgT3V0cHV0IG9ubHkuIEltbXV0
YWJsZS4gVGhlIGlkIG9mIHRoZSBjdXN0b20gbW9kdWxlLgogVGhlIGlkIGlzIHNlcnZlci1n
ZW5lcmF0ZWQgYW5kIGlzIG5vdCB1c2VyIHNldHRhYmxlLgogSXQgd2lsbCBiZSBhIG51bWVy
aWMgaWQgY29udGFpbmluZyAxLTIwIGRpZ2l0cy4KCgwKBQQBAgAFEgM1AggKDAoFBAECAAES
AzUJCwoMCgUEAQIAAxIDNQ4PCg0KBQQBAgAIEgQ1EDgDCg8KCAQBAgAInAgAEgM2BCsKDwoI
BAECAAicCAESAzcELQrWAgoEBAECARIDPwJDGsgCIE9wdGlvbmFsLiBUaGUgZGlzcGxheSBu
YW1lIG9mIHRoZSBTZWN1cml0eSBIZWFsdGggQW5hbHl0aWNzIGN1c3RvbSBtb2R1bGUuCiBU
aGlzIGRpc3BsYXkgbmFtZSBiZWNvbWVzIHRoZSBmaW5kaW5nIGNhdGVnb3J5IGZvciBhbGwg
ZmluZGluZ3MgdGhhdCBhcmUKIHJldHVybmVkIGJ5IHRoaXMgY3VzdG9tIG1vZHVsZS4gVGhl
IGRpc3BsYXkgbmFtZSBtdXN0IGJlIGJldHdlZW4gMSBhbmQKIDEyOCBjaGFyYWN0ZXJzLCBz
dGFydCB3aXRoIGEgbG93ZXJjYXNlIGxldHRlciwgYW5kIGNvbnRhaW4gYWxwaGFudW1lcmlj
CiBjaGFyYWN0ZXJzIG9yIHVuZGVyc2NvcmVzIG9ubHkuCgoMCgUEAQIBBRIDPwIICgwKBQQB
AgEBEgM/CRUKDAoFBAECAQMSAz8YGQoMCgUEAQIBCBIDPxpCCg8KCAQBAgEInAgAEgM/G0EK
LgoEBAECAhIDQgJDGiEgUmVxdWlyZWQuIGN1c3RvbSBtb2R1bGUgZGV0YWlscwoKDAoFBAEC
AgYSA0ICDgoMCgUEAQICARIDQg8VCgwKBQQBAgIDEgNCGBkKDAoFBAECAggSA0IaQgoPCggE
AQICCJwIABIDQhtBCl4KBAQBAgMSA0YCLhpRIFRoZSBzdGF0ZSBvZiBlbmFibGVtZW50IGZv
ciB0aGUgbW9kdWxlIGF0IGl0cyBsZXZlbCBvZiB0aGUgcmVzb3VyY2UKIGhpZXJhcmNoeS4K
CgwKBQQBAgMGEgNGAhEKDAoFBAECAwESA0YSKQoMCgUEAQIDAxIDRiwtYgZwcm90bzM=
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Securityposture::V1::ShaConstraints::SecurityHealthAnalyticsModule ===
    # Fields for SecurityHealthAnalyticsModule
    # Field: module_name Type: 9 ()
    # Field: module_enablement_state Type: 14 (.google.cloud.securityposture.v1.EnablementState)

# === Message: Google::Cloud::Securityposture::V1::ShaConstraints::SecurityHealthAnalyticsCustomModule ===
    # Fields for SecurityHealthAnalyticsCustomModule
    # Field: id Type: 9 ()
    # Field: display_name Type: 9 ()
    # Field: config Type: 11 (.google.cloud.securityposture.v1.CustomConfig)
    # Field: module_enablement_state Type: 14 (.google.cloud.securityposture.v1.EnablementState)

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Securityposture::V1::ShaConstraints - Compiled Protocol Buffers messages for google/cloud/securityposture/v1/sha_constraints.proto

=head1 SYNOPSIS

    use Google::Cloud::Securityposture::V1::ShaConstraints;

    my $msg = Google::Cloud::Securityposture::V1::ShaConstraints::SecurityHealthAnalyticsModule->new({
        module_name => $module_name,
        module_enablement_state => $module_enablement_state,
    });

    # Read or update a field
    my $val = $msg->module_name();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Securityposture::V1::ShaConstraints::SecurityHealthAnalyticsModule->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/securityposture/v1/sha_constraints.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Securityposture::V1::ShaConstraints::SecurityHealthAnalyticsModule

Message for Security Health Analytics built-in detector.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->module_name() >> / C<< $msg->module_name($value) >>

Type: C<String>

Required. The name of the module eg: BIGQUERY_TABLE_CMEK_DISABLED.

=item * C<< $msg->module_enablement_state() >> / C<< $msg->module_enablement_state($value) >>

Type: C<Enum> (L<Google::Cloud::Securityposture::V1::EnablementState>)

The state of enablement for the module at its level of the resource
hierarchy.

=back

=head2 Google::Cloud::Securityposture::V1::ShaConstraints::SecurityHealthAnalyticsCustomModule

Message for SHA Custom Module

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->id() >> / C<< $msg->id($value) >>

Type: C<String>

Output only. Immutable. The id of the custom module.
The id is server-generated and is not user settable.
It will be a numeric id containing 1-20 digits.

=item * C<< $msg->display_name() >> / C<< $msg->display_name($value) >>

Type: C<String>

Optional. The display name of the Security Health Analytics custom module.
This display name becomes the finding category for all findings that are
returned by this custom module. The display name must be between 1 and
128 characters, start with a lowercase letter, and contain alphanumeric
characters or underscores only.

=item * C<< $msg->config() >> / C<< $msg->config($value) >>

Type: C<Message> (L<Google::Cloud::Securityposture::V1::ShaCustomConfig::CustomConfig>)

Required. custom module details

=item * C<< $msg->module_enablement_state() >> / C<< $msg->module_enablement_state($value) >>

Type: C<Enum> (L<Google::Cloud::Securityposture::V1::EnablementState>)

The state of enablement for the module at its level of the resource
hierarchy.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Securityposture::V1::ShaConstraints::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
