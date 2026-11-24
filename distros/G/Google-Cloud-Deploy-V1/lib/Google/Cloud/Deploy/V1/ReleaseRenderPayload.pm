package Google::Cloud::Deploy::V1::ReleaseRenderPayload;

use strict;
use warnings;

our $VERSION = '0.14';

use Protobuf::Message;
use Protobuf::DescriptorPool;
use Protobuf::Internal qw(:all);
use MIME::Base64;

BEGIN {
    eval { require Google::Cloud::Deploy::V1::CloudDeploy };
    eval { require Google::Cloud::Deploy::V1::LogEnums };
    my $descriptor_b64 = <<'EOF';
CjNnb29nbGUvY2xvdWQvZGVwbG95L3YxL3JlbGVhc2VfcmVuZGVyX3BheWxvYWQucHJvdG8S
Fmdvb2dsZS5jbG91ZC5kZXBsb3kudjEaKWdvb2dsZS9jbG91ZC9kZXBsb3kvdjEvY2xvdWRf
ZGVwbG95LnByb3RvGiZnb29nbGUvY2xvdWQvZGVwbG95L3YxL2xvZ19lbnVtcy5wcm90byL8
AQoSUmVsZWFzZVJlbmRlckV2ZW50EhgKB21lc3NhZ2UYASABKAlSB21lc3NhZ2USIQoMcGlw
ZWxpbmVfdWlkGAQgASgJUgtwaXBlbGluZVVpZBIYCgdyZWxlYXNlGAIgASgJUgdyZWxlYXNl
EjAKBHR5cGUYBSABKA4yHC5nb29nbGUuY2xvdWQuZGVwbG95LnYxLlR5cGVSBHR5cGUSXQoU
cmVsZWFzZV9yZW5kZXJfc3RhdGUYAyABKA4yKy5nb29nbGUuY2xvdWQuZGVwbG95LnYxLlJl
bGVhc2UuUmVuZGVyU3RhdGVSEnJlbGVhc2VSZW5kZXJTdGF0ZUJtChpjb20uZ29vZ2xlLmNs
b3VkLmRlcGxveS52MUIZUmVsZWFzZVJlbmRlclBheWxvYWRQcm90b1ABWjJjbG91ZC5nb29n
bGUuY29tL2dvL2RlcGxveS9hcGl2MS9kZXBsb3lwYjtkZXBsb3lwYkqyDAoGEgQOAC4BCrwE
CgEMEgMOABIysQQgQ29weXJpZ2h0IDIwMjUgR29vZ2xlIExMQwoKIExpY2Vuc2VkIHVuZGVy
IHRoZSBBcGFjaGUgTGljZW5zZSwgVmVyc2lvbiAyLjAgKHRoZSAiTGljZW5zZSIpOwogeW91
IG1heSBub3QgdXNlIHRoaXMgZmlsZSBleGNlcHQgaW4gY29tcGxpYW5jZSB3aXRoIHRoZSBM
aWNlbnNlLgogWW91IG1heSBvYnRhaW4gYSBjb3B5IG9mIHRoZSBMaWNlbnNlIGF0CgogICAg
IGh0dHA6Ly93d3cuYXBhY2hlLm9yZy9saWNlbnNlcy9MSUNFTlNFLTIuMAoKIFVubGVzcyBy
ZXF1aXJlZCBieSBhcHBsaWNhYmxlIGxhdyBvciBhZ3JlZWQgdG8gaW4gd3JpdGluZywgc29m
dHdhcmUKIGRpc3RyaWJ1dGVkIHVuZGVyIHRoZSBMaWNlbnNlIGlzIGRpc3RyaWJ1dGVkIG9u
IGFuICJBUyBJUyIgQkFTSVMsCiBXSVRIT1VUIFdBUlJBTlRJRVMgT1IgQ09ORElUSU9OUyBP
RiBBTlkgS0lORCwgZWl0aGVyIGV4cHJlc3Mgb3IgaW1wbGllZC4KIFNlZSB0aGUgTGljZW5z
ZSBmb3IgdGhlIHNwZWNpZmljIGxhbmd1YWdlIGdvdmVybmluZyBwZXJtaXNzaW9ucyBhbmQK
IGxpbWl0YXRpb25zIHVuZGVyIHRoZSBMaWNlbnNlLgoKCAoBAhIDEAAfCgkKAgMAEgMSADMK
CQoCAwESAxMAMAoICgEIEgMVAEkKCQoCCAsSAxUASQoICgEIEgMWACIKCQoCCAoSAxYAIgoI
CgEIEgMXADoKCQoCCAgSAxcAOgoICgEIEgMYADMKCQoCCAESAxgAMwqIAQoCBAASBBwALgEa
fCBQYXlsb2FkIHByb3RvIGZvciAiY2xvdWRkZXBsb3kuZ29vZ2xlYXBpcy5jb20vcmVsZWFz
ZV9yZW5kZXIiCiBQbGF0Zm9ybSBMb2cgZXZlbnQgdGhhdCBkZXNjcmliZXMgdGhlIHJlbmRl
ciBzdGF0dXMgY2hhbmdlLgoKCgoDBAABEgMcCBoKigEKBAQAAgASAx8CFRp9IERlYnVnIG1l
c3NhZ2UgZm9yIHdoZW4gYSByZW5kZXIgdHJhbnNpdGlvbiBvY2N1cnMuIFByb3ZpZGVzIGZ1
cnRoZXIKIGRldGFpbHMgYXMgcmVuZGVyaW5nIHByb2dyZXNzZXMgdGhyb3VnaCByZW5kZXIg
c3RhdGVzLgoKDAoFBAACAAUSAx8CCAoMCgUEAAIAARIDHwkQCgwKBQQAAgADEgMfExQKOwoE
BAACARIDIgIaGi4gVW5pcXVlIGlkZW50aWZpZXIgb2YgdGhlIGBEZWxpdmVyeVBpcGVsaW5l
YC4KCgwKBQQAAgEFEgMiAggKDAoFBAACAQESAyIJFQoMCgUEAAIBAxIDIhgZCrcBCgQEAAIC
EgMnAhUaqQEgVGhlIG5hbWUgb2YgdGhlIHJlbGVhc2UuCiByZWxlYXNlX3VpZCBpcyBub3Qg
aW4gdGhpcyBsb2cgbWVzc2FnZSBiZWNhdXNlIHdlIHdyaXRlIHNvbWUgb2YgdGhlc2UgbG9n
CiBtZXNzYWdlcyBhdCByZWxlYXNlIGNyZWF0aW9uIHRpbWUsIGJlZm9yZSB3ZSd2ZSBnZW5l
cmF0ZWQgdGhlIHVpZC4KCgwKBQQAAgIFEgMnAggKDAoFBAACAgESAycJEAoMCgUEAAICAxID
JxMUClcKBAQAAgMSAyoCEBpKIFR5cGUgb2YgdGhpcyBub3RpZmljYXRpb24sIGUuZy4gZm9y
IGEgcmVsZWFzZSByZW5kZXIgc3RhdGUgY2hhbmdlIGV2ZW50LgoKDAoFBAACAwYSAyoCBgoM
CgUEAAIDARIDKgcLCgwKBQQAAgMDEgMqDg8KLwoEBAACBBIDLQIvGiIgVGhlIHN0YXRlIG9m
IHRoZSByZWxlYXNlIHJlbmRlci4KCgwKBQQAAgQGEgMtAhUKDAoFBAACBAESAy0WKgoMCgUE
AAIEAxIDLS0uYgZwcm90bzM=
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Deploy::V1::ReleaseRenderPayload::ReleaseRenderEvent ===
    # Fields for ReleaseRenderEvent
    # Field: message Type: 9 ()
    # Field: pipeline_uid Type: 9 ()
    # Field: release Type: 9 ()
    # Field: type Type: 14 (.google.cloud.deploy.v1.Type)
    # Field: release_render_state Type: 14 (.google.cloud.deploy.v1.Release.RenderState)

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Deploy::V1::ReleaseRenderPayload - Compiled Protocol Buffers messages for google/cloud/deploy/v1/release_render_payload.proto

=head1 SYNOPSIS

    use Google::Cloud::Deploy::V1::ReleaseRenderPayload;

    my $msg = Google::Cloud::Deploy::V1::ReleaseRenderPayload::ReleaseRenderEvent->new({
        message => $message,
        pipeline_uid => $pipeline_uid,
        release => $release,
        type => $type,
    });

    # Read or update a field
    my $val = $msg->message();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Deploy::V1::ReleaseRenderPayload::ReleaseRenderEvent->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/deploy/v1/release_render_payload.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Deploy::V1::ReleaseRenderPayload::ReleaseRenderEvent

Payload proto for "clouddeploy.googleapis.com/release_render"
Platform Log event that describes the render status change.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->message() >> / C<< $msg->message($value) >>

Type: C<String>

Debug message for when a render transition occurs. Provides further
details as rendering progresses through render states.

=item * C<< $msg->pipeline_uid() >> / C<< $msg->pipeline_uid($value) >>

Type: C<String>

Unique identifier of the `DeliveryPipeline`.

=item * C<< $msg->release() >> / C<< $msg->release($value) >>

Type: C<String>

The name of the release.
release_uid is not in this log message because we write some of these log
messages at release creation time, before we've generated the uid.

=item * C<< $msg->type() >> / C<< $msg->type($value) >>

Type: C<Enum> (L<Google::Cloud::Deploy::V1::Type>)

Type of this notification, e.g. for a release render state change event.

=item * C<< $msg->release_render_state() >> / C<< $msg->release_render_state($value) >>

Type: C<Enum> (L<Google::Cloud::Deploy::V1::Release::RenderState>)

The state of the release render.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Deploy::V1::ReleaseRenderPayload::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
