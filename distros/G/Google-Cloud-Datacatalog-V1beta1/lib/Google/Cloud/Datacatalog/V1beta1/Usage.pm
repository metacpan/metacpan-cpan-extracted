package Google::Cloud::Datacatalog::V1beta1::Usage;

use strict;
use warnings;

our $VERSION = '0.14';

use Protobuf::Message;
use Protobuf::DescriptorPool;
use Protobuf::Internal qw(:all);
use MIME::Base64;

BEGIN {
    eval { require Google::Protobuf::Timestamp };
    my $descriptor_b64 = <<'EOF';
Cixnb29nbGUvY2xvdWQvZGF0YWNhdGFsb2cvdjFiZXRhMS91c2FnZS5wcm90bxIgZ29vZ2xl
LmNsb3VkLmRhdGFjYXRhbG9nLnYxYmV0YTEaH2dvb2dsZS9wcm90b2J1Zi90aW1lc3RhbXAu
cHJvdG8i7gEKClVzYWdlU3RhdHMSKwoRdG90YWxfY29tcGxldGlvbnMYASABKAJSEHRvdGFs
Q29tcGxldGlvbnMSJQoOdG90YWxfZmFpbHVyZXMYAiABKAJSDXRvdGFsRmFpbHVyZXMSLwoT
dG90YWxfY2FuY2VsbGF0aW9ucxgDIAEoAlISdG90YWxDYW5jZWxsYXRpb25zElsKK3RvdGFs
X2V4ZWN1dGlvbl90aW1lX2Zvcl9jb21wbGV0aW9uc19taWxsaXMYBCABKAJSJnRvdGFsRXhl
Y3V0aW9uVGltZUZvckNvbXBsZXRpb25zTWlsbGlzIsECCgtVc2FnZVNpZ25hbBI7Cgt1cGRh
dGVfdGltZRgBIAEoCzIaLmdvb2dsZS5wcm90b2J1Zi5UaW1lc3RhbXBSCnVwZGF0ZVRpbWUS
fgoXdXNhZ2Vfd2l0aGluX3RpbWVfcmFuZ2UYAiADKAsyRy5nb29nbGUuY2xvdWQuZGF0YWNh
dGFsb2cudjFiZXRhMS5Vc2FnZVNpZ25hbC5Vc2FnZVdpdGhpblRpbWVSYW5nZUVudHJ5UhR1
c2FnZVdpdGhpblRpbWVSYW5nZRp1ChlVc2FnZVdpdGhpblRpbWVSYW5nZUVudHJ5EhAKA2tl
eRgBIAEoCVIDa2V5EkIKBXZhbHVlGAIgASgLMiwuZ29vZ2xlLmNsb3VkLmRhdGFjYXRhbG9n
LnYxYmV0YTEuVXNhZ2VTdGF0c1IFdmFsdWU6AjgBQtwBCiRjb20uZ29vZ2xlLmNsb3VkLmRh
dGFjYXRhbG9nLnYxYmV0YTFQAVpGY2xvdWQuZ29vZ2xlLmNvbS9nby9kYXRhY2F0YWxvZy9h
cGl2MWJldGExL2RhdGFjYXRhbG9ncGI7ZGF0YWNhdGFsb2dwYqoCIEdvb2dsZS5DbG91ZC5E
YXRhQ2F0YWxvZy5WMUJldGExygIgR29vZ2xlXENsb3VkXERhdGFDYXRhbG9nXFYxYmV0YTHq
AiNHb29nbGU6OkNsb3VkOjpEYXRhQ2F0YWxvZzo6VjFiZXRhMUrtDwoGEgQOADoBCrwECgEM
EgMOABIysQQgQ29weXJpZ2h0IDIwMjUgR29vZ2xlIExMQwoKIExpY2Vuc2VkIHVuZGVyIHRo
ZSBBcGFjaGUgTGljZW5zZSwgVmVyc2lvbiAyLjAgKHRoZSAiTGljZW5zZSIpOwogeW91IG1h
eSBub3QgdXNlIHRoaXMgZmlsZSBleGNlcHQgaW4gY29tcGxpYW5jZSB3aXRoIHRoZSBMaWNl
bnNlLgogWW91IG1heSBvYnRhaW4gYSBjb3B5IG9mIHRoZSBMaWNlbnNlIGF0CgogICAgIGh0
dHA6Ly93d3cuYXBhY2hlLm9yZy9saWNlbnNlcy9MSUNFTlNFLTIuMAoKIFVubGVzcyByZXF1
aXJlZCBieSBhcHBsaWNhYmxlIGxhdyBvciBhZ3JlZWQgdG8gaW4gd3JpdGluZywgc29mdHdh
cmUKIGRpc3RyaWJ1dGVkIHVuZGVyIHRoZSBMaWNlbnNlIGlzIGRpc3RyaWJ1dGVkIG9uIGFu
ICJBUyBJUyIgQkFTSVMsCiBXSVRIT1VUIFdBUlJBTlRJRVMgT1IgQ09ORElUSU9OUyBPRiBB
TlkgS0lORCwgZWl0aGVyIGV4cHJlc3Mgb3IgaW1wbGllZC4KIFNlZSB0aGUgTGljZW5zZSBm
b3IgdGhlIHNwZWNpZmljIGxhbmd1YWdlIGdvdmVybmluZyBwZXJtaXNzaW9ucyBhbmQKIGxp
bWl0YXRpb25zIHVuZGVyIHRoZSBMaWNlbnNlLgoKCAoBAhIDEAApCgkKAgMAEgMSACkKCAoB
CBIDFAA9CgkKAgglEgMUAD0KCAoBCBIDFQBdCgkKAggLEgMVAF0KCAoBCBIDFgAiCgkKAggK
EgMWACIKCAoBCBIDFwA9CgkKAggBEgMXAD0KCAoBCBIDGAA9CgkKAggpEgMYAD0KCAoBCBID
GQA8CgkKAggtEgMZADwK0QIKAgQAEgQiADABGsQCIERldGFpbGVkIGNvdW50cyBvbiB0aGUg
ZW50cnkncyB1c2FnZS4KIENhdmVhdHM6CiAtIE9ubHkgQmlnUXVlcnkgdGFibGVzIGhhdmUg
dXNhZ2Ugc3RhdHMKIC0gVGhlIHVzYWdlIHN0YXRzIG9ubHkgaW5jbHVkZSBCaWdRdWVyeSBx
dWVyeSBqb2JzCiAtIFRoZSB1c2FnZSBzdGF0cyBtaWdodCBiZSB1bmRlcmVzdGltYXRlZCwg
ZS5nLiB3aWxkY2FyZCB0YWJsZSByZWZlcmVuY2VzCiBhcmUgbm90IHlldCBjb3VudGVkIGlu
IHVzYWdlIGNvbXB1dGF0aW9uCiBodHRwczovL2Nsb3VkLmdvb2dsZS5jb20vYmlncXVlcnkv
ZG9jcy9xdWVyeWluZy13aWxkY2FyZC10YWJsZXMKCgoKAwQAARIDIggSClMKBAQAAgASAyQC
HhpGIFRoZSBudW1iZXIgb2YgdGltZXMgdGhhdCB0aGUgdW5kZXJseWluZyBlbnRyeSB3YXMg
c3VjY2Vzc2Z1bGx5IHVzZWQuCgoMCgUEAAIABRIDJAIHCgwKBQQAAgABEgMkCBkKDAoFBAAC
AAMSAyQcHQpiCgQEAAIBEgMoAhsaVSBUaGUgbnVtYmVyIG9mIHRpbWVzIHRoYXQgdGhlIHVu
ZGVybHlpbmcgZW50cnkgd2FzIGF0dGVtcHRlZCB0byBiZSB1c2VkCiBidXQgZmFpbGVkLgoK
DAoFBAACAQUSAygCBwoMCgUEAAIBARIDKAgWCgwKBQQAAgEDEgMoGRoKdQoEBAACAhIDLAIg
GmggVGhlIG51bWJlciBvZiB0aW1lcyB0aGF0IHRoZSB1bmRlcmx5aW5nIGVudHJ5IHdhcyBh
dHRlbXB0ZWQgdG8gYmUgdXNlZAogYnV0IHdhcyBjYW5jZWxsZWQgYnkgdGhlIHVzZXIuCgoM
CgUEAAICBRIDLAIHCgwKBQQAAgIBEgMsCBsKDAoFBAACAgMSAyweHwpaCgQEAAIDEgMvAjga
TSBUb3RhbCB0aW1lIHNwZW50IChpbiBtaWxsaXNlY29uZHMpIGR1cmluZyB1c2VzIHRoZSBy
ZXN1bHRlZCBpbiBjb21wbGV0aW9ucy4KCgwKBQQAAgMFEgMvAgcKDAoFBAACAwESAy8IMwoM
CgUEAAIDAxIDLzY3CkkKAgQBEgQzADoBGj0gVGhlIHNldCBvZiBhbGwgdXNhZ2Ugc2lnbmFs
cyB0aGF0IHdlIHN0b3JlIGluIERhdGEgQ2F0YWxvZy4KCgoKAwQBARIDMwgTCkkKBAQBAgAS
AzUCLBo8IFRoZSB0aW1lc3RhbXAgb2YgdGhlIGVuZCBvZiB0aGUgdXNhZ2Ugc3RhdGlzdGlj
cyBkdXJhdGlvbi4KCgwKBQQBAgAGEgM1AhsKDAoFBAECAAESAzUcJwoMCgUEAQIAAxIDNSor
CoYBCgQEAQIBEgM5AjYaeSBVc2FnZSBzdGF0aXN0aWNzIG92ZXIgZWFjaCBvZiB0aGUgcHJl
LWRlZmluZWQgdGltZSByYW5nZXMsIHN1cHBvcnRlZAogc3RyaW5ncyBmb3IgdGltZSByYW5n
ZXMgYXJlIHsiMjRIIiwgIjdEIiwgIjMwRCJ9LgoKDAoFBAECAQYSAzkCGQoMCgUEAQIBARID
ORoxCgwKBQQBAgEDEgM5NDViBnByb3RvMw==
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Datacatalog::V1beta1::Usage::UsageStats ===
    # Fields for UsageStats
    # Field: total_completions Type: 2 ()
    # Field: total_failures Type: 2 ()
    # Field: total_cancellations Type: 2 ()
    # Field: total_execution_time_for_completions_millis Type: 2 ()

# === Message: Google::Cloud::Datacatalog::V1beta1::Usage::UsageSignal ===
    # Fields for UsageSignal
    # Field: update_time Type: 11 (.google.protobuf.Timestamp)
    # Field: usage_within_time_range Type: 11 (.google.cloud.datacatalog.v1beta1.UsageSignal.UsageWithinTimeRangeEntry)

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Datacatalog::V1beta1::Usage - Compiled Protocol Buffers messages for google/cloud/datacatalog/v1beta1/usage.proto

=head1 SYNOPSIS

    use Google::Cloud::Datacatalog::V1beta1::Usage;

    my $msg = Google::Cloud::Datacatalog::V1beta1::Usage::UsageStats->new({
        total_completions => $total_completions,
        total_failures => $total_failures,
        total_cancellations => $total_cancellations,
        total_execution_time_for_completions_millis => $total_execution_time_for_completions_millis,
    });

    # Read or update a field
    my $val = $msg->total_completions();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Datacatalog::V1beta1::Usage::UsageStats->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/datacatalog/v1beta1/usage.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Datacatalog::V1beta1::Usage::UsageStats

Detailed counts on the entry's usage.
Caveats:
- Only BigQuery tables have usage stats
- The usage stats only include BigQuery query jobs
- The usage stats might be underestimated, e.g. wildcard table references
are not yet counted in usage computation
https://cloud.google.com/bigquery/docs/querying-wildcard-tables

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->total_completions() >> / C<< $msg->total_completions($value) >>

Type: C<Float>

The number of times that the underlying entry was successfully used.

=item * C<< $msg->total_failures() >> / C<< $msg->total_failures($value) >>

Type: C<Float>

The number of times that the underlying entry was attempted to be used
but failed.

=item * C<< $msg->total_cancellations() >> / C<< $msg->total_cancellations($value) >>

Type: C<Float>

The number of times that the underlying entry was attempted to be used
but was cancelled by the user.

=item * C<< $msg->total_execution_time_for_completions_millis() >> / C<< $msg->total_execution_time_for_completions_millis($value) >>

Type: C<Float>

Total time spent (in milliseconds) during uses the resulted in completions.

=back

=head2 Google::Cloud::Datacatalog::V1beta1::Usage::UsageSignal

The set of all usage signals that we store in Data Catalog.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->update_time() >> / C<< $msg->update_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

The timestamp of the end of the usage statistics duration.

=item * C<< $msg->usage_within_time_range() >> / C<< $msg->usage_within_time_range($value) >>

Type: C<Message> (L<Google::Cloud::Datacatalog::V1beta1::Usage::UsageSignal::UsageWithinTimeRangeEntry>)

Usage statistics over each of the pre-defined time ranges, supported
strings for time ranges are {"24H", "7D", "30D"}.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Datacatalog::V1beta1::Usage::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
