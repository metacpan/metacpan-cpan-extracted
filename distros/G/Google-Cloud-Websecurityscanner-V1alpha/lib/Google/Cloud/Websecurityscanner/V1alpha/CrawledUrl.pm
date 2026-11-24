package Google::Cloud::Websecurityscanner::V1alpha::CrawledUrl;

use strict;
use warnings;

our $VERSION = '0.14';

use Protobuf::Message;
use Protobuf::DescriptorPool;
use Protobuf::Internal qw(:all);
use MIME::Base64;

BEGIN {
    my $descriptor_b64 = <<'EOF';
Cjlnb29nbGUvY2xvdWQvd2Vic2VjdXJpdHlzY2FubmVyL3YxYWxwaGEvY3Jhd2xlZF91cmwu
cHJvdG8SJ2dvb2dsZS5jbG91ZC53ZWJzZWN1cml0eXNjYW5uZXIudjFhbHBoYSJTCgpDcmF3
bGVkVXJsEh8KC2h0dHBfbWV0aG9kGAEgASgJUgpodHRwTWV0aG9kEhAKA3VybBgCIAEoCVID
dXJsEhIKBGJvZHkYAyABKAlSBGJvZHlCnQEKK2NvbS5nb29nbGUuY2xvdWQud2Vic2VjdXJp
dHlzY2FubmVyLnYxYWxwaGFCD0NyYXdsZWRVcmxQcm90b1ABWltjbG91ZC5nb29nbGUuY29t
L2dvL3dlYnNlY3VyaXR5c2Nhbm5lci9hcGl2MWFscGhhL3dlYnNlY3VyaXR5c2Nhbm5lcnBi
O3dlYnNlY3VyaXR5c2Nhbm5lcnBiSo8KCgYSBA8AJQEKvQQKAQwSAw8AEjKyBCBDb3B5cmln
aHQgMjAyNSBHb29nbGUgTExDCgogTGljZW5zZWQgdW5kZXIgdGhlIEFwYWNoZSBMaWNlbnNl
LCBWZXJzaW9uIDIuMCAodGhlICJMaWNlbnNlIik7CiB5b3UgbWF5IG5vdCB1c2UgdGhpcyBm
aWxlIGV4Y2VwdCBpbiBjb21wbGlhbmNlIHdpdGggdGhlIExpY2Vuc2UuCiBZb3UgbWF5IG9i
dGFpbiBhIGNvcHkgb2YgdGhlIExpY2Vuc2UgYXQKCiAgICAgaHR0cDovL3d3dy5hcGFjaGUu
b3JnL2xpY2Vuc2VzL0xJQ0VOU0UtMi4wCgogVW5sZXNzIHJlcXVpcmVkIGJ5IGFwcGxpY2Fi
bGUgbGF3IG9yIGFncmVlZCB0byBpbiB3cml0aW5nLCBzb2Z0d2FyZQogZGlzdHJpYnV0ZWQg
dW5kZXIgdGhlIExpY2Vuc2UgaXMgZGlzdHJpYnV0ZWQgb24gYW4gIkFTIElTIiBCQVNJUywK
IFdJVEhPVVQgV0FSUkFOVElFUyBPUiBDT05ESVRJT05TIE9GIEFOWSBLSU5ELCBlaXRoZXIg
ZXhwcmVzcyBvciBpbXBsaWVkLgogU2VlIHRoZSBMaWNlbnNlIGZvciB0aGUgc3BlY2lmaWMg
bGFuZ3VhZ2UgZ292ZXJuaW5nIHBlcm1pc3Npb25zIGFuZAogbGltaXRhdGlvbnMgdW5kZXIg
dGhlIExpY2Vuc2UuCgoKCAoBAhIDEQAwCggKAQgSAxMAcgoJCgIICxIDEwByCggKAQgSAxQA
IgoJCgIIChIDFAAiCggKAQgSAxUAMAoJCgIICBIDFQAwCggKAQgSAxYARAoJCgIIARIDFgBE
CuUBCgIEABIEGwAlARrYASBBIENyYXdsZWRVcmwgcmVzb3VyY2UgcmVwcmVzZW50cyBhIFVS
TCB0aGF0IHdhcyBjcmF3bGVkIGR1cmluZyBhIFNjYW5SdW4uIFdlYgogU2VjdXJpdHkgU2Nh
bm5lciBTZXJ2aWNlIGNyYXdscyB0aGUgd2ViIGFwcGxpY2F0aW9ucywgZm9sbG93aW5nIGFs
bCBsaW5rcwogd2l0aGluIHRoZSBzY29wZSBvZiBzaXRlcywgdG8gZmluZCB0aGUgVVJMcyB0
byB0ZXN0IGFnYWluc3QuCgoKCgMEAAESAxsIEgppCgQEAAIAEgMeAhkaXCBPdXRwdXQgb25s
eS4gVGhlIGh0dHAgbWV0aG9kIG9mIHRoZSByZXF1ZXN0IHRoYXQgd2FzIHVzZWQgdG8gdmlz
aXQgdGhlIFVSTCwgaW4KIHVwcGVyY2FzZS4KCgwKBQQAAgAFEgMeAggKDAoFBAACAAESAx4J
FAoMCgUEAAIAAxIDHhcYCjUKBAQAAgESAyECERooIE91dHB1dCBvbmx5LiBUaGUgVVJMIHRo
YXQgd2FzIGNyYXdsZWQuCgoMCgUEAAIBBRIDIQIICgwKBQQAAgEBEgMhCQwKDAoFBAACAQMS
AyEPEApTCgQEAAICEgMkAhIaRiBPdXRwdXQgb25seS4gVGhlIGJvZHkgb2YgdGhlIHJlcXVl
c3QgdGhhdCB3YXMgdXNlZCB0byB2aXNpdCB0aGUgVVJMLgoKDAoFBAACAgUSAyQCCAoMCgUE
AAICARIDJAkNCgwKBQQAAgIDEgMkEBFiBnByb3RvMw==
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Websecurityscanner::V1alpha::CrawledUrl::CrawledUrl ===
    # Fields for CrawledUrl
    # Field: http_method Type: 9 ()
    # Field: url Type: 9 ()
    # Field: body Type: 9 ()

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Websecurityscanner::V1alpha::CrawledUrl - Compiled Protocol Buffers messages for google/cloud/websecurityscanner/v1alpha/crawled_url.proto

=head1 SYNOPSIS

    use Google::Cloud::Websecurityscanner::V1alpha::CrawledUrl;

    my $msg = Google::Cloud::Websecurityscanner::V1alpha::CrawledUrl::CrawledUrl->new({
        http_method => $http_method,
        url => $url,
        body => $body,
    });

    # Read or update a field
    my $val = $msg->http_method();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Websecurityscanner::V1alpha::CrawledUrl::CrawledUrl->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/websecurityscanner/v1alpha/crawled_url.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Websecurityscanner::V1alpha::CrawledUrl::CrawledUrl

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

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Websecurityscanner::V1alpha::CrawledUrl::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
