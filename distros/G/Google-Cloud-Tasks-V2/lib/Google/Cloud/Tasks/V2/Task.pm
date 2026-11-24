package Google::Cloud::Tasks::V2::Task;

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
    eval { require Google::Cloud::Tasks::V2::Queue };
    eval { require Google::Cloud::Tasks::V2::Target };
    eval { require Google::Protobuf::Duration };
    eval { require Google::Protobuf::Timestamp };
    eval { require Google::Rpc::Status };
    my $descriptor_b64 = <<'EOF';
CiBnb29nbGUvY2xvdWQvdGFza3MvdjIvdGFzay5wcm90bxIVZ29vZ2xlLmNsb3VkLnRhc2tz
LnYyGh9nb29nbGUvYXBpL2ZpZWxkX2JlaGF2aW9yLnByb3RvGhlnb29nbGUvYXBpL3Jlc291
cmNlLnByb3RvGiFnb29nbGUvY2xvdWQvdGFza3MvdjIvcXVldWUucHJvdG8aImdvb2dsZS9j
bG91ZC90YXNrcy92Mi90YXJnZXQucHJvdG8aHmdvb2dsZS9wcm90b2J1Zi9kdXJhdGlvbi5w
cm90bxofZ29vZ2xlL3Byb3RvYnVmL3RpbWVzdGFtcC5wcm90bxoXZ29vZ2xlL3JwYy9zdGF0
dXMucHJvdG8ilAcKBFRhc2sSEgoEbmFtZRgBIAEoCVIEbmFtZRJkChdhcHBfZW5naW5lX2h0
dHBfcmVxdWVzdBgCIAEoCzIrLmdvb2dsZS5jbG91ZC50YXNrcy52Mi5BcHBFbmdpbmVIdHRw
UmVxdWVzdEgAUhRhcHBFbmdpbmVIdHRwUmVxdWVzdBJHCgxodHRwX3JlcXVlc3QYAyABKAsy
Ii5nb29nbGUuY2xvdWQudGFza3MudjIuSHR0cFJlcXVlc3RIAFILaHR0cFJlcXVlc3QSPwoN
c2NoZWR1bGVfdGltZRgEIAEoCzIaLmdvb2dsZS5wcm90b2J1Zi5UaW1lc3RhbXBSDHNjaGVk
dWxlVGltZRI7CgtjcmVhdGVfdGltZRgFIAEoCzIaLmdvb2dsZS5wcm90b2J1Zi5UaW1lc3Rh
bXBSCmNyZWF0ZVRpbWUSRgoRZGlzcGF0Y2hfZGVhZGxpbmUYBiABKAsyGS5nb29nbGUucHJv
dG9idWYuRHVyYXRpb25SEGRpc3BhdGNoRGVhZGxpbmUSJQoOZGlzcGF0Y2hfY291bnQYByAB
KAVSDWRpc3BhdGNoQ291bnQSJQoOcmVzcG9uc2VfY291bnQYCCABKAVSDXJlc3BvbnNlQ291
bnQSQwoNZmlyc3RfYXR0ZW1wdBgJIAEoCzIeLmdvb2dsZS5jbG91ZC50YXNrcy52Mi5BdHRl
bXB0UgxmaXJzdEF0dGVtcHQSQQoMbGFzdF9hdHRlbXB0GAogASgLMh4uZ29vZ2xlLmNsb3Vk
LnRhc2tzLnYyLkF0dGVtcHRSC2xhc3RBdHRlbXB0EjQKBHZpZXcYCyABKA4yIC5nb29nbGUu
Y2xvdWQudGFza3MudjIuVGFzay5WaWV3UgR2aWV3EkoKDHJldHJ5X2NvbmZpZxgMIAEoCzIi
Lmdvb2dsZS5jbG91ZC50YXNrcy52Mi5SZXRyeUNvbmZpZ0ID4EEBUgtyZXRyeUNvbmZpZyIx
CgRWaWV3EhQKEFZJRVdfVU5TUEVDSUZJRUQQABIJCgVCQVNJQxABEggKBEZVTEwQAjpo6kFl
Ch5jbG91ZHRhc2tzLmdvb2dsZWFwaXMuY29tL1Rhc2sSQ3Byb2plY3RzL3twcm9qZWN0fS9s
b2NhdGlvbnMve2xvY2F0aW9ufS9xdWV1ZXMve3F1ZXVlfS90YXNrcy97dGFza31CDgoMbWVz
c2FnZV90eXBlIokCCgdBdHRlbXB0Ej8KDXNjaGVkdWxlX3RpbWUYASABKAsyGi5nb29nbGUu
cHJvdG9idWYuVGltZXN0YW1wUgxzY2hlZHVsZVRpbWUSPwoNZGlzcGF0Y2hfdGltZRgCIAEo
CzIaLmdvb2dsZS5wcm90b2J1Zi5UaW1lc3RhbXBSDGRpc3BhdGNoVGltZRI/Cg1yZXNwb25z
ZV90aW1lGAMgASgLMhouZ29vZ2xlLnByb3RvYnVmLlRpbWVzdGFtcFIMcmVzcG9uc2VUaW1l
EjsKD3Jlc3BvbnNlX3N0YXR1cxgEIAEoCzISLmdvb2dsZS5ycGMuU3RhdHVzUg5yZXNwb25z
ZVN0YXR1c0JoChljb20uZ29vZ2xlLmNsb3VkLnRhc2tzLnYyQglUYXNrUHJvdG9QAVo+Y2xv
dWQuZ29vZ2xlLmNvbS9nby9jbG91ZHRhc2tzL2FwaXYyL2Nsb3VkdGFza3NwYjtjbG91ZHRh
c2tzcGJKgj8KBxIFDgDRAQEKvAQKAQwSAw4AEjKxBCBDb3B5cmlnaHQgMjAyNiBHb29nbGUg
TExDCgogTGljZW5zZWQgdW5kZXIgdGhlIEFwYWNoZSBMaWNlbnNlLCBWZXJzaW9uIDIuMCAo
dGhlICJMaWNlbnNlIik7CiB5b3UgbWF5IG5vdCB1c2UgdGhpcyBmaWxlIGV4Y2VwdCBpbiBj
b21wbGlhbmNlIHdpdGggdGhlIExpY2Vuc2UuCiBZb3UgbWF5IG9idGFpbiBhIGNvcHkgb2Yg
dGhlIExpY2Vuc2UgYXQKCiAgICAgaHR0cDovL3d3dy5hcGFjaGUub3JnL2xpY2Vuc2VzL0xJ
Q0VOU0UtMi4wCgogVW5sZXNzIHJlcXVpcmVkIGJ5IGFwcGxpY2FibGUgbGF3IG9yIGFncmVl
ZCB0byBpbiB3cml0aW5nLCBzb2Z0d2FyZQogZGlzdHJpYnV0ZWQgdW5kZXIgdGhlIExpY2Vu
c2UgaXMgZGlzdHJpYnV0ZWQgb24gYW4gIkFTIElTIiBCQVNJUywKIFdJVEhPVVQgV0FSUkFO
VElFUyBPUiBDT05ESVRJT05TIE9GIEFOWSBLSU5ELCBlaXRoZXIgZXhwcmVzcyBvciBpbXBs
aWVkLgogU2VlIHRoZSBMaWNlbnNlIGZvciB0aGUgc3BlY2lmaWMgbGFuZ3VhZ2UgZ292ZXJu
aW5nIHBlcm1pc3Npb25zIGFuZAogbGltaXRhdGlvbnMgdW5kZXIgdGhlIExpY2Vuc2UuCgoI
CgECEgMQAB4KCQoCAwASAxIAKQoJCgIDARIDEwAjCgkKAgMCEgMUACsKCQoCAwMSAxUALAoJ
CgIDBBIDFgAoCgkKAgMFEgMXACkKCQoCAwYSAxgAIQoICgEIEgMaAFUKCQoCCAsSAxoAVQoI
CgEIEgMbACIKCQoCCAoSAxsAIgoICgEIEgMcACoKCQoCCAgSAxwAKgoICgEIEgMdADIKCQoC
CAESAx0AMgooCgIEABIFIAC5AQEaGyBBIHVuaXQgb2Ygc2NoZWR1bGVkIHdvcmsuCgoKCgME
AAESAyAIDAoLCgMEAAcSBCECJAQKDQoFBAAHnQgSBCECJAQK1gIKBAQABAASBC0CQgMaxwIg
VGhlIHZpZXcgc3BlY2lmaWVzIGEgc3Vic2V0IG9mIFtUYXNrXVtnb29nbGUuY2xvdWQudGFz
a3MudjIuVGFza10gZGF0YS4KCiBXaGVuIGEgdGFzayBpcyByZXR1cm5lZCBpbiBhIHJlc3Bv
bnNlLCBub3QgYWxsCiBpbmZvcm1hdGlvbiBpcyByZXRyaWV2ZWQgYnkgZGVmYXVsdCBiZWNh
dXNlIHNvbWUgZGF0YSwgc3VjaCBhcwogcGF5bG9hZHMsIG1pZ2h0IGJlIGRlc2lyYWJsZSB0
byByZXR1cm4gb25seSB3aGVuIG5lZWRlZCBiZWNhdXNlCiBvZiBpdHMgbGFyZ2Ugc2l6ZSBv
ciBiZWNhdXNlIG9mIHRoZSBzZW5zaXRpdml0eSBvZiBkYXRhIHRoYXQgaXQKIGNvbnRhaW5z
LgoKDAoFBAAEAAESAy0HCwowCgYEAAQAAgASAy8EGRohIFVuc3BlY2lmaWVkLiBEZWZhdWx0
cyB0byBCQVNJQy4KCg4KBwQABAACAAESAy8EFAoOCgcEAAQAAgACEgMvFxgK7QIKBgQABAAC
ARIDOgQOGt0CIFRoZSBiYXNpYyB2aWV3IG9taXRzIGZpZWxkcyB3aGljaCBjYW4gYmUgbGFy
Z2Ugb3IgY2FuIGNvbnRhaW4KIHNlbnNpdGl2ZSBkYXRhLgoKIFRoaXMgdmlldyBkb2VzIG5v
dCBpbmNsdWRlIHRoZQogW2JvZHkgaW4KIEFwcEVuZ2luZUh0dHBSZXF1ZXN0XVtnb29nbGUu
Y2xvdWQudGFza3MudjIuQXBwRW5naW5lSHR0cFJlcXVlc3QuYm9keV0uCiBCb2RpZXMgYXJl
IGRlc2lyYWJsZSB0byByZXR1cm4gb25seSB3aGVuIG5lZWRlZCwgYmVjYXVzZSB0aGV5CiBj
YW4gYmUgbGFyZ2UgYW5kIGJlY2F1c2Ugb2YgdGhlIHNlbnNpdGl2aXR5IG9mIHRoZSBkYXRh
IHRoYXQgeW91CiBjaG9vc2UgdG8gc3RvcmUgaW4gaXQuCgoOCgcEAAQAAgEBEgM6BAkKDgoH
BAAEAAIBAhIDOgwNCoMCCgYEAAQAAgISA0EEDRrzASBBbGwgaW5mb3JtYXRpb24gaXMgcmV0
dXJuZWQuCgogQXV0aG9yaXphdGlvbiBmb3IgW0ZVTExdW2dvb2dsZS5jbG91ZC50YXNrcy52
Mi5UYXNrLlZpZXcuRlVMTF0gcmVxdWlyZXMKIGBjbG91ZHRhc2tzLnRhc2tzLmZ1bGxWaWV3
YCBbR29vZ2xlIElBTV0oaHR0cHM6Ly9jbG91ZC5nb29nbGUuY29tL2lhbS8pCiBwZXJtaXNz
aW9uIG9uIHRoZSBbUXVldWVdW2dvb2dsZS5jbG91ZC50YXNrcy52Mi5RdWV1ZV0gcmVzb3Vy
Y2UuCgoOCgcEAAQAAgIBEgNBBAgKDgoHBAAEAAICAhIDQQsMCpEICgQEAAIAEgNZAhIagwgg
T3B0aW9uYWxseSBjYWxsZXItc3BlY2lmaWVkIGluCiBbQ3JlYXRlVGFza11bZ29vZ2xlLmNs
b3VkLnRhc2tzLnYyLkNsb3VkVGFza3MuQ3JlYXRlVGFza10uCgogVGhlIHRhc2sgbmFtZS4K
CiBUaGUgdGFzayBuYW1lIG11c3QgaGF2ZSB0aGUgZm9sbG93aW5nIGZvcm1hdDoKIGBwcm9q
ZWN0cy9QUk9KRUNUX0lEL2xvY2F0aW9ucy9MT0NBVElPTl9JRC9xdWV1ZXMvUVVFVUVfSUQv
dGFza3MvVEFTS19JRGAKCiAqIGBQUk9KRUNUX0lEYCBjYW4gY29udGFpbiBsZXR0ZXJzIChb
QS1aYS16XSksIG51bWJlcnMgKFswLTldKSwKICAgIGh5cGhlbnMgKC0pLCBjb2xvbnMgKDop
LCBvciBwZXJpb2RzICguKS4KICAgIEZvciBtb3JlIGluZm9ybWF0aW9uLCBzZWUKICAgIFtJ
ZGVudGlmeWluZwogICAgcHJvamVjdHNdKGh0dHBzOi8vY2xvdWQuZ29vZ2xlLmNvbS9yZXNv
dXJjZS1tYW5hZ2VyL2RvY3MvY3JlYXRpbmctbWFuYWdpbmctcHJvamVjdHMjaWRlbnRpZnlp
bmdfcHJvamVjdHMpCiAqIGBMT0NBVElPTl9JRGAgaXMgdGhlIGNhbm9uaWNhbCBJRCBmb3Ig
dGhlIHRhc2sncyBsb2NhdGlvbi4KICAgIFRoZSBsaXN0IG9mIGF2YWlsYWJsZSBsb2NhdGlv
bnMgY2FuIGJlIG9idGFpbmVkIGJ5IGNhbGxpbmcKICAgIFtMaXN0TG9jYXRpb25zXVtnb29n
bGUuY2xvdWQubG9jYXRpb24uTG9jYXRpb25zLkxpc3RMb2NhdGlvbnNdLgogICAgRm9yIG1v
cmUgaW5mb3JtYXRpb24sIHNlZSBodHRwczovL2Nsb3VkLmdvb2dsZS5jb20vYWJvdXQvbG9j
YXRpb25zLy4KICogYFFVRVVFX0lEYCBjYW4gY29udGFpbiBsZXR0ZXJzIChbQS1aYS16XSks
IG51bWJlcnMgKFswLTldKSwgb3IKICAgaHlwaGVucyAoLSkuIFRoZSBtYXhpbXVtIGxlbmd0
aCBpcyAxMDAgY2hhcmFjdGVycy4KICogYFRBU0tfSURgIGNhbiBjb250YWluIG9ubHkgbGV0
dGVycyAoW0EtWmEtel0pLCBudW1iZXJzIChbMC05XSksCiAgIGh5cGhlbnMgKC0pLCBvciB1
bmRlcnNjb3JlcyAoXykuIFRoZSBtYXhpbXVtIGxlbmd0aCBpcyA1MDAgY2hhcmFjdGVycy4K
CgwKBQQAAgAFEgNZAggKDAoFBAACAAESA1kJDQoMCgUEAAIAAxIDWRARCjwKBAQACAASBFwC
aAMaLiBSZXF1aXJlZC4gVGhlIG1lc3NhZ2UgdG8gc2VuZCB0byB0aGUgd29ya2VyLgoKDAoF
BAAIAAESA1wIFAq5AQoEBAACARIDYQQ1GqsBIEhUVFAgcmVxdWVzdCB0aGF0IGlzIHNlbnQg
dG8gdGhlIEFwcCBFbmdpbmUgYXBwIGhhbmRsZXIuCgogQW4gQXBwIEVuZ2luZSB0YXNrIGlz
IGEgdGFzayB0aGF0IGhhcwogW0FwcEVuZ2luZUh0dHBSZXF1ZXN0XVtnb29nbGUuY2xvdWQu
dGFza3MudjIuQXBwRW5naW5lSHR0cFJlcXVlc3RdIHNldC4KCgwKBQQAAgEGEgNhBBgKDAoF
BAACAQESA2EZMAoMCgUEAAIBAxIDYTM0CpEBCgQEAAICEgNnBCEagwEgSFRUUCByZXF1ZXN0
IHRoYXQgaXMgc2VudCB0byB0aGUgd29ya2VyLgoKIEFuIEhUVFAgdGFzayBpcyBhIHRhc2sg
dGhhdCBoYXMKIFtIdHRwUmVxdWVzdF1bZ29vZ2xlLmNsb3VkLnRhc2tzLnYyLkh0dHBSZXF1
ZXN0XSBzZXQuCgoMCgUEAAICBhIDZwQPCgwKBQQAAgIBEgNnEBwKDAoFBAACAgMSA2cfIAqP
AQoEBAACAxIDbQIuGoEBIFRoZSB0aW1lIHdoZW4gdGhlIHRhc2sgaXMgc2NoZWR1bGVkIHRv
IGJlIGF0dGVtcHRlZCBvciByZXRyaWVkLgoKIGBzY2hlZHVsZV90aW1lYCB3aWxsIGJlIHRy
dW5jYXRlZCB0byB0aGUgbmVhcmVzdCBtaWNyb3NlY29uZC4KCgwKBQQAAgMGEgNtAhsKDAoF
BAACAwESA20cKQoMCgUEAAIDAxIDbSwtCngKBAQAAgQSA3ICLBprIE91dHB1dCBvbmx5LiBU
aGUgdGltZSB0aGF0IHRoZSB0YXNrIHdhcyBjcmVhdGVkLgoKIGBjcmVhdGVfdGltZWAgd2ls
bCBiZSB0cnVuY2F0ZWQgdG8gdGhlIG5lYXJlc3Qgc2Vjb25kLgoKDAoFBAACBAYSA3ICGwoM
CgUEAAIEARIDchwnCgwKBQQAAgQDEgNyKisK5w8KBAQAAgUSBJkBAjEa2A8gVGhlIGRlYWRs
aW5lIGZvciByZXF1ZXN0cyBzZW50IHRvIHRoZSB3b3JrZXIuIElmIHRoZSB3b3JrZXIgZG9l
cyBub3QKIHJlc3BvbmQgYnkgdGhpcyBkZWFkbGluZSB0aGVuIHRoZSByZXF1ZXN0IGlzIGNh
bmNlbGxlZCBhbmQgdGhlIGF0dGVtcHQKIGlzIG1hcmtlZCBhcyBhIGBERUFETElORV9FWENF
RURFRGAgZmFpbHVyZS4gQ2xvdWQgVGFza3Mgd2lsbCByZXRyeSB0aGUKIHRhc2sgYWNjb3Jk
aW5nIHRvIHRoZSBbUmV0cnlDb25maWddW2dvb2dsZS5jbG91ZC50YXNrcy52Mi5SZXRyeUNv
bmZpZ10uCgogTm90ZSB0aGF0IHdoZW4gdGhlIHJlcXVlc3QgaXMgY2FuY2VsbGVkLCBDbG91
ZCBUYXNrcyB3aWxsIHN0b3AgbGlzdGVuaW5nCiBmb3IgdGhlIHJlc3BvbnNlLCBidXQgd2hl
dGhlciB0aGUgd29ya2VyIHN0b3BzIHByb2Nlc3NpbmcgZGVwZW5kcyBvbiB0aGUKIHdvcmtl
ci4gRm9yIGV4YW1wbGUsIGlmIHRoZSB3b3JrZXIgaXMgc3R1Y2ssIGl0IG1heSBub3QgcmVh
Y3QgdG8gY2FuY2VsbGVkCiByZXF1ZXN0cy4KCiBUaGUgZGVmYXVsdCBhbmQgbWF4aW11bSB2
YWx1ZXMgZGVwZW5kIG9uIHRoZSB0eXBlIG9mIHJlcXVlc3Q6CgogKiBGb3IgW0hUVFAgdGFz
a3NdW2dvb2dsZS5jbG91ZC50YXNrcy52Mi5IdHRwUmVxdWVzdF0sIHRoZSBkZWZhdWx0IGlz
IDEwCiBtaW51dGVzLiBUaGUgZGVhZGxpbmUKICAgbXVzdCBiZSBpbiB0aGUgaW50ZXJ2YWwg
WzE1IHNlY29uZHMsIDMwIG1pbnV0ZXNdLgoKICogRm9yIFtBcHAgRW5naW5lIHRhc2tzXVtn
b29nbGUuY2xvdWQudGFza3MudjIuQXBwRW5naW5lSHR0cFJlcXVlc3RdLCAwCiBpbmRpY2F0
ZXMgdGhhdCB0aGUKICAgcmVxdWVzdCBoYXMgdGhlIGRlZmF1bHQgZGVhZGxpbmUuIFRoZSBk
ZWZhdWx0IGRlYWRsaW5lIGRlcGVuZHMgb24gdGhlCiAgIFtzY2FsaW5nCiAgIHR5cGVdKGh0
dHBzOi8vY2xvdWQuZ29vZ2xlLmNvbS9hcHBlbmdpbmUvZG9jcy9zdGFuZGFyZC9nby9ob3ct
aW5zdGFuY2VzLWFyZS1tYW5hZ2VkI2luc3RhbmNlX3NjYWxpbmcpCiAgIG9mIHRoZSBzZXJ2
aWNlOiAxMCBtaW51dGVzIGZvciBzdGFuZGFyZCBhcHBzIHdpdGggYXV0b21hdGljIHNjYWxp
bmcsIDI0CiAgIGhvdXJzIGZvciBzdGFuZGFyZCBhcHBzIHdpdGggbWFudWFsIGFuZCBiYXNp
YyBzY2FsaW5nLCBhbmQgNjAgbWludXRlcyBmb3IKICAgZmxleCBhcHBzLiBJZiB0aGUgcmVx
dWVzdCBkZWFkbGluZSBpcyBzZXQsIGl0IG11c3QgYmUgaW4gdGhlIGludGVydmFsIFsxNQog
ICBzZWNvbmRzLCAyNCBob3VycyAxNSBzZWNvbmRzXS4gUmVnYXJkbGVzcyBvZiB0aGUgdGFz
aydzCiAgIGBkaXNwYXRjaF9kZWFkbGluZWAsIHRoZSBhcHAgaGFuZGxlciB3aWxsIG5vdCBy
dW4gZm9yIGxvbmdlciB0aGFuIHRoYW4KICAgdGhlIHNlcnZpY2UncyB0aW1lb3V0LiBXZSBy
ZWNvbW1lbmQgc2V0dGluZyB0aGUgYGRpc3BhdGNoX2RlYWRsaW5lYCB0bwogICBhdCBtb3N0
IGEgZmV3IHNlY29uZHMgbW9yZSB0aGFuIHRoZSBhcHAgaGFuZGxlcidzIHRpbWVvdXQuIEZv
ciBtb3JlCiAgIGluZm9ybWF0aW9uIHNlZQogICBbVGltZW91dHNdKGh0dHBzOi8vY2xvdWQu
Z29vZ2xlLmNvbS90YXNrcy9kb2NzL2NyZWF0aW5nLWFwcGVuZ2luZS1oYW5kbGVycyN0aW1l
b3V0cykuCgogVGhlIHZhbHVlIG11c3QgYmUgZ2l2ZW4gYXMgYSBzdHJpbmcgdGhhdCBpbmRp
Y2F0ZXMgdGhlIGxlbmd0aCBvZiB0aW1lCiAoaW4gc2Vjb25kcykgZm9sbG93ZWQgYnkgYHNg
IChmb3IgInNlY29uZHMiKS4gRm9yIG1vcmUgaW5mb3JtYXRpb24gb24gdGhlCiBmb3JtYXQs
IHNlZSB0aGUgZG9jdW1lbnRhdGlvbiBmb3IKIFtEdXJhdGlvbl0oaHR0cHM6Ly9wcm90b2J1
Zi5kZXYvcmVmZXJlbmNlL3Byb3RvYnVmL2dvb2dsZS5wcm90b2J1Zi8jZHVyYXRpb24pLgog
YGRpc3BhdGNoX2RlYWRsaW5lYCB3aWxsIGJlIHRydW5jYXRlZCB0byB0aGUgbmVhcmVzdCBt
aWxsaXNlY29uZC4gVGhlCiBkZWFkbGluZSBpcyBhbiBhcHByb3hpbWF0ZSBkZWFkbGluZS4K
Cg0KBQQAAgUGEgSZAQIaCg0KBQQAAgUBEgSZARssCg0KBQQAAgUDEgSZAS8wCpwBCgQEAAIG
EgSfAQIbGo0BIE91dHB1dCBvbmx5LiBUaGUgbnVtYmVyIG9mIGF0dGVtcHRzIGRpc3BhdGNo
ZWQuCgogVGhpcyBjb3VudCBpbmNsdWRlcyBhdHRlbXB0cyB3aGljaCBoYXZlIGJlZW4gZGlz
cGF0Y2hlZCBidXQgaGF2ZW4ndAogcmVjZWl2ZWQgYSByZXNwb25zZS4KCg0KBQQAAgYFEgSf
AQIHCg0KBQQAAgYBEgSfAQgWCg0KBQQAAgYDEgSfARkaClMKBAQAAgcSBKIBAhsaRSBPdXRw
dXQgb25seS4gVGhlIG51bWJlciBvZiBhdHRlbXB0cyB3aGljaCBoYXZlIHJlY2VpdmVkIGEg
cmVzcG9uc2UuCgoNCgUEAAIHBRIEogECBwoNCgUEAAIHARIEogEIFgoNCgUEAAIHAxIEogEZ
Ggr3AQoEBAACCBIEqQECHBroASBPdXRwdXQgb25seS4gVGhlIHN0YXR1cyBvZiB0aGUgdGFz
aydzIGZpcnN0IGF0dGVtcHQuCgogT25seSBbZGlzcGF0Y2hfdGltZV1bZ29vZ2xlLmNsb3Vk
LnRhc2tzLnYyLkF0dGVtcHQuZGlzcGF0Y2hfdGltZV0gd2lsbCBiZQogc2V0LiBUaGUgb3Ro
ZXIgW0F0dGVtcHRdW2dvb2dsZS5jbG91ZC50YXNrcy52Mi5BdHRlbXB0XSBpbmZvcm1hdGlv
biBpcyBub3QKIHJldGFpbmVkIGJ5IENsb3VkIFRhc2tzLgoKDQoFBAACCAYSBKkBAgkKDQoF
BAACCAESBKkBChcKDQoFBAACCAMSBKkBGhsKQwoEBAACCRIErAECHBo1IE91dHB1dCBvbmx5
LiBUaGUgc3RhdHVzIG9mIHRoZSB0YXNrJ3MgbGFzdCBhdHRlbXB0LgoKDQoFBAACCQYSBKwB
AgkKDQoFBAACCQESBKwBChYKDQoFBAACCQMSBKwBGRsKegoEBAACChIEsAECERpsIE91dHB1
dCBvbmx5LiBUaGUgdmlldyBzcGVjaWZpZXMgd2hpY2ggc3Vic2V0IG9mIHRoZQogW1Rhc2td
W2dvb2dsZS5jbG91ZC50YXNrcy52Mi5UYXNrXSBoYXMgYmVlbiByZXR1cm5lZC4KCg0KBQQA
AgoGEgSwAQIGCg0KBQQAAgoBEgSwAQcLCg0KBQQAAgoDEgSwAQ4QCtcBCgQEAAILEgS4AQJJ
GsgBIE9wdGlvbmFsLiBTcGVjaWZpZXMgdGhlIHRhc2stbGV2ZWwKIFtSZXRyeUNvbmZpZ11b
Z29vZ2xlLmNsb3VkLnRhc2tzLnYyLlJldHJ5Q29uZmlnXS4KCiBJZiBwcmVzZW50LCB0aGlz
IG92ZXJyaWRlcyB0aGUKIFtRdWV1ZS5yZXRyeV9jb25maWddW2dvb2dsZS5jbG91ZC50YXNr
cy52Mi5RdWV1ZS5yZXRyeV9jb25maWddIGZvciB0aGlzCiB0YXNrLgoKDQoFBAACCwYSBLgB
Ag0KDQoFBAACCwESBLgBDhoKDQoFBAACCwMSBLgBHR8KDQoFBAACCwgSBLgBIEgKEAoIBAAC
CwicCAASBLgBIUcKLQoCBAESBrwBANEBARofIFRoZSBzdGF0dXMgb2YgYSB0YXNrIGF0dGVt
cHQuCgoLCgMEAQESBLwBCA8KhgEKBAQBAgASBMABAi4aeCBPdXRwdXQgb25seS4gVGhlIHRp
bWUgdGhhdCB0aGlzIGF0dGVtcHQgd2FzIHNjaGVkdWxlZC4KCiBgc2NoZWR1bGVfdGltZWAg
d2lsbCBiZSB0cnVuY2F0ZWQgdG8gdGhlIG5lYXJlc3QgbWljcm9zZWNvbmQuCgoNCgUEAQIA
BhIEwAECGwoNCgUEAQIAARIEwAEcKQoNCgUEAQIAAxIEwAEsLQqHAQoEBAECARIExQECLhp5
IE91dHB1dCBvbmx5LiBUaGUgdGltZSB0aGF0IHRoaXMgYXR0ZW1wdCB3YXMgZGlzcGF0Y2hl
ZC4KCiBgZGlzcGF0Y2hfdGltZWAgd2lsbCBiZSB0cnVuY2F0ZWQgdG8gdGhlIG5lYXJlc3Qg
bWljcm9zZWNvbmQuCgoNCgUEAQIBBhIExQECGwoNCgUEAQIBARIExQEcKQoNCgUEAQIBAxIE
xQEsLQqPAQoEBAECAhIEygECLhqAASBPdXRwdXQgb25seS4gVGhlIHRpbWUgdGhhdCB0aGlz
IGF0dGVtcHQgcmVzcG9uc2Ugd2FzIHJlY2VpdmVkLgoKIGByZXNwb25zZV90aW1lYCB3aWxs
IGJlIHRydW5jYXRlZCB0byB0aGUgbmVhcmVzdCBtaWNyb3NlY29uZC4KCg0KBQQBAgIGEgTK
AQIbCg0KBQQBAgIBEgTKARwpCg0KBQQBAgIDEgTKASwtCtkBCgQEAQIDEgTQAQIoGsoBIE91
dHB1dCBvbmx5LiBUaGUgcmVzcG9uc2UgZnJvbSB0aGUgd29ya2VyIGZvciB0aGlzIGF0dGVt
cHQuCgogSWYgYHJlc3BvbnNlX3RpbWVgIGlzIHVuc2V0LCB0aGVuIHRoZSB0YXNrIGhhcyBu
b3QgYmVlbiBhdHRlbXB0ZWQgb3IgaXMKIGN1cnJlbnRseSBydW5uaW5nIGFuZCB0aGUgYHJl
c3BvbnNlX3N0YXR1c2AgZmllbGQgaXMgbWVhbmluZ2xlc3MuCgoNCgUEAQIDBhIE0AECEwoN
CgUEAQIDARIE0AEUIwoNCgUEAQIDAxIE0AEmJ2IGcHJvdG8z
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Tasks::V2::Task::Task ===
    # Fields for Task
    # Field: name Type: 9 ()
    # Field: app_engine_http_request Type: 11 (.google.cloud.tasks.v2.AppEngineHttpRequest)
    # Field: http_request Type: 11 (.google.cloud.tasks.v2.HttpRequest)
    # Field: schedule_time Type: 11 (.google.protobuf.Timestamp)
    # Field: create_time Type: 11 (.google.protobuf.Timestamp)
    # Field: dispatch_deadline Type: 11 (.google.protobuf.Duration)
    # Field: dispatch_count Type: 5 ()
    # Field: response_count Type: 5 ()
    # Field: first_attempt Type: 11 (.google.cloud.tasks.v2.Attempt)
    # Field: last_attempt Type: 11 (.google.cloud.tasks.v2.Attempt)
    # Field: view Type: 14 (.google.cloud.tasks.v2.Task.View)
    # Field: retry_config Type: 11 (.google.cloud.tasks.v2.RetryConfig)

# Enum: Task::View
our $Task_VIEW_UNSPECIFIED = 0;
our $Task_BASIC = 1;
our $Task_FULL = 2;

# === Message: Google::Cloud::Tasks::V2::Task::Attempt ===
    # Fields for Attempt
    # Field: schedule_time Type: 11 (.google.protobuf.Timestamp)
    # Field: dispatch_time Type: 11 (.google.protobuf.Timestamp)
    # Field: response_time Type: 11 (.google.protobuf.Timestamp)
    # Field: response_status Type: 11 (.google.rpc.Status)

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Tasks::V2::Task - Compiled Protocol Buffers messages for google/cloud/tasks/v2/task.proto

=head1 SYNOPSIS

    use Google::Cloud::Tasks::V2::Task;

    my $msg = Google::Cloud::Tasks::V2::Task::Task->new({
        name => $name,
        app_engine_http_request => $app_engine_http_request,
        http_request => $http_request,
        schedule_time => $schedule_time,
    });

    # Read or update a field
    my $val = $msg->name();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Tasks::V2::Task::Task->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/tasks/v2/task.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Tasks::V2::Task::Task

A unit of scheduled work.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Optionally caller-specified in
[CreateTask][google.cloud.tasks.v2.CloudTasks.CreateTask].

The task name.

The task name must have the following format:
`projects/PROJECT_ID/locations/LOCATION_ID/queues/QUEUE_ID/tasks/TASK_ID`

* `PROJECT_ID` can contain letters ([A-Za-z]), numbers ([0-9]),
   hyphens (-), colons (:), or periods (.).
   For more information, see
   [Identifying
   projects](https://cloud.google.com/resource-manager/docs/creating-managing-projects#identifying_projects)
* `LOCATION_ID` is the canonical ID for the task's location.
   The list of available locations can be obtained by calling
   [ListLocations][google.cloud.location.Locations.ListLocations].
   For more information, see https://cloud.google.com/about/locations/.
* `QUEUE_ID` can contain letters ([A-Za-z]), numbers ([0-9]), or
  hyphens (-). The maximum length is 100 characters.
* `TASK_ID` can contain only letters ([A-Za-z]), numbers ([0-9]),
  hyphens (-), or underscores (_). The maximum length is 500 characters.

=item * C<< $msg->app_engine_http_request() >> / C<< $msg->app_engine_http_request($value) >>

Type: C<Message> (L<Google::Cloud::Tasks::V2::Target::AppEngineHttpRequest>)

HTTP request that is sent to the App Engine app handler.

An App Engine task is a task that has
[AppEngineHttpRequest][google.cloud.tasks.v2.AppEngineHttpRequest] set.

=item * C<< $msg->http_request() >> / C<< $msg->http_request($value) >>

Type: C<Message> (L<Google::Cloud::Tasks::V2::Target::HttpRequest>)

HTTP request that is sent to the worker.

An HTTP task is a task that has
[HttpRequest][google.cloud.tasks.v2.HttpRequest] set.

=item * C<< $msg->schedule_time() >> / C<< $msg->schedule_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

The time when the task is scheduled to be attempted or retried.

`schedule_time` will be truncated to the nearest microsecond.

=item * C<< $msg->create_time() >> / C<< $msg->create_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Output only. The time that the task was created.

`create_time` will be truncated to the nearest second.

=item * C<< $msg->dispatch_deadline() >> / C<< $msg->dispatch_deadline($value) >>

Type: C<Message> (L<Google::Protobuf::Duration::Duration>)

The deadline for requests sent to the worker. If the worker does not
respond by this deadline then the request is cancelled and the attempt
is marked as a `DEADLINE_EXCEEDED` failure. Cloud Tasks will retry the
task according to the [RetryConfig][google.cloud.tasks.v2.RetryConfig].

Note that when the request is cancelled, Cloud Tasks will stop listening
for the response, but whether the worker stops processing depends on the
worker. For example, if the worker is stuck, it may not react to cancelled
requests.

The default and maximum values depend on the type of request:

* For [HTTP tasks][google.cloud.tasks.v2.HttpRequest], the default is 10
minutes. The deadline
  must be in the interval [15 seconds, 30 minutes].

* For [App Engine tasks][google.cloud.tasks.v2.AppEngineHttpRequest], 0
indicates that the
  request has the default deadline. The default deadline depends on the
  [scaling
  type](https://cloud.google.com/appengine/docs/standard/go/how-instances-are-managed#instance_scaling)
  of the service: 10 minutes for standard apps with automatic scaling, 24
  hours for standard apps with manual and basic scaling, and 60 minutes for
  flex apps. If the request deadline is set, it must be in the interval [15
  seconds, 24 hours 15 seconds]. Regardless of the task's
  `dispatch_deadline`, the app handler will not run for longer than than
  the service's timeout. We recommend setting the `dispatch_deadline` to
  at most a few seconds more than the app handler's timeout. For more
  information see
  [Timeouts](https://cloud.google.com/tasks/docs/creating-appengine-handlers#timeouts).

The value must be given as a string that indicates the length of time
(in seconds) followed by `s` (for "seconds"). For more information on the
format, see the documentation for
[Duration](https://protobuf.dev/reference/protobuf/google.protobuf/#duration).
`dispatch_deadline` will be truncated to the nearest millisecond. The
deadline is an approximate deadline.

=item * C<< $msg->dispatch_count() >> / C<< $msg->dispatch_count($value) >>

Type: C<Int32>

Output only. The number of attempts dispatched.

This count includes attempts which have been dispatched but haven't
received a response.

=item * C<< $msg->response_count() >> / C<< $msg->response_count($value) >>

Type: C<Int32>

Output only. The number of attempts which have received a response.

=item * C<< $msg->first_attempt() >> / C<< $msg->first_attempt($value) >>

Type: C<Message> (L<Google::Cloud::Tasks::V2::Task::Attempt>)

Output only. The status of the task's first attempt.

Only [dispatch_time][google.cloud.tasks.v2.Attempt.dispatch_time] will be
set. The other [Attempt][google.cloud.tasks.v2.Attempt] information is not
retained by Cloud Tasks.

=item * C<< $msg->last_attempt() >> / C<< $msg->last_attempt($value) >>

Type: C<Message> (L<Google::Cloud::Tasks::V2::Task::Attempt>)

Output only. The status of the task's last attempt.

=item * C<< $msg->view() >> / C<< $msg->view($value) >>

Type: C<Enum> (L<Google::Cloud::Tasks::V2::Task::View>)

Output only. The view specifies which subset of the
[Task][google.cloud.tasks.v2.Task] has been returned.

=item * C<< $msg->retry_config() >> / C<< $msg->retry_config($value) >>

Type: C<Message> (L<Google::Cloud::Tasks::V2::Queue::RetryConfig>)

Optional. Specifies the task-level
[RetryConfig][google.cloud.tasks.v2.RetryConfig].

If present, this overrides the
[Queue.retry_config][google.cloud.tasks.v2.Queue.retry_config] for this
task.

=back

=head3 Enum: Task::View

=over 4

=item * C<VIEW_UNSPECIFIED> => C<0>

=item * C<BASIC> => C<1>

=item * C<FULL> => C<2>

=back

=head2 Google::Cloud::Tasks::V2::Task::Attempt

The status of a task attempt.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->schedule_time() >> / C<< $msg->schedule_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Output only. The time that this attempt was scheduled.

`schedule_time` will be truncated to the nearest microsecond.

=item * C<< $msg->dispatch_time() >> / C<< $msg->dispatch_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Output only. The time that this attempt was dispatched.

`dispatch_time` will be truncated to the nearest microsecond.

=item * C<< $msg->response_time() >> / C<< $msg->response_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Output only. The time that this attempt response was received.

`response_time` will be truncated to the nearest microsecond.

=item * C<< $msg->response_status() >> / C<< $msg->response_status($value) >>

Type: C<Message> (L<Google::Rpc::Status::Status>)

Output only. The response from the worker for this attempt.

If `response_time` is unset, then the task has not been attempted or is
currently running and the `response_status` field is meaningless.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Tasks::V2::Task::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
