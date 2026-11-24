package Google::Cloud::Cloudcontrolspartner::V1::CustomerWorkloads;

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
    eval { require Google::Cloud::Cloudcontrolspartner::V1::CompletionState };
    eval { require Google::Protobuf::Timestamp };
    my $descriptor_b64 = <<'EOF';
Cj1nb29nbGUvY2xvdWQvY2xvdWRjb250cm9sc3BhcnRuZXIvdjEvY3VzdG9tZXJfd29ya2xv
YWRzLnByb3RvEiRnb29nbGUuY2xvdWQuY2xvdWRjb250cm9sc3BhcnRuZXIudjEaH2dvb2ds
ZS9hcGkvZmllbGRfYmVoYXZpb3IucHJvdG8aGWdvb2dsZS9hcGkvcmVzb3VyY2UucHJvdG8a
O2dvb2dsZS9jbG91ZC9jbG91ZGNvbnRyb2xzcGFydG5lci92MS9jb21wbGV0aW9uX3N0YXRl
LnByb3RvGh9nb29nbGUvcHJvdG9idWYvdGltZXN0YW1wLnByb3RvIrcHCghXb3JrbG9hZBIX
CgRuYW1lGAEgASgJQgPgQQhSBG5hbWUSIAoJZm9sZGVyX2lkGAIgASgDQgPgQQNSCGZvbGRl
cklkEkAKC2NyZWF0ZV90aW1lGAMgASgLMhouZ29vZ2xlLnByb3RvYnVmLlRpbWVzdGFtcEID
4EEDUgpjcmVhdGVUaW1lEhsKBmZvbGRlchgEIAEoCUID4EEDUgZmb2xkZXISeQoZd29ya2xv
YWRfb25ib2FyZGluZ19zdGF0ZRgFIAEoCzI9Lmdvb2dsZS5jbG91ZC5jbG91ZGNvbnRyb2xz
cGFydG5lci52MS5Xb3JrbG9hZE9uYm9hcmRpbmdTdGF0ZVIXd29ya2xvYWRPbmJvYXJkaW5n
U3RhdGUSIQoMaXNfb25ib2FyZGVkGAYgASgIUgtpc09uYm9hcmRlZBI5ChlrZXlfbWFuYWdl
bWVudF9wcm9qZWN0X2lkGAcgASgJUhZrZXlNYW5hZ2VtZW50UHJvamVjdElkEhoKCGxvY2F0
aW9uGAggASgJUghsb2NhdGlvbhJQCgdwYXJ0bmVyGAkgASgOMjYuZ29vZ2xlLmNsb3VkLmNs
b3VkY29udHJvbHNwYXJ0bmVyLnYxLldvcmtsb2FkLlBhcnRuZXJSB3BhcnRuZXIiogIKB1Bh
cnRuZXISFwoTUEFSVE5FUl9VTlNQRUNJRklFRBAAEiIKHlBBUlRORVJfTE9DQUxfQ09OVFJP
TFNfQllfUzNOUxABEisKJ1BBUlRORVJfU09WRVJFSUdOX0NPTlRST0xTX0JZX1RfU1lTVEVN
UxACEi0KKVBBUlRORVJfU09WRVJFSUdOX0NPTlRST0xTX0JZX1NJQV9NSU5TQUlUEAMSJQoh
UEFSVE5FUl9TT1ZFUkVJR05fQ09OVFJPTFNfQllfUFNOEAQSJwojUEFSVE5FUl9TT1ZFUkVJ
R05fQ09OVFJPTFNfQllfQ05UWFQQBhIuCipQQVJUTkVSX1NPVkVSRUlHTl9DT05UUk9MU19C
WV9DTlRYVF9OT19FS00QBzqkAepBoAEKLGNsb3VkY29udHJvbHNwYXJ0bmVyLmdvb2dsZWFw
aXMuY29tL1dvcmtsb2FkEltvcmdhbml6YXRpb25zL3tvcmdhbml6YXRpb259L2xvY2F0aW9u
cy97bG9jYXRpb259L2N1c3RvbWVycy97Y3VzdG9tZXJ9L3dvcmtsb2Fkcy97d29ya2xvYWR9
Kgl3b3JrbG9hZHMyCHdvcmtsb2FkIt0BChRMaXN0V29ya2xvYWRzUmVxdWVzdBJMCgZwYXJl
bnQYASABKAlCNOBBAvpBLhIsY2xvdWRjb250cm9sc3BhcnRuZXIuZ29vZ2xlYXBpcy5jb20v
V29ya2xvYWRSBnBhcmVudBIbCglwYWdlX3NpemUYAiABKAVSCHBhZ2VTaXplEh0KCnBhZ2Vf
dG9rZW4YAyABKAlSCXBhZ2VUb2tlbhIbCgZmaWx0ZXIYBCABKAlCA+BBAVIGZmlsdGVyEh4K
CG9yZGVyX2J5GAUgASgJQgPgQQFSB29yZGVyQnkirwEKFUxpc3RXb3JrbG9hZHNSZXNwb25z
ZRJMCgl3b3JrbG9hZHMYASADKAsyLi5nb29nbGUuY2xvdWQuY2xvdWRjb250cm9sc3BhcnRu
ZXIudjEuV29ya2xvYWRSCXdvcmtsb2FkcxImCg9uZXh0X3BhZ2VfdG9rZW4YAiABKAlSDW5l
eHRQYWdlVG9rZW4SIAoLdW5yZWFjaGFibGUYAyADKAlSC3VucmVhY2hhYmxlIl4KEkdldFdv
cmtsb2FkUmVxdWVzdBJICgRuYW1lGAEgASgJQjTgQQL6QS4KLGNsb3VkY29udHJvbHNwYXJ0
bmVyLmdvb2dsZWFwaXMuY29tL1dvcmtsb2FkUgRuYW1lIoIBChdXb3JrbG9hZE9uYm9hcmRp
bmdTdGF0ZRJnChBvbmJvYXJkaW5nX3N0ZXBzGAEgAygLMjwuZ29vZ2xlLmNsb3VkLmNsb3Vk
Y29udHJvbHNwYXJ0bmVyLnYxLldvcmtsb2FkT25ib2FyZGluZ1N0ZXBSD29uYm9hcmRpbmdT
dGVwcyKwAwoWV29ya2xvYWRPbmJvYXJkaW5nU3RlcBJVCgRzdGVwGAEgASgOMkEuZ29vZ2xl
LmNsb3VkLmNsb3VkY29udHJvbHNwYXJ0bmVyLnYxLldvcmtsb2FkT25ib2FyZGluZ1N0ZXAu
U3RlcFIEc3RlcBI5CgpzdGFydF90aW1lGAIgASgLMhouZ29vZ2xlLnByb3RvYnVmLlRpbWVz
dGFtcFIJc3RhcnRUaW1lEkMKD2NvbXBsZXRpb25fdGltZRgDIAEoCzIaLmdvb2dsZS5wcm90
b2J1Zi5UaW1lc3RhbXBSDmNvbXBsZXRpb25UaW1lEmUKEGNvbXBsZXRpb25fc3RhdGUYBCAB
KA4yNS5nb29nbGUuY2xvdWQuY2xvdWRjb250cm9sc3BhcnRuZXIudjEuQ29tcGxldGlvblN0
YXRlQgPgQQNSD2NvbXBsZXRpb25TdGF0ZSJYCgRTdGVwEhQKEFNURVBfVU5TUEVDSUZJRUQQ
ABITCg9FS01fUFJPVklTSU9ORUQQARIlCiFTSUdORURfQUNDRVNTX0FQUFJPVkFMX0NPTkZJ
R1VSRUQQAkKaAgooY29tLmdvb2dsZS5jbG91ZC5jbG91ZGNvbnRyb2xzcGFydG5lci52MUIW
Q3VzdG9tZXJXb3JrbG9hZHNQcm90b1ABWlxjbG91ZC5nb29nbGUuY29tL2dvL2Nsb3VkY29u
dHJvbHNwYXJ0bmVyL2FwaXYxL2Nsb3VkY29udHJvbHNwYXJ0bmVycGI7Y2xvdWRjb250cm9s
c3BhcnRuZXJwYqoCJEdvb2dsZS5DbG91ZC5DbG91ZENvbnRyb2xzUGFydG5lci5WMcoCJEdv
b2dsZVxDbG91ZFxDbG91ZENvbnRyb2xzUGFydG5lclxWMeoCJ0dvb2dsZTo6Q2xvdWQ6OkNs
b3VkQ29udHJvbHNQYXJ0bmVyOjpWMUr4KwoHEgUOALUBAQq8BAoBDBIDDgASMrEEIENvcHly
aWdodCAyMDI1IEdvb2dsZSBMTEMKCiBMaWNlbnNlZCB1bmRlciB0aGUgQXBhY2hlIExpY2Vu
c2UsIFZlcnNpb24gMi4wICh0aGUgIkxpY2Vuc2UiKTsKIHlvdSBtYXkgbm90IHVzZSB0aGlz
IGZpbGUgZXhjZXB0IGluIGNvbXBsaWFuY2Ugd2l0aCB0aGUgTGljZW5zZS4KIFlvdSBtYXkg
b2J0YWluIGEgY29weSBvZiB0aGUgTGljZW5zZSBhdAoKICAgICBodHRwOi8vd3d3LmFwYWNo
ZS5vcmcvbGljZW5zZXMvTElDRU5TRS0yLjAKCiBVbmxlc3MgcmVxdWlyZWQgYnkgYXBwbGlj
YWJsZSBsYXcgb3IgYWdyZWVkIHRvIGluIHdyaXRpbmcsIHNvZnR3YXJlCiBkaXN0cmlidXRl
ZCB1bmRlciB0aGUgTGljZW5zZSBpcyBkaXN0cmlidXRlZCBvbiBhbiAiQVMgSVMiIEJBU0lT
LAogV0lUSE9VVCBXQVJSQU5USUVTIE9SIENPTkRJVElPTlMgT0YgQU5ZIEtJTkQsIGVpdGhl
ciBleHByZXNzIG9yIGltcGxpZWQuCiBTZWUgdGhlIExpY2Vuc2UgZm9yIHRoZSBzcGVjaWZp
YyBsYW5ndWFnZSBnb3Zlcm5pbmcgcGVybWlzc2lvbnMgYW5kCiBsaW1pdGF0aW9ucyB1bmRl
ciB0aGUgTGljZW5zZS4KCggKAQISAxAALQoJCgIDABIDEgApCgkKAgMBEgMTACMKCQoCAwIS
AxQARQoJCgIDAxIDFQApCggKAQgSAxcAQQoJCgIIJRIDFwBBCggKAQgSAxgAcwoJCgIICxID
GABzCggKAQgSAxkAIgoJCgIIChIDGQAiCggKAQgSAxoANwoJCgIICBIDGgA3CggKAQgSAxsA
QQoJCgIIARIDGwBBCggKAQgSAxwAQQoJCgIIKRIDHABBCggKAQgSAx0AQAoJCgIILRIDHQBA
CrUBCgIEABIEIgBfARqoASBDb250YWlucyBtZXRhZGF0YSBhcm91bmQgdGhlIFtXb3JrbG9h
ZAogcmVzb3VyY2VdKGh0dHBzOi8vY2xvdWQuZ29vZ2xlLmNvbS9hc3N1cmVkLXdvcmtsb2Fk
cy9kb2NzL3JlZmVyZW5jZS9yZXN0L1NoYXJlZC5UeXBlcy9Xb3JrbG9hZCkKIGluIHRoZSBB
c3N1cmVkIFdvcmtsb2FkcyBBUEkuCgoKCgMEAAESAyIIEAoLCgMEAAcSBCMCKAQKDQoFBAAH
nQgSBCMCKAQKNQoEBAAEABIEKwJBAxonIFN1cHBvcnRlZCBBc3N1cmVkIFdvcmtsb2FkcyBQ
YXJ0bmVycy4KCgwKBQQABAABEgMrBw4KIQoGBAAEAAIAEgMtBBwaEiBVbmtub3duIFBhcnRu
ZXIuCgoOCgcEAAQAAgABEgMtBBcKDgoHBAAEAAIAAhIDLRobCjkKBgQABAACARIDMAQnGiog
RW51bSByZXByZXNlbnRpbmcgUzNOUyAoVGhhbGVzKSBwYXJ0bmVyLgoKDgoHBAAEAAIBARID
MAQiCg4KBwQABAACAQISAzAlJgo6CgYEAAQAAgISAzMEMBorIEVudW0gcmVwcmVzZW50aW5n
IFRfU1lTVEVNIChUU0kpIHBhcnRuZXIuCgoOCgcEAAQAAgIBEgMzBCsKDgoHBAAEAAICAhID
My4vCj8KBgQABAACAxIDNgQyGjAgRW51bSByZXByZXNlbnRpbmcgU0lBX01JTlNBSVQgKElu
ZHJhKSBwYXJ0bmVyLgoKDgoHBAAEAAIDARIDNgQtCg4KBwQABAACAwISAzYwMQo1CgYEAAQA
AgQSAzkEKhomIEVudW0gcmVwcmVzZW50aW5nIFBTTiAoVElNKSBwYXJ0bmVyLgoKDgoHBAAE
AAIEARIDOQQlCg4KBwQABAACBAISAzkoKQpLCgYEAAQAAgUSAzwELBo8IEVudW0gcmVwcmVz
ZW50aW5nIENOVFhUIChLaW5nZG9tIG9mIFNhdWRpIEFyYWJpYSkgcGFydG5lci4KCg4KBwQA
BAACBQESAzwEJwoOCgcEAAQAAgUCEgM8KisKbQoGBAAEAAIGEgNABDMaXiBFbnVtIHJlcHJl
c2VudGluZyBDTlhUIChLaW5nZG9tIG9mIFNhdWRpIEFyYWJpYSkgcGFydG5lciBvZmZlcmlu
ZyB3aXRob3V0CiBFS00gcHJvdmlzaW9uaW5nLgoKDgoHBAAEAAIGARIDQAQuCg4KBwQABAAC
BgISA0AxMgqBAQoEBAACABIDRQI9GnQgSWRlbnRpZmllci4gRm9ybWF0OgogYG9yZ2FuaXph
dGlvbnMve29yZ2FuaXphdGlvbn0vbG9jYXRpb25zL3tsb2NhdGlvbn0vY3VzdG9tZXJzL3tj
dXN0b21lcn0vd29ya2xvYWRzL3t3b3JrbG9hZH1gCgoMCgUEAAIABRIDRQIICgwKBQQAAgAB
EgNFCQ0KDAoFBAACAAMSA0UQEQoMCgUEAAIACBIDRRI8Cg8KCAQAAgAInAgAEgNFEzsKRgoE
BAACARIDSAJCGjkgT3V0cHV0IG9ubHkuIEZvbGRlciBpZCB0aGlzIHdvcmtsb2FkIGlzIGFz
c29jaWF0ZWQgd2l0aAoKDAoFBAACAQUSA0gCBwoMCgUEAAIBARIDSAgRCgwKBQQAAgEDEgNI
FBUKDAoFBAACAQgSA0gWQQoPCggEAAIBCJwIABIDSBdACjsKBAQAAgISBEsCTDIaLSBPdXRw
dXQgb25seS4gVGltZSB0aGUgcmVzb3VyY2Ugd2FzIGNyZWF0ZWQuCgoMCgUEAAICBhIDSwIb
CgwKBQQAAgIBEgNLHCcKDAoFBAACAgMSA0sqKwoMCgUEAAICCBIDTAYxCg8KCAQAAgIInAgA
EgNMBzAKUAoEBAACAxIDTwJAGkMgT3V0cHV0IG9ubHkuIFRoZSBuYW1lIG9mIGNvbnRhaW5l
ciBmb2xkZXIgb2YgdGhlIGFzc3VyZWQgd29ya2xvYWQKCgwKBQQAAgMFEgNPAggKDAoFBAAC
AwESA08JDwoMCgUEAAIDAxIDTxITCgwKBQQAAgMIEgNPFD8KDwoIBAACAwicCAASA08VPgo3
CgQEAAIEEgNSAjgaKiBDb250YWluZXIgZm9yIHdvcmtsb2FkIG9uYm9hcmRpbmcgc3RlcHMu
CgoMCgUEAAIEBhIDUgIZCgwKBQQAAgQBEgNSGjMKDAoFBAACBAMSA1I2Nwo/CgQEAAIFEgNV
AhgaMiBJbmRpY2F0ZXMgd2hldGhlciBhIHdvcmtsb2FkIGlzIGZ1bGx5IG9uYm9hcmRlZC4K
CgwKBQQAAgUFEgNVAgYKDAoFBAACBQESA1UHEwoMCgUEAAIFAxIDVRYXCkwKBAQAAgYSA1gC
Jxo/IFRoZSBwcm9qZWN0IGlkIG9mIHRoZSBrZXkgbWFuYWdlbWVudCBwcm9qZWN0IGZvciB0
aGUgd29ya2xvYWQKCgwKBQQAAgYFEgNYAggKDAoFBAACBgESA1gJIgoMCgUEAAIGAxIDWCUm
CjgKBAQAAgcSA1sCFhorIFRoZSBHb29nbGUgQ2xvdWQgbG9jYXRpb24gb2YgdGhlIHdvcmts
b2FkCgoMCgUEAAIHBRIDWwIICgwKBQQAAgcBEgNbCREKDAoFBAACBwMSA1sUFQo1CgQEAAII
EgNeAhYaKCBQYXJ0bmVyIGFzc29jaWF0ZWQgd2l0aCB0aGlzIHdvcmtsb2FkLgoKDAoFBAAC
CAYSA14CCQoMCgUEAAIIARIDXgoRCgwKBQQAAggDEgNeFBUKMQoCBAESBGIAegEaJSBSZXF1
ZXN0IHRvIGxpc3QgY3VzdG9tZXIgd29ya2xvYWRzLgoKCgoDBAEBEgNiCBwKfAoEBAECABIE
ZgJrBBpuIFJlcXVpcmVkLiBQYXJlbnQgcmVzb3VyY2UKIEZvcm1hdDoKIGBvcmdhbml6YXRp
b25zL3tvcmdhbml6YXRpb259L2xvY2F0aW9ucy97bG9jYXRpb259L2N1c3RvbWVycy97Y3Vz
dG9tZXJ9YAoKDAoFBAECAAUSA2YCCAoMCgUEAQIAARIDZgkPCgwKBQQBAgADEgNmEhMKDQoF
BAECAAgSBGYUawMKDwoIBAECAAicCAASA2cEKgoPCgcEAQIACJ8IEgRoBGoFCqEBCgQEAQIB
EgNvAhYakwEgVGhlIG1heGltdW0gbnVtYmVyIG9mIHdvcmtsb2FkcyB0byByZXR1cm4uIFRo
ZSBzZXJ2aWNlIG1heSByZXR1cm4gZmV3ZXIKIHRoYW4gdGhpcyB2YWx1ZS4gSWYgdW5zcGVj
aWZpZWQsIGF0IG1vc3QgNTAwIHdvcmtsb2FkcyB3aWxsIGJlIHJldHVybmVkLgoKDAoFBAEC
AQUSA28CBwoMCgUEAQIBARIDbwgRCgwKBQQBAgEDEgNvFBUKegoEBAECAhIDcwIYGm0gQSBw
YWdlIHRva2VuLCByZWNlaXZlZCBmcm9tIGEgcHJldmlvdXMgYExpc3RXb3JrbG9hZHNgIGNh
bGwuCiBQcm92aWRlIHRoaXMgdG8gcmV0cmlldmUgdGhlIHN1YnNlcXVlbnQgcGFnZS4KCgwK
BQQBAgIFEgNzAggKDAoFBAECAgESA3MJEwoMCgUEAQICAxIDcxYXCisKBAQBAgMSA3YCPRoe
IE9wdGlvbmFsLiBGaWx0ZXJpbmcgcmVzdWx0cy4KCgwKBQQBAgMFEgN2AggKDAoFBAECAwES
A3YJDwoMCgUEAQIDAxIDdhITCgwKBQQBAgMIEgN2FDwKDwoIBAECAwicCAASA3YVOwo7CgQE
AQIEEgN5Aj8aLiBPcHRpb25hbC4gSGludCBmb3IgaG93IHRvIG9yZGVyIHRoZSByZXN1bHRz
LgoKDAoFBAECBAUSA3kCCAoMCgUEAQIEARIDeQkRCgwKBQQBAgQDEgN5FBUKDAoFBAECBAgS
A3kWPgoPCggEAQIECJwIABIDeRc9CkUKAgQCEgV9AIcBARo4IFJlc3BvbnNlIG1lc3NhZ2Ug
Zm9yIGxpc3QgY3VzdG9tZXIgd29ya2xvYWRzIHJlcXVlc3RzLgoKCgoDBAIBEgN9CB0KKQoE
BAICABIDfwIiGhwgTGlzdCBvZiBjdXN0b21lciB3b3JrbG9hZHMKCgwKBQQCAgAEEgN/AgoK
DAoFBAICAAYSA38LEwoMCgUEAgIAARIDfxQdCgwKBQQCAgADEgN/ICEKjQEKBAQCAgESBIMB
Ah0afyBBIHRva2VuIHRoYXQgY2FuIGJlIHNlbnQgYXMgYHBhZ2VfdG9rZW5gIHRvIHJldHJp
ZXZlIHRoZSBuZXh0IHBhZ2UuCiBJZiB0aGlzIGZpZWxkIGlzIG9taXR0ZWQsIHRoZXJlIGFy
ZSBubyBzdWJzZXF1ZW50IHBhZ2VzLgoKDQoFBAICAQUSBIMBAggKDQoFBAICAQESBIMBCRgK
DQoFBAICAQMSBIMBGxwKNAoEBAICAhIEhgECIhomIExvY2F0aW9ucyB0aGF0IGNvdWxkIG5v
dCBiZSByZWFjaGVkLgoKDQoFBAICAgQSBIYBAgoKDQoFBAICAgUSBIYBCxEKDQoFBAICAgES
BIYBEh0KDQoFBAICAgMSBIYBICEKOAoCBAMSBooBAJMBARoqIE1lc3NhZ2UgZm9yIGdldHRp
bmcgYSBjdXN0b21lciB3b3JrbG9hZC4KCgsKAwQDARIEigEIGgqCAQoEBAMCABIGjQECkgEE
GnIgUmVxdWlyZWQuIEZvcm1hdDoKIGBvcmdhbml6YXRpb25zL3tvcmdhbml6YXRpb259L2xv
Y2F0aW9ucy97bG9jYXRpb259L2N1c3RvbWVycy97Y3VzdG9tZXJ9L3dvcmtsb2Fkcy97d29y
a2xvYWR9YAoKDQoFBAMCAAUSBI0BAggKDQoFBAMCAAESBI0BCQ0KDQoFBAMCAAMSBI0BEBEK
DwoFBAMCAAgSBo0BEpIBAwoQCggEAwIACJwIABIEjgEEKgoRCgcEAwIACJ8IEgaPAQSRAQUK
OAoCBAQSBpYBAJkBARoqIENvbnRhaW5lciBmb3Igd29ya2xvYWQgb25ib2FyZGluZyBzdGVw
cy4KCgsKAwQEARIElgEIHwoyCgQEBAIAEgSYAQI3GiQgTGlzdCBvZiB3b3JrbG9hZCBvbmJv
YXJkaW5nIHN0ZXBzLgoKDQoFBAQCAAQSBJgBAgoKDQoFBAQCAAYSBJgBCyEKDQoFBAQCAAES
BJgBIjIKDQoFBAQCAAMSBJgBNTYKPgoCBAUSBpwBALUBARowIENvbnRhaW5lciBmb3Igd29y
a2xvYWQgb25ib2FyZGluZyBpbmZvcm1hdGlvbi4KCgsKAwQFARIEnAEIHgo1CgQEBQQAEgae
AQKnAQMaJSBFbnVtIGZvciBwb3NzaWJsZSBvbmJvYXJkaW5nIHN0ZXBzLgoKDQoFBAUEAAES
BJ4BBwsKIwoGBAUEAAIAEgSgAQQZGhMgVW5zcGVjaWZpZWQgc3RlcC4KCg8KBwQFBAACAAES
BKABBBQKDwoHBAUEAAIAAhIEoAEXGAonCgYEBQQAAgESBKMBBBgaFyBFS00gUHJvdmlzaW9u
ZWQgc3RlcC4KCg8KBwQFBAACAQESBKMBBBMKDwoHBAUEAAIBAhIEowEWFwouCgYEBQQAAgIS
BKYBBCoaHiBTaWduZWQgQWNjZXNzIEFwcHJvdmFsIHN0ZXAuCgoPCgcEBQQAAgIBEgSmAQQl
Cg8KBwQFBAACAgISBKYBKCkKJAoEBAUCABIEqgECEBoWIFRoZSBvbmJvYXJkaW5nIHN0ZXAu
CgoNCgUEBQIABhIEqgECBgoNCgUEBQIAARIEqgEHCwoNCgUEBQIAAxIEqgEODwo5CgQEBQIB
EgStAQIrGisgVGhlIHN0YXJ0aW5nIHRpbWUgb2YgdGhlIG9uYm9hcmRpbmcgc3RlcC4KCg0K
BQQFAgEGEgStAQIbCg0KBQQFAgEBEgStARwmCg0KBQQFAgEDEgStASkqCjsKBAQFAgISBLAB
AjAaLSBUaGUgY29tcGxldGlvbiB0aW1lIG9mIHRoZSBvbmJvYXJkaW5nIHN0ZXAuCgoNCgUE
BQICBhIEsAECGwoNCgUEBQICARIEsAEcKwoNCgUEBQICAxIEsAEuLwpLCgQEBQIDEgazAQK0
ATIaOyBPdXRwdXQgb25seS4gVGhlIGNvbXBsZXRpb24gc3RhdGUgb2YgdGhlIG9uYm9hcmRp
bmcgc3RlcC4KCg0KBQQFAgMGEgSzAQIRCg0KBQQFAgMBEgSzARIiCg0KBQQFAgMDEgSzASUm
Cg0KBQQFAgMIEgS0AQYxChAKCAQFAgMInAgAEgS0AQcwYgZwcm90bzM=
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Cloudcontrolspartner::V1::CustomerWorkloads::Workload ===
    # Fields for Workload
    # Field: name Type: 9 ()
    # Field: folder_id Type: 3 ()
    # Field: create_time Type: 11 (.google.protobuf.Timestamp)
    # Field: folder Type: 9 ()
    # Field: workload_onboarding_state Type: 11 (.google.cloud.cloudcontrolspartner.v1.WorkloadOnboardingState)
    # Field: is_onboarded Type: 8 ()
    # Field: key_management_project_id Type: 9 ()
    # Field: location Type: 9 ()
    # Field: partner Type: 14 (.google.cloud.cloudcontrolspartner.v1.Workload.Partner)

# Enum: Workload::Partner
our $Workload_PARTNER_UNSPECIFIED = 0;
our $Workload_PARTNER_LOCAL_CONTROLS_BY_S3NS = 1;
our $Workload_PARTNER_SOVEREIGN_CONTROLS_BY_T_SYSTEMS = 2;
our $Workload_PARTNER_SOVEREIGN_CONTROLS_BY_SIA_MINSAIT = 3;
our $Workload_PARTNER_SOVEREIGN_CONTROLS_BY_PSN = 4;
our $Workload_PARTNER_SOVEREIGN_CONTROLS_BY_CNTXT = 6;
our $Workload_PARTNER_SOVEREIGN_CONTROLS_BY_CNTXT_NO_EKM = 7;

# === Message: Google::Cloud::Cloudcontrolspartner::V1::CustomerWorkloads::ListWorkloadsRequest ===
    # Fields for ListWorkloadsRequest
    # Field: parent Type: 9 ()
    # Field: page_size Type: 5 ()
    # Field: page_token Type: 9 ()
    # Field: filter Type: 9 ()
    # Field: order_by Type: 9 ()

# === Message: Google::Cloud::Cloudcontrolspartner::V1::CustomerWorkloads::ListWorkloadsResponse ===
    # Fields for ListWorkloadsResponse
    # Field: workloads Type: 11 (.google.cloud.cloudcontrolspartner.v1.Workload)
    # Field: next_page_token Type: 9 ()
    # Field: unreachable Type: 9 ()

# === Message: Google::Cloud::Cloudcontrolspartner::V1::CustomerWorkloads::GetWorkloadRequest ===
    # Fields for GetWorkloadRequest
    # Field: name Type: 9 ()

# === Message: Google::Cloud::Cloudcontrolspartner::V1::CustomerWorkloads::WorkloadOnboardingState ===
    # Fields for WorkloadOnboardingState
    # Field: onboarding_steps Type: 11 (.google.cloud.cloudcontrolspartner.v1.WorkloadOnboardingStep)

# === Message: Google::Cloud::Cloudcontrolspartner::V1::CustomerWorkloads::WorkloadOnboardingStep ===
    # Fields for WorkloadOnboardingStep
    # Field: step Type: 14 (.google.cloud.cloudcontrolspartner.v1.WorkloadOnboardingStep.Step)
    # Field: start_time Type: 11 (.google.protobuf.Timestamp)
    # Field: completion_time Type: 11 (.google.protobuf.Timestamp)
    # Field: completion_state Type: 14 (.google.cloud.cloudcontrolspartner.v1.CompletionState)

# Enum: WorkloadOnboardingStep::Step
our $WorkloadOnboardingStep_STEP_UNSPECIFIED = 0;
our $WorkloadOnboardingStep_EKM_PROVISIONED = 1;
our $WorkloadOnboardingStep_SIGNED_ACCESS_APPROVAL_CONFIGURED = 2;

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Cloudcontrolspartner::V1::CustomerWorkloads - Compiled Protocol Buffers messages for google/cloud/cloudcontrolspartner/v1/customer_workloads.proto

=head1 SYNOPSIS

    use Google::Cloud::Cloudcontrolspartner::V1::CustomerWorkloads;

    my $msg = Google::Cloud::Cloudcontrolspartner::V1::CustomerWorkloads::Workload->new({
        name => $name,
        folder_id => $folder_id,
        create_time => $create_time,
        folder => $folder,
    });

    # Read or update a field
    my $val = $msg->name();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Cloudcontrolspartner::V1::CustomerWorkloads::Workload->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/cloudcontrolspartner/v1/customer_workloads.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Cloudcontrolspartner::V1::CustomerWorkloads::Workload

Contains metadata around the [Workload
resource](https://cloud.google.com/assured-workloads/docs/reference/rest/Shared.Types/Workload)
in the Assured Workloads API.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Identifier. Format:
`organizations/{organization}/locations/{location}/customers/{customer}/workloads/{workload}`

=item * C<< $msg->folder_id() >> / C<< $msg->folder_id($value) >>

Type: C<Int64>

Output only. Folder id this workload is associated with

=item * C<< $msg->create_time() >> / C<< $msg->create_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Output only. Time the resource was created.

=item * C<< $msg->folder() >> / C<< $msg->folder($value) >>

Type: C<String>

Output only. The name of container folder of the assured workload

=item * C<< $msg->workload_onboarding_state() >> / C<< $msg->workload_onboarding_state($value) >>

Type: C<Message> (L<Google::Cloud::Cloudcontrolspartner::V1::CustomerWorkloads::WorkloadOnboardingState>)

Container for workload onboarding steps.

=item * C<< $msg->is_onboarded() >> / C<< $msg->is_onboarded($value) >>

Type: C<Bool>

Indicates whether a workload is fully onboarded.

=item * C<< $msg->key_management_project_id() >> / C<< $msg->key_management_project_id($value) >>

Type: C<String>

The project id of the key management project for the workload

=item * C<< $msg->location() >> / C<< $msg->location($value) >>

Type: C<String>

The Google Cloud location of the workload

=item * C<< $msg->partner() >> / C<< $msg->partner($value) >>

Type: C<Enum> (L<Google::Cloud::Cloudcontrolspartner::V1::Workload::Partner>)

Partner associated with this workload.

=back

=head3 Enum: Workload::Partner

=over 4

=item * C<PARTNER_UNSPECIFIED> => C<0>

=item * C<PARTNER_LOCAL_CONTROLS_BY_S3NS> => C<1>

=item * C<PARTNER_SOVEREIGN_CONTROLS_BY_T_SYSTEMS> => C<2>

=item * C<PARTNER_SOVEREIGN_CONTROLS_BY_SIA_MINSAIT> => C<3>

=item * C<PARTNER_SOVEREIGN_CONTROLS_BY_PSN> => C<4>

=item * C<PARTNER_SOVEREIGN_CONTROLS_BY_CNTXT> => C<6>

=item * C<PARTNER_SOVEREIGN_CONTROLS_BY_CNTXT_NO_EKM> => C<7>

=back

=head2 Google::Cloud::Cloudcontrolspartner::V1::CustomerWorkloads::ListWorkloadsRequest

Request to list customer workloads.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->parent() >> / C<< $msg->parent($value) >>

Type: C<String>

Required. Parent resource
Format:
`organizations/{organization}/locations/{location}/customers/{customer}`

=item * C<< $msg->page_size() >> / C<< $msg->page_size($value) >>

Type: C<Int32>

The maximum number of workloads to return. The service may return fewer
than this value. If unspecified, at most 500 workloads will be returned.

=item * C<< $msg->page_token() >> / C<< $msg->page_token($value) >>

Type: C<String>

A page token, received from a previous `ListWorkloads` call.
Provide this to retrieve the subsequent page.

=item * C<< $msg->filter() >> / C<< $msg->filter($value) >>

Type: C<String>

Optional. Filtering results.

=item * C<< $msg->order_by() >> / C<< $msg->order_by($value) >>

Type: C<String>

Optional. Hint for how to order the results.

=back

=head2 Google::Cloud::Cloudcontrolspartner::V1::CustomerWorkloads::ListWorkloadsResponse

Response message for list customer workloads requests.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->workloads() >> / C<< $msg->workloads($value) >>

Type: C<Message> (L<Google::Cloud::Cloudcontrolspartner::V1::CustomerWorkloads::Workload>)

List of customer workloads

=item * C<< $msg->next_page_token() >> / C<< $msg->next_page_token($value) >>

Type: C<String>

A token that can be sent as `page_token` to retrieve the next page.
If this field is omitted, there are no subsequent pages.

=item * C<< $msg->unreachable() >> / C<< $msg->unreachable($value) >>

Type: C<String>

Locations that could not be reached.

=back

=head2 Google::Cloud::Cloudcontrolspartner::V1::CustomerWorkloads::GetWorkloadRequest

Message for getting a customer workload.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. Format:
`organizations/{organization}/locations/{location}/customers/{customer}/workloads/{workload}`

=back

=head2 Google::Cloud::Cloudcontrolspartner::V1::CustomerWorkloads::WorkloadOnboardingState

Container for workload onboarding steps.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->onboarding_steps() >> / C<< $msg->onboarding_steps($value) >>

Type: C<Message> (L<Google::Cloud::Cloudcontrolspartner::V1::CustomerWorkloads::WorkloadOnboardingStep>)

List of workload onboarding steps.

=back

=head2 Google::Cloud::Cloudcontrolspartner::V1::CustomerWorkloads::WorkloadOnboardingStep

Container for workload onboarding information.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->step() >> / C<< $msg->step($value) >>

Type: C<Enum> (L<Google::Cloud::Cloudcontrolspartner::V1::WorkloadOnboardingStep::Step>)

The onboarding step.

=item * C<< $msg->start_time() >> / C<< $msg->start_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

The starting time of the onboarding step.

=item * C<< $msg->completion_time() >> / C<< $msg->completion_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

The completion time of the onboarding step.

=item * C<< $msg->completion_state() >> / C<< $msg->completion_state($value) >>

Type: C<Enum> (L<Google::Cloud::Cloudcontrolspartner::V1::CompletionState>)

Output only. The completion state of the onboarding step.

=back

=head3 Enum: WorkloadOnboardingStep::Step

=over 4

=item * C<STEP_UNSPECIFIED> => C<0>

=item * C<EKM_PROVISIONED> => C<1>

=item * C<SIGNED_ACCESS_APPROVAL_CONFIGURED> => C<2>

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Cloudcontrolspartner::V1::CustomerWorkloads::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
