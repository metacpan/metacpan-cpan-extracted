package Google::Cloud::Vision::V1::ProductSearch;

use strict;
use warnings;

our $VERSION = '0.14';

use Protobuf::Message;
use Protobuf::DescriptorPool;
use Protobuf::Internal qw(:all);
use MIME::Base64;

BEGIN {
    eval { require Google::Api::Resource };
    eval { require Google::Cloud::Vision::V1::Geometry };
    eval { require Google::Cloud::Vision::V1::ProductSearchService };
    eval { require Google::Protobuf::Timestamp };
    my $descriptor_b64 = <<'EOF';
Citnb29nbGUvY2xvdWQvdmlzaW9uL3YxL3Byb2R1Y3Rfc2VhcmNoLnByb3RvEhZnb29nbGUu
Y2xvdWQudmlzaW9uLnYxGhlnb29nbGUvYXBpL3Jlc291cmNlLnByb3RvGiVnb29nbGUvY2xv
dWQvdmlzaW9uL3YxL2dlb21ldHJ5LnByb3RvGjNnb29nbGUvY2xvdWQvdmlzaW9uL3YxL3By
b2R1Y3Rfc2VhcmNoX3NlcnZpY2UucHJvdG8aH2dvb2dsZS9wcm90b2J1Zi90aW1lc3RhbXAu
cHJvdG8i7wEKE1Byb2R1Y3RTZWFyY2hQYXJhbXMSSQoNYm91bmRpbmdfcG9seRgJIAEoCzIk
Lmdvb2dsZS5jbG91ZC52aXNpb24udjEuQm91bmRpbmdQb2x5Ugxib3VuZGluZ1BvbHkSRgoL
cHJvZHVjdF9zZXQYBiABKAlCJfpBIgogdmlzaW9uLmdvb2dsZWFwaXMuY29tL1Byb2R1Y3RT
ZXRSCnByb2R1Y3RTZXQSLQoScHJvZHVjdF9jYXRlZ29yaWVzGAcgAygJUhFwcm9kdWN0Q2F0
ZWdvcmllcxIWCgZmaWx0ZXIYCCABKAlSBmZpbHRlciKUBgoUUHJvZHVjdFNlYXJjaFJlc3Vs
dHMSOQoKaW5kZXhfdGltZRgCIAEoCzIaLmdvb2dsZS5wcm90b2J1Zi5UaW1lc3RhbXBSCWlu
ZGV4VGltZRJNCgdyZXN1bHRzGAUgAygLMjMuZ29vZ2xlLmNsb3VkLnZpc2lvbi52MS5Qcm9k
dWN0U2VhcmNoUmVzdWx0cy5SZXN1bHRSB3Jlc3VsdHMScgoXcHJvZHVjdF9ncm91cGVkX3Jl
c3VsdHMYBiADKAsyOi5nb29nbGUuY2xvdWQudmlzaW9uLnYxLlByb2R1Y3RTZWFyY2hSZXN1
bHRzLkdyb3VwZWRSZXN1bHRSFXByb2R1Y3RHcm91cGVkUmVzdWx0cxpvCgZSZXN1bHQSOQoH
cHJvZHVjdBgBIAEoCzIfLmdvb2dsZS5jbG91ZC52aXNpb24udjEuUHJvZHVjdFIHcHJvZHVj
dBIUCgVzY29yZRgCIAEoAlIFc2NvcmUSFAoFaW1hZ2UYAyABKAlSBWltYWdlGnMKEE9iamVj
dEFubm90YXRpb24SEAoDbWlkGAEgASgJUgNtaWQSIwoNbGFuZ3VhZ2VfY29kZRgCIAEoCVIM
bGFuZ3VhZ2VDb2RlEhIKBG5hbWUYAyABKAlSBG5hbWUSFAoFc2NvcmUYBCABKAJSBXNjb3Jl
GpcCCg1Hcm91cGVkUmVzdWx0EkkKDWJvdW5kaW5nX3BvbHkYASABKAsyJC5nb29nbGUuY2xv
dWQudmlzaW9uLnYxLkJvdW5kaW5nUG9seVIMYm91bmRpbmdQb2x5Ek0KB3Jlc3VsdHMYAiAD
KAsyMy5nb29nbGUuY2xvdWQudmlzaW9uLnYxLlByb2R1Y3RTZWFyY2hSZXN1bHRzLlJlc3Vs
dFIHcmVzdWx0cxJsChJvYmplY3RfYW5ub3RhdGlvbnMYAyADKAsyPS5nb29nbGUuY2xvdWQu
dmlzaW9uLnYxLlByb2R1Y3RTZWFyY2hSZXN1bHRzLk9iamVjdEFubm90YXRpb25SEW9iamVj
dEFubm90YXRpb25zQnMKGmNvbS5nb29nbGUuY2xvdWQudmlzaW9uLnYxQhJQcm9kdWN0U2Vh
cmNoUHJvdG9QAVo1Y2xvdWQuZ29vZ2xlLmNvbS9nby92aXNpb24vdjIvYXBpdjEvdmlzaW9u
cGI7dmlzaW9ucGL4AQGiAgRHQ1ZOSr4lCgYSBA4AfAEKvAQKAQwSAw4AEjKxBCBDb3B5cmln
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
dGhlIExpY2Vuc2UuCgoICgECEgMQAB8KCQoCAwASAxIAIwoJCgIDARIDEwAvCgkKAgMCEgMU
AD0KCQoCAwMSAxUAKQoICgEIEgMXAB8KCQoCCB8SAxcAHwoICgEIEgMYAEwKCQoCCAsSAxgA
TAoICgEIEgMZACIKCQoCCAoSAxkAIgoICgEIEgMaADMKCQoCCAgSAxoAMwoICgEIEgMbADMK
CQoCCAESAxsAMwoICgEIEgMcACIKCQoCCCQSAxwAIgo2CgIEABIEHwA/ARoqIFBhcmFtZXRl
cnMgZm9yIGEgcHJvZHVjdCBzZWFyY2ggcmVxdWVzdC4KCgoKAwQAARIDHwgbCokBCgQEAAIA
EgMiAiEafCBUaGUgYm91bmRpbmcgcG9seWdvbiBhcm91bmQgdGhlIGFyZWEgb2YgaW50ZXJl
c3QgaW4gdGhlIGltYWdlLgogSWYgaXQgaXMgbm90IHNwZWNpZmllZCwgc3lzdGVtIGRpc2Ny
ZXRpb24gd2lsbCBiZSBhcHBsaWVkLgoKDAoFBAACAAYSAyICDgoMCgUEAAIAARIDIg8cCgwK
BQQAAgADEgMiHyAKzAEKBAQAAgESBCkCKwUavQEgVGhlIHJlc291cmNlIG5hbWUgb2YgYSBb
UHJvZHVjdFNldF1bZ29vZ2xlLmNsb3VkLnZpc2lvbi52MS5Qcm9kdWN0U2V0XSB0bwogYmUg
c2VhcmNoZWQgZm9yIHNpbWlsYXIgaW1hZ2VzLgoKIEZvcm1hdCBpczoKIGBwcm9qZWN0cy9Q
Uk9KRUNUX0lEL2xvY2F0aW9ucy9MT0NfSUQvcHJvZHVjdFNldHMvUFJPRFVDVF9TRVRfSURg
LgoKDAoFBAACAQUSAykCCAoMCgUEAAIBARIDKQkUCgwKBQQAAgEDEgMpFxgKDQoFBAACAQgS
BCkZKwQKDwoHBAACAQifCBIEKRorAwr8AwoEBAACAhIDNAIpGu4DIFRoZSBsaXN0IG9mIHBy
b2R1Y3QgY2F0ZWdvcmllcyB0byBzZWFyY2ggaW4uIEN1cnJlbnRseSwgd2Ugb25seSBjb25z
aWRlcgogdGhlIGZpcnN0IGNhdGVnb3J5LCBhbmQgZWl0aGVyICJob21lZ29vZHMtdjIiLCAi
YXBwYXJlbC12MiIsICJ0b3lzLXYyIiwKICJwYWNrYWdlZGdvb2RzLXYxIiwgb3IgImdlbmVy
YWwtdjEiIHNob3VsZCBiZSBzcGVjaWZpZWQuIFRoZSBsZWdhY3kKIGNhdGVnb3JpZXMgImhv
bWVnb29kcyIsICJhcHBhcmVsIiwgYW5kICJ0b3lzIiBhcmUgc3RpbGwgc3VwcG9ydGVkIGJ1
dCB3aWxsCiBiZSBkZXByZWNhdGVkLiBGb3IgbmV3IHByb2R1Y3RzLCBwbGVhc2UgdXNlICJo
b21lZ29vZHMtdjIiLCAiYXBwYXJlbC12MiIsCiBvciAidG95cy12MiIgZm9yIGJldHRlciBw
cm9kdWN0IHNlYXJjaCBhY2N1cmFjeS4gSXQgaXMgcmVjb21tZW5kZWQgdG8KIG1pZ3JhdGUg
ZXhpc3RpbmcgcHJvZHVjdHMgdG8gdGhlc2UgY2F0ZWdvcmllcyBhcyB3ZWxsLgoKDAoFBAAC
AgQSAzQCCgoMCgUEAAICBRIDNAsRCgwKBQQAAgIBEgM0EiQKDAoFBAACAgMSAzQnKArwAwoE
BAACAxIDPgIUGuIDIFRoZSBmaWx0ZXJpbmcgZXhwcmVzc2lvbi4gVGhpcyBjYW4gYmUgdXNl
ZCB0byByZXN0cmljdCBzZWFyY2ggcmVzdWx0cyBiYXNlZAogb24gUHJvZHVjdCBsYWJlbHMu
IFdlIGN1cnJlbnRseSBzdXBwb3J0IGFuIEFORCBvZiBPUiBvZiBrZXktdmFsdWUKIGV4cHJl
c3Npb25zLCB3aGVyZSBlYWNoIGV4cHJlc3Npb24gd2l0aGluIGFuIE9SIG11c3QgaGF2ZSB0
aGUgc2FtZSBrZXkuIEFuCiAnPScgc2hvdWxkIGJlIHVzZWQgdG8gY29ubmVjdCB0aGUga2V5
IGFuZCB2YWx1ZS4KCiBGb3IgZXhhbXBsZSwgIihjb2xvciA9IHJlZCBPUiBjb2xvciA9IGJs
dWUpIEFORCBicmFuZCA9IEdvb2dsZSIgaXMKIGFjY2VwdGFibGUsIGJ1dCAiKGNvbG9yID0g
cmVkIE9SIGJyYW5kID0gR29vZ2xlKSIgaXMgbm90IGFjY2VwdGFibGUuCiAiY29sb3I6IHJl
ZCIgaXMgbm90IGFjY2VwdGFibGUgYmVjYXVzZSBpdCB1c2VzIGEgJzonIGluc3RlYWQgb2Yg
YW4gJz0nLgoKDAoFBAACAwUSAz4CCAoMCgUEAAIDARIDPgkPCgwKBQQAAgMDEgM+EhMKMwoC
BAESBEIAfAEaJyBSZXN1bHRzIGZvciBhIHByb2R1Y3Qgc2VhcmNoIHJlcXVlc3QuCgoKCgME
AQESA0IIHAosCgQEAQMAEgREAk8DGh4gSW5mb3JtYXRpb24gYWJvdXQgYSBwcm9kdWN0LgoK
DAoFBAEDAAESA0QKEAodCgYEAQMAAgASA0YEGBoOIFRoZSBQcm9kdWN0LgoKDgoHBAEDAAIA
BhIDRgQLCg4KBwQBAwACAAESA0YMEwoOCgcEAQMAAgADEgNGFhcKaQoGBAEDAAIBEgNKBBQa
WiBBIGNvbmZpZGVuY2UgbGV2ZWwgb24gdGhlIG1hdGNoLCByYW5naW5nIGZyb20gMCAobm8g
Y29uZmlkZW5jZSkgdG8KIDEgKGZ1bGwgY29uZmlkZW5jZSkuCgoOCgcEAQMAAgEFEgNKBAkK
DgoHBAEDAAIBARIDSgoPCg4KBwQBAwACAQMSA0oSEwppCgYEAQMAAgISA04EFRpaIFRoZSBy
ZXNvdXJjZSBuYW1lIG9mIHRoZSBpbWFnZSBmcm9tIHRoZSBwcm9kdWN0IHRoYXQgaXMgdGhl
IGNsb3Nlc3QgbWF0Y2gKIHRvIHRoZSBxdWVyeS4KCg4KBwQBAwACAgUSA04ECgoOCgcEAQMA
AgIBEgNOCxAKDgoHBAEDAAICAxIDThMUCkYKBAQBAwESBFICYAMaOCBQcmVkaWN0aW9uIGZv
ciB3aGF0IHRoZSBvYmplY3QgaW4gdGhlIGJvdW5kaW5nIGJveCBpcy4KCgwKBQQBAwEBEgNS
ChoKRwoGBAEDAQIAEgNUBBMaOCBPYmplY3QgSUQgdGhhdCBzaG91bGQgYWxpZ24gd2l0aCBF
bnRpdHlBbm5vdGF0aW9uIG1pZC4KCg4KBwQBAwECAAUSA1QECgoOCgcEAQMBAgABEgNUCw4K
DgoHBAEDAQIAAxIDVBESCqUBCgYEAQMBAgESA1kEHRqVASBUaGUgQkNQLTQ3IGxhbmd1YWdl
IGNvZGUsIHN1Y2ggYXMgImVuLVVTIiBvciAic3ItTGF0biIuIEZvciBtb3JlCiBpbmZvcm1h
dGlvbiwgc2VlCiBodHRwOi8vd3d3LnVuaWNvZGUub3JnL3JlcG9ydHMvdHIzNS8jVW5pY29k
ZV9sb2NhbGVfaWRlbnRpZmllci4KCg4KBwQBAwECAQUSA1kECgoOCgcEAQMBAgEBEgNZCxgK
DgoHBAEDAQIBAxIDWRscCkgKBgQBAwECAhIDXAQUGjkgT2JqZWN0IG5hbWUsIGV4cHJlc3Nl
ZCBpbiBpdHMgYGxhbmd1YWdlX2NvZGVgIGxhbmd1YWdlLgoKDgoHBAEDAQICBRIDXAQKCg4K
BwQBAwECAgESA1wLDwoOCgcEAQMBAgIDEgNcEhMKMwoGBAEDAQIDEgNfBBQaJCBTY29yZSBv
ZiB0aGUgcmVzdWx0LiBSYW5nZSBbMCwgMV0uCgoOCgcEAQMBAgMFEgNfBAkKDgoHBAEDAQID
ARIDXwoPCg4KBwQBAwECAwMSA18SEwpdCgQEAQMCEgRkAm0DGk8gSW5mb3JtYXRpb24gYWJv
dXQgdGhlIHByb2R1Y3RzIHNpbWlsYXIgdG8gYSBzaW5nbGUgcHJvZHVjdCBpbiBhIHF1ZXJ5
CiBpbWFnZS4KCgwKBQQBAwIBEgNkChcKVQoGBAEDAgIAEgNmBCMaRiBUaGUgYm91bmRpbmcg
cG9seWdvbiBhcm91bmQgdGhlIHByb2R1Y3QgZGV0ZWN0ZWQgaW4gdGhlIHF1ZXJ5IGltYWdl
LgoKDgoHBAEDAgIABhIDZgQQCg4KBwQBAwICAAESA2YRHgoOCgcEAQMCAgADEgNmISIKPQoG
BAEDAgIBEgNpBCAaLiBMaXN0IG9mIHJlc3VsdHMsIG9uZSBmb3IgZWFjaCBwcm9kdWN0IG1h
dGNoLgoKDgoHBAEDAgIBBBIDaQQMCg4KBwQBAwICAQYSA2kNEwoOCgcEAQMCAgEBEgNpFBsK
DgoHBAEDAgIBAxIDaR4fClAKBgQBAwICAhIDbAQ1GkEgTGlzdCBvZiBnZW5lcmljIHByZWRp
Y3Rpb25zIGZvciB0aGUgb2JqZWN0IGluIHRoZSBib3VuZGluZyBib3guCgoOCgcEAQMCAgIE
EgNsBAwKDgoHBAEDAgICBhIDbA0dCg4KBwQBAwICAgESA2weMAoOCgcEAQMCAgIDEgNsMzQK
zAEKBAQBAgASA3ICKxq+ASBUaW1lc3RhbXAgb2YgdGhlIGluZGV4IHdoaWNoIHByb3ZpZGVk
IHRoZXNlIHJlc3VsdHMuIFByb2R1Y3RzIGFkZGVkIHRvIHRoZQogcHJvZHVjdCBzZXQgYW5k
IHByb2R1Y3RzIHJlbW92ZWQgZnJvbSB0aGUgcHJvZHVjdCBzZXQgYWZ0ZXIgdGhpcyB0aW1l
IGFyZQogbm90IHJlZmxlY3RlZCBpbiB0aGUgY3VycmVudCByZXN1bHRzLgoKDAoFBAECAAYS
A3ICGwoMCgUEAQIAARIDchwmCgwKBQQBAgADEgNyKSoKOwoEBAECARIDdQIeGi4gTGlzdCBv
ZiByZXN1bHRzLCBvbmUgZm9yIGVhY2ggcHJvZHVjdCBtYXRjaC4KCgwKBQQBAgEEEgN1AgoK
DAoFBAECAQYSA3ULEQoMCgUEAQIBARIDdRIZCgwKBQQBAgEDEgN1HB0KpgIKBAQBAgISA3sC
NRqYAiBMaXN0IG9mIHJlc3VsdHMgZ3JvdXBlZCBieSBwcm9kdWN0cyBkZXRlY3RlZCBpbiB0
aGUgcXVlcnkgaW1hZ2UuIEVhY2ggZW50cnkKIGNvcnJlc3BvbmRzIHRvIG9uZSBib3VuZGlu
ZyBwb2x5Z29uIGluIHRoZSBxdWVyeSBpbWFnZSwgYW5kIGNvbnRhaW5zIHRoZQogbWF0Y2hp
bmcgcHJvZHVjdHMgc3BlY2lmaWMgdG8gdGhhdCByZWdpb24uIFRoZXJlIG1heSBiZSBkdXBs
aWNhdGUgcHJvZHVjdAogbWF0Y2hlcyBpbiB0aGUgdW5pb24gb2YgYWxsIHRoZSBwZXItcHJv
ZHVjdCByZXN1bHRzLgoKDAoFBAECAgQSA3sCCgoMCgUEAQICBhIDewsYCgwKBQQBAgIBEgN7
GTAKDAoFBAECAgMSA3szNGIGcHJvdG8z
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Vision::V1::ProductSearch::ProductSearchParams ===
    # Fields for ProductSearchParams
    # Field: bounding_poly Type: 11 (.google.cloud.vision.v1.BoundingPoly)
    # Field: product_set Type: 9 ()
    # Field: product_categories Type: 9 ()
    # Field: filter Type: 9 ()

# === Message: Google::Cloud::Vision::V1::ProductSearch::ProductSearchResults ===
    # Fields for ProductSearchResults
    # Field: index_time Type: 11 (.google.protobuf.Timestamp)
    # Field: results Type: 11 (.google.cloud.vision.v1.ProductSearchResults.Result)
    # Field: product_grouped_results Type: 11 (.google.cloud.vision.v1.ProductSearchResults.GroupedResult)

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Vision::V1::ProductSearch - Compiled Protocol Buffers messages for google/cloud/vision/v1/product_search.proto

=head1 SYNOPSIS

    use Google::Cloud::Vision::V1::ProductSearch;

    my $msg = Google::Cloud::Vision::V1::ProductSearch::ProductSearchParams->new({
        bounding_poly => $bounding_poly,
        product_set => $product_set,
        product_categories => $product_categories,
        filter => $filter,
    });

    # Read or update a field
    my $val = $msg->bounding_poly();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Vision::V1::ProductSearch::ProductSearchParams->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/vision/v1/product_search.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Vision::V1::ProductSearch::ProductSearchParams

Parameters for a product search request.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->bounding_poly() >> / C<< $msg->bounding_poly($value) >>

Type: C<Message> (L<Google::Cloud::Vision::V1::Geometry::BoundingPoly>)

The bounding polygon around the area of interest in the image.
If it is not specified, system discretion will be applied.

=item * C<< $msg->product_set() >> / C<< $msg->product_set($value) >>

Type: C<String>

The resource name of a [ProductSet][google.cloud.vision.v1.ProductSet] to
be searched for similar images.

Format is:
`projects/PROJECT_ID/locations/LOC_ID/productSets/PRODUCT_SET_ID`.

=item * C<< $msg->product_categories() >> / C<< $msg->product_categories($value) >>

Type: C<String>

The list of product categories to search in. Currently, we only consider
the first category, and either "homegoods-v2", "apparel-v2", "toys-v2",
"packagedgoods-v1", or "general-v1" should be specified. The legacy
categories "homegoods", "apparel", and "toys" are still supported but will
be deprecated. For new products, please use "homegoods-v2", "apparel-v2",
or "toys-v2" for better product search accuracy. It is recommended to
migrate existing products to these categories as well.

=item * C<< $msg->filter() >> / C<< $msg->filter($value) >>

Type: C<String>

The filtering expression. This can be used to restrict search results based
on Product labels. We currently support an AND of OR of key-value
expressions, where each expression within an OR must have the same key. An
'=' should be used to connect the key and value.

For example, "(color = red OR color = blue) AND brand = Google" is
acceptable, but "(color = red OR brand = Google)" is not acceptable.
"color: red" is not acceptable because it uses a ':' instead of an '='.

=back

=head2 Google::Cloud::Vision::V1::ProductSearch::ProductSearchResults

Results for a product search request.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->index_time() >> / C<< $msg->index_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Timestamp of the index which provided these results. Products added to the
product set and products removed from the product set after this time are
not reflected in the current results.

=item * C<< $msg->results() >> / C<< $msg->results($value) >>

Type: C<Message> (L<Google::Cloud::Vision::V1::ProductSearch::ProductSearchResults::Result>)

List of results, one for each product match.

=item * C<< $msg->product_grouped_results() >> / C<< $msg->product_grouped_results($value) >>

Type: C<Message> (L<Google::Cloud::Vision::V1::ProductSearch::ProductSearchResults::GroupedResult>)

List of results grouped by products detected in the query image. Each entry
corresponds to one bounding polygon in the query image, and contains the
matching products specific to that region. There may be duplicate product
matches in the union of all the per-product results.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Vision::V1::ProductSearch::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
