package Google::Cloud::Datacatalog::V1::Bigquery;

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
Cipnb29nbGUvY2xvdWQvZGF0YWNhdGFsb2cvdjEvYmlncXVlcnkucHJvdG8SG2dvb2dsZS5j
bG91ZC5kYXRhY2F0YWxvZy52MRofZ29vZ2xlL2FwaS9maWVsZF9iZWhhdmlvci5wcm90byLd
AgoWQmlnUXVlcnlDb25uZWN0aW9uU3BlYxJrCg9jb25uZWN0aW9uX3R5cGUYASABKA4yQi5n
b29nbGUuY2xvdWQuZGF0YWNhdGFsb2cudjEuQmlnUXVlcnlDb25uZWN0aW9uU3BlYy5Db25u
ZWN0aW9uVHlwZVIOY29ubmVjdGlvblR5cGUSWgoJY2xvdWRfc3FsGAIgASgLMjsuZ29vZ2xl
LmNsb3VkLmRhdGFjYXRhbG9nLnYxLkNsb3VkU3FsQmlnUXVlcnlDb25uZWN0aW9uU3BlY0gA
UghjbG91ZFNxbBIlCg5oYXNfY3JlZGVudGlhbBgDIAEoCFINaGFzQ3JlZGVudGlhbCJACg5D
b25uZWN0aW9uVHlwZRIfChtDT05ORUNUSU9OX1RZUEVfVU5TUEVDSUZJRUQQABINCglDTE9V
RF9TUUwQAUIRCg9jb25uZWN0aW9uX3NwZWMigwIKHkNsb3VkU3FsQmlnUXVlcnlDb25uZWN0
aW9uU3BlYxIfCgtpbnN0YW5jZV9pZBgBIAEoCVIKaW5zdGFuY2VJZBIaCghkYXRhYmFzZRgC
IAEoCVIIZGF0YWJhc2USXAoEdHlwZRgDIAEoDjJILmdvb2dsZS5jbG91ZC5kYXRhY2F0YWxv
Zy52MS5DbG91ZFNxbEJpZ1F1ZXJ5Q29ubmVjdGlvblNwZWMuRGF0YWJhc2VUeXBlUgR0eXBl
IkYKDERhdGFiYXNlVHlwZRIdChlEQVRBQkFTRV9UWVBFX1VOU1BFQ0lGSUVEEAASDAoIUE9T
VEdSRVMQARIJCgVNWVNRTBACIkQKE0JpZ1F1ZXJ5Um91dGluZVNwZWMSLQoSaW1wb3J0ZWRf
bGlicmFyaWVzGAEgAygJUhFpbXBvcnRlZExpYnJhcmllc0LSAQofY29tLmdvb2dsZS5jbG91
ZC5kYXRhY2F0YWxvZy52MUINQmlnUXVlcnlQcm90b1ABWkFjbG91ZC5nb29nbGUuY29tL2dv
L2RhdGFjYXRhbG9nL2FwaXYxL2RhdGFjYXRhbG9ncGI7ZGF0YWNhdGFsb2dwYqoCG0dvb2ds
ZS5DbG91ZC5EYXRhQ2F0YWxvZy5WMcoCG0dvb2dsZVxDbG91ZFxEYXRhQ2F0YWxvZ1xWMeoC
Hkdvb2dsZTo6Q2xvdWQ6OkRhdGFDYXRhbG9nOjpWMUrZEQoGEgQOAFABCrwECgEMEgMOABIy
sQQgQ29weXJpZ2h0IDIwMjUgR29vZ2xlIExMQwoKIExpY2Vuc2VkIHVuZGVyIHRoZSBBcGFj
aGUgTGljZW5zZSwgVmVyc2lvbiAyLjAgKHRoZSAiTGljZW5zZSIpOwogeW91IG1heSBub3Qg
dXNlIHRoaXMgZmlsZSBleGNlcHQgaW4gY29tcGxpYW5jZSB3aXRoIHRoZSBMaWNlbnNlLgog
WW91IG1heSBvYnRhaW4gYSBjb3B5IG9mIHRoZSBMaWNlbnNlIGF0CgogICAgIGh0dHA6Ly93
d3cuYXBhY2hlLm9yZy9saWNlbnNlcy9MSUNFTlNFLTIuMAoKIFVubGVzcyByZXF1aXJlZCBi
eSBhcHBsaWNhYmxlIGxhdyBvciBhZ3JlZWQgdG8gaW4gd3JpdGluZywgc29mdHdhcmUKIGRp
c3RyaWJ1dGVkIHVuZGVyIHRoZSBMaWNlbnNlIGlzIGRpc3RyaWJ1dGVkIG9uIGFuICJBUyBJ
UyIgQkFTSVMsCiBXSVRIT1VUIFdBUlJBTlRJRVMgT1IgQ09ORElUSU9OUyBPRiBBTlkgS0lO
RCwgZWl0aGVyIGV4cHJlc3Mgb3IgaW1wbGllZC4KIFNlZSB0aGUgTGljZW5zZSBmb3IgdGhl
IHNwZWNpZmljIGxhbmd1YWdlIGdvdmVybmluZyBwZXJtaXNzaW9ucyBhbmQKIGxpbWl0YXRp
b25zIHVuZGVyIHRoZSBMaWNlbnNlLgoKCAoBAhIDEAAkCgkKAgMAEgMSACkKCAoBCBIDFAA4
CgkKAgglEgMUADgKCAoBCBIDFQBYCgkKAggLEgMVAFgKCAoBCBIDFgAiCgkKAggKEgMWACIK
CAoBCBIDFwAuCgkKAggIEgMXAC4KCAoBCBIDGAA4CgkKAggBEgMYADgKCAoBCBIDGQA4CgkK
AggpEgMZADgKCAoBCBIDGgA3CgkKAggtEgMaADcKOAoCBAASBB0AMgEaLCBTcGVjaWZpY2F0
aW9uIGZvciB0aGUgQmlnUXVlcnkgY29ubmVjdGlvbi4KCgoKAwQAARIDHQgeCjQKBAQABAAS
BB8CJQMaJiBUaGUgdHlwZSBvZiB0aGUgQmlnUXVlcnkgY29ubmVjdGlvbi4KCgwKBQQABAAB
EgMfBxUKIgoGBAAEAAIAEgMhBCQaEyBVbnNwZWNpZmllZCB0eXBlLgoKDgoHBAAEAAIAARID
IQQfCg4KBwQABAACAAISAyEiIwomCgYEAAQAAgESAyQEEhoXIENsb3VkIFNRTCBjb25uZWN0
aW9uLgoKDgoHBAAEAAIBARIDJAQNCg4KBwQABAACAQISAyQQEQozCgQEAAIAEgMoAiUaJiBU
aGUgdHlwZSBvZiB0aGUgQmlnUXVlcnkgY29ubmVjdGlvbi4KCgwKBQQAAgAGEgMoAhAKDAoF
BAACAAESAygRIAoMCgUEAAIAAxIDKCMkCgwKBAQACAASBCoCLQMKDAoFBAAIAAESAyoIFwpR
CgQEAAIBEgMsBDEaRCBTcGVjaWZpY2F0aW9uIGZvciB0aGUgQmlnUXVlcnkgY29ubmVjdGlv
biB0byBhIENsb3VkIFNRTCBpbnN0YW5jZS4KCgwKBQQAAgEGEgMsBCIKDAoFBAACAQESAywj
LAoMCgUEAAIBAxIDLC8wCmMKBAQAAgISAzECGhpWIFRydWUgaWYgdGhlcmUgYXJlIGNyZWRl
bnRpYWxzIGF0dGFjaGVkIHRvIHRoZSBCaWdRdWVyeSBjb25uZWN0aW9uOyBmYWxzZQogb3Ro
ZXJ3aXNlLgoKDAoFBAACAgUSAzECBgoMCgUEAAICARIDMQcVCgwKBQQAAgIDEgMxGBkKUAoC
BAESBDUASgEaRCBTcGVjaWZpY2F0aW9uIGZvciB0aGUgQmlnUXVlcnkgY29ubmVjdGlvbiB0
byBhIENsb3VkIFNRTCBpbnN0YW5jZS4KCgoKAwQBARIDNQgmCjMKBAQBBAASBDcCQAMaJSBT
dXBwb3J0ZWQgQ2xvdWQgU1FMIGRhdGFiYXNlIHR5cGVzLgoKDAoFBAEEAAESAzcHEworCgYE
AQQAAgASAzkEIhocIFVuc3BlY2lmaWVkIGRhdGFiYXNlIHR5cGUuCgoOCgcEAQQAAgABEgM5
BB0KDgoHBAEEAAIAAhIDOSAhCioKBgQBBAACARIDPAQRGhsgQ2xvdWQgU1FMIGZvciBQb3N0
Z3JlU1FMLgoKDgoHBAEEAAIBARIDPAQMCg4KBwQBBAACAQISAzwPEAolCgYEAQQAAgISAz8E
DhoWIENsb3VkIFNRTCBmb3IgTXlTUUwuCgoOCgcEAQQAAgIBEgM/BAkKDgoHBAEEAAICAhID
PwwNClIKBAQBAgASA0MCGRpFIENsb3VkIFNRTCBpbnN0YW5jZSBJRCBpbiB0aGUgZm9ybWF0
IG9mIGBwcm9qZWN0OmxvY2F0aW9uOmluc3RhbmNlYC4KCgwKBQQBAgAFEgNDAggKDAoFBAEC
AAESA0MJFAoMCgUEAQIAAxIDQxcYCh0KBAQBAgESA0YCFhoQIERhdGFiYXNlIG5hbWUuCgoM
CgUEAQIBBRIDRgIICgwKBQQBAgEBEgNGCREKDAoFBAECAQMSA0YUFQouCgQEAQICEgNJAhga
ISBUeXBlIG9mIHRoZSBDbG91ZCBTUUwgZGF0YWJhc2UuCgoMCgUEAQICBhIDSQIOCgwKBQQB
AgIBEgNJDxMKDAoFBAECAgMSA0kWFwo0CgIEAhIETQBQARooIEZpZWxkcyBzcGVjaWZpYyBm
b3IgQmlnUXVlcnkgcm91dGluZXMuCgoKCgMEAgESA00IGwovCgQEAgIAEgNPAikaIiBQYXRo
cyBvZiB0aGUgaW1wb3J0ZWQgbGlicmFyaWVzLgoKDAoFBAICAAQSA08CCgoMCgUEAgIABRID
TwsRCgwKBQQCAgABEgNPEiQKDAoFBAICAAMSA08nKGIGcHJvdG8z
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Datacatalog::V1::Bigquery::BigQueryConnectionSpec ===
    # Fields for BigQueryConnectionSpec
    # Field: connection_type Type: 14 (.google.cloud.datacatalog.v1.BigQueryConnectionSpec.ConnectionType)
    # Field: cloud_sql Type: 11 (.google.cloud.datacatalog.v1.CloudSqlBigQueryConnectionSpec)
    # Field: has_credential Type: 8 ()

# Enum: BigQueryConnectionSpec::ConnectionType
our $BigQueryConnectionSpec_CONNECTION_TYPE_UNSPECIFIED = 0;
our $BigQueryConnectionSpec_CLOUD_SQL = 1;

# === Message: Google::Cloud::Datacatalog::V1::Bigquery::CloudSqlBigQueryConnectionSpec ===
    # Fields for CloudSqlBigQueryConnectionSpec
    # Field: instance_id Type: 9 ()
    # Field: database Type: 9 ()
    # Field: type Type: 14 (.google.cloud.datacatalog.v1.CloudSqlBigQueryConnectionSpec.DatabaseType)

# Enum: CloudSqlBigQueryConnectionSpec::DatabaseType
our $CloudSqlBigQueryConnectionSpec_DATABASE_TYPE_UNSPECIFIED = 0;
our $CloudSqlBigQueryConnectionSpec_POSTGRES = 1;
our $CloudSqlBigQueryConnectionSpec_MYSQL = 2;

# === Message: Google::Cloud::Datacatalog::V1::Bigquery::BigQueryRoutineSpec ===
    # Fields for BigQueryRoutineSpec
    # Field: imported_libraries Type: 9 ()

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Datacatalog::V1::Bigquery - Compiled Protocol Buffers messages for google/cloud/datacatalog/v1/bigquery.proto

=head1 SYNOPSIS

    use Google::Cloud::Datacatalog::V1::Bigquery;

    my $msg = Google::Cloud::Datacatalog::V1::Bigquery::BigQueryConnectionSpec->new({
        connection_type => $connection_type,
        cloud_sql => $cloud_sql,
        has_credential => $has_credential,
    });

    # Read or update a field
    my $val = $msg->connection_type();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Datacatalog::V1::Bigquery::BigQueryConnectionSpec->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/datacatalog/v1/bigquery.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Datacatalog::V1::Bigquery::BigQueryConnectionSpec

Specification for the BigQuery connection.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->connection_type() >> / C<< $msg->connection_type($value) >>

Type: C<Enum> (L<Google::Cloud::Datacatalog::V1::BigQueryConnectionSpec::ConnectionType>)

The type of the BigQuery connection.

=item * C<< $msg->cloud_sql() >> / C<< $msg->cloud_sql($value) >>

Type: C<Message> (L<Google::Cloud::Datacatalog::V1::Bigquery::CloudSqlBigQueryConnectionSpec>)

Specification for the BigQuery connection to a Cloud SQL instance.

=item * C<< $msg->has_credential() >> / C<< $msg->has_credential($value) >>

Type: C<Bool>

True if there are credentials attached to the BigQuery connection; false
otherwise.

=back

=head3 Enum: BigQueryConnectionSpec::ConnectionType

=over 4

=item * C<CONNECTION_TYPE_UNSPECIFIED> => C<0>

=item * C<CLOUD_SQL> => C<1>

=back

=head2 Google::Cloud::Datacatalog::V1::Bigquery::CloudSqlBigQueryConnectionSpec

Specification for the BigQuery connection to a Cloud SQL instance.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->instance_id() >> / C<< $msg->instance_id($value) >>

Type: C<String>

Cloud SQL instance ID in the format of `project:location:instance`.

=item * C<< $msg->database() >> / C<< $msg->database($value) >>

Type: C<String>

Database name.

=item * C<< $msg->type() >> / C<< $msg->type($value) >>

Type: C<Enum> (L<Google::Cloud::Datacatalog::V1::CloudSqlBigQueryConnectionSpec::DatabaseType>)

Type of the Cloud SQL database.

=back

=head3 Enum: CloudSqlBigQueryConnectionSpec::DatabaseType

=over 4

=item * C<DATABASE_TYPE_UNSPECIFIED> => C<0>

=item * C<POSTGRES> => C<1>

=item * C<MYSQL> => C<2>

=back

=head2 Google::Cloud::Datacatalog::V1::Bigquery::BigQueryRoutineSpec

Fields specific for BigQuery routines.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->imported_libraries() >> / C<< $msg->imported_libraries($value) >>

Type: C<String>

Paths of the imported libraries.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Datacatalog::V1::Bigquery::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
