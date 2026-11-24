package Google::Cloud::Bigquery::Storage::V1beta1::TableReference;

use strict;
use warnings;

our $VERSION = '0.14';

use Protobuf::Message;
use Protobuf::DescriptorPool;
use Protobuf::Internal qw(:all);
use MIME::Base64;

BEGIN {
    eval { require Google::Protobuf::Timestamp };
    my $descriptor_b64 = <<'EOF';
Cjtnb29nbGUvY2xvdWQvYmlncXVlcnkvc3RvcmFnZS92MWJldGExL3RhYmxlX3JlZmVyZW5j
ZS5wcm90bxIlZ29vZ2xlLmNsb3VkLmJpZ3F1ZXJ5LnN0b3JhZ2UudjFiZXRhMRofZ29vZ2xl
L3Byb3RvYnVmL3RpbWVzdGFtcC5wcm90byJpCg5UYWJsZVJlZmVyZW5jZRIdCgpwcm9qZWN0
X2lkGAEgASgJUglwcm9qZWN0SWQSHQoKZGF0YXNldF9pZBgCIAEoCVIJZGF0YXNldElkEhkK
CHRhYmxlX2lkGAMgASgJUgd0YWJsZUlkIlEKDlRhYmxlTW9kaWZpZXJzEj8KDXNuYXBzaG90
X3RpbWUYASABKAsyGi5nb29nbGUucHJvdG9idWYuVGltZXN0YW1wUgxzbmFwc2hvdFRpbWVC
hQEKKWNvbS5nb29nbGUuY2xvdWQuYmlncXVlcnkuc3RvcmFnZS52MWJldGExQhNUYWJsZVJl
ZmVyZW5jZVByb3RvWkNjbG91ZC5nb29nbGUuY29tL2dvL2JpZ3F1ZXJ5L3N0b3JhZ2UvYXBp
djFiZXRhMS9zdG9yYWdlcGI7c3RvcmFnZXBiSukJCgYSBA4AKAEKvAQKAQwSAw4AEjKxBCBD
b3B5cmlnaHQgMjAyNSBHb29nbGUgTExDCgogTGljZW5zZWQgdW5kZXIgdGhlIEFwYWNoZSBM
aWNlbnNlLCBWZXJzaW9uIDIuMCAodGhlICJMaWNlbnNlIik7CiB5b3UgbWF5IG5vdCB1c2Ug
dGhpcyBmaWxlIGV4Y2VwdCBpbiBjb21wbGlhbmNlIHdpdGggdGhlIExpY2Vuc2UuCiBZb3Ug
bWF5IG9idGFpbiBhIGNvcHkgb2YgdGhlIExpY2Vuc2UgYXQKCiAgICAgaHR0cDovL3d3dy5h
cGFjaGUub3JnL2xpY2Vuc2VzL0xJQ0VOU0UtMi4wCgogVW5sZXNzIHJlcXVpcmVkIGJ5IGFw
cGxpY2FibGUgbGF3IG9yIGFncmVlZCB0byBpbiB3cml0aW5nLCBzb2Z0d2FyZQogZGlzdHJp
YnV0ZWQgdW5kZXIgdGhlIExpY2Vuc2UgaXMgZGlzdHJpYnV0ZWQgb24gYW4gIkFTIElTIiBC
QVNJUywKIFdJVEhPVVQgV0FSUkFOVElFUyBPUiBDT05ESVRJT05TIE9GIEFOWSBLSU5ELCBl
aXRoZXIgZXhwcmVzcyBvciBpbXBsaWVkLgogU2VlIHRoZSBMaWNlbnNlIGZvciB0aGUgc3Bl
Y2lmaWMgbGFuZ3VhZ2UgZ292ZXJuaW5nIHBlcm1pc3Npb25zIGFuZAogbGltaXRhdGlvbnMg
dW5kZXIgdGhlIExpY2Vuc2UuCgoICgECEgMQAC4KCQoCAwASAxIAKQoICgEIEgMUAFoKCQoC
CAsSAxQAWgoICgEIEgMVADQKCQoCCAgSAxUANAoICgEIEgMWAEIKCQoCCAESAxYAQgpaCgIE
ABIEGQAiARpOIFRhYmxlIHJlZmVyZW5jZSB0aGF0IGluY2x1ZGVzIGp1c3QgdGhlIDMgc3Ry
aW5ncyBuZWVkZWQgdG8gaWRlbnRpZnkgYSB0YWJsZS4KCgoKAwQAARIDGQgWCjYKBAQAAgAS
AxsCGBopIFRoZSBhc3NpZ25lZCBwcm9qZWN0IElEIG9mIHRoZSBwcm9qZWN0LgoKDAoFBAAC
AAUSAxsCCAoMCgUEAAIAARIDGwkTCgwKBQQAAgADEgMbFhcKOgoEBAACARIDHgIYGi0gVGhl
IElEIG9mIHRoZSBkYXRhc2V0IGluIHRoZSBhYm92ZSBwcm9qZWN0LgoKDAoFBAACAQUSAx4C
CAoMCgUEAAIBARIDHgkTCgwKBQQAAgEDEgMeFhcKOAoEBAACAhIDIQIWGisgVGhlIElEIG9m
IHRoZSB0YWJsZSBpbiB0aGUgYWJvdmUgZGF0YXNldC4KCgwKBQQAAgIFEgMhAggKDAoFBAAC
AgESAyEJEQoMCgUEAAICAxIDIRQVCjIKAgQBEgQlACgBGiYgQWxsIGZpZWxkcyBpbiB0aGlz
IG1lc3NhZ2Ugb3B0aW9uYWwuCgoKCgMEAQESAyUIFgpOCgQEAQIAEgMnAi4aQSBUaGUgc25h
cHNob3QgdGltZSBvZiB0aGUgdGFibGUuIElmIG5vdCBzZXQsIGludGVycHJldGVkIGFzIG5v
dy4KCgwKBQQBAgAGEgMnAhsKDAoFBAECAAESAyccKQoMCgUEAQIAAxIDJywtYgZwcm90bzM=

EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Bigquery::Storage::V1beta1::TableReference::TableReference ===
    # Fields for TableReference
    # Field: project_id Type: 9 ()
    # Field: dataset_id Type: 9 ()
    # Field: table_id Type: 9 ()

# === Message: Google::Cloud::Bigquery::Storage::V1beta1::TableReference::TableModifiers ===
    # Fields for TableModifiers
    # Field: snapshot_time Type: 11 (.google.protobuf.Timestamp)

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Bigquery::Storage::V1beta1::TableReference - Compiled Protocol Buffers messages for google/cloud/bigquery/storage/v1beta1/table_reference.proto

=head1 SYNOPSIS

    use Google::Cloud::Bigquery::Storage::V1beta1::TableReference;

    my $msg = Google::Cloud::Bigquery::Storage::V1beta1::TableReference::TableReference->new({
        project_id => $project_id,
        dataset_id => $dataset_id,
        table_id => $table_id,
    });

    # Read or update a field
    my $val = $msg->project_id();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Bigquery::Storage::V1beta1::TableReference::TableReference->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/bigquery/storage/v1beta1/table_reference.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Bigquery::Storage::V1beta1::TableReference::TableReference

Table reference that includes just the 3 strings needed to identify a table.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->project_id() >> / C<< $msg->project_id($value) >>

Type: C<String>

The assigned project ID of the project.

=item * C<< $msg->dataset_id() >> / C<< $msg->dataset_id($value) >>

Type: C<String>

The ID of the dataset in the above project.

=item * C<< $msg->table_id() >> / C<< $msg->table_id($value) >>

Type: C<String>

The ID of the table in the above dataset.

=back

=head2 Google::Cloud::Bigquery::Storage::V1beta1::TableReference::TableModifiers

All fields in this message optional.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->snapshot_time() >> / C<< $msg->snapshot_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

The snapshot time of the table. If not set, interpreted as now.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Bigquery::Storage::V1beta1::TableReference::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
