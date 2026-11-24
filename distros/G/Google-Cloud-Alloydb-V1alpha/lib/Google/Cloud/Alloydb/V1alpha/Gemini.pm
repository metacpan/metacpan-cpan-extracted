package Google::Cloud::Alloydb::V1alpha::Gemini;

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
Cilnb29nbGUvY2xvdWQvYWxsb3lkYi92MWFscGhhL2dlbWluaS5wcm90bxIcZ29vZ2xlLmNs
b3VkLmFsbG95ZGIudjFhbHBoYRofZ29vZ2xlL2FwaS9maWVsZF9iZWhhdmlvci5wcm90byI4
ChNHZW1pbmlDbHVzdGVyQ29uZmlnEiEKCGVudGl0bGVkGAEgASgIQgUYAeBBA1IIZW50aXRs
ZWQiOQoUR2VtaW5pSW5zdGFuY2VDb25maWcSIQoIZW50aXRsZWQYASABKAhCBRgB4EEDUghl
bnRpdGxlZCJzChFHQ0FJbnN0YW5jZUNvbmZpZxJeCg9nY2FfZW50aXRsZW1lbnQYASABKA4y
MC5nb29nbGUuY2xvdWQuYWxsb3lkYi52MWFscGhhLkdDQUVudGl0bGVtZW50VHlwZUID4EED
Ug5nY2FFbnRpdGxlbWVudCpMChJHQ0FFbnRpdGxlbWVudFR5cGUSJAogR0NBX0VOVElUTEVN
RU5UX1RZUEVfVU5TUEVDSUZJRUQQABIQCgxHQ0FfU1RBTkRBUkQQAULNAQogY29tLmdvb2ds
ZS5jbG91ZC5hbGxveWRiLnYxYWxwaGFCC0dlbWluaVByb3RvUAFaOmNsb3VkLmdvb2dsZS5j
b20vZ28vYWxsb3lkYi9hcGl2MWFscGhhL2FsbG95ZGJwYjthbGxveWRicGKqAhxHb29nbGUu
Q2xvdWQuQWxsb3lEYi5WMUFscGhhygIcR29vZ2xlXENsb3VkXEFsbG95RGJcVjFhbHBoYeoC
H0dvb2dsZTo6Q2xvdWQ6OkFsbG95REI6OlYxYWxwaGFKyA4KBhIEDgA7AQq8BAoBDBIDDgAS
MrEEIENvcHlyaWdodCAyMDI1IEdvb2dsZSBMTEMKCiBMaWNlbnNlZCB1bmRlciB0aGUgQXBh
Y2hlIExpY2Vuc2UsIFZlcnNpb24gMi4wICh0aGUgIkxpY2Vuc2UiKTsKIHlvdSBtYXkgbm90
IHVzZSB0aGlzIGZpbGUgZXhjZXB0IGluIGNvbXBsaWFuY2Ugd2l0aCB0aGUgTGljZW5zZS4K
IFlvdSBtYXkgb2J0YWluIGEgY29weSBvZiB0aGUgTGljZW5zZSBhdAoKICAgICBodHRwOi8v
d3d3LmFwYWNoZS5vcmcvbGljZW5zZXMvTElDRU5TRS0yLjAKCiBVbmxlc3MgcmVxdWlyZWQg
YnkgYXBwbGljYWJsZSBsYXcgb3IgYWdyZWVkIHRvIGluIHdyaXRpbmcsIHNvZnR3YXJlCiBk
aXN0cmlidXRlZCB1bmRlciB0aGUgTGljZW5zZSBpcyBkaXN0cmlidXRlZCBvbiBhbiAiQVMg
SVMiIEJBU0lTLAogV0lUSE9VVCBXQVJSQU5USUVTIE9SIENPTkRJVElPTlMgT0YgQU5ZIEtJ
TkQsIGVpdGhlciBleHByZXNzIG9yIGltcGxpZWQuCiBTZWUgdGhlIExpY2Vuc2UgZm9yIHRo
ZSBzcGVjaWZpYyBsYW5ndWFnZSBnb3Zlcm5pbmcgcGVybWlzc2lvbnMgYW5kCiBsaW1pdGF0
aW9ucyB1bmRlciB0aGUgTGljZW5zZS4KCggKAQISAxAAJQoJCgIDABIDEgApCggKAQgSAxQA
OQoJCgIIJRIDFAA5CggKAQgSAxUAUQoJCgIICxIDFQBRCggKAQgSAxYAIgoJCgIIChIDFgAi
CggKAQgSAxcALAoJCgIICBIDFwAsCggKAQgSAxgAOQoJCgIIARIDGAA5CggKAQgSAxkAOQoJ
CgIIKRIDGQA5CggKAQgSAxoAOAoJCgIILRIDGgA4ClMKAgUAEgQdACMBGkcgRW51bSByZXBy
ZXNlbnRpbmcgdGhlIHR5cGUgb2YgR0NBIGVudGl0bGVtZW50IGFzc2lnbmVkIHRvIGEgcmVz
b3VyY2UuCgoKCgMFAAESAx0FFwouCgQFAAIAEgMfAicaISBObyBHQ0EgZW50aXRsZW1lbnQg
aXMgYXNzaWduZWQuCgoMCgUFAAIAARIDHwIiCgwKBQUAAgACEgMfJSYKQQoEBQACARIDIgIT
GjQgVGhlIHJlc291cmNlIGlzIGVudGl0bGVkIHRvIHRoZSBHQ0EgU3RhbmRhcmQgVGllci4K
CgwKBQUAAgEBEgMiAg4KDAoFBQACAQISAyIREgpVCgIEABIEJgArARpJIERlcHJlY2F0ZWQg
YW5kIHVudXNlZC4gVGhpcyBtZXNzYWdlIHdpbGwgYmUgcmVtb3ZlZCBpbiB0aGUgbmVhciBm
dXR1cmUuCgoKCgMEAAESAyYIGwpjCgQEAAIAEgQpAipFGlUgT3V0cHV0IG9ubHkuIERlcHJl
Y2F0ZWQgYW5kIHVudXNlZC4gVGhpcyBmaWVsZCB3aWxsIGJlIHJlbW92ZWQgaW4gdGhlIG5l
YXIKIGZ1dHVyZS4KCgwKBQQAAgAFEgMpAgYKDAoFBAACAAESAykHDwoMCgUEAAIAAxIDKRIT
CgwKBQQAAgAIEgMqBkQKDQoGBAACAAgDEgMqBxgKDwoIBAACAAicCAASAyoaQwpVCgIEARIE
LgAzARpJIERlcHJlY2F0ZWQgYW5kIHVudXNlZC4gVGhpcyBtZXNzYWdlIHdpbGwgYmUgcmVt
b3ZlZCBpbiB0aGUgbmVhciBmdXR1cmUuCgoKCgMEAQESAy4IHApjCgQEAQIAEgQxAjJFGlUg
T3V0cHV0IG9ubHkuIERlcHJlY2F0ZWQgYW5kIHVudXNlZC4gVGhpcyBmaWVsZCB3aWxsIGJl
IHJlbW92ZWQgaW4gdGhlIG5lYXIKIGZ1dHVyZS4KCgwKBQQBAgAFEgMxAgYKDAoFBAECAAES
AzEHDwoMCgUEAQIAAxIDMRITCgwKBQQBAgAIEgMyBkQKDQoGBAECAAgDEgMyBxgKDwoIBAEC
AAicCAASAzIaQwpiCgIEAhIENwA7ARpWIEluc3RhbmNlIGxldmVsIGNvbmZpZ3VyYXRpb24g
cGFyYW1ldGVycyByZWxhdGVkIHRvIHRoZSBHZW1pbmkgQ2xvdWQgQXNzaXN0CiBwcm9kdWN0
LgoKCgoDBAIBEgM3CBkKUgoEBAICABIEOQI6MhpEIE91dHB1dCBvbmx5LiBSZXByZXNlbnRz
IHRoZSBHQ0EgZW50aXRsZW1lbnQgc3RhdGUgb2YgdGhlIGluc3RhbmNlLgoKDAoFBAICAAYS
AzkCFAoMCgUEAgIAARIDORUkCgwKBQQCAgADEgM5JygKDAoFBAICAAgSAzoGMQoPCggEAgIA
CJwIABIDOgcwYgZwcm90bzM=
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Alloydb::V1alpha::Gemini::GeminiClusterConfig ===
    # Fields for GeminiClusterConfig
    # Field: entitled Type: 8 ()

# === Message: Google::Cloud::Alloydb::V1alpha::Gemini::GeminiInstanceConfig ===
    # Fields for GeminiInstanceConfig
    # Field: entitled Type: 8 ()

# === Message: Google::Cloud::Alloydb::V1alpha::Gemini::GCAInstanceConfig ===
    # Fields for GCAInstanceConfig
    # Field: gca_entitlement Type: 14 (.google.cloud.alloydb.v1alpha.GCAEntitlementType)

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Alloydb::V1alpha::Gemini - Compiled Protocol Buffers messages for google/cloud/alloydb/v1alpha/gemini.proto

=head1 SYNOPSIS

    use Google::Cloud::Alloydb::V1alpha::Gemini;

    my $msg = Google::Cloud::Alloydb::V1alpha::Gemini::GeminiClusterConfig->new({
        entitled => $entitled,
    });

    # Read or update a field
    my $val = $msg->entitled();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Alloydb::V1alpha::Gemini::GeminiClusterConfig->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/alloydb/v1alpha/gemini.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Alloydb::V1alpha::Gemini::GeminiClusterConfig

Deprecated and unused. This message will be removed in the near future.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->entitled() >> / C<< $msg->entitled($value) >>

Type: C<Bool>

Output only. Deprecated and unused. This field will be removed in the near
future.

=back

=head2 Google::Cloud::Alloydb::V1alpha::Gemini::GeminiInstanceConfig

Deprecated and unused. This message will be removed in the near future.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->entitled() >> / C<< $msg->entitled($value) >>

Type: C<Bool>

Output only. Deprecated and unused. This field will be removed in the near
future.

=back

=head2 Google::Cloud::Alloydb::V1alpha::Gemini::GCAInstanceConfig

Instance level configuration parameters related to the Gemini Cloud Assist
product.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->gca_entitlement() >> / C<< $msg->gca_entitlement($value) >>

Type: C<Enum> (L<Google::Cloud::Alloydb::V1alpha::GCAEntitlementType>)

Output only. Represents the GCA entitlement state of the instance.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Alloydb::V1alpha::Gemini::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
