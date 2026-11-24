package Google::Apps::Script::Type::Sheets::SheetsAddonManifest;

use strict;
use warnings;

our $VERSION = '0.14';

use Protobuf::Message;
use Protobuf::DescriptorPool;
use Protobuf::Internal qw(:all);
use MIME::Base64;

BEGIN {
    eval { require Google::Api::FieldBehavior };
    eval { require Google::Apps::Script::Type::ExtensionPoint };
    my $descriptor_b64 = <<'EOF';
Cjpnb29nbGUvYXBwcy9zY3JpcHQvdHlwZS9zaGVldHMvc2hlZXRzX2FkZG9uX21hbmlmZXN0
LnByb3RvEh5nb29nbGUuYXBwcy5zY3JpcHQudHlwZS5zaGVldHMaH2dvb2dsZS9hcGkvZmll
bGRfYmVoYXZpb3IucHJvdG8aLWdvb2dsZS9hcHBzL3NjcmlwdC90eXBlL2V4dGVuc2lvbl9w
b2ludC5wcm90byLpAQoTU2hlZXRzQWRkT25NYW5pZmVzdBJaChBob21lcGFnZV90cmlnZ2Vy
GAMgASgLMi8uZ29vZ2xlLmFwcHMuc2NyaXB0LnR5cGUuSG9tZXBhZ2VFeHRlbnNpb25Qb2lu
dFIPaG9tZXBhZ2VUcmlnZ2VyEnYKHW9uX2ZpbGVfc2NvcGVfZ3JhbnRlZF90cmlnZ2VyGAUg
ASgLMjQuZ29vZ2xlLmFwcHMuc2NyaXB0LnR5cGUuc2hlZXRzLlNoZWV0c0V4dGVuc2lvblBv
aW50UhlvbkZpbGVTY29wZUdyYW50ZWRUcmlnZ2VyIj4KFFNoZWV0c0V4dGVuc2lvblBvaW50
EiYKDHJ1bl9mdW5jdGlvbhgBIAEoCUID4EECUgtydW5GdW5jdGlvbkLmAQoiY29tLmdvb2ds
ZS5hcHBzLnNjcmlwdC50eXBlLnNoZWV0c0IYU2hlZXRzQWRkT25NYW5pZmVzdFByb3RvUAFa
PWdvb2dsZS5nb2xhbmcub3JnL2dlbnByb3RvL2dvb2dsZWFwaXMvYXBwcy9zY3JpcHQvdHlw
ZS9zaGVldHOqAh5Hb29nbGUuQXBwcy5TY3JpcHQuVHlwZS5TaGVldHPKAh5Hb29nbGVcQXBw
c1xTY3JpcHRcVHlwZVxTaGVldHPqAiJHb29nbGU6OkFwcHM6OlNjcmlwdDo6VHlwZTo6U2hl
ZXRzSvYKCgYSBA4ALgEKvAQKAQwSAw4AEjKxBCBDb3B5cmlnaHQgMjAyNSBHb29nbGUgTExD
CgogTGljZW5zZWQgdW5kZXIgdGhlIEFwYWNoZSBMaWNlbnNlLCBWZXJzaW9uIDIuMCAodGhl
ICJMaWNlbnNlIik7CiB5b3UgbWF5IG5vdCB1c2UgdGhpcyBmaWxlIGV4Y2VwdCBpbiBjb21w
bGlhbmNlIHdpdGggdGhlIExpY2Vuc2UuCiBZb3UgbWF5IG9idGFpbiBhIGNvcHkgb2YgdGhl
IExpY2Vuc2UgYXQKCiAgICAgaHR0cDovL3d3dy5hcGFjaGUub3JnL2xpY2Vuc2VzL0xJQ0VO
U0UtMi4wCgogVW5sZXNzIHJlcXVpcmVkIGJ5IGFwcGxpY2FibGUgbGF3IG9yIGFncmVlZCB0
byBpbiB3cml0aW5nLCBzb2Z0d2FyZQogZGlzdHJpYnV0ZWQgdW5kZXIgdGhlIExpY2Vuc2Ug
aXMgZGlzdHJpYnV0ZWQgb24gYW4gIkFTIElTIiBCQVNJUywKIFdJVEhPVVQgV0FSUkFOVElF
UyBPUiBDT05ESVRJT05TIE9GIEFOWSBLSU5ELCBlaXRoZXIgZXhwcmVzcyBvciBpbXBsaWVk
LgogU2VlIHRoZSBMaWNlbnNlIGZvciB0aGUgc3BlY2lmaWMgbGFuZ3VhZ2UgZ292ZXJuaW5n
IHBlcm1pc3Npb25zIGFuZAogbGltaXRhdGlvbnMgdW5kZXIgdGhlIExpY2Vuc2UuCgoICgEC
EgMQACcKCQoCAwASAxIAKQoJCgIDARIDEwA3CggKAQgSAxUAOwoJCgIIJRIDFQA7CggKAQgS
AxYAVAoJCgIICxIDFgBUCggKAQgSAxcAIgoJCgIIChIDFwAiCggKAQgSAxgAOQoJCgIICBID
GAA5CggKAQgSAxkAOwoJCgIIARIDGQA7CggKAQgSAxoAPAoJCgIIKRIDGgA8CggKAQgSAxsA
OwoJCgIILRIDGwA7ClUKAgQAEgQgACgBGhkgU2hlZXRzIGFkZC1vbiBtYW5pZmVzdC4KMi4g
TWFuaWZlc3Qgc2VjdGlvbiBzcGVjaWZpYyB0byBTaGVldHMgYWRkLW9ucy4KCgoKAwQAARID
IAgbCmIKBAQAAgASAyMCRhpVIElmIHByZXNlbnQsIHRoaXMgb3ZlcnJpZGVzIHRoZSBjb25m
aWd1cmF0aW9uIGZyb20KIGBhZGRPbnMuY29tbW9uLmhvbWVwYWdlVHJpZ2dlcmAuCgoMCgUE
AAIABhIDIwIwCgwKBQQAAgABEgMjMUEKDAoFBAACAAMSAyNERQppCgQEAAIBEgMnAjkaXCBF
bmRwb2ludCB0byBleGVjdXRlIHdoZW4gZmlsZSBzY29wZSBhdXRob3JpemF0aW9uIGlzIGdy
YW50ZWQKIGZvciB0aGlzIGRvY3VtZW50L3VzZXIgcGFpci4KCgwKBQQAAgEGEgMnAhYKDAoF
BAACAQESAycXNAoMCgUEAAIBAxIDJzc4CkUKAgQBEgQrAC4BGjkgQ29tbW9uIGZvcm1hdCBm
b3IgZGVjbGFyaW5nIGEgU2hlZXRzIGFkZC1vbidzIHRyaWdnZXJzLgoKCgoDBAEBEgMrCBwK
WAoEBAECABIDLQJDGksgUmVxdWlyZWQuIFRoZSBlbmRwb2ludCB0byBleGVjdXRlIHdoZW4g
dGhpcyBleHRlbnNpb24gcG9pbnQgaXMgYWN0aXZhdGVkLgoKDAoFBAECAAUSAy0CCAoMCgUE
AQIAARIDLQkVCgwKBQQBAgADEgMtGBkKDAoFBAECAAgSAy0aQgoPCggEAQIACJwIABIDLRtB
YgZwcm90bzM=
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Apps::Script::Type::Sheets::SheetsAddonManifest::SheetsAddOnManifest ===
    # Fields for SheetsAddOnManifest
    # Field: homepage_trigger Type: 11 (.google.apps.script.type.HomepageExtensionPoint)
    # Field: on_file_scope_granted_trigger Type: 11 (.google.apps.script.type.sheets.SheetsExtensionPoint)

# === Message: Google::Apps::Script::Type::Sheets::SheetsAddonManifest::SheetsExtensionPoint ===
    # Fields for SheetsExtensionPoint
    # Field: run_function Type: 9 ()

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Apps::Script::Type::Sheets::SheetsAddonManifest - Compiled Protocol Buffers messages for google/apps/script/type/sheets/sheets_addon_manifest.proto

=head1 SYNOPSIS

    use Google::Apps::Script::Type::Sheets::SheetsAddonManifest;

    my $msg = Google::Apps::Script::Type::Sheets::SheetsAddonManifest::SheetsAddOnManifest->new({
        homepage_trigger => $homepage_trigger,
        on_file_scope_granted_trigger => $on_file_scope_granted_trigger,
    });

    # Read or update a field
    my $val = $msg->homepage_trigger();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Apps::Script::Type::Sheets::SheetsAddonManifest::SheetsAddOnManifest->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/apps/script/type/sheets/sheets_addon_manifest.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Apps::Script::Type::Sheets::SheetsAddonManifest::SheetsAddOnManifest

Sheets add-on manifest.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->homepage_trigger() >> / C<< $msg->homepage_trigger($value) >>

Type: C<Message> (L<Google::Apps::Script::Type::ExtensionPoint::HomepageExtensionPoint>)

If present, this overrides the configuration from
`addOns.common.homepageTrigger`.

=item * C<< $msg->on_file_scope_granted_trigger() >> / C<< $msg->on_file_scope_granted_trigger($value) >>

Type: C<Message> (L<Google::Apps::Script::Type::Sheets::SheetsAddonManifest::SheetsExtensionPoint>)

Endpoint to execute when file scope authorization is granted
for this document/user pair.

=back

=head2 Google::Apps::Script::Type::Sheets::SheetsAddonManifest::SheetsExtensionPoint

Common format for declaring a Sheets add-on's triggers.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->run_function() >> / C<< $msg->run_function($value) >>

Type: C<String>

Required. The endpoint to execute when this extension point is activated.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Apps::Script::Type::Sheets::SheetsAddonManifest::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
