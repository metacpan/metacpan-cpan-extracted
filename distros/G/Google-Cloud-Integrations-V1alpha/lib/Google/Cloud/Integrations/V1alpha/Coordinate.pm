package Google::Cloud::Integrations::V1alpha::Coordinate;

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
CjJnb29nbGUvY2xvdWQvaW50ZWdyYXRpb25zL3YxYWxwaGEvY29vcmRpbmF0ZS5wcm90bxIh
Z29vZ2xlLmNsb3VkLmludGVncmF0aW9ucy52MWFscGhhGh9nb29nbGUvYXBpL2ZpZWxkX2Jl
aGF2aW9yLnByb3RvIjIKCkNvb3JkaW5hdGUSEQoBeBgBIAEoBUID4EECUgF4EhEKAXkYAiAB
KAVCA+BBAlIBeUKpAQolY29tLmdvb2dsZS5jbG91ZC5pbnRlZ3JhdGlvbnMudjFhbHBoYUIP
Q29vcmRpbmF0ZVByb3RvUAFaSWNsb3VkLmdvb2dsZS5jb20vZ28vaW50ZWdyYXRpb25zL2Fw
aXYxYWxwaGEvaW50ZWdyYXRpb25zcGI7aW50ZWdyYXRpb25zcGKqAiFHb29nbGUuQ2xvdWQu
SW50ZWdyYXRpb25zLlYxQWxwaGFKiwgKBhIEDgAhAQq8BAoBDBIDDgASMrEEIENvcHlyaWdo
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
aGUgTGljZW5zZS4KCggKAQISAxAAKgoJCgIDABIDEgApCggKAQgSAxQAPgoJCgIIJRIDFAA+
CggKAQgSAxUAYAoJCgIICxIDFQBgCggKAQgSAxYAIgoJCgIIChIDFgAiCggKAQgSAxcAMAoJ
CgIICBIDFwAwCggKAQgSAxgAPgoJCgIIARIDGAA+CkAKAgQAEgQbACEBGjQgQ29uZmlndXJh
dGlvbiBkZXRhaWwgb2YgY29vcmRpbmF0ZSwgaXQgdXNlZCBmb3IgVUkKCgoKAwQAARIDGwgS
CjEKBAQAAgASAx0CNxokIFJlcXVpcmVkLiBYIGF4aXMgb2YgdGhlIGNvb3JkaW5hdGUKCgwK
BQQAAgAFEgMdAgcKDAoFBAACAAESAx0ICQoMCgUEAAIAAxIDHQwNCgwKBQQAAgAIEgMdDjYK
DwoIBAACAAicCAASAx0PNQoxCgQEAAIBEgMgAjcaJCBSZXF1aXJlZC4gWSBheGlzIG9mIHRo
ZSBjb29yZGluYXRlCgoMCgUEAAIBBRIDIAIHCgwKBQQAAgEBEgMgCAkKDAoFBAACAQMSAyAM
DQoMCgUEAAIBCBIDIA42Cg8KCAQAAgEInAgAEgMgDzViBnByb3RvMw==
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Integrations::V1alpha::Coordinate::Coordinate ===
    # Fields for Coordinate
    # Field: x Type: 5 ()
    # Field: y Type: 5 ()

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Integrations::V1alpha::Coordinate - Compiled Protocol Buffers messages for google/cloud/integrations/v1alpha/coordinate.proto

=head1 SYNOPSIS

    use Google::Cloud::Integrations::V1alpha::Coordinate;

    my $msg = Google::Cloud::Integrations::V1alpha::Coordinate::Coordinate->new({
        x => $x,
        y => $y,
    });

    # Read or update a field
    my $val = $msg->x();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Integrations::V1alpha::Coordinate::Coordinate->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/integrations/v1alpha/coordinate.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Integrations::V1alpha::Coordinate::Coordinate

Configuration detail of coordinate, it used for UI

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->x() >> / C<< $msg->x($value) >>

Type: C<Int32>

Required. X axis of the coordinate

=item * C<< $msg->y() >> / C<< $msg->y($value) >>

Type: C<Int32>

Required. Y axis of the coordinate

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Integrations::V1alpha::Coordinate::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
