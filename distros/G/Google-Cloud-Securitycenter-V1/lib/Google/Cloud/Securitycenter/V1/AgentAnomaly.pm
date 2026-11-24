package Google::Cloud::Securitycenter::V1::AgentAnomaly;

use strict;
use warnings;

our $VERSION = '0.14';

use Protobuf::Message;
use Protobuf::DescriptorPool;
use Protobuf::Internal qw(:all);
use MIME::Base64;

BEGIN {
    my $descriptor_b64 = <<'EOF';
CjJnb29nbGUvY2xvdWQvc2VjdXJpdHljZW50ZXIvdjEvYWdlbnRfYW5vbWFseS5wcm90bxIe
Z29vZ2xlLmNsb3VkLnNlY3VyaXR5Y2VudGVyLnYxIocCCgxBZ2VudEFub21hbHkSKQoQY29u
ZmlkZW5jZV9zY29yZRgBIAEoAVIPY29uZmlkZW5jZVNjb3JlEmIKE2RldGVjdG9yX3JlZmVy
ZW5jZXMYAiADKAsyMS5nb29nbGUuY2xvdWQuc2VjdXJpdHljZW50ZXIudjEuRGV0ZWN0b3JS
ZWZlcmVuY2VSEmRldGVjdG9yUmVmZXJlbmNlcxJoChVpbnZvY2F0aW9uX3JlZmVyZW5jZXMY
AyADKAsyMy5nb29nbGUuY2xvdWQuc2VjdXJpdHljZW50ZXIudjEuSW52b2NhdGlvblJlZmVy
ZW5jZVIUaW52b2NhdGlvblJlZmVyZW5jZXMizAIKEURldGVjdG9yUmVmZXJlbmNlElYKCHNl
dmVyaXR5GAEgASgOMjouZ29vZ2xlLmNsb3VkLnNlY3VyaXR5Y2VudGVyLnYxLkRldGVjdG9y
UmVmZXJlbmNlLlNldmVyaXR5UghzZXZlcml0eRIfCgtkZXRlY3Rvcl9pZBgCIAEoCVIKZGV0
ZWN0b3JJZBIhCgxkaXNwbGF5X25hbWUYAyABKAlSC2Rpc3BsYXlOYW1lEiAKC2V4cGxhbmF0
aW9uGAQgASgJUgtleHBsYW5hdGlvbhImCg5yZWNvbW1lbmRhdGlvbhgFIAEoCVIOcmVjb21t
ZW5kYXRpb24iUQoIU2V2ZXJpdHkSGAoUU0VWRVJJVFlfVU5TUEVDSUZJRUQQABIMCghDUklU
SUNBTBABEggKBEhJR0gQAhIKCgZNRURJVU0QAxIHCgNMT1cQBCI6ChNJbnZvY2F0aW9uUmVm
ZXJlbmNlEiMKDWludm9jYXRpb25faWQYASABKAlSDGludm9jYXRpb25JZELrAQoiY29tLmdv
b2dsZS5jbG91ZC5zZWN1cml0eWNlbnRlci52MUIRQWdlbnRBbm9tYWx5UHJvdG9QAVpKY2xv
dWQuZ29vZ2xlLmNvbS9nby9zZWN1cml0eWNlbnRlci9hcGl2MS9zZWN1cml0eWNlbnRlcnBi
O3NlY3VyaXR5Y2VudGVycGKqAh5Hb29nbGUuQ2xvdWQuU2VjdXJpdHlDZW50ZXIuVjHKAh5H
b29nbGVcQ2xvdWRcU2VjdXJpdHlDZW50ZXJcVjHqAiFHb29nbGU6OkNsb3VkOjpTZWN1cml0
eUNlbnRlcjo6VjFKiBcKBhIEDgBXAQq8BAoBDBIDDgASMrEEIENvcHlyaWdodCAyMDI2IEdv
b2dsZSBMTEMKCiBMaWNlbnNlZCB1bmRlciB0aGUgQXBhY2hlIExpY2Vuc2UsIFZlcnNpb24g
Mi4wICh0aGUgIkxpY2Vuc2UiKTsKIHlvdSBtYXkgbm90IHVzZSB0aGlzIGZpbGUgZXhjZXB0
IGluIGNvbXBsaWFuY2Ugd2l0aCB0aGUgTGljZW5zZS4KIFlvdSBtYXkgb2J0YWluIGEgY29w
eSBvZiB0aGUgTGljZW5zZSBhdAoKICAgICBodHRwOi8vd3d3LmFwYWNoZS5vcmcvbGljZW5z
ZXMvTElDRU5TRS0yLjAKCiBVbmxlc3MgcmVxdWlyZWQgYnkgYXBwbGljYWJsZSBsYXcgb3Ig
YWdyZWVkIHRvIGluIHdyaXRpbmcsIHNvZnR3YXJlCiBkaXN0cmlidXRlZCB1bmRlciB0aGUg
TGljZW5zZSBpcyBkaXN0cmlidXRlZCBvbiBhbiAiQVMgSVMiIEJBU0lTLAogV0lUSE9VVCBX
QVJSQU5USUVTIE9SIENPTkRJVElPTlMgT0YgQU5ZIEtJTkQsIGVpdGhlciBleHByZXNzIG9y
IGltcGxpZWQuCiBTZWUgdGhlIExpY2Vuc2UgZm9yIHRoZSBzcGVjaWZpYyBsYW5ndWFnZSBn
b3Zlcm5pbmcgcGVybWlzc2lvbnMgYW5kCiBsaW1pdGF0aW9ucyB1bmRlciB0aGUgTGljZW5z
ZS4KCggKAQISAxAAJwoICgEIEgMSADsKCQoCCCUSAxIAOwoICgEIEgMTAGEKCQoCCAsSAxMA
YQoICgEIEgMUACIKCQoCCAoSAxQAIgoICgEIEgMVADIKCQoCCAgSAxUAMgoICgEIEgMWADsK
CQoCCAESAxYAOwoICgEIEgMXADsKCQoCCCkSAxcAOwoICgEIEgMYADoKCQoCCC0SAxgAOgpV
CgIEABIEGwAoARpJIFJlcHJlc2VudHMgZGV0YWlscyBhYm91dCBhbiBhbm9tYWx5IGRldGVj
dGVkIGluIGFuIEFJIGFnZW50J3MgYmVoYXZpb3IuCgoKCgMEAAESAxsIFAr5AQoEBAACABID
IAIeGusBIFRoZSBvdmVyYWxsIGNvbmZpZGVuY2Ugc2NvcmUgaW5kaWNhdGluZyB0aGUgbGlr
ZWxpaG9vZCB0aGF0IHRoaXMgc2Vzc2lvbgogY29udGFpbnMgYSB0cnVlIGFub21hbHkuIFRo
ZSBzY29yZSByYW5nZXMgZnJvbSAwLjAgdG8gMS4wLCB3aGVyZSAxLjAKIHNpZ25pZmllcyAx
MDAlIGNvbmZpZGVuY2UgaW4gdGhlIHByZXNlbmNlIG9mIGFuIGFub21hbHkgYW5kIDAuMCBz
aWduaWZpZXMKIDAlIGNvbmZpZGVuY2UuCgoMCgUEAAIABRIDIAIICgwKBQQAAgABEgMgCRkK
DAoFBAACAAMSAyAcHQprCgQEAAIBEgMkAjUaXiBUaGUgbGlzdCBvZiByZWZlcmVuY2VzIHRv
IHNwZWNpZmljIGRldGVjdG9ycyB0aGF0IGlkZW50aWZpZWQgYW5vbWFsaWVzCiB3aXRoaW4g
dGhpcyBzZXNzaW9uLgoKDAoFBAACAQQSAyQCCgoMCgUEAAIBBhIDJAscCgwKBQQAAgEBEgMk
HTAKDAoFBAACAQMSAyQzNAo7CgQEAAICEgMnAjkaLiBSZWZlcmVuY2VzIHRvIHRoZSBPcGVu
VGVsZW1ldHJ5IGludm9jYXRpb25zLgoKDAoFBAACAgQSAycCCgoMCgUEAAICBhIDJwseCgwK
BQQAAgIBEgMnHzQKDAoFBAACAgMSAyc3OApECgIEARIEKwBRARo4IFJlcHJlc2VudHMgYSBy
ZWZlcmVuY2UgdG8gYSBzcGVjaWZpYyBhbm9tYWx5IGRldGVjdG9yLgoKCgoDBAEBEgMrCBkK
LgoEBAEEABIELQI8AxogIFNldmVyaXR5IGxldmVscyBmb3IgZGV0ZWN0b3JzLgoKDAoFBAEE
AAESAy0HDwomCgYEAQQAAgASAy8EHRoXIFVuc3BlY2lmaWVkIHNldmVyaXR5LgoKDgoHBAEE
AAIAARIDLwQYCg4KBwQBBAACAAISAy8bHAojCgYEAQQAAgESAzIEERoUIENyaXRpY2FsIHNl
dmVyaXR5LgoKDgoHBAEEAAIBARIDMgQMCg4KBwQBBAACAQISAzIPEAofCgYEAQQAAgISAzUE
DRoQIEhpZ2ggc2V2ZXJpdHkuCgoOCgcEAQQAAgIBEgM1BAgKDgoHBAEEAAICAhIDNQsMCiEK
BgQBBAACAxIDOAQPGhIgTWVkaXVtIHNldmVyaXR5LgoKDgoHBAEEAAIDARIDOAQKCg4KBwQB
BAACAwISAzgNDgoeCgYEAQQAAgQSAzsEDBoPIExvdyBzZXZlcml0eS4KCg4KBwQBBAACBAES
AzsEBwoOCgcEAQQAAgQCEgM7CgsKLAoEBAECABIDPwIYGh8gVGhlIHNldmVyaXR5IG9mIHRo
ZSBkZXRlY3Rvci4KCgwKBQQBAgAGEgM/AgoKDAoFBAECAAESAz8LEwoMCgUEAQIAAxIDPxYX
CjUKBAQBAgESA0ICGRooIFRoZSB1bmlxdWUgaWRlbnRpZmllciBvZiB0aGUgZGV0ZWN0b3Iu
CgoMCgUEAQIBBRIDQgIICgwKBQQBAgEBEgNCCRQKDAoFBAECAQMSA0IXGAqXAQoEBAECAhID
RgIaGokBIEEgaHVtYW4gcmVhZGFibGUgbmFtZSBmb3IgdGhlIGRldGVjdG9yLCBwcm92aWRp
bmcgY29udGV4dCBvbiBpdHMgcHVycG9zZS4KIEZvciBleGFtcGxlLCAiQVNJMDI6IFRvb2wg
TWlzdXNlIiwgb3IgIkV4Y2Vzc2l2ZSBBUEkgQ2FsbHMiLgoKDAoFBAECAgUSA0YCCAoMCgUE
AQICARIDRgkVCgwKBQQBAgIDEgNGGBkKvQEKBAQBAgMSA0sCGRqvASBBIGRldGFpbGVkIGV4
cGxhbmF0aW9uIGdlbmVyYXRlZCBieSBhbiBMTE0gb3IgdGhlIGRldGVjdG9yIGl0c2VsZiwK
IGRlc2NyaWJpbmcgd2h5IHRoaXMgc3BlY2lmaWMgYW5vbWFseSB3YXMgZmxhZ2dlZC4gVGhp
cyBwcm92aWRlcyByYXRpb25hbGUKIGFuZCBjb250ZXh0IGZvciB0aGUgZGV0ZWN0aW9uLgoK
DAoFBAECAwUSA0sCCAoMCgUEAQIDARIDSwkUCgwKBQQBAgMDEgNLFxgKzwEKBAQBAgQSA1AC
HBrBASBSZWNvbW1lbmRlZCBzdGVwcyBvciBhY3Rpb25zIHRvIHJlbWVkaWF0ZSBvciBpbnZl
c3RpZ2F0ZSB0aGUgYW5vbWFseQogZmxhZ2dlZCBieSB0aGlzIGRldGVjdG9yLiBUaGVzZSBj
b3VsZCBpbmNsdWRlIGNvbmZpZ3VyYXRpb24gY2hhbmdlcywgY29kZQogYWRqdXN0bWVudHMs
IG9yIGZ1cnRoZXIgZGlhZ25vc3RpYyBwcm9jZWR1cmVzLgoKDAoFBAECBAUSA1ACCAoMCgUE
AQIEARIDUAkXCgwKBQQBAgQDEgNQGhsKTAoCBAISBFQAVwEaQCBSZXByZXNlbnRzIGEgcmVm
ZXJlbmNlIHRvIGEgc3BlY2lmaWMgT3BlblRlbGVtZXRyeSBpbnZvY2F0aW9uLgoKCgoDBAIB
EgNUCBsKNwoEBAICABIDVgIbGiogVGhlIHVuaXF1ZSBpZGVudGlmaWVyIG9mIHRoZSBpbnZv
Y2F0aW9uLgoKDAoFBAICAAUSA1YCCAoMCgUEAgIAARIDVgkWCgwKBQQCAgADEgNWGRpiBnBy
b3RvMw==
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Securitycenter::V1::AgentAnomaly::AgentAnomaly ===
    # Fields for AgentAnomaly
    # Field: confidence_score Type: 1 ()
    # Field: detector_references Type: 11 (.google.cloud.securitycenter.v1.DetectorReference)
    # Field: invocation_references Type: 11 (.google.cloud.securitycenter.v1.InvocationReference)

# === Message: Google::Cloud::Securitycenter::V1::AgentAnomaly::DetectorReference ===
    # Fields for DetectorReference
    # Field: severity Type: 14 (.google.cloud.securitycenter.v1.DetectorReference.Severity)
    # Field: detector_id Type: 9 ()
    # Field: display_name Type: 9 ()
    # Field: explanation Type: 9 ()
    # Field: recommendation Type: 9 ()

# Enum: DetectorReference::Severity
our $DetectorReference_SEVERITY_UNSPECIFIED = 0;
our $DetectorReference_CRITICAL = 1;
our $DetectorReference_HIGH = 2;
our $DetectorReference_MEDIUM = 3;
our $DetectorReference_LOW = 4;

# === Message: Google::Cloud::Securitycenter::V1::AgentAnomaly::InvocationReference ===
    # Fields for InvocationReference
    # Field: invocation_id Type: 9 ()

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Securitycenter::V1::AgentAnomaly - Compiled Protocol Buffers messages for google/cloud/securitycenter/v1/agent_anomaly.proto

=head1 SYNOPSIS

    use Google::Cloud::Securitycenter::V1::AgentAnomaly;

    my $msg = Google::Cloud::Securitycenter::V1::AgentAnomaly::AgentAnomaly->new({
        confidence_score => $confidence_score,
        detector_references => $detector_references,
        invocation_references => $invocation_references,
    });

    # Read or update a field
    my $val = $msg->confidence_score();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Securitycenter::V1::AgentAnomaly::AgentAnomaly->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/securitycenter/v1/agent_anomaly.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Securitycenter::V1::AgentAnomaly::AgentAnomaly

Represents details about an anomaly detected in an AI agent's behavior.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->confidence_score() >> / C<< $msg->confidence_score($value) >>

Type: C<Double>

The overall confidence score indicating the likelihood that this session
contains a true anomaly. The score ranges from 0.0 to 1.0, where 1.0
signifies 100% confidence in the presence of an anomaly and 0.0 signifies
0% confidence.

=item * C<< $msg->detector_references() >> / C<< $msg->detector_references($value) >>

Type: C<Message> (L<Google::Cloud::Securitycenter::V1::AgentAnomaly::DetectorReference>)

The list of references to specific detectors that identified anomalies
within this session.

=item * C<< $msg->invocation_references() >> / C<< $msg->invocation_references($value) >>

Type: C<Message> (L<Google::Cloud::Securitycenter::V1::AgentAnomaly::InvocationReference>)

References to the OpenTelemetry invocations.

=back

=head2 Google::Cloud::Securitycenter::V1::AgentAnomaly::DetectorReference

Represents a reference to a specific anomaly detector.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->severity() >> / C<< $msg->severity($value) >>

Type: C<Enum> (L<Google::Cloud::Securitycenter::V1::DetectorReference::Severity>)

The severity of the detector.

=item * C<< $msg->detector_id() >> / C<< $msg->detector_id($value) >>

Type: C<String>

The unique identifier of the detector.

=item * C<< $msg->display_name() >> / C<< $msg->display_name($value) >>

Type: C<String>

A human readable name for the detector, providing context on its purpose.
For example, "ASI02: Tool Misuse", or "Excessive API Calls".

=item * C<< $msg->explanation() >> / C<< $msg->explanation($value) >>

Type: C<String>

A detailed explanation generated by an LLM or the detector itself,
describing why this specific anomaly was flagged. This provides rationale
and context for the detection.

=item * C<< $msg->recommendation() >> / C<< $msg->recommendation($value) >>

Type: C<String>

Recommended steps or actions to remediate or investigate the anomaly
flagged by this detector. These could include configuration changes, code
adjustments, or further diagnostic procedures.

=back

=head3 Enum: DetectorReference::Severity

=over 4

=item * C<SEVERITY_UNSPECIFIED> => C<0>

=item * C<CRITICAL> => C<1>

=item * C<HIGH> => C<2>

=item * C<MEDIUM> => C<3>

=item * C<LOW> => C<4>

=back

=head2 Google::Cloud::Securitycenter::V1::AgentAnomaly::InvocationReference

Represents a reference to a specific OpenTelemetry invocation.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->invocation_id() >> / C<< $msg->invocation_id($value) >>

Type: C<String>

The unique identifier of the invocation.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Securitycenter::V1::AgentAnomaly::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
