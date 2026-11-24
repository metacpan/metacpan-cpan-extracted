package Google::Cloud::Oracledatabase::V1::PluggableDatabase;

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
    eval { require Google::Protobuf::Timestamp };
    my $descriptor_b64 = <<'EOF';
Cjdnb29nbGUvY2xvdWQvb3JhY2xlZGF0YWJhc2UvdjEvcGx1Z2dhYmxlX2RhdGFiYXNlLnBy
b3RvEh5nb29nbGUuY2xvdWQub3JhY2xlZGF0YWJhc2UudjEaH2dvb2dsZS9hcGkvZmllbGRf
YmVoYXZpb3IucHJvdG8aGWdvb2dsZS9hcGkvcmVzb3VyY2UucHJvdG8aH2dvb2dsZS9wcm90
b2J1Zi90aW1lc3RhbXAucHJvdG8ingMKEVBsdWdnYWJsZURhdGFiYXNlEhcKBG5hbWUYASAB
KAlCA+BBCFIEbmFtZRJgCgpwcm9wZXJ0aWVzGAIgASgLMjsuZ29vZ2xlLmNsb3VkLm9yYWNs
ZWRhdGFiYXNlLnYxLlBsdWdnYWJsZURhdGFiYXNlUHJvcGVydGllc0ID4EEBUgpwcm9wZXJ0
aWVzEhwKB29jaV91cmwYAyABKAlCA+BBA1IGb2NpVXJsEkAKC2NyZWF0ZV90aW1lGAQgASgL
MhouZ29vZ2xlLnByb3RvYnVmLlRpbWVzdGFtcEID4EEDUgpjcmVhdGVUaW1lOq0B6kGpAQov
b3JhY2xlZGF0YWJhc2UuZ29vZ2xlYXBpcy5jb20vUGx1Z2dhYmxlRGF0YWJhc2UST3Byb2pl
Y3RzL3twcm9qZWN0fS9sb2NhdGlvbnMve2xvY2F0aW9ufS9wbHVnZ2FibGVEYXRhYmFzZXMv
e3BsdWdnYWJsZV9kYXRhYmFzZX0qEnBsdWdnYWJsZURhdGFiYXNlczIRcGx1Z2dhYmxlRGF0
YWJhc2UiiRAKG1BsdWdnYWJsZURhdGFiYXNlUHJvcGVydGllcxIqCg5jb21wYXJ0bWVudF9p
ZBgBIAEoCUID4EECUg1jb21wYXJ0bWVudElkEnYKEmNvbm5lY3Rpb25fc3RyaW5ncxgCIAEo
CzJCLmdvb2dsZS5jbG91ZC5vcmFjbGVkYXRhYmFzZS52MS5QbHVnZ2FibGVEYXRhYmFzZUNv
bm5lY3Rpb25TdHJpbmdzQgPgQQFSEWNvbm5lY3Rpb25TdHJpbmdzEjsKF2NvbnRhaW5lcl9k
YXRhYmFzZV9vY2lkGAMgASgJQgPgQQJSFWNvbnRhaW5lckRhdGFiYXNlT2NpZBJ0CgxkZWZp
bmVkX3RhZ3MYBCADKAsyTC5nb29nbGUuY2xvdWQub3JhY2xlZGF0YWJhc2UudjEuUGx1Z2dh
YmxlRGF0YWJhc2VQcm9wZXJ0aWVzLkRlZmluZWRUYWdzRW50cnlCA+BBAVILZGVmaW5lZFRh
Z3MSdwoNZnJlZWZvcm1fdGFncxgFIAMoCzJNLmdvb2dsZS5jbG91ZC5vcmFjbGVkYXRhYmFz
ZS52MS5QbHVnZ2FibGVEYXRhYmFzZVByb3BlcnRpZXMuRnJlZWZvcm1UYWdzRW50cnlCA+BB
AVIMZnJlZWZvcm1UYWdzEhcKBG9jaWQYBiABKAlCA+BBA1IEb2NpZBIoCg1pc19yZXN0cmlj
dGVkGAcgASgIQgPgQQFSDGlzUmVzdHJpY3RlZBIwChFsaWZlY3ljbGVfZGV0YWlscxgIIAEo
CUID4EEDUhBsaWZlY3ljbGVEZXRhaWxzEokBCg9saWZlY3ljbGVfc3RhdGUYCSABKA4yWy5n
b29nbGUuY2xvdWQub3JhY2xlZGF0YWJhc2UudjEuUGx1Z2dhYmxlRGF0YWJhc2VQcm9wZXJ0
aWVzLlBsdWdnYWJsZURhdGFiYXNlTGlmZWN5Y2xlU3RhdGVCA+BBA1IObGlmZWN5Y2xlU3Rh
dGUSHgoIcGRiX25hbWUYCiABKAlCA+BBAlIHcGRiTmFtZRJ7ChZwZGJfbm9kZV9sZXZlbF9k
ZXRhaWxzGAsgAygLMkEuZ29vZ2xlLmNsb3VkLm9yYWNsZWRhdGFiYXNlLnYxLlBsdWdnYWJs
ZURhdGFiYXNlTm9kZUxldmVsRGV0YWlsc0ID4EEBUhNwZGJOb2RlTGV2ZWxEZXRhaWxzEnsK
GmRhdGFiYXNlX21hbmFnZW1lbnRfY29uZmlnGA0gASgLMjguZ29vZ2xlLmNsb3VkLm9yYWNs
ZWRhdGFiYXNlLnYxLkRhdGFiYXNlTWFuYWdlbWVudENvbmZpZ0ID4EEDUhhkYXRhYmFzZU1h
bmFnZW1lbnRDb25maWcSlAEKGW9wZXJhdGlvbnNfaW5zaWdodHNfc3RhdGUYDiABKA4yUy5n
b29nbGUuY2xvdWQub3JhY2xlZGF0YWJhc2UudjEuUGx1Z2dhYmxlRGF0YWJhc2VQcm9wZXJ0
aWVzLk9wZXJhdGlvbnNJbnNpZ2h0c1N0YXRlQgPgQQNSF29wZXJhdGlvbnNJbnNpZ2h0c1N0
YXRlGrUBCg9EZWZpbmVkVGFnVmFsdWUSaQoEdGFncxgBIAMoCzJVLmdvb2dsZS5jbG91ZC5v
cmFjbGVkYXRhYmFzZS52MS5QbHVnZ2FibGVEYXRhYmFzZVByb3BlcnRpZXMuRGVmaW5lZFRh
Z1ZhbHVlLlRhZ3NFbnRyeVIEdGFncxo3CglUYWdzRW50cnkSEAoDa2V5GAEgASgJUgNrZXkS
FAoFdmFsdWUYAiABKAlSBXZhbHVlOgI4ARqLAQoQRGVmaW5lZFRhZ3NFbnRyeRIQCgNrZXkY
ASABKAlSA2tleRJhCgV2YWx1ZRgCIAEoCzJLLmdvb2dsZS5jbG91ZC5vcmFjbGVkYXRhYmFz
ZS52MS5QbHVnZ2FibGVEYXRhYmFzZVByb3BlcnRpZXMuRGVmaW5lZFRhZ1ZhbHVlUgV2YWx1
ZToCOAEaPwoRRnJlZWZvcm1UYWdzRW50cnkSEAoDa2V5GAEgASgJUgNrZXkSFAoFdmFsdWUY
AiABKAlSBXZhbHVlOgI4ASKzAgofUGx1Z2dhYmxlRGF0YWJhc2VMaWZlY3ljbGVTdGF0ZRIy
Ci5QTFVHR0FCTEVfREFUQUJBU0VfTElGRUNZQ0xFX1NUQVRFX1VOU1BFQ0lGSUVEEAASEAoM
UFJPVklTSU9OSU5HEAESDQoJQVZBSUxBQkxFEAISDwoLVEVSTUlOQVRJTkcQAxIOCgpURVJN
SU5BVEVEEAQSDAoIVVBEQVRJTkcQBRIKCgZGQUlMRUQQBhIOCgpSRUxPQ0FUSU5HEAcSDQoJ
UkVMT0NBVEVEEAgSDgoKUkVGUkVTSElORxAJEhcKE1JFU1RPUkVfSU5fUFJPR1JFU1MQChIS
Cg5SRVNUT1JFX0ZBSUxFRBALEhYKEkJBQ0tVUF9JTl9QUk9HUkVTUxAMEgwKCERJU0FCTEVE
EA0iqgEKF09wZXJhdGlvbnNJbnNpZ2h0c1N0YXRlEikKJU9QRVJBVElPTlNfSU5TSUdIVFNf
U1RBVEVfVU5TUEVDSUZJRUQQABIMCghFTkFCTElORxABEgsKB0VOQUJMRUQQAhINCglESVNB
QkxJTkcQAxIPCgtOT1RfRU5BQkxFRBAEEhMKD0ZBSUxFRF9FTkFCTElORxAFEhQKEEZBSUxF
RF9ESVNBQkxJTkcQBiLYAgoiUGx1Z2dhYmxlRGF0YWJhc2VDb25uZWN0aW9uU3RyaW5ncxKX
AQoWYWxsX2Nvbm5lY3Rpb25fc3RyaW5ncxgBIAMoCzJcLmdvb2dsZS5jbG91ZC5vcmFjbGVk
YXRhYmFzZS52MS5QbHVnZ2FibGVEYXRhYmFzZUNvbm5lY3Rpb25TdHJpbmdzLkFsbENvbm5l
Y3Rpb25TdHJpbmdzRW50cnlCA+BBAVIUYWxsQ29ubmVjdGlvblN0cmluZ3MSJAoLcGRiX2Rl
ZmF1bHQYAiABKAlCA+BBAVIKcGRiRGVmYXVsdBIpCg5wZGJfaXBfZGVmYXVsdBgDIAEoCUID
4EEBUgxwZGJJcERlZmF1bHQaRwoZQWxsQ29ubmVjdGlvblN0cmluZ3NFbnRyeRIQCgNrZXkY
ASABKAlSA2tleRIUCgV2YWx1ZRgCIAEoCVIFdmFsdWU6AjgBIoIDCiFQbHVnZ2FibGVEYXRh
YmFzZU5vZGVMZXZlbERldGFpbHMSIAoJbm9kZV9uYW1lGAEgASgJQgPgQQJSCG5vZGVOYW1l
En0KCW9wZW5fbW9kZRgCIAEoDjJbLmdvb2dsZS5jbG91ZC5vcmFjbGVkYXRhYmFzZS52MS5Q
bHVnZ2FibGVEYXRhYmFzZU5vZGVMZXZlbERldGFpbHMuUGx1Z2dhYmxlRGF0YWJhc2VPcGVu
TW9kZUID4EECUghvcGVuTW9kZRI3ChVwbHVnZ2FibGVfZGF0YWJhc2VfaWQYAyABKAlCA+BB
AlITcGx1Z2dhYmxlRGF0YWJhc2VJZCKCAQoZUGx1Z2dhYmxlRGF0YWJhc2VPcGVuTW9kZRIs
CihQTFVHR0FCTEVfREFUQUJBU0VfT1BFTl9NT0RFX1VOU1BFQ0lGSUVEEAASDQoJUkVBRF9P
TkxZEAESDgoKUkVBRF9XUklURRACEgsKB01PVU5URUQQAxILCgdNSUdSQVRFEAQikwQKGERh
dGFiYXNlTWFuYWdlbWVudENvbmZpZxJ4ChBtYW5hZ2VtZW50X3N0YXRlGAEgASgOMkguZ29v
Z2xlLmNsb3VkLm9yYWNsZWRhdGFiYXNlLnYxLkRhdGFiYXNlTWFuYWdlbWVudENvbmZpZy5N
YW5hZ2VtZW50U3RhdGVCA+BBA1IPbWFuYWdlbWVudFN0YXRlEnUKD21hbmFnZW1lbnRfdHlw
ZRgCIAEoDjJHLmdvb2dsZS5jbG91ZC5vcmFjbGVkYXRhYmFzZS52MS5EYXRhYmFzZU1hbmFn
ZW1lbnRDb25maWcuTWFuYWdlbWVudFR5cGVCA+BBA1IObWFuYWdlbWVudFR5cGUiuQEKD01h
bmFnZW1lbnRTdGF0ZRIgChxNQU5BR0VNRU5UX1NUQVRFX1VOU1BFQ0lGSUVEEAASDAoIRU5B
QkxJTkcQARILCgdFTkFCTEVEEAISDQoJRElTQUJMSU5HEAMSDAoIRElTQUJMRUQQBBIMCghV
UERBVElORxAFEhMKD0ZBSUxFRF9FTkFCTElORxAGEhQKEEZBSUxFRF9ESVNBQkxJTkcQBxIT
Cg9GQUlMRURfVVBEQVRJTkcQCCJKCg5NYW5hZ2VtZW50VHlwZRIfChtNQU5BR0VNRU5UX1RZ
UEVfVU5TUEVDSUZJRUQQABIJCgVCQVNJQxABEgwKCEFEVkFOQ0VEEAIiagobR2V0UGx1Z2dh
YmxlRGF0YWJhc2VSZXF1ZXN0EksKBG5hbWUYASABKAlCN+BBAvpBMQovb3JhY2xlZGF0YWJh
c2UuZ29vZ2xlYXBpcy5jb20vUGx1Z2dhYmxlRGF0YWJhc2VSBG5hbWUi0wEKHUxpc3RQbHVn
Z2FibGVEYXRhYmFzZXNSZXF1ZXN0Ek8KBnBhcmVudBgBIAEoCUI34EEC+kExEi9vcmFjbGVk
YXRhYmFzZS5nb29nbGVhcGlzLmNvbS9QbHVnZ2FibGVEYXRhYmFzZVIGcGFyZW50EiAKCXBh
Z2Vfc2l6ZRgCIAEoBUID4EEBUghwYWdlU2l6ZRIiCgpwYWdlX3Rva2VuGAMgASgJQgPgQQFS
CXBhZ2VUb2tlbhIbCgZmaWx0ZXIYBCABKAlCA+BBAVIGZmlsdGVyIqwBCh5MaXN0UGx1Z2dh
YmxlRGF0YWJhc2VzUmVzcG9uc2USYgoTcGx1Z2dhYmxlX2RhdGFiYXNlcxgBIAMoCzIxLmdv
b2dsZS5jbG91ZC5vcmFjbGVkYXRhYmFzZS52MS5QbHVnZ2FibGVEYXRhYmFzZVIScGx1Z2dh
YmxlRGF0YWJhc2VzEiYKD25leHRfcGFnZV90b2tlbhgCIAEoCVINbmV4dFBhZ2VUb2tlbkLw
AQoiY29tLmdvb2dsZS5jbG91ZC5vcmFjbGVkYXRhYmFzZS52MUIWUGx1Z2dhYmxlRGF0YWJh
c2VQcm90b1ABWkpjbG91ZC5nb29nbGUuY29tL2dvL29yYWNsZWRhdGFiYXNlL2FwaXYxL29y
YWNsZWRhdGFiYXNlcGI7b3JhY2xlZGF0YWJhc2VwYqoCHkdvb2dsZS5DbG91ZC5PcmFjbGVE
YXRhYmFzZS5WMcoCHkdvb2dsZVxDbG91ZFxPcmFjbGVEYXRhYmFzZVxWMeoCIUdvb2dsZTo6
Q2xvdWQ6Ok9yYWNsZURhdGFiYXNlOjpWMUr+WAoHEgUOAM8CAQq8BAoBDBIDDgASMrEEIENv
cHlyaWdodCAyMDI2IEdvb2dsZSBMTEMKCiBMaWNlbnNlZCB1bmRlciB0aGUgQXBhY2hlIExp
Y2Vuc2UsIFZlcnNpb24gMi4wICh0aGUgIkxpY2Vuc2UiKTsKIHlvdSBtYXkgbm90IHVzZSB0
aGlzIGZpbGUgZXhjZXB0IGluIGNvbXBsaWFuY2Ugd2l0aCB0aGUgTGljZW5zZS4KIFlvdSBt
YXkgb2J0YWluIGEgY29weSBvZiB0aGUgTGljZW5zZSBhdAoKICAgICBodHRwOi8vd3d3LmFw
YWNoZS5vcmcvbGljZW5zZXMvTElDRU5TRS0yLjAKCiBVbmxlc3MgcmVxdWlyZWQgYnkgYXBw
bGljYWJsZSBsYXcgb3IgYWdyZWVkIHRvIGluIHdyaXRpbmcsIHNvZnR3YXJlCiBkaXN0cmli
dXRlZCB1bmRlciB0aGUgTGljZW5zZSBpcyBkaXN0cmlidXRlZCBvbiBhbiAiQVMgSVMiIEJB
U0lTLAogV0lUSE9VVCBXQVJSQU5USUVTIE9SIENPTkRJVElPTlMgT0YgQU5ZIEtJTkQsIGVp
dGhlciBleHByZXNzIG9yIGltcGxpZWQuCiBTZWUgdGhlIExpY2Vuc2UgZm9yIHRoZSBzcGVj
aWZpYyBsYW5ndWFnZSBnb3Zlcm5pbmcgcGVybWlzc2lvbnMgYW5kCiBsaW1pdGF0aW9ucyB1
bmRlciB0aGUgTGljZW5zZS4KCggKAQISAxAAJwoJCgIDABIDEgApCgkKAgMBEgMTACMKCQoC
AwISAxQAKQoICgEIEgMWADsKCQoCCCUSAxYAOwoICgEIEgMXAGEKCQoCCAsSAxcAYQoICgEI
EgMYACIKCQoCCAoSAxgAIgoICgEIEgMZADcKCQoCCAgSAxkANwoICgEIEgMaADsKCQoCCAES
AxoAOwoICgEIEgMbADsKCQoCCCkSAxsAOwoICgEIEgMcADoKCQoCCC0SAxwAOgp/CgIEABIE
IAA4ARpzIFRoZSBQbHVnZ2FibGVEYXRhYmFzZSByZXNvdXJjZS4KIGh0dHBzOi8vZG9jcy5v
cmFjbGUuY29tL2VuLXVzL2lhYXMvYXBpLyMvZW4vZGF0YWJhc2UvMjAxNjA5MTgvUGx1Z2dh
YmxlRGF0YWJhc2UvCgoKCgMEAAESAyAIGQoLCgMEAAcSBCECJgQKDQoFBAAHnQgSBCECJgQK
rwEKBAQAAgASAysCPRqhASBJZGVudGlmaWVyLiBUaGUgbmFtZSBvZiB0aGUgUGx1Z2dhYmxl
RGF0YWJhc2UgcmVzb3VyY2UgaW4gdGhlIGZvbGxvd2luZwogZm9ybWF0OgogcHJvamVjdHMv
e3Byb2plY3R9L2xvY2F0aW9ucy97cmVnaW9ufS9wbHVnZ2FibGVEYXRhYmFzZXMve3BsdWdn
YWJsZV9kYXRhYmFzZX0KCgwKBQQAAgAFEgMrAggKDAoFBAACAAESAysJDQoMCgUEAAIAAxID
KxARCgwKBQQAAgAIEgMrEjwKDwoIBAACAAicCAASAysTOwpCCgQEAAIBEgQuAi8vGjQgT3B0
aW9uYWwuIFRoZSBwcm9wZXJ0aWVzIG9mIHRoZSBQbHVnZ2FibGVEYXRhYmFzZS4KCgwKBQQA
AgEGEgMuAh0KDAoFBAACAQESAy4eKAoMCgUEAAIBAxIDLissCgwKBQQAAgEIEgMvBi4KDwoI
BAACAQicCAASAy8HLQpeCgQEAAICEgMzAkEaUSBPdXRwdXQgb25seS4gSFRUUFMgbGluayB0
byBPQ0kgcmVzb3VyY2VzIGV4cG9zZWQgdG8gQ3VzdG9tZXIgdmlhIFVJCiBJbnRlcmZhY2Uu
CgoMCgUEAAICBRIDMwIICgwKBQQAAgIBEgMzCRAKDAoFBAACAgMSAzMTFAoMCgUEAAICCBID
MxVACg8KCAQAAgIInAgAEgMzFj8KVgoEBAACAxIENgI3MhpIIE91dHB1dCBvbmx5LiBUaGUg
ZGF0ZSBhbmQgdGltZSB0aGF0IHRoZSBQbHVnZ2FibGVEYXRhYmFzZSB3YXMgY3JlYXRlZC4K
CgwKBQQAAgMGEgM2AhsKDAoFBAACAwESAzYcJwoMCgUEAAIDAxIDNiorCgwKBQQAAgMIEgM3
BjEKDwoIBAACAwicCAASAzcHMAo1CgIEARIFOwC4AQEaKCBUaGUgcHJvcGVydGllcyBvZiBh
IFBsdWdnYWJsZURhdGFiYXNlLgoKCgoDBAEBEgM7CCMKPwoEBAEDABIEPQJAAxoxIFdyYXBw
ZXIgbWVzc2FnZSBmb3IgdGhlIHZhbHVlIG9mIGEgZGVmaW5lZCB0YWcuCgoMCgUEAQMAARID
PQoZCi8KBgQBAwACABIDPwQhGiAgVGhlIHRhZ3Mgd2l0aGluIHRoZSBuYW1lc3BhY2UuCgoO
CgcEAQMAAgAGEgM/BBcKDgoHBAEDAAIAARIDPxgcCg4KBwQBAwACAAMSAz8fIApGCgQEAQQA
EgRDAm0DGjggVGhlIHZhcmlvdXMgbGlmZWN5Y2xlIHN0YXRlcyBvZiB0aGUgUGx1Z2dhYmxl
RGF0YWJhc2UuCgoMCgUEAQQAARIDQwcmCjQKBgQBBAACABIDRQQ3GiUgVGhlIGxpZmVjeWNs
ZSBzdGF0ZSBpcyB1bnNwZWNpZmllZC4KCg4KBwQBBAACAAESA0UEMgoOCgcEAQQAAgACEgNF
NTYKOAoGBAEEAAIBEgNIBBUaKSBUaGUgcGx1Z2dhYmxlIGRhdGFiYXNlIGlzIHByb3Zpc2lv
bmluZy4KCg4KBwQBBAACAQESA0gEEAoOCgcEAQQAAgECEgNIExQKNQoGBAEEAAICEgNLBBIa
JiBUaGUgcGx1Z2dhYmxlIGRhdGFiYXNlIGlzIGF2YWlsYWJsZS4KCg4KBwQBBAACAgESA0sE
DQoOCgcEAQQAAgICEgNLEBEKNwoGBAEEAAIDEgNOBBQaKCBUaGUgcGx1Z2dhYmxlIGRhdGFi
YXNlIGlzIHRlcm1pbmF0aW5nLgoKDgoHBAEEAAIDARIDTgQPCg4KBwQBBAACAwISA04SEwo2
CgYEAQQAAgQSA1EEExonIFRoZSBwbHVnZ2FibGUgZGF0YWJhc2UgaXMgdGVybWluYXRlZC4K
Cg4KBwQBBAACBAESA1EEDgoOCgcEAQQAAgQCEgNRERIKNAoGBAEEAAIFEgNUBBEaJSBUaGUg
cGx1Z2dhYmxlIGRhdGFiYXNlIGlzIHVwZGF0aW5nLgoKDgoHBAEEAAIFARIDVAQMCg4KBwQB
BAACBQISA1QPEAo9CgYEAQQAAgYSA1cEDxouIFRoZSBwbHVnZ2FibGUgZGF0YWJhc2UgaXMg
aW4gYSBmYWlsZWQgc3RhdGUuCgoOCgcEAQQAAgYBEgNXBAoKDgoHBAEEAAIGAhIDVw0OCjYK
BgQBBAACBxIDWgQTGicgVGhlIHBsdWdnYWJsZSBkYXRhYmFzZSBpcyByZWxvY2F0aW5nLgoK
DgoHBAEEAAIHARIDWgQOCg4KBwQBBAACBwISA1oREgo1CgYEAQQAAggSA10EEhomIFRoZSBw
bHVnZ2FibGUgZGF0YWJhc2UgaXMgcmVsb2NhdGVkLgoKDgoHBAEEAAIIARIDXQQNCg4KBwQB
BAACCAISA10QEQo2CgYEAQQAAgkSA2AEExonIFRoZSBwbHVnZ2FibGUgZGF0YWJhc2UgaXMg
cmVmcmVzaGluZy4KCg4KBwQBBAACCQESA2AEDgoOCgcEAQQAAgkCEgNgERIKNQoGBAEEAAIK
EgNjBB0aJiBUaGUgcGx1Z2dhYmxlIGRhdGFiYXNlIGlzIHJlc3RvcmluZy4KCg4KBwQBBAAC
CgESA2MEFwoOCgcEAQQAAgoCEgNjGhwKNwoGBAEEAAILEgNmBBgaKCBUaGUgcGx1Z2dhYmxl
IGRhdGFiYXNlIHJlc3RvcmUgZmFpbGVkLgoKDgoHBAEEAAILARIDZgQSCg4KBwQBBAACCwIS
A2YVFwo2CgYEAQQAAgwSA2kEHBonIFRoZSBwbHVnZ2FibGUgZGF0YWJhc2UgaXMgYmFja2lu
ZyB1cC4KCg4KBwQBBAACDAESA2kEFgoOCgcEAQQAAgwCEgNpGRsKNAoGBAEEAAINEgNsBBIa
JSBUaGUgcGx1Z2dhYmxlIGRhdGFiYXNlIGlzIGRpc2FibGVkLgoKDgoHBAEEAAINARIDbAQM
Cg4KBwQBBAACDQISA2wPEQpFCgQEAQQBEgVwAoUBAxo2IFRoZSBzdGF0dXMgb2YgT3BlcmF0
aW9ucyBJbnNpZ2h0cyBmb3IgdGhpcyBEYXRhYmFzZS4KCgwKBQQBBAEBEgNwBx4KLQoGBAEE
AQIAEgNyBC4aHiBUaGUgc3RhdHVzIGlzIG5vdCBzcGVjaWZpZWQuCgoOCgcEAQQBAgABEgNy
BCkKDgoHBAEEAQIAAhIDciwtCjEKBgQBBAECARIDdQQRGiIgT3BlcmF0aW9ucyBJbnNpZ2h0
cyBpcyBlbmFibGluZy4KCg4KBwQBBAECAQESA3UEDAoOCgcEAQQBAgECEgN1DxAKMAoGBAEE
AQICEgN4BBAaISBPcGVyYXRpb25zIEluc2lnaHRzIGlzIGVuYWJsZWQuCgoOCgcEAQQBAgIB
EgN4BAsKDgoHBAEEAQICAhIDeA4PCjIKBgQBBAECAxIDewQSGiMgT3BlcmF0aW9ucyBJbnNp
Z2h0cyBpcyBkaXNhYmxpbmcuCgoOCgcEAQQBAgMBEgN7BA0KDgoHBAEEAQIDAhIDexARCjQK
BgQBBAECBBIDfgQUGiUgT3BlcmF0aW9ucyBJbnNpZ2h0cyBpcyBub3QgZW5hYmxlZC4KCg4K
BwQBBAECBAESA34EDwoOCgcEAQQBAgQCEgN+EhMKNwoGBAEEAQIFEgSBAQQYGicgT3BlcmF0
aW9ucyBJbnNpZ2h0cyBmYWlsZWQgdG8gZW5hYmxlLgoKDwoHBAEEAQIFARIEgQEEEwoPCgcE
AQQBAgUCEgSBARYXCjgKBgQBBAECBhIEhAEEGRooIE9wZXJhdGlvbnMgSW5zaWdodHMgZmFp
bGVkIHRvIGRpc2FibGUuCgoPCgcEAQQBAgYBEgSEAQQUCg8KBwQBBAECBgISBIQBFxgKNgoE
BAECABIEiAECRRooIFJlcXVpcmVkLiBUaGUgT0NJRCBvZiB0aGUgY29tcGFydG1lbnQuCgoN
CgUEAQIABRIEiAECCAoNCgUEAQIAARIEiAEJFwoNCgUEAQIAAxIEiAEaGwoNCgUEAQIACBIE
iAEcRAoQCggEAQIACJwIABIEiAEdQwpaCgQEAQIBEgaLAQKMAS8aSiBPcHRpb25hbC4gVGhl
IENvbm5lY3Rpb24gc3RyaW5ncyB1c2VkIHRvIGNvbm5lY3QgdG8gdGhlIE9yYWNsZSBEYXRh
YmFzZS4KCg0KBQQBAgEGEgSLAQIkCg0KBQQBAgEBEgSLASU3Cg0KBQQBAgEDEgSLATo7Cg0K
BQQBAgEIEgSMAQYuChAKCAQBAgEInAgAEgSMAQctCi4KBAQBAgISBI8BAk4aICBSZXF1aXJl
ZC4gVGhlIE9DSUQgb2YgdGhlIENEQi4KCg0KBQQBAgIFEgSPAQIICg0KBQQBAgIBEgSPAQkg
Cg0KBQQBAgIDEgSPASMkCg0KBQQBAgIIEgSPASVNChAKCAQBAgIInAgAEgSPASZMCm4KBAQB
AgMSBpMBApQBLxpeIE9wdGlvbmFsLiBEZWZpbmVkIHRhZ3MgZm9yIHRoaXMgcmVzb3VyY2Uu
IEVhY2gga2V5IGlzIHByZWRlZmluZWQgYW5kIHNjb3BlZAogdG8gYSBuYW1lc3BhY2UuCgoN
CgUEAQIDBhIEkwECHgoNCgUEAQIDARIEkwEfKwoNCgUEAQIDAxIEkwEuLwoNCgUEAQIDCBIE
lAEGLgoQCggEAQIDCJwIABIElAEHLQqPAQoEBAECBBIGmAECmQEvGn8gT3B0aW9uYWwuIEZy
ZWUtZm9ybSB0YWdzIGZvciB0aGlzIHJlc291cmNlLiBFYWNoIHRhZyBpcyBhIHNpbXBsZSBr
ZXktdmFsdWUKIHBhaXIgd2l0aCBubyBwcmVkZWZpbmVkIG5hbWUsIHR5cGUsIG9yIG5hbWVz
cGFjZS4KCg0KBQQBAgQGEgSYAQIVCg0KBQQBAgQBEgSYARYjCg0KBQQBAgQDEgSYASYnCg0K
BQQBAgQIEgSZAQYuChAKCAQBAgQInAgAEgSZAQctCkAKBAQBAgUSBJwBAj4aMiBPdXRwdXQg
b25seS4gVGhlIE9DSUQgb2YgdGhlIHBsdWdnYWJsZSBkYXRhYmFzZS4KCg0KBQQBAgUFEgSc
AQIICg0KBQQBAgUBEgScAQkNCg0KBQQBAgUDEgScARARCg0KBQQBAgUIEgScARI9ChAKCAQB
AgUInAgAEgScARM8Ct8BCgQEAQIGEgShAQJCGtABIE9wdGlvbmFsLiBUaGUgcmVzdHJpY3Rl
ZCBtb2RlIG9mIHRoZSBwbHVnZ2FibGUgZGF0YWJhc2UuIElmIGEgcGx1Z2dhYmxlCiBkYXRh
YmFzZSBpcyBvcGVuZWQgaW4gcmVzdHJpY3RlZCBtb2RlLCB0aGUgdXNlciBuZWVkcyBib3Ro
IGNyZWF0ZSBhIHNlc3Npb24KIGFuZCBoYXZlIHJlc3RyaWN0ZWQgc2Vzc2lvbiBwcml2aWxl
Z2VzIHRvIGNvbm5lY3QgdG8gaXQuCgoNCgUEAQIGBRIEoQECBgoNCgUEAQIGARIEoQEHFAoN
CgUEAQIGAxIEoQEXGAoNCgUEAQIGCBIEoQEZQQoQCggEAQIGCJwIABIEoQEaQApWCgQEAQIH
EgSkAQJLGkggT3V0cHV0IG9ubHkuIEFkZGl0aW9uYWwgaW5mb3JtYXRpb24gYWJvdXQgdGhl
IGN1cnJlbnQgbGlmZWN5Y2xlIHN0YXRlLgoKDQoFBAECBwUSBKQBAggKDQoFBAECBwESBKQB
CRoKDQoFBAECBwMSBKQBHR4KDQoFBAECBwgSBKQBH0oKEAoIBAECBwicCAASBKQBIEkKSwoE
BAECCBIGpwECqAEyGjsgT3V0cHV0IG9ubHkuIFRoZSBjdXJyZW50IHN0YXRlIG9mIHRoZSBw
bHVnZ2FibGUgZGF0YWJhc2UuCgoNCgUEAQIIBhIEpwECIQoNCgUEAQIIARIEpwEiMQoNCgUE
AQIIAxIEpwE0NQoNCgUEAQIICBIEqAEGMQoQCggEAQIICJwIABIEqAEHMAosCgQEAQIJEgSr
AQJAGh4gUmVxdWlyZWQuIFRoZSBkYXRhYmFzZSBuYW1lLgoKDQoFBAECCQUSBKsBAggKDQoF
BAECCQESBKsBCREKDQoFBAECCQMSBKsBFBYKDQoFBAECCQgSBKsBFz8KEAoIBAECCQicCAAS
BKsBGD4KQQoEBAECChIGrgECrwEvGjEgT3B0aW9uYWwuIFBsdWdnYWJsZSBEYXRhYmFzZSBO
b2RlIExldmVsIERldGFpbHMKCg0KBQQBAgoEEgSuAQIKCg0KBQQBAgoGEgSuAQssCg0KBQQB
AgoBEgSuAS1DCg0KBQQBAgoDEgSuAUZICg0KBQQBAgoIEgSvAQYuChAKCAQBAgoInAgAEgSv
AQctClQKBAQBAgsSBrIBArMBMhpEIE91dHB1dCBvbmx5LiBUaGUgY29uZmlndXJhdGlvbiBv
ZiB0aGUgRGF0YWJhc2UgTWFuYWdlbWVudCBzZXJ2aWNlLgoKDQoFBAECCwYSBLIBAhoKDQoF
BAECCwESBLIBGzUKDQoFBAECCwMSBLIBODoKDQoFBAECCwgSBLMBBjEKEAoIBAECCwicCAAS
BLMBBzAKUwoEBAECDBIGtgECtwEyGkMgT3V0cHV0IG9ubHkuIFRoZSBzdGF0dXMgb2YgT3Bl
cmF0aW9ucyBJbnNpZ2h0cyBmb3IgdGhpcyBEYXRhYmFzZS4KCg0KBQQBAgwGEgS2AQIZCg0K
BQQBAgwBEgS2ARozCg0KBQQBAgwDEgS2ATY4Cg0KBQQBAgwIEgS3AQYxChAKCAQBAgwInAgA
EgS3AQcwCk4KAgQCEga7AQDIAQEaQCBUaGUgY29ubmVjdGlvbiBzdHJpbmdzIHVzZWQgdG8g
Y29ubmVjdCB0byB0aGUgT3JhY2xlIERhdGFiYXNlLgoKCwoDBAIBEgS7AQgqCmAKBAQCAgAS
Br4BAr8BLxpQIE9wdGlvbmFsLiBBbGwgY29ubmVjdGlvbiBzdHJpbmdzIHRvIHVzZSB0byBj
b25uZWN0IHRvIHRoZSBwbHVnZ2FibGUKIGRhdGFiYXNlLgoKDQoFBAICAAYSBL4BAhUKDQoF
BAICAAESBL4BFiwKDQoFBAICAAMSBL4BLzAKDQoFBAICAAgSBL8BBi4KEAoIBAICAAicCAAS
BL8BBy0KZQoEBAICARIEwwECQhpXIE9wdGlvbmFsLiBUaGUgZGVmYXVsdCBjb25uZWN0aW9u
IHN0cmluZyB0byB1c2UgdG8gY29ubmVjdCB0byB0aGUgcGx1Z2dhYmxlCiBkYXRhYmFzZS4K
Cg0KBQQCAgEFEgTDAQIICg0KBQQCAgEBEgTDAQkUCg0KBQQCAgEDEgTDARcYCg0KBQQCAgEI
EgTDARlBChAKCAQCAgEInAgAEgTDARpACm4KBAQCAgISBMcBAkUaYCBPcHRpb25hbC4gVGhl
IGRlZmF1bHQgY29ubmVjdGlvbiBzdHJpbmcgdG8gdXNlIHRvIGNvbm5lY3QgdG8gdGhlIHBs
dWdnYWJsZQogZGF0YWJhc2UgdXNpbmcgSVAuCgoNCgUEAgICBRIExwECCAoNCgUEAgICARIE
xwEJFwoNCgUEAgICAxIExwEaGwoNCgUEAgICCBIExwEcRAoQCggEAgICCJwIABIExwEdQwo6
CgIEAxIGywEA5wEBGiwgVGhlIFBsdWdnYWJsZSBEYXRhYmFzZSBOb2RlIExldmVsIERldGFp
bHMuCgoLCgMEAwESBMsBCCkKSAoEBAMEABIGzQEC3AEDGjggVGhlIG1vZGUgdGhhdCB0aGUg
cGx1Z2dhYmxlIGRhdGFiYXNlIGlzIGluIHRvIG9wZW4gaXQuCgoNCgUEAwQAARIEzQEHIAov
CgYEAwQAAgASBM8BBDEaHyBUaGUgb3BlbiBtb2RlIGlzIHVuc3BlY2lmaWVkLgoKDwoHBAME
AAIAARIEzwEELAoPCgcEAwQAAgACEgTPAS8wCkUKBgQDBAACARIE0gEEEho1IFRoZSBwbHVn
Z2FibGUgZGF0YWJhc2UgaXMgb3BlbmVkIGluIHJlYWQtb25seSBtb2RlLgoKDwoHBAMEAAIB
ARIE0gEEDQoPCgcEAwQAAgECEgTSARARCkYKBgQDBAACAhIE1QEEExo2IFRoZSBwbHVnZ2Fi
bGUgZGF0YWJhc2UgaXMgb3BlbmVkIGluIHJlYWQtd3JpdGUgbW9kZS4KCg8KBwQDBAACAgES
BNUBBA4KDwoHBAMEAAICAhIE1QEREgo0CgYEAwQAAgMSBNgBBBAaJCBUaGUgcGx1Z2dhYmxl
IGRhdGFiYXNlIGlzIG1vdW50ZWQuCgoPCgcEAwQAAgMBEgTYAQQLCg8KBwQDBAACAwISBNgB
Dg8KNQoGBAMEAAIEEgTbAQQQGiUgVGhlIHBsdWdnYWJsZSBkYXRhYmFzZSBpcyBtaWdyYXRl
ZC4KCg8KBwQDBAACBAESBNsBBAsKDwoHBAMEAAIEAhIE2wEODwo9CgQEAwIAEgTfAQJAGi8g
UmVxdWlyZWQuIFRoZSBOb2RlIG5hbWUgb2YgdGhlIERhdGFiYXNlIGhvbWUuCgoNCgUEAwIA
BRIE3wECCAoNCgUEAwIAARIE3wEJEgoNCgUEAwIAAxIE3wEVFgoNCgUEAwIACBIE3wEXPwoQ
CggEAwIACJwIABIE3wEYPgpSCgQEAwIBEgbiAQLjAS8aQiBSZXF1aXJlZC4gVGhlIG1vZGUg
dGhhdCB0aGUgcGx1Z2dhYmxlIGRhdGFiYXNlIGlzIGluIHRvIG9wZW4gaXQuCgoNCgUEAwIB
BhIE4gECGwoNCgUEAwIBARIE4gEcJQoNCgUEAwIBAxIE4gEoKQoNCgUEAwIBCBIE4wEGLgoQ
CggEAwIBCJwIABIE4wEHLQo9CgQEAwICEgTmAQJMGi8gUmVxdWlyZWQuIFRoZSBPQ0lEIG9m
IHRoZSBQbHVnZ2FibGUgRGF0YWJhc2UuCgoNCgUEAwICBRIE5gECCAoNCgUEAwICARIE5gEJ
HgoNCgUEAwICAxIE5gEhIgoNCgUEAwICCBIE5gEjSwoQCggEAwICCJwIABIE5gEkSgpFCgIE
BBIG6gEAnAIBGjcgVGhlIGNvbmZpZ3VyYXRpb24gb2YgdGhlIERhdGFiYXNlIE1hbmFnZW1l
bnQgc2VydmljZS4KCgsKAwQEARIE6gEIIApACgQEBAQAEgbsAQKHAgMaMCBUaGUgc3RhdHVz
IG9mIHRoZSBEYXRhYmFzZSBNYW5hZ2VtZW50IHNlcnZpY2UuCgoNCgUEBAQAARIE7AEHFgou
CgYEBAQAAgASBO4BBCUaHiBUaGUgc3RhdHVzIGlzIG5vdCBzcGVjaWZpZWQuCgoPCgcEBAQA
AgABEgTuAQQgCg8KBwQEBAACAAISBO4BIyQKPgoGBAQEAAIBEgTxAQQRGi4gVGhlIERhdGFi
YXNlIE1hbmFnZW1lbnQgc2VydmljZSBpcyBlbmFibGluZy4KCg8KBwQEBAACAQESBPEBBAwK
DwoHBAQEAAIBAhIE8QEPEAo9CgYEBAQAAgISBPQBBBAaLSBUaGUgRGF0YWJhc2UgTWFuYWdl
bWVudCBzZXJ2aWNlIGlzIGVuYWJsZWQuCgoPCgcEBAQAAgIBEgT0AQQLCg8KBwQEBAACAgIS
BPQBDg8KPwoGBAQEAAIDEgT3AQQSGi8gVGhlIERhdGFiYXNlIE1hbmFnZW1lbnQgc2Vydmlj
ZSBpcyBkaXNhYmxpbmcuCgoPCgcEBAQAAgMBEgT3AQQNCg8KBwQEBAACAwISBPcBEBEKPgoG
BAQEAAIEEgT6AQQRGi4gVGhlIERhdGFiYXNlIE1hbmFnZW1lbnQgc2VydmljZSBpcyBkaXNh
YmxlZC4KCg8KBwQEBAACBAESBPoBBAwKDwoHBAQEAAIEAhIE+gEPEAo+CgYEBAQAAgUSBP0B
BBEaLiBUaGUgRGF0YWJhc2UgTWFuYWdlbWVudCBzZXJ2aWNlIGlzIHVwZGF0aW5nLgoKDwoH
BAQEAAIFARIE/QEEDAoPCgcEBAQAAgUCEgT9AQ8QCkMKBgQEBAACBhIEgAIEGBozIFRoZSBE
YXRhYmFzZSBNYW5hZ2VtZW50IHNlcnZpY2UgZmFpbGVkIHRvIGVuYWJsZS4KCg8KBwQEBAAC
BgESBIACBBMKDwoHBAQEAAIGAhIEgAIWFwpECgYEBAQAAgcSBIMCBBkaNCBUaGUgRGF0YWJh
c2UgTWFuYWdlbWVudCBzZXJ2aWNlIGZhaWxlZCB0byBkaXNhYmxlLgoKDwoHBAQEAAIHARIE
gwIEFAoPCgcEBAQAAgcCEgSDAhcYCkMKBgQEBAACCBIEhgIEGBozIFRoZSBEYXRhYmFzZSBN
YW5hZ2VtZW50IHNlcnZpY2UgZmFpbGVkIHRvIHVwZGF0ZS4KCg8KBwQEBAACCAESBIYCBBMK
DwoHBAQEAAIIAhIEhgIWFwovCgQEBAQBEgaKAgKTAgMaHyBUaGUgRGF0YWJhc2UgTWFuYWdl
bWVudCB0eXBlLgoKDQoFBAQEAQESBIoCBxUKLAoGBAQEAQIAEgSMAgQkGhwgVGhlIHR5cGUg
aXMgbm90IHNwZWNpZmllZC4KCg8KBwQEBAECAAESBIwCBB8KDwoHBAQEAQIAAhIEjAIiIwos
CgYEBAQBAgESBI8CBA4aHCBCYXNpYyBEYXRhYmFzZSBNYW5hZ2VtZW50LgoKDwoHBAQEAQIB
ARIEjwIECQoPCgcEBAQBAgECEgSPAgwNCi8KBgQEBAECAhIEkgIEERofIEFkdmFuY2VkIERh
dGFiYXNlIE1hbmFnZW1lbnQuCgoPCgcEBAQBAgIBEgSSAgQMCg8KBwQEBAECAgISBJICDxAK
TQoEBAQCABIGlgIClwIyGj0gT3V0cHV0IG9ubHkuIFRoZSBzdGF0dXMgb2YgdGhlIERhdGFi
YXNlIE1hbmFnZW1lbnQgc2VydmljZS4KCg0KBQQEAgAGEgSWAgIRCg0KBQQEAgABEgSWAhIi
Cg0KBQQEAgADEgSWAiUmCg0KBQQEAgAIEgSXAgYxChAKCAQEAgAInAgAEgSXAgcwCjwKBAQE
AgESBpoCApsCMhosIE91dHB1dCBvbmx5LiBUaGUgRGF0YWJhc2UgTWFuYWdlbWVudCB0eXBl
LgoKDQoFBAQCAQYSBJoCAhAKDQoFBAQCAQESBJoCESAKDQoFBAQCAQMSBJoCIyQKDQoFBAQC
AQgSBJsCBjEKEAoIBAQCAQicCAASBJsCBzAKOAoCBAUSBp8CAKkCARoqIFRoZSByZXF1ZXN0
IGZvciBgUGx1Z2dhYmxlRGF0YWJhc2UuR2V0YC4KCgsKAwQFARIEnwIIIwqwAQoEBAUCABIG
owICqAIEGp8BIFJlcXVpcmVkLiBUaGUgbmFtZSBvZiB0aGUgUGx1Z2dhYmxlRGF0YWJhc2Ug
cmVzb3VyY2UgaW4gdGhlIGZvbGxvd2luZwogZm9ybWF0OgogcHJvamVjdHMve3Byb2plY3R9
L2xvY2F0aW9ucy97cmVnaW9ufS9wbHVnZ2FibGVEYXRhYmFzZXMve3BsdWdnYWJsZV9kYXRh
YmFzZX0KCg0KBQQFAgAFEgSjAgIICg0KBQQFAgABEgSjAgkNCg0KBQQFAgADEgSjAhARCg8K
BQQFAgAIEgajAhKoAgMKEAoIBAUCAAicCAASBKQCBCoKEQoHBAUCAAifCBIGpQIEpwIFCjkK
AgQGEgasAgDGAgEaKyBUaGUgcmVxdWVzdCBmb3IgYFBsdWdnYWJsZURhdGFiYXNlLkxpc3Rg
LgoKCwoDBAYBEgSsAgglCooBCgQEBgIAEgavAgK0AgQaeiBSZXF1aXJlZC4gVGhlIHBhcmVu
dCwgd2hpY2ggb3ducyB0aGlzIGNvbGxlY3Rpb24gb2YgUGx1Z2dhYmxlRGF0YWJhc2VzLgog
Rm9ybWF0OiBwcm9qZWN0cy97cHJvamVjdH0vbG9jYXRpb25zL3tsb2NhdGlvbn0KCg0KBQQG
AgAFEgSvAgIICg0KBQQGAgABEgSvAgkPCg0KBQQGAgADEgSvAhITCg8KBQQGAgAIEgavAhS0
AgMKEAoIBAYCAAicCAASBLACBCoKEQoHBAYCAAifCBIGsQIEswIFCnwKBAQGAgESBLgCAj8a
biBPcHRpb25hbC4gVGhlIG1heGltdW0gbnVtYmVyIG9mIFBsdWdnYWJsZURhdGFiYXNlcyB0
byByZXR1cm4uIFRoZSBzZXJ2aWNlCiBtYXkgcmV0dXJuIGZld2VyIHRoYW4gdGhpcyB2YWx1
ZS4KCg0KBQQGAgEFEgS4AgIHCg0KBQQGAgEBEgS4AggRCg0KBQQGAgEDEgS4AhQVCg0KBQQG
AgEIEgS4AhY+ChAKCAQGAgEInAgAEgS4Ahc9Co8CCgQEBgICEgS/AgJBGoACIE9wdGlvbmFs
LiBBIHBhZ2UgdG9rZW4sIHJlY2VpdmVkIGZyb20gYSBwcmV2aW91cyBgTGlzdFBsdWdnYWJs
ZURhdGFiYXNlc2AKIGNhbGwuIFByb3ZpZGUgdGhpcyB0byByZXRyaWV2ZSB0aGUgc3Vic2Vx
dWVudCBwYWdlLgoKIFdoZW4gcGFnaW5hdGluZywgYWxsIG90aGVyIHBhcmFtZXRlcnMgcHJv
dmlkZWQgdG8gYExpc3RQbHVnZ2FibGVEYXRhYmFzZXNgCiBtdXN0IG1hdGNoIHRoZSBjYWxs
IHRoYXQgcHJvdmlkZWQgdGhlIHBhZ2UgdG9rZW4uCgoNCgUEBgICBRIEvwICCAoNCgUEBgIC
ARIEvwIJEwoNCgUEBgICAxIEvwIWFwoNCgUEBgICCBIEvwIYQAoQCggEBgICCJwIABIEvwIZ
PwqaAgoEBAYCAxIExQICPRqLAiBPcHRpb25hbC4gQW4gZXhwcmVzc2lvbiBmb3IgZmlsdGVy
aW5nIHRoZSByZXN1bHRzIG9mIHRoZSByZXF1ZXN0LiBMaXN0IGZvcgogcGx1Z2dhYmxlIGRh
dGFiYXNlcyBpcyBzdXBwb3J0ZWQgb25seSB3aXRoIGEgdmFsaWQgY29udGFpbmVyIGRhdGFi
YXNlIChmdWxsCiByZXNvdXJjZSBuYW1lKSBmaWx0ZXIgaW4gdGhpcyBmb3JtYXQ6CiBgZGF0
YWJhc2U9InByb2plY3RzL3twcm9qZWN0fS9sb2NhdGlvbnMve2xvY2F0aW9ufS9kYXRhYmFz
ZXMve2RhdGFiYXNlfSJgCgoNCgUEBgIDBRIExQICCAoNCgUEBgIDARIExQIJDwoNCgUEBgID
AxIExQISEwoNCgUEBgIDCBIExQIUPAoQCggEBgIDCJwIABIExQIVOwo6CgIEBxIGyQIAzwIB
GiwgVGhlIHJlc3BvbnNlIGZvciBgUGx1Z2dhYmxlRGF0YWJhc2UuTGlzdGAuCgoLCgMEBwES
BMkCCCYKLwoEBAcCABIEywICNRohIFRoZSBsaXN0IG9mIFBsdWdnYWJsZURhdGFiYXNlcy4K
Cg0KBQQHAgAEEgTLAgIKCg0KBQQHAgAGEgTLAgscCg0KBQQHAgABEgTLAh0wCg0KBQQHAgAD
EgTLAjM0Ck8KBAQHAgESBM4CAh0aQSBBIHRva2VuIGlkZW50aWZ5aW5nIGEgcGFnZSBvZiBy
ZXN1bHRzIHRoZSBzZXJ2ZXIgc2hvdWxkIHJldHVybi4KCg0KBQQHAgEFEgTOAgIICg0KBQQH
AgEBEgTOAgkYCg0KBQQHAgEDEgTOAhscYgZwcm90bzM=
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Oracledatabase::V1::PluggableDatabase::PluggableDatabase ===
    # Fields for PluggableDatabase
    # Field: name Type: 9 ()
    # Field: properties Type: 11 (.google.cloud.oracledatabase.v1.PluggableDatabaseProperties)
    # Field: oci_url Type: 9 ()
    # Field: create_time Type: 11 (.google.protobuf.Timestamp)

# === Message: Google::Cloud::Oracledatabase::V1::PluggableDatabase::PluggableDatabaseProperties ===
    # Fields for PluggableDatabaseProperties
    # Field: compartment_id Type: 9 ()
    # Field: connection_strings Type: 11 (.google.cloud.oracledatabase.v1.PluggableDatabaseConnectionStrings)
    # Field: container_database_ocid Type: 9 ()
    # Field: defined_tags Type: 11 (.google.cloud.oracledatabase.v1.PluggableDatabaseProperties.DefinedTagsEntry)
    # Field: freeform_tags Type: 11 (.google.cloud.oracledatabase.v1.PluggableDatabaseProperties.FreeformTagsEntry)
    # Field: ocid Type: 9 ()
    # Field: is_restricted Type: 8 ()
    # Field: lifecycle_details Type: 9 ()
    # Field: lifecycle_state Type: 14 (.google.cloud.oracledatabase.v1.PluggableDatabaseProperties.PluggableDatabaseLifecycleState)
    # Field: pdb_name Type: 9 ()
    # Field: pdb_node_level_details Type: 11 (.google.cloud.oracledatabase.v1.PluggableDatabaseNodeLevelDetails)
    # Field: database_management_config Type: 11 (.google.cloud.oracledatabase.v1.DatabaseManagementConfig)
    # Field: operations_insights_state Type: 14 (.google.cloud.oracledatabase.v1.PluggableDatabaseProperties.OperationsInsightsState)

# Enum: PluggableDatabaseProperties::PluggableDatabaseLifecycleState
our $PluggableDatabaseProperties_PLUGGABLE_DATABASE_LIFECYCLE_STATE_UNSPECIFIED = 0;
our $PluggableDatabaseProperties_PROVISIONING = 1;
our $PluggableDatabaseProperties_AVAILABLE = 2;
our $PluggableDatabaseProperties_TERMINATING = 3;
our $PluggableDatabaseProperties_TERMINATED = 4;
our $PluggableDatabaseProperties_UPDATING = 5;
our $PluggableDatabaseProperties_FAILED = 6;
our $PluggableDatabaseProperties_RELOCATING = 7;
our $PluggableDatabaseProperties_RELOCATED = 8;
our $PluggableDatabaseProperties_REFRESHING = 9;
our $PluggableDatabaseProperties_RESTORE_IN_PROGRESS = 10;
our $PluggableDatabaseProperties_RESTORE_FAILED = 11;
our $PluggableDatabaseProperties_BACKUP_IN_PROGRESS = 12;
our $PluggableDatabaseProperties_DISABLED = 13;

# Enum: PluggableDatabaseProperties::OperationsInsightsState
our $PluggableDatabaseProperties_OPERATIONS_INSIGHTS_STATE_UNSPECIFIED = 0;
our $PluggableDatabaseProperties_ENABLING = 1;
our $PluggableDatabaseProperties_ENABLED = 2;
our $PluggableDatabaseProperties_DISABLING = 3;
our $PluggableDatabaseProperties_NOT_ENABLED = 4;
our $PluggableDatabaseProperties_FAILED_ENABLING = 5;
our $PluggableDatabaseProperties_FAILED_DISABLING = 6;

# === Message: Google::Cloud::Oracledatabase::V1::PluggableDatabase::PluggableDatabaseConnectionStrings ===
    # Fields for PluggableDatabaseConnectionStrings
    # Field: all_connection_strings Type: 11 (.google.cloud.oracledatabase.v1.PluggableDatabaseConnectionStrings.AllConnectionStringsEntry)
    # Field: pdb_default Type: 9 ()
    # Field: pdb_ip_default Type: 9 ()

# === Message: Google::Cloud::Oracledatabase::V1::PluggableDatabase::PluggableDatabaseNodeLevelDetails ===
    # Fields for PluggableDatabaseNodeLevelDetails
    # Field: node_name Type: 9 ()
    # Field: open_mode Type: 14 (.google.cloud.oracledatabase.v1.PluggableDatabaseNodeLevelDetails.PluggableDatabaseOpenMode)
    # Field: pluggable_database_id Type: 9 ()

# Enum: PluggableDatabaseNodeLevelDetails::PluggableDatabaseOpenMode
our $PluggableDatabaseNodeLevelDetails_PLUGGABLE_DATABASE_OPEN_MODE_UNSPECIFIED = 0;
our $PluggableDatabaseNodeLevelDetails_READ_ONLY = 1;
our $PluggableDatabaseNodeLevelDetails_READ_WRITE = 2;
our $PluggableDatabaseNodeLevelDetails_MOUNTED = 3;
our $PluggableDatabaseNodeLevelDetails_MIGRATE = 4;

# === Message: Google::Cloud::Oracledatabase::V1::PluggableDatabase::DatabaseManagementConfig ===
    # Fields for DatabaseManagementConfig
    # Field: management_state Type: 14 (.google.cloud.oracledatabase.v1.DatabaseManagementConfig.ManagementState)
    # Field: management_type Type: 14 (.google.cloud.oracledatabase.v1.DatabaseManagementConfig.ManagementType)

# Enum: DatabaseManagementConfig::ManagementState
our $DatabaseManagementConfig_MANAGEMENT_STATE_UNSPECIFIED = 0;
our $DatabaseManagementConfig_ENABLING = 1;
our $DatabaseManagementConfig_ENABLED = 2;
our $DatabaseManagementConfig_DISABLING = 3;
our $DatabaseManagementConfig_DISABLED = 4;
our $DatabaseManagementConfig_UPDATING = 5;
our $DatabaseManagementConfig_FAILED_ENABLING = 6;
our $DatabaseManagementConfig_FAILED_DISABLING = 7;
our $DatabaseManagementConfig_FAILED_UPDATING = 8;

# Enum: DatabaseManagementConfig::ManagementType
our $DatabaseManagementConfig_MANAGEMENT_TYPE_UNSPECIFIED = 0;
our $DatabaseManagementConfig_BASIC = 1;
our $DatabaseManagementConfig_ADVANCED = 2;

# === Message: Google::Cloud::Oracledatabase::V1::PluggableDatabase::GetPluggableDatabaseRequest ===
    # Fields for GetPluggableDatabaseRequest
    # Field: name Type: 9 ()

# === Message: Google::Cloud::Oracledatabase::V1::PluggableDatabase::ListPluggableDatabasesRequest ===
    # Fields for ListPluggableDatabasesRequest
    # Field: parent Type: 9 ()
    # Field: page_size Type: 5 ()
    # Field: page_token Type: 9 ()
    # Field: filter Type: 9 ()

# === Message: Google::Cloud::Oracledatabase::V1::PluggableDatabase::ListPluggableDatabasesResponse ===
    # Fields for ListPluggableDatabasesResponse
    # Field: pluggable_databases Type: 11 (.google.cloud.oracledatabase.v1.PluggableDatabase)
    # Field: next_page_token Type: 9 ()

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Oracledatabase::V1::PluggableDatabase - Compiled Protocol Buffers messages for google/cloud/oracledatabase/v1/pluggable_database.proto

=head1 SYNOPSIS

    use Google::Cloud::Oracledatabase::V1::PluggableDatabase;

    my $msg = Google::Cloud::Oracledatabase::V1::PluggableDatabase::PluggableDatabase->new({
        name => $name,
        properties => $properties,
        oci_url => $oci_url,
        create_time => $create_time,
    });

    # Read or update a field
    my $val = $msg->name();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Oracledatabase::V1::PluggableDatabase::PluggableDatabase->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/oracledatabase/v1/pluggable_database.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Oracledatabase::V1::PluggableDatabase::PluggableDatabase

The PluggableDatabase resource.
https://docs.oracle.com/en-us/iaas/api/#/en/database/20160918/PluggableDatabase/

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Identifier. The name of the PluggableDatabase resource in the following
format:
projects/{project}/locations/{region}/pluggableDatabases/{pluggable_database}

=item * C<< $msg->properties() >> / C<< $msg->properties($value) >>

Type: C<Message> (L<Google::Cloud::Oracledatabase::V1::PluggableDatabase::PluggableDatabaseProperties>)

Optional. The properties of the PluggableDatabase.

=item * C<< $msg->oci_url() >> / C<< $msg->oci_url($value) >>

Type: C<String>

Output only. HTTPS link to OCI resources exposed to Customer via UI
Interface.

=item * C<< $msg->create_time() >> / C<< $msg->create_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Output only. The date and time that the PluggableDatabase was created.

=back

=head2 Google::Cloud::Oracledatabase::V1::PluggableDatabase::PluggableDatabaseProperties

The properties of a PluggableDatabase.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->compartment_id() >> / C<< $msg->compartment_id($value) >>

Type: C<String>

Required. The OCID of the compartment.

=item * C<< $msg->connection_strings() >> / C<< $msg->connection_strings($value) >>

Type: C<Message> (L<Google::Cloud::Oracledatabase::V1::PluggableDatabase::PluggableDatabaseConnectionStrings>)

Optional. The Connection strings used to connect to the Oracle Database.

=item * C<< $msg->container_database_ocid() >> / C<< $msg->container_database_ocid($value) >>

Type: C<String>

Required. The OCID of the CDB.

=item * C<< $msg->defined_tags() >> / C<< $msg->defined_tags($value) >>

Type: C<Message> (L<Google::Cloud::Oracledatabase::V1::PluggableDatabase::PluggableDatabaseProperties::DefinedTagsEntry>)

Optional. Defined tags for this resource. Each key is predefined and scoped
to a namespace.

=item * C<< $msg->freeform_tags() >> / C<< $msg->freeform_tags($value) >>

Type: C<Message> (L<Google::Cloud::Oracledatabase::V1::PluggableDatabase::PluggableDatabaseProperties::FreeformTagsEntry>)

Optional. Free-form tags for this resource. Each tag is a simple key-value
pair with no predefined name, type, or namespace.

=item * C<< $msg->ocid() >> / C<< $msg->ocid($value) >>

Type: C<String>

Output only. The OCID of the pluggable database.

=item * C<< $msg->is_restricted() >> / C<< $msg->is_restricted($value) >>

Type: C<Bool>

Optional. The restricted mode of the pluggable database. If a pluggable
database is opened in restricted mode, the user needs both create a session
and have restricted session privileges to connect to it.

=item * C<< $msg->lifecycle_details() >> / C<< $msg->lifecycle_details($value) >>

Type: C<String>

Output only. Additional information about the current lifecycle state.

=item * C<< $msg->lifecycle_state() >> / C<< $msg->lifecycle_state($value) >>

Type: C<Enum> (L<Google::Cloud::Oracledatabase::V1::PluggableDatabaseProperties::PluggableDatabaseLifecycleState>)

Output only. The current state of the pluggable database.

=item * C<< $msg->pdb_name() >> / C<< $msg->pdb_name($value) >>

Type: C<String>

Required. The database name.

=item * C<< $msg->pdb_node_level_details() >> / C<< $msg->pdb_node_level_details($value) >>

Type: C<Message> (L<Google::Cloud::Oracledatabase::V1::PluggableDatabase::PluggableDatabaseNodeLevelDetails>)

Optional. Pluggable Database Node Level Details

=item * C<< $msg->database_management_config() >> / C<< $msg->database_management_config($value) >>

Type: C<Message> (L<Google::Cloud::Oracledatabase::V1::PluggableDatabase::DatabaseManagementConfig>)

Output only. The configuration of the Database Management service.

=item * C<< $msg->operations_insights_state() >> / C<< $msg->operations_insights_state($value) >>

Type: C<Enum> (L<Google::Cloud::Oracledatabase::V1::PluggableDatabaseProperties::OperationsInsightsState>)

Output only. The status of Operations Insights for this Database.

=back

=head3 Enum: PluggableDatabaseProperties::PluggableDatabaseLifecycleState

=over 4

=item * C<PLUGGABLE_DATABASE_LIFECYCLE_STATE_UNSPECIFIED> => C<0>

=item * C<PROVISIONING> => C<1>

=item * C<AVAILABLE> => C<2>

=item * C<TERMINATING> => C<3>

=item * C<TERMINATED> => C<4>

=item * C<UPDATING> => C<5>

=item * C<FAILED> => C<6>

=item * C<RELOCATING> => C<7>

=item * C<RELOCATED> => C<8>

=item * C<REFRESHING> => C<9>

=item * C<RESTORE_IN_PROGRESS> => C<10>

=item * C<RESTORE_FAILED> => C<11>

=item * C<BACKUP_IN_PROGRESS> => C<12>

=item * C<DISABLED> => C<13>

=back

=head3 Enum: PluggableDatabaseProperties::OperationsInsightsState

=over 4

=item * C<OPERATIONS_INSIGHTS_STATE_UNSPECIFIED> => C<0>

=item * C<ENABLING> => C<1>

=item * C<ENABLED> => C<2>

=item * C<DISABLING> => C<3>

=item * C<NOT_ENABLED> => C<4>

=item * C<FAILED_ENABLING> => C<5>

=item * C<FAILED_DISABLING> => C<6>

=back

=head2 Google::Cloud::Oracledatabase::V1::PluggableDatabase::PluggableDatabaseConnectionStrings

The connection strings used to connect to the Oracle Database.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->all_connection_strings() >> / C<< $msg->all_connection_strings($value) >>

Type: C<Message> (L<Google::Cloud::Oracledatabase::V1::PluggableDatabase::PluggableDatabaseConnectionStrings::AllConnectionStringsEntry>)

Optional. All connection strings to use to connect to the pluggable
database.

=item * C<< $msg->pdb_default() >> / C<< $msg->pdb_default($value) >>

Type: C<String>

Optional. The default connection string to use to connect to the pluggable
database.

=item * C<< $msg->pdb_ip_default() >> / C<< $msg->pdb_ip_default($value) >>

Type: C<String>

Optional. The default connection string to use to connect to the pluggable
database using IP.

=back

=head2 Google::Cloud::Oracledatabase::V1::PluggableDatabase::PluggableDatabaseNodeLevelDetails

The Pluggable Database Node Level Details.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->node_name() >> / C<< $msg->node_name($value) >>

Type: C<String>

Required. The Node name of the Database home.

=item * C<< $msg->open_mode() >> / C<< $msg->open_mode($value) >>

Type: C<Enum> (L<Google::Cloud::Oracledatabase::V1::PluggableDatabaseNodeLevelDetails::PluggableDatabaseOpenMode>)

Required. The mode that the pluggable database is in to open it.

=item * C<< $msg->pluggable_database_id() >> / C<< $msg->pluggable_database_id($value) >>

Type: C<String>

Required. The OCID of the Pluggable Database.

=back

=head3 Enum: PluggableDatabaseNodeLevelDetails::PluggableDatabaseOpenMode

=over 4

=item * C<PLUGGABLE_DATABASE_OPEN_MODE_UNSPECIFIED> => C<0>

=item * C<READ_ONLY> => C<1>

=item * C<READ_WRITE> => C<2>

=item * C<MOUNTED> => C<3>

=item * C<MIGRATE> => C<4>

=back

=head2 Google::Cloud::Oracledatabase::V1::PluggableDatabase::DatabaseManagementConfig

The configuration of the Database Management service.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->management_state() >> / C<< $msg->management_state($value) >>

Type: C<Enum> (L<Google::Cloud::Oracledatabase::V1::DatabaseManagementConfig::ManagementState>)

Output only. The status of the Database Management service.

=item * C<< $msg->management_type() >> / C<< $msg->management_type($value) >>

Type: C<Enum> (L<Google::Cloud::Oracledatabase::V1::DatabaseManagementConfig::ManagementType>)

Output only. The Database Management type.

=back

=head3 Enum: DatabaseManagementConfig::ManagementState

=over 4

=item * C<MANAGEMENT_STATE_UNSPECIFIED> => C<0>

=item * C<ENABLING> => C<1>

=item * C<ENABLED> => C<2>

=item * C<DISABLING> => C<3>

=item * C<DISABLED> => C<4>

=item * C<UPDATING> => C<5>

=item * C<FAILED_ENABLING> => C<6>

=item * C<FAILED_DISABLING> => C<7>

=item * C<FAILED_UPDATING> => C<8>

=back

=head3 Enum: DatabaseManagementConfig::ManagementType

=over 4

=item * C<MANAGEMENT_TYPE_UNSPECIFIED> => C<0>

=item * C<BASIC> => C<1>

=item * C<ADVANCED> => C<2>

=back

=head2 Google::Cloud::Oracledatabase::V1::PluggableDatabase::GetPluggableDatabaseRequest

The request for `PluggableDatabase.Get`.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. The name of the PluggableDatabase resource in the following
format:
projects/{project}/locations/{region}/pluggableDatabases/{pluggable_database}

=back

=head2 Google::Cloud::Oracledatabase::V1::PluggableDatabase::ListPluggableDatabasesRequest

The request for `PluggableDatabase.List`.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->parent() >> / C<< $msg->parent($value) >>

Type: C<String>

Required. The parent, which owns this collection of PluggableDatabases.
Format: projects/{project}/locations/{location}

=item * C<< $msg->page_size() >> / C<< $msg->page_size($value) >>

Type: C<Int32>

Optional. The maximum number of PluggableDatabases to return. The service
may return fewer than this value.

=item * C<< $msg->page_token() >> / C<< $msg->page_token($value) >>

Type: C<String>

Optional. A page token, received from a previous `ListPluggableDatabases`
call. Provide this to retrieve the subsequent page.

When paginating, all other parameters provided to `ListPluggableDatabases`
must match the call that provided the page token.

=item * C<< $msg->filter() >> / C<< $msg->filter($value) >>

Type: C<String>

Optional. An expression for filtering the results of the request. List for
pluggable databases is supported only with a valid container database (full
resource name) filter in this format:
`database="projects/{project}/locations/{location}/databases/{database}"`

=back

=head2 Google::Cloud::Oracledatabase::V1::PluggableDatabase::ListPluggableDatabasesResponse

The response for `PluggableDatabase.List`.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->pluggable_databases() >> / C<< $msg->pluggable_databases($value) >>

Type: C<Message> (L<Google::Cloud::Oracledatabase::V1::PluggableDatabase::PluggableDatabase>)

The list of PluggableDatabases.

=item * C<< $msg->next_page_token() >> / C<< $msg->next_page_token($value) >>

Type: C<String>

A token identifying a page of results the server should return.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Oracledatabase::V1::PluggableDatabase::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
