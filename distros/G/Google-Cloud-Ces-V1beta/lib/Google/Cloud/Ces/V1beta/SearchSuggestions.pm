package Google::Cloud::Ces::V1beta::SearchSuggestions;

use strict;
use warnings;

our $VERSION = '0.14';

use Protobuf::Message;
use Protobuf::DescriptorPool;
use Protobuf::Internal qw(:all);
use MIME::Base64;

BEGIN {
    my $descriptor_b64 = <<'EOF';
CjBnb29nbGUvY2xvdWQvY2VzL3YxYmV0YS9zZWFyY2hfc3VnZ2VzdGlvbnMucHJvdG8SF2dv
b2dsZS5jbG91ZC5jZXMudjFiZXRhIoYBChdHb29nbGVTZWFyY2hTdWdnZXN0aW9ucxIUCgVo
dG1scxgBIAMoCVIFaHRtbHMSVQoSd2ViX3NlYXJjaF9xdWVyaWVzGAIgAygLMicuZ29vZ2xl
LmNsb3VkLmNlcy52MWJldGEuV2ViU2VhcmNoUXVlcnlSEHdlYlNlYXJjaFF1ZXJpZXMiOAoO
V2ViU2VhcmNoUXVlcnkSFAoFcXVlcnkYASABKAlSBXF1ZXJ5EhAKA3VyaRgCIAEoCVIDdXJp
QmYKG2NvbS5nb29nbGUuY2xvdWQuY2VzLnYxYmV0YUIWU2VhcmNoU3VnZ2VzdGlvbnNQcm90
b1ABWi1jbG91ZC5nb29nbGUuY29tL2dvL2Nlcy9hcGl2MWJldGEvY2VzcGI7Y2VzcGJKmwwK
BhIEDgAsAQq8BAoBDBIDDgASMrEEIENvcHlyaWdodCAyMDI2IEdvb2dsZSBMTEMKCiBMaWNl
bnNlZCB1bmRlciB0aGUgQXBhY2hlIExpY2Vuc2UsIFZlcnNpb24gMi4wICh0aGUgIkxpY2Vu
c2UiKTsKIHlvdSBtYXkgbm90IHVzZSB0aGlzIGZpbGUgZXhjZXB0IGluIGNvbXBsaWFuY2Ug
d2l0aCB0aGUgTGljZW5zZS4KIFlvdSBtYXkgb2J0YWluIGEgY29weSBvZiB0aGUgTGljZW5z
ZSBhdAoKICAgICBodHRwOi8vd3d3LmFwYWNoZS5vcmcvbGljZW5zZXMvTElDRU5TRS0yLjAK
CiBVbmxlc3MgcmVxdWlyZWQgYnkgYXBwbGljYWJsZSBsYXcgb3IgYWdyZWVkIHRvIGluIHdy
aXRpbmcsIHNvZnR3YXJlCiBkaXN0cmlidXRlZCB1bmRlciB0aGUgTGljZW5zZSBpcyBkaXN0
cmlidXRlZCBvbiBhbiAiQVMgSVMiIEJBU0lTLAogV0lUSE9VVCBXQVJSQU5USUVTIE9SIENP
TkRJVElPTlMgT0YgQU5ZIEtJTkQsIGVpdGhlciBleHByZXNzIG9yIGltcGxpZWQuCiBTZWUg
dGhlIExpY2Vuc2UgZm9yIHRoZSBzcGVjaWZpYyBsYW5ndWFnZSBnb3Zlcm5pbmcgcGVybWlz
c2lvbnMgYW5kCiBsaW1pdGF0aW9ucyB1bmRlciB0aGUgTGljZW5zZS4KCggKAQISAxAAIAoI
CgEIEgMSAEQKCQoCCAsSAxIARAoICgEIEgMTACIKCQoCCAoSAxMAIgoICgEIEgMUADcKCQoC
CAgSAxQANwoICgEIEgMVADQKCQoCCAESAxUANApmCgIEABIEGQAjARpaIFNlYXJjaCBzdWdn
ZXN0aW9ucyBmcm9tIFtHb29nbGUgU2VhcmNoCiBUb29sXVtnb29nbGUuY2xvdWQuY2VzLnYx
YmV0YS5Hb29nbGVTZWFyY2hUb29sXS4KCgoKAwQAARIDGQgfCuYBCgQEAAIAEgMeAhwa2AEg
Q29tcGxpYW50IEhUTUwgYW5kIENTUyBzdHlsaW5nIGZvciBzZWFyY2ggc3VnZ2VzdGlvbnMu
CiBUaGUgcHJvdmlkZWQgSFRNTCBhbmQgQ1NTIGF1dG9tYXRpY2FsbHkgYWRhcHRzIHRvIHlv
dXIgZGV2aWNlIHNldHRpbmdzLAogZGlzcGxheWluZyBpbiBlaXRoZXIgbGlnaHQgb3IgZGFy
ayBtb2RlIGluZGljYXRlZCBieQogYEBtZWRpYShwcmVmZXJzLWNvbG9yLXNjaGVtZSlgLgoK
DAoFBAACAAQSAx4CCgoMCgUEAAIABRIDHgsRCgwKBQQAAgABEgMeEhcKDAoFBAACAAMSAx4a
GwqDAQoEBAACARIDIgIxGnYgTGlzdCBvZiBxdWVyaWVzIHVzZWQgdG8gcGVyZm9ybSB0aGUg
Z29vZ2xlIHNlYXJjaCBhbG9uZyB3aXRoIHRoZSBzZWFyY2gKIHJlc3VsdCBVUklzIGZvcm1p
bmcgdGhlIHNlYXJjaCBzdWdnZXN0aW9ucy4KCgwKBQQAAgEEEgMiAgoKDAoFBAACAQYSAyIL
GQoMCgUEAAIBARIDIhosCgwKBQQAAgEDEgMiLzAKUQoCBAESBCYALAEaRSBSZXByZXNlbnRz
IGEgc2luZ2xlIHdlYiBzZWFyY2ggcXVlcnkgYW5kIGl0cyBhc3NvY2lhdGVkIHNlYXJjaCB1
cmkuCgoKCgMEAQESAyYIFgolCgQEAQIAEgMoAhMaGCBUaGUgc2VhcmNoIHF1ZXJ5IHRleHQu
CgoMCgUEAQIABRIDKAIICgwKBQQBAgABEgMoCQ4KDAoFBAECAAMSAygREgpHCgQEAQIBEgMr
AhEaOiBUaGUgVVJJIHRvIHRoZSBHb29nbGUgU2VhcmNoIHJlc3VsdHMgcGFnZSBmb3IgdGhl
IHF1ZXJ5LgoKDAoFBAECAQUSAysCCAoMCgUEAQIBARIDKwkMCgwKBQQBAgEDEgMrDxBiBnBy
b3RvMw==
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Ces::V1beta::SearchSuggestions::GoogleSearchSuggestions ===
    # Fields for GoogleSearchSuggestions
    # Field: htmls Type: 9 ()
    # Field: web_search_queries Type: 11 (.google.cloud.ces.v1beta.WebSearchQuery)

# === Message: Google::Cloud::Ces::V1beta::SearchSuggestions::WebSearchQuery ===
    # Fields for WebSearchQuery
    # Field: query Type: 9 ()
    # Field: uri Type: 9 ()

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Ces::V1beta::SearchSuggestions - Compiled Protocol Buffers messages for google/cloud/ces/v1beta/search_suggestions.proto

=head1 SYNOPSIS

    use Google::Cloud::Ces::V1beta::SearchSuggestions;

    my $msg = Google::Cloud::Ces::V1beta::SearchSuggestions::GoogleSearchSuggestions->new({
        htmls => $htmls,
        web_search_queries => $web_search_queries,
    });

    # Read or update a field
    my $val = $msg->htmls();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Ces::V1beta::SearchSuggestions::GoogleSearchSuggestions->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/ces/v1beta/search_suggestions.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Ces::V1beta::SearchSuggestions::GoogleSearchSuggestions

Search suggestions from [Google Search
Tool][google.cloud.ces.v1beta.GoogleSearchTool].

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->htmls() >> / C<< $msg->htmls($value) >>

Type: C<String>

Compliant HTML and CSS styling for search suggestions.
The provided HTML and CSS automatically adapts to your device settings,
displaying in either light or dark mode indicated by
`@media(prefers-color-scheme)`.

=item * C<< $msg->web_search_queries() >> / C<< $msg->web_search_queries($value) >>

Type: C<Message> (L<Google::Cloud::Ces::V1beta::SearchSuggestions::WebSearchQuery>)

List of queries used to perform the google search along with the search
result URIs forming the search suggestions.

=back

=head2 Google::Cloud::Ces::V1beta::SearchSuggestions::WebSearchQuery

Represents a single web search query and its associated search uri.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->query() >> / C<< $msg->query($value) >>

Type: C<String>

The search query text.

=item * C<< $msg->uri() >> / C<< $msg->uri($value) >>

Type: C<String>

The URI to the Google Search results page for the query.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Ces::V1beta::SearchSuggestions::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
