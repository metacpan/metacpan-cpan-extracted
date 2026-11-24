package Google::Cloud::Ces::V1::ToolsetTool;

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
CiZnb29nbGUvY2xvdWQvY2VzL3YxL3Rvb2xzZXRfdG9vbC5wcm90bxITZ29vZ2xlLmNsb3Vk
LmNlcy52MRofZ29vZ2xlL2FwaS9maWVsZF9iZWhhdmlvci5wcm90bxoZZ29vZ2xlL2FwaS9y
ZXNvdXJjZS5wcm90byJpCgtUb29sc2V0VG9vbBI8Cgd0b29sc2V0GAEgASgJQiLgQQL6QRwK
GmNlcy5nb29nbGVhcGlzLmNvbS9Ub29sc2V0Ugd0b29sc2V0EhwKB3Rvb2xfaWQYAyABKAlC
A+BBAVIGdG9vbElkQlgKF2NvbS5nb29nbGUuY2xvdWQuY2VzLnYxQhBUb29sc2V0VG9vbFBy
b3RvUAFaKWNsb3VkLmdvb2dsZS5jb20vZ28vY2VzL2FwaXYxL2Nlc3BiO2Nlc3BiSqcJCgYS
BA4AJgEKvAQKAQwSAw4AEjKxBCBDb3B5cmlnaHQgMjAyNiBHb29nbGUgTExDCgogTGljZW5z
ZWQgdW5kZXIgdGhlIEFwYWNoZSBMaWNlbnNlLCBWZXJzaW9uIDIuMCAodGhlICJMaWNlbnNl
Iik7CiB5b3UgbWF5IG5vdCB1c2UgdGhpcyBmaWxlIGV4Y2VwdCBpbiBjb21wbGlhbmNlIHdp
dGggdGhlIExpY2Vuc2UuCiBZb3UgbWF5IG9idGFpbiBhIGNvcHkgb2YgdGhlIExpY2Vuc2Ug
YXQKCiAgICAgaHR0cDovL3d3dy5hcGFjaGUub3JnL2xpY2Vuc2VzL0xJQ0VOU0UtMi4wCgog
VW5sZXNzIHJlcXVpcmVkIGJ5IGFwcGxpY2FibGUgbGF3IG9yIGFncmVlZCB0byBpbiB3cml0
aW5nLCBzb2Z0d2FyZQogZGlzdHJpYnV0ZWQgdW5kZXIgdGhlIExpY2Vuc2UgaXMgZGlzdHJp
YnV0ZWQgb24gYW4gIkFTIElTIiBCQVNJUywKIFdJVEhPVVQgV0FSUkFOVElFUyBPUiBDT05E
SVRJT05TIE9GIEFOWSBLSU5ELCBlaXRoZXIgZXhwcmVzcyBvciBpbXBsaWVkLgogU2VlIHRo
ZSBMaWNlbnNlIGZvciB0aGUgc3BlY2lmaWMgbGFuZ3VhZ2UgZ292ZXJuaW5nIHBlcm1pc3Np
b25zIGFuZAogbGltaXRhdGlvbnMgdW5kZXIgdGhlIExpY2Vuc2UuCgoICgECEgMQABwKCQoC
AwASAxIAKQoJCgIDARIDEwAjCggKAQgSAxUAQAoJCgIICxIDFQBACggKAQgSAxYAIgoJCgII
ChIDFgAiCggKAQgSAxcAMQoJCgIICBIDFwAxCggKAQgSAxgAMAoJCgIIARIDGAAwCjQKAgQA
EgQbACYBGiggQSB0b29sIHRoYXQgaXMgY3JlYXRlZCBmcm9tIGEgdG9vbHNldC4KCgoKAwQA
ARIDGwgTCq4BCgQEAAIAEgQfAiIEGp8BIFJlcXVpcmVkLiBUaGUgcmVzb3VyY2UgbmFtZSBv
ZiB0aGUgVG9vbHNldCBmcm9tIHdoaWNoIHRoaXMgdG9vbCBpcyBkZXJpdmVkLgogRm9ybWF0
OgogYHByb2plY3RzL3twcm9qZWN0fS9sb2NhdGlvbnMve2xvY2F0aW9ufS9hcHBzL3thcHB9
L3Rvb2xzZXRzL3t0b29sc2V0fWAKCgwKBQQAAgAFEgMfAggKDAoFBAACAAESAx8JEAoMCgUE
AAIAAxIDHxMUCg0KBQQAAgAIEgQfFSIDCg8KCAQAAgAInAgAEgMgBCoKDgoHBAACAAifCBID
IQRMClQKBAQAAgESAyUCPhpHIE9wdGlvbmFsLiBUaGUgdG9vbCBJRCB0byBmaWx0ZXIgdGhl
IHRvb2xzIHRvIHJldHJpZXZlIHRoZSBzY2hlbWEgZm9yLgoKDAoFBAACAQUSAyUCCAoMCgUE
AAIBARIDJQkQCgwKBQQAAgEDEgMlExQKDAoFBAACAQgSAyUVPQoPCggEAAIBCJwIABIDJRY8
YgZwcm90bzM=
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Ces::V1::ToolsetTool::ToolsetTool ===
    # Fields for ToolsetTool
    # Field: toolset Type: 9 ()
    # Field: tool_id Type: 9 ()

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Ces::V1::ToolsetTool - Compiled Protocol Buffers messages for google/cloud/ces/v1/toolset_tool.proto

=head1 SYNOPSIS

    use Google::Cloud::Ces::V1::ToolsetTool;

    my $msg = Google::Cloud::Ces::V1::ToolsetTool::ToolsetTool->new({
        toolset => $toolset,
        tool_id => $tool_id,
    });

    # Read or update a field
    my $val = $msg->toolset();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Ces::V1::ToolsetTool::ToolsetTool->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/ces/v1/toolset_tool.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Ces::V1::ToolsetTool::ToolsetTool

A tool that is created from a toolset.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->toolset() >> / C<< $msg->toolset($value) >>

Type: C<String>

Required. The resource name of the Toolset from which this tool is derived.
Format:
`projects/{project}/locations/{location}/apps/{app}/toolsets/{toolset}`

=item * C<< $msg->tool_id() >> / C<< $msg->tool_id($value) >>

Type: C<String>

Optional. The tool ID to filter the tools to retrieve the schema for.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Ces::V1::ToolsetTool::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
