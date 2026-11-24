package Google::Datastore::V1::AggregationResult;

use strict;
use warnings;

our $VERSION = '0.14';

use Protobuf::Message;
use Protobuf::DescriptorPool;
use Protobuf::Internal qw(:all);
use MIME::Base64;

BEGIN {
    eval { require Google::Datastore::V1::Entity };
    eval { require Google::Datastore::V1::Query };
    eval { require Google::Protobuf::Timestamp };
    my $descriptor_b64 = <<'EOF';
Cixnb29nbGUvZGF0YXN0b3JlL3YxL2FnZ3JlZ2F0aW9uX3Jlc3VsdC5wcm90bxITZ29vZ2xl
LmRhdGFzdG9yZS52MRogZ29vZ2xlL2RhdGFzdG9yZS92MS9lbnRpdHkucHJvdG8aH2dvb2ds
ZS9kYXRhc3RvcmUvdjEvcXVlcnkucHJvdG8aH2dvb2dsZS9wcm90b2J1Zi90aW1lc3RhbXAu
cHJvdG8i6wEKEUFnZ3JlZ2F0aW9uUmVzdWx0EnIKFGFnZ3JlZ2F0ZV9wcm9wZXJ0aWVzGAIg
AygLMj8uZ29vZ2xlLmRhdGFzdG9yZS52MS5BZ2dyZWdhdGlvblJlc3VsdC5BZ2dyZWdhdGVQ
cm9wZXJ0aWVzRW50cnlSE2FnZ3JlZ2F0ZVByb3BlcnRpZXMaYgoYQWdncmVnYXRlUHJvcGVy
dGllc0VudHJ5EhAKA2tleRgBIAEoCVIDa2V5EjAKBXZhbHVlGAIgASgLMhouZ29vZ2xlLmRh
dGFzdG9yZS52MS5WYWx1ZVIFdmFsdWU6AjgBIoQCChZBZ2dyZWdhdGlvblJlc3VsdEJhdGNo
ElcKE2FnZ3JlZ2F0aW9uX3Jlc3VsdHMYASADKAsyJi5nb29nbGUuZGF0YXN0b3JlLnYxLkFn
Z3JlZ2F0aW9uUmVzdWx0UhJhZ2dyZWdhdGlvblJlc3VsdHMSWAoMbW9yZV9yZXN1bHRzGAIg
ASgOMjUuZ29vZ2xlLmRhdGFzdG9yZS52MS5RdWVyeVJlc3VsdEJhdGNoLk1vcmVSZXN1bHRz
VHlwZVILbW9yZVJlc3VsdHMSNwoJcmVhZF90aW1lGAMgASgLMhouZ29vZ2xlLnByb3RvYnVm
LlRpbWVzdGFtcFIIcmVhZFRpbWVCxwEKF2NvbS5nb29nbGUuZGF0YXN0b3JlLnYxQhZBZ2dy
ZWdhdGlvblJlc3VsdFByb3RvUAFaO2Nsb3VkLmdvb2dsZS5jb20vZ28vZGF0YXN0b3JlL2Fw
aXYxL2RhdGFzdG9yZXBiO2RhdGFzdG9yZXBiqgIZR29vZ2xlLkNsb3VkLkRhdGFzdG9yZS5W
McoCGUdvb2dsZVxDbG91ZFxEYXRhc3RvcmVcVjHqAhxHb29nbGU6OkNsb3VkOjpEYXRhc3Rv
cmU6OlYxSr0QCgYSBA4APQEKvAQKAQwSAw4AEjKxBCBDb3B5cmlnaHQgMjAyNiBHb29nbGUg
TExDCgogTGljZW5zZWQgdW5kZXIgdGhlIEFwYWNoZSBMaWNlbnNlLCBWZXJzaW9uIDIuMCAo
dGhlICJMaWNlbnNlIik7CiB5b3UgbWF5IG5vdCB1c2UgdGhpcyBmaWxlIGV4Y2VwdCBpbiBj
b21wbGlhbmNlIHdpdGggdGhlIExpY2Vuc2UuCiBZb3UgbWF5IG9idGFpbiBhIGNvcHkgb2Yg
dGhlIExpY2Vuc2UgYXQKCiAgICAgaHR0cDovL3d3dy5hcGFjaGUub3JnL2xpY2Vuc2VzL0xJ
Q0VOU0UtMi4wCgogVW5sZXNzIHJlcXVpcmVkIGJ5IGFwcGxpY2FibGUgbGF3IG9yIGFncmVl
ZCB0byBpbiB3cml0aW5nLCBzb2Z0d2FyZQogZGlzdHJpYnV0ZWQgdW5kZXIgdGhlIExpY2Vu
c2UgaXMgZGlzdHJpYnV0ZWQgb24gYW4gIkFTIElTIiBCQVNJUywKIFdJVEhPVVQgV0FSUkFO
VElFUyBPUiBDT05ESVRJT05TIE9GIEFOWSBLSU5ELCBlaXRoZXIgZXhwcmVzcyBvciBpbXBs
aWVkLgogU2VlIHRoZSBMaWNlbnNlIGZvciB0aGUgc3BlY2lmaWMgbGFuZ3VhZ2UgZ292ZXJu
aW5nIHBlcm1pc3Npb25zIGFuZAogbGltaXRhdGlvbnMgdW5kZXIgdGhlIExpY2Vuc2UuCgoI
CgECEgMQABwKCQoCAwASAxIAKgoJCgIDARIDEwApCgkKAgMCEgMUACkKCAoBCBIDFgA2CgkK
AgglEgMWADYKCAoBCBIDFwBSCgkKAggLEgMXAFIKCAoBCBIDGAAiCgkKAggKEgMYACIKCAoB
CBIDGQA3CgkKAggIEgMZADcKCAoBCBIDGgAwCgkKAggBEgMaADAKCAoBCBIDGwA2CgkKAggp
EgMbADYKCAoBCBIDHAA1CgkKAggtEgMcADUK/AEKAgQAEgQjACsBGu8BIFRoZSByZXN1bHQg
b2YgYSBzaW5nbGUgYnVja2V0IGZyb20gYSBEYXRhc3RvcmUgYWdncmVnYXRpb24gcXVlcnku
CgogVGhlIGtleXMgb2YgYGFnZ3JlZ2F0ZV9wcm9wZXJ0aWVzYCBhcmUgdGhlIHNhbWUgZm9y
IGFsbCByZXN1bHRzIGluIGFuCiBhZ2dyZWdhdGlvbiBxdWVyeSwgdW5saWtlIGVudGl0eSBx
dWVyaWVzIHdoaWNoIGNhbiBoYXZlIGRpZmZlcmVudCBmaWVsZHMKIHByZXNlbnQgZm9yIGVh
Y2ggcmVzdWx0LgoKCgoDBAABEgMjCBkKrgIKBAQAAgASAyoCLhqgAiBUaGUgcmVzdWx0IG9m
IHRoZSBhZ2dyZWdhdGlvbiBmdW5jdGlvbnMsIGV4OiBgQ09VTlQoKikgQVMgdG90YWxfZW50
aXRpZXNgLgoKIFRoZSBrZXkgaXMgdGhlCiBbYWxpYXNdW2dvb2dsZS5kYXRhc3RvcmUudjEu
QWdncmVnYXRpb25RdWVyeS5BZ2dyZWdhdGlvbi5hbGlhc10gYXNzaWduZWQgdG8KIHRoZSBh
Z2dyZWdhdGlvbiBmdW5jdGlvbiBvbiBpbnB1dCBhbmQgdGhlIHNpemUgb2YgdGhpcyBtYXAg
ZXF1YWxzIHRoZQogbnVtYmVyIG9mIGFnZ3JlZ2F0aW9uIGZ1bmN0aW9ucyBpbiB0aGUgcXVl
cnkuCgoMCgUEAAIABhIDKgIUCgwKBQQAAgABEgMqFSkKDAoFBAACAAMSAyosLQpOCgIEARIE
LgA9ARpCIEEgYmF0Y2ggb2YgYWdncmVnYXRpb24gcmVzdWx0cyBwcm9kdWNlZCBieSBhbiBh
Z2dyZWdhdGlvbiBxdWVyeS4KCgoKAwQBARIDLggeCjYKBAQBAgASAzACNRopIFRoZSBhZ2dy
ZWdhdGlvbiByZXN1bHRzIGZvciB0aGlzIGJhdGNoLgoKDAoFBAECAAQSAzACCgoMCgUEAQIA
BhIDMAscCgwKBQQBAgABEgMwHTAKDAoFBAECAAMSAzAzNArCAQoEBAECARIDNQI0GrQBIFRo
ZSBzdGF0ZSBvZiB0aGUgcXVlcnkgYWZ0ZXIgdGhlIGN1cnJlbnQgYmF0Y2guCiBPbmx5IENP
VU5UKCopIGFnZ3JlZ2F0aW9ucyBhcmUgc3VwcG9ydGVkIGluIHRoZSBpbml0aWFsIGxhdW5j
aC4gVGhlcmVmb3JlLAogZXhwZWN0ZWQgcmVzdWx0IHR5cGUgaXMgbGltaXRlZCB0byBgTk9f
TU9SRV9SRVNVTFRTYC4KCgwKBQQBAgEGEgM1AiIKDAoFBAECAQESAzUjLwoMCgUEAQIBAxID
NTIzCuoBCgQEAQICEgM8Aioa3AEgUmVhZCB0aW1lc3RhbXAgdGhpcyBiYXRjaCB3YXMgcmV0
dXJuZWQgZnJvbS4KCiBJbiBhIHNpbmdsZSB0cmFuc2FjdGlvbiwgc3Vic2VxdWVudCBxdWVy
eSByZXN1bHQgYmF0Y2hlcyBmb3IgdGhlIHNhbWUgcXVlcnkKIGNhbiBoYXZlIGEgZ3JlYXRl
ciB0aW1lc3RhbXAuIEVhY2ggYmF0Y2gncyByZWFkIHRpbWVzdGFtcAogaXMgdmFsaWQgZm9y
IGFsbCBwcmVjZWRpbmcgYmF0Y2hlcy4KCgwKBQQBAgIGEgM8AhsKDAoFBAECAgESAzwcJQoM
CgUEAQICAxIDPCgpYgZwcm90bzM=
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Datastore::V1::AggregationResult::AggregationResult ===
    # Fields for AggregationResult
    # Field: aggregate_properties Type: 11 (.google.datastore.v1.AggregationResult.AggregatePropertiesEntry)

# === Message: Google::Datastore::V1::AggregationResult::AggregationResultBatch ===
    # Fields for AggregationResultBatch
    # Field: aggregation_results Type: 11 (.google.datastore.v1.AggregationResult)
    # Field: more_results Type: 14 (.google.datastore.v1.QueryResultBatch.MoreResultsType)
    # Field: read_time Type: 11 (.google.protobuf.Timestamp)

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Datastore::V1::AggregationResult - Compiled Protocol Buffers messages for google/datastore/v1/aggregation_result.proto

=head1 SYNOPSIS

    use Google::Datastore::V1::AggregationResult;

    my $msg = Google::Datastore::V1::AggregationResult::AggregationResult->new({
        aggregate_properties => $aggregate_properties,
    });

    # Read or update a field
    my $val = $msg->aggregate_properties();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Datastore::V1::AggregationResult::AggregationResult->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/datastore/v1/aggregation_result.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Datastore::V1::AggregationResult::AggregationResult

The result of a single bucket from a Datastore aggregation query.

The keys of `aggregate_properties` are the same for all results in an
aggregation query, unlike entity queries which can have different fields
present for each result.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->aggregate_properties() >> / C<< $msg->aggregate_properties($value) >>

Type: C<Message> (L<Google::Datastore::V1::AggregationResult::AggregationResult::AggregatePropertiesEntry>)

The result of the aggregation functions, ex: `COUNT(*) AS total_entities`.

The key is the
[alias][google.datastore.v1.AggregationQuery.Aggregation.alias] assigned to
the aggregation function on input and the size of this map equals the
number of aggregation functions in the query.

=back

=head2 Google::Datastore::V1::AggregationResult::AggregationResultBatch

A batch of aggregation results produced by an aggregation query.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->aggregation_results() >> / C<< $msg->aggregation_results($value) >>

Type: C<Message> (L<Google::Datastore::V1::AggregationResult::AggregationResult>)

The aggregation results for this batch.

=item * C<< $msg->more_results() >> / C<< $msg->more_results($value) >>

Type: C<Enum> (L<Google::Datastore::V1::QueryResultBatch::MoreResultsType>)

The state of the query after the current batch.
Only COUNT(*) aggregations are supported in the initial launch. Therefore,
expected result type is limited to `NO_MORE_RESULTS`.

=item * C<< $msg->read_time() >> / C<< $msg->read_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Read timestamp this batch was returned from.

In a single transaction, subsequent query result batches for the same query
can have a greater timestamp. Each batch's read timestamp
is valid for all preceding batches.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Datastore::V1::AggregationResult::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
