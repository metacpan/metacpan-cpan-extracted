package Google::Cloud::Discoveryengine::V1beta::Completion;

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
CjRnb29nbGUvY2xvdWQvZGlzY292ZXJ5ZW5naW5lL3YxYmV0YS9jb21wbGV0aW9uLnByb3Rv
EiNnb29nbGUuY2xvdWQuZGlzY292ZXJ5ZW5naW5lLnYxYmV0YRofZ29vZ2xlL2FwaS9maWVs
ZF9iZWhhdmlvci5wcm90byKJAgoXU3VnZ2VzdGlvbkRlbnlMaXN0RW50cnkSJgoMYmxvY2tf
cGhyYXNlGAEgASgJQgPgQQJSC2Jsb2NrUGhyYXNlEnYKDm1hdGNoX29wZXJhdG9yGAIgASgO
MkouZ29vZ2xlLmNsb3VkLmRpc2NvdmVyeWVuZ2luZS52MWJldGEuU3VnZ2VzdGlvbkRlbnlM
aXN0RW50cnkuTWF0Y2hPcGVyYXRvckID4EECUg1tYXRjaE9wZXJhdG9yIk4KDU1hdGNoT3Bl
cmF0b3ISHgoaTUFUQ0hfT1BFUkFUT1JfVU5TUEVDSUZJRUQQABIPCgtFWEFDVF9NQVRDSBAB
EgwKCENPTlRBSU5TEAIiogIKFENvbXBsZXRpb25TdWdnZXN0aW9uEiMKDGdsb2JhbF9zY29y
ZRgCIAEoAUgAUgtnbG9iYWxTY29yZRIeCglmcmVxdWVuY3kYAyABKANIAFIJZnJlcXVlbmN5
EiMKCnN1Z2dlc3Rpb24YASABKAlCA+BBAlIKc3VnZ2VzdGlvbhIjCg1sYW5ndWFnZV9jb2Rl
GAQgASgJUgxsYW5ndWFnZUNvZGUSGQoIZ3JvdXBfaWQYBSABKAlSB2dyb3VwSWQSHwoLZ3Jv
dXBfc2NvcmUYBiABKAFSCmdyb3VwU2NvcmUSLwoTYWx0ZXJuYXRpdmVfcGhyYXNlcxgHIAMo
CVISYWx0ZXJuYXRpdmVQaHJhc2VzQg4KDHJhbmtpbmdfaW5mb0KWAgonY29tLmdvb2dsZS5j
bG91ZC5kaXNjb3ZlcnllbmdpbmUudjFiZXRhQg9Db21wbGV0aW9uUHJvdG9QAVpRY2xvdWQu
Z29vZ2xlLmNvbS9nby9kaXNjb3ZlcnllbmdpbmUvYXBpdjFiZXRhL2Rpc2NvdmVyeWVuZ2lu
ZXBiO2Rpc2NvdmVyeWVuZ2luZXBiogIPRElTQ09WRVJZRU5HSU5FqgIjR29vZ2xlLkNsb3Vk
LkRpc2NvdmVyeUVuZ2luZS5WMUJldGHKAiNHb29nbGVcQ2xvdWRcRGlzY292ZXJ5RW5naW5l
XFYxYmV0YeoCJkdvb2dsZTo6Q2xvdWQ6OkRpc2NvdmVyeUVuZ2luZTo6VjFiZXRhSroWCgYS
BA4AUgEKvAQKAQwSAw4AEjKxBCBDb3B5cmlnaHQgMjAyNiBHb29nbGUgTExDCgogTGljZW5z
ZWQgdW5kZXIgdGhlIEFwYWNoZSBMaWNlbnNlLCBWZXJzaW9uIDIuMCAodGhlICJMaWNlbnNl
Iik7CiB5b3UgbWF5IG5vdCB1c2UgdGhpcyBmaWxlIGV4Y2VwdCBpbiBjb21wbGlhbmNlIHdp
dGggdGhlIExpY2Vuc2UuCiBZb3UgbWF5IG9idGFpbiBhIGNvcHkgb2YgdGhlIExpY2Vuc2Ug
YXQKCiAgICAgaHR0cDovL3d3dy5hcGFjaGUub3JnL2xpY2Vuc2VzL0xJQ0VOU0UtMi4wCgog
VW5sZXNzIHJlcXVpcmVkIGJ5IGFwcGxpY2FibGUgbGF3IG9yIGFncmVlZCB0byBpbiB3cml0
aW5nLCBzb2Z0d2FyZQogZGlzdHJpYnV0ZWQgdW5kZXIgdGhlIExpY2Vuc2UgaXMgZGlzdHJp
YnV0ZWQgb24gYW4gIkFTIElTIiBCQVNJUywKIFdJVEhPVVQgV0FSUkFOVElFUyBPUiBDT05E
SVRJT05TIE9GIEFOWSBLSU5ELCBlaXRoZXIgZXhwcmVzcyBvciBpbXBsaWVkLgogU2VlIHRo
ZSBMaWNlbnNlIGZvciB0aGUgc3BlY2lmaWMgbGFuZ3VhZ2UgZ292ZXJuaW5nIHBlcm1pc3Np
b25zIGFuZAogbGltaXRhdGlvbnMgdW5kZXIgdGhlIExpY2Vuc2UuCgoICgECEgMQACwKCQoC
AwASAxIAKQoICgEIEgMUAEAKCQoCCCUSAxQAQAoICgEIEgMVAGgKCQoCCAsSAxUAaAoICgEI
EgMWACIKCQoCCAoSAxYAIgoICgEIEgMXADAKCQoCCAgSAxcAMAoICgEIEgMYAEAKCQoCCAES
AxgAQAoICgEIEgMZAC0KCQoCCCQSAxkALQoICgEIEgMaAEAKCQoCCCkSAxoAQAoICgEIEgMb
AD8KCQoCCC0SAxsAPwqEAQoCBAASBB8AMwEaeCBTdWdnZXN0aW9uIGRlbnkgbGlzdCBlbnRy
eSBpZGVudGlmeWluZyB0aGUgcGhyYXNlIHRvIGJsb2NrIGZyb20gc3VnZ2VzdGlvbnMKIGFu
ZCB0aGUgYXBwbGllZCBvcGVyYXRpb24gZm9yIHRoZSBwaHJhc2UuCgoKCgMEAAESAx8IHwpF
CgQEAAQAEgQhAioDGjcgT3BlcmF0b3IgZm9yIG1hdGNoaW5nIHdpdGggdGhlIGdlbmVyYXRl
ZCBzdWdnZXN0aW9ucy4KCgwKBQQABAABEgMhBxQKMgoGBAAEAAIAEgMjBCMaIyBEZWZhdWx0
IHZhbHVlLiBTaG91bGQgbm90IGJlIHVzZWQKCg4KBwQABAACAAESAyMEHgoOCgcEAAQAAgAC
EgMjISIKWAoGBAAEAAIBEgMmBBQaSSBJZiB0aGUgc3VnZ2VzdGlvbiBpcyBhbiBleGFjdCBt
YXRjaCB0byB0aGUgYmxvY2tfcGhyYXNlLCB0aGVuIGJsb2NrIGl0LgoKDgoHBAAEAAIBARID
JgQPCg4KBwQABAACAQISAyYSEwpMCgYEAAQAAgISAykEERo9IElmIHRoZSBzdWdnZXN0aW9u
IGNvbnRhaW5zIHRoZSBibG9ja19waHJhc2UsIHRoZW4gYmxvY2sgaXQuCgoOCgcEAAQAAgIB
EgMpBAwKDgoHBAAEAAICAhIDKQ8QCmEKBAQAAgASAy4CQxpUIFJlcXVpcmVkLiBQaHJhc2Ug
dG8gYmxvY2sgZnJvbSBzdWdnZXN0aW9ucyBzZXJ2ZWQuIENhbiBiZSBtYXhpbXVtIDEyNQog
Y2hhcmFjdGVycy4KCgwKBQQAAgAFEgMuAggKDAoFBAACAAESAy4JFQoMCgUEAAIAAxIDLhgZ
CgwKBQQAAgAIEgMuGkIKDwoIBAACAAicCAASAy4bQQqbAQoEBAACARIDMgJMGo0BIFJlcXVp
cmVkLiBUaGUgbWF0Y2ggb3BlcmF0b3IgdG8gYXBwbHkgZm9yIHRoaXMgcGhyYXNlLiBXaGV0
aGVyIHRvIGJsb2NrIHRoZQogZXhhY3QgcGhyYXNlLCBvciBibG9jayBhbnkgc3VnZ2VzdGlv
bnMgY29udGFpbmluZyB0aGlzIHBocmFzZS4KCgwKBQQAAgEGEgMyAg8KDAoFBAACAQESAzIQ
HgoMCgUEAAIBAxIDMiEiCgwKBQQAAgEIEgMyI0sKDwoIBAACAQicCAASAzIkSgpHCgIEARIE
NgBSARo7IEF1dG9jb21wbGV0ZSBzdWdnZXN0aW9ucyB0aGF0IGFyZSBpbXBvcnRlZCBmcm9t
IEN1c3RvbWVyLgoKCgoDBAEBEgM2CBwKMwoEBAEIABIEOAJAAxolIFJhbmtpbmcgbWV0cmlj
cyBvZiB0aGlzIHN1Z2dlc3Rpb24uCgoMCgUEAQgAARIDOAgUCmYKBAQBAgASAzsEHBpZIEds
b2JhbCBzY29yZSBvZiB0aGlzIHN1Z2dlc3Rpb24uIENvbnRyb2wgaG93IHRoaXMgc3VnZ2Vz
dGlvbiB3b3VsZCBiZQogc2NvcmVkIC8gcmFua2VkLgoKDAoFBAECAAUSAzsECgoMCgUEAQIA
ARIDOwsXCgwKBQQBAgADEgM7GhsKawoEBAECARIDPwQYGl4gRnJlcXVlbmN5IG9mIHRoaXMg
c3VnZ2VzdGlvbi4gV2lsbCBiZSB1c2VkIHRvIHJhbmsgc3VnZ2VzdGlvbnMgd2hlbiBzY29y
ZQogaXMgbm90IGF2YWlsYWJsZS4KCgwKBQQBAgEFEgM/BAkKDAoFBAECAQESAz8KEwoMCgUE
AQIBAxIDPxYXCi0KBAQBAgISA0MCQRogIFJlcXVpcmVkLiBUaGUgc3VnZ2VzdGlvbiB0ZXh0
LgoKDAoFBAECAgUSA0MCCAoMCgUEAQICARIDQwkTCgwKBQQBAgIDEgNDFhcKDAoFBAECAggS
A0MYQAoPCggEAQICCJwIABIDQxk/CjcKBAQBAgMSA0YCGxoqIEJDUC00NyBsYW5ndWFnZSBj
b2RlIG9mIHRoaXMgc3VnZ2VzdGlvbi4KCgwKBQQBAgMFEgNGAggKDAoFBAECAwESA0YJFgoM
CgUEAQIDAxIDRhkaCtMBCgQEAQIEEgNLAhYaxQEgSWYgdHdvIHN1Z2dlc3Rpb25zIGhhdmUg
dGhlIHNhbWUgZ3JvdXBJZCwgdGhleSB3aWxsIG5vdCBiZQogcmV0dXJuZWQgdG9nZXRoZXIu
IEluc3RlYWQgdGhlIG9uZSByYW5rZWQgaGlnaGVyIHdpbGwgYmUgcmV0dXJuZWQuIFRoaXMg
Y2FuCiBiZSB1c2VkIHRvIGRlZHVwbGljYXRlIHNlbWFudGljYWxseSBpZGVudGljYWwgc3Vn
Z2VzdGlvbnMuCgoMCgUEAQIEBRIDSwIICgwKBQQBAgQBEgNLCREKDAoFBAECBAMSA0sUFQo9
CgQEAQIFEgNOAhkaMCBUaGUgc2NvcmUgb2YgdGhpcyBzdWdnZXN0aW9uIHdpdGhpbiBpdHMg
Z3JvdXAuCgoMCgUEAQIFBRIDTgIICgwKBQQBAgUBEgNOCRQKDAoFBAECBQMSA04XGApACgQE
AQIGEgNRAioaMyBBbHRlcm5hdGl2ZSBtYXRjaGluZyBwaHJhc2VzIGZvciB0aGlzIHN1Z2dl
c3Rpb24uCgoMCgUEAQIGBBIDUQIKCgwKBQQBAgYFEgNRCxEKDAoFBAECBgESA1ESJQoMCgUE
AQIGAxIDUSgpYgZwcm90bzM=
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Discoveryengine::V1beta::Completion::SuggestionDenyListEntry ===
    # Fields for SuggestionDenyListEntry
    # Field: block_phrase Type: 9 ()
    # Field: match_operator Type: 14 (.google.cloud.discoveryengine.v1beta.SuggestionDenyListEntry.MatchOperator)

# Enum: SuggestionDenyListEntry::MatchOperator
our $SuggestionDenyListEntry_MATCH_OPERATOR_UNSPECIFIED = 0;
our $SuggestionDenyListEntry_EXACT_MATCH = 1;
our $SuggestionDenyListEntry_CONTAINS = 2;

# === Message: Google::Cloud::Discoveryengine::V1beta::Completion::CompletionSuggestion ===
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

Google::Cloud::Discoveryengine::V1beta::Completion - Compiled Protocol Buffers messages for google/cloud/discoveryengine/v1beta/completion.proto

=head1 SYNOPSIS

    use Google::Cloud::Discoveryengine::V1beta::Completion;

    my $msg = Google::Cloud::Discoveryengine::V1beta::Completion::SuggestionDenyListEntry->new({
        block_phrase => $block_phrase,
        match_operator => $match_operator,
    });

    # Read or update a field
    my $val = $msg->block_phrase();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Discoveryengine::V1beta::Completion::SuggestionDenyListEntry->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/discoveryengine/v1beta/completion.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Discoveryengine::V1beta::Completion::SuggestionDenyListEntry

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

Type: C<Enum> (L<Google::Cloud::Discoveryengine::V1beta::SuggestionDenyListEntry::MatchOperator>)

Required. The match operator to apply for this phrase. Whether to block the
exact phrase, or block any suggestions containing this phrase.

=back

=head3 Enum: SuggestionDenyListEntry::MatchOperator

=over 4

=item * C<MATCH_OPERATOR_UNSPECIFIED> => C<0>

=item * C<EXACT_MATCH> => C<1>

=item * C<CONTAINS> => C<2>

=back

=head2 Google::Cloud::Discoveryengine::V1beta::Completion::CompletionSuggestion

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

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Discoveryengine::V1beta::Completion::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
