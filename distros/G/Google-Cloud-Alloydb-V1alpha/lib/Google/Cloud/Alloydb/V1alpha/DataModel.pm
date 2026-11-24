package Google::Cloud::Alloydb::V1alpha::DataModel;

use strict;
use warnings;

our $VERSION = '0.14';

use Protobuf::Message;
use Protobuf::DescriptorPool;
use Protobuf::Internal qw(:all);
use MIME::Base64;

BEGIN {
    my $descriptor_b64 = <<'EOF';
Ci1nb29nbGUvY2xvdWQvYWxsb3lkYi92MWFscGhhL2RhdGFfbW9kZWwucHJvdG8SHGdvb2ds
ZS5jbG91ZC5hbGxveWRiLnYxYWxwaGEilAEKCVNxbFJlc3VsdBJHCgdjb2x1bW5zGAEgAygL
Mi0uZ29vZ2xlLmNsb3VkLmFsbG95ZGIudjFhbHBoYS5TcWxSZXN1bHRDb2x1bW5SB2NvbHVt
bnMSPgoEcm93cxgCIAMoCzIqLmdvb2dsZS5jbG91ZC5hbGxveWRiLnYxYWxwaGEuU3FsUmVz
dWx0Um93UgRyb3dzIjkKD1NxbFJlc3VsdENvbHVtbhISCgRuYW1lGAEgASgJUgRuYW1lEhIK
BHR5cGUYAiABKAlSBHR5cGUiVAoMU3FsUmVzdWx0Um93EkQKBnZhbHVlcxgBIAMoCzIsLmdv
b2dsZS5jbG91ZC5hbGxveWRiLnYxYWxwaGEuU3FsUmVzdWx0VmFsdWVSBnZhbHVlcyJoCg5T
cWxSZXN1bHRWYWx1ZRIZCgV2YWx1ZRgBIAEoCUgAUgV2YWx1ZYgBARIiCgpudWxsX3ZhbHVl
GAIgASgISAFSCW51bGxWYWx1ZYgBAUIICgZfdmFsdWVCDQoLX251bGxfdmFsdWVC0AEKIGNv
bS5nb29nbGUuY2xvdWQuYWxsb3lkYi52MWFscGhhQg5EYXRhTW9kZWxQcm90b1ABWjpjbG91
ZC5nb29nbGUuY29tL2dvL2FsbG95ZGIvYXBpdjFhbHBoYS9hbGxveWRicGI7YWxsb3lkYnBi
qgIcR29vZ2xlLkNsb3VkLkFsbG95RGIuVjFBbHBoYcoCHEdvb2dsZVxDbG91ZFxBbGxveURi
XFYxYWxwaGHqAh9Hb29nbGU6OkNsb3VkOjpBbGxveURCOjpWMWFscGhhStsPCgYSBA4APQEK
vAQKAQwSAw4AEjKxBCBDb3B5cmlnaHQgMjAyNSBHb29nbGUgTExDCgogTGljZW5zZWQgdW5k
ZXIgdGhlIEFwYWNoZSBMaWNlbnNlLCBWZXJzaW9uIDIuMCAodGhlICJMaWNlbnNlIik7CiB5
b3UgbWF5IG5vdCB1c2UgdGhpcyBmaWxlIGV4Y2VwdCBpbiBjb21wbGlhbmNlIHdpdGggdGhl
IExpY2Vuc2UuCiBZb3UgbWF5IG9idGFpbiBhIGNvcHkgb2YgdGhlIExpY2Vuc2UgYXQKCiAg
ICAgaHR0cDovL3d3dy5hcGFjaGUub3JnL2xpY2Vuc2VzL0xJQ0VOU0UtMi4wCgogVW5sZXNz
IHJlcXVpcmVkIGJ5IGFwcGxpY2FibGUgbGF3IG9yIGFncmVlZCB0byBpbiB3cml0aW5nLCBz
b2Z0d2FyZQogZGlzdHJpYnV0ZWQgdW5kZXIgdGhlIExpY2Vuc2UgaXMgZGlzdHJpYnV0ZWQg
b24gYW4gIkFTIElTIiBCQVNJUywKIFdJVEhPVVQgV0FSUkFOVElFUyBPUiBDT05ESVRJT05T
IE9GIEFOWSBLSU5ELCBlaXRoZXIgZXhwcmVzcyBvciBpbXBsaWVkLgogU2VlIHRoZSBMaWNl
bnNlIGZvciB0aGUgc3BlY2lmaWMgbGFuZ3VhZ2UgZ292ZXJuaW5nIHBlcm1pc3Npb25zIGFu
ZAogbGltaXRhdGlvbnMgdW5kZXIgdGhlIExpY2Vuc2UuCgoICgECEgMQACUKCAoBCBIDEgA5
CgkKAgglEgMSADkKCAoBCBIDEwBRCgkKAggLEgMTAFEKCAoBCBIDFAAiCgkKAggKEgMUACIK
CAoBCBIDFQAvCgkKAggIEgMVAC8KCAoBCBIDFgA5CgkKAggBEgMWADkKCAoBCBIDFwA5CgkK
AggpEgMXADkKCAoBCBIDGAA4CgkKAggtEgMYADgKUwoCBAASBBsAIgEaRyBTcWxSZXN1bHQg
cmVwcmVzZW50cyB0aGUgcmVzdWx0IGZvciB0aGUgZXhlY3V0aW9uIG9mIGEgc3FsIHN0YXRl
bWVudC4KCgoKAwQAARIDGwgRCmcKBAQAAgASAx4CJxpaIExpc3Qgb2YgY29sdW1ucyBpbmNs
dWRlZCBpbiB0aGUgcmVzdWx0LiBUaGlzIGFsc28gaW5jbHVkZXMgdGhlIGRhdGEgdHlwZQog
b2YgdGhlIGNvbHVtbi4KCgwKBQQAAgAEEgMeAgoKDAoFBAACAAYSAx4LGgoMCgUEAAIAARID
HhsiCgwKBQQAAgADEgMeJSYKMgoEBAACARIDIQIhGiUgUm93cyByZXR1cm5lZCBieSB0aGUg
U1FMIHN0YXRlbWVudC4KCgwKBQQAAgEEEgMhAgoKDAoFBAACAQYSAyELFwoMCgUEAAIBARID
IRgcCgwKBQQAAgEDEgMhHyAKSQoCBAESBCUALQEaPSBDb250YWlucyB0aGUgbmFtZSBhbmQg
ZGF0YXR5cGUgb2YgYSBjb2x1bW4gaW4gYSBTUUwgUmVzdWx0LgoKCgoDBAEBEgMlCBcKIgoE
BAECABIDJwISGhUgTmFtZSBvZiB0aGUgY29sdW1uLgoKDAoFBAECAAUSAycCCAoMCgUEAQIA
ARIDJwkNCgwKBQQBAgADEgMnEBEKqQEKBAQBAgESAywCEhqbASBEYXRhdHlwZSBvZiB0aGUg
Y29sdW1uIGFzIHJlcG9ydGVkIGJ5IHRoZSBwb3N0Z3JlcyBkcml2ZXIuCiBDb21tb24gdHlw
ZSBuYW1lcyBhcmUgIlZBUkNIQVIiLCAiVEVYVCIsICJOVkFSQ0hBUiIsICJERUNJTUFMIiwg
IkJPT0wiLAogIklOVCIsIGFuZCAiQklHSU5UIi4KCgwKBQQBAgEFEgMsAggKDAoFBAECAQES
AywJDQoMCgUEAQIBAxIDLBARCi0KAgQCEgQwADMBGiEgQSBzaW5nbGUgcm93IGZyb20gYSBz
cWwgcmVzdWx0LgoKCgoDBAIBEgMwCBQKNQoEBAICABIDMgIlGiggTGlzdCBvZiB2YWx1ZXMg
aW4gYSByb3cgb2Ygc3FsIHJlc3VsdC4KCgwKBQQCAgAEEgMyAgoKDAoFBAICAAYSAzILGQoM
CgUEAgIAARIDMhogCgwKBQQCAgADEgMyIyQKOAoCBAMSBDYAPQEaLCBBIHNpbmdsZSB2YWx1
ZSBpbiBhIHJvdyBmcm9tIGEgc3FsIHJlc3VsdC4KCgoKAwQDARIDNggWCnkKBAQDAgASAzkC
HBpsIFRoZSBjZWxsIHZhbHVlIHJlcHJlc2VudGVkIGluIHN0cmluZyBmb3JtYXQuCiBUaW1l
c3RhbXBzIGFyZSBjb252ZXJ0ZWQgdG8gc3RyaW5nIHVzaW5nIFJGQzMzMzlOYW5vIGZvcm1h
dC4KCgwKBQQDAgAEEgM5AgoKDAoFBAMCAAUSAzkLEQoMCgUEAwIAARIDORIXCgwKBQQDAgAD
EgM5GhsKMQoEBAMCARIDPAIfGiQgU2V0IHRvIHRydWUgaWYgY2VsbCB2YWx1ZSBpcyBudWxs
LgoKDAoFBAMCAQQSAzwCCgoMCgUEAwIBBRIDPAsPCgwKBQQDAgEBEgM8EBoKDAoFBAMCAQMS
AzwdHmIGcHJvdG8z
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Alloydb::V1alpha::DataModel::SqlResult ===
    # Fields for SqlResult
    # Field: columns Type: 11 (.google.cloud.alloydb.v1alpha.SqlResultColumn)
    # Field: rows Type: 11 (.google.cloud.alloydb.v1alpha.SqlResultRow)

# === Message: Google::Cloud::Alloydb::V1alpha::DataModel::SqlResultColumn ===
    # Fields for SqlResultColumn
    # Field: name Type: 9 ()
    # Field: type Type: 9 ()

# === Message: Google::Cloud::Alloydb::V1alpha::DataModel::SqlResultRow ===
    # Fields for SqlResultRow
    # Field: values Type: 11 (.google.cloud.alloydb.v1alpha.SqlResultValue)

# === Message: Google::Cloud::Alloydb::V1alpha::DataModel::SqlResultValue ===
    # Fields for SqlResultValue
    # Field: value Type: 9 ()
    # Field: null_value Type: 8 ()

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Alloydb::V1alpha::DataModel - Compiled Protocol Buffers messages for google/cloud/alloydb/v1alpha/data_model.proto

=head1 SYNOPSIS

    use Google::Cloud::Alloydb::V1alpha::DataModel;

    my $msg = Google::Cloud::Alloydb::V1alpha::DataModel::SqlResult->new({
        columns => $columns,
        rows => $rows,
    });

    # Read or update a field
    my $val = $msg->columns();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Alloydb::V1alpha::DataModel::SqlResult->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/alloydb/v1alpha/data_model.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Alloydb::V1alpha::DataModel::SqlResult

SqlResult represents the result for the execution of a sql statement.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->columns() >> / C<< $msg->columns($value) >>

Type: C<Message> (L<Google::Cloud::Alloydb::V1alpha::DataModel::SqlResultColumn>)

List of columns included in the result. This also includes the data type
of the column.

=item * C<< $msg->rows() >> / C<< $msg->rows($value) >>

Type: C<Message> (L<Google::Cloud::Alloydb::V1alpha::DataModel::SqlResultRow>)

Rows returned by the SQL statement.

=back

=head2 Google::Cloud::Alloydb::V1alpha::DataModel::SqlResultColumn

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

=head2 Google::Cloud::Alloydb::V1alpha::DataModel::SqlResultRow

A single row from a sql result.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->values() >> / C<< $msg->values($value) >>

Type: C<Message> (L<Google::Cloud::Alloydb::V1alpha::DataModel::SqlResultValue>)

List of values in a row of sql result.

=back

=head2 Google::Cloud::Alloydb::V1alpha::DataModel::SqlResultValue

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

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Alloydb::V1alpha::DataModel::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
