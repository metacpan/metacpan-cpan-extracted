package Google::Cloud::Scheduler::V1beta1::Target;

use strict;
use warnings;

our $VERSION = '0.14';

use Protobuf::Message;
use Protobuf::DescriptorPool;
use Protobuf::Internal qw(:all);
use MIME::Base64;

BEGIN {
    eval { require Google::Api::Resource };
    my $descriptor_b64 = <<'EOF';
Citnb29nbGUvY2xvdWQvc2NoZWR1bGVyL3YxYmV0YTEvdGFyZ2V0LnByb3RvEh5nb29nbGUu
Y2xvdWQuc2NoZWR1bGVyLnYxYmV0YTEaGWdvb2dsZS9hcGkvcmVzb3VyY2UucHJvdG8iwQMK
Ckh0dHBUYXJnZXQSEAoDdXJpGAEgASgJUgN1cmkSSwoLaHR0cF9tZXRob2QYAiABKA4yKi5n
b29nbGUuY2xvdWQuc2NoZWR1bGVyLnYxYmV0YTEuSHR0cE1ldGhvZFIKaHR0cE1ldGhvZBJR
CgdoZWFkZXJzGAMgAygLMjcuZ29vZ2xlLmNsb3VkLnNjaGVkdWxlci52MWJldGExLkh0dHBU
YXJnZXQuSGVhZGVyc0VudHJ5UgdoZWFkZXJzEhIKBGJvZHkYBCABKAxSBGJvZHkSTQoLb2F1
dGhfdG9rZW4YBSABKAsyKi5nb29nbGUuY2xvdWQuc2NoZWR1bGVyLnYxYmV0YTEuT0F1dGhU
b2tlbkgAUgpvYXV0aFRva2VuEkoKCm9pZGNfdG9rZW4YBiABKAsyKS5nb29nbGUuY2xvdWQu
c2NoZWR1bGVyLnYxYmV0YTEuT2lkY1Rva2VuSABSCW9pZGNUb2tlbho6CgxIZWFkZXJzRW50
cnkSEAoDa2V5GAEgASgJUgNrZXkSFAoFdmFsdWUYAiABKAlSBXZhbHVlOgI4AUIWChRhdXRo
b3JpemF0aW9uX2hlYWRlciKRAwoTQXBwRW5naW5lSHR0cFRhcmdldBJLCgtodHRwX21ldGhv
ZBgBIAEoDjIqLmdvb2dsZS5jbG91ZC5zY2hlZHVsZXIudjFiZXRhMS5IdHRwTWV0aG9kUgpo
dHRwTWV0aG9kEl4KEmFwcF9lbmdpbmVfcm91dGluZxgCIAEoCzIwLmdvb2dsZS5jbG91ZC5z
Y2hlZHVsZXIudjFiZXRhMS5BcHBFbmdpbmVSb3V0aW5nUhBhcHBFbmdpbmVSb3V0aW5nEiEK
DHJlbGF0aXZlX3VyaRgDIAEoCVILcmVsYXRpdmVVcmkSWgoHaGVhZGVycxgEIAMoCzJALmdv
b2dsZS5jbG91ZC5zY2hlZHVsZXIudjFiZXRhMS5BcHBFbmdpbmVIdHRwVGFyZ2V0LkhlYWRl
cnNFbnRyeVIHaGVhZGVycxISCgRib2R5GAUgASgMUgRib2R5GjoKDEhlYWRlcnNFbnRyeRIQ
CgNrZXkYASABKAlSA2tleRIUCgV2YWx1ZRgCIAEoCVIFdmFsdWU6AjgBIoACCgxQdWJzdWJU
YXJnZXQSPwoKdG9waWNfbmFtZRgBIAEoCUIg+kEdChtwdWJzdWIuZ29vZ2xlYXBpcy5jb20v
VG9waWNSCXRvcGljTmFtZRISCgRkYXRhGAMgASgMUgRkYXRhElwKCmF0dHJpYnV0ZXMYBCAD
KAsyPC5nb29nbGUuY2xvdWQuc2NoZWR1bGVyLnYxYmV0YTEuUHVic3ViVGFyZ2V0LkF0dHJp
YnV0ZXNFbnRyeVIKYXR0cmlidXRlcxo9Cg9BdHRyaWJ1dGVzRW50cnkSEAoDa2V5GAEgASgJ
UgNrZXkSFAoFdmFsdWUYAiABKAlSBXZhbHVlOgI4ASJ2ChBBcHBFbmdpbmVSb3V0aW5nEhgK
B3NlcnZpY2UYASABKAlSB3NlcnZpY2USGAoHdmVyc2lvbhgCIAEoCVIHdmVyc2lvbhIaCghp
bnN0YW5jZRgDIAEoCVIIaW5zdGFuY2USEgoEaG9zdBgEIAEoCVIEaG9zdCJWCgpPQXV0aFRv
a2VuEjIKFXNlcnZpY2VfYWNjb3VudF9lbWFpbBgBIAEoCVITc2VydmljZUFjY291bnRFbWFp
bBIUCgVzY29wZRgCIAEoCVIFc2NvcGUiWwoJT2lkY1Rva2VuEjIKFXNlcnZpY2VfYWNjb3Vu
dF9lbWFpbBgBIAEoCVITc2VydmljZUFjY291bnRFbWFpbBIaCghhdWRpZW5jZRgCIAEoCVII
YXVkaWVuY2UqcwoKSHR0cE1ldGhvZBIbChdIVFRQX01FVEhPRF9VTlNQRUNJRklFRBAAEggK
BFBPU1QQARIHCgNHRVQQAhIICgRIRUFEEAMSBwoDUFVUEAQSCgoGREVMRVRFEAUSCQoFUEFU
Q0gQBhILCgdPUFRJT05TEAdCuAEKImNvbS5nb29nbGUuY2xvdWQuc2NoZWR1bGVyLnYxYmV0
YTFCC1RhcmdldFByb3RvUAFaQGNsb3VkLmdvb2dsZS5jb20vZ28vc2NoZWR1bGVyL2FwaXYx
YmV0YTEvc2NoZWR1bGVycGI7c2NoZWR1bGVycGLqQUAKG3B1YnN1Yi5nb29nbGVhcGlzLmNv
bS9Ub3BpYxIhcHJvamVjdHMve3Byb2plY3R9L3RvcGljcy97dG9waWN9Sut1CgcSBQ4A8gIB
CrwECgEMEgMOABIysQQgQ29weXJpZ2h0IDIwMjUgR29vZ2xlIExMQwoKIExpY2Vuc2VkIHVu
ZGVyIHRoZSBBcGFjaGUgTGljZW5zZSwgVmVyc2lvbiAyLjAgKHRoZSAiTGljZW5zZSIpOwog
eW91IG1heSBub3QgdXNlIHRoaXMgZmlsZSBleGNlcHQgaW4gY29tcGxpYW5jZSB3aXRoIHRo
ZSBMaWNlbnNlLgogWW91IG1heSBvYnRhaW4gYSBjb3B5IG9mIHRoZSBMaWNlbnNlIGF0Cgog
ICAgIGh0dHA6Ly93d3cuYXBhY2hlLm9yZy9saWNlbnNlcy9MSUNFTlNFLTIuMAoKIFVubGVz
cyByZXF1aXJlZCBieSBhcHBsaWNhYmxlIGxhdyBvciBhZ3JlZWQgdG8gaW4gd3JpdGluZywg
c29mdHdhcmUKIGRpc3RyaWJ1dGVkIHVuZGVyIHRoZSBMaWNlbnNlIGlzIGRpc3RyaWJ1dGVk
IG9uIGFuICJBUyBJUyIgQkFTSVMsCiBXSVRIT1VUIFdBUlJBTlRJRVMgT1IgQ09ORElUSU9O
UyBPRiBBTlkgS0lORCwgZWl0aGVyIGV4cHJlc3Mgb3IgaW1wbGllZC4KIFNlZSB0aGUgTGlj
ZW5zZSBmb3IgdGhlIHNwZWNpZmljIGxhbmd1YWdlIGdvdmVybmluZyBwZXJtaXNzaW9ucyBh
bmQKIGxpbWl0YXRpb25zIHVuZGVyIHRoZSBMaWNlbnNlLgoKCAoBAhIDEAAnCgkKAgMAEgMS
ACMKCAoBCBIDFABXCgkKAggLEgMUAFcKCAoBCBIDFQAiCgkKAggKEgMVACIKCAoBCBIDFgAs
CgkKAggIEgMWACwKCAoBCBIDFwA7CgkKAggBEgMXADsKCQoBCBIEGAAbAgoMCgQInQgAEgQY
ABsCCsIDCgIEABIEJABkARq1AyBIdHRwIHRhcmdldC4gVGhlIGpvYiB3aWxsIGJlIHB1c2hl
ZCB0byB0aGUgam9iIGhhbmRsZXIgYnkgbWVhbnMgb2YKIGFuIEhUVFAgcmVxdWVzdCB2aWEg
YW4KIFtodHRwX21ldGhvZF1bZ29vZ2xlLmNsb3VkLnNjaGVkdWxlci52MWJldGExLkh0dHBU
YXJnZXQuaHR0cF9tZXRob2RdIHN1Y2ggYXMKIEhUVFAgUE9TVCwgSFRUUCBHRVQsIGV0Yy4g
VGhlIGpvYiBpcyBhY2tub3dsZWRnZWQgYnkgbWVhbnMgb2YgYW4gSFRUUAogcmVzcG9uc2Ug
Y29kZSBpbiB0aGUgcmFuZ2UgWzIwMCAtIDI5OV0uIEEgZmFpbHVyZSB0byByZWNlaXZlIGEg
cmVzcG9uc2UKIGNvbnN0aXR1dGVzIGEgZmFpbGVkIGV4ZWN1dGlvbi4gRm9yIGEgcmVkaXJl
Y3RlZCByZXF1ZXN0LCB0aGUgcmVzcG9uc2UKIHJldHVybmVkIGJ5IHRoZSByZWRpcmVjdGVk
IHJlcXVlc3QgaXMgY29uc2lkZXJlZC4KCgoKAwQAARIDJAgSCqsDCgQEAAIAEgMrAhEanQMg
UmVxdWlyZWQuIFRoZSBmdWxsIFVSSSBwYXRoIHRoYXQgdGhlIHJlcXVlc3Qgd2lsbCBiZSBz
ZW50IHRvLiBUaGlzIHN0cmluZwogbXVzdCBiZWdpbiB3aXRoIGVpdGhlciAiaHR0cDovLyIg
b3IgImh0dHBzOi8vIi4gU29tZSBleGFtcGxlcyBvZgogdmFsaWQgdmFsdWVzIGZvciBbdXJp
XVtnb29nbGUuY2xvdWQuc2NoZWR1bGVyLnYxYmV0YTEuSHR0cFRhcmdldC51cmldIGFyZToK
IGBodHRwOi8vYWNtZS5jb21gIGFuZCBgaHR0cHM6Ly9hY21lLmNvbS9zYWxlczo4MDgwYC4g
Q2xvdWQgU2NoZWR1bGVyIHdpbGwKIGVuY29kZSBzb21lIGNoYXJhY3RlcnMgZm9yIHNhZmV0
eSBhbmQgY29tcGF0aWJpbGl0eS4gVGhlIG1heGltdW0gYWxsb3dlZAogVVJMIGxlbmd0aCBp
cyAyMDgzIGNoYXJhY3RlcnMgYWZ0ZXIgZW5jb2RpbmcuCgoMCgUEAAIABRIDKwIICgwKBQQA
AgABEgMrCQwKDAoFBAACAAMSAysPEAo4CgQEAAIBEgMuAh0aKyBXaGljaCBIVFRQIG1ldGhv
ZCB0byB1c2UgZm9yIHRoZSByZXF1ZXN0LgoKDAoFBAACAQYSAy4CDAoMCgUEAAIBARIDLg0Y
CgwKBQQAAgEDEgMuGxwK/ggKBAQAAgISA0QCIhrwCCBUaGUgdXNlciBjYW4gc3BlY2lmeSBI
VFRQIHJlcXVlc3QgaGVhZGVycyB0byBzZW5kIHdpdGggdGhlIGpvYidzCiBIVFRQIHJlcXVl
c3QuIFRoaXMgbWFwIGNvbnRhaW5zIHRoZSBoZWFkZXIgZmllbGQgbmFtZXMgYW5kCiB2YWx1
ZXMuIFJlcGVhdGVkIGhlYWRlcnMgYXJlIG5vdCBzdXBwb3J0ZWQsIGJ1dCBhIGhlYWRlciB2
YWx1ZSBjYW4KIGNvbnRhaW4gY29tbWFzLiBUaGVzZSBoZWFkZXJzIHJlcHJlc2VudCBhIHN1
YnNldCBvZiB0aGUgaGVhZGVycwogdGhhdCB3aWxsIGFjY29tcGFueSB0aGUgam9iJ3MgSFRU
UCByZXF1ZXN0LiBTb21lIEhUVFAgcmVxdWVzdAogaGVhZGVycyB3aWxsIGJlIGlnbm9yZWQg
b3IgcmVwbGFjZWQuIEEgcGFydGlhbCBsaXN0IG9mIGhlYWRlcnMgdGhhdAogd2lsbCBiZSBp
Z25vcmVkIG9yIHJlcGxhY2VkIGlzIGJlbG93OgogLSBIb3N0OiBUaGlzIHdpbGwgYmUgY29t
cHV0ZWQgYnkgQ2xvdWQgU2NoZWR1bGVyIGFuZCBkZXJpdmVkIGZyb20KIFt1cmldW2dvb2ds
ZS5jbG91ZC5zY2hlZHVsZXIudjFiZXRhMS5IdHRwVGFyZ2V0LnVyaV0uCiAqIGBDb250ZW50
LUxlbmd0aGA6IFRoaXMgd2lsbCBiZSBjb21wdXRlZCBieSBDbG91ZCBTY2hlZHVsZXIuCiAq
IGBVc2VyLUFnZW50YDogVGhpcyB3aWxsIGJlIHNldCB0byBgIkdvb2dsZS1DbG91ZC1TY2hl
ZHVsZXIiYC4KICogYFgtR29vZ2xlLSpgOiBHb29nbGUgaW50ZXJuYWwgdXNlIG9ubHkuCiAq
IGBYLUFwcEVuZ2luZS0qYDogR29vZ2xlIGludGVybmFsIHVzZSBvbmx5LgogKiBgWC1DbG91
ZFNjaGVkdWxlcmA6IFRoaXMgaGVhZGVyIHdpbGwgYmUgc2V0IHRvIHRydWUuCiAqIGBYLUNs
b3VkU2NoZWR1bGVyLUpvYk5hbWVgOiBUaGlzIGhlYWRlciB3aWxsIGNvbnRhaW4gdGhlIGpv
YiBuYW1lLgogKiBgWC1DbG91ZFNjaGVkdWxlci1TY2hlZHVsZVRpbWVgOiBGb3IgQ2xvdWQg
U2NoZWR1bGVyIGpvYnMgc3BlY2lmaWVkIGluCiB0aGUgdW5peC1jcm9uIGZvcm1hdCwgdGhp
cyBoZWFkZXIgd2lsbCBjb250YWluIHRoZSBqb2Igc2NoZWR1bGUgYXMgYW4KIG9mZnNldCBv
ZiBVVEMgcGFyc2VkIGFjY29yZGluZyB0byBSRkMzMzM5LgoKIFRoZSB0b3RhbCBzaXplIG9m
IGhlYWRlcnMgbXVzdCBiZSBsZXNzIHRoYW4gODBLQi4KCgwKBQQAAgIGEgNEAhUKDAoFBAAC
AgESA0QWHQoMCgUEAAICAxIDRCAhCuABCgQEAAIDEgNJAhEa0gEgSFRUUCByZXF1ZXN0IGJv
ZHkuIEEgcmVxdWVzdCBib2R5IGlzIGFsbG93ZWQgb25seSBpZiB0aGUgSFRUUAogbWV0aG9k
IGlzIFBPU1QsIFBVVCwgb3IgUEFUQ0guIEl0IGlzIGFuIGVycm9yIHRvIHNldCBib2R5IG9u
IGEgam9iIHdpdGggYW4KIGluY29tcGF0aWJsZSBbSHR0cE1ldGhvZF1bZ29vZ2xlLmNsb3Vk
LnNjaGVkdWxlci52MWJldGExLkh0dHBNZXRob2RdLgoKDAoFBAACAwUSA0kCBwoMCgUEAAID
ARIDSQgMCgwKBQQAAgMDEgNJDxAK7AEKBAQACAASBFACYwMa3QEgVGhlIG1vZGUgZm9yIGdl
bmVyYXRpbmcgYW4gYEF1dGhvcml6YXRpb25gIGhlYWRlciBmb3IgSFRUUCByZXF1ZXN0cy4K
CiBJZiBzcGVjaWZpZWQsIGFsbCBgQXV0aG9yaXphdGlvbmAgaGVhZGVycyBpbiB0aGUKIFtI
dHRwVGFyZ2V0LmhlYWRlcnNdW2dvb2dsZS5jbG91ZC5zY2hlZHVsZXIudjFiZXRhMS5IdHRw
VGFyZ2V0LmhlYWRlcnNdCiBmaWVsZCB3aWxsIGJlIG92ZXJyaWRkZW4uCgoMCgUEAAgAARID
UAgcCqwCCgQEAAIEEgNYBB8angIgSWYgc3BlY2lmaWVkLCBhbgogW09BdXRoIHRva2VuXSho
dHRwczovL2RldmVsb3BlcnMuZ29vZ2xlLmNvbS9pZGVudGl0eS9wcm90b2NvbHMvT0F1dGgy
KQogd2lsbCBiZSBnZW5lcmF0ZWQgYW5kIGF0dGFjaGVkIGFzIGFuIGBBdXRob3JpemF0aW9u
YCBoZWFkZXIgaW4gdGhlIEhUVFAKIHJlcXVlc3QuCgogVGhpcyB0eXBlIG9mIGF1dGhvcml6
YXRpb24gc2hvdWxkIGdlbmVyYWxseSBvbmx5IGJlIHVzZWQgd2hlbiBjYWxsaW5nCiBHb29n
bGUgQVBJcyBob3N0ZWQgb24gKi5nb29nbGVhcGlzLmNvbS4KCgwKBQQAAgQGEgNYBA4KDAoF
BAACBAESA1gPGgoMCgUEAAIEAxIDWB0eCtsCCgQEAAIFEgNiBB0azQIgSWYgc3BlY2lmaWVk
LCBhbgogW09JRENdKGh0dHBzOi8vZGV2ZWxvcGVycy5nb29nbGUuY29tL2lkZW50aXR5L3By
b3RvY29scy9PcGVuSURDb25uZWN0KQogdG9rZW4gd2lsbCBiZSBnZW5lcmF0ZWQgYW5kIGF0
dGFjaGVkIGFzIGFuIGBBdXRob3JpemF0aW9uYCBoZWFkZXIgaW4gdGhlCiBIVFRQIHJlcXVl
c3QuCgogVGhpcyB0eXBlIG9mIGF1dGhvcml6YXRpb24gY2FuIGJlIHVzZWQgZm9yIG1hbnkg
c2NlbmFyaW9zLCBpbmNsdWRpbmcKIGNhbGxpbmcgQ2xvdWQgUnVuLCBvciBlbmRwb2ludHMg
d2hlcmUgeW91IGludGVuZCB0byB2YWxpZGF0ZSB0aGUgdG9rZW4KIHlvdXJzZWxmLgoKDAoF
BAACBQYSA2IEDQoMCgUEAAIFARIDYg4YCgwKBQQAAgUDEgNiGxwK8QQKAgQBEgVvAK0BARrj
BCBBcHAgRW5naW5lIHRhcmdldC4gVGhlIGpvYiB3aWxsIGJlIHB1c2hlZCB0byBhIGpvYiBo
YW5kbGVyIGJ5IG1lYW5zCiBvZiBhbiBIVFRQIHJlcXVlc3QgdmlhIGFuCiBbaHR0cF9tZXRo
b2RdW2dvb2dsZS5jbG91ZC5zY2hlZHVsZXIudjFiZXRhMS5BcHBFbmdpbmVIdHRwVGFyZ2V0
Lmh0dHBfbWV0aG9kXQogc3VjaCBhcyBIVFRQIFBPU1QsIEhUVFAgR0VULCBldGMuIFRoZSBq
b2IgaXMgYWNrbm93bGVkZ2VkIGJ5IG1lYW5zIG9mIGFuIEhUVFAKIHJlc3BvbnNlIGNvZGUg
aW4gdGhlIHJhbmdlIFsyMDAgLSAyOTldLiBFcnJvciA1MDMgaXMgY29uc2lkZXJlZCBhbiBB
cHAgRW5naW5lCiBzeXN0ZW0gZXJyb3IgaW5zdGVhZCBvZiBhbiBhcHBsaWNhdGlvbiBlcnJv
ci4gUmVxdWVzdHMgcmV0dXJuaW5nIGVycm9yIDUwMwogd2lsbCBiZSByZXRyaWVkIHJlZ2Fy
ZGxlc3Mgb2YgcmV0cnkgY29uZmlndXJhdGlvbiBhbmQgbm90IGNvdW50ZWQgYWdhaW5zdAog
cmV0cnkgY291bnRzLiBBbnkgb3RoZXIgcmVzcG9uc2UgY29kZSwgb3IgYSBmYWlsdXJlIHRv
IHJlY2VpdmUgYSByZXNwb25zZQogYmVmb3JlIHRoZSBkZWFkbGluZSwgY29uc3RpdHV0ZXMg
YSBmYWlsZWQgYXR0ZW1wdC4KCgoKAwQBARIDbwgbClwKBAQBAgASA3ICHRpPIFRoZSBIVFRQ
IG1ldGhvZCB0byB1c2UgZm9yIHRoZSByZXF1ZXN0LiBQQVRDSCBhbmQgT1BUSU9OUyBhcmUg
bm90CiBwZXJtaXR0ZWQuCgoMCgUEAQIABhIDcgIMCgwKBQQBAgABEgNyDRgKDAoFBAECAAMS
A3IbHAo2CgQEAQIBEgN1AioaKSBBcHAgRW5naW5lIFJvdXRpbmcgc2V0dGluZyBmb3IgdGhl
IGpvYi4KCgwKBQQBAgEGEgN1AhIKDAoFBAECAQESA3UTJQoMCgUEAQIBAxIDdSgpCsECCgQE
AQICEgN9AhoaswIgVGhlIHJlbGF0aXZlIFVSSS4KCiBUaGUgcmVsYXRpdmUgVVJMIG11c3Qg
YmVnaW4gd2l0aCAiLyIgYW5kIG11c3QgYmUgYSB2YWxpZCBIVFRQIHJlbGF0aXZlIFVSTC4K
IEl0IGNhbiBjb250YWluIGEgcGF0aCwgcXVlcnkgc3RyaW5nIGFyZ3VtZW50cywgYW5kIGAj
YCBmcmFnbWVudHMuCiBJZiB0aGUgcmVsYXRpdmUgVVJMIGlzIGVtcHR5LCB0aGVuIHRoZSBy
b290IHBhdGggIi8iIHdpbGwgYmUgdXNlZC4KIE5vIHNwYWNlcyBhcmUgYWxsb3dlZCwgYW5k
IHRoZSBtYXhpbXVtIGxlbmd0aCBhbGxvd2VkIGlzIDIwODMgY2hhcmFjdGVycy4KCgwKBQQB
AgIFEgN9AggKDAoFBAECAgESA30JFQoMCgUEAQICAxIDfRgZCrkMCgQEAQIDEgSkAQIiGqoM
IEhUVFAgcmVxdWVzdCBoZWFkZXJzLgoKIFRoaXMgbWFwIGNvbnRhaW5zIHRoZSBoZWFkZXIg
ZmllbGQgbmFtZXMgYW5kIHZhbHVlcy4gSGVhZGVycyBjYW4gYmUgc2V0CiB3aGVuIHRoZSBq
b2IgaXMgY3JlYXRlZC4KCiBDbG91ZCBTY2hlZHVsZXIgc2V0cyBzb21lIGhlYWRlcnMgdG8g
ZGVmYXVsdCB2YWx1ZXM6CgogKiBgVXNlci1BZ2VudGA6IEJ5IGRlZmF1bHQsIHRoaXMgaGVh
ZGVyIGlzCiAgIGAiQXBwRW5naW5lLUdvb2dsZTsgKCtodHRwOi8vY29kZS5nb29nbGUuY29t
L2FwcGVuZ2luZSkiYC4KICAgVGhpcyBoZWFkZXIgY2FuIGJlIG1vZGlmaWVkLCBidXQgQ2xv
dWQgU2NoZWR1bGVyIHdpbGwgYXBwZW5kCiAgIGAiQXBwRW5naW5lLUdvb2dsZTsgKCtodHRw
Oi8vY29kZS5nb29nbGUuY29tL2FwcGVuZ2luZSkiYCB0byB0aGUKICAgbW9kaWZpZWQgYFVz
ZXItQWdlbnRgLgogKiBgWC1DbG91ZFNjaGVkdWxlcmA6IFRoaXMgaGVhZGVyIHdpbGwgYmUg
c2V0IHRvIHRydWUuCiAqIGBYLUNsb3VkU2NoZWR1bGVyLUpvYk5hbWVgOiBUaGlzIGhlYWRl
ciB3aWxsIGNvbnRhaW4gdGhlIGpvYiBuYW1lLgogKiBgWC1DbG91ZFNjaGVkdWxlci1TY2hl
ZHVsZVRpbWVgOiBGb3IgQ2xvdWQgU2NoZWR1bGVyIGpvYnMgc3BlY2lmaWVkIGluCiB0aGUg
dW5peC1jcm9uIGZvcm1hdCwgdGhpcyBoZWFkZXIgd2lsbCBjb250YWluIHRoZSBqb2Igc2No
ZWR1bGUgYXMgYW4KIG9mZnNldCBvZiBVVEMgcGFyc2VkIGFjY29yZGluZyB0byBSRkMzMzM5
LgoKIElmIHRoZSBqb2IgaGFzIGFuCiBbYm9keV1bZ29vZ2xlLmNsb3VkLnNjaGVkdWxlci52
MWJldGExLkFwcEVuZ2luZUh0dHBUYXJnZXQuYm9keV0sIENsb3VkCiBTY2hlZHVsZXIgc2V0
cyB0aGUgZm9sbG93aW5nIGhlYWRlcnM6CgogKiBgQ29udGVudC1UeXBlYDogQnkgZGVmYXVs
dCwgdGhlIGBDb250ZW50LVR5cGVgIGhlYWRlciBpcyBzZXQgdG8KICAgYCJhcHBsaWNhdGlv
bi9vY3RldC1zdHJlYW0iYC4gVGhlIGRlZmF1bHQgY2FuIGJlIG92ZXJyaWRkZW4gYnkgZXhw
bGljdGx5CiAgIHNldHRpbmcgYENvbnRlbnQtVHlwZWAgdG8gYSBwYXJ0aWN1bGFyIG1lZGlh
IHR5cGUgd2hlbiB0aGUgam9iIGlzCiAgIGNyZWF0ZWQuCiAgIEZvciBleGFtcGxlLCBgQ29u
dGVudC1UeXBlYCBjYW4gYmUgc2V0IHRvIGAiYXBwbGljYXRpb24vanNvbiJgLgogKiBgQ29u
dGVudC1MZW5ndGhgOiBUaGlzIGlzIGNvbXB1dGVkIGJ5IENsb3VkIFNjaGVkdWxlci4gVGhp
cyB2YWx1ZSBpcwogICBvdXRwdXQgb25seS4gSXQgY2Fubm90IGJlIGNoYW5nZWQuCgogVGhl
IGhlYWRlcnMgYmVsb3cgYXJlIG91dHB1dCBvbmx5LiBUaGV5IGNhbm5vdCBiZSBzZXQgb3Ig
b3ZlcnJpZGRlbjoKCiAqIGBYLUdvb2dsZS0qYDogRm9yIEdvb2dsZSBpbnRlcm5hbCB1c2Ug
b25seS4KICogYFgtQXBwRW5naW5lLSpgOiBGb3IgR29vZ2xlIGludGVybmFsIHVzZSBvbmx5
LgoKIEluIGFkZGl0aW9uLCBzb21lIEFwcCBFbmdpbmUgaGVhZGVycywgd2hpY2ggY29udGFp
bgogam9iLXNwZWNpZmljIGluZm9ybWF0aW9uLCBhcmUgYWxzbyBiZSBzZW50IHRvIHRoZSBq
b2IgaGFuZGxlci4KCg0KBQQBAgMGEgSkAQIVCg0KBQQBAgMBEgSkARYdCg0KBQQBAgMDEgSk
ASAhCv4BCgQEAQIEEgSsAQIRGu8BIEJvZHkuCgogSFRUUCByZXF1ZXN0IGJvZHkuIEEgcmVx
dWVzdCBib2R5IGlzIGFsbG93ZWQgb25seSBpZiB0aGUgSFRUUCBtZXRob2QgaXMKIFBPU1Qg
b3IgUFVULiBJdCB3aWxsIHJlc3VsdCBpbiBpbnZhbGlkIGFyZ3VtZW50IGVycm9yIHRvIHNl
dCBhIGJvZHkgb24gYQogam9iIHdpdGggYW4gaW5jb21wYXRpYmxlCiBbSHR0cE1ldGhvZF1b
Z29vZ2xlLmNsb3VkLnNjaGVkdWxlci52MWJldGExLkh0dHBNZXRob2RdLgoKDQoFBAECBAUS
BKwBAgcKDQoFBAECBAESBKwBCAwKDQoFBAECBAMSBKwBDxAKbgoCBAISBrEBAMgBARpgIFB1
Yi9TdWIgdGFyZ2V0LiBUaGUgam9iIHdpbGwgYmUgZGVsaXZlcmVkIGJ5IHB1Ymxpc2hpbmcg
YSBtZXNzYWdlIHRvCiB0aGUgZ2l2ZW4gUHViL1N1YiB0b3BpYy4KCgsKAwQCARIEsQEIFAqm
AwoEBAICABIGuQECuwEEGpUDIFJlcXVpcmVkLiBUaGUgbmFtZSBvZiB0aGUgQ2xvdWQgUHVi
L1N1YiB0b3BpYyB0byB3aGljaCBtZXNzYWdlcyB3aWxsCiBiZSBwdWJsaXNoZWQgd2hlbiBh
IGpvYiBpcyBkZWxpdmVyZWQuIFRoZSB0b3BpYyBuYW1lIG11c3QgYmUgaW4gdGhlCiBzYW1l
IGZvcm1hdCBhcyByZXF1aXJlZCBieSBQdWIvU3ViJ3MKIFtQdWJsaXNoUmVxdWVzdC5uYW1l
XShodHRwczovL2Nsb3VkLmdvb2dsZS5jb20vcHVic3ViL2RvY3MvcmVmZXJlbmNlL3JwYy9n
b29nbGUucHVic3ViLnYxI3B1Ymxpc2hyZXF1ZXN0KSwKIGZvciBleGFtcGxlIGBwcm9qZWN0
cy9QUk9KRUNUX0lEL3RvcGljcy9UT1BJQ19JRGAuCgogVGhlIHRvcGljIG11c3QgYmUgaW4g
dGhlIHNhbWUgcHJvamVjdCBhcyB0aGUgQ2xvdWQgU2NoZWR1bGVyIGpvYi4KCg0KBQQCAgAF
EgS5AQIICg0KBQQCAgABEgS5AQkTCg0KBQQCAgADEgS5ARYXCg8KBQQCAgAIEga5ARi7AQMK
DwoHBAICAAifCBIEugEETQqHAQoEBAICARIEwQECERp5IFRoZSBtZXNzYWdlIHBheWxvYWQg
Zm9yIFB1YnN1Yk1lc3NhZ2UuCgogUHVic3ViIG1lc3NhZ2UgbXVzdCBjb250YWluIGVpdGhl
ciBub24tZW1wdHkgZGF0YSwgb3IgYXQgbGVhc3Qgb25lCiBhdHRyaWJ1dGUuCgoNCgUEAgIB
BRIEwQECBwoNCgUEAgIBARIEwQEIDAoNCgUEAgIBAxIEwQEPEAp+CgQEAgICEgTHAQIlGnAg
QXR0cmlidXRlcyBmb3IgUHVic3ViTWVzc2FnZS4KCiBQdWJzdWIgbWVzc2FnZSBtdXN0IGNv
bnRhaW4gZWl0aGVyIG5vbi1lbXB0eSBkYXRhLCBvciBhdCBsZWFzdCBvbmUKIGF0dHJpYnV0
ZS4KCg0KBQQCAgIGEgTHAQIVCg0KBQQCAgIBEgTHARYgCg0KBQQCAgIDEgTHASMkCsUECgIE
AxIG1QEAtAIBGrYEIEFwcCBFbmdpbmUgUm91dGluZy4KCiBGb3IgbW9yZSBpbmZvcm1hdGlv
biBhYm91dCBzZXJ2aWNlcywgdmVyc2lvbnMsIGFuZCBpbnN0YW5jZXMgc2VlCiBbQW4gT3Zl
cnZpZXcgb2YgQXBwCiBFbmdpbmVdKGh0dHBzOi8vY2xvdWQuZ29vZ2xlLmNvbS9hcHBlbmdp
bmUvZG9jcy9weXRob24vYW4tb3ZlcnZpZXctb2YtYXBwLWVuZ2luZSksCiBbTWljcm9zZXJ2
aWNlcyBBcmNoaXRlY3R1cmUgb24gR29vZ2xlIEFwcAogRW5naW5lXShodHRwczovL2Nsb3Vk
Lmdvb2dsZS5jb20vYXBwZW5naW5lL2RvY3MvcHl0aG9uL21pY3Jvc2VydmljZXMtb24tYXBw
LWVuZ2luZSksCiBbQXBwIEVuZ2luZSBTdGFuZGFyZCByZXF1ZXN0CiByb3V0aW5nXShodHRw
czovL2Nsb3VkLmdvb2dsZS5jb20vYXBwZW5naW5lL2RvY3Mvc3RhbmRhcmQvcHl0aG9uL2hv
dy1yZXF1ZXN0cy1hcmUtcm91dGVkKSwKIGFuZCBbQXBwIEVuZ2luZSBGbGV4IHJlcXVlc3QK
IHJvdXRpbmddKGh0dHBzOi8vY2xvdWQuZ29vZ2xlLmNvbS9hcHBlbmdpbmUvZG9jcy9mbGV4
aWJsZS9weXRob24vaG93LXJlcXVlc3RzLWFyZS1yb3V0ZWQpLgoKCwoDBAMBEgTVAQgYCoIB
CgQEAwIAEgTaAQIVGnQgQXBwIHNlcnZpY2UuCgogQnkgZGVmYXVsdCwgdGhlIGpvYiBpcyBz
ZW50IHRvIHRoZSBzZXJ2aWNlIHdoaWNoIGlzIHRoZSBkZWZhdWx0CiBzZXJ2aWNlIHdoZW4g
dGhlIGpvYiBpcyBhdHRlbXB0ZWQuCgoNCgUEAwIABRIE2gECCAoNCgUEAwIAARIE2gEJEAoN
CgUEAwIAAxIE2gETFAqCAQoEBAMCARIE4AECFRp0IEFwcCB2ZXJzaW9uLgoKIEJ5IGRlZmF1
bHQsIHRoZSBqb2IgaXMgc2VudCB0byB0aGUgdmVyc2lvbiB3aGljaCBpcyB0aGUgZGVmYXVs
dAogdmVyc2lvbiB3aGVuIHRoZSBqb2IgaXMgYXR0ZW1wdGVkLgoKDQoFBAMCAQUSBOABAggK
DQoFBAMCAQESBOABCRAKDQoFBAMCAQMSBOABExQKiwUKBAQDAgISBO8BAhYa/AQgQXBwIGlu
c3RhbmNlLgoKIEJ5IGRlZmF1bHQsIHRoZSBqb2IgaXMgc2VudCB0byBhbiBpbnN0YW5jZSB3
aGljaCBpcyBhdmFpbGFibGUgd2hlbgogdGhlIGpvYiBpcyBhdHRlbXB0ZWQuCgogUmVxdWVz
dHMgY2FuIG9ubHkgYmUgc2VudCB0byBhIHNwZWNpZmljIGluc3RhbmNlIGlmCiBbbWFudWFs
IHNjYWxpbmcgaXMgdXNlZCBpbiBBcHAgRW5naW5lCiBTdGFuZGFyZF0oaHR0cHM6Ly9jbG91
ZC5nb29nbGUuY29tL2FwcGVuZ2luZS9kb2NzL3B5dGhvbi9hbi1vdmVydmlldy1vZi1hcHAt
ZW5naW5lPyNzY2FsaW5nX3R5cGVzX2FuZF9pbnN0YW5jZV9jbGFzc2VzKS4KIEFwcCBFbmdp
bmUgRmxleCBkb2VzIG5vdCBzdXBwb3J0IGluc3RhbmNlcy4gRm9yIG1vcmUgaW5mb3JtYXRp
b24sIHNlZQogW0FwcCBFbmdpbmUgU3RhbmRhcmQgcmVxdWVzdAogcm91dGluZ10oaHR0cHM6
Ly9jbG91ZC5nb29nbGUuY29tL2FwcGVuZ2luZS9kb2NzL3N0YW5kYXJkL3B5dGhvbi9ob3ct
cmVxdWVzdHMtYXJlLXJvdXRlZCkKIGFuZCBbQXBwIEVuZ2luZSBGbGV4IHJlcXVlc3QKIHJv
dXRpbmddKGh0dHBzOi8vY2xvdWQuZ29vZ2xlLmNvbS9hcHBlbmdpbmUvZG9jcy9mbGV4aWJs
ZS9weXRob24vaG93LXJlcXVlc3RzLWFyZS1yb3V0ZWQpLgoKDQoFBAMCAgUSBO8BAggKDQoF
BAMCAgESBO8BCREKDQoFBAMCAgMSBO8BFBUKjRYKBAQDAgMSBLMCAhIa/hUgT3V0cHV0IG9u
bHkuIFRoZSBob3N0IHRoYXQgdGhlIGpvYiBpcyBzZW50IHRvLgoKIEZvciBtb3JlIGluZm9y
bWF0aW9uIGFib3V0IGhvdyBBcHAgRW5naW5lIHJlcXVlc3RzIGFyZSByb3V0ZWQsIHNlZQog
W2hlcmVdKGh0dHBzOi8vY2xvdWQuZ29vZ2xlLmNvbS9hcHBlbmdpbmUvZG9jcy9zdGFuZGFy
ZC9weXRob24vaG93LXJlcXVlc3RzLWFyZS1yb3V0ZWQpLgoKIFRoZSBob3N0IGlzIGNvbnN0
cnVjdGVkIGFzOgoKCiAqIGBob3N0ID0gW2FwcGxpY2F0aW9uX2RvbWFpbl9uYW1lXWA8L2Jy
PgogICBgfCBbc2VydmljZV0gKyAnLicgKyBbYXBwbGljYXRpb25fZG9tYWluX25hbWVdYDwv
YnI+CiAgIGB8IFt2ZXJzaW9uXSArICcuJyArIFthcHBsaWNhdGlvbl9kb21haW5fbmFtZV1g
PC9icj4KICAgYHwgW3ZlcnNpb25fZG90X3NlcnZpY2VdKyAnLicgKyBbYXBwbGljYXRpb25f
ZG9tYWluX25hbWVdYDwvYnI+CiAgIGB8IFtpbnN0YW5jZV0gKyAnLicgKyBbYXBwbGljYXRp
b25fZG9tYWluX25hbWVdYDwvYnI+CiAgIGB8IFtpbnN0YW5jZV9kb3Rfc2VydmljZV0gKyAn
LicgKyBbYXBwbGljYXRpb25fZG9tYWluX25hbWVdYDwvYnI+CiAgIGB8IFtpbnN0YW5jZV9k
b3RfdmVyc2lvbl0gKyAnLicgKyBbYXBwbGljYXRpb25fZG9tYWluX25hbWVdYDwvYnI+CiAg
IGB8IFtpbnN0YW5jZV9kb3RfdmVyc2lvbl9kb3Rfc2VydmljZV0gKyAnLicgKyBbYXBwbGlj
YXRpb25fZG9tYWluX25hbWVdYAoKICogYGFwcGxpY2F0aW9uX2RvbWFpbl9uYW1lYCA9IFRo
ZSBkb21haW4gbmFtZSBvZiB0aGUgYXBwLCBmb3IKICAgZXhhbXBsZSA8YXBwLWlkPi5hcHBz
cG90LmNvbSwgd2hpY2ggaXMgYXNzb2NpYXRlZCB3aXRoIHRoZQogICBqb2IncyBwcm9qZWN0
IElELgoKICogYHNlcnZpY2UgPWAKIFtzZXJ2aWNlXVtnb29nbGUuY2xvdWQuc2NoZWR1bGVy
LnYxYmV0YTEuQXBwRW5naW5lUm91dGluZy5zZXJ2aWNlXQoKICogYHZlcnNpb24gPWAKIFt2
ZXJzaW9uXVtnb29nbGUuY2xvdWQuc2NoZWR1bGVyLnYxYmV0YTEuQXBwRW5naW5lUm91dGlu
Zy52ZXJzaW9uXQoKICogYHZlcnNpb25fZG90X3NlcnZpY2UgPWAKICAgW3ZlcnNpb25dW2dv
b2dsZS5jbG91ZC5zY2hlZHVsZXIudjFiZXRhMS5BcHBFbmdpbmVSb3V0aW5nLnZlcnNpb25d
IGArICcuJwogICArYCBbc2VydmljZV1bZ29vZ2xlLmNsb3VkLnNjaGVkdWxlci52MWJldGEx
LkFwcEVuZ2luZVJvdXRpbmcuc2VydmljZV0KCiAqIGBpbnN0YW5jZSA9YAogW2luc3RhbmNl
XVtnb29nbGUuY2xvdWQuc2NoZWR1bGVyLnYxYmV0YTEuQXBwRW5naW5lUm91dGluZy5pbnN0
YW5jZV0KCiAqIGBpbnN0YW5jZV9kb3Rfc2VydmljZSA9YAogICBbaW5zdGFuY2VdW2dvb2ds
ZS5jbG91ZC5zY2hlZHVsZXIudjFiZXRhMS5BcHBFbmdpbmVSb3V0aW5nLmluc3RhbmNlXSBg
KwogICAnLicgK2AgW3NlcnZpY2VdW2dvb2dsZS5jbG91ZC5zY2hlZHVsZXIudjFiZXRhMS5B
cHBFbmdpbmVSb3V0aW5nLnNlcnZpY2VdCgogKiBgaW5zdGFuY2VfZG90X3ZlcnNpb24gPWAK
ICAgW2luc3RhbmNlXVtnb29nbGUuY2xvdWQuc2NoZWR1bGVyLnYxYmV0YTEuQXBwRW5naW5l
Um91dGluZy5pbnN0YW5jZV0gYCsKICAgJy4nICtgIFt2ZXJzaW9uXVtnb29nbGUuY2xvdWQu
c2NoZWR1bGVyLnYxYmV0YTEuQXBwRW5naW5lUm91dGluZy52ZXJzaW9uXQoKICogYGluc3Rh
bmNlX2RvdF92ZXJzaW9uX2RvdF9zZXJ2aWNlID1gCiAgIFtpbnN0YW5jZV1bZ29vZ2xlLmNs
b3VkLnNjaGVkdWxlci52MWJldGExLkFwcEVuZ2luZVJvdXRpbmcuaW5zdGFuY2VdIGArCiAg
ICcuJyArYCBbdmVyc2lvbl1bZ29vZ2xlLmNsb3VkLnNjaGVkdWxlci52MWJldGExLkFwcEVu
Z2luZVJvdXRpbmcudmVyc2lvbl0KICAgYCsgJy4nICtgCiAgIFtzZXJ2aWNlXVtnb29nbGUu
Y2xvdWQuc2NoZWR1bGVyLnYxYmV0YTEuQXBwRW5naW5lUm91dGluZy5zZXJ2aWNlXQoKCiBJ
ZiBbc2VydmljZV1bZ29vZ2xlLmNsb3VkLnNjaGVkdWxlci52MWJldGExLkFwcEVuZ2luZVJv
dXRpbmcuc2VydmljZV0gaXMKIGVtcHR5LCB0aGVuIHRoZSBqb2Igd2lsbCBiZSBzZW50IHRv
IHRoZSBzZXJ2aWNlIHdoaWNoIGlzIHRoZSBkZWZhdWx0CiBzZXJ2aWNlIHdoZW4gdGhlIGpv
YiBpcyBhdHRlbXB0ZWQuCgogSWYgW3ZlcnNpb25dW2dvb2dsZS5jbG91ZC5zY2hlZHVsZXIu
djFiZXRhMS5BcHBFbmdpbmVSb3V0aW5nLnZlcnNpb25dIGlzCiBlbXB0eSwgdGhlbiB0aGUg
am9iIHdpbGwgYmUgc2VudCB0byB0aGUgdmVyc2lvbiB3aGljaCBpcyB0aGUgZGVmYXVsdAog
dmVyc2lvbiB3aGVuIHRoZSBqb2IgaXMgYXR0ZW1wdGVkLgoKIElmIFtpbnN0YW5jZV1bZ29v
Z2xlLmNsb3VkLnNjaGVkdWxlci52MWJldGExLkFwcEVuZ2luZVJvdXRpbmcuaW5zdGFuY2Vd
IGlzCiBlbXB0eSwgdGhlbiB0aGUgam9iIHdpbGwgYmUgc2VudCB0byBhbiBpbnN0YW5jZSB3
aGljaCBpcyBhdmFpbGFibGUgd2hlbiB0aGUKIGpvYiBpcyBhdHRlbXB0ZWQuCgogSWYgW3Nl
cnZpY2VdW2dvb2dsZS5jbG91ZC5zY2hlZHVsZXIudjFiZXRhMS5BcHBFbmdpbmVSb3V0aW5n
LnNlcnZpY2VdLAogW3ZlcnNpb25dW2dvb2dsZS5jbG91ZC5zY2hlZHVsZXIudjFiZXRhMS5B
cHBFbmdpbmVSb3V0aW5nLnZlcnNpb25dLCBvcgogW2luc3RhbmNlXVtnb29nbGUuY2xvdWQu
c2NoZWR1bGVyLnYxYmV0YTEuQXBwRW5naW5lUm91dGluZy5pbnN0YW5jZV0gaXMKIGludmFs
aWQsIHRoZW4gdGhlIGpvYiB3aWxsIGJlIHNlbnQgdG8gdGhlIGRlZmF1bHQgdmVyc2lvbiBv
ZiB0aGUgZGVmYXVsdAogc2VydmljZSB3aGVuIHRoZSBqb2IgaXMgYXR0ZW1wdGVkLgoKDQoF
BAMCAwUSBLMCAggKDQoFBAMCAwESBLMCCQ0KDQoFBAMCAwMSBLMCEBEKOAoCBQASBrcCAM8C
ARoqIFRoZSBIVFRQIG1ldGhvZCB1c2VkIHRvIGV4ZWN1dGUgdGhlIGpvYi4KCgsKAwUAARIE
twIFDwo6CgQFAAIAEgS5AgIeGiwgSFRUUCBtZXRob2QgdW5zcGVjaWZpZWQuIERlZmF1bHRz
IHRvIFBPU1QuCgoNCgUFAAIAARIEuQICGQoNCgUFAAIAAhIEuQIcHQoZCgQFAAIBEgS8AgIL
GgsgSFRUUCBQT1NUCgoNCgUFAAIBARIEvAICBgoNCgUFAAIBAhIEvAIJCgoYCgQFAAICEgS/
AgIKGgogSFRUUCBHRVQKCg0KBQUAAgIBEgS/AgIFCg0KBQUAAgICEgS/AggJChkKBAUAAgMS
BMICAgsaCyBIVFRQIEhFQUQKCg0KBQUAAgMBEgTCAgIGCg0KBQUAAgMCEgTCAgkKChgKBAUA
AgQSBMUCAgoaCiBIVFRQIFBVVAoKDQoFBQACBAESBMUCAgUKDQoFBQACBAISBMUCCAkKGwoE
BQACBRIEyAICDRoNIEhUVFAgREVMRVRFCgoNCgUFAAIFARIEyAICCAoNCgUFAAIFAhIEyAIL
DAoaCgQFAAIGEgTLAgIMGgwgSFRUUCBQQVRDSAoKDQoFBQACBgESBMsCAgcKDQoFBQACBgIS
BMsCCgsKHAoEBQACBxIEzgICDhoOIEhUVFAgT1BUSU9OUwoKDQoFBQACBwESBM4CAgkKDQoF
BQACBwISBM4CDA0K9wEKAgQEEgbVAgDgAgEa6AEgQ29udGFpbnMgaW5mb3JtYXRpb24gbmVl
ZGVkIGZvciBnZW5lcmF0aW5nIGFuCiBbT0F1dGggdG9rZW5dKGh0dHBzOi8vZGV2ZWxvcGVy
cy5nb29nbGUuY29tL2lkZW50aXR5L3Byb3RvY29scy9PQXV0aDIpLgogVGhpcyB0eXBlIG9m
IGF1dGhvcml6YXRpb24gc2hvdWxkIGdlbmVyYWxseSBvbmx5IGJlIHVzZWQgd2hlbiBjYWxs
aW5nIEdvb2dsZQogQVBJcyBob3N0ZWQgb24gKi5nb29nbGVhcGlzLmNvbS4KCgsKAwQEARIE
1QIIEgqZAgoEBAQCABIE2gICIxqKAiBbU2VydmljZSBhY2NvdW50IGVtYWlsXShodHRwczov
L2Nsb3VkLmdvb2dsZS5jb20vaWFtL2RvY3Mvc2VydmljZS1hY2NvdW50cykKIHRvIGJlIHVz
ZWQgZm9yIGdlbmVyYXRpbmcgT0F1dGggdG9rZW4uCiBUaGUgc2VydmljZSBhY2NvdW50IG11
c3QgYmUgd2l0aGluIHRoZSBzYW1lIHByb2plY3QgYXMgdGhlIGpvYi4gVGhlIGNhbGxlcgog
bXVzdCBoYXZlIGlhbS5zZXJ2aWNlQWNjb3VudHMuYWN0QXMgcGVybWlzc2lvbiBmb3IgdGhl
IHNlcnZpY2UgYWNjb3VudC4KCg0KBQQEAgAFEgTaAgIICg0KBQQEAgABEgTaAgkeCg0KBQQE
AgADEgTaAiEiCp0BCgQEBAIBEgTfAgITGo4BIE9BdXRoIHNjb3BlIHRvIGJlIHVzZWQgZm9y
IGdlbmVyYXRpbmcgT0F1dGggYWNjZXNzIHRva2VuLgogSWYgbm90IHNwZWNpZmllZCwgImh0
dHBzOi8vd3d3Lmdvb2dsZWFwaXMuY29tL2F1dGgvY2xvdWQtcGxhdGZvcm0iCiB3aWxsIGJl
IHVzZWQuCgoNCgUEBAIBBRIE3wICCAoNCgUEBAIBARIE3wIJDgoNCgUEBAIBAxIE3wIREgqx
AgoCBAUSBugCAPICARqiAiBDb250YWlucyBpbmZvcm1hdGlvbiBuZWVkZWQgZm9yIGdlbmVy
YXRpbmcgYW4KIFtPcGVuSUQgQ29ubmVjdAogdG9rZW5dKGh0dHBzOi8vZGV2ZWxvcGVycy5n
b29nbGUuY29tL2lkZW50aXR5L3Byb3RvY29scy9PcGVuSURDb25uZWN0KS4KIFRoaXMgdHlw
ZSBvZiBhdXRob3JpemF0aW9uIGNhbiBiZSB1c2VkIGZvciBtYW55IHNjZW5hcmlvcywgaW5j
bHVkaW5nCiBjYWxsaW5nIENsb3VkIFJ1biwgb3IgZW5kcG9pbnRzIHdoZXJlIHlvdSBpbnRl
bmQgdG8gdmFsaWRhdGUgdGhlIHRva2VuCiB5b3Vyc2VsZi4KCgsKAwQFARIE6AIIEQqYAgoE
BAUCABIE7QICIxqJAiBbU2VydmljZSBhY2NvdW50IGVtYWlsXShodHRwczovL2Nsb3VkLmdv
b2dsZS5jb20vaWFtL2RvY3Mvc2VydmljZS1hY2NvdW50cykKIHRvIGJlIHVzZWQgZm9yIGdl
bmVyYXRpbmcgT0lEQyB0b2tlbi4KIFRoZSBzZXJ2aWNlIGFjY291bnQgbXVzdCBiZSB3aXRo
aW4gdGhlIHNhbWUgcHJvamVjdCBhcyB0aGUgam9iLiBUaGUgY2FsbGVyCiBtdXN0IGhhdmUg
aWFtLnNlcnZpY2VBY2NvdW50cy5hY3RBcyBwZXJtaXNzaW9uIGZvciB0aGUgc2VydmljZSBh
Y2NvdW50LgoKDQoFBAUCAAUSBO0CAggKDQoFBAUCAAESBO0CCR4KDQoFBAUCAAMSBO0CISIK
fAoEBAUCARIE8QICFhpuIEF1ZGllbmNlIHRvIGJlIHVzZWQgd2hlbiBnZW5lcmF0aW5nIE9J
REMgdG9rZW4uIElmIG5vdCBzcGVjaWZpZWQsIHRoZSBVUkkKIHNwZWNpZmllZCBpbiB0YXJn
ZXQgd2lsbCBiZSB1c2VkLgoKDQoFBAUCAQUSBPECAggKDQoFBAUCAQESBPECCREKDQoFBAUC
AQMSBPECFBViBnByb3RvMw==
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Scheduler::V1beta1::Target::HttpTarget ===
    # Fields for HttpTarget
    # Field: uri Type: 9 ()
    # Field: http_method Type: 14 (.google.cloud.scheduler.v1beta1.HttpMethod)
    # Field: headers Type: 11 (.google.cloud.scheduler.v1beta1.HttpTarget.HeadersEntry)
    # Field: body Type: 12 ()
    # Field: oauth_token Type: 11 (.google.cloud.scheduler.v1beta1.OAuthToken)
    # Field: oidc_token Type: 11 (.google.cloud.scheduler.v1beta1.OidcToken)

# === Message: Google::Cloud::Scheduler::V1beta1::Target::AppEngineHttpTarget ===
    # Fields for AppEngineHttpTarget
    # Field: http_method Type: 14 (.google.cloud.scheduler.v1beta1.HttpMethod)
    # Field: app_engine_routing Type: 11 (.google.cloud.scheduler.v1beta1.AppEngineRouting)
    # Field: relative_uri Type: 9 ()
    # Field: headers Type: 11 (.google.cloud.scheduler.v1beta1.AppEngineHttpTarget.HeadersEntry)
    # Field: body Type: 12 ()

# === Message: Google::Cloud::Scheduler::V1beta1::Target::PubsubTarget ===
    # Fields for PubsubTarget
    # Field: topic_name Type: 9 ()
    # Field: data Type: 12 ()
    # Field: attributes Type: 11 (.google.cloud.scheduler.v1beta1.PubsubTarget.AttributesEntry)

# === Message: Google::Cloud::Scheduler::V1beta1::Target::AppEngineRouting ===
    # Fields for AppEngineRouting
    # Field: service Type: 9 ()
    # Field: version Type: 9 ()
    # Field: instance Type: 9 ()
    # Field: host Type: 9 ()

# === Message: Google::Cloud::Scheduler::V1beta1::Target::OAuthToken ===
    # Fields for OAuthToken
    # Field: service_account_email Type: 9 ()
    # Field: scope Type: 9 ()

# === Message: Google::Cloud::Scheduler::V1beta1::Target::OidcToken ===
    # Fields for OidcToken
    # Field: service_account_email Type: 9 ()
    # Field: audience Type: 9 ()

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Scheduler::V1beta1::Target - Compiled Protocol Buffers messages for google/cloud/scheduler/v1beta1/target.proto

=head1 SYNOPSIS

    use Google::Cloud::Scheduler::V1beta1::Target;

    my $msg = Google::Cloud::Scheduler::V1beta1::Target::HttpTarget->new({
        uri => $uri,
        http_method => $http_method,
        headers => $headers,
        body => $body,
    });

    # Read or update a field
    my $val = $msg->uri();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Scheduler::V1beta1::Target::HttpTarget->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/scheduler/v1beta1/target.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Scheduler::V1beta1::Target::HttpTarget

Http target. The job will be pushed to the job handler by means of
an HTTP request via an
[http_method][google.cloud.scheduler.v1beta1.HttpTarget.http_method] such as
HTTP POST, HTTP GET, etc. The job is acknowledged by means of an HTTP
response code in the range [200 - 299]. A failure to receive a response
constitutes a failed execution. For a redirected request, the response
returned by the redirected request is considered.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->uri() >> / C<< $msg->uri($value) >>

Type: C<String>

Required. The full URI path that the request will be sent to. This string
must begin with either "http://" or "https://". Some examples of
valid values for [uri][google.cloud.scheduler.v1beta1.HttpTarget.uri] are:
`http://acme.com` and `https://acme.com/sales:8080`. Cloud Scheduler will
encode some characters for safety and compatibility. The maximum allowed
URL length is 2083 characters after encoding.

=item * C<< $msg->http_method() >> / C<< $msg->http_method($value) >>

Type: C<Enum> (L<Google::Cloud::Scheduler::V1beta1::HttpMethod>)

Which HTTP method to use for the request.

=item * C<< $msg->headers() >> / C<< $msg->headers($value) >>

Type: C<Message> (L<Google::Cloud::Scheduler::V1beta1::Target::HttpTarget::HeadersEntry>)

The user can specify HTTP request headers to send with the job's
HTTP request. This map contains the header field names and
values. Repeated headers are not supported, but a header value can
contain commas. These headers represent a subset of the headers
that will accompany the job's HTTP request. Some HTTP request
headers will be ignored or replaced. A partial list of headers that
will be ignored or replaced is below:
- Host: This will be computed by Cloud Scheduler and derived from
[uri][google.cloud.scheduler.v1beta1.HttpTarget.uri].
* `Content-Length`: This will be computed by Cloud Scheduler.
* `User-Agent`: This will be set to `"Google-Cloud-Scheduler"`.
* `X-Google-*`: Google internal use only.
* `X-AppEngine-*`: Google internal use only.
* `X-CloudScheduler`: This header will be set to true.
* `X-CloudScheduler-JobName`: This header will contain the job name.
* `X-CloudScheduler-ScheduleTime`: For Cloud Scheduler jobs specified in
the unix-cron format, this header will contain the job schedule as an
offset of UTC parsed according to RFC3339.

The total size of headers must be less than 80KB.

=item * C<< $msg->body() >> / C<< $msg->body($value) >>

Type: C<Bytes>

HTTP request body. A request body is allowed only if the HTTP
method is POST, PUT, or PATCH. It is an error to set body on a job with an
incompatible [HttpMethod][google.cloud.scheduler.v1beta1.HttpMethod].

=item * C<< $msg->oauth_token() >> / C<< $msg->oauth_token($value) >>

Type: C<Message> (L<Google::Cloud::Scheduler::V1beta1::Target::OAuthToken>)

If specified, an
[OAuth token](https://developers.google.com/identity/protocols/OAuth2)
will be generated and attached as an `Authorization` header in the HTTP
request.

This type of authorization should generally only be used when calling
Google APIs hosted on *.googleapis.com.

=item * C<< $msg->oidc_token() >> / C<< $msg->oidc_token($value) >>

Type: C<Message> (L<Google::Cloud::Scheduler::V1beta1::Target::OidcToken>)

If specified, an
[OIDC](https://developers.google.com/identity/protocols/OpenIDConnect)
token will be generated and attached as an `Authorization` header in the
HTTP request.

This type of authorization can be used for many scenarios, including
calling Cloud Run, or endpoints where you intend to validate the token
yourself.

=back

=head2 Google::Cloud::Scheduler::V1beta1::Target::AppEngineHttpTarget

App Engine target. The job will be pushed to a job handler by means
of an HTTP request via an
[http_method][google.cloud.scheduler.v1beta1.AppEngineHttpTarget.http_method]
such as HTTP POST, HTTP GET, etc. The job is acknowledged by means of an HTTP
response code in the range [200 - 299]. Error 503 is considered an App Engine
system error instead of an application error. Requests returning error 503
will be retried regardless of retry configuration and not counted against
retry counts. Any other response code, or a failure to receive a response
before the deadline, constitutes a failed attempt.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->http_method() >> / C<< $msg->http_method($value) >>

Type: C<Enum> (L<Google::Cloud::Scheduler::V1beta1::HttpMethod>)

The HTTP method to use for the request. PATCH and OPTIONS are not
permitted.

=item * C<< $msg->app_engine_routing() >> / C<< $msg->app_engine_routing($value) >>

Type: C<Message> (L<Google::Cloud::Scheduler::V1beta1::Target::AppEngineRouting>)

App Engine Routing setting for the job.

=item * C<< $msg->relative_uri() >> / C<< $msg->relative_uri($value) >>

Type: C<String>

The relative URI.

The relative URL must begin with "/" and must be a valid HTTP relative URL.
It can contain a path, query string arguments, and `#` fragments.
If the relative URL is empty, then the root path "/" will be used.
No spaces are allowed, and the maximum length allowed is 2083 characters.

=item * C<< $msg->headers() >> / C<< $msg->headers($value) >>

Type: C<Message> (L<Google::Cloud::Scheduler::V1beta1::Target::AppEngineHttpTarget::HeadersEntry>)

HTTP request headers.

This map contains the header field names and values. Headers can be set
when the job is created.

Cloud Scheduler sets some headers to default values:

* `User-Agent`: By default, this header is
  `"AppEngine-Google; (+http://code.google.com/appengine)"`.
  This header can be modified, but Cloud Scheduler will append
  `"AppEngine-Google; (+http://code.google.com/appengine)"` to the
  modified `User-Agent`.
* `X-CloudScheduler`: This header will be set to true.
* `X-CloudScheduler-JobName`: This header will contain the job name.
* `X-CloudScheduler-ScheduleTime`: For Cloud Scheduler jobs specified in
the unix-cron format, this header will contain the job schedule as an
offset of UTC parsed according to RFC3339.

If the job has an
[body][google.cloud.scheduler.v1beta1.AppEngineHttpTarget.body], Cloud
Scheduler sets the following headers:

* `Content-Type`: By default, the `Content-Type` header is set to
  `"application/octet-stream"`. The default can be overridden by explictly
  setting `Content-Type` to a particular media type when the job is
  created.
  For example, `Content-Type` can be set to `"application/json"`.
* `Content-Length`: This is computed by Cloud Scheduler. This value is
  output only. It cannot be changed.

The headers below are output only. They cannot be set or overridden:

* `X-Google-*`: For Google internal use only.
* `X-AppEngine-*`: For Google internal use only.

In addition, some App Engine headers, which contain
job-specific information, are also be sent to the job handler.

=item * C<< $msg->body() >> / C<< $msg->body($value) >>

Type: C<Bytes>

Body.

HTTP request body. A request body is allowed only if the HTTP method is
POST or PUT. It will result in invalid argument error to set a body on a
job with an incompatible
[HttpMethod][google.cloud.scheduler.v1beta1.HttpMethod].

=back

=head2 Google::Cloud::Scheduler::V1beta1::Target::PubsubTarget

Pub/Sub target. The job will be delivered by publishing a message to
the given Pub/Sub topic.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->topic_name() >> / C<< $msg->topic_name($value) >>

Type: C<String>

Required. The name of the Cloud Pub/Sub topic to which messages will
be published when a job is delivered. The topic name must be in the
same format as required by Pub/Sub's
[PublishRequest.name](https://cloud.google.com/pubsub/docs/reference/rpc/google.pubsub.v1#publishrequest),
for example `projects/PROJECT_ID/topics/TOPIC_ID`.

The topic must be in the same project as the Cloud Scheduler job.

=item * C<< $msg->data() >> / C<< $msg->data($value) >>

Type: C<Bytes>

The message payload for PubsubMessage.

Pubsub message must contain either non-empty data, or at least one
attribute.

=item * C<< $msg->attributes() >> / C<< $msg->attributes($value) >>

Type: C<Message> (L<Google::Cloud::Scheduler::V1beta1::Target::PubsubTarget::AttributesEntry>)

Attributes for PubsubMessage.

Pubsub message must contain either non-empty data, or at least one
attribute.

=back

=head2 Google::Cloud::Scheduler::V1beta1::Target::AppEngineRouting

App Engine Routing.

For more information about services, versions, and instances see
[An Overview of App
Engine](https://cloud.google.com/appengine/docs/python/an-overview-of-app-engine),
[Microservices Architecture on Google App
Engine](https://cloud.google.com/appengine/docs/python/microservices-on-app-engine),
[App Engine Standard request
routing](https://cloud.google.com/appengine/docs/standard/python/how-requests-are-routed),
and [App Engine Flex request
routing](https://cloud.google.com/appengine/docs/flexible/python/how-requests-are-routed).

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->service() >> / C<< $msg->service($value) >>

Type: C<String>

App service.

By default, the job is sent to the service which is the default
service when the job is attempted.

=item * C<< $msg->version() >> / C<< $msg->version($value) >>

Type: C<String>

App version.

By default, the job is sent to the version which is the default
version when the job is attempted.

=item * C<< $msg->instance() >> / C<< $msg->instance($value) >>

Type: C<String>

App instance.

By default, the job is sent to an instance which is available when
the job is attempted.

Requests can only be sent to a specific instance if
[manual scaling is used in App Engine
Standard](https://cloud.google.com/appengine/docs/python/an-overview-of-app-engine?#scaling_types_and_instance_classes).
App Engine Flex does not support instances. For more information, see
[App Engine Standard request
routing](https://cloud.google.com/appengine/docs/standard/python/how-requests-are-routed)
and [App Engine Flex request
routing](https://cloud.google.com/appengine/docs/flexible/python/how-requests-are-routed).

=item * C<< $msg->host() >> / C<< $msg->host($value) >>

Type: C<String>

Output only. The host that the job is sent to.

For more information about how App Engine requests are routed, see
[here](https://cloud.google.com/appengine/docs/standard/python/how-requests-are-routed).

The host is constructed as:


* `host = [application_domain_name]`</br>
  `| [service] + '.' + [application_domain_name]`</br>
  `| [version] + '.' + [application_domain_name]`</br>
  `| [version_dot_service]+ '.' + [application_domain_name]`</br>
  `| [instance] + '.' + [application_domain_name]`</br>
  `| [instance_dot_service] + '.' + [application_domain_name]`</br>
  `| [instance_dot_version] + '.' + [application_domain_name]`</br>
  `| [instance_dot_version_dot_service] + '.' + [application_domain_name]`

* `application_domain_name` = The domain name of the app, for
  example <app-id>.appspot.com, which is associated with the
  job's project ID.

* `service =`
[service][google.cloud.scheduler.v1beta1.AppEngineRouting.service]

* `version =`
[version][google.cloud.scheduler.v1beta1.AppEngineRouting.version]

* `version_dot_service =`
  [version][google.cloud.scheduler.v1beta1.AppEngineRouting.version] `+ '.'
  +` [service][google.cloud.scheduler.v1beta1.AppEngineRouting.service]

* `instance =`
[instance][google.cloud.scheduler.v1beta1.AppEngineRouting.instance]

* `instance_dot_service =`
  [instance][google.cloud.scheduler.v1beta1.AppEngineRouting.instance] `+
  '.' +` [service][google.cloud.scheduler.v1beta1.AppEngineRouting.service]

* `instance_dot_version =`
  [instance][google.cloud.scheduler.v1beta1.AppEngineRouting.instance] `+
  '.' +` [version][google.cloud.scheduler.v1beta1.AppEngineRouting.version]

* `instance_dot_version_dot_service =`
  [instance][google.cloud.scheduler.v1beta1.AppEngineRouting.instance] `+
  '.' +` [version][google.cloud.scheduler.v1beta1.AppEngineRouting.version]
  `+ '.' +`
  [service][google.cloud.scheduler.v1beta1.AppEngineRouting.service]


If [service][google.cloud.scheduler.v1beta1.AppEngineRouting.service] is
empty, then the job will be sent to the service which is the default
service when the job is attempted.

If [version][google.cloud.scheduler.v1beta1.AppEngineRouting.version] is
empty, then the job will be sent to the version which is the default
version when the job is attempted.

If [instance][google.cloud.scheduler.v1beta1.AppEngineRouting.instance] is
empty, then the job will be sent to an instance which is available when the
job is attempted.

If [service][google.cloud.scheduler.v1beta1.AppEngineRouting.service],
[version][google.cloud.scheduler.v1beta1.AppEngineRouting.version], or
[instance][google.cloud.scheduler.v1beta1.AppEngineRouting.instance] is
invalid, then the job will be sent to the default version of the default
service when the job is attempted.

=back

=head2 Google::Cloud::Scheduler::V1beta1::Target::OAuthToken

Contains information needed for generating an
[OAuth token](https://developers.google.com/identity/protocols/OAuth2).
This type of authorization should generally only be used when calling Google
APIs hosted on *.googleapis.com.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->service_account_email() >> / C<< $msg->service_account_email($value) >>

Type: C<String>

[Service account email](https://cloud.google.com/iam/docs/service-accounts)
to be used for generating OAuth token.
The service account must be within the same project as the job. The caller
must have iam.serviceAccounts.actAs permission for the service account.

=item * C<< $msg->scope() >> / C<< $msg->scope($value) >>

Type: C<String>

OAuth scope to be used for generating OAuth access token.
If not specified, "https://www.googleapis.com/auth/cloud-platform"
will be used.

=back

=head2 Google::Cloud::Scheduler::V1beta1::Target::OidcToken

Contains information needed for generating an
[OpenID Connect
token](https://developers.google.com/identity/protocols/OpenIDConnect).
This type of authorization can be used for many scenarios, including
calling Cloud Run, or endpoints where you intend to validate the token
yourself.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->service_account_email() >> / C<< $msg->service_account_email($value) >>

Type: C<String>

[Service account email](https://cloud.google.com/iam/docs/service-accounts)
to be used for generating OIDC token.
The service account must be within the same project as the job. The caller
must have iam.serviceAccounts.actAs permission for the service account.

=item * C<< $msg->audience() >> / C<< $msg->audience($value) >>

Type: C<String>

Audience to be used when generating OIDC token. If not specified, the URI
specified in target will be used.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Scheduler::V1beta1::Target::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
