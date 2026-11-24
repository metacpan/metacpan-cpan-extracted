package Google::Cloud::Websecurityscanner::V1::ScanRunWarningTrace;

use strict;
use warnings;

our $VERSION = '0.14';

use Protobuf::Message;
use Protobuf::DescriptorPool;
use Protobuf::Internal qw(:all);
use MIME::Base64;

BEGIN {
    my $descriptor_b64 = <<'EOF';
Cj9nb29nbGUvY2xvdWQvd2Vic2VjdXJpdHlzY2FubmVyL3YxL3NjYW5fcnVuX3dhcm5pbmdf
dHJhY2UucHJvdG8SImdvb2dsZS5jbG91ZC53ZWJzZWN1cml0eXNjYW5uZXIudjEimwIKE1Nj
YW5SdW5XYXJuaW5nVHJhY2USUAoEY29kZRgBIAEoDjI8Lmdvb2dsZS5jbG91ZC53ZWJzZWN1
cml0eXNjYW5uZXIudjEuU2NhblJ1bldhcm5pbmdUcmFjZS5Db2RlUgRjb2RlIrEBCgRDb2Rl
EhQKEENPREVfVU5TUEVDSUZJRUQQABIeChpJTlNVRkZJQ0lFTlRfQ1JBV0xfUkVTVUxUUxAB
EhoKFlRPT19NQU5ZX0NSQVdMX1JFU1VMVFMQAhIXChNUT09fTUFOWV9GVVpaX1RBU0tTEAMS
EgoOQkxPQ0tFRF9CWV9JQVAQBBIqCiZOT19TVEFSVElOR19VUkxfRk9VTkRfRk9SX01BTkFH
RURfU0NBThAFQo4CCiZjb20uZ29vZ2xlLmNsb3VkLndlYnNlY3VyaXR5c2Nhbm5lci52MUIY
U2NhblJ1bldhcm5pbmdUcmFjZVByb3RvUAFaVmNsb3VkLmdvb2dsZS5jb20vZ28vd2Vic2Vj
dXJpdHlzY2FubmVyL2FwaXYxL3dlYnNlY3VyaXR5c2Nhbm5lcnBiO3dlYnNlY3VyaXR5c2Nh
bm5lcnBiqgIiR29vZ2xlLkNsb3VkLldlYlNlY3VyaXR5U2Nhbm5lci5WMcoCIkdvb2dsZVxD
bG91ZFxXZWJTZWN1cml0eVNjYW5uZXJcVjHqAiVHb29nbGU6OkNsb3VkOjpXZWJTZWN1cml0
eVNjYW5uZXI6OlYxSuUPCgYSBA4APAEKvAQKAQwSAw4AEjKxBCBDb3B5cmlnaHQgMjAyNSBH
b29nbGUgTExDCgogTGljZW5zZWQgdW5kZXIgdGhlIEFwYWNoZSBMaWNlbnNlLCBWZXJzaW9u
IDIuMCAodGhlICJMaWNlbnNlIik7CiB5b3UgbWF5IG5vdCB1c2UgdGhpcyBmaWxlIGV4Y2Vw
dCBpbiBjb21wbGlhbmNlIHdpdGggdGhlIExpY2Vuc2UuCiBZb3UgbWF5IG9idGFpbiBhIGNv
cHkgb2YgdGhlIExpY2Vuc2UgYXQKCiAgICAgaHR0cDovL3d3dy5hcGFjaGUub3JnL2xpY2Vu
c2VzL0xJQ0VOU0UtMi4wCgogVW5sZXNzIHJlcXVpcmVkIGJ5IGFwcGxpY2FibGUgbGF3IG9y
IGFncmVlZCB0byBpbiB3cml0aW5nLCBzb2Z0d2FyZQogZGlzdHJpYnV0ZWQgdW5kZXIgdGhl
IExpY2Vuc2UgaXMgZGlzdHJpYnV0ZWQgb24gYW4gIkFTIElTIiBCQVNJUywKIFdJVEhPVVQg
V0FSUkFOVElFUyBPUiBDT05ESVRJT05TIE9GIEFOWSBLSU5ELCBlaXRoZXIgZXhwcmVzcyBv
ciBpbXBsaWVkLgogU2VlIHRoZSBMaWNlbnNlIGZvciB0aGUgc3BlY2lmaWMgbGFuZ3VhZ2Ug
Z292ZXJuaW5nIHBlcm1pc3Npb25zIGFuZAogbGltaXRhdGlvbnMgdW5kZXIgdGhlIExpY2Vu
c2UuCgoICgECEgMQACsKCAoBCBIDEgA/CgkKAgglEgMSAD8KCAoBCBIDEwBtCgkKAggLEgMT
AG0KCAoBCBIDFAAiCgkKAggKEgMUACIKCAoBCBIDFQA5CgkKAggIEgMVADkKCAoBCBIDFgA/
CgkKAggBEgMWAD8KCAoBCBIDFwA/CgkKAggpEgMXAD8KCAoBCBIDGAA+CgkKAggtEgMYAD4K
uAEKAgQAEgQdADwBGqsBIE91dHB1dCBvbmx5LgogRGVmaW5lcyBhIHdhcm5pbmcgdHJhY2Ug
bWVzc2FnZSBmb3IgU2NhblJ1bi4gV2FybmluZyB0cmFjZXMgcHJvdmlkZSBjdXN0b21lcnMK
IHdpdGggdXNlZnVsIGluZm9ybWF0aW9uIHRoYXQgaGVscHMgbWFrZSB0aGUgc2Nhbm5pbmcg
cHJvY2VzcyBtb3JlIGVmZmVjdGl2ZS4KCgoKAwQAARIDHQgbCkkKBAQABAASBCECOAMaOyBP
dXRwdXQgb25seS4KIERlZmluZXMgYSB3YXJuaW5nIG1lc3NhZ2UgY29kZS4KIE5leHQgaWQ6
IDYKCgwKBQQABAABEgMhBwsKLQoGBAAEAAIAEgMjBBkaHiBEZWZhdWx0IHZhbHVlIGlzIG5l
dmVyIHVzZWQuCgoOCgcEAAQAAgABEgMjBBQKDgoHBAAEAAIAAhIDIxcYCr0BCgYEAAQAAgES
AygEIxqtASBJbmRpY2F0ZXMgdGhhdCBhIHNjYW4gZGlzY292ZXJlZCBhbiB1bmV4cGVjdGVk
bHkgbG93IG51bWJlciBvZiBVUkxzLiBUaGlzCiBpcyBzb21ldGltZXMgY2F1c2VkIGJ5IGNv
bXBsZXggbmF2aWdhdGlvbiBmZWF0dXJlcyBvciBieSB1c2luZyBhIHNpbmdsZQogVVJMIGZv
ciBudW1lcm91cyBwYWdlcy4KCg4KBwQABAACAQESAygEHgoOCgcEAAQAAgECEgMoISIKZgoG
BAAEAAICEgMsBB8aVyBJbmRpY2F0ZXMgdGhhdCBhIHNjYW4gZGlzY292ZXJlZCB0b28gbWFu
eSBVUkxzIHRvIHRlc3QsIG9yIGV4Y2Vzc2l2ZQogcmVkdW5kYW50IFVSTHMuCgoOCgcEAAQA
AgIBEgMsBBoKDgoHBAAEAAICAhIDLB0eCusBCgYEAAQAAgMSAzEEHBrbASBJbmRpY2F0ZXMg
dGhhdCB0b28gbWFueSB0ZXN0cyBoYXZlIGJlZW4gZ2VuZXJhdGVkIGZvciB0aGUgc2Nhbi4g
Q3VzdG9tZXIKIHNob3VsZCB0cnkgcmVkdWNpbmcgdGhlIG51bWJlciBvZiBzdGFydGluZyBV
UkxzLCBpbmNyZWFzaW5nIHRoZSBRUFMgcmF0ZSwKIG9yIG5hcnJvd2luZyBkb3duIHRoZSBz
Y29wZSBvZiB0aGUgc2NhbiB1c2luZyB0aGUgZXhjbHVkZWQgcGF0dGVybnMuCgoOCgcEAAQA
AgMBEgMxBBcKDgoHBAAEAAIDAhIDMRobCjkKBgQABAACBBIDNAQXGiogSW5kaWNhdGVzIHRo
YXQgYSBzY2FuIGlzIGJsb2NrZWQgYnkgSUFQLgoKDgoHBAAEAAIEARIDNAQSCg4KBwQABAAC
BAISAzQVFgo8CgYEAAQAAgUSAzcELxotIEluZGljYXRlcyB0aGF0IG5vIHNlZWRzIGlzIGZv
dW5kIGZvciBhIHNjYW4KCg4KBwQABAACBQESAzcEKgoOCgcEAAQAAgUCEgM3LS4KNwoEBAAC
ABIDOwIQGiogT3V0cHV0IG9ubHkuIEluZGljYXRlcyB0aGUgd2FybmluZyBjb2RlLgoKDAoF
BAACAAYSAzsCBgoMCgUEAAIAARIDOwcLCgwKBQQAAgADEgM7Dg9iBnByb3RvMw==
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Websecurityscanner::V1::ScanRunWarningTrace::ScanRunWarningTrace ===
    # Fields for ScanRunWarningTrace
    # Field: code Type: 14 (.google.cloud.websecurityscanner.v1.ScanRunWarningTrace.Code)

# Enum: ScanRunWarningTrace::Code
our $ScanRunWarningTrace_CODE_UNSPECIFIED = 0;
our $ScanRunWarningTrace_INSUFFICIENT_CRAWL_RESULTS = 1;
our $ScanRunWarningTrace_TOO_MANY_CRAWL_RESULTS = 2;
our $ScanRunWarningTrace_TOO_MANY_FUZZ_TASKS = 3;
our $ScanRunWarningTrace_BLOCKED_BY_IAP = 4;
our $ScanRunWarningTrace_NO_STARTING_URL_FOUND_FOR_MANAGED_SCAN = 5;

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Websecurityscanner::V1::ScanRunWarningTrace - Compiled Protocol Buffers messages for google/cloud/websecurityscanner/v1/scan_run_warning_trace.proto

=head1 SYNOPSIS

    use Google::Cloud::Websecurityscanner::V1::ScanRunWarningTrace;

    my $msg = Google::Cloud::Websecurityscanner::V1::ScanRunWarningTrace::ScanRunWarningTrace->new({
        code => $code,
    });

    # Read or update a field
    my $val = $msg->code();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Websecurityscanner::V1::ScanRunWarningTrace::ScanRunWarningTrace->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/websecurityscanner/v1/scan_run_warning_trace.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Websecurityscanner::V1::ScanRunWarningTrace::ScanRunWarningTrace

Output only.
Defines a warning trace message for ScanRun. Warning traces provide customers
with useful information that helps make the scanning process more effective.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->code() >> / C<< $msg->code($value) >>

Type: C<Enum> (L<Google::Cloud::Websecurityscanner::V1::ScanRunWarningTrace::Code>)

Output only. Indicates the warning code.

=back

=head3 Enum: ScanRunWarningTrace::Code

=over 4

=item * C<CODE_UNSPECIFIED> => C<0>

=item * C<INSUFFICIENT_CRAWL_RESULTS> => C<1>

=item * C<TOO_MANY_CRAWL_RESULTS> => C<2>

=item * C<TOO_MANY_FUZZ_TASKS> => C<3>

=item * C<BLOCKED_BY_IAP> => C<4>

=item * C<NO_STARTING_URL_FOUND_FOR_MANAGED_SCAN> => C<5>

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Websecurityscanner::V1::ScanRunWarningTrace::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
