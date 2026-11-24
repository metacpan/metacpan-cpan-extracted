package Google::Apps::Script::Type::ExtensionPoint;

use strict;
use warnings;

our $VERSION = '0.14';

use Protobuf::Message;
use Protobuf::DescriptorPool;
use Protobuf::Internal qw(:all);
use MIME::Base64;

BEGIN {
    eval { require Google::Protobuf::Wrappers };
    my $descriptor_b64 = <<'EOF';
Ci1nb29nbGUvYXBwcy9zY3JpcHQvdHlwZS9leHRlbnNpb25fcG9pbnQucHJvdG8SF2dvb2ds
ZS5hcHBzLnNjcmlwdC50eXBlGh5nb29nbGUvcHJvdG9idWYvd3JhcHBlcnMucHJvdG8ibAoW
TWVudUl0ZW1FeHRlbnNpb25Qb2ludBIhCgxydW5fZnVuY3Rpb24YASABKAlSC3J1bkZ1bmN0
aW9uEhQKBWxhYmVsGAIgASgJUgVsYWJlbBIZCghsb2dvX3VybBgDIAEoCVIHbG9nb1VybCJx
ChZIb21lcGFnZUV4dGVuc2lvblBvaW50EiEKDHJ1bl9mdW5jdGlvbhgBIAEoCVILcnVuRnVu
Y3Rpb24SNAoHZW5hYmxlZBgCIAEoCzIaLmdvb2dsZS5wcm90b2J1Zi5Cb29sVmFsdWVSB2Vu
YWJsZWQiiAEKHVVuaXZlcnNhbEFjdGlvbkV4dGVuc2lvblBvaW50EhQKBWxhYmVsGAEgASgJ
UgVsYWJlbBIdCglvcGVuX2xpbmsYAiABKAlIAFIIb3BlbkxpbmsSIwoMcnVuX2Z1bmN0aW9u
GAMgASgJSABSC3J1bkZ1bmN0aW9uQg0KC2FjdGlvbl90eXBlQqgBChtjb20uZ29vZ2xlLmFw
cHMuc2NyaXB0LnR5cGVQAVo2Z29vZ2xlLmdvbGFuZy5vcmcvZ2VucHJvdG8vZ29vZ2xlYXBp
cy9hcHBzL3NjcmlwdC90eXBlqgIXR29vZ2xlLkFwcHMuU2NyaXB0LlR5cGXKAhdHb29nbGVc
QXBwc1xTY3JpcHRcVHlwZeoCGkdvb2dsZTo6QXBwczo6U2NyaXB0OjpUeXBlSvATCgYSBA4A
TAEKvAQKAQwSAw4AEjKxBCBDb3B5cmlnaHQgMjAyNSBHb29nbGUgTExDCgogTGljZW5zZWQg
dW5kZXIgdGhlIEFwYWNoZSBMaWNlbnNlLCBWZXJzaW9uIDIuMCAodGhlICJMaWNlbnNlIik7
CiB5b3UgbWF5IG5vdCB1c2UgdGhpcyBmaWxlIGV4Y2VwdCBpbiBjb21wbGlhbmNlIHdpdGgg
dGhlIExpY2Vuc2UuCiBZb3UgbWF5IG9idGFpbiBhIGNvcHkgb2YgdGhlIExpY2Vuc2UgYXQK
CiAgICAgaHR0cDovL3d3dy5hcGFjaGUub3JnL2xpY2Vuc2VzL0xJQ0VOU0UtMi4wCgogVW5s
ZXNzIHJlcXVpcmVkIGJ5IGFwcGxpY2FibGUgbGF3IG9yIGFncmVlZCB0byBpbiB3cml0aW5n
LCBzb2Z0d2FyZQogZGlzdHJpYnV0ZWQgdW5kZXIgdGhlIExpY2Vuc2UgaXMgZGlzdHJpYnV0
ZWQgb24gYW4gIkFTIElTIiBCQVNJUywKIFdJVEhPVVQgV0FSUkFOVElFUyBPUiBDT05ESVRJ
T05TIE9GIEFOWSBLSU5ELCBlaXRoZXIgZXhwcmVzcyBvciBpbXBsaWVkLgogU2VlIHRoZSBM
aWNlbnNlIGZvciB0aGUgc3BlY2lmaWMgbGFuZ3VhZ2UgZ292ZXJuaW5nIHBlcm1pc3Npb25z
IGFuZAogbGltaXRhdGlvbnMgdW5kZXIgdGhlIExpY2Vuc2UuCgoICgECEgMQACAKCQoCAwAS
AxIAKAoICgEIEgMUADQKCQoCCCUSAxQANAoICgEIEgMVAE0KCQoCCAsSAxUATQoICgEIEgMW
ACIKCQoCCAoSAxYAIgoICgEIEgMXADQKCQoCCAESAxcANAoICgEIEgMYADQKCQoCCCkSAxgA
NAoICgEIEgMZADMKCQoCCC0SAxkAMwqoAQoCBAASBB8ALAEaVyBDb21tb24gZm9ybWF0IGZv
ciBkZWNsYXJpbmcgYSAgbWVudSBpdGVtLCBvciBidXR0b24sIHRoYXQgYXBwZWFycyB3aXRo
aW4gYQogaG9zdCBhcHAuCjJDIENvbW1vbiBNYW5pZmVzdCBwcm90b3MgZm9yIEcgU3VpdGUg
ZXh0ZW5zaW9uLXBvaW50IGNvbmZpZ3VyYXRpb24uCgoKCgMEAAESAx8IHgpZCgQEAAIAEgMi
AhoaTCBSZXF1aXJlZC4gVGhlIGVuZHBvaW50IHRvIGV4ZWN1dGUgd2hlbiB0aGlzIGV4dGVu
c2lvbiBwb2ludCBpcwogYWN0aXZhdGVkLgoKDAoFBAACAAUSAyICCAoMCgUEAAIAARIDIgkV
CgwKBQQAAgADEgMiGBkKigEKBAQAAgESAyYCExp9IFJlcXVpcmVkLiBVc2VyLXZpc2libGUg
dGV4dCBkZXNjcmliaW5nIHRoZSBhY3Rpb24gdGFrZW4gYnkgYWN0aXZhdGluZyB0aGlzCiBl
eHRlbnNpb24gcG9pbnQuIEZvciBleGFtcGxlLCAiSW5zZXJ0IGludm9pY2UiLgoKDAoFBAAC
AQUSAyYCCAoMCgUEAAIBARIDJgkOCgwKBQQAAgEDEgMmERIKfwoEBAACAhIDKwIWGnIgVGhl
IFVSTCBmb3IgdGhlIGxvZ28gaW1hZ2Ugc2hvd24gaW4gdGhlIGFkZC1vbiB0b29sYmFyLgoK
IElmIG5vdCBzZXQsIGRlZmF1bHRzIHRvIHRoZSBhZGQtb24ncyBwcmltYXJ5IGxvZ28gVVJM
LgoKDAoFBAACAgUSAysCCAoMCgUEAAICARIDKwkRCgwKBQQAAgIDEgMrFBUKRQoCBAESBC8A
OwEaOSBDb21tb24gZm9ybWF0IGZvciBkZWNsYXJpbmcgYW4gYWRkLW9uJ3MgaG9tZS1wYWdl
IHZpZXcuCgoKCgMEAQESAy8IHgpZCgQEAQIAEgMyAhoaTCBSZXF1aXJlZC4gVGhlIGVuZHBv
aW50IHRvIGV4ZWN1dGUgd2hlbiB0aGlzIGV4dGVuc2lvbiBwb2ludCBpcwogYWN0aXZhdGVk
LgoKDAoFBAECAAUSAzICCAoMCgUEAQIAARIDMgkVCgwKBQQBAgADEgMyGBkK7gEKBAQBAgES
AzoCKBrgASBPcHRpb25hbC4gSWYgc2V0IHRvIGBmYWxzZWAsIGRpc2FibGUgdGhlIGhvbWUt
cGFnZSB2aWV3IGluIHRoaXMgY29udGV4dC4KCiBEZWZhdWx0cyB0byBgdHJ1ZWAgaWYgdW5z
ZXQuCgogSWYgYW4gYWRkLW9ucyBjdXN0b20gaG9tZS1wYWdlIHZpZXcgaXMgZGlzYWJsZWQs
IGFuIGF1dG9nZW5lcmF0ZWQgb3ZlcnZpZXcKIGNhcmQgd2lsbCBiZSBwcm92aWRlZCBmb3Ig
dXNlcnMgaW5zdGVhZC4KCgwKBQQBAgEGEgM6AhsKDAoFBAECAQESAzocIwoMCgUEAQIBAxID
OiYnClAKAgQCEgQ+AEwBGkQgRm9ybWF0IGZvciBkZWNsYXJpbmcgYSB1bml2ZXJzYWwgYWN0
aW9uIG1lbnUgaXRlbSBleHRlbnNpb24gcG9pbnQuCgoKCgMEAgESAz4IJQqOAQoEBAICABID
QQITGoABIFJlcXVpcmVkLiBVc2VyLXZpc2libGUgdGV4dCBkZXNjcmliaW5nIHRoZSBhY3Rp
b24gdGFrZW4gYnkgYWN0aXZhdGluZyB0aGlzCiBleHRlbnNpb24gcG9pbnQsIGZvciBleGFt
cGxlLCAiQWRkIGEgbmV3IGNvbnRhY3QiLgoKDAoFBAICAAUSA0ECCAoMCgUEAgIAARIDQQkO
CgwKBQQCAgADEgNBERIKkwEKBAQCCAASBEUCSwMahAEgUmVxdWlyZWQuIFRoZSBhY3Rpb24g
dHlwZSBzdXBwb3J0ZWQgb24gYSB1bml2ZXJzYWwgYWN0aW9uIG1lbnUgaXRlbS4gSXQKIGNv
dWxkIGJlIGVpdGhlciBhIGxpbmsgdG8gb3BlbiBvciBhbiBlbmRwb2ludCB0byBleGVjdXRl
LgoKDAoFBAIIAAESA0UIEwo3CgQEAgIBEgNHBBkaKiBVUkwgdG8gYmUgb3BlbmVkIGJ5IHRo
ZSBVbml2ZXJzYWxBY3Rpb24uCgoMCgUEAgIBBRIDRwQKCgwKBQQCAgEBEgNHCxQKDAoFBAIC
AQMSA0cXGAo5CgQEAgICEgNKBBwaLCBFbmRwb2ludCB0byBiZSBydW4gYnkgdGhlIFVuaXZl
cnNhbEFjdGlvbi4KCgwKBQQCAgIFEgNKBAoKDAoFBAICAgESA0oLFwoMCgUEAgICAxIDShob
YgZwcm90bzM=
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Apps::Script::Type::ExtensionPoint::MenuItemExtensionPoint ===
    # Fields for MenuItemExtensionPoint
    # Field: run_function Type: 9 ()
    # Field: label Type: 9 ()
    # Field: logo_url Type: 9 ()

# === Message: Google::Apps::Script::Type::ExtensionPoint::HomepageExtensionPoint ===
    # Fields for HomepageExtensionPoint
    # Field: run_function Type: 9 ()
    # Field: enabled Type: 11 (.google.protobuf.BoolValue)

# === Message: Google::Apps::Script::Type::ExtensionPoint::UniversalActionExtensionPoint ===
    # Fields for UniversalActionExtensionPoint
    # Field: label Type: 9 ()
    # Field: open_link Type: 9 ()
    # Field: run_function Type: 9 ()

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Apps::Script::Type::ExtensionPoint - Compiled Protocol Buffers messages for google/apps/script/type/extension_point.proto

=head1 SYNOPSIS

    use Google::Apps::Script::Type::ExtensionPoint;

    my $msg = Google::Apps::Script::Type::ExtensionPoint::MenuItemExtensionPoint->new({
        run_function => $run_function,
        label => $label,
        logo_url => $logo_url,
    });

    # Read or update a field
    my $val = $msg->run_function();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Apps::Script::Type::ExtensionPoint::MenuItemExtensionPoint->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/apps/script/type/extension_point.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Apps::Script::Type::ExtensionPoint::MenuItemExtensionPoint

Common format for declaring a  menu item, or button, that appears within a
host app.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->run_function() >> / C<< $msg->run_function($value) >>

Type: C<String>

Required. The endpoint to execute when this extension point is
activated.

=item * C<< $msg->label() >> / C<< $msg->label($value) >>

Type: C<String>

Required. User-visible text describing the action taken by activating this
extension point. For example, "Insert invoice".

=item * C<< $msg->logo_url() >> / C<< $msg->logo_url($value) >>

Type: C<String>

The URL for the logo image shown in the add-on toolbar.

If not set, defaults to the add-on's primary logo URL.

=back

=head2 Google::Apps::Script::Type::ExtensionPoint::HomepageExtensionPoint

Common format for declaring an add-on's home-page view.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->run_function() >> / C<< $msg->run_function($value) >>

Type: C<String>

Required. The endpoint to execute when this extension point is
activated.

=item * C<< $msg->enabled() >> / C<< $msg->enabled($value) >>

Type: C<Message> (L<Google::Protobuf::Wrappers::BoolValue>)

Optional. If set to `false`, disable the home-page view in this context.

Defaults to `true` if unset.

If an add-ons custom home-page view is disabled, an autogenerated overview
card will be provided for users instead.

=back

=head2 Google::Apps::Script::Type::ExtensionPoint::UniversalActionExtensionPoint

Format for declaring a universal action menu item extension point.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->label() >> / C<< $msg->label($value) >>

Type: C<String>

Required. User-visible text describing the action taken by activating this
extension point, for example, "Add a new contact".

=item * C<< $msg->open_link() >> / C<< $msg->open_link($value) >>

Type: C<String>

URL to be opened by the UniversalAction.

=item * C<< $msg->run_function() >> / C<< $msg->run_function($value) >>

Type: C<String>

Endpoint to be run by the UniversalAction.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Apps::Script::Type::ExtensionPoint::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
