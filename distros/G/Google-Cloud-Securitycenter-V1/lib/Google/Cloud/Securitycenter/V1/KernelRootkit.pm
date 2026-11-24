package Google::Cloud::Securitycenter::V1::KernelRootkit;

use strict;
use warnings;

our $VERSION = '0.14';

use Protobuf::Message;
use Protobuf::DescriptorPool;
use Protobuf::Internal qw(:all);
use MIME::Base64;

BEGIN {
    my $descriptor_b64 = <<'EOF';
CjNnb29nbGUvY2xvdWQvc2VjdXJpdHljZW50ZXIvdjEva2VybmVsX3Jvb3RraXQucHJvdG8S
Hmdvb2dsZS5jbG91ZC5zZWN1cml0eWNlbnRlci52MSLCBAoNS2VybmVsUm9vdGtpdBISCgRu
YW1lGAEgASgJUgRuYW1lEkAKHHVuZXhwZWN0ZWRfY29kZV9tb2RpZmljYXRpb24YAiABKAhS
GnVuZXhwZWN0ZWRDb2RlTW9kaWZpY2F0aW9uElIKJnVuZXhwZWN0ZWRfcmVhZF9vbmx5X2Rh
dGFfbW9kaWZpY2F0aW9uGAMgASgIUiJ1bmV4cGVjdGVkUmVhZE9ubHlEYXRhTW9kaWZpY2F0
aW9uEjoKGXVuZXhwZWN0ZWRfZnRyYWNlX2hhbmRsZXIYBCABKAhSF3VuZXhwZWN0ZWRGdHJh
Y2VIYW5kbGVyEjoKGXVuZXhwZWN0ZWRfa3Byb2JlX2hhbmRsZXIYBSABKAhSF3VuZXhwZWN0
ZWRLcHJvYmVIYW5kbGVyEj8KHHVuZXhwZWN0ZWRfa2VybmVsX2NvZGVfcGFnZXMYBiABKAhS
GXVuZXhwZWN0ZWRLZXJuZWxDb2RlUGFnZXMSQwoedW5leHBlY3RlZF9zeXN0ZW1fY2FsbF9o
YW5kbGVyGAcgASgIUht1bmV4cGVjdGVkU3lzdGVtQ2FsbEhhbmRsZXISQAocdW5leHBlY3Rl
ZF9pbnRlcnJ1cHRfaGFuZGxlchgIIAEoCFIadW5leHBlY3RlZEludGVycnVwdEhhbmRsZXIS
RwogdW5leHBlY3RlZF9wcm9jZXNzZXNfaW5fcnVucXVldWUYCSABKAhSHXVuZXhwZWN0ZWRQ
cm9jZXNzZXNJblJ1bnF1ZXVlQuwBCiJjb20uZ29vZ2xlLmNsb3VkLnNlY3VyaXR5Y2VudGVy
LnYxQhJLZXJuZWxSb290a2l0UHJvdG9QAVpKY2xvdWQuZ29vZ2xlLmNvbS9nby9zZWN1cml0
eWNlbnRlci9hcGl2MS9zZWN1cml0eWNlbnRlcnBiO3NlY3VyaXR5Y2VudGVycGKqAh5Hb29n
bGUuQ2xvdWQuU2VjdXJpdHlDZW50ZXIuVjHKAh5Hb29nbGVcQ2xvdWRcU2VjdXJpdHlDZW50
ZXJcVjHqAiFHb29nbGU6OkNsb3VkOjpTZWN1cml0eUNlbnRlcjo6VjFKphEKBhIEDgA9AQq8
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
CiBsaW1pdGF0aW9ucyB1bmRlciB0aGUgTGljZW5zZS4KCggKAQISAxAAJwoICgEIEgMSADsK
CQoCCCUSAxIAOwoICgEIEgMTAGEKCQoCCAsSAxMAYQoICgEIEgMUACIKCQoCCAoSAxQAIgoI
CgEIEgMVADMKCQoCCAgSAxUAMwoICgEIEgMWADsKCQoCCAESAxYAOwoICgEIEgMXADsKCQoC
CCkSAxcAOwoICgEIEgMYADoKCQoCCC0SAxgAOgotCgIEABIEGwA9ARohIEtlcm5lbCBtb2Rl
IHJvb3RraXQgc2lnbmF0dXJlcy4KCgoKAwQAARIDGwgVCiwKBAQAAgASAx0CEhofIFJvb3Rr
aXQgbmFtZSwgd2hlbiBhdmFpbGFibGUuCgoMCgUEAAIABRIDHQIICgwKBQQAAgABEgMdCQ0K
DAoFBAACAAMSAx0QEQpSCgQEAAIBEgMgAigaRSBUcnVlIGlmIHVuZXhwZWN0ZWQgbW9kaWZp
Y2F0aW9ucyBvZiBrZXJuZWwgY29kZSBtZW1vcnkgYXJlIHByZXNlbnQuCgoMCgUEAAIBBRID
IAIGCgwKBQQAAgEBEgMgByMKDAoFBAACAQMSAyAmJwpdCgQEAAICEgMkAjIaUCBUcnVlIGlm
IHVuZXhwZWN0ZWQgbW9kaWZpY2F0aW9ucyBvZiBrZXJuZWwgcmVhZC1vbmx5IGRhdGEgbWVt
b3J5IGFyZQogcHJlc2VudC4KCgwKBQQAAgIFEgMkAgYKDAoFBAACAgESAyQHLQoMCgUEAAIC
AxIDJDAxCpEBCgQEAAIDEgMoAiUagwEgVHJ1ZSBpZiBgZnRyYWNlYCBwb2ludHMgYXJlIHBy
ZXNlbnQgd2l0aCBjYWxsYmFja3MgcG9pbnRpbmcgdG8gcmVnaW9ucwogdGhhdCBhcmUgbm90
IGluIHRoZSBleHBlY3RlZCBrZXJuZWwgb3IgbW9kdWxlIGNvZGUgcmFuZ2UuCgoMCgUEAAID
BRIDKAIGCgwKBQQAAgMBEgMoByAKDAoFBAACAwMSAygjJAqRAQoEBAACBBIDLAIlGoMBIFRy
dWUgaWYgYGtwcm9iZWAgcG9pbnRzIGFyZSBwcmVzZW50IHdpdGggY2FsbGJhY2tzIHBvaW50
aW5nIHRvIHJlZ2lvbnMKIHRoYXQgYXJlIG5vdCBpbiB0aGUgZXhwZWN0ZWQga2VybmVsIG9y
IG1vZHVsZSBjb2RlIHJhbmdlLgoKDAoFBAACBAUSAywCBgoMCgUEAAIEARIDLAcgCgwKBQQA
AgQDEgMsIyQKcQoEBAACBRIDMAIoGmQgVHJ1ZSBpZiBrZXJuZWwgY29kZSBwYWdlcyB0aGF0
IGFyZSBub3QgaW4gdGhlIGV4cGVjdGVkIGtlcm5lbCBvciBtb2R1bGUKIGNvZGUgcmVnaW9u
cyBhcmUgcHJlc2VudC4KCgwKBQQAAgUFEgMwAgYKDAoFBAACBQESAzAHIwoMCgUEAAIFAxID
MCYnCngKBAQAAgYSAzQCKhprIFRydWUgaWYgc3lzdGVtIGNhbGwgaGFuZGxlcnMgdGhhdCBh
cmUgYXJlIG5vdCBpbiB0aGUgZXhwZWN0ZWQga2VybmVsIG9yCiBtb2R1bGUgY29kZSByZWdp
b25zIGFyZSBwcmVzZW50LgoKDAoFBAACBgUSAzQCBgoMCgUEAAIGARIDNAclCgwKBQQAAgYD
EgM0KCkKdgoEBAACBxIDOAIoGmkgVHJ1ZSBpZiBpbnRlcnJ1cHQgaGFuZGxlcnMgdGhhdCBh
cmUgYXJlIG5vdCBpbiB0aGUgZXhwZWN0ZWQga2VybmVsIG9yCiBtb2R1bGUgY29kZSByZWdp
b25zIGFyZSBwcmVzZW50LgoKDAoFBAACBwUSAzgCBgoMCgUEAAIHARIDOAcjCgwKBQQAAgcD
EgM4JicKnAEKBAQAAggSAzwCLBqOASBUcnVlIGlmIHVuZXhwZWN0ZWQgcHJvY2Vzc2VzIGlu
IHRoZSBzY2hlZHVsZXIgcnVuIHF1ZXVlIGFyZSBwcmVzZW50LiBTdWNoCiBwcm9jZXNzZXMg
YXJlIGluIHRoZSBydW4gcXVldWUsIGJ1dCBub3QgaW4gdGhlIHByb2Nlc3MgdGFzayBsaXN0
LgoKDAoFBAACCAUSAzwCBgoMCgUEAAIIARIDPAcnCgwKBQQAAggDEgM8KitiBnByb3RvMw==

EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Securitycenter::V1::KernelRootkit::KernelRootkit ===
    # Fields for KernelRootkit
    # Field: name Type: 9 ()
    # Field: unexpected_code_modification Type: 8 ()
    # Field: unexpected_read_only_data_modification Type: 8 ()
    # Field: unexpected_ftrace_handler Type: 8 ()
    # Field: unexpected_kprobe_handler Type: 8 ()
    # Field: unexpected_kernel_code_pages Type: 8 ()
    # Field: unexpected_system_call_handler Type: 8 ()
    # Field: unexpected_interrupt_handler Type: 8 ()
    # Field: unexpected_processes_in_runqueue Type: 8 ()

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Securitycenter::V1::KernelRootkit - Compiled Protocol Buffers messages for google/cloud/securitycenter/v1/kernel_rootkit.proto

=head1 SYNOPSIS

    use Google::Cloud::Securitycenter::V1::KernelRootkit;

    my $msg = Google::Cloud::Securitycenter::V1::KernelRootkit::KernelRootkit->new({
        name => $name,
        unexpected_code_modification => $unexpected_code_modification,
        unexpected_read_only_data_modification => $unexpected_read_only_data_modification,
        unexpected_ftrace_handler => $unexpected_ftrace_handler,
    });

    # Read or update a field
    my $val = $msg->name();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Securitycenter::V1::KernelRootkit::KernelRootkit->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/securitycenter/v1/kernel_rootkit.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Securitycenter::V1::KernelRootkit::KernelRootkit

Kernel mode rootkit signatures.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Rootkit name, when available.

=item * C<< $msg->unexpected_code_modification() >> / C<< $msg->unexpected_code_modification($value) >>

Type: C<Bool>

True if unexpected modifications of kernel code memory are present.

=item * C<< $msg->unexpected_read_only_data_modification() >> / C<< $msg->unexpected_read_only_data_modification($value) >>

Type: C<Bool>

True if unexpected modifications of kernel read-only data memory are
present.

=item * C<< $msg->unexpected_ftrace_handler() >> / C<< $msg->unexpected_ftrace_handler($value) >>

Type: C<Bool>

True if `ftrace` points are present with callbacks pointing to regions
that are not in the expected kernel or module code range.

=item * C<< $msg->unexpected_kprobe_handler() >> / C<< $msg->unexpected_kprobe_handler($value) >>

Type: C<Bool>

True if `kprobe` points are present with callbacks pointing to regions
that are not in the expected kernel or module code range.

=item * C<< $msg->unexpected_kernel_code_pages() >> / C<< $msg->unexpected_kernel_code_pages($value) >>

Type: C<Bool>

True if kernel code pages that are not in the expected kernel or module
code regions are present.

=item * C<< $msg->unexpected_system_call_handler() >> / C<< $msg->unexpected_system_call_handler($value) >>

Type: C<Bool>

True if system call handlers that are are not in the expected kernel or
module code regions are present.

=item * C<< $msg->unexpected_interrupt_handler() >> / C<< $msg->unexpected_interrupt_handler($value) >>

Type: C<Bool>

True if interrupt handlers that are are not in the expected kernel or
module code regions are present.

=item * C<< $msg->unexpected_processes_in_runqueue() >> / C<< $msg->unexpected_processes_in_runqueue($value) >>

Type: C<Bool>

True if unexpected processes in the scheduler run queue are present. Such
processes are in the run queue, but not in the process task list.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Securitycenter::V1::KernelRootkit::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
