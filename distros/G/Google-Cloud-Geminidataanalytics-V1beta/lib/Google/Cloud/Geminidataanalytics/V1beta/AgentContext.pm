package Google::Cloud::Geminidataanalytics::V1beta::AgentContext;

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
Cjtnb29nbGUvY2xvdWQvZ2VtaW5pZGF0YWFuYWx5dGljcy92MWJldGEvYWdlbnRfY29udGV4
dC5wcm90bxInZ29vZ2xlLmNsb3VkLmdlbWluaWRhdGFhbmFseXRpY3MudjFiZXRhGh9nb29n
bGUvYXBpL2ZpZWxkX2JlaGF2aW9yLnByb3RvIkIKFUFnZW50Q29udGV4dFJlZmVyZW5jZRIp
Cg5jb250ZXh0X3NldF9pZBgBIAEoCUID4EECUgxjb250ZXh0U2V0SWRCogIKK2NvbS5nb29n
bGUuY2xvdWQuZ2VtaW5pZGF0YWFuYWx5dGljcy52MWJldGFCEUFnZW50Q29udGV4dFByb3Rv
UAFaXWNsb3VkLmdvb2dsZS5jb20vZ28vZ2VtaW5pZGF0YWFuYWx5dGljcy9hcGl2MWJldGEv
Z2VtaW5pZGF0YWFuYWx5dGljc3BiO2dlbWluaWRhdGFhbmFseXRpY3NwYqoCJ0dvb2dsZS5D
bG91ZC5HZW1pbmlEYXRhQW5hbHl0aWNzLlYxQmV0YcoCJ0dvb2dsZVxDbG91ZFxHZW1pbmlE
YXRhQW5hbHl0aWNzXFYxYmV0YeoCKkdvb2dsZTo6Q2xvdWQ6OkdlbWluaURhdGFBbmFseXRp
Y3M6OlYxYmV0YUq8BwoGEgQOACABCrwECgEMEgMOABIysQQgQ29weXJpZ2h0IDIwMjYgR29v
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
LgoKCAoBAhIDEAAwCgkKAgMAEgMSACkKCAoBCBIDFABECgkKAgglEgMUAEQKCAoBCBIDFQB0
CgkKAggLEgMVAHQKCAoBCBIDFgAiCgkKAggKEgMWACIKCAoBCBIDFwAyCgkKAggIEgMXADIK
CAoBCBIDGABECgkKAggBEgMYAEQKCAoBCBIDGQBECgkKAggpEgMZAEQKCAoBCBIDGgBDCgkK
AggtEgMaAEMKQAoCBAASBB0AIAEaNCBNZXNzYWdlIHJlcHJlc2VudGluZyBhIHJlZmVyZW5j
ZSB0byBBZ2VudCBDb250ZXh0LgoKCgoDBAABEgMdCB0KNAoEBAACABIDHwJFGicgUmVxdWly
ZWQuIENvbnRleHQgc2V0IElEIHRvIHJldHJpZXZlLgoKDAoFBAACAAUSAx8CCAoMCgUEAAIA
ARIDHwkXCgwKBQQAAgADEgMfGhsKDAoFBAACAAgSAx8cRAoPCggEAAIACJwIABIDHx1DYgZw
cm90bzM=
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Geminidataanalytics::V1beta::AgentContext::AgentContextReference ===
    # Fields for AgentContextReference
    # Field: context_set_id Type: 9 ()

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Geminidataanalytics::V1beta::AgentContext - Compiled Protocol Buffers messages for google/cloud/geminidataanalytics/v1beta/agent_context.proto

=head1 SYNOPSIS

    use Google::Cloud::Geminidataanalytics::V1beta::AgentContext;

    my $msg = Google::Cloud::Geminidataanalytics::V1beta::AgentContext::AgentContextReference->new({
        context_set_id => $context_set_id,
    });

    # Read or update a field
    my $val = $msg->context_set_id();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Geminidataanalytics::V1beta::AgentContext::AgentContextReference->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/geminidataanalytics/v1beta/agent_context.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Geminidataanalytics::V1beta::AgentContext::AgentContextReference

Message representing a reference to Agent Context.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->context_set_id() >> / C<< $msg->context_set_id($value) >>

Type: C<String>

Required. Context set ID to retrieve.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Geminidataanalytics::V1beta::AgentContext::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
