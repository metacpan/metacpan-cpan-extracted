package Google::Cloud::Deploy::V1::DeliverypipelineNotificationPayload;

use strict;
use warnings;

our $VERSION = '0.14';

use Protobuf::Message;
use Protobuf::DescriptorPool;
use Protobuf::Internal qw(:all);
use MIME::Base64;

BEGIN {
    eval { require Google::Cloud::Deploy::V1::LogEnums };
    my $descriptor_b64 = <<'EOF';
CkJnb29nbGUvY2xvdWQvZGVwbG95L3YxL2RlbGl2ZXJ5cGlwZWxpbmVfbm90aWZpY2F0aW9u
X3BheWxvYWQucHJvdG8SFmdvb2dsZS5jbG91ZC5kZXBsb3kudjEaJmdvb2dsZS9jbG91ZC9k
ZXBsb3kvdjEvbG9nX2VudW1zLnByb3RvIr8BCiFEZWxpdmVyeVBpcGVsaW5lTm90aWZpY2F0
aW9uRXZlbnQSGAoHbWVzc2FnZRgBIAEoCVIHbWVzc2FnZRIhCgxwaXBlbGluZV91aWQYBCAB
KAlSC3BpcGVsaW5lVWlkEisKEWRlbGl2ZXJ5X3BpcGVsaW5lGAIgASgJUhBkZWxpdmVyeVBp
cGVsaW5lEjAKBHR5cGUYAyABKA4yHC5nb29nbGUuY2xvdWQuZGVwbG95LnYxLlR5cGVSBHR5
cGVCfAoaY29tLmdvb2dsZS5jbG91ZC5kZXBsb3kudjFCKERlbGl2ZXJ5UGlwZWxpbmVOb3Rp
ZmljYXRpb25QYXlsb2FkUHJvdG9QAVoyY2xvdWQuZ29vZ2xlLmNvbS9nby9kZXBsb3kvYXBp
djEvZGVwbG95cGI7ZGVwbG95cGJKrgoKBhIEDgAoAQq8BAoBDBIDDgASMrEEIENvcHlyaWdo
dCAyMDI1IEdvb2dsZSBMTEMKCiBMaWNlbnNlZCB1bmRlciB0aGUgQXBhY2hlIExpY2Vuc2Us
IFZlcnNpb24gMi4wICh0aGUgIkxpY2Vuc2UiKTsKIHlvdSBtYXkgbm90IHVzZSB0aGlzIGZp
bGUgZXhjZXB0IGluIGNvbXBsaWFuY2Ugd2l0aCB0aGUgTGljZW5zZS4KIFlvdSBtYXkgb2J0
YWluIGEgY29weSBvZiB0aGUgTGljZW5zZSBhdAoKICAgICBodHRwOi8vd3d3LmFwYWNoZS5v
cmcvbGljZW5zZXMvTElDRU5TRS0yLjAKCiBVbmxlc3MgcmVxdWlyZWQgYnkgYXBwbGljYWJs
ZSBsYXcgb3IgYWdyZWVkIHRvIGluIHdyaXRpbmcsIHNvZnR3YXJlCiBkaXN0cmlidXRlZCB1
bmRlciB0aGUgTGljZW5zZSBpcyBkaXN0cmlidXRlZCBvbiBhbiAiQVMgSVMiIEJBU0lTLAog
V0lUSE9VVCBXQVJSQU5USUVTIE9SIENPTkRJVElPTlMgT0YgQU5ZIEtJTkQsIGVpdGhlciBl
eHByZXNzIG9yIGltcGxpZWQuCiBTZWUgdGhlIExpY2Vuc2UgZm9yIHRoZSBzcGVjaWZpYyBs
YW5ndWFnZSBnb3Zlcm5pbmcgcGVybWlzc2lvbnMgYW5kCiBsaW1pdGF0aW9ucyB1bmRlciB0
aGUgTGljZW5zZS4KCggKAQISAxAAHwoJCgIDABIDEgAwCggKAQgSAxQASQoJCgIICxIDFABJ
CggKAQgSAxUAIgoJCgIIChIDFQAiCggKAQgSAxYASQoJCgIICBIDFgBJCggKAQgSAxcAMwoJ
CgIIARIDFwAzCskBCgIEABIEHAAoARq8ASBQYXlsb2FkIHByb3RvIGZvciAiY2xvdWRkZXBs
b3kuZ29vZ2xlYXBpcy5jb20vZGVsaXZlcnlwaXBlbGluZV9ub3RpZmljYXRpb24iCiBQbGF0
Zm9ybSBMb2cgZXZlbnQgdGhhdCBkZXNjcmliZXMgdGhlIGZhaWx1cmUgdG8gc2VuZCBkZWxp
dmVyeSBwaXBlbGluZQogc3RhdHVzIGNoYW5nZSBQdWIvU3ViIG5vdGlmaWNhdGlvbi4KCgoK
AwQAARIDHAgpCkMKBAQAAgASAx4CFRo2IERlYnVnIG1lc3NhZ2UgZm9yIHdoZW4gYSBub3Rp
ZmljYXRpb24gZmFpbHMgdG8gc2VuZC4KCgwKBQQAAgAFEgMeAggKDAoFBAACAAESAx4JEAoM
CgUEAAIAAxIDHhMUCjsKBAQAAgESAyECGhouIFVuaXF1ZSBpZGVudGlmaWVyIG9mIHRoZSBg
RGVsaXZlcnlQaXBlbGluZWAuCgoMCgUEAAIBBRIDIQIICgwKBQQAAgEBEgMhCRUKDAoFBAAC
AQMSAyEYGQozCgQEAAICEgMkAh8aJiBUaGUgbmFtZSBvZiB0aGUgYERlbGl2ZXJ5IFBpcGVs
aW5lYC4KCgwKBQQAAgIFEgMkAggKDAoFBAACAgESAyQJGgoMCgUEAAICAxIDJB0eCkUKBAQA
AgMSAycCEBo4IFR5cGUgb2YgdGhpcyBub3RpZmljYXRpb24sIGUuZy4gZm9yIGEgUHViL1N1
YiBmYWlsdXJlLgoKDAoFBAACAwYSAycCBgoMCgUEAAIDARIDJwcLCgwKBQQAAgMDEgMnDg9i
BnByb3RvMw==
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Deploy::V1::DeliverypipelineNotificationPayload::DeliveryPipelineNotificationEvent ===
    # Fields for DeliveryPipelineNotificationEvent
    # Field: message Type: 9 ()
    # Field: pipeline_uid Type: 9 ()
    # Field: delivery_pipeline Type: 9 ()
    # Field: type Type: 14 (.google.cloud.deploy.v1.Type)

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Deploy::V1::DeliverypipelineNotificationPayload - Compiled Protocol Buffers messages for google/cloud/deploy/v1/deliverypipeline_notification_payload.proto

=head1 SYNOPSIS

    use Google::Cloud::Deploy::V1::DeliverypipelineNotificationPayload;

    my $msg = Google::Cloud::Deploy::V1::DeliverypipelineNotificationPayload::DeliveryPipelineNotificationEvent->new({
        message => $message,
        pipeline_uid => $pipeline_uid,
        delivery_pipeline => $delivery_pipeline,
        type => $type,
    });

    # Read or update a field
    my $val = $msg->message();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Deploy::V1::DeliverypipelineNotificationPayload::DeliveryPipelineNotificationEvent->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/deploy/v1/deliverypipeline_notification_payload.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Deploy::V1::DeliverypipelineNotificationPayload::DeliveryPipelineNotificationEvent

Payload proto for "clouddeploy.googleapis.com/deliverypipeline_notification"
Platform Log event that describes the failure to send delivery pipeline
status change Pub/Sub notification.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->message() >> / C<< $msg->message($value) >>

Type: C<String>

Debug message for when a notification fails to send.

=item * C<< $msg->pipeline_uid() >> / C<< $msg->pipeline_uid($value) >>

Type: C<String>

Unique identifier of the `DeliveryPipeline`.

=item * C<< $msg->delivery_pipeline() >> / C<< $msg->delivery_pipeline($value) >>

Type: C<String>

The name of the `Delivery Pipeline`.

=item * C<< $msg->type() >> / C<< $msg->type($value) >>

Type: C<Enum> (L<Google::Cloud::Deploy::V1::Type>)

Type of this notification, e.g. for a Pub/Sub failure.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Deploy::V1::DeliverypipelineNotificationPayload::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
