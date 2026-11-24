package Google::Devtools::Artifactregistry::V1::Version;

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
    eval { require Google::Devtools::Artifactregistry::V1::File };
    eval { require Google::Devtools::Artifactregistry::V1::Tag };
    eval { require Google::Protobuf::FieldMask };
    eval { require Google::Protobuf::Struct };
    eval { require Google::Protobuf::Timestamp };
    my $descriptor_b64 = <<'EOF';
CjFnb29nbGUvZGV2dG9vbHMvYXJ0aWZhY3RyZWdpc3RyeS92MS92ZXJzaW9uLnByb3RvEiNn
b29nbGUuZGV2dG9vbHMuYXJ0aWZhY3RyZWdpc3RyeS52MRofZ29vZ2xlL2FwaS9maWVsZF9i
ZWhhdmlvci5wcm90bxoZZ29vZ2xlL2FwaS9yZXNvdXJjZS5wcm90bxouZ29vZ2xlL2RldnRv
b2xzL2FydGlmYWN0cmVnaXN0cnkvdjEvZmlsZS5wcm90bxotZ29vZ2xlL2RldnRvb2xzL2Fy
dGlmYWN0cmVnaXN0cnkvdjEvdGFnLnByb3RvGiBnb29nbGUvcHJvdG9idWYvZmllbGRfbWFz
ay5wcm90bxocZ29vZ2xlL3Byb3RvYnVmL3N0cnVjdC5wcm90bxofZ29vZ2xlL3Byb3RvYnVm
L3RpbWVzdGFtcC5wcm90byLTBQoHVmVyc2lvbhISCgRuYW1lGAEgASgJUgRuYW1lEiAKC2Rl
c2NyaXB0aW9uGAMgASgJUgtkZXNjcmlwdGlvbhI7CgtjcmVhdGVfdGltZRgFIAEoCzIaLmdv
b2dsZS5wcm90b2J1Zi5UaW1lc3RhbXBSCmNyZWF0ZVRpbWUSOwoLdXBkYXRlX3RpbWUYBiAB
KAsyGi5nb29nbGUucHJvdG9idWYuVGltZXN0YW1wUgp1cGRhdGVUaW1lEksKDHJlbGF0ZWRf
dGFncxgHIAMoCzIoLmdvb2dsZS5kZXZ0b29scy5hcnRpZmFjdHJlZ2lzdHJ5LnYxLlRhZ1IL
cmVsYXRlZFRhZ3MSOAoIbWV0YWRhdGEYCCABKAsyFy5nb29nbGUucHJvdG9idWYuU3RydWN0
QgPgQQNSCG1ldGFkYXRhEmQKC2Fubm90YXRpb25zGAkgAygLMj0uZ29vZ2xlLmRldnRvb2xz
LmFydGlmYWN0cmVnaXN0cnkudjEuVmVyc2lvbi5Bbm5vdGF0aW9uc0VudHJ5QgPgQQFSC2Fu
bm90YXRpb25zElIKDGZpbmdlcnByaW50cxgKIAMoCzIpLmdvb2dsZS5kZXZ0b29scy5hcnRp
ZmFjdHJlZ2lzdHJ5LnYxLkhhc2hCA+BBA1IMZmluZ2VycHJpbnRzGj4KEEFubm90YXRpb25z
RW50cnkSEAoDa2V5GAEgASgJUgNrZXkSFAoFdmFsdWUYAiABKAlSBXZhbHVlOgI4ATqWAepB
kgEKJ2FydGlmYWN0cmVnaXN0cnkuZ29vZ2xlYXBpcy5jb20vVmVyc2lvbhJncHJvamVjdHMv
e3Byb2plY3R9L2xvY2F0aW9ucy97bG9jYXRpb259L3JlcG9zaXRvcmllcy97cmVwb3NpdG9y
eX0vcGFja2FnZXMve3BhY2thZ2V9L3ZlcnNpb25zL3t2ZXJzaW9ufSLsAQoTTGlzdFZlcnNp
b25zUmVxdWVzdBIWCgZwYXJlbnQYASABKAlSBnBhcmVudBIbCglwYWdlX3NpemUYAiABKAVS
CHBhZ2VTaXplEh0KCnBhZ2VfdG9rZW4YAyABKAlSCXBhZ2VUb2tlbhJECgR2aWV3GAQgASgO
MjAuZ29vZ2xlLmRldnRvb2xzLmFydGlmYWN0cmVnaXN0cnkudjEuVmVyc2lvblZpZXdSBHZp
ZXcSHgoIb3JkZXJfYnkYBSABKAlCA+BBAVIHb3JkZXJCeRIbCgZmaWx0ZXIYBiABKAlCA+BB
AVIGZmlsdGVyIogBChRMaXN0VmVyc2lvbnNSZXNwb25zZRJICgh2ZXJzaW9ucxgBIAMoCzIs
Lmdvb2dsZS5kZXZ0b29scy5hcnRpZmFjdHJlZ2lzdHJ5LnYxLlZlcnNpb25SCHZlcnNpb25z
EiYKD25leHRfcGFnZV90b2tlbhgCIAEoCVINbmV4dFBhZ2VUb2tlbiJtChFHZXRWZXJzaW9u
UmVxdWVzdBISCgRuYW1lGAEgASgJUgRuYW1lEkQKBHZpZXcYAiABKA4yMC5nb29nbGUuZGV2
dG9vbHMuYXJ0aWZhY3RyZWdpc3RyeS52MS5WZXJzaW9uVmlld1IEdmlldyJAChREZWxldGVW
ZXJzaW9uUmVxdWVzdBISCgRuYW1lGAEgASgJUgRuYW1lEhQKBWZvcmNlGAIgASgIUgVmb3Jj
ZSLOAQoaQmF0Y2hEZWxldGVWZXJzaW9uc1JlcXVlc3QSRAoGcGFyZW50GAEgASgJQiz6QSkS
J2FydGlmYWN0cmVnaXN0cnkuZ29vZ2xlYXBpcy5jb20vVmVyc2lvblIGcGFyZW50EkUKBW5h
bWVzGAIgAygJQi/gQQL6QSkKJ2FydGlmYWN0cmVnaXN0cnkuZ29vZ2xlYXBpcy5jb20vVmVy
c2lvblIFbmFtZXMSIwoNdmFsaWRhdGVfb25seRgDIAEoCFIMdmFsaWRhdGVPbmx5IkYKG0Jh
dGNoRGVsZXRlVmVyc2lvbnNNZXRhZGF0YRInCg9mYWlsZWRfdmVyc2lvbnMYAiADKAlSDmZh
aWxlZFZlcnNpb25zIqABChRVcGRhdGVWZXJzaW9uUmVxdWVzdBJLCgd2ZXJzaW9uGAEgASgL
MiwuZ29vZ2xlLmRldnRvb2xzLmFydGlmYWN0cmVnaXN0cnkudjEuVmVyc2lvbkID4EECUgd2
ZXJzaW9uEjsKC3VwZGF0ZV9tYXNrGAIgASgLMhouZ29vZ2xlLnByb3RvYnVmLkZpZWxkTWFz
a1IKdXBkYXRlTWFzaypACgtWZXJzaW9uVmlldxIcChhWRVJTSU9OX1ZJRVdfVU5TUEVDSUZJ
RUQQABIJCgVCQVNJQxABEggKBEZVTEwQAkL3AQonY29tLmdvb2dsZS5kZXZ0b29scy5hcnRp
ZmFjdHJlZ2lzdHJ5LnYxQgxWZXJzaW9uUHJvdG9QAVpQY2xvdWQuZ29vZ2xlLmNvbS9nby9h
cnRpZmFjdHJlZ2lzdHJ5L2FwaXYxL2FydGlmYWN0cmVnaXN0cnlwYjthcnRpZmFjdHJlZ2lz
dHJ5cGKqAiBHb29nbGUuQ2xvdWQuQXJ0aWZhY3RSZWdpc3RyeS5WMcoCIEdvb2dsZVxDbG91
ZFxBcnRpZmFjdFJlZ2lzdHJ5XFYx6gIjR29vZ2xlOjpDbG91ZDo6QXJ0aWZhY3RSZWdpc3Ry
eTo6VjFKzz8KBxIFDgDfAQEKvAQKAQwSAw4AEjKxBCBDb3B5cmlnaHQgMjAyNiBHb29nbGUg
TExDCgogTGljZW5zZWQgdW5kZXIgdGhlIEFwYWNoZSBMaWNlbnNlLCBWZXJzaW9uIDIuMCAo
dGhlICJMaWNlbnNlIik7CiB5b3UgbWF5IG5vdCB1c2UgdGhpcyBmaWxlIGV4Y2VwdCBpbiBj
b21wbGlhbmNlIHdpdGggdGhlIExpY2Vuc2UuCiBZb3UgbWF5IG9idGFpbiBhIGNvcHkgb2Yg
dGhlIExpY2Vuc2UgYXQKCiAgICAgaHR0cDovL3d3dy5hcGFjaGUub3JnL2xpY2Vuc2VzL0xJ
Q0VOU0UtMi4wCgogVW5sZXNzIHJlcXVpcmVkIGJ5IGFwcGxpY2FibGUgbGF3IG9yIGFncmVl
ZCB0byBpbiB3cml0aW5nLCBzb2Z0d2FyZQogZGlzdHJpYnV0ZWQgdW5kZXIgdGhlIExpY2Vu
c2UgaXMgZGlzdHJpYnV0ZWQgb24gYW4gIkFTIElTIiBCQVNJUywKIFdJVEhPVVQgV0FSUkFO
VElFUyBPUiBDT05ESVRJT05TIE9GIEFOWSBLSU5ELCBlaXRoZXIgZXhwcmVzcyBvciBpbXBs
aWVkLgogU2VlIHRoZSBMaWNlbnNlIGZvciB0aGUgc3BlY2lmaWMgbGFuZ3VhZ2UgZ292ZXJu
aW5nIHBlcm1pc3Npb25zIGFuZAogbGltaXRhdGlvbnMgdW5kZXIgdGhlIExpY2Vuc2UuCgoI
CgECEgMQACwKCQoCAwASAxIAKQoJCgIDARIDEwAjCgkKAgMCEgMUADgKCQoCAwMSAxUANwoJ
CgIDBBIDFgAqCgkKAgMFEgMXACYKCQoCAwYSAxgAKQoICgEIEgMaAD0KCQoCCCUSAxoAPQoI
CgEIEgMbAGcKCQoCCAsSAxsAZwoICgEIEgMcACIKCQoCCAoSAxwAIgoICgEIEgMdAC0KCQoC
CAgSAx0ALQoICgEIEgMeAEAKCQoCCAESAx4AQAoICgEIEgMfAD0KCQoCCCkSAx8APQoICgEI
EgMgADwKCQoCCC0SAyAAPApdCgIFABIEJAAuARpRIFRoZSB2aWV3LCB3aGljaCBkZXRlcm1p
bmVzIHdoYXQgdmVyc2lvbiBpbmZvcm1hdGlvbiBpcyByZXR1cm5lZCBpbiBhCiByZXNwb25z
ZS4KCgoKAwUAARIDJAUQClIKBAUAAgASAycCHxpFIFRoZSBkZWZhdWx0IC8gdW5zZXQgdmFs
dWUuCiBUaGUgQVBJIHdpbGwgZGVmYXVsdCB0byB0aGUgQkFTSUMgdmlldy4KCgwKBQUAAgAB
EgMnAhoKDAoFBQACAAISAycdHgpWCgQFAAIBEgMqAgwaSSBJbmNsdWRlcyBiYXNpYyBpbmZv
cm1hdGlvbiBhYm91dCB0aGUgdmVyc2lvbiwgYnV0IG5vdCBhbnkgcmVsYXRlZCB0YWdzLgoK
DAoFBQACAQESAyoCBwoMCgUFAAIBAhIDKgoLCiIKBAUAAgISAy0CCxoVIEluY2x1ZGUgZXZl
cnl0aGluZy4KCgwKBQUAAgIBEgMtAgYKDAoFBQACAgISAy0JCgrNAQoCBAASBDMAWwEawAEg
VGhlIGJvZHkgb2YgYSB2ZXJzaW9uIHJlc291cmNlLiBBIHZlcnNpb24gcmVzb3VyY2UgcmVw
cmVzZW50cyBhCiBjb2xsZWN0aW9uIG9mIGNvbXBvbmVudHMsIHN1Y2ggYXMgZmlsZXMgYW5k
IG90aGVyIGRhdGEuIFRoaXMgbWF5IGNvcnJlc3BvbmQKIHRvIGEgdmVyc2lvbiBpbiBtYW55
IHBhY2thZ2UgbWFuYWdlbWVudCBzY2hlbWVzLgoKCgoDBAABEgMzCA8KCwoDBAAHEgQ0AjcE
Cg0KBQQAB50IEgQ0AjcECtkBCgQEAAIAEgM9AhIaywEgVGhlIG5hbWUgb2YgdGhlIHZlcnNp
b24sIGZvciBleGFtcGxlOgogYHByb2plY3RzL3AxL2xvY2F0aW9ucy91cy1jZW50cmFsMS9y
ZXBvc2l0b3JpZXMvcmVwbzEvcGFja2FnZXMvcGtnMS92ZXJzaW9ucy9hcnQxYC4KIElmIHRo
ZSBwYWNrYWdlIG9yIHZlcnNpb24gSUQgcGFydHMgY29udGFpbiBzbGFzaGVzLCB0aGUgc2xh
c2hlcyBhcmUKIGVzY2FwZWQuCgoMCgUEAAIABRIDPQIICgwKBQQAAgABEgM9CQ0KDAoFBAAC
AAMSAz0QEQpSCgQEAAIBEgNAAhkaRSBPcHRpb25hbC4gRGVzY3JpcHRpb24gb2YgdGhlIHZl
cnNpb24sIGFzIHNwZWNpZmllZCBpbiBpdHMgbWV0YWRhdGEuCgoMCgUEAAIBBRIDQAIICgwK
BQQAAgEBEgNACRQKDAoFBAACAQMSA0AXGAo1CgQEAAICEgNDAiwaKCBUaGUgdGltZSB3aGVu
IHRoZSB2ZXJzaW9uIHdhcyBjcmVhdGVkLgoKDAoFBAACAgYSA0MCGwoMCgUEAAICARIDQxwn
CgwKBQQAAgIDEgNDKisKOgoEBAACAxIDRgIsGi0gVGhlIHRpbWUgd2hlbiB0aGUgdmVyc2lv
biB3YXMgbGFzdCB1cGRhdGVkLgoKDAoFBAACAwYSA0YCGwoMCgUEAAIDARIDRhwnCgwKBQQA
AgMDEgNGKisKbQoEBAACBBIDSgIgGmAgT3V0cHV0IG9ubHkuIEEgbGlzdCBvZiByZWxhdGVk
IHRhZ3MuIFdpbGwgY29udGFpbiB1cCB0byAxMDAgdGFncyB0aGF0CiByZWZlcmVuY2UgdGhp
cyB2ZXJzaW9uLgoKDAoFBAACBAQSA0oCCgoMCgUEAAIEBhIDSgsOCgwKBQQAAgQBEgNKDxsK
DAoFBAACBAMSA0oeHwrQAgoEBAACBRIEUQJSMhrBAiBPdXRwdXQgb25seS4gUmVwb3NpdG9y
eS1zcGVjaWZpYyBNZXRhZGF0YSBzdG9yZWQgYWdhaW5zdCB0aGlzIHZlcnNpb24uCiBUaGUg
ZmllbGRzIHJldHVybmVkIGFyZSBkZWZpbmVkIGJ5IHRoZSB1bmRlcmx5aW5nIHJlcG9zaXRv
cnktc3BlY2lmaWMKIHJlc291cmNlLiBDdXJyZW50bHksIHRoZSByZXNvdXJjZXMgY291bGQg
YmU6CiBbRG9ja2VySW1hZ2VdW2dvb2dsZS5kZXZ0b29scy5hcnRpZmFjdHJlZ2lzdHJ5LnYx
LkRvY2tlckltYWdlXQogW01hdmVuQXJ0aWZhY3RdW2dvb2dsZS5kZXZ0b29scy5hcnRpZmFj
dHJlZ2lzdHJ5LnYxLk1hdmVuQXJ0aWZhY3RdCgoMCgUEAAIFBhIDUQIYCgwKBQQAAgUBEgNR
GSEKDAoFBAACBQMSA1EkJQoMCgUEAAIFCBIDUgYxCg8KCAQAAgUInAgAEgNSBzAKNgoEBAAC
BhIDVQJPGikgT3B0aW9uYWwuIENsaWVudCBzcGVjaWZpZWQgYW5ub3RhdGlvbnMuCgoMCgUE
AAIGBhIDVQIVCgwKBQQAAgYBEgNVFiEKDAoFBAACBgMSA1UkJQoMCgUEAAIGCBIDVSZOCg8K
CAQAAgYInAgAEgNVJ00K3QEKBAQAAgcSA1oCThrPASBPdXRwdXQgb25seS4gSW1tdXRhYmxl
IHJlZmVyZW5jZSBmb3IgdGhlIHZlcnNpb24sIGNhbGN1bGF0ZWQgYmFzZWQgb24gdGhlCiB2
ZXJzaW9uJ3MgY29udGVudC4gQ3VycmVudGx5IHdlIG9ubHkgc3VwcG9ydCBkaXJzdW1fc2hh
MjU2IGhhc2ggYWxnb3JpdGhtLgogQWRkaXRpb25hbCBoYXNoIGFsZ29yaXRobXMgbWF5IGJl
IGFkZGVkIGluIHRoZSBmdXR1cmUuCgoMCgUEAAIHBBIDWgIKCgwKBQQAAgcGEgNaCw8KDAoF
BAACBwESA1oQHAoMCgUEAAIHAxIDWh8hCgwKBQQAAgcIEgNaIk0KDwoIBAACBwicCAASA1oj
TAosCgIEARIFXgCcAQEaHyBUaGUgcmVxdWVzdCB0byBsaXN0IHZlcnNpb25zLgoKCgoDBAEB
EgNeCBsKTQoEBAECABIDYAIUGkAgVGhlIG5hbWUgb2YgdGhlIHBhcmVudCByZXNvdXJjZSB3
aG9zZSB2ZXJzaW9ucyB3aWxsIGJlIGxpc3RlZC4KCgwKBQQBAgAFEgNgAggKDAoFBAECAAES
A2AJDwoMCgUEAQIAAxIDYBITClQKBAQBAgESA2MCFhpHIFRoZSBtYXhpbXVtIG51bWJlciBv
ZiB2ZXJzaW9ucyB0byByZXR1cm4uIE1heGltdW0gcGFnZSBzaXplIGlzIDEsMDAwLgoKDAoF
BAECAQUSA2MCBwoMCgUEAQIBARIDYwgRCgwKBQQBAgEDEgNjFBUKVwoEBAECAhIDZgIYGkog
VGhlIG5leHRfcGFnZV90b2tlbiB2YWx1ZSByZXR1cm5lZCBmcm9tIGEgcHJldmlvdXMgbGlz
dCByZXF1ZXN0LCBpZiBhbnkuCgoMCgUEAQICBRIDZgIICgwKBQQBAgIBEgNmCRMKDAoFBAEC
AgMSA2YWFwpACgQEAQIDEgNpAhcaMyBUaGUgdmlldyB0aGF0IHNob3VsZCBiZSByZXR1cm5l
ZCBpbiB0aGUgcmVzcG9uc2UuCgoMCgUEAQIDBhIDaQINCgwKBQQBAgMBEgNpDhIKDAoFBAEC
AwMSA2kVFgo7CgQEAQIEEgNsAj8aLiBPcHRpb25hbC4gVGhlIGZpZWxkIHRvIG9yZGVyIHRo
ZSByZXN1bHRzIGJ5LgoKDAoFBAECBAUSA2wCCAoMCgUEAQIEARIDbAkRCgwKBQQBAgQDEgNs
FBUKDAoFBAECBAgSA2wWPgoPCggEAQIECJwIABIDbBc9CroPCgQEAQIFEgSbAQI9GqsPIE9w
dGlvbmFsLiBBbiBleHByZXNzaW9uIGZvciBmaWx0ZXJpbmcgdGhlIHJlc3VsdHMgb2YgdGhl
IHJlcXVlc3QuIEZpbHRlcgogcnVsZXMgYXJlIGNhc2UgaW5zZW5zaXRpdmUuIFRoZSBmaWVs
ZHMgZWxpZ2libGUgZm9yIGZpbHRlcmluZyBhcmU6CgogICAqIGBuYW1lYAogICAqIGBhbm5v
dGF0aW9uc2AKCiAgRXhhbXBsZXMgb2YgdXNpbmcgYSBmaWx0ZXI6CgogIFRvIGZpbHRlciB0
aGUgcmVzdWx0cyBvZiB5b3VyIHJlcXVlc3QgdG8gdmVyc2lvbnMgd2l0aCB0aGUgbmFtZQog
IGBteS12ZXJzaW9uYCBpbiBwcm9qZWN0IGBteS1wcm9qZWN0YCBpbiB0aGUgYHVzLWNlbnRy
YWxgIHJlZ2lvbiwgaW4KICByZXBvc2l0b3J5IGBteS1yZXBvYCwgYXBwZW5kIHRoZSBmb2xs
b3dpbmcgZmlsdGVyIGV4cHJlc3Npb24gdG8geW91cgogIHJlcXVlc3Q6CgogICAqIGBuYW1l
PSJwcm9qZWN0cy9teS1wcm9qZWN0L2xvY2F0aW9ucy91cy1jZW50cmFsMS9yZXBvc2l0b3Jp
ZXMvbXktcmVwby9wYWNrYWdlcy9teS1wYWNrYWdlL3ZlcnNpb25zL215LXZlcnNpb24iYAoK
ICBZb3UgY2FuIGFsc28gdXNlIHdpbGRjYXJkcyB0byBtYXRjaCBhbnkgbnVtYmVyIG9mIGNo
YXJhY3RlcnMgYmVmb3JlIG9yCiAgYWZ0ZXIgdGhlIHZhbHVlOgoKICAgKiBgbmFtZT0icHJv
amVjdHMvbXktcHJvamVjdC9sb2NhdGlvbnMvdXMtY2VudHJhbDEvcmVwb3NpdG9yaWVzL215
LXJlcG8vcGFja2FnZXMvbXktcGFja2FnZS92ZXJzaW9ucy8qdmVyc2lvbiJgCiAgICogYG5h
bWU9InByb2plY3RzL215LXByb2plY3QvbG9jYXRpb25zL3VzLWNlbnRyYWwxL3JlcG9zaXRv
cmllcy9teS1yZXBvL3BhY2thZ2VzL215LXBhY2thZ2UvdmVyc2lvbnMvbXkqImAKICAgKiBg
bmFtZT0icHJvamVjdHMvbXktcHJvamVjdC9sb2NhdGlvbnMvdXMtY2VudHJhbDEvcmVwb3Np
dG9yaWVzL215LXJlcG8vcGFja2FnZXMvbXktcGFja2FnZS92ZXJzaW9ucy8qdmVyc2lvbioi
YAoKICBUbyBmaWx0ZXIgdGhlIHJlc3VsdHMgb2YgeW91ciByZXF1ZXN0IHRvIHZlcnNpb25z
IHdpdGggdGhlIGFubm90YXRpb24KICBrZXktdmFsdWUgcGFpciBbYGV4dGVybmFsX2xpbmtg
OiBgZXh0ZXJuYWxfbGlua192YWx1ZWBdLCBhcHBlbmQgdGhlCiAgZm9sbG93aW5nIGZpbHRl
ciBleHByZXNzaW9uIHRvIHlvdXIgcmVxdWVzdDoKCiAgICogYCJhbm5vdGF0aW9ucy5leHRl
cm5hbF9saW5rOmV4dGVybmFsX2xpbmtfdmFsdWUiYAoKICBUbyBmaWx0ZXIganVzdCBmb3Ig
YSBzcGVjaWZpYyBhbm5vdGF0aW9uIGtleSBgZXh0ZXJuYWxfbGlua2AsIGFwcGVuZCB0aGUK
ICBmb2xsb3dpbmcgZmlsdGVyIGV4cHJlc3Npb24gdG8geW91ciByZXF1ZXN0OgoKICAgKiBg
ImFubm90YXRpb25zLmV4dGVybmFsX2xpbmsiYAoKICBJZiB0aGUgYW5ub3RhdGlvbiBrZXkg
b3IgdmFsdWUgY29udGFpbnMgc3BlY2lhbCBjaGFyYWN0ZXJzLCB5b3UgY2FuIGVzY2FwZQog
IHRoZW0gYnkgc3Vycm91bmRpbmcgdGhlIHZhbHVlIHdpdGggYmFja3RpY2tzLiBGb3IgZXhh
bXBsZSwgdG8gZmlsdGVyIHRoZQogIHJlc3VsdHMgb2YgeW91ciByZXF1ZXN0IHRvIHZlcnNp
b25zIHdpdGggdGhlIGFubm90YXRpb24ga2V5LXZhbHVlIHBhaXIKICBbYGV4dGVybmFsLmxp
bmtgOmBodHRwczovL2V4YW1wbGUuY29tL215LXZlcnNpb25gXSwgYXBwZW5kIHRoZSBmb2xs
b3dpbmcKICBmaWx0ZXIgZXhwcmVzc2lvbiB0byB5b3VyIHJlcXVlc3Q6CgogICAqIGBgICJh
bm5vdGF0aW9ucy5gZXh0ZXJuYWwubGlua2A6YGh0dHBzOi8vZXhhbXBsZS5jb20vbXktdmVy
c2lvbmAiIGBgCgogIFlvdSBjYW4gYWxzbyBmaWx0ZXIgd2l0aCBhbm5vdGF0aW9ucyB3aXRo
IGEgd2lsZGNhcmQgdG8KICBtYXRjaCBhbnkgbnVtYmVyIG9mIGNoYXJhY3RlcnMgYmVmb3Jl
IG9yIGFmdGVyIHRoZSB2YWx1ZToKCiAgICogYGAgImFubm90YXRpb25zLipfbGluazpgKmV4
YW1wbGUuY29tKmAiIGBgCgoNCgUEAQIFBRIEmwECCAoNCgUEAQIFARIEmwEJDwoNCgUEAQIF
AxIEmwESEwoNCgUEAQIFCBIEmwEUPAoQCggEAQIFCJwIABIEmwEVOwozCgIEAhIGnwEApgEB
GiUgVGhlIHJlc3BvbnNlIGZyb20gbGlzdGluZyB2ZXJzaW9ucy4KCgsKAwQCARIEnwEIHAom
CgQEAgIAEgShAQIgGhggVGhlIHZlcnNpb25zIHJldHVybmVkLgoKDQoFBAICAAQSBKEBAgoK
DQoFBAICAAYSBKEBCxIKDQoFBAICAAESBKEBExsKDQoFBAICAAMSBKEBHh8KcwoEBAICARIE
pQECHRplIFRoZSB0b2tlbiB0byByZXRyaWV2ZSB0aGUgbmV4dCBwYWdlIG9mIHZlcnNpb25z
LCBvciBlbXB0eSBpZiB0aGVyZSBhcmUgbm8KIG1vcmUgdmVyc2lvbnMgdG8gcmV0dXJuLgoK
DQoFBAICAQUSBKUBAggKDQoFBAICAQESBKUBCRgKDQoFBAICAQMSBKUBGxwKMgoCBAMSBqkB
AK8BARokIFRoZSByZXF1ZXN0IHRvIHJldHJpZXZlIGEgdmVyc2lvbi4KCgsKAwQDARIEqQEI
GQo0CgQEAwIAEgSrAQISGiYgVGhlIG5hbWUgb2YgdGhlIHZlcnNpb24gdG8gcmV0cmlldmUu
CgoNCgUEAwIABRIEqwECCAoNCgUEAwIAARIEqwEJDQoNCgUEAwIAAxIEqwEQEQpBCgQEAwIB
EgSuAQIXGjMgVGhlIHZpZXcgdGhhdCBzaG91bGQgYmUgcmV0dXJuZWQgaW4gdGhlIHJlc3Bv
bnNlLgoKDQoFBAMCAQYSBK4BAg0KDQoFBAMCAQESBK4BDhIKDQoFBAMCAQMSBK4BFRYKMAoC
BAQSBrIBALkBARoiIFRoZSByZXF1ZXN0IHRvIGRlbGV0ZSBhIHZlcnNpb24uCgoLCgMEBAES
BLIBCBwKMgoEBAQCABIEtAECEhokIFRoZSBuYW1lIG9mIHRoZSB2ZXJzaW9uIHRvIGRlbGV0
ZS4KCg0KBQQEAgAFEgS0AQIICg0KBQQEAgABEgS0AQkNCg0KBQQEAgADEgS0ARARCpcBCgQE
BAIBEgS4AQIRGogBIEJ5IGRlZmF1bHQsIGEgdmVyc2lvbiB0aGF0IGlzIHRhZ2dlZCBtYXkg
bm90IGJlIGRlbGV0ZWQuIElmIGZvcmNlPXRydWUsIHRoZQogdmVyc2lvbiBhbmQgYW55IHRh
Z3MgcG9pbnRpbmcgdG8gdGhlIHZlcnNpb24gYXJlIGRlbGV0ZWQuCgoNCgUEBAIBBRIEuAEC
BgoNCgUEBAIBARIEuAEHDAoNCgUEBAIBAxIEuAEPEApMCgIEBRIGvAEAzgEBGj4gVGhlIHJl
cXVlc3QgdG8gZGVsZXRlIG11bHRpcGxlIHZlcnNpb25zIGFjcm9zcyBhIHJlcG9zaXRvcnku
CgoLCgMEBQESBLwBCCIKTAoEBAUCABIGvgECwAEFGjwgVGhlIG5hbWUgb2YgdGhlIHJlcG9z
aXRvcnkgaG9sZGluZyBhbGwgcmVxdWVzdGVkIHZlcnNpb25zLgoKDQoFBAUCAAUSBL4BAggK
DQoFBAUCAAESBL4BCQ8KDQoFBAUCAAMSBL4BEhMKDwoFBAUCAAgSBr4BFMABBAoRCgcEBQIA
CJ8IEga+ARXAAQMKzAEKBAQFAgESBsUBAsoBBBq7ASBSZXF1aXJlZC4gVGhlIG5hbWVzIG9m
IHRoZSB2ZXJzaW9ucyB0byBkZWxldGUuCiBUaGUgbWF4aW11bSBudW1iZXIgb2YgdmVyc2lv
bnMgZGVsZXRlZCBwZXIgYmF0Y2ggaXMgZGV0ZXJtaW5lZCBieSB0aGUKIHNlcnZpY2UgYW5k
IGlzIGRlcGVuZGVudCBvbiB0aGUgYXZhaWxhYmxlIHJlc291cmNlcyBpbiB0aGUgcmVnaW9u
LgoKDQoFBAUCAQQSBMUBAgoKDQoFBAUCAQUSBMUBCxEKDQoFBAUCAQESBMUBEhcKDQoFBAUC
AQMSBMUBGhsKDwoFBAUCAQgSBsUBHMoBAwoQCggEBQIBCJwIABIExgEEKgoRCgcEBQIBCJ8I
EgbHAQTJAQUKWwoEBAUCAhIEzQECGRpNIElmIHRydWUsIHRoZSByZXF1ZXN0IGlzIHBlcmZv
cm1lZCB3aXRob3V0IGRlbGV0aW5nIGRhdGEsIGZvbGxvd2luZyBBSVAtMTYzLgoKDQoFBAUC
AgUSBM0BAgYKDQoFBAUCAgESBM0BBxQKDQoFBAUCAgMSBM0BFxgKRwoCBAYSBtEBANQBARo5
IFRoZSBtZXRhZGF0YSBvZiBhbiBMUk8gZnJvbSBkZWxldGluZyBtdWx0aXBsZSB2ZXJzaW9u
cy4KCgsKAwQGARIE0QEIIwo8CgQEBgIAEgTTAQImGi4gVGhlIHZlcnNpb25zIHRoZSBvcGVy
YXRpb24gZmFpbGVkIHRvIGRlbGV0ZS4KCg0KBQQGAgAEEgTTAQIKCg0KBQQGAgAFEgTTAQsR
Cg0KBQQGAgABEgTTARIhCg0KBQQGAgADEgTTASQlCjAKAgQHEgbXAQDfAQEaIiBUaGUgcmVx
dWVzdCB0byB1cGRhdGUgYSB2ZXJzaW9uLgoKCwoDBAcBEgTXAQgcCk8KBAQHAgASBNkBAj8a
QSBSZXF1aXJlZC4gVGhlIFZlcnNpb24gdGhhdCByZXBsYWNlcyB0aGUgcmVzb3VyY2Ugb24g
dGhlIHNlcnZlci4KCg0KBQQHAgAGEgTZAQIJCg0KBQQHAgABEgTZAQoRCg0KBQQHAgADEgTZ
ARQVCg0KBQQHAgAIEgTZARY+ChAKCAQHAgAInAgAEgTZARc9CrcBCgQEBwIBEgTeAQIsGqgB
IFRoZSB1cGRhdGUgbWFzayBhcHBsaWVzIHRvIHRoZSByZXNvdXJjZS4gRm9yIHRoZSBgRmll
bGRNYXNrYCBkZWZpbml0aW9uLAogc2VlCiBodHRwczovL2RldmVsb3BlcnMuZ29vZ2xlLmNv
bS9wcm90b2NvbC1idWZmZXJzL2RvY3MvcmVmZXJlbmNlL2dvb2dsZS5wcm90b2J1ZiNmaWVs
ZG1hc2sKCg0KBQQHAgEGEgTeAQIbCg0KBQQHAgEBEgTeARwnCg0KBQQHAgEDEgTeASorYgZw
cm90bzM=
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Devtools::Artifactregistry::V1::Version::Version ===
    # Fields for Version
    # Field: name Type: 9 ()
    # Field: description Type: 9 ()
    # Field: create_time Type: 11 (.google.protobuf.Timestamp)
    # Field: update_time Type: 11 (.google.protobuf.Timestamp)
    # Field: related_tags Type: 11 (.google.devtools.artifactregistry.v1.Tag)
    # Field: metadata Type: 11 (.google.protobuf.Struct)
    # Field: annotations Type: 11 (.google.devtools.artifactregistry.v1.Version.AnnotationsEntry)
    # Field: fingerprints Type: 11 (.google.devtools.artifactregistry.v1.Hash)

# === Message: Google::Devtools::Artifactregistry::V1::Version::ListVersionsRequest ===
    # Fields for ListVersionsRequest
    # Field: parent Type: 9 ()
    # Field: page_size Type: 5 ()
    # Field: page_token Type: 9 ()
    # Field: view Type: 14 (.google.devtools.artifactregistry.v1.VersionView)
    # Field: order_by Type: 9 ()
    # Field: filter Type: 9 ()

# === Message: Google::Devtools::Artifactregistry::V1::Version::ListVersionsResponse ===
    # Fields for ListVersionsResponse
    # Field: versions Type: 11 (.google.devtools.artifactregistry.v1.Version)
    # Field: next_page_token Type: 9 ()

# === Message: Google::Devtools::Artifactregistry::V1::Version::GetVersionRequest ===
    # Fields for GetVersionRequest
    # Field: name Type: 9 ()
    # Field: view Type: 14 (.google.devtools.artifactregistry.v1.VersionView)

# === Message: Google::Devtools::Artifactregistry::V1::Version::DeleteVersionRequest ===
    # Fields for DeleteVersionRequest
    # Field: name Type: 9 ()
    # Field: force Type: 8 ()

# === Message: Google::Devtools::Artifactregistry::V1::Version::BatchDeleteVersionsRequest ===
    # Fields for BatchDeleteVersionsRequest
    # Field: parent Type: 9 ()
    # Field: names Type: 9 ()
    # Field: validate_only Type: 8 ()

# === Message: Google::Devtools::Artifactregistry::V1::Version::BatchDeleteVersionsMetadata ===
    # Fields for BatchDeleteVersionsMetadata
    # Field: failed_versions Type: 9 ()

# === Message: Google::Devtools::Artifactregistry::V1::Version::UpdateVersionRequest ===
    # Fields for UpdateVersionRequest
    # Field: version Type: 11 (.google.devtools.artifactregistry.v1.Version)
    # Field: update_mask Type: 11 (.google.protobuf.FieldMask)

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Devtools::Artifactregistry::V1::Version - Compiled Protocol Buffers messages for google/devtools/artifactregistry/v1/version.proto

=head1 SYNOPSIS

    use Google::Devtools::Artifactregistry::V1::Version;

    my $msg = Google::Devtools::Artifactregistry::V1::Version::Version->new({
        name => $name,
        description => $description,
        create_time => $create_time,
        update_time => $update_time,
    });

    # Read or update a field
    my $val = $msg->name();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Devtools::Artifactregistry::V1::Version::Version->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/devtools/artifactregistry/v1/version.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Devtools::Artifactregistry::V1::Version::Version

The body of a version resource. A version resource represents a
collection of components, such as files and other data. This may correspond
to a version in many package management schemes.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

The name of the version, for example:
`projects/p1/locations/us-central1/repositories/repo1/packages/pkg1/versions/art1`.
If the package or version ID parts contain slashes, the slashes are
escaped.

=item * C<< $msg->description() >> / C<< $msg->description($value) >>

Type: C<String>

Optional. Description of the version, as specified in its metadata.

=item * C<< $msg->create_time() >> / C<< $msg->create_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

The time when the version was created.

=item * C<< $msg->update_time() >> / C<< $msg->update_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

The time when the version was last updated.

=item * C<< $msg->related_tags() >> / C<< $msg->related_tags($value) >>

Type: C<Message> (L<Google::Devtools::Artifactregistry::V1::Tag::Tag>)

Output only. A list of related tags. Will contain up to 100 tags that
reference this version.

=item * C<< $msg->metadata() >> / C<< $msg->metadata($value) >>

Type: C<Message> (L<Google::Protobuf::Struct::Struct>)

Output only. Repository-specific Metadata stored against this version.
The fields returned are defined by the underlying repository-specific
resource. Currently, the resources could be:
[DockerImage][google.devtools.artifactregistry.v1.DockerImage]
[MavenArtifact][google.devtools.artifactregistry.v1.MavenArtifact]

=item * C<< $msg->annotations() >> / C<< $msg->annotations($value) >>

Type: C<Message> (L<Google::Devtools::Artifactregistry::V1::Version::Version::AnnotationsEntry>)

Optional. Client specified annotations.

=item * C<< $msg->fingerprints() >> / C<< $msg->fingerprints($value) >>

Type: C<Message> (L<Google::Devtools::Artifactregistry::V1::File::Hash>)

Output only. Immutable reference for the version, calculated based on the
version's content. Currently we only support dirsum_sha256 hash algorithm.
Additional hash algorithms may be added in the future.

=back

=head2 Google::Devtools::Artifactregistry::V1::Version::ListVersionsRequest

The request to list versions.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->parent() >> / C<< $msg->parent($value) >>

Type: C<String>

The name of the parent resource whose versions will be listed.

=item * C<< $msg->page_size() >> / C<< $msg->page_size($value) >>

Type: C<Int32>

The maximum number of versions to return. Maximum page size is 1,000.

=item * C<< $msg->page_token() >> / C<< $msg->page_token($value) >>

Type: C<String>

The next_page_token value returned from a previous list request, if any.

=item * C<< $msg->view() >> / C<< $msg->view($value) >>

Type: C<Enum> (L<Google::Devtools::Artifactregistry::V1::VersionView>)

The view that should be returned in the response.

=item * C<< $msg->order_by() >> / C<< $msg->order_by($value) >>

Type: C<String>

Optional. The field to order the results by.

=item * C<< $msg->filter() >> / C<< $msg->filter($value) >>

Type: C<String>

Optional. An expression for filtering the results of the request. Filter
rules are case insensitive. The fields eligible for filtering are:

  * `name`
  * `annotations`

 Examples of using a filter:

 To filter the results of your request to versions with the name
 `my-version` in project `my-project` in the `us-central` region, in
 repository `my-repo`, append the following filter expression to your
 request:

  * `name="projects/my-project/locations/us-central1/repositories/my-repo/packages/my-package/versions/my-version"`

 You can also use wildcards to match any number of characters before or
 after the value:

  * `name="projects/my-project/locations/us-central1/repositories/my-repo/packages/my-package/versions/*version"`
  * `name="projects/my-project/locations/us-central1/repositories/my-repo/packages/my-package/versions/my*"`
  * `name="projects/my-project/locations/us-central1/repositories/my-repo/packages/my-package/versions/*version*"`

 To filter the results of your request to versions with the annotation
 key-value pair [`external_link`: `external_link_value`], append the
 following filter expression to your request:

  * `"annotations.external_link:external_link_value"`

 To filter just for a specific annotation key `external_link`, append the
 following filter expression to your request:

  * `"annotations.external_link"`

 If the annotation key or value contains special characters, you can escape
 them by surrounding the value with backticks. For example, to filter the
 results of your request to versions with the annotation key-value pair
 [`external.link`:`https://example.com/my-version`], append the following
 filter expression to your request:

  * `` "annotations.`external.link`:`https://example.com/my-version`" ``

 You can also filter with annotations with a wildcard to
 match any number of characters before or after the value:

  * `` "annotations.*_link:`*example.com*`" ``

=back

=head2 Google::Devtools::Artifactregistry::V1::Version::ListVersionsResponse

The response from listing versions.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->versions() >> / C<< $msg->versions($value) >>

Type: C<Message> (L<Google::Devtools::Artifactregistry::V1::Version::Version>)

The versions returned.

=item * C<< $msg->next_page_token() >> / C<< $msg->next_page_token($value) >>

Type: C<String>

The token to retrieve the next page of versions, or empty if there are no
more versions to return.

=back

=head2 Google::Devtools::Artifactregistry::V1::Version::GetVersionRequest

The request to retrieve a version.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

The name of the version to retrieve.

=item * C<< $msg->view() >> / C<< $msg->view($value) >>

Type: C<Enum> (L<Google::Devtools::Artifactregistry::V1::VersionView>)

The view that should be returned in the response.

=back

=head2 Google::Devtools::Artifactregistry::V1::Version::DeleteVersionRequest

The request to delete a version.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

The name of the version to delete.

=item * C<< $msg->force() >> / C<< $msg->force($value) >>

Type: C<Bool>

By default, a version that is tagged may not be deleted. If force=true, the
version and any tags pointing to the version are deleted.

=back

=head2 Google::Devtools::Artifactregistry::V1::Version::BatchDeleteVersionsRequest

The request to delete multiple versions across a repository.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->parent() >> / C<< $msg->parent($value) >>

Type: C<String>

The name of the repository holding all requested versions.

=item * C<< $msg->names() >> / C<< $msg->names($value) >>

Type: C<String>

Required. The names of the versions to delete.
The maximum number of versions deleted per batch is determined by the
service and is dependent on the available resources in the region.

=item * C<< $msg->validate_only() >> / C<< $msg->validate_only($value) >>

Type: C<Bool>

If true, the request is performed without deleting data, following AIP-163.

=back

=head2 Google::Devtools::Artifactregistry::V1::Version::BatchDeleteVersionsMetadata

The metadata of an LRO from deleting multiple versions.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->failed_versions() >> / C<< $msg->failed_versions($value) >>

Type: C<String>

The versions the operation failed to delete.

=back

=head2 Google::Devtools::Artifactregistry::V1::Version::UpdateVersionRequest

The request to update a version.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->version() >> / C<< $msg->version($value) >>

Type: C<Message> (L<Google::Devtools::Artifactregistry::V1::Version::Version>)

Required. The Version that replaces the resource on the server.

=item * C<< $msg->update_mask() >> / C<< $msg->update_mask($value) >>

Type: C<Message> (L<Google::Protobuf::FieldMask::FieldMask>)

The update mask applies to the resource. For the `FieldMask` definition,
see
https://developers.google.com/protocol-buffers/docs/reference/google.protobuf#fieldmask

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Devtools::Artifactregistry::V1::Version::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
