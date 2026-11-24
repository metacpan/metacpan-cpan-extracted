package Google::Actions::Sdk::V2::Interactionmodel::Type::RegularExpressionType;

use strict;
use warnings;

our $VERSION = '0.14';

use Protobuf::Message;
use Protobuf::DescriptorPool;
use Protobuf::Internal qw(:all);
use MIME::Base64;

BEGIN {
    eval { require Google::Actions::Sdk::V2::Interactionmodel::Type::EntityDisplay };
    eval { require Google::Api::FieldBehavior };
    my $descriptor_b64 = <<'EOF';
Cklnb29nbGUvYWN0aW9ucy9zZGsvdjIvaW50ZXJhY3Rpb25tb2RlbC90eXBlL3JlZ3VsYXJf
ZXhwcmVzc2lvbl90eXBlLnByb3RvEitnb29nbGUuYWN0aW9ucy5zZGsudjIuaW50ZXJhY3Rp
b25tb2RlbC50eXBlGkBnb29nbGUvYWN0aW9ucy9zZGsvdjIvaW50ZXJhY3Rpb25tb2RlbC90
eXBlL2VudGl0eV9kaXNwbGF5LnByb3RvGh9nb29nbGUvYXBpL2ZpZWxkX2JlaGF2aW9yLnBy
b3RvIq8DChVSZWd1bGFyRXhwcmVzc2lvblR5cGUScQoIZW50aXRpZXMYASADKAsyUC5nb29n
bGUuYWN0aW9ucy5zZGsudjIuaW50ZXJhY3Rpb25tb2RlbC50eXBlLlJlZ3VsYXJFeHByZXNz
aW9uVHlwZS5FbnRpdGllc0VudHJ5QgPgQQJSCGVudGl0aWVzGpkBCgZFbnRpdHkSWQoHZGlz
cGxheRgBIAEoCzI6Lmdvb2dsZS5hY3Rpb25zLnNkay52Mi5pbnRlcmFjdGlvbm1vZGVsLnR5
cGUuRW50aXR5RGlzcGxheUID4EEBUgdkaXNwbGF5EjQKE3JlZ3VsYXJfZXhwcmVzc2lvbnMY
AiADKAlCA+BBAlIScmVndWxhckV4cHJlc3Npb25zGoYBCg1FbnRpdGllc0VudHJ5EhAKA2tl
eRgBIAEoCVIDa2V5El8KBXZhbHVlGAIgASgLMkkuZ29vZ2xlLmFjdGlvbnMuc2RrLnYyLmlu
dGVyYWN0aW9ubW9kZWwudHlwZS5SZWd1bGFyRXhwcmVzc2lvblR5cGUuRW50aXR5UgV2YWx1
ZToCOAFCmwEKL2NvbS5nb29nbGUuYWN0aW9ucy5zZGsudjIuaW50ZXJhY3Rpb25tb2RlbC50
eXBlQhpSZWd1bGFyRXhwcmVzc2lvblR5cGVQcm90b1ABWkpnb29nbGUuZ29sYW5nLm9yZy9n
ZW5wcm90by9nb29nbGVhcGlzL2FjdGlvbnMvc2RrL3YyL2ludGVyYWN0aW9ubW9kZWwvdHlw
ZUqIDAoGEgQOACsBCrwECgEMEgMOABIysQQgQ29weXJpZ2h0IDIwMjUgR29vZ2xlIExMQwoK
IExpY2Vuc2VkIHVuZGVyIHRoZSBBcGFjaGUgTGljZW5zZSwgVmVyc2lvbiAyLjAgKHRoZSAi
TGljZW5zZSIpOwogeW91IG1heSBub3QgdXNlIHRoaXMgZmlsZSBleGNlcHQgaW4gY29tcGxp
YW5jZSB3aXRoIHRoZSBMaWNlbnNlLgogWW91IG1heSBvYnRhaW4gYSBjb3B5IG9mIHRoZSBM
aWNlbnNlIGF0CgogICAgIGh0dHA6Ly93d3cuYXBhY2hlLm9yZy9saWNlbnNlcy9MSUNFTlNF
LTIuMAoKIFVubGVzcyByZXF1aXJlZCBieSBhcHBsaWNhYmxlIGxhdyBvciBhZ3JlZWQgdG8g
aW4gd3JpdGluZywgc29mdHdhcmUKIGRpc3RyaWJ1dGVkIHVuZGVyIHRoZSBMaWNlbnNlIGlz
IGRpc3RyaWJ1dGVkIG9uIGFuICJBUyBJUyIgQkFTSVMsCiBXSVRIT1VUIFdBUlJBTlRJRVMg
T1IgQ09ORElUSU9OUyBPRiBBTlkgS0lORCwgZWl0aGVyIGV4cHJlc3Mgb3IgaW1wbGllZC4K
IFNlZSB0aGUgTGljZW5zZSBmb3IgdGhlIHNwZWNpZmljIGxhbmd1YWdlIGdvdmVybmluZyBw
ZXJtaXNzaW9ucyBhbmQKIGxpbWl0YXRpb25zIHVuZGVyIHRoZSBMaWNlbnNlLgoKCAoBAhID
EAA0CgkKAgMAEgMSAEoKCQoCAwESAxMAKQoICgEIEgMVAGEKCQoCCAsSAxUAYQoICgEIEgMW
ACIKCQoCCAoSAxYAIgoICgEIEgMXADsKCQoCCAgSAxcAOwoICgEIEgMYAEgKCQoCCAESAxgA
SApeCgIEABIEHAArARpSIFR5cGUgdGhhdCBtYXRjaGVzIHRleHQgYnkgcmVndWxhciBleHBy
ZXNzaW9ucy4KICoqVGhpcyBtZXNzYWdlIGlzIGxvY2FsaXphYmxlLioqCgoKCgMEAAESAxwI
HQpuCgQEAAMAEgQfAicDGmAgUmVwcmVzZW50cyBhbiBlbnRpdHkgb2JqZWN0IHRoYXQgY29u
dGFpbnMgdGhlIHJlZ3VsYXIgZXhwcmVzc2lvbiB0aGF0IGlzCiB1c2VkIGZvciBjb21wYXJp
c29uLgoKDAoFBAADAAESAx8KEAqbAQoGBAADAAIAEgMiBEcaiwEgT3B0aW9uYWwuIEVsZW1l
bnRzIHRoYXQgd2lsbCBiZSBkaXNwbGF5ZWQgb24gdGhlIGNhbnZhcyBvbmNlIGFuIGVudGl0
eSBpcwogZXh0cmFjdGVkIGZyb20gYSBxdWVyeS4gT25seSByZWxldmFudCBmb3IgY2FudmFz
IGVuYWJsZWQgYXBwcy4KCg4KBwQAAwACAAYSAyIEEQoOCgcEAAMAAgABEgMiEhkKDgoHBAAD
AAIAAxIDIhwdCg4KBwQAAwACAAgSAyIeRgoRCgoEAAMAAgAInAgAEgMiH0UKcgoGBAADAAIB
EgMmBFUaYyBSZXF1aXJlZC4gVXNlcyBSRTIgcmVnZXggc3ludGF4IChTZWUKIGh0dHBzOi8v
Z2l0aHViLmNvbS9nb29nbGUvcmUyL3dpa2kvU3ludGF4IGZvciBtb3JlIGRldGFpbHMpCgoO
CgcEAAMAAgEEEgMmBAwKDgoHBAADAAIBBRIDJg0TCg4KBwQAAwACAQESAyYUJwoOCgcEAAMA
AgEDEgMmKisKDgoHBAADAAIBCBIDJixUChEKCgQAAwACAQicCAASAyYtUwpQCgQEAAIAEgMq
AkwaQyBSZXF1aXJlZC4gTmFtZWQgbWFwIG9mIGVudGl0aWVzIHdoaWNoIGVhY2ggY29udGFp
biBSZWdleCBzdHJpbmdzLgoKDAoFBAACAAYSAyoCFQoMCgUEAAIAARIDKhYeCgwKBQQAAgAD
EgMqISIKDAoFBAACAAgSAyojSwoPCggEAAIACJwIABIDKiRKYgZwcm90bzM=
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Actions::Sdk::V2::Interactionmodel::Type::RegularExpressionType::RegularExpressionType ===
    # Fields for RegularExpressionType
    # Field: entities Type: 11 (.google.actions.sdk.v2.interactionmodel.type.RegularExpressionType.EntitiesEntry)

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Actions::Sdk::V2::Interactionmodel::Type::RegularExpressionType - Compiled Protocol Buffers messages for google/actions/sdk/v2/interactionmodel/type/regular_expression_type.proto

=head1 SYNOPSIS

    use Google::Actions::Sdk::V2::Interactionmodel::Type::RegularExpressionType;

    my $msg = Google::Actions::Sdk::V2::Interactionmodel::Type::RegularExpressionType::RegularExpressionType->new({
        entities => $entities,
    });

    # Read or update a field
    my $val = $msg->entities();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Actions::Sdk::V2::Interactionmodel::Type::RegularExpressionType::RegularExpressionType->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/actions/sdk/v2/interactionmodel/type/regular_expression_type.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Actions::Sdk::V2::Interactionmodel::Type::RegularExpressionType::RegularExpressionType

Type that matches text by regular expressions.
B<This message is localizable.>

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->entities() >> / C<< $msg->entities($value) >>

Type: C<Message> (L<Google::Actions::Sdk::V2::Interactionmodel::Type::RegularExpressionType::RegularExpressionType::EntitiesEntry>)

Required. Named map of entities which each contain Regex strings.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Actions::Sdk::V2::Interactionmodel::Type::RegularExpressionType::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
