package Google::Cloud::Lustre::V1::Transfer;

use strict;
use warnings;

our $VERSION = '0.14';

use Protobuf::Message;
use Protobuf::DescriptorPool;
use Protobuf::Internal qw(:all);
use MIME::Base64;

BEGIN {
    eval { require Google::Api::FieldBehavior };
    eval { require Google::Api::FieldInfo };
    eval { require Google::Api::Resource };
    eval { require Google::Protobuf::Timestamp };
    eval { require Google::Rpc::Code };
    my $descriptor_b64 = <<'EOF';
CiVnb29nbGUvY2xvdWQvbHVzdHJlL3YxL3RyYW5zZmVyLnByb3RvEhZnb29nbGUuY2xvdWQu
bHVzdHJlLnYxGh9nb29nbGUvYXBpL2ZpZWxkX2JlaGF2aW9yLnByb3RvGhtnb29nbGUvYXBp
L2ZpZWxkX2luZm8ucHJvdG8aGWdvb2dsZS9hcGkvcmVzb3VyY2UucHJvdG8aH2dvb2dsZS9w
cm90b2J1Zi90aW1lc3RhbXAucHJvdG8aFWdvb2dsZS9ycGMvY29kZS5wcm90byLtAgoRSW1w
b3J0RGF0YVJlcXVlc3QSPAoIZ2NzX3BhdGgYAiABKAsyHy5nb29nbGUuY2xvdWQubHVzdHJl
LnYxLkdjc1BhdGhIAFIHZ2NzUGF0aBJFCgtsdXN0cmVfcGF0aBgDIAEoCzIiLmdvb2dsZS5j
bG91ZC5sdXN0cmUudjEuTHVzdHJlUGF0aEgBUgpsdXN0cmVQYXRoEjoKBG5hbWUYASABKAlC
JuBBAvpBIAoebHVzdHJlLmdvb2dsZWFwaXMuY29tL0luc3RhbmNlUgRuYW1lEioKCnJlcXVl
c3RfaWQYBCABKAlCC+KMz9cIAggB4EEBUglyZXF1ZXN0SWQSUgoPc2VydmljZV9hY2NvdW50
GAUgASgJQingQQH6QSMKIWlhbS5nb29nbGVhcGlzLmNvbS9TZXJ2aWNlQWNjb3VudFIOc2Vy
dmljZUFjY291bnRCCAoGc291cmNlQg0KC2Rlc3RpbmF0aW9uIu0CChFFeHBvcnREYXRhUmVx
dWVzdBJFCgtsdXN0cmVfcGF0aBgCIAEoCzIiLmdvb2dsZS5jbG91ZC5sdXN0cmUudjEuTHVz
dHJlUGF0aEgAUgpsdXN0cmVQYXRoEjwKCGdjc19wYXRoGAMgASgLMh8uZ29vZ2xlLmNsb3Vk
Lmx1c3RyZS52MS5HY3NQYXRoSAFSB2djc1BhdGgSOgoEbmFtZRgBIAEoCUIm4EEC+kEgCh5s
dXN0cmUuZ29vZ2xlYXBpcy5jb20vSW5zdGFuY2VSBG5hbWUSKgoKcmVxdWVzdF9pZBgEIAEo
CUIL4ozP1wgCCAHgQQFSCXJlcXVlc3RJZBJSCg9zZXJ2aWNlX2FjY291bnQYBSABKAlCKeBB
AfpBIwohaWFtLmdvb2dsZWFwaXMuY29tL1NlcnZpY2VBY2NvdW50Ug5zZXJ2aWNlQWNjb3Vu
dEIICgZzb3VyY2VCDQoLZGVzdGluYXRpb24iFAoSRXhwb3J0RGF0YVJlc3BvbnNlIhQKEklt
cG9ydERhdGFSZXNwb25zZSK4AwoSRXhwb3J0RGF0YU1ldGFkYXRhEmAKEm9wZXJhdGlvbl9t
ZXRhZGF0YRgBIAEoCzIxLmdvb2dsZS5jbG91ZC5sdXN0cmUudjEuVHJhbnNmZXJPcGVyYXRp
b25NZXRhZGF0YVIRb3BlcmF0aW9uTWV0YWRhdGESQAoLY3JlYXRlX3RpbWUYAiABKAsyGi5n
b29nbGUucHJvdG9idWYuVGltZXN0YW1wQgPgQQNSCmNyZWF0ZVRpbWUSOgoIZW5kX3RpbWUY
AyABKAsyGi5nb29nbGUucHJvdG9idWYuVGltZXN0YW1wQgPgQQNSB2VuZFRpbWUSGwoGdGFy
Z2V0GAQgASgJQgPgQQNSBnRhcmdldBIXCgR2ZXJiGAUgASgJQgPgQQNSBHZlcmISKgoOc3Rh
dHVzX21lc3NhZ2UYBiABKAlCA+BBA1INc3RhdHVzTWVzc2FnZRI6ChZyZXF1ZXN0ZWRfY2Fu
Y2VsbGF0aW9uGAcgASgIQgPgQQNSFXJlcXVlc3RlZENhbmNlbGxhdGlvbhIkCgthcGlfdmVy
c2lvbhgIIAEoCUID4EEDUgphcGlWZXJzaW9uIp8DChJJbXBvcnREYXRhTWV0YWRhdGESYAoS
b3BlcmF0aW9uX21ldGFkYXRhGAEgASgLMjEuZ29vZ2xlLmNsb3VkLmx1c3RyZS52MS5UcmFu
c2Zlck9wZXJhdGlvbk1ldGFkYXRhUhFvcGVyYXRpb25NZXRhZGF0YRJACgtjcmVhdGVfdGlt
ZRgCIAEoCzIaLmdvb2dsZS5wcm90b2J1Zi5UaW1lc3RhbXBCA+BBA1IKY3JlYXRlVGltZRI6
CghlbmRfdGltZRgDIAEoCzIaLmdvb2dsZS5wcm90b2J1Zi5UaW1lc3RhbXBCA+BBA1IHZW5k
VGltZRIbCgZ0YXJnZXQYBCABKAlCA+BBA1IGdGFyZ2V0EioKDnN0YXR1c19tZXNzYWdlGAYg
ASgJQgPgQQNSDXN0YXR1c01lc3NhZ2USOgoWcmVxdWVzdGVkX2NhbmNlbGxhdGlvbhgHIAEo
CEID4EEDUhVyZXF1ZXN0ZWRDYW5jZWxsYXRpb24SJAoLYXBpX3ZlcnNpb24YCCABKAlCA+BB
A1IKYXBpVmVyc2lvbiIgCgdHY3NQYXRoEhUKA3VyaRgBIAEoCUID4EECUgN1cmkiJQoKTHVz
dHJlUGF0aBIXCgRwYXRoGAEgASgJQgPgQQFSBHBhdGginAMKEFRyYW5zZmVyQ291bnRlcnMS
LgoTZm91bmRfb2JqZWN0c19jb3VudBgBIAEoA1IRZm91bmRPYmplY3RzQ291bnQSKgoRYnl0
ZXNfZm91bmRfY291bnQYAiABKANSD2J5dGVzRm91bmRDb3VudBIyChVvYmplY3RzX3NraXBw
ZWRfY291bnQYAyABKANSE29iamVjdHNTa2lwcGVkQ291bnQSLgoTYnl0ZXNfc2tpcHBlZF9j
b3VudBgEIAEoA1IRYnl0ZXNTa2lwcGVkQ291bnQSMAoUb2JqZWN0c19jb3BpZWRfY291bnQY
BSABKANSEm9iamVjdHNDb3BpZWRDb3VudBIsChJieXRlc19jb3BpZWRfY291bnQYBiABKANS
EGJ5dGVzQ29waWVkQ291bnQSNQoUb2JqZWN0c19mYWlsZWRfY291bnQYByABKANCA+BBA1IS
b2JqZWN0c0ZhaWxlZENvdW50EjEKEmJ5dGVzX2ZhaWxlZF9jb3VudBgIIAEoA0ID4EEDUhBi
eXRlc0ZhaWxlZENvdW50IksKDUVycm9yTG9nRW50cnkSFQoDdXJpGAEgASgJQgPgQQJSA3Vy
aRIjCg1lcnJvcl9kZXRhaWxzGAIgAygJUgxlcnJvckRldGFpbHMivQEKDEVycm9yU3VtbWFy
eRI0CgplcnJvcl9jb2RlGAEgASgOMhAuZ29vZ2xlLnJwYy5Db2RlQgPgQQJSCWVycm9yQ29k
ZRIkCgtlcnJvcl9jb3VudBgCIAEoA0ID4EECUgplcnJvckNvdW50ElEKEWVycm9yX2xvZ19l
bnRyaWVzGAMgAygLMiUuZ29vZ2xlLmNsb3VkLmx1c3RyZS52MS5FcnJvckxvZ0VudHJ5Ug9l
cnJvckxvZ0VudHJpZXMiiQUKGVRyYW5zZmVyT3BlcmF0aW9uTWV0YWRhdGESVwoSc291cmNl
X2x1c3RyZV9wYXRoGAMgASgLMiIuZ29vZ2xlLmNsb3VkLmx1c3RyZS52MS5MdXN0cmVQYXRo
QgPgQQNIAFIQc291cmNlTHVzdHJlUGF0aBJOCg9zb3VyY2VfZ2NzX3BhdGgYBCABKAsyHy5n
b29nbGUuY2xvdWQubHVzdHJlLnYxLkdjc1BhdGhCA+BBA0gAUg1zb3VyY2VHY3NQYXRoElgK
FGRlc3RpbmF0aW9uX2djc19wYXRoGAUgASgLMh8uZ29vZ2xlLmNsb3VkLmx1c3RyZS52MS5H
Y3NQYXRoQgPgQQNIAVISZGVzdGluYXRpb25HY3NQYXRoEmEKF2Rlc3RpbmF0aW9uX2x1c3Ry
ZV9wYXRoGAYgASgLMiIuZ29vZ2xlLmNsb3VkLmx1c3RyZS52MS5MdXN0cmVQYXRoQgPgQQNI
AVIVZGVzdGluYXRpb25MdXN0cmVQYXRoEkkKCGNvdW50ZXJzGAEgASgLMiguZ29vZ2xlLmNs
b3VkLmx1c3RyZS52MS5UcmFuc2ZlckNvdW50ZXJzQgPgQQNSCGNvdW50ZXJzEk4KDXRyYW5z
ZmVyX3R5cGUYAiABKA4yJC5nb29nbGUuY2xvdWQubHVzdHJlLnYxLlRyYW5zZmVyVHlwZUID
4EEDUgx0cmFuc2ZlclR5cGUSUgoPZXJyb3Jfc3VtbWFyaWVzGAcgAygLMiQuZ29vZ2xlLmNs
b3VkLmx1c3RyZS52MS5FcnJvclN1bW1hcnlCA+BBA1IOZXJyb3JTdW1tYXJpZXNCCAoGc291
cmNlQg0KC2Rlc3RpbmF0aW9uKkUKDFRyYW5zZmVyVHlwZRIdChlUUkFOU0ZFUl9UWVBFX1VO
U1BFQ0lGSUVEEAASCgoGSU1QT1JUEAESCgoGRVhQT1JUEAJCYQoaY29tLmdvb2dsZS5jbG91
ZC5sdXN0cmUudjFCDVRyYW5zZmVyUHJvdG9QAVoyY2xvdWQuZ29vZ2xlLmNvbS9nby9sdXN0
cmUvYXBpdjEvbHVzdHJlcGI7bHVzdHJlcGJKxlgKBxIFDgC6AgEKvAQKAQwSAw4AEjKxBCBD
b3B5cmlnaHQgMjAyNiBHb29nbGUgTExDCgogTGljZW5zZWQgdW5kZXIgdGhlIEFwYWNoZSBM
aWNlbnNlLCBWZXJzaW9uIDIuMCAodGhlICJMaWNlbnNlIik7CiB5b3UgbWF5IG5vdCB1c2Ug
dGhpcyBmaWxlIGV4Y2VwdCBpbiBjb21wbGlhbmNlIHdpdGggdGhlIExpY2Vuc2UuCiBZb3Ug
bWF5IG9idGFpbiBhIGNvcHkgb2YgdGhlIExpY2Vuc2UgYXQKCiAgICAgaHR0cDovL3d3dy5h
cGFjaGUub3JnL2xpY2Vuc2VzL0xJQ0VOU0UtMi4wCgogVW5sZXNzIHJlcXVpcmVkIGJ5IGFw
cGxpY2FibGUgbGF3IG9yIGFncmVlZCB0byBpbiB3cml0aW5nLCBzb2Z0d2FyZQogZGlzdHJp
YnV0ZWQgdW5kZXIgdGhlIExpY2Vuc2UgaXMgZGlzdHJpYnV0ZWQgb24gYW4gIkFTIElTIiBC
QVNJUywKIFdJVEhPVVQgV0FSUkFOVElFUyBPUiBDT05ESVRJT05TIE9GIEFOWSBLSU5ELCBl
aXRoZXIgZXhwcmVzcyBvciBpbXBsaWVkLgogU2VlIHRoZSBMaWNlbnNlIGZvciB0aGUgc3Bl
Y2lmaWMgbGFuZ3VhZ2UgZ292ZXJuaW5nIHBlcm1pc3Npb25zIGFuZAogbGltaXRhdGlvbnMg
dW5kZXIgdGhlIExpY2Vuc2UuCgoICgECEgMQAB8KCQoCAwASAxIAKQoJCgIDARIDEwAlCgkK
AgMCEgMUACMKCQoCAwMSAxUAKQoJCgIDBBIDFgAfCggKAQgSAxgASQoJCgIICxIDGABJCggK
AQgSAxkAIgoJCgIIChIDGQAiCggKAQgSAxoALgoJCgIICBIDGgAuCggKAQgSAxsAMwoJCgII
ARIDGwAzCi0KAgUAEgQeACcBGiEgVHlwZSBvZiB0cmFuc2ZlciB0aGF0IG9jY3VycmVkLgoK
CgoDBQABEgMeBREKKAoEBQACABIDIAIgGhsgWmVybyBpcyBhbiBpbGxlZ2FsIHZhbHVlLgoK
DAoFBQACAAESAyACGwoMCgUFAAIAAhIDIB4fCiEKBAUAAgESAyMCDRoUIEltcG9ydHMgdG8g
THVzdHJlLgoKDAoFBQACAQESAyMCCAoMCgUFAAIBAhIDIwsMCiMKBAUAAgISAyYCDRoWIEV4
cG9ydHMgZnJvbSBMdXN0cmUuCgoMCgUFAAICARIDJgIICgwKBQUAAgICEgMmCwwKMwoCBAAS
BCoAVQEaJyBNZXNzYWdlIGZvciBpbXBvcnRpbmcgZGF0YSB0byBMdXN0cmUuCgoKCgMEAAES
AyoIGQqFAQoEBAAIABIELQIyAxp3IEEgQ2xvdWQgU3RvcmFnZSBVUkkgb2YgYSBmb2xkZXIg
dG8gaW1wb3J0IGZpbGUgZGF0YSBmcm9tLCBpbiB0aGUKIGZvcm0gb2YgYGdzOi8vPGJ1Y2tl
dF9uYW1lPi88cGF0aF9pbnNpZGVfYnVja2V0Pi9gLgoKDAoFBAAIAAESAy0IDgqsAQoEBAAC
ABIDMQQZGp4BIFRoZSBDbG91ZCBTdG9yYWdlIHNvdXJjZSBidWNrZXQgYW5kLCBvcHRpb25h
bGx5LCBwYXRoIGluc2lkZSB0aGUgYnVja2V0LgogSWYgYSBwYXRoIGluc2lkZSB0aGUgYnVj
a2V0IGlzIHNwZWNpZmllZCwgaXQgbXVzdCBlbmQgd2l0aCBhIGZvcndhcmQKIHNsYXNoIChg
L2ApLgoKDAoFBAACAAYSAzEECwoMCgUEAAIAARIDMQwUCgwKBQQAAgADEgMxFxgKNQoEBAAI
ARIENQI4AxonIFRoZSBkZXN0aW5hdGlvbiBvZiB0aGUgZGF0YSB0cmFuc2Zlci4KCgwKBQQA
CAEBEgM1CBMKJwoEBAACARIDNwQfGhogTHVzdHJlIHBhdGggZGVzdGluYXRpb24uCgoMCgUE
AAIBBhIDNwQOCgwKBQQAAgEBEgM3DxoKDAoFBAACAQMSAzcdHgqRAQoEBAACAhIEPAI/BBqC
ASBSZXF1aXJlZC4gVGhlIG5hbWUgb2YgdGhlIE1hbmFnZWQgTHVzdHJlIGluc3RhbmNlIGlu
IHRoZSBmb3JtYXQKIGBwcm9qZWN0cy97cHJvamVjdH0vbG9jYXRpb25zL3tsb2NhdGlvbn0v
aW5zdGFuY2VzL3tpbnN0YW5jZX1gLgoKDAoFBAACAgUSAzwCCAoMCgUEAAICARIDPAkNCgwK
BQQAAgIDEgM8EBEKDQoFBAACAggSBDwSPwMKDwoIBAACAgicCAASAz0EKgoOCgcEAAICCJ8I
EgM+BFAKNAoEBAACAxIEQgJFBBomIE9wdGlvbmFsLiBVVUlEIHRvIGlkZW50aWZ5IHJlcXVl
c3RzLgoKDAoFBAACAwUSA0ICCAoMCgUEAAIDARIDQgkTCgwKBQQAAgMDEgNCFhcKDQoFBAAC
AwgSBEIYRQMKEgoLBAACAwjM8fmKAQESA0MEKgoPCggEAAIDCJwIABIDRAQqCusCCgQEAAIE
EgRPAlQEGtwCIE9wdGlvbmFsLiBVc2VyLXNwZWNpZmllZCBzZXJ2aWNlIGFjY291bnQgdXNl
ZCB0byBwZXJmb3JtIHRoZSB0cmFuc2Zlci4KIElmIHVuc3BlY2lmaWVkLCB0aGUgZGVmYXVs
dCBNYW5hZ2VkIEx1c3RyZSBzZXJ2aWNlIGFnZW50IHdpbGwgYmUgdXNlZC4KCiBVc2Ugb25l
IG9mIHRoZSBmb2xsb3dpbmcgZm9ybWF0czoKCiAqIGB7RU1BSUxfQUREUkVTU19PUl9VTklR
VUVfSUR9YAogKiBgcHJvamVjdHMve1BST0pFQ1RfSUR9L3NlcnZpY2VBY2NvdW50cy97RU1B
SUxfQUREUkVTU19PUl9VTklRVUVfSUR9YAogKiBgcHJvamVjdHMvLS9zZXJ2aWNlQWNjb3Vu
dHMve0VNQUlMX0FERFJFU1NfT1JfVU5JUVVFX0lEfWAKCgwKBQQAAgQFEgNPAggKDAoFBAAC
BAESA08JGAoMCgUEAAIEAxIDTxscCg0KBQQAAgQIEgRPHVQDCg8KCAQAAgQInAgAEgNQBCoK
DwoHBAACBAifCBIEUQRTBQpJCgIEARIFWACEAQEaPCBFeHBvcnQgZGF0YSBmcm9tIE1hbmFn
ZWQgTHVzdHJlIHRvIGEgQ2xvdWQgU3RvcmFnZSBidWNrZXQuCgoKCgMEAQESA1gIGQowCgQE
AQgAEgRaAl4DGiIgVGhlIHNvdXJjZSBvZiB0aGUgZGF0YSB0cmFuc2Zlci4KCgwKBQQBCAAB
EgNaCA4KbwoEBAECABIDXQQfGmIgVGhlIHJvb3QgZGlyZWN0b3J5IHBhdGggdG8gdGhlIE1h
bmFnZWQgTHVzdHJlIGZpbGUgc3lzdGVtLiBNdXN0IHN0YXJ0CiB3aXRoIGAvYC4gRGVmYXVs
dCBpcyBgL2AuCgoMCgUEAQIABhIDXQQOCgwKBQQBAgABEgNdDxoKDAoFBAECAAMSA10dHgo1
CgQEAQgBEgRhAmcDGicgVGhlIGRlc3RpbmF0aW9uIG9mIHRoZSBkYXRhIHRyYW5zZmVyLgoK
DAoFBAEIAQESA2EIEwroAQoEBAECARIDZgQZGtoBIFRoZSBVUkkgdG8gYSBDbG91ZCBTdG9y
YWdlIGJ1Y2tldCwgb3IgYSBwYXRoIHdpdGhpbiBhIGJ1Y2tldCwgdXNpbmcKIHRoZSBmb3Jt
YXQgYGdzOi8vPGJ1Y2tldF9uYW1lPi88b3B0aW9uYWxfcGF0aF9pbnNpZGVfYnVja2V0Pi9g
LiBJZiBhCiBwYXRoIGluc2lkZSB0aGUgYnVja2V0IGlzIHNwZWNpZmllZCwgaXQgbXVzdCBl
bmQgd2l0aCBhIGZvcndhcmQgc2xhc2gKIChgL2ApLgoKDAoFBAECAQYSA2YECwoMCgUEAQIB
ARIDZgwUCgwKBQQBAgEDEgNmFxgKkQEKBAQBAgISBGsCbgQaggEgUmVxdWlyZWQuIFRoZSBu
YW1lIG9mIHRoZSBNYW5hZ2VkIEx1c3RyZSBpbnN0YW5jZSBpbiB0aGUgZm9ybWF0CiBgcHJv
amVjdHMve3Byb2plY3R9L2xvY2F0aW9ucy97bG9jYXRpb259L2luc3RhbmNlcy97aW5zdGFu
Y2V9YC4KCgwKBQQBAgIFEgNrAggKDAoFBAECAgESA2sJDQoMCgUEAQICAxIDaxARCg0KBQQB
AgIIEgRrEm4DCg8KCAQBAgIInAgAEgNsBCoKDgoHBAECAgifCBIDbQRQCjQKBAQBAgMSBHEC
dAQaJiBPcHRpb25hbC4gVVVJRCB0byBpZGVudGlmeSByZXF1ZXN0cy4KCgwKBQQBAgMFEgNx
AggKDAoFBAECAwESA3EJEwoMCgUEAQIDAxIDcRYXCg0KBQQBAgMIEgRxGHQDChIKCwQBAgMI
zPH5igEBEgNyBCoKDwoIBAECAwicCAASA3MEKgrfAgoEBAECBBIFfgKDAQQazwIgT3B0aW9u
YWwuIFVzZXItc3BlY2lmaWVkIHNlcnZpY2UgYWNjb3VudCB1c2VkIHRvIHBlcmZvcm0gdGhl
IHRyYW5zZmVyLgogSWYgdW5zcGVjaWZpZWQsIHRoZSBNYW5hZ2VkIEx1c3RyZSBzZXJ2aWNl
IGFnZW50IGlzIHVzZWQuCgogVXNlIG9uZSBvZiB0aGUgZm9sbG93aW5nIGZvcm1hdHM6Cgog
KiBge0VNQUlMX0FERFJFU1NfT1JfVU5JUVVFX0lEfWAKICogYHByb2plY3RzL3tQUk9KRUNU
X0lEfS9zZXJ2aWNlQWNjb3VudHMve0VNQUlMX0FERFJFU1NfT1JfVU5JUVVFX0lEfWAKICog
YHByb2plY3RzLy0vc2VydmljZUFjY291bnRzL3tFTUFJTF9BRERSRVNTX09SX1VOSVFVRV9J
RH1gCgoMCgUEAQIEBRIDfgIICgwKBQQBAgQBEgN+CRgKDAoFBAECBAMSA34bHAoOCgUEAQIE
CBIFfh2DAQMKDwoIBAECBAicCAASA38EKgoRCgcEAQIECJ8IEgaAAQSCAQUKLgoCBAISBIcB
AB0aIiBSZXNwb25zZSBtZXNzYWdlIGZvciBFeHBvcnREYXRhLgoKCwoDBAIBEgSHAQgaCi4K
AgQDEgSKAQAdGiIgUmVzcG9uc2UgbWVzc2FnZSBmb3IgSW1wb3J0RGF0YS4KCgsKAwQDARIE
igEIGgo2CgIEBBIGjQEArAEBGiggTWV0YWRhdGEgb2YgdGhlIGV4cG9ydCBkYXRhIG9wZXJh
dGlvbi4KCgsKAwQEARIEjQEIGgoxCgQEBAIAEgSPAQIzGiMgRGF0YSB0cmFuc2ZlciBvcGVy
YXRpb24gbWV0YWRhdGEuCgoNCgUEBAIABhIEjwECGwoNCgUEBAIAARIEjwEcLgoNCgUEBAIA
AxIEjwExMgpCCgQEBAIBEgaSAQKTATIaMiBPdXRwdXQgb25seS4gVGhlIHRpbWUgdGhlIG9w
ZXJhdGlvbiB3YXMgY3JlYXRlZC4KCg0KBQQEAgEGEgSSAQIbCg0KBQQEAgEBEgSSARwnCg0K
BQQEAgEDEgSSASorCg0KBQQEAgEIEgSTAQYxChAKCAQEAgEInAgAEgSTAQcwCkcKBAQEAgIS
BpYBApcBMho3IE91dHB1dCBvbmx5LiBUaGUgdGltZSB0aGUgb3BlcmF0aW9uIGZpbmlzaGVk
IHJ1bm5pbmcuCgoNCgUEBAICBhIElgECGwoNCgUEBAICARIElgEcJAoNCgUEBAICAxIElgEn
KAoNCgUEBAICCBIElwEGMQoQCggEBAICCJwIABIElwEHMApaCgQEBAIDEgSaAQJAGkwgT3V0
cHV0IG9ubHkuIFNlcnZlci1kZWZpbmVkIHJlc291cmNlIHBhdGggZm9yIHRoZSB0YXJnZXQg
b2YgdGhlIG9wZXJhdGlvbi4KCg0KBQQEAgMFEgSaAQIICg0KBQQEAgMBEgSaAQkPCg0KBQQE
AgMDEgSaARITCg0KBQQEAgMIEgSaARQ/ChAKCAQEAgMInAgAEgSaARU+CkgKBAQEAgQSBJ0B
Aj4aOiBPdXRwdXQgb25seS4gTmFtZSBvZiB0aGUgdmVyYiBleGVjdXRlZCBieSB0aGUgb3Bl
cmF0aW9uLgoKDQoFBAQCBAUSBJ0BAggKDQoFBAQCBAESBJ0BCQ0KDQoFBAQCBAMSBJ0BEBEK
DQoFBAQCBAgSBJ0BEj0KEAoIBAQCBAicCAASBJ0BEzwKTAoEBAQCBRIEoAECSBo+IE91dHB1
dCBvbmx5LiBIdW1hbi1yZWFkYWJsZSBzdGF0dXMgb2YgdGhlIG9wZXJhdGlvbiwgaWYgYW55
LgoKDQoFBAQCBQUSBKABAggKDQoFBAQCBQESBKABCRcKDQoFBAQCBQMSBKABGhsKDQoFBAQC
BQgSBKABHEcKEAoIBAQCBQicCAASBKABHUYK0QIKBAQEAgYSBKgBAk4awgIgT3V0cHV0IG9u
bHkuIElkZW50aWZpZXMgd2hldGhlciB0aGUgdXNlciBoYXMgcmVxdWVzdGVkIGNhbmNlbGxh
dGlvbgogb2YgdGhlIG9wZXJhdGlvbi4gT3BlcmF0aW9ucyB0aGF0IGhhdmUgc3VjY2Vzc2Z1
bGx5IGJlZW4gY2FuY2VsbGVkCiBoYXZlCiBbZ29vZ2xlLmxvbmdydW5uaW5nLk9wZXJhdGlv
bi5lcnJvcl1bZ29vZ2xlLmxvbmdydW5uaW5nLk9wZXJhdGlvbi5lcnJvcl0KIHZhbHVlIHdp
dGggYSBbZ29vZ2xlLnJwYy5TdGF0dXMuY29kZV1bZ29vZ2xlLnJwYy5TdGF0dXMuY29kZV0g
b2YgMSwKIGNvcnJlc3BvbmRpbmcgdG8gYENvZGUuQ0FOQ0VMTEVEYC4KCg0KBQQEAgYFEgSo
AQIGCg0KBQQEAgYBEgSoAQcdCg0KBQQEAgYDEgSoASAhCg0KBQQEAgYIEgSoASJNChAKCAQE
AgYInAgAEgSoASNMCkUKBAQEAgcSBKsBAkUaNyBPdXRwdXQgb25seS4gQVBJIHZlcnNpb24g
dXNlZCB0byBzdGFydCB0aGUgb3BlcmF0aW9uLgoKDQoFBAQCBwUSBKsBAggKDQoFBAQCBwES
BKsBCRQKDQoFBAQCBwMSBKsBFxgKDQoFBAQCBwgSBKsBGUQKEAoIBAQCBwicCAASBKsBGkMK
NgoCBAUSBq8BAMsBARooIE1ldGFkYXRhIG9mIHRoZSBpbXBvcnQgZGF0YSBvcGVyYXRpb24u
CgoLCgMEBQESBK8BCBoKMQoEBAUCABIEsQECMxojIERhdGEgdHJhbnNmZXIgb3BlcmF0aW9u
IG1ldGFkYXRhLgoKDQoFBAUCAAYSBLEBAhsKDQoFBAUCAAESBLEBHC4KDQoFBAUCAAMSBLEB
MTIKQgoEBAUCARIGtAECtQEyGjIgT3V0cHV0IG9ubHkuIFRoZSB0aW1lIHRoZSBvcGVyYXRp
b24gd2FzIGNyZWF0ZWQuCgoNCgUEBQIBBhIEtAECGwoNCgUEBQIBARIEtAEcJwoNCgUEBQIB
AxIEtAEqKwoNCgUEBQIBCBIEtQEGMQoQCggEBQIBCJwIABIEtQEHMApHCgQEBQICEga4AQK5
ATIaNyBPdXRwdXQgb25seS4gVGhlIHRpbWUgdGhlIG9wZXJhdGlvbiBmaW5pc2hlZCBydW5u
aW5nLgoKDQoFBAUCAgYSBLgBAhsKDQoFBAUCAgESBLgBHCQKDQoFBAUCAgMSBLgBJygKDQoF
BAUCAggSBLkBBjEKEAoIBAUCAgicCAASBLkBBzAKWgoEBAUCAxIEvAECQBpMIE91dHB1dCBv
bmx5LiBTZXJ2ZXItZGVmaW5lZCByZXNvdXJjZSBwYXRoIGZvciB0aGUgdGFyZ2V0IG9mIHRo
ZSBvcGVyYXRpb24uCgoNCgUEBQIDBRIEvAECCAoNCgUEBQIDARIEvAEJDwoNCgUEBQIDAxIE
vAESEwoNCgUEBQIDCBIEvAEUPwoQCggEBQIDCJwIABIEvAEVPgpICgQEBQIEEgS/AQJIGjog
T3V0cHV0IG9ubHkuIE5hbWUgb2YgdGhlIHZlcmIgZXhlY3V0ZWQgYnkgdGhlIG9wZXJhdGlv
bi4KCg0KBQQFAgQFEgS/AQIICg0KBQQFAgQBEgS/AQkXCg0KBQQFAgQDEgS/ARobCg0KBQQF
AgQIEgS/ARxHChAKCAQFAgQInAgAEgS/AR1GCtECCgQEBQIFEgTHAQJOGsICIE91dHB1dCBv
bmx5LiBJZGVudGlmaWVzIHdoZXRoZXIgdGhlIHVzZXIgaGFzIHJlcXVlc3RlZCBjYW5jZWxs
YXRpb24KIG9mIHRoZSBvcGVyYXRpb24uIE9wZXJhdGlvbnMgdGhhdCBoYXZlIHN1Y2Nlc3Nm
dWxseSBiZWVuIGNhbmNlbGxlZAogaGF2ZQogW2dvb2dsZS5sb25ncnVubmluZy5PcGVyYXRp
b24uZXJyb3JdW2dvb2dsZS5sb25ncnVubmluZy5PcGVyYXRpb24uZXJyb3JdCiB2YWx1ZSB3
aXRoIGEgW2dvb2dsZS5ycGMuU3RhdHVzLmNvZGVdW2dvb2dsZS5ycGMuU3RhdHVzLmNvZGVd
IG9mIDEsCiBjb3JyZXNwb25kaW5nIHRvIGBDb2RlLkNBTkNFTExFRGAuCgoNCgUEBQIFBRIE
xwECBgoNCgUEBQIFARIExwEHHQoNCgUEBQIFAxIExwEgIQoNCgUEBQIFCBIExwEiTQoQCggE
BQIFCJwIABIExwEjTApFCgQEBQIGEgTKAQJFGjcgT3V0cHV0IG9ubHkuIEFQSSB2ZXJzaW9u
IHVzZWQgdG8gc3RhcnQgdGhlIG9wZXJhdGlvbi4KCg0KBQQFAgYFEgTKAQIICg0KBQQFAgYB
EgTKAQkUCg0KBQQFAgYDEgTKARcYCg0KBQQFAgYIEgTKARlEChAKCAQFAgYInAgAEgTKARpD
ClsKAgQGEgbOAQDUAQEaTSBTcGVjaWZpZXMgYSBDbG91ZCBTdG9yYWdlIGJ1Y2tldCBhbmQs
IG9wdGlvbmFsbHksIGEgcGF0aCBpbnNpZGUgdGhlIGJ1Y2tldC4KCgsKAwQGARIEzgEIDwrz
AQoEBAYCABIE0wECOhrkASBSZXF1aXJlZC4gVGhlIFVSSSB0byBhIENsb3VkIFN0b3JhZ2Ug
YnVja2V0LCBvciBhIHBhdGggd2l0aGluIGEgYnVja2V0LAogdXNpbmcgdGhlIGZvcm1hdCBg
Z3M6Ly88YnVja2V0X25hbWU+LzxvcHRpb25hbF9wYXRoX2luc2lkZV9idWNrZXQ+L2AuIElm
IGEKIHBhdGggaW5zaWRlIHRoZSBidWNrZXQgaXMgc3BlY2lmaWVkLCBpdCBtdXN0IGVuZCB3
aXRoIGEgZm9yd2FyZCBzbGFzaAogKGAvYCkuCgoNCgUEBgIABRIE0wECCAoNCgUEBgIAARIE
0wEJDAoNCgUEBgIAAxIE0wEPEAoNCgUEBgIACBIE0wEROQoQCggEBgIACJwIABIE0wESOApC
CgIEBxIG1wEA3QEBGjQgVGhlIHJvb3QgZGlyZWN0b3J5IHBhdGggdG8gdGhlIEx1c3RyZSBm
aWxlIHN5c3RlbS4KCgsKAwQHARIE1wEIEgryAQoEBAcCABIE3AECOxrjASBPcHRpb25hbC4g
VGhlIHJvb3QgZGlyZWN0b3J5IHBhdGggdG8gdGhlIE1hbmFnZWQgTHVzdHJlIGZpbGUgc3lz
dGVtLiBNdXN0CiBzdGFydCB3aXRoCiBgL2AuIERlZmF1bHQgaXMgYC9gLiBJZiB5b3UncmUg
aW1wb3J0aW5nIGRhdGEgaW50byBNYW5hZ2VkIEx1c3RyZSwgYW55CiBwYXRoIG90aGVyIHRo
YW4gdGhlIGRlZmF1bHQgbXVzdCBhbHJlYWR5IGV4aXN0IG9uIHRoZSBmaWxlIHN5c3RlbS4K
Cg0KBQQHAgAFEgTcAQIICg0KBQQHAgABEgTcAQkNCg0KBQQHAgADEgTcARARCg0KBQQHAgAI
EgTcARI6ChAKCAQHAgAInAgAEgTcARM5CloKAgQIEgbgAQD+AQEaTCBBIGNvbGxlY3Rpb24g
b2YgY291bnRlcnMgdGhhdCByZXBvcnQgdGhlIHByb2dyZXNzIG9mIGEgdHJhbnNmZXIgb3Bl
cmF0aW9uLgoKCwoDBAgBEgTgAQgYCqwBCgQECAIAEgTkAQIgGp0BIE9iamVjdHMgZm91bmQg
aW4gdGhlIGRhdGEgc291cmNlIHRoYXQgYXJlIHNjaGVkdWxlZCB0byBiZSB0cmFuc2ZlcnJl
ZCwKIGV4Y2x1ZGluZyBhbnkgdGhhdCBhcmUgZmlsdGVyZWQgYmFzZWQgb24gb2JqZWN0IGNv
bmRpdGlvbnMgb3Igc2tpcHBlZCBkdWUKIHRvIHN5bmMuCgoNCgUECAIABRIE5AECBwoNCgUE
CAIAARIE5AEIGwoNCgUECAIAAxIE5AEeHwq6AQoEBAgCARIE6QECHhqrASBUb3RhbCBudW1i
ZXIgb2YgYnl0ZXMgZm91bmQgaW4gdGhlIGRhdGEgc291cmNlIHRoYXQgYXJlIHNjaGVkdWxl
ZCB0byBiZQogdHJhbnNmZXJyZWQsIGV4Y2x1ZGluZyBhbnkgdGhhdCBhcmUgZmlsdGVyZWQg
YmFzZWQgb24gb2JqZWN0IGNvbmRpdGlvbnMgb3IKIHNraXBwZWQgZHVlIHRvIHN5bmMuCgoN
CgUECAIBBRIE6QECBwoNCgUECAIBARIE6QEIGQoNCgUECAIBAxIE6QEcHQp4CgQECAICEgTt
AQIiGmogT2JqZWN0cyBpbiB0aGUgZGF0YSBzb3VyY2UgdGhhdCBhcmUgbm90IHRyYW5zZmVy
cmVkIGJlY2F1c2UgdGhleSBhbHJlYWR5CiBleGlzdCBpbiB0aGUgZGF0YSBkZXN0aW5hdGlv
bi4KCg0KBQQIAgIFEgTtAQIHCg0KBQQIAgIBEgTtAQgdCg0KBQQIAgIDEgTtASAhCnYKBAQI
AgMSBPEBAiAaaCBCeXRlcyBpbiB0aGUgZGF0YSBzb3VyY2UgdGhhdCBhcmUgbm90IHRyYW5z
ZmVycmVkIGJlY2F1c2UgdGhleSBhbHJlYWR5CiBleGlzdCBpbiB0aGUgZGF0YSBkZXN0aW5h
dGlvbi4KCg0KBQQIAgMFEgTxAQIHCg0KBQQIAgMBEgTxAQgbCg0KBQQIAgMDEgTxAR4fCkAK
BAQIAgQSBPQBAiEaMiBPYmplY3RzIHRoYXQgYXJlIGNvcGllZCB0byB0aGUgZGF0YSBkZXN0
aW5hdGlvbi4KCg0KBQQIAgQFEgT0AQIHCg0KBQQIAgQBEgT0AQgcCg0KBQQIAgQDEgT0AR8g
Cj4KBAQIAgUSBPcBAh8aMCBCeXRlcyB0aGF0IGFyZSBjb3BpZWQgdG8gdGhlIGRhdGEgZGVz
dGluYXRpb24uCgoNCgUECAIFBRIE9wECBwoNCgUECAIFARIE9wEIGgoNCgUECAIFAxIE9wEd
HgpWCgQECAIGEgT6AQJNGkggT3V0cHV0IG9ubHkuIE9iamVjdHMgdGhhdCBhcmUgZmFpbGVk
IHRvIHdyaXRlIHRvIHRoZSBkYXRhIGRlc3RpbmF0aW9uLgoKDQoFBAgCBgUSBPoBAgcKDQoF
BAgCBgESBPoBCBwKDQoFBAgCBgMSBPoBHyAKDQoFBAgCBggSBPoBIUwKEAoIBAgCBgicCAAS
BPoBIksKVAoEBAgCBxIE/QECSxpGIE91dHB1dCBvbmx5LiBCeXRlcyB0aGF0IGFyZSBmYWls
ZWQgdG8gd3JpdGUgdG8gdGhlIGRhdGEgZGVzdGluYXRpb24uCgoNCgUECAIHBRIE/QECBwoN
CgUECAIHARIE/QEIGgoNCgUECAIHAxIE/QEdHgoNCgUECAIHCBIE/QEfSgoQCggECAIHCJwI
ABIE/QEgSQo/CgIECRIGgQIAiAIBGjEgQW4gZW50cnkgZGVzY3JpYmluZyBhbiBlcnJvciB0
aGF0IGhhcyBvY2N1cnJlZC4KCgsKAwQJARIEgQIIFQqJAQoEBAkCABIEhAICOhp7IFJlcXVp
cmVkLiBBIFVSTCB0aGF0IHJlZmVycyB0byB0aGUgdGFyZ2V0IChhIGRhdGEgc291cmNlLCBh
IGRhdGEgc2luaywKIG9yIGFuIG9iamVjdCkgd2l0aCB3aGljaCB0aGUgZXJyb3IgaXMgYXNz
b2NpYXRlZC4KCg0KBQQJAgAFEgSEAgIICg0KBQQJAgABEgSEAgkMCg0KBQQJAgADEgSEAg8Q
Cg0KBQQJAgAIEgSEAhE5ChAKCAQJAgAInAgAEgSEAhI4CkAKBAQJAgESBIcCAiQaMiBBIGxp
c3Qgb2YgbWVzc2FnZXMgdGhhdCBjYXJyeSB0aGUgZXJyb3IgZGV0YWlscy4KCg0KBQQJAgEE
EgSHAgIKCg0KBQQJAgEFEgSHAgsRCg0KBQQJAgEBEgSHAhIfCg0KBQQJAgEDEgSHAiIjCl4K
AgQKEgaMAgCYAgEaUCBBIHN1bW1hcnkgb2YgZXJyb3JzIGJ5IGVycm9yIGNvZGUsIHBsdXMg
YSBjb3VudCBhbmQgc2FtcGxlIGVycm9yIGxvZwogZW50cmllcy4KCgsKAwQKARIEjAIIFAoZ
CgQECgIAEgSOAgJKGgsgUmVxdWlyZWQuCgoNCgUECgIABhIEjgICEQoNCgUECgIAARIEjgIS
HAoNCgUECgIAAxIEjgIfIAoNCgUECgIACBIEjgIhSQoQCggECgIACJwIABIEjgIiSAo2CgQE
CgIBEgSRAgJBGiggUmVxdWlyZWQuIENvdW50IG9mIHRoaXMgdHlwZSBvZiBlcnJvci4KCg0K
BQQKAgEFEgSRAgIHCg0KBQQKAgEBEgSRAggTCg0KBQQKAgEDEgSRAhYXCg0KBQQKAgEIEgSR
AhhAChAKCAQKAgEInAgAEgSRAhk/CoIBCgQECgICEgSXAgIvGnQgRXJyb3Igc2FtcGxlcy4K
CiBBdCBtb3N0IDUgZXJyb3IgbG9nIGVudHJpZXMgYXJlIHJlY29yZGVkIGZvciBhIGdpdmVu
CiBlcnJvciBjb2RlIGZvciBhIHNpbmdsZSB0cmFuc2ZlciBvcGVyYXRpb24uCgoNCgUECgIC
BBIElwICCgoNCgUECgICBhIElwILGAoNCgUECgICARIElwIZKgoNCgUECgICAxIElwItLgpP
CgIECxIGmwIAugIBGkEgUmVwcmVzZW50cyB0aGUgbWV0YWRhdGEgb2YgdGhlIGxvbmctcnVu
bmluZyB0cmFuc2ZlciBvcGVyYXRpb24uCgoLCgMECwESBJsCCCEKMwoEBAsIABIGnQICpAID
GiMgVGhlIHNvdXJjZSBvZiB0cmFuc2ZlciBvcGVyYXRpb24uCgoNCgUECwgAARIEnQIIDgot
CgQECwIAEgafAgSgAjQaHSBPdXRwdXQgb25seS4gTHVzdHJlIHNvdXJjZS4KCg0KBQQLAgAG
EgSfAgQOCg0KBQQLAgABEgSfAg8hCg0KBQQLAgADEgSfAiQlCg0KBQQLAgAIEgSgAggzChAK
CAQLAgAInAgAEgSgAgkyCjIKBAQLAgESBKMCBEwaJCBPdXRwdXQgb25seS4gQ2xvdWQgU3Rv
cmFnZSBzb3VyY2UuCgoNCgUECwIBBhIEowIECwoNCgUECwIBARIEowIMGwoNCgUECwIBAxIE
owIeHwoNCgUECwIBCBIEowIgSwoQCggECwIBCJwIABIEowIhSgo4CgQECwgBEganAgKvAgMa
KCBUaGUgZGVzdGluYXRpb24gb2YgdHJhbnNmZXIgb3BlcmF0aW9uLgoKDQoFBAsIAQESBKcC
CBMKOQoEBAsCAhIGqQIEqgI0GikgT3V0cHV0IG9ubHkuIENsb3VkIFN0b3JhZ2UgZGVzdGlu
YXRpb24uCgoNCgUECwICBhIEqQIECwoNCgUECwICARIEqQIMIAoNCgUECwICAxIEqQIjJAoN
CgUECwICCBIEqgIIMwoQCggECwICCJwIABIEqgIJMgoyCgQECwIDEgatAgSuAjQaIiBPdXRw
dXQgb25seS4gTHVzdHJlIGRlc3RpbmF0aW9uLgoKDQoFBAsCAwYSBK0CBA4KDQoFBAsCAwES
BK0CDyYKDQoFBAsCAwMSBK0CKSoKDQoFBAsCAwgSBK4CCDMKEAoIBAsCAwicCAASBK4CCTIK
RAoEBAsCBBIEsgICTBo2IE91dHB1dCBvbmx5LiBUaGUgcHJvZ3Jlc3Mgb2YgdGhlIHRyYW5z
ZmVyIG9wZXJhdGlvbi4KCg0KBQQLAgQGEgSyAgISCg0KBQQLAgQBEgSyAhMbCg0KBQQLAgQD
EgSyAh4fCg0KBQQLAgQIEgSyAiBLChAKCAQLAgQInAgAEgSyAiFKCjwKBAQLAgUSBLUCAk0a
LiBPdXRwdXQgb25seS4gVGhlIHR5cGUgb2YgdHJhbnNmZXIgb2NjdXJyaW5nLgoKDQoFBAsC
BQYSBLUCAg4KDQoFBAsCBQESBLUCDxwKDQoFBAsCBQMSBLUCHyAKDQoFBAsCBQgSBLUCIUwK
EAoIBAsCBQicCAASBLUCIksKSQoEBAsCBhIGuAICuQIyGjkgT3V0cHV0IG9ubHkuIEVycm9y
IHN1bW1hcnkgYWJvdXQgdGhlIHRyYW5zZmVyIG9wZXJhdGlvbgoKDQoFBAsCBgQSBLgCAgoK
DQoFBAsCBgYSBLgCCxcKDQoFBAsCBgESBLgCGCcKDQoFBAsCBgMSBLgCKisKDQoFBAsCBggS
BLkCBjEKEAoIBAsCBgicCAASBLkCBzBiBnByb3RvMw==
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Lustre::V1::Transfer::ImportDataRequest ===
    # Fields for ImportDataRequest
    # Field: gcs_path Type: 11 (.google.cloud.lustre.v1.GcsPath)
    # Field: lustre_path Type: 11 (.google.cloud.lustre.v1.LustrePath)
    # Field: name Type: 9 ()
    # Field: request_id Type: 9 ()
    # Field: service_account Type: 9 ()

# === Message: Google::Cloud::Lustre::V1::Transfer::ExportDataRequest ===
    # Fields for ExportDataRequest
    # Field: lustre_path Type: 11 (.google.cloud.lustre.v1.LustrePath)
    # Field: gcs_path Type: 11 (.google.cloud.lustre.v1.GcsPath)
    # Field: name Type: 9 ()
    # Field: request_id Type: 9 ()
    # Field: service_account Type: 9 ()

# === Message: Google::Cloud::Lustre::V1::Transfer::ExportDataResponse ===
    # Fields for ExportDataResponse

# === Message: Google::Cloud::Lustre::V1::Transfer::ImportDataResponse ===
    # Fields for ImportDataResponse

# === Message: Google::Cloud::Lustre::V1::Transfer::ExportDataMetadata ===
    # Fields for ExportDataMetadata
    # Field: operation_metadata Type: 11 (.google.cloud.lustre.v1.TransferOperationMetadata)
    # Field: create_time Type: 11 (.google.protobuf.Timestamp)
    # Field: end_time Type: 11 (.google.protobuf.Timestamp)
    # Field: target Type: 9 ()
    # Field: verb Type: 9 ()
    # Field: status_message Type: 9 ()
    # Field: requested_cancellation Type: 8 ()
    # Field: api_version Type: 9 ()

# === Message: Google::Cloud::Lustre::V1::Transfer::ImportDataMetadata ===
    # Fields for ImportDataMetadata
    # Field: operation_metadata Type: 11 (.google.cloud.lustre.v1.TransferOperationMetadata)
    # Field: create_time Type: 11 (.google.protobuf.Timestamp)
    # Field: end_time Type: 11 (.google.protobuf.Timestamp)
    # Field: target Type: 9 ()
    # Field: status_message Type: 9 ()
    # Field: requested_cancellation Type: 8 ()
    # Field: api_version Type: 9 ()

# === Message: Google::Cloud::Lustre::V1::Transfer::GcsPath ===
    # Fields for GcsPath
    # Field: uri Type: 9 ()

# === Message: Google::Cloud::Lustre::V1::Transfer::LustrePath ===
    # Fields for LustrePath
    # Field: path Type: 9 ()

# === Message: Google::Cloud::Lustre::V1::Transfer::TransferCounters ===
    # Fields for TransferCounters
    # Field: found_objects_count Type: 3 ()
    # Field: bytes_found_count Type: 3 ()
    # Field: objects_skipped_count Type: 3 ()
    # Field: bytes_skipped_count Type: 3 ()
    # Field: objects_copied_count Type: 3 ()
    # Field: bytes_copied_count Type: 3 ()
    # Field: objects_failed_count Type: 3 ()
    # Field: bytes_failed_count Type: 3 ()

# === Message: Google::Cloud::Lustre::V1::Transfer::ErrorLogEntry ===
    # Fields for ErrorLogEntry
    # Field: uri Type: 9 ()
    # Field: error_details Type: 9 ()

# === Message: Google::Cloud::Lustre::V1::Transfer::ErrorSummary ===
    # Fields for ErrorSummary
    # Field: error_code Type: 14 (.google.rpc.Code)
    # Field: error_count Type: 3 ()
    # Field: error_log_entries Type: 11 (.google.cloud.lustre.v1.ErrorLogEntry)

# === Message: Google::Cloud::Lustre::V1::Transfer::TransferOperationMetadata ===
    # Fields for TransferOperationMetadata
    # Field: source_lustre_path Type: 11 (.google.cloud.lustre.v1.LustrePath)
    # Field: source_gcs_path Type: 11 (.google.cloud.lustre.v1.GcsPath)
    # Field: destination_gcs_path Type: 11 (.google.cloud.lustre.v1.GcsPath)
    # Field: destination_lustre_path Type: 11 (.google.cloud.lustre.v1.LustrePath)
    # Field: counters Type: 11 (.google.cloud.lustre.v1.TransferCounters)
    # Field: transfer_type Type: 14 (.google.cloud.lustre.v1.TransferType)
    # Field: error_summaries Type: 11 (.google.cloud.lustre.v1.ErrorSummary)

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Lustre::V1::Transfer - Compiled Protocol Buffers messages for google/cloud/lustre/v1/transfer.proto

=head1 SYNOPSIS

    use Google::Cloud::Lustre::V1::Transfer;

    my $msg = Google::Cloud::Lustre::V1::Transfer::ImportDataRequest->new({
        gcs_path => $gcs_path,
        lustre_path => $lustre_path,
        name => $name,
        request_id => $request_id,
    });

    # Read or update a field
    my $val = $msg->gcs_path();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Lustre::V1::Transfer::ImportDataRequest->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/lustre/v1/transfer.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Lustre::V1::Transfer::ImportDataRequest

Message for importing data to Lustre.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->gcs_path() >> / C<< $msg->gcs_path($value) >>

Type: C<Message> (L<Google::Cloud::Lustre::V1::Transfer::GcsPath>)

The Cloud Storage source bucket and, optionally, path inside the bucket.
If a path inside the bucket is specified, it must end with a forward
slash (`/`).

=item * C<< $msg->lustre_path() >> / C<< $msg->lustre_path($value) >>

Type: C<Message> (L<Google::Cloud::Lustre::V1::Transfer::LustrePath>)

Lustre path destination.

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. The name of the Managed Lustre instance in the format
`projects/{project}/locations/{location}/instances/{instance}`.

=item * C<< $msg->request_id() >> / C<< $msg->request_id($value) >>

Type: C<String>

Optional. UUID to identify requests.

=item * C<< $msg->service_account() >> / C<< $msg->service_account($value) >>

Type: C<String>

Optional. User-specified service account used to perform the transfer.
If unspecified, the default Managed Lustre service agent will be used.

Use one of the following formats:

* `{EMAIL_ADDRESS_OR_UNIQUE_ID}`
* `projects/{PROJECT_ID}/serviceAccounts/{EMAIL_ADDRESS_OR_UNIQUE_ID}`
* `projects/-/serviceAccounts/{EMAIL_ADDRESS_OR_UNIQUE_ID}`

=back

=head2 Google::Cloud::Lustre::V1::Transfer::ExportDataRequest

Export data from Managed Lustre to a Cloud Storage bucket.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->lustre_path() >> / C<< $msg->lustre_path($value) >>

Type: C<Message> (L<Google::Cloud::Lustre::V1::Transfer::LustrePath>)

The root directory path to the Managed Lustre file system. Must start
with `/`. Default is `/`.

=item * C<< $msg->gcs_path() >> / C<< $msg->gcs_path($value) >>

Type: C<Message> (L<Google::Cloud::Lustre::V1::Transfer::GcsPath>)

The URI to a Cloud Storage bucket, or a path within a bucket, using
the format `gs://<bucket_name>/<optional_path_inside_bucket>/`. If a
path inside the bucket is specified, it must end with a forward slash
(`/`).

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. The name of the Managed Lustre instance in the format
`projects/{project}/locations/{location}/instances/{instance}`.

=item * C<< $msg->request_id() >> / C<< $msg->request_id($value) >>

Type: C<String>

Optional. UUID to identify requests.

=item * C<< $msg->service_account() >> / C<< $msg->service_account($value) >>

Type: C<String>

Optional. User-specified service account used to perform the transfer.
If unspecified, the Managed Lustre service agent is used.

Use one of the following formats:

* `{EMAIL_ADDRESS_OR_UNIQUE_ID}`
* `projects/{PROJECT_ID}/serviceAccounts/{EMAIL_ADDRESS_OR_UNIQUE_ID}`
* `projects/-/serviceAccounts/{EMAIL_ADDRESS_OR_UNIQUE_ID}`

=back

=head2 Google::Cloud::Lustre::V1::Transfer::ExportDataResponse

Response message for ExportData.

Inherits from L<Protobuf::Message>.

=head2 Google::Cloud::Lustre::V1::Transfer::ImportDataResponse

Response message for ImportData.

Inherits from L<Protobuf::Message>.

=head2 Google::Cloud::Lustre::V1::Transfer::ExportDataMetadata

Metadata of the export data operation.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->operation_metadata() >> / C<< $msg->operation_metadata($value) >>

Type: C<Message> (L<Google::Cloud::Lustre::V1::Transfer::TransferOperationMetadata>)

Data transfer operation metadata.

=item * C<< $msg->create_time() >> / C<< $msg->create_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Output only. The time the operation was created.

=item * C<< $msg->end_time() >> / C<< $msg->end_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Output only. The time the operation finished running.

=item * C<< $msg->target() >> / C<< $msg->target($value) >>

Type: C<String>

Output only. Server-defined resource path for the target of the operation.

=item * C<< $msg->verb() >> / C<< $msg->verb($value) >>

Type: C<String>

Output only. Name of the verb executed by the operation.

=item * C<< $msg->status_message() >> / C<< $msg->status_message($value) >>

Type: C<String>

Output only. Human-readable status of the operation, if any.

=item * C<< $msg->requested_cancellation() >> / C<< $msg->requested_cancellation($value) >>

Type: C<Bool>

Output only. Identifies whether the user has requested cancellation
of the operation. Operations that have successfully been cancelled
have
[google.longrunning.Operation.error][google.longrunning.Operation.error]
value with a [google.rpc.Status.code][google.rpc.Status.code] of 1,
corresponding to `Code.CANCELLED`.

=item * C<< $msg->api_version() >> / C<< $msg->api_version($value) >>

Type: C<String>

Output only. API version used to start the operation.

=back

=head2 Google::Cloud::Lustre::V1::Transfer::ImportDataMetadata

Metadata of the import data operation.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->operation_metadata() >> / C<< $msg->operation_metadata($value) >>

Type: C<Message> (L<Google::Cloud::Lustre::V1::Transfer::TransferOperationMetadata>)

Data transfer operation metadata.

=item * C<< $msg->create_time() >> / C<< $msg->create_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Output only. The time the operation was created.

=item * C<< $msg->end_time() >> / C<< $msg->end_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Output only. The time the operation finished running.

=item * C<< $msg->target() >> / C<< $msg->target($value) >>

Type: C<String>

Output only. Server-defined resource path for the target of the operation.

=item * C<< $msg->status_message() >> / C<< $msg->status_message($value) >>

Type: C<String>

Output only. Name of the verb executed by the operation.

=item * C<< $msg->requested_cancellation() >> / C<< $msg->requested_cancellation($value) >>

Type: C<Bool>

Output only. Identifies whether the user has requested cancellation
of the operation. Operations that have successfully been cancelled
have
[google.longrunning.Operation.error][google.longrunning.Operation.error]
value with a [google.rpc.Status.code][google.rpc.Status.code] of 1,
corresponding to `Code.CANCELLED`.

=item * C<< $msg->api_version() >> / C<< $msg->api_version($value) >>

Type: C<String>

Output only. API version used to start the operation.

=back

=head2 Google::Cloud::Lustre::V1::Transfer::GcsPath

Specifies a Cloud Storage bucket and, optionally, a path inside the bucket.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->uri() >> / C<< $msg->uri($value) >>

Type: C<String>

Required. The URI to a Cloud Storage bucket, or a path within a bucket,
using the format `gs://<bucket_name>/<optional_path_inside_bucket>/`. If a
path inside the bucket is specified, it must end with a forward slash
(`/`).

=back

=head2 Google::Cloud::Lustre::V1::Transfer::LustrePath

The root directory path to the Lustre file system.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->path() >> / C<< $msg->path($value) >>

Type: C<String>

Optional. The root directory path to the Managed Lustre file system. Must
start with
`/`. Default is `/`. If you're importing data into Managed Lustre, any
path other than the default must already exist on the file system.

=back

=head2 Google::Cloud::Lustre::V1::Transfer::TransferCounters

A collection of counters that report the progress of a transfer operation.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->found_objects_count() >> / C<< $msg->found_objects_count($value) >>

Type: C<Int64>

Objects found in the data source that are scheduled to be transferred,
excluding any that are filtered based on object conditions or skipped due
to sync.

=item * C<< $msg->bytes_found_count() >> / C<< $msg->bytes_found_count($value) >>

Type: C<Int64>

Total number of bytes found in the data source that are scheduled to be
transferred, excluding any that are filtered based on object conditions or
skipped due to sync.

=item * C<< $msg->objects_skipped_count() >> / C<< $msg->objects_skipped_count($value) >>

Type: C<Int64>

Objects in the data source that are not transferred because they already
exist in the data destination.

=item * C<< $msg->bytes_skipped_count() >> / C<< $msg->bytes_skipped_count($value) >>

Type: C<Int64>

Bytes in the data source that are not transferred because they already
exist in the data destination.

=item * C<< $msg->objects_copied_count() >> / C<< $msg->objects_copied_count($value) >>

Type: C<Int64>

Objects that are copied to the data destination.

=item * C<< $msg->bytes_copied_count() >> / C<< $msg->bytes_copied_count($value) >>

Type: C<Int64>

Bytes that are copied to the data destination.

=item * C<< $msg->objects_failed_count() >> / C<< $msg->objects_failed_count($value) >>

Type: C<Int64>

Output only. Objects that are failed to write to the data destination.

=item * C<< $msg->bytes_failed_count() >> / C<< $msg->bytes_failed_count($value) >>

Type: C<Int64>

Output only. Bytes that are failed to write to the data destination.

=back

=head2 Google::Cloud::Lustre::V1::Transfer::ErrorLogEntry

An entry describing an error that has occurred.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->uri() >> / C<< $msg->uri($value) >>

Type: C<String>

Required. A URL that refers to the target (a data source, a data sink,
or an object) with which the error is associated.

=item * C<< $msg->error_details() >> / C<< $msg->error_details($value) >>

Type: C<String>

A list of messages that carry the error details.

=back

=head2 Google::Cloud::Lustre::V1::Transfer::ErrorSummary

A summary of errors by error code, plus a count and sample error log
entries.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->error_code() >> / C<< $msg->error_code($value) >>

Type: C<Enum> (L<Google::Rpc::Code>)

Required.

=item * C<< $msg->error_count() >> / C<< $msg->error_count($value) >>

Type: C<Int64>

Required. Count of this type of error.

=item * C<< $msg->error_log_entries() >> / C<< $msg->error_log_entries($value) >>

Type: C<Message> (L<Google::Cloud::Lustre::V1::Transfer::ErrorLogEntry>)

Error samples.

At most 5 error log entries are recorded for a given
error code for a single transfer operation.

=back

=head2 Google::Cloud::Lustre::V1::Transfer::TransferOperationMetadata

Represents the metadata of the long-running transfer operation.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->source_lustre_path() >> / C<< $msg->source_lustre_path($value) >>

Type: C<Message> (L<Google::Cloud::Lustre::V1::Transfer::LustrePath>)

Output only. Lustre source.

=item * C<< $msg->source_gcs_path() >> / C<< $msg->source_gcs_path($value) >>

Type: C<Message> (L<Google::Cloud::Lustre::V1::Transfer::GcsPath>)

Output only. Cloud Storage source.

=item * C<< $msg->destination_gcs_path() >> / C<< $msg->destination_gcs_path($value) >>

Type: C<Message> (L<Google::Cloud::Lustre::V1::Transfer::GcsPath>)

Output only. Cloud Storage destination.

=item * C<< $msg->destination_lustre_path() >> / C<< $msg->destination_lustre_path($value) >>

Type: C<Message> (L<Google::Cloud::Lustre::V1::Transfer::LustrePath>)

Output only. Lustre destination.

=item * C<< $msg->counters() >> / C<< $msg->counters($value) >>

Type: C<Message> (L<Google::Cloud::Lustre::V1::Transfer::TransferCounters>)

Output only. The progress of the transfer operation.

=item * C<< $msg->transfer_type() >> / C<< $msg->transfer_type($value) >>

Type: C<Enum> (L<Google::Cloud::Lustre::V1::TransferType>)

Output only. The type of transfer occurring.

=item * C<< $msg->error_summaries() >> / C<< $msg->error_summaries($value) >>

Type: C<Message> (L<Google::Cloud::Lustre::V1::Transfer::ErrorSummary>)

Output only. Error summary about the transfer operation

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Lustre::V1::Transfer::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
