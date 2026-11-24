package Google::Devtools::Cloudtrace::V1::Trace;

use strict;
use warnings;

our $VERSION = '0.14';

use Protobuf::Message;
use Protobuf::DescriptorPool;
use Protobuf::Internal qw(:all);
use MIME::Base64;

BEGIN {
    eval { require Google::Api::Client };
    eval { require Google::Api::FieldBehavior };
    eval { require Google::Protobuf::Empty };
    eval { require Google::Protobuf::Timestamp };
    eval { require Google::Api::Annotations };
    my $descriptor_b64 = <<'EOF';
Cilnb29nbGUvZGV2dG9vbHMvY2xvdWR0cmFjZS92MS90cmFjZS5wcm90bxIdZ29vZ2xlLmRl
dnRvb2xzLmNsb3VkdHJhY2UudjEaF2dvb2dsZS9hcGkvY2xpZW50LnByb3RvGh9nb29nbGUv
YXBpL2ZpZWxkX2JlaGF2aW9yLnByb3RvGhtnb29nbGUvcHJvdG9idWYvZW1wdHkucHJvdG8a
H2dvb2dsZS9wcm90b2J1Zi90aW1lc3RhbXAucHJvdG8aHGdvb2dsZS9hcGkvYW5ub3RhdGlv
bnMucHJvdG8igQEKBVRyYWNlEh0KCnByb2plY3RfaWQYASABKAlSCXByb2plY3RJZBIZCgh0
cmFjZV9pZBgCIAEoCVIHdHJhY2VJZBI+CgVzcGFucxgDIAMoCzIoLmdvb2dsZS5kZXZ0b29s
cy5jbG91ZHRyYWNlLnYxLlRyYWNlU3BhblIFc3BhbnMiRgoGVHJhY2VzEjwKBnRyYWNlcxgB
IAMoCzIkLmdvb2dsZS5kZXZ0b29scy5jbG91ZHRyYWNlLnYxLlRyYWNlUgZ0cmFjZXMi7AMK
CVRyYWNlU3BhbhIXCgdzcGFuX2lkGAEgASgGUgZzcGFuSWQSRQoEa2luZBgCIAEoDjIxLmdv
b2dsZS5kZXZ0b29scy5jbG91ZHRyYWNlLnYxLlRyYWNlU3Bhbi5TcGFuS2luZFIEa2luZBIS
CgRuYW1lGAMgASgJUgRuYW1lEjkKCnN0YXJ0X3RpbWUYBCABKAsyGi5nb29nbGUucHJvdG9i
dWYuVGltZXN0YW1wUglzdGFydFRpbWUSNQoIZW5kX3RpbWUYBSABKAsyGi5nb29nbGUucHJv
dG9idWYuVGltZXN0YW1wUgdlbmRUaW1lEikKDnBhcmVudF9zcGFuX2lkGAYgASgGQgPgQQFS
DHBhcmVudFNwYW5JZBJMCgZsYWJlbHMYByADKAsyNC5nb29nbGUuZGV2dG9vbHMuY2xvdWR0
cmFjZS52MS5UcmFjZVNwYW4uTGFiZWxzRW50cnlSBmxhYmVscxo5CgtMYWJlbHNFbnRyeRIQ
CgNrZXkYASABKAlSA2tleRIUCgV2YWx1ZRgCIAEoCVIFdmFsdWU6AjgBIkUKCFNwYW5LaW5k
EhkKFVNQQU5fS0lORF9VTlNQRUNJRklFRBAAEg4KClJQQ19TRVJWRVIQARIOCgpSUENfQ0xJ
RU5UEAIiywMKEUxpc3RUcmFjZXNSZXF1ZXN0EiIKCnByb2plY3RfaWQYASABKAlCA+BBAlIJ
cHJvamVjdElkElIKBHZpZXcYAiABKA4yOS5nb29nbGUuZGV2dG9vbHMuY2xvdWR0cmFjZS52
MS5MaXN0VHJhY2VzUmVxdWVzdC5WaWV3VHlwZUID4EEBUgR2aWV3EiAKCXBhZ2Vfc2l6ZRgD
IAEoBUID4EEBUghwYWdlU2l6ZRIdCgpwYWdlX3Rva2VuGAQgASgJUglwYWdlVG9rZW4SOQoK
c3RhcnRfdGltZRgFIAEoCzIaLmdvb2dsZS5wcm90b2J1Zi5UaW1lc3RhbXBSCXN0YXJ0VGlt
ZRI1CghlbmRfdGltZRgGIAEoCzIaLmdvb2dsZS5wcm90b2J1Zi5UaW1lc3RhbXBSB2VuZFRp
bWUSGwoGZmlsdGVyGAcgASgJQgPgQQFSBmZpbHRlchIeCghvcmRlcl9ieRgIIAEoCUID4EEB
UgdvcmRlckJ5Ik4KCFZpZXdUeXBlEhkKFVZJRVdfVFlQRV9VTlNQRUNJRklFRBAAEgsKB01J
TklNQUwQARIMCghST09UU1BBThACEgwKCENPTVBMRVRFEAMiegoSTGlzdFRyYWNlc1Jlc3Bv
bnNlEjwKBnRyYWNlcxgBIAMoCzIkLmdvb2dsZS5kZXZ0b29scy5jbG91ZHRyYWNlLnYxLlRy
YWNlUgZ0cmFjZXMSJgoPbmV4dF9wYWdlX3Rva2VuGAIgASgJUg1uZXh0UGFnZVRva2VuIlUK
D0dldFRyYWNlUmVxdWVzdBIiCgpwcm9qZWN0X2lkGAEgASgJQgPgQQJSCXByb2plY3RJZBIe
Cgh0cmFjZV9pZBgCIAEoCUID4EECUgd0cmFjZUlkInwKElBhdGNoVHJhY2VzUmVxdWVzdBIi
Cgpwcm9qZWN0X2lkGAEgASgJQgPgQQJSCXByb2plY3RJZBJCCgZ0cmFjZXMYAiABKAsyJS5n
b29nbGUuZGV2dG9vbHMuY2xvdWR0cmFjZS52MS5UcmFjZXNCA+BBAlIGdHJhY2VzMrUFCgxU
cmFjZVNlcnZpY2USqAEKCkxpc3RUcmFjZXMSMC5nb29nbGUuZGV2dG9vbHMuY2xvdWR0cmFj
ZS52MS5MaXN0VHJhY2VzUmVxdWVzdBoxLmdvb2dsZS5kZXZ0b29scy5jbG91ZHRyYWNlLnYx
Lkxpc3RUcmFjZXNSZXNwb25zZSI1gtPkkwIiEiAvdjEvcHJvamVjdHMve3Byb2plY3RfaWR9
L3RyYWNlc9pBCnByb2plY3RfaWQSqwEKCEdldFRyYWNlEi4uZ29vZ2xlLmRldnRvb2xzLmNs
b3VkdHJhY2UudjEuR2V0VHJhY2VSZXF1ZXN0GiQuZ29vZ2xlLmRldnRvb2xzLmNsb3VkdHJh
Y2UudjEuVHJhY2UiSYLT5JMCLRIrL3YxL3Byb2plY3RzL3twcm9qZWN0X2lkfS90cmFjZXMv
e3RyYWNlX2lkfdpBE3Byb2plY3RfaWQsdHJhY2VfaWQSngEKC1BhdGNoVHJhY2VzEjEuZ29v
Z2xlLmRldnRvb2xzLmNsb3VkdHJhY2UudjEuUGF0Y2hUcmFjZXNSZXF1ZXN0GhYuZ29vZ2xl
LnByb3RvYnVmLkVtcHR5IkSC0+STAioyIC92MS9wcm9qZWN0cy97cHJvamVjdF9pZH0vdHJh
Y2VzOgZ0cmFjZXPaQRFwcm9qZWN0X2lkLHRyYWNlcxqqAcpBGWNsb3VkdHJhY2UuZ29vZ2xl
YXBpcy5jb23SQYoBaHR0cHM6Ly93d3cuZ29vZ2xlYXBpcy5jb20vYXV0aC9jbG91ZC1wbGF0
Zm9ybSxodHRwczovL3d3dy5nb29nbGVhcGlzLmNvbS9hdXRoL3RyYWNlLmFwcGVuZCxodHRw
czovL3d3dy5nb29nbGVhcGlzLmNvbS9hdXRoL3RyYWNlLnJlYWRvbmx5Qq0BCiFjb20uZ29v
Z2xlLmRldnRvb2xzLmNsb3VkdHJhY2UudjFCClRyYWNlUHJvdG9QAVovY2xvdWQuZ29vZ2xl
LmNvbS9nby90cmFjZS9hcGl2MS90cmFjZXBiO3RyYWNlcGKqAhVHb29nbGUuQ2xvdWQuVHJh
Y2UuVjHKAhVHb29nbGVcQ2xvdWRcVHJhY2VcVjHqAhhHb29nbGU6OkNsb3VkOjpUcmFjZTo6
VjFK11gKBxIFDgCvAgEKvAQKAQwSAw4AEjKxBCBDb3B5cmlnaHQgMjAyNSBHb29nbGUgTExD
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
EgMQACYKCQoCAwASAxIAIQoJCgIDARIDEwApCgkKAgMCEgMUACUKCQoCAwMSAxUAKQoJCgID
BBIDFgAmCggKAQgSAxgAMgoJCgIIJRIDGAAyCggKAQgSAxkARgoJCgIICxIDGQBGCggKAQgS
AxoAIgoJCgIIChIDGgAiCggKAQgSAxsAKwoJCgIICBIDGwArCggKAQgSAxwAOgoJCgIIARID
HAA6CggKAQgSAx0AMgoJCgIIKRIDHQAyCggKAQgSAx4AMQoJCgIILRIDHgAxCtcCCgIGABIE
JQBIARrKAiBUaGlzIGZpbGUgZGVzY3JpYmVzIGFuIEFQSSBmb3IgY29sbGVjdGluZyBhbmQg
dmlld2luZyB0cmFjZXMgYW5kIHNwYW5zCiB3aXRoaW4gYSB0cmFjZS4gIEEgVHJhY2UgaXMg
YSBjb2xsZWN0aW9uIG9mIHNwYW5zIGNvcnJlc3BvbmRpbmcgdG8gYSBzaW5nbGUKIG9wZXJh
dGlvbiBvciBzZXQgb2Ygb3BlcmF0aW9ucyBmb3IgYW4gYXBwbGljYXRpb24uIEEgc3BhbiBp
cyBhbiBpbmRpdmlkdWFsCiB0aW1lZCBldmVudCB3aGljaCBmb3JtcyBhIG5vZGUgb2YgdGhl
IHRyYWNlIHRyZWUuIFNwYW5zIGZvciBhIHNpbmdsZSB0cmFjZQogbWF5IHNwYW4gbXVsdGlw
bGUgc2VydmljZXMuCgoKCgMGAAESAyUIFAoKCgMGAAMSAyYCQQoMCgUGAAOZCBIDJgJBCgsK
AwYAAxIEJwIqNwoNCgUGAAOaCBIEJwIqNwpXCgQGAAIAEgQtAjIDGkkgUmV0dXJucyBvZiBh
IGxpc3Qgb2YgdHJhY2VzIHRoYXQgbWF0Y2ggdGhlIHNwZWNpZmllZCBmaWx0ZXIgY29uZGl0
aW9ucy4KCgwKBQYAAgABEgMtBhAKDAoFBgACAAISAy0RIgoMCgUGAAIAAxIDLS0/Cg0KBQYA
AgAEEgQuBDAGChEKCQYAAgAEsMq8IhIELgQwBgoMCgUGAAIABBIDMQQ4Cg8KCAYAAgAEmwgA
EgMxBDgKLgoEBgACARIENQI6AxogIEdldHMgYSBzaW5nbGUgdHJhY2UgYnkgaXRzIElELgoK
DAoFBgACAQESAzUGDgoMCgUGAAIBAhIDNQ8eCgwKBQYAAgEDEgM1KS4KDQoFBgACAQQSBDYE
OAYKEQoJBgACAQSwyrwiEgQ2BDgGCgwKBQYAAgEEEgM5BEEKDwoIBgACAQSbCAASAzkEQQrq
AgoEBgACAhIEQQJHAxrbAiBTZW5kcyBuZXcgdHJhY2VzIHRvIFN0YWNrZHJpdmVyIFRyYWNl
IG9yIHVwZGF0ZXMgZXhpc3RpbmcgdHJhY2VzLiBJZiB0aGUgSUQKIG9mIGEgdHJhY2UgdGhh
dCB5b3Ugc2VuZCBtYXRjaGVzIHRoYXQgb2YgYW4gZXhpc3RpbmcgdHJhY2UsIGFueSBmaWVs
ZHMKIGluIHRoZSBleGlzdGluZyB0cmFjZSBhbmQgaXRzIHNwYW5zIGFyZSBvdmVyd3JpdHRl
biBieSB0aGUgcHJvdmlkZWQgdmFsdWVzLAogYW5kIGFueSBuZXcgZmllbGRzIHByb3ZpZGVk
IGFyZSBtZXJnZWQgd2l0aCB0aGUgZXhpc3RpbmcgdHJhY2UgZGF0YS4gSWYgdGhlCiBJRCBk
b2VzIG5vdCBtYXRjaCwgYSBuZXcgdHJhY2UgaXMgY3JlYXRlZC4KCgwKBQYAAgIBEgNBBhEK
DAoFBgACAgISA0ESJAoMCgUGAAICAxIDQS9ECg0KBQYAAgIEEgRCBEUGChEKCQYAAgIEsMq8
IhIEQgRFBgoMCgUGAAICBBIDRgQ/Cg8KCAYAAgIEmwgAEgNGBD8KwgEKAgQAEgRNAFgBGrUB
IEEgdHJhY2UgZGVzY3JpYmVzIGhvdyBsb25nIGl0IHRha2VzIGZvciBhbiBhcHBsaWNhdGlv
biB0byBwZXJmb3JtIGFuCiBvcGVyYXRpb24uIEl0IGNvbnNpc3RzIG9mIGEgc2V0IG9mIHNw
YW5zLCBlYWNoIG9mIHdoaWNoIHJlcHJlc2VudCBhIHNpbmdsZQogdGltZWQgZXZlbnQgd2l0
aGluIHRoZSBvcGVyYXRpb24uCgoKCgMEAAESA00IDQpOCgQEAAIAEgNPAhgaQSBQcm9qZWN0
IElEIG9mIHRoZSBDbG91ZCBwcm9qZWN0IHdoZXJlIHRoZSB0cmFjZSBkYXRhIGlzIHN0b3Jl
ZC4KCgwKBQQAAgAFEgNPAggKDAoFBAACAAESA08JEwoMCgUEAAIAAxIDTxYXCroBCgQEAAIB
EgNUAhYarAEgR2xvYmFsbHkgdW5pcXVlIGlkZW50aWZpZXIgZm9yIHRoZSB0cmFjZS4gVGhp
cyBpZGVudGlmaWVyIGlzIGEgMTI4LWJpdAogbnVtZXJpYyB2YWx1ZSBmb3JtYXR0ZWQgYXMg
YSAzMi1ieXRlIGhleCBzdHJpbmcuIEZvciBleGFtcGxlLAogYDM4MmQ0ZjRjNmI3YmIyZjRh
OTcyNTU5ZDkwODUwMDFkYC4KCgwKBQQAAgEFEgNUAggKDAoFBAACAQESA1QJEQoMCgUEAAIB
AxIDVBQVCjAKBAQAAgISA1cCHxojIENvbGxlY3Rpb24gb2Ygc3BhbnMgaW4gdGhlIHRyYWNl
LgoKDAoFBAACAgQSA1cCCgoMCgUEAAICBhIDVwsUCgwKBQQAAgIBEgNXFRoKDAoFBAACAgMS
A1cdHgosCgIEARIEWwBeARogIExpc3Qgb2YgbmV3IG9yIHVwZGF0ZWQgdHJhY2VzLgoKCgoD
BAEBEgNbCA4KHgoEBAECABIDXQIcGhEgTGlzdCBvZiB0cmFjZXMuCgoMCgUEAQIABBIDXQIK
CgwKBQQBAgAGEgNdCxAKDAoFBAECAAESA10RFwoMCgUEAQIAAxIDXRobCtwCCgIEAhIFZQC0
AQEazgIgQSBzcGFuIHJlcHJlc2VudHMgYSBzaW5nbGUgdGltZWQgZXZlbnQgd2l0aGluIGEg
dHJhY2UuIFNwYW5zIGNhbiBiZSBuZXN0ZWQKIGFuZCBmb3JtIGEgdHJhY2UgdHJlZS4gT2Z0
ZW4sIGEgdHJhY2UgY29udGFpbnMgYSByb290IHNwYW4gdGhhdCBkZXNjcmliZXMgdGhlCiBl
bmQtdG8tZW5kIGxhdGVuY3kgb2YgYW4gb3BlcmF0aW9uIGFuZCwgb3B0aW9uYWxseSwgb25l
IG9yIG1vcmUgc3Vic3BhbnMgZm9yCiBpdHMgc3Vib3BlcmF0aW9ucy4gU3BhbnMgZG8gbm90
IG5lZWQgdG8gYmUgY29udGlndW91cy4gVGhlcmUgbWF5IGJlIGdhcHMKIGJldHdlZW4gc3Bh
bnMgaW4gYSB0cmFjZS4KCgoKAwQCARIDZQgRCogBCgQEAgQAEgRoAnMDGnogVHlwZSBvZiBz
cGFuLiBDYW4gYmUgdXNlZCB0byBzcGVjaWZ5IGFkZGl0aW9uYWwgcmVsYXRpb25zaGlwcyBi
ZXR3ZWVuIHNwYW5zCiBpbiBhZGRpdGlvbiB0byBhIHBhcmVudC9jaGlsZCByZWxhdGlvbnNo
aXAuCgoMCgUEAgQAARIDaAcPCh0KBgQCBAACABIDagQeGg4gVW5zcGVjaWZpZWQuCgoOCgcE
AgQAAgABEgNqBBkKDgoHBAIEAAIAAhIDahwdCnAKBgQCBAACARIDbgQTGmEgSW5kaWNhdGVz
IHRoYXQgdGhlIHNwYW4gY292ZXJzIHNlcnZlci1zaWRlIGhhbmRsaW5nIG9mIGFuIFJQQyBv
ciBvdGhlcgogcmVtb3RlIG5ldHdvcmsgcmVxdWVzdC4KCg4KBwQCBAACAQESA24EDgoOCgcE
AgQAAgECEgNuERIKbwoGBAIEAAICEgNyBBMaYCBJbmRpY2F0ZXMgdGhhdCB0aGUgc3BhbiBj
b3ZlcnMgdGhlIGNsaWVudC1zaWRlIHdyYXBwZXIgYXJvdW5kIGFuIFJQQyBvcgogb3RoZXIg
cmVtb3RlIHJlcXVlc3QuCgoOCgcEAgQAAgIBEgNyBA4KDgoHBAIEAAICAhIDchESCo4BCgQE
AgIAEgN3AhYagAEgSWRlbnRpZmllciBmb3IgdGhlIHNwYW4uIE11c3QgYmUgYSA2NC1iaXQg
aW50ZWdlciBvdGhlciB0aGFuIDAgYW5kCiB1bmlxdWUgd2l0aGluIGEgdHJhY2UuIEZvciBl
eGFtcGxlLCBgMjIwNTMxMDcwMTY0MDU3MTI4NGAuCgoMCgUEAgIABRIDdwIJCgwKBQQCAgAB
EgN3ChEKDAoFBAICAAMSA3cUFQrqAQoEBAICARIDfAIUGtwBIERpc3Rpbmd1aXNoZXMgYmV0
d2VlbiBzcGFucyBnZW5lcmF0ZWQgaW4gYSBwYXJ0aWN1bGFyIGNvbnRleHQuIEZvciBleGFt
cGxlLAogdHdvIHNwYW5zIHdpdGggdGhlIHNhbWUgbmFtZSBtYXkgYmUgZGlzdGluZ3Vpc2hl
ZCB1c2luZyBgUlBDX0NMSUVOVGAKIGFuZCBgUlBDX1NFUlZFUmAgdG8gaWRlbnRpZnkgcXVl
dWVpbmcgbGF0ZW5jeSBhc3NvY2lhdGVkIHdpdGggdGhlIHNwYW4uCgoMCgUEAgIBBhIDfAIK
CgwKBQQCAgEBEgN8Cw8KDAoFBAICAQMSA3wSEwqGAwoEBAICAhIEhQECEhr3AiBOYW1lIG9m
IHRoZSBzcGFuLiBNdXN0IGJlIGxlc3MgdGhhbiAxMjggYnl0ZXMuIFRoZSBzcGFuIG5hbWUg
aXMgc2FuaXRpemVkCiBhbmQgZGlzcGxheWVkIGluIHRoZSBTdGFja2RyaXZlciBUcmFjZSB0
b29sIGluIHRoZQogR29vZ2xlIENsb3VkIFBsYXRmb3JtIENvbnNvbGUuCiBUaGUgbmFtZSBt
YXkgYmUgYSBtZXRob2QgbmFtZSBvciBzb21lIG90aGVyIHBlci1jYWxsIHNpdGUgbmFtZS4K
IEZvciB0aGUgc2FtZSBleGVjdXRhYmxlIGFuZCB0aGUgc2FtZSBjYWxsIHBvaW50LCBhIGJl
c3QgcHJhY3RpY2UgaXMKIHRvIHVzZSBhIGNvbnNpc3RlbnQgbmFtZSwgd2hpY2ggbWFrZXMg
aXQgZWFzaWVyIHRvIGNvcnJlbGF0ZQogY3Jvc3MtdHJhY2Ugc3BhbnMuCgoNCgUEAgICBRIE
hQECCAoNCgUEAgICARIEhQEJDQoNCgUEAgICAxIEhQEQEQpKCgQEAgIDEgSIAQIrGjwgU3Rh
cnQgdGltZSBvZiB0aGUgc3BhbiBpbiBuYW5vc2Vjb25kcyBmcm9tIHRoZSBVTklYIGVwb2No
LgoKDQoFBAICAwYSBIgBAhsKDQoFBAICAwESBIgBHCYKDQoFBAICAwMSBIgBKSoKSAoEBAIC
BBIEiwECKRo6IEVuZCB0aW1lIG9mIHRoZSBzcGFuIGluIG5hbm9zZWNvbmRzIGZyb20gdGhl
IFVOSVggZXBvY2guCgoNCgUEAgIEBhIEiwECGwoNCgUEAgIEARIEiwEcJAoNCgUEAgIEAxIE
iwEnKAo4CgQEAgIFEgSOAQJGGiogT3B0aW9uYWwuIElEIG9mIHRoZSBwYXJlbnQgc3Bhbiwg
aWYgYW55LgoKDQoFBAICBQUSBI4BAgkKDQoFBAICBQESBI4BChgKDQoFBAICBQMSBI4BGxwK
DQoFBAICBQgSBI4BHUUKEAoIBAICBQicCAASBI4BHkQKxQcKBAQCAgYSBLMBAiEatgcgQ29s
bGVjdGlvbiBvZiBsYWJlbHMgYXNzb2NpYXRlZCB3aXRoIHRoZSBzcGFuLiBMYWJlbCBrZXlz
IG11c3QgYmUgbGVzcyB0aGFuCiAxMjggYnl0ZXMuIExhYmVsIHZhbHVlcyBtdXN0IGJlIGxl
c3MgdGhhbiAxNiBraWxvYnl0ZXMgKDEwTUIgZm9yCiBgL3N0YWNrdHJhY2VgIHZhbHVlcyku
CgogU29tZSBwcmVkZWZpbmVkIGxhYmVsIGtleXMgZXhpc3QsIG9yIHlvdSBtYXkgY3JlYXRl
IHlvdXIgb3duLiBXaGVuIGNyZWF0aW5nCiB5b3VyIG93biwgd2UgcmVjb21tZW5kIHRoZSBm
b2xsb3dpbmcgZm9ybWF0czoKCiAqIGAvY2F0ZWdvcnkvcHJvZHVjdC9rZXlgIGZvciBhZ2Vu
dHMgb2Ygd2VsbC1rbm93biBwcm9kdWN0cyAoZS5nLgogICBgL2RiL21vbmdvZGIvcmVhZF9z
aXplYCkuCiAqIGBzaG9ydF9ob3N0L3BhdGgva2V5YCBmb3IgZG9tYWluLXNwZWNpZmljIGtl
eXMgKGUuZy4KICAgYGZvby5jb20vbXlwcm9kdWN0L2JhcmApCgogUHJlZGVmaW5lZCBsYWJl
bHMgaW5jbHVkZToKCiAqICAgYC9hZ2VudGAKICogICBgL2NvbXBvbmVudGAKICogICBgL2Vy
cm9yL21lc3NhZ2VgCiAqICAgYC9lcnJvci9uYW1lYAogKiAgIGAvaHR0cC9jbGllbnRfY2l0
eWAKICogICBgL2h0dHAvY2xpZW50X2NvdW50cnlgCiAqICAgYC9odHRwL2NsaWVudF9wcm90
b2NvbGAKICogICBgL2h0dHAvY2xpZW50X3JlZ2lvbmAKICogICBgL2h0dHAvaG9zdGAKICog
ICBgL2h0dHAvbWV0aG9kYAogKiAgIGAvaHR0cC9wYXRoYAogKiAgIGAvaHR0cC9yZWRpcmVj
dGVkX3VybGAKICogICBgL2h0dHAvcmVxdWVzdC9zaXplYAogKiAgIGAvaHR0cC9yZXNwb25z
ZS9zaXplYAogKiAgIGAvaHR0cC9yb3V0ZWAKICogICBgL2h0dHAvc3RhdHVzX2NvZGVgCiAq
ICAgYC9odHRwL3VybGAKICogICBgL2h0dHAvdXNlcl9hZ2VudGAKICogICBgL3BpZGAKICog
ICBgL3N0YWNrdHJhY2VgCiAqICAgYC90aWRgCgoNCgUEAgIGBhIEswECFQoNCgUEAgIGARIE
swEWHAoNCgUEAgIGAxIEswEfIAprCgIEAxIGuAEAkgIBGl0gVGhlIHJlcXVlc3QgbWVzc2Fn
ZSBmb3IgdGhlIGBMaXN0VHJhY2VzYCBtZXRob2QuIEFsbCBmaWVsZHMgYXJlIHJlcXVpcmVk
CiB1bmxlc3Mgc3BlY2lmaWVkLgoKCwoDBAMBEgS4AQgZCj8KBAQDBAASBroBAsoBAxovIFR5
cGUgb2YgZGF0YSByZXR1cm5lZCBmb3IgdHJhY2VzIGluIHRoZSBsaXN0LgoKDQoFBAMEAAES
BLoBBw8KNgoGBAMEAAIAEgS8AQQeGiYgRGVmYXVsdCBpcyBgTUlOSU1BTGAgaWYgdW5zcGVj
aWZpZWQuCgoPCgcEAwQAAgABEgS8AQQZCg8KBwQDBAACAAISBLwBHB0KYQoGBAMEAAIBEgTA
AQQQGlEgTWluaW1hbCB2aWV3IG9mIHRoZSB0cmFjZSByZWNvcmQgdGhhdCBjb250YWlucyBv
bmx5IHRoZSBwcm9qZWN0CiBhbmQgdHJhY2UgSURzLgoKDwoHBAMEAAIBARIEwAEECwoPCgcE
AwQAAgECEgTAAQ4PCnQKBgQDBAACAhIExAEEERpkIFJvb3Qgc3BhbiB2aWV3IG9mIHRoZSB0
cmFjZSByZWNvcmQgdGhhdCByZXR1cm5zIHRoZSByb290IHNwYW5zIGFsb25nCiB3aXRoIHRo
ZSBtaW5pbWFsIHRyYWNlIGRhdGEuCgoPCgcEAwQAAgIBEgTEAQQMCg8KBwQDBAACAgISBMQB
DxAKxAEKBgQDBAACAxIEyQEEERqzASBDb21wbGV0ZSB2aWV3IG9mIHRoZSB0cmFjZSByZWNv
cmQgdGhhdCBjb250YWlucyB0aGUgYWN0dWFsIHRyYWNlIGRhdGEuCiBUaGlzIGlzIGVxdWl2
YWxlbnQgdG8gY2FsbGluZyB0aGUgUkVTVCBgZ2V0YCBvciBSUEMgYEdldFRyYWNlYCBtZXRo
b2QKIHVzaW5nIHRoZSBJRCBvZiBlYWNoIGxpc3RlZCB0cmFjZS4KCg8KBwQDBAACAwESBMkB
BAwKDwoHBAMEAAIDAhIEyQEPEApRCgQEAwIAEgTNAQJBGkMgUmVxdWlyZWQuIElEIG9mIHRo
ZSBDbG91ZCBwcm9qZWN0IHdoZXJlIHRoZSB0cmFjZSBkYXRhIGlzIHN0b3JlZC4KCg0KBQQD
AgAFEgTNAQIICg0KBQQDAgABEgTNAQkTCg0KBQQDAgADEgTNARYXCg0KBQQDAgAIEgTNARhA
ChAKCAQDAgAInAgAEgTNARk/Cl4KBAQDAgESBNEBAj0aUCBPcHRpb25hbC4gVHlwZSBvZiBk
YXRhIHJldHVybmVkIGZvciB0cmFjZXMgaW4gdGhlIGxpc3QuIERlZmF1bHQgaXMKIGBNSU5J
TUFMYC4KCg0KBQQDAgEGEgTRAQIKCg0KBQQDAgEBEgTRAQsPCg0KBQQDAgEDEgTRARITCg0K
BQQDAgEIEgTRARQ8ChAKCAQDAgEInAgAEgTRARU7CtMBCgQEAwICEgTWAQI/GsQBIE9wdGlv
bmFsLiBNYXhpbXVtIG51bWJlciBvZiB0cmFjZXMgdG8gcmV0dXJuLiBJZiBub3Qgc3BlY2lm
aWVkIG9yIDw9IDAsIHRoZQogaW1wbGVtZW50YXRpb24gc2VsZWN0cyBhIHJlYXNvbmFibGUg
dmFsdWUuICBUaGUgaW1wbGVtZW50YXRpb24gbWF5CiByZXR1cm4gZmV3ZXIgdHJhY2VzIHRo
YW4gdGhlIHJlcXVlc3RlZCBwYWdlIHNpemUuCgoNCgUEAwICBRIE1gECBwoNCgUEAwICARIE
1gEIEQoNCgUEAwICAxIE1gEUFQoNCgUEAwICCBIE1gEWPgoQCggEAwICCJwIABIE1gEXPQqV
AQoEBAMCAxIE2gECGBqGASBUb2tlbiBpZGVudGlmeWluZyB0aGUgcGFnZSBvZiByZXN1bHRz
IHRvIHJldHVybi4gSWYgcHJvdmlkZWQsIHVzZSB0aGUKIHZhbHVlIG9mIHRoZSBgbmV4dF9w
YWdlX3Rva2VuYCBmaWVsZCBmcm9tIGEgcHJldmlvdXMgcmVxdWVzdC4KCg0KBQQDAgMFEgTa
AQIICg0KBQQDAgMBEgTaAQkTCg0KBQQDAgMDEgTaARYXCncKBAQDAgQSBN4BAisaaSBTdGFy
dCBvZiB0aGUgdGltZSBpbnRlcnZhbCAoaW5jbHVzaXZlKSBkdXJpbmcgd2hpY2ggdGhlIHRy
YWNlIGRhdGEgd2FzCiBjb2xsZWN0ZWQgZnJvbSB0aGUgYXBwbGljYXRpb24uCgoNCgUEAwIE
BhIE3gECGwoNCgUEAwIEARIE3gEcJgoNCgUEAwIEAxIE3gEpKgp1CgQEAwIFEgTiAQIpGmcg
RW5kIG9mIHRoZSB0aW1lIGludGVydmFsIChpbmNsdXNpdmUpIGR1cmluZyB3aGljaCB0aGUg
dHJhY2UgZGF0YSB3YXMKIGNvbGxlY3RlZCBmcm9tIHRoZSBhcHBsaWNhdGlvbi4KCg0KBQQD
AgUGEgTiAQIbCg0KBQQDAgUBEgTiARwkCg0KBQQDAgUDEgTiAScoCqUMCgQEAwIGEgSCAgI9
GpYMIE9wdGlvbmFsLiBBIGZpbHRlciBhZ2FpbnN0IGxhYmVscyBmb3IgdGhlIHJlcXVlc3Qu
CgogQnkgZGVmYXVsdCwgc2VhcmNoZXMgdXNlIHByZWZpeCBtYXRjaGluZy4gVG8gc3BlY2lm
eSBleGFjdCBtYXRjaCwgcHJlcGVuZAogYSBwbHVzIHN5bWJvbCAoYCtgKSB0byB0aGUgc2Vh
cmNoIHRlcm0uCiBNdWx0aXBsZSB0ZXJtcyBhcmUgQU5EZWQuIFN5bnRheDoKCiAqICAgYHJv
b3Q6TkFNRV9QUkVGSVhgIG9yIGBOQU1FX1BSRUZJWGA6IFJldHVybiB0cmFjZXMgd2hlcmUg
YW55IHJvb3QKICAgICBzcGFuIHN0YXJ0cyB3aXRoIGBOQU1FX1BSRUZJWGAuCiAqICAgYCty
b290Ok5BTUVgIG9yIGArTkFNRWA6IFJldHVybiB0cmFjZXMgd2hlcmUgYW55IHJvb3Qgc3Bh
bidzIG5hbWUgaXMKICAgICBleGFjdGx5IGBOQU1FYC4KICogICBgc3BhbjpOQU1FX1BSRUZJ
WGA6IFJldHVybiB0cmFjZXMgd2hlcmUgYW55IHNwYW4gc3RhcnRzIHdpdGgKICAgICBgTkFN
RV9QUkVGSVhgLgogKiAgIGArc3BhbjpOQU1FYDogUmV0dXJuIHRyYWNlcyB3aGVyZSBhbnkg
c3BhbidzIG5hbWUgaXMgZXhhY3RseQogICAgIGBOQU1FYC4KICogICBgbGF0ZW5jeTpEVVJB
VElPTmA6IFJldHVybiB0cmFjZXMgd2hvc2Ugb3ZlcmFsbCBsYXRlbmN5IGlzCiAgICAgZ3Jl
YXRlciBvciBlcXVhbCB0byB0aGFuIGBEVVJBVElPTmAuIEFjY2VwdGVkIHVuaXRzIGFyZSBu
YW5vc2Vjb25kcwogICAgIChgbnNgKSwgbWlsbGlzZWNvbmRzIChgbXNgKSwgYW5kIHNlY29u
ZHMgKGBzYCkuIERlZmF1bHQgaXMgYG1zYC4gRm9yCiAgICAgZXhhbXBsZSwgYGxhdGVuY3k6
MjRtc2AgcmV0dXJucyB0cmFjZXMgd2hvc2Ugb3ZlcmFsbCBsYXRlbmN5CiAgICAgaXMgZ3Jl
YXRlciB0aGFuIG9yIGVxdWFsIHRvIDI0IG1pbGxpc2Vjb25kcy4KICogICBgbGFiZWw6TEFC
RUxfS0VZYDogUmV0dXJuIGFsbCB0cmFjZXMgY29udGFpbmluZyB0aGUgc3BlY2lmaWVkCiAg
ICAgbGFiZWwga2V5IChleGFjdCBtYXRjaCwgY2FzZS1zZW5zaXRpdmUpIHJlZ2FyZGxlc3Mg
b2YgdGhlIGtleTp2YWx1ZQogICAgIHBhaXIncyB2YWx1ZSAoaW5jbHVkaW5nIGVtcHR5IHZh
bHVlcykuCiAqICAgYExBQkVMX0tFWTpWQUxVRV9QUkVGSVhgOiBSZXR1cm4gYWxsIHRyYWNl
cyBjb250YWluaW5nIHRoZSBzcGVjaWZpZWQKICAgICBsYWJlbCBrZXkgKGV4YWN0IG1hdGNo
LCBjYXNlLXNlbnNpdGl2ZSkgd2hvc2UgdmFsdWUgc3RhcnRzIHdpdGgKICAgICBgVkFMVUVf
UFJFRklYYC4gQm90aCBhIGtleSBhbmQgYSB2YWx1ZSBtdXN0IGJlIHNwZWNpZmllZC4KICog
ICBgK0xBQkVMX0tFWTpWQUxVRWA6IFJldHVybiBhbGwgdHJhY2VzIGNvbnRhaW5pbmcgYSBr
ZXk6dmFsdWUgcGFpcgogICAgIGV4YWN0bHkgbWF0Y2hpbmcgdGhlIHNwZWNpZmllZCB0ZXh0
LiBCb3RoIGEga2V5IGFuZCBhIHZhbHVlIG11c3QgYmUKICAgICBzcGVjaWZpZWQuCiAqICAg
YG1ldGhvZDpWQUxVRWA6IEVxdWl2YWxlbnQgdG8gYC9odHRwL21ldGhvZDpWQUxVRWAuCiAq
ICAgYHVybDpWQUxVRWA6IEVxdWl2YWxlbnQgdG8gYC9odHRwL3VybDpWQUxVRWAuCgoNCgUE
AwIGBRIEggICCAoNCgUEAwIGARIEggIJDwoNCgUEAwIGAxIEggISEwoNCgUEAwIGCBIEggIU
PAoQCggEAwIGCJwIABIEggIVOwrDAwoEBAMCBxIEkQICPxq0AyBPcHRpb25hbC4gRmllbGQg
dXNlZCB0byBzb3J0IHRoZSByZXR1cm5lZCB0cmFjZXMuCiBDYW4gYmUgb25lIG9mIHRoZSBm
b2xsb3dpbmc6CgogKiAgIGB0cmFjZV9pZGAKICogICBgbmFtZWAgKGBuYW1lYCBmaWVsZCBv
ZiByb290IHNwYW4gaW4gdGhlIHRyYWNlKQogKiAgIGBkdXJhdGlvbmAgKGRpZmZlcmVuY2Ug
YmV0d2VlbiBgZW5kX3RpbWVgIGFuZCBgc3RhcnRfdGltZWAgZmllbGRzIG9mCiAgICAgIHRo
ZSByb290IHNwYW4pCiAqICAgYHN0YXJ0YCAoYHN0YXJ0X3RpbWVgIGZpZWxkIG9mIHRoZSBy
b290IHNwYW4pCgogRGVzY2VuZGluZyBvcmRlciBjYW4gYmUgc3BlY2lmaWVkIGJ5IGFwcGVu
ZGluZyBgZGVzY2AgdG8gdGhlIHNvcnQgZmllbGQKIChmb3IgZXhhbXBsZSwgYG5hbWUgZGVz
Y2ApLgoKIE9ubHkgb25lIHNvcnQgZmllbGQgaXMgcGVybWl0dGVkLgoKDQoFBAMCBwUSBJEC
AggKDQoFBAMCBwESBJECCREKDQoFBAMCBwMSBJECFBUKDQoFBAMCBwgSBJECFj4KEAoIBAMC
BwicCAASBJECFz0KQQoCBAQSBpUCAJ0CARozIFRoZSByZXNwb25zZSBtZXNzYWdlIGZvciB0
aGUgYExpc3RUcmFjZXNgIG1ldGhvZC4KCgsKAwQEARIElQIIGgpJCgQEBAIAEgSXAgIcGjsg
TGlzdCBvZiB0cmFjZSByZWNvcmRzIGFzIHNwZWNpZmllZCBieSB0aGUgdmlldyBwYXJhbWV0
ZXIuCgoNCgUEBAIABBIElwICCgoNCgUEBAIABhIElwILEAoNCgUEBAIAARIElwIRFwoNCgUE
BAIAAxIElwIaGwq9AQoEBAQCARIEnAICHRquASBJZiBkZWZpbmVkLCBpbmRpY2F0ZXMgdGhh
dCB0aGVyZSBhcmUgbW9yZSB0cmFjZXMgdGhhdCBtYXRjaCB0aGUgcmVxdWVzdAogYW5kIHRo
YXQgdGhpcyB2YWx1ZSBzaG91bGQgYmUgcGFzc2VkIHRvIHRoZSBuZXh0IHJlcXVlc3QgdG8g
Y29udGludWUKIHJldHJpZXZpbmcgYWRkaXRpb25hbCB0cmFjZXMuCgoNCgUEBAIBBRIEnAIC
CAoNCgUEBAIBARIEnAIJGAoNCgUEBAIBAxIEnAIbHAo+CgIEBRIGoAIApgIBGjAgVGhlIHJl
cXVlc3QgbWVzc2FnZSBmb3IgdGhlIGBHZXRUcmFjZWAgbWV0aG9kLgoKCwoDBAUBEgSgAggX
ClEKBAQFAgASBKICAkEaQyBSZXF1aXJlZC4gSUQgb2YgdGhlIENsb3VkIHByb2plY3Qgd2hl
cmUgdGhlIHRyYWNlIGRhdGEgaXMgc3RvcmVkLgoKDQoFBAUCAAUSBKICAggKDQoFBAUCAAES
BKICCRMKDQoFBAUCAAMSBKICFhcKDQoFBAUCAAgSBKICGEAKEAoIBAUCAAicCAASBKICGT8K
NAoEBAUCARIEpQICPxomIFJlcXVpcmVkLiBJRCBvZiB0aGUgdHJhY2UgdG8gcmV0dXJuLgoK
DQoFBAUCAQUSBKUCAggKDQoFBAUCAQESBKUCCREKDQoFBAUCAQMSBKUCFBUKDQoFBAUCAQgS
BKUCFj4KEAoIBAUCAQicCAASBKUCFz0KQQoCBAYSBqkCAK8CARozIFRoZSByZXF1ZXN0IG1l
c3NhZ2UgZm9yIHRoZSBgUGF0Y2hUcmFjZXNgIG1ldGhvZC4KCgsKAwQGARIEqQIIGgpRCgQE
BgIAEgSrAgJBGkMgUmVxdWlyZWQuIElEIG9mIHRoZSBDbG91ZCBwcm9qZWN0IHdoZXJlIHRo
ZSB0cmFjZSBkYXRhIGlzIHN0b3JlZC4KCg0KBQQGAgAFEgSrAgIICg0KBQQGAgABEgSrAgkT
Cg0KBQQGAgADEgSrAhYXCg0KBQQGAgAIEgSrAhhAChAKCAQGAgAInAgAEgSrAhk/CjIKBAQG
AgESBK4CAj0aJCBSZXF1aXJlZC4gVGhlIGJvZHkgb2YgdGhlIG1lc3NhZ2UuCgoNCgUEBgIB
BhIErgICCAoNCgUEBgIBARIErgIJDwoNCgUEBgIBAxIErgISEwoNCgUEBgIBCBIErgIUPAoQ
CggEBgIBCJwIABIErgIVO2IGcHJvdG8z
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Devtools::Cloudtrace::V1::Trace::Trace ===
    # Fields for Trace
    # Field: project_id Type: 9 ()
    # Field: trace_id Type: 9 ()
    # Field: spans Type: 11 (.google.devtools.cloudtrace.v1.TraceSpan)

# === Message: Google::Devtools::Cloudtrace::V1::Trace::Traces ===
    # Fields for Traces
    # Field: traces Type: 11 (.google.devtools.cloudtrace.v1.Trace)

# === Message: Google::Devtools::Cloudtrace::V1::Trace::TraceSpan ===
    # Fields for TraceSpan
    # Field: span_id Type: 6 ()
    # Field: kind Type: 14 (.google.devtools.cloudtrace.v1.TraceSpan.SpanKind)
    # Field: name Type: 9 ()
    # Field: start_time Type: 11 (.google.protobuf.Timestamp)
    # Field: end_time Type: 11 (.google.protobuf.Timestamp)
    # Field: parent_span_id Type: 6 ()
    # Field: labels Type: 11 (.google.devtools.cloudtrace.v1.TraceSpan.LabelsEntry)

# Enum: TraceSpan::SpanKind
our $TraceSpan_SPAN_KIND_UNSPECIFIED = 0;
our $TraceSpan_RPC_SERVER = 1;
our $TraceSpan_RPC_CLIENT = 2;

# === Message: Google::Devtools::Cloudtrace::V1::Trace::ListTracesRequest ===
    # Fields for ListTracesRequest
    # Field: project_id Type: 9 ()
    # Field: view Type: 14 (.google.devtools.cloudtrace.v1.ListTracesRequest.ViewType)
    # Field: page_size Type: 5 ()
    # Field: page_token Type: 9 ()
    # Field: start_time Type: 11 (.google.protobuf.Timestamp)
    # Field: end_time Type: 11 (.google.protobuf.Timestamp)
    # Field: filter Type: 9 ()
    # Field: order_by Type: 9 ()

# Enum: ListTracesRequest::ViewType
our $ListTracesRequest_VIEW_TYPE_UNSPECIFIED = 0;
our $ListTracesRequest_MINIMAL = 1;
our $ListTracesRequest_ROOTSPAN = 2;
our $ListTracesRequest_COMPLETE = 3;

# === Message: Google::Devtools::Cloudtrace::V1::Trace::ListTracesResponse ===
    # Fields for ListTracesResponse
    # Field: traces Type: 11 (.google.devtools.cloudtrace.v1.Trace)
    # Field: next_page_token Type: 9 ()

# === Message: Google::Devtools::Cloudtrace::V1::Trace::GetTraceRequest ===
    # Fields for GetTraceRequest
    # Field: project_id Type: 9 ()
    # Field: trace_id Type: 9 ()

# === Message: Google::Devtools::Cloudtrace::V1::Trace::PatchTracesRequest ===
    # Fields for PatchTracesRequest
    # Field: project_id Type: 9 ()
    # Field: traces Type: 11 (.google.devtools.cloudtrace.v1.Traces)

# === Service Client: Google::Devtools::Cloudtrace::V1::Trace::TraceServiceClient ===
package Google::Devtools::Cloudtrace::V1::Trace::TraceServiceClient;

=pod

=head2 Service Client: Google::Devtools::Cloudtrace::V1::Trace::TraceServiceClient

Client stub representing the remote C<TraceService> gRPC service. Delegates call dispatching to L<Google::gRPC::Client>.

=head3 target

The endpoint target address. Defaults to C<devtools.googleapis.com:443>.

=head3 credentials

The authentication credentials provider. Defaults to application default credentials via L<Google::Auth>.

=cut

use Moo;
use Google::Auth;
use Google::gRPC::Client;

has credentials => ( is => 'ro', default => sub { Google::Auth->default() } );
has target      => ( is => 'ro', default => 'devtools.googleapis.com:443' );

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

sub list_traces {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Devtools::Cloudtrace::V1::Trace::ListTracesRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.devtools.cloudtrace.v1.TraceService',
        method         => 'ListTraces',
        request        => $req,
        response_class => 'Google::Devtools::Cloudtrace::V1::Trace::ListTracesResponse',
    });
}

sub get_trace {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Devtools::Cloudtrace::V1::Trace::GetTraceRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.devtools.cloudtrace.v1.TraceService',
        method         => 'GetTrace',
        request        => $req,
        response_class => 'Google::Devtools::Cloudtrace::V1::Trace::Trace',
    });
}

sub patch_traces {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Devtools::Cloudtrace::V1::Trace::PatchTracesRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.devtools.cloudtrace.v1.TraceService',
        method         => 'PatchTraces',
        request        => $req,
        response_class => 'Google::Protobuf::Empty::Empty',
    });
}

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Devtools::Cloudtrace::V1::Trace - Compiled Protocol Buffers messages for google/devtools/cloudtrace/v1/trace.proto

=head1 SYNOPSIS

    use Google::Devtools::Cloudtrace::V1::Trace;

    my $msg = Google::Devtools::Cloudtrace::V1::Trace::Trace->new({
        project_id => $project_id,
        trace_id => $trace_id,
        spans => $spans,
    });

    # Read or update a field
    my $val = $msg->project_id();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Devtools::Cloudtrace::V1::Trace::Trace->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/devtools/cloudtrace/v1/trace.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Devtools::Cloudtrace::V1::Trace::Trace

A trace describes how long it takes for an application to perform an
operation. It consists of a set of spans, each of which represent a single
timed event within the operation.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->project_id() >> / C<< $msg->project_id($value) >>

Type: C<String>

Project ID of the Cloud project where the trace data is stored.

=item * C<< $msg->trace_id() >> / C<< $msg->trace_id($value) >>

Type: C<String>

Globally unique identifier for the trace. This identifier is a 128-bit
numeric value formatted as a 32-byte hex string. For example,
`382d4f4c6b7bb2f4a972559d9085001d`.

=item * C<< $msg->spans() >> / C<< $msg->spans($value) >>

Type: C<Message> (L<Google::Devtools::Cloudtrace::V1::Trace::TraceSpan>)

Collection of spans in the trace.

=back

=head2 Google::Devtools::Cloudtrace::V1::Trace::Traces

List of new or updated traces.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->traces() >> / C<< $msg->traces($value) >>

Type: C<Message> (L<Google::Devtools::Cloudtrace::V1::Trace::Trace>)

List of traces.

=back

=head2 Google::Devtools::Cloudtrace::V1::Trace::TraceSpan

A span represents a single timed event within a trace. Spans can be nested
and form a trace tree. Often, a trace contains a root span that describes the
end-to-end latency of an operation and, optionally, one or more subspans for
its suboperations. Spans do not need to be contiguous. There may be gaps
between spans in a trace.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->span_id() >> / C<< $msg->span_id($value) >>

Type: C<Fixed64>

Identifier for the span. Must be a 64-bit integer other than 0 and
unique within a trace. For example, `2205310701640571284`.

=item * C<< $msg->kind() >> / C<< $msg->kind($value) >>

Type: C<Enum> (L<Google::Devtools::Cloudtrace::V1::TraceSpan::SpanKind>)

Distinguishes between spans generated in a particular context. For example,
two spans with the same name may be distinguished using `RPC_CLIENT`
and `RPC_SERVER` to identify queueing latency associated with the span.

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Name of the span. Must be less than 128 bytes. The span name is sanitized
and displayed in the Stackdriver Trace tool in the
Google Cloud Platform Console.
The name may be a method name or some other per-call site name.
For the same executable and the same call point, a best practice is
to use a consistent name, which makes it easier to correlate
cross-trace spans.

=item * C<< $msg->start_time() >> / C<< $msg->start_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Start time of the span in nanoseconds from the UNIX epoch.

=item * C<< $msg->end_time() >> / C<< $msg->end_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

End time of the span in nanoseconds from the UNIX epoch.

=item * C<< $msg->parent_span_id() >> / C<< $msg->parent_span_id($value) >>

Type: C<Fixed64>

Optional. ID of the parent span, if any.

=item * C<< $msg->labels() >> / C<< $msg->labels($value) >>

Type: C<Message> (L<Google::Devtools::Cloudtrace::V1::Trace::TraceSpan::LabelsEntry>)

Collection of labels associated with the span. Label keys must be less than
128 bytes. Label values must be less than 16 kilobytes (10MB for
`/stacktrace` values).

Some predefined label keys exist, or you may create your own. When creating
your own, we recommend the following formats:

* `/category/product/key` for agents of well-known products (e.g.
  `/db/mongodb/read_size`).
* `short_host/path/key` for domain-specific keys (e.g.
  `foo.com/myproduct/bar`)

Predefined labels include:

*   `/agent`
*   `/component`
*   `/error/message`
*   `/error/name`
*   `/http/client_city`
*   `/http/client_country`
*   `/http/client_protocol`
*   `/http/client_region`
*   `/http/host`
*   `/http/method`
*   `/http/path`
*   `/http/redirected_url`
*   `/http/request/size`
*   `/http/response/size`
*   `/http/route`
*   `/http/status_code`
*   `/http/url`
*   `/http/user_agent`
*   `/pid`
*   `/stacktrace`
*   `/tid`

=back

=head3 Enum: TraceSpan::SpanKind

=over 4

=item * C<SPAN_KIND_UNSPECIFIED> => C<0>

=item * C<RPC_SERVER> => C<1>

=item * C<RPC_CLIENT> => C<2>

=back

=head2 Google::Devtools::Cloudtrace::V1::Trace::ListTracesRequest

The request message for the `ListTraces` method. All fields are required
unless specified.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->project_id() >> / C<< $msg->project_id($value) >>

Type: C<String>

Required. ID of the Cloud project where the trace data is stored.

=item * C<< $msg->view() >> / C<< $msg->view($value) >>

Type: C<Enum> (L<Google::Devtools::Cloudtrace::V1::ListTracesRequest::ViewType>)

Optional. Type of data returned for traces in the list. Default is
`MINIMAL`.

=item * C<< $msg->page_size() >> / C<< $msg->page_size($value) >>

Type: C<Int32>

Optional. Maximum number of traces to return. If not specified or <= 0, the
implementation selects a reasonable value.  The implementation may
return fewer traces than the requested page size.

=item * C<< $msg->page_token() >> / C<< $msg->page_token($value) >>

Type: C<String>

Token identifying the page of results to return. If provided, use the
value of the `next_page_token` field from a previous request.

=item * C<< $msg->start_time() >> / C<< $msg->start_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Start of the time interval (inclusive) during which the trace data was
collected from the application.

=item * C<< $msg->end_time() >> / C<< $msg->end_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

End of the time interval (inclusive) during which the trace data was
collected from the application.

=item * C<< $msg->filter() >> / C<< $msg->filter($value) >>

Type: C<String>

Optional. A filter against labels for the request.

By default, searches use prefix matching. To specify exact match, prepend
a plus symbol (`+`) to the search term.
Multiple terms are ANDed. Syntax:

*   `root:NAME_PREFIX` or `NAME_PREFIX`: Return traces where any root
    span starts with `NAME_PREFIX`.
*   `+root:NAME` or `+NAME`: Return traces where any root span's name is
    exactly `NAME`.
*   `span:NAME_PREFIX`: Return traces where any span starts with
    `NAME_PREFIX`.
*   `+span:NAME`: Return traces where any span's name is exactly
    `NAME`.
*   `latency:DURATION`: Return traces whose overall latency is
    greater or equal to than `DURATION`. Accepted units are nanoseconds
    (`ns`), milliseconds (`ms`), and seconds (`s`). Default is `ms`. For
    example, `latency:24ms` returns traces whose overall latency
    is greater than or equal to 24 milliseconds.
*   `label:LABEL_KEY`: Return all traces containing the specified
    label key (exact match, case-sensitive) regardless of the key:value
    pair's value (including empty values).
*   `LABEL_KEY:VALUE_PREFIX`: Return all traces containing the specified
    label key (exact match, case-sensitive) whose value starts with
    `VALUE_PREFIX`. Both a key and a value must be specified.
*   `+LABEL_KEY:VALUE`: Return all traces containing a key:value pair
    exactly matching the specified text. Both a key and a value must be
    specified.
*   `method:VALUE`: Equivalent to `/http/method:VALUE`.
*   `url:VALUE`: Equivalent to `/http/url:VALUE`.

=item * C<< $msg->order_by() >> / C<< $msg->order_by($value) >>

Type: C<String>

Optional. Field used to sort the returned traces.
Can be one of the following:

*   `trace_id`
*   `name` (`name` field of root span in the trace)
*   `duration` (difference between `end_time` and `start_time` fields of
     the root span)
*   `start` (`start_time` field of the root span)

Descending order can be specified by appending `desc` to the sort field
(for example, `name desc`).

Only one sort field is permitted.

=back

=head3 Enum: ListTracesRequest::ViewType

=over 4

=item * C<VIEW_TYPE_UNSPECIFIED> => C<0>

=item * C<MINIMAL> => C<1>

=item * C<ROOTSPAN> => C<2>

=item * C<COMPLETE> => C<3>

=back

=head2 Google::Devtools::Cloudtrace::V1::Trace::ListTracesResponse

The response message for the `ListTraces` method.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->traces() >> / C<< $msg->traces($value) >>

Type: C<Message> (L<Google::Devtools::Cloudtrace::V1::Trace::Trace>)

List of trace records as specified by the view parameter.

=item * C<< $msg->next_page_token() >> / C<< $msg->next_page_token($value) >>

Type: C<String>

If defined, indicates that there are more traces that match the request
and that this value should be passed to the next request to continue
retrieving additional traces.

=back

=head2 Google::Devtools::Cloudtrace::V1::Trace::GetTraceRequest

The request message for the `GetTrace` method.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->project_id() >> / C<< $msg->project_id($value) >>

Type: C<String>

Required. ID of the Cloud project where the trace data is stored.

=item * C<< $msg->trace_id() >> / C<< $msg->trace_id($value) >>

Type: C<String>

Required. ID of the trace to return.

=back

=head2 Google::Devtools::Cloudtrace::V1::Trace::PatchTracesRequest

The request message for the `PatchTraces` method.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->project_id() >> / C<< $msg->project_id($value) >>

Type: C<String>

Required. ID of the Cloud project where the trace data is stored.

=item * C<< $msg->traces() >> / C<< $msg->traces($value) >>

Type: C<Message> (L<Google::Devtools::Cloudtrace::V1::Trace::Traces>)

Required. The body of the message.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Devtools::Cloudtrace::V1::Trace::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
