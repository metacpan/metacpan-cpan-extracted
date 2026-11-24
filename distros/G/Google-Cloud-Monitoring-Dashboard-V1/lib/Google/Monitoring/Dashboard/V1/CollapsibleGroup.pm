package Google::Monitoring::Dashboard::V1::CollapsibleGroup;

use strict;
use warnings;

our $VERSION = '0.14';

use Protobuf::Message;
use Protobuf::DescriptorPool;
use Protobuf::Internal qw(:all);
use MIME::Base64;

BEGIN {
    my $descriptor_b64 = <<'EOF';
CjZnb29nbGUvbW9uaXRvcmluZy9kYXNoYm9hcmQvdjEvY29sbGFwc2libGVfZ3JvdXAucHJv
dG8SHmdvb2dsZS5tb25pdG9yaW5nLmRhc2hib2FyZC52MSIwChBDb2xsYXBzaWJsZUdyb3Vw
EhwKCWNvbGxhcHNlZBgBIAEoCFIJY29sbGFwc2VkQv4BCiJjb20uZ29vZ2xlLm1vbml0b3Jp
bmcuZGFzaGJvYXJkLnYxQhVDb2xsYXBzaWJsZUdyb3VwUHJvdG9QAVpGY2xvdWQuZ29vZ2xl
LmNvbS9nby9tb25pdG9yaW5nL2Rhc2hib2FyZC9hcGl2MS9kYXNoYm9hcmRwYjtkYXNoYm9h
cmRwYqoCJEdvb2dsZS5DbG91ZC5Nb25pdG9yaW5nLkRhc2hib2FyZC5WMcoCJEdvb2dsZVxD
bG91ZFxNb25pdG9yaW5nXERhc2hib2FyZFxWMeoCKEdvb2dsZTo6Q2xvdWQ6Ok1vbml0b3Jp
bmc6OkRhc2hib2FyZDo6VjFK/QcKBhIEDgAfAQq8BAoBDBIDDgASMrEEIENvcHlyaWdodCAy
MDI1IEdvb2dsZSBMTEMKCiBMaWNlbnNlZCB1bmRlciB0aGUgQXBhY2hlIExpY2Vuc2UsIFZl
cnNpb24gMi4wICh0aGUgIkxpY2Vuc2UiKTsKIHlvdSBtYXkgbm90IHVzZSB0aGlzIGZpbGUg
ZXhjZXB0IGluIGNvbXBsaWFuY2Ugd2l0aCB0aGUgTGljZW5zZS4KIFlvdSBtYXkgb2J0YWlu
IGEgY29weSBvZiB0aGUgTGljZW5zZSBhdAoKICAgICBodHRwOi8vd3d3LmFwYWNoZS5vcmcv
bGljZW5zZXMvTElDRU5TRS0yLjAKCiBVbmxlc3MgcmVxdWlyZWQgYnkgYXBwbGljYWJsZSBs
YXcgb3IgYWdyZWVkIHRvIGluIHdyaXRpbmcsIHNvZnR3YXJlCiBkaXN0cmlidXRlZCB1bmRl
ciB0aGUgTGljZW5zZSBpcyBkaXN0cmlidXRlZCBvbiBhbiAiQVMgSVMiIEJBU0lTLAogV0lU
SE9VVCBXQVJSQU5USUVTIE9SIENPTkRJVElPTlMgT0YgQU5ZIEtJTkQsIGVpdGhlciBleHBy
ZXNzIG9yIGltcGxpZWQuCiBTZWUgdGhlIExpY2Vuc2UgZm9yIHRoZSBzcGVjaWZpYyBsYW5n
dWFnZSBnb3Zlcm5pbmcgcGVybWlzc2lvbnMgYW5kCiBsaW1pdGF0aW9ucyB1bmRlciB0aGUg
TGljZW5zZS4KCggKAQISAxAAJwoICgEIEgMSAEEKCQoCCCUSAxIAQQoICgEIEgMTAF0KCQoC
CAsSAxMAXQoICgEIEgMUACIKCQoCCAoSAxQAIgoICgEIEgMVADYKCQoCCAgSAxUANgoICgEI
EgMWADsKCQoCCAESAxYAOwoICgEIEgMXAEIKCQoCCCkSAxcAQgoICgEIEgMYAEEKCQoCCC0S
AxgAQQqaAQoCBAASBBwAHwEajQEgQSB3aWRnZXQgdGhhdCBncm91cHMgdGhlIG90aGVyIHdp
ZGdldHMuIEFsbCB3aWRnZXRzIHRoYXQgYXJlIHdpdGhpbgogdGhlIGFyZWEgc3Bhbm5lZCBi
eSB0aGUgZ3JvdXBpbmcgd2lkZ2V0IGFyZSBjb25zaWRlcmVkIG1lbWJlciB3aWRnZXRzLgoK
CgoDBAABEgMcCBgKRAoEBAACABIDHgIVGjcgVGhlIGNvbGxhcHNlZCBzdGF0ZSBvZiB0aGUg
d2lkZ2V0IG9uIGZpcnN0IHBhZ2UgbG9hZC4KCgwKBQQAAgAFEgMeAgYKDAoFBAACAAESAx4H
EAoMCgUEAAIAAxIDHhMUYgZwcm90bzM=
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Monitoring::Dashboard::V1::CollapsibleGroup::CollapsibleGroup ===
    # Fields for CollapsibleGroup
    # Field: collapsed Type: 8 ()

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Monitoring::Dashboard::V1::CollapsibleGroup - Compiled Protocol Buffers messages for google/monitoring/dashboard/v1/collapsible_group.proto

=head1 SYNOPSIS

    use Google::Monitoring::Dashboard::V1::CollapsibleGroup;

    my $msg = Google::Monitoring::Dashboard::V1::CollapsibleGroup::CollapsibleGroup->new({
        collapsed => $collapsed,
    });

    # Read or update a field
    my $val = $msg->collapsed();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Monitoring::Dashboard::V1::CollapsibleGroup::CollapsibleGroup->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/monitoring/dashboard/v1/collapsible_group.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Monitoring::Dashboard::V1::CollapsibleGroup::CollapsibleGroup

A widget that groups the other widgets. All widgets that are within
the area spanned by the grouping widget are considered member widgets.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->collapsed() >> / C<< $msg->collapsed($value) >>

Type: C<Bool>

The collapsed state of the widget on first page load.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Monitoring::Dashboard::V1::CollapsibleGroup::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
