package Google::Cloud::Ces::V1beta::AgentCard;

use strict;
use warnings;

our $VERSION = '0.14';

use Protobuf::Message;
use Protobuf::DescriptorPool;
use Protobuf::Internal qw(:all);
use MIME::Base64;

BEGIN {
    eval { require Google::Api::FieldBehavior };
    eval { require Google::Cloud::Ces::V1beta::Auth };
    my $descriptor_b64 = <<'EOF';
Cihnb29nbGUvY2xvdWQvY2VzL3YxYmV0YS9hZ2VudF9jYXJkLnByb3RvEhdnb29nbGUuY2xv
dWQuY2VzLnYxYmV0YRofZ29vZ2xlL2FwaS9maWVsZF9iZWhhdmlvci5wcm90bxoiZ29vZ2xl
L2Nsb3VkL2Nlcy92MWJldGEvYXV0aC5wcm90byKNAgoJQWdlbnRDYXJkEhcKBG5hbWUYASAB
KAlCA+BBAlIEbmFtZRIlCgtkZXNjcmlwdGlvbhgCIAEoCUID4EECUgtkZXNjcmlwdGlvbhJf
ChRzdXBwb3J0ZWRfaW50ZXJmYWNlcxgDIAMoCzInLmdvb2dsZS5jbG91ZC5jZXMudjFiZXRh
LkFnZW50SW50ZXJmYWNlQgPgQQJSE3N1cHBvcnRlZEludGVyZmFjZXMSHQoHdmVyc2lvbhgF
IAEoCUID4EECUgd2ZXJzaW9uEkAKBnNraWxscxgGIAMoCzIjLmdvb2dsZS5jbG91ZC5jZXMu
djFiZXRhLkFnZW50U2tpbGxCA+BBAlIGc2tpbGxzIp8BCg5BZ2VudEludGVyZmFjZRIVCgN1
cmwYASABKAlCA+BBAlIDdXJsEi4KEHByb3RvY29sX2JpbmRpbmcYAiABKAlCA+BBAlIPcHJv
dG9jb2xCaW5kaW5nEhYKBnRlbmFudBgDIAEoCVIGdGVuYW50Ei4KEHByb3RvY29sX3ZlcnNp
b24YBCABKAlCA+BBAlIPcHJvdG9jb2xWZXJzaW9uItoBCgpBZ2VudFNraWxsEhMKAmlkGAEg
ASgJQgPgQQJSAmlkEhcKBG5hbWUYAiABKAlCA+BBAlIEbmFtZRIlCgtkZXNjcmlwdGlvbhgD
IAEoCUID4EECUgtkZXNjcmlwdGlvbhIXCgR0YWdzGAQgAygJQgPgQQJSBHRhZ3MSGgoIZXhh
bXBsZXMYBSADKAlSCGV4YW1wbGVzEh8KC2lucHV0X21vZGVzGAYgAygJUgppbnB1dE1vZGVz
EiEKDG91dHB1dF9tb2RlcxgHIAMoCVILb3V0cHV0TW9kZXMi4gUKD1JlbW90ZUEyYUNvbmZp
ZxJICgphZ2VudF9jYXJkGAEgASgLMiIuZ29vZ2xlLmNsb3VkLmNlcy52MWJldGEuQWdlbnRD
YXJkQgPgQQFIAFIJYWdlbnRDYXJkEiwKDmFnZW50X3JlZ2lzdHJ5GAIgASgJQgPgQQFIAFIN
YWdlbnRSZWdpc3RyeRJeChJhcGlfYXV0aGVudGljYXRpb24YAyABKAsyKi5nb29nbGUuY2xv
dWQuY2VzLnYxYmV0YS5BcGlBdXRoZW50aWNhdGlvbkID4EEBUhFhcGlBdXRoZW50aWNhdGlv
bhJ9ChZpbnB1dF92YXJpYWJsZV9tYXBwaW5nGAQgAygLMkIuZ29vZ2xlLmNsb3VkLmNlcy52
MWJldGEuUmVtb3RlQTJhQ29uZmlnLklucHV0VmFyaWFibGVNYXBwaW5nRW50cnlCA+BBAVIU
aW5wdXRWYXJpYWJsZU1hcHBpbmcSgAEKF291dHB1dF92YXJpYWJsZV9tYXBwaW5nGAUgAygL
MkMuZ29vZ2xlLmNsb3VkLmNlcy52MWJldGEuUmVtb3RlQTJhQ29uZmlnLk91dHB1dFZhcmlh
YmxlTWFwcGluZ0VudHJ5QgPgQQFSFW91dHB1dFZhcmlhYmxlTWFwcGluZxIwChFzdHJlYW1p
bmdfZW5hYmxlZBgGIAEoCEID4EEBUhBzdHJlYW1pbmdFbmFibGVkEiIKCmNvbnRleHRfaWQY
ByABKAlCA+BBAVIJY29udGV4dElkGkcKGUlucHV0VmFyaWFibGVNYXBwaW5nRW50cnkSEAoD
a2V5GAEgASgJUgNrZXkSFAoFdmFsdWUYAiABKAlSBXZhbHVlOgI4ARpIChpPdXRwdXRWYXJp
YWJsZU1hcHBpbmdFbnRyeRIQCgNrZXkYASABKAlSA2tleRIUCgV2YWx1ZRgCIAEoCVIFdmFs
dWU6AjgBQgwKCmFnZW50X3NwZWMiugUKD1JlbW90ZUFnZW50VG9vbBIXCgRuYW1lGAEgASgJ
QgPgQQJSBG5hbWUSJQoLZGVzY3JpcHRpb24YAiABKAlCA+BBAlILZGVzY3JpcHRpb24SRgoK
YWdlbnRfY2FyZBgDIAEoCzIiLmdvb2dsZS5jbG91ZC5jZXMudjFiZXRhLkFnZW50Q2FyZEID
4EECUglhZ2VudENhcmQSXgoSYXBpX2F1dGhlbnRpY2F0aW9uGAQgASgLMiouZ29vZ2xlLmNs
b3VkLmNlcy52MWJldGEuQXBpQXV0aGVudGljYXRpb25CA+BBAVIRYXBpQXV0aGVudGljYXRp
b24SKgoOc3RhdGVmdWxfYWdlbnQYBSABKAhCA+BBAVINc3RhdGVmdWxBZ2VudBJ9ChZpbnB1
dF92YXJpYWJsZV9tYXBwaW5nGAYgAygLMkIuZ29vZ2xlLmNsb3VkLmNlcy52MWJldGEuUmVt
b3RlQWdlbnRUb29sLklucHV0VmFyaWFibGVNYXBwaW5nRW50cnlCA+BBAVIUaW5wdXRWYXJp
YWJsZU1hcHBpbmcSgAEKF291dHB1dF92YXJpYWJsZV9tYXBwaW5nGAcgAygLMkMuZ29vZ2xl
LmNsb3VkLmNlcy52MWJldGEuUmVtb3RlQWdlbnRUb29sLk91dHB1dFZhcmlhYmxlTWFwcGlu
Z0VudHJ5QgPgQQFSFW91dHB1dFZhcmlhYmxlTWFwcGluZxpHChlJbnB1dFZhcmlhYmxlTWFw
cGluZ0VudHJ5EhAKA2tleRgBIAEoCVIDa2V5EhQKBXZhbHVlGAIgASgJUgV2YWx1ZToCOAEa
SAoaT3V0cHV0VmFyaWFibGVNYXBwaW5nRW50cnkSEAoDa2V5GAEgASgJUgNrZXkSFAoFdmFs
dWUYAiABKAlSBXZhbHVlOgI4AUJeChtjb20uZ29vZ2xlLmNsb3VkLmNlcy52MWJldGFCDkFn
ZW50Q2FyZFByb3RvUAFaLWNsb3VkLmdvb2dsZS5jb20vZ28vY2VzL2FwaXYxYmV0YS9jZXNw
YjtjZXNwYkqLNwoHEgUOAKYBAQq8BAoBDBIDDgASMrEEIENvcHlyaWdodCAyMDI2IEdvb2ds
ZSBMTEMKCiBMaWNlbnNlZCB1bmRlciB0aGUgQXBhY2hlIExpY2Vuc2UsIFZlcnNpb24gMi4w
ICh0aGUgIkxpY2Vuc2UiKTsKIHlvdSBtYXkgbm90IHVzZSB0aGlzIGZpbGUgZXhjZXB0IGlu
IGNvbXBsaWFuY2Ugd2l0aCB0aGUgTGljZW5zZS4KIFlvdSBtYXkgb2J0YWluIGEgY29weSBv
ZiB0aGUgTGljZW5zZSBhdAoKICAgICBodHRwOi8vd3d3LmFwYWNoZS5vcmcvbGljZW5zZXMv
TElDRU5TRS0yLjAKCiBVbmxlc3MgcmVxdWlyZWQgYnkgYXBwbGljYWJsZSBsYXcgb3IgYWdy
ZWVkIHRvIGluIHdyaXRpbmcsIHNvZnR3YXJlCiBkaXN0cmlidXRlZCB1bmRlciB0aGUgTGlj
ZW5zZSBpcyBkaXN0cmlidXRlZCBvbiBhbiAiQVMgSVMiIEJBU0lTLAogV0lUSE9VVCBXQVJS
QU5USUVTIE9SIENPTkRJVElPTlMgT0YgQU5ZIEtJTkQsIGVpdGhlciBleHByZXNzIG9yIGlt
cGxpZWQuCiBTZWUgdGhlIExpY2Vuc2UgZm9yIHRoZSBzcGVjaWZpYyBsYW5ndWFnZSBnb3Zl
cm5pbmcgcGVybWlzc2lvbnMgYW5kCiBsaW1pdGF0aW9ucyB1bmRlciB0aGUgTGljZW5zZS4K
CggKAQISAxAAIAoJCgIDABIDEgApCgkKAgMBEgMTACwKCAoBCBIDFQBECgkKAggLEgMVAEQK
CAoBCBIDFgAiCgkKAggKEgMWACIKCAoBCBIDFwAvCgkKAggIEgMXAC8KCAoBCBIDGAA0CgkK
AggBEgMYADQKxwEKAgQAEgQdADABGroBIEFnZW50Q2FyZCBjb252ZXlzIGtleSBpbmZvcm1h
dGlvbiBhYm91dCBhIHJlbW90ZSBhZ2VudC4KIEl0IGlzIGEgdHJpbW1lZCB2ZXJzaW9uIG9m
IHRoZSBBZ2VudENhcmQgZGVmaW5lZCBpbiB0aGUgQTJBIHByb3RvY29sCiBodHRwczovL2Ey
YS1wcm90b2NvbC5vcmcvZGV2L3NwZWNpZmljYXRpb24vIzQ0MS1hZ2VudGNhcmQKCgoKAwQA
ARIDHQgRCj0KBAQAAgASAx8COxowIFJlcXVpcmVkLiBBIGh1bWFuLXJlYWRhYmxlIG5hbWUg
Zm9yIHRoZSBhZ2VudC4KCgwKBQQAAgAFEgMfAggKDAoFBAACAAESAx8JDQoMCgUEAAIAAxID
HxARCgwKBQQAAgAIEgMfEjoKDwoIBAACAAicCAASAx8TOQpWCgQEAAIBEgMiAkIaSSBSZXF1
aXJlZC4gQSBkZXNjcmlwdGlvbiBvZiB0aGUgYWdlbnQncyBkb21haW4gb2YgYWN0aW9uL3Nv
bHV0aW9uIHNwYWNlLgoKDAoFBAACAQUSAyICCAoMCgUEAAIBARIDIgkUCgwKBQQAAgEDEgMi
FxgKDAoFBAACAQgSAyIZQQoPCggEAAIBCJwIABIDIhpACl4KBAQAAgISBCYCJy8aUCBSZXF1
aXJlZC4gT3JkZXJlZCBsaXN0IG9mIHN1cHBvcnRlZCBpbnRlcmZhY2VzLiBUaGUgZmlyc3Qg
ZW50cnkgaXMKIHByZWZlcnJlZC4KCgwKBQQAAgIEEgMmAgoKDAoFBAACAgYSAyYLGQoMCgUE
AAICARIDJhouCgwKBQQAAgIDEgMmMTIKDAoFBAACAggSAycGLgoPCggEAAICCJwIABIDJwct
CjIKBAQAAgMSAyoCPholIFJlcXVpcmVkLiBUaGUgdmVyc2lvbiBvZiB0aGUgYWdlbnQuCgoM
CgUEAAIDBRIDKgIICgwKBQQAAgMBEgMqCRAKDAoFBAACAwMSAyoTFAoMCgUEAAIDCBIDKhU9
Cg8KCAQAAgMInAgAEgMqFjwKywEKBAQAAgQSAy8CShq9ASBSZXF1aXJlZC4gU2tpbGxzIHJl
cHJlc2VudCBhIHVuaXQgb2YgYWJpbGl0eSBhbiBhZ2VudCBjYW4gcGVyZm9ybS4gVGhpcyBt
YXkKIHNvbWV3aGF0IGFic3RyYWN0IGJ1dCByZXByZXNlbnRzIGEgbW9yZSBmb2N1c2VkIHNl
dCBvZiBhY3Rpb25zIHRoYXQgdGhlCiBhZ2VudCBpcyBoaWdobHkgbGlrZWx5IHRvIHN1Y2Nl
ZWQgYXQuCgoMCgUEAAIEBBIDLwIKCgwKBQQAAgQGEgMvCxUKDAoFBAACBAESAy8WHAoMCgUE
AAIEAxIDLx8gCgwKBQQAAgQIEgMvIUkKDwoIBAACBAicCAASAy8iSArWAQoCBAESBDUARwEa
yQEgRGVjbGFyZXMgYSBjb21iaW5hdGlvbiBvZiBhIHRhcmdldCBVUkwsIHRyYW5zcG9ydCBh
bmQgcHJvdG9jb2wgdmVyc2lvbiBmb3IKIGludGVyYWN0aW5nIHdpdGggdGhlIGFnZW50LiBU
aGlzIGFsbG93cyBhZ2VudHMgdG8gZXhwb3NlIHRoZSBzYW1lCiBmdW5jdGlvbmFsaXR5IG92
ZXIgbXVsdGlwbGUgcHJvdG9jb2wgYmluZGluZyBtZWNoYW5pc21zLgoKCgoDBAEBEgM1CBYK
wgEKBAQBAgASAzkCOhq0ASBSZXF1aXJlZC4gVGhlIFVSTCB3aGVyZSB0aGlzIGludGVyZmFj
ZSBpcyBhdmFpbGFibGUuIE11c3QgYmUgYSB2YWxpZAogYWJzb2x1dGUgSFRUUFMgVVJMIGlu
IHByb2R1Y3Rpb24uIEV4YW1wbGU6CiAiaHR0cHM6Ly9hcGkuZXhhbXBsZS5jb20vYTJhL3Yx
IiwgImh0dHBzOi8vZ3JwYy5leGFtcGxlLmNvbS9hMmEiCgoMCgUEAQIABRIDOQIICgwKBQQB
AgABEgM5CQwKDAoFBAECAAMSAzkPEAoMCgUEAQIACBIDORE5Cg8KCAQBAgAInAgAEgM5EjgK
4QEKBAQBAgESAz4CRxrTASBSZXF1aXJlZC4gVGhlIHByb3RvY29sIGJpbmRpbmcgc3VwcG9y
dGVkIGF0IHRoaXMgVVJMLiBUaGlzIGlzIGFuIG9wZW4gZm9ybQogc3RyaW5nLCB0byBiZSBl
YXNpbHkgZXh0ZW5kZWQgZm9yIG90aGVyIHByb3RvY29sIGJpbmRpbmdzLiBUaGUgY29yZSBv
bmVzCiBvZmZpY2lhbGx5IHN1cHBvcnRlZCBhcmUgYEpTT05SUENgLCBgR1JQQ2AgYW5kIGBI
VFRQK0pTT05gLgoKDAoFBAECAQUSAz4CCAoMCgUEAQIBARIDPgkZCgwKBQQBAgEDEgM+HB0K
DAoFBAECAQgSAz4eRgoPCggEAQIBCJwIABIDPh9FCkoKBAQBAgISA0ECFBo9IFRlbmFudCBJ
RCB0byBiZSB1c2VkIGluIHRoZSByZXF1ZXN0IHdoZW4gY2FsbGluZyB0aGUgYWdlbnQuCgoM
CgUEAQICBRIDQQIICgwKBQQBAgIBEgNBCQ8KDAoFBAECAgMSA0ESEwqkAQoEBAECAxIDRgJH
GpYBIFJlcXVpcmVkLiBUaGUgdmVyc2lvbiBvZiB0aGUgQTJBIHByb3RvY29sIHRoaXMgaW50
ZXJmYWNlIGV4cG9zZXMuCiBVc2UgdGhlIGxhdGVzdCBzdXBwb3J0ZWQgbWlub3IgdmVyc2lv
biBwZXIgbWFqb3IgdmVyc2lvbi4KIEV4YW1wbGVzOiAiMC4zIiwgIjEuMCIKCgwKBQQBAgMF
EgNGAggKDAoFBAECAwESA0YJGQoMCgUEAQIDAxIDRhwdCgwKBQQBAgMIEgNGHkYKDwoIBAEC
AwicCAASA0YfRQpVCgIEAhIESgBhARpJIFJlcHJlc2VudHMgYSBkaXN0aW5jdCBjYXBhYmls
aXR5IG9yIGZ1bmN0aW9uIHRoYXQgYW4gYWdlbnQgY2FuIHBlcmZvcm0uCgoKCgMEAgESA0oI
EgpDCgQEAgIAEgNMAjkaNiBSZXF1aXJlZC4gQSB1bmlxdWUgaWRlbnRpZmllciBmb3IgdGhl
IGFnZW50J3Mgc2tpbGwuCgoMCgUEAgIABRIDTAIICgwKBQQCAgABEgNMCQsKDAoFBAICAAMS
A0wODwoMCgUEAgIACBIDTBA4Cg8KCAQCAgAInAgAEgNMETcKPQoEBAICARIDTwI7GjAgUmVx
dWlyZWQuIEEgaHVtYW4tcmVhZGFibGUgbmFtZSBmb3IgdGhlIHNraWxsLgoKDAoFBAICAQUS
A08CCAoMCgUEAgIBARIDTwkNCgwKBQQCAgEDEgNPEBEKDAoFBAICAQgSA08SOgoPCggEAgIB
CJwIABIDTxM5Cj0KBAQCAgISA1ICQhowIFJlcXVpcmVkLiBBIGRldGFpbGVkIGRlc2NyaXB0
aW9uIG9mIHRoZSBza2lsbC4KCgwKBQQCAgIFEgNSAggKDAoFBAICAgESA1IJFAoMCgUEAgIC
AxIDUhcYCgwKBQQCAgIIEgNSGUEKDwoIBAICAgicCAASA1IaQApPCgQEAgIDEgNVAkQaQiBS
ZXF1aXJlZC4gQSBzZXQgb2Yga2V5d29yZHMgZGVzY3JpYmluZyB0aGUgc2tpbGwncyBjYXBh
YmlsaXRpZXMuCgoMCgUEAgIDBBIDVQIKCgwKBQQCAgMFEgNVCxEKDAoFBAICAwESA1USFgoM
CgUEAgIDAxIDVRkaCgwKBQQCAgMIEgNVG0MKDwoIBAICAwicCAASA1UcQgpHCgQEAgIEEgNY
Ah8aOiBFeGFtcGxlIHByb21wdHMgb3Igc2NlbmFyaW9zIHRoYXQgdGhpcyBza2lsbCBjYW4g
aGFuZGxlLgoKDAoFBAICBAQSA1gCCgoMCgUEAgIEBRIDWAsRCgwKBQQCAgQBEgNYEhoKDAoF
BAICBAMSA1gdHgpnCgQEAgIFEgNcAiIaWiBUaGUgc2V0IG9mIHN1cHBvcnRlZCBpbnB1dCBt
ZWRpYSB0eXBlcyBmb3IgdGhpcyBza2lsbCwgb3ZlcnJpZGluZyB0aGUKIGFnZW50J3MgZGVm
YXVsdHMuCgoMCgUEAgIFBBIDXAIKCgwKBQQCAgUFEgNcCxEKDAoFBAICBQESA1wSHQoMCgUE
AgIFAxIDXCAhCmgKBAQCAgYSA2ACIxpbIFRoZSBzZXQgb2Ygc3VwcG9ydGVkIG91dHB1dCBt
ZWRpYSB0eXBlcyBmb3IgdGhpcyBza2lsbCwgb3ZlcnJpZGluZyB0aGUKIGFnZW50J3MgZGVm
YXVsdHMuCgoMCgUEAgIGBBIDYAIKCgwKBQQCAgYFEgNgCxEKDAoFBAICBgESA2ASHgoMCgUE
AgIGAxIDYCEiCm8KAgQDEgVlAIYBARpiIFNoYXJlZCBjb25maWd1cmF0aW9uIGZvciBjb25u
ZWN0aW5nIHRvIGEgcmVtb3RlCiBbQTJBXShodHRwczovL2dpdGh1Yi5jb20vYTJhcHJvamVj
dC9BMkEpIGFnZW50LgoKCgoDBAMBEgNlCBcKMgoEBAMIABIEZwJuAxokIFNwZWNpZmljYXRp
b24gb2YgdGhlIHJlbW90ZSBhZ2VudC4KCgwKBQQDCAABEgNnCBIKPAoEBAMCABIDaQRGGi8g
T3B0aW9uYWwuIFRoZSBmdWxsIGFnZW50IGNhcmQgZGVmaW5lZCBpbmxpbmUuCgoMCgUEAwIA
BhIDaQQNCgwKBQQDAgABEgNpDhgKDAoFBAMCAAMSA2kbHAoMCgUEAwIACBIDaR1FCg8KCAQD
AgAInAgAEgNpHkQKiAEKBAQDAgESA20ERxp7IE9wdGlvbmFsLiBSZWZlcmVuY2UgdG8gdGhl
IGFnZW50IGluIHRoZSBBZ2VudCBSZWdpc3RyeS4KIEZvcm1hdDogYHByb2plY3RzL3twcm9q
ZWN0fS9sb2NhdGlvbnMve2xvY2F0aW9ufS9hZ2VudHMve2FnZW50fWAKCgwKBQQDAgEFEgNt
BAoKDAoFBAMCAQESA20LGQoMCgUEAwIBAxIDbRwdCgwKBQQDAgEIEgNtHkYKDwoIBAMCAQic
CAASA20fRQqZAQoEBAMCAhIEcgJzLxqKASBPcHRpb25hbC4gQXV0aGVudGljYXRpb24gY29u
ZmlndXJhdGlvbiBmb3IgY2FsbGluZyB0aGUgcmVtb3RlIGFnZW50LgogT3B0aW9uYWwgaWYg
dGhlIHJlZ2lzdHJ5IHJlZmVyZW5jZSBhbHJlYWR5IGhhbmRsZXMgYXV0aGVudGljYXRpb24u
CgoMCgUEAwICBhIDcgITCgwKBQQDAgIBEgNyFCYKDAoFBAMCAgMSA3IpKgoMCgUEAwICCBID
cwYuCg8KCAQDAgIInAgAEgNzBy0KYgoEBAMCAxIEdwJ4LxpUIE9wdGlvbmFsLiBNYXBwaW5n
IG9mIGlucHV0IHZhcmlhYmxlIG5hbWVzIG9mIHJlbW90ZSBhZ2VudCB0byBHRUNYIHZhcmlh
YmxlCiBuYW1lcy4KCgwKBQQDAgMGEgN3AhUKDAoFBAMCAwESA3cWLAoMCgUEAwIDAxIDdy8w
CgwKBQQDAgMIEgN4Bi4KDwoIBAMCAwicCAASA3gHLQpjCgQEAwIEEgR8An0vGlUgT3B0aW9u
YWwuIE1hcHBpbmcgb2Ygb3V0cHV0IHZhcmlhYmxlIG5hbWVzIG9mIHJlbW90ZSBhZ2VudCB0
byBHRUNYIHZhcmlhYmxlCiBuYW1lcy4KCgwKBQQDAgQGEgN8AhUKDAoFBAMCBAESA3wWLQoM
CgUEAwIEAxIDfDAxCgwKBQQDAgQIEgN9Bi4KDwoIBAMCBAicCAASA30HLQpMCgQEAwIFEgSA
AQJGGj4gT3B0aW9uYWwuIFdoZXRoZXIgc3RyZWFtaW5nIGlzIGVuYWJsZWQgZm9yIHRoZSBy
ZW1vdGUgYWdlbnQuCgoNCgUEAwIFBRIEgAECBgoNCgUEAwIFARIEgAEHGAoNCgUEAwIFAxIE
gAEbHAoNCgUEAwIFCBIEgAEdRQoQCggEAwIFCJwIABIEgAEeRArTAQoEBAMCBhIEhQECQRrE
ASBPcHRpb25hbC4gSWYgbm90IGVtcHR5LCBpbnRlcmFjdGlvbnMgd2l0aCB0aGUgcmVtb3Rl
IEEyQSBhZ2VudCB3aWxsIHVzZQogdGhpcyBjb250ZXh0IElELiBUaGlzIGNvbnRleHRfaWQg
ZmllbGQgY2FuIHJlZmVyIHRvIGEgc2Vzc2lvbiB2YXJpYWJsZSBsaWtlCiBgJGNvbnRleHQu
dmFyaWFibGVzLm9yZGVyX2FnZW50X3Nlc3Npb25faWRgLgoKDQoFBAMCBgUSBIUBAggKDQoF
BAMCBgESBIUBCRMKDQoFBAMCBgMSBIUBFhcKDQoFBAMCBggSBIUBGEAKEAoIBAMCBgicCAAS
BIUBGT8KVQoCBAQSBokBAKYBARpHIFJlcHJlc2VudHMgYSB0b29sIHRoYXQgYWxsb3dzIHRo
ZSBhZ2VudCB0byBjYWxsIGFub3RoZXIgcmVtb3RlIGFnZW50LgoKCwoDBAQBEgSJAQgXCi8K
BAQEAgASBIsBAjsaISBSZXF1aXJlZC4gVGhlIG5hbWUgb2YgdGhlIHRvb2wuCgoNCgUEBAIA
BRIEiwECCAoNCgUEBAIAARIEiwEJDQoNCgUEBAIAAxIEiwEQEQoNCgUEBAIACBIEiwESOgoQ
CggEBAIACJwIABIEiwETOQo2CgQEBAIBEgSOAQJCGiggUmVxdWlyZWQuIFRoZSBkZXNjcmlw
dGlvbiBvZiB0aGUgdG9vbC4KCg0KBQQEAgEFEgSOAQIICg0KBQQEAgEBEgSOAQkUCg0KBQQE
AgEDEgSOARcYCg0KBQQEAgEIEgSOARlBChAKCAQEAgEInAgAEgSOARpAClQKBAQEAgISBJEB
AkQaRiBSZXF1aXJlZC4gVGhlIGFnZW50IGNhcmQgb2YgdGhlIHJlbW90ZSBhZ2VudCB0aGF0
IHRoaXMgdG9vbCBpbnZva2VzLgoKDQoFBAQCAgYSBJEBAgsKDQoFBAQCAgESBJEBDBYKDQoF
BAQCAgMSBJEBGRoKDQoFBAQCAggSBJEBG0MKEAoIBAQCAgicCAASBJEBHEIKVgoEBAQCAxIG
lAEClQEvGkYgT3B0aW9uYWwuIEF1dGhlbnRpY2F0aW9uIGNvbmZpZ3VyYXRpb24gZm9yIGNh
bGxpbmcgdGhlIHJlbW90ZSBhZ2VudC4KCg0KBQQEAgMGEgSUAQITCg0KBQQEAgMBEgSUARQm
Cg0KBQQEAgMDEgSUASkqCg0KBQQEAgMIEgSVAQYuChAKCAQEAgMInAgAEgSVAQctCv0BCgQE
BAIEEgSbAQJDGu4BIE9wdGlvbmFsLiBXaGVuIGVuYWJsZWQsIHRoZSBpbnRlcmFjdGlvbiBi
ZXR3ZWVuIHRoZSBDWEFTIGFwcCBhbmQgdGhlIHJlbW90ZQogYWdlbnQgd2lsbCBzaGFyZSB0
aGUgc2FtZSBjb250ZXh0LiBJZiB0aGUgcmVtb3RlIGFnZW50IHJldHVybnMgYQogY29udGV4
dF9pZCwgaXQgd2lsbCBiZSBwZXJzaXN0ZWQgZm9yIHRoZSBlbnRpcmV0eSBvZiB0aGUgc2Vz
c2lvbiBmb3IgdGhpcwogcmVtb3RlIGFnZW50IHRvb2wuCgoNCgUEBAIEBRIEmwECBgoNCgUE
BAIEARIEmwEHFQoNCgUEBAIEAxIEmwEYGQoNCgUEBAIECBIEmwEaQgoQCggEBAIECJwIABIE
mwEbQQpkCgQEBAIFEgafAQKgAS8aVCBPcHRpb25hbC4gTWFwcGluZyBvZiBpbnB1dCB2YXJp
YWJsZSBuYW1lcyBvZiByZW1vdGUgYWdlbnQgdG8gR0VDWCB2YXJpYWJsZQogbmFtZXMuCgoN
CgUEBAIFBhIEnwECFQoNCgUEBAIFARIEnwEWLAoNCgUEBAIFAxIEnwEvMAoNCgUEBAIFCBIE
oAEGLgoQCggEBAIFCJwIABIEoAEHLQplCgQEBAIGEgakAQKlAS8aVSBPcHRpb25hbC4gTWFw
cGluZyBvZiBvdXRwdXQgdmFyaWFibGUgbmFtZXMgb2YgcmVtb3RlIGFnZW50IHRvIEdFQ1gg
dmFyaWFibGUKIG5hbWVzLgoKDQoFBAQCBgYSBKQBAhUKDQoFBAQCBgESBKQBFi0KDQoFBAQC
BgMSBKQBMDEKDQoFBAQCBggSBKUBBi4KEAoIBAQCBgicCAASBKUBBy1iBnByb3RvMw==
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Ces::V1beta::AgentCard::AgentCard ===
    # Fields for AgentCard
    # Field: name Type: 9 ()
    # Field: description Type: 9 ()
    # Field: supported_interfaces Type: 11 (.google.cloud.ces.v1beta.AgentInterface)
    # Field: version Type: 9 ()
    # Field: skills Type: 11 (.google.cloud.ces.v1beta.AgentSkill)

# === Message: Google::Cloud::Ces::V1beta::AgentCard::AgentInterface ===
    # Fields for AgentInterface
    # Field: url Type: 9 ()
    # Field: protocol_binding Type: 9 ()
    # Field: tenant Type: 9 ()
    # Field: protocol_version Type: 9 ()

# === Message: Google::Cloud::Ces::V1beta::AgentCard::AgentSkill ===
    # Fields for AgentSkill
    # Field: id Type: 9 ()
    # Field: name Type: 9 ()
    # Field: description Type: 9 ()
    # Field: tags Type: 9 ()
    # Field: examples Type: 9 ()
    # Field: input_modes Type: 9 ()
    # Field: output_modes Type: 9 ()

# === Message: Google::Cloud::Ces::V1beta::AgentCard::RemoteA2aConfig ===
    # Fields for RemoteA2aConfig
    # Field: agent_card Type: 11 (.google.cloud.ces.v1beta.AgentCard)
    # Field: agent_registry Type: 9 ()
    # Field: api_authentication Type: 11 (.google.cloud.ces.v1beta.ApiAuthentication)
    # Field: input_variable_mapping Type: 11 (.google.cloud.ces.v1beta.RemoteA2aConfig.InputVariableMappingEntry)
    # Field: output_variable_mapping Type: 11 (.google.cloud.ces.v1beta.RemoteA2aConfig.OutputVariableMappingEntry)
    # Field: streaming_enabled Type: 8 ()
    # Field: context_id Type: 9 ()

# === Message: Google::Cloud::Ces::V1beta::AgentCard::RemoteAgentTool ===
    # Fields for RemoteAgentTool
    # Field: name Type: 9 ()
    # Field: description Type: 9 ()
    # Field: agent_card Type: 11 (.google.cloud.ces.v1beta.AgentCard)
    # Field: api_authentication Type: 11 (.google.cloud.ces.v1beta.ApiAuthentication)
    # Field: stateful_agent Type: 8 ()
    # Field: input_variable_mapping Type: 11 (.google.cloud.ces.v1beta.RemoteAgentTool.InputVariableMappingEntry)
    # Field: output_variable_mapping Type: 11 (.google.cloud.ces.v1beta.RemoteAgentTool.OutputVariableMappingEntry)

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Ces::V1beta::AgentCard - Compiled Protocol Buffers messages for google/cloud/ces/v1beta/agent_card.proto

=head1 SYNOPSIS

    use Google::Cloud::Ces::V1beta::AgentCard;

    my $msg = Google::Cloud::Ces::V1beta::AgentCard::AgentCard->new({
        name => $name,
        description => $description,
        supported_interfaces => $supported_interfaces,
        version => $version,
    });

    # Read or update a field
    my $val = $msg->name();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Ces::V1beta::AgentCard::AgentCard->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/ces/v1beta/agent_card.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Ces::V1beta::AgentCard::AgentCard

AgentCard conveys key information about a remote agent.
It is a trimmed version of the AgentCard defined in the A2A protocol
https://a2a-protocol.org/dev/specification/#441-agentcard

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. A human-readable name for the agent.

=item * C<< $msg->description() >> / C<< $msg->description($value) >>

Type: C<String>

Required. A description of the agent's domain of action/solution space.

=item * C<< $msg->supported_interfaces() >> / C<< $msg->supported_interfaces($value) >>

Type: C<Message> (L<Google::Cloud::Ces::V1beta::AgentCard::AgentInterface>)

Required. Ordered list of supported interfaces. The first entry is
preferred.

=item * C<< $msg->version() >> / C<< $msg->version($value) >>

Type: C<String>

Required. The version of the agent.

=item * C<< $msg->skills() >> / C<< $msg->skills($value) >>

Type: C<Message> (L<Google::Cloud::Ces::V1beta::AgentCard::AgentSkill>)

Required. Skills represent a unit of ability an agent can perform. This may
somewhat abstract but represents a more focused set of actions that the
agent is highly likely to succeed at.

=back

=head2 Google::Cloud::Ces::V1beta::AgentCard::AgentInterface

Declares a combination of a target URL, transport and protocol version for
interacting with the agent. This allows agents to expose the same
functionality over multiple protocol binding mechanisms.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->url() >> / C<< $msg->url($value) >>

Type: C<String>

Required. The URL where this interface is available. Must be a valid
absolute HTTPS URL in production. Example:
"https://api.example.com/a2a/v1", "https://grpc.example.com/a2a"

=item * C<< $msg->protocol_binding() >> / C<< $msg->protocol_binding($value) >>

Type: C<String>

Required. The protocol binding supported at this URL. This is an open form
string, to be easily extended for other protocol bindings. The core ones
officially supported are `JSONRPC`, `GRPC` and `HTTP+JSON`.

=item * C<< $msg->tenant() >> / C<< $msg->tenant($value) >>

Type: C<String>

Tenant ID to be used in the request when calling the agent.

=item * C<< $msg->protocol_version() >> / C<< $msg->protocol_version($value) >>

Type: C<String>

Required. The version of the A2A protocol this interface exposes.
Use the latest supported minor version per major version.
Examples: "0.3", "1.0"

=back

=head2 Google::Cloud::Ces::V1beta::AgentCard::AgentSkill

Represents a distinct capability or function that an agent can perform.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->id() >> / C<< $msg->id($value) >>

Type: C<String>

Required. A unique identifier for the agent's skill.

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. A human-readable name for the skill.

=item * C<< $msg->description() >> / C<< $msg->description($value) >>

Type: C<String>

Required. A detailed description of the skill.

=item * C<< $msg->tags() >> / C<< $msg->tags($value) >>

Type: C<String>

Required. A set of keywords describing the skill's capabilities.

=item * C<< $msg->examples() >> / C<< $msg->examples($value) >>

Type: C<String>

Example prompts or scenarios that this skill can handle.

=item * C<< $msg->input_modes() >> / C<< $msg->input_modes($value) >>

Type: C<String>

The set of supported input media types for this skill, overriding the
agent's defaults.

=item * C<< $msg->output_modes() >> / C<< $msg->output_modes($value) >>

Type: C<String>

The set of supported output media types for this skill, overriding the
agent's defaults.

=back

=head2 Google::Cloud::Ces::V1beta::AgentCard::RemoteA2aConfig

Shared configuration for connecting to a remote
[A2A](https://github.com/a2aproject/A2A) agent.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->agent_card() >> / C<< $msg->agent_card($value) >>

Type: C<Message> (L<Google::Cloud::Ces::V1beta::AgentCard::AgentCard>)

Optional. The full agent card defined inline.

=item * C<< $msg->agent_registry() >> / C<< $msg->agent_registry($value) >>

Type: C<String>

Optional. Reference to the agent in the Agent Registry.
Format: `projects/{project}/locations/{location}/agents/{agent}`

=item * C<< $msg->api_authentication() >> / C<< $msg->api_authentication($value) >>

Type: C<Message> (L<Google::Cloud::Ces::V1beta::Auth::ApiAuthentication>)

Optional. Authentication configuration for calling the remote agent.
Optional if the registry reference already handles authentication.

=item * C<< $msg->input_variable_mapping() >> / C<< $msg->input_variable_mapping($value) >>

Type: C<Message> (L<Google::Cloud::Ces::V1beta::AgentCard::RemoteA2aConfig::InputVariableMappingEntry>)

Optional. Mapping of input variable names of remote agent to GECX variable
names.

=item * C<< $msg->output_variable_mapping() >> / C<< $msg->output_variable_mapping($value) >>

Type: C<Message> (L<Google::Cloud::Ces::V1beta::AgentCard::RemoteA2aConfig::OutputVariableMappingEntry>)

Optional. Mapping of output variable names of remote agent to GECX variable
names.

=item * C<< $msg->streaming_enabled() >> / C<< $msg->streaming_enabled($value) >>

Type: C<Bool>

Optional. Whether streaming is enabled for the remote agent.

=item * C<< $msg->context_id() >> / C<< $msg->context_id($value) >>

Type: C<String>

Optional. If not empty, interactions with the remote A2A agent will use
this context ID. This context_id field can refer to a session variable like
`$context.variables.order_agent_session_id`.

=back

=head2 Google::Cloud::Ces::V1beta::AgentCard::RemoteAgentTool

Represents a tool that allows the agent to call another remote agent.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. The name of the tool.

=item * C<< $msg->description() >> / C<< $msg->description($value) >>

Type: C<String>

Required. The description of the tool.

=item * C<< $msg->agent_card() >> / C<< $msg->agent_card($value) >>

Type: C<Message> (L<Google::Cloud::Ces::V1beta::AgentCard::AgentCard>)

Required. The agent card of the remote agent that this tool invokes.

=item * C<< $msg->api_authentication() >> / C<< $msg->api_authentication($value) >>

Type: C<Message> (L<Google::Cloud::Ces::V1beta::Auth::ApiAuthentication>)

Optional. Authentication configuration for calling the remote agent.

=item * C<< $msg->stateful_agent() >> / C<< $msg->stateful_agent($value) >>

Type: C<Bool>

Optional. When enabled, the interaction between the CXAS app and the remote
agent will share the same context. If the remote agent returns a
context_id, it will be persisted for the entirety of the session for this
remote agent tool.

=item * C<< $msg->input_variable_mapping() >> / C<< $msg->input_variable_mapping($value) >>

Type: C<Message> (L<Google::Cloud::Ces::V1beta::AgentCard::RemoteAgentTool::InputVariableMappingEntry>)

Optional. Mapping of input variable names of remote agent to GECX variable
names.

=item * C<< $msg->output_variable_mapping() >> / C<< $msg->output_variable_mapping($value) >>

Type: C<Message> (L<Google::Cloud::Ces::V1beta::AgentCard::RemoteAgentTool::OutputVariableMappingEntry>)

Optional. Mapping of output variable names of remote agent to GECX variable
names.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Ces::V1beta::AgentCard::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
