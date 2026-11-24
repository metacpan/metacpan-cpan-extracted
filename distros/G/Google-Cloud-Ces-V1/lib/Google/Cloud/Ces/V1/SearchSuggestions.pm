package Google::Cloud::Ces::V1::SearchSuggestions;

use strict;
use warnings;

our $VERSION = '0.14';

use Protobuf::Message;
use Protobuf::DescriptorPool;
use Protobuf::Internal qw(:all);
use MIME::Base64;

BEGIN {
    my $descriptor_b64 = <<'EOF';
Cixnb29nbGUvY2xvdWQvY2VzL3YxL3NlYXJjaF9zdWdnZXN0aW9ucy5wcm90bxITZ29vZ2xl
LmNsb3VkLmNlcy52MSKCAQoXR29vZ2xlU2VhcmNoU3VnZ2VzdGlvbnMSFAoFaHRtbHMYASAD
KAlSBWh0bWxzElEKEndlYl9zZWFyY2hfcXVlcmllcxgCIAMoCzIjLmdvb2dsZS5jbG91ZC5j
ZXMudjEuV2ViU2VhcmNoUXVlcnlSEHdlYlNlYXJjaFF1ZXJpZXMiOAoOV2ViU2VhcmNoUXVl
cnkSFAoFcXVlcnkYASABKAlSBXF1ZXJ5EhAKA3VyaRgCIAEoCVIDdXJpQl4KF2NvbS5nb29n
bGUuY2xvdWQuY2VzLnYxQhZTZWFyY2hTdWdnZXN0aW9uc1Byb3RvUAFaKWNsb3VkLmdvb2ds
ZS5jb20vZ28vY2VzL2FwaXYxL2Nlc3BiO2Nlc3BiSpcMCgYSBA4ALAEKvAQKAQwSAw4AEjKx
BCBDb3B5cmlnaHQgMjAyNiBHb29nbGUgTExDCgogTGljZW5zZWQgdW5kZXIgdGhlIEFwYWNo
ZSBMaWNlbnNlLCBWZXJzaW9uIDIuMCAodGhlICJMaWNlbnNlIik7CiB5b3UgbWF5IG5vdCB1
c2UgdGhpcyBmaWxlIGV4Y2VwdCBpbiBjb21wbGlhbmNlIHdpdGggdGhlIExpY2Vuc2UuCiBZ
b3UgbWF5IG9idGFpbiBhIGNvcHkgb2YgdGhlIExpY2Vuc2UgYXQKCiAgICAgaHR0cDovL3d3
dy5hcGFjaGUub3JnL2xpY2Vuc2VzL0xJQ0VOU0UtMi4wCgogVW5sZXNzIHJlcXVpcmVkIGJ5
IGFwcGxpY2FibGUgbGF3IG9yIGFncmVlZCB0byBpbiB3cml0aW5nLCBzb2Z0d2FyZQogZGlz
dHJpYnV0ZWQgdW5kZXIgdGhlIExpY2Vuc2UgaXMgZGlzdHJpYnV0ZWQgb24gYW4gIkFTIElT
IiBCQVNJUywKIFdJVEhPVVQgV0FSUkFOVElFUyBPUiBDT05ESVRJT05TIE9GIEFOWSBLSU5E
LCBlaXRoZXIgZXhwcmVzcyBvciBpbXBsaWVkLgogU2VlIHRoZSBMaWNlbnNlIGZvciB0aGUg
c3BlY2lmaWMgbGFuZ3VhZ2UgZ292ZXJuaW5nIHBlcm1pc3Npb25zIGFuZAogbGltaXRhdGlv
bnMgdW5kZXIgdGhlIExpY2Vuc2UuCgoICgECEgMQABwKCAoBCBIDEgBACgkKAggLEgMSAEAK
CAoBCBIDEwAiCgkKAggKEgMTACIKCAoBCBIDFAA3CgkKAggIEgMUADcKCAoBCBIDFQAwCgkK
AggBEgMVADAKYgoCBAASBBkAIwEaViBTZWFyY2ggc3VnZ2VzdGlvbnMgZnJvbSBbR29vZ2xl
IFNlYXJjaAogVG9vbF1bZ29vZ2xlLmNsb3VkLmNlcy52MS5Hb29nbGVTZWFyY2hUb29sXS4K
CgoKAwQAARIDGQgfCuYBCgQEAAIAEgMeAhwa2AEgQ29tcGxpYW50IEhUTUwgYW5kIENTUyBz
dHlsaW5nIGZvciBzZWFyY2ggc3VnZ2VzdGlvbnMuCiBUaGUgcHJvdmlkZWQgSFRNTCBhbmQg
Q1NTIGF1dG9tYXRpY2FsbHkgYWRhcHRzIHRvIHlvdXIgZGV2aWNlIHNldHRpbmdzLAogZGlz
cGxheWluZyBpbiBlaXRoZXIgbGlnaHQgb3IgZGFyayBtb2RlIGluZGljYXRlZCBieQogYEBt
ZWRpYShwcmVmZXJzLWNvbG9yLXNjaGVtZSlgLgoKDAoFBAACAAQSAx4CCgoMCgUEAAIABRID
HgsRCgwKBQQAAgABEgMeEhcKDAoFBAACAAMSAx4aGwqDAQoEBAACARIDIgIxGnYgTGlzdCBv
ZiBxdWVyaWVzIHVzZWQgdG8gcGVyZm9ybSB0aGUgZ29vZ2xlIHNlYXJjaCBhbG9uZyB3aXRo
IHRoZSBzZWFyY2gKIHJlc3VsdCBVUklzIGZvcm1pbmcgdGhlIHNlYXJjaCBzdWdnZXN0aW9u
cy4KCgwKBQQAAgEEEgMiAgoKDAoFBAACAQYSAyILGQoMCgUEAAIBARIDIhosCgwKBQQAAgED
EgMiLzAKUQoCBAESBCYALAEaRSBSZXByZXNlbnRzIGEgc2luZ2xlIHdlYiBzZWFyY2ggcXVl
cnkgYW5kIGl0cyBhc3NvY2lhdGVkIHNlYXJjaCB1cmkuCgoKCgMEAQESAyYIFgolCgQEAQIA
EgMoAhMaGCBUaGUgc2VhcmNoIHF1ZXJ5IHRleHQuCgoMCgUEAQIABRIDKAIICgwKBQQBAgAB
EgMoCQ4KDAoFBAECAAMSAygREgpHCgQEAQIBEgMrAhEaOiBUaGUgVVJJIHRvIHRoZSBHb29n
bGUgU2VhcmNoIHJlc3VsdHMgcGFnZSBmb3IgdGhlIHF1ZXJ5LgoKDAoFBAECAQUSAysCCAoM
CgUEAQIBARIDKwkMCgwKBQQBAgEDEgMrDxBiBnByb3RvMw==
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Ces::V1::SearchSuggestions::GoogleSearchSuggestions ===
    # Fields for GoogleSearchSuggestions
    # Field: htmls Type: 9 ()
    # Field: web_search_queries Type: 11 (.google.cloud.ces.v1.WebSearchQuery)

# === Message: Google::Cloud::Ces::V1::SearchSuggestions::WebSearchQuery ===
    # Fields for WebSearchQuery
    # Field: query Type: 9 ()
    # Field: uri Type: 9 ()

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Ces::V1::SearchSuggestions - Compiled Protocol Buffers messages for google/cloud/ces/v1/search_suggestions.proto

=head1 SYNOPSIS

    use Google::Cloud::Ces::V1::SearchSuggestions;

    my $msg = Google::Cloud::Ces::V1::SearchSuggestions::GoogleSearchSuggestions->new({
        htmls => $htmls,
        web_search_queries => $web_search_queries,
    });

    # Read or update a field
    my $val = $msg->htmls();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Ces::V1::SearchSuggestions::GoogleSearchSuggestions->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/ces/v1/search_suggestions.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Ces::V1::SearchSuggestions::GoogleSearchSuggestions

Search suggestions from [Google Search
Tool][google.cloud.ces.v1.GoogleSearchTool].

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

Type: C<Message> (L<Google::Cloud::Ces::V1::SearchSuggestions::WebSearchQuery>)

List of queries used to perform the google search along with the search
result URIs forming the search suggestions.

=back

=head2 Google::Cloud::Ces::V1::SearchSuggestions::WebSearchQuery

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

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Ces::V1::SearchSuggestions::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
