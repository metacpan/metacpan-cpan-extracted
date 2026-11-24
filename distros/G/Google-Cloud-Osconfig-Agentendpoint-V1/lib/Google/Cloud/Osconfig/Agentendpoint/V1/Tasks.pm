package Google::Cloud::Osconfig::Agentendpoint::V1::Tasks;

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
    eval { require Google::Cloud::Osconfig::Agentendpoint::V1::ConfigCommon };
    eval { require Google::Cloud::Osconfig::Agentendpoint::V1::OsPolicy };
    eval { require Google::Cloud::Osconfig::Agentendpoint::V1::PatchJobs };
    my $descriptor_b64 = <<'EOF';
CjJnb29nbGUvY2xvdWQvb3Njb25maWcvYWdlbnRlbmRwb2ludC92MS90YXNrcy5wcm90bxIm
Z29vZ2xlLmNsb3VkLm9zY29uZmlnLmFnZW50ZW5kcG9pbnQudjEaH2dvb2dsZS9hcGkvZmll
bGRfYmVoYXZpb3IucHJvdG8aGWdvb2dsZS9hcGkvcmVzb3VyY2UucHJvdG8aOmdvb2dsZS9j
bG91ZC9vc2NvbmZpZy9hZ2VudGVuZHBvaW50L3YxL2NvbmZpZ19jb21tb24ucHJvdG8aNmdv
b2dsZS9jbG91ZC9vc2NvbmZpZy9hZ2VudGVuZHBvaW50L3YxL29zX3BvbGljeS5wcm90bxo3
Z29vZ2xlL2Nsb3VkL29zY29uZmlnL2FnZW50ZW5kcG9pbnQvdjEvcGF0Y2hfam9icy5wcm90
byK1BQoEVGFzaxIXCgd0YXNrX2lkGAEgASgJUgZ0YXNrSWQSTQoJdGFza190eXBlGAIgASgO
MjAuZ29vZ2xlLmNsb3VkLm9zY29uZmlnLmFnZW50ZW5kcG9pbnQudjEuVGFza1R5cGVSCHRh
c2tUeXBlElwKDnRhc2tfZGlyZWN0aXZlGAMgASgOMjUuZ29vZ2xlLmNsb3VkLm9zY29uZmln
LmFnZW50ZW5kcG9pbnQudjEuVGFza0RpcmVjdGl2ZVINdGFza0RpcmVjdGl2ZRJoChJhcHBs
eV9wYXRjaGVzX3Rhc2sYBCABKAsyOC5nb29nbGUuY2xvdWQub3Njb25maWcuYWdlbnRlbmRw
b2ludC52MS5BcHBseVBhdGNoZXNUYXNrSABSEGFwcGx5UGF0Y2hlc1Rhc2sSXAoOZXhlY19z
dGVwX3Rhc2sYBSABKAsyNC5nb29nbGUuY2xvdWQub3Njb25maWcuYWdlbnRlbmRwb2ludC52
MS5FeGVjU3RlcFRhc2tIAFIMZXhlY1N0ZXBUYXNrEmUKEWFwcGx5X2NvbmZpZ190YXNrGAcg
ASgLMjcuZ29vZ2xlLmNsb3VkLm9zY29uZmlnLmFnZW50ZW5kcG9pbnQudjEuQXBwbHlDb25m
aWdUYXNrSABSD2FwcGx5Q29uZmlnVGFzaxJmCg5zZXJ2aWNlX2xhYmVscxgGIAMoCzI/Lmdv
b2dsZS5jbG91ZC5vc2NvbmZpZy5hZ2VudGVuZHBvaW50LnYxLlRhc2suU2VydmljZUxhYmVs
c0VudHJ5Ug1zZXJ2aWNlTGFiZWxzGkAKElNlcnZpY2VMYWJlbHNFbnRyeRIQCgNrZXkYASAB
KAlSA2tleRIUCgV2YWx1ZRgCIAEoCVIFdmFsdWU6AjgBQg4KDHRhc2tfZGV0YWlscyKDAQoQ
QXBwbHlQYXRjaGVzVGFzaxJWCgxwYXRjaF9jb25maWcYASABKAsyMy5nb29nbGUuY2xvdWQu
b3Njb25maWcuYWdlbnRlbmRwb2ludC52MS5QYXRjaENvbmZpZ1ILcGF0Y2hDb25maWcSFwoH
ZHJ5X3J1bhgDIAEoCFIGZHJ5UnVuIugBChhBcHBseVBhdGNoZXNUYXNrUHJvZ3Jlc3MSYQoF
c3RhdGUYASABKA4yRi5nb29nbGUuY2xvdWQub3Njb25maWcuYWdlbnRlbmRwb2ludC52MS5B
cHBseVBhdGNoZXNUYXNrUHJvZ3Jlc3MuU3RhdGVCA+BBAlIFc3RhdGUiaQoFU3RhdGUSFQoR
U1RBVEVfVU5TUEVDSUZJRUQQABILCgdTVEFSVEVEEAQSFwoTRE9XTkxPQURJTkdfUEFUQ0hF
UxABEhQKEEFQUExZSU5HX1BBVENIRVMQAhINCglSRUJPT1RJTkcQAyLTAQoWQXBwbHlQYXRj
aGVzVGFza091dHB1dBJfCgVzdGF0ZRgBIAEoDjJELmdvb2dsZS5jbG91ZC5vc2NvbmZpZy5h
Z2VudGVuZHBvaW50LnYxLkFwcGx5UGF0Y2hlc1Rhc2tPdXRwdXQuU3RhdGVCA+BBAlIFc3Rh
dGUiWAoFU3RhdGUSFQoRU1RBVEVfVU5TUEVDSUZJRUQQABINCglTVUNDRUVERUQQARIdChlT
VUNDRUVERURfUkVCT09UX1JFUVVJUkVEEAISCgoGRkFJTEVEEAMiXQoMRXhlY1N0ZXBUYXNr
Ek0KCWV4ZWNfc3RlcBgBIAEoCzIwLmdvb2dsZS5jbG91ZC5vc2NvbmZpZy5hZ2VudGVuZHBv
aW50LnYxLkV4ZWNTdGVwUghleGVjU3RlcCKiAQoURXhlY1N0ZXBUYXNrUHJvZ3Jlc3MSXQoF
c3RhdGUYASABKA4yQi5nb29nbGUuY2xvdWQub3Njb25maWcuYWdlbnRlbmRwb2ludC52MS5F
eGVjU3RlcFRhc2tQcm9ncmVzcy5TdGF0ZUID4EECUgVzdGF0ZSIrCgVTdGF0ZRIVChFTVEFU
RV9VTlNQRUNJRklFRBAAEgsKB1NUQVJURUQQASLgAQoSRXhlY1N0ZXBUYXNrT3V0cHV0ElsK
BXN0YXRlGAEgASgOMkAuZ29vZ2xlLmNsb3VkLm9zY29uZmlnLmFnZW50ZW5kcG9pbnQudjEu
RXhlY1N0ZXBUYXNrT3V0cHV0LlN0YXRlQgPgQQJSBXN0YXRlEiAKCWV4aXRfY29kZRgCIAEo
BUID4EECUghleGl0Q29kZSJLCgVTdGF0ZRIVChFTVEFURV9VTlNQRUNJRklFRBAAEg0KCUNP
TVBMRVRFRBABEg0KCVRJTUVEX09VVBACEg0KCUNBTkNFTExFRBADIpgDCg9BcHBseUNvbmZp
Z1Rhc2sSYQoLb3NfcG9saWNpZXMYASADKAsyQC5nb29nbGUuY2xvdWQub3Njb25maWcuYWdl
bnRlbmRwb2ludC52MS5BcHBseUNvbmZpZ1Rhc2suT1NQb2xpY3lSCm9zUG9saWNpZXMaoQIK
CE9TUG9saWN5Eg4KAmlkGAEgASgJUgJpZBJJCgRtb2RlGAIgASgOMjUuZ29vZ2xlLmNsb3Vk
Lm9zY29uZmlnLmFnZW50ZW5kcG9pbnQudjEuT1NQb2xpY3kuTW9kZVIEbW9kZRJhChRvc19w
b2xpY3lfYXNzaWdubWVudBgDIAEoCUIv+kEsCipvc2NvbmZpZy5nb29nbGVhcGlzLmNvbS9P
U1BvbGljeUFzc2lnbm1lbnRSEm9zUG9saWN5QXNzaWdubWVudBJXCglyZXNvdXJjZXMYBCAD
KAsyOS5nb29nbGUuY2xvdWQub3Njb25maWcuYWdlbnRlbmRwb2ludC52MS5PU1BvbGljeS5S
ZXNvdXJjZVIJcmVzb3VyY2VzIrgBChdBcHBseUNvbmZpZ1Rhc2tQcm9ncmVzcxJbCgVzdGF0
ZRgBIAEoDjJFLmdvb2dsZS5jbG91ZC5vc2NvbmZpZy5hZ2VudGVuZHBvaW50LnYxLkFwcGx5
Q29uZmlnVGFza1Byb2dyZXNzLlN0YXRlUgVzdGF0ZSJACgVTdGF0ZRIVChFTVEFURV9VTlNQ
RUNJRklFRBAAEgsKB1NUQVJURUQQARITCg9BUFBMWUlOR19DT05GSUcQAiLdBAoVQXBwbHlD
b25maWdUYXNrT3V0cHV0El4KBXN0YXRlGAEgASgOMkMuZ29vZ2xlLmNsb3VkLm9zY29uZmln
LmFnZW50ZW5kcG9pbnQudjEuQXBwbHlDb25maWdUYXNrT3V0cHV0LlN0YXRlQgPgQQJSBXN0
YXRlEngKEW9zX3BvbGljeV9yZXN1bHRzGAIgAygLMkwuZ29vZ2xlLmNsb3VkLm9zY29uZmln
LmFnZW50ZW5kcG9pbnQudjEuQXBwbHlDb25maWdUYXNrT3V0cHV0Lk9TUG9saWN5UmVzdWx0
Ug9vc1BvbGljeVJlc3VsdHManwIKDk9TUG9saWN5UmVzdWx0EiAKDG9zX3BvbGljeV9pZBgB
IAEoCVIKb3NQb2xpY3lJZBJhChRvc19wb2xpY3lfYXNzaWdubWVudBgCIAEoCUIv+kEsCipv
c2NvbmZpZy5nb29nbGVhcGlzLmNvbS9PU1BvbGljeUFzc2lnbm1lbnRSEm9zUG9saWN5QXNz
aWdubWVudBKHAQoeb3NfcG9saWN5X3Jlc291cmNlX2NvbXBsaWFuY2VzGAMgAygLMkIuZ29v
Z2xlLmNsb3VkLm9zY29uZmlnLmFnZW50ZW5kcG9pbnQudjEuT1NQb2xpY3lSZXNvdXJjZUNv
bXBsaWFuY2VSG29zUG9saWN5UmVzb3VyY2VDb21wbGlhbmNlcyJICgVTdGF0ZRIVChFTVEFU
RV9VTlNQRUNJRklFRBAAEg0KCVNVQ0NFRURFRBABEgoKBkZBSUxFRBACEg0KCUNBTkNFTExF
RBADKkcKDVRhc2tEaXJlY3RpdmUSHgoaVEFTS19ESVJFQ1RJVkVfVU5TUEVDSUZJRUQQABIM
CghDT05USU5VRRABEggKBFNUT1AQAipjCghUYXNrVHlwZRIZChVUQVNLX1RZUEVfVU5TUEVD
SUZJRUQQABIRCg1BUFBMWV9QQVRDSEVTEAESEgoORVhFQ19TVEVQX1RBU0sQAhIVChFBUFBM
WV9DT05GSUdfVEFTSxADQosCCipjb20uZ29vZ2xlLmNsb3VkLm9zY29uZmlnLmFnZW50ZW5k
cG9pbnQudjFCBVRhc2tzUAFaUGNsb3VkLmdvb2dsZS5jb20vZ28vb3Njb25maWcvYWdlbnRl
bmRwb2ludC9hcGl2MS9hZ2VudGVuZHBvaW50cGI7YWdlbnRlbmRwb2ludHBi6kGAAQoqb3Nj
b25maWcuZ29vZ2xlYXBpcy5jb20vT1NQb2xpY3lBc3NpZ25tZW50ElJwcm9qZWN0cy97cHJv
amVjdH0vbG9jYXRpb25zL3tsb2NhdGlvbn0vb3NQb2xpY3lBc3NpZ25tZW50cy97b3NfcG9s
aWN5X2Fzc2lnbm1lbnR9SupGCgcSBQ4AnwIBCrwECgEMEgMOABIysQQgQ29weXJpZ2h0IDIw
MjYgR29vZ2xlIExMQwoKIExpY2Vuc2VkIHVuZGVyIHRoZSBBcGFjaGUgTGljZW5zZSwgVmVy
c2lvbiAyLjAgKHRoZSAiTGljZW5zZSIpOwogeW91IG1heSBub3QgdXNlIHRoaXMgZmlsZSBl
eGNlcHQgaW4gY29tcGxpYW5jZSB3aXRoIHRoZSBMaWNlbnNlLgogWW91IG1heSBvYnRhaW4g
YSBjb3B5IG9mIHRoZSBMaWNlbnNlIGF0CgogICAgIGh0dHA6Ly93d3cuYXBhY2hlLm9yZy9s
aWNlbnNlcy9MSUNFTlNFLTIuMAoKIFVubGVzcyByZXF1aXJlZCBieSBhcHBsaWNhYmxlIGxh
dyBvciBhZ3JlZWQgdG8gaW4gd3JpdGluZywgc29mdHdhcmUKIGRpc3RyaWJ1dGVkIHVuZGVy
IHRoZSBMaWNlbnNlIGlzIGRpc3RyaWJ1dGVkIG9uIGFuICJBUyBJUyIgQkFTSVMsCiBXSVRI
T1VUIFdBUlJBTlRJRVMgT1IgQ09ORElUSU9OUyBPRiBBTlkgS0lORCwgZWl0aGVyIGV4cHJl
c3Mgb3IgaW1wbGllZC4KIFNlZSB0aGUgTGljZW5zZSBmb3IgdGhlIHNwZWNpZmljIGxhbmd1
YWdlIGdvdmVybmluZyBwZXJtaXNzaW9ucyBhbmQKIGxpbWl0YXRpb25zIHVuZGVyIHRoZSBM
aWNlbnNlLgoKCAoBAhIDEAAvCgkKAgMAEgMSACkKCQoCAwESAxMAIwoJCgIDAhIDFABECgkK
AgMDEgMVAEAKCQoCAwQSAxYAQQoICgEIEgMYAGcKCQoCCAsSAxgAZwoICgEIEgMZACIKCQoC
CAoSAxkAIgoICgEIEgMaACYKCQoCCAgSAxoAJgoICgEIEgMbAEMKCQoCCAESAxsAQwoJCgEI
EgQcAB8CCgwKBAidCAASBBwAHwIKMwoCBQASBCIALQEaJyBTcGVjaWZpZXMgdGhlIGN1cnJl
bnQgYWdlbnQgYmVoYXZpb3IuCgoKCgMFAAESAyIFEgomCgQFAAIAEgMkAiEaGSBVbnNwZWNp
ZmllZCBpcyBpbnZhbGlkLgoKDAoFBQACAAESAyQCHAoMCgUFAAIAAhIDJB8gCjQKBAUAAgES
AycCDxonIFRoZSB0YXNrIHNob3VsZCBjb250aW51ZSB0byBwcm9ncmVzcy4KCgwKBQUAAgEB
EgMnAgoKDAoFBQACAQISAycNDgqpAQoEBQACAhIDLAILGpsBIFRhc2sgc2hvdWxkIG5vdCBi
ZSBzdGFydGVkLCBvciBpZiBhbHJlYWR5IGluIHByb2dyZXNzLCBzaG91bGQgc3RvcAogYXQg
Zmlyc3Qgc2FmZSBzdG9wcGluZyBwb2ludC4gIFRhc2sgc2hvdWxkIGJlIGNvbnNpZGVyZWQg
ZG9uZSBhbmQgd2lsbAogbmV2ZXIgcmVwZWF0LgoKDAoFBQACAgESAywCBgoMCgUFAAICAhID
LAkKCjQKAgUBEgQwADwBGiggU3BlY2lmaWVzIHRoZSB0eXBlIG9mIHRhc2sgdG8gcGVyZm9y
bS4KCgoKAwUBARIDMAUNCiYKBAUBAgASAzICHBoZIFVuc3BlY2lmaWVkIGlzIGludmFsaWQu
CgoMCgUFAQIAARIDMgIXCgwKBQUBAgACEgMyGhsKJgoEBQECARIDNQIUGhkgVGhlIGFwcGx5
IHBhdGNoZXMgdGFzay4KCgwKBQUBAgEBEgM1Ag8KDAoFBQECAQISAzUSEwoiCgQFAQICEgM4
AhUaFSBUaGUgZXhlYyBzdGVwIHRhc2suCgoMCgUFAQICARIDOAIQCgwKBQUBAgICEgM4ExQK
JAoEBQECAxIDOwIYGhcgVGhlIGFwcGx5IGNvbmZpZyB0YXNrCgoMCgUFAQIDARIDOwITCgwK
BQUBAgMCEgM7FhcKOgoCBAASBD8AXQEaLiBBIHVuaXQgb2Ygd29yayB0byBiZSBwZXJmb3Jt
ZWQgYnkgdGhlIGFnZW50LgoKCgoDBAABEgM/CAwKHgoEBAACABIDQQIVGhEgVW5pcXVlIHRh
c2sgaWQuCgoMCgUEAAIABRIDQQIICgwKBQQAAgABEgNBCRAKDAoFBAACAAMSA0ETFArpAQoE
BAACARIDSgIZGtsBIFRoZSB0eXBlIG9mIHRhc2sgdG8gcGVyZm9ybS4KCiBUYXNrIGRldGFp
bHMgbXVzdCBpbmNsdWRlIHRoZSBhcHByb3ByaWF0ZSBtZXNzYWdlIGJhc2VkIG9uIHRoaXMg
ZW51bSBhcwogc3BlY2lmaWVkIGJlbG93OgogQVBQTFlfUEFUQ0hFUyA9IEFwcGx5UGF0Y2hl
c1Rhc2sKIEVYRUNfU1RFUCA9IEV4ZWNTdGVwVGFzawogQVBQTFlfQ09ORklHX1RBU0sgPSBB
cHBseUNvbmZpZ1Rhc2sKCgwKBQQAAgEGEgNKAgoKDAoFBAACAQESA0oLFAoMCgUEAAIBAxID
ShcYCi4KBAQAAgISA00CIxohIEN1cnJlbnQgZGlyZWN0aXZlIHRvIHRoZSBhZ2VudC4KCgwK
BQQAAgIGEgNNAg8KDAoFBAACAgESA00QHgoMCgUEAAICAxIDTSEiCkMKBAQACAASBFACWQMa
NSBTcGVjaWZpYyBkZXRhaWxzIGFib3V0IHRoZSBjdXJyZW50IHRhc2sgdG8gcGVyZm9ybS4K
CgwKBQQACAABEgNQCBQKPwoEBAACAxIDUgQsGjIgRGV0YWlscyBhYm91dCB0aGUgYXBwbHkg
cGF0Y2hlcyB0YXNrIHRvIHBlcmZvcm0uCgoMCgUEAAIDBhIDUgQUCgwKBQQAAgMBEgNSFScK
DAoFBAACAwMSA1IqKwo7CgQEAAIEEgNVBCQaLiBEZXRhaWxzIGFib3V0IHRoZSBleGVjIHN0
ZXAgdGFzayB0byBwZXJmb3JtLgoKDAoFBAACBAYSA1UEEAoMCgUEAAIEARIDVREfCgwKBQQA
AgQDEgNVIiMKQwoEBAACBRIDWAQqGjYgRGV0YWlscyBhYm91dCB0aGUgYXBwbHkgY29uZmln
IHN0ZXAgdGFzayB0byBwZXJmb3JtLgoKDAoFBAACBQYSA1gEEwoMCgUEAAIFARIDWBQlCgwK
BQQAAgUDEgNYKCkKSgoEBAACBhIDXAIpGj0gTGFiZWxzIGRlc2NyaWJpbmcgdGhlIHRhc2su
ICBVc2VkIGZvciBsb2dnaW5nIGJ5IHRoZSBhZ2VudC4KCgwKBQQAAgYGEgNcAhUKDAoFBAAC
BgESA1wWJAoMCgUEAAIGAxIDXCcoCj0KAgQBEgRgAGcBGjEgTWVzc2FnZSB3aGljaCBpbnN0
cnVjdHMgYWdlbnQgdG8gYXBwbHkgcGF0Y2hlcy4KCgoKAwQBARIDYAgYCkgKBAQBAgASA2IC
Hxo7IFNwZWNpZmljIGluZm9ybWF0aW9uIGFib3V0IGhvdyBwYXRjaGVzIHNob3VsZCBiZSBh
cHBsaWVkLgoKDAoFBAECAAYSA2ICDQoMCgUEAQIAARIDYg4aCgwKBQQBAgADEgNiHR4KlAEK
BAQBAgESA2YCExqGASBJZiB0cnVlLCB0aGUgYWdlbnQgd2lsbCByZXBvcnQgaXRzIHN0YXR1
cyBhcyBpdCBnb2VzIHRocm91Z2ggdGhlIG1vdGlvbnMKIGJ1dCB3b24ndCBhY3R1YWxseSBy
dW4gYW55IHVwZGF0ZXMgb3IgcGVyZm9ybSBhbnkgcmVib290cy4KCgwKBQQBAgEFEgNmAgYK
DAoFBAECAQESA2YHDgoMCgUEAQIBAxIDZhESClMKAgQCEgRqAH8BGkcgSW5mb3JtYXRpb24g
cmVwb3J0ZWQgZnJvbSB0aGUgYWdlbnQgYWJvdXQgYXBwbHlpbmcgcGF0Y2hlcyBleGVjdXRp
b24uCgoKCgMEAgESA2oIIAo8CgQEAgQAEgRsAnsDGi4gVGhlIGludGVybWVkaWF0ZSBzdGF0
ZXMgb2YgYXBwbHlpbmcgcGF0Y2hlcy4KCgwKBQQCBAABEgNsBwwKKAoGBAIEAAIAEgNuBBoa
GSBVbnNwZWNpZmllZCBpcyBpbnZhbGlkLgoKDgoHBAIEAAIAARIDbgQVCg4KBwQCBAACAAIS
A24YGQo2CgYEAgQAAgESA3EEEBonIFRoZSBhZ2VudCBoYXMgc3RhcnRlZCB0aGUgcGF0Y2gg
dGFzay4KCg4KBwQCBAACAQESA3EECwoOCgcEAgQAAgECEgNxDg8KPAoGBAIEAAICEgN0BBwa
LSBUaGUgYWdlbnQgaXMgY3VycmVudGx5IGRvd25sb2FkaW5nIHBhdGNoZXMuCgoOCgcEAgQA
AgIBEgN0BBcKDgoHBAIEAAICAhIDdBobCjkKBgQCBAACAxIDdwQZGiogVGhlIGFnZW50IGlz
IGN1cnJlbnRseSBhcHBseWluZyBwYXRjaGVzLgoKDgoHBAIEAAIDARIDdwQUCg4KBwQCBAAC
AwISA3cXGAo/CgYEAgQAAgQSA3oEEhowIFRoZSBhZ2VudCBpcyBjdXJyZW50bHkgcmVib290
aW5nIHRoZSBpbnN0YW5jZS4KCg4KBwQCBAACBAESA3oEDQoOCgcEAgQAAgQCEgN6EBEKQwoE
BAICABIDfgI7GjYgUmVxdWlyZWQuIFRoZSBjdXJyZW50IHN0YXRlIG9mIHRoaXMgcGF0Y2gg
ZXhlY3V0aW9uLgoKDAoFBAICAAYSA34CBwoMCgUEAgIAARIDfggNCgwKBQQCAgADEgN+EBEK
DAoFBAICAAgSA34SOgoPCggEAgIACJwIABIDfhM5ClUKAgQDEgaCAQCUAQEaRyBJbmZvcm1h
dGlvbiByZXBvcnRlZCBmcm9tIHRoZSBhZ2VudCBhYm91dCBhcHBseWluZyBwYXRjaGVzIGV4
ZWN1dGlvbi4KCgsKAwQDARIEggEIHgo3CgQEAwQAEgaEAQKQAQMaJyBUaGUgZmluYWwgc3Rh
dGVzIG9mIGFwcGx5aW5nIHBhdGNoZXMuCgoNCgUEAwQAARIEhAEHDAopCgYEAwQAAgASBIYB
BBoaGSBVbnNwZWNpZmllZCBpcyBpbnZhbGlkLgoKDwoHBAMEAAIAARIEhgEEFQoPCgcEAwQA
AgACEgSGARgZCjoKBgQDBAACARIEiQEEEhoqIEFwcGx5aW5nIHBhdGNoZXMgY29tcGxldGVk
IHN1Y2Nlc3NmdWxseS4KCg8KBwQDBAACAQESBIkBBA0KDwoHBAMEAAIBAhIEiQEQEQpUCgYE
AwQAAgISBIwBBCIaRCBBcHBseWluZyBwYXRjaGVzIGNvbXBsZXRlZCBzdWNjZXNzZnVsbHks
IGJ1dCBhIHJlYm9vdCBpcyByZXF1aXJlZC4KCg8KBwQDBAACAgESBIwBBB0KDwoHBAMEAAIC
AhIEjAEgIQoqCgYEAwQAAgMSBI8BBA8aGiBBcHBseWluZyBwYXRjaGVzIGZhaWxlZC4KCg8K
BwQDBAACAwESBI8BBAoKDwoHBAMEAAIDAhIEjwENDgo3CgQEAwIAEgSTAQI7GikgUmVxdWly
ZWQuIFRoZSBmaW5hbCBzdGF0ZSBvZiB0aGlzIHRhc2suCgoNCgUEAwIABhIEkwECBwoNCgUE
AwIAARIEkwEIDQoNCgUEAwIAAxIEkwEQEQoNCgUEAwIACBIEkwESOgoQCggEAwIACJwIABIE
kwETOQpPCgIEBBIGlwEAmgEBGkEgTWVzc2FnZSB3aGljaCBpbnN0cnVjdHMgYWdlbnQgdG8g
ZXhlY3V0ZSB0aGUgZm9sbG93aW5nIGNvbW1hbmQuCgoLCgMEBAESBJcBCBQKMAoEBAQCABIE
mQECGRoiIERldGFpbHMgb2YgdGhlIGV4ZWMgc3RlcCB0byBydW4uCgoNCgUEBAIABhIEmQEC
CgoNCgUEBAIAARIEmQELFAoNCgUEBAIAAxIEmQEXGApSCgIEBRIGnQEAqQEBGkQgSW5mb3Jt
YXRpb24gcmVwb3J0ZWQgZnJvbSB0aGUgYWdlbnQgYWJvdXQgdGhlIGV4ZWMgc3RlcCBleGVj
dXRpb24uCgoLCgMEBQESBJ0BCBwKOAoEBAUEABIGnwECpQEDGiggVGhlIGludGVybWVkaWF0
ZSBzdGF0ZXMgb2YgZXhlYyBzdGVwcy4KCg0KBQQFBAABEgSfAQcMCikKBgQFBAACABIEoQEE
GhoZIFVuc3BlY2lmaWVkIGlzIGludmFsaWQuCgoPCgcEBQQAAgABEgShAQQVCg8KBwQFBAAC
AAISBKEBGBkKOwoGBAUEAAIBEgSkAQQQGisgVGhlIGFnZW50IGhhcyBzdGFydGVkIHRoZSBl
eGVjIHN0ZXAgdGFzay4KCg8KBwQFBAACAQESBKQBBAsKDwoHBAUEAAIBAhIEpAEODwo+CgQE
BQIAEgSoAQI7GjAgUmVxdWlyZWQuIFRoZSBjdXJyZW50IHN0YXRlIG9mIHRoaXMgZXhlYyBz
dGVwLgoKDQoFBAUCAAYSBKgBAgcKDQoFBAUCAAESBKgBCA0KDQoFBAUCAAMSBKgBEBEKDQoF
BAUCAAgSBKgBEjoKEAoIBAUCAAicCAASBKgBEzkKUgoCBAYSBqwBAMIBARpEIEluZm9ybWF0
aW9uIHJlcG9ydGVkIGZyb20gdGhlIGFnZW50IGFib3V0IHRoZSBleGVjIHN0ZXAgZXhlY3V0
aW9uLgoKCwoDBAYBEgSsAQgaCjEKBAQGBAASBq4BAroBAxohIFRoZSBmaW5hbCBzdGF0ZXMg
b2YgZXhlYyBzdGVwcy4KCg0KBQQGBAABEgSuAQcMCikKBgQGBAACABIEsAEEGhoZIFVuc3Bl
Y2lmaWVkIGlzIGludmFsaWQuCgoPCgcEBgQAAgABEgSwAQQVCg8KBwQGBAACAAISBLABGBkK
MwoGBAYEAAIBEgSzAQQSGiMgVGhlIGV4ZWMgc3RlcCBjb21wbGV0ZWQgbm9ybWFsbHkuCgoP
CgcEBgQAAgEBEgSzAQQNCg8KBwQGBAACAQISBLMBEBEKSAoGBAYEAAICEgS2AQQSGjggVGhl
IGV4ZWMgc3RlcCB3YXMgdGVybWluYXRlZCBiZWNhdXNlIGl0IHRvb2sgdG9vIGxvbmcuCgoP
CgcEBgQAAgIBEgS2AQQNCg8KBwQGBAACAgISBLYBEBEKRQoGBAYEAAIDEgS5AQQSGjUgVGhl
IGV4ZWMgc3RlcCB0YXNrIHdhcyBjYW5jZWxsZWQgYmVmb3JlIGl0IHN0YXJ0ZWQuCgoPCgcE
BgQAAgMBEgS5AQQNCg8KBwQGBAACAwISBLkBEBEKOwoEBAYCABIEvQECOxotIFJlcXVpcmVk
LiBUaGUgZmluYWwgc3RhdGUgb2YgdGhlIGV4ZWMgc3RlcC4KCg0KBQQGAgAGEgS9AQIHCg0K
BQQGAgABEgS9AQgNCg0KBQQGAgADEgS9ARARCg0KBQQGAgAIEgS9ARI6ChAKCAQGAgAInAgA
EgS9ARM5CmUKBAQGAgESBMEBAj8aVyBSZXF1aXJlZC4gVGhlIGV4aXQgY29kZSByZWNlaXZl
ZCBmcm9tIHRoZSBzY3JpcHQgd2hpY2ggcmFuIGFzIHBhcnQgb2YgdGhlCiBleGVjIHN0ZXAu
CgoNCgUEBgIBBRIEwQECBwoNCgUEBgIBARIEwQEIEQoNCgUEBgIBAxIEwQEUFQoNCgUEBgIB
CBIEwQEWPgoQCggEBgIBCJwIABIEwQEXPQpiCgIEBxIGxgEA4QEBGlQgTWVzc2FnZSB3aGlj
aCBpbnN0cnVjdHMgT1MgQ29uZmlnIGFnZW50IHRvIGFwcGx5IHRoZSBkZXNpcmVkIHN0YXRl
CiBjb25maWd1cmF0aW9uLgoKCwoDBAcBEgTGAQgXCjQKBAQHAwASBsgBAt0BAxokIE1lc3Nh
Z2UgcmVwcmVzZW50aW5nIGFuIE9TIHBvbGljeS4KCg0KBQQHAwABEgTIAQoSClgKBgQHAwAC
ABIEywEEEhpIIFVzZXIgcHJvdmlkZWQgcG9saWN5IGlkLgogVXNlZCBmb3IgcmVwb3J0aW5n
IGFuZCBsb2dnaW5nIGJ5IHRoZSBhZ2VudC4KCg8KBwQHAwACAAUSBMsBBAoKDwoHBAcDAAIA
ARIEywELDQoPCgcEBwMAAgADEgTLARARCiEKBgQHAwACARIEzgEEQxoRIFRoZSBwb2xpY3kg
bW9kZQoKDwoHBAcDAAIBBhIEzgEEOQoPCgcEBwMAAgEBEgTOATo+Cg8KBwQHAwACAQMSBM4B
QUIKigIKBgQHAwACAhIG1QEE1wEHGvcBIFJlZmVyZW5jZSB0byB0aGUgYE9TUG9saWN5QXNz
aWdubWVudGAgQVBJIHJlc291cmNlIHRoYXQgdGhpcyBgT1NQb2xpY3lgCiBiZWxvbmdzIHRv
LgogRm9ybWF0OgogcHJvamVjdHMve3Byb2plY3RfbnVtYmVyfS9sb2NhdGlvbnMve2xvY2F0
aW9ufS9vc1BvbGljeUFzc2lnbm1lbnRzL3tvc19wb2xpY3lfYXNzaWdubWVudF9pZEByZXZp
c2lvbl9pZH0KIFVzZWQgZm9yIHJlcG9ydGluZyBhbmQgbG9nZ2luZyBieSB0aGUgYWdlbnQu
CgoPCgcEBwMAAgIFEgTVAQQKCg8KBwQHAwACAgESBNUBCx8KDwoHBAcDAAICAxIE1QEiIwoR
CgcEBwMAAgIIEgbVASTXAQYKEwoJBAcDAAICCJ8IEgbVASXXAQUKYwoGBAcDAAIDEgbbAQTc
ARYaUSBMaXN0IG9mIHJlc291cmNlcyBhc3NvY2lhdGVkIHdpdGggdGhlIHBvbGljeSB0byBi
ZSBzZXQgdG8gdGhlaXIKIGRlc2lyZWQgc3RhdGUuCgoPCgcEBwMAAgMEEgTbAQQMCg8KBwQH
AwACAwYSBNsBDUYKDwoHBAcDAAIDARIE3AEIEQoPCgcEBwMAAgMDEgTcARQVCkMKBAQHAgAS
BOABAiQaNSBMaXN0IG9mIG9zIHBvbGljaWVzIHRvIGJlIGFwcGxpZWQgZm9yIHRoZSBpbnN0
YW5jZS4KCg0KBQQHAgAEEgTgAQIKCg0KBQQHAgAGEgTgAQsTCg0KBQQHAgABEgTgARQfCg0K
BQQHAgADEgTgASIjCoABCgIECBIG5QEA9AEBGnIgSW5mb3JtYXRpb24gcmVwb3J0ZWQgZnJv
bSB0aGUgYWdlbnQgcmVnYXJkaW5nIHRoZSBwcm9ncmVzcyBvZiB0aGUgdGFzayBvZgogYXBw
bHlpbmcgZGVzaXJlZCBzdGF0ZSBjb25maWd1cmF0aW9uLgoKCwoDBAgBEgTlAQgfCj8KBAQI
BAASBucBAvABAxovIFRoZSBpbnRlcm1lZGlhdGUgc3RhdGVzIG9mIGFwcGx5IGNvbmZpZyB0
YXNrLgoKDQoFBAgEAAESBOcBBwwKHwoGBAgEAAIAEgTpAQQaGg8gSW52YWxpZCBzdGF0ZQoK
DwoHBAgEAAIAARIE6QEEFQoPCgcECAQAAgACEgTpARgZCjEKBgQIBAACARIE7AEEEBohIFRo
ZSBhZ2VudCBoYXMgc3RhcnRlZCB0aGUgdGFzay4KCg8KBwQIBAACAQESBOwBBAsKDwoHBAgE
AAIBAhIE7AEODwpMCgYECAQAAgISBO8BBBgaPCBUaGUgYWdlbnQgaXMgaW4gdGhlIHByb2Nl
c3Mgb2YgYXBwbHlpbmcgdGhlIGNvbmZpZ3VyYXRpb24uCgoPCgcECAQAAgIBEgTvAQQTCg8K
BwQIBAACAgISBO8BFhcKLwoEBAgCABIE8wECEhohIFRoZSBjdXJyZW50IHN0YXRlIG9mIHRo
aXMgdGFzay4KCg0KBQQIAgAGEgTzAQIHCg0KBQQIAgABEgTzAQgNCg0KBQQIAgADEgTzARAR
Cn4KAgQJEgb4AQCfAgEacCBJbmZvcm1hdGlvbiByZXBvcnRlZCBmcm9tIHRoZSBhZ2VudCBy
ZWdhcmRpbmcgdGhlIG91dHB1dCBvZiB0aGUgdGFzayBvZgogYXBwbHlpbmcgZGVzaXJlZCBz
dGF0ZSBjb25maWd1cmF0aW9uLgoKCwoDBAkBEgT4AQgdCksKBAQJAwASBvoBAokCAxo7IFJl
c3VsdCBvZiBhcHBseWluZyBkZXNpcmVkIHN0YXRlIGNvbmZpZyBmb3IgYW4gT1MgcG9saWN5
LgoKDQoFBAkDAAESBPoBChgKIgoGBAkDAAIAEgT8AQQcGhIgVGhlIE9TIHBvbGljeSBpZAoK
DwoHBAkDAAIABRIE/AEECgoPCgcECQMAAgABEgT8AQsXCg8KBwQJAwACAAMSBPwBGhsKigIK
BgQJAwACARIGgwIEhQIHGvcBIFJlZmVyZW5jZSB0byB0aGUgYE9TUG9saWN5QXNzaWdubWVu
dGAgQVBJIHJlc291cmNlIHRoYXQgdGhpcyBgT1NQb2xpY3lgCiBiZWxvbmdzIHRvLgogRm9y
bWF0OgogcHJvamVjdHMve3Byb2plY3RfbnVtYmVyfS9sb2NhdGlvbnMve2xvY2F0aW9ufS9v
c1BvbGljeUFzc2lnbm1lbnRzL3tvc19wb2xpY3lfYXNzaWdubWVudF9pZEByZXZpc2lvbl9p
ZH0KIFVzZWQgZm9yIHJlcG9ydGluZyBhbmQgbG9nZ2luZyBieSB0aGUgYWdlbnQuCgoPCgcE
CQMAAgEFEgSDAgQKCg8KBwQJAwACAQESBIMCCx8KDwoHBAkDAAIBAxIEgwIiIwoRCgcECQMA
AgEIEgaDAiSFAgYKEwoJBAkDAAIBCJ8IEgaDAiWFAgUKVwoGBAkDAAICEgSIAgRLGkcgUmVz
dWx0cyBvZiBhcHBseWluZyBkZXNpcmVkIHN0YXRlIGNvbmZpZyBmb3IgdGhlIE9TIHBvbGlj
eSByZXNvdXJjZXMuCgoPCgcECQMAAgIEEgSIAgQMCg8KBwQJAwACAgYSBIgCDScKDwoHBAkD
AAICARIEiAIoRgoPCgcECQMAAgIDEgSIAklKCi8KBAQJBAASBowCApgCAxofIFRoZSBmaW5h
bCBzdGF0ZSBvZiB0aGlzIHRhc2suCgoNCgUECQQAARIEjAIHDAopCgYECQQAAgASBI4CBBoa
GSBVbnNwZWNpZmllZCBpcyBpbnZhbGlkLgoKDwoHBAkEAAIAARIEjgIEFQoPCgcECQQAAgAC
EgSOAhgZCj8KBgQJBAACARIEkQIEEhovIFRoZSBhcHBseSBjb25maWcgdGFzayBjb21wbGV0
ZWQgc3VjY2Vzc2Z1bGx5LgoKDwoHBAkEAAIBARIEkQIEDQoPCgcECQQAAgECEgSRAhARCi8K
BgQJBAACAhIElAIEDxofIFRoZSBhcHBseSBjb25maWcgdGFzayBmYWlsZWQuCgoPCgcECQQA
AgIBEgSUAgQKCg8KBwQJBAACAgISBJQCDQ4KNgoGBAkEAAIDEgSXAgQSGiYgVGhlIGFwcGx5
IGNvbmZpZyB0YXNrIHdhcyBjYW5jZWxsZWQuCgoPCgcECQQAAgMBEgSXAgQNCg8KBwQJBAAC
AwISBJcCEBEKNwoEBAkCABIEmwICOxopIFJlcXVpcmVkLiBUaGUgZmluYWwgc3RhdGUgb2Yg
dGhpcyB0YXNrLgoKDQoFBAkCAAYSBJsCAgcKDQoFBAkCAAESBJsCCA0KDQoFBAkCAAMSBJsC
EBEKDQoFBAkCAAgSBJsCEjoKEAoIBAkCAAicCAASBJsCEzkKTQoEBAkCARIEngICMBo/IFJl
c3VsdHMgb2YgYXBwbHlpbmcgZGVzaXJlZCBzdGF0ZSBjb25maWcgZm9yIHRoZSBPUyBwb2xp
Y2llcy4KCg0KBQQJAgEEEgSeAgIKCg0KBQQJAgEGEgSeAgsZCg0KBQQJAgEBEgSeAhorCg0K
BQQJAgEDEgSeAi4vYgZwcm90bzM=
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Osconfig::Agentendpoint::V1::Tasks::Task ===
    # Fields for Task
    # Field: task_id Type: 9 ()
    # Field: task_type Type: 14 (.google.cloud.osconfig.agentendpoint.v1.TaskType)
    # Field: task_directive Type: 14 (.google.cloud.osconfig.agentendpoint.v1.TaskDirective)
    # Field: apply_patches_task Type: 11 (.google.cloud.osconfig.agentendpoint.v1.ApplyPatchesTask)
    # Field: exec_step_task Type: 11 (.google.cloud.osconfig.agentendpoint.v1.ExecStepTask)
    # Field: apply_config_task Type: 11 (.google.cloud.osconfig.agentendpoint.v1.ApplyConfigTask)
    # Field: service_labels Type: 11 (.google.cloud.osconfig.agentendpoint.v1.Task.ServiceLabelsEntry)

# === Message: Google::Cloud::Osconfig::Agentendpoint::V1::Tasks::ApplyPatchesTask ===
    # Fields for ApplyPatchesTask
    # Field: patch_config Type: 11 (.google.cloud.osconfig.agentendpoint.v1.PatchConfig)
    # Field: dry_run Type: 8 ()

# === Message: Google::Cloud::Osconfig::Agentendpoint::V1::Tasks::ApplyPatchesTaskProgress ===
    # Fields for ApplyPatchesTaskProgress
    # Field: state Type: 14 (.google.cloud.osconfig.agentendpoint.v1.ApplyPatchesTaskProgress.State)

# Enum: ApplyPatchesTaskProgress::State
our $ApplyPatchesTaskProgress_STATE_UNSPECIFIED = 0;
our $ApplyPatchesTaskProgress_STARTED = 4;
our $ApplyPatchesTaskProgress_DOWNLOADING_PATCHES = 1;
our $ApplyPatchesTaskProgress_APPLYING_PATCHES = 2;
our $ApplyPatchesTaskProgress_REBOOTING = 3;

# === Message: Google::Cloud::Osconfig::Agentendpoint::V1::Tasks::ApplyPatchesTaskOutput ===
    # Fields for ApplyPatchesTaskOutput
    # Field: state Type: 14 (.google.cloud.osconfig.agentendpoint.v1.ApplyPatchesTaskOutput.State)

# Enum: ApplyPatchesTaskOutput::State
our $ApplyPatchesTaskOutput_STATE_UNSPECIFIED = 0;
our $ApplyPatchesTaskOutput_SUCCEEDED = 1;
our $ApplyPatchesTaskOutput_SUCCEEDED_REBOOT_REQUIRED = 2;
our $ApplyPatchesTaskOutput_FAILED = 3;

# === Message: Google::Cloud::Osconfig::Agentendpoint::V1::Tasks::ExecStepTask ===
    # Fields for ExecStepTask
    # Field: exec_step Type: 11 (.google.cloud.osconfig.agentendpoint.v1.ExecStep)

# === Message: Google::Cloud::Osconfig::Agentendpoint::V1::Tasks::ExecStepTaskProgress ===
    # Fields for ExecStepTaskProgress
    # Field: state Type: 14 (.google.cloud.osconfig.agentendpoint.v1.ExecStepTaskProgress.State)

# Enum: ExecStepTaskProgress::State
our $ExecStepTaskProgress_STATE_UNSPECIFIED = 0;
our $ExecStepTaskProgress_STARTED = 1;

# === Message: Google::Cloud::Osconfig::Agentendpoint::V1::Tasks::ExecStepTaskOutput ===
    # Fields for ExecStepTaskOutput
    # Field: state Type: 14 (.google.cloud.osconfig.agentendpoint.v1.ExecStepTaskOutput.State)
    # Field: exit_code Type: 5 ()

# Enum: ExecStepTaskOutput::State
our $ExecStepTaskOutput_STATE_UNSPECIFIED = 0;
our $ExecStepTaskOutput_COMPLETED = 1;
our $ExecStepTaskOutput_TIMED_OUT = 2;
our $ExecStepTaskOutput_CANCELLED = 3;

# === Message: Google::Cloud::Osconfig::Agentendpoint::V1::Tasks::ApplyConfigTask ===
    # Fields for ApplyConfigTask
    # Field: os_policies Type: 11 (.google.cloud.osconfig.agentendpoint.v1.ApplyConfigTask.OSPolicy)

# === Message: Google::Cloud::Osconfig::Agentendpoint::V1::Tasks::ApplyConfigTaskProgress ===
    # Fields for ApplyConfigTaskProgress
    # Field: state Type: 14 (.google.cloud.osconfig.agentendpoint.v1.ApplyConfigTaskProgress.State)

# Enum: ApplyConfigTaskProgress::State
our $ApplyConfigTaskProgress_STATE_UNSPECIFIED = 0;
our $ApplyConfigTaskProgress_STARTED = 1;
our $ApplyConfigTaskProgress_APPLYING_CONFIG = 2;

# === Message: Google::Cloud::Osconfig::Agentendpoint::V1::Tasks::ApplyConfigTaskOutput ===
    # Fields for ApplyConfigTaskOutput
    # Field: state Type: 14 (.google.cloud.osconfig.agentendpoint.v1.ApplyConfigTaskOutput.State)
    # Field: os_policy_results Type: 11 (.google.cloud.osconfig.agentendpoint.v1.ApplyConfigTaskOutput.OSPolicyResult)

# Enum: ApplyConfigTaskOutput::State
our $ApplyConfigTaskOutput_STATE_UNSPECIFIED = 0;
our $ApplyConfigTaskOutput_SUCCEEDED = 1;
our $ApplyConfigTaskOutput_FAILED = 2;
our $ApplyConfigTaskOutput_CANCELLED = 3;

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Osconfig::Agentendpoint::V1::Tasks - Compiled Protocol Buffers messages for google/cloud/osconfig/agentendpoint/v1/tasks.proto

=head1 SYNOPSIS

    use Google::Cloud::Osconfig::Agentendpoint::V1::Tasks;

    my $msg = Google::Cloud::Osconfig::Agentendpoint::V1::Tasks::Task->new({
        task_id => $task_id,
        task_type => $task_type,
        task_directive => $task_directive,
        apply_patches_task => $apply_patches_task,
    });

    # Read or update a field
    my $val = $msg->task_id();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Osconfig::Agentendpoint::V1::Tasks::Task->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/osconfig/agentendpoint/v1/tasks.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Osconfig::Agentendpoint::V1::Tasks::Task

A unit of work to be performed by the agent.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->task_id() >> / C<< $msg->task_id($value) >>

Type: C<String>

Unique task id.

=item * C<< $msg->task_type() >> / C<< $msg->task_type($value) >>

Type: C<Enum> (L<Google::Cloud::Osconfig::Agentendpoint::V1::TaskType>)

The type of task to perform.

Task details must include the appropriate message based on this enum as
specified below:
APPLY_PATCHES = ApplyPatchesTask
EXEC_STEP = ExecStepTask
APPLY_CONFIG_TASK = ApplyConfigTask

=item * C<< $msg->task_directive() >> / C<< $msg->task_directive($value) >>

Type: C<Enum> (L<Google::Cloud::Osconfig::Agentendpoint::V1::TaskDirective>)

Current directive to the agent.

=item * C<< $msg->apply_patches_task() >> / C<< $msg->apply_patches_task($value) >>

Type: C<Message> (L<Google::Cloud::Osconfig::Agentendpoint::V1::Tasks::ApplyPatchesTask>)

Details about the apply patches task to perform.

=item * C<< $msg->exec_step_task() >> / C<< $msg->exec_step_task($value) >>

Type: C<Message> (L<Google::Cloud::Osconfig::Agentendpoint::V1::Tasks::ExecStepTask>)

Details about the exec step task to perform.

=item * C<< $msg->apply_config_task() >> / C<< $msg->apply_config_task($value) >>

Type: C<Message> (L<Google::Cloud::Osconfig::Agentendpoint::V1::Tasks::ApplyConfigTask>)

Details about the apply config step task to perform.

=item * C<< $msg->service_labels() >> / C<< $msg->service_labels($value) >>

Type: C<Message> (L<Google::Cloud::Osconfig::Agentendpoint::V1::Tasks::Task::ServiceLabelsEntry>)

Labels describing the task.  Used for logging by the agent.

=back

=head2 Google::Cloud::Osconfig::Agentendpoint::V1::Tasks::ApplyPatchesTask

Message which instructs agent to apply patches.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->patch_config() >> / C<< $msg->patch_config($value) >>

Type: C<Message> (L<Google::Cloud::Osconfig::Agentendpoint::V1::PatchJobs::PatchConfig>)

Specific information about how patches should be applied.

=item * C<< $msg->dry_run() >> / C<< $msg->dry_run($value) >>

Type: C<Bool>

If true, the agent will report its status as it goes through the motions
but won't actually run any updates or perform any reboots.

=back

=head2 Google::Cloud::Osconfig::Agentendpoint::V1::Tasks::ApplyPatchesTaskProgress

Information reported from the agent about applying patches execution.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->state() >> / C<< $msg->state($value) >>

Type: C<Enum> (L<Google::Cloud::Osconfig::Agentendpoint::V1::ApplyPatchesTaskProgress::State>)

Required. The current state of this patch execution.

=back

=head3 Enum: ApplyPatchesTaskProgress::State

=over 4

=item * C<STATE_UNSPECIFIED> => C<0>

=item * C<STARTED> => C<4>

=item * C<DOWNLOADING_PATCHES> => C<1>

=item * C<APPLYING_PATCHES> => C<2>

=item * C<REBOOTING> => C<3>

=back

=head2 Google::Cloud::Osconfig::Agentendpoint::V1::Tasks::ApplyPatchesTaskOutput

Information reported from the agent about applying patches execution.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->state() >> / C<< $msg->state($value) >>

Type: C<Enum> (L<Google::Cloud::Osconfig::Agentendpoint::V1::ApplyPatchesTaskOutput::State>)

Required. The final state of this task.

=back

=head3 Enum: ApplyPatchesTaskOutput::State

=over 4

=item * C<STATE_UNSPECIFIED> => C<0>

=item * C<SUCCEEDED> => C<1>

=item * C<SUCCEEDED_REBOOT_REQUIRED> => C<2>

=item * C<FAILED> => C<3>

=back

=head2 Google::Cloud::Osconfig::Agentendpoint::V1::Tasks::ExecStepTask

Message which instructs agent to execute the following command.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->exec_step() >> / C<< $msg->exec_step($value) >>

Type: C<Message> (L<Google::Cloud::Osconfig::Agentendpoint::V1::PatchJobs::ExecStep>)

Details of the exec step to run.

=back

=head2 Google::Cloud::Osconfig::Agentendpoint::V1::Tasks::ExecStepTaskProgress

Information reported from the agent about the exec step execution.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->state() >> / C<< $msg->state($value) >>

Type: C<Enum> (L<Google::Cloud::Osconfig::Agentendpoint::V1::ExecStepTaskProgress::State>)

Required. The current state of this exec step.

=back

=head3 Enum: ExecStepTaskProgress::State

=over 4

=item * C<STATE_UNSPECIFIED> => C<0>

=item * C<STARTED> => C<1>

=back

=head2 Google::Cloud::Osconfig::Agentendpoint::V1::Tasks::ExecStepTaskOutput

Information reported from the agent about the exec step execution.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->state() >> / C<< $msg->state($value) >>

Type: C<Enum> (L<Google::Cloud::Osconfig::Agentendpoint::V1::ExecStepTaskOutput::State>)

Required. The final state of the exec step.

=item * C<< $msg->exit_code() >> / C<< $msg->exit_code($value) >>

Type: C<Int32>

Required. The exit code received from the script which ran as part of the
exec step.

=back

=head3 Enum: ExecStepTaskOutput::State

=over 4

=item * C<STATE_UNSPECIFIED> => C<0>

=item * C<COMPLETED> => C<1>

=item * C<TIMED_OUT> => C<2>

=item * C<CANCELLED> => C<3>

=back

=head2 Google::Cloud::Osconfig::Agentendpoint::V1::Tasks::ApplyConfigTask

Message which instructs OS Config agent to apply the desired state
configuration.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->os_policies() >> / C<< $msg->os_policies($value) >>

Type: C<Message> (L<Google::Cloud::Osconfig::Agentendpoint::V1::Tasks::ApplyConfigTask::OSPolicy>)

List of os policies to be applied for the instance.

=back

=head2 Google::Cloud::Osconfig::Agentendpoint::V1::Tasks::ApplyConfigTaskProgress

Information reported from the agent regarding the progress of the task of
applying desired state configuration.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->state() >> / C<< $msg->state($value) >>

Type: C<Enum> (L<Google::Cloud::Osconfig::Agentendpoint::V1::ApplyConfigTaskProgress::State>)

The current state of this task.

=back

=head3 Enum: ApplyConfigTaskProgress::State

=over 4

=item * C<STATE_UNSPECIFIED> => C<0>

=item * C<STARTED> => C<1>

=item * C<APPLYING_CONFIG> => C<2>

=back

=head2 Google::Cloud::Osconfig::Agentendpoint::V1::Tasks::ApplyConfigTaskOutput

Information reported from the agent regarding the output of the task of
applying desired state configuration.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->state() >> / C<< $msg->state($value) >>

Type: C<Enum> (L<Google::Cloud::Osconfig::Agentendpoint::V1::ApplyConfigTaskOutput::State>)

Required. The final state of this task.

=item * C<< $msg->os_policy_results() >> / C<< $msg->os_policy_results($value) >>

Type: C<Message> (L<Google::Cloud::Osconfig::Agentendpoint::V1::Tasks::ApplyConfigTaskOutput::OSPolicyResult>)

Results of applying desired state config for the OS policies.

=back

=head3 Enum: ApplyConfigTaskOutput::State

=over 4

=item * C<STATE_UNSPECIFIED> => C<0>

=item * C<SUCCEEDED> => C<1>

=item * C<FAILED> => C<2>

=item * C<CANCELLED> => C<3>

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Osconfig::Agentendpoint::V1::Tasks::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
