package Google::Cloud::Tasks::V2beta3::Task;

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
    eval { require Google::Cloud::Tasks::V2beta3::Queue };
    eval { require Google::Cloud::Tasks::V2beta3::Target };
    eval { require Google::Protobuf::Duration };
    eval { require Google::Protobuf::Timestamp };
    eval { require Google::Rpc::Status };
    my $descriptor_b64 = <<'EOF';
CiVnb29nbGUvY2xvdWQvdGFza3MvdjJiZXRhMy90YXNrLnByb3RvEhpnb29nbGUuY2xvdWQu
dGFza3MudjJiZXRhMxofZ29vZ2xlL2FwaS9maWVsZF9iZWhhdmlvci5wcm90bxoZZ29vZ2xl
L2FwaS9yZXNvdXJjZS5wcm90bxomZ29vZ2xlL2Nsb3VkL3Rhc2tzL3YyYmV0YTMvcXVldWUu
cHJvdG8aJ2dvb2dsZS9jbG91ZC90YXNrcy92MmJldGEzL3RhcmdldC5wcm90bxoeZ29vZ2xl
L3Byb3RvYnVmL2R1cmF0aW9uLnByb3RvGh9nb29nbGUvcHJvdG9idWYvdGltZXN0YW1wLnBy
b3RvGhdnb29nbGUvcnBjL3N0YXR1cy5wcm90byKACAoEVGFzaxISCgRuYW1lGAEgASgJUgRu
YW1lEmkKF2FwcF9lbmdpbmVfaHR0cF9yZXF1ZXN0GAMgASgLMjAuZ29vZ2xlLmNsb3VkLnRh
c2tzLnYyYmV0YTMuQXBwRW5naW5lSHR0cFJlcXVlc3RIAFIUYXBwRW5naW5lSHR0cFJlcXVl
c3QSTAoMaHR0cF9yZXF1ZXN0GAsgASgLMicuZ29vZ2xlLmNsb3VkLnRhc2tzLnYyYmV0YTMu
SHR0cFJlcXVlc3RIAFILaHR0cFJlcXVlc3QSTAoMcHVsbF9tZXNzYWdlGA0gASgLMicuZ29v
Z2xlLmNsb3VkLnRhc2tzLnYyYmV0YTMuUHVsbE1lc3NhZ2VIAFILcHVsbE1lc3NhZ2USPwoN
c2NoZWR1bGVfdGltZRgEIAEoCzIaLmdvb2dsZS5wcm90b2J1Zi5UaW1lc3RhbXBSDHNjaGVk
dWxlVGltZRI7CgtjcmVhdGVfdGltZRgFIAEoCzIaLmdvb2dsZS5wcm90b2J1Zi5UaW1lc3Rh
bXBSCmNyZWF0ZVRpbWUSRgoRZGlzcGF0Y2hfZGVhZGxpbmUYDCABKAsyGS5nb29nbGUucHJv
dG9idWYuRHVyYXRpb25SEGRpc3BhdGNoRGVhZGxpbmUSJQoOZGlzcGF0Y2hfY291bnQYBiAB
KAVSDWRpc3BhdGNoQ291bnQSJQoOcmVzcG9uc2VfY291bnQYByABKAVSDXJlc3BvbnNlQ291
bnQSSAoNZmlyc3RfYXR0ZW1wdBgIIAEoCzIjLmdvb2dsZS5jbG91ZC50YXNrcy52MmJldGEz
LkF0dGVtcHRSDGZpcnN0QXR0ZW1wdBJGCgxsYXN0X2F0dGVtcHQYCSABKAsyIy5nb29nbGUu
Y2xvdWQudGFza3MudjJiZXRhMy5BdHRlbXB0UgtsYXN0QXR0ZW1wdBI5CgR2aWV3GAogASgO
MiUuZ29vZ2xlLmNsb3VkLnRhc2tzLnYyYmV0YTMuVGFzay5WaWV3UgR2aWV3Ek8KDHJldHJ5
X2NvbmZpZxgOIAEoCzInLmdvb2dsZS5jbG91ZC50YXNrcy52MmJldGEzLlJldHJ5Q29uZmln
QgPgQQFSC3JldHJ5Q29uZmlnIjEKBFZpZXcSFAoQVklFV19VTlNQRUNJRklFRBAAEgkKBUJB
U0lDEAESCAoERlVMTBACOmjqQWUKHmNsb3VkdGFza3MuZ29vZ2xlYXBpcy5jb20vVGFzaxJD
cHJvamVjdHMve3Byb2plY3R9L2xvY2F0aW9ucy97bG9jYXRpb259L3F1ZXVlcy97cXVldWV9
L3Rhc2tzL3t0YXNrfUIOCgxwYXlsb2FkX3R5cGUiiQIKB0F0dGVtcHQSPwoNc2NoZWR1bGVf
dGltZRgBIAEoCzIaLmdvb2dsZS5wcm90b2J1Zi5UaW1lc3RhbXBSDHNjaGVkdWxlVGltZRI/
Cg1kaXNwYXRjaF90aW1lGAIgASgLMhouZ29vZ2xlLnByb3RvYnVmLlRpbWVzdGFtcFIMZGlz
cGF0Y2hUaW1lEj8KDXJlc3BvbnNlX3RpbWUYAyABKAsyGi5nb29nbGUucHJvdG9idWYuVGlt
ZXN0YW1wUgxyZXNwb25zZVRpbWUSOwoPcmVzcG9uc2Vfc3RhdHVzGAQgASgLMhIuZ29vZ2xl
LnJwYy5TdGF0dXNSDnJlc3BvbnNlU3RhdHVzQnIKHmNvbS5nb29nbGUuY2xvdWQudGFza3Mu
djJiZXRhM0IJVGFza1Byb3RvUAFaQ2Nsb3VkLmdvb2dsZS5jb20vZ28vY2xvdWR0YXNrcy9h
cGl2MmJldGEzL2Nsb3VkdGFza3NwYjtjbG91ZHRhc2tzcGJK3EMKBxIFDgDdAQEKvAQKAQwS
Aw4AEjKxBCBDb3B5cmlnaHQgMjAyNiBHb29nbGUgTExDCgogTGljZW5zZWQgdW5kZXIgdGhl
IEFwYWNoZSBMaWNlbnNlLCBWZXJzaW9uIDIuMCAodGhlICJMaWNlbnNlIik7CiB5b3UgbWF5
IG5vdCB1c2UgdGhpcyBmaWxlIGV4Y2VwdCBpbiBjb21wbGlhbmNlIHdpdGggdGhlIExpY2Vu
c2UuCiBZb3UgbWF5IG9idGFpbiBhIGNvcHkgb2YgdGhlIExpY2Vuc2UgYXQKCiAgICAgaHR0
cDovL3d3dy5hcGFjaGUub3JnL2xpY2Vuc2VzL0xJQ0VOU0UtMi4wCgogVW5sZXNzIHJlcXVp
cmVkIGJ5IGFwcGxpY2FibGUgbGF3IG9yIGFncmVlZCB0byBpbiB3cml0aW5nLCBzb2Z0d2Fy
ZQogZGlzdHJpYnV0ZWQgdW5kZXIgdGhlIExpY2Vuc2UgaXMgZGlzdHJpYnV0ZWQgb24gYW4g
IkFTIElTIiBCQVNJUywKIFdJVEhPVVQgV0FSUkFOVElFUyBPUiBDT05ESVRJT05TIE9GIEFO
WSBLSU5ELCBlaXRoZXIgZXhwcmVzcyBvciBpbXBsaWVkLgogU2VlIHRoZSBMaWNlbnNlIGZv
ciB0aGUgc3BlY2lmaWMgbGFuZ3VhZ2UgZ292ZXJuaW5nIHBlcm1pc3Npb25zIGFuZAogbGlt
aXRhdGlvbnMgdW5kZXIgdGhlIExpY2Vuc2UuCgoICgECEgMQACMKCQoCAwASAxIAKQoJCgID
ARIDEwAjCgkKAgMCEgMUADAKCQoCAwMSAxUAMQoJCgIDBBIDFgAoCgkKAgMFEgMXACkKCQoC
AwYSAxgAIQoICgEIEgMaAFoKCQoCCAsSAxoAWgoICgEIEgMbACIKCQoCCAoSAxsAIgoICgEI
EgMcACoKCQoCCAgSAxwAKgoICgEIEgMdADcKCQoCCAESAx0ANwooCgIEABIFIADFAQEaGyBB
IHVuaXQgb2Ygc2NoZWR1bGVkIHdvcmsuCgoKCgMEAAESAyAIDAoLCgMEAAcSBCECJAQKDQoF
BAAHnQgSBCECJAQK3AIKBAQABAASBC4CRAMazQIgVGhlIHZpZXcgc3BlY2lmaWVzIGEgc3Vi
c2V0IG9mIFtUYXNrXVtnb29nbGUuY2xvdWQudGFza3MudjJiZXRhMy5UYXNrXQogZGF0YS4K
CiBXaGVuIGEgdGFzayBpcyByZXR1cm5lZCBpbiBhIHJlc3BvbnNlLCBub3QgYWxsCiBpbmZv
cm1hdGlvbiBpcyByZXRyaWV2ZWQgYnkgZGVmYXVsdCBiZWNhdXNlIHNvbWUgZGF0YSwgc3Vj
aCBhcwogcGF5bG9hZHMsIG1pZ2h0IGJlIGRlc2lyYWJsZSB0byByZXR1cm4gb25seSB3aGVu
IG5lZWRlZCBiZWNhdXNlCiBvZiBpdHMgbGFyZ2Ugc2l6ZSBvciBiZWNhdXNlIG9mIHRoZSBz
ZW5zaXRpdml0eSBvZiBkYXRhIHRoYXQgaXQKIGNvbnRhaW5zLgoKDAoFBAAEAAESAy4HCwow
CgYEAAQAAgASAzAEGRohIFVuc3BlY2lmaWVkLiBEZWZhdWx0cyB0byBCQVNJQy4KCg4KBwQA
BAACAAESAzAEFAoOCgcEAAQAAgACEgMwFxgK8gIKBgQABAACARIDOwQOGuICIFRoZSBiYXNp
YyB2aWV3IG9taXRzIGZpZWxkcyB3aGljaCBjYW4gYmUgbGFyZ2Ugb3IgY2FuIGNvbnRhaW4K
IHNlbnNpdGl2ZSBkYXRhLgoKIFRoaXMgdmlldyBkb2VzIG5vdCBpbmNsdWRlIHRoZQogW2Jv
ZHkgaW4KIEFwcEVuZ2luZUh0dHBSZXF1ZXN0XVtnb29nbGUuY2xvdWQudGFza3MudjJiZXRh
My5BcHBFbmdpbmVIdHRwUmVxdWVzdC5ib2R5XS4KIEJvZGllcyBhcmUgZGVzaXJhYmxlIHRv
IHJldHVybiBvbmx5IHdoZW4gbmVlZGVkLCBiZWNhdXNlIHRoZXkKIGNhbiBiZSBsYXJnZSBh
bmQgYmVjYXVzZSBvZiB0aGUgc2Vuc2l0aXZpdHkgb2YgdGhlIGRhdGEgdGhhdCB5b3UKIGNo
b29zZSB0byBzdG9yZSBpbiBpdC4KCg4KBwQABAACAQESAzsECQoOCgcEAAQAAgECEgM7DA0K
jgIKBgQABAACAhIDQwQNGv4BIEFsbCBpbmZvcm1hdGlvbiBpcyByZXR1cm5lZC4KCiBBdXRo
b3JpemF0aW9uIGZvciBbRlVMTF1bZ29vZ2xlLmNsb3VkLnRhc2tzLnYyYmV0YTMuVGFzay5W
aWV3LkZVTExdCiByZXF1aXJlcyBgY2xvdWR0YXNrcy50YXNrcy5mdWxsVmlld2AgW0dvb2ds
ZQogSUFNXShodHRwczovL2Nsb3VkLmdvb2dsZS5jb20vaWFtLykgcGVybWlzc2lvbiBvbiB0
aGUKIFtRdWV1ZV1bZ29vZ2xlLmNsb3VkLnRhc2tzLnYyYmV0YTMuUXVldWVdIHJlc291cmNl
LgoKDgoHBAAEAAICARIDQwQICg4KBwQABAACAgISA0MLDAqWCAoEBAACABIDWwISGogIIE9w
dGlvbmFsbHkgY2FsbGVyLXNwZWNpZmllZCBpbgogW0NyZWF0ZVRhc2tdW2dvb2dsZS5jbG91
ZC50YXNrcy52MmJldGEzLkNsb3VkVGFza3MuQ3JlYXRlVGFza10uCgogVGhlIHRhc2sgbmFt
ZS4KCiBUaGUgdGFzayBuYW1lIG11c3QgaGF2ZSB0aGUgZm9sbG93aW5nIGZvcm1hdDoKIGBw
cm9qZWN0cy9QUk9KRUNUX0lEL2xvY2F0aW9ucy9MT0NBVElPTl9JRC9xdWV1ZXMvUVVFVUVf
SUQvdGFza3MvVEFTS19JRGAKCiAqIGBQUk9KRUNUX0lEYCBjYW4gY29udGFpbiBsZXR0ZXJz
IChbQS1aYS16XSksIG51bWJlcnMgKFswLTldKSwKICAgIGh5cGhlbnMgKC0pLCBjb2xvbnMg
KDopLCBvciBwZXJpb2RzICguKS4KICAgIEZvciBtb3JlIGluZm9ybWF0aW9uLCBzZWUKICAg
IFtJZGVudGlmeWluZwogICAgcHJvamVjdHNdKGh0dHBzOi8vY2xvdWQuZ29vZ2xlLmNvbS9y
ZXNvdXJjZS1tYW5hZ2VyL2RvY3MvY3JlYXRpbmctbWFuYWdpbmctcHJvamVjdHMjaWRlbnRp
ZnlpbmdfcHJvamVjdHMpCiAqIGBMT0NBVElPTl9JRGAgaXMgdGhlIGNhbm9uaWNhbCBJRCBm
b3IgdGhlIHRhc2sncyBsb2NhdGlvbi4KICAgIFRoZSBsaXN0IG9mIGF2YWlsYWJsZSBsb2Nh
dGlvbnMgY2FuIGJlIG9idGFpbmVkIGJ5IGNhbGxpbmcKICAgIFtMaXN0TG9jYXRpb25zXVtn
b29nbGUuY2xvdWQubG9jYXRpb24uTG9jYXRpb25zLkxpc3RMb2NhdGlvbnNdLgogICAgRm9y
IG1vcmUgaW5mb3JtYXRpb24sIHNlZSBodHRwczovL2Nsb3VkLmdvb2dsZS5jb20vYWJvdXQv
bG9jYXRpb25zLy4KICogYFFVRVVFX0lEYCBjYW4gY29udGFpbiBsZXR0ZXJzIChbQS1aYS16
XSksIG51bWJlcnMgKFswLTldKSwgb3IKICAgaHlwaGVucyAoLSkuIFRoZSBtYXhpbXVtIGxl
bmd0aCBpcyAxMDAgY2hhcmFjdGVycy4KICogYFRBU0tfSURgIGNhbiBjb250YWluIG9ubHkg
bGV0dGVycyAoW0EtWmEtel0pLCBudW1iZXJzIChbMC05XSksCiAgIGh5cGhlbnMgKC0pLCBv
ciB1bmRlcnNjb3JlcyAoXykuIFRoZSBtYXhpbXVtIGxlbmd0aCBpcyA1MDAgY2hhcmFjdGVy
cy4KCgwKBQQAAgAFEgNbAggKDAoFBAACAAESA1sJDQoMCgUEAAIAAxIDWxARCjwKBAQACAAS
BF4CdAMaLiBSZXF1aXJlZC4gVGhlIG1lc3NhZ2UgdG8gc2VuZCB0byB0aGUgd29ya2VyLgoK
DAoFBAAIAAESA14IFAq/AQoEBAACARIDZAQ1GrEBIEhUVFAgcmVxdWVzdCB0aGF0IGlzIHNl
bnQgdG8gdGhlIEFwcCBFbmdpbmUgYXBwIGhhbmRsZXIuCgogQW4gQXBwIEVuZ2luZSB0YXNr
IGlzIGEgdGFzayB0aGF0IGhhcwogW0FwcEVuZ2luZUh0dHBSZXF1ZXN0XVtnb29nbGUuY2xv
dWQudGFza3MudjJiZXRhMy5BcHBFbmdpbmVIdHRwUmVxdWVzdF0KIHNldC4KCgwKBQQAAgEG
EgNkBBgKDAoFBAACAQESA2QZMAoMCgUEAAIBAxIDZDM0Cp0BCgQEAAICEgNqBCIajwEgSFRU
UCByZXF1ZXN0IHRoYXQgaXMgc2VudCB0byB0aGUgdGFzaydzIHRhcmdldC4KCiBBbiBIVFRQ
IHRhc2sgaXMgYSB0YXNrIHRoYXQgaGFzCiBbSHR0cFJlcXVlc3RdW2dvb2dsZS5jbG91ZC50
YXNrcy52MmJldGEzLkh0dHBSZXF1ZXN0XSBzZXQuCgoMCgUEAAICBhIDagQPCgwKBQQAAgIB
EgNqEBwKDAoFBAACAgMSA2ofIQrpAwoEBAACAxIDcwQiGtsDIFB1bGwgTWVzc2FnZSBjb250
YWluZWQgaW4gYSB0YXNrIGluIGEKIFtQVUxMXVtnb29nbGUuY2xvdWQudGFza3MudjJiZXRh
My5RdWV1ZS50eXBlXSBxdWV1ZSB0eXBlLiBUaGlzIHBheWxvYWQKIHR5cGUgY2Fubm90IGJl
IGV4cGxpY2l0bHkgc2V0IHRocm91Z2ggQ2xvdWQgVGFza3MgQVBJLiBJdHMgcHVycG9zZSwK
IGN1cnJlbnRseSBpcyB0byBwcm92aWRlIGJhY2t3YXJkIGNvbXBhdGliaWxpdHkgd2l0aCBB
cHAgRW5naW5lIFRhc2sgUXVldWUKIFtwdWxsXShodHRwczovL2Nsb3VkLmdvb2dsZS5jb20v
YXBwZW5naW5lL2RvY3Mvc3RhbmRhcmQvamF2YS90YXNrcXVldWUvcHVsbC8pCiBxdWV1ZXMg
dG8gcHJvdmlkZSBhIHdheSB0byBpbnNwZWN0IGNvbnRlbnRzIG9mIHB1bGwgdGFza3MgdGhy
b3VnaCB0aGUKIFtDbG91ZFRhc2tzLkdldFRhc2tdW2dvb2dsZS5jbG91ZC50YXNrcy52MmJl
dGEzLkNsb3VkVGFza3MuR2V0VGFza10uCgoMCgUEAAIDBhIDcwQPCgwKBQQAAgMBEgNzEBwK
DAoFBAACAwMSA3MfIQrRAQoEBAACBBIDewIuGsMBIFRoZSB0aW1lIHdoZW4gdGhlIHRhc2sg
aXMgc2NoZWR1bGVkIHRvIGJlIGF0dGVtcHRlZC4KCiBGb3IgQXBwIEVuZ2luZSBxdWV1ZXMs
IHRoaXMgaXMgd2hlbiB0aGUgdGFzayB3aWxsIGJlIGF0dGVtcHRlZCBvciByZXRyaWVkLgoK
IGBzY2hlZHVsZV90aW1lYCB3aWxsIGJlIHRydW5jYXRlZCB0byB0aGUgbmVhcmVzdCBtaWNy
b3NlY29uZC4KCgwKBQQAAgQGEgN7AhsKDAoFBAACBAESA3scKQoMCgUEAAIEAxIDeywtCnkK
BAQAAgUSBIABAiwaayBPdXRwdXQgb25seS4gVGhlIHRpbWUgdGhhdCB0aGUgdGFzayB3YXMg
Y3JlYXRlZC4KCiBgY3JlYXRlX3RpbWVgIHdpbGwgYmUgdHJ1bmNhdGVkIHRvIHRoZSBuZWFy
ZXN0IHNlY29uZC4KCg0KBQQAAgUGEgSAAQIbCg0KBQQAAgUBEgSAARwnCg0KBQQAAgUDEgSA
ASorCvcPCgQEAAIGEgSoAQIyGugPIFRoZSBkZWFkbGluZSBmb3IgcmVxdWVzdHMgc2VudCB0
byB0aGUgd29ya2VyLiBJZiB0aGUgd29ya2VyIGRvZXMgbm90CiByZXNwb25kIGJ5IHRoaXMg
ZGVhZGxpbmUgdGhlbiB0aGUgcmVxdWVzdCBpcyBjYW5jZWxsZWQgYW5kIHRoZSBhdHRlbXB0
CiBpcyBtYXJrZWQgYXMgYSBgREVBRExJTkVfRVhDRUVERURgIGZhaWx1cmUuIENsb3VkIFRh
c2tzIHdpbGwgcmV0cnkgdGhlCiB0YXNrIGFjY29yZGluZyB0byB0aGUKIFtSZXRyeUNvbmZp
Z11bZ29vZ2xlLmNsb3VkLnRhc2tzLnYyYmV0YTMuUmV0cnlDb25maWddLgoKIE5vdGUgdGhh
dCB3aGVuIHRoZSByZXF1ZXN0IGlzIGNhbmNlbGxlZCwgQ2xvdWQgVGFza3Mgd2lsbCBzdG9w
IGxpc3RlbmluZwogZm9yIHRoZSByZXNwb25zZSwgYnV0IHdoZXRoZXIgdGhlIHdvcmtlciBz
dG9wcyBwcm9jZXNzaW5nIGRlcGVuZHMgb24gdGhlCiB3b3JrZXIuIEZvciBleGFtcGxlLCBp
ZiB0aGUgd29ya2VyIGlzIHN0dWNrLCBpdCBtYXkgbm90IHJlYWN0IHRvIGNhbmNlbGxlZAog
cmVxdWVzdHMuCgogVGhlIGRlZmF1bHQgYW5kIG1heGltdW0gdmFsdWVzIGRlcGVuZCBvbiB0
aGUgdHlwZSBvZiByZXF1ZXN0OgoKICogRm9yIFtIVFRQIHRhc2tzXVtnb29nbGUuY2xvdWQu
dGFza3MudjJiZXRhMy5IdHRwUmVxdWVzdF0sIHRoZSBkZWZhdWx0IGlzCiAxMCBtaW51dGVz
LiBUaGUgZGVhZGxpbmUKICAgbXVzdCBiZSBpbiB0aGUgaW50ZXJ2YWwgWzE1IHNlY29uZHMs
IDMwIG1pbnV0ZXNdLgoKICogRm9yIFtBcHAgRW5naW5lIHRhc2tzXVtnb29nbGUuY2xvdWQu
dGFza3MudjJiZXRhMy5BcHBFbmdpbmVIdHRwUmVxdWVzdF0sCiAwIGluZGljYXRlcyB0aGF0
IHRoZQogICByZXF1ZXN0IGhhcyB0aGUgZGVmYXVsdCBkZWFkbGluZS4gVGhlIGRlZmF1bHQg
ZGVhZGxpbmUgZGVwZW5kcyBvbiB0aGUKICAgW3NjYWxpbmcKICAgdHlwZV0oaHR0cHM6Ly9j
bG91ZC5nb29nbGUuY29tL2FwcGVuZ2luZS9kb2NzL3N0YW5kYXJkL2dvL2hvdy1pbnN0YW5j
ZXMtYXJlLW1hbmFnZWQjaW5zdGFuY2Vfc2NhbGluZykKICAgb2YgdGhlIHNlcnZpY2U6IDEw
IG1pbnV0ZXMgZm9yIHN0YW5kYXJkIGFwcHMgd2l0aCBhdXRvbWF0aWMgc2NhbGluZywgMjQK
ICAgaG91cnMgZm9yIHN0YW5kYXJkIGFwcHMgd2l0aCBtYW51YWwgYW5kIGJhc2ljIHNjYWxp
bmcsIGFuZCA2MCBtaW51dGVzIGZvcgogICBmbGV4IGFwcHMuIElmIHRoZSByZXF1ZXN0IGRl
YWRsaW5lIGlzIHNldCwgaXQgbXVzdCBiZSBpbiB0aGUgaW50ZXJ2YWwgWzE1CiAgIHNlY29u
ZHMsIDI0IGhvdXJzIDE1IHNlY29uZHNdLiBSZWdhcmRsZXNzIG9mIHRoZSB0YXNrJ3MKICAg
YGRpc3BhdGNoX2RlYWRsaW5lYCwgdGhlIGFwcCBoYW5kbGVyIHdpbGwgbm90IHJ1biBmb3Ig
bG9uZ2VyIHRoYW4gdGhhbgogICB0aGUgc2VydmljZSdzIHRpbWVvdXQuIFdlIHJlY29tbWVu
ZCBzZXR0aW5nIHRoZSBgZGlzcGF0Y2hfZGVhZGxpbmVgIHRvCiAgIGF0IG1vc3QgYSBmZXcg
c2Vjb25kcyBtb3JlIHRoYW4gdGhlIGFwcCBoYW5kbGVyJ3MgdGltZW91dC4gRm9yIG1vcmUK
ICAgaW5mb3JtYXRpb24gc2VlCiAgIFtUaW1lb3V0c10oaHR0cHM6Ly9jbG91ZC5nb29nbGUu
Y29tL3Rhc2tzL2RvY3MvY3JlYXRpbmctYXBwZW5naW5lLWhhbmRsZXJzI3RpbWVvdXRzKS4K
CiBUaGUgdmFsdWUgbXVzdCBiZSBnaXZlbiBhcyBhIHN0cmluZyB0aGF0IGluZGljYXRlcyB0
aGUgbGVuZ3RoIG9mIHRpbWUKIChpbiBzZWNvbmRzKSBmb2xsb3dlZCBieSBgc2AgKGZvciAi
c2Vjb25kcyIpLiBGb3IgbW9yZSBpbmZvcm1hdGlvbiBvbiB0aGUKIGZvcm1hdCwgc2VlIHRo
ZSBkb2N1bWVudGF0aW9uIGZvcgogW0R1cmF0aW9uXShodHRwczovL3Byb3RvYnVmLmRldi9y
ZWZlcmVuY2UvcHJvdG9idWYvZ29vZ2xlLnByb3RvYnVmLyNkdXJhdGlvbikuCiBgZGlzcGF0
Y2hfZGVhZGxpbmVgIHdpbGwgYmUgdHJ1bmNhdGVkIHRvIHRoZSBuZWFyZXN0IG1pbGxpc2Vj
b25kLiBUaGUKIGRlYWRsaW5lIGlzIGFuIGFwcHJveGltYXRlIGRlYWRsaW5lLgoKDQoFBAAC
BgYSBKgBAhoKDQoFBAACBgESBKgBGywKDQoFBAACBgMSBKgBLzEKnAEKBAQAAgcSBK4BAhsa
jQEgT3V0cHV0IG9ubHkuIFRoZSBudW1iZXIgb2YgYXR0ZW1wdHMgZGlzcGF0Y2hlZC4KCiBU
aGlzIGNvdW50IGluY2x1ZGVzIGF0dGVtcHRzIHdoaWNoIGhhdmUgYmVlbiBkaXNwYXRjaGVk
IGJ1dCBoYXZlbid0CiByZWNlaXZlZCBhIHJlc3BvbnNlLgoKDQoFBAACBwUSBK4BAgcKDQoF
BAACBwESBK4BCBYKDQoFBAACBwMSBK4BGRoKUwoEBAACCBIEsQECGxpFIE91dHB1dCBvbmx5
LiBUaGUgbnVtYmVyIG9mIGF0dGVtcHRzIHdoaWNoIGhhdmUgcmVjZWl2ZWQgYSByZXNwb25z
ZS4KCg0KBQQAAggFEgSxAQIHCg0KBQQAAggBEgSxAQgWCg0KBQQAAggDEgSxARkaCoECCgQE
AAIJEgS4AQIcGvIBIE91dHB1dCBvbmx5LiBUaGUgc3RhdHVzIG9mIHRoZSB0YXNrJ3MgZmly
c3QgYXR0ZW1wdC4KCiBPbmx5IFtkaXNwYXRjaF90aW1lXVtnb29nbGUuY2xvdWQudGFza3Mu
djJiZXRhMy5BdHRlbXB0LmRpc3BhdGNoX3RpbWVdIHdpbGwKIGJlIHNldC4gVGhlIG90aGVy
IFtBdHRlbXB0XVtnb29nbGUuY2xvdWQudGFza3MudjJiZXRhMy5BdHRlbXB0XSBpbmZvcm1h
dGlvbgogaXMgbm90IHJldGFpbmVkIGJ5IENsb3VkIFRhc2tzLgoKDQoFBAACCQYSBLgBAgkK
DQoFBAACCQESBLgBChcKDQoFBAACCQMSBLgBGhsKQwoEBAACChIEuwECGxo1IE91dHB1dCBv
bmx5LiBUaGUgc3RhdHVzIG9mIHRoZSB0YXNrJ3MgbGFzdCBhdHRlbXB0LgoKDQoFBAACCgYS
BLsBAgkKDQoFBAACCgESBLsBChYKDQoFBAACCgMSBLsBGRoKfwoEBAACCxIEvwECERpxIE91
dHB1dCBvbmx5LiBUaGUgdmlldyBzcGVjaWZpZXMgd2hpY2ggc3Vic2V0IG9mIHRoZQogW1Rh
c2tdW2dvb2dsZS5jbG91ZC50YXNrcy52MmJldGEzLlRhc2tdIGhhcyBiZWVuIHJldHVybmVk
LgoKDQoFBAACCwYSBL8BAgYKDQoFBAACCwESBL8BBwsKDQoFBAACCwMSBL8BDhAKiQEKBAQA
AgwSBMQBAkkaeyBPcHRpb25hbC4gU3BlY2lmaWVzIHRoZSB0YXNrLWxldmVsIHJldHJ5IGNv
bmZpZy4KCiBJZiBwcmVzZW50LCB0aGlzIG92ZXJyaWRlcyB0aGUgcXVldWUtbGV2ZWwgcmV0
cnkgY29uZmlnIGZvciB0aGlzIHRhc2suCgoNCgUEAAIMBhIExAECDQoNCgUEAAIMARIExAEO
GgoNCgUEAAIMAxIExAEdHwoNCgUEAAIMCBIExAEgSAoQCggEAAIMCJwIABIExAEhRwotCgIE
ARIGyAEA3QEBGh8gVGhlIHN0YXR1cyBvZiBhIHRhc2sgYXR0ZW1wdC4KCgsKAwQBARIEyAEI
DwqGAQoEBAECABIEzAECLhp4IE91dHB1dCBvbmx5LiBUaGUgdGltZSB0aGF0IHRoaXMgYXR0
ZW1wdCB3YXMgc2NoZWR1bGVkLgoKIGBzY2hlZHVsZV90aW1lYCB3aWxsIGJlIHRydW5jYXRl
ZCB0byB0aGUgbmVhcmVzdCBtaWNyb3NlY29uZC4KCg0KBQQBAgAGEgTMAQIbCg0KBQQBAgAB
EgTMARwpCg0KBQQBAgADEgTMASwtCocBCgQEAQIBEgTRAQIuGnkgT3V0cHV0IG9ubHkuIFRo
ZSB0aW1lIHRoYXQgdGhpcyBhdHRlbXB0IHdhcyBkaXNwYXRjaGVkLgoKIGBkaXNwYXRjaF90
aW1lYCB3aWxsIGJlIHRydW5jYXRlZCB0byB0aGUgbmVhcmVzdCBtaWNyb3NlY29uZC4KCg0K
BQQBAgEGEgTRAQIbCg0KBQQBAgEBEgTRARwpCg0KBQQBAgEDEgTRASwtCo8BCgQEAQICEgTW
AQIuGoABIE91dHB1dCBvbmx5LiBUaGUgdGltZSB0aGF0IHRoaXMgYXR0ZW1wdCByZXNwb25z
ZSB3YXMgcmVjZWl2ZWQuCgogYHJlc3BvbnNlX3RpbWVgIHdpbGwgYmUgdHJ1bmNhdGVkIHRv
IHRoZSBuZWFyZXN0IG1pY3Jvc2Vjb25kLgoKDQoFBAECAgYSBNYBAhsKDQoFBAECAgESBNYB
HCkKDQoFBAECAgMSBNYBLC0K2QEKBAQBAgMSBNwBAigaygEgT3V0cHV0IG9ubHkuIFRoZSBy
ZXNwb25zZSBmcm9tIHRoZSB3b3JrZXIgZm9yIHRoaXMgYXR0ZW1wdC4KCiBJZiBgcmVzcG9u
c2VfdGltZWAgaXMgdW5zZXQsIHRoZW4gdGhlIHRhc2sgaGFzIG5vdCBiZWVuIGF0dGVtcHRl
ZCBvciBpcwogY3VycmVudGx5IHJ1bm5pbmcgYW5kIHRoZSBgcmVzcG9uc2Vfc3RhdHVzYCBm
aWVsZCBpcyBtZWFuaW5nbGVzcy4KCg0KBQQBAgMGEgTcAQITCg0KBQQBAgMBEgTcARQjCg0K
BQQBAgMDEgTcASYnYgZwcm90bzM=
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Tasks::V2beta3::Task::Task ===
    # Fields for Task
    # Field: name Type: 9 ()
    # Field: app_engine_http_request Type: 11 (.google.cloud.tasks.v2beta3.AppEngineHttpRequest)
    # Field: http_request Type: 11 (.google.cloud.tasks.v2beta3.HttpRequest)
    # Field: pull_message Type: 11 (.google.cloud.tasks.v2beta3.PullMessage)
    # Field: schedule_time Type: 11 (.google.protobuf.Timestamp)
    # Field: create_time Type: 11 (.google.protobuf.Timestamp)
    # Field: dispatch_deadline Type: 11 (.google.protobuf.Duration)
    # Field: dispatch_count Type: 5 ()
    # Field: response_count Type: 5 ()
    # Field: first_attempt Type: 11 (.google.cloud.tasks.v2beta3.Attempt)
    # Field: last_attempt Type: 11 (.google.cloud.tasks.v2beta3.Attempt)
    # Field: view Type: 14 (.google.cloud.tasks.v2beta3.Task.View)
    # Field: retry_config Type: 11 (.google.cloud.tasks.v2beta3.RetryConfig)

# Enum: Task::View
our $Task_VIEW_UNSPECIFIED = 0;
our $Task_BASIC = 1;
our $Task_FULL = 2;

# === Message: Google::Cloud::Tasks::V2beta3::Task::Attempt ===
    # Fields for Attempt
    # Field: schedule_time Type: 11 (.google.protobuf.Timestamp)
    # Field: dispatch_time Type: 11 (.google.protobuf.Timestamp)
    # Field: response_time Type: 11 (.google.protobuf.Timestamp)
    # Field: response_status Type: 11 (.google.rpc.Status)

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Tasks::V2beta3::Task - Compiled Protocol Buffers messages for google/cloud/tasks/v2beta3/task.proto

=head1 SYNOPSIS

    use Google::Cloud::Tasks::V2beta3::Task;

    my $msg = Google::Cloud::Tasks::V2beta3::Task::Task->new({
        name => $name,
        app_engine_http_request => $app_engine_http_request,
        http_request => $http_request,
        pull_message => $pull_message,
    });

    # Read or update a field
    my $val = $msg->name();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Tasks::V2beta3::Task::Task->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/tasks/v2beta3/task.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Tasks::V2beta3::Task::Task

A unit of scheduled work.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Optionally caller-specified in
[CreateTask][google.cloud.tasks.v2beta3.CloudTasks.CreateTask].

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

Type: C<Message> (L<Google::Cloud::Tasks::V2beta3::Target::AppEngineHttpRequest>)

HTTP request that is sent to the App Engine app handler.

An App Engine task is a task that has
[AppEngineHttpRequest][google.cloud.tasks.v2beta3.AppEngineHttpRequest]
set.

=item * C<< $msg->http_request() >> / C<< $msg->http_request($value) >>

Type: C<Message> (L<Google::Cloud::Tasks::V2beta3::Target::HttpRequest>)

HTTP request that is sent to the task's target.

An HTTP task is a task that has
[HttpRequest][google.cloud.tasks.v2beta3.HttpRequest] set.

=item * C<< $msg->pull_message() >> / C<< $msg->pull_message($value) >>

Type: C<Message> (L<Google::Cloud::Tasks::V2beta3::Target::PullMessage>)

Pull Message contained in a task in a
[PULL][google.cloud.tasks.v2beta3.Queue.type] queue type. This payload
type cannot be explicitly set through Cloud Tasks API. Its purpose,
currently is to provide backward compatibility with App Engine Task Queue
[pull](https://cloud.google.com/appengine/docs/standard/java/taskqueue/pull/)
queues to provide a way to inspect contents of pull tasks through the
[CloudTasks.GetTask][google.cloud.tasks.v2beta3.CloudTasks.GetTask].

=item * C<< $msg->schedule_time() >> / C<< $msg->schedule_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

The time when the task is scheduled to be attempted.

For App Engine queues, this is when the task will be attempted or retried.

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
task according to the
[RetryConfig][google.cloud.tasks.v2beta3.RetryConfig].

Note that when the request is cancelled, Cloud Tasks will stop listening
for the response, but whether the worker stops processing depends on the
worker. For example, if the worker is stuck, it may not react to cancelled
requests.

The default and maximum values depend on the type of request:

* For [HTTP tasks][google.cloud.tasks.v2beta3.HttpRequest], the default is
10 minutes. The deadline
  must be in the interval [15 seconds, 30 minutes].

* For [App Engine tasks][google.cloud.tasks.v2beta3.AppEngineHttpRequest],
0 indicates that the
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

Type: C<Message> (L<Google::Cloud::Tasks::V2beta3::Task::Attempt>)

Output only. The status of the task's first attempt.

Only [dispatch_time][google.cloud.tasks.v2beta3.Attempt.dispatch_time] will
be set. The other [Attempt][google.cloud.tasks.v2beta3.Attempt] information
is not retained by Cloud Tasks.

=item * C<< $msg->last_attempt() >> / C<< $msg->last_attempt($value) >>

Type: C<Message> (L<Google::Cloud::Tasks::V2beta3::Task::Attempt>)

Output only. The status of the task's last attempt.

=item * C<< $msg->view() >> / C<< $msg->view($value) >>

Type: C<Enum> (L<Google::Cloud::Tasks::V2beta3::Task::View>)

Output only. The view specifies which subset of the
[Task][google.cloud.tasks.v2beta3.Task] has been returned.

=item * C<< $msg->retry_config() >> / C<< $msg->retry_config($value) >>

Type: C<Message> (L<Google::Cloud::Tasks::V2beta3::Queue::RetryConfig>)

Optional. Specifies the task-level retry config.

If present, this overrides the queue-level retry config for this task.

=back

=head3 Enum: Task::View

=over 4

=item * C<VIEW_UNSPECIFIED> => C<0>

=item * C<BASIC> => C<1>

=item * C<FULL> => C<2>

=back

=head2 Google::Cloud::Tasks::V2beta3::Task::Attempt

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

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Tasks::V2beta3::Task::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
