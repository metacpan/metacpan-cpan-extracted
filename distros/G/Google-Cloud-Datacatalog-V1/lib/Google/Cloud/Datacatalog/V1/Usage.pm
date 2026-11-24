package Google::Cloud::Datacatalog::V1::Usage;

use strict;
use warnings;

our $VERSION = '0.14';

use Protobuf::Message;
use Protobuf::DescriptorPool;
use Protobuf::Internal qw(:all);
use MIME::Base64;

BEGIN {
    eval { require Google::Api::FieldBehavior };
    eval { require Google::Protobuf::Timestamp };
    my $descriptor_b64 = <<'EOF';
Cidnb29nbGUvY2xvdWQvZGF0YWNhdGFsb2cvdjEvdXNhZ2UucHJvdG8SG2dvb2dsZS5jbG91
ZC5kYXRhY2F0YWxvZy52MRofZ29vZ2xlL2FwaS9maWVsZF9iZWhhdmlvci5wcm90bxofZ29v
Z2xlL3Byb3RvYnVmL3RpbWVzdGFtcC5wcm90byLuAQoKVXNhZ2VTdGF0cxIrChF0b3RhbF9j
b21wbGV0aW9ucxgBIAEoAlIQdG90YWxDb21wbGV0aW9ucxIlCg50b3RhbF9mYWlsdXJlcxgC
IAEoAlINdG90YWxGYWlsdXJlcxIvChN0b3RhbF9jYW5jZWxsYXRpb25zGAMgASgCUhJ0b3Rh
bENhbmNlbGxhdGlvbnMSWwordG90YWxfZXhlY3V0aW9uX3RpbWVfZm9yX2NvbXBsZXRpb25z
X21pbGxpcxgEIAEoAlImdG90YWxFeGVjdXRpb25UaW1lRm9yQ29tcGxldGlvbnNNaWxsaXMi
RQoQQ29tbW9uVXNhZ2VTdGF0cxIiCgp2aWV3X2NvdW50GAEgASgDSABSCXZpZXdDb3VudIgB
AUINCgtfdmlld19jb3VudCKIBQoLVXNhZ2VTaWduYWwSOwoLdXBkYXRlX3RpbWUYASABKAsy
Gi5nb29nbGUucHJvdG9idWYuVGltZXN0YW1wUgp1cGRhdGVUaW1lEn4KF3VzYWdlX3dpdGhp
bl90aW1lX3JhbmdlGAIgAygLMkIuZ29vZ2xlLmNsb3VkLmRhdGFjYXRhbG9nLnYxLlVzYWdl
U2lnbmFsLlVzYWdlV2l0aGluVGltZVJhbmdlRW50cnlCA+BBA1IUdXNhZ2VXaXRoaW5UaW1l
UmFuZ2USjAEKHmNvbW1vbl91c2FnZV93aXRoaW5fdGltZV9yYW5nZRgDIAMoCzJILmdvb2ds
ZS5jbG91ZC5kYXRhY2F0YWxvZy52MS5Vc2FnZVNpZ25hbC5Db21tb25Vc2FnZVdpdGhpblRp
bWVSYW5nZUVudHJ5Uhpjb21tb25Vc2FnZVdpdGhpblRpbWVSYW5nZRIqCg5mYXZvcml0ZV9j
b3VudBgEIAEoA0gAUg1mYXZvcml0ZUNvdW50iAEBGnAKGVVzYWdlV2l0aGluVGltZVJhbmdl
RW50cnkSEAoDa2V5GAEgASgJUgNrZXkSPQoFdmFsdWUYAiABKAsyJy5nb29nbGUuY2xvdWQu
ZGF0YWNhdGFsb2cudjEuVXNhZ2VTdGF0c1IFdmFsdWU6AjgBGnwKH0NvbW1vblVzYWdlV2l0
aGluVGltZVJhbmdlRW50cnkSEAoDa2V5GAEgASgJUgNrZXkSQwoFdmFsdWUYAiABKAsyLS5n
b29nbGUuY2xvdWQuZGF0YWNhdGFsb2cudjEuQ29tbW9uVXNhZ2VTdGF0c1IFdmFsdWU6AjgB
QhEKD19mYXZvcml0ZV9jb3VudELDAQofY29tLmdvb2dsZS5jbG91ZC5kYXRhY2F0YWxvZy52
MVABWkFjbG91ZC5nb29nbGUuY29tL2dvL2RhdGFjYXRhbG9nL2FwaXYxL2RhdGFjYXRhbG9n
cGI7ZGF0YWNhdGFsb2dwYqoCG0dvb2dsZS5DbG91ZC5EYXRhQ2F0YWxvZy5WMcoCG0dvb2ds
ZVxDbG91ZFxEYXRhQ2F0YWxvZ1xWMeoCHkdvb2dsZTo6Q2xvdWQ6OkRhdGFDYXRhbG9nOjpW
MUqJFQoGEgQOAFIBCrwECgEMEgMOABIysQQgQ29weXJpZ2h0IDIwMjUgR29vZ2xlIExMQwoK
IExpY2Vuc2VkIHVuZGVyIHRoZSBBcGFjaGUgTGljZW5zZSwgVmVyc2lvbiAyLjAgKHRoZSAi
TGljZW5zZSIpOwogeW91IG1heSBub3QgdXNlIHRoaXMgZmlsZSBleGNlcHQgaW4gY29tcGxp
YW5jZSB3aXRoIHRoZSBMaWNlbnNlLgogWW91IG1heSBvYnRhaW4gYSBjb3B5IG9mIHRoZSBM
aWNlbnNlIGF0CgogICAgIGh0dHA6Ly93d3cuYXBhY2hlLm9yZy9saWNlbnNlcy9MSUNFTlNF
LTIuMAoKIFVubGVzcyByZXF1aXJlZCBieSBhcHBsaWNhYmxlIGxhdyBvciBhZ3JlZWQgdG8g
aW4gd3JpdGluZywgc29mdHdhcmUKIGRpc3RyaWJ1dGVkIHVuZGVyIHRoZSBMaWNlbnNlIGlz
IGRpc3RyaWJ1dGVkIG9uIGFuICJBUyBJUyIgQkFTSVMsCiBXSVRIT1VUIFdBUlJBTlRJRVMg
T1IgQ09ORElUSU9OUyBPRiBBTlkgS0lORCwgZWl0aGVyIGV4cHJlc3Mgb3IgaW1wbGllZC4K
IFNlZSB0aGUgTGljZW5zZSBmb3IgdGhlIHNwZWNpZmljIGxhbmd1YWdlIGdvdmVybmluZyBw
ZXJtaXNzaW9ucyBhbmQKIGxpbWl0YXRpb25zIHVuZGVyIHRoZSBMaWNlbnNlLgoKCAoBAhID
EAAkCgkKAgMAEgMSACkKCQoCAwESAxMAKQoICgEIEgMVADgKCQoCCCUSAxUAOAoICgEIEgMW
AFgKCQoCCAsSAxYAWAoICgEIEgMXACIKCQoCCAoSAxcAIgoICgEIEgMYADgKCQoCCAESAxgA
OAoICgEIEgMZADgKCQoCCCkSAxkAOAoICgEIEgMaADcKCQoCCC0SAxoANwqnAwoCBAASBCYA
MgEamgMgRGV0YWlsZWQgc3RhdGlzdGljcyBvbiB0aGUgZW50cnkncyB1c2FnZS4KCiBVc2Fn
ZSBzdGF0aXN0aWNzIGhhdmUgdGhlIGZvbGxvd2luZyBsaW1pdGF0aW9uczoKCiAtIE9ubHkg
QmlnUXVlcnkgdGFibGVzIGhhdmUgdGhlbS4KIC0gVGhleSBvbmx5IGluY2x1ZGUgQmlnUXVl
cnkgcXVlcnkgam9icy4KIC0gVGhleSBtaWdodCBiZSB1bmRlcmVzdGltYXRlZCBiZWNhdXNl
IHdpbGRjYXJkIHRhYmxlIHJlZmVyZW5jZXMKICAgYXJlIG5vdCB5ZXQgY291bnRlZC4gRm9y
IG1vcmUgaW5mb3JtYXRpb24sIHNlZQogICBbUXVlcnlpbmcgbXVsdGlwbGUgdGFibGVzIHVz
aW5nIGEgd2lsZGNhcmQgdGFibGVdCiAgIChodHRwczovL2Nsb3VkLmdvb2dsZS5jb20vYmln
cXVlcnkvZG9jcy9xdWVyeWluZy13aWxkY2FyZC10YWJsZXMpCgoKCgMEAAESAyYIEgpFCgQE
AAIAEgMoAh4aOCBUaGUgbnVtYmVyIG9mIHN1Y2Nlc3NmdWwgdXNlcyBvZiB0aGUgdW5kZXJs
eWluZyBlbnRyeS4KCgwKBQQAAgAFEgMoAgcKDAoFBAACAAESAygIGQoMCgUEAAIAAxIDKBwd
CkkKBAQAAgESAysCGxo8IFRoZSBudW1iZXIgb2YgZmFpbGVkIGF0dGVtcHRzIHRvIHVzZSB0
aGUgdW5kZXJseWluZyBlbnRyeS4KCgwKBQQAAgEFEgMrAgcKDAoFBAACAQESAysIFgoMCgUE
AAIBAxIDKxkaCkwKBAQAAgISAy4CIBo/IFRoZSBudW1iZXIgb2YgY2FuY2VsbGVkIGF0dGVt
cHRzIHRvIHVzZSB0aGUgdW5kZXJseWluZyBlbnRyeS4KCgwKBQQAAgIFEgMuAgcKDAoFBAAC
AgESAy4IGwoMCgUEAAICAxIDLh4fCkkKBAQAAgMSAzECOBo8IFRvdGFsIHRpbWUgc3BlbnQg
b25seSBvbiBzdWNjZXNzZnVsIHVzZXMsIGluIG1pbGxpc2Vjb25kcy4KCgwKBQQAAgMFEgMx
AgcKDAoFBAACAwESAzEIMwoMCgUEAAIDAxIDMTY3ClYKAgQBEgQ3ADoBGkogQ29tbW9uIHN0
YXRpc3RpY3Mgb24gdGhlIGVudHJ5J3MgdXNhZ2UuCgogVGhleSBjYW4gYmUgc2V0IG9uIGFu
eSBzeXN0ZW0uCgoKCgMEAQESAzcIGAorCgQEAQIAEgM5AiAaHiBWaWV3IGNvdW50IGluIHNv
dXJjZSBzeXN0ZW0uCgoMCgUEAQIABBIDOQIKCgwKBQQBAgAFEgM5CxAKDAoFBAECAAESAzkR
GwoMCgUEAQIAAxIDOR4fCscBCgIEAhIEQABSARq6ASBUaGUgc2V0IG9mIGFsbCB1c2FnZSBz
aWduYWxzIHRoYXQgRGF0YSBDYXRhbG9nIHN0b3Jlcy4KCiBOb3RlOiBVc3VhbGx5LCB0aGVz
ZSBzaWduYWxzIGFyZSB1cGRhdGVkIGRhaWx5LiBJbiByYXJlIGNhc2VzLCBhbiB1cGRhdGUg
bWF5CiBmYWlsIGJ1dCB3aWxsIGJlIHBlcmZvcm1lZCBhZ2FpbiBvbiB0aGUgbmV4dCBkYXku
CgoKCgMEAgESA0AIEwpFCgQEAgIAEgNCAiwaOCBUaGUgZW5kIHRpbWVzdGFtcCBvZiB0aGUg
ZHVyYXRpb24gb2YgdXNhZ2Ugc3RhdGlzdGljcy4KCgwKBQQCAgAGEgNCAhsKDAoFBAICAAES
A0IcJwoMCgUEAgIAAxIDQiorCpUBCgQEAgIBEgRIAkkyGoYBIE91dHB1dCBvbmx5LiBCaWdR
dWVyeSB1c2FnZSBzdGF0aXN0aWNzIG92ZXIgZWFjaCBvZiB0aGUgcHJlZGVmaW5lZCB0aW1l
CiByYW5nZXMuCgogU3VwcG9ydGVkIHRpbWUgcmFuZ2VzIGFyZSBgeyIyNEgiLCAiN0QiLCAi
MzBEIn1gLgoKDAoFBAICAQYSA0gCGQoMCgUEAgIBARIDSBoxCgwKBQQCAgEDEgNINDUKDAoF
BAICAQgSA0kGMQoPCggEAgIBCJwIABIDSQcwCpABCgQEAgICEgNOAkMaggEgQ29tbW9uIHVz
YWdlIHN0YXRpc3RpY3Mgb3ZlciBlYWNoIG9mIHRoZSBwcmVkZWZpbmVkIHRpbWUgcmFuZ2Vz
LgoKIFN1cHBvcnRlZCB0aW1lIHJhbmdlcyBhcmUgYHsiMjRIIiwgIjdEIiwgIjMwRCIsICJM
aWZldGltZSJ9YC4KCgwKBQQCAgIGEgNOAh8KDAoFBAICAgESA04gPgoMCgUEAgICAxIDTkFC
CjMKBAQCAgMSA1ECJBomIEZhdm9yaXRlIGNvdW50IGluIHRoZSBzb3VyY2Ugc3lzdGVtLgoK
DAoFBAICAwQSA1ECCgoMCgUEAgIDBRIDUQsQCgwKBQQCAgMBEgNRER8KDAoFBAICAwMSA1Ei
I2IGcHJvdG8z
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Datacatalog::V1::Usage::UsageStats ===
    # Fields for UsageStats
    # Field: total_completions Type: 2 ()
    # Field: total_failures Type: 2 ()
    # Field: total_cancellations Type: 2 ()
    # Field: total_execution_time_for_completions_millis Type: 2 ()

# === Message: Google::Cloud::Datacatalog::V1::Usage::CommonUsageStats ===
    # Fields for CommonUsageStats
    # Field: view_count Type: 3 ()

# === Message: Google::Cloud::Datacatalog::V1::Usage::UsageSignal ===
    # Fields for UsageSignal
    # Field: update_time Type: 11 (.google.protobuf.Timestamp)
    # Field: usage_within_time_range Type: 11 (.google.cloud.datacatalog.v1.UsageSignal.UsageWithinTimeRangeEntry)
    # Field: common_usage_within_time_range Type: 11 (.google.cloud.datacatalog.v1.UsageSignal.CommonUsageWithinTimeRangeEntry)
    # Field: favorite_count Type: 3 ()

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Datacatalog::V1::Usage - Compiled Protocol Buffers messages for google/cloud/datacatalog/v1/usage.proto

=head1 SYNOPSIS

    use Google::Cloud::Datacatalog::V1::Usage;

    my $msg = Google::Cloud::Datacatalog::V1::Usage::UsageStats->new({
        total_completions => $total_completions,
        total_failures => $total_failures,
        total_cancellations => $total_cancellations,
        total_execution_time_for_completions_millis => $total_execution_time_for_completions_millis,
    });

    # Read or update a field
    my $val = $msg->total_completions();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Datacatalog::V1::Usage::UsageStats->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/datacatalog/v1/usage.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Datacatalog::V1::Usage::UsageStats

Detailed statistics on the entry's usage.

Usage statistics have the following limitations:

- Only BigQuery tables have them.
- They only include BigQuery query jobs.
- They might be underestimated because wildcard table references
  are not yet counted. For more information, see
  [Querying multiple tables using a wildcard table]
  (https://cloud.google.com/bigquery/docs/querying-wildcard-tables)

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->total_completions() >> / C<< $msg->total_completions($value) >>

Type: C<Float>

The number of successful uses of the underlying entry.

=item * C<< $msg->total_failures() >> / C<< $msg->total_failures($value) >>

Type: C<Float>

The number of failed attempts to use the underlying entry.

=item * C<< $msg->total_cancellations() >> / C<< $msg->total_cancellations($value) >>

Type: C<Float>

The number of cancelled attempts to use the underlying entry.

=item * C<< $msg->total_execution_time_for_completions_millis() >> / C<< $msg->total_execution_time_for_completions_millis($value) >>

Type: C<Float>

Total time spent only on successful uses, in milliseconds.

=back

=head2 Google::Cloud::Datacatalog::V1::Usage::CommonUsageStats

Common statistics on the entry's usage.

They can be set on any system.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->view_count() >> / C<< $msg->view_count($value) >>

Type: C<Int64>

View count in source system.

=back

=head2 Google::Cloud::Datacatalog::V1::Usage::UsageSignal

The set of all usage signals that Data Catalog stores.

Note: Usually, these signals are updated daily. In rare cases, an update may
fail but will be performed again on the next day.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->update_time() >> / C<< $msg->update_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

The end timestamp of the duration of usage statistics.

=item * C<< $msg->usage_within_time_range() >> / C<< $msg->usage_within_time_range($value) >>

Type: C<Message> (L<Google::Cloud::Datacatalog::V1::Usage::UsageSignal::UsageWithinTimeRangeEntry>)

Output only. BigQuery usage statistics over each of the predefined time
ranges.

Supported time ranges are `{"24H", "7D", "30D"}`.

=item * C<< $msg->common_usage_within_time_range() >> / C<< $msg->common_usage_within_time_range($value) >>

Type: C<Message> (L<Google::Cloud::Datacatalog::V1::Usage::UsageSignal::CommonUsageWithinTimeRangeEntry>)

Common usage statistics over each of the predefined time ranges.

Supported time ranges are `{"24H", "7D", "30D", "Lifetime"}`.

=item * C<< $msg->favorite_count() >> / C<< $msg->favorite_count($value) >>

Type: C<Int64>

Favorite count in the source system.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Datacatalog::V1::Usage::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
