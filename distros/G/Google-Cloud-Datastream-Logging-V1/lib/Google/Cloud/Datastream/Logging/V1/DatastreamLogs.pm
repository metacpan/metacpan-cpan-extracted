package Google::Cloud::Datastream::Logging::V1::DatastreamLogs;

use strict;
use warnings;

our $VERSION = '0.14';

use Protobuf::Message;
use Protobuf::DescriptorPool;
use Protobuf::Internal qw(:all);
use MIME::Base64;

BEGIN {
    eval { require Google::Api::FieldBehavior };
    eval { require Google::Cloud::Datastream::V1::DatastreamResources };
    my $descriptor_b64 = <<'EOF';
Cjhnb29nbGUvY2xvdWQvZGF0YXN0cmVhbS9sb2dnaW5nL3YxL2RhdGFzdHJlYW1fbG9ncy5w
cm90bxIiZ29vZ2xlLmNsb3VkLmRhdGFzdHJlYW0ubG9nZ2luZy52MRofZ29vZ2xlL2FwaS9m
aWVsZF9iZWhhdmlvci5wcm90bxo1Z29vZ2xlL2Nsb3VkL2RhdGFzdHJlYW0vdjEvZGF0YXN0
cmVhbV9yZXNvdXJjZXMucHJvdG8izgIKFlN0cmVhbUFjdGl2aXR5TG9nRW50cnkSHQoKZXZl
bnRfY29kZRgBIAEoCVIJZXZlbnRDb2RlEiMKDWV2ZW50X21lc3NhZ2UYAiABKAlSDGV2ZW50
TWVzc2FnZRJ+ChNzdHJlYW1fc3RhdGVfY2hhbmdlGGQgASgLMkwuZ29vZ2xlLmNsb3VkLmRh
dGFzdHJlYW0ubG9nZ2luZy52MS5TdHJlYW1BY3Rpdml0eUxvZ0VudHJ5LlN0cmVhbVN0YXRl
Q2hhbmdlSABSEXN0cmVhbVN0YXRlQ2hhbmdlGl8KEVN0cmVhbVN0YXRlQ2hhbmdlEkoKCW5l
d19zdGF0ZRgBIAEoDjIoLmdvb2dsZS5jbG91ZC5kYXRhc3RyZWFtLnYxLlN0cmVhbS5TdGF0
ZUID4EEDUghuZXdTdGF0ZUIPCg1ldmVudF9wYXlsb2FkQvQBCiZjb20uZ29vZ2xlLmNsb3Vk
LmRhdGFzdHJlYW0ubG9nZ2luZy52MUITRGF0YXN0cmVhbUxvZ3NQcm90b1ABWkBjbG91ZC5n
b29nbGUuY29tL2dvL2RhdGFzdHJlYW0vbG9nZ2luZy9hcGl2MS9sb2dnaW5ncGI7bG9nZ2lu
Z3BiqgIiR29vZ2xlLkNsb3VkLkRhdGFzdHJlYW0uTG9nZ2luZy5WMcoCIkdvb2dsZVxDbG91
ZFxEYXRhc3RyZWFtXExvZ2dpbmdcVjHqAiZHb29nbGU6OkNsb3VkOjpEYXRhc3RyZWFtOjpM
b2dnaW5nOjpWMUrjCgoGEgQOADABCrwECgEMEgMOABIysQQgQ29weXJpZ2h0IDIwMjUgR29v
Z2xlIExMQwoKIExpY2Vuc2VkIHVuZGVyIHRoZSBBcGFjaGUgTGljZW5zZSwgVmVyc2lvbiAy
LjAgKHRoZSAiTGljZW5zZSIpOwogeW91IG1heSBub3QgdXNlIHRoaXMgZmlsZSBleGNlcHQg
aW4gY29tcGxpYW5jZSB3aXRoIHRoZSBMaWNlbnNlLgogWW91IG1heSBvYnRhaW4gYSBjb3B5
IG9mIHRoZSBMaWNlbnNlIGF0CgogICAgIGh0dHA6Ly93d3cuYXBhY2hlLm9yZy9saWNlbnNl
cy9MSUNFTlNFLTIuMAoKIFVubGVzcyByZXF1aXJlZCBieSBhcHBsaWNhYmxlIGxhdyBvciBh
Z3JlZWQgdG8gaW4gd3JpdGluZywgc29mdHdhcmUKIGRpc3RyaWJ1dGVkIHVuZGVyIHRoZSBM
aWNlbnNlIGlzIGRpc3RyaWJ1dGVkIG9uIGFuICJBUyBJUyIgQkFTSVMsCiBXSVRIT1VUIFdB
UlJBTlRJRVMgT1IgQ09ORElUSU9OUyBPRiBBTlkgS0lORCwgZWl0aGVyIGV4cHJlc3Mgb3Ig
aW1wbGllZC4KIFNlZSB0aGUgTGljZW5zZSBmb3IgdGhlIHNwZWNpZmljIGxhbmd1YWdlIGdv
dmVybmluZyBwZXJtaXNzaW9ucyBhbmQKIGxpbWl0YXRpb25zIHVuZGVyIHRoZSBMaWNlbnNl
LgoKCAoBAhIDEAArCgkKAgMAEgMSACkKCQoCAwESAxMAPwoICgEIEgMVAD8KCQoCCCUSAxUA
PwoICgEIEgMWAFcKCQoCCAsSAxYAVwoICgEIEgMXACIKCQoCCAoSAxcAIgoICgEIEgMYADQK
CQoCCAgSAxgANAoICgEIEgMZAD8KCQoCCAESAxkAPwoICgEIEgMaAEAKCQoCCCkSAxoAQAoI
CgEIEgMbAD8KCQoCCC0SAxsAPwpACgIEABIEHgAwARo0IExvZyBkZWZpbml0aW9uIGZvciBh
Y3Rpdml0aWVzIHJlbGF0ZWQgdG8gYSBzdHJlYW0uCgoKCgMEAAESAx4IHgo+CgQEAAMAEgQg
AiQDGjAgUGF5bG9hZCBmb3IgYSBjaGFuZ2UgaW4gdGhlIHN0YXRlIG9mIGEgc3RyZWFtLgoK
DAoFBAADAAESAyAKGwo0CgYEAAMAAgASBCIEIzQaJCBPdXRwdXQgb25seS4gVGhlIG5ldyBz
dHJlYW0gc3RhdGUuCgoOCgcEAAMAAgAGEgMiBCsKDgoHBAADAAIAARIDIiw1Cg4KBwQAAwAC
AAMSAyI4OQoOCgcEAAMAAgAIEgMjCDMKEQoKBAADAAIACJwIABIDIwkyCi0KBAQAAgASAycC
GBogIEEgY29kZSByZXByZXNlbnRpbmcgdGhlIGV2ZW50LgoKDAoFBAACAAUSAycCCAoMCgUE
AAIAARIDJwkTCgwKBQQAAgADEgMnFhcKOAoEBAACARIDKgIbGisgQSBmcmVlLXRleHQgbWVz
c2FnZSBkZXNjcmliaW5nIHRoZSBldmVudC4KCgwKBQQAAgEFEgMqAggKDAoFBAACAQESAyoJ
FgoMCgUEAAIBAxIDKhkaCgwKBAQACAASBCwCLwMKDAoFBAAIAAESAywIFQo/CgQEAAICEgMu
BDAaMiBBIHBheWxvYWQgZm9yIGEgY2hhbmdlIGluIHRoZSBzdGF0ZSBvZiBhIHN0cmVhbS4K
CgwKBQQAAgIGEgMuBBUKDAoFBAACAgESAy4WKQoMCgUEAAICAxIDLiwvYgZwcm90bzM=
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Datastream::Logging::V1::DatastreamLogs::StreamActivityLogEntry ===
    # Fields for StreamActivityLogEntry
    # Field: event_code Type: 9 ()
    # Field: event_message Type: 9 ()
    # Field: stream_state_change Type: 11 (.google.cloud.datastream.logging.v1.StreamActivityLogEntry.StreamStateChange)

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Datastream::Logging::V1::DatastreamLogs - Compiled Protocol Buffers messages for google/cloud/datastream/logging/v1/datastream_logs.proto

=head1 SYNOPSIS

    use Google::Cloud::Datastream::Logging::V1::DatastreamLogs;

    my $msg = Google::Cloud::Datastream::Logging::V1::DatastreamLogs::StreamActivityLogEntry->new({
        event_code => $event_code,
        event_message => $event_message,
        stream_state_change => $stream_state_change,
    });

    # Read or update a field
    my $val = $msg->event_code();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Datastream::Logging::V1::DatastreamLogs::StreamActivityLogEntry->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/datastream/logging/v1/datastream_logs.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Datastream::Logging::V1::DatastreamLogs::StreamActivityLogEntry

Log definition for activities related to a stream.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->event_code() >> / C<< $msg->event_code($value) >>

Type: C<String>

A code representing the event.

=item * C<< $msg->event_message() >> / C<< $msg->event_message($value) >>

Type: C<String>

A free-text message describing the event.

=item * C<< $msg->stream_state_change() >> / C<< $msg->stream_state_change($value) >>

Type: C<Message> (L<Google::Cloud::Datastream::Logging::V1::DatastreamLogs::StreamActivityLogEntry::StreamStateChange>)

A payload for a change in the state of a stream.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Datastream::Logging::V1::DatastreamLogs::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
