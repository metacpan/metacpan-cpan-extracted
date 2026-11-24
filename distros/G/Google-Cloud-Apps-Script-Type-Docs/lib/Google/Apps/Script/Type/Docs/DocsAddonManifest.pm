package Google::Apps::Script::Type::Docs::DocsAddonManifest;

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
CjZnb29nbGUvYXBwcy9zY3JpcHQvdHlwZS9kb2NzL2RvY3NfYWRkb25fbWFuaWZlc3QucHJv
dG8SHGdvb2dsZS5hcHBzLnNjcmlwdC50eXBlLmRvY3MaH2dvb2dsZS9hcGkvZmllbGRfYmVo
YXZpb3IucHJvdG8aLWdvb2dsZS9hcHBzL3NjcmlwdC90eXBlL2V4dGVuc2lvbl9wb2ludC5w
cm90byLjAQoRRG9jc0FkZE9uTWFuaWZlc3QSWgoQaG9tZXBhZ2VfdHJpZ2dlchgBIAEoCzIv
Lmdvb2dsZS5hcHBzLnNjcmlwdC50eXBlLkhvbWVwYWdlRXh0ZW5zaW9uUG9pbnRSD2hvbWVw
YWdlVHJpZ2dlchJyCh1vbl9maWxlX3Njb3BlX2dyYW50ZWRfdHJpZ2dlchgCIAEoCzIwLmdv
b2dsZS5hcHBzLnNjcmlwdC50eXBlLmRvY3MuRG9jc0V4dGVuc2lvblBvaW50UhlvbkZpbGVT
Y29wZUdyYW50ZWRUcmlnZ2VyIjwKEkRvY3NFeHRlbnNpb25Qb2ludBImCgxydW5fZnVuY3Rp
b24YASABKAlCA+BBAlILcnVuRnVuY3Rpb25C2gEKIGNvbS5nb29nbGUuYXBwcy5zY3JpcHQu
dHlwZS5kb2NzQhZEb2NzQWRkT25NYW5pZmVzdFByb3RvUAFaO2dvb2dsZS5nb2xhbmcub3Jn
L2dlbnByb3RvL2dvb2dsZWFwaXMvYXBwcy9zY3JpcHQvdHlwZS9kb2NzqgIcR29vZ2xlLkFw
cHMuU2NyaXB0LlR5cGUuRG9jc8oCHEdvb2dsZVxBcHBzXFNjcmlwdFxUeXBlXERvY3PqAiBH
b29nbGU6OkFwcHM6OlNjcmlwdDo6VHlwZTo6RG9jc0rwCgoGEgQOAC4BCrwECgEMEgMOABIy
sQQgQ29weXJpZ2h0IDIwMjUgR29vZ2xlIExMQwoKIExpY2Vuc2VkIHVuZGVyIHRoZSBBcGFj
aGUgTGljZW5zZSwgVmVyc2lvbiAyLjAgKHRoZSAiTGljZW5zZSIpOwogeW91IG1heSBub3Qg
dXNlIHRoaXMgZmlsZSBleGNlcHQgaW4gY29tcGxpYW5jZSB3aXRoIHRoZSBMaWNlbnNlLgog
WW91IG1heSBvYnRhaW4gYSBjb3B5IG9mIHRoZSBMaWNlbnNlIGF0CgogICAgIGh0dHA6Ly93
d3cuYXBhY2hlLm9yZy9saWNlbnNlcy9MSUNFTlNFLTIuMAoKIFVubGVzcyByZXF1aXJlZCBi
eSBhcHBsaWNhYmxlIGxhdyBvciBhZ3JlZWQgdG8gaW4gd3JpdGluZywgc29mdHdhcmUKIGRp
c3RyaWJ1dGVkIHVuZGVyIHRoZSBMaWNlbnNlIGlzIGRpc3RyaWJ1dGVkIG9uIGFuICJBUyBJ
UyIgQkFTSVMsCiBXSVRIT1VUIFdBUlJBTlRJRVMgT1IgQ09ORElUSU9OUyBPRiBBTlkgS0lO
RCwgZWl0aGVyIGV4cHJlc3Mgb3IgaW1wbGllZC4KIFNlZSB0aGUgTGljZW5zZSBmb3IgdGhl
IHNwZWNpZmljIGxhbmd1YWdlIGdvdmVybmluZyBwZXJtaXNzaW9ucyBhbmQKIGxpbWl0YXRp
b25zIHVuZGVyIHRoZSBMaWNlbnNlLgoKCAoBAhIDEAAlCgkKAgMAEgMSACkKCQoCAwESAxMA
NwoICgEIEgMVADkKCQoCCCUSAxUAOQoICgEIEgMWAFIKCQoCCAsSAxYAUgoICgEIEgMXACIK
CQoCCAoSAxcAIgoICgEIEgMYADcKCQoCCAgSAxgANwoICgEIEgMZADkKCQoCCAESAxkAOQoI
CgEIEgMaADoKCQoCCCkSAxoAOgoICgEIEgMbADkKCQoCCC0SAxsAOQpRCgIEABIEIAAoARoX
IERvY3MgYWRkLW9uIG1hbmlmZXN0LgoyLCBNYW5pZmVzdCBzZWN0aW9uIHNwZWNpZmljIHRv
IERvY3MgYWRkLW9ucy4KCgoKAwQAARIDIAgZCmIKBAQAAgASAyMCRhpVIElmIHByZXNlbnQs
IHRoaXMgb3ZlcnJpZGVzIHRoZSBjb25maWd1cmF0aW9uIGZyb20KIGBhZGRPbnMuY29tbW9u
LmhvbWVwYWdlVHJpZ2dlcmAuCgoMCgUEAAIABhIDIwIwCgwKBQQAAgABEgMjMUEKDAoFBAAC
AAMSAyNERQppCgQEAAIBEgMnAjcaXCBFbmRwb2ludCB0byBleGVjdXRlIHdoZW4gZmlsZSBz
Y29wZSBhdXRob3JpemF0aW9uIGlzIGdyYW50ZWQKIGZvciB0aGlzIGRvY3VtZW50L3VzZXIg
cGFpci4KCgwKBQQAAgEGEgMnAhQKDAoFBAACAQESAycVMgoMCgUEAAIBAxIDJzU2CkMKAgQB
EgQrAC4BGjcgQ29tbW9uIGZvcm1hdCBmb3IgZGVjbGFyaW5nIGEgRG9jcyBhZGQtb24ncyB0
cmlnZ2Vycy4KCgoKAwQBARIDKwgaClgKBAQBAgASAy0CQxpLIFJlcXVpcmVkLiBUaGUgZW5k
cG9pbnQgdG8gZXhlY3V0ZSB3aGVuIHRoaXMgZXh0ZW5zaW9uIHBvaW50IGlzIGFjdGl2YXRl
ZC4KCgwKBQQBAgAFEgMtAggKDAoFBAECAAESAy0JFQoMCgUEAQIAAxIDLRgZCgwKBQQBAgAI
EgMtGkIKDwoIBAECAAicCAASAy0bQWIGcHJvdG8z
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Apps::Script::Type::Docs::DocsAddonManifest::DocsAddOnManifest ===
    # Fields for DocsAddOnManifest
    # Field: homepage_trigger Type: 11 (.google.apps.script.type.HomepageExtensionPoint)
    # Field: on_file_scope_granted_trigger Type: 11 (.google.apps.script.type.docs.DocsExtensionPoint)

# === Message: Google::Apps::Script::Type::Docs::DocsAddonManifest::DocsExtensionPoint ===
    # Fields for DocsExtensionPoint
    # Field: run_function Type: 9 ()

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Apps::Script::Type::Docs::DocsAddonManifest - Compiled Protocol Buffers messages for google/apps/script/type/docs/docs_addon_manifest.proto

=head1 SYNOPSIS

    use Google::Apps::Script::Type::Docs::DocsAddonManifest;

    my $msg = Google::Apps::Script::Type::Docs::DocsAddonManifest::DocsAddOnManifest->new({
        homepage_trigger => $homepage_trigger,
        on_file_scope_granted_trigger => $on_file_scope_granted_trigger,
    });

    # Read or update a field
    my $val = $msg->homepage_trigger();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Apps::Script::Type::Docs::DocsAddonManifest::DocsAddOnManifest->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/apps/script/type/docs/docs_addon_manifest.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Apps::Script::Type::Docs::DocsAddonManifest::DocsAddOnManifest

Docs add-on manifest.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->homepage_trigger() >> / C<< $msg->homepage_trigger($value) >>

Type: C<Message> (L<Google::Apps::Script::Type::ExtensionPoint::HomepageExtensionPoint>)

If present, this overrides the configuration from
`addOns.common.homepageTrigger`.

=item * C<< $msg->on_file_scope_granted_trigger() >> / C<< $msg->on_file_scope_granted_trigger($value) >>

Type: C<Message> (L<Google::Apps::Script::Type::Docs::DocsAddonManifest::DocsExtensionPoint>)

Endpoint to execute when file scope authorization is granted
for this document/user pair.

=back

=head2 Google::Apps::Script::Type::Docs::DocsAddonManifest::DocsExtensionPoint

Common format for declaring a Docs add-on's triggers.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->run_function() >> / C<< $msg->run_function($value) >>

Type: C<String>

Required. The endpoint to execute when this extension point is activated.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Apps::Script::Type::Docs::DocsAddonManifest::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
