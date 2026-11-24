package Google::Spanner::V1::ResultSet;

use strict;
use warnings;

our $VERSION = '0.14';

use Protobuf::Message;
use Protobuf::DescriptorPool;
use Protobuf::Internal qw(:all);
use MIME::Base64;

BEGIN {
    eval { require Google::Api::FieldBehavior };
    eval { require Google::Protobuf::Struct };
    eval { require Google::Spanner::V1::Location };
    eval { require Google::Spanner::V1::QueryPlan };
    eval { require Google::Spanner::V1::Transaction };
    eval { require Google::Spanner::V1::Type };
    my $descriptor_b64 = <<'EOF';
CiJnb29nbGUvc3Bhbm5lci92MS9yZXN1bHRfc2V0LnByb3RvEhFnb29nbGUuc3Bhbm5lci52
MRofZ29vZ2xlL2FwaS9maWVsZF9iZWhhdmlvci5wcm90bxocZ29vZ2xlL3Byb3RvYnVmL3N0
cnVjdC5wcm90bxogZ29vZ2xlL3NwYW5uZXIvdjEvbG9jYXRpb24ucHJvdG8aImdvb2dsZS9z
cGFubmVyL3YxL3F1ZXJ5X3BsYW4ucHJvdG8aI2dvb2dsZS9zcGFubmVyL3YxL3RyYW5zYWN0
aW9uLnByb3RvGhxnb29nbGUvc3Bhbm5lci92MS90eXBlLnByb3RvIuECCglSZXN1bHRTZXQS
QAoIbWV0YWRhdGEYASABKAsyJC5nb29nbGUuc3Bhbm5lci52MS5SZXN1bHRTZXRNZXRhZGF0
YVIIbWV0YWRhdGESLgoEcm93cxgCIAMoCzIaLmdvb2dsZS5wcm90b2J1Zi5MaXN0VmFsdWVS
BHJvd3MSNwoFc3RhdHMYAyABKAsyIS5nb29nbGUuc3Bhbm5lci52MS5SZXN1bHRTZXRTdGF0
c1IFc3RhdHMSYQoPcHJlY29tbWl0X3Rva2VuGAUgASgLMjMuZ29vZ2xlLnNwYW5uZXIudjEu
TXVsdGlwbGV4ZWRTZXNzaW9uUHJlY29tbWl0VG9rZW5CA+BBAVIOcHJlY29tbWl0VG9rZW4S
RgoMY2FjaGVfdXBkYXRlGAYgASgLMh4uZ29vZ2xlLnNwYW5uZXIudjEuQ2FjaGVVcGRhdGVC
A+BBAVILY2FjaGVVcGRhdGUiyQMKEFBhcnRpYWxSZXN1bHRTZXQSQAoIbWV0YWRhdGEYASAB
KAsyJC5nb29nbGUuc3Bhbm5lci52MS5SZXN1bHRTZXRNZXRhZGF0YVIIbWV0YWRhdGESLgoG
dmFsdWVzGAIgAygLMhYuZ29vZ2xlLnByb3RvYnVmLlZhbHVlUgZ2YWx1ZXMSIwoNY2h1bmtl
ZF92YWx1ZRgDIAEoCFIMY2h1bmtlZFZhbHVlEiEKDHJlc3VtZV90b2tlbhgEIAEoDFILcmVz
dW1lVG9rZW4SNwoFc3RhdHMYBSABKAsyIS5nb29nbGUuc3Bhbm5lci52MS5SZXN1bHRTZXRT
dGF0c1IFc3RhdHMSYQoPcHJlY29tbWl0X3Rva2VuGAggASgLMjMuZ29vZ2xlLnNwYW5uZXIu
djEuTXVsdGlwbGV4ZWRTZXNzaW9uUHJlY29tbWl0VG9rZW5CA+BBAVIOcHJlY29tbWl0VG9r
ZW4SFwoEbGFzdBgJIAEoCEID4EEBUgRsYXN0EkYKDGNhY2hlX3VwZGF0ZRgKIAEoCzIeLmdv
b2dsZS5zcGFubmVyLnYxLkNhY2hlVXBkYXRlQgPgQQFSC2NhY2hlVXBkYXRlIuMBChFSZXN1
bHRTZXRNZXRhZGF0YRI4Cghyb3dfdHlwZRgBIAEoCzIdLmdvb2dsZS5zcGFubmVyLnYxLlN0
cnVjdFR5cGVSB3Jvd1R5cGUSQAoLdHJhbnNhY3Rpb24YAiABKAsyHi5nb29nbGUuc3Bhbm5l
ci52MS5UcmFuc2FjdGlvblILdHJhbnNhY3Rpb24SUgoVdW5kZWNsYXJlZF9wYXJhbWV0ZXJz
GAMgASgLMh0uZ29vZ2xlLnNwYW5uZXIudjEuU3RydWN0VHlwZVIUdW5kZWNsYXJlZFBhcmFt
ZXRlcnMi8wEKDlJlc3VsdFNldFN0YXRzEjsKCnF1ZXJ5X3BsYW4YASABKAsyHC5nb29nbGUu
c3Bhbm5lci52MS5RdWVyeVBsYW5SCXF1ZXJ5UGxhbhI4CgtxdWVyeV9zdGF0cxgCIAEoCzIX
Lmdvb2dsZS5wcm90b2J1Zi5TdHJ1Y3RSCnF1ZXJ5U3RhdHMSKAoPcm93X2NvdW50X2V4YWN0
GAMgASgDSABSDXJvd0NvdW50RXhhY3QSMwoVcm93X2NvdW50X2xvd2VyX2JvdW5kGAQgASgD
SABSEnJvd0NvdW50TG93ZXJCb3VuZEILCglyb3dfY291bnRCsQEKFWNvbS5nb29nbGUuc3Bh
bm5lci52MUIOUmVzdWx0U2V0UHJvdG9QAVo1Y2xvdWQuZ29vZ2xlLmNvbS9nby9zcGFubmVy
L2FwaXYxL3NwYW5uZXJwYjtzcGFubmVycGKqAhdHb29nbGUuQ2xvdWQuU3Bhbm5lci5WMcoC
F0dvb2dsZVxDbG91ZFxTcGFubmVyXFYx6gIaR29vZ2xlOjpDbG91ZDo6U3Bhbm5lcjo6VjFK
7lQKBxIFDgCDAgEKvAQKAQwSAw4AEjKxBCBDb3B5cmlnaHQgMjAyNiBHb29nbGUgTExDCgog
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
ABoKCQoCAwASAxIAKQoJCgIDARIDEwAmCgkKAgMCEgMUACoKCQoCAwMSAxUALAoJCgIDBBID
FgAtCgkKAgMFEgMXACYKCAoBCBIDGQA0CgkKAgglEgMZADQKCAoBCBIDGgBMCgkKAggLEgMa
AEwKCAoBCBIDGwAiCgkKAggKEgMbACIKCAoBCBIDHAAvCgkKAggIEgMcAC8KCAoBCBIDHQAu
CgkKAggBEgMdAC4KCAoBCBIDHgA0CgkKAggpEgMeADQKCAoBCBIDHwAzCgkKAggtEgMfADMK
eQoCBAASBCMARwEabSBSZXN1bHRzIGZyb20gW1JlYWRdW2dvb2dsZS5zcGFubmVyLnYxLlNw
YW5uZXIuUmVhZF0gb3IKIFtFeGVjdXRlU3FsXVtnb29nbGUuc3Bhbm5lci52MS5TcGFubmVy
LkV4ZWN1dGVTcWxdLgoKCgoDBAABEgMjCBEKSwoEBAACABIDJQIhGj4gTWV0YWRhdGEgYWJv
dXQgdGhlIHJlc3VsdCBzZXQsIHN1Y2ggYXMgcm93IHR5cGUgaW5mb3JtYXRpb24uCgoMCgUE
AAIABhIDJQITCgwKBQQAAgABEgMlFBwKDAoFBAACAAMSAyUfIArdAgoEBAACARIDLAIuGs8C
IEVhY2ggZWxlbWVudCBpbiBgcm93c2AgaXMgYSByb3cgd2hvc2UgZm9ybWF0IGlzIGRlZmlu
ZWQgYnkKIFttZXRhZGF0YS5yb3dfdHlwZV1bZ29vZ2xlLnNwYW5uZXIudjEuUmVzdWx0U2V0
TWV0YWRhdGEucm93X3R5cGVdLiBUaGUgaXRoCiBlbGVtZW50IGluIGVhY2ggcm93IG1hdGNo
ZXMgdGhlIGl0aCBmaWVsZCBpbgogW21ldGFkYXRhLnJvd190eXBlXVtnb29nbGUuc3Bhbm5l
ci52MS5SZXN1bHRTZXRNZXRhZGF0YS5yb3dfdHlwZV0uIEVsZW1lbnRzCiBhcmUgZW5jb2Rl
ZCBiYXNlZCBvbiB0eXBlIGFzIGRlc2NyaWJlZCBbaGVyZV1bZ29vZ2xlLnNwYW5uZXIudjEu
VHlwZUNvZGVdLgoKDAoFBAACAQQSAywCCgoMCgUEAAIBBhIDLAskCgwKBQQAAgEBEgMsJSkK
DAoFBAACAQMSAywsLQr6BAoEBAACAhIDNwIbGuwEIFF1ZXJ5IHBsYW4gYW5kIGV4ZWN1dGlv
biBzdGF0aXN0aWNzIGZvciB0aGUgU1FMIHN0YXRlbWVudCB0aGF0CiBwcm9kdWNlZCB0aGlz
IHJlc3VsdCBzZXQuIFRoZXNlIGNhbiBiZSByZXF1ZXN0ZWQgYnkgc2V0dGluZwogW0V4ZWN1
dGVTcWxSZXF1ZXN0LnF1ZXJ5X21vZGVdW2dvb2dsZS5zcGFubmVyLnYxLkV4ZWN1dGVTcWxS
ZXF1ZXN0LnF1ZXJ5X21vZGVdLgogRE1MIHN0YXRlbWVudHMgYWx3YXlzIHByb2R1Y2Ugc3Rh
dHMgY29udGFpbmluZyB0aGUgbnVtYmVyIG9mIHJvd3MKIG1vZGlmaWVkLCB1bmxlc3MgZXhl
Y3V0ZWQgdXNpbmcgdGhlCiBbRXhlY3V0ZVNxbFJlcXVlc3QuUXVlcnlNb2RlLlBMQU5dW2dv
b2dsZS5zcGFubmVyLnYxLkV4ZWN1dGVTcWxSZXF1ZXN0LlF1ZXJ5TW9kZS5QTEFOXQogW0V4
ZWN1dGVTcWxSZXF1ZXN0LnF1ZXJ5X21vZGVdW2dvb2dsZS5zcGFubmVyLnYxLkV4ZWN1dGVT
cWxSZXF1ZXN0LnF1ZXJ5X21vZGVdLgogT3RoZXIgZmllbGRzIG1pZ2h0IG9yIG1pZ2h0IG5v
dCBiZSBwb3B1bGF0ZWQsIGJhc2VkIG9uIHRoZQogW0V4ZWN1dGVTcWxSZXF1ZXN0LnF1ZXJ5
X21vZGVdW2dvb2dsZS5zcGFubmVyLnYxLkV4ZWN1dGVTcWxSZXF1ZXN0LnF1ZXJ5X21vZGVd
LgoKDAoFBAACAgYSAzcCEAoMCgUEAAICARIDNxEWCgwKBQQAAgIDEgM3GRoKngIKBAQAAgMS
BD0CPi8ajwIgT3B0aW9uYWwuIEEgcHJlY29tbWl0IHRva2VuIGlzIGluY2x1ZGVkIGlmIHRo
ZSByZWFkLXdyaXRlIHRyYW5zYWN0aW9uIGlzIG9uCiBhIG11bHRpcGxleGVkIHNlc3Npb24u
IFBhc3MgdGhlIHByZWNvbW1pdCB0b2tlbiB3aXRoIHRoZSBoaWdoZXN0IHNlcXVlbmNlCiBu
dW1iZXIgZnJvbSB0aGlzIHRyYW5zYWN0aW9uIGF0dGVtcHQgdG8gdGhlCiBbQ29tbWl0XVtn
b29nbGUuc3Bhbm5lci52MS5TcGFubmVyLkNvbW1pdF0gcmVxdWVzdCBmb3IgdGhpcyB0cmFu
c2FjdGlvbi4KCgwKBQQAAgMGEgM9AiIKDAoFBAACAwESAz0jMgoMCgUEAAIDAxIDPTU2CgwK
BQQAAgMIEgM+Bi4KDwoIBAACAwicCAASAz4HLQqKAwoEBAACBBIDRgJIGvwCIE9wdGlvbmFs
LiBBIGNhY2hlIHVwZGF0ZSBleHByZXNzZXMgYSBzZXQgb2YgY2hhbmdlcyB0aGUgY2xpZW50
IHNob3VsZAogaW5jb3Jwb3JhdGUgaW50byBpdHMgbG9jYXRpb24gY2FjaGUuIFRoZSBjbGll
bnQgc2hvdWxkIGRpc2NhcmQgdGhlIGNoYW5nZXMKIGlmIHRoZXkgYXJlIG9sZGVyIHRoYW4g
dGhlIGRhdGEgaXQgYWxyZWFkeSBoYXMuIFRoaXMgZGF0YSBjYW4gYmUgb2J0YWluZWQKIGlu
IHJlc3BvbnNlIHRvIHJlcXVlc3RzIHRoYXQgaW5jbHVkZWQgYSBgUm91dGluZ0hpbnRgIGZp
ZWxkLCBidXQgbWF5IGFsc28KIGJlIG9idGFpbmVkIGJ5IGV4cGxpY2l0IGxvY2F0aW9uLWZl
dGNoaW5nIFJQQ3Mgd2hpY2ggbWF5IGJlIGFkZGVkIGluIHRoZQogZnV0dXJlLgoKDAoFBAAC
BAYSA0YCDQoMCgUEAAIEARIDRg4aCgwKBQQAAgQDEgNGHR4KDAoFBAACBAgSA0YfRwoPCggE
AAIECJwIABIDRiBGCswBCgIEARIFTADIAQEavgEgUGFydGlhbCByZXN1bHRzIGZyb20gYSBz
dHJlYW1pbmcgcmVhZCBvciBTUUwgcXVlcnkuIFN0cmVhbWluZyByZWFkcyBhbmQKIFNRTCBx
dWVyaWVzIGJldHRlciB0b2xlcmF0ZSBsYXJnZSByZXN1bHQgc2V0cywgbGFyZ2Ugcm93cywg
YW5kIGxhcmdlCiB2YWx1ZXMsIGJ1dCBhcmUgYSBsaXR0bGUgdHJpY2tpZXIgdG8gY29uc3Vt
ZS4KCgoKAwQBARIDTAgYCnAKBAQBAgASA08CIRpjIE1ldGFkYXRhIGFib3V0IHRoZSByZXN1
bHQgc2V0LCBzdWNoIGFzIHJvdyB0eXBlIGluZm9ybWF0aW9uLgogT25seSBwcmVzZW50IGlu
IHRoZSBmaXJzdCByZXNwb25zZS4KCgwKBQQBAgAGEgNPAhMKDAoFBAECAAESA08UHAoMCgUE
AQIAAxIDTx8gCq0XCgQEAQIBEgSfAQIsGp4XIEEgc3RyZWFtZWQgcmVzdWx0IHNldCBjb25z
aXN0cyBvZiBhIHN0cmVhbSBvZiB2YWx1ZXMsIHdoaWNoIG1pZ2h0CiBiZSBzcGxpdCBpbnRv
IG1hbnkgYFBhcnRpYWxSZXN1bHRTZXRgIG1lc3NhZ2VzIHRvIGFjY29tbW9kYXRlCiBsYXJn
ZSByb3dzIGFuZC9vciBsYXJnZSB2YWx1ZXMuIEV2ZXJ5IE4gY29tcGxldGUgdmFsdWVzIGRl
ZmluZXMgYQogcm93LCB3aGVyZSBOIGlzIGVxdWFsIHRvIHRoZSBudW1iZXIgb2YgZW50cmll
cyBpbgogW21ldGFkYXRhLnJvd190eXBlLmZpZWxkc11bZ29vZ2xlLnNwYW5uZXIudjEuU3Ry
dWN0VHlwZS5maWVsZHNdLgoKIE1vc3QgdmFsdWVzIGFyZSBlbmNvZGVkIGJhc2VkIG9uIHR5
cGUgYXMgZGVzY3JpYmVkCiBbaGVyZV1bZ29vZ2xlLnNwYW5uZXIudjEuVHlwZUNvZGVdLgoK
IEl0J3MgcG9zc2libGUgdGhhdCB0aGUgbGFzdCB2YWx1ZSBpbiB2YWx1ZXMgaXMgImNodW5r
ZWQiLAogbWVhbmluZyB0aGF0IHRoZSByZXN0IG9mIHRoZSB2YWx1ZSBpcyBzZW50IGluIHN1
YnNlcXVlbnQKIGBQYXJ0aWFsUmVzdWx0U2V0YChzKS4gVGhpcyBpcyBkZW5vdGVkIGJ5IHRo
ZQogW2NodW5rZWRfdmFsdWVdW2dvb2dsZS5zcGFubmVyLnYxLlBhcnRpYWxSZXN1bHRTZXQu
Y2h1bmtlZF92YWx1ZV0gZmllbGQuCiBUd28gb3IgbW9yZSBjaHVua2VkIHZhbHVlcyBjYW4g
YmUgbWVyZ2VkIHRvIGZvcm0gYSBjb21wbGV0ZSB2YWx1ZSBhcwogZm9sbG93czoKCiAgICog
YGJvb2wvbnVtYmVyL251bGxgOiBjYW4ndCBiZSBjaHVua2VkCiAgICogYHN0cmluZ2A6IGNv
bmNhdGVuYXRlIHRoZSBzdHJpbmdzCiAgICogYGxpc3RgOiBjb25jYXRlbmF0ZSB0aGUgbGlz
dHMuIElmIHRoZSBsYXN0IGVsZW1lbnQgaW4gYSBsaXN0IGlzIGEKICAgICBgc3RyaW5nYCwg
YGxpc3RgLCBvciBgb2JqZWN0YCwgbWVyZ2UgaXQgd2l0aCB0aGUgZmlyc3QgZWxlbWVudCBp
bgogICAgIHRoZSBuZXh0IGxpc3QgYnkgYXBwbHlpbmcgdGhlc2UgcnVsZXMgcmVjdXJzaXZl
bHkuCiAgICogYG9iamVjdGA6IGNvbmNhdGVuYXRlIHRoZSAoZmllbGQgbmFtZSwgZmllbGQg
dmFsdWUpIHBhaXJzLiBJZiBhCiAgICAgZmllbGQgbmFtZSBpcyBkdXBsaWNhdGVkLCB0aGVu
IGFwcGx5IHRoZXNlIHJ1bGVzIHJlY3Vyc2l2ZWx5CiAgICAgdG8gbWVyZ2UgdGhlIGZpZWxk
IHZhbHVlcy4KCiBTb21lIGV4YW1wbGVzIG9mIG1lcmdpbmc6CgogICAgIFN0cmluZ3MgYXJl
IGNvbmNhdGVuYXRlZC4KICAgICAiZm9vIiwgImJhciIgPT4gImZvb2JhciIKCiAgICAgTGlz
dHMgb2Ygbm9uLXN0cmluZ3MgYXJlIGNvbmNhdGVuYXRlZC4KICAgICBbMiwgM10sIFs0XSA9
PiBbMiwgMywgNF0KCiAgICAgTGlzdHMgYXJlIGNvbmNhdGVuYXRlZCwgYnV0IHRoZSBsYXN0
IGFuZCBmaXJzdCBlbGVtZW50cyBhcmUgbWVyZ2VkCiAgICAgYmVjYXVzZSB0aGV5IGFyZSBz
dHJpbmdzLgogICAgIFsiYSIsICJiIl0sIFsiYyIsICJkIl0gPT4gWyJhIiwgImJjIiwgImQi
XQoKICAgICBMaXN0cyBhcmUgY29uY2F0ZW5hdGVkLCBidXQgdGhlIGxhc3QgYW5kIGZpcnN0
IGVsZW1lbnRzIGFyZSBtZXJnZWQKICAgICBiZWNhdXNlIHRoZXkgYXJlIGxpc3RzLiBSZWN1
cnNpdmVseSwgdGhlIGxhc3QgYW5kIGZpcnN0IGVsZW1lbnRzCiAgICAgb2YgdGhlIGlubmVy
IGxpc3RzIGFyZSBtZXJnZWQgYmVjYXVzZSB0aGV5IGFyZSBzdHJpbmdzLgogICAgIFsiYSIs
IFsiYiIsICJjIl1dLCBbWyJkIl0sICJlIl0gPT4gWyJhIiwgWyJiIiwgImNkIl0sICJlIl0K
CiAgICAgTm9uLW92ZXJsYXBwaW5nIG9iamVjdCBmaWVsZHMgYXJlIGNvbWJpbmVkLgogICAg
IHsiYSI6ICIxIn0sIHsiYiI6ICIyIn0gPT4geyJhIjogIjEiLCAiYiI6IDIifQoKICAgICBP
dmVybGFwcGluZyBvYmplY3QgZmllbGRzIGFyZSBtZXJnZWQuCiAgICAgeyJhIjogIjEifSwg
eyJhIjogIjIifSA9PiB7ImEiOiAiMTIifQoKICAgICBFeGFtcGxlcyBvZiBtZXJnaW5nIG9i
amVjdHMgY29udGFpbmluZyBsaXN0cyBvZiBzdHJpbmdzLgogICAgIHsiYSI6IFsiMSJdfSwg
eyJhIjogWyIyIl19ID0+IHsiYSI6IFsiMTIiXX0KCiBGb3IgYSBtb3JlIGNvbXBsZXRlIGV4
YW1wbGUsIHN1cHBvc2UgYSBzdHJlYW1pbmcgU1FMIHF1ZXJ5IGlzCiB5aWVsZGluZyBhIHJl
c3VsdCBzZXQgd2hvc2Ugcm93cyBjb250YWluIGEgc2luZ2xlIHN0cmluZwogZmllbGQuIFRo
ZSBmb2xsb3dpbmcgYFBhcnRpYWxSZXN1bHRTZXRgcyBtaWdodCBiZSB5aWVsZGVkOgoKICAg
ICB7CiAgICAgICAibWV0YWRhdGEiOiB7IC4uLiB9CiAgICAgICAidmFsdWVzIjogWyJIZWxs
byIsICJXIl0KICAgICAgICJjaHVua2VkX3ZhbHVlIjogdHJ1ZQogICAgICAgInJlc3VtZV90
b2tlbiI6ICJBZjY1Li4uIgogICAgIH0KICAgICB7CiAgICAgICAidmFsdWVzIjogWyJvcmwi
XQogICAgICAgImNodW5rZWRfdmFsdWUiOiB0cnVlCiAgICAgfQogICAgIHsKICAgICAgICJ2
YWx1ZXMiOiBbImQiXQogICAgICAgInJlc3VtZV90b2tlbiI6ICJaeDFCLi4uIgogICAgIH0K
CiBUaGlzIHNlcXVlbmNlIG9mIGBQYXJ0aWFsUmVzdWx0U2V0YHMgZW5jb2RlcyB0d28gcm93
cywgb25lCiBjb250YWluaW5nIHRoZSBmaWVsZCB2YWx1ZSBgIkhlbGxvImAsIGFuZCBhIHNl
Y29uZCBjb250YWluaW5nIHRoZQogZmllbGQgdmFsdWUgYCJXb3JsZCIgPSAiVyIgKyAib3Js
IiArICJkImAuCgogTm90IGFsbCBgUGFydGlhbFJlc3VsdFNldGBzIGNvbnRhaW4gYSBgcmVz
dW1lX3Rva2VuYC4gRXhlY3V0aW9uIGNhbiBvbmx5IGJlCiByZXN1bWVkIGZyb20gYSBwcmV2
aW91c2x5IHlpZWxkZWQgYHJlc3VtZV90b2tlbmAuIEZvciB0aGUgYWJvdmUgc2VxdWVuY2Ug
b2YKIGBQYXJ0aWFsUmVzdWx0U2V0YHMsIHJlc3VtaW5nIHRoZSBxdWVyeSB3aXRoIGAicmVz
dW1lX3Rva2VuIjogIkFmNjUuLi4iYAogeWllbGRzIHJlc3VsdHMgZnJvbSB0aGUgYFBhcnRp
YWxSZXN1bHRTZXRgIHdpdGggdmFsdWUgIm9ybCIuCgoNCgUEAQIBBBIEnwECCgoNCgUEAQIB
BhIEnwELIAoNCgUEAQIBARIEnwEhJwoNCgUEAQIBAxIEnwEqKwrgAQoEBAECAhIEpQECGRrR
ASBJZiB0cnVlLCB0aGVuIHRoZSBmaW5hbCB2YWx1ZSBpbgogW3ZhbHVlc11bZ29vZ2xlLnNw
YW5uZXIudjEuUGFydGlhbFJlc3VsdFNldC52YWx1ZXNdIGlzIGNodW5rZWQsIGFuZCBtdXN0
IGJlCiBjb21iaW5lZCB3aXRoIG1vcmUgdmFsdWVzIGZyb20gc3Vic2VxdWVudCBgUGFydGlh
bFJlc3VsdFNldGBzIHRvIG9idGFpbiBhCiBjb21wbGV0ZSBmaWVsZCB2YWx1ZS4KCg0KBQQB
AgIFEgSlAQIGCg0KBQQBAgIBEgSlAQcUCg0KBQQBAgIDEgSlARcYCrsCCgQEAQIDEgSsAQIZ
GqwCIFN0cmVhbWluZyBjYWxscyBtaWdodCBiZSBpbnRlcnJ1cHRlZCBmb3IgYSB2YXJpZXR5
IG9mIHJlYXNvbnMsIHN1Y2gKIGFzIFRDUCBjb25uZWN0aW9uIGxvc3MuIElmIHRoaXMgb2Nj
dXJzLCB0aGUgc3RyZWFtIG9mIHJlc3VsdHMgY2FuCiBiZSByZXN1bWVkIGJ5IHJlLXNlbmRp
bmcgdGhlIG9yaWdpbmFsIHJlcXVlc3QgYW5kIGluY2x1ZGluZwogYHJlc3VtZV90b2tlbmAu
IE5vdGUgdGhhdCBleGVjdXRpbmcgYW55IG90aGVyIHRyYW5zYWN0aW9uIGluIHRoZQogc2Ft
ZSBzZXNzaW9uIGludmFsaWRhdGVzIHRoZSB0b2tlbi4KCg0KBQQBAgMFEgSsAQIHCg0KBQQB
AgMBEgSsAQgUCg0KBQQBAgMDEgSsARcYCuUCCgQEAQIEEgSzAQIbGtYCIFF1ZXJ5IHBsYW4g
YW5kIGV4ZWN1dGlvbiBzdGF0aXN0aWNzIGZvciB0aGUgc3RhdGVtZW50IHRoYXQgcHJvZHVj
ZWQgdGhpcwogc3RyZWFtaW5nIHJlc3VsdCBzZXQuIFRoZXNlIGNhbiBiZSByZXF1ZXN0ZWQg
Ynkgc2V0dGluZwogW0V4ZWN1dGVTcWxSZXF1ZXN0LnF1ZXJ5X21vZGVdW2dvb2dsZS5zcGFu
bmVyLnYxLkV4ZWN1dGVTcWxSZXF1ZXN0LnF1ZXJ5X21vZGVdCiBhbmQgYXJlIHNlbnQgb25s
eSBvbmNlIHdpdGggdGhlIGxhc3QgcmVzcG9uc2UgaW4gdGhlIHN0cmVhbS4gVGhpcyBmaWVs
ZCBpcwogYWxzbyBwcmVzZW50IGluIHRoZSBsYXN0IHJlc3BvbnNlIGZvciBETUwgc3RhdGVt
ZW50cy4KCg0KBQQBAgQGEgSzAQIQCg0KBQQBAgQBEgSzAREWCg0KBQQBAgQDEgSzARkaCqUC
CgQEAQIFEga5AQK6AS8alAIgT3B0aW9uYWwuIEEgcHJlY29tbWl0IHRva2VuIGlzIGluY2x1
ZGVkIGlmIHRoZSByZWFkLXdyaXRlIHRyYW5zYWN0aW9uCiBoYXMgbXVsdGlwbGV4ZWQgc2Vz
c2lvbnMgZW5hYmxlZC4gUGFzcyB0aGUgcHJlY29tbWl0IHRva2VuIHdpdGggdGhlIGhpZ2hl
c3QKIHNlcXVlbmNlIG51bWJlciBmcm9tIHRoaXMgdHJhbnNhY3Rpb24gYXR0ZW1wdCB0byB0
aGUKIFtDb21taXRdW2dvb2dsZS5zcGFubmVyLnYxLlNwYW5uZXIuQ29tbWl0XSByZXF1ZXN0
IGZvciB0aGlzIHRyYW5zYWN0aW9uLgoKDQoFBAECBQYSBLkBAiIKDQoFBAECBQESBLkBIzIK
DQoFBAECBQMSBLkBNTYKDQoFBAECBQgSBLoBBi4KEAoIBAECBQicCAASBLoBBy0KygEKBAQB
AgYSBL8BAjkauwEgT3B0aW9uYWwuIEluZGljYXRlcyB3aGV0aGVyIHRoaXMgaXMgdGhlIGxh
c3QgYFBhcnRpYWxSZXN1bHRTZXRgIGluIHRoZQogc3RyZWFtLiBUaGUgc2VydmVyIG1pZ2h0
IG9wdGlvbmFsbHkgc2V0IHRoaXMgZmllbGQuIENsaWVudHMgc2hvdWxkbid0IHJlbHkKIG9u
IHRoaXMgZmllbGQgYmVpbmcgc2V0IGluIGFsbCBjYXNlcy4KCg0KBQQBAgYFEgS/AQIGCg0K
BQQBAgYBEgS/AQcLCg0KBQQBAgYDEgS/AQ4PCg0KBQQBAgYIEgS/ARA4ChAKCAQBAgYInAgA
EgS/ARE3CosDCgQEAQIHEgTHAQJJGvwCIE9wdGlvbmFsLiBBIGNhY2hlIHVwZGF0ZSBleHBy
ZXNzZXMgYSBzZXQgb2YgY2hhbmdlcyB0aGUgY2xpZW50IHNob3VsZAogaW5jb3Jwb3JhdGUg
aW50byBpdHMgbG9jYXRpb24gY2FjaGUuIFRoZSBjbGllbnQgc2hvdWxkIGRpc2NhcmQgdGhl
IGNoYW5nZXMKIGlmIHRoZXkgYXJlIG9sZGVyIHRoYW4gdGhlIGRhdGEgaXQgYWxyZWFkeSBo
YXMuIFRoaXMgZGF0YSBjYW4gYmUgb2J0YWluZWQKIGluIHJlc3BvbnNlIHRvIHJlcXVlc3Rz
IHRoYXQgaW5jbHVkZWQgYSBgUm91dGluZ0hpbnRgIGZpZWxkLCBidXQgbWF5IGFsc28KIGJl
IG9idGFpbmVkIGJ5IGV4cGxpY2l0IGxvY2F0aW9uLWZldGNoaW5nIFJQQ3Mgd2hpY2ggbWF5
IGJlIGFkZGVkIGluIHRoZQogZnV0dXJlLgoKDQoFBAECBwYSBMcBAg0KDQoFBAECBwESBMcB
DhoKDQoFBAECBwMSBMcBHR8KDQoFBAECBwgSBMcBIEgKEAoIBAECBwicCAASBMcBIUcKhQEK
AgQCEgbMAQDmAQEadyBNZXRhZGF0YSBhYm91dCBhIFtSZXN1bHRTZXRdW2dvb2dsZS5zcGFu
bmVyLnYxLlJlc3VsdFNldF0gb3IKIFtQYXJ0aWFsUmVzdWx0U2V0XVtnb29nbGUuc3Bhbm5l
ci52MS5QYXJ0aWFsUmVzdWx0U2V0XS4KCgsKAwQCARIEzAEIGQrRAgoEBAICABIE1QECGhrC
AiBJbmRpY2F0ZXMgdGhlIGZpZWxkIG5hbWVzIGFuZCB0eXBlcyBmb3IgdGhlIHJvd3MgaW4g
dGhlIHJlc3VsdAogc2V0LiBGb3IgZXhhbXBsZSwgYSBTUUwgcXVlcnkgbGlrZSBgIlNFTEVD
VCBVc2VySWQsIFVzZXJOYW1lIEZST00KIFVzZXJzImAgY291bGQgcmV0dXJuIGEgYHJvd190
eXBlYCB2YWx1ZSBsaWtlOgoKICAgICAiZmllbGRzIjogWwogICAgICAgeyAibmFtZSI6ICJV
c2VySWQiLCAidHlwZSI6IHsgImNvZGUiOiAiSU5UNjQiIH0gfSwKICAgICAgIHsgIm5hbWUi
OiAiVXNlck5hbWUiLCAidHlwZSI6IHsgImNvZGUiOiAiU1RSSU5HIiB9IH0sCiAgICAgXQoK
DQoFBAICAAYSBNUBAgwKDQoFBAICAAESBNUBDRUKDQoFBAICAAMSBNUBGBkKigEKBAQCAgES
BNkBAh4afCBJZiB0aGUgcmVhZCBvciBTUUwgcXVlcnkgYmVnYW4gYSB0cmFuc2FjdGlvbiBh
cyBhIHNpZGUtZWZmZWN0LCB0aGUKIGluZm9ybWF0aW9uIGFib3V0IHRoZSBuZXcgdHJhbnNh
Y3Rpb24gaXMgeWllbGRlZCBoZXJlLgoKDQoFBAICAQYSBNkBAg0KDQoFBAICAQESBNkBDhkK
DQoFBAICAQMSBNkBHB0K7QMKBAQCAgISBOUBAica3gMgQSBTUUwgcXVlcnkgY2FuIGJlIHBh
cmFtZXRlcml6ZWQuIEluIFBMQU4gbW9kZSwgdGhlc2UgcGFyYW1ldGVycyBjYW4gYmUKIHVu
ZGVjbGFyZWQuIFRoaXMgaW5kaWNhdGVzIHRoZSBmaWVsZCBuYW1lcyBhbmQgdHlwZXMgZm9y
IHRob3NlIHVuZGVjbGFyZWQKIHBhcmFtZXRlcnMgaW4gdGhlIFNRTCBxdWVyeS4gRm9yIGV4
YW1wbGUsIGEgU1FMIHF1ZXJ5IGxpa2UgYCJTRUxFQ1QgKiBGUk9NCiBVc2VycyB3aGVyZSBV
c2VySWQgPSBAdXNlcklkIGFuZCBVc2VyTmFtZSA9IEB1c2VyTmFtZSAiYCBjb3VsZCByZXR1
cm4gYQogYHVuZGVjbGFyZWRfcGFyYW1ldGVyc2AgdmFsdWUgbGlrZToKCiAgICAgImZpZWxk
cyI6IFsKICAgICAgIHsgIm5hbWUiOiAiVXNlcklkIiwgInR5cGUiOiB7ICJjb2RlIjogIklO
VDY0IiB9IH0sCiAgICAgICB7ICJuYW1lIjogIlVzZXJOYW1lIiwgInR5cGUiOiB7ICJjb2Rl
IjogIlNUUklORyIgfSB9LAogICAgIF0KCg0KBQQCAgIGEgTlAQIMCg0KBQQCAgIBEgTlAQ0i
Cg0KBQQCAgIDEgTlASUmCpMBCgIEAxIG6gEAgwIBGoQBIEFkZGl0aW9uYWwgc3RhdGlzdGlj
cyBhYm91dCBhIFtSZXN1bHRTZXRdW2dvb2dsZS5zcGFubmVyLnYxLlJlc3VsdFNldF0gb3IK
IFtQYXJ0aWFsUmVzdWx0U2V0XVtnb29nbGUuc3Bhbm5lci52MS5QYXJ0aWFsUmVzdWx0U2V0
XS4KCgsKAwQDARIE6gEIFgpkCgQEAwIAEgTtAQIbGlYgW1F1ZXJ5UGxhbl1bZ29vZ2xlLnNw
YW5uZXIudjEuUXVlcnlQbGFuXSBmb3IgdGhlIHF1ZXJ5IGFzc29jaWF0ZWQgd2l0aCB0aGlz
CiByZXN1bHQuCgoNCgUEAwIABhIE7QECCwoNCgUEAwIAARIE7QEMFgoNCgUEAwIAAxIE7QEZ
GgqeAgoEBAMCARIE+AECKRqPAiBBZ2dyZWdhdGVkIHN0YXRpc3RpY3MgZnJvbSB0aGUgZXhl
Y3V0aW9uIG9mIHRoZSBxdWVyeS4gT25seSBwcmVzZW50IHdoZW4KIHRoZSBxdWVyeSBpcyBw
cm9maWxlZC4gRm9yIGV4YW1wbGUsIGEgcXVlcnkgY291bGQgcmV0dXJuIHRoZSBzdGF0aXN0
aWNzIGFzCiBmb2xsb3dzOgoKICAgICB7CiAgICAgICAicm93c19yZXR1cm5lZCI6ICIzIiwK
ICAgICAgICJlbGFwc2VkX3RpbWUiOiAiMS4yMiBzZWNzIiwKICAgICAgICJjcHVfdGltZSI6
ICIxLjE5IHNlY3MiCiAgICAgfQoKDQoFBAMCAQYSBPgBAhgKDQoFBAMCAQESBPgBGSQKDQoF
BAMCAQMSBPgBJygKQwoEBAMIABIG+wECggIDGjMgVGhlIG51bWJlciBvZiByb3dzIG1vZGlm
aWVkIGJ5IHRoZSBETUwgc3RhdGVtZW50LgoKDQoFBAMIAAESBPsBCBEKTwoEBAMCAhIE/QEE
HhpBIFN0YW5kYXJkIERNTCByZXR1cm5zIGFuIGV4YWN0IGNvdW50IG9mIHJvd3MgdGhhdCB3
ZXJlIG1vZGlmaWVkLgoKDQoFBAMCAgUSBP0BBAkKDQoFBAMCAgESBP0BChkKDQoFBAMCAgMS
BP0BHB0KeAoEBAMCAxIEgQIEJBpqIFBhcnRpdGlvbmVkIERNTCBkb2Vzbid0IG9mZmVyIGV4
YWN0bHktb25jZSBzZW1hbnRpY3MsIHNvIGl0CiByZXR1cm5zIGEgbG93ZXIgYm91bmQgb2Yg
dGhlIHJvd3MgbW9kaWZpZWQuCgoNCgUEAwIDBRIEgQIECQoNCgUEAwIDARIEgQIKHwoNCgUE
AwIDAxIEgQIiI2IGcHJvdG8z
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Spanner::V1::ResultSet::ResultSet ===
    # Fields for ResultSet
    # Field: metadata Type: 11 (.google.spanner.v1.ResultSetMetadata)
    # Field: rows Type: 11 (.google.protobuf.ListValue)
    # Field: stats Type: 11 (.google.spanner.v1.ResultSetStats)
    # Field: precommit_token Type: 11 (.google.spanner.v1.MultiplexedSessionPrecommitToken)
    # Field: cache_update Type: 11 (.google.spanner.v1.CacheUpdate)

# === Message: Google::Spanner::V1::ResultSet::PartialResultSet ===
    # Fields for PartialResultSet
    # Field: metadata Type: 11 (.google.spanner.v1.ResultSetMetadata)
    # Field: values Type: 11 (.google.protobuf.Value)
    # Field: chunked_value Type: 8 ()
    # Field: resume_token Type: 12 ()
    # Field: stats Type: 11 (.google.spanner.v1.ResultSetStats)
    # Field: precommit_token Type: 11 (.google.spanner.v1.MultiplexedSessionPrecommitToken)
    # Field: last Type: 8 ()
    # Field: cache_update Type: 11 (.google.spanner.v1.CacheUpdate)

# === Message: Google::Spanner::V1::ResultSet::ResultSetMetadata ===
    # Fields for ResultSetMetadata
    # Field: row_type Type: 11 (.google.spanner.v1.StructType)
    # Field: transaction Type: 11 (.google.spanner.v1.Transaction)
    # Field: undeclared_parameters Type: 11 (.google.spanner.v1.StructType)

# === Message: Google::Spanner::V1::ResultSet::ResultSetStats ===
    # Fields for ResultSetStats
    # Field: query_plan Type: 11 (.google.spanner.v1.QueryPlan)
    # Field: query_stats Type: 11 (.google.protobuf.Struct)
    # Field: row_count_exact Type: 3 ()
    # Field: row_count_lower_bound Type: 3 ()

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Spanner::V1::ResultSet - Compiled Protocol Buffers messages for google/spanner/v1/result_set.proto

=head1 SYNOPSIS

    use Google::Spanner::V1::ResultSet;

    my $msg = Google::Spanner::V1::ResultSet::ResultSet->new({
        metadata => $metadata,
        rows => $rows,
        stats => $stats,
        precommit_token => $precommit_token,
    });

    # Read or update a field
    my $val = $msg->metadata();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Spanner::V1::ResultSet::ResultSet->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/spanner/v1/result_set.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Spanner::V1::ResultSet::ResultSet

Results from [Read][google.spanner.v1.Spanner.Read] or
[ExecuteSql][google.spanner.v1.Spanner.ExecuteSql].

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->metadata() >> / C<< $msg->metadata($value) >>

Type: C<Message> (L<Google::Spanner::V1::ResultSet::ResultSetMetadata>)

Metadata about the result set, such as row type information.

=item * C<< $msg->rows() >> / C<< $msg->rows($value) >>

Type: C<Message> (L<Google::Protobuf::Struct::ListValue>)

Each element in `rows` is a row whose format is defined by
[metadata.row_type][google.spanner.v1.ResultSetMetadata.row_type]. The ith
element in each row matches the ith field in
[metadata.row_type][google.spanner.v1.ResultSetMetadata.row_type]. Elements
are encoded based on type as described [here][google.spanner.v1.TypeCode].

=item * C<< $msg->stats() >> / C<< $msg->stats($value) >>

Type: C<Message> (L<Google::Spanner::V1::ResultSet::ResultSetStats>)

Query plan and execution statistics for the SQL statement that
produced this result set. These can be requested by setting
[ExecuteSqlRequest.query_mode][google.spanner.v1.ExecuteSqlRequest.query_mode].
DML statements always produce stats containing the number of rows
modified, unless executed using the
[ExecuteSqlRequest.QueryMode.PLAN][google.spanner.v1.ExecuteSqlRequest.QueryMode.PLAN]
[ExecuteSqlRequest.query_mode][google.spanner.v1.ExecuteSqlRequest.query_mode].
Other fields might or might not be populated, based on the
[ExecuteSqlRequest.query_mode][google.spanner.v1.ExecuteSqlRequest.query_mode].

=item * C<< $msg->precommit_token() >> / C<< $msg->precommit_token($value) >>

Type: C<Message> (L<Google::Spanner::V1::Transaction::MultiplexedSessionPrecommitToken>)

Optional. A precommit token is included if the read-write transaction is on
a multiplexed session. Pass the precommit token with the highest sequence
number from this transaction attempt to the
[Commit][google.spanner.v1.Spanner.Commit] request for this transaction.

=item * C<< $msg->cache_update() >> / C<< $msg->cache_update($value) >>

Type: C<Message> (L<Google::Spanner::V1::Location::CacheUpdate>)

Optional. A cache update expresses a set of changes the client should
incorporate into its location cache. The client should discard the changes
if they are older than the data it already has. This data can be obtained
in response to requests that included a `RoutingHint` field, but may also
be obtained by explicit location-fetching RPCs which may be added in the
future.

=back

=head2 Google::Spanner::V1::ResultSet::PartialResultSet

Partial results from a streaming read or SQL query. Streaming reads and
SQL queries better tolerate large result sets, large rows, and large
values, but are a little trickier to consume.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->metadata() >> / C<< $msg->metadata($value) >>

Type: C<Message> (L<Google::Spanner::V1::ResultSet::ResultSetMetadata>)

Metadata about the result set, such as row type information.
Only present in the first response.

=item * C<< $msg->values() >> / C<< $msg->values($value) >>

Type: C<Message> (L<Google::Protobuf::Struct::Value>)

A streamed result set consists of a stream of values, which might
be split into many `PartialResultSet` messages to accommodate
large rows and/or large values. Every N complete values defines a
row, where N is equal to the number of entries in
[metadata.row_type.fields][google.spanner.v1.StructType.fields].

Most values are encoded based on type as described
[here][google.spanner.v1.TypeCode].

It's possible that the last value in values is "chunked",
meaning that the rest of the value is sent in subsequent
`PartialResultSet`(s). This is denoted by the
[chunked_value][google.spanner.v1.PartialResultSet.chunked_value] field.
Two or more chunked values can be merged to form a complete value as
follows:

  * `bool/number/null`: can't be chunked
  * `string`: concatenate the strings
  * `list`: concatenate the lists. If the last element in a list is a
    `string`, `list`, or `object`, merge it with the first element in
    the next list by applying these rules recursively.
  * `object`: concatenate the (field name, field value) pairs. If a
    field name is duplicated, then apply these rules recursively
    to merge the field values.

Some examples of merging:

    Strings are concatenated.
    "foo", "bar" => "foobar"

    Lists of non-strings are concatenated.
    [2, 3], [4] => [2, 3, 4]

    Lists are concatenated, but the last and first elements are merged
    because they are strings.
    ["a", "b"], ["c", "d"] => ["a", "bc", "d"]

    Lists are concatenated, but the last and first elements are merged
    because they are lists. Recursively, the last and first elements
    of the inner lists are merged because they are strings.
    ["a", ["b", "c"]], [["d"], "e"] => ["a", ["b", "cd"], "e"]

    Non-overlapping object fields are combined.
    {"a": "1"}, {"b": "2"} => {"a": "1", "b": 2"}

    Overlapping object fields are merged.
    {"a": "1"}, {"a": "2"} => {"a": "12"}

    Examples of merging objects containing lists of strings.
    {"a": ["1"]}, {"a": ["2"]} => {"a": ["12"]}

For a more complete example, suppose a streaming SQL query is
yielding a result set whose rows contain a single string
field. The following `PartialResultSet`s might be yielded:

    {
      "metadata": { ... }
      "values": ["Hello", "W"]
      "chunked_value": true
      "resume_token": "Af65..."
    }
    {
      "values": ["orl"]
      "chunked_value": true
    }
    {
      "values": ["d"]
      "resume_token": "Zx1B..."
    }

This sequence of `PartialResultSet`s encodes two rows, one
containing the field value `"Hello"`, and a second containing the
field value `"World" = "W" + "orl" + "d"`.

Not all `PartialResultSet`s contain a `resume_token`. Execution can only be
resumed from a previously yielded `resume_token`. For the above sequence of
`PartialResultSet`s, resuming the query with `"resume_token": "Af65..."`
yields results from the `PartialResultSet` with value "orl".

=item * C<< $msg->chunked_value() >> / C<< $msg->chunked_value($value) >>

Type: C<Bool>

If true, then the final value in
[values][google.spanner.v1.PartialResultSet.values] is chunked, and must be
combined with more values from subsequent `PartialResultSet`s to obtain a
complete field value.

=item * C<< $msg->resume_token() >> / C<< $msg->resume_token($value) >>

Type: C<Bytes>

Streaming calls might be interrupted for a variety of reasons, such
as TCP connection loss. If this occurs, the stream of results can
be resumed by re-sending the original request and including
`resume_token`. Note that executing any other transaction in the
same session invalidates the token.

=item * C<< $msg->stats() >> / C<< $msg->stats($value) >>

Type: C<Message> (L<Google::Spanner::V1::ResultSet::ResultSetStats>)

Query plan and execution statistics for the statement that produced this
streaming result set. These can be requested by setting
[ExecuteSqlRequest.query_mode][google.spanner.v1.ExecuteSqlRequest.query_mode]
and are sent only once with the last response in the stream. This field is
also present in the last response for DML statements.

=item * C<< $msg->precommit_token() >> / C<< $msg->precommit_token($value) >>

Type: C<Message> (L<Google::Spanner::V1::Transaction::MultiplexedSessionPrecommitToken>)

Optional. A precommit token is included if the read-write transaction
has multiplexed sessions enabled. Pass the precommit token with the highest
sequence number from this transaction attempt to the
[Commit][google.spanner.v1.Spanner.Commit] request for this transaction.

=item * C<< $msg->last() >> / C<< $msg->last($value) >>

Type: C<Bool>

Optional. Indicates whether this is the last `PartialResultSet` in the
stream. The server might optionally set this field. Clients shouldn't rely
on this field being set in all cases.

=item * C<< $msg->cache_update() >> / C<< $msg->cache_update($value) >>

Type: C<Message> (L<Google::Spanner::V1::Location::CacheUpdate>)

Optional. A cache update expresses a set of changes the client should
incorporate into its location cache. The client should discard the changes
if they are older than the data it already has. This data can be obtained
in response to requests that included a `RoutingHint` field, but may also
be obtained by explicit location-fetching RPCs which may be added in the
future.

=back

=head2 Google::Spanner::V1::ResultSet::ResultSetMetadata

Metadata about a [ResultSet][google.spanner.v1.ResultSet] or
[PartialResultSet][google.spanner.v1.PartialResultSet].

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->row_type() >> / C<< $msg->row_type($value) >>

Type: C<Message> (L<Google::Spanner::V1::Type::StructType>)

Indicates the field names and types for the rows in the result
set. For example, a SQL query like `"SELECT UserId, UserName FROM
Users"` could return a `row_type` value like:

    "fields": [
      { "name": "UserId", "type": { "code": "INT64" } },
      { "name": "UserName", "type": { "code": "STRING" } },
    ]

=item * C<< $msg->transaction() >> / C<< $msg->transaction($value) >>

Type: C<Message> (L<Google::Spanner::V1::Transaction::Transaction>)

If the read or SQL query began a transaction as a side-effect, the
information about the new transaction is yielded here.

=item * C<< $msg->undeclared_parameters() >> / C<< $msg->undeclared_parameters($value) >>

Type: C<Message> (L<Google::Spanner::V1::Type::StructType>)

A SQL query can be parameterized. In PLAN mode, these parameters can be
undeclared. This indicates the field names and types for those undeclared
parameters in the SQL query. For example, a SQL query like `"SELECT * FROM
Users where UserId = @userId and UserName = @userName "` could return a
`undeclared_parameters` value like:

    "fields": [
      { "name": "UserId", "type": { "code": "INT64" } },
      { "name": "UserName", "type": { "code": "STRING" } },
    ]

=back

=head2 Google::Spanner::V1::ResultSet::ResultSetStats

Additional statistics about a [ResultSet][google.spanner.v1.ResultSet] or
[PartialResultSet][google.spanner.v1.PartialResultSet].

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->query_plan() >> / C<< $msg->query_plan($value) >>

Type: C<Message> (L<Google::Spanner::V1::QueryPlan::QueryPlan>)

[QueryPlan][google.spanner.v1.QueryPlan] for the query associated with this
result.

=item * C<< $msg->query_stats() >> / C<< $msg->query_stats($value) >>

Type: C<Message> (L<Google::Protobuf::Struct::Struct>)

Aggregated statistics from the execution of the query. Only present when
the query is profiled. For example, a query could return the statistics as
follows:

    {
      "rows_returned": "3",
      "elapsed_time": "1.22 secs",
      "cpu_time": "1.19 secs"
    }

=item * C<< $msg->row_count_exact() >> / C<< $msg->row_count_exact($value) >>

Type: C<Int64>

Standard DML returns an exact count of rows that were modified.

=item * C<< $msg->row_count_lower_bound() >> / C<< $msg->row_count_lower_bound($value) >>

Type: C<Int64>

Partitioned DML doesn't offer exactly-once semantics, so it
returns a lower bound of the rows modified.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Spanner::V1::ResultSet::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
