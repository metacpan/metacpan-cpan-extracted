package Google::Cloud::Tasks::V2::CmekConfig;

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
Cidnb29nbGUvY2xvdWQvdGFza3MvdjIvY21la19jb25maWcucHJvdG8SFWdvb2dsZS5jbG91
ZC50YXNrcy52MhofZ29vZ2xlL2FwaS9maWVsZF9iZWhhdmlvci5wcm90bxoZZ29vZ2xlL2Fw
aS9yZXNvdXJjZS5wcm90byLFAQoKQ21la0NvbmZpZxIXCgRuYW1lGAEgASgJQgPgQQNSBG5h
bWUSPwoHa21zX2tleRgCIAEoCUIm+kEjCiFjbG91ZGttcy5nb29nbGVhcGlzLmNvbS9Dcnlw
dG9LZXlSBmttc0tleTpd6kFaCiRjbG91ZHRhc2tzLmdvb2dsZWFwaXMuY29tL0NtZWtDb25m
aWcSMnByb2plY3RzL3twcm9qZWN0fS9sb2NhdGlvbnMve2xvY2F0aW9ufS9jbWVrQ29uZmln
QukBChljb20uZ29vZ2xlLmNsb3VkLnRhc2tzLnYyQg9DbWVrQ29uZmlnUHJvdG9QAVo+Y2xv
dWQuZ29vZ2xlLmNvbS9nby9jbG91ZHRhc2tzL2FwaXYyL2Nsb3VkdGFza3NwYjtjbG91ZHRh
c2tzcGLqQXgKIWNsb3Vka21zLmdvb2dsZWFwaXMuY29tL0NyeXB0b0tleRJTcHJvamVjdHMv
e3Byb2plY3R9L2xvY2F0aW9ucy97bG9jYXRpb259L2tleVJpbmdzL3trZXlfcmluZ30vY3J5
cHRvS2V5cy97Y3J5cHRvX2tleX1K3QsKBhIEDgAyAQq8BAoBDBIDDgASMrEEIENvcHlyaWdo
dCAyMDI2IEdvb2dsZSBMTEMKCiBMaWNlbnNlZCB1bmRlciB0aGUgQXBhY2hlIExpY2Vuc2Us
IFZlcnNpb24gMi4wICh0aGUgIkxpY2Vuc2UiKTsKIHlvdSBtYXkgbm90IHVzZSB0aGlzIGZp
bGUgZXhjZXB0IGluIGNvbXBsaWFuY2Ugd2l0aCB0aGUgTGljZW5zZS4KIFlvdSBtYXkgb2J0
YWluIGEgY29weSBvZiB0aGUgTGljZW5zZSBhdAoKICAgICBodHRwOi8vd3d3LmFwYWNoZS5v
cmcvbGljZW5zZXMvTElDRU5TRS0yLjAKCiBVbmxlc3MgcmVxdWlyZWQgYnkgYXBwbGljYWJs
ZSBsYXcgb3IgYWdyZWVkIHRvIGluIHdyaXRpbmcsIHNvZnR3YXJlCiBkaXN0cmlidXRlZCB1
bmRlciB0aGUgTGljZW5zZSBpcyBkaXN0cmlidXRlZCBvbiBhbiAiQVMgSVMiIEJBU0lTLAog
V0lUSE9VVCBXQVJSQU5USUVTIE9SIENPTkRJVElPTlMgT0YgQU5ZIEtJTkQsIGVpdGhlciBl
eHByZXNzIG9yIGltcGxpZWQuCiBTZWUgdGhlIExpY2Vuc2UgZm9yIHRoZSBzcGVjaWZpYyBs
YW5ndWFnZSBnb3Zlcm5pbmcgcGVybWlzc2lvbnMgYW5kCiBsaW1pdGF0aW9ucyB1bmRlciB0
aGUgTGljZW5zZS4KCggKAQISAxAAHgoJCgIDABIDEgApCgkKAgMBEgMTACMKCAoBCBIDFQBV
CgkKAggLEgMVAFUKCAoBCBIDFgAiCgkKAggKEgMWACIKCAoBCBIDFwAwCgkKAggIEgMXADAK
CAoBCBIDGAAyCgkKAggBEgMYADIKCQoBCBIEGQAcAgoMCgQInQgAEgQZABwCCnkKAgQAEgQg
ADIBGm0gRGVzY3JpYmVzIHRoZSBjdXN0b21lci1tYW5hZ2VkIGVuY3J5cHRpb24ga2V5IChD
TUVLKSBjb25maWd1cmF0aW9uIGFzc29jaWF0ZWQKIHdpdGggYSBwcm9qZWN0IGFuZCBsb2Nh
dGlvbi4KCgoKAwQAARIDIAgSCgsKAwQABxIEIQIkBAoNCgUEAAedCBIEIQIkBArCAQoEBAAC
ABIDKQI+GrQBIE91dHB1dCBvbmx5LiBUaGUgY29uZmlnIHJlc291cmNlIG5hbWUgd2hpY2gg
aW5jbHVkZXMgdGhlIHByb2plY3QgYW5kCiBsb2NhdGlvbiBhbmQgbXVzdCBlbmQgaW4gJ2Nt
ZWtDb25maWcnLCBpbiB0aGUgZm9ybWF0CiBgcHJvamVjdHMvUFJPSkVDVF9JRC9sb2NhdGlv
bnMvTE9DQVRJT05fSUQvY21la0NvbmZpZ2AKCgwKBQQAAgAFEgMpAggKDAoFBAACAAESAykJ
DQoMCgUEAAIAAxIDKRARCgwKBQQAAgAIEgMpEj0KDwoIBAACAAicCAASAykTPAqLAgoEBAAC
ARIELwIxBRr8ASBSZXNvdXJjZSBuYW1lIG9mIHRoZSBDbG91ZCBLTVMga2V5LCBvZiB0aGUg
Zm9ybQogYHByb2plY3RzL1BST0pFQ1RfSUQvbG9jYXRpb25zL0xPQ0FUSU9OX0lEL2tleVJp
bmdzL0tFWV9SSU5HX0lEL2NyeXB0b0tleXMvS0VZX0lEYCwKIHRoYXQgd2lsbCBiZSB1c2Vk
IHRvIGVuY3J5cHQgdGhlIFF1ZXVlcyAmIFRhc2tzIGluIHRoZSByZWdpb24uIFNldHRpbmcK
IHRoaXMgYXMgYmxhbmsgd2lsbCB0dXJuIG9mZiBDTUVLIGVuY3J5cHRpb24uCgoMCgUEAAIB
BRIDLwIICgwKBQQAAgEBEgMvCRAKDAoFBAACAQMSAy8TFAoNCgUEAAIBCBIELxUxBAoPCgcE
AAIBCJ8IEgQvFjEDYgZwcm90bzM=
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Tasks::V2::CmekConfig::CmekConfig ===
    # Fields for CmekConfig
    # Field: name Type: 9 ()
    # Field: kms_key Type: 9 ()

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Tasks::V2::CmekConfig - Compiled Protocol Buffers messages for google/cloud/tasks/v2/cmek_config.proto

=head1 SYNOPSIS

    use Google::Cloud::Tasks::V2::CmekConfig;

    my $msg = Google::Cloud::Tasks::V2::CmekConfig::CmekConfig->new({
        name => $name,
        kms_key => $kms_key,
    });

    # Read or update a field
    my $val = $msg->name();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Tasks::V2::CmekConfig::CmekConfig->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/tasks/v2/cmek_config.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Tasks::V2::CmekConfig::CmekConfig

Describes the customer-managed encryption key (CMEK) configuration associated
with a project and location.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Output only. The config resource name which includes the project and
location and must end in 'cmekConfig', in the format
`projects/PROJECT_ID/locations/LOCATION_ID/cmekConfig`

=item * C<< $msg->kms_key() >> / C<< $msg->kms_key($value) >>

Type: C<String>

Resource name of the Cloud KMS key, of the form
`projects/PROJECT_ID/locations/LOCATION_ID/keyRings/KEY_RING_ID/cryptoKeys/KEY_ID`,
that will be used to encrypt the Queues & Tasks in the region. Setting
this as blank will turn off CMEK encryption.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Tasks::V2::CmekConfig::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
