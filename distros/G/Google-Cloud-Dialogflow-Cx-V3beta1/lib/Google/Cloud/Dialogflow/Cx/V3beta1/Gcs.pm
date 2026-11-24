package Google::Cloud::Dialogflow::Cx::V3beta1::Gcs;

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
Cixnb29nbGUvY2xvdWQvZGlhbG9nZmxvdy9jeC92M2JldGExL2djcy5wcm90bxIiZ29vZ2xl
LmNsb3VkLmRpYWxvZ2Zsb3cuY3gudjNiZXRhMRofZ29vZ2xlL2FwaS9maWVsZF9iZWhhdmlv
ci5wcm90byInCg5HY3NEZXN0aW5hdGlvbhIVCgN1cmkYASABKAlCA+BBAlIDdXJpQr8BCiZj
b20uZ29vZ2xlLmNsb3VkLmRpYWxvZ2Zsb3cuY3gudjNiZXRhMUIIR2NzUHJvdG9QAVo2Y2xv
dWQuZ29vZ2xlLmNvbS9nby9kaWFsb2dmbG93L2N4L2FwaXYzYmV0YTEvY3hwYjtjeHBiogIC
REaqAiJHb29nbGUuQ2xvdWQuRGlhbG9nZmxvdy5DeC5WM0JldGEx6gImR29vZ2xlOjpDbG91
ZDo6RGlhbG9nZmxvdzo6Q1g6OlYzYmV0YTFK1gkKBhIEDgAjAQq8BAoBDBIDDgASMrEEIENv
cHlyaWdodCAyMDI2IEdvb2dsZSBMTEMKCiBMaWNlbnNlZCB1bmRlciB0aGUgQXBhY2hlIExp
Y2Vuc2UsIFZlcnNpb24gMi4wICh0aGUgIkxpY2Vuc2UiKTsKIHlvdSBtYXkgbm90IHVzZSB0
aGlzIGZpbGUgZXhjZXB0IGluIGNvbXBsaWFuY2Ugd2l0aCB0aGUgTGljZW5zZS4KIFlvdSBt
YXkgb2J0YWluIGEgY29weSBvZiB0aGUgTGljZW5zZSBhdAoKICAgICBodHRwOi8vd3d3LmFw
YWNoZS5vcmcvbGljZW5zZXMvTElDRU5TRS0yLjAKCiBVbmxlc3MgcmVxdWlyZWQgYnkgYXBw
bGljYWJsZSBsYXcgb3IgYWdyZWVkIHRvIGluIHdyaXRpbmcsIHNvZnR3YXJlCiBkaXN0cmli
dXRlZCB1bmRlciB0aGUgTGljZW5zZSBpcyBkaXN0cmlidXRlZCBvbiBhbiAiQVMgSVMiIEJB
U0lTLAogV0lUSE9VVCBXQVJSQU5USUVTIE9SIENPTkRJVElPTlMgT0YgQU5ZIEtJTkQsIGVp
dGhlciBleHByZXNzIG9yIGltcGxpZWQuCiBTZWUgdGhlIExpY2Vuc2UgZm9yIHRoZSBzcGVj
aWZpYyBsYW5ndWFnZSBnb3Zlcm5pbmcgcGVybWlzc2lvbnMgYW5kCiBsaW1pdGF0aW9ucyB1
bmRlciB0aGUgTGljZW5zZS4KCggKAQISAxAAKwoJCgIDABIDEgApCggKAQgSAxQAPwoJCgII
JRIDFAA/CggKAQgSAxUATQoJCgIICxIDFQBNCggKAQgSAxYAIgoJCgIIChIDFgAiCggKAQgS
AxcAKQoJCgIICBIDFwApCggKAQgSAxgAPwoJCgIIARIDGAA/CggKAQgSAxkAIAoJCgIIJBID
GQAgCggKAQgSAxoAPwoJCgIILRIDGgA/CqMBCgIEABIEHgAjARqWASBHb29nbGUgQ2xvdWQg
U3RvcmFnZSBsb2NhdGlvbiBmb3IgYSBEaWFsb2dmbG93IG9wZXJhdGlvbiB0aGF0IHdyaXRl
cyBvcgogZXhwb3J0cyBvYmplY3RzIChlLmcuIGV4cG9ydGVkIGFnZW50IG9yIHRyYW5zY3Jp
cHRzKSBvdXRzaWRlIG9mIERpYWxvZ2Zsb3cuCgoKCgMEAAESAx4IFgrpAQoEBAACABIDIgI6
GtsBIFJlcXVpcmVkLiBUaGUgR29vZ2xlIENsb3VkIFN0b3JhZ2UgVVJJIGZvciB0aGUgZXhw
b3J0ZWQgb2JqZWN0cy4gQSBVUkkgaXMKIG9mIHRoZSBmb3JtOiBgZ3M6Ly9idWNrZXQvb2Jq
ZWN0LW5hbWUtb3ItcHJlZml4YCBXaGV0aGVyIGEgZnVsbCBvYmplY3QKIG5hbWUsIG9yIGp1
c3QgYSBwcmVmaXgsIGl0cyB1c2FnZSBkZXBlbmRzIG9uIHRoZSBEaWFsb2dmbG93IG9wZXJh
dGlvbi4KCgwKBQQAAgAFEgMiAggKDAoFBAACAAESAyIJDAoMCgUEAAIAAxIDIg8QCgwKBQQA
AgAIEgMiETkKDwoIBAACAAicCAASAyISOGIGcHJvdG8z
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Dialogflow::Cx::V3beta1::Gcs::GcsDestination ===
    # Fields for GcsDestination
    # Field: uri Type: 9 ()

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Dialogflow::Cx::V3beta1::Gcs - Compiled Protocol Buffers messages for google/cloud/dialogflow/cx/v3beta1/gcs.proto

=head1 SYNOPSIS

    use Google::Cloud::Dialogflow::Cx::V3beta1::Gcs;

    my $msg = Google::Cloud::Dialogflow::Cx::V3beta1::Gcs::GcsDestination->new({
        uri => $uri,
    });

    # Read or update a field
    my $val = $msg->uri();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Dialogflow::Cx::V3beta1::Gcs::GcsDestination->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/dialogflow/cx/v3beta1/gcs.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Dialogflow::Cx::V3beta1::Gcs::GcsDestination

Google Cloud Storage location for a Dialogflow operation that writes or
exports objects (e.g. exported agent or transcripts) outside of Dialogflow.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->uri() >> / C<< $msg->uri($value) >>

Type: C<String>

Required. The Google Cloud Storage URI for the exported objects. A URI is
of the form: `gs://bucket/object-name-or-prefix` Whether a full object
name, or just a prefix, its usage depends on the Dialogflow operation.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Dialogflow::Cx::V3beta1::Gcs::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
