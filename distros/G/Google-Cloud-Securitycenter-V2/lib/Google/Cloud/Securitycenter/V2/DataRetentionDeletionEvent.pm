package Google::Cloud::Securitycenter::V2::DataRetentionDeletionEvent;

use strict;
use warnings;

our $VERSION = '0.14';

use Protobuf::Message;
use Protobuf::DescriptorPool;
use Protobuf::Internal qw(:all);
use MIME::Base64;

BEGIN {
    eval { require Google::Protobuf::Duration };
    eval { require Google::Protobuf::Timestamp };
    my $descriptor_b64 = <<'EOF';
CkJnb29nbGUvY2xvdWQvc2VjdXJpdHljZW50ZXIvdjIvZGF0YV9yZXRlbnRpb25fZGVsZXRp
b25fZXZlbnQucHJvdG8SHmdvb2dsZS5jbG91ZC5zZWN1cml0eWNlbnRlci52MhoeZ29vZ2xl
L3Byb3RvYnVmL2R1cmF0aW9uLnByb3RvGh9nb29nbGUvcHJvdG9idWYvdGltZXN0YW1wLnBy
b3RvIpQDChpEYXRhUmV0ZW50aW9uRGVsZXRpb25FdmVudBJMChRldmVudF9kZXRlY3Rpb25f
dGltZRgCIAEoCzIaLmdvb2dsZS5wcm90b2J1Zi5UaW1lc3RhbXBSEmV2ZW50RGV0ZWN0aW9u
VGltZRIqChFkYXRhX29iamVjdF9jb3VudBgDIAEoA1IPZGF0YU9iamVjdENvdW50Ek0KFW1h
eF9yZXRlbnRpb25fYWxsb3dlZBgEIAEoCzIZLmdvb2dsZS5wcm90b2J1Zi5EdXJhdGlvblIT
bWF4UmV0ZW50aW9uQWxsb3dlZBJjCgpldmVudF90eXBlGAUgASgOMkQuZ29vZ2xlLmNsb3Vk
LnNlY3VyaXR5Y2VudGVyLnYyLkRhdGFSZXRlbnRpb25EZWxldGlvbkV2ZW50LkV2ZW50VHlw
ZVIJZXZlbnRUeXBlIkgKCUV2ZW50VHlwZRIaChZFVkVOVF9UWVBFX1VOU1BFQ0lGSUVEEAAS
HwobRVZFTlRfVFlQRV9NQVhfVFRMX0VYQ0VFREVEEAFC+QEKImNvbS5nb29nbGUuY2xvdWQu
c2VjdXJpdHljZW50ZXIudjJCH0RhdGFSZXRlbnRpb25EZWxldGlvbkV2ZW50UHJvdG9QAVpK
Y2xvdWQuZ29vZ2xlLmNvbS9nby9zZWN1cml0eWNlbnRlci9hcGl2Mi9zZWN1cml0eWNlbnRl
cnBiO3NlY3VyaXR5Y2VudGVycGKqAh5Hb29nbGUuQ2xvdWQuU2VjdXJpdHlDZW50ZXIuVjLK
Ah5Hb29nbGVcQ2xvdWRcU2VjdXJpdHlDZW50ZXJcVjLqAiFHb29nbGU6OkNsb3VkOjpTZWN1
cml0eUNlbnRlcjo6VjJKyBQKBhIEDgBDAQq8BAoBDBIDDgASMrEEIENvcHlyaWdodCAyMDI1
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
ZW5zZS4KCggKAQISAxAAJwoJCgIDABIDEgAoCgkKAgMBEgMTACkKCAoBCBIDFQA7CgkKAggl
EgMVADsKCAoBCBIDFgBhCgkKAggLEgMWAGEKCAoBCBIDFwAiCgkKAggKEgMXACIKCAoBCBID
GABACgkKAggIEgMYAEAKCAoBCBIDGQA7CgkKAggBEgMZADsKCAoBCBIDGgA7CgkKAggpEgMa
ADsKCAoBCBIDGwA6CgkKAggtEgMbADoK/QQKAgQAEgQmAEMBGvAEIERldGFpbHMgYWJvdXQg
ZGF0YSByZXRlbnRpb24gZGVsZXRpb24gdmlvbGF0aW9ucywgaW4gd2hpY2ggdGhlIGRhdGEg
aXMKIG5vbi1jb21wbGlhbnQgYmFzZWQgb24gdGhlaXIgcmV0ZW50aW9uIG9yIGRlbGV0aW9u
IHRpbWUsIGFzIGRlZmluZWQgaW4gdGhlCiBhcHBsaWNhYmxlIGRhdGEgc2VjdXJpdHkgcG9s
aWN5LiBUaGUgRGF0YSBSZXRlbnRpb24gRGVsZXRpb24gKERSRCkgY29udHJvbCBpcwogYSBj
b250cm9sIG9mIHRoZSBEU1BNIChEYXRhIFNlY3VyaXR5IFBvc3R1cmUgTWFuYWdlbWVudCkg
c3VpdGUgdGhhdCBlbmFibGVzCiBvcmdhbml6YXRpb25zIHRvIG1hbmFnZSBkYXRhIHJldGVu
dGlvbiBhbmQgZGVsZXRpb24gcG9saWNpZXMgaW4gY29tcGxpYW5jZQogd2l0aCByZWd1bGF0
aW9ucywgc3VjaCBhcyBHRFBSIGFuZCBDUlBBLiBEUkQgc3VwcG9ydHMgdHdvIHByaW1hcnkg
cG9saWN5CiB0eXBlczogbWF4aW11bSBzdG9yYWdlIGxlbmd0aCAobWF4IFRUTCkgYW5kIG1p
bmltdW0gc3RvcmFnZSBsZW5ndGggKG1pbiBUVEwpLgogQm90aCBhcmUgYWltZWQgYXQgaGVs
cGluZyBvcmdhbml6YXRpb25zIG1lZXQgcmVndWxhdG9yeSBhbmQgZGF0YSBtYW5hZ2VtZW50
CiBjb21taXRtZW50cy4KCgoKAwQAARIDJggiCiYKBAQABAASBCgCLgMaGCBUeXBlIG9mIHRo
ZSBEUkQgZXZlbnQuCgoMCgUEAAQAARIDKAcQCigKBgQABAACABIDKgQfGhkgVW5zcGVjaWZp
ZWQgZXZlbnQgdHlwZS4KCg4KBwQABAACAAESAyoEGgoOCgcEAAQAAgACEgMqHR4KPgoGBAAE
AAIBEgMtBCQaLyBUaGUgbWF4aW11bSByZXRlbnRpb24gdGltZSBoYXMgYmVlbiBleGNlZWRl
ZC4KCg4KBwQABAACAQESAy0EHwoOCgcEAAQAAgECEgMtIiMKQAoEBAACABIDMQI1GjMgVGlt
ZXN0YW1wIGluZGljYXRpbmcgd2hlbiB0aGUgZXZlbnQgd2FzIGRldGVjdGVkLgoKDAoFBAAC
AAYSAzECGwoMCgUEAAIAARIDMRwwCgwKBQQAAgADEgMxMzQKnwIKBAQAAgESAzcCHhqRAiBO
dW1iZXIgb2Ygb2JqZWN0cyB0aGF0IHZpb2xhdGVkIHRoZSBwb2xpY3kgZm9yIHRoaXMgcmVz
b3VyY2UuIElmIHRoZSBudW1iZXIKIGlzIGxlc3MgdGhhbiAxLDAwMCwgdGhlbiB0aGUgdmFs
dWUgb2YgdGhpcyBmaWVsZCBpcyB0aGUgZXhhY3QgbnVtYmVyLiBJZgogdGhlIG51bWJlciBv
ZiBvYmplY3RzIHRoYXQgdmlvbGF0ZWQgdGhlIHBvbGljeSBpcyBncmVhdGVyIHRoYW4gb3Ig
ZXF1YWwgdG8KIDEsMDAwLCB0aGVuIHRoZSB2YWx1ZSBvZiB0aGlzIGZpZWxkIGlzIDEwMDAu
CgoMCgUEAAIBBRIDNwIHCgwKBQQAAgEBEgM3CBkKDAoFBAACAQMSAzccHQqsAwoEBAACAhID
PwI1Gp4DIE1heGltdW0gZHVyYXRpb24gb2YgcmV0ZW50aW9uIGFsbG93ZWQgZnJvbSB0aGUg
RFJEIGNvbnRyb2wuIFRoaXMgY29tZXMKIGZyb20gdGhlIERSRCBjb250cm9sIHdoZXJlIHVz
ZXJzIHNldCBhIG1heCBUVEwgZm9yIHRoZWlyIGRhdGEuIEZvciBleGFtcGxlLAogc3VwcG9z
ZSB0aGF0IGEgdXNlciBzZXRzIHRoZSBtYXggVFRMIGZvciBhIENsb3VkIFN0b3JhZ2UgYnVj
a2V0IHRvIDkwIGRheXMuCiBIb3dldmVyLCBhbiBvYmplY3QgaW4gdGhhdCBidWNrZXQgaXMg
MTAwIGRheXMgb2xkLiBJbiB0aGlzIGNhc2UsIGEKIERhdGFSZXRlbnRpb25EZWxldGlvbkV2
ZW50IHdpbGwgYmUgZ2VuZXJhdGVkIGZvciB0aGF0IENsb3VkIFN0b3JhZ2UgYnVja2V0LAog
YW5kIHRoZSBtYXhfcmV0ZW50aW9uX2FsbG93ZWQgaXMgOTAgZGF5cy4KCgwKBQQAAgIGEgM/
AhoKDAoFBAACAgESAz8bMAoMCgUEAAICAxIDPzM0CiUKBAQAAgMSA0ICGxoYIFR5cGUgb2Yg
dGhlIERSRCBldmVudC4KCgwKBQQAAgMGEgNCAgsKDAoFBAACAwESA0IMFgoMCgUEAAIDAxID
QhkaYgZwcm90bzM=
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Securitycenter::V2::DataRetentionDeletionEvent::DataRetentionDeletionEvent ===
    # Fields for DataRetentionDeletionEvent
    # Field: event_detection_time Type: 11 (.google.protobuf.Timestamp)
    # Field: data_object_count Type: 3 ()
    # Field: max_retention_allowed Type: 11 (.google.protobuf.Duration)
    # Field: event_type Type: 14 (.google.cloud.securitycenter.v2.DataRetentionDeletionEvent.EventType)

# Enum: DataRetentionDeletionEvent::EventType
our $DataRetentionDeletionEvent_EVENT_TYPE_UNSPECIFIED = 0;
our $DataRetentionDeletionEvent_EVENT_TYPE_MAX_TTL_EXCEEDED = 1;

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Securitycenter::V2::DataRetentionDeletionEvent - Compiled Protocol Buffers messages for google/cloud/securitycenter/v2/data_retention_deletion_event.proto

=head1 SYNOPSIS

    use Google::Cloud::Securitycenter::V2::DataRetentionDeletionEvent;

    my $msg = Google::Cloud::Securitycenter::V2::DataRetentionDeletionEvent::DataRetentionDeletionEvent->new({
        event_detection_time => $event_detection_time,
        data_object_count => $data_object_count,
        max_retention_allowed => $max_retention_allowed,
        event_type => $event_type,
    });

    # Read or update a field
    my $val = $msg->event_detection_time();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Securitycenter::V2::DataRetentionDeletionEvent::DataRetentionDeletionEvent->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/securitycenter/v2/data_retention_deletion_event.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Securitycenter::V2::DataRetentionDeletionEvent::DataRetentionDeletionEvent

Details about data retention deletion violations, in which the data is
non-compliant based on their retention or deletion time, as defined in the
applicable data security policy. The Data Retention Deletion (DRD) control is
a control of the DSPM (Data Security Posture Management) suite that enables
organizations to manage data retention and deletion policies in compliance
with regulations, such as GDPR and CRPA. DRD supports two primary policy
types: maximum storage length (max TTL) and minimum storage length (min TTL).
Both are aimed at helping organizations meet regulatory and data management
commitments.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->event_detection_time() >> / C<< $msg->event_detection_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Timestamp indicating when the event was detected.

=item * C<< $msg->data_object_count() >> / C<< $msg->data_object_count($value) >>

Type: C<Int64>

Number of objects that violated the policy for this resource. If the number
is less than 1,000, then the value of this field is the exact number. If
the number of objects that violated the policy is greater than or equal to
1,000, then the value of this field is 1000.

=item * C<< $msg->max_retention_allowed() >> / C<< $msg->max_retention_allowed($value) >>

Type: C<Message> (L<Google::Protobuf::Duration::Duration>)

Maximum duration of retention allowed from the DRD control. This comes
from the DRD control where users set a max TTL for their data. For example,
suppose that a user sets the max TTL for a Cloud Storage bucket to 90 days.
However, an object in that bucket is 100 days old. In this case, a
DataRetentionDeletionEvent will be generated for that Cloud Storage bucket,
and the max_retention_allowed is 90 days.

=item * C<< $msg->event_type() >> / C<< $msg->event_type($value) >>

Type: C<Enum> (L<Google::Cloud::Securitycenter::V2::DataRetentionDeletionEvent::EventType>)

Type of the DRD event.

=back

=head3 Enum: DataRetentionDeletionEvent::EventType

=over 4

=item * C<EVENT_TYPE_UNSPECIFIED> => C<0>

=item * C<EVENT_TYPE_MAX_TTL_EXCEEDED> => C<1>

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Securitycenter::V2::DataRetentionDeletionEvent::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
