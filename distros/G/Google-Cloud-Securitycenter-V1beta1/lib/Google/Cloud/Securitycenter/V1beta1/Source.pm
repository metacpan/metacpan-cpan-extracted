package Google::Cloud::Securitycenter::V1beta1::Source;

use strict;
use warnings;

our $VERSION = '0.14';

use Protobuf::Message;
use Protobuf::DescriptorPool;
use Protobuf::Internal qw(:all);
use MIME::Base64;

BEGIN {
    eval { require Google::Api::Resource };
    my $descriptor_b64 = <<'EOF';
CjBnb29nbGUvY2xvdWQvc2VjdXJpdHljZW50ZXIvdjFiZXRhMS9zb3VyY2UucHJvdG8SI2dv
b2dsZS5jbG91ZC5zZWN1cml0eWNlbnRlci52MWJldGExGhlnb29nbGUvYXBpL3Jlc291cmNl
LnByb3RvIrsBCgZTb3VyY2USEgoEbmFtZRgBIAEoCVIEbmFtZRIhCgxkaXNwbGF5X25hbWUY
AiABKAlSC2Rpc3BsYXlOYW1lEiAKC2Rlc2NyaXB0aW9uGAMgASgJUgtkZXNjcmlwdGlvbjpY
6kFVCiRzZWN1cml0eWNlbnRlci5nb29nbGVhcGlzLmNvbS9Tb3VyY2USLW9yZ2FuaXphdGlv
bnMve29yZ2FuaXphdGlvbn0vc291cmNlcy97c291cmNlfUJ8Cidjb20uZ29vZ2xlLmNsb3Vk
LnNlY3VyaXR5Y2VudGVyLnYxYmV0YTFQAVpPY2xvdWQuZ29vZ2xlLmNvbS9nby9zZWN1cml0
eWNlbnRlci9hcGl2MWJldGExL3NlY3VyaXR5Y2VudGVycGI7c2VjdXJpdHljZW50ZXJwYkr6
DgoGEgQOADYBCrwECgEMEgMOABIysQQgQ29weXJpZ2h0IDIwMjUgR29vZ2xlIExMQwoKIExp
Y2Vuc2VkIHVuZGVyIHRoZSBBcGFjaGUgTGljZW5zZSwgVmVyc2lvbiAyLjAgKHRoZSAiTGlj
ZW5zZSIpOwogeW91IG1heSBub3QgdXNlIHRoaXMgZmlsZSBleGNlcHQgaW4gY29tcGxpYW5j
ZSB3aXRoIHRoZSBMaWNlbnNlLgogWW91IG1heSBvYnRhaW4gYSBjb3B5IG9mIHRoZSBMaWNl
bnNlIGF0CgogICAgIGh0dHA6Ly93d3cuYXBhY2hlLm9yZy9saWNlbnNlcy9MSUNFTlNFLTIu
MAoKIFVubGVzcyByZXF1aXJlZCBieSBhcHBsaWNhYmxlIGxhdyBvciBhZ3JlZWQgdG8gaW4g
d3JpdGluZywgc29mdHdhcmUKIGRpc3RyaWJ1dGVkIHVuZGVyIHRoZSBMaWNlbnNlIGlzIGRp
c3RyaWJ1dGVkIG9uIGFuICJBUyBJUyIgQkFTSVMsCiBXSVRIT1VUIFdBUlJBTlRJRVMgT1Ig
Q09ORElUSU9OUyBPRiBBTlkgS0lORCwgZWl0aGVyIGV4cHJlc3Mgb3IgaW1wbGllZC4KIFNl
ZSB0aGUgTGljZW5zZSBmb3IgdGhlIHNwZWNpZmljIGxhbmd1YWdlIGdvdmVybmluZyBwZXJt
aXNzaW9ucyBhbmQKIGxpbWl0YXRpb25zIHVuZGVyIHRoZSBMaWNlbnNlLgoKCAoBAhIDEAAs
CgkKAgMAEgMSACMKCAoBCBIDFABmCgkKAggLEgMUAGYKCAoBCBIDFQAiCgkKAggKEgMVACIK
CAoBCBIDFgBACgkKAggBEgMWAEAK4QEKAgQAEgQbADYBGtQBIFNlY3VyaXR5IENvbW1hbmQg
Q2VudGVyIGZpbmRpbmcgc291cmNlLiBBIGZpbmRpbmcgc291cmNlCiBpcyBhbiBlbnRpdHkg
b3IgYSBtZWNoYW5pc20gdGhhdCBjYW4gcHJvZHVjZSBhIGZpbmRpbmcuIEEgc291cmNlIGlz
IGxpa2UgYQogY29udGFpbmVyIG9mIGZpbmRpbmdzIHRoYXQgY29tZSBmcm9tIHRoZSBzYW1l
IHNjYW5uZXIsIGxvZ2dlciwgbW9uaXRvciwgZXRjLgoKCgoDBAABEgMbCA4KCwoDBAAHEgQc
Ah8ECg0KBQQAB50IEgQcAh8ECswBCgQEAAIAEgMlAhIavgEgVGhlIHJlbGF0aXZlIHJlc291
cmNlIG5hbWUgb2YgdGhpcyBzb3VyY2UuIFNlZToKIGh0dHBzOi8vY2xvdWQuZ29vZ2xlLmNv
bS9hcGlzL2Rlc2lnbi9yZXNvdXJjZV9uYW1lcyNyZWxhdGl2ZV9yZXNvdXJjZV9uYW1lCiBF
eGFtcGxlOgogIm9yZ2FuaXphdGlvbnMve29yZ2FuaXphdGlvbl9pZH0vc291cmNlcy97c291
cmNlX2lkfSIKCgwKBQQAAgAFEgMlAggKDAoFBAACAAESAyUJDQoMCgUEAAIAAxIDJRARCokC
CgQEAAIBEgMsAhoa+wEgVGhlIHNvdXJjZSdzIGRpc3BsYXkgbmFtZS4KIEEgc291cmNlJ3Mg
ZGlzcGxheSBuYW1lIG11c3QgYmUgdW5pcXVlIGFtb25nc3QgaXRzIHNpYmxpbmdzLCBmb3Ig
ZXhhbXBsZSwKIHR3byBzb3VyY2VzIHdpdGggdGhlIHNhbWUgcGFyZW50IGNhbid0IHNoYXJl
IHRoZSBzYW1lIGRpc3BsYXkgbmFtZS4KIFRoZSBkaXNwbGF5IG5hbWUgbXVzdCBoYXZlIGEg
bGVuZ3RoIGJldHdlZW4gMSBhbmQgNjQgY2hhcmFjdGVycwogKGluY2x1c2l2ZSkuCgoMCgUE
AAIBBRIDLAIICgwKBQQAAgEBEgMsCRUKDAoFBAACAQMSAywYGQr3AgoEBAACAhIDNQIZGukC
IFRoZSBkZXNjcmlwdGlvbiBvZiB0aGUgc291cmNlIChtYXggb2YgMTAyNCBjaGFyYWN0ZXJz
KS4KIEV4YW1wbGU6CiAiV2ViIFNlY3VyaXR5IFNjYW5uZXIgaXMgYSB3ZWIgc2VjdXJpdHkg
c2Nhbm5lciBmb3IgY29tbW9uCiB2dWxuZXJhYmlsaXRpZXMgaW4gQXBwIEVuZ2luZSBhcHBs
aWNhdGlvbnMuIEl0IGNhbiBhdXRvbWF0aWNhbGx5CiBzY2FuIGFuZCBkZXRlY3QgZm91ciBj
b21tb24gdnVsbmVyYWJpbGl0aWVzLCBpbmNsdWRpbmcgY3Jvc3Mtc2l0ZS1zY3JpcHRpbmcK
IChYU1MpLCBGbGFzaCBpbmplY3Rpb24sIG1peGVkIGNvbnRlbnQgKEhUVFAgaW4gSFRUUFMp
LCBhbmQKIG91dGRhdGVkL2luc2VjdXJlIGxpYnJhcmllcy4iCgoMCgUEAAICBRIDNQIICgwK
BQQAAgIBEgM1CRQKDAoFBAACAgMSAzUXGGIGcHJvdG8z
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Securitycenter::V1beta1::Source::Source ===
    # Fields for Source
    # Field: name Type: 9 ()
    # Field: display_name Type: 9 ()
    # Field: description Type: 9 ()

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Securitycenter::V1beta1::Source - Compiled Protocol Buffers messages for google/cloud/securitycenter/v1beta1/source.proto

=head1 SYNOPSIS

    use Google::Cloud::Securitycenter::V1beta1::Source;

    my $msg = Google::Cloud::Securitycenter::V1beta1::Source::Source->new({
        name => $name,
        display_name => $display_name,
        description => $description,
    });

    # Read or update a field
    my $val = $msg->name();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Securitycenter::V1beta1::Source::Source->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/securitycenter/v1beta1/source.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Securitycenter::V1beta1::Source::Source

Security Command Center finding source. A finding source
is an entity or a mechanism that can produce a finding. A source is like a
container of findings that come from the same scanner, logger, monitor, etc.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

The relative resource name of this source. See:
https://cloud.google.com/apis/design/resource_names#relative_resource_name
Example:
"organizations/{organization_id}/sources/{source_id}"

=item * C<< $msg->display_name() >> / C<< $msg->display_name($value) >>

Type: C<String>

The source's display name.
A source's display name must be unique amongst its siblings, for example,
two sources with the same parent can't share the same display name.
The display name must have a length between 1 and 64 characters
(inclusive).

=item * C<< $msg->description() >> / C<< $msg->description($value) >>

Type: C<String>

The description of the source (max of 1024 characters).
Example:
"Web Security Scanner is a web security scanner for common
vulnerabilities in App Engine applications. It can automatically
scan and detect four common vulnerabilities, including cross-site-scripting
(XSS), Flash injection, mixed content (HTTP in HTTPS), and
outdated/insecure libraries."

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Securitycenter::V1beta1::Source::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
