package Google::Iam::Admin::V1::WorkforcePoolPlatformLogs;

use strict;
use warnings;

our $VERSION = '0.14';

use Protobuf::Message;
use Protobuf::DescriptorPool;
use Protobuf::Internal qw(:all);
use MIME::Base64;

BEGIN {
    my $descriptor_b64 = <<'EOF';
CjZnb29nbGUvaWFtL2FkbWluL3YxL3dvcmtmb3JjZV9wb29sX3BsYXRmb3JtX2xvZ3MucHJv
dG8SE2dvb2dsZS5pYW0uYWRtaW4udjEifwoiV29ya2ZvcmNlUG9vbEF0dHJpYnV0ZVN5bmNF
dmVudExvZxIYCgdzdWJqZWN0GAEgASgJUgdzdWJqZWN0EiUKDmZhaWx1cmVfcmVhc29uGAIg
ASgJUg1mYWlsdXJlUmVhc29uEhgKB21lc3NhZ2UYAyABKAlSB21lc3NhZ2VCqAEKF2NvbS5n
b29nbGUuaWFtLmFkbWluLnYxQh5Xb3JrZm9yY2VQb29sUGxhdGZvcm1Mb2dzUHJvdG9QAVoz
Y2xvdWQuZ29vZ2xlLmNvbS9nby9pYW0vYWRtaW4vYXBpdjEvYWRtaW5wYjthZG1pbnBiqgIZ
R29vZ2xlLkNsb3VkLklhbS5BZG1pbi5WMcoCGUdvb2dsZVxDbG91ZFxJYW1cQWRtaW5cVjFK
mg4KBhIEDgAwAQq8BAoBDBIDDgASMrEEIENvcHlyaWdodCAyMDI2IEdvb2dsZSBMTEMKCiBM
aWNlbnNlZCB1bmRlciB0aGUgQXBhY2hlIExpY2Vuc2UsIFZlcnNpb24gMi4wICh0aGUgIkxp
Y2Vuc2UiKTsKIHlvdSBtYXkgbm90IHVzZSB0aGlzIGZpbGUgZXhjZXB0IGluIGNvbXBsaWFu
Y2Ugd2l0aCB0aGUgTGljZW5zZS4KIFlvdSBtYXkgb2J0YWluIGEgY29weSBvZiB0aGUgTGlj
ZW5zZSBhdAoKICAgICBodHRwOi8vd3d3LmFwYWNoZS5vcmcvbGljZW5zZXMvTElDRU5TRS0y
LjAKCiBVbmxlc3MgcmVxdWlyZWQgYnkgYXBwbGljYWJsZSBsYXcgb3IgYWdyZWVkIHRvIGlu
IHdyaXRpbmcsIHNvZnR3YXJlCiBkaXN0cmlidXRlZCB1bmRlciB0aGUgTGljZW5zZSBpcyBk
aXN0cmlidXRlZCBvbiBhbiAiQVMgSVMiIEJBU0lTLAogV0lUSE9VVCBXQVJSQU5USUVTIE9S
IENPTkRJVElPTlMgT0YgQU5ZIEtJTkQsIGVpdGhlciBleHByZXNzIG9yIGltcGxpZWQuCiBT
ZWUgdGhlIExpY2Vuc2UgZm9yIHRoZSBzcGVjaWZpYyBsYW5ndWFnZSBnb3Zlcm5pbmcgcGVy
bWlzc2lvbnMgYW5kCiBsaW1pdGF0aW9ucyB1bmRlciB0aGUgTGljZW5zZS4KCggKAQISAxAA
HAoICgEIEgMSADYKCQoCCCUSAxIANgoICgEIEgMTAEoKCQoCCAsSAxMASgoICgEIEgMUACIK
CQoCCAoSAxQAIgoICgEIEgMVAD8KCQoCCAgSAxUAPwoICgEIEgMWADAKCQoCCAESAxYAMAoI
CgEIEgMXADcKCQoCCCkSAxcANwpdCgIEABIEGwAwARpRIExvZyBwYXlsb2FkIGZvciBXb3Jr
Zm9yY2UgUG9vbCBQcm92aWRlciBiYWNrZ3JvdW5kIHVzZXIgYXR0cmlidXRlIHN5bmMKIGV2
ZW50cy4KCgoKAwQAARIDGwgqCpcBCgQEAAIAEgMeAhUaiQEgVGhlIHJhdyBzdWJqZWN0IGlk
ZW50aWZpZXIgb2YgdGhlIHVzZXIgd2hvc2UgYXR0cmlidXRlcyBhcmUgYmVpbmcgc3luY2Vk
LgogVGhpcyBpZGVudGlmaWVzIHRoZSBzcGVjaWZpYyB1c2VyIHdpdGhpbiB0aGUgd29ya2Zv
cmNlIHBvb2wuCgoMCgUEAAIABRIDHgIICgwKBQQAAgABEgMeCRAKDAoFBAACAAMSAx4TFArX
AwoEBAACARIDKgIcGskDIEEgbWFjaGluZS1yZWFkYWJsZSBjb2RlIGluZGljYXRpbmcgdGhl
IHJlYXNvbiBmb3IgZmFpbHVyZS4gT25seSBwb3B1bGF0ZWQKIHdoZW4gYHNldmVyaXR5YCBp
cyBgRVJST1JgLgoKIFBvc3NpYmxlIHZhbHVlcyBpbmNsdWRlLCBidXQgYXJlIG5vdCBsaW1p
dGVkIHRvOgogLSBgUFJPVklERVJfTk9UX0ZPVU5EYDogVGhlIHVzZXIgd2FzIG5vdCBmb3Vu
ZCBpbiB0aGUgaWRlbnRpdHkgcHJvdmlkZXIuCiAtIGBJRFBfVU5SRUFDSEFCTEVgOiBUaGUg
aWRlbnRpdHkgcHJvdmlkZXIgY291bGQgbm90IGJlIHJlYWNoZWQuCiAtIGBBVFRSSUJVVEVf
TUFQUElOR19FUlJPUmA6IFRoZSBhdHRyaWJ1dGUgbWFwcGluZyBjb25maWd1cmF0aW9uIGlz
CiBpbnZhbGlkLgogLSBgSU5URVJOQUxfRVJST1JgOiBBbiBpbnRlcm5hbCBlcnJvciBvY2N1
cnJlZCBkdXJpbmcgYXR0cmlidXRlCiBzeW5jaHJvbml6YXRpb24uCgoMCgUEAAIBBRIDKgII
CgwKBQQAAgEBEgMqCRcKDAoFBAACAQMSAyoaGwrrAQoEBAACAhIDLwIVGt0BIEh1bWFuLXJl
YWRhYmxlIGRldGFpbHMgZGVzY3JpYmluZyB0aGUgYXR0cmlidXRlIHN5bmMgcmVzdWx0LiBG
b3Igc3VjY2Vzc2Z1bAogc3luY3MsIHRoaXMgY29udGFpbnMgdGhlIHVwZGF0ZWQgdXNlciBh
dHRyaWJ1dGVzIGlmIGRldGFpbGVkIGF1ZGl0CiBsb2dnaW5nIGlzIGVuYWJsZWQuIEZvciBm
YWlsdXJlcywgdGhpcyBkZXNjcmliZXMgdGhlIGNhdXNlIG9mIHRoZSBmYWlsdXJlLgoKDAoF
BAACAgUSAy8CCAoMCgUEAAICARIDLwkQCgwKBQQAAgIDEgMvExRiBnByb3RvMw==
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Iam::Admin::V1::WorkforcePoolPlatformLogs::WorkforcePoolAttributeSyncEventLog ===
    # Fields for WorkforcePoolAttributeSyncEventLog
    # Field: subject Type: 9 ()
    # Field: failure_reason Type: 9 ()
    # Field: message Type: 9 ()

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Iam::Admin::V1::WorkforcePoolPlatformLogs - Compiled Protocol Buffers messages for google/iam/admin/v1/workforce_pool_platform_logs.proto

=head1 SYNOPSIS

    use Google::Iam::Admin::V1::WorkforcePoolPlatformLogs;

    my $msg = Google::Iam::Admin::V1::WorkforcePoolPlatformLogs::WorkforcePoolAttributeSyncEventLog->new({
        subject => $subject,
        failure_reason => $failure_reason,
        message => $message,
    });

    # Read or update a field
    my $val = $msg->subject();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Iam::Admin::V1::WorkforcePoolPlatformLogs::WorkforcePoolAttributeSyncEventLog->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/iam/admin/v1/workforce_pool_platform_logs.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Iam::Admin::V1::WorkforcePoolPlatformLogs::WorkforcePoolAttributeSyncEventLog

Log payload for Workforce Pool Provider background user attribute sync
events.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->subject() >> / C<< $msg->subject($value) >>

Type: C<String>

The raw subject identifier of the user whose attributes are being synced.
This identifies the specific user within the workforce pool.

=item * C<< $msg->failure_reason() >> / C<< $msg->failure_reason($value) >>

Type: C<String>

A machine-readable code indicating the reason for failure. Only populated
when `severity` is `ERROR`.

Possible values include, but are not limited to:
- `PROVIDER_NOT_FOUND`: The user was not found in the identity provider.
- `IDP_UNREACHABLE`: The identity provider could not be reached.
- `ATTRIBUTE_MAPPING_ERROR`: The attribute mapping configuration is
invalid.
- `INTERNAL_ERROR`: An internal error occurred during attribute
synchronization.

=item * C<< $msg->message() >> / C<< $msg->message($value) >>

Type: C<String>

Human-readable details describing the attribute sync result. For successful
syncs, this contains the updated user attributes if detailed audit
logging is enabled. For failures, this describes the cause of the failure.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Iam::Admin::V1::WorkforcePoolPlatformLogs::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
