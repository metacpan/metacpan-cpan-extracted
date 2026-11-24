package Grafeas::V1::Discovery;

use strict;
use warnings;

our $VERSION = '0.14';

use Protobuf::Message;
use Protobuf::DescriptorPool;
use Protobuf::Internal qw(:all);
use MIME::Base64;

BEGIN {
    eval { require Google::Api::FieldBehavior };
    eval { require Google::Protobuf::Timestamp };
    eval { require Google::Rpc::Status };
    eval { require Grafeas::V1::Common };
    my $descriptor_b64 = <<'EOF';
ChpncmFmZWFzL3YxL2Rpc2NvdmVyeS5wcm90bxIKZ3JhZmVhcy52MRofZ29vZ2xlL2FwaS9m
aWVsZF9iZWhhdmlvci5wcm90bxofZ29vZ2xlL3Byb3RvYnVmL3RpbWVzdGFtcC5wcm90bxoX
Z29vZ2xlL3JwYy9zdGF0dXMucHJvdG8aF2dyYWZlYXMvdjEvY29tbW9uLnByb3RvIkoKDURp
c2NvdmVyeU5vdGUSOQoNYW5hbHlzaXNfa2luZBgBIAEoDjIULmdyYWZlYXMudjEuTm90ZUtp
bmRSDGFuYWx5c2lzS2luZCKbDwoTRGlzY292ZXJ5T2NjdXJyZW5jZRJjChNjb250aW51b3Vz
X2FuYWx5c2lzGAEgASgOMjIuZ3JhZmVhcy52MS5EaXNjb3ZlcnlPY2N1cnJlbmNlLkNvbnRp
bnVvdXNBbmFseXNpc1ISY29udGludW91c0FuYWx5c2lzElcKD2FuYWx5c2lzX3N0YXR1cxgC
IAEoDjIuLmdyYWZlYXMudjEuRGlzY292ZXJ5T2NjdXJyZW5jZS5BbmFseXNpc1N0YXR1c1IO
YW5hbHlzaXNTdGF0dXMSYAoSYW5hbHlzaXNfY29tcGxldGVkGAcgASgLMjEuZ3JhZmVhcy52
MS5EaXNjb3ZlcnlPY2N1cnJlbmNlLkFuYWx5c2lzQ29tcGxldGVkUhFhbmFseXNpc0NvbXBs
ZXRlZBI5Cg5hbmFseXNpc19lcnJvchgIIAMoCzISLmdvb2dsZS5ycGMuU3RhdHVzUg1hbmFs
eXNpc0Vycm9yEkYKFWFuYWx5c2lzX3N0YXR1c19lcnJvchgDIAEoCzISLmdvb2dsZS5ycGMu
U3RhdHVzUhNhbmFseXNpc1N0YXR1c0Vycm9yEhAKA2NwZRgEIAEoCVIDY3BlEkAKDmxhc3Rf
c2Nhbl90aW1lGAUgASgLMhouZ29vZ2xlLnByb3RvYnVmLlRpbWVzdGFtcFIMbGFzdFNjYW5U
aW1lEkIKDGFyY2hpdmVfdGltZRgGIAEoCzIaLmdvb2dsZS5wcm90b2J1Zi5UaW1lc3RhbXBC
A+BBA1ILYXJjaGl2ZVRpbWUSSwoLc2JvbV9zdGF0dXMYCSABKAsyKi5ncmFmZWFzLnYxLkRp
c2NvdmVyeU9jY3VycmVuY2UuU0JPTVN0YXR1c1IKc2JvbVN0YXR1cxJ1Chl2dWxuZXJhYmls
aXR5X2F0dGVzdGF0aW9uGAogASgLMjguZ3JhZmVhcy52MS5EaXNjb3ZlcnlPY2N1cnJlbmNl
LlZ1bG5lcmFiaWxpdHlBdHRlc3RhdGlvblIYdnVsbmVyYWJpbGl0eUF0dGVzdGF0aW9uEjoK
BWZpbGVzGAsgAygLMiQuZ3JhZmVhcy52MS5EaXNjb3ZlcnlPY2N1cnJlbmNlLkZpbGVSBWZp
bGVzEl8KHmxhc3RfdnVsbmVyYWJpbGl0eV91cGRhdGVfdGltZRgMIAEoCzIaLmdvb2dsZS5w
cm90b2J1Zi5UaW1lc3RhbXBSG2xhc3RWdWxuZXJhYmlsaXR5VXBkYXRlVGltZRo4ChFBbmFs
eXNpc0NvbXBsZXRlZBIjCg1hbmFseXNpc190eXBlGAEgAygJUgxhbmFseXNpc1R5cGUauwEK
ClNCT01TdGF0dXMSUwoKc2JvbV9zdGF0ZRgBIAEoDjI0LmdyYWZlYXMudjEuRGlzY292ZXJ5
T2NjdXJyZW5jZS5TQk9NU3RhdHVzLlNCT01TdGF0ZVIJc2JvbVN0YXRlEhQKBWVycm9yGAIg
ASgJUgVlcnJvciJCCglTQk9NU3RhdGUSGgoWU0JPTV9TVEFURV9VTlNQRUNJRklFRBAAEgsK
B1BFTkRJTkcQARIMCghDT01QTEVURRACGtICChhWdWxuZXJhYmlsaXR5QXR0ZXN0YXRpb24S
RgoRbGFzdF9hdHRlbXB0X3RpbWUYASABKAsyGi5nb29nbGUucHJvdG9idWYuVGltZXN0YW1w
Ug9sYXN0QXR0ZW1wdFRpbWUSbAoFc3RhdGUYAiABKA4yVi5ncmFmZWFzLnYxLkRpc2NvdmVy
eU9jY3VycmVuY2UuVnVsbmVyYWJpbGl0eUF0dGVzdGF0aW9uLlZ1bG5lcmFiaWxpdHlBdHRl
c3RhdGlvblN0YXRlUgVzdGF0ZRIUCgVlcnJvchgDIAEoCVIFZXJyb3IiagodVnVsbmVyYWJp
bGl0eUF0dGVzdGF0aW9uU3RhdGUSLworVlVMTkVSQUJJTElUWV9BVFRFU1RBVElPTl9TVEFU
RV9VTlNQRUNJRklFRBAAEgsKB1NVQ0NFU1MQARILCgdGQUlMVVJFEAIanwEKBEZpbGUSEgoE
bmFtZRgBIAEoCVIEbmFtZRJICgZkaWdlc3QYAiADKAsyMC5ncmFmZWFzLnYxLkRpc2NvdmVy
eU9jY3VycmVuY2UuRmlsZS5EaWdlc3RFbnRyeVIGZGlnZXN0GjkKC0RpZ2VzdEVudHJ5EhAK
A2tleRgBIAEoCVIDa2V5EhQKBXZhbHVlGAIgASgJUgV2YWx1ZToCOAEiUwoSQ29udGludW91
c0FuYWx5c2lzEiMKH0NPTlRJTlVPVVNfQU5BTFlTSVNfVU5TUEVDSUZJRUQQABIKCgZBQ1RJ
VkUQARIMCghJTkFDVElWRRACIqMBCg5BbmFseXNpc1N0YXR1cxIfChtBTkFMWVNJU19TVEFU
VVNfVU5TUEVDSUZJRUQQABILCgdQRU5ESU5HEAESDAoIU0NBTk5JTkcQAhIUChBGSU5JU0hF
RF9TVUNDRVNTEAMSDAoIQ09NUExFVEUQAxITCg9GSU5JU0hFRF9GQUlMRUQQBBIYChRGSU5J
U0hFRF9VTlNVUFBPUlRFRBAFGgIQAUJRCg1pby5ncmFmZWFzLnYxUAFaOGdvb2dsZS5nb2xh
bmcub3JnL2dlbnByb3RvL2dvb2dsZWFwaXMvZ3JhZmVhcy92MTtncmFmZWFzogIDR1JBSu4s
CgcSBQ4AoQEBCtoECgEMEgMOABIyzwQgQ29weXJpZ2h0IDIwMTkgVGhlIEdyYWZlYXMgQXV0
aG9ycy4gQWxsIHJpZ2h0cyByZXNlcnZlZC4KCiBMaWNlbnNlZCB1bmRlciB0aGUgQXBhY2hl
IExpY2Vuc2UsIFZlcnNpb24gMi4wICh0aGUgIkxpY2Vuc2UiKTsKIHlvdSBtYXkgbm90IHVz
ZSB0aGlzIGZpbGUgZXhjZXB0IGluIGNvbXBsaWFuY2Ugd2l0aCB0aGUgTGljZW5zZS4KIFlv
dSBtYXkgb2J0YWluIGEgY29weSBvZiB0aGUgTGljZW5zZSBhdAoKICAgIGh0dHA6Ly93d3cu
YXBhY2hlLm9yZy9saWNlbnNlcy9MSUNFTlNFLTIuMAoKIFVubGVzcyByZXF1aXJlZCBieSBh
cHBsaWNhYmxlIGxhdyBvciBhZ3JlZWQgdG8gaW4gd3JpdGluZywgc29mdHdhcmUKIGRpc3Ry
aWJ1dGVkIHVuZGVyIHRoZSBMaWNlbnNlIGlzIGRpc3RyaWJ1dGVkIG9uIGFuICJBUyBJUyIg
QkFTSVMsCiBXSVRIT1VUIFdBUlJBTlRJRVMgT1IgQ09ORElUSU9OUyBPRiBBTlkgS0lORCwg
ZWl0aGVyIGV4cHJlc3Mgb3IgaW1wbGllZC4KIFNlZSB0aGUgTGljZW5zZSBmb3IgdGhlIHNw
ZWNpZmljIGxhbmd1YWdlIGdvdmVybmluZyBwZXJtaXNzaW9ucyBhbmQKIGxpbWl0YXRpb25z
IHVuZGVyIHRoZSBMaWNlbnNlLgoKCAoBAhIDEAATCgkKAgMAEgMSACkKCQoCAwESAxMAKQoJ
CgIDAhIDFAAhCgkKAgMDEgMVACEKCAoBCBIDFwBPCgkKAggLEgMXAE8KCAoBCBIDGAAiCgkK
AggKEgMYACIKCAoBCBIDGQAmCgkKAggBEgMZACYKCAoBCBIDGgAhCgkKAggkEgMaACEK0wEK
AgQAEgQfACMBGsYBIEEgbm90ZSB0aGF0IGluZGljYXRlcyBhIHR5cGUgb2YgYW5hbHlzaXMg
YSBwcm92aWRlciB3b3VsZCBwZXJmb3JtLiBUaGlzIG5vdGUKIGV4aXN0cyBpbiBhIHByb3Zp
ZGVyJ3MgcHJvamVjdC4gQSBgRGlzY292ZXJ5YCBvY2N1cnJlbmNlIGlzIGNyZWF0ZWQgaW4g
YQogY29uc3VtZXIncyBwcm9qZWN0IGF0IHRoZSBzdGFydCBvZiBhbmFseXNpcy4KCgoKAwQA
ARIDHwgVClwKBAQAAgASAyICKBpPIFJlcXVpcmVkLiBJbW11dGFibGUuIFRoZSBraW5kIG9m
IGFuYWx5c2lzIHRoYXQgaXMgaGFuZGxlZCBieSB0aGlzCiBkaXNjb3ZlcnkuCgoMCgUEAAIA
BhIDIgIVCgwKBQQAAgABEgMiFiMKDAoFBAACAAMSAyImJwpXCgIEARIFJgChAQEaSiBQcm92
aWRlcyBpbmZvcm1hdGlvbiBhYm91dCB0aGUgYW5hbHlzaXMgc3RhdHVzIG9mIGEgZGlzY292
ZXJlZCByZXNvdXJjZS4KCgoKAwQBARIDJggbCj4KBAQBBAASBCgCLwMaMCBXaGV0aGVyIHRo
ZSByZXNvdXJjZSBpcyBjb250aW51b3VzbHkgYW5hbHl6ZWQuCgoMCgUEAQQAARIDKAcZChkK
BgQBBAACABIDKgQoGgogVW5rbm93bi4KCg4KBwQBBAACAAESAyoEIwoOCgcEAQQAAgACEgMq
JicKNwoGBAEEAAIBEgMsBA8aKCBUaGUgcmVzb3VyY2UgaXMgY29udGludW91c2x5IGFuYWx5
emVkLgoKDgoHBAEEAAIBARIDLAQKCg4KBwQBBAACAQISAywNDgpBCgYEAQQAAgISAy4EERoy
IFRoZSByZXNvdXJjZSBpcyBpZ25vcmVkIGZvciBjb250aW51b3VzIGFuYWx5c2lzLgoKDgoH
BAEEAAICARIDLgQMCg4KBwQBBAACAgISAy4PEAo9CgQEAQIAEgMyAi0aMCBXaGV0aGVyIHRo
ZSByZXNvdXJjZSBpcyBjb250aW51b3VzbHkgYW5hbHl6ZWQuCgoMCgUEAQIABhIDMgIUCgwK
BQQBAgABEgMyFSgKDAoFBAECAAMSAzIrLAp6CgQEAQQBEgQ2AkgDGmwgQW5hbHlzaXMgc3Rh
dHVzIGZvciBhIHJlc291cmNlLiBDdXJyZW50bHkgZm9yIGluaXRpYWwgYW5hbHlzaXMgb25s
eSAobm90CiB1cGRhdGVkIGluIGNvbnRpbnVvdXMgYW5hbHlzaXMpLgoKDAoFBAEEAQESAzYH
FQoMCgUEAQQBAxIDNwQeCg0KBgQBBAEDAhIDNwQeChkKBgQBBAECABIDOgQkGgogVW5rbm93
bi4KCg4KBwQBBAECAAESAzoEHwoOCgcEAQQBAgACEgM6IiMKRAoGBAEEAQIBEgM8BBAaNSBS
ZXNvdXJjZSBpcyBrbm93biBidXQgbm8gYWN0aW9uIGhhcyBiZWVuIHRha2VuIHlldC4KCg4K
BwQBBAECAQESAzwECwoOCgcEAQQBAgECEgM8Dg8KLAoGBAEEAQICEgM+BBEaHSBSZXNvdXJj
ZSBpcyBiZWluZyBhbmFseXplZC4KCg4KBwQBBAECAgESAz4EDAoOCgcEAQQBAgICEgM+DxAK
NAoGBAEEAQIDEgNABBkaJSBBbmFseXNpcyBoYXMgZmluaXNoZWQgc3VjY2Vzc2Z1bGx5LgoK
DgoHBAEEAQIDARIDQAQUCg4KBwQBBAECAwISA0AXGAooCgYEAQQBAgQSA0IEERoZIEFuYWx5
c2lzIGhhcyBjb21wbGV0ZWQuCgoOCgcEAQQBAgQBEgNCBAwKDgoHBAEEAQIEAhIDQg8QCl4K
BgQBBAECBRIDRQQYGk8gQW5hbHlzaXMgaGFzIGZpbmlzaGVkIHVuc3VjY2Vzc2Z1bGx5LCB0
aGUgYW5hbHlzaXMgaXRzZWxmIGlzIGluIGEgYmFkCiBzdGF0ZS4KCg4KBwQBBAECBQESA0UE
EwoOCgcEAQQBAgUCEgNFFhcKOwoGBAEEAQIGEgNHBB0aLCBUaGUgcmVzb3VyY2UgaXMga25v
d24gbm90IHRvIGJlIHN1cHBvcnRlZC4KCg4KBwQBBAECBgESA0cEGAoOCgcEAQQBAgYCEgNH
GxwKOAoEBAECARIDSwIlGisgVGhlIHN0YXR1cyBvZiBkaXNjb3ZlcnkgZm9yIHRoZSByZXNv
dXJjZS4KCgwKBQQBAgEGEgNLAhAKDAoFBAECAQESA0sRIAoMCgUEAQIBAxIDSyMkCoMBCgQE
AQMAEgRPAlEDGnUgSW5kaWNhdGVzIHdoaWNoIGFuYWx5c2lzIGNvbXBsZXRlZCBzdWNjZXNz
ZnVsbHkuIE11bHRpcGxlIHR5cGVzIG9mCiBhbmFseXNpcyBjYW4gYmUgcGVyZm9ybWVkIG9u
IGEgc2luZ2xlIHJlc291cmNlLgoKDAoFBAEDAAESA08KGwoNCgYEAQMAAgASA1AEJgoOCgcE
AQMAAgAEEgNQBAwKDgoHBAEDAAIABRIDUA0TCg4KBwQBAwACAAESA1AUIQoOCgcEAQMAAgAD
EgNQJCUKCwoEBAECAhIDUwIrCgwKBQQBAgIGEgNTAhMKDAoFBAECAgESA1MUJgoMCgUEAQIC
AxIDUykqCnkKBAQBAgMSA1cCMBpsIEluZGljYXRlcyBhbnkgZXJyb3JzIGVuY291bnRlcmVk
IGR1cmluZyBhbmFseXNpcyBvZiBhIHJlc291cmNlLiBUaGVyZQogY291bGQgYmUgMCBvciBt
b3JlIG9mIHRoZXNlIGVycm9ycy4KCgwKBQQBAgMEEgNXAgoKDAoFBAECAwYSA1cLHAoMCgUE
AQIDARIDVx0rCgwKBQQBAgMDEgNXLi8KtAEKBAQBAgQSA1wCLhqmASBXaGVuIGFuIGVycm9y
IGlzIGVuY291bnRlcmVkIHRoaXMgd2lsbCBjb250YWluIGEgTG9jYWxpemVkTWVzc2FnZSB1
bmRlcgogZGV0YWlscyB0byBzaG93IHRvIHRoZSB1c2VyLiBUaGUgTG9jYWxpemVkTWVzc2Fn
ZSBpcyBvdXRwdXQgb25seSBhbmQKIHBvcHVsYXRlZCBieSB0aGUgQVBJLgoKDAoFBAECBAYS
A1wCEwoMCgUEAQIEARIDXBQpCgwKBQQBAgQDEgNcLC0KNQoEBAECBRIDXwIRGiggVGhlIENQ
RSBvZiB0aGUgcmVzb3VyY2UgYmVpbmcgc2Nhbm5lZC4KCgwKBQQBAgUFEgNfAggKDAoFBAEC
BQESA18JDAoMCgUEAQIFAxIDXw8QCjcKBAQBAgYSA2ICLxoqIFRoZSBsYXN0IHRpbWUgdGhp
cyByZXNvdXJjZSB3YXMgc2Nhbm5lZC4KCgwKBQQBAgYGEgNiAhsKDAoFBAECBgESA2IcKgoM
CgUEAQIGAxIDYi0uClgKBAQBAgcSBGUCZjIaSiBUaGUgdGltZSBvY2N1cnJlbmNlcyByZWxh
dGVkIHRvIHRoaXMgZGlzY292ZXJ5IG9jY3VycmVuY2Ugd2VyZSBhcmNoaXZlZC4KCgwKBQQB
AgcGEgNlAhsKDAoFBAECBwESA2UcKAoMCgUEAQIHAxIDZSssCgwKBQQBAgcIEgNmBjEKDwoI
BAECBwicCAASA2YHMAoxCgQEAQMBEgRpAnkDGiMgVGhlIHN0YXR1cyBvZiBhbiBTQk9NIGdl
bmVyYXRpb24uCgoMCgUEAQMBARIDaQoUCkkKBgQBAwEEABIEawRyBRo5IEFuIGVudW0gaW5k
aWNhdGluZyB0aGUgcHJvZ3Jlc3Mgb2YgdGhlIFNCT00gZ2VuZXJhdGlvbi4KCg4KBwQBAwEE
AAESA2sJEgopCggEAQMBBAACABIDbQYhGhggRGVmYXVsdCB1bmtub3duIHN0YXRlLgoKEAoJ
BAEDAQQAAgABEgNtBhwKEAoJBAEDAQQAAgACEgNtHyAKLAoIBAEDAQQAAgESA28GEhobIFNC
T00gc2Nhbm5pbmcgaXMgcGVuZGluZy4KChAKCQQBAwEEAAIBARIDbwYNChAKCQQBAwEEAAIB
AhIDbxARCi8KCAQBAwEEAAICEgNxBhMaHiBTQk9NIHNjYW5uaW5nIGhhcyBjb21wbGV0ZWQu
CgoQCgkEAQMBBAACAgESA3EGDgoQCgkEAQMBBAACAgISA3EREgo1CgYEAQMBAgASA3UEHRom
IFRoZSBwcm9ncmVzcyBvZiB0aGUgU0JPTSBnZW5lcmF0aW9uLgoKDgoHBAEDAQIABhIDdQQN
Cg4KBwQBAwECAAESA3UOGAoOCgcEAQMBAgADEgN1GxwKYwoGBAEDAQIBEgN4BBUaVCBJZiB0
aGVyZSB3YXMgYW4gZXJyb3IgZ2VuZXJhdGluZyBhbiBTQk9NLCB0aGlzIHdpbGwgaW5kaWNh
dGUgd2hhdCB0aGF0CiBlcnJvciB3YXMuCgoOCgcEAQMBAgEFEgN4BAoKDgoHBAEDAQIBARID
eAsQCg4KBwQBAwECAQMSA3gTFAowCgQEAQIIEgN8Ah0aIyBUaGUgc3RhdHVzIG9mIGFuIFNC
T00gZ2VuZXJhdGlvbi4KCgwKBQQBAggGEgN8AgwKDAoFBAECCAESA3wNGAoMCgUEAQIIAxID
fBscCkcKBAQBAwISBX8CkgEDGjggVGhlIHN0YXR1cyBvZiBhbiB2dWxuZXJhYmlsaXR5IGF0
dGVzdGF0aW9uIGdlbmVyYXRpb24uCgoMCgUEAQMCARIDfwoiCk8KBgQBAwIEABIGgQEEiAEF
Gj0gQW4gZW51bSBpbmRpY2F0aW5nIHRoZSBzdGF0ZSBvZiB0aGUgYXR0ZXN0YXRpb24gZ2Vu
ZXJhdGlvbi4KCg8KBwQBAwIEAAESBIEBCSYKKgoIBAEDAgQAAgASBIMBBjYaGCBEZWZhdWx0
IHVua25vd24gc3RhdGUuCgoRCgkEAQMCBAACAAESBIMBBjEKEQoJBAEDAgQAAgACEgSDATQ1
CkYKCAQBAwIEAAIBEgSFAQYSGjQgQXR0ZXN0YXRpb24gd2FzIHN1Y2Nlc3NmdWxseSBnZW5l
cmF0ZWQgYW5kIHN0b3JlZC4KChEKCQQBAwIEAAIBARIEhQEGDQoRCgkEAQMCBAACAQISBIUB
EBEKSAoIBAEDAgQAAgISBIcBBhIaNiBBdHRlc3RhdGlvbiB3YXMgdW5zdWNjZXNzZnVsbHkg
Z2VuZXJhdGVkIGFuZCBzdG9yZWQuCgoRCgkEAQMCBAACAgESBIcBBg0KEQoJBAEDAgQAAgIC
EgSHARARCkgKBgQBAwICABIEiwEENBo4IFRoZSBsYXN0IHRpbWUgd2UgYXR0ZW1wdGVkIHRv
IGdlbmVyYXRlIGFuIGF0dGVzdGF0aW9uLgoKDwoHBAEDAgIABhIEiwEEHQoPCgcEAQMCAgAB
EgSLAR4vCg8KBwQBAwICAAMSBIsBMjMKTgoGBAEDAgIBEgSOAQQsGj4gVGhlIHN1Y2Nlc3Mv
ZmFpbHVyZSBzdGF0ZSBvZiB0aGUgbGF0ZXN0IGF0dGVzdGF0aW9uIGF0dGVtcHQuCgoPCgcE
AQMCAgEGEgSOAQQhCg8KBwQBAwICAQESBI4BIicKDwoHBAEDAgIBAxIEjgEqKwpZCgYEAQMC
AgISBJEBBBUaSSBJZiBmYWlsdXJlLCB0aGUgZXJyb3IgcmVhc29uIGZvciB3aHkgdGhlIGF0
dGVzdGF0aW9uIGdlbmVyYXRpb24gZmFpbGVkLgoKDwoHBAEDAgICBRIEkQEECgoPCgcEAQMC
AgIBEgSRAQsQCg8KBwQBAwICAgMSBJEBExQKRgoEBAECCRIElQECOho4IFRoZSBzdGF0dXMg
b2YgYW4gdnVsbmVyYWJpbGl0eSBhdHRlc3RhdGlvbiBnZW5lcmF0aW9uLgoKDQoFBAECCQYS
BJUBAhoKDQoFBAECCQESBJUBGzQKDQoFBAECCQMSBJUBNzkKDgoEBAEDAxIGlwECmgEDCg0K
BQQBAwMBEgSXAQoOCg4KBgQBAwMCABIEmAEEFAoPCgcEAQMDAgAFEgSYAQQKCg8KBwQBAwMC
AAESBJgBCw8KDwoHBAEDAwIAAxIEmAESEwoOCgYEAQMDAgESBJkBBCMKDwoHBAEDAwIBBhIE
mQEEFwoPCgcEAQMDAgEBEgSZARgeCg8KBwQBAwMCAQMSBJkBISIKTAoEBAECChIEnQECGxo+
IEZpbGVzIHRoYXQgbWFrZSB1cCB0aGUgcmVzb3VyY2UgZGVzY3JpYmVkIGJ5IHRoZSBvY2N1
cnJlbmNlLgoKDQoFBAECCgQSBJ0BAgoKDQoFBAECCgYSBJ0BCw8KDQoFBAECCgESBJ0BEBUK
DQoFBAECCgMSBJ0BGBoKQQoEBAECCxIEoAECQBozIFRoZSBsYXN0IHRpbWUgdnVsbmVyYWJp
bGl0eSBzY2FuIHJlc3VsdHMgY2hhbmdlZC4KCg0KBQQBAgsGEgSgAQIbCg0KBQQBAgsBEgSg
ARw6Cg0KBQQBAgsDEgSgAT0/YgZwcm90bzM=
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Grafeas::V1::Discovery::DiscoveryNote ===
    # Fields for DiscoveryNote
    # Field: analysis_kind Type: 14 (.grafeas.v1.NoteKind)

# === Message: Grafeas::V1::Discovery::DiscoveryOccurrence ===
    # Fields for DiscoveryOccurrence
    # Field: continuous_analysis Type: 14 (.grafeas.v1.DiscoveryOccurrence.ContinuousAnalysis)
    # Field: analysis_status Type: 14 (.grafeas.v1.DiscoveryOccurrence.AnalysisStatus)
    # Field: analysis_completed Type: 11 (.grafeas.v1.DiscoveryOccurrence.AnalysisCompleted)
    # Field: analysis_error Type: 11 (.google.rpc.Status)
    # Field: analysis_status_error Type: 11 (.google.rpc.Status)
    # Field: cpe Type: 9 ()
    # Field: last_scan_time Type: 11 (.google.protobuf.Timestamp)
    # Field: archive_time Type: 11 (.google.protobuf.Timestamp)
    # Field: sbom_status Type: 11 (.grafeas.v1.DiscoveryOccurrence.SBOMStatus)
    # Field: vulnerability_attestation Type: 11 (.grafeas.v1.DiscoveryOccurrence.VulnerabilityAttestation)
    # Field: files Type: 11 (.grafeas.v1.DiscoveryOccurrence.File)
    # Field: last_vulnerability_update_time Type: 11 (.google.protobuf.Timestamp)

# Enum: DiscoveryOccurrence::ContinuousAnalysis
our $DiscoveryOccurrence_CONTINUOUS_ANALYSIS_UNSPECIFIED = 0;
our $DiscoveryOccurrence_ACTIVE = 1;
our $DiscoveryOccurrence_INACTIVE = 2;

# Enum: DiscoveryOccurrence::AnalysisStatus
our $DiscoveryOccurrence_ANALYSIS_STATUS_UNSPECIFIED = 0;
our $DiscoveryOccurrence_PENDING = 1;
our $DiscoveryOccurrence_SCANNING = 2;
our $DiscoveryOccurrence_FINISHED_SUCCESS = 3;
our $DiscoveryOccurrence_COMPLETE = 3;
our $DiscoveryOccurrence_FINISHED_FAILED = 4;
our $DiscoveryOccurrence_FINISHED_UNSUPPORTED = 5;

1;

__END__

=encoding UTF-8

=head1 NAME

Grafeas::V1::Discovery - Compiled Protocol Buffers messages for grafeas/v1/discovery.proto

=head1 SYNOPSIS

    use Grafeas::V1::Discovery;

    my $msg = Grafeas::V1::Discovery::DiscoveryNote->new({
        analysis_kind => $analysis_kind,
    });

    # Read or update a field
    my $val = $msg->analysis_kind();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Grafeas::V1::Discovery::DiscoveryNote->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<grafeas/v1/discovery.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Grafeas::V1::Discovery::DiscoveryNote

A note that indicates a type of analysis a provider would perform. This note
exists in a provider's project. A `Discovery` occurrence is created in a
consumer's project at the start of analysis.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->analysis_kind() >> / C<< $msg->analysis_kind($value) >>

Type: C<Enum> (L<Grafeas::V1::NoteKind>)

Required. Immutable. The kind of analysis that is handled by this
discovery.

=back

=head2 Grafeas::V1::Discovery::DiscoveryOccurrence

Provides information about the analysis status of a discovered resource.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->continuous_analysis() >> / C<< $msg->continuous_analysis($value) >>

Type: C<Enum> (L<Grafeas::V1::DiscoveryOccurrence::ContinuousAnalysis>)

Whether the resource is continuously analyzed.

=item * C<< $msg->analysis_status() >> / C<< $msg->analysis_status($value) >>

Type: C<Enum> (L<Grafeas::V1::DiscoveryOccurrence::AnalysisStatus>)

The status of discovery for the resource.

=item * C<< $msg->analysis_completed() >> / C<< $msg->analysis_completed($value) >>

Type: C<Message> (L<Grafeas::V1::Discovery::DiscoveryOccurrence::AnalysisCompleted>)

=item * C<< $msg->analysis_error() >> / C<< $msg->analysis_error($value) >>

Type: C<Message> (L<Google::Rpc::Status::Status>)

Indicates any errors encountered during analysis of a resource. There
could be 0 or more of these errors.

=item * C<< $msg->analysis_status_error() >> / C<< $msg->analysis_status_error($value) >>

Type: C<Message> (L<Google::Rpc::Status::Status>)

When an error is encountered this will contain a LocalizedMessage under
details to show to the user. The LocalizedMessage is output only and
populated by the API.

=item * C<< $msg->cpe() >> / C<< $msg->cpe($value) >>

Type: C<String>

The CPE of the resource being scanned.

=item * C<< $msg->last_scan_time() >> / C<< $msg->last_scan_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

The last time this resource was scanned.

=item * C<< $msg->archive_time() >> / C<< $msg->archive_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

The time occurrences related to this discovery occurrence were archived.

=item * C<< $msg->sbom_status() >> / C<< $msg->sbom_status($value) >>

Type: C<Message> (L<Grafeas::V1::Discovery::DiscoveryOccurrence::SBOMStatus>)

The status of an SBOM generation.

=item * C<< $msg->vulnerability_attestation() >> / C<< $msg->vulnerability_attestation($value) >>

Type: C<Message> (L<Grafeas::V1::Discovery::DiscoveryOccurrence::VulnerabilityAttestation>)

The status of an vulnerability attestation generation.

=item * C<< $msg->files() >> / C<< $msg->files($value) >>

Type: C<Message> (L<Grafeas::V1::Discovery::DiscoveryOccurrence::File>)

Files that make up the resource described by the occurrence.

=item * C<< $msg->last_vulnerability_update_time() >> / C<< $msg->last_vulnerability_update_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

The last time vulnerability scan results changed.

=back

=head3 Enum: DiscoveryOccurrence::ContinuousAnalysis

=over 4

=item * C<CONTINUOUS_ANALYSIS_UNSPECIFIED> => C<0>

=item * C<ACTIVE> => C<1>

=item * C<INACTIVE> => C<2>

=back

=head3 Enum: DiscoveryOccurrence::AnalysisStatus

=over 4

=item * C<ANALYSIS_STATUS_UNSPECIFIED> => C<0>

=item * C<PENDING> => C<1>

=item * C<SCANNING> => C<2>

=item * C<FINISHED_SUCCESS> => C<3>

=item * C<COMPLETE> => C<3>

=item * C<FINISHED_FAILED> => C<4>

=item * C<FINISHED_UNSUPPORTED> => C<5>

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Grafeas::V1::Discovery::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
