package Google::Cloud::Bigquery::V2::TableReference;

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
Ci5nb29nbGUvY2xvdWQvYmlncXVlcnkvdjIvdGFibGVfcmVmZXJlbmNlLnByb3RvEhhnb29n
bGUuY2xvdWQuYmlncXVlcnkudjIaH2dvb2dsZS9hcGkvZmllbGRfYmVoYXZpb3IucHJvdG8i
eAoOVGFibGVSZWZlcmVuY2USIgoKcHJvamVjdF9pZBgBIAEoCUID4EECUglwcm9qZWN0SWQS
IgoKZGF0YXNldF9pZBgCIAEoCUID4EECUglkYXRhc2V0SWQSHgoIdGFibGVfaWQYAyABKAlC
A+BBAlIHdGFibGVJZEJwChxjb20uZ29vZ2xlLmNsb3VkLmJpZ3F1ZXJ5LnYyQhNUYWJsZVJl
ZmVyZW5jZVByb3RvWjtjbG91ZC5nb29nbGUuY29tL2dvL2JpZ3F1ZXJ5L3YyL2FwaXYyL2Jp
Z3F1ZXJ5cGI7YmlncXVlcnlwYkr3CwoGEgQOACcBCrwECgEMEgMOABIysQQgQ29weXJpZ2h0
IDIwMjYgR29vZ2xlIExMQwoKIExpY2Vuc2VkIHVuZGVyIHRoZSBBcGFjaGUgTGljZW5zZSwg
VmVyc2lvbiAyLjAgKHRoZSAiTGljZW5zZSIpOwogeW91IG1heSBub3QgdXNlIHRoaXMgZmls
ZSBleGNlcHQgaW4gY29tcGxpYW5jZSB3aXRoIHRoZSBMaWNlbnNlLgogWW91IG1heSBvYnRh
aW4gYSBjb3B5IG9mIHRoZSBMaWNlbnNlIGF0CgogICAgIGh0dHA6Ly93d3cuYXBhY2hlLm9y
Zy9saWNlbnNlcy9MSUNFTlNFLTIuMAoKIFVubGVzcyByZXF1aXJlZCBieSBhcHBsaWNhYmxl
IGxhdyBvciBhZ3JlZWQgdG8gaW4gd3JpdGluZywgc29mdHdhcmUKIGRpc3RyaWJ1dGVkIHVu
ZGVyIHRoZSBMaWNlbnNlIGlzIGRpc3RyaWJ1dGVkIG9uIGFuICJBUyBJUyIgQkFTSVMsCiBX
SVRIT1VUIFdBUlJBTlRJRVMgT1IgQ09ORElUSU9OUyBPRiBBTlkgS0lORCwgZWl0aGVyIGV4
cHJlc3Mgb3IgaW1wbGllZC4KIFNlZSB0aGUgTGljZW5zZSBmb3IgdGhlIHNwZWNpZmljIGxh
bmd1YWdlIGdvdmVybmluZyBwZXJtaXNzaW9ucyBhbmQKIGxpbWl0YXRpb25zIHVuZGVyIHRo
ZSBMaWNlbnNlLgoKCAoBAhIDEAAhCgkKAgMAEgMSACkKCAoBCBIDFABSCgkKAggLEgMUAFIK
CAoBCBIDFQA0CgkKAggIEgMVADQKCAoBCBIDFgA1CgkKAggBEgMWADUKCgoCBAASBBgAJwEK
CgoDBAABEgMYCBYKRQoEBAACABIDGgJBGjggUmVxdWlyZWQuIFRoZSBJRCBvZiB0aGUgcHJv
amVjdCBjb250YWluaW5nIHRoaXMgdGFibGUuCgoMCgUEAAIABRIDGgIICgwKBQQAAgABEgMa
CRMKDAoFBAACAAMSAxoWFwoMCgUEAAIACBIDGhhACg8KCAQAAgAInAgAEgMaGT8KRQoEBAAC
ARIDHQJBGjggUmVxdWlyZWQuIFRoZSBJRCBvZiB0aGUgZGF0YXNldCBjb250YWluaW5nIHRo
aXMgdGFibGUuCgoMCgUEAAIBBRIDHQIICgwKBQQAAgEBEgMdCRMKDAoFBAACAQMSAx0WFwoM
CgUEAAIBCBIDHRhACg8KCAQAAgEInAgAEgMdGT8K2AMKBAQAAgISAyYCPxrKAyBSZXF1aXJl
ZC4gVGhlIElEIG9mIHRoZSB0YWJsZS4gVGhlIElEIGNhbiBjb250YWluIFVuaWNvZGUgY2hh
cmFjdGVycyBpbgogY2F0ZWdvcnkgTCAobGV0dGVyKSwgTSAobWFyayksIE4gKG51bWJlciks
IFBjIChjb25uZWN0b3IsIGluY2x1ZGluZwogdW5kZXJzY29yZSksIFBkIChkYXNoKSwgYW5k
IFpzIChzcGFjZSkuIEZvciBtb3JlIGluZm9ybWF0aW9uLCBzZWUgW0dlbmVyYWwKIENhdGVn
b3J5XShodHRwczovL3dpa2lwZWRpYS5vcmcvd2lraS9Vbmljb2RlX2NoYXJhY3Rlcl9wcm9w
ZXJ0eSNHZW5lcmFsX0NhdGVnb3J5KS4KIFRoZSBtYXhpbXVtIGxlbmd0aCBpcyAxLDAyNCBj
aGFyYWN0ZXJzLiAgQ2VydGFpbiBvcGVyYXRpb25zIGFsbG93IHN1ZmZpeGluZwogb2YgdGhl
IHRhYmxlIElEIHdpdGggYSBwYXJ0aXRpb24gZGVjb3JhdG9yLCBzdWNoIGFzCiBgc2FtcGxl
X3RhYmxlJDIwMTkwMTIzYC4KCgwKBQQAAgIFEgMmAggKDAoFBAACAgESAyYJEQoMCgUEAAIC
AxIDJhQVCgwKBQQAAgIIEgMmFj4KDwoIBAACAgicCAASAyYXPWIGcHJvdG8z
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Bigquery::V2::TableReference::TableReference ===
    # Fields for TableReference
    # Field: project_id Type: 9 ()
    # Field: dataset_id Type: 9 ()
    # Field: table_id Type: 9 ()

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Bigquery::V2::TableReference - Compiled Protocol Buffers messages for google/cloud/bigquery/v2/table_reference.proto

=head1 SYNOPSIS

    use Google::Cloud::Bigquery::V2::TableReference;

    my $msg = Google::Cloud::Bigquery::V2::TableReference::TableReference->new({
        project_id => $project_id,
        dataset_id => $dataset_id,
        table_id => $table_id,
    });

    # Read or update a field
    my $val = $msg->project_id();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Bigquery::V2::TableReference::TableReference->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/bigquery/v2/table_reference.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Bigquery::V2::TableReference::TableReference

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->project_id() >> / C<< $msg->project_id($value) >>

Type: C<String>

Required. The ID of the project containing this table.

=item * C<< $msg->dataset_id() >> / C<< $msg->dataset_id($value) >>

Type: C<String>

Required. The ID of the dataset containing this table.

=item * C<< $msg->table_id() >> / C<< $msg->table_id($value) >>

Type: C<String>

Required. The ID of the table. The ID can contain Unicode characters in
category L (letter), M (mark), N (number), Pc (connector, including
underscore), Pd (dash), and Zs (space). For more information, see [General
Category](https://wikipedia.org/wiki/Unicode_character_property#General_Category).
The maximum length is 1,024 characters.  Certain operations allow suffixing
of the table ID with a partition decorator, such as
`sample_table$20190123`.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Bigquery::V2::TableReference::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
