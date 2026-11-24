package Google::Actions::Sdk::V2::Interactionmodel::Prompt::Suggestion;

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
Cj5nb29nbGUvYWN0aW9ucy9zZGsvdjIvaW50ZXJhY3Rpb25tb2RlbC9wcm9tcHQvc3VnZ2Vz
dGlvbi5wcm90bxItZ29vZ2xlLmFjdGlvbnMuc2RrLnYyLmludGVyYWN0aW9ubW9kZWwucHJv
bXB0Gh9nb29nbGUvYXBpL2ZpZWxkX2JlaGF2aW9yLnByb3RvIicKClN1Z2dlc3Rpb24SGQoF
dGl0bGUYASABKAlCA+BBAlIFdGl0bGVCmwEKMWNvbS5nb29nbGUuYWN0aW9ucy5zZGsudjIu
aW50ZXJhY3Rpb25tb2RlbC5wcm9tcHRCD1N1Z2dlc3Rpb25Qcm90b1ABWlNnb29nbGUuZ29s
YW5nLm9yZy9nZW5wcm90by9nb29nbGVhcGlzL2FjdGlvbnMvc2RrL3YyL2ludGVyYWN0aW9u
bW9kZWwvcHJvbXB0O3Byb21wdErXCAoGEgQOACABCrwECgEMEgMOABIysQQgQ29weXJpZ2h0
IDIwMjUgR29vZ2xlIExMQwoKIExpY2Vuc2VkIHVuZGVyIHRoZSBBcGFjaGUgTGljZW5zZSwg
VmVyc2lvbiAyLjAgKHRoZSAiTGljZW5zZSIpOwogeW91IG1heSBub3QgdXNlIHRoaXMgZmls
ZSBleGNlcHQgaW4gY29tcGxpYW5jZSB3aXRoIHRoZSBMaWNlbnNlLgogWW91IG1heSBvYnRh
aW4gYSBjb3B5IG9mIHRoZSBMaWNlbnNlIGF0CgogICAgIGh0dHA6Ly93d3cuYXBhY2hlLm9y
Zy9saWNlbnNlcy9MSUNFTlNFLTIuMAoKIFVubGVzcyByZXF1aXJlZCBieSBhcHBsaWNhYmxl
IGxhdyBvciBhZ3JlZWQgdG8gaW4gd3JpdGluZywgc29mdHdhcmUKIGRpc3RyaWJ1dGVkIHVu
ZGVyIHRoZSBMaWNlbnNlIGlzIGRpc3RyaWJ1dGVkIG9uIGFuICJBUyBJUyIgQkFTSVMsCiBX
SVRIT1VUIFdBUlJBTlRJRVMgT1IgQ09ORElUSU9OUyBPRiBBTlkgS0lORCwgZWl0aGVyIGV4
cHJlc3Mgb3IgaW1wbGllZC4KIFNlZSB0aGUgTGljZW5zZSBmb3IgdGhlIHNwZWNpZmljIGxh
bmd1YWdlIGdvdmVybmluZyBwZXJtaXNzaW9ucyBhbmQKIGxpbWl0YXRpb25zIHVuZGVyIHRo
ZSBMaWNlbnNlLgoKCAoBAhIDEAA2CgkKAgMAEgMSACkKCAoBCBIDFABqCgkKAggLEgMUAGoK
CAoBCBIDFQAiCgkKAggKEgMVACIKCAoBCBIDFgAwCgkKAggIEgMWADAKCAoBCBIDFwBKCgkK
AggBEgMXAEoKWwoCBAASBBoAIAEaTyBSZXByZXNlbnRzIGEgc3VnZ2VzdGlvbiBjaGlwLCBh
IFVJIGVsZW1lbnQgc2hvd24gdG8gdGhlIHVzZXIgZm9yIGNvbnZlbmllbmNlLgoKCgoDBAAB
EgMaCBIK8gEKBAQAAgASAx8CPBrkASBSZXF1aXJlZC4gVGhlIHRleHQgc2hvd24gaW4gdGhl
IHN1Z2dlc3Rpb24gY2hpcC4gV2hlbiB0YXBwZWQsIHRoaXMgdGV4dCB3aWxsIGJlCiBwb3N0
ZWQgYmFjayB0byB0aGUgY29udmVyc2F0aW9uIHZlcmJhdGltIGFzIGlmIHRoZSB1c2VyIGhh
ZCB0eXBlZCBpdC4KIEVhY2ggdGl0bGUgbXVzdCBiZSB1bmlxdWUgYW1vbmcgdGhlIHNldCBv
ZiBzdWdnZXN0aW9uIGNoaXBzLgogTWF4IDI1IGNoYXJzCgoMCgUEAAIABRIDHwIICgwKBQQA
AgABEgMfCQ4KDAoFBAACAAMSAx8REgoMCgUEAAIACBIDHxM7Cg8KCAQAAgAInAgAEgMfFDpi
BnByb3RvMw==
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Actions::Sdk::V2::Interactionmodel::Prompt::Suggestion::Suggestion ===
    # Fields for Suggestion
    # Field: title Type: 9 ()

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Actions::Sdk::V2::Interactionmodel::Prompt::Suggestion - Compiled Protocol Buffers messages for google/actions/sdk/v2/interactionmodel/prompt/suggestion.proto

=head1 SYNOPSIS

    use Google::Actions::Sdk::V2::Interactionmodel::Prompt::Suggestion;

    my $msg = Google::Actions::Sdk::V2::Interactionmodel::Prompt::Suggestion::Suggestion->new({
        title => $title,
    });

    # Read or update a field
    my $val = $msg->title();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Actions::Sdk::V2::Interactionmodel::Prompt::Suggestion::Suggestion->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/actions/sdk/v2/interactionmodel/prompt/suggestion.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Actions::Sdk::V2::Interactionmodel::Prompt::Suggestion::Suggestion

Represents a suggestion chip, a UI element shown to the user for convenience.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->title() >> / C<< $msg->title($value) >>

Type: C<String>

Required. The text shown in the suggestion chip. When tapped, this text will be
posted back to the conversation verbatim as if the user had typed it.
Each title must be unique among the set of suggestion chips.
Max 25 chars

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Actions::Sdk::V2::Interactionmodel::Prompt::Suggestion::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
