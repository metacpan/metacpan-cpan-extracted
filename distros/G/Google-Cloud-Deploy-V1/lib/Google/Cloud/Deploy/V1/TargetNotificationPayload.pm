package Google::Cloud::Deploy::V1::TargetNotificationPayload;

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
Cjhnb29nbGUvY2xvdWQvZGVwbG95L3YxL3RhcmdldF9ub3RpZmljYXRpb25fcGF5bG9hZC5w
cm90bxIWZ29vZ2xlLmNsb3VkLmRlcGxveS52MRomZ29vZ2xlL2Nsb3VkL2RlcGxveS92MS9s
b2dfZW51bXMucHJvdG8ifQoXVGFyZ2V0Tm90aWZpY2F0aW9uRXZlbnQSGAoHbWVzc2FnZRgB
IAEoCVIHbWVzc2FnZRIWCgZ0YXJnZXQYAiABKAlSBnRhcmdldBIwCgR0eXBlGAMgASgOMhwu
Z29vZ2xlLmNsb3VkLmRlcGxveS52MS5UeXBlUgR0eXBlQnIKGmNvbS5nb29nbGUuY2xvdWQu
ZGVwbG95LnYxQh5UYXJnZXROb3RpZmljYXRpb25QYXlsb2FkUHJvdG9QAVoyY2xvdWQuZ29v
Z2xlLmNvbS9nby9kZXBsb3kvYXBpdjEvZGVwbG95cGI7ZGVwbG95cGJKpwkKBhIEDgAlAQq8
BAoBDBIDDgASMrEEIENvcHlyaWdodCAyMDI1IEdvb2dsZSBMTEMKCiBMaWNlbnNlZCB1bmRl
ciB0aGUgQXBhY2hlIExpY2Vuc2UsIFZlcnNpb24gMi4wICh0aGUgIkxpY2Vuc2UiKTsKIHlv
dSBtYXkgbm90IHVzZSB0aGlzIGZpbGUgZXhjZXB0IGluIGNvbXBsaWFuY2Ugd2l0aCB0aGUg
TGljZW5zZS4KIFlvdSBtYXkgb2J0YWluIGEgY29weSBvZiB0aGUgTGljZW5zZSBhdAoKICAg
ICBodHRwOi8vd3d3LmFwYWNoZS5vcmcvbGljZW5zZXMvTElDRU5TRS0yLjAKCiBVbmxlc3Mg
cmVxdWlyZWQgYnkgYXBwbGljYWJsZSBsYXcgb3IgYWdyZWVkIHRvIGluIHdyaXRpbmcsIHNv
ZnR3YXJlCiBkaXN0cmlidXRlZCB1bmRlciB0aGUgTGljZW5zZSBpcyBkaXN0cmlidXRlZCBv
biBhbiAiQVMgSVMiIEJBU0lTLAogV0lUSE9VVCBXQVJSQU5USUVTIE9SIENPTkRJVElPTlMg
T0YgQU5ZIEtJTkQsIGVpdGhlciBleHByZXNzIG9yIGltcGxpZWQuCiBTZWUgdGhlIExpY2Vu
c2UgZm9yIHRoZSBzcGVjaWZpYyBsYW5ndWFnZSBnb3Zlcm5pbmcgcGVybWlzc2lvbnMgYW5k
CiBsaW1pdGF0aW9ucyB1bmRlciB0aGUgTGljZW5zZS4KCggKAQISAxAAHwoJCgIDABIDEgAw
CggKAQgSAxQASQoJCgIICxIDFABJCggKAQgSAxUAIgoJCgIIChIDFQAiCggKAQgSAxYAPwoJ
CgIICBIDFgA/CggKAQgSAxcAMwoJCgIIARIDFwAzCrQBCgIEABIEHAAlARqnASBQYXlsb2Fk
IHByb3RvIGZvciAiY2xvdWRkZXBsb3kuZ29vZ2xlYXBpcy5jb20vdGFyZ2V0X25vdGlmaWNh
dGlvbiIKIFBsYXRmb3JtIExvZyBldmVudCB0aGF0IGRlc2NyaWJlcyB0aGUgZmFpbHVyZSB0
byBzZW5kIHRhcmdldCBzdGF0dXMgY2hhbmdlCiBQdWIvU3ViIG5vdGlmaWNhdGlvbi4KCgoK
AwQAARIDHAgfCkMKBAQAAgASAx4CFRo2IERlYnVnIG1lc3NhZ2UgZm9yIHdoZW4gYSBub3Rp
ZmljYXRpb24gZmFpbHMgdG8gc2VuZC4KCgwKBQQAAgAFEgMeAggKDAoFBAACAAESAx4JEAoM
CgUEAAIAAxIDHhMUCigKBAQAAgESAyECFBobIFRoZSBuYW1lIG9mIHRoZSBgVGFyZ2V0YC4K
CgwKBQQAAgEFEgMhAggKDAoFBAACAQESAyEJDwoMCgUEAAIBAxIDIRITCkUKBAQAAgISAyQC
EBo4IFR5cGUgb2YgdGhpcyBub3RpZmljYXRpb24sIGUuZy4gZm9yIGEgUHViL1N1YiBmYWls
dXJlLgoKDAoFBAACAgYSAyQCBgoMCgUEAAICARIDJAcLCgwKBQQAAgIDEgMkDg9iBnByb3Rv
Mw==
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Deploy::V1::TargetNotificationPayload::TargetNotificationEvent ===
    # Fields for TargetNotificationEvent
    # Field: message Type: 9 ()
    # Field: target Type: 9 ()
    # Field: type Type: 14 (.google.cloud.deploy.v1.Type)

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Deploy::V1::TargetNotificationPayload - Compiled Protocol Buffers messages for google/cloud/deploy/v1/target_notification_payload.proto

=head1 SYNOPSIS

    use Google::Cloud::Deploy::V1::TargetNotificationPayload;

    my $msg = Google::Cloud::Deploy::V1::TargetNotificationPayload::TargetNotificationEvent->new({
        message => $message,
        target => $target,
        type => $type,
    });

    # Read or update a field
    my $val = $msg->message();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Deploy::V1::TargetNotificationPayload::TargetNotificationEvent->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/deploy/v1/target_notification_payload.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Deploy::V1::TargetNotificationPayload::TargetNotificationEvent

Payload proto for "clouddeploy.googleapis.com/target_notification"
Platform Log event that describes the failure to send target status change
Pub/Sub notification.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->message() >> / C<< $msg->message($value) >>

Type: C<String>

Debug message for when a notification fails to send.

=item * C<< $msg->target() >> / C<< $msg->target($value) >>

Type: C<String>

The name of the `Target`.

=item * C<< $msg->type() >> / C<< $msg->type($value) >>

Type: C<Enum> (L<Google::Cloud::Deploy::V1::Type>)

Type of this notification, e.g. for a Pub/Sub failure.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Deploy::V1::TargetNotificationPayload::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
