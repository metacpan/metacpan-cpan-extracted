package Google::Compute::Logging::Gdnsusage::V1::GdnsVmUsage;

use strict;
use warnings;

our $VERSION = '0.14';

use Protobuf::Message;
use Protobuf::DescriptorPool;
use Protobuf::Internal qw(:all);
use MIME::Base64;

BEGIN {
    my $descriptor_b64 = <<'EOF';
Cjdnb29nbGUvY29tcHV0ZS9sb2dnaW5nL2dkbnN1c2FnZS92MS9nZG5zX3ZtX3VzYWdlLnBy
b3RvEiNnb29nbGUuY29tcHV0ZS5sb2dnaW5nLmdkbnN1c2FnZS52MSLTAgoWR2Ruc1ZtVXNh
Z2VQbGF0Zm9ybUxvZxJNCglzb3VyY2Vfdm0YASABKAsyKy5nb29nbGUuY29tcHV0ZS5sb2dn
aW5nLmdkbnN1c2FnZS52MS5WbUluZm9IAFIIc291cmNlVm2IAQESVwoOZGVzdGluYXRpb25f
dm0YAiABKAsyKy5nb29nbGUuY29tcHV0ZS5sb2dnaW5nLmdkbnN1c2FnZS52MS5WbUluZm9I
AVINZGVzdGluYXRpb25WbYgBARIoCg1kZWJ1Z19tZXNzYWdlGAMgASgJSAJSDGRlYnVnTWVz
c2FnZYgBARIkCgtxdWVyeV9jb3VudBgFIAEoBUgDUgpxdWVyeUNvdW50iAEBQgwKCl9zb3Vy
Y2Vfdm1CEQoPX2Rlc3RpbmF0aW9uX3ZtQhAKDl9kZWJ1Z19tZXNzYWdlQg4KDF9xdWVyeV9j
b3VudCJ5CgZWbUluZm8SIgoKcHJvamVjdF9pZBgBIAEoCUgAUglwcm9qZWN0SWSIAQESEwoC
dm0YAiABKAlIAVICdm2IAQESFwoEem9uZRgDIAEoCUgCUgR6b25liAEBQg0KC19wcm9qZWN0
X2lkQgUKA192bUIHCgVfem9uZUL9AQojZ29vZ2xlLmNvbXB1dGUubG9nZ2luZy5nZG5zdXNh
Z2UudjFCEEdkbnNWbVVzYWdlUHJvdG9QAVpMZ29vZ2xlLmdvbGFuZy5vcmcvZ2VucHJvdG8v
Z29vZ2xlYXBpcy9jb21wdXRlL2xvZ2dpbmcvZ2Ruc3VzYWdlL3YxO2dkbnN1c2FnZaoCI0dv
b2dsZS5Db21wdXRlLkxvZ2dpbmcuR2Ruc1VzYWdlLlYxygIjR29vZ2xlXENvbXB1dGVcTG9n
Z2luZ1xHZG5zVXNhZ2VcVjHqAidHb29nbGU6OkNvbXB1dGU6OkxvZ2dpbmc6OkdkbnNVc2Fn
ZTo6VjFK3w0KBhIEDgA5AQq8BAoBDBIDDgASMrEEIENvcHlyaWdodCAyMDI1IEdvb2dsZSBM
TEMKCiBMaWNlbnNlZCB1bmRlciB0aGUgQXBhY2hlIExpY2Vuc2UsIFZlcnNpb24gMi4wICh0
aGUgIkxpY2Vuc2UiKTsKIHlvdSBtYXkgbm90IHVzZSB0aGlzIGZpbGUgZXhjZXB0IGluIGNv
bXBsaWFuY2Ugd2l0aCB0aGUgTGljZW5zZS4KIFlvdSBtYXkgb2J0YWluIGEgY29weSBvZiB0
aGUgTGljZW5zZSBhdAoKICAgICBodHRwOi8vd3d3LmFwYWNoZS5vcmcvbGljZW5zZXMvTElD
RU5TRS0yLjAKCiBVbmxlc3MgcmVxdWlyZWQgYnkgYXBwbGljYWJsZSBsYXcgb3IgYWdyZWVk
IHRvIGluIHdyaXRpbmcsIHNvZnR3YXJlCiBkaXN0cmlidXRlZCB1bmRlciB0aGUgTGljZW5z
ZSBpcyBkaXN0cmlidXRlZCBvbiBhbiAiQVMgSVMiIEJBU0lTLAogV0lUSE9VVCBXQVJSQU5U
SUVTIE9SIENPTkRJVElPTlMgT0YgQU5ZIEtJTkQsIGVpdGhlciBleHByZXNzIG9yIGltcGxp
ZWQuCiBTZWUgdGhlIExpY2Vuc2UgZm9yIHRoZSBzcGVjaWZpYyBsYW5ndWFnZSBnb3Zlcm5p
bmcgcGVybWlzc2lvbnMgYW5kCiBsaW1pdGF0aW9ucyB1bmRlciB0aGUgTGljZW5zZS4KCggK
AQISAxAALAoICgEIEgMSAGMKCQoCCAsSAxIAYwoICgEIEgMTACIKCQoCCAoSAxMAIgoICgEI
EgMUADEKCQoCCAgSAxQAMQoICgEIEgMVADwKCQoCCAESAxUAPAoICgEIEgMWAEAKCQoCCCUS
AxYAQAoICgEIEgMXAEEKCQoCCCkSAxcAQQoICgEIEgMYAEAKCQoCCC0SAxgAQAqtAQoCBAAS
BB8ALQEaOSBVc2VkIGZvciBzdHJ1Y3R1cmVkIHBheWxvYWQgZm9yIHJlcG9ydGluZyBQbGF0
Zm9ybSBMb2dzCjJmIGdkbnNfdm1fdXNhZ2UucHJvdG8KIERlZmluaXRpb24gb2YganNvbl9w
YXlsb2FkIG9mIEdsb2JhbCBEbnMgdXNhZ2UgcGVyLXZtIGxldmVsIGZvcgogUGxhdGZvcm0g
TG9ncy4KCgoKAwQAARIDHwgeCiYKBAQAAgASAyECIBoZIHNvdXJjZSB2bSdzIGluZm9ybWF0
aW9uCgoMCgUEAAIABBIDIQIKCgwKBQQAAgAGEgMhCxEKDAoFBAACAAESAyESGwoMCgUEAAIA
AxIDIR4fCisKBAQAAgESAyQCJRoeIGRlc3RpbmF0aW9uIHZtJ3MgaW5mb3JtYXRpb24KCgwK
BQQAAgEEEgMkAgoKDAoFBAACAQYSAyQLEQoMCgUEAAIBARIDJBIgCgwKBQQAAgEDEgMkIyQK
dgoEBAACAhIDKAIkGmkgbWVzc2FnZSB0aGF0IGluZm9ybXMgdXNlcnMgb24gaG93IHRvIGZp
eCB0aGUgZ2xvYmFsIEROUyBxdWVyeSB0aGF0IGlzCiBibG9ja2luZyB0aGUgem9uYWwgRE5T
IG1pZ3JhdGlvbgoKDAoFBAACAgQSAygCCgoMCgUEAAICBRIDKAsRCgwKBQQAAgIBEgMoEh8K
DAoFBAACAgMSAygiIwpfCgQEAAIDEgMsAiEaUiBudW1iZXIgb2YgekROUyBtaWdyYXRpb24g
YmxvY2tpbmcgcXVlcmllcyBzZW50IGZyb20gc291cmNlX3ZtIHRvCiBkZXN0aW5hdGlvbl92
bQoKDAoFBAACAwQSAywCCgoMCgUEAAIDBRIDLAsQCgwKBQQAAgMBEgMsERwKDAoFBAACAwMS
AywfIAoYCgIEARIEMAA5ARoMIFZNIGRldGFpbHMKCgoKAwQBARIDMAgOCiMKBAQBAgASAzIC
IRoWIHByb2plY3QgaWQgb2YgdGhlIHZtCgoMCgUEAQIABBIDMgIKCgwKBQQBAgAFEgMyCxEK
DAoFBAECAAESAzISHAoMCgUEAQIAAxIDMh8gCh0KBAQBAgESAzUCGRoQIG5hbWUgb2YgdGhl
IHZtCgoMCgUEAQIBBBIDNQIKCgwKBQQBAgEFEgM1CxEKDAoFBAECAQESAzUSFAoMCgUEAQIB
AxIDNRcYCh0KBAQBAgISAzgCGxoQIHpvbmUgb2YgdGhlIHZtCgoMCgUEAQICBBIDOAIKCgwK
BQQBAgIFEgM4CxEKDAoFBAECAgESAzgSFgoMCgUEAQICAxIDOBkaYgZwcm90bzM=
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Compute::Logging::Gdnsusage::V1::GdnsVmUsage::GdnsVmUsagePlatformLog ===
    # Fields for GdnsVmUsagePlatformLog
    # Field: source_vm Type: 11 (.google.compute.logging.gdnsusage.v1.VmInfo)
    # Field: destination_vm Type: 11 (.google.compute.logging.gdnsusage.v1.VmInfo)
    # Field: debug_message Type: 9 ()
    # Field: query_count Type: 5 ()

# === Message: Google::Compute::Logging::Gdnsusage::V1::GdnsVmUsage::VmInfo ===
    # Fields for VmInfo
    # Field: project_id Type: 9 ()
    # Field: vm Type: 9 ()
    # Field: zone Type: 9 ()

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Compute::Logging::Gdnsusage::V1::GdnsVmUsage - Compiled Protocol Buffers messages for google/compute/logging/gdnsusage/v1/gdns_vm_usage.proto

=head1 SYNOPSIS

    use Google::Compute::Logging::Gdnsusage::V1::GdnsVmUsage;

    my $msg = Google::Compute::Logging::Gdnsusage::V1::GdnsVmUsage::GdnsVmUsagePlatformLog->new({
        source_vm => $source_vm,
        destination_vm => $destination_vm,
        debug_message => $debug_message,
        query_count => $query_count,
    });

    # Read or update a field
    my $val = $msg->source_vm();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Compute::Logging::Gdnsusage::V1::GdnsVmUsage::GdnsVmUsagePlatformLog->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/compute/logging/gdnsusage/v1/gdns_vm_usage.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Compute::Logging::Gdnsusage::V1::GdnsVmUsage::GdnsVmUsagePlatformLog

Used for structured payload for reporting Platform Logs

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->source_vm() >> / C<< $msg->source_vm($value) >>

Type: C<Message> (L<Google::Compute::Logging::Gdnsusage::V1::GdnsVmUsage::VmInfo>)

source vm's information

=item * C<< $msg->destination_vm() >> / C<< $msg->destination_vm($value) >>

Type: C<Message> (L<Google::Compute::Logging::Gdnsusage::V1::GdnsVmUsage::VmInfo>)

destination vm's information

=item * C<< $msg->debug_message() >> / C<< $msg->debug_message($value) >>

Type: C<String>

message that informs users on how to fix the global DNS query that is
blocking the zonal DNS migration

=item * C<< $msg->query_count() >> / C<< $msg->query_count($value) >>

Type: C<Int32>

number of zDNS migration blocking queries sent from source_vm to
destination_vm

=back

=head2 Google::Compute::Logging::Gdnsusage::V1::GdnsVmUsage::VmInfo

VM details

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->project_id() >> / C<< $msg->project_id($value) >>

Type: C<String>

project id of the vm

=item * C<< $msg->vm() >> / C<< $msg->vm($value) >>

Type: C<String>

name of the vm

=item * C<< $msg->zone() >> / C<< $msg->zone($value) >>

Type: C<String>

zone of the vm

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Compute::Logging::Gdnsusage::V1::GdnsVmUsage::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
