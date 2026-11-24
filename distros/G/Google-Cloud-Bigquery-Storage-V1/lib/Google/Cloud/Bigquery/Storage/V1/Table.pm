package Google::Cloud::Bigquery::Storage::V1::Table;

use strict;
use warnings;

our $VERSION = '0.14';

use Protobuf::Message;
use Protobuf::DescriptorPool;
use Protobuf::Internal qw(:all);
use MIME::Base64;

BEGIN {
    eval { require Google::Api::FieldBehavior };
    eval { require Google::Protobuf::Wrappers };
    my $descriptor_b64 = <<'EOF';
Cixnb29nbGUvY2xvdWQvYmlncXVlcnkvc3RvcmFnZS92MS90YWJsZS5wcm90bxIgZ29vZ2xl
LmNsb3VkLmJpZ3F1ZXJ5LnN0b3JhZ2UudjEaH2dvb2dsZS9hcGkvZmllbGRfYmVoYXZpb3Iu
cHJvdG8aHmdvb2dsZS9wcm90b2J1Zi93cmFwcGVycy5wcm90byJZCgtUYWJsZVNjaGVtYRJK
CgZmaWVsZHMYASADKAsyMi5nb29nbGUuY2xvdWQuYmlncXVlcnkuc3RvcmFnZS52MS5UYWJs
ZUZpZWxkU2NoZW1hUgZmaWVsZHMixAgKEFRhYmxlRmllbGRTY2hlbWESFwoEbmFtZRgBIAEo
CUID4EECUgRuYW1lElAKBHR5cGUYAiABKA4yNy5nb29nbGUuY2xvdWQuYmlncXVlcnkuc3Rv
cmFnZS52MS5UYWJsZUZpZWxkU2NoZW1hLlR5cGVCA+BBAlIEdHlwZRJQCgRtb2RlGAMgASgO
MjcuZ29vZ2xlLmNsb3VkLmJpZ3F1ZXJ5LnN0b3JhZ2UudjEuVGFibGVGaWVsZFNjaGVtYS5N
b2RlQgPgQQFSBG1vZGUSTwoGZmllbGRzGAQgAygLMjIuZ29vZ2xlLmNsb3VkLmJpZ3F1ZXJ5
LnN0b3JhZ2UudjEuVGFibGVGaWVsZFNjaGVtYUID4EEBUgZmaWVsZHMSJQoLZGVzY3JpcHRp
b24YBiABKAlCA+BBAVILZGVzY3JpcHRpb24SIgoKbWF4X2xlbmd0aBgHIAEoA0ID4EEBUglt
YXhMZW5ndGgSIQoJcHJlY2lzaW9uGAggASgDQgPgQQFSCXByZWNpc2lvbhIZCgVzY2FsZRgJ
IAEoA0ID4EEBUgVzY2FsZRI9ChhkZWZhdWx0X3ZhbHVlX2V4cHJlc3Npb24YCiABKAlCA+BB
AVIWZGVmYXVsdFZhbHVlRXhwcmVzc2lvbhJRChN0aW1lc3RhbXBfcHJlY2lzaW9uGBsgASgL
MhsuZ29vZ2xlLnByb3RvYnVmLkludDY0VmFsdWVCA+BBAVISdGltZXN0YW1wUHJlY2lzaW9u
EnYKEnJhbmdlX2VsZW1lbnRfdHlwZRgLIAEoCzJDLmdvb2dsZS5jbG91ZC5iaWdxdWVyeS5z
dG9yYWdlLnYxLlRhYmxlRmllbGRTY2hlbWEuRmllbGRFbGVtZW50VHlwZUID4EEBUhByYW5n
ZUVsZW1lbnRUeXBlGmQKEEZpZWxkRWxlbWVudFR5cGUSUAoEdHlwZRgBIAEoDjI3Lmdvb2ds
ZS5jbG91ZC5iaWdxdWVyeS5zdG9yYWdlLnYxLlRhYmxlRmllbGRTY2hlbWEuVHlwZUID4EEC
UgR0eXBlIuABCgRUeXBlEhQKEFRZUEVfVU5TUEVDSUZJRUQQABIKCgZTVFJJTkcQARIJCgVJ
TlQ2NBACEgoKBkRPVUJMRRADEgoKBlNUUlVDVBAEEgkKBUJZVEVTEAUSCAoEQk9PTBAGEg0K
CVRJTUVTVEFNUBAHEggKBERBVEUQCBIICgRUSU1FEAkSDAoIREFURVRJTUUQChINCglHRU9H
UkFQSFkQCxILCgdOVU1FUklDEAwSDgoKQklHTlVNRVJJQxANEgwKCElOVEVSVkFMEA4SCAoE
SlNPThAPEgkKBVJBTkdFEBAiRgoETW9kZRIUChBNT0RFX1VOU1BFQ0lGSUVEEAASDAoITlVM
TEFCTEUQARIMCghSRVFVSVJFRBACEgwKCFJFUEVBVEVEEANCugEKJGNvbS5nb29nbGUuY2xv
dWQuYmlncXVlcnkuc3RvcmFnZS52MUIKVGFibGVQcm90b1ABWj5jbG91ZC5nb29nbGUuY29t
L2dvL2JpZ3F1ZXJ5L3N0b3JhZ2UvYXBpdjEvc3RvcmFnZXBiO3N0b3JhZ2VwYqoCIEdvb2ds
ZS5DbG91ZC5CaWdRdWVyeS5TdG9yYWdlLlYxygIgR29vZ2xlXENsb3VkXEJpZ1F1ZXJ5XFN0
b3JhZ2VcVjFKpTMKBxIFDgDHAQEKvAQKAQwSAw4AEjKxBCBDb3B5cmlnaHQgMjAyNiBHb29n
bGUgTExDCgogTGljZW5zZWQgdW5kZXIgdGhlIEFwYWNoZSBMaWNlbnNlLCBWZXJzaW9uIDIu
MCAodGhlICJMaWNlbnNlIik7CiB5b3UgbWF5IG5vdCB1c2UgdGhpcyBmaWxlIGV4Y2VwdCBp
biBjb21wbGlhbmNlIHdpdGggdGhlIExpY2Vuc2UuCiBZb3UgbWF5IG9idGFpbiBhIGNvcHkg
b2YgdGhlIExpY2Vuc2UgYXQKCiAgICAgaHR0cDovL3d3dy5hcGFjaGUub3JnL2xpY2Vuc2Vz
L0xJQ0VOU0UtMi4wCgogVW5sZXNzIHJlcXVpcmVkIGJ5IGFwcGxpY2FibGUgbGF3IG9yIGFn
cmVlZCB0byBpbiB3cml0aW5nLCBzb2Z0d2FyZQogZGlzdHJpYnV0ZWQgdW5kZXIgdGhlIExp
Y2Vuc2UgaXMgZGlzdHJpYnV0ZWQgb24gYW4gIkFTIElTIiBCQVNJUywKIFdJVEhPVVQgV0FS
UkFOVElFUyBPUiBDT05ESVRJT05TIE9GIEFOWSBLSU5ELCBlaXRoZXIgZXhwcmVzcyBvciBp
bXBsaWVkLgogU2VlIHRoZSBMaWNlbnNlIGZvciB0aGUgc3BlY2lmaWMgbGFuZ3VhZ2UgZ292
ZXJuaW5nIHBlcm1pc3Npb25zIGFuZAogbGltaXRhdGlvbnMgdW5kZXIgdGhlIExpY2Vuc2Uu
CgoICgECEgMQACkKCQoCAwASAxIAKQoJCgIDARIDEwAoCggKAQgSAxUAPQoJCgIIJRIDFQA9
CggKAQgSAxYAVQoJCgIICxIDFgBVCggKAQgSAxcAIgoJCgIIChIDFwAiCggKAQgSAxgAKwoJ
CgIICBIDGAArCggKAQgSAxkAPQoJCgIIARIDGQA9CggKAQgSAxoAPgoJCgIIKRIDGgA+CrQB
CgIEABIEHwAiARqnASBTY2hlbWEgb2YgYSB0YWJsZS4gVGhpcyBzY2hlbWEgaXMgYSBzdWJz
ZXQgb2YKIGdvb2dsZS5jbG91ZC5iaWdxdWVyeS52Mi5UYWJsZVNjaGVtYSBjb250YWluaW5n
IGluZm9ybWF0aW9uIG5lY2Vzc2FyeSB0bwogZ2VuZXJhdGUgdmFsaWQgbWVzc2FnZSB0byB3
cml0ZSB0byBCaWdRdWVyeS4KCgoKAwQAARIDHwgTCi8KBAQAAgASAyECJxoiIERlc2NyaWJl
cyB0aGUgZmllbGRzIGluIGEgdGFibGUuCgoMCgUEAAIABBIDIQIKCgwKBQQAAgAGEgMhCxsK
DAoFBAACAAESAyEcIgoMCgUEAAIAAxIDISUmClQKAgQBEgUlAMcBARpHIFRhYmxlRmllbGRT
Y2hlbWEgZGVmaW5lcyBhIHNpbmdsZSBmaWVsZC9jb2x1bW4gd2l0aGluIGEgdGFibGUgc2No
ZW1hLgoKCgoDBAEBEgMlCBgKDAoEBAEEABIEJgJZAwoMCgUEAQQAARIDJgcLCh4KBgQBBAAC
ABIDKAQZGg8gSWxsZWdhbCB2YWx1ZQoKDgoHBAEEAAIAARIDKAQUCg4KBwQBBAACAAISAygX
GAoaCgYEAQQAAgESAysEDxoLIDY0SywgVVRGOAoKDgoHBAEEAAIBARIDKwQKCg4KBwQBBAAC
AQISAysNDgoeCgYEAQQAAgISAy4EDhoPIDY0LWJpdCBzaWduZWQKCg4KBwQBBAACAgESAy4E
CQoOCgcEAQQAAgICEgMuDA0KKwoGBAEEAAIDEgMxBA8aHCA2NC1iaXQgSUVFRSBmbG9hdGlu
ZyBwb2ludAoKDgoHBAEEAAIDARIDMQQKCg4KBwQBBAACAwISAzENDgofCgYEAQQAAgQSAzQE
DxoQIEFnZ3JlZ2F0ZSB0eXBlCgoOCgcEAQQAAgQBEgM0BAoKDgoHBAEEAAIEAhIDNA0OChwK
BgQBBAACBRIDNwQOGg0gNjRLLCBCaW5hcnkKCg4KBwQBBAACBQESAzcECQoOCgcEAQQAAgUC
EgM3DA0KGQoGBAEEAAIGEgM6BA0aCiAyLXZhbHVlZAoKDgoHBAEEAAIGARIDOgQICg4KBwQB
BAACBgISAzoLDAozCgYEAQQAAgcSAz0EEhokIDY0LWJpdCBzaWduZWQgdXNlYyBzaW5jZSBV
VEMgZXBvY2gKCg4KBwQBBAACBwESAz0EDQoOCgcEAQQAAgcCEgM9EBEKLgoGBAEEAAIIEgNA
BA0aHyBDaXZpbCBkYXRlIC0gWWVhciwgTW9udGgsIERheQoKDgoHBAEEAAIIARIDQAQICg4K
BwQBBAACCAISA0ALDApACgYEAQQAAgkSA0MEDRoxIENpdmlsIHRpbWUgLSBIb3VyLCBNaW51
dGUsIFNlY29uZCwgTWljcm9zZWNvbmRzCgoOCgcEAQQAAgkBEgNDBAgKDgoHBAEEAAIJAhID
QwsMCjkKBgQBBAACChIDRgQSGiogQ29tYmluYXRpb24gb2YgY2l2aWwgZGF0ZSBhbmQgY2l2
aWwgdGltZQoKDgoHBAEEAAIKARIDRgQMCg4KBwQBBAACCgISA0YPEQohCgYEAQQAAgsSA0kE
ExoSIEdlb2dyYXBoeSBvYmplY3QKCg4KBwQBBAACCwESA0kEDQoOCgcEAQQAAgsCEgNJEBIK
HgoGBAEEAAIMEgNMBBEaDyBOdW1lcmljIHZhbHVlCgoOCgcEAQQAAgwBEgNMBAsKDgoHBAEE
AAIMAhIDTA4QCiEKBgQBBAACDRIDTwQUGhIgQmlnTnVtZXJpYyB2YWx1ZQoKDgoHBAEEAAIN
ARIDTwQOCg4KBwQBBAACDQISA08REwoZCgYEAQQAAg4SA1IEEhoKIEludGVydmFsCgoOCgcE
AQQAAg4BEgNSBAwKDgoHBAEEAAIOAhIDUg8RCh0KBgQBBAACDxIDVQQOGg4gSlNPTiwgU3Ry
aW5nCgoOCgcEAQQAAg8BEgNVBAgKDgoHBAEEAAIPAhIDVQsNChYKBgQBBAACEBIDWAQPGgcg
UkFOR0UKCg4KBwQBBAACEAESA1gECQoOCgcEAQQAAhACEgNYDA4KDAoEBAEEARIEWwJkAwoM
CgUEAQQBARIDWwcLCh4KBgQBBAECABIDXQQZGg8gSWxsZWdhbCB2YWx1ZQoKDgoHBAEEAQIA
ARIDXQQUCg4KBwQBBAECAAISA10XGAoNCgYEAQQBAgESA18EEQoOCgcEAQQBAgEBEgNfBAwK
DgoHBAEEAQIBAhIDXw8QCg0KBgQBBAECAhIDYQQRCg4KBwQBBAECAgESA2EEDAoOCgcEAQQB
AgICEgNhDxAKDQoGBAEEAQIDEgNjBBEKDgoHBAEEAQIDARIDYwQMCg4KBwQBBAECAwISA2MP
EAo3CgQEAQMAEgRnAmoDGikgUmVwcmVzZW50cyB0aGUgdHlwZSBvZiBhIGZpZWxkIGVsZW1l
bnQuCgoMCgUEAQMAARIDZwoaCjcKBgQBAwACABIDaQQ7GiggUmVxdWlyZWQuIFRoZSB0eXBl
IG9mIGEgZmllbGQgZWxlbWVudC4KCg4KBwQBAwACAAYSA2kECAoOCgcEAQMAAgABEgNpCQ0K
DgoHBAEDAAIAAxIDaRARCg4KBwQBAwACAAgSA2kSOgoRCgoEAQMAAgAInAgAEgNpEzkKzwEK
BAQBAgASA28COxrBASBSZXF1aXJlZC4gVGhlIGZpZWxkIG5hbWUuIFRoZSBuYW1lIG11c3Qg
Y29udGFpbiBvbmx5IGxldHRlcnMgKGEteiwgQS1aKSwKIG51bWJlcnMgKDAtOSksIG9yIHVu
ZGVyc2NvcmVzIChfKSwgYW5kIG11c3Qgc3RhcnQgd2l0aCBhIGxldHRlciBvcgogdW5kZXJz
Y29yZS4gVGhlIG1heGltdW0gbGVuZ3RoIGlzIDEyOCBjaGFyYWN0ZXJzLgoKDAoFBAECAAUS
A28CCAoMCgUEAQIAARIDbwkNCgwKBQQBAgADEgNvEBEKDAoFBAECAAgSA28SOgoPCggEAQIA
CJwIABIDbxM5Ci0KBAQBAgESA3ICORogIFJlcXVpcmVkLiBUaGUgZmllbGQgZGF0YSB0eXBl
LgoKDAoFBAECAQYSA3ICBgoMCgUEAQIBARIDcgcLCgwKBQQBAgEDEgNyDg8KDAoFBAECAQgS
A3IQOAoPCggEAQIBCJwIABIDchE3CkcKBAQBAgISA3UCORo6IE9wdGlvbmFsLiBUaGUgZmll
bGQgbW9kZS4gVGhlIGRlZmF1bHQgdmFsdWUgaXMgTlVMTEFCTEUuCgoMCgUEAQICBhIDdQIG
CgwKBQQBAgIBEgN1BwsKDAoFBAECAgMSA3UODwoMCgUEAQICCBIDdRA4Cg8KCAQBAgIInAgA
EgN1ETcKYwoEBAECAxIDeQJQGlYgT3B0aW9uYWwuIERlc2NyaWJlcyB0aGUgbmVzdGVkIHNj
aGVtYSBmaWVsZHMgaWYgdGhlIHR5cGUgcHJvcGVydHkgaXMgc2V0IHRvCiBTVFJVQ1QuCgoM
CgUEAQIDBBIDeQIKCgwKBQQBAgMGEgN5CxsKDAoFBAECAwESA3kcIgoMCgUEAQIDAxIDeSUm
CgwKBQQBAgMIEgN5J08KDwoIBAECAwicCAASA3koTgpXCgQEAQIEEgN8AkIaSiBPcHRpb25h
bC4gVGhlIGZpZWxkIGRlc2NyaXB0aW9uLiBUaGUgbWF4aW11bSBsZW5ndGggaXMgMSwwMjQg
Y2hhcmFjdGVycy4KCgwKBQQBAgQFEgN8AggKDAoFBAECBAESA3wJFAoMCgUEAQIEAxIDfBcY
CgwKBQQBAgQIEgN8GUEKDwoIBAECBAicCAASA3waQAq4AwoEBAECBRIEigECQBqpAyBPcHRp
b25hbC4gTWF4aW11bSBsZW5ndGggb2YgdmFsdWVzIG9mIHRoaXMgZmllbGQgZm9yIFNUUklO
R1Mgb3IgQllURVMuCgogSWYgbWF4X2xlbmd0aCBpcyBub3Qgc3BlY2lmaWVkLCBubyBtYXhp
bXVtIGxlbmd0aCBjb25zdHJhaW50IGlzIGltcG9zZWQKIG9uIHRoaXMgZmllbGQuCgogSWYg
dHlwZSA9ICJTVFJJTkciLCB0aGVuIG1heF9sZW5ndGggcmVwcmVzZW50cyB0aGUgbWF4aW11
bSBVVEYtOAogbGVuZ3RoIG9mIHN0cmluZ3MgaW4gdGhpcyBmaWVsZC4KCiBJZiB0eXBlID0g
IkJZVEVTIiwgdGhlbiBtYXhfbGVuZ3RoIHJlcHJlc2VudHMgdGhlIG1heGltdW0gbnVtYmVy
IG9mCiBieXRlcyBpbiB0aGlzIGZpZWxkLgoKIEl0IGlzIGludmFsaWQgdG8gc2V0IHRoaXMg
ZmllbGQgaWYgdHlwZSBpcyBub3QgIlNUUklORyIgb3IgIkJZVEVTIi4KCg0KBQQBAgUFEgSK
AQIHCg0KBQQBAgUBEgSKAQgSCg0KBQQBAgUDEgSKARUWCg0KBQQBAgUIEgSKARc/ChAKCAQB
AgUInAgAEgSKARg+CuQJCgQEAQIGEgSsAQI/GtUJIE9wdGlvbmFsLiBQcmVjaXNpb24gKG1h
eGltdW0gbnVtYmVyIG9mIHRvdGFsIGRpZ2l0cyBpbiBiYXNlIDEwKSBhbmQgc2NhbGUKICht
YXhpbXVtIG51bWJlciBvZiBkaWdpdHMgaW4gdGhlIGZyYWN0aW9uYWwgcGFydCBpbiBiYXNl
IDEwKSBjb25zdHJhaW50cwogZm9yIHZhbHVlcyBvZiB0aGlzIGZpZWxkIGZvciBOVU1FUklD
IG9yIEJJR05VTUVSSUMuCgogSXQgaXMgaW52YWxpZCB0byBzZXQgcHJlY2lzaW9uIG9yIHNj
YWxlIGlmIHR5cGUgaXMgbm90ICJOVU1FUklDIiBvcgogIkJJR05VTUVSSUMiLgoKIElmIHBy
ZWNpc2lvbiBhbmQgc2NhbGUgYXJlIG5vdCBzcGVjaWZpZWQsIG5vIHZhbHVlIHJhbmdlIGNv
bnN0cmFpbnQgaXMKIGltcG9zZWQgb24gdGhpcyBmaWVsZCBpbnNvZmFyIGFzIHZhbHVlcyBh
cmUgcGVybWl0dGVkIGJ5IHRoZSB0eXBlLgoKIFZhbHVlcyBvZiB0aGlzIE5VTUVSSUMgb3Ig
QklHTlVNRVJJQyBmaWVsZCBtdXN0IGJlIGluIHRoaXMgcmFuZ2Ugd2hlbjoKCiAqIFByZWNp
c2lvbiAoUCkgYW5kIHNjYWxlIChTKSBhcmUgc3BlY2lmaWVkOgogICBbLTEwXihQLVMpICsg
MTBeKC1TKSwgMTBeKFAtUykgLSAxMF4oLVMpXQogKiBQcmVjaXNpb24gKFApIGlzIHNwZWNp
ZmllZCBidXQgbm90IHNjYWxlIChhbmQgdGh1cyBzY2FsZSBpcwogICBpbnRlcnByZXRlZCB0
byBiZSBlcXVhbCB0byB6ZXJvKToKICAgWy0xMF5QICsgMSwgMTBeUCAtIDFdLgoKIEFjY2Vw
dGFibGUgdmFsdWVzIGZvciBwcmVjaXNpb24gYW5kIHNjYWxlIGlmIGJvdGggYXJlIHNwZWNp
ZmllZDoKCiAqIElmIHR5cGUgPSAiTlVNRVJJQyI6CiAgIDEgPD0gcHJlY2lzaW9uIC0gc2Nh
bGUgPD0gMjkgYW5kIDAgPD0gc2NhbGUgPD0gOS4KICogSWYgdHlwZSA9ICJCSUdOVU1FUklD
IjoKICAgMSA8PSBwcmVjaXNpb24gLSBzY2FsZSA8PSAzOCBhbmQgMCA8PSBzY2FsZSA8PSAz
OC4KCiBBY2NlcHRhYmxlIHZhbHVlcyBmb3IgcHJlY2lzaW9uIGlmIG9ubHkgcHJlY2lzaW9u
IGlzIHNwZWNpZmllZCBidXQgbm90CiBzY2FsZSAoYW5kIHRodXMgc2NhbGUgaXMgaW50ZXJw
cmV0ZWQgdG8gYmUgZXF1YWwgdG8gemVybyk6CgogKiBJZiB0eXBlID0gIk5VTUVSSUMiOiAx
IDw9IHByZWNpc2lvbiA8PSAyOS4KICogSWYgdHlwZSA9ICJCSUdOVU1FUklDIjogMSA8PSBw
cmVjaXNpb24gPD0gMzguCgogSWYgc2NhbGUgaXMgc3BlY2lmaWVkIGJ1dCBub3QgcHJlY2lz
aW9uLCB0aGVuIGl0IGlzIGludmFsaWQuCgoNCgUEAQIGBRIErAECBwoNCgUEAQIGARIErAEI
EQoNCgUEAQIGAxIErAEUFQoNCgUEAQIGCBIErAEWPgoQCggEAQIGCJwIABIErAEXPQo6CgQE
AQIHEgSvAQI7GiwgT3B0aW9uYWwuIFNlZSBkb2N1bWVudGF0aW9uIGZvciBwcmVjaXNpb24u
CgoNCgUEAQIHBRIErwECBwoNCgUEAQIHARIErwEIDQoNCgUEAQIHAxIErwEQEQoNCgUEAQIH
CBIErwESOgoQCggEAQIHCJwIABIErwETOQqTAQoEBAECCBIEswECUBqEASBPcHRpb25hbC4g
QSBTUUwgZXhwcmVzc2lvbiB0byBzcGVjaWZ5IHRoZSBbZGVmYXVsdCB2YWx1ZV0KIChodHRw
czovL2Nsb3VkLmdvb2dsZS5jb20vYmlncXVlcnkvZG9jcy9kZWZhdWx0LXZhbHVlcykgZm9y
IHRoaXMgZmllbGQuCgoNCgUEAQIIBRIEswECCAoNCgUEAQIIARIEswEJIQoNCgUEAQIIAxIE
swEkJgoNCgUEAQIICBIEswEnTwoQCggEAQIICJwIABIEswEoTgqBAgoEBAECCRIGvAECvQEv
GvABIE9wdGlvbmFsLiBQcmVjaXNpb24gKG1heGltdW0gbnVtYmVyIG9mIHRvdGFsIGRpZ2l0
cyBpbiBiYXNlIDEwKSBmb3Igc2Vjb25kcwogb2YgVElNRVNUQU1QIHR5cGUuCgogUG9zc2li
bGUgdmFsdWVzIGluY2x1ZGU6CgogKiA2IChEZWZhdWx0LCBmb3IgVElNRVNUQU1QIHR5cGUg
d2l0aCBtaWNyb3NlY29uZCBwcmVjaXNpb24pCiAqIDEyIChGb3IgVElNRVNUQU1QIHR5cGUg
d2l0aCBwaWNvc2Vjb25kIHByZWNpc2lvbikKCg0KBQQBAgkGEgS8AQIcCg0KBQQBAgkBEgS8
AR0wCg0KBQQBAgkDEgS8ATM1Cg0KBQQBAgkIEgS9AQYuChAKCAQBAgkInAgAEgS9AQctCuoB
CgQEAQIKEgbFAQLGAS8a2QEgT3B0aW9uYWwuIFRoZSBzdWJ0eXBlIG9mIHRoZSBSQU5HRSwg
aWYgdGhlIHR5cGUgb2YgdGhpcyBmaWVsZCBpcyBSQU5HRS4gSWYKIHRoZSB0eXBlIGlzIFJB
TkdFLCB0aGlzIGZpZWxkIGlzIHJlcXVpcmVkLiBQb3NzaWJsZSB2YWx1ZXMgZm9yIHRoZSBm
aWVsZAogZWxlbWVudCB0eXBlIG9mIGEgUkFOR0UgaW5jbHVkZToKICogREFURQogKiBEQVRF
VElNRQogKiBUSU1FU1RBTVAKCg0KBQQBAgoGEgTFAQISCg0KBQQBAgoBEgTFARMlCg0KBQQB
AgoDEgTFASgqCg0KBQQBAgoIEgTGAQYuChAKCAQBAgoInAgAEgTGAQctYgZwcm90bzM=
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Bigquery::Storage::V1::Table::TableSchema ===
    # Fields for TableSchema
    # Field: fields Type: 11 (.google.cloud.bigquery.storage.v1.TableFieldSchema)

# === Message: Google::Cloud::Bigquery::Storage::V1::Table::TableFieldSchema ===
    # Fields for TableFieldSchema
    # Field: name Type: 9 ()
    # Field: type Type: 14 (.google.cloud.bigquery.storage.v1.TableFieldSchema.Type)
    # Field: mode Type: 14 (.google.cloud.bigquery.storage.v1.TableFieldSchema.Mode)
    # Field: fields Type: 11 (.google.cloud.bigquery.storage.v1.TableFieldSchema)
    # Field: description Type: 9 ()
    # Field: max_length Type: 3 ()
    # Field: precision Type: 3 ()
    # Field: scale Type: 3 ()
    # Field: default_value_expression Type: 9 ()
    # Field: timestamp_precision Type: 11 (.google.protobuf.Int64Value)
    # Field: range_element_type Type: 11 (.google.cloud.bigquery.storage.v1.TableFieldSchema.FieldElementType)

# Enum: TableFieldSchema::Type
our $TableFieldSchema_TYPE_UNSPECIFIED = 0;
our $TableFieldSchema_STRING = 1;
our $TableFieldSchema_INT64 = 2;
our $TableFieldSchema_DOUBLE = 3;
our $TableFieldSchema_STRUCT = 4;
our $TableFieldSchema_BYTES = 5;
our $TableFieldSchema_BOOL = 6;
our $TableFieldSchema_TIMESTAMP = 7;
our $TableFieldSchema_DATE = 8;
our $TableFieldSchema_TIME = 9;
our $TableFieldSchema_DATETIME = 10;
our $TableFieldSchema_GEOGRAPHY = 11;
our $TableFieldSchema_NUMERIC = 12;
our $TableFieldSchema_BIGNUMERIC = 13;
our $TableFieldSchema_INTERVAL = 14;
our $TableFieldSchema_JSON = 15;
our $TableFieldSchema_RANGE = 16;

# Enum: TableFieldSchema::Mode
our $TableFieldSchema_MODE_UNSPECIFIED = 0;
our $TableFieldSchema_NULLABLE = 1;
our $TableFieldSchema_REQUIRED = 2;
our $TableFieldSchema_REPEATED = 3;

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Bigquery::Storage::V1::Table - Compiled Protocol Buffers messages for google/cloud/bigquery/storage/v1/table.proto

=head1 SYNOPSIS

    use Google::Cloud::Bigquery::Storage::V1::Table;

    my $msg = Google::Cloud::Bigquery::Storage::V1::Table::TableSchema->new({
        fields => $fields,
    });

    # Read or update a field
    my $val = $msg->fields();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Bigquery::Storage::V1::Table::TableSchema->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/bigquery/storage/v1/table.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Bigquery::Storage::V1::Table::TableSchema

Schema of a table. This schema is a subset of
google.cloud.bigquery.v2.TableSchema containing information necessary to
generate valid message to write to BigQuery.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->fields() >> / C<< $msg->fields($value) >>

Type: C<Message> (L<Google::Cloud::Bigquery::Storage::V1::Table::TableFieldSchema>)

Describes the fields in a table.

=back

=head2 Google::Cloud::Bigquery::Storage::V1::Table::TableFieldSchema

TableFieldSchema defines a single field/column within a table schema.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. The field name. The name must contain only letters (a-z, A-Z),
numbers (0-9), or underscores (_), and must start with a letter or
underscore. The maximum length is 128 characters.

=item * C<< $msg->type() >> / C<< $msg->type($value) >>

Type: C<Enum> (L<Google::Cloud::Bigquery::Storage::V1::TableFieldSchema::Type>)

Required. The field data type.

=item * C<< $msg->mode() >> / C<< $msg->mode($value) >>

Type: C<Enum> (L<Google::Cloud::Bigquery::Storage::V1::TableFieldSchema::Mode>)

Optional. The field mode. The default value is NULLABLE.

=item * C<< $msg->fields() >> / C<< $msg->fields($value) >>

Type: C<Message> (L<Google::Cloud::Bigquery::Storage::V1::Table::TableFieldSchema>)

Optional. Describes the nested schema fields if the type property is set to
STRUCT.

=item * C<< $msg->description() >> / C<< $msg->description($value) >>

Type: C<String>

Optional. The field description. The maximum length is 1,024 characters.

=item * C<< $msg->max_length() >> / C<< $msg->max_length($value) >>

Type: C<Int64>

Optional. Maximum length of values of this field for STRINGS or BYTES.

If max_length is not specified, no maximum length constraint is imposed
on this field.

If type = "STRING", then max_length represents the maximum UTF-8
length of strings in this field.

If type = "BYTES", then max_length represents the maximum number of
bytes in this field.

It is invalid to set this field if type is not "STRING" or "BYTES".

=item * C<< $msg->precision() >> / C<< $msg->precision($value) >>

Type: C<Int64>

Optional. Precision (maximum number of total digits in base 10) and scale
(maximum number of digits in the fractional part in base 10) constraints
for values of this field for NUMERIC or BIGNUMERIC.

It is invalid to set precision or scale if type is not "NUMERIC" or
"BIGNUMERIC".

If precision and scale are not specified, no value range constraint is
imposed on this field insofar as values are permitted by the type.

Values of this NUMERIC or BIGNUMERIC field must be in this range when:

* Precision (P) and scale (S) are specified:
  [-10^(P-S) + 10^(-S), 10^(P-S) - 10^(-S)]
* Precision (P) is specified but not scale (and thus scale is
  interpreted to be equal to zero):
  [-10^P + 1, 10^P - 1].

Acceptable values for precision and scale if both are specified:

* If type = "NUMERIC":
  1 <= precision - scale <= 29 and 0 <= scale <= 9.
* If type = "BIGNUMERIC":
  1 <= precision - scale <= 38 and 0 <= scale <= 38.

Acceptable values for precision if only precision is specified but not
scale (and thus scale is interpreted to be equal to zero):

* If type = "NUMERIC": 1 <= precision <= 29.
* If type = "BIGNUMERIC": 1 <= precision <= 38.

If scale is specified but not precision, then it is invalid.

=item * C<< $msg->scale() >> / C<< $msg->scale($value) >>

Type: C<Int64>

Optional. See documentation for precision.

=item * C<< $msg->default_value_expression() >> / C<< $msg->default_value_expression($value) >>

Type: C<String>

Optional. A SQL expression to specify the [default value]
(https://cloud.google.com/bigquery/docs/default-values) for this field.

=item * C<< $msg->timestamp_precision() >> / C<< $msg->timestamp_precision($value) >>

Type: C<Message> (L<Google::Protobuf::Wrappers::Int64Value>)

Optional. Precision (maximum number of total digits in base 10) for seconds
of TIMESTAMP type.

Possible values include:

* 6 (Default, for TIMESTAMP type with microsecond precision)
* 12 (For TIMESTAMP type with picosecond precision)

=item * C<< $msg->range_element_type() >> / C<< $msg->range_element_type($value) >>

Type: C<Message> (L<Google::Cloud::Bigquery::Storage::V1::Table::TableFieldSchema::FieldElementType>)

Optional. The subtype of the RANGE, if the type of this field is RANGE. If
the type is RANGE, this field is required. Possible values for the field
element type of a RANGE include:
* DATE
* DATETIME
* TIMESTAMP

=back

=head3 Enum: TableFieldSchema::Type

=over 4

=item * C<TYPE_UNSPECIFIED> => C<0>

=item * C<STRING> => C<1>

=item * C<INT64> => C<2>

=item * C<DOUBLE> => C<3>

=item * C<STRUCT> => C<4>

=item * C<BYTES> => C<5>

=item * C<BOOL> => C<6>

=item * C<TIMESTAMP> => C<7>

=item * C<DATE> => C<8>

=item * C<TIME> => C<9>

=item * C<DATETIME> => C<10>

=item * C<GEOGRAPHY> => C<11>

=item * C<NUMERIC> => C<12>

=item * C<BIGNUMERIC> => C<13>

=item * C<INTERVAL> => C<14>

=item * C<JSON> => C<15>

=item * C<RANGE> => C<16>

=back

=head3 Enum: TableFieldSchema::Mode

=over 4

=item * C<MODE_UNSPECIFIED> => C<0>

=item * C<NULLABLE> => C<1>

=item * C<REQUIRED> => C<2>

=item * C<REPEATED> => C<3>

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Bigquery::Storage::V1::Table::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
