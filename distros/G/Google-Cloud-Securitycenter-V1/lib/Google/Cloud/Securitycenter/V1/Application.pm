package Google::Cloud::Securitycenter::V1::Application;

use strict;
use warnings;

our $VERSION = '0.14';

use Protobuf::Message;
use Protobuf::DescriptorPool;
use Protobuf::Internal qw(:all);
use MIME::Base64;

BEGIN {
    my $descriptor_b64 = <<'EOF';
CjBnb29nbGUvY2xvdWQvc2VjdXJpdHljZW50ZXIvdjEvYXBwbGljYXRpb24ucHJvdG8SHmdv
b2dsZS5jbG91ZC5zZWN1cml0eWNlbnRlci52MSJDCgtBcHBsaWNhdGlvbhIZCghiYXNlX3Vy
aRgBIAEoCVIHYmFzZVVyaRIZCghmdWxsX3VyaRgCIAEoCVIHZnVsbFVyaULqAQoiY29tLmdv
b2dsZS5jbG91ZC5zZWN1cml0eWNlbnRlci52MUIQQXBwbGljYXRpb25Qcm90b1ABWkpjbG91
ZC5nb29nbGUuY29tL2dvL3NlY3VyaXR5Y2VudGVyL2FwaXYxL3NlY3VyaXR5Y2VudGVycGI7
c2VjdXJpdHljZW50ZXJwYqoCHkdvb2dsZS5DbG91ZC5TZWN1cml0eUNlbnRlci5WMcoCHkdv
b2dsZVxDbG91ZFxTZWN1cml0eUNlbnRlclxWMeoCIUdvb2dsZTo6Q2xvdWQ6OlNlY3VyaXR5
Q2VudGVyOjpWMUq3CQoGEgQOACMBCrwECgEMEgMOABIysQQgQ29weXJpZ2h0IDIwMjUgR29v
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
LgoKCAoBAhIDEAAnCggKAQgSAxIAOwoJCgIIJRIDEgA7CggKAQgSAxMAYQoJCgIICxIDEwBh
CggKAQgSAxQAIgoJCgIIChIDFAAiCggKAQgSAxUAMQoJCgIICBIDFQAxCggKAQgSAxYAOwoJ
CgIIARIDFgA7CggKAQgSAxcAOwoJCgIIKRIDFwA7CggKAQgSAxgAOgoJCgIILRIDGAA6CkIK
AgQAEgQbACMBGjYgUmVwcmVzZW50cyBhbiBhcHBsaWNhdGlvbiBhc3NvY2lhdGVkIHdpdGgg
YSBmaW5kaW5nLgoKCgoDBAABEgMbCBMKoQEKBAQAAgASAx4CFhqTASBUaGUgYmFzZSBVUkkg
dGhhdCBpZGVudGlmaWVzIHRoZSBuZXR3b3JrIGxvY2F0aW9uIG9mIHRoZSBhcHBsaWNhdGlv
biBpbgogd2hpY2ggdGhlIHZ1bG5lcmFiaWxpdHkgd2FzIGRldGVjdGVkLiBGb3IgZXhhbXBs
ZSwgYGh0dHA6Ly9leGFtcGxlLmNvbWAuCgoMCgUEAAIABRIDHgIICgwKBQQAAgABEgMeCREK
DAoFBAACAAMSAx4UFQqIAQoEBAACARIDIgIWGnsgVGhlIGZ1bGwgVVJJIHdpdGggcGF5bG9h
ZCB0aGF0IGNhbiBiZSB1c2VkIHRvIHJlcHJvZHVjZSB0aGUKIHZ1bG5lcmFiaWxpdHkuIEZv
ciBleGFtcGxlLCBgaHR0cDovL2V4YW1wbGUuY29tP3A9YU1tWWdJNkhgLgoKDAoFBAACAQUS
AyICCAoMCgUEAAIBARIDIgkRCgwKBQQAAgEDEgMiFBViBnByb3RvMw==
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Securitycenter::V1::Application::Application ===
    # Fields for Application
    # Field: base_uri Type: 9 ()
    # Field: full_uri Type: 9 ()

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Securitycenter::V1::Application - Compiled Protocol Buffers messages for google/cloud/securitycenter/v1/application.proto

=head1 SYNOPSIS

    use Google::Cloud::Securitycenter::V1::Application;

    my $msg = Google::Cloud::Securitycenter::V1::Application::Application->new({
        base_uri => $base_uri,
        full_uri => $full_uri,
    });

    # Read or update a field
    my $val = $msg->base_uri();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Securitycenter::V1::Application::Application->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/securitycenter/v1/application.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Securitycenter::V1::Application::Application

Represents an application associated with a finding.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->base_uri() >> / C<< $msg->base_uri($value) >>

Type: C<String>

The base URI that identifies the network location of the application in
which the vulnerability was detected. For example, `http://example.com`.

=item * C<< $msg->full_uri() >> / C<< $msg->full_uri($value) >>

Type: C<String>

The full URI with payload that can be used to reproduce the
vulnerability. For example, `http://example.com?p=aMmYgI6H`.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Securitycenter::V1::Application::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
