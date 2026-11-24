package Google::Apps::Script::Type::ScriptManifest;

use strict;
use warnings;

our $VERSION = '0.14';

use Protobuf::Message;
use Protobuf::DescriptorPool;
use Protobuf::Internal qw(:all);
use MIME::Base64;

BEGIN {
    eval { require Google::Apps::Script::Type::AddonWidgetSet };
    eval { require Google::Apps::Script::Type::ExtensionPoint };
    eval { require Google::Protobuf::Struct };
    my $descriptor_b64 = <<'EOF';
Ci1nb29nbGUvYXBwcy9zY3JpcHQvdHlwZS9zY3JpcHRfbWFuaWZlc3QucHJvdG8SF2dvb2ds
ZS5hcHBzLnNjcmlwdC50eXBlGi5nb29nbGUvYXBwcy9zY3JpcHQvdHlwZS9hZGRvbl93aWRn
ZXRfc2V0LnByb3RvGi1nb29nbGUvYXBwcy9zY3JpcHQvdHlwZS9leHRlbnNpb25fcG9pbnQu
cHJvdG8aHGdvb2dsZS9wcm90b2J1Zi9zdHJ1Y3QucHJvdG8isQQKE0NvbW1vbkFkZE9uTWFu
aWZlc3QSEgoEbmFtZRgBIAEoCVIEbmFtZRIZCghsb2dvX3VybBgCIAEoCVIHbG9nb1VybBJW
ChFsYXlvdXRfcHJvcGVydGllcxgDIAEoCzIpLmdvb2dsZS5hcHBzLnNjcmlwdC50eXBlLkxh
eW91dFByb3BlcnRpZXNSEGxheW91dFByb3BlcnRpZXMSUgoRYWRkX29uX3dpZGdldF9zZXQY
BCABKAsyJy5nb29nbGUuYXBwcy5zY3JpcHQudHlwZS5BZGRPbldpZGdldFNldFIOYWRkT25X
aWRnZXRTZXQSLQoTdXNlX2xvY2FsZV9mcm9tX2FwcBgFIAEoCFIQdXNlTG9jYWxlRnJvbUFw
cBJaChBob21lcGFnZV90cmlnZ2VyGAYgASgLMi8uZ29vZ2xlLmFwcHMuc2NyaXB0LnR5cGUu
SG9tZXBhZ2VFeHRlbnNpb25Qb2ludFIPaG9tZXBhZ2VUcmlnZ2VyEmMKEXVuaXZlcnNhbF9h
Y3Rpb25zGAcgAygLMjYuZ29vZ2xlLmFwcHMuc2NyaXB0LnR5cGUuVW5pdmVyc2FsQWN0aW9u
RXh0ZW5zaW9uUG9pbnRSEHVuaXZlcnNhbEFjdGlvbnMSTwoWb3Blbl9saW5rX3VybF9wcmVm
aXhlcxgIIAEoCzIaLmdvb2dsZS5wcm90b2J1Zi5MaXN0VmFsdWVSE29wZW5MaW5rVXJsUHJl
Zml4ZXMiYAoQTGF5b3V0UHJvcGVydGllcxIjCg1wcmltYXJ5X2NvbG9yGAEgASgJUgxwcmlt
YXJ5Q29sb3ISJwoPc2Vjb25kYXJ5X2NvbG9yGAIgASgJUg5zZWNvbmRhcnlDb2xvciJyCgtI
dHRwT3B0aW9ucxJjChRhdXRob3JpemF0aW9uX2hlYWRlchgBIAEoDjIwLmdvb2dsZS5hcHBz
LnNjcmlwdC50eXBlLkh0dHBBdXRob3JpemF0aW9uSGVhZGVyUhNhdXRob3JpemF0aW9uSGVh
ZGVyKnYKF0h0dHBBdXRob3JpemF0aW9uSGVhZGVyEikKJUhUVFBfQVVUSE9SSVpBVElPTl9I
RUFERVJfVU5TUEVDSUZJRUQQABITCg9TWVNURU1fSURfVE9LRU4QARIRCg1VU0VSX0lEX1RP
S0VOEAISCAoETk9ORRADQqgBChtjb20uZ29vZ2xlLmFwcHMuc2NyaXB0LnR5cGVQAVo2Z29v
Z2xlLmdvbGFuZy5vcmcvZ2VucHJvdG8vZ29vZ2xlYXBpcy9hcHBzL3NjcmlwdC90eXBlqgIX
R29vZ2xlLkFwcHMuU2NyaXB0LlR5cGXKAhdHb29nbGVcQXBwc1xTY3JpcHRcVHlwZeoCGkdv
b2dsZTo6QXBwczo6U2NyaXB0OjpUeXBlSrkdCgYSBA4AaAEKvAQKAQwSAw4AEjKxBCBDb3B5
cmlnaHQgMjAyNSBHb29nbGUgTExDCgogTGljZW5zZWQgdW5kZXIgdGhlIEFwYWNoZSBMaWNl
bnNlLCBWZXJzaW9uIDIuMCAodGhlICJMaWNlbnNlIik7CiB5b3UgbWF5IG5vdCB1c2UgdGhp
cyBmaWxlIGV4Y2VwdCBpbiBjb21wbGlhbmNlIHdpdGggdGhlIExpY2Vuc2UuCiBZb3UgbWF5
IG9idGFpbiBhIGNvcHkgb2YgdGhlIExpY2Vuc2UgYXQKCiAgICAgaHR0cDovL3d3dy5hcGFj
aGUub3JnL2xpY2Vuc2VzL0xJQ0VOU0UtMi4wCgogVW5sZXNzIHJlcXVpcmVkIGJ5IGFwcGxp
Y2FibGUgbGF3IG9yIGFncmVlZCB0byBpbiB3cml0aW5nLCBzb2Z0d2FyZQogZGlzdHJpYnV0
ZWQgdW5kZXIgdGhlIExpY2Vuc2UgaXMgZGlzdHJpYnV0ZWQgb24gYW4gIkFTIElTIiBCQVNJ
UywKIFdJVEhPVVQgV0FSUkFOVElFUyBPUiBDT05ESVRJT05TIE9GIEFOWSBLSU5ELCBlaXRo
ZXIgZXhwcmVzcyBvciBpbXBsaWVkLgogU2VlIHRoZSBMaWNlbnNlIGZvciB0aGUgc3BlY2lm
aWMgbGFuZ3VhZ2UgZ292ZXJuaW5nIHBlcm1pc3Npb25zIGFuZAogbGltaXRhdGlvbnMgdW5k
ZXIgdGhlIExpY2Vuc2UuCgoICgECEgMQACAKCQoCAwASAxIAOAoJCgIDARIDEwA3CgkKAgMC
EgMUACYKCAoBCBIDFgA0CgkKAgglEgMWADQKCAoBCBIDFwBNCgkKAggLEgMXAE0KCAoBCBID
GAAiCgkKAggKEgMYACIKCAoBCBIDGQA0CgkKAggBEgMZADQKCAoBCBIDGgA0CgkKAggpEgMa
ADQKCAoBCBIDGwAzCgkKAggtEgMbADMKVgoCBAASBB4AQwEaSiBBZGQtb24gY29uZmlndXJh
dGlvbiB0aGF0IGlzIHNoYXJlZCBhY3Jvc3MgYWxsIGFkZC1vbiBob3N0IGFwcGxpY2F0aW9u
cy4KCgoKAwQAARIDHggbCjgKBAQAAgASAyACEhorIFJlcXVpcmVkLiBUaGUgZGlzcGxheSBu
YW1lIG9mIHRoZSBhZGQtb24uCgoMCgUEAAIABRIDIAIICgwKBQQAAgABEgMgCQ0KDAoFBAAC
AAMSAyAQEQpQCgQEAAIBEgMjAhYaQyBSZXF1aXJlZC4gVGhlIFVSTCBmb3IgdGhlIGxvZ28g
aW1hZ2Ugc2hvd24gaW4gdGhlIGFkZC1vbiB0b29sYmFyLgoKDAoFBAACAQUSAyMCCAoMCgUE
AAIBARIDIwkRCgwKBQQAAgEDEgMjFBUKPQoEBAACAhIDJgIpGjAgQ29tbW9uIGxheW91dCBw
cm9wZXJ0aWVzIGZvciB0aGUgYWRkLW9uIGNhcmRzLgoKDAoFBAACAgYSAyYCEgoMCgUEAAIC
ARIDJhMkCgwKBQQAAgIDEgMmJygKdgoEBAACAxIDKgInGmkgVGhlIHdpZGdldHMgdXNlZCBp
biB0aGUgYWRkLW9uLiBJZiB0aGlzIGZpZWxkIGlzIG5vdCBzcGVjaWZpZWQsCiBpdCBpbmRp
Y2F0ZXMgdGhhdCBkZWZhdWx0IHNldCBpcyB1c2VkLgoKDAoFBAACAwYSAyoCEAoMCgUEAAID
ARIDKhEiCgwKBQQAAgMDEgMqJSYKQAoEBAACBBIDLQIfGjMgV2hldGhlciB0byBwYXNzIGxv
Y2FsZSBpbmZvcm1hdGlvbiBmcm9tIGhvc3QgYXBwLgoKDAoFBAACBAUSAy0CBgoMCgUEAAIE
ARIDLQcaCgwKBQQAAgQDEgMtHR4KgAIKBAQAAgUSAzMCLhryASBEZWZpbmVzIGFuIGVuZHBv
aW50IHRoYXQgd2lsbCBiZSBleGVjdXRlZCBpbiBhbnkgY29udGV4dCwgaW4KIGFueSBob3N0
LiBBbnkgY2FyZHMgZ2VuZXJhdGVkIGJ5IHRoaXMgZnVuY3Rpb24gd2lsbCBhbHdheXMgYmUg
YXZhaWxhYmxlIHRvCiB0aGUgdXNlciwgYnV0IG1heSBiZSBlY2xpcHNlZCBieSBjb250ZXh0
dWFsIGNvbnRlbnQgd2hlbiB0aGlzIGFkZC1vbgogZGVjbGFyZXMgbW9yZSB0YXJnZXRlZCB0
cmlnZ2Vycy4KCgwKBQQAAgUGEgMzAhgKDAoFBAACBQESAzMZKQoMCgUEAAIFAxIDMywtCt0B
CgQEAAIGEgM5Aj8azwEgRGVmaW5lcyBhIGxpc3Qgb2YgZXh0ZW5zaW9uIHBvaW50cyBpbiB0
aGUgdW5pdmVyc2FsIGFjdGlvbiBtZW51IHdoaWNoCiBzZXJ2ZXMgYXMgYSBzZXR0aW5nIG1l
bnUgZm9yIHRoZSBhZGQtb24uIFRoZSBleHRlbnNpb24gcG9pbnQgY2FuIGJlCiBsaW5rIFVS
TCB0byBvcGVuIG9yIGFuIGVuZHBvaW50IHRvIGV4ZWN1dGUgYXMgYSBmb3JtCiBzdWJtaXNz
aW9uLgoKDAoFBAACBgQSAzkCCgoMCgUEAAIGBhIDOQsoCgwKBQQAAgYBEgM5KToKDAoFBAAC
BgMSAzk9PgroAgoEBAACBxIDQgI3GtoCIEFuIE9wZW5MaW5rIGFjdGlvbgogY2FuIG9ubHkg
dXNlIGEgVVJMIHdpdGggYW4gSFRUUFMsIE1BSUxUTyBvciBURUwgc2NoZW1lLiAgRm9yIEhU
VFBTIGxpbmtzLAogdGhlIFVSTCBtdXN0IGFsc28KIFttYXRjaF0oL2dtYWlsL2FkZC1vbnMv
Y29uY2VwdHMvbWFuaWZlc3RzI3doaXRlbGlzdGluZ191cmxzKSBvbmUgb2YgdGhlCiBwcmVm
aXhlcyBzcGVjaWZpZWQgaW4gdGhpcyB3aGl0ZWxpc3QuIElmIHRoZSBwcmVmaXggb21pdHMg
dGhlIHNjaGVtZSwgSFRUUFMKIGlzIGFzc3VtZWQuICBOb3RpY2UgdGhhdCBIVFRQIGxpbmtz
IGFyZSBhdXRvbWF0aWNhbGx5IHJld3JpdHRlbiB0byBIVFRQUwogbGlua3MuCgoMCgUEAAIH
BhIDQgIbCgwKBQQAAgcBEgNCHDIKDAoFBAACBwMSA0I1NgpQCgIEARIERgBSARpEIENhcmQg
bGF5b3V0IHByb3BlcnRpZXMgc2hhcmVkIGFjcm9zcyBhbGwgYWRkLW9uIGhvc3QgYXBwbGlj
YXRpb25zLgoKCgoDBAEBEgNGCBgKrAEKBAQBAgASA0oCGxqeASBUaGUgcHJpbWFyeSBjb2xv
ciBvZiB0aGUgYWRkLW9uLiBJdCBzZXRzIHRoZSBjb2xvciBvZiB0b29sYmFyLiBJZiBubwog
cHJpbWFyeSBjb2xvciBpcyBzZXQgZXhwbGljaXRseSwgdGhlIGRlZmF1bHQgdmFsdWUgcHJv
dmlkZWQgYnkgdGhlCiBmcmFtZXdvcmsgaXMgdXNlZC4KCgwKBQQBAgAFEgNKAggKDAoFBAEC
AAESA0oJFgoMCgUEAQIAAxIDShkaCqsCCgQEAQIBEgNRAh0anQIgVGhlIHNlY29uZGFyeSBj
b2xvciBvZiB0aGUgYWRkLW9uLiBJdCBzZXRzIHRoZSBjb2xvciBvZiBidXR0b25zLgogSWYg
cHJpbWFyeSBjb2xvciBpcyBzZXQgYnV0IG5vIHNlY29uZGFyeSBjb2xvciBpcyBzZXQsIHRo
ZQogc2Vjb25kYXJ5IGNvbG9yIGlzIHRoZSBzYW1lIGFzIHRoZSBwcmltYXJ5IGNvbG9yLiBJ
ZiBuZWl0aGVyIHByaW1hcnkKIGNvbG9yIG5vciBzZWNvbmRhcnkgY29sb3IgaXMgc2V0LCB0
aGUgZGVmYXVsdCB2YWx1ZSBwcm92aWRlZCBieSB0aGUKIGZyYW1ld29yayBpcyB1c2VkLgoK
DAoFBAECAQUSA1ECCAoMCgUEAQIBARIDUQkYCgwKBQQBAgEDEgNRGxwKQwoCBAISBFUAWAEa
NyBPcHRpb25zIGZvciBzZW5kaW5nIHJlcXVlc3RzIHRvIGFkZC1vbiBIVFRQIGVuZHBvaW50
cwoKCgoDBAIBEgNVCBMKUAoEBAICABIDVwIzGkMgQ29uZmlndXJhdGlvbiBmb3IgdGhlIHRv
a2VuIHNlbnQgaW4gdGhlIEhUVFAgQXV0aG9yaXphdGlvbiBoZWFkZXIKCgwKBQQCAgAGEgNX
AhkKDAoFBAICAAESA1caLgoMCgUEAgIAAxIDVzEyCj8KAgUAEgRbAGgBGjMgQXV0aG9yaXph
dGlvbiBoZWFkZXIgc2VudCBpbiBhZGQtb24gSFRUUCByZXF1ZXN0cwoKCgoDBQABEgNbBRwK
PQoEBQACABIDXQIsGjAgRGVmYXVsdCB2YWx1ZSwgZXF1aXZhbGVudCB0byBgU1lTVEVNX0lE
X1RPS0VOYAoKDAoFBQACAAESA10CJwoMCgUFAAIAAhIDXSorCnMKBAUAAgESA2ECFhpmIFNl
bmQgYW4gSUQgdG9rZW4gZm9yIHRoZSBwcm9qZWN0LXNwZWNpZmljIEdvb2dsZSBXb3Jrc3Bh
Y2UgYWRkLW9ucyBzeXN0ZW0KIHNlcnZpY2UgYWNjb3VudCAoZGVmYXVsdCkKCgwKBQUAAgEB
EgNhAhEKDAoFBQACAQISA2EUFQowCgQFAAICEgNkAhQaIyBTZW5kIGFuIElEIHRva2VuIGZv
ciB0aGUgZW5kIHVzZXIKCgwKBQUAAgIBEgNkAg8KDAoFBQACAgISA2QSEwozCgQFAAIDEgNn
AgsaJiBEbyBub3Qgc2VuZCBhbiBBdXRoZW50aWNhdGlvbiBoZWFkZXIKCgwKBQUAAgMBEgNn
AgYKDAoFBQACAwISA2cJCmIGcHJvdG8z
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Apps::Script::Type::ScriptManifest::CommonAddOnManifest ===
    # Fields for CommonAddOnManifest
    # Field: name Type: 9 ()
    # Field: logo_url Type: 9 ()
    # Field: layout_properties Type: 11 (.google.apps.script.type.LayoutProperties)
    # Field: add_on_widget_set Type: 11 (.google.apps.script.type.AddOnWidgetSet)
    # Field: use_locale_from_app Type: 8 ()
    # Field: homepage_trigger Type: 11 (.google.apps.script.type.HomepageExtensionPoint)
    # Field: universal_actions Type: 11 (.google.apps.script.type.UniversalActionExtensionPoint)
    # Field: open_link_url_prefixes Type: 11 (.google.protobuf.ListValue)

# === Message: Google::Apps::Script::Type::ScriptManifest::LayoutProperties ===
    # Fields for LayoutProperties
    # Field: primary_color Type: 9 ()
    # Field: secondary_color Type: 9 ()

# === Message: Google::Apps::Script::Type::ScriptManifest::HttpOptions ===
    # Fields for HttpOptions
    # Field: authorization_header Type: 14 (.google.apps.script.type.HttpAuthorizationHeader)

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Apps::Script::Type::ScriptManifest - Compiled Protocol Buffers messages for google/apps/script/type/script_manifest.proto

=head1 SYNOPSIS

    use Google::Apps::Script::Type::ScriptManifest;

    my $msg = Google::Apps::Script::Type::ScriptManifest::CommonAddOnManifest->new({
        name => $name,
        logo_url => $logo_url,
        layout_properties => $layout_properties,
        add_on_widget_set => $add_on_widget_set,
    });

    # Read or update a field
    my $val = $msg->name();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Apps::Script::Type::ScriptManifest::CommonAddOnManifest->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/apps/script/type/script_manifest.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Apps::Script::Type::ScriptManifest::CommonAddOnManifest

Add-on configuration that is shared across all add-on host applications.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. The display name of the add-on.

=item * C<< $msg->logo_url() >> / C<< $msg->logo_url($value) >>

Type: C<String>

Required. The URL for the logo image shown in the add-on toolbar.

=item * C<< $msg->layout_properties() >> / C<< $msg->layout_properties($value) >>

Type: C<Message> (L<Google::Apps::Script::Type::ScriptManifest::LayoutProperties>)

Common layout properties for the add-on cards.

=item * C<< $msg->add_on_widget_set() >> / C<< $msg->add_on_widget_set($value) >>

Type: C<Message> (L<Google::Apps::Script::Type::AddonWidgetSet::AddOnWidgetSet>)

The widgets used in the add-on. If this field is not specified,
it indicates that default set is used.

=item * C<< $msg->use_locale_from_app() >> / C<< $msg->use_locale_from_app($value) >>

Type: C<Bool>

Whether to pass locale information from host app.

=item * C<< $msg->homepage_trigger() >> / C<< $msg->homepage_trigger($value) >>

Type: C<Message> (L<Google::Apps::Script::Type::ExtensionPoint::HomepageExtensionPoint>)

Defines an endpoint that will be executed in any context, in
any host. Any cards generated by this function will always be available to
the user, but may be eclipsed by contextual content when this add-on
declares more targeted triggers.

=item * C<< $msg->universal_actions() >> / C<< $msg->universal_actions($value) >>

Type: C<Message> (L<Google::Apps::Script::Type::ExtensionPoint::UniversalActionExtensionPoint>)

Defines a list of extension points in the universal action menu which
serves as a setting menu for the add-on. The extension point can be
link URL to open or an endpoint to execute as a form
submission.

=item * C<< $msg->open_link_url_prefixes() >> / C<< $msg->open_link_url_prefixes($value) >>

Type: C<Message> (L<Google::Protobuf::Struct::ListValue>)

An OpenLink action
can only use a URL with an HTTPS, MAILTO or TEL scheme.  For HTTPS links,
the URL must also
[match](/gmail/add-ons/concepts/manifests#whitelisting_urls) one of the
prefixes specified in this whitelist. If the prefix omits the scheme, HTTPS
is assumed.  Notice that HTTP links are automatically rewritten to HTTPS
links.

=back

=head2 Google::Apps::Script::Type::ScriptManifest::LayoutProperties

Card layout properties shared across all add-on host applications.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->primary_color() >> / C<< $msg->primary_color($value) >>

Type: C<String>

The primary color of the add-on. It sets the color of toolbar. If no
primary color is set explicitly, the default value provided by the
framework is used.

=item * C<< $msg->secondary_color() >> / C<< $msg->secondary_color($value) >>

Type: C<String>

The secondary color of the add-on. It sets the color of buttons.
If primary color is set but no secondary color is set, the
secondary color is the same as the primary color. If neither primary
color nor secondary color is set, the default value provided by the
framework is used.

=back

=head2 Google::Apps::Script::Type::ScriptManifest::HttpOptions

Options for sending requests to add-on HTTP endpoints

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->authorization_header() >> / C<< $msg->authorization_header($value) >>

Type: C<Enum> (L<Google::Apps::Script::Type::HttpAuthorizationHeader>)

Configuration for the token sent in the HTTP Authorization header

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Apps::Script::Type::ScriptManifest::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
