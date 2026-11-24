package Google::Cloud::Automl::V1::Image;

use strict;
use warnings;

our $VERSION = '0.14';

use Protobuf::Message;
use Protobuf::DescriptorPool;
use Protobuf::Internal qw(:all);
use MIME::Base64;

BEGIN {
    eval { require Google::Api::FieldBehavior };
    eval { require Google::Cloud::Automl::V1::Classification };
    my $descriptor_b64 = <<'EOF';
CiJnb29nbGUvY2xvdWQvYXV0b21sL3YxL2ltYWdlLnByb3RvEhZnb29nbGUuY2xvdWQuYXV0
b21sLnYxGh9nb29nbGUvYXBpL2ZpZWxkX2JlaGF2aW9yLnByb3RvGitnb29nbGUvY2xvdWQv
YXV0b21sL3YxL2NsYXNzaWZpY2F0aW9uLnByb3RvIoYBCiJJbWFnZUNsYXNzaWZpY2F0aW9u
RGF0YXNldE1ldGFkYXRhEmAKE2NsYXNzaWZpY2F0aW9uX3R5cGUYASABKA4yKi5nb29nbGUu
Y2xvdWQuYXV0b21sLnYxLkNsYXNzaWZpY2F0aW9uVHlwZUID4EECUhJjbGFzc2lmaWNhdGlv
blR5cGUiJQojSW1hZ2VPYmplY3REZXRlY3Rpb25EYXRhc2V0TWV0YWRhdGEi4wIKIEltYWdl
Q2xhc3NpZmljYXRpb25Nb2RlbE1ldGFkYXRhEicKDWJhc2VfbW9kZWxfaWQYASABKAlCA+BB
AVILYmFzZU1vZGVsSWQSRQoddHJhaW5fYnVkZ2V0X21pbGxpX25vZGVfaG91cnMYECABKANC
A+BBAVIZdHJhaW5CdWRnZXRNaWxsaU5vZGVIb3VycxJBCht0cmFpbl9jb3N0X21pbGxpX25v
ZGVfaG91cnMYESABKANCA+BBA1IXdHJhaW5Db3N0TWlsbGlOb2RlSG91cnMSJAoLc3RvcF9y
ZWFzb24YBSABKAlCA+BBA1IKc3RvcFJlYXNvbhIiCgptb2RlbF90eXBlGAcgASgJQgPgQQFS
CW1vZGVsVHlwZRIeCghub2RlX3FwcxgNIAEoAUID4EEDUgdub2RlUXBzEiIKCm5vZGVfY291
bnQYDiABKANCA+BBA1IJbm9kZUNvdW50IrsCCiFJbWFnZU9iamVjdERldGVjdGlvbk1vZGVs
TWV0YWRhdGESIgoKbW9kZWxfdHlwZRgBIAEoCUID4EEBUgltb2RlbFR5cGUSIgoKbm9kZV9j
b3VudBgDIAEoA0ID4EEDUglub2RlQ291bnQSHgoIbm9kZV9xcHMYBCABKAFCA+BBA1IHbm9k
ZVFwcxIkCgtzdG9wX3JlYXNvbhgFIAEoCUID4EEDUgpzdG9wUmVhc29uEkUKHXRyYWluX2J1
ZGdldF9taWxsaV9ub2RlX2hvdXJzGAYgASgDQgPgQQFSGXRyYWluQnVkZ2V0TWlsbGlOb2Rl
SG91cnMSQQobdHJhaW5fY29zdF9taWxsaV9ub2RlX2hvdXJzGAcgASgDQgPgQQNSF3RyYWlu
Q29zdE1pbGxpTm9kZUhvdXJzIlAKKkltYWdlQ2xhc3NpZmljYXRpb25Nb2RlbERlcGxveW1l
bnRNZXRhZGF0YRIiCgpub2RlX2NvdW50GAEgASgDQgPgQQRSCW5vZGVDb3VudCJRCitJbWFn
ZU9iamVjdERldGVjdGlvbk1vZGVsRGVwbG95bWVudE1ldGFkYXRhEiIKCm5vZGVfY291bnQY
ASABKANCA+BBBFIJbm9kZUNvdW50QqwBChpjb20uZ29vZ2xlLmNsb3VkLmF1dG9tbC52MUIK
SW1hZ2VQcm90b1ABWjJjbG91ZC5nb29nbGUuY29tL2dvL2F1dG9tbC9hcGl2MS9hdXRvbWxw
YjthdXRvbWxwYqoCFkdvb2dsZS5DbG91ZC5BdXRvTUwuVjHKAhZHb29nbGVcQ2xvdWRcQXV0
b01sXFYx6gIZR29vZ2xlOjpDbG91ZDo6QXV0b01MOjpWMUrsVAoHEgUOAMgBAQq8BAoBDBID
DgASMrEEIENvcHlyaWdodCAyMDI1IEdvb2dsZSBMTEMKCiBMaWNlbnNlZCB1bmRlciB0aGUg
QXBhY2hlIExpY2Vuc2UsIFZlcnNpb24gMi4wICh0aGUgIkxpY2Vuc2UiKTsKIHlvdSBtYXkg
bm90IHVzZSB0aGlzIGZpbGUgZXhjZXB0IGluIGNvbXBsaWFuY2Ugd2l0aCB0aGUgTGljZW5z
ZS4KIFlvdSBtYXkgb2J0YWluIGEgY29weSBvZiB0aGUgTGljZW5zZSBhdAoKICAgICBodHRw
Oi8vd3d3LmFwYWNoZS5vcmcvbGljZW5zZXMvTElDRU5TRS0yLjAKCiBVbmxlc3MgcmVxdWly
ZWQgYnkgYXBwbGljYWJsZSBsYXcgb3IgYWdyZWVkIHRvIGluIHdyaXRpbmcsIHNvZnR3YXJl
CiBkaXN0cmlidXRlZCB1bmRlciB0aGUgTGljZW5zZSBpcyBkaXN0cmlidXRlZCBvbiBhbiAi
QVMgSVMiIEJBU0lTLAogV0lUSE9VVCBXQVJSQU5USUVTIE9SIENPTkRJVElPTlMgT0YgQU5Z
IEtJTkQsIGVpdGhlciBleHByZXNzIG9yIGltcGxpZWQuCiBTZWUgdGhlIExpY2Vuc2UgZm9y
IHRoZSBzcGVjaWZpYyBsYW5ndWFnZSBnb3Zlcm5pbmcgcGVybWlzc2lvbnMgYW5kCiBsaW1p
dGF0aW9ucyB1bmRlciB0aGUgTGljZW5zZS4KCggKAQISAxAAHwoJCgIDABIDEgApCgkKAgMB
EgMTADUKCAoBCBIDFQAzCgkKAgglEgMVADMKCAoBCBIDFgBJCgkKAggLEgMWAEkKCAoBCBID
FwAiCgkKAggKEgMXACIKCAoBCBIDGAArCgkKAggIEgMYACsKCAoBCBIDGQAzCgkKAggBEgMZ
ADMKCAoBCBIDGgAzCgkKAggpEgMaADMKCAoBCBIDGwAyCgkKAggtEgMbADIKSAoCBAASBB4A
IQEaPCBEYXRhc2V0IG1ldGFkYXRhIHRoYXQgaXMgc3BlY2lmaWMgdG8gaW1hZ2UgY2xhc3Np
ZmljYXRpb24uCgoKCgMEAAESAx4IKgo8CgQEAAIAEgMgAlYaLyBSZXF1aXJlZC4gVHlwZSBv
ZiB0aGUgY2xhc3NpZmljYXRpb24gcHJvYmxlbS4KCgwKBQQAAgAGEgMgAhQKDAoFBAACAAES
AyAVKAoMCgUEAAIAAxIDICssCgwKBQQAAgAIEgMgLVUKDwoIBAACAAicCAASAyAuVApCCgIE
ARIEJAAmARo2IERhdGFzZXQgbWV0YWRhdGEgc3BlY2lmaWMgdG8gaW1hZ2Ugb2JqZWN0IGRl
dGVjdGlvbi4KCgoKAwQBARIDJAgrCjYKAgQCEgQpAHUBGiogTW9kZWwgbWV0YWRhdGEgZm9y
IGltYWdlIGNsYXNzaWZpY2F0aW9uLgoKCgoDBAIBEgMpCCgKtwIKBAQCAgASAy8CRBqpAiBP
cHRpb25hbC4gVGhlIElEIG9mIHRoZSBgYmFzZWAgbW9kZWwuIElmIGl0IGlzIHNwZWNpZmll
ZCwgdGhlIG5ldyBtb2RlbAogd2lsbCBiZSBjcmVhdGVkIGJhc2VkIG9uIHRoZSBgYmFzZWAg
bW9kZWwuIE90aGVyd2lzZSwgdGhlIG5ldyBtb2RlbCB3aWxsIGJlCiBjcmVhdGVkIGZyb20g
c2NyYXRjaC4gVGhlIGBiYXNlYCBtb2RlbCBtdXN0IGJlIGluIHRoZSBzYW1lCiBgcHJvamVj
dGAgYW5kIGBsb2NhdGlvbmAgYXMgdGhlIG5ldyBtb2RlbCB0byBjcmVhdGUsIGFuZCBoYXZl
IHRoZSBzYW1lCiBgbW9kZWxfdHlwZWAuCgoMCgUEAgIABRIDLwIICgwKBQQCAgABEgMvCRYK
DAoFBAICAAMSAy8ZGgoMCgUEAgIACBIDLxtDCg8KCAQCAgAInAgAEgMvHEIKrgcKBAQCAgES
Az8CVBqgByBPcHRpb25hbC4gVGhlIHRyYWluIGJ1ZGdldCBvZiBjcmVhdGluZyB0aGlzIG1v
ZGVsLCBleHByZXNzZWQgaW4gbWlsbGkgbm9kZQogaG91cnMgaS5lLiAxLDAwMCB2YWx1ZSBp
biB0aGlzIGZpZWxkIG1lYW5zIDEgbm9kZSBob3VyLiBUaGUgYWN0dWFsCiBgdHJhaW5fY29z
dGAgd2lsbCBiZSBlcXVhbCBvciBsZXNzIHRoYW4gdGhpcyB2YWx1ZS4gSWYgZnVydGhlciBt
b2RlbAogdHJhaW5pbmcgY2Vhc2VzIHRvIHByb3ZpZGUgYW55IGltcHJvdmVtZW50cywgaXQg
d2lsbCBzdG9wIHdpdGhvdXQgdXNpbmcKIGZ1bGwgYnVkZ2V0IGFuZCB0aGUgc3RvcF9yZWFz
b24gd2lsbCBiZSBgTU9ERUxfQ09OVkVSR0VEYC4KIE5vdGUsIG5vZGVfaG91ciAgPSBhY3R1
YWxfaG91ciAqIG51bWJlcl9vZl9ub2Rlc19pbnZvdmxlZC4KIEZvciBtb2RlbCB0eXBlIGBj
bG91ZGAoZGVmYXVsdCksIHRoZSB0cmFpbiBidWRnZXQgbXVzdCBiZSBiZXR3ZWVuIDgsMDAw
CiBhbmQgODAwLDAwMCBtaWxsaSBub2RlIGhvdXJzLCBpbmNsdXNpdmUuIFRoZSBkZWZhdWx0
IHZhbHVlIGlzIDE5MiwgMDAwCiB3aGljaCByZXByZXNlbnRzIG9uZSBkYXkgaW4gd2FsbCB0
aW1lLiBGb3IgbW9kZWwgdHlwZQogYG1vYmlsZS1sb3ctbGF0ZW5jeS0xYCwgYG1vYmlsZS12
ZXJzYXRpbGUtMWAsIGBtb2JpbGUtaGlnaC1hY2N1cmFjeS0xYCwKIGBtb2JpbGUtY29yZS1t
bC1sb3ctbGF0ZW5jeS0xYCwgYG1vYmlsZS1jb3JlLW1sLXZlcnNhdGlsZS0xYCwKIGBtb2Jp
bGUtY29yZS1tbC1oaWdoLWFjY3VyYWN5LTFgLCB0aGUgdHJhaW4gYnVkZ2V0IG11c3QgYmUg
YmV0d2VlbiAxLDAwMAogYW5kIDEwMCwwMDAgbWlsbGkgbm9kZSBob3VycywgaW5jbHVzaXZl
LiBUaGUgZGVmYXVsdCB2YWx1ZSBpcyAyNCwgMDAwIHdoaWNoCiByZXByZXNlbnRzIG9uZSBk
YXkgaW4gd2FsbCB0aW1lLgoKDAoFBAICAQUSAz8CBwoMCgUEAgIBARIDPwglCgwKBQQCAgED
EgM/KCoKDAoFBAICAQgSAz8rUwoPCggEAgIBCJwIABIDPyxSCsgBCgQEAgICEgNEAlUaugEg
T3V0cHV0IG9ubHkuIFRoZSBhY3R1YWwgdHJhaW4gY29zdCBvZiBjcmVhdGluZyB0aGlzIG1v
ZGVsLCBleHByZXNzZWQgaW4KIG1pbGxpIG5vZGUgaG91cnMsIGkuZS4gMSwwMDAgdmFsdWUg
aW4gdGhpcyBmaWVsZCBtZWFucyAxIG5vZGUgaG91ci4KIEd1YXJhbnRlZWQgdG8gbm90IGV4
Y2VlZCB0aGUgdHJhaW4gYnVkZ2V0LgoKDAoFBAICAgUSA0QCBwoMCgUEAgICARIDRAgjCgwK
BQQCAgIDEgNEJigKDAoFBAICAggSA0QpVAoPCggEAgICCJwIABIDRCpTCnsKBAQCAgMSA0gC
RRpuIE91dHB1dCBvbmx5LiBUaGUgcmVhc29uIHRoYXQgdGhpcyBjcmVhdGUgbW9kZWwgb3Bl
cmF0aW9uIHN0b3BwZWQsCiBlLmcuIGBCVURHRVRfUkVBQ0hFRGAsIGBNT0RFTF9DT05WRVJH
RURgLgoKDAoFBAICAwUSA0gCCAoMCgUEAgIDARIDSAkUCgwKBQQCAgMDEgNIFxgKDAoFBAIC
AwgSA0gZRAoPCggEAgIDCJwIABIDSBpDCvMSCgQEAgIEEgNrAkEa5RIgT3B0aW9uYWwuIFR5
cGUgb2YgdGhlIG1vZGVsLiBUaGUgYXZhaWxhYmxlIHZhbHVlcyBhcmU6CiAqICAgYGNsb3Vk
YCAtIE1vZGVsIHRvIGJlIHVzZWQgdmlhIHByZWRpY3Rpb24gY2FsbHMgdG8gQXV0b01MIEFQ
SS4KICAgICAgICAgICAgICAgVGhpcyBpcyB0aGUgZGVmYXVsdCB2YWx1ZS4KICogICBgbW9i
aWxlLWxvdy1sYXRlbmN5LTFgIC0gQSBtb2RlbCB0aGF0LCBpbiBhZGRpdGlvbiB0byBwcm92
aWRpbmcKICAgICAgICAgICAgICAgcHJlZGljdGlvbiB2aWEgQXV0b01MIEFQSSwgY2FuIGFs
c28gYmUgZXhwb3J0ZWQgKHNlZQogICAgICAgICAgICAgICBbQXV0b01sLkV4cG9ydE1vZGVs
XVtnb29nbGUuY2xvdWQuYXV0b21sLnYxLkF1dG9NbC5FeHBvcnRNb2RlbF0pIGFuZCB1c2Vk
IG9uIGEgbW9iaWxlIG9yIGVkZ2UgZGV2aWNlCiAgICAgICAgICAgICAgIHdpdGggVGVuc29y
RmxvdyBhZnRlcndhcmRzLiBFeHBlY3RlZCB0byBoYXZlIGxvdyBsYXRlbmN5LCBidXQKICAg
ICAgICAgICAgICAgbWF5IGhhdmUgbG93ZXIgcHJlZGljdGlvbiBxdWFsaXR5IHRoYW4gb3Ro
ZXIgbW9kZWxzLgogKiAgIGBtb2JpbGUtdmVyc2F0aWxlLTFgIC0gQSBtb2RlbCB0aGF0LCBp
biBhZGRpdGlvbiB0byBwcm92aWRpbmcKICAgICAgICAgICAgICAgcHJlZGljdGlvbiB2aWEg
QXV0b01MIEFQSSwgY2FuIGFsc28gYmUgZXhwb3J0ZWQgKHNlZQogICAgICAgICAgICAgICBb
QXV0b01sLkV4cG9ydE1vZGVsXVtnb29nbGUuY2xvdWQuYXV0b21sLnYxLkF1dG9NbC5FeHBv
cnRNb2RlbF0pIGFuZCB1c2VkIG9uIGEgbW9iaWxlIG9yIGVkZ2UgZGV2aWNlCiAgICAgICAg
ICAgICAgIHdpdGggVGVuc29yRmxvdyBhZnRlcndhcmRzLgogKiAgIGBtb2JpbGUtaGlnaC1h
Y2N1cmFjeS0xYCAtIEEgbW9kZWwgdGhhdCwgaW4gYWRkaXRpb24gdG8gcHJvdmlkaW5nCiAg
ICAgICAgICAgICAgIHByZWRpY3Rpb24gdmlhIEF1dG9NTCBBUEksIGNhbiBhbHNvIGJlIGV4
cG9ydGVkIChzZWUKICAgICAgICAgICAgICAgW0F1dG9NbC5FeHBvcnRNb2RlbF1bZ29vZ2xl
LmNsb3VkLmF1dG9tbC52MS5BdXRvTWwuRXhwb3J0TW9kZWxdKSBhbmQgdXNlZCBvbiBhIG1v
YmlsZSBvciBlZGdlIGRldmljZQogICAgICAgICAgICAgICB3aXRoIFRlbnNvckZsb3cgYWZ0
ZXJ3YXJkcy4gIEV4cGVjdGVkIHRvIGhhdmUgYSBoaWdoZXIKICAgICAgICAgICAgICAgbGF0
ZW5jeSwgYnV0IHNob3VsZCBhbHNvIGhhdmUgYSBoaWdoZXIgcHJlZGljdGlvbiBxdWFsaXR5
CiAgICAgICAgICAgICAgIHRoYW4gb3RoZXIgbW9kZWxzLgogKiAgIGBtb2JpbGUtY29yZS1t
bC1sb3ctbGF0ZW5jeS0xYCAtIEEgbW9kZWwgdGhhdCwgaW4gYWRkaXRpb24gdG8gcHJvdmlk
aW5nCiAgICAgICAgICAgICAgIHByZWRpY3Rpb24gdmlhIEF1dG9NTCBBUEksIGNhbiBhbHNv
IGJlIGV4cG9ydGVkIChzZWUKICAgICAgICAgICAgICAgW0F1dG9NbC5FeHBvcnRNb2RlbF1b
Z29vZ2xlLmNsb3VkLmF1dG9tbC52MS5BdXRvTWwuRXhwb3J0TW9kZWxdKSBhbmQgdXNlZCBv
biBhIG1vYmlsZSBkZXZpY2Ugd2l0aCBDb3JlCiAgICAgICAgICAgICAgIE1MIGFmdGVyd2Fy
ZHMuIEV4cGVjdGVkIHRvIGhhdmUgbG93IGxhdGVuY3ksIGJ1dCBtYXkgaGF2ZQogICAgICAg
ICAgICAgICBsb3dlciBwcmVkaWN0aW9uIHF1YWxpdHkgdGhhbiBvdGhlciBtb2RlbHMuCiAq
ICAgYG1vYmlsZS1jb3JlLW1sLXZlcnNhdGlsZS0xYCAtIEEgbW9kZWwgdGhhdCwgaW4gYWRk
aXRpb24gdG8gcHJvdmlkaW5nCiAgICAgICAgICAgICAgIHByZWRpY3Rpb24gdmlhIEF1dG9N
TCBBUEksIGNhbiBhbHNvIGJlIGV4cG9ydGVkIChzZWUKICAgICAgICAgICAgICAgW0F1dG9N
bC5FeHBvcnRNb2RlbF1bZ29vZ2xlLmNsb3VkLmF1dG9tbC52MS5BdXRvTWwuRXhwb3J0TW9k
ZWxdKSBhbmQgdXNlZCBvbiBhIG1vYmlsZSBkZXZpY2Ugd2l0aCBDb3JlCiAgICAgICAgICAg
ICAgIE1MIGFmdGVyd2FyZHMuCiAqICAgYG1vYmlsZS1jb3JlLW1sLWhpZ2gtYWNjdXJhY3kt
MWAgLSBBIG1vZGVsIHRoYXQsIGluIGFkZGl0aW9uIHRvCiAgICAgICAgICAgICAgIHByb3Zp
ZGluZyBwcmVkaWN0aW9uIHZpYSBBdXRvTUwgQVBJLCBjYW4gYWxzbyBiZSBleHBvcnRlZAog
ICAgICAgICAgICAgICAoc2VlIFtBdXRvTWwuRXhwb3J0TW9kZWxdW2dvb2dsZS5jbG91ZC5h
dXRvbWwudjEuQXV0b01sLkV4cG9ydE1vZGVsXSkgYW5kIHVzZWQgb24gYSBtb2JpbGUgZGV2
aWNlIHdpdGgKICAgICAgICAgICAgICAgQ29yZSBNTCBhZnRlcndhcmRzLiAgRXhwZWN0ZWQg
dG8gaGF2ZSBhIGhpZ2hlciBsYXRlbmN5LCBidXQKICAgICAgICAgICAgICAgc2hvdWxkIGFs
c28gaGF2ZSBhIGhpZ2hlciBwcmVkaWN0aW9uIHF1YWxpdHkgdGhhbiBvdGhlcgogICAgICAg
ICAgICAgICBtb2RlbHMuCgoMCgUEAgIEBRIDawIICgwKBQQCAgQBEgNrCRMKDAoFBAICBAMS
A2sWFwoMCgUEAgIECBIDaxhACg8KCAQCAgQInAgAEgNrGT8KlwEKBAQCAgUSA28CQxqJASBP
dXRwdXQgb25seS4gQW4gYXBwcm94aW1hdGUgbnVtYmVyIG9mIG9ubGluZSBwcmVkaWN0aW9u
IFFQUyB0aGF0IGNhbgogYmUgc3VwcG9ydGVkIGJ5IHRoaXMgbW9kZWwgcGVyIGVhY2ggbm9k
ZSBvbiB3aGljaCBpdCBpcyBkZXBsb3llZC4KCgwKBQQCAgUFEgNvAggKDAoFBAICBQESA28J
EQoMCgUEAgIFAxIDbxQWCgwKBQQCAgUIEgNvF0IKDwoIBAICBQicCAASA28YQQrEAQoEBAIC
BhIDdAJEGrYBIE91dHB1dCBvbmx5LiBUaGUgbnVtYmVyIG9mIG5vZGVzIHRoaXMgbW9kZWwg
aXMgZGVwbG95ZWQgb24uIEEgbm9kZSBpcyBhbgogYWJzdHJhY3Rpb24gb2YgYSBtYWNoaW5l
IHJlc291cmNlLCB3aGljaCBjYW4gaGFuZGxlIG9ubGluZSBwcmVkaWN0aW9uIFFQUwogYXMg
Z2l2ZW4gaW4gdGhlIG5vZGVfcXBzIGZpZWxkLgoKDAoFBAICBgUSA3QCBwoMCgUEAgIGARID
dAgSCgwKBQQCAgYDEgN0FRcKDAoFBAICBggSA3QYQwoPCggEAgIGCJwIABIDdBlCCkEKAgQD
EgV4ALQBARo0IE1vZGVsIG1ldGFkYXRhIHNwZWNpZmljIHRvIGltYWdlIG9iamVjdCBkZXRl
Y3Rpb24uCgoKCgMEAwESA3gIKQrpDAoEBAMCABIEkAECQRraDCBPcHRpb25hbC4gVHlwZSBv
ZiB0aGUgbW9kZWwuIFRoZSBhdmFpbGFibGUgdmFsdWVzIGFyZToKICogICBgY2xvdWQtaGln
aC1hY2N1cmFjeS0xYCAtIChkZWZhdWx0KSBBIG1vZGVsIHRvIGJlIHVzZWQgdmlhIHByZWRp
Y3Rpb24KICAgICAgICAgICAgICAgY2FsbHMgdG8gQXV0b01MIEFQSS4gRXhwZWN0ZWQgdG8g
aGF2ZSBhIGhpZ2hlciBsYXRlbmN5LCBidXQKICAgICAgICAgICAgICAgc2hvdWxkIGFsc28g
aGF2ZSBhIGhpZ2hlciBwcmVkaWN0aW9uIHF1YWxpdHkgdGhhbiBvdGhlcgogICAgICAgICAg
ICAgICBtb2RlbHMuCiAqICAgYGNsb3VkLWxvdy1sYXRlbmN5LTFgIC0gIEEgbW9kZWwgdG8g
YmUgdXNlZCB2aWEgcHJlZGljdGlvbgogICAgICAgICAgICAgICBjYWxscyB0byBBdXRvTUwg
QVBJLiBFeHBlY3RlZCB0byBoYXZlIGxvdyBsYXRlbmN5LCBidXQgbWF5CiAgICAgICAgICAg
ICAgIGhhdmUgbG93ZXIgcHJlZGljdGlvbiBxdWFsaXR5IHRoYW4gb3RoZXIgbW9kZWxzLgog
KiAgIGBtb2JpbGUtbG93LWxhdGVuY3ktMWAgLSBBIG1vZGVsIHRoYXQsIGluIGFkZGl0aW9u
IHRvIHByb3ZpZGluZwogICAgICAgICAgICAgICBwcmVkaWN0aW9uIHZpYSBBdXRvTUwgQVBJ
LCBjYW4gYWxzbyBiZSBleHBvcnRlZCAoc2VlCiAgICAgICAgICAgICAgIFtBdXRvTWwuRXhw
b3J0TW9kZWxdW2dvb2dsZS5jbG91ZC5hdXRvbWwudjEuQXV0b01sLkV4cG9ydE1vZGVsXSkg
YW5kIHVzZWQgb24gYSBtb2JpbGUgb3IgZWRnZSBkZXZpY2UKICAgICAgICAgICAgICAgd2l0
aCBUZW5zb3JGbG93IGFmdGVyd2FyZHMuIEV4cGVjdGVkIHRvIGhhdmUgbG93IGxhdGVuY3ks
IGJ1dAogICAgICAgICAgICAgICBtYXkgaGF2ZSBsb3dlciBwcmVkaWN0aW9uIHF1YWxpdHkg
dGhhbiBvdGhlciBtb2RlbHMuCiAqICAgYG1vYmlsZS12ZXJzYXRpbGUtMWAgLSBBIG1vZGVs
IHRoYXQsIGluIGFkZGl0aW9uIHRvIHByb3ZpZGluZwogICAgICAgICAgICAgICBwcmVkaWN0
aW9uIHZpYSBBdXRvTUwgQVBJLCBjYW4gYWxzbyBiZSBleHBvcnRlZCAoc2VlCiAgICAgICAg
ICAgICAgIFtBdXRvTWwuRXhwb3J0TW9kZWxdW2dvb2dsZS5jbG91ZC5hdXRvbWwudjEuQXV0
b01sLkV4cG9ydE1vZGVsXSkgYW5kIHVzZWQgb24gYSBtb2JpbGUgb3IgZWRnZSBkZXZpY2UK
ICAgICAgICAgICAgICAgd2l0aCBUZW5zb3JGbG93IGFmdGVyd2FyZHMuCiAqICAgYG1vYmls
ZS1oaWdoLWFjY3VyYWN5LTFgIC0gQSBtb2RlbCB0aGF0LCBpbiBhZGRpdGlvbiB0byBwcm92
aWRpbmcKICAgICAgICAgICAgICAgcHJlZGljdGlvbiB2aWEgQXV0b01MIEFQSSwgY2FuIGFs
c28gYmUgZXhwb3J0ZWQgKHNlZQogICAgICAgICAgICAgICBbQXV0b01sLkV4cG9ydE1vZGVs
XVtnb29nbGUuY2xvdWQuYXV0b21sLnYxLkF1dG9NbC5FeHBvcnRNb2RlbF0pIGFuZCB1c2Vk
IG9uIGEgbW9iaWxlIG9yIGVkZ2UgZGV2aWNlCiAgICAgICAgICAgICAgIHdpdGggVGVuc29y
RmxvdyBhZnRlcndhcmRzLiAgRXhwZWN0ZWQgdG8gaGF2ZSBhIGhpZ2hlcgogICAgICAgICAg
ICAgICBsYXRlbmN5LCBidXQgc2hvdWxkIGFsc28gaGF2ZSBhIGhpZ2hlciBwcmVkaWN0aW9u
IHF1YWxpdHkKICAgICAgICAgICAgICAgdGhhbiBvdGhlciBtb2RlbHMuCgoNCgUEAwIABRIE
kAECCAoNCgUEAwIAARIEkAEJEwoNCgUEAwIAAxIEkAEWFwoNCgUEAwIACBIEkAEYQAoQCggE
AwIACJwIABIEkAEZPwrJAQoEBAMCARIElQECQxq6ASBPdXRwdXQgb25seS4gVGhlIG51bWJl
ciBvZiBub2RlcyB0aGlzIG1vZGVsIGlzIGRlcGxveWVkIG9uLiBBIG5vZGUgaXMgYW4KIGFi
c3RyYWN0aW9uIG9mIGEgbWFjaGluZSByZXNvdXJjZSwgd2hpY2ggY2FuIGhhbmRsZSBvbmxp
bmUgcHJlZGljdGlvbiBRUFMKIGFzIGdpdmVuIGluIHRoZSBxcHNfcGVyX25vZGUgZmllbGQu
CgoNCgUEAwIBBRIElQECBwoNCgUEAwIBARIElQEIEgoNCgUEAwIBAxIElQEVFgoNCgUEAwIB
CBIElQEXQgoQCggEAwIBCJwIABIElQEYQQqYAQoEBAMCAhIEmQECQhqJASBPdXRwdXQgb25s
eS4gQW4gYXBwcm94aW1hdGUgbnVtYmVyIG9mIG9ubGluZSBwcmVkaWN0aW9uIFFQUyB0aGF0
IGNhbgogYmUgc3VwcG9ydGVkIGJ5IHRoaXMgbW9kZWwgcGVyIGVhY2ggbm9kZSBvbiB3aGlj
aCBpdCBpcyBkZXBsb3llZC4KCg0KBQQDAgIFEgSZAQIICg0KBQQDAgIBEgSZAQkRCg0KBQQD
AgIDEgSZARQVCg0KBQQDAgIIEgSZARZBChAKCAQDAgIInAgAEgSZARdACnwKBAQDAgMSBJ0B
AkUabiBPdXRwdXQgb25seS4gVGhlIHJlYXNvbiB0aGF0IHRoaXMgY3JlYXRlIG1vZGVsIG9w
ZXJhdGlvbiBzdG9wcGVkLAogZS5nLiBgQlVER0VUX1JFQUNIRURgLCBgTU9ERUxfQ09OVkVS
R0VEYC4KCg0KBQQDAgMFEgSdAQIICg0KBQQDAgMBEgSdAQkUCg0KBQQDAgMDEgSdARcYCg0K
BQQDAgMIEgSdARlEChAKCAQDAgMInAgAEgSdARpDCtsHCgQEAwIEEgSuAQJTGswHIE9wdGlv
bmFsLiBUaGUgdHJhaW4gYnVkZ2V0IG9mIGNyZWF0aW5nIHRoaXMgbW9kZWwsIGV4cHJlc3Nl
ZCBpbiBtaWxsaSBub2RlCiBob3VycyBpLmUuIDEsMDAwIHZhbHVlIGluIHRoaXMgZmllbGQg
bWVhbnMgMSBub2RlIGhvdXIuIFRoZSBhY3R1YWwKIGB0cmFpbl9jb3N0YCB3aWxsIGJlIGVx
dWFsIG9yIGxlc3MgdGhhbiB0aGlzIHZhbHVlLiBJZiBmdXJ0aGVyIG1vZGVsCiB0cmFpbmlu
ZyBjZWFzZXMgdG8gcHJvdmlkZSBhbnkgaW1wcm92ZW1lbnRzLCBpdCB3aWxsIHN0b3Agd2l0
aG91dCB1c2luZwogZnVsbCBidWRnZXQgYW5kIHRoZSBzdG9wX3JlYXNvbiB3aWxsIGJlIGBN
T0RFTF9DT05WRVJHRURgLgogTm90ZSwgbm9kZV9ob3VyICA9IGFjdHVhbF9ob3VyICogbnVt
YmVyX29mX25vZGVzX2ludm92bGVkLgogRm9yIG1vZGVsIHR5cGUgYGNsb3VkLWhpZ2gtYWNj
dXJhY3ktMWAoZGVmYXVsdCkgYW5kIGBjbG91ZC1sb3ctbGF0ZW5jeS0xYCwKIHRoZSB0cmFp
biBidWRnZXQgbXVzdCBiZSBiZXR3ZWVuIDIwLDAwMCBhbmQgOTAwLDAwMCBtaWxsaSBub2Rl
IGhvdXJzLAogaW5jbHVzaXZlLiBUaGUgZGVmYXVsdCB2YWx1ZSBpcyAyMTYsIDAwMCB3aGlj
aCByZXByZXNlbnRzIG9uZSBkYXkgaW4KIHdhbGwgdGltZS4KIEZvciBtb2RlbCB0eXBlIGBt
b2JpbGUtbG93LWxhdGVuY3ktMWAsIGBtb2JpbGUtdmVyc2F0aWxlLTFgLAogYG1vYmlsZS1o
aWdoLWFjY3VyYWN5LTFgLCBgbW9iaWxlLWNvcmUtbWwtbG93LWxhdGVuY3ktMWAsCiBgbW9i
aWxlLWNvcmUtbWwtdmVyc2F0aWxlLTFgLCBgbW9iaWxlLWNvcmUtbWwtaGlnaC1hY2N1cmFj
eS0xYCwgdGhlIHRyYWluCiBidWRnZXQgbXVzdCBiZSBiZXR3ZWVuIDEsMDAwIGFuZCAxMDAs
MDAwIG1pbGxpIG5vZGUgaG91cnMsIGluY2x1c2l2ZS4KIFRoZSBkZWZhdWx0IHZhbHVlIGlz
IDI0LCAwMDAgd2hpY2ggcmVwcmVzZW50cyBvbmUgZGF5IGluIHdhbGwgdGltZS4KCg0KBQQD
AgQFEgSuAQIHCg0KBQQDAgQBEgSuAQglCg0KBQQDAgQDEgSuASgpCg0KBQQDAgQIEgSuASpS
ChAKCAQDAgQInAgAEgSuAStRCskBCgQEAwIFEgSzAQJUGroBIE91dHB1dCBvbmx5LiBUaGUg
YWN0dWFsIHRyYWluIGNvc3Qgb2YgY3JlYXRpbmcgdGhpcyBtb2RlbCwgZXhwcmVzc2VkIGlu
CiBtaWxsaSBub2RlIGhvdXJzLCBpLmUuIDEsMDAwIHZhbHVlIGluIHRoaXMgZmllbGQgbWVh
bnMgMSBub2RlIGhvdXIuCiBHdWFyYW50ZWVkIHRvIG5vdCBleGNlZWQgdGhlIHRyYWluIGJ1
ZGdldC4KCg0KBQQDAgUFEgSzAQIHCg0KBQQDAgUBEgSzAQgjCg0KBQQDAgUDEgSzASYnCg0K
BQQDAgUIEgSzAShTChAKCAQDAgUInAgAEgSzASlSCksKAgQEEga3AQC+AQEaPSBNb2RlbCBk
ZXBsb3ltZW50IG1ldGFkYXRhIHNwZWNpZmljIHRvIEltYWdlIENsYXNzaWZpY2F0aW9uLgoK
CwoDBAQBEgS3AQgyCrwCCgQEBAIAEgS9AQJCGq0CIElucHV0IG9ubHkuIFRoZSBudW1iZXIg
b2Ygbm9kZXMgdG8gZGVwbG95IHRoZSBtb2RlbCBvbi4gQSBub2RlIGlzIGFuCiBhYnN0cmFj
dGlvbiBvZiBhIG1hY2hpbmUgcmVzb3VyY2UsIHdoaWNoIGNhbiBoYW5kbGUgb25saW5lIHBy
ZWRpY3Rpb24gUVBTCiBhcyBnaXZlbiBpbiB0aGUgbW9kZWwncwogW25vZGVfcXBzXVtnb29n
bGUuY2xvdWQuYXV0b21sLnYxLkltYWdlQ2xhc3NpZmljYXRpb25Nb2RlbE1ldGFkYXRhLm5v
ZGVfcXBzXS4KIE11c3QgYmUgYmV0d2VlbiAxIGFuZCAxMDAsIGluY2x1c2l2ZSBvbiBib3Ro
IGVuZHMuCgoNCgUEBAIABRIEvQECBwoNCgUEBAIAARIEvQEIEgoNCgUEBAIAAxIEvQEVFgoN
CgUEBAIACBIEvQEXQQoQCggEBAIACJwIABIEvQEYQApNCgIEBRIGwQEAyAEBGj8gTW9kZWwg
ZGVwbG95bWVudCBtZXRhZGF0YSBzcGVjaWZpYyB0byBJbWFnZSBPYmplY3QgRGV0ZWN0aW9u
LgoKCwoDBAUBEgTBAQgzCsUCCgQEBQIAEgTHAQJCGrYCIElucHV0IG9ubHkuIFRoZSBudW1i
ZXIgb2Ygbm9kZXMgdG8gZGVwbG95IHRoZSBtb2RlbCBvbi4gQSBub2RlIGlzIGFuCiBhYnN0
cmFjdGlvbiBvZiBhIG1hY2hpbmUgcmVzb3VyY2UsIHdoaWNoIGNhbiBoYW5kbGUgb25saW5l
IHByZWRpY3Rpb24gUVBTCiBhcyBnaXZlbiBpbiB0aGUgbW9kZWwncwogW3Fwc19wZXJfbm9k
ZV1bZ29vZ2xlLmNsb3VkLmF1dG9tbC52MS5JbWFnZU9iamVjdERldGVjdGlvbk1vZGVsTWV0
YWRhdGEucXBzX3Blcl9ub2RlXS4KIE11c3QgYmUgYmV0d2VlbiAxIGFuZCAxMDAsIGluY2x1
c2l2ZSBvbiBib3RoIGVuZHMuCgoNCgUEBQIABRIExwECBwoNCgUEBQIAARIExwEIEgoNCgUE
BQIAAxIExwEVFgoNCgUEBQIACBIExwEXQQoQCggEBQIACJwIABIExwEYQGIGcHJvdG8z
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Automl::V1::Image::ImageClassificationDatasetMetadata ===
    # Fields for ImageClassificationDatasetMetadata
    # Field: classification_type Type: 14 (.google.cloud.automl.v1.ClassificationType)

# === Message: Google::Cloud::Automl::V1::Image::ImageObjectDetectionDatasetMetadata ===
    # Fields for ImageObjectDetectionDatasetMetadata

# === Message: Google::Cloud::Automl::V1::Image::ImageClassificationModelMetadata ===
    # Fields for ImageClassificationModelMetadata
    # Field: base_model_id Type: 9 ()
    # Field: train_budget_milli_node_hours Type: 3 ()
    # Field: train_cost_milli_node_hours Type: 3 ()
    # Field: stop_reason Type: 9 ()
    # Field: model_type Type: 9 ()
    # Field: node_qps Type: 1 ()
    # Field: node_count Type: 3 ()

# === Message: Google::Cloud::Automl::V1::Image::ImageObjectDetectionModelMetadata ===
    # Fields for ImageObjectDetectionModelMetadata
    # Field: model_type Type: 9 ()
    # Field: node_count Type: 3 ()
    # Field: node_qps Type: 1 ()
    # Field: stop_reason Type: 9 ()
    # Field: train_budget_milli_node_hours Type: 3 ()
    # Field: train_cost_milli_node_hours Type: 3 ()

# === Message: Google::Cloud::Automl::V1::Image::ImageClassificationModelDeploymentMetadata ===
    # Fields for ImageClassificationModelDeploymentMetadata
    # Field: node_count Type: 3 ()

# === Message: Google::Cloud::Automl::V1::Image::ImageObjectDetectionModelDeploymentMetadata ===
    # Fields for ImageObjectDetectionModelDeploymentMetadata
    # Field: node_count Type: 3 ()

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Automl::V1::Image - Compiled Protocol Buffers messages for google/cloud/automl/v1/image.proto

=head1 SYNOPSIS

    use Google::Cloud::Automl::V1::Image;

    my $msg = Google::Cloud::Automl::V1::Image::ImageClassificationDatasetMetadata->new({
        classification_type => $classification_type,
    });

    # Read or update a field
    my $val = $msg->classification_type();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Automl::V1::Image::ImageClassificationDatasetMetadata->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/automl/v1/image.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Automl::V1::Image::ImageClassificationDatasetMetadata

Dataset metadata that is specific to image classification.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->classification_type() >> / C<< $msg->classification_type($value) >>

Type: C<Enum> (L<Google::Cloud::Automl::V1::ClassificationType>)

Required. Type of the classification problem.

=back

=head2 Google::Cloud::Automl::V1::Image::ImageObjectDetectionDatasetMetadata

Dataset metadata specific to image object detection.

Inherits from L<Protobuf::Message>.

=head2 Google::Cloud::Automl::V1::Image::ImageClassificationModelMetadata

Model metadata for image classification.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->base_model_id() >> / C<< $msg->base_model_id($value) >>

Type: C<String>

Optional. The ID of the `base` model. If it is specified, the new model
will be created based on the `base` model. Otherwise, the new model will be
created from scratch. The `base` model must be in the same
`project` and `location` as the new model to create, and have the same
`model_type`.

=item * C<< $msg->train_budget_milli_node_hours() >> / C<< $msg->train_budget_milli_node_hours($value) >>

Type: C<Int64>

Optional. The train budget of creating this model, expressed in milli node
hours i.e. 1,000 value in this field means 1 node hour. The actual
`train_cost` will be equal or less than this value. If further model
training ceases to provide any improvements, it will stop without using
full budget and the stop_reason will be `MODEL_CONVERGED`.
Note, node_hour  = actual_hour * number_of_nodes_invovled.
For model type `cloud`(default), the train budget must be between 8,000
and 800,000 milli node hours, inclusive. The default value is 192, 000
which represents one day in wall time. For model type
`mobile-low-latency-1`, `mobile-versatile-1`, `mobile-high-accuracy-1`,
`mobile-core-ml-low-latency-1`, `mobile-core-ml-versatile-1`,
`mobile-core-ml-high-accuracy-1`, the train budget must be between 1,000
and 100,000 milli node hours, inclusive. The default value is 24, 000 which
represents one day in wall time.

=item * C<< $msg->train_cost_milli_node_hours() >> / C<< $msg->train_cost_milli_node_hours($value) >>

Type: C<Int64>

Output only. The actual train cost of creating this model, expressed in
milli node hours, i.e. 1,000 value in this field means 1 node hour.
Guaranteed to not exceed the train budget.

=item * C<< $msg->stop_reason() >> / C<< $msg->stop_reason($value) >>

Type: C<String>

Output only. The reason that this create model operation stopped,
e.g. `BUDGET_REACHED`, `MODEL_CONVERGED`.

=item * C<< $msg->model_type() >> / C<< $msg->model_type($value) >>

Type: C<String>

Optional. Type of the model. The available values are:
*   `cloud` - Model to be used via prediction calls to AutoML API.
              This is the default value.
*   `mobile-low-latency-1` - A model that, in addition to providing
              prediction via AutoML API, can also be exported (see
              [AutoMl.ExportModel][google.cloud.automl.v1.AutoMl.ExportModel]) and used on a mobile or edge device
              with TensorFlow afterwards. Expected to have low latency, but
              may have lower prediction quality than other models.
*   `mobile-versatile-1` - A model that, in addition to providing
              prediction via AutoML API, can also be exported (see
              [AutoMl.ExportModel][google.cloud.automl.v1.AutoMl.ExportModel]) and used on a mobile or edge device
              with TensorFlow afterwards.
*   `mobile-high-accuracy-1` - A model that, in addition to providing
              prediction via AutoML API, can also be exported (see
              [AutoMl.ExportModel][google.cloud.automl.v1.AutoMl.ExportModel]) and used on a mobile or edge device
              with TensorFlow afterwards.  Expected to have a higher
              latency, but should also have a higher prediction quality
              than other models.
*   `mobile-core-ml-low-latency-1` - A model that, in addition to providing
              prediction via AutoML API, can also be exported (see
              [AutoMl.ExportModel][google.cloud.automl.v1.AutoMl.ExportModel]) and used on a mobile device with Core
              ML afterwards. Expected to have low latency, but may have
              lower prediction quality than other models.
*   `mobile-core-ml-versatile-1` - A model that, in addition to providing
              prediction via AutoML API, can also be exported (see
              [AutoMl.ExportModel][google.cloud.automl.v1.AutoMl.ExportModel]) and used on a mobile device with Core
              ML afterwards.
*   `mobile-core-ml-high-accuracy-1` - A model that, in addition to
              providing prediction via AutoML API, can also be exported
              (see [AutoMl.ExportModel][google.cloud.automl.v1.AutoMl.ExportModel]) and used on a mobile device with
              Core ML afterwards.  Expected to have a higher latency, but
              should also have a higher prediction quality than other
              models.

=item * C<< $msg->node_qps() >> / C<< $msg->node_qps($value) >>

Type: C<Double>

Output only. An approximate number of online prediction QPS that can
be supported by this model per each node on which it is deployed.

=item * C<< $msg->node_count() >> / C<< $msg->node_count($value) >>

Type: C<Int64>

Output only. The number of nodes this model is deployed on. A node is an
abstraction of a machine resource, which can handle online prediction QPS
as given in the node_qps field.

=back

=head2 Google::Cloud::Automl::V1::Image::ImageObjectDetectionModelMetadata

Model metadata specific to image object detection.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->model_type() >> / C<< $msg->model_type($value) >>

Type: C<String>

Optional. Type of the model. The available values are:
*   `cloud-high-accuracy-1` - (default) A model to be used via prediction
              calls to AutoML API. Expected to have a higher latency, but
              should also have a higher prediction quality than other
              models.
*   `cloud-low-latency-1` -  A model to be used via prediction
              calls to AutoML API. Expected to have low latency, but may
              have lower prediction quality than other models.
*   `mobile-low-latency-1` - A model that, in addition to providing
              prediction via AutoML API, can also be exported (see
              [AutoMl.ExportModel][google.cloud.automl.v1.AutoMl.ExportModel]) and used on a mobile or edge device
              with TensorFlow afterwards. Expected to have low latency, but
              may have lower prediction quality than other models.
*   `mobile-versatile-1` - A model that, in addition to providing
              prediction via AutoML API, can also be exported (see
              [AutoMl.ExportModel][google.cloud.automl.v1.AutoMl.ExportModel]) and used on a mobile or edge device
              with TensorFlow afterwards.
*   `mobile-high-accuracy-1` - A model that, in addition to providing
              prediction via AutoML API, can also be exported (see
              [AutoMl.ExportModel][google.cloud.automl.v1.AutoMl.ExportModel]) and used on a mobile or edge device
              with TensorFlow afterwards.  Expected to have a higher
              latency, but should also have a higher prediction quality
              than other models.

=item * C<< $msg->node_count() >> / C<< $msg->node_count($value) >>

Type: C<Int64>

Output only. The number of nodes this model is deployed on. A node is an
abstraction of a machine resource, which can handle online prediction QPS
as given in the qps_per_node field.

=item * C<< $msg->node_qps() >> / C<< $msg->node_qps($value) >>

Type: C<Double>

Output only. An approximate number of online prediction QPS that can
be supported by this model per each node on which it is deployed.

=item * C<< $msg->stop_reason() >> / C<< $msg->stop_reason($value) >>

Type: C<String>

Output only. The reason that this create model operation stopped,
e.g. `BUDGET_REACHED`, `MODEL_CONVERGED`.

=item * C<< $msg->train_budget_milli_node_hours() >> / C<< $msg->train_budget_milli_node_hours($value) >>

Type: C<Int64>

Optional. The train budget of creating this model, expressed in milli node
hours i.e. 1,000 value in this field means 1 node hour. The actual
`train_cost` will be equal or less than this value. If further model
training ceases to provide any improvements, it will stop without using
full budget and the stop_reason will be `MODEL_CONVERGED`.
Note, node_hour  = actual_hour * number_of_nodes_invovled.
For model type `cloud-high-accuracy-1`(default) and `cloud-low-latency-1`,
the train budget must be between 20,000 and 900,000 milli node hours,
inclusive. The default value is 216, 000 which represents one day in
wall time.
For model type `mobile-low-latency-1`, `mobile-versatile-1`,
`mobile-high-accuracy-1`, `mobile-core-ml-low-latency-1`,
`mobile-core-ml-versatile-1`, `mobile-core-ml-high-accuracy-1`, the train
budget must be between 1,000 and 100,000 milli node hours, inclusive.
The default value is 24, 000 which represents one day in wall time.

=item * C<< $msg->train_cost_milli_node_hours() >> / C<< $msg->train_cost_milli_node_hours($value) >>

Type: C<Int64>

Output only. The actual train cost of creating this model, expressed in
milli node hours, i.e. 1,000 value in this field means 1 node hour.
Guaranteed to not exceed the train budget.

=back

=head2 Google::Cloud::Automl::V1::Image::ImageClassificationModelDeploymentMetadata

Model deployment metadata specific to Image Classification.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->node_count() >> / C<< $msg->node_count($value) >>

Type: C<Int64>

Input only. The number of nodes to deploy the model on. A node is an
abstraction of a machine resource, which can handle online prediction QPS
as given in the model's
[node_qps][google.cloud.automl.v1.ImageClassificationModelMetadata.node_qps].
Must be between 1 and 100, inclusive on both ends.

=back

=head2 Google::Cloud::Automl::V1::Image::ImageObjectDetectionModelDeploymentMetadata

Model deployment metadata specific to Image Object Detection.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->node_count() >> / C<< $msg->node_count($value) >>

Type: C<Int64>

Input only. The number of nodes to deploy the model on. A node is an
abstraction of a machine resource, which can handle online prediction QPS
as given in the model's
[qps_per_node][google.cloud.automl.v1.ImageObjectDetectionModelMetadata.qps_per_node].
Must be between 1 and 100, inclusive on both ends.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Automl::V1::Image::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
