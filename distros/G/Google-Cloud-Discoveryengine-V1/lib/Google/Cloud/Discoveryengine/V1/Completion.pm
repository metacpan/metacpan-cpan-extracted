package Google::Cloud::Discoveryengine::V1::Completion;

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
CjBnb29nbGUvY2xvdWQvZGlzY292ZXJ5ZW5naW5lL3YxL2NvbXBsZXRpb24ucHJvdG8SH2dv
b2dsZS5jbG91ZC5kaXNjb3ZlcnllbmdpbmUudjEaH2dvb2dsZS9hcGkvZmllbGRfYmVoYXZp
b3IucHJvdG8ihQIKF1N1Z2dlc3Rpb25EZW55TGlzdEVudHJ5EiYKDGJsb2NrX3BocmFzZRgB
IAEoCUID4EECUgtibG9ja1BocmFzZRJyCg5tYXRjaF9vcGVyYXRvchgCIAEoDjJGLmdvb2ds
ZS5jbG91ZC5kaXNjb3ZlcnllbmdpbmUudjEuU3VnZ2VzdGlvbkRlbnlMaXN0RW50cnkuTWF0
Y2hPcGVyYXRvckID4EECUg1tYXRjaE9wZXJhdG9yIk4KDU1hdGNoT3BlcmF0b3ISHgoaTUFU
Q0hfT1BFUkFUT1JfVU5TUEVDSUZJRUQQABIPCgtFWEFDVF9NQVRDSBABEgwKCENPTlRBSU5T
EAIiogIKFENvbXBsZXRpb25TdWdnZXN0aW9uEiMKDGdsb2JhbF9zY29yZRgCIAEoAUgAUgtn
bG9iYWxTY29yZRIeCglmcmVxdWVuY3kYAyABKANIAFIJZnJlcXVlbmN5EiMKCnN1Z2dlc3Rp
b24YASABKAlCA+BBAlIKc3VnZ2VzdGlvbhIjCg1sYW5ndWFnZV9jb2RlGAQgASgJUgxsYW5n
dWFnZUNvZGUSGQoIZ3JvdXBfaWQYBSABKAlSB2dyb3VwSWQSHwoLZ3JvdXBfc2NvcmUYBiAB
KAFSCmdyb3VwU2NvcmUSLwoTYWx0ZXJuYXRpdmVfcGhyYXNlcxgHIAMoCVISYWx0ZXJuYXRp
dmVQaHJhc2VzQg4KDHJhbmtpbmdfaW5mb0KCAgojY29tLmdvb2dsZS5jbG91ZC5kaXNjb3Zl
cnllbmdpbmUudjFCD0NvbXBsZXRpb25Qcm90b1ABWk1jbG91ZC5nb29nbGUuY29tL2dvL2Rp
c2NvdmVyeWVuZ2luZS9hcGl2MS9kaXNjb3ZlcnllbmdpbmVwYjtkaXNjb3ZlcnllbmdpbmVw
YqICD0RJU0NPVkVSWUVOR0lORaoCH0dvb2dsZS5DbG91ZC5EaXNjb3ZlcnlFbmdpbmUuVjHK
Ah9Hb29nbGVcQ2xvdWRcRGlzY292ZXJ5RW5naW5lXFYx6gIiR29vZ2xlOjpDbG91ZDo6RGlz
Y292ZXJ5RW5naW5lOjpWMUq6FgoGEgQOAFIBCrwECgEMEgMOABIysQQgQ29weXJpZ2h0IDIw
MjYgR29vZ2xlIExMQwoKIExpY2Vuc2VkIHVuZGVyIHRoZSBBcGFjaGUgTGljZW5zZSwgVmVy
c2lvbiAyLjAgKHRoZSAiTGljZW5zZSIpOwogeW91IG1heSBub3QgdXNlIHRoaXMgZmlsZSBl
eGNlcHQgaW4gY29tcGxpYW5jZSB3aXRoIHRoZSBMaWNlbnNlLgogWW91IG1heSBvYnRhaW4g
YSBjb3B5IG9mIHRoZSBMaWNlbnNlIGF0CgogICAgIGh0dHA6Ly93d3cuYXBhY2hlLm9yZy9s
aWNlbnNlcy9MSUNFTlNFLTIuMAoKIFVubGVzcyByZXF1aXJlZCBieSBhcHBsaWNhYmxlIGxh
dyBvciBhZ3JlZWQgdG8gaW4gd3JpdGluZywgc29mdHdhcmUKIGRpc3RyaWJ1dGVkIHVuZGVy
IHRoZSBMaWNlbnNlIGlzIGRpc3RyaWJ1dGVkIG9uIGFuICJBUyBJUyIgQkFTSVMsCiBXSVRI
T1VUIFdBUlJBTlRJRVMgT1IgQ09ORElUSU9OUyBPRiBBTlkgS0lORCwgZWl0aGVyIGV4cHJl
c3Mgb3IgaW1wbGllZC4KIFNlZSB0aGUgTGljZW5zZSBmb3IgdGhlIHNwZWNpZmljIGxhbmd1
YWdlIGdvdmVybmluZyBwZXJtaXNzaW9ucyBhbmQKIGxpbWl0YXRpb25zIHVuZGVyIHRoZSBM
aWNlbnNlLgoKCAoBAhIDEAAoCgkKAgMAEgMSACkKCAoBCBIDFAA8CgkKAgglEgMUADwKCAoB
CBIDFQBkCgkKAggLEgMVAGQKCAoBCBIDFgAiCgkKAggKEgMWACIKCAoBCBIDFwAwCgkKAggI
EgMXADAKCAoBCBIDGAA8CgkKAggBEgMYADwKCAoBCBIDGQAtCgkKAggkEgMZAC0KCAoBCBID
GgA8CgkKAggpEgMaADwKCAoBCBIDGwA7CgkKAggtEgMbADsKhAEKAgQAEgQfADMBGnggU3Vn
Z2VzdGlvbiBkZW55IGxpc3QgZW50cnkgaWRlbnRpZnlpbmcgdGhlIHBocmFzZSB0byBibG9j
ayBmcm9tIHN1Z2dlc3Rpb25zCiBhbmQgdGhlIGFwcGxpZWQgb3BlcmF0aW9uIGZvciB0aGUg
cGhyYXNlLgoKCgoDBAABEgMfCB8KRQoEBAAEABIEIQIqAxo3IE9wZXJhdG9yIGZvciBtYXRj
aGluZyB3aXRoIHRoZSBnZW5lcmF0ZWQgc3VnZ2VzdGlvbnMuCgoMCgUEAAQAARIDIQcUCjIK
BgQABAACABIDIwQjGiMgRGVmYXVsdCB2YWx1ZS4gU2hvdWxkIG5vdCBiZSB1c2VkCgoOCgcE
AAQAAgABEgMjBB4KDgoHBAAEAAIAAhIDIyEiClgKBgQABAACARIDJgQUGkkgSWYgdGhlIHN1
Z2dlc3Rpb24gaXMgYW4gZXhhY3QgbWF0Y2ggdG8gdGhlIGJsb2NrX3BocmFzZSwgdGhlbiBi
bG9jayBpdC4KCg4KBwQABAACAQESAyYEDwoOCgcEAAQAAgECEgMmEhMKTAoGBAAEAAICEgMp
BBEaPSBJZiB0aGUgc3VnZ2VzdGlvbiBjb250YWlucyB0aGUgYmxvY2tfcGhyYXNlLCB0aGVu
IGJsb2NrIGl0LgoKDgoHBAAEAAICARIDKQQMCg4KBwQABAACAgISAykPEAphCgQEAAIAEgMu
AkMaVCBSZXF1aXJlZC4gUGhyYXNlIHRvIGJsb2NrIGZyb20gc3VnZ2VzdGlvbnMgc2VydmVk
LiBDYW4gYmUgbWF4aW11bSAxMjUKIGNoYXJhY3RlcnMuCgoMCgUEAAIABRIDLgIICgwKBQQA
AgABEgMuCRUKDAoFBAACAAMSAy4YGQoMCgUEAAIACBIDLhpCCg8KCAQAAgAInAgAEgMuG0EK
mwEKBAQAAgESAzICTBqNASBSZXF1aXJlZC4gVGhlIG1hdGNoIG9wZXJhdG9yIHRvIGFwcGx5
IGZvciB0aGlzIHBocmFzZS4gV2hldGhlciB0byBibG9jayB0aGUKIGV4YWN0IHBocmFzZSwg
b3IgYmxvY2sgYW55IHN1Z2dlc3Rpb25zIGNvbnRhaW5pbmcgdGhpcyBwaHJhc2UuCgoMCgUE
AAIBBhIDMgIPCgwKBQQAAgEBEgMyEB4KDAoFBAACAQMSAzIhIgoMCgUEAAIBCBIDMiNLCg8K
CAQAAgEInAgAEgMyJEoKRwoCBAESBDYAUgEaOyBBdXRvY29tcGxldGUgc3VnZ2VzdGlvbnMg
dGhhdCBhcmUgaW1wb3J0ZWQgZnJvbSBDdXN0b21lci4KCgoKAwQBARIDNggcCjMKBAQBCAAS
BDgCQAMaJSBSYW5raW5nIG1ldHJpY3Mgb2YgdGhpcyBzdWdnZXN0aW9uLgoKDAoFBAEIAAES
AzgIFApmCgQEAQIAEgM7BBwaWSBHbG9iYWwgc2NvcmUgb2YgdGhpcyBzdWdnZXN0aW9uLiBD
b250cm9sIGhvdyB0aGlzIHN1Z2dlc3Rpb24gd291bGQgYmUKIHNjb3JlZCAvIHJhbmtlZC4K
CgwKBQQBAgAFEgM7BAoKDAoFBAECAAESAzsLFwoMCgUEAQIAAxIDOxobCmsKBAQBAgESAz8E
GBpeIEZyZXF1ZW5jeSBvZiB0aGlzIHN1Z2dlc3Rpb24uIFdpbGwgYmUgdXNlZCB0byByYW5r
IHN1Z2dlc3Rpb25zIHdoZW4gc2NvcmUKIGlzIG5vdCBhdmFpbGFibGUuCgoMCgUEAQIBBRID
PwQJCgwKBQQBAgEBEgM/ChMKDAoFBAECAQMSAz8WFwotCgQEAQICEgNDAkEaICBSZXF1aXJl
ZC4gVGhlIHN1Z2dlc3Rpb24gdGV4dC4KCgwKBQQBAgIFEgNDAggKDAoFBAECAgESA0MJEwoM
CgUEAQICAxIDQxYXCgwKBQQBAgIIEgNDGEAKDwoIBAECAgicCAASA0MZPwo3CgQEAQIDEgNG
AhsaKiBCQ1AtNDcgbGFuZ3VhZ2UgY29kZSBvZiB0aGlzIHN1Z2dlc3Rpb24uCgoMCgUEAQID
BRIDRgIICgwKBQQBAgMBEgNGCRYKDAoFBAECAwMSA0YZGgrTAQoEBAECBBIDSwIWGsUBIElm
IHR3byBzdWdnZXN0aW9ucyBoYXZlIHRoZSBzYW1lIGdyb3VwSWQsIHRoZXkgd2lsbCBub3Qg
YmUKIHJldHVybmVkIHRvZ2V0aGVyLiBJbnN0ZWFkIHRoZSBvbmUgcmFua2VkIGhpZ2hlciB3
aWxsIGJlIHJldHVybmVkLiBUaGlzIGNhbgogYmUgdXNlZCB0byBkZWR1cGxpY2F0ZSBzZW1h
bnRpY2FsbHkgaWRlbnRpY2FsIHN1Z2dlc3Rpb25zLgoKDAoFBAECBAUSA0sCCAoMCgUEAQIE
ARIDSwkRCgwKBQQBAgQDEgNLFBUKPQoEBAECBRIDTgIZGjAgVGhlIHNjb3JlIG9mIHRoaXMg
c3VnZ2VzdGlvbiB3aXRoaW4gaXRzIGdyb3VwLgoKDAoFBAECBQUSA04CCAoMCgUEAQIFARID
TgkUCgwKBQQBAgUDEgNOFxgKQAoEBAECBhIDUQIqGjMgQWx0ZXJuYXRpdmUgbWF0Y2hpbmcg
cGhyYXNlcyBmb3IgdGhpcyBzdWdnZXN0aW9uLgoKDAoFBAECBgQSA1ECCgoMCgUEAQIGBRID
UQsRCgwKBQQBAgYBEgNREiUKDAoFBAECBgMSA1EoKWIGcHJvdG8z
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Discoveryengine::V1::Completion::SuggestionDenyListEntry ===
    # Fields for SuggestionDenyListEntry
    # Field: block_phrase Type: 9 ()
    # Field: match_operator Type: 14 (.google.cloud.discoveryengine.v1.SuggestionDenyListEntry.MatchOperator)

# Enum: SuggestionDenyListEntry::MatchOperator
our $SuggestionDenyListEntry_MATCH_OPERATOR_UNSPECIFIED = 0;
our $SuggestionDenyListEntry_EXACT_MATCH = 1;
our $SuggestionDenyListEntry_CONTAINS = 2;

# === Message: Google::Cloud::Discoveryengine::V1::Completion::CompletionSuggestion ===
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

Google::Cloud::Discoveryengine::V1::Completion - Compiled Protocol Buffers messages for google/cloud/discoveryengine/v1/completion.proto

=head1 SYNOPSIS

    use Google::Cloud::Discoveryengine::V1::Completion;

    my $msg = Google::Cloud::Discoveryengine::V1::Completion::SuggestionDenyListEntry->new({
        block_phrase => $block_phrase,
        match_operator => $match_operator,
    });

    # Read or update a field
    my $val = $msg->block_phrase();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Discoveryengine::V1::Completion::SuggestionDenyListEntry->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/discoveryengine/v1/completion.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Discoveryengine::V1::Completion::SuggestionDenyListEntry

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

Type: C<Enum> (L<Google::Cloud::Discoveryengine::V1::SuggestionDenyListEntry::MatchOperator>)

Required. The match operator to apply for this phrase. Whether to block the
exact phrase, or block any suggestions containing this phrase.

=back

=head3 Enum: SuggestionDenyListEntry::MatchOperator

=over 4

=item * C<MATCH_OPERATOR_UNSPECIFIED> => C<0>

=item * C<EXACT_MATCH> => C<1>

=item * C<CONTAINS> => C<2>

=back

=head2 Google::Cloud::Discoveryengine::V1::Completion::CompletionSuggestion

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

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Discoveryengine::V1::Completion::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
