package Google::Cloud::Oracledatabase::V1::ExadbVmCluster;

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
    eval { require Google::Cloud::Oracledatabase::V1::Common };
    eval { require Google::Protobuf::Timestamp };
    eval { require Google::Type::Datetime };
    my $descriptor_b64 = <<'EOF';
CjVnb29nbGUvY2xvdWQvb3JhY2xlZGF0YWJhc2UvdjEvZXhhZGJfdm1fY2x1c3Rlci5wcm90
bxIeZ29vZ2xlLmNsb3VkLm9yYWNsZWRhdGFiYXNlLnYxGh9nb29nbGUvYXBpL2ZpZWxkX2Jl
aGF2aW9yLnByb3RvGhlnb29nbGUvYXBpL3Jlc291cmNlLnByb3RvGitnb29nbGUvY2xvdWQv
b3JhY2xlZGF0YWJhc2UvdjEvY29tbW9uLnByb3RvGh9nb29nbGUvcHJvdG9idWYvdGltZXN0
YW1wLnByb3RvGhpnb29nbGUvdHlwZS9kYXRldGltZS5wcm90byLCCAoORXhhZGJWbUNsdXN0
ZXISFwoEbmFtZRgBIAEoCUID4EEIUgRuYW1lEl0KCnByb3BlcnRpZXMYAiABKAsyOC5nb29n
bGUuY2xvdWQub3JhY2xlZGF0YWJhc2UudjEuRXhhZGJWbUNsdXN0ZXJQcm9wZXJ0aWVzQgPg
QQJSCnByb3BlcnRpZXMSLgoPZ2NwX29yYWNsZV96b25lGAMgASgJQgbgQQPgQQVSDWdjcE9y
YWNsZVpvbmUSVwoGbGFiZWxzGAUgAygLMjouZ29vZ2xlLmNsb3VkLm9yYWNsZWRhdGFiYXNl
LnYxLkV4YWRiVm1DbHVzdGVyLkxhYmVsc0VudHJ5QgPgQQFSBmxhYmVscxJUCgtvZGJfbmV0
d29yaxgGIAEoCUIz4EEB4EEF+kEqCihvcmFjbGVkYXRhYmFzZS5nb29nbGVhcGlzLmNvbS9P
ZGJOZXR3b3JrUgpvZGJOZXR3b3JrElEKCm9kYl9zdWJuZXQYByABKAlCMuBBAuBBBfpBKQon
b3JhY2xlZGF0YWJhc2UuZ29vZ2xlYXBpcy5jb20vT2RiU3VibmV0UglvZGJTdWJuZXQSXgoR
YmFja3VwX29kYl9zdWJuZXQYCCABKAlCMuBBAuBBBfpBKQonb3JhY2xlZGF0YWJhc2UuZ29v
Z2xlYXBpcy5jb20vT2RiU3VibmV0Ug9iYWNrdXBPZGJTdWJuZXQSKQoMZGlzcGxheV9uYW1l
GAkgASgJQgbgQQLgQQVSC2Rpc3BsYXlOYW1lEkAKC2NyZWF0ZV90aW1lGAogASgLMhouZ29v
Z2xlLnByb3RvYnVmLlRpbWVzdGFtcEID4EEDUgpjcmVhdGVUaW1lEioKDmVudGl0bGVtZW50
X2lkGAsgASgJQgPgQQNSDWVudGl0bGVtZW50SWQSZQoSaWRlbnRpdHlfY29ubmVjdG9yGAwg
ASgLMjEuZ29vZ2xlLmNsb3VkLm9yYWNsZWRhdGFiYXNlLnYxLklkZW50aXR5Q29ubmVjdG9y
QgPgQQNSEWlkZW50aXR5Q29ubmVjdG9yEkkKG2lkZW50aXR5X2Nvbm5lY3Rvcl9kaXNhYmxl
ZBgNIAEoCEIJ4EEB4EEE4EEFUhlpZGVudGl0eUNvbm5lY3RvckRpc2FibGVkGjkKC0xhYmVs
c0VudHJ5EhAKA2tleRgBIAEoCVIDa2V5EhQKBXZhbHVlGAIgASgJUgV2YWx1ZToCOAE6nwHq
QZsBCixvcmFjbGVkYXRhYmFzZS5nb29nbGVhcGlzLmNvbS9FeGFkYlZtQ2x1c3RlchJKcHJv
amVjdHMve3Byb2plY3R9L2xvY2F0aW9ucy97bG9jYXRpb259L2V4YWRiVm1DbHVzdGVycy97
ZXhhZGJfdm1fY2x1c3Rlcn0qD2V4YWRiVm1DbHVzdGVyczIOZXhhZGJWbUNsdXN0ZXIiUwoc
RXhhZGJWbUNsdXN0ZXJTdG9yYWdlRGV0YWlscxIzChRzaXplX2luX2dic19wZXJfbm9kZRgC
IAEoBUID4EECUhBzaXplSW5HYnNQZXJOb2RlIv0NChhFeGFkYlZtQ2x1c3RlclByb3BlcnRp
ZXMSKQoMY2x1c3Rlcl9uYW1lGAEgASgJQgbgQQHgQQVSC2NsdXN0ZXJOYW1lEioKDWdyaWRf
aW1hZ2VfaWQYAiABKAlCBuBBAuBBBVILZ3JpZEltYWdlSWQSIgoKbm9kZV9jb3VudBgDIAEo
BUID4EECUglub2RlQ291bnQSRAobZW5hYmxlZF9lY3B1X2NvdW50X3Blcl9ub2RlGBQgASgF
QgbgQQLgQQVSF2VuYWJsZWRFY3B1Q291bnRQZXJOb2RlEkoKHmFkZGl0aW9uYWxfZWNwdV9j
b3VudF9wZXJfbm9kZRgVIAEoBUIG4EEB4EEFUhphZGRpdGlvbmFsRWNwdUNvdW50UGVyTm9k
ZRJ5ChZ2bV9maWxlX3N5c3RlbV9zdG9yYWdlGAYgASgLMjwuZ29vZ2xlLmNsb3VkLm9yYWNs
ZWRhdGFiYXNlLnYxLkV4YWRiVm1DbHVzdGVyU3RvcmFnZURldGFpbHNCBuBBAuBBBVITdm1G
aWxlU3lzdGVtU3RvcmFnZRJyCg1saWNlbnNlX21vZGVsGAcgASgOMkUuZ29vZ2xlLmNsb3Vk
Lm9yYWNsZWRhdGFiYXNlLnYxLkV4YWRiVm1DbHVzdGVyUHJvcGVydGllcy5MaWNlbnNlTW9k
ZWxCBuBBAeBBBVIMbGljZW5zZU1vZGVsEnoKGWV4YXNjYWxlX2RiX3N0b3JhZ2VfdmF1bHQY
CCABKAlCP+BBAuBBBfpBNgo0b3JhY2xlZGF0YWJhc2UuZ29vZ2xlYXBpcy5jb20vRXhhc2Nh
bGVEYlN0b3JhZ2VWYXVsdFIWZXhhc2NhbGVEYlN0b3JhZ2VWYXVsdBIvCg9ob3N0bmFtZV9w
cmVmaXgYCSABKAlCBuBBAuBBBVIOaG9zdG5hbWVQcmVmaXgSHwoIaG9zdG5hbWUYCiABKAlC
A+BBA1IIaG9zdG5hbWUSLgoPc3NoX3B1YmxpY19rZXlzGAsgAygJQgbgQQLgQQVSDXNzaFB1
YmxpY0tleXMSewoXZGF0YV9jb2xsZWN0aW9uX29wdGlvbnMYDCABKAsyOy5nb29nbGUuY2xv
dWQub3JhY2xlZGF0YWJhc2UudjEuRGF0YUNvbGxlY3Rpb25PcHRpb25zQ29tbW9uQgbgQQHg
QQVSFWRhdGFDb2xsZWN0aW9uT3B0aW9ucxI6Cgl0aW1lX3pvbmUYDSABKAsyFS5nb29nbGUu
dHlwZS5UaW1lWm9uZUIG4EEB4EEFUgh0aW1lWm9uZRKDAQoPbGlmZWN5Y2xlX3N0YXRlGA4g
ASgOMlUuZ29vZ2xlLmNsb3VkLm9yYWNsZWRhdGFiYXNlLnYxLkV4YWRiVm1DbHVzdGVyUHJv
cGVydGllcy5FeGFkYlZtQ2x1c3RlckxpZmVjeWNsZVN0YXRlQgPgQQNSDmxpZmVjeWNsZVN0
YXRlEngKD3NoYXBlX2F0dHJpYnV0ZRgPIAEoDjJHLmdvb2dsZS5jbG91ZC5vcmFjbGVkYXRh
YmFzZS52MS5FeGFkYlZtQ2x1c3RlclByb3BlcnRpZXMuU2hhcGVBdHRyaWJ1dGVCBuBBAuBB
BVIOc2hhcGVBdHRyaWJ1dGUSKQoObWVtb3J5X3NpemVfZ2IYECABKAVCA+BBA1IMbWVtb3J5
U2l6ZUdiEjsKFnNjYW5fbGlzdGVuZXJfcG9ydF90Y3AYESABKAVCBuBBAeBBBVITc2Nhbkxp
c3RlbmVyUG9ydFRjcBIcCgdvY2lfdXJpGBIgASgJQgPgQQNSBm9jaVVyaRIiCgpnaV92ZXJz
aW9uGBMgASgJQgPgQQNSCWdpVmVyc2lvbiJfCgxMaWNlbnNlTW9kZWwSHQoZTElDRU5TRV9N
T0RFTF9VTlNQRUNJRklFRBAAEhQKEExJQ0VOU0VfSU5DTFVERUQQARIaChZCUklOR19ZT1VS
X09XTl9MSUNFTlNFEAIiyQEKHEV4YWRiVm1DbHVzdGVyTGlmZWN5Y2xlU3RhdGUSMAosRVhB
REJfVk1fQ0xVU1RFUl9MSUZFQ1lDTEVfU1RBVEVfVU5TUEVDSUZJRUQQABIQCgxQUk9WSVNJ
T05JTkcQARINCglBVkFJTEFCTEUQAhIMCghVUERBVElORxADEg8KC1RFUk1JTkFUSU5HEAQS
DgoKVEVSTUlOQVRFRBAFEgoKBkZBSUxFRBAGEhsKF01BSU5URU5BTkNFX0lOX1BST0dSRVNT
EAciVwoOU2hhcGVBdHRyaWJ1dGUSHwobU0hBUEVfQVRUUklCVVRFX1VOU1BFQ0lGSUVEEAAS
EQoNU01BUlRfU1RPUkFHRRABEhEKDUJMT0NLX1NUT1JBR0UQAkLtAQoiY29tLmdvb2dsZS5j
bG91ZC5vcmFjbGVkYXRhYmFzZS52MUITRXhhZGJWbUNsdXN0ZXJQcm90b1ABWkpjbG91ZC5n
b29nbGUuY29tL2dvL29yYWNsZWRhdGFiYXNlL2FwaXYxL29yYWNsZWRhdGFiYXNlcGI7b3Jh
Y2xlZGF0YWJhc2VwYqoCHkdvb2dsZS5DbG91ZC5PcmFjbGVEYXRhYmFzZS5WMcoCHkdvb2ds
ZVxDbG91ZFxPcmFjbGVEYXRhYmFzZVxWMeoCIUdvb2dsZTo6Q2xvdWQ6Ok9yYWNsZURhdGFi
YXNlOjpWMUrtUQoHEgUOALMCAQq8BAoBDBIDDgASMrEEIENvcHlyaWdodCAyMDI2IEdvb2ds
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
CggKAQISAxAAJwoJCgIDABIDEgApCgkKAgMBEgMTACMKCQoCAwISAxQANQoJCgIDAxIDFQAp
CgkKAgMEEgMWACQKCAoBCBIDGAA7CgkKAgglEgMYADsKCAoBCBIDGQBhCgkKAggLEgMZAGEK
CAoBCBIDGgAiCgkKAggKEgMaACIKCAoBCBIDGwA0CgkKAggIEgMbADQKCAoBCBIDHAA7CgkK
AggBEgMcADsKCAoBCBIDHQA7CgkKAggpEgMdADsKCAoBCBIDHgA6CgkKAggtEgMeADoKsgEK
AgQAEgUjAIEBARqkASBFeGFkYlZtQ2x1c3RlciByZXByZXNlbnRzIGEgY2x1c3RlciBvZiBW
TXMgdGhhdCBhcmUgdXNlZCB0byBydW4gRXhhZGF0YQogd29ya2xvYWRzLgogaHR0cHM6Ly9k
b2NzLm9yYWNsZS5jb20vZW4tdXMvaWFhcy9hcGkvIy9lbi9kYXRhYmFzZS8yMDE2MDkxOC9F
eGFkYlZtQ2x1c3Rlci8KCgoKAwQAARIDIwgWCgsKAwQABxIEJAIpBAoNCgUEAAedCBIEJAIp
BAqnAQoEBAACABIDLgI9GpkBIElkZW50aWZpZXIuIFRoZSBuYW1lIG9mIHRoZSBFeGFkYlZt
Q2x1c3RlciByZXNvdXJjZSBpbiB0aGUgZm9sbG93aW5nCiBmb3JtYXQ6CiBwcm9qZWN0cy97
cHJvamVjdH0vbG9jYXRpb25zL3tyZWdpb259L2V4YWRiVm1DbHVzdGVycy97ZXhhZGJfdm1f
Y2x1c3Rlcn0KCgwKBQQAAgAFEgMuAggKDAoFBAACAAESAy4JDQoMCgUEAAIAAxIDLhARCgwK
BQQAAgAIEgMuEjwKDwoIBAACAAicCAASAy4TOwo/CgQEAAIBEgQxAjIvGjEgUmVxdWlyZWQu
IFRoZSBwcm9wZXJ0aWVzIG9mIHRoZSBFeGFkYlZtQ2x1c3Rlci4KCgwKBQQAAgEGEgMxAhoK
DAoFBAACAQESAzEbJQoMCgUEAAIBAxIDMSgpCgwKBQQAAgEIEgMyBi4KDwoIBAACAQicCAAS
AzIHLQrUAQoEBAACAhIENwI6BBrFASBPdXRwdXQgb25seS4gSW1tdXRhYmxlLiBUaGUgR0NQ
IE9yYWNsZSB6b25lIHdoZXJlIE9yYWNsZSBFeGFkYlZtQ2x1c3RlciBpcwogaG9zdGVkLiBF
eGFtcGxlOiB1cy1lYXN0NC1iLXIyLiBEdXJpbmcgY3JlYXRpb24sIHRoZSBzeXN0ZW0gd2ls
bCBwaWNrIHRoZQogem9uZSBhc3NpZ25lZCB0byB0aGUgRXhhc2NhbGVEYlN0b3JhZ2VWYXVs
dC4KCgwKBQQAAgIFEgM3AggKDAoFBAACAgESAzcJGAoMCgUEAAICAxIDNxscCg0KBQQAAgII
EgQ3HToDCg8KCAQAAgIInAgAEgM4BC0KDwoIBAACAgicCAESAzkEKwpPCgQEAAIDEgM9Akoa
QiBPcHRpb25hbC4gVGhlIGxhYmVscyBvciB0YWdzIGFzc29jaWF0ZWQgd2l0aCB0aGUgRXhh
ZGJWbUNsdXN0ZXIuCgoMCgUEAAIDBhIDPQIVCgwKBQQAAgMBEgM9FhwKDAoFBAACAwMSAz0f
IAoMCgUEAAIDCBIDPSFJCg8KCAQAAgMInAgAEgM9IkgKjQIKBAQAAgQSBEQCSgQa/gEgT3B0
aW9uYWwuIEltbXV0YWJsZS4gVGhlIG5hbWUgb2YgdGhlIE9kYk5ldHdvcmsgYXNzb2NpYXRl
ZCB3aXRoIHRoZQogRXhhZGJWbUNsdXN0ZXIuIEZvcm1hdDoKIHByb2plY3RzL3twcm9qZWN0
fS9sb2NhdGlvbnMve2xvY2F0aW9ufS9vZGJOZXR3b3Jrcy97b2RiX25ldHdvcmt9IEl0IGlz
CiBvcHRpb25hbCBidXQgaWYgc3BlY2lmaWVkLCB0aGlzIHNob3VsZCBtYXRjaCB0aGUgcGFy
ZW50IE9EQk5ldHdvcmsgb2YgdGhlCiBPZGJTdWJuZXQuCgoMCgUEAAIEBRIDRAIICgwKBQQA
AgQBEgNECRQKDAoFBAACBAMSA0QXGAoNCgUEAAIECBIERBlKAwoPCggEAAIECJwIABIDRQQq
Cg8KCAQAAgQInAgBEgNGBCsKDwoHBAACBAifCBIERwRJBQrZAQoEBAACBRIETwJVBBrKASBS
ZXF1aXJlZC4gSW1tdXRhYmxlLiBUaGUgbmFtZSBvZiB0aGUgT2RiU3VibmV0IGFzc29jaWF0
ZWQgd2l0aCB0aGUKIEV4YWRiVm1DbHVzdGVyIGZvciBJUCBhbGxvY2F0aW9uLiBGb3JtYXQ6
CiBwcm9qZWN0cy97cHJvamVjdH0vbG9jYXRpb25zL3tsb2NhdGlvbn0vb2RiTmV0d29ya3Mv
e29kYl9uZXR3b3JrfS9vZGJTdWJuZXRzL3tvZGJfc3VibmV0fQoKDAoFBAACBQUSA08CCAoM
CgUEAAIFARIDTwkTCgwKBQQAAgUDEgNPFhcKDQoFBAACBQgSBE8YVQMKDwoIBAACBQicCAAS
A1AEKgoPCggEAAIFCJwIARIDUQQrCg8KBwQAAgUInwgSBFIEVAUKzgEKBAQAAgYSBFoCYAQa
vwEgUmVxdWlyZWQuIEltbXV0YWJsZS4gVGhlIG5hbWUgb2YgdGhlIGJhY2t1cCBPZGJTdWJu
ZXQgYXNzb2NpYXRlZCB3aXRoIHRoZQogRXhhZGJWbUNsdXN0ZXIuIEZvcm1hdDoKIHByb2pl
Y3RzL3twcm9qZWN0fS9sb2NhdGlvbnMve2xvY2F0aW9ufS9vZGJOZXR3b3Jrcy97b2RiX25l
dHdvcmt9L29kYlN1Ym5ldHMve29kYl9zdWJuZXR9CgoMCgUEAAIGBRIDWgIICgwKBQQAAgYB
EgNaCRoKDAoFBAACBgMSA1odHgoNCgUEAAIGCBIEWh9gAwoPCggEAAIGCJwIABIDWwQqCg8K
CAQAAgYInAgBEgNcBCsKDwoHBAACBgifCBIEXQRfBQreAQoEBAACBxIEZQJoBBrPASBSZXF1
aXJlZC4gSW1tdXRhYmxlLiBUaGUgZGlzcGxheSBuYW1lIGZvciB0aGUgRXhhZGJWbUNsdXN0
ZXIuIFRoZSBuYW1lIGRvZXMKIG5vdCBoYXZlIHRvIGJlIHVuaXF1ZSB3aXRoaW4geW91ciBw
cm9qZWN0LiBUaGUgbmFtZSBtdXN0IGJlIDEtMjU1CiBjaGFyYWN0ZXJzIGxvbmcgYW5kIGNh
biBvbmx5IGNvbnRhaW4gYWxwaGFudW1lcmljIGNoYXJhY3RlcnMuCgoMCgUEAAIHBRIDZQII
CgwKBQQAAgcBEgNlCRUKDAoFBAACBwMSA2UYGQoNCgUEAAIHCBIEZRpoAwoPCggEAAIHCJwI
ABIDZgQqCg8KCAQAAgcInAgBEgNnBCsKUwoEBAACCBIEawJsMhpFIE91dHB1dCBvbmx5LiBU
aGUgZGF0ZSBhbmQgdGltZSB0aGF0IHRoZSBFeGFkYlZtQ2x1c3RlciB3YXMgY3JlYXRlZC4K
CgwKBQQAAggGEgNrAhsKDAoFBAACCAESA2scJwoMCgUEAAIIAxIDayosCgwKBQQAAggIEgNs
BjEKDwoIBAACCAicCAASA2wHMApnCgQEAAIJEgNwAkkaWiBPdXRwdXQgb25seS4gVGhlIElE
IG9mIHRoZSBzdWJzY3JpcHRpb24gZW50aXRsZW1lbnQgYXNzb2NpYXRlZCB3aXRoIHRoZQog
RXhhZGJWbUNsdXN0ZXIuCgoMCgUEAAIJBRIDcAIICgwKBQQAAgkBEgNwCRcKDAoFBAACCQMS
A3AaHAoMCgUEAAIJCBIDcB1ICg8KCAQAAgkInAgAEgNwHkcKiwEKBAQAAgoSBHQCdTIafSBP
dXRwdXQgb25seS4gVGhlIGlkZW50aXR5IGNvbm5lY3RvciBkZXRhaWxzIHdoaWNoIHdpbGwg
YWxsb3cgT0NJIHRvCiBzZWN1cmVseSBhY2Nlc3MgdGhlIHJlc291cmNlcyBpbiB0aGUgY3Vz
dG9tZXIgcHJvamVjdC4KCgwKBQQAAgoGEgN0AhMKDAoFBAACCgESA3QUJgoMCgUEAAIKAxID
dCkrCgwKBQQAAgoIEgN1BjEKDwoIBAACCgicCAASA3UHMArtAgoEBAACCxIFfAKAAQQa3QIg
T3B0aW9uYWwuIElucHV0IG9ubHkuIEltbXV0YWJsZS4gSWYgc2V0IHRvIHRydWUsIGRpc2Fi
bGVzIHRoZSBhdXRvbWF0aWMKIHByb3Zpc2lvbmluZyBvZiB0aGUgV29ya2xvYWQgSWRlbnRp
dHkgQ29ubmVjdG9yIGR1cmluZyBjcmVhdGlvbi4gSWYgc2V0IHRvCiBmYWxzZSBvciBvbWl0
dGVkLCB0aGUgV29ya2xvYWQgSWRlbnRpdHkgQ29ubmVjdG9yIHdpbGwgYmUgYXV0b21hdGlj
YWxseQogcHJvdmlzaW9uZWQgYnkgZGVmYXVsdC4gTm90ZTogUHJvdmlzaW9uaW5nIHRoZSBX
b3JrbG9hZCBJZGVudGl0eSBDb25uZWN0b3IKIGlzIGEgcHJlcmVxdWlzaXRlIGZvciBlbmFi
bGluZyBHb29nbGUgQ2xvdWQgQ01FSy4KCgwKBQQAAgsFEgN8AgYKDAoFBAACCwESA3wHIgoM
CgUEAAILAxIDfCUnCg4KBQQAAgsIEgV8KIABAwoPCggEAAILCJwIABIDfQQqCg8KCAQAAgsI
nAgBEgN+BCwKDwoIBAACCwicCAISA38EKwpRCgIEARIGhAEAiQEBGkMgVGhlIHN0b3JhZ2Ug
YWxsb2NhdGlvbiBmb3IgdGhlIGV4YWRidm1jbHVzdGVyLCBpbiBnaWdhYnl0ZXMgKEdCKS4K
CgsKAwQBARIEhAEIJAq8AQoEBAECABIEiAECShqtASBSZXF1aXJlZC4gVGhlIHN0b3JhZ2Ug
YWxsb2NhdGlvbiBmb3IgdGhlIGV4YWRidm1jbHVzdGVyIHBlciBub2RlLCBpbgogZ2lnYWJ5
dGVzIChHQikuIFRoaXMgZmllbGQgaXMgdXNlZCB0byBjYWxjdWxhdGUgdGhlIHRvdGFsIHN0
b3JhZ2UKIGFsbG9jYXRpb24gZm9yIHRoZSBleGFkYnZtY2x1c3Rlci4KCg0KBQQBAgAFEgSI
AQIHCg0KBQQBAgABEgSIAQgcCg0KBQQBAgADEgSIAR8gCg0KBQQBAgAIEgSIASFJChAKCAQB
AgAInAgAEgSIASJICjQKAgQCEgaMAQCzAgEaJiBUaGUgcHJvcGVydGllcyBvZiBhbiBFeGFk
YlZtQ2x1c3Rlci4KCgsKAwQCARIEjAEIIApSCgQEAgQAEgaOAQKXAQMaQiBUaGUgT3JhY2xl
IGxpY2Vuc2UgbW9kZWwgdGhhdCBhcHBsaWVzIHRvIHRoZSBFeGFTY2FsZSBWTSBjbHVzdGVy
CgoNCgUEAgQAARIEjgEHEwoeCgYEAgQAAgASBJABBCIaDiBVbnNwZWNpZmllZC4KCg8KBwQC
BAACAAESBJABBB0KDwoHBAIEAAIAAhIEkAEgIQouCgYEAgQAAgESBJMBBBkaHiBEZWZhdWx0
IGlzIGxpY2Vuc2UgaW5jbHVkZWQuCgoPCgcEAgQAAgEBEgSTAQQUCg8KBwQCBAACAQISBJMB
FxgKKQoGBAIEAAICEgSWAQQfGhkgQnJpbmcgeW91ciBvd24gbGljZW5zZS4KCg8KBwQCBAAC
AgESBJYBBBoKDwoHBAIEAAICAhIElgEdHgpBCgQEAgQBEgaaAQKyAQMaMSBUaGUgdmFyaW91
cyBsaWZlY3ljbGUgc3RhdGVzIG9mIHRoZSBWTSBjbHVzdGVyLgoKDQoFBAIEAQESBJoBByMK
LAoGBAIEAQIAEgScAQQ1GhwgRGVmYXVsdCB1bnNwZWNpZmllZCB2YWx1ZS4KCg8KBwQCBAEC
AAESBJwBBDAKDwoHBAIEAQIAAhIEnAEzNApHCgYEAgQBAgESBJ8BBBUaNyBJbmRpY2F0ZXMg
dGhhdCB0aGUgcmVzb3VyY2UgaXMgaW4gcHJvdmlzaW9uaW5nIHN0YXRlLgoKDwoHBAIEAQIB
ARIEnwEEEAoPCgcEAgQBAgECEgSfARMUCkQKBgQCBAECAhIEogEEEho0IEluZGljYXRlcyB0
aGF0IHRoZSByZXNvdXJjZSBpcyBpbiBhdmFpbGFibGUgc3RhdGUuCgoPCgcEAgQBAgIBEgSi
AQQNCg8KBwQCBAECAgISBKIBEBEKQwoGBAIEAQIDEgSlAQQRGjMgSW5kaWNhdGVzIHRoYXQg
dGhlIHJlc291cmNlIGlzIGluIHVwZGF0aW5nIHN0YXRlLgoKDwoHBAIEAQIDARIEpQEEDAoP
CgcEAgQBAgMCEgSlAQ8QCkYKBgQCBAECBBIEqAEEFBo2IEluZGljYXRlcyB0aGF0IHRoZSBy
ZXNvdXJjZSBpcyBpbiB0ZXJtaW5hdGluZyBzdGF0ZS4KCg8KBwQCBAECBAESBKgBBA8KDwoH
BAIEAQIEAhIEqAESEwpFCgYEAgQBAgUSBKsBBBMaNSBJbmRpY2F0ZXMgdGhhdCB0aGUgcmVz
b3VyY2UgaXMgaW4gdGVybWluYXRlZCBzdGF0ZS4KCg8KBwQCBAECBQESBKsBBA4KDwoHBAIE
AQIFAhIEqwEREgpBCgYEAgQBAgYSBK4BBA8aMSBJbmRpY2F0ZXMgdGhhdCB0aGUgcmVzb3Vy
Y2UgaXMgaW4gZmFpbGVkIHN0YXRlLgoKDwoHBAIEAQIGARIErgEECgoPCgcEAgQBAgYCEgSu
AQ0OClIKBgQCBAECBxIEsQEEIBpCIEluZGljYXRlcyB0aGF0IHRoZSByZXNvdXJjZSBpcyBp
biBtYWludGVuYW5jZSBpbiBwcm9ncmVzcyBzdGF0ZS4KCg8KBwQCBAECBwESBLEBBBsKDwoH
BAIEAQIHAhIEsQEeHwrAAQoEBAIEAhIGtwECwAEDGq8BIFRoZSBzaGFwZSBhdHRyaWJ1dGUg
b2YgdGhlIFZNIGNsdXN0ZXIuIFRoZSB0eXBlIG9mIEV4YXNjYWxlIHN0b3JhZ2UgdXNlZAog
Zm9yIEV4YWRhdGEgVk0gY2x1c3Rlci4gVGhlIGRlZmF1bHQgaXMgU01BUlRfU1RPUkFHRSB3
aGljaCBzdXBwb3J0cyBPcmFjbGUKIERhdGFiYXNlIDIzYWkgYW5kIGxhdGVyCgoNCgUEAgQC
ARIEtwEHFQosCgYEAgQCAgASBLkBBCQaHCBEZWZhdWx0IHVuc3BlY2lmaWVkIHZhbHVlLgoK
DwoHBAIEAgIAARIEuQEEHwoPCgcEAgQCAgACEgS5ASIjCkIKBgQCBAICARIEvAEEFhoyIElu
ZGljYXRlcyB0aGF0IHRoZSByZXNvdXJjZSBpcyBpbiBzbWFydCBzdG9yYWdlLgoKDwoHBAIE
AgIBARIEvAEEEQoPCgcEAgQCAgECEgS8ARQVCkIKBgQCBAICAhIEvwEEFhoyIEluZGljYXRl
cyB0aGF0IHRoZSByZXNvdXJjZSBpcyBpbiBibG9jayBzdG9yYWdlLgoKDwoHBAIEAgICARIE
vwEEEQoPCgcEAgQCAgICEgS/ARQVCqICCgQEAgIAEgbGAQLJAQQakQIgT3B0aW9uYWwuIElt
bXV0YWJsZS4gVGhlIGNsdXN0ZXIgbmFtZSBmb3IgRXhhc2NhbGUgdm0gY2x1c3Rlci4gVGhl
IGNsdXN0ZXIKIG5hbWUgbXVzdCBiZWdpbiB3aXRoIGFuIGFscGhhYmV0aWMgY2hhcmFjdGVy
IGFuZCBtYXkgY29udGFpbiBoeXBoZW5zKC0pIGJ1dAogY2FuIG5vdCBjb250YWluIHVuZGVy
c2NvcmVzKF8pLiBJdCBzaG91bGQgYmUgbm90IG1vcmUgdGhhbiAxMSBjaGFyYWN0ZXJzCiBh
bmQgaXMgbm90IGNhc2Ugc2Vuc2l0aXZlLiBPQ0kgQ2x1c3RlciBuYW1lLgoKDQoFBAICAAUS
BMYBAggKDQoFBAICAAESBMYBCRUKDQoFBAICAAMSBMYBGBkKDwoFBAICAAgSBsYBGskBAwoQ
CggEAgIACJwIABIExwEEKgoQCggEAgIACJwIARIEyAEEKwpDCgQEAgIBEgbMAQLPAQQaMyBS
ZXF1aXJlZC4gSW1tdXRhYmxlLiBHcmlkIEluZnJhc3RydWN0dXJlIFZlcnNpb24uCgoNCgUE
AgIBBRIEzAECCAoNCgUEAgIBARIEzAEJFgoNCgUEAgIBAxIEzAEZGgoPCgUEAgIBCBIGzAEb
zwEDChAKCAQCAgEInAgAEgTNAQQqChAKCAQCAgEInAgBEgTOAQQrCkgKBAQCAgISBNIBAkAa
OiBSZXF1aXJlZC4gVGhlIG51bWJlciBvZiBub2Rlcy9WTXMgaW4gdGhlIEV4YWRiVm1DbHVz
dGVyLgoKDQoFBAICAgUSBNIBAgcKDQoFBAICAgESBNIBCBIKDQoFBAICAgMSBNIBFRYKDQoF
BAICAggSBNIBFz8KEAoIBAICAgicCAASBNIBGD4KggEKBAQCAgMSBtYBAtkBBBpyIFJlcXVp
cmVkLiBJbW11dGFibGUuIFRoZSBudW1iZXIgb2YgRUNQVXMgZW5hYmxlZCBwZXIgbm9kZSBm
b3IgYW4gZXhhZGF0YSB2bQogY2x1c3RlciBvbiBleGFzY2FsZSBpbmZyYXN0cnVjdHVyZS4K
Cg0KBQQCAgMFEgTWAQIHCg0KBQQCAgMBEgTWAQgjCg0KBQQCAgMDEgTWASYoCg8KBQQCAgMI
EgbWASnZAQMKEAoIBAICAwicCAASBNcBBCoKEAoIBAICAwicCAESBNgBBCsKhQEKBAQCAgQS
Bt0BAuABBBp1IE9wdGlvbmFsLiBJbW11dGFibGUuIFRoZSBudW1iZXIgb2YgYWRkaXRpb25h
bCBFQ1BVcyBwZXIgbm9kZSBmb3IgYW4gRXhhZGF0YQogVk0gY2x1c3RlciBvbiBleGFzY2Fs
ZSBpbmZyYXN0cnVjdHVyZS4KCg0KBQQCAgQFEgTdAQIHCg0KBQQCAgQBEgTdAQgmCg0KBQQC
AgQDEgTdASkrCg8KBQQCAgQIEgbdASzgAQMKEAoIBAICBAicCAASBN4BBCoKEAoIBAICBAic
CAESBN8BBCsKVAoEBAICBRIG4wEC5gEEGkQgUmVxdWlyZWQuIEltbXV0YWJsZS4gVG90YWwg
c3RvcmFnZSBkZXRhaWxzIGZvciB0aGUgRXhhZGJWbUNsdXN0ZXIuCgoNCgUEAgIFBhIE4wEC
HgoNCgUEAgIFARIE4wEfNQoNCgUEAgIFAxIE4wE4OQoPCgUEAgIFCBIG4wE65gEDChAKCAQC
AgUInAgAEgTkAQQqChAKCAQCAgUInAgBEgTlAQQrCk4KBAQCAgYSBukBAuwBBBo+IE9wdGlv
bmFsLiBJbW11dGFibGUuIFRoZSBsaWNlbnNlIHR5cGUgb2YgdGhlIEV4YWRiVm1DbHVzdGVy
LgoKDQoFBAICBgYSBOkBAg4KDQoFBAICBgESBOkBDxwKDQoFBAICBgMSBOkBHyAKDwoFBAIC
BggSBukBIewBAwoQCggEAgIGCJwIABIE6gEEKgoQCggEAgIGCJwIARIE6wEEKwr5AgoEBAIC
BxIG9AEC+gEEGugCIFJlcXVpcmVkLiBJbW11dGFibGUuIFRoZSBuYW1lIG9mIEV4YXNjYWxl
RGJTdG9yYWdlVmF1bHQgYXNzb2NpYXRlZCB3aXRoIHRoZQogRXhhZGJWbUNsdXN0ZXIuIEl0
IGNhbiByZWZlciB0byBhbiBleGlzdGluZyBFeGFzY2FsZURiU3RvcmFnZVZhdWx0LiBPciBh
CiBuZXcgb25lIGNhbiBiZSBjcmVhdGVkIGR1cmluZyB0aGUgRXhhZGJWbUNsdXN0ZXIgY3Jl
YXRpb24gKHJlcXVpcmVzCiBzdG9yYWdlX3ZhdWx0X3Byb3BlcnRpZXMgdG8gYmUgc2V0KS4K
IEZvcm1hdDoKIHByb2plY3RzL3twcm9qZWN0fS9sb2NhdGlvbnMve2xvY2F0aW9ufS9leGFz
Y2FsZURiU3RvcmFnZVZhdWx0cy97ZXhhc2NhbGVfZGJfc3RvcmFnZV92YXVsdH0KCg0KBQQC
AgcFEgT0AQIICg0KBQQCAgcBEgT0AQkiCg0KBQQCAgcDEgT0ASUmCg8KBQQCAgcIEgb0ASf6
AQMKEAoIBAICBwicCAASBPUBBCoKEAoIBAICBwicCAESBPYBBCsKEQoHBAICBwifCBIG9wEE
+QEFCkgKBAQCAggSBv0BAoACBBo4IFJlcXVpcmVkLiBJbW11dGFibGUuIFByZWZpeCBmb3Ig
Vk0gY2x1c3RlciBob3N0IG5hbWVzLgoKDQoFBAICCAUSBP0BAggKDQoFBAICCAESBP0BCRgK
DQoFBAICCAMSBP0BGxwKDwoFBAICCAgSBv0BHYACAwoQCggEAgIICJwIABIE/gEEKgoQCggE
AgIICJwIARIE/wEEKwpACgQEAgIJEgSDAgJDGjIgT3V0cHV0IG9ubHkuIFRoZSBob3N0bmFt
ZSBvZiB0aGUgRXhhZGJWbUNsdXN0ZXIuCgoNCgUEAgIJBRIEgwICCAoNCgUEAgIJARIEgwIJ
EQoNCgUEAgIJAxIEgwIUFgoNCgUEAgIJCBIEgwIXQgoQCggEAgIJCJwIABIEgwIYQQpSCgQE
AgIKEgaGAgKJAgQaQiBSZXF1aXJlZC4gSW1tdXRhYmxlLiBUaGUgU1NIIHB1YmxpYyBrZXlz
IGZvciB0aGUgRXhhZGJWbUNsdXN0ZXIuCgoNCgUEAgIKBBIEhgICCgoNCgUEAgIKBRIEhgIL
EQoNCgUEAgIKARIEhgISIQoNCgUEAgIKAxIEhgIkJgoPCgUEAgIKCBIGhgIniQIDChAKCAQC
AgoInAgAEgSHAgQqChAKCAQCAgoInAgBEgSIAgQrCl0KBAQCAgsSBowCAo8CBBpNIE9wdGlv
bmFsLiBJbW11dGFibGUuIEluZGljYXRlcyB1c2VyIHByZWZlcmVuY2UgZm9yIGRhdGEgY29s
bGVjdGlvbiBvcHRpb25zLgoKDQoFBAICCwYSBIwCAh0KDQoFBAICCwESBIwCHjUKDQoFBAIC
CwMSBIwCODoKDwoFBAICCwgSBowCO48CAwoQCggEAgILCJwIABIEjQIEKgoQCggEAgILCJwI
ARIEjgIEKwpLCgQEAgIMEgaSAgKVAgQaOyBPcHRpb25hbC4gSW1tdXRhYmxlLiBUaGUgdGlt
ZSB6b25lIG9mIHRoZSBFeGFkYlZtQ2x1c3Rlci4KCg0KBQQCAgwGEgSSAgIWCg0KBQQCAgwB
EgSSAhcgCg0KBQQCAgwDEgSSAiMlCg8KBQQCAgwIEgaSAiaVAgMKEAoIBAICDAicCAASBJMC
BCoKEAoIBAICDAicCAESBJQCBCsKNAoEBAICDRIGmAICmQIyGiQgT3V0cHV0IG9ubHkuIFN0
YXRlIG9mIHRoZSBjbHVzdGVyLgoKDQoFBAICDQYSBJgCAh4KDQoFBAICDQESBJgCHy4KDQoF
BAICDQMSBJgCMTMKDQoFBAICDQgSBJkCBjEKEAoIBAICDQicCAASBJkCBzAK1QEKBAQCAg4S
Bp4CAqECBBrEASBSZXF1aXJlZC4gSW1tdXRhYmxlLiBUaGUgc2hhcGUgYXR0cmlidXRlIG9m
IHRoZSBWTSBjbHVzdGVyLiBUaGUgdHlwZSBvZgogRXhhc2NhbGUgc3RvcmFnZSB1c2VkIGZv
ciBFeGFkYXRhIFZNIGNsdXN0ZXIuIFRoZSBkZWZhdWx0IGlzIFNNQVJUX1NUT1JBR0UKIHdo
aWNoIHN1cHBvcnRzIE9yYWNsZSBEYXRhYmFzZSAyM2FpIGFuZCBsYXRlcgoKDQoFBAICDgYS
BJ4CAhAKDQoFBAICDgESBJ4CESAKDQoFBAICDgMSBJ4CIyUKDwoFBAICDggSBp4CJqECAwoQ
CggEAgIOCJwIABIEnwIEKgoQCggEAgIOCJwIARIEoAIEKwqnAQoEBAICDxIEpgICSBqYASBP
dXRwdXQgb25seS4gTWVtb3J5IHBlciBWTSAoR0IpIChSZWFkLW9ubHkpOiBTaG93cyB0aGUg
YW1vdW50IG9mIG1lbW9yeQogYWxsb2NhdGVkIHRvIGVhY2ggVk0uIE1lbW9yeSBpcyBjYWxj
dWxhdGVkIGJhc2VkIG9uIDIuNzUgR0IgcGVyIFRvdGFsCiBFQ1BVcy4KCg0KBQQCAg8FEgSm
AgIHCg0KBQQCAg8BEgSmAggWCg0KBQQCAg8DEgSmAhkbCg0KBQQCAg8IEgSmAhxHChAKCAQC
Ag8InAgAEgSmAh1GCj8KBAQCAhASBqkCAqwCBBovIE9wdGlvbmFsLiBJbW11dGFibGUuIFND
QU4gbGlzdGVuZXIgcG9ydCAtIFRDUAoKDQoFBAICEAUSBKkCAgcKDQoFBAICEAESBKkCCB4K
DQoFBAICEAMSBKkCISMKDwoFBAICEAgSBqkCJKwCAwoQCggEAgIQCJwIABIEqgIEKgoQCggE
AgIQCJwIARIEqwIEKwpQCgQEAgIREgSvAgJCGkIgT3V0cHV0IG9ubHkuIERlZXAgbGluayB0
byB0aGUgT0NJIGNvbnNvbGUgdG8gdmlldyB0aGlzIHJlc291cmNlLgoKDQoFBAICEQUSBK8C
AggKDQoFBAICEQESBK8CCRAKDQoFBAICEQMSBK8CExUKDQoFBAICEQgSBK8CFkEKEAoIBAIC
EQicCAASBK8CF0AKUgoEBAICEhIEsgICRRpEIE91dHB1dCBvbmx5LiBUaGUgT3JhY2xlIEdy
aWQgSW5mcmFzdHJ1Y3R1cmUgKEdJKSBzb2Z0d2FyZSB2ZXJzaW9uLgoKDQoFBAICEgUSBLIC
AggKDQoFBAICEgESBLICCRMKDQoFBAICEgMSBLICFhgKDQoFBAICEggSBLICGUQKEAoIBAIC
EgicCAASBLICGkNiBnByb3RvMw==
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Oracledatabase::V1::ExadbVmCluster::ExadbVmCluster ===
    # Fields for ExadbVmCluster
    # Field: name Type: 9 ()
    # Field: properties Type: 11 (.google.cloud.oracledatabase.v1.ExadbVmClusterProperties)
    # Field: gcp_oracle_zone Type: 9 ()
    # Field: labels Type: 11 (.google.cloud.oracledatabase.v1.ExadbVmCluster.LabelsEntry)
    # Field: odb_network Type: 9 ()
    # Field: odb_subnet Type: 9 ()
    # Field: backup_odb_subnet Type: 9 ()
    # Field: display_name Type: 9 ()
    # Field: create_time Type: 11 (.google.protobuf.Timestamp)
    # Field: entitlement_id Type: 9 ()
    # Field: identity_connector Type: 11 (.google.cloud.oracledatabase.v1.IdentityConnector)
    # Field: identity_connector_disabled Type: 8 ()

# === Message: Google::Cloud::Oracledatabase::V1::ExadbVmCluster::ExadbVmClusterStorageDetails ===
    # Fields for ExadbVmClusterStorageDetails
    # Field: size_in_gbs_per_node Type: 5 ()

# === Message: Google::Cloud::Oracledatabase::V1::ExadbVmCluster::ExadbVmClusterProperties ===
    # Fields for ExadbVmClusterProperties
    # Field: cluster_name Type: 9 ()
    # Field: grid_image_id Type: 9 ()
    # Field: node_count Type: 5 ()
    # Field: enabled_ecpu_count_per_node Type: 5 ()
    # Field: additional_ecpu_count_per_node Type: 5 ()
    # Field: vm_file_system_storage Type: 11 (.google.cloud.oracledatabase.v1.ExadbVmClusterStorageDetails)
    # Field: license_model Type: 14 (.google.cloud.oracledatabase.v1.ExadbVmClusterProperties.LicenseModel)
    # Field: exascale_db_storage_vault Type: 9 ()
    # Field: hostname_prefix Type: 9 ()
    # Field: hostname Type: 9 ()
    # Field: ssh_public_keys Type: 9 ()
    # Field: data_collection_options Type: 11 (.google.cloud.oracledatabase.v1.DataCollectionOptionsCommon)
    # Field: time_zone Type: 11 (.google.type.TimeZone)
    # Field: lifecycle_state Type: 14 (.google.cloud.oracledatabase.v1.ExadbVmClusterProperties.ExadbVmClusterLifecycleState)
    # Field: shape_attribute Type: 14 (.google.cloud.oracledatabase.v1.ExadbVmClusterProperties.ShapeAttribute)
    # Field: memory_size_gb Type: 5 ()
    # Field: scan_listener_port_tcp Type: 5 ()
    # Field: oci_uri Type: 9 ()
    # Field: gi_version Type: 9 ()

# Enum: ExadbVmClusterProperties::LicenseModel
our $ExadbVmClusterProperties_LICENSE_MODEL_UNSPECIFIED = 0;
our $ExadbVmClusterProperties_LICENSE_INCLUDED = 1;
our $ExadbVmClusterProperties_BRING_YOUR_OWN_LICENSE = 2;

# Enum: ExadbVmClusterProperties::ExadbVmClusterLifecycleState
our $ExadbVmClusterProperties_EXADB_VM_CLUSTER_LIFECYCLE_STATE_UNSPECIFIED = 0;
our $ExadbVmClusterProperties_PROVISIONING = 1;
our $ExadbVmClusterProperties_AVAILABLE = 2;
our $ExadbVmClusterProperties_UPDATING = 3;
our $ExadbVmClusterProperties_TERMINATING = 4;
our $ExadbVmClusterProperties_TERMINATED = 5;
our $ExadbVmClusterProperties_FAILED = 6;
our $ExadbVmClusterProperties_MAINTENANCE_IN_PROGRESS = 7;

# Enum: ExadbVmClusterProperties::ShapeAttribute
our $ExadbVmClusterProperties_SHAPE_ATTRIBUTE_UNSPECIFIED = 0;
our $ExadbVmClusterProperties_SMART_STORAGE = 1;
our $ExadbVmClusterProperties_BLOCK_STORAGE = 2;

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Oracledatabase::V1::ExadbVmCluster - Compiled Protocol Buffers messages for google/cloud/oracledatabase/v1/exadb_vm_cluster.proto

=head1 SYNOPSIS

    use Google::Cloud::Oracledatabase::V1::ExadbVmCluster;

    my $msg = Google::Cloud::Oracledatabase::V1::ExadbVmCluster::ExadbVmCluster->new({
        name => $name,
        properties => $properties,
        gcp_oracle_zone => $gcp_oracle_zone,
        labels => $labels,
    });

    # Read or update a field
    my $val = $msg->name();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Oracledatabase::V1::ExadbVmCluster::ExadbVmCluster->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/oracledatabase/v1/exadb_vm_cluster.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Oracledatabase::V1::ExadbVmCluster::ExadbVmCluster

ExadbVmCluster represents a cluster of VMs that are used to run Exadata
workloads.
https://docs.oracle.com/en-us/iaas/api/#/en/database/20160918/ExadbVmCluster/

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Identifier. The name of the ExadbVmCluster resource in the following
format:
projects/{project}/locations/{region}/exadbVmClusters/{exadb_vm_cluster}

=item * C<< $msg->properties() >> / C<< $msg->properties($value) >>

Type: C<Message> (L<Google::Cloud::Oracledatabase::V1::ExadbVmCluster::ExadbVmClusterProperties>)

Required. The properties of the ExadbVmCluster.

=item * C<< $msg->gcp_oracle_zone() >> / C<< $msg->gcp_oracle_zone($value) >>

Type: C<String>

Output only. Immutable. The GCP Oracle zone where Oracle ExadbVmCluster is
hosted. Example: us-east4-b-r2. During creation, the system will pick the
zone assigned to the ExascaleDbStorageVault.

=item * C<< $msg->labels() >> / C<< $msg->labels($value) >>

Type: C<Message> (L<Google::Cloud::Oracledatabase::V1::ExadbVmCluster::ExadbVmCluster::LabelsEntry>)

Optional. The labels or tags associated with the ExadbVmCluster.

=item * C<< $msg->odb_network() >> / C<< $msg->odb_network($value) >>

Type: C<String>

Optional. Immutable. The name of the OdbNetwork associated with the
ExadbVmCluster. Format:
projects/{project}/locations/{location}/odbNetworks/{odb_network} It is
optional but if specified, this should match the parent ODBNetwork of the
OdbSubnet.

=item * C<< $msg->odb_subnet() >> / C<< $msg->odb_subnet($value) >>

Type: C<String>

Required. Immutable. The name of the OdbSubnet associated with the
ExadbVmCluster for IP allocation. Format:
projects/{project}/locations/{location}/odbNetworks/{odb_network}/odbSubnets/{odb_subnet}

=item * C<< $msg->backup_odb_subnet() >> / C<< $msg->backup_odb_subnet($value) >>

Type: C<String>

Required. Immutable. The name of the backup OdbSubnet associated with the
ExadbVmCluster. Format:
projects/{project}/locations/{location}/odbNetworks/{odb_network}/odbSubnets/{odb_subnet}

=item * C<< $msg->display_name() >> / C<< $msg->display_name($value) >>

Type: C<String>

Required. Immutable. The display name for the ExadbVmCluster. The name does
not have to be unique within your project. The name must be 1-255
characters long and can only contain alphanumeric characters.

=item * C<< $msg->create_time() >> / C<< $msg->create_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Output only. The date and time that the ExadbVmCluster was created.

=item * C<< $msg->entitlement_id() >> / C<< $msg->entitlement_id($value) >>

Type: C<String>

Output only. The ID of the subscription entitlement associated with the
ExadbVmCluster.

=item * C<< $msg->identity_connector() >> / C<< $msg->identity_connector($value) >>

Type: C<Message> (L<Google::Cloud::Oracledatabase::V1::Common::IdentityConnector>)

Output only. The identity connector details which will allow OCI to
securely access the resources in the customer project.

=item * C<< $msg->identity_connector_disabled() >> / C<< $msg->identity_connector_disabled($value) >>

Type: C<Bool>

Optional. Input only. Immutable. If set to true, disables the automatic
provisioning of the Workload Identity Connector during creation. If set to
false or omitted, the Workload Identity Connector will be automatically
provisioned by default. Note: Provisioning the Workload Identity Connector
is a prerequisite for enabling Google Cloud CMEK.

=back

=head2 Google::Cloud::Oracledatabase::V1::ExadbVmCluster::ExadbVmClusterStorageDetails

The storage allocation for the exadbvmcluster, in gigabytes (GB).

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->size_in_gbs_per_node() >> / C<< $msg->size_in_gbs_per_node($value) >>

Type: C<Int32>

Required. The storage allocation for the exadbvmcluster per node, in
gigabytes (GB). This field is used to calculate the total storage
allocation for the exadbvmcluster.

=back

=head2 Google::Cloud::Oracledatabase::V1::ExadbVmCluster::ExadbVmClusterProperties

The properties of an ExadbVmCluster.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->cluster_name() >> / C<< $msg->cluster_name($value) >>

Type: C<String>

Optional. Immutable. The cluster name for Exascale vm cluster. The cluster
name must begin with an alphabetic character and may contain hyphens(-) but
can not contain underscores(_). It should be not more than 11 characters
and is not case sensitive. OCI Cluster name.

=item * C<< $msg->grid_image_id() >> / C<< $msg->grid_image_id($value) >>

Type: C<String>

Required. Immutable. Grid Infrastructure Version.

=item * C<< $msg->node_count() >> / C<< $msg->node_count($value) >>

Type: C<Int32>

Required. The number of nodes/VMs in the ExadbVmCluster.

=item * C<< $msg->enabled_ecpu_count_per_node() >> / C<< $msg->enabled_ecpu_count_per_node($value) >>

Type: C<Int32>

Required. Immutable. The number of ECPUs enabled per node for an exadata vm
cluster on exascale infrastructure.

=item * C<< $msg->additional_ecpu_count_per_node() >> / C<< $msg->additional_ecpu_count_per_node($value) >>

Type: C<Int32>

Optional. Immutable. The number of additional ECPUs per node for an Exadata
VM cluster on exascale infrastructure.

=item * C<< $msg->vm_file_system_storage() >> / C<< $msg->vm_file_system_storage($value) >>

Type: C<Message> (L<Google::Cloud::Oracledatabase::V1::ExadbVmCluster::ExadbVmClusterStorageDetails>)

Required. Immutable. Total storage details for the ExadbVmCluster.

=item * C<< $msg->license_model() >> / C<< $msg->license_model($value) >>

Type: C<Enum> (L<Google::Cloud::Oracledatabase::V1::ExadbVmClusterProperties::LicenseModel>)

Optional. Immutable. The license type of the ExadbVmCluster.

=item * C<< $msg->exascale_db_storage_vault() >> / C<< $msg->exascale_db_storage_vault($value) >>

Type: C<String>

Required. Immutable. The name of ExascaleDbStorageVault associated with the
ExadbVmCluster. It can refer to an existing ExascaleDbStorageVault. Or a
new one can be created during the ExadbVmCluster creation (requires
storage_vault_properties to be set).
Format:
projects/{project}/locations/{location}/exascaleDbStorageVaults/{exascale_db_storage_vault}

=item * C<< $msg->hostname_prefix() >> / C<< $msg->hostname_prefix($value) >>

Type: C<String>

Required. Immutable. Prefix for VM cluster host names.

=item * C<< $msg->hostname() >> / C<< $msg->hostname($value) >>

Type: C<String>

Output only. The hostname of the ExadbVmCluster.

=item * C<< $msg->ssh_public_keys() >> / C<< $msg->ssh_public_keys($value) >>

Type: C<String>

Required. Immutable. The SSH public keys for the ExadbVmCluster.

=item * C<< $msg->data_collection_options() >> / C<< $msg->data_collection_options($value) >>

Type: C<Message> (L<Google::Cloud::Oracledatabase::V1::Common::DataCollectionOptionsCommon>)

Optional. Immutable. Indicates user preference for data collection options.

=item * C<< $msg->time_zone() >> / C<< $msg->time_zone($value) >>

Type: C<Message> (L<Google::Type::Datetime::TimeZone>)

Optional. Immutable. The time zone of the ExadbVmCluster.

=item * C<< $msg->lifecycle_state() >> / C<< $msg->lifecycle_state($value) >>

Type: C<Enum> (L<Google::Cloud::Oracledatabase::V1::ExadbVmClusterProperties::ExadbVmClusterLifecycleState>)

Output only. State of the cluster.

=item * C<< $msg->shape_attribute() >> / C<< $msg->shape_attribute($value) >>

Type: C<Enum> (L<Google::Cloud::Oracledatabase::V1::ExadbVmClusterProperties::ShapeAttribute>)

Required. Immutable. The shape attribute of the VM cluster. The type of
Exascale storage used for Exadata VM cluster. The default is SMART_STORAGE
which supports Oracle Database 23ai and later

=item * C<< $msg->memory_size_gb() >> / C<< $msg->memory_size_gb($value) >>

Type: C<Int32>

Output only. Memory per VM (GB) (Read-only): Shows the amount of memory
allocated to each VM. Memory is calculated based on 2.75 GB per Total
ECPUs.

=item * C<< $msg->scan_listener_port_tcp() >> / C<< $msg->scan_listener_port_tcp($value) >>

Type: C<Int32>

Optional. Immutable. SCAN listener port - TCP

=item * C<< $msg->oci_uri() >> / C<< $msg->oci_uri($value) >>

Type: C<String>

Output only. Deep link to the OCI console to view this resource.

=item * C<< $msg->gi_version() >> / C<< $msg->gi_version($value) >>

Type: C<String>

Output only. The Oracle Grid Infrastructure (GI) software version.

=back

=head3 Enum: ExadbVmClusterProperties::LicenseModel

=over 4

=item * C<LICENSE_MODEL_UNSPECIFIED> => C<0>

=item * C<LICENSE_INCLUDED> => C<1>

=item * C<BRING_YOUR_OWN_LICENSE> => C<2>

=back

=head3 Enum: ExadbVmClusterProperties::ExadbVmClusterLifecycleState

=over 4

=item * C<EXADB_VM_CLUSTER_LIFECYCLE_STATE_UNSPECIFIED> => C<0>

=item * C<PROVISIONING> => C<1>

=item * C<AVAILABLE> => C<2>

=item * C<UPDATING> => C<3>

=item * C<TERMINATING> => C<4>

=item * C<TERMINATED> => C<5>

=item * C<FAILED> => C<6>

=item * C<MAINTENANCE_IN_PROGRESS> => C<7>

=back

=head3 Enum: ExadbVmClusterProperties::ShapeAttribute

=over 4

=item * C<SHAPE_ATTRIBUTE_UNSPECIFIED> => C<0>

=item * C<SMART_STORAGE> => C<1>

=item * C<BLOCK_STORAGE> => C<2>

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Oracledatabase::V1::ExadbVmCluster::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
