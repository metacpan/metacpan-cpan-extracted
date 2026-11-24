package Google::Cloud::Video::Stitcher::V1::Events;

use strict;
use warnings;

our $VERSION = '0.14';

use Protobuf::Message;
use Protobuf::DescriptorPool;
use Protobuf::Internal qw(:all);
use MIME::Base64;

BEGIN {
    eval { require Google::Protobuf::Duration };
    my $descriptor_b64 = <<'EOF';
Citnb29nbGUvY2xvdWQvdmlkZW8vc3RpdGNoZXIvdjEvZXZlbnRzLnByb3RvEh5nb29nbGUu
Y2xvdWQudmlkZW8uc3RpdGNoZXIudjEaHmdvb2dsZS9wcm90b2J1Zi9kdXJhdGlvbi5wcm90
byKlBAoFRXZlbnQSQwoEdHlwZRgBIAEoDjIvLmdvb2dsZS5jbG91ZC52aWRlby5zdGl0Y2hl
ci52MS5FdmVudC5FdmVudFR5cGVSBHR5cGUSEAoDdXJpGAIgASgJUgN1cmkSDgoCaWQYAyAB
KAlSAmlkEjEKBm9mZnNldBgEIAEoCzIZLmdvb2dsZS5wcm90b2J1Zi5EdXJhdGlvblIGb2Zm
c2V0IoEDCglFdmVudFR5cGUSGgoWRVZFTlRfVFlQRV9VTlNQRUNJRklFRBAAEhEKDUNSRUFU
SVZFX1ZJRVcQARIJCgVTVEFSVBACEg8KC0JSRUFLX1NUQVJUEAMSDQoJQlJFQUtfRU5EEAQS
DgoKSU1QUkVTU0lPThAFEhIKDkZJUlNUX1FVQVJUSUxFEAYSDAoITUlEUE9JTlQQBxISCg5U
SElSRF9RVUFSVElMRRAIEgwKCENPTVBMRVRFEAkSDAoIUFJPR1JFU1MQChIICgRNVVRFEAsS
CgoGVU5NVVRFEAwSCQoFUEFVU0UQDRIJCgVDTElDSxAOEhEKDUNMSUNLX1RIUk9VR0gQDxIK
CgZSRVdJTkQQEBIKCgZSRVNVTUUQERIJCgVFUlJPUhASEgoKBkVYUEFORBAVEgwKCENPTExB
UFNFEBYSCQoFQ0xPU0UQGBIQCgxDTE9TRV9MSU5FQVIQGRIICgRTS0lQEBoSFQoRQUNDRVBU
X0lOVklUQVRJT04QGyKKAQoNUHJvZ3Jlc3NFdmVudBI6Cgt0aW1lX29mZnNldBgBIAEoCzIZ
Lmdvb2dsZS5wcm90b2J1Zi5EdXJhdGlvblIKdGltZU9mZnNldBI9CgZldmVudHMYAiADKAsy
JS5nb29nbGUuY2xvdWQudmlkZW8uc3RpdGNoZXIudjEuRXZlbnRSBmV2ZW50c0JzCiJjb20u
Z29vZ2xlLmNsb3VkLnZpZGVvLnN0aXRjaGVyLnYxQgtFdmVudHNQcm90b1ABWj5jbG91ZC5n
b29nbGUuY29tL2dvL3ZpZGVvL3N0aXRjaGVyL2FwaXYxL3N0aXRjaGVycGI7c3RpdGNoZXJw
YkqKHAoHEgUOAIIBAQq8BAoBDBIDDgASMrEEIENvcHlyaWdodCAyMDI1IEdvb2dsZSBMTEMK
CiBMaWNlbnNlZCB1bmRlciB0aGUgQXBhY2hlIExpY2Vuc2UsIFZlcnNpb24gMi4wICh0aGUg
IkxpY2Vuc2UiKTsKIHlvdSBtYXkgbm90IHVzZSB0aGlzIGZpbGUgZXhjZXB0IGluIGNvbXBs
aWFuY2Ugd2l0aCB0aGUgTGljZW5zZS4KIFlvdSBtYXkgb2J0YWluIGEgY29weSBvZiB0aGUg
TGljZW5zZSBhdAoKICAgICBodHRwOi8vd3d3LmFwYWNoZS5vcmcvbGljZW5zZXMvTElDRU5T
RS0yLjAKCiBVbmxlc3MgcmVxdWlyZWQgYnkgYXBwbGljYWJsZSBsYXcgb3IgYWdyZWVkIHRv
IGluIHdyaXRpbmcsIHNvZnR3YXJlCiBkaXN0cmlidXRlZCB1bmRlciB0aGUgTGljZW5zZSBp
cyBkaXN0cmlidXRlZCBvbiBhbiAiQVMgSVMiIEJBU0lTLAogV0lUSE9VVCBXQVJSQU5USUVT
IE9SIENPTkRJVElPTlMgT0YgQU5ZIEtJTkQsIGVpdGhlciBleHByZXNzIG9yIGltcGxpZWQu
CiBTZWUgdGhlIExpY2Vuc2UgZm9yIHRoZSBzcGVjaWZpYyBsYW5ndWFnZSBnb3Zlcm5pbmcg
cGVybWlzc2lvbnMgYW5kCiBsaW1pdGF0aW9ucyB1bmRlciB0aGUgTGljZW5zZS4KCggKAQIS
AxAAJwoJCgIDABIDEgAoCggKAQgSAxQAVQoJCgIICxIDFABVCggKAQgSAxUAIgoJCgIIChID
FQAiCggKAQgSAxYALAoJCgIICBIDFgAsCggKAQgSAxcAOwoJCgIIARIDFwA7CjMKAgQAEgQa
AHQBGicgRGVzY3JpYmVzIGFuIGV2ZW50IGFuZCBhIHRyaWdnZXIgVVJJLgoKCgoDBAABEgMa
CA0KMgoEBAAEABIEHAJnAxokIERlc2NyaWJlcyB0aGUgZXZlbnQgdGhhdCBvY2N1cnJlZC4K
CgwKBQQABAABEgMcBxAKLwoGBAAEAAIAEgMeBB8aICBUaGUgZXZlbnQgdHlwZSBpcyB1bnNw
ZWNpZmllZC4KCg4KBwQABAACAAESAx4EGgoOCgcEAAQAAgACEgMeHR4KMwoGBAAEAAIBEgMh
BBYaJCBGaXJzdCBmcmFtZSBvZiBjcmVhdGl2ZSBhZCB2aWV3ZWQuCgoOCgcEAAQAAgEBEgMh
BBEKDgoHBAAEAAIBAhIDIRQVCiUKBgQABAACAhIDJAQOGhYgQ3JlYXRpdmUgYWQgc3RhcnRl
ZC4KCg4KBwQABAACAgESAyQECQoOCgcEAAQAAgICEgMkDA0KJgoGBAAEAAIDEgMnBBQaFyBT
dGFydCBvZiBhbiBhZCBicmVhay4KCg4KBwQABAACAwESAycEDwoOCgcEAAQAAgMCEgMnEhMK
JAoGBAAEAAIEEgMqBBIaFSBFbmQgb2YgYW4gYWQgYnJlYWsuCgoOCgcEAAQAAgQBEgMqBA0K
DgoHBAAEAAIEAhIDKhARChwKBgQABAACBRIDLQQTGg0gSW1wcmVzc2lvbi4KCg4KBwQABAAC
BQESAy0EDgoOCgcEAAQAAgUCEgMtERIKKQoGBAAEAAIGEgMwBBcaGiBGaXJzdCBxdWFydGls
ZSBwcm9ncmVzcy4KCg4KBwQABAACBgESAzAEEgoOCgcEAAQAAgYCEgMwFRYKIwoGBAAEAAIH
EgMzBBEaFCBNaWRwb2ludCBwcm9ncmVzcy4KCg4KBwQABAACBwESAzMEDAoOCgcEAAQAAgcC
EgMzDxAKKQoGBAAEAAIIEgM2BBcaGiBUaGlyZCBxdWFydGlsZSBwcm9ncmVzcy4KCg4KBwQA
BAACCAESAzYEEgoOCgcEAAQAAggCEgM2FRYKJwoGBAAEAAIJEgM5BBEaGCBBZCBwcm9ncmVz
cyBjb21wbGV0ZWQuCgoOCgcEAAQAAgkBEgM5BAwKDgoHBAAEAAIJAhIDOQ8QCjgKBgQABAAC
ChIDPAQSGikgU3BlY2lmaWMgcHJvZ3Jlc3MgZXZlbnQgd2l0aCBhbiBvZmZzZXQuCgoOCgcE
AAQAAgoBEgM8BAwKDgoHBAAEAAIKAhIDPA8RCh4KBgQABAACCxIDPwQOGg8gUGxheWVyIG11
dGVkLgoKDgoHBAAEAAILARIDPwQICg4KBwQABAACCwISAz8LDQogCgYEAAQAAgwSA0IEEBoR
IFBsYXllciB1bm11dGVkLgoKDgoHBAAEAAIMARIDQgQKCg4KBwQABAACDAISA0INDwofCgYE
AAQAAg0SA0UEDxoQIFBsYXllciBwYXVzZWQuCgoOCgcEAAQAAg0BEgNFBAkKDgoHBAAEAAIN
AhIDRQwOCh0KBgQABAACDhIDSAQPGg4gQ2xpY2sgZXZlbnQuCgoOCgcEAAQAAg4BEgNIBAkK
DgoHBAAEAAIOAhIDSAwOCiUKBgQABAACDxIDSwQXGhYgQ2xpY2stdGhyb3VnaCBldmVudC4K
Cg4KBwQABAACDwESA0sEEQoOCgcEAAQAAg8CEgNLFBYKIgoGBAAEAAIQEgNOBBAaEyBQbGF5
ZXIgcmV3aW5kaW5nLgoKDgoHBAAEAAIQARIDTgQKCg4KBwQABAACEAISA04NDwogCgYEAAQA
AhESA1EEEBoRIFBsYXllciByZXN1bWVkLgoKDgoHBAAEAAIRARIDUQQKCg4KBwQABAACEQIS
A1ENDwodCgYEAAQAAhISA1QEDxoOIEVycm9yIGV2ZW50LgoKDgoHBAAEAAISARIDVAQJCg4K
BwQABAACEgISA1QMDgouCgYEAAQAAhMSA1cEEBofIEFkIGV4cGFuZGVkIHRvIGEgbGFyZ2Vy
IHNpemUuCgoOCgcEAAQAAhMBEgNXBAoKDgoHBAAEAAITAhIDVw0PCjAKBgQABAACFBIDWgQS
GiEgQWQgY29sbGFwc2VkIHRvIGEgc21hbGxlciBzaXplLgoKDgoHBAAEAAIUARIDWgQMCg4K
BwQABAACFAISA1oPEQomCgYEAAQAAhUSA10EDxoXIE5vbi1saW5lYXIgYWQgY2xvc2VkLgoK
DgoHBAAEAAIVARIDXQQJCg4KBwQABAACFQISA10MDgoiCgYEAAQAAhYSA2AEFhoTIExpbmVh
ciBhZCBjbG9zZWQuCgoOCgcEAAQAAhYBEgNgBBAKDgoHBAAEAAIWAhIDYBMVChwKBgQABAAC
FxIDYwQOGg0gQWQgc2tpcHBlZC4KCg4KBwQABAACFwESA2MECAoOCgcEAAQAAhcCEgNjCw0K
KQoGBAAEAAIYEgNmBBsaGiBBY2NlcHQgaW52aXRhdGlvbiBldmVudC4KCg4KBwQABAACGAES
A2YEFQoOCgcEAAQAAhgCEgNmGBoKMQoEBAACABIDagIVGiQgRGVzY3JpYmVzIHRoZSBldmVu
dCB0aGF0IG9jY3VycmVkLgoKDAoFBAACAAYSA2oCCwoMCgUEAAIAARIDagwQCgwKBQQAAgAD
EgNqExQKMQoEBAACARIDbQIRGiQgVGhlIFVSSSB0byB0cmlnZ2VyIGZvciB0aGlzIGV2ZW50
LgoKDAoFBAACAQUSA20CCAoMCgUEAAIBARIDbQkMCgwKBQQAAgEDEgNtDxAKIwoEBAACAhID
cAIQGhYgVGhlIElEIG9mIHRoZSBldmVudC4KCgwKBQQAAgIFEgNwAggKDAoFBAACAgESA3AJ
CwoMCgUEAAICAxIDcA4PCkUKBAQAAgMSA3MCJho4IFRoZSBvZmZzZXQgaW4gc2Vjb25kcyBp
ZiB0aGUgZXZlbnQgdHlwZSBpcyBgUFJPR1JFU1NgLgoKDAoFBAACAwYSA3MCGgoMCgUEAAID
ARIDcxshCgwKBQQAAgMDEgNzJCUKZQoCBAESBXgAggEBGlggSW5kaWNhdGVzIGEgdGltZSBp
biB3aGljaCBhIGxpc3Qgb2YgZXZlbnRzIHNob3VsZCBiZSB0cmlnZ2VyZWQKIGR1cmluZyBt
ZWRpYSBwbGF5YmFjay4KCgoKAwQBARIDeAgVCoIBCgQEAQIAEgN7AisadSBUaGUgdGltZSB3
aGVuIHRoZSBmb2xsb3dpbmcgdHJhY2tpbmcgZXZlbnRzIG9jY3Vycy4gVGhlIHRpbWUgaXMg
aW4KIHNlY29uZHMgcmVsYXRpdmUgdG8gdGhlIHN0YXJ0IG9mIHRoZSBWT0QgYXNzZXQuCgoM
CgUEAQIABhIDewIaCgwKBQQBAgABEgN7GyYKDAoFBAECAAMSA3spKgr/AQoEBAECARIEgQEC
HBrwASBUaGUgbGlzdCBvZiBwcm9ncmVzcyB0cmFja2luZyBldmVudHMgZm9yIHRoZSBhZCBi
cmVhay4gVGhlc2UgY2FuIGJlIG9mCiB0aGUgZm9sbG93aW5nIElBQiB0eXBlczogYEJSRUFL
X1NUQVJUYCwgYEJSRUFLX0VORGAsIGBJTVBSRVNTSU9OYCwKIGBDUkVBVElWRV9WSUVXYCwg
YFNUQVJUYCwgYEZJUlNUX1FVQVJUSUxFYCwgYE1JRFBPSU5UYCwgYFRISVJEX1FVQVJUSUxF
YCwKIGBDT01QTEVURWAsIGBQUk9HUkVTU2AuCgoNCgUEAQIBBBIEgQECCgoNCgUEAQIBBhIE
gQELEAoNCgUEAQIBARIEgQERFwoNCgUEAQIBAxIEgQEaG2IGcHJvdG8z
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Video::Stitcher::V1::Events::Event ===
    # Fields for Event
    # Field: type Type: 14 (.google.cloud.video.stitcher.v1.Event.EventType)
    # Field: uri Type: 9 ()
    # Field: id Type: 9 ()
    # Field: offset Type: 11 (.google.protobuf.Duration)

# Enum: Event::EventType
our $Event_EVENT_TYPE_UNSPECIFIED = 0;
our $Event_CREATIVE_VIEW = 1;
our $Event_START = 2;
our $Event_BREAK_START = 3;
our $Event_BREAK_END = 4;
our $Event_IMPRESSION = 5;
our $Event_FIRST_QUARTILE = 6;
our $Event_MIDPOINT = 7;
our $Event_THIRD_QUARTILE = 8;
our $Event_COMPLETE = 9;
our $Event_PROGRESS = 10;
our $Event_MUTE = 11;
our $Event_UNMUTE = 12;
our $Event_PAUSE = 13;
our $Event_CLICK = 14;
our $Event_CLICK_THROUGH = 15;
our $Event_REWIND = 16;
our $Event_RESUME = 17;
our $Event_ERROR = 18;
our $Event_EXPAND = 21;
our $Event_COLLAPSE = 22;
our $Event_CLOSE = 24;
our $Event_CLOSE_LINEAR = 25;
our $Event_SKIP = 26;
our $Event_ACCEPT_INVITATION = 27;

# === Message: Google::Cloud::Video::Stitcher::V1::Events::ProgressEvent ===
    # Fields for ProgressEvent
    # Field: time_offset Type: 11 (.google.protobuf.Duration)
    # Field: events Type: 11 (.google.cloud.video.stitcher.v1.Event)

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Video::Stitcher::V1::Events - Compiled Protocol Buffers messages for google/cloud/video/stitcher/v1/events.proto

=head1 SYNOPSIS

    use Google::Cloud::Video::Stitcher::V1::Events;

    my $msg = Google::Cloud::Video::Stitcher::V1::Events::Event->new({
        type => $type,
        uri => $uri,
        id => $id,
        offset => $offset,
    });

    # Read or update a field
    my $val = $msg->type();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Video::Stitcher::V1::Events::Event->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/video/stitcher/v1/events.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Video::Stitcher::V1::Events::Event

Describes an event and a trigger URI.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->type() >> / C<< $msg->type($value) >>

Type: C<Enum> (L<Google::Cloud::Video::Stitcher::V1::Event::EventType>)

Describes the event that occurred.

=item * C<< $msg->uri() >> / C<< $msg->uri($value) >>

Type: C<String>

The URI to trigger for this event.

=item * C<< $msg->id() >> / C<< $msg->id($value) >>

Type: C<String>

The ID of the event.

=item * C<< $msg->offset() >> / C<< $msg->offset($value) >>

Type: C<Message> (L<Google::Protobuf::Duration::Duration>)

The offset in seconds if the event type is `PROGRESS`.

=back

=head3 Enum: Event::EventType

=over 4

=item * C<EVENT_TYPE_UNSPECIFIED> => C<0>

=item * C<CREATIVE_VIEW> => C<1>

=item * C<START> => C<2>

=item * C<BREAK_START> => C<3>

=item * C<BREAK_END> => C<4>

=item * C<IMPRESSION> => C<5>

=item * C<FIRST_QUARTILE> => C<6>

=item * C<MIDPOINT> => C<7>

=item * C<THIRD_QUARTILE> => C<8>

=item * C<COMPLETE> => C<9>

=item * C<PROGRESS> => C<10>

=item * C<MUTE> => C<11>

=item * C<UNMUTE> => C<12>

=item * C<PAUSE> => C<13>

=item * C<CLICK> => C<14>

=item * C<CLICK_THROUGH> => C<15>

=item * C<REWIND> => C<16>

=item * C<RESUME> => C<17>

=item * C<ERROR> => C<18>

=item * C<EXPAND> => C<21>

=item * C<COLLAPSE> => C<22>

=item * C<CLOSE> => C<24>

=item * C<CLOSE_LINEAR> => C<25>

=item * C<SKIP> => C<26>

=item * C<ACCEPT_INVITATION> => C<27>

=back

=head2 Google::Cloud::Video::Stitcher::V1::Events::ProgressEvent

Indicates a time in which a list of events should be triggered
during media playback.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->time_offset() >> / C<< $msg->time_offset($value) >>

Type: C<Message> (L<Google::Protobuf::Duration::Duration>)

The time when the following tracking events occurs. The time is in
seconds relative to the start of the VOD asset.

=item * C<< $msg->events() >> / C<< $msg->events($value) >>

Type: C<Message> (L<Google::Cloud::Video::Stitcher::V1::Events::Event>)

The list of progress tracking events for the ad break. These can be of
the following IAB types: `BREAK_START`, `BREAK_END`, `IMPRESSION`,
`CREATIVE_VIEW`, `START`, `FIRST_QUARTILE`, `MIDPOINT`, `THIRD_QUARTILE`,
`COMPLETE`, `PROGRESS`.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Video::Stitcher::V1::Events::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
