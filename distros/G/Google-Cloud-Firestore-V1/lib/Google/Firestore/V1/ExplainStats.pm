package Google::Firestore::V1::ExplainStats;

use strict;
use warnings;

our $VERSION = '0.14';

use Protobuf::Message;
use Protobuf::DescriptorPool;
use Protobuf::Internal qw(:all);
use MIME::Base64;

BEGIN {
    eval { require Google::Protobuf::Any };
    my $descriptor_b64 = <<'EOF';
Cidnb29nbGUvZmlyZXN0b3JlL3YxL2V4cGxhaW5fc3RhdHMucHJvdG8SE2dvb2dsZS5maXJl
c3RvcmUudjEaGWdvb2dsZS9wcm90b2J1Zi9hbnkucHJvdG8iOAoMRXhwbGFpblN0YXRzEigK
BGRhdGEYASABKAsyFC5nb29nbGUucHJvdG9idWYuQW55UgRkYXRhQsIBChdjb20uZ29vZ2xl
LmZpcmVzdG9yZS52MUIRRXhwbGFpblN0YXRzUHJvdG9QAVo7Y2xvdWQuZ29vZ2xlLmNvbS9n
by9maXJlc3RvcmUvYXBpdjEvZmlyZXN0b3JlcGI7ZmlyZXN0b3JlcGKqAhlHb29nbGUuQ2xv
dWQuRmlyZXN0b3JlLlYxygIZR29vZ2xlXENsb3VkXEZpcmVzdG9yZVxWMeoCHEdvb2dsZTo6
Q2xvdWQ6OkZpcmVzdG9yZTo6VjFKvwkKBhIEDgAoAQq8BAoBDBIDDgASMrEEIENvcHlyaWdo
dCAyMDI2IEdvb2dsZSBMTEMKCiBMaWNlbnNlZCB1bmRlciB0aGUgQXBhY2hlIExpY2Vuc2Us
IFZlcnNpb24gMi4wICh0aGUgIkxpY2Vuc2UiKTsKIHlvdSBtYXkgbm90IHVzZSB0aGlzIGZp
bGUgZXhjZXB0IGluIGNvbXBsaWFuY2Ugd2l0aCB0aGUgTGljZW5zZS4KIFlvdSBtYXkgb2J0
YWluIGEgY29weSBvZiB0aGUgTGljZW5zZSBhdAoKICAgICBodHRwOi8vd3d3LmFwYWNoZS5v
cmcvbGljZW5zZXMvTElDRU5TRS0yLjAKCiBVbmxlc3MgcmVxdWlyZWQgYnkgYXBwbGljYWJs
ZSBsYXcgb3IgYWdyZWVkIHRvIGluIHdyaXRpbmcsIHNvZnR3YXJlCiBkaXN0cmlidXRlZCB1
bmRlciB0aGUgTGljZW5zZSBpcyBkaXN0cmlidXRlZCBvbiBhbiAiQVMgSVMiIEJBU0lTLAog
V0lUSE9VVCBXQVJSQU5USUVTIE9SIENPTkRJVElPTlMgT0YgQU5ZIEtJTkQsIGVpdGhlciBl
eHByZXNzIG9yIGltcGxpZWQuCiBTZWUgdGhlIExpY2Vuc2UgZm9yIHRoZSBzcGVjaWZpYyBs
YW5ndWFnZSBnb3Zlcm5pbmcgcGVybWlzc2lvbnMgYW5kCiBsaW1pdGF0aW9ucyB1bmRlciB0
aGUgTGljZW5zZS4KCggKAQISAxAAHAoJCgIDABIDEgAjCggKAQgSAxQANgoJCgIIJRIDFAA2
CggKAQgSAxUAUgoJCgIICxIDFQBSCggKAQgSAxYAIgoJCgIIChIDFgAiCggKAQgSAxcAMgoJ
CgIICBIDFwAyCggKAQgSAxgAMAoJCgIIARIDGAAwCggKAQgSAxkANgoJCgIIKRIDGQA2CggK
AQgSAxoANQoJCgIILRIDGgA1CtUBCgIEABIEIgAoARqUASBQaXBlbGluZSBleHBsYWluIHN0
YXRzLgoKIERlcGVuZGluZyBvbiB0aGUgZXhwbGFpbiBvcHRpb25zIGluIHRoZSBvcmlnaW5h
bCByZXF1ZXN0LCB0aGlzIGNhbiBjb250YWluCiB0aGUgb3B0aW1pemVkIHBsYW4gYW5kIC8g
b3IgZXhlY3V0aW9uIHN0YXRzLgoyMiBTcGVjaWZpY2F0aW9uIG9mIEZpcmVzdG9yZSBFeHBs
YWluIFN0YXRzIGZpZWxkcy4KCgoKAwQAARIDIggUCr8BCgQEAAIAEgMnAh8asQEgVGhlIGZv
cm1hdCBkZXBlbmRzIG9uIHRoZSBgb3V0cHV0X2Zvcm1hdGAgb3B0aW9ucyBpbiB0aGUgcmVx
dWVzdC4KCiBDdXJyZW50bHkgdGhlcmUgYXJlIHR3byBzdXBwb3J0ZWQgb3B0aW9uczogYFRF
WFRgIGFuZCBgSlNPTmAuCiBCb3RoIHN1cHBseSBhIGBnb29nbGUucHJvdG9idWYuU3RyaW5n
VmFsdWVgLgoKDAoFBAACAAYSAycCFQoMCgUEAAIAARIDJxYaCgwKBQQAAgADEgMnHR5iBnBy
b3RvMw==
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Firestore::V1::ExplainStats::ExplainStats ===
    # Fields for ExplainStats
    # Field: data Type: 11 (.google.protobuf.Any)

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Firestore::V1::ExplainStats - Compiled Protocol Buffers messages for google/firestore/v1/explain_stats.proto

=head1 SYNOPSIS

    use Google::Firestore::V1::ExplainStats;

    my $msg = Google::Firestore::V1::ExplainStats::ExplainStats->new({
        data => $data,
    });

    # Read or update a field
    my $val = $msg->data();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Firestore::V1::ExplainStats::ExplainStats->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/firestore/v1/explain_stats.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Firestore::V1::ExplainStats::ExplainStats

Pipeline explain stats.

Depending on the explain options in the original request, this can contain
the optimized plan and / or execution stats.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->data() >> / C<< $msg->data($value) >>

Type: C<Message> (L<Google::Protobuf::Any::Any>)

The format depends on the `output_format` options in the request.

Currently there are two supported options: `TEXT` and `JSON`.
Both supply a `google.protobuf.StringValue`.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Firestore::V1::ExplainStats::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
