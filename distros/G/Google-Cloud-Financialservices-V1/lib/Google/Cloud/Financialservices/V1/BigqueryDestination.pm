package Google::Cloud::Financialservices::V1::BigqueryDestination;

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
Cjxnb29nbGUvY2xvdWQvZmluYW5jaWFsc2VydmljZXMvdjEvYmlncXVlcnlfZGVzdGluYXRp
b24ucHJvdG8SIWdvb2dsZS5jbG91ZC5maW5hbmNpYWxzZXJ2aWNlcy52MRofZ29vZ2xlL2Fw
aS9maWVsZF9iZWhhdmlvci5wcm90byKOAgoTQmlnUXVlcnlEZXN0aW5hdGlvbhIgCgl0YWJs
ZV91cmkYASABKAlCA+BBAVIIdGFibGVVcmkSeQoRd3JpdGVfZGlzcG9zaXRpb24YAiABKA4y
Ry5nb29nbGUuY2xvdWQuZmluYW5jaWFsc2VydmljZXMudjEuQmlnUXVlcnlEZXN0aW5hdGlv
bi5Xcml0ZURpc3Bvc2l0aW9uQgPgQQJSEHdyaXRlRGlzcG9zaXRpb24iWgoQV3JpdGVEaXNw
b3NpdGlvbhIhCh1XUklURV9ESVNQT1NJVElPTl9VTlNQRUNJRklFRBAAEg8KC1dSSVRFX0VN
UFRZEAESEgoOV1JJVEVfVFJVTkNBVEUQAkKHAgolY29tLmdvb2dsZS5jbG91ZC5maW5hbmNp
YWxzZXJ2aWNlcy52MUIYQmlnUXVlcnlEZXN0aW5hdGlvblByb3RvUAFaU2Nsb3VkLmdvb2ds
ZS5jb20vZ28vZmluYW5jaWFsc2VydmljZXMvYXBpdjEvZmluYW5jaWFsc2VydmljZXNwYjtm
aW5hbmNpYWxzZXJ2aWNlc3BiqgIhR29vZ2xlLkNsb3VkLkZpbmFuY2lhbFNlcnZpY2VzLlYx
ygIhR29vZ2xlXENsb3VkXEZpbmFuY2lhbFNlcnZpY2VzXFYx6gIkR29vZ2xlOjpDbG91ZDo6
RmluYW5jaWFsU2VydmljZXM6OlYxSpIOCgYSBA4ANgEKvAQKAQwSAw4AEjKxBCBDb3B5cmln
aHQgMjAyNSBHb29nbGUgTExDCgogTGljZW5zZWQgdW5kZXIgdGhlIEFwYWNoZSBMaWNlbnNl
LCBWZXJzaW9uIDIuMCAodGhlICJMaWNlbnNlIik7CiB5b3UgbWF5IG5vdCB1c2UgdGhpcyBm
aWxlIGV4Y2VwdCBpbiBjb21wbGlhbmNlIHdpdGggdGhlIExpY2Vuc2UuCiBZb3UgbWF5IG9i
dGFpbiBhIGNvcHkgb2YgdGhlIExpY2Vuc2UgYXQKCiAgICAgaHR0cDovL3d3dy5hcGFjaGUu
b3JnL2xpY2Vuc2VzL0xJQ0VOU0UtMi4wCgogVW5sZXNzIHJlcXVpcmVkIGJ5IGFwcGxpY2Fi
bGUgbGF3IG9yIGFncmVlZCB0byBpbiB3cml0aW5nLCBzb2Z0d2FyZQogZGlzdHJpYnV0ZWQg
dW5kZXIgdGhlIExpY2Vuc2UgaXMgZGlzdHJpYnV0ZWQgb24gYW4gIkFTIElTIiBCQVNJUywK
IFdJVEhPVVQgV0FSUkFOVElFUyBPUiBDT05ESVRJT05TIE9GIEFOWSBLSU5ELCBlaXRoZXIg
ZXhwcmVzcyBvciBpbXBsaWVkLgogU2VlIHRoZSBMaWNlbnNlIGZvciB0aGUgc3BlY2lmaWMg
bGFuZ3VhZ2UgZ292ZXJuaW5nIHBlcm1pc3Npb25zIGFuZAogbGltaXRhdGlvbnMgdW5kZXIg
dGhlIExpY2Vuc2UuCgoICgECEgMQACoKCQoCAwASAxIAKQoICgEIEgMUAD4KCQoCCCUSAxQA
PgoICgEIEgMVAGoKCQoCCAsSAxUAagoICgEIEgMWACIKCQoCCAoSAxYAIgoICgEIEgMXADkK
CQoCCAgSAxcAOQoICgEIEgMYAD4KCQoCCAESAxgAPgoICgEIEgMZAD4KCQoCCCkSAxkAPgoI
CgEIEgMaAD0KCQoCCC0SAxoAPQpPCgIEABIEHQA2ARpDIEJpZ1F1ZXJ5RGVzdGluYXRpb24g
aXMgYSB3cmFwcGVyIGZvciBCaWdRdWVyeSBvdXRwdXQgaW5mb3JtYXRpb24uCgoKCgMEAAES
Ax0IGwpiCgQEAAQAEgQgAikDGlQgV3JpdGVEaXNwb3NpdGlvbiBjb250cm9scyB0aGUgYmVo
YXZpb3Igd2hlbiB0aGUgZGVzdGluYXRpb24gdGFibGUgYWxyZWFkeQogZXhpc3RzLgoKDAoF
BAAEAAESAyAHFwo9CgYEAAQAAgASAyIEJhouIERlZmF1bHQgYmVoYXZpb3IgaXMgdGhlIHNh
bWUgYXMgV1JJVEVfRU1QVFkuCgoOCgcEAAQAAgABEgMiBCEKDgoHBAAEAAIAAhIDIiQlClUK
BgQABAACARIDJQQUGkYgSWYgdGhlIHRhYmxlIGFscmVhZHkgZXhpc3RzIGFuZCBjb250YWlu
cyBkYXRhLCBhbiBlcnJvciBpcyByZXR1cm5lZC4KCg4KBwQABAACAQESAyUEDwoOCgcEAAQA
AgECEgMlEhMKSwoGBAAEAAICEgMoBBcaPCBJZiB0aGUgdGFibGUgYWxyZWFkeSBleGlzdHMs
IHRoZSBkYXRhIHdpbGwgYmUgb3ZlcndyaXR0ZW4uCgoOCgcEAAQAAgIBEgMoBBIKDgoHBAAE
AAICAhIDKBUWCrsBCgQEAAIAEgMvAkAarQEgT3B0aW9uYWwuIEJpZ1F1ZXJ5IFVSSSB0byBh
IHRhYmxlLCBtdXN0IGJlIG9mIHRoZSBmb3JtCiBicTovL3Byb2plY3RJZC5icURhdGFzZXRJ
ZC50YWJsZUlkLgogTm90ZSB0aGF0IHRoZSBCaWdRdWVyeSBkYXRhc2V0IG11c3QgYWxyZWFk
eSBleGlzdC4KIFZQQy1TQyByZXN0cmljdGlvbnMgYXBwbHkuCgoMCgUEAAIABRIDLwIICgwK
BQQAAgABEgMvCRIKDAoFBAACAAMSAy8VFgoMCgUEAAIACBIDLxc/Cg8KCAQAAgAInAgAEgMv
GD4KvgEKBAQAAgESBDQCNS8arwEgUmVxdWlyZWQuIFdoZXRoZXIgb3Igbm90IHRvIG92ZXJ3
cml0ZSB0aGUgZGVzdGluYXRpb24gdGFibGUuIEJ5IGRlZmF1bHQgdGhlCiB0YWJsZSB3b24n
dCBiZSBvdmVyd3JpdHRlbiBhbmQgYW4gZXJyb3Igd2lsbCBiZSByZXR1cm5lZCBpZiB0aGUg
dGFibGUKIGV4aXN0cyBhbmQgY29udGFpbnMgZGF0YS4KCgwKBQQAAgEGEgM0AhIKDAoFBAAC
AQESAzQTJAoMCgUEAAIBAxIDNCcoCgwKBQQAAgEIEgM1Bi4KDwoIBAACAQicCAASAzUHLWIG
cHJvdG8z
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Financialservices::V1::BigqueryDestination::BigQueryDestination ===
    # Fields for BigQueryDestination
    # Field: table_uri Type: 9 ()
    # Field: write_disposition Type: 14 (.google.cloud.financialservices.v1.BigQueryDestination.WriteDisposition)

# Enum: BigQueryDestination::WriteDisposition
our $BigQueryDestination_WRITE_DISPOSITION_UNSPECIFIED = 0;
our $BigQueryDestination_WRITE_EMPTY = 1;
our $BigQueryDestination_WRITE_TRUNCATE = 2;

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Financialservices::V1::BigqueryDestination - Compiled Protocol Buffers messages for google/cloud/financialservices/v1/bigquery_destination.proto

=head1 SYNOPSIS

    use Google::Cloud::Financialservices::V1::BigqueryDestination;

    my $msg = Google::Cloud::Financialservices::V1::BigqueryDestination::BigQueryDestination->new({
        table_uri => $table_uri,
        write_disposition => $write_disposition,
    });

    # Read or update a field
    my $val = $msg->table_uri();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Financialservices::V1::BigqueryDestination::BigQueryDestination->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/financialservices/v1/bigquery_destination.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Financialservices::V1::BigqueryDestination::BigQueryDestination

BigQueryDestination is a wrapper for BigQuery output information.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->table_uri() >> / C<< $msg->table_uri($value) >>

Type: C<String>

Optional. BigQuery URI to a table, must be of the form
bq://projectId.bqDatasetId.tableId.
Note that the BigQuery dataset must already exist.
VPC-SC restrictions apply.

=item * C<< $msg->write_disposition() >> / C<< $msg->write_disposition($value) >>

Type: C<Enum> (L<Google::Cloud::Financialservices::V1::BigQueryDestination::WriteDisposition>)

Required. Whether or not to overwrite the destination table. By default the
table won't be overwritten and an error will be returned if the table
exists and contains data.

=back

=head3 Enum: BigQueryDestination::WriteDisposition

=over 4

=item * C<WRITE_DISPOSITION_UNSPECIFIED> => C<0>

=item * C<WRITE_EMPTY> => C<1>

=item * C<WRITE_TRUNCATE> => C<2>

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Financialservices::V1::BigqueryDestination::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
