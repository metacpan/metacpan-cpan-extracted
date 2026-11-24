package Google::Cloud::Confidentialcomputing::V1alpha1::Service;

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
    eval { require Google::Api::Resource };
    eval { require Google::Protobuf::Timestamp };
    my $descriptor_b64 = <<'EOF';
Cjlnb29nbGUvY2xvdWQvY29uZmlkZW50aWFsY29tcHV0aW5nL3YxYWxwaGExL3NlcnZpY2Uu
cHJvdG8SK2dvb2dsZS5jbG91ZC5jb25maWRlbnRpYWxjb21wdXRpbmcudjFhbHBoYTEaHGdv
b2dsZS9hcGkvYW5ub3RhdGlvbnMucHJvdG8aF2dvb2dsZS9hcGkvY2xpZW50LnByb3RvGh9n
b29nbGUvYXBpL2ZpZWxkX2JlaGF2aW9yLnByb3RvGhlnb29nbGUvYXBpL3Jlc291cmNlLnBy
b3RvGh9nb29nbGUvcHJvdG9idWYvdGltZXN0YW1wLnByb3RvIswCCglDaGFsbGVuZ2USFwoE
bmFtZRgBIAEoCUID4EEDUgRuYW1lEkAKC2NyZWF0ZV90aW1lGAIgASgLMhouZ29vZ2xlLnBy
b3RvYnVmLlRpbWVzdGFtcEID4EEDUgpjcmVhdGVUaW1lEkAKC2V4cGlyZV90aW1lGAMgASgL
MhouZ29vZ2xlLnByb3RvYnVmLlRpbWVzdGFtcEID4EEDUgpleHBpcmVUaW1lEhcKBHVzZWQY
BCABKAhCA+BBA1IEdXNlZBIZCgVub25jZRgFIAEoDEID4EEDUgVub25jZTpu6kFrCi5jb25m
aWRlbnRpYWxjb21wdXRpbmcuZ29vZ2xlYXBpcy5jb20vQ2hhbGxlbmdlEjlwcm9qZWN0cy97
cHJvamVjdH0vbG9jYXRpb25zL3tsb2NhdGlvbn0vY2hhbGxlbmdlcy97dXVpZH0itgEKFkNy
ZWF0ZUNoYWxsZW5nZVJlcXVlc3QSQQoGcGFyZW50GAEgASgJQingQQL6QSMKIWxvY2F0aW9u
cy5nb29nbGVhcGlzLmNvbS9Mb2NhdGlvblIGcGFyZW50ElkKCWNoYWxsZW5nZRgCIAEoCzI2
Lmdvb2dsZS5jbG91ZC5jb25maWRlbnRpYWxjb21wdXRpbmcudjFhbHBoYTEuQ2hhbGxlbmdl
QgPgQQJSCWNoYWxsZW5nZSLGAgoYVmVyaWZ5QXR0ZXN0YXRpb25SZXF1ZXN0ElQKCWNoYWxs
ZW5nZRgBIAEoCUI24EEC+kEwCi5jb25maWRlbnRpYWxjb21wdXRpbmcuZ29vZ2xlYXBpcy5j
b20vQ2hhbGxlbmdlUgljaGFsbGVuZ2USaQoPZ2NwX2NyZWRlbnRpYWxzGAIgASgLMjsuZ29v
Z2xlLmNsb3VkLmNvbmZpZGVudGlhbGNvbXB1dGluZy52MWFscGhhMS5HY3BDcmVkZW50aWFs
c0ID4EEBUg5nY3BDcmVkZW50aWFscxJpCg90cG1fYXR0ZXN0YXRpb24YAyABKAsyOy5nb29n
bGUuY2xvdWQuY29uZmlkZW50aWFsY29tcHV0aW5nLnYxYWxwaGExLlRwbUF0dGVzdGF0aW9u
QgPgQQJSDnRwbUF0dGVzdGF0aW9uIkMKGVZlcmlmeUF0dGVzdGF0aW9uUmVzcG9uc2USJgoM
Y2xhaW1zX3Rva2VuGAEgASgMQgPgQQNSC2NsYWltc1Rva2VuIi0KDkdjcENyZWRlbnRpYWxz
EhsKCWlkX3Rva2VucxgBIAMoDFIIaWRUb2tlbnMijwQKDlRwbUF0dGVzdGF0aW9uElkKBnF1
b3RlcxgBIAMoCzJBLmdvb2dsZS5jbG91ZC5jb25maWRlbnRpYWxjb21wdXRpbmcudjFhbHBo
YTEuVHBtQXR0ZXN0YXRpb24uUXVvdGVSBnF1b3RlcxIiCg10Y2dfZXZlbnRfbG9nGAIgASgM
Ugt0Y2dFdmVudExvZxIuChNjYW5vbmljYWxfZXZlbnRfbG9nGAMgASgMUhFjYW5vbmljYWxF
dmVudExvZxIXCgdha19jZXJ0GAQgASgMUgZha0NlcnQSHQoKY2VydF9jaGFpbhgFIAMoDFIJ
Y2VydENoYWluGpUCCgVRdW90ZRIbCgloYXNoX2FsZ28YASABKAVSCGhhc2hBbGdvEm8KCnBj
cl92YWx1ZXMYAiADKAsyUC5nb29nbGUuY2xvdWQuY29uZmlkZW50aWFsY29tcHV0aW5nLnYx
YWxwaGExLlRwbUF0dGVzdGF0aW9uLlF1b3RlLlBjclZhbHVlc0VudHJ5UglwY3JWYWx1ZXMS
GwoJcmF3X3F1b3RlGAMgASgMUghyYXdRdW90ZRIjCg1yYXdfc2lnbmF0dXJlGAQgASgMUgxy
YXdTaWduYXR1cmUaPAoOUGNyVmFsdWVzRW50cnkSEAoDa2V5GAEgASgFUgNrZXkSFAoFdmFs
dWUYAiABKAxSBXZhbHVlOgI4ATLbBAoVQ29uZmlkZW50aWFsQ29tcHV0aW5nEuoBCg9DcmVh
dGVDaGFsbGVuZ2USQy5nb29nbGUuY2xvdWQuY29uZmlkZW50aWFsY29tcHV0aW5nLnYxYWxw
aGExLkNyZWF0ZUNoYWxsZW5nZVJlcXVlc3QaNi5nb29nbGUuY2xvdWQuY29uZmlkZW50aWFs
Y29tcHV0aW5nLnYxYWxwaGExLkNoYWxsZW5nZSJagtPkkwJBIjQvdjFhbHBoYTEve3BhcmVu
dD1wcm9qZWN0cy8qL2xvY2F0aW9ucy8qfS9jaGFsbGVuZ2VzOgljaGFsbGVuZ2XaQRBwYXJl
bnQsY2hhbGxlbmdlEvoBChFWZXJpZnlBdHRlc3RhdGlvbhJFLmdvb2dsZS5jbG91ZC5jb25m
aWRlbnRpYWxjb21wdXRpbmcudjFhbHBoYTEuVmVyaWZ5QXR0ZXN0YXRpb25SZXF1ZXN0GkYu
Z29vZ2xlLmNsb3VkLmNvbmZpZGVudGlhbGNvbXB1dGluZy52MWFscGhhMS5WZXJpZnlBdHRl
c3RhdGlvblJlc3BvbnNlIlaC0+STAlAiSy92MWFscGhhMS97Y2hhbGxlbmdlPXByb2plY3Rz
LyovbG9jYXRpb25zLyovY2hhbGxlbmdlcy8qfTp2ZXJpZnlBdHRlc3RhdGlvbjoBKhpYykEk
Y29uZmlkZW50aWFsY29tcHV0aW5nLmdvb2dsZWFwaXMuY29t0kEuaHR0cHM6Ly93d3cuZ29v
Z2xlYXBpcy5jb20vYXV0aC9jbG91ZC1wbGF0Zm9ybUK1AgovY29tLmdvb2dsZS5jbG91ZC5j
b25maWRlbnRpYWxjb21wdXRpbmcudjFhbHBoYTFCDFNlcnZpY2VQcm90b1ABWmVjbG91ZC5n
b29nbGUuY29tL2dvL2NvbmZpZGVudGlhbGNvbXB1dGluZy9hcGl2MWFscGhhMS9jb25maWRl
bnRpYWxjb21wdXRpbmdwYjtjb25maWRlbnRpYWxjb21wdXRpbmdwYqoCK0dvb2dsZS5DbG91
ZC5Db25maWRlbnRpYWxDb21wdXRpbmcuVjFBbHBoYTHKAitHb29nbGVcQ2xvdWRcQ29uZmlk
ZW50aWFsQ29tcHV0aW5nXFYxYWxwaGEx6gIuR29vZ2xlOjpDbG91ZDo6Q29uZmlkZW50aWFs
Q29tcHV0aW5nOjpWMWFscGhhMUrGMgoHEgUOALcBAQq8BAoBDBIDDgASMrEEIENvcHlyaWdo
dCAyMDI1IEdvb2dsZSBMTEMKCiBMaWNlbnNlZCB1bmRlciB0aGUgQXBhY2hlIExpY2Vuc2Us
IFZlcnNpb24gMi4wICh0aGUgIkxpY2Vuc2UiKTsKIHlvdSBtYXkgbm90IHVzZSB0aGlzIGZp
bGUgZXhjZXB0IGluIGNvbXBsaWFuY2Ugd2l0aCB0aGUgTGljZW5zZS4KIFlvdSBtYXkgb2J0
YWluIGEgY29weSBvZiB0aGUgTGljZW5zZSBhdAoKICAgICBodHRwOi8vd3d3LmFwYWNoZS5v
cmcvbGljZW5zZXMvTElDRU5TRS0yLjAKCiBVbmxlc3MgcmVxdWlyZWQgYnkgYXBwbGljYWJs
ZSBsYXcgb3IgYWdyZWVkIHRvIGluIHdyaXRpbmcsIHNvZnR3YXJlCiBkaXN0cmlidXRlZCB1
bmRlciB0aGUgTGljZW5zZSBpcyBkaXN0cmlidXRlZCBvbiBhbiAiQVMgSVMiIEJBU0lTLAog
V0lUSE9VVCBXQVJSQU5USUVTIE9SIENPTkRJVElPTlMgT0YgQU5ZIEtJTkQsIGVpdGhlciBl
eHByZXNzIG9yIGltcGxpZWQuCiBTZWUgdGhlIExpY2Vuc2UgZm9yIHRoZSBzcGVjaWZpYyBs
YW5ndWFnZSBnb3Zlcm5pbmcgcGVybWlzc2lvbnMgYW5kCiBsaW1pdGF0aW9ucyB1bmRlciB0
aGUgTGljZW5zZS4KCggKAQISAxAANAoJCgIDABIDEgAmCgkKAgMBEgMTACEKCQoCAwISAxQA
KQoJCgIDAxIDFQAjCgkKAgMEEgMWACkKCAoBCBIDGABICgkKAgglEgMYAEgKCAoBCBIDGQB8
CgkKAggLEgMZAHwKCAoBCBIDGgAiCgkKAggKEgMaACIKCAoBCBIDGwAtCgkKAggIEgMbAC0K
CAoBCBIDHABICgkKAggBEgMcAEgKCAoBCBIDHQBICgkKAggpEgMdAEgKCAoBCBIDHgBHCgkK
AggtEgMeAEcKNwoCBgASBCEANwEaKyBTZXJ2aWNlIGRlc2NyaWJpbmcgaGFuZGxlcnMgZm9y
IHJlc291cmNlcwoKCgoDBgABEgMhCB0KCgoDBgADEgMiAkwKDAoFBgADmQgSAyICTAoLCgMG
AAMSBCMCJDcKDQoFBgADmggSBCMCJDcKSAoEBgACABIEJwItAxo6IENyZWF0ZXMgYSBuZXcg
Q2hhbGxlbmdlIGluIGEgZ2l2ZW4gcHJvamVjdCBhbmQgbG9jYXRpb24uCgoMCgUGAAIAARID
JwYVCgwKBQYAAgACEgMnFiwKDAoFBgACAAMSAyc3QAoNCgUGAAIABBIEKAQrBgoRCgkGAAIA
BLDKvCISBCgEKwYKDAoFBgACAAQSAywEPgoPCggGAAIABJsIABIDLAQ+ClYKBAYAAgESBDAC
NgMaSCBWZXJpZmllcyB0aGUgcHJvdmlkZWQgYXR0ZXN0YXRpb24gaW5mbywgcmV0dXJuaW5n
IGEgc2lnbmVkIE9JREMgdG9rZW4uCgoMCgUGAAIBARIDMAYXCgwKBQYAAgECEgMwGDAKDAoF
BgACAQMSAzEPKAoNCgUGAAIBBBIEMgQ1BgoRCgkGAAIBBLDKvCISBDIENQYKVQoCBAASBDoA
UwEaSSBBIENoYWxsZW5nZSBmcm9tIHRoZSBzZXJ2ZXIgdXNlZCB0byBndWFyYW50ZWUgZnJl
c2huZXNzIG9mIGF0dGVzdGF0aW9ucwoKCgoDBAABEgM6CBEKCwoDBAAHEgQ7Aj4ECg0KBQQA
B50IEgQ7Aj4ECnUKBAQAAgASA0ICPhpoIE91dHB1dCBvbmx5LiBUaGUgcmVzb3VyY2UgbmFt
ZSBmb3IgdGhpcyBDaGFsbGVuZ2UgaW4gdGhlIGZvcm1hdAogYHByb2plY3RzLyovbG9jYXRp
b25zLyovY2hhbGxlbmdlcy8qYAoKDAoFBAACAAUSA0ICCAoMCgUEAAIAARIDQgkNCgwKBQQA
AgADEgNCEBEKDAoFBAACAAgSA0ISPQoPCggEAAIACJwIABIDQhM8CkkKBAQAAgESBEUCRjIa
OyBPdXRwdXQgb25seS4gVGhlIHRpbWUgYXQgd2hpY2ggdGhpcyBDaGFsbGVuZ2Ugd2FzIGNy
ZWF0ZWQKCgwKBQQAAgEGEgNFAhsKDAoFBAACAQESA0UcJwoMCgUEAAIBAxIDRSorCgwKBQQA
AgEIEgNGBjEKDwoIBAACAQicCAASA0YHMAqmAQoEBAACAhIESgJLMhqXASBPdXRwdXQgb25s
eS4gVGhlIHRpbWUgYXQgd2hpY2ggdGhpcyBDaGFsbGVuZ2Ugd2lsbCBubyBsb25nZXIgYmUg
dXNhYmxlLiBJdAogaXMgYWxzbyB0aGUgZXhwaXJhdGlvbiB0aW1lIGZvciBhbnkgdG9rZW5z
IGdlbmVyYXRlZCBmcm9tIHRoaXMgQ2hhbGxlbmdlLgoKDAoFBAACAgYSA0oCGwoMCgUEAAIC
ARIDShwnCgwKBQQAAgIDEgNKKisKDAoFBAACAggSA0sGMQoPCggEAAICCJwIABIDSwcwCloK
BAQAAgMSA04CPBpNIE91dHB1dCBvbmx5LiBJbmRpY2F0ZXMgaWYgdGhpcyBjaGFsbGVuZ2Ug
aGFzIGJlZW4gdXNlZCB0byBnZW5lcmF0ZSBhIHRva2VuLgoKDAoFBAACAwUSA04CBgoMCgUE
AAIDARIDTgcLCgwKBQQAAgMDEgNODg8KDAoFBAACAwgSA04QOwoPCggEAAIDCJwIABIDThE6
ClkKBAQAAgQSA1ICPhpMIE91dHB1dCBvbmx5LiBSYW5kb20gZGF0YSB3aGljaCBzaG91bGQg
YmUgdXNlZCB3aGVuIGNhbGxpbmcgVFBNMl9RdW90ZS4KIC0tCgoMCgUEAAIEBRIDUgIHCgwK
BQQAAgQBEgNSCA0KDAoFBAACBAMSA1IQEQoMCgUEAAIECBIDUhI9Cg8KCAQAAgQInAgAEgNS
EzwKLgoCBAESBFYAYwEaIiBNZXNzYWdlIGZvciBjcmVhdGluZyBhIENoYWxsZW5nZQoKCgoD
BAEBEgNWCB4KhgEKBAQBAgASBFkCXgQaeCBSZXF1aXJlZC4gVGhlIHJlc291cmNlIG5hbWUg
b2YgdGhlIGxvY2F0aW9uIHdoZXJlIHRoZSBDaGFsbGVuZ2Ugd2lsbCBiZQogdXNlZCwgaW4g
dGhlIGZvcm1hdCBgcHJvamVjdHMvKi9sb2NhdGlvbnMvKmAuCgoMCgUEAQIABRIDWQIICgwK
BQQBAgABEgNZCQ8KDAoFBAECAAMSA1kSEwoNCgUEAQIACBIEWRReAwoPCggEAQIACJwIABID
WgQqCg8KBwQBAgAInwgSBFsEXQUKiwEKBAQBAgESA2ICQxp+IFJlcXVpcmVkLiBUaGUgQ2hh
bGxlbmdlIHRvIGJlIGNyZWF0ZWQuIEN1cnJlbnRseSB0aGlzIGZpZWxkIGNhbiBiZSBlbXB0
eSBhcwogYWxsIHRoZSBDaGFsbGVuZ2UgZmllbGRzIGFyZSBzZXQgYnkgdGhlIHNlcnZlci4K
CgwKBQQBAgEGEgNiAgsKDAoFBAECAQESA2IMFQoMCgUEAQIBAxIDYhgZCgwKBQQBAgEIEgNi
GkIKDwoIBAECAQicCAASA2IbQQqaAQoCBAISBGcAeQEajQEgQSByZXF1ZXN0IGZvciBhbiBP
SURDIHRva2VuLCBwcm92aWRpbmcgYWxsIHRoZSBuZWNlc3NhcnkgaW5mb3JtYXRpb24gbmVl
ZGVkCiBmb3IgdGhpcyBzZXJ2aWNlIHRvIHZlcmlmeSB0aGUgcGxhZm9ybSBzdGF0ZSBvZiB0
aGUgcmVxdWVzdG9yLgoKCgoDBAIBEgNnCCAK4AEKBAQCAgASBGsCcAQa0QEgUmVxdWlyZWQu
IFRoZSBuYW1lIG9mIHRoZSBDaGFsbGVuZ2Ugd2hvc2Ugbm9uY2Ugd2FzIHVzZWQgdG8gZ2Vu
ZXJhdGUgdGhlCiBhdHRlc3RhdGlvbiwgaW4gdGhlIGZvcm1hdCBgcHJvamVjdHMvKi9sb2Nh
dGlvbnMvKi9jaGFsbGVuZ2VzLypgLiBUaGUKIHByb3ZpZGVkIENoYWxsZW5nZSB3aWxsIGJl
IGNvbnN1bWVkLCBhbmQgY2Fubm90IGJlIHVzZWQgYWdhaW4uCgoMCgUEAgIABRIDawIICgwK
BQQCAgABEgNrCRIKDAoFBAICAAMSA2sVFgoNCgUEAgIACBIEaxdwAwoPCggEAgIACJwIABID
bAQqCg8KBwQCAgAInwgSBG0EbwUKXgoEBAICARIDdAJOGlEgT3B0aW9uYWwuIENyZWRlbnRp
YWxzIHVzZWQgdG8gcG9wdWxhdGUgdGhlICJlbWFpbHMiIGNsYWltIGluIHRoZQogY2xhaW1z
X3Rva2VuLgoKDAoFBAICAQYSA3QCEAoMCgUEAgIBARIDdBEgCgwKBQQCAgEDEgN0IyQKDAoF
BAICAQgSA3QlTQoPCggEAgIBCJwIABIDdCZMCpEBCgQEAgICEgN4Ak4agwEgUmVxdWlyZWQu
IFRoZSBUUE0tc3BlY2lmaWMgZGF0YSBwcm92aWRlZCBieSB0aGUgYXR0ZXN0aW5nIHBsYXRm
b3JtLCB1c2VkIHRvCiBwb3B1bGF0ZSBhbnkgb2YgdGhlIGNsYWltcyByZWdhcmRpbmcgcGxh
dGZvcm0gc3RhdGUuCgoMCgUEAgICBhIDeAIQCgwKBQQCAgIBEgN4ESAKDAoFBAICAgMSA3gj
JAoMCgUEAgICCBIDeCVNCg8KCAQCAgIInAgAEgN4JkwKbgoCBAMSBX0AggEBGmEgQSByZXNw
b25zZSBvbmNlIGFuIGF0dGVzdGF0aW9uIGhhcyBiZWVuIHN1Y2Nlc3NmdWxseSB2ZXJpZmll
ZCwgY29udGFpbmluZyBhCiBzaWduZWQgT0lEQyB0b2tlbi4KCgoKAwQDARIDfQghCqEBCgQE
AwIAEgSBAQJFGpIBIE91dHB1dCBvbmx5LiBUaGUgT0lEQyB0b2tlbiBpc3N1ZWQgYnkgdGhp
cyBzZXJ2aWNlLiBJdCBjb250YWlucyBzcGVjaWZpYwogcGxhdGZvcm0gY2xhaW1zIGJhc2Vk
IG9uIHRoZSBjb250ZW50cyBvZiB0aGUgcHJvdmlkZWQgYXR0ZXN0YXRpb24uCiAtLQoKDQoF
BAMCAAUSBIEBAgcKDQoFBAMCAAESBIEBCBQKDQoFBAMCAAMSBIEBFxgKDQoFBAMCAAgSBIEB
GUQKEAoIBAMCAAicCAASBIEBGkMKoAEKAgQEEgaGAQCOAQEakQEgQ3JlZGVudGlhbHMgaXNz
dWVkIGJ5IEdDUCB3aGljaCBhcmUgbGlua2VkIHRvIHRoZSBwbGF0Zm9ybSBhdHRlc3RhdGlv
bi4gVGhlc2UKIHdpbGwgYmUgdmVyaWZpZWQgc2VydmVyLXNpZGUgYXMgcGFydCBvZiBhdHRl
c3RhaW9uIHZlcmlmaWNhdGlvbi4KCgsKAwQEARIEhgEIFgrTAgoEBAQCABIEjQECHxrEAiBB
IGxpc3Qgb2Ygc2VydmljZSBhY2NvdW50IE9wZW5JRCBDb25uZWN0IElEIHRva2VucyBpZGVu
dGlmeWluZyB3aGljaAogc2VydmljZSBhY2NvdW50IGlkZW50aXRpZXMgc2hvdWxkIGJlIGlu
Y2x1ZGVkIGluIHRoZSBjbGFpbXNfdG9rZW4uIFRoZXNlCiBjYW4gYmUgZ2VuZXJhdGVkIGJ5
IGNhbGxpbmcgYHNlcnZpY2VBY2NvdW50cy5nZW5lcmF0ZUlkVG9rZW5gLiBUaGUKIENoYWxs
ZW5nZS5uYW1lIG11c3QgYmUgdXNlZCBhcyB0aGUgYGF1ZGllbmNlYCBwYXJhbWV0ZXIsIGFu
ZCB0aGUKIGBpbmNsdWRlRW1haWxgIHBhcmFtZXRlciBtdXN0IGJlIGB0cnVlYC4KIC0tCgoN
CgUEBAIABBIEjQECCgoNCgUEBAIABRIEjQELEAoNCgUEBAIAARIEjQERGgoNCgUEBAIAAxIE
jQEdHgpwCgIEBRIGkgEAtwEBGmIgVFBNMiBkYXRhIGNvbnRhaW5pbmcgZXZlcnl0aGluZyBu
ZWNlc3NhcnkgdG8gdmFsaWRhdGUgYW55IHBsYXRmb3JtIHN0YXRlCiBtZWFzdXJlZCBpbnRv
IHRoZSBUUE0uCgoLCgMEBQESBJIBCBYKmQEKBAQFAwASBpUBAqEBAxqIASBJbmZvcm1hdGlv
biBhYm91dCBQbGF0Zm9ybSBDb250cm9sIFJlZ2lzdGVycyAoUENScykgaW5jbHVkaW5nIGEg
c2lnbmF0dXJlCiBvdmVyIHRoZWlyIHZhbHVlcywgd2hpY2ggY2FuIGJlIHVzZWQgZm9yIHJl
bW90ZSB2YWxpZGF0aW9uLgoKDQoFBAUDAAESBJUBCg8KWgoGBAUDAAIAEgSXAQQYGkogVGhl
IGhhc2ggYWxnb3JpdGhtIG9mIHRoZSBQQ1IgYmFuayBiZWluZyBxdW90ZWQsIGVuY29kZWQg
YXMgYSBUUE1fQUxHX0lECgoPCgcEBQMAAgAFEgSXAQQJCg8KBwQFAwACAAESBJcBChMKDwoH
BAUDAAIAAxIElwEWFwo+CgYEBQMAAgESBJoBBCUaLiBSYXcgYmluYXJ5IHZhbHVlcyBvZiBl
YWNoIFBDUnMgYmVpbmcgcXVvdGVkLgoKDwoHBAUDAAIBBhIEmgEEFQoPCgcEBQMAAgEBEgSa
ARYgCg8KBwQFAwACAQMSBJoBIyQKNgoGBAUDAAICEgSdAQQYGiYgVFBNMiBxdW90ZSwgZW5j
b2RlZCBhcyBhIFRQTVNfQVRURVNUCgoPCgcEBQMAAgIFEgSdAQQJCg8KBwQFAwACAgESBJ0B
ChMKDwoHBAUDAAICAxIEnQEWFwo9CgYEBQMAAgMSBKABBBwaLSBUUE0yIHNpZ25hdHVyZSwg
ZW5jb2RlZCBhcyBhIFRQTVRfU0lHTkFUVVJFCgoPCgcEBQMAAgMFEgSgAQQJCg8KBwQFAwAC
AwESBKABChcKDwoHBAUDAAIDAxIEoAEaGwpRCgQEBQIAEgSkAQIcGkMgVFBNMiBQQ1IgUXVv
dGVzIGdlbmVyYXRlZCBieSBjYWxsaW5nIFRQTTJfUXVvdGUgb24gZWFjaCBQQ1IgYmFuay4K
Cg0KBQQFAgAEEgSkAQIKCg0KBQQFAgAGEgSkAQsQCg0KBQQFAgABEgSkAREXCg0KBQQFAgAD
EgSkARobCtkBCgQEBQIBEgSpAQIaGsoBIFRoZSBiaW5hcnkgVENHIEV2ZW50IExvZyBjb250
YWluaW5nIGV2ZW50cyBtZWFzdXJlZCBpbnRvIHRoZSBUUE0gYnkgdGhlCiBwbGF0Zm9ybSBm
aXJtd2FyZSBhbmQgb3BlcmF0aW5nIHN5c3RlbS4gRm9ybWF0dGVkIGFzIGRlc2NyaWJlZCBp
biB0aGUKICJUQ0cgUEMgQ2xpZW50IFBsYXRmb3JtIEZpcm13YXJlIFByb2ZpbGUgU3BlY2lm
aWNhdGlvbiIuCgoNCgUEBQIBBRIEqQECBwoNCgUEBQIBARIEqQEIFQoNCgUEBQIBAxIEqQEY
GQrTAQoEBAUCAhIErgECIBrEASBBbiBFdmVudCBMb2cgY29udGFpbmluZyBhZGRpdGlvbmFs
IGV2ZW50cyBtZWFzdXJlZCBpbnRvIHRoZSBUUE0gdGhhdCBhcmUKIG5vdCBhbHJlYWR5IHBy
ZXNlbnQgaW4gdGhlIHRjZ19ldmVudF9sb2cuIEZvcm1hdHRlZCBhcyBkZXNjcmliZWQgaW4g
dGhlCiAiQ2Fub25pY2FsIEV2ZW50IExvZyBGb3JtYXQiIFRDRyBTcGVjaWZpY2F0aW9uLgoK
DQoFBAUCAgUSBK4BAgcKDQoFBAUCAgESBK4BCBsKDQoFBAUCAgMSBK4BHh8KngEKBAQFAgMS
BLIBAhQajwEgREVSLWVuY29kZWQgWC41MDkgY2VydGlmaWNhdGUgb2YgdGhlIEF0dGVzdGF0
aW9uIEtleSAob3RoZXJ3aXNlIGtub3duIGFzCiBhbiBBSyBvciBhIFRQTSByZXN0cmljdGVk
IHNpZ25pbmcga2V5KSB1c2VkIHRvIGdlbmVyYXRlIHRoZSBxdW90ZXMuCgoNCgUEBQIDBRIE
sgECBwoNCgUEBQIDARIEsgEIDwoNCgUEBQIDAxIEsgESEwqDAQoEBAUCBBIEtgECIBp1IExp
c3Qgb2YgREVSLWVuY29kZWQgWC41MDkgY2VydGlmaWNhdGVzIHdoaWNoLCB0b2dldGhlciB3
aXRoIHRoZSBha19jZXJ0LAogY2hhaW4gYmFjayB0byBhIHRydXN0ZWQgUm9vdCBDZXJ0aWZp
Y2F0ZS4KCg0KBQQFAgQEEgS2AQIKCg0KBQQFAgQFEgS2AQsQCg0KBQQFAgQBEgS2AREbCg0K
BQQFAgQDEgS2AR4fYgZwcm90bzM=
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Confidentialcomputing::V1alpha1::Service::Challenge ===
    # Fields for Challenge
    # Field: name Type: 9 ()
    # Field: create_time Type: 11 (.google.protobuf.Timestamp)
    # Field: expire_time Type: 11 (.google.protobuf.Timestamp)
    # Field: used Type: 8 ()
    # Field: nonce Type: 12 ()

# === Message: Google::Cloud::Confidentialcomputing::V1alpha1::Service::CreateChallengeRequest ===
    # Fields for CreateChallengeRequest
    # Field: parent Type: 9 ()
    # Field: challenge Type: 11 (.google.cloud.confidentialcomputing.v1alpha1.Challenge)

# === Message: Google::Cloud::Confidentialcomputing::V1alpha1::Service::VerifyAttestationRequest ===
    # Fields for VerifyAttestationRequest
    # Field: challenge Type: 9 ()
    # Field: gcp_credentials Type: 11 (.google.cloud.confidentialcomputing.v1alpha1.GcpCredentials)
    # Field: tpm_attestation Type: 11 (.google.cloud.confidentialcomputing.v1alpha1.TpmAttestation)

# === Message: Google::Cloud::Confidentialcomputing::V1alpha1::Service::VerifyAttestationResponse ===
    # Fields for VerifyAttestationResponse
    # Field: claims_token Type: 12 ()

# === Message: Google::Cloud::Confidentialcomputing::V1alpha1::Service::GcpCredentials ===
    # Fields for GcpCredentials
    # Field: id_tokens Type: 12 ()

# === Message: Google::Cloud::Confidentialcomputing::V1alpha1::Service::TpmAttestation ===
    # Fields for TpmAttestation
    # Field: quotes Type: 11 (.google.cloud.confidentialcomputing.v1alpha1.TpmAttestation.Quote)
    # Field: tcg_event_log Type: 12 ()
    # Field: canonical_event_log Type: 12 ()
    # Field: ak_cert Type: 12 ()
    # Field: cert_chain Type: 12 ()

# === Service Client: Google::Cloud::Confidentialcomputing::V1alpha1::Service::ConfidentialComputingClient ===
package Google::Cloud::Confidentialcomputing::V1alpha1::Service::ConfidentialComputingClient;

=pod

=head2 Service Client: Google::Cloud::Confidentialcomputing::V1alpha1::Service::ConfidentialComputingClient

Client stub representing the remote C<ConfidentialComputing> gRPC service. Delegates call dispatching to L<Google::gRPC::Client>.

=head3 target

The endpoint target address. Defaults to C<confidentialcomputing.googleapis.com:443>.

=head3 credentials

The authentication credentials provider. Defaults to application default credentials via L<Google::Auth>.

=cut

use Moo;
use Google::Auth;
use Google::gRPC::Client;

has credentials => ( is => 'ro', default => sub { Google::Auth->default() } );
has target      => ( is => 'ro', default => 'confidentialcomputing.googleapis.com:443' );

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

sub create_challenge {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Confidentialcomputing::V1alpha1::Service::CreateChallengeRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.confidentialcomputing.v1alpha1.ConfidentialComputing',
        method         => 'CreateChallenge',
        request        => $req,
        response_class => 'Google::Cloud::Confidentialcomputing::V1alpha1::Service::Challenge',
    });
}

sub verify_attestation {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Confidentialcomputing::V1alpha1::Service::VerifyAttestationRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.confidentialcomputing.v1alpha1.ConfidentialComputing',
        method         => 'VerifyAttestation',
        request        => $req,
        response_class => 'Google::Cloud::Confidentialcomputing::V1alpha1::Service::VerifyAttestationResponse',
    });
}

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Confidentialcomputing::V1alpha1::Service - Compiled Protocol Buffers messages for google/cloud/confidentialcomputing/v1alpha1/service.proto

=head1 SYNOPSIS

    use Google::Cloud::Confidentialcomputing::V1alpha1::Service;

    my $msg = Google::Cloud::Confidentialcomputing::V1alpha1::Service::Challenge->new({
        name => $name,
        create_time => $create_time,
        expire_time => $expire_time,
        used => $used,
    });

    # Read or update a field
    my $val = $msg->name();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Confidentialcomputing::V1alpha1::Service::Challenge->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/confidentialcomputing/v1alpha1/service.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Confidentialcomputing::V1alpha1::Service::Challenge

A Challenge from the server used to guarantee freshness of attestations

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Output only. The resource name for this Challenge in the format
`projects/*/locations/*/challenges/*`

=item * C<< $msg->create_time() >> / C<< $msg->create_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Output only. The time at which this Challenge was created

=item * C<< $msg->expire_time() >> / C<< $msg->expire_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Output only. The time at which this Challenge will no longer be usable. It
is also the expiration time for any tokens generated from this Challenge.

=item * C<< $msg->used() >> / C<< $msg->used($value) >>

Type: C<Bool>

Output only. Indicates if this challenge has been used to generate a token.

=item * C<< $msg->nonce() >> / C<< $msg->nonce($value) >>

Type: C<Bytes>

Output only. Random data which should be used when calling TPM2_Quote.
--

=back

=head2 Google::Cloud::Confidentialcomputing::V1alpha1::Service::CreateChallengeRequest

Message for creating a Challenge

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->parent() >> / C<< $msg->parent($value) >>

Type: C<String>

Required. The resource name of the location where the Challenge will be
used, in the format `projects/*/locations/*`.

=item * C<< $msg->challenge() >> / C<< $msg->challenge($value) >>

Type: C<Message> (L<Google::Cloud::Confidentialcomputing::V1alpha1::Service::Challenge>)

Required. The Challenge to be created. Currently this field can be empty as
all the Challenge fields are set by the server.

=back

=head2 Google::Cloud::Confidentialcomputing::V1alpha1::Service::VerifyAttestationRequest

A request for an OIDC token, providing all the necessary information needed
for this service to verify the plaform state of the requestor.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->challenge() >> / C<< $msg->challenge($value) >>

Type: C<String>

Required. The name of the Challenge whose nonce was used to generate the
attestation, in the format `projects/*/locations/*/challenges/*`. The
provided Challenge will be consumed, and cannot be used again.

=item * C<< $msg->gcp_credentials() >> / C<< $msg->gcp_credentials($value) >>

Type: C<Message> (L<Google::Cloud::Confidentialcomputing::V1alpha1::Service::GcpCredentials>)

Optional. Credentials used to populate the "emails" claim in the
claims_token.

=item * C<< $msg->tpm_attestation() >> / C<< $msg->tpm_attestation($value) >>

Type: C<Message> (L<Google::Cloud::Confidentialcomputing::V1alpha1::Service::TpmAttestation>)

Required. The TPM-specific data provided by the attesting platform, used to
populate any of the claims regarding platform state.

=back

=head2 Google::Cloud::Confidentialcomputing::V1alpha1::Service::VerifyAttestationResponse

A response once an attestation has been successfully verified, containing a
signed OIDC token.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->claims_token() >> / C<< $msg->claims_token($value) >>

Type: C<Bytes>

Output only. The OIDC token issued by this service. It contains specific
platform claims based on the contents of the provided attestation.
--

=back

=head2 Google::Cloud::Confidentialcomputing::V1alpha1::Service::GcpCredentials

Credentials issued by GCP which are linked to the platform attestation. These
will be verified server-side as part of attestaion verification.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->id_tokens() >> / C<< $msg->id_tokens($value) >>

Type: C<Bytes>

A list of service account OpenID Connect ID tokens identifying which
service account identities should be included in the claims_token. These
can be generated by calling `serviceAccounts.generateIdToken`. The
Challenge.name must be used as the `audience` parameter, and the
`includeEmail` parameter must be `true`.
--

=back

=head2 Google::Cloud::Confidentialcomputing::V1alpha1::Service::TpmAttestation

TPM2 data containing everything necessary to validate any platform state
measured into the TPM.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->quotes() >> / C<< $msg->quotes($value) >>

Type: C<Message> (L<Google::Cloud::Confidentialcomputing::V1alpha1::Service::TpmAttestation::Quote>)

TPM2 PCR Quotes generated by calling TPM2_Quote on each PCR bank.

=item * C<< $msg->tcg_event_log() >> / C<< $msg->tcg_event_log($value) >>

Type: C<Bytes>

The binary TCG Event Log containing events measured into the TPM by the
platform firmware and operating system. Formatted as described in the
"TCG PC Client Platform Firmware Profile Specification".

=item * C<< $msg->canonical_event_log() >> / C<< $msg->canonical_event_log($value) >>

Type: C<Bytes>

An Event Log containing additional events measured into the TPM that are
not already present in the tcg_event_log. Formatted as described in the
"Canonical Event Log Format" TCG Specification.

=item * C<< $msg->ak_cert() >> / C<< $msg->ak_cert($value) >>

Type: C<Bytes>

DER-encoded X.509 certificate of the Attestation Key (otherwise known as
an AK or a TPM restricted signing key) used to generate the quotes.

=item * C<< $msg->cert_chain() >> / C<< $msg->cert_chain($value) >>

Type: C<Bytes>

List of DER-encoded X.509 certificates which, together with the ak_cert,
chain back to a trusted Root Certificate.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Confidentialcomputing::V1alpha1::Service::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
