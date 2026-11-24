package Google::Monitoring::V3::DroppedLabels;

use strict;
use warnings;

our $VERSION = '0.14';

use Protobuf::Message;
use Protobuf::DescriptorPool;
use Protobuf::Internal qw(:all);
use MIME::Base64;

BEGIN {
    my $descriptor_b64 = <<'EOF';
Cilnb29nbGUvbW9uaXRvcmluZy92My9kcm9wcGVkX2xhYmVscy5wcm90bxIUZ29vZ2xlLm1v
bml0b3JpbmcudjMijwEKDURyb3BwZWRMYWJlbHMSRAoFbGFiZWwYASADKAsyLi5nb29nbGUu
bW9uaXRvcmluZy52My5Ecm9wcGVkTGFiZWxzLkxhYmVsRW50cnlSBWxhYmVsGjgKCkxhYmVs
RW50cnkSEAoDa2V5GAEgASgJUgNrZXkSFAoFdmFsdWUYAiABKAlSBXZhbHVlOgI4AULNAQoY
Y29tLmdvb2dsZS5tb25pdG9yaW5nLnYzQhJEcm9wcGVkTGFiZWxzUHJvdG9QAVpBY2xvdWQu
Z29vZ2xlLmNvbS9nby9tb25pdG9yaW5nL2FwaXYzL3YyL21vbml0b3JpbmdwYjttb25pdG9y
aW5ncGKqAhpHb29nbGUuQ2xvdWQuTW9uaXRvcmluZy5WM8oCGkdvb2dsZVxDbG91ZFxNb25p
dG9yaW5nXFYz6gIdR29vZ2xlOjpDbG91ZDo6TW9uaXRvcmluZzo6VjNK8A0KBhIEDgAtAQq8
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
CiBsaW1pdGF0aW9ucyB1bmRlciB0aGUgTGljZW5zZS4KCggKAQISAxAAHQoICgEIEgMSADcK
CQoCCCUSAxIANwoICgEIEgMTAFgKCQoCCAsSAxMAWAoICgEIEgMUACIKCQoCCAoSAxQAIgoI
CgEIEgMVADMKCQoCCAgSAxUAMwoICgEIEgMWADEKCQoCCAESAxYAMQoICgEIEgMXADcKCQoC
CCkSAxcANwoICgEIEgMYADYKCQoCCC0SAxgANgr7BgoCBAASBCoALQEa7gYgQSBzZXQgb2Yg
KGxhYmVsLCB2YWx1ZSkgcGFpcnMgdGhhdCB3ZXJlIHJlbW92ZWQgZnJvbSBhIERpc3RyaWJ1
dGlvbgogdGltZSBzZXJpZXMgZHVyaW5nIGFnZ3JlZ2F0aW9uIGFuZCB0aGVuIGFkZGVkIGFz
IGFuIGF0dGFjaG1lbnQgdG8gYQogRGlzdHJpYnV0aW9uLkV4ZW1wbGFyLgoKIFRoZSBmdWxs
IGxhYmVsIHNldCBmb3IgdGhlIGV4ZW1wbGFycyBpcyBjb25zdHJ1Y3RlZCBieSB1c2luZyB0
aGUgZHJvcHBlZAogcGFpcnMgaW4gY29tYmluYXRpb24gd2l0aCB0aGUgbGFiZWwgdmFsdWVz
IHRoYXQgcmVtYWluIG9uIHRoZSBhZ2dyZWdhdGVkCiBEaXN0cmlidXRpb24gdGltZSBzZXJp
ZXMuIFRoZSBjb25zdHJ1Y3RlZCBmdWxsIGxhYmVsIHNldCBjYW4gYmUgdXNlZCB0bwogaWRl
bnRpZnkgdGhlIHNwZWNpZmljIGVudGl0eSwgc3VjaCBhcyB0aGUgaW5zdGFuY2Ugb3Igam9i
LCB3aGljaCBtaWdodCBiZQogY29udHJpYnV0aW5nIHRvIGEgbG9uZy10YWlsLiBIb3dldmVy
LCB3aXRoIGRyb3BwZWQgbGFiZWxzLCB0aGUgc3RvcmFnZQogcmVxdWlyZW1lbnRzIGFyZSBy
ZWR1Y2VkIGJlY2F1c2Ugb25seSB0aGUgYWdncmVnYXRlZCBkaXN0cmlidXRpb24gdmFsdWVz
IGZvcgogYSBsYXJnZSBncm91cCBvZiB0aW1lIHNlcmllcyBhcmUgc3RvcmVkLgoKIE5vdGUg
dGhhdCB0aGVyZSBhcmUgbm8gZ3VhcmFudGVlcyBvbiBvcmRlcmluZyBvZiB0aGUgbGFiZWxz
IGZyb20KIGV4ZW1wbGFyLXRvLWV4ZW1wbGFyIGFuZCBmcm9tIGRpc3RyaWJ1dGlvbi10by1k
aXN0cmlidXRpb24gaW4gdGhlIHNhbWUKIHN0cmVhbSwgYW5kIHRoZXJlIG1heSBiZSBkdXBs
aWNhdGVzLiAgSXQgaXMgdXAgdG8gY2xpZW50cyB0byByZXNvbHZlIGFueQogYW1iaWd1aXRp
ZXMuCgoKCgMEAAESAyoIFQpWCgQEAAIAEgMsAiAaSSBNYXAgZnJvbSBsYWJlbCB0byBpdHMg
dmFsdWUsIGZvciBhbGwgbGFiZWxzIGRyb3BwZWQgaW4gYW55IGFnZ3JlZ2F0aW9uLgoKDAoF
BAACAAYSAywCFQoMCgUEAAIAARIDLBYbCgwKBQQAAgADEgMsHh9iBnByb3RvMw==
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Monitoring::V3::DroppedLabels::DroppedLabels ===
    # Fields for DroppedLabels
    # Field: label Type: 11 (.google.monitoring.v3.DroppedLabels.LabelEntry)

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Monitoring::V3::DroppedLabels - Compiled Protocol Buffers messages for google/monitoring/v3/dropped_labels.proto

=head1 SYNOPSIS

    use Google::Monitoring::V3::DroppedLabels;

    my $msg = Google::Monitoring::V3::DroppedLabels::DroppedLabels->new({
        label => $label,
    });

    # Read or update a field
    my $val = $msg->label();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Monitoring::V3::DroppedLabels::DroppedLabels->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/monitoring/v3/dropped_labels.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Monitoring::V3::DroppedLabels::DroppedLabels

A set of (label, value) pairs that were removed from a Distribution
time series during aggregation and then added as an attachment to a
Distribution.Exemplar.

The full label set for the exemplars is constructed by using the dropped
pairs in combination with the label values that remain on the aggregated
Distribution time series. The constructed full label set can be used to
identify the specific entity, such as the instance or job, which might be
contributing to a long-tail. However, with dropped labels, the storage
requirements are reduced because only the aggregated distribution values for
a large group of time series are stored.

Note that there are no guarantees on ordering of the labels from
exemplar-to-exemplar and from distribution-to-distribution in the same
stream, and there may be duplicates.  It is up to clients to resolve any
ambiguities.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->label() >> / C<< $msg->label($value) >>

Type: C<Message> (L<Google::Monitoring::V3::DroppedLabels::DroppedLabels::LabelEntry>)

Map from label to its value, for all labels dropped in any aggregation.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Monitoring::V3::DroppedLabels::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
