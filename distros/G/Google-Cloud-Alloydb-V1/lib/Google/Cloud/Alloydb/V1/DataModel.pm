package Google::Cloud::Alloydb::V1::DataModel;

use strict;
use warnings;

our $VERSION = '0.14';

use Protobuf::Message;
use Protobuf::DescriptorPool;
use Protobuf::Internal qw(:all);
use MIME::Base64;

BEGIN {
    my $descriptor_b64 = <<'EOF';
Cihnb29nbGUvY2xvdWQvYWxsb3lkYi92MS9kYXRhX21vZGVsLnByb3RvEhdnb29nbGUuY2xv
dWQuYWxsb3lkYi52MSKKAQoJU3FsUmVzdWx0EkIKB2NvbHVtbnMYASADKAsyKC5nb29nbGUu
Y2xvdWQuYWxsb3lkYi52MS5TcWxSZXN1bHRDb2x1bW5SB2NvbHVtbnMSOQoEcm93cxgCIAMo
CzIlLmdvb2dsZS5jbG91ZC5hbGxveWRiLnYxLlNxbFJlc3VsdFJvd1IEcm93cyI5Cg9TcWxS
ZXN1bHRDb2x1bW4SEgoEbmFtZRgBIAEoCVIEbmFtZRISCgR0eXBlGAIgASgJUgR0eXBlIk8K
DFNxbFJlc3VsdFJvdxI/CgZ2YWx1ZXMYASADKAsyJy5nb29nbGUuY2xvdWQuYWxsb3lkYi52
MS5TcWxSZXN1bHRWYWx1ZVIGdmFsdWVzImgKDlNxbFJlc3VsdFZhbHVlEhkKBXZhbHVlGAEg
ASgJSABSBXZhbHVliAEBEiIKCm51bGxfdmFsdWUYAiABKAhIAVIJbnVsbFZhbHVliAEBQggK
Bl92YWx1ZUINCgtfbnVsbF92YWx1ZUK3AQobY29tLmdvb2dsZS5jbG91ZC5hbGxveWRiLnYx
Qg5EYXRhTW9kZWxQcm90b1ABWjVjbG91ZC5nb29nbGUuY29tL2dvL2FsbG95ZGIvYXBpdjEv
YWxsb3lkYnBiO2FsbG95ZGJwYqoCF0dvb2dsZS5DbG91ZC5BbGxveURiLlYxygIXR29vZ2xl
XENsb3VkXEFsbG95RGJcVjHqAhpHb29nbGU6OkNsb3VkOjpBbGxveURCOjpWMUrbDwoGEgQO
AD0BCrwECgEMEgMOABIysQQgQ29weXJpZ2h0IDIwMjUgR29vZ2xlIExMQwoKIExpY2Vuc2Vk
IHVuZGVyIHRoZSBBcGFjaGUgTGljZW5zZSwgVmVyc2lvbiAyLjAgKHRoZSAiTGljZW5zZSIp
OwogeW91IG1heSBub3QgdXNlIHRoaXMgZmlsZSBleGNlcHQgaW4gY29tcGxpYW5jZSB3aXRo
IHRoZSBMaWNlbnNlLgogWW91IG1heSBvYnRhaW4gYSBjb3B5IG9mIHRoZSBMaWNlbnNlIGF0
CgogICAgIGh0dHA6Ly93d3cuYXBhY2hlLm9yZy9saWNlbnNlcy9MSUNFTlNFLTIuMAoKIFVu
bGVzcyByZXF1aXJlZCBieSBhcHBsaWNhYmxlIGxhdyBvciBhZ3JlZWQgdG8gaW4gd3JpdGlu
Zywgc29mdHdhcmUKIGRpc3RyaWJ1dGVkIHVuZGVyIHRoZSBMaWNlbnNlIGlzIGRpc3RyaWJ1
dGVkIG9uIGFuICJBUyBJUyIgQkFTSVMsCiBXSVRIT1VUIFdBUlJBTlRJRVMgT1IgQ09ORElU
SU9OUyBPRiBBTlkgS0lORCwgZWl0aGVyIGV4cHJlc3Mgb3IgaW1wbGllZC4KIFNlZSB0aGUg
TGljZW5zZSBmb3IgdGhlIHNwZWNpZmljIGxhbmd1YWdlIGdvdmVybmluZyBwZXJtaXNzaW9u
cyBhbmQKIGxpbWl0YXRpb25zIHVuZGVyIHRoZSBMaWNlbnNlLgoKCAoBAhIDEAAgCggKAQgS
AxIANAoJCgIIJRIDEgA0CggKAQgSAxMATAoJCgIICxIDEwBMCggKAQgSAxQAIgoJCgIIChID
FAAiCggKAQgSAxUALwoJCgIICBIDFQAvCggKAQgSAxYANAoJCgIIARIDFgA0CggKAQgSAxcA
NAoJCgIIKRIDFwA0CggKAQgSAxgAMwoJCgIILRIDGAAzClMKAgQAEgQbACIBGkcgU3FsUmVz
dWx0IHJlcHJlc2VudHMgdGhlIHJlc3VsdCBmb3IgdGhlIGV4ZWN1dGlvbiBvZiBhIHNxbCBz
dGF0ZW1lbnQuCgoKCgMEAAESAxsIEQpnCgQEAAIAEgMeAicaWiBMaXN0IG9mIGNvbHVtbnMg
aW5jbHVkZWQgaW4gdGhlIHJlc3VsdC4gVGhpcyBhbHNvIGluY2x1ZGVzIHRoZSBkYXRhIHR5
cGUKIG9mIHRoZSBjb2x1bW4uCgoMCgUEAAIABBIDHgIKCgwKBQQAAgAGEgMeCxoKDAoFBAAC
AAESAx4bIgoMCgUEAAIAAxIDHiUmCjIKBAQAAgESAyECIRolIFJvd3MgcmV0dXJuZWQgYnkg
dGhlIFNRTCBzdGF0ZW1lbnQuCgoMCgUEAAIBBBIDIQIKCgwKBQQAAgEGEgMhCxcKDAoFBAAC
AQESAyEYHAoMCgUEAAIBAxIDIR8gCkkKAgQBEgQlAC0BGj0gQ29udGFpbnMgdGhlIG5hbWUg
YW5kIGRhdGF0eXBlIG9mIGEgY29sdW1uIGluIGEgU1FMIFJlc3VsdC4KCgoKAwQBARIDJQgX
CiIKBAQBAgASAycCEhoVIE5hbWUgb2YgdGhlIGNvbHVtbi4KCgwKBQQBAgAFEgMnAggKDAoF
BAECAAESAycJDQoMCgUEAQIAAxIDJxARCqkBCgQEAQIBEgMsAhIamwEgRGF0YXR5cGUgb2Yg
dGhlIGNvbHVtbiBhcyByZXBvcnRlZCBieSB0aGUgcG9zdGdyZXMgZHJpdmVyLgogQ29tbW9u
IHR5cGUgbmFtZXMgYXJlICJWQVJDSEFSIiwgIlRFWFQiLCAiTlZBUkNIQVIiLCAiREVDSU1B
TCIsICJCT09MIiwKICJJTlQiLCBhbmQgIkJJR0lOVCIuCgoMCgUEAQIBBRIDLAIICgwKBQQB
AgEBEgMsCQ0KDAoFBAECAQMSAywQEQotCgIEAhIEMAAzARohIEEgc2luZ2xlIHJvdyBmcm9t
IGEgc3FsIHJlc3VsdC4KCgoKAwQCARIDMAgUCjUKBAQCAgASAzICJRooIExpc3Qgb2YgdmFs
dWVzIGluIGEgcm93IG9mIHNxbCByZXN1bHQuCgoMCgUEAgIABBIDMgIKCgwKBQQCAgAGEgMy
CxkKDAoFBAICAAESAzIaIAoMCgUEAgIAAxIDMiMkCjgKAgQDEgQ2AD0BGiwgQSBzaW5nbGUg
dmFsdWUgaW4gYSByb3cgZnJvbSBhIHNxbCByZXN1bHQuCgoKCgMEAwESAzYIFgp5CgQEAwIA
EgM5AhwabCBUaGUgY2VsbCB2YWx1ZSByZXByZXNlbnRlZCBpbiBzdHJpbmcgZm9ybWF0Lgog
VGltZXN0YW1wcyBhcmUgY29udmVydGVkIHRvIHN0cmluZyB1c2luZyBSRkMzMzM5TmFubyBm
b3JtYXQuCgoMCgUEAwIABBIDOQIKCgwKBQQDAgAFEgM5CxEKDAoFBAMCAAESAzkSFwoMCgUE
AwIAAxIDORobCjEKBAQDAgESAzwCHxokIFNldCB0byB0cnVlIGlmIGNlbGwgdmFsdWUgaXMg
bnVsbC4KCgwKBQQDAgEEEgM8AgoKDAoFBAMCAQUSAzwLDwoMCgUEAwIBARIDPBAaCgwKBQQD
AgEDEgM8HR5iBnByb3RvMw==
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Alloydb::V1::DataModel::SqlResult ===
    # Fields for SqlResult
    # Field: columns Type: 11 (.google.cloud.alloydb.v1.SqlResultColumn)
    # Field: rows Type: 11 (.google.cloud.alloydb.v1.SqlResultRow)

# === Message: Google::Cloud::Alloydb::V1::DataModel::SqlResultColumn ===
    # Fields for SqlResultColumn
    # Field: name Type: 9 ()
    # Field: type Type: 9 ()

# === Message: Google::Cloud::Alloydb::V1::DataModel::SqlResultRow ===
    # Fields for SqlResultRow
    # Field: values Type: 11 (.google.cloud.alloydb.v1.SqlResultValue)

# === Message: Google::Cloud::Alloydb::V1::DataModel::SqlResultValue ===
    # Fields for SqlResultValue
    # Field: value Type: 9 ()
    # Field: null_value Type: 8 ()

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Alloydb::V1::DataModel - Compiled Protocol Buffers messages for google/cloud/alloydb/v1/data_model.proto

=head1 SYNOPSIS

    use Google::Cloud::Alloydb::V1::DataModel;

    my $msg = Google::Cloud::Alloydb::V1::DataModel::SqlResult->new({
        columns => $columns,
        rows => $rows,
    });

    # Read or update a field
    my $val = $msg->columns();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Alloydb::V1::DataModel::SqlResult->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/alloydb/v1/data_model.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Alloydb::V1::DataModel::SqlResult

SqlResult represents the result for the execution of a sql statement.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->columns() >> / C<< $msg->columns($value) >>

Type: C<Message> (L<Google::Cloud::Alloydb::V1::DataModel::SqlResultColumn>)

List of columns included in the result. This also includes the data type
of the column.

=item * C<< $msg->rows() >> / C<< $msg->rows($value) >>

Type: C<Message> (L<Google::Cloud::Alloydb::V1::DataModel::SqlResultRow>)

Rows returned by the SQL statement.

=back

=head2 Google::Cloud::Alloydb::V1::DataModel::SqlResultColumn

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

=head2 Google::Cloud::Alloydb::V1::DataModel::SqlResultRow

A single row from a sql result.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->values() >> / C<< $msg->values($value) >>

Type: C<Message> (L<Google::Cloud::Alloydb::V1::DataModel::SqlResultValue>)

List of values in a row of sql result.

=back

=head2 Google::Cloud::Alloydb::V1::DataModel::SqlResultValue

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

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Alloydb::V1::DataModel::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
