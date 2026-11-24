package Google::Cloud::Eventarc::Logging::V1::EnrollmentActivity;

use strict;
use warnings;

our $VERSION = '0.14';

use Protobuf::Message;
use Protobuf::DescriptorPool;
use Protobuf::Internal qw(:all);
use MIME::Base64;

BEGIN {
    eval { require Google::Api::FieldInfo };
    eval { require Google::Protobuf::Timestamp };
    eval { require Google::Rpc::Status };
    my $descriptor_b64 = <<'EOF';
Cjpnb29nbGUvY2xvdWQvZXZlbnRhcmMvbG9nZ2luZy92MS9lbnJvbGxtZW50X2FjdGl2aXR5
LnByb3RvEiBnb29nbGUuY2xvdWQuZXZlbnRhcmMubG9nZ2luZy52MRobZ29vZ2xlL2FwaS9m
aWVsZF9pbmZvLnByb3RvGh9nb29nbGUvcHJvdG9idWYvdGltZXN0YW1wLnByb3RvGhdnb29n
bGUvcnBjL3N0YXR1cy5wcm90byKHBAoSRW5yb2xsbWVudEFjdGl2aXR5EikKC21lc3NhZ2Vf
dWlkGAEgASgJQgjijM/XCAIIAVIKbWVzc2FnZVVpZBJkCgphdHRyaWJ1dGVzGAIgAygLMkQu
Z29vZ2xlLmNsb3VkLmV2ZW50YXJjLmxvZ2dpbmcudjEuRW5yb2xsbWVudEFjdGl2aXR5LkF0
dHJpYnV0ZXNFbnRyeVIKYXR0cmlidXRlcxI/Cg1hY3Rpdml0eV90aW1lGAMgASgLMhouZ29v
Z2xlLnByb3RvYnVmLlRpbWVzdGFtcFIMYWN0aXZpdHlUaW1lElgKB21hdGNoZWQYBCABKAsy
PC5nb29nbGUuY2xvdWQuZXZlbnRhcmMubG9nZ2luZy52MS5FbnJvbGxtZW50QWN0aXZpdHku
TWF0Y2hlZEgAUgdtYXRjaGVkGnoKB01hdGNoZWQSGAoHZGV0YWlscxgBIAEoCVIHZGV0YWls
cxIrChFldmVudF9kZXN0aW5hdGlvbhgCIAEoCVIQZXZlbnREZXN0aW5hdGlvbhIoCgVlcnJv
chgDIAEoCzISLmdvb2dsZS5ycGMuU3RhdHVzUgVlcnJvcho9Cg9BdHRyaWJ1dGVzRW50cnkS
EAoDa2V5GAEgASgJUgNrZXkSFAoFdmFsdWUYAiABKAlSBXZhbHVlOgI4AUIKCghhY3Rpdml0
eULuAQokY29tLmdvb2dsZS5jbG91ZC5ldmVudGFyYy5sb2dnaW5nLnYxQhdFbnJvbGxtZW50
QWN0aXZpdHlQcm90b1ABWj5jbG91ZC5nb29nbGUuY29tL2dvL2V2ZW50YXJjL2xvZ2dpbmcv
YXBpdjEvbG9nZ2luZ3BiO2xvZ2dpbmdwYqoCIEdvb2dsZS5DbG91ZC5FdmVudGFyYy5Mb2dn
aW5nLlYxygIgR29vZ2xlXENsb3VkXEV2ZW50YXJjXExvZ2dpbmdcVjHqAiRHb29nbGU6OkNs
b3VkOjpFdmVudGFyYzo6TG9nZ2luZzo6VjFKuQ8KBhIEDgA9AQq8BAoBDBIDDgASMrEEIENv
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
bmRlciB0aGUgTGljZW5zZS4KCggKAQISAxAAKQoJCgIDABIDEgAlCgkKAgMBEgMTACkKCQoC
AwISAxQAIQoICgEIEgMWAD0KCQoCCCUSAxYAPQoICgEIEgMXAFUKCQoCCAsSAxcAVQoICgEI
EgMYACIKCQoCCAoSAxgAIgoICgEIEgMZADgKCQoCCAgSAxkAOAoICgEIEgMaAD0KCQoCCAES
AxoAPQoICgEIEgMbAD4KCQoCCCkSAxsAPgoICgEIEgMcAD0KCQoCCC0SAxwAPQpZCgIEABIE
HwA9ARpNIExvZ2dlZCBkdXJpbmcgdGhlIHByb2Nlc3Npbmcgb2YgYW4gZW5yb2xsbWVudCBv
biBhbiBldmVudCBpbiBhIG1lc3NhZ2UgYnVzLgoKCgoDBAABEgMfCBoKWwoEBAADABIEIQIr
AxpNIFN0cnVjdHVyZWQgbG9nIG1lc3NhZ2UgdGhhdCBpcyBlbWl0dGVkIHdoZW4gYW4gZXZl
bnQgbWF0Y2hlcyBhbiBlbnJvbGxtZW50LgoKDAoFBAADAAESAyEKEQo/CgYEAAMAAgASAyME
FxowIEluZm9ybWF0aW9uYWwgZGV0YWlscyBhYm91dCB0aGUgbWF0Y2hlZCBldmVudC4KCg4K
BwQAAwACAAUSAyMECgoOCgcEAAMAAgABEgMjCxIKDgoHBAADAAIAAxIDIxUWCmIKBgQAAwAC
ARIDJwQhGlMgVGhlIGRlc3RpbmF0aW9uIHRoaXMgZW5yb2xsbWVudCBpcyBtYXRjaGVkIHRv
LCBzdWNoIGFzIHRoZSBuYW1lIG9mIHRoZQogcGlwZWxpbmUuCgoOCgcEAAMAAgEFEgMnBAoK
DgoHBAADAAIBARIDJwscCg4KBwQAAwACAQMSAycfIApACgYEAAMAAgISAyoEIBoxIExvZ2dl
ZCB3aGVuIHRoZSBlbnJvbGxtZW50IGVuY291bnRlcnMgYW4gZXJyb3IuCgoOCgcEAAMAAgIG
EgMqBBUKDgoHBAADAAICARIDKhYbCg4KBwQAAwACAgMSAyoeHwplCgQEAAIAEgMvAkIaWCBU
aGUgdW5pcXVlIHN5c3RlbSBnZW5lcmF0ZWQgSUQgYXNzb2NpYXRlZCB3aXRoIHRoZSBldmVu
dCBwYXNzZWQgZnJvbSB0aGUKIG1lc3NhZ2UgYnVzLgoKDAoFBAACAAUSAy8CCAoMCgUEAAIA
ARIDLwkUCgwKBQQAAgADEgMvFxgKDAoFBAACAAgSAy8ZQQoSCgsEAAIACMzx+YoBARIDLxpA
Ck0KBAQAAgESAzICJRpAIFRoZSBDbG91ZEV2ZW50IElEIGFuZCBzb3VyY2UgZnJvbSB0aGUg
YXR0cmlidXRlcyBvZiB0aGUgZXZlbnQuCgoMCgUEAAIBBhIDMgIVCgwKBQQAAgEBEgMyFiAK
DAoFBAACAQMSAzIjJAo8CgQEAAICEgM1Ai4aLyBUaGUgcG9pbnQgaW4gdGltZSB3aGVuIHRo
ZSBhY3Rpdml0eSBvY2N1cnJlZC4KCgwKBQQAAgIGEgM1AhsKDAoFBAACAgESAzUcKQoMCgUE
AAICAxIDNSwtCmEKBAQACAASBDkCPAMaUyBPbmUgb2YgdGhlIGFjdGl2aXRpZXMgdGhhdCBj
YW4gYmUgbG9nZ2VkIGR1cmluZyB0aGUgcHJvY2Vzc2luZyBvZiBhbgogZW5yb2xsbWVudC4K
CgwKBQQACAABEgM5CBAKOgoEBAACAxIDOwQYGi0gTG9nZ2VkIHdoZW4gYW4gZXZlbnQgbWF0
Y2hlcyBhbiBlbnJvbGxtZW50LgoKDAoFBAACAwYSAzsECwoMCgUEAAIDARIDOwwTCgwKBQQA
AgMDEgM7FhdiBnByb3RvMw==
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Eventarc::Logging::V1::EnrollmentActivity::EnrollmentActivity ===
    # Fields for EnrollmentActivity
    # Field: message_uid Type: 9 ()
    # Field: attributes Type: 11 (.google.cloud.eventarc.logging.v1.EnrollmentActivity.AttributesEntry)
    # Field: activity_time Type: 11 (.google.protobuf.Timestamp)
    # Field: matched Type: 11 (.google.cloud.eventarc.logging.v1.EnrollmentActivity.Matched)

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Eventarc::Logging::V1::EnrollmentActivity - Compiled Protocol Buffers messages for google/cloud/eventarc/logging/v1/enrollment_activity.proto

=head1 SYNOPSIS

    use Google::Cloud::Eventarc::Logging::V1::EnrollmentActivity;

    my $msg = Google::Cloud::Eventarc::Logging::V1::EnrollmentActivity::EnrollmentActivity->new({
        message_uid => $message_uid,
        attributes => $attributes,
        activity_time => $activity_time,
        matched => $matched,
    });

    # Read or update a field
    my $val = $msg->message_uid();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Eventarc::Logging::V1::EnrollmentActivity::EnrollmentActivity->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/eventarc/logging/v1/enrollment_activity.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Eventarc::Logging::V1::EnrollmentActivity::EnrollmentActivity

Logged during the processing of an enrollment on an event in a message bus.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->message_uid() >> / C<< $msg->message_uid($value) >>

Type: C<String>

The unique system generated ID associated with the event passed from the
message bus.

=item * C<< $msg->attributes() >> / C<< $msg->attributes($value) >>

Type: C<Message> (L<Google::Cloud::Eventarc::Logging::V1::EnrollmentActivity::EnrollmentActivity::AttributesEntry>)

The CloudEvent ID and source from the attributes of the event.

=item * C<< $msg->activity_time() >> / C<< $msg->activity_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

The point in time when the activity occurred.

=item * C<< $msg->matched() >> / C<< $msg->matched($value) >>

Type: C<Message> (L<Google::Cloud::Eventarc::Logging::V1::EnrollmentActivity::EnrollmentActivity::Matched>)

Logged when an event matches an enrollment.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Eventarc::Logging::V1::EnrollmentActivity::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
