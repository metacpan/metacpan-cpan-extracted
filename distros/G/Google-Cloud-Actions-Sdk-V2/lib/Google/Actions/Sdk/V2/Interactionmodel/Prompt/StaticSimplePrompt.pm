package Google::Actions::Sdk::V2::Interactionmodel::Prompt::StaticSimplePrompt;

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
Ckhnb29nbGUvYWN0aW9ucy9zZGsvdjIvaW50ZXJhY3Rpb25tb2RlbC9wcm9tcHQvc3RhdGlj
X3NpbXBsZV9wcm9tcHQucHJvdG8SLWdvb2dsZS5hY3Rpb25zLnNkay52Mi5pbnRlcmFjdGlv
bm1vZGVsLnByb21wdBofZ29vZ2xlL2FwaS9maWVsZF9iZWhhdmlvci5wcm90byK8AQoSU3Rh
dGljU2ltcGxlUHJvbXB0EmUKCHZhcmlhbnRzGAEgAygLMkkuZ29vZ2xlLmFjdGlvbnMuc2Rr
LnYyLmludGVyYWN0aW9ubW9kZWwucHJvbXB0LlN0YXRpY1NpbXBsZVByb21wdC5WYXJpYW50
Ugh2YXJpYW50cxo/CgdWYXJpYW50EhsKBnNwZWVjaBgBIAEoCUID4EEBUgZzcGVlY2gSFwoE
dGV4dBgCIAEoCUID4EEBUgR0ZXh0QqMBCjFjb20uZ29vZ2xlLmFjdGlvbnMuc2RrLnYyLmlu
dGVyYWN0aW9ubW9kZWwucHJvbXB0QhdTdGF0aWNTaW1wbGVQcm9tcHRQcm90b1ABWlNnb29n
bGUuZ29sYW5nLm9yZy9nZW5wcm90by9nb29nbGVhcGlzL2FjdGlvbnMvc2RrL3YyL2ludGVy
YWN0aW9ubW9kZWwvcHJvbXB0O3Byb21wdEqUDgoGEgQOAC8BCrwECgEMEgMOABIysQQgQ29w
eXJpZ2h0IDIwMjUgR29vZ2xlIExMQwoKIExpY2Vuc2VkIHVuZGVyIHRoZSBBcGFjaGUgTGlj
ZW5zZSwgVmVyc2lvbiAyLjAgKHRoZSAiTGljZW5zZSIpOwogeW91IG1heSBub3QgdXNlIHRo
aXMgZmlsZSBleGNlcHQgaW4gY29tcGxpYW5jZSB3aXRoIHRoZSBMaWNlbnNlLgogWW91IG1h
eSBvYnRhaW4gYSBjb3B5IG9mIHRoZSBMaWNlbnNlIGF0CgogICAgIGh0dHA6Ly93d3cuYXBh
Y2hlLm9yZy9saWNlbnNlcy9MSUNFTlNFLTIuMAoKIFVubGVzcyByZXF1aXJlZCBieSBhcHBs
aWNhYmxlIGxhdyBvciBhZ3JlZWQgdG8gaW4gd3JpdGluZywgc29mdHdhcmUKIGRpc3RyaWJ1
dGVkIHVuZGVyIHRoZSBMaWNlbnNlIGlzIGRpc3RyaWJ1dGVkIG9uIGFuICJBUyBJUyIgQkFT
SVMsCiBXSVRIT1VUIFdBUlJBTlRJRVMgT1IgQ09ORElUSU9OUyBPRiBBTlkgS0lORCwgZWl0
aGVyIGV4cHJlc3Mgb3IgaW1wbGllZC4KIFNlZSB0aGUgTGljZW5zZSBmb3IgdGhlIHNwZWNp
ZmljIGxhbmd1YWdlIGdvdmVybmluZyBwZXJtaXNzaW9ucyBhbmQKIGxpbWl0YXRpb25zIHVu
ZGVyIHRoZSBMaWNlbnNlLgoKCAoBAhIDEAA2CgkKAgMAEgMSACkKCAoBCBIDFABqCgkKAggL
EgMUAGoKCAoBCBIDFQAiCgkKAggKEgMVACIKCAoBCBIDFgA4CgkKAggIEgMWADgKCAoBCBID
FwBKCgkKAggBEgMXAEoKPgoCBAASBBoALwEaMiBSZXByZXNlbnRzIGEgc2ltcGxlIHByb21w
dCB0byBiZSBzZW5kIHRvIGEgdXNlci4KCgoKAwQAARIDGggaCkgKBAQAAwASBBwCKwMaOiBS
ZXByZXNlbnRzIGEgdmFyaWFudCB3aGljaCBpcyBwYXJ0IG9mIHRoZSBzaW1wbGUgcHJvbXB0
LgoKDAoFBAADAAESAxwKEQrDAgoGBAADAAIAEgMjBD8aswIgT3B0aW9uYWwuIFJlcHJlc2Vu
dHMgdGhlIHNwZWVjaCB0byBiZSBzcG9rZW4gdG8gdGhlIHVzZXIuICBDYW4gYmUgU1NNTCBv
ciB0ZXh0IHRvCiBzcGVlY2guCiBCeSBkZWZhdWx0LCBzcGVlY2ggd2lsbCBiZSBhcHBlbmRl
ZCB0byBwcmV2aW91cyBTaW1wbGUgcHJvbXB0J3MKIHNwZWVjaC4gSWYgdGhlIGBvdmVycmlk
ZWAgZmllbGQgaW4gdGhlIGNvbnRhaW5pbmcgcHJvbXB0IGlzIGB0cnVlYCB0aGUKIHNwZWVj
aCBkZWZpbmVkIGluIHRoaXMgZmllbGQgd2lsbCBvdmVycmlkZSBwcmV2aW91cyBTaW1wbGUg
cHJvbXB0J3MKIHNwZWVjaC4KCg4KBwQAAwACAAUSAyMECgoOCgcEAAMAAgABEgMjCxEKDgoH
BAADAAIAAxIDIxQVCg4KBwQAAwACAAgSAyMWPgoRCgoEAAMAAgAInAgAEgMjFz0K7gIKBgQA
AwACARIDKgQ9Gt4CIE9wdGlvbmFsLiBUZXh0IHRvIGRpc3BsYXkgaW4gdGhlIGNoYXQgYnVi
YmxlLiBJZiBub3QgZ2l2ZW4sIGEgZGlzcGxheSByZW5kZXJpbmcgb2YKIHRoZSBzcGVlY2gg
ZmllbGQgYWJvdmUgd2lsbCBiZSB1c2VkLiBMaW1pdGVkIHRvIDY0MCBjaGFycy4KIEJ5IGRl
ZmF1bHQsIHRleHQgd2lsbCBiZSBhcHBlbmRlZCB0byBwcmV2aW91cyBTaW1wbGUgcHJvbXB0
J3MgdGV4dC4KIElmIHRoZSBgb3ZlcnJpZGVgIGZpZWxkIGluIHRoZSBjb250YWluaW5nIHBy
b21wdCBpcyBgdHJ1ZWAgdGhlIHRleHQKIGRlZmluZWQgaW4gdGhpcyBmaWVsZCB3aWxsIG92
ZXJyaWRlIHByZXZpb3VzIFNpbXBsZSBwcm9tcHQncyB0ZXh0LgoKDgoHBAADAAIBBRIDKgQK
Cg4KBwQAAwACAQESAyoLDwoOCgcEAAMAAgEDEgMqEhMKDgoHBAADAAIBCBIDKhQ8ChEKCgQA
AwACAQicCAASAyoVOwopCgQEAAIAEgMuAiAaHCBMaXN0IG9mIHBvc3NpYmxlIHZhcmlhbnRz
LgoKDAoFBAACAAQSAy4CCgoMCgUEAAIABhIDLgsSCgwKBQQAAgABEgMuExsKDAoFBAACAAMS
Ay4eH2IGcHJvdG8z
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Actions::Sdk::V2::Interactionmodel::Prompt::StaticSimplePrompt::StaticSimplePrompt ===
    # Fields for StaticSimplePrompt
    # Field: variants Type: 11 (.google.actions.sdk.v2.interactionmodel.prompt.StaticSimplePrompt.Variant)

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Actions::Sdk::V2::Interactionmodel::Prompt::StaticSimplePrompt - Compiled Protocol Buffers messages for google/actions/sdk/v2/interactionmodel/prompt/static_simple_prompt.proto

=head1 SYNOPSIS

    use Google::Actions::Sdk::V2::Interactionmodel::Prompt::StaticSimplePrompt;

    my $msg = Google::Actions::Sdk::V2::Interactionmodel::Prompt::StaticSimplePrompt::StaticSimplePrompt->new({
        variants => $variants,
    });

    # Read or update a field
    my $val = $msg->variants();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Actions::Sdk::V2::Interactionmodel::Prompt::StaticSimplePrompt::StaticSimplePrompt->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/actions/sdk/v2/interactionmodel/prompt/static_simple_prompt.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Actions::Sdk::V2::Interactionmodel::Prompt::StaticSimplePrompt::StaticSimplePrompt

Represents a simple prompt to be send to a user.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->variants() >> / C<< $msg->variants($value) >>

Type: C<Message> (L<Google::Actions::Sdk::V2::Interactionmodel::Prompt::StaticSimplePrompt::StaticSimplePrompt::Variant>)

List of possible variants.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Actions::Sdk::V2::Interactionmodel::Prompt::StaticSimplePrompt::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
