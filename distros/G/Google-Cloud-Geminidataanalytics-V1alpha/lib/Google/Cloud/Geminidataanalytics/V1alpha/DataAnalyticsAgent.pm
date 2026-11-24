package Google::Cloud::Geminidataanalytics::V1alpha::DataAnalyticsAgent;

use strict;
use warnings;

our $VERSION = '0.14';

use Protobuf::Message;
use Protobuf::DescriptorPool;
use Protobuf::Internal qw(:all);
use MIME::Base64;

BEGIN {
    eval { require Google::Api::FieldBehavior };
    eval { require Google::Cloud::Geminidataanalytics::V1alpha::Context };
    my $descriptor_b64 = <<'EOF';
CkNnb29nbGUvY2xvdWQvZ2VtaW5pZGF0YWFuYWx5dGljcy92MWFscGhhL2RhdGFfYW5hbHl0
aWNzX2FnZW50LnByb3RvEihnb29nbGUuY2xvdWQuZ2VtaW5pZGF0YWFuYWx5dGljcy52MWFs
cGhhGh9nb29nbGUvYXBpL2ZpZWxkX2JlaGF2aW9yLnByb3RvGjZnb29nbGUvY2xvdWQvZ2Vt
aW5pZGF0YWFuYWx5dGljcy92MWFscGhhL2NvbnRleHQucHJvdG8iyAIKEkRhdGFBbmFseXRp
Y3NBZ2VudBJfCg9zdGFnaW5nX2NvbnRleHQYBSABKAsyMS5nb29nbGUuY2xvdWQuZ2VtaW5p
ZGF0YWFuYWx5dGljcy52MWFscGhhLkNvbnRleHRCA+BBAVIOc3RhZ2luZ0NvbnRleHQSYwoR
cHVibGlzaGVkX2NvbnRleHQYBiABKAsyMS5nb29nbGUuY2xvdWQuZ2VtaW5pZGF0YWFuYWx5
dGljcy52MWFscGhhLkNvbnRleHRCA+BBAVIQcHVibGlzaGVkQ29udGV4dBJsChZsYXN0X3B1
Ymxpc2hlZF9jb250ZXh0GAcgASgLMjEuZ29vZ2xlLmNsb3VkLmdlbWluaWRhdGFhbmFseXRp
Y3MudjFhbHBoYS5Db250ZXh0QgPgQQNSFGxhc3RQdWJsaXNoZWRDb250ZXh0Qq0CCixjb20u
Z29vZ2xlLmNsb3VkLmdlbWluaWRhdGFhbmFseXRpY3MudjFhbHBoYUIXRGF0YUFuYWx5dGlj
c0FnZW50UHJvdG9QAVpeY2xvdWQuZ29vZ2xlLmNvbS9nby9nZW1pbmlkYXRhYW5hbHl0aWNz
L2FwaXYxYWxwaGEvZ2VtaW5pZGF0YWFuYWx5dGljc3BiO2dlbWluaWRhdGFhbmFseXRpY3Nw
YqoCKEdvb2dsZS5DbG91ZC5HZW1pbmlEYXRhQW5hbHl0aWNzLlYxQWxwaGHKAihHb29nbGVc
Q2xvdWRcR2VtaW5pRGF0YUFuYWx5dGljc1xWMWFscGhh6gIrR29vZ2xlOjpDbG91ZDo6R2Vt
aW5pRGF0YUFuYWx5dGljczo6VjFhbHBoYUr2CwoGEgQOAC0BCrwECgEMEgMOABIysQQgQ29w
eXJpZ2h0IDIwMjYgR29vZ2xlIExMQwoKIExpY2Vuc2VkIHVuZGVyIHRoZSBBcGFjaGUgTGlj
ZW5zZSwgVmVyc2lvbiAyLjAgKHRoZSAiTGljZW5zZSIpOwogeW91IG1heSBub3QgdXNlIHRo
aXMgZmlsZSBleGNlcHQgaW4gY29tcGxpYW5jZSB3aXRoIHRoZSBMaWNlbnNlLgogWW91IG1h
eSBvYnRhaW4gYSBjb3B5IG9mIHRoZSBMaWNlbnNlIGF0CgogICAgIGh0dHA6Ly93d3cuYXBh
Y2hlLm9yZy9saWNlbnNlcy9MSUNFTlNFLTIuMAoKIFVubGVzcyByZXF1aXJlZCBieSBhcHBs
aWNhYmxlIGxhdyBvciBhZ3JlZWQgdG8gaW4gd3JpdGluZywgc29mdHdhcmUKIGRpc3RyaWJ1
dGVkIHVuZGVyIHRoZSBMaWNlbnNlIGlzIGRpc3RyaWJ1dGVkIG9uIGFuICJBUyBJUyIgQkFT
SVMsCiBXSVRIT1VUIFdBUlJBTlRJRVMgT1IgQ09ORElUSU9OUyBPRiBBTlkgS0lORCwgZWl0
aGVyIGV4cHJlc3Mgb3IgaW1wbGllZC4KIFNlZSB0aGUgTGljZW5zZSBmb3IgdGhlIHNwZWNp
ZmljIGxhbmd1YWdlIGdvdmVybmluZyBwZXJtaXNzaW9ucyBhbmQKIGxpbWl0YXRpb25zIHVu
ZGVyIHRoZSBMaWNlbnNlLgoKCAoBAhIDEAAxCgkKAgMAEgMSACkKCQoCAwESAxMAQAoICgEI
EgMVAEUKCQoCCCUSAxUARQoICgEIEgMWAHUKCQoCCAsSAxYAdQoICgEIEgMXACIKCQoCCAoS
AxcAIgoICgEIEgMYADgKCQoCCAgSAxgAOAoICgEIEgMZAEUKCQoCCAESAxkARQoICgEIEgMa
AEUKCQoCCCkSAxoARQoICgEIEgMbAEQKCQoCCC0SAxsARAo9CgIEABIEHgAtARoxIE1lc3Nh
Z2UgZGVzY3JpYmluZyBhIERhdGFBbmFseXRpY3NBZ2VudCBvYmplY3QuCgoKCgMEAAESAx4I
GgqBAQoEBAACABIDIQJHGnQgT3B0aW9uYWwuIFRoZSBzdGFnaW5nIGNvbnRleHQgZm9yIHRo
ZSBhZ2VudC4KIFRoaXMgY29udGV4dCBpcyB1c2VkIHRvIHRlc3QgYW5kIHZhbGlkYXRlIGNo
YW5nZXMgYmVmb3JlIHB1Ymxpc2hpbmcuCgoMCgUEAAIABhIDIQIJCgwKBQQAAgABEgMhChkK
DAoFBAACAAMSAyEcHQoMCgUEAAIACBIDIR5GCg8KCAQAAgAInAgAEgMhH0UKcgoEBAACARID
JQJJGmUgT3B0aW9uYWwuIFRoZSBwdWJsaXNoZWQgY29udGV4dCBmb3IgdGhlIGFnZW50Lgog
VGhpcyBjb250ZXh0IGlzIHVzZWQgYnkgdGhlIENoYXQgQVBJIGluIHByb2R1Y3Rpb24uCgoM
CgUEAAIBBhIDJQIJCgwKBQQAAgEBEgMlChsKDAoFBAACAQMSAyUeHwoMCgUEAAIBCBIDJSBI
Cg8KCAQAAgEInAgAEgMlIUcK2wEKBAQAAgISBCsCLDIazAEgT3V0cHV0IG9ubHkuIFRoZSBs
YXN0IHB1Ymxpc2hlZCBjb250ZXh0IGZvciB0aGUgYWdlbnQuCiBUaGlzIGlzIGFuIG91dHB1
dC1vbmx5IGZpZWxkIHBvcHVsYXRlZCBieSB0aGUgc3lzdGVtIHdoZW4gdGhlCiBwdWJsaXNo
ZWQgY29udGV4dCBpcyB1cGRhdGVkLiBJdCBpcyB1c2VkIHRvIHJlc3RvcmUgdGhlIGFnZW50
IHRvIGEKIHByZXZpb3VzIHN0YXRlLgoKDAoFBAACAgYSAysCCQoMCgUEAAICARIDKwogCgwK
BQQAAgIDEgMrIyQKDAoFBAACAggSAywGMQoPCggEAAICCJwIABIDLAcwYgZwcm90bzM=
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Geminidataanalytics::V1alpha::DataAnalyticsAgent::DataAnalyticsAgent ===
    # Fields for DataAnalyticsAgent
    # Field: staging_context Type: 11 (.google.cloud.geminidataanalytics.v1alpha.Context)
    # Field: published_context Type: 11 (.google.cloud.geminidataanalytics.v1alpha.Context)
    # Field: last_published_context Type: 11 (.google.cloud.geminidataanalytics.v1alpha.Context)

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Geminidataanalytics::V1alpha::DataAnalyticsAgent - Compiled Protocol Buffers messages for google/cloud/geminidataanalytics/v1alpha/data_analytics_agent.proto

=head1 SYNOPSIS

    use Google::Cloud::Geminidataanalytics::V1alpha::DataAnalyticsAgent;

    my $msg = Google::Cloud::Geminidataanalytics::V1alpha::DataAnalyticsAgent::DataAnalyticsAgent->new({
        staging_context => $staging_context,
        published_context => $published_context,
        last_published_context => $last_published_context,
    });

    # Read or update a field
    my $val = $msg->staging_context();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Geminidataanalytics::V1alpha::DataAnalyticsAgent::DataAnalyticsAgent->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/geminidataanalytics/v1alpha/data_analytics_agent.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Geminidataanalytics::V1alpha::DataAnalyticsAgent::DataAnalyticsAgent

Message describing a DataAnalyticsAgent object.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->staging_context() >> / C<< $msg->staging_context($value) >>

Type: C<Message> (L<Google::Cloud::Geminidataanalytics::V1alpha::Context::Context>)

Optional. The staging context for the agent.
This context is used to test and validate changes before publishing.

=item * C<< $msg->published_context() >> / C<< $msg->published_context($value) >>

Type: C<Message> (L<Google::Cloud::Geminidataanalytics::V1alpha::Context::Context>)

Optional. The published context for the agent.
This context is used by the Chat API in production.

=item * C<< $msg->last_published_context() >> / C<< $msg->last_published_context($value) >>

Type: C<Message> (L<Google::Cloud::Geminidataanalytics::V1alpha::Context::Context>)

Output only. The last published context for the agent.
This is an output-only field populated by the system when the
published context is updated. It is used to restore the agent to a
previous state.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Geminidataanalytics::V1alpha::DataAnalyticsAgent::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
