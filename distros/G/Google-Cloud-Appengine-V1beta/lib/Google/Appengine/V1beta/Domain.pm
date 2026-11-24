package Google::Appengine::V1beta::Domain;

use strict;
use warnings;

our $VERSION = '0.14';

use Protobuf::Message;
use Protobuf::DescriptorPool;
use Protobuf::Internal qw(:all);
use MIME::Base64;

BEGIN {
    my $descriptor_b64 = <<'EOF';
CiRnb29nbGUvYXBwZW5naW5lL3YxYmV0YS9kb21haW4ucHJvdG8SF2dvb2dsZS5hcHBlbmdp
bmUudjFiZXRhIjYKEEF1dGhvcml6ZWREb21haW4SEgoEbmFtZRgBIAEoCVIEbmFtZRIOCgJp
ZBgCIAEoCVICaWRC0QEKG2NvbS5nb29nbGUuYXBwZW5naW5lLnYxYmV0YUILRG9tYWluUHJv
dG9QAVpAZ29vZ2xlLmdvbGFuZy5vcmcvZ2VucHJvdG8vZ29vZ2xlYXBpcy9hcHBlbmdpbmUv
djFiZXRhO2FwcGVuZ2luZaoCHUdvb2dsZS5DbG91ZC5BcHBFbmdpbmUuVjFCZXRhygIdR29v
Z2xlXENsb3VkXEFwcEVuZ2luZVxWMWJldGHqAiBHb29nbGU6OkNsb3VkOjpBcHBFbmdpbmU6
OlYxYmV0YUr7CQoGEgQOACcBCrwECgEMEgMOABIysQQgQ29weXJpZ2h0IDIwMjUgR29vZ2xl
IExMQwoKIExpY2Vuc2VkIHVuZGVyIHRoZSBBcGFjaGUgTGljZW5zZSwgVmVyc2lvbiAyLjAg
KHRoZSAiTGljZW5zZSIpOwogeW91IG1heSBub3QgdXNlIHRoaXMgZmlsZSBleGNlcHQgaW4g
Y29tcGxpYW5jZSB3aXRoIHRoZSBMaWNlbnNlLgogWW91IG1heSBvYnRhaW4gYSBjb3B5IG9m
IHRoZSBMaWNlbnNlIGF0CgogICAgIGh0dHA6Ly93d3cuYXBhY2hlLm9yZy9saWNlbnNlcy9M
SUNFTlNFLTIuMAoKIFVubGVzcyByZXF1aXJlZCBieSBhcHBsaWNhYmxlIGxhdyBvciBhZ3Jl
ZWQgdG8gaW4gd3JpdGluZywgc29mdHdhcmUKIGRpc3RyaWJ1dGVkIHVuZGVyIHRoZSBMaWNl
bnNlIGlzIGRpc3RyaWJ1dGVkIG9uIGFuICJBUyBJUyIgQkFTSVMsCiBXSVRIT1VUIFdBUlJB
TlRJRVMgT1IgQ09ORElUSU9OUyBPRiBBTlkgS0lORCwgZWl0aGVyIGV4cHJlc3Mgb3IgaW1w
bGllZC4KIFNlZSB0aGUgTGljZW5zZSBmb3IgdGhlIHNwZWNpZmljIGxhbmd1YWdlIGdvdmVy
bmluZyBwZXJtaXNzaW9ucyBhbmQKIGxpbWl0YXRpb25zIHVuZGVyIHRoZSBMaWNlbnNlLgoK
CAoBAhIDEAAgCggKAQgSAxIAOgoJCgIIJRIDEgA6CggKAQgSAxMAVwoJCgIICxIDEwBXCggK
AQgSAxQAIgoJCgIIChIDFAAiCggKAQgSAxUALAoJCgIICBIDFQAsCggKAQgSAxYANAoJCgII
ARIDFgA0CggKAQgSAxcAOgoJCgIIKRIDFwA6CggKAQgSAxgAOQoJCgIILRIDGAA5Cr8BCgIE
ABIEHQAnARqyASBBIGRvbWFpbiB0aGF0IGEgdXNlciBoYXMgYmVlbiBhdXRob3JpemVkIHRv
IGFkbWluaXN0ZXIuIFRvIGF1dGhvcml6ZSB1c2UKIG9mIGEgZG9tYWluLCB2ZXJpZnkgb3du
ZXJzaGlwIHZpYQogW1NlYXJjaCBDb25zb2xlXShodHRwczovL3NlYXJjaC5nb29nbGUuY29t
L3NlYXJjaC1jb25zb2xlL3dlbGNvbWUpLgoKCgoDBAABEgMdCBgKiwEKBAQAAgASAyICEhp+
IEZ1bGwgcGF0aCB0byB0aGUgYEF1dGhvcml6ZWREb21haW5gIHJlc291cmNlIGluIHRoZSBB
UEkuIEV4YW1wbGU6CiBgYXBwcy9teWFwcC9hdXRob3JpemVkRG9tYWlucy9leGFtcGxlLmNv
bWAuCgogQE91dHB1dE9ubHkKCgwKBQQAAgAFEgMiAggKDAoFBAACAAESAyIJDQoMCgUEAAIA
AxIDIhARCmUKBAQAAgESAyYCEBpYIEZ1bGx5IHF1YWxpZmllZCBkb21haW4gbmFtZSBvZiB0
aGUgZG9tYWluIGF1dGhvcml6ZWQgZm9yIHVzZS4gRXhhbXBsZToKIGBleGFtcGxlLmNvbWAu
CgoMCgUEAAIBBRIDJgIICgwKBQQAAgEBEgMmCQsKDAoFBAACAQMSAyYOD2IGcHJvdG8z
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Appengine::V1beta::Domain::AuthorizedDomain ===
    # Fields for AuthorizedDomain
    # Field: name Type: 9 ()
    # Field: id Type: 9 ()

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Appengine::V1beta::Domain - Compiled Protocol Buffers messages for google/appengine/v1beta/domain.proto

=head1 SYNOPSIS

    use Google::Appengine::V1beta::Domain;

    my $msg = Google::Appengine::V1beta::Domain::AuthorizedDomain->new({
        name => $name,
        id => $id,
    });

    # Read or update a field
    my $val = $msg->name();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Appengine::V1beta::Domain::AuthorizedDomain->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/appengine/v1beta/domain.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Appengine::V1beta::Domain::AuthorizedDomain

A domain that a user has been authorized to administer. To authorize use
of a domain, verify ownership via
[Search Console](https://search.google.com/search-console/welcome).

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Full path to the `AuthorizedDomain` resource in the API. Example:
`apps/myapp/authorizedDomains/example.com`.

@OutputOnly

=item * C<< $msg->id() >> / C<< $msg->id($value) >>

Type: C<String>

Fully qualified domain name of the domain authorized for use. Example:
`example.com`.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Appengine::V1beta::Domain::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
