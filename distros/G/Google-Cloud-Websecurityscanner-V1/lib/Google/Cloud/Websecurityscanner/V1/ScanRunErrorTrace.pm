package Google::Cloud::Websecurityscanner::V1::ScanRunErrorTrace;

use strict;
use warnings;

our $VERSION = '0.14';

use Protobuf::Message;
use Protobuf::DescriptorPool;
use Protobuf::Internal qw(:all);
use MIME::Base64;

BEGIN {
    eval { require Google::Cloud::Websecurityscanner::V1::ScanConfigError };
    my $descriptor_b64 = <<'EOF';
Cj1nb29nbGUvY2xvdWQvd2Vic2VjdXJpdHlzY2FubmVyL3YxL3NjYW5fcnVuX2Vycm9yX3Ry
YWNlLnByb3RvEiJnb29nbGUuY2xvdWQud2Vic2VjdXJpdHlzY2FubmVyLnYxGjpnb29nbGUv
Y2xvdWQvd2Vic2VjdXJpdHlzY2FubmVyL3YxL3NjYW5fY29uZmlnX2Vycm9yLnByb3RvIr0D
ChFTY2FuUnVuRXJyb3JUcmFjZRJOCgRjb2RlGAEgASgOMjouZ29vZ2xlLmNsb3VkLndlYnNl
Y3VyaXR5c2Nhbm5lci52MS5TY2FuUnVuRXJyb3JUcmFjZS5Db2RlUgRjb2RlEl8KEXNjYW5f
Y29uZmlnX2Vycm9yGAIgASgLMjMuZ29vZ2xlLmNsb3VkLndlYnNlY3VyaXR5c2Nhbm5lci52
MS5TY2FuQ29uZmlnRXJyb3JSD3NjYW5Db25maWdFcnJvchI8Chttb3N0X2NvbW1vbl9odHRw
X2Vycm9yX2NvZGUYAyABKAVSF21vc3RDb21tb25IdHRwRXJyb3JDb2RlIrgBCgRDb2RlEhQK
EENPREVfVU5TUEVDSUZJRUQQABISCg5JTlRFUk5BTF9FUlJPUhABEhUKEVNDQU5fQ09ORklH
X0lTU1VFEAISHwobQVVUSEVOVElDQVRJT05fQ09ORklHX0lTU1VFEAMSHAoYVElNRURfT1VU
X1dISUxFX1NDQU5OSU5HEAQSFgoSVE9PX01BTllfUkVESVJFQ1RTEAUSGAoUVE9PX01BTllf
SFRUUF9FUlJPUlMQBkKMAgomY29tLmdvb2dsZS5jbG91ZC53ZWJzZWN1cml0eXNjYW5uZXIu
djFCFlNjYW5SdW5FcnJvclRyYWNlUHJvdG9QAVpWY2xvdWQuZ29vZ2xlLmNvbS9nby93ZWJz
ZWN1cml0eXNjYW5uZXIvYXBpdjEvd2Vic2VjdXJpdHlzY2FubmVycGI7d2Vic2VjdXJpdHlz
Y2FubmVycGKqAiJHb29nbGUuQ2xvdWQuV2ViU2VjdXJpdHlTY2FubmVyLlYxygIiR29vZ2xl
XENsb3VkXFdlYlNlY3VyaXR5U2Nhbm5lclxWMeoCJUdvb2dsZTo6Q2xvdWQ6OldlYlNlY3Vy
aXR5U2Nhbm5lcjo6VjFKzhQKBhIEDgBKAQq8BAoBDBIDDgASMrEEIENvcHlyaWdodCAyMDI1
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
ZW5zZS4KCggKAQISAxAAKwoJCgIDABIDEgBECggKAQgSAxQAPwoJCgIIJRIDFAA/CggKAQgS
AxUAbQoJCgIICxIDFQBtCggKAQgSAxYAIgoJCgIIChIDFgAiCggKAQgSAxcANwoJCgIICBID
FwA3CggKAQgSAxgAPwoJCgIIARIDGAA/CggKAQgSAxkAPwoJCgIIKRIDGQA/CggKAQgSAxoA
PgoJCgIILRIDGgA+CkkKAgQAEgQeAEoBGj0gT3V0cHV0IG9ubHkuCiBEZWZpbmVzIGFuIGVy
cm9yIHRyYWNlIG1lc3NhZ2UgZm9yIGEgU2NhblJ1bi4KCgoKAwQAARIDHggZCkcKBAQABAAS
BCICPAMaOSBPdXRwdXQgb25seS4KIERlZmluZXMgYW4gZXJyb3IgcmVhc29uIGNvZGUuCiBO
ZXh0IGlkOiA4CgoMCgUEAAQAARIDIgcLCi0KBgQABAACABIDJAQZGh4gRGVmYXVsdCB2YWx1
ZSBpcyBuZXZlciB1c2VkLgoKDgoHBAAEAAIAARIDJAQUCg4KBwQABAACAAISAyQXGApUCgYE
AAQAAgESAycEFxpFIEluZGljYXRlcyB0aGF0IHRoZSBzY2FuIHJ1biBmYWlsZWQgZHVlIHRv
IGFuIGludGVybmFsIHNlcnZlciBlcnJvci4KCg4KBwQABAACAQESAycEEgoOCgcEAAQAAgEC
EgMnFRYKlQEKBgQABAACAhIDKwQaGoUBIEluZGljYXRlcyBhIHNjYW4gY29uZmlndXJhdGlv
biBlcnJvciwgdXN1YWxseSBkdWUgdG8gb3V0ZGF0ZWQgU2NhbkNvbmZpZwogc2V0dGluZ3Ms
IHN1Y2ggYXMgc3RhcnRpbmdfdXJscyBvciB0aGUgRE5TIGNvbmZpZ3VyYXRpb24uCgoOCgcE
AAQAAgIBEgMrBBUKDgoHBAAEAAICAhIDKxgZCnAKBgQABAACAxIDLwQkGmEgSW5kaWNhdGVz
IGFuIGF1dGhlbnRpY2F0aW9uIGVycm9yLCB1c3VhbGx5IGR1ZSB0byBvdXRkYXRlZCBTY2Fu
Q29uZmlnCiBhdXRoZW50aWNhdGlvbiBzZXR0aW5ncy4KCg4KBwQABAACAwESAy8EHwoOCgcE
AAQAAgMCEgMvIiMKWQoGBAAEAAIEEgMyBCEaSiBJbmRpY2F0ZXMgYSBzY2FuIG9wZXJhdGlv
biB0aW1lb3V0LCB1c3VhbGx5IGNhdXNlZCBieSBhIHZlcnkgbGFyZ2Ugc2l0ZS4KCg4KBwQA
BAACBAESAzIEHAoOCgcEAAQAAgQCEgMyHyAKkAEKBgQABAACBRIDNgQbGoABIEluZGljYXRl
cyB0aGF0IGEgc2NhbiBlbmNvdW50ZXJlZCBleGNlc3NpdmUgcmVkaXJlY3RzLCBlaXRoZXIg
dG8KIGF1dGhlbnRpY2F0aW9uIG9yIHNvbWUgb3RoZXIgcGFnZSBvdXRzaWRlIG9mIHRoZSBz
Y2FuIHNjb3BlLgoKDgoHBAAEAAIFARIDNgQWCg4KBwQABAACBQISAzYZGgrXAQoGBAAEAAIG
EgM7BB0axwEgSW5kaWNhdGVzIHRoYXQgYSBzY2FuIGVuY291bnRlcmVkIG51bWVyb3VzIGVy
cm9ycyBmcm9tIHRoZSB3ZWIgc2l0ZQogcGFnZXMuIFdoZW4gYXZhaWxhYmxlLCBtb3N0X2Nv
bW1vbl9odHRwX2Vycm9yX2NvZGUgZmllbGQgaW5kaWNhdGVzIHRoZQogbW9zdCBjb21tb24g
SFRUUCBlcnJvciBjb2RlIGVuY291bnRlcmVkIGR1cmluZyB0aGUgc2Nhbi4KCg4KBwQABAAC
BgESAzsEGAoOCgcEAAQAAgYCEgM7GxwKPAoEBAACABIDPwIQGi8gT3V0cHV0IG9ubHkuIElu
ZGljYXRlcyB0aGUgZXJyb3IgcmVhc29uIGNvZGUuCgoMCgUEAAIABhIDPwIGCgwKBQQAAgAB
EgM/BwsKDAoFBAACAAMSAz8ODwrIAQoEBAACARIDRAIoGroBIE91dHB1dCBvbmx5LiBJZiB0
aGUgc2NhbiBlbmNvdW50ZXJzIFNDQU5fQ09ORklHX0lTU1VFIGVycm9yLCB0aGlzIGZpZWxk
IGhhcyB0aGUgZXJyb3IKIG1lc3NhZ2UgZW5jb3VudGVyZWQgZHVyaW5nIHNjYW4gY29uZmln
dXJhdGlvbiB2YWxpZGF0aW9uIHRoYXQgaXMgcGVyZm9ybWVkCiBiZWZvcmUgZWFjaCBzY2Fu
IHJ1bi4KCgwKBQQAAgEGEgNEAhEKDAoFBAACAQESA0QSIwoMCgUEAAIBAxIDRCYnCvABCgQE
AAICEgNJAiga4gEgT3V0cHV0IG9ubHkuIElmIHRoZSBzY2FuIGVuY291bnRlcnMgVE9PX01B
TllfSFRUUF9FUlJPUlMsIHRoaXMgZmllbGQgaW5kaWNhdGVzIHRoZSBtb3N0CiBjb21tb24g
SFRUUCBlcnJvciBjb2RlLCBpZiBzdWNoIGlzIGF2YWlsYWJsZS4gRm9yIGV4YW1wbGUsIGlm
IHRoaXMgY29kZSBpcwogNDA0LCB0aGUgc2NhbiBoYXMgZW5jb3VudGVyZWQgdG9vIG1hbnkg
Tk9UX0ZPVU5EIHJlc3BvbnNlcy4KCgwKBQQAAgIFEgNJAgcKDAoFBAACAgESA0kIIwoMCgUE
AAICAxIDSSYnYgZwcm90bzM=
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Websecurityscanner::V1::ScanRunErrorTrace::ScanRunErrorTrace ===
    # Fields for ScanRunErrorTrace
    # Field: code Type: 14 (.google.cloud.websecurityscanner.v1.ScanRunErrorTrace.Code)
    # Field: scan_config_error Type: 11 (.google.cloud.websecurityscanner.v1.ScanConfigError)
    # Field: most_common_http_error_code Type: 5 ()

# Enum: ScanRunErrorTrace::Code
our $ScanRunErrorTrace_CODE_UNSPECIFIED = 0;
our $ScanRunErrorTrace_INTERNAL_ERROR = 1;
our $ScanRunErrorTrace_SCAN_CONFIG_ISSUE = 2;
our $ScanRunErrorTrace_AUTHENTICATION_CONFIG_ISSUE = 3;
our $ScanRunErrorTrace_TIMED_OUT_WHILE_SCANNING = 4;
our $ScanRunErrorTrace_TOO_MANY_REDIRECTS = 5;
our $ScanRunErrorTrace_TOO_MANY_HTTP_ERRORS = 6;

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Websecurityscanner::V1::ScanRunErrorTrace - Compiled Protocol Buffers messages for google/cloud/websecurityscanner/v1/scan_run_error_trace.proto

=head1 SYNOPSIS

    use Google::Cloud::Websecurityscanner::V1::ScanRunErrorTrace;

    my $msg = Google::Cloud::Websecurityscanner::V1::ScanRunErrorTrace::ScanRunErrorTrace->new({
        code => $code,
        scan_config_error => $scan_config_error,
        most_common_http_error_code => $most_common_http_error_code,
    });

    # Read or update a field
    my $val = $msg->code();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Websecurityscanner::V1::ScanRunErrorTrace::ScanRunErrorTrace->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/websecurityscanner/v1/scan_run_error_trace.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Websecurityscanner::V1::ScanRunErrorTrace::ScanRunErrorTrace

Output only.
Defines an error trace message for a ScanRun.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->code() >> / C<< $msg->code($value) >>

Type: C<Enum> (L<Google::Cloud::Websecurityscanner::V1::ScanRunErrorTrace::Code>)

Output only. Indicates the error reason code.

=item * C<< $msg->scan_config_error() >> / C<< $msg->scan_config_error($value) >>

Type: C<Message> (L<Google::Cloud::Websecurityscanner::V1::ScanConfigError::ScanConfigError>)

Output only. If the scan encounters SCAN_CONFIG_ISSUE error, this field has the error
message encountered during scan configuration validation that is performed
before each scan run.

=item * C<< $msg->most_common_http_error_code() >> / C<< $msg->most_common_http_error_code($value) >>

Type: C<Int32>

Output only. If the scan encounters TOO_MANY_HTTP_ERRORS, this field indicates the most
common HTTP error code, if such is available. For example, if this code is
404, the scan has encountered too many NOT_FOUND responses.

=back

=head3 Enum: ScanRunErrorTrace::Code

=over 4

=item * C<CODE_UNSPECIFIED> => C<0>

=item * C<INTERNAL_ERROR> => C<1>

=item * C<SCAN_CONFIG_ISSUE> => C<2>

=item * C<AUTHENTICATION_CONFIG_ISSUE> => C<3>

=item * C<TIMED_OUT_WHILE_SCANNING> => C<4>

=item * C<TOO_MANY_REDIRECTS> => C<5>

=item * C<TOO_MANY_HTTP_ERRORS> => C<6>

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Websecurityscanner::V1::ScanRunErrorTrace::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
