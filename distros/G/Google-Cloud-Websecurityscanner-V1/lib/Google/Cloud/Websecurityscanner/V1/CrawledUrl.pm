package Google::Cloud::Websecurityscanner::V1::CrawledUrl;

use strict;
use warnings;

our $VERSION = '0.14';

use Protobuf::Message;
use Protobuf::DescriptorPool;
use Protobuf::Internal qw(:all);
use MIME::Base64;

BEGIN {
    my $descriptor_b64 = <<'EOF';
CjRnb29nbGUvY2xvdWQvd2Vic2VjdXJpdHlzY2FubmVyL3YxL2NyYXdsZWRfdXJsLnByb3Rv
EiJnb29nbGUuY2xvdWQud2Vic2VjdXJpdHlzY2FubmVyLnYxIlMKCkNyYXdsZWRVcmwSHwoL
aHR0cF9tZXRob2QYASABKAlSCmh0dHBNZXRob2QSEAoDdXJsGAIgASgJUgN1cmwSEgoEYm9k
eRgDIAEoCVIEYm9keUKFAgomY29tLmdvb2dsZS5jbG91ZC53ZWJzZWN1cml0eXNjYW5uZXIu
djFCD0NyYXdsZWRVcmxQcm90b1ABWlZjbG91ZC5nb29nbGUuY29tL2dvL3dlYnNlY3VyaXR5
c2Nhbm5lci9hcGl2MS93ZWJzZWN1cml0eXNjYW5uZXJwYjt3ZWJzZWN1cml0eXNjYW5uZXJw
YqoCIkdvb2dsZS5DbG91ZC5XZWJTZWN1cml0eVNjYW5uZXIuVjHKAiJHb29nbGVcQ2xvdWRc
V2ViU2VjdXJpdHlTY2FubmVyXFYx6gIlR29vZ2xlOjpDbG91ZDo6V2ViU2VjdXJpdHlTY2Fu
bmVyOjpWMUrNCgoGEgQOACcBCrwECgEMEgMOABIysQQgQ29weXJpZ2h0IDIwMjUgR29vZ2xl
IExMQwoKIExpY2Vuc2VkIHVuZGVyIHRoZSBBcGFjaGUgTGljZW5zZSwgVmVyc2lvbiAyLjAg
KHRoZSAiTGljZW5zZSIpOwogeW91IG1heSBub3QgdXNlIHRoaXMgZmlsZSBleGNlcHQgaW4g
Y29tcGxpYW5jZSB3aXRoIHRoZSBMaWNlbnNlLgogWW91IG1heSBvYnRhaW4gYSBjb3B5IG9m
IHRoZSBMaWNlbnNlIGF0CgogICAgIGh0dHA6Ly93d3cuYXBhY2hlLm9yZy9saWNlbnNlcy9M
SUNFTlNFLTIuMAoKIFVubGVzcyByZXF1aXJlZCBieSBhcHBsaWNhYmxlIGxhdyBvciBhZ3Jl
ZWQgdG8gaW4gd3JpdGluZywgc29mdHdhcmUKIGRpc3RyaWJ1dGVkIHVuZGVyIHRoZSBMaWNl
bnNlIGlzIGRpc3RyaWJ1dGVkIG9uIGFuICJBUyBJUyIgQkFTSVMsCiBXSVRIT1VUIFdBUlJB
TlRJRVMgT1IgQ09ORElUSU9OUyBPRiBBTlkgS0lORCwgZWl0aGVyIGV4cHJlc3Mgb3IgaW1w
bGllZC4KIFNlZSB0aGUgTGljZW5zZSBmb3IgdGhlIHNwZWNpZmljIGxhbmd1YWdlIGdvdmVy
bmluZyBwZXJtaXNzaW9ucyBhbmQKIGxpbWl0YXRpb25zIHVuZGVyIHRoZSBMaWNlbnNlLgoK
CAoBAhIDEAArCggKAQgSAxIAPwoJCgIIJRIDEgA/CggKAQgSAxMAbQoJCgIICxIDEwBtCggK
AQgSAxQAIgoJCgIIChIDFAAiCggKAQgSAxUAMAoJCgIICBIDFQAwCggKAQgSAxYAPwoJCgII
ARIDFgA/CggKAQgSAxcAPwoJCgIIKRIDFwA/CggKAQgSAxgAPgoJCgIILRIDGAA+CuUBCgIE
ABIEHQAnARrYASBBIENyYXdsZWRVcmwgcmVzb3VyY2UgcmVwcmVzZW50cyBhIFVSTCB0aGF0
IHdhcyBjcmF3bGVkIGR1cmluZyBhIFNjYW5SdW4uIFdlYgogU2VjdXJpdHkgU2Nhbm5lciBT
ZXJ2aWNlIGNyYXdscyB0aGUgd2ViIGFwcGxpY2F0aW9ucywgZm9sbG93aW5nIGFsbCBsaW5r
cwogd2l0aGluIHRoZSBzY29wZSBvZiBzaXRlcywgdG8gZmluZCB0aGUgVVJMcyB0byB0ZXN0
IGFnYWluc3QuCgoKCgMEAAESAx0IEgppCgQEAAIAEgMgAhkaXCBPdXRwdXQgb25seS4gVGhl
IGh0dHAgbWV0aG9kIG9mIHRoZSByZXF1ZXN0IHRoYXQgd2FzIHVzZWQgdG8gdmlzaXQgdGhl
IFVSTCwgaW4KIHVwcGVyY2FzZS4KCgwKBQQAAgAFEgMgAggKDAoFBAACAAESAyAJFAoMCgUE
AAIAAxIDIBcYCjUKBAQAAgESAyMCERooIE91dHB1dCBvbmx5LiBUaGUgVVJMIHRoYXQgd2Fz
IGNyYXdsZWQuCgoMCgUEAAIBBRIDIwIICgwKBQQAAgEBEgMjCQwKDAoFBAACAQMSAyMPEApT
CgQEAAICEgMmAhIaRiBPdXRwdXQgb25seS4gVGhlIGJvZHkgb2YgdGhlIHJlcXVlc3QgdGhh
dCB3YXMgdXNlZCB0byB2aXNpdCB0aGUgVVJMLgoKDAoFBAACAgUSAyYCCAoMCgUEAAICARID
JgkNCgwKBQQAAgIDEgMmEBFiBnByb3RvMw==
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Websecurityscanner::V1::CrawledUrl::CrawledUrl ===
    # Fields for CrawledUrl
    # Field: http_method Type: 9 ()
    # Field: url Type: 9 ()
    # Field: body Type: 9 ()

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Websecurityscanner::V1::CrawledUrl - Compiled Protocol Buffers messages for google/cloud/websecurityscanner/v1/crawled_url.proto

=head1 SYNOPSIS

    use Google::Cloud::Websecurityscanner::V1::CrawledUrl;

    my $msg = Google::Cloud::Websecurityscanner::V1::CrawledUrl::CrawledUrl->new({
        http_method => $http_method,
        url => $url,
        body => $body,
    });

    # Read or update a field
    my $val = $msg->http_method();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Websecurityscanner::V1::CrawledUrl::CrawledUrl->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/websecurityscanner/v1/crawled_url.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Websecurityscanner::V1::CrawledUrl::CrawledUrl

A CrawledUrl resource represents a URL that was crawled during a ScanRun. Web
Security Scanner Service crawls the web applications, following all links
within the scope of sites, to find the URLs to test against.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->http_method() >> / C<< $msg->http_method($value) >>

Type: C<String>

Output only. The http method of the request that was used to visit the URL, in
uppercase.

=item * C<< $msg->url() >> / C<< $msg->url($value) >>

Type: C<String>

Output only. The URL that was crawled.

=item * C<< $msg->body() >> / C<< $msg->body($value) >>

Type: C<String>

Output only. The body of the request that was used to visit the URL.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Websecurityscanner::V1::CrawledUrl::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
