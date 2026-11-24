package Google::Devtools::Testing::V1::ApplicationDetails;

use strict;
use warnings;

our $VERSION = '0.14';

use Protobuf::Message;
use Protobuf::DescriptorPool;
use Protobuf::Internal qw(:all);
use MIME::Base64;

BEGIN {
    eval { require Google::Api::Annotations };
    eval { require Google::Api::Client };
    eval { require Google::Api::FieldBehavior };
    eval { require Google::Devtools::Testing::V1::TestExecution };
    my $descriptor_b64 = <<'EOF';
CjRnb29nbGUvZGV2dG9vbHMvdGVzdGluZy92MS9hcHBsaWNhdGlvbl9kZXRhaWxzLnByb3Rv
Ehpnb29nbGUuZGV2dG9vbHMudGVzdGluZy52MRocZ29vZ2xlL2FwaS9hbm5vdGF0aW9ucy5w
cm90bxoXZ29vZ2xlL2FwaS9jbGllbnQucHJvdG8aH2dvb2dsZS9hcGkvZmllbGRfYmVoYXZp
b3IucHJvdG8aL2dvb2dsZS9kZXZ0b29scy90ZXN0aW5nL3YxL3Rlc3RfZXhlY3V0aW9uLnBy
b3RvIlcKCUFwa0RldGFpbBJKCgxhcGtfbWFuaWZlc3QYASABKAsyJy5nb29nbGUuZGV2dG9v
bHMudGVzdGluZy52MS5BcGtNYW5pZmVzdFILYXBrTWFuaWZlc3QiywUKC0Fwa01hbmlmZXN0
EiEKDHBhY2thZ2VfbmFtZRgBIAEoCVILcGFja2FnZU5hbWUSJgoPbWluX3Nka192ZXJzaW9u
GAIgASgFUg1taW5TZGtWZXJzaW9uEiYKD21heF9zZGtfdmVyc2lvbhgDIAEoBVINbWF4U2Rr
VmVyc2lvbhIsChJ0YXJnZXRfc2RrX3ZlcnNpb24YBiABKAVSEHRhcmdldFNka1ZlcnNpb24S
KwoRYXBwbGljYXRpb25fbGFiZWwYBCABKAlSEGFwcGxpY2F0aW9uTGFiZWwSTwoOaW50ZW50
X2ZpbHRlcnMYBSADKAsyKC5nb29nbGUuZGV2dG9vbHMudGVzdGluZy52MS5JbnRlbnRGaWx0
ZXJSDWludGVudEZpbHRlcnMSXwoUdXNlc19wZXJtaXNzaW9uX3RhZ3MYDSADKAsyLS5nb29n
bGUuZGV2dG9vbHMudGVzdGluZy52MS5Vc2VzUGVybWlzc2lvblRhZ1ISdXNlc1Blcm1pc3Np
b25UYWdzEicKD3VzZXNfcGVybWlzc2lvbhgHIAMoCVIOdXNlc1Blcm1pc3Npb24SIQoMdmVy
c2lvbl9jb2RlGAggASgDUgt2ZXJzaW9uQ29kZRIhCgx2ZXJzaW9uX25hbWUYCSABKAlSC3Zl
cnNpb25OYW1lEkAKCG1ldGFkYXRhGAogAygLMiQuZ29vZ2xlLmRldnRvb2xzLnRlc3Rpbmcu
djEuTWV0YWRhdGFSCG1ldGFkYXRhEkoKDHVzZXNfZmVhdHVyZRgLIAMoCzInLmdvb2dsZS5k
ZXZ0b29scy50ZXN0aW5nLnYxLlVzZXNGZWF0dXJlUgt1c2VzRmVhdHVyZRI/CghzZXJ2aWNl
cxgMIAMoCzIjLmdvb2dsZS5kZXZ0b29scy50ZXN0aW5nLnYxLlNlcnZpY2VSCHNlcnZpY2Vz
Ik8KEVVzZXNQZXJtaXNzaW9uVGFnEhIKBG5hbWUYASABKAlSBG5hbWUSJgoPbWF4X3Nka192
ZXJzaW9uGAIgASgFUg1tYXhTZGtWZXJzaW9uImwKB1NlcnZpY2USEgoEbmFtZRgBIAEoCVIE
bmFtZRJNCg1pbnRlbnRfZmlsdGVyGAIgAygLMiguZ29vZ2xlLmRldnRvb2xzLnRlc3Rpbmcu
djEuSW50ZW50RmlsdGVyUgxpbnRlbnRGaWx0ZXIidQoMSW50ZW50RmlsdGVyEiEKDGFjdGlv
bl9uYW1lcxgBIAMoCVILYWN0aW9uTmFtZXMSJQoOY2F0ZWdvcnlfbmFtZXMYAiADKAlSDWNh
dGVnb3J5TmFtZXMSGwoJbWltZV90eXBlGAMgASgJUghtaW1lVHlwZSI0CghNZXRhZGF0YRIS
CgRuYW1lGAEgASgJUgRuYW1lEhQKBXZhbHVlGAIgASgJUgV2YWx1ZSJCCgtVc2VzRmVhdHVy
ZRISCgRuYW1lGAEgASgJUgRuYW1lEh8KC2lzX3JlcXVpcmVkGAIgASgIUgppc1JlcXVpcmVk
IrsBChRHZXRBcGtEZXRhaWxzUmVxdWVzdBJKCghsb2NhdGlvbhgBIAEoCzIpLmdvb2dsZS5k
ZXZ0b29scy50ZXN0aW5nLnYxLkZpbGVSZWZlcmVuY2VCA+BBAVIIbG9jYXRpb24SVwoPYnVu
ZGxlX2xvY2F0aW9uGAIgASgLMikuZ29vZ2xlLmRldnRvb2xzLnRlc3RpbmcudjEuRmlsZVJl
ZmVyZW5jZUID4EEBUg5idW5kbGVMb2NhdGlvbiJdChVHZXRBcGtEZXRhaWxzUmVzcG9uc2US
RAoKYXBrX2RldGFpbBgBIAEoCzIlLmdvb2dsZS5kZXZ0b29scy50ZXN0aW5nLnYxLkFwa0Rl
dGFpbFIJYXBrRGV0YWlsMpsCChhBcHBsaWNhdGlvbkRldGFpbFNlcnZpY2USsgEKDUdldEFw
a0RldGFpbHMSMC5nb29nbGUuZGV2dG9vbHMudGVzdGluZy52MS5HZXRBcGtEZXRhaWxzUmVx
dWVzdBoxLmdvb2dsZS5kZXZ0b29scy50ZXN0aW5nLnYxLkdldEFwa0RldGFpbHNSZXNwb25z
ZSI8gtPkkwI2IiovdjEvYXBwbGljYXRpb25EZXRhaWxTZXJ2aWNlL2dldEFwa0RldGFpbHM6
CGxvY2F0aW9uGkrKQRZ0ZXN0aW5nLmdvb2dsZWFwaXMuY29t0kEuaHR0cHM6Ly93d3cuZ29v
Z2xlYXBpcy5jb20vYXV0aC9jbG91ZC1wbGF0Zm9ybUJ9Ch5jb20uZ29vZ2xlLmRldnRvb2xz
LnRlc3RpbmcudjFCFkFwcGxpY2F0aW9uRGV0YWlsUHJvdG9QAVpBZ29vZ2xlLmdvbGFuZy5v
cmcvZ2VucHJvdG8vZ29vZ2xlYXBpcy9kZXZ0b29scy90ZXN0aW5nL3YxO3Rlc3RpbmdK0CcK
BxIFDgCeAQEKvAQKAQwSAw4AEjKxBCBDb3B5cmlnaHQgMjAyNSBHb29nbGUgTExDCgogTGlj
ZW5zZWQgdW5kZXIgdGhlIEFwYWNoZSBMaWNlbnNlLCBWZXJzaW9uIDIuMCAodGhlICJMaWNl
bnNlIik7CiB5b3UgbWF5IG5vdCB1c2UgdGhpcyBmaWxlIGV4Y2VwdCBpbiBjb21wbGlhbmNl
IHdpdGggdGhlIExpY2Vuc2UuCiBZb3UgbWF5IG9idGFpbiBhIGNvcHkgb2YgdGhlIExpY2Vu
c2UgYXQKCiAgICAgaHR0cDovL3d3dy5hcGFjaGUub3JnL2xpY2Vuc2VzL0xJQ0VOU0UtMi4w
CgogVW5sZXNzIHJlcXVpcmVkIGJ5IGFwcGxpY2FibGUgbGF3IG9yIGFncmVlZCB0byBpbiB3
cml0aW5nLCBzb2Z0d2FyZQogZGlzdHJpYnV0ZWQgdW5kZXIgdGhlIExpY2Vuc2UgaXMgZGlz
dHJpYnV0ZWQgb24gYW4gIkFTIElTIiBCQVNJUywKIFdJVEhPVVQgV0FSUkFOVElFUyBPUiBD
T05ESVRJT05TIE9GIEFOWSBLSU5ELCBlaXRoZXIgZXhwcmVzcyBvciBpbXBsaWVkLgogU2Vl
IHRoZSBMaWNlbnNlIGZvciB0aGUgc3BlY2lmaWMgbGFuZ3VhZ2UgZ292ZXJuaW5nIHBlcm1p
c3Npb25zIGFuZAogbGltaXRhdGlvbnMgdW5kZXIgdGhlIExpY2Vuc2UuCgoICgECEgMQACMK
CQoCAwASAxIAJgoJCgIDARIDEwAhCgkKAgMCEgMUACkKCQoCAwMSAxUAOQoICgEIEgMXAFgK
CQoCCAsSAxcAWAoICgEIEgMYACIKCQoCCAoSAxgAIgoICgEIEgMZADcKCQoCCAgSAxkANwoI
CgEIEgMaADcKCQoCCAESAxoANwp6CgIGABIEHgAqARpuIEEgc2VydmljZSB3aGljaCBwYXJz
ZXMgaW5wdXQgYXBwbGljYXRpb25zIGFuZCByZXR1cm5zIGRldGFpbHMgdGhhdCBjYW4gYmUK
IHVzZWZ1bCBpbiB0aGUgY29udGV4dCBvZiB0ZXN0aW5nLgoKCgoDBgABEgMeCCAKCgoDBgAD
EgMfAj4KDAoFBgADmQgSAx8CPgoLCgMGAAMSBCACITcKDQoFBgADmggSBCACITcKPwoEBgAC
ABIEJAIpAxoxIEdldHMgdGhlIGRldGFpbHMgb2YgYW4gQW5kcm9pZCBhcHBsaWNhdGlvbiBB
UEsuCgoMCgUGAAIAARIDJAYTCgwKBQYAAgACEgMkFCgKDAoFBgACAAMSAyQzSAoNCgUGAAIA
BBIEJQQoBgoRCgkGAAIABLDKvCISBCUEKAYKXgoCBAASBC4AMAEaUiBBbmRyb2lkIGFwcGxp
Y2F0aW9uIGRldGFpbHMgYmFzZWQgb24gYXBwbGljYXRpb24gbWFuaWZlc3QgYW5kIGFyY2hp
dmUKIGNvbnRlbnRzLgoKCgoDBAABEgMuCBEKCwoEBAACABIDLwIfCgwKBQQAAgAGEgMvAg0K
DAoFBAACAAESAy8OGgoMCgUEAAIAAxIDLx0eCnIKAgQBEgQ0AFoBGmYgQW4gQW5kcm9pZCBh
cHAgbWFuaWZlc3QuIFNlZQogaHR0cDovL2RldmVsb3Blci5hbmRyb2lkLmNvbS9ndWlkZS90
b3BpY3MvbWFuaWZlc3QvbWFuaWZlc3QtaW50cm8uaHRtbAoKCgoDBAEBEgM0CBMKWgoEBAEC
ABIDNwIaGk0gRnVsbCBKYXZhLXN0eWxlIHBhY2thZ2UgbmFtZSBmb3IgdGhpcyBhcHBsaWNh
dGlvbiwgZS5nLgogImNvbS5leGFtcGxlLmZvbyIuCgoMCgUEAQIABRIDNwIICgwKBQQBAgAB
EgM3CRUKDAoFBAECAAMSAzcYGQpFCgQEAQIBEgM6AhwaOCBNaW5pbXVtIEFQSSBsZXZlbCBy
ZXF1aXJlZCBmb3IgdGhlIGFwcGxpY2F0aW9uIHRvIHJ1bi4KCgwKBQQBAgEFEgM6AgcKDAoF
BAECAQESAzoIFwoMCgUEAQIBAxIDOhobCk0KBAQBAgISAz0CHBpAIE1heGltdW0gQVBJIGxl
dmVsIG9uIHdoaWNoIHRoZSBhcHBsaWNhdGlvbiBpcyBkZXNpZ25lZCB0byBydW4uCgoMCgUE
AQICBRIDPQIHCgwKBQQBAgIBEgM9CBcKDAoFBAECAgMSAz0aGwpTCgQEAQIDEgNAAh8aRiBT
cGVjaWZpZXMgdGhlIEFQSSBMZXZlbCBvbiB3aGljaCB0aGUgYXBwbGljYXRpb24gaXMgZGVz
aWduZWQgdG8gcnVuLgoKDAoFBAECAwUSA0ACBwoMCgUEAQIDARIDQAgaCgwKBQQBAgMDEgNA
HR4KNgoEBAECBBIDQwIfGikgVXNlci1yZWFkYWJsZSBuYW1lIGZvciB0aGUgYXBwbGljYXRp
b24uCgoMCgUEAQIEBRIDQwIICgwKBQQBAgQBEgNDCRoKDAoFBAECBAMSA0MdHgoLCgQEAQIF
EgNFAisKDAoFBAECBQQSA0UCCgoMCgUEAQIFBhIDRQsXCgwKBQQBAgUBEgNFGCYKDAoFBAEC
BQMSA0UpKgpBCgQEAQIGEgNIAjcaNCBQZXJtaXNzaW9ucyBkZWNsYXJlZCB0byBiZSB1c2Vk
IGJ5IHRoZSBhcHBsaWNhdGlvbgoKDAoFBAECBgQSA0gCCgoMCgUEAQIGBhIDSAscCgwKBQQB
AgYBEgNIHTEKDAoFBAECBgMSA0g0NgoLCgQEAQIHEgNKAiYKDAoFBAECBwQSA0oCCgoMCgUE
AQIHBRIDSgsRCgwKBQQBAgcBEgNKEiEKDAoFBAECBwMSA0okJQo5CgQEAQIIEgNNAhkaLCBW
ZXJzaW9uIG51bWJlciB1c2VkIGludGVybmFsbHkgYnkgdGhlIGFwcC4KCgwKBQQBAggFEgNN
AgcKDAoFBAECCAESA00IFAoMCgUEAQIIAxIDTRcYCi0KBAQBAgkSA1ACGhogIFZlcnNpb24g
bnVtYmVyIHNob3duIHRvIHVzZXJzLgoKDAoFBAECCQUSA1ACCAoMCgUEAQIJARIDUAkVCgwK
BQQBAgkDEgNQGBkKNgoEBAECChIDUwIiGikgTWV0YS1kYXRhIHRhZ3MgZGVmaW5lZCBpbiB0
aGUgbWFuaWZlc3QuCgoMCgUEAQIKBBIDUwIKCgwKBQQBAgoGEgNTCxMKDAoFBAECCgESA1MU
HAoMCgUEAQIKAxIDUx8hCjoKBAQBAgsSA1YCKRotIEZlYXR1cmUgdXNhZ2UgdGFncyBkZWZp
bmVkIGluIHRoZSBtYW5pZmVzdC4KCgwKBQQBAgsEEgNWAgoKDAoFBAECCwYSA1YLFgoMCgUE
AQILARIDVhcjCgwKBQQBAgsDEgNWJigKOwoEBAECDBIDWQIhGi4gU2VydmljZXMgY29udGFp
bmVkIGluIHRoZSA8YXBwbGljYXRpb24+IHRhZy4KCgwKBQQBAgwEEgNZAgoKDAoFBAECDAYS
A1kLEgoMCgUEAQIMARIDWRMbCgwKBQQBAgwDEgNZHiAKjQEKAgQCEgReAGQBGoABIFRoZSA8
dXNlcy1wZXJtaXNzaW9uPiB0YWcgd2l0aGluIGEgbWFuaWZlc3QuCiBodHRwczovL2RldmVs
b3Blci5hbmRyb2lkLmNvbS9ndWlkZS90b3BpY3MvbWFuaWZlc3QvdXNlcy1wZXJtaXNzaW9u
LWVsZW1lbnQuaHRtbAoKCgoDBAIBEgNeCBkKJQoEBAICABIDYAISGhggVGhlIGFuZHJvaWQ6
bmFtZSB2YWx1ZQoKDAoFBAICAAUSA2ACCAoMCgUEAgIAARIDYAkNCgwKBQQCAgADEgNgEBEK
JQoEBAICARIDYwIcGhggVGhlIGFuZHJvaWQ6bmFtZSB2YWx1ZQoKDAoFBAICAQUSA2MCBwoM
CgUEAgIBARIDYwgXCgwKBQQCAgEDEgNjGhsKgQEKAgQDEgRoAG4BGnUgVGhlIDxzZXJ2aWNl
PiBzZWN0aW9uIG9mIGFuIDxhcHBsaWNhdGlvbj4gdGFnLgogaHR0cHM6Ly9kZXZlbG9wZXIu
YW5kcm9pZC5jb20vZ3VpZGUvdG9waWNzL21hbmlmZXN0L3NlcnZpY2UtZWxlbWVudAoKCgoD
BAMBEgNoCA8KJQoEBAMCABIDagISGhggVGhlIGFuZHJvaWQ6bmFtZSB2YWx1ZQoKDAoFBAMC
AAUSA2oCCAoMCgUEAwIAARIDagkNCgwKBQQDAgADEgNqEBEKLAoEBAMCARIDbQIqGh8gSW50
ZW50IGZpbHRlcnMgaW4gdGhlIHNlcnZpY2UKCgwKBQQDAgEEEgNtAgoKDAoFBAMCAQYSA20L
FwoMCgUEAwIBARIDbRglCgwKBQQDAgEDEgNtKCkKkAEKAgQEEgRyAHsBGoMBIFRoZSA8aW50
ZW50LWZpbHRlcj4gc2VjdGlvbiBvZiBhbiA8YWN0aXZpdHk+IHRhZy4KIGh0dHBzOi8vZGV2
ZWxvcGVyLmFuZHJvaWQuY29tL2d1aWRlL3RvcGljcy9tYW5pZmVzdC9pbnRlbnQtZmlsdGVy
LWVsZW1lbnQuaHRtbAoKCgoDBAQBEgNyCBQKOgoEBAQCABIDdAIjGi0gVGhlIGFuZHJvaWQ6
bmFtZSB2YWx1ZSBvZiB0aGUgPGFjdGlvbj4gdGFnLgoKDAoFBAQCAAQSA3QCCgoMCgUEBAIA
BRIDdAsRCgwKBQQEAgABEgN0Eh4KDAoFBAQCAAMSA3QhIgo8CgQEBAIBEgN3AiUaLyBUaGUg
YW5kcm9pZDpuYW1lIHZhbHVlIG9mIHRoZSA8Y2F0ZWdvcnk+IHRhZy4KCgwKBQQEAgEEEgN3
AgoKDAoFBAQCAQUSA3cLEQoMCgUEBAIBARIDdxIgCgwKBQQEAgEDEgN3IyQKPAoEBAQCAhID
egIXGi8gVGhlIGFuZHJvaWQ6bWltZVR5cGUgdmFsdWUgb2YgdGhlIDxkYXRhPiB0YWcuCgoM
CgUEBAICBRIDegIICgwKBQQEAgIBEgN6CRIKDAoFBAQCAgMSA3oVFgp/CgIEBRIFfwCFAQEa
ciBBIDxtZXRhLWRhdGE+IHRhZyB3aXRoaW4gYSBtYW5pZmVzdC4KIGh0dHBzOi8vZGV2ZWxv
cGVyLmFuZHJvaWQuY29tL2d1aWRlL3RvcGljcy9tYW5pZmVzdC9tZXRhLWRhdGEtZWxlbWVu
dC5odG1sCgoKCgMEBQESA38IEAomCgQEBQIAEgSBAQISGhggVGhlIGFuZHJvaWQ6bmFtZSB2
YWx1ZQoKDQoFBAUCAAUSBIEBAggKDQoFBAUCAAESBIEBCQ0KDQoFBAUCAAMSBIEBEBEKJwoE
BAUCARIEhAECExoZIFRoZSBhbmRyb2lkOnZhbHVlIHZhbHVlCgoNCgUEBQIBBRIEhAECCAoN
CgUEBQIBARIEhAEJDgoNCgUEBQIBAxIEhAEREgqGAQoCBAYSBokBAI8BARp4IEEgPHVzZXMt
ZmVhdHVyZT4gdGFnIHdpdGhpbiBhIG1hbmlmZXN0LgogaHR0cHM6Ly9kZXZlbG9wZXIuYW5k
cm9pZC5jb20vZ3VpZGUvdG9waWNzL21hbmlmZXN0L3VzZXMtZmVhdHVyZS1lbGVtZW50Lmh0
bWwKCgsKAwQGARIEiQEIEwomCgQEBgIAEgSLAQISGhggVGhlIGFuZHJvaWQ6bmFtZSB2YWx1
ZQoKDQoFBAYCAAUSBIsBAggKDQoFBAYCAAESBIsBCQ0KDQoFBAYCAAMSBIsBEBEKKgoEBAYC
ARIEjgECFxocIFRoZSBhbmRyb2lkOnJlcXVpcmVkIHZhbHVlCgoNCgUEBgIBBRIEjgECBgoN
CgUEBgIBARIEjgEHEgoNCgUEBgIBAxIEjgEVFgpHCgIEBxIGkgEAmAEBGjkgQSByZXF1ZXN0
IHRvIGdldCB0aGUgZGV0YWlscyBvZiBhbiBBbmRyb2lkIGFwcGxpY2F0aW9uLgoKCwoDBAcB
EgSSAQgcCjsKBAQHAgASBJQBAkYaLSBPcHRpb25hbC4gVGhlIEFQSyB0byBiZSBwYXJzZWQg
Zm9yIGRldGFpbHMuCgoNCgUEBwIABhIElAECDwoNCgUEBwIAARIElAEQGAoNCgUEBwIAAxIE
lAEbHAoNCgUEBwIACBIElAEdRQoQCggEBwIACJwIABIElAEeRApCCgQEBwIBEgSXAQJNGjQg
T3B0aW9uYWwuIFRoZSBBcHAgQnVuZGxlIHRvIGJlIHBhcnNlZCBmb3IgZGV0YWlscy4KCg0K
BQQHAgEGEgSXAQIPCg0KBQQHAgEBEgSXARAfCg0KBQQHAgEDEgSXASIjCg0KBQQHAgEIEgSX
ASRMChAKCAQHAgEInAgAEgSXASVLClUKAgQIEgabAQCeAQEaRyBSZXNwb25zZSBjb250YWlu
aW5nIHRoZSBkZXRhaWxzIG9mIHRoZSBzcGVjaWZpZWQgQW5kcm9pZCBhcHBsaWNhdGlvbi4K
CgsKAwQIARIEmwEIHQorCgQECAIAEgSdAQIbGh0gRGV0YWlscyBvZiB0aGUgQW5kcm9pZCBB
cHAuCgoNCgUECAIABhIEnQECCwoNCgUECAIAARIEnQEMFgoNCgUECAIAAxIEnQEZGmIGcHJv
dG8z
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Devtools::Testing::V1::ApplicationDetails::ApkDetail ===
    # Fields for ApkDetail
    # Field: apk_manifest Type: 11 (.google.devtools.testing.v1.ApkManifest)

# === Message: Google::Devtools::Testing::V1::ApplicationDetails::ApkManifest ===
    # Fields for ApkManifest
    # Field: package_name Type: 9 ()
    # Field: min_sdk_version Type: 5 ()
    # Field: max_sdk_version Type: 5 ()
    # Field: target_sdk_version Type: 5 ()
    # Field: application_label Type: 9 ()
    # Field: intent_filters Type: 11 (.google.devtools.testing.v1.IntentFilter)
    # Field: uses_permission_tags Type: 11 (.google.devtools.testing.v1.UsesPermissionTag)
    # Field: uses_permission Type: 9 ()
    # Field: version_code Type: 3 ()
    # Field: version_name Type: 9 ()
    # Field: metadata Type: 11 (.google.devtools.testing.v1.Metadata)
    # Field: uses_feature Type: 11 (.google.devtools.testing.v1.UsesFeature)
    # Field: services Type: 11 (.google.devtools.testing.v1.Service)

# === Message: Google::Devtools::Testing::V1::ApplicationDetails::UsesPermissionTag ===
    # Fields for UsesPermissionTag
    # Field: name Type: 9 ()
    # Field: max_sdk_version Type: 5 ()

# === Message: Google::Devtools::Testing::V1::ApplicationDetails::Service ===
    # Fields for Service
    # Field: name Type: 9 ()
    # Field: intent_filter Type: 11 (.google.devtools.testing.v1.IntentFilter)

# === Message: Google::Devtools::Testing::V1::ApplicationDetails::IntentFilter ===
    # Fields for IntentFilter
    # Field: action_names Type: 9 ()
    # Field: category_names Type: 9 ()
    # Field: mime_type Type: 9 ()

# === Message: Google::Devtools::Testing::V1::ApplicationDetails::Metadata ===
    # Fields for Metadata
    # Field: name Type: 9 ()
    # Field: value Type: 9 ()

# === Message: Google::Devtools::Testing::V1::ApplicationDetails::UsesFeature ===
    # Fields for UsesFeature
    # Field: name Type: 9 ()
    # Field: is_required Type: 8 ()

# === Message: Google::Devtools::Testing::V1::ApplicationDetails::GetApkDetailsRequest ===
    # Fields for GetApkDetailsRequest
    # Field: location Type: 11 (.google.devtools.testing.v1.FileReference)
    # Field: bundle_location Type: 11 (.google.devtools.testing.v1.FileReference)

# === Message: Google::Devtools::Testing::V1::ApplicationDetails::GetApkDetailsResponse ===
    # Fields for GetApkDetailsResponse
    # Field: apk_detail Type: 11 (.google.devtools.testing.v1.ApkDetail)

# === Service Client: Google::Devtools::Testing::V1::ApplicationDetails::ApplicationDetailServiceClient ===
package Google::Devtools::Testing::V1::ApplicationDetails::ApplicationDetailServiceClient;

=pod

=head2 Service Client: Google::Devtools::Testing::V1::ApplicationDetails::ApplicationDetailServiceClient

Client stub representing the remote C<ApplicationDetailService> gRPC service. Delegates call dispatching to L<Google::gRPC::Client>.

=head3 target

The endpoint target address. Defaults to C<devtools.googleapis.com:443>.

=head3 credentials

The authentication credentials provider. Defaults to application default credentials via L<Google::Auth>.

=cut

use Moo;
use Google::Auth;
use Google::gRPC::Client;

has credentials => ( is => 'ro', default => sub { Google::Auth->default() } );
has target      => ( is => 'ro', default => 'devtools.googleapis.com:443' );

has _grpc_client => (
    is => 'ro',
    lazy => 1,
    builder => sub {
        my $self = shift;
        return Google::gRPC::Client->new(
            target     => $self->target,
            auth_token => $self->credentials->get_token(),
        );
    }
);

sub get_apk_details {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Devtools::Testing::V1::ApplicationDetails::GetApkDetailsRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.devtools.testing.v1.ApplicationDetailService',
        method         => 'GetApkDetails',
        request        => $req,
        response_class => 'Google::Devtools::Testing::V1::ApplicationDetails::GetApkDetailsResponse',
    });
}

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Devtools::Testing::V1::ApplicationDetails - Compiled Protocol Buffers messages for google/devtools/testing/v1/application_details.proto

=head1 SYNOPSIS

    use Google::Devtools::Testing::V1::ApplicationDetails;

    my $msg = Google::Devtools::Testing::V1::ApplicationDetails::ApkDetail->new({
        apk_manifest => $apk_manifest,
    });

    # Read or update a field
    my $val = $msg->apk_manifest();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Devtools::Testing::V1::ApplicationDetails::ApkDetail->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/devtools/testing/v1/application_details.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Devtools::Testing::V1::ApplicationDetails::ApkDetail

Android application details based on application manifest and archive
contents.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->apk_manifest() >> / C<< $msg->apk_manifest($value) >>

Type: C<Message> (L<Google::Devtools::Testing::V1::ApplicationDetails::ApkManifest>)

=back

=head2 Google::Devtools::Testing::V1::ApplicationDetails::ApkManifest

An Android app manifest. See
http://developer.android.com/guide/topics/manifest/manifest-intro.html

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->package_name() >> / C<< $msg->package_name($value) >>

Type: C<String>

Full Java-style package name for this application, e.g.
"com.example.foo".

=item * C<< $msg->min_sdk_version() >> / C<< $msg->min_sdk_version($value) >>

Type: C<Int32>

Minimum API level required for the application to run.

=item * C<< $msg->max_sdk_version() >> / C<< $msg->max_sdk_version($value) >>

Type: C<Int32>

Maximum API level on which the application is designed to run.

=item * C<< $msg->target_sdk_version() >> / C<< $msg->target_sdk_version($value) >>

Type: C<Int32>

Specifies the API Level on which the application is designed to run.

=item * C<< $msg->application_label() >> / C<< $msg->application_label($value) >>

Type: C<String>

User-readable name for the application.

=item * C<< $msg->intent_filters() >> / C<< $msg->intent_filters($value) >>

Type: C<Message> (L<Google::Devtools::Testing::V1::ApplicationDetails::IntentFilter>)

=item * C<< $msg->uses_permission_tags() >> / C<< $msg->uses_permission_tags($value) >>

Type: C<Message> (L<Google::Devtools::Testing::V1::ApplicationDetails::UsesPermissionTag>)

Permissions declared to be used by the application

=item * C<< $msg->uses_permission() >> / C<< $msg->uses_permission($value) >>

Type: C<String>

=item * C<< $msg->version_code() >> / C<< $msg->version_code($value) >>

Type: C<Int64>

Version number used internally by the app.

=item * C<< $msg->version_name() >> / C<< $msg->version_name($value) >>

Type: C<String>

Version number shown to users.

=item * C<< $msg->metadata() >> / C<< $msg->metadata($value) >>

Type: C<Message> (L<Google::Devtools::Testing::V1::ApplicationDetails::Metadata>)

Meta-data tags defined in the manifest.

=item * C<< $msg->uses_feature() >> / C<< $msg->uses_feature($value) >>

Type: C<Message> (L<Google::Devtools::Testing::V1::ApplicationDetails::UsesFeature>)

Feature usage tags defined in the manifest.

=item * C<< $msg->services() >> / C<< $msg->services($value) >>

Type: C<Message> (L<Google::Devtools::Testing::V1::ApplicationDetails::Service>)

Services contained in the <application> tag.

=back

=head2 Google::Devtools::Testing::V1::ApplicationDetails::UsesPermissionTag

The <uses-permission> tag within a manifest.
https://developer.android.com/guide/topics/manifest/uses-permission-element.html

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

The android:name value

=item * C<< $msg->max_sdk_version() >> / C<< $msg->max_sdk_version($value) >>

Type: C<Int32>

The android:name value

=back

=head2 Google::Devtools::Testing::V1::ApplicationDetails::Service

The <service> section of an <application> tag.
https://developer.android.com/guide/topics/manifest/service-element

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

The android:name value

=item * C<< $msg->intent_filter() >> / C<< $msg->intent_filter($value) >>

Type: C<Message> (L<Google::Devtools::Testing::V1::ApplicationDetails::IntentFilter>)

Intent filters in the service

=back

=head2 Google::Devtools::Testing::V1::ApplicationDetails::IntentFilter

The <intent-filter> section of an <activity> tag.
https://developer.android.com/guide/topics/manifest/intent-filter-element.html

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->action_names() >> / C<< $msg->action_names($value) >>

Type: C<String>

The android:name value of the <action> tag.

=item * C<< $msg->category_names() >> / C<< $msg->category_names($value) >>

Type: C<String>

The android:name value of the <category> tag.

=item * C<< $msg->mime_type() >> / C<< $msg->mime_type($value) >>

Type: C<String>

The android:mimeType value of the <data> tag.

=back

=head2 Google::Devtools::Testing::V1::ApplicationDetails::Metadata

A <meta-data> tag within a manifest.
https://developer.android.com/guide/topics/manifest/meta-data-element.html

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

The android:name value

=item * C<< $msg->value() >> / C<< $msg->value($value) >>

Type: C<String>

The android:value value

=back

=head2 Google::Devtools::Testing::V1::ApplicationDetails::UsesFeature

A <uses-feature> tag within a manifest.
https://developer.android.com/guide/topics/manifest/uses-feature-element.html

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

The android:name value

=item * C<< $msg->is_required() >> / C<< $msg->is_required($value) >>

Type: C<Bool>

The android:required value

=back

=head2 Google::Devtools::Testing::V1::ApplicationDetails::GetApkDetailsRequest

A request to get the details of an Android application.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->location() >> / C<< $msg->location($value) >>

Type: C<Message> (L<Google::Devtools::Testing::V1::TestExecution::FileReference>)

Optional. The APK to be parsed for details.

=item * C<< $msg->bundle_location() >> / C<< $msg->bundle_location($value) >>

Type: C<Message> (L<Google::Devtools::Testing::V1::TestExecution::FileReference>)

Optional. The App Bundle to be parsed for details.

=back

=head2 Google::Devtools::Testing::V1::ApplicationDetails::GetApkDetailsResponse

Response containing the details of the specified Android application.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->apk_detail() >> / C<< $msg->apk_detail($value) >>

Type: C<Message> (L<Google::Devtools::Testing::V1::ApplicationDetails::ApkDetail>)

Details of the Android App.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Devtools::Testing::V1::ApplicationDetails::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
