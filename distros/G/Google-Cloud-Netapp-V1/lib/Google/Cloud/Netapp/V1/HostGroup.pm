package Google::Cloud::Netapp::V1::HostGroup;

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
    eval { require Google::Cloud::Netapp::V1::Common };
    eval { require Google::Protobuf::FieldMask };
    eval { require Google::Protobuf::Timestamp };
    my $descriptor_b64 = <<'EOF';
Cidnb29nbGUvY2xvdWQvbmV0YXBwL3YxL2hvc3RfZ3JvdXAucHJvdG8SFmdvb2dsZS5jbG91
ZC5uZXRhcHAudjEaH2dvb2dsZS9hcGkvZmllbGRfYmVoYXZpb3IucHJvdG8aGWdvb2dsZS9h
cGkvcmVzb3VyY2UucHJvdG8aI2dvb2dsZS9jbG91ZC9uZXRhcHAvdjEvY29tbW9uLnByb3Rv
GiBnb29nbGUvcHJvdG9idWYvZmllbGRfbWFzay5wcm90bxofZ29vZ2xlL3Byb3RvYnVmL3Rp
bWVzdGFtcC5wcm90byLbAQoVTGlzdEhvc3RHcm91cHNSZXF1ZXN0Ej8KBnBhcmVudBgBIAEo
CUIn4EEC+kEhEh9uZXRhcHAuZ29vZ2xlYXBpcy5jb20vSG9zdEdyb3VwUgZwYXJlbnQSIAoJ
cGFnZV9zaXplGAIgASgFQgPgQQFSCHBhZ2VTaXplEiIKCnBhZ2VfdG9rZW4YAyABKAlCA+BB
AVIJcGFnZVRva2VuEhsKBmZpbHRlchgEIAEoCUID4EEBUgZmaWx0ZXISHgoIb3JkZXJfYnkY
BSABKAlCA+BBAVIHb3JkZXJCeSKmAQoWTGlzdEhvc3RHcm91cHNSZXNwb25zZRJCCgtob3N0
X2dyb3VwcxgBIAMoCzIhLmdvb2dsZS5jbG91ZC5uZXRhcHAudjEuSG9zdEdyb3VwUgpob3N0
R3JvdXBzEiYKD25leHRfcGFnZV90b2tlbhgCIAEoCVINbmV4dFBhZ2VUb2tlbhIgCgt1bnJl
YWNoYWJsZRgDIAMoCVILdW5yZWFjaGFibGUiUgoTR2V0SG9zdEdyb3VwUmVxdWVzdBI7CgRu
YW1lGAEgASgJQifgQQL6QSEKH25ldGFwcC5nb29nbGVhcGlzLmNvbS9Ib3N0R3JvdXBSBG5h
bWUiyQEKFkNyZWF0ZUhvc3RHcm91cFJlcXVlc3QSPwoGcGFyZW50GAEgASgJQifgQQL6QSES
H25ldGFwcC5nb29nbGVhcGlzLmNvbS9Ib3N0R3JvdXBSBnBhcmVudBJFCgpob3N0X2dyb3Vw
GAIgASgLMiEuZ29vZ2xlLmNsb3VkLm5ldGFwcC52MS5Ib3N0R3JvdXBCA+BBAlIJaG9zdEdy
b3VwEicKDWhvc3RfZ3JvdXBfaWQYAyABKAlCA+BBAlILaG9zdEdyb3VwSWQioQEKFlVwZGF0
ZUhvc3RHcm91cFJlcXVlc3QSRQoKaG9zdF9ncm91cBgBIAEoCzIhLmdvb2dsZS5jbG91ZC5u
ZXRhcHAudjEuSG9zdEdyb3VwQgPgQQJSCWhvc3RHcm91cBJACgt1cGRhdGVfbWFzaxgCIAEo
CzIaLmdvb2dsZS5wcm90b2J1Zi5GaWVsZE1hc2tCA+BBAVIKdXBkYXRlTWFzayJVChZEZWxl
dGVIb3N0R3JvdXBSZXF1ZXN0EjsKBG5hbWUYASABKAlCJ+BBAvpBIQofbmV0YXBwLmdvb2ds
ZWFwaXMuY29tL0hvc3RHcm91cFIEbmFtZSKGBgoJSG9zdEdyb3VwEhcKBG5hbWUYASABKAlC
A+BBCFIEbmFtZRI/CgR0eXBlGAIgASgOMiYuZ29vZ2xlLmNsb3VkLm5ldGFwcC52MS5Ib3N0
R3JvdXAuVHlwZUID4EECUgR0eXBlEkIKBXN0YXRlGAMgASgOMicuZ29vZ2xlLmNsb3VkLm5l
dGFwcC52MS5Ib3N0R3JvdXAuU3RhdGVCA+BBA1IFc3RhdGUSQAoLY3JlYXRlX3RpbWUYBCAB
KAsyGi5nb29nbGUucHJvdG9idWYuVGltZXN0YW1wQgPgQQNSCmNyZWF0ZVRpbWUSGQoFaG9z
dHMYBSADKAlCA+BBAlIFaG9zdHMSPAoHb3NfdHlwZRgGIAEoDjIeLmdvb2dsZS5jbG91ZC5u
ZXRhcHAudjEuT3NUeXBlQgPgQQJSBm9zVHlwZRIlCgtkZXNjcmlwdGlvbhgHIAEoCUID4EEB
UgtkZXNjcmlwdGlvbhJKCgZsYWJlbHMYCCADKAsyLS5nb29nbGUuY2xvdWQubmV0YXBwLnYx
Lkhvc3RHcm91cC5MYWJlbHNFbnRyeUID4EEBUgZsYWJlbHMaOQoLTGFiZWxzRW50cnkSEAoD
a2V5GAEgASgJUgNrZXkSFAoFdmFsdWUYAiABKAlSBXZhbHVlOgI4ASIxCgRUeXBlEhQKEFRZ
UEVfVU5TUEVDSUZJRUQQABITCg9JU0NTSV9JTklUSUFUT1IQASJhCgVTdGF0ZRIVChFTVEFU
RV9VTlNQRUNJRklFRBAAEgwKCENSRUFUSU5HEAESCQoFUkVBRFkQAhIMCghVUERBVElORxAD
EgwKCERFTEVUSU5HEAQSDAoIRElTQUJMRUQQBTp86kF5Ch9uZXRhcHAuZ29vZ2xlYXBpcy5j
b20vSG9zdEdyb3VwEj9wcm9qZWN0cy97cHJvamVjdH0vbG9jYXRpb25zL3tsb2NhdGlvbn0v
aG9zdEdyb3Vwcy97aG9zdF9ncm91cH0qCmhvc3RHcm91cHMyCWhvc3RHcm91cEKwAQoaY29t
Lmdvb2dsZS5jbG91ZC5uZXRhcHAudjFCDkhvc3RHcm91cFByb3RvUAFaMmNsb3VkLmdvb2ds
ZS5jb20vZ28vbmV0YXBwL2FwaXYxL25ldGFwcHBiO25ldGFwcHBiqgIWR29vZ2xlLkNsb3Vk
Lk5ldEFwcC5WMcoCFkdvb2dsZVxDbG91ZFxOZXRBcHBcVjHqAhlHb29nbGU6OkNsb3VkOjpO
ZXRBcHA6OlYxSvUwCgcSBQ4AxAEBCrwECgEMEgMOABIysQQgQ29weXJpZ2h0IDIwMjYgR29v
Z2xlIExMQwoKIExpY2Vuc2VkIHVuZGVyIHRoZSBBcGFjaGUgTGljZW5zZSwgVmVyc2lvbiAy
LjAgKHRoZSAiTGljZW5zZSIpOwogeW91IG1heSBub3QgdXNlIHRoaXMgZmlsZSBleGNlcHQg
aW4gY29tcGxpYW5jZSB3aXRoIHRoZSBMaWNlbnNlLgogWW91IG1heSBvYnRhaW4gYSBjb3B5
IG9mIHRoZSBMaWNlbnNlIGF0CgogICAgIGh0dHA6Ly93d3cuYXBhY2hlLm9yZy9saWNlbnNl
cy9MSUNFTlNFLTIuMAoKIFVubGVzcyByZXF1aXJlZCBieSBhcHBsaWNhYmxlIGxhdyBvciBh
Z3JlZWQgdG8gaW4gd3JpdGluZywgc29mdHdhcmUKIGRpc3RyaWJ1dGVkIHVuZGVyIHRoZSBM
aWNlbnNlIGlzIGRpc3RyaWJ1dGVkIG9uIGFuICJBUyBJUyIgQkFTSVMsCiBXSVRIT1VUIFdB
UlJBTlRJRVMgT1IgQ09ORElUSU9OUyBPRiBBTlkgS0lORCwgZWl0aGVyIGV4cHJlc3Mgb3Ig
aW1wbGllZC4KIFNlZSB0aGUgTGljZW5zZSBmb3IgdGhlIHNwZWNpZmljIGxhbmd1YWdlIGdv
dmVybmluZyBwZXJtaXNzaW9ucyBhbmQKIGxpbWl0YXRpb25zIHVuZGVyIHRoZSBMaWNlbnNl
LgoKCAoBAhIDEAAfCgkKAgMAEgMSACkKCQoCAwESAxMAIwoJCgIDAhIDFAAtCgkKAgMDEgMV
ACoKCQoCAwQSAxYAKQoICgEIEgMYADMKCQoCCCUSAxgAMwoICgEIEgMZAEkKCQoCCAsSAxkA
SQoICgEIEgMaACIKCQoCCAoSAxoAIgoICgEIEgMbAC8KCQoCCAgSAxsALwoICgEIEgMcADMK
CQoCCAESAxwAMwoICgEIEgMdADMKCQoCCCkSAx0AMwoICgEIEgMeADIKCQoCCC0SAx4AMgo8
CgIEABIEIQA2ARowIExpc3RIb3N0R3JvdXBzUmVxdWVzdCBmb3IgbGlzdGluZyBob3N0IGdy
b3Vwcy4KCgoKAwQAARIDIQgdCkAKBAQAAgASBCMCKAQaMiBSZXF1aXJlZC4gUGFyZW50IHZh
bHVlIGZvciBMaXN0SG9zdEdyb3Vwc1JlcXVlc3QKCgwKBQQAAgAFEgMjAggKDAoFBAACAAES
AyMJDwoMCgUEAAIAAxIDIxITCg0KBQQAAgAIEgQjFCgDCg8KCAQAAgAInAgAEgMkBCoKDwoH
BAACAAifCBIEJQQnBQqaAQoEBAACARIDLAI/GowBIE9wdGlvbmFsLiBSZXF1ZXN0ZWQgcGFn
ZSBzaXplLiBTZXJ2ZXIgbWF5IHJldHVybiBmZXdlciBpdGVtcyB0aGFuCiByZXF1ZXN0ZWQu
IElmIHVuc3BlY2lmaWVkLCB0aGUgc2VydmVyIHdpbGwgcGljayBhbiBhcHByb3ByaWF0ZSBk
ZWZhdWx0LgoKDAoFBAACAQUSAywCBwoMCgUEAAIBARIDLAgRCgwKBQQAAgEDEgMsFBUKDAoF
BAACAQgSAywWPgoPCggEAAIBCJwIABIDLBc9ClgKBAQAAgISAy8CQRpLIE9wdGlvbmFsLiBB
IHRva2VuIGlkZW50aWZ5aW5nIGEgcGFnZSBvZiByZXN1bHRzIHRoZSBzZXJ2ZXIgc2hvdWxk
IHJldHVybi4KCgwKBQQAAgIFEgMvAggKDAoFBAACAgESAy8JEwoMCgUEAAICAxIDLxYXCgwK
BQQAAgIIEgMvGEAKDwoIBAACAgicCAASAy8ZPwo4CgQEAAIDEgMyAj0aKyBPcHRpb25hbC4g
RmlsdGVyIHRvIGFwcGx5IHRvIHRoZSByZXF1ZXN0LgoKDAoFBAACAwUSAzICCAoMCgUEAAID
ARIDMgkPCgwKBQQAAgMDEgMyEhMKDAoFBAACAwgSAzIUPAoPCggEAAIDCJwIABIDMhU7CjoK
BAQAAgQSAzUCPxotIE9wdGlvbmFsLiBIaW50IGZvciBob3cgdG8gb3JkZXIgdGhlIHJlc3Vs
dHMKCgwKBQQAAgQFEgM1AggKDAoFBAACBAESAzUJEQoMCgUEAAIEAxIDNRQVCgwKBQQAAgQI
EgM1Fj4KDwoIBAACBAicCAASAzUXPQpQCgIEARIEOQBCARpEIExpc3RIb3N0R3JvdXBzUmVz
cG9uc2UgaXMgdGhlIHJlc3BvbnNlIHRvIGEgTGlzdEhvc3RHcm91cHNSZXF1ZXN0LgoKCgoD
BAEBEgM5CB4KJwoEBAECABIDOwIlGhogVGhlIGxpc3Qgb2YgaG9zdCBncm91cHMuCgoMCgUE
AQIABBIDOwIKCgwKBQQBAgAGEgM7CxQKDAoFBAECAAESAzsVIAoMCgUEAQIAAxIDOyMkCk4K
BAQBAgESAz4CHRpBIEEgdG9rZW4gaWRlbnRpZnlpbmcgYSBwYWdlIG9mIHJlc3VsdHMgdGhl
IHNlcnZlciBzaG91bGQgcmV0dXJuLgoKDAoFBAECAQUSAz4CCAoMCgUEAQIBARIDPgkYCgwK
BQQBAgEDEgM+GxwKMwoEBAECAhIDQQIiGiYgTG9jYXRpb25zIHRoYXQgY291bGQgbm90IGJl
IHJlYWNoZWQuCgoMCgUEAQICBBIDQQIKCgwKBQQBAgIFEgNBCxEKDAoFBAECAgESA0ESHQoM
CgUEAQICAxIDQSAhCjsKAgQCEgRFAE8BGi8gR2V0SG9zdEdyb3VwUmVxdWVzdCBmb3IgZ2V0
dGluZyBhIGhvc3QgZ3JvdXAuCgoKCgMEAgESA0UIGwqZAQoEBAICABIESQJOBBqKASBSZXF1
aXJlZC4gVGhlIHJlc291cmNlIG5hbWUgb2YgdGhlIGhvc3QgZ3JvdXAuCiBGb3JtYXQ6CiBg
cHJvamVjdHMve3Byb2plY3RfbnVtYmVyfS9sb2NhdGlvbnMve2xvY2F0aW9uX2lkfS9ob3N0
R3JvdXBzL3tob3N0X2dyb3VwX2lkfWAuCgoMCgUEAgIABRIDSQIICgwKBQQCAgABEgNJCQ0K
DAoFBAICAAMSA0kQEQoNCgUEAgIACBIESRJOAwoPCggEAgIACJwIABIDSgQqCg8KBwQCAgAI
nwgSBEsETQUKPwoCBAMSBFIAYwEaMyBDcmVhdGVIb3N0R3JvdXBSZXF1ZXN0IGZvciBjcmVh
dGluZyBhIGhvc3QgZ3JvdXAuCgoKCgMEAwESA1IIHgpBCgQEAwIAEgRUAlkEGjMgUmVxdWly
ZWQuIFBhcmVudCB2YWx1ZSBmb3IgQ3JlYXRlSG9zdEdyb3VwUmVxdWVzdAoKDAoFBAMCAAUS
A1QCCAoMCgUEAwIAARIDVAkPCgwKBQQDAgADEgNUEhMKDQoFBAMCAAgSBFQUWQMKDwoIBAMC
AAicCAASA1UEKgoPCgcEAwIACJ8IEgRWBFgFCjwKBAQDAgESA1wCRBovIFJlcXVpcmVkLiBG
aWVsZHMgb2YgdGhlIGhvc3QgZ3JvdXAgdG8gY3JlYXRlLgoKDAoFBAMCAQYSA1wCCwoMCgUE
AwIBARIDXAwWCgwKBQQDAgEDEgNcGRoKDAoFBAMCAQgSA1wbQwoPCggEAwIBCJwIABIDXBxC
CpECCgQEAwICEgNiAkQagwIgUmVxdWlyZWQuIElEIG9mIHRoZSBob3N0IGdyb3VwIHRvIGNy
ZWF0ZS4gTXVzdCBiZSB1bmlxdWUgd2l0aGluIHRoZSBwYXJlbnQKIHJlc291cmNlLiBNdXN0
IGNvbnRhaW4gb25seSBsZXR0ZXJzLCBudW1iZXJzLCBhbmQgaHlwaGVuLCB3aXRoCiB0aGUg
Zmlyc3QgY2hhcmFjdGVyIGEgbGV0dGVyIG9yIHVuZGVyc2NvcmUsIHRoZSBsYXN0IGEgbGV0
dGVyIG9yIHVuZGVyc2NvcmUKIG9yIGEgbnVtYmVyLCBhbmQgYSA2MyBjaGFyYWN0ZXIgbWF4
aW11bS4KCgwKBQQDAgIFEgNiAggKDAoFBAMCAgESA2IJFgoMCgUEAwICAxIDYhkaCgwKBQQD
AgIIEgNiG0MKDwoIBAMCAgicCAASA2IcQgo/CgIEBBIEZgBwARozIFVwZGF0ZUhvc3RHcm91
cFJlcXVlc3QgZm9yIHVwZGF0aW5nIGEgaG9zdCBncm91cC4KCgoKAwQEARIDZggeCtABCgQE
BAIAEgNrAkQawgEgUmVxdWlyZWQuIFRoZSBob3N0IGdyb3VwIHRvIHVwZGF0ZS4KIFRoZSBo
b3N0IGdyb3VwJ3MgYG5hbWVgIGZpZWxkIGlzIHVzZWQgdG8gaWRlbnRpZnkgdGhlIGhvc3Qg
Z3JvdXAuCiBGb3JtYXQ6CiBgcHJvamVjdHMve3Byb2plY3RfbnVtYmVyfS9sb2NhdGlvbnMv
e2xvY2F0aW9uX2lkfS9ob3N0R3JvdXBzL3tob3N0X2dyb3VwX2lkfWAuCgoMCgUEBAIABhID
awILCgwKBQQEAgABEgNrDBYKDAoFBAQCAAMSA2sZGgoMCgUEBAIACBIDaxtDCg8KCAQEAgAI
nAgAEgNrHEIKNwoEBAQCARIEbgJvLxopIE9wdGlvbmFsLiBUaGUgbGlzdCBvZiBmaWVsZHMg
dG8gdXBkYXRlLgoKDAoFBAQCAQYSA24CGwoMCgUEBAIBARIDbhwnCgwKBQQEAgEDEgNuKisK
DAoFBAQCAQgSA28GLgoPCggEBAIBCJwIABIDbwctCkYKAgQFEgRzAH0BGjogRGVsZXRlSG9z
dEdyb3VwUmVxdWVzdCBmb3IgZGVsZXRpbmcgYSBzaW5nbGUgaG9zdCBncm91cC4KCgoKAwQF
ARIDcwgeCpkBCgQEBQIAEgR3AnwEGooBIFJlcXVpcmVkLiBUaGUgcmVzb3VyY2UgbmFtZSBv
ZiB0aGUgaG9zdCBncm91cC4KIEZvcm1hdDoKIGBwcm9qZWN0cy97cHJvamVjdF9udW1iZXJ9
L2xvY2F0aW9ucy97bG9jYXRpb25faWR9L2hvc3RHcm91cHMve2hvc3RfZ3JvdXBfaWR9YC4K
CgwKBQQFAgAFEgN3AggKDAoFBAUCAAESA3cJDQoMCgUEBQIAAxIDdxARCg0KBQQFAgAIEgR3
EnwDCg8KCAQFAgAInAgAEgN4BCoKDwoHBAUCAAifCBIEeQR7BQpjCgIEBhIGgQEAxAEBGlUg
SG9zdCBncm91cCBpcyBhIGNvbGxlY3Rpb24gb2YgaG9zdHMgdGhhdCBjYW4gYmUgdXNlZCBm
b3IgYWNjZXNzaW5nIGEgQmxvY2sKIFZvbHVtZS4KCgsKAwQGARIEgQEIEQoNCgMEBgcSBoIB
AocBBAoPCgUEBgedCBIGggEChwEECiYKBAQGBAASBooBApABAxoWIFR5cGVzIG9mIGhvc3Qg
Z3JvdXAuCgoNCgUEBgQAARIEigEHCwoyCgYEBgQAAgASBIwBBBkaIiBVbnNwZWNpZmllZCB0
eXBlIGZvciBob3N0IGdyb3VwLgoKDwoHBAYEAAIAARIEjAEEFAoPCgcEBgQAAgACEgSMARcY
Ci0KBgQGBAACARIEjwEEGBodIGlTQ1NJIGluaXRpYXRvciBob3N0IGdyb3VwLgoKDwoHBAYE
AAIBARIEjwEEEwoPCgcEBgQAAgECEgSPARYXCiQKBAQGBAESBpMBAqUBAxoUIEhvc3QgZ3Jv
dXAgc3RhdGVzLgoKDQoFBAYEAQESBJMBBwwKMwoGBAYEAQIAEgSVAQQaGiMgVW5zcGVjaWZp
ZWQgc3RhdGUgZm9yIGhvc3QgZ3JvdXAuCgoPCgcEBgQBAgABEgSVAQQVCg8KBwQGBAECAAIS
BJUBGBkKKQoGBAYEAQIBEgSYAQQRGhkgSG9zdCBncm91cCBpcyBjcmVhdGluZy4KCg8KBwQG
BAECAQESBJgBBAwKDwoHBAYEAQIBAhIEmAEPEAomCgYEBgQBAgISBJsBBA4aFiBIb3N0IGdy
b3VwIGlzIHJlYWR5LgoKDwoHBAYEAQICARIEmwEECQoPCgcEBgQBAgICEgSbAQwNCikKBgQG
BAECAxIEngEEERoZIEhvc3QgZ3JvdXAgaXMgdXBkYXRpbmcuCgoPCgcEBgQBAgMBEgSeAQQM
Cg8KBwQGBAECAwISBJ4BDxAKKQoGBAYEAQIEEgShAQQRGhkgSG9zdCBncm91cCBpcyBkZWxl
dGluZy4KCg8KBwQGBAECBAESBKEBBAwKDwoHBAYEAQIEAhIEoQEPEAopCgYEBgQBAgUSBKQB
BBEaGSBIb3N0IGdyb3VwIGlzIGRpc2FibGVkLgoKDwoHBAYEAQIFARIEpAEEDAoPCgcEBgQB
AgUCEgSkAQ8QCpsBCgQEBgIAEgSqAQI9GowBIElkZW50aWZpZXIuIFRoZSByZXNvdXJjZSBu
YW1lIG9mIHRoZSBob3N0IGdyb3VwLgogRm9ybWF0OgogYHByb2plY3RzL3twcm9qZWN0X251
bWJlcn0vbG9jYXRpb25zL3tsb2NhdGlvbl9pZH0vaG9zdEdyb3Vwcy97aG9zdF9ncm91cF9p
ZH1gLgoKDQoFBAYCAAUSBKoBAggKDQoFBAYCAAESBKoBCQ0KDQoFBAYCAAMSBKoBEBEKDQoF
BAYCAAgSBKoBEjwKEAoIBAYCAAicCAASBKoBEzsKMQoEBAYCARIErQECORojIFJlcXVpcmVk
LiBUeXBlIG9mIHRoZSBob3N0IGdyb3VwLgoKDQoFBAYCAQYSBK0BAgYKDQoFBAYCAQESBK0B
BwsKDQoFBAYCAQMSBK0BDg8KDQoFBAYCAQgSBK0BEDgKEAoIBAYCAQicCAASBK0BETcKNQoE
BAYCAhIEsAECPhonIE91dHB1dCBvbmx5LiBTdGF0ZSBvZiB0aGUgaG9zdCBncm91cC4KCg0K
BQQGAgIGEgSwAQIHCg0KBQQGAgIBEgSwAQgNCg0KBQQGAgIDEgSwARARCg0KBQQGAgIIEgSw
ARI9ChAKCAQGAgIInAgAEgSwARM8Cj0KBAQGAgMSBrMBArQBMhotIE91dHB1dCBvbmx5LiBD
cmVhdGUgdGltZSBvZiB0aGUgaG9zdCBncm91cC4KCg0KBQQGAgMGEgSzAQIbCg0KBQQGAgMB
EgSzARwnCg0KBQQGAgMDEgSzASorCg0KBQQGAgMIEgS0AQYxChAKCAQGAgMInAgAEgS0AQcw
CksKBAQGAgQSBLcBAkUaPSBSZXF1aXJlZC4gVGhlIGxpc3Qgb2YgaG9zdHMgYXNzb2NpYXRl
ZCB3aXRoIHRoZSBob3N0IGdyb3VwLgoKDQoFBAYCBAQSBLcBAgoKDQoFBAYCBAUSBLcBCxEK
DQoFBAYCBAESBLcBEhcKDQoFBAYCBAMSBLcBGhsKDQoFBAYCBAgSBLcBHEQKEAoIBAYCBAic
CAASBLcBHUMK9wEKBAQGAgUSBL0BAj4a6AEgUmVxdWlyZWQuIFRoZSBPUyB0eXBlIG9mIHRo
ZSBob3N0IGdyb3VwLiBJdCBpbmRpY2F0ZXMgdGhlIHR5cGUgb2Ygb3BlcmF0aW5nCiBzeXN0
ZW0gdXNlZCBieSBhbGwgb2YgdGhlIGhvc3RzIGluIHRoZSBIb3N0R3JvdXAuIEFsbCBob3N0
cyBpbiBhIEhvc3RHcm91cAogbXVzdCBiZSBvZiB0aGUgc2FtZSBPUyB0eXBlLiBUaGlzIGNh
biBiZSBzZXQgb25seSB3aGVuIGNyZWF0aW5nIGEKIEhvc3RHcm91cC4KCg0KBQQGAgUGEgS9
AQIICg0KBQQGAgUBEgS9AQkQCg0KBQQGAgUDEgS9ARMUCg0KBQQGAgUIEgS9ARU9ChAKCAQG
AgUInAgAEgS9ARY8CjgKBAQGAgYSBMABAkIaKiBPcHRpb25hbC4gRGVzY3JpcHRpb24gb2Yg
dGhlIGhvc3QgZ3JvdXAuCgoNCgUEBgIGBRIEwAECCAoNCgUEBgIGARIEwAEJFAoNCgUEBgIG
AxIEwAEXGAoNCgUEBgIGCBIEwAEZQQoQCggEBgIGCJwIABIEwAEaQAozCgQEBgIHEgTDAQJK
GiUgT3B0aW9uYWwuIExhYmVscyBvZiB0aGUgaG9zdCBncm91cC4KCg0KBQQGAgcGEgTDAQIV
Cg0KBQQGAgcBEgTDARYcCg0KBQQGAgcDEgTDAR8gCg0KBQQGAgcIEgTDASFJChAKCAQGAgcI
nAgAEgTDASJIYgZwcm90bzM=
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Netapp::V1::HostGroup::ListHostGroupsRequest ===
    # Fields for ListHostGroupsRequest
    # Field: parent Type: 9 ()
    # Field: page_size Type: 5 ()
    # Field: page_token Type: 9 ()
    # Field: filter Type: 9 ()
    # Field: order_by Type: 9 ()

# === Message: Google::Cloud::Netapp::V1::HostGroup::ListHostGroupsResponse ===
    # Fields for ListHostGroupsResponse
    # Field: host_groups Type: 11 (.google.cloud.netapp.v1.HostGroup)
    # Field: next_page_token Type: 9 ()
    # Field: unreachable Type: 9 ()

# === Message: Google::Cloud::Netapp::V1::HostGroup::GetHostGroupRequest ===
    # Fields for GetHostGroupRequest
    # Field: name Type: 9 ()

# === Message: Google::Cloud::Netapp::V1::HostGroup::CreateHostGroupRequest ===
    # Fields for CreateHostGroupRequest
    # Field: parent Type: 9 ()
    # Field: host_group Type: 11 (.google.cloud.netapp.v1.HostGroup)
    # Field: host_group_id Type: 9 ()

# === Message: Google::Cloud::Netapp::V1::HostGroup::UpdateHostGroupRequest ===
    # Fields for UpdateHostGroupRequest
    # Field: host_group Type: 11 (.google.cloud.netapp.v1.HostGroup)
    # Field: update_mask Type: 11 (.google.protobuf.FieldMask)

# === Message: Google::Cloud::Netapp::V1::HostGroup::DeleteHostGroupRequest ===
    # Fields for DeleteHostGroupRequest
    # Field: name Type: 9 ()

# === Message: Google::Cloud::Netapp::V1::HostGroup::HostGroup ===
    # Fields for HostGroup
    # Field: name Type: 9 ()
    # Field: type Type: 14 (.google.cloud.netapp.v1.HostGroup.Type)
    # Field: state Type: 14 (.google.cloud.netapp.v1.HostGroup.State)
    # Field: create_time Type: 11 (.google.protobuf.Timestamp)
    # Field: hosts Type: 9 ()
    # Field: os_type Type: 14 (.google.cloud.netapp.v1.OsType)
    # Field: description Type: 9 ()
    # Field: labels Type: 11 (.google.cloud.netapp.v1.HostGroup.LabelsEntry)

# Enum: HostGroup::Type
our $HostGroup_TYPE_UNSPECIFIED = 0;
our $HostGroup_ISCSI_INITIATOR = 1;

# Enum: HostGroup::State
our $HostGroup_STATE_UNSPECIFIED = 0;
our $HostGroup_CREATING = 1;
our $HostGroup_READY = 2;
our $HostGroup_UPDATING = 3;
our $HostGroup_DELETING = 4;
our $HostGroup_DISABLED = 5;

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Netapp::V1::HostGroup - Compiled Protocol Buffers messages for google/cloud/netapp/v1/host_group.proto

=head1 SYNOPSIS

    use Google::Cloud::Netapp::V1::HostGroup;

    my $msg = Google::Cloud::Netapp::V1::HostGroup::ListHostGroupsRequest->new({
        parent => $parent,
        page_size => $page_size,
        page_token => $page_token,
        filter => $filter,
    });

    # Read or update a field
    my $val = $msg->parent();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Netapp::V1::HostGroup::ListHostGroupsRequest->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/netapp/v1/host_group.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Netapp::V1::HostGroup::ListHostGroupsRequest

ListHostGroupsRequest for listing host groups.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->parent() >> / C<< $msg->parent($value) >>

Type: C<String>

Required. Parent value for ListHostGroupsRequest

=item * C<< $msg->page_size() >> / C<< $msg->page_size($value) >>

Type: C<Int32>

Optional. Requested page size. Server may return fewer items than
requested. If unspecified, the server will pick an appropriate default.

=item * C<< $msg->page_token() >> / C<< $msg->page_token($value) >>

Type: C<String>

Optional. A token identifying a page of results the server should return.

=item * C<< $msg->filter() >> / C<< $msg->filter($value) >>

Type: C<String>

Optional. Filter to apply to the request.

=item * C<< $msg->order_by() >> / C<< $msg->order_by($value) >>

Type: C<String>

Optional. Hint for how to order the results

=back

=head2 Google::Cloud::Netapp::V1::HostGroup::ListHostGroupsResponse

ListHostGroupsResponse is the response to a ListHostGroupsRequest.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->host_groups() >> / C<< $msg->host_groups($value) >>

Type: C<Message> (L<Google::Cloud::Netapp::V1::HostGroup::HostGroup>)

The list of host groups.

=item * C<< $msg->next_page_token() >> / C<< $msg->next_page_token($value) >>

Type: C<String>

A token identifying a page of results the server should return.

=item * C<< $msg->unreachable() >> / C<< $msg->unreachable($value) >>

Type: C<String>

Locations that could not be reached.

=back

=head2 Google::Cloud::Netapp::V1::HostGroup::GetHostGroupRequest

GetHostGroupRequest for getting a host group.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. The resource name of the host group.
Format:
`projects/{project_number}/locations/{location_id}/hostGroups/{host_group_id}`.

=back

=head2 Google::Cloud::Netapp::V1::HostGroup::CreateHostGroupRequest

CreateHostGroupRequest for creating a host group.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->parent() >> / C<< $msg->parent($value) >>

Type: C<String>

Required. Parent value for CreateHostGroupRequest

=item * C<< $msg->host_group() >> / C<< $msg->host_group($value) >>

Type: C<Message> (L<Google::Cloud::Netapp::V1::HostGroup::HostGroup>)

Required. Fields of the host group to create.

=item * C<< $msg->host_group_id() >> / C<< $msg->host_group_id($value) >>

Type: C<String>

Required. ID of the host group to create. Must be unique within the parent
resource. Must contain only letters, numbers, and hyphen, with
the first character a letter or underscore, the last a letter or underscore
or a number, and a 63 character maximum.

=back

=head2 Google::Cloud::Netapp::V1::HostGroup::UpdateHostGroupRequest

UpdateHostGroupRequest for updating a host group.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->host_group() >> / C<< $msg->host_group($value) >>

Type: C<Message> (L<Google::Cloud::Netapp::V1::HostGroup::HostGroup>)

Required. The host group to update.
The host group's `name` field is used to identify the host group.
Format:
`projects/{project_number}/locations/{location_id}/hostGroups/{host_group_id}`.

=item * C<< $msg->update_mask() >> / C<< $msg->update_mask($value) >>

Type: C<Message> (L<Google::Protobuf::FieldMask::FieldMask>)

Optional. The list of fields to update.

=back

=head2 Google::Cloud::Netapp::V1::HostGroup::DeleteHostGroupRequest

DeleteHostGroupRequest for deleting a single host group.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. The resource name of the host group.
Format:
`projects/{project_number}/locations/{location_id}/hostGroups/{host_group_id}`.

=back

=head2 Google::Cloud::Netapp::V1::HostGroup::HostGroup

Host group is a collection of hosts that can be used for accessing a Block
Volume.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Identifier. The resource name of the host group.
Format:
`projects/{project_number}/locations/{location_id}/hostGroups/{host_group_id}`.

=item * C<< $msg->type() >> / C<< $msg->type($value) >>

Type: C<Enum> (L<Google::Cloud::Netapp::V1::HostGroup::Type>)

Required. Type of the host group.

=item * C<< $msg->state() >> / C<< $msg->state($value) >>

Type: C<Enum> (L<Google::Cloud::Netapp::V1::HostGroup::State>)

Output only. State of the host group.

=item * C<< $msg->create_time() >> / C<< $msg->create_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Output only. Create time of the host group.

=item * C<< $msg->hosts() >> / C<< $msg->hosts($value) >>

Type: C<String>

Required. The list of hosts associated with the host group.

=item * C<< $msg->os_type() >> / C<< $msg->os_type($value) >>

Type: C<Enum> (L<Google::Cloud::Netapp::V1::OsType>)

Required. The OS type of the host group. It indicates the type of operating
system used by all of the hosts in the HostGroup. All hosts in a HostGroup
must be of the same OS type. This can be set only when creating a
HostGroup.

=item * C<< $msg->description() >> / C<< $msg->description($value) >>

Type: C<String>

Optional. Description of the host group.

=item * C<< $msg->labels() >> / C<< $msg->labels($value) >>

Type: C<Message> (L<Google::Cloud::Netapp::V1::HostGroup::HostGroup::LabelsEntry>)

Optional. Labels of the host group.

=back

=head3 Enum: HostGroup::Type

=over 4

=item * C<TYPE_UNSPECIFIED> => C<0>

=item * C<ISCSI_INITIATOR> => C<1>

=back

=head3 Enum: HostGroup::State

=over 4

=item * C<STATE_UNSPECIFIED> => C<0>

=item * C<CREATING> => C<1>

=item * C<READY> => C<2>

=item * C<UPDATING> => C<3>

=item * C<DELETING> => C<4>

=item * C<DISABLED> => C<5>

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Netapp::V1::HostGroup::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
