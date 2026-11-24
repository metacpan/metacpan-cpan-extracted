package Google::Cloud::Websecurityscanner::V1beta::ScanRunErrorTrace;

use strict;
use warnings;

our $VERSION = '0.14';

use Protobuf::Message;
use Protobuf::DescriptorPool;
use Protobuf::Internal qw(:all);
use MIME::Base64;

BEGIN {
    eval { require Google::Cloud::Websecurityscanner::V1beta::ScanConfigError };
    my $descriptor_b64 = <<'EOF';
CkFnb29nbGUvY2xvdWQvd2Vic2VjdXJpdHlzY2FubmVyL3YxYmV0YS9zY2FuX3J1bl9lcnJv
cl90cmFjZS5wcm90bxImZ29vZ2xlLmNsb3VkLndlYnNlY3VyaXR5c2Nhbm5lci52MWJldGEa
Pmdvb2dsZS9jbG91ZC93ZWJzZWN1cml0eXNjYW5uZXIvdjFiZXRhL3NjYW5fY29uZmlnX2Vy
cm9yLnByb3RvIsUDChFTY2FuUnVuRXJyb3JUcmFjZRJSCgRjb2RlGAEgASgOMj4uZ29vZ2xl
LmNsb3VkLndlYnNlY3VyaXR5c2Nhbm5lci52MWJldGEuU2NhblJ1bkVycm9yVHJhY2UuQ29k
ZVIEY29kZRJjChFzY2FuX2NvbmZpZ19lcnJvchgCIAEoCzI3Lmdvb2dsZS5jbG91ZC53ZWJz
ZWN1cml0eXNjYW5uZXIudjFiZXRhLlNjYW5Db25maWdFcnJvclIPc2NhbkNvbmZpZ0Vycm9y
EjwKG21vc3RfY29tbW9uX2h0dHBfZXJyb3JfY29kZRgDIAEoBVIXbW9zdENvbW1vbkh0dHBF
cnJvckNvZGUiuAEKBENvZGUSFAoQQ09ERV9VTlNQRUNJRklFRBAAEhIKDklOVEVSTkFMX0VS
Uk9SEAESFQoRU0NBTl9DT05GSUdfSVNTVUUQAhIfChtBVVRIRU5USUNBVElPTl9DT05GSUdf
SVNTVUUQAxIcChhUSU1FRF9PVVRfV0hJTEVfU0NBTk5JTkcQBBIWChJUT09fTUFOWV9SRURJ
UkVDVFMQBRIYChRUT09fTUFOWV9IVFRQX0VSUk9SUxAGQqACCipjb20uZ29vZ2xlLmNsb3Vk
LndlYnNlY3VyaXR5c2Nhbm5lci52MWJldGFCFlNjYW5SdW5FcnJvclRyYWNlUHJvdG9QAVpa
Y2xvdWQuZ29vZ2xlLmNvbS9nby93ZWJzZWN1cml0eXNjYW5uZXIvYXBpdjFiZXRhL3dlYnNl
Y3VyaXR5c2Nhbm5lcnBiO3dlYnNlY3VyaXR5c2Nhbm5lcnBiqgImR29vZ2xlLkNsb3VkLldl
YlNlY3VyaXR5U2Nhbm5lci5WMUJldGHKAiZHb29nbGVcQ2xvdWRcV2ViU2VjdXJpdHlTY2Fu
bmVyXFYxYmV0YeoCKUdvb2dsZTo6Q2xvdWQ6OldlYlNlY3VyaXR5U2Nhbm5lcjo6VjFiZXRh
SqgUCgYSBA8ASwEKvQQKAQwSAw8AEjKyBCBDb3B5cmlnaHQgMjAyNSBHb29nbGUgTExDCgog
TGljZW5zZWQgdW5kZXIgdGhlIEFwYWNoZSBMaWNlbnNlLCBWZXJzaW9uIDIuMCAodGhlICJM
aWNlbnNlIik7CiB5b3UgbWF5IG5vdCB1c2UgdGhpcyBmaWxlIGV4Y2VwdCBpbiBjb21wbGlh
bmNlIHdpdGggdGhlIExpY2Vuc2UuCiBZb3UgbWF5IG9idGFpbiBhIGNvcHkgb2YgdGhlIExp
Y2Vuc2UgYXQKCiAgICAgaHR0cDovL3d3dy5hcGFjaGUub3JnL2xpY2Vuc2VzL0xJQ0VOU0Ut
Mi4wCgogVW5sZXNzIHJlcXVpcmVkIGJ5IGFwcGxpY2FibGUgbGF3IG9yIGFncmVlZCB0byBp
biB3cml0aW5nLCBzb2Z0d2FyZQogZGlzdHJpYnV0ZWQgdW5kZXIgdGhlIExpY2Vuc2UgaXMg
ZGlzdHJpYnV0ZWQgb24gYW4gIkFTIElTIiBCQVNJUywKIFdJVEhPVVQgV0FSUkFOVElFUyBP
UiBDT05ESVRJT05TIE9GIEFOWSBLSU5ELCBlaXRoZXIgZXhwcmVzcyBvciBpbXBsaWVkLgog
U2VlIHRoZSBMaWNlbnNlIGZvciB0aGUgc3BlY2lmaWMgbGFuZ3VhZ2UgZ292ZXJuaW5nIHBl
cm1pc3Npb25zIGFuZAogbGltaXRhdGlvbnMgdW5kZXIgdGhlIExpY2Vuc2UuCgoKCAoBAhID
EQAvCgkKAgMAEgMTAEgKCAoBCBIDFQBDCgkKAgglEgMVAEMKCAoBCBIDFgBxCgkKAggLEgMW
AHEKCAoBCBIDFwAiCgkKAggKEgMXACIKCAoBCBIDGAA3CgkKAggIEgMYADcKCAoBCBIDGQBD
CgkKAggBEgMZAEMKCAoBCBIDGgBDCgkKAggpEgMaAEMKCAoBCBIDGwBCCgkKAggtEgMbAEIK
SQoCBAASBB8ASwEaPSBPdXRwdXQgb25seS4KIERlZmluZXMgYW4gZXJyb3IgdHJhY2UgbWVz
c2FnZSBmb3IgYSBTY2FuUnVuLgoKCgoDBAABEgMfCBkKRwoEBAAEABIEIwI9Axo5IE91dHB1
dCBvbmx5LgogRGVmaW5lcyBhbiBlcnJvciByZWFzb24gY29kZS4KIE5leHQgaWQ6IDcKCgwK
BQQABAABEgMjBwsKLQoGBAAEAAIAEgMlBBkaHiBEZWZhdWx0IHZhbHVlIGlzIG5ldmVyIHVz
ZWQuCgoOCgcEAAQAAgABEgMlBBQKDgoHBAAEAAIAAhIDJRcYClQKBgQABAACARIDKAQXGkUg
SW5kaWNhdGVzIHRoYXQgdGhlIHNjYW4gcnVuIGZhaWxlZCBkdWUgdG8gYW4gaW50ZXJuYWwg
c2VydmVyIGVycm9yLgoKDgoHBAAEAAIBARIDKAQSCg4KBwQABAACAQISAygVFgqVAQoGBAAE
AAICEgMsBBoahQEgSW5kaWNhdGVzIGEgc2NhbiBjb25maWd1cmF0aW9uIGVycm9yLCB1c3Vh
bGx5IGR1ZSB0byBvdXRkYXRlZCBTY2FuQ29uZmlnCiBzZXR0aW5ncywgc3VjaCBhcyBzdGFy
dGluZ191cmxzIG9yIHRoZSBETlMgY29uZmlndXJhdGlvbi4KCg4KBwQABAACAgESAywEFQoO
CgcEAAQAAgICEgMsGBkKcAoGBAAEAAIDEgMwBCQaYSBJbmRpY2F0ZXMgYW4gYXV0aGVudGlj
YXRpb24gZXJyb3IsIHVzdWFsbHkgZHVlIHRvIG91dGRhdGVkIFNjYW5Db25maWcKIGF1dGhl
bnRpY2F0aW9uIHNldHRpbmdzLgoKDgoHBAAEAAIDARIDMAQfCg4KBwQABAACAwISAzAiIwpZ
CgYEAAQAAgQSAzMEIRpKIEluZGljYXRlcyBhIHNjYW4gb3BlcmF0aW9uIHRpbWVvdXQsIHVz
dWFsbHkgY2F1c2VkIGJ5IGEgdmVyeSBsYXJnZSBzaXRlLgoKDgoHBAAEAAIEARIDMwQcCg4K
BwQABAACBAISAzMfIAqQAQoGBAAEAAIFEgM3BBsagAEgSW5kaWNhdGVzIHRoYXQgYSBzY2Fu
IGVuY291bnRlcmVkIGV4Y2Vzc2l2ZSByZWRpcmVjdHMsIGVpdGhlciB0bwogYXV0aGVudGlj
YXRpb24gb3Igc29tZSBvdGhlciBwYWdlIG91dHNpZGUgb2YgdGhlIHNjYW4gc2NvcGUuCgoO
CgcEAAQAAgUBEgM3BBYKDgoHBAAEAAIFAhIDNxkaCtcBCgYEAAQAAgYSAzwEHRrHASBJbmRp
Y2F0ZXMgdGhhdCBhIHNjYW4gZW5jb3VudGVyZWQgbnVtZXJvdXMgZXJyb3JzIGZyb20gdGhl
IHdlYiBzaXRlCiBwYWdlcy4gV2hlbiBhdmFpbGFibGUsIG1vc3RfY29tbW9uX2h0dHBfZXJy
b3JfY29kZSBmaWVsZCBpbmRpY2F0ZXMgdGhlCiBtb3N0IGNvbW1vbiBIVFRQIGVycm9yIGNv
ZGUgZW5jb3VudGVyZWQgZHVyaW5nIHRoZSBzY2FuLgoKDgoHBAAEAAIGARIDPAQYCg4KBwQA
BAACBgISAzwbHAovCgQEAAIAEgNAAhAaIiBJbmRpY2F0ZXMgdGhlIGVycm9yIHJlYXNvbiBj
b2RlLgoKDAoFBAACAAYSA0ACBgoMCgUEAAIAARIDQAcLCgwKBQQAAgADEgNADg8KuwEKBAQA
AgESA0UCKBqtASBJZiB0aGUgc2NhbiBlbmNvdW50ZXJzIFNDQU5fQ09ORklHX0lTU1VFIGVy
cm9yLCB0aGlzIGZpZWxkIGhhcyB0aGUgZXJyb3IKIG1lc3NhZ2UgZW5jb3VudGVyZWQgZHVy
aW5nIHNjYW4gY29uZmlndXJhdGlvbiB2YWxpZGF0aW9uIHRoYXQgaXMgcGVyZm9ybWVkCiBi
ZWZvcmUgZWFjaCBzY2FuIHJ1bi4KCgwKBQQAAgEGEgNFAhEKDAoFBAACAQESA0USIwoMCgUE
AAIBAxIDRSYnCuMBCgQEAAICEgNKAiga1QEgSWYgdGhlIHNjYW4gZW5jb3VudGVycyBUT09f
TUFOWV9IVFRQX0VSUk9SUywgdGhpcyBmaWVsZCBpbmRpY2F0ZXMgdGhlIG1vc3QKIGNvbW1v
biBIVFRQIGVycm9yIGNvZGUsIGlmIHN1Y2ggaXMgYXZhaWxhYmxlLiBGb3IgZXhhbXBsZSwg
aWYgdGhpcyBjb2RlIGlzCiA0MDQsIHRoZSBzY2FuIGhhcyBlbmNvdW50ZXJlZCB0b28gbWFu
eSBOT1RfRk9VTkQgcmVzcG9uc2VzLgoKDAoFBAACAgUSA0oCBwoMCgUEAAICARIDSggjCgwK
BQQAAgIDEgNKJidiBnByb3RvMw==
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Websecurityscanner::V1beta::ScanRunErrorTrace::ScanRunErrorTrace ===
    # Fields for ScanRunErrorTrace
    # Field: code Type: 14 (.google.cloud.websecurityscanner.v1beta.ScanRunErrorTrace.Code)
    # Field: scan_config_error Type: 11 (.google.cloud.websecurityscanner.v1beta.ScanConfigError)
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

Google::Cloud::Websecurityscanner::V1beta::ScanRunErrorTrace - Compiled Protocol Buffers messages for google/cloud/websecurityscanner/v1beta/scan_run_error_trace.proto

=head1 SYNOPSIS

    use Google::Cloud::Websecurityscanner::V1beta::ScanRunErrorTrace;

    my $msg = Google::Cloud::Websecurityscanner::V1beta::ScanRunErrorTrace::ScanRunErrorTrace->new({
        code => $code,
        scan_config_error => $scan_config_error,
        most_common_http_error_code => $most_common_http_error_code,
    });

    # Read or update a field
    my $val = $msg->code();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Websecurityscanner::V1beta::ScanRunErrorTrace::ScanRunErrorTrace->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/websecurityscanner/v1beta/scan_run_error_trace.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Websecurityscanner::V1beta::ScanRunErrorTrace::ScanRunErrorTrace

Output only.
Defines an error trace message for a ScanRun.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->code() >> / C<< $msg->code($value) >>

Type: C<Enum> (L<Google::Cloud::Websecurityscanner::V1beta::ScanRunErrorTrace::Code>)

Indicates the error reason code.

=item * C<< $msg->scan_config_error() >> / C<< $msg->scan_config_error($value) >>

Type: C<Message> (L<Google::Cloud::Websecurityscanner::V1beta::ScanConfigError::ScanConfigError>)

If the scan encounters SCAN_CONFIG_ISSUE error, this field has the error
message encountered during scan configuration validation that is performed
before each scan run.

=item * C<< $msg->most_common_http_error_code() >> / C<< $msg->most_common_http_error_code($value) >>

Type: C<Int32>

If the scan encounters TOO_MANY_HTTP_ERRORS, this field indicates the most
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

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Websecurityscanner::V1beta::ScanRunErrorTrace::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
