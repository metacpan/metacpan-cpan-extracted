package Google::Firestore::V1::QueryProfile;

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
Cidnb29nbGUvZmlyZXN0b3JlL3YxL3F1ZXJ5X3Byb2ZpbGUucHJvdG8SE2dvb2dsZS5maXJl
c3RvcmUudjEaH2dvb2dsZS9hcGkvZmllbGRfYmVoYXZpb3IucHJvdG8aHmdvb2dsZS9wcm90
b2J1Zi9kdXJhdGlvbi5wcm90bxocZ29vZ2xlL3Byb3RvYnVmL3N0cnVjdC5wcm90byIvCg5F
eHBsYWluT3B0aW9ucxIdCgdhbmFseXplGAEgASgIQgPgQQFSB2FuYWx5emUiowEKDkV4cGxh
aW5NZXRyaWNzEkMKDHBsYW5fc3VtbWFyeRgBIAEoCzIgLmdvb2dsZS5maXJlc3RvcmUudjEu
UGxhblN1bW1hcnlSC3BsYW5TdW1tYXJ5EkwKD2V4ZWN1dGlvbl9zdGF0cxgCIAEoCzIjLmdv
b2dsZS5maXJlc3RvcmUudjEuRXhlY3V0aW9uU3RhdHNSDmV4ZWN1dGlvblN0YXRzIkkKC1Bs
YW5TdW1tYXJ5EjoKDGluZGV4ZXNfdXNlZBgBIAMoCzIXLmdvb2dsZS5wcm90b2J1Zi5TdHJ1
Y3RSC2luZGV4ZXNVc2VkIugBCg5FeGVjdXRpb25TdGF0cxIpChByZXN1bHRzX3JldHVybmVk
GAEgASgDUg9yZXN1bHRzUmV0dXJuZWQSSAoSZXhlY3V0aW9uX2R1cmF0aW9uGAMgASgLMhku
Z29vZ2xlLnByb3RvYnVmLkR1cmF0aW9uUhFleGVjdXRpb25EdXJhdGlvbhInCg9yZWFkX29w
ZXJhdGlvbnMYBCABKANSDnJlYWRPcGVyYXRpb25zEjgKC2RlYnVnX3N0YXRzGAUgASgLMhcu
Z29vZ2xlLnByb3RvYnVmLlN0cnVjdFIKZGVidWdTdGF0c0LJAQoXY29tLmdvb2dsZS5maXJl
c3RvcmUudjFCEVF1ZXJ5UHJvZmlsZVByb3RvUAFaO2Nsb3VkLmdvb2dsZS5jb20vZ28vZmly
ZXN0b3JlL2FwaXYxL2ZpcmVzdG9yZXBiO2ZpcmVzdG9yZXBiogIER0NGU6oCGUdvb2dsZS5D
bG91ZC5GaXJlc3RvcmUuVjHKAhlHb29nbGVcQ2xvdWRcRmlyZXN0b3JlXFYx6gIcR29vZ2xl
OjpDbG91ZDo6RmlyZXN0b3JlOjpWMUqeFgoGEgQOAFsBCrwECgEMEgMOABIysQQgQ29weXJp
Z2h0IDIwMjYgR29vZ2xlIExMQwoKIExpY2Vuc2VkIHVuZGVyIHRoZSBBcGFjaGUgTGljZW5z
ZSwgVmVyc2lvbiAyLjAgKHRoZSAiTGljZW5zZSIpOwogeW91IG1heSBub3QgdXNlIHRoaXMg
ZmlsZSBleGNlcHQgaW4gY29tcGxpYW5jZSB3aXRoIHRoZSBMaWNlbnNlLgogWW91IG1heSBv
YnRhaW4gYSBjb3B5IG9mIHRoZSBMaWNlbnNlIGF0CgogICAgIGh0dHA6Ly93d3cuYXBhY2hl
Lm9yZy9saWNlbnNlcy9MSUNFTlNFLTIuMAoKIFVubGVzcyByZXF1aXJlZCBieSBhcHBsaWNh
YmxlIGxhdyBvciBhZ3JlZWQgdG8gaW4gd3JpdGluZywgc29mdHdhcmUKIGRpc3RyaWJ1dGVk
IHVuZGVyIHRoZSBMaWNlbnNlIGlzIGRpc3RyaWJ1dGVkIG9uIGFuICJBUyBJUyIgQkFTSVMs
CiBXSVRIT1VUIFdBUlJBTlRJRVMgT1IgQ09ORElUSU9OUyBPRiBBTlkgS0lORCwgZWl0aGVy
IGV4cHJlc3Mgb3IgaW1wbGllZC4KIFNlZSB0aGUgTGljZW5zZSBmb3IgdGhlIHNwZWNpZmlj
IGxhbmd1YWdlIGdvdmVybmluZyBwZXJtaXNzaW9ucyBhbmQKIGxpbWl0YXRpb25zIHVuZGVy
IHRoZSBMaWNlbnNlLgoKCAoBAhIDEAAcCgkKAgMAEgMSACkKCQoCAwESAxMAKAoJCgIDAhID
FAAmCggKAQgSAxYANgoJCgIIJRIDFgA2CggKAQgSAxcAUgoJCgIICxIDFwBSCggKAQgSAxgA
IgoJCgIIChIDGAAiCggKAQgSAxkAMgoJCgIICBIDGQAyCggKAQgSAxoAMAoJCgIIARIDGgAw
CggKAQgSAxsAIgoJCgIIJBIDGwAiCggKAQgSAxwANgoJCgIIKRIDHAA2CggKAQgSAx0ANQoJ
CgIILRIDHQA1CmQKAgQAEgQiACsBGiAgRXhwbGFpbiBvcHRpb25zIGZvciB0aGUgcXVlcnku
CjI2IFNwZWNpZmljYXRpb24gb2YgdGhlIEZpcmVzdG9yZSBRdWVyeSBQcm9maWxlIGZpZWxk
cy4KCgoKAwQAARIDIggWCq4CCgQEAAIAEgMqAjwaoAIgT3B0aW9uYWwuIFdoZXRoZXIgdG8g
ZXhlY3V0ZSB0aGlzIHF1ZXJ5LgoKIFdoZW4gZmFsc2UgKHRoZSBkZWZhdWx0KSwgdGhlIHF1
ZXJ5IHdpbGwgYmUgcGxhbm5lZCwgcmV0dXJuaW5nIG9ubHkKIG1ldHJpY3MgZnJvbSB0aGUg
cGxhbm5pbmcgc3RhZ2VzLgoKIFdoZW4gdHJ1ZSwgdGhlIHF1ZXJ5IHdpbGwgYmUgcGxhbm5l
ZCBhbmQgZXhlY3V0ZWQsIHJldHVybmluZyB0aGUgZnVsbAogcXVlcnkgcmVzdWx0cyBhbG9u
ZyB3aXRoIGJvdGggcGxhbm5pbmcgYW5kIGV4ZWN1dGlvbiBzdGFnZSBtZXRyaWNzLgoKDAoF
BAACAAUSAyoCBgoMCgUEAAIAARIDKgcOCgwKBQQAAgADEgMqERIKDAoFBAACAAgSAyoTOwoP
CggEAAIACJwIABIDKhQ6CiwKAgQBEgQuADYBGiAgRXhwbGFpbiBtZXRyaWNzIGZvciB0aGUg
cXVlcnkuCgoKCgMEAQESAy4IFgo4CgQEAQIAEgMwAh8aKyBQbGFubmluZyBwaGFzZSBpbmZv
cm1hdGlvbiBmb3IgdGhlIHF1ZXJ5LgoKDAoFBAECAAYSAzACDQoMCgUEAQIAARIDMA4aCgwK
BQQBAgADEgMwHR4KqgEKBAQBAgESAzUCJRqcASBBZ2dyZWdhdGVkIHN0YXRzIGZyb20gdGhl
IGV4ZWN1dGlvbiBvZiB0aGUgcXVlcnkuIE9ubHkgcHJlc2VudCB3aGVuCiBbRXhwbGFpbk9w
dGlvbnMuYW5hbHl6ZV1bZ29vZ2xlLmZpcmVzdG9yZS52MS5FeHBsYWluT3B0aW9ucy5hbmFs
eXplXSBpcyBzZXQKIHRvIHRydWUuCgoMCgUEAQIBBhIDNQIQCgwKBQQBAgEBEgM1ESAKDAoF
BAECAQMSAzUjJAo3CgIEAhIEOQBAARorIFBsYW5uaW5nIHBoYXNlIGluZm9ybWF0aW9uIGZv
ciB0aGUgcXVlcnkuCgoKCgMEAgESAzkIEwrfAQoEBAICABIDPwIzGtEBIFRoZSBpbmRleGVz
IHNlbGVjdGVkIGZvciB0aGUgcXVlcnkuIEZvciBleGFtcGxlOgogIFsKICAgIHsicXVlcnlf
c2NvcGUiOiAiQ29sbGVjdGlvbiIsICJwcm9wZXJ0aWVzIjogIihmb28gQVNDLCBfX25hbWVf
XyBBU0MpIn0sCiAgICB7InF1ZXJ5X3Njb3BlIjogIkNvbGxlY3Rpb24iLCAicHJvcGVydGll
cyI6ICIoYmFyIEFTQywgX19uYW1lX18gQVNDKSJ9CiAgXQoKDAoFBAICAAQSAz8CCgoMCgUE
AgIABhIDPwshCgwKBQQCAgABEgM/Ii4KDAoFBAICAAMSAz8xMgoxCgIEAxIEQwBbARolIEV4
ZWN1dGlvbiBzdGF0aXN0aWNzIGZvciB0aGUgcXVlcnkuCgoKCgMEAwESA0MIFgpuCgQEAwIA
EgNGAh0aYSBUb3RhbCBudW1iZXIgb2YgcmVzdWx0cyByZXR1cm5lZCwgaW5jbHVkaW5nIGRv
Y3VtZW50cywgcHJvamVjdGlvbnMsCiBhZ2dyZWdhdGlvbiByZXN1bHRzLCBrZXlzLgoKDAoF
BAMCAAUSA0YCBwoMCgUEAwIAARIDRggYCgwKBQQDAgADEgNGGxwKPgoEBAMCARIDSQIyGjEg
VG90YWwgdGltZSB0byBleGVjdXRlIHRoZSBxdWVyeSBpbiB0aGUgYmFja2VuZC4KCgwKBQQD
AgEGEgNJAhoKDAoFBAMCAQESA0kbLQoMCgUEAwIBAxIDSTAxCi4KBAQDAgISA0wCHBohIFRv
dGFsIGJpbGxhYmxlIHJlYWQgb3BlcmF0aW9ucy4KCgwKBQQDAgIFEgNMAgcKDAoFBAMCAgES
A0wIFwoMCgUEAwICAxIDTBobCvoCCgQEAwIDEgNaAika7AIgRGVidWdnaW5nIHN0YXRpc3Rp
Y3MgZnJvbSB0aGUgZXhlY3V0aW9uIG9mIHRoZSBxdWVyeS4gTm90ZSB0aGF0IHRoZQogZGVi
dWdnaW5nIHN0YXRzIGFyZSBzdWJqZWN0IHRvIGNoYW5nZSBhcyBGaXJlc3RvcmUgZXZvbHZl
cy4gSXQgY291bGQKIGluY2x1ZGU6CiAgewogICAgImluZGV4ZXNfZW50cmllc19zY2FubmVk
IjogIjEwMDAiLAogICAgImRvY3VtZW50c19zY2FubmVkIjogIjIwIiwKICAgICJiaWxsaW5n
X2RldGFpbHMiIDogewogICAgICAgImRvY3VtZW50c19iaWxsYWJsZSI6ICIyMCIsCiAgICAg
ICAiaW5kZXhfZW50cmllc19iaWxsYWJsZSI6ICIxMDAwIiwKICAgICAgICJtaW5fcXVlcnlf
Y29zdCI6ICIwIgogICAgfQogIH0KCgwKBQQDAgMGEgNaAhgKDAoFBAMCAwESA1oZJAoMCgUE
AwIDAxIDWicoYgZwcm90bzM=
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Firestore::V1::QueryProfile::ExplainOptions ===
    # Fields for ExplainOptions
    # Field: analyze Type: 8 ()

# === Message: Google::Firestore::V1::QueryProfile::ExplainMetrics ===
    # Fields for ExplainMetrics
    # Field: plan_summary Type: 11 (.google.firestore.v1.PlanSummary)
    # Field: execution_stats Type: 11 (.google.firestore.v1.ExecutionStats)

# === Message: Google::Firestore::V1::QueryProfile::PlanSummary ===
    # Fields for PlanSummary
    # Field: indexes_used Type: 11 (.google.protobuf.Struct)

# === Message: Google::Firestore::V1::QueryProfile::ExecutionStats ===
    # Fields for ExecutionStats
    # Field: results_returned Type: 3 ()
    # Field: execution_duration Type: 11 (.google.protobuf.Duration)
    # Field: read_operations Type: 3 ()
    # Field: debug_stats Type: 11 (.google.protobuf.Struct)

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Firestore::V1::QueryProfile - Compiled Protocol Buffers messages for google/firestore/v1/query_profile.proto

=head1 SYNOPSIS

    use Google::Firestore::V1::QueryProfile;

    my $msg = Google::Firestore::V1::QueryProfile::ExplainOptions->new({
        analyze => $analyze,
    });

    # Read or update a field
    my $val = $msg->analyze();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Firestore::V1::QueryProfile::ExplainOptions->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/firestore/v1/query_profile.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Firestore::V1::QueryProfile::ExplainOptions

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

=head2 Google::Firestore::V1::QueryProfile::ExplainMetrics

Explain metrics for the query.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->plan_summary() >> / C<< $msg->plan_summary($value) >>

Type: C<Message> (L<Google::Firestore::V1::QueryProfile::PlanSummary>)

Planning phase information for the query.

=item * C<< $msg->execution_stats() >> / C<< $msg->execution_stats($value) >>

Type: C<Message> (L<Google::Firestore::V1::QueryProfile::ExecutionStats>)

Aggregated stats from the execution of the query. Only present when
[ExplainOptions.analyze][google.firestore.v1.ExplainOptions.analyze] is set
to true.

=back

=head2 Google::Firestore::V1::QueryProfile::PlanSummary

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

=head2 Google::Firestore::V1::QueryProfile::ExecutionStats

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

L<Protobuf>, L<Protobuf::Message>, L<Google::Firestore::V1::QueryProfile::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
