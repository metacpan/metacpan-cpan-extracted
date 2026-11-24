package Google::Cloud::Geminidataanalytics::V1alpha::AgentContext;

use strict;
use warnings;

our $VERSION = '0.14';

use Protobuf::Message;
use Protobuf::DescriptorPool;
use Protobuf::Internal qw(:all);
use MIME::Base64;

BEGIN {
    eval { require Google::Api::FieldBehavior };
    my $descriptor_b64 = <<'EOF';
Cjxnb29nbGUvY2xvdWQvZ2VtaW5pZGF0YWFuYWx5dGljcy92MWFscGhhL2FnZW50X2NvbnRl
eHQucHJvdG8SKGdvb2dsZS5jbG91ZC5nZW1pbmlkYXRhYW5hbHl0aWNzLnYxYWxwaGEaH2dv
b2dsZS9hcGkvZmllbGRfYmVoYXZpb3IucHJvdG8iQgoVQWdlbnRDb250ZXh0UmVmZXJlbmNl
EikKDmNvbnRleHRfc2V0X2lkGAEgASgJQgPgQQJSDGNvbnRleHRTZXRJZEKnAgosY29tLmdv
b2dsZS5jbG91ZC5nZW1pbmlkYXRhYW5hbHl0aWNzLnYxYWxwaGFCEUFnZW50Q29udGV4dFBy
b3RvUAFaXmNsb3VkLmdvb2dsZS5jb20vZ28vZ2VtaW5pZGF0YWFuYWx5dGljcy9hcGl2MWFs
cGhhL2dlbWluaWRhdGFhbmFseXRpY3NwYjtnZW1pbmlkYXRhYW5hbHl0aWNzcGKqAihHb29n
bGUuQ2xvdWQuR2VtaW5pRGF0YUFuYWx5dGljcy5WMUFscGhhygIoR29vZ2xlXENsb3VkXEdl
bWluaURhdGFBbmFseXRpY3NcVjFhbHBoYeoCK0dvb2dsZTo6Q2xvdWQ6OkdlbWluaURhdGFB
bmFseXRpY3M6OlYxYWxwaGFKvAcKBhIEDgAgAQq8BAoBDBIDDgASMrEEIENvcHlyaWdodCAy
MDI2IEdvb2dsZSBMTEMKCiBMaWNlbnNlZCB1bmRlciB0aGUgQXBhY2hlIExpY2Vuc2UsIFZl
cnNpb24gMi4wICh0aGUgIkxpY2Vuc2UiKTsKIHlvdSBtYXkgbm90IHVzZSB0aGlzIGZpbGUg
ZXhjZXB0IGluIGNvbXBsaWFuY2Ugd2l0aCB0aGUgTGljZW5zZS4KIFlvdSBtYXkgb2J0YWlu
IGEgY29weSBvZiB0aGUgTGljZW5zZSBhdAoKICAgICBodHRwOi8vd3d3LmFwYWNoZS5vcmcv
bGljZW5zZXMvTElDRU5TRS0yLjAKCiBVbmxlc3MgcmVxdWlyZWQgYnkgYXBwbGljYWJsZSBs
YXcgb3IgYWdyZWVkIHRvIGluIHdyaXRpbmcsIHNvZnR3YXJlCiBkaXN0cmlidXRlZCB1bmRl
ciB0aGUgTGljZW5zZSBpcyBkaXN0cmlidXRlZCBvbiBhbiAiQVMgSVMiIEJBU0lTLAogV0lU
SE9VVCBXQVJSQU5USUVTIE9SIENPTkRJVElPTlMgT0YgQU5ZIEtJTkQsIGVpdGhlciBleHBy
ZXNzIG9yIGltcGxpZWQuCiBTZWUgdGhlIExpY2Vuc2UgZm9yIHRoZSBzcGVjaWZpYyBsYW5n
dWFnZSBnb3Zlcm5pbmcgcGVybWlzc2lvbnMgYW5kCiBsaW1pdGF0aW9ucyB1bmRlciB0aGUg
TGljZW5zZS4KCggKAQISAxAAMQoJCgIDABIDEgApCggKAQgSAxQARQoJCgIIJRIDFABFCggK
AQgSAxUAdQoJCgIICxIDFQB1CggKAQgSAxYAIgoJCgIIChIDFgAiCggKAQgSAxcAMgoJCgII
CBIDFwAyCggKAQgSAxgARQoJCgIIARIDGABFCggKAQgSAxkARQoJCgIIKRIDGQBFCggKAQgS
AxoARAoJCgIILRIDGgBECkAKAgQAEgQdACABGjQgTWVzc2FnZSByZXByZXNlbnRpbmcgYSBy
ZWZlcmVuY2UgdG8gQWdlbnQgQ29udGV4dC4KCgoKAwQAARIDHQgdCjQKBAQAAgASAx8CRRon
IFJlcXVpcmVkLiBDb250ZXh0IHNldCBJRCB0byByZXRyaWV2ZS4KCgwKBQQAAgAFEgMfAggK
DAoFBAACAAESAx8JFwoMCgUEAAIAAxIDHxobCgwKBQQAAgAIEgMfHEQKDwoIBAACAAicCAAS
Ax8dQ2IGcHJvdG8z
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Geminidataanalytics::V1alpha::AgentContext::AgentContextReference ===
    # Fields for AgentContextReference
    # Field: context_set_id Type: 9 ()

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Geminidataanalytics::V1alpha::AgentContext - Compiled Protocol Buffers messages for google/cloud/geminidataanalytics/v1alpha/agent_context.proto

=head1 SYNOPSIS

    use Google::Cloud::Geminidataanalytics::V1alpha::AgentContext;

    my $msg = Google::Cloud::Geminidataanalytics::V1alpha::AgentContext::AgentContextReference->new({
        context_set_id => $context_set_id,
    });

    # Read or update a field
    my $val = $msg->context_set_id();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Geminidataanalytics::V1alpha::AgentContext::AgentContextReference->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/geminidataanalytics/v1alpha/agent_context.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Geminidataanalytics::V1alpha::AgentContext::AgentContextReference

Message representing a reference to Agent Context.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->context_set_id() >> / C<< $msg->context_set_id($value) >>

Type: C<String>

Required. Context set ID to retrieve.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Geminidataanalytics::V1alpha::AgentContext::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
