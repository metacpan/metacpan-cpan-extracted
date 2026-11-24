package Google::Cloud::Asset::V1::AssetEnrichmentResourceowners;

use strict;
use warnings;

our $VERSION = '0.14';

use Protobuf::Message;
use Protobuf::DescriptorPool;
use Protobuf::Internal qw(:all);
use MIME::Base64;

BEGIN {
    my $descriptor_b64 = <<'EOF';
Cjtnb29nbGUvY2xvdWQvYXNzZXQvdjEvYXNzZXRfZW5yaWNobWVudF9yZXNvdXJjZW93bmVy
cy5wcm90bxIVZ29vZ2xlLmNsb3VkLmFzc2V0LnYxIjkKDlJlc291cmNlT3duZXJzEicKD3Jl
c291cmNlX293bmVycxgBIAMoCVIOcmVzb3VyY2VPd25lcnNCogEKGWNvbS5nb29nbGUuY2xv
dWQuYXNzZXQudjFCIkFzc2V0RW5yaWNobWVudFJlc291cmNlb3duZXJzUHJvdG9QAVovY2xv
dWQuZ29vZ2xlLmNvbS9nby9hc3NldC9hcGl2MS9hc3NldHBiO2Fzc2V0cGKqAhVHb29nbGUu
Q2xvdWQuQXNzZXQuVjHKAhVHb29nbGVcQ2xvdWRcQXNzZXRcVjFK7AYKBhIEDgAdAQq8BAoB
DBIDDgASMrEEIENvcHlyaWdodCAyMDI1IEdvb2dsZSBMTEMKCiBMaWNlbnNlZCB1bmRlciB0
aGUgQXBhY2hlIExpY2Vuc2UsIFZlcnNpb24gMi4wICh0aGUgIkxpY2Vuc2UiKTsKIHlvdSBt
YXkgbm90IHVzZSB0aGlzIGZpbGUgZXhjZXB0IGluIGNvbXBsaWFuY2Ugd2l0aCB0aGUgTGlj
ZW5zZS4KIFlvdSBtYXkgb2J0YWluIGEgY29weSBvZiB0aGUgTGljZW5zZSBhdAoKICAgICBo
dHRwOi8vd3d3LmFwYWNoZS5vcmcvbGljZW5zZXMvTElDRU5TRS0yLjAKCiBVbmxlc3MgcmVx
dWlyZWQgYnkgYXBwbGljYWJsZSBsYXcgb3IgYWdyZWVkIHRvIGluIHdyaXRpbmcsIHNvZnR3
YXJlCiBkaXN0cmlidXRlZCB1bmRlciB0aGUgTGljZW5zZSBpcyBkaXN0cmlidXRlZCBvbiBh
biAiQVMgSVMiIEJBU0lTLAogV0lUSE9VVCBXQVJSQU5USUVTIE9SIENPTkRJVElPTlMgT0Yg
QU5ZIEtJTkQsIGVpdGhlciBleHByZXNzIG9yIGltcGxpZWQuCiBTZWUgdGhlIExpY2Vuc2Ug
Zm9yIHRoZSBzcGVjaWZpYyBsYW5ndWFnZSBnb3Zlcm5pbmcgcGVybWlzc2lvbnMgYW5kCiBs
aW1pdGF0aW9ucyB1bmRlciB0aGUgTGljZW5zZS4KCggKAQISAxAAHgoICgEIEgMSADIKCQoC
CCUSAxIAMgoICgEIEgMTAEYKCQoCCAsSAxMARgoICgEIEgMUACIKCQoCCAoSAxQAIgoICgEI
EgMVAEMKCQoCCAgSAxUAQwoICgEIEgMWADIKCQoCCAESAxYAMgoICgEIEgMXADIKCQoCCCkS
AxcAMgouCgIEABIEGgAdARoiIFRoZSByZXNvdXJjZSBvd25lcnMgaW5mb3JtYXRpb24uCgoK
CgMEAAESAxoIFgonCgQEAAIAEgMcAiYaGiBMaXN0IG9mIHJlc291cmNlIG93bmVycy4KCgwK
BQQAAgAEEgMcAgoKDAoFBAACAAUSAxwLEQoMCgUEAAIAARIDHBIhCgwKBQQAAgADEgMcJCVi
BnByb3RvMw==
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Asset::V1::AssetEnrichmentResourceowners::ResourceOwners ===
    # Fields for ResourceOwners
    # Field: resource_owners Type: 9 ()

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Asset::V1::AssetEnrichmentResourceowners - Compiled Protocol Buffers messages for google/cloud/asset/v1/asset_enrichment_resourceowners.proto

=head1 SYNOPSIS

    use Google::Cloud::Asset::V1::AssetEnrichmentResourceowners;

    my $msg = Google::Cloud::Asset::V1::AssetEnrichmentResourceowners::ResourceOwners->new({
        resource_owners => $resource_owners,
    });

    # Read or update a field
    my $val = $msg->resource_owners();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Asset::V1::AssetEnrichmentResourceowners::ResourceOwners->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/asset/v1/asset_enrichment_resourceowners.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Asset::V1::AssetEnrichmentResourceowners::ResourceOwners

The resource owners information.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->resource_owners() >> / C<< $msg->resource_owners($value) >>

Type: C<String>

List of resource owners.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Asset::V1::AssetEnrichmentResourceowners::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
