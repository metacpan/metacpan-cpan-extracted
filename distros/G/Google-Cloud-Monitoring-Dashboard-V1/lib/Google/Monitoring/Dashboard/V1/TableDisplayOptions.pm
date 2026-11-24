package Google::Monitoring::Dashboard::V1::TableDisplayOptions;

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
Cjpnb29nbGUvbW9uaXRvcmluZy9kYXNoYm9hcmQvdjEvdGFibGVfZGlzcGxheV9vcHRpb25z
LnByb3RvEh5nb29nbGUubW9uaXRvcmluZy5kYXNoYm9hcmQudjEaH2dvb2dsZS9hcGkvZmll
bGRfYmVoYXZpb3IucHJvdG8iQQoTVGFibGVEaXNwbGF5T3B0aW9ucxIqCg1zaG93bl9jb2x1
bW5zGAEgAygJQgUYAeBBAVIMc2hvd25Db2x1bW5zQoECCiJjb20uZ29vZ2xlLm1vbml0b3Jp
bmcuZGFzaGJvYXJkLnYxQhhUYWJsZURpc3BsYXlPcHRpb25zUHJvdG9QAVpGY2xvdWQuZ29v
Z2xlLmNvbS9nby9tb25pdG9yaW5nL2Rhc2hib2FyZC9hcGl2MS9kYXNoYm9hcmRwYjtkYXNo
Ym9hcmRwYqoCJEdvb2dsZS5DbG91ZC5Nb25pdG9yaW5nLkRhc2hib2FyZC5WMcoCJEdvb2ds
ZVxDbG91ZFxNb25pdG9yaW5nXERhc2hib2FyZFxWMeoCKEdvb2dsZTo6Q2xvdWQ6Ok1vbml0
b3Jpbmc6OkRhc2hib2FyZDo6VjFKhAgKBhIEDgAiAQq8BAoBDBIDDgASMrEEIENvcHlyaWdo
dCAyMDI1IEdvb2dsZSBMTEMKCiBMaWNlbnNlZCB1bmRlciB0aGUgQXBhY2hlIExpY2Vuc2Us
IFZlcnNpb24gMi4wICh0aGUgIkxpY2Vuc2UiKTsKIHlvdSBtYXkgbm90IHVzZSB0aGlzIGZp
bGUgZXhjZXB0IGluIGNvbXBsaWFuY2Ugd2l0aCB0aGUgTGljZW5zZS4KIFlvdSBtYXkgb2J0
YWluIGEgY29weSBvZiB0aGUgTGljZW5zZSBhdAoKICAgICBodHRwOi8vd3d3LmFwYWNoZS5v
cmcvbGljZW5zZXMvTElDRU5TRS0yLjAKCiBVbmxlc3MgcmVxdWlyZWQgYnkgYXBwbGljYWJs
ZSBsYXcgb3IgYWdyZWVkIHRvIGluIHdyaXRpbmcsIHNvZnR3YXJlCiBkaXN0cmlidXRlZCB1
bmRlciB0aGUgTGljZW5zZSBpcyBkaXN0cmlidXRlZCBvbiBhbiAiQVMgSVMiIEJBU0lTLAog
V0lUSE9VVCBXQVJSQU5USUVTIE9SIENPTkRJVElPTlMgT0YgQU5ZIEtJTkQsIGVpdGhlciBl
eHByZXNzIG9yIGltcGxpZWQuCiBTZWUgdGhlIExpY2Vuc2UgZm9yIHRoZSBzcGVjaWZpYyBs
YW5ndWFnZSBnb3Zlcm5pbmcgcGVybWlzc2lvbnMgYW5kCiBsaW1pdGF0aW9ucyB1bmRlciB0
aGUgTGljZW5zZS4KCggKAQISAxAAJwoJCgIDABIDEgApCggKAQgSAxQAQQoJCgIIJRIDFABB
CggKAQgSAxUAXQoJCgIICxIDFQBdCggKAQgSAxYAIgoJCgIIChIDFgAiCggKAQgSAxcAOQoJ
CgIICBIDFwA5CggKAQgSAxgAOwoJCgIIARIDGAA7CggKAQgSAxkAQgoJCgIIKRIDGQBCCggK
AQgSAxoAQQoJCgIILRIDGgBBCjcKAgQAEgQdACIBGisgVGFibGUgZGlzcGxheSBvcHRpb25z
IHRoYXQgY2FuIGJlIHJldXNlZC4KCgoKAwQAARIDHQgbCmgKBAQAAgASBCACIUIaWiBPcHRp
b25hbC4gVGhpcyBmaWVsZCBpcyB1bnVzZWQgYW5kIGhhcyBiZWVuIHJlcGxhY2VkIGJ5CiBU
aW1lU2VyaWVzVGFibGUuY29sdW1uX3NldHRpbmdzCgoMCgUEAAIABBIDIAIKCgwKBQQAAgAF
EgMgCxEKDAoFBAACAAESAyASHwoMCgUEAAIAAxIDICIjCgwKBQQAAgAIEgMhBkEKDQoGBAAC
AAgDEgMhBxgKDwoIBAACAAicCAASAyEaQGIGcHJvdG8z
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Monitoring::Dashboard::V1::TableDisplayOptions::TableDisplayOptions ===
    # Fields for TableDisplayOptions
    # Field: shown_columns Type: 9 ()

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Monitoring::Dashboard::V1::TableDisplayOptions - Compiled Protocol Buffers messages for google/monitoring/dashboard/v1/table_display_options.proto

=head1 SYNOPSIS

    use Google::Monitoring::Dashboard::V1::TableDisplayOptions;

    my $msg = Google::Monitoring::Dashboard::V1::TableDisplayOptions::TableDisplayOptions->new({
        shown_columns => $shown_columns,
    });

    # Read or update a field
    my $val = $msg->shown_columns();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Monitoring::Dashboard::V1::TableDisplayOptions::TableDisplayOptions->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/monitoring/dashboard/v1/table_display_options.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Monitoring::Dashboard::V1::TableDisplayOptions::TableDisplayOptions

Table display options that can be reused.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->shown_columns() >> / C<< $msg->shown_columns($value) >>

Type: C<String>

Optional. This field is unused and has been replaced by
TimeSeriesTable.column_settings

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Monitoring::Dashboard::V1::TableDisplayOptions::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
