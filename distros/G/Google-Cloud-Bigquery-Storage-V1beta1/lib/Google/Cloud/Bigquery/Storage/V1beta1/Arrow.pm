package Google::Cloud::Bigquery::Storage::V1beta1::Arrow;

use strict;
use warnings;

our $VERSION = '0.14';

use Protobuf::Message;
use Protobuf::DescriptorPool;
use Protobuf::Internal qw(:all);
use MIME::Base64;

BEGIN {
    my $descriptor_b64 = <<'EOF';
CjFnb29nbGUvY2xvdWQvYmlncXVlcnkvc3RvcmFnZS92MWJldGExL2Fycm93LnByb3RvEiVn
b29nbGUuY2xvdWQuYmlncXVlcnkuc3RvcmFnZS52MWJldGExIjoKC0Fycm93U2NoZW1hEisK
EXNlcmlhbGl6ZWRfc2NoZW1hGAEgASgMUhBzZXJpYWxpemVkU2NoZW1hImcKEEFycm93UmVj
b3JkQmF0Y2gSNgoXc2VyaWFsaXplZF9yZWNvcmRfYmF0Y2gYASABKAxSFXNlcmlhbGl6ZWRS
ZWNvcmRCYXRjaBIbCglyb3dfY291bnQYAiABKANSCHJvd0NvdW50QnwKKWNvbS5nb29nbGUu
Y2xvdWQuYmlncXVlcnkuc3RvcmFnZS52MWJldGExQgpBcnJvd1Byb3RvWkNjbG91ZC5nb29n
bGUuY29tL2dvL2JpZ3F1ZXJ5L3N0b3JhZ2UvYXBpdjFiZXRhMS9zdG9yYWdlcGI7c3RvcmFn
ZXBiSv4HCgYSBA4AIwEKvAQKAQwSAw4AEjKxBCBDb3B5cmlnaHQgMjAyNSBHb29nbGUgTExD
CgogTGljZW5zZWQgdW5kZXIgdGhlIEFwYWNoZSBMaWNlbnNlLCBWZXJzaW9uIDIuMCAodGhl
ICJMaWNlbnNlIik7CiB5b3UgbWF5IG5vdCB1c2UgdGhpcyBmaWxlIGV4Y2VwdCBpbiBjb21w
bGlhbmNlIHdpdGggdGhlIExpY2Vuc2UuCiBZb3UgbWF5IG9idGFpbiBhIGNvcHkgb2YgdGhl
IExpY2Vuc2UgYXQKCiAgICAgaHR0cDovL3d3dy5hcGFjaGUub3JnL2xpY2Vuc2VzL0xJQ0VO
U0UtMi4wCgogVW5sZXNzIHJlcXVpcmVkIGJ5IGFwcGxpY2FibGUgbGF3IG9yIGFncmVlZCB0
byBpbiB3cml0aW5nLCBzb2Z0d2FyZQogZGlzdHJpYnV0ZWQgdW5kZXIgdGhlIExpY2Vuc2Ug
aXMgZGlzdHJpYnV0ZWQgb24gYW4gIkFTIElTIiBCQVNJUywKIFdJVEhPVVQgV0FSUkFOVElF
UyBPUiBDT05ESVRJT05TIE9GIEFOWSBLSU5ELCBlaXRoZXIgZXhwcmVzcyBvciBpbXBsaWVk
LgogU2VlIHRoZSBMaWNlbnNlIGZvciB0aGUgc3BlY2lmaWMgbGFuZ3VhZ2UgZ292ZXJuaW5n
IHBlcm1pc3Npb25zIGFuZAogbGltaXRhdGlvbnMgdW5kZXIgdGhlIExpY2Vuc2UuCgoICgEC
EgMQAC4KCAoBCBIDEgBaCgkKAggLEgMSAFoKCAoBCBIDEwArCgkKAggIEgMTACsKCAoBCBID
FABCCgkKAggBEgMUAEIKGwoCBAASBBcAGgEaDyBBcnJvdyBzY2hlbWEuCgoKCgMEAAESAxcI
EworCgQEAAIAEgMZAh4aHiBJUEMgc2VyaWFsaXplZCBBcnJvdyBzY2hlbWEuCgoMCgUEAAIA
BRIDGQIHCgwKBQQAAgABEgMZCBkKDAoFBAACAAMSAxkcHQogCgIEARIEHQAjARoUIEFycm93
IFJlY29yZEJhdGNoLgoKCgoDBAEBEgMdCBgKMAoEBAECABIDHwIkGiMgSVBDIHNlcmlhbGl6
ZWQgQXJyb3cgUmVjb3JkQmF0Y2guCgoMCgUEAQIABRIDHwIHCgwKBQQBAgABEgMfCB8KDAoF
BAECAAMSAx8iIwo4CgQEAQIBEgMiAhYaKyBUaGUgY291bnQgb2Ygcm93cyBpbiB0aGUgcmV0
dXJuaW5nIGJsb2NrLgoKDAoFBAECAQUSAyICBwoMCgUEAQIBARIDIggRCgwKBQQBAgEDEgMi
FBViBnByb3RvMw==
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Bigquery::Storage::V1beta1::Arrow::ArrowSchema ===
    # Fields for ArrowSchema
    # Field: serialized_schema Type: 12 ()

# === Message: Google::Cloud::Bigquery::Storage::V1beta1::Arrow::ArrowRecordBatch ===
    # Fields for ArrowRecordBatch
    # Field: serialized_record_batch Type: 12 ()
    # Field: row_count Type: 3 ()

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Bigquery::Storage::V1beta1::Arrow - Compiled Protocol Buffers messages for google/cloud/bigquery/storage/v1beta1/arrow.proto

=head1 SYNOPSIS

    use Google::Cloud::Bigquery::Storage::V1beta1::Arrow;

    my $msg = Google::Cloud::Bigquery::Storage::V1beta1::Arrow::ArrowSchema->new({
        serialized_schema => $serialized_schema,
    });

    # Read or update a field
    my $val = $msg->serialized_schema();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Bigquery::Storage::V1beta1::Arrow::ArrowSchema->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/bigquery/storage/v1beta1/arrow.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Bigquery::Storage::V1beta1::Arrow::ArrowSchema

Arrow schema.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->serialized_schema() >> / C<< $msg->serialized_schema($value) >>

Type: C<Bytes>

IPC serialized Arrow schema.

=back

=head2 Google::Cloud::Bigquery::Storage::V1beta1::Arrow::ArrowRecordBatch

Arrow RecordBatch.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->serialized_record_batch() >> / C<< $msg->serialized_record_batch($value) >>

Type: C<Bytes>

IPC serialized Arrow RecordBatch.

=item * C<< $msg->row_count() >> / C<< $msg->row_count($value) >>

Type: C<Int64>

The count of rows in the returning block.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Bigquery::Storage::V1beta1::Arrow::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
