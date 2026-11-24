package Google::Cloud::Gkehub::Multiclusteringress::V1beta::Multiclusteringress;

use strict;
use warnings;

our $VERSION = '0.14';

use Protobuf::Message;
use Protobuf::DescriptorPool;
use Protobuf::Internal qw(:all);
use MIME::Base64;

BEGIN {
    my $descriptor_b64 = <<'EOF';
Ckhnb29nbGUvY2xvdWQvZ2tlaHViL3YxYmV0YS9tdWx0aWNsdXN0ZXJpbmdyZXNzL211bHRp
Y2x1c3RlcmluZ3Jlc3MucHJvdG8SLmdvb2dsZS5jbG91ZC5na2VodWIubXVsdGljbHVzdGVy
aW5ncmVzcy52MWJldGEijQEKC0ZlYXR1cmVTcGVjEisKEWNvbmZpZ19tZW1iZXJzaGlwGAEg
ASgJUhBjb25maWdNZW1iZXJzaGlwElEKB2JpbGxpbmcYAiABKA4yNy5nb29nbGUuY2xvdWQu
Z2tlaHViLm11bHRpY2x1c3RlcmluZ3Jlc3MudjFiZXRhLkJpbGxpbmdSB2JpbGxpbmcqSQoH
QmlsbGluZxIXChNCSUxMSU5HX1VOU1BFQ0lGSUVEEAASEQoNUEFZX0FTX1lPVV9HTxABEhIK
DkFOVEhPU19MSUNFTlNFEAJCzQIKMmNvbS5nb29nbGUuY2xvdWQuZ2tlaHViLm11bHRpY2x1
c3RlcmluZ3Jlc3MudjFiZXRhQhhNdWx0aUNsdXN0ZXJJbmdyZXNzUHJvdG9QAVpkY2xvdWQu
Z29vZ2xlLmNvbS9nby9na2VodWIvbXVsdGljbHVzdGVyaW5ncmVzcy9hcGl2MWJldGEvbXVs
dGljbHVzdGVyaW5ncmVzc3BiO211bHRpY2x1c3RlcmluZ3Jlc3NwYqoCLkdvb2dsZS5DbG91
ZC5Ha2VIdWIuTXVsdGlDbHVzdGVySW5ncmVzcy5WMUJldGHKAi5Hb29nbGVcQ2xvdWRcR2tl
SHViXE11bHRpQ2x1c3RlckluZ3Jlc3NcVjFiZXRh6gIyR29vZ2xlOjpDbG91ZDo6R2tlSHVi
OjpNdWx0aUNsdXN0ZXJJbmdyZXNzOjpWMWJldGFKmgsKBhIEDgAwAQq8BAoBDBIDDgASMrEE
IENvcHlyaWdodCAyMDI1IEdvb2dsZSBMTEMKCiBMaWNlbnNlZCB1bmRlciB0aGUgQXBhY2hl
IExpY2Vuc2UsIFZlcnNpb24gMi4wICh0aGUgIkxpY2Vuc2UiKTsKIHlvdSBtYXkgbm90IHVz
ZSB0aGlzIGZpbGUgZXhjZXB0IGluIGNvbXBsaWFuY2Ugd2l0aCB0aGUgTGljZW5zZS4KIFlv
dSBtYXkgb2J0YWluIGEgY29weSBvZiB0aGUgTGljZW5zZSBhdAoKICAgICBodHRwOi8vd3d3
LmFwYWNoZS5vcmcvbGljZW5zZXMvTElDRU5TRS0yLjAKCiBVbmxlc3MgcmVxdWlyZWQgYnkg
YXBwbGljYWJsZSBsYXcgb3IgYWdyZWVkIHRvIGluIHdyaXRpbmcsIHNvZnR3YXJlCiBkaXN0
cmlidXRlZCB1bmRlciB0aGUgTGljZW5zZSBpcyBkaXN0cmlidXRlZCBvbiBhbiAiQVMgSVMi
IEJBU0lTLAogV0lUSE9VVCBXQVJSQU5USUVTIE9SIENPTkRJVElPTlMgT0YgQU5ZIEtJTkQs
IGVpdGhlciBleHByZXNzIG9yIGltcGxpZWQuCiBTZWUgdGhlIExpY2Vuc2UgZm9yIHRoZSBz
cGVjaWZpYyBsYW5ndWFnZSBnb3Zlcm5pbmcgcGVybWlzc2lvbnMgYW5kCiBsaW1pdGF0aW9u
cyB1bmRlciB0aGUgTGljZW5zZS4KCggKAQISAxAANwoICgEIEgMTAEsKCQoCCCUSAxMASwoI
CgEIEgMUAHsKCQoCCAsSAxQAewoICgEIEgMVACIKCQoCCAoSAxUAIgoICgEIEgMWADkKCQoC
CAgSAxYAOQoICgEIEgMXAEsKCQoCCAESAxcASwoICgEIEgMYAEwKCQoCCCkSAxgATAoICgEI
EgMZAEsKCQoCCC0SAxkASwpPCgIFABIEHAAlARpDIEJpbGxpbmcgaWRlbnRpZmllcyB3aGlj
aCBiaWxsaW5nIHN0cnVjdHVyZSB0aGUgY3VzdG9tZXIgaXMgdXNpbmcuCgoKCgMFAAESAxwF
DAoWCgQFAAIAEgMeAhoaCSBVbmtub3duCgoMCgUFAAIAARIDHgIVCgwKBQUAAgACEgMeGBkK
LAoEBQACARIDIQIUGh8gVXNlciBwYXlzIGEgZmVlIHBlci1lbmRwb2ludC4KCgwKBQUAAgEB
EgMhAg8KDAoFBQACAQISAyESEwo0CgQFAAICEgMkAhUaJyBVc2VyIGlzIHBheWluZyBmb3Ig
QW50aG9zIGFzIGEgd2hvbGUuCgoMCgUFAAICARIDJAIQCgwKBQUAAgICEgMkExQKYAoCBAAS
BCkAMAEaVCAqKk11bHRpLWNsdXN0ZXIgSW5ncmVzcyoqOiBUaGUgY29uZmlndXJhdGlvbiBm
b3IgdGhlIE11bHRpQ2x1c3RlckluZ3Jlc3MKIGZlYXR1cmUuCgoKCgMEAAESAykIEwqXAQoE
BAACABIDLAIfGokBIEZ1bGx5LXF1YWxpZmllZCBNZW1iZXJzaGlwIG5hbWUgd2hpY2ggaG9z
dHMgdGhlIE11bHRpQ2x1c3RlckluZ3Jlc3MgQ1JELgogRXhhbXBsZTogYHByb2plY3RzL2Zv
by1wcm9qL2xvY2F0aW9ucy9nbG9iYWwvbWVtYmVyc2hpcHMvYmFyYAoKDAoFBAACAAUSAywC
CAoMCgUEAAIAARIDLAkaCgwKBQQAAgADEgMsHR4KKwoEBAACARIDLwIWGh4gQ3VzdG9tZXIn
cyBiaWxsaW5nIHN0cnVjdHVyZQoKDAoFBAACAQYSAy8CCQoMCgUEAAIBARIDLwoRCgwKBQQA
AgEDEgMvFBViBnByb3RvMw==
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Gkehub::Multiclusteringress::V1beta::Multiclusteringress::FeatureSpec ===
    # Fields for FeatureSpec
    # Field: config_membership Type: 9 ()
    # Field: billing Type: 14 (.google.cloud.gkehub.multiclusteringress.v1beta.Billing)

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Gkehub::Multiclusteringress::V1beta::Multiclusteringress - Compiled Protocol Buffers messages for google/cloud/gkehub/v1beta/multiclusteringress/multiclusteringress.proto

=head1 SYNOPSIS

    use Google::Cloud::Gkehub::Multiclusteringress::V1beta::Multiclusteringress;

    my $msg = Google::Cloud::Gkehub::Multiclusteringress::V1beta::Multiclusteringress::FeatureSpec->new({
        config_membership => $config_membership,
        billing => $billing,
    });

    # Read or update a field
    my $val = $msg->config_membership();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Gkehub::Multiclusteringress::V1beta::Multiclusteringress::FeatureSpec->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/gkehub/v1beta/multiclusteringress/multiclusteringress.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Gkehub::Multiclusteringress::V1beta::Multiclusteringress::FeatureSpec

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

Type: C<Enum> (L<Google::Cloud::Gkehub::Multiclusteringress::V1beta::Billing>)

Customer's billing structure

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Gkehub::Multiclusteringress::V1beta::Multiclusteringress::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
