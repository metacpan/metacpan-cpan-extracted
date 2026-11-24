package Google::Cloud::Tasks::V2::Queue;

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
    eval { require Google::Cloud::Tasks::V2::Target };
    eval { require Google::Protobuf::Duration };
    eval { require Google::Protobuf::Timestamp };
    my $descriptor_b64 = <<'EOF';
CiFnb29nbGUvY2xvdWQvdGFza3MvdjIvcXVldWUucHJvdG8SFWdvb2dsZS5jbG91ZC50YXNr
cy52MhofZ29vZ2xlL2FwaS9maWVsZF9iZWhhdmlvci5wcm90bxoZZ29vZ2xlL2FwaS9yZXNv
dXJjZS5wcm90bxoiZ29vZ2xlL2Nsb3VkL3Rhc2tzL3YyL3RhcmdldC5wcm90bxoeZ29vZ2xl
L3Byb3RvYnVmL2R1cmF0aW9uLnByb3RvGh9nb29nbGUvcHJvdG9idWYvdGltZXN0YW1wLnBy
b3RvItsFCgVRdWV1ZRISCgRuYW1lGAEgASgJUgRuYW1lEmYKG2FwcF9lbmdpbmVfcm91dGlu
Z19vdmVycmlkZRgCIAEoCzInLmdvb2dsZS5jbG91ZC50YXNrcy52Mi5BcHBFbmdpbmVSb3V0
aW5nUhhhcHBFbmdpbmVSb3V0aW5nT3ZlcnJpZGUSQgoLaHR0cF90YXJnZXQYCiABKAsyIS5n
b29nbGUuY2xvdWQudGFza3MudjIuSHR0cFRhcmdldFIKaHR0cFRhcmdldBJCCgtyYXRlX2xp
bWl0cxgDIAEoCzIhLmdvb2dsZS5jbG91ZC50YXNrcy52Mi5SYXRlTGltaXRzUgpyYXRlTGlt
aXRzEkUKDHJldHJ5X2NvbmZpZxgEIAEoCzIiLmdvb2dsZS5jbG91ZC50YXNrcy52Mi5SZXRy
eUNvbmZpZ1ILcmV0cnlDb25maWcSOAoFc3RhdGUYBSABKA4yIi5nb29nbGUuY2xvdWQudGFz
a3MudjIuUXVldWUuU3RhdGVSBXN0YXRlEjkKCnB1cmdlX3RpbWUYBiABKAsyGi5nb29nbGUu
cHJvdG9idWYuVGltZXN0YW1wUglwdXJnZVRpbWUSbQoac3RhY2tkcml2ZXJfbG9nZ2luZ19j
b25maWcYCSABKAsyLy5nb29nbGUuY2xvdWQudGFza3MudjIuU3RhY2tkcml2ZXJMb2dnaW5n
Q29uZmlnUhhzdGFja2RyaXZlckxvZ2dpbmdDb25maWciRQoFU3RhdGUSFQoRU1RBVEVfVU5T
UEVDSUZJRUQQABILCgdSVU5OSU5HEAESCgoGUEFVU0VEEAISDAoIRElTQUJMRUQQAzpc6kFZ
Ch9jbG91ZHRhc2tzLmdvb2dsZWFwaXMuY29tL1F1ZXVlEjZwcm9qZWN0cy97cHJvamVjdH0v
bG9jYXRpb25zL3tsb2NhdGlvbn0vcXVldWVzL3txdWV1ZX0iqQEKClJhdGVMaW1pdHMSOQoZ
bWF4X2Rpc3BhdGNoZXNfcGVyX3NlY29uZBgBIAEoAVIWbWF4RGlzcGF0Y2hlc1BlclNlY29u
ZBIkCg5tYXhfYnVyc3Rfc2l6ZRgCIAEoBVIMbWF4QnVyc3RTaXplEjoKGW1heF9jb25jdXJy
ZW50X2Rpc3BhdGNoZXMYAyABKAVSF21heENvbmN1cnJlbnREaXNwYXRjaGVzIpYCCgtSZXRy
eUNvbmZpZxIhCgxtYXhfYXR0ZW1wdHMYASABKAVSC21heEF0dGVtcHRzEkcKEm1heF9yZXRy
eV9kdXJhdGlvbhgCIAEoCzIZLmdvb2dsZS5wcm90b2J1Zi5EdXJhdGlvblIQbWF4UmV0cnlE
dXJhdGlvbhI6CgttaW5fYmFja29mZhgDIAEoCzIZLmdvb2dsZS5wcm90b2J1Zi5EdXJhdGlv
blIKbWluQmFja29mZhI6CgttYXhfYmFja29mZhgEIAEoCzIZLmdvb2dsZS5wcm90b2J1Zi5E
dXJhdGlvblIKbWF4QmFja29mZhIjCg1tYXhfZG91YmxpbmdzGAUgASgFUgxtYXhEb3VibGlu
Z3MiQQoYU3RhY2tkcml2ZXJMb2dnaW5nQ29uZmlnEiUKDnNhbXBsaW5nX3JhdGlvGAEgASgB
Ug1zYW1wbGluZ1JhdGlvQmkKGWNvbS5nb29nbGUuY2xvdWQudGFza3MudjJCClF1ZXVlUHJv
dG9QAVo+Y2xvdWQuZ29vZ2xlLmNvbS9nby9jbG91ZHRhc2tzL2FwaXYyL2Nsb3VkdGFza3Nw
YjtjbG91ZHRhc2tzcGJKtX8KBxIFDgCLAwEKvAQKAQwSAw4AEjKxBCBDb3B5cmlnaHQgMjAy
NiBHb29nbGUgTExDCgogTGljZW5zZWQgdW5kZXIgdGhlIEFwYWNoZSBMaWNlbnNlLCBWZXJz
aW9uIDIuMCAodGhlICJMaWNlbnNlIik7CiB5b3UgbWF5IG5vdCB1c2UgdGhpcyBmaWxlIGV4
Y2VwdCBpbiBjb21wbGlhbmNlIHdpdGggdGhlIExpY2Vuc2UuCiBZb3UgbWF5IG9idGFpbiBh
IGNvcHkgb2YgdGhlIExpY2Vuc2UgYXQKCiAgICAgaHR0cDovL3d3dy5hcGFjaGUub3JnL2xp
Y2Vuc2VzL0xJQ0VOU0UtMi4wCgogVW5sZXNzIHJlcXVpcmVkIGJ5IGFwcGxpY2FibGUgbGF3
IG9yIGFncmVlZCB0byBpbiB3cml0aW5nLCBzb2Z0d2FyZQogZGlzdHJpYnV0ZWQgdW5kZXIg
dGhlIExpY2Vuc2UgaXMgZGlzdHJpYnV0ZWQgb24gYW4gIkFTIElTIiBCQVNJUywKIFdJVEhP
VVQgV0FSUkFOVElFUyBPUiBDT05ESVRJT05TIE9GIEFOWSBLSU5ELCBlaXRoZXIgZXhwcmVz
cyBvciBpbXBsaWVkLgogU2VlIHRoZSBMaWNlbnNlIGZvciB0aGUgc3BlY2lmaWMgbGFuZ3Vh
Z2UgZ292ZXJuaW5nIHBlcm1pc3Npb25zIGFuZAogbGltaXRhdGlvbnMgdW5kZXIgdGhlIExp
Y2Vuc2UuCgoICgECEgMQAB4KCQoCAwASAxIAKQoJCgIDARIDEwAjCgkKAgMCEgMUACwKCQoC
AwMSAxUAKAoJCgIDBBIDFgApCggKAQgSAxgAVQoJCgIICxIDGABVCggKAQgSAxkAIgoJCgII
ChIDGQAiCggKAQgSAxoAKwoJCgIICBIDGgArCggKAQgSAxsAMgoJCgIIARIDGwAyCs8BCgIE
ABIFIAC3AQEawQEgQSBxdWV1ZSBpcyBhIGNvbnRhaW5lciBvZiByZWxhdGVkIHRhc2tzLiBR
dWV1ZXMgYXJlIGNvbmZpZ3VyZWQgdG8gbWFuYWdlCiBob3cgdGhvc2UgdGFza3MgYXJlIGRp
c3BhdGNoZWQuIENvbmZpZ3VyYWJsZSBwcm9wZXJ0aWVzIGluY2x1ZGUgcmF0ZSBsaW1pdHMs
CiByZXRyeSBvcHRpb25zLCBxdWV1ZSB0eXBlcywgYW5kIG90aGVycy4KCgoKAwQAARIDIAgN
CgsKAwQABxIEIQIkBAoNCgUEAAedCBIEIQIkBAojCgQEAAQAEgQnAkkDGhUgU3RhdGUgb2Yg
dGhlIHF1ZXVlLgoKDAoFBAAEAAESAycHDAojCgYEAAQAAgASAykEGhoUIFVuc3BlY2lmaWVk
IHN0YXRlLgoKDgoHBAAEAAIAARIDKQQVCg4KBwQABAACAAISAykYGQqRAwoGBAAEAAIBEgMz
BBAagQMgVGhlIHF1ZXVlIGlzIHJ1bm5pbmcuIFRhc2tzIGNhbiBiZSBkaXNwYXRjaGVkLgoK
IElmIHRoZSBxdWV1ZSB3YXMgY3JlYXRlZCB1c2luZyBDbG91ZCBUYXNrcyBhbmQgdGhlIHF1
ZXVlIGhhcwogaGFkIG5vIGFjdGl2aXR5IChtZXRob2QgY2FsbHMgb3IgdGFzayBkaXNwYXRj
aGVzKSBmb3IgMzAgZGF5cywKIHRoZSBxdWV1ZSBtYXkgdGFrZSBhIGZldyBtaW51dGVzIHRv
IHJlLWFjdGl2YXRlLiBTb21lIG1ldGhvZAogY2FsbHMgbWF5IHJldHVybiBbTk9UX0ZPVU5E
XVtnb29nbGUucnBjLkNvZGUuTk9UX0ZPVU5EXSBhbmQKIHRhc2tzIG1heSBub3QgYmUgZGlz
cGF0Y2hlZCBmb3IgYSBmZXcgbWludXRlcyB1bnRpbCB0aGUgcXVldWUKIGhhcyBiZWVuIHJl
LWFjdGl2YXRlZC4KCg4KBwQABAACAQESAzMECwoOCgcEAAQAAgECEgMzDg8KsgEKBgQABAAC
AhIDOAQPGqIBIFRhc2tzIGFyZSBwYXVzZWQgYnkgdGhlIHVzZXIuIElmIHRoZSBxdWV1ZSBp
cyBwYXVzZWQgdGhlbiBDbG91ZAogVGFza3Mgd2lsbCBzdG9wIGRlbGl2ZXJpbmcgdGFza3Mg
ZnJvbSBpdCwgYnV0IG1vcmUgdGFza3MgY2FuCiBzdGlsbCBiZSBhZGRlZCB0byBpdCBieSB0
aGUgdXNlci4KCg4KBwQABAACAgESAzgECgoOCgcEAAQAAgICEgM4DQ4KpAQKBgQABAACAxID
SAQRGpQEIFRoZSBxdWV1ZSBpcyBkaXNhYmxlZC4KCiBBIHF1ZXVlIGJlY29tZXMgYERJU0FC
TEVEYCB3aGVuCiBbcXVldWUueWFtbF0oaHR0cHM6Ly9jbG91ZC5nb29nbGUuY29tL2FwcGVu
Z2luZS9kb2NzL3B5dGhvbi9jb25maWcvcXVldWVyZWYpCiBvcgogW3F1ZXVlLnhtbF0oaHR0
cHM6Ly9jbG91ZC5nb29nbGUuY29tL2FwcGVuZ2luZS9kb2NzL3N0YW5kYXJkL2phdmEvY29u
ZmlnL3F1ZXVlcmVmKQogaXMgdXBsb2FkZWQgd2hpY2ggZG9lcyBub3QgY29udGFpbiB0aGUg
cXVldWUuIFlvdSBjYW5ub3QgZGlyZWN0bHkgZGlzYWJsZQogYSBxdWV1ZS4KCiBXaGVuIGEg
cXVldWUgaXMgZGlzYWJsZWQsIHRhc2tzIGNhbiBzdGlsbCBiZSBhZGRlZCB0byBhIHF1ZXVl
CiBidXQgdGhlIHRhc2tzIGFyZSBub3QgZGlzcGF0Y2hlZC4KCiBUbyBwZXJtYW5lbnRseSBk
ZWxldGUgdGhpcyBxdWV1ZSBhbmQgYWxsIG9mIGl0cyB0YXNrcywgY2FsbAogW0RlbGV0ZVF1
ZXVlXVtnb29nbGUuY2xvdWQudGFza3MudjIuQ2xvdWRUYXNrcy5EZWxldGVRdWV1ZV0uCgoO
CgcEAAQAAgMBEgNIBAwKDgoHBAAEAAIDAhIDSA8QCqIHCgQEAAIAEgNfAhIalAcgQ2FsbGVy
LXNwZWNpZmllZCBhbmQgcmVxdWlyZWQgaW4KIFtDcmVhdGVRdWV1ZV1bZ29vZ2xlLmNsb3Vk
LnRhc2tzLnYyLkNsb3VkVGFza3MuQ3JlYXRlUXVldWVdLCBhZnRlciB3aGljaCBpdAogYmVj
b21lcyBvdXRwdXQgb25seS4KCiBUaGUgcXVldWUgbmFtZS4KCiBUaGUgcXVldWUgbmFtZSBt
dXN0IGhhdmUgdGhlIGZvbGxvd2luZyBmb3JtYXQ6CiBgcHJvamVjdHMvUFJPSkVDVF9JRC9s
b2NhdGlvbnMvTE9DQVRJT05fSUQvcXVldWVzL1FVRVVFX0lEYAoKICogYFBST0pFQ1RfSURg
IGNhbiBjb250YWluIGxldHRlcnMgKFtBLVphLXpdKSwgbnVtYmVycyAoWzAtOV0pLAogICAg
aHlwaGVucyAoLSksIGNvbG9ucyAoOiksIG9yIHBlcmlvZHMgKC4pLgogICAgRm9yIG1vcmUg
aW5mb3JtYXRpb24sIHNlZQogICAgW0lkZW50aWZ5aW5nCiAgICBwcm9qZWN0c10oaHR0cHM6
Ly9jbG91ZC5nb29nbGUuY29tL3Jlc291cmNlLW1hbmFnZXIvZG9jcy9jcmVhdGluZy1tYW5h
Z2luZy1wcm9qZWN0cyNpZGVudGlmeWluZ19wcm9qZWN0cykKICogYExPQ0FUSU9OX0lEYCBp
cyB0aGUgY2Fub25pY2FsIElEIGZvciB0aGUgcXVldWUncyBsb2NhdGlvbi4KICAgIFRoZSBs
aXN0IG9mIGF2YWlsYWJsZSBsb2NhdGlvbnMgY2FuIGJlIG9idGFpbmVkIGJ5IGNhbGxpbmcK
ICAgIFtMaXN0TG9jYXRpb25zXVtnb29nbGUuY2xvdWQubG9jYXRpb24uTG9jYXRpb25zLkxp
c3RMb2NhdGlvbnNdLgogICAgRm9yIG1vcmUgaW5mb3JtYXRpb24sIHNlZSBodHRwczovL2Ns
b3VkLmdvb2dsZS5jb20vYWJvdXQvbG9jYXRpb25zLy4KICogYFFVRVVFX0lEYCBjYW4gY29u
dGFpbiBsZXR0ZXJzIChbQS1aYS16XSksIG51bWJlcnMgKFswLTldKSwgb3IKICAgaHlwaGVu
cyAoLSkuIFRoZSBtYXhpbXVtIGxlbmd0aCBpcyAxMDAgY2hhcmFjdGVycy4KCgwKBQQAAgAF
EgNfAggKDAoFBAACAAESA18JDQoMCgUEAAIAAxIDXxARCr0ECgQEAAIBEgNsAjMarwQgT3Zl
cnJpZGVzIGZvcgogW3Rhc2stbGV2ZWwKIGFwcF9lbmdpbmVfcm91dGluZ11bZ29vZ2xlLmNs
b3VkLnRhc2tzLnYyLkFwcEVuZ2luZUh0dHBSZXF1ZXN0LmFwcF9lbmdpbmVfcm91dGluZ10u
CiBUaGVzZSBzZXR0aW5ncyBhcHBseSBvbmx5IHRvCiBbQXBwIEVuZ2luZSB0YXNrc11bZ29v
Z2xlLmNsb3VkLnRhc2tzLnYyLkFwcEVuZ2luZUh0dHBSZXF1ZXN0XSBpbiB0aGlzCiBxdWV1
ZS4gW0h0dHAgdGFza3NdW2dvb2dsZS5jbG91ZC50YXNrcy52Mi5IdHRwUmVxdWVzdF0gYXJl
IG5vdCBhZmZlY3RlZC4KCiBJZiBzZXQsIGBhcHBfZW5naW5lX3JvdXRpbmdfb3ZlcnJpZGVg
IGlzIHVzZWQgZm9yIGFsbAogW0FwcCBFbmdpbmUgdGFza3NdW2dvb2dsZS5jbG91ZC50YXNr
cy52Mi5BcHBFbmdpbmVIdHRwUmVxdWVzdF0gaW4gdGhlCiBxdWV1ZSwgbm8gbWF0dGVyIHdo
YXQgdGhlIHNldHRpbmcgaXMgZm9yIHRoZSBbdGFzay1sZXZlbAogYXBwX2VuZ2luZV9yb3V0
aW5nXVtnb29nbGUuY2xvdWQudGFza3MudjIuQXBwRW5naW5lSHR0cFJlcXVlc3QuYXBwX2Vu
Z2luZV9yb3V0aW5nXS4KCgwKBQQAAgEGEgNsAhIKDAoFBAACAQESA2wTLgoMCgUEAAIBAxID
bDEyCjMKBAQAAgISA28CHhomIE1vZGlmaWVzIEhUVFAgdGFyZ2V0IGZvciBIVFRQIHRhc2tz
LgoKDAoFBAACAgYSA28CDAoMCgUEAAICARIDbw0YCgwKBQQAAgIDEgNvGx0K7wkKBAQAAgMS
BI0BAh0a4AkgUmF0ZSBsaW1pdHMgZm9yIHRhc2sgZGlzcGF0Y2hlcy4KCiBbcmF0ZV9saW1p
dHNdW2dvb2dsZS5jbG91ZC50YXNrcy52Mi5RdWV1ZS5yYXRlX2xpbWl0c10gYW5kCiBbcmV0
cnlfY29uZmlnXVtnb29nbGUuY2xvdWQudGFza3MudjIuUXVldWUucmV0cnlfY29uZmlnXSBh
cmUgcmVsYXRlZAogYmVjYXVzZSB0aGV5IGJvdGggY29udHJvbCB0YXNrIGF0dGVtcHRzLiBI
b3dldmVyIHRoZXkgY29udHJvbCB0YXNrIGF0dGVtcHRzCiBpbiBkaWZmZXJlbnQgd2F5czoK
CiAqIFtyYXRlX2xpbWl0c11bZ29vZ2xlLmNsb3VkLnRhc2tzLnYyLlF1ZXVlLnJhdGVfbGlt
aXRzXSBjb250cm9scyB0aGUgdG90YWwKIHJhdGUgb2YKICAgZGlzcGF0Y2hlcyBmcm9tIGEg
cXVldWUgKGkuZS4gYWxsIHRyYWZmaWMgZGlzcGF0Y2hlZCBmcm9tIHRoZQogICBxdWV1ZSwg
cmVnYXJkbGVzcyBvZiB3aGV0aGVyIHRoZSBkaXNwYXRjaCBpcyBmcm9tIGEgZmlyc3QKICAg
YXR0ZW1wdCBvciBhIHJldHJ5KS4KICogW3JldHJ5X2NvbmZpZ11bZ29vZ2xlLmNsb3VkLnRh
c2tzLnYyLlF1ZXVlLnJldHJ5X2NvbmZpZ10gY29udHJvbHMgd2hhdAogaGFwcGVucyB0byBh
CiAgIHBhcnRpY3VsYXIgdGFzayBhZnRlciBpdHMgZmlyc3QgYXR0ZW1wdCBmYWlscy4gVGhh
dCBpcywKICAgW3JldHJ5X2NvbmZpZ11bZ29vZ2xlLmNsb3VkLnRhc2tzLnYyLlF1ZXVlLnJl
dHJ5X2NvbmZpZ10gY29udHJvbHMgdGFzawogICByZXRyaWVzICh0aGUgc2Vjb25kIGF0dGVt
cHQsIHRoaXJkIGF0dGVtcHQsIGV0YykuCgogVGhlIHF1ZXVlJ3MgYWN0dWFsIGRpc3BhdGNo
IHJhdGUgaXMgdGhlIHJlc3VsdCBvZjoKCiAqIE51bWJlciBvZiB0YXNrcyBpbiB0aGUgcXVl
dWUKICogVXNlci1zcGVjaWZpZWQgdGhyb3R0bGluZzoKIFtyYXRlX2xpbWl0c11bZ29vZ2xl
LmNsb3VkLnRhc2tzLnYyLlF1ZXVlLnJhdGVfbGltaXRzXSwKICAgW3JldHJ5X2NvbmZpZ11b
Z29vZ2xlLmNsb3VkLnRhc2tzLnYyLlF1ZXVlLnJldHJ5X2NvbmZpZ10sIGFuZCB0aGUKICAg
W3F1ZXVlJ3Mgc3RhdGVdW2dvb2dsZS5jbG91ZC50YXNrcy52Mi5RdWV1ZS5zdGF0ZV0uCiAq
IFN5c3RlbSB0aHJvdHRsaW5nIGR1ZSB0byBgNDI5YCAoVG9vIE1hbnkgUmVxdWVzdHMpIG9y
IGA1MDNgIChTZXJ2aWNlCiAgIFVuYXZhaWxhYmxlKSByZXNwb25zZXMgZnJvbSB0aGUgd29y
a2VyLCBoaWdoIGVycm9yIHJhdGVzLCBvciB0byBzbW9vdGgKICAgc3VkZGVuIGxhcmdlIHRy
YWZmaWMgc3Bpa2VzLgoKDQoFBAACAwYSBI0BAgwKDQoFBAACAwESBI0BDRgKDQoFBAACAwMS
BI0BGxwK1gQKBAQAAgQSBJkBAh8axwQgU2V0dGluZ3MgdGhhdCBkZXRlcm1pbmUgdGhlIHJl
dHJ5IGJlaGF2aW9yLgoKICogRm9yIHRhc2tzIGNyZWF0ZWQgdXNpbmcgQ2xvdWQgVGFza3M6
IHRoZSBxdWV1ZS1sZXZlbCByZXRyeSBzZXR0aW5ncwogICBhcHBseSB0byBhbGwgdGFza3Mg
aW4gdGhlIHF1ZXVlIHRoYXQgd2VyZSBjcmVhdGVkIHVzaW5nIENsb3VkIFRhc2tzLgogICBS
ZXRyeSBzZXR0aW5ncyBjYW5ub3QgYmUgc2V0IG9uIGluZGl2aWR1YWwgdGFza3MuCiAqIEZv
ciB0YXNrcyBjcmVhdGVkIHVzaW5nIHRoZSBBcHAgRW5naW5lIFNESzogdGhlIHF1ZXVlLWxl
dmVsIHJldHJ5CiAgIHNldHRpbmdzIGFwcGx5IHRvIGFsbCB0YXNrcyBpbiB0aGUgcXVldWUg
d2hpY2ggZG8gbm90IGhhdmUgcmV0cnkgc2V0dGluZ3MKICAgZXhwbGljaXRseSBzZXQgb24g
dGhlIHRhc2sgYW5kIHdlcmUgY3JlYXRlZCBieSB0aGUgQXBwIEVuZ2luZSBTREsuIFNlZQog
ICBbQXBwIEVuZ2luZQogICBkb2N1bWVudGF0aW9uXShodHRwczovL2Nsb3VkLmdvb2dsZS5j
b20vYXBwZW5naW5lL2RvY3Mvc3RhbmRhcmQvcHl0aG9uL3Rhc2txdWV1ZS9wdXNoL3JldHJ5
aW5nLXRhc2tzKS4KCg0KBQQAAgQGEgSZAQINCg0KBQQAAgQBEgSZAQ4aCg0KBQQAAgQDEgSZ
AR0eCpgDCgQEAAIFEgSjAQISGokDIE91dHB1dCBvbmx5LiBUaGUgc3RhdGUgb2YgdGhlIHF1
ZXVlLgoKIGBzdGF0ZWAgY2FuIG9ubHkgYmUgY2hhbmdlZCBieSBjYWxsaW5nCiBbUGF1c2VR
dWV1ZV1bZ29vZ2xlLmNsb3VkLnRhc2tzLnYyLkNsb3VkVGFza3MuUGF1c2VRdWV1ZV0sCiBb
UmVzdW1lUXVldWVdW2dvb2dsZS5jbG91ZC50YXNrcy52Mi5DbG91ZFRhc2tzLlJlc3VtZVF1
ZXVlXSwgb3IgdXBsb2FkaW5nCiBbcXVldWUueWFtbC94bWxdKGh0dHBzOi8vY2xvdWQuZ29v
Z2xlLmNvbS9hcHBlbmdpbmUvZG9jcy9weXRob24vY29uZmlnL3F1ZXVlcmVmKS4KIFtVcGRh
dGVRdWV1ZV1bZ29vZ2xlLmNsb3VkLnRhc2tzLnYyLkNsb3VkVGFza3MuVXBkYXRlUXVldWVd
IGNhbm5vdCBiZSB1c2VkCiB0byBjaGFuZ2UgYHN0YXRlYC4KCg0KBQQAAgUGEgSjAQIHCg0K
BQQAAgUBEgSjAQgNCg0KBQQAAgUDEgSjARARCrYECgQEAAIGEgSxAQIrGqcEIE91dHB1dCBv
bmx5LiBUaGUgbGFzdCB0aW1lIHRoaXMgcXVldWUgd2FzIHB1cmdlZC4KCiBBbGwgdGFza3Mg
dGhhdCB3ZXJlIFtjcmVhdGVkXVtnb29nbGUuY2xvdWQudGFza3MudjIuVGFzay5jcmVhdGVf
dGltZV0KIGJlZm9yZSB0aGlzIHRpbWUgd2VyZSBwdXJnZWQuCgogQSBxdWV1ZSBjYW4gYmUg
cHVyZ2VkIHVzaW5nCiBbUHVyZ2VRdWV1ZV1bZ29vZ2xlLmNsb3VkLnRhc2tzLnYyLkNsb3Vk
VGFza3MuUHVyZ2VRdWV1ZV0sIHRoZSBbQXBwIEVuZ2luZQogVGFzayBRdWV1ZSBTREssIG9y
IHRoZSBDbG91ZAogQ29uc29sZV0oaHR0cHM6Ly9jbG91ZC5nb29nbGUuY29tL2FwcGVuZ2lu
ZS9kb2NzL3N0YW5kYXJkL3B5dGhvbi90YXNrcXVldWUvcHVzaC9kZWxldGluZy10YXNrcy1h
bmQtcXVldWVzI3B1cmdpbmdfYWxsX3Rhc2tzX2Zyb21fYV9xdWV1ZSkuCgogUHVyZ2UgdGlt
ZSB3aWxsIGJlIHRydW5jYXRlZCB0byB0aGUgbmVhcmVzdCBtaWNyb3NlY29uZC4gUHVyZ2UK
IHRpbWUgd2lsbCBiZSB1bnNldCBpZiB0aGUgcXVldWUgaGFzIG5ldmVyIGJlZW4gcHVyZ2Vk
LgoKDQoFBAACBgYSBLEBAhsKDQoFBAACBgESBLEBHCYKDQoFBAACBgMSBLEBKSoKrQEKBAQA
AgcSBLYBAjoangEgQ29uZmlndXJhdGlvbiBvcHRpb25zIGZvciB3cml0aW5nIGxvZ3MgdG8K
IFtTdGFja2RyaXZlciBMb2dnaW5nXShodHRwczovL2Nsb3VkLmdvb2dsZS5jb20vbG9nZ2lu
Zy9kb2NzLykuIElmIHRoaXMKIGZpZWxkIGlzIHVuc2V0LCB0aGVuIG5vIGxvZ3MgYXJlIHdy
aXR0ZW4uCgoNCgUEAAIHBhIEtgECGgoNCgUEAAIHARIEtgEbNQoNCgUEAAIHAxIEtgE4OQrx
AgoCBAESBsEBAIECARriAiBSYXRlIGxpbWl0cy4KCiBUaGlzIG1lc3NhZ2UgZGV0ZXJtaW5l
cyB0aGUgbWF4aW11bSByYXRlIHRoYXQgdGFza3MgY2FuIGJlIGRpc3BhdGNoZWQgYnkgYQog
cXVldWUsIHJlZ2FyZGxlc3Mgb2Ygd2hldGhlciB0aGUgZGlzcGF0Y2ggaXMgYSBmaXJzdCB0
YXNrIGF0dGVtcHQgb3IgYSByZXRyeS4KCiBOb3RlOiBUaGUgZGVidWdnaW5nIGNvbW1hbmQs
CiBbUnVuVGFza11bZ29vZ2xlLmNsb3VkLnRhc2tzLnYyLkNsb3VkVGFza3MuUnVuVGFza10s
IHdpbGwgcnVuIGEgdGFzayBldmVuIGlmCiB0aGUgcXVldWUgaGFzIHJlYWNoZWQgaXRzIFtS
YXRlTGltaXRzXVtnb29nbGUuY2xvdWQudGFza3MudjIuUmF0ZUxpbWl0c10uCgoLCgMEAQES
BMEBCBIK1AIKBAQBAgASBM0BAicaxQIgVGhlIG1heGltdW0gcmF0ZSBhdCB3aGljaCB0YXNr
cyBhcmUgZGlzcGF0Y2hlZCBmcm9tIHRoaXMgcXVldWUuCgogSWYgdW5zcGVjaWZpZWQgd2hl
biB0aGUgcXVldWUgaXMgY3JlYXRlZCwgQ2xvdWQgVGFza3Mgd2lsbCBwaWNrIHRoZQogZGVm
YXVsdC4KCiBUaGUgbWF4aW11bSBhbGxvd2VkIHZhbHVlIGlzIDUwMC4KCgogVGhpcyBmaWVs
ZCBoYXMgdGhlIHNhbWUgbWVhbmluZyBhcwogW3JhdGUgaW4KIHF1ZXVlLnlhbWwveG1sXSho
dHRwczovL2Nsb3VkLmdvb2dsZS5jb20vYXBwZW5naW5lL2RvY3Mvc3RhbmRhcmQvcHl0aG9u
L2NvbmZpZy9xdWV1ZXJlZiNyYXRlKS4KCg0KBQQBAgAFEgTNAQIICg0KBQQBAgABEgTNAQki
Cg0KBQQBAgADEgTNASUmCt8MCgQEAQIBEgTvAQIbGtAMIE91dHB1dCBvbmx5LiBUaGUgbWF4
IGJ1cnN0IHNpemUuCgogTWF4IGJ1cnN0IHNpemUgbGltaXRzIGhvdyBmYXN0IHRhc2tzIGlu
IHF1ZXVlIGFyZSBwcm9jZXNzZWQgd2hlbgogbWFueSB0YXNrcyBhcmUgaW4gdGhlIHF1ZXVl
IGFuZCB0aGUgcmF0ZSBpcyBoaWdoLiBUaGlzIGZpZWxkCiBhbGxvd3MgdGhlIHF1ZXVlIHRv
IGhhdmUgYSBoaWdoIHJhdGUgc28gcHJvY2Vzc2luZyBzdGFydHMgc2hvcnRseQogYWZ0ZXIg
YSB0YXNrIGlzIGVucXVldWVkLCBidXQgc3RpbGwgbGltaXRzIHJlc291cmNlIHVzYWdlIHdo
ZW4KIG1hbnkgdGFza3MgYXJlIGVucXVldWVkIGluIGEgc2hvcnQgcGVyaW9kIG9mIHRpbWUu
CgogVGhlIFt0b2tlbiBidWNrZXRdKGh0dHBzOi8vd2lraXBlZGlhLm9yZy93aWtpL1Rva2Vu
X0J1Y2tldCkKIGFsZ29yaXRobSBpcyB1c2VkIHRvIGNvbnRyb2wgdGhlIHJhdGUgb2YgdGFz
ayBkaXNwYXRjaGVzLiBFYWNoCiBxdWV1ZSBoYXMgYSB0b2tlbiBidWNrZXQgdGhhdCBob2xk
cyB0b2tlbnMsIHVwIHRvIHRoZSBtYXhpbXVtCiBzcGVjaWZpZWQgYnkgYG1heF9idXJzdF9z
aXplYC4gRWFjaCB0aW1lIGEgdGFzayBpcyBkaXNwYXRjaGVkLCBhCiB0b2tlbiBpcyByZW1v
dmVkIGZyb20gdGhlIGJ1Y2tldC4gVGFza3Mgd2lsbCBiZSBkaXNwYXRjaGVkIHVudGlsCiB0
aGUgcXVldWUncyBidWNrZXQgcnVucyBvdXQgb2YgdG9rZW5zLiBUaGUgYnVja2V0IHdpbGwg
YmUKIGNvbnRpbnVvdXNseSByZWZpbGxlZCB3aXRoIG5ldyB0b2tlbnMgYmFzZWQgb24KIGBt
YXhfZGlzcGF0Y2hlc19wZXJfc2Vjb25kYC4KCiBDbG91ZCBUYXNrcyBhdXRvbWF0aWNhbGx5
IHNldHMgYW4gYXBwcm9wcmlhdGUgYG1heF9idXJzdF9zaXplYCBiYXNlZAogb24gdGhlIHZh
bHVlIG9mIGBtYXhfZGlzcGF0Y2hlc19wZXJfc2Vjb25kYC4gVGhlIHZhbHVlIGlzIGR5bmFt
aWNhbGx5CiBvcHRpbWl6ZWQgdG8gZW5zdXJlIHF1ZXVlIHN0YWJpbGl0eSBhbmQgdGhyb3Vn
aHB1dC4gSXQgaXMgZ2VuZXJhbGx5IGF0CiBsZWFzdCBlcXVhbCB0byBgbWF4X2Rpc3BhdGNo
ZXNfcGVyX3NlY29uZGAgYnV0IG1pZ2h0IGJlIGhpZ2hlciB0bwogYWNjb21tb2RhdGUgYnVy
c3RzIG9mIHRyYWZmaWMuCgogRm9yIHF1ZXVlcyB0aGF0IHdlcmUgY3JlYXRlZCBvciB1cGRh
dGVkIHVzaW5nCiBgcXVldWUueWFtbC94bWxgLCBgbWF4X2J1cnN0X3NpemVgIGlzIGVxdWFs
IHRvCiBbYnVja2V0X3NpemVdKGh0dHBzOi8vY2xvdWQuZ29vZ2xlLmNvbS9hcHBlbmdpbmUv
ZG9jcy9zdGFuZGFyZC9weXRob24vY29uZmlnL3F1ZXVlcmVmI2J1Y2tldF9zaXplKS4KIFNp
bmNlIGBtYXhfYnVyc3Rfc2l6ZWAgaXMgb3V0cHV0IG9ubHksIGlmCiBbVXBkYXRlUXVldWVd
W2dvb2dsZS5jbG91ZC50YXNrcy52Mi5DbG91ZFRhc2tzLlVwZGF0ZVF1ZXVlXSBpcyBjYWxs
ZWQgb24gYQogcXVldWUgY3JlYXRlZCBieSBgcXVldWUueWFtbC94bWxgLCBgbWF4X2J1cnN0
X3NpemVgIHdpbGwgYmUgcmVzZXQgYmFzZWQgb24KIHRoZSB2YWx1ZSBvZiBgbWF4X2Rpc3Bh
dGNoZXNfcGVyX3NlY29uZGAsIHJlZ2FyZGxlc3Mgb2Ygd2hldGhlcgogYG1heF9kaXNwYXRj
aGVzX3Blcl9zZWNvbmRgIGlzIHVwZGF0ZWQuCgoKDQoFBAECAQUSBO8BAgcKDQoFBAECAQES
BO8BCBYKDQoFBAECAQMSBO8BGRoKngQKBAQBAgISBIACAiYajwQgVGhlIG1heGltdW0gbnVt
YmVyIG9mIGNvbmN1cnJlbnQgdGFza3MgdGhhdCBDbG91ZCBUYXNrcyBhbGxvd3MKIHRvIGJl
IGRpc3BhdGNoZWQgZm9yIHRoaXMgcXVldWUuIEFmdGVyIHRoaXMgdGhyZXNob2xkIGhhcyBi
ZWVuCiByZWFjaGVkLCBDbG91ZCBUYXNrcyBzdG9wcyBkaXNwYXRjaGluZyB0YXNrcyB1bnRp
bCB0aGUgbnVtYmVyIG9mCiBjb25jdXJyZW50IHJlcXVlc3RzIGRlY3JlYXNlcy4KCiBJZiB1
bnNwZWNpZmllZCB3aGVuIHRoZSBxdWV1ZSBpcyBjcmVhdGVkLCBDbG91ZCBUYXNrcyB3aWxs
IHBpY2sgdGhlCiBkZWZhdWx0LgoKCiBUaGUgbWF4aW11bSBhbGxvd2VkIHZhbHVlIGlzIDUs
MDAwLgoKCiBUaGlzIGZpZWxkIGhhcyB0aGUgc2FtZSBtZWFuaW5nIGFzCiBbbWF4X2NvbmN1
cnJlbnRfcmVxdWVzdHMgaW4KIHF1ZXVlLnlhbWwveG1sXShodHRwczovL2Nsb3VkLmdvb2ds
ZS5jb20vYXBwZW5naW5lL2RvY3Mvc3RhbmRhcmQvcHl0aG9uL2NvbmZpZy9xdWV1ZXJlZiNt
YXhfY29uY3VycmVudF9yZXF1ZXN0cykuCgoNCgUEAQICBRIEgAICBwoNCgUEAQICARIEgAII
IQoNCgUEAQICAxIEgAIkJQpfCgIEAhIGhgIAgQMBGlEgUmV0cnkgY29uZmlnLgoKIFRoZXNl
IHNldHRpbmdzIGRldGVybWluZSB3aGVuIGEgZmFpbGVkIHRhc2sgYXR0ZW1wdCBpcyByZXRy
aWVkLgoKCwoDBAIBEgSGAggTCtIHCgQEAgIAEgSdAgIZGsMHIE51bWJlciBvZiBhdHRlbXB0
cyBwZXIgdGFzaywgaW5jbHVkaW5nIHRoZSBmaXJzdCBhdHRlbXB0LiAoSWYgdGhlCiBmaXJz
dCBhdHRlbXB0IGZhaWxzLCB0aGVyZSB3aWxsIGJlIGBtYXhfYXR0ZW1wdHMgLSAxYCByZXRy
aWVzLikKCiBNdXN0IGJlIGdyZWF0ZXIgdGhhbiBvciBlcXVhbCB0byAtMSwgd2hpY2ggaW5k
aWNhdGVzIHVubGltaXRlZCBhdHRlbXB0cy4KCgogQ2xvdWQgVGFza3Mgc3RvcHMgcmV0cnlp
bmcgb25seSB3aGVuIGBtYXhfYXR0ZW1wdHNgIGFuZAogYG1heF9yZXRyeV9kdXJhdGlvbmAg
YXJlIGJvdGggc2F0aXNmaWVkLCBvciB3aGVuIHRoZSB0YXNrIGlzIHN1Y2Nlc3NmdWxseQog
ZXhlY3V0ZWQuIFdoZW4gdGhlIHRhc2sgaGFzIGJlZW4gYXR0ZW1wdGVkCiBgbWF4X2F0dGVt
cHRzYCB0aW1lcyBhbmQgd2hlbiB0aGUgYG1heF9yZXRyeV9kdXJhdGlvbmAgdGltZSBoYXMg
cGFzc2VkLCBubwogZnVydGhlciBhdHRlbXB0cyBhcmUgbWFkZSwgYW5kIHRoZSB0YXNrIGlz
IGRlbGV0ZWQuIElmIGBtYXhfYXR0ZW1wdHNgIGlzCiBzZXQgdG8gLTEgYW5kIGBtYXhfcmV0
cnlfZHVyYXRpb25gIGlzIHNldCB0byAwLCB0aGUgdGFzayBpcyByZXRyaWVkCiB1bnRpbCB0
aGUgW21heGltdW0gdGFzawogcmV0ZW50aW9uXShodHRwczovL2RvY3MuY2xvdWQuZ29vZ2xl
LmNvbS90YXNrcy9kb2NzL3F1b3RhcyNsaW1pdHMpIGxpbWl0IGlzCiByZWFjaGVkLgoKIElm
IHVuc3BlY2lmaWVkIHdoZW4gdGhlIHF1ZXVlIGlzIGNyZWF0ZWQsIENsb3VkIFRhc2tzIHdp
bGwgcGljayB0aGUKIGRlZmF1bHQuCgogVGhpcyBmaWVsZCBoYXMgdGhlIHNhbWUgbWVhbmlu
ZyBhcwogW3Rhc2tfcmV0cnlfbGltaXQgaW4KIHF1ZXVlLnlhbWwveG1sXShodHRwczovL2Ns
b3VkLmdvb2dsZS5jb20vYXBwZW5naW5lL2RvY3Mvc3RhbmRhcmQvcHl0aG9uL2NvbmZpZy9x
dWV1ZXJlZiNyZXRyeV9wYXJhbWV0ZXJzKS4KCg0KBQQCAgAFEgSdAgIHCg0KBQQCAgABEgSd
AggUCg0KBQQCAgADEgSdAhcYCrwICgQEAgIBEgS3AgIyGq0IIElmIHBvc2l0aXZlLCBgbWF4
X3JldHJ5X2R1cmF0aW9uYCBzcGVjaWZpZXMgdGhlIHRpbWUgbGltaXQgZm9yCiByZXRyeWlu
ZyBhIGZhaWxlZCB0YXNrLCBtZWFzdXJlZCBmcm9tIHdoZW4gdGhlIHRhc2sgd2FzIGZpcnN0
CiBhdHRlbXB0ZWQuIE9uY2UgYG1heF9yZXRyeV9kdXJhdGlvbmAgdGltZSBoYXMgcGFzc2Vk
ICphbmQqIHRoZQogdGFzayBoYXMgYmVlbiBhdHRlbXB0ZWQKIFttYXhfYXR0ZW1wdHNdW2dv
b2dsZS5jbG91ZC50YXNrcy52Mi5SZXRyeUNvbmZpZy5tYXhfYXR0ZW1wdHNdIHRpbWVzLCBu
bwogZnVydGhlciBhdHRlbXB0cyBhcmUgbWFkZSBhbmQgdGhlIHRhc2sgaXMgZGVsZXRlZC4K
CiBBIHplcm8gKDApIGluZGljYXRlcyBhbiB1bmxpbWl0ZWQgZHVyYXRpb24sIHVwIHRvIHRo
ZQogW21heGltdW0gdGFzawogcmV0ZW50aW9uXShodHRwczovL2RvY3MuY2xvdWQuZ29vZ2xl
LmNvbS90YXNrcy9kb2NzL3F1b3RhcyNsaW1pdHMpIGxpbWl0LgoKCiBUaGUgdmFsdWUgbXVz
dCBiZSBnaXZlbiBhcyBhIHN0cmluZyB0aGF0IGluZGljYXRlcyB0aGUgbGVuZ3RoIG9mIHRp
bWUKIChpbiBzZWNvbmRzKSBmb2xsb3dlZCBieSBgc2AgKGZvciAic2Vjb25kcyIpLiBGb3Ig
dGhlIG1heGltdW0gcG9zc2libGUKIHZhbHVlIG9yIHRoZSBmb3JtYXQsIHNlZSB0aGUgZG9j
dW1lbnRhdGlvbiBmb3IKIFtEdXJhdGlvbl0oaHR0cHM6Ly9wcm90b2J1Zi5kZXYvcmVmZXJl
bmNlL3Byb3RvYnVmL2dvb2dsZS5wcm90b2J1Zi8jZHVyYXRpb24pLgogYG1heF9yZXRyeV9k
dXJhdGlvbmAgd2lsbCBiZSB0cnVuY2F0ZWQgdG8gdGhlIG5lYXJlc3Qgc2Vjb25kLgoKIElm
IHVuc3BlY2lmaWVkIHdoZW4gdGhlIHF1ZXVlIGlzIGNyZWF0ZWQsIENsb3VkIFRhc2tzIHdp
bGwgcGljayB0aGUKIGRlZmF1bHQuCgogVGhpcyBmaWVsZCBoYXMgdGhlIHNhbWUgbWVhbmlu
ZyBhcwogW3Rhc2tfYWdlX2xpbWl0IGluCiBxdWV1ZS55YW1sL3htbF0oaHR0cHM6Ly9jbG91
ZC5nb29nbGUuY29tL2FwcGVuZ2luZS9kb2NzL3N0YW5kYXJkL3B5dGhvbi9jb25maWcvcXVl
dWVyZWYjcmV0cnlfcGFyYW1ldGVycykuCgoNCgUEAgIBBhIEtwICGgoNCgUEAgIBARIEtwIb
LQoNCgUEAgIBAxIEtwIwMQqnBwoEBAICAhIEzQICKxqYByBBIHRhc2sgd2lsbCBiZSBbc2No
ZWR1bGVkXVtnb29nbGUuY2xvdWQudGFza3MudjIuVGFzay5zY2hlZHVsZV90aW1lXSBmb3IK
IHJldHJ5IGJldHdlZW4gW21pbl9iYWNrb2ZmXVtnb29nbGUuY2xvdWQudGFza3MudjIuUmV0
cnlDb25maWcubWluX2JhY2tvZmZdCiBhbmQgW21heF9iYWNrb2ZmXVtnb29nbGUuY2xvdWQu
dGFza3MudjIuUmV0cnlDb25maWcubWF4X2JhY2tvZmZdIGR1cmF0aW9uCiBhZnRlciBpdCBm
YWlscywgaWYgdGhlIHF1ZXVlJ3MKIFtSZXRyeUNvbmZpZ11bZ29vZ2xlLmNsb3VkLnRhc2tz
LnYyLlJldHJ5Q29uZmlnXSBzcGVjaWZpZXMgdGhhdCB0aGUgdGFzawogc2hvdWxkIGJlIHJl
dHJpZWQuCgoKIFRoZSB2YWx1ZSBtdXN0IGJlIGdpdmVuIGFzIGEgc3RyaW5nIHRoYXQgaW5k
aWNhdGVzIHRoZSBsZW5ndGggb2YgdGltZQogKGluIHNlY29uZHMpIGZvbGxvd2VkIGJ5IGBz
YCAoZm9yICJzZWNvbmRzIikuIEZvciBtb3JlIGluZm9ybWF0aW9uIG9uIHRoZQogZm9ybWF0
LCBzZWUgdGhlIGRvY3VtZW50YXRpb24gZm9yCiBbRHVyYXRpb25dKGh0dHBzOi8vcHJvdG9i
dWYuZGV2L3JlZmVyZW5jZS9wcm90b2J1Zi9nb29nbGUucHJvdG9idWYvI2R1cmF0aW9uKS4K
IGBtaW5fYmFja29mZmAgd2lsbCBiZSB0cnVuY2F0ZWQgdG8gdGhlIG5lYXJlc3Qgc2Vjb25k
LgoKIElmIHVuc3BlY2lmaWVkIHdoZW4gdGhlIHF1ZXVlIGlzIGNyZWF0ZWQsIENsb3VkIFRh
c2tzIHdpbGwgcGljayB0aGUKIGRlZmF1bHQuCgogVGhpcyBmaWVsZCBoYXMgdGhlIHNhbWUg
bWVhbmluZyBhcwogW21pbl9iYWNrb2ZmX3NlY29uZHMgaW4KIHF1ZXVlLnlhbWwveG1sXSho
dHRwczovL2Nsb3VkLmdvb2dsZS5jb20vYXBwZW5naW5lL2RvY3Mvc3RhbmRhcmQvcHl0aG9u
L2NvbmZpZy9xdWV1ZXJlZiNyZXRyeV9wYXJhbWV0ZXJzKS4KCg0KBQQCAgIGEgTNAgIaCg0K
BQQCAgIBEgTNAhsmCg0KBQQCAgIDEgTNAikqCqcHCgQEAgIDEgTjAgIrGpgHIEEgdGFzayB3
aWxsIGJlIFtzY2hlZHVsZWRdW2dvb2dsZS5jbG91ZC50YXNrcy52Mi5UYXNrLnNjaGVkdWxl
X3RpbWVdIGZvcgogcmV0cnkgYmV0d2VlbiBbbWluX2JhY2tvZmZdW2dvb2dsZS5jbG91ZC50
YXNrcy52Mi5SZXRyeUNvbmZpZy5taW5fYmFja29mZl0KIGFuZCBbbWF4X2JhY2tvZmZdW2dv
b2dsZS5jbG91ZC50YXNrcy52Mi5SZXRyeUNvbmZpZy5tYXhfYmFja29mZl0gZHVyYXRpb24K
IGFmdGVyIGl0IGZhaWxzLCBpZiB0aGUgcXVldWUncwogW1JldHJ5Q29uZmlnXVtnb29nbGUu
Y2xvdWQudGFza3MudjIuUmV0cnlDb25maWddIHNwZWNpZmllcyB0aGF0IHRoZSB0YXNrCiBz
aG91bGQgYmUgcmV0cmllZC4KCgogVGhlIHZhbHVlIG11c3QgYmUgZ2l2ZW4gYXMgYSBzdHJp
bmcgdGhhdCBpbmRpY2F0ZXMgdGhlIGxlbmd0aCBvZiB0aW1lCiAoaW4gc2Vjb25kcykgZm9s
bG93ZWQgYnkgYHNgIChmb3IgInNlY29uZHMiKS4gRm9yIG1vcmUgaW5mb3JtYXRpb24gb24g
dGhlCiBmb3JtYXQsIHNlZSB0aGUgZG9jdW1lbnRhdGlvbiBmb3IKIFtEdXJhdGlvbl0oaHR0
cHM6Ly9wcm90b2J1Zi5kZXYvcmVmZXJlbmNlL3Byb3RvYnVmL2dvb2dsZS5wcm90b2J1Zi8j
ZHVyYXRpb24pLgogYG1heF9iYWNrb2ZmYCB3aWxsIGJlIHRydW5jYXRlZCB0byB0aGUgbmVh
cmVzdCBzZWNvbmQuCgogSWYgdW5zcGVjaWZpZWQgd2hlbiB0aGUgcXVldWUgaXMgY3JlYXRl
ZCwgQ2xvdWQgVGFza3Mgd2lsbCBwaWNrIHRoZQogZGVmYXVsdC4KCiBUaGlzIGZpZWxkIGhh
cyB0aGUgc2FtZSBtZWFuaW5nIGFzCiBbbWF4X2JhY2tvZmZfc2Vjb25kcyBpbgogcXVldWUu
eWFtbC94bWxdKGh0dHBzOi8vY2xvdWQuZ29vZ2xlLmNvbS9hcHBlbmdpbmUvZG9jcy9zdGFu
ZGFyZC9weXRob24vY29uZmlnL3F1ZXVlcmVmI3JldHJ5X3BhcmFtZXRlcnMpLgoKDQoFBAIC
AwYSBOMCAhoKDQoFBAICAwESBOMCGyYKDQoFBAICAwMSBOMCKSoK+gkKBAQCAgQSBIADAhoa
6wkgVGhlIHRpbWUgYmV0d2VlbiByZXRyaWVzIHdpbGwgZG91YmxlIGBtYXhfZG91Ymxpbmdz
YCB0aW1lcy4KCiBBIHRhc2sncyByZXRyeSBpbnRlcnZhbCBzdGFydHMgYXQKIFttaW5fYmFj
a29mZl1bZ29vZ2xlLmNsb3VkLnRhc2tzLnYyLlJldHJ5Q29uZmlnLm1pbl9iYWNrb2ZmXSwg
dGhlbiBkb3VibGVzCiBgbWF4X2RvdWJsaW5nc2AgdGltZXMsIHRoZW4gaW5jcmVhc2VzIGxp
bmVhcmx5LCBhbmQgZmluYWxseQogcmV0cmllcyBhdCBpbnRlcnZhbHMgb2YKIFttYXhfYmFj
a29mZl1bZ29vZ2xlLmNsb3VkLnRhc2tzLnYyLlJldHJ5Q29uZmlnLm1heF9iYWNrb2ZmXSB1
cCB0bwogW21heF9hdHRlbXB0c11bZ29vZ2xlLmNsb3VkLnRhc2tzLnYyLlJldHJ5Q29uZmln
Lm1heF9hdHRlbXB0c10gdGltZXMuCgogRm9yIGV4YW1wbGUsIGlmCiBbbWluX2JhY2tvZmZd
W2dvb2dsZS5jbG91ZC50YXNrcy52Mi5SZXRyeUNvbmZpZy5taW5fYmFja29mZl0gaXMgMTBz
LAogW21heF9iYWNrb2ZmXVtnb29nbGUuY2xvdWQudGFza3MudjIuUmV0cnlDb25maWcubWF4
X2JhY2tvZmZdIGlzIDMwMHMsIGFuZAogYG1heF9kb3VibGluZ3NgIGlzIDMsIHRoZW4gdGhl
IGEgdGFzayB3aWxsIGZpcnN0IGJlIHJldHJpZWQgaW4KIDEwcy4gVGhlIHJldHJ5IGludGVy
dmFsIHdpbGwgZG91YmxlIHRocmVlIHRpbWVzLCBhbmQgdGhlbgogaW5jcmVhc2UgbGluZWFy
bHkgYnkgMl4zICogMTBzLiAgRmluYWxseSwgdGhlIHRhc2sgd2lsbCByZXRyeSBhdAogaW50
ZXJ2YWxzIG9mIFttYXhfYmFja29mZl1bZ29vZ2xlLmNsb3VkLnRhc2tzLnYyLlJldHJ5Q29u
ZmlnLm1heF9iYWNrb2ZmXQogdW50aWwgdGhlIHRhc2sgaGFzIGJlZW4gYXR0ZW1wdGVkCiBb
bWF4X2F0dGVtcHRzXVtnb29nbGUuY2xvdWQudGFza3MudjIuUmV0cnlDb25maWcubWF4X2F0
dGVtcHRzXSB0aW1lcy4gVGh1cywKIHRoZSByZXF1ZXN0cyB3aWxsIHJldHJ5IGF0IDEwcywg
MjBzLCA0MHMsIDgwcywgMTYwcywgMjQwcywgMzAwcywgMzAwcywgLi4uLgoKIElmIHVuc3Bl
Y2lmaWVkIHdoZW4gdGhlIHF1ZXVlIGlzIGNyZWF0ZWQsIENsb3VkIFRhc2tzIHdpbGwgcGlj
ayB0aGUKIGRlZmF1bHQuCgoKIFRoaXMgZmllbGQgaGFzIHRoZSBzYW1lIG1lYW5pbmcgYXMK
IFttYXhfZG91YmxpbmdzIGluCiBxdWV1ZS55YW1sL3htbF0oaHR0cHM6Ly9jbG91ZC5nb29n
bGUuY29tL2FwcGVuZ2luZS9kb2NzL3N0YW5kYXJkL3B5dGhvbi9jb25maWcvcXVldWVyZWYj
cmV0cnlfcGFyYW1ldGVycykuCgoNCgUEAgIEBRIEgAMCBwoNCgUEAgIEARIEgAMIFQoNCgUE
AgIEAxIEgAMYGQp5CgIEAxIGhQMAiwMBGmsgQ29uZmlndXJhdGlvbiBvcHRpb25zIGZvciB3
cml0aW5nIGxvZ3MgdG8KIFtTdGFja2RyaXZlciBMb2dnaW5nXShodHRwczovL2Nsb3VkLmdv
b2dsZS5jb20vbG9nZ2luZy9kb2NzLykuCgoLCgMEAwESBIUDCCAKgAIKBAQDAgASBIoDAhwa
8QEgU3BlY2lmaWVzIHRoZSBmcmFjdGlvbiBvZiBvcGVyYXRpb25zIHRvIHdyaXRlIHRvCiBb
U3RhY2tkcml2ZXIgTG9nZ2luZ10oaHR0cHM6Ly9jbG91ZC5nb29nbGUuY29tL2xvZ2dpbmcv
ZG9jcy8pLgogVGhpcyBmaWVsZCBtYXkgY29udGFpbiBhbnkgdmFsdWUgYmV0d2VlbiAwLjAg
YW5kIDEuMCwgaW5jbHVzaXZlLgogMC4wIGlzIHRoZSBkZWZhdWx0IGFuZCBtZWFucyB0aGF0
IG5vIG9wZXJhdGlvbnMgYXJlIGxvZ2dlZC4KCg0KBQQDAgAFEgSKAwIICg0KBQQDAgABEgSK
AwkXCg0KBQQDAgADEgSKAxobYgZwcm90bzM=
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Tasks::V2::Queue::Queue ===
    # Fields for Queue
    # Field: name Type: 9 ()
    # Field: app_engine_routing_override Type: 11 (.google.cloud.tasks.v2.AppEngineRouting)
    # Field: http_target Type: 11 (.google.cloud.tasks.v2.HttpTarget)
    # Field: rate_limits Type: 11 (.google.cloud.tasks.v2.RateLimits)
    # Field: retry_config Type: 11 (.google.cloud.tasks.v2.RetryConfig)
    # Field: state Type: 14 (.google.cloud.tasks.v2.Queue.State)
    # Field: purge_time Type: 11 (.google.protobuf.Timestamp)
    # Field: stackdriver_logging_config Type: 11 (.google.cloud.tasks.v2.StackdriverLoggingConfig)

# Enum: Queue::State
our $Queue_STATE_UNSPECIFIED = 0;
our $Queue_RUNNING = 1;
our $Queue_PAUSED = 2;
our $Queue_DISABLED = 3;

# === Message: Google::Cloud::Tasks::V2::Queue::RateLimits ===
    # Fields for RateLimits
    # Field: max_dispatches_per_second Type: 1 ()
    # Field: max_burst_size Type: 5 ()
    # Field: max_concurrent_dispatches Type: 5 ()

# === Message: Google::Cloud::Tasks::V2::Queue::RetryConfig ===
    # Fields for RetryConfig
    # Field: max_attempts Type: 5 ()
    # Field: max_retry_duration Type: 11 (.google.protobuf.Duration)
    # Field: min_backoff Type: 11 (.google.protobuf.Duration)
    # Field: max_backoff Type: 11 (.google.protobuf.Duration)
    # Field: max_doublings Type: 5 ()

# === Message: Google::Cloud::Tasks::V2::Queue::StackdriverLoggingConfig ===
    # Fields for StackdriverLoggingConfig
    # Field: sampling_ratio Type: 1 ()

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Tasks::V2::Queue - Compiled Protocol Buffers messages for google/cloud/tasks/v2/queue.proto

=head1 SYNOPSIS

    use Google::Cloud::Tasks::V2::Queue;

    my $msg = Google::Cloud::Tasks::V2::Queue::Queue->new({
        name => $name,
        app_engine_routing_override => $app_engine_routing_override,
        http_target => $http_target,
        rate_limits => $rate_limits,
    });

    # Read or update a field
    my $val = $msg->name();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Tasks::V2::Queue::Queue->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/tasks/v2/queue.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Tasks::V2::Queue::Queue

A queue is a container of related tasks. Queues are configured to manage
how those tasks are dispatched. Configurable properties include rate limits,
retry options, queue types, and others.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Caller-specified and required in
[CreateQueue][google.cloud.tasks.v2.CloudTasks.CreateQueue], after which it
becomes output only.

The queue name.

The queue name must have the following format:
`projects/PROJECT_ID/locations/LOCATION_ID/queues/QUEUE_ID`

* `PROJECT_ID` can contain letters ([A-Za-z]), numbers ([0-9]),
   hyphens (-), colons (:), or periods (.).
   For more information, see
   [Identifying
   projects](https://cloud.google.com/resource-manager/docs/creating-managing-projects#identifying_projects)
* `LOCATION_ID` is the canonical ID for the queue's location.
   The list of available locations can be obtained by calling
   [ListLocations][google.cloud.location.Locations.ListLocations].
   For more information, see https://cloud.google.com/about/locations/.
* `QUEUE_ID` can contain letters ([A-Za-z]), numbers ([0-9]), or
  hyphens (-). The maximum length is 100 characters.

=item * C<< $msg->app_engine_routing_override() >> / C<< $msg->app_engine_routing_override($value) >>

Type: C<Message> (L<Google::Cloud::Tasks::V2::Target::AppEngineRouting>)

Overrides for
[task-level
app_engine_routing][google.cloud.tasks.v2.AppEngineHttpRequest.app_engine_routing].
These settings apply only to
[App Engine tasks][google.cloud.tasks.v2.AppEngineHttpRequest] in this
queue. [Http tasks][google.cloud.tasks.v2.HttpRequest] are not affected.

If set, `app_engine_routing_override` is used for all
[App Engine tasks][google.cloud.tasks.v2.AppEngineHttpRequest] in the
queue, no matter what the setting is for the [task-level
app_engine_routing][google.cloud.tasks.v2.AppEngineHttpRequest.app_engine_routing].

=item * C<< $msg->http_target() >> / C<< $msg->http_target($value) >>

Type: C<Message> (L<Google::Cloud::Tasks::V2::Target::HttpTarget>)

Modifies HTTP target for HTTP tasks.

=item * C<< $msg->rate_limits() >> / C<< $msg->rate_limits($value) >>

Type: C<Message> (L<Google::Cloud::Tasks::V2::Queue::RateLimits>)

Rate limits for task dispatches.

[rate_limits][google.cloud.tasks.v2.Queue.rate_limits] and
[retry_config][google.cloud.tasks.v2.Queue.retry_config] are related
because they both control task attempts. However they control task attempts
in different ways:

* [rate_limits][google.cloud.tasks.v2.Queue.rate_limits] controls the total
rate of
  dispatches from a queue (i.e. all traffic dispatched from the
  queue, regardless of whether the dispatch is from a first
  attempt or a retry).
* [retry_config][google.cloud.tasks.v2.Queue.retry_config] controls what
happens to a
  particular task after its first attempt fails. That is,
  [retry_config][google.cloud.tasks.v2.Queue.retry_config] controls task
  retries (the second attempt, third attempt, etc).

The queue's actual dispatch rate is the result of:

* Number of tasks in the queue
* User-specified throttling:
[rate_limits][google.cloud.tasks.v2.Queue.rate_limits],
  [retry_config][google.cloud.tasks.v2.Queue.retry_config], and the
  [queue's state][google.cloud.tasks.v2.Queue.state].
* System throttling due to `429` (Too Many Requests) or `503` (Service
  Unavailable) responses from the worker, high error rates, or to smooth
  sudden large traffic spikes.

=item * C<< $msg->retry_config() >> / C<< $msg->retry_config($value) >>

Type: C<Message> (L<Google::Cloud::Tasks::V2::Queue::RetryConfig>)

Settings that determine the retry behavior.

* For tasks created using Cloud Tasks: the queue-level retry settings
  apply to all tasks in the queue that were created using Cloud Tasks.
  Retry settings cannot be set on individual tasks.
* For tasks created using the App Engine SDK: the queue-level retry
  settings apply to all tasks in the queue which do not have retry settings
  explicitly set on the task and were created by the App Engine SDK. See
  [App Engine
  documentation](https://cloud.google.com/appengine/docs/standard/python/taskqueue/push/retrying-tasks).

=item * C<< $msg->state() >> / C<< $msg->state($value) >>

Type: C<Enum> (L<Google::Cloud::Tasks::V2::Queue::State>)

Output only. The state of the queue.

`state` can only be changed by calling
[PauseQueue][google.cloud.tasks.v2.CloudTasks.PauseQueue],
[ResumeQueue][google.cloud.tasks.v2.CloudTasks.ResumeQueue], or uploading
[queue.yaml/xml](https://cloud.google.com/appengine/docs/python/config/queueref).
[UpdateQueue][google.cloud.tasks.v2.CloudTasks.UpdateQueue] cannot be used
to change `state`.

=item * C<< $msg->purge_time() >> / C<< $msg->purge_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Output only. The last time this queue was purged.

All tasks that were [created][google.cloud.tasks.v2.Task.create_time]
before this time were purged.

A queue can be purged using
[PurgeQueue][google.cloud.tasks.v2.CloudTasks.PurgeQueue], the [App Engine
Task Queue SDK, or the Cloud
Console](https://cloud.google.com/appengine/docs/standard/python/taskqueue/push/deleting-tasks-and-queues#purging_all_tasks_from_a_queue).

Purge time will be truncated to the nearest microsecond. Purge
time will be unset if the queue has never been purged.

=item * C<< $msg->stackdriver_logging_config() >> / C<< $msg->stackdriver_logging_config($value) >>

Type: C<Message> (L<Google::Cloud::Tasks::V2::Queue::StackdriverLoggingConfig>)

Configuration options for writing logs to
[Stackdriver Logging](https://cloud.google.com/logging/docs/). If this
field is unset, then no logs are written.

=back

=head3 Enum: Queue::State

=over 4

=item * C<STATE_UNSPECIFIED> => C<0>

=item * C<RUNNING> => C<1>

=item * C<PAUSED> => C<2>

=item * C<DISABLED> => C<3>

=back

=head2 Google::Cloud::Tasks::V2::Queue::RateLimits

Rate limits.

This message determines the maximum rate that tasks can be dispatched by a
queue, regardless of whether the dispatch is a first task attempt or a retry.

Note: The debugging command,
[RunTask][google.cloud.tasks.v2.CloudTasks.RunTask], will run a task even if
the queue has reached its [RateLimits][google.cloud.tasks.v2.RateLimits].

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->max_dispatches_per_second() >> / C<< $msg->max_dispatches_per_second($value) >>

Type: C<Double>

The maximum rate at which tasks are dispatched from this queue.

If unspecified when the queue is created, Cloud Tasks will pick the
default.

The maximum allowed value is 500.


This field has the same meaning as
[rate in
queue.yaml/xml](https://cloud.google.com/appengine/docs/standard/python/config/queueref#rate).

=item * C<< $msg->max_burst_size() >> / C<< $msg->max_burst_size($value) >>

Type: C<Int32>

Output only. The max burst size.

Max burst size limits how fast tasks in queue are processed when
many tasks are in the queue and the rate is high. This field
allows the queue to have a high rate so processing starts shortly
after a task is enqueued, but still limits resource usage when
many tasks are enqueued in a short period of time.

The [token bucket](https://wikipedia.org/wiki/Token_Bucket)
algorithm is used to control the rate of task dispatches. Each
queue has a token bucket that holds tokens, up to the maximum
specified by `max_burst_size`. Each time a task is dispatched, a
token is removed from the bucket. Tasks will be dispatched until
the queue's bucket runs out of tokens. The bucket will be
continuously refilled with new tokens based on
`max_dispatches_per_second`.

Cloud Tasks automatically sets an appropriate `max_burst_size` based
on the value of `max_dispatches_per_second`. The value is dynamically
optimized to ensure queue stability and throughput. It is generally at
least equal to `max_dispatches_per_second` but might be higher to
accommodate bursts of traffic.

For queues that were created or updated using
`queue.yaml/xml`, `max_burst_size` is equal to
[bucket_size](https://cloud.google.com/appengine/docs/standard/python/config/queueref#bucket_size).
Since `max_burst_size` is output only, if
[UpdateQueue][google.cloud.tasks.v2.CloudTasks.UpdateQueue] is called on a
queue created by `queue.yaml/xml`, `max_burst_size` will be reset based on
the value of `max_dispatches_per_second`, regardless of whether
`max_dispatches_per_second` is updated.


=item * C<< $msg->max_concurrent_dispatches() >> / C<< $msg->max_concurrent_dispatches($value) >>

Type: C<Int32>

The maximum number of concurrent tasks that Cloud Tasks allows
to be dispatched for this queue. After this threshold has been
reached, Cloud Tasks stops dispatching tasks until the number of
concurrent requests decreases.

If unspecified when the queue is created, Cloud Tasks will pick the
default.


The maximum allowed value is 5,000.


This field has the same meaning as
[max_concurrent_requests in
queue.yaml/xml](https://cloud.google.com/appengine/docs/standard/python/config/queueref#max_concurrent_requests).

=back

=head2 Google::Cloud::Tasks::V2::Queue::RetryConfig

Retry config.

These settings determine when a failed task attempt is retried.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->max_attempts() >> / C<< $msg->max_attempts($value) >>

Type: C<Int32>

Number of attempts per task, including the first attempt. (If the
first attempt fails, there will be `max_attempts - 1` retries.)

Must be greater than or equal to -1, which indicates unlimited attempts.


Cloud Tasks stops retrying only when `max_attempts` and
`max_retry_duration` are both satisfied, or when the task is successfully
executed. When the task has been attempted
`max_attempts` times and when the `max_retry_duration` time has passed, no
further attempts are made, and the task is deleted. If `max_attempts` is
set to -1 and `max_retry_duration` is set to 0, the task is retried
until the [maximum task
retention](https://docs.cloud.google.com/tasks/docs/quotas#limits) limit is
reached.

If unspecified when the queue is created, Cloud Tasks will pick the
default.

This field has the same meaning as
[task_retry_limit in
queue.yaml/xml](https://cloud.google.com/appengine/docs/standard/python/config/queueref#retry_parameters).

=item * C<< $msg->max_retry_duration() >> / C<< $msg->max_retry_duration($value) >>

Type: C<Message> (L<Google::Protobuf::Duration::Duration>)

If positive, `max_retry_duration` specifies the time limit for
retrying a failed task, measured from when the task was first
attempted. Once `max_retry_duration` time has passed *and* the
task has been attempted
[max_attempts][google.cloud.tasks.v2.RetryConfig.max_attempts] times, no
further attempts are made and the task is deleted.

A zero (0) indicates an unlimited duration, up to the
[maximum task
retention](https://docs.cloud.google.com/tasks/docs/quotas#limits) limit.


The value must be given as a string that indicates the length of time
(in seconds) followed by `s` (for "seconds"). For the maximum possible
value or the format, see the documentation for
[Duration](https://protobuf.dev/reference/protobuf/google.protobuf/#duration).
`max_retry_duration` will be truncated to the nearest second.

If unspecified when the queue is created, Cloud Tasks will pick the
default.

This field has the same meaning as
[task_age_limit in
queue.yaml/xml](https://cloud.google.com/appengine/docs/standard/python/config/queueref#retry_parameters).

=item * C<< $msg->min_backoff() >> / C<< $msg->min_backoff($value) >>

Type: C<Message> (L<Google::Protobuf::Duration::Duration>)

A task will be [scheduled][google.cloud.tasks.v2.Task.schedule_time] for
retry between [min_backoff][google.cloud.tasks.v2.RetryConfig.min_backoff]
and [max_backoff][google.cloud.tasks.v2.RetryConfig.max_backoff] duration
after it fails, if the queue's
[RetryConfig][google.cloud.tasks.v2.RetryConfig] specifies that the task
should be retried.


The value must be given as a string that indicates the length of time
(in seconds) followed by `s` (for "seconds"). For more information on the
format, see the documentation for
[Duration](https://protobuf.dev/reference/protobuf/google.protobuf/#duration).
`min_backoff` will be truncated to the nearest second.

If unspecified when the queue is created, Cloud Tasks will pick the
default.

This field has the same meaning as
[min_backoff_seconds in
queue.yaml/xml](https://cloud.google.com/appengine/docs/standard/python/config/queueref#retry_parameters).

=item * C<< $msg->max_backoff() >> / C<< $msg->max_backoff($value) >>

Type: C<Message> (L<Google::Protobuf::Duration::Duration>)

A task will be [scheduled][google.cloud.tasks.v2.Task.schedule_time] for
retry between [min_backoff][google.cloud.tasks.v2.RetryConfig.min_backoff]
and [max_backoff][google.cloud.tasks.v2.RetryConfig.max_backoff] duration
after it fails, if the queue's
[RetryConfig][google.cloud.tasks.v2.RetryConfig] specifies that the task
should be retried.


The value must be given as a string that indicates the length of time
(in seconds) followed by `s` (for "seconds"). For more information on the
format, see the documentation for
[Duration](https://protobuf.dev/reference/protobuf/google.protobuf/#duration).
`max_backoff` will be truncated to the nearest second.

If unspecified when the queue is created, Cloud Tasks will pick the
default.

This field has the same meaning as
[max_backoff_seconds in
queue.yaml/xml](https://cloud.google.com/appengine/docs/standard/python/config/queueref#retry_parameters).

=item * C<< $msg->max_doublings() >> / C<< $msg->max_doublings($value) >>

Type: C<Int32>

The time between retries will double `max_doublings` times.

A task's retry interval starts at
[min_backoff][google.cloud.tasks.v2.RetryConfig.min_backoff], then doubles
`max_doublings` times, then increases linearly, and finally
retries at intervals of
[max_backoff][google.cloud.tasks.v2.RetryConfig.max_backoff] up to
[max_attempts][google.cloud.tasks.v2.RetryConfig.max_attempts] times.

For example, if
[min_backoff][google.cloud.tasks.v2.RetryConfig.min_backoff] is 10s,
[max_backoff][google.cloud.tasks.v2.RetryConfig.max_backoff] is 300s, and
`max_doublings` is 3, then the a task will first be retried in
10s. The retry interval will double three times, and then
increase linearly by 2^3 * 10s.  Finally, the task will retry at
intervals of [max_backoff][google.cloud.tasks.v2.RetryConfig.max_backoff]
until the task has been attempted
[max_attempts][google.cloud.tasks.v2.RetryConfig.max_attempts] times. Thus,
the requests will retry at 10s, 20s, 40s, 80s, 160s, 240s, 300s, 300s, ....

If unspecified when the queue is created, Cloud Tasks will pick the
default.


This field has the same meaning as
[max_doublings in
queue.yaml/xml](https://cloud.google.com/appengine/docs/standard/python/config/queueref#retry_parameters).

=back

=head2 Google::Cloud::Tasks::V2::Queue::StackdriverLoggingConfig

Configuration options for writing logs to
[Stackdriver Logging](https://cloud.google.com/logging/docs/).

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->sampling_ratio() >> / C<< $msg->sampling_ratio($value) >>

Type: C<Double>

Specifies the fraction of operations to write to
[Stackdriver Logging](https://cloud.google.com/logging/docs/).
This field may contain any value between 0.0 and 1.0, inclusive.
0.0 is the default and means that no operations are logged.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Tasks::V2::Queue::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
