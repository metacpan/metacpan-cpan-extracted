package Google::Cloud::Websecurityscanner::V1beta::ScanRunWarningTrace;

use strict;
use warnings;

our $VERSION = '0.14';

use Protobuf::Message;
use Protobuf::DescriptorPool;
use Protobuf::Internal qw(:all);
use MIME::Base64;

BEGIN {
    my $descriptor_b64 = <<'EOF';
CkNnb29nbGUvY2xvdWQvd2Vic2VjdXJpdHlzY2FubmVyL3YxYmV0YS9zY2FuX3J1bl93YXJu
aW5nX3RyYWNlLnByb3RvEiZnb29nbGUuY2xvdWQud2Vic2VjdXJpdHlzY2FubmVyLnYxYmV0
YSLzAQoTU2NhblJ1bldhcm5pbmdUcmFjZRJUCgRjb2RlGAEgASgOMkAuZ29vZ2xlLmNsb3Vk
LndlYnNlY3VyaXR5c2Nhbm5lci52MWJldGEuU2NhblJ1bldhcm5pbmdUcmFjZS5Db2RlUgRj
b2RlIoUBCgRDb2RlEhQKEENPREVfVU5TUEVDSUZJRUQQABIeChpJTlNVRkZJQ0lFTlRfQ1JB
V0xfUkVTVUxUUxABEhoKFlRPT19NQU5ZX0NSQVdMX1JFU1VMVFMQAhIXChNUT09fTUFOWV9G
VVpaX1RBU0tTEAMSEgoOQkxPQ0tFRF9CWV9JQVAQBEKiAgoqY29tLmdvb2dsZS5jbG91ZC53
ZWJzZWN1cml0eXNjYW5uZXIudjFiZXRhQhhTY2FuUnVuV2FybmluZ1RyYWNlUHJvdG9QAVpa
Y2xvdWQuZ29vZ2xlLmNvbS9nby93ZWJzZWN1cml0eXNjYW5uZXIvYXBpdjFiZXRhL3dlYnNl
Y3VyaXR5c2Nhbm5lcnBiO3dlYnNlY3VyaXR5c2Nhbm5lcnBiqgImR29vZ2xlLkNsb3VkLldl
YlNlY3VyaXR5U2Nhbm5lci5WMUJldGHKAiZHb29nbGVcQ2xvdWRcV2ViU2VjdXJpdHlTY2Fu
bmVyXFYxYmV0YeoCKUdvb2dsZTo6Q2xvdWQ6OldlYlNlY3VyaXR5U2Nhbm5lcjo6VjFiZXRh
SvsOCgYSBA8AOgEKvQQKAQwSAw8AEjKyBCBDb3B5cmlnaHQgMjAyNSBHb29nbGUgTExDCgog
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
EQAvCggKAQgSAxMAQwoJCgIIJRIDEwBDCggKAQgSAxQAcQoJCgIICxIDFABxCggKAQgSAxUA
IgoJCgIIChIDFQAiCggKAQgSAxYAOQoJCgIICBIDFgA5CggKAQgSAxcAQwoJCgIIARIDFwBD
CggKAQgSAxgAQwoJCgIIKRIDGABDCggKAQgSAxkAQgoJCgIILRIDGQBCCrgBCgIEABIEHgA6
ARqrASBPdXRwdXQgb25seS4KIERlZmluZXMgYSB3YXJuaW5nIHRyYWNlIG1lc3NhZ2UgZm9y
IFNjYW5SdW4uIFdhcm5pbmcgdHJhY2VzIHByb3ZpZGUgY3VzdG9tZXJzCiB3aXRoIHVzZWZ1
bCBpbmZvcm1hdGlvbiB0aGF0IGhlbHBzIG1ha2UgdGhlIHNjYW5uaW5nIHByb2Nlc3MgbW9y
ZSBlZmZlY3RpdmUuCgoKCgMEAAESAx4IGwpJCgQEAAQAEgQiAjYDGjsgT3V0cHV0IG9ubHku
CiBEZWZpbmVzIGEgd2FybmluZyBtZXNzYWdlIGNvZGUuCiBOZXh0IGlkOiA2CgoMCgUEAAQA
ARIDIgcLCi0KBgQABAACABIDJAQZGh4gRGVmYXVsdCB2YWx1ZSBpcyBuZXZlciB1c2VkLgoK
DgoHBAAEAAIAARIDJAQUCg4KBwQABAACAAISAyQXGAq9AQoGBAAEAAIBEgMpBCMarQEgSW5k
aWNhdGVzIHRoYXQgYSBzY2FuIGRpc2NvdmVyZWQgYW4gdW5leHBlY3RlZGx5IGxvdyBudW1i
ZXIgb2YgVVJMcy4gVGhpcwogaXMgc29tZXRpbWVzIGNhdXNlZCBieSBjb21wbGV4IG5hdmln
YXRpb24gZmVhdHVyZXMgb3IgYnkgdXNpbmcgYSBzaW5nbGUKIFVSTCBmb3IgbnVtZXJvdXMg
cGFnZXMuCgoOCgcEAAQAAgEBEgMpBB4KDgoHBAAEAAIBAhIDKSEiCmYKBgQABAACAhIDLQQf
GlcgSW5kaWNhdGVzIHRoYXQgYSBzY2FuIGRpc2NvdmVyZWQgdG9vIG1hbnkgVVJMcyB0byB0
ZXN0LCBvciBleGNlc3NpdmUKIHJlZHVuZGFudCBVUkxzLgoKDgoHBAAEAAICARIDLQQaCg4K
BwQABAACAgISAy0dHgrrAQoGBAAEAAIDEgMyBBwa2wEgSW5kaWNhdGVzIHRoYXQgdG9vIG1h
bnkgdGVzdHMgaGF2ZSBiZWVuIGdlbmVyYXRlZCBmb3IgdGhlIHNjYW4uIEN1c3RvbWVyCiBz
aG91bGQgdHJ5IHJlZHVjaW5nIHRoZSBudW1iZXIgb2Ygc3RhcnRpbmcgVVJMcywgaW5jcmVh
c2luZyB0aGUgUVBTIHJhdGUsCiBvciBuYXJyb3dpbmcgZG93biB0aGUgc2NvcGUgb2YgdGhl
IHNjYW4gdXNpbmcgdGhlIGV4Y2x1ZGVkIHBhdHRlcm5zLgoKDgoHBAAEAAIDARIDMgQXCg4K
BwQABAACAwISAzIaGwo5CgYEAAQAAgQSAzUEFxoqIEluZGljYXRlcyB0aGF0IGEgc2NhbiBp
cyBibG9ja2VkIGJ5IElBUC4KCg4KBwQABAACBAESAzUEEgoOCgcEAAQAAgQCEgM1FRYKKgoE
BAACABIDOQIQGh0gSW5kaWNhdGVzIHRoZSB3YXJuaW5nIGNvZGUuCgoMCgUEAAIABhIDOQIG
CgwKBQQAAgABEgM5BwsKDAoFBAACAAMSAzkOD2IGcHJvdG8z
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Websecurityscanner::V1beta::ScanRunWarningTrace::ScanRunWarningTrace ===
    # Fields for ScanRunWarningTrace
    # Field: code Type: 14 (.google.cloud.websecurityscanner.v1beta.ScanRunWarningTrace.Code)

# Enum: ScanRunWarningTrace::Code
our $ScanRunWarningTrace_CODE_UNSPECIFIED = 0;
our $ScanRunWarningTrace_INSUFFICIENT_CRAWL_RESULTS = 1;
our $ScanRunWarningTrace_TOO_MANY_CRAWL_RESULTS = 2;
our $ScanRunWarningTrace_TOO_MANY_FUZZ_TASKS = 3;
our $ScanRunWarningTrace_BLOCKED_BY_IAP = 4;

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Websecurityscanner::V1beta::ScanRunWarningTrace - Compiled Protocol Buffers messages for google/cloud/websecurityscanner/v1beta/scan_run_warning_trace.proto

=head1 SYNOPSIS

    use Google::Cloud::Websecurityscanner::V1beta::ScanRunWarningTrace;

    my $msg = Google::Cloud::Websecurityscanner::V1beta::ScanRunWarningTrace::ScanRunWarningTrace->new({
        code => $code,
    });

    # Read or update a field
    my $val = $msg->code();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Websecurityscanner::V1beta::ScanRunWarningTrace::ScanRunWarningTrace->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/websecurityscanner/v1beta/scan_run_warning_trace.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Websecurityscanner::V1beta::ScanRunWarningTrace::ScanRunWarningTrace

Output only.
Defines a warning trace message for ScanRun. Warning traces provide customers
with useful information that helps make the scanning process more effective.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->code() >> / C<< $msg->code($value) >>

Type: C<Enum> (L<Google::Cloud::Websecurityscanner::V1beta::ScanRunWarningTrace::Code>)

Indicates the warning code.

=back

=head3 Enum: ScanRunWarningTrace::Code

=over 4

=item * C<CODE_UNSPECIFIED> => C<0>

=item * C<INSUFFICIENT_CRAWL_RESULTS> => C<1>

=item * C<TOO_MANY_CRAWL_RESULTS> => C<2>

=item * C<TOO_MANY_FUZZ_TASKS> => C<3>

=item * C<BLOCKED_BY_IAP> => C<4>

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Websecurityscanner::V1beta::ScanRunWarningTrace::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
