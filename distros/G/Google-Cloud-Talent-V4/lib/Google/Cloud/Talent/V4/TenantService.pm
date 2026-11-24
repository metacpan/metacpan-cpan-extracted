package Google::Cloud::Talent::V4::TenantService;

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
    eval { require Google::Cloud::Talent::V4::Common };
    eval { require Google::Cloud::Talent::V4::Tenant };
    eval { require Google::Protobuf::Empty };
    eval { require Google::Protobuf::FieldMask };
    my $descriptor_b64 = <<'EOF';
Citnb29nbGUvY2xvdWQvdGFsZW50L3Y0L3RlbmFudF9zZXJ2aWNlLnByb3RvEhZnb29nbGUu
Y2xvdWQudGFsZW50LnY0Ghxnb29nbGUvYXBpL2Fubm90YXRpb25zLnByb3RvGhdnb29nbGUv
YXBpL2NsaWVudC5wcm90bxofZ29vZ2xlL2FwaS9maWVsZF9iZWhhdmlvci5wcm90bxoZZ29v
Z2xlL2FwaS9yZXNvdXJjZS5wcm90bxojZ29vZ2xlL2Nsb3VkL3RhbGVudC92NC9jb21tb24u
cHJvdG8aI2dvb2dsZS9jbG91ZC90YWxlbnQvdjQvdGVuYW50LnByb3RvGhtnb29nbGUvcHJv
dG9idWYvZW1wdHkucHJvdG8aIGdvb2dsZS9wcm90b2J1Zi9maWVsZF9tYXNrLnByb3RvIp8B
ChNDcmVhdGVUZW5hbnRSZXF1ZXN0EksKBnBhcmVudBgBIAEoCUIz4EEC+kEtCitjbG91ZHJl
c291cmNlbWFuYWdlci5nb29nbGVhcGlzLmNvbS9Qcm9qZWN0UgZwYXJlbnQSOwoGdGVuYW50
GAIgASgLMh4uZ29vZ2xlLmNsb3VkLnRhbGVudC52NC5UZW5hbnRCA+BBAlIGdGVuYW50IkoK
EEdldFRlbmFudFJlcXVlc3QSNgoEbmFtZRgBIAEoCUIi4EEC+kEcChpqb2JzLmdvb2dsZWFw
aXMuY29tL1RlbmFudFIEbmFtZSKPAQoTVXBkYXRlVGVuYW50UmVxdWVzdBI7CgZ0ZW5hbnQY
ASABKAsyHi5nb29nbGUuY2xvdWQudGFsZW50LnY0LlRlbmFudEID4EECUgZ0ZW5hbnQSOwoL
dXBkYXRlX21hc2sYAiABKAsyGi5nb29nbGUucHJvdG9idWYuRmllbGRNYXNrUgp1cGRhdGVN
YXNrIk0KE0RlbGV0ZVRlbmFudFJlcXVlc3QSNgoEbmFtZRgBIAEoCUIi4EEC+kEcChpqb2Jz
Lmdvb2dsZWFwaXMuY29tL1RlbmFudFIEbmFtZSKdAQoSTGlzdFRlbmFudHNSZXF1ZXN0EksK
BnBhcmVudBgBIAEoCUIz4EEC+kEtCitjbG91ZHJlc291cmNlbWFuYWdlci5nb29nbGVhcGlz
LmNvbS9Qcm9qZWN0UgZwYXJlbnQSHQoKcGFnZV90b2tlbhgCIAEoCVIJcGFnZVRva2VuEhsK
CXBhZ2Vfc2l6ZRgDIAEoBVIIcGFnZVNpemUivQEKE0xpc3RUZW5hbnRzUmVzcG9uc2USOAoH
dGVuYW50cxgBIAMoCzIeLmdvb2dsZS5jbG91ZC50YWxlbnQudjQuVGVuYW50Ugd0ZW5hbnRz
EiYKD25leHRfcGFnZV90b2tlbhgCIAEoCVINbmV4dFBhZ2VUb2tlbhJECghtZXRhZGF0YRgD
IAEoCzIoLmdvb2dsZS5jbG91ZC50YWxlbnQudjQuUmVzcG9uc2VNZXRhZGF0YVIIbWV0YWRh
dGEy8AYKDVRlbmFudFNlcnZpY2USnAEKDENyZWF0ZVRlbmFudBIrLmdvb2dsZS5jbG91ZC50
YWxlbnQudjQuQ3JlYXRlVGVuYW50UmVxdWVzdBoeLmdvb2dsZS5jbG91ZC50YWxlbnQudjQu
VGVuYW50Ij+C0+STAikiHy92NC97cGFyZW50PXByb2plY3RzLyp9L3RlbmFudHM6BnRlbmFu
dNpBDXBhcmVudCx0ZW5hbnQShQEKCUdldFRlbmFudBIoLmdvb2dsZS5jbG91ZC50YWxlbnQu
djQuR2V0VGVuYW50UmVxdWVzdBoeLmdvb2dsZS5jbG91ZC50YWxlbnQudjQuVGVuYW50Ii6C
0+STAiESHy92NC97bmFtZT1wcm9qZWN0cy8qL3RlbmFudHMvKn3aQQRuYW1lEqgBCgxVcGRh
dGVUZW5hbnQSKy5nb29nbGUuY2xvdWQudGFsZW50LnY0LlVwZGF0ZVRlbmFudFJlcXVlc3Qa
Hi5nb29nbGUuY2xvdWQudGFsZW50LnY0LlRlbmFudCJLgtPkkwIwMiYvdjQve3RlbmFudC5u
YW1lPXByb2plY3RzLyovdGVuYW50cy8qfToGdGVuYW502kESdGVuYW50LHVwZGF0ZV9tYXNr
EoMBCgxEZWxldGVUZW5hbnQSKy5nb29nbGUuY2xvdWQudGFsZW50LnY0LkRlbGV0ZVRlbmFu
dFJlcXVlc3QaFi5nb29nbGUucHJvdG9idWYuRW1wdHkiLoLT5JMCISofL3Y0L3tuYW1lPXBy
b2plY3RzLyovdGVuYW50cy8qfdpBBG5hbWUSmAEKC0xpc3RUZW5hbnRzEiouZ29vZ2xlLmNs
b3VkLnRhbGVudC52NC5MaXN0VGVuYW50c1JlcXVlc3QaKy5nb29nbGUuY2xvdWQudGFsZW50
LnY0Lkxpc3RUZW5hbnRzUmVzcG9uc2UiMILT5JMCIRIfL3Y0L3twYXJlbnQ9cHJvamVjdHMv
Kn0vdGVuYW50c9pBBnBhcmVudBpsykETam9icy5nb29nbGVhcGlzLmNvbdJBU2h0dHBzOi8v
d3d3Lmdvb2dsZWFwaXMuY29tL2F1dGgvY2xvdWQtcGxhdGZvcm0saHR0cHM6Ly93d3cuZ29v
Z2xlYXBpcy5jb20vYXV0aC9qb2JzQmwKGmNvbS5nb29nbGUuY2xvdWQudGFsZW50LnY0QhJU
ZW5hbnRTZXJ2aWNlUHJvdG9QAVoyY2xvdWQuZ29vZ2xlLmNvbS9nby90YWxlbnQvYXBpdjQv
dGFsZW50cGI7dGFsZW50cGKiAgNDVFNKjiQKBxIFDgCuAQEKvAQKAQwSAw4AEjKxBCBDb3B5
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
ZXIgdGhlIExpY2Vuc2UuCgoICgECEgMQAB8KCQoCAwASAxIAJgoJCgIDARIDEwAhCgkKAgMC
EgMUACkKCQoCAwMSAxUAIwoJCgIDBBIDFgAtCgkKAgMFEgMXAC0KCQoCAwYSAxgAJQoJCgID
BxIDGQAqCggKAQgSAxsASQoJCgIICxIDGwBJCggKAQgSAxwAIgoJCgIIChIDHAAiCggKAQgS
Ax0AMwoJCgIICBIDHQAzCggKAQgSAx4AMwoJCgIIARIDHgAzCggKAQgSAx8AIQoJCgIIJBID
HwAhClcKAgYAEgQiAFEBGksgQSBzZXJ2aWNlIHRoYXQgaGFuZGxlcyB0ZW5hbnQgbWFuYWdl
bWVudCwgaW5jbHVkaW5nIENSVUQgYW5kIGVudW1lcmF0aW9uLgoKCgoDBgABEgMiCBUKCgoD
BgADEgMjAjsKDAoFBgADmQgSAyMCOwoLCgMGAAMSBCQCJi0KDQoFBgADmggSBCQCJi0KLAoE
BgACABIEKQIvAxoeIENyZWF0ZXMgYSBuZXcgdGVuYW50IGVudGl0eS4KCgwKBQYAAgABEgMp
BhIKDAoFBgACAAISAykTJgoMCgUGAAIAAxIDKTE3Cg0KBQYAAgAEEgQqBC0GChEKCQYAAgAE
sMq8IhIEKgQtBgoMCgUGAAIABBIDLgQ7Cg8KCAYAAgAEmwgAEgMuBDsKKwoEBgACARIEMgI3
AxodIFJldHJpZXZlcyBzcGVjaWZpZWQgdGVuYW50LgoKDAoFBgACAQESAzIGDwoMCgUGAAIB
AhIDMhAgCgwKBQYAAgEDEgMyKzEKDQoFBgACAQQSBDMENQYKEQoJBgACAQSwyrwiEgQzBDUG
CgwKBQYAAgEEEgM2BDIKDwoIBgACAQSbCAASAzYEMgopCgQGAAICEgQ6AkADGhsgVXBkYXRl
cyBzcGVjaWZpZWQgdGVuYW50LgoKDAoFBgACAgESAzoGEgoMCgUGAAICAhIDOhMmCgwKBQYA
AgIDEgM6MTcKDQoFBgACAgQSBDsEPgYKEQoJBgACAgSwyrwiEgQ7BD4GCgwKBQYAAgIEEgM/
BEAKDwoIBgACAgSbCAASAz8EQAopCgQGAAIDEgRDAkgDGhsgRGVsZXRlcyBzcGVjaWZpZWQg
dGVuYW50LgoKDAoFBgACAwESA0MGEgoMCgUGAAIDAhIDQxMmCgwKBQYAAgMDEgNDMUYKDQoF
BgACAwQSBEQERgYKEQoJBgACAwSwyrwiEgREBEYGCgwKBQYAAgMEEgNHBDIKDwoIBgACAwSb
CAASA0cEMgo+CgQGAAIEEgRLAlADGjAgTGlzdHMgYWxsIHRlbmFudHMgYXNzb2NpYXRlZCB3
aXRoIHRoZSBwcm9qZWN0LgoKDAoFBgACBAESA0sGEQoMCgUGAAIEAhIDSxIkCgwKBQYAAgQD
EgNLL0IKDQoFBgACBAQSBEwETgYKEQoJBgACBASwyrwiEgRMBE4GCgwKBQYAAgQEEgNPBDQK
DwoIBgACBASbCAASA08ENAo1CgIEABIEVABiARopIFRoZSBSZXF1ZXN0IG9mIHRoZSBDcmVh
dGVUZW5hbnQgbWV0aG9kLgoKCgoDBAABEgNUCBsKoQEKBAQAAgASBFkCXgQakgEgUmVxdWly
ZWQuIFJlc291cmNlIG5hbWUgb2YgdGhlIHByb2plY3QgdW5kZXIgd2hpY2ggdGhlIHRlbmFu
dCBpcyBjcmVhdGVkLgoKIFRoZSBmb3JtYXQgaXMgInByb2plY3RzL3twcm9qZWN0X2lkfSIs
IGZvciBleGFtcGxlLAogInByb2plY3RzL2ZvbyIuCgoMCgUEAAIABRIDWQIICgwKBQQAAgAB
EgNZCQ8KDAoFBAACAAMSA1kSEwoNCgUEAAIACBIEWRReAwoPCggEAAIACJwIABIDWgQqCg8K
BwQAAgAInwgSBFsEXQUKMgoEBAACARIDYQI9GiUgUmVxdWlyZWQuIFRoZSB0ZW5hbnQgdG8g
YmUgY3JlYXRlZC4KCgwKBQQAAgEGEgNhAggKDAoFBAACAQESA2EJDwoMCgUEAAIBAxIDYRIT
CgwKBQQAAgEIEgNhFDwKDwoIBAACAQicCAASA2EVOwozCgIEARIEZQBuARonIFJlcXVlc3Qg
Zm9yIGdldHRpbmcgYSB0ZW5hbnQgYnkgbmFtZS4KCgoKAwQBARIDZQgYCrIBCgQEAQIAEgRq
Am0EGqMBIFJlcXVpcmVkLiBUaGUgcmVzb3VyY2UgbmFtZSBvZiB0aGUgdGVuYW50IHRvIGJl
IHJldHJpZXZlZC4KCiBUaGUgZm9ybWF0IGlzICJwcm9qZWN0cy97cHJvamVjdF9pZH0vdGVu
YW50cy97dGVuYW50X2lkfSIsIGZvciBleGFtcGxlLAogInByb2plY3RzL2Zvby90ZW5hbnRz
L2JhciIuCgoMCgUEAQIABRIDagIICgwKBQQBAgABEgNqCQ0KDAoFBAECAAMSA2oQEQoNCgUE
AQIACBIEahJtAwoPCggEAQIACJwIABIDawQqCg4KBwQBAgAInwgSA2wETAo3CgIEAhIFcQCA
AQEaKiBSZXF1ZXN0IGZvciB1cGRhdGluZyBhIHNwZWNpZmllZCB0ZW5hbnQuCgoKCgMEAgES
A3EIGwpcCgQEAgIAEgN0Aj0aTyBSZXF1aXJlZC4gVGhlIHRlbmFudCByZXNvdXJjZSB0byBy
ZXBsYWNlIHRoZSBjdXJyZW50IHJlc291cmNlIGluIHRoZQogc3lzdGVtLgoKDAoFBAICAAYS
A3QCCAoMCgUEAgIAARIDdAkPCgwKBQQCAgADEgN0EhMKDAoFBAICAAgSA3QUPAoPCggEAgIA
CJwIABIDdBU7CrgDCgQEAgIBEgN/AiwaqgMgU3Ryb25nbHkgcmVjb21tZW5kZWQgZm9yIHRo
ZSBiZXN0IHNlcnZpY2UgZXhwZXJpZW5jZS4KCiBJZiBbdXBkYXRlX21hc2tdW2dvb2dsZS5j
bG91ZC50YWxlbnQudjQuVXBkYXRlVGVuYW50UmVxdWVzdC51cGRhdGVfbWFza10gaXMKIHBy
b3ZpZGVkLCBvbmx5IHRoZSBzcGVjaWZpZWQgZmllbGRzIGluCiBbdGVuYW50XVtnb29nbGUu
Y2xvdWQudGFsZW50LnY0LlVwZGF0ZVRlbmFudFJlcXVlc3QudGVuYW50XSBhcmUgdXBkYXRl
ZC4KIE90aGVyd2lzZSBhbGwgdGhlIGZpZWxkcyBhcmUgdXBkYXRlZC4KCiBBIGZpZWxkIG1h
c2sgdG8gc3BlY2lmeSB0aGUgdGVuYW50IGZpZWxkcyB0byBiZSB1cGRhdGVkLiBPbmx5CiB0
b3AgbGV2ZWwgZmllbGRzIG9mIFtUZW5hbnRdW2dvb2dsZS5jbG91ZC50YWxlbnQudjQuVGVu
YW50XSBhcmUgc3VwcG9ydGVkLgoKDAoFBAICAQYSA38CGwoMCgUEAgIBARIDfxwnCgwKBQQC
AgEDEgN/KisKKwoCBAMSBoMBAIwBARodIFJlcXVlc3QgdG8gZGVsZXRlIGEgdGVuYW50LgoK
CwoDBAMBEgSDAQgbCrIBCgQEAwIAEgaIAQKLAQQaoQEgUmVxdWlyZWQuIFRoZSByZXNvdXJj
ZSBuYW1lIG9mIHRoZSB0ZW5hbnQgdG8gYmUgZGVsZXRlZC4KCiBUaGUgZm9ybWF0IGlzICJw
cm9qZWN0cy97cHJvamVjdF9pZH0vdGVuYW50cy97dGVuYW50X2lkfSIsIGZvciBleGFtcGxl
LAogInByb2plY3RzL2Zvby90ZW5hbnRzL2JhciIuCgoNCgUEAwIABRIEiAECCAoNCgUEAwIA
ARIEiAEJDQoNCgUEAwIAAxIEiAEQEQoPCgUEAwIACBIGiAESiwEDChAKCAQDAgAInAgAEgSJ
AQQqCg8KBwQDAgAInwgSBIoBBEwKRQoCBAQSBo8BAKEBARo3IExpc3QgdGVuYW50cyBmb3Ig
d2hpY2ggdGhlIGNsaWVudCBoYXMgQUNMIHZpc2liaWxpdHkuCgoLCgMEBAESBI8BCBoKowEK
BAQEAgASBpQBApkBBBqSASBSZXF1aXJlZC4gUmVzb3VyY2UgbmFtZSBvZiB0aGUgcHJvamVj
dCB1bmRlciB3aGljaCB0aGUgdGVuYW50IGlzIGNyZWF0ZWQuCgogVGhlIGZvcm1hdCBpcyAi
cHJvamVjdHMve3Byb2plY3RfaWR9IiwgZm9yIGV4YW1wbGUsCiAicHJvamVjdHMvZm9vIi4K
Cg0KBQQEAgAFEgSUAQIICg0KBQQEAgABEgSUAQkPCg0KBQQEAgADEgSUARITCg8KBQQEAgAI
EgaUARSZAQMKEAoIBAQCAAicCAASBJUBBCoKEQoHBAQCAAifCBIGlgEEmAEFCkQKBAQEAgES
BJwBAhgaNiBUaGUgc3RhcnRpbmcgaW5kaWNhdG9yIGZyb20gd2hpY2ggdG8gcmV0dXJuIHJl
c3VsdHMuCgoNCgUEBAIBBRIEnAECCAoNCgUEBAIBARIEnAEJEwoNCgUEBAIBAxIEnAEWFwqA
AQoEBAQCAhIEoAECFhpyIFRoZSBtYXhpbXVtIG51bWJlciBvZiB0ZW5hbnRzIHRvIGJlIHJl
dHVybmVkLCBhdCBtb3N0IDEwMC4KIERlZmF1bHQgaXMgMTAwIGlmIGEgbm9uLXBvc2l0aXZl
IG51bWJlciBpcyBwcm92aWRlZC4KCg0KBQQEAgIFEgSgAQIHCg0KBQQEAgIBEgSgAQgRCg0K
BQQEAgIDEgSgARQVCjEKAgQFEgakAQCuAQEaIyBUaGUgTGlzdCB0ZW5hbnRzIHJlc3BvbnNl
IG9iamVjdC4KCgsKAwQFARIEpAEIGwovCgQEBQIAEgSmAQIeGiEgVGVuYW50cyBmb3IgdGhl
IGN1cnJlbnQgY2xpZW50LgoKDQoFBAUCAAQSBKYBAgoKDQoFBAUCAAYSBKYBCxEKDQoFBAUC
AAESBKYBEhkKDQoFBAUCAAMSBKYBHB0KPQoEBAUCARIEqQECHRovIEEgdG9rZW4gdG8gcmV0
cmlldmUgdGhlIG5leHQgcGFnZSBvZiByZXN1bHRzLgoKDQoFBAUCAQUSBKkBAggKDQoFBAUC
AQESBKkBCRgKDQoFBAUCAQMSBKkBGxwKYAoEBAUCAhIErQECIBpSIEFkZGl0aW9uYWwgaW5m
b3JtYXRpb24gZm9yIHRoZSBBUEkgaW52b2NhdGlvbiwgc3VjaCBhcyB0aGUgcmVxdWVzdAog
dHJhY2tpbmcgaWQuCgoNCgUEBQICBhIErQECEgoNCgUEBQICARIErQETGwoNCgUEBQICAxIE
rQEeH2IGcHJvdG8z
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Talent::V4::TenantService::CreateTenantRequest ===
    # Fields for CreateTenantRequest
    # Field: parent Type: 9 ()
    # Field: tenant Type: 11 (.google.cloud.talent.v4.Tenant)

# === Message: Google::Cloud::Talent::V4::TenantService::GetTenantRequest ===
    # Fields for GetTenantRequest
    # Field: name Type: 9 ()

# === Message: Google::Cloud::Talent::V4::TenantService::UpdateTenantRequest ===
    # Fields for UpdateTenantRequest
    # Field: tenant Type: 11 (.google.cloud.talent.v4.Tenant)
    # Field: update_mask Type: 11 (.google.protobuf.FieldMask)

# === Message: Google::Cloud::Talent::V4::TenantService::DeleteTenantRequest ===
    # Fields for DeleteTenantRequest
    # Field: name Type: 9 ()

# === Message: Google::Cloud::Talent::V4::TenantService::ListTenantsRequest ===
    # Fields for ListTenantsRequest
    # Field: parent Type: 9 ()
    # Field: page_token Type: 9 ()
    # Field: page_size Type: 5 ()

# === Message: Google::Cloud::Talent::V4::TenantService::ListTenantsResponse ===
    # Fields for ListTenantsResponse
    # Field: tenants Type: 11 (.google.cloud.talent.v4.Tenant)
    # Field: next_page_token Type: 9 ()
    # Field: metadata Type: 11 (.google.cloud.talent.v4.ResponseMetadata)

# === Service Client: Google::Cloud::Talent::V4::TenantService::TenantServiceClient ===
package Google::Cloud::Talent::V4::TenantService::TenantServiceClient;

=pod

=head2 Service Client: Google::Cloud::Talent::V4::TenantService::TenantServiceClient

Client stub representing the remote C<TenantService> gRPC service. Delegates call dispatching to L<Google::gRPC::Client>.

=head3 target

The endpoint target address. Defaults to C<talent.googleapis.com:443>.

=head3 credentials

The authentication credentials provider. Defaults to application default credentials via L<Google::Auth>.

=cut

use Moo;
use Google::Auth;
use Google::gRPC::Client;

has credentials => ( is => 'ro', default => sub { Google::Auth->default() } );
has target      => ( is => 'ro', default => 'talent.googleapis.com:443' );

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

sub create_tenant {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Talent::V4::TenantService::CreateTenantRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.talent.v4.TenantService',
        method         => 'CreateTenant',
        request        => $req,
        response_class => 'Google::Cloud::Talent::V4::Tenant::Tenant',
    });
}

sub get_tenant {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Talent::V4::TenantService::GetTenantRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.talent.v4.TenantService',
        method         => 'GetTenant',
        request        => $req,
        response_class => 'Google::Cloud::Talent::V4::Tenant::Tenant',
    });
}

sub update_tenant {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Talent::V4::TenantService::UpdateTenantRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.talent.v4.TenantService',
        method         => 'UpdateTenant',
        request        => $req,
        response_class => 'Google::Cloud::Talent::V4::Tenant::Tenant',
    });
}

sub delete_tenant {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Talent::V4::TenantService::DeleteTenantRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.talent.v4.TenantService',
        method         => 'DeleteTenant',
        request        => $req,
        response_class => 'Google::Protobuf::Empty::Empty',
    });
}

sub list_tenants {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Talent::V4::TenantService::ListTenantsRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.talent.v4.TenantService',
        method         => 'ListTenants',
        request        => $req,
        response_class => 'Google::Cloud::Talent::V4::TenantService::ListTenantsResponse',
    });
}

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Talent::V4::TenantService - Compiled Protocol Buffers messages for google/cloud/talent/v4/tenant_service.proto

=head1 SYNOPSIS

    use Google::Cloud::Talent::V4::TenantService;

    my $msg = Google::Cloud::Talent::V4::TenantService::CreateTenantRequest->new({
        parent => $parent,
        tenant => $tenant,
    });

    # Read or update a field
    my $val = $msg->parent();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Talent::V4::TenantService::CreateTenantRequest->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/talent/v4/tenant_service.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Talent::V4::TenantService::CreateTenantRequest

The Request of the CreateTenant method.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->parent() >> / C<< $msg->parent($value) >>

Type: C<String>

Required. Resource name of the project under which the tenant is created.

The format is "projects/{project_id}", for example,
"projects/foo".

=item * C<< $msg->tenant() >> / C<< $msg->tenant($value) >>

Type: C<Message> (L<Google::Cloud::Talent::V4::Tenant::Tenant>)

Required. The tenant to be created.

=back

=head2 Google::Cloud::Talent::V4::TenantService::GetTenantRequest

Request for getting a tenant by name.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. The resource name of the tenant to be retrieved.

The format is "projects/{project_id}/tenants/{tenant_id}", for example,
"projects/foo/tenants/bar".

=back

=head2 Google::Cloud::Talent::V4::TenantService::UpdateTenantRequest

Request for updating a specified tenant.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->tenant() >> / C<< $msg->tenant($value) >>

Type: C<Message> (L<Google::Cloud::Talent::V4::Tenant::Tenant>)

Required. The tenant resource to replace the current resource in the
system.

=item * C<< $msg->update_mask() >> / C<< $msg->update_mask($value) >>

Type: C<Message> (L<Google::Protobuf::FieldMask::FieldMask>)

Strongly recommended for the best service experience.

If [update_mask][google.cloud.talent.v4.UpdateTenantRequest.update_mask] is
provided, only the specified fields in
[tenant][google.cloud.talent.v4.UpdateTenantRequest.tenant] are updated.
Otherwise all the fields are updated.

A field mask to specify the tenant fields to be updated. Only
top level fields of [Tenant][google.cloud.talent.v4.Tenant] are supported.

=back

=head2 Google::Cloud::Talent::V4::TenantService::DeleteTenantRequest

Request to delete a tenant.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. The resource name of the tenant to be deleted.

The format is "projects/{project_id}/tenants/{tenant_id}", for example,
"projects/foo/tenants/bar".

=back

=head2 Google::Cloud::Talent::V4::TenantService::ListTenantsRequest

List tenants for which the client has ACL visibility.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->parent() >> / C<< $msg->parent($value) >>

Type: C<String>

Required. Resource name of the project under which the tenant is created.

The format is "projects/{project_id}", for example,
"projects/foo".

=item * C<< $msg->page_token() >> / C<< $msg->page_token($value) >>

Type: C<String>

The starting indicator from which to return results.

=item * C<< $msg->page_size() >> / C<< $msg->page_size($value) >>

Type: C<Int32>

The maximum number of tenants to be returned, at most 100.
Default is 100 if a non-positive number is provided.

=back

=head2 Google::Cloud::Talent::V4::TenantService::ListTenantsResponse

The List tenants response object.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->tenants() >> / C<< $msg->tenants($value) >>

Type: C<Message> (L<Google::Cloud::Talent::V4::Tenant::Tenant>)

Tenants for the current client.

=item * C<< $msg->next_page_token() >> / C<< $msg->next_page_token($value) >>

Type: C<String>

A token to retrieve the next page of results.

=item * C<< $msg->metadata() >> / C<< $msg->metadata($value) >>

Type: C<Message> (L<Google::Cloud::Talent::V4::Common::ResponseMetadata>)

Additional information for the API invocation, such as the request
tracking id.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Talent::V4::TenantService::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
