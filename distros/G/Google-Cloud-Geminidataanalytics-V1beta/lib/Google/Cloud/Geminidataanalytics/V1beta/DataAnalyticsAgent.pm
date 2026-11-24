package Google::Cloud::Geminidataanalytics::V1beta::DataAnalyticsAgent;

use strict;
use warnings;

our $VERSION = '0.14';

use Protobuf::Message;
use Protobuf::DescriptorPool;
use Protobuf::Internal qw(:all);
use MIME::Base64;

BEGIN {
    eval { require Google::Api::FieldBehavior };
    eval { require Google::Cloud::Geminidataanalytics::V1beta::Context };
    my $descriptor_b64 = <<'EOF';
CkJnb29nbGUvY2xvdWQvZ2VtaW5pZGF0YWFuYWx5dGljcy92MWJldGEvZGF0YV9hbmFseXRp
Y3NfYWdlbnQucHJvdG8SJ2dvb2dsZS5jbG91ZC5nZW1pbmlkYXRhYW5hbHl0aWNzLnYxYmV0
YRofZ29vZ2xlL2FwaS9maWVsZF9iZWhhdmlvci5wcm90bxo1Z29vZ2xlL2Nsb3VkL2dlbWlu
aWRhdGFhbmFseXRpY3MvdjFiZXRhL2NvbnRleHQucHJvdG8ixQIKEkRhdGFBbmFseXRpY3NB
Z2VudBJeCg9zdGFnaW5nX2NvbnRleHQYBSABKAsyMC5nb29nbGUuY2xvdWQuZ2VtaW5pZGF0
YWFuYWx5dGljcy52MWJldGEuQ29udGV4dEID4EEBUg5zdGFnaW5nQ29udGV4dBJiChFwdWJs
aXNoZWRfY29udGV4dBgGIAEoCzIwLmdvb2dsZS5jbG91ZC5nZW1pbmlkYXRhYW5hbHl0aWNz
LnYxYmV0YS5Db250ZXh0QgPgQQFSEHB1Ymxpc2hlZENvbnRleHQSawoWbGFzdF9wdWJsaXNo
ZWRfY29udGV4dBgHIAEoCzIwLmdvb2dsZS5jbG91ZC5nZW1pbmlkYXRhYW5hbHl0aWNzLnYx
YmV0YS5Db250ZXh0QgPgQQNSFGxhc3RQdWJsaXNoZWRDb250ZXh0QqgCCitjb20uZ29vZ2xl
LmNsb3VkLmdlbWluaWRhdGFhbmFseXRpY3MudjFiZXRhQhdEYXRhQW5hbHl0aWNzQWdlbnRQ
cm90b1ABWl1jbG91ZC5nb29nbGUuY29tL2dvL2dlbWluaWRhdGFhbmFseXRpY3MvYXBpdjFi
ZXRhL2dlbWluaWRhdGFhbmFseXRpY3NwYjtnZW1pbmlkYXRhYW5hbHl0aWNzcGKqAidHb29n
bGUuQ2xvdWQuR2VtaW5pRGF0YUFuYWx5dGljcy5WMUJldGHKAidHb29nbGVcQ2xvdWRcR2Vt
aW5pRGF0YUFuYWx5dGljc1xWMWJldGHqAipHb29nbGU6OkNsb3VkOjpHZW1pbmlEYXRhQW5h
bHl0aWNzOjpWMWJldGFK9gsKBhIEDgAtAQq8BAoBDBIDDgASMrEEIENvcHlyaWdodCAyMDI2
IEdvb2dsZSBMTEMKCiBMaWNlbnNlZCB1bmRlciB0aGUgQXBhY2hlIExpY2Vuc2UsIFZlcnNp
b24gMi4wICh0aGUgIkxpY2Vuc2UiKTsKIHlvdSBtYXkgbm90IHVzZSB0aGlzIGZpbGUgZXhj
ZXB0IGluIGNvbXBsaWFuY2Ugd2l0aCB0aGUgTGljZW5zZS4KIFlvdSBtYXkgb2J0YWluIGEg
Y29weSBvZiB0aGUgTGljZW5zZSBhdAoKICAgICBodHRwOi8vd3d3LmFwYWNoZS5vcmcvbGlj
ZW5zZXMvTElDRU5TRS0yLjAKCiBVbmxlc3MgcmVxdWlyZWQgYnkgYXBwbGljYWJsZSBsYXcg
b3IgYWdyZWVkIHRvIGluIHdyaXRpbmcsIHNvZnR3YXJlCiBkaXN0cmlidXRlZCB1bmRlciB0
aGUgTGljZW5zZSBpcyBkaXN0cmlidXRlZCBvbiBhbiAiQVMgSVMiIEJBU0lTLAogV0lUSE9V
VCBXQVJSQU5USUVTIE9SIENPTkRJVElPTlMgT0YgQU5ZIEtJTkQsIGVpdGhlciBleHByZXNz
IG9yIGltcGxpZWQuCiBTZWUgdGhlIExpY2Vuc2UgZm9yIHRoZSBzcGVjaWZpYyBsYW5ndWFn
ZSBnb3Zlcm5pbmcgcGVybWlzc2lvbnMgYW5kCiBsaW1pdGF0aW9ucyB1bmRlciB0aGUgTGlj
ZW5zZS4KCggKAQISAxAAMAoJCgIDABIDEgApCgkKAgMBEgMTAD8KCAoBCBIDFQBECgkKAggl
EgMVAEQKCAoBCBIDFgB0CgkKAggLEgMWAHQKCAoBCBIDFwAiCgkKAggKEgMXACIKCAoBCBID
GAA4CgkKAggIEgMYADgKCAoBCBIDGQBECgkKAggBEgMZAEQKCAoBCBIDGgBECgkKAggpEgMa
AEQKCAoBCBIDGwBDCgkKAggtEgMbAEMKPQoCBAASBB4ALQEaMSBNZXNzYWdlIGRlc2NyaWJp
bmcgYSBEYXRhQW5hbHl0aWNzQWdlbnQgb2JqZWN0LgoKCgoDBAABEgMeCBoKgQEKBAQAAgAS
AyECRxp0IE9wdGlvbmFsLiBUaGUgc3RhZ2luZyBjb250ZXh0IGZvciB0aGUgYWdlbnQuCiBU
aGlzIGNvbnRleHQgaXMgdXNlZCB0byB0ZXN0IGFuZCB2YWxpZGF0ZSBjaGFuZ2VzIGJlZm9y
ZSBwdWJsaXNoaW5nLgoKDAoFBAACAAYSAyECCQoMCgUEAAIAARIDIQoZCgwKBQQAAgADEgMh
HB0KDAoFBAACAAgSAyEeRgoPCggEAAIACJwIABIDIR9FCnIKBAQAAgESAyUCSRplIE9wdGlv
bmFsLiBUaGUgcHVibGlzaGVkIGNvbnRleHQgZm9yIHRoZSBhZ2VudC4KIFRoaXMgY29udGV4
dCBpcyB1c2VkIGJ5IHRoZSBDaGF0IEFQSSBpbiBwcm9kdWN0aW9uLgoKDAoFBAACAQYSAyUC
CQoMCgUEAAIBARIDJQobCgwKBQQAAgEDEgMlHh8KDAoFBAACAQgSAyUgSAoPCggEAAIBCJwI
ABIDJSFHCtsBCgQEAAICEgQrAiwyGswBIE91dHB1dCBvbmx5LiBUaGUgbGFzdCBwdWJsaXNo
ZWQgY29udGV4dCBmb3IgdGhlIGFnZW50LgogVGhpcyBpcyBhbiBvdXRwdXQtb25seSBmaWVs
ZCBwb3B1bGF0ZWQgYnkgdGhlIHN5c3RlbSB3aGVuIHRoZQogcHVibGlzaGVkIGNvbnRleHQg
aXMgdXBkYXRlZC4gSXQgaXMgdXNlZCB0byByZXN0b3JlIHRoZSBhZ2VudCB0byBhCiBwcmV2
aW91cyBzdGF0ZS4KCgwKBQQAAgIGEgMrAgkKDAoFBAACAgESAysKIAoMCgUEAAICAxIDKyMk
CgwKBQQAAgIIEgMsBjEKDwoIBAACAgicCAASAywHMGIGcHJvdG8z
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Geminidataanalytics::V1beta::DataAnalyticsAgent::DataAnalyticsAgent ===
    # Fields for DataAnalyticsAgent
    # Field: staging_context Type: 11 (.google.cloud.geminidataanalytics.v1beta.Context)
    # Field: published_context Type: 11 (.google.cloud.geminidataanalytics.v1beta.Context)
    # Field: last_published_context Type: 11 (.google.cloud.geminidataanalytics.v1beta.Context)

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Geminidataanalytics::V1beta::DataAnalyticsAgent - Compiled Protocol Buffers messages for google/cloud/geminidataanalytics/v1beta/data_analytics_agent.proto

=head1 SYNOPSIS

    use Google::Cloud::Geminidataanalytics::V1beta::DataAnalyticsAgent;

    my $msg = Google::Cloud::Geminidataanalytics::V1beta::DataAnalyticsAgent::DataAnalyticsAgent->new({
        staging_context => $staging_context,
        published_context => $published_context,
        last_published_context => $last_published_context,
    });

    # Read or update a field
    my $val = $msg->staging_context();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Geminidataanalytics::V1beta::DataAnalyticsAgent::DataAnalyticsAgent->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/geminidataanalytics/v1beta/data_analytics_agent.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Geminidataanalytics::V1beta::DataAnalyticsAgent::DataAnalyticsAgent

Message describing a DataAnalyticsAgent object.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->staging_context() >> / C<< $msg->staging_context($value) >>

Type: C<Message> (L<Google::Cloud::Geminidataanalytics::V1beta::Context::Context>)

Optional. The staging context for the agent.
This context is used to test and validate changes before publishing.

=item * C<< $msg->published_context() >> / C<< $msg->published_context($value) >>

Type: C<Message> (L<Google::Cloud::Geminidataanalytics::V1beta::Context::Context>)

Optional. The published context for the agent.
This context is used by the Chat API in production.

=item * C<< $msg->last_published_context() >> / C<< $msg->last_published_context($value) >>

Type: C<Message> (L<Google::Cloud::Geminidataanalytics::V1beta::Context::Context>)

Output only. The last published context for the agent.
This is an output-only field populated by the system when the
published context is updated. It is used to restore the agent to a
previous state.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Geminidataanalytics::V1beta::DataAnalyticsAgent::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
