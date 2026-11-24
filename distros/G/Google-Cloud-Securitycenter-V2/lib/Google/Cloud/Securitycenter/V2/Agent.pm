package Google::Cloud::Securitycenter::V2::Agent;

use strict;
use warnings;

our $VERSION = '0.14';

use Protobuf::Message;
use Protobuf::DescriptorPool;
use Protobuf::Internal qw(:all);
use MIME::Base64;

BEGIN {
    my $descriptor_b64 = <<'EOF';
Cipnb29nbGUvY2xvdWQvc2VjdXJpdHljZW50ZXIvdjIvYWdlbnQucHJvdG8SHmdvb2dsZS5j
bG91ZC5zZWN1cml0eWNlbnRlci52MiI6CgVBZ2VudBIOCgJpZBgBIAEoCVICaWQSIQoMZGlz
cGxheV9uYW1lGAIgASgJUgtkaXNwbGF5TmFtZULkAQoiY29tLmdvb2dsZS5jbG91ZC5zZWN1
cml0eWNlbnRlci52MkIKQWdlbnRQcm90b1ABWkpjbG91ZC5nb29nbGUuY29tL2dvL3NlY3Vy
aXR5Y2VudGVyL2FwaXYyL3NlY3VyaXR5Y2VudGVycGI7c2VjdXJpdHljZW50ZXJwYqoCHkdv
b2dsZS5DbG91ZC5TZWN1cml0eUNlbnRlci5WMsoCHkdvb2dsZVxDbG91ZFxTZWN1cml0eUNl
bnRlclxWMuoCIUdvb2dsZTo6Q2xvdWQ6OlNlY3VyaXR5Q2VudGVyOjpWMkqjCAoGEgQOACIB
CrwECgEMEgMOABIysQQgQ29weXJpZ2h0IDIwMjYgR29vZ2xlIExMQwoKIExpY2Vuc2VkIHVu
ZGVyIHRoZSBBcGFjaGUgTGljZW5zZSwgVmVyc2lvbiAyLjAgKHRoZSAiTGljZW5zZSIpOwog
eW91IG1heSBub3QgdXNlIHRoaXMgZmlsZSBleGNlcHQgaW4gY29tcGxpYW5jZSB3aXRoIHRo
ZSBMaWNlbnNlLgogWW91IG1heSBvYnRhaW4gYSBjb3B5IG9mIHRoZSBMaWNlbnNlIGF0Cgog
ICAgIGh0dHA6Ly93d3cuYXBhY2hlLm9yZy9saWNlbnNlcy9MSUNFTlNFLTIuMAoKIFVubGVz
cyByZXF1aXJlZCBieSBhcHBsaWNhYmxlIGxhdyBvciBhZ3JlZWQgdG8gaW4gd3JpdGluZywg
c29mdHdhcmUKIGRpc3RyaWJ1dGVkIHVuZGVyIHRoZSBMaWNlbnNlIGlzIGRpc3RyaWJ1dGVk
IG9uIGFuICJBUyBJUyIgQkFTSVMsCiBXSVRIT1VUIFdBUlJBTlRJRVMgT1IgQ09ORElUSU9O
UyBPRiBBTlkgS0lORCwgZWl0aGVyIGV4cHJlc3Mgb3IgaW1wbGllZC4KIFNlZSB0aGUgTGlj
ZW5zZSBmb3IgdGhlIHNwZWNpZmljIGxhbmd1YWdlIGdvdmVybmluZyBwZXJtaXNzaW9ucyBh
bmQKIGxpbWl0YXRpb25zIHVuZGVyIHRoZSBMaWNlbnNlLgoKCAoBAhIDEAAnCggKAQgSAxIA
OwoJCgIIJRIDEgA7CggKAQgSAxMAYQoJCgIICxIDEwBhCggKAQgSAxQAIgoJCgIIChIDFAAi
CggKAQgSAxUAKwoJCgIICBIDFQArCggKAQgSAxYAOwoJCgIIARIDFgA7CggKAQgSAxcAOwoJ
CgIIKRIDFwA7CggKAQgSAxgAOgoJCgIILRIDGAA6Ci4KAgQAEgQbACIBGiIgUmVwcmVzZW50
cyBhIG1vbml0b3JlZCBBSSBBZ2VudC4KCgoKAwQAARIDGwgNCicKBAQAAgASAx0CEBoaIElk
ZW50aWZpZXIgb2YgdGhlIGFnZW50LgoKDAoFBAACAAUSAx0CCAoMCgUEAAIAARIDHQkLCgwK
BQQAAgADEgMdDg8KgwEKBAQAAgESAyECGhp2IFRoZSB1c2VyIGZyaWVuZGx5IG5hbWUgb2Yg
dGhlIHNwZWNpZmljIGFnZW50IGluc3RhbmNlIHdoZXJlIHRoZSBmaW5kaW5nIHdhcwogZGV0
ZWN0ZWQsIGZvciBleGFtcGxlLCAiQmFua2luZyBBZ2VudCIuCgoMCgUEAAIBBRIDIQIICgwK
BQQAAgEBEgMhCRUKDAoFBAACAQMSAyEYGWIGcHJvdG8z
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Securitycenter::V2::Agent::Agent ===
    # Fields for Agent
    # Field: id Type: 9 ()
    # Field: display_name Type: 9 ()

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Securitycenter::V2::Agent - Compiled Protocol Buffers messages for google/cloud/securitycenter/v2/agent.proto

=head1 SYNOPSIS

    use Google::Cloud::Securitycenter::V2::Agent;

    my $msg = Google::Cloud::Securitycenter::V2::Agent::Agent->new({
        id => $id,
        display_name => $display_name,
    });

    # Read or update a field
    my $val = $msg->id();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Securitycenter::V2::Agent::Agent->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/securitycenter/v2/agent.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Securitycenter::V2::Agent::Agent

Represents a monitored AI Agent.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->id() >> / C<< $msg->id($value) >>

Type: C<String>

Identifier of the agent.

=item * C<< $msg->display_name() >> / C<< $msg->display_name($value) >>

Type: C<String>

The user friendly name of the specific agent instance where the finding was
detected, for example, "Banking Agent".

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Securitycenter::V2::Agent::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
