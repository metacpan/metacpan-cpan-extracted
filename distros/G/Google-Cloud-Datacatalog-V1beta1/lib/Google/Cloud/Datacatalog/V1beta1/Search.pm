package Google::Cloud::Datacatalog::V1beta1::Search;

use strict;
use warnings;

our $VERSION = '0.14';

use Protobuf::Message;
use Protobuf::DescriptorPool;
use Protobuf::Internal qw(:all);
use MIME::Base64;

BEGIN {
    eval { require Google::Api::FieldBehavior };
    eval { require Google::Protobuf::Timestamp };
    my $descriptor_b64 = <<'EOF';
Ci1nb29nbGUvY2xvdWQvZGF0YWNhdGFsb2cvdjFiZXRhMS9zZWFyY2gucHJvdG8SIGdvb2ds
ZS5jbG91ZC5kYXRhY2F0YWxvZy52MWJldGExGh9nb29nbGUvYXBpL2ZpZWxkX2JlaGF2aW9y
LnByb3RvGh9nb29nbGUvcHJvdG9idWYvdGltZXN0YW1wLnByb3RvIscCChNTZWFyY2hDYXRh
bG9nUmVzdWx0EmAKEnNlYXJjaF9yZXN1bHRfdHlwZRgBIAEoDjIyLmdvb2dsZS5jbG91ZC5k
YXRhY2F0YWxvZy52MWJldGExLlNlYXJjaFJlc3VsdFR5cGVSEHNlYXJjaFJlc3VsdFR5cGUS
MgoVc2VhcmNoX3Jlc3VsdF9zdWJ0eXBlGAIgASgJUhNzZWFyY2hSZXN1bHRTdWJ0eXBlEjQK
FnJlbGF0aXZlX3Jlc291cmNlX25hbWUYAyABKAlSFHJlbGF0aXZlUmVzb3VyY2VOYW1lEicK
D2xpbmtlZF9yZXNvdXJjZRgEIAEoCVIObGlua2VkUmVzb3VyY2USOwoLbW9kaWZ5X3RpbWUY
ByABKAsyGi5nb29nbGUucHJvdG9idWYuVGltZXN0YW1wUgptb2RpZnlUaW1lKmQKEFNlYXJj
aFJlc3VsdFR5cGUSIgoeU0VBUkNIX1JFU1VMVF9UWVBFX1VOU1BFQ0lGSUVEEAASCQoFRU5U
UlkQARIQCgxUQUdfVEVNUExBVEUQAhIPCgtFTlRSWV9HUk9VUBADQtwBCiRjb20uZ29vZ2xl
LmNsb3VkLmRhdGFjYXRhbG9nLnYxYmV0YTFQAVpGY2xvdWQuZ29vZ2xlLmNvbS9nby9kYXRh
Y2F0YWxvZy9hcGl2MWJldGExL2RhdGFjYXRhbG9ncGI7ZGF0YWNhdGFsb2dwYqoCIEdvb2ds
ZS5DbG91ZC5EYXRhQ2F0YWxvZy5WMUJldGExygIgR29vZ2xlXENsb3VkXERhdGFDYXRhbG9n
XFYxYmV0YTHqAiNHb29nbGU6OkNsb3VkOjpEYXRhQ2F0YWxvZzo6VjFiZXRhMUrtEwoGEgQO
AEgBCrwECgEMEgMOABIysQQgQ29weXJpZ2h0IDIwMjUgR29vZ2xlIExMQwoKIExpY2Vuc2Vk
IHVuZGVyIHRoZSBBcGFjaGUgTGljZW5zZSwgVmVyc2lvbiAyLjAgKHRoZSAiTGljZW5zZSIp
OwogeW91IG1heSBub3QgdXNlIHRoaXMgZmlsZSBleGNlcHQgaW4gY29tcGxpYW5jZSB3aXRo
IHRoZSBMaWNlbnNlLgogWW91IG1heSBvYnRhaW4gYSBjb3B5IG9mIHRoZSBMaWNlbnNlIGF0
CgogICAgIGh0dHA6Ly93d3cuYXBhY2hlLm9yZy9saWNlbnNlcy9MSUNFTlNFLTIuMAoKIFVu
bGVzcyByZXF1aXJlZCBieSBhcHBsaWNhYmxlIGxhdyBvciBhZ3JlZWQgdG8gaW4gd3JpdGlu
Zywgc29mdHdhcmUKIGRpc3RyaWJ1dGVkIHVuZGVyIHRoZSBMaWNlbnNlIGlzIGRpc3RyaWJ1
dGVkIG9uIGFuICJBUyBJUyIgQkFTSVMsCiBXSVRIT1VUIFdBUlJBTlRJRVMgT1IgQ09ORElU
SU9OUyBPRiBBTlkgS0lORCwgZWl0aGVyIGV4cHJlc3Mgb3IgaW1wbGllZC4KIFNlZSB0aGUg
TGljZW5zZSBmb3IgdGhlIHNwZWNpZmljIGxhbmd1YWdlIGdvdmVybmluZyBwZXJtaXNzaW9u
cyBhbmQKIGxpbWl0YXRpb25zIHVuZGVyIHRoZSBMaWNlbnNlLgoKCAoBAhIDEAApCgkKAgMA
EgMSACkKCQoCAwESAxMAKQoICgEIEgMVAD0KCQoCCCUSAxUAPQoICgEIEgMWAF0KCQoCCAsS
AxYAXQoICgEIEgMXACIKCQoCCAoSAxcAIgoICgEIEgMYAD0KCQoCCAESAxgAPQoICgEIEgMZ
AD0KCQoCCCkSAxkAPQoICgEIEgMaADwKCQoCCC0SAxoAPAqNAQoCBAASBB4AOQEagAEgQSBy
ZXN1bHQgdGhhdCBhcHBlYXJzIGluIHRoZSByZXNwb25zZSBvZiBhIHNlYXJjaCByZXF1ZXN0
LiBFYWNoIHJlc3VsdAogY2FwdHVyZXMgZGV0YWlscyBvZiBvbmUgZW50cnkgdGhhdCBtYXRj
aGVzIHRoZSBzZWFyY2guCgoKCgMEAAESAx4IGwqDAQoEBAACABIDIQIqGnYgVHlwZSBvZiB0
aGUgc2VhcmNoIHJlc3VsdC4gVGhpcyBmaWVsZCBjYW4gYmUgdXNlZCB0byBkZXRlcm1pbmUg
d2hpY2ggR2V0CiBtZXRob2QgdG8gY2FsbCB0byBmZXRjaCB0aGUgZnVsbCByZXNvdXJjZS4K
CgwKBQQAAgAGEgMhAhIKDAoFBAACAAESAyETJQoMCgUEAAIAAxIDISgpCv4BCgQEAAIBEgMn
AiMa8AEgU3ViLXR5cGUgb2YgdGhlIHNlYXJjaCByZXN1bHQuIFRoaXMgaXMgYSBkb3QtZGVs
aW1pdGVkIGRlc2NyaXB0aW9uIG9mIHRoZQogcmVzb3VyY2UncyBmdWxsIHR5cGUsIGFuZCBp
cyB0aGUgc2FtZSBhcyB0aGUgdmFsdWUgY2FsbGVycyB3b3VsZCBwcm92aWRlIGluCiB0aGUg
InR5cGUiIHNlYXJjaCBmYWNldC4gIEV4YW1wbGVzOiBgZW50cnkudGFibGVgLCBgZW50cnku
ZGF0YVN0cmVhbWAsCiBgdGFnVGVtcGxhdGVgLgoKDAoFBAACAQUSAycCCAoMCgUEAAIBARID
JwkeCgwKBQQAAgEDEgMnISIK9AEKBAQAAgISAy4CJBrmASBUaGUgcmVsYXRpdmUgcmVzb3Vy
Y2UgbmFtZSBvZiB0aGUgcmVzb3VyY2UgaW4gVVJMIGZvcm1hdC4KIEV4YW1wbGVzOgoKICAq
IGBwcm9qZWN0cy97cHJvamVjdF9pZH0vbG9jYXRpb25zL3tsb2NhdGlvbl9pZH0vZW50cnlH
cm91cHMve2VudHJ5X2dyb3VwX2lkfS9lbnRyaWVzL3tlbnRyeV9pZH1gCiAgKiBgcHJvamVj
dHMve3Byb2plY3RfaWR9L3RhZ1RlbXBsYXRlcy97dGFnX3RlbXBsYXRlX2lkfWAKCgwKBQQA
AgIFEgMuAggKDAoFBAACAgESAy4JHwoMCgUEAAICAxIDLiIjCvcBCgQEAAIDEgM1Ah0a6QEg
VGhlIGZ1bGwgbmFtZSBvZiB0aGUgY2xvdWQgcmVzb3VyY2UgdGhlIGVudHJ5IGJlbG9uZ3Mg
dG8uIFNlZToKIGh0dHBzOi8vY2xvdWQuZ29vZ2xlLmNvbS9hcGlzL2Rlc2lnbi9yZXNvdXJj
ZV9uYW1lcyNmdWxsX3Jlc291cmNlX25hbWUuCiBFeGFtcGxlOgoKICAqIGAvL2JpZ3F1ZXJ5
Lmdvb2dsZWFwaXMuY29tL3Byb2plY3RzL3Byb2plY3RJZC9kYXRhc2V0cy9kYXRhc2V0SWQv
dGFibGVzL3RhYmxlSWRgCgoMCgUEAAIDBRIDNQIICgwKBQQAAgMBEgM1CRgKDAoFBAACAwMS
AzUbHApNCgQEAAIEEgM4AiwaQCBMYXN0LW1vZGlmaWVkIHRpbWVzdGFtcCBvZiB0aGUgZW50
cnkgZnJvbSB0aGUgbWFuYWdpbmcgc3lzdGVtLgoKDAoFBAACBAYSAzgCGwoMCgUEAAIEARID
OBwnCgwKBQQAAgQDEgM4KisKTgoCBQASBDwASAEaQiBUaGUgZGlmZmVyZW50IHR5cGVzIG9m
IHJlc291cmNlcyB0aGF0IGNhbiBiZSByZXR1cm5lZCBpbiBzZWFyY2guCgoKCgMFAAESAzwF
FQokCgQFAAIAEgM+AiUaFyBEZWZhdWx0IHVua25vd24gdHlwZS4KCgwKBQUAAgABEgM+AiAK
DAoFBQACAAISAz4jJApCCgQFAAIBEgNBAgwaNSBBbiBbRW50cnldW2dvb2dsZS5jbG91ZC5k
YXRhY2F0YWxvZy52MWJldGExLkVudHJ5XS4KCgwKBQUAAgEBEgNBAgcKDAoFBQACAQISA0EK
CwpNCgQFAAICEgNEAhMaQCBBIFtUYWdUZW1wbGF0ZV1bZ29vZ2xlLmNsb3VkLmRhdGFjYXRh
bG9nLnYxYmV0YTEuVGFnVGVtcGxhdGVdLgoKDAoFBQACAgESA0QCDgoMCgUFAAICAhIDRBES
CkwKBAUAAgMSA0cCEho/IEFuIFtFbnRyeUdyb3VwXVtnb29nbGUuY2xvdWQuZGF0YWNhdGFs
b2cudjFiZXRhMS5FbnRyeUdyb3VwXS4KCgwKBQUAAgMBEgNHAg0KDAoFBQACAwISA0cQEWIG
cHJvdG8z
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Datacatalog::V1beta1::Search::SearchCatalogResult ===
    # Fields for SearchCatalogResult
    # Field: search_result_type Type: 14 (.google.cloud.datacatalog.v1beta1.SearchResultType)
    # Field: search_result_subtype Type: 9 ()
    # Field: relative_resource_name Type: 9 ()
    # Field: linked_resource Type: 9 ()
    # Field: modify_time Type: 11 (.google.protobuf.Timestamp)

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Datacatalog::V1beta1::Search - Compiled Protocol Buffers messages for google/cloud/datacatalog/v1beta1/search.proto

=head1 SYNOPSIS

    use Google::Cloud::Datacatalog::V1beta1::Search;

    my $msg = Google::Cloud::Datacatalog::V1beta1::Search::SearchCatalogResult->new({
        search_result_type => $search_result_type,
        search_result_subtype => $search_result_subtype,
        relative_resource_name => $relative_resource_name,
        linked_resource => $linked_resource,
    });

    # Read or update a field
    my $val = $msg->search_result_type();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Datacatalog::V1beta1::Search::SearchCatalogResult->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/datacatalog/v1beta1/search.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Datacatalog::V1beta1::Search::SearchCatalogResult

A result that appears in the response of a search request. Each result
captures details of one entry that matches the search.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->search_result_type() >> / C<< $msg->search_result_type($value) >>

Type: C<Enum> (L<Google::Cloud::Datacatalog::V1beta1::SearchResultType>)

Type of the search result. This field can be used to determine which Get
method to call to fetch the full resource.

=item * C<< $msg->search_result_subtype() >> / C<< $msg->search_result_subtype($value) >>

Type: C<String>

Sub-type of the search result. This is a dot-delimited description of the
resource's full type, and is the same as the value callers would provide in
the "type" search facet.  Examples: `entry.table`, `entry.dataStream`,
`tagTemplate`.

=item * C<< $msg->relative_resource_name() >> / C<< $msg->relative_resource_name($value) >>

Type: C<String>

The relative resource name of the resource in URL format.
Examples:

 * `projects/{project_id}/locations/{location_id}/entryGroups/{entry_group_id}/entries/{entry_id}`
 * `projects/{project_id}/tagTemplates/{tag_template_id}`

=item * C<< $msg->linked_resource() >> / C<< $msg->linked_resource($value) >>

Type: C<String>

The full name of the cloud resource the entry belongs to. See:
https://cloud.google.com/apis/design/resource_names#full_resource_name.
Example:

 * `//bigquery.googleapis.com/projects/projectId/datasets/datasetId/tables/tableId`

=item * C<< $msg->modify_time() >> / C<< $msg->modify_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Last-modified timestamp of the entry from the managing system.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Datacatalog::V1beta1::Search::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
