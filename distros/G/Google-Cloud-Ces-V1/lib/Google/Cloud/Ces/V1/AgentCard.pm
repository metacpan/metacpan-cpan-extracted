package Google::Cloud::Ces::V1::AgentCard;

use strict;
use warnings;

our $VERSION = '0.14';

use Protobuf::Message;
use Protobuf::DescriptorPool;
use Protobuf::Internal qw(:all);
use MIME::Base64;

BEGIN {
    eval { require Google::Api::FieldBehavior };
    eval { require Google::Cloud::Ces::V1::Auth };
    my $descriptor_b64 = <<'EOF';
CiRnb29nbGUvY2xvdWQvY2VzL3YxL2FnZW50X2NhcmQucHJvdG8SE2dvb2dsZS5jbG91ZC5j
ZXMudjEaH2dvb2dsZS9hcGkvZmllbGRfYmVoYXZpb3IucHJvdG8aHmdvb2dsZS9jbG91ZC9j
ZXMvdjEvYXV0aC5wcm90byKFAgoJQWdlbnRDYXJkEhcKBG5hbWUYASABKAlCA+BBAlIEbmFt
ZRIlCgtkZXNjcmlwdGlvbhgCIAEoCUID4EECUgtkZXNjcmlwdGlvbhJbChRzdXBwb3J0ZWRf
aW50ZXJmYWNlcxgDIAMoCzIjLmdvb2dsZS5jbG91ZC5jZXMudjEuQWdlbnRJbnRlcmZhY2VC
A+BBAlITc3VwcG9ydGVkSW50ZXJmYWNlcxIdCgd2ZXJzaW9uGAUgASgJQgPgQQJSB3ZlcnNp
b24SPAoGc2tpbGxzGAYgAygLMh8uZ29vZ2xlLmNsb3VkLmNlcy52MS5BZ2VudFNraWxsQgPg
QQJSBnNraWxscyKfAQoOQWdlbnRJbnRlcmZhY2USFQoDdXJsGAEgASgJQgPgQQJSA3VybBIu
ChBwcm90b2NvbF9iaW5kaW5nGAIgASgJQgPgQQJSD3Byb3RvY29sQmluZGluZxIWCgZ0ZW5h
bnQYAyABKAlSBnRlbmFudBIuChBwcm90b2NvbF92ZXJzaW9uGAQgASgJQgPgQQJSD3Byb3Rv
Y29sVmVyc2lvbiLaAQoKQWdlbnRTa2lsbBITCgJpZBgBIAEoCUID4EECUgJpZBIXCgRuYW1l
GAIgASgJQgPgQQJSBG5hbWUSJQoLZGVzY3JpcHRpb24YAyABKAlCA+BBAlILZGVzY3JpcHRp
b24SFwoEdGFncxgEIAMoCUID4EECUgR0YWdzEhoKCGV4YW1wbGVzGAUgAygJUghleGFtcGxl
cxIfCgtpbnB1dF9tb2RlcxgGIAMoCVIKaW5wdXRNb2RlcxIhCgxvdXRwdXRfbW9kZXMYByAD
KAlSC291dHB1dE1vZGVzIqkFCg9SZW1vdGVBZ2VudFRvb2wSFwoEbmFtZRgBIAEoCUID4EEC
UgRuYW1lEiUKC2Rlc2NyaXB0aW9uGAIgASgJQgPgQQJSC2Rlc2NyaXB0aW9uEkIKCmFnZW50
X2NhcmQYAyABKAsyHi5nb29nbGUuY2xvdWQuY2VzLnYxLkFnZW50Q2FyZEID4EECUglhZ2Vu
dENhcmQSWgoSYXBpX2F1dGhlbnRpY2F0aW9uGAQgASgLMiYuZ29vZ2xlLmNsb3VkLmNlcy52
MS5BcGlBdXRoZW50aWNhdGlvbkID4EEBUhFhcGlBdXRoZW50aWNhdGlvbhIqCg5zdGF0ZWZ1
bF9hZ2VudBgFIAEoCEID4EEBUg1zdGF0ZWZ1bEFnZW50EnkKFmlucHV0X3ZhcmlhYmxlX21h
cHBpbmcYBiADKAsyPi5nb29nbGUuY2xvdWQuY2VzLnYxLlJlbW90ZUFnZW50VG9vbC5JbnB1
dFZhcmlhYmxlTWFwcGluZ0VudHJ5QgPgQQFSFGlucHV0VmFyaWFibGVNYXBwaW5nEnwKF291
dHB1dF92YXJpYWJsZV9tYXBwaW5nGAcgAygLMj8uZ29vZ2xlLmNsb3VkLmNlcy52MS5SZW1v
dGVBZ2VudFRvb2wuT3V0cHV0VmFyaWFibGVNYXBwaW5nRW50cnlCA+BBAVIVb3V0cHV0VmFy
aWFibGVNYXBwaW5nGkcKGUlucHV0VmFyaWFibGVNYXBwaW5nRW50cnkSEAoDa2V5GAEgASgJ
UgNrZXkSFAoFdmFsdWUYAiABKAlSBXZhbHVlOgI4ARpIChpPdXRwdXRWYXJpYWJsZU1hcHBp
bmdFbnRyeRIQCgNrZXkYASABKAlSA2tleRIUCgV2YWx1ZRgCIAEoCVIFdmFsdWU6AjgBQlYK
F2NvbS5nb29nbGUuY2xvdWQuY2VzLnYxQg5BZ2VudENhcmRQcm90b1ABWiljbG91ZC5nb29n
bGUuY29tL2dvL2Nlcy9hcGl2MS9jZXNwYjtjZXNwYkrFKgoHEgUOAIEBAQq8BAoBDBIDDgAS
MrEEIENvcHlyaWdodCAyMDI2IEdvb2dsZSBMTEMKCiBMaWNlbnNlZCB1bmRlciB0aGUgQXBh
Y2hlIExpY2Vuc2UsIFZlcnNpb24gMi4wICh0aGUgIkxpY2Vuc2UiKTsKIHlvdSBtYXkgbm90
IHVzZSB0aGlzIGZpbGUgZXhjZXB0IGluIGNvbXBsaWFuY2Ugd2l0aCB0aGUgTGljZW5zZS4K
IFlvdSBtYXkgb2J0YWluIGEgY29weSBvZiB0aGUgTGljZW5zZSBhdAoKICAgICBodHRwOi8v
d3d3LmFwYWNoZS5vcmcvbGljZW5zZXMvTElDRU5TRS0yLjAKCiBVbmxlc3MgcmVxdWlyZWQg
YnkgYXBwbGljYWJsZSBsYXcgb3IgYWdyZWVkIHRvIGluIHdyaXRpbmcsIHNvZnR3YXJlCiBk
aXN0cmlidXRlZCB1bmRlciB0aGUgTGljZW5zZSBpcyBkaXN0cmlidXRlZCBvbiBhbiAiQVMg
SVMiIEJBU0lTLAogV0lUSE9VVCBXQVJSQU5USUVTIE9SIENPTkRJVElPTlMgT0YgQU5ZIEtJ
TkQsIGVpdGhlciBleHByZXNzIG9yIGltcGxpZWQuCiBTZWUgdGhlIExpY2Vuc2UgZm9yIHRo
ZSBzcGVjaWZpYyBsYW5ndWFnZSBnb3Zlcm5pbmcgcGVybWlzc2lvbnMgYW5kCiBsaW1pdGF0
aW9ucyB1bmRlciB0aGUgTGljZW5zZS4KCggKAQISAxAAHAoJCgIDABIDEgApCgkKAgMBEgMT
ACgKCAoBCBIDFQBACgkKAggLEgMVAEAKCAoBCBIDFgAiCgkKAggKEgMWACIKCAoBCBIDFwAv
CgkKAggIEgMXAC8KCAoBCBIDGAAwCgkKAggBEgMYADAKxwEKAgQAEgQdADABGroBIEFnZW50
Q2FyZCBjb252ZXlzIGtleSBpbmZvcm1hdGlvbiBhYm91dCBhIHJlbW90ZSBhZ2VudC4KIEl0
IGlzIGEgdHJpbW1lZCB2ZXJzaW9uIG9mIHRoZSBBZ2VudENhcmQgZGVmaW5lZCBpbiB0aGUg
QTJBIHByb3RvY29sCiBodHRwczovL2EyYS1wcm90b2NvbC5vcmcvZGV2L3NwZWNpZmljYXRp
b24vIzQ0MS1hZ2VudGNhcmQKCgoKAwQAARIDHQgRCj0KBAQAAgASAx8COxowIFJlcXVpcmVk
LiBBIGh1bWFuLXJlYWRhYmxlIG5hbWUgZm9yIHRoZSBhZ2VudC4KCgwKBQQAAgAFEgMfAggK
DAoFBAACAAESAx8JDQoMCgUEAAIAAxIDHxARCgwKBQQAAgAIEgMfEjoKDwoIBAACAAicCAAS
Ax8TOQpWCgQEAAIBEgMiAkIaSSBSZXF1aXJlZC4gQSBkZXNjcmlwdGlvbiBvZiB0aGUgYWdl
bnQncyBkb21haW4gb2YgYWN0aW9uL3NvbHV0aW9uIHNwYWNlLgoKDAoFBAACAQUSAyICCAoM
CgUEAAIBARIDIgkUCgwKBQQAAgEDEgMiFxgKDAoFBAACAQgSAyIZQQoPCggEAAIBCJwIABID
IhpACl4KBAQAAgISBCYCJy8aUCBSZXF1aXJlZC4gT3JkZXJlZCBsaXN0IG9mIHN1cHBvcnRl
ZCBpbnRlcmZhY2VzLiBUaGUgZmlyc3QgZW50cnkgaXMKIHByZWZlcnJlZC4KCgwKBQQAAgIE
EgMmAgoKDAoFBAACAgYSAyYLGQoMCgUEAAICARIDJhouCgwKBQQAAgIDEgMmMTIKDAoFBAAC
AggSAycGLgoPCggEAAICCJwIABIDJwctCjIKBAQAAgMSAyoCPholIFJlcXVpcmVkLiBUaGUg
dmVyc2lvbiBvZiB0aGUgYWdlbnQuCgoMCgUEAAIDBRIDKgIICgwKBQQAAgMBEgMqCRAKDAoF
BAACAwMSAyoTFAoMCgUEAAIDCBIDKhU9Cg8KCAQAAgMInAgAEgMqFjwKywEKBAQAAgQSAy8C
Shq9ASBSZXF1aXJlZC4gU2tpbGxzIHJlcHJlc2VudCBhIHVuaXQgb2YgYWJpbGl0eSBhbiBh
Z2VudCBjYW4gcGVyZm9ybS4gVGhpcyBtYXkKIHNvbWV3aGF0IGFic3RyYWN0IGJ1dCByZXBy
ZXNlbnRzIGEgbW9yZSBmb2N1c2VkIHNldCBvZiBhY3Rpb25zIHRoYXQgdGhlCiBhZ2VudCBp
cyBoaWdobHkgbGlrZWx5IHRvIHN1Y2NlZWQgYXQuCgoMCgUEAAIEBBIDLwIKCgwKBQQAAgQG
EgMvCxUKDAoFBAACBAESAy8WHAoMCgUEAAIEAxIDLx8gCgwKBQQAAgQIEgMvIUkKDwoIBAAC
BAicCAASAy8iSArWAQoCBAESBDUARwEayQEgRGVjbGFyZXMgYSBjb21iaW5hdGlvbiBvZiBh
IHRhcmdldCBVUkwsIHRyYW5zcG9ydCBhbmQgcHJvdG9jb2wgdmVyc2lvbiBmb3IKIGludGVy
YWN0aW5nIHdpdGggdGhlIGFnZW50LiBUaGlzIGFsbG93cyBhZ2VudHMgdG8gZXhwb3NlIHRo
ZSBzYW1lCiBmdW5jdGlvbmFsaXR5IG92ZXIgbXVsdGlwbGUgcHJvdG9jb2wgYmluZGluZyBt
ZWNoYW5pc21zLgoKCgoDBAEBEgM1CBYKwgEKBAQBAgASAzkCOhq0ASBSZXF1aXJlZC4gVGhl
IFVSTCB3aGVyZSB0aGlzIGludGVyZmFjZSBpcyBhdmFpbGFibGUuIE11c3QgYmUgYSB2YWxp
ZAogYWJzb2x1dGUgSFRUUFMgVVJMIGluIHByb2R1Y3Rpb24uIEV4YW1wbGU6CiAiaHR0cHM6
Ly9hcGkuZXhhbXBsZS5jb20vYTJhL3YxIiwgImh0dHBzOi8vZ3JwYy5leGFtcGxlLmNvbS9h
MmEiCgoMCgUEAQIABRIDOQIICgwKBQQBAgABEgM5CQwKDAoFBAECAAMSAzkPEAoMCgUEAQIA
CBIDORE5Cg8KCAQBAgAInAgAEgM5EjgK4QEKBAQBAgESAz4CRxrTASBSZXF1aXJlZC4gVGhl
IHByb3RvY29sIGJpbmRpbmcgc3VwcG9ydGVkIGF0IHRoaXMgVVJMLiBUaGlzIGlzIGFuIG9w
ZW4gZm9ybQogc3RyaW5nLCB0byBiZSBlYXNpbHkgZXh0ZW5kZWQgZm9yIG90aGVyIHByb3Rv
Y29sIGJpbmRpbmdzLiBUaGUgY29yZSBvbmVzCiBvZmZpY2lhbGx5IHN1cHBvcnRlZCBhcmUg
YEpTT05SUENgLCBgR1JQQ2AgYW5kIGBIVFRQK0pTT05gLgoKDAoFBAECAQUSAz4CCAoMCgUE
AQIBARIDPgkZCgwKBQQBAgEDEgM+HB0KDAoFBAECAQgSAz4eRgoPCggEAQIBCJwIABIDPh9F
CkoKBAQBAgISA0ECFBo9IFRlbmFudCBJRCB0byBiZSB1c2VkIGluIHRoZSByZXF1ZXN0IHdo
ZW4gY2FsbGluZyB0aGUgYWdlbnQuCgoMCgUEAQICBRIDQQIICgwKBQQBAgIBEgNBCQ8KDAoF
BAECAgMSA0ESEwqkAQoEBAECAxIDRgJHGpYBIFJlcXVpcmVkLiBUaGUgdmVyc2lvbiBvZiB0
aGUgQTJBIHByb3RvY29sIHRoaXMgaW50ZXJmYWNlIGV4cG9zZXMuCiBVc2UgdGhlIGxhdGVz
dCBzdXBwb3J0ZWQgbWlub3IgdmVyc2lvbiBwZXIgbWFqb3IgdmVyc2lvbi4KIEV4YW1wbGVz
OiAiMC4zIiwgIjEuMCIKCgwKBQQBAgMFEgNGAggKDAoFBAECAwESA0YJGQoMCgUEAQIDAxID
RhwdCgwKBQQBAgMIEgNGHkYKDwoIBAECAwicCAASA0YfRQpVCgIEAhIESgBhARpJIFJlcHJl
c2VudHMgYSBkaXN0aW5jdCBjYXBhYmlsaXR5IG9yIGZ1bmN0aW9uIHRoYXQgYW4gYWdlbnQg
Y2FuIHBlcmZvcm0uCgoKCgMEAgESA0oIEgpDCgQEAgIAEgNMAjkaNiBSZXF1aXJlZC4gQSB1
bmlxdWUgaWRlbnRpZmllciBmb3IgdGhlIGFnZW50J3Mgc2tpbGwuCgoMCgUEAgIABRIDTAII
CgwKBQQCAgABEgNMCQsKDAoFBAICAAMSA0wODwoMCgUEAgIACBIDTBA4Cg8KCAQCAgAInAgA
EgNMETcKPQoEBAICARIDTwI7GjAgUmVxdWlyZWQuIEEgaHVtYW4tcmVhZGFibGUgbmFtZSBm
b3IgdGhlIHNraWxsLgoKDAoFBAICAQUSA08CCAoMCgUEAgIBARIDTwkNCgwKBQQCAgEDEgNP
EBEKDAoFBAICAQgSA08SOgoPCggEAgIBCJwIABIDTxM5Cj0KBAQCAgISA1ICQhowIFJlcXVp
cmVkLiBBIGRldGFpbGVkIGRlc2NyaXB0aW9uIG9mIHRoZSBza2lsbC4KCgwKBQQCAgIFEgNS
AggKDAoFBAICAgESA1IJFAoMCgUEAgICAxIDUhcYCgwKBQQCAgIIEgNSGUEKDwoIBAICAgic
CAASA1IaQApPCgQEAgIDEgNVAkQaQiBSZXF1aXJlZC4gQSBzZXQgb2Yga2V5d29yZHMgZGVz
Y3JpYmluZyB0aGUgc2tpbGwncyBjYXBhYmlsaXRpZXMuCgoMCgUEAgIDBBIDVQIKCgwKBQQC
AgMFEgNVCxEKDAoFBAICAwESA1USFgoMCgUEAgIDAxIDVRkaCgwKBQQCAgMIEgNVG0MKDwoI
BAICAwicCAASA1UcQgpHCgQEAgIEEgNYAh8aOiBFeGFtcGxlIHByb21wdHMgb3Igc2NlbmFy
aW9zIHRoYXQgdGhpcyBza2lsbCBjYW4gaGFuZGxlLgoKDAoFBAICBAQSA1gCCgoMCgUEAgIE
BRIDWAsRCgwKBQQCAgQBEgNYEhoKDAoFBAICBAMSA1gdHgpnCgQEAgIFEgNcAiIaWiBUaGUg
c2V0IG9mIHN1cHBvcnRlZCBpbnB1dCBtZWRpYSB0eXBlcyBmb3IgdGhpcyBza2lsbCwgb3Zl
cnJpZGluZyB0aGUKIGFnZW50J3MgZGVmYXVsdHMuCgoMCgUEAgIFBBIDXAIKCgwKBQQCAgUF
EgNcCxEKDAoFBAICBQESA1wSHQoMCgUEAgIFAxIDXCAhCmgKBAQCAgYSA2ACIxpbIFRoZSBz
ZXQgb2Ygc3VwcG9ydGVkIG91dHB1dCBtZWRpYSB0eXBlcyBmb3IgdGhpcyBza2lsbCwgb3Zl
cnJpZGluZyB0aGUKIGFnZW50J3MgZGVmYXVsdHMuCgoMCgUEAgIGBBIDYAIKCgwKBQQCAgYF
EgNgCxEKDAoFBAICBgESA2ASHgoMCgUEAgIGAxIDYCEiClQKAgQDEgVkAIEBARpHIFJlcHJl
c2VudHMgYSB0b29sIHRoYXQgYWxsb3dzIHRoZSBhZ2VudCB0byBjYWxsIGFub3RoZXIgcmVt
b3RlIGFnZW50LgoKCgoDBAMBEgNkCBcKLgoEBAMCABIDZgI7GiEgUmVxdWlyZWQuIFRoZSBu
YW1lIG9mIHRoZSB0b29sLgoKDAoFBAMCAAUSA2YCCAoMCgUEAwIAARIDZgkNCgwKBQQDAgAD
EgNmEBEKDAoFBAMCAAgSA2YSOgoPCggEAwIACJwIABIDZhM5CjUKBAQDAgESA2kCQhooIFJl
cXVpcmVkLiBUaGUgZGVzY3JpcHRpb24gb2YgdGhlIHRvb2wuCgoMCgUEAwIBBRIDaQIICgwK
BQQDAgEBEgNpCRQKDAoFBAMCAQMSA2kXGAoMCgUEAwIBCBIDaRlBCg8KCAQDAgEInAgAEgNp
GkAKUwoEBAMCAhIDbAJEGkYgUmVxdWlyZWQuIFRoZSBhZ2VudCBjYXJkIG9mIHRoZSByZW1v
dGUgYWdlbnQgdGhhdCB0aGlzIHRvb2wgaW52b2tlcy4KCgwKBQQDAgIGEgNsAgsKDAoFBAMC
AgESA2wMFgoMCgUEAwICAxIDbBkaCgwKBQQDAgIIEgNsG0MKDwoIBAMCAgicCAASA2wcQgpU
CgQEAwIDEgRvAnAvGkYgT3B0aW9uYWwuIEF1dGhlbnRpY2F0aW9uIGNvbmZpZ3VyYXRpb24g
Zm9yIGNhbGxpbmcgdGhlIHJlbW90ZSBhZ2VudC4KCgwKBQQDAgMGEgNvAhMKDAoFBAMCAwES
A28UJgoMCgUEAwIDAxIDbykqCgwKBQQDAgMIEgNwBi4KDwoIBAMCAwicCAASA3AHLQr8AQoE
BAMCBBIDdgJDGu4BIE9wdGlvbmFsLiBXaGVuIGVuYWJsZWQsIHRoZSBpbnRlcmFjdGlvbiBi
ZXR3ZWVuIHRoZSBDWEFTIGFwcCBhbmQgdGhlIHJlbW90ZQogYWdlbnQgd2lsbCBzaGFyZSB0
aGUgc2FtZSBjb250ZXh0LiBJZiB0aGUgcmVtb3RlIGFnZW50IHJldHVybnMgYQogY29udGV4
dF9pZCwgaXQgd2lsbCBiZSBwZXJzaXN0ZWQgZm9yIHRoZSBlbnRpcmV0eSBvZiB0aGUgc2Vz
c2lvbiBmb3IgdGhpcwogcmVtb3RlIGFnZW50IHRvb2wuCgoMCgUEAwIEBRIDdgIGCgwKBQQD
AgQBEgN2BxUKDAoFBAMCBAMSA3YYGQoMCgUEAwIECBIDdhpCCg8KCAQDAgQInAgAEgN2G0EK
YgoEBAMCBRIEegJ7LxpUIE9wdGlvbmFsLiBNYXBwaW5nIG9mIGlucHV0IHZhcmlhYmxlIG5h
bWVzIG9mIHJlbW90ZSBhZ2VudCB0byBHRUNYIHZhcmlhYmxlCiBuYW1lcy4KCgwKBQQDAgUG
EgN6AhUKDAoFBAMCBQESA3oWLAoMCgUEAwIFAxIDei8wCgwKBQQDAgUIEgN7Bi4KDwoIBAMC
BQicCAASA3sHLQpkCgQEAwIGEgV/AoABLxpVIE9wdGlvbmFsLiBNYXBwaW5nIG9mIG91dHB1
dCB2YXJpYWJsZSBuYW1lcyBvZiByZW1vdGUgYWdlbnQgdG8gR0VDWCB2YXJpYWJsZQogbmFt
ZXMuCgoMCgUEAwIGBhIDfwIVCgwKBQQDAgYBEgN/Fi0KDAoFBAMCBgMSA38wMQoNCgUEAwIG
CBIEgAEGLgoQCggEAwIGCJwIABIEgAEHLWIGcHJvdG8z
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Ces::V1::AgentCard::AgentCard ===
    # Fields for AgentCard
    # Field: name Type: 9 ()
    # Field: description Type: 9 ()
    # Field: supported_interfaces Type: 11 (.google.cloud.ces.v1.AgentInterface)
    # Field: version Type: 9 ()
    # Field: skills Type: 11 (.google.cloud.ces.v1.AgentSkill)

# === Message: Google::Cloud::Ces::V1::AgentCard::AgentInterface ===
    # Fields for AgentInterface
    # Field: url Type: 9 ()
    # Field: protocol_binding Type: 9 ()
    # Field: tenant Type: 9 ()
    # Field: protocol_version Type: 9 ()

# === Message: Google::Cloud::Ces::V1::AgentCard::AgentSkill ===
    # Fields for AgentSkill
    # Field: id Type: 9 ()
    # Field: name Type: 9 ()
    # Field: description Type: 9 ()
    # Field: tags Type: 9 ()
    # Field: examples Type: 9 ()
    # Field: input_modes Type: 9 ()
    # Field: output_modes Type: 9 ()

# === Message: Google::Cloud::Ces::V1::AgentCard::RemoteAgentTool ===
    # Fields for RemoteAgentTool
    # Field: name Type: 9 ()
    # Field: description Type: 9 ()
    # Field: agent_card Type: 11 (.google.cloud.ces.v1.AgentCard)
    # Field: api_authentication Type: 11 (.google.cloud.ces.v1.ApiAuthentication)
    # Field: stateful_agent Type: 8 ()
    # Field: input_variable_mapping Type: 11 (.google.cloud.ces.v1.RemoteAgentTool.InputVariableMappingEntry)
    # Field: output_variable_mapping Type: 11 (.google.cloud.ces.v1.RemoteAgentTool.OutputVariableMappingEntry)

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Ces::V1::AgentCard - Compiled Protocol Buffers messages for google/cloud/ces/v1/agent_card.proto

=head1 SYNOPSIS

    use Google::Cloud::Ces::V1::AgentCard;

    my $msg = Google::Cloud::Ces::V1::AgentCard::AgentCard->new({
        name => $name,
        description => $description,
        supported_interfaces => $supported_interfaces,
        version => $version,
    });

    # Read or update a field
    my $val = $msg->name();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Ces::V1::AgentCard::AgentCard->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/ces/v1/agent_card.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Ces::V1::AgentCard::AgentCard

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

Type: C<Message> (L<Google::Cloud::Ces::V1::AgentCard::AgentInterface>)

Required. Ordered list of supported interfaces. The first entry is
preferred.

=item * C<< $msg->version() >> / C<< $msg->version($value) >>

Type: C<String>

Required. The version of the agent.

=item * C<< $msg->skills() >> / C<< $msg->skills($value) >>

Type: C<Message> (L<Google::Cloud::Ces::V1::AgentCard::AgentSkill>)

Required. Skills represent a unit of ability an agent can perform. This may
somewhat abstract but represents a more focused set of actions that the
agent is highly likely to succeed at.

=back

=head2 Google::Cloud::Ces::V1::AgentCard::AgentInterface

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

=head2 Google::Cloud::Ces::V1::AgentCard::AgentSkill

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

=head2 Google::Cloud::Ces::V1::AgentCard::RemoteAgentTool

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

Type: C<Message> (L<Google::Cloud::Ces::V1::AgentCard::AgentCard>)

Required. The agent card of the remote agent that this tool invokes.

=item * C<< $msg->api_authentication() >> / C<< $msg->api_authentication($value) >>

Type: C<Message> (L<Google::Cloud::Ces::V1::Auth::ApiAuthentication>)

Optional. Authentication configuration for calling the remote agent.

=item * C<< $msg->stateful_agent() >> / C<< $msg->stateful_agent($value) >>

Type: C<Bool>

Optional. When enabled, the interaction between the CXAS app and the remote
agent will share the same context. If the remote agent returns a
context_id, it will be persisted for the entirety of the session for this
remote agent tool.

=item * C<< $msg->input_variable_mapping() >> / C<< $msg->input_variable_mapping($value) >>

Type: C<Message> (L<Google::Cloud::Ces::V1::AgentCard::RemoteAgentTool::InputVariableMappingEntry>)

Optional. Mapping of input variable names of remote agent to GECX variable
names.

=item * C<< $msg->output_variable_mapping() >> / C<< $msg->output_variable_mapping($value) >>

Type: C<Message> (L<Google::Cloud::Ces::V1::AgentCard::RemoteAgentTool::OutputVariableMappingEntry>)

Optional. Mapping of output variable names of remote agent to GECX variable
names.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Ces::V1::AgentCard::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
