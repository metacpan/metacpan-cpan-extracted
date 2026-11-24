package Google::Cloud::Securitycenter::V1::Asset;

use strict;
use warnings;

our $VERSION = '0.14';

use Protobuf::Message;
use Protobuf::DescriptorPool;
use Protobuf::Internal qw(:all);
use MIME::Base64;

BEGIN {
    eval { require Google::Api::Resource };
    eval { require Google::Cloud::Securitycenter::V1::Folder };
    eval { require Google::Cloud::Securitycenter::V1::SecurityMarks };
    eval { require Google::Protobuf::Struct };
    eval { require Google::Protobuf::Timestamp };
    my $descriptor_b64 = <<'EOF';
Cipnb29nbGUvY2xvdWQvc2VjdXJpdHljZW50ZXIvdjEvYXNzZXQucHJvdG8SHmdvb2dsZS5j
bG91ZC5zZWN1cml0eWNlbnRlci52MRoZZ29vZ2xlL2FwaS9yZXNvdXJjZS5wcm90bxorZ29v
Z2xlL2Nsb3VkL3NlY3VyaXR5Y2VudGVyL3YxL2ZvbGRlci5wcm90bxozZ29vZ2xlL2Nsb3Vk
L3NlY3VyaXR5Y2VudGVyL3YxL3NlY3VyaXR5X21hcmtzLnByb3RvGhxnb29nbGUvcHJvdG9i
dWYvc3RydWN0LnByb3RvGh9nb29nbGUvcHJvdG9idWYvdGltZXN0YW1wLnByb3RvIucKCgVB
c3NldBISCgRuYW1lGAEgASgJUgRuYW1lEnwKGnNlY3VyaXR5X2NlbnRlcl9wcm9wZXJ0aWVz
GAIgASgLMj4uZ29vZ2xlLmNsb3VkLnNlY3VyaXR5Y2VudGVyLnYxLkFzc2V0LlNlY3VyaXR5
Q2VudGVyUHJvcGVydGllc1IYc2VjdXJpdHlDZW50ZXJQcm9wZXJ0aWVzEm4KE3Jlc291cmNl
X3Byb3BlcnRpZXMYByADKAsyPS5nb29nbGUuY2xvdWQuc2VjdXJpdHljZW50ZXIudjEuQXNz
ZXQuUmVzb3VyY2VQcm9wZXJ0aWVzRW50cnlSEnJlc291cmNlUHJvcGVydGllcxJUCg5zZWN1
cml0eV9tYXJrcxgIIAEoCzItLmdvb2dsZS5jbG91ZC5zZWN1cml0eWNlbnRlci52MS5TZWN1
cml0eU1hcmtzUg1zZWN1cml0eU1hcmtzEjsKC2NyZWF0ZV90aW1lGAkgASgLMhouZ29vZ2xl
LnByb3RvYnVmLlRpbWVzdGFtcFIKY3JlYXRlVGltZRI7Cgt1cGRhdGVfdGltZRgKIAEoCzIa
Lmdvb2dsZS5wcm90b2J1Zi5UaW1lc3RhbXBSCnVwZGF0ZVRpbWUSTgoKaWFtX3BvbGljeRgL
IAEoCzIvLmdvb2dsZS5jbG91ZC5zZWN1cml0eWNlbnRlci52MS5Bc3NldC5JYW1Qb2xpY3lS
CWlhbVBvbGljeRIlCg5jYW5vbmljYWxfbmFtZRgNIAEoCVINY2Fub25pY2FsTmFtZRrbAwoY
U2VjdXJpdHlDZW50ZXJQcm9wZXJ0aWVzEiMKDXJlc291cmNlX25hbWUYASABKAlSDHJlc291
cmNlTmFtZRIjCg1yZXNvdXJjZV90eXBlGAIgASgJUgxyZXNvdXJjZVR5cGUSJwoPcmVzb3Vy
Y2VfcGFyZW50GAMgASgJUg5yZXNvdXJjZVBhcmVudBIpChByZXNvdXJjZV9wcm9qZWN0GAQg
ASgJUg9yZXNvdXJjZVByb2plY3QSJwoPcmVzb3VyY2Vfb3duZXJzGAUgAygJUg5yZXNvdXJj
ZU93bmVycxIyChVyZXNvdXJjZV9kaXNwbGF5X25hbWUYBiABKAlSE3Jlc291cmNlRGlzcGxh
eU5hbWUSPwoccmVzb3VyY2VfcGFyZW50X2Rpc3BsYXlfbmFtZRgHIAEoCVIZcmVzb3VyY2VQ
YXJlbnREaXNwbGF5TmFtZRJBCh1yZXNvdXJjZV9wcm9qZWN0X2Rpc3BsYXlfbmFtZRgIIAEo
CVIacmVzb3VyY2VQcm9qZWN0RGlzcGxheU5hbWUSQAoHZm9sZGVycxgKIAMoCzImLmdvb2ds
ZS5jbG91ZC5zZWN1cml0eWNlbnRlci52MS5Gb2xkZXJSB2ZvbGRlcnMaLAoJSWFtUG9saWN5
Eh8KC3BvbGljeV9ibG9iGAEgASgJUgpwb2xpY3lCbG9iGl0KF1Jlc291cmNlUHJvcGVydGll
c0VudHJ5EhAKA2tleRgBIAEoCVIDa2V5EiwKBXZhbHVlGAIgASgLMhYuZ29vZ2xlLnByb3Rv
YnVmLlZhbHVlUgV2YWx1ZToCOAE6qQHqQaUBCiNzZWN1cml0eWNlbnRlci5nb29nbGVhcGlz
LmNvbS9Bc3NldBIrb3JnYW5pemF0aW9ucy97b3JnYW5pemF0aW9ufS9hc3NldHMve2Fzc2V0
fRIfZm9sZGVycy97Zm9sZGVyfS9hc3NldHMve2Fzc2V0fRIhcHJvamVjdHMve3Byb2plY3R9
L2Fzc2V0cy97YXNzZXR9KgZhc3NldHMyBWFzc2V0QtgBCiJjb20uZ29vZ2xlLmNsb3VkLnNl
Y3VyaXR5Y2VudGVyLnYxUAFaSmNsb3VkLmdvb2dsZS5jb20vZ28vc2VjdXJpdHljZW50ZXIv
YXBpdjEvc2VjdXJpdHljZW50ZXJwYjtzZWN1cml0eWNlbnRlcnBiqgIeR29vZ2xlLkNsb3Vk
LlNlY3VyaXR5Q2VudGVyLlYxygIeR29vZ2xlXENsb3VkXFNlY3VyaXR5Q2VudGVyXFYx6gIh
R29vZ2xlOjpDbG91ZDo6U2VjdXJpdHlDZW50ZXI6OlYxSv8oCgcSBQ4AhwEBCrwECgEMEgMO
ABIysQQgQ29weXJpZ2h0IDIwMjUgR29vZ2xlIExMQwoKIExpY2Vuc2VkIHVuZGVyIHRoZSBB
cGFjaGUgTGljZW5zZSwgVmVyc2lvbiAyLjAgKHRoZSAiTGljZW5zZSIpOwogeW91IG1heSBu
b3QgdXNlIHRoaXMgZmlsZSBleGNlcHQgaW4gY29tcGxpYW5jZSB3aXRoIHRoZSBMaWNlbnNl
LgogWW91IG1heSBvYnRhaW4gYSBjb3B5IG9mIHRoZSBMaWNlbnNlIGF0CgogICAgIGh0dHA6
Ly93d3cuYXBhY2hlLm9yZy9saWNlbnNlcy9MSUNFTlNFLTIuMAoKIFVubGVzcyByZXF1aXJl
ZCBieSBhcHBsaWNhYmxlIGxhdyBvciBhZ3JlZWQgdG8gaW4gd3JpdGluZywgc29mdHdhcmUK
IGRpc3RyaWJ1dGVkIHVuZGVyIHRoZSBMaWNlbnNlIGlzIGRpc3RyaWJ1dGVkIG9uIGFuICJB
UyBJUyIgQkFTSVMsCiBXSVRIT1VUIFdBUlJBTlRJRVMgT1IgQ09ORElUSU9OUyBPRiBBTlkg
S0lORCwgZWl0aGVyIGV4cHJlc3Mgb3IgaW1wbGllZC4KIFNlZSB0aGUgTGljZW5zZSBmb3Ig
dGhlIHNwZWNpZmljIGxhbmd1YWdlIGdvdmVybmluZyBwZXJtaXNzaW9ucyBhbmQKIGxpbWl0
YXRpb25zIHVuZGVyIHRoZSBMaWNlbnNlLgoKCAoBAhIDEAAnCgkKAgMAEgMSACMKCQoCAwES
AxMANQoJCgIDAhIDFAA9CgkKAgMDEgMVACYKCQoCAwQSAxYAKQoICgEIEgMYADsKCQoCCCUS
AxgAOwoICgEIEgMZAGEKCQoCCAsSAxkAYQoICgEIEgMaACIKCQoCCAoSAxoAIgoICgEIEgMb
ADsKCQoCCAESAxsAOwoICgEIEgMcADsKCQoCCCkSAxwAOwoICgEIEgMdADoKCQoCCC0SAx0A
OgrUAgoCBAASBSYAhwEBGsYCIFNlY3VyaXR5IENvbW1hbmQgQ2VudGVyIHJlcHJlc2VudGF0
aW9uIG9mIGEgR29vZ2xlIENsb3VkCiByZXNvdXJjZS4KCiBUaGUgQXNzZXQgaXMgYSBTZWN1
cml0eSBDb21tYW5kIENlbnRlciByZXNvdXJjZSB0aGF0IGNhcHR1cmVzIGluZm9ybWF0aW9u
CiBhYm91dCBhIHNpbmdsZSBHb29nbGUgQ2xvdWQgcmVzb3VyY2UuIEFsbCBtb2RpZmljYXRp
b25zIHRvIGFuIEFzc2V0IGFyZSBvbmx5CiB3aXRoaW4gdGhlIGNvbnRleHQgb2YgU2VjdXJp
dHkgQ29tbWFuZCBDZW50ZXIgYW5kIGRvbid0IGFmZmVjdCB0aGUgcmVmZXJlbmNlZAogR29v
Z2xlIENsb3VkIHJlc291cmNlLgoKCgoDBAABEgMmCA0KCwoDBAAHEgQnAi4ECg0KBQQAB50I
EgQnAi4ECpkBCgQEAAMAEgQyAlYDGooBIFNlY3VyaXR5IENvbW1hbmQgQ2VudGVyIG1hbmFn
ZWQgcHJvcGVydGllcy4gVGhlc2UgcHJvcGVydGllcyBhcmUgbWFuYWdlZCBieQogU2VjdXJp
dHkgQ29tbWFuZCBDZW50ZXIgYW5kIGNhbm5vdCBiZSBtb2RpZmllZCBieSB0aGUgdXNlci4K
CgwKBQQAAwABEgMyCiIK1QEKBgQAAwACABIDNgQdGsUBIFRoZSBmdWxsIHJlc291cmNlIG5h
bWUgb2YgdGhlIEdvb2dsZSBDbG91ZCByZXNvdXJjZSB0aGlzIGFzc2V0CiByZXByZXNlbnRz
LiBUaGlzIGZpZWxkIGlzIGltbXV0YWJsZSBhZnRlciBjcmVhdGUgdGltZS4gU2VlOgogaHR0
cHM6Ly9jbG91ZC5nb29nbGUuY29tL2FwaXMvZGVzaWduL3Jlc291cmNlX25hbWVzI2Z1bGxf
cmVzb3VyY2VfbmFtZQoKDgoHBAADAAIABRIDNgQKCg4KBwQAAwACAAESAzYLGAoOCgcEAAMA
AgADEgM2GxwKgQIKBgQAAwACARIDPAQdGvEBIFRoZSB0eXBlIG9mIHRoZSBHb29nbGUgQ2xv
dWQgcmVzb3VyY2UuIEV4YW1wbGVzIGluY2x1ZGU6IEFQUExJQ0FUSU9OLAogUFJPSkVDVCwg
YW5kIE9SR0FOSVpBVElPTi4gVGhpcyBpcyBhIGNhc2UgaW5zZW5zaXRpdmUgZmllbGQgZGVm
aW5lZCBieQogU2VjdXJpdHkgQ29tbWFuZCBDZW50ZXIgYW5kL29yIHRoZSBwcm9kdWNlciBv
ZiB0aGUgcmVzb3VyY2UgYW5kIGlzCiBpbW11dGFibGUgYWZ0ZXIgY3JlYXRlIHRpbWUuCgoO
CgcEAAMAAgEFEgM8BAoKDgoHBAADAAIBARIDPAsYCg4KBwQAAwACAQMSAzwbHAqeAQoGBAAD
AAICEgNABB8ajgEgVGhlIGZ1bGwgcmVzb3VyY2UgbmFtZSBvZiB0aGUgaW1tZWRpYXRlIHBh
cmVudCBvZiB0aGUgcmVzb3VyY2UuIFNlZToKIGh0dHBzOi8vY2xvdWQuZ29vZ2xlLmNvbS9h
cGlzL2Rlc2lnbi9yZXNvdXJjZV9uYW1lcyNmdWxsX3Jlc291cmNlX25hbWUKCg4KBwQAAwAC
AgUSA0AECgoOCgcEAAMAAgIBEgNACxoKDgoHBAADAAICAxIDQB0eCp0BCgYEAAMAAgMSA0QE
IBqNASBUaGUgZnVsbCByZXNvdXJjZSBuYW1lIG9mIHRoZSBwcm9qZWN0IHRoZSByZXNvdXJj
ZSBiZWxvbmdzIHRvLiBTZWU6CiBodHRwczovL2Nsb3VkLmdvb2dsZS5jb20vYXBpcy9kZXNp
Z24vcmVzb3VyY2VfbmFtZXMjZnVsbF9yZXNvdXJjZV9uYW1lCgoOCgcEAAMAAgMFEgNEBAoK
DgoHBAADAAIDARIDRAsbCg4KBwQAAwACAwMSA0QeHwo1CgYEAAMAAgQSA0cEKBomIE93bmVy
cyBvZiB0aGUgR29vZ2xlIENsb3VkIHJlc291cmNlLgoKDgoHBAADAAIEBBIDRwQMCg4KBwQA
AwACBAUSA0cNEwoOCgcEAAMAAgQBEgNHFCMKDgoHBAADAAIEAxIDRyYnCkEKBgQAAwACBRID
SgQlGjIgVGhlIHVzZXIgZGVmaW5lZCBkaXNwbGF5IG5hbWUgZm9yIHRoaXMgcmVzb3VyY2Uu
CgoOCgcEAAMAAgUFEgNKBAoKDgoHBAADAAIFARIDSgsgCg4KBwQAAwACBQMSA0ojJApPCgYE
AAMAAgYSA00ELBpAIFRoZSB1c2VyIGRlZmluZWQgZGlzcGxheSBuYW1lIGZvciB0aGUgcGFy
ZW50IG9mIHRoaXMgcmVzb3VyY2UuCgoOCgcEAAMAAgYFEgNNBAoKDgoHBAADAAIGARIDTQsn
Cg4KBwQAAwACBgMSA00qKwpQCgYEAAMAAgcSA1AELRpBIFRoZSB1c2VyIGRlZmluZWQgZGlz
cGxheSBuYW1lIGZvciB0aGUgcHJvamVjdCBvZiB0aGlzIHJlc291cmNlLgoKDgoHBAADAAIH
BRIDUAQKCg4KBwQAAwACBwESA1ALKAoOCgcEAAMAAgcDEgNQKywKxwEKBgQAAwACCBIDVQQh
GrcBIENvbnRhaW5zIGEgRm9sZGVyIG1lc3NhZ2UgZm9yIGVhY2ggZm9sZGVyIGluIHRoZSBh
c3NldHMgYW5jZXN0cnkuCiBUaGUgZmlyc3QgZm9sZGVyIGlzIHRoZSBkZWVwZXN0IG5lc3Rl
ZCBmb2xkZXIsIGFuZCB0aGUgbGFzdCBmb2xkZXIgaXMgdGhlCiBmb2xkZXIgZGlyZWN0bHkg
dW5kZXIgdGhlIE9yZ2FuaXphdGlvbi4KCg4KBwQAAwACCAQSA1UEDAoOCgcEAAMAAggGEgNV
DRMKDgoHBAADAAIIARIDVRQbCg4KBwQAAwACCAMSA1UeIArzAQoEBAADARIEXAJhAxrkASBD
bG91ZCBJQU0gUG9saWN5IGluZm9ybWF0aW9uIGFzc29jaWF0ZWQgd2l0aCB0aGUgR29vZ2xl
IENsb3VkIHJlc291cmNlCiBkZXNjcmliZWQgYnkgdGhlIFNlY3VyaXR5IENvbW1hbmQgQ2Vu
dGVyIGFzc2V0LiBUaGlzIGluZm9ybWF0aW9uIGlzIG1hbmFnZWQKIGFuZCBkZWZpbmVkIGJ5
IHRoZSBHb29nbGUgQ2xvdWQgcmVzb3VyY2UgYW5kIGNhbm5vdCBiZSBtb2RpZmllZCBieSB0
aGUKIHVzZXIuCgoMCgUEAAMBARIDXAoTCqIBCgYEAAMBAgASA2AEGxqSASBUaGUgSlNPTiBy
ZXByZXNlbnRhdGlvbiBvZiB0aGUgUG9saWN5IGFzc29jaWF0ZWQgd2l0aCB0aGUgYXNzZXQu
CiBTZWUgaHR0cHM6Ly9jbG91ZC5nb29nbGUuY29tL2lhbS9yZWZlcmVuY2UvcmVzdC92MS9Q
b2xpY3kgZm9yIGZvcm1hdAogZGV0YWlscy4KCg4KBwQAAwECAAUSA2AECgoOCgcEAAMBAgAB
EgNgCxYKDgoHBAADAQIAAxIDYBkaCsoBCgQEAAIAEgNnAhIavAEgVGhlIHJlbGF0aXZlIHJl
c291cmNlIG5hbWUgb2YgdGhpcyBhc3NldC4gU2VlOgogaHR0cHM6Ly9jbG91ZC5nb29nbGUu
Y29tL2FwaXMvZGVzaWduL3Jlc291cmNlX25hbWVzI3JlbGF0aXZlX3Jlc291cmNlX25hbWUK
IEV4YW1wbGU6CiAib3JnYW5pemF0aW9ucy97b3JnYW5pemF0aW9uX2lkfS9hc3NldHMve2Fz
c2V0X2lkfSIuCgoMCgUEAAIABRIDZwIICgwKBQQAAgABEgNnCQ0KDAoFBAACAAMSA2cQEQqY
AQoEBAACARIDawI6GooBIFNlY3VyaXR5IENvbW1hbmQgQ2VudGVyIG1hbmFnZWQgcHJvcGVy
dGllcy4gVGhlc2UgcHJvcGVydGllcyBhcmUgbWFuYWdlZCBieQogU2VjdXJpdHkgQ29tbWFu
ZCBDZW50ZXIgYW5kIGNhbm5vdCBiZSBtb2RpZmllZCBieSB0aGUgdXNlci4KCgwKBQQAAgEG
EgNrAhoKDAoFBAACAQESA2sbNQoMCgUEAAIBAxIDazg5CpcBCgQEAAICEgNvAj0aiQEgUmVz
b3VyY2UgbWFuYWdlZCBwcm9wZXJ0aWVzLiBUaGVzZSBwcm9wZXJ0aWVzIGFyZSBtYW5hZ2Vk
IGFuZCBkZWZpbmVkIGJ5CiB0aGUgR29vZ2xlIENsb3VkIHJlc291cmNlIGFuZCBjYW5ub3Qg
YmUgbW9kaWZpZWQgYnkgdGhlIHVzZXIuCgoMCgUEAAICBhIDbwIkCgwKBQQAAgIBEgNvJTgK
DAoFBAACAgMSA287PAqgAQoEBAACAxIDcwIjGpIBIFVzZXIgc3BlY2lmaWVkIHNlY3VyaXR5
IG1hcmtzLiBUaGVzZSBtYXJrcyBhcmUgZW50aXJlbHkgbWFuYWdlZCBieSB0aGUgdXNlcgog
YW5kIGNvbWUgZnJvbSB0aGUgU2VjdXJpdHlNYXJrcyByZXNvdXJjZSB0aGF0IGJlbG9uZ3Mg
dG8gdGhlIGFzc2V0LgoKDAoFBAACAwYSA3MCDwoMCgUEAAIDARIDcxAeCgwKBQQAAgMDEgNz
ISIKUgoEBAACBBIDdgIsGkUgVGhlIHRpbWUgYXQgd2hpY2ggdGhlIGFzc2V0IHdhcyBjcmVh
dGVkIGluIFNlY3VyaXR5IENvbW1hbmQgQ2VudGVyLgoKDAoFBAACBAYSA3YCGwoMCgUEAAIE
ARIDdhwnCgwKBQQAAgQDEgN2KisKUgoEBAACBRIDeQItGkUgVGhlIHRpbWUgYXQgd2hpY2gg
dGhlIGFzc2V0IHdhcyBsYXN0IHVwZGF0ZWQgb3IgYWRkZWQgaW4gQ2xvdWQgU0NDLgoKDAoF
BAACBQYSA3kCGwoMCgUEAAIFARIDeRwnCgwKBQQAAgUDEgN5KiwK8gEKBAQAAgYSA38CHBrk
ASBDbG91ZCBJQU0gUG9saWN5IGluZm9ybWF0aW9uIGFzc29jaWF0ZWQgd2l0aCB0aGUgR29v
Z2xlIENsb3VkIHJlc291cmNlCiBkZXNjcmliZWQgYnkgdGhlIFNlY3VyaXR5IENvbW1hbmQg
Q2VudGVyIGFzc2V0LiBUaGlzIGluZm9ybWF0aW9uIGlzIG1hbmFnZWQKIGFuZCBkZWZpbmVk
IGJ5IHRoZSBHb29nbGUgQ2xvdWQgcmVzb3VyY2UgYW5kIGNhbm5vdCBiZSBtb2RpZmllZCBi
eSB0aGUKIHVzZXIuCgoMCgUEAAIGBhIDfwILCgwKBQQAAgYBEgN/DBYKDAoFBAACBgMSA38Z
GwqKAgoEBAACBxIEhgECHRr7ASBUaGUgY2Fub25pY2FsIG5hbWUgb2YgdGhlIHJlc291cmNl
LiBJdCdzIGVpdGhlcgogIm9yZ2FuaXphdGlvbnMve29yZ2FuaXphdGlvbl9pZH0vYXNzZXRz
L3thc3NldF9pZH0iLAogImZvbGRlcnMve2ZvbGRlcl9pZH0vYXNzZXRzL3thc3NldF9pZH0i
IG9yCiAicHJvamVjdHMve3Byb2plY3RfbnVtYmVyfS9hc3NldHMve2Fzc2V0X2lkfSIsIGRl
cGVuZGluZyBvbiB0aGUgY2xvc2VzdCBDUk0KIGFuY2VzdG9yIG9mIHRoZSByZXNvdXJjZS4K
Cg0KBQQAAgcFEgSGAQIICg0KBQQAAgcBEgSGAQkXCg0KBQQAAgcDEgSGARocYgZwcm90bzM=

EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Securitycenter::V1::Asset::Asset ===
    # Fields for Asset
    # Field: name Type: 9 ()
    # Field: security_center_properties Type: 11 (.google.cloud.securitycenter.v1.Asset.SecurityCenterProperties)
    # Field: resource_properties Type: 11 (.google.cloud.securitycenter.v1.Asset.ResourcePropertiesEntry)
    # Field: security_marks Type: 11 (.google.cloud.securitycenter.v1.SecurityMarks)
    # Field: create_time Type: 11 (.google.protobuf.Timestamp)
    # Field: update_time Type: 11 (.google.protobuf.Timestamp)
    # Field: iam_policy Type: 11 (.google.cloud.securitycenter.v1.Asset.IamPolicy)
    # Field: canonical_name Type: 9 ()

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Securitycenter::V1::Asset - Compiled Protocol Buffers messages for google/cloud/securitycenter/v1/asset.proto

=head1 SYNOPSIS

    use Google::Cloud::Securitycenter::V1::Asset;

    my $msg = Google::Cloud::Securitycenter::V1::Asset::Asset->new({
        name => $name,
        security_center_properties => $security_center_properties,
        resource_properties => $resource_properties,
        security_marks => $security_marks,
    });

    # Read or update a field
    my $val = $msg->name();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Securitycenter::V1::Asset::Asset->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/securitycenter/v1/asset.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Securitycenter::V1::Asset::Asset

Security Command Center representation of a Google Cloud
resource.

The Asset is a Security Command Center resource that captures information
about a single Google Cloud resource. All modifications to an Asset are only
within the context of Security Command Center and don't affect the referenced
Google Cloud resource.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

The relative resource name of this asset. See:
https://cloud.google.com/apis/design/resource_names#relative_resource_name
Example:
"organizations/{organization_id}/assets/{asset_id}".

=item * C<< $msg->security_center_properties() >> / C<< $msg->security_center_properties($value) >>

Type: C<Message> (L<Google::Cloud::Securitycenter::V1::Asset::Asset::SecurityCenterProperties>)

Security Command Center managed properties. These properties are managed by
Security Command Center and cannot be modified by the user.

=item * C<< $msg->resource_properties() >> / C<< $msg->resource_properties($value) >>

Type: C<Message> (L<Google::Cloud::Securitycenter::V1::Asset::Asset::ResourcePropertiesEntry>)

Resource managed properties. These properties are managed and defined by
the Google Cloud resource and cannot be modified by the user.

=item * C<< $msg->security_marks() >> / C<< $msg->security_marks($value) >>

Type: C<Message> (L<Google::Cloud::Securitycenter::V1::SecurityMarks::SecurityMarks>)

User specified security marks. These marks are entirely managed by the user
and come from the SecurityMarks resource that belongs to the asset.

=item * C<< $msg->create_time() >> / C<< $msg->create_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

The time at which the asset was created in Security Command Center.

=item * C<< $msg->update_time() >> / C<< $msg->update_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

The time at which the asset was last updated or added in Cloud SCC.

=item * C<< $msg->iam_policy() >> / C<< $msg->iam_policy($value) >>

Type: C<Message> (L<Google::Cloud::Securitycenter::V1::Asset::Asset::IamPolicy>)

Cloud IAM Policy information associated with the Google Cloud resource
described by the Security Command Center asset. This information is managed
and defined by the Google Cloud resource and cannot be modified by the
user.

=item * C<< $msg->canonical_name() >> / C<< $msg->canonical_name($value) >>

Type: C<String>

The canonical name of the resource. It's either
"organizations/{organization_id}/assets/{asset_id}",
"folders/{folder_id}/assets/{asset_id}" or
"projects/{project_number}/assets/{asset_id}", depending on the closest CRM
ancestor of the resource.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Securitycenter::V1::Asset::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
