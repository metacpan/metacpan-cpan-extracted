package Google::Apps::Script::Type::Drive::DriveAddonManifest;

use strict;
use warnings;

our $VERSION = '0.14';

use Protobuf::Message;
use Protobuf::DescriptorPool;
use Protobuf::Internal qw(:all);
use MIME::Base64;

BEGIN {
    eval { require Google::Apps::Script::Type::ExtensionPoint };
    my $descriptor_b64 = <<'EOF';
Cjhnb29nbGUvYXBwcy9zY3JpcHQvdHlwZS9kcml2ZS9kcml2ZV9hZGRvbl9tYW5pZmVzdC5w
cm90bxIdZ29vZ2xlLmFwcHMuc2NyaXB0LnR5cGUuZHJpdmUaLWdvb2dsZS9hcHBzL3Njcmlw
dC90eXBlL2V4dGVuc2lvbl9wb2ludC5wcm90byLfAQoSRHJpdmVBZGRPbk1hbmlmZXN0EloK
EGhvbWVwYWdlX3RyaWdnZXIYASABKAsyLy5nb29nbGUuYXBwcy5zY3JpcHQudHlwZS5Ib21l
cGFnZUV4dGVuc2lvblBvaW50Ug9ob21lcGFnZVRyaWdnZXISbQoZb25faXRlbXNfc2VsZWN0
ZWRfdHJpZ2dlchgCIAEoCzIyLmdvb2dsZS5hcHBzLnNjcmlwdC50eXBlLmRyaXZlLkRyaXZl
RXh0ZW5zaW9uUG9pbnRSFm9uSXRlbXNTZWxlY3RlZFRyaWdnZXIiOAoTRHJpdmVFeHRlbnNp
b25Qb2ludBIhCgxydW5fZnVuY3Rpb24YASABKAlSC3J1bkZ1bmN0aW9uQuABCiFjb20uZ29v
Z2xlLmFwcHMuc2NyaXB0LnR5cGUuZHJpdmVCF0RyaXZlQWRkT25NYW5pZmVzdFByb3RvUAFa
PGdvb2dsZS5nb2xhbmcub3JnL2dlbnByb3RvL2dvb2dsZWFwaXMvYXBwcy9zY3JpcHQvdHlw
ZS9kcml2ZaoCHUdvb2dsZS5BcHBzLlNjcmlwdC5UeXBlLkRyaXZlygIdR29vZ2xlXEFwcHNc
U2NyaXB0XFR5cGVcRHJpdmXqAiFHb29nbGU6OkFwcHM6OlNjcmlwdDo6VHlwZTo6RHJpdmVK
qgsKBhIEDgAvAQq8BAoBDBIDDgASMrEEIENvcHlyaWdodCAyMDI1IEdvb2dsZSBMTEMKCiBM
aWNlbnNlZCB1bmRlciB0aGUgQXBhY2hlIExpY2Vuc2UsIFZlcnNpb24gMi4wICh0aGUgIkxp
Y2Vuc2UiKTsKIHlvdSBtYXkgbm90IHVzZSB0aGlzIGZpbGUgZXhjZXB0IGluIGNvbXBsaWFu
Y2Ugd2l0aCB0aGUgTGljZW5zZS4KIFlvdSBtYXkgb2J0YWluIGEgY29weSBvZiB0aGUgTGlj
ZW5zZSBhdAoKICAgICBodHRwOi8vd3d3LmFwYWNoZS5vcmcvbGljZW5zZXMvTElDRU5TRS0y
LjAKCiBVbmxlc3MgcmVxdWlyZWQgYnkgYXBwbGljYWJsZSBsYXcgb3IgYWdyZWVkIHRvIGlu
IHdyaXRpbmcsIHNvZnR3YXJlCiBkaXN0cmlidXRlZCB1bmRlciB0aGUgTGljZW5zZSBpcyBk
aXN0cmlidXRlZCBvbiBhbiAiQVMgSVMiIEJBU0lTLAogV0lUSE9VVCBXQVJSQU5USUVTIE9S
IENPTkRJVElPTlMgT0YgQU5ZIEtJTkQsIGVpdGhlciBleHByZXNzIG9yIGltcGxpZWQuCiBT
ZWUgdGhlIExpY2Vuc2UgZm9yIHRoZSBzcGVjaWZpYyBsYW5ndWFnZSBnb3Zlcm5pbmcgcGVy
bWlzc2lvbnMgYW5kCiBsaW1pdGF0aW9ucyB1bmRlciB0aGUgTGljZW5zZS4KCggKAQISAxAA
JgoJCgIDABIDEgA3CggKAQgSAxQAOgoJCgIIJRIDFAA6CggKAQgSAxUAUwoJCgIICxIDFQBT
CggKAQgSAxYAIgoJCgIIChIDFgAiCggKAQgSAxcAOAoJCgIICBIDFwA4CggKAQgSAxgAOgoJ
CgIIARIDGAA6CggKAQgSAxkAOwoJCgIIKRIDGQA7CggKAQgSAxoAOgoJCgIILRIDGgA6ClMK
AgQAEgQfACcBGhggRHJpdmUgYWRkLW9uIG1hbmlmZXN0LgoyLSBNYW5pZmVzdCBzZWN0aW9u
IHNwZWNpZmljIHRvIERyaXZlIGFkZC1vbnMuCgoKCgMEAAESAx8IGgpiCgQEAAIAEgMiAkYa
VSBJZiBwcmVzZW50LCB0aGlzIG92ZXJyaWRlcyB0aGUgY29uZmlndXJhdGlvbiBmcm9tCiBg
YWRkT25zLmNvbW1vbi5ob21lcGFnZVRyaWdnZXJgLgoKDAoFBAACAAYSAyICMAoMCgUEAAIA
ARIDIjFBCgwKBQQAAgADEgMiREUKhgEKBAQAAgESAyYCNBp5IENvcnJlc3BvbmRzIHRvIGJl
aHZpb3IgdGhhdCBzaG91bGQgZXhlY3V0ZSB3aGVuIGl0ZW1zIGFyZSBzZWxlY3RlZAogaW4g
cmVsZXZhbnQgRHJpdmUgdmlldyAoZS5nLiB0aGUgTXkgRHJpdmUgRG9jbGlzdCkuCgoMCgUE
AAIBBhIDJgIVCgwKBQQAAgEBEgMmFi8KDAoFBAACAQMSAyYyMwqFAQoCBAESBCsALwEaeSBB
IGdlbmVyaWMgZXh0ZW5zaW9uIHBvaW50IHdpdGggY29tbW9uIGZlYXR1cmVzLCBlLmcuIHNv
bWV0aGluZyB0aGF0IHNpbXBseQogbmVlZHMgYSBjb3JyZXNwb25kaW5nIHJ1biBmdW5jdGlv
biB0byB3b3JrLgoKCgoDBAEBEgMrCBsKWQoEBAECABIDLgIaGkwgUmVxdWlyZWQuIFRoZSBl
bmRwb2ludCB0byBleGVjdXRlIHdoZW4gdGhpcyBleHRlbnNpb24gcG9pbnQgaXMKIGFjdGl2
YXRlZC4KCgwKBQQBAgAFEgMuAggKDAoFBAECAAESAy4JFQoMCgUEAQIAAxIDLhgZYgZwcm90
bzM=
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Apps::Script::Type::Drive::DriveAddonManifest::DriveAddOnManifest ===
    # Fields for DriveAddOnManifest
    # Field: homepage_trigger Type: 11 (.google.apps.script.type.HomepageExtensionPoint)
    # Field: on_items_selected_trigger Type: 11 (.google.apps.script.type.drive.DriveExtensionPoint)

# === Message: Google::Apps::Script::Type::Drive::DriveAddonManifest::DriveExtensionPoint ===
    # Fields for DriveExtensionPoint
    # Field: run_function Type: 9 ()

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Apps::Script::Type::Drive::DriveAddonManifest - Compiled Protocol Buffers messages for google/apps/script/type/drive/drive_addon_manifest.proto

=head1 SYNOPSIS

    use Google::Apps::Script::Type::Drive::DriveAddonManifest;

    my $msg = Google::Apps::Script::Type::Drive::DriveAddonManifest::DriveAddOnManifest->new({
        homepage_trigger => $homepage_trigger,
        on_items_selected_trigger => $on_items_selected_trigger,
    });

    # Read or update a field
    my $val = $msg->homepage_trigger();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Apps::Script::Type::Drive::DriveAddonManifest::DriveAddOnManifest->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/apps/script/type/drive/drive_addon_manifest.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Apps::Script::Type::Drive::DriveAddonManifest::DriveAddOnManifest

Drive add-on manifest.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->homepage_trigger() >> / C<< $msg->homepage_trigger($value) >>

Type: C<Message> (L<Google::Apps::Script::Type::ExtensionPoint::HomepageExtensionPoint>)

If present, this overrides the configuration from
`addOns.common.homepageTrigger`.

=item * C<< $msg->on_items_selected_trigger() >> / C<< $msg->on_items_selected_trigger($value) >>

Type: C<Message> (L<Google::Apps::Script::Type::Drive::DriveAddonManifest::DriveExtensionPoint>)

Corresponds to behvior that should execute when items are selected
in relevant Drive view (e.g. the My Drive Doclist).

=back

=head2 Google::Apps::Script::Type::Drive::DriveAddonManifest::DriveExtensionPoint

A generic extension point with common features, e.g. something that simply
needs a corresponding run function to work.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->run_function() >> / C<< $msg->run_function($value) >>

Type: C<String>

Required. The endpoint to execute when this extension point is
activated.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Apps::Script::Type::Drive::DriveAddonManifest::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
