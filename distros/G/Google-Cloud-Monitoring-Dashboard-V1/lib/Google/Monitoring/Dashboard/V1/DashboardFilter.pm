package Google::Monitoring::Dashboard::V1::DashboardFilter;

use strict;
use warnings;

our $VERSION = '0.14';

use Protobuf::Message;
use Protobuf::DescriptorPool;
use Protobuf::Internal qw(:all);
use MIME::Base64;

BEGIN {
    eval { require Google::Api::FieldBehavior };
    my $descriptor_b64 = <<'EOF';
CjVnb29nbGUvbW9uaXRvcmluZy9kYXNoYm9hcmQvdjEvZGFzaGJvYXJkX2ZpbHRlci5wcm90
bxIeZ29vZ2xlLm1vbml0b3JpbmcuZGFzaGJvYXJkLnYxGh9nb29nbGUvYXBpL2ZpZWxkX2Jl
aGF2aW9yLnByb3RvIoQDCg9EYXNoYm9hcmRGaWx0ZXISIAoJbGFiZWxfa2V5GAEgASgJQgPg
QQJSCGxhYmVsS2V5EisKEXRlbXBsYXRlX3ZhcmlhYmxlGAMgASgJUhB0ZW1wbGF0ZVZhcmlh
YmxlEiMKDHN0cmluZ192YWx1ZRgEIAEoCUgAUgtzdHJpbmdWYWx1ZRJbCgtmaWx0ZXJfdHlw
ZRgFIAEoDjI6Lmdvb2dsZS5tb25pdG9yaW5nLmRhc2hib2FyZC52MS5EYXNoYm9hcmRGaWx0
ZXIuRmlsdGVyVHlwZVIKZmlsdGVyVHlwZSKOAQoKRmlsdGVyVHlwZRIbChdGSUxURVJfVFlQ
RV9VTlNQRUNJRklFRBAAEhIKDlJFU09VUkNFX0xBQkVMEAESEAoMTUVUUklDX0xBQkVMEAIS
FwoTVVNFUl9NRVRBREFUQV9MQUJFTBADEhkKFVNZU1RFTV9NRVRBREFUQV9MQUJFTBAEEgkK
BUdST1VQEAVCDwoNZGVmYXVsdF92YWx1ZUL9AQoiY29tLmdvb2dsZS5tb25pdG9yaW5nLmRh
c2hib2FyZC52MUIURGFzaGJvYXJkRmlsdGVyUHJvdG9QAVpGY2xvdWQuZ29vZ2xlLmNvbS9n
by9tb25pdG9yaW5nL2Rhc2hib2FyZC9hcGl2MS9kYXNoYm9hcmRwYjtkYXNoYm9hcmRwYqoC
JEdvb2dsZS5DbG91ZC5Nb25pdG9yaW5nLkRhc2hib2FyZC5WMcoCJEdvb2dsZVxDbG91ZFxN
b25pdG9yaW5nXERhc2hib2FyZFxWMeoCKEdvb2dsZTo6Q2xvdWQ6Ok1vbml0b3Jpbmc6OkRh
c2hib2FyZDo6VjFKghAKBhIEDgBDAQq8BAoBDBIDDgASMrEEIENvcHlyaWdodCAyMDI1IEdv
b2dsZSBMTEMKCiBMaWNlbnNlZCB1bmRlciB0aGUgQXBhY2hlIExpY2Vuc2UsIFZlcnNpb24g
Mi4wICh0aGUgIkxpY2Vuc2UiKTsKIHlvdSBtYXkgbm90IHVzZSB0aGlzIGZpbGUgZXhjZXB0
IGluIGNvbXBsaWFuY2Ugd2l0aCB0aGUgTGljZW5zZS4KIFlvdSBtYXkgb2J0YWluIGEgY29w
eSBvZiB0aGUgTGljZW5zZSBhdAoKICAgICBodHRwOi8vd3d3LmFwYWNoZS5vcmcvbGljZW5z
ZXMvTElDRU5TRS0yLjAKCiBVbmxlc3MgcmVxdWlyZWQgYnkgYXBwbGljYWJsZSBsYXcgb3Ig
YWdyZWVkIHRvIGluIHdyaXRpbmcsIHNvZnR3YXJlCiBkaXN0cmlidXRlZCB1bmRlciB0aGUg
TGljZW5zZSBpcyBkaXN0cmlidXRlZCBvbiBhbiAiQVMgSVMiIEJBU0lTLAogV0lUSE9VVCBX
QVJSQU5USUVTIE9SIENPTkRJVElPTlMgT0YgQU5ZIEtJTkQsIGVpdGhlciBleHByZXNzIG9y
IGltcGxpZWQuCiBTZWUgdGhlIExpY2Vuc2UgZm9yIHRoZSBzcGVjaWZpYyBsYW5ndWFnZSBn
b3Zlcm5pbmcgcGVybWlzc2lvbnMgYW5kCiBsaW1pdGF0aW9ucyB1bmRlciB0aGUgTGljZW5z
ZS4KCggKAQISAxAAJwoJCgIDABIDEgApCggKAQgSAxQAQQoJCgIIJRIDFABBCggKAQgSAxUA
XQoJCgIICxIDFQBdCggKAQgSAxYAIgoJCgIIChIDFgAiCggKAQgSAxcANQoJCgIICBIDFwA1
CggKAQgSAxgAOwoJCgIIARIDGAA7CggKAQgSAxkAQgoJCgIIKRIDGQBCCggKAQgSAxoAQQoJ
CgIILRIDGgBBClAKAgQAEgQdAEMBGkQgQSBmaWx0ZXIgdG8gcmVkdWNlIHRoZSBhbW91bnQg
b2YgZGF0YSBjaGFydGVkIGluIHJlbGV2YW50IHdpZGdldHMuCgoKCgMEAAESAx0IFwoxCgQE
AAQAEgQfAjEDGiMgVGhlIHR5cGUgZm9yIHRoZSBkYXNoYm9hcmQgZmlsdGVyCgoMCgUEAAQA
ARIDHwcRClgKBgQABAACABIDIQQgGkkgRmlsdGVyIHR5cGUgaXMgdW5zcGVjaWZpZWQuIFRo
aXMgaXMgbm90IHZhbGlkIGluIGEgd2VsbC1mb3JtZWQgcmVxdWVzdC4KCg4KBwQABAACAAES
AyEEGwoOCgcEAAQAAgACEgMhHh8KMQoGBAAEAAIBEgMkBBcaIiBGaWx0ZXIgb24gYSByZXNv
dXJjZSBsYWJlbCB2YWx1ZQoKDgoHBAAEAAIBARIDJAQSCg4KBwQABAACAQISAyQVFgowCgYE
AAQAAgISAycEFRohIEZpbHRlciBvbiBhIG1ldHJpY3MgbGFiZWwgdmFsdWUKCg4KBwQABAAC
AgESAycEEAoOCgcEAAQAAgICEgMnExQKNgoGBAAEAAIDEgMqBBwaJyBGaWx0ZXIgb24gYSB1
c2VyIG1ldGFkYXRhIGxhYmVsIHZhbHVlCgoOCgcEAAQAAgMBEgMqBBcKDgoHBAAEAAIDAhID
KhobCjgKBgQABAACBBIDLQQeGikgRmlsdGVyIG9uIGEgc3lzdGVtIG1ldGFkYXRhIGxhYmVs
IHZhbHVlCgoOCgcEAAQAAgQBEgMtBBkKDgoHBAAEAAIEAhIDLRwdCiUKBgQABAACBRIDMAQO
GhYgRmlsdGVyIG9uIGEgZ3JvdXAgaWQKCg4KBwQABAACBQESAzAECQoOCgcEAAQAAgUCEgMw
DA0KLgoEBAACABIDNAJAGiEgUmVxdWlyZWQuIFRoZSBrZXkgZm9yIHRoZSBsYWJlbAoKDAoF
BAACAAUSAzQCCAoMCgUEAAIAARIDNAkSCgwKBQQAAgADEgM0FRYKDAoFBAACAAgSAzQXPwoP
CggEAAIACJwIABIDNBg+CrkBCgQEAAIBEgM5Ah8aqwEgVGhlIHBsYWNlaG9sZGVyIHRleHQg
dGhhdCBjYW4gYmUgcmVmZXJlbmNlZCBpbiBhIGZpbHRlciBzdHJpbmcgb3IgTVFMCiBxdWVy
eS4gSWYgb21pdHRlZCwgdGhlIGRhc2hib2FyZCBmaWx0ZXIgd2lsbCBiZSBhcHBsaWVkIHRv
IGFsbCByZWxldmFudAogd2lkZ2V0cyBpbiB0aGUgZGFzaGJvYXJkLgoKDAoFBAACAQUSAzkC
CAoMCgUEAAIBARIDOQkaCgwKBQQAAgEDEgM5HR4KPwoEBAAIABIEPAI/AxoxIFRoZSBkZWZh
dWx0IHZhbHVlIHVzZWQgaW4gdGhlIGZpbHRlciBjb21wYXJpc29uCgoMCgUEAAgAARIDPAgV
Ci4KBAQAAgISAz4EHBohIEEgdmFyaWFibGUtbGVuZ3RoIHN0cmluZyB2YWx1ZS4KCgwKBQQA
AgIFEgM+BAoKDAoFBAACAgESAz4LFwoMCgUEAAICAxIDPhobCigKBAQAAgMSA0ICHRobIFRo
ZSBzcGVjaWZpZWQgZmlsdGVyIHR5cGUKCgwKBQQAAgMGEgNCAgwKDAoFBAACAwESA0INGAoM
CgUEAAIDAxIDQhscYgZwcm90bzM=
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Monitoring::Dashboard::V1::DashboardFilter::DashboardFilter ===
    # Fields for DashboardFilter
    # Field: label_key Type: 9 ()
    # Field: template_variable Type: 9 ()
    # Field: string_value Type: 9 ()
    # Field: filter_type Type: 14 (.google.monitoring.dashboard.v1.DashboardFilter.FilterType)

# Enum: DashboardFilter::FilterType
our $DashboardFilter_FILTER_TYPE_UNSPECIFIED = 0;
our $DashboardFilter_RESOURCE_LABEL = 1;
our $DashboardFilter_METRIC_LABEL = 2;
our $DashboardFilter_USER_METADATA_LABEL = 3;
our $DashboardFilter_SYSTEM_METADATA_LABEL = 4;
our $DashboardFilter_GROUP = 5;

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Monitoring::Dashboard::V1::DashboardFilter - Compiled Protocol Buffers messages for google/monitoring/dashboard/v1/dashboard_filter.proto

=head1 SYNOPSIS

    use Google::Monitoring::Dashboard::V1::DashboardFilter;

    my $msg = Google::Monitoring::Dashboard::V1::DashboardFilter::DashboardFilter->new({
        label_key => $label_key,
        template_variable => $template_variable,
        string_value => $string_value,
        filter_type => $filter_type,
    });

    # Read or update a field
    my $val = $msg->label_key();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Monitoring::Dashboard::V1::DashboardFilter::DashboardFilter->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/monitoring/dashboard/v1/dashboard_filter.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Monitoring::Dashboard::V1::DashboardFilter::DashboardFilter

A filter to reduce the amount of data charted in relevant widgets.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->label_key() >> / C<< $msg->label_key($value) >>

Type: C<String>

Required. The key for the label

=item * C<< $msg->template_variable() >> / C<< $msg->template_variable($value) >>

Type: C<String>

The placeholder text that can be referenced in a filter string or MQL
query. If omitted, the dashboard filter will be applied to all relevant
widgets in the dashboard.

=item * C<< $msg->string_value() >> / C<< $msg->string_value($value) >>

Type: C<String>

A variable-length string value.

=item * C<< $msg->filter_type() >> / C<< $msg->filter_type($value) >>

Type: C<Enum> (L<Google::Monitoring::Dashboard::V1::DashboardFilter::FilterType>)

The specified filter type

=back

=head3 Enum: DashboardFilter::FilterType

=over 4

=item * C<FILTER_TYPE_UNSPECIFIED> => C<0>

=item * C<RESOURCE_LABEL> => C<1>

=item * C<METRIC_LABEL> => C<2>

=item * C<USER_METADATA_LABEL> => C<3>

=item * C<SYSTEM_METADATA_LABEL> => C<4>

=item * C<GROUP> => C<5>

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Monitoring::Dashboard::V1::DashboardFilter::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
