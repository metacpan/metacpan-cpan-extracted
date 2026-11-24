package Google::Cloud::Ces::V1beta::ToolsetTool;

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
Cipnb29nbGUvY2xvdWQvY2VzL3YxYmV0YS90b29sc2V0X3Rvb2wucHJvdG8SF2dvb2dsZS5j
bG91ZC5jZXMudjFiZXRhGh9nb29nbGUvYXBpL2ZpZWxkX2JlaGF2aW9yLnByb3RvGhlnb29n
bGUvYXBpL3Jlc291cmNlLnByb3RvImkKC1Rvb2xzZXRUb29sEjwKB3Rvb2xzZXQYASABKAlC
IuBBAvpBHAoaY2VzLmdvb2dsZWFwaXMuY29tL1Rvb2xzZXRSB3Rvb2xzZXQSHAoHdG9vbF9p
ZBgDIAEoCUID4EEBUgZ0b29sSWRCYAobY29tLmdvb2dsZS5jbG91ZC5jZXMudjFiZXRhQhBU
b29sc2V0VG9vbFByb3RvUAFaLWNsb3VkLmdvb2dsZS5jb20vZ28vY2VzL2FwaXYxYmV0YS9j
ZXNwYjtjZXNwYkqnCQoGEgQOACYBCrwECgEMEgMOABIysQQgQ29weXJpZ2h0IDIwMjYgR29v
Z2xlIExMQwoKIExpY2Vuc2VkIHVuZGVyIHRoZSBBcGFjaGUgTGljZW5zZSwgVmVyc2lvbiAy
LjAgKHRoZSAiTGljZW5zZSIpOwogeW91IG1heSBub3QgdXNlIHRoaXMgZmlsZSBleGNlcHQg
aW4gY29tcGxpYW5jZSB3aXRoIHRoZSBMaWNlbnNlLgogWW91IG1heSBvYnRhaW4gYSBjb3B5
IG9mIHRoZSBMaWNlbnNlIGF0CgogICAgIGh0dHA6Ly93d3cuYXBhY2hlLm9yZy9saWNlbnNl
cy9MSUNFTlNFLTIuMAoKIFVubGVzcyByZXF1aXJlZCBieSBhcHBsaWNhYmxlIGxhdyBvciBh
Z3JlZWQgdG8gaW4gd3JpdGluZywgc29mdHdhcmUKIGRpc3RyaWJ1dGVkIHVuZGVyIHRoZSBM
aWNlbnNlIGlzIGRpc3RyaWJ1dGVkIG9uIGFuICJBUyBJUyIgQkFTSVMsCiBXSVRIT1VUIFdB
UlJBTlRJRVMgT1IgQ09ORElUSU9OUyBPRiBBTlkgS0lORCwgZWl0aGVyIGV4cHJlc3Mgb3Ig
aW1wbGllZC4KIFNlZSB0aGUgTGljZW5zZSBmb3IgdGhlIHNwZWNpZmljIGxhbmd1YWdlIGdv
dmVybmluZyBwZXJtaXNzaW9ucyBhbmQKIGxpbWl0YXRpb25zIHVuZGVyIHRoZSBMaWNlbnNl
LgoKCAoBAhIDEAAgCgkKAgMAEgMSACkKCQoCAwESAxMAIwoICgEIEgMVAEQKCQoCCAsSAxUA
RAoICgEIEgMWACIKCQoCCAoSAxYAIgoICgEIEgMXADEKCQoCCAgSAxcAMQoICgEIEgMYADQK
CQoCCAESAxgANAo0CgIEABIEGwAmARooIEEgdG9vbCB0aGF0IGlzIGNyZWF0ZWQgZnJvbSBh
IHRvb2xzZXQuCgoKCgMEAAESAxsIEwquAQoEBAACABIEHwIiBBqfASBSZXF1aXJlZC4gVGhl
IHJlc291cmNlIG5hbWUgb2YgdGhlIFRvb2xzZXQgZnJvbSB3aGljaCB0aGlzIHRvb2wgaXMg
ZGVyaXZlZC4KIEZvcm1hdDoKIGBwcm9qZWN0cy97cHJvamVjdH0vbG9jYXRpb25zL3tsb2Nh
dGlvbn0vYXBwcy97YXBwfS90b29sc2V0cy97dG9vbHNldH1gCgoMCgUEAAIABRIDHwIICgwK
BQQAAgABEgMfCRAKDAoFBAACAAMSAx8TFAoNCgUEAAIACBIEHxUiAwoPCggEAAIACJwIABID
IAQqCg4KBwQAAgAInwgSAyEETApUCgQEAAIBEgMlAj4aRyBPcHRpb25hbC4gVGhlIHRvb2wg
SUQgdG8gZmlsdGVyIHRoZSB0b29scyB0byByZXRyaWV2ZSB0aGUgc2NoZW1hIGZvci4KCgwK
BQQAAgEFEgMlAggKDAoFBAACAQESAyUJEAoMCgUEAAIBAxIDJRMUCgwKBQQAAgEIEgMlFT0K
DwoIBAACAQicCAASAyUWPGIGcHJvdG8z
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Ces::V1beta::ToolsetTool::ToolsetTool ===
    # Fields for ToolsetTool
    # Field: toolset Type: 9 ()
    # Field: tool_id Type: 9 ()

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Ces::V1beta::ToolsetTool - Compiled Protocol Buffers messages for google/cloud/ces/v1beta/toolset_tool.proto

=head1 SYNOPSIS

    use Google::Cloud::Ces::V1beta::ToolsetTool;

    my $msg = Google::Cloud::Ces::V1beta::ToolsetTool::ToolsetTool->new({
        toolset => $toolset,
        tool_id => $tool_id,
    });

    # Read or update a field
    my $val = $msg->toolset();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Ces::V1beta::ToolsetTool::ToolsetTool->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/ces/v1beta/toolset_tool.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Ces::V1beta::ToolsetTool::ToolsetTool

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

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Ces::V1beta::ToolsetTool::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
