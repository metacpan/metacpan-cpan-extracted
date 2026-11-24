package Google::Cloud::Bigquery::V2::PropertyGraphReference;

use strict;
use warnings;

our $VERSION = '0.14';

use Protobuf::Message;
use Protobuf::DescriptorPool;
use Protobuf::Internal qw(:all);
use MIME::Base64;

BEGIN {
    eval { require Google::Api::FieldBehavior };
    my $descriptor_b64 = <<'EOF';
Cjdnb29nbGUvY2xvdWQvYmlncXVlcnkvdjIvcHJvcGVydHlfZ3JhcGhfcmVmZXJlbmNlLnBy
b3RvEhhnb29nbGUuY2xvdWQuYmlncXVlcnkudjIaH2dvb2dsZS9hcGkvZmllbGRfYmVoYXZp
b3IucHJvdG8ikQEKFlByb3BlcnR5R3JhcGhSZWZlcmVuY2USIgoKcHJvamVjdF9pZBgBIAEo
CUID4EECUglwcm9qZWN0SWQSIgoKZGF0YXNldF9pZBgCIAEoCUID4EECUglkYXRhc2V0SWQS
LwoRcHJvcGVydHlfZ3JhcGhfaWQYAyABKAlCA+BBAlIPcHJvcGVydHlHcmFwaElkQnoKHGNv
bS5nb29nbGUuY2xvdWQuYmlncXVlcnkudjJCG1Byb3BlcnR5R3JhcGhSZWZlcmVuY2VQcm90
b1ABWjtjbG91ZC5nb29nbGUuY29tL2dvL2JpZ3F1ZXJ5L3YyL2FwaXYyL2JpZ3F1ZXJ5cGI7
YmlncXVlcnlwYkqVCgoGEgQOACUBCrwECgEMEgMOABIysQQgQ29weXJpZ2h0IDIwMjYgR29v
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
LgoKCAoBAhIDEAAhCgkKAgMAEgMSACkKCAoBCBIDFABSCgkKAggLEgMUAFIKCAoBCBIDFQAi
CgkKAggKEgMVACIKCAoBCBIDFgA8CgkKAggIEgMWADwKCAoBCBIDFwA1CgkKAggBEgMXADUK
KgoCBAASBBoAJQEaHiBJZCBwYXRoIG9mIGEgcHJvcGVydHkgZ3JhcGguCgoKCgMEAAESAxoI
HgpOCgQEAAIAEgMcAkEaQSBSZXF1aXJlZC4gVGhlIElEIG9mIHRoZSBwcm9qZWN0IGNvbnRh
aW5pbmcgdGhpcyBwcm9wZXJ0eSBncmFwaC4KCgwKBQQAAgAFEgMcAggKDAoFBAACAAESAxwJ
EwoMCgUEAAIAAxIDHBYXCgwKBQQAAgAIEgMcGEAKDwoIBAACAAicCAASAxwZPwpOCgQEAAIB
EgMfAkEaQSBSZXF1aXJlZC4gVGhlIElEIG9mIHRoZSBkYXRhc2V0IGNvbnRhaW5pbmcgdGhp
cyBwcm9wZXJ0eSBncmFwaC4KCgwKBQQAAgEFEgMfAggKDAoFBAACAQESAx8JEwoMCgUEAAIB
AxIDHxYXCgwKBQQAAgEIEgMfGEAKDwoIBAACAQicCAASAx8ZPwqvAQoEBAACAhIDJAJIGqEB
IFJlcXVpcmVkLiBUaGUgSUQgb2YgdGhlIHByb3BlcnR5IGdyYXBoLiBUaGUgSUQgbXVzdCBj
b250YWluIG9ubHkKIGxldHRlcnMgKGEteiwgQS1aKSwgbnVtYmVycyAoMC05KSwgb3IgdW5k
ZXJzY29yZXMgKF8pLiBUaGUgbWF4aW11bQogbGVuZ3RoIGlzIDI1NiBjaGFyYWN0ZXJzLgoK
DAoFBAACAgUSAyQCCAoMCgUEAAICARIDJAkaCgwKBQQAAgIDEgMkHR4KDAoFBAACAggSAyQf
RwoPCggEAAICCJwIABIDJCBGYgZwcm90bzM=
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Bigquery::V2::PropertyGraphReference::PropertyGraphReference ===
    # Fields for PropertyGraphReference
    # Field: project_id Type: 9 ()
    # Field: dataset_id Type: 9 ()
    # Field: property_graph_id Type: 9 ()

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Bigquery::V2::PropertyGraphReference - Compiled Protocol Buffers messages for google/cloud/bigquery/v2/property_graph_reference.proto

=head1 SYNOPSIS

    use Google::Cloud::Bigquery::V2::PropertyGraphReference;

    my $msg = Google::Cloud::Bigquery::V2::PropertyGraphReference::PropertyGraphReference->new({
        project_id => $project_id,
        dataset_id => $dataset_id,
        property_graph_id => $property_graph_id,
    });

    # Read or update a field
    my $val = $msg->project_id();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Bigquery::V2::PropertyGraphReference::PropertyGraphReference->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/bigquery/v2/property_graph_reference.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Bigquery::V2::PropertyGraphReference::PropertyGraphReference

Id path of a property graph.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->project_id() >> / C<< $msg->project_id($value) >>

Type: C<String>

Required. The ID of the project containing this property graph.

=item * C<< $msg->dataset_id() >> / C<< $msg->dataset_id($value) >>

Type: C<String>

Required. The ID of the dataset containing this property graph.

=item * C<< $msg->property_graph_id() >> / C<< $msg->property_graph_id($value) >>

Type: C<String>

Required. The ID of the property graph. The ID must contain only
letters (a-z, A-Z), numbers (0-9), or underscores (_). The maximum
length is 256 characters.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Bigquery::V2::PropertyGraphReference::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
