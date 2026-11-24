package Google::Cloud::Datacatalog::V1::Search;

use strict;
use warnings;

our $VERSION = '0.14';

use Protobuf::Message;
use Protobuf::DescriptorPool;
use Protobuf::Internal qw(:all);
use MIME::Base64;

BEGIN {
    eval { require Google::Api::FieldBehavior };
    eval { require Google::Cloud::Datacatalog::V1::Common };
    eval { require Google::Protobuf::Timestamp };
    my $descriptor_b64 = <<'EOF';
Cihnb29nbGUvY2xvdWQvZGF0YWNhdGFsb2cvdjEvc2VhcmNoLnByb3RvEhtnb29nbGUuY2xv
dWQuZGF0YWNhdGFsb2cudjEaH2dvb2dsZS9hcGkvZmllbGRfYmVoYXZpb3IucHJvdG8aKGdv
b2dsZS9jbG91ZC9kYXRhY2F0YWxvZy92MS9jb21tb24ucHJvdG8aH2dvb2dsZS9wcm90b2J1
Zi90aW1lc3RhbXAucHJvdG8i3AQKE1NlYXJjaENhdGFsb2dSZXN1bHQSWwoSc2VhcmNoX3Jl
c3VsdF90eXBlGAEgASgOMi0uZ29vZ2xlLmNsb3VkLmRhdGFjYXRhbG9nLnYxLlNlYXJjaFJl
c3VsdFR5cGVSEHNlYXJjaFJlc3VsdFR5cGUSMgoVc2VhcmNoX3Jlc3VsdF9zdWJ0eXBlGAIg
ASgJUhNzZWFyY2hSZXN1bHRTdWJ0eXBlEjQKFnJlbGF0aXZlX3Jlc291cmNlX25hbWUYAyAB
KAlSFHJlbGF0aXZlUmVzb3VyY2VOYW1lEicKD2xpbmtlZF9yZXNvdXJjZRgEIAEoCVIObGlu
a2VkUmVzb3VyY2USOwoLbW9kaWZ5X3RpbWUYByABKAsyGi5nb29nbGUucHJvdG9idWYuVGlt
ZXN0YW1wUgptb2RpZnlUaW1lEmEKEWludGVncmF0ZWRfc3lzdGVtGAggASgOMi0uZ29vZ2xl
LmNsb3VkLmRhdGFjYXRhbG9nLnYxLkludGVncmF0ZWRTeXN0ZW1CA+BBA0gAUhBpbnRlZ3Jh
dGVkU3lzdGVtEjQKFXVzZXJfc3BlY2lmaWVkX3N5c3RlbRgJIAEoCUgAUhN1c2VyU3BlY2lm
aWVkU3lzdGVtEjAKFGZ1bGx5X3F1YWxpZmllZF9uYW1lGAogASgJUhJmdWxseVF1YWxpZmll
ZE5hbWUSIQoMZGlzcGxheV9uYW1lGAwgASgJUgtkaXNwbGF5TmFtZRIgCgtkZXNjcmlwdGlv
bhgNIAEoCVILZGVzY3JpcHRpb25CCAoGc3lzdGVtKmQKEFNlYXJjaFJlc3VsdFR5cGUSIgoe
U0VBUkNIX1JFU1VMVF9UWVBFX1VOU1BFQ0lGSUVEEAASCQoFRU5UUlkQARIQCgxUQUdfVEVN
UExBVEUQAhIPCgtFTlRSWV9HUk9VUBADQsMBCh9jb20uZ29vZ2xlLmNsb3VkLmRhdGFjYXRh
bG9nLnYxUAFaQWNsb3VkLmdvb2dsZS5jb20vZ28vZGF0YWNhdGFsb2cvYXBpdjEvZGF0YWNh
dGFsb2dwYjtkYXRhY2F0YWxvZ3BiqgIbR29vZ2xlLkNsb3VkLkRhdGFDYXRhbG9nLlYxygIb
R29vZ2xlXENsb3VkXERhdGFDYXRhbG9nXFYx6gIeR29vZ2xlOjpDbG91ZDo6RGF0YUNhdGFs
b2c6OlYxStscCgYSBA4AdgEKvAQKAQwSAw4AEjKxBCBDb3B5cmlnaHQgMjAyNSBHb29nbGUg
TExDCgogTGljZW5zZWQgdW5kZXIgdGhlIEFwYWNoZSBMaWNlbnNlLCBWZXJzaW9uIDIuMCAo
dGhlICJMaWNlbnNlIik7CiB5b3UgbWF5IG5vdCB1c2UgdGhpcyBmaWxlIGV4Y2VwdCBpbiBj
b21wbGlhbmNlIHdpdGggdGhlIExpY2Vuc2UuCiBZb3UgbWF5IG9idGFpbiBhIGNvcHkgb2Yg
dGhlIExpY2Vuc2UgYXQKCiAgICAgaHR0cDovL3d3dy5hcGFjaGUub3JnL2xpY2Vuc2VzL0xJ
Q0VOU0UtMi4wCgogVW5sZXNzIHJlcXVpcmVkIGJ5IGFwcGxpY2FibGUgbGF3IG9yIGFncmVl
ZCB0byBpbiB3cml0aW5nLCBzb2Z0d2FyZQogZGlzdHJpYnV0ZWQgdW5kZXIgdGhlIExpY2Vu
c2UgaXMgZGlzdHJpYnV0ZWQgb24gYW4gIkFTIElTIiBCQVNJUywKIFdJVEhPVVQgV0FSUkFO
VElFUyBPUiBDT05ESVRJT05TIE9GIEFOWSBLSU5ELCBlaXRoZXIgZXhwcmVzcyBvciBpbXBs
aWVkLgogU2VlIHRoZSBMaWNlbnNlIGZvciB0aGUgc3BlY2lmaWMgbGFuZ3VhZ2UgZ292ZXJu
aW5nIHBlcm1pc3Npb25zIGFuZAogbGltaXRhdGlvbnMgdW5kZXIgdGhlIExpY2Vuc2UuCgoI
CgECEgMQACQKCQoCAwASAxIAKQoJCgIDARIDEwAyCgkKAgMCEgMUACkKCAoBCBIDFgA4CgkK
AgglEgMWADgKCAoBCBIDFwBYCgkKAggLEgMXAFgKCAoBCBIDGAAiCgkKAggKEgMYACIKCAoB
CBIDGQA4CgkKAggBEgMZADgKCAoBCBIDGgA4CgkKAggpEgMaADgKCAoBCBIDGwA3CgkKAggt
EgMbADcKfgoCBAASBCAAZwEaciBSZXN1bHQgaW4gdGhlIHJlc3BvbnNlIHRvIGEgc2VhcmNo
IHJlcXVlc3QuCgogRWFjaCByZXN1bHQgY2FwdHVyZXMgZGV0YWlscyBvZiBvbmUgZW50cnkg
dGhhdCBtYXRjaGVzIHRoZSBzZWFyY2guCgoKCgMEAAESAyAIGwqFAQoEBAACABIDJQIqGngg
VHlwZSBvZiB0aGUgc2VhcmNoIHJlc3VsdC4KCiBZb3UgY2FuIHVzZSB0aGlzIGZpZWxkIHRv
IGRldGVybWluZSB3aGljaCBnZXQgbWV0aG9kIHRvIGNhbGwgdG8gZmV0Y2ggdGhlCiBmdWxs
IHJlc291cmNlLgoKDAoFBAACAAYSAyUCEgoMCgUEAAIAARIDJRMlCgwKBQQAAgADEgMlKCkK
1AEKBAQAAgESAy0CIxrGASBTdWItdHlwZSBvZiB0aGUgc2VhcmNoIHJlc3VsdC4KCiBBIGRv
dC1kZWxpbWl0ZWQgZnVsbCB0eXBlIG9mIHRoZSByZXNvdXJjZS4gVGhlIHNhbWUgdHlwZSB5
b3UKIHNwZWNpZnkgaW4gdGhlIGB0eXBlYCBzZWFyY2ggcHJlZGljYXRlLgoKIEV4YW1wbGVz
OiBgZW50cnkudGFibGVgLCBgZW50cnkuZGF0YVN0cmVhbWAsIGB0YWdUZW1wbGF0ZWAuCgoM
CgUEAAIBBRIDLQIICgwKBQQAAgEBEgMtCR4KDAoFBAACAQMSAy0hIgrsAQoEBAACAhIDNQIk
Gt4BIFRoZSByZWxhdGl2ZSBuYW1lIG9mIHRoZSByZXNvdXJjZSBpbiBVUkwgZm9ybWF0LgoK
IEV4YW1wbGVzOgoKICAqIGBwcm9qZWN0cy97UFJPSkVDVF9JRH0vbG9jYXRpb25zL3tMT0NB
VElPTl9JRH0vZW50cnlHcm91cHMve0VOVFJZX0dST1VQX0lEfS9lbnRyaWVzL3tFTlRSWV9J
RH1gCiAgKiBgcHJvamVjdHMve1BST0pFQ1RfSUR9L3RhZ1RlbXBsYXRlcy97VEFHX1RFTVBM
QVRFX0lEfWAKCgwKBQQAAgIFEgM1AggKDAoFBAACAgESAzUJHwoMCgUEAAICAxIDNSIjCpUC
CgQEAAIDEgM/Ah0ahwIgVGhlIGZ1bGwgbmFtZSBvZiB0aGUgR29vZ2xlIENsb3VkIHJlc291
cmNlIHRoZSBlbnRyeSBiZWxvbmdzIHRvLgoKIEZvciBtb3JlIGluZm9ybWF0aW9uLCBzZWUg
W0Z1bGwgUmVzb3VyY2UgTmFtZV0KICgvYXBpcy9kZXNpZ24vcmVzb3VyY2VfbmFtZXMjZnVs
bF9yZXNvdXJjZV9uYW1lKS4KCiBFeGFtcGxlOgoKIGAvL2JpZ3F1ZXJ5Lmdvb2dsZWFwaXMu
Y29tL3Byb2plY3RzL1BST0pFQ1RfSUQvZGF0YXNldHMvREFUQVNFVF9JRC90YWJsZXMvVEFC
TEVfSURgCgoMCgUEAAIDBRIDPwIICgwKBQQAAgMBEgM/CRgKDAoFBAACAwMSAz8bHApRCgQE
AAIEEgNCAiwaRCBUaGUgbGFzdCBtb2RpZmljYXRpb24gdGltZXN0YW1wIG9mIHRoZSBlbnRy
eSBpbiB0aGUgc291cmNlIHN5c3RlbS4KCgwKBQQAAgQGEgNCAhsKDAoFBAACBAESA0IcJwoM
CgUEAAIEAxIDQiorCmoKBAQACAASBEYCTgMaXCBUaGUgc291cmNlIHN5c3RlbSBvZiB0aGUg
ZW50cnkuIEFwcGxpY2FibGUgb25seSB3aGVuIHRoZQogYHNlYXJjaF9yZXN1bHRfdHlwZWAg
aXMgYEVOVFJZYC4KCgwKBQQACAABEgNGCA4KmQEKBAQAAgUSBEkESjQaigEgT3V0cHV0IG9u
bHkuIFRoZSBzb3VyY2Ugc3lzdGVtIHRoYXQgRGF0YSBDYXRhbG9nIGF1dG9tYXRpY2FsbHkg
aW50ZWdyYXRlcwogd2l0aCwgc3VjaCBhcyBCaWdRdWVyeSwgQ2xvdWQgUHViL1N1Yiwgb3Ig
RGF0YXByb2MgTWV0YXN0b3JlLgoKDAoFBAACBQYSA0kEFAoMCgUEAAIFARIDSRUmCgwKBQQA
AgUDEgNJKSoKDAoFBAACBQgSA0oIMwoPCggEAAIFCJwIABIDSgkyClYKBAQAAgYSA00EJRpJ
IEN1c3RvbSBzb3VyY2Ugc3lzdGVtIHRoYXQgeW91IGNhbiBtYW51YWxseSBpbnRlZ3JhdGUg
RGF0YSBDYXRhbG9nIHdpdGguCgoMCgUEAAIGBRIDTQQKCgwKBQQAAgYBEgNNCyAKDAoFBAAC
BgMSA00jJAqPAwoEBAACBxIDXwIjGoEDIEZ1bGx5IHF1YWxpZmllZCBuYW1lIChGUU4pIG9m
IHRoZSByZXNvdXJjZS4KCiBGUU5zIHRha2UgdHdvIGZvcm1zOgoKICogRm9yIG5vbi1yZWdp
b25hbGl6ZWQgcmVzb3VyY2VzOgoKICAgYHtTWVNURU19OntQUk9KRUNUfS57UEFUSF9UT19S
RVNPVVJDRV9TRVBBUkFURURfV0lUSF9ET1RTfWAKCiAqIEZvciByZWdpb25hbGl6ZWQgcmVz
b3VyY2VzOgoKICAgYHtTWVNURU19OntQUk9KRUNUfS57TE9DQVRJT05fSUR9LntQQVRIX1RP
X1JFU09VUkNFX1NFUEFSQVRFRF9XSVRIX0RPVFN9YAoKIEV4YW1wbGUgZm9yIGEgRFBNUyB0
YWJsZToKCiBgZGF0YXByb2NfbWV0YXN0b3JlOlBST0pFQ1RfSUQuTE9DQVRJT05fSUQuSU5T
VEFOQ0VfSUQuREFUQUJBU0VfSUQuVEFCTEVfSURgCgoMCgUEAAIHBRIDXwIICgwKBQQAAgcB
EgNfCR0KDAoFBAACBwMSA18gIgouCgQEAAIIEgNiAhsaISBUaGUgZGlzcGxheSBuYW1lIG9m
IHRoZSByZXN1bHQuCgoMCgUEAAIIBRIDYgIICgwKBQQAAggBEgNiCRUKDAoFBAACCAMSA2IY
GgpzCgQEAAIJEgNmAhoaZiBFbnRyeSBkZXNjcmlwdGlvbiB0aGF0IGNhbiBjb25zaXN0IG9m
IHNldmVyYWwgc2VudGVuY2VzIG9yIHBhcmFncmFwaHMgdGhhdAogZGVzY3JpYmUgZW50cnkg
Y29udGVudHMuCgoMCgUEAAIJBRIDZgIICgwKBQQAAgkBEgNmCRQKDAoFBAACCQMSA2YXGQpI
CgIFABIEagB2ARo8IFRoZSByZXNvdXJjZSB0eXBlcyB0aGF0IGNhbiBiZSByZXR1cm5lZCBp
biBzZWFyY2ggcmVzdWx0cy4KCgoKAwUAARIDagUVCiQKBAUAAgASA2wCJRoXIERlZmF1bHQg
dW5rbm93biB0eXBlLgoKDAoFBQACAAESA2wCIAoMCgUFAAIAAhIDbCMkCj0KBAUAAgESA28C
DBowIEFuIFtFbnRyeV1bZ29vZ2xlLmNsb3VkLmRhdGFjYXRhbG9nLnYxLkVudHJ5XS4KCgwK
BQUAAgEBEgNvAgcKDAoFBQACAQISA28KCwpICgQFAAICEgNyAhMaOyBBIFtUYWdUZW1wbGF0
ZV1bZ29vZ2xlLmNsb3VkLmRhdGFjYXRhbG9nLnYxLlRhZ1RlbXBsYXRlXS4KCgwKBQUAAgIB
EgNyAg4KDAoFBQACAgISA3IREgpHCgQFAAIDEgN1AhIaOiBBbiBbRW50cnlHcm91cF1bZ29v
Z2xlLmNsb3VkLmRhdGFjYXRhbG9nLnYxLkVudHJ5R3JvdXBdLgoKDAoFBQACAwESA3UCDQoM
CgUFAAIDAhIDdRARYgZwcm90bzM=
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Datacatalog::V1::Search::SearchCatalogResult ===
    # Fields for SearchCatalogResult
    # Field: search_result_type Type: 14 (.google.cloud.datacatalog.v1.SearchResultType)
    # Field: search_result_subtype Type: 9 ()
    # Field: relative_resource_name Type: 9 ()
    # Field: linked_resource Type: 9 ()
    # Field: modify_time Type: 11 (.google.protobuf.Timestamp)
    # Field: integrated_system Type: 14 (.google.cloud.datacatalog.v1.IntegratedSystem)
    # Field: user_specified_system Type: 9 ()
    # Field: fully_qualified_name Type: 9 ()
    # Field: display_name Type: 9 ()
    # Field: description Type: 9 ()

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Datacatalog::V1::Search - Compiled Protocol Buffers messages for google/cloud/datacatalog/v1/search.proto

=head1 SYNOPSIS

    use Google::Cloud::Datacatalog::V1::Search;

    my $msg = Google::Cloud::Datacatalog::V1::Search::SearchCatalogResult->new({
        search_result_type => $search_result_type,
        search_result_subtype => $search_result_subtype,
        relative_resource_name => $relative_resource_name,
        linked_resource => $linked_resource,
    });

    # Read or update a field
    my $val = $msg->search_result_type();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Datacatalog::V1::Search::SearchCatalogResult->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/datacatalog/v1/search.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Datacatalog::V1::Search::SearchCatalogResult

Result in the response to a search request.

Each result captures details of one entry that matches the search.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->search_result_type() >> / C<< $msg->search_result_type($value) >>

Type: C<Enum> (L<Google::Cloud::Datacatalog::V1::SearchResultType>)

Type of the search result.

You can use this field to determine which get method to call to fetch the
full resource.

=item * C<< $msg->search_result_subtype() >> / C<< $msg->search_result_subtype($value) >>

Type: C<String>

Sub-type of the search result.

A dot-delimited full type of the resource. The same type you
specify in the `type` search predicate.

Examples: `entry.table`, `entry.dataStream`, `tagTemplate`.

=item * C<< $msg->relative_resource_name() >> / C<< $msg->relative_resource_name($value) >>

Type: C<String>

The relative name of the resource in URL format.

Examples:

 * `projects/{PROJECT_ID}/locations/{LOCATION_ID}/entryGroups/{ENTRY_GROUP_ID}/entries/{ENTRY_ID}`
 * `projects/{PROJECT_ID}/tagTemplates/{TAG_TEMPLATE_ID}`

=item * C<< $msg->linked_resource() >> / C<< $msg->linked_resource($value) >>

Type: C<String>

The full name of the Google Cloud resource the entry belongs to.

For more information, see [Full Resource Name]
(/apis/design/resource_names#full_resource_name).

Example:

`//bigquery.googleapis.com/projects/PROJECT_ID/datasets/DATASET_ID/tables/TABLE_ID`

=item * C<< $msg->modify_time() >> / C<< $msg->modify_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

The last modification timestamp of the entry in the source system.

=item * C<< $msg->integrated_system() >> / C<< $msg->integrated_system($value) >>

Type: C<Enum> (L<Google::Cloud::Datacatalog::V1::IntegratedSystem>)

Output only. The source system that Data Catalog automatically integrates
with, such as BigQuery, Cloud Pub/Sub, or Dataproc Metastore.

=item * C<< $msg->user_specified_system() >> / C<< $msg->user_specified_system($value) >>

Type: C<String>

Custom source system that you can manually integrate Data Catalog with.

=item * C<< $msg->fully_qualified_name() >> / C<< $msg->fully_qualified_name($value) >>

Type: C<String>

Fully qualified name (FQN) of the resource.

FQNs take two forms:

* For non-regionalized resources:

  `{SYSTEM}:{PROJECT}.{PATH_TO_RESOURCE_SEPARATED_WITH_DOTS}`

* For regionalized resources:

  `{SYSTEM}:{PROJECT}.{LOCATION_ID}.{PATH_TO_RESOURCE_SEPARATED_WITH_DOTS}`

Example for a DPMS table:

`dataproc_metastore:PROJECT_ID.LOCATION_ID.INSTANCE_ID.DATABASE_ID.TABLE_ID`

=item * C<< $msg->display_name() >> / C<< $msg->display_name($value) >>

Type: C<String>

The display name of the result.

=item * C<< $msg->description() >> / C<< $msg->description($value) >>

Type: C<String>

Entry description that can consist of several sentences or paragraphs that
describe entry contents.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Datacatalog::V1::Search::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
