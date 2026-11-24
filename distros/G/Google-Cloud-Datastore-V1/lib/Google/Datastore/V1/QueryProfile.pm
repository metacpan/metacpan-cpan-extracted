package Google::Datastore::V1::QueryProfile;

use strict;
use warnings;

our $VERSION = '0.14';

use Protobuf::Message;
use Protobuf::DescriptorPool;
use Protobuf::Internal qw(:all);
use MIME::Base64;

BEGIN {
    eval { require Google::Api::FieldBehavior };
    eval { require Google::Protobuf::Duration };
    eval { require Google::Protobuf::Struct };
    my $descriptor_b64 = <<'EOF';
Cidnb29nbGUvZGF0YXN0b3JlL3YxL3F1ZXJ5X3Byb2ZpbGUucHJvdG8SE2dvb2dsZS5kYXRh
c3RvcmUudjEaH2dvb2dsZS9hcGkvZmllbGRfYmVoYXZpb3IucHJvdG8aHmdvb2dsZS9wcm90
b2J1Zi9kdXJhdGlvbi5wcm90bxocZ29vZ2xlL3Byb3RvYnVmL3N0cnVjdC5wcm90byIvCg5F
eHBsYWluT3B0aW9ucxIdCgdhbmFseXplGAEgASgIQgPgQQFSB2FuYWx5emUiowEKDkV4cGxh
aW5NZXRyaWNzEkMKDHBsYW5fc3VtbWFyeRgBIAEoCzIgLmdvb2dsZS5kYXRhc3RvcmUudjEu
UGxhblN1bW1hcnlSC3BsYW5TdW1tYXJ5EkwKD2V4ZWN1dGlvbl9zdGF0cxgCIAEoCzIjLmdv
b2dsZS5kYXRhc3RvcmUudjEuRXhlY3V0aW9uU3RhdHNSDmV4ZWN1dGlvblN0YXRzIkkKC1Bs
YW5TdW1tYXJ5EjoKDGluZGV4ZXNfdXNlZBgBIAMoCzIXLmdvb2dsZS5wcm90b2J1Zi5TdHJ1
Y3RSC2luZGV4ZXNVc2VkIugBCg5FeGVjdXRpb25TdGF0cxIpChByZXN1bHRzX3JldHVybmVk
GAEgASgDUg9yZXN1bHRzUmV0dXJuZWQSSAoSZXhlY3V0aW9uX2R1cmF0aW9uGAMgASgLMhku
Z29vZ2xlLnByb3RvYnVmLkR1cmF0aW9uUhFleGVjdXRpb25EdXJhdGlvbhInCg9yZWFkX29w
ZXJhdGlvbnMYBCABKANSDnJlYWRPcGVyYXRpb25zEjgKC2RlYnVnX3N0YXRzGAUgASgLMhcu
Z29vZ2xlLnByb3RvYnVmLlN0cnVjdFIKZGVidWdTdGF0c0LCAQoXY29tLmdvb2dsZS5kYXRh
c3RvcmUudjFCEVF1ZXJ5UHJvZmlsZVByb3RvUAFaO2Nsb3VkLmdvb2dsZS5jb20vZ28vZGF0
YXN0b3JlL2FwaXYxL2RhdGFzdG9yZXBiO2RhdGFzdG9yZXBiqgIZR29vZ2xlLkNsb3VkLkRh
dGFzdG9yZS5WMcoCGUdvb2dsZVxDbG91ZFxEYXRhc3RvcmVcVjHqAhxHb29nbGU6OkNsb3Vk
OjpEYXRhc3RvcmU6OlYxSokWCgYSBA4AWgEKvAQKAQwSAw4AEjKxBCBDb3B5cmlnaHQgMjAy
NiBHb29nbGUgTExDCgogTGljZW5zZWQgdW5kZXIgdGhlIEFwYWNoZSBMaWNlbnNlLCBWZXJz
aW9uIDIuMCAodGhlICJMaWNlbnNlIik7CiB5b3UgbWF5IG5vdCB1c2UgdGhpcyBmaWxlIGV4
Y2VwdCBpbiBjb21wbGlhbmNlIHdpdGggdGhlIExpY2Vuc2UuCiBZb3UgbWF5IG9idGFpbiBh
IGNvcHkgb2YgdGhlIExpY2Vuc2UgYXQKCiAgICAgaHR0cDovL3d3dy5hcGFjaGUub3JnL2xp
Y2Vuc2VzL0xJQ0VOU0UtMi4wCgogVW5sZXNzIHJlcXVpcmVkIGJ5IGFwcGxpY2FibGUgbGF3
IG9yIGFncmVlZCB0byBpbiB3cml0aW5nLCBzb2Z0d2FyZQogZGlzdHJpYnV0ZWQgdW5kZXIg
dGhlIExpY2Vuc2UgaXMgZGlzdHJpYnV0ZWQgb24gYW4gIkFTIElTIiBCQVNJUywKIFdJVEhP
VVQgV0FSUkFOVElFUyBPUiBDT05ESVRJT05TIE9GIEFOWSBLSU5ELCBlaXRoZXIgZXhwcmVz
cyBvciBpbXBsaWVkLgogU2VlIHRoZSBMaWNlbnNlIGZvciB0aGUgc3BlY2lmaWMgbGFuZ3Vh
Z2UgZ292ZXJuaW5nIHBlcm1pc3Npb25zIGFuZAogbGltaXRhdGlvbnMgdW5kZXIgdGhlIExp
Y2Vuc2UuCgoICgECEgMQABwKCQoCAwASAxIAKQoJCgIDARIDEwAoCgkKAgMCEgMUACYKCAoB
CBIDFgA2CgkKAgglEgMWADYKCAoBCBIDFwBSCgkKAggLEgMXAFIKCAoBCBIDGAAiCgkKAggK
EgMYACIKCAoBCBIDGQAyCgkKAggIEgMZADIKCAoBCBIDGgAwCgkKAggBEgMaADAKCAoBCBID
GwA2CgkKAggpEgMbADYKCAoBCBIDHAA1CgkKAggtEgMcADUKZAoCBAASBCEAKgEaICBFeHBs
YWluIG9wdGlvbnMgZm9yIHRoZSBxdWVyeS4KMjYgU3BlY2lmaWNhdGlvbiBvZiB0aGUgRGF0
YXN0b3JlIFF1ZXJ5IFByb2ZpbGUgZmllbGRzLgoKCgoDBAABEgMhCBYKrgIKBAQAAgASAykC
PBqgAiBPcHRpb25hbC4gV2hldGhlciB0byBleGVjdXRlIHRoaXMgcXVlcnkuCgogV2hlbiBm
YWxzZSAodGhlIGRlZmF1bHQpLCB0aGUgcXVlcnkgd2lsbCBiZSBwbGFubmVkLCByZXR1cm5p
bmcgb25seQogbWV0cmljcyBmcm9tIHRoZSBwbGFubmluZyBzdGFnZXMuCgogV2hlbiB0cnVl
LCB0aGUgcXVlcnkgd2lsbCBiZSBwbGFubmVkIGFuZCBleGVjdXRlZCwgcmV0dXJuaW5nIHRo
ZSBmdWxsCiBxdWVyeSByZXN1bHRzIGFsb25nIHdpdGggYm90aCBwbGFubmluZyBhbmQgZXhl
Y3V0aW9uIHN0YWdlIG1ldHJpY3MuCgoMCgUEAAIABRIDKQIGCgwKBQQAAgABEgMpBw4KDAoF
BAACAAMSAykREgoMCgUEAAIACBIDKRM7Cg8KCAQAAgAInAgAEgMpFDoKLAoCBAESBC0ANQEa
ICBFeHBsYWluIG1ldHJpY3MgZm9yIHRoZSBxdWVyeS4KCgoKAwQBARIDLQgWCjgKBAQBAgAS
Ay8CHxorIFBsYW5uaW5nIHBoYXNlIGluZm9ybWF0aW9uIGZvciB0aGUgcXVlcnkuCgoMCgUE
AQIABhIDLwINCgwKBQQBAgABEgMvDhoKDAoFBAECAAMSAy8dHgqqAQoEBAECARIDNAIlGpwB
IEFnZ3JlZ2F0ZWQgc3RhdHMgZnJvbSB0aGUgZXhlY3V0aW9uIG9mIHRoZSBxdWVyeS4gT25s
eSBwcmVzZW50IHdoZW4KIFtFeHBsYWluT3B0aW9ucy5hbmFseXplXVtnb29nbGUuZGF0YXN0
b3JlLnYxLkV4cGxhaW5PcHRpb25zLmFuYWx5emVdIGlzIHNldAogdG8gdHJ1ZS4KCgwKBQQB
AgEGEgM0AhAKDAoFBAECAQESAzQRIAoMCgUEAQIBAxIDNCMkCjcKAgQCEgQ4AD8BGisgUGxh
bm5pbmcgcGhhc2UgaW5mb3JtYXRpb24gZm9yIHRoZSBxdWVyeS4KCgoKAwQCARIDOAgTCt8B
CgQEAgIAEgM+AjMa0QEgVGhlIGluZGV4ZXMgc2VsZWN0ZWQgZm9yIHRoZSBxdWVyeS4gRm9y
IGV4YW1wbGU6CiAgWwogICAgeyJxdWVyeV9zY29wZSI6ICJDb2xsZWN0aW9uIiwgInByb3Bl
cnRpZXMiOiAiKGZvbyBBU0MsIF9fbmFtZV9fIEFTQykifSwKICAgIHsicXVlcnlfc2NvcGUi
OiAiQ29sbGVjdGlvbiIsICJwcm9wZXJ0aWVzIjogIihiYXIgQVNDLCBfX25hbWVfXyBBU0Mp
In0KICBdCgoMCgUEAgIABBIDPgIKCgwKBQQCAgAGEgM+CyEKDAoFBAICAAESAz4iLgoMCgUE
AgIAAxIDPjEyCjEKAgQDEgRCAFoBGiUgRXhlY3V0aW9uIHN0YXRpc3RpY3MgZm9yIHRoZSBx
dWVyeS4KCgoKAwQDARIDQggWCm4KBAQDAgASA0UCHRphIFRvdGFsIG51bWJlciBvZiByZXN1
bHRzIHJldHVybmVkLCBpbmNsdWRpbmcgZG9jdW1lbnRzLCBwcm9qZWN0aW9ucywKIGFnZ3Jl
Z2F0aW9uIHJlc3VsdHMsIGtleXMuCgoMCgUEAwIABRIDRQIHCgwKBQQDAgABEgNFCBgKDAoF
BAMCAAMSA0UbHAo+CgQEAwIBEgNIAjIaMSBUb3RhbCB0aW1lIHRvIGV4ZWN1dGUgdGhlIHF1
ZXJ5IGluIHRoZSBiYWNrZW5kLgoKDAoFBAMCAQYSA0gCGgoMCgUEAwIBARIDSBstCgwKBQQD
AgEDEgNIMDEKLgoEBAMCAhIDSwIcGiEgVG90YWwgYmlsbGFibGUgcmVhZCBvcGVyYXRpb25z
LgoKDAoFBAMCAgUSA0sCBwoMCgUEAwICARIDSwgXCgwKBQQDAgIDEgNLGhsK+gIKBAQDAgMS
A1kCKRrsAiBEZWJ1Z2dpbmcgc3RhdGlzdGljcyBmcm9tIHRoZSBleGVjdXRpb24gb2YgdGhl
IHF1ZXJ5LiBOb3RlIHRoYXQgdGhlCiBkZWJ1Z2dpbmcgc3RhdHMgYXJlIHN1YmplY3QgdG8g
Y2hhbmdlIGFzIEZpcmVzdG9yZSBldm9sdmVzLiBJdCBjb3VsZAogaW5jbHVkZToKICB7CiAg
ICAiaW5kZXhlc19lbnRyaWVzX3NjYW5uZWQiOiAiMTAwMCIsCiAgICAiZG9jdW1lbnRzX3Nj
YW5uZWQiOiAiMjAiLAogICAgImJpbGxpbmdfZGV0YWlscyIgOiB7CiAgICAgICAiZG9jdW1l
bnRzX2JpbGxhYmxlIjogIjIwIiwKICAgICAgICJpbmRleF9lbnRyaWVzX2JpbGxhYmxlIjog
IjEwMDAiLAogICAgICAgIm1pbl9xdWVyeV9jb3N0IjogIjAiCiAgICB9CiAgfQoKDAoFBAMC
AwYSA1kCGAoMCgUEAwIDARIDWRkkCgwKBQQDAgMDEgNZJyhiBnByb3RvMw==
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Datastore::V1::QueryProfile::ExplainOptions ===
    # Fields for ExplainOptions
    # Field: analyze Type: 8 ()

# === Message: Google::Datastore::V1::QueryProfile::ExplainMetrics ===
    # Fields for ExplainMetrics
    # Field: plan_summary Type: 11 (.google.datastore.v1.PlanSummary)
    # Field: execution_stats Type: 11 (.google.datastore.v1.ExecutionStats)

# === Message: Google::Datastore::V1::QueryProfile::PlanSummary ===
    # Fields for PlanSummary
    # Field: indexes_used Type: 11 (.google.protobuf.Struct)

# === Message: Google::Datastore::V1::QueryProfile::ExecutionStats ===
    # Fields for ExecutionStats
    # Field: results_returned Type: 3 ()
    # Field: execution_duration Type: 11 (.google.protobuf.Duration)
    # Field: read_operations Type: 3 ()
    # Field: debug_stats Type: 11 (.google.protobuf.Struct)

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Datastore::V1::QueryProfile - Compiled Protocol Buffers messages for google/datastore/v1/query_profile.proto

=head1 SYNOPSIS

    use Google::Datastore::V1::QueryProfile;

    my $msg = Google::Datastore::V1::QueryProfile::ExplainOptions->new({
        analyze => $analyze,
    });

    # Read or update a field
    my $val = $msg->analyze();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Datastore::V1::QueryProfile::ExplainOptions->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/datastore/v1/query_profile.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Datastore::V1::QueryProfile::ExplainOptions

Explain options for the query.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->analyze() >> / C<< $msg->analyze($value) >>

Type: C<Bool>

Optional. Whether to execute this query.

When false (the default), the query will be planned, returning only
metrics from the planning stages.

When true, the query will be planned and executed, returning the full
query results along with both planning and execution stage metrics.

=back

=head2 Google::Datastore::V1::QueryProfile::ExplainMetrics

Explain metrics for the query.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->plan_summary() >> / C<< $msg->plan_summary($value) >>

Type: C<Message> (L<Google::Datastore::V1::QueryProfile::PlanSummary>)

Planning phase information for the query.

=item * C<< $msg->execution_stats() >> / C<< $msg->execution_stats($value) >>

Type: C<Message> (L<Google::Datastore::V1::QueryProfile::ExecutionStats>)

Aggregated stats from the execution of the query. Only present when
[ExplainOptions.analyze][google.datastore.v1.ExplainOptions.analyze] is set
to true.

=back

=head2 Google::Datastore::V1::QueryProfile::PlanSummary

Planning phase information for the query.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->indexes_used() >> / C<< $msg->indexes_used($value) >>

Type: C<Message> (L<Google::Protobuf::Struct::Struct>)

The indexes selected for the query. For example:
 [
   {"query_scope": "Collection", "properties": "(foo ASC, __name__ ASC)"},
   {"query_scope": "Collection", "properties": "(bar ASC, __name__ ASC)"}
 ]

=back

=head2 Google::Datastore::V1::QueryProfile::ExecutionStats

Execution statistics for the query.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->results_returned() >> / C<< $msg->results_returned($value) >>

Type: C<Int64>

Total number of results returned, including documents, projections,
aggregation results, keys.

=item * C<< $msg->execution_duration() >> / C<< $msg->execution_duration($value) >>

Type: C<Message> (L<Google::Protobuf::Duration::Duration>)

Total time to execute the query in the backend.

=item * C<< $msg->read_operations() >> / C<< $msg->read_operations($value) >>

Type: C<Int64>

Total billable read operations.

=item * C<< $msg->debug_stats() >> / C<< $msg->debug_stats($value) >>

Type: C<Message> (L<Google::Protobuf::Struct::Struct>)

Debugging statistics from the execution of the query. Note that the
debugging stats are subject to change as Firestore evolves. It could
include:
 {
   "indexes_entries_scanned": "1000",
   "documents_scanned": "20",
   "billing_details" : {
      "documents_billable": "20",
      "index_entries_billable": "1000",
      "min_query_cost": "0"
   }
 }

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Datastore::V1::QueryProfile::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
