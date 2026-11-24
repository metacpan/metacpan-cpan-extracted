package Google::Cloud::Datacatalog::V1::Policytagmanagerserialization;

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
    eval { require Google::Cloud::Datacatalog::V1::Policytagmanager };
    my $descriptor_b64 = <<'EOF';
Cj9nb29nbGUvY2xvdWQvZGF0YWNhdGFsb2cvdjEvcG9saWN5dGFnbWFuYWdlcnNlcmlhbGl6
YXRpb24ucHJvdG8SG2dvb2dsZS5jbG91ZC5kYXRhY2F0YWxvZy52MRocZ29vZ2xlL2FwaS9h
bm5vdGF0aW9ucy5wcm90bxoXZ29vZ2xlL2FwaS9jbGllbnQucHJvdG8aH2dvb2dsZS9hcGkv
ZmllbGRfYmVoYXZpb3IucHJvdG8aGWdvb2dsZS9hcGkvcmVzb3VyY2UucHJvdG8aMmdvb2ds
ZS9jbG91ZC9kYXRhY2F0YWxvZy92MS9wb2xpY3l0YWdtYW5hZ2VyLnByb3RvIpkCChJTZXJp
YWxpemVkVGF4b25vbXkSJgoMZGlzcGxheV9uYW1lGAEgASgJQgPgQQJSC2Rpc3BsYXlOYW1l
EiAKC2Rlc2NyaXB0aW9uGAIgASgJUgtkZXNjcmlwdGlvbhJRCgtwb2xpY3lfdGFncxgDIAMo
CzIwLmdvb2dsZS5jbG91ZC5kYXRhY2F0YWxvZy52MS5TZXJpYWxpemVkUG9saWN5VGFnUgpw
b2xpY3lUYWdzEmYKFmFjdGl2YXRlZF9wb2xpY3lfdHlwZXMYBCADKA4yMC5nb29nbGUuY2xv
dWQuZGF0YWNhdGFsb2cudjEuVGF4b25vbXkuUG9saWN5VHlwZVIUYWN0aXZhdGVkUG9saWN5
VHlwZXMi3AEKE1NlcmlhbGl6ZWRQb2xpY3lUYWcSHQoKcG9saWN5X3RhZxgBIAEoCVIJcG9s
aWN5VGFnEiYKDGRpc3BsYXlfbmFtZRgCIAEoCUID4EECUgtkaXNwbGF5TmFtZRIgCgtkZXNj
cmlwdGlvbhgDIAEoCVILZGVzY3JpcHRpb24SXAoRY2hpbGRfcG9saWN5X3RhZ3MYBCADKAsy
MC5nb29nbGUuY2xvdWQuZGF0YWNhdGFsb2cudjEuU2VyaWFsaXplZFBvbGljeVRhZ1IPY2hp
bGRQb2xpY3lUYWdzIsABChZSZXBsYWNlVGF4b25vbXlSZXF1ZXN0Ej8KBG5hbWUYASABKAlC
K+BBAvpBJQojZGF0YWNhdGFsb2cuZ29vZ2xlYXBpcy5jb20vVGF4b25vbXlSBG5hbWUSZQoT
c2VyaWFsaXplZF90YXhvbm9teRgCIAEoCzIvLmdvb2dsZS5jbG91ZC5kYXRhY2F0YWxvZy52
MS5TZXJpYWxpemVkVGF4b25vbXlCA+BBAlISc2VyaWFsaXplZFRheG9ub215IqICChdJbXBv
cnRUYXhvbm9taWVzUmVxdWVzdBJDCgZwYXJlbnQYASABKAlCK+BBAvpBJRIjZGF0YWNhdGFs
b2cuZ29vZ2xlYXBpcy5jb20vVGF4b25vbXlSBnBhcmVudBJQCg1pbmxpbmVfc291cmNlGAIg
ASgLMikuZ29vZ2xlLmNsb3VkLmRhdGFjYXRhbG9nLnYxLklubGluZVNvdXJjZUgAUgxpbmxp
bmVTb3VyY2USZgoVY3Jvc3NfcmVnaW9uYWxfc291cmNlGAMgASgLMjAuZ29vZ2xlLmNsb3Vk
LmRhdGFjYXRhbG9nLnYxLkNyb3NzUmVnaW9uYWxTb3VyY2VIAFITY3Jvc3NSZWdpb25hbFNv
dXJjZUIICgZzb3VyY2UiZAoMSW5saW5lU291cmNlElQKCnRheG9ub21pZXMYASADKAsyLy5n
b29nbGUuY2xvdWQuZGF0YWNhdGFsb2cudjEuU2VyaWFsaXplZFRheG9ub215QgPgQQJSCnRh
eG9ub21pZXMiXgoTQ3Jvc3NSZWdpb25hbFNvdXJjZRJHCgh0YXhvbm9teRgBIAEoCUIr4EEC
+kElCiNkYXRhY2F0YWxvZy5nb29nbGVhcGlzLmNvbS9UYXhvbm9teVIIdGF4b25vbXkiYQoY
SW1wb3J0VGF4b25vbWllc1Jlc3BvbnNlEkUKCnRheG9ub21pZXMYASADKAsyJS5nb29nbGUu
Y2xvdWQuZGF0YWNhdGFsb2cudjEuVGF4b25vbXlSCnRheG9ub21pZXMi8QEKF0V4cG9ydFRh
eG9ub21pZXNSZXF1ZXN0EkMKBnBhcmVudBgBIAEoCUIr4EEC+kElEiNkYXRhY2F0YWxvZy5n
b29nbGVhcGlzLmNvbS9UYXhvbm9teVIGcGFyZW50EksKCnRheG9ub21pZXMYAiADKAlCK+BB
AvpBJQojZGF0YWNhdGFsb2cuZ29vZ2xlYXBpcy5jb20vVGF4b25vbXlSCnRheG9ub21pZXMS
NQoVc2VyaWFsaXplZF90YXhvbm9taWVzGAMgASgISABSFHNlcmlhbGl6ZWRUYXhvbm9taWVz
Qg0KC2Rlc3RpbmF0aW9uImsKGEV4cG9ydFRheG9ub21pZXNSZXNwb25zZRJPCgp0YXhvbm9t
aWVzGAEgAygLMi8uZ29vZ2xlLmNsb3VkLmRhdGFjYXRhbG9nLnYxLlNlcmlhbGl6ZWRUYXhv
bm9teVIKdGF4b25vbWllczKnBQodUG9saWN5VGFnTWFuYWdlclNlcmlhbGl6YXRpb24SsAEK
D1JlcGxhY2VUYXhvbm9teRIzLmdvb2dsZS5jbG91ZC5kYXRhY2F0YWxvZy52MS5SZXBsYWNl
VGF4b25vbXlSZXF1ZXN0GiUuZ29vZ2xlLmNsb3VkLmRhdGFjYXRhbG9nLnYxLlRheG9ub215
IkGC0+STAjsiNi92MS97bmFtZT1wcm9qZWN0cy8qL2xvY2F0aW9ucy8qL3RheG9ub21pZXMv
Kn06cmVwbGFjZToBKhLBAQoQSW1wb3J0VGF4b25vbWllcxI0Lmdvb2dsZS5jbG91ZC5kYXRh
Y2F0YWxvZy52MS5JbXBvcnRUYXhvbm9taWVzUmVxdWVzdBo1Lmdvb2dsZS5jbG91ZC5kYXRh
Y2F0YWxvZy52MS5JbXBvcnRUYXhvbm9taWVzUmVzcG9uc2UiQILT5JMCOiI1L3YxL3twYXJl
bnQ9cHJvamVjdHMvKi9sb2NhdGlvbnMvKn0vdGF4b25vbWllczppbXBvcnQ6ASoSvgEKEEV4
cG9ydFRheG9ub21pZXMSNC5nb29nbGUuY2xvdWQuZGF0YWNhdGFsb2cudjEuRXhwb3J0VGF4
b25vbWllc1JlcXVlc3QaNS5nb29nbGUuY2xvdWQuZGF0YWNhdGFsb2cudjEuRXhwb3J0VGF4
b25vbWllc1Jlc3BvbnNlIj2C0+STAjcSNS92MS97cGFyZW50PXByb2plY3RzLyovbG9jYXRp
b25zLyp9L3RheG9ub21pZXM6ZXhwb3J0Gk7KQRpkYXRhY2F0YWxvZy5nb29nbGVhcGlzLmNv
bdJBLmh0dHBzOi8vd3d3Lmdvb2dsZWFwaXMuY29tL2F1dGgvY2xvdWQtcGxhdGZvcm1C5wEK
H2NvbS5nb29nbGUuY2xvdWQuZGF0YWNhdGFsb2cudjFCIlBvbGljeVRhZ01hbmFnZXJTZXJp
YWxpemF0aW9uUHJvdG9QAVpBY2xvdWQuZ29vZ2xlLmNvbS9nby9kYXRhY2F0YWxvZy9hcGl2
MS9kYXRhY2F0YWxvZ3BiO2RhdGFjYXRhbG9ncGKqAhtHb29nbGUuQ2xvdWQuRGF0YUNhdGFs
b2cuVjHKAhtHb29nbGVcQ2xvdWRcRGF0YUNhdGFsb2dcVjHqAh5Hb29nbGU6OkNsb3VkOjpE
YXRhQ2F0YWxvZzo6VjFK9jUKBxIFDgDkAQEKvAQKAQwSAw4AEjKxBCBDb3B5cmlnaHQgMjAy
NSBHb29nbGUgTExDCgogTGljZW5zZWQgdW5kZXIgdGhlIEFwYWNoZSBMaWNlbnNlLCBWZXJz
aW9uIDIuMCAodGhlICJMaWNlbnNlIik7CiB5b3UgbWF5IG5vdCB1c2UgdGhpcyBmaWxlIGV4
Y2VwdCBpbiBjb21wbGlhbmNlIHdpdGggdGhlIExpY2Vuc2UuCiBZb3UgbWF5IG9idGFpbiBh
IGNvcHkgb2YgdGhlIExpY2Vuc2UgYXQKCiAgICAgaHR0cDovL3d3dy5hcGFjaGUub3JnL2xp
Y2Vuc2VzL0xJQ0VOU0UtMi4wCgogVW5sZXNzIHJlcXVpcmVkIGJ5IGFwcGxpY2FibGUgbGF3
IG9yIGFncmVlZCB0byBpbiB3cml0aW5nLCBzb2Z0d2FyZQogZGlzdHJpYnV0ZWQgdW5kZXIg
dGhlIExpY2Vuc2UgaXMgZGlzdHJpYnV0ZWQgb24gYW4gIkFTIElTIiBCQVNJUywKIFdJVEhP
VVQgV0FSUkFOVElFUyBPUiBDT05ESVRJT05TIE9GIEFOWSBLSU5ELCBlaXRoZXIgZXhwcmVz
cyBvciBpbXBsaWVkLgogU2VlIHRoZSBMaWNlbnNlIGZvciB0aGUgc3BlY2lmaWMgbGFuZ3Vh
Z2UgZ292ZXJuaW5nIHBlcm1pc3Npb25zIGFuZAogbGltaXRhdGlvbnMgdW5kZXIgdGhlIExp
Y2Vuc2UuCgoICgECEgMQACQKCQoCAwASAxIAJgoJCgIDARIDEwAhCgkKAgMCEgMUACkKCQoC
AwMSAxUAIwoJCgIDBBIDFgA8CggKAQgSAxgAOAoJCgIIJRIDGAA4CggKAQgSAxkAWAoJCgII
CxIDGQBYCggKAQgSAxoAIgoJCgIIChIDGgAiCggKAQgSAxsAQwoJCgIICBIDGwBDCggKAQgS
AxwAOAoJCgIIARIDHAA4CggKAQgSAx0AOAoJCgIIKRIDHQA4CggKAQgSAx4ANwoJCgIILRID
HgA3CsABCgIGABIEJABZARqzASBQb2xpY3kgVGFnIE1hbmFnZXIgU2VyaWFsaXphdGlvbiBB
UEkgc2VydmljZSBhbGxvd3MgeW91IHRvIG1hbmlwdWxhdGUKIHlvdXIgcG9saWN5IHRhZ3Mg
YW5kIHRheG9ub21pZXMgaW4gYSBzZXJpYWxpemVkIGZvcm1hdC4KCiBUYXhvbm9teSBpcyBh
IGhpZXJhcmNoaWNhbCBncm91cCBvZiBwb2xpY3kgdGFncy4KCgoKAwYAARIDJAglCgoKAwYA
AxIDJQJCCgwKBQYAA5kIEgMlAkIKCwoDBgADEgQmAic3Cg0KBQYAA5oIEgQmAic3CoMECgQG
AAIAEgQ2AjsDGvQDIFJlcGxhY2VzICh1cGRhdGVzKSBhIHRheG9ub215IGFuZCBhbGwgaXRz
IHBvbGljeSB0YWdzLgoKIFRoZSB0YXhvbm9teSBhbmQgaXRzIGVudGlyZSBoaWVyYXJjaHkg
b2YgcG9saWN5IHRhZ3MgbXVzdCBiZQogcmVwcmVzZW50ZWQgbGl0ZXJhbGx5IGJ5IGBTZXJp
YWxpemVkVGF4b25vbXlgIGFuZCB0aGUgbmVzdGVkCiBgU2VyaWFsaXplZFBvbGljeVRhZ2Ag
bWVzc2FnZXMuCgogVGhpcyBvcGVyYXRpb24gYXV0b21hdGljYWxseSBkb2VzIHRoZSBmb2xs
b3dpbmc6CgogLSBEZWxldGVzIHRoZSBleGlzdGluZyBwb2xpY3kgdGFncyB0aGF0IGFyZSBt
aXNzaW5nIGZyb20gdGhlCiAgIGBTZXJpYWxpemVkUG9saWN5VGFnYC4KIC0gQ3JlYXRlcyBw
b2xpY3kgdGFncyB0aGF0IGRvbid0IGhhdmUgcmVzb3VyY2UgbmFtZXMuIFRoZXkgYXJlIGNv
bnNpZGVyZWQKICAgbmV3LgogLSBVcGRhdGVzIHBvbGljeSB0YWdzIHdpdGggdmFsaWQgcmVz
b3VyY2VzIG5hbWVzIGFjY29yZGluZ2x5LgoKDAoFBgACAAESAzYGFQoMCgUGAAIAAhIDNhYs
CgwKBQYAAgADEgM2Nz8KDQoFBgACAAQSBDcEOgYKEQoJBgACAASwyrwiEgQ3BDoGCucCCgQG
AAIBEgRFAksDGtgCIENyZWF0ZXMgbmV3IHRheG9ub21pZXMgKGluY2x1ZGluZyB0aGVpciBw
b2xpY3kgdGFncykgaW4gYSBnaXZlbiBwcm9qZWN0CiBieSBpbXBvcnRpbmcgZnJvbSBpbmxp
bmVkIG9yIGNyb3NzLXJlZ2lvbmFsIHNvdXJjZXMuCgogRm9yIGEgY3Jvc3MtcmVnaW9uYWwg
c291cmNlLCBuZXcgdGF4b25vbWllcyBhcmUgY3JlYXRlZCBieSBjb3B5aW5nCiBmcm9tIGEg
c291cmNlIGluIGFub3RoZXIgcmVnaW9uLgoKIEZvciBhbiBpbmxpbmVkIHNvdXJjZSwgdGF4
b25vbWllcyBhbmQgcG9saWN5IHRhZ3MgYXJlIGNyZWF0ZWQgaW4gYnVsayB1c2luZwogbmVz
dGVkIHByb3RvY29sIGJ1ZmZlciBzdHJ1Y3R1cmVzLgoKDAoFBgACAQESA0UGFgoMCgUGAAIB
AhIDRRcuCgwKBQYAAgEDEgNGDycKDQoFBgACAQQSBEcESgYKEQoJBgACAQSwyrwiEgRHBEoG
CrMCCgQGAAICEgRTAlgDGqQCIEV4cG9ydHMgdGF4b25vbWllcyBpbiB0aGUgcmVxdWVzdGVk
IHR5cGUgYW5kIHJldHVybnMgdGhlbSwKIGluY2x1ZGluZyB0aGVpciBwb2xpY3kgdGFncy4g
VGhlIHJlcXVlc3RlZCB0YXhvbm9taWVzIG11c3QgYmVsb25nIHRvIHRoZQogc2FtZSBwcm9q
ZWN0LgoKIFRoaXMgbWV0aG9kIGdlbmVyYXRlcyBgU2VyaWFsaXplZFRheG9ub215YCBwcm90
b2NvbCBidWZmZXJzIHdpdGggbmVzdGVkCiBwb2xpY3kgdGFncyB0aGF0IGNhbiBiZSB1c2Vk
IGFzIGlucHV0IGZvciBgSW1wb3J0VGF4b25vbWllc2AgY2FsbHMuCgoMCgUGAAICARIDUwYW
CgwKBQYAAgICEgNTFy4KDAoFBgACAgMSA1QPJwoNCgUGAAICBBIEVQRXBgoRCgkGAAICBLDK
vCISBFUEVwYKnQEKAgQAEgReAGwBGpABIEEgbmVzdGVkIHByb3RvY29sIGJ1ZmZlciB0aGF0
IHJlcHJlc2VudHMgYSB0YXhvbm9teSBhbmQgdGhlIGhpZXJhcmNoeSBvZiBpdHMKIHBvbGlj
eSB0YWdzLiBVc2VkIGZvciB0YXhvbm9teSByZXBsYWNlbWVudCwgaW1wb3J0LCBhbmQKIGV4
cG9ydC4KCgoKAwQAARIDXggaCmAKBAQAAgASA2ECQxpTIFJlcXVpcmVkLiBEaXNwbGF5IG5h
bWUgb2YgdGhlIHRheG9ub215LiBBdCBtb3N0IDIwMCBieXRlcyB3aGVuIGVuY29kZWQgaW4K
IFVURi04LgoKDAoFBAACAAUSA2ECCAoMCgUEAAIAARIDYQkVCgwKBQQAAgADEgNhGBkKDAoF
BAACAAgSA2EaQgoPCggEAAIACJwIABIDYRtBCpABCgQEAAIBEgNlAhkaggEgRGVzY3JpcHRp
b24gb2YgdGhlIHNlcmlhbGl6ZWQgdGF4b25vbXkuIEF0IG1vc3QgMjAwMCBieXRlcyB3aGVu
CiBlbmNvZGVkIGluIFVURi04LiBJZiBub3Qgc2V0LCBkZWZhdWx0cyB0byBhbiBlbXB0eSBk
ZXNjcmlwdGlvbi4KCgwKBQQAAgEFEgNlAggKDAoFBAACAQESA2UJFAoMCgUEAAIBAxIDZRcY
CkoKBAQAAgISA2gCLxo9IFRvcCBsZXZlbCBwb2xpY3kgdGFncyBhc3NvY2lhdGVkIHdpdGgg
dGhlIHRheG9ub215LCBpZiBhbnkuCgoMCgUEAAICBBIDaAIKCgwKBQQAAgIGEgNoCx4KDAoF
BAACAgESA2gfKgoMCgUEAAICAxIDaC0uCkYKBAQAAgMSA2sCOho5IEEgbGlzdCBvZiBwb2xp
Y3kgdHlwZXMgdGhhdCBhcmUgYWN0aXZhdGVkIHBlciB0YXhvbm9teS4KCgwKBQQAAgMEEgNr
AgoKDAoFBAACAwYSA2sLHgoMCgUEAAIDARIDax81CgwKBQQAAgMDEgNrODkKXgoCBAESBXAA
gQEBGlEgQSBuZXN0ZWQgcHJvdG9jb2wgYnVmZmVyIHRoYXQgcmVwcmVzZW50cyBhIHBvbGlj
eSB0YWcgYW5kIGFsbCBpdHMKIGRlc2NlbmRhbnRzLgoKCgoDBAEBEgNwCBsKaAoEBAECABID
dAIYGlsgUmVzb3VyY2UgbmFtZSBvZiB0aGUgcG9saWN5IHRhZy4KCiBUaGlzIGZpZWxkIGlz
IGlnbm9yZWQgd2hlbiBjYWxsaW5nIGBJbXBvcnRUYXhvbm9taWVzYC4KCgwKBQQBAgAFEgN0
AggKDAoFBAECAAESA3QJEwoMCgUEAQIAAxIDdBYXCmIKBAQBAgESA3gCQxpVIFJlcXVpcmVk
LiBEaXNwbGF5IG5hbWUgb2YgdGhlIHBvbGljeSB0YWcuIEF0IG1vc3QgMjAwIGJ5dGVzIHdo
ZW4gZW5jb2RlZAogaW4gVVRGLTguCgoMCgUEAQIBBRIDeAIICgwKBQQBAgEBEgN4CRUKDAoF
BAECAQMSA3gYGQoMCgUEAQIBCBIDeBpCCg8KCAQBAgEInAgAEgN4G0EKkwEKBAQBAgISA30C
GRqFASBEZXNjcmlwdGlvbiBvZiB0aGUgc2VyaWFsaXplZCBwb2xpY3kgdGFnLiBBdCBtb3N0
CiAyMDAwIGJ5dGVzIHdoZW4gZW5jb2RlZCBpbiBVVEYtOC4gSWYgbm90IHNldCwgZGVmYXVs
dHMgdG8gYW4KIGVtcHR5IGRlc2NyaXB0aW9uLgoKDAoFBAECAgUSA30CCAoMCgUEAQICARID
fQkUCgwKBQQBAgIDEgN9FxgKMwoEBAECAxIEgAECNRolIENoaWxkcmVuIG9mIHRoZSBwb2xp
Y3kgdGFnLCBpZiBhbnkuCgoNCgUEAQIDBBIEgAECCgoNCgUEAQIDBhIEgAELHgoNCgUEAQID
ARIEgAEfMAoNCgUEAQIDAxIEgAEzNAqCAQoCBAISBoUBAJEBARp0IFJlcXVlc3QgbWVzc2Fn
ZSBmb3IKIFtSZXBsYWNlVGF4b25vbXldW2dvb2dsZS5jbG91ZC5kYXRhY2F0YWxvZy52MS5Q
b2xpY3lUYWdNYW5hZ2VyU2VyaWFsaXphdGlvbi5SZXBsYWNlVGF4b25vbXldLgoKCwoDBAIB
EgSFAQgeCkQKBAQCAgASBocBAowBBBo0IFJlcXVpcmVkLiBSZXNvdXJjZSBuYW1lIG9mIHRo
ZSB0YXhvbm9teSB0byB1cGRhdGUuCgoNCgUEAgIABRIEhwECCAoNCgUEAgIAARIEhwEJDQoN
CgUEAgIAAxIEhwEQEQoPCgUEAgIACBIGhwESjAEDChAKCAQCAgAInAgAEgSIAQQqChEKBwQC
AgAInwgSBokBBIsBBQpQCgQEAgIBEgaPAQKQAS8aQCBSZXF1aXJlZC4gVGF4b25vbXkgdG8g
dXBkYXRlIGFsb25nIHdpdGggaXRzIGNoaWxkIHBvbGljeSB0YWdzLgoKDQoFBAICAQYSBI8B
AhQKDQoFBAICAQESBI8BFSgKDQoFBAICAQMSBI8BKywKDQoFBAICAQgSBJABBi4KEAoIBAIC
AQicCAASBJABBy0KhAEKAgQDEgaVAQCnAQEadiBSZXF1ZXN0IG1lc3NhZ2UgZm9yCiBbSW1w
b3J0VGF4b25vbWllc11bZ29vZ2xlLmNsb3VkLmRhdGFjYXRhbG9nLnYxLlBvbGljeVRhZ01h
bmFnZXJTZXJpYWxpemF0aW9uLkltcG9ydFRheG9ub21pZXNdLgoKCwoDBAMBEgSVAQgfCmIK
BAQDAgASBpgBAp0BBBpSIFJlcXVpcmVkLiBSZXNvdXJjZSBuYW1lIG9mIHByb2plY3QgdGhh
dCB0aGUgaW1wb3J0ZWQgdGF4b25vbWllcyB3aWxsIGJlbG9uZwogdG8uCgoNCgUEAwIABRIE
mAECCAoNCgUEAwIAARIEmAEJDwoNCgUEAwIAAxIEmAESEwoPCgUEAwIACBIGmAEUnQEDChAK
CAQDAgAInAgAEgSZAQQqChEKBwQDAgAInwgSBpoBBJwBBQouCgQEAwgAEgagAQKmAQMaHiBT
b3VyY2UgdGF4b25vbWllcyB0byBpbXBvcnQuCgoNCgUEAwgAARIEoAEIDgoxCgQEAwIBEgSi
AQQjGiMgSW5saW5lIHNvdXJjZSB0YXhvbm9teSB0byBpbXBvcnQuCgoNCgUEAwIBBhIEogEE
EAoNCgUEAwIBARIEogERHgoNCgUEAwIBAxIEogEhIgo5CgQEAwICEgSlAQQyGisgQ3Jvc3Mt
cmVnaW9uYWwgc291cmNlIHRheG9ub215IHRvIGltcG9ydC4KCg0KBQQDAgIGEgSlAQQXCg0K
BQQDAgIBEgSlARgtCg0KBQQDAgIDEgSlATAxCj4KAgQEEgaqAQCuAQEaMCBJbmxpbmUgc291
cmNlIGNvbnRhaW5pbmcgdGF4b25vbWllcyB0byBpbXBvcnQuCgoLCgMEBAESBKoBCBQKMQoE
BAQCABIGrAECrQEvGiEgUmVxdWlyZWQuIFRheG9ub21pZXMgdG8gaW1wb3J0LgoKDQoFBAQC
AAQSBKwBAgoKDQoFBAQCAAYSBKwBCx0KDQoFBAQCAAESBKwBHigKDQoFBAQCAAMSBKwBKywK
DQoFBAQCAAgSBK0BBi4KEAoIBAQCAAicCAASBK0BBy0KYwoCBAUSBrIBALoBARpVIENyb3Nz
LXJlZ2lvbmFsIHNvdXJjZSB1c2VkIHRvIGltcG9ydCBhbiBleGlzdGluZyB0YXhvbm9teSBp
bnRvIGEgZGlmZmVyZW50CiByZWdpb24uCgoLCgMEBQESBLIBCBsKTwoEBAUCABIGtAECuQEE
Gj8gUmVxdWlyZWQuIFRoZSByZXNvdXJjZSBuYW1lIG9mIHRoZSBzb3VyY2UgdGF4b25vbXkg
dG8gaW1wb3J0LgoKDQoFBAUCAAUSBLQBAggKDQoFBAUCAAESBLQBCREKDQoFBAUCAAMSBLQB
FBUKDwoFBAUCAAgSBrQBFrkBAwoQCggEBQIACJwIABIEtQEEKgoRCgcEBQIACJ8IEga2AQS4
AQUKhQEKAgQGEga+AQDBAQEadyBSZXNwb25zZSBtZXNzYWdlIGZvcgogW0ltcG9ydFRheG9u
b21pZXNdW2dvb2dsZS5jbG91ZC5kYXRhY2F0YWxvZy52MS5Qb2xpY3lUYWdNYW5hZ2VyU2Vy
aWFsaXphdGlvbi5JbXBvcnRUYXhvbm9taWVzXS4KCgsKAwQGARIEvgEIIAokCgQEBgIAEgTA
AQIjGhYgSW1wb3J0ZWQgdGF4b25vbWllcy4KCg0KBQQGAgAEEgTAAQIKCg0KBQQGAgAGEgTA
AQsTCg0KBQQGAgABEgTAARQeCg0KBQQGAgADEgTAASEiCoQBCgIEBxIGxQEA3QEBGnYgUmVx
dWVzdCBtZXNzYWdlIGZvcgogW0V4cG9ydFRheG9ub21pZXNdW2dvb2dsZS5jbG91ZC5kYXRh
Y2F0YWxvZy52MS5Qb2xpY3lUYWdNYW5hZ2VyU2VyaWFsaXphdGlvbi5FeHBvcnRUYXhvbm9t
aWVzXS4KCgsKAwQHARIExQEIHwphCgQEBwIAEgbIAQLNAQQaUSBSZXF1aXJlZC4gUmVzb3Vy
Y2UgbmFtZSBvZiB0aGUgcHJvamVjdCB0aGF0IHRoZSBleHBvcnRlZCB0YXhvbm9taWVzIGJl
bG9uZwogdG8uCgoNCgUEBwIABRIEyAECCAoNCgUEBwIAARIEyAEJDwoNCgUEBwIAAxIEyAES
EwoPCgUEBwIACBIGyAEUzQEDChAKCAQHAgAInAgAEgTJAQQqChEKBwQHAgAInwgSBsoBBMwB
BQpHCgQEBwIBEgbQAQLVAQQaNyBSZXF1aXJlZC4gUmVzb3VyY2UgbmFtZXMgb2YgdGhlIHRh
eG9ub21pZXMgdG8gZXhwb3J0LgoKDQoFBAcCAQQSBNABAgoKDQoFBAcCAQUSBNABCxEKDQoF
BAcCAQESBNABEhwKDQoFBAcCAQMSBNABHyAKDwoFBAcCAQgSBtABIdUBAwoQCggEBwIBCJwI
ABIE0QEEKgoRCgcEBwIBCJ8IEgbSAQTUAQUKPgoEBAcIABIG2AEC3AEDGi4gUmVxdWlyZWQu
IEV4cG9ydCBkZXN0aW5hdGlvbiBmb3IgdGF4b25vbWllcy4KCg0KBQQHCAABEgTYAQgTCmoK
BAQHAgISBNsBBCMaXCBTZXJpYWxpemVkIGV4cG9ydCB0YXhvbm9taWVzIHRoYXQgY29udGFp
biBhbGwgdGhlIHBvbGljeQogdGFncyBhcyBuZXN0ZWQgcHJvdG9jb2wgYnVmZmVycy4KCg0K
BQQHAgIFEgTbAQQICg0KBQQHAgIBEgTbAQkeCg0KBQQHAgIDEgTbASEiCoUBCgIECBIG4QEA
5AEBGncgUmVzcG9uc2UgbWVzc2FnZSBmb3IKIFtFeHBvcnRUYXhvbm9taWVzXVtnb29nbGUu
Y2xvdWQuZGF0YWNhdGFsb2cudjEuUG9saWN5VGFnTWFuYWdlclNlcmlhbGl6YXRpb24uRXhw
b3J0VGF4b25vbWllc10uCgoLCgMECAESBOEBCCAKTgoEBAgCABIE4wECLRpAIExpc3Qgb2Yg
dGF4b25vbWllcyBhbmQgcG9saWN5IHRhZ3MgYXMgbmVzdGVkIHByb3RvY29sIGJ1ZmZlcnMu
CgoNCgUECAIABBIE4wECCgoNCgUECAIABhIE4wELHQoNCgUECAIAARIE4wEeKAoNCgUECAIA
AxIE4wErLGIGcHJvdG8z
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Datacatalog::V1::Policytagmanagerserialization::SerializedTaxonomy ===
    # Fields for SerializedTaxonomy
    # Field: display_name Type: 9 ()
    # Field: description Type: 9 ()
    # Field: policy_tags Type: 11 (.google.cloud.datacatalog.v1.SerializedPolicyTag)
    # Field: activated_policy_types Type: 14 (.google.cloud.datacatalog.v1.Taxonomy.PolicyType)

# === Message: Google::Cloud::Datacatalog::V1::Policytagmanagerserialization::SerializedPolicyTag ===
    # Fields for SerializedPolicyTag
    # Field: policy_tag Type: 9 ()
    # Field: display_name Type: 9 ()
    # Field: description Type: 9 ()
    # Field: child_policy_tags Type: 11 (.google.cloud.datacatalog.v1.SerializedPolicyTag)

# === Message: Google::Cloud::Datacatalog::V1::Policytagmanagerserialization::ReplaceTaxonomyRequest ===
    # Fields for ReplaceTaxonomyRequest
    # Field: name Type: 9 ()
    # Field: serialized_taxonomy Type: 11 (.google.cloud.datacatalog.v1.SerializedTaxonomy)

# === Message: Google::Cloud::Datacatalog::V1::Policytagmanagerserialization::ImportTaxonomiesRequest ===
    # Fields for ImportTaxonomiesRequest
    # Field: parent Type: 9 ()
    # Field: inline_source Type: 11 (.google.cloud.datacatalog.v1.InlineSource)
    # Field: cross_regional_source Type: 11 (.google.cloud.datacatalog.v1.CrossRegionalSource)

# === Message: Google::Cloud::Datacatalog::V1::Policytagmanagerserialization::InlineSource ===
    # Fields for InlineSource
    # Field: taxonomies Type: 11 (.google.cloud.datacatalog.v1.SerializedTaxonomy)

# === Message: Google::Cloud::Datacatalog::V1::Policytagmanagerserialization::CrossRegionalSource ===
    # Fields for CrossRegionalSource
    # Field: taxonomy Type: 9 ()

# === Message: Google::Cloud::Datacatalog::V1::Policytagmanagerserialization::ImportTaxonomiesResponse ===
    # Fields for ImportTaxonomiesResponse
    # Field: taxonomies Type: 11 (.google.cloud.datacatalog.v1.Taxonomy)

# === Message: Google::Cloud::Datacatalog::V1::Policytagmanagerserialization::ExportTaxonomiesRequest ===
    # Fields for ExportTaxonomiesRequest
    # Field: parent Type: 9 ()
    # Field: taxonomies Type: 9 ()
    # Field: serialized_taxonomies Type: 8 ()

# === Message: Google::Cloud::Datacatalog::V1::Policytagmanagerserialization::ExportTaxonomiesResponse ===
    # Fields for ExportTaxonomiesResponse
    # Field: taxonomies Type: 11 (.google.cloud.datacatalog.v1.SerializedTaxonomy)

# === Service Client: Google::Cloud::Datacatalog::V1::Policytagmanagerserialization::PolicyTagManagerSerializationClient ===
package Google::Cloud::Datacatalog::V1::Policytagmanagerserialization::PolicyTagManagerSerializationClient;

=pod

=head2 Service Client: Google::Cloud::Datacatalog::V1::Policytagmanagerserialization::PolicyTagManagerSerializationClient

Client stub representing the remote C<PolicyTagManagerSerialization> gRPC service. Delegates call dispatching to L<Google::gRPC::Client>.

=head3 target

The endpoint target address. Defaults to C<datacatalog.googleapis.com:443>.

=head3 credentials

The authentication credentials provider. Defaults to application default credentials via L<Google::Auth>.

=cut

use Moo;
use Google::Auth;
use Google::gRPC::Client;

has credentials => ( is => 'ro', default => sub { Google::Auth->default() } );
has target      => ( is => 'ro', default => 'datacatalog.googleapis.com:443' );

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

sub replace_taxonomy {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Datacatalog::V1::Policytagmanagerserialization::ReplaceTaxonomyRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.datacatalog.v1.PolicyTagManagerSerialization',
        method         => 'ReplaceTaxonomy',
        request        => $req,
        response_class => 'Google::Cloud::Datacatalog::V1::Policytagmanager::Taxonomy',
    });
}

sub import_taxonomies {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Datacatalog::V1::Policytagmanagerserialization::ImportTaxonomiesRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.datacatalog.v1.PolicyTagManagerSerialization',
        method         => 'ImportTaxonomies',
        request        => $req,
        response_class => 'Google::Cloud::Datacatalog::V1::Policytagmanagerserialization::ImportTaxonomiesResponse',
    });
}

sub export_taxonomies {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Datacatalog::V1::Policytagmanagerserialization::ExportTaxonomiesRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.datacatalog.v1.PolicyTagManagerSerialization',
        method         => 'ExportTaxonomies',
        request        => $req,
        response_class => 'Google::Cloud::Datacatalog::V1::Policytagmanagerserialization::ExportTaxonomiesResponse',
    });
}

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Datacatalog::V1::Policytagmanagerserialization - Compiled Protocol Buffers messages for google/cloud/datacatalog/v1/policytagmanagerserialization.proto

=head1 SYNOPSIS

    use Google::Cloud::Datacatalog::V1::Policytagmanagerserialization;

    my $msg = Google::Cloud::Datacatalog::V1::Policytagmanagerserialization::SerializedTaxonomy->new({
        display_name => $display_name,
        description => $description,
        policy_tags => $policy_tags,
        activated_policy_types => $activated_policy_types,
    });

    # Read or update a field
    my $val = $msg->display_name();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Datacatalog::V1::Policytagmanagerserialization::SerializedTaxonomy->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/datacatalog/v1/policytagmanagerserialization.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Datacatalog::V1::Policytagmanagerserialization::SerializedTaxonomy

A nested protocol buffer that represents a taxonomy and the hierarchy of its
policy tags. Used for taxonomy replacement, import, and
export.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->display_name() >> / C<< $msg->display_name($value) >>

Type: C<String>

Required. Display name of the taxonomy. At most 200 bytes when encoded in
UTF-8.

=item * C<< $msg->description() >> / C<< $msg->description($value) >>

Type: C<String>

Description of the serialized taxonomy. At most 2000 bytes when
encoded in UTF-8. If not set, defaults to an empty description.

=item * C<< $msg->policy_tags() >> / C<< $msg->policy_tags($value) >>

Type: C<Message> (L<Google::Cloud::Datacatalog::V1::Policytagmanagerserialization::SerializedPolicyTag>)

Top level policy tags associated with the taxonomy, if any.

=item * C<< $msg->activated_policy_types() >> / C<< $msg->activated_policy_types($value) >>

Type: C<Enum> (L<Google::Cloud::Datacatalog::V1::Taxonomy::PolicyType>)

A list of policy types that are activated per taxonomy.

=back

=head2 Google::Cloud::Datacatalog::V1::Policytagmanagerserialization::SerializedPolicyTag

A nested protocol buffer that represents a policy tag and all its
descendants.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->policy_tag() >> / C<< $msg->policy_tag($value) >>

Type: C<String>

Resource name of the policy tag.

This field is ignored when calling `ImportTaxonomies`.

=item * C<< $msg->display_name() >> / C<< $msg->display_name($value) >>

Type: C<String>

Required. Display name of the policy tag. At most 200 bytes when encoded
in UTF-8.

=item * C<< $msg->description() >> / C<< $msg->description($value) >>

Type: C<String>

Description of the serialized policy tag. At most
2000 bytes when encoded in UTF-8. If not set, defaults to an
empty description.

=item * C<< $msg->child_policy_tags() >> / C<< $msg->child_policy_tags($value) >>

Type: C<Message> (L<Google::Cloud::Datacatalog::V1::Policytagmanagerserialization::SerializedPolicyTag>)

Children of the policy tag, if any.

=back

=head2 Google::Cloud::Datacatalog::V1::Policytagmanagerserialization::ReplaceTaxonomyRequest

Request message for
[ReplaceTaxonomy][google.cloud.datacatalog.v1.PolicyTagManagerSerialization.ReplaceTaxonomy].

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. Resource name of the taxonomy to update.

=item * C<< $msg->serialized_taxonomy() >> / C<< $msg->serialized_taxonomy($value) >>

Type: C<Message> (L<Google::Cloud::Datacatalog::V1::Policytagmanagerserialization::SerializedTaxonomy>)

Required. Taxonomy to update along with its child policy tags.

=back

=head2 Google::Cloud::Datacatalog::V1::Policytagmanagerserialization::ImportTaxonomiesRequest

Request message for
[ImportTaxonomies][google.cloud.datacatalog.v1.PolicyTagManagerSerialization.ImportTaxonomies].

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->parent() >> / C<< $msg->parent($value) >>

Type: C<String>

Required. Resource name of project that the imported taxonomies will belong
to.

=item * C<< $msg->inline_source() >> / C<< $msg->inline_source($value) >>

Type: C<Message> (L<Google::Cloud::Datacatalog::V1::Policytagmanagerserialization::InlineSource>)

Inline source taxonomy to import.

=item * C<< $msg->cross_regional_source() >> / C<< $msg->cross_regional_source($value) >>

Type: C<Message> (L<Google::Cloud::Datacatalog::V1::Policytagmanagerserialization::CrossRegionalSource>)

Cross-regional source taxonomy to import.

=back

=head2 Google::Cloud::Datacatalog::V1::Policytagmanagerserialization::InlineSource

Inline source containing taxonomies to import.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->taxonomies() >> / C<< $msg->taxonomies($value) >>

Type: C<Message> (L<Google::Cloud::Datacatalog::V1::Policytagmanagerserialization::SerializedTaxonomy>)

Required. Taxonomies to import.

=back

=head2 Google::Cloud::Datacatalog::V1::Policytagmanagerserialization::CrossRegionalSource

Cross-regional source used to import an existing taxonomy into a different
region.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->taxonomy() >> / C<< $msg->taxonomy($value) >>

Type: C<String>

Required. The resource name of the source taxonomy to import.

=back

=head2 Google::Cloud::Datacatalog::V1::Policytagmanagerserialization::ImportTaxonomiesResponse

Response message for
[ImportTaxonomies][google.cloud.datacatalog.v1.PolicyTagManagerSerialization.ImportTaxonomies].

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->taxonomies() >> / C<< $msg->taxonomies($value) >>

Type: C<Message> (L<Google::Cloud::Datacatalog::V1::Policytagmanager::Taxonomy>)

Imported taxonomies.

=back

=head2 Google::Cloud::Datacatalog::V1::Policytagmanagerserialization::ExportTaxonomiesRequest

Request message for
[ExportTaxonomies][google.cloud.datacatalog.v1.PolicyTagManagerSerialization.ExportTaxonomies].

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->parent() >> / C<< $msg->parent($value) >>

Type: C<String>

Required. Resource name of the project that the exported taxonomies belong
to.

=item * C<< $msg->taxonomies() >> / C<< $msg->taxonomies($value) >>

Type: C<String>

Required. Resource names of the taxonomies to export.

=item * C<< $msg->serialized_taxonomies() >> / C<< $msg->serialized_taxonomies($value) >>

Type: C<Bool>

Serialized export taxonomies that contain all the policy
tags as nested protocol buffers.

=back

=head2 Google::Cloud::Datacatalog::V1::Policytagmanagerserialization::ExportTaxonomiesResponse

Response message for
[ExportTaxonomies][google.cloud.datacatalog.v1.PolicyTagManagerSerialization.ExportTaxonomies].

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->taxonomies() >> / C<< $msg->taxonomies($value) >>

Type: C<Message> (L<Google::Cloud::Datacatalog::V1::Policytagmanagerserialization::SerializedTaxonomy>)

List of taxonomies and policy tags as nested protocol buffers.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Datacatalog::V1::Policytagmanagerserialization::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
