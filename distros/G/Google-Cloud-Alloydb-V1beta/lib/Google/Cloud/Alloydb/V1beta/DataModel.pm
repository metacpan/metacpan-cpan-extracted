package Google::Cloud::Alloydb::V1beta::DataModel;

use strict;
use warnings;

our $VERSION = '0.14';

use Protobuf::Message;
use Protobuf::DescriptorPool;
use Protobuf::Internal qw(:all);
use MIME::Base64;

BEGIN {
    my $descriptor_b64 = <<'EOF';
Cixnb29nbGUvY2xvdWQvYWxsb3lkYi92MWJldGEvZGF0YV9tb2RlbC5wcm90bxIbZ29vZ2xl
LmNsb3VkLmFsbG95ZGIudjFiZXRhIpIBCglTcWxSZXN1bHQSRgoHY29sdW1ucxgBIAMoCzIs
Lmdvb2dsZS5jbG91ZC5hbGxveWRiLnYxYmV0YS5TcWxSZXN1bHRDb2x1bW5SB2NvbHVtbnMS
PQoEcm93cxgCIAMoCzIpLmdvb2dsZS5jbG91ZC5hbGxveWRiLnYxYmV0YS5TcWxSZXN1bHRS
b3dSBHJvd3MiOQoPU3FsUmVzdWx0Q29sdW1uEhIKBG5hbWUYASABKAlSBG5hbWUSEgoEdHlw
ZRgCIAEoCVIEdHlwZSJTCgxTcWxSZXN1bHRSb3cSQwoGdmFsdWVzGAEgAygLMisuZ29vZ2xl
LmNsb3VkLmFsbG95ZGIudjFiZXRhLlNxbFJlc3VsdFZhbHVlUgZ2YWx1ZXMiaAoOU3FsUmVz
dWx0VmFsdWUSGQoFdmFsdWUYASABKAlIAFIFdmFsdWWIAQESIgoKbnVsbF92YWx1ZRgCIAEo
CEgBUgludWxsVmFsdWWIAQFCCAoGX3ZhbHVlQg0KC19udWxsX3ZhbHVlQssBCh9jb20uZ29v
Z2xlLmNsb3VkLmFsbG95ZGIudjFiZXRhQg5EYXRhTW9kZWxQcm90b1ABWjljbG91ZC5nb29n
bGUuY29tL2dvL2FsbG95ZGIvYXBpdjFiZXRhL2FsbG95ZGJwYjthbGxveWRicGKqAhtHb29n
bGUuQ2xvdWQuQWxsb3lEYi5WMUJldGHKAhtHb29nbGVcQ2xvdWRcQWxsb3lEYlxWMWJldGHq
Ah5Hb29nbGU6OkNsb3VkOjpBbGxveURCOjpWMWJldGFK2w8KBhIEDgA9AQq8BAoBDBIDDgAS
MrEEIENvcHlyaWdodCAyMDI1IEdvb2dsZSBMTEMKCiBMaWNlbnNlZCB1bmRlciB0aGUgQXBh
Y2hlIExpY2Vuc2UsIFZlcnNpb24gMi4wICh0aGUgIkxpY2Vuc2UiKTsKIHlvdSBtYXkgbm90
IHVzZSB0aGlzIGZpbGUgZXhjZXB0IGluIGNvbXBsaWFuY2Ugd2l0aCB0aGUgTGljZW5zZS4K
IFlvdSBtYXkgb2J0YWluIGEgY29weSBvZiB0aGUgTGljZW5zZSBhdAoKICAgICBodHRwOi8v
d3d3LmFwYWNoZS5vcmcvbGljZW5zZXMvTElDRU5TRS0yLjAKCiBVbmxlc3MgcmVxdWlyZWQg
YnkgYXBwbGljYWJsZSBsYXcgb3IgYWdyZWVkIHRvIGluIHdyaXRpbmcsIHNvZnR3YXJlCiBk
aXN0cmlidXRlZCB1bmRlciB0aGUgTGljZW5zZSBpcyBkaXN0cmlidXRlZCBvbiBhbiAiQVMg
SVMiIEJBU0lTLAogV0lUSE9VVCBXQVJSQU5USUVTIE9SIENPTkRJVElPTlMgT0YgQU5ZIEtJ
TkQsIGVpdGhlciBleHByZXNzIG9yIGltcGxpZWQuCiBTZWUgdGhlIExpY2Vuc2UgZm9yIHRo
ZSBzcGVjaWZpYyBsYW5ndWFnZSBnb3Zlcm5pbmcgcGVybWlzc2lvbnMgYW5kCiBsaW1pdGF0
aW9ucyB1bmRlciB0aGUgTGljZW5zZS4KCggKAQISAxAAJAoICgEIEgMSADgKCQoCCCUSAxIA
OAoICgEIEgMTAFAKCQoCCAsSAxMAUAoICgEIEgMUACIKCQoCCAoSAxQAIgoICgEIEgMVAC8K
CQoCCAgSAxUALwoICgEIEgMWADgKCQoCCAESAxYAOAoICgEIEgMXADgKCQoCCCkSAxcAOAoI
CgEIEgMYADcKCQoCCC0SAxgANwpTCgIEABIEGwAiARpHIFNxbFJlc3VsdCByZXByZXNlbnRz
IHRoZSByZXN1bHQgZm9yIHRoZSBleGVjdXRpb24gb2YgYSBzcWwgc3RhdGVtZW50LgoKCgoD
BAABEgMbCBEKZwoEBAACABIDHgInGlogTGlzdCBvZiBjb2x1bW5zIGluY2x1ZGVkIGluIHRo
ZSByZXN1bHQuIFRoaXMgYWxzbyBpbmNsdWRlcyB0aGUgZGF0YSB0eXBlCiBvZiB0aGUgY29s
dW1uLgoKDAoFBAACAAQSAx4CCgoMCgUEAAIABhIDHgsaCgwKBQQAAgABEgMeGyIKDAoFBAAC
AAMSAx4lJgoyCgQEAAIBEgMhAiEaJSBSb3dzIHJldHVybmVkIGJ5IHRoZSBTUUwgc3RhdGVt
ZW50LgoKDAoFBAACAQQSAyECCgoMCgUEAAIBBhIDIQsXCgwKBQQAAgEBEgMhGBwKDAoFBAAC
AQMSAyEfIApJCgIEARIEJQAtARo9IENvbnRhaW5zIHRoZSBuYW1lIGFuZCBkYXRhdHlwZSBv
ZiBhIGNvbHVtbiBpbiBhIFNRTCBSZXN1bHQuCgoKCgMEAQESAyUIFwoiCgQEAQIAEgMnAhIa
FSBOYW1lIG9mIHRoZSBjb2x1bW4uCgoMCgUEAQIABRIDJwIICgwKBQQBAgABEgMnCQ0KDAoF
BAECAAMSAycQEQqpAQoEBAECARIDLAISGpsBIERhdGF0eXBlIG9mIHRoZSBjb2x1bW4gYXMg
cmVwb3J0ZWQgYnkgdGhlIHBvc3RncmVzIGRyaXZlci4KIENvbW1vbiB0eXBlIG5hbWVzIGFy
ZSAiVkFSQ0hBUiIsICJURVhUIiwgIk5WQVJDSEFSIiwgIkRFQ0lNQUwiLCAiQk9PTCIsCiAi
SU5UIiwgYW5kICJCSUdJTlQiLgoKDAoFBAECAQUSAywCCAoMCgUEAQIBARIDLAkNCgwKBQQB
AgEDEgMsEBEKLQoCBAISBDAAMwEaISBBIHNpbmdsZSByb3cgZnJvbSBhIHNxbCByZXN1bHQu
CgoKCgMEAgESAzAIFAo1CgQEAgIAEgMyAiUaKCBMaXN0IG9mIHZhbHVlcyBpbiBhIHJvdyBv
ZiBzcWwgcmVzdWx0LgoKDAoFBAICAAQSAzICCgoMCgUEAgIABhIDMgsZCgwKBQQCAgABEgMy
GiAKDAoFBAICAAMSAzIjJAo4CgIEAxIENgA9ARosIEEgc2luZ2xlIHZhbHVlIGluIGEgcm93
IGZyb20gYSBzcWwgcmVzdWx0LgoKCgoDBAMBEgM2CBYKeQoEBAMCABIDOQIcGmwgVGhlIGNl
bGwgdmFsdWUgcmVwcmVzZW50ZWQgaW4gc3RyaW5nIGZvcm1hdC4KIFRpbWVzdGFtcHMgYXJl
IGNvbnZlcnRlZCB0byBzdHJpbmcgdXNpbmcgUkZDMzMzOU5hbm8gZm9ybWF0LgoKDAoFBAMC
AAQSAzkCCgoMCgUEAwIABRIDOQsRCgwKBQQDAgABEgM5EhcKDAoFBAMCAAMSAzkaGwoxCgQE
AwIBEgM8Ah8aJCBTZXQgdG8gdHJ1ZSBpZiBjZWxsIHZhbHVlIGlzIG51bGwuCgoMCgUEAwIB
BBIDPAIKCgwKBQQDAgEFEgM8Cw8KDAoFBAMCAQESAzwQGgoMCgUEAwIBAxIDPB0eYgZwcm90
bzM=
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Alloydb::V1beta::DataModel::SqlResult ===
    # Fields for SqlResult
    # Field: columns Type: 11 (.google.cloud.alloydb.v1beta.SqlResultColumn)
    # Field: rows Type: 11 (.google.cloud.alloydb.v1beta.SqlResultRow)

# === Message: Google::Cloud::Alloydb::V1beta::DataModel::SqlResultColumn ===
    # Fields for SqlResultColumn
    # Field: name Type: 9 ()
    # Field: type Type: 9 ()

# === Message: Google::Cloud::Alloydb::V1beta::DataModel::SqlResultRow ===
    # Fields for SqlResultRow
    # Field: values Type: 11 (.google.cloud.alloydb.v1beta.SqlResultValue)

# === Message: Google::Cloud::Alloydb::V1beta::DataModel::SqlResultValue ===
    # Fields for SqlResultValue
    # Field: value Type: 9 ()
    # Field: null_value Type: 8 ()

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Alloydb::V1beta::DataModel - Compiled Protocol Buffers messages for google/cloud/alloydb/v1beta/data_model.proto

=head1 SYNOPSIS

    use Google::Cloud::Alloydb::V1beta::DataModel;

    my $msg = Google::Cloud::Alloydb::V1beta::DataModel::SqlResult->new({
        columns => $columns,
        rows => $rows,
    });

    # Read or update a field
    my $val = $msg->columns();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Alloydb::V1beta::DataModel::SqlResult->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/alloydb/v1beta/data_model.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Alloydb::V1beta::DataModel::SqlResult

SqlResult represents the result for the execution of a sql statement.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->columns() >> / C<< $msg->columns($value) >>

Type: C<Message> (L<Google::Cloud::Alloydb::V1beta::DataModel::SqlResultColumn>)

List of columns included in the result. This also includes the data type
of the column.

=item * C<< $msg->rows() >> / C<< $msg->rows($value) >>

Type: C<Message> (L<Google::Cloud::Alloydb::V1beta::DataModel::SqlResultRow>)

Rows returned by the SQL statement.

=back

=head2 Google::Cloud::Alloydb::V1beta::DataModel::SqlResultColumn

Contains the name and datatype of a column in a SQL Result.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Name of the column.

=item * C<< $msg->type() >> / C<< $msg->type($value) >>

Type: C<String>

Datatype of the column as reported by the postgres driver.
Common type names are "VARCHAR", "TEXT", "NVARCHAR", "DECIMAL", "BOOL",
"INT", and "BIGINT".

=back

=head2 Google::Cloud::Alloydb::V1beta::DataModel::SqlResultRow

A single row from a sql result.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->values() >> / C<< $msg->values($value) >>

Type: C<Message> (L<Google::Cloud::Alloydb::V1beta::DataModel::SqlResultValue>)

List of values in a row of sql result.

=back

=head2 Google::Cloud::Alloydb::V1beta::DataModel::SqlResultValue

A single value in a row from a sql result.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->value() >> / C<< $msg->value($value) >>

Type: C<String>

The cell value represented in string format.
Timestamps are converted to string using RFC3339Nano format.

=item * C<< $msg->null_value() >> / C<< $msg->null_value($value) >>

Type: C<Bool>

Set to true if cell value is null.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Alloydb::V1beta::DataModel::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
