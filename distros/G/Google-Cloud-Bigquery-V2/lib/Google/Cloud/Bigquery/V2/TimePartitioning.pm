package Google::Cloud::Bigquery::V2::TimePartitioning;

use strict;
use warnings;

our $VERSION = '0.14';

use Protobuf::Message;
use Protobuf::DescriptorPool;
use Protobuf::Internal qw(:all);
use MIME::Base64;

BEGIN {
    eval { require Google::Api::FieldBehavior };
    eval { require Google::Protobuf::Wrappers };
    my $descriptor_b64 = <<'EOF';
CjBnb29nbGUvY2xvdWQvYmlncXVlcnkvdjIvdGltZV9wYXJ0aXRpb25pbmcucHJvdG8SGGdv
b2dsZS5jbG91ZC5iaWdxdWVyeS52MhofZ29vZ2xlL2FwaS9maWVsZF9iZWhhdmlvci5wcm90
bxoeZ29vZ2xlL3Byb3RvYnVmL3dyYXBwZXJzLnByb3RvIqsBChBUaW1lUGFydGl0aW9uaW5n
EhcKBHR5cGUYASABKAlCA+BBAlIEdHlwZRJFCg1leHBpcmF0aW9uX21zGAIgASgLMhsuZ29v
Z2xlLnByb3RvYnVmLkludDY0VmFsdWVCA+BBAVIMZXhwaXJhdGlvbk1zEjcKBWZpZWxkGAMg
ASgLMhwuZ29vZ2xlLnByb3RvYnVmLlN0cmluZ1ZhbHVlQgPgQQFSBWZpZWxkQnIKHGNvbS5n
b29nbGUuY2xvdWQuYmlncXVlcnkudjJCFVRpbWVQYXJ0aXRpb25pbmdQcm90b1o7Y2xvdWQu
Z29vZ2xlLmNvbS9nby9iaWdxdWVyeS92Mi9hcGl2Mi9iaWdxdWVyeXBiO2JpZ3F1ZXJ5cGJK
kAwKBhIEDgArAQq8BAoBDBIDDgASMrEEIENvcHlyaWdodCAyMDI2IEdvb2dsZSBMTEMKCiBM
aWNlbnNlZCB1bmRlciB0aGUgQXBhY2hlIExpY2Vuc2UsIFZlcnNpb24gMi4wICh0aGUgIkxp
Y2Vuc2UiKTsKIHlvdSBtYXkgbm90IHVzZSB0aGlzIGZpbGUgZXhjZXB0IGluIGNvbXBsaWFu
Y2Ugd2l0aCB0aGUgTGljZW5zZS4KIFlvdSBtYXkgb2J0YWluIGEgY29weSBvZiB0aGUgTGlj
ZW5zZSBhdAoKICAgICBodHRwOi8vd3d3LmFwYWNoZS5vcmcvbGljZW5zZXMvTElDRU5TRS0y
LjAKCiBVbmxlc3MgcmVxdWlyZWQgYnkgYXBwbGljYWJsZSBsYXcgb3IgYWdyZWVkIHRvIGlu
IHdyaXRpbmcsIHNvZnR3YXJlCiBkaXN0cmlidXRlZCB1bmRlciB0aGUgTGljZW5zZSBpcyBk
aXN0cmlidXRlZCBvbiBhbiAiQVMgSVMiIEJBU0lTLAogV0lUSE9VVCBXQVJSQU5USUVTIE9S
IENPTkRJVElPTlMgT0YgQU5ZIEtJTkQsIGVpdGhlciBleHByZXNzIG9yIGltcGxpZWQuCiBT
ZWUgdGhlIExpY2Vuc2UgZm9yIHRoZSBzcGVjaWZpYyBsYW5ndWFnZSBnb3Zlcm5pbmcgcGVy
bWlzc2lvbnMgYW5kCiBsaW1pdGF0aW9ucyB1bmRlciB0aGUgTGljZW5zZS4KCggKAQISAxAA
IQoJCgIDABIDEgApCgkKAgMBEgMTACgKCAoBCBIDFQBSCgkKAggLEgMVAFIKCAoBCBIDFgA2
CgkKAggIEgMWADYKCAoBCBIDFwA1CgkKAggBEgMXADUKCgoCBAASBBkAKwEKCgoDBAABEgMZ
CBgKngEKBAQAAgASAxwCOxqQASBSZXF1aXJlZC4gVGhlIHN1cHBvcnRlZCB0eXBlcyBhcmUg
REFZLCBIT1VSLCBNT05USCwgYW5kIFlFQVIsIHdoaWNoIHdpbGwKIGdlbmVyYXRlIG9uZSBw
YXJ0aXRpb24gcGVyIGRheSwgaG91ciwgbW9udGgsIGFuZCB5ZWFyLCByZXNwZWN0aXZlbHku
CgoMCgUEAAIABRIDHAIICgwKBQQAAgABEgMcCQ0KDAoFBAACAAMSAxwQEQoMCgUEAAIACBID
HBI6Cg8KCAQAAgAInAgAEgMcEzkKmAEKBAQAAgESBCECIi8aiQEgT3B0aW9uYWwuIE51bWJl
ciBvZiBtaWxsaXNlY29uZHMgZm9yIHdoaWNoIHRvIGtlZXAgdGhlIHN0b3JhZ2UgZm9yIGEK
IHBhcnRpdGlvbi4KIEEgd3JhcHBlciBpcyB1c2VkIGhlcmUgYmVjYXVzZSAwIGlzIGFuIGlu
dmFsaWQgdmFsdWUuCgoMCgUEAAIBBhIDIQIcCgwKBQQAAgEBEgMhHSoKDAoFBAACAQMSAyEt
LgoMCgUEAAIBCBIDIgYuCg8KCAQAAgEInAgAEgMiBy0KuAIKBAQAAgISBCkCKi8aqQIgT3B0
aW9uYWwuIElmIG5vdCBzZXQsIHRoZSB0YWJsZSBpcyBwYXJ0aXRpb25lZCBieSBwc2V1ZG8K
IGNvbHVtbiAnX1BBUlRJVElPTlRJTUUnOyBpZiBzZXQsIHRoZSB0YWJsZSBpcyBwYXJ0aXRp
b25lZCBieSB0aGlzIGZpZWxkLgogVGhlIGZpZWxkIG11c3QgYmUgYSB0b3AtbGV2ZWwgVElN
RVNUQU1QIG9yIERBVEUgZmllbGQuIEl0cyBtb2RlIG11c3QgYmUKIE5VTExBQkxFIG9yIFJF
UVVJUkVELgogQSB3cmFwcGVyIGlzIHVzZWQgaGVyZSBiZWNhdXNlIGFuIGVtcHR5IHN0cmlu
ZyBpcyBhbiBpbnZhbGlkIHZhbHVlLgoKDAoFBAACAgYSAykCHQoMCgUEAAICARIDKR4jCgwK
BQQAAgIDEgMpJicKDAoFBAACAggSAyoGLgoPCggEAAICCJwIABIDKgctYgZwcm90bzM=
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Bigquery::V2::TimePartitioning::TimePartitioning ===
    # Fields for TimePartitioning
    # Field: type Type: 9 ()
    # Field: expiration_ms Type: 11 (.google.protobuf.Int64Value)
    # Field: field Type: 11 (.google.protobuf.StringValue)

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Bigquery::V2::TimePartitioning - Compiled Protocol Buffers messages for google/cloud/bigquery/v2/time_partitioning.proto

=head1 SYNOPSIS

    use Google::Cloud::Bigquery::V2::TimePartitioning;

    my $msg = Google::Cloud::Bigquery::V2::TimePartitioning::TimePartitioning->new({
        type => $type,
        expiration_ms => $expiration_ms,
        field => $field,
    });

    # Read or update a field
    my $val = $msg->type();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Bigquery::V2::TimePartitioning::TimePartitioning->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/bigquery/v2/time_partitioning.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Bigquery::V2::TimePartitioning::TimePartitioning

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->type() >> / C<< $msg->type($value) >>

Type: C<String>

Required. The supported types are DAY, HOUR, MONTH, and YEAR, which will
generate one partition per day, hour, month, and year, respectively.

=item * C<< $msg->expiration_ms() >> / C<< $msg->expiration_ms($value) >>

Type: C<Message> (L<Google::Protobuf::Wrappers::Int64Value>)

Optional. Number of milliseconds for which to keep the storage for a
partition.
A wrapper is used here because 0 is an invalid value.

=item * C<< $msg->field() >> / C<< $msg->field($value) >>

Type: C<Message> (L<Google::Protobuf::Wrappers::StringValue>)

Optional. If not set, the table is partitioned by pseudo
column '_PARTITIONTIME'; if set, the table is partitioned by this field.
The field must be a top-level TIMESTAMP or DATE field. Its mode must be
NULLABLE or REQUIRED.
A wrapper is used here because an empty string is an invalid value.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Bigquery::V2::TimePartitioning::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
