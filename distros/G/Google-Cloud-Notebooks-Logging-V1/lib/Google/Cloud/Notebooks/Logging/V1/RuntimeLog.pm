package Google::Cloud::Notebooks::Logging::V1::RuntimeLog;

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
CjNnb29nbGUvY2xvdWQvbm90ZWJvb2tzL2xvZ2dpbmcvdjEvcnVudGltZV9sb2cucHJvdG8S
IWdvb2dsZS5jbG91ZC5ub3RlYm9va3MubG9nZ2luZy52MRofZ29vZ2xlL2FwaS9maWVsZF9i
ZWhhdmlvci5wcm90byLEAgoMUnVudGltZUV2ZW50ElIKBHR5cGUYASABKA4yOS5nb29nbGUu
Y2xvdWQubm90ZWJvb2tzLmxvZ2dpbmcudjEuUnVudGltZUV2ZW50LkV2ZW50VHlwZUID4EEC
UgR0eXBlElsKB2RldGFpbHMYAiADKAsyPC5nb29nbGUuY2xvdWQubm90ZWJvb2tzLmxvZ2dp
bmcudjEuUnVudGltZUV2ZW50LkRldGFpbHNFbnRyeUID4EEBUgdkZXRhaWxzGjoKDERldGFp
bHNFbnRyeRIQCgNrZXkYASABKAlSA2tleRIUCgV2YWx1ZRgCIAEoCVIFdmFsdWU6AjgBIkcK
CUV2ZW50VHlwZRIaChZFVkVOVF9UWVBFX1VOU1BFQ0lGSUVEEAASHgoaUlVOVElNRV9TVEFU
RV9DSEFOR0VfRVZFTlQQAUKfAQolY29tLmdvb2dsZS5jbG91ZC5ub3RlYm9va3MubG9nZ2lu
Zy52MUIPUnVudGltZUxvZ1Byb3RvUAFaP2Nsb3VkLmdvb2dsZS5jb20vZ28vbm90ZWJvb2tz
L2xvZ2dpbmcvYXBpdjEvbG9nZ2luZ3BiO2xvZ2dpbmdwYqoCIUdvb2dsZS5DbG91ZC5Ob3Rl
Ym9va3MuTG9nZ2luZy5WMUqJCgoGEgQOACwBCrwECgEMEgMOABIysQQgQ29weXJpZ2h0IDIw
MjUgR29vZ2xlIExMQwoKIExpY2Vuc2VkIHVuZGVyIHRoZSBBcGFjaGUgTGljZW5zZSwgVmVy
c2lvbiAyLjAgKHRoZSAiTGljZW5zZSIpOwogeW91IG1heSBub3QgdXNlIHRoaXMgZmlsZSBl
eGNlcHQgaW4gY29tcGxpYW5jZSB3aXRoIHRoZSBMaWNlbnNlLgogWW91IG1heSBvYnRhaW4g
YSBjb3B5IG9mIHRoZSBMaWNlbnNlIGF0CgogICAgIGh0dHA6Ly93d3cuYXBhY2hlLm9yZy9s
aWNlbnNlcy9MSUNFTlNFLTIuMAoKIFVubGVzcyByZXF1aXJlZCBieSBhcHBsaWNhYmxlIGxh
dyBvciBhZ3JlZWQgdG8gaW4gd3JpdGluZywgc29mdHdhcmUKIGRpc3RyaWJ1dGVkIHVuZGVy
IHRoZSBMaWNlbnNlIGlzIGRpc3RyaWJ1dGVkIG9uIGFuICJBUyBJUyIgQkFTSVMsCiBXSVRI
T1VUIFdBUlJBTlRJRVMgT1IgQ09ORElUSU9OUyBPRiBBTlkgS0lORCwgZWl0aGVyIGV4cHJl
c3Mgb3IgaW1wbGllZC4KIFNlZSB0aGUgTGljZW5zZSBmb3IgdGhlIHNwZWNpZmljIGxhbmd1
YWdlIGdvdmVybmluZyBwZXJtaXNzaW9ucyBhbmQKIGxpbWl0YXRpb25zIHVuZGVyIHRoZSBM
aWNlbnNlLgoKCAoBAhIDEAAqCgkKAgMAEgMSACkKCAoBCBIDFAA+CgkKAgglEgMUAD4KCAoB
CBIDFQBWCgkKAggLEgMVAFYKCAoBCBIDFgAiCgkKAggKEgMWACIKCAoBCBIDFwAwCgkKAggI
EgMXADAKCAoBCBIDGAA+CgkKAggBEgMYAD4KbwoCBAASBB0ALAEaLyBMb2cgY29udGVudCBv
ZiBhbiBldmVudCByZWxhdGVkIHRvIGEgcnVudGltZS4KMjIgRGVmaW5lcyBwcm90b3MgZm9y
IHJ1bnRpbWUgcmVsYXRlZCBwbGF0Zm9ybSBsb2dzCgoKCgMEAAESAx0IFAojCgQEAAQAEgQf
AiUDGhUgRGVmaW5lcyBldmVudCB0eXBlLgoKDAoFBAAEAAESAx8HEAooCgYEAAQAAgASAyEE
HxoZIEV2ZW50IGlzIG5vdCBzcGVjaWZpZWQuCgoOCgcEAAQAAgABEgMhBBoKDgoHBAAEAAIA
AhIDIR0eCjAKBgQABAACARIDJAQjGiEgUnVudGltZSBzdGF0ZSBoYXMgYmVlbiB1cGRhdGVk
LgoKDgoHBAAEAAIBARIDJAQeCg4KBwQABAACAQISAyQhIgonCgQEAAIAEgMoAj4aGiBSZXF1
aXJlZC4gVHlwZSBvZiBldmVudC4KCgwKBQQAAgAGEgMoAgsKDAoFBAACAAESAygMEAoMCgUE
AAIAAxIDKBMUCgwKBQQAAgAIEgMoFT0KDwoIBAACAAicCAASAygWPAo7CgQEAAIBEgMrAksa
LiBPcHRpb25hbC4gQWRkaXRpb25hbCBtZXRhZGF0YSBmb3IgdGhlIGV2ZW50LgoKDAoFBAAC
AQYSAysCFQoMCgUEAAIBARIDKxYdCgwKBQQAAgEDEgMrICEKDAoFBAACAQgSAysiSgoPCggE
AAIBCJwIABIDKyNJYgZwcm90bzM=
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Notebooks::Logging::V1::RuntimeLog::RuntimeEvent ===
    # Fields for RuntimeEvent
    # Field: type Type: 14 (.google.cloud.notebooks.logging.v1.RuntimeEvent.EventType)
    # Field: details Type: 11 (.google.cloud.notebooks.logging.v1.RuntimeEvent.DetailsEntry)

# Enum: RuntimeEvent::EventType
our $RuntimeEvent_EVENT_TYPE_UNSPECIFIED = 0;
our $RuntimeEvent_RUNTIME_STATE_CHANGE_EVENT = 1;

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Notebooks::Logging::V1::RuntimeLog - Compiled Protocol Buffers messages for google/cloud/notebooks/logging/v1/runtime_log.proto

=head1 SYNOPSIS

    use Google::Cloud::Notebooks::Logging::V1::RuntimeLog;

    my $msg = Google::Cloud::Notebooks::Logging::V1::RuntimeLog::RuntimeEvent->new({
        type => $type,
        details => $details,
    });

    # Read or update a field
    my $val = $msg->type();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Notebooks::Logging::V1::RuntimeLog::RuntimeEvent->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/notebooks/logging/v1/runtime_log.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Notebooks::Logging::V1::RuntimeLog::RuntimeEvent

Log content of an event related to a runtime.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->type() >> / C<< $msg->type($value) >>

Type: C<Enum> (L<Google::Cloud::Notebooks::Logging::V1::RuntimeEvent::EventType>)

Required. Type of event.

=item * C<< $msg->details() >> / C<< $msg->details($value) >>

Type: C<Message> (L<Google::Cloud::Notebooks::Logging::V1::RuntimeLog::RuntimeEvent::DetailsEntry>)

Optional. Additional metadata for the event.

=back

=head3 Enum: RuntimeEvent::EventType

=over 4

=item * C<EVENT_TYPE_UNSPECIFIED> => C<0>

=item * C<RUNTIME_STATE_CHANGE_EVENT> => C<1>

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Notebooks::Logging::V1::RuntimeLog::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
