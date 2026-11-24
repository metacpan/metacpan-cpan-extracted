package Google::Actions::Sdk::V2::Interactionmodel::Type::Type;

use strict;
use warnings;

our $VERSION = '0.14';

use Protobuf::Message;
use Protobuf::DescriptorPool;
use Protobuf::Internal qw(:all);
use MIME::Base64;

BEGIN {
    eval { require Google::Actions::Sdk::V2::Interactionmodel::Type::FreeTextType };
    eval { require Google::Actions::Sdk::V2::Interactionmodel::Type::RegularExpressionType };
    eval { require Google::Actions::Sdk::V2::Interactionmodel::Type::SynonymType };
    my $descriptor_b64 = <<'EOF';
CjZnb29nbGUvYWN0aW9ucy9zZGsvdjIvaW50ZXJhY3Rpb25tb2RlbC90eXBlL3R5cGUucHJv
dG8SK2dvb2dsZS5hY3Rpb25zLnNkay52Mi5pbnRlcmFjdGlvbm1vZGVsLnR5cGUaQGdvb2ds
ZS9hY3Rpb25zL3Nkay92Mi9pbnRlcmFjdGlvbm1vZGVsL3R5cGUvZnJlZV90ZXh0X3R5cGUu
cHJvdG8aSWdvb2dsZS9hY3Rpb25zL3Nkay92Mi9pbnRlcmFjdGlvbm1vZGVsL3R5cGUvcmVn
dWxhcl9leHByZXNzaW9uX3R5cGUucHJvdG8aPmdvb2dsZS9hY3Rpb25zL3Nkay92Mi9pbnRl
cmFjdGlvbm1vZGVsL3R5cGUvc3lub255bV90eXBlLnByb3RvItcCCgRUeXBlElQKB3N5bm9u
eW0YASABKAsyOC5nb29nbGUuYWN0aW9ucy5zZGsudjIuaW50ZXJhY3Rpb25tb2RlbC50eXBl
LlN5bm9ueW1UeXBlSABSB3N5bm9ueW0ScwoScmVndWxhcl9leHByZXNzaW9uGAIgASgLMkIu
Z29vZ2xlLmFjdGlvbnMuc2RrLnYyLmludGVyYWN0aW9ubW9kZWwudHlwZS5SZWd1bGFyRXhw
cmVzc2lvblR5cGVIAFIRcmVndWxhckV4cHJlc3Npb24SWAoJZnJlZV90ZXh0GAMgASgLMjku
Z29vZ2xlLmFjdGlvbnMuc2RrLnYyLmludGVyYWN0aW9ubW9kZWwudHlwZS5GcmVlVGV4dFR5
cGVIAFIIZnJlZVRleHQSHgoKZXhjbHVzaW9ucxgEIAMoCVIKZXhjbHVzaW9uc0IKCghzdWJf
dHlwZUKKAQovY29tLmdvb2dsZS5hY3Rpb25zLnNkay52Mi5pbnRlcmFjdGlvbm1vZGVsLnR5
cGVCCVR5cGVQcm90b1ABWkpnb29nbGUuZ29sYW5nLm9yZy9nZW5wcm90by9nb29nbGVhcGlz
L2FjdGlvbnMvc2RrL3YyL2ludGVyYWN0aW9ubW9kZWwvdHlwZUqFDQoGEgQOADEBCrwECgEM
EgMOABIysQQgQ29weXJpZ2h0IDIwMjUgR29vZ2xlIExMQwoKIExpY2Vuc2VkIHVuZGVyIHRo
ZSBBcGFjaGUgTGljZW5zZSwgVmVyc2lvbiAyLjAgKHRoZSAiTGljZW5zZSIpOwogeW91IG1h
eSBub3QgdXNlIHRoaXMgZmlsZSBleGNlcHQgaW4gY29tcGxpYW5jZSB3aXRoIHRoZSBMaWNl
bnNlLgogWW91IG1heSBvYnRhaW4gYSBjb3B5IG9mIHRoZSBMaWNlbnNlIGF0CgogICAgIGh0
dHA6Ly93d3cuYXBhY2hlLm9yZy9saWNlbnNlcy9MSUNFTlNFLTIuMAoKIFVubGVzcyByZXF1
aXJlZCBieSBhcHBsaWNhYmxlIGxhdyBvciBhZ3JlZWQgdG8gaW4gd3JpdGluZywgc29mdHdh
cmUKIGRpc3RyaWJ1dGVkIHVuZGVyIHRoZSBMaWNlbnNlIGlzIGRpc3RyaWJ1dGVkIG9uIGFu
ICJBUyBJUyIgQkFTSVMsCiBXSVRIT1VUIFdBUlJBTlRJRVMgT1IgQ09ORElUSU9OUyBPRiBB
TlkgS0lORCwgZWl0aGVyIGV4cHJlc3Mgb3IgaW1wbGllZC4KIFNlZSB0aGUgTGljZW5zZSBm
b3IgdGhlIHNwZWNpZmljIGxhbmd1YWdlIGdvdmVybmluZyBwZXJtaXNzaW9ucyBhbmQKIGxp
bWl0YXRpb25zIHVuZGVyIHRoZSBMaWNlbnNlLgoKCAoBAhIDEAA0CgkKAgMAEgMSAEoKCQoC
AwESAxMAUwoJCgIDAhIDFABICggKAQgSAxYAYQoJCgIICxIDFgBhCggKAQgSAxcAIgoJCgII
ChIDFwAiCggKAQgSAxgAKgoJCgIICBIDGAAqCggKAQgSAxkASAoJCgIIARIDGQBICosCCgIE
ABIEHwAxARr+ASBEZWNsYXJhdGlvbiBvZiBhIGN1c3RvbSB0eXBlLCBhcyBvcHBvc2VkIHRv
IGJ1aWx0LWluIHR5cGVzLiBUeXBlcyBjYW4gYmUKIGFzc2lnbmVkIHRvIHNsb3RzIGluIGEg
c2NlbmUgb3IgcGFyYW1ldGVycyBvZiBhbiBpbnRlbnQncyB0cmFpbmluZyBwaHJhc2VzLgog
UHJhY3RpY2FsbHksIFR5cGVzIGNhbiBiZSB0aG91Z2h0IG9mIGFzIGVudW1zLgogTm90ZSwg
dHlwZSBuYW1lIGlzIHNwZWNpZmllZCBpbiB0aGUgbmFtZSBvZiB0aGUgZmlsZS4KCgoKAwQA
ARIDHwgMCk8KBAQACAASBCECKgMaQSBTZWxlY3Rpb24gb2Ygc3ViIHR5cGUgYmFzZWQgb24g
dGhlIHR5cGUgb2YgbWF0Y2hpbmcgdG8gYmUgZG9uZS4KCgwKBQQACAABEgMhCBAKOwoEBAAC
ABIDIwQcGi4gU3lub255bXMgdHlwZSwgd2hpY2ggaXMgZXNzZW50aWFsbHkgYW4gZW51bS4K
CgwKBQQAAgAGEgMjBA8KDAoFBAACAAESAyMQFwoMCgUEAAIAAxIDIxobCj4KBAQAAgESAyYE
MRoxIFJlZ2V4IHR5cGUsIGFsbG93cyByZWd1bGFyIGV4cHJlc3Npb24gbWF0Y2hpbmcuCgoM
CgUEAAIBBhIDJgQZCgwKBQQAAgEBEgMmGiwKDAoFBAACAQMSAyYvMAodCgQEAAICEgMpBB8a
ECBGcmVlVGV4dCB0eXBlLgoKDAoFBAACAgYSAykEEAoMCgUEAAICARIDKREaCgwKBQQAAgID
EgMpHR4K8QEKBAQAAgMSAzACIRrjASBTZXQgb2YgZXhjZXB0aW9uYWwgd29yZHMvcGhyYXNl
cyB0aGF0IHNob3VsZG4ndCBiZSBtYXRjaGVkIGJ5IHR5cGUuCiBOb3RlOiBJZiB3b3JkL3Bo
cmFzZSBpcyBtYXRjaGVkIGJ5IHRoZSB0eXBlIGJ1dCBsaXN0ZWQgYXMgYW4gZXhjbHVzaW9u
IGl0CiB3b24ndCBiZSByZXR1cm5lZCBpbiBwYXJhbWV0ZXIgZXh0cmFjdGlvbiByZXN1bHQu
CiAqKlRoaXMgZmllbGQgaXMgbG9jYWxpemFibGUuKioKCgwKBQQAAgMEEgMwAgoKDAoFBAAC
AwUSAzALEQoMCgUEAAIDARIDMBIcCgwKBQQAAgMDEgMwHyBiBnByb3RvMw==
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Actions::Sdk::V2::Interactionmodel::Type::Type::Type ===
    # Fields for Type
    # Field: synonym Type: 11 (.google.actions.sdk.v2.interactionmodel.type.SynonymType)
    # Field: regular_expression Type: 11 (.google.actions.sdk.v2.interactionmodel.type.RegularExpressionType)
    # Field: free_text Type: 11 (.google.actions.sdk.v2.interactionmodel.type.FreeTextType)
    # Field: exclusions Type: 9 ()

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Actions::Sdk::V2::Interactionmodel::Type::Type - Compiled Protocol Buffers messages for google/actions/sdk/v2/interactionmodel/type/type.proto

=head1 SYNOPSIS

    use Google::Actions::Sdk::V2::Interactionmodel::Type::Type;

    my $msg = Google::Actions::Sdk::V2::Interactionmodel::Type::Type::Type->new({
        synonym => $synonym,
        regular_expression => $regular_expression,
        free_text => $free_text,
        exclusions => $exclusions,
    });

    # Read or update a field
    my $val = $msg->synonym();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Actions::Sdk::V2::Interactionmodel::Type::Type::Type->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/actions/sdk/v2/interactionmodel/type/type.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Actions::Sdk::V2::Interactionmodel::Type::Type::Type

Declaration of a custom type, as opposed to built-in types. Types can be
assigned to slots in a scene or parameters of an intent's training phrases.
Practically, Types can be thought of as enums.
Note, type name is specified in the name of the file.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->synonym() >> / C<< $msg->synonym($value) >>

Type: C<Message> (L<Google::Actions::Sdk::V2::Interactionmodel::Type::SynonymType::SynonymType>)

Synonyms type, which is essentially an enum.

=item * C<< $msg->regular_expression() >> / C<< $msg->regular_expression($value) >>

Type: C<Message> (L<Google::Actions::Sdk::V2::Interactionmodel::Type::RegularExpressionType::RegularExpressionType>)

Regex type, allows regular expression matching.

=item * C<< $msg->free_text() >> / C<< $msg->free_text($value) >>

Type: C<Message> (L<Google::Actions::Sdk::V2::Interactionmodel::Type::FreeTextType::FreeTextType>)

FreeText type.

=item * C<< $msg->exclusions() >> / C<< $msg->exclusions($value) >>

Type: C<String>

Set of exceptional words/phrases that shouldn't be matched by type.
Note: If word/phrase is matched by the type but listed as an exclusion it
won't be returned in parameter extraction result.
B<This field is localizable.>

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Actions::Sdk::V2::Interactionmodel::Type::Type::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
