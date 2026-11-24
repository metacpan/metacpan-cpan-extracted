package Google::Cloud::Gkehub::Multiclusteringress::V1alpha::Multiclusteringress;

use strict;
use warnings;

our $VERSION = '0.14';

use Protobuf::Message;
use Protobuf::DescriptorPool;
use Protobuf::Internal qw(:all);
use MIME::Base64;

BEGIN {
    my $descriptor_b64 = <<'EOF';
Cklnb29nbGUvY2xvdWQvZ2tlaHViL3YxYWxwaGEvbXVsdGljbHVzdGVyaW5ncmVzcy9tdWx0
aWNsdXN0ZXJpbmdyZXNzLnByb3RvEi9nb29nbGUuY2xvdWQuZ2tlaHViLm11bHRpY2x1c3Rl
cmluZ3Jlc3MudjFhbHBoYSKOAQoLRmVhdHVyZVNwZWMSKwoRY29uZmlnX21lbWJlcnNoaXAY
ASABKAlSEGNvbmZpZ01lbWJlcnNoaXASUgoHYmlsbGluZxgCIAEoDjI4Lmdvb2dsZS5jbG91
ZC5na2VodWIubXVsdGljbHVzdGVyaW5ncmVzcy52MWFscGhhLkJpbGxpbmdSB2JpbGxpbmcq
SQoHQmlsbGluZxIXChNCSUxMSU5HX1VOU1BFQ0lGSUVEEAASEQoNUEFZX0FTX1lPVV9HTxAB
EhIKDkFOVEhPU19MSUNFTlNFEAJC0gIKM2NvbS5nb29nbGUuY2xvdWQuZ2tlaHViLm11bHRp
Y2x1c3RlcmluZ3Jlc3MudjFhbHBoYUIYTXVsdGlDbHVzdGVySW5ncmVzc1Byb3RvUAFaZWNs
b3VkLmdvb2dsZS5jb20vZ28vZ2tlaHViL211bHRpY2x1c3RlcmluZ3Jlc3MvYXBpdjFhbHBo
YS9tdWx0aWNsdXN0ZXJpbmdyZXNzcGI7bXVsdGljbHVzdGVyaW5ncmVzc3BiqgIvR29vZ2xl
LkNsb3VkLkdrZUh1Yi5NdWx0aUNsdXN0ZXJJbmdyZXNzLlYxQWxwaGHKAi9Hb29nbGVcQ2xv
dWRcR2tlSHViXE11bHRpQ2x1c3RlckluZ3Jlc3NcVjFhbHBoYeoCM0dvb2dsZTo6Q2xvdWQ6
OkdrZUh1Yjo6TXVsdGlDbHVzdGVySW5ncmVzczo6VjFhbHBoYUqaCwoGEgQOADABCrwECgEM
EgMOABIysQQgQ29weXJpZ2h0IDIwMjUgR29vZ2xlIExMQwoKIExpY2Vuc2VkIHVuZGVyIHRo
ZSBBcGFjaGUgTGljZW5zZSwgVmVyc2lvbiAyLjAgKHRoZSAiTGljZW5zZSIpOwogeW91IG1h
eSBub3QgdXNlIHRoaXMgZmlsZSBleGNlcHQgaW4gY29tcGxpYW5jZSB3aXRoIHRoZSBMaWNl
bnNlLgogWW91IG1heSBvYnRhaW4gYSBjb3B5IG9mIHRoZSBMaWNlbnNlIGF0CgogICAgIGh0
dHA6Ly93d3cuYXBhY2hlLm9yZy9saWNlbnNlcy9MSUNFTlNFLTIuMAoKIFVubGVzcyByZXF1
aXJlZCBieSBhcHBsaWNhYmxlIGxhdyBvciBhZ3JlZWQgdG8gaW4gd3JpdGluZywgc29mdHdh
cmUKIGRpc3RyaWJ1dGVkIHVuZGVyIHRoZSBMaWNlbnNlIGlzIGRpc3RyaWJ1dGVkIG9uIGFu
ICJBUyBJUyIgQkFTSVMsCiBXSVRIT1VUIFdBUlJBTlRJRVMgT1IgQ09ORElUSU9OUyBPRiBB
TlkgS0lORCwgZWl0aGVyIGV4cHJlc3Mgb3IgaW1wbGllZC4KIFNlZSB0aGUgTGljZW5zZSBm
b3IgdGhlIHNwZWNpZmljIGxhbmd1YWdlIGdvdmVybmluZyBwZXJtaXNzaW9ucyBhbmQKIGxp
bWl0YXRpb25zIHVuZGVyIHRoZSBMaWNlbnNlLgoKCAoBAhIDEAA4CggKAQgSAxMATAoJCgII
JRIDEwBMCggKAQgSAxQAfAoJCgIICxIDFAB8CggKAQgSAxUAIgoJCgIIChIDFQAiCggKAQgS
AxYAOQoJCgIICBIDFgA5CggKAQgSAxcATAoJCgIIARIDFwBMCggKAQgSAxgATQoJCgIIKRID
GABNCggKAQgSAxkATAoJCgIILRIDGQBMCk8KAgUAEgQcACUBGkMgQmlsbGluZyBpZGVudGlm
aWVzIHdoaWNoIGJpbGxpbmcgc3RydWN0dXJlIHRoZSBjdXN0b21lciBpcyB1c2luZy4KCgoK
AwUAARIDHAUMChYKBAUAAgASAx4CGhoJIFVua25vd24KCgwKBQUAAgABEgMeAhUKDAoFBQAC
AAISAx4YGQosCgQFAAIBEgMhAhQaHyBVc2VyIHBheXMgYSBmZWUgcGVyLWVuZHBvaW50LgoK
DAoFBQACAQESAyECDwoMCgUFAAIBAhIDIRITCjQKBAUAAgISAyQCFRonIFVzZXIgaXMgcGF5
aW5nIGZvciBBbnRob3MgYXMgYSB3aG9sZS4KCgwKBQUAAgIBEgMkAhAKDAoFBQACAgISAyQT
FApgCgIEABIEKQAwARpUICoqTXVsdGktY2x1c3RlciBJbmdyZXNzKio6IFRoZSBjb25maWd1
cmF0aW9uIGZvciB0aGUgTXVsdGlDbHVzdGVySW5ncmVzcwogZmVhdHVyZS4KCgoKAwQAARID
KQgTCpcBCgQEAAIAEgMsAh8aiQEgRnVsbHktcXVhbGlmaWVkIE1lbWJlcnNoaXAgbmFtZSB3
aGljaCBob3N0cyB0aGUgTXVsdGlDbHVzdGVySW5ncmVzcyBDUkQuCiBFeGFtcGxlOiBgcHJv
amVjdHMvZm9vLXByb2ovbG9jYXRpb25zL2dsb2JhbC9tZW1iZXJzaGlwcy9iYXJgCgoMCgUE
AAIABRIDLAIICgwKBQQAAgABEgMsCRoKDAoFBAACAAMSAywdHgorCgQEAAIBEgMvAhYaHiBD
dXN0b21lcidzIGJpbGxpbmcgc3RydWN0dXJlCgoMCgUEAAIBBhIDLwIJCgwKBQQAAgEBEgMv
ChEKDAoFBAACAQMSAy8UFWIGcHJvdG8z
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Gkehub::Multiclusteringress::V1alpha::Multiclusteringress::FeatureSpec ===
    # Fields for FeatureSpec
    # Field: config_membership Type: 9 ()
    # Field: billing Type: 14 (.google.cloud.gkehub.multiclusteringress.v1alpha.Billing)

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Gkehub::Multiclusteringress::V1alpha::Multiclusteringress - Compiled Protocol Buffers messages for google/cloud/gkehub/v1alpha/multiclusteringress/multiclusteringress.proto

=head1 SYNOPSIS

    use Google::Cloud::Gkehub::Multiclusteringress::V1alpha::Multiclusteringress;

    my $msg = Google::Cloud::Gkehub::Multiclusteringress::V1alpha::Multiclusteringress::FeatureSpec->new({
        config_membership => $config_membership,
        billing => $billing,
    });

    # Read or update a field
    my $val = $msg->config_membership();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Gkehub::Multiclusteringress::V1alpha::Multiclusteringress::FeatureSpec->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/gkehub/v1alpha/multiclusteringress/multiclusteringress.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Gkehub::Multiclusteringress::V1alpha::Multiclusteringress::FeatureSpec

B<Multi-cluster Ingress>: The configuration for the MultiClusterIngress
feature.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->config_membership() >> / C<< $msg->config_membership($value) >>

Type: C<String>

Fully-qualified Membership name which hosts the MultiClusterIngress CRD.
Example: `projects/foo-proj/locations/global/memberships/bar`

=item * C<< $msg->billing() >> / C<< $msg->billing($value) >>

Type: C<Enum> (L<Google::Cloud::Gkehub::Multiclusteringress::V1alpha::Billing>)

Customer's billing structure

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Gkehub::Multiclusteringress::V1alpha::Multiclusteringress::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
