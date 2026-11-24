package Google::Cloud::Datacatalog::V1::Tags;

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
    my $descriptor_b64 = <<'EOF';
CiZnb29nbGUvY2xvdWQvZGF0YWNhdGFsb2cvdjEvdGFncy5wcm90bxIbZ29vZ2xlLmNsb3Vk
LmRhdGFjYXRhbG9nLnYxGh9nb29nbGUvYXBpL2ZpZWxkX2JlaGF2aW9yLnByb3RvGhlnb29n
bGUvYXBpL3Jlc291cmNlLnByb3RvGh9nb29nbGUvcHJvdG9idWYvdGltZXN0YW1wLnByb3Rv
IswECgNUYWcSFwoEbmFtZRgBIAEoCUID4EEIUgRuYW1lEh8KCHRlbXBsYXRlGAIgASgJQgPg
QQJSCHRlbXBsYXRlEjcKFXRlbXBsYXRlX2Rpc3BsYXlfbmFtZRgFIAEoCUID4EEDUhN0ZW1w
bGF0ZURpc3BsYXlOYW1lEhgKBmNvbHVtbhgEIAEoCUgAUgZjb2x1bW4SSQoGZmllbGRzGAMg
AygLMiwuZ29vZ2xlLmNsb3VkLmRhdGFjYXRhbG9nLnYxLlRhZy5GaWVsZHNFbnRyeUID4EEC
UgZmaWVsZHMSfgoYZGF0YXBsZXhfdHJhbnNmZXJfc3RhdHVzGAcgASgOMj8uZ29vZ2xlLmNs
b3VkLmRhdGFjYXRhbG9nLnYxLlRhZ1RlbXBsYXRlLkRhdGFwbGV4VHJhbnNmZXJTdGF0dXNC
A+BBA1IWZGF0YXBsZXhUcmFuc2ZlclN0YXR1cxpgCgtGaWVsZHNFbnRyeRIQCgNrZXkYASAB
KAlSA2tleRI7CgV2YWx1ZRgCIAEoCzIlLmdvb2dsZS5jbG91ZC5kYXRhY2F0YWxvZy52MS5U
YWdGaWVsZFIFdmFsdWU6AjgBOoEB6kF+Ch5kYXRhY2F0YWxvZy5nb29nbGVhcGlzLmNvbS9U
YWcSXHByb2plY3RzL3twcm9qZWN0fS9sb2NhdGlvbnMve2xvY2F0aW9ufS9lbnRyeUdyb3Vw
cy97ZW50cnlfZ3JvdXB9L2VudHJpZXMve2VudHJ5fS90YWdzL3t0YWd9QgcKBXNjb3BlIrID
CghUYWdGaWVsZBImCgxkaXNwbGF5X25hbWUYASABKAlCA+BBA1ILZGlzcGxheU5hbWUSIwoM
ZG91YmxlX3ZhbHVlGAIgASgBSABSC2RvdWJsZVZhbHVlEiMKDHN0cmluZ192YWx1ZRgDIAEo
CUgAUgtzdHJpbmdWYWx1ZRIfCgpib29sX3ZhbHVlGAQgASgISABSCWJvb2xWYWx1ZRJFCg90
aW1lc3RhbXBfdmFsdWUYBSABKAsyGi5nb29nbGUucHJvdG9idWYuVGltZXN0YW1wSABSDnRp
bWVzdGFtcFZhbHVlElAKCmVudW1fdmFsdWUYBiABKAsyLy5nb29nbGUuY2xvdWQuZGF0YWNh
dGFsb2cudjEuVGFnRmllbGQuRW51bVZhbHVlSABSCWVudW1WYWx1ZRInCg5yaWNodGV4dF92
YWx1ZRgIIAEoCUgAUg1yaWNodGV4dFZhbHVlEhkKBW9yZGVyGAcgASgFQgPgQQNSBW9yZGVy
Gi4KCUVudW1WYWx1ZRIhCgxkaXNwbGF5X25hbWUYASABKAlSC2Rpc3BsYXlOYW1lQgYKBGtp
bmQikQUKC1RhZ1RlbXBsYXRlEhcKBG5hbWUYASABKAlCA+BBCFIEbmFtZRIhCgxkaXNwbGF5
X25hbWUYAiABKAlSC2Rpc3BsYXlOYW1lEjAKFGlzX3B1YmxpY2x5X3JlYWRhYmxlGAUgASgI
UhJpc1B1YmxpY2x5UmVhZGFibGUSUQoGZmllbGRzGAMgAygLMjQuZ29vZ2xlLmNsb3VkLmRh
dGFjYXRhbG9nLnYxLlRhZ1RlbXBsYXRlLkZpZWxkc0VudHJ5QgPgQQJSBmZpZWxkcxJ+Chhk
YXRhcGxleF90cmFuc2Zlcl9zdGF0dXMYByABKA4yPy5nb29nbGUuY2xvdWQuZGF0YWNhdGFs
b2cudjEuVGFnVGVtcGxhdGUuRGF0YXBsZXhUcmFuc2ZlclN0YXR1c0ID4EEBUhZkYXRhcGxl
eFRyYW5zZmVyU3RhdHVzGmgKC0ZpZWxkc0VudHJ5EhAKA2tleRgBIAEoCVIDa2V5EkMKBXZh
bHVlGAIgASgLMi0uZ29vZ2xlLmNsb3VkLmRhdGFjYXRhbG9nLnYxLlRhZ1RlbXBsYXRlRmll
bGRSBXZhbHVlOgI4ASJlChZEYXRhcGxleFRyYW5zZmVyU3RhdHVzEigKJERBVEFQTEVYX1RS
QU5TRkVSX1NUQVRVU19VTlNQRUNJRklFRBAAEhAKCE1JR1JBVEVEEAEaAggBEg8KC1RSQU5T
RkVSUkVEEAI6cOpBbQomZGF0YWNhdGFsb2cuZ29vZ2xlYXBpcy5jb20vVGFnVGVtcGxhdGUS
Q3Byb2plY3RzL3twcm9qZWN0fS9sb2NhdGlvbnMve2xvY2F0aW9ufS90YWdUZW1wbGF0ZXMv
e3RhZ190ZW1wbGF0ZX0i8AIKEFRhZ1RlbXBsYXRlRmllbGQSFwoEbmFtZRgGIAEoCUID4EEI
UgRuYW1lEiEKDGRpc3BsYXlfbmFtZRgBIAEoCVILZGlzcGxheU5hbWUSPwoEdHlwZRgCIAEo
CzImLmdvb2dsZS5jbG91ZC5kYXRhY2F0YWxvZy52MS5GaWVsZFR5cGVCA+BBAlIEdHlwZRIf
Cgtpc19yZXF1aXJlZBgDIAEoCFIKaXNSZXF1aXJlZBIgCgtkZXNjcmlwdGlvbhgEIAEoCVIL
ZGVzY3JpcHRpb24SFAoFb3JkZXIYBSABKAVSBW9yZGVyOoUB6kGBAQorZGF0YWNhdGFsb2cu
Z29vZ2xlYXBpcy5jb20vVGFnVGVtcGxhdGVGaWVsZBJScHJvamVjdHMve3Byb2plY3R9L2xv
Y2F0aW9ucy97bG9jYXRpb259L3RhZ1RlbXBsYXRlcy97dGFnX3RlbXBsYXRlfS9maWVsZHMv
e2ZpZWxkfSLbAwoJRmllbGRUeXBlEl0KDnByaW1pdGl2ZV90eXBlGAEgASgOMjQuZ29vZ2xl
LmNsb3VkLmRhdGFjYXRhbG9nLnYxLkZpZWxkVHlwZS5QcmltaXRpdmVUeXBlSABSDXByaW1p
dGl2ZVR5cGUSTgoJZW51bV90eXBlGAIgASgLMi8uZ29vZ2xlLmNsb3VkLmRhdGFjYXRhbG9n
LnYxLkZpZWxkVHlwZS5FbnVtVHlwZUgAUghlbnVtVHlwZRqhAQoIRW51bVR5cGUSYAoOYWxs
b3dlZF92YWx1ZXMYASADKAsyOS5nb29nbGUuY2xvdWQuZGF0YWNhdGFsb2cudjEuRmllbGRU
eXBlLkVudW1UeXBlLkVudW1WYWx1ZVINYWxsb3dlZFZhbHVlcxozCglFbnVtVmFsdWUSJgoM
ZGlzcGxheV9uYW1lGAEgASgJQgPgQQJSC2Rpc3BsYXlOYW1lIm4KDVByaW1pdGl2ZVR5cGUS
HgoaUFJJTUlUSVZFX1RZUEVfVU5TUEVDSUZJRUQQABIKCgZET1VCTEUQARIKCgZTVFJJTkcQ
AhIICgRCT09MEAMSDQoJVElNRVNUQU1QEAQSDAoIUklDSFRFWFQQBUILCgl0eXBlX2RlY2xC
wwEKH2NvbS5nb29nbGUuY2xvdWQuZGF0YWNhdGFsb2cudjFQAVpBY2xvdWQuZ29vZ2xlLmNv
bS9nby9kYXRhY2F0YWxvZy9hcGl2MS9kYXRhY2F0YWxvZ3BiO2RhdGFjYXRhbG9ncGKqAhtH
b29nbGUuQ2xvdWQuRGF0YUNhdGFsb2cuVjHKAhtHb29nbGVcQ2xvdWRcRGF0YUNhdGFsb2dc
VjHqAh5Hb29nbGU6OkNsb3VkOjpEYXRhQ2F0YWxvZzo6VjFK21YKBxIFDgCyAgEKvAQKAQwS
Aw4AEjKxBCBDb3B5cmlnaHQgMjAyNSBHb29nbGUgTExDCgogTGljZW5zZWQgdW5kZXIgdGhl
IEFwYWNoZSBMaWNlbnNlLCBWZXJzaW9uIDIuMCAodGhlICJMaWNlbnNlIik7CiB5b3UgbWF5
IG5vdCB1c2UgdGhpcyBmaWxlIGV4Y2VwdCBpbiBjb21wbGlhbmNlIHdpdGggdGhlIExpY2Vu
c2UuCiBZb3UgbWF5IG9idGFpbiBhIGNvcHkgb2YgdGhlIExpY2Vuc2UgYXQKCiAgICAgaHR0
cDovL3d3dy5hcGFjaGUub3JnL2xpY2Vuc2VzL0xJQ0VOU0UtMi4wCgogVW5sZXNzIHJlcXVp
cmVkIGJ5IGFwcGxpY2FibGUgbGF3IG9yIGFncmVlZCB0byBpbiB3cml0aW5nLCBzb2Z0d2Fy
ZQogZGlzdHJpYnV0ZWQgdW5kZXIgdGhlIExpY2Vuc2UgaXMgZGlzdHJpYnV0ZWQgb24gYW4g
IkFTIElTIiBCQVNJUywKIFdJVEhPVVQgV0FSUkFOVElFUyBPUiBDT05ESVRJT05TIE9GIEFO
WSBLSU5ELCBlaXRoZXIgZXhwcmVzcyBvciBpbXBsaWVkLgogU2VlIHRoZSBMaWNlbnNlIGZv
ciB0aGUgc3BlY2lmaWMgbGFuZ3VhZ2UgZ292ZXJuaW5nIHBlcm1pc3Npb25zIGFuZAogbGlt
aXRhdGlvbnMgdW5kZXIgdGhlIExpY2Vuc2UuCgoICgECEgMQACQKCQoCAwASAxIAKQoJCgID
ARIDEwAjCgkKAgMCEgMUACkKCAoBCBIDFgA4CgkKAgglEgMWADgKCAoBCBIDFwBYCgkKAggL
EgMXAFgKCAoBCBIDGAAiCgkKAggKEgMYACIKCAoBCBIDGQA4CgkKAggBEgMZADgKCAoBCBID
GgA4CgkKAggpEgMaADgKCAoBCBIDGwA3CgkKAggtEgMbADcKqQIKAgQAEgQjAFQBGpwCIFRh
Z3MgY29udGFpbiBjdXN0b20gbWV0YWRhdGEgYW5kIGFyZSBhdHRhY2hlZCB0byBEYXRhIENh
dGFsb2cgcmVzb3VyY2VzLiBUYWdzCiBjb25mb3JtIHdpdGggdGhlIHNwZWNpZmljYXRpb24g
b2YgdGhlaXIgdGFnIHRlbXBsYXRlLgoKIFNlZSBbRGF0YSBDYXRhbG9nCiBJQU1dKGh0dHBz
Oi8vY2xvdWQuZ29vZ2xlLmNvbS9kYXRhLWNhdGFsb2cvZG9jcy9jb25jZXB0cy9pYW0pIGZv
ciBpbmZvcm1hdGlvbgogb24gdGhlIHBlcm1pc3Npb25zIG5lZWRlZCB0byBjcmVhdGUgb3Ig
dmlldyB0YWdzLgoKCgoDBAABEgMjCAsKCwoDBAAHEgQkAicECg0KBQQAB50IEgQkAicECskB
CgQEAAIAEgMuAj0auwEgSWRlbnRpZmllci4gVGhlIHJlc291cmNlIG5hbWUgb2YgdGhlIHRh
ZyBpbiBVUkwgZm9ybWF0IHdoZXJlIHRhZyBJRCBpcyBhCiBzeXN0ZW0tZ2VuZXJhdGVkIGlk
ZW50aWZpZXIuCgogTm90ZTogVGhlIHRhZyBpdHNlbGYgbWlnaHQgbm90IGJlIHN0b3JlZCBp
biB0aGUgbG9jYXRpb24gc3BlY2lmaWVkIGluIGl0cwogbmFtZS4KCgwKBQQAAgAFEgMuAggK
DAoFBAACAAESAy4JDQoMCgUEAAIAAxIDLhARCgwKBQQAAgAIEgMuEjwKDwoIBAACAAicCAAS
Ay4TOwrVAQoEBAACARIDNQI/GscBIFJlcXVpcmVkLiBUaGUgcmVzb3VyY2UgbmFtZSBvZiB0
aGUgdGFnIHRlbXBsYXRlIHRoaXMgdGFnIHVzZXMuIEV4YW1wbGU6CgogYHByb2plY3RzL3tQ
Uk9KRUNUX0lEfS9sb2NhdGlvbnMve0xPQ0FUSU9OfS90YWdUZW1wbGF0ZXMve1RBR19URU1Q
TEFURV9JRH1gCgogVGhpcyBmaWVsZCBjYW5ub3QgYmUgbW9kaWZpZWQgYWZ0ZXIgY3JlYXRp
b24uCgoMCgUEAAIBBRIDNQIICgwKBQQAAgEBEgM1CREKDAoFBAACAQMSAzUUFQoMCgUEAAIB
CBIDNRY+Cg8KCAQAAgEInAgAEgM1Fz0KQQoEBAACAhIDOAJPGjQgT3V0cHV0IG9ubHkuIFRo
ZSBkaXNwbGF5IG5hbWUgb2YgdGhlIHRhZyB0ZW1wbGF0ZS4KCgwKBQQAAgIFEgM4AggKDAoF
BAACAgESAzgJHgoMCgUEAAICAxIDOCEiCgwKBQQAAgIIEgM4I04KDwoIBAACAgicCAASAzgk
TQqhAgoEBAAIABIEQQJIAxqSAiBUaGUgc2NvcGUgd2l0aGluIHRoZSBwYXJlbnQgcmVzb3Vy
Y2UgdGhhdCB0aGlzIHRhZyBpcyBhdHRhY2hlZCB0by4gSWYgbm90CiBwcm92aWRlZCwgdGhl
IHRhZyBpcyBhdHRhY2hlZCB0byB0aGUgcGFyZW50IHJlc291cmNlIGl0c2VsZi4KCiBEZWxl
dGluZyB0aGUgc2NvcGUgZnJvbSB0aGUgcGFyZW50IHJlc291cmNlIGRlbGV0ZXMgYWxsIHRh
Z3MgYXR0YWNoZWQKIHRvIHRoYXQgc2NvcGUuCgogVGhlc2UgZmllbGRzIGNhbm5vdCBiZSB1
cGRhdGVkIGFmdGVyIGNyZWF0aW9uLgoKDAoFBAAIAAESA0EIDQqPAgoEBAACAxIDRwQWGoEC
IFJlc291cmNlcyBsaWtlIGVudHJ5IGNhbiBoYXZlIHNjaGVtYXMgYXNzb2NpYXRlZCB3aXRo
IHRoZW0uIFRoaXMgc2NvcGUKIGFsbG93cyB5b3UgdG8gYXR0YWNoIHRhZ3MgdG8gYW4gaW5k
aXZpZHVhbCBjb2x1bW4gYmFzZWQgb24gdGhhdCBzY2hlbWEuCgogVG8gYXR0YWNoIGEgdGFn
IHRvIGEgbmVzdGVkIGNvbHVtbiwgc2VwYXJhdGUgY29sdW1uIG5hbWVzIHdpdGggYSBkb3QK
IChgLmApLiBFeGFtcGxlOiBgY29sdW1uLm5lc3RlZF9jb2x1bW5gLgoKDAoFBAACAwUSA0cE
CgoMCgUEAAIDARIDRwsRCgwKBQQAAgMDEgNHFBUK0QEKBAQAAgQSA08CTBrDASBSZXF1aXJl
ZC4gTWFwcyB0aGUgSUQgb2YgYSB0YWcgZmllbGQgdG8gaXRzIHZhbHVlIGFuZCBhZGRpdGlv
bmFsCiBpbmZvcm1hdGlvbiBhYm91dCB0aGF0IGZpZWxkLgoKIFRhZyB0ZW1wbGF0ZSBkZWZp
bmVzIHZhbGlkIGZpZWxkIElEcy4gQSB0YWcKIG11c3QgaGF2ZSBhdCBsZWFzdCAxIGZpZWxk
IGFuZCBhdCBtb3N0IDUwMCBmaWVsZHMuCgoMCgUEAAIEBhIDTwIXCgwKBQQAAgQBEgNPGB4K
DAoFBAACBAMSA08hIgoMCgUEAAIECBIDTyNLCg8KCAQAAgQInAgAEgNPJEoKTQoEBAACBRIE
UgJTMho/IE91dHB1dCBvbmx5LiBEZW5vdGVzIHRoZSB0cmFuc2ZlciBzdGF0dXMgb2YgdGhl
IFRhZyBUZW1wbGF0ZS4KCgwKBQQAAgUGEgNSAiQKDAoFBAACBQESA1IlPQoMCgUEAAIFAxID
UkBBCgwKBQQAAgUIEgNTBjEKDwoIBAACBQicCAASA1MHMAp5CgIEARIFWACHAQEabCBDb250
YWlucyB0aGUgdmFsdWUgYW5kIGFkZGl0aW9uYWwgaW5mb3JtYXRpb24gb24gYSBmaWVsZCB3
aXRoaW4KIGEgW1RhZ11bZ29vZ2xlLmNsb3VkLmRhdGFjYXRhbG9nLnYxLlRhZ10uCgoKCgME
AQESA1gIEAoeCgQEAQMAEgRaAl0DGhAgQW4gZW51bSB2YWx1ZS4KCgwKBQQBAwABEgNaChMK
NAoGBAEDAAIAEgNcBBwaJSBUaGUgZGlzcGxheSBuYW1lIG9mIHRoZSBlbnVtIHZhbHVlLgoK
DgoHBAEDAAIABRIDXAQKCg4KBwQBAwACAAESA1wLFwoOCgcEAQMAAgADEgNcGhsKOwoEBAEC
ABIDYAJGGi4gT3V0cHV0IG9ubHkuIFRoZSBkaXNwbGF5IG5hbWUgb2YgdGhpcyBmaWVsZC4K
CgwKBQQBAgAFEgNgAggKDAoFBAECAAESA2AJFQoMCgUEAQIAAxIDYBgZCgwKBQQBAgAIEgNg
GkUKDwoIBAECAAicCAASA2AbRAoyCgQEAQgAEgRjAn0DGiQgUmVxdWlyZWQuIFRoZSB2YWx1
ZSBvZiB0aGlzIGZpZWxkLgoKDAoFBAEIAAESA2MIDAo7CgQEAQIBEgNlBBwaLiBUaGUgdmFs
dWUgb2YgYSB0YWcgZmllbGQgd2l0aCBhIGRvdWJsZSB0eXBlLgoKDAoFBAECAQUSA2UECgoM
CgUEAQIBARIDZQsXCgwKBQQBAgEDEgNlGhsKagoEBAECAhIDagQcGl0gVGhlIHZhbHVlIG9m
IGEgdGFnIGZpZWxkIHdpdGggYSBzdHJpbmcgdHlwZS4KCiBUaGUgbWF4aW11bSBsZW5ndGgg
aXMgMjAwMCBVVEYtOCBjaGFyYWN0ZXJzLgoKDAoFBAECAgUSA2oECgoMCgUEAQICARIDagsX
CgwKBQQBAgIDEgNqGhsKPAoEBAECAxIDbQQYGi8gVGhlIHZhbHVlIG9mIGEgdGFnIGZpZWxk
IHdpdGggYSBib29sZWFuIHR5cGUuCgoMCgUEAQIDBRIDbQQICgwKBQQBAgMBEgNtCRMKDAoF
BAECAwMSA20WFwo+CgQEAQIEEgNwBDIaMSBUaGUgdmFsdWUgb2YgYSB0YWcgZmllbGQgd2l0
aCBhIHRpbWVzdGFtcCB0eXBlLgoKDAoFBAECBAYSA3AEHQoMCgUEAQIEARIDcB4tCgwKBQQB
AgQDEgNwMDEKfgoEBAECBRIDdQQdGnEgVGhlIHZhbHVlIG9mIGEgdGFnIGZpZWxkIHdpdGgg
YW4gZW51bSB0eXBlLgoKIFRoaXMgdmFsdWUgbXVzdCBiZSBvbmUgb2YgdGhlIGFsbG93ZWQg
dmFsdWVzIGxpc3RlZCBpbiB0aGlzIGVudW0uCgoMCgUEAQIFBhIDdQQNCgwKBQQBAgUBEgN1
DhgKDAoFBAECBQMSA3UbHAraAQoEBAECBhIDfAQeGswBIFRoZSB2YWx1ZSBvZiBhIHRhZyBm
aWVsZCB3aXRoIGEgcmljaCB0ZXh0IHR5cGUuCgogVGhlIG1heGltdW0gbGVuZ3RoIGlzIDEw
IE1pQiBhcyB0aGlzIHZhbHVlIGhvbGRzIEhUTUwgZGVzY3JpcHRpb25zCiBpbmNsdWRpbmcg
ZW5jb2RlZCBpbWFnZXMuIFRoZSBtYXhpbXVtIGxlbmd0aCBvZiB0aGUgdGV4dCB3aXRob3V0
IGltYWdlcwogaXMgMTAwIEtpQi4KCgwKBQQBAgYFEgN8BAoKDAoFBAECBgESA3wLGQoMCgUE
AQIGAxIDfBwdCu4CCgQEAQIHEgSGAQI+Gt8CIE91dHB1dCBvbmx5LiBUaGUgb3JkZXIgb2Yg
dGhpcyBmaWVsZCB3aXRoIHJlc3BlY3QgdG8gb3RoZXIgZmllbGRzIGluIHRoaXMKIHRhZy4g
Q2FuIGJlIHNldCBieQogW1RhZ11bZ29vZ2xlLmNsb3VkLmRhdGFjYXRhbG9nLnYxLlRhZ1Rl
bXBsYXRlRmllbGQub3JkZXJdLgoKIEZvciBleGFtcGxlLCBhIGhpZ2hlciB2YWx1ZSBjYW4g
aW5kaWNhdGUgYSBtb3JlIGltcG9ydGFudCBmaWVsZC4KIFRoZSB2YWx1ZSBjYW4gYmUgbmVn
YXRpdmUuIE11bHRpcGxlIGZpZWxkcyBjYW4gaGF2ZSB0aGUgc2FtZSBvcmRlciwgYW5kCiBm
aWVsZCBvcmRlcnMgd2l0aGluIGEgdGFnIGRvbid0IGhhdmUgdG8gYmUgc2VxdWVudGlhbC4K
Cg0KBQQBAgcFEgSGAQIHCg0KBQQBAgcBEgSGAQgNCg0KBQQBAgcDEgSGARARCg0KBQQBAgcI
EgSGARI9ChAKCAQBAgcInAgAEgSGARM8Cv4DCgIEAhIGkgEAzwEBGu8DIEEgdGFnIHRlbXBs
YXRlIGRlZmluZXMgYSB0YWcgdGhhdCBjYW4gaGF2ZSBvbmUgb3IgbW9yZSB0eXBlZCBmaWVs
ZHMuCgogVGhlIHRlbXBsYXRlIGlzIHVzZWQgdG8gY3JlYXRlIHRhZ3MgdGhhdCBhcmUgYXR0
YWNoZWQgdG8gR29vZ2xlIENsb3VkCiAgcmVzb3VyY2VzLiBbVGFnIHRlbXBsYXRlIHJvbGVz
XQogKGh0dHBzOi8vY2xvdWQuZ29vZ2xlLmNvbS9pYW0vZG9jcy91bmRlcnN0YW5kaW5nLXJv
bGVzI2RhdGEtY2F0YWxvZy1yb2xlcykKIHByb3ZpZGUgcGVybWlzc2lvbnMgdG8gY3JlYXRl
LCBlZGl0LCBhbmQgdXNlIHRoZSB0ZW1wbGF0ZS4gRm9yIGV4YW1wbGUsCiBzZWUgdGhlIFtU
YWdUZW1wbGF0ZSBVc2VyXQogKGh0dHBzOi8vY2xvdWQuZ29vZ2xlLmNvbS9kYXRhLWNhdGFs
b2cvZG9jcy9ob3ctdG8vdGVtcGxhdGUtdXNlcikgcm9sZQogdGhhdCBpbmNsdWRlcyBhIHBl
cm1pc3Npb24gdG8gdXNlIHRoZSB0YWcgdGVtcGxhdGUgdG8gdGFnIHJlc291cmNlcy4KCgsK
AwQCARIEkgEIEwoNCgMEAgcSBpMBApYBBAoPCgUEAgedCBIGkwEClgEEClYKBAQCBAASBpkB
AqcBAxpGIFRoaXMgZW51bSBkZXNjcmliZXMgVGFnVGVtcGxhdGUgdHJhbnNmZXIgc3RhdHVz
IHRvIERhdGFwbGV4IHNlcnZpY2UuCgoNCgUEAgQAARIEmQEHHQpoCgYEAgQAAgASBJwBBC0a
WCBEZWZhdWx0IHZhbHVlLiBUYWdUZW1wbGF0ZSBhbmQgaXRzIHRhZ3MgYXJlIG9ubHkgdmlz
aWJsZSBhbmQgZWRpdGFibGUgaW4KIERhdGFDYXRhbG9nLgoKDwoHBAIEAAIAARIEnAEEKAoP
CgcEAgQAAgACEgScASssCp8CCgYEAgQAAgESBKIBBCUajgIgVGFnVGVtcGxhdGUgYW5kIGl0
cyB0YWdzIGFyZSBhdXRvLWNvcGllZCB0byBEYXRhcGxleCBzZXJ2aWNlLgogVmlzaWJsZSBp
biBib3RoIHNlcnZpY2VzLiBFZGl0YWJsZSBpbiBEYXRhQ2F0YWxvZywgcmVhZC1vbmx5IGlu
IERhdGFwbGV4LgogRGVwcmVjYXRlZDogSW5kaXZpZHVhbCBUYWdUZW1wbGF0ZSBtaWdyYXRp
b24gaXMgZGVwcmVjYXRlZCBpbiBmYXZvciBvZgogb3JnYW5pemF0aW9uIG9yIHByb2plY3Qg
d2lkZSBUYWdUZW1wbGF0ZSBtaWdyYXRpb24gb3B0LWluLgoKDwoHBAIEAAIBARIEogEEDAoP
CgcEAgQAAgECEgSiAQ8QCg8KBwQCBAACAQMSBKIBESQKEAoIBAIEAAIBAwESBKIBEiMKmwEK
BgQCBAACAhIEpgEEFBqKASBUYWdUZW1wbGF0ZSBhbmQgaXRzIHRhZ3MgYXJlIGF1dG8tY29w
aWVkIHRvIERhdGFwbGV4IHNlcnZpY2UuCiBWaXNpYmxlIGluIGJvdGggc2VydmljZXMuIEVk
aXRhYmxlIGluIERhdGFwbGV4LCByZWFkLW9ubHkgaW4gRGF0YUNhdGFsb2cuCgoPCgcEAgQA
AgIBEgSmAQQPCg8KBwQCBAACAgISBKYBEhMKxQEKBAQCAgASBK0BAj0atgEgSWRlbnRpZmll
ci4gVGhlIHJlc291cmNlIG5hbWUgb2YgdGhlIHRhZyB0ZW1wbGF0ZSBpbiBVUkwgZm9ybWF0
LgoKIE5vdGU6IFRoZSB0YWcgdGVtcGxhdGUgaXRzZWxmIGFuZCBpdHMgY2hpbGQgcmVzb3Vy
Y2VzIG1pZ2h0IG5vdCBiZQogc3RvcmVkIGluIHRoZSBsb2NhdGlvbiBzcGVjaWZpZWQgaW4g
aXRzIG5hbWUuCgoNCgUEAgIABRIErQECCAoNCgUEAgIAARIErQEJDQoNCgUEAgIAAxIErQEQ
EQoNCgUEAgIACBIErQESPAoQCggEAgIACJwIABIErQETOwr/AQoEBAICARIEtAECGhrwASBE
aXNwbGF5IG5hbWUgZm9yIHRoaXMgdGVtcGxhdGUuIERlZmF1bHRzIHRvIGFuIGVtcHR5IHN0
cmluZy4KCiBUaGUgbmFtZSBtdXN0IGNvbnRhaW4gb25seSBVbmljb2RlIGxldHRlcnMsIG51
bWJlcnMgKDAtOSksIHVuZGVyc2NvcmVzIChfKSwKIGRhc2hlcyAoLSksIHNwYWNlcyAoICks
IGFuZCBjYW4ndCBzdGFydCBvciBlbmQgd2l0aCBzcGFjZXMuCiBUaGUgbWF4aW11bSBsZW5n
dGggaXMgMjAwIGNoYXJhY3RlcnMuCgoNCgUEAgIBBRIEtAECCAoNCgUEAgIBARIEtAEJFQoN
CgUEAgIBAxIEtAEYGQrXAgoEBAICAhIEvAECIBrIAiBJbmRpY2F0ZXMgd2hldGhlciB0YWdz
IGNyZWF0ZWQgd2l0aCB0aGlzIHRlbXBsYXRlIGFyZSBwdWJsaWMuIFB1YmxpYyB0YWdzCiBk
byBub3QgcmVxdWlyZSB0YWcgdGVtcGxhdGUgYWNjZXNzIHRvIGFwcGVhciBpbgogW0xpc3RU
YWdzXVtnb29nbGUuY2xvdWQuZGF0YWNhdGFsb2cudjEuRGF0YUNhdGFsb2cuTGlzdFRhZ3Nd
IEFQSSByZXNwb25zZS4KCiBBZGRpdGlvbmFsbHksIHlvdSBjYW4gc2VhcmNoIGZvciBhIHB1
YmxpYyB0YWcgYnkgdmFsdWUgd2l0aCBhCiBzaW1wbGUgc2VhcmNoIHF1ZXJ5IGluIGFkZGl0
aW9uIHRvIHVzaW5nIGEgYGB0YWc6YGAgcHJlZGljYXRlLgoKDQoFBAICAgUSBLwBAgYKDQoF
BAICAgESBLwBBxsKDQoFBAICAgMSBLwBHh8K7wMKBAQCAgMSBskBAsoBLxreAyBSZXF1aXJl
ZC4gTWFwIG9mIHRhZyB0ZW1wbGF0ZSBmaWVsZCBJRHMgdG8gdGhlIHNldHRpbmdzIGZvciB0
aGUgZmllbGQuCiBUaGlzIG1hcCBpcyBhbiBleGhhdXN0aXZlIGxpc3Qgb2YgdGhlIGFsbG93
ZWQgZmllbGRzLiBUaGUgbWFwIG11c3QgY29udGFpbgogYXQgbGVhc3Qgb25lIGZpZWxkIGFu
ZCBhdCBtb3N0IDUwMCBmaWVsZHMuCgogVGhlIGtleXMgdG8gdGhpcyBtYXAgYXJlIHRhZyB0
ZW1wbGF0ZSBmaWVsZCBJRHMuIFRoZSBJRHMgaGF2ZSB0aGUKIGZvbGxvd2luZyBsaW1pdGF0
aW9uczoKCiAqIENhbiBjb250YWluIHVwcGVyY2FzZSBhbmQgbG93ZXJjYXNlIGxldHRlcnMs
IG51bWJlcnMgKDAtOSkgYW5kCiAgIHVuZGVyc2NvcmVzIChfKS4KICogTXVzdCBiZSBhdCBs
ZWFzdCAxIGNoYXJhY3RlciBhbmQgYXQgbW9zdCA2NCBjaGFyYWN0ZXJzIGxvbmcuCiAqIE11
c3Qgc3RhcnQgd2l0aCBhIGxldHRlciBvciB1bmRlcnNjb3JlLgoKDQoFBAICAwYSBMkBAh8K
DQoFBAICAwESBMkBICYKDQoFBAICAwMSBMkBKSoKDQoFBAICAwgSBMoBBi4KEAoIBAICAwic
CAASBMoBBy0KPgoEBAICBBIGzQECzgEvGi4gT3B0aW9uYWwuIFRyYW5zZmVyIHN0YXR1cyBv
ZiB0aGUgVGFnVGVtcGxhdGUKCg0KBQQCAgQGEgTNAQIYCg0KBQQCAgQBEgTNARkxCg0KBQQC
AgQDEgTNATQ1Cg0KBQQCAgQIEgTOAQYuChAKCAQCAgQInAgAEgTOAQctCksKAgQDEgbSAQD8
AQEaPSBUaGUgdGVtcGxhdGUgZm9yIGFuIGluZGl2aWR1YWwgZmllbGQgd2l0aGluIGEgdGFn
IHRlbXBsYXRlLgoKCwoDBAMBEgTSAQgYCg0KAwQDBxIG0wEC1gEECg8KBQQDB50IEgbTAQLW
AQQKxAMKBAQDAgASBOMBAj0atQMgSWRlbnRpZmllci4gVGhlIHJlc291cmNlIG5hbWUgb2Yg
dGhlIHRhZyB0ZW1wbGF0ZSBmaWVsZCBpbiBVUkwgZm9ybWF0LgogRXhhbXBsZToKCiBgcHJv
amVjdHMve1BST0pFQ1RfSUR9L2xvY2F0aW9ucy97TE9DQVRJT059L3RhZ1RlbXBsYXRlcy97
VEFHX1RFTVBMQVRFfS9maWVsZHMve0ZJRUxEfWAKCiBOb3RlOiBUaGUgdGFnIHRlbXBsYXRl
IGZpZWxkIGl0c2VsZiBtaWdodCBub3QgYmUgc3RvcmVkIGluIHRoZSBsb2NhdGlvbgogc3Bl
Y2lmaWVkIGluIGl0cyBuYW1lLgoKIFRoZSBuYW1lIG11c3QgY29udGFpbiBvbmx5IGxldHRl
cnMgKGEteiwgQS1aKSwgbnVtYmVycyAoMC05KSwKIG9yIHVuZGVyc2NvcmVzIChfKSwgYW5k
IG11c3Qgc3RhcnQgd2l0aCBhIGxldHRlciBvciB1bmRlcnNjb3JlLgogVGhlIG1heGltdW0g
bGVuZ3RoIGlzIDY0IGNoYXJhY3RlcnMuCgoNCgUEAwIABRIE4wECCAoNCgUEAwIAARIE4wEJ
DQoNCgUEAwIAAxIE4wEQEQoNCgUEAwIACBIE4wESPAoQCggEAwIACJwIABIE4wETOwqAAgoE
BAMCARIE6gECGhrxASBUaGUgZGlzcGxheSBuYW1lIGZvciB0aGlzIGZpZWxkLiBEZWZhdWx0
cyB0byBhbiBlbXB0eSBzdHJpbmcuCgogVGhlIG5hbWUgbXVzdCBjb250YWluIG9ubHkgVW5p
Y29kZSBsZXR0ZXJzLCBudW1iZXJzICgwLTkpLCB1bmRlcnNjb3JlcyAoXyksCiBkYXNoZXMg
KC0pLCBzcGFjZXMgKCApLCBhbmQgY2FuJ3Qgc3RhcnQgb3IgZW5kIHdpdGggc3BhY2VzLgog
VGhlIG1heGltdW0gbGVuZ3RoIGlzIDIwMCBjaGFyYWN0ZXJzLgoKDQoFBAMCAQUSBOoBAggK
DQoFBAMCAQESBOoBCRUKDQoFBAMCAQMSBOoBGBkKRwoEBAMCAhIE7QECPho5IFJlcXVpcmVk
LiBUaGUgdHlwZSBvZiB2YWx1ZSB0aGlzIHRhZyBmaWVsZCBjYW4gY29udGFpbi4KCg0KBQQD
AgIGEgTtAQILCg0KBQQDAgIBEgTtAQwQCg0KBQQDAgIDEgTtARMUCg0KBQQDAgIIEgTtARU9
ChAKCAQDAgIInAgAEgTtARY8CkMKBAQDAgMSBPABAhcaNSBJZiB0cnVlLCB0aGlzIGZpZWxk
IGlzIHJlcXVpcmVkLiBEZWZhdWx0cyB0byBmYWxzZS4KCg0KBQQDAgMFEgTwAQIGCg0KBQQD
AgMBEgTwAQcSCg0KBQQDAgMDEgTwARUWCkwKBAQDAgQSBPMBAhkaPiBUaGUgZGVzY3JpcHRp
b24gZm9yIHRoaXMgZmllbGQuIERlZmF1bHRzIHRvIGFuIGVtcHR5IHN0cmluZy4KCg0KBQQD
AgQFEgTzAQIICg0KBQQDAgQBEgTzAQkUCg0KBQQDAgQDEgTzARcYCp8CCgQEAwIFEgT7AQIS
GpACIFRoZSBvcmRlciBvZiB0aGlzIGZpZWxkIHdpdGggcmVzcGVjdCB0byBvdGhlciBmaWVs
ZHMgaW4gdGhpcyB0YWcKIHRlbXBsYXRlLgoKIEZvciBleGFtcGxlLCBhIGhpZ2hlciB2YWx1
ZSBjYW4gaW5kaWNhdGUgYSBtb3JlIGltcG9ydGFudCBmaWVsZC4KIFRoZSB2YWx1ZSBjYW4g
YmUgbmVnYXRpdmUuIE11bHRpcGxlIGZpZWxkcyBjYW4gaGF2ZSB0aGUgc2FtZSBvcmRlciBh
bmQKIGZpZWxkIG9yZGVycyB3aXRoaW4gYSB0YWcgZG9uJ3QgaGF2ZSB0byBiZSBzZXF1ZW50
aWFsLgoKDQoFBAMCBQUSBPsBAgcKDQoFBAMCBQESBPsBCA0KDQoFBAMCBQMSBPsBEBEKDAoC
BAQSBv4BALICAQoLCgMEBAESBP4BCBEKDgoEBAQEABIG/wECkQIDCg0KBQQEBAABEgT/AQcU
CjcKBgQEBAACABIEgQIEIxonIFRoZSBkZWZhdWx0IGludmFsaWQgdmFsdWUgZm9yIGEgdHlw
ZS4KCg8KBwQEBAACAAESBIECBB4KDwoHBAQEAAIAAhIEgQIhIgosCgYEBAQAAgESBIQCBA8a
HCBBIGRvdWJsZSBwcmVjaXNpb24gbnVtYmVyLgoKDwoHBAQEAAIBARIEhAIECgoPCgcEBAQA
AgECEgSEAg0OCiIKBgQEBAACAhIEhwIEDxoSIEFuIFVURi04IHN0cmluZy4KCg8KBwQEBAAC
AgESBIcCBAoKDwoHBAQEAAICAhIEhwINDgoiCgYEBAQAAgMSBIoCBA0aEiBBIGJvb2xlYW4g
dmFsdWUuCgoPCgcEBAQAAgMBEgSKAgQICg8KBwQEBAACAwISBIoCCwwKHgoGBAQEAAIEEgSN
AgQSGg4gQSB0aW1lc3RhbXAuCgoPCgcEBAQAAgQBEgSNAgQNCg8KBwQEBAACBAISBI0CEBEK
KQoGBAQEAAIFEgSQAgQRGhkgQSBSaWNodGV4dCBkZXNjcmlwdGlvbi4KCg8KBwQEBAACBQES
BJACBAwKDwoHBAQEAAIFAhIEkAIPEAoOCgQEBAMAEgaTAgKoAgMKDQoFBAQDAAESBJMCChIK
EAoGBAQDAAMAEgaUAgScAgUKDwoHBAQDAAMAARIElAIMFQqSAgoIBAQDAAMAAgASBJsCBkca
/wEgUmVxdWlyZWQuIFRoZSBkaXNwbGF5IG5hbWUgb2YgdGhlIGVudW0gdmFsdWUuIE11c3Qg
bm90IGJlIGFuIGVtcHR5CiBzdHJpbmcuCgogVGhlIG5hbWUgbXVzdCBjb250YWluIG9ubHkg
VW5pY29kZSBsZXR0ZXJzLCBudW1iZXJzICgwLTkpLCB1bmRlcnNjb3JlcwogKF8pLCBkYXNo
ZXMgKC0pLCBzcGFjZXMgKCApLCBhbmQgY2FuJ3Qgc3RhcnQgb3IgZW5kIHdpdGggc3BhY2Vz
LiBUaGUKIG1heGltdW0gbGVuZ3RoIGlzIDIwMCBjaGFyYWN0ZXJzLgoKEQoJBAQDAAMAAgAF
EgSbAgYMChEKCQQEAwADAAIAARIEmwINGQoRCgkEBAMAAwACAAMSBJsCHB0KEQoJBAQDAAMA
AgAIEgSbAh5GChQKDAQEAwADAAIACJwIABIEmwIfRQq2AwoGBAQDAAIAEgSnAgQqGqUDIFRo
ZSBzZXQgb2YgYWxsb3dlZCB2YWx1ZXMgZm9yIHRoaXMgZW51bS4KCiBUaGlzIHNldCBtdXN0
IG5vdCBiZSBlbXB0eSBhbmQgY2FuIGluY2x1ZGUgdXAgdG8gMTAwIGFsbG93ZWQgdmFsdWVz
LgogVGhlIGRpc3BsYXkgbmFtZXMgb2YgdGhlIHZhbHVlcyBpbiB0aGlzIHNldCBtdXN0IG5v
dCBiZSBlbXB0eSBhbmQgbXVzdAogYmUgY2FzZS1pbnNlbnNpdGl2ZWx5IHVuaXF1ZSB3aXRo
aW4gdGhpcyBzZXQuCgogVGhlIG9yZGVyIG9mIGl0ZW1zIGluIHRoaXMgc2V0IGlzIHByZXNl
cnZlZC4gVGhpcyBmaWVsZCBjYW4gYmUgdXNlZCB0bwogY3JlYXRlLCByZW1vdmUsIGFuZCBy
ZW9yZGVyIGVudW0gdmFsdWVzLiBUbyByZW5hbWUgZW51bSB2YWx1ZXMsIHVzZSB0aGUKIGBS
ZW5hbWVUYWdUZW1wbGF0ZUZpZWxkRW51bVZhbHVlYCBtZXRob2QuCgoPCgcEBAMAAgAEEgSn
AgQMCg8KBwQEAwACAAYSBKcCDRYKDwoHBAQDAAIAARIEpwIXJQoPCgcEBAMAAgADEgSnAigp
ChsKBAQECAASBqsCArECAxoLIFJlcXVpcmVkLgoKDQoFBAQIAAESBKsCCBEKPgoEBAQCABIE
rQIEJRowIFByaW1pdGl2ZSB0eXBlcywgc3VjaCBhcyBzdHJpbmcsIGJvb2xlYW4sIGV0Yy4K
Cg0KBQQEAgAGEgStAgQRCg0KBQQEAgABEgStAhIgCg0KBQQEAgADEgStAiMkCh0KBAQEAgES
BLACBBsaDyBBbiBlbnVtIHR5cGUuCgoNCgUEBAIBBhIEsAIEDAoNCgUEBAIBARIEsAINFgoN
CgUEBAIBAxIEsAIZGmIGcHJvdG8z
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Datacatalog::V1::Tags::Tag ===
    # Fields for Tag
    # Field: name Type: 9 ()
    # Field: template Type: 9 ()
    # Field: template_display_name Type: 9 ()
    # Field: column Type: 9 ()
    # Field: fields Type: 11 (.google.cloud.datacatalog.v1.Tag.FieldsEntry)
    # Field: dataplex_transfer_status Type: 14 (.google.cloud.datacatalog.v1.TagTemplate.DataplexTransferStatus)

# === Message: Google::Cloud::Datacatalog::V1::Tags::TagField ===
    # Fields for TagField
    # Field: display_name Type: 9 ()
    # Field: double_value Type: 1 ()
    # Field: string_value Type: 9 ()
    # Field: bool_value Type: 8 ()
    # Field: timestamp_value Type: 11 (.google.protobuf.Timestamp)
    # Field: enum_value Type: 11 (.google.cloud.datacatalog.v1.TagField.EnumValue)
    # Field: richtext_value Type: 9 ()
    # Field: order Type: 5 ()

# === Message: Google::Cloud::Datacatalog::V1::Tags::TagTemplate ===
    # Fields for TagTemplate
    # Field: name Type: 9 ()
    # Field: display_name Type: 9 ()
    # Field: is_publicly_readable Type: 8 ()
    # Field: fields Type: 11 (.google.cloud.datacatalog.v1.TagTemplate.FieldsEntry)
    # Field: dataplex_transfer_status Type: 14 (.google.cloud.datacatalog.v1.TagTemplate.DataplexTransferStatus)

# Enum: TagTemplate::DataplexTransferStatus
our $TagTemplate_DATAPLEX_TRANSFER_STATUS_UNSPECIFIED = 0;
our $TagTemplate_MIGRATED = 1;
our $TagTemplate_TRANSFERRED = 2;

# === Message: Google::Cloud::Datacatalog::V1::Tags::TagTemplateField ===
    # Fields for TagTemplateField
    # Field: name Type: 9 ()
    # Field: display_name Type: 9 ()
    # Field: type Type: 11 (.google.cloud.datacatalog.v1.FieldType)
    # Field: is_required Type: 8 ()
    # Field: description Type: 9 ()
    # Field: order Type: 5 ()

# === Message: Google::Cloud::Datacatalog::V1::Tags::FieldType ===
    # Fields for FieldType
    # Field: primitive_type Type: 14 (.google.cloud.datacatalog.v1.FieldType.PrimitiveType)
    # Field: enum_type Type: 11 (.google.cloud.datacatalog.v1.FieldType.EnumType)

# Enum: FieldType::PrimitiveType
our $FieldType_PRIMITIVE_TYPE_UNSPECIFIED = 0;
our $FieldType_DOUBLE = 1;
our $FieldType_STRING = 2;
our $FieldType_BOOL = 3;
our $FieldType_TIMESTAMP = 4;
our $FieldType_RICHTEXT = 5;

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Datacatalog::V1::Tags - Compiled Protocol Buffers messages for google/cloud/datacatalog/v1/tags.proto

=head1 SYNOPSIS

    use Google::Cloud::Datacatalog::V1::Tags;

    my $msg = Google::Cloud::Datacatalog::V1::Tags::Tag->new({
        name => $name,
        template => $template,
        template_display_name => $template_display_name,
        column => $column,
    });

    # Read or update a field
    my $val = $msg->name();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Datacatalog::V1::Tags::Tag->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/datacatalog/v1/tags.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Datacatalog::V1::Tags::Tag

Tags contain custom metadata and are attached to Data Catalog resources. Tags
conform with the specification of their tag template.

See [Data Catalog
IAM](https://cloud.google.com/data-catalog/docs/concepts/iam) for information
on the permissions needed to create or view tags.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Identifier. The resource name of the tag in URL format where tag ID is a
system-generated identifier.

Note: The tag itself might not be stored in the location specified in its
name.

=item * C<< $msg->template() >> / C<< $msg->template($value) >>

Type: C<String>

Required. The resource name of the tag template this tag uses. Example:

`projects/{PROJECT_ID}/locations/{LOCATION}/tagTemplates/{TAG_TEMPLATE_ID}`

This field cannot be modified after creation.

=item * C<< $msg->template_display_name() >> / C<< $msg->template_display_name($value) >>

Type: C<String>

Output only. The display name of the tag template.

=item * C<< $msg->column() >> / C<< $msg->column($value) >>

Type: C<String>

Resources like entry can have schemas associated with them. This scope
allows you to attach tags to an individual column based on that schema.

To attach a tag to a nested column, separate column names with a dot
(`.`). Example: `column.nested_column`.

=item * C<< $msg->fields() >> / C<< $msg->fields($value) >>

Type: C<Message> (L<Google::Cloud::Datacatalog::V1::Tags::Tag::FieldsEntry>)

Required. Maps the ID of a tag field to its value and additional
information about that field.

Tag template defines valid field IDs. A tag
must have at least 1 field and at most 500 fields.

=item * C<< $msg->dataplex_transfer_status() >> / C<< $msg->dataplex_transfer_status($value) >>

Type: C<Enum> (L<Google::Cloud::Datacatalog::V1::TagTemplate::DataplexTransferStatus>)

Output only. Denotes the transfer status of the Tag Template.

=back

=head2 Google::Cloud::Datacatalog::V1::Tags::TagField

Contains the value and additional information on a field within
a [Tag][google.cloud.datacatalog.v1.Tag].

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->display_name() >> / C<< $msg->display_name($value) >>

Type: C<String>

Output only. The display name of this field.

=item * C<< $msg->double_value() >> / C<< $msg->double_value($value) >>

Type: C<Double>

The value of a tag field with a double type.

=item * C<< $msg->string_value() >> / C<< $msg->string_value($value) >>

Type: C<String>

The value of a tag field with a string type.

The maximum length is 2000 UTF-8 characters.

=item * C<< $msg->bool_value() >> / C<< $msg->bool_value($value) >>

Type: C<Bool>

The value of a tag field with a boolean type.

=item * C<< $msg->timestamp_value() >> / C<< $msg->timestamp_value($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

The value of a tag field with a timestamp type.

=item * C<< $msg->enum_value() >> / C<< $msg->enum_value($value) >>

Type: C<Message> (L<Google::Cloud::Datacatalog::V1::Tags::TagField::EnumValue>)

The value of a tag field with an enum type.

This value must be one of the allowed values listed in this enum.

=item * C<< $msg->richtext_value() >> / C<< $msg->richtext_value($value) >>

Type: C<String>

The value of a tag field with a rich text type.

The maximum length is 10 MiB as this value holds HTML descriptions
including encoded images. The maximum length of the text without images
is 100 KiB.

=item * C<< $msg->order() >> / C<< $msg->order($value) >>

Type: C<Int32>

Output only. The order of this field with respect to other fields in this
tag. Can be set by
[Tag][google.cloud.datacatalog.v1.TagTemplateField.order].

For example, a higher value can indicate a more important field.
The value can be negative. Multiple fields can have the same order, and
field orders within a tag don't have to be sequential.

=back

=head2 Google::Cloud::Datacatalog::V1::Tags::TagTemplate

A tag template defines a tag that can have one or more typed fields.

The template is used to create tags that are attached to Google Cloud
 resources. [Tag template roles]
(https://cloud.google.com/iam/docs/understanding-roles#data-catalog-roles)
provide permissions to create, edit, and use the template. For example,
see the [TagTemplate User]
(https://cloud.google.com/data-catalog/docs/how-to/template-user) role
that includes a permission to use the tag template to tag resources.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Identifier. The resource name of the tag template in URL format.

Note: The tag template itself and its child resources might not be
stored in the location specified in its name.

=item * C<< $msg->display_name() >> / C<< $msg->display_name($value) >>

Type: C<String>

Display name for this template. Defaults to an empty string.

The name must contain only Unicode letters, numbers (0-9), underscores (_),
dashes (-), spaces ( ), and can't start or end with spaces.
The maximum length is 200 characters.

=item * C<< $msg->is_publicly_readable() >> / C<< $msg->is_publicly_readable($value) >>

Type: C<Bool>

Indicates whether tags created with this template are public. Public tags
do not require tag template access to appear in
[ListTags][google.cloud.datacatalog.v1.DataCatalog.ListTags] API response.

Additionally, you can search for a public tag by value with a
simple search query in addition to using a ``tag:`` predicate.

=item * C<< $msg->fields() >> / C<< $msg->fields($value) >>

Type: C<Message> (L<Google::Cloud::Datacatalog::V1::Tags::TagTemplate::FieldsEntry>)

Required. Map of tag template field IDs to the settings for the field.
This map is an exhaustive list of the allowed fields. The map must contain
at least one field and at most 500 fields.

The keys to this map are tag template field IDs. The IDs have the
following limitations:

* Can contain uppercase and lowercase letters, numbers (0-9) and
  underscores (_).
* Must be at least 1 character and at most 64 characters long.
* Must start with a letter or underscore.

=item * C<< $msg->dataplex_transfer_status() >> / C<< $msg->dataplex_transfer_status($value) >>

Type: C<Enum> (L<Google::Cloud::Datacatalog::V1::TagTemplate::DataplexTransferStatus>)

Optional. Transfer status of the TagTemplate

=back

=head3 Enum: TagTemplate::DataplexTransferStatus

=over 4

=item * C<DATAPLEX_TRANSFER_STATUS_UNSPECIFIED> => C<0>

=item * C<MIGRATED> => C<1>

=item * C<TRANSFERRED> => C<2>

=back

=head2 Google::Cloud::Datacatalog::V1::Tags::TagTemplateField

The template for an individual field within a tag template.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Identifier. The resource name of the tag template field in URL format.
Example:

`projects/{PROJECT_ID}/locations/{LOCATION}/tagTemplates/{TAG_TEMPLATE}/fields/{FIELD}`

Note: The tag template field itself might not be stored in the location
specified in its name.

The name must contain only letters (a-z, A-Z), numbers (0-9),
or underscores (_), and must start with a letter or underscore.
The maximum length is 64 characters.

=item * C<< $msg->display_name() >> / C<< $msg->display_name($value) >>

Type: C<String>

The display name for this field. Defaults to an empty string.

The name must contain only Unicode letters, numbers (0-9), underscores (_),
dashes (-), spaces ( ), and can't start or end with spaces.
The maximum length is 200 characters.

=item * C<< $msg->type() >> / C<< $msg->type($value) >>

Type: C<Message> (L<Google::Cloud::Datacatalog::V1::Tags::FieldType>)

Required. The type of value this tag field can contain.

=item * C<< $msg->is_required() >> / C<< $msg->is_required($value) >>

Type: C<Bool>

If true, this field is required. Defaults to false.

=item * C<< $msg->description() >> / C<< $msg->description($value) >>

Type: C<String>

The description for this field. Defaults to an empty string.

=item * C<< $msg->order() >> / C<< $msg->order($value) >>

Type: C<Int32>

The order of this field with respect to other fields in this tag
template.

For example, a higher value can indicate a more important field.
The value can be negative. Multiple fields can have the same order and
field orders within a tag don't have to be sequential.

=back

=head2 Google::Cloud::Datacatalog::V1::Tags::FieldType

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->primitive_type() >> / C<< $msg->primitive_type($value) >>

Type: C<Enum> (L<Google::Cloud::Datacatalog::V1::FieldType::PrimitiveType>)

Primitive types, such as string, boolean, etc.

=item * C<< $msg->enum_type() >> / C<< $msg->enum_type($value) >>

Type: C<Message> (L<Google::Cloud::Datacatalog::V1::Tags::FieldType::EnumType>)

An enum type.

=back

=head3 Enum: FieldType::PrimitiveType

=over 4

=item * C<PRIMITIVE_TYPE_UNSPECIFIED> => C<0>

=item * C<DOUBLE> => C<1>

=item * C<STRING> => C<2>

=item * C<BOOL> => C<3>

=item * C<TIMESTAMP> => C<4>

=item * C<RICHTEXT> => C<5>

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Datacatalog::V1::Tags::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
