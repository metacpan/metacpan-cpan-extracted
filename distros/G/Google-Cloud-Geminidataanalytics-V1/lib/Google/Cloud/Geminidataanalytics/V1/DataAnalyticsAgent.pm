package Google::Cloud::Geminidataanalytics::V1::DataAnalyticsAgent;

use strict;
use warnings;

our $VERSION = '0.14';

use Protobuf::Message;
use Protobuf::DescriptorPool;
use Protobuf::Internal qw(:all);
use MIME::Base64;

BEGIN {
    eval { require Google::Api::FieldBehavior };
    eval { require Google::Cloud::Geminidataanalytics::V1::Context };
    my $descriptor_b64 = <<'EOF';
Cj5nb29nbGUvY2xvdWQvZ2VtaW5pZGF0YWFuYWx5dGljcy92MS9kYXRhX2FuYWx5dGljc19h
Z2VudC5wcm90bxIjZ29vZ2xlLmNsb3VkLmdlbWluaWRhdGFhbmFseXRpY3MudjEaH2dvb2ds
ZS9hcGkvZmllbGRfYmVoYXZpb3IucHJvdG8aMWdvb2dsZS9jbG91ZC9nZW1pbmlkYXRhYW5h
bHl0aWNzL3YxL2NvbnRleHQucHJvdG8iuQIKEkRhdGFBbmFseXRpY3NBZ2VudBJaCg9zdGFn
aW5nX2NvbnRleHQYBSABKAsyLC5nb29nbGUuY2xvdWQuZ2VtaW5pZGF0YWFuYWx5dGljcy52
MS5Db250ZXh0QgPgQQFSDnN0YWdpbmdDb250ZXh0El4KEXB1Ymxpc2hlZF9jb250ZXh0GAYg
ASgLMiwuZ29vZ2xlLmNsb3VkLmdlbWluaWRhdGFhbmFseXRpY3MudjEuQ29udGV4dEID4EEB
UhBwdWJsaXNoZWRDb250ZXh0EmcKFmxhc3RfcHVibGlzaGVkX2NvbnRleHQYByABKAsyLC5n
b29nbGUuY2xvdWQuZ2VtaW5pZGF0YWFuYWx5dGljcy52MS5Db250ZXh0QgPgQQNSFGxhc3RQ
dWJsaXNoZWRDb250ZXh0QpQCCidjb20uZ29vZ2xlLmNsb3VkLmdlbWluaWRhdGFhbmFseXRp
Y3MudjFCF0RhdGFBbmFseXRpY3NBZ2VudFByb3RvUAFaWWNsb3VkLmdvb2dsZS5jb20vZ28v
Z2VtaW5pZGF0YWFuYWx5dGljcy9hcGl2MS9nZW1pbmlkYXRhYW5hbHl0aWNzcGI7Z2VtaW5p
ZGF0YWFuYWx5dGljc3BiqgIjR29vZ2xlLkNsb3VkLkdlbWluaURhdGFBbmFseXRpY3MuVjHK
AiNHb29nbGVcQ2xvdWRcR2VtaW5pRGF0YUFuYWx5dGljc1xWMeoCJkdvb2dsZTo6Q2xvdWQ6
OkdlbWluaURhdGFBbmFseXRpY3M6OlYxSvYLCgYSBA4ALQEKvAQKAQwSAw4AEjKxBCBDb3B5
cmlnaHQgMjAyNiBHb29nbGUgTExDCgogTGljZW5zZWQgdW5kZXIgdGhlIEFwYWNoZSBMaWNl
bnNlLCBWZXJzaW9uIDIuMCAodGhlICJMaWNlbnNlIik7CiB5b3UgbWF5IG5vdCB1c2UgdGhp
cyBmaWxlIGV4Y2VwdCBpbiBjb21wbGlhbmNlIHdpdGggdGhlIExpY2Vuc2UuCiBZb3UgbWF5
IG9idGFpbiBhIGNvcHkgb2YgdGhlIExpY2Vuc2UgYXQKCiAgICAgaHR0cDovL3d3dy5hcGFj
aGUub3JnL2xpY2Vuc2VzL0xJQ0VOU0UtMi4wCgogVW5sZXNzIHJlcXVpcmVkIGJ5IGFwcGxp
Y2FibGUgbGF3IG9yIGFncmVlZCB0byBpbiB3cml0aW5nLCBzb2Z0d2FyZQogZGlzdHJpYnV0
ZWQgdW5kZXIgdGhlIExpY2Vuc2UgaXMgZGlzdHJpYnV0ZWQgb24gYW4gIkFTIElTIiBCQVNJ
UywKIFdJVEhPVVQgV0FSUkFOVElFUyBPUiBDT05ESVRJT05TIE9GIEFOWSBLSU5ELCBlaXRo
ZXIgZXhwcmVzcyBvciBpbXBsaWVkLgogU2VlIHRoZSBMaWNlbnNlIGZvciB0aGUgc3BlY2lm
aWMgbGFuZ3VhZ2UgZ292ZXJuaW5nIHBlcm1pc3Npb25zIGFuZAogbGltaXRhdGlvbnMgdW5k
ZXIgdGhlIExpY2Vuc2UuCgoICgECEgMQACwKCQoCAwASAxIAKQoJCgIDARIDEwA7CggKAQgS
AxUAQAoJCgIIJRIDFQBACggKAQgSAxYAcAoJCgIICxIDFgBwCggKAQgSAxcAIgoJCgIIChID
FwAiCggKAQgSAxgAOAoJCgIICBIDGAA4CggKAQgSAxkAQAoJCgIIARIDGQBACggKAQgSAxoA
QAoJCgIIKRIDGgBACggKAQgSAxsAPwoJCgIILRIDGwA/Cj0KAgQAEgQeAC0BGjEgTWVzc2Fn
ZSBkZXNjcmliaW5nIGEgRGF0YUFuYWx5dGljc0FnZW50IG9iamVjdC4KCgoKAwQAARIDHgga
CoEBCgQEAAIAEgMhAkcadCBPcHRpb25hbC4gVGhlIHN0YWdpbmcgY29udGV4dCBmb3IgdGhl
IGFnZW50LgogVGhpcyBjb250ZXh0IGlzIHVzZWQgdG8gdGVzdCBhbmQgdmFsaWRhdGUgY2hh
bmdlcyBiZWZvcmUgcHVibGlzaGluZy4KCgwKBQQAAgAGEgMhAgkKDAoFBAACAAESAyEKGQoM
CgUEAAIAAxIDIRwdCgwKBQQAAgAIEgMhHkYKDwoIBAACAAicCAASAyEfRQpyCgQEAAIBEgMl
AkkaZSBPcHRpb25hbC4gVGhlIHB1Ymxpc2hlZCBjb250ZXh0IGZvciB0aGUgYWdlbnQuCiBU
aGlzIGNvbnRleHQgaXMgdXNlZCBieSB0aGUgQ2hhdCBBUEkgaW4gcHJvZHVjdGlvbi4KCgwK
BQQAAgEGEgMlAgkKDAoFBAACAQESAyUKGwoMCgUEAAIBAxIDJR4fCgwKBQQAAgEIEgMlIEgK
DwoIBAACAQicCAASAyUhRwrbAQoEBAACAhIEKwIsMhrMASBPdXRwdXQgb25seS4gVGhlIGxh
c3QgcHVibGlzaGVkIGNvbnRleHQgZm9yIHRoZSBhZ2VudC4KIFRoaXMgaXMgYW4gb3V0cHV0
LW9ubHkgZmllbGQgcG9wdWxhdGVkIGJ5IHRoZSBzeXN0ZW0gd2hlbiB0aGUKIHB1Ymxpc2hl
ZCBjb250ZXh0IGlzIHVwZGF0ZWQuIEl0IGlzIHVzZWQgdG8gcmVzdG9yZSB0aGUgYWdlbnQg
dG8gYQogcHJldmlvdXMgc3RhdGUuCgoMCgUEAAICBhIDKwIJCgwKBQQAAgIBEgMrCiAKDAoF
BAACAgMSAysjJAoMCgUEAAICCBIDLAYxCg8KCAQAAgIInAgAEgMsBzBiBnByb3RvMw==
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Geminidataanalytics::V1::DataAnalyticsAgent::DataAnalyticsAgent ===
    # Fields for DataAnalyticsAgent
    # Field: staging_context Type: 11 (.google.cloud.geminidataanalytics.v1.Context)
    # Field: published_context Type: 11 (.google.cloud.geminidataanalytics.v1.Context)
    # Field: last_published_context Type: 11 (.google.cloud.geminidataanalytics.v1.Context)

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Geminidataanalytics::V1::DataAnalyticsAgent - Compiled Protocol Buffers messages for google/cloud/geminidataanalytics/v1/data_analytics_agent.proto

=head1 SYNOPSIS

    use Google::Cloud::Geminidataanalytics::V1::DataAnalyticsAgent;

    my $msg = Google::Cloud::Geminidataanalytics::V1::DataAnalyticsAgent::DataAnalyticsAgent->new({
        staging_context => $staging_context,
        published_context => $published_context,
        last_published_context => $last_published_context,
    });

    # Read or update a field
    my $val = $msg->staging_context();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Geminidataanalytics::V1::DataAnalyticsAgent::DataAnalyticsAgent->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/geminidataanalytics/v1/data_analytics_agent.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Geminidataanalytics::V1::DataAnalyticsAgent::DataAnalyticsAgent

Message describing a DataAnalyticsAgent object.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->staging_context() >> / C<< $msg->staging_context($value) >>

Type: C<Message> (L<Google::Cloud::Geminidataanalytics::V1::Context::Context>)

Optional. The staging context for the agent.
This context is used to test and validate changes before publishing.

=item * C<< $msg->published_context() >> / C<< $msg->published_context($value) >>

Type: C<Message> (L<Google::Cloud::Geminidataanalytics::V1::Context::Context>)

Optional. The published context for the agent.
This context is used by the Chat API in production.

=item * C<< $msg->last_published_context() >> / C<< $msg->last_published_context($value) >>

Type: C<Message> (L<Google::Cloud::Geminidataanalytics::V1::Context::Context>)

Output only. The last published context for the agent.
This is an output-only field populated by the system when the
published context is updated. It is used to restore the agent to a
previous state.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Geminidataanalytics::V1::DataAnalyticsAgent::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
