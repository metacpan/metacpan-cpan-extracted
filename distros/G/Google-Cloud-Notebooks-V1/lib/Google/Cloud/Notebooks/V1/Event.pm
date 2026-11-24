package Google::Cloud::Notebooks::V1::Event;

use strict;
use warnings;

our $VERSION = '0.14';

use Protobuf::Message;
use Protobuf::DescriptorPool;
use Protobuf::Internal qw(:all);
use MIME::Base64;

BEGIN {
    eval { require Google::Api::FieldBehavior };
    eval { require Google::Protobuf::Timestamp };
    my $descriptor_b64 = <<'EOF';
CiVnb29nbGUvY2xvdWQvbm90ZWJvb2tzL3YxL2V2ZW50LnByb3RvEhlnb29nbGUuY2xvdWQu
bm90ZWJvb2tzLnYxGh9nb29nbGUvYXBpL2ZpZWxkX2JlaGF2aW9yLnByb3RvGh9nb29nbGUv
cHJvdG9idWYvdGltZXN0YW1wLnByb3RvIu0CCgVFdmVudBI7CgtyZXBvcnRfdGltZRgBIAEo
CzIaLmdvb2dsZS5wcm90b2J1Zi5UaW1lc3RhbXBSCnJlcG9ydFRpbWUSPgoEdHlwZRgCIAEo
DjIqLmdvb2dsZS5jbG91ZC5ub3RlYm9va3MudjEuRXZlbnQuRXZlbnRUeXBlUgR0eXBlEkwK
B2RldGFpbHMYAyADKAsyLS5nb29nbGUuY2xvdWQubm90ZWJvb2tzLnYxLkV2ZW50LkRldGFp
bHNFbnRyeUID4EEBUgdkZXRhaWxzGjoKDERldGFpbHNFbnRyeRIQCgNrZXkYASABKAlSA2tl
eRIUCgV2YWx1ZRgCIAEoCVIFdmFsdWU6AjgBIl0KCUV2ZW50VHlwZRIaChZFVkVOVF9UWVBF
X1VOU1BFQ0lGSUVEEAASCAoESURMRRABEg0KCUhFQVJUQkVBVBACEgoKBkhFQUxUSBADEg8K
C01BSU5URU5BTkNFEARCagodY29tLmdvb2dsZS5jbG91ZC5ub3RlYm9va3MudjFCCkV2ZW50
UHJvdG9QAVo7Y2xvdWQuZ29vZ2xlLmNvbS9nby9ub3RlYm9va3MvYXBpdjEvbm90ZWJvb2tz
cGI7bm90ZWJvb2tzcGJK8w4KBhIEDgA8AQq8BAoBDBIDDgASMrEEIENvcHlyaWdodCAyMDI1
IEdvb2dsZSBMTEMKCiBMaWNlbnNlZCB1bmRlciB0aGUgQXBhY2hlIExpY2Vuc2UsIFZlcnNp
b24gMi4wICh0aGUgIkxpY2Vuc2UiKTsKIHlvdSBtYXkgbm90IHVzZSB0aGlzIGZpbGUgZXhj
ZXB0IGluIGNvbXBsaWFuY2Ugd2l0aCB0aGUgTGljZW5zZS4KIFlvdSBtYXkgb2J0YWluIGEg
Y29weSBvZiB0aGUgTGljZW5zZSBhdAoKICAgICBodHRwOi8vd3d3LmFwYWNoZS5vcmcvbGlj
ZW5zZXMvTElDRU5TRS0yLjAKCiBVbmxlc3MgcmVxdWlyZWQgYnkgYXBwbGljYWJsZSBsYXcg
b3IgYWdyZWVkIHRvIGluIHdyaXRpbmcsIHNvZnR3YXJlCiBkaXN0cmlidXRlZCB1bmRlciB0
aGUgTGljZW5zZSBpcyBkaXN0cmlidXRlZCBvbiBhbiAiQVMgSVMiIEJBU0lTLAogV0lUSE9V
VCBXQVJSQU5USUVTIE9SIENPTkRJVElPTlMgT0YgQU5ZIEtJTkQsIGVpdGhlciBleHByZXNz
IG9yIGltcGxpZWQuCiBTZWUgdGhlIExpY2Vuc2UgZm9yIHRoZSBzcGVjaWZpYyBsYW5ndWFn
ZSBnb3Zlcm5pbmcgcGVybWlzc2lvbnMgYW5kCiBsaW1pdGF0aW9ucyB1bmRlciB0aGUgTGlj
ZW5zZS4KCggKAQISAxAAIgoJCgIDABIDEgApCgkKAgMBEgMTACkKCAoBCBIDFQBSCgkKAggL
EgMVAFIKCAoBCBIDFgAiCgkKAggKEgMWACIKCAoBCBIDFwArCgkKAggIEgMXACsKCAoBCBID
GAA2CgkKAggBEgMYADYKWAoCBAASBBsAPAEaTCBUaGUgZGVmaW5pdGlvbiBvZiBhbiBFdmVu
dCBmb3IgYSBtYW5hZ2VkIC8gc2VtaS1tYW5hZ2VkIG5vdGVib29rIGluc3RhbmNlLgoKCgoD
BAABEgMbCA0KMgoEBAAEABIEHQIyAxokIFRoZSBkZWZpbml0aW9uIG9mIHRoZSBldmVudCB0
eXBlcy4KCgwKBQQABAABEgMdBxAKKAoGBAAEAAIAEgMfBB8aGSBFdmVudCBpcyBub3Qgc3Bl
Y2lmaWVkLgoKDgoHBAAEAAIAARIDHwQaCg4KBwQABAACAAISAx8dHgovCgYEAAQAAgESAyIE
DRogIFRoZSBpbnN0YW5jZSAvIHJ1bnRpbWUgaXMgaWRsZQoKDgoHBAAEAAIBARIDIgQICg4K
BwQABAACAQISAyILDAqHAQoGBAAEAAICEgMnBBIaeCBUaGUgaW5zdGFuY2UgLyBydW50aW1l
IGlzIGF2YWlsYWJsZS4KIFRoaXMgZXZlbnQgaW5kaWNhdGVzIHRoYXQgaW5zdGFuY2UgLyBy
dW50aW1lIHVuZGVybHlpbmcgY29tcHV0ZSBpcwogb3BlcmF0aW9uYWwuCgoOCgcEAAQAAgIB
EgMnBA0KDgoHBAAEAAICAhIDJxARCn4KBgQABAACAxIDKwQPGm8gVGhlIGluc3RhbmNlIC8g
cnVudGltZSBoZWFsdGggaXMgYXZhaWxhYmxlLgogVGhpcyBldmVudCBpbmRpY2F0ZXMgdGhh
dCBpbnN0YW5jZSAvIHJ1bnRpbWUgaGVhbHRoIGluZm9ybWF0aW9uLgoKDgoHBAAEAAIDARID
KwQKCg4KBwQABAACAwISAysNDgrVAQoGBAAEAAIEEgMxBBQaxQEgVGhlIGluc3RhbmNlIC8g
cnVudGltZSBpcyBhdmFpbGFibGUuCiBUaGlzIGV2ZW50IGFsbG93cyBpbnN0YW5jZSAvIHJ1
bnRpbWUgdG8gc2VuZCBIb3N0IG1haW50ZW5hbmNlCiBpbmZvcm1hdGlvbiB0byBDb250cm9s
IFBsYW5lLgogaHR0cHM6Ly9jbG91ZC5nb29nbGUuY29tL2NvbXB1dGUvZG9jcy9ncHVzL2dw
dS1ob3N0LW1haW50ZW5hbmNlCgoOCgcEAAQAAgQBEgMxBA8KDgoHBAAEAAIEAhIDMRITCiEK
BAQAAgASAzUCLBoUIEV2ZW50IHJlcG9ydCB0aW1lLgoKDAoFBAACAAYSAzUCGwoMCgUEAAIA
ARIDNRwnCgwKBQQAAgADEgM1KisKGgoEBAACARIDOAIVGg0gRXZlbnQgdHlwZS4KCgwKBQQA
AgEGEgM4AgsKDAoFBAACAQESAzgMEAoMCgUEAAIBAxIDOBMUClUKBAQAAgISAzsCSxpIIE9w
dGlvbmFsLiBFdmVudCBkZXRhaWxzLiBUaGlzIGZpZWxkIGlzIHVzZWQgdG8gcGFzcyBldmVu
dCBpbmZvcm1hdGlvbi4KCgwKBQQAAgIGEgM7AhUKDAoFBAACAgESAzsWHQoMCgUEAAICAxID
OyAhCgwKBQQAAgIIEgM7IkoKDwoIBAACAgicCAASAzsjSWIGcHJvdG8z
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Notebooks::V1::Event::Event ===
    # Fields for Event
    # Field: report_time Type: 11 (.google.protobuf.Timestamp)
    # Field: type Type: 14 (.google.cloud.notebooks.v1.Event.EventType)
    # Field: details Type: 11 (.google.cloud.notebooks.v1.Event.DetailsEntry)

# Enum: Event::EventType
our $Event_EVENT_TYPE_UNSPECIFIED = 0;
our $Event_IDLE = 1;
our $Event_HEARTBEAT = 2;
our $Event_HEALTH = 3;
our $Event_MAINTENANCE = 4;

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Notebooks::V1::Event - Compiled Protocol Buffers messages for google/cloud/notebooks/v1/event.proto

=head1 SYNOPSIS

    use Google::Cloud::Notebooks::V1::Event;

    my $msg = Google::Cloud::Notebooks::V1::Event::Event->new({
        report_time => $report_time,
        type => $type,
        details => $details,
    });

    # Read or update a field
    my $val = $msg->report_time();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Notebooks::V1::Event::Event->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/notebooks/v1/event.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Notebooks::V1::Event::Event

The definition of an Event for a managed / semi-managed notebook instance.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->report_time() >> / C<< $msg->report_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Event report time.

=item * C<< $msg->type() >> / C<< $msg->type($value) >>

Type: C<Enum> (L<Google::Cloud::Notebooks::V1::Event::EventType>)

Event type.

=item * C<< $msg->details() >> / C<< $msg->details($value) >>

Type: C<Message> (L<Google::Cloud::Notebooks::V1::Event::Event::DetailsEntry>)

Optional. Event details. This field is used to pass event information.

=back

=head3 Enum: Event::EventType

=over 4

=item * C<EVENT_TYPE_UNSPECIFIED> => C<0>

=item * C<IDLE> => C<1>

=item * C<HEARTBEAT> => C<2>

=item * C<HEALTH> => C<3>

=item * C<MAINTENANCE> => C<4>

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Notebooks::V1::Event::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
