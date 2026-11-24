package Google::Cloud::Sql::V1::CloudSqlWorkloadCaptures;

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
    eval { require Google::Cloud::Sql::V1::CloudSqlResources };
    eval { require Google::Protobuf::Timestamp };
    my $descriptor_b64 = <<'EOF';
CjVnb29nbGUvY2xvdWQvc3FsL3YxL2Nsb3VkX3NxbF93b3JrbG9hZF9jYXB0dXJlcy5wcm90
bxITZ29vZ2xlLmNsb3VkLnNxbC52MRocZ29vZ2xlL2FwaS9hbm5vdGF0aW9ucy5wcm90bxoX
Z29vZ2xlL2FwaS9jbGllbnQucHJvdG8aH2dvb2dsZS9hcGkvZmllbGRfYmVoYXZpb3IucHJv
dG8aGWdvb2dsZS9hcGkvcmVzb3VyY2UucHJvdG8aLWdvb2dsZS9jbG91ZC9zcWwvdjEvY2xv
dWRfc3FsX3Jlc291cmNlcy5wcm90bxofZ29vZ2xlL3Byb3RvYnVmL3RpbWVzdGFtcC5wcm90
byLaAQocV29ya2xvYWRDYXB0dXJlc1N0YXJ0UmVxdWVzdBIdCgdwcm9qZWN0GAEgASgJQgPg
QQJSB3Byb2plY3QSHwoIaW5zdGFuY2UYAiABKAlCA+BBAlIIaW5zdGFuY2USegoec3RhcnRf
d29ya2xvYWRfY2FwdHVyZV9jb250ZXh0GGQgASgLMjAuZ29vZ2xlLmNsb3VkLnNxbC52MS5T
dGFydFdvcmtsb2FkQ2FwdHVyZUNvbnRleHRCA+BBAVIbc3RhcnRXb3JrbG9hZENhcHR1cmVD
b250ZXh0ItYBChtXb3JrbG9hZENhcHR1cmVzU3RvcFJlcXVlc3QSHQoHcHJvamVjdBgBIAEo
CUID4EECUgdwcm9qZWN0Eh8KCGluc3RhbmNlGAIgASgJQgPgQQJSCGluc3RhbmNlEncKHXN0
b3Bfd29ya2xvYWRfY2FwdHVyZV9jb250ZXh0GGQgASgLMi8uZ29vZ2xlLmNsb3VkLnNxbC52
MS5TdG9wV29ya2xvYWRDYXB0dXJlQ29udGV4dEID4EEBUhpzdG9wV29ya2xvYWRDYXB0dXJl
Q29udGV4dCKDAgoiV29ya2xvYWRDYXB0dXJlc1N0YXJ0UmVwbGF5UmVxdWVzdBIdCgdwcm9q
ZWN0GAEgASgJQgPgQQJSB3Byb2plY3QSHwoIaW5zdGFuY2UYAiABKAlCA+BBAlIIaW5zdGFu
Y2USdwodc3RhcnRfd29ya2xvYWRfcmVwbGF5X2NvbnRleHQYZCABKAsyLy5nb29nbGUuY2xv
dWQuc3FsLnYxLlN0YXJ0V29ya2xvYWRSZXBsYXlDb250ZXh0QgPgQQJSGnN0YXJ0V29ya2xv
YWRSZXBsYXlDb250ZXh0EiQKC3dvcmtsb2FkX2lkGAQgASgJQgPgQQJSCndvcmtsb2FkSWQi
2QEKIVdvcmtsb2FkQ2FwdHVyZXNTdG9wUmVwbGF5UmVxdWVzdBIdCgdwcm9qZWN0GAEgASgJ
QgPgQQJSB3Byb2plY3QSHwoIaW5zdGFuY2UYAiABKAlCA+BBAlIIaW5zdGFuY2USdAocc3Rv
cF93b3JrbG9hZF9yZXBsYXlfY29udGV4dBhkIAEoCzIuLmdvb2dsZS5jbG91ZC5zcWwudjEu
U3RvcFdvcmtsb2FkUmVwbGF5Q29udGV4dEID4EEBUhlzdG9wV29ya2xvYWRSZXBsYXlDb250
ZXh0ImAKHlNxbFdvcmtsb2FkQ2FwdHVyZXNMaXN0UmVxdWVzdBIdCgdwcm9qZWN0GAEgASgJ
QgPgQQJSB3Byb2plY3QSHwoIaW5zdGFuY2UYAiABKAlCA+BBAlIIaW5zdGFuY2UihQEKHFdv
cmtsb2FkQ2FwdHVyZXNMaXN0UmVzcG9uc2USUQoRd29ya2xvYWRfY2FwdHVyZXMYASADKAsy
JC5nb29nbGUuY2xvdWQuc3FsLnYxLldvcmtsb2FkQ2FwdHVyZVIQd29ya2xvYWRDYXB0dXJl
cxISCgRraW5kGAIgASgJUgRraW5kIvkGCg9Xb3JrbG9hZENhcHR1cmUSJAoLd29ya2xvYWRf
aWQYASABKAlCA+BBA1IKd29ya2xvYWRJZBJRCg9zb3VyY2VfaW5zdGFuY2UYAiABKAlCKOBB
A/pBIgogY2xvdWRzcWwuZ29vZ2xlYXBpcy5jb20vSW5zdGFuY2VSDnNvdXJjZUluc3RhbmNl
EmUKFndvcmtsb2FkX2NhcHR1cmVfc3RhdGUYAyABKA4yKi5nb29nbGUuY2xvdWQuc3FsLnYx
Lldvcmtsb2FkQ2FwdHVyZS5TdGF0ZUID4EEDUhR3b3JrbG9hZENhcHR1cmVTdGF0ZRI+Cgpz
dGFydF90aW1lGAQgASgLMhouZ29vZ2xlLnByb3RvYnVmLlRpbWVzdGFtcEID4EEDUglzdGFy
dFRpbWUSOgoIZW5kX3RpbWUYBSABKAsyGi5nb29nbGUucHJvdG9idWYuVGltZXN0YW1wQgPg
QQNSB2VuZFRpbWUSVgoPcmVwbGF5X2luc3RhbmNlGAYgASgJQijgQQP6QSIKIGNsb3Vkc3Fs
Lmdvb2dsZWFwaXMuY29tL0luc3RhbmNlSABSDnJlcGxheUluc3RhbmNliAEBEi8KDnJldGVu
dGlvbl9kYXlzGAcgASgFQgPgQQNIAVINcmV0ZW50aW9uRGF5c4gBARIlCgliYWNrdXBfaWQY
CCABKAlCA+BBA0gCUghiYWNrdXBJZIgBARJgCgxjYXB0dXJlX21vZGUYDSABKA4yOC5nb29n
bGUuY2xvdWQuc3FsLnYxLldvcmtsb2FkQ2FwdHVyZS5Xb3JrbG9hZENhcHR1cmVNb2RlQgPg
QQNSC2NhcHR1cmVNb2RlIlYKBVN0YXRlEhUKEVNUQVRFX1VOU1BFQ0lGSUVEEAASCwoHUlVO
TklORxABEg0KCUNPTVBMRVRFRBACEgoKBkZBSUxFRBADEg4KClRFUk1JTkFURUQQBCJrChNX
b3JrbG9hZENhcHR1cmVNb2RlEiUKIVdPUktMT0FEX0NBUFRVUkVfTU9ERV9VTlNQRUNJRklF
RBAAEhAKDENBUFRVUkVfT05MWRABEhsKF0NBUFRVUkVfQU5EX0xJVkVfUkVQTEFZEAJCEgoQ
X3JlcGxheV9pbnN0YW5jZUIRCg9fcmV0ZW50aW9uX2RheXNCDAoKX2JhY2t1cF9pZDKtCAoa
U3FsV29ya2xvYWRDYXB0dXJlc1NlcnZpY2USqQEKBVN0YXJ0EjEuZ29vZ2xlLmNsb3VkLnNx
bC52MS5Xb3JrbG9hZENhcHR1cmVzU3RhcnRSZXF1ZXN0Gh4uZ29vZ2xlLmNsb3VkLnNxbC52
MS5PcGVyYXRpb24iTYLT5JMCRyJCL3YxL3Byb2plY3RzL3twcm9qZWN0fS9pbnN0YW5jZXMv
e2luc3RhbmNlfS93b3JrbG9hZENhcHR1cmVzOnN0YXJ0OgEqEqYBCgRTdG9wEjAuZ29vZ2xl
LmNsb3VkLnNxbC52MS5Xb3JrbG9hZENhcHR1cmVzU3RvcFJlcXVlc3QaHi5nb29nbGUuY2xv
dWQuc3FsLnYxLk9wZXJhdGlvbiJMgtPkkwJGIkEvdjEvcHJvamVjdHMve3Byb2plY3R9L2lu
c3RhbmNlcy97aW5zdGFuY2V9L3dvcmtsb2FkQ2FwdHVyZXM6c3RvcDoBKhLJAQoLU3RhcnRS
ZXBsYXkSNy5nb29nbGUuY2xvdWQuc3FsLnYxLldvcmtsb2FkQ2FwdHVyZXNTdGFydFJlcGxh
eVJlcXVlc3QaHi5nb29nbGUuY2xvdWQuc3FsLnYxLk9wZXJhdGlvbiJhgtPkkwJbIlYvdjEv
cHJvamVjdHMve3Byb2plY3R9L2luc3RhbmNlcy97aW5zdGFuY2V9L3dvcmtsb2FkQ2FwdHVy
ZXMve3dvcmtsb2FkX2lkfTpzdGFydFJlcGxheToBKhK4AQoKU3RvcFJlcGxheRI2Lmdvb2ds
ZS5jbG91ZC5zcWwudjEuV29ya2xvYWRDYXB0dXJlc1N0b3BSZXBsYXlSZXF1ZXN0Gh4uZ29v
Z2xlLmNsb3VkLnNxbC52MS5PcGVyYXRpb24iUoLT5JMCTCJHL3YxL3Byb2plY3RzL3twcm9q
ZWN0fS9pbnN0YW5jZXMve2luc3RhbmNlfS93b3JrbG9hZENhcHR1cmVzOnN0b3BSZXBsYXk6
ASoStAEKBExpc3QSMy5nb29nbGUuY2xvdWQuc3FsLnYxLlNxbFdvcmtsb2FkQ2FwdHVyZXNM
aXN0UmVxdWVzdBoxLmdvb2dsZS5jbG91ZC5zcWwudjEuV29ya2xvYWRDYXB0dXJlc0xpc3RS
ZXNwb25zZSJEgtPkkwI+EjwvdjEvcHJvamVjdHMve3Byb2plY3R9L2luc3RhbmNlcy97aW5z
dGFuY2V9L3dvcmtsb2FkQ2FwdHVyZXMafMpBF3NxbGFkbWluLmdvb2dsZWFwaXMuY29t0kFf
aHR0cHM6Ly93d3cuZ29vZ2xlYXBpcy5jb20vYXV0aC9jbG91ZC1wbGF0Zm9ybSxodHRwczov
L3d3dy5nb29nbGVhcGlzLmNvbS9hdXRoL3NxbHNlcnZpY2UuYWRtaW5CZQoXY29tLmdvb2ds
ZS5jbG91ZC5zcWwudjFCHUNsb3VkU3FsV29ya2xvYWRDYXB0dXJlc1Byb3RvUAFaKWNsb3Vk
Lmdvb2dsZS5jb20vZ28vc3FsL2FwaXYxL3NxbHBiO3NxbHBiSoU/CgcSBQ4A7wEBCrwECgEM
EgMOABIysQQgQ29weXJpZ2h0IDIwMjYgR29vZ2xlIExMQwoKIExpY2Vuc2VkIHVuZGVyIHRo
ZSBBcGFjaGUgTGljZW5zZSwgVmVyc2lvbiAyLjAgKHRoZSAiTGljZW5zZSIpOwogeW91IG1h
eSBub3QgdXNlIHRoaXMgZmlsZSBleGNlcHQgaW4gY29tcGxpYW5jZSB3aXRoIHRoZSBMaWNl
bnNlLgogWW91IG1heSBvYnRhaW4gYSBjb3B5IG9mIHRoZSBMaWNlbnNlIGF0CgogICAgIGh0
dHA6Ly93d3cuYXBhY2hlLm9yZy9saWNlbnNlcy9MSUNFTlNFLTIuMAoKIFVubGVzcyByZXF1
aXJlZCBieSBhcHBsaWNhYmxlIGxhdyBvciBhZ3JlZWQgdG8gaW4gd3JpdGluZywgc29mdHdh
cmUKIGRpc3RyaWJ1dGVkIHVuZGVyIHRoZSBMaWNlbnNlIGlzIGRpc3RyaWJ1dGVkIG9uIGFu
ICJBUyBJUyIgQkFTSVMsCiBXSVRIT1VUIFdBUlJBTlRJRVMgT1IgQ09ORElUSU9OUyBPRiBB
TlkgS0lORCwgZWl0aGVyIGV4cHJlc3Mgb3IgaW1wbGllZC4KIFNlZSB0aGUgTGljZW5zZSBm
b3IgdGhlIHNwZWNpZmljIGxhbmd1YWdlIGdvdmVybmluZyBwZXJtaXNzaW9ucyBhbmQKIGxp
bWl0YXRpb25zIHVuZGVyIHRoZSBMaWNlbnNlLgoKCAoBAhIDEAAcCgkKAgMAEgMSACYKCQoC
AwESAxMAIQoJCgIDAhIDFAApCgkKAgMDEgMVACMKCQoCAwQSAxYANwoJCgIDBRIDFwApCggK
AQgSAxkAQAoJCgIICxIDGQBACggKAQgSAxoAIgoJCgIIChIDGgAiCggKAQgSAxsAPgoJCgII
CBIDGwA+CggKAQgSAxwAMAoJCgIIARIDHAAwCjIKAgYAEgQfAFMBGiYgQ2xvdWQgU1FMIFdv
cmtsb2FkIENhcHR1cmVzIHNlcnZpY2UuCgoKCgMGAAESAx8IIgoKCgMGAAMSAyACPwoMCgUG
AAOZCBIDIAI/CgsKAwYAAxIEIQIjOQoNCgUGAAOaCBIEIQIjOQruAgoEBgACABIEKgIvAxrf
AiBTdGFydHMgY2FwdHVyaW5nIHRoZSBTUUwgcXVlcmllcywgdHJhbnNhY3Rpb25zLCBhbmQg
b3RoZXIgb3BlcmF0aW9ucwogZXhlY3V0ZWQgb24gdGhlIHByaW1hcnkgaW5zdGFuY2UuIFRo
aXMgdHJhZmZpYyBpcyBzZWN1cmVseSBzdG9yZWQgYW5kIGZvcm1zCiBhICJjYXB0dXJlZCB3
b3JrbG9hZCIuIFRoaXMgd29ya2xvYWQgY2FuIGJlIHJlcGxheWVkIGxhdGVyIG9uIGEgZGlm
ZmVyZW50CiBpbnN0YW5jZSB0byBzYWZlbHkgdGVzdCBwZXJmb3JtYW5jZSBpbXBhY3RzLCBk
YXRhYmFzZSB1cGdyYWRlcywKIGNvbmZpZ3VyYXRpb24gY2hhbmdlcyBldGMuIGJlZm9yZSBh
cHBseWluZyB0aGVtIHRvIHByb2R1Y3Rpb24uCgoMCgUGAAIAARIDKgYLCgwKBQYAAgACEgMq
DCgKDAoFBgACAAMSAyozPAoNCgUGAAIABBIEKwQuBgoRCgkGAAIABLDKvCISBCsELgYKawoE
BgACARIEMwI4AxpdIFN0b3BzIGNhcHR1cmluZyB0aGUgcXVlcnkgdHJhZmZpYyBhbmQgcmVs
YXRlZCBvcGVyYXRpb25zIGV4ZWN1dGVkIG9uIHRoZQogcHJpbWFyeSBpbnN0YW5jZS4KCgwK
BQYAAgEBEgMzBgoKDAoFBgACAQISAzMLJgoMCgUGAAIBAxIDMzE6Cg0KBQYAAgEEEgQ0BDcG
ChEKCQYAAgEEsMq8IhIENAQ3BgrbAQoEBgACAhIEPQJCAxrMASBTdGFydHMgZXhlY3V0aW5n
IGEgY2FwdHVyZWQgd29ya2xvYWQgb24gYSBzZXBhcmF0ZSBDbG91ZCBTUUwgaW5zdGFuY2UK
IHByb3Zpc2lvbmVkIGZvciB3b3JrbG9hZCByZXBsYXkuIFRoaXMgdGFyZ2V0IGluc3RhbmNl
IHNpbXVsYXRlcyB0aGUKIHByb2R1Y3Rpb24gZW52aXJvbm1lbnQgd2l0aG91dCBhZmZlY3Rp
bmcgdGhlIHByaW1hcnkgaW5zdGFuY2UuCgoMCgUGAAICARIDPQYRCgwKBQYAAgICEgM9EjQK
DAoFBgACAgMSAz0/SAoNCgUGAAICBBIEPgRBBgoRCgkGAAICBLDKvCISBD4EQQYKWAoEBgAC
AxIERQJKAxpKIFN0b3BzIGFuIGFjdGl2ZSB3b3JrbG9hZCByZXBsYXkgb24gdGhlIHRhcmdl
dCBDbG91ZCBTUUwgcmVwbGF5IGluc3RhbmNlLgoKDAoFBgACAwESA0UGEAoMCgUGAAIDAhID
RREyCgwKBQYAAgMDEgNFPUYKDQoFBgACAwQSBEYESQYKEQoJBgACAwSwyrwiEgRGBEkGCkoK
BAYAAgQSBE0CUgMaPCBMaXN0cyBhbGwgY2FwdHVyZWQgd29ya2xvYWRzIGFzc29jaWF0ZWQg
d2l0aCB0aGUgaW5zdGFuY2UuCgoMCgUGAAIEARIDTQYKCgwKBQYAAgQCEgNNCykKDAoFBgAC
BAMSA04PKwoNCgUGAAIEBBIETwRRBgoRCgkGAAIEBLDKvCISBE8EUQYKYAoCBAASBFcAYQEa
VCBSZXF1ZXN0IHRvIHN0YXJ0IHJlY29yZGluZyB0cmFmZmljIGZyb20gdGhlIHByaW1hcnkg
aW5zdGFuY2UgKGNhcHR1cmVkCiB3b3JrbG9hZCkuCgoKCgMEAAESA1cIJApOCgQEAAIAEgNZ
Aj4aQSBSZXF1aXJlZC4gUHJvamVjdCBJRCBvZiB0aGUgcHJvamVjdCB0aGF0IGNvbnRhaW5z
IHRoZSBpbnN0YW5jZS4KCgwKBQQAAgAFEgNZAggKDAoFBAACAAESA1kJEAoMCgUEAAIAAxID
WRMUCgwKBQQAAgAIEgNZFT0KDwoIBAACAAicCAASA1kWPApVCgQEAAIBEgNcAj8aSCBSZXF1
aXJlZC4gQ2xvdWQgU1FMIGluc3RhbmNlIElELiBUaGlzIGRvZXMgbm90IGluY2x1ZGUgdGhl
IHByb2plY3QgSUQuCgoMCgUEAAIBBRIDXAIICgwKBQQAAgEBEgNcCREKDAoFBAACAQMSA1wU
FQoMCgUEAAIBCBIDXBY+Cg8KCAQAAgEInAgAEgNcFz0KVgoEBAACAhIEXwJgLxpIIE9wdGlv
bmFsLiBDb250YWlucyBkZXRhaWxzIGFib3V0IHRoZSBzdGFydCB3b3JrbG9hZCBjYXB0dXJl
IG9wZXJhdGlvbi4KCgwKBQQAAgIGEgNfAh0KDAoFBAACAgESA18ePAoMCgUEAAICAxIDXz9C
CgwKBQQAAgIIEgNgBi4KDwoIBAACAgicCAASA2AHLQpKCgIEARIEZABuARo+IFJlcXVlc3Qg
dG8gc3RvcCByZWNvcmRpbmcgdHJhZmZpYyBmcm9tIHRoZSBwcmltYXJ5IGluc3RhbmNlLgoK
CgoDBAEBEgNkCCMKTgoEBAECABIDZgI+GkEgUmVxdWlyZWQuIFByb2plY3QgSUQgb2YgdGhl
IHByb2plY3QgdGhhdCBjb250YWlucyB0aGUgaW5zdGFuY2UuCgoMCgUEAQIABRIDZgIICgwK
BQQBAgABEgNmCRAKDAoFBAECAAMSA2YTFAoMCgUEAQIACBIDZhU9Cg8KCAQBAgAInAgAEgNm
FjwKVQoEBAECARIDaQI/GkggUmVxdWlyZWQuIENsb3VkIFNRTCBpbnN0YW5jZSBJRC4gVGhp
cyBkb2VzIG5vdCBpbmNsdWRlIHRoZSBwcm9qZWN0IElELgoKDAoFBAECAQUSA2kCCAoMCgUE
AQIBARIDaQkRCgwKBQQBAgEDEgNpFBUKDAoFBAECAQgSA2kWPgoPCggEAQIBCJwIABIDaRc9
ClUKBAQBAgISBGwCbS8aRyBPcHRpb25hbC4gQ29udGFpbnMgZGV0YWlscyBhYm91dCB0aGUg
c3RvcCB3b3JrbG9hZCBjYXB0dXJlIG9wZXJhdGlvbi4KCgwKBQQBAgIGEgNsAhwKDAoFBAEC
AgESA2wdOgoMCgUEAQICAxIDbD1ACgwKBQQBAgIIEgNtBi4KDwoIBAECAgicCAASA20HLQqZ
AQoCBAISBHIAfwEajAEgUmVxdWVzdCB0byBzdGFydCBleGVjdXRpbmcgYSBjYXB0dXJlZCB3
b3JrbG9hZCBvbiBhIHJlcGxheSBpbnN0YW5jZSAodGhlCiBDbG91ZCBTUUwgaW5zdGFuY2Ug
d2hlcmUgdGhlIHJlY29yZGVkIFNRTCBxdWVyaWVzIGFyZSBleGVjdXRlZCkuCgoKCgMEAgES
A3IIKgpOCgQEAgIAEgN0Aj4aQSBSZXF1aXJlZC4gUHJvamVjdCBJRCBvZiB0aGUgcHJvamVj
dCB0aGF0IGNvbnRhaW5zIHRoZSBpbnN0YW5jZS4KCgwKBQQCAgAFEgN0AggKDAoFBAICAAES
A3QJEAoMCgUEAgIAAxIDdBMUCgwKBQQCAgAIEgN0FT0KDwoIBAICAAicCAASA3QWPApVCgQE
AgIBEgN3Aj8aSCBSZXF1aXJlZC4gQ2xvdWQgU1FMIGluc3RhbmNlIElELiBUaGlzIGRvZXMg
bm90IGluY2x1ZGUgdGhlIHByb2plY3QgSUQuCgoMCgUEAgIBBRIDdwIICgwKBQQCAgEBEgN3
CREKDAoFBAICAQMSA3cUFQoMCgUEAgIBCBIDdxY+Cg8KCAQCAgEInAgAEgN3Fz0KVQoEBAIC
AhIEegJ7LxpHIFJlcXVpcmVkLiBDb250YWlucyBkZXRhaWxzIGFib3V0IHRoZSBzdGFydCB3
b3JrbG9hZCByZXBsYXkgb3BlcmF0aW9uLgoKDAoFBAICAgYSA3oCHAoMCgUEAgICARIDeh06
CgwKBQQCAgIDEgN6PUAKDAoFBAICAggSA3sGLgoPCggEAgICCJwIABIDewctCjoKBAQCAgMS
A34CQhotIFJlcXVpcmVkLiBUaGUgSUQgb2YgdGhlIHdvcmtsb2FkIHRvIHJlcGxheS4KCgwK
BQQCAgMFEgN+AggKDAoFBAICAwESA34JFAoMCgUEAgIDAxIDfhcYCgwKBQQCAgMIEgN+GUEK
DwoIBAICAwicCAASA34aQAphCgIEAxIGgwEAkAEBGlMgUmVxdWVzdCB0byBzdG9wIGFuIGFj
dGl2ZSB3b3JrbG9hZCByZXBsYXkgb24gYSB0YXJnZXQgQ2xvdWQgU1FMIHJlcGxheQogaW5z
dGFuY2UuCgoLCgMEAwESBIMBCCkKXgoEBAMCABIEhgECPhpQIFJlcXVpcmVkLiBQcm9qZWN0
IElEIG9mIHRoZSBwcm9qZWN0IHRoYXQgY29udGFpbnMgdGhlIHRhcmdldCByZXBsYXkKIGlu
c3RhbmNlLgoKDQoFBAMCAAUSBIYBAggKDQoFBAMCAAESBIYBCRAKDQoFBAMCAAMSBIYBExQK
DQoFBAMCAAgSBIYBFT0KEAoIBAMCAAicCAASBIYBFjwKdQoEBAMCARIEigECPxpnIFJlcXVp
cmVkLiBDbG91ZCBTUUwgaW5zdGFuY2UgSUQgb2YgdGhlIHRhcmdldCByZXBsYXkgaW5zdGFu
Y2UuIFRoaXMgZG9lcwogbm90IGluY2x1ZGUgdGhlIHByb2plY3QgSUQuCgoNCgUEAwIBBRIE
igECCAoNCgUEAwIBARIEigEJEQoNCgUEAwIBAxIEigEUFQoNCgUEAwIBCBIEigEWPgoQCggE
AwIBCJwIABIEigEXPQp8CgQEAwICEgaOAQKPAS8abCBPcHRpb25hbC4gQ29udGFpbnMgZGV0
YWlscyBhYm91dCB0aGUgc3RvcCB3b3JrbG9hZCByZXBsYXkgb3BlcmF0aW9uLiBJZgogb21p
dHRlZCwgZGVmYXVsdCB2YWx1ZXMgYXJlIHVzZWQuCgoNCgUEAwICBhIEjgECGwoNCgUEAwIC
ARIEjgEcOAoNCgUEAwICAxIEjgE7PgoNCgUEAwICCBIEjwEGLgoQCggEAwICCJwIABIEjwEH
LQo5CgIEBBIGkwEAmQEBGisgSW5zdGFuY2UgbGlzdCBjYXB0dXJlZCB3b3JrbG9hZHMgcmVx
dWVzdC4KCgsKAwQEARIEkwEIJgpPCgQEBAIAEgSVAQI+GkEgUmVxdWlyZWQuIFByb2plY3Qg
SUQgb2YgdGhlIHByb2plY3QgdGhhdCBjb250YWlucyB0aGUgaW5zdGFuY2UuCgoNCgUEBAIA
BRIElQECCAoNCgUEBAIAARIElQEJEAoNCgUEBAIAAxIElQETFAoNCgUEBAIACBIElQEVPQoQ
CggEBAIACJwIABIElQEWPApWCgQEBAIBEgSYAQI/GkggUmVxdWlyZWQuIENsb3VkIFNRTCBp
bnN0YW5jZSBJRC4gVGhpcyBkb2VzIG5vdCBpbmNsdWRlIHRoZSBwcm9qZWN0IElELgoKDQoF
BAQCAQUSBJgBAggKDQoFBAQCAQESBJgBCREKDQoFBAQCAQMSBJgBFBUKDQoFBAQCAQgSBJgB
Fj4KEAoIBAQCAQicCAASBJgBFz0KOgoCBAUSBpwBAKIBARosIEluc3RhbmNlIGxpc3QgY2Fw
dHVyZWQgd29ya2xvYWRzIHJlc3BvbnNlLgoKCwoDBAUBEgScAQgkCjwKBAQFAgASBJ4BAjEa
LiBMaXN0IG9mIGNhcHR1cmVkIHdvcmtsb2FkcyBmb3IgdGhlIGluc3RhbmNlLgoKDQoFBAUC
AAQSBJ4BAgoKDQoFBAUCAAYSBJ4BCxoKDQoFBAUCAAESBJ4BGywKDQoFBAUCAAMSBJ4BLzAK
OgoEBAUCARIEoQECEhosIFRoaXMgaXMgYWx3YXlzIGBzcWwjd29ya2xvYWRDYXB0dXJlc0xp
c3RgLgoKDQoFBAUCAQUSBKEBAggKDQoFBAUCAQESBKEBCQ0KDQoFBAUCAQMSBKEBEBEKMgoC
BAYSBqUBAO8BARokIENhcHR1cmVkIHdvcmtsb2FkIGZvciBhbiBpbnN0YW5jZS4KCgsKAwQG
ARIEpQEIFwowCgQEBgQAEganAQK5AQMaICBTdGF0ZSBvZiB0aGUgd29ya2xvYWQgY2FwdHVy
ZS4KCg0KBQQGBAABEgSnAQcMCjYKBgQGBAACABIEqQEEGhomIERlZmF1bHQgdmFsdWUuIFRo
aXMgdmFsdWUgaXMgdW51c2VkLgoKDwoHBAYEAAIAARIEqQEEFQoPCgcEBgQAAgACEgSpARgZ
CjgKBgQGBAACARIErAEEEBooIFdvcmtsb2FkIGNhcHR1cmUgaXMgY3VycmVudGx5IHJ1bm5p
bmcuCgoPCgcEBgQAAgEBEgSsAQQLCg8KBwQGBAACAQISBKwBDg8KeQoGBAYEAAICEgSwAQQS
GmkgV29ya2xvYWQgY2FwdHVyZSBjb21wbGV0ZWQgc3VjY2Vzc2Z1bGx5LiBUaGlzIHN0YXRl
IGlzIHNldCB3aGVuIHRoZSB1c2VyCiBleHBsaWNpdGx5IHN0b3BzIHRoZSBjYXB0dXJlLgoK
DwoHBAYEAAICARIEsAEEDQoPCgcEBgQAAgICEgSwARARCioKBgQGBAACAxIEswEEDxoaIFdv
cmtsb2FkIGNhcHR1cmUgZmFpbGVkLgoKDwoHBAYEAAIDARIEswEECgoPCgcEBgQAAgMCEgSz
AQ0OCswBCgYEBgQAAgQSBLgBBBMauwEgV29ya2xvYWQgY2FwdHVyZSB3YXMgdGVybWluYXRl
ZCBhdXRvbWF0aWNhbGx5LiBUaGlzIHN0YXRlIGlzIHNldCB3aGVuCiBDbG91ZCBTUUwgYXV0
b21hdGljYWxseSBzdG9wcyB0aGUgY2FwdHVyZSBkdWUgdG8gYSBjb25mbGljdGluZyBvcGVy
YXRpb24KIG9yIHdoZW4gdGhlIG1heGltdW0gZHVyYXRpb24gaXMgcmVhY2hlZC4KCg8KBwQG
BAACBAESBLgBBA4KDwoHBAYEAAIEAhIEuAEREgo9CgQEBgQBEga8AQLGAQMaLSBTcGVjaWZp
ZXMgdGhlIG1vZGUgb2YgdGhlIHdvcmtsb2FkIGNhcHR1cmUuCgoNCgUEBgQBARIEvAEHGgo2
CgYEBgQBAgASBL4BBCoaJiBEZWZhdWx0IHZhbHVlLiBUaGlzIHZhbHVlIGlzIHVudXNlZC4K
Cg8KBwQGBAECAAESBL4BBCUKDwoHBAYEAQIAAhIEvgEoKQpGCgYEBgQBAgESBMEBBBUaNiBS
ZWNvcmRzIGFuZCBzdG9yZXMgdGhlIHdvcmtsb2FkIHdpdGhvdXQgbGl2ZSByZXBsYXkuCgoP
CgcEBgQBAgEBEgTBAQQQCg8KBwQGBAECAQISBMEBExQKYAoGBAYEAQICEgTFAQQgGlAgUmVj
b3JkcyB0aGUgd29ya2xvYWQgYW5kIHNpbXVsdGFuZW91c2x5IHJlcGxheXMgaXQgb24gYSBs
aXZlIHJlcGxheQogaW5zdGFuY2UuCgoPCgcEBgQBAgIBEgTFAQQbCg8KBwQGBAECAgISBMUB
Hh8KPQoEBAYCABIEyQECRRovIE91dHB1dCBvbmx5LiBUaGUgSUQgb2YgdGhlIGNhcHR1cmVk
IHdvcmtsb2FkLgoKDQoFBAYCAAUSBMkBAggKDQoFBAYCAAESBMkBCRQKDQoFBAYCAAMSBMkB
FxgKDQoFBAYCAAgSBMkBGUQKEAoIBAYCAAicCAASBMkBGkMKPwoEBAYCARIGzAEC0QEEGi8g
T3V0cHV0IG9ubHkuIFRoZSBuYW1lIG9mIHRoZSBzb3VyY2UgaW5zdGFuY2UuCgoNCgUEBgIB
BRIEzAECCAoNCgUEBgIBARIEzAEJGAoNCgUEBgIBAxIEzAEbHAoPCgUEBgIBCBIGzAEd0QED
ChAKCAQGAgEInAgAEgTNAQQtChEKBwQGAgEInwgSBs4BBNABBQo/CgQEBgICEgTUAQJPGjEg
T3V0cHV0IG9ubHkuIFRoZSBzdGF0ZSBvZiB0aGUgd29ya2xvYWQgY2FwdHVyZS4KCg0KBQQG
AgIGEgTUAQIHCg0KBQQGAgIBEgTUAQgeCg0KBQQGAgIDEgTUASEiCg0KBQQGAgIIEgTUASNO
ChAKCAQGAgIInAgAEgTUASRNCkYKBAQGAgMSBtcBAtgBMho2IE91dHB1dCBvbmx5LiBUaGUg
c3RhcnQgdGltZSBvZiB0aGUgd29ya2xvYWQgY2FwdHVyZS4KCg0KBQQGAgMGEgTXAQIbCg0K
BQQGAgMBEgTXARwmCg0KBQQGAgMDEgTXASkqCg0KBQQGAgMIEgTYAQYxChAKCAQGAgMInAgA
EgTYAQcwCkQKBAQGAgQSBtsBAtwBMho0IE91dHB1dCBvbmx5LiBUaGUgZW5kIHRpbWUgb2Yg
dGhlIHdvcmtsb2FkIGNhcHR1cmUuCgoNCgUEBgIEBhIE2wECGwoNCgUEBgIEARIE2wEcJAoN
CgUEBgIEAxIE2wEnKAoNCgUEBgIECBIE3AEGMQoQCggEBgIECJwIABIE3AEHMApbCgQEBgIF
EgbfAQLkAQQaSyBPdXRwdXQgb25seS4gVGhlIG5hbWUgb2YgdGhlIHJlcGxheSBpbnN0YW5j
ZSwgaWYgbGl2ZSByZXBsYXkgd2FzIGVuYWJsZWQuCgoNCgUEBgIFBBIE3wECCgoNCgUEBgIF
BRIE3wELEQoNCgUEBgIFARIE3wESIQoNCgUEBgIFAxIE3wEkJQoPCgUEBgIFCBIG3wEm5AED
ChAKCAQGAgUInAgAEgTgAQQtChEKBwQGAgUInwgSBuEBBOMBBQpUCgQEBgIGEgTnAQJQGkYg
T3V0cHV0IG9ubHkuIFRoZSByZXRlbnRpb24gcGVyaW9kIGluIGRheXMgZm9yIHRoZSBjYXB0
dXJlZCB3b3JrbG9hZC4KCg0KBQQGAgYEEgTnAQIKCg0KBQQGAgYFEgTnAQsQCg0KBQQGAgYB
EgTnAREfCg0KBQQGAgYDEgTnASIjCg0KBQQGAgYIEgTnASRPChAKCAQGAgYInAgAEgTnASVO
ClUKBAQGAgcSBOoBAkwaRyBPdXRwdXQgb25seS4gVGhlIGJhc2UgYmFja3VwIElEIGFzc29j
aWF0ZWQgd2l0aCB0aGUgd29ya2xvYWQgY2FwdHVyZS4KCg0KBQQGAgcEEgTqAQIKCg0KBQQG
AgcFEgTqAQsRCg0KBQQGAgcBEgTqARIbCg0KBQQGAgcDEgTqAR4fCg0KBQQGAgcIEgTqASBL
ChAKCAQGAgcInAgAEgTqASFKCkgKBAQGAggSBu0BAu4BMho4IE91dHB1dCBvbmx5LiBUaGUg
Y2FwdHVyZSBtb2RlIG9mIHRoZSB3b3JrbG9hZCBjYXB0dXJlLgoKDQoFBAYCCAYSBO0BAhUK
DQoFBAYCCAESBO0BFiIKDQoFBAYCCAMSBO0BJScKDQoFBAYCCAgSBO4BBjEKEAoIBAYCCAic
CAASBO4BBzBiBnByb3RvMw==
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Sql::V1::CloudSqlWorkloadCaptures::WorkloadCapturesStartRequest ===
    # Fields for WorkloadCapturesStartRequest
    # Field: project Type: 9 ()
    # Field: instance Type: 9 ()
    # Field: start_workload_capture_context Type: 11 (.google.cloud.sql.v1.StartWorkloadCaptureContext)

# === Message: Google::Cloud::Sql::V1::CloudSqlWorkloadCaptures::WorkloadCapturesStopRequest ===
    # Fields for WorkloadCapturesStopRequest
    # Field: project Type: 9 ()
    # Field: instance Type: 9 ()
    # Field: stop_workload_capture_context Type: 11 (.google.cloud.sql.v1.StopWorkloadCaptureContext)

# === Message: Google::Cloud::Sql::V1::CloudSqlWorkloadCaptures::WorkloadCapturesStartReplayRequest ===
    # Fields for WorkloadCapturesStartReplayRequest
    # Field: project Type: 9 ()
    # Field: instance Type: 9 ()
    # Field: start_workload_replay_context Type: 11 (.google.cloud.sql.v1.StartWorkloadReplayContext)
    # Field: workload_id Type: 9 ()

# === Message: Google::Cloud::Sql::V1::CloudSqlWorkloadCaptures::WorkloadCapturesStopReplayRequest ===
    # Fields for WorkloadCapturesStopReplayRequest
    # Field: project Type: 9 ()
    # Field: instance Type: 9 ()
    # Field: stop_workload_replay_context Type: 11 (.google.cloud.sql.v1.StopWorkloadReplayContext)

# === Message: Google::Cloud::Sql::V1::CloudSqlWorkloadCaptures::SqlWorkloadCapturesListRequest ===
    # Fields for SqlWorkloadCapturesListRequest
    # Field: project Type: 9 ()
    # Field: instance Type: 9 ()

# === Message: Google::Cloud::Sql::V1::CloudSqlWorkloadCaptures::WorkloadCapturesListResponse ===
    # Fields for WorkloadCapturesListResponse
    # Field: workload_captures Type: 11 (.google.cloud.sql.v1.WorkloadCapture)
    # Field: kind Type: 9 ()

# === Message: Google::Cloud::Sql::V1::CloudSqlWorkloadCaptures::WorkloadCapture ===
    # Fields for WorkloadCapture
    # Field: workload_id Type: 9 ()
    # Field: source_instance Type: 9 ()
    # Field: workload_capture_state Type: 14 (.google.cloud.sql.v1.WorkloadCapture.State)
    # Field: start_time Type: 11 (.google.protobuf.Timestamp)
    # Field: end_time Type: 11 (.google.protobuf.Timestamp)
    # Field: replay_instance Type: 9 ()
    # Field: retention_days Type: 5 ()
    # Field: backup_id Type: 9 ()
    # Field: capture_mode Type: 14 (.google.cloud.sql.v1.WorkloadCapture.WorkloadCaptureMode)

# Enum: WorkloadCapture::State
our $WorkloadCapture_STATE_UNSPECIFIED = 0;
our $WorkloadCapture_RUNNING = 1;
our $WorkloadCapture_COMPLETED = 2;
our $WorkloadCapture_FAILED = 3;
our $WorkloadCapture_TERMINATED = 4;

# Enum: WorkloadCapture::WorkloadCaptureMode
our $WorkloadCapture_WORKLOAD_CAPTURE_MODE_UNSPECIFIED = 0;
our $WorkloadCapture_CAPTURE_ONLY = 1;
our $WorkloadCapture_CAPTURE_AND_LIVE_REPLAY = 2;

# === Service Client: Google::Cloud::Sql::V1::CloudSqlWorkloadCaptures::SqlWorkloadCapturesServiceClient ===
package Google::Cloud::Sql::V1::CloudSqlWorkloadCaptures::SqlWorkloadCapturesServiceClient;

=pod

=head2 Service Client: Google::Cloud::Sql::V1::CloudSqlWorkloadCaptures::SqlWorkloadCapturesServiceClient

Client stub representing the remote C<SqlWorkloadCapturesService> gRPC service. Delegates call dispatching to L<Google::gRPC::Client>.

=head3 target

The endpoint target address. Defaults to C<sql.googleapis.com:443>.

=head3 credentials

The authentication credentials provider. Defaults to application default credentials via L<Google::Auth>.

=cut

use Moo;
use Google::Auth;
use Google::gRPC::Client;

has credentials => ( is => 'ro', default => sub { Google::Auth->default() } );
has target      => ( is => 'ro', default => 'sql.googleapis.com:443' );

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

sub start {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Sql::V1::CloudSqlWorkloadCaptures::WorkloadCapturesStartRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.sql.v1.SqlWorkloadCapturesService',
        method         => 'Start',
        request        => $req,
        response_class => 'Google::Cloud::Sql::V1::CloudSqlResources::Operation',
    });
}

sub stop {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Sql::V1::CloudSqlWorkloadCaptures::WorkloadCapturesStopRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.sql.v1.SqlWorkloadCapturesService',
        method         => 'Stop',
        request        => $req,
        response_class => 'Google::Cloud::Sql::V1::CloudSqlResources::Operation',
    });
}

sub start_replay {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Sql::V1::CloudSqlWorkloadCaptures::WorkloadCapturesStartReplayRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.sql.v1.SqlWorkloadCapturesService',
        method         => 'StartReplay',
        request        => $req,
        response_class => 'Google::Cloud::Sql::V1::CloudSqlResources::Operation',
    });
}

sub stop_replay {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Sql::V1::CloudSqlWorkloadCaptures::WorkloadCapturesStopReplayRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.sql.v1.SqlWorkloadCapturesService',
        method         => 'StopReplay',
        request        => $req,
        response_class => 'Google::Cloud::Sql::V1::CloudSqlResources::Operation',
    });
}

sub list {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Sql::V1::CloudSqlWorkloadCaptures::SqlWorkloadCapturesListRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.sql.v1.SqlWorkloadCapturesService',
        method         => 'List',
        request        => $req,
        response_class => 'Google::Cloud::Sql::V1::CloudSqlWorkloadCaptures::WorkloadCapturesListResponse',
    });
}

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Sql::V1::CloudSqlWorkloadCaptures - Compiled Protocol Buffers messages for google/cloud/sql/v1/cloud_sql_workload_captures.proto

=head1 SYNOPSIS

    use Google::Cloud::Sql::V1::CloudSqlWorkloadCaptures;

    my $msg = Google::Cloud::Sql::V1::CloudSqlWorkloadCaptures::WorkloadCapturesStartRequest->new({
        project => $project,
        instance => $instance,
        start_workload_capture_context => $start_workload_capture_context,
    });

    # Read or update a field
    my $val = $msg->project();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Sql::V1::CloudSqlWorkloadCaptures::WorkloadCapturesStartRequest->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/sql/v1/cloud_sql_workload_captures.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Sql::V1::CloudSqlWorkloadCaptures::WorkloadCapturesStartRequest

Request to start recording traffic from the primary instance (captured
workload).

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->project() >> / C<< $msg->project($value) >>

Type: C<String>

Required. Project ID of the project that contains the instance.

=item * C<< $msg->instance() >> / C<< $msg->instance($value) >>

Type: C<String>

Required. Cloud SQL instance ID. This does not include the project ID.

=item * C<< $msg->start_workload_capture_context() >> / C<< $msg->start_workload_capture_context($value) >>

Type: C<Message> (L<Google::Cloud::Sql::V1::CloudSqlResources::StartWorkloadCaptureContext>)

Optional. Contains details about the start workload capture operation.

=back

=head2 Google::Cloud::Sql::V1::CloudSqlWorkloadCaptures::WorkloadCapturesStopRequest

Request to stop recording traffic from the primary instance.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->project() >> / C<< $msg->project($value) >>

Type: C<String>

Required. Project ID of the project that contains the instance.

=item * C<< $msg->instance() >> / C<< $msg->instance($value) >>

Type: C<String>

Required. Cloud SQL instance ID. This does not include the project ID.

=item * C<< $msg->stop_workload_capture_context() >> / C<< $msg->stop_workload_capture_context($value) >>

Type: C<Message> (L<Google::Cloud::Sql::V1::CloudSqlResources::StopWorkloadCaptureContext>)

Optional. Contains details about the stop workload capture operation.

=back

=head2 Google::Cloud::Sql::V1::CloudSqlWorkloadCaptures::WorkloadCapturesStartReplayRequest

Request to start executing a captured workload on a replay instance (the
Cloud SQL instance where the recorded SQL queries are executed).

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->project() >> / C<< $msg->project($value) >>

Type: C<String>

Required. Project ID of the project that contains the instance.

=item * C<< $msg->instance() >> / C<< $msg->instance($value) >>

Type: C<String>

Required. Cloud SQL instance ID. This does not include the project ID.

=item * C<< $msg->start_workload_replay_context() >> / C<< $msg->start_workload_replay_context($value) >>

Type: C<Message> (L<Google::Cloud::Sql::V1::CloudSqlResources::StartWorkloadReplayContext>)

Required. Contains details about the start workload replay operation.

=item * C<< $msg->workload_id() >> / C<< $msg->workload_id($value) >>

Type: C<String>

Required. The ID of the workload to replay.

=back

=head2 Google::Cloud::Sql::V1::CloudSqlWorkloadCaptures::WorkloadCapturesStopReplayRequest

Request to stop an active workload replay on a target Cloud SQL replay
instance.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->project() >> / C<< $msg->project($value) >>

Type: C<String>

Required. Project ID of the project that contains the target replay
instance.

=item * C<< $msg->instance() >> / C<< $msg->instance($value) >>

Type: C<String>

Required. Cloud SQL instance ID of the target replay instance. This does
not include the project ID.

=item * C<< $msg->stop_workload_replay_context() >> / C<< $msg->stop_workload_replay_context($value) >>

Type: C<Message> (L<Google::Cloud::Sql::V1::CloudSqlResources::StopWorkloadReplayContext>)

Optional. Contains details about the stop workload replay operation. If
omitted, default values are used.

=back

=head2 Google::Cloud::Sql::V1::CloudSqlWorkloadCaptures::SqlWorkloadCapturesListRequest

Instance list captured workloads request.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->project() >> / C<< $msg->project($value) >>

Type: C<String>

Required. Project ID of the project that contains the instance.

=item * C<< $msg->instance() >> / C<< $msg->instance($value) >>

Type: C<String>

Required. Cloud SQL instance ID. This does not include the project ID.

=back

=head2 Google::Cloud::Sql::V1::CloudSqlWorkloadCaptures::WorkloadCapturesListResponse

Instance list captured workloads response.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->workload_captures() >> / C<< $msg->workload_captures($value) >>

Type: C<Message> (L<Google::Cloud::Sql::V1::CloudSqlWorkloadCaptures::WorkloadCapture>)

List of captured workloads for the instance.

=item * C<< $msg->kind() >> / C<< $msg->kind($value) >>

Type: C<String>

This is always `sql#workloadCapturesList`.

=back

=head2 Google::Cloud::Sql::V1::CloudSqlWorkloadCaptures::WorkloadCapture

Captured workload for an instance.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->workload_id() >> / C<< $msg->workload_id($value) >>

Type: C<String>

Output only. The ID of the captured workload.

=item * C<< $msg->source_instance() >> / C<< $msg->source_instance($value) >>

Type: C<String>

Output only. The name of the source instance.

=item * C<< $msg->workload_capture_state() >> / C<< $msg->workload_capture_state($value) >>

Type: C<Enum> (L<Google::Cloud::Sql::V1::WorkloadCapture::State>)

Output only. The state of the workload capture.

=item * C<< $msg->start_time() >> / C<< $msg->start_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Output only. The start time of the workload capture.

=item * C<< $msg->end_time() >> / C<< $msg->end_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Output only. The end time of the workload capture.

=item * C<< $msg->replay_instance() >> / C<< $msg->replay_instance($value) >>

Type: C<String>

Output only. The name of the replay instance, if live replay was enabled.

=item * C<< $msg->retention_days() >> / C<< $msg->retention_days($value) >>

Type: C<Int32>

Output only. The retention period in days for the captured workload.

=item * C<< $msg->backup_id() >> / C<< $msg->backup_id($value) >>

Type: C<String>

Output only. The base backup ID associated with the workload capture.

=item * C<< $msg->capture_mode() >> / C<< $msg->capture_mode($value) >>

Type: C<Enum> (L<Google::Cloud::Sql::V1::WorkloadCapture::WorkloadCaptureMode>)

Output only. The capture mode of the workload capture.

=back

=head3 Enum: WorkloadCapture::State

=over 4

=item * C<STATE_UNSPECIFIED> => C<0>

=item * C<RUNNING> => C<1>

=item * C<COMPLETED> => C<2>

=item * C<FAILED> => C<3>

=item * C<TERMINATED> => C<4>

=back

=head3 Enum: WorkloadCapture::WorkloadCaptureMode

=over 4

=item * C<WORKLOAD_CAPTURE_MODE_UNSPECIFIED> => C<0>

=item * C<CAPTURE_ONLY> => C<1>

=item * C<CAPTURE_AND_LIVE_REPLAY> => C<2>

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Sql::V1::CloudSqlWorkloadCaptures::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
