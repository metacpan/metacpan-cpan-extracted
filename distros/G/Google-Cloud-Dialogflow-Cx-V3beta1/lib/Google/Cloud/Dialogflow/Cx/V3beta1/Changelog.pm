package Google::Cloud::Dialogflow::Cx::V3beta1::Changelog;

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
CjJnb29nbGUvY2xvdWQvZGlhbG9nZmxvdy9jeC92M2JldGExL2NoYW5nZWxvZy5wcm90bxIi
Z29vZ2xlLmNsb3VkLmRpYWxvZ2Zsb3cuY3gudjNiZXRhMRocZ29vZ2xlL2FwaS9hbm5vdGF0
aW9ucy5wcm90bxoXZ29vZ2xlL2FwaS9jbGllbnQucHJvdG8aH2dvb2dsZS9hcGkvZmllbGRf
YmVoYXZpb3IucHJvdG8aGWdvb2dsZS9hcGkvcmVzb3VyY2UucHJvdG8aH2dvb2dsZS9wcm90
b2J1Zi90aW1lc3RhbXAucHJvdG8isAEKFUxpc3RDaGFuZ2Vsb2dzUmVxdWVzdBJDCgZwYXJl
bnQYASABKAlCK+BBAvpBJRIjZGlhbG9nZmxvdy5nb29nbGVhcGlzLmNvbS9DaGFuZ2Vsb2dS
BnBhcmVudBIWCgZmaWx0ZXIYAiABKAlSBmZpbHRlchIbCglwYWdlX3NpemUYAyABKAVSCHBh
Z2VTaXplEh0KCnBhZ2VfdG9rZW4YBCABKAlSCXBhZ2VUb2tlbiKPAQoWTGlzdENoYW5nZWxv
Z3NSZXNwb25zZRJNCgpjaGFuZ2Vsb2dzGAEgAygLMi0uZ29vZ2xlLmNsb3VkLmRpYWxvZ2Zs
b3cuY3gudjNiZXRhMS5DaGFuZ2Vsb2dSCmNoYW5nZWxvZ3MSJgoPbmV4dF9wYWdlX3Rva2Vu
GAIgASgJUg1uZXh0UGFnZVRva2VuIlYKE0dldENoYW5nZWxvZ1JlcXVlc3QSPwoEbmFtZRgB
IAEoCUIr4EEC+kElCiNkaWFsb2dmbG93Lmdvb2dsZWFwaXMuY29tL0NoYW5nZWxvZ1IEbmFt
ZSKEAwoJQ2hhbmdlbG9nEhIKBG5hbWUYASABKAlSBG5hbWUSHQoKdXNlcl9lbWFpbBgCIAEo
CVIJdXNlckVtYWlsEiEKDGRpc3BsYXlfbmFtZRgHIAEoCVILZGlzcGxheU5hbWUSFgoGYWN0
aW9uGAsgASgJUgZhY3Rpb24SEgoEdHlwZRgIIAEoCVIEdHlwZRIaCghyZXNvdXJjZRgDIAEo
CVIIcmVzb3VyY2USOwoLY3JlYXRlX3RpbWUYBCABKAsyGi5nb29nbGUucHJvdG9idWYuVGlt
ZXN0YW1wUgpjcmVhdGVUaW1lEiMKDWxhbmd1YWdlX2NvZGUYDiABKAlSDGxhbmd1YWdlQ29k
ZTp36kF0CiNkaWFsb2dmbG93Lmdvb2dsZWFwaXMuY29tL0NoYW5nZWxvZxJNcHJvamVjdHMv
e3Byb2plY3R9L2xvY2F0aW9ucy97bG9jYXRpb259L2FnZW50cy97YWdlbnR9L2NoYW5nZWxv
Z3Mve2NoYW5nZWxvZ30ypQQKCkNoYW5nZWxvZ3MS1gEKDkxpc3RDaGFuZ2Vsb2dzEjkuZ29v
Z2xlLmNsb3VkLmRpYWxvZ2Zsb3cuY3gudjNiZXRhMS5MaXN0Q2hhbmdlbG9nc1JlcXVlc3Qa
Oi5nb29nbGUuY2xvdWQuZGlhbG9nZmxvdy5jeC52M2JldGExLkxpc3RDaGFuZ2Vsb2dzUmVz
cG9uc2UiTYLT5JMCPhI8L3YzYmV0YTEve3BhcmVudD1wcm9qZWN0cy8qL2xvY2F0aW9ucy8q
L2FnZW50cy8qfS9jaGFuZ2Vsb2dz2kEGcGFyZW50EsMBCgxHZXRDaGFuZ2Vsb2cSNy5nb29n
bGUuY2xvdWQuZGlhbG9nZmxvdy5jeC52M2JldGExLkdldENoYW5nZWxvZ1JlcXVlc3QaLS5n
b29nbGUuY2xvdWQuZGlhbG9nZmxvdy5jeC52M2JldGExLkNoYW5nZWxvZyJLgtPkkwI+Ejwv
djNiZXRhMS97bmFtZT1wcm9qZWN0cy8qL2xvY2F0aW9ucy8qL2FnZW50cy8qL2NoYW5nZWxv
Z3MvKn3aQQRuYW1lGnjKQRlkaWFsb2dmbG93Lmdvb2dsZWFwaXMuY29t0kFZaHR0cHM6Ly93
d3cuZ29vZ2xlYXBpcy5jb20vYXV0aC9jbG91ZC1wbGF0Zm9ybSxodHRwczovL3d3dy5nb29n
bGVhcGlzLmNvbS9hdXRoL2RpYWxvZ2Zsb3dCxQEKJmNvbS5nb29nbGUuY2xvdWQuZGlhbG9n
Zmxvdy5jeC52M2JldGExQg5DaGFuZ2Vsb2dQcm90b1ABWjZjbG91ZC5nb29nbGUuY29tL2dv
L2RpYWxvZ2Zsb3cvY3gvYXBpdjNiZXRhMS9jeHBiO2N4cGKiAgJERqoCIkdvb2dsZS5DbG91
ZC5EaWFsb2dmbG93LkN4LlYzQmV0YTHqAiZHb29nbGU6OkNsb3VkOjpEaWFsb2dmbG93OjpD
WDo6VjNiZXRhMUqFJQoHEgUOAJ4BAQq8BAoBDBIDDgASMrEEIENvcHlyaWdodCAyMDI2IEdv
b2dsZSBMTEMKCiBMaWNlbnNlZCB1bmRlciB0aGUgQXBhY2hlIExpY2Vuc2UsIFZlcnNpb24g
Mi4wICh0aGUgIkxpY2Vuc2UiKTsKIHlvdSBtYXkgbm90IHVzZSB0aGlzIGZpbGUgZXhjZXB0
IGluIGNvbXBsaWFuY2Ugd2l0aCB0aGUgTGljZW5zZS4KIFlvdSBtYXkgb2J0YWluIGEgY29w
eSBvZiB0aGUgTGljZW5zZSBhdAoKICAgICBodHRwOi8vd3d3LmFwYWNoZS5vcmcvbGljZW5z
ZXMvTElDRU5TRS0yLjAKCiBVbmxlc3MgcmVxdWlyZWQgYnkgYXBwbGljYWJsZSBsYXcgb3Ig
YWdyZWVkIHRvIGluIHdyaXRpbmcsIHNvZnR3YXJlCiBkaXN0cmlidXRlZCB1bmRlciB0aGUg
TGljZW5zZSBpcyBkaXN0cmlidXRlZCBvbiBhbiAiQVMgSVMiIEJBU0lTLAogV0lUSE9VVCBX
QVJSQU5USUVTIE9SIENPTkRJVElPTlMgT0YgQU5ZIEtJTkQsIGVpdGhlciBleHByZXNzIG9y
IGltcGxpZWQuCiBTZWUgdGhlIExpY2Vuc2UgZm9yIHRoZSBzcGVjaWZpYyBsYW5ndWFnZSBn
b3Zlcm5pbmcgcGVybWlzc2lvbnMgYW5kCiBsaW1pdGF0aW9ucyB1bmRlciB0aGUgTGljZW5z
ZS4KCggKAQISAxAAKwoJCgIDABIDEgAmCgkKAgMBEgMTACEKCQoCAwISAxQAKQoJCgIDAxID
FQAjCgkKAgMEEgMWACkKCAoBCBIDGAA/CgkKAgglEgMYAD8KCAoBCBIDGQBNCgkKAggLEgMZ
AE0KCAoBCBIDGgAiCgkKAggKEgMaACIKCAoBCBIDGwAvCgkKAggIEgMbAC8KCAoBCBIDHAA/
CgkKAggBEgMcAD8KCAoBCBIDHQAgCgkKAggkEgMdACAKCAoBCBIDHgA/CgkKAggtEgMeAD8K
XwoCBgASBCIANwEaUyBTZXJ2aWNlIGZvciBtYW5hZ2luZwogW0NoYW5nZWxvZ3NdW2dvb2ds
ZS5jbG91ZC5kaWFsb2dmbG93LmN4LnYzYmV0YTEuQ2hhbmdlbG9nXS4KCgoKAwYAARIDIggS
CgoKAwYAAxIDIwJBCgwKBQYAA5kIEgMjAkEKCwoDBgADEgQkAiYzCg0KBQYAA5oIEgQkAiYz
Ci8KBAYAAgASBCkCLgMaISBSZXR1cm5zIHRoZSBsaXN0IG9mIENoYW5nZWxvZ3MuCgoMCgUG
AAIAARIDKQYUCgwKBQYAAgACEgMpFSoKDAoFBgACAAMSAyk1SwoNCgUGAAIABBIEKgQsBgoR
CgkGAAIABLDKvCISBCoELAYKDAoFBgACAAQSAy0ENAoPCggGAAIABJsIABIDLQQ0CjIKBAYA
AgESBDECNgMaJCBSZXRyaWV2ZXMgdGhlIHNwZWNpZmllZCBDaGFuZ2Vsb2cuCgoMCgUGAAIB
ARIDMQYSCgwKBQYAAgECEgMxEyYKDAoFBgACAQMSAzExOgoNCgUGAAIBBBIEMgQ0BgoRCgkG
AAIBBLDKvCISBDIENAYKDAoFBgACAQQSAzUEMgoPCggGAAIBBJsIABIDNQQyCoEBCgIEABIE
OwBhARp1IFRoZSByZXF1ZXN0IG1lc3NhZ2UgZm9yCiBbQ2hhbmdlbG9ncy5MaXN0Q2hhbmdl
bG9nc11bZ29vZ2xlLmNsb3VkLmRpYWxvZ2Zsb3cuY3gudjNiZXRhMS5DaGFuZ2Vsb2dzLkxp
c3RDaGFuZ2Vsb2dzXS4KCgoKAwQAARIDOwgdCocBCgQEAAIAEgQ+AkMEGnkgUmVxdWlyZWQu
IFRoZSBhZ2VudCBjb250YWluaW5nIHRoZSBjaGFuZ2Vsb2dzLgogRm9ybWF0OiBgcHJvamVj
dHMvPFByb2plY3RJRD4vbG9jYXRpb25zLzxMb2NhdGlvbklEPi9hZ2VudHMvPEFnZW50SUQ+
YC4KCgwKBQQAAgAFEgM+AggKDAoFBAACAAESAz4JDwoMCgUEAAIAAxIDPhITCg0KBQQAAgAI
EgQ+FEMDCg8KCAQAAgAInAgAEgM/BCoKDwoHBAACAAifCBIEQARCBQrHBgoEBAACARIDWQIU
GrkGIFRoZSBmaWx0ZXIgc3RyaW5nLiBTdXBwb3J0cyBmaWx0ZXIgYnkgdXNlcl9lbWFpbCwg
cmVzb3VyY2UsIHR5cGUgYW5kCiBjcmVhdGVfdGltZS4gU29tZSBleGFtcGxlczoKICAgMS4g
QnkgdXNlciBlbWFpbDoKICAgICAgICB1c2VyX2VtYWlsID0gInNvbWVvbmVAZ29vZ2xlLmNv
bSIKICAgMi4gQnkgcmVzb3VyY2UgbmFtZToKICAgICAgICByZXNvdXJjZSA9ICJwcm9qZWN0
cy8xMjMvbG9jYXRpb25zL2dsb2JhbC9hZ2VudHMvNDU2L2Zsb3dzLzc4OSIKICAgMy4gQnkg
cmVzb3VyY2UgZGlzcGxheSBuYW1lOgogICAgICAgIGRpc3BsYXlfbmFtZSA9ICJteSBhZ2Vu
dCIKICAgNC4gQnkgYWN0aW9uOgogICAgICAgIGFjdGlvbiA9ICJDcmVhdGUiCiAgIDUuIEJ5
IHR5cGU6CiAgICAgICAgdHlwZSA9ICJmbG93cyIKICAgNi4gQnkgY3JlYXRlIHRpbWUuIEN1
cnJlbnRseSBwcmVkaWNhdGVzIG9uIGBjcmVhdGVfdGltZWAgYW5kCiAgICAgIGBjcmVhdGVf
dGltZV9lcG9jaF9zZWNvbmRzYCBhcmUgc3VwcG9ydGVkOgogICAgICAgIGNyZWF0ZV90aW1l
X2Vwb2NoX3NlY29uZHMgPiAxNTUxNzkwODc3IEFORCBjcmVhdGVfdGltZSA8PQogICAgICAg
IDIwMTctMDEtMTVUMDE6MzA6MTUuMDFaCiAgIDcuIENvbWJpbmF0aW9uIG9mIGFib3ZlIGZp
bHRlcnM6CiAgICAgICAgcmVzb3VyY2UgPSAicHJvamVjdHMvMTIzL2xvY2F0aW9ucy9nbG9i
YWwvYWdlbnRzLzQ1Ni9mbG93cy83ODkiCiAgICAgICAgICBBTkQgdXNlcl9lbWFpbCA9ICJz
b21lb25lQGdvb2dsZS5jb20iCiAgICAgICAgICBBTkQgY3JlYXRlX3RpbWUgPD0gMjAxNy0w
MS0xNVQwMTozMDoxNS4wMVoKCgwKBQQAAgEFEgNZAggKDAoFBAACAQESA1kJDwoMCgUEAAIB
AxIDWRITCmgKBAQAAgISA10CFhpbIFRoZSBtYXhpbXVtIG51bWJlciBvZiBpdGVtcyB0byBy
ZXR1cm4gaW4gYSBzaW5nbGUgcGFnZS4gQnkgZGVmYXVsdCAxMDAgYW5kCiBhdCBtb3N0IDEw
MDAuCgoMCgUEAAICBRIDXQIHCgwKBQQAAgIBEgNdCBEKDAoFBAACAgMSA10UFQpPCgQEAAID
EgNgAhgaQiBUaGUgbmV4dF9wYWdlX3Rva2VuIHZhbHVlIHJldHVybmVkIGZyb20gYSBwcmV2
aW91cyBsaXN0IHJlcXVlc3QuCgoMCgUEAAIDBRIDYAIICgwKBQQAAgMBEgNgCRMKDAoFBAAC
AwMSA2AWFwqCAQoCBAESBGUAbgEadiBUaGUgcmVzcG9uc2UgbWVzc2FnZSBmb3IKIFtDaGFu
Z2Vsb2dzLkxpc3RDaGFuZ2Vsb2dzXVtnb29nbGUuY2xvdWQuZGlhbG9nZmxvdy5jeC52M2Jl
dGExLkNoYW5nZWxvZ3MuTGlzdENoYW5nZWxvZ3NdLgoKCgoDBAEBEgNlCB4KtAEKBAQBAgAS
A2kCJBqmASBUaGUgbGlzdCBvZiBjaGFuZ2Vsb2dzLiBUaGVyZSB3aWxsIGJlIGEgbWF4aW11
bSBudW1iZXIgb2YgaXRlbXMgcmV0dXJuZWQKIGJhc2VkIG9uIHRoZSBwYWdlX3NpemUgZmll
bGQgaW4gdGhlIHJlcXVlc3QuIFRoZSBjaGFuZ2Vsb2dzIHdpbGwgYmUgb3JkZXJlZAogYnkg
dGltZXN0YW1wLgoKDAoFBAECAAQSA2kCCgoMCgUEAQIABhIDaQsUCgwKBQQBAgABEgNpFR8K
DAoFBAECAAMSA2kiIwpuCgQEAQIBEgNtAh0aYSBUb2tlbiB0byByZXRyaWV2ZSB0aGUgbmV4
dCBwYWdlIG9mIHJlc3VsdHMsIG9yIGVtcHR5IGlmIHRoZXJlIGFyZSBubyBtb3JlCiByZXN1
bHRzIGluIHRoZSBsaXN0LgoKDAoFBAECAQUSA20CCAoMCgUEAQIBARIDbQkYCgwKBQQBAgED
EgNtGxwKfQoCBAISBHIAfAEacSBUaGUgcmVxdWVzdCBtZXNzYWdlIGZvcgogW0NoYW5nZWxv
Z3MuR2V0Q2hhbmdlbG9nXVtnb29nbGUuY2xvdWQuZGlhbG9nZmxvdy5jeC52M2JldGExLkNo
YW5nZWxvZ3MuR2V0Q2hhbmdlbG9nXS4KCgoKAwQCARIDcggbCp8BCgQEAgIAEgR2AnsEGpAB
IFJlcXVpcmVkLiBUaGUgbmFtZSBvZiB0aGUgY2hhbmdlbG9nIHRvIGdldC4KIEZvcm1hdDoK
IGBwcm9qZWN0cy88UHJvamVjdElEPi9sb2NhdGlvbnMvPExvY2F0aW9uSUQ+L2FnZW50cy88
QWdlbnRJRD4vY2hhbmdlbG9ncy88Q2hhbmdlbG9nSUQ+YC4KCgwKBQQCAgAFEgN2AggKDAoF
BAICAAESA3YJDQoMCgUEAgIAAxIDdhARCg0KBQQCAgAIEgR2EnsDCg8KCAQCAgAInAgAEgN3
BCoKDwoHBAICAAifCBIEeAR6BQpECgIEAxIFfwCeAQEaNyBDaGFuZ2Vsb2dzIHJlcHJlc2Vu
dHMgYSBjaGFuZ2UgbWFkZSB0byBhIGdpdmVuIGFnZW50LgoKCgoDBAMBEgN/CBEKDQoDBAMH
EgaAAQKDAQQKDwoFBAMHnQgSBoABAoMBBAqbAQoEBAMCABIEiAECEhqMASBUaGUgdW5pcXVl
IGlkZW50aWZpZXIgb2YgdGhlIGNoYW5nZWxvZy4KIEZvcm1hdDoKIGBwcm9qZWN0cy88UHJv
amVjdElEPi9sb2NhdGlvbnMvPExvY2F0aW9uSUQ+L2FnZW50cy88QWdlbnRJRD4vY2hhbmdl
bG9ncy88Q2hhbmdlbG9nSUQ+YC4KCg0KBQQDAgAFEgSIAQIICg0KBQQDAgABEgSIAQkNCg0K
BQQDAgADEgSIARARCjgKBAQDAgESBIsBAhgaKiBFbWFpbCBhZGRyZXNzIG9mIHRoZSBhdXRo
ZW50aWNhdGVkIHVzZXIuCgoNCgUEAwIBBRIEiwECCAoNCgUEAwIBARIEiwEJEwoNCgUEAwIB
AxIEiwEWFwpBCgQEAwICEgSOAQIaGjMgVGhlIGFmZmVjdGVkIHJlc291cmNlIGRpc3BsYXkg
bmFtZSBvZiB0aGUgY2hhbmdlLgoKDQoFBAMCAgUSBI4BAggKDQoFBAMCAgESBI4BCRUKDQoF
BAMCAgMSBI4BGBkKKQoEBAMCAxIEkQECFRobIFRoZSBhY3Rpb24gb2YgdGhlIGNoYW5nZS4K
Cg0KBQQDAgMFEgSRAQIICg0KBQQDAgMBEgSRAQkPCg0KBQQDAgMDEgSRARIUCisKBAQDAgQS
BJQBAhIaHSBUaGUgYWZmZWN0ZWQgcmVzb3VyY2UgdHlwZS4KCg0KBQQDAgQFEgSUAQIICg0K
BQQDAgQBEgSUAQkNCg0KBQQDAgQDEgSUARARCjkKBAQDAgUSBJcBAhYaKyBUaGUgYWZmZWN0
ZWQgcmVzb3VyY2UgbmFtZSBvZiB0aGUgY2hhbmdlLgoKDQoFBAMCBQUSBJcBAggKDQoFBAMC
BQESBJcBCREKDQoFBAMCBQMSBJcBFBUKLAoEBAMCBhIEmgECLBoeIFRoZSB0aW1lc3RhbXAg
b2YgdGhlIGNoYW5nZS4KCg0KBQQDAgYGEgSaAQIbCg0KBQQDAgYBEgSaARwnCg0KBQQDAgYD
EgSaASorCjkKBAQDAgcSBJ0BAhwaKyBUaGUgYWZmZWN0ZWQgbGFuZ3VhZ2UgY29kZSBvZiB0
aGUgY2hhbmdlLgoKDQoFBAMCBwUSBJ0BAggKDQoFBAMCBwESBJ0BCRYKDQoFBAMCBwMSBJ0B
GRtiBnByb3RvMw==
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Dialogflow::Cx::V3beta1::Changelog::ListChangelogsRequest ===
    # Fields for ListChangelogsRequest
    # Field: parent Type: 9 ()
    # Field: filter Type: 9 ()
    # Field: page_size Type: 5 ()
    # Field: page_token Type: 9 ()

# === Message: Google::Cloud::Dialogflow::Cx::V3beta1::Changelog::ListChangelogsResponse ===
    # Fields for ListChangelogsResponse
    # Field: changelogs Type: 11 (.google.cloud.dialogflow.cx.v3beta1.Changelog)
    # Field: next_page_token Type: 9 ()

# === Message: Google::Cloud::Dialogflow::Cx::V3beta1::Changelog::GetChangelogRequest ===
    # Fields for GetChangelogRequest
    # Field: name Type: 9 ()

# === Message: Google::Cloud::Dialogflow::Cx::V3beta1::Changelog::Changelog ===
    # Fields for Changelog
    # Field: name Type: 9 ()
    # Field: user_email Type: 9 ()
    # Field: display_name Type: 9 ()
    # Field: action Type: 9 ()
    # Field: type Type: 9 ()
    # Field: resource Type: 9 ()
    # Field: create_time Type: 11 (.google.protobuf.Timestamp)
    # Field: language_code Type: 9 ()

# === Service Client: Google::Cloud::Dialogflow::Cx::V3beta1::Changelog::ChangelogsClient ===
package Google::Cloud::Dialogflow::Cx::V3beta1::Changelog::ChangelogsClient;

=pod

=head2 Service Client: Google::Cloud::Dialogflow::Cx::V3beta1::Changelog::ChangelogsClient

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
        ? Google::Cloud::Dialogflow::Cx::V3beta1::Changelog::ListChangelogsRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.dialogflow.cx.v3beta1.Changelogs',
        method         => 'ListChangelogs',
        request        => $req,
        response_class => 'Google::Cloud::Dialogflow::Cx::V3beta1::Changelog::ListChangelogsResponse',
    });
}

sub get_changelog {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Dialogflow::Cx::V3beta1::Changelog::GetChangelogRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.dialogflow.cx.v3beta1.Changelogs',
        method         => 'GetChangelog',
        request        => $req,
        response_class => 'Google::Cloud::Dialogflow::Cx::V3beta1::Changelog::Changelog',
    });
}

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Dialogflow::Cx::V3beta1::Changelog - Compiled Protocol Buffers messages for google/cloud/dialogflow/cx/v3beta1/changelog.proto

=head1 SYNOPSIS

    use Google::Cloud::Dialogflow::Cx::V3beta1::Changelog;

    my $msg = Google::Cloud::Dialogflow::Cx::V3beta1::Changelog::ListChangelogsRequest->new({
        parent => $parent,
        filter => $filter,
        page_size => $page_size,
        page_token => $page_token,
    });

    # Read or update a field
    my $val = $msg->parent();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Dialogflow::Cx::V3beta1::Changelog::ListChangelogsRequest->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/dialogflow/cx/v3beta1/changelog.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Dialogflow::Cx::V3beta1::Changelog::ListChangelogsRequest

The request message for
[Changelogs.ListChangelogs][google.cloud.dialogflow.cx.v3beta1.Changelogs.ListChangelogs].

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

=head2 Google::Cloud::Dialogflow::Cx::V3beta1::Changelog::ListChangelogsResponse

The response message for
[Changelogs.ListChangelogs][google.cloud.dialogflow.cx.v3beta1.Changelogs.ListChangelogs].

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->changelogs() >> / C<< $msg->changelogs($value) >>

Type: C<Message> (L<Google::Cloud::Dialogflow::Cx::V3beta1::Changelog::Changelog>)

The list of changelogs. There will be a maximum number of items returned
based on the page_size field in the request. The changelogs will be ordered
by timestamp.

=item * C<< $msg->next_page_token() >> / C<< $msg->next_page_token($value) >>

Type: C<String>

Token to retrieve the next page of results, or empty if there are no more
results in the list.

=back

=head2 Google::Cloud::Dialogflow::Cx::V3beta1::Changelog::GetChangelogRequest

The request message for
[Changelogs.GetChangelog][google.cloud.dialogflow.cx.v3beta1.Changelogs.GetChangelog].

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. The name of the changelog to get.
Format:
`projects/<ProjectID>/locations/<LocationID>/agents/<AgentID>/changelogs/<ChangelogID>`.

=back

=head2 Google::Cloud::Dialogflow::Cx::V3beta1::Changelog::Changelog

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

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Dialogflow::Cx::V3beta1::Changelog::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
