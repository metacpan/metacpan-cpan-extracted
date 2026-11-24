package Google::Cloud::Eventarc::Publishing::V1::CloudEvent;

use strict;
use warnings;

our $VERSION = '0.14';

use Protobuf::Message;
use Protobuf::DescriptorPool;
use Protobuf::Internal qw(:all);
use MIME::Base64;

BEGIN {
    eval { require Google::Api::FieldBehavior };
    eval { require Google::Protobuf::Any };
    eval { require Google::Protobuf::Timestamp };
    my $descriptor_b64 = <<'EOF';
CjVnb29nbGUvY2xvdWQvZXZlbnRhcmMvcHVibGlzaGluZy92MS9jbG91ZF9ldmVudC5wcm90
bxIjZ29vZ2xlLmNsb3VkLmV2ZW50YXJjLnB1Ymxpc2hpbmcudjEaH2dvb2dsZS9hcGkvZmll
bGRfYmVoYXZpb3IucHJvdG8aGWdvb2dsZS9wcm90b2J1Zi9hbnkucHJvdG8aH2dvb2dsZS9w
cm90b2J1Zi90aW1lc3RhbXAucHJvdG8inAYKCkNsb3VkRXZlbnQSEwoCaWQYASABKAlCA+BB
AlICaWQSGwoGc291cmNlGAIgASgJQgPgQQJSBnNvdXJjZRImCgxzcGVjX3ZlcnNpb24YAyAB
KAlCA+BBAlILc3BlY1ZlcnNpb24SFwoEdHlwZRgEIAEoCUID4EECUgR0eXBlEmQKCmF0dHJp
YnV0ZXMYBSADKAsyPy5nb29nbGUuY2xvdWQuZXZlbnRhcmMucHVibGlzaGluZy52MS5DbG91
ZEV2ZW50LkF0dHJpYnV0ZXNFbnRyeUID4EEBUgphdHRyaWJ1dGVzEiYKC2JpbmFyeV9kYXRh
GAYgASgMQgPgQQFIAFIKYmluYXJ5RGF0YRIiCgl0ZXh0X2RhdGEYByABKAlCA+BBAUgAUgh0
ZXh0RGF0YRI6Cgpwcm90b19kYXRhGAggASgLMhQuZ29vZ2xlLnByb3RvYnVmLkFueUID4EEB
SABSCXByb3RvRGF0YRqaAgoYQ2xvdWRFdmVudEF0dHJpYnV0ZVZhbHVlEh8KCmNlX2Jvb2xl
YW4YASABKAhIAFIJY2VCb29sZWFuEh8KCmNlX2ludGVnZXIYAiABKAVIAFIJY2VJbnRlZ2Vy
Eh0KCWNlX3N0cmluZxgDIAEoCUgAUghjZVN0cmluZxIbCghjZV9ieXRlcxgEIAEoDEgAUgdj
ZUJ5dGVzEhcKBmNlX3VyaRgFIAEoCUgAUgVjZVVyaRIeCgpjZV91cmlfcmVmGAYgASgJSABS
CGNlVXJpUmVmEj8KDGNlX3RpbWVzdGFtcBgHIAEoCzIaLmdvb2dsZS5wcm90b2J1Zi5UaW1l
c3RhbXBIAFILY2VUaW1lc3RhbXBCBgoEYXR0chqHAQoPQXR0cmlidXRlc0VudHJ5EhAKA2tl
eRgBIAEoCVIDa2V5El4KBXZhbHVlGAIgASgLMkguZ29vZ2xlLmNsb3VkLmV2ZW50YXJjLnB1
Ymxpc2hpbmcudjEuQ2xvdWRFdmVudC5DbG91ZEV2ZW50QXR0cmlidXRlVmFsdWVSBXZhbHVl
OgI4AUIGCgRkYXRhQvsBCidjb20uZ29vZ2xlLmNsb3VkLmV2ZW50YXJjLnB1Ymxpc2hpbmcu
djFCD0Nsb3VkRXZlbnRQcm90b1ABWkdjbG91ZC5nb29nbGUuY29tL2dvL2V2ZW50YXJjL3B1
Ymxpc2hpbmcvYXBpdjEvcHVibGlzaGluZ3BiO3B1Ymxpc2hpbmdwYqoCI0dvb2dsZS5DbG91
ZC5FdmVudGFyYy5QdWJsaXNoaW5nLlYxygIjR29vZ2xlXENsb3VkXEV2ZW50YXJjXFB1Ymxp
c2hpbmdcVjHqAidHb29nbGU6OkNsb3VkOjpFdmVudGFyYzo6UHVibGlzaGluZzo6VjFKwxoK
BhIEDgBkAQq8BAoBDBIDDgASMrEEIENvcHlyaWdodCAyMDI2IEdvb2dsZSBMTEMKCiBMaWNl
bnNlZCB1bmRlciB0aGUgQXBhY2hlIExpY2Vuc2UsIFZlcnNpb24gMi4wICh0aGUgIkxpY2Vu
c2UiKTsKIHlvdSBtYXkgbm90IHVzZSB0aGlzIGZpbGUgZXhjZXB0IGluIGNvbXBsaWFuY2Ug
d2l0aCB0aGUgTGljZW5zZS4KIFlvdSBtYXkgb2J0YWluIGEgY29weSBvZiB0aGUgTGljZW5z
ZSBhdAoKICAgICBodHRwOi8vd3d3LmFwYWNoZS5vcmcvbGljZW5zZXMvTElDRU5TRS0yLjAK
CiBVbmxlc3MgcmVxdWlyZWQgYnkgYXBwbGljYWJsZSBsYXcgb3IgYWdyZWVkIHRvIGluIHdy
aXRpbmcsIHNvZnR3YXJlCiBkaXN0cmlidXRlZCB1bmRlciB0aGUgTGljZW5zZSBpcyBkaXN0
cmlidXRlZCBvbiBhbiAiQVMgSVMiIEJBU0lTLAogV0lUSE9VVCBXQVJSQU5USUVTIE9SIENP
TkRJVElPTlMgT0YgQU5ZIEtJTkQsIGVpdGhlciBleHByZXNzIG9yIGltcGxpZWQuCiBTZWUg
dGhlIExpY2Vuc2UgZm9yIHRoZSBzcGVjaWZpYyBsYW5ndWFnZSBnb3Zlcm5pbmcgcGVybWlz
c2lvbnMgYW5kCiBsaW1pdGF0aW9ucyB1bmRlciB0aGUgTGljZW5zZS4KCggKAQISAxAALAoJ
CgIDABIDEgApCgkKAgMBEgMTACMKCQoCAwISAxQAKQoICgEIEgMWAEAKCQoCCCUSAxYAQAoI
CgEIEgMXAF4KCQoCCAsSAxcAXgoICgEIEgMYACIKCQoCCAoSAxgAIgoICgEIEgMZADAKCQoC
CAgSAxkAMAoICgEIEgMaAEAKCQoCCAESAxoAQAoICgEIEgMbAEEKCQoCCCkSAxsAQQoICgEI
EgMcAEAKCQoCCC0SAxwAQApqCgIEABIEIABkARpeIENsb3VkRXZlbnQgcmVwcmVzZW50cyBh
IHZlbmRvci1uZXV0cmFsIHNwZWNpZmljYXRpb24gZm9yIGRlZmluaW5nIHRoZSBmb3JtYXQK
IG9mIGV2ZW50IGRhdGEuCgoKCgMEAAESAyAIEgpWCgQEAAMAEgQiAjoDGkggVGhlIGZvbGxv
d2luZyBhYnN0cmFjdCBkYXRhIHR5cGVzIGFyZSBhdmFpbGFibGUgZm9yIHVzZSBpbiBhdHRy
aWJ1dGVzLgoKDAoFBAADAAESAyIKIgotCgYEAAMACAASBCQEOQUaHSBUaGUgdmFsdWUgb2Yg
dGhlIGF0dHJpYnV0ZS4KCg4KBwQAAwAIAAESAyQKDgofCgYEAAMAAgASAyYGGhoQIEJvb2xl
YW4gdmFsdWUuCgoOCgcEAAMAAgAFEgMmBgoKDgoHBAADAAIAARIDJgsVCg4KBwQAAwACAAMS
AyYYGQofCgYEAAMAAgESAykGGxoQIEludGVnZXIgdmFsdWUuCgoOCgcEAAMAAgEFEgMpBgsK
DgoHBAADAAIBARIDKQwWCg4KBwQAAwACAQMSAykZGgoeCgYEAAMAAgISAywGGxoPIFN0cmlu
ZyB2YWx1ZS4KCg4KBwQAAwACAgUSAywGDAoOCgcEAAMAAgIBEgMsDRYKDgoHBAADAAICAxID
LBkaCh0KBgQAAwACAxIDLwYZGg4gQnl0ZXMgdmFsdWUuCgoOCgcEAAMAAgMFEgMvBgsKDgoH
BAADAAIDARIDLwwUCg4KBwQAAwACAwMSAy8XGAobCgYEAAMAAgQSAzIGGBoMIFVSSSB2YWx1
ZS4KCg4KBwQAAwACBAUSAzIGDAoOCgcEAAMAAgQBEgMyDRMKDgoHBAADAAIEAxIDMhYXCiUK
BgQAAwACBRIDNQYcGhYgVVJJLXJlZmVyZW5jZSB2YWx1ZS4KCg4KBwQAAwACBQUSAzUGDAoO
CgcEAAMAAgUBEgM1DRcKDgoHBAADAAIFAxIDNRobCiEKBgQAAwACBhIDOAYxGhIgVGltZXN0
YW1wIHZhbHVlLgoKDgoHBAADAAIGBhIDOAYfCg4KBwQAAwACBgESAzggLAoOCgcEAAMAAgYD
EgM4LzAKeQoEBAACABIDPgI5GmwgUmVxdWlyZWQuIElkZW50aWZpZXMgdGhlIGV2ZW50LiBQ
cm9kdWNlcnMgTVVTVCBlbnN1cmUgdGhhdCBzb3VyY2UgKyBpZCBpcwogdW5pcXVlIGZvciBl
YWNoIGRpc3RpbmN0IGV2ZW50LgoKDAoFBAACAAUSAz4CCAoMCgUEAAIAARIDPgkLCgwKBQQA
AgADEgM+Dg8KDAoFBAACAAgSAz4QOAoPCggEAAIACJwIABIDPhE3CloKBAQAAgESA0ICPRpN
IFJlcXVpcmVkLiBJZGVudGlmaWVzIHRoZSBjb250ZXh0IGluIHdoaWNoIGFuIGV2ZW50IGhh
cHBlbmVkLgogVVJJLXJlZmVyZW5jZQoKDAoFBAACAQUSA0ICCAoMCgUEAAIBARIDQgkPCgwK
BQQAAgEDEgNCEhMKDAoFBAACAQgSA0IUPAoPCggEAAIBCJwIABIDQhU7ClwKBAQAAgISA0YC
QxpPIFJlcXVpcmVkLiBUaGUgdmVyc2lvbiBvZiB0aGUgQ2xvdWRFdmVudHMgc3BlY2lmaWNh
dGlvbiB3aGljaCB0aGUgZXZlbnQKIHVzZXMuCgoMCgUEAAICBRIDRgIICgwKBQQAAgIBEgNG
CRUKDAoFBAACAgMSA0YYGQoMCgUEAAICCBIDRhpCCg8KCAQAAgIInAgAEgNGG0EKfQoEBAAC
AxIDSgI7GnAgUmVxdWlyZWQuIFRoaXMgYXR0cmlidXRlIGNvbnRhaW5zIGEgdmFsdWUgZGVz
Y3JpYmluZyB0aGUgdHlwZSBvZiBldmVudAogcmVsYXRlZCB0byB0aGUgb3JpZ2luYXRpbmcg
b2NjdXJyZW5jZS4KCgwKBQQAAgMFEgNKAggKDAoFBAACAwESA0oJDQoMCgUEAAIDAxIDShAR
CgwKBQQAAgMIEgNKEjoKDwoIBAACAwicCAASA0oTOQpCCgQEAAIEEgRNAk4vGjQgT3B0aW9u
YWwuIFVzZWQgZm9yIE9wdGlvbmFsICYgRXh0ZW5zaW9uIEF0dHJpYnV0ZXMKCgwKBQQAAgQG
EgNNAicKDAoFBAACBAESA00oMgoMCgUEAAIEAxIDTTU2CgwKBQQAAgQIEgNOBi4KDwoIBAAC
BAicCAASA04HLQrxAQoEBAAIABIEVAJjAxriASBUaGUgZXZlbnQgcGF5bG9hZC4gSXQgc2hv
dWxkIGJlIGVuY29kZWQgaW50byBhIG1lZGlhIGZvcm1hdCB3aGljaCBpcwogc3BlY2lmaWVk
IGJ5IHRoZSAnZGF0YWNvbnRlbnR0eXBlJyBhdHRyaWJ1dGUgKGUuZy4gYXBwbGljYXRpb24v
anNvbiksIGFuZAogYWRoZXJlcyB0byB0aGUgZGF0YXNjaGVtYSBmb3JtYXQgd2hlbiB0aG9z
ZSByZXNwZWN0aXZlIGF0dHJpYnV0ZXMgYXJlCiBwcmVzZW50LgoKDAoFBAAIAAESA1QIDAol
CgQEAAIFEgNWBEMaGCBPcHRpb25hbC4gQmluYXJ5IGRhdGEuCgoMCgUEAAIFBRIDVgQJCgwK
BQQAAgUBEgNWChUKDAoFBAACBQMSA1YYGQoMCgUEAAIFCBIDVhpCCg8KCAQAAgUInAgAEgNW
G0EKIwoEBAACBhIDWQRCGhYgT3B0aW9uYWwuIFRleHQgZGF0YS4KCgwKBQQAAgYFEgNZBAoK
DAoFBAACBgESA1kLFAoMCgUEAAIGAxIDWRcYCgwKBQQAAgYIEgNZGUEKDwoIBAACBgicCAAS
A1kaQArYAgoEBAACBxIDYgRQGsoCIE9wdGlvbmFsLiBQcm90byBkYXRhLgoKIE5PVEU6IFRo
ZSBgcHJvdG9EYXRhYCBmaWVsZCBvbmx5IGZ1bmN0aW9ucyBhcyBleHBlY3RlZCB3aGVuIHRo
ZSBwYXlsb2FkCiBpcyBzcGVjaWZpY2FsbHkgYSBgQ2xvdWRFdmVudGAgbWVzc2FnZSB0eXBl
LCBhbmQgY2FuJ3QgYmUgdXNlZCBmb3IKIGFyYml0cmFyeSBwcm90b2NvbCBidWZmZXIgbWVz
c2FnZXMuIEZvciBhbnkgb3RoZXIgcHJvdG9jb2wgYnVmZmVyIHR5cGUsCiB5b3UgbXVzdCBz
ZXJpYWxpemUgeW91ciBwcm90byBtZXNzYWdlIGludG8gYnl0ZXMsIGFuZCB1c2UgdGhlCiBg
YmluYXJ5RGF0YWAgZmllbGQgaW5zdGVhZC4KCgwKBQQAAgcGEgNiBBcKDAoFBAACBwESA2IY
IgoMCgUEAAIHAxIDYiUmCgwKBQQAAgcIEgNiJ08KDwoIBAACBwicCAASA2IoTmIGcHJvdG8z

EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Eventarc::Publishing::V1::CloudEvent::CloudEvent ===
    # Fields for CloudEvent
    # Field: id Type: 9 ()
    # Field: source Type: 9 ()
    # Field: spec_version Type: 9 ()
    # Field: type Type: 9 ()
    # Field: attributes Type: 11 (.google.cloud.eventarc.publishing.v1.CloudEvent.AttributesEntry)
    # Field: binary_data Type: 12 ()
    # Field: text_data Type: 9 ()
    # Field: proto_data Type: 11 (.google.protobuf.Any)

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Eventarc::Publishing::V1::CloudEvent - Compiled Protocol Buffers messages for google/cloud/eventarc/publishing/v1/cloud_event.proto

=head1 SYNOPSIS

    use Google::Cloud::Eventarc::Publishing::V1::CloudEvent;

    my $msg = Google::Cloud::Eventarc::Publishing::V1::CloudEvent::CloudEvent->new({
        id => $id,
        source => $source,
        spec_version => $spec_version,
        type => $type,
    });

    # Read or update a field
    my $val = $msg->id();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Eventarc::Publishing::V1::CloudEvent::CloudEvent->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/eventarc/publishing/v1/cloud_event.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Eventarc::Publishing::V1::CloudEvent::CloudEvent

CloudEvent represents a vendor-neutral specification for defining the format
of event data.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->id() >> / C<< $msg->id($value) >>

Type: C<String>

Required. Identifies the event. Producers MUST ensure that source + id is
unique for each distinct event.

=item * C<< $msg->source() >> / C<< $msg->source($value) >>

Type: C<String>

Required. Identifies the context in which an event happened.
URI-reference

=item * C<< $msg->spec_version() >> / C<< $msg->spec_version($value) >>

Type: C<String>

Required. The version of the CloudEvents specification which the event
uses.

=item * C<< $msg->type() >> / C<< $msg->type($value) >>

Type: C<String>

Required. This attribute contains a value describing the type of event
related to the originating occurrence.

=item * C<< $msg->attributes() >> / C<< $msg->attributes($value) >>

Type: C<Message> (L<Google::Cloud::Eventarc::Publishing::V1::CloudEvent::CloudEvent::AttributesEntry>)

Optional. Used for Optional & Extension Attributes

=item * C<< $msg->binary_data() >> / C<< $msg->binary_data($value) >>

Type: C<Bytes>

Optional. Binary data.

=item * C<< $msg->text_data() >> / C<< $msg->text_data($value) >>

Type: C<String>

Optional. Text data.

=item * C<< $msg->proto_data() >> / C<< $msg->proto_data($value) >>

Type: C<Message> (L<Google::Protobuf::Any::Any>)

Optional. Proto data.

NOTE: The `protoData` field only functions as expected when the payload
is specifically a `CloudEvent` message type, and can't be used for
arbitrary protocol buffer messages. For any other protocol buffer type,
you must serialize your proto message into bytes, and use the
`binaryData` field instead.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Eventarc::Publishing::V1::CloudEvent::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
