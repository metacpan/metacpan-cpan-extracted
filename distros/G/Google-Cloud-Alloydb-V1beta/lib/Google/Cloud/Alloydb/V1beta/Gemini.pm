package Google::Cloud::Alloydb::V1beta::Gemini;

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
Cihnb29nbGUvY2xvdWQvYWxsb3lkYi92MWJldGEvZ2VtaW5pLnByb3RvEhtnb29nbGUuY2xv
dWQuYWxsb3lkYi52MWJldGEaH2dvb2dsZS9hcGkvZmllbGRfYmVoYXZpb3IucHJvdG8iOAoT
R2VtaW5pQ2x1c3RlckNvbmZpZxIhCghlbnRpdGxlZBgBIAEoCEIFGAHgQQNSCGVudGl0bGVk
IjkKFEdlbWluaUluc3RhbmNlQ29uZmlnEiEKCGVudGl0bGVkGAEgASgIQgUYAeBBA1IIZW50
aXRsZWQicgoRR0NBSW5zdGFuY2VDb25maWcSXQoPZ2NhX2VudGl0bGVtZW50GAEgASgOMi8u
Z29vZ2xlLmNsb3VkLmFsbG95ZGIudjFiZXRhLkdDQUVudGl0bGVtZW50VHlwZUID4EEDUg5n
Y2FFbnRpdGxlbWVudCpMChJHQ0FFbnRpdGxlbWVudFR5cGUSJAogR0NBX0VOVElUTEVNRU5U
X1RZUEVfVU5TUEVDSUZJRUQQABIQCgxHQ0FfU1RBTkRBUkQQAULIAQofY29tLmdvb2dsZS5j
bG91ZC5hbGxveWRiLnYxYmV0YUILR2VtaW5pUHJvdG9QAVo5Y2xvdWQuZ29vZ2xlLmNvbS9n
by9hbGxveWRiL2FwaXYxYmV0YS9hbGxveWRicGI7YWxsb3lkYnBiqgIbR29vZ2xlLkNsb3Vk
LkFsbG95RGIuVjFCZXRhygIbR29vZ2xlXENsb3VkXEFsbG95RGJcVjFiZXRh6gIeR29vZ2xl
OjpDbG91ZDo6QWxsb3lEQjo6VjFiZXRhSsgOCgYSBA4AOwEKvAQKAQwSAw4AEjKxBCBDb3B5
cmlnaHQgMjAyNSBHb29nbGUgTExDCgogTGljZW5zZWQgdW5kZXIgdGhlIEFwYWNoZSBMaWNl
bnNlLCBWZXJzaW9uIDIuMCAodGhlICJMaWNlbnNlIik7CiB5b3UgbWF5IG5vdCB1c2UgdGhp
cyBmaWxlIGV4Y2VwdCBpbiBjb21wbGlhbmNlIHdpdGggdGhlIExpY2Vuc2UuCiBZb3UgbWF5
IG9idGFpbiBhIGNvcHkgb2YgdGhlIExpY2Vuc2UgYXQKCiAgICAgaHR0cDovL3d3dy5hcGFj
aGUub3JnL2xpY2Vuc2VzL0xJQ0VOU0UtMi4wCgogVW5sZXNzIHJlcXVpcmVkIGJ5IGFwcGxp
Y2FibGUgbGF3IG9yIGFncmVlZCB0byBpbiB3cml0aW5nLCBzb2Z0d2FyZQogZGlzdHJpYnV0
ZWQgdW5kZXIgdGhlIExpY2Vuc2UgaXMgZGlzdHJpYnV0ZWQgb24gYW4gIkFTIElTIiBCQVNJ
UywKIFdJVEhPVVQgV0FSUkFOVElFUyBPUiBDT05ESVRJT05TIE9GIEFOWSBLSU5ELCBlaXRo
ZXIgZXhwcmVzcyBvciBpbXBsaWVkLgogU2VlIHRoZSBMaWNlbnNlIGZvciB0aGUgc3BlY2lm
aWMgbGFuZ3VhZ2UgZ292ZXJuaW5nIHBlcm1pc3Npb25zIGFuZAogbGltaXRhdGlvbnMgdW5k
ZXIgdGhlIExpY2Vuc2UuCgoICgECEgMQACQKCQoCAwASAxIAKQoICgEIEgMUADgKCQoCCCUS
AxQAOAoICgEIEgMVAFAKCQoCCAsSAxUAUAoICgEIEgMWACIKCQoCCAoSAxYAIgoICgEIEgMX
ACwKCQoCCAgSAxcALAoICgEIEgMYADgKCQoCCAESAxgAOAoICgEIEgMZADgKCQoCCCkSAxkA
OAoICgEIEgMaADcKCQoCCC0SAxoANwpTCgIFABIEHQAjARpHIEVudW0gcmVwcmVzZW50aW5n
IHRoZSB0eXBlIG9mIEdDQSBlbnRpdGxlbWVudCBhc3NpZ25lZCB0byBhIHJlc291cmNlLgoK
CgoDBQABEgMdBRcKLgoEBQACABIDHwInGiEgTm8gR0NBIGVudGl0bGVtZW50IGlzIGFzc2ln
bmVkLgoKDAoFBQACAAESAx8CIgoMCgUFAAIAAhIDHyUmCkEKBAUAAgESAyICExo0IFRoZSBy
ZXNvdXJjZSBpcyBlbnRpdGxlZCB0byB0aGUgR0NBIFN0YW5kYXJkIFRpZXIuCgoMCgUFAAIB
ARIDIgIOCgwKBQUAAgECEgMiERIKVQoCBAASBCYAKwEaSSBEZXByZWNhdGVkIGFuZCB1bnVz
ZWQuIFRoaXMgbWVzc2FnZSB3aWxsIGJlIHJlbW92ZWQgaW4gdGhlIG5lYXIgZnV0dXJlLgoK
CgoDBAABEgMmCBsKYwoEBAACABIEKQIqRRpVIE91dHB1dCBvbmx5LiBEZXByZWNhdGVkIGFu
ZCB1bnVzZWQuIFRoaXMgZmllbGQgd2lsbCBiZSByZW1vdmVkIGluIHRoZSBuZWFyCiBmdXR1
cmUuCgoMCgUEAAIABRIDKQIGCgwKBQQAAgABEgMpBw8KDAoFBAACAAMSAykSEwoMCgUEAAIA
CBIDKgZECg0KBgQAAgAIAxIDKgcYCg8KCAQAAgAInAgAEgMqGkMKVQoCBAESBC4AMwEaSSBE
ZXByZWNhdGVkIGFuZCB1bnVzZWQuIFRoaXMgbWVzc2FnZSB3aWxsIGJlIHJlbW92ZWQgaW4g
dGhlIG5lYXIgZnV0dXJlLgoKCgoDBAEBEgMuCBwKYwoEBAECABIEMQIyRRpVIE91dHB1dCBv
bmx5LiBEZXByZWNhdGVkIGFuZCB1bnVzZWQuIFRoaXMgZmllbGQgd2lsbCBiZSByZW1vdmVk
IGluIHRoZSBuZWFyCiBmdXR1cmUuCgoMCgUEAQIABRIDMQIGCgwKBQQBAgABEgMxBw8KDAoF
BAECAAMSAzESEwoMCgUEAQIACBIDMgZECg0KBgQBAgAIAxIDMgcYCg8KCAQBAgAInAgAEgMy
GkMKYgoCBAISBDcAOwEaViBJbnN0YW5jZSBsZXZlbCBjb25maWd1cmF0aW9uIHBhcmFtZXRl
cnMgcmVsYXRlZCB0byB0aGUgR2VtaW5pIENsb3VkIEFzc2lzdAogcHJvZHVjdC4KCgoKAwQC
ARIDNwgZClIKBAQCAgASBDkCOjIaRCBPdXRwdXQgb25seS4gUmVwcmVzZW50cyB0aGUgR0NB
IGVudGl0bGVtZW50IHN0YXRlIG9mIHRoZSBpbnN0YW5jZS4KCgwKBQQCAgAGEgM5AhQKDAoF
BAICAAESAzkVJAoMCgUEAgIAAxIDOScoCgwKBQQCAgAIEgM6BjEKDwoIBAICAAicCAASAzoH
MGIGcHJvdG8z
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Alloydb::V1beta::Gemini::GeminiClusterConfig ===
    # Fields for GeminiClusterConfig
    # Field: entitled Type: 8 ()

# === Message: Google::Cloud::Alloydb::V1beta::Gemini::GeminiInstanceConfig ===
    # Fields for GeminiInstanceConfig
    # Field: entitled Type: 8 ()

# === Message: Google::Cloud::Alloydb::V1beta::Gemini::GCAInstanceConfig ===
    # Fields for GCAInstanceConfig
    # Field: gca_entitlement Type: 14 (.google.cloud.alloydb.v1beta.GCAEntitlementType)

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Alloydb::V1beta::Gemini - Compiled Protocol Buffers messages for google/cloud/alloydb/v1beta/gemini.proto

=head1 SYNOPSIS

    use Google::Cloud::Alloydb::V1beta::Gemini;

    my $msg = Google::Cloud::Alloydb::V1beta::Gemini::GeminiClusterConfig->new({
        entitled => $entitled,
    });

    # Read or update a field
    my $val = $msg->entitled();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Alloydb::V1beta::Gemini::GeminiClusterConfig->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/alloydb/v1beta/gemini.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Alloydb::V1beta::Gemini::GeminiClusterConfig

Deprecated and unused. This message will be removed in the near future.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->entitled() >> / C<< $msg->entitled($value) >>

Type: C<Bool>

Output only. Deprecated and unused. This field will be removed in the near
future.

=back

=head2 Google::Cloud::Alloydb::V1beta::Gemini::GeminiInstanceConfig

Deprecated and unused. This message will be removed in the near future.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->entitled() >> / C<< $msg->entitled($value) >>

Type: C<Bool>

Output only. Deprecated and unused. This field will be removed in the near
future.

=back

=head2 Google::Cloud::Alloydb::V1beta::Gemini::GCAInstanceConfig

Instance level configuration parameters related to the Gemini Cloud Assist
product.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->gca_entitlement() >> / C<< $msg->gca_entitlement($value) >>

Type: C<Enum> (L<Google::Cloud::Alloydb::V1beta::GCAEntitlementType>)

Output only. Represents the GCA entitlement state of the instance.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Alloydb::V1beta::Gemini::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
