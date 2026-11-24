package Google::Cloud::Dialogflow::Cx::V3::Changelog;

use strict;
use warnings;

our $VERSION = '0.14';

use Protobuf::Message;
use Protobuf::DescriptorPool;
use Protobuf::Internal qw(:all);
use MIME::Base64;

BEGIN {
    eval { require Google::Api::Annotations };
    eval { require Google::Api::Client };
    eval { require Google::Api::FieldBehavior };
    eval { require Google::Api::Resource };
    eval { require Google::Protobuf::Timestamp };
    my $descriptor_b64 = <<'EOF';
Ci1nb29nbGUvY2xvdWQvZGlhbG9nZmxvdy9jeC92My9jaGFuZ2Vsb2cucHJvdG8SHWdvb2ds
ZS5jbG91ZC5kaWFsb2dmbG93LmN4LnYzGhxnb29nbGUvYXBpL2Fubm90YXRpb25zLnByb3Rv
Ghdnb29nbGUvYXBpL2NsaWVudC5wcm90bxofZ29vZ2xlL2FwaS9maWVsZF9iZWhhdmlvci5w
cm90bxoZZ29vZ2xlL2FwaS9yZXNvdXJjZS5wcm90bxofZ29vZ2xlL3Byb3RvYnVmL3RpbWVz
dGFtcC5wcm90byKwAQoVTGlzdENoYW5nZWxvZ3NSZXF1ZXN0EkMKBnBhcmVudBgBIAEoCUIr
4EEC+kElEiNkaWFsb2dmbG93Lmdvb2dsZWFwaXMuY29tL0NoYW5nZWxvZ1IGcGFyZW50EhYK
BmZpbHRlchgCIAEoCVIGZmlsdGVyEhsKCXBhZ2Vfc2l6ZRgDIAEoBVIIcGFnZVNpemUSHQoK
cGFnZV90b2tlbhgEIAEoCVIJcGFnZVRva2VuIooBChZMaXN0Q2hhbmdlbG9nc1Jlc3BvbnNl
EkgKCmNoYW5nZWxvZ3MYASADKAsyKC5nb29nbGUuY2xvdWQuZGlhbG9nZmxvdy5jeC52My5D
aGFuZ2Vsb2dSCmNoYW5nZWxvZ3MSJgoPbmV4dF9wYWdlX3Rva2VuGAIgASgJUg1uZXh0UGFn
ZVRva2VuIlYKE0dldENoYW5nZWxvZ1JlcXVlc3QSPwoEbmFtZRgBIAEoCUIr4EEC+kElCiNk
aWFsb2dmbG93Lmdvb2dsZWFwaXMuY29tL0NoYW5nZWxvZ1IEbmFtZSKEAwoJQ2hhbmdlbG9n
EhIKBG5hbWUYASABKAlSBG5hbWUSHQoKdXNlcl9lbWFpbBgCIAEoCVIJdXNlckVtYWlsEiEK
DGRpc3BsYXlfbmFtZRgHIAEoCVILZGlzcGxheU5hbWUSFgoGYWN0aW9uGAsgASgJUgZhY3Rp
b24SEgoEdHlwZRgIIAEoCVIEdHlwZRIaCghyZXNvdXJjZRgDIAEoCVIIcmVzb3VyY2USOwoL
Y3JlYXRlX3RpbWUYBCABKAsyGi5nb29nbGUucHJvdG9idWYuVGltZXN0YW1wUgpjcmVhdGVU
aW1lEiMKDWxhbmd1YWdlX2NvZGUYDiABKAlSDGxhbmd1YWdlQ29kZTp36kF0CiNkaWFsb2dm
bG93Lmdvb2dsZWFwaXMuY29tL0NoYW5nZWxvZxJNcHJvamVjdHMve3Byb2plY3R9L2xvY2F0
aW9ucy97bG9jYXRpb259L2FnZW50cy97YWdlbnR9L2NoYW5nZWxvZ3Mve2NoYW5nZWxvZ30y
hwQKCkNoYW5nZWxvZ3MSxwEKDkxpc3RDaGFuZ2Vsb2dzEjQuZ29vZ2xlLmNsb3VkLmRpYWxv
Z2Zsb3cuY3gudjMuTGlzdENoYW5nZWxvZ3NSZXF1ZXN0GjUuZ29vZ2xlLmNsb3VkLmRpYWxv
Z2Zsb3cuY3gudjMuTGlzdENoYW5nZWxvZ3NSZXNwb25zZSJIgtPkkwI5EjcvdjMve3BhcmVu
dD1wcm9qZWN0cy8qL2xvY2F0aW9ucy8qL2FnZW50cy8qfS9jaGFuZ2Vsb2dz2kEGcGFyZW50
ErQBCgxHZXRDaGFuZ2Vsb2cSMi5nb29nbGUuY2xvdWQuZGlhbG9nZmxvdy5jeC52My5HZXRD
aGFuZ2Vsb2dSZXF1ZXN0GiguZ29vZ2xlLmNsb3VkLmRpYWxvZ2Zsb3cuY3gudjMuQ2hhbmdl
bG9nIkaC0+STAjkSNy92My97bmFtZT1wcm9qZWN0cy8qL2xvY2F0aW9ucy8qL2FnZW50cy8q
L2NoYW5nZWxvZ3MvKn3aQQRuYW1lGnjKQRlkaWFsb2dmbG93Lmdvb2dsZWFwaXMuY29t0kFZ
aHR0cHM6Ly93d3cuZ29vZ2xlYXBpcy5jb20vYXV0aC9jbG91ZC1wbGF0Zm9ybSxodHRwczov
L3d3dy5nb29nbGVhcGlzLmNvbS9hdXRoL2RpYWxvZ2Zsb3dCsQEKIWNvbS5nb29nbGUuY2xv
dWQuZGlhbG9nZmxvdy5jeC52M0IOQ2hhbmdlbG9nUHJvdG9QAVoxY2xvdWQuZ29vZ2xlLmNv
bS9nby9kaWFsb2dmbG93L2N4L2FwaXYzL2N4cGI7Y3hwYqICAkRGqgIdR29vZ2xlLkNsb3Vk
LkRpYWxvZ2Zsb3cuQ3guVjPqAiFHb29nbGU6OkNsb3VkOjpEaWFsb2dmbG93OjpDWDo6VjNK
7CQKBxIFDgCdAQEKvAQKAQwSAw4AEjKxBCBDb3B5cmlnaHQgMjAyNiBHb29nbGUgTExDCgog
TGljZW5zZWQgdW5kZXIgdGhlIEFwYWNoZSBMaWNlbnNlLCBWZXJzaW9uIDIuMCAodGhlICJM
aWNlbnNlIik7CiB5b3UgbWF5IG5vdCB1c2UgdGhpcyBmaWxlIGV4Y2VwdCBpbiBjb21wbGlh
bmNlIHdpdGggdGhlIExpY2Vuc2UuCiBZb3UgbWF5IG9idGFpbiBhIGNvcHkgb2YgdGhlIExp
Y2Vuc2UgYXQKCiAgICAgaHR0cDovL3d3dy5hcGFjaGUub3JnL2xpY2Vuc2VzL0xJQ0VOU0Ut
Mi4wCgogVW5sZXNzIHJlcXVpcmVkIGJ5IGFwcGxpY2FibGUgbGF3IG9yIGFncmVlZCB0byBp
biB3cml0aW5nLCBzb2Z0d2FyZQogZGlzdHJpYnV0ZWQgdW5kZXIgdGhlIExpY2Vuc2UgaXMg
ZGlzdHJpYnV0ZWQgb24gYW4gIkFTIElTIiBCQVNJUywKIFdJVEhPVVQgV0FSUkFOVElFUyBP
UiBDT05ESVRJT05TIE9GIEFOWSBLSU5ELCBlaXRoZXIgZXhwcmVzcyBvciBpbXBsaWVkLgog
U2VlIHRoZSBMaWNlbnNlIGZvciB0aGUgc3BlY2lmaWMgbGFuZ3VhZ2UgZ292ZXJuaW5nIHBl
cm1pc3Npb25zIGFuZAogbGltaXRhdGlvbnMgdW5kZXIgdGhlIExpY2Vuc2UuCgoICgECEgMQ
ACYKCQoCAwASAxIAJgoJCgIDARIDEwAhCgkKAgMCEgMUACkKCQoCAwMSAxUAIwoJCgIDBBID
FgApCggKAQgSAxgAOgoJCgIIJRIDGAA6CggKAQgSAxkASAoJCgIICxIDGQBICggKAQgSAxoA
IgoJCgIIChIDGgAiCggKAQgSAxsALwoJCgIICBIDGwAvCggKAQgSAxwAOgoJCgIIARIDHAA6
CggKAQgSAx0AIAoJCgIIJBIDHQAgCggKAQgSAx4AOgoJCgIILRIDHgA6ClkKAgYAEgQhADYB
Gk0gU2VydmljZSBmb3IgbWFuYWdpbmcgW0NoYW5nZWxvZ3NdW2dvb2dsZS5jbG91ZC5kaWFs
b2dmbG93LmN4LnYzLkNoYW5nZWxvZ10uCgoKCgMGAAESAyEIEgoKCgMGAAMSAyICQQoMCgUG
AAOZCBIDIgJBCgsKAwYAAxIEIwIlMwoNCgUGAAOaCBIEIwIlMwovCgQGAAIAEgQoAi0DGiEg
UmV0dXJucyB0aGUgbGlzdCBvZiBDaGFuZ2Vsb2dzLgoKDAoFBgACAAESAygGFAoMCgUGAAIA
AhIDKBUqCgwKBQYAAgADEgMoNUsKDQoFBgACAAQSBCkEKwYKEQoJBgACAASwyrwiEgQpBCsG
CgwKBQYAAgAEEgMsBDQKDwoIBgACAASbCAASAywENAoyCgQGAAIBEgQwAjUDGiQgUmV0cmll
dmVzIHRoZSBzcGVjaWZpZWQgQ2hhbmdlbG9nLgoKDAoFBgACAQESAzAGEgoMCgUGAAIBAhID
MBMmCgwKBQYAAgEDEgMwMToKDQoFBgACAQQSBDEEMwYKEQoJBgACAQSwyrwiEgQxBDMGCgwK
BQYAAgEEEgM0BDIKDwoIBgACAQSbCAASAzQEMgp8CgIEABIEOgBgARpwIFRoZSByZXF1ZXN0
IG1lc3NhZ2UgZm9yCiBbQ2hhbmdlbG9ncy5MaXN0Q2hhbmdlbG9nc11bZ29vZ2xlLmNsb3Vk
LmRpYWxvZ2Zsb3cuY3gudjMuQ2hhbmdlbG9ncy5MaXN0Q2hhbmdlbG9nc10uCgoKCgMEAAES
AzoIHQqHAQoEBAACABIEPQJCBBp5IFJlcXVpcmVkLiBUaGUgYWdlbnQgY29udGFpbmluZyB0
aGUgY2hhbmdlbG9ncy4KIEZvcm1hdDogYHByb2plY3RzLzxQcm9qZWN0SUQ+L2xvY2F0aW9u
cy88TG9jYXRpb25JRD4vYWdlbnRzLzxBZ2VudElEPmAuCgoMCgUEAAIABRIDPQIICgwKBQQA
AgABEgM9CQ8KDAoFBAACAAMSAz0SEwoNCgUEAAIACBIEPRRCAwoPCggEAAIACJwIABIDPgQq
Cg8KBwQAAgAInwgSBD8EQQUKxwYKBAQAAgESA1gCFBq5BiBUaGUgZmlsdGVyIHN0cmluZy4g
U3VwcG9ydHMgZmlsdGVyIGJ5IHVzZXJfZW1haWwsIHJlc291cmNlLCB0eXBlIGFuZAogY3Jl
YXRlX3RpbWUuIFNvbWUgZXhhbXBsZXM6CiAgIDEuIEJ5IHVzZXIgZW1haWw6CiAgICAgICAg
dXNlcl9lbWFpbCA9ICJzb21lb25lQGdvb2dsZS5jb20iCiAgIDIuIEJ5IHJlc291cmNlIG5h
bWU6CiAgICAgICAgcmVzb3VyY2UgPSAicHJvamVjdHMvMTIzL2xvY2F0aW9ucy9nbG9iYWwv
YWdlbnRzLzQ1Ni9mbG93cy83ODkiCiAgIDMuIEJ5IHJlc291cmNlIGRpc3BsYXkgbmFtZToK
ICAgICAgICBkaXNwbGF5X25hbWUgPSAibXkgYWdlbnQiCiAgIDQuIEJ5IGFjdGlvbjoKICAg
ICAgICBhY3Rpb24gPSAiQ3JlYXRlIgogICA1LiBCeSB0eXBlOgogICAgICAgIHR5cGUgPSAi
Zmxvd3MiCiAgIDYuIEJ5IGNyZWF0ZSB0aW1lLiBDdXJyZW50bHkgcHJlZGljYXRlcyBvbiBg
Y3JlYXRlX3RpbWVgIGFuZAogICAgICBgY3JlYXRlX3RpbWVfZXBvY2hfc2Vjb25kc2AgYXJl
IHN1cHBvcnRlZDoKICAgICAgICBjcmVhdGVfdGltZV9lcG9jaF9zZWNvbmRzID4gMTU1MTc5
MDg3NyBBTkQgY3JlYXRlX3RpbWUgPD0KICAgICAgICAyMDE3LTAxLTE1VDAxOjMwOjE1LjAx
WgogICA3LiBDb21iaW5hdGlvbiBvZiBhYm92ZSBmaWx0ZXJzOgogICAgICAgIHJlc291cmNl
ID0gInByb2plY3RzLzEyMy9sb2NhdGlvbnMvZ2xvYmFsL2FnZW50cy80NTYvZmxvd3MvNzg5
IgogICAgICAgICAgQU5EIHVzZXJfZW1haWwgPSAic29tZW9uZUBnb29nbGUuY29tIgogICAg
ICAgICAgQU5EIGNyZWF0ZV90aW1lIDw9IDIwMTctMDEtMTVUMDE6MzA6MTUuMDFaCgoMCgUE
AAIBBRIDWAIICgwKBQQAAgEBEgNYCQ8KDAoFBAACAQMSA1gSEwpoCgQEAAICEgNcAhYaWyBU
aGUgbWF4aW11bSBudW1iZXIgb2YgaXRlbXMgdG8gcmV0dXJuIGluIGEgc2luZ2xlIHBhZ2Uu
IEJ5IGRlZmF1bHQgMTAwIGFuZAogYXQgbW9zdCAxMDAwLgoKDAoFBAACAgUSA1wCBwoMCgUE
AAICARIDXAgRCgwKBQQAAgIDEgNcFBUKTwoEBAACAxIDXwIYGkIgVGhlIG5leHRfcGFnZV90
b2tlbiB2YWx1ZSByZXR1cm5lZCBmcm9tIGEgcHJldmlvdXMgbGlzdCByZXF1ZXN0LgoKDAoF
BAACAwUSA18CCAoMCgUEAAIDARIDXwkTCgwKBQQAAgMDEgNfFhcKfQoCBAESBGQAbQEacSBU
aGUgcmVzcG9uc2UgbWVzc2FnZSBmb3IKIFtDaGFuZ2Vsb2dzLkxpc3RDaGFuZ2Vsb2dzXVtn
b29nbGUuY2xvdWQuZGlhbG9nZmxvdy5jeC52My5DaGFuZ2Vsb2dzLkxpc3RDaGFuZ2Vsb2dz
XS4KCgoKAwQBARIDZAgeCrQBCgQEAQIAEgNoAiQapgEgVGhlIGxpc3Qgb2YgY2hhbmdlbG9n
cy4gVGhlcmUgd2lsbCBiZSBhIG1heGltdW0gbnVtYmVyIG9mIGl0ZW1zIHJldHVybmVkCiBi
YXNlZCBvbiB0aGUgcGFnZV9zaXplIGZpZWxkIGluIHRoZSByZXF1ZXN0LiBUaGUgY2hhbmdl
bG9ncyB3aWxsIGJlIG9yZGVyZWQKIGJ5IHRpbWVzdGFtcC4KCgwKBQQBAgAEEgNoAgoKDAoF
BAECAAYSA2gLFAoMCgUEAQIAARIDaBUfCgwKBQQBAgADEgNoIiMKbgoEBAECARIDbAIdGmEg
VG9rZW4gdG8gcmV0cmlldmUgdGhlIG5leHQgcGFnZSBvZiByZXN1bHRzLCBvciBlbXB0eSBp
ZiB0aGVyZSBhcmUgbm8gbW9yZQogcmVzdWx0cyBpbiB0aGUgbGlzdC4KCgwKBQQBAgEFEgNs
AggKDAoFBAECAQESA2wJGAoMCgUEAQIBAxIDbBscCngKAgQCEgRxAHsBGmwgVGhlIHJlcXVl
c3QgbWVzc2FnZSBmb3IKIFtDaGFuZ2Vsb2dzLkdldENoYW5nZWxvZ11bZ29vZ2xlLmNsb3Vk
LmRpYWxvZ2Zsb3cuY3gudjMuQ2hhbmdlbG9ncy5HZXRDaGFuZ2Vsb2ddLgoKCgoDBAIBEgNx
CBsKnwEKBAQCAgASBHUCegQakAEgUmVxdWlyZWQuIFRoZSBuYW1lIG9mIHRoZSBjaGFuZ2Vs
b2cgdG8gZ2V0LgogRm9ybWF0OgogYHByb2plY3RzLzxQcm9qZWN0SUQ+L2xvY2F0aW9ucy88
TG9jYXRpb25JRD4vYWdlbnRzLzxBZ2VudElEPi9jaGFuZ2Vsb2dzLzxDaGFuZ2Vsb2dJRD5g
LgoKDAoFBAICAAUSA3UCCAoMCgUEAgIAARIDdQkNCgwKBQQCAgADEgN1EBEKDQoFBAICAAgS
BHUSegMKDwoIBAICAAicCAASA3YEKgoPCgcEAgIACJ8IEgR3BHkFCkQKAgQDEgV+AJ0BARo3
IENoYW5nZWxvZ3MgcmVwcmVzZW50cyBhIGNoYW5nZSBtYWRlIHRvIGEgZ2l2ZW4gYWdlbnQu
CgoKCgMEAwESA34IEQoMCgMEAwcSBX8CggEECg4KBQQDB50IEgV/AoIBBAqbAQoEBAMCABIE
hwECEhqMASBUaGUgdW5pcXVlIGlkZW50aWZpZXIgb2YgdGhlIGNoYW5nZWxvZy4KIEZvcm1h
dDoKIGBwcm9qZWN0cy88UHJvamVjdElEPi9sb2NhdGlvbnMvPExvY2F0aW9uSUQ+L2FnZW50
cy88QWdlbnRJRD4vY2hhbmdlbG9ncy88Q2hhbmdlbG9nSUQ+YC4KCg0KBQQDAgAFEgSHAQII
Cg0KBQQDAgABEgSHAQkNCg0KBQQDAgADEgSHARARCjgKBAQDAgESBIoBAhgaKiBFbWFpbCBh
ZGRyZXNzIG9mIHRoZSBhdXRoZW50aWNhdGVkIHVzZXIuCgoNCgUEAwIBBRIEigECCAoNCgUE
AwIBARIEigEJEwoNCgUEAwIBAxIEigEWFwpBCgQEAwICEgSNAQIaGjMgVGhlIGFmZmVjdGVk
IHJlc291cmNlIGRpc3BsYXkgbmFtZSBvZiB0aGUgY2hhbmdlLgoKDQoFBAMCAgUSBI0BAggK
DQoFBAMCAgESBI0BCRUKDQoFBAMCAgMSBI0BGBkKKQoEBAMCAxIEkAECFRobIFRoZSBhY3Rp
b24gb2YgdGhlIGNoYW5nZS4KCg0KBQQDAgMFEgSQAQIICg0KBQQDAgMBEgSQAQkPCg0KBQQD
AgMDEgSQARIUCisKBAQDAgQSBJMBAhIaHSBUaGUgYWZmZWN0ZWQgcmVzb3VyY2UgdHlwZS4K
Cg0KBQQDAgQFEgSTAQIICg0KBQQDAgQBEgSTAQkNCg0KBQQDAgQDEgSTARARCjkKBAQDAgUS
BJYBAhYaKyBUaGUgYWZmZWN0ZWQgcmVzb3VyY2UgbmFtZSBvZiB0aGUgY2hhbmdlLgoKDQoF
BAMCBQUSBJYBAggKDQoFBAMCBQESBJYBCREKDQoFBAMCBQMSBJYBFBUKLAoEBAMCBhIEmQEC
LBoeIFRoZSB0aW1lc3RhbXAgb2YgdGhlIGNoYW5nZS4KCg0KBQQDAgYGEgSZAQIbCg0KBQQD
AgYBEgSZARwnCg0KBQQDAgYDEgSZASorCjkKBAQDAgcSBJwBAhwaKyBUaGUgYWZmZWN0ZWQg
bGFuZ3VhZ2UgY29kZSBvZiB0aGUgY2hhbmdlLgoKDQoFBAMCBwUSBJwBAggKDQoFBAMCBwES
BJwBCRYKDQoFBAMCBwMSBJwBGRtiBnByb3RvMw==
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Dialogflow::Cx::V3::Changelog::ListChangelogsRequest ===
    # Fields for ListChangelogsRequest
    # Field: parent Type: 9 ()
    # Field: filter Type: 9 ()
    # Field: page_size Type: 5 ()
    # Field: page_token Type: 9 ()

# === Message: Google::Cloud::Dialogflow::Cx::V3::Changelog::ListChangelogsResponse ===
    # Fields for ListChangelogsResponse
    # Field: changelogs Type: 11 (.google.cloud.dialogflow.cx.v3.Changelog)
    # Field: next_page_token Type: 9 ()

# === Message: Google::Cloud::Dialogflow::Cx::V3::Changelog::GetChangelogRequest ===
    # Fields for GetChangelogRequest
    # Field: name Type: 9 ()

# === Message: Google::Cloud::Dialogflow::Cx::V3::Changelog::Changelog ===
    # Fields for Changelog
    # Field: name Type: 9 ()
    # Field: user_email Type: 9 ()
    # Field: display_name Type: 9 ()
    # Field: action Type: 9 ()
    # Field: type Type: 9 ()
    # Field: resource Type: 9 ()
    # Field: create_time Type: 11 (.google.protobuf.Timestamp)
    # Field: language_code Type: 9 ()

# === Service Client: Google::Cloud::Dialogflow::Cx::V3::Changelog::ChangelogsClient ===
package Google::Cloud::Dialogflow::Cx::V3::Changelog::ChangelogsClient;

=pod

=head2 Service Client: Google::Cloud::Dialogflow::Cx::V3::Changelog::ChangelogsClient

Client stub representing the remote C<Changelogs> gRPC service. Delegates call dispatching to L<Google::gRPC::Client>.

=head3 target

The endpoint target address. Defaults to C<dialogflow.googleapis.com:443>.

=head3 credentials

The authentication credentials provider. Defaults to application default credentials via L<Google::Auth>.

=cut

use Moo;
use Google::Auth;
use Google::gRPC::Client;

has credentials => ( is => 'ro', default => sub { Google::Auth->default() } );
has target      => ( is => 'ro', default => 'dialogflow.googleapis.com:443' );

has _grpc_client => (
    is => 'ro',
    lazy => 1,
    builder => sub {
        my $self = shift;
        return Google::gRPC::Client->new(
            target     => $self->target,
            auth_token => $self->credentials->get_token(),
        );
    }
);

sub list_changelogs {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Dialogflow::Cx::V3::Changelog::ListChangelogsRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.dialogflow.cx.v3.Changelogs',
        method         => 'ListChangelogs',
        request        => $req,
        response_class => 'Google::Cloud::Dialogflow::Cx::V3::Changelog::ListChangelogsResponse',
    });
}

sub get_changelog {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Dialogflow::Cx::V3::Changelog::GetChangelogRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.dialogflow.cx.v3.Changelogs',
        method         => 'GetChangelog',
        request        => $req,
        response_class => 'Google::Cloud::Dialogflow::Cx::V3::Changelog::Changelog',
    });
}

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Dialogflow::Cx::V3::Changelog - Compiled Protocol Buffers messages for google/cloud/dialogflow/cx/v3/changelog.proto

=head1 SYNOPSIS

    use Google::Cloud::Dialogflow::Cx::V3::Changelog;

    my $msg = Google::Cloud::Dialogflow::Cx::V3::Changelog::ListChangelogsRequest->new({
        parent => $parent,
        filter => $filter,
        page_size => $page_size,
        page_token => $page_token,
    });

    # Read or update a field
    my $val = $msg->parent();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Dialogflow::Cx::V3::Changelog::ListChangelogsRequest->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/dialogflow/cx/v3/changelog.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Dialogflow::Cx::V3::Changelog::ListChangelogsRequest

The request message for
[Changelogs.ListChangelogs][google.cloud.dialogflow.cx.v3.Changelogs.ListChangelogs].

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->parent() >> / C<< $msg->parent($value) >>

Type: C<String>

Required. The agent containing the changelogs.
Format: `projects/<ProjectID>/locations/<LocationID>/agents/<AgentID>`.

=item * C<< $msg->filter() >> / C<< $msg->filter($value) >>

Type: C<String>

The filter string. Supports filter by user_email, resource, type and
create_time. Some examples:
  1. By user email:
       user_email = "someone@google.com"
  2. By resource name:
       resource = "projects/123/locations/global/agents/456/flows/789"
  3. By resource display name:
       display_name = "my agent"
  4. By action:
       action = "Create"
  5. By type:
       type = "flows"
  6. By create time. Currently predicates on `create_time` and
     `create_time_epoch_seconds` are supported:
       create_time_epoch_seconds > 1551790877 AND create_time <=
       2017-01-15T01:30:15.01Z
  7. Combination of above filters:
       resource = "projects/123/locations/global/agents/456/flows/789"
         AND user_email = "someone@google.com"
         AND create_time <= 2017-01-15T01:30:15.01Z

=item * C<< $msg->page_size() >> / C<< $msg->page_size($value) >>

Type: C<Int32>

The maximum number of items to return in a single page. By default 100 and
at most 1000.

=item * C<< $msg->page_token() >> / C<< $msg->page_token($value) >>

Type: C<String>

The next_page_token value returned from a previous list request.

=back

=head2 Google::Cloud::Dialogflow::Cx::V3::Changelog::ListChangelogsResponse

The response message for
[Changelogs.ListChangelogs][google.cloud.dialogflow.cx.v3.Changelogs.ListChangelogs].

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->changelogs() >> / C<< $msg->changelogs($value) >>

Type: C<Message> (L<Google::Cloud::Dialogflow::Cx::V3::Changelog::Changelog>)

The list of changelogs. There will be a maximum number of items returned
based on the page_size field in the request. The changelogs will be ordered
by timestamp.

=item * C<< $msg->next_page_token() >> / C<< $msg->next_page_token($value) >>

Type: C<String>

Token to retrieve the next page of results, or empty if there are no more
results in the list.

=back

=head2 Google::Cloud::Dialogflow::Cx::V3::Changelog::GetChangelogRequest

The request message for
[Changelogs.GetChangelog][google.cloud.dialogflow.cx.v3.Changelogs.GetChangelog].

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. The name of the changelog to get.
Format:
`projects/<ProjectID>/locations/<LocationID>/agents/<AgentID>/changelogs/<ChangelogID>`.

=back

=head2 Google::Cloud::Dialogflow::Cx::V3::Changelog::Changelog

Changelogs represents a change made to a given agent.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

The unique identifier of the changelog.
Format:
`projects/<ProjectID>/locations/<LocationID>/agents/<AgentID>/changelogs/<ChangelogID>`.

=item * C<< $msg->user_email() >> / C<< $msg->user_email($value) >>

Type: C<String>

Email address of the authenticated user.

=item * C<< $msg->display_name() >> / C<< $msg->display_name($value) >>

Type: C<String>

The affected resource display name of the change.

=item * C<< $msg->action() >> / C<< $msg->action($value) >>

Type: C<String>

The action of the change.

=item * C<< $msg->type() >> / C<< $msg->type($value) >>

Type: C<String>

The affected resource type.

=item * C<< $msg->resource() >> / C<< $msg->resource($value) >>

Type: C<String>

The affected resource name of the change.

=item * C<< $msg->create_time() >> / C<< $msg->create_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

The timestamp of the change.

=item * C<< $msg->language_code() >> / C<< $msg->language_code($value) >>

Type: C<String>

The affected language code of the change.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Dialogflow::Cx::V3::Changelog::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
