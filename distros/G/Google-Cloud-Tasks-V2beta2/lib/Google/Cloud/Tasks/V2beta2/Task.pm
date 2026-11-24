package Google::Cloud::Tasks::V2beta2::Task;

use strict;
use warnings;

our $VERSION = '0.14';

use Protobuf::Message;
use Protobuf::DescriptorPool;
use Protobuf::Internal qw(:all);
use MIME::Base64;

BEGIN {
    eval { require Google::Api::Resource };
    eval { require Google::Cloud::Tasks::V2beta2::Target };
    eval { require Google::Protobuf::Timestamp };
    eval { require Google::Rpc::Status };
    my $descriptor_b64 = <<'EOF';
CiVnb29nbGUvY2xvdWQvdGFza3MvdjJiZXRhMi90YXNrLnByb3RvEhpnb29nbGUuY2xvdWQu
dGFza3MudjJiZXRhMhoZZ29vZ2xlL2FwaS9yZXNvdXJjZS5wcm90bxonZ29vZ2xlL2Nsb3Vk
L3Rhc2tzL3YyYmV0YTIvdGFyZ2V0LnByb3RvGh9nb29nbGUvcHJvdG9idWYvdGltZXN0YW1w
LnByb3RvGhdnb29nbGUvcnBjL3N0YXR1cy5wcm90byLHBQoEVGFzaxISCgRuYW1lGAEgASgJ
UgRuYW1lEmkKF2FwcF9lbmdpbmVfaHR0cF9yZXF1ZXN0GAMgASgLMjAuZ29vZ2xlLmNsb3Vk
LnRhc2tzLnYyYmV0YTIuQXBwRW5naW5lSHR0cFJlcXVlc3RIAFIUYXBwRW5naW5lSHR0cFJl
cXVlc3QSTAoMcHVsbF9tZXNzYWdlGAQgASgLMicuZ29vZ2xlLmNsb3VkLnRhc2tzLnYyYmV0
YTIuUHVsbE1lc3NhZ2VIAFILcHVsbE1lc3NhZ2USTAoMaHR0cF9yZXF1ZXN0GA0gASgLMicu
Z29vZ2xlLmNsb3VkLnRhc2tzLnYyYmV0YTIuSHR0cFJlcXVlc3RIAFILaHR0cFJlcXVlc3QS
PwoNc2NoZWR1bGVfdGltZRgFIAEoCzIaLmdvb2dsZS5wcm90b2J1Zi5UaW1lc3RhbXBSDHNj
aGVkdWxlVGltZRI7CgtjcmVhdGVfdGltZRgGIAEoCzIaLmdvb2dsZS5wcm90b2J1Zi5UaW1l
c3RhbXBSCmNyZWF0ZVRpbWUSPgoGc3RhdHVzGAcgASgLMiYuZ29vZ2xlLmNsb3VkLnRhc2tz
LnYyYmV0YTIuVGFza1N0YXR1c1IGc3RhdHVzEjkKBHZpZXcYCCABKA4yJS5nb29nbGUuY2xv
dWQudGFza3MudjJiZXRhMi5UYXNrLlZpZXdSBHZpZXciMQoEVmlldxIUChBWSUVXX1VOU1BF
Q0lGSUVEEAASCQoFQkFTSUMQARIICgRGVUxMEAI6aOpBZQoeY2xvdWR0YXNrcy5nb29nbGVh
cGlzLmNvbS9UYXNrEkNwcm9qZWN0cy97cHJvamVjdH0vbG9jYXRpb25zL3tsb2NhdGlvbn0v
cXVldWVzL3txdWV1ZX0vdGFza3Mve3Rhc2t9Qg4KDHBheWxvYWRfdHlwZSKwAgoKVGFza1N0
YXR1cxI0ChZhdHRlbXB0X2Rpc3BhdGNoX2NvdW50GAEgASgFUhRhdHRlbXB0RGlzcGF0Y2hD
b3VudBI0ChZhdHRlbXB0X3Jlc3BvbnNlX2NvdW50GAIgASgFUhRhdHRlbXB0UmVzcG9uc2VD
b3VudBJbChRmaXJzdF9hdHRlbXB0X3N0YXR1cxgDIAEoCzIpLmdvb2dsZS5jbG91ZC50YXNr
cy52MmJldGEyLkF0dGVtcHRTdGF0dXNSEmZpcnN0QXR0ZW1wdFN0YXR1cxJZChNsYXN0X2F0
dGVtcHRfc3RhdHVzGAQgASgLMikuZ29vZ2xlLmNsb3VkLnRhc2tzLnYyYmV0YTIuQXR0ZW1w
dFN0YXR1c1IRbGFzdEF0dGVtcHRTdGF0dXMijwIKDUF0dGVtcHRTdGF0dXMSPwoNc2NoZWR1
bGVfdGltZRgBIAEoCzIaLmdvb2dsZS5wcm90b2J1Zi5UaW1lc3RhbXBSDHNjaGVkdWxlVGlt
ZRI/Cg1kaXNwYXRjaF90aW1lGAIgASgLMhouZ29vZ2xlLnByb3RvYnVmLlRpbWVzdGFtcFIM
ZGlzcGF0Y2hUaW1lEj8KDXJlc3BvbnNlX3RpbWUYAyABKAsyGi5nb29nbGUucHJvdG9idWYu
VGltZXN0YW1wUgxyZXNwb25zZVRpbWUSOwoPcmVzcG9uc2Vfc3RhdHVzGAQgASgLMhIuZ29v
Z2xlLnJwYy5TdGF0dXNSDnJlc3BvbnNlU3RhdHVzQnIKHmNvbS5nb29nbGUuY2xvdWQudGFz
a3MudjJiZXRhMkIJVGFza1Byb3RvUAFaQ2Nsb3VkLmdvb2dsZS5jb20vZ28vY2xvdWR0YXNr
cy9hcGl2MmJldGEyL2Nsb3VkdGFza3NwYjtjbG91ZHRhc2tzcGJK8zcKBxIFDgDMAQEKvAQK
AQwSAw4AEjKxBCBDb3B5cmlnaHQgMjAyNSBHb29nbGUgTExDCgogTGljZW5zZWQgdW5kZXIg
dGhlIEFwYWNoZSBMaWNlbnNlLCBWZXJzaW9uIDIuMCAodGhlICJMaWNlbnNlIik7CiB5b3Ug
bWF5IG5vdCB1c2UgdGhpcyBmaWxlIGV4Y2VwdCBpbiBjb21wbGlhbmNlIHdpdGggdGhlIExp
Y2Vuc2UuCiBZb3UgbWF5IG9idGFpbiBhIGNvcHkgb2YgdGhlIExpY2Vuc2UgYXQKCiAgICAg
aHR0cDovL3d3dy5hcGFjaGUub3JnL2xpY2Vuc2VzL0xJQ0VOU0UtMi4wCgogVW5sZXNzIHJl
cXVpcmVkIGJ5IGFwcGxpY2FibGUgbGF3IG9yIGFncmVlZCB0byBpbiB3cml0aW5nLCBzb2Z0
d2FyZQogZGlzdHJpYnV0ZWQgdW5kZXIgdGhlIExpY2Vuc2UgaXMgZGlzdHJpYnV0ZWQgb24g
YW4gIkFTIElTIiBCQVNJUywKIFdJVEhPVVQgV0FSUkFOVElFUyBPUiBDT05ESVRJT05TIE9G
IEFOWSBLSU5ELCBlaXRoZXIgZXhwcmVzcyBvciBpbXBsaWVkLgogU2VlIHRoZSBMaWNlbnNl
IGZvciB0aGUgc3BlY2lmaWMgbGFuZ3VhZ2UgZ292ZXJuaW5nIHBlcm1pc3Npb25zIGFuZAog
bGltaXRhdGlvbnMgdW5kZXIgdGhlIExpY2Vuc2UuCgoICgECEgMQACMKCQoCAwASAxIAIwoJ
CgIDARIDEwAxCgkKAgMCEgMUACkKCQoCAwMSAxUAIQoICgEIEgMXAFoKCQoCCAsSAxcAWgoI
CgEIEgMYACIKCQoCCAoSAxgAIgoICgEIEgMZACoKCQoCCAgSAxkAKgoICgEIEgMaADcKCQoC
CAESAxoANwooCgIEABIFHQCTAQEaGyBBIHVuaXQgb2Ygc2NoZWR1bGVkIHdvcmsuCgoKCgME
AAESAx0IDAoLCgMEAAcSBB4CIQQKDQoFBAAHnQgSBB4CIQQK3AIKBAQABAASBCsCQwMazQIg
VGhlIHZpZXcgc3BlY2lmaWVzIGEgc3Vic2V0IG9mIFtUYXNrXVtnb29nbGUuY2xvdWQudGFz
a3MudjJiZXRhMi5UYXNrXQogZGF0YS4KCiBXaGVuIGEgdGFzayBpcyByZXR1cm5lZCBpbiBh
IHJlc3BvbnNlLCBub3QgYWxsCiBpbmZvcm1hdGlvbiBpcyByZXRyaWV2ZWQgYnkgZGVmYXVs
dCBiZWNhdXNlIHNvbWUgZGF0YSwgc3VjaCBhcwogcGF5bG9hZHMsIG1pZ2h0IGJlIGRlc2ly
YWJsZSB0byByZXR1cm4gb25seSB3aGVuIG5lZWRlZCBiZWNhdXNlCiBvZiBpdHMgbGFyZ2Ug
c2l6ZSBvciBiZWNhdXNlIG9mIHRoZSBzZW5zaXRpdml0eSBvZiBkYXRhIHRoYXQgaXQKIGNv
bnRhaW5zLgoKDAoFBAAEAAESAysHCwowCgYEAAQAAgASAy0EGRohIFVuc3BlY2lmaWVkLiBE
ZWZhdWx0cyB0byBCQVNJQy4KCg4KBwQABAACAAESAy0EFAoOCgcEAAQAAgACEgMtFxgKyQMK
BgQABAACARIDOgQOGrkDIFRoZSBiYXNpYyB2aWV3IG9taXRzIGZpZWxkcyB3aGljaCBjYW4g
YmUgbGFyZ2Ugb3IgY2FuIGNvbnRhaW4KIHNlbnNpdGl2ZSBkYXRhLgoKIFRoaXMgdmlldyBk
b2VzIG5vdCBpbmNsdWRlIHRoZQogKFtwYXlsb2FkIGluCiBBcHBFbmdpbmVIdHRwUmVxdWVz
dF1bZ29vZ2xlLmNsb3VkLnRhc2tzLnYyYmV0YTIuQXBwRW5naW5lSHR0cFJlcXVlc3RdCiBh
bmQgW3BheWxvYWQgaW4KIFB1bGxNZXNzYWdlXVtnb29nbGUuY2xvdWQudGFza3MudjJiZXRh
Mi5QdWxsTWVzc2FnZS5wYXlsb2FkXSkuIFRoZXNlCiBwYXlsb2FkcyBhcmUgZGVzaXJhYmxl
IHRvIHJldHVybiBvbmx5IHdoZW4gbmVlZGVkLCBiZWNhdXNlIHRoZXkgY2FuIGJlCiBsYXJn
ZSBhbmQgYmVjYXVzZSBvZiB0aGUgc2Vuc2l0aXZpdHkgb2YgdGhlIGRhdGEgdGhhdCB5b3Ug
Y2hvb3NlIHRvIHN0b3JlCiBpbiBpdC4KCg4KBwQABAACAQESAzoECQoOCgcEAAQAAgECEgM6
DA0KjgIKBgQABAACAhIDQgQNGv4BIEFsbCBpbmZvcm1hdGlvbiBpcyByZXR1cm5lZC4KCiBB
dXRob3JpemF0aW9uIGZvciBbRlVMTF1bZ29vZ2xlLmNsb3VkLnRhc2tzLnYyYmV0YTIuVGFz
ay5WaWV3LkZVTExdCiByZXF1aXJlcyBgY2xvdWR0YXNrcy50YXNrcy5mdWxsVmlld2AgW0dv
b2dsZQogSUFNXShodHRwczovL2Nsb3VkLmdvb2dsZS5jb20vaWFtLykgcGVybWlzc2lvbiBv
biB0aGUKIFtRdWV1ZV1bZ29vZ2xlLmNsb3VkLnRhc2tzLnYyYmV0YTIuUXVldWVdIHJlc291
cmNlLgoKDgoHBAAEAAICARIDQgQICg4KBwQABAACAgISA0ILDAqWCAoEBAACABIDWgISGogI
IE9wdGlvbmFsbHkgY2FsbGVyLXNwZWNpZmllZCBpbgogW0NyZWF0ZVRhc2tdW2dvb2dsZS5j
bG91ZC50YXNrcy52MmJldGEyLkNsb3VkVGFza3MuQ3JlYXRlVGFza10uCgogVGhlIHRhc2sg
bmFtZS4KCiBUaGUgdGFzayBuYW1lIG11c3QgaGF2ZSB0aGUgZm9sbG93aW5nIGZvcm1hdDoK
IGBwcm9qZWN0cy9QUk9KRUNUX0lEL2xvY2F0aW9ucy9MT0NBVElPTl9JRC9xdWV1ZXMvUVVF
VUVfSUQvdGFza3MvVEFTS19JRGAKCiAqIGBQUk9KRUNUX0lEYCBjYW4gY29udGFpbiBsZXR0
ZXJzIChbQS1aYS16XSksIG51bWJlcnMgKFswLTldKSwKICAgIGh5cGhlbnMgKC0pLCBjb2xv
bnMgKDopLCBvciBwZXJpb2RzICguKS4KICAgIEZvciBtb3JlIGluZm9ybWF0aW9uLCBzZWUK
ICAgIFtJZGVudGlmeWluZwogICAgcHJvamVjdHNdKGh0dHBzOi8vY2xvdWQuZ29vZ2xlLmNv
bS9yZXNvdXJjZS1tYW5hZ2VyL2RvY3MvY3JlYXRpbmctbWFuYWdpbmctcHJvamVjdHMjaWRl
bnRpZnlpbmdfcHJvamVjdHMpCiAqIGBMT0NBVElPTl9JRGAgaXMgdGhlIGNhbm9uaWNhbCBJ
RCBmb3IgdGhlIHRhc2sncyBsb2NhdGlvbi4KICAgIFRoZSBsaXN0IG9mIGF2YWlsYWJsZSBs
b2NhdGlvbnMgY2FuIGJlIG9idGFpbmVkIGJ5IGNhbGxpbmcKICAgIFtMaXN0TG9jYXRpb25z
XVtnb29nbGUuY2xvdWQubG9jYXRpb24uTG9jYXRpb25zLkxpc3RMb2NhdGlvbnNdLgogICAg
Rm9yIG1vcmUgaW5mb3JtYXRpb24sIHNlZSBodHRwczovL2Nsb3VkLmdvb2dsZS5jb20vYWJv
dXQvbG9jYXRpb25zLy4KICogYFFVRVVFX0lEYCBjYW4gY29udGFpbiBsZXR0ZXJzIChbQS1a
YS16XSksIG51bWJlcnMgKFswLTldKSwgb3IKICAgaHlwaGVucyAoLSkuIFRoZSBtYXhpbXVt
IGxlbmd0aCBpcyAxMDAgY2hhcmFjdGVycy4KICogYFRBU0tfSURgIGNhbiBjb250YWluIG9u
bHkgbGV0dGVycyAoW0EtWmEtel0pLCBudW1iZXJzIChbMC05XSksCiAgIGh5cGhlbnMgKC0p
LCBvciB1bmRlcnNjb3JlcyAoXykuIFRoZSBtYXhpbXVtIGxlbmd0aCBpcyA1MDAgY2hhcmFj
dGVycy4KCgwKBQQAAgAFEgNaAggKDAoFBAACAAESA1oJDQoMCgUEAAIAAxIDWhARCqcBCgQE
AAgAEgRgAnkDGpgBIFJlcXVpcmVkLgoKIFRoZSB0YXNrJ3MgcGF5bG9hZCBpcyB1c2VkIGJ5
IHRoZSB0YXNrJ3MgdGFyZ2V0IHRvIHByb2Nlc3MgdGhlIHRhc2suCiBBIHBheWxvYWQgaXMg
dmFsaWQgb25seSBpZiBpdCBpcyBjb21wYXRpYmxlIHdpdGggdGhlIHF1ZXVlJ3MgdGFyZ2V0
LgoKDAoFBAAIAAESA2AIFAq+AgoEBAACARIDaQQ1GrACIEFwcCBFbmdpbmUgSFRUUCByZXF1
ZXN0IHRoYXQgaXMgc2VudCB0byB0aGUgdGFzaydzIHRhcmdldC4gQ2FuCiBiZSBzZXQgb25s
eSBpZgogW2FwcF9lbmdpbmVfaHR0cF90YXJnZXRdW2dvb2dsZS5jbG91ZC50YXNrcy52MmJl
dGEyLlF1ZXVlLmFwcF9lbmdpbmVfaHR0cF90YXJnZXRdCiBpcyBzZXQgb24gdGhlIHF1ZXVl
LgoKIEFuIEFwcCBFbmdpbmUgdGFzayBpcyBhIHRhc2sgdGhhdCBoYXMKIFtBcHBFbmdpbmVI
dHRwUmVxdWVzdF1bZ29vZ2xlLmNsb3VkLnRhc2tzLnYyYmV0YTIuQXBwRW5naW5lSHR0cFJl
cXVlc3RdCiBzZXQuCgoMCgUEAAIBBhIDaQQYCgwKBQQAAgEBEgNpGTAKDAoFBAACAQMSA2kz
NAqnAgoEBAACAhIDcgQhGpkCIFtMZWFzZVRhc2tzXVtnb29nbGUuY2xvdWQudGFza3MudjJi
ZXRhMi5DbG91ZFRhc2tzLkxlYXNlVGFza3NdIHRvIHByb2Nlc3MKIHRoZSB0YXNrLiBDYW4g
YmUgc2V0IG9ubHkgaWYKIFtwdWxsX3RhcmdldF1bZ29vZ2xlLmNsb3VkLnRhc2tzLnYyYmV0
YTIuUXVldWUucHVsbF90YXJnZXRdIGlzIHNldCBvbiB0aGUKIHF1ZXVlLgoKIEEgcHVsbCB0
YXNrIGlzIGEgdGFzayB0aGF0IGhhcwogW1B1bGxNZXNzYWdlXVtnb29nbGUuY2xvdWQudGFz
a3MudjJiZXRhMi5QdWxsTWVzc2FnZV0gc2V0LgoKDAoFBAACAgYSA3IEDwoMCgUEAAICARID
chAcCgwKBQQAAgIDEgNyHyAKnQEKBAQAAgMSA3gEIhqPASBIVFRQIHJlcXVlc3QgdGhhdCBp
cyBzZW50IHRvIHRoZSB0YXNrJ3MgdGFyZ2V0LgoKIEFuIEhUVFAgdGFzayBpcyBhIHRhc2sg
dGhhdCBoYXMKIFtIdHRwUmVxdWVzdF1bZ29vZ2xlLmNsb3VkLnRhc2tzLnYyYmV0YTIuSHR0
cFJlcXVlc3RdIHNldC4KCgwKBQQAAgMGEgN4BA8KDAoFBAACAwESA3gQHAoMCgUEAAIDAxID
eB8hCvYDCgQEAAIEEgSGAQIuGucDIFRoZSB0aW1lIHdoZW4gdGhlIHRhc2sgaXMgc2NoZWR1
bGVkIHRvIGJlIGF0dGVtcHRlZC4KCiBGb3IgQXBwIEVuZ2luZSBxdWV1ZXMsIHRoaXMgaXMg
d2hlbiB0aGUgdGFzayB3aWxsIGJlIGF0dGVtcHRlZCBvciByZXRyaWVkLgoKIEZvciBwdWxs
IHF1ZXVlcywgdGhpcyBpcyB0aGUgdGltZSB3aGVuIHRoZSB0YXNrIGlzIGF2YWlsYWJsZSB0
bwogYmUgbGVhc2VkOyBpZiBhIHRhc2sgaXMgY3VycmVudGx5IGxlYXNlZCwgdGhpcyBpcyB0
aGUgdGltZSB3aGVuCiB0aGUgY3VycmVudCBsZWFzZSBleHBpcmVzLCB0aGF0IGlzLCB0aGUg
dGltZSB0aGF0IHRoZSB0YXNrIHdhcwogbGVhc2VkIHBsdXMgdGhlCiBbbGVhc2VfZHVyYXRp
b25dW2dvb2dsZS5jbG91ZC50YXNrcy52MmJldGEyLkxlYXNlVGFza3NSZXF1ZXN0LmxlYXNl
X2R1cmF0aW9uXS4KCiBgc2NoZWR1bGVfdGltZWAgd2lsbCBiZSB0cnVuY2F0ZWQgdG8gdGhl
IG5lYXJlc3QgbWljcm9zZWNvbmQuCgoNCgUEAAIEBhIEhgECGwoNCgUEAAIEARIEhgEcKQoN
CgUEAAIEAxIEhgEsLQp5CgQEAAIFEgSLAQIsGmsgT3V0cHV0IG9ubHkuIFRoZSB0aW1lIHRo
YXQgdGhlIHRhc2sgd2FzIGNyZWF0ZWQuCgogYGNyZWF0ZV90aW1lYCB3aWxsIGJlIHRydW5j
YXRlZCB0byB0aGUgbmVhcmVzdCBzZWNvbmQuCgoNCgUEAAIFBhIEiwECGwoNCgUEAAIFARIE
iwEcJwoNCgUEAAIFAxIEiwEqKwotCgQEAAIGEgSOAQIYGh8gT3V0cHV0IG9ubHkuIFRoZSB0
YXNrIHN0YXR1cy4KCg0KBQQAAgYGEgSOAQIMCg0KBQQAAgYBEgSOAQ0TCg0KBQQAAgYDEgSO
ARYXCn8KBAQAAgcSBJIBAhAacSBPdXRwdXQgb25seS4gVGhlIHZpZXcgc3BlY2lmaWVzIHdo
aWNoIHN1YnNldCBvZiB0aGUKIFtUYXNrXVtnb29nbGUuY2xvdWQudGFza3MudjJiZXRhMi5U
YXNrXSBoYXMgYmVlbiByZXR1cm5lZC4KCg0KBQQAAgcGEgSSAQIGCg0KBQQAAgcBEgSSAQcL
Cg0KBQQAAgcDEgSSAQ4PCiMKAgQBEgaWAQC0AQEaFSBTdGF0dXMgb2YgdGhlIHRhc2suCgoL
CgMEAQESBJYBCBIKnAEKBAQBAgASBJsBAiMajQEgT3V0cHV0IG9ubHkuIFRoZSBudW1iZXIg
b2YgYXR0ZW1wdHMgZGlzcGF0Y2hlZC4KCiBUaGlzIGNvdW50IGluY2x1ZGVzIGF0dGVtcHRz
IHdoaWNoIGhhdmUgYmVlbiBkaXNwYXRjaGVkIGJ1dCBoYXZlbid0CiByZWNlaXZlZCBhIHJl
c3BvbnNlLgoKDQoFBAECAAUSBJsBAgcKDQoFBAECAAESBJsBCB4KDQoFBAECAAMSBJsBISIK
rgEKBAQBAgESBKEBAiManwEgT3V0cHV0IG9ubHkuIFRoZSBudW1iZXIgb2YgYXR0ZW1wdHMg
d2hpY2ggaGF2ZSByZWNlaXZlZCBhIHJlc3BvbnNlLgoKIFRoaXMgZmllbGQgaXMgbm90IGNh
bGN1bGF0ZWQgZm9yIFtwdWxsCiB0YXNrc11bZ29vZ2xlLmNsb3VkLnRhc2tzLnYyYmV0YTIu
UHVsbE1lc3NhZ2VdLgoKDQoFBAECAQUSBKEBAgcKDQoFBAECAQESBKEBCB4KDQoFBAECAQMS
BKEBISIK7wIKBAQBAgISBK0BAika4AIgT3V0cHV0IG9ubHkuIFRoZSBzdGF0dXMgb2YgdGhl
IHRhc2sncyBmaXJzdCBhdHRlbXB0LgoKIE9ubHkKIFtkaXNwYXRjaF90aW1lXVtnb29nbGUu
Y2xvdWQudGFza3MudjJiZXRhMi5BdHRlbXB0U3RhdHVzLmRpc3BhdGNoX3RpbWVdCiB3aWxs
IGJlIHNldC4gVGhlIG90aGVyCiBbQXR0ZW1wdFN0YXR1c11bZ29vZ2xlLmNsb3VkLnRhc2tz
LnYyYmV0YTIuQXR0ZW1wdFN0YXR1c10gaW5mb3JtYXRpb24gaXMKIG5vdCByZXRhaW5lZCBi
eSBDbG91ZCBUYXNrcy4KCiBUaGlzIGZpZWxkIGlzIG5vdCBjYWxjdWxhdGVkIGZvciBbcHVs
bAogdGFza3NdW2dvb2dsZS5jbG91ZC50YXNrcy52MmJldGEyLlB1bGxNZXNzYWdlXS4KCg0K
BQQBAgIGEgStAQIPCg0KBQQBAgIBEgStARAkCg0KBQQBAgIDEgStAScoCp4BCgQEAQIDEgSz
AQIoGo8BIE91dHB1dCBvbmx5LiBUaGUgc3RhdHVzIG9mIHRoZSB0YXNrJ3MgbGFzdCBhdHRl
bXB0LgoKIFRoaXMgZmllbGQgaXMgbm90IGNhbGN1bGF0ZWQgZm9yIFtwdWxsCiB0YXNrc11b
Z29vZ2xlLmNsb3VkLnRhc2tzLnYyYmV0YTIuUHVsbE1lc3NhZ2VdLgoKDQoFBAECAwYSBLMB
Ag8KDQoFBAECAwESBLMBECMKDQoFBAECAwMSBLMBJicKLQoCBAISBrcBAMwBARofIFRoZSBz
dGF0dXMgb2YgYSB0YXNrIGF0dGVtcHQuCgoLCgMEAgESBLcBCBUKhgEKBAQCAgASBLsBAi4a
eCBPdXRwdXQgb25seS4gVGhlIHRpbWUgdGhhdCB0aGlzIGF0dGVtcHQgd2FzIHNjaGVkdWxl
ZC4KCiBgc2NoZWR1bGVfdGltZWAgd2lsbCBiZSB0cnVuY2F0ZWQgdG8gdGhlIG5lYXJlc3Qg
bWljcm9zZWNvbmQuCgoNCgUEAgIABhIEuwECGwoNCgUEAgIAARIEuwEcKQoNCgUEAgIAAxIE
uwEsLQqHAQoEBAICARIEwAECLhp5IE91dHB1dCBvbmx5LiBUaGUgdGltZSB0aGF0IHRoaXMg
YXR0ZW1wdCB3YXMgZGlzcGF0Y2hlZC4KCiBgZGlzcGF0Y2hfdGltZWAgd2lsbCBiZSB0cnVu
Y2F0ZWQgdG8gdGhlIG5lYXJlc3QgbWljcm9zZWNvbmQuCgoNCgUEAgIBBhIEwAECGwoNCgUE
AgIBARIEwAEcKQoNCgUEAgIBAxIEwAEsLQqPAQoEBAICAhIExQECLhqAASBPdXRwdXQgb25s
eS4gVGhlIHRpbWUgdGhhdCB0aGlzIGF0dGVtcHQgcmVzcG9uc2Ugd2FzIHJlY2VpdmVkLgoK
IGByZXNwb25zZV90aW1lYCB3aWxsIGJlIHRydW5jYXRlZCB0byB0aGUgbmVhcmVzdCBtaWNy
b3NlY29uZC4KCg0KBQQCAgIGEgTFAQIbCg0KBQQCAgIBEgTFARwpCg0KBQQCAgIDEgTFASwt
CrYBCgQEAgIDEgTLAQIoGqcBIE91dHB1dCBvbmx5LiBUaGUgcmVzcG9uc2UgZnJvbSB0aGUg
dGFyZ2V0IGZvciB0aGlzIGF0dGVtcHQuCgogSWYgdGhlIHRhc2sgaGFzIG5vdCBiZWVuIGF0
dGVtcHRlZCBvciB0aGUgdGFzayBpcyBjdXJyZW50bHkgcnVubmluZwogdGhlbiB0aGUgcmVz
cG9uc2Ugc3RhdHVzIGlzIHVuc2V0LgoKDQoFBAICAwYSBMsBAhMKDQoFBAICAwESBMsBFCMK
DQoFBAICAwMSBMsBJidiBnByb3RvMw==
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Tasks::V2beta2::Task::Task ===
    # Fields for Task
    # Field: name Type: 9 ()
    # Field: app_engine_http_request Type: 11 (.google.cloud.tasks.v2beta2.AppEngineHttpRequest)
    # Field: pull_message Type: 11 (.google.cloud.tasks.v2beta2.PullMessage)
    # Field: http_request Type: 11 (.google.cloud.tasks.v2beta2.HttpRequest)
    # Field: schedule_time Type: 11 (.google.protobuf.Timestamp)
    # Field: create_time Type: 11 (.google.protobuf.Timestamp)
    # Field: status Type: 11 (.google.cloud.tasks.v2beta2.TaskStatus)
    # Field: view Type: 14 (.google.cloud.tasks.v2beta2.Task.View)

# Enum: Task::View
our $Task_VIEW_UNSPECIFIED = 0;
our $Task_BASIC = 1;
our $Task_FULL = 2;

# === Message: Google::Cloud::Tasks::V2beta2::Task::TaskStatus ===
    # Fields for TaskStatus
    # Field: attempt_dispatch_count Type: 5 ()
    # Field: attempt_response_count Type: 5 ()
    # Field: first_attempt_status Type: 11 (.google.cloud.tasks.v2beta2.AttemptStatus)
    # Field: last_attempt_status Type: 11 (.google.cloud.tasks.v2beta2.AttemptStatus)

# === Message: Google::Cloud::Tasks::V2beta2::Task::AttemptStatus ===
    # Fields for AttemptStatus
    # Field: schedule_time Type: 11 (.google.protobuf.Timestamp)
    # Field: dispatch_time Type: 11 (.google.protobuf.Timestamp)
    # Field: response_time Type: 11 (.google.protobuf.Timestamp)
    # Field: response_status Type: 11 (.google.rpc.Status)

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Tasks::V2beta2::Task - Compiled Protocol Buffers messages for google/cloud/tasks/v2beta2/task.proto

=head1 SYNOPSIS

    use Google::Cloud::Tasks::V2beta2::Task;

    my $msg = Google::Cloud::Tasks::V2beta2::Task::Task->new({
        name => $name,
        app_engine_http_request => $app_engine_http_request,
        pull_message => $pull_message,
        http_request => $http_request,
    });

    # Read or update a field
    my $val = $msg->name();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Tasks::V2beta2::Task::Task->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/tasks/v2beta2/task.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Tasks::V2beta2::Task::Task

A unit of scheduled work.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Optionally caller-specified in
[CreateTask][google.cloud.tasks.v2beta2.CloudTasks.CreateTask].

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

Type: C<Message> (L<Google::Cloud::Tasks::V2beta2::Target::AppEngineHttpRequest>)

App Engine HTTP request that is sent to the task's target. Can
be set only if
[app_engine_http_target][google.cloud.tasks.v2beta2.Queue.app_engine_http_target]
is set on the queue.

An App Engine task is a task that has
[AppEngineHttpRequest][google.cloud.tasks.v2beta2.AppEngineHttpRequest]
set.

=item * C<< $msg->pull_message() >> / C<< $msg->pull_message($value) >>

Type: C<Message> (L<Google::Cloud::Tasks::V2beta2::Target::PullMessage>)

[LeaseTasks][google.cloud.tasks.v2beta2.CloudTasks.LeaseTasks] to process
the task. Can be set only if
[pull_target][google.cloud.tasks.v2beta2.Queue.pull_target] is set on the
queue.

A pull task is a task that has
[PullMessage][google.cloud.tasks.v2beta2.PullMessage] set.

=item * C<< $msg->http_request() >> / C<< $msg->http_request($value) >>

Type: C<Message> (L<Google::Cloud::Tasks::V2beta2::Target::HttpRequest>)

HTTP request that is sent to the task's target.

An HTTP task is a task that has
[HttpRequest][google.cloud.tasks.v2beta2.HttpRequest] set.

=item * C<< $msg->schedule_time() >> / C<< $msg->schedule_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

The time when the task is scheduled to be attempted.

For App Engine queues, this is when the task will be attempted or retried.

For pull queues, this is the time when the task is available to
be leased; if a task is currently leased, this is the time when
the current lease expires, that is, the time that the task was
leased plus the
[lease_duration][google.cloud.tasks.v2beta2.LeaseTasksRequest.lease_duration].

`schedule_time` will be truncated to the nearest microsecond.

=item * C<< $msg->create_time() >> / C<< $msg->create_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Output only. The time that the task was created.

`create_time` will be truncated to the nearest second.

=item * C<< $msg->status() >> / C<< $msg->status($value) >>

Type: C<Message> (L<Google::Cloud::Tasks::V2beta2::Task::TaskStatus>)

Output only. The task status.

=item * C<< $msg->view() >> / C<< $msg->view($value) >>

Type: C<Enum> (L<Google::Cloud::Tasks::V2beta2::Task::View>)

Output only. The view specifies which subset of the
[Task][google.cloud.tasks.v2beta2.Task] has been returned.

=back

=head3 Enum: Task::View

=over 4

=item * C<VIEW_UNSPECIFIED> => C<0>

=item * C<BASIC> => C<1>

=item * C<FULL> => C<2>

=back

=head2 Google::Cloud::Tasks::V2beta2::Task::TaskStatus

Status of the task.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->attempt_dispatch_count() >> / C<< $msg->attempt_dispatch_count($value) >>

Type: C<Int32>

Output only. The number of attempts dispatched.

This count includes attempts which have been dispatched but haven't
received a response.

=item * C<< $msg->attempt_response_count() >> / C<< $msg->attempt_response_count($value) >>

Type: C<Int32>

Output only. The number of attempts which have received a response.

This field is not calculated for [pull
tasks][google.cloud.tasks.v2beta2.PullMessage].

=item * C<< $msg->first_attempt_status() >> / C<< $msg->first_attempt_status($value) >>

Type: C<Message> (L<Google::Cloud::Tasks::V2beta2::Task::AttemptStatus>)

Output only. The status of the task's first attempt.

Only
[dispatch_time][google.cloud.tasks.v2beta2.AttemptStatus.dispatch_time]
will be set. The other
[AttemptStatus][google.cloud.tasks.v2beta2.AttemptStatus] information is
not retained by Cloud Tasks.

This field is not calculated for [pull
tasks][google.cloud.tasks.v2beta2.PullMessage].

=item * C<< $msg->last_attempt_status() >> / C<< $msg->last_attempt_status($value) >>

Type: C<Message> (L<Google::Cloud::Tasks::V2beta2::Task::AttemptStatus>)

Output only. The status of the task's last attempt.

This field is not calculated for [pull
tasks][google.cloud.tasks.v2beta2.PullMessage].

=back

=head2 Google::Cloud::Tasks::V2beta2::Task::AttemptStatus

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

Output only. The response from the target for this attempt.

If the task has not been attempted or the task is currently running
then the response status is unset.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Tasks::V2beta2::Task::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
