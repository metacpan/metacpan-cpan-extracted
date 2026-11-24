package Google::Actions::Sdk::V2::Interactionmodel::Type::EntityDisplay;

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
CkBnb29nbGUvYWN0aW9ucy9zZGsvdjIvaW50ZXJhY3Rpb25tb2RlbC90eXBlL2VudGl0eV9k
aXNwbGF5LnByb3RvEitnb29nbGUuYWN0aW9ucy5zZGsudjIuaW50ZXJhY3Rpb25tb2RlbC50
eXBlGh9nb29nbGUvYXBpL2ZpZWxkX2JlaGF2aW9yLnByb3RvIlMKDUVudGl0eURpc3BsYXkS
IgoKaWNvbl90aXRsZRgBIAEoCUID4EEBUglpY29uVGl0bGUSHgoIaWNvbl91cmwYAiABKAlC
A+BBAlIHaWNvblVybEKTAQovY29tLmdvb2dsZS5hY3Rpb25zLnNkay52Mi5pbnRlcmFjdGlv
bm1vZGVsLnR5cGVCEkVudGl0eURpc3BsYXlQcm90b1ABWkpnb29nbGUuZ29sYW5nLm9yZy9n
ZW5wcm90by9nb29nbGVhcGlzL2FjdGlvbnMvc2RrL3YyL2ludGVyYWN0aW9ubW9kZWwvdHlw
ZUrqCAoGEgQOACIBCrwECgEMEgMOABIysQQgQ29weXJpZ2h0IDIwMjUgR29vZ2xlIExMQwoK
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
EAA0CgkKAgMAEgMSACkKCAoBCBIDFABhCgkKAggLEgMUAGEKCAoBCBIDFQAiCgkKAggKEgMV
ACIKCAoBCBIDFgAzCgkKAggIEgMWADMKCAoBCBIDFwBICgkKAggBEgMXAEgKwQEKAgQAEgQc
ACIBGrQBIEVsZW1lbnRzIHRoYXQgd2lsbCBiZSBkaXNwbGF5ZWQgb24gdGhlIGNhbnZhcyBv
bmNlIGEgcGFydGljdWxhciB0eXBlJ3MgZW50aXR5CiBpcyBleHRyYWN0ZWQgZnJvbSBhIHF1
ZXJ5LiBPbmx5IHJlbGV2YW50IGZvciBjYW52YXMgZW5hYmxlZCBhcHBzLgogKipUaGlzIG1l
c3NhZ2UgaXMgbG9jYWxpemFibGUuKioKCgoKAwQAARIDHAgVCisKBAQAAgASAx4CQRoeIE9w
dGlvbmFsLiBUaXRsZSBvZiB0aGUgaWNvbi4KCgwKBQQAAgAFEgMeAggKDAoFBAACAAESAx4J
EwoMCgUEAAIAAxIDHhYXCgwKBQQAAgAIEgMeGEAKDwoIBAACAAicCAASAx4ZPwopCgQEAAIB
EgMhAj8aHCBSZXF1aXJlZC4gVXJsIG9mIHRoZSBpY29uLgoKDAoFBAACAQUSAyECCAoMCgUE
AAIBARIDIQkRCgwKBQQAAgEDEgMhFBUKDAoFBAACAQgSAyEWPgoPCggEAAIBCJwIABIDIRc9
YgZwcm90bzM=
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Actions::Sdk::V2::Interactionmodel::Type::EntityDisplay::EntityDisplay ===
    # Fields for EntityDisplay
    # Field: icon_title Type: 9 ()
    # Field: icon_url Type: 9 ()

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Actions::Sdk::V2::Interactionmodel::Type::EntityDisplay - Compiled Protocol Buffers messages for google/actions/sdk/v2/interactionmodel/type/entity_display.proto

=head1 SYNOPSIS

    use Google::Actions::Sdk::V2::Interactionmodel::Type::EntityDisplay;

    my $msg = Google::Actions::Sdk::V2::Interactionmodel::Type::EntityDisplay::EntityDisplay->new({
        icon_title => $icon_title,
        icon_url => $icon_url,
    });

    # Read or update a field
    my $val = $msg->icon_title();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Actions::Sdk::V2::Interactionmodel::Type::EntityDisplay::EntityDisplay->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/actions/sdk/v2/interactionmodel/type/entity_display.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Actions::Sdk::V2::Interactionmodel::Type::EntityDisplay::EntityDisplay

Elements that will be displayed on the canvas once a particular type's entity
is extracted from a query. Only relevant for canvas enabled apps.
B<This message is localizable.>

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->icon_title() >> / C<< $msg->icon_title($value) >>

Type: C<String>

Optional. Title of the icon.

=item * C<< $msg->icon_url() >> / C<< $msg->icon_url($value) >>

Type: C<String>

Required. Url of the icon.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Actions::Sdk::V2::Interactionmodel::Type::EntityDisplay::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
