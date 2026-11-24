package Google::Cloud::Kms::Logging::V1::Logs;

use strict;
use warnings;

our $VERSION = '0.14';

use Protobuf::Message;
use Protobuf::DescriptorPool;
use Protobuf::Internal qw(:all);
use MIME::Base64;

BEGIN {
    eval { require Google::Rpc::Status };
    my $descriptor_b64 = <<'EOF';
CiZnb29nbGUvY2xvdWQva21zL2xvZ2dpbmcvdjEvbG9ncy5wcm90bxIbZ29vZ2xlLmNsb3Vk
Lmttcy5sb2dnaW5nLnYxGhdnb29nbGUvcnBjL3N0YXR1cy5wcm90byKvAQoOQ3J5cHRvS2V5
RXZlbnQSYAoOcm90YXRpb25fZXZlbnQYASABKAsyOS5nb29nbGUuY2xvdWQua21zLmxvZ2dp
bmcudjEuQ3J5cHRvS2V5RXZlbnQuUm90YXRpb25FdmVudFINcm90YXRpb25FdmVudBo7Cg1S
b3RhdGlvbkV2ZW50EioKBnN0YXR1cxgBIAEoCzISLmdvb2dsZS5ycGMuU3RhdHVzUgZzdGF0
dXMi5wUKFUNyeXB0b0tleVZlcnNpb25FdmVudBKOAQobc2NoZWR1bGVkX2Rlc3RydWN0aW9u
X2V2ZW50GAEgASgLMkwuZ29vZ2xlLmNsb3VkLmttcy5sb2dnaW5nLnYxLkNyeXB0b0tleVZl
cnNpb25FdmVudC5TY2hlZHVsZWREZXN0cnVjdGlvbkV2ZW50SABSGXNjaGVkdWxlZERlc3Ry
dWN0aW9uRXZlbnQSeQoUa2V5X2dlbmVyYXRpb25fZXZlbnQYAiABKAsyRS5nb29nbGUuY2xv
dWQua21zLmxvZ2dpbmcudjEuQ3J5cHRvS2V5VmVyc2lvbkV2ZW50LktleUdlbmVyYXRpb25F
dmVudEgAUhJrZXlHZW5lcmF0aW9uRXZlbnQSYwoMaW1wb3J0X2V2ZW50GAMgASgLMj4uZ29v
Z2xlLmNsb3VkLmttcy5sb2dnaW5nLnYxLkNyeXB0b0tleVZlcnNpb25FdmVudC5JbXBvcnRF
dmVudEgAUgtpbXBvcnRFdmVudBqOAQoZU2NoZWR1bGVkRGVzdHJ1Y3Rpb25FdmVudBIqCgZz
dGF0dXMYASABKAsyEi5nb29nbGUucnBjLlN0YXR1c1IGc3RhdHVzEkUKH2tleV9hY2Nlc3Nf
anVzdGlmaWNhdGlvbl9yZWFzb24YAiABKAlSHGtleUFjY2Vzc0p1c3RpZmljYXRpb25SZWFz
b24ahwEKEktleUdlbmVyYXRpb25FdmVudBIqCgZzdGF0dXMYASABKAsyEi5nb29nbGUucnBj
LlN0YXR1c1IGc3RhdHVzEkUKH2tleV9hY2Nlc3NfanVzdGlmaWNhdGlvbl9yZWFzb24YAiAB
KAlSHGtleUFjY2Vzc0p1c3RpZmljYXRpb25SZWFzb24aOQoLSW1wb3J0RXZlbnQSKgoGc3Rh
dHVzGAEgASgLMhIuZ29vZ2xlLnJwYy5TdGF0dXNSBnN0YXR1c0IHCgVldmVudEJpCh9jb20u
Z29vZ2xlLmNsb3VkLmttcy5sb2dnaW5nLnYxQglMb2dzUHJvdG9QAVo5Y2xvdWQuZ29vZ2xl
LmNvbS9nby9rbXMvbG9nZ2luZy9hcGl2MS9sb2dnaW5ncGI7bG9nZ2luZ3BiSrcbCgYSBA4A
WgEKvAQKAQwSAw4AEjKxBCBDb3B5cmlnaHQgMjAyNSBHb29nbGUgTExDCgogTGljZW5zZWQg
dW5kZXIgdGhlIEFwYWNoZSBMaWNlbnNlLCBWZXJzaW9uIDIuMCAodGhlICJMaWNlbnNlIik7
CiB5b3UgbWF5IG5vdCB1c2UgdGhpcyBmaWxlIGV4Y2VwdCBpbiBjb21wbGlhbmNlIHdpdGgg
dGhlIExpY2Vuc2UuCiBZb3UgbWF5IG9idGFpbiBhIGNvcHkgb2YgdGhlIExpY2Vuc2UgYXQK
CiAgICAgaHR0cDovL3d3dy5hcGFjaGUub3JnL2xpY2Vuc2VzL0xJQ0VOU0UtMi4wCgogVW5s
ZXNzIHJlcXVpcmVkIGJ5IGFwcGxpY2FibGUgbGF3IG9yIGFncmVlZCB0byBpbiB3cml0aW5n
LCBzb2Z0d2FyZQogZGlzdHJpYnV0ZWQgdW5kZXIgdGhlIExpY2Vuc2UgaXMgZGlzdHJpYnV0
ZWQgb24gYW4gIkFTIElTIiBCQVNJUywKIFdJVEhPVVQgV0FSUkFOVElFUyBPUiBDT05ESVRJ
T05TIE9GIEFOWSBLSU5ELCBlaXRoZXIgZXhwcmVzcyBvciBpbXBsaWVkLgogU2VlIHRoZSBM
aWNlbnNlIGZvciB0aGUgc3BlY2lmaWMgbGFuZ3VhZ2UgZ292ZXJuaW5nIHBlcm1pc3Npb25z
IGFuZAogbGltaXRhdGlvbnMgdW5kZXIgdGhlIExpY2Vuc2UuCgoICgECEgMQACQKCQoCAwAS
AxIAIQoICgEIEgMUAFAKCQoCCAsSAxQAUAoICgEIEgMVACIKCQoCCAoSAxUAIgoICgEIEgMW
ACoKCQoCCAgSAxYAKgoICgEIEgMXADgKCQoCCAESAxcAOAqiAQoCBAASBB0AKAEaUiBMb2cg
bWVzc2FnZSB1c2VkIHRvIHNlbmQgdG8gUGxhdGZvcm0gTG9nZ2luZyBmb3IgYXN5bmNocm9u
b3VzCiBDcnlwdG9LZXkgZXZlbnRzLgoyQiBUaGlzIGZpbGUgZGVmaW5lcyB0aGUgZm9ybWF0
IG9mIENsb3VkIEtNUyBQbGF0Zm9ybSBMb2dnaW5nIExvZ3MuCgoKCgMEAAESAx0IFgqiAQoE
BAADABIEIAIkAxqTASBUaGUgZXZlbnQgZW1pdHRlZCBieSBLTVMgd2hlbiBwZXJmb3JtaW5n
IGEgc2NoZWR1bGVkIGF1dG9tYXRpYyBDcnlwdG9LZXkKIHJvdGF0aW9uLiBTZWUgaHR0cHM6
Ly9jbG91ZC5nb29nbGUuY29tL2ttcy9kb2NzL3JvdGF0aW5nLWtleXMjYXV0b21hdGljCgoM
CgUEAAMAARIDIAoXCosBCgYEAAMAAgASAyMEIRp8IFRoZSByZXN1bHQgb2YgdGhlIHNjaGVk
dWxlZCBrZXkgcm90YXRpb24uIFRoZSAnZGV0YWlscycgZmllbGQgb2YgdGhlCiBzdGF0dXMg
bWF5IGNvbnRhaW4gYSBnb29nbGUucnBjLlByZWNvbmRpdGlvbkZhaWx1cmUuCgoOCgcEAAMA
AgAGEgMjBBUKDgoHBAADAAIAARIDIxYcCg4KBwQAAwACAAMSAyMfIApRCgQEAAIAEgMnAiMa
RCBBbiBldmVudCBmb3Igcm90YXRpbmcgdGhlIHByaW1hcnkgQ3J5cHRvS2V5VmVyc2lvbiBv
ZiBhIENyeXB0b0tleS4KCgwKBQQAAgAGEgMnAg8KDAoFBAACAAESAycQHgoMCgUEAAIAAxID
JyEiCmUKAgQBEgQsAFoBGlkgTG9nIG1lc3NhZ2UgdXNlZCB0byBzZW5kIHRvIFBsYXRmb3Jt
IExvZ2dpbmcgZm9yIGFzeW5jaHJvbm91cwogQ3J5cHRvS2V5VmVyc2lvbiBldmVudHMuCgoK
CgMEAQESAywIHQqmAQoEBAEDABIELwI5AxqXASBUaGUgZXZlbnQgZW1pdHRlZCBieSBLTVMg
d2hlbiBkZXN0cm95aW5nIGEgQ3J5cHRvS2V5VmVyc2lvbiBzY2hlZHVsZWQgZm9yCiBkZXN0
cnVjdGlvbi4gU2VlIGh0dHBzOi8vY2xvdWQuZ29vZ2xlLmNvbS9rbXMvZG9jcy9kZXN0cm95
LXJlc3RvcmUjZGVzdHJveQoKDAoFBAEDAAESAy8KIwr1AQoGBAEDAAIAEgM0BCEa5QEgVGhl
IHJlc3VsdCBvZiB0aGUgc2NoZWR1bGVkIGtleSB2ZXJzaW9uIGRlc3RydWN0aW9uLiBUaGUg
J2RldGFpbHMnIGZpZWxkCiBvZiB0aGUgc3RhdHVzIG1heSBjb250YWluIGEgZ29vZ2xlLnJw
Yy5QcmVjb25kaXRpb25GYWlsdXJlLiBGb3IgRUtNIGtleXMsCiB0aGUgJ3Zpb2xhdGlvbnMn
IGZpZWxkIG9mIGEgUHJlY29uZGl0aW9uRmFpbHVyZSB3aWxsIGFsc28gaW5jbHVkZSBFS00K
IGVycm9ycy4KCg4KBwQBAwACAAYSAzQEFQoOCgcEAQMAAgABEgM0FhwKDgoHBAEDAAIAAxID
NB8gCp8BCgYEAQMAAgESAzgELxqPASBUaGUgS2V5IEFjY2VzcyBKdXN0aWZpY2F0aW9uIChL
QUopIHJlYXNvbiBhc3NvY2lhdGVkIHdpdGggdGhlIHJlcXVlc3QuCiBUaGlzIGZpZWxkIGlz
IG9ubHkgcG9wdWxhdGVkIGZvciBLQUogZW5yb2xsZWQgY3VzdG9tZXJzIGZvciBFS00ga2V5
cy4KCg4KBwQBAwACAQUSAzgECgoOCgcEAQMAAgEBEgM4CyoKDgoHBAEDAAIBAxIDOC0uCn4K
BAQBAwESBD0CRgMacCBUaGUgZXZlbnQgZW1pdHRlZCBieSBLTVMgd2hlbiBnZW5lcmF0aW5n
IGEgQ3J5cHRvS2V5VmVyc2lvbi4gU2VlCiBodHRwczovL2Nsb3VkLmdvb2dsZS5jb20va21z
L2RvY3Mva2V5LXN0YXRlcwoKDAoFBAEDAQESAz0KHArpAQoGBAEDAQIAEgNBBCEa2QEgVGhl
IHJlc3VsdCBvZiB0aGUga2V5IHZlcnNpb24gZ2VuZXJhdGlvbi4gVGhlICdkZXRhaWxzJyBm
aWVsZCBvZiB0aGUKIHN0YXR1cyBtYXkgY29udGFpbiBhIGdvb2dsZS5ycGMuUHJlY29uZGl0
aW9uRmFpbHVyZS4gRm9yIEVLTSBrZXlzLCB0aGUKICd2aW9sYXRpb25zJyBmaWVsZCBvZiBh
IFByZWNvbmRpdGlvbkZhaWx1cmUgd2lsbCBhbHNvIGluY2x1ZGUgRUtNIGVycm9ycy4KCg4K
BwQBAwECAAYSA0EEFQoOCgcEAQMBAgABEgNBFhwKDgoHBAEDAQIAAxIDQR8gCp8BCgYEAQMB
AgESA0UELxqPASBUaGUgS2V5IEFjY2VzcyBKdXN0aWZpY2F0aW9uIChLQUopIHJlYXNvbiBh
c3NvY2lhdGVkIHdpdGggdGhlIHJlcXVlc3QuCiBUaGlzIGZpZWxkIGlzIG9ubHkgcG9wdWxh
dGVkIGZvciBLQUogZW5yb2xsZWQgY3VzdG9tZXJzIGZvciBFS00ga2V5cy4KCg4KBwQBAwEC
AQUSA0UECgoOCgcEAQMBAgEBEgNFCyoKDgoHBAEDAQIBAxIDRS0uCoIBCgQEAQMCEgRKAk4D
GnQgVGhlIGV2ZW50IGVtaXR0ZWQgYnkgS01TIHdoZW4gaW1wb3J0aW5nIGEgQ3J5cHRvS2V5
VmVyc2lvbi4gU2VlCiBodHRwczovL2Nsb3VkLmdvb2dsZS5jb20va21zL2RvY3MvaW1wb3J0
aW5nLWEta2V5CgoMCgUEAQMCARIDSgoVCocBCgYEAQMCAgASA00EIRp4IFRoZSByZXN1bHQg
b2YgdGhlIGtleSB2ZXJzaW9uIGltcG9ydC4gVGhlICdkZXRhaWxzJyBmaWVsZCBvZiB0aGUg
c3RhdHVzCiBtYXkgY29udGFpbiBhIGdvb2dsZS5ycGMuUHJlY29uZGl0aW9uRmFpbHVyZS4K
Cg4KBwQBAwICAAYSA00EFQoOCgcEAQMCAgABEgNNFhwKDgoHBAEDAgIAAxIDTR8gCgwKBAQB
CAASBFACWQMKDAoFBAEIAAESA1AIDQpMCgQEAQIAEgNSBD4aPyBBbiBldmVudCBmb3IgdGhl
IHNjaGVkdWxlZCBkZXN0cnVjdGlvbiBvZiBhIENyeXB0b0tleVZlcnNpb24uCgoMCgUEAQIA
BhIDUgQdCgwKBQQBAgABEgNSHjkKDAoFBAECAAMSA1I8PQpBCgQEAQIBEgNVBDAaNCBBbiBl
dmVudCBmb3IgdGhlIGdlbmVyYXRpb24gb2YgYSBDcnlwdG9LZXlWZXJzaW9uLgoKDAoFBAEC
AQYSA1UEFgoMCgUEAQIBARIDVRcrCgwKBQQBAgEDEgNVLi8KTgoEBAECAhIDWAQhGkEgQW4g
ZXZlbnQgZm9yIHRoZSBpbXBvcnQgb2Yga2V5IG1hdGVyaWFsIGZvciBhIENyeXB0b0tleVZl
cnNpb24uCgoMCgUEAQICBhIDWAQPCgwKBQQBAgIBEgNYEBwKDAoFBAECAgMSA1gfIGIGcHJv
dG8z
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Kms::Logging::V1::Logs::CryptoKeyEvent ===
    # Fields for CryptoKeyEvent
    # Field: rotation_event Type: 11 (.google.cloud.kms.logging.v1.CryptoKeyEvent.RotationEvent)

# === Message: Google::Cloud::Kms::Logging::V1::Logs::CryptoKeyVersionEvent ===
    # Fields for CryptoKeyVersionEvent
    # Field: scheduled_destruction_event Type: 11 (.google.cloud.kms.logging.v1.CryptoKeyVersionEvent.ScheduledDestructionEvent)
    # Field: key_generation_event Type: 11 (.google.cloud.kms.logging.v1.CryptoKeyVersionEvent.KeyGenerationEvent)
    # Field: import_event Type: 11 (.google.cloud.kms.logging.v1.CryptoKeyVersionEvent.ImportEvent)

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Kms::Logging::V1::Logs - Compiled Protocol Buffers messages for google/cloud/kms/logging/v1/logs.proto

=head1 SYNOPSIS

    use Google::Cloud::Kms::Logging::V1::Logs;

    my $msg = Google::Cloud::Kms::Logging::V1::Logs::CryptoKeyEvent->new({
        rotation_event => $rotation_event,
    });

    # Read or update a field
    my $val = $msg->rotation_event();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Kms::Logging::V1::Logs::CryptoKeyEvent->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/kms/logging/v1/logs.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Kms::Logging::V1::Logs::CryptoKeyEvent

Log message used to send to Platform Logging for asynchronous
CryptoKey events.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->rotation_event() >> / C<< $msg->rotation_event($value) >>

Type: C<Message> (L<Google::Cloud::Kms::Logging::V1::Logs::CryptoKeyEvent::RotationEvent>)

An event for rotating the primary CryptoKeyVersion of a CryptoKey.

=back

=head2 Google::Cloud::Kms::Logging::V1::Logs::CryptoKeyVersionEvent

Log message used to send to Platform Logging for asynchronous
CryptoKeyVersion events.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->scheduled_destruction_event() >> / C<< $msg->scheduled_destruction_event($value) >>

Type: C<Message> (L<Google::Cloud::Kms::Logging::V1::Logs::CryptoKeyVersionEvent::ScheduledDestructionEvent>)

An event for the scheduled destruction of a CryptoKeyVersion.

=item * C<< $msg->key_generation_event() >> / C<< $msg->key_generation_event($value) >>

Type: C<Message> (L<Google::Cloud::Kms::Logging::V1::Logs::CryptoKeyVersionEvent::KeyGenerationEvent>)

An event for the generation of a CryptoKeyVersion.

=item * C<< $msg->import_event() >> / C<< $msg->import_event($value) >>

Type: C<Message> (L<Google::Cloud::Kms::Logging::V1::Logs::CryptoKeyVersionEvent::ImportEvent>)

An event for the import of key material for a CryptoKeyVersion.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Kms::Logging::V1::Logs::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
