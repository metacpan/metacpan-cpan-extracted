package Google::Firestore::V1::AggregationResult;

use strict;
use warnings;

our $VERSION = '0.14';

use Protobuf::Message;
use Protobuf::DescriptorPool;
use Protobuf::Internal qw(:all);
use MIME::Base64;

BEGIN {
    eval { require Google::Firestore::V1::Document };
    my $descriptor_b64 = <<'EOF';
Cixnb29nbGUvZmlyZXN0b3JlL3YxL2FnZ3JlZ2F0aW9uX3Jlc3VsdC5wcm90bxITZ29vZ2xl
LmZpcmVzdG9yZS52MRoiZ29vZ2xlL2ZpcmVzdG9yZS92MS9kb2N1bWVudC5wcm90byLbAQoR
QWdncmVnYXRpb25SZXN1bHQSZgoQYWdncmVnYXRlX2ZpZWxkcxgCIAMoCzI7Lmdvb2dsZS5m
aXJlc3RvcmUudjEuQWdncmVnYXRpb25SZXN1bHQuQWdncmVnYXRlRmllbGRzRW50cnlSD2Fn
Z3JlZ2F0ZUZpZWxkcxpeChRBZ2dyZWdhdGVGaWVsZHNFbnRyeRIQCgNrZXkYASABKAlSA2tl
eRIwCgV2YWx1ZRgCIAEoCzIaLmdvb2dsZS5maXJlc3RvcmUudjEuVmFsdWVSBXZhbHVlOgI4
AULOAQoXY29tLmdvb2dsZS5maXJlc3RvcmUudjFCFkFnZ3JlZ2F0aW9uUmVzdWx0UHJvdG9Q
AVo7Y2xvdWQuZ29vZ2xlLmNvbS9nby9maXJlc3RvcmUvYXBpdjEvZmlyZXN0b3JlcGI7Zmly
ZXN0b3JlcGKiAgRHQ0ZTqgIZR29vZ2xlLkNsb3VkLkZpcmVzdG9yZS5WMcoCGUdvb2dsZVxD
bG91ZFxGaXJlc3RvcmVcVjHqAhxHb29nbGU6OkNsb3VkOjpGaXJlc3RvcmU6OlYxSu4KCgYS
BA4AKgEKvAQKAQwSAw4AEjKxBCBDb3B5cmlnaHQgMjAyNiBHb29nbGUgTExDCgogTGljZW5z
ZWQgdW5kZXIgdGhlIEFwYWNoZSBMaWNlbnNlLCBWZXJzaW9uIDIuMCAodGhlICJMaWNlbnNl
Iik7CiB5b3UgbWF5IG5vdCB1c2UgdGhpcyBmaWxlIGV4Y2VwdCBpbiBjb21wbGlhbmNlIHdp
dGggdGhlIExpY2Vuc2UuCiBZb3UgbWF5IG9idGFpbiBhIGNvcHkgb2YgdGhlIExpY2Vuc2Ug
YXQKCiAgICAgaHR0cDovL3d3dy5hcGFjaGUub3JnL2xpY2Vuc2VzL0xJQ0VOU0UtMi4wCgog
VW5sZXNzIHJlcXVpcmVkIGJ5IGFwcGxpY2FibGUgbGF3IG9yIGFncmVlZCB0byBpbiB3cml0
aW5nLCBzb2Z0d2FyZQogZGlzdHJpYnV0ZWQgdW5kZXIgdGhlIExpY2Vuc2UgaXMgZGlzdHJp
YnV0ZWQgb24gYW4gIkFTIElTIiBCQVNJUywKIFdJVEhPVVQgV0FSUkFOVElFUyBPUiBDT05E
SVRJT05TIE9GIEFOWSBLSU5ELCBlaXRoZXIgZXhwcmVzcyBvciBpbXBsaWVkLgogU2VlIHRo
ZSBMaWNlbnNlIGZvciB0aGUgc3BlY2lmaWMgbGFuZ3VhZ2UgZ292ZXJuaW5nIHBlcm1pc3Np
b25zIGFuZAogbGltaXRhdGlvbnMgdW5kZXIgdGhlIExpY2Vuc2UuCgoICgECEgMQABwKCQoC
AwASAxIALAoICgEIEgMUADYKCQoCCCUSAxQANgoICgEIEgMVAFIKCQoCCAsSAxUAUgoICgEI
EgMWACIKCQoCCAoSAxYAIgoICgEIEgMXADcKCQoCCAgSAxcANwoICgEIEgMYADAKCQoCCAES
AxgAMAoICgEIEgMZACIKCQoCCCQSAxkAIgoICgEIEgMaADYKCQoCCCkSAxoANgoICgEIEgMb
ADUKCQoCCC0SAxsANQr6AQoCBAASBCIAKgEa7QEgVGhlIHJlc3VsdCBvZiBhIHNpbmdsZSBi
dWNrZXQgZnJvbSBhIEZpcmVzdG9yZSBhZ2dyZWdhdGlvbiBxdWVyeS4KCiBUaGUga2V5cyBv
ZiBgYWdncmVnYXRlX2ZpZWxkc2AgYXJlIHRoZSBzYW1lIGZvciBhbGwgcmVzdWx0cyBpbiBh
biBhZ2dyZWdhdGlvbgogcXVlcnksIHVubGlrZSBkb2N1bWVudCBxdWVyaWVzIHdoaWNoIGNh
biBoYXZlIGRpZmZlcmVudCBmaWVsZHMgcHJlc2VudCBmb3IKIGVhY2ggcmVzdWx0LgoKCgoD
BAABEgMiCBkKtAIKBAQAAgASAykCKhqmAiBUaGUgcmVzdWx0IG9mIHRoZSBhZ2dyZWdhdGlv
biBmdW5jdGlvbnMsIGV4OiBgQ09VTlQoKikgQVMgdG90YWxfZG9jc2AuCgogVGhlIGtleSBp
cyB0aGUKIFthbGlhc11bZ29vZ2xlLmZpcmVzdG9yZS52MS5TdHJ1Y3R1cmVkQWdncmVnYXRp
b25RdWVyeS5BZ2dyZWdhdGlvbi5hbGlhc10KIGFzc2lnbmVkIHRvIHRoZSBhZ2dyZWdhdGlv
biBmdW5jdGlvbiBvbiBpbnB1dCBhbmQgdGhlIHNpemUgb2YgdGhpcyBtYXAKIGVxdWFscyB0
aGUgbnVtYmVyIG9mIGFnZ3JlZ2F0aW9uIGZ1bmN0aW9ucyBpbiB0aGUgcXVlcnkuCgoMCgUE
AAIABhIDKQIUCgwKBQQAAgABEgMpFSUKDAoFBAACAAMSAykoKWIGcHJvdG8z
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Firestore::V1::AggregationResult::AggregationResult ===
    # Fields for AggregationResult
    # Field: aggregate_fields Type: 11 (.google.firestore.v1.AggregationResult.AggregateFieldsEntry)

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Firestore::V1::AggregationResult - Compiled Protocol Buffers messages for google/firestore/v1/aggregation_result.proto

=head1 SYNOPSIS

    use Google::Firestore::V1::AggregationResult;

    my $msg = Google::Firestore::V1::AggregationResult::AggregationResult->new({
        aggregate_fields => $aggregate_fields,
    });

    # Read or update a field
    my $val = $msg->aggregate_fields();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Firestore::V1::AggregationResult::AggregationResult->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/firestore/v1/aggregation_result.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Firestore::V1::AggregationResult::AggregationResult

The result of a single bucket from a Firestore aggregation query.

The keys of `aggregate_fields` are the same for all results in an aggregation
query, unlike document queries which can have different fields present for
each result.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->aggregate_fields() >> / C<< $msg->aggregate_fields($value) >>

Type: C<Message> (L<Google::Firestore::V1::AggregationResult::AggregationResult::AggregateFieldsEntry>)

The result of the aggregation functions, ex: `COUNT(*) AS total_docs`.

The key is the
[alias][google.firestore.v1.StructuredAggregationQuery.Aggregation.alias]
assigned to the aggregation function on input and the size of this map
equals the number of aggregation functions in the query.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Firestore::V1::AggregationResult::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
