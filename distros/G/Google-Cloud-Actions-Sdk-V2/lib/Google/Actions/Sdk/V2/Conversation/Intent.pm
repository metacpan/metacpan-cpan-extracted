package Google::Actions::Sdk::V2::Conversation::Intent;

use strict;
use warnings;

our $VERSION = '0.14';

use Protobuf::Message;
use Protobuf::DescriptorPool;
use Protobuf::Internal qw(:all);
use MIME::Base64;

BEGIN {
    eval { require Google::Protobuf::Struct };
    my $descriptor_b64 = <<'EOF';
Ci9nb29nbGUvYWN0aW9ucy9zZGsvdjIvY29udmVyc2F0aW9uL2ludGVudC5wcm90bxIiZ29v
Z2xlLmFjdGlvbnMuc2RrLnYyLmNvbnZlcnNhdGlvbhocZ29vZ2xlL3Byb3RvYnVmL3N0cnVj
dC5wcm90byL3AQoGSW50ZW50EhIKBG5hbWUYASABKAlSBG5hbWUSTgoGcGFyYW1zGAIgAygL
MjYuZ29vZ2xlLmFjdGlvbnMuc2RrLnYyLmNvbnZlcnNhdGlvbi5JbnRlbnQuUGFyYW1zRW50
cnlSBnBhcmFtcxIUCgVxdWVyeRgDIAEoCVIFcXVlcnkacwoLUGFyYW1zRW50cnkSEAoDa2V5
GAEgASgJUgNrZXkSTgoFdmFsdWUYAiABKAsyOC5nb29nbGUuYWN0aW9ucy5zZGsudjIuY29u
dmVyc2F0aW9uLkludGVudFBhcmFtZXRlclZhbHVlUgV2YWx1ZToCOAEiZgoUSW50ZW50UGFy
YW1ldGVyVmFsdWUSGgoIb3JpZ2luYWwYASABKAlSCG9yaWdpbmFsEjIKCHJlc29sdmVkGAIg
ASgLMhYuZ29vZ2xlLnByb3RvYnVmLlZhbHVlUghyZXNvbHZlZEKHAQomY29tLmdvb2dsZS5h
Y3Rpb25zLnNkay52Mi5jb252ZXJzYXRpb25CC0ludGVudFByb3RvUAFaTmdvb2dsZS5nb2xh
bmcub3JnL2dlbnByb3RvL2dvb2dsZWFwaXMvYWN0aW9ucy9zZGsvdjIvY29udmVyc2F0aW9u
O2NvbnZlcnNhdGlvbkrDDgoGEgQOADMBCrwECgEMEgMOABIysQQgQ29weXJpZ2h0IDIwMjUg
R29vZ2xlIExMQwoKIExpY2Vuc2VkIHVuZGVyIHRoZSBBcGFjaGUgTGljZW5zZSwgVmVyc2lv
biAyLjAgKHRoZSAiTGljZW5zZSIpOwogeW91IG1heSBub3QgdXNlIHRoaXMgZmlsZSBleGNl
cHQgaW4gY29tcGxpYW5jZSB3aXRoIHRoZSBMaWNlbnNlLgogWW91IG1heSBvYnRhaW4gYSBj
b3B5IG9mIHRoZSBMaWNlbnNlIGF0CgogICAgIGh0dHA6Ly93d3cuYXBhY2hlLm9yZy9saWNl
bnNlcy9MSUNFTlNFLTIuMAoKIFVubGVzcyByZXF1aXJlZCBieSBhcHBsaWNhYmxlIGxhdyBv
ciBhZ3JlZWQgdG8gaW4gd3JpdGluZywgc29mdHdhcmUKIGRpc3RyaWJ1dGVkIHVuZGVyIHRo
ZSBMaWNlbnNlIGlzIGRpc3RyaWJ1dGVkIG9uIGFuICJBUyBJUyIgQkFTSVMsCiBXSVRIT1VU
IFdBUlJBTlRJRVMgT1IgQ09ORElUSU9OUyBPRiBBTlkgS0lORCwgZWl0aGVyIGV4cHJlc3Mg
b3IgaW1wbGllZC4KIFNlZSB0aGUgTGljZW5zZSBmb3IgdGhlIHNwZWNpZmljIGxhbmd1YWdl
IGdvdmVybmluZyBwZXJtaXNzaW9ucyBhbmQKIGxpbWl0YXRpb25zIHVuZGVyIHRoZSBMaWNl
bnNlLgoKCAoBAhIDEAArCgkKAgMAEgMSACYKCAoBCBIDFABlCgkKAggLEgMUAGUKCAoBCBID
FQAiCgkKAggKEgMVACIKCAoBCBIDFgAsCgkKAggIEgMWACwKCAoBCBIDFwA/CgkKAggBEgMX
AD8KIwoCBAASBBoAJwEaFyBSZXByZXNlbnRzIGFuIGludGVudC4KCgoKAwQAARIDGggOCj0K
BAQAAgASAxwCEhowIFJlcXVpcmVkLiBUaGUgbmFtZSBvZiB0aGUgbGFzdCBtYXRjaGVkIGlu
dGVudC4KCgwKBQQAAgAFEgMcAggKDAoFBAACAAESAxwJDQoMCgUEAAIAAxIDHBARCqECCgQE
AAIBEgMiAi8akwIgUmVxdWlyZWQuIFJlcHJlc2VudHMgcGFyYW1ldGVycyBpZGVudGlmaWVk
IGFzIHBhcnQgb2YgaW50ZW50IG1hdGNoaW5nLgogVGhpcyBpcyBhIG1hcCBvZiB0aGUgbmFt
ZSBvZiB0aGUgaWRlbnRpZmllZCBwYXJhbWV0ZXIgdG8gdGhlIHZhbHVlIG9mIHRoZQogcGFy
YW1ldGVyIGlkZW50aWZpZWQgZnJvbSB1c2VyIGlucHV0LiBBbGwgcGFyYW1ldGVycyBkZWZp
bmVkIGluCiB0aGUgbWF0Y2hlZCBpbnRlbnQgdGhhdCBhcmUgaWRlbnRpZmllZCB3aWxsIGJl
IHN1cmZhY2VkIGhlcmUuCgoMCgUEAAIBBhIDIgIjCgwKBQQAAgEBEgMiJCoKDAoFBAACAQMS
AyItLgqnAQoEBAACAhIDJgITGpkBIE9wdGlvbmFsLiBUeXBlZCBvciBzcG9rZW4gaW5wdXQg
ZnJvbSB0aGUgZW5kIHVzZXIgdGhhdCBtYXRjaGVkIHRoaXMgaW50ZW50LgogVGhpcyB3aWxs
IGJlIHBvcHVsYXRlZCB3aGVuIGFuIGludGVudCBpcyBtYXRjaGVkLCBiYXNlZCBvbiB0aGUg
dXNlciBpbnB1dC4KCgwKBQQAAgIFEgMmAggKDAoFBAACAgESAyYJDgoMCgUEAAICAxIDJhES
CjYKAgQBEgQqADMBGiogUmVwcmVzZW50cyBhIHZhbHVlIGZvciBpbnRlbnQgcGFyYW1ldGVy
LgoKCgoDBAEBEgMqCBwKSwoEBAECABIDLAIWGj4gUmVxdWlyZWQuIE9yaWdpbmFsIHRleHQg
dmFsdWUgZXh0cmFjdGVkIGZyb20gdXNlciB1dHRlcmFuY2UuCgoMCgUEAQIABRIDLAIICgwK
BQQBAgABEgMsCREKDAoFBAECAAMSAywUFQrvAQoEBAECARIDMgIlGuEBIFJlcXVpcmVkLiBT
dHJ1Y3R1cmVkIHZhbHVlIGZvciBwYXJhbWV0ZXIgZXh0cmFjdGVkIGZyb20gdXNlciBpbnB1
dC4KIFRoaXMgd2lsbCBvbmx5IGJlIHBvcHVsYXRlZCBpZiB0aGUgcGFyYW1ldGVyIGlzIGRl
ZmluZWQgaW4gdGhlIG1hdGNoZWQKIGludGVudCBhbmQgdGhlIHZhbHVlIG9mIHRoZSBwYXJh
bWV0ZXIgY291bGQgYmUgaWRlbnRpZmllZCBkdXJpbmcgaW50ZW50CiBtYXRjaGluZy4KCgwK
BQQBAgEGEgMyAhcKDAoFBAECAQESAzIYIAoMCgUEAQIBAxIDMiMkYgZwcm90bzM=
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Actions::Sdk::V2::Conversation::Intent::Intent ===
    # Fields for Intent
    # Field: name Type: 9 ()
    # Field: params Type: 11 (.google.actions.sdk.v2.conversation.Intent.ParamsEntry)
    # Field: query Type: 9 ()

# === Message: Google::Actions::Sdk::V2::Conversation::Intent::IntentParameterValue ===
    # Fields for IntentParameterValue
    # Field: original Type: 9 ()
    # Field: resolved Type: 11 (.google.protobuf.Value)

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Actions::Sdk::V2::Conversation::Intent - Compiled Protocol Buffers messages for google/actions/sdk/v2/conversation/intent.proto

=head1 SYNOPSIS

    use Google::Actions::Sdk::V2::Conversation::Intent;

    my $msg = Google::Actions::Sdk::V2::Conversation::Intent::Intent->new({
        name => $name,
        params => $params,
        query => $query,
    });

    # Read or update a field
    my $val = $msg->name();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Actions::Sdk::V2::Conversation::Intent::Intent->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/actions/sdk/v2/conversation/intent.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Actions::Sdk::V2::Conversation::Intent::Intent

Represents an intent.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. The name of the last matched intent.

=item * C<< $msg->params() >> / C<< $msg->params($value) >>

Type: C<Message> (L<Google::Actions::Sdk::V2::Conversation::Intent::Intent::ParamsEntry>)

Required. Represents parameters identified as part of intent matching.
This is a map of the name of the identified parameter to the value of the
parameter identified from user input. All parameters defined in
the matched intent that are identified will be surfaced here.

=item * C<< $msg->query() >> / C<< $msg->query($value) >>

Type: C<String>

Optional. Typed or spoken input from the end user that matched this intent.
This will be populated when an intent is matched, based on the user input.

=back

=head2 Google::Actions::Sdk::V2::Conversation::Intent::IntentParameterValue

Represents a value for intent parameter.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->original() >> / C<< $msg->original($value) >>

Type: C<String>

Required. Original text value extracted from user utterance.

=item * C<< $msg->resolved() >> / C<< $msg->resolved($value) >>

Type: C<Message> (L<Google::Protobuf::Struct::Value>)

Required. Structured value for parameter extracted from user input.
This will only be populated if the parameter is defined in the matched
intent and the value of the parameter could be identified during intent
matching.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Actions::Sdk::V2::Conversation::Intent::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
