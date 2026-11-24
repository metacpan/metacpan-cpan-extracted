package Google::Cloud::Faulttesting::V1alpha::Logging;

use strict;
use warnings;

our $VERSION = '0.14';

use Protobuf::Message;
use Protobuf::DescriptorPool;
use Protobuf::Internal qw(:all);
use MIME::Base64;

BEGIN {
    eval { require Google::Api::FieldBehavior };
    eval { require Google::Api::Resource };
    eval { require Google::Cloud::Faulttesting::V1alpha::State };
    eval { require Google::Protobuf::Struct };
    eval { require Google::Protobuf::Timestamp };
    my $descriptor_b64 = <<'EOF';
Ci9nb29nbGUvY2xvdWQvZmF1bHR0ZXN0aW5nL3YxYWxwaGEvbG9nZ2luZy5wcm90bxIhZ29v
Z2xlLmNsb3VkLmZhdWx0dGVzdGluZy52MWFscGhhGh9nb29nbGUvYXBpL2ZpZWxkX2JlaGF2
aW9yLnByb3RvGhlnb29nbGUvYXBpL3Jlc291cmNlLnByb3RvGi1nb29nbGUvY2xvdWQvZmF1
bHR0ZXN0aW5nL3YxYWxwaGEvc3RhdGUucHJvdG8aHGdvb2dsZS9wcm90b2J1Zi9zdHJ1Y3Qu
cHJvdG8aH2dvb2dsZS9wcm90b2J1Zi90aW1lc3RhbXAucHJvdG8iuwIKD0ZhdWx0VGVzdGlu
Z0xvZxI+CgpldmVudF90aW1lGAEgASgLMhouZ29vZ2xlLnByb3RvYnVmLlRpbWVzdGFtcEID
4EECUglldmVudFRpbWUSTgoKZXhwZXJpbWVudBgCIAEoCUIu4EEC+kEoCiZmYXVsdHRlc3Rp
bmcuZ29vZ2xlYXBpcy5jb20vRXhwZXJpbWVudFIKZXhwZXJpbWVudBJDCgVzdGF0ZRgDIAEo
DjIoLmdvb2dsZS5jbG91ZC5mYXVsdHRlc3RpbmcudjFhbHBoYS5TdGF0ZUID4EEDUgVzdGF0
ZRIbCgZyZWFzb24YBCABKAlCA+BBAVIGcmVhc29uEjYKB2RldGFpbHMYBSABKAsyFy5nb29n
bGUucHJvdG9idWYuU3RydWN0QgPgQQFSB2RldGFpbHNC8QEKJWNvbS5nb29nbGUuY2xvdWQu
ZmF1bHR0ZXN0aW5nLnYxYWxwaGFCDExvZ2dpbmdQcm90b1ABWkljbG91ZC5nb29nbGUuY29t
L2dvL2ZhdWx0dGVzdGluZy9hcGl2MWFscGhhL2ZhdWx0dGVzdGluZ3BiO2ZhdWx0dGVzdGlu
Z3BiqgIhR29vZ2xlLkNsb3VkLkZhdWx0VGVzdGluZy5WMUFscGhhygIhR29vZ2xlXENsb3Vk
XEZhdWx0VGVzdGluZ1xWMWFscGhh6gIkR29vZ2xlOjpDbG91ZDo6RmF1bHRUZXN0aW5nOjpW
MWFscGhhSpsNCgYSBA4AOAEKvAQKAQwSAw4AEjKxBCBDb3B5cmlnaHQgMjAyNiBHb29nbGUg
TExDCgogTGljZW5zZWQgdW5kZXIgdGhlIEFwYWNoZSBMaWNlbnNlLCBWZXJzaW9uIDIuMCAo
dGhlICJMaWNlbnNlIik7CiB5b3UgbWF5IG5vdCB1c2UgdGhpcyBmaWxlIGV4Y2VwdCBpbiBj
b21wbGlhbmNlIHdpdGggdGhlIExpY2Vuc2UuCiBZb3UgbWF5IG9idGFpbiBhIGNvcHkgb2Yg
dGhlIExpY2Vuc2UgYXQKCiAgICAgaHR0cDovL3d3dy5hcGFjaGUub3JnL2xpY2Vuc2VzL0xJ
Q0VOU0UtMi4wCgogVW5sZXNzIHJlcXVpcmVkIGJ5IGFwcGxpY2FibGUgbGF3IG9yIGFncmVl
ZCB0byBpbiB3cml0aW5nLCBzb2Z0d2FyZQogZGlzdHJpYnV0ZWQgdW5kZXIgdGhlIExpY2Vu
c2UgaXMgZGlzdHJpYnV0ZWQgb24gYW4gIkFTIElTIiBCQVNJUywKIFdJVEhPVVQgV0FSUkFO
VElFUyBPUiBDT05ESVRJT05TIE9GIEFOWSBLSU5ELCBlaXRoZXIgZXhwcmVzcyBvciBpbXBs
aWVkLgogU2VlIHRoZSBMaWNlbnNlIGZvciB0aGUgc3BlY2lmaWMgbGFuZ3VhZ2UgZ292ZXJu
aW5nIHBlcm1pc3Npb25zIGFuZAogbGltaXRhdGlvbnMgdW5kZXIgdGhlIExpY2Vuc2UuCgoI
CgECEgMQACoKCQoCAwASAxIAKQoJCgIDARIDEwAjCgkKAgMCEgMUADcKCQoCAwMSAxUAJgoJ
CgIDBBIDFgApCggKAQgSAxgAPgoJCgIIJRIDGAA+CggKAQgSAxkAYAoJCgIICxIDGQBgCggK
AQgSAxoAIgoJCgIIChIDGgAiCggKAQgSAxsALQoJCgIICBIDGwAtCggKAQgSAxwAPgoJCgII
ARIDHAA+CggKAQgSAx0APgoJCgIIKRIDHQA+CggKAQgSAx4APQoJCgIILRIDHgA9CjcKAgQA
EgQhADgBGisgUmVwcmVzZW50cyB0aGUgcGF5bG9hZCBvZiBhIFBsYXRmb3JtIExvZy4KCgoK
AwQAARIDIQgXClsKBAQAAgASBCMCJC8aTSBSZXF1aXJlZC4gSW5kaWNhdGVzIHRoZSB0aW1l
IHRoZSBldmVudCBkZXNjcmliZWQgYnkgdGhlIGxvZyBlbnRyeSBvY2N1cnJlZC4KCgwKBQQA
AgAGEgMjAhsKDAoFBAACAAESAyMcJgoMCgUEAAIAAxIDIykqCgwKBQQAAgAIEgMkBi4KDwoI
BAACAAicCAASAyQHLQpwCgQEAAIBEgQoAi0EGmIgUmVxdWlyZWQuIFNwZWNpZmllcyB0aGUg
cmVzb3VyY2UgbmFtZSBvZiB0aGUgZXhwZXJpbWVudCB0aGF0IHRoaXMgbG9nIGVudHJ5CiBp
cyBhc3NvY2lhdGVkIHdpdGguCgoMCgUEAAIBBRIDKAIICgwKBQQAAgEBEgMoCRMKDAoFBAAC
AQMSAygWFwoNCgUEAAIBCBIEKBgtAwoPCggEAAIBCJwIABIDKQQqCg8KBwQAAgEInwgSBCoE
LAUKXwoEBAACAhIDMQI+GlIgT3V0cHV0IG9ubHkuIFJlcHJlc2VudHMgdGhlIHN0YXRlIG9m
IHRoZSByZXNvdXJjZSBhZnRlciB0aGUgZXZlbnQuCiBPdXRwdXQgb25seS4KCgwKBQQAAgIG
EgMxAgcKDAoFBAACAgESAzEIDQoMCgUEAAICAxIDMRARCgwKBQQAAgIIEgMxEj0KDwoIBAAC
AgicCAASAzETPApDCgQEAAIDEgM0Aj0aNiBPcHRpb25hbC4gRGVzY3JpYmVzIHRoZSByZWFz
b24gZm9yIHRoZSBzdGF0ZSBjaGFuZ2UuCgoMCgUEAAIDBRIDNAIICgwKBQQAAgMBEgM0CQ8K
DAoFBAACAwMSAzQSEwoMCgUEAAIDCBIDNBQ8Cg8KCAQAAgMInAgAEgM0FTsKRQoEBAACBBID
NwJOGjggT3B0aW9uYWwuIFByb3ZpZGVzIGFkZGl0aW9uYWwgZGV0YWlscyBhYm91dCB0aGUg
ZXZlbnQuCgoMCgUEAAIEBhIDNwIYCgwKBQQAAgQBEgM3GSAKDAoFBAACBAMSAzcjJAoMCgUE
AAIECBIDNyVNCg8KCAQAAgQInAgAEgM3JkxiBnByb3RvMw==
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Faulttesting::V1alpha::Logging::FaultTestingLog ===
    # Fields for FaultTestingLog
    # Field: event_time Type: 11 (.google.protobuf.Timestamp)
    # Field: experiment Type: 9 ()
    # Field: state Type: 14 (.google.cloud.faulttesting.v1alpha.State)
    # Field: reason Type: 9 ()
    # Field: details Type: 11 (.google.protobuf.Struct)

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Faulttesting::V1alpha::Logging - Compiled Protocol Buffers messages for google/cloud/faulttesting/v1alpha/logging.proto

=head1 SYNOPSIS

    use Google::Cloud::Faulttesting::V1alpha::Logging;

    my $msg = Google::Cloud::Faulttesting::V1alpha::Logging::FaultTestingLog->new({
        event_time => $event_time,
        experiment => $experiment,
        state => $state,
        reason => $reason,
    });

    # Read or update a field
    my $val = $msg->event_time();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Faulttesting::V1alpha::Logging::FaultTestingLog->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/faulttesting/v1alpha/logging.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Faulttesting::V1alpha::Logging::FaultTestingLog

Represents the payload of a Platform Log.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->event_time() >> / C<< $msg->event_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Required. Indicates the time the event described by the log entry occurred.

=item * C<< $msg->experiment() >> / C<< $msg->experiment($value) >>

Type: C<String>

Required. Specifies the resource name of the experiment that this log entry
is associated with.

=item * C<< $msg->state() >> / C<< $msg->state($value) >>

Type: C<Enum> (L<Google::Cloud::Faulttesting::V1alpha::State>)

Output only. Represents the state of the resource after the event.
Output only.

=item * C<< $msg->reason() >> / C<< $msg->reason($value) >>

Type: C<String>

Optional. Describes the reason for the state change.

=item * C<< $msg->details() >> / C<< $msg->details($value) >>

Type: C<Message> (L<Google::Protobuf::Struct::Struct>)

Optional. Provides additional details about the event.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Faulttesting::V1alpha::Logging::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
