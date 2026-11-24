package Google::Apps::Script::Type::AddonWidgetSet;

use strict;
use warnings;

our $VERSION = '0.14';

use Protobuf::Message;
use Protobuf::DescriptorPool;
use Protobuf::Internal qw(:all);
use MIME::Base64;

BEGIN {
    my $descriptor_b64 = <<'EOF';
Ci5nb29nbGUvYXBwcy9zY3JpcHQvdHlwZS9hZGRvbl93aWRnZXRfc2V0LnByb3RvEhdnb29n
bGUuYXBwcy5zY3JpcHQudHlwZSKxAgoOQWRkT25XaWRnZXRTZXQSVQoMdXNlZF93aWRnZXRz
GAEgAygOMjIuZ29vZ2xlLmFwcHMuc2NyaXB0LnR5cGUuQWRkT25XaWRnZXRTZXQuV2lkZ2V0
VHlwZVILdXNlZFdpZGdldHMixwEKCldpZGdldFR5cGUSGwoXV0lER0VUX1RZUEVfVU5TUEVD
SUZJRUQQABIPCgtEQVRFX1BJQ0tFUhABEhIKDlNUWUxFRF9CVVRUT05TEAISFAoQUEVSU0lT
VEVOVF9GT1JNUxADEhAKDEZJWEVEX0ZPT1RFUhAEEiEKHVVQREFURV9TVUJKRUNUX0FORF9S
RUNJUElFTlRTEAUSDwoLR1JJRF9XSURHRVQQBhIbChdBRERPTl9DT01QT1NFX1VJX0FDVElP
ThAHQr0BChtjb20uZ29vZ2xlLmFwcHMuc2NyaXB0LnR5cGVCE0FkZE9uV2lkZ2V0U2V0UHJv
dG9QAVo2Z29vZ2xlLmdvbGFuZy5vcmcvZ2VucHJvdG8vZ29vZ2xlYXBpcy9hcHBzL3Njcmlw
dC90eXBlqgIXR29vZ2xlLkFwcHMuU2NyaXB0LlR5cGXKAhdHb29nbGVcQXBwc1xTY3JpcHRc
VHlwZeoCGkdvb2dsZTo6QXBwczo6U2NyaXB0OjpUeXBlSqgNCgYSBA4AOQEKvAQKAQwSAw4A
EjKxBCBDb3B5cmlnaHQgMjAyNSBHb29nbGUgTExDCgogTGljZW5zZWQgdW5kZXIgdGhlIEFw
YWNoZSBMaWNlbnNlLCBWZXJzaW9uIDIuMCAodGhlICJMaWNlbnNlIik7CiB5b3UgbWF5IG5v
dCB1c2UgdGhpcyBmaWxlIGV4Y2VwdCBpbiBjb21wbGlhbmNlIHdpdGggdGhlIExpY2Vuc2Uu
CiBZb3UgbWF5IG9idGFpbiBhIGNvcHkgb2YgdGhlIExpY2Vuc2UgYXQKCiAgICAgaHR0cDov
L3d3dy5hcGFjaGUub3JnL2xpY2Vuc2VzL0xJQ0VOU0UtMi4wCgogVW5sZXNzIHJlcXVpcmVk
IGJ5IGFwcGxpY2FibGUgbGF3IG9yIGFncmVlZCB0byBpbiB3cml0aW5nLCBzb2Z0d2FyZQog
ZGlzdHJpYnV0ZWQgdW5kZXIgdGhlIExpY2Vuc2UgaXMgZGlzdHJpYnV0ZWQgb24gYW4gIkFT
IElTIiBCQVNJUywKIFdJVEhPVVQgV0FSUkFOVElFUyBPUiBDT05ESVRJT05TIE9GIEFOWSBL
SU5ELCBlaXRoZXIgZXhwcmVzcyBvciBpbXBsaWVkLgogU2VlIHRoZSBMaWNlbnNlIGZvciB0
aGUgc3BlY2lmaWMgbGFuZ3VhZ2UgZ292ZXJuaW5nIHBlcm1pc3Npb25zIGFuZAogbGltaXRh
dGlvbnMgdW5kZXIgdGhlIExpY2Vuc2UuCgoICgECEgMQACAKCAoBCBIDEgA0CgkKAgglEgMS
ADQKCAoBCBIDEwBNCgkKAggLEgMTAE0KCAoBCBIDFAAiCgkKAggKEgMUACIKCAoBCBIDFQA0
CgkKAggIEgMVADQKCAoBCBIDFgA0CgkKAggBEgMWADQKCAoBCBIDFwA0CgkKAggpEgMXADQK
CAoBCBIDGAAzCgkKAggtEgMYADMKMgoCBAASBBsAOQEaJiBUaGUgd2lkZ2V0IHN1YnNldCB1
c2VkIGJ5IGFuIGFkZC1vbi4KCgoKAwQAARIDGwgWCkEKBAQABAASBB0CNQMaMyBUaGUgV2lk
Z2V0IHR5cGUuIERFRkFVTFQgaXMgdGhlIGJhc2ljIHdpZGdldCBzZXQuCgoMCgUEAAQAARID
HQcRCigKBgQABAACABIDHwQgGhkgVGhlIGRlZmF1bHQgd2lkZ2V0IHNldC4KCg4KBwQABAAC
AAESAx8EGwoOCgcEAAQAAgACEgMfHh8KIQoGBAAEAAIBEgMiBBQaEiBUaGUgZGF0ZSBwaWNr
ZXIuCgoOCgcEAAQAAgEBEgMiBA8KDgoHBAAEAAIBAhIDIhITCkwKBgQABAACAhIDJQQXGj0g
U3R5bGVkIGJ1dHRvbnMgaW5jbHVkZSBmaWxsZWQgYnV0dG9ucyBhbmQgZGlzYWJsZWQgYnV0
dG9ucy4KCg4KBwQABAACAgESAyUEEgoOCgcEAAQAAgICEgMlFRYKTgoGBAAEAAIDEgMoBBka
PyBQZXJzaXN0ZW50IGZvcm1zIGFsbG93IHBlcnNpc3RpbmcgZm9ybSB2YWx1ZXMgZHVyaW5n
IGFjdGlvbnMuCgoOCgcEAAQAAgMBEgMoBBQKDgoHBAAEAAIDAhIDKBcYCiYKBgQABAACBBID
KwQVGhcgRml4ZWQgZm9vdGVyIGluIGNhcmQuCgoOCgcEAAQAAgQBEgMrBBAKDgoHBAAEAAIE
AhIDKxMUCj4KBgQABAACBRIDLgQmGi8gVXBkYXRlIHRoZSBzdWJqZWN0IGFuZCByZWNpcGll
bnRzIG9mIGEgZHJhZnQuCgoOCgcEAAQAAgUBEgMuBCEKDgoHBAAEAAIFAhIDLiQlCiEKBgQA
BAACBhIDMQQUGhIgVGhlIGdyaWQgd2lkZ2V0LgoKDgoHBAAEAAIGARIDMQQPCg4KBwQABAAC
BgISAzESEwpMCgYEAAQAAgcSAzQEIBo9IEEgR21haWwgYWRkLW9uIGFjdGlvbiB0aGF0IGFw
cGxpZXMgdG8gdGhlIGFkZG9uIGNvbXBvc2UgVUkuCgoOCgcEAAQAAgcBEgM0BBsKDgoHBAAE
AAIHAhIDNB4fCjUKBAQAAgASAzgCJxooIFRoZSBsaXN0IG9mIHdpZGdldHMgdXNlZCBpbiBh
biBhZGQtb24uCgoMCgUEAAIABBIDOAIKCgwKBQQAAgAGEgM4CxUKDAoFBAACAAESAzgWIgoM
CgUEAAIAAxIDOCUmYgZwcm90bzM=
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Apps::Script::Type::AddonWidgetSet::AddOnWidgetSet ===
    # Fields for AddOnWidgetSet
    # Field: used_widgets Type: 14 (.google.apps.script.type.AddOnWidgetSet.WidgetType)

# Enum: AddOnWidgetSet::WidgetType
our $AddOnWidgetSet_WIDGET_TYPE_UNSPECIFIED = 0;
our $AddOnWidgetSet_DATE_PICKER = 1;
our $AddOnWidgetSet_STYLED_BUTTONS = 2;
our $AddOnWidgetSet_PERSISTENT_FORMS = 3;
our $AddOnWidgetSet_FIXED_FOOTER = 4;
our $AddOnWidgetSet_UPDATE_SUBJECT_AND_RECIPIENTS = 5;
our $AddOnWidgetSet_GRID_WIDGET = 6;
our $AddOnWidgetSet_ADDON_COMPOSE_UI_ACTION = 7;

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Apps::Script::Type::AddonWidgetSet - Compiled Protocol Buffers messages for google/apps/script/type/addon_widget_set.proto

=head1 SYNOPSIS

    use Google::Apps::Script::Type::AddonWidgetSet;

    my $msg = Google::Apps::Script::Type::AddonWidgetSet::AddOnWidgetSet->new({
        used_widgets => $used_widgets,
    });

    # Read or update a field
    my $val = $msg->used_widgets();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Apps::Script::Type::AddonWidgetSet::AddOnWidgetSet->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/apps/script/type/addon_widget_set.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Apps::Script::Type::AddonWidgetSet::AddOnWidgetSet

The widget subset used by an add-on.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->used_widgets() >> / C<< $msg->used_widgets($value) >>

Type: C<Enum> (L<Google::Apps::Script::Type::AddOnWidgetSet::WidgetType>)

The list of widgets used in an add-on.

=back

=head3 Enum: AddOnWidgetSet::WidgetType

=over 4

=item * C<WIDGET_TYPE_UNSPECIFIED> => C<0>

=item * C<DATE_PICKER> => C<1>

=item * C<STYLED_BUTTONS> => C<2>

=item * C<PERSISTENT_FORMS> => C<3>

=item * C<FIXED_FOOTER> => C<4>

=item * C<UPDATE_SUBJECT_AND_RECIPIENTS> => C<5>

=item * C<GRID_WIDGET> => C<6>

=item * C<ADDON_COMPOSE_UI_ACTION> => C<7>

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Apps::Script::Type::AddonWidgetSet::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
