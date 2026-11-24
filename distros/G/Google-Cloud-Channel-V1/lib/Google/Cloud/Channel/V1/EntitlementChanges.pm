package Google::Cloud::Channel::V1::EntitlementChanges;

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
    eval { require Google::Cloud::Channel::V1::Entitlements };
    eval { require Google::Protobuf::Timestamp };
    my $descriptor_b64 = <<'EOF';
CjFnb29nbGUvY2xvdWQvY2hhbm5lbC92MS9lbnRpdGxlbWVudF9jaGFuZ2VzLnByb3RvEhdn
b29nbGUuY2xvdWQuY2hhbm5lbC52MRofZ29vZ2xlL2FwaS9maWVsZF9iZWhhdmlvci5wcm90
bxoZZ29vZ2xlL2FwaS9yZXNvdXJjZS5wcm90bxoqZ29vZ2xlL2Nsb3VkL2NoYW5uZWwvdjEv
ZW50aXRsZW1lbnRzLnByb3RvGh9nb29nbGUvcHJvdG9idWYvdGltZXN0YW1wLnByb3RvIu0N
ChFFbnRpdGxlbWVudENoYW5nZRJkChFzdXNwZW5zaW9uX3JlYXNvbhgJIAEoDjI1Lmdvb2ds
ZS5jbG91ZC5jaGFubmVsLnYxLkVudGl0bGVtZW50LlN1c3BlbnNpb25SZWFzb25IAFIQc3Vz
cGVuc2lvblJlYXNvbhJwChNjYW5jZWxsYXRpb25fcmVhc29uGAogASgOMj0uZ29vZ2xlLmNs
b3VkLmNoYW5uZWwudjEuRW50aXRsZW1lbnRDaGFuZ2UuQ2FuY2VsbGF0aW9uUmVhc29uSABS
EmNhbmNlbGxhdGlvblJlYXNvbhJqChFhY3RpdmF0aW9uX3JlYXNvbhgLIAEoDjI7Lmdvb2ds
ZS5jbG91ZC5jaGFubmVsLnYxLkVudGl0bGVtZW50Q2hhbmdlLkFjdGl2YXRpb25SZWFzb25I
AFIQYWN0aXZhdGlvblJlYXNvbhIwChNvdGhlcl9jaGFuZ2VfcmVhc29uGGQgASgJSABSEW90
aGVyQ2hhbmdlUmVhc29uElEKC2VudGl0bGVtZW50GAEgASgJQi/gQQL6QSkKJ2Nsb3VkY2hh
bm5lbC5nb29nbGVhcGlzLmNvbS9FbnRpdGxlbWVudFILZW50aXRsZW1lbnQSPwoFb2ZmZXIY
AiABKAlCKeBBAvpBIwohY2xvdWRjaGFubmVsLmdvb2dsZWFwaXMuY29tL09mZmVyUgVvZmZl
chJcChNwcm92aXNpb25lZF9zZXJ2aWNlGAMgASgLMisuZ29vZ2xlLmNsb3VkLmNoYW5uZWwu
djEuUHJvdmlzaW9uZWRTZXJ2aWNlUhJwcm92aXNpb25lZFNlcnZpY2USVgoLY2hhbmdlX3R5
cGUYBCABKA4yNS5nb29nbGUuY2xvdWQuY2hhbm5lbC52MS5FbnRpdGxlbWVudENoYW5nZS5D
aGFuZ2VUeXBlUgpjaGFuZ2VUeXBlEjsKC2NyZWF0ZV90aW1lGAUgASgLMhouZ29vZ2xlLnBy
b3RvYnVmLlRpbWVzdGFtcFIKY3JlYXRlVGltZRJcCg1vcGVyYXRvcl90eXBlGAYgASgOMjcu
Z29vZ2xlLmNsb3VkLmNoYW5uZWwudjEuRW50aXRsZW1lbnRDaGFuZ2UuT3BlcmF0b3JUeXBl
UgxvcGVyYXRvclR5cGUSQgoKcGFyYW1ldGVycxgIIAMoCzIiLmdvb2dsZS5jbG91ZC5jaGFu
bmVsLnYxLlBhcmFtZXRlclIKcGFyYW1ldGVycxIaCghvcGVyYXRvchgMIAEoCVIIb3BlcmF0
b3Ii1wIKCkNoYW5nZVR5cGUSGwoXQ0hBTkdFX1RZUEVfVU5TUEVDSUZJRUQQABILCgdDUkVB
VEVEEAESFwoTUFJJQ0VfUExBTl9TV0lUQ0hFRBADEhYKEkNPTU1JVE1FTlRfQ0hBTkdFRBAE
EgsKB1JFTkVXRUQQBRINCglTVVNQRU5ERUQQBhINCglBQ1RJVkFURUQQBxINCglDQU5DRUxM
RUQQCBIPCgtTS1VfQ0hBTkdFRBAJEhsKF1JFTkVXQUxfU0VUVElOR19DSEFOR0VEEAoSHQoZ
UEFJRF9TVUJTQ1JJUFRJT05fU1RBUlRFRBALEhcKE0xJQ0VOU0VfQ0FQX0NIQU5HRUQQDBIe
ChpTVVNQRU5TSU9OX0RFVEFJTFNfQ0hBTkdFRBANEhsKF1RSSUFMX0VORF9EQVRFX0VYVEVO
REVEEA4SEQoNVFJJQUxfU1RBUlRFRBAPInoKDE9wZXJhdG9yVHlwZRIdChlPUEVSQVRPUl9U
WVBFX1VOU1BFQ0lGSUVEEAASIwofQ1VTVE9NRVJfU0VSVklDRV9SRVBSRVNFTlRBVElWRRAB
EgoKBlNZU1RFTRACEgwKCENVU1RPTUVSEAMSDAoIUkVTRUxMRVIQBCJ/ChJDYW5jZWxsYXRp
b25SZWFzb24SIwofQ0FOQ0VMTEFUSU9OX1JFQVNPTl9VTlNQRUNJRklFRBAAEhYKElNFUlZJ
Q0VfVEVSTUlOQVRFRBABEhYKElJFTEFUSU9OU0hJUF9FTkRFRBACEhQKEFBBUlRJQUxfVFJB
TlNGRVIQAyK0AQoQQWN0aXZhdGlvblJlYXNvbhIhCh1BQ1RJVkFUSU9OX1JFQVNPTl9VTlNQ
RUNJRklFRBAAEh8KG1JFU0VMTEVSX1JFVk9LRURfU1VTUEVOU0lPThABEiEKHUNVU1RPTUVS
X0FDQ0VQVEVEX1BFTkRJTkdfVE9TEAISHAoYUkVORVdBTF9TRVRUSU5HU19DSEFOR0VEEAMS
GwoXT1RIRVJfQUNUSVZBVElPTl9SRUFTT04QZEIPCg1jaGFuZ2VfcmVhc29uQm8KG2NvbS5n
b29nbGUuY2xvdWQuY2hhbm5lbC52MUIXRW50aXRsZW1lbnRDaGFuZ2VzUHJvdG9QAVo1Y2xv
dWQuZ29vZ2xlLmNvbS9nby9jaGFubmVsL2FwaXYxL2NoYW5uZWxwYjtjaGFubmVscGJKwS0K
BxIFDgDAAQEKvAQKAQwSAw4AEjKxBCBDb3B5cmlnaHQgMjAyNSBHb29nbGUgTExDCgogTGlj
ZW5zZWQgdW5kZXIgdGhlIEFwYWNoZSBMaWNlbnNlLCBWZXJzaW9uIDIuMCAodGhlICJMaWNl
bnNlIik7CiB5b3UgbWF5IG5vdCB1c2UgdGhpcyBmaWxlIGV4Y2VwdCBpbiBjb21wbGlhbmNl
IHdpdGggdGhlIExpY2Vuc2UuCiBZb3UgbWF5IG9idGFpbiBhIGNvcHkgb2YgdGhlIExpY2Vu
c2UgYXQKCiAgICAgaHR0cDovL3d3dy5hcGFjaGUub3JnL2xpY2Vuc2VzL0xJQ0VOU0UtMi4w
CgogVW5sZXNzIHJlcXVpcmVkIGJ5IGFwcGxpY2FibGUgbGF3IG9yIGFncmVlZCB0byBpbiB3
cml0aW5nLCBzb2Z0d2FyZQogZGlzdHJpYnV0ZWQgdW5kZXIgdGhlIExpY2Vuc2UgaXMgZGlz
dHJpYnV0ZWQgb24gYW4gIkFTIElTIiBCQVNJUywKIFdJVEhPVVQgV0FSUkFOVElFUyBPUiBD
T05ESVRJT05TIE9GIEFOWSBLSU5ELCBlaXRoZXIgZXhwcmVzcyBvciBpbXBsaWVkLgogU2Vl
IHRoZSBMaWNlbnNlIGZvciB0aGUgc3BlY2lmaWMgbGFuZ3VhZ2UgZ292ZXJuaW5nIHBlcm1p
c3Npb25zIGFuZAogbGltaXRhdGlvbnMgdW5kZXIgdGhlIExpY2Vuc2UuCgoICgECEgMQACAK
CQoCAwASAxIAKQoJCgIDARIDEwAjCgkKAgMCEgMUADQKCQoCAwMSAxUAKQoICgEIEgMXAEwK
CQoCCAsSAxcATAoICgEIEgMYACIKCQoCCAoSAxgAIgoICgEIEgMZADgKCQoCCAgSAxkAOAoI
CgEIEgMaADQKCQoCCAESAxoANAo/CgIEABIFHQDAAQEaMiBDaGFuZ2UgZXZlbnQgZW50cnkg
Zm9yIEVudGl0bGVtZW50IG9yZGVyIGhpc3RvcnkKCgoKAwQAARIDHQgZCjMKBAQABAASBB8C
TwMaJSBTcGVjaWZpZXMgdGhlIHR5cGUgb2YgY2hhbmdlIGFjdGlvbgoKDAoFBAAEAAESAx8H
EQoaCgYEAAQAAgASAyEEIBoLIE5vdCB1c2VkLgoKDgoHBAAEAAIAARIDIQQbCg4KBwQABAAC
AAISAyEeHwotCgYEAAQAAgESAyQEEBoeIE5ldyBFbnRpdGxlbWVudCB3YXMgY3JlYXRlZC4K
Cg4KBwQABAACAQESAyQECwoOCgcEAAQAAgECEgMkDg8KRwoGBAAEAAICEgMnBBwaOCBQcmlj
ZSBwbGFuIGFzc29jaWF0ZWQgd2l0aCBhbiBFbnRpdGxlbWVudCB3YXMgY2hhbmdlZC4KCg4K
BwQABAACAgESAycEFwoOCgcEAAQAAgICEgMnGhsKVAoGBAAEAAIDEgMqBBsaRSBOdW1iZXIg
b2Ygc2VhdHMgY29tbWl0dGVkIGZvciBhIGNvbW1pdG1lbnQgRW50aXRsZW1lbnQgd2FzIGNo
YW5nZWQuCgoOCgcEAAQAAgMBEgMqBBYKDgoHBAAEAAIDAhIDKhkaCjMKBgQABAACBBIDLQQQ
GiQgQW4gYW5udWFsIEVudGl0bGVtZW50IHdhcyByZW5ld2VkLgoKDgoHBAAEAAIEARIDLQQL
Cg4KBwQABAACBAISAy0ODworCgYEAAQAAgUSAzAEEhocIEVudGl0bGVtZW50IHdhcyBzdXNw
ZW5kZWQuCgoOCgcEAAQAAgUBEgMwBA0KDgoHBAAEAAIFAhIDMBARCisKBgQABAACBhIDMwQS
GhwgRW50aXRsZW1lbnQgd2FzIGFjdGl2YXRlZC4KCg4KBwQABAACBgESAzMEDQoOCgcEAAQA
AgYCEgMzEBEKKwoGBAAEAAIHEgM2BBIaHCBFbnRpdGxlbWVudCB3YXMgY2FuY2VsbGVkLgoK
DgoHBAAEAAIHARIDNgQNCg4KBwQABAACBwISAzYQEQqLAQoGBAAEAAIIEgM6BBQafCBFbnRp
dGxlbWVudCB3YXMgdXBncmFkZWQgb3IgZG93bmdyYWRlZCBmb3IgZXguIGZyb20gR29vZ2xl
IFdvcmtzcGFjZQogQnVzaW5lc3MgU3RhbmRhcmQgdG8gR29vZ2xlIFdvcmtzcGFjZSBCdXNp
bmVzcyBQbHVzLgoKDgoHBAAEAAIIARIDOgQPCg4KBwQABAACCAISAzoSEwpJCgYEAAQAAgkS
Az0EIRo6IFRoZSBzZXR0aW5ncyBmb3IgcmVuZXdhbCBvZiBhbiBFbnRpdGxlbWVudCBoYXZl
IGNoYW5nZWQuCgoOCgcEAAQAAgkBEgM9BBsKDgoHBAAEAAIJAhIDPR4gCp4BCgYEAAQAAgoS
A0IEIxqOASBVc2UgZm9yIEdvb2dsZSBXb3Jrc3BhY2Ugc3Vic2NyaXB0aW9uLgogRWl0aGVy
IGEgdHJpYWwgd2FzIGNvbnZlcnRlZCB0byBhIHBhaWQgc3Vic2NyaXB0aW9uIG9yIGEgbmV3
IHN1YnNjcmlwdGlvbgogd2l0aCBubyB0cmlhbCBpcyBjcmVhdGVkLgoKDgoHBAAEAAIKARID
QgQdCg4KBwQABAACCgISA0IgIgo9CgYEAAQAAgsSA0UEHRouIExpY2Vuc2UgY2FwIHdhcyBj
aGFuZ2VkIGZvciB0aGUgZW50aXRsZW1lbnQuCgoOCgcEAAQAAgsBEgNFBBcKDgoHBAAEAAIL
AhIDRRocClEKBgQABAACDBIDSAQkGkIgVGhlIHN1c3BlbnNpb24gZGV0YWlscyBoYXZlIGNo
YW5nZWQgKGJ1dCBpdCBpcyBzdGlsbCBzdXNwZW5kZWQpLgoKDgoHBAAEAAIMARIDSAQeCg4K
BwQABAACDAISA0ghIwoxCgYEAAQAAg0SA0sEIRoiIFRoZSB0cmlhbCBlbmQgZGF0ZSB3YXMg
ZXh0ZW5kZWQuCgoOCgcEAAQAAg0BEgNLBBsKDgoHBAAEAAINAhIDSx4gCisKBgQABAACDhID
TgQXGhwgRW50aXRsZW1lbnQgc3RhcnRlZCB0cmlhbC4KCg4KBwQABAACDgESA04EEQoOCgcE
AAQAAg4CEgNOFBYKSQoEBAAEARIEUgJhAxo7IFNwZWNpZmllcyB0aGUgdHlwZSBvZiBvcGVy
YXRvciByZXNwb25zaWJsZSBmb3IgdGhlIGNoYW5nZQoKDAoFBAAEAQESA1IHEwoaCgYEAAQB
AgASA1QEIhoLIE5vdCB1c2VkLgoKDgoHBAAEAQIAARIDVAQdCg4KBwQABAECAAISA1QgIQox
CgYEAAQBAgESA1cEKBoiIEN1c3RvbWVyIHNlcnZpY2UgcmVwcmVzZW50YXRpdmUuCgoOCgcE
AAQBAgEBEgNXBCMKDgoHBAAEAQIBAhIDVyYnCiEKBgQABAECAhIDWgQPGhIgU3lzdGVtIGF1
dG8gam9iLgoKDgoHBAAEAQICARIDWgQKCg4KBwQABAECAgISA1oNDgofCgYEAAQBAgMSA10E
ERoQIEN1c3RvbWVyIHVzZXIuCgoOCgcEAAQBAgMBEgNdBAwKDgoHBAAEAQIDAhIDXQ8QCh8K
BgQABAECBBIDYAQRGhAgUmVzZWxsZXIgdXNlci4KCg4KBwQABAECBAESA2AEDAoOCgcEAAQB
AgQCEgNgDxAKNwoEBAAEAhIEZAJyAxopIENhbmNlbGxhdGlvbiByZWFzb24gZm9yIHRoZSBl
bnRpdGxlbWVudAoKDAoFBAAEAgESA2QHGQoaCgYEAAQCAgASA2YEKBoLIE5vdCB1c2VkLgoK
DgoHBAAEAgIAARIDZgQjCg4KBwQABAICAAISA2YmJwpCCgYEAAQCAgESA2kEGxozIFJlc2Vs
bGVyIHRyaWdnZXJlZCBhIGNhbmNlbGxhdGlvbiBvZiB0aGUgc2VydmljZS4KCg4KBwQABAIC
AQESA2kEFgoOCgcEAAQCAgECEgNpGRoKXQoGBAAEAgICEgNtBBsaTiBSZWxhdGlvbnNoaXAg
YmV0d2VlbiB0aGUgcmVzZWxsZXIgYW5kIGN1c3RvbWVyIGhhcyBlbmRlZCBkdWUgdG8gYQog
dHJhbnNmZXIuCgoOCgcEAAQCAgIBEgNtBBYKDgoHBAAEAgICAhIDbRkaCngKBgQABAICAxID
cQQZGmkgRW50aXRsZW1lbnQgdHJhbnNmZXJyZWQgYXdheSBmcm9tIHJlc2VsbGVyIHdoaWxl
IHN0aWxsIGtlZXBpbmcgb3RoZXIKIGVudGl0bGVtZW50KHMpIHdpdGggdGhlIHJlc2VsbGVy
LgoKDgoHBAAEAgIDARIDcQQUCg4KBwQABAICAwISA3EXGAo0CgQEAAQDEgV1AocBAxolIFRo
ZSBFbnRpdGxlbWVudCdzIGFjdGl2YXRpb24gcmVhc29uCgoMCgUEAAQDARIDdQcXChoKBgQA
BAMCABIDdwQmGgsgTm90IHVzZWQuCgoOCgcEAAQDAgABEgN3BCEKDgoHBAAEAwIAAhIDdyQl
Cj4KBgQABAMCARIDegQkGi8gUmVzZWxsZXIgcmVhY3RpdmF0ZWQgYSBzdXNwZW5kZWQgRW50
aXRsZW1lbnQuCgoOCgcEAAQDAgEBEgN6BB8KDgoHBAAEAwIBAhIDeiIjCjwKBgQABAMCAhID
fQQmGi0gQ3VzdG9tZXIgYWNjZXB0ZWQgcGVuZGluZyB0ZXJtcyBvZiBzZXJ2aWNlLgoKDgoH
BAAEAwICARIDfQQhCg4KBwQABAMCAgISA30kJQqhAQoGBAAEAwIDEgSCAQQhGpABIFJlc2Vs
bGVyIHVwZGF0ZWQgdGhlIHJlbmV3YWwgc2V0dGluZ3Mgb24gYW4gZW50aXRsZW1lbnQgdGhh
dCB3YXMKIHN1c3BlbmRlZCBkdWUgdG8gY2FuY2VsbGF0aW9uLCBhbmQgdGhpcyB1cGRhdGUg
cmVhY3RpdmF0ZWQgdGhlCiBlbnRpdGxlbWVudC4KCg8KBwQABAMCAwESBIIBBBwKDwoHBAAE
AwIDAhIEggEfIAp8CgYEAAQDAgQSBIYBBCIabCBPdGhlciByZWFzb25zIChBY3RpdmF0ZWQg
dGVtcG9yYXJpbHkgZm9yIGNhbmNlbGxhdGlvbiwgYWRkZWQgYSBwYXltZW50CiBwbGFuIHRv
IGEgdHJpYWwgZW50aXRsZW1lbnQsIGV0Yy4pCgoPCgcEAAQDAgQBEgSGAQQbCg8KBwQABAMC
BAISBIYBHiEKMAoEBAAIABIGigEClgEDGiAgVGhlIHJlYXNvbiB0aGUgY2hhbmdlIHdhcyBt
YWRlCgoNCgUEAAgAARIEigEIFQo2CgQEAAIAEgSMAQQ3GiggU3VzcGVuc2lvbiByZWFzb24g
Zm9yIHRoZSBFbnRpdGxlbWVudC4KCg0KBQQAAgAGEgSMAQQgCg0KBQQAAgABEgSMASEyCg0K
BQQAAgADEgSMATU2CjgKBAQAAgESBI8BBDAaKiBDYW5jZWxsYXRpb24gcmVhc29uIGZvciB0
aGUgRW50aXRsZW1lbnQuCgoNCgUEAAIBBhIEjwEEFgoNCgUEAAIBARIEjwEXKgoNCgUEAAIB
AxIEjwEtLwozCgQEAAICEgSSAQQsGiUgVGhlIEVudGl0bGVtZW50J3MgYWN0aXZhdGlvbiBy
ZWFzb24KCg0KBQQAAgIGEgSSAQQUCg0KBQQAAgIBEgSSARUmCg0KBQQAAgIDEgSSASkrCkMK
BAQAAgMSBJUBBCUaNSBlLmcuIHB1cmNoYXNlX251bWJlciBjaGFuZ2UgcmVhc29uLCBlbnRl
cmVkIGJ5IENSUy4KCg0KBQQAAgMFEgSVAQQKCg0KBQQAAgMBEgSVAQseCg0KBQQAAgMDEgSV
ASEkCpYBCgQEAAIEEgaaAQKfAQQahQEgUmVxdWlyZWQuIFJlc291cmNlIG5hbWUgb2YgYW4g
ZW50aXRsZW1lbnQgaW4gdGhlIGZvcm06CiBhY2NvdW50cy97YWNjb3VudF9pZH0vY3VzdG9t
ZXJzL3tjdXN0b21lcl9pZH0vZW50aXRsZW1lbnRzL3tlbnRpdGxlbWVudF9pZH0KCg0KBQQA
AgQFEgSaAQIICg0KBQQAAgQBEgSaAQkUCg0KBQQAAgQDEgSaARcYCg8KBQQAAgQIEgaaARmf
AQMKEAoIBAACBAicCAASBJsBBCoKEQoHBAACBAifCBIGnAEEngEFCocBCgQEAAIFEgajAQKo
AQQadyBSZXF1aXJlZC4gUmVzb3VyY2UgbmFtZSBvZiB0aGUgT2ZmZXIgYXQgdGhlIHRpbWUg
b2YgY2hhbmdlLgogVGFrZXMgdGhlIGZvcm06IGFjY291bnRzL3thY2NvdW50X2lkfS9vZmZl
cnMve29mZmVyX2lkfS4KCg0KBQQAAgUFEgSjAQIICg0KBQQAAgUBEgSjAQkOCg0KBQQAAgUD
EgSjARESCg8KBQQAAgUIEgajAROoAQMKEAoIBAACBQicCAASBKQBBCoKEQoHBAACBQifCBIG
pQEEpwEFCjcKBAQAAgYSBKsBAi0aKSBTZXJ2aWNlIHByb3Zpc2lvbmVkIGZvciBhbiBFbnRp
dGxlbWVudC4KCg0KBQQAAgYGEgSrAQIUCg0KBQQAAgYBEgSrARUoCg0KBQQAAgYDEgSrASss
CicKBAQAAgcSBK4BAh0aGSBUaGUgY2hhbmdlIGFjdGlvbiB0eXBlLgoKDQoFBAACBwYSBK4B
AgwKDQoFBAACBwESBK4BDRgKDQoFBAACBwMSBK4BGxwKMQoEBAACCBIEsQECLBojIFRoZSBz
dWJtaXR0ZWQgdGltZSBvZiB0aGUgY2hhbmdlLgoKDQoFBAACCAYSBLEBAhsKDQoFBAACCAES
BLEBHCcKDQoFBAACCAMSBLEBKisKOQoEBAACCRIEtAECIRorIE9wZXJhdG9yIHR5cGUgcmVz
cG9uc2libGUgZm9yIHRoZSBjaGFuZ2UuCgoNCgUEAAIJBhIEtAECDgoNCgUEAAIJARIEtAEP
HAoNCgUEAAIJAxIEtAEfIAqYAQoEBAACChIEugECJBqJASBFeHRlbmRlZCBwYXJhbWV0ZXJz
LCBzdWNoIGFzOgogcHVyY2hhc2Vfb3JkZXJfbnVtYmVyLCBnY3BfZGV0YWlsczsKIGludGVy
bmFsX2NvcnJlbGF0aW9uX2lkLCBsb25nX3J1bm5pbmdfb3BlcmF0aW9uX2lkLCBvcmRlcl9p
ZDsKIGV0Yy4KCg0KBQQAAgoEEgS6AQIKCg0KBQQAAgoGEgS6AQsUCg0KBQQAAgoBEgS6ARUf
Cg0KBQQAAgoDEgS6ASIjCscBCgQEAAILEgS/AQIXGrgBIEh1bWFuLXJlYWRhYmxlIGlkZW50
aWZpZXIgdGhhdCBzaG93cyB3aGF0IG9wZXJhdG9yIG1hZGUgYSBjaGFuZ2UuCiBXaGVuIHRo
ZSBvcGVyYXRvcl90eXBlIGlzIFJFU0VMTEVSLCB0aGlzIGlzIHRoZSB1c2VyJ3MgZW1haWwg
YWRkcmVzcy4KIEZvciBhbGwgb3RoZXIgb3BlcmF0b3IgdHlwZXMsIHRoaXMgaXMgZW1wdHku
CgoNCgUEAAILBRIEvwECCAoNCgUEAAILARIEvwEJEQoNCgUEAAILAxIEvwEUFmIGcHJvdG8z

EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Channel::V1::EntitlementChanges::EntitlementChange ===
    # Fields for EntitlementChange
    # Field: suspension_reason Type: 14 (.google.cloud.channel.v1.Entitlement.SuspensionReason)
    # Field: cancellation_reason Type: 14 (.google.cloud.channel.v1.EntitlementChange.CancellationReason)
    # Field: activation_reason Type: 14 (.google.cloud.channel.v1.EntitlementChange.ActivationReason)
    # Field: other_change_reason Type: 9 ()
    # Field: entitlement Type: 9 ()
    # Field: offer Type: 9 ()
    # Field: provisioned_service Type: 11 (.google.cloud.channel.v1.ProvisionedService)
    # Field: change_type Type: 14 (.google.cloud.channel.v1.EntitlementChange.ChangeType)
    # Field: create_time Type: 11 (.google.protobuf.Timestamp)
    # Field: operator_type Type: 14 (.google.cloud.channel.v1.EntitlementChange.OperatorType)
    # Field: parameters Type: 11 (.google.cloud.channel.v1.Parameter)
    # Field: operator Type: 9 ()

# Enum: EntitlementChange::ChangeType
our $EntitlementChange_CHANGE_TYPE_UNSPECIFIED = 0;
our $EntitlementChange_CREATED = 1;
our $EntitlementChange_PRICE_PLAN_SWITCHED = 3;
our $EntitlementChange_COMMITMENT_CHANGED = 4;
our $EntitlementChange_RENEWED = 5;
our $EntitlementChange_SUSPENDED = 6;
our $EntitlementChange_ACTIVATED = 7;
our $EntitlementChange_CANCELLED = 8;
our $EntitlementChange_SKU_CHANGED = 9;
our $EntitlementChange_RENEWAL_SETTING_CHANGED = 10;
our $EntitlementChange_PAID_SUBSCRIPTION_STARTED = 11;
our $EntitlementChange_LICENSE_CAP_CHANGED = 12;
our $EntitlementChange_SUSPENSION_DETAILS_CHANGED = 13;
our $EntitlementChange_TRIAL_END_DATE_EXTENDED = 14;
our $EntitlementChange_TRIAL_STARTED = 15;

# Enum: EntitlementChange::OperatorType
our $EntitlementChange_OPERATOR_TYPE_UNSPECIFIED = 0;
our $EntitlementChange_CUSTOMER_SERVICE_REPRESENTATIVE = 1;
our $EntitlementChange_SYSTEM = 2;
our $EntitlementChange_CUSTOMER = 3;
our $EntitlementChange_RESELLER = 4;

# Enum: EntitlementChange::CancellationReason
our $EntitlementChange_CANCELLATION_REASON_UNSPECIFIED = 0;
our $EntitlementChange_SERVICE_TERMINATED = 1;
our $EntitlementChange_RELATIONSHIP_ENDED = 2;
our $EntitlementChange_PARTIAL_TRANSFER = 3;

# Enum: EntitlementChange::ActivationReason
our $EntitlementChange_ACTIVATION_REASON_UNSPECIFIED = 0;
our $EntitlementChange_RESELLER_REVOKED_SUSPENSION = 1;
our $EntitlementChange_CUSTOMER_ACCEPTED_PENDING_TOS = 2;
our $EntitlementChange_RENEWAL_SETTINGS_CHANGED = 3;
our $EntitlementChange_OTHER_ACTIVATION_REASON = 100;

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Channel::V1::EntitlementChanges - Compiled Protocol Buffers messages for google/cloud/channel/v1/entitlement_changes.proto

=head1 SYNOPSIS

    use Google::Cloud::Channel::V1::EntitlementChanges;

    my $msg = Google::Cloud::Channel::V1::EntitlementChanges::EntitlementChange->new({
        suspension_reason => $suspension_reason,
        cancellation_reason => $cancellation_reason,
        activation_reason => $activation_reason,
        other_change_reason => $other_change_reason,
    });

    # Read or update a field
    my $val = $msg->suspension_reason();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Channel::V1::EntitlementChanges::EntitlementChange->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/channel/v1/entitlement_changes.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Channel::V1::EntitlementChanges::EntitlementChange

Change event entry for Entitlement order history

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->suspension_reason() >> / C<< $msg->suspension_reason($value) >>

Type: C<Enum> (L<Google::Cloud::Channel::V1::Entitlement::SuspensionReason>)

Suspension reason for the Entitlement.

=item * C<< $msg->cancellation_reason() >> / C<< $msg->cancellation_reason($value) >>

Type: C<Enum> (L<Google::Cloud::Channel::V1::EntitlementChange::CancellationReason>)

Cancellation reason for the Entitlement.

=item * C<< $msg->activation_reason() >> / C<< $msg->activation_reason($value) >>

Type: C<Enum> (L<Google::Cloud::Channel::V1::EntitlementChange::ActivationReason>)

The Entitlement's activation reason

=item * C<< $msg->other_change_reason() >> / C<< $msg->other_change_reason($value) >>

Type: C<String>

e.g. purchase_number change reason, entered by CRS.

=item * C<< $msg->entitlement() >> / C<< $msg->entitlement($value) >>

Type: C<String>

Required. Resource name of an entitlement in the form:
accounts/{account_id}/customers/{customer_id}/entitlements/{entitlement_id}

=item * C<< $msg->offer() >> / C<< $msg->offer($value) >>

Type: C<String>

Required. Resource name of the Offer at the time of change.
Takes the form: accounts/{account_id}/offers/{offer_id}.

=item * C<< $msg->provisioned_service() >> / C<< $msg->provisioned_service($value) >>

Type: C<Message> (L<Google::Cloud::Channel::V1::Entitlements::ProvisionedService>)

Service provisioned for an Entitlement.

=item * C<< $msg->change_type() >> / C<< $msg->change_type($value) >>

Type: C<Enum> (L<Google::Cloud::Channel::V1::EntitlementChange::ChangeType>)

The change action type.

=item * C<< $msg->create_time() >> / C<< $msg->create_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

The submitted time of the change.

=item * C<< $msg->operator_type() >> / C<< $msg->operator_type($value) >>

Type: C<Enum> (L<Google::Cloud::Channel::V1::EntitlementChange::OperatorType>)

Operator type responsible for the change.

=item * C<< $msg->parameters() >> / C<< $msg->parameters($value) >>

Type: C<Message> (L<Google::Cloud::Channel::V1::Entitlements::Parameter>)

Extended parameters, such as:
purchase_order_number, gcp_details;
internal_correlation_id, long_running_operation_id, order_id;
etc.

=item * C<< $msg->operator() >> / C<< $msg->operator($value) >>

Type: C<String>

Human-readable identifier that shows what operator made a change.
When the operator_type is RESELLER, this is the user's email address.
For all other operator types, this is empty.

=back

=head3 Enum: EntitlementChange::ChangeType

=over 4

=item * C<CHANGE_TYPE_UNSPECIFIED> => C<0>

=item * C<CREATED> => C<1>

=item * C<PRICE_PLAN_SWITCHED> => C<3>

=item * C<COMMITMENT_CHANGED> => C<4>

=item * C<RENEWED> => C<5>

=item * C<SUSPENDED> => C<6>

=item * C<ACTIVATED> => C<7>

=item * C<CANCELLED> => C<8>

=item * C<SKU_CHANGED> => C<9>

=item * C<RENEWAL_SETTING_CHANGED> => C<10>

=item * C<PAID_SUBSCRIPTION_STARTED> => C<11>

=item * C<LICENSE_CAP_CHANGED> => C<12>

=item * C<SUSPENSION_DETAILS_CHANGED> => C<13>

=item * C<TRIAL_END_DATE_EXTENDED> => C<14>

=item * C<TRIAL_STARTED> => C<15>

=back

=head3 Enum: EntitlementChange::OperatorType

=over 4

=item * C<OPERATOR_TYPE_UNSPECIFIED> => C<0>

=item * C<CUSTOMER_SERVICE_REPRESENTATIVE> => C<1>

=item * C<SYSTEM> => C<2>

=item * C<CUSTOMER> => C<3>

=item * C<RESELLER> => C<4>

=back

=head3 Enum: EntitlementChange::CancellationReason

=over 4

=item * C<CANCELLATION_REASON_UNSPECIFIED> => C<0>

=item * C<SERVICE_TERMINATED> => C<1>

=item * C<RELATIONSHIP_ENDED> => C<2>

=item * C<PARTIAL_TRANSFER> => C<3>

=back

=head3 Enum: EntitlementChange::ActivationReason

=over 4

=item * C<ACTIVATION_REASON_UNSPECIFIED> => C<0>

=item * C<RESELLER_REVOKED_SUSPENSION> => C<1>

=item * C<CUSTOMER_ACCEPTED_PENDING_TOS> => C<2>

=item * C<RENEWAL_SETTINGS_CHANGED> => C<3>

=item * C<OTHER_ACTIVATION_REASON> => C<100>

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Channel::V1::EntitlementChanges::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
