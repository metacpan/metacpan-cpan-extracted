package Google::Cloud::Ces::V1beta::SystemTool;

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
Cilnb29nbGUvY2xvdWQvY2VzL3YxYmV0YS9zeXN0ZW1fdG9vbC5wcm90bxIXZ29vZ2xlLmNs
b3VkLmNlcy52MWJldGEaH2dvb2dsZS9hcGkvZmllbGRfYmVoYXZpb3IucHJvdG8iTAoKU3lz
dGVtVG9vbBIXCgRuYW1lGAEgASgJQgPgQQJSBG5hbWUSJQoLZGVzY3JpcHRpb24YAiABKAlC
A+BBA1ILZGVzY3JpcHRpb25CXwobY29tLmdvb2dsZS5jbG91ZC5jZXMudjFiZXRhQg9TeXN0
ZW1Ub29sUHJvdG9QAVotY2xvdWQuZ29vZ2xlLmNvbS9nby9jZXMvYXBpdjFiZXRhL2Nlc3Bi
O2Nlc3BiSu4HCgYSBA4AIAEKvAQKAQwSAw4AEjKxBCBDb3B5cmlnaHQgMjAyNiBHb29nbGUg
TExDCgogTGljZW5zZWQgdW5kZXIgdGhlIEFwYWNoZSBMaWNlbnNlLCBWZXJzaW9uIDIuMCAo
dGhlICJMaWNlbnNlIik7CiB5b3UgbWF5IG5vdCB1c2UgdGhpcyBmaWxlIGV4Y2VwdCBpbiBj
b21wbGlhbmNlIHdpdGggdGhlIExpY2Vuc2UuCiBZb3UgbWF5IG9idGFpbiBhIGNvcHkgb2Yg
dGhlIExpY2Vuc2UgYXQKCiAgICAgaHR0cDovL3d3dy5hcGFjaGUub3JnL2xpY2Vuc2VzL0xJ
Q0VOU0UtMi4wCgogVW5sZXNzIHJlcXVpcmVkIGJ5IGFwcGxpY2FibGUgbGF3IG9yIGFncmVl
ZCB0byBpbiB3cml0aW5nLCBzb2Z0d2FyZQogZGlzdHJpYnV0ZWQgdW5kZXIgdGhlIExpY2Vu
c2UgaXMgZGlzdHJpYnV0ZWQgb24gYW4gIkFTIElTIiBCQVNJUywKIFdJVEhPVVQgV0FSUkFO
VElFUyBPUiBDT05ESVRJT05TIE9GIEFOWSBLSU5ELCBlaXRoZXIgZXhwcmVzcyBvciBpbXBs
aWVkLgogU2VlIHRoZSBMaWNlbnNlIGZvciB0aGUgc3BlY2lmaWMgbGFuZ3VhZ2UgZ292ZXJu
aW5nIHBlcm1pc3Npb25zIGFuZAogbGltaXRhdGlvbnMgdW5kZXIgdGhlIExpY2Vuc2UuCgoI
CgECEgMQACAKCQoCAwASAxIAKQoICgEIEgMUAEQKCQoCCAsSAxQARAoICgEIEgMVACIKCQoC
CAoSAxUAIgoICgEIEgMWADAKCQoCCAgSAxYAMAoICgEIEgMXADQKCQoCCAESAxcANAomCgIE
ABIEGgAgARoaIFByZS1kZWZpbmVkIHN5c3RlbSB0b29sLgoKCgoDBAABEgMaCBIKNQoEBAAC
ABIDHAI7GiggUmVxdWlyZWQuIFRoZSBuYW1lIG9mIHRoZSBzeXN0ZW0gdG9vbC4KCgwKBQQA
AgAFEgMcAggKDAoFBAACAAESAxwJDQoMCgUEAAIAAxIDHBARCgwKBQQAAgAIEgMcEjoKDwoI
BAACAAicCAASAxwTOQo/CgQEAAIBEgMfAkUaMiBPdXRwdXQgb25seS4gVGhlIGRlc2NyaXB0
aW9uIG9mIHRoZSBzeXN0ZW0gdG9vbC4KCgwKBQQAAgEFEgMfAggKDAoFBAACAQESAx8JFAoM
CgUEAAIBAxIDHxcYCgwKBQQAAgEIEgMfGUQKDwoIBAACAQicCAASAx8aQ2IGcHJvdG8z
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Ces::V1beta::SystemTool::SystemTool ===
    # Fields for SystemTool
    # Field: name Type: 9 ()
    # Field: description Type: 9 ()

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Ces::V1beta::SystemTool - Compiled Protocol Buffers messages for google/cloud/ces/v1beta/system_tool.proto

=head1 SYNOPSIS

    use Google::Cloud::Ces::V1beta::SystemTool;

    my $msg = Google::Cloud::Ces::V1beta::SystemTool::SystemTool->new({
        name => $name,
        description => $description,
    });

    # Read or update a field
    my $val = $msg->name();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Ces::V1beta::SystemTool::SystemTool->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/ces/v1beta/system_tool.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Ces::V1beta::SystemTool::SystemTool

Pre-defined system tool.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. The name of the system tool.

=item * C<< $msg->description() >> / C<< $msg->description($value) >>

Type: C<String>

Output only. The description of the system tool.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Ces::V1beta::SystemTool::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
