package Google::Cloud::Agentregistry::V1::Properties;

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
Ci5nb29nbGUvY2xvdWQvYWdlbnRyZWdpc3RyeS92MS9wcm9wZXJ0aWVzLnByb3RvEh1nb29n
bGUuY2xvdWQuYWdlbnRyZWdpc3RyeS52MRofZ29vZ2xlL2FwaS9maWVsZF9iZWhhdmlvci5w
cm90bxoZZ29vZ2xlL2FwaS9yZXNvdXJjZS5wcm90byLnAQoJSW50ZXJmYWNlEhUKA3VybBgB
IAEoCUID4EECUgN1cmwSaAoQcHJvdG9jb2xfYmluZGluZxgCIAEoDjI4Lmdvb2dsZS5jbG91
ZC5hZ2VudHJlZ2lzdHJ5LnYxLkludGVyZmFjZS5Qcm90b2NvbEJpbmRpbmdCA+BBAlIPcHJv
dG9jb2xCaW5kaW5nIlkKD1Byb3RvY29sQmluZGluZxIgChxQUk9UT0NPTF9CSU5ESU5HX1VO
U1BFQ0lGSUVEEAASCwoHSlNPTlJQQxABEggKBEdSUEMQAhINCglIVFRQX0pTT04QA0LiAQoh
Y29tLmdvb2dsZS5jbG91ZC5hZ2VudHJlZ2lzdHJ5LnYxQg9Qcm9wZXJ0aWVzUHJvdG9QAVpH
Y2xvdWQuZ29vZ2xlLmNvbS9nby9hZ2VudHJlZ2lzdHJ5L2FwaXYxL2FnZW50cmVnaXN0cnlw
YjthZ2VudHJlZ2lzdHJ5cGKqAh1Hb29nbGUuQ2xvdWQuQWdlbnRSZWdpc3RyeS5WMcoCHUdv
b2dsZVxDbG91ZFxBZ2VudFJlZ2lzdHJ5XFYx6gIgR29vZ2xlOjpDbG91ZDo6QWdlbnRSZWdp
c3RyeTo6VjFKyAsKBhIEDgAzAQq8BAoBDBIDDgASMrEEIENvcHlyaWdodCAyMDI2IEdvb2ds
ZSBMTEMKCiBMaWNlbnNlZCB1bmRlciB0aGUgQXBhY2hlIExpY2Vuc2UsIFZlcnNpb24gMi4w
ICh0aGUgIkxpY2Vuc2UiKTsKIHlvdSBtYXkgbm90IHVzZSB0aGlzIGZpbGUgZXhjZXB0IGlu
IGNvbXBsaWFuY2Ugd2l0aCB0aGUgTGljZW5zZS4KIFlvdSBtYXkgb2J0YWluIGEgY29weSBv
ZiB0aGUgTGljZW5zZSBhdAoKICAgICBodHRwOi8vd3d3LmFwYWNoZS5vcmcvbGljZW5zZXMv
TElDRU5TRS0yLjAKCiBVbmxlc3MgcmVxdWlyZWQgYnkgYXBwbGljYWJsZSBsYXcgb3IgYWdy
ZWVkIHRvIGluIHdyaXRpbmcsIHNvZnR3YXJlCiBkaXN0cmlidXRlZCB1bmRlciB0aGUgTGlj
ZW5zZSBpcyBkaXN0cmlidXRlZCBvbiBhbiAiQVMgSVMiIEJBU0lTLAogV0lUSE9VVCBXQVJS
QU5USUVTIE9SIENPTkRJVElPTlMgT0YgQU5ZIEtJTkQsIGVpdGhlciBleHByZXNzIG9yIGlt
cGxpZWQuCiBTZWUgdGhlIExpY2Vuc2UgZm9yIHRoZSBzcGVjaWZpYyBsYW5ndWFnZSBnb3Zl
cm5pbmcgcGVybWlzc2lvbnMgYW5kCiBsaW1pdGF0aW9ucyB1bmRlciB0aGUgTGljZW5zZS4K
CggKAQISAxAAJgoJCgIDABIDEgApCgkKAgMBEgMTACMKCAoBCBIDFQA6CgkKAgglEgMVADoK
CAoBCBIDFgBeCgkKAggLEgMWAF4KCAoBCBIDFwAiCgkKAggKEgMXACIKCAoBCBIDGAAwCgkK
AggIEgMYADAKCAoBCBIDGQA6CgkKAggBEgMZADoKCAoBCBIDGgA6CgkKAggpEgMaADoKCAoB
CBIDGwA5CgkKAggtEgMbADkKSwoCBAASBB4AMwEaPyBSZXByZXNlbnRzIHRoZSBjb25uZWN0
aW9uIGRldGFpbHMgZm9yIGFuIEFnZW50IG9yIE1DUCBTZXJ2ZXIuCgoKCgMEAAESAx4IEQo2
CgQEAAQAEgQgAiwDGiggVGhlIHByb3RvY29sIGJpbmRpbmcgb2YgdGhlIGludGVyZmFjZS4K
CgwKBQQABAABEgMgBxYKMAoGBAAEAAIAEgMiBCUaISBVbnNwZWNpZmllZCB0cmFuc3BvcnQg
cHJvdG9jb2wuCgoOCgcEAAQAAgABEgMiBCAKDgoHBAAEAAIAAhIDIiMkCigKBgQABAACARID
JQQQGhkgSlNPTi1SUEMgc3BlY2lmaWNhdGlvbi4KCg4KBwQABAACAQESAyUECwoOCgcEAAQA
AgECEgMlDg8KJAoGBAAEAAICEgMoBA0aFSBnUlBDIHNwZWNpZmljYXRpb24uCgoOCgcEAAQA
AgIBEgMoBAgKDgoHBAAEAAICAhIDKAsMCikKBgQABAACAxIDKwQSGhogSFRUUCtKU09OIHNw
ZWNpZmljYXRpb24uCgoOCgcEAAQAAgMBEgMrBA0KDgoHBAAEAAIDAhIDKxARCi0KBAQAAgAS
Ay8COhogIFJlcXVpcmVkLiBUaGUgZGVzdGluYXRpb24gVVJMLgoKDAoFBAACAAUSAy8CCAoM
CgUEAAIAARIDLwkMCgwKBQQAAgADEgMvDxAKDAoFBAACAAgSAy8ROQoPCggEAAIACJwIABID
LxI4Cj8KBAQAAgESAzICUBoyIFJlcXVpcmVkLiBUaGUgcHJvdG9jb2wgYmluZGluZyBvZiB0
aGUgaW50ZXJmYWNlLgoKDAoFBAACAQYSAzICEQoMCgUEAAIBARIDMhIiCgwKBQQAAgEDEgMy
JSYKDAoFBAACAQgSAzInTwoPCggEAAIBCJwIABIDMihOYgZwcm90bzM=
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Agentregistry::V1::Properties::Interface ===
    # Fields for Interface
    # Field: url Type: 9 ()
    # Field: protocol_binding Type: 14 (.google.cloud.agentregistry.v1.Interface.ProtocolBinding)

# Enum: Interface::ProtocolBinding
our $Interface_PROTOCOL_BINDING_UNSPECIFIED = 0;
our $Interface_JSONRPC = 1;
our $Interface_GRPC = 2;
our $Interface_HTTP_JSON = 3;

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Agentregistry::V1::Properties - Compiled Protocol Buffers messages for google/cloud/agentregistry/v1/properties.proto

=head1 SYNOPSIS

    use Google::Cloud::Agentregistry::V1::Properties;

    my $msg = Google::Cloud::Agentregistry::V1::Properties::Interface->new({
        url => $url,
        protocol_binding => $protocol_binding,
    });

    # Read or update a field
    my $val = $msg->url();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Agentregistry::V1::Properties::Interface->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/agentregistry/v1/properties.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Agentregistry::V1::Properties::Interface

Represents the connection details for an Agent or MCP Server.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->url() >> / C<< $msg->url($value) >>

Type: C<String>

Required. The destination URL.

=item * C<< $msg->protocol_binding() >> / C<< $msg->protocol_binding($value) >>

Type: C<Enum> (L<Google::Cloud::Agentregistry::V1::Interface::ProtocolBinding>)

Required. The protocol binding of the interface.

=back

=head3 Enum: Interface::ProtocolBinding

=over 4

=item * C<PROTOCOL_BINDING_UNSPECIFIED> => C<0>

=item * C<JSONRPC> => C<1>

=item * C<GRPC> => C<2>

=item * C<HTTP_JSON> => C<3>

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Agentregistry::V1::Properties::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
