package Google::Cloud::Discoveryengine::V1alpha::Completion;

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
CjVnb29nbGUvY2xvdWQvZGlzY292ZXJ5ZW5naW5lL3YxYWxwaGEvY29tcGxldGlvbi5wcm90
bxIkZ29vZ2xlLmNsb3VkLmRpc2NvdmVyeWVuZ2luZS52MWFscGhhGh9nb29nbGUvYXBpL2Zp
ZWxkX2JlaGF2aW9yLnByb3RvIooCChdTdWdnZXN0aW9uRGVueUxpc3RFbnRyeRImCgxibG9j
a19waHJhc2UYASABKAlCA+BBAlILYmxvY2tQaHJhc2USdwoObWF0Y2hfb3BlcmF0b3IYAiAB
KA4ySy5nb29nbGUuY2xvdWQuZGlzY292ZXJ5ZW5naW5lLnYxYWxwaGEuU3VnZ2VzdGlvbkRl
bnlMaXN0RW50cnkuTWF0Y2hPcGVyYXRvckID4EECUg1tYXRjaE9wZXJhdG9yIk4KDU1hdGNo
T3BlcmF0b3ISHgoaTUFUQ0hfT1BFUkFUT1JfVU5TUEVDSUZJRUQQABIPCgtFWEFDVF9NQVRD
SBABEgwKCENPTlRBSU5TEAIiogIKFENvbXBsZXRpb25TdWdnZXN0aW9uEiMKDGdsb2JhbF9z
Y29yZRgCIAEoAUgAUgtnbG9iYWxTY29yZRIeCglmcmVxdWVuY3kYAyABKANIAFIJZnJlcXVl
bmN5EiMKCnN1Z2dlc3Rpb24YASABKAlCA+BBAlIKc3VnZ2VzdGlvbhIjCg1sYW5ndWFnZV9j
b2RlGAQgASgJUgxsYW5ndWFnZUNvZGUSGQoIZ3JvdXBfaWQYBSABKAlSB2dyb3VwSWQSHwoL
Z3JvdXBfc2NvcmUYBiABKAFSCmdyb3VwU2NvcmUSLwoTYWx0ZXJuYXRpdmVfcGhyYXNlcxgH
IAMoCVISYWx0ZXJuYXRpdmVQaHJhc2VzQg4KDHJhbmtpbmdfaW5mb0KbAgooY29tLmdvb2ds
ZS5jbG91ZC5kaXNjb3ZlcnllbmdpbmUudjFhbHBoYUIPQ29tcGxldGlvblByb3RvUAFaUmNs
b3VkLmdvb2dsZS5jb20vZ28vZGlzY292ZXJ5ZW5naW5lL2FwaXYxYWxwaGEvZGlzY292ZXJ5
ZW5naW5lcGI7ZGlzY292ZXJ5ZW5naW5lcGKiAg9ESVNDT1ZFUllFTkdJTkWqAiRHb29nbGUu
Q2xvdWQuRGlzY292ZXJ5RW5naW5lLlYxQWxwaGHKAiRHb29nbGVcQ2xvdWRcRGlzY292ZXJ5
RW5naW5lXFYxYWxwaGHqAidHb29nbGU6OkNsb3VkOjpEaXNjb3ZlcnlFbmdpbmU6OlYxYWxw
aGFKuhYKBhIEDgBSAQq8BAoBDBIDDgASMrEEIENvcHlyaWdodCAyMDI1IEdvb2dsZSBMTEMK
CiBMaWNlbnNlZCB1bmRlciB0aGUgQXBhY2hlIExpY2Vuc2UsIFZlcnNpb24gMi4wICh0aGUg
IkxpY2Vuc2UiKTsKIHlvdSBtYXkgbm90IHVzZSB0aGlzIGZpbGUgZXhjZXB0IGluIGNvbXBs
aWFuY2Ugd2l0aCB0aGUgTGljZW5zZS4KIFlvdSBtYXkgb2J0YWluIGEgY29weSBvZiB0aGUg
TGljZW5zZSBhdAoKICAgICBodHRwOi8vd3d3LmFwYWNoZS5vcmcvbGljZW5zZXMvTElDRU5T
RS0yLjAKCiBVbmxlc3MgcmVxdWlyZWQgYnkgYXBwbGljYWJsZSBsYXcgb3IgYWdyZWVkIHRv
IGluIHdyaXRpbmcsIHNvZnR3YXJlCiBkaXN0cmlidXRlZCB1bmRlciB0aGUgTGljZW5zZSBp
cyBkaXN0cmlidXRlZCBvbiBhbiAiQVMgSVMiIEJBU0lTLAogV0lUSE9VVCBXQVJSQU5USUVT
IE9SIENPTkRJVElPTlMgT0YgQU5ZIEtJTkQsIGVpdGhlciBleHByZXNzIG9yIGltcGxpZWQu
CiBTZWUgdGhlIExpY2Vuc2UgZm9yIHRoZSBzcGVjaWZpYyBsYW5ndWFnZSBnb3Zlcm5pbmcg
cGVybWlzc2lvbnMgYW5kCiBsaW1pdGF0aW9ucyB1bmRlciB0aGUgTGljZW5zZS4KCggKAQIS
AxAALQoJCgIDABIDEgApCggKAQgSAxQAQQoJCgIIJRIDFABBCggKAQgSAxUAaQoJCgIICxID
FQBpCggKAQgSAxYAIgoJCgIIChIDFgAiCggKAQgSAxcAMAoJCgIICBIDFwAwCggKAQgSAxgA
QQoJCgIIARIDGABBCggKAQgSAxkALQoJCgIIJBIDGQAtCggKAQgSAxoAQQoJCgIIKRIDGgBB
CggKAQgSAxsAQAoJCgIILRIDGwBACoQBCgIEABIEHwAzARp4IFN1Z2dlc3Rpb24gZGVueSBs
aXN0IGVudHJ5IGlkZW50aWZ5aW5nIHRoZSBwaHJhc2UgdG8gYmxvY2sgZnJvbSBzdWdnZXN0
aW9ucwogYW5kIHRoZSBhcHBsaWVkIG9wZXJhdGlvbiBmb3IgdGhlIHBocmFzZS4KCgoKAwQA
ARIDHwgfCkUKBAQABAASBCECKgMaNyBPcGVyYXRvciBmb3IgbWF0Y2hpbmcgd2l0aCB0aGUg
Z2VuZXJhdGVkIHN1Z2dlc3Rpb25zLgoKDAoFBAAEAAESAyEHFAoyCgYEAAQAAgASAyMEIxoj
IERlZmF1bHQgdmFsdWUuIFNob3VsZCBub3QgYmUgdXNlZAoKDgoHBAAEAAIAARIDIwQeCg4K
BwQABAACAAISAyMhIgpYCgYEAAQAAgESAyYEFBpJIElmIHRoZSBzdWdnZXN0aW9uIGlzIGFu
IGV4YWN0IG1hdGNoIHRvIHRoZSBibG9ja19waHJhc2UsIHRoZW4gYmxvY2sgaXQuCgoOCgcE
AAQAAgEBEgMmBA8KDgoHBAAEAAIBAhIDJhITCkwKBgQABAACAhIDKQQRGj0gSWYgdGhlIHN1
Z2dlc3Rpb24gY29udGFpbnMgdGhlIGJsb2NrX3BocmFzZSwgdGhlbiBibG9jayBpdC4KCg4K
BwQABAACAgESAykEDAoOCgcEAAQAAgICEgMpDxAKYQoEBAACABIDLgJDGlQgUmVxdWlyZWQu
IFBocmFzZSB0byBibG9jayBmcm9tIHN1Z2dlc3Rpb25zIHNlcnZlZC4gQ2FuIGJlIG1heGlt
dW0gMTI1CiBjaGFyYWN0ZXJzLgoKDAoFBAACAAUSAy4CCAoMCgUEAAIAARIDLgkVCgwKBQQA
AgADEgMuGBkKDAoFBAACAAgSAy4aQgoPCggEAAIACJwIABIDLhtBCpsBCgQEAAIBEgMyAkwa
jQEgUmVxdWlyZWQuIFRoZSBtYXRjaCBvcGVyYXRvciB0byBhcHBseSBmb3IgdGhpcyBwaHJh
c2UuIFdoZXRoZXIgdG8gYmxvY2sgdGhlCiBleGFjdCBwaHJhc2UsIG9yIGJsb2NrIGFueSBz
dWdnZXN0aW9ucyBjb250YWluaW5nIHRoaXMgcGhyYXNlLgoKDAoFBAACAQYSAzICDwoMCgUE
AAIBARIDMhAeCgwKBQQAAgEDEgMyISIKDAoFBAACAQgSAzIjSwoPCggEAAIBCJwIABIDMiRK
CkcKAgQBEgQ2AFIBGjsgQXV0b2NvbXBsZXRlIHN1Z2dlc3Rpb25zIHRoYXQgYXJlIGltcG9y
dGVkIGZyb20gQ3VzdG9tZXIuCgoKCgMEAQESAzYIHAozCgQEAQgAEgQ4AkADGiUgUmFua2lu
ZyBtZXRyaWNzIG9mIHRoaXMgc3VnZ2VzdGlvbi4KCgwKBQQBCAABEgM4CBQKZgoEBAECABID
OwQcGlkgR2xvYmFsIHNjb3JlIG9mIHRoaXMgc3VnZ2VzdGlvbi4gQ29udHJvbCBob3cgdGhp
cyBzdWdnZXN0aW9uIHdvdWxkIGJlCiBzY29yZWQgLyByYW5rZWQuCgoMCgUEAQIABRIDOwQK
CgwKBQQBAgABEgM7CxcKDAoFBAECAAMSAzsaGwprCgQEAQIBEgM/BBgaXiBGcmVxdWVuY3kg
b2YgdGhpcyBzdWdnZXN0aW9uLiBXaWxsIGJlIHVzZWQgdG8gcmFuayBzdWdnZXN0aW9ucyB3
aGVuIHNjb3JlCiBpcyBub3QgYXZhaWxhYmxlLgoKDAoFBAECAQUSAz8ECQoMCgUEAQIBARID
PwoTCgwKBQQBAgEDEgM/FhcKLQoEBAECAhIDQwJBGiAgUmVxdWlyZWQuIFRoZSBzdWdnZXN0
aW9uIHRleHQuCgoMCgUEAQICBRIDQwIICgwKBQQBAgIBEgNDCRMKDAoFBAECAgMSA0MWFwoM
CgUEAQICCBIDQxhACg8KCAQBAgIInAgAEgNDGT8KNwoEBAECAxIDRgIbGiogQkNQLTQ3IGxh
bmd1YWdlIGNvZGUgb2YgdGhpcyBzdWdnZXN0aW9uLgoKDAoFBAECAwUSA0YCCAoMCgUEAQID
ARIDRgkWCgwKBQQBAgMDEgNGGRoK0wEKBAQBAgQSA0sCFhrFASBJZiB0d28gc3VnZ2VzdGlv
bnMgaGF2ZSB0aGUgc2FtZSBncm91cElkLCB0aGV5IHdpbGwgbm90IGJlCiByZXR1cm5lZCB0
b2dldGhlci4gSW5zdGVhZCB0aGUgb25lIHJhbmtlZCBoaWdoZXIgd2lsbCBiZSByZXR1cm5l
ZC4gVGhpcyBjYW4KIGJlIHVzZWQgdG8gZGVkdXBsaWNhdGUgc2VtYW50aWNhbGx5IGlkZW50
aWNhbCBzdWdnZXN0aW9ucy4KCgwKBQQBAgQFEgNLAggKDAoFBAECBAESA0sJEQoMCgUEAQIE
AxIDSxQVCj0KBAQBAgUSA04CGRowIFRoZSBzY29yZSBvZiB0aGlzIHN1Z2dlc3Rpb24gd2l0
aGluIGl0cyBncm91cC4KCgwKBQQBAgUFEgNOAggKDAoFBAECBQESA04JFAoMCgUEAQIFAxID
ThcYCkAKBAQBAgYSA1ECKhozIEFsdGVybmF0aXZlIG1hdGNoaW5nIHBocmFzZXMgZm9yIHRo
aXMgc3VnZ2VzdGlvbi4KCgwKBQQBAgYEEgNRAgoKDAoFBAECBgUSA1ELEQoMCgUEAQIGARID
URIlCgwKBQQBAgYDEgNRKCliBnByb3RvMw==
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Discoveryengine::V1alpha::Completion::SuggestionDenyListEntry ===
    # Fields for SuggestionDenyListEntry
    # Field: block_phrase Type: 9 ()
    # Field: match_operator Type: 14 (.google.cloud.discoveryengine.v1alpha.SuggestionDenyListEntry.MatchOperator)

# Enum: SuggestionDenyListEntry::MatchOperator
our $SuggestionDenyListEntry_MATCH_OPERATOR_UNSPECIFIED = 0;
our $SuggestionDenyListEntry_EXACT_MATCH = 1;
our $SuggestionDenyListEntry_CONTAINS = 2;

# === Message: Google::Cloud::Discoveryengine::V1alpha::Completion::CompletionSuggestion ===
    # Fields for CompletionSuggestion
    # Field: global_score Type: 1 ()
    # Field: frequency Type: 3 ()
    # Field: suggestion Type: 9 ()
    # Field: language_code Type: 9 ()
    # Field: group_id Type: 9 ()
    # Field: group_score Type: 1 ()
    # Field: alternative_phrases Type: 9 ()

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Discoveryengine::V1alpha::Completion - Compiled Protocol Buffers messages for google/cloud/discoveryengine/v1alpha/completion.proto

=head1 SYNOPSIS

    use Google::Cloud::Discoveryengine::V1alpha::Completion;

    my $msg = Google::Cloud::Discoveryengine::V1alpha::Completion::SuggestionDenyListEntry->new({
        block_phrase => $block_phrase,
        match_operator => $match_operator,
    });

    # Read or update a field
    my $val = $msg->block_phrase();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Discoveryengine::V1alpha::Completion::SuggestionDenyListEntry->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/discoveryengine/v1alpha/completion.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Discoveryengine::V1alpha::Completion::SuggestionDenyListEntry

Suggestion deny list entry identifying the phrase to block from suggestions
and the applied operation for the phrase.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->block_phrase() >> / C<< $msg->block_phrase($value) >>

Type: C<String>

Required. Phrase to block from suggestions served. Can be maximum 125
characters.

=item * C<< $msg->match_operator() >> / C<< $msg->match_operator($value) >>

Type: C<Enum> (L<Google::Cloud::Discoveryengine::V1alpha::SuggestionDenyListEntry::MatchOperator>)

Required. The match operator to apply for this phrase. Whether to block the
exact phrase, or block any suggestions containing this phrase.

=back

=head3 Enum: SuggestionDenyListEntry::MatchOperator

=over 4

=item * C<MATCH_OPERATOR_UNSPECIFIED> => C<0>

=item * C<EXACT_MATCH> => C<1>

=item * C<CONTAINS> => C<2>

=back

=head2 Google::Cloud::Discoveryengine::V1alpha::Completion::CompletionSuggestion

Autocomplete suggestions that are imported from Customer.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->global_score() >> / C<< $msg->global_score($value) >>

Type: C<Double>

Global score of this suggestion. Control how this suggestion would be
scored / ranked.

=item * C<< $msg->frequency() >> / C<< $msg->frequency($value) >>

Type: C<Int64>

Frequency of this suggestion. Will be used to rank suggestions when score
is not available.

=item * C<< $msg->suggestion() >> / C<< $msg->suggestion($value) >>

Type: C<String>

Required. The suggestion text.

=item * C<< $msg->language_code() >> / C<< $msg->language_code($value) >>

Type: C<String>

BCP-47 language code of this suggestion.

=item * C<< $msg->group_id() >> / C<< $msg->group_id($value) >>

Type: C<String>

If two suggestions have the same groupId, they will not be
returned together. Instead the one ranked higher will be returned. This can
be used to deduplicate semantically identical suggestions.

=item * C<< $msg->group_score() >> / C<< $msg->group_score($value) >>

Type: C<Double>

The score of this suggestion within its group.

=item * C<< $msg->alternative_phrases() >> / C<< $msg->alternative_phrases($value) >>

Type: C<String>

Alternative matching phrases for this suggestion.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Discoveryengine::V1alpha::Completion::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
