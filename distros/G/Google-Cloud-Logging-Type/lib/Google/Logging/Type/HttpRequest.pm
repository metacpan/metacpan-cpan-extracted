package Google::Logging::Type::HttpRequest;

use strict;
use warnings;

our $VERSION = '0.14';

use Protobuf::Message;
use Protobuf::DescriptorPool;
use Protobuf::Internal qw(:all);
use MIME::Base64;

BEGIN {
    eval { require Google::Protobuf::Duration };
    my $descriptor_b64 = <<'EOF';
CiZnb29nbGUvbG9nZ2luZy90eXBlL2h0dHBfcmVxdWVzdC5wcm90bxITZ29vZ2xlLmxvZ2dp
bmcudHlwZRoeZ29vZ2xlL3Byb3RvYnVmL2R1cmF0aW9uLnByb3RvIq8ECgtIdHRwUmVxdWVz
dBIlCg5yZXF1ZXN0X21ldGhvZBgBIAEoCVINcmVxdWVzdE1ldGhvZBIfCgtyZXF1ZXN0X3Vy
bBgCIAEoCVIKcmVxdWVzdFVybBIhCgxyZXF1ZXN0X3NpemUYAyABKANSC3JlcXVlc3RTaXpl
EhYKBnN0YXR1cxgEIAEoBVIGc3RhdHVzEiMKDXJlc3BvbnNlX3NpemUYBSABKANSDHJlc3Bv
bnNlU2l6ZRIdCgp1c2VyX2FnZW50GAYgASgJUgl1c2VyQWdlbnQSGwoJcmVtb3RlX2lwGAcg
ASgJUghyZW1vdGVJcBIbCglzZXJ2ZXJfaXAYDSABKAlSCHNlcnZlcklwEhgKB3JlZmVyZXIY
CCABKAlSB3JlZmVyZXISMwoHbGF0ZW5jeRgOIAEoCzIZLmdvb2dsZS5wcm90b2J1Zi5EdXJh
dGlvblIHbGF0ZW5jeRIhCgxjYWNoZV9sb29rdXAYCyABKAhSC2NhY2hlTG9va3VwEhsKCWNh
Y2hlX2hpdBgJIAEoCFIIY2FjaGVIaXQSSgoiY2FjaGVfdmFsaWRhdGVkX3dpdGhfb3JpZ2lu
X3NlcnZlchgKIAEoCFIeY2FjaGVWYWxpZGF0ZWRXaXRoT3JpZ2luU2VydmVyEigKEGNhY2hl
X2ZpbGxfYnl0ZXMYDCABKANSDmNhY2hlRmlsbEJ5dGVzEhoKCHByb3RvY29sGA8gASgJUghw
cm90b2NvbEK+AQoXY29tLmdvb2dsZS5sb2dnaW5nLnR5cGVCEEh0dHBSZXF1ZXN0UHJvdG9Q
AVo4Z29vZ2xlLmdvbGFuZy5vcmcvZ2VucHJvdG8vZ29vZ2xlYXBpcy9sb2dnaW5nL3R5cGU7
bHR5cGWqAhlHb29nbGUuQ2xvdWQuTG9nZ2luZy5UeXBlygIZR29vZ2xlXENsb3VkXExvZ2dp
bmdcVHlwZeoCHEdvb2dsZTo6Q2xvdWQ6OkxvZ2dpbmc6OlR5cGVKjhwKBhIEDgBeAQq8BAoB
DBIDDgASMrEEIENvcHlyaWdodCAyMDI1IEdvb2dsZSBMTEMKCiBMaWNlbnNlZCB1bmRlciB0
aGUgQXBhY2hlIExpY2Vuc2UsIFZlcnNpb24gMi4wICh0aGUgIkxpY2Vuc2UiKTsKIHlvdSBt
YXkgbm90IHVzZSB0aGlzIGZpbGUgZXhjZXB0IGluIGNvbXBsaWFuY2Ugd2l0aCB0aGUgTGlj
ZW5zZS4KIFlvdSBtYXkgb2J0YWluIGEgY29weSBvZiB0aGUgTGljZW5zZSBhdAoKICAgICBo
dHRwOi8vd3d3LmFwYWNoZS5vcmcvbGljZW5zZXMvTElDRU5TRS0yLjAKCiBVbmxlc3MgcmVx
dWlyZWQgYnkgYXBwbGljYWJsZSBsYXcgb3IgYWdyZWVkIHRvIGluIHdyaXRpbmcsIHNvZnR3
YXJlCiBkaXN0cmlidXRlZCB1bmRlciB0aGUgTGljZW5zZSBpcyBkaXN0cmlidXRlZCBvbiBh
biAiQVMgSVMiIEJBU0lTLAogV0lUSE9VVCBXQVJSQU5USUVTIE9SIENPTkRJVElPTlMgT0Yg
QU5ZIEtJTkQsIGVpdGhlciBleHByZXNzIG9yIGltcGxpZWQuCiBTZWUgdGhlIExpY2Vuc2Ug
Zm9yIHRoZSBzcGVjaWZpYyBsYW5ndWFnZSBnb3Zlcm5pbmcgcGVybWlzc2lvbnMgYW5kCiBs
aW1pdGF0aW9ucyB1bmRlciB0aGUgTGljZW5zZS4KCggKAQISAxAAHAoJCgIDABIDEgAoCggK
AQgSAxQANgoJCgIIJRIDFAA2CggKAQgSAxUATwoJCgIICxIDFQBPCggKAQgSAxYAIgoJCgII
ChIDFgAiCggKAQgSAxcAMQoJCgIICBIDFwAxCggKAQgSAxgAMAoJCgIIARIDGAAwCggKAQgS
AxkANgoJCgIIKRIDGQA2CggKAQgSAxoANQoJCgIILRIDGgA1CsEBCgIEABIEHwBeARq0ASBB
IGNvbW1vbiBwcm90byBmb3IgbG9nZ2luZyBIVFRQIHJlcXVlc3RzLiBPbmx5IGNvbnRhaW5z
IHNlbWFudGljcwogZGVmaW5lZCBieSB0aGUgSFRUUCBzcGVjaWZpY2F0aW9uLiBQcm9kdWN0
LXNwZWNpZmljIGxvZ2dpbmcKIGluZm9ybWF0aW9uIE1VU1QgYmUgZGVmaW5lZCBpbiBhIHNl
cGFyYXRlIG1lc3NhZ2UuCgoKCgMEAAESAx8IEwpSCgQEAAIAEgMhAhwaRSBUaGUgcmVxdWVz
dCBtZXRob2QuIEV4YW1wbGVzOiBgIkdFVCJgLCBgIkhFQUQiYCwgYCJQVVQiYCwgYCJQT1NU
ImAuCgoMCgUEAAIABRIDIQIICgwKBQQAAgABEgMhCRcKDAoFBAACAAMSAyEaGwqtAQoEBAAC
ARIDJgIZGp8BIFRoZSBzY2hlbWUgKGh0dHAsIGh0dHBzKSwgdGhlIGhvc3QgbmFtZSwgdGhl
IHBhdGggYW5kIHRoZSBxdWVyeQogcG9ydGlvbiBvZiB0aGUgVVJMIHRoYXQgd2FzIHJlcXVl
c3RlZC4KIEV4YW1wbGU6IGAiaHR0cDovL2V4YW1wbGUuY29tL3NvbWUvaW5mbz9jb2xvcj1y
ZWQiYC4KCgwKBQQAAgEFEgMmAggKDAoFBAACAQESAyYJFAoMCgUEAAIBAxIDJhcYCnIKBAQA
AgISAyoCGRplIFRoZSBzaXplIG9mIHRoZSBIVFRQIHJlcXVlc3QgbWVzc2FnZSBpbiBieXRl
cywgaW5jbHVkaW5nIHRoZSByZXF1ZXN0CiBoZWFkZXJzIGFuZCB0aGUgcmVxdWVzdCBib2R5
LgoKDAoFBAACAgUSAyoCBwoMCgUEAAICARIDKggUCgwKBQQAAgIDEgMqFxgKWAoEBAACAxID
LgITGksgVGhlIHJlc3BvbnNlIGNvZGUgaW5kaWNhdGluZyB0aGUgc3RhdHVzIG9mIHJlc3Bv
bnNlLgogRXhhbXBsZXM6IDIwMCwgNDA0LgoKDAoFBAACAwUSAy4CBwoMCgUEAAIDARIDLggO
CgwKBQQAAgMDEgMuERIKjwEKBAQAAgQSAzICGhqBASBUaGUgc2l6ZSBvZiB0aGUgSFRUUCBy
ZXNwb25zZSBtZXNzYWdlIHNlbnQgYmFjayB0byB0aGUgY2xpZW50LCBpbiBieXRlcywKIGlu
Y2x1ZGluZyB0aGUgcmVzcG9uc2UgaGVhZGVycyBhbmQgdGhlIHJlc3BvbnNlIGJvZHkuCgoM
CgUEAAIEBRIDMgIHCgwKBQQAAgQBEgMyCBUKDAoFBAACBAMSAzIYGQqMAQoEBAACBRIDNwIY
Gn8gVGhlIHVzZXIgYWdlbnQgc2VudCBieSB0aGUgY2xpZW50LiBFeGFtcGxlOgogYCJNb3pp
bGxhLzQuMCAoY29tcGF0aWJsZTsgTVNJRSA2LjA7IFdpbmRvd3MgOTg7IFEzMTI0NjE7IC5O
RVQKIENMUiAxLjAuMzcwNSkiYC4KCgwKBQQAAgUFEgM3AggKDAoFBAACBQESAzcJEwoMCgUE
AAIFAxIDNxYXCs8BCgQEAAIGEgM8AhcawQEgVGhlIElQIGFkZHJlc3MgKElQdjQgb3IgSVB2
Nikgb2YgdGhlIGNsaWVudCB0aGF0IGlzc3VlZCB0aGUgSFRUUAogcmVxdWVzdC4gVGhpcyBm
aWVsZCBjYW4gaW5jbHVkZSBwb3J0IGluZm9ybWF0aW9uLiBFeGFtcGxlczoKIGAiMTkyLjE2
OC4xLjEiYCwgYCIxMC4wLjAuMTo4MCJgLCBgIkZFODA6OjAyMDI6QjNGRjpGRTFFOjgzMjki
YC4KCgwKBQQAAgYFEgM8AggKDAoFBAACBgESAzwJEgoMCgUEAAIGAxIDPBUWCtYBCgQEAAIH
EgNBAhgayAEgVGhlIElQIGFkZHJlc3MgKElQdjQgb3IgSVB2Nikgb2YgdGhlIG9yaWdpbiBz
ZXJ2ZXIgdGhhdCB0aGUgcmVxdWVzdCB3YXMKIHNlbnQgdG8uIFRoaXMgZmllbGQgY2FuIGlu
Y2x1ZGUgcG9ydCBpbmZvcm1hdGlvbi4gRXhhbXBsZXM6CiBgIjE5Mi4xNjguMS4xImAsIGAi
MTAuMC4wLjE6ODAiYCwgYCJGRTgwOjowMjAyOkIzRkY6RkUxRTo4MzI5ImAuCgoMCgUEAAIH
BRIDQQIICgwKBQQAAgcBEgNBCRIKDAoFBAACBwMSA0EVFwqhAQoEBAACCBIDRgIVGpMBIFRo
ZSByZWZlcmVyIFVSTCBvZiB0aGUgcmVxdWVzdCwgYXMgZGVmaW5lZCBpbgogW0hUVFAvMS4x
IEhlYWRlciBGaWVsZAogRGVmaW5pdGlvbnNdKGh0dHBzOi8vZGF0YXRyYWNrZXIuaWV0Zi5v
cmcvZG9jL2h0bWwvcmZjMjYxNiNzZWN0aW9uLTE0LjM2KS4KCgwKBQQAAggFEgNGAggKDAoF
BAACCAESA0YJEAoMCgUEAAIIAxIDRhMUCoEBCgQEAAIJEgNKAigadCBUaGUgcmVxdWVzdCBw
cm9jZXNzaW5nIGxhdGVuY3kgb24gdGhlIHNlcnZlciwgZnJvbSB0aGUgdGltZSB0aGUgcmVx
dWVzdCB3YXMKIHJlY2VpdmVkIHVudGlsIHRoZSByZXNwb25zZSB3YXMgc2VudC4KCgwKBQQA
AgkGEgNKAhoKDAoFBAACCQESA0obIgoMCgUEAAIJAxIDSiUnCjsKBAQAAgoSA00CGRouIFdo
ZXRoZXIgb3Igbm90IGEgY2FjaGUgbG9va3VwIHdhcyBhdHRlbXB0ZWQuCgoMCgUEAAIKBRID
TQIGCgwKBQQAAgoBEgNNBxMKDAoFBAACCgMSA00WGApcCgQEAAILEgNRAhUaTyBXaGV0aGVy
IG9yIG5vdCBhbiBlbnRpdHkgd2FzIHNlcnZlZCBmcm9tIGNhY2hlCiAod2l0aCBvciB3aXRo
b3V0IHZhbGlkYXRpb24pLgoKDAoFBAACCwUSA1ECBgoMCgUEAAILARIDUQcQCgwKBQQAAgsD
EgNRExQKqAEKBAQAAgwSA1YCLxqaASBXaGV0aGVyIG9yIG5vdCB0aGUgcmVzcG9uc2Ugd2Fz
IHZhbGlkYXRlZCB3aXRoIHRoZSBvcmlnaW4gc2VydmVyIGJlZm9yZQogYmVpbmcgc2VydmVk
IGZyb20gY2FjaGUuIFRoaXMgZmllbGQgaXMgb25seSBtZWFuaW5nZnVsIGlmIGBjYWNoZV9o
aXRgIGlzCiBUcnVlLgoKDAoFBAACDAUSA1YCBgoMCgUEAAIMARIDVgcpCgwKBQQAAgwDEgNW
LC4KcAoEBAACDRIDWgIeGmMgVGhlIG51bWJlciBvZiBIVFRQIHJlc3BvbnNlIGJ5dGVzIGlu
c2VydGVkIGludG8gY2FjaGUuIFNldCBvbmx5IHdoZW4gYQogY2FjaGUgZmlsbCB3YXMgYXR0
ZW1wdGVkLgoKDAoFBAACDQUSA1oCBwoMCgUEAAINARIDWggYCgwKBQQAAg0DEgNaGx0KWQoE
BAACDhIDXQIXGkwgUHJvdG9jb2wgdXNlZCBmb3IgdGhlIHJlcXVlc3QuIEV4YW1wbGVzOiAi
SFRUUC8xLjEiLCAiSFRUUC8yIiwgIndlYnNvY2tldCIKCgwKBQQAAg4FEgNdAggKDAoFBAAC
DgESA10JEQoMCgUEAAIOAxIDXRQWYgZwcm90bzM=
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Logging::Type::HttpRequest::HttpRequest ===
    # Fields for HttpRequest
    # Field: request_method Type: 9 ()
    # Field: request_url Type: 9 ()
    # Field: request_size Type: 3 ()
    # Field: status Type: 5 ()
    # Field: response_size Type: 3 ()
    # Field: user_agent Type: 9 ()
    # Field: remote_ip Type: 9 ()
    # Field: server_ip Type: 9 ()
    # Field: referer Type: 9 ()
    # Field: latency Type: 11 (.google.protobuf.Duration)
    # Field: cache_lookup Type: 8 ()
    # Field: cache_hit Type: 8 ()
    # Field: cache_validated_with_origin_server Type: 8 ()
    # Field: cache_fill_bytes Type: 3 ()
    # Field: protocol Type: 9 ()

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Logging::Type::HttpRequest - Compiled Protocol Buffers messages for google/logging/type/http_request.proto

=head1 SYNOPSIS

    use Google::Logging::Type::HttpRequest;

    my $msg = Google::Logging::Type::HttpRequest::HttpRequest->new({
        request_method => $request_method,
        request_url => $request_url,
        request_size => $request_size,
        status => $status,
    });

    # Read or update a field
    my $val = $msg->request_method();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Logging::Type::HttpRequest::HttpRequest->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/logging/type/http_request.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Logging::Type::HttpRequest::HttpRequest

A common proto for logging HTTP requests. Only contains semantics
defined by the HTTP specification. Product-specific logging
information MUST be defined in a separate message.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->request_method() >> / C<< $msg->request_method($value) >>

Type: C<String>

The request method. Examples: `"GET"`, `"HEAD"`, `"PUT"`, `"POST"`.

=item * C<< $msg->request_url() >> / C<< $msg->request_url($value) >>

Type: C<String>

The scheme (http, https), the host name, the path and the query
portion of the URL that was requested.
Example: `"http://example.com/some/info?color=red"`.

=item * C<< $msg->request_size() >> / C<< $msg->request_size($value) >>

Type: C<Int64>

The size of the HTTP request message in bytes, including the request
headers and the request body.

=item * C<< $msg->status() >> / C<< $msg->status($value) >>

Type: C<Int32>

The response code indicating the status of response.
Examples: 200, 404.

=item * C<< $msg->response_size() >> / C<< $msg->response_size($value) >>

Type: C<Int64>

The size of the HTTP response message sent back to the client, in bytes,
including the response headers and the response body.

=item * C<< $msg->user_agent() >> / C<< $msg->user_agent($value) >>

Type: C<String>

The user agent sent by the client. Example:
`"Mozilla/4.0 (compatible; MSIE 6.0; Windows 98; Q312461; .NET
CLR 1.0.3705)"`.

=item * C<< $msg->remote_ip() >> / C<< $msg->remote_ip($value) >>

Type: C<String>

The IP address (IPv4 or IPv6) of the client that issued the HTTP
request. This field can include port information. Examples:
`"192.168.1.1"`, `"10.0.0.1:80"`, `"FE80::0202:B3FF:FE1E:8329"`.

=item * C<< $msg->server_ip() >> / C<< $msg->server_ip($value) >>

Type: C<String>

The IP address (IPv4 or IPv6) of the origin server that the request was
sent to. This field can include port information. Examples:
`"192.168.1.1"`, `"10.0.0.1:80"`, `"FE80::0202:B3FF:FE1E:8329"`.

=item * C<< $msg->referer() >> / C<< $msg->referer($value) >>

Type: C<String>

The referer URL of the request, as defined in
[HTTP/1.1 Header Field
Definitions](https://datatracker.ietf.org/doc/html/rfc2616#section-14.36).

=item * C<< $msg->latency() >> / C<< $msg->latency($value) >>

Type: C<Message> (L<Google::Protobuf::Duration::Duration>)

The request processing latency on the server, from the time the request was
received until the response was sent.

=item * C<< $msg->cache_lookup() >> / C<< $msg->cache_lookup($value) >>

Type: C<Bool>

Whether or not a cache lookup was attempted.

=item * C<< $msg->cache_hit() >> / C<< $msg->cache_hit($value) >>

Type: C<Bool>

Whether or not an entity was served from cache
(with or without validation).

=item * C<< $msg->cache_validated_with_origin_server() >> / C<< $msg->cache_validated_with_origin_server($value) >>

Type: C<Bool>

Whether or not the response was validated with the origin server before
being served from cache. This field is only meaningful if `cache_hit` is
True.

=item * C<< $msg->cache_fill_bytes() >> / C<< $msg->cache_fill_bytes($value) >>

Type: C<Int64>

The number of HTTP response bytes inserted into cache. Set only when a
cache fill was attempted.

=item * C<< $msg->protocol() >> / C<< $msg->protocol($value) >>

Type: C<String>

Protocol used for the request. Examples: "HTTP/1.1", "HTTP/2", "websocket"

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Logging::Type::HttpRequest::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
