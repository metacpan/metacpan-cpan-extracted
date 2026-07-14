package Google::Cloud::Bigquery::V2::Project;

use strict;
use warnings;

our $VERSION = '0.05';

use Protobuf::Message;
use Protobuf::DescriptorPool;
use Protobuf::Internal qw(:all);
use MIME::Base64;

BEGIN {
    eval { require Google::Api::Auditing };
    eval { require Google::Api::FieldBehavior };
    eval { require Google::Api::Policy };
    eval { require Google::Api::Visibility };
    eval { require Google::Protobuf::Wrappers };
    my $descriptor_b64 = <<'EOF';
CiZnb29nbGUvY2xvdWQvYmlncXVlcnkvdjIvcHJvamVjdC5wcm90bxIYZ29vZ2xlLmNsb3Vk
LmJpZ3F1ZXJ5LnYyGhlnb29nbGUvYXBpL2F1ZGl0aW5nLnByb3RvGh9nb29nbGUvYXBpL2Zp
ZWxkX2JlaGF2aW9yLnByb3RvGhdnb29nbGUvYXBpL3BvbGljeS5wcm90bxobZ29vZ2xlL2Fw
aS92aXNpYmlsaXR5LnByb3RvGh5nb29nbGUvcHJvdG9idWYvd3JhcHBlcnMucHJvdG8iNgoQ
UHJvamVjdFJlZmVyZW5jZRIiCgpwcm9qZWN0X2lkGAEgASgJQgPgQQJSCXByb2plY3RJZCLo
AQoHUHJvamVjdBISCgRraW5kGAEgASgJUgRraW5kEg4KAmlkGAIgASgJUgJpZBIdCgpudW1l
cmljX2lkGAMgASgDUgludW1lcmljSWQSVwoRcHJvamVjdF9yZWZlcmVuY2UYBCABKAsyKi5n
b29nbGUuY2xvdWQuYmlncXVlcnkudjIuUHJvamVjdFJlZmVyZW5jZVIQcHJvamVjdFJlZmVy
ZW5jZRJBCg1mcmllbmRseV9uYW1lGAUgASgLMhwuZ29vZ2xlLnByb3RvYnVmLlN0cmluZ1Zh
bHVlUgxmcmllbmRseU5hbWUiowEKE0xpc3RQcm9qZWN0c1JlcXVlc3QSPQoLbWF4X3Jlc3Vs
dHMYASABKAsyHC5nb29nbGUucHJvdG9idWYuVUludDMyVmFsdWVSCm1heFJlc3VsdHMSHQoK
cGFnZV90b2tlbhgCIAEoCVIJcGFnZVRva2VuEi4KBWRlYnVnGMgBIAMoCUIX+tLkkwIREg9H
T09HTEVfSU5URVJOQUxSBWRlYnVnItoBCgtQcm9qZWN0TGlzdBISCgRraW5kGAEgASgJUgRr
aW5kEhIKBGV0YWcYAiABKAlSBGV0YWcSJgoPbmV4dF9wYWdlX3Rva2VuGAMgASgJUg1uZXh0
UGFnZVRva2VuEj0KCHByb2plY3RzGAQgAygLMiEuZ29vZ2xlLmNsb3VkLmJpZ3F1ZXJ5LnYy
LlByb2plY3RSCHByb2plY3RzEjwKC3RvdGFsX2l0ZW1zGAUgASgLMhsuZ29vZ2xlLnByb3Rv
YnVmLkludDMyVmFsdWVSCnRvdGFsSXRlbXMibgoYR2V0U2VydmljZUFjY291bnRSZXF1ZXN0
EiIKCnByb2plY3RfaWQYASABKAlCA+BBAlIJcHJvamVjdElkEi4KBWRlYnVnGMgBIAMoCUIX
+tLkkwIREg9HT09HTEVfSU5URVJOQUxSBWRlYnVnIkUKGUdldFNlcnZpY2VBY2NvdW50UmVz
cG9uc2USEgoEa2luZBgBIAEoCVIEa2luZBIUCgVlbWFpbBgCIAEoCVIFZW1haWwyzgIKDlBy
b2plY3RTZXJ2aWNlEpABCgxMaXN0UHJvamVjdHMSLS5nb29nbGUuY2xvdWQuYmlncXVlcnku
djIuTGlzdFByb2plY3RzUmVxdWVzdBolLmdvb2dsZS5jbG91ZC5iaWdxdWVyeS52Mi5Qcm9q
ZWN0TGlzdCIqQQAAAAAAAG5AeAGIAQHq6oCsAxASDkFVRElUX0VYRU1QVEVEqrvJ6QQAEqgB
ChFHZXRTZXJ2aWNlQWNjb3VudBIyLmdvb2dsZS5jbG91ZC5iaWdxdWVyeS52Mi5HZXRTZXJ2
aWNlQWNjb3VudFJlcXVlc3QaMy5nb29nbGUuY2xvdWQuYmlncXVlcnkudjIuR2V0U2Vydmlj
ZUFjY291bnRSZXNwb25zZSIqQQAAAAAAAFBAeAGIAQHq6oCsAxASDkFVRElUX0VYRU1QVEVE
qrvJ6QQAQmkKHGNvbS5nb29nbGUuY2xvdWQuYmlncXVlcnkudjJCDFByb2plY3RQcm90b1o7
Y2xvdWQuZ29vZ2xlLmNvbS9nby9iaWdxdWVyeS92Mi9hcGl2Mi9iaWdxdWVyeXBiO2JpZ3F1
ZXJ5cGJKwS8KBxIFAACkAQEKCAoBDBIDAAASCggKAQISAwIAIQoJCgIDABIDBAAjCgkKAgMB
EgMFACkKCQoCAwISAwYAIQoJCgIDAxIDBwAlCgkKAgMEEgMIACgKCAoBCBIDCgBSCgkKAggL
EgMKAFIKCAoBCBIDCwA1CgkKAggBEgMLADUKCAoBCBIDDAAtCgkKAggIEgMMAC0K0AMKAgYA
EgQXAFMBGsMDICgtLQogVGhpcyBzZXJ2aWNlIGlzIG1pcnJvcmluZyBhbiBleGlzdGluZyBB
cGlhcnkgc2VydmljZSAtIGJpZ3F1ZXJ5LnByb2plY3RzLgogQVBJIGRlZmluaXRpb246CiAg
Z29vZ2xlZGF0YS9hcGlzZXJ2aW5nL2NvbmZpZy9jbG91ZC9oZWxpeC92Mi9iYXNlLmFwaQog
IGdvb2dsZWRhdGEvYXBpc2VydmluZy9jb25maWcvY2xvdWQvaGVsaXgvdjIvdGVtcGxhdGVz
L2hlbGl4LnByb2plY3RzLmxpc3QuanNvbnQKICBnb29nbGVkYXRhL2FwaXNlcnZpbmcvY29u
ZmlnL2Nsb3VkL2hlbGl4L3YyL3RlbXBsYXRlcy9oZWxpeC5wcm9qZWN0cy5nZXRzZXJ2aWNl
YWNjb3VudC5yZXNwb25zZS5qc29udAogIGNsb3VkL2hlbGl4L3Byb3RvL2hlbGl4LnJvc3kK
IC0tKQogVGhpcyBzZXJ2aWNlIHByb3ZpZGVzIGFjY2VzcyB0byBCaWdRdWVyeSBmdW5jdGlv
bmFsaXR5IHJlbGF0ZWQgdG8gcHJvamVjdHMuCgoKCgMGAAESAxcIFgqhBgoEBgACABIEKgI3
AxqSBiBSUEMgdG8gbGlzdCBwcm9qZWN0cyB0byB3aGljaCB0aGUgdXNlciBoYXMgYmVlbiBn
cmFudGVkIGFueSBwcm9qZWN0IHJvbGUuCgogVXNlcnMgb2YgdGhpcyBtZXRob2QgYXJlIGVu
Y291cmFnZWQgdG8gY29uc2lkZXIgdGhlCiBbUmVzb3VyY2UgTWFuYWdlcl0oaHR0cHM6Ly9j
bG91ZC5nb29nbGUuY29tL3Jlc291cmNlLW1hbmFnZXIvZG9jcy8pIEFQSSwKIHdoaWNoIHBy
b3ZpZGVzIHRoZSB1bmRlcmx5aW5nIGRhdGEgZm9yIHRoaXMgbWV0aG9kIGFuZCBoYXMgbW9y
ZQogY2FwYWJpbGl0aWVzLgoKICgtLSBhcGktbGludGVyOiBzdGFuZGFyZC1tZXRob2RzPWRp
c2FibGVkIC0tKQogKC0tIGFwaS1saW50ZXI6IGNvcmU6OjAxMjc6Omh0dHAtYW5ub3RhdGlv
bj1kaXNhYmxlZAogICAgIGFpcC5kZXYvbm90LXByZWNlZGVudDogTWF0Y2hpbmcgZXhpc3Rp
bmcgQmlnUXVlcnkgQVBJcyBpbiBub3QgZGVmaW5pbmcKICAgICBodHRwIGFubm90YXRpb25z
IGluIHRoZSBzZXJ2aWNlIGRlZmluaXRpb24uIC0tKQoKICMgSUFNIFBlcm1pc3Npb25zCgog
UmVxdWlyZXMgbm8gc3BlY2lmaWMgSUFNIHBlcm1pc3Npb24ocykgdG8gdXNlIHRoaXMgbWV0
aG9kLgogVGhlIHJlc3VsdHMgYXJlIGZpbHRlcmVkIHRvIG9ubHkgaW5jbHVkZSBwcm9qZWN0
cyBvbiB3aGljaCB0aGUgY2FsbGVyIGhhcwogYmVlbiBncmFudGVkIGEgcHJvamVjdC1sZXZl
bCByb2xlIHN1Y2ggYXMgYSBCaWdRdWVyeSBwcmVkZWZpbmVkIElBTSByb2xlIG9yCiBhIGJh
c2ljIHJvbGUgc3VjaCBhcyBWaWV3ZXIgb3IgT3duZXIuCgoMCgUGAAIAARIDKgYSCgwKBQYA
AgACEgMqEyYKDAoFBgACAAMSAyoxPAoNCgUGAAIABBIEKwQtBgoRCgkGAAIABLWXmU0SBCsE
LQYKDAoFBgACAAQSAy4ELQoNCgYGAAIABBESAy4ELQoMCgUGAAIABBIDLwQuCg0KBgYAAgAE
DxIDLwQuCgwKBQYAAgAEEgMyBBoKLQoGBgACAAQIEgMyBBoaHiBSZXF1ZXN0IGRlYWRsaW5l
IGluIHNlY29uZHMuCgoMCgUGAAIABBIDNgRFCpoBCgoGAAIABK2NwDUCEgM2BEUahgEgTWFy
ayBhcyBleGVtcHRlZCBmb3IgUkVBRCB0eXBlIG9mIGV2ZW50cyBkdWUgdG8gc2NhbGluZyBj
b25jZXJucy4KIEFkanVzdCBhY2NvcmRpbmdseSBvbmNlIHRoZSB0cmFmZmljIHBhdHRlcm4g
aXMgYmV0dGVyIHVuZGVyc3Rvb2QuCgq+BAoEBgACARIERAJSAxqvBCAoLS0KICAgYXBpLWxp
bnRlcjogY29yZTo6MDEyNzo6cmVzb3VyY2UtbmFtZS1leHRyYWN0aW9uPWRpc2FibGVkCiAg
IGFwaS1saW50ZXI6IGNvcmU6OjAxMzE6Omh0dHAtdXJpLW5hbWU9ZGlzYWJsZWQKICAgYXBp
LWxpbnRlcjogY29yZTo6MDEzMTo6bWV0aG9kLXNpZ25hdHVyZT1kaXNhYmxlZAogICBhaXAu
ZGV2L25vdC1wcmVjZWRlbnQ6IEJRIFJQQyBkZWZpbml0aW9ucyBwcmVkYXRlIEFJUCBndWlk
YW5jZS4KIC0tKQogUlBDIHRvIGdldCB0aGUgc2VydmljZSBhY2NvdW50IGZvciBhIHByb2pl
Y3QgdXNlZCBmb3IgaW50ZXJhY3Rpb25zIHdpdGgKIEdvb2dsZSBDbG91ZCBLTVMuIFJlcXVp
cmVzIHRoZSBgYmlncXVlcnkuam9icy5jcmVhdGVgIHBlcm1pc3Npb24gb24gdGhlCiBwcm9q
ZWN0IHJlc291cmNlLiBUaGlzIHBlcm1pc3Npb24gaXMgcmVxdWlyZWQgdG8gYXV0aG9yaXpl
IHRoZSByZXRyaWV2YWwKIG9mIHRoZSBwcm9qZWN0J3Mgc2VydmljZSBpZGVudGl0eSBmb3Ig
dGVjaG5pY2FsIG1hbmFnZW1lbnQgdGFza3MgbGlrZQogZW5jcnlwdGlvbiBjb25maWd1cmF0
aW9uLgoKDAoFBgACAQESA0QGFwoMCgUGAAIBAhIDRBgwCgwKBQYAAgEDEgNFDygKDQoFBgAC
AQQSBEYESAYKEQoJBgACAQS1l5lNEgRGBEgGCgwKBQYAAgEEEgNJBC0KDQoGBgACAQQREgNJ
BC0KDAoFBgACAQQSA0oELgoNCgYGAAIBBA8SA0oELgoMCgUGAAIBBBIDTQQZCi0KBgYAAgEE
CBIDTQQZGh4gUmVxdWVzdCBkZWFkbGluZSBpbiBzZWNvbmRzLgoKDAoFBgACAQQSA1EERQqa
AQoKBgACAQStjcA1AhIDUQRFGoYBIE1hcmsgYXMgZXhlbXB0ZWQgZm9yIFJFQUQgdHlwZSBv
ZiBldmVudHMgZHVlIHRvIHNjYWxpbmcgY29uY2VybnMuCiBBZGp1c3QgYWNjb3JkaW5nbHkg
b25jZSB0aGUgdHJhZmZpYyBwYXR0ZXJuIGlzIGJldHRlciB1bmRlcnN0b29kLgoKLgoCBAAS
BFYAWgEaIiBBIHVuaXF1ZSByZWZlcmVuY2UgdG8gYSBwcm9qZWN0LgoKCgoDBAABEgNWCBgK
YgoEBAACABIDWQJBGlUgSUQgb2YgdGhlIHByb2plY3QuCiBDYW4gYmUgZWl0aGVyIHRoZSBu
dW1lcmljIElEIG9yIHRoZSBhc3NpZ25lZCBJRCBvZiB0aGUgcHJvamVjdC4KCgwKBQQAAgAF
EgNZAggKDAoFBAACAAESA1kJEwoMCgUEAAIAAxIDWRYXCgwKBQQAAgAIEgNZGEAKDwoIBAAC
AAicCAASA1kZPwpJCgIEARIEXgBqARo9IEluZm9ybWF0aW9uIGFib3V0IGEgc2luZ2xlIHBy
b2plY3QuCiAoPT0gaW5saW5lX21lc3NhZ2UgPT0pCgoKCgMEAQESA14IDwohCgQEAQIAEgNg
AhIaFCBUaGUgcmVzb3VyY2UgdHlwZS4KCgwKBQQBAgAFEgNgAggKDAoFBAECAAESA2AJDQoM
CgUEAQIAAxIDYBARCiwKBAQBAgESA2ICEBofIEFuIG9wYXF1ZSBJRCBvZiB0aGlzIHByb2pl
Y3QuCgoMCgUEAQIBBRIDYgIICgwKBQQBAgEBEgNiCQsKDAoFBAECAQMSA2IODwouCgQEAQIC
EgNkAhcaISBUaGUgbnVtZXJpYyBJRCBvZiB0aGlzIHByb2plY3QuCgoMCgUEAQICBRIDZAIH
CgwKBQQBAgIBEgNkCBIKDAoFBAECAgMSA2QVFgoyCgQEAQIDEgNmAikaJSBBIHVuaXF1ZSBy
ZWZlcmVuY2UgdG8gdGhpcyBwcm9qZWN0LgoKDAoFBAECAwYSA2YCEgoMCgUEAQIDARIDZhMk
CgwKBQQBAgMDEgNmJygKgAEKBAQBAgQSA2kCMBpzIEEgZGVzY3JpcHRpdmUgbmFtZSBmb3Ig
dGhpcyBwcm9qZWN0LgogQSB3cmFwcGVyIGlzIHVzZWQgaGVyZSBiZWNhdXNlIGZyaWVuZGx5
TmFtZSBjYW4gYmUgc2V0IHRvIHRoZSBlbXB0eSBzdHJpbmcuCgoMCgUEAQIEBhIDaQIdCgwK
BQQBAgQBEgNpHisKDAoFBAECBAMSA2kuLwqfBAoCBAISBXEAggEBGpwCIFJlcXVlc3Qgb2Jq
ZWN0IG9mIExpc3RQcm9qZWN0cwogKC0tIGFwaS1saW50ZXI6IGNvcmU6OjAxNTg6OnJlcXVl
c3QtcGFnZS1zaXplLWZpZWxkPWRpc2FibGVkCiAgICAgYWlwLmRldi9ub3QtcHJlY2VkZW50
OiBUaGlzIEFQSSBwcmVkYXRlcyBBSVAgZ3VpZGFuY2UuIC0tKQogKC0tIGFwaS1saW50ZXI6
IGNvcmU6OjAxMzI6OnJlcXVlc3QtcGFyZW50LXJlcXVpcmVkPWRpc2FibGVkCiAgICAgYWlw
LmRldi9ub3QtcHJlY2VkZW50OiBUaGlzIEFQSSBwcmVkYXRlcyBBSVAgZ3VpZGFuY2UuIC0t
KQoi8gEgVGhlIG1heGltdW0gbnVtYmVyIG9mIHJlc3VsdHMgdG8gcmV0dXJuIGluIGEgc2lu
Z2xlIHBhZ2UuIFRvIHZpZXcgbW9yZQogcmVzdWx0cywgY2FsbCB0aGlzIG1ldGhvZCBtdWx0
aXBsZSB0aW1lcy4gVG8gZG8gdGhpcywgc2V0IHRoZSBgcGFnZVRva2VuYAogcGFyYW1ldGVy
IG9mIHRoZSBzdWJzZXF1ZW50IHJlcXVlc3QgdG8gdGhlIGBuZXh0UGFnZVRva2VuYCB2YWx1
ZSBmcm9tIHRoZQogcHJldmlvdXMgcmVzcG9uc2UuCgoKCgMEAgESA3EIGwr6AQoEBAICABID
ewIuGuwBYG1heFJlc3VsdHNgIHVuc2V0IHJldHVybnMgYWxsIHJlc3VsdHMsIHVwIHRvIDUw
IHBlciBwYWdlLgogQWRkaXRpb25hbGx5LCB0aGUgbnVtYmVyIG9mIHByb2plY3RzIGluIGEg
cGFnZSBtYXkgYmUgZmV3ZXIgdGhhbgpgbWF4UmVzdWx0c2AgYmVjYXVzZSBwcm9qZWN0cyBh
cmUgcmV0cmlldmVkIGFuZCB0aGVuIGZpbHRlcmVkIHRvIG9ubHkKIHByb2plY3RzIHdpdGgg
dGhlIEJpZ1F1ZXJ5IEFQSSBlbmFibGVkLgoKDAoFBAICAAYSA3sCHQoMCgUEAgIAARIDex4p
CgwKBQQCAgADEgN7LC0KjAEKBAQCAgESA34CGBp/IFBhZ2UgdG9rZW4sIHJldHVybmVkIGJ5
IGEgcHJldmlvdXMgY2FsbCwgdG8gcmVxdWVzdCB0aGUgbmV4dCBwYWdlIG9mCiByZXN1bHRz
LiAgSWYgbm90IHByZXNlbnQsIG5vIGZ1cnRoZXIgcGFnZXMgYXJlIHByZXNlbnQuCgoMCgUE
AgIBBRIDfgIICgwKBQQCAgEBEgN+CRMKDAoFBAICAQMSA34WFwooCgQEAgICEgaAAQKBAUYa
GCBEZWJ1ZyBpbmZvIGFzIGEgc3RyaW5nCgoNCgUEAgICBBIEgAECCgoNCgUEAgICBRIEgAEL
EQoNCgUEAgICARIEgAESFwoNCgUEAgICAxIEgAEaHQoNCgUEAgICCBIEgQEGRQoSCgoEAgIC
CK/KvCICEgSBAQdECi8KAgQDEgaFAQCTAQEaISBSZXNwb25zZSBvYmplY3Qgb2YgTGlzdFBy
b2plY3RzCgoLCgMEAwESBIUBCBMKMgoEBAMCABIEhwECEhokIFRoZSByZXNvdXJjZSB0eXBl
IG9mIHRoZSByZXNwb25zZS4KCg0KBQQDAgAFEgSHAQIICg0KBQQDAgABEgSHAQkNCg0KBQQD
AgADEgSHARARCi4KBAQDAgESBIkBAhIaICBBIGhhc2ggb2YgdGhlIHBhZ2Ugb2YgcmVzdWx0
cy4KCg0KBQQDAgEFEgSJAQIICg0KBQQDAgEBEgSJAQkNCg0KBQQDAgEDEgSJARARCkMKBAQD
AgISBIsBAh0aNSBVc2UgdGhpcyB0b2tlbiB0byByZXF1ZXN0IHRoZSBuZXh0IHBhZ2Ugb2Yg
cmVzdWx0cy4KCg0KBQQDAgIFEgSLAQIICg0KBQQDAgIBEgSLAQkYCg0KBQQDAgIDEgSLARsc
CnUKBAQDAgMSBI4BAiAaZyBQcm9qZWN0cyB0byB3aGljaCB0aGUgdXNlciBoYXMgYXQgbGVh
c3QgUkVBRCBhY2Nlc3MuCiBUaGlzIGZpZWxkIGNhbiBiZSBvbWl0dGVkIGlmIGB0b3RhbEl0
ZW1zYCBpcyAwLgoKDQoFBAMCAwQSBI4BAgoKDQoFBAMCAwYSBI4BCxIKDQoFBAMCAwESBI4B
ExsKDQoFBAMCAwMSBI4BHh8KmgEKBAQDAgQSBJIBAi0aiwEgVGhlIHRvdGFsIG51bWJlciBv
ZiBwcm9qZWN0cyBpbiB0aGUgcGFnZS4KIEEgd3JhcHBlciBpcyB1c2VkIGhlcmUgYmVjYXVz
ZSB0aGUgZmllbGQgc2hvdWxkIHN0aWxsIGJlIGluIHRoZSByZXNwb25zZQogd2hlbiB0aGUg
dmFsdWUgaXMgMC4KCg0KBQQDAgQGEgSSAQIcCg0KBQQDAgQBEgSSAR0oCg0KBQQDAgQDEgSS
ASssCjMKAgQEEgaWAQCcAQEaJSBSZXF1ZXN0IG9iamVjdCBvZiBHZXRTZXJ2aWNlQWNjb3Vu
dAoKCwoDBAQBEgSWAQggCiIKBAQEAgASBJgBAkEaFCBJRCBvZiB0aGUgcHJvamVjdC4KCg0K
BQQEAgAFEgSYAQIICg0KBQQEAgABEgSYAQkTCg0KBQQEAgADEgSYARYXCg0KBQQEAgAIEgSY
ARhAChAKCAQEAgAInAgAEgSYARk/CigKBAQEAgESBpoBApsBRhoYIERlYnVnIGluZm8gYXMg
YSBzdHJpbmcKCg0KBQQEAgEEEgSaAQIKCg0KBQQEAgEFEgSaAQsRCg0KBQQEAgEBEgSaARIX
Cg0KBQQEAgEDEgSaARodCg0KBQQEAgEIEgSbAQZFChIKCgQEAgEIr8q8IgISBJsBB0QKNAoC
BAUSBp8BAKQBARomIFJlc3BvbnNlIG9iamVjdCBvZiBHZXRTZXJ2aWNlQWNjb3VudAoKCwoD
BAUBEgSfAQghCjIKBAQFAgASBKEBAhIaJCBUaGUgcmVzb3VyY2UgdHlwZSBvZiB0aGUgcmVz
cG9uc2UuCgoNCgUEBQIABRIEoQECCAoNCgUEBQIAARIEoQEJDQoNCgUEBQIAAxIEoQEQEQoy
CgQEBQIBEgSjAQITGiQgVGhlIHNlcnZpY2UgYWNjb3VudCBlbWFpbCBhZGRyZXNzLgoKDQoF
BAUCAQUSBKMBAggKDQoFBAUCAQESBKMBCQ4KDQoFBAUCAQMSBKMBERJiBnByb3RvMw==
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Bigquery::V2::Project::ProjectReference ===
    # Fields for ProjectReference
    # Field: project_id Type: 9 ()

# === Message: Google::Cloud::Bigquery::V2::Project::Project ===
    # Fields for Project
    # Field: kind Type: 9 ()
    # Field: id Type: 9 ()
    # Field: numeric_id Type: 3 ()
    # Field: project_reference Type: 11 (.google.cloud.bigquery.v2.ProjectReference)
    # Field: friendly_name Type: 11 (.google.protobuf.StringValue)

# === Message: Google::Cloud::Bigquery::V2::Project::ListProjectsRequest ===
    # Fields for ListProjectsRequest
    # Field: max_results Type: 11 (.google.protobuf.UInt32Value)
    # Field: page_token Type: 9 ()
    # Field: debug Type: 9 ()

# === Message: Google::Cloud::Bigquery::V2::Project::ProjectList ===
    # Fields for ProjectList
    # Field: kind Type: 9 ()
    # Field: etag Type: 9 ()
    # Field: next_page_token Type: 9 ()
    # Field: projects Type: 11 (.google.cloud.bigquery.v2.Project)
    # Field: total_items Type: 11 (.google.protobuf.Int32Value)

# === Message: Google::Cloud::Bigquery::V2::Project::GetServiceAccountRequest ===
    # Fields for GetServiceAccountRequest
    # Field: project_id Type: 9 ()
    # Field: debug Type: 9 ()

# === Message: Google::Cloud::Bigquery::V2::Project::GetServiceAccountResponse ===
    # Fields for GetServiceAccountResponse
    # Field: kind Type: 9 ()
    # Field: email Type: 9 ()

# === Service Client: Google::Cloud::Bigquery::V2::Project::ProjectServiceClient ===
package Google::Cloud::Bigquery::V2::Project::ProjectServiceClient;

=pod

=head1 NAME

Google::Cloud::Bigquery::V2::Project::ProjectServiceClient - Client stub representing the remote ProjectService service

=head1 DESCRIPTION

This class acts as a local client stub for the remote gRPC service.
It delegates call dispatching to an underlying L<Google::gRPC::Client>
instance, ensuring type-safe request parsing and response mapping.

=head1 CONFIGURATION AND ENVIRONMENT

=head2 target

The endpoint target address. Defaults to C<bigquery.googleapis.com:443>.

=head2 credentials

The authentication credentials provider. Defaults to application default credentials via L<Google::Auth>.

=cut

use Moo;
use Google::Auth;
use Google::gRPC::Client;

has credentials => ( is => 'ro', default => sub { Google::Auth->default() } );
has target      => ( is => 'ro', default => 'bigquery.googleapis.com:443' );

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

sub list_projects {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Bigquery::V2::Project::ListProjectsRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.bigquery.v2.ProjectService',
        method         => 'ListProjects',
        request        => $req,
        response_class => 'Google::Cloud::Bigquery::V2::Project::ProjectList',
    });
}

sub get_service_account {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Bigquery::V2::Project::GetServiceAccountRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.bigquery.v2.ProjectService',
        method         => 'GetServiceAccount',
        request        => $req,
        response_class => 'Google::Cloud::Bigquery::V2::Project::GetServiceAccountResponse',
    });
}

1;
