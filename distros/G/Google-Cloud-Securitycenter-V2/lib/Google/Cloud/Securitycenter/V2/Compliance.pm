package Google::Cloud::Securitycenter::V2::Compliance;

use strict;
use warnings;

our $VERSION = '0.14';

use Protobuf::Message;
use Protobuf::DescriptorPool;
use Protobuf::Internal qw(:all);
use MIME::Base64;

BEGIN {
    my $descriptor_b64 = <<'EOF';
Ci9nb29nbGUvY2xvdWQvc2VjdXJpdHljZW50ZXIvdjIvY29tcGxpYW5jZS5wcm90bxIeZ29v
Z2xlLmNsb3VkLnNlY3VyaXR5Y2VudGVyLnYyIlQKCkNvbXBsaWFuY2USGgoIc3RhbmRhcmQY
ASABKAlSCHN0YW5kYXJkEhgKB3ZlcnNpb24YAiABKAlSB3ZlcnNpb24SEAoDaWRzGAMgAygJ
UgNpZHNC6QEKImNvbS5nb29nbGUuY2xvdWQuc2VjdXJpdHljZW50ZXIudjJCD0NvbXBsaWFu
Y2VQcm90b1ABWkpjbG91ZC5nb29nbGUuY29tL2dvL3NlY3VyaXR5Y2VudGVyL2FwaXYyL3Nl
Y3VyaXR5Y2VudGVycGI7c2VjdXJpdHljZW50ZXJwYqoCHkdvb2dsZS5DbG91ZC5TZWN1cml0
eUNlbnRlci5WMsoCHkdvb2dsZVxDbG91ZFxTZWN1cml0eUNlbnRlclxWMuoCIUdvb2dsZTo6
Q2xvdWQ6OlNlY3VyaXR5Q2VudGVyOjpWMkrgCQoGEgQOACYBCrwECgEMEgMOABIysQQgQ29w
eXJpZ2h0IDIwMjUgR29vZ2xlIExMQwoKIExpY2Vuc2VkIHVuZGVyIHRoZSBBcGFjaGUgTGlj
ZW5zZSwgVmVyc2lvbiAyLjAgKHRoZSAiTGljZW5zZSIpOwogeW91IG1heSBub3QgdXNlIHRo
aXMgZmlsZSBleGNlcHQgaW4gY29tcGxpYW5jZSB3aXRoIHRoZSBMaWNlbnNlLgogWW91IG1h
eSBvYnRhaW4gYSBjb3B5IG9mIHRoZSBMaWNlbnNlIGF0CgogICAgIGh0dHA6Ly93d3cuYXBh
Y2hlLm9yZy9saWNlbnNlcy9MSUNFTlNFLTIuMAoKIFVubGVzcyByZXF1aXJlZCBieSBhcHBs
aWNhYmxlIGxhdyBvciBhZ3JlZWQgdG8gaW4gd3JpdGluZywgc29mdHdhcmUKIGRpc3RyaWJ1
dGVkIHVuZGVyIHRoZSBMaWNlbnNlIGlzIGRpc3RyaWJ1dGVkIG9uIGFuICJBUyBJUyIgQkFT
SVMsCiBXSVRIT1VUIFdBUlJBTlRJRVMgT1IgQ09ORElUSU9OUyBPRiBBTlkgS0lORCwgZWl0
aGVyIGV4cHJlc3Mgb3IgaW1wbGllZC4KIFNlZSB0aGUgTGljZW5zZSBmb3IgdGhlIHNwZWNp
ZmljIGxhbmd1YWdlIGdvdmVybmluZyBwZXJtaXNzaW9ucyBhbmQKIGxpbWl0YXRpb25zIHVu
ZGVyIHRoZSBMaWNlbnNlLgoKCAoBAhIDEAAnCggKAQgSAxIAOwoJCgIIJRIDEgA7CggKAQgS
AxMAYQoJCgIICxIDEwBhCggKAQgSAxQAIgoJCgIIChIDFAAiCggKAQgSAxUAMAoJCgIICBID
FQAwCggKAQgSAxYAOwoJCgIIARIDFgA7CggKAQgSAxcAOwoJCgIIKRIDFwA7CggKAQgSAxgA
OgoJCgIILRIDGAA6CmoKAgQAEgQcACYBGl4gQ29udGFpbnMgY29tcGxpYW5jZSBpbmZvcm1h
dGlvbiBhYm91dCBhIHNlY3VyaXR5IHN0YW5kYXJkIGluZGljYXRpbmcgdW5tZXQKIHJlY29t
bWVuZGF0aW9ucy4KCgoKAwQAARIDHAgSCl4KBAQAAgASAx8CFhpRIEluZHVzdHJ5LXdpZGUg
Y29tcGxpYW5jZSBzdGFuZGFyZHMgb3IgYmVuY2htYXJrcywgc3VjaCBhcyBDSVMsIFBDSSwg
YW5kCiBPV0FTUC4KCgwKBQQAAgAFEgMfAggKDAoFBAACAAESAx8JEQoMCgUEAAIAAxIDHxQV
CkUKBAQAAgESAyICFRo4IFZlcnNpb24gb2YgdGhlIHN0YW5kYXJkIG9yIGJlbmNobWFyaywg
Zm9yIGV4YW1wbGUsIDEuMQoKDAoFBAACAQUSAyICCAoMCgUEAAIBARIDIgkQCgwKBQQAAgED
EgMiExQKTwoEBAACAhIDJQIaGkIgUG9saWNpZXMgd2l0aGluIHRoZSBzdGFuZGFyZCBvciBi
ZW5jaG1hcmssIGZvciBleGFtcGxlLCBBLjEyLjQuMQoKDAoFBAACAgQSAyUCCgoMCgUEAAIC
BRIDJQsRCgwKBQQAAgIBEgMlEhUKDAoFBAACAgMSAyUYGWIGcHJvdG8z
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Securitycenter::V2::Compliance::Compliance ===
    # Fields for Compliance
    # Field: standard Type: 9 ()
    # Field: version Type: 9 ()
    # Field: ids Type: 9 ()

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Securitycenter::V2::Compliance - Compiled Protocol Buffers messages for google/cloud/securitycenter/v2/compliance.proto

=head1 SYNOPSIS

    use Google::Cloud::Securitycenter::V2::Compliance;

    my $msg = Google::Cloud::Securitycenter::V2::Compliance::Compliance->new({
        standard => $standard,
        version => $version,
        ids => $ids,
    });

    # Read or update a field
    my $val = $msg->standard();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Securitycenter::V2::Compliance::Compliance->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/securitycenter/v2/compliance.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Securitycenter::V2::Compliance::Compliance

Contains compliance information about a security standard indicating unmet
recommendations.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->standard() >> / C<< $msg->standard($value) >>

Type: C<String>

Industry-wide compliance standards or benchmarks, such as CIS, PCI, and
OWASP.

=item * C<< $msg->version() >> / C<< $msg->version($value) >>

Type: C<String>

Version of the standard or benchmark, for example, 1.1

=item * C<< $msg->ids() >> / C<< $msg->ids($value) >>

Type: C<String>

Policies within the standard or benchmark, for example, A.12.4.1

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Securitycenter::V2::Compliance::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
