package Google::Cloud::Bigquery::V2::TableConstraints;

use strict;
use warnings;

our $VERSION = '0.14';

use Protobuf::Message;
use Protobuf::DescriptorPool;
use Protobuf::Internal qw(:all);
use MIME::Base64;

BEGIN {
    eval { require Google::Api::FieldBehavior };
    eval { require Google::Cloud::Bigquery::V2::TableReference };
    my $descriptor_b64 = <<'EOF';
CjBnb29nbGUvY2xvdWQvYmlncXVlcnkvdjIvdGFibGVfY29uc3RyYWludHMucHJvdG8SGGdv
b2dsZS5jbG91ZC5iaWdxdWVyeS52MhofZ29vZ2xlL2FwaS9maWVsZF9iZWhhdmlvci5wcm90
bxouZ29vZ2xlL2Nsb3VkL2JpZ3F1ZXJ5L3YyL3RhYmxlX3JlZmVyZW5jZS5wcm90byIrCgpQ
cmltYXJ5S2V5Eh0KB2NvbHVtbnMYASADKAlCA+BBAlIHY29sdW1ucyJ3Cg9Db2x1bW5SZWZl
cmVuY2USMgoScmVmZXJlbmNpbmdfY29sdW1uGAEgASgJQgPgQQJSEXJlZmVyZW5jaW5nQ29s
dW1uEjAKEXJlZmVyZW5jZWRfY29sdW1uGAIgASgJQgPgQQJSEHJlZmVyZW5jZWRDb2x1bW4i
3AEKCkZvcmVpZ25LZXkSFwoEbmFtZRgBIAEoCUID4EEBUgRuYW1lElgKEHJlZmVyZW5jZWRf
dGFibGUYAiABKAsyKC5nb29nbGUuY2xvdWQuYmlncXVlcnkudjIuVGFibGVSZWZlcmVuY2VC
A+BBAlIPcmVmZXJlbmNlZFRhYmxlElsKEWNvbHVtbl9yZWZlcmVuY2VzGAMgAygLMikuZ29v
Z2xlLmNsb3VkLmJpZ3F1ZXJ5LnYyLkNvbHVtblJlZmVyZW5jZUID4EECUhBjb2x1bW5SZWZl
cmVuY2VzIqwBChBUYWJsZUNvbnN0cmFpbnRzEkoKC3ByaW1hcnlfa2V5GAEgASgLMiQuZ29v
Z2xlLmNsb3VkLmJpZ3F1ZXJ5LnYyLlByaW1hcnlLZXlCA+BBAVIKcHJpbWFyeUtleRJMCgxm
b3JlaWduX2tleXMYAiADKAsyJC5nb29nbGUuY2xvdWQuYmlncXVlcnkudjIuRm9yZWlnbktl
eUID4EEBUgtmb3JlaWduS2V5c0JyChxjb20uZ29vZ2xlLmNsb3VkLmJpZ3F1ZXJ5LnYyQhVU
YWJsZUNvbnN0cmFpbnRzUHJvdG9aO2Nsb3VkLmdvb2dsZS5jb20vZ28vYmlncXVlcnkvdjIv
YXBpdjIvYmlncXVlcnlwYjtiaWdxdWVyeXBiSvwSCgYSBA4AQQEKvAQKAQwSAw4AEjKxBCBD
b3B5cmlnaHQgMjAyNiBHb29nbGUgTExDCgogTGljZW5zZWQgdW5kZXIgdGhlIEFwYWNoZSBM
aWNlbnNlLCBWZXJzaW9uIDIuMCAodGhlICJMaWNlbnNlIik7CiB5b3UgbWF5IG5vdCB1c2Ug
dGhpcyBmaWxlIGV4Y2VwdCBpbiBjb21wbGlhbmNlIHdpdGggdGhlIExpY2Vuc2UuCiBZb3Ug
bWF5IG9idGFpbiBhIGNvcHkgb2YgdGhlIExpY2Vuc2UgYXQKCiAgICAgaHR0cDovL3d3dy5h
cGFjaGUub3JnL2xpY2Vuc2VzL0xJQ0VOU0UtMi4wCgogVW5sZXNzIHJlcXVpcmVkIGJ5IGFw
cGxpY2FibGUgbGF3IG9yIGFncmVlZCB0byBpbiB3cml0aW5nLCBzb2Z0d2FyZQogZGlzdHJp
YnV0ZWQgdW5kZXIgdGhlIExpY2Vuc2UgaXMgZGlzdHJpYnV0ZWQgb24gYW4gIkFTIElTIiBC
QVNJUywKIFdJVEhPVVQgV0FSUkFOVElFUyBPUiBDT05ESVRJT05TIE9GIEFOWSBLSU5ELCBl
aXRoZXIgZXhwcmVzcyBvciBpbXBsaWVkLgogU2VlIHRoZSBMaWNlbnNlIGZvciB0aGUgc3Bl
Y2lmaWMgbGFuZ3VhZ2UgZ292ZXJuaW5nIHBlcm1pc3Npb25zIGFuZAogbGltaXRhdGlvbnMg
dW5kZXIgdGhlIExpY2Vuc2UuCgoICgECEgMQACEKCQoCAwASAxIAKQoJCgIDARIDEwA4CggK
AQgSAxUAUgoJCgIICxIDFQBSCggKAQgSAxYANgoJCgIICBIDFgA2CggKAQgSAxcANQoJCgII
ARIDFwA1CkkKAgQAEgQaAB0BGj0gUmVwcmVzZW50cyB0aGUgcHJpbWFyeSBrZXkgY29uc3Ry
YWludCBvbiBhIHRhYmxlJ3MgY29sdW1ucy4KCgoKAwQAARIDGggSClUKBAQAAgASAxwCRxpI
IFJlcXVpcmVkLiBUaGUgY29sdW1ucyB0aGF0IGFyZSBjb21wb3NlZCBvZiB0aGUgcHJpbWFy
eSBrZXkgY29uc3RyYWludC4KCgwKBQQAAgAEEgMcAgoKDAoFBAACAAUSAxwLEQoMCgUEAAIA
ARIDHBIZCgwKBQQAAgADEgMcHB0KDAoFBAACAAgSAxweRgoPCggEAAIACJwIABIDHB9FCkgK
AgQBEgQgACcBGjwgVGhlIHBhaXIgb2YgdGhlIGZvcmVpZ24ga2V5IGNvbHVtbiBhbmQgcHJp
bWFyeSBrZXkgY29sdW1uLgoKCgoDBAEBEgMgCBcKQgoEBAECABIDIgJJGjUgUmVxdWlyZWQu
IFRoZSBjb2x1bW4gdGhhdCBjb21wb3NlcyB0aGUgZm9yZWlnbiBrZXkuCgoMCgUEAQIABRID
IgIICgwKBQQBAgABEgMiCRsKDAoFBAECAAMSAyIeHwoMCgUEAQIACBIDIiBICg8KCAQBAgAI
nAgAEgMiIUcKZgoEBAECARIDJgJIGlkgUmVxdWlyZWQuIFRoZSBjb2x1bW4gaW4gdGhlIHBy
aW1hcnkga2V5IHRoYXQgYXJlIHJlZmVyZW5jZWQgYnkgdGhlCiByZWZlcmVuY2luZ19jb2x1
bW4uCgoMCgUEAQIBBRIDJgIICgwKBQQBAgEBEgMmCRoKDAoFBAECAQMSAyYdHgoMCgUEAQIB
CBIDJh9HCg8KCAQBAgEInAgAEgMmIEYKRwoCBAISBCoANQEaOyBSZXByZXNlbnRzIGEgZm9y
ZWlnbiBrZXkgY29uc3RyYWludCBvbiBhIHRhYmxlJ3MgY29sdW1ucy4KCgoKAwQCARIDKggS
CkkKBAQCAgASAywCOxo8IE9wdGlvbmFsLiBTZXQgb25seSBpZiB0aGUgZm9yZWlnbiBrZXkg
Y29uc3RyYWludCBpcyBuYW1lZC4KCgwKBQQCAgAFEgMsAggKDAoFBAICAAESAywJDQoMCgUE
AgIAAxIDLBARCgwKBQQCAgAIEgMsEjoKDwoIBAICAAicCAASAywTOQplCgQEAgIBEgMwAk8a
WCBSZXF1aXJlZC4gVGhlIHRhYmxlIHRoYXQgaG9sZHMgdGhlIHByaW1hcnkga2V5IGFuZCBp
cyByZWZlcmVuY2VkIGJ5IHRoaXMKIGZvcmVpZ24ga2V5LgoKDAoFBAICAQYSAzACEAoMCgUE
AgIBARIDMBEhCgwKBQQCAgEDEgMwJCUKDAoFBAICAQgSAzAmTgoPCggEAgIBCJwIABIDMCdN
CkMKBAQCAgISBDMCNC8aNSBSZXF1aXJlZC4gVGhlIGNvbHVtbnMgdGhhdCBjb21wb3NlIHRo
ZSBmb3JlaWduIGtleS4KCgwKBQQCAgIEEgMzAgoKDAoFBAICAgYSAzMLGgoMCgUEAgICARID
MxssCgwKBQQCAgIDEgMzLzAKDAoFBAICAggSAzQGLgoPCggEAgICCJwIABIDNActCksKAgQD
EgQ4AEEBGj8gVGhlIFRhYmxlQ29uc3RyYWludHMgZGVmaW5lcyB0aGUgcHJpbWFyeSBrZXkg
YW5kIGZvcmVpZ24ga2V5LgoKCgoDBAMBEgM4CBgKowEKBAQDAgASAzwCRhqVASBPcHRpb25h
bC4gUmVwcmVzZW50cyBhIHByaW1hcnkga2V5IGNvbnN0cmFpbnQgb24gYSB0YWJsZSdzIGNv
bHVtbnMuCiBQcmVzZW50IG9ubHkgaWYgdGhlIHRhYmxlIGhhcyBhIHByaW1hcnkga2V5Lgog
VGhlIHByaW1hcnkga2V5IGlzIG5vdCBlbmZvcmNlZC4KCgwKBQQDAgAGEgM8AgwKDAoFBAMC
AAESAzwNGAoMCgUEAwIAAxIDPBscCgwKBQQDAgAIEgM8HUUKDwoIBAMCAAicCAASAzweRApn
CgQEAwIBEgNAAlAaWiBPcHRpb25hbC4gUHJlc2VudCBvbmx5IGlmIHRoZSB0YWJsZSBoYXMg
YSBmb3JlaWduIGtleS4KIFRoZSBmb3JlaWduIGtleSBpcyBub3QgZW5mb3JjZWQuCgoMCgUE
AwIBBBIDQAIKCgwKBQQDAgEGEgNACxUKDAoFBAMCAQESA0AWIgoMCgUEAwIBAxIDQCUmCgwK
BQQDAgEIEgNAJ08KDwoIBAMCAQicCAASA0AoTmIGcHJvdG8z
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Bigquery::V2::TableConstraints::PrimaryKey ===
    # Fields for PrimaryKey
    # Field: columns Type: 9 ()

# === Message: Google::Cloud::Bigquery::V2::TableConstraints::ColumnReference ===
    # Fields for ColumnReference
    # Field: referencing_column Type: 9 ()
    # Field: referenced_column Type: 9 ()

# === Message: Google::Cloud::Bigquery::V2::TableConstraints::ForeignKey ===
    # Fields for ForeignKey
    # Field: name Type: 9 ()
    # Field: referenced_table Type: 11 (.google.cloud.bigquery.v2.TableReference)
    # Field: column_references Type: 11 (.google.cloud.bigquery.v2.ColumnReference)

# === Message: Google::Cloud::Bigquery::V2::TableConstraints::TableConstraints ===
    # Fields for TableConstraints
    # Field: primary_key Type: 11 (.google.cloud.bigquery.v2.PrimaryKey)
    # Field: foreign_keys Type: 11 (.google.cloud.bigquery.v2.ForeignKey)

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Bigquery::V2::TableConstraints - Compiled Protocol Buffers messages for google/cloud/bigquery/v2/table_constraints.proto

=head1 SYNOPSIS

    use Google::Cloud::Bigquery::V2::TableConstraints;

    my $msg = Google::Cloud::Bigquery::V2::TableConstraints::PrimaryKey->new({
        columns => $columns,
    });

    # Read or update a field
    my $val = $msg->columns();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Bigquery::V2::TableConstraints::PrimaryKey->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/bigquery/v2/table_constraints.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Bigquery::V2::TableConstraints::PrimaryKey

Represents the primary key constraint on a table's columns.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->columns() >> / C<< $msg->columns($value) >>

Type: C<String>

Required. The columns that are composed of the primary key constraint.

=back

=head2 Google::Cloud::Bigquery::V2::TableConstraints::ColumnReference

The pair of the foreign key column and primary key column.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->referencing_column() >> / C<< $msg->referencing_column($value) >>

Type: C<String>

Required. The column that composes the foreign key.

=item * C<< $msg->referenced_column() >> / C<< $msg->referenced_column($value) >>

Type: C<String>

Required. The column in the primary key that are referenced by the
referencing_column.

=back

=head2 Google::Cloud::Bigquery::V2::TableConstraints::ForeignKey

Represents a foreign key constraint on a table's columns.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Optional. Set only if the foreign key constraint is named.

=item * C<< $msg->referenced_table() >> / C<< $msg->referenced_table($value) >>

Type: C<Message> (L<Google::Cloud::Bigquery::V2::TableReference::TableReference>)

Required. The table that holds the primary key and is referenced by this
foreign key.

=item * C<< $msg->column_references() >> / C<< $msg->column_references($value) >>

Type: C<Message> (L<Google::Cloud::Bigquery::V2::TableConstraints::ColumnReference>)

Required. The columns that compose the foreign key.

=back

=head2 Google::Cloud::Bigquery::V2::TableConstraints::TableConstraints

The TableConstraints defines the primary key and foreign key.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->primary_key() >> / C<< $msg->primary_key($value) >>

Type: C<Message> (L<Google::Cloud::Bigquery::V2::TableConstraints::PrimaryKey>)

Optional. Represents a primary key constraint on a table's columns.
Present only if the table has a primary key.
The primary key is not enforced.

=item * C<< $msg->foreign_keys() >> / C<< $msg->foreign_keys($value) >>

Type: C<Message> (L<Google::Cloud::Bigquery::V2::TableConstraints::ForeignKey>)

Optional. Present only if the table has a foreign key.
The foreign key is not enforced.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Bigquery::V2::TableConstraints::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
