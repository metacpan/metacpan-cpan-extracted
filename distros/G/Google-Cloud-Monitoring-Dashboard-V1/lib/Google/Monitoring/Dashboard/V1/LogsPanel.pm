package Google::Monitoring::Dashboard::V1::LogsPanel;

use strict;
use warnings;

our $VERSION = '0.14';

use Protobuf::Message;
use Protobuf::DescriptorPool;
use Protobuf::Internal qw(:all);
use MIME::Base64;

BEGIN {
    my $descriptor_b64 = <<'EOF';
Ci9nb29nbGUvbW9uaXRvcmluZy9kYXNoYm9hcmQvdjEvbG9nc19wYW5lbC5wcm90bxIeZ29v
Z2xlLm1vbml0b3JpbmcuZGFzaGJvYXJkLnYxIkoKCUxvZ3NQYW5lbBIWCgZmaWx0ZXIYASAB
KAlSBmZpbHRlchIlCg5yZXNvdXJjZV9uYW1lcxgCIAMoCVINcmVzb3VyY2VOYW1lc0L3AQoi
Y29tLmdvb2dsZS5tb25pdG9yaW5nLmRhc2hib2FyZC52MUIOTG9nc1BhbmVsUHJvdG9QAVpG
Y2xvdWQuZ29vZ2xlLmNvbS9nby9tb25pdG9yaW5nL2Rhc2hib2FyZC9hcGl2MS9kYXNoYm9h
cmRwYjtkYXNoYm9hcmRwYqoCJEdvb2dsZS5DbG91ZC5Nb25pdG9yaW5nLkRhc2hib2FyZC5W
McoCJEdvb2dsZVxDbG91ZFxNb25pdG9yaW5nXERhc2hib2FyZFxWMeoCKEdvb2dsZTo6Q2xv
dWQ6Ok1vbml0b3Jpbmc6OkRhc2hib2FyZDo6VjFKsAoKBhIEDgAlAQq8BAoBDBIDDgASMrEE
IENvcHlyaWdodCAyMDI1IEdvb2dsZSBMTEMKCiBMaWNlbnNlZCB1bmRlciB0aGUgQXBhY2hl
IExpY2Vuc2UsIFZlcnNpb24gMi4wICh0aGUgIkxpY2Vuc2UiKTsKIHlvdSBtYXkgbm90IHVz
ZSB0aGlzIGZpbGUgZXhjZXB0IGluIGNvbXBsaWFuY2Ugd2l0aCB0aGUgTGljZW5zZS4KIFlv
dSBtYXkgb2J0YWluIGEgY29weSBvZiB0aGUgTGljZW5zZSBhdAoKICAgICBodHRwOi8vd3d3
LmFwYWNoZS5vcmcvbGljZW5zZXMvTElDRU5TRS0yLjAKCiBVbmxlc3MgcmVxdWlyZWQgYnkg
YXBwbGljYWJsZSBsYXcgb3IgYWdyZWVkIHRvIGluIHdyaXRpbmcsIHNvZnR3YXJlCiBkaXN0
cmlidXRlZCB1bmRlciB0aGUgTGljZW5zZSBpcyBkaXN0cmlidXRlZCBvbiBhbiAiQVMgSVMi
IEJBU0lTLAogV0lUSE9VVCBXQVJSQU5USUVTIE9SIENPTkRJVElPTlMgT0YgQU5ZIEtJTkQs
IGVpdGhlciBleHByZXNzIG9yIGltcGxpZWQuCiBTZWUgdGhlIExpY2Vuc2UgZm9yIHRoZSBz
cGVjaWZpYyBsYW5ndWFnZSBnb3Zlcm5pbmcgcGVybWlzc2lvbnMgYW5kCiBsaW1pdGF0aW9u
cyB1bmRlciB0aGUgTGljZW5zZS4KCggKAQISAxAAJwoICgEIEgMSAEEKCQoCCCUSAxIAQQoI
CgEIEgMTAF0KCQoCCAsSAxMAXQoICgEIEgMUACIKCQoCCAoSAxQAIgoICgEIEgMVAC8KCQoC
CAgSAxUALwoICgEIEgMWADsKCQoCCAESAxYAOwoICgEIEgMXAEIKCQoCCCkSAxcAQgoICgEI
EgMYAEEKCQoCCC0SAxgAQQo1CgIEABIEGwAlARopIEEgd2lkZ2V0IHRoYXQgZGlzcGxheXMg
YSBzdHJlYW0gb2YgbG9nLgoKCgoDBAABEgMbCBEK/wEKBAQAAgASAyACFBrxASBBIGZpbHRl
ciB0aGF0IGNob29zZXMgd2hpY2ggbG9nIGVudHJpZXMgdG8gcmV0dXJuLiAgU2VlIFtBZHZh
bmNlZCBMb2dzCiBRdWVyaWVzXShodHRwczovL2Nsb3VkLmdvb2dsZS5jb20vbG9nZ2luZy9k
b2NzL3ZpZXcvYWR2YW5jZWQtcXVlcmllcykuCiBPbmx5IGxvZyBlbnRyaWVzIHRoYXQgbWF0
Y2ggdGhlIGZpbHRlciBhcmUgcmV0dXJuZWQuICBBbiBlbXB0eSBmaWx0ZXIKIG1hdGNoZXMg
YWxsIGxvZyBlbnRyaWVzLgoKDAoFBAACAAUSAyACCAoMCgUEAAIAARIDIAkPCgwKBQQAAgAD
EgMgEhMKogEKBAQAAgESAyQCJRqUASBUaGUgbmFtZXMgb2YgbG9nZ2luZyByZXNvdXJjZXMg
dG8gY29sbGVjdCBsb2dzIGZvci4gQ3VycmVudGx5IG9ubHkgcHJvamVjdHMKIGFyZSBzdXBw
b3J0ZWQuIElmIGVtcHR5LCB0aGUgd2lkZ2V0IHdpbGwgZGVmYXVsdCB0byB0aGUgaG9zdCBw
cm9qZWN0LgoKDAoFBAACAQQSAyQCCgoMCgUEAAIBBRIDJAsRCgwKBQQAAgEBEgMkEiAKDAoF
BAACAQMSAyQjJGIGcHJvdG8z
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Monitoring::Dashboard::V1::LogsPanel::LogsPanel ===
    # Fields for LogsPanel
    # Field: filter Type: 9 ()
    # Field: resource_names Type: 9 ()

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Monitoring::Dashboard::V1::LogsPanel - Compiled Protocol Buffers messages for google/monitoring/dashboard/v1/logs_panel.proto

=head1 SYNOPSIS

    use Google::Monitoring::Dashboard::V1::LogsPanel;

    my $msg = Google::Monitoring::Dashboard::V1::LogsPanel::LogsPanel->new({
        filter => $filter,
        resource_names => $resource_names,
    });

    # Read or update a field
    my $val = $msg->filter();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Monitoring::Dashboard::V1::LogsPanel::LogsPanel->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/monitoring/dashboard/v1/logs_panel.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Monitoring::Dashboard::V1::LogsPanel::LogsPanel

A widget that displays a stream of log.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->filter() >> / C<< $msg->filter($value) >>

Type: C<String>

A filter that chooses which log entries to return.  See [Advanced Logs
Queries](https://cloud.google.com/logging/docs/view/advanced-queries).
Only log entries that match the filter are returned.  An empty filter
matches all log entries.

=item * C<< $msg->resource_names() >> / C<< $msg->resource_names($value) >>

Type: C<String>

The names of logging resources to collect logs for. Currently only projects
are supported. If empty, the widget will default to the host project.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Monitoring::Dashboard::V1::LogsPanel::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
