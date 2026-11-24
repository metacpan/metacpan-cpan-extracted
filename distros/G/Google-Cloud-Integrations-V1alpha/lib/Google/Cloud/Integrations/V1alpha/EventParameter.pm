package Google::Cloud::Integrations::V1alpha::EventParameter;

use strict;
use warnings;

our $VERSION = '0.14';

use Protobuf::Message;
use Protobuf::DescriptorPool;
use Protobuf::Internal qw(:all);
use MIME::Base64;

BEGIN {
    eval { require Google::Cloud::Integrations::V1alpha::ValueType };
    my $descriptor_b64 = <<'EOF';
Cjdnb29nbGUvY2xvdWQvaW50ZWdyYXRpb25zL3YxYWxwaGEvZXZlbnRfcGFyYW1ldGVyLnBy
b3RvEiFnb29nbGUuY2xvdWQuaW50ZWdyYXRpb25zLnYxYWxwaGEaMmdvb2dsZS9jbG91ZC9p
bnRlZ3JhdGlvbnMvdjFhbHBoYS92YWx1ZV90eXBlLnByb3RvIn4KDkV2ZW50UGFyYW1ldGVy
EhAKA2tleRgBIAEoCVIDa2V5EkIKBXZhbHVlGAIgASgLMiwuZ29vZ2xlLmNsb3VkLmludGVn
cmF0aW9ucy52MWFscGhhLlZhbHVlVHlwZVIFdmFsdWUSFgoGbWFza2VkGAMgASgIUgZtYXNr
ZWRCrQEKJWNvbS5nb29nbGUuY2xvdWQuaW50ZWdyYXRpb25zLnYxYWxwaGFCE0V2ZW50UGFy
YW1ldGVyUHJvdG9QAVpJY2xvdWQuZ29vZ2xlLmNvbS9nby9pbnRlZ3JhdGlvbnMvYXBpdjFh
bHBoYS9pbnRlZ3JhdGlvbnNwYjtpbnRlZ3JhdGlvbnNwYqoCIUdvb2dsZS5DbG91ZC5JbnRl
Z3JhdGlvbnMuVjFBbHBoYUrtCgoGEgQOACkBCrwECgEMEgMOABIysQQgQ29weXJpZ2h0IDIw
MjUgR29vZ2xlIExMQwoKIExpY2Vuc2VkIHVuZGVyIHRoZSBBcGFjaGUgTGljZW5zZSwgVmVy
c2lvbiAyLjAgKHRoZSAiTGljZW5zZSIpOwogeW91IG1heSBub3QgdXNlIHRoaXMgZmlsZSBl
eGNlcHQgaW4gY29tcGxpYW5jZSB3aXRoIHRoZSBMaWNlbnNlLgogWW91IG1heSBvYnRhaW4g
YSBjb3B5IG9mIHRoZSBMaWNlbnNlIGF0CgogICAgIGh0dHA6Ly93d3cuYXBhY2hlLm9yZy9s
aWNlbnNlcy9MSUNFTlNFLTIuMAoKIFVubGVzcyByZXF1aXJlZCBieSBhcHBsaWNhYmxlIGxh
dyBvciBhZ3JlZWQgdG8gaW4gd3JpdGluZywgc29mdHdhcmUKIGRpc3RyaWJ1dGVkIHVuZGVy
IHRoZSBMaWNlbnNlIGlzIGRpc3RyaWJ1dGVkIG9uIGFuICJBUyBJUyIgQkFTSVMsCiBXSVRI
T1VUIFdBUlJBTlRJRVMgT1IgQ09ORElUSU9OUyBPRiBBTlkgS0lORCwgZWl0aGVyIGV4cHJl
c3Mgb3IgaW1wbGllZC4KIFNlZSB0aGUgTGljZW5zZSBmb3IgdGhlIHNwZWNpZmljIGxhbmd1
YWdlIGdvdmVybmluZyBwZXJtaXNzaW9ucyBhbmQKIGxpbWl0YXRpb25zIHVuZGVyIHRoZSBM
aWNlbnNlLgoKCAoBAhIDEAAqCgkKAgMAEgMSADwKCAoBCBIDFAA+CgkKAgglEgMUAD4KCAoB
CBIDFQBgCgkKAggLEgMVAGAKCAoBCBIDFgAiCgkKAggKEgMWACIKCAoBCBIDFwA0CgkKAggI
EgMXADQKCAoBCBIDGAA+CgkKAggBEgMYAD4KpQEKAgQAEgQdACkBGpgBIFRoaXMgbWVzc2Fn
ZSBpcyB1c2VkIGZvciBwcm9jZXNzaW5nIGFuZCBwZXJzaXN0aW5nICh3aGVuIGFwcGxpY2Fi
bGUpIGtleQogdmFsdWUgcGFpciBwYXJhbWV0ZXJzIGZvciBlYWNoIGV2ZW50IGluIHRoZSBl
dmVudCBidXMuCiBOZXh0IGF2YWlsYWJsZSBpZDogNAoKCgoDBAABEgMdCBYKvgEKBAQAAgAS
AyECERqwASBLZXkgaXMgdXNlZCB0byByZXRyaWV2ZSB0aGUgY29ycmVzcG9uZGluZyBwYXJh
bWV0ZXIgdmFsdWUuIFRoaXMgc2hvdWxkIGJlCiB1bmlxdWUgZm9yIGEgZ2l2ZW4gZmlyZWQg
ZXZlbnQuIFRoZXNlIHBhcmFtZXRlcnMgbXVzdCBiZSBwcmVkZWZpbmVkIGluIHRoZQogaW50
ZWdyYXRpb24gZGVmaW5pdGlvbi4KCgwKBQQAAgAFEgMhAggKDAoFBAACAAESAyEJDAoMCgUE
AAIAAxIDIQ8QCm8KBAQAAgESAyUCFhpiIFZhbHVlcyBmb3IgdGhlIGRlZmluZWQga2V5cy4g
RWFjaCB2YWx1ZSBjYW4gZWl0aGVyIGJlIHN0cmluZywgaW50LCBkb3VibGUKIG9yIGFueSBw
cm90byBtZXNzYWdlLgoKDAoFBAACAQYSAyUCCwoMCgUEAAIBARIDJQwRCgwKBQQAAgEDEgMl
FBUKQgoEBAACAhIDKAISGjUgVHJ1ZSBpZiB0aGlzIHBhcmFtZXRlciBzaG91bGQgYmUgbWFz
a2VkIGluIHRoZSBsb2dzCgoMCgUEAAICBRIDKAIGCgwKBQQAAgIBEgMoBw0KDAoFBAACAgMS
AygQEWIGcHJvdG8z
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Integrations::V1alpha::EventParameter::EventParameter ===
    # Fields for EventParameter
    # Field: key Type: 9 ()
    # Field: value Type: 11 (.google.cloud.integrations.v1alpha.ValueType)
    # Field: masked Type: 8 ()

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Integrations::V1alpha::EventParameter - Compiled Protocol Buffers messages for google/cloud/integrations/v1alpha/event_parameter.proto

=head1 SYNOPSIS

    use Google::Cloud::Integrations::V1alpha::EventParameter;

    my $msg = Google::Cloud::Integrations::V1alpha::EventParameter::EventParameter->new({
        key => $key,
        value => $value,
        masked => $masked,
    });

    # Read or update a field
    my $val = $msg->key();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Integrations::V1alpha::EventParameter::EventParameter->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/integrations/v1alpha/event_parameter.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Integrations::V1alpha::EventParameter::EventParameter

This message is used for processing and persisting (when applicable) key
value pair parameters for each event in the event bus.
Next available id: 4

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->key() >> / C<< $msg->key($value) >>

Type: C<String>

Key is used to retrieve the corresponding parameter value. This should be
unique for a given fired event. These parameters must be predefined in the
integration definition.

=item * C<< $msg->value() >> / C<< $msg->value($value) >>

Type: C<Message> (L<Google::Cloud::Integrations::V1alpha::ValueType::ValueType>)

Values for the defined keys. Each value can either be string, int, double
or any proto message.

=item * C<< $msg->masked() >> / C<< $msg->masked($value) >>

Type: C<Bool>

True if this parameter should be masked in the logs

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Integrations::V1alpha::EventParameter::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
