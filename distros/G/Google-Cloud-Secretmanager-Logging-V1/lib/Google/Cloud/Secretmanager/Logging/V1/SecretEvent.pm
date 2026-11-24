package Google::Cloud::Secretmanager::Logging::V1::SecretEvent;

use strict;
use warnings;

our $VERSION = '0.14';

use Protobuf::Message;
use Protobuf::DescriptorPool;
use Protobuf::Internal qw(:all);
use MIME::Base64;

BEGIN {
    my $descriptor_b64 = <<'EOF';
Cjhnb29nbGUvY2xvdWQvc2VjcmV0bWFuYWdlci9sb2dnaW5nL3YxL3NlY3JldF9ldmVudC5w
cm90bxIlZ29vZ2xlLmNsb3VkLnNlY3JldG1hbmFnZXIubG9nZ2luZy52MSLxAgoLU2VjcmV0
RXZlbnQSEgoEbmFtZRgBIAEoCVIEbmFtZRJQCgR0eXBlGAIgASgOMjwuZ29vZ2xlLmNsb3Vk
LnNlY3JldG1hbmFnZXIubG9nZ2luZy52MS5TZWNyZXRFdmVudC5FdmVudFR5cGVSBHR5cGUS
HwoLbG9nX21lc3NhZ2UYAyABKAlSCmxvZ01lc3NhZ2Ui2gEKCUV2ZW50VHlwZRIaChZFVkVO
VF9UWVBFX1VOU1BFQ0lGSUVEEAASFgoSRVhQSVJFU19JTl8zMF9EQVlTEAESFQoRRVhQSVJF
U19JTl83X0RBWVMQAhIUChBFWFBJUkVTX0lOXzFfREFZEAMSFgoSRVhQSVJFU19JTl82X0hP
VVJTEAQSFQoRRVhQSVJFU19JTl8xX0hPVVIQBRILCgdFWFBJUkVEEAYSEwoPVE9QSUNfTk9U
X0ZPVU5EEAcSGwoXVE9QSUNfUEVSTUlTU0lPTl9ERU5JRUQQCEKAAgopY29tLmdvb2dsZS5j
bG91ZC5zZWNyZXRtYW5hZ2VyLmxvZ2dpbmcudjFCEFNlY3JldEV2ZW50UHJvdG9QAVpDY2xv
dWQuZ29vZ2xlLmNvbS9nby9zZWNyZXRtYW5hZ2VyL2xvZ2dpbmcvYXBpdjEvbG9nZ2luZ3Bi
O2xvZ2dpbmdwYqoCJUdvb2dsZS5DbG91ZC5TZWNyZXRNYW5hZ2VyLkxvZ2dpbmcuVjHKAiVH
b29nbGVcQ2xvdWRcU2VjcmV0TWFuYWdlclxMb2dnaW5nXFYx6gIpR29vZ2xlOjpDbG91ZDo6
U2VjcmV0TWFuYWdlcjo6TG9nZ2luZzo6VjFKgxIKBhIEDgBGAQq8BAoBDBIDDgASMrEEIENv
cHlyaWdodCAyMDI1IEdvb2dsZSBMTEMKCiBMaWNlbnNlZCB1bmRlciB0aGUgQXBhY2hlIExp
Y2Vuc2UsIFZlcnNpb24gMi4wICh0aGUgIkxpY2Vuc2UiKTsKIHlvdSBtYXkgbm90IHVzZSB0
aGlzIGZpbGUgZXhjZXB0IGluIGNvbXBsaWFuY2Ugd2l0aCB0aGUgTGljZW5zZS4KIFlvdSBt
YXkgb2J0YWluIGEgY29weSBvZiB0aGUgTGljZW5zZSBhdAoKICAgICBodHRwOi8vd3d3LmFw
YWNoZS5vcmcvbGljZW5zZXMvTElDRU5TRS0yLjAKCiBVbmxlc3MgcmVxdWlyZWQgYnkgYXBw
bGljYWJsZSBsYXcgb3IgYWdyZWVkIHRvIGluIHdyaXRpbmcsIHNvZnR3YXJlCiBkaXN0cmli
dXRlZCB1bmRlciB0aGUgTGljZW5zZSBpcyBkaXN0cmlidXRlZCBvbiBhbiAiQVMgSVMiIEJB
U0lTLAogV0lUSE9VVCBXQVJSQU5USUVTIE9SIENPTkRJVElPTlMgT0YgQU5ZIEtJTkQsIGVp
dGhlciBleHByZXNzIG9yIGltcGxpZWQuCiBTZWUgdGhlIExpY2Vuc2UgZm9yIHRoZSBzcGVj
aWZpYyBsYW5ndWFnZSBnb3Zlcm5pbmcgcGVybWlzc2lvbnMgYW5kCiBsaW1pdGF0aW9ucyB1
bmRlciB0aGUgTGljZW5zZS4KCggKAQISAxAALgoICgEIEgMSAFoKCQoCCAsSAxIAWgoICgEI
EgMTACIKCQoCCAoSAxMAIgoICgEIEgMUADEKCQoCCAgSAxQAMQoICgEIEgMVAEIKCQoCCAES
AxUAQgoICgEIEgMWAEIKCQoCCCUSAxYAQgoICgEIEgMXAEMKCQoCCCkSAxcAQwoICgEIEgMY
AEIKCQoCCC0SAxgAQgo4CgIEABIEGwBGARosIExvZ2dlZCBldmVudCByZWxhdGluZyB0byBh
IHNwZWNpZmljIHNlY3JldAoKCgoDBAABEgMbCBMKZwoEBAAEABIEHgI8AxpZIERlc2NyaWJl
cyB0aGUgdHlwZSBvZiBldmVudCB0aGF0IGlzIGJlaW5nIGxvZ2dlZC4gQWxsIGxvZ3MgaGF2
ZSBleGFjdGx5IG9uZQogRXZlbnRUeXBlLgoKDAoFBAAEAAESAx4HEApCCgYEAAQAAgASAyAE
HxozIEFuIHVucmVjb2duaXplZCBldmVudCB0eXBlLiBTaG91bGQgbmV2ZXIgYmUgdXNlZC4K
Cg4KBwQABAACAAESAyAEGgoOCgcEAAQAAgACEgMgHR4KPgoGBAAEAAIBEgMjBBsaLyBUaGUg
c2VjcmV0IGlzIHNjaGVkdWxlZCB0byBleHBpcmUgaW4gMzAgZGF5cy4KCg4KBwQABAACAQES
AyMEFgoOCgcEAAQAAgECEgMjGRoKPQoGBAAEAAICEgMmBBoaLiBUaGUgc2VjcmV0IGlzIHNj
aGVkdWxlZCB0byBleHBpcmUgaW4gNyBkYXlzLgoKDgoHBAAEAAICARIDJgQVCg4KBwQABAAC
AgISAyYYGQo8CgYEAAQAAgMSAykEGRotIFRoZSBzZWNyZXQgaXMgc2NoZWR1bGVkIHRvIGV4
cGlyZSBpbiAxIGRheS4KCg4KBwQABAACAwESAykEFAoOCgcEAAQAAgMCEgMpFxgKPgoGBAAE
AAIEEgMsBBsaLyBUaGUgc2VjcmV0IGlzIHNjaGVkdWxlZCB0byBleHBpcmUgaW4gNiBob3Vy
cy4KCg4KBwQABAACBAESAywEFgoOCgcEAAQAAgQCEgMsGRoKPQoGBAAEAAIFEgMvBBoaLiBU
aGUgc2VjcmV0IGlzIHNjaGVkdWxlZCB0byBleHBpcmUgaW4gMSBob3VyLgoKDgoHBAAEAAIF
ARIDLwQVCg4KBwQABAACBQISAy8YGQpICgYEAAQAAgYSAzIEEBo5IFRoZSBzZWNyZXQncyBl
eHBpcmUtdGltZSBoYXMgcGFzc2VkIGFuZCBpdCBoYXMgZXhwaXJlZC4KCg4KBwQABAACBgES
AzIECwoOCgcEAAQAAgYCEgMyDg8KTQoGBAAEAAIHEgM1BBgaPiBBIFB1Yi9TdWIgdG9waWMg
Y29uZmlndXJlZCBvbiB0aGUgc2VjcmV0IGNvdWxkIG5vdCBiZSBmb3VuZC4KCg4KBwQABAAC
BwESAzUEEwoOCgcEAAQAAgcCEgM1FhcK2QEKBgQABAACCBIDOwQgGskBIEEgUHViL1N1YiB0
b3BpYyBjb25maWd1cmVkIG9uIHRoZSBzZWNyZXQgZG9lcyBub3QgaGF2ZSB0aGUgbmVlZGVk
CiBwZXJtaXNzaW9ucy4gVGhlIFNlY3JldCBNYW5hZ2VyIFA0U0EgbXVzdCBiZSBncmFudGVk
CiAncHVic3ViLnRvcGljLnB1Ymxpc2gnIHBlcm1pc3Npb24gKG9yICdyb2xlcy9wdWJzdWIu
cHVibGlzaGVyJykgb24gdGhlCiB0b3BpYy4KCg4KBwQABAACCAESAzsEGwoOCgcEAAQAAggC
EgM7Hh8KTwoEBAACABIDPwISGkIgUmVzb3VyY2UgbmFtZSBvZiB0aGUgc2VjcmV0IGluIHRo
ZSBmb3JtYXQgYHByb2plY3RzLyovc2VjcmV0cy8qYAoKDAoFBAACAAUSAz8CCAoMCgUEAAIA
ARIDPwkNCgwKBQQAAgADEgM/EBEKQAoEBAACARIDQgIVGjMgVHlwZSBvZiBldmVudCB0aGF0
IGlzIGJlaW5nIGxvZ2dlZCBmb3IgdGhlIHNlY3JldAoKDAoFBAACAQYSA0ICCwoMCgUEAAIB
ARIDQgwQCgwKBQQAAgEDEgNCExQKOgoEBAACAhIDRQIZGi0gSHVtYW4gcmVhZGFibGUgbWVz
c2FnZSBkZXNjcmliaW5nIHRoZSBldmVudAoKDAoFBAACAgUSA0UCCAoMCgUEAAICARIDRQkU
CgwKBQQAAgIDEgNFFxhiBnByb3RvMw==
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Secretmanager::Logging::V1::SecretEvent::SecretEvent ===
    # Fields for SecretEvent
    # Field: name Type: 9 ()
    # Field: type Type: 14 (.google.cloud.secretmanager.logging.v1.SecretEvent.EventType)
    # Field: log_message Type: 9 ()

# Enum: SecretEvent::EventType
our $SecretEvent_EVENT_TYPE_UNSPECIFIED = 0;
our $SecretEvent_EXPIRES_IN_30_DAYS = 1;
our $SecretEvent_EXPIRES_IN_7_DAYS = 2;
our $SecretEvent_EXPIRES_IN_1_DAY = 3;
our $SecretEvent_EXPIRES_IN_6_HOURS = 4;
our $SecretEvent_EXPIRES_IN_1_HOUR = 5;
our $SecretEvent_EXPIRED = 6;
our $SecretEvent_TOPIC_NOT_FOUND = 7;
our $SecretEvent_TOPIC_PERMISSION_DENIED = 8;

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Secretmanager::Logging::V1::SecretEvent - Compiled Protocol Buffers messages for google/cloud/secretmanager/logging/v1/secret_event.proto

=head1 SYNOPSIS

    use Google::Cloud::Secretmanager::Logging::V1::SecretEvent;

    my $msg = Google::Cloud::Secretmanager::Logging::V1::SecretEvent::SecretEvent->new({
        name => $name,
        type => $type,
        log_message => $log_message,
    });

    # Read or update a field
    my $val = $msg->name();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Secretmanager::Logging::V1::SecretEvent::SecretEvent->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/secretmanager/logging/v1/secret_event.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Secretmanager::Logging::V1::SecretEvent::SecretEvent

Logged event relating to a specific secret

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Resource name of the secret in the format `projects/*/secrets/*`

=item * C<< $msg->type() >> / C<< $msg->type($value) >>

Type: C<Enum> (L<Google::Cloud::Secretmanager::Logging::V1::SecretEvent::EventType>)

Type of event that is being logged for the secret

=item * C<< $msg->log_message() >> / C<< $msg->log_message($value) >>

Type: C<String>

Human readable message describing the event

=back

=head3 Enum: SecretEvent::EventType

=over 4

=item * C<EVENT_TYPE_UNSPECIFIED> => C<0>

=item * C<EXPIRES_IN_30_DAYS> => C<1>

=item * C<EXPIRES_IN_7_DAYS> => C<2>

=item * C<EXPIRES_IN_1_DAY> => C<3>

=item * C<EXPIRES_IN_6_HOURS> => C<4>

=item * C<EXPIRES_IN_1_HOUR> => C<5>

=item * C<EXPIRED> => C<6>

=item * C<TOPIC_NOT_FOUND> => C<7>

=item * C<TOPIC_PERMISSION_DENIED> => C<8>

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Secretmanager::Logging::V1::SecretEvent::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
