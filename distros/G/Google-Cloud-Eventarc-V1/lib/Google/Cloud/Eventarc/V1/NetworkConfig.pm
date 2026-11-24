package Google::Cloud::Eventarc::V1::NetworkConfig;

use strict;
use warnings;

our $VERSION = '0.14';

use Protobuf::Message;
use Protobuf::DescriptorPool;
use Protobuf::Internal qw(:all);
use MIME::Base64;

BEGIN {
    eval { require Google::Api::FieldBehavior };
    eval { require Google::Api::Resource };
    my $descriptor_b64 = <<'EOF';
Ci1nb29nbGUvY2xvdWQvZXZlbnRhcmMvdjEvbmV0d29ya19jb25maWcucHJvdG8SGGdvb2ds
ZS5jbG91ZC5ldmVudGFyYy52MRofZ29vZ2xlL2FwaS9maWVsZF9iZWhhdmlvci5wcm90bxoZ
Z29vZ2xlL2FwaS9yZXNvdXJjZS5wcm90byJwCg1OZXR3b3JrQ29uZmlnEl8KEm5ldHdvcmtf
YXR0YWNobWVudBgBIAEoCUIw4EEC+kEqCihjb21wdXRlLmdvb2dsZWFwaXMuY29tL05ldHdv
cmtBdHRhY2htZW50UhFuZXR3b3JrQXR0YWNobWVudELCAQocY29tLmdvb2dsZS5jbG91ZC5l
dmVudGFyYy52MUISTmV0d29ya0NvbmZpZ1Byb3RvUAFaOGNsb3VkLmdvb2dsZS5jb20vZ28v
ZXZlbnRhcmMvYXBpdjEvZXZlbnRhcmNwYjtldmVudGFyY3BiqgIYR29vZ2xlLkNsb3VkLkV2
ZW50YXJjLlYxygIYR29vZ2xlXENsb3VkXEV2ZW50YXJjXFYx6gIbR29vZ2xlOjpDbG91ZDo6
RXZlbnRhcmM6OlYxSvIICgYSBA4AKAEKvAQKAQwSAw4AEjKxBCBDb3B5cmlnaHQgMjAyNSBH
b29nbGUgTExDCgogTGljZW5zZWQgdW5kZXIgdGhlIEFwYWNoZSBMaWNlbnNlLCBWZXJzaW9u
IDIuMCAodGhlICJMaWNlbnNlIik7CiB5b3UgbWF5IG5vdCB1c2UgdGhpcyBmaWxlIGV4Y2Vw
dCBpbiBjb21wbGlhbmNlIHdpdGggdGhlIExpY2Vuc2UuCiBZb3UgbWF5IG9idGFpbiBhIGNv
cHkgb2YgdGhlIExpY2Vuc2UgYXQKCiAgICAgaHR0cDovL3d3dy5hcGFjaGUub3JnL2xpY2Vu
c2VzL0xJQ0VOU0UtMi4wCgogVW5sZXNzIHJlcXVpcmVkIGJ5IGFwcGxpY2FibGUgbGF3IG9y
IGFncmVlZCB0byBpbiB3cml0aW5nLCBzb2Z0d2FyZQogZGlzdHJpYnV0ZWQgdW5kZXIgdGhl
IExpY2Vuc2UgaXMgZGlzdHJpYnV0ZWQgb24gYW4gIkFTIElTIiBCQVNJUywKIFdJVEhPVVQg
V0FSUkFOVElFUyBPUiBDT05ESVRJT05TIE9GIEFOWSBLSU5ELCBlaXRoZXIgZXhwcmVzcyBv
ciBpbXBsaWVkLgogU2VlIHRoZSBMaWNlbnNlIGZvciB0aGUgc3BlY2lmaWMgbGFuZ3VhZ2Ug
Z292ZXJuaW5nIHBlcm1pc3Npb25zIGFuZAogbGltaXRhdGlvbnMgdW5kZXIgdGhlIExpY2Vu
c2UuCgoICgECEgMQACEKCQoCAwASAxIAKQoJCgIDARIDEwAjCggKAQgSAxUANQoJCgIIJRID
FQA1CggKAQgSAxYATwoJCgIICxIDFgBPCggKAQgSAxcAIgoJCgIIChIDFwAiCggKAQgSAxgA
MwoJCgIICBIDGAAzCggKAQgSAxkANQoJCgIIARIDGQA1CggKAQgSAxoANQoJCgIIKRIDGgA1
CggKAQgSAxsANAoJCgIILRIDGwA0CkoKAgQAEgQeACgBGj4gTmV0d29yayBDb25maWd1cmF0
aW9uIHRoYXQgY2FuIGJlIGluaGVyaXRlZCBieSBvdGhlciBwcm90b3MuCgoKCgMEAAESAx4I
FQrCAQoEBAACABIEIgInBBqzASBSZXF1aXJlZC4gTmFtZSBvZiB0aGUgTmV0d29ya0F0dGFj
aG1lbnQgdGhhdCBhbGxvd3MgYWNjZXNzIHRvIHRoZQogY3VzdG9tZXIncyBWUEMuIEZvcm1h
dDoKIGBwcm9qZWN0cy97UFJPSkVDVF9JRH0vcmVnaW9ucy97UkVHSU9OfS9uZXR3b3JrQXR0
YWNobWVudHMve05FVFdPUktfQVRUQUNITUVOVF9OQU1FfWAKCgwKBQQAAgAFEgMiAggKDAoF
BAACAAESAyIJGwoMCgUEAAIAAxIDIh4fCg0KBQQAAgAIEgQiICcDCg8KCAQAAgAInAgAEgMj
BCoKDwoHBAACAAifCBIEJAQmBWIGcHJvdG8z
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Eventarc::V1::NetworkConfig::NetworkConfig ===
    # Fields for NetworkConfig
    # Field: network_attachment Type: 9 ()

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Eventarc::V1::NetworkConfig - Compiled Protocol Buffers messages for google/cloud/eventarc/v1/network_config.proto

=head1 SYNOPSIS

    use Google::Cloud::Eventarc::V1::NetworkConfig;

    my $msg = Google::Cloud::Eventarc::V1::NetworkConfig::NetworkConfig->new({
        network_attachment => $network_attachment,
    });

    # Read or update a field
    my $val = $msg->network_attachment();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Eventarc::V1::NetworkConfig::NetworkConfig->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/eventarc/v1/network_config.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Eventarc::V1::NetworkConfig::NetworkConfig

Network Configuration that can be inherited by other protos.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->network_attachment() >> / C<< $msg->network_attachment($value) >>

Type: C<String>

Required. Name of the NetworkAttachment that allows access to the
customer's VPC. Format:
`projects/{PROJECT_ID}/regions/{REGION}/networkAttachments/{NETWORK_ATTACHMENT_NAME}`

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Eventarc::V1::NetworkConfig::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
