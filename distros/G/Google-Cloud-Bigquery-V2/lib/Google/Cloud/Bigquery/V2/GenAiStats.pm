package Google::Cloud::Bigquery::V2::GenAiStats;

use strict;
use warnings;

our $VERSION = '0.14';

use Protobuf::Message;
use Protobuf::DescriptorPool;
use Protobuf::Internal qw(:all);
use MIME::Base64;

BEGIN {
    my $descriptor_b64 = <<'EOF';
Citnb29nbGUvY2xvdWQvYmlncXVlcnkvdjIvZ2VuX2FpX3N0YXRzLnByb3RvEhhnb29nbGUu
Y2xvdWQuYmlncXVlcnkudjIiWQoXR2VuQWlGdW5jdGlvbkVycm9yU3RhdHMSFgoGZXJyb3Jz
GAMgAygJUgZlcnJvcnMSJgoPbnVtX2ZhaWxlZF9yb3dzGAUgASgDUg1udW1GYWlsZWRSb3dz
IqcBCiJHZW5BaUZ1bmN0aW9uQ29zdE9wdGltaXphdGlvblN0YXRzEjoKF251bV9jb3N0X29w
dGltaXplZF9yb3dzGAEgASgDSABSFG51bUNvc3RPcHRpbWl6ZWRSb3dziAEBEh0KB21lc3Nh
Z2UYAiABKAlIAVIHbWVzc2FnZYgBAUIaChhfbnVtX2Nvc3Rfb3B0aW1pemVkX3Jvd3NCCgoI
X21lc3NhZ2UiYgoXR2VuQWlGdW5jdGlvbkNhY2hlU3RhdHMSMAoSbnVtX2NhY2hlX2hpdF9y
b3dzGAEgASgDSABSD251bUNhY2hlSGl0Um93c4gBAUIVChNfbnVtX2NhY2hlX2hpdF9yb3dz
IqsEChJHZW5BaUZ1bmN0aW9uU3RhdHMSKAoNZnVuY3Rpb25fbmFtZRgBIAEoCUgAUgxmdW5j
dGlvbk5hbWWIAQESGwoGcHJvbXB0GAIgASgJSAFSBnByb21wdIgBARIxChJudW1fcHJvY2Vz
c2VkX3Jvd3MYAyABKANIAlIQbnVtUHJvY2Vzc2VkUm93c4gBARJXCgtlcnJvcl9zdGF0cxgE
IAEoCzIxLmdvb2dsZS5jbG91ZC5iaWdxdWVyeS52Mi5HZW5BaUZ1bmN0aW9uRXJyb3JTdGF0
c0gDUgplcnJvclN0YXRziAEBEnkKF2Nvc3Rfb3B0aW1pemF0aW9uX3N0YXRzGAUgASgLMjwu
Z29vZ2xlLmNsb3VkLmJpZ3F1ZXJ5LnYyLkdlbkFpRnVuY3Rpb25Db3N0T3B0aW1pemF0aW9u
U3RhdHNIBFIVY29zdE9wdGltaXphdGlvblN0YXRziAEBElcKC2NhY2hlX3N0YXRzGAYgASgL
MjEuZ29vZ2xlLmNsb3VkLmJpZ3F1ZXJ5LnYyLkdlbkFpRnVuY3Rpb25DYWNoZVN0YXRzSAVS
CmNhY2hlU3RhdHOIAQFCEAoOX2Z1bmN0aW9uX25hbWVCCQoHX3Byb21wdEIVChNfbnVtX3By
b2Nlc3NlZF9yb3dzQg4KDF9lcnJvcl9zdGF0c0IaChhfY29zdF9vcHRpbWl6YXRpb25fc3Rh
dHNCDgoMX2NhY2hlX3N0YXRzIikKD0dlbkFpRXJyb3JTdGF0cxIWCgZlcnJvcnMYASADKAlS
BmVycm9ycyLCAQoKR2VuQWlTdGF0cxJPCgtlcnJvcl9zdGF0cxgEIAEoCzIpLmdvb2dsZS5j
bG91ZC5iaWdxdWVyeS52Mi5HZW5BaUVycm9yU3RhdHNIAFIKZXJyb3JTdGF0c4gBARJTCg5m
dW5jdGlvbl9zdGF0cxgFIAMoCzIsLmdvb2dsZS5jbG91ZC5iaWdxdWVyeS52Mi5HZW5BaUZ1
bmN0aW9uU3RhdHNSDWZ1bmN0aW9uU3RhdHNCDgoMX2Vycm9yX3N0YXRzQm4KHGNvbS5nb29n
bGUuY2xvdWQuYmlncXVlcnkudjJCD0dlbkFpU3RhdHNQcm90b1ABWjtjbG91ZC5nb29nbGUu
Y29tL2dvL2JpZ3F1ZXJ5L3YyL2FwaXYyL2JpZ3F1ZXJ5cGI7YmlncXVlcnlwYkqFGAoGEgQO
AFUBCrwECgEMEgMOABIysQQgQ29weXJpZ2h0IDIwMjYgR29vZ2xlIExMQwoKIExpY2Vuc2Vk
IHVuZGVyIHRoZSBBcGFjaGUgTGljZW5zZSwgVmVyc2lvbiAyLjAgKHRoZSAiTGljZW5zZSIp
OwogeW91IG1heSBub3QgdXNlIHRoaXMgZmlsZSBleGNlcHQgaW4gY29tcGxpYW5jZSB3aXRo
IHRoZSBMaWNlbnNlLgogWW91IG1heSBvYnRhaW4gYSBjb3B5IG9mIHRoZSBMaWNlbnNlIGF0
CgogICAgIGh0dHA6Ly93d3cuYXBhY2hlLm9yZy9saWNlbnNlcy9MSUNFTlNFLTIuMAoKIFVu
bGVzcyByZXF1aXJlZCBieSBhcHBsaWNhYmxlIGxhdyBvciBhZ3JlZWQgdG8gaW4gd3JpdGlu
Zywgc29mdHdhcmUKIGRpc3RyaWJ1dGVkIHVuZGVyIHRoZSBMaWNlbnNlIGlzIGRpc3RyaWJ1
dGVkIG9uIGFuICJBUyBJUyIgQkFTSVMsCiBXSVRIT1VUIFdBUlJBTlRJRVMgT1IgQ09ORElU
SU9OUyBPRiBBTlkgS0lORCwgZWl0aGVyIGV4cHJlc3Mgb3IgaW1wbGllZC4KIFNlZSB0aGUg
TGljZW5zZSBmb3IgdGhlIHNwZWNpZmljIGxhbmd1YWdlIGdvdmVybmluZyBwZXJtaXNzaW9u
cyBhbmQKIGxpbWl0YXRpb25zIHVuZGVyIHRoZSBMaWNlbnNlLgoKCAoBAhIDEAAhCggKAQgS
AxIAUgoJCgIICxIDEgBSCggKAQgSAxMAIgoJCgIIChIDEwAiCggKAQgSAxQAMAoJCgIICBID
FAAwCggKAQgSAxUANQoJCgIIARIDFQA1CkIKAgQAEgQYAB8BGjYgUHJvdmlkZXMgZXJyb3Ig
c3RhdGlzdGljcyBmb3IgYSBHZW5BaSBmdW5jdGlvbiBjYWxsLgoKCgoDBAABEgMYCB8KXAoE
BAACABIDGwIdGk8gQSBsaXN0IG9mIHVuaXF1ZSBlcnJvcnMgYXQgZnVuY3Rpb24gbGV2ZWwg
KHVwIHRvIDUsIHRydW5jYXRlZCB0byAxMDAKIGNoYXJzKS4KCgwKBQQAAgAEEgMbAgoKDAoF
BAACAAUSAxsLEQoMCgUEAAIAARIDGxIYCgwKBQQAAgADEgMbGxwKPgoEBAACARIDHgIcGjEg
TnVtYmVyIG9mIGZhaWxlZCByb3dzIHByb2Nlc3NlZCBieSB0aGUgZnVuY3Rpb24KCgwKBQQA
AgEFEgMeAgcKDAoFBAACAQESAx4IFwoMCgUEAAIBAxIDHhobCk4KAgQBEgQiACgBGkIgUHJv
dmlkZXMgY29zdCBvcHRpbWl6YXRpb24gc3RhdGlzdGljcyBmb3IgYSBHZW5BaSBmdW5jdGlv
biBjYWxsLgoKCgoDBAEBEgMiCCoKQwoEBAECABIDJAItGjYgTnVtYmVyIG9mIHJvd3MgaW5m
ZXJyZWQgdmlhIGNvc3Qgb3B0aW1pemVkIHdvcmtmbG93LgoKDAoFBAECAAQSAyQCCgoMCgUE
AQIABRIDJAsQCgwKBQQBAgABEgMkESgKDAoFBAECAAMSAyQrLApZCgQEAQIBEgMnAh4aTCBT
eXN0ZW0gZ2VuZXJhdGVkIG1lc3NhZ2UgdG8gcHJvdmlkZSBpbnNpZ2h0cyBpbnRvIGNvc3Qg
b3B0aW1pemF0aW9uIHN0YXRlLgoKDAoFBAECAQQSAycCCgoMCgUEAQIBBRIDJwsRCgwKBQQB
AgEBEgMnEhkKDAoFBAECAQMSAyccHQpCCgIEAhIEKwAuARo2IFByb3ZpZGVzIGNhY2hlIHN0
YXRpc3RpY3MgZm9yIGEgR2VuQWkgZnVuY3Rpb24gY2FsbC4KCgoKAwQCARIDKwgfCjAKBAQC
AgASAy0CKBojIE51bWJlciBvZiByb3dzIHNlcnZlZCBmcm9tIGNhY2hlLgoKDAoFBAICAAQS
Ay0CCgoMCgUEAgIABRIDLQsQCgwKBQQCAgABEgMtESMKDAoFBAICAAMSAy0mJwpLCgIEAxIE
MQBEARo/IFByb3ZpZGVzIHN0YXRpc3RpY3MgZm9yIGVhY2ggQWkgZnVuY3Rpb24gY2FsbCB3
aXRoaW4gYSBxdWVyeS4KCgoKAwQDARIDMQgaCiQKBAQDAgASAzMCJBoXIE5hbWUgb2YgdGhl
IGZ1bmN0aW9uLgoKDAoFBAMCAAQSAzMCCgoMCgUEAwIABRIDMwsRCgwKBQQDAgABEgMzEh8K
DAoFBAMCAAMSAzMiIwpJCgQEAwIBEgM2Ah0aPCBVc2VyIGlucHV0IHByb21wdCBvZiB0aGUg
ZnVuY3Rpb24gKHRydW5jYXRlZCB0byAyMCBjaGFycykuCgoMCgUEAwIBBBIDNgIKCgwKBQQD
AgEFEgM2CxEKDAoFBAMCAQESAzYSGAoMCgUEAwIBAxIDNhscCoABCgQEAwICEgM6AigacyBO
dW1iZXIgb2Ygcm93cyBwcm9jZXNzZWQgYnkgdGhpcyBHZW5BaSBmdW5jdGlvbi4KIFRoaXMg
aW5jbHVkZXMgYWxsIGNvc3Rfb3B0aW1pemVkLCBsbG1faW5mZXJyZWQgYW5kIGZhaWxlZF9y
b3dzLgoKDAoFBAMCAgQSAzoCCgoMCgUEAwICBRIDOgsQCgwKBQQDAgIBEgM6ESMKDAoFBAMC
AgMSAzomJwosCgQEAwIDEgM9AjMaHyBFcnJvciBzdGF0cyBmb3IgdGhlIGZ1bmN0aW9uLgoK
DAoFBAMCAwQSAz0CCgoMCgUEAwIDBhIDPQsiCgwKBQQDAgMBEgM9Iy4KDAoFBAMCAwMSAz0x
MgpYCgQEAwIEEgNAAkoaSyBDb3N0IG9wdGltaXphdGlvbiBzdGF0cyBpZiBhcHBsaWVkIG9u
IHRoZSByb3dzIHByb2Nlc3NlZCBieSB0aGUgZnVuY3Rpb24uCgoMCgUEAwIEBBIDQAIKCgwK
BQQDAgQGEgNACy0KDAoFBAMCBAESA0AuRQoMCgUEAwIEAxIDQEhJCiwKBAQDAgUSA0MCMxof
IENhY2hlIHN0YXRzIGZvciB0aGUgZnVuY3Rpb24uCgoMCgUEAwIFBBIDQwIKCgwKBQQDAgUG
EgNDCyIKDAoFBAMCBQESA0MjLgoMCgUEAwIFAxIDQzEyClcKAgQEEgRHAEoBGksgUHJvdmlk
ZXMgZXJyb3Igc3RhdGlzdGljcyBmb3IgdGhlIHF1ZXJ5IGpvYiBhY3Jvc3MgYWxsIEFJIGZ1
bmN0aW9uIGNhbGxzLgoKCgoDBAQBEgNHCBcKVwoEBAQCABIDSQIdGkogQSBsaXN0IG9mIHVu
aXF1ZSBlcnJvcnMgYXQgcXVlcnkgbGV2ZWwgKHVwIHRvIDUsIHRydW5jYXRlZCB0byAxMDAg
Y2hhcnMpCgoMCgUEBAIABBIDSQIKCgwKBQQEAgAFEgNJCxEKDAoFBAQCAAESA0kSGAoMCgUE
BAIAAxIDSRscCiwKAgQFEgRNAFUBGiAgR2VuQWkgc3RhdHMgZm9yIHRoZSBxdWVyeSBqb2Iu
CgoKCgMEBQESA00IEgo/CgQEBQIAEgNPAisaMiBKb2IgbGV2ZWwgZXJyb3Igc3RhdHMgYWNy
b3NzIGFsbCBHZW5BaSBmdW5jdGlvbnMKCgwKBQQFAgAEEgNPAgoKDAoFBAUCAAYSA08LGgoM
CgUEBQIAARIDTxsmCgwKBQQFAgADEgNPKSoKswEKBAQFAgESA1QCMRqlASBGdW5jdGlvbiBs
ZXZlbCBzdGF0cyBmb3IgR2VuQUkgRnVuY3Rpb25zLiBGb3IgbW9yZSBpbmZvcm1hdGlvbiwg
c2VlCiBbR2VuZXJhdGl2ZSBBSQogb3ZlcnZpZXddKGh0dHBzOi8vZG9jcy5jbG91ZC5nb29n
bGUuY29tL2JpZ3F1ZXJ5L2RvY3MvZ2VuZXJhdGl2ZS1haS1vdmVydmlldykuCgoMCgUEBQIB
BBIDVAIKCgwKBQQFAgEGEgNUCx0KDAoFBAUCAQESA1QeLAoMCgUEBQIBAxIDVC8wYgZwcm90
bzM=
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Bigquery::V2::GenAiStats::GenAiFunctionErrorStats ===
    # Fields for GenAiFunctionErrorStats
    # Field: errors Type: 9 ()
    # Field: num_failed_rows Type: 3 ()

# === Message: Google::Cloud::Bigquery::V2::GenAiStats::GenAiFunctionCostOptimizationStats ===
    # Fields for GenAiFunctionCostOptimizationStats
    # Field: num_cost_optimized_rows Type: 3 ()
    # Field: message Type: 9 ()

# === Message: Google::Cloud::Bigquery::V2::GenAiStats::GenAiFunctionCacheStats ===
    # Fields for GenAiFunctionCacheStats
    # Field: num_cache_hit_rows Type: 3 ()

# === Message: Google::Cloud::Bigquery::V2::GenAiStats::GenAiFunctionStats ===
    # Fields for GenAiFunctionStats
    # Field: function_name Type: 9 ()
    # Field: prompt Type: 9 ()
    # Field: num_processed_rows Type: 3 ()
    # Field: error_stats Type: 11 (.google.cloud.bigquery.v2.GenAiFunctionErrorStats)
    # Field: cost_optimization_stats Type: 11 (.google.cloud.bigquery.v2.GenAiFunctionCostOptimizationStats)
    # Field: cache_stats Type: 11 (.google.cloud.bigquery.v2.GenAiFunctionCacheStats)

# === Message: Google::Cloud::Bigquery::V2::GenAiStats::GenAiErrorStats ===
    # Fields for GenAiErrorStats
    # Field: errors Type: 9 ()

# === Message: Google::Cloud::Bigquery::V2::GenAiStats::GenAiStats ===
    # Fields for GenAiStats
    # Field: error_stats Type: 11 (.google.cloud.bigquery.v2.GenAiErrorStats)
    # Field: function_stats Type: 11 (.google.cloud.bigquery.v2.GenAiFunctionStats)

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Bigquery::V2::GenAiStats - Compiled Protocol Buffers messages for google/cloud/bigquery/v2/gen_ai_stats.proto

=head1 SYNOPSIS

    use Google::Cloud::Bigquery::V2::GenAiStats;

    my $msg = Google::Cloud::Bigquery::V2::GenAiStats::GenAiFunctionErrorStats->new({
        errors => $errors,
        num_failed_rows => $num_failed_rows,
    });

    # Read or update a field
    my $val = $msg->errors();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Bigquery::V2::GenAiStats::GenAiFunctionErrorStats->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/bigquery/v2/gen_ai_stats.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Bigquery::V2::GenAiStats::GenAiFunctionErrorStats

Provides error statistics for a GenAi function call.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->errors() >> / C<< $msg->errors($value) >>

Type: C<String>

A list of unique errors at function level (up to 5, truncated to 100
chars).

=item * C<< $msg->num_failed_rows() >> / C<< $msg->num_failed_rows($value) >>

Type: C<Int64>

Number of failed rows processed by the function

=back

=head2 Google::Cloud::Bigquery::V2::GenAiStats::GenAiFunctionCostOptimizationStats

Provides cost optimization statistics for a GenAi function call.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->num_cost_optimized_rows() >> / C<< $msg->num_cost_optimized_rows($value) >>

Type: C<Int64>

Number of rows inferred via cost optimized workflow.

=item * C<< $msg->message() >> / C<< $msg->message($value) >>

Type: C<String>

System generated message to provide insights into cost optimization state.

=back

=head2 Google::Cloud::Bigquery::V2::GenAiStats::GenAiFunctionCacheStats

Provides cache statistics for a GenAi function call.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->num_cache_hit_rows() >> / C<< $msg->num_cache_hit_rows($value) >>

Type: C<Int64>

Number of rows served from cache.

=back

=head2 Google::Cloud::Bigquery::V2::GenAiStats::GenAiFunctionStats

Provides statistics for each Ai function call within a query.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->function_name() >> / C<< $msg->function_name($value) >>

Type: C<String>

Name of the function.

=item * C<< $msg->prompt() >> / C<< $msg->prompt($value) >>

Type: C<String>

User input prompt of the function (truncated to 20 chars).

=item * C<< $msg->num_processed_rows() >> / C<< $msg->num_processed_rows($value) >>

Type: C<Int64>

Number of rows processed by this GenAi function.
This includes all cost_optimized, llm_inferred and failed_rows.

=item * C<< $msg->error_stats() >> / C<< $msg->error_stats($value) >>

Type: C<Message> (L<Google::Cloud::Bigquery::V2::GenAiStats::GenAiFunctionErrorStats>)

Error stats for the function.

=item * C<< $msg->cost_optimization_stats() >> / C<< $msg->cost_optimization_stats($value) >>

Type: C<Message> (L<Google::Cloud::Bigquery::V2::GenAiStats::GenAiFunctionCostOptimizationStats>)

Cost optimization stats if applied on the rows processed by the function.

=item * C<< $msg->cache_stats() >> / C<< $msg->cache_stats($value) >>

Type: C<Message> (L<Google::Cloud::Bigquery::V2::GenAiStats::GenAiFunctionCacheStats>)

Cache stats for the function.

=back

=head2 Google::Cloud::Bigquery::V2::GenAiStats::GenAiErrorStats

Provides error statistics for the query job across all AI function calls.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->errors() >> / C<< $msg->errors($value) >>

Type: C<String>

A list of unique errors at query level (up to 5, truncated to 100 chars)

=back

=head2 Google::Cloud::Bigquery::V2::GenAiStats::GenAiStats

GenAi stats for the query job.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->error_stats() >> / C<< $msg->error_stats($value) >>

Type: C<Message> (L<Google::Cloud::Bigquery::V2::GenAiStats::GenAiErrorStats>)

Job level error stats across all GenAi functions

=item * C<< $msg->function_stats() >> / C<< $msg->function_stats($value) >>

Type: C<Message> (L<Google::Cloud::Bigquery::V2::GenAiStats::GenAiFunctionStats>)

Function level stats for GenAI Functions. For more information, see
[Generative AI
overview](https://docs.cloud.google.com/bigquery/docs/generative-ai-overview).

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Bigquery::V2::GenAiStats::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
