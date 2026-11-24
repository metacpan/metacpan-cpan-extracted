package Google::Monitoring::V3::SpanContext;

use strict;
use warnings;

our $VERSION = '0.14';

use Protobuf::Message;
use Protobuf::DescriptorPool;
use Protobuf::Internal qw(:all);
use MIME::Base64;

BEGIN {
    my $descriptor_b64 = <<'EOF';
Cidnb29nbGUvbW9uaXRvcmluZy92My9zcGFuX2NvbnRleHQucHJvdG8SFGdvb2dsZS5tb25p
dG9yaW5nLnYzIioKC1NwYW5Db250ZXh0EhsKCXNwYW5fbmFtZRgBIAEoCVIIc3Bhbk5hbWVC
ywEKGGNvbS5nb29nbGUubW9uaXRvcmluZy52M0IQU3BhbkNvbnRleHRQcm90b1ABWkFjbG91
ZC5nb29nbGUuY29tL2dvL21vbml0b3JpbmcvYXBpdjMvdjIvbW9uaXRvcmluZ3BiO21vbml0
b3JpbmdwYqoCGkdvb2dsZS5DbG91ZC5Nb25pdG9yaW5nLlYzygIaR29vZ2xlXENsb3VkXE1v
bml0b3JpbmdcVjPqAh1Hb29nbGU6OkNsb3VkOjpNb25pdG9yaW5nOjpWM0rOCwoGEgQOACwB
CrwECgEMEgMOABIysQQgQ29weXJpZ2h0IDIwMjUgR29vZ2xlIExMQwoKIExpY2Vuc2VkIHVu
ZGVyIHRoZSBBcGFjaGUgTGljZW5zZSwgVmVyc2lvbiAyLjAgKHRoZSAiTGljZW5zZSIpOwog
eW91IG1heSBub3QgdXNlIHRoaXMgZmlsZSBleGNlcHQgaW4gY29tcGxpYW5jZSB3aXRoIHRo
ZSBMaWNlbnNlLgogWW91IG1heSBvYnRhaW4gYSBjb3B5IG9mIHRoZSBMaWNlbnNlIGF0Cgog
ICAgIGh0dHA6Ly93d3cuYXBhY2hlLm9yZy9saWNlbnNlcy9MSUNFTlNFLTIuMAoKIFVubGVz
cyByZXF1aXJlZCBieSBhcHBsaWNhYmxlIGxhdyBvciBhZ3JlZWQgdG8gaW4gd3JpdGluZywg
c29mdHdhcmUKIGRpc3RyaWJ1dGVkIHVuZGVyIHRoZSBMaWNlbnNlIGlzIGRpc3RyaWJ1dGVk
IG9uIGFuICJBUyBJUyIgQkFTSVMsCiBXSVRIT1VUIFdBUlJBTlRJRVMgT1IgQ09ORElUSU9O
UyBPRiBBTlkgS0lORCwgZWl0aGVyIGV4cHJlc3Mgb3IgaW1wbGllZC4KIFNlZSB0aGUgTGlj
ZW5zZSBmb3IgdGhlIHNwZWNpZmljIGxhbmd1YWdlIGdvdmVybmluZyBwZXJtaXNzaW9ucyBh
bmQKIGxpbWl0YXRpb25zIHVuZGVyIHRoZSBMaWNlbnNlLgoKCAoBAhIDEAAdCggKAQgSAxIA
NwoJCgIIJRIDEgA3CggKAQgSAxMAWAoJCgIICxIDEwBYCggKAQgSAxQAIgoJCgIIChIDFAAi
CggKAQgSAxUAMQoJCgIICBIDFQAxCggKAQgSAxYAMQoJCgIIARIDFgAxCggKAQgSAxcANwoJ
CgIIKRIDFwA3CggKAQgSAxgANgoJCgIILRIDGAA2CqcCCgIEABIEIQAsARqaAiBUaGUgY29u
dGV4dCBvZiBhIHNwYW4uIFRoaXMgaXMgYXR0YWNoZWQgdG8gYW4KIFtFeGVtcGxhcl1bZ29v
Z2xlLmFwaS5EaXN0cmlidXRpb24uRXhlbXBsYXJdCiBpbiBbRGlzdHJpYnV0aW9uXVtnb29n
bGUuYXBpLkRpc3RyaWJ1dGlvbl0gdmFsdWVzIGR1cmluZyBhZ2dyZWdhdGlvbi4KCiBJdCBj
b250YWlucyB0aGUgbmFtZSBvZiBhIHNwYW4gd2l0aCBmb3JtYXQ6CgogICAgIHByb2plY3Rz
L1tQUk9KRUNUX0lEX09SX05VTUJFUl0vdHJhY2VzL1tUUkFDRV9JRF0vc3BhbnMvW1NQQU5f
SURdCgoKCgMEAAESAyEIEwqHAwoEBAACABIDKwIXGvkCIFRoZSByZXNvdXJjZSBuYW1lIG9m
IHRoZSBzcGFuLiBUaGUgZm9ybWF0IGlzOgoKICAgICBwcm9qZWN0cy9bUFJPSkVDVF9JRF9P
Ul9OVU1CRVJdL3RyYWNlcy9bVFJBQ0VfSURdL3NwYW5zL1tTUEFOX0lEXQoKIGBbVFJBQ0Vf
SURdYCBpcyBhIHVuaXF1ZSBpZGVudGlmaWVyIGZvciBhIHRyYWNlIHdpdGhpbiBhIHByb2pl
Y3Q7CiBpdCBpcyBhIDMyLWNoYXJhY3RlciBoZXhhZGVjaW1hbCBlbmNvZGluZyBvZiBhIDE2
LWJ5dGUgYXJyYXkuCgogYFtTUEFOX0lEXWAgaXMgYSB1bmlxdWUgaWRlbnRpZmllciBmb3Ig
YSBzcGFuIHdpdGhpbiBhIHRyYWNlOyBpdAogaXMgYSAxNi1jaGFyYWN0ZXIgaGV4YWRlY2lt
YWwgZW5jb2Rpbmcgb2YgYW4gOC1ieXRlIGFycmF5LgoKDAoFBAACAAUSAysCCAoMCgUEAAIA
ARIDKwkSCgwKBQQAAgADEgMrFRZiBnByb3RvMw==
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Monitoring::V3::SpanContext::SpanContext ===
    # Fields for SpanContext
    # Field: span_name Type: 9 ()

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Monitoring::V3::SpanContext - Compiled Protocol Buffers messages for google/monitoring/v3/span_context.proto

=head1 SYNOPSIS

    use Google::Monitoring::V3::SpanContext;

    my $msg = Google::Monitoring::V3::SpanContext::SpanContext->new({
        span_name => $span_name,
    });

    # Read or update a field
    my $val = $msg->span_name();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Monitoring::V3::SpanContext::SpanContext->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/monitoring/v3/span_context.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Monitoring::V3::SpanContext::SpanContext

The context of a span. This is attached to an
[Exemplar][google.api.Distribution.Exemplar]
in [Distribution][google.api.Distribution] values during aggregation.

It contains the name of a span with format:

    projects/[PROJECT_ID_OR_NUMBER]/traces/[TRACE_ID]/spans/[SPAN_ID]

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->span_name() >> / C<< $msg->span_name($value) >>

Type: C<String>

The resource name of the span. The format is:

    projects/[PROJECT_ID_OR_NUMBER]/traces/[TRACE_ID]/spans/[SPAN_ID]

`[TRACE_ID]` is a unique identifier for a trace within a project;
it is a 32-character hexadecimal encoding of a 16-byte array.

`[SPAN_ID]` is a unique identifier for a span within a trace; it
is a 16-character hexadecimal encoding of an 8-byte array.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Monitoring::V3::SpanContext::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
