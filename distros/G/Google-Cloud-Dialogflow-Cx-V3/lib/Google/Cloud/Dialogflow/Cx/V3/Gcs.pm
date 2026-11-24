package Google::Cloud::Dialogflow::Cx::V3::Gcs;

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
Cidnb29nbGUvY2xvdWQvZGlhbG9nZmxvdy9jeC92My9nY3MucHJvdG8SHWdvb2dsZS5jbG91
ZC5kaWFsb2dmbG93LmN4LnYzGh9nb29nbGUvYXBpL2ZpZWxkX2JlaGF2aW9yLnByb3RvIicK
Dkdjc0Rlc3RpbmF0aW9uEhUKA3VyaRgBIAEoCUID4EECUgN1cmlCqwEKIWNvbS5nb29nbGUu
Y2xvdWQuZGlhbG9nZmxvdy5jeC52M0IIR2NzUHJvdG9QAVoxY2xvdWQuZ29vZ2xlLmNvbS9n
by9kaWFsb2dmbG93L2N4L2FwaXYzL2N4cGI7Y3hwYqICAkRGqgIdR29vZ2xlLkNsb3VkLkRp
YWxvZ2Zsb3cuQ3guVjPqAiFHb29nbGU6OkNsb3VkOjpEaWFsb2dmbG93OjpDWDo6VjNK1gkK
BhIEDgAjAQq8BAoBDBIDDgASMrEEIENvcHlyaWdodCAyMDI2IEdvb2dsZSBMTEMKCiBMaWNl
bnNlZCB1bmRlciB0aGUgQXBhY2hlIExpY2Vuc2UsIFZlcnNpb24gMi4wICh0aGUgIkxpY2Vu
c2UiKTsKIHlvdSBtYXkgbm90IHVzZSB0aGlzIGZpbGUgZXhjZXB0IGluIGNvbXBsaWFuY2Ug
d2l0aCB0aGUgTGljZW5zZS4KIFlvdSBtYXkgb2J0YWluIGEgY29weSBvZiB0aGUgTGljZW5z
ZSBhdAoKICAgICBodHRwOi8vd3d3LmFwYWNoZS5vcmcvbGljZW5zZXMvTElDRU5TRS0yLjAK
CiBVbmxlc3MgcmVxdWlyZWQgYnkgYXBwbGljYWJsZSBsYXcgb3IgYWdyZWVkIHRvIGluIHdy
aXRpbmcsIHNvZnR3YXJlCiBkaXN0cmlidXRlZCB1bmRlciB0aGUgTGljZW5zZSBpcyBkaXN0
cmlidXRlZCBvbiBhbiAiQVMgSVMiIEJBU0lTLAogV0lUSE9VVCBXQVJSQU5USUVTIE9SIENP
TkRJVElPTlMgT0YgQU5ZIEtJTkQsIGVpdGhlciBleHByZXNzIG9yIGltcGxpZWQuCiBTZWUg
dGhlIExpY2Vuc2UgZm9yIHRoZSBzcGVjaWZpYyBsYW5ndWFnZSBnb3Zlcm5pbmcgcGVybWlz
c2lvbnMgYW5kCiBsaW1pdGF0aW9ucyB1bmRlciB0aGUgTGljZW5zZS4KCggKAQISAxAAJgoJ
CgIDABIDEgApCggKAQgSAxQAOgoJCgIIJRIDFAA6CggKAQgSAxUASAoJCgIICxIDFQBICggK
AQgSAxYAIgoJCgIIChIDFgAiCggKAQgSAxcAKQoJCgIICBIDFwApCggKAQgSAxgAOgoJCgII
ARIDGAA6CggKAQgSAxkAIAoJCgIIJBIDGQAgCggKAQgSAxoAOgoJCgIILRIDGgA6CqMBCgIE
ABIEHgAjARqWASBHb29nbGUgQ2xvdWQgU3RvcmFnZSBsb2NhdGlvbiBmb3IgYSBEaWFsb2dm
bG93IG9wZXJhdGlvbiB0aGF0IHdyaXRlcyBvcgogZXhwb3J0cyBvYmplY3RzIChlLmcuIGV4
cG9ydGVkIGFnZW50IG9yIHRyYW5zY3JpcHRzKSBvdXRzaWRlIG9mIERpYWxvZ2Zsb3cuCgoK
CgMEAAESAx4IFgrpAQoEBAACABIDIgI6GtsBIFJlcXVpcmVkLiBUaGUgR29vZ2xlIENsb3Vk
IFN0b3JhZ2UgVVJJIGZvciB0aGUgZXhwb3J0ZWQgb2JqZWN0cy4gQSBVUkkgaXMKIG9mIHRo
ZSBmb3JtOiBgZ3M6Ly9idWNrZXQvb2JqZWN0LW5hbWUtb3ItcHJlZml4YCBXaGV0aGVyIGEg
ZnVsbCBvYmplY3QKIG5hbWUsIG9yIGp1c3QgYSBwcmVmaXgsIGl0cyB1c2FnZSBkZXBlbmRz
IG9uIHRoZSBEaWFsb2dmbG93IG9wZXJhdGlvbi4KCgwKBQQAAgAFEgMiAggKDAoFBAACAAES
AyIJDAoMCgUEAAIAAxIDIg8QCgwKBQQAAgAIEgMiETkKDwoIBAACAAicCAASAyISOGIGcHJv
dG8z
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Dialogflow::Cx::V3::Gcs::GcsDestination ===
    # Fields for GcsDestination
    # Field: uri Type: 9 ()

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Dialogflow::Cx::V3::Gcs - Compiled Protocol Buffers messages for google/cloud/dialogflow/cx/v3/gcs.proto

=head1 SYNOPSIS

    use Google::Cloud::Dialogflow::Cx::V3::Gcs;

    my $msg = Google::Cloud::Dialogflow::Cx::V3::Gcs::GcsDestination->new({
        uri => $uri,
    });

    # Read or update a field
    my $val = $msg->uri();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Dialogflow::Cx::V3::Gcs::GcsDestination->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/dialogflow/cx/v3/gcs.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Dialogflow::Cx::V3::Gcs::GcsDestination

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

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Dialogflow::Cx::V3::Gcs::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
