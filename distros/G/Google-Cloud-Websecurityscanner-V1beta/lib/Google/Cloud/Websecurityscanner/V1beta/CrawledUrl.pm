package Google::Cloud::Websecurityscanner::V1beta::CrawledUrl;

use strict;
use warnings;

our $VERSION = '0.14';

use Protobuf::Message;
use Protobuf::DescriptorPool;
use Protobuf::Internal qw(:all);
use MIME::Base64;

BEGIN {
    my $descriptor_b64 = <<'EOF';
Cjhnb29nbGUvY2xvdWQvd2Vic2VjdXJpdHlzY2FubmVyL3YxYmV0YS9jcmF3bGVkX3VybC5w
cm90bxImZ29vZ2xlLmNsb3VkLndlYnNlY3VyaXR5c2Nhbm5lci52MWJldGEiUwoKQ3Jhd2xl
ZFVybBIfCgtodHRwX21ldGhvZBgBIAEoCVIKaHR0cE1ldGhvZBIQCgN1cmwYAiABKAlSA3Vy
bBISCgRib2R5GAMgASgJUgRib2R5QpkCCipjb20uZ29vZ2xlLmNsb3VkLndlYnNlY3VyaXR5
c2Nhbm5lci52MWJldGFCD0NyYXdsZWRVcmxQcm90b1ABWlpjbG91ZC5nb29nbGUuY29tL2dv
L3dlYnNlY3VyaXR5c2Nhbm5lci9hcGl2MWJldGEvd2Vic2VjdXJpdHlzY2FubmVycGI7d2Vi
c2VjdXJpdHlzY2FubmVycGKqAiZHb29nbGUuQ2xvdWQuV2ViU2VjdXJpdHlTY2FubmVyLlYx
QmV0YcoCJkdvb2dsZVxDbG91ZFxXZWJTZWN1cml0eVNjYW5uZXJcVjFiZXRh6gIpR29vZ2xl
OjpDbG91ZDo6V2ViU2VjdXJpdHlTY2FubmVyOjpWMWJldGFKpwoKBhIEDwAoAQq9BAoBDBID
DwASMrIEIENvcHlyaWdodCAyMDI1IEdvb2dsZSBMTEMKCiBMaWNlbnNlZCB1bmRlciB0aGUg
QXBhY2hlIExpY2Vuc2UsIFZlcnNpb24gMi4wICh0aGUgIkxpY2Vuc2UiKTsKIHlvdSBtYXkg
bm90IHVzZSB0aGlzIGZpbGUgZXhjZXB0IGluIGNvbXBsaWFuY2Ugd2l0aCB0aGUgTGljZW5z
ZS4KIFlvdSBtYXkgb2J0YWluIGEgY29weSBvZiB0aGUgTGljZW5zZSBhdAoKICAgICBodHRw
Oi8vd3d3LmFwYWNoZS5vcmcvbGljZW5zZXMvTElDRU5TRS0yLjAKCiBVbmxlc3MgcmVxdWly
ZWQgYnkgYXBwbGljYWJsZSBsYXcgb3IgYWdyZWVkIHRvIGluIHdyaXRpbmcsIHNvZnR3YXJl
CiBkaXN0cmlidXRlZCB1bmRlciB0aGUgTGljZW5zZSBpcyBkaXN0cmlidXRlZCBvbiBhbiAi
QVMgSVMiIEJBU0lTLAogV0lUSE9VVCBXQVJSQU5USUVTIE9SIENPTkRJVElPTlMgT0YgQU5Z
IEtJTkQsIGVpdGhlciBleHByZXNzIG9yIGltcGxpZWQuCiBTZWUgdGhlIExpY2Vuc2UgZm9y
IHRoZSBzcGVjaWZpYyBsYW5ndWFnZSBnb3Zlcm5pbmcgcGVybWlzc2lvbnMgYW5kCiBsaW1p
dGF0aW9ucyB1bmRlciB0aGUgTGljZW5zZS4KCgoICgECEgMRAC8KCAoBCBIDEwBDCgkKAggl
EgMTAEMKCAoBCBIDFABxCgkKAggLEgMUAHEKCAoBCBIDFQAiCgkKAggKEgMVACIKCAoBCBID
FgAwCgkKAggIEgMWADAKCAoBCBIDFwBDCgkKAggBEgMXAEMKCAoBCBIDGABDCgkKAggpEgMY
AEMKCAoBCBIDGQBCCgkKAggtEgMZAEIK5QEKAgQAEgQeACgBGtgBIEEgQ3Jhd2xlZFVybCBy
ZXNvdXJjZSByZXByZXNlbnRzIGEgVVJMIHRoYXQgd2FzIGNyYXdsZWQgZHVyaW5nIGEgU2Nh
blJ1bi4gV2ViCiBTZWN1cml0eSBTY2FubmVyIFNlcnZpY2UgY3Jhd2xzIHRoZSB3ZWIgYXBw
bGljYXRpb25zLCBmb2xsb3dpbmcgYWxsIGxpbmtzCiB3aXRoaW4gdGhlIHNjb3BlIG9mIHNp
dGVzLCB0byBmaW5kIHRoZSBVUkxzIHRvIHRlc3QgYWdhaW5zdC4KCgoKAwQAARIDHggSClwK
BAQAAgASAyECGRpPIFRoZSBodHRwIG1ldGhvZCBvZiB0aGUgcmVxdWVzdCB0aGF0IHdhcyB1
c2VkIHRvIHZpc2l0IHRoZSBVUkwsIGluCiB1cHBlcmNhc2UuCgoMCgUEAAIABRIDIQIICgwK
BQQAAgABEgMhCRQKDAoFBAACAAMSAyEXGAooCgQEAAIBEgMkAhEaGyBUaGUgVVJMIHRoYXQg
d2FzIGNyYXdsZWQuCgoMCgUEAAIBBRIDJAIICgwKBQQAAgEBEgMkCQwKDAoFBAACAQMSAyQP
EApGCgQEAAICEgMnAhIaOSBUaGUgYm9keSBvZiB0aGUgcmVxdWVzdCB0aGF0IHdhcyB1c2Vk
IHRvIHZpc2l0IHRoZSBVUkwuCgoMCgUEAAICBRIDJwIICgwKBQQAAgIBEgMnCQ0KDAoFBAAC
AgMSAycQEWIGcHJvdG8z
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Websecurityscanner::V1beta::CrawledUrl::CrawledUrl ===
    # Fields for CrawledUrl
    # Field: http_method Type: 9 ()
    # Field: url Type: 9 ()
    # Field: body Type: 9 ()

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Websecurityscanner::V1beta::CrawledUrl - Compiled Protocol Buffers messages for google/cloud/websecurityscanner/v1beta/crawled_url.proto

=head1 SYNOPSIS

    use Google::Cloud::Websecurityscanner::V1beta::CrawledUrl;

    my $msg = Google::Cloud::Websecurityscanner::V1beta::CrawledUrl::CrawledUrl->new({
        http_method => $http_method,
        url => $url,
        body => $body,
    });

    # Read or update a field
    my $val = $msg->http_method();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Websecurityscanner::V1beta::CrawledUrl::CrawledUrl->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/websecurityscanner/v1beta/crawled_url.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Websecurityscanner::V1beta::CrawledUrl::CrawledUrl

A CrawledUrl resource represents a URL that was crawled during a ScanRun. Web
Security Scanner Service crawls the web applications, following all links
within the scope of sites, to find the URLs to test against.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->http_method() >> / C<< $msg->http_method($value) >>

Type: C<String>

The http method of the request that was used to visit the URL, in
uppercase.

=item * C<< $msg->url() >> / C<< $msg->url($value) >>

Type: C<String>

The URL that was crawled.

=item * C<< $msg->body() >> / C<< $msg->body($value) >>

Type: C<String>

The body of the request that was used to visit the URL.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Websecurityscanner::V1beta::CrawledUrl::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
