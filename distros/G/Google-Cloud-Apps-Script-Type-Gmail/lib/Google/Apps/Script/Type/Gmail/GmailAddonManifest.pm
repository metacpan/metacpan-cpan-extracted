package Google::Apps::Script::Type::Gmail::GmailAddonManifest;

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
    my $descriptor_b64 = <<'EOF';
Cjhnb29nbGUvYXBwcy9zY3JpcHQvdHlwZS9nbWFpbC9nbWFpbF9hZGRvbl9tYW5pZmVzdC5w
cm90bxIdZ29vZ2xlLmFwcHMuc2NyaXB0LnR5cGUuZ21haWwaLmdvb2dsZS9hcHBzL3Njcmlw
dC90eXBlL2FkZG9uX3dpZGdldF9zZXQucHJvdG8aLWdvb2dsZS9hcHBzL3NjcmlwdC90eXBl
L2V4dGVuc2lvbl9wb2ludC5wcm90byLKAwoSR21haWxBZGRPbk1hbmlmZXN0EloKEGhvbWVw
YWdlX3RyaWdnZXIYDiABKAsyLy5nb29nbGUuYXBwcy5zY3JpcHQudHlwZS5Ib21lcGFnZUV4
dGVuc2lvblBvaW50Ug9ob21lcGFnZVRyaWdnZXISYQoTY29udGV4dHVhbF90cmlnZ2VycxgD
IAMoCzIwLmdvb2dsZS5hcHBzLnNjcmlwdC50eXBlLmdtYWlsLkNvbnRleHR1YWxUcmlnZ2Vy
UhJjb250ZXh0dWFsVHJpZ2dlcnMSWwoRdW5pdmVyc2FsX2FjdGlvbnMYBCADKAsyLi5nb29n
bGUuYXBwcy5zY3JpcHQudHlwZS5nbWFpbC5Vbml2ZXJzYWxBY3Rpb25SEHVuaXZlcnNhbEFj
dGlvbnMSVgoPY29tcG9zZV90cmlnZ2VyGAwgASgLMi0uZ29vZ2xlLmFwcHMuc2NyaXB0LnR5
cGUuZ21haWwuQ29tcG9zZVRyaWdnZXJSDmNvbXBvc2VUcmlnZ2VyEkAKHGF1dGhvcml6YXRp
b25fY2hlY2tfZnVuY3Rpb24YByABKAlSGmF1dGhvcml6YXRpb25DaGVja0Z1bmN0aW9uIngK
D1VuaXZlcnNhbEFjdGlvbhISCgR0ZXh0GAEgASgJUgR0ZXh0Eh0KCW9wZW5fbGluaxgCIAEo
CUgAUghvcGVuTGluaxIjCgxydW5fZnVuY3Rpb24YAyABKAlIAFILcnVuRnVuY3Rpb25CDQoL
YWN0aW9uX3R5cGUi8QEKDkNvbXBvc2VUcmlnZ2VyEkkKB2FjdGlvbnMYBSADKAsyLy5nb29n
bGUuYXBwcy5zY3JpcHQudHlwZS5NZW51SXRlbUV4dGVuc2lvblBvaW50UgdhY3Rpb25zElwK
DGRyYWZ0X2FjY2VzcxgEIAEoDjI5Lmdvb2dsZS5hcHBzLnNjcmlwdC50eXBlLmdtYWlsLkNv
bXBvc2VUcmlnZ2VyLkRyYWZ0QWNjZXNzUgtkcmFmdEFjY2VzcyI2CgtEcmFmdEFjY2VzcxIP
CgtVTlNQRUNJRklFRBAAEggKBE5PTkUQARIMCghNRVRBREFUQRACIqsBChFDb250ZXh0dWFs
VHJpZ2dlchJbCg11bmNvbmRpdGlvbmFsGAEgASgLMjMuZ29vZ2xlLmFwcHMuc2NyaXB0LnR5
cGUuZ21haWwuVW5jb25kaXRpb25hbFRyaWdnZXJIAFINdW5jb25kaXRpb25hbBIuChNvbl90
cmlnZ2VyX2Z1bmN0aW9uGAQgASgJUhFvblRyaWdnZXJGdW5jdGlvbkIJCgd0cmlnZ2VyIhYK
FFVuY29uZGl0aW9uYWxUcmlnZ2VyQuABCiFjb20uZ29vZ2xlLmFwcHMuc2NyaXB0LnR5cGUu
Z21haWxCF0dtYWlsQWRkT25NYW5pZmVzdFByb3RvUAFaPGdvb2dsZS5nb2xhbmcub3JnL2dl
bnByb3RvL2dvb2dsZWFwaXMvYXBwcy9zY3JpcHQvdHlwZS9nbWFpbKoCHUdvb2dsZS5BcHBz
LlNjcmlwdC5UeXBlLkdtYWlsygIdR29vZ2xlXEFwcHNcU2NyaXB0XFR5cGVcR21haWzqAiFH
b29nbGU6OkFwcHM6OlNjcmlwdDo6VHlwZTo6R21haWxKvSUKBhIEDgB+Hwq8BAoBDBIDDgAS
MrEEIENvcHlyaWdodCAyMDI1IEdvb2dsZSBMTEMKCiBMaWNlbnNlZCB1bmRlciB0aGUgQXBh
Y2hlIExpY2Vuc2UsIFZlcnNpb24gMi4wICh0aGUgIkxpY2Vuc2UiKTsKIHlvdSBtYXkgbm90
IHVzZSB0aGlzIGZpbGUgZXhjZXB0IGluIGNvbXBsaWFuY2Ugd2l0aCB0aGUgTGljZW5zZS4K
IFlvdSBtYXkgb2J0YWluIGEgY29weSBvZiB0aGUgTGljZW5zZSBhdAoKICAgICBodHRwOi8v
d3d3LmFwYWNoZS5vcmcvbGljZW5zZXMvTElDRU5TRS0yLjAKCiBVbmxlc3MgcmVxdWlyZWQg
YnkgYXBwbGljYWJsZSBsYXcgb3IgYWdyZWVkIHRvIGluIHdyaXRpbmcsIHNvZnR3YXJlCiBk
aXN0cmlidXRlZCB1bmRlciB0aGUgTGljZW5zZSBpcyBkaXN0cmlidXRlZCBvbiBhbiAiQVMg
SVMiIEJBU0lTLAogV0lUSE9VVCBXQVJSQU5USUVTIE9SIENPTkRJVElPTlMgT0YgQU5ZIEtJ
TkQsIGVpdGhlciBleHByZXNzIG9yIGltcGxpZWQuCiBTZWUgdGhlIExpY2Vuc2UgZm9yIHRo
ZSBzcGVjaWZpYyBsYW5ndWFnZSBnb3Zlcm5pbmcgcGVybWlzc2lvbnMgYW5kCiBsaW1pdGF0
aW9ucyB1bmRlciB0aGUgTGljZW5zZS4KCggKAQISAxAAJgoJCgIDABIDEgA4CgkKAgMBEgMT
ADcKCAoBCBIDFQA6CgkKAgglEgMVADoKCAoBCBIDFgBTCgkKAggLEgMWAFMKCAoBCBIDFwAi
CgkKAggKEgMXACIKCAoBCBIDGAA4CgkKAggIEgMYADgKCAoBCBIDGQA6CgkKAggBEgMZADoK
CAoBCBIDGgA7CgkKAggpEgMaADsKCAoBCBIDGwA6CgkKAggtEgMbADoKVAoCBAASBB4APgEa
SCBQcm9wZXJ0aWVzIGN1c3RvbWl6aW5nIHRoZSBhcHBlYXJhbmNlIGFuZCBleGVjdXRpb24g
b2YgYSBHbWFpbCBhZGQtb24uCgoKCgMEAAESAx4IGgr1AgoEBAACABIDJgJHGucCIERlZmlu
ZXMgYW4gZW5kcG9pbnQgdGhhdCB3aWxsIGJlIGV4ZWN1dGVkIGluIGNvbnRleHRzIHRoYXQg
ZG9uJ3QKIG1hdGNoIGEgZGVjbGFyZWQgY29udGV4dHVhbCB0cmlnZ2VyLiBBbnkgY2FyZHMg
Z2VuZXJhdGVkIGJ5IHRoaXMgZnVuY3Rpb24KIHdpbGwgYWx3YXlzIGJlIGF2YWlsYWJsZSB0
byB0aGUgdXNlciwgYnV0IG1heSBiZSBlY2xpcHNlZCBieSBjb250ZXh0dWFsCiBjb250ZW50
IHdoZW4gdGhpcyBhZGQtb24gZGVjbGFyZXMgbW9yZSB0YXJnZXRlZCB0cmlnZ2Vycy4KCiBJ
ZiBwcmVzZW50LCB0aGlzIG92ZXJyaWRlcyB0aGUgY29uZmlndXJhdGlvbiBmcm9tCiBgYWRk
T25zLmNvbW1vbi5ob21lcGFnZVRyaWdnZXJgLgoKDAoFBAACAAYSAyYCMAoMCgUEAAIAARID
JjFBCgwKBQQAAgADEgMmREYKRQoEBAACARIDKQI1GjggRGVmaW5lcyB0aGUgc2V0IG9mIGNv
bmRpdGlvbnMgdGhhdCB0cmlnZ2VyIHRoZSBhZGQtb24uCgoMCgUEAAIBBBIDKQIKCgwKBQQA
AgEGEgMpCxwKDAoFBAACAQESAykdMAoMCgUEAAIBAxIDKTM0CrABCgQEAAICEgMuAjEaogEg
RGVmaW5lcyBzZXQgb2YgW3VuaXZlcnNhbAogYWN0aW9uc10oL2dtYWlsL2FkZC1vbnMvaG93
LXRvcy91bml2ZXJzYWwtYWN0aW9ucykgZm9yIHRoZSBhZGQtb24uIFRoZSB1c2VyCiB0cmln
Z2VycyB1bml2ZXJzYWwgYWN0aW9ucyBmcm9tIHRoZSBhZGQtb24gdG9vbGJhciBtZW51LgoK
DAoFBAACAgQSAy4CCgoMCgUEAAICBhIDLgsaCgwKBQQAAgIBEgMuGywKDAoFBAACAgMSAy4v
MAqyAgoEBAACAxIDNgImGqQCIERlZmluZXMgdGhlIGNvbXBvc2UgdGltZSB0cmlnZ2VyIGZv
ciBhIGNvbXBvc2UgdGltZSBhZGQtb24uIFRoaXMgaXMgdGhlCiB0cmlnZ2VyIHRoYXQgY2F1
c2VzIGFuIGFkZC1vbiB0byB0YWtlIGFjdGlvbiB3aGVuIHRoZSB1c2VyIGlzIGNvbXBvc2lu
ZyBhbgogZW1haWwuCiBBbGwgY29tcG9zZSB0aW1lIGFkZG9ucyBhcmUgcmVxdWlyZWQgdG8g
aGF2ZSB0aGUKIGdtYWlsLmFkZG9ucy5jdXJyZW50LmFjdGlvbi5jb21wb3NlIHNjb3BlIGV2
ZW4gdGhvdWdoIGl0IG1pZ2h0IG5vdCBlZGl0IHRoZQogZHJhZnQuCgoMCgUEAAIDBhIDNgIQ
CgwKBQQAAgMBEgM2ESAKDAoFBAACAwMSAzYjJQrlAgoEBAACBBIDPQIqGtcCIFRoZSBuYW1l
IG9mIGFuIGVuZHBvaW50IHRoYXQgdmVyaWZpZXMgdGhhdCB0aGUgYWRkLW9uIGhhcwogYWxs
IHRoZSByZXF1aXJlZCB0aGlyZC1wYXJ0eSBhdXRob3JpemF0aW9ucywgYnkgcHJvYmluZyB0
aGUgdGhpcmQtcGFydHkKIEFQSXMuIElmIHRoZSBwcm9iZSBmYWlscywgdGhlIGZ1bmN0aW9u
IHNob3VsZCB0aHJvdyBhbiBleGNlcHRpb24gdG8KIGluaXRpYXRlIHRoZSBhdXRob3JpemF0
aW9uIGZsb3cuIFRoaXMgZnVuY3Rpb24gaXMgY2FsbGVkIGJlZm9yZSBlYWNoCiBpbnZvY2F0
aW9uIG9mIHRoZSBhZGQtb24sIGluIG9yZGVyIHRvIGVuc3VyZSBhIHNtb290aCB1c2VyIGV4
cGVyaWVuY2UuCgoMCgUEAAIEBRIDPQIICgwKBQQAAgQBEgM9CSUKDAoFBAACBAMSAz0oKQpr
CgIEARIEQgBSARpfIEFuIGFjdGlvbiB0aGF0IGlzIGFsd2F5cyBhdmFpbGFibGUgaW4gdGhl
IGFkZC1vbiB0b29sYmFyIG1lbnUgcmVnYXJkbGVzcyBvZgogbWVzc2FnZSBjb250ZXh0LgoK
CgoDBAEBEgNCCBcKZAoEBAECABIDRQISGlcgUmVxdWlyZWQuIFVzZXItdmlzaWJsZSB0ZXh0
IGRlc2NyaWJpbmcgdGhlIGFjdGlvbiwgZm9yIGV4YW1wbGUsICJBZGQgYSBuZXcKIGNvbnRh
Y3QuIgoKDAoFBAECAAUSA0UCCAoMCgUEAQIAARIDRQkNCgwKBQQBAgADEgNFEBEKagoEBAEI
ABIESQJRAxpcIFRoZSB0eXBlIG9mIHRoZSBhY3Rpb24gZGV0ZXJtaW5lcyB0aGUgYmVoYXZp
b3Igb2YgR21haWwgd2hlbiB0aGUgdXNlcgogaW52b2tlcyB0aGUgYWN0aW9uLgoKDAoFBAEI
AAESA0kIEwpQCgQEAQIBEgNLBBkaQyBBIGxpbmsgdGhhdCBpcyBvcGVuZWQgYnkgR21haWwg
d2hlbiB0aGUgdXNlciB0cmlnZ2VycyB0aGUgYWN0aW9uLgoKDAoFBAECAQUSA0sECgoMCgUE
AQIBARIDSwsUCgwKBQQBAgEDEgNLFxgKqAEKBAQBAgISA1AEHBqaASBBbiBlbmRwb2ludCB0
aGF0IGlzIGNhbGxlZCB3aGVuIHRoZSB1c2VyIHRyaWdnZXJzIHRoZQogYWN0aW9uLiBTZWUg
dGhlIFt1bml2ZXJzYWwgYWN0aW9ucwogZ3VpZGVdKC9nbWFpbC9hZGQtb25zL2hvdy10b3Mv
dW5pdmVyc2FsLWFjdGlvbnMpIGZvciBkZXRhaWxzLgoKDAoFBAECAgUSA1AECgoMCgUEAQIC
ARIDUAsXCgwKBQQBAgIDEgNQGhsKRwoCBAISBFUAawEaOyBBIHRyaWdnZXIgdGhhdCBhY3Rp
dmF0ZXMgd2hlbiB1c2VyIGlzIGNvbXBvc2luZyBhbiBlbWFpbC4KCgoKAwQCARIDVQgWClgK
BAQCBAASBFcCYwMaSiBBbiBlbnVtIGRlZmluaW5nIHRoZSBsZXZlbCBvZiBkYXRhIGFjY2Vz
cyB0aGlzIGNvbXBvc2UgdHJpZ2dlciByZXF1aXJlcy4KCgwKBQQCBAABEgNXBxIKQwoGBAIE
AAIAEgNZBBQaNCBEZWZhdWx0IHZhbHVlIHdoZW4gbm90aGluZyBpcyBzZXQgZm9yIERyYWZ0
QWNjZXNzLgoKDgoHBAIEAAIAARIDWQQPCg4KBwQCBAACAAISA1kSEwp9CgYEAgQAAgESA10E
DRpuIE5PTkUgbWVhbnMgY29tcG9zZSB0cmlnZ2VyIHdvbid0IGJlIGFibGUgdG8gYWNjZXNz
IGFueSBkYXRhIG9mIHRoZSBkcmFmdAogd2hlbiBhIGNvbXBvc2UgYWRkb24gaXMgdHJpZ2dl
cmVkLgoKDgoHBAIEAAIBARIDXQQICg4KBwQCBAACAQISA10LDArJAQoGBAIEAAICEgNiBBEa
uQEgTUVUQURBVEEgZ2l2ZXMgY29tcG9zZSB0cmlnZ2VyIHRoZSBwZXJtaXNzaW9uIHRvIGFj
Y2VzcyB0aGUgbWV0YWRhdGEgb2YKIHRoZSBkcmFmdCB3aGVuIGEgY29tcG9zZSBhZGRvbiBp
cyB0cmlnZ2VyZWQuIFRoaXMgaW5jbHVkZXMgdGhlIGF1ZGllbmNlCiBsaXN0IChUby9jYyBs
aXN0KSBvZiBhIGRyYWZ0IG1lc3NhZ2UuCgoOCgcEAgQAAgIBEgNiBAwKDgoHBAIEAAICAhID
Yg8QCoQBCgQEAgIAEgNnAkYadyBEZWZpbmVzIHRoZSBzZXQgb2YgYWN0aW9ucyBmb3IgY29t
cG9zZSB0aW1lIGFkZC1vbi4gVGhlc2UgYXJlIGFjdGlvbnMKIHRoYXQgdXNlciBjYW4gdHJp
Z2dlciBvbiBhIGNvbXBvc2UgdGltZSBhZGRvbi4KCgwKBQQCAgAEEgNnAgoKDAoFBAICAAYS
A2cLOQoMCgUEAgIAARIDZzpBCgwKBQQCAgADEgNnREUKVgoEBAICARIDagIfGkkgRGVmaW5l
IHRoZSBsZXZlbCBvZiBkYXRhIGFjY2VzcyB3aGVuIGEgY29tcG9zZSB0aW1lIGFkZG9uIGlz
IHRyaWdnZXJlZC4KCgwKBQQCAgEGEgNqAg0KDAoFBAICAQESA2oOGgoMCgUEAgIBAxIDah0e
Cs0BCgIEAxIEcAB7ARrAASBEZWZpbmVzIGEgdHJpZ2dlciB0aGF0IGZpcmVzIHdoZW4gdGhl
IG9wZW4gZW1haWwgbWVldHMgYSBzcGVjaWZpYyBjcml0ZXJpYS4KIFdoZW4gdGhlIHRyaWdn
ZXIgZmlyZXMsIGl0IGV4ZWN1dGVzIGEgc3BlY2lmaWMgZW5kcG9pbnQsIHVzdWFsbHkKIGlu
IG9yZGVyIHRvIGNyZWF0ZSBuZXcgY2FyZHMgYW5kIHVwZGF0ZSB0aGUgVUkuCgoKCgMEAwES
A3AIGQpdCgQEAwgAEgRzAnYDGk8gVGhlIHR5cGUgb2YgdHJpZ2dlciBkZXRlcm1pbmVzIHRo
ZSBjb25kaXRpb25zIEdtYWlsIHVzZXMgdG8gc2hvdyB0aGUKIGFkZC1vbi4KCgwKBQQDCAAB
EgNzCA8KUgoEBAMCABIDdQQrGkUgVW5jb25kaXRpb25hbFRyaWdnZXJzIGFyZSBleGVjdXRl
ZCB3aGVuIGFueSBtYWlsIG1lc3NhZ2UgaXMgb3BlbmVkLgoKDAoFBAMCAAYSA3UEGAoMCgUE
AwIAARIDdRkmCgwKBQQDAgADEgN1KSoKXgoEBAMCARIDegIhGlEgUmVxdWlyZWQuIFRoZSBu
YW1lIG9mIHRoZSBlbmRwb2ludCB0byBjYWxsIHdoZW4gYSBtZXNzYWdlIG1hdGNoZXMgdGhl
CiB0cmlnZ2VyLgoKDAoFBAMCAQUSA3oCCAoMCgUEAwIBARIDegkcCgwKBQQDAgEDEgN6HyAK
QwoCBAQSA34AHxo4IEEgdHJpZ2dlciB0aGF0IGZpcmVzIHdoZW4gYW55IGVtYWlsIG1lc3Nh
Z2UgaXMgb3BlbmVkLgoKCgoDBAQBEgN+CBxiBnByb3RvMw==
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Apps::Script::Type::Gmail::GmailAddonManifest::GmailAddOnManifest ===
    # Fields for GmailAddOnManifest
    # Field: homepage_trigger Type: 11 (.google.apps.script.type.HomepageExtensionPoint)
    # Field: contextual_triggers Type: 11 (.google.apps.script.type.gmail.ContextualTrigger)
    # Field: universal_actions Type: 11 (.google.apps.script.type.gmail.UniversalAction)
    # Field: compose_trigger Type: 11 (.google.apps.script.type.gmail.ComposeTrigger)
    # Field: authorization_check_function Type: 9 ()

# === Message: Google::Apps::Script::Type::Gmail::GmailAddonManifest::UniversalAction ===
    # Fields for UniversalAction
    # Field: text Type: 9 ()
    # Field: open_link Type: 9 ()
    # Field: run_function Type: 9 ()

# === Message: Google::Apps::Script::Type::Gmail::GmailAddonManifest::ComposeTrigger ===
    # Fields for ComposeTrigger
    # Field: actions Type: 11 (.google.apps.script.type.MenuItemExtensionPoint)
    # Field: draft_access Type: 14 (.google.apps.script.type.gmail.ComposeTrigger.DraftAccess)

# Enum: ComposeTrigger::DraftAccess
our $ComposeTrigger_UNSPECIFIED = 0;
our $ComposeTrigger_NONE = 1;
our $ComposeTrigger_METADATA = 2;

# === Message: Google::Apps::Script::Type::Gmail::GmailAddonManifest::ContextualTrigger ===
    # Fields for ContextualTrigger
    # Field: unconditional Type: 11 (.google.apps.script.type.gmail.UnconditionalTrigger)
    # Field: on_trigger_function Type: 9 ()

# === Message: Google::Apps::Script::Type::Gmail::GmailAddonManifest::UnconditionalTrigger ===
    # Fields for UnconditionalTrigger

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Apps::Script::Type::Gmail::GmailAddonManifest - Compiled Protocol Buffers messages for google/apps/script/type/gmail/gmail_addon_manifest.proto

=head1 SYNOPSIS

    use Google::Apps::Script::Type::Gmail::GmailAddonManifest;

    my $msg = Google::Apps::Script::Type::Gmail::GmailAddonManifest::GmailAddOnManifest->new({
        homepage_trigger => $homepage_trigger,
        contextual_triggers => $contextual_triggers,
        universal_actions => $universal_actions,
        compose_trigger => $compose_trigger,
    });

    # Read or update a field
    my $val = $msg->homepage_trigger();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Apps::Script::Type::Gmail::GmailAddonManifest::GmailAddOnManifest->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/apps/script/type/gmail/gmail_addon_manifest.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Apps::Script::Type::Gmail::GmailAddonManifest::GmailAddOnManifest

Properties customizing the appearance and execution of a Gmail add-on.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->homepage_trigger() >> / C<< $msg->homepage_trigger($value) >>

Type: C<Message> (L<Google::Apps::Script::Type::ExtensionPoint::HomepageExtensionPoint>)

Defines an endpoint that will be executed in contexts that don't
match a declared contextual trigger. Any cards generated by this function
will always be available to the user, but may be eclipsed by contextual
content when this add-on declares more targeted triggers.

If present, this overrides the configuration from
`addOns.common.homepageTrigger`.

=item * C<< $msg->contextual_triggers() >> / C<< $msg->contextual_triggers($value) >>

Type: C<Message> (L<Google::Apps::Script::Type::Gmail::GmailAddonManifest::ContextualTrigger>)

Defines the set of conditions that trigger the add-on.

=item * C<< $msg->universal_actions() >> / C<< $msg->universal_actions($value) >>

Type: C<Message> (L<Google::Apps::Script::Type::Gmail::GmailAddonManifest::UniversalAction>)

Defines set of [universal
actions](/gmail/add-ons/how-tos/universal-actions) for the add-on. The user
triggers universal actions from the add-on toolbar menu.

=item * C<< $msg->compose_trigger() >> / C<< $msg->compose_trigger($value) >>

Type: C<Message> (L<Google::Apps::Script::Type::Gmail::GmailAddonManifest::ComposeTrigger>)

Defines the compose time trigger for a compose time add-on. This is the
trigger that causes an add-on to take action when the user is composing an
email.
All compose time addons are required to have the
gmail.addons.current.action.compose scope even though it might not edit the
draft.

=item * C<< $msg->authorization_check_function() >> / C<< $msg->authorization_check_function($value) >>

Type: C<String>

The name of an endpoint that verifies that the add-on has
all the required third-party authorizations, by probing the third-party
APIs. If the probe fails, the function should throw an exception to
initiate the authorization flow. This function is called before each
invocation of the add-on, in order to ensure a smooth user experience.

=back

=head2 Google::Apps::Script::Type::Gmail::GmailAddonManifest::UniversalAction

An action that is always available in the add-on toolbar menu regardless of
message context.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->text() >> / C<< $msg->text($value) >>

Type: C<String>

Required. User-visible text describing the action, for example, "Add a new
contact."

=item * C<< $msg->open_link() >> / C<< $msg->open_link($value) >>

Type: C<String>

A link that is opened by Gmail when the user triggers the action.

=item * C<< $msg->run_function() >> / C<< $msg->run_function($value) >>

Type: C<String>

An endpoint that is called when the user triggers the
action. See the [universal actions
guide](/gmail/add-ons/how-tos/universal-actions) for details.

=back

=head2 Google::Apps::Script::Type::Gmail::GmailAddonManifest::ComposeTrigger

A trigger that activates when user is composing an email.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->actions() >> / C<< $msg->actions($value) >>

Type: C<Message> (L<Google::Apps::Script::Type::ExtensionPoint::MenuItemExtensionPoint>)

Defines the set of actions for compose time add-on. These are actions
that user can trigger on a compose time addon.

=item * C<< $msg->draft_access() >> / C<< $msg->draft_access($value) >>

Type: C<Enum> (L<Google::Apps::Script::Type::Gmail::ComposeTrigger::DraftAccess>)

Define the level of data access when a compose time addon is triggered.

=back

=head3 Enum: ComposeTrigger::DraftAccess

=over 4

=item * C<UNSPECIFIED> => C<0>

=item * C<NONE> => C<1>

=item * C<METADATA> => C<2>

=back

=head2 Google::Apps::Script::Type::Gmail::GmailAddonManifest::ContextualTrigger

Defines a trigger that fires when the open email meets a specific criteria.
When the trigger fires, it executes a specific endpoint, usually
in order to create new cards and update the UI.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->unconditional() >> / C<< $msg->unconditional($value) >>

Type: C<Message> (L<Google::Apps::Script::Type::Gmail::GmailAddonManifest::UnconditionalTrigger>)

UnconditionalTriggers are executed when any mail message is opened.

=item * C<< $msg->on_trigger_function() >> / C<< $msg->on_trigger_function($value) >>

Type: C<String>

Required. The name of the endpoint to call when a message matches the
trigger.

=back

=head2 Google::Apps::Script::Type::Gmail::GmailAddonManifest::UnconditionalTrigger

A trigger that fires when any email message is opened.

Inherits from L<Protobuf::Message>.

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Apps::Script::Type::Gmail::GmailAddonManifest::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
