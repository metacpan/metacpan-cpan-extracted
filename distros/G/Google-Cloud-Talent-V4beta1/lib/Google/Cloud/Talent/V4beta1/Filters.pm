package Google::Cloud::Talent::V4beta1::Filters;

use strict;
use warnings;

our $VERSION = '0.14';

use Protobuf::Message;
use Protobuf::DescriptorPool;
use Protobuf::Internal qw(:all);
use MIME::Base64;

BEGIN {
    eval { require Google::Api::FieldBehavior };
    eval { require Google::Cloud::Talent::V4beta1::Common };
    eval { require Google::Protobuf::Duration };
    eval { require Google::Type::Latlng };
    eval { require Google::Type::Timeofday };
    my $descriptor_b64 = <<'EOF';
Cilnb29nbGUvY2xvdWQvdGFsZW50L3Y0YmV0YTEvZmlsdGVycy5wcm90bxIbZ29vZ2xlLmNs
b3VkLnRhbGVudC52NGJldGExGh9nb29nbGUvYXBpL2ZpZWxkX2JlaGF2aW9yLnByb3RvGihn
b29nbGUvY2xvdWQvdGFsZW50L3Y0YmV0YTEvY29tbW9uLnByb3RvGh5nb29nbGUvcHJvdG9i
dWYvZHVyYXRpb24ucHJvdG8aGGdvb2dsZS90eXBlL2xhdGxuZy5wcm90bxobZ29vZ2xlL3R5
cGUvdGltZW9mZGF5LnByb3RvIucGCghKb2JRdWVyeRIUCgVxdWVyeRgBIAEoCVIFcXVlcnkS
LgoTcXVlcnlfbGFuZ3VhZ2VfY29kZRgOIAEoCVIRcXVlcnlMYW5ndWFnZUNvZGUSHAoJY29t
cGFuaWVzGAIgAygJUgljb21wYW5pZXMSVgoQbG9jYXRpb25fZmlsdGVycxgDIAMoCzIrLmdv
b2dsZS5jbG91ZC50YWxlbnQudjRiZXRhMS5Mb2NhdGlvbkZpbHRlclIPbG9jYXRpb25GaWx0
ZXJzEk8KDmpvYl9jYXRlZ29yaWVzGAQgAygOMiguZ29vZ2xlLmNsb3VkLnRhbGVudC52NGJl
dGExLkpvYkNhdGVnb3J5Ug1qb2JDYXRlZ29yaWVzElEKDmNvbW11dGVfZmlsdGVyGAUgASgL
MiouZ29vZ2xlLmNsb3VkLnRhbGVudC52NGJldGExLkNvbW11dGVGaWx0ZXJSDWNvbW11dGVG
aWx0ZXISMgoVY29tcGFueV9kaXNwbGF5X25hbWVzGAYgAygJUhNjb21wYW55RGlzcGxheU5h
bWVzEmAKE2NvbXBlbnNhdGlvbl9maWx0ZXIYByABKAsyLy5nb29nbGUuY2xvdWQudGFsZW50
LnY0YmV0YTEuQ29tcGVuc2F0aW9uRmlsdGVyUhJjb21wZW5zYXRpb25GaWx0ZXISNgoXY3Vz
dG9tX2F0dHJpYnV0ZV9maWx0ZXIYCCABKAlSFWN1c3RvbUF0dHJpYnV0ZUZpbHRlchIuChNk
aXNhYmxlX3NwZWxsX2NoZWNrGAkgASgIUhFkaXNhYmxlU3BlbGxDaGVjaxJWChBlbXBsb3lt
ZW50X3R5cGVzGAogAygOMisuZ29vZ2xlLmNsb3VkLnRhbGVudC52NGJldGExLkVtcGxveW1l
bnRUeXBlUg9lbXBsb3ltZW50VHlwZXMSJQoObGFuZ3VhZ2VfY29kZXMYCyADKAlSDWxhbmd1
YWdlQ29kZXMSWQoScHVibGlzaF90aW1lX3JhbmdlGAwgASgLMisuZ29vZ2xlLmNsb3VkLnRh
bGVudC52NGJldGExLlRpbWVzdGFtcFJhbmdlUhBwdWJsaXNoVGltZVJhbmdlEiMKDWV4Y2x1
ZGVkX2pvYnMYDSADKAlSDGV4Y2x1ZGVkSm9icyLRAwoOTG9jYXRpb25GaWx0ZXISGAoHYWRk
cmVzcxgBIAEoCVIHYWRkcmVzcxIfCgtyZWdpb25fY29kZRgCIAEoCVIKcmVnaW9uQ29kZRIs
CgdsYXRfbG5nGAMgASgLMhMuZ29vZ2xlLnR5cGUuTGF0TG5nUgZsYXRMbmcSKgoRZGlzdGFu
Y2VfaW5fbWlsZXMYBCABKAFSD2Rpc3RhbmNlSW5NaWxlcxJ4ChZ0ZWxlY29tbXV0ZV9wcmVm
ZXJlbmNlGAUgASgOMkEuZ29vZ2xlLmNsb3VkLnRhbGVudC52NGJldGExLkxvY2F0aW9uRmls
dGVyLlRlbGVjb21tdXRlUHJlZmVyZW5jZVIVdGVsZWNvbW11dGVQcmVmZXJlbmNlEhgKB25l
Z2F0ZWQYBiABKAhSB25lZ2F0ZWQilQEKFVRlbGVjb21tdXRlUHJlZmVyZW5jZRImCiJURUxF
Q09NTVVURV9QUkVGRVJFTkNFX1VOU1BFQ0lGSUVEEAASHAoUVEVMRUNPTU1VVEVfRVhDTFVE
RUQQARoCCAESFwoTVEVMRUNPTU1VVEVfQUxMT1dFRBACEh0KGVRFTEVDT01NVVRFX0pPQlNf
RVhDTFVERUQQAyKLBAoSQ29tcGVuc2F0aW9uRmlsdGVyElMKBHR5cGUYASABKA4yOi5nb29n
bGUuY2xvdWQudGFsZW50LnY0YmV0YTEuQ29tcGVuc2F0aW9uRmlsdGVyLkZpbHRlclR5cGVC
A+BBAlIEdHlwZRJZCgV1bml0cxgCIAMoDjI+Lmdvb2dsZS5jbG91ZC50YWxlbnQudjRiZXRh
MS5Db21wZW5zYXRpb25JbmZvLkNvbXBlbnNhdGlvblVuaXRCA+BBAlIFdW5pdHMSVQoFcmFu
Z2UYAyABKAsyPy5nb29nbGUuY2xvdWQudGFsZW50LnY0YmV0YTEuQ29tcGVuc2F0aW9uSW5m
by5Db21wZW5zYXRpb25SYW5nZVIFcmFuZ2USZQowaW5jbHVkZV9qb2JzX3dpdGhfdW5zcGVj
aWZpZWRfY29tcGVuc2F0aW9uX3JhbmdlGAQgASgIUitpbmNsdWRlSm9ic1dpdGhVbnNwZWNp
ZmllZENvbXBlbnNhdGlvblJhbmdlIoYBCgpGaWx0ZXJUeXBlEhsKF0ZJTFRFUl9UWVBFX1VO
U1BFQ0lGSUVEEAASDQoJVU5JVF9PTkxZEAESEwoPVU5JVF9BTkRfQU1PVU5UEAISGgoWQU5O
VUFMSVpFRF9CQVNFX0FNT1VOVBADEhsKF0FOTlVBTElaRURfVE9UQUxfQU1PVU5UEAQisQQK
DUNvbW11dGVGaWx0ZXISVgoOY29tbXV0ZV9tZXRob2QYASABKA4yKi5nb29nbGUuY2xvdWQu
dGFsZW50LnY0YmV0YTEuQ29tbXV0ZU1ldGhvZEID4EECUg1jb21tdXRlTWV0aG9kEkUKEXN0
YXJ0X2Nvb3JkaW5hdGVzGAIgASgLMhMuZ29vZ2xlLnR5cGUuTGF0TG5nQgPgQQJSEHN0YXJ0
Q29vcmRpbmF0ZXMSRwoPdHJhdmVsX2R1cmF0aW9uGAMgASgLMhkuZ29vZ2xlLnByb3RvYnVm
LkR1cmF0aW9uQgPgQQJSDnRyYXZlbER1cmF0aW9uEjoKGWFsbG93X2ltcHJlY2lzZV9hZGRy
ZXNzZXMYBCABKAhSF2FsbG93SW1wcmVjaXNlQWRkcmVzc2VzElsKDHJvYWRfdHJhZmZpYxgF
IAEoDjI2Lmdvb2dsZS5jbG91ZC50YWxlbnQudjRiZXRhMS5Db21tdXRlRmlsdGVyLlJvYWRU
cmFmZmljSABSC3JvYWRUcmFmZmljEj8KDmRlcGFydHVyZV90aW1lGAYgASgLMhYuZ29vZ2xl
LnR5cGUuVGltZU9mRGF5SABSDWRlcGFydHVyZVRpbWUiTAoLUm9hZFRyYWZmaWMSHAoYUk9B
RF9UUkFGRklDX1VOU1BFQ0lGSUVEEAASEAoMVFJBRkZJQ19GUkVFEAESDQoJQlVTWV9IT1VS
EAJCEAoOdHJhZmZpY19vcHRpb25CcAofY29tLmdvb2dsZS5jbG91ZC50YWxlbnQudjRiZXRh
MUIMRmlsdGVyc1Byb3RvUAFaN2Nsb3VkLmdvb2dsZS5jb20vZ28vdGFsZW50L2FwaXY0YmV0
YTEvdGFsZW50cGI7dGFsZW50cGKiAgNDVFNKt34KBxIFDgCMAwEKvAQKAQwSAw4AEjKxBCBD
b3B5cmlnaHQgMjAyNSBHb29nbGUgTExDCgogTGljZW5zZWQgdW5kZXIgdGhlIEFwYWNoZSBM
aWNlbnNlLCBWZXJzaW9uIDIuMCAodGhlICJMaWNlbnNlIik7CiB5b3UgbWF5IG5vdCB1c2Ug
dGhpcyBmaWxlIGV4Y2VwdCBpbiBjb21wbGlhbmNlIHdpdGggdGhlIExpY2Vuc2UuCiBZb3Ug
bWF5IG9idGFpbiBhIGNvcHkgb2YgdGhlIExpY2Vuc2UgYXQKCiAgICAgaHR0cDovL3d3dy5h
cGFjaGUub3JnL2xpY2Vuc2VzL0xJQ0VOU0UtMi4wCgogVW5sZXNzIHJlcXVpcmVkIGJ5IGFw
cGxpY2FibGUgbGF3IG9yIGFncmVlZCB0byBpbiB3cml0aW5nLCBzb2Z0d2FyZQogZGlzdHJp
YnV0ZWQgdW5kZXIgdGhlIExpY2Vuc2UgaXMgZGlzdHJpYnV0ZWQgb24gYW4gIkFTIElTIiBC
QVNJUywKIFdJVEhPVVQgV0FSUkFOVElFUyBPUiBDT05ESVRJT05TIE9GIEFOWSBLSU5ELCBl
aXRoZXIgZXhwcmVzcyBvciBpbXBsaWVkLgogU2VlIHRoZSBMaWNlbnNlIGZvciB0aGUgc3Bl
Y2lmaWMgbGFuZ3VhZ2UgZ292ZXJuaW5nIHBlcm1pc3Npb25zIGFuZAogbGltaXRhdGlvbnMg
dW5kZXIgdGhlIExpY2Vuc2UuCgoICgECEgMQACQKCQoCAwASAxIAKQoJCgIDARIDEwAyCgkK
AgMCEgMUACgKCQoCAwMSAxUAIgoJCgIDBBIDFgAlCggKAQgSAxgATgoJCgIICxIDGABOCggK
AQgSAxkAIgoJCgIIChIDGQAiCggKAQgSAxoALQoJCgIICBIDGgAtCggKAQgSAxsAOAoJCgII
ARIDGwA4CggKAQgSAxwAIQoJCgIIJBIDHAAhCjwKAgQAEgUfAMwBARovIFRoZSBxdWVyeSBy
ZXF1aXJlZCB0byBwZXJmb3JtIGEgc2VhcmNoIHF1ZXJ5LgoKCgoDBAABEgMfCBAKmgEKBAQA
AgASAyQCExqMASBUaGUgcXVlcnkgc3RyaW5nIHRoYXQgbWF0Y2hlcyBhZ2FpbnN0IHRoZSBq
b2IgdGl0bGUsIGRlc2NyaXB0aW9uLCBhbmQKIGxvY2F0aW9uIGZpZWxkcy4KCiBUaGUgbWF4
aW11bSBudW1iZXIgb2YgYWxsb3dlZCBjaGFyYWN0ZXJzIGlzIDI1NS4KCgwKBQQAAgAFEgMk
AggKDAoFBAACAAESAyQJDgoMCgUEAAIAAxIDJBESCrgDCgQEAAIBEgMvAiIaqgMgVGhlIGxh
bmd1YWdlIGNvZGUgb2YgW3F1ZXJ5XVtnb29nbGUuY2xvdWQudGFsZW50LnY0YmV0YTEuSm9i
UXVlcnkucXVlcnldLgogRm9yIGV4YW1wbGUsICJlbi1VUyIuIFRoaXMgZmllbGQgaGVscHMg
dG8gYmV0dGVyIGludGVycHJldCB0aGUgcXVlcnkuCgogSWYgYSB2YWx1ZSBpc24ndCBzcGVj
aWZpZWQsIHRoZSBxdWVyeSBsYW5ndWFnZSBjb2RlIGlzIGF1dG9tYXRpY2FsbHkKIGRldGVj
dGVkLCB3aGljaCBtYXkgbm90IGJlIGFjY3VyYXRlLgoKIExhbmd1YWdlIGNvZGUgc2hvdWxk
IGJlIGluIEJDUC00NyBmb3JtYXQsIHN1Y2ggYXMgImVuLVVTIiBvciAic3ItTGF0biIuCiBG
b3IgbW9yZSBpbmZvcm1hdGlvbiwgc2VlCiBbVGFncyBmb3IgSWRlbnRpZnlpbmcgTGFuZ3Vh
Z2VzXShodHRwczovL3Rvb2xzLmlldGYub3JnL2h0bWwvYmNwNDcpLgoKDAoFBAACAQUSAy8C
CAoMCgUEAAIBARIDLwkcCgwKBQQAAgEDEgMvHyEKjwQKBAQAAgISA0ECIBqBBCBUaGlzIGZp
bHRlciBzcGVjaWZpZXMgdGhlIGNvbXBhbnkgZW50aXRpZXMgdG8gc2VhcmNoIGFnYWluc3Qu
CgogSWYgYSB2YWx1ZSBpc24ndCBzcGVjaWZpZWQsIGpvYnMgYXJlIHNlYXJjaGVkIGZvciBh
Z2FpbnN0IGFsbAogY29tcGFuaWVzLgoKIElmIG11bHRpcGxlIHZhbHVlcyBhcmUgc3BlY2lm
aWVkLCBqb2JzIGFyZSBzZWFyY2hlZCBhZ2FpbnN0IHRoZQogY29tcGFuaWVzIHNwZWNpZmll
ZC4KCiBUaGUgZm9ybWF0IGlzCiAicHJvamVjdHMve3Byb2plY3RfaWR9L3RlbmFudHMve3Rl
bmFudF9pZH0vY29tcGFuaWVzL3tjb21wYW55X2lkfSIuIEZvcgogZXhhbXBsZSwgInByb2pl
Y3RzL2Zvby90ZW5hbnRzL2Jhci9jb21wYW5pZXMvYmF6Ii4KCiBJZiB0ZW5hbnQgaWQgaXMg
dW5zcGVjaWZpZWQsIHRoZSBkZWZhdWx0IHRlbmFudCBpcyB1c2VkLiBGb3IKIGV4YW1wbGUs
ICJwcm9qZWN0cy9mb28vY29tcGFuaWVzL2JhciIuCgogQXQgbW9zdCAyMCBjb21wYW55IGZp
bHRlcnMgYXJlIGFsbG93ZWQuCgoMCgUEAAICBBIDQQIKCgwKBQQAAgIFEgNBCxEKDAoFBAAC
AgESA0ESGwoMCgUEAAICAxIDQR4fCpQFCgQEAAIDEgNRAi8ahgUgVGhlIGxvY2F0aW9uIGZp
bHRlciBzcGVjaWZpZXMgZ2VvLXJlZ2lvbnMgY29udGFpbmluZyB0aGUgam9icyB0bwogc2Vh
cmNoIGFnYWluc3QuIFNlZQogW0xvY2F0aW9uRmlsdGVyXVtnb29nbGUuY2xvdWQudGFsZW50
LnY0YmV0YTEuTG9jYXRpb25GaWx0ZXJdIGZvciBtb3JlCiBpbmZvcm1hdGlvbi4KCiBJZiBh
IGxvY2F0aW9uIHZhbHVlIGlzbid0IHNwZWNpZmllZCwgam9icyBmaXR0aW5nIHRoZSBvdGhl
ciBzZWFyY2gKIGNyaXRlcmlhIGFyZSByZXRyaWV2ZWQgcmVnYXJkbGVzcyBvZiB3aGVyZSB0
aGV5J3JlIGxvY2F0ZWQuCgogSWYgbXVsdGlwbGUgdmFsdWVzIGFyZSBzcGVjaWZpZWQsIGpv
YnMgYXJlIHJldHJpZXZlZCBmcm9tIGFueSBvZiB0aGUKIHNwZWNpZmllZCBsb2NhdGlvbnMu
IElmIGRpZmZlcmVudCB2YWx1ZXMgYXJlIHNwZWNpZmllZCBmb3IgdGhlCiBbTG9jYXRpb25G
aWx0ZXIuZGlzdGFuY2VfaW5fbWlsZXNdW2dvb2dsZS5jbG91ZC50YWxlbnQudjRiZXRhMS5M
b2NhdGlvbkZpbHRlci5kaXN0YW5jZV9pbl9taWxlc10KIHBhcmFtZXRlciwgdGhlIG1heGlt
dW0gcHJvdmlkZWQgZGlzdGFuY2UgaXMgdXNlZCBmb3IgYWxsIGxvY2F0aW9ucy4KCiBBdCBt
b3N0IDUgbG9jYXRpb24gZmlsdGVycyBhcmUgYWxsb3dlZC4KCgwKBQQAAgMEEgNRAgoKDAoF
BAACAwYSA1ELGQoMCgUEAAIDARIDURoqCgwKBQQAAgMDEgNRLS4K2gIKBAQAAgQSA1sCKhrM
AiBUaGUgY2F0ZWdvcnkgZmlsdGVyIHNwZWNpZmllcyB0aGUgY2F0ZWdvcmllcyBvZiBqb2Jz
IHRvIHNlYXJjaCBhZ2FpbnN0LgogU2VlIFtKb2JDYXRlZ29yeV1bZ29vZ2xlLmNsb3VkLnRh
bGVudC52NGJldGExLkpvYkNhdGVnb3J5XSBmb3IgbW9yZQogaW5mb3JtYXRpb24uCgogSWYg
YSB2YWx1ZSBpc24ndCBzcGVjaWZpZWQsIGpvYnMgZnJvbSBhbnkgY2F0ZWdvcnkgYXJlIHNl
YXJjaGVkIGFnYWluc3QuCgogSWYgbXVsdGlwbGUgdmFsdWVzIGFyZSBzcGVjaWZpZWQsIGpv
YnMgZnJvbSBhbnkgb2YgdGhlIHNwZWNpZmllZAogY2F0ZWdvcmllcyBhcmUgc2VhcmNoZWQg
YWdhaW5zdC4KCgwKBQQAAgQEEgNbAgoKDAoFBAACBAYSA1sLFgoMCgUEAAIEARIDWxclCgwK
BQQAAgQDEgNbKCkKhAMKBAQAAgUSA2YCIxr2AiBBbGxvd3MgZmlsdGVyaW5nIGpvYnMgYnkg
Y29tbXV0ZSB0aW1lIHdpdGggZGlmZmVyZW50IHRyYXZlbCBtZXRob2RzIChmb3IKICBleGFt
cGxlLCBkcml2aW5nIG9yIHB1YmxpYyB0cmFuc2l0KS4KCiBOb3RlOiBUaGlzIG9ubHkgd29y
a3Mgd2hlbiB5b3Ugc3BlY2lmeSBhCiBbQ29tbXV0ZU1ldGhvZF1bZ29vZ2xlLmNsb3VkLnRh
bGVudC52NGJldGExLkNvbW11dGVNZXRob2RdLiBJbiB0aGlzIGNhc2UsCiBbbG9jYXRpb25f
ZmlsdGVyc11bZ29vZ2xlLmNsb3VkLnRhbGVudC52NGJldGExLkpvYlF1ZXJ5LmxvY2F0aW9u
X2ZpbHRlcnNdCiBpcyBpZ25vcmVkLgoKICBDdXJyZW50bHkgd2UgZG9uJ3Qgc3VwcG9ydCBz
b3J0aW5nIGJ5IGNvbW11dGUgdGltZS4KCgwKBQQAAgUGEgNmAg8KDAoFBAACBQESA2YQHgoM
CgUEAAIFAxIDZiEiCvQHCgQEAAIGEgSCAQIsGuUHIFRoaXMgZmlsdGVyIHNwZWNpZmllcyB0
aGUgY29tcGFueQogW0NvbXBhbnkuZGlzcGxheV9uYW1lXVtnb29nbGUuY2xvdWQudGFsZW50
LnY0YmV0YTEuQ29tcGFueS5kaXNwbGF5X25hbWVdIG9mCiB0aGUgam9icyB0byBzZWFyY2gg
YWdhaW5zdC4gVGhlIGNvbXBhbnkgbmFtZSBtdXN0IG1hdGNoIHRoZSB2YWx1ZSBleGFjdGx5
LgoKIEFsdGVybmF0aXZlbHksIHRoZSB2YWx1ZSBiZWluZyBzZWFyY2hlZCBmb3IgY2FuIGJl
IHdyYXBwZWQgaW4gZGlmZmVyZW50CiBtYXRjaCBvcGVyYXRvcnMuCiBgU1VCU1RSSU5HX01B
VENIKFt2YWx1ZV0pYAogVGhlIGNvbXBhbnkgbmFtZSBtdXN0IGNvbnRhaW4gYSBjYXNlIGlu
c2Vuc2l0aXZlIHN1YnN0cmluZyBtYXRjaCBvZiB0aGUKIHZhbHVlLiBVc2luZyB0aGlzIGZ1
bmN0aW9uIG1heSBpbmNyZWFzZSBsYXRlbmN5LgoKIFNhbXBsZSBWYWx1ZTogYFNVQlNUUklO
R19NQVRDSChnb29nbGUpYAoKIGBNVUxUSV9XT1JEX1RPS0VOX01BVENIKFt2YWx1ZV0pYAog
VGhlIHZhbHVlIHdpbGwgYmUgdHJlYXRlZCBhcyBhIG11bHRpIHdvcmQgdG9rZW4gYW5kIHRo
ZSBjb21wYW55IG5hbWUgbXVzdAogY29udGFpbiBhIGNhc2UgaW5zZW5zaXRpdmUgbWF0Y2gg
b2YgdGhlIHZhbHVlLiBVc2luZyB0aGlzIGZ1bmN0aW9uIG1heQogaW5jcmVhc2UgbGF0ZW5j
eS4KCiBTYW1wbGUgVmFsdWU6IGBNVUxUSV9XT1JEX1RPS0VOX01BVENIKGdvb2dsZSlgCgog
SWYgYSB2YWx1ZSBpc24ndCBzcGVjaWZpZWQsIGpvYnMgd2l0aGluIHRoZSBzZWFyY2ggcmVz
dWx0cyBhcmUKIGFzc29jaWF0ZWQgd2l0aCBhbnkgY29tcGFueS4KCiBJZiBtdWx0aXBsZSB2
YWx1ZXMgYXJlIHNwZWNpZmllZCwgam9icyB3aXRoaW4gdGhlIHNlYXJjaCByZXN1bHRzIG1h
eSBiZQogYXNzb2NpYXRlZCB3aXRoIGFueSBvZiB0aGUgc3BlY2lmaWVkIGNvbXBhbmllcy4K
CiBBdCBtb3N0IDIwIGNvbXBhbnkgZGlzcGxheSBuYW1lIGZpbHRlcnMgYXJlIGFsbG93ZWQu
CgoNCgUEAAIGBBIEggECCgoNCgUEAAIGBRIEggELEQoNCgUEAAIGARIEggESJwoNCgUEAAIG
AxIEggEqKwrGAgoEBAACBxIEiQECLRq3AiBUaGlzIHNlYXJjaCBmaWx0ZXIgaXMgYXBwbGll
ZCBvbmx5IHRvCiBbSm9iLmNvbXBlbnNhdGlvbl9pbmZvXVtnb29nbGUuY2xvdWQudGFsZW50
LnY0YmV0YTEuSm9iLmNvbXBlbnNhdGlvbl9pbmZvXS4KIEZvciBleGFtcGxlLCBpZiB0aGUg
ZmlsdGVyIGlzIHNwZWNpZmllZCBhcyAiSG91cmx5IGpvYiB3aXRoIHBlci1ob3VyCiBjb21w
ZW5zYXRpb24gPiAkMTUiLCBvbmx5IGpvYnMgbWVldGluZyB0aGVzZSBjcml0ZXJpYSBhcmUg
c2VhcmNoZWQuIElmIGEKIGZpbHRlciBpc24ndCBkZWZpbmVkLCBhbGwgb3BlbiBqb2JzIGFy
ZSBzZWFyY2hlZC4KCg0KBQQAAgcGEgSJAQIUCg0KBQQAAgcBEgSJARUoCg0KBQQAAgcDEgSJ
ASssCtoHCgQEAAIIEgSiAQIlGssHIFRoaXMgZmlsdGVyIHNwZWNpZmllcyBhIHN0cnVjdHVy
ZWQgc3ludGF4IHRvIG1hdGNoIGFnYWluc3QgdGhlCiBbSm9iLmN1c3RvbV9hdHRyaWJ1dGVz
XVtnb29nbGUuY2xvdWQudGFsZW50LnY0YmV0YTEuSm9iLmN1c3RvbV9hdHRyaWJ1dGVzXQog
bWFya2VkIGFzIGBmaWx0ZXJhYmxlYC4KCiBUaGUgc3ludGF4IGZvciB0aGlzIGV4cHJlc3Np
b24gaXMgYSBzdWJzZXQgb2YgU1FMIHN5bnRheC4KCiBTdXBwb3J0ZWQgb3BlcmF0b3JzIGFy
ZTogYD1gLCBgIT1gLCBgPGAsIGA8PWAsIGA+YCwgYW5kIGA+PWAgd2hlcmUgdGhlCiBsZWZ0
IG9mIHRoZSBvcGVyYXRvciBpcyBhIGN1c3RvbSBmaWVsZCBrZXkgYW5kIHRoZSByaWdodCBv
ZiB0aGUgb3BlcmF0b3IKIGlzIGEgbnVtYmVyIG9yIGEgcXVvdGVkIHN0cmluZy4gWW91IG11
c3QgZXNjYXBlIGJhY2tzbGFzaCAoXFwpIGFuZAogcXVvdGUgKFwiKSBjaGFyYWN0ZXJzLgoK
IFN1cHBvcnRlZCBmdW5jdGlvbnMgYXJlIGBMT1dFUihbZmllbGRfbmFtZV0pYCB0bwogcGVy
Zm9ybSBhIGNhc2UgaW5zZW5zaXRpdmUgbWF0Y2ggYW5kIGBFTVBUWShbZmllbGRfbmFtZV0p
YCB0byBmaWx0ZXIgb24gdGhlCiBleGlzdGVuY2Ugb2YgYSBrZXkuCgogQm9vbGVhbiBleHBy
ZXNzaW9ucyAoQU5EL09SL05PVCkgYXJlIHN1cHBvcnRlZCB1cCB0byAzIGxldmVscyBvZgog
bmVzdGluZyAoZm9yIGV4YW1wbGUsICIoKEEgQU5EIEIgQU5EIEMpIE9SIE5PVCBEKSBBTkQg
RSIpLCBhIG1heGltdW0gb2YgMTAwCiBjb21wYXJpc29ucyBvciBmdW5jdGlvbnMgYXJlIGFs
bG93ZWQgaW4gdGhlIGV4cHJlc3Npb24uIFRoZSBleHByZXNzaW9uCiBtdXN0IGJlIDwgMTAw
MDAgYnl0ZXMgaW4gbGVuZ3RoLgoKIFNhbXBsZSBRdWVyeToKIGAoTE9XRVIoZHJpdmluZ19s
aWNlbnNlKT0iY2xhc3MgXCJhXCIiIE9SIEVNUFRZKGRyaXZpbmdfbGljZW5zZSkpIEFORAog
ZHJpdmluZ195ZWFycyA+IDEwYAoKDQoFBAACCAUSBKIBAggKDQoFBAACCAESBKIBCSAKDQoF
BAACCAMSBKIBIyQK4AEKBAQAAgkSBKkBAh8a0QEgVGhpcyBmbGFnIGNvbnRyb2xzIHRoZSBz
cGVsbC1jaGVjayBmZWF0dXJlLiBJZiBmYWxzZSwgdGhlCiBzZXJ2aWNlIGF0dGVtcHRzIHRv
IGNvcnJlY3QgYSBtaXNzcGVsbGVkIHF1ZXJ5LAogZm9yIGV4YW1wbGUsICJlbmdpbmVlIiBp
cyBjb3JyZWN0ZWQgdG8gImVuZ2luZWVyIi4KCiBEZWZhdWx0cyB0byBmYWxzZTogYSBzcGVs
bCBjaGVjayBpcyBwZXJmb3JtZWQuCgoNCgUEAAIJBRIEqQECBgoNCgUEAAIJARIEqQEHGgoN
CgUEAAIJAxIEqQEdHgqHAwoEBAACChIEtAECMBr4AiBUaGUgZW1wbG95bWVudCB0eXBlIGZp
bHRlciBzcGVjaWZpZXMgdGhlIGVtcGxveW1lbnQgdHlwZSBvZiBqb2JzIHRvCiBzZWFyY2gg
YWdhaW5zdCwgc3VjaCBhcwogW0VtcGxveW1lbnRUeXBlLkZVTExfVElNRV1bZ29vZ2xlLmNs
b3VkLnRhbGVudC52NGJldGExLkVtcGxveW1lbnRUeXBlLkZVTExfVElNRV0uCgogSWYgYSB2
YWx1ZSBpc24ndCBzcGVjaWZpZWQsIGpvYnMgaW4gdGhlIHNlYXJjaCByZXN1bHRzIGluY2x1
ZGVzIGFueQogZW1wbG95bWVudCB0eXBlLgoKIElmIG11bHRpcGxlIHZhbHVlcyBhcmUgc3Bl
Y2lmaWVkLCBqb2JzIGluIHRoZSBzZWFyY2ggcmVzdWx0cyBpbmNsdWRlCiBhbnkgb2YgdGhl
IHNwZWNpZmllZCBlbXBsb3ltZW50IHR5cGVzLgoKDQoFBAACCgQSBLQBAgoKDQoFBAACCgYS
BLQBCxkKDQoFBAACCgESBLQBGioKDQoFBAACCgMSBLQBLS8KkgMKBAQAAgsSBMIBAiYagwMg
VGhpcyBmaWx0ZXIgc3BlY2lmaWVzIHRoZSBsb2NhbGUgb2Ygam9icyB0byBzZWFyY2ggYWdh
aW5zdCwKIGZvciBleGFtcGxlLCAiZW4tVVMiLgoKIElmIGEgdmFsdWUgaXNuJ3Qgc3BlY2lm
aWVkLCB0aGUgc2VhcmNoIHJlc3VsdHMgY2FuIGNvbnRhaW4gam9icyBpbiBhbnkKIGxvY2Fs
ZS4KCgogTGFuZ3VhZ2UgY29kZXMgc2hvdWxkIGJlIGluIEJDUC00NyBmb3JtYXQsIHN1Y2gg
YXMgImVuLVVTIiBvciAic3ItTGF0biIuCiBGb3IgbW9yZSBpbmZvcm1hdGlvbiwgc2VlCiBb
VGFncyBmb3IgSWRlbnRpZnlpbmcgTGFuZ3VhZ2VzXShodHRwczovL3Rvb2xzLmlldGYub3Jn
L2h0bWwvYmNwNDcpLgoKIEF0IG1vc3QgMTAgbGFuZ3VhZ2UgY29kZSBmaWx0ZXJzIGFyZSBh
bGxvd2VkLgoKDQoFBAACCwQSBMIBAgoKDQoFBAACCwUSBMIBCxEKDQoFBAACCwESBMIBEiAK
DQoFBAACCwMSBMIBIyUKXQoEBAACDBIExgECKRpPIEpvYnMgcHVibGlzaGVkIHdpdGhpbiBh
IHJhbmdlIHNwZWNpZmllZCBieSB0aGlzIGZpbHRlciBhcmUgc2VhcmNoZWQKIGFnYWluc3Qu
CgoNCgUEAAIMBhIExgECEAoNCgUEAAIMARIExgERIwoNCgUEAAIMAxIExgEmKAqFAQoEBAAC
DRIEywECJRp3IFRoaXMgZmlsdGVyIHNwZWNpZmllcyBhIGxpc3Qgb2Ygam9iIG5hbWVzIHRv
IGJlIGV4Y2x1ZGVkIGR1cmluZyBzZWFyY2guCgogQXQgbW9zdCA0MDAgZXhjbHVkZWQgam9i
IG5hbWVzIGFyZSBhbGxvd2VkLgoKDQoFBAACDQQSBMsBAgoKDQoFBAACDQUSBMsBCxEKDQoF
BAACDQESBMsBEh8KDQoFBAACDQMSBMsBIiQKMAoCBAESBs8BAJ0CARoiIEdlb2dyYXBoaWMg
cmVnaW9uIG9mIHRoZSBzZWFyY2guCgoLCgMEAQESBM8BCBYKPgoEBAEEABIG0QEC3gEDGi4g
U3BlY2lmeSB3aGV0aGVyIHRvIGluY2x1ZGUgdGVsZWNvbW11dGUgam9icy4KCg0KBQQBBAAB
EgTRAQccCk4KBgQBBAACABIE0wEEKxo+IERlZmF1bHQgdmFsdWUgaWYgdGhlIHRlbGVjb21t
dXRlIHByZWZlcmVuY2UgaXNuJ3Qgc3BlY2lmaWVkLgoKDwoHBAEEAAIAARIE0wEEJgoPCgcE
AQQAAgACEgTTASkqCoQBCgYEAQQAAgESBNcBBDEadCBEZXByZWNhdGVkOiBJZ25vcmUgdGVs
ZWNvbW11dGUgc3RhdHVzIG9mIGpvYnMuIFVzZQogVEVMRUNPTU1VVEVfSk9CU19FWENMVURF
RCBpZiB3YW50IHRvIGV4Y2x1ZGUgdGVsZWNvbW11dGUgam9icy4KCg8KBwQBBAACAQESBNcB
BBgKDwoHBAEEAAIBAhIE1wEbHAoPCgcEAQQAAgEDEgTXAR0wChAKCAQBBAACAQMBEgTXAR4v
CikKBgQBBAACAhIE2gEEHBoZIEFsbG93IHRlbGVjb21tdXRlIGpvYnMuCgoPCgcEAQQAAgIB
EgTaAQQXCg8KBwQBBAACAgISBNoBGhsKKwoGBAEEAAIDEgTdAQQiGhsgRXhjbHVkZSB0ZWxl
Y29tbXV0ZSBqb2JzLgoKDwoHBAEEAAIDARIE3QEEHQoPCgcEAQQAAgMCEgTdASAhCkgKBAQB
AgASBOEBAhUaOiBUaGUgYWRkcmVzcyBuYW1lLCBzdWNoIGFzICJNb3VudGFpbiBWaWV3IiBv
ciAiQmF5IEFyZWEiLgoKDQoFBAECAAUSBOEBAggKDQoFBAECAAESBOEBCRAKDQoFBAECAAMS
BOEBExQKvAYKBAQBAgESBPIBAhkarQYgQ0xEUiByZWdpb24gY29kZSBvZiB0aGUgY291bnRy
eS9yZWdpb24uIFRoaXMgZmllbGQgbWF5IGJlIHVzZWQgaW4gdHdvIHdheXM6CgogMSkgSWYg
dGVsZWNvbW11dGUgcHJlZmVyZW5jZSBpcyBub3Qgc2V0LCB0aGlzIGZpZWxkIGlzIHVzZWQg
YWRkcmVzcwogYW1iaWd1aXR5IG9mIHRoZSB1c2VyLWlucHV0IGFkZHJlc3MuIEZvciBleGFt
cGxlLCAiTGl2ZXJwb29sIiBtYXkgcmVmZXIgdG8KICJMaXZlcnBvb2wsIE5ZLCBVUyIgb3Ig
IkxpdmVycG9vbCwgVUsiLiBUaGlzIHJlZ2lvbiBjb2RlIGJpYXNlcyB0aGUKIGFkZHJlc3Mg
cmVzb2x1dGlvbiB0b3dhcmQgYSBzcGVjaWZpYyBjb3VudHJ5IG9yIHRlcnJpdG9yeS4gSWYg
dGhpcyBmaWVsZCBpcwogbm90IHNldCwgYWRkcmVzcyByZXNvbHV0aW9uIGlzIGJpYXNlZCB0
b3dhcmQgdGhlIFVuaXRlZCBTdGF0ZXMgYnkgZGVmYXVsdC4KCiAyKSBJZiB0ZWxlY29tbXV0
ZSBwcmVmZXJlbmNlIGlzIHNldCB0byBURUxFQ09NTVVURV9BTExPV0VELCB0aGUKIHRlbGVj
b21tdXRlIGxvY2F0aW9uIGZpbHRlciB3aWxsIGJlIGxpbWl0ZWQgdG8gdGhlIHJlZ2lvbiBz
cGVjaWZpZWQgaW4gdGhpcwogZmllbGQuIElmIHRoaXMgZmllbGQgaXMgbm90IHNldCwgdGhl
IHRlbGVjb21tdXRlIGpvYiBsb2NhdGlvbnMgd2lsbCBub3QgYmUKCiBTZWUKIGh0dHBzOi8v
dW5pY29kZS1vcmcuZ2l0aHViLmlvL2NsZHItc3RhZ2luZy9jaGFydHMvbGF0ZXN0L3N1cHBs
ZW1lbnRhbC90ZXJyaXRvcnlfaW5mb3JtYXRpb24uaHRtbAogZm9yIGRldGFpbHMuIEV4YW1w
bGU6ICJDSCIgZm9yIFN3aXR6ZXJsYW5kLgoKDQoFBAECAQUSBPIBAggKDQoFBAECAQESBPIB
CRQKDQoFBAECAQMSBPIBFxgKhAEKBAQBAgISBPYBAiEadiBUaGUgbGF0aXR1ZGUgYW5kIGxv
bmdpdHVkZSBvZiB0aGUgZ2VvZ3JhcGhpYyBjZW50ZXIgdG8gc2VhcmNoIGZyb20uIFRoaXMK
IGZpZWxkIGlzIGlnbm9yZWQgaWYgYGFkZHJlc3NgIGlzIHByb3ZpZGVkLgoKDQoFBAECAgYS
BPYBAhQKDQoFBAECAgESBPYBFRwKDQoFBAECAgMSBPYBHyAKywEKBAQBAgMSBPsBAh8avAEg
VGhlIGRpc3RhbmNlX2luX21pbGVzIGlzIGFwcGxpZWQgd2hlbiB0aGUgbG9jYXRpb24gYmVp
bmcgc2VhcmNoZWQgZm9yIGlzCiBpZGVudGlmaWVkIGFzIGEgY2l0eSBvciBzbWFsbGVyLiBU
aGlzIGZpZWxkIGlzIGlnbm9yZWQgaWYgdGhlIGxvY2F0aW9uCiBiZWluZyBzZWFyY2hlZCBm
b3IgaXMgYSBzdGF0ZSBvciBsYXJnZXIuCgoNCgUEAQIDBRIE+wECCAoNCgUEAQIDARIE+wEJ
GgoNCgUEAQIDAxIE+wEdHgqzDAoEBAECBBIEmAICMxqkDCBBbGxvd3MgdGhlIGNsaWVudCB0
byByZXR1cm4gam9icyB3aXRob3V0IGEKIHNldCBsb2NhdGlvbiwgc3BlY2lmaWNhbGx5LCB0
ZWxlY29tbXV0aW5nIGpvYnMgKHRlbGVjb21tdXRpbmcgaXMgY29uc2lkZXJlZAogYnkgdGhl
IHNlcnZpY2UgYXMgYSBzcGVjaWFsIGxvY2F0aW9uKS4KIFtKb2IucG9zdGluZ19yZWdpb25d
W2dvb2dsZS5jbG91ZC50YWxlbnQudjRiZXRhMS5Kb2IucG9zdGluZ19yZWdpb25dCiBpbmRp
Y2F0ZXMgaWYgYSBqb2IgcGVybWl0cyB0ZWxlY29tbXV0aW5nLiBJZiB0aGlzIGZpZWxkIGlz
IHNldCB0bwogW1RlbGVjb21tdXRlUHJlZmVyZW5jZS5URUxFQ09NTVVURV9BTExPV0VEXVtn
b29nbGUuY2xvdWQudGFsZW50LnY0YmV0YTEuTG9jYXRpb25GaWx0ZXIuVGVsZWNvbW11dGVQ
cmVmZXJlbmNlLlRFTEVDT01NVVRFX0FMTE9XRURdLAogdGVsZWNvbW11dGluZyBqb2JzIGFy
ZSBzZWFyY2hlZCwgYW5kCiBbYWRkcmVzc11bZ29vZ2xlLmNsb3VkLnRhbGVudC52NGJldGEx
LkxvY2F0aW9uRmlsdGVyLmFkZHJlc3NdIGFuZAogW2xhdF9sbmddW2dvb2dsZS5jbG91ZC50
YWxlbnQudjRiZXRhMS5Mb2NhdGlvbkZpbHRlci5sYXRfbG5nXSBhcmUgaWdub3JlZC4KIElm
IG5vdCBzZXQgb3Igc2V0IHRvCiBbVGVsZWNvbW11dGVQcmVmZXJlbmNlLlRFTEVDT01NVVRF
X0VYQ0xVREVEXVtnb29nbGUuY2xvdWQudGFsZW50LnY0YmV0YTEuTG9jYXRpb25GaWx0ZXIu
VGVsZWNvbW11dGVQcmVmZXJlbmNlLlRFTEVDT01NVVRFX0VYQ0xVREVEXSwKIHRoZSB0ZWxl
Y29tbXV0ZSBzdGF0dXMgb2YgdGhlIGpvYnMgaXMgaWdub3JlZC4gSm9icyB0aGF0IGhhdmUK
IFtQb3N0aW5nUmVnaW9uLlRFTEVDT01NVVRFXVtnb29nbGUuY2xvdWQudGFsZW50LnY0YmV0
YTEuUG9zdGluZ1JlZ2lvbi5URUxFQ09NTVVURV0KIGFuZCBoYXZlIGFkZGl0aW9uYWwKIFtK
b2IuYWRkcmVzc2VzXVtnb29nbGUuY2xvdWQudGFsZW50LnY0YmV0YTEuSm9iLmFkZHJlc3Nl
c10gbWF5IHN0aWxsIGJlCiBtYXRjaGVkIGJhc2VkIG9uIG90aGVyIGxvY2F0aW9uIGZpbHRl
cnMgdXNpbmcKIFthZGRyZXNzXVtnb29nbGUuY2xvdWQudGFsZW50LnY0YmV0YTEuTG9jYXRp
b25GaWx0ZXIuYWRkcmVzc10gb3IKIFtsYXRsbmddW10uCgogVGhpcyBmaWx0ZXIgY2FuIGJl
IHVzZWQgYnkgaXRzZWxmIHRvIHNlYXJjaCBleGNsdXNpdmVseSBmb3IgdGVsZWNvbW11dGlu
Zwogam9icywgb3IgaXQgY2FuIGJlIGNvbWJpbmVkIHdpdGggYW5vdGhlciBsb2NhdGlvbgog
ZmlsdGVyIHRvIHNlYXJjaCBmb3IgYSBjb21iaW5hdGlvbiBvZiBqb2IgbG9jYXRpb25zLAog
c3VjaCBhcyAiTW91bnRhaW4gVmlldyIgb3IgInRlbGVjb21tdXRpbmciIGpvYnMuIEhvd2V2
ZXIsIHdoZW4gdXNlZCBpbgogY29tYmluYXRpb24gd2l0aCBvdGhlciBsb2NhdGlvbiBmaWx0
ZXJzLCB0ZWxlY29tbXV0aW5nIGpvYnMgY2FuIGJlCiB0cmVhdGVkIGFzIGxlc3MgcmVsZXZh
bnQgdGhhbiBvdGhlciBqb2JzIGluIHRoZSBzZWFyY2ggcmVzcG9uc2UuCgogVGhpcyBmaWVs
ZCBpcyBvbmx5IHVzZWQgZm9yIGpvYiBzZWFyY2ggcmVxdWVzdHMuCgoNCgUEAQIEBhIEmAIC
FwoNCgUEAQIEARIEmAIYLgoNCgUEAQIEAxIEmAIxMgpmCgQEAQIFEgScAgITGlggV2hldGhl
ciB0byBhcHBseSBuZWdhdGlvbiB0byB0aGUgZmlsdGVyIHNvIHByb2ZpbGVzIG1hdGNoaW5n
IHRoZSBmaWx0ZXIKIGFyZSBleGNsdWRlZC4KCg0KBQQBAgUFEgScAgIGCg0KBQQBAgUBEgSc
AgcOCg0KBQQBAgUDEgScAhESCjsKAgQCEgagAgDdAgEaLSBGaWx0ZXIgb24gam9iIGNvbXBl
bnNhdGlvbiB0eXBlIGFuZCBhbW91bnQuCgoLCgMEAgESBKACCBoKMAoEBAIEABIGogICzQID
GiAgU3BlY2lmeSB0aGUgdHlwZSBvZiBmaWx0ZXJpbmcuCgoNCgUEAgQAARIEogIHEQpaCgYE
AgQAAgASBKQCBCAaSiBGaWx0ZXIgdHlwZSB1bnNwZWNpZmllZC4gUG9zaXRpb24gaG9sZGVy
LCBJTlZBTElELCBzaG91bGQgbmV2ZXIgYmUgdXNlZC4KCg8KBwQCBAACAAESBKQCBBsKDwoH
BAIEAAIAAhIEpAIeHwrvAwoGBAIEAAIBEgSwAgQSGt4DIEZpbHRlciBieSBgYmFzZSBjb21w
ZW5zYXRpb24gZW50cnknc2AgdW5pdC4gQSBqb2IgaXMgYSBtYXRjaCBpZiBhbmQKIG9ubHkg
aWYgdGhlIGpvYiBjb250YWlucyBhIGJhc2UgQ29tcGVuc2F0aW9uRW50cnkgYW5kIHRoZSBi
YXNlCiBDb21wZW5zYXRpb25FbnRyeSdzIHVuaXQgbWF0Y2hlcyBwcm92aWRlZAogW3VuaXRz
XVtnb29nbGUuY2xvdWQudGFsZW50LnY0YmV0YTEuQ29tcGVuc2F0aW9uRmlsdGVyLnVuaXRz
XS4gUG9wdWxhdGUKIG9uZSBvciBtb3JlCiBbdW5pdHNdW2dvb2dsZS5jbG91ZC50YWxlbnQu
djRiZXRhMS5Db21wZW5zYXRpb25GaWx0ZXIudW5pdHNdLgoKIFNlZQogW0NvbXBlbnNhdGlv
bkluZm8uQ29tcGVuc2F0aW9uRW50cnldW2dvb2dsZS5jbG91ZC50YWxlbnQudjRiZXRhMS5D
b21wZW5zYXRpb25JbmZvLkNvbXBlbnNhdGlvbkVudHJ5XQogZm9yIGRlZmluaXRpb24gb2Yg
YmFzZSBjb21wZW5zYXRpb24gZW50cnkuCgoPCgcEAgQAAgEBEgSwAgQNCg8KBwQCBAACAQIS
BLACEBEK1AUKBgQCBAACAhIEwAIEGBrDBSBGaWx0ZXIgYnkgYGJhc2UgY29tcGVuc2F0aW9u
IGVudHJ5J3NgIHVuaXQgYW5kIGFtb3VudCAvIHJhbmdlLiBBIGpvYgogaXMgYSBtYXRjaCBp
ZiBhbmQgb25seSBpZiB0aGUgam9iIGNvbnRhaW5zIGEgYmFzZSBDb21wZW5zYXRpb25FbnRy
eSwgYW5kCiB0aGUgYmFzZSBlbnRyeSdzIHVuaXQgbWF0Y2hlcyBwcm92aWRlZAogW0NvbXBl
bnNhdGlvblVuaXRdW2dvb2dsZS5jbG91ZC50YWxlbnQudjRiZXRhMS5Db21wZW5zYXRpb25J
bmZvLkNvbXBlbnNhdGlvblVuaXRdCiBhbmQgYW1vdW50IG9yIHJhbmdlIG92ZXJsYXBzIHdp
dGggcHJvdmlkZWQKIFtDb21wZW5zYXRpb25SYW5nZV1bZ29vZ2xlLmNsb3VkLnRhbGVudC52
NGJldGExLkNvbXBlbnNhdGlvbkluZm8uQ29tcGVuc2F0aW9uUmFuZ2VdLgoKIFNlZQogW0Nv
bXBlbnNhdGlvbkluZm8uQ29tcGVuc2F0aW9uRW50cnldW2dvb2dsZS5jbG91ZC50YWxlbnQu
djRiZXRhMS5Db21wZW5zYXRpb25JbmZvLkNvbXBlbnNhdGlvbkVudHJ5XQogZm9yIGRlZmlu
aXRpb24gb2YgYmFzZSBjb21wZW5zYXRpb24gZW50cnkuCgogU2V0IGV4YWN0bHkgb25lCiBb
dW5pdHNdW2dvb2dsZS5jbG91ZC50YWxlbnQudjRiZXRhMS5Db21wZW5zYXRpb25GaWx0ZXIu
dW5pdHNdIGFuZAogcG9wdWxhdGUgW3JhbmdlXVtnb29nbGUuY2xvdWQudGFsZW50LnY0YmV0
YTEuQ29tcGVuc2F0aW9uRmlsdGVyLnJhbmdlXS4KCg8KBwQCBAACAgESBMACBBMKDwoHBAIE
AAICAhIEwAIWFwqAAgoGBAIEAAIDEgTGAgQfGu8BIEZpbHRlciBieSBhbm51YWxpemVkIGJh
c2UgY29tcGVuc2F0aW9uIGFtb3VudCBhbmQgYGJhc2UgY29tcGVuc2F0aW9uCiBlbnRyeSdz
YCB1bml0LiBQb3B1bGF0ZQogW3JhbmdlXVtnb29nbGUuY2xvdWQudGFsZW50LnY0YmV0YTEu
Q29tcGVuc2F0aW9uRmlsdGVyLnJhbmdlXSBhbmQgemVybyBvcgogbW9yZSBbdW5pdHNdW2dv
b2dsZS5jbG91ZC50YWxlbnQudjRiZXRhMS5Db21wZW5zYXRpb25GaWx0ZXIudW5pdHNdLgoK
DwoHBAIEAAIDARIExgIEGgoPCgcEAgQAAgMCEgTGAh0eCoICCgYEAgQAAgQSBMwCBCAa8QEg
RmlsdGVyIGJ5IGFubnVhbGl6ZWQgdG90YWwgY29tcGVuc2F0aW9uIGFtb3VudCBhbmQgYGJh
c2UgY29tcGVuc2F0aW9uCiBlbnRyeSdzYCB1bml0IC4gUG9wdWxhdGUKIFtyYW5nZV1bZ29v
Z2xlLmNsb3VkLnRhbGVudC52NGJldGExLkNvbXBlbnNhdGlvbkZpbHRlci5yYW5nZV0gYW5k
IHplcm8gb3IKIG1vcmUgW3VuaXRzXVtnb29nbGUuY2xvdWQudGFsZW50LnY0YmV0YTEuQ29t
cGVuc2F0aW9uRmlsdGVyLnVuaXRzXS4KCg8KBwQCBAACBAESBMwCBBsKDwoHBAIEAAIEAhIE
zAIeHwopCgQEAgIAEgTQAgI/GhsgUmVxdWlyZWQuIFR5cGUgb2YgZmlsdGVyLgoKDQoFBAIC
AAYSBNACAgwKDQoFBAICAAESBNACDREKDQoFBAICAAMSBNACFBUKDQoFBAICAAgSBNACFj4K
EAoIBAICAAicCAASBNACFz0KrQEKBAQCAgESBtQCAtUCLxqcASBSZXF1aXJlZC4gU3BlY2lm
eSBkZXNpcmVkIGBiYXNlIGNvbXBlbnNhdGlvbiBlbnRyeSdzYAogW0NvbXBlbnNhdGlvbklu
Zm8uQ29tcGVuc2F0aW9uVW5pdF1bZ29vZ2xlLmNsb3VkLnRhbGVudC52NGJldGExLkNvbXBl
bnNhdGlvbkluZm8uQ29tcGVuc2F0aW9uVW5pdF0uCgoNCgUEAgIBBBIE1AICCgoNCgUEAgIB
BhIE1AILLAoNCgUEAgIBARIE1AItMgoNCgUEAgIBAxIE1AI1NgoNCgUEAgIBCBIE1QIGLgoQ
CggEAgIBCJwIABIE1QIHLQojCgQEAgICEgTYAgIvGhUgQ29tcGVuc2F0aW9uIHJhbmdlLgoK
DQoFBAICAgYSBNgCAiQKDQoFBAICAgESBNgCJSoKDQoFBAICAgMSBNgCLS4KXgoEBAICAxIE
3AICPBpQIElmIHNldCB0byB0cnVlLCBqb2JzIHdpdGggdW5zcGVjaWZpZWQgY29tcGVuc2F0
aW9uIHJhbmdlIGZpZWxkcyBhcmUKIGluY2x1ZGVkLgoKDQoFBAICAwUSBNwCAgYKDQoFBAIC
AwESBNwCBzcKDQoFBAICAwMSBNwCOjsKNQoCBAMSBuACAIwDARonIFBhcmFtZXRlcnMgbmVl
ZGVkIGZvciBjb21tdXRlIHNlYXJjaC4KCgsKAwQDARIE4AIIFQpLCgQEAwQAEgbiAgLrAgMa
OyBUaGUgdHJhZmZpYyBkZW5zaXR5IHRvIHVzZSB3aGVuIGNhbGN1bGF0aW5nIGNvbW11dGUg
dGltZS4KCg0KBQQDBAABEgTiAgcSCjkKBgQDBAACABIE5AIEIRopIFJvYWQgdHJhZmZpYyBz
aXR1YXRpb24gaXNuJ3Qgc3BlY2lmaWVkLgoKDwoHBAMEAAIAARIE5AIEHAoPCgcEAwQAAgAC
EgTkAh8gCk4KBgQDBAACARIE5wIEFRo+IE9wdGltYWwgY29tbXV0ZSB0aW1lIHdpdGhvdXQg
Y29uc2lkZXJpbmcgYW55IHRyYWZmaWMgaW1wYWN0LgoKDwoHBAMEAAIBARIE5wIEEAoPCgcE
AwQAAgECEgTnAhMUClQKBgQDBAACAhIE6gIEEhpEIENvbW11dGUgdGltZSBjYWxjdWxhdGlv
biB0YWtlcyBpbiBhY2NvdW50IHRoZSBwZWFrIHRyYWZmaWMgaW1wYWN0LgoKDwoHBAMEAAIC
ARIE6gIEDQoPCgcEAwQAAgICEgTqAhARClkKBAQDAgASBO4CAkwaSyBSZXF1aXJlZC4gVGhl
IG1ldGhvZCBvZiB0cmFuc3BvcnRhdGlvbiB0byBjYWxjdWxhdGUgdGhlIGNvbW11dGUgdGlt
ZSBmb3IuCgoNCgUEAwIABhIE7gICDwoNCgUEAwIAARIE7gIQHgoNCgUEAwIAAxIE7gIhIgoN
CgUEAwIACBIE7gIjSwoQCggEAwIACJwIABIE7gIkSgprCgQEAwIBEgbyAgLzAi8aWyBSZXF1
aXJlZC4gVGhlIGxhdGl0dWRlIGFuZCBsb25naXR1ZGUgb2YgdGhlIGxvY2F0aW9uIHRvIGNh
bGN1bGF0ZSB0aGUKIGNvbW11dGUgdGltZSBmcm9tLgoKDQoFBAMCAQYSBPICAhQKDQoFBAMC
AQESBPICFSYKDQoFBAMCAQMSBPICKSoKDQoFBAMCAQgSBPMCBi4KEAoIBAMCAQicCAASBPMC
By0KgwEKBAQDAgISBvcCAvgCLxpzIFJlcXVpcmVkLiBUaGUgbWF4aW11bSB0cmF2ZWwgdGlt
ZSBpbiBzZWNvbmRzLiBUaGUgbWF4aW11bSBhbGxvd2VkIHZhbHVlIGlzCiBgMzYwMHNgIChv
bmUgaG91cikuIEZvcm1hdCBpcyBgMTIzc2AuCgoNCgUEAwICBhIE9wICGgoNCgUEAwICARIE
9wIbKgoNCgUEAwICAxIE9wItLgoNCgUEAwICCBIE+AIGLgoQCggEAwICCJwIABIE+AIHLQrQ
AgoEBAMCAxIE/wICJRrBAiBJZiBgdHJ1ZWAsIGpvYnMgd2l0aG91dCBzdHJlZXQgbGV2ZWwg
YWRkcmVzc2VzIG1heSBhbHNvIGJlIHJldHVybmVkLgogRm9yIGNpdHkgbGV2ZWwgYWRkcmVz
c2VzLCB0aGUgY2l0eSBjZW50ZXIgaXMgdXNlZC4gRm9yIHN0YXRlIGFuZCBjb2Fyc2VyCiBs
ZXZlbCBhZGRyZXNzZXMsIHRleHQgbWF0Y2hpbmcgaXMgdXNlZC4KIElmIHRoaXMgZmllbGQg
aXMgc2V0IHRvIGBmYWxzZWAgb3IgaXNuJ3Qgc3BlY2lmaWVkLCBvbmx5IGpvYnMgdGhhdCBp
bmNsdWRlCiBzdHJlZXQgbGV2ZWwgYWRkcmVzc2VzIHdpbGwgYmUgcmV0dXJuZWQgYnkgY29t
bXV0ZSBzZWFyY2guCgoNCgUEAwIDBRIE/wICBgoNCgUEAwIDARIE/wIHIAoNCgUEAwIDAxIE
/wIjJApRCgQEAwgAEgaCAwKLAwMaQSBUcmFmZmljIGZhY3RvciB0byB0YWtlIGludG8gYWNj
b3VudCB3aGlsZSBzZWFyY2hpbmcgYnkgY29tbXV0ZS4KCg0KBQQDCAABEgSCAwgWClMKBAQD
AgQSBIQDBCEaRSBTcGVjaWZpZXMgdGhlIHRyYWZmaWMgZGVuc2l0eSB0byB1c2Ugd2hlbiBj
YWxjdWxhdGluZyBjb21tdXRlIHRpbWUuCgoNCgUEAwIEBhIEhAMEDwoNCgUEAwIEARIEhAMQ
HAoNCgUEAwIEAxIEhAMfIAraAQoEBAMCBRIEigMELRrLASBUaGUgZGVwYXJ0dXJlIHRpbWUg
dXNlZCB0byBjYWxjdWxhdGUgdHJhZmZpYyBpbXBhY3QsIHJlcHJlc2VudGVkIGFzCiBbZ29v
Z2xlLnR5cGUuVGltZU9mRGF5XVtnb29nbGUudHlwZS5UaW1lT2ZEYXldIGluIGxvY2FsIHRp
bWUgem9uZS4KCiBDdXJyZW50bHkgdHJhZmZpYyBtb2RlbCBpcyByZXN0cmljdGVkIHRvIGhv
dXIgbGV2ZWwgcmVzb2x1dGlvbi4KCg0KBQQDAgUGEgSKAwQZCg0KBQQDAgUBEgSKAxooCg0K
BQQDAgUDEgSKAyssYgZwcm90bzM=
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Talent::V4beta1::Filters::JobQuery ===
    # Fields for JobQuery
    # Field: query Type: 9 ()
    # Field: query_language_code Type: 9 ()
    # Field: companies Type: 9 ()
    # Field: location_filters Type: 11 (.google.cloud.talent.v4beta1.LocationFilter)
    # Field: job_categories Type: 14 (.google.cloud.talent.v4beta1.JobCategory)
    # Field: commute_filter Type: 11 (.google.cloud.talent.v4beta1.CommuteFilter)
    # Field: company_display_names Type: 9 ()
    # Field: compensation_filter Type: 11 (.google.cloud.talent.v4beta1.CompensationFilter)
    # Field: custom_attribute_filter Type: 9 ()
    # Field: disable_spell_check Type: 8 ()
    # Field: employment_types Type: 14 (.google.cloud.talent.v4beta1.EmploymentType)
    # Field: language_codes Type: 9 ()
    # Field: publish_time_range Type: 11 (.google.cloud.talent.v4beta1.TimestampRange)
    # Field: excluded_jobs Type: 9 ()

# === Message: Google::Cloud::Talent::V4beta1::Filters::LocationFilter ===
    # Fields for LocationFilter
    # Field: address Type: 9 ()
    # Field: region_code Type: 9 ()
    # Field: lat_lng Type: 11 (.google.type.LatLng)
    # Field: distance_in_miles Type: 1 ()
    # Field: telecommute_preference Type: 14 (.google.cloud.talent.v4beta1.LocationFilter.TelecommutePreference)
    # Field: negated Type: 8 ()

# Enum: LocationFilter::TelecommutePreference
our $LocationFilter_TELECOMMUTE_PREFERENCE_UNSPECIFIED = 0;
our $LocationFilter_TELECOMMUTE_EXCLUDED = 1;
our $LocationFilter_TELECOMMUTE_ALLOWED = 2;
our $LocationFilter_TELECOMMUTE_JOBS_EXCLUDED = 3;

# === Message: Google::Cloud::Talent::V4beta1::Filters::CompensationFilter ===
    # Fields for CompensationFilter
    # Field: type Type: 14 (.google.cloud.talent.v4beta1.CompensationFilter.FilterType)
    # Field: units Type: 14 (.google.cloud.talent.v4beta1.CompensationInfo.CompensationUnit)
    # Field: range Type: 11 (.google.cloud.talent.v4beta1.CompensationInfo.CompensationRange)
    # Field: include_jobs_with_unspecified_compensation_range Type: 8 ()

# Enum: CompensationFilter::FilterType
our $CompensationFilter_FILTER_TYPE_UNSPECIFIED = 0;
our $CompensationFilter_UNIT_ONLY = 1;
our $CompensationFilter_UNIT_AND_AMOUNT = 2;
our $CompensationFilter_ANNUALIZED_BASE_AMOUNT = 3;
our $CompensationFilter_ANNUALIZED_TOTAL_AMOUNT = 4;

# === Message: Google::Cloud::Talent::V4beta1::Filters::CommuteFilter ===
    # Fields for CommuteFilter
    # Field: commute_method Type: 14 (.google.cloud.talent.v4beta1.CommuteMethod)
    # Field: start_coordinates Type: 11 (.google.type.LatLng)
    # Field: travel_duration Type: 11 (.google.protobuf.Duration)
    # Field: allow_imprecise_addresses Type: 8 ()
    # Field: road_traffic Type: 14 (.google.cloud.talent.v4beta1.CommuteFilter.RoadTraffic)
    # Field: departure_time Type: 11 (.google.type.TimeOfDay)

# Enum: CommuteFilter::RoadTraffic
our $CommuteFilter_ROAD_TRAFFIC_UNSPECIFIED = 0;
our $CommuteFilter_TRAFFIC_FREE = 1;
our $CommuteFilter_BUSY_HOUR = 2;

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Talent::V4beta1::Filters - Compiled Protocol Buffers messages for google/cloud/talent/v4beta1/filters.proto

=head1 SYNOPSIS

    use Google::Cloud::Talent::V4beta1::Filters;

    my $msg = Google::Cloud::Talent::V4beta1::Filters::JobQuery->new({
        query => $query,
        query_language_code => $query_language_code,
        companies => $companies,
        location_filters => $location_filters,
    });

    # Read or update a field
    my $val = $msg->query();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Talent::V4beta1::Filters::JobQuery->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/talent/v4beta1/filters.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Talent::V4beta1::Filters::JobQuery

The query required to perform a search query.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->query() >> / C<< $msg->query($value) >>

Type: C<String>

The query string that matches against the job title, description, and
location fields.

The maximum number of allowed characters is 255.

=item * C<< $msg->query_language_code() >> / C<< $msg->query_language_code($value) >>

Type: C<String>

The language code of [query][google.cloud.talent.v4beta1.JobQuery.query].
For example, "en-US". This field helps to better interpret the query.

If a value isn't specified, the query language code is automatically
detected, which may not be accurate.

Language code should be in BCP-47 format, such as "en-US" or "sr-Latn".
For more information, see
[Tags for Identifying Languages](https://tools.ietf.org/html/bcp47).

=item * C<< $msg->companies() >> / C<< $msg->companies($value) >>

Type: C<String>

This filter specifies the company entities to search against.

If a value isn't specified, jobs are searched for against all
companies.

If multiple values are specified, jobs are searched against the
companies specified.

The format is
"projects/{project_id}/tenants/{tenant_id}/companies/{company_id}". For
example, "projects/foo/tenants/bar/companies/baz".

If tenant id is unspecified, the default tenant is used. For
example, "projects/foo/companies/bar".

At most 20 company filters are allowed.

=item * C<< $msg->location_filters() >> / C<< $msg->location_filters($value) >>

Type: C<Message> (L<Google::Cloud::Talent::V4beta1::Filters::LocationFilter>)

The location filter specifies geo-regions containing the jobs to
search against. See
[LocationFilter][google.cloud.talent.v4beta1.LocationFilter] for more
information.

If a location value isn't specified, jobs fitting the other search
criteria are retrieved regardless of where they're located.

If multiple values are specified, jobs are retrieved from any of the
specified locations. If different values are specified for the
[LocationFilter.distance_in_miles][google.cloud.talent.v4beta1.LocationFilter.distance_in_miles]
parameter, the maximum provided distance is used for all locations.

At most 5 location filters are allowed.

=item * C<< $msg->job_categories() >> / C<< $msg->job_categories($value) >>

Type: C<Enum> (L<Google::Cloud::Talent::V4beta1::JobCategory>)

The category filter specifies the categories of jobs to search against.
See [JobCategory][google.cloud.talent.v4beta1.JobCategory] for more
information.

If a value isn't specified, jobs from any category are searched against.

If multiple values are specified, jobs from any of the specified
categories are searched against.

=item * C<< $msg->commute_filter() >> / C<< $msg->commute_filter($value) >>

Type: C<Message> (L<Google::Cloud::Talent::V4beta1::Filters::CommuteFilter>)

Allows filtering jobs by commute time with different travel methods (for
 example, driving or public transit).

Note: This only works when you specify a
[CommuteMethod][google.cloud.talent.v4beta1.CommuteMethod]. In this case,
[location_filters][google.cloud.talent.v4beta1.JobQuery.location_filters]
is ignored.

 Currently we don't support sorting by commute time.

=item * C<< $msg->company_display_names() >> / C<< $msg->company_display_names($value) >>

Type: C<String>

This filter specifies the company
[Company.display_name][google.cloud.talent.v4beta1.Company.display_name] of
the jobs to search against. The company name must match the value exactly.

Alternatively, the value being searched for can be wrapped in different
match operators.
`SUBSTRING_MATCH([value])`
The company name must contain a case insensitive substring match of the
value. Using this function may increase latency.

Sample Value: `SUBSTRING_MATCH(google)`

`MULTI_WORD_TOKEN_MATCH([value])`
The value will be treated as a multi word token and the company name must
contain a case insensitive match of the value. Using this function may
increase latency.

Sample Value: `MULTI_WORD_TOKEN_MATCH(google)`

If a value isn't specified, jobs within the search results are
associated with any company.

If multiple values are specified, jobs within the search results may be
associated with any of the specified companies.

At most 20 company display name filters are allowed.

=item * C<< $msg->compensation_filter() >> / C<< $msg->compensation_filter($value) >>

Type: C<Message> (L<Google::Cloud::Talent::V4beta1::Filters::CompensationFilter>)

This search filter is applied only to
[Job.compensation_info][google.cloud.talent.v4beta1.Job.compensation_info].
For example, if the filter is specified as "Hourly job with per-hour
compensation > $15", only jobs meeting these criteria are searched. If a
filter isn't defined, all open jobs are searched.

=item * C<< $msg->custom_attribute_filter() >> / C<< $msg->custom_attribute_filter($value) >>

Type: C<String>

This filter specifies a structured syntax to match against the
[Job.custom_attributes][google.cloud.talent.v4beta1.Job.custom_attributes]
marked as `filterable`.

The syntax for this expression is a subset of SQL syntax.

Supported operators are: `=`, `!=`, `<`, `<=`, `>`, and `>=` where the
left of the operator is a custom field key and the right of the operator
is a number or a quoted string. You must escape backslash (\\) and
quote (\") characters.

Supported functions are `LOWER([field_name])` to
perform a case insensitive match and `EMPTY([field_name])` to filter on the
existence of a key.

Boolean expressions (AND/OR/NOT) are supported up to 3 levels of
nesting (for example, "((A AND B AND C) OR NOT D) AND E"), a maximum of 100
comparisons or functions are allowed in the expression. The expression
must be < 10000 bytes in length.

Sample Query:
`(LOWER(driving_license)="class \"a\"" OR EMPTY(driving_license)) AND
driving_years > 10`

=item * C<< $msg->disable_spell_check() >> / C<< $msg->disable_spell_check($value) >>

Type: C<Bool>

This flag controls the spell-check feature. If false, the
service attempts to correct a misspelled query,
for example, "enginee" is corrected to "engineer".

Defaults to false: a spell check is performed.

=item * C<< $msg->employment_types() >> / C<< $msg->employment_types($value) >>

Type: C<Enum> (L<Google::Cloud::Talent::V4beta1::EmploymentType>)

The employment type filter specifies the employment type of jobs to
search against, such as
[EmploymentType.FULL_TIME][google.cloud.talent.v4beta1.EmploymentType.FULL_TIME].

If a value isn't specified, jobs in the search results includes any
employment type.

If multiple values are specified, jobs in the search results include
any of the specified employment types.

=item * C<< $msg->language_codes() >> / C<< $msg->language_codes($value) >>

Type: C<String>

This filter specifies the locale of jobs to search against,
for example, "en-US".

If a value isn't specified, the search results can contain jobs in any
locale.


Language codes should be in BCP-47 format, such as "en-US" or "sr-Latn".
For more information, see
[Tags for Identifying Languages](https://tools.ietf.org/html/bcp47).

At most 10 language code filters are allowed.

=item * C<< $msg->publish_time_range() >> / C<< $msg->publish_time_range($value) >>

Type: C<Message> (L<Google::Cloud::Talent::V4beta1::Common::TimestampRange>)

Jobs published within a range specified by this filter are searched
against.

=item * C<< $msg->excluded_jobs() >> / C<< $msg->excluded_jobs($value) >>

Type: C<String>

This filter specifies a list of job names to be excluded during search.

At most 400 excluded job names are allowed.

=back

=head2 Google::Cloud::Talent::V4beta1::Filters::LocationFilter

Geographic region of the search.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->address() >> / C<< $msg->address($value) >>

Type: C<String>

The address name, such as "Mountain View" or "Bay Area".

=item * C<< $msg->region_code() >> / C<< $msg->region_code($value) >>

Type: C<String>

CLDR region code of the country/region. This field may be used in two ways:

1) If telecommute preference is not set, this field is used address
ambiguity of the user-input address. For example, "Liverpool" may refer to
"Liverpool, NY, US" or "Liverpool, UK". This region code biases the
address resolution toward a specific country or territory. If this field is
not set, address resolution is biased toward the United States by default.

2) If telecommute preference is set to TELECOMMUTE_ALLOWED, the
telecommute location filter will be limited to the region specified in this
field. If this field is not set, the telecommute job locations will not be

See
https://unicode-org.github.io/cldr-staging/charts/latest/supplemental/territory_information.html
for details. Example: "CH" for Switzerland.

=item * C<< $msg->lat_lng() >> / C<< $msg->lat_lng($value) >>

Type: C<Message> (L<Google::Type::Latlng::LatLng>)

The latitude and longitude of the geographic center to search from. This
field is ignored if `address` is provided.

=item * C<< $msg->distance_in_miles() >> / C<< $msg->distance_in_miles($value) >>

Type: C<Double>

The distance_in_miles is applied when the location being searched for is
identified as a city or smaller. This field is ignored if the location
being searched for is a state or larger.

=item * C<< $msg->telecommute_preference() >> / C<< $msg->telecommute_preference($value) >>

Type: C<Enum> (L<Google::Cloud::Talent::V4beta1::LocationFilter::TelecommutePreference>)

Allows the client to return jobs without a
set location, specifically, telecommuting jobs (telecommuting is considered
by the service as a special location).
[Job.posting_region][google.cloud.talent.v4beta1.Job.posting_region]
indicates if a job permits telecommuting. If this field is set to
[TelecommutePreference.TELECOMMUTE_ALLOWED][google.cloud.talent.v4beta1.LocationFilter.TelecommutePreference.TELECOMMUTE_ALLOWED],
telecommuting jobs are searched, and
[address][google.cloud.talent.v4beta1.LocationFilter.address] and
[lat_lng][google.cloud.talent.v4beta1.LocationFilter.lat_lng] are ignored.
If not set or set to
[TelecommutePreference.TELECOMMUTE_EXCLUDED][google.cloud.talent.v4beta1.LocationFilter.TelecommutePreference.TELECOMMUTE_EXCLUDED],
the telecommute status of the jobs is ignored. Jobs that have
[PostingRegion.TELECOMMUTE][google.cloud.talent.v4beta1.PostingRegion.TELECOMMUTE]
and have additional
[Job.addresses][google.cloud.talent.v4beta1.Job.addresses] may still be
matched based on other location filters using
[address][google.cloud.talent.v4beta1.LocationFilter.address] or
[latlng][].

This filter can be used by itself to search exclusively for telecommuting
jobs, or it can be combined with another location
filter to search for a combination of job locations,
such as "Mountain View" or "telecommuting" jobs. However, when used in
combination with other location filters, telecommuting jobs can be
treated as less relevant than other jobs in the search response.

This field is only used for job search requests.

=item * C<< $msg->negated() >> / C<< $msg->negated($value) >>

Type: C<Bool>

Whether to apply negation to the filter so profiles matching the filter
are excluded.

=back

=head3 Enum: LocationFilter::TelecommutePreference

=over 4

=item * C<TELECOMMUTE_PREFERENCE_UNSPECIFIED> => C<0>

=item * C<TELECOMMUTE_EXCLUDED> => C<1>

=item * C<TELECOMMUTE_ALLOWED> => C<2>

=item * C<TELECOMMUTE_JOBS_EXCLUDED> => C<3>

=back

=head2 Google::Cloud::Talent::V4beta1::Filters::CompensationFilter

Filter on job compensation type and amount.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->type() >> / C<< $msg->type($value) >>

Type: C<Enum> (L<Google::Cloud::Talent::V4beta1::CompensationFilter::FilterType>)

Required. Type of filter.

=item * C<< $msg->units() >> / C<< $msg->units($value) >>

Type: C<Enum> (L<Google::Cloud::Talent::V4beta1::CompensationInfo::CompensationUnit>)

Required. Specify desired `base compensation entry's`
[CompensationInfo.CompensationUnit][google.cloud.talent.v4beta1.CompensationInfo.CompensationUnit].

=item * C<< $msg->range() >> / C<< $msg->range($value) >>

Type: C<Message> (L<Google::Cloud::Talent::V4beta1::Common::CompensationInfo::CompensationRange>)

Compensation range.

=item * C<< $msg->include_jobs_with_unspecified_compensation_range() >> / C<< $msg->include_jobs_with_unspecified_compensation_range($value) >>

Type: C<Bool>

If set to true, jobs with unspecified compensation range fields are
included.

=back

=head3 Enum: CompensationFilter::FilterType

=over 4

=item * C<FILTER_TYPE_UNSPECIFIED> => C<0>

=item * C<UNIT_ONLY> => C<1>

=item * C<UNIT_AND_AMOUNT> => C<2>

=item * C<ANNUALIZED_BASE_AMOUNT> => C<3>

=item * C<ANNUALIZED_TOTAL_AMOUNT> => C<4>

=back

=head2 Google::Cloud::Talent::V4beta1::Filters::CommuteFilter

Parameters needed for commute search.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->commute_method() >> / C<< $msg->commute_method($value) >>

Type: C<Enum> (L<Google::Cloud::Talent::V4beta1::CommuteMethod>)

Required. The method of transportation to calculate the commute time for.

=item * C<< $msg->start_coordinates() >> / C<< $msg->start_coordinates($value) >>

Type: C<Message> (L<Google::Type::Latlng::LatLng>)

Required. The latitude and longitude of the location to calculate the
commute time from.

=item * C<< $msg->travel_duration() >> / C<< $msg->travel_duration($value) >>

Type: C<Message> (L<Google::Protobuf::Duration::Duration>)

Required. The maximum travel time in seconds. The maximum allowed value is
`3600s` (one hour). Format is `123s`.

=item * C<< $msg->allow_imprecise_addresses() >> / C<< $msg->allow_imprecise_addresses($value) >>

Type: C<Bool>

If `true`, jobs without street level addresses may also be returned.
For city level addresses, the city center is used. For state and coarser
level addresses, text matching is used.
If this field is set to `false` or isn't specified, only jobs that include
street level addresses will be returned by commute search.

=item * C<< $msg->road_traffic() >> / C<< $msg->road_traffic($value) >>

Type: C<Enum> (L<Google::Cloud::Talent::V4beta1::CommuteFilter::RoadTraffic>)

Specifies the traffic density to use when calculating commute time.

=item * C<< $msg->departure_time() >> / C<< $msg->departure_time($value) >>

Type: C<Message> (L<Google::Type::Timeofday::TimeOfDay>)

The departure time used to calculate traffic impact, represented as
[google.type.TimeOfDay][google.type.TimeOfDay] in local time zone.

Currently traffic model is restricted to hour level resolution.

=back

=head3 Enum: CommuteFilter::RoadTraffic

=over 4

=item * C<ROAD_TRAFFIC_UNSPECIFIED> => C<0>

=item * C<TRAFFIC_FREE> => C<1>

=item * C<BUSY_HOUR> => C<2>

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Talent::V4beta1::Filters::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
