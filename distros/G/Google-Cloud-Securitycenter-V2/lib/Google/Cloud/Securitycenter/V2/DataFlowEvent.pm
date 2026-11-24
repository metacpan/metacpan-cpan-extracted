package Google::Cloud::Securitycenter::V2::DataFlowEvent;

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
CjRnb29nbGUvY2xvdWQvc2VjdXJpdHljZW50ZXIvdjIvZGF0YV9mbG93X2V2ZW50LnByb3Rv
Eh5nb29nbGUuY2xvdWQuc2VjdXJpdHljZW50ZXIudjIaH2dvb2dsZS9wcm90b2J1Zi90aW1l
c3RhbXAucHJvdG8i2AIKDURhdGFGbG93RXZlbnQSGQoIZXZlbnRfaWQYASABKAlSB2V2ZW50
SWQSJwoPcHJpbmNpcGFsX2VtYWlsGAIgASgJUg5wcmluY2lwYWxFbWFpbBJVCglvcGVyYXRp
b24YAyABKA4yNy5nb29nbGUuY2xvdWQuc2VjdXJpdHljZW50ZXIudjIuRGF0YUZsb3dFdmVu
dC5PcGVyYXRpb25SCW9wZXJhdGlvbhIrChF2aW9sYXRlZF9sb2NhdGlvbhgEIAEoCVIQdmlv
bGF0ZWRMb2NhdGlvbhI5CgpldmVudF90aW1lGAUgASgLMhouZ29vZ2xlLnByb3RvYnVmLlRp
bWVzdGFtcFIJZXZlbnRUaW1lIkQKCU9wZXJhdGlvbhIZChVPUEVSQVRJT05fVU5TUEVDSUZJ
RUQQABIICgRSRUFEEAESCAoETU9WRRACEggKBENPUFkQA0LsAQoiY29tLmdvb2dsZS5jbG91
ZC5zZWN1cml0eWNlbnRlci52MkISRGF0YUZsb3dFdmVudFByb3RvUAFaSmNsb3VkLmdvb2ds
ZS5jb20vZ28vc2VjdXJpdHljZW50ZXIvYXBpdjIvc2VjdXJpdHljZW50ZXJwYjtzZWN1cml0
eWNlbnRlcnBiqgIeR29vZ2xlLkNsb3VkLlNlY3VyaXR5Q2VudGVyLlYyygIeR29vZ2xlXENs
b3VkXFNlY3VyaXR5Q2VudGVyXFYy6gIhR29vZ2xlOjpDbG91ZDo6U2VjdXJpdHlDZW50ZXI6
OlYySr0PCgYSBA4APgEKvAQKAQwSAw4AEjKxBCBDb3B5cmlnaHQgMjAyNSBHb29nbGUgTExD
CgogTGljZW5zZWQgdW5kZXIgdGhlIEFwYWNoZSBMaWNlbnNlLCBWZXJzaW9uIDIuMCAodGhl
ICJMaWNlbnNlIik7CiB5b3UgbWF5IG5vdCB1c2UgdGhpcyBmaWxlIGV4Y2VwdCBpbiBjb21w
bGlhbmNlIHdpdGggdGhlIExpY2Vuc2UuCiBZb3UgbWF5IG9idGFpbiBhIGNvcHkgb2YgdGhl
IExpY2Vuc2UgYXQKCiAgICAgaHR0cDovL3d3dy5hcGFjaGUub3JnL2xpY2Vuc2VzL0xJQ0VO
U0UtMi4wCgogVW5sZXNzIHJlcXVpcmVkIGJ5IGFwcGxpY2FibGUgbGF3IG9yIGFncmVlZCB0
byBpbiB3cml0aW5nLCBzb2Z0d2FyZQogZGlzdHJpYnV0ZWQgdW5kZXIgdGhlIExpY2Vuc2Ug
aXMgZGlzdHJpYnV0ZWQgb24gYW4gIkFTIElTIiBCQVNJUywKIFdJVEhPVVQgV0FSUkFOVElF
UyBPUiBDT05ESVRJT05TIE9GIEFOWSBLSU5ELCBlaXRoZXIgZXhwcmVzcyBvciBpbXBsaWVk
LgogU2VlIHRoZSBMaWNlbnNlIGZvciB0aGUgc3BlY2lmaWMgbGFuZ3VhZ2UgZ292ZXJuaW5n
IHBlcm1pc3Npb25zIGFuZAogbGltaXRhdGlvbnMgdW5kZXIgdGhlIExpY2Vuc2UuCgoICgEC
EgMQACcKCQoCAwASAxIAKQoICgEIEgMUADsKCQoCCCUSAxQAOwoICgEIEgMVAGEKCQoCCAsS
AxUAYQoICgEIEgMWACIKCQoCCAoSAxYAIgoICgEIEgMXADMKCQoCCAgSAxcAMwoICgEIEgMY
ADsKCQoCCAESAxgAOwoICgEIEgMZADsKCQoCCCkSAxkAOwoICgEIEgMaADoKCQoCCC0SAxoA
Ogq7AQoCBAASBB8APgEargEgRGV0YWlscyBhYm91dCBhIGRhdGEgZmxvdyBldmVudCwgaW4g
d2hpY2ggZWl0aGVyIHRoZSBkYXRhIGlzIG1vdmVkIHRvIG9yIGlzCiBhY2Nlc3NlZCBmcm9t
IGEgbm9uLWNvbXBsaWFudCBnZW8tbG9jYXRpb24sIGFzIGRlZmluZWQgaW4gdGhlIGFwcGxp
Y2FibGUgZGF0YQogc2VjdXJpdHkgcG9saWN5LgoKCgoDBAABEgMfCBUKMwoEBAAEABIEIQIt
AxolIFRoZSBvcGVyYXRpb24gb2YgYSBkYXRhIGZsb3cgZXZlbnQuCgoMCgUEAAQAARIDIQcQ
Ci4KBgQABAACABIDIwQeGh8gVGhlIG9wZXJhdGlvbiBpcyB1bnNwZWNpZmllZC4KCg4KBwQA
BAACAAESAyMEGQoOCgcEAAQAAgACEgMjHB0KLQoGBAAEAAIBEgMmBA0aHiBSZXByZXNlbnRz
IGEgcmVhZCBvcGVyYXRpb24uCgoOCgcEAAQAAgEBEgMmBAgKDgoHBAAEAAIBAhIDJgsMCi0K
BgQABAACAhIDKQQNGh4gUmVwcmVzZW50cyBhIG1vdmUgb3BlcmF0aW9uLgoKDgoHBAAEAAIC
ARIDKQQICg4KBwQABAACAgISAykLDAotCgYEAAQAAgMSAywEDRoeIFJlcHJlc2VudHMgYSBj
b3B5IG9wZXJhdGlvbi4KCg4KBwQABAACAwESAywECAoOCgcEAAQAAgMCEgMsCwwKNQoEBAAC
ABIDMAIWGiggVW5pcXVlIGlkZW50aWZpZXIgZm9yIGRhdGEgZmxvdyBldmVudC4KCgwKBQQA
AgAFEgMwAggKDAoFBAACAAESAzAJEQoMCgUEAAIAAxIDMBQVCqcBCgQEAAIBEgM0Ah0amQEg
VGhlIGVtYWlsIGFkZHJlc3Mgb2YgdGhlIHByaW5jaXBhbCB0aGF0IGluaXRpYXRlZCB0aGUg
ZGF0YSBmbG93IGV2ZW50LiBUaGUKIHByaW5jaXBhbCBjb3VsZCBiZSBhIHVzZXIgYWNjb3Vu
dCwgc2VydmljZSBhY2NvdW50LCBHb29nbGUgZ3JvdXAsIG9yIG90aGVyLgoKDAoFBAACAQUS
AzQCCAoMCgUEAAIBARIDNAkYCgwKBQQAAgEDEgM0GxwKUAoEBAACAhIDNwIaGkMgVGhlIG9w
ZXJhdGlvbiBwZXJmb3JtZWQgYnkgdGhlIHByaW5jaXBhbCBmb3IgdGhlIGRhdGEgZmxvdyBl
dmVudC4KCgwKBQQAAgIGEgM3AgsKDAoFBAACAgESAzcMFQoMCgUEAAICAxIDNxgZCk8KBAQA
AgMSAzoCHxpCIE5vbi1jb21wbGlhbnQgbG9jYXRpb24gb2YgdGhlIHByaW5jaXBhbCBvciB0
aGUgZGF0YSBkZXN0aW5hdGlvbi4KCgwKBQQAAgMFEgM6AggKDAoFBAACAwESAzoJGgoMCgUE
AAIDAxIDOh0eCiwKBAQAAgQSAz0CKxofIFRpbWVzdGFtcCBvZiBkYXRhIGZsb3cgZXZlbnQu
CgoMCgUEAAIEBhIDPQIbCgwKBQQAAgQBEgM9HCYKDAoFBAACBAMSAz0pKmIGcHJvdG8z
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Securitycenter::V2::DataFlowEvent::DataFlowEvent ===
    # Fields for DataFlowEvent
    # Field: event_id Type: 9 ()
    # Field: principal_email Type: 9 ()
    # Field: operation Type: 14 (.google.cloud.securitycenter.v2.DataFlowEvent.Operation)
    # Field: violated_location Type: 9 ()
    # Field: event_time Type: 11 (.google.protobuf.Timestamp)

# Enum: DataFlowEvent::Operation
our $DataFlowEvent_OPERATION_UNSPECIFIED = 0;
our $DataFlowEvent_READ = 1;
our $DataFlowEvent_MOVE = 2;
our $DataFlowEvent_COPY = 3;

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Securitycenter::V2::DataFlowEvent - Compiled Protocol Buffers messages for google/cloud/securitycenter/v2/data_flow_event.proto

=head1 SYNOPSIS

    use Google::Cloud::Securitycenter::V2::DataFlowEvent;

    my $msg = Google::Cloud::Securitycenter::V2::DataFlowEvent::DataFlowEvent->new({
        event_id => $event_id,
        principal_email => $principal_email,
        operation => $operation,
        violated_location => $violated_location,
    });

    # Read or update a field
    my $val = $msg->event_id();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Securitycenter::V2::DataFlowEvent::DataFlowEvent->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/securitycenter/v2/data_flow_event.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Securitycenter::V2::DataFlowEvent::DataFlowEvent

Details about a data flow event, in which either the data is moved to or is
accessed from a non-compliant geo-location, as defined in the applicable data
security policy.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->event_id() >> / C<< $msg->event_id($value) >>

Type: C<String>

Unique identifier for data flow event.

=item * C<< $msg->principal_email() >> / C<< $msg->principal_email($value) >>

Type: C<String>

The email address of the principal that initiated the data flow event. The
principal could be a user account, service account, Google group, or other.

=item * C<< $msg->operation() >> / C<< $msg->operation($value) >>

Type: C<Enum> (L<Google::Cloud::Securitycenter::V2::DataFlowEvent::Operation>)

The operation performed by the principal for the data flow event.

=item * C<< $msg->violated_location() >> / C<< $msg->violated_location($value) >>

Type: C<String>

Non-compliant location of the principal or the data destination.

=item * C<< $msg->event_time() >> / C<< $msg->event_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Timestamp of data flow event.

=back

=head3 Enum: DataFlowEvent::Operation

=over 4

=item * C<OPERATION_UNSPECIFIED> => C<0>

=item * C<READ> => C<1>

=item * C<MOVE> => C<2>

=item * C<COPY> => C<3>

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Securitycenter::V2::DataFlowEvent::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
