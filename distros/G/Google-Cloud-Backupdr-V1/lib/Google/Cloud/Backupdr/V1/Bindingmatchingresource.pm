package Google::Cloud::Backupdr::V1::Bindingmatchingresource;

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
    eval { require Google::Protobuf::Timestamp };
    eval { require Google::Rpc::Status };
    my $descriptor_b64 = <<'EOF';
CjZnb29nbGUvY2xvdWQvYmFja3VwZHIvdjEvYmluZGluZ21hdGNoaW5ncmVzb3VyY2UucHJv
dG8SGGdvb2dsZS5jbG91ZC5iYWNrdXBkci52MRofZ29vZ2xlL2FwaS9maWVsZF9iZWhhdmlv
ci5wcm90bxoZZ29vZ2xlL2FwaS9yZXNvdXJjZS5wcm90bxofZ29vZ2xlL3Byb3RvYnVmL3Rp
bWVzdGFtcC5wcm90bxoXZ29vZ2xlL3JwYy9zdGF0dXMucHJvdG8i+QEKI0xpc3RCaW5kaW5n
TWF0Y2hpbmdSZXNvdXJjZXNSZXF1ZXN0Ek8KBnBhcmVudBgBIAEoCUI34EEC+kExEi9iYWNr
dXBkci5nb29nbGVhcGlzLmNvbS9CaW5kaW5nTWF0Y2hpbmdSZXNvdXJjZVIGcGFyZW50EiAK
CXBhZ2Vfc2l6ZRgCIAEoBUID4EEBUghwYWdlU2l6ZRIiCgpwYWdlX3Rva2VuGAMgASgJQgPg
QQFSCXBhZ2VUb2tlbhIbCgZmaWx0ZXIYBCABKAlCA+BBAVIGZmlsdGVyEh4KCG9yZGVyX2J5
GAUgASgJQgPgQQFSB29yZGVyQnkisAEKJExpc3RCaW5kaW5nTWF0Y2hpbmdSZXNvdXJjZXNS
ZXNwb25zZRJgChJtYXRjaGluZ19yZXNvdXJjZXMYASADKAsyMS5nb29nbGUuY2xvdWQuYmFj
a3VwZHIudjEuQmluZGluZ01hdGNoaW5nUmVzb3VyY2VSEW1hdGNoaW5nUmVzb3VyY2VzEiYK
D25leHRfcGFnZV90b2tlbhgCIAEoCVINbmV4dFBhZ2VUb2tlbiKVBAoXQmluZGluZ01hdGNo
aW5nUmVzb3VyY2USGgoEbmFtZRgBIAEoCUIG4EEI4EEDUgRuYW1lEh8KCHJlc291cmNlGAIg
ASgJQgPgQQNSCHJlc291cmNlElEKFGxhc3RfZXZhbHVhdGlvbl90aW1lGAMgASgLMhouZ29v
Z2xlLnByb3RvYnVmLlRpbWVzdGFtcEID4EEDUhJsYXN0RXZhbHVhdGlvblRpbWUSbAoXYXV0
b19wcm90ZWN0aW9uX2RldGFpbHMYBCABKAsyLy5nb29nbGUuY2xvdWQuYmFja3VwZHIudjEu
QXV0b1Byb3RlY3Rpb25EZXRhaWxzQgPgQQNSFWF1dG9Qcm90ZWN0aW9uRGV0YWlsczr7AepB
9wEKL2JhY2t1cGRyLmdvb2dsZWFwaXMuY29tL0JpbmRpbmdNYXRjaGluZ1Jlc291cmNlEpAB
cHJvamVjdHMve3Byb2plY3R9L2xvY2F0aW9ucy97bG9jYXRpb259L2F1dG9Qcm90ZWN0aW9u
UG9saWNpZXMve2F1dG9fcHJvdGVjdGlvbl9wb2xpY3l9L2JpbmRpbmdzL3tiaW5kaW5nfS9t
YXRjaGluZ1Jlc291cmNlcy97bWF0Y2hpbmdfcmVzb3VyY2V9KhhiaW5kaW5nTWF0Y2hpbmdS
ZXNvdXJjZXMyF2JpbmRpbmdNYXRjaGluZ1Jlc291cmNlIsUDChVBdXRvUHJvdGVjdGlvbkRl
dGFpbHMSUAoFc3RhdGUYASABKA4yNS5nb29nbGUuY2xvdWQuYmFja3VwZHIudjEuQXV0b1By
b3RlY3Rpb25EZXRhaWxzLlN0YXRlQgPgQQNSBXN0YXRlEm0KF2JhY2t1cF9wbGFuX2Fzc29j
aWF0aW9uGAIgASgJQjXgQQP6QS8KLWJhY2t1cGRyLmdvb2dsZWFwaXMuY29tL0JhY2t1cFBs
YW5Bc3NvY2lhdGlvblIVYmFja3VwUGxhbkFzc29jaWF0aW9uEksKC2RhdGFfc291cmNlGAMg
ASgJQirgQQP6QSQKImJhY2t1cGRyLmdvb2dsZWFwaXMuY29tL0RhdGFTb3VyY2VSCmRhdGFT
b3VyY2USLQoFZXJyb3IYBCABKAsyEi5nb29nbGUucnBjLlN0YXR1c0ID4EEDUgVlcnJvciJv
CgVTdGF0ZRIVChFTVEFURV9VTlNQRUNJRklFRBAAEg0KCVBST1RFQ1RFRBABEhUKEVBST1RF
Q1RJT05fRkFJTEVEEAISEAoMVU5QUk9URUNUSU5HEAMSFwoTVU5QUk9URUNUSU9OX0ZBSUxF
RBAEQswBChxjb20uZ29vZ2xlLmNsb3VkLmJhY2t1cGRyLnYxQhxCaW5kaW5nTWF0Y2hpbmdS
ZXNvdXJjZVByb3RvUAFaOGNsb3VkLmdvb2dsZS5jb20vZ28vYmFja3VwZHIvYXBpdjEvYmFj
a3VwZHJwYjtiYWNrdXBkcnBiqgIYR29vZ2xlLkNsb3VkLkJhY2t1cERSLlYxygIYR29vZ2xl
XENsb3VkXEJhY2t1cERSXFYx6gIbR29vZ2xlOjpDbG91ZDo6QmFja3VwRFI6OlYxSrwvCgcS
BQ4ApwEBCrwECgEMEgMOABIysQQgQ29weXJpZ2h0IDIwMjYgR29vZ2xlIExMQwoKIExpY2Vu
c2VkIHVuZGVyIHRoZSBBcGFjaGUgTGljZW5zZSwgVmVyc2lvbiAyLjAgKHRoZSAiTGljZW5z
ZSIpOwogeW91IG1heSBub3QgdXNlIHRoaXMgZmlsZSBleGNlcHQgaW4gY29tcGxpYW5jZSB3
aXRoIHRoZSBMaWNlbnNlLgogWW91IG1heSBvYnRhaW4gYSBjb3B5IG9mIHRoZSBMaWNlbnNl
IGF0CgogICAgIGh0dHA6Ly93d3cuYXBhY2hlLm9yZy9saWNlbnNlcy9MSUNFTlNFLTIuMAoK
IFVubGVzcyByZXF1aXJlZCBieSBhcHBsaWNhYmxlIGxhdyBvciBhZ3JlZWQgdG8gaW4gd3Jp
dGluZywgc29mdHdhcmUKIGRpc3RyaWJ1dGVkIHVuZGVyIHRoZSBMaWNlbnNlIGlzIGRpc3Ry
aWJ1dGVkIG9uIGFuICJBUyBJUyIgQkFTSVMsCiBXSVRIT1VUIFdBUlJBTlRJRVMgT1IgQ09O
RElUSU9OUyBPRiBBTlkgS0lORCwgZWl0aGVyIGV4cHJlc3Mgb3IgaW1wbGllZC4KIFNlZSB0
aGUgTGljZW5zZSBmb3IgdGhlIHNwZWNpZmljIGxhbmd1YWdlIGdvdmVybmluZyBwZXJtaXNz
aW9ucyBhbmQKIGxpbWl0YXRpb25zIHVuZGVyIHRoZSBMaWNlbnNlLgoKCAoBAhIDEAAhCgkK
AgMAEgMSACkKCQoCAwESAxMAIwoJCgIDAhIDFAApCgkKAgMDEgMVACEKCAoBCBIDFwA1CgkK
AgglEgMXADUKCAoBCBIDGABPCgkKAggLEgMYAE8KCAoBCBIDGQAiCgkKAggKEgMZACIKCAoB
CBIDGgA9CgkKAggIEgMaAD0KCAoBCBIDGwA1CgkKAggBEgMbADUKCAoBCBIDHAA1CgkKAggp
EgMcADUKCAoBCBIDHQA0CgkKAggtEgMdADQKQAoCBAASBCAAQgEaNCBSZXF1ZXN0IG1lc3Nh
Z2UgZm9yIExpc3QgQmluZGluZ01hdGNoaW5nUmVzb3VyY2VzLgoKCgoDBAABEgMgCCsK7wIK
BAQAAgASBCYCKwQa4AIgUmVxdWlyZWQuIFRoZSBwcm9qZWN0LCBsb2NhdGlvbiwgYXV0byBw
cm90ZWN0aW9uIHBvbGljeSBhbmQgYmluZGluZyBmb3IKIHdoaWNoIHRvIHJldHJpZXZlIGBC
aW5kaW5nTWF0Y2hpbmdSZXNvdXJjZXNgIGluZm9ybWF0aW9uLiBGb3JtYXQ6CiBgcHJvamVj
dHMve3Byb2plY3R9L2xvY2F0aW9ucy97bG9jYXRpb259L2F1dG9Qcm90ZWN0aW9uUG9saWNp
ZXMve2F1dG9fcHJvdGVjdGlvbl9wb2xpY3l9L2JpbmRpbmdzL3tiaW5kaW5nfWAuCiBJbiBH
b29nbGUgQ2xvdWQgQmFja3VwIGFuZCBEUiwgbG9jYXRpb25zIG1hcCB0byBHb29nbGUgQ2xv
dWQgcmVnaW9ucywgZm9yCiBleGFtcGxlICoqdXMtY2VudHJhbDEqKi4KCgwKBQQAAgAFEgMm
AggKDAoFBAACAAESAyYJDwoMCgUEAAIAAxIDJhITCg0KBQQAAgAIEgQmFCsDCg8KCAQAAgAI
nAgAEgMnBCoKDwoHBAACAAifCBIEKAQqBQqqAwoEBAACARIDMwI/GpwDIE9wdGlvbmFsLiBU
aGUgbWF4aW11bSBudW1iZXIgb2YgYEJpbmRpbmdNYXRjaGluZ1Jlc291cmNlc2AgdG8gcmV0
dXJuIGluIGEKIHNpbmdsZSByZXNwb25zZS4gVGhlIGRlZmF1bHQgcGFnZSBzaXplIGlzIDEw
MCBhbmQgbWF4aW11bSBwYWdlIHNpemUgaXMgMjAwLgogTm90ZSB0aGF0IHRoZSByZXNwb25z
ZSBtYXkgaW5jbHVkZSBhIHBhcnRpYWwgbGlzdCBhbmQgYSBjYWxsZXIgc2hvdWxkCiBvbmx5
IHJlbHkgb24gdGhlIHJlc3BvbnNlJ3MKIFtuZXh0X3BhZ2VfdG9rZW5dW2dvb2dsZS5jbG91
ZC5iYWNrdXBkci52MS5MaXN0QmluZGluZ01hdGNoaW5nUmVzb3VyY2VzUmVzcG9uc2UubmV4
dF9wYWdlX3Rva2VuXQogdG8gZGV0ZXJtaW5lIGlmIHRoZXJlIGFyZSBtb3JlIGluc3RhbmNl
cyBsZWZ0IHRvIGJlIHF1ZXJpZWQuCgoMCgUEAAIBBRIDMwIHCgwKBQQAAgEBEgMzCBEKDAoF
BAACAQMSAzMUFQoMCgUEAAIBCBIDMxY+Cg8KCAQAAgEInAgAEgMzFz0KmwMKBAQAAgISAzsC
QRqNAyBPcHRpb25hbC4gVGhlIHZhbHVlIG9mCiBbbmV4dF9wYWdlX3Rva2VuXVtnb29nbGUu
Y2xvdWQuYmFja3VwZHIudjEuTGlzdEJpbmRpbmdNYXRjaGluZ1Jlc291cmNlc1Jlc3BvbnNl
Lm5leHRfcGFnZV90b2tlbl0KIHJlY2VpdmVkIGZyb20gYSBwcmV2aW91cyBgTGlzdEJpbmRp
bmdNYXRjaGluZ1Jlc291cmNlc2AgY2FsbC4gUHJvdmlkZSB0aGlzCiB0byByZXRyaWV2ZSB0
aGUgc3Vic2VxdWVudCBwYWdlIGluIGEgbXVsdGktcGFnZSBsaXN0IG9mIHJlc3VsdHMuIFdo
ZW4KIHBhZ2luYXRpbmcsIGFsbCBvdGhlciBwYXJhbWV0ZXJzIHByb3ZpZGVkIHRvIGBMaXN0
QmluZGluZ01hdGNoaW5nUmVzb3VyY2VzYAogbXVzdCBtYXRjaCB0aGUgY2FsbCB0aGF0IHBy
b3ZpZGVkIHRoZSBwYWdlIHRva2VuLgoKDAoFBAACAgUSAzsCCAoMCgUEAAICARIDOwkTCgwK
BQQAAgIDEgM7FhcKDAoFBAACAggSAzsYQAoPCggEAAICCJwIABIDOxk/CksKBAQAAgMSAz4C
PRo+IE9wdGlvbmFsLiBGaWVsZCBtYXRjaCBleHByZXNzaW9uIHVzZWQgdG8gZmlsdGVyIHRo
ZSByZXN1bHRzLgoKDAoFBAACAwUSAz4CCAoMCgUEAAIDARIDPgkPCgwKBQQAAgMDEgM+EhMK
DAoFBAACAwgSAz4UPAoPCggEAAIDCJwIABIDPhU7CjwKBAQAAgQSA0ECPxovIE9wdGlvbmFs
LiBGaWVsZCBieSB3aGljaCB0byBzb3J0IHRoZSByZXN1bHRzLgoKDAoFBAACBAUSA0ECCAoM
CgUEAAIEARIDQQkRCgwKBQQAAgQDEgNBFBUKDAoFBAACBAgSA0EWPgoPCggEAAIECJwIABID
QRc9ClQKAgQBEgRFAFABGkggVGhlIHJlc3BvbnNlIG1lc3NhZ2UgZm9yIGdldHRpbmcgYSBs
aXN0IG9mIGBCaW5kaW5nTWF0Y2hpbmdSZXNvdXJjZXNgLgoKCgoDBAEBEgNFCCwKaQoEBAEC
ABIDSAI6GlwgVGhlIGxpc3Qgb2YgYEJpbmRpbmdNYXRjaGluZ1Jlc291cmNlc2AgaW4gdGhl
IHByb2plY3QsbG9jYXRpb24gZm9yIHRoZQogc3BlY2lmaWVkIGJpbmRpbmcuCgoMCgUEAQIA
BBIDSAIKCgwKBQQBAgAGEgNICyIKDAoFBAECAAESA0gjNQoMCgUEAQIAAxIDSDg5Cq0CCgQE
AQIBEgNPAh0anwIgQSB0b2tlbiB3aGljaCBtYXkgYmUgc2VudCBhcwogW3BhZ2VfdG9rZW5d
W2dvb2dsZS5jbG91ZC5iYWNrdXBkci52MS5MaXN0QmluZGluZ01hdGNoaW5nUmVzb3VyY2Vz
UmVxdWVzdC5wYWdlX3Rva2VuXQogaW4gYSBzdWJzZXF1ZW50IGBMaXN0QmluZGluZ01hdGNo
aW5nUmVzb3VyY2VzYCBjYWxsIHRvIHJldHJpZXZlIHRoZSBuZXh0CiBwYWdlIG9mIHJlc3Vs
dHMuIElmIHRoaXMgZmllbGQgaXMgb21pdHRlZCBvciBlbXB0eSwgdGhlbiB0aGVyZSBhcmUg
bm8gbW9yZQogcmVzdWx0cyB0byByZXR1cm4uCgoMCgUEAQIBBRIDTwIICgwKBQQBAgEBEgNP
CRgKDAoFBAECAQMSA08bHApxCgIEAhIEVAB2ARplIEJpbmRpbmdNYXRjaGluZ1Jlc291cmNl
IGNvbnRhaW5zIHRoZSBkZXRhaWxzIG9mIGEgcmVzb3VyY2UgdGhhdCBtYXRjaGVzIHRoZQog
Y3JpdGVyaWEgb2YgYSBiaW5kaW5nLgoKCgoDBAIBEgNUCB8KCwoDBAIHEgRVAloECg0KBQQC
B50IEgRVAloECvoBCgQEAgIAEgRfAmIEGusBIE91dHB1dCBvbmx5LiBJZGVudGlmaWVyLiBU
aGUgcmVzb3VyY2UgbmFtZSBvZiB0aGUKIGBCaW5kaW5nTWF0Y2hpbmdSZXNvdXJjZWAuIEZv
cm1hdDoKIGBwcm9qZWN0cy97cHJvamVjdH0vbG9jYXRpb25zL3tsb2NhdGlvbn0vYXV0b1By
b3RlY3Rpb25Qb2xpY2llcy97YXV0b19wcm90ZWN0aW9uX3BvbGljeX0vYmluZGluZ3Mve2Jp
bmRpbmd9L21hdGNoaW5nUmVzb3VyY2VzL3ttYXRjaGluZ19yZXNvdXJjZX1gCgoMCgUEAgIA
BRIDXwIICgwKBQQCAgABEgNfCQ0KDAoFBAICAAMSA18QEQoNCgUEAgIACBIEXxJiAwoPCggE
AgIACJwIABIDYAQsCg8KCAQCAgAInAgBEgNhBC0K6QIKBAQCAgESA2sCQhrbAiBPdXRwdXQg
b25seS4gUmVzb3VyY2UgbmFtZSBvZiB0aGUgd29ya2xvYWQgdGhhdCBtYXRjaGVzIHRoZSBj
cml0ZXJpYSBvZiB0aGUKIGJpbmRpbmcuCgogVGhlIGZvcm1hdCBjYW4gYmUgZWl0aGVyIGEg
cmVsYXRpdmUgcmVzb3VyY2UgbmFtZSAoZS5nLiwKIGBwcm9qZWN0cy9teS1wcm9qZWN0L3pv
bmVzL3VzLWNlbnRyYWwxLWEvaW5zdGFuY2VzL215LWluc3RhbmNlYCkgb3IgYQogc2NoZW1l
bGVzcyBmdWxsIHJlc291cmNlIG5hbWUgKGUuZy4sCiBgLy9jb21wdXRlLmdvb2dsZWFwaXMu
Y29tL3Byb2plY3RzL215LXByb2plY3Qvem9uZXMvdXMtY2VudHJhbDEtYS9pbnN0YW5jZXMv
bXktaW5zdGFuY2VgKS4KCgwKBQQCAgEFEgNrAggKDAoFBAICAQESA2sJEQoMCgUEAgIBAxID
axQVCgwKBQQCAgEIEgNrFkEKDwoIBAICAQicCAASA2sXQApgCgQEAgICEgRvAnAyGlIgT3V0
cHV0IG9ubHkuIFRoZSB0aW1lc3RhbXAgd2hlbiB0aGUgcmVzb3VyY2Ugd2FzIGxhc3QgZXZh
bHVhdGVkIGZvcgogcHJvdGVjdGlvbi4KCgwKBQQCAgIGEgNvAhsKDAoFBAICAgESA28cMAoM
CgUEAgICAxIDbzM0CgwKBQQCAgIIEgNwBjEKDwoIBAICAgicCAASA3AHMApxCgQEAgIDEgR0
AnUyGmMgT3V0cHV0IG9ubHkuIFRoZSBhdXRvIHByb3RlY3Rpb24gZGV0YWlscyBvZiB0aGUg
cmVzb3VyY2UgZnJvbSB0aGUgY3VycmVudAogYmluZGluZydzIHBlcnNwZWN0aXZlLgoKDAoF
BAICAwYSA3QCFwoMCgUEAgIDARIDdBgvCgwKBQQCAgMDEgN0MjMKDAoFBAICAwgSA3UGMQoP
CggEAgIDCJwIABIDdQcwCnsKAgQDEgV6AKcBARpuIEF1dG9Qcm90ZWN0aW9uRGV0YWlscyBj
b250YWlucyB0aGUgcHJvdGVjdGlvbiBkZXRhaWxzIG9mIGEgcmVzb3VyY2UgZnJvbSB0aGUK
IGN1cnJlbnQgYmluZGluZydzIHBlcnNwZWN0aXZlLgoKCgoDBAMBEgN6CB0KOwoEBAMEABIF
fAKLAQMaLCBFbnVtIGZvciBwcm90ZWN0aW9uIHN0YXRlIG9mIHRoZSByZXNvdXJjZS4KCgwK
BQQDBAABEgN8BwwKIwoGBAMEAAIAEgN+BBoaFCBTdGF0ZSB1bnNwZWNpZmllZC4KCg4KBwQD
BAACAAESA34EFQoOCgcEAwQAAgACEgN+GBkKKAoGBAMEAAIBEgSBAQQSGhggUmVzb3VyY2Ug
aXMgcHJvdGVjdGVkLgoKDwoHBAMEAAIBARIEgQEEDQoPCgcEAwQAAgECEgSBARARCi0KBgQD
BAACAhIEhAEEGhodIFJlc291cmNlIHByb3RlY3Rpb24gZmFpbGVkLgoKDwoHBAMEAAICARIE
hAEEFQoPCgcEAwQAAgICEgSEARgZCjAKBgQDBAACAxIEhwEEFRogIFJlc291cmNlIGlzIGJl
aW5nIHVucHJvdGVjdGVkLgoKDwoHBAMEAAIDARIEhwEEEAoPCgcEAwQAAgMCEgSHARMUCi8K
BgQDBAACBBIEigEEHBofIFJlc291cmNlIHVucHJvdGVjdGlvbiBmYWlsZWQuCgoPCgcEAwQA
AgQBEgSKAQQXCg8KBwQDBAACBAISBIoBGhsKcwoEBAMCABIEjwECPhplIE91dHB1dCBvbmx5
LiBQcm90ZWN0aW9uIHN0YXRlIG9mIHRoZSByZXNvdXJjZSBmcm9tIHRoZSBjdXJyZW50IGJp
bmRpbmcncwogcGVyc3BlY3RpdmUuIE91dHB1dCBvbmx5LgoKDQoFBAMCAAYSBI8BAgcKDQoF
BAMCAAESBI8BCA0KDQoFBAMCAAMSBI8BEBEKDQoFBAMCAAgSBI8BEj0KEAoIBAMCAAicCAAS
BI8BEzwKywEKBAQDAgESBpQBApkBBBq6ASBPdXRwdXQgb25seS4gUmVzb3VyY2UgbmFtZSBv
ZiBiYWNrdXAgcGxhbiBhc3NvY2lhdGlvbiBsaW5rZWQgdG8gdGhlCiByZXNvdXJjZSwgaWYg
YW55LiBGb3JtYXQ6CiBwcm9qZWN0cy97cHJvamVjdH0vbG9jYXRpb25zL3tsb2NhdGlvbn0v
YmFja3VwUGxhbkFzc29jaWF0aW9ucy97YmFja3VwUGxhbkFzc29jaWF0aW9uSWR9CgoNCgUE
AwIBBRIElAECCAoNCgUEAwIBARIElAEJIAoNCgUEAwIBAxIElAEjJAoPCgUEAwIBCBIGlAEl
mQEDChAKCAQDAgEInAgAEgSVAQQtChEKBwQDAgEInwgSBpYBBJgBBQrJAQoEBAMCAhIGngEC
owEEGrgBIE91dHB1dCBvbmx5LiBSZXNvdXJjZSBuYW1lIG9mIHRoZSBkYXRhc291cmNlIGxp
bmtlZCB0byB0aGUgcmVzb3VyY2UsIGlmCiBhbnkuIEZvcm1hdDoKIHByb2plY3RzL3twcm9q
ZWN0fS9sb2NhdGlvbnMve2xvY2F0aW9ufS9iYWNrdXBWYXVsdHMve2JhY2t1cFZhdWx0SWR9
L2RhdGFTb3VyY2VzL3tkYXRhU291cmNlSWR9CgoNCgUEAwICBRIEngECCAoNCgUEAwICARIE
ngEJFAoNCgUEAwICAxIEngEXGAoPCgUEAwICCBIGngEZowEDChAKCAQDAgIInAgAEgSfAQQt
ChEKBwQDAgIInwgSBqABBKIBBQpYCgQEAwIDEgSmAQJKGkogT3V0cHV0IG9ubHkuIEVycm9y
IGR1cmluZyBsYXN0IHN5bmMgZm9yIHByb3RlY3Rpb24vdW5wcm90ZWN0aW9uLCBpZiBhbnku
CgoNCgUEAwIDBhIEpgECEwoNCgUEAwIDARIEpgEUGQoNCgUEAwIDAxIEpgEcHQoNCgUEAwID
CBIEpgEeSQoQCggEAwIDCJwIABIEpgEfSGIGcHJvdG8z
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Backupdr::V1::Bindingmatchingresource::ListBindingMatchingResourcesRequest ===
    # Fields for ListBindingMatchingResourcesRequest
    # Field: parent Type: 9 ()
    # Field: page_size Type: 5 ()
    # Field: page_token Type: 9 ()
    # Field: filter Type: 9 ()
    # Field: order_by Type: 9 ()

# === Message: Google::Cloud::Backupdr::V1::Bindingmatchingresource::ListBindingMatchingResourcesResponse ===
    # Fields for ListBindingMatchingResourcesResponse
    # Field: matching_resources Type: 11 (.google.cloud.backupdr.v1.BindingMatchingResource)
    # Field: next_page_token Type: 9 ()

# === Message: Google::Cloud::Backupdr::V1::Bindingmatchingresource::BindingMatchingResource ===
    # Fields for BindingMatchingResource
    # Field: name Type: 9 ()
    # Field: resource Type: 9 ()
    # Field: last_evaluation_time Type: 11 (.google.protobuf.Timestamp)
    # Field: auto_protection_details Type: 11 (.google.cloud.backupdr.v1.AutoProtectionDetails)

# === Message: Google::Cloud::Backupdr::V1::Bindingmatchingresource::AutoProtectionDetails ===
    # Fields for AutoProtectionDetails
    # Field: state Type: 14 (.google.cloud.backupdr.v1.AutoProtectionDetails.State)
    # Field: backup_plan_association Type: 9 ()
    # Field: data_source Type: 9 ()
    # Field: error Type: 11 (.google.rpc.Status)

# Enum: AutoProtectionDetails::State
our $AutoProtectionDetails_STATE_UNSPECIFIED = 0;
our $AutoProtectionDetails_PROTECTED = 1;
our $AutoProtectionDetails_PROTECTION_FAILED = 2;
our $AutoProtectionDetails_UNPROTECTING = 3;
our $AutoProtectionDetails_UNPROTECTION_FAILED = 4;

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Backupdr::V1::Bindingmatchingresource - Compiled Protocol Buffers messages for google/cloud/backupdr/v1/bindingmatchingresource.proto

=head1 SYNOPSIS

    use Google::Cloud::Backupdr::V1::Bindingmatchingresource;

    my $msg = Google::Cloud::Backupdr::V1::Bindingmatchingresource::ListBindingMatchingResourcesRequest->new({
        parent => $parent,
        page_size => $page_size,
        page_token => $page_token,
        filter => $filter,
    });

    # Read or update a field
    my $val = $msg->parent();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Backupdr::V1::Bindingmatchingresource::ListBindingMatchingResourcesRequest->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/backupdr/v1/bindingmatchingresource.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Backupdr::V1::Bindingmatchingresource::ListBindingMatchingResourcesRequest

Request message for List BindingMatchingResources.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->parent() >> / C<< $msg->parent($value) >>

Type: C<String>

Required. The project, location, auto protection policy and binding for
which to retrieve `BindingMatchingResources` information. Format:
`projects/{project}/locations/{location}/autoProtectionPolicies/{auto_protection_policy}/bindings/{binding}`.
In Google Cloud Backup and DR, locations map to Google Cloud regions, for
example B<us-central1>.

=item * C<< $msg->page_size() >> / C<< $msg->page_size($value) >>

Type: C<Int32>

Optional. The maximum number of `BindingMatchingResources` to return in a
single response. The default page size is 100 and maximum page size is 200.
Note that the response may include a partial list and a caller should
only rely on the response's
[next_page_token][google.cloud.backupdr.v1.ListBindingMatchingResourcesResponse.next_page_token]
to determine if there are more instances left to be queried.

=item * C<< $msg->page_token() >> / C<< $msg->page_token($value) >>

Type: C<String>

Optional. The value of
[next_page_token][google.cloud.backupdr.v1.ListBindingMatchingResourcesResponse.next_page_token]
received from a previous `ListBindingMatchingResources` call. Provide this
to retrieve the subsequent page in a multi-page list of results. When
paginating, all other parameters provided to `ListBindingMatchingResources`
must match the call that provided the page token.

=item * C<< $msg->filter() >> / C<< $msg->filter($value) >>

Type: C<String>

Optional. Field match expression used to filter the results.

=item * C<< $msg->order_by() >> / C<< $msg->order_by($value) >>

Type: C<String>

Optional. Field by which to sort the results.

=back

=head2 Google::Cloud::Backupdr::V1::Bindingmatchingresource::ListBindingMatchingResourcesResponse

The response message for getting a list of `BindingMatchingResources`.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->matching_resources() >> / C<< $msg->matching_resources($value) >>

Type: C<Message> (L<Google::Cloud::Backupdr::V1::Bindingmatchingresource::BindingMatchingResource>)

The list of `BindingMatchingResources` in the project,location for the
specified binding.

=item * C<< $msg->next_page_token() >> / C<< $msg->next_page_token($value) >>

Type: C<String>

A token which may be sent as
[page_token][google.cloud.backupdr.v1.ListBindingMatchingResourcesRequest.page_token]
in a subsequent `ListBindingMatchingResources` call to retrieve the next
page of results. If this field is omitted or empty, then there are no more
results to return.

=back

=head2 Google::Cloud::Backupdr::V1::Bindingmatchingresource::BindingMatchingResource

BindingMatchingResource contains the details of a resource that matches the
criteria of a binding.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Output only. Identifier. The resource name of the
`BindingMatchingResource`. Format:
`projects/{project}/locations/{location}/autoProtectionPolicies/{auto_protection_policy}/bindings/{binding}/matchingResources/{matching_resource}`

=item * C<< $msg->resource() >> / C<< $msg->resource($value) >>

Type: C<String>

Output only. Resource name of the workload that matches the criteria of the
binding.

The format can be either a relative resource name (e.g.,
`projects/my-project/zones/us-central1-a/instances/my-instance`) or a
schemeless full resource name (e.g.,
`//compute.googleapis.com/projects/my-project/zones/us-central1-a/instances/my-instance`).

=item * C<< $msg->last_evaluation_time() >> / C<< $msg->last_evaluation_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Output only. The timestamp when the resource was last evaluated for
protection.

=item * C<< $msg->auto_protection_details() >> / C<< $msg->auto_protection_details($value) >>

Type: C<Message> (L<Google::Cloud::Backupdr::V1::Bindingmatchingresource::AutoProtectionDetails>)

Output only. The auto protection details of the resource from the current
binding's perspective.

=back

=head2 Google::Cloud::Backupdr::V1::Bindingmatchingresource::AutoProtectionDetails

AutoProtectionDetails contains the protection details of a resource from the
current binding's perspective.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->state() >> / C<< $msg->state($value) >>

Type: C<Enum> (L<Google::Cloud::Backupdr::V1::AutoProtectionDetails::State>)

Output only. Protection state of the resource from the current binding's
perspective. Output only.

=item * C<< $msg->backup_plan_association() >> / C<< $msg->backup_plan_association($value) >>

Type: C<String>

Output only. Resource name of backup plan association linked to the
resource, if any. Format:
projects/{project}/locations/{location}/backupPlanAssociations/{backupPlanAssociationId}

=item * C<< $msg->data_source() >> / C<< $msg->data_source($value) >>

Type: C<String>

Output only. Resource name of the datasource linked to the resource, if
any. Format:
projects/{project}/locations/{location}/backupVaults/{backupVaultId}/dataSources/{dataSourceId}

=item * C<< $msg->error() >> / C<< $msg->error($value) >>

Type: C<Message> (L<Google::Rpc::Status::Status>)

Output only. Error during last sync for protection/unprotection, if any.

=back

=head3 Enum: AutoProtectionDetails::State

=over 4

=item * C<STATE_UNSPECIFIED> => C<0>

=item * C<PROTECTED> => C<1>

=item * C<PROTECTION_FAILED> => C<2>

=item * C<UNPROTECTING> => C<3>

=item * C<UNPROTECTION_FAILED> => C<4>

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Backupdr::V1::Bindingmatchingresource::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
