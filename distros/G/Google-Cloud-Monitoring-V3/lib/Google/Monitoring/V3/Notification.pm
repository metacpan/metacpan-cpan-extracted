package Google::Monitoring::V3::Notification;

use strict;
use warnings;

our $VERSION = '0.14';

use Protobuf::Message;
use Protobuf::DescriptorPool;
use Protobuf::Internal qw(:all);
use MIME::Base64;

BEGIN {
    eval { require Google::Api::FieldBehavior };
    eval { require Google::Api::Label };
    eval { require Google::Api::LaunchStage };
    eval { require Google::Api::Resource };
    eval { require Google::Monitoring::V3::Common };
    eval { require Google::Monitoring::V3::MutationRecord };
    eval { require Google::Protobuf::Wrappers };
    my $descriptor_b64 = <<'EOF';
Cidnb29nbGUvbW9uaXRvcmluZy92My9ub3RpZmljYXRpb24ucHJvdG8SFGdvb2dsZS5tb25p
dG9yaW5nLnYzGh9nb29nbGUvYXBpL2ZpZWxkX2JlaGF2aW9yLnByb3RvGhZnb29nbGUvYXBp
L2xhYmVsLnByb3RvGh1nb29nbGUvYXBpL2xhdW5jaF9zdGFnZS5wcm90bxoZZ29vZ2xlL2Fw
aS9yZXNvdXJjZS5wcm90bxohZ29vZ2xlL21vbml0b3JpbmcvdjMvY29tbW9uLnByb3RvGipn
b29nbGUvbW9uaXRvcmluZy92My9tdXRhdGlvbl9yZWNvcmQucHJvdG8aHmdvb2dsZS9wcm90
b2J1Zi93cmFwcGVycy5wcm90byLwBAodTm90aWZpY2F0aW9uQ2hhbm5lbERlc2NyaXB0b3IS
EgoEbmFtZRgGIAEoCVIEbmFtZRISCgR0eXBlGAEgASgJUgR0eXBlEiEKDGRpc3BsYXlfbmFt
ZRgCIAEoCVILZGlzcGxheU5hbWUSIAoLZGVzY3JpcHRpb24YAyABKAlSC2Rlc2NyaXB0aW9u
EjMKBmxhYmVscxgEIAMoCzIbLmdvb2dsZS5hcGkuTGFiZWxEZXNjcmlwdG9yUgZsYWJlbHMS
TgoPc3VwcG9ydGVkX3RpZXJzGAUgAygOMiEuZ29vZ2xlLm1vbml0b3JpbmcudjMuU2Vydmlj
ZVRpZXJCAhgBUg5zdXBwb3J0ZWRUaWVycxI6CgxsYXVuY2hfc3RhZ2UYByABKA4yFy5nb29n
bGUuYXBpLkxhdW5jaFN0YWdlUgtsYXVuY2hTdGFnZTqgAupBnAIKN21vbml0b3JpbmcuZ29v
Z2xlYXBpcy5jb20vTm90aWZpY2F0aW9uQ2hhbm5lbERlc2NyaXB0b3ISRnByb2plY3RzL3tw
cm9qZWN0fS9ub3RpZmljYXRpb25DaGFubmVsRGVzY3JpcHRvcnMve2NoYW5uZWxfZGVzY3Jp
cHRvcn0SUG9yZ2FuaXphdGlvbnMve29yZ2FuaXphdGlvbn0vbm90aWZpY2F0aW9uQ2hhbm5l
bERlc2NyaXB0b3JzL3tjaGFubmVsX2Rlc2NyaXB0b3J9EkRmb2xkZXJzL3tmb2xkZXJ9L25v
dGlmaWNhdGlvbkNoYW5uZWxEZXNjcmlwdG9ycy97Y2hhbm5lbF9kZXNjcmlwdG9yfRIBKiLL
CAoTTm90aWZpY2F0aW9uQ2hhbm5lbBISCgR0eXBlGAEgASgJUgR0eXBlEhcKBG5hbWUYBiAB
KAlCA+BBCFIEbmFtZRIhCgxkaXNwbGF5X25hbWUYAyABKAlSC2Rpc3BsYXlOYW1lEiAKC2Rl
c2NyaXB0aW9uGAQgASgJUgtkZXNjcmlwdGlvbhJNCgZsYWJlbHMYBSADKAsyNS5nb29nbGUu
bW9uaXRvcmluZy52My5Ob3RpZmljYXRpb25DaGFubmVsLkxhYmVsc0VudHJ5UgZsYWJlbHMS
WgoLdXNlcl9sYWJlbHMYCCADKAsyOS5nb29nbGUubW9uaXRvcmluZy52My5Ob3RpZmljYXRp
b25DaGFubmVsLlVzZXJMYWJlbHNFbnRyeVIKdXNlckxhYmVscxJtChN2ZXJpZmljYXRpb25f
c3RhdHVzGAkgASgOMjwuZ29vZ2xlLm1vbml0b3JpbmcudjMuTm90aWZpY2F0aW9uQ2hhbm5l
bC5WZXJpZmljYXRpb25TdGF0dXNSEnZlcmlmaWNhdGlvblN0YXR1cxI0CgdlbmFibGVkGAsg
ASgLMhouZ29vZ2xlLnByb3RvYnVmLkJvb2xWYWx1ZVIHZW5hYmxlZBJNCg9jcmVhdGlvbl9y
ZWNvcmQYDCABKAsyJC5nb29nbGUubW9uaXRvcmluZy52My5NdXRhdGlvblJlY29yZFIOY3Jl
YXRpb25SZWNvcmQSTwoQbXV0YXRpb25fcmVjb3JkcxgNIAMoCzIkLmdvb2dsZS5tb25pdG9y
aW5nLnYzLk11dGF0aW9uUmVjb3JkUg9tdXRhdGlvblJlY29yZHMaOQoLTGFiZWxzRW50cnkS
EAoDa2V5GAEgASgJUgNrZXkSFAoFdmFsdWUYAiABKAlSBXZhbHVlOgI4ARo9Cg9Vc2VyTGFi
ZWxzRW50cnkSEAoDa2V5GAEgASgJUgNrZXkSFAoFdmFsdWUYAiABKAlSBXZhbHVlOgI4ASJX
ChJWZXJpZmljYXRpb25TdGF0dXMSIwofVkVSSUZJQ0FUSU9OX1NUQVRVU19VTlNQRUNJRklF
RBAAEg4KClVOVkVSSUZJRUQQARIMCghWRVJJRklFRBACOv4B6kH6AQotbW9uaXRvcmluZy5n
b29nbGVhcGlzLmNvbS9Ob3RpZmljYXRpb25DaGFubmVsEj5wcm9qZWN0cy97cHJvamVjdH0v
bm90aWZpY2F0aW9uQ2hhbm5lbHMve25vdGlmaWNhdGlvbl9jaGFubmVsfRJIb3JnYW5pemF0
aW9ucy97b3JnYW5pemF0aW9ufS9ub3RpZmljYXRpb25DaGFubmVscy97bm90aWZpY2F0aW9u
X2NoYW5uZWx9Ejxmb2xkZXJzL3tmb2xkZXJ9L25vdGlmaWNhdGlvbkNoYW5uZWxzL3tub3Rp
ZmljYXRpb25fY2hhbm5lbH0SASpCzAEKGGNvbS5nb29nbGUubW9uaXRvcmluZy52M0IRTm90
aWZpY2F0aW9uUHJvdG9QAVpBY2xvdWQuZ29vZ2xlLmNvbS9nby9tb25pdG9yaW5nL2FwaXYz
L3YyL21vbml0b3JpbmdwYjttb25pdG9yaW5ncGKqAhpHb29nbGUuQ2xvdWQuTW9uaXRvcmlu
Zy5WM8oCGkdvb2dsZVxDbG91ZFxNb25pdG9yaW5nXFYz6gIdR29vZ2xlOjpDbG91ZDo6TW9u
aXRvcmluZzo6VjNK3j8KBxIFDgDDAQEKvAQKAQwSAw4AEjKxBCBDb3B5cmlnaHQgMjAyNSBH
b29nbGUgTExDCgogTGljZW5zZWQgdW5kZXIgdGhlIEFwYWNoZSBMaWNlbnNlLCBWZXJzaW9u
IDIuMCAodGhlICJMaWNlbnNlIik7CiB5b3UgbWF5IG5vdCB1c2UgdGhpcyBmaWxlIGV4Y2Vw
dCBpbiBjb21wbGlhbmNlIHdpdGggdGhlIExpY2Vuc2UuCiBZb3UgbWF5IG9idGFpbiBhIGNv
cHkgb2YgdGhlIExpY2Vuc2UgYXQKCiAgICAgaHR0cDovL3d3dy5hcGFjaGUub3JnL2xpY2Vu
c2VzL0xJQ0VOU0UtMi4wCgogVW5sZXNzIHJlcXVpcmVkIGJ5IGFwcGxpY2FibGUgbGF3IG9y
IGFncmVlZCB0byBpbiB3cml0aW5nLCBzb2Z0d2FyZQogZGlzdHJpYnV0ZWQgdW5kZXIgdGhl
IExpY2Vuc2UgaXMgZGlzdHJpYnV0ZWQgb24gYW4gIkFTIElTIiBCQVNJUywKIFdJVEhPVVQg
V0FSUkFOVElFUyBPUiBDT05ESVRJT05TIE9GIEFOWSBLSU5ELCBlaXRoZXIgZXhwcmVzcyBv
ciBpbXBsaWVkLgogU2VlIHRoZSBMaWNlbnNlIGZvciB0aGUgc3BlY2lmaWMgbGFuZ3VhZ2Ug
Z292ZXJuaW5nIHBlcm1pc3Npb25zIGFuZAogbGltaXRhdGlvbnMgdW5kZXIgdGhlIExpY2Vu
c2UuCgoICgECEgMQAB0KCQoCAwASAxIAKQoJCgIDARIDEwAgCgkKAgMCEgMUACcKCQoCAwMS
AxUAIwoJCgIDBBIDFgArCgkKAgMFEgMXADQKCQoCAwYSAxgAKAoICgEIEgMaADcKCQoCCCUS
AxoANwoICgEIEgMbAFgKCQoCCAsSAxsAWAoICgEIEgMcACIKCQoCCAoSAxwAIgoICgEIEgMd
ADIKCQoCCAgSAx0AMgoICgEIEgMeADEKCQoCCAESAx4AMQoICgEIEgMfADcKCQoCCCkSAx8A
NwoICgEIEgMgADYKCQoCCC0SAyAANgrNAQoCBAASBCUAUAEawAEgQSBkZXNjcmlwdGlvbiBv
ZiBhIG5vdGlmaWNhdGlvbiBjaGFubmVsLiBUaGUgZGVzY3JpcHRvciBpbmNsdWRlcwogdGhl
IHByb3BlcnRpZXMgb2YgdGhlIGNoYW5uZWwgYW5kIHRoZSBzZXQgb2YgbGFiZWxzIG9yIGZp
ZWxkcyB0aGF0CiBtdXN0IGJlIHNwZWNpZmllZCB0byBjb25maWd1cmUgY2hhbm5lbHMgb2Yg
YSBnaXZlbiB0eXBlLgoKCgoDBAABEgMlCCUKCwoDBAAHEgQmAiwECg0KBQQAB50IEgQmAiwE
CtYBCgQEAAIAEgMzAhIayAEgVGhlIGZ1bGwgUkVTVCByZXNvdXJjZSBuYW1lIGZvciB0aGlz
IGRlc2NyaXB0b3IuIFRoZSBmb3JtYXQgaXM6CgogICAgIHByb2plY3RzL1tQUk9KRUNUX0lE
X09SX05VTUJFUl0vbm90aWZpY2F0aW9uQ2hhbm5lbERlc2NyaXB0b3JzL1tUWVBFXQoKIElu
IHRoZSBhYm92ZSwgYFtUWVBFXWAgaXMgdGhlIHZhbHVlIG9mIHRoZSBgdHlwZWAgZmllbGQu
CgoMCgUEAAIABRIDMwIICgwKBQQAAgABEgMzCQ0KDAoFBAACAAMSAzMQEQqBAgoEBAACARID
OgISGvMBIFRoZSB0eXBlIG9mIG5vdGlmaWNhdGlvbiBjaGFubmVsLCBzdWNoIGFzICJlbWFp
bCIgYW5kICJzbXMiLiBUbyB2aWV3IHRoZQogZnVsbCBsaXN0IG9mIGNoYW5uZWxzLCBzZWUK
IFtDaGFubmVsCiBkZXNjcmlwdG9yc10oaHR0cHM6Ly9jbG91ZC5nb29nbGUuY29tL21vbml0
b3JpbmcvYWxlcnRzL3VzaW5nLWNoYW5uZWxzLWFwaSNuY2QpLgogTm90aWZpY2F0aW9uIGNo
YW5uZWwgdHlwZXMgYXJlIGdsb2JhbGx5IHVuaXF1ZS4KCgwKBQQAAgEFEgM6AggKDAoFBAAC
AQESAzoJDQoMCgUEAAIBAxIDOhARCoEBCgQEAAICEgM+AhoadCBBIGh1bWFuLXJlYWRhYmxl
IG5hbWUgZm9yIHRoZSBub3RpZmljYXRpb24gY2hhbm5lbCB0eXBlLiAgVGhpcwogZm9ybSBv
ZiB0aGUgbmFtZSBpcyBzdWl0YWJsZSBmb3IgYSB1c2VyIGludGVyZmFjZS4KCgwKBQQAAgIF
EgM+AggKDAoFBAACAgESAz4JFQoMCgUEAAICAxIDPhgZCsMBCgQEAAIDEgNDAhkatQEgQSBo
dW1hbi1yZWFkYWJsZSBkZXNjcmlwdGlvbiBvZiB0aGUgbm90aWZpY2F0aW9uIGNoYW5uZWwK
IHR5cGUuIFRoZSBkZXNjcmlwdGlvbiBtYXkgaW5jbHVkZSBhIGRlc2NyaXB0aW9uIG9mIHRo
ZSBwcm9wZXJ0aWVzCiBvZiB0aGUgY2hhbm5lbCBhbmQgcG9pbnRlcnMgdG8gZXh0ZXJuYWwg
ZG9jdW1lbnRhdGlvbi4KCgwKBQQAAgMFEgNDAggKDAoFBAACAwESA0MJFAoMCgUEAAIDAxID
QxcYCr4BCgQEAAIEEgNIAjEasAEgVGhlIHNldCBvZiBsYWJlbHMgdGhhdCBtdXN0IGJlIGRl
ZmluZWQgdG8gaWRlbnRpZnkgYSBwYXJ0aWN1bGFyCiBjaGFubmVsIG9mIHRoZSBjb3JyZXNw
b25kaW5nIHR5cGUuIEVhY2ggbGFiZWwgaW5jbHVkZXMgYQogZGVzY3JpcHRpb24gZm9yIGhv
dyB0aGF0IGZpZWxkIHNob3VsZCBiZSBwb3B1bGF0ZWQuCgoMCgUEAAIEBBIDSAIKCgwKBQQA
AgQGEgNICyUKDAoFBAACBAESA0gmLAoMCgUEAAIEAxIDSC8wCn4KBAQAAgUSA0wCPxpxIFRo
ZSB0aWVycyB0aGF0IHN1cHBvcnQgdGhpcyBub3RpZmljYXRpb24gY2hhbm5lbDsgdGhlIHBy
b2plY3Qgc2VydmljZSB0aWVyCiBtdXN0IGJlIG9uZSBvZiB0aGUgc3VwcG9ydGVkX3RpZXJz
LgoKDAoFBAACBQQSA0wCCgoMCgUEAAIFBhIDTAsWCgwKBQQAAgUBEgNMFyYKDAoFBAACBQMS
A0wpKgoMCgUEAAIFCBIDTCs+Cg0KBgQAAgUIAxIDTCw9CkIKBAQAAgYSA08CKho1IFRoZSBw
cm9kdWN0IGxhdW5jaCBzdGFnZSBmb3IgY2hhbm5lbHMgb2YgdGhpcyB0eXBlLgoKDAoFBAAC
BgYSA08CGAoMCgUEAAIGARIDTxklCgwKBQQAAgYDEgNPKCkKzwIKAgQBEgVXAMMBARrBAiBB
IGBOb3RpZmljYXRpb25DaGFubmVsYCBpcyBhIG1lZGl1bSB0aHJvdWdoIHdoaWNoIGFuIGFs
ZXJ0IGlzCiBkZWxpdmVyZWQgd2hlbiBhIHBvbGljeSB2aW9sYXRpb24gaXMgZGV0ZWN0ZWQu
IEV4YW1wbGVzIG9mIGNoYW5uZWxzCiBpbmNsdWRlIGVtYWlsLCBTTVMsIGFuZCB0aGlyZC1w
YXJ0eSBtZXNzYWdpbmcgYXBwbGljYXRpb25zLiBGaWVsZHMKIGNvbnRhaW5pbmcgc2Vuc2l0
aXZlIGluZm9ybWF0aW9uIGxpa2UgYXV0aGVudGljYXRpb24gdG9rZW5zIG9yCiBjb250YWN0
IGluZm8gYXJlIG9ubHkgcGFydGlhbGx5IHBvcHVsYXRlZCBvbiByZXRyaWV2YWwuCgoKCgME
AQESA1cIGwoLCgMEAQcSBFgCXgQKDQoFBAEHnQgSBFgCXgQK2QIKBAQBBAASBGYCdgMaygIg
SW5kaWNhdGVzIHdoZXRoZXIgdGhlIGNoYW5uZWwgaGFzIGJlZW4gdmVyaWZpZWQgb3Igbm90
LiBJdCBpcyBpbGxlZ2FsCiB0byBzcGVjaWZ5IHRoaXMgZmllbGQgaW4gYQogW2BDcmVhdGVO
b3RpZmljYXRpb25DaGFubmVsYF1bZ29vZ2xlLm1vbml0b3JpbmcudjMuTm90aWZpY2F0aW9u
Q2hhbm5lbFNlcnZpY2UuQ3JlYXRlTm90aWZpY2F0aW9uQ2hhbm5lbF0KIG9yIGFuCiBbYFVw
ZGF0ZU5vdGlmaWNhdGlvbkNoYW5uZWxgXVtnb29nbGUubW9uaXRvcmluZy52My5Ob3RpZmlj
YXRpb25DaGFubmVsU2VydmljZS5VcGRhdGVOb3RpZmljYXRpb25DaGFubmVsXQogb3BlcmF0
aW9uLgoKDAoFBAEEAAESA2YHGQrNAQoGBAEEAAIAEgNqBCgavQEgU2VudGluZWwgdmFsdWUg
dXNlZCB0byBpbmRpY2F0ZSB0aGF0IHRoZSBzdGF0ZSBpcyB1bmtub3duLCBvbWl0dGVkLCBv
cgogaXMgbm90IGFwcGxpY2FibGUgKGFzIGluIHRoZSBjYXNlIG9mIGNoYW5uZWxzIHRoYXQg
bmVpdGhlciBzdXBwb3J0CiBub3IgcmVxdWlyZSB2ZXJpZmljYXRpb24gaW4gb3JkZXIgdG8g
ZnVuY3Rpb24pLgoKDgoHBAEEAAIAARIDagQjCg4KBwQBBAACAAISA2omJwqtAgoGBAEEAAIB
EgNwBBManQIgVGhlIGNoYW5uZWwgaGFzIHlldCB0byBiZSB2ZXJpZmllZCBhbmQgcmVxdWly
ZXMgdmVyaWZpY2F0aW9uIHRvIGZ1bmN0aW9uLgogTm90ZSB0aGF0IHRoaXMgc3RhdGUgYWxz
byBhcHBsaWVzIHRvIHRoZSBjYXNlIHdoZXJlIHRoZSB2ZXJpZmljYXRpb24KIHByb2Nlc3Mg
aGFzIGJlZW4gaW5pdGlhdGVkIGJ5IHNlbmRpbmcgYSB2ZXJpZmljYXRpb24gY29kZSBidXQg
d2hlcmUKIHRoZSB2ZXJpZmljYXRpb24gY29kZSBoYXMgbm90IGJlZW4gc3VibWl0dGVkIHRv
IGNvbXBsZXRlIHRoZSBwcm9jZXNzLgoKDgoHBAEEAAIBARIDcAQOCg4KBwQBBAACAQISA3AR
EgrBAQoGBAEEAAICEgN1BBEasQEgSXQgaGFzIGJlZW4gcHJvdmVuIHRoYXQgbm90aWZpY2F0
aW9ucyBjYW4gYmUgcmVjZWl2ZWQgb24gdGhpcwogbm90aWZpY2F0aW9uIGNoYW5uZWwgYW5k
IHRoYXQgc29tZW9uZSBvbiB0aGUgcHJvamVjdCBoYXMgYWNjZXNzCiB0byBtZXNzYWdlcyB0
aGF0IGFyZSBkZWxpdmVyZWQgdG8gdGhhdCBjaGFubmVsLgoKDgoHBAEEAAICARIDdQQMCg4K
BwQBBAACAgISA3UPEArBAQoEBAECABIDfAISGrMBIFRoZSB0eXBlIG9mIHRoZSBub3RpZmlj
YXRpb24gY2hhbm5lbC4gVGhpcyBmaWVsZCBtYXRjaGVzIHRoZQogdmFsdWUgb2YgdGhlCiBb
Tm90aWZpY2F0aW9uQ2hhbm5lbERlc2NyaXB0b3IudHlwZV1bZ29vZ2xlLm1vbml0b3Jpbmcu
djMuTm90aWZpY2F0aW9uQ2hhbm5lbERlc2NyaXB0b3IudHlwZV0KIGZpZWxkLgoKDAoFBAEC
AAUSA3wCCAoMCgUEAQIAARIDfAkNCgwKBQQBAgADEgN8EBEK6wEKBAQBAgESBIMBAj0a3AEg
SWRlbnRpZmllci4gVGhlIGZ1bGwgUkVTVCByZXNvdXJjZSBuYW1lIGZvciB0aGlzIGNoYW5u
ZWwuIFRoZSBmb3JtYXQgaXM6CgogICAgIHByb2plY3RzL1tQUk9KRUNUX0lEX09SX05VTUJF
Ul0vbm90aWZpY2F0aW9uQ2hhbm5lbHMvW0NIQU5ORUxfSURdCgogVGhlIGBbQ0hBTk5FTF9J
RF1gIGlzIGF1dG9tYXRpY2FsbHkgYXNzaWduZWQgYnkgdGhlIHNlcnZlciBvbiBjcmVhdGlv
bi4KCg0KBQQBAgEFEgSDAQIICg0KBQQBAgEBEgSDAQkNCg0KBQQBAgEDEgSDARARCg0KBQQB
AgEIEgSDARI8ChAKCAQBAgEInAgAEgSDARM7CqoCCgQEAQICEgSJAQIaGpsCIEFuIG9wdGlv
bmFsIGh1bWFuLXJlYWRhYmxlIG5hbWUgZm9yIHRoaXMgbm90aWZpY2F0aW9uIGNoYW5uZWwu
IEl0IGlzCiByZWNvbW1lbmRlZCB0aGF0IHlvdSBzcGVjaWZ5IGEgbm9uLWVtcHR5IGFuZCB1
bmlxdWUgbmFtZSBpbiBvcmRlciB0bwogbWFrZSBpdCBlYXNpZXIgdG8gaWRlbnRpZnkgdGhl
IGNoYW5uZWxzIGluIHlvdXIgcHJvamVjdCwgdGhvdWdoIHRoaXMgaXMKIG5vdCBlbmZvcmNl
ZC4gVGhlIGRpc3BsYXkgbmFtZSBpcyBsaW1pdGVkIHRvIDUxMiBVbmljb2RlIGNoYXJhY3Rl
cnMuCgoNCgUEAQICBRIEiQECCAoNCgUEAQICARIEiQEJFQoNCgUEAQICAxIEiQEYGQrfAQoE
BAECAxIEjgECGRrQASBBbiBvcHRpb25hbCBodW1hbi1yZWFkYWJsZSBkZXNjcmlwdGlvbiBv
ZiB0aGlzIG5vdGlmaWNhdGlvbiBjaGFubmVsLiBUaGlzCiBkZXNjcmlwdGlvbiBtYXkgcHJv
dmlkZSBhZGRpdGlvbmFsIGRldGFpbHMsIGJleW9uZCB0aGUgZGlzcGxheQogbmFtZSwgZm9y
IHRoZSBjaGFubmVsLiBUaGlzIG1heSBub3QgZXhjZWVkIDEwMjQgVW5pY29kZSBjaGFyYWN0
ZXJzLgoKDQoFBAECAwUSBI4BAggKDQoFBAECAwESBI4BCRQKDQoFBAECAwMSBI4BFxgKtwIK
BAQBAgQSBJQBAiEaqAIgQ29uZmlndXJhdGlvbiBmaWVsZHMgdGhhdCBkZWZpbmUgdGhlIGNo
YW5uZWwgYW5kIGl0cyBiZWhhdmlvci4gVGhlCiBwZXJtaXNzaWJsZSBhbmQgcmVxdWlyZWQg
bGFiZWxzIGFyZSBzcGVjaWZpZWQgaW4gdGhlCiBbTm90aWZpY2F0aW9uQ2hhbm5lbERlc2Ny
aXB0b3IubGFiZWxzXVtnb29nbGUubW9uaXRvcmluZy52My5Ob3RpZmljYXRpb25DaGFubmVs
RGVzY3JpcHRvci5sYWJlbHNdCiBvZiB0aGUgYE5vdGlmaWNhdGlvbkNoYW5uZWxEZXNjcmlw
dG9yYCBjb3JyZXNwb25kaW5nIHRvIHRoZSBgdHlwZWAgZmllbGQuCgoNCgUEAQIEBhIElAEC
FQoNCgUEAQIEARIElAEWHAoNCgUEAQIEAxIElAEfIAqMBAoEBAECBRIEnwECJhr9AyBVc2Vy
LXN1cHBsaWVkIGtleS92YWx1ZSBkYXRhIHRoYXQgZG9lcyBub3QgbmVlZCB0byBjb25mb3Jt
IHRvCiB0aGUgY29ycmVzcG9uZGluZyBgTm90aWZpY2F0aW9uQ2hhbm5lbERlc2NyaXB0b3Jg
J3Mgc2NoZW1hLCB1bmxpa2UKIHRoZSBgbGFiZWxzYCBmaWVsZC4gVGhpcyBmaWVsZCBpcyBp
bnRlbmRlZCB0byBiZSB1c2VkIGZvciBvcmdhbml6aW5nCiBhbmQgaWRlbnRpZnlpbmcgdGhl
IGBOb3RpZmljYXRpb25DaGFubmVsYCBvYmplY3RzLgoKIFRoZSBmaWVsZCBjYW4gY29udGFp
biB1cCB0byA2NCBlbnRyaWVzLiBFYWNoIGtleSBhbmQgdmFsdWUgaXMgbGltaXRlZCB0bwog
NjMgVW5pY29kZSBjaGFyYWN0ZXJzIG9yIDEyOCBieXRlcywgd2hpY2hldmVyIGlzIHNtYWxs
ZXIuIExhYmVscyBhbmQKIHZhbHVlcyBjYW4gY29udGFpbiBvbmx5IGxvd2VyY2FzZSBsZXR0
ZXJzLCBudW1lcmFscywgdW5kZXJzY29yZXMsIGFuZAogZGFzaGVzLiBLZXlzIG11c3QgYmVn
aW4gd2l0aCBhIGxldHRlci4KCg0KBQQBAgUGEgSfAQIVCg0KBQQBAgUBEgSfARYhCg0KBQQB
AgUDEgSfASQlCvcICgQEAQIGEgS0AQItGugIIEluZGljYXRlcyB3aGV0aGVyIHRoaXMgY2hh
bm5lbCBoYXMgYmVlbiB2ZXJpZmllZCBvciBub3QuIE9uIGEKIFtgTGlzdE5vdGlmaWNhdGlv
bkNoYW5uZWxzYF1bZ29vZ2xlLm1vbml0b3JpbmcudjMuTm90aWZpY2F0aW9uQ2hhbm5lbFNl
cnZpY2UuTGlzdE5vdGlmaWNhdGlvbkNoYW5uZWxzXQogb3IKIFtgR2V0Tm90aWZpY2F0aW9u
Q2hhbm5lbGBdW2dvb2dsZS5tb25pdG9yaW5nLnYzLk5vdGlmaWNhdGlvbkNoYW5uZWxTZXJ2
aWNlLkdldE5vdGlmaWNhdGlvbkNoYW5uZWxdCiBvcGVyYXRpb24sIHRoaXMgZmllbGQgaXMg
ZXhwZWN0ZWQgdG8gYmUgcG9wdWxhdGVkLgoKIElmIHRoZSB2YWx1ZSBpcyBgVU5WRVJJRklF
RGAsIHRoZW4gaXQgaW5kaWNhdGVzIHRoYXQgdGhlIGNoYW5uZWwgaXMKIG5vbi1mdW5jdGlv
bmluZyAoaXQgYm90aCByZXF1aXJlcyB2ZXJpZmljYXRpb24gYW5kIGxhY2tzIHZlcmlmaWNh
dGlvbik7CiBvdGhlcndpc2UsIGl0IGlzIGFzc3VtZWQgdGhhdCB0aGUgY2hhbm5lbCB3b3Jr
cy4KCiBJZiB0aGUgY2hhbm5lbCBpcyBuZWl0aGVyIGBWRVJJRklFRGAgbm9yIGBVTlZFUklG
SUVEYCwgaXQgaW1wbGllcyB0aGF0CiB0aGUgY2hhbm5lbCBpcyBvZiBhIHR5cGUgdGhhdCBk
b2VzIG5vdCByZXF1aXJlIHZlcmlmaWNhdGlvbiBvciB0aGF0CiB0aGlzIHNwZWNpZmljIGNo
YW5uZWwgaGFzIGJlZW4gZXhlbXB0ZWQgZnJvbSB2ZXJpZmljYXRpb24gYmVjYXVzZSBpdCB3
YXMKIGNyZWF0ZWQgcHJpb3IgdG8gdmVyaWZpY2F0aW9uIGJlaW5nIHJlcXVpcmVkIGZvciBj
aGFubmVscyBvZiB0aGlzIHR5cGUuCgogVGhpcyBmaWVsZCBjYW5ub3QgYmUgbW9kaWZpZWQg
dXNpbmcgYSBzdGFuZGFyZAogW2BVcGRhdGVOb3RpZmljYXRpb25DaGFubmVsYF1bZ29vZ2xl
Lm1vbml0b3JpbmcudjMuTm90aWZpY2F0aW9uQ2hhbm5lbFNlcnZpY2UuVXBkYXRlTm90aWZp
Y2F0aW9uQ2hhbm5lbF0KIG9wZXJhdGlvbi4gVG8gY2hhbmdlIHRoZSB2YWx1ZSBvZiB0aGlz
IGZpZWxkLCB5b3UgbXVzdCBjYWxsCiBbYFZlcmlmeU5vdGlmaWNhdGlvbkNoYW5uZWxgXVtn
b29nbGUubW9uaXRvcmluZy52My5Ob3RpZmljYXRpb25DaGFubmVsU2VydmljZS5WZXJpZnlO
b3RpZmljYXRpb25DaGFubmVsXS4KCg0KBQQBAgYGEgS0AQIUCg0KBQQBAgYBEgS0ARUoCg0K
BQQBAgYDEgS0ASssCrQDCgQEAQIHEgS8AQIpGqUDIFdoZXRoZXIgbm90aWZpY2F0aW9ucyBh
cmUgZm9yd2FyZGVkIHRvIHRoZSBkZXNjcmliZWQgY2hhbm5lbC4gVGhpcyBtYWtlcwogaXQg
cG9zc2libGUgdG8gZGlzYWJsZSBkZWxpdmVyeSBvZiBub3RpZmljYXRpb25zIHRvIGEgcGFy
dGljdWxhciBjaGFubmVsCiB3aXRob3V0IHJlbW92aW5nIHRoZSBjaGFubmVsIGZyb20gYWxs
IGFsZXJ0aW5nIHBvbGljaWVzIHRoYXQgcmVmZXJlbmNlCiB0aGUgY2hhbm5lbC4gVGhpcyBp
cyBhIG1vcmUgY29udmVuaWVudCBhcHByb2FjaCB3aGVuIHRoZSBjaGFuZ2UgaXMKIHRlbXBv
cmFyeSBhbmQgeW91IHdhbnQgdG8gcmVjZWl2ZSBub3RpZmljYXRpb25zIGZyb20gdGhlIHNh
bWUgc2V0CiBvZiBhbGVydGluZyBwb2xpY2llcyBvbiB0aGUgY2hhbm5lbCBhdCBzb21lIHBv
aW50IGluIHRoZSBmdXR1cmUuCgoNCgUEAQIHBhIEvAECGwoNCgUEAQIHARIEvAEcIwoNCgUE
AQIHAxIEvAEmKAo3CgQEAQIIEgS/AQImGikgUmVjb3JkIG9mIHRoZSBjcmVhdGlvbiBvZiB0
aGlzIGNoYW5uZWwuCgoNCgUEAQIIBhIEvwECEAoNCgUEAQIIARIEvwERIAoNCgUEAQIIAxIE
vwEjJQo8CgQEAQIJEgTCAQIwGi4gUmVjb3JkcyBvZiB0aGUgbW9kaWZpY2F0aW9uIG9mIHRo
aXMgY2hhbm5lbC4KCg0KBQQBAgkEEgTCAQIKCg0KBQQBAgkGEgTCAQsZCg0KBQQBAgkBEgTC
ARoqCg0KBQQBAgkDEgTCAS0vYgZwcm90bzM=
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Monitoring::V3::Notification::NotificationChannelDescriptor ===
    # Fields for NotificationChannelDescriptor
    # Field: name Type: 9 ()
    # Field: type Type: 9 ()
    # Field: display_name Type: 9 ()
    # Field: description Type: 9 ()
    # Field: labels Type: 11 (.google.api.LabelDescriptor)
    # Field: supported_tiers Type: 14 (.google.monitoring.v3.ServiceTier)
    # Field: launch_stage Type: 14 (.google.api.LaunchStage)

# === Message: Google::Monitoring::V3::Notification::NotificationChannel ===
    # Fields for NotificationChannel
    # Field: type Type: 9 ()
    # Field: name Type: 9 ()
    # Field: display_name Type: 9 ()
    # Field: description Type: 9 ()
    # Field: labels Type: 11 (.google.monitoring.v3.NotificationChannel.LabelsEntry)
    # Field: user_labels Type: 11 (.google.monitoring.v3.NotificationChannel.UserLabelsEntry)
    # Field: verification_status Type: 14 (.google.monitoring.v3.NotificationChannel.VerificationStatus)
    # Field: enabled Type: 11 (.google.protobuf.BoolValue)
    # Field: creation_record Type: 11 (.google.monitoring.v3.MutationRecord)
    # Field: mutation_records Type: 11 (.google.monitoring.v3.MutationRecord)

# Enum: NotificationChannel::VerificationStatus
our $NotificationChannel_VERIFICATION_STATUS_UNSPECIFIED = 0;
our $NotificationChannel_UNVERIFIED = 1;
our $NotificationChannel_VERIFIED = 2;

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Monitoring::V3::Notification - Compiled Protocol Buffers messages for google/monitoring/v3/notification.proto

=head1 SYNOPSIS

    use Google::Monitoring::V3::Notification;

    my $msg = Google::Monitoring::V3::Notification::NotificationChannelDescriptor->new({
        name => $name,
        type => $type,
        display_name => $display_name,
        description => $description,
    });

    # Read or update a field
    my $val = $msg->name();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Monitoring::V3::Notification::NotificationChannelDescriptor->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/monitoring/v3/notification.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Monitoring::V3::Notification::NotificationChannelDescriptor

A description of a notification channel. The descriptor includes
the properties of the channel and the set of labels or fields that
must be specified to configure channels of a given type.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

The full REST resource name for this descriptor. The format is:

    projects/[PROJECT_ID_OR_NUMBER]/notificationChannelDescriptors/[TYPE]

In the above, `[TYPE]` is the value of the `type` field.

=item * C<< $msg->type() >> / C<< $msg->type($value) >>

Type: C<String>

The type of notification channel, such as "email" and "sms". To view the
full list of channels, see
[Channel
descriptors](https://cloud.google.com/monitoring/alerts/using-channels-api#ncd).
Notification channel types are globally unique.

=item * C<< $msg->display_name() >> / C<< $msg->display_name($value) >>

Type: C<String>

A human-readable name for the notification channel type.  This
form of the name is suitable for a user interface.

=item * C<< $msg->description() >> / C<< $msg->description($value) >>

Type: C<String>

A human-readable description of the notification channel
type. The description may include a description of the properties
of the channel and pointers to external documentation.

=item * C<< $msg->labels() >> / C<< $msg->labels($value) >>

Type: C<Message> (L<Google::Api::Label::LabelDescriptor>)

The set of labels that must be defined to identify a particular
channel of the corresponding type. Each label includes a
description for how that field should be populated.

=item * C<< $msg->supported_tiers() >> / C<< $msg->supported_tiers($value) >>

Type: C<Enum> (L<Google::Monitoring::V3::ServiceTier>)

The tiers that support this notification channel; the project service tier
must be one of the supported_tiers.

=item * C<< $msg->launch_stage() >> / C<< $msg->launch_stage($value) >>

Type: C<Enum> (L<Google::Api::LaunchStage>)

The product launch stage for channels of this type.

=back

=head2 Google::Monitoring::V3::Notification::NotificationChannel

A `NotificationChannel` is a medium through which an alert is
delivered when a policy violation is detected. Examples of channels
include email, SMS, and third-party messaging applications. Fields
containing sensitive information like authentication tokens or
contact info are only partially populated on retrieval.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->type() >> / C<< $msg->type($value) >>

Type: C<String>

The type of the notification channel. This field matches the
value of the
[NotificationChannelDescriptor.type][google.monitoring.v3.NotificationChannelDescriptor.type]
field.

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Identifier. The full REST resource name for this channel. The format is:

    projects/[PROJECT_ID_OR_NUMBER]/notificationChannels/[CHANNEL_ID]

The `[CHANNEL_ID]` is automatically assigned by the server on creation.

=item * C<< $msg->display_name() >> / C<< $msg->display_name($value) >>

Type: C<String>

An optional human-readable name for this notification channel. It is
recommended that you specify a non-empty and unique name in order to
make it easier to identify the channels in your project, though this is
not enforced. The display name is limited to 512 Unicode characters.

=item * C<< $msg->description() >> / C<< $msg->description($value) >>

Type: C<String>

An optional human-readable description of this notification channel. This
description may provide additional details, beyond the display
name, for the channel. This may not exceed 1024 Unicode characters.

=item * C<< $msg->labels() >> / C<< $msg->labels($value) >>

Type: C<Message> (L<Google::Monitoring::V3::Notification::NotificationChannel::LabelsEntry>)

Configuration fields that define the channel and its behavior. The
permissible and required labels are specified in the
[NotificationChannelDescriptor.labels][google.monitoring.v3.NotificationChannelDescriptor.labels]
of the `NotificationChannelDescriptor` corresponding to the `type` field.

=item * C<< $msg->user_labels() >> / C<< $msg->user_labels($value) >>

Type: C<Message> (L<Google::Monitoring::V3::Notification::NotificationChannel::UserLabelsEntry>)

User-supplied key/value data that does not need to conform to
the corresponding `NotificationChannelDescriptor`'s schema, unlike
the `labels` field. This field is intended to be used for organizing
and identifying the `NotificationChannel` objects.

The field can contain up to 64 entries. Each key and value is limited to
63 Unicode characters or 128 bytes, whichever is smaller. Labels and
values can contain only lowercase letters, numerals, underscores, and
dashes. Keys must begin with a letter.

=item * C<< $msg->verification_status() >> / C<< $msg->verification_status($value) >>

Type: C<Enum> (L<Google::Monitoring::V3::NotificationChannel::VerificationStatus>)

Indicates whether this channel has been verified or not. On a
[`ListNotificationChannels`][google.monitoring.v3.NotificationChannelService.ListNotificationChannels]
or
[`GetNotificationChannel`][google.monitoring.v3.NotificationChannelService.GetNotificationChannel]
operation, this field is expected to be populated.

If the value is `UNVERIFIED`, then it indicates that the channel is
non-functioning (it both requires verification and lacks verification);
otherwise, it is assumed that the channel works.

If the channel is neither `VERIFIED` nor `UNVERIFIED`, it implies that
the channel is of a type that does not require verification or that
this specific channel has been exempted from verification because it was
created prior to verification being required for channels of this type.

This field cannot be modified using a standard
[`UpdateNotificationChannel`][google.monitoring.v3.NotificationChannelService.UpdateNotificationChannel]
operation. To change the value of this field, you must call
[`VerifyNotificationChannel`][google.monitoring.v3.NotificationChannelService.VerifyNotificationChannel].

=item * C<< $msg->enabled() >> / C<< $msg->enabled($value) >>

Type: C<Message> (L<Google::Protobuf::Wrappers::BoolValue>)

Whether notifications are forwarded to the described channel. This makes
it possible to disable delivery of notifications to a particular channel
without removing the channel from all alerting policies that reference
the channel. This is a more convenient approach when the change is
temporary and you want to receive notifications from the same set
of alerting policies on the channel at some point in the future.

=item * C<< $msg->creation_record() >> / C<< $msg->creation_record($value) >>

Type: C<Message> (L<Google::Monitoring::V3::MutationRecord::MutationRecord>)

Record of the creation of this channel.

=item * C<< $msg->mutation_records() >> / C<< $msg->mutation_records($value) >>

Type: C<Message> (L<Google::Monitoring::V3::MutationRecord::MutationRecord>)

Records of the modification of this channel.

=back

=head3 Enum: NotificationChannel::VerificationStatus

=over 4

=item * C<VERIFICATION_STATUS_UNSPECIFIED> => C<0>

=item * C<UNVERIFIED> => C<1>

=item * C<VERIFIED> => C<2>

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Monitoring::V3::Notification::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
