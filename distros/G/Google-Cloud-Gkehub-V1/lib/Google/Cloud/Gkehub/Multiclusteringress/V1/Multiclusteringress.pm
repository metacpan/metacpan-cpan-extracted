package Google::Cloud::Gkehub::Multiclusteringress::V1::Multiclusteringress;

use strict;
use warnings;

our $VERSION = '0.14';

use Protobuf::Message;
use Protobuf::DescriptorPool;
use Protobuf::Internal qw(:all);
use MIME::Base64;

BEGIN {
    my $descriptor_b64 = <<'EOF';
CkRnb29nbGUvY2xvdWQvZ2tlaHViL3YxL211bHRpY2x1c3RlcmluZ3Jlc3MvbXVsdGljbHVz
dGVyaW5ncmVzcy5wcm90bxIqZ29vZ2xlLmNsb3VkLmdrZWh1Yi5tdWx0aWNsdXN0ZXJpbmdy
ZXNzLnYxIjoKC0ZlYXR1cmVTcGVjEisKEWNvbmZpZ19tZW1iZXJzaGlwGAEgASgJUhBjb25m
aWdNZW1iZXJzaGlwQrkCCi5jb20uZ29vZ2xlLmNsb3VkLmdrZWh1Yi5tdWx0aWNsdXN0ZXJp
bmdyZXNzLnYxQhhNdWx0aUNsdXN0ZXJJbmdyZXNzUHJvdG9QAVpgY2xvdWQuZ29vZ2xlLmNv
bS9nby9na2VodWIvbXVsdGljbHVzdGVyaW5ncmVzcy9hcGl2MS9tdWx0aWNsdXN0ZXJpbmdy
ZXNzcGI7bXVsdGljbHVzdGVyaW5ncmVzc3BiqgIqR29vZ2xlLkNsb3VkLkdrZUh1Yi5NdWx0
aUNsdXN0ZXJJbmdyZXNzLlYxygIqR29vZ2xlXENsb3VkXEdrZUh1YlxNdWx0aUNsdXN0ZXJJ
bmdyZXNzXFYx6gIuR29vZ2xlOjpDbG91ZDo6R2tlSHViOjpNdWx0aUNsdXN0ZXJJbmdyZXNz
OjpWMUqWCAoGEgQOACABCrwECgEMEgMOABIysQQgQ29weXJpZ2h0IDIwMjUgR29vZ2xlIExM
QwoKIExpY2Vuc2VkIHVuZGVyIHRoZSBBcGFjaGUgTGljZW5zZSwgVmVyc2lvbiAyLjAgKHRo
ZSAiTGljZW5zZSIpOwogeW91IG1heSBub3QgdXNlIHRoaXMgZmlsZSBleGNlcHQgaW4gY29t
cGxpYW5jZSB3aXRoIHRoZSBMaWNlbnNlLgogWW91IG1heSBvYnRhaW4gYSBjb3B5IG9mIHRo
ZSBMaWNlbnNlIGF0CgogICAgIGh0dHA6Ly93d3cuYXBhY2hlLm9yZy9saWNlbnNlcy9MSUNF
TlNFLTIuMAoKIFVubGVzcyByZXF1aXJlZCBieSBhcHBsaWNhYmxlIGxhdyBvciBhZ3JlZWQg
dG8gaW4gd3JpdGluZywgc29mdHdhcmUKIGRpc3RyaWJ1dGVkIHVuZGVyIHRoZSBMaWNlbnNl
IGlzIGRpc3RyaWJ1dGVkIG9uIGFuICJBUyBJUyIgQkFTSVMsCiBXSVRIT1VUIFdBUlJBTlRJ
RVMgT1IgQ09ORElUSU9OUyBPRiBBTlkgS0lORCwgZWl0aGVyIGV4cHJlc3Mgb3IgaW1wbGll
ZC4KIFNlZSB0aGUgTGljZW5zZSBmb3IgdGhlIHNwZWNpZmljIGxhbmd1YWdlIGdvdmVybmlu
ZyBwZXJtaXNzaW9ucyBhbmQKIGxpbWl0YXRpb25zIHVuZGVyIHRoZSBMaWNlbnNlLgoKCAoB
AhIDEAAzCggKAQgSAxIARwoJCgIIJRIDEgBHCggKAQgSAxMAdwoJCgIICxIDEwB3CggKAQgS
AxQAIgoJCgIIChIDFAAiCggKAQgSAxUAOQoJCgIICBIDFQA5CggKAQgSAxYARwoJCgIIARID
FgBHCggKAQgSAxcASAoJCgIIKRIDFwBICggKAQgSAxgARwoJCgIILRIDGABHCmAKAgQAEgQc
ACABGlQgKipNdWx0aS1jbHVzdGVyIEluZ3Jlc3MqKjogVGhlIGNvbmZpZ3VyYXRpb24gZm9y
IHRoZSBNdWx0aUNsdXN0ZXJJbmdyZXNzCiBmZWF0dXJlLgoKCgoDBAABEgMcCBMKlwEKBAQA
AgASAx8CHxqJASBGdWxseS1xdWFsaWZpZWQgTWVtYmVyc2hpcCBuYW1lIHdoaWNoIGhvc3Rz
IHRoZSBNdWx0aUNsdXN0ZXJJbmdyZXNzIENSRC4KIEV4YW1wbGU6IGBwcm9qZWN0cy9mb28t
cHJvai9sb2NhdGlvbnMvZ2xvYmFsL21lbWJlcnNoaXBzL2JhcmAKCgwKBQQAAgAFEgMfAggK
DAoFBAACAAESAx8JGgoMCgUEAAIAAxIDHx0eYgZwcm90bzM=
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Gkehub::Multiclusteringress::V1::Multiclusteringress::FeatureSpec ===
    # Fields for FeatureSpec
    # Field: config_membership Type: 9 ()

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Gkehub::Multiclusteringress::V1::Multiclusteringress - Compiled Protocol Buffers messages for google/cloud/gkehub/v1/multiclusteringress/multiclusteringress.proto

=head1 SYNOPSIS

    use Google::Cloud::Gkehub::Multiclusteringress::V1::Multiclusteringress;

    my $msg = Google::Cloud::Gkehub::Multiclusteringress::V1::Multiclusteringress::FeatureSpec->new({
        config_membership => $config_membership,
    });

    # Read or update a field
    my $val = $msg->config_membership();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Gkehub::Multiclusteringress::V1::Multiclusteringress::FeatureSpec->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/gkehub/v1/multiclusteringress/multiclusteringress.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Gkehub::Multiclusteringress::V1::Multiclusteringress::FeatureSpec

B<Multi-cluster Ingress>: The configuration for the MultiClusterIngress
feature.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->config_membership() >> / C<< $msg->config_membership($value) >>

Type: C<String>

Fully-qualified Membership name which hosts the MultiClusterIngress CRD.
Example: `projects/foo-proj/locations/global/memberships/bar`

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Gkehub::Multiclusteringress::V1::Multiclusteringress::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
