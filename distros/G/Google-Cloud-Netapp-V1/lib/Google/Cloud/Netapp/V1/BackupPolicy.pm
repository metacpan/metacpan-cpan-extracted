package Google::Cloud::Netapp::V1::BackupPolicy;

use strict;
use warnings;

our $VERSION = '0.14';

use Protobuf::Message;
use Protobuf::DescriptorPool;
use Protobuf::Internal qw(:all);
use MIME::Base64;

BEGIN {
    eval { require Google::Api::FieldBehavior };
    eval { require Google::Api::Resource };
    eval { require Google::Protobuf::FieldMask };
    eval { require Google::Protobuf::Timestamp };
    my $descriptor_b64 = <<'EOF';
Cipnb29nbGUvY2xvdWQvbmV0YXBwL3YxL2JhY2t1cF9wb2xpY3kucHJvdG8SFmdvb2dsZS5j
bG91ZC5uZXRhcHAudjEaH2dvb2dsZS9hcGkvZmllbGRfYmVoYXZpb3IucHJvdG8aGWdvb2ds
ZS9hcGkvcmVzb3VyY2UucHJvdG8aIGdvb2dsZS9wcm90b2J1Zi9maWVsZF9tYXNrLnByb3Rv
Gh9nb29nbGUvcHJvdG9idWYvdGltZXN0YW1wLnByb3RvIscHCgxCYWNrdXBQb2xpY3kSFwoE
bmFtZRgBIAEoCUID4EEIUgRuYW1lEjEKEmRhaWx5X2JhY2t1cF9saW1pdBgCIAEoBUgAUhBk
YWlseUJhY2t1cExpbWl0iAEBEjMKE3dlZWtseV9iYWNrdXBfbGltaXQYAyABKAVIAVIRd2Vl
a2x5QmFja3VwTGltaXSIAQESNQoUbW9udGhseV9iYWNrdXBfbGltaXQYBCABKAVIAlISbW9u
dGhseUJhY2t1cExpbWl0iAEBEiUKC2Rlc2NyaXB0aW9uGAUgASgJSANSC2Rlc2NyaXB0aW9u
iAEBEh0KB2VuYWJsZWQYBiABKAhIBFIHZW5hYmxlZIgBARI8ChVhc3NpZ25lZF92b2x1bWVf
Y291bnQYByABKAVCA+BBA0gFUhNhc3NpZ25lZFZvbHVtZUNvdW50iAEBEkAKC2NyZWF0ZV90
aW1lGAggASgLMhouZ29vZ2xlLnByb3RvYnVmLlRpbWVzdGFtcEID4EEDUgpjcmVhdGVUaW1l
EkgKBmxhYmVscxgJIAMoCzIwLmdvb2dsZS5jbG91ZC5uZXRhcHAudjEuQmFja3VwUG9saWN5
LkxhYmVsc0VudHJ5UgZsYWJlbHMSRQoFc3RhdGUYCiABKA4yKi5nb29nbGUuY2xvdWQubmV0
YXBwLnYxLkJhY2t1cFBvbGljeS5TdGF0ZUID4EEDUgVzdGF0ZRo5CgtMYWJlbHNFbnRyeRIQ
CgNrZXkYASABKAlSA2tleRIUCgV2YWx1ZRgCIAEoCVIFdmFsdWU6AjgBIl4KBVN0YXRlEhUK
EVNUQVRFX1VOU1BFQ0lGSUVEEAASDAoIQ1JFQVRJTkcQARIJCgVSRUFEWRACEgwKCERFTEVU
SU5HEAMSCQoFRVJST1IQBBIMCghVUERBVElORxAFOo4B6kGKAQoibmV0YXBwLmdvb2dsZWFw
aXMuY29tL0JhY2t1cFBvbGljeRJGcHJvamVjdHMve3Byb2plY3R9L2xvY2F0aW9ucy97bG9j
YXRpb259L2JhY2t1cFBvbGljaWVzL3tiYWNrdXBfcG9saWN5fSoOYmFja3VwUG9saWNpZXMy
DGJhY2t1cFBvbGljeUIVChNfZGFpbHlfYmFja3VwX2xpbWl0QhYKFF93ZWVrbHlfYmFja3Vw
X2xpbWl0QhcKFV9tb250aGx5X2JhY2t1cF9saW1pdEIOCgxfZGVzY3JpcHRpb25CCgoIX2Vu
YWJsZWRCGAoWX2Fzc2lnbmVkX3ZvbHVtZV9jb3VudCLeAQoZQ3JlYXRlQmFja3VwUG9saWN5
UmVxdWVzdBJCCgZwYXJlbnQYASABKAlCKuBBAvpBJBIibmV0YXBwLmdvb2dsZWFwaXMuY29t
L0JhY2t1cFBvbGljeVIGcGFyZW50Ek4KDWJhY2t1cF9wb2xpY3kYAiABKAsyJC5nb29nbGUu
Y2xvdWQubmV0YXBwLnYxLkJhY2t1cFBvbGljeUID4EECUgxiYWNrdXBQb2xpY3kSLQoQYmFj
a3VwX3BvbGljeV9pZBgDIAEoCUID4EECUg5iYWNrdXBQb2xpY3lJZCJYChZHZXRCYWNrdXBQ
b2xpY3lSZXF1ZXN0Ej4KBG5hbWUYASABKAlCKuBBAvpBJAoibmV0YXBwLmdvb2dsZWFwaXMu
Y29tL0JhY2t1cFBvbGljeVIEbmFtZSLOAQoZTGlzdEJhY2t1cFBvbGljaWVzUmVxdWVzdBJC
CgZwYXJlbnQYASABKAlCKuBBAvpBJBIibmV0YXBwLmdvb2dsZWFwaXMuY29tL0JhY2t1cFBv
bGljeVIGcGFyZW50EhsKCXBhZ2Vfc2l6ZRgCIAEoBVIIcGFnZVNpemUSHQoKcGFnZV90b2tl
bhgDIAEoCVIJcGFnZVRva2VuEhYKBmZpbHRlchgEIAEoCVIGZmlsdGVyEhkKCG9yZGVyX2J5
GAUgASgJUgdvcmRlckJ5IrUBChpMaXN0QmFja3VwUG9saWNpZXNSZXNwb25zZRJNCg9iYWNr
dXBfcG9saWNpZXMYASADKAsyJC5nb29nbGUuY2xvdWQubmV0YXBwLnYxLkJhY2t1cFBvbGlj
eVIOYmFja3VwUG9saWNpZXMSJgoPbmV4dF9wYWdlX3Rva2VuGAIgASgJUg1uZXh0UGFnZVRv
a2VuEiAKC3VucmVhY2hhYmxlGAMgAygJUgt1bnJlYWNoYWJsZSKtAQoZVXBkYXRlQmFja3Vw
UG9saWN5UmVxdWVzdBJACgt1cGRhdGVfbWFzaxgBIAEoCzIaLmdvb2dsZS5wcm90b2J1Zi5G
aWVsZE1hc2tCA+BBAlIKdXBkYXRlTWFzaxJOCg1iYWNrdXBfcG9saWN5GAIgASgLMiQuZ29v
Z2xlLmNsb3VkLm5ldGFwcC52MS5CYWNrdXBQb2xpY3lCA+BBAlIMYmFja3VwUG9saWN5IlsK
GURlbGV0ZUJhY2t1cFBvbGljeVJlcXVlc3QSPgoEbmFtZRgBIAEoCUIq4EEC+kEkCiJuZXRh
cHAuZ29vZ2xlYXBpcy5jb20vQmFja3VwUG9saWN5UgRuYW1lQrMBChpjb20uZ29vZ2xlLmNs
b3VkLm5ldGFwcC52MUIRQmFja3VwUG9saWN5UHJvdG9QAVoyY2xvdWQuZ29vZ2xlLmNvbS9n
by9uZXRhcHAvYXBpdjEvbmV0YXBwcGI7bmV0YXBwcGKqAhZHb29nbGUuQ2xvdWQuTmV0QXBw
LlYxygIWR29vZ2xlXENsb3VkXE5ldEFwcFxWMeoCGUdvb2dsZTo6Q2xvdWQ6Ok5ldEFwcDo6
VjFK7TEKBxIFDgDCAQEKvAQKAQwSAw4AEjKxBCBDb3B5cmlnaHQgMjAyNiBHb29nbGUgTExD
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
EgMQAB8KCQoCAwASAxIAKQoJCgIDARIDEwAjCgkKAgMCEgMUACoKCQoCAwMSAxUAKQoICgEI
EgMXADMKCQoCCCUSAxcAMwoICgEIEgMYAEkKCQoCCAsSAxgASQoICgEIEgMZACIKCQoCCAoS
AxkAIgoICgEIEgMaADIKCQoCCAgSAxoAMgoICgEIEgMbADMKCQoCCAESAxsAMwoICgEIEgMc
ADMKCQoCCCkSAxwAMwoICgEIEgMdADIKCQoCCC0SAx0AMgocCgIEABIEIABiARoQIEJhY2t1
cCBQb2xpY3kuCgoKCgMEAAESAyAIFAoLCgMEAAcSBCECJgQKDQoFBAAHnQgSBCECJgQKDAoE
BAAEABIEKAI6AwoMCgUEAAQAARIDKAcMCh8KBgQABAACABIDKgQaGhAgU3RhdGUgbm90IHNl
dC4KCg4KBwQABAACAAESAyoEFQoOCgcEAAQAAgACEgMqGBkKLwoGBAAEAAIBEgMtBBEaICBC
YWNrdXBQb2xpY3kgaXMgYmVpbmcgY3JlYXRlZC4KCg4KBwQABAACAQESAy0EDAoOCgcEAAQA
AgECEgMtDxAKMwoGBAAEAAICEgMwBA4aJCBCYWNrdXBQb2xpY3kgaXMgYXZhaWxhYmxlIGZv
ciB1c2UuCgoOCgcEAAQAAgIBEgMwBAkKDgoHBAAEAAICAhIDMAwNCi8KBgQABAACAxIDMwQR
GiAgQmFja3VwUG9saWN5IGlzIGJlaW5nIGRlbGV0ZWQuCgoOCgcEAAQAAgMBEgMzBAwKDgoH
BAAEAAIDAhIDMw8QCj4KBgQABAACBBIDNgQOGi8gQmFja3VwUG9saWN5IGlzIG5vdCB2YWxp
ZCBhbmQgY2Fubm90IGJlIHVzZWQuCgoOCgcEAAQAAgQBEgM2BAkKDgoHBAAEAAIEAhIDNgwN
Ci8KBgQABAACBRIDOQQRGiAgQmFja3VwUG9saWN5IGlzIGJlaW5nIHVwZGF0ZWQuCgoOCgcE
AAQAAgUBEgM5BAwKDgoHBAAEAAIFAhIDOQ8QCp0BCgQEAAIAEgM/Aj0ajwEgSWRlbnRpZmll
ci4gVGhlIHJlc291cmNlIG5hbWUgb2YgdGhlIGJhY2t1cCBwb2xpY3kuCiBGb3JtYXQ6CiBg
cHJvamVjdHMve3Byb2plY3RfaWR9L2xvY2F0aW9ucy97bG9jYXRpb259L2JhY2t1cFBvbGlj
aWVzL3tiYWNrdXBfcG9saWN5X2lkfWAuCgoMCgUEAAIABRIDPwIICgwKBQQAAgABEgM/CQ0K
DAoFBAACAAMSAz8QEQoMCgUEAAIACBIDPxI8Cg8KCAQAAgAInAgAEgM/EzsKXwoEBAACARID
QwIoGlIgTnVtYmVyIG9mIGRhaWx5IGJhY2t1cHMgdG8ga2VlcC4gTm90ZSB0aGF0IHRoZSBt
aW5pbXVtIGRhaWx5IGJhY2t1cCBsaW1pdAogaXMgMi4KCgwKBQQAAgEEEgNDAgoKDAoFBAAC
AQUSA0MLEAoMCgUEAAIBARIDQxEjCgwKBQQAAgEDEgNDJicKggEKBAQAAgISA0cCKRp1IE51
bWJlciBvZiB3ZWVrbHkgYmFja3VwcyB0byBrZWVwLiBOb3RlIHRoYXQgdGhlIHN1bSBvZiBk
YWlseSwgd2Vla2x5IGFuZAogbW9udGhseSBiYWNrdXBzIHNob3VsZCBiZSBncmVhdGVyIHRo
YW4gMS4KCgwKBQQAAgIEEgNHAgoKDAoFBAACAgUSA0cLEAoMCgUEAAICARIDRxEkCgwKBQQA
AgIDEgNHJygKgwEKBAQAAgMSA0sCKhp2IE51bWJlciBvZiBtb250aGx5IGJhY2t1cHMgdG8g
a2VlcC4gTm90ZSB0aGF0IHRoZSBzdW0gb2YgZGFpbHksIHdlZWtseSBhbmQKIG1vbnRobHkg
YmFja3VwcyBzaG91bGQgYmUgZ3JlYXRlciB0aGFuIDEuCgoMCgUEAAIDBBIDSwIKCgwKBQQA
AgMFEgNLCxAKDAoFBAACAwESA0sRJQoMCgUEAAIDAxIDSygpCjAKBAQAAgQSA04CIhojIERl
c2NyaXB0aW9uIG9mIHRoZSBiYWNrdXAgcG9saWN5LgoKDAoFBAACBAQSA04CCgoMCgUEAAIE
BRIDTgsRCgwKBQQAAgQBEgNOEh0KDAoFBAACBAMSA04gIQrYAQoEBAACBRIDUwIcGsoBIElm
IGVuYWJsZWQsIG1ha2UgYmFja3VwcyBhdXRvbWF0aWNhbGx5IGFjY29yZGluZyB0byB0aGUg
c2NoZWR1bGVzLgogVGhpcyB3aWxsIGJlIGFwcGxpZWQgdG8gYWxsIHZvbHVtZXMgdGhhdCBo
YXZlIHRoaXMgcG9saWN5IGF0dGFjaGVkIGFuZAogZW5mb3JjZWQgb24gdm9sdW1lIGxldmVs
LiBJZiBub3Qgc3BlY2lmaWVkLCBkZWZhdWx0IGlzIHRydWUuCgoMCgUEAAIFBBIDUwIKCgwK
BQQAAgUFEgNTCw8KDAoFBAACBQESA1MQFwoMCgUEAAIFAxIDUxobClgKBAQAAgYSBFYCVzIa
SiBPdXRwdXQgb25seS4gVGhlIHRvdGFsIG51bWJlciBvZiB2b2x1bWVzIGFzc2lnbmVkIGJ5
IHRoaXMgYmFja3VwIHBvbGljeS4KCgwKBQQAAgYEEgNWAgoKDAoFBAACBgUSA1YLEAoMCgUE
AAIGARIDVhEmCgwKBQQAAgYDEgNWKSoKDAoFBAACBggSA1cGMQoPCggEAAIGCJwIABIDVwcw
CkkKBAQAAgcSBFoCWzIaOyBPdXRwdXQgb25seS4gVGhlIHRpbWUgd2hlbiB0aGUgYmFja3Vw
IHBvbGljeSB3YXMgY3JlYXRlZC4KCgwKBQQAAgcGEgNaAhsKDAoFBAACBwESA1ocJwoMCgUE
AAIHAxIDWiorCgwKBQQAAgcIEgNbBjEKDwoIBAACBwicCAASA1sHMApDCgQEAAIIEgNeAiEa
NiBSZXNvdXJjZSBsYWJlbHMgdG8gcmVwcmVzZW50IHVzZXIgcHJvdmlkZWQgbWV0YWRhdGEu
CgoMCgUEAAIIBhIDXgIVCgwKBQQAAggBEgNeFhwKDAoFBAACCAMSA14fIAo0CgQEAAIJEgNh
Aj8aJyBPdXRwdXQgb25seS4gVGhlIGJhY2t1cCBwb2xpY3kgc3RhdGUuCgoMCgUEAAIJBhID
YQIHCgwKBQQAAgkBEgNhCA0KDAoFBAACCQMSA2EQEgoMCgUEAAIJCBIDYRM+Cg8KCAQAAgkI
nAgAEgNhFD0KPwoCBAESBGUAeAEaMyBDcmVhdGVCYWNrdXBQb2xpY3lSZXF1ZXN0IGNyZWF0
ZXMgYSBiYWNrdXBQb2xpY3kuCgoKCgMEAQESA2UIIQqEAQoEBAECABIEaAJtBBp2IFJlcXVp
cmVkLiBUaGUgbG9jYXRpb24gdG8gY3JlYXRlIHRoZSBiYWNrdXAgcG9saWNpZXMgb2YsIGlu
IHRoZSBmb3JtYXQKIGBwcm9qZWN0cy97cHJvamVjdF9pZH0vbG9jYXRpb25zL3tsb2NhdGlv
bn1gCgoMCgUEAQIABRIDaAIICgwKBQQBAgABEgNoCQ8KDAoFBAECAAMSA2gSEwoNCgUEAQIA
CBIEaBRtAwoPCggEAQIACJwIABIDaQQqCg8KBwQBAgAInwgSBGoEbAUKMAoEBAECARIDcAJK
GiMgUmVxdWlyZWQuIEEgYmFja3VwUG9saWN5IHJlc291cmNlCgoMCgUEAQIBBhIDcAIOCgwK
BQQBAgEBEgNwDxwKDAoFBAECAQMSA3AfIAoMCgUEAQIBCBIDcCFJCg8KCAQBAgEInAgAEgNw
IkgKhAIKBAQBAgISA3cCRxr2ASBSZXF1aXJlZC4gVGhlIElEIHRvIHVzZSBmb3IgdGhlIGJh
Y2t1cCBwb2xpY3kuCiBUaGUgSUQgbXVzdCBiZSB1bmlxdWUgd2l0aGluIHRoZSBzcGVjaWZp
ZWQgbG9jYXRpb24uCiBNdXN0IGNvbnRhaW4gb25seSBsZXR0ZXJzLCBudW1iZXJzIGFuZCBo
eXBoZW4sIHdpdGggdGhlIGZpcnN0CiBjaGFyYWN0ZXIgYSBsZXR0ZXIsIHRoZSBsYXN0IGEg
bGV0dGVyIG9yIGEKIG51bWJlciwgYW5kIGEgNjMgY2hhcmFjdGVyIG1heGltdW0uCgoMCgUE
AQICBRIDdwIICgwKBQQBAgIBEgN3CRkKDAoFBAECAgMSA3ccHQoMCgUEAQICCBIDdx5GCg8K
CAQBAgIInAgAEgN3H0UKRwoCBAISBXsAhAEBGjogR2V0QmFja3VwUG9saWN5UmVxdWVzdCBn
ZXRzIHRoZSBzdGF0ZSBvZiBhIGJhY2t1cFBvbGljeS4KCgoKAwQCARIDewgeCpkBCgQEAgIA
EgV+AoMBBBqJASBSZXF1aXJlZC4gVGhlIGJhY2t1cFBvbGljeSByZXNvdXJjZSBuYW1lLCBp
biB0aGUgZm9ybWF0CiBgcHJvamVjdHMve3Byb2plY3RfaWR9L2xvY2F0aW9ucy97bG9jYXRp
b259L2JhY2t1cFBvbGljaWVzL3tiYWNrdXBfcG9saWN5X2lkfWAKCgwKBQQCAgAFEgN+AggK
DAoFBAICAAESA34JDQoMCgUEAgIAAxIDfhARCg4KBQQCAgAIEgV+EoMBAwoPCggEAgIACJwI
ABIDfwQqChEKBwQCAgAInwgSBoABBIIBBQpSCgIEAxIGhwEAnAEBGkQgTGlzdEJhY2t1cFBv
bGljaWVzUmVxdWVzdCBmb3IgcmVxdWVzdGluZyBtdWx0aXBsZSBiYWNrdXAgcG9saWNpZXMu
CgoLCgMEAwESBIcBCCEKRgoEBAMCABIGiQECjgEEGjYgUmVxdWlyZWQuIFBhcmVudCB2YWx1
ZSBmb3IgTGlzdEJhY2t1cFBvbGljaWVzUmVxdWVzdAoKDQoFBAMCAAUSBIkBAggKDQoFBAMC
AAESBIkBCQ8KDQoFBAMCAAMSBIkBEhMKDwoFBAMCAAgSBokBFI4BAwoQCggEAwIACJwIABIE
igEEKgoRCgcEAwIACJ8IEgaLAQSNAQUKkQEKBAQDAgESBJIBAhYaggEgUmVxdWVzdGVkIHBh
Z2Ugc2l6ZS4gU2VydmVyIG1heSByZXR1cm4gZmV3ZXIgaXRlbXMgdGhhbiByZXF1ZXN0ZWQu
CiBJZiB1bnNwZWNpZmllZCwgdGhlIHNlcnZlciB3aWxsIHBpY2sgYW4gYXBwcm9wcmlhdGUg
ZGVmYXVsdC4KCg0KBQQDAgEFEgSSAQIHCg0KBQQDAgEBEgSSAQgRCg0KBQQDAgEDEgSSARQV
Ck8KBAQDAgISBJUBAhgaQSBBIHRva2VuIGlkZW50aWZ5aW5nIGEgcGFnZSBvZiByZXN1bHRz
IHRoZSBzZXJ2ZXIgc2hvdWxkIHJldHVybi4KCg0KBQQDAgIFEgSVAQIICg0KBQQDAgIBEgSV
AQkTCg0KBQQDAgIDEgSVARYXCiEKBAQDAgMSBJgBAhQaEyBGaWx0ZXJpbmcgcmVzdWx0cwoK
DQoFBAMCAwUSBJgBAggKDQoFBAMCAwESBJgBCQ8KDQoFBAMCAwMSBJgBEhMKMQoEBAMCBBIE
mwECFhojIEhpbnQgZm9yIGhvdyB0byBvcmRlciB0aGUgcmVzdWx0cwoKDQoFBAMCBAUSBJsB
AggKDQoFBAMCBAESBJsBCREKDQoFBAMCBAMSBJsBFBUKVgoCBAQSBp8BAKgBARpIIExpc3RC
YWNrdXBQb2xpY2llc1Jlc3BvbnNlIGNvbnRhaW5zIGFsbCB0aGUgYmFja3VwIHBvbGljaWVz
IHJlcXVlc3RlZC4KCgsKAwQEARIEnwEIIgosCgQEBAIAEgShAQIsGh4gVGhlIGxpc3Qgb2Yg
YmFja3VwIHBvbGljaWVzLgoKDQoFBAQCAAQSBKEBAgoKDQoFBAQCAAYSBKEBCxcKDQoFBAQC
AAESBKEBGCcKDQoFBAQCAAMSBKEBKisKTwoEBAQCARIEpAECHRpBIEEgdG9rZW4gaWRlbnRp
ZnlpbmcgYSBwYWdlIG9mIHJlc3VsdHMgdGhlIHNlcnZlciBzaG91bGQgcmV0dXJuLgoKDQoF
BAQCAQUSBKQBAggKDQoFBAQCAQESBKQBCRgKDQoFBAQCAQMSBKQBGxwKNAoEBAQCAhIEpwEC
IhomIExvY2F0aW9ucyB0aGF0IGNvdWxkIG5vdCBiZSByZWFjaGVkLgoKDQoFBAQCAgQSBKcB
AgoKDQoFBAQCAgUSBKcBCxEKDQoFBAQCAgESBKcBEh0KDQoFBAQCAgMSBKcBICEKRwoCBAUS
BqsBALYBARo5IFVwZGF0ZUJhY2t1cFBvbGljeVJlcXVlc3QgZm9yIHVwZGF0aW5nIGEgYmFj
a3VwIHBvbGljeS4KCgsKAwQFARIEqwEIIQrfAgoEBAUCABIGsQECsgEvGs4CIFJlcXVpcmVk
LiBGaWVsZCBtYXNrIGlzIHVzZWQgdG8gc3BlY2lmeSB0aGUgZmllbGRzIHRvIGJlIG92ZXJ3
cml0dGVuIGluIHRoZQogQmFja3VwIFBvbGljeSByZXNvdXJjZSBieSB0aGUgdXBkYXRlLgog
VGhlIGZpZWxkcyBzcGVjaWZpZWQgaW4gdGhlIHVwZGF0ZV9tYXNrIGFyZSByZWxhdGl2ZSB0
byB0aGUgcmVzb3VyY2UsIG5vdAogdGhlIGZ1bGwgcmVxdWVzdC4gQSBmaWVsZCB3aWxsIGJl
IG92ZXJ3cml0dGVuIGlmIGl0IGlzIGluIHRoZSBtYXNrLiBJZiB0aGUKIHVzZXIgZG9lcyBu
b3QgcHJvdmlkZSBhIG1hc2sgdGhlbiBhbGwgZmllbGRzIHdpbGwgYmUgb3ZlcndyaXR0ZW4u
CgoNCgUEBQIABhIEsQECGwoNCgUEBQIAARIEsQEcJwoNCgUEBQIAAxIEsQEqKwoNCgUEBQIA
CBIEsgEGLgoQCggEBQIACJwIABIEsgEHLQo5CgQEBQIBEgS1AQJKGisgUmVxdWlyZWQuIFRo
ZSBiYWNrdXAgcG9saWN5IGJlaW5nIHVwZGF0ZWQKCg0KBQQFAgEGEgS1AQIOCg0KBQQFAgEB
EgS1AQ8cCg0KBQQFAgEDEgS1AR8gCg0KBQQFAgEIEgS1ASFJChAKCAQFAgEInAgAEgS1ASJI
CkIKAgQGEga5AQDCAQEaNCBEZWxldGVCYWNrdXBQb2xpY3lSZXF1ZXN0IGRlbGV0ZXMgYSBi
YWNrdXAgcG9saWN5LgoKCwoDBAYBEgS5AQghCpsBCgQEBgIAEga8AQLBAQQaigEgUmVxdWly
ZWQuIFRoZSBiYWNrdXAgcG9saWN5IHJlc291cmNlIG5hbWUsIGluIHRoZSBmb3JtYXQKIGBw
cm9qZWN0cy97cHJvamVjdF9pZH0vbG9jYXRpb25zL3tsb2NhdGlvbn0vYmFja3VwUG9saWNp
ZXMve2JhY2t1cF9wb2xpY3lfaWR9YAoKDQoFBAYCAAUSBLwBAggKDQoFBAYCAAESBLwBCQ0K
DQoFBAYCAAMSBLwBEBEKDwoFBAYCAAgSBrwBEsEBAwoQCggEBgIACJwIABIEvQEEKgoRCgcE
BgIACJ8IEga+AQTAAQViBnByb3RvMw==
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Netapp::V1::BackupPolicy::BackupPolicy ===
    # Fields for BackupPolicy
    # Field: name Type: 9 ()
    # Field: daily_backup_limit Type: 5 ()
    # Field: weekly_backup_limit Type: 5 ()
    # Field: monthly_backup_limit Type: 5 ()
    # Field: description Type: 9 ()
    # Field: enabled Type: 8 ()
    # Field: assigned_volume_count Type: 5 ()
    # Field: create_time Type: 11 (.google.protobuf.Timestamp)
    # Field: labels Type: 11 (.google.cloud.netapp.v1.BackupPolicy.LabelsEntry)
    # Field: state Type: 14 (.google.cloud.netapp.v1.BackupPolicy.State)

# Enum: BackupPolicy::State
our $BackupPolicy_STATE_UNSPECIFIED = 0;
our $BackupPolicy_CREATING = 1;
our $BackupPolicy_READY = 2;
our $BackupPolicy_DELETING = 3;
our $BackupPolicy_ERROR = 4;
our $BackupPolicy_UPDATING = 5;

# === Message: Google::Cloud::Netapp::V1::BackupPolicy::CreateBackupPolicyRequest ===
    # Fields for CreateBackupPolicyRequest
    # Field: parent Type: 9 ()
    # Field: backup_policy Type: 11 (.google.cloud.netapp.v1.BackupPolicy)
    # Field: backup_policy_id Type: 9 ()

# === Message: Google::Cloud::Netapp::V1::BackupPolicy::GetBackupPolicyRequest ===
    # Fields for GetBackupPolicyRequest
    # Field: name Type: 9 ()

# === Message: Google::Cloud::Netapp::V1::BackupPolicy::ListBackupPoliciesRequest ===
    # Fields for ListBackupPoliciesRequest
    # Field: parent Type: 9 ()
    # Field: page_size Type: 5 ()
    # Field: page_token Type: 9 ()
    # Field: filter Type: 9 ()
    # Field: order_by Type: 9 ()

# === Message: Google::Cloud::Netapp::V1::BackupPolicy::ListBackupPoliciesResponse ===
    # Fields for ListBackupPoliciesResponse
    # Field: backup_policies Type: 11 (.google.cloud.netapp.v1.BackupPolicy)
    # Field: next_page_token Type: 9 ()
    # Field: unreachable Type: 9 ()

# === Message: Google::Cloud::Netapp::V1::BackupPolicy::UpdateBackupPolicyRequest ===
    # Fields for UpdateBackupPolicyRequest
    # Field: update_mask Type: 11 (.google.protobuf.FieldMask)
    # Field: backup_policy Type: 11 (.google.cloud.netapp.v1.BackupPolicy)

# === Message: Google::Cloud::Netapp::V1::BackupPolicy::DeleteBackupPolicyRequest ===
    # Fields for DeleteBackupPolicyRequest
    # Field: name Type: 9 ()

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Netapp::V1::BackupPolicy - Compiled Protocol Buffers messages for google/cloud/netapp/v1/backup_policy.proto

=head1 SYNOPSIS

    use Google::Cloud::Netapp::V1::BackupPolicy;

    my $msg = Google::Cloud::Netapp::V1::BackupPolicy::BackupPolicy->new({
        name => $name,
        daily_backup_limit => $daily_backup_limit,
        weekly_backup_limit => $weekly_backup_limit,
        monthly_backup_limit => $monthly_backup_limit,
    });

    # Read or update a field
    my $val = $msg->name();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Netapp::V1::BackupPolicy::BackupPolicy->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/netapp/v1/backup_policy.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Netapp::V1::BackupPolicy::BackupPolicy

Backup Policy.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Identifier. The resource name of the backup policy.
Format:
`projects/{project_id}/locations/{location}/backupPolicies/{backup_policy_id}`.

=item * C<< $msg->daily_backup_limit() >> / C<< $msg->daily_backup_limit($value) >>

Type: C<Int32>

Number of daily backups to keep. Note that the minimum daily backup limit
is 2.

=item * C<< $msg->weekly_backup_limit() >> / C<< $msg->weekly_backup_limit($value) >>

Type: C<Int32>

Number of weekly backups to keep. Note that the sum of daily, weekly and
monthly backups should be greater than 1.

=item * C<< $msg->monthly_backup_limit() >> / C<< $msg->monthly_backup_limit($value) >>

Type: C<Int32>

Number of monthly backups to keep. Note that the sum of daily, weekly and
monthly backups should be greater than 1.

=item * C<< $msg->description() >> / C<< $msg->description($value) >>

Type: C<String>

Description of the backup policy.

=item * C<< $msg->enabled() >> / C<< $msg->enabled($value) >>

Type: C<Bool>

If enabled, make backups automatically according to the schedules.
This will be applied to all volumes that have this policy attached and
enforced on volume level. If not specified, default is true.

=item * C<< $msg->assigned_volume_count() >> / C<< $msg->assigned_volume_count($value) >>

Type: C<Int32>

Output only. The total number of volumes assigned by this backup policy.

=item * C<< $msg->create_time() >> / C<< $msg->create_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Output only. The time when the backup policy was created.

=item * C<< $msg->labels() >> / C<< $msg->labels($value) >>

Type: C<Message> (L<Google::Cloud::Netapp::V1::BackupPolicy::BackupPolicy::LabelsEntry>)

Resource labels to represent user provided metadata.

=item * C<< $msg->state() >> / C<< $msg->state($value) >>

Type: C<Enum> (L<Google::Cloud::Netapp::V1::BackupPolicy::State>)

Output only. The backup policy state.

=back

=head3 Enum: BackupPolicy::State

=over 4

=item * C<STATE_UNSPECIFIED> => C<0>

=item * C<CREATING> => C<1>

=item * C<READY> => C<2>

=item * C<DELETING> => C<3>

=item * C<ERROR> => C<4>

=item * C<UPDATING> => C<5>

=back

=head2 Google::Cloud::Netapp::V1::BackupPolicy::CreateBackupPolicyRequest

CreateBackupPolicyRequest creates a backupPolicy.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->parent() >> / C<< $msg->parent($value) >>

Type: C<String>

Required. The location to create the backup policies of, in the format
`projects/{project_id}/locations/{location}`

=item * C<< $msg->backup_policy() >> / C<< $msg->backup_policy($value) >>

Type: C<Message> (L<Google::Cloud::Netapp::V1::BackupPolicy::BackupPolicy>)

Required. A backupPolicy resource

=item * C<< $msg->backup_policy_id() >> / C<< $msg->backup_policy_id($value) >>

Type: C<String>

Required. The ID to use for the backup policy.
The ID must be unique within the specified location.
Must contain only letters, numbers and hyphen, with the first
character a letter, the last a letter or a
number, and a 63 character maximum.

=back

=head2 Google::Cloud::Netapp::V1::BackupPolicy::GetBackupPolicyRequest

GetBackupPolicyRequest gets the state of a backupPolicy.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. The backupPolicy resource name, in the format
`projects/{project_id}/locations/{location}/backupPolicies/{backup_policy_id}`

=back

=head2 Google::Cloud::Netapp::V1::BackupPolicy::ListBackupPoliciesRequest

ListBackupPoliciesRequest for requesting multiple backup policies.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->parent() >> / C<< $msg->parent($value) >>

Type: C<String>

Required. Parent value for ListBackupPoliciesRequest

=item * C<< $msg->page_size() >> / C<< $msg->page_size($value) >>

Type: C<Int32>

Requested page size. Server may return fewer items than requested.
If unspecified, the server will pick an appropriate default.

=item * C<< $msg->page_token() >> / C<< $msg->page_token($value) >>

Type: C<String>

A token identifying a page of results the server should return.

=item * C<< $msg->filter() >> / C<< $msg->filter($value) >>

Type: C<String>

Filtering results

=item * C<< $msg->order_by() >> / C<< $msg->order_by($value) >>

Type: C<String>

Hint for how to order the results

=back

=head2 Google::Cloud::Netapp::V1::BackupPolicy::ListBackupPoliciesResponse

ListBackupPoliciesResponse contains all the backup policies requested.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->backup_policies() >> / C<< $msg->backup_policies($value) >>

Type: C<Message> (L<Google::Cloud::Netapp::V1::BackupPolicy::BackupPolicy>)

The list of backup policies.

=item * C<< $msg->next_page_token() >> / C<< $msg->next_page_token($value) >>

Type: C<String>

A token identifying a page of results the server should return.

=item * C<< $msg->unreachable() >> / C<< $msg->unreachable($value) >>

Type: C<String>

Locations that could not be reached.

=back

=head2 Google::Cloud::Netapp::V1::BackupPolicy::UpdateBackupPolicyRequest

UpdateBackupPolicyRequest for updating a backup policy.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->update_mask() >> / C<< $msg->update_mask($value) >>

Type: C<Message> (L<Google::Protobuf::FieldMask::FieldMask>)

Required. Field mask is used to specify the fields to be overwritten in the
Backup Policy resource by the update.
The fields specified in the update_mask are relative to the resource, not
the full request. A field will be overwritten if it is in the mask. If the
user does not provide a mask then all fields will be overwritten.

=item * C<< $msg->backup_policy() >> / C<< $msg->backup_policy($value) >>

Type: C<Message> (L<Google::Cloud::Netapp::V1::BackupPolicy::BackupPolicy>)

Required. The backup policy being updated

=back

=head2 Google::Cloud::Netapp::V1::BackupPolicy::DeleteBackupPolicyRequest

DeleteBackupPolicyRequest deletes a backup policy.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. The backup policy resource name, in the format
`projects/{project_id}/locations/{location}/backupPolicies/{backup_policy_id}`

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Netapp::V1::BackupPolicy::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
