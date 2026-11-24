package Google::Ai::Generativelanguage::V1alpha::Retriever;

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
CjRnb29nbGUvYWkvZ2VuZXJhdGl2ZWxhbmd1YWdlL3YxYWxwaGEvcmV0cmlldmVyLnByb3Rv
EiRnb29nbGUuYWkuZ2VuZXJhdGl2ZWxhbmd1YWdlLnYxYWxwaGEaH2dvb2dsZS9hcGkvZmll
bGRfYmVoYXZpb3IucHJvdG8aGWdvb2dsZS9hcGkvcmVzb3VyY2UucHJvdG8aH2dvb2dsZS9w
cm90b2J1Zi90aW1lc3RhbXAucHJvdG8iogIKBkNvcnB1cxIaCgRuYW1lGAEgASgJQgbgQQjg
QQVSBG5hbWUSJgoMZGlzcGxheV9uYW1lGAIgASgJQgPgQQFSC2Rpc3BsYXlOYW1lEkAKC2Ny
ZWF0ZV90aW1lGAMgASgLMhouZ29vZ2xlLnByb3RvYnVmLlRpbWVzdGFtcEID4EEDUgpjcmVh
dGVUaW1lEkAKC3VwZGF0ZV90aW1lGAQgASgLMhouZ29vZ2xlLnByb3RvYnVmLlRpbWVzdGFt
cEID4EEDUgp1cGRhdGVUaW1lOlDqQU0KKGdlbmVyYXRpdmVsYW5ndWFnZS5nb29nbGVhcGlz
LmNvbS9Db3JwdXMSEGNvcnBvcmEve2NvcnB1c30qB2NvcnBvcmEyBmNvcnB1cyKjAwoIRG9j
dW1lbnQSGgoEbmFtZRgBIAEoCUIG4EEI4EEFUgRuYW1lEiYKDGRpc3BsYXlfbmFtZRgCIAEo
CUID4EEBUgtkaXNwbGF5TmFtZRJiCg9jdXN0b21fbWV0YWRhdGEYAyADKAsyNC5nb29nbGUu
YWkuZ2VuZXJhdGl2ZWxhbmd1YWdlLnYxYWxwaGEuQ3VzdG9tTWV0YWRhdGFCA+BBAVIOY3Vz
dG9tTWV0YWRhdGESQAoLdXBkYXRlX3RpbWUYBCABKAsyGi5nb29nbGUucHJvdG9idWYuVGlt
ZXN0YW1wQgPgQQNSCnVwZGF0ZVRpbWUSQAoLY3JlYXRlX3RpbWUYBSABKAsyGi5nb29nbGUu
cHJvdG9idWYuVGltZXN0YW1wQgPgQQNSCmNyZWF0ZVRpbWU6a+pBaAoqZ2VuZXJhdGl2ZWxh
bmd1YWdlLmdvb2dsZWFwaXMuY29tL0RvY3VtZW50EiVjb3Jwb3JhL3tjb3JwdXN9L2RvY3Vt
ZW50cy97ZG9jdW1lbnR9Kglkb2N1bWVudHMyCGRvY3VtZW50IiQKClN0cmluZ0xpc3QSFgoG
dmFsdWVzGAEgAygJUgZ2YWx1ZXMi3AEKDkN1c3RvbU1ldGFkYXRhEiMKDHN0cmluZ192YWx1
ZRgCIAEoCUgAUgtzdHJpbmdWYWx1ZRJeChFzdHJpbmdfbGlzdF92YWx1ZRgGIAEoCzIwLmdv
b2dsZS5haS5nZW5lcmF0aXZlbGFuZ3VhZ2UudjFhbHBoYS5TdHJpbmdMaXN0SABSD3N0cmlu
Z0xpc3RWYWx1ZRIlCg1udW1lcmljX3ZhbHVlGAcgASgCSABSDG51bWVyaWNWYWx1ZRIVCgNr
ZXkYASABKAlCA+BBAlIDa2V5QgcKBXZhbHVlIn0KDk1ldGFkYXRhRmlsdGVyEhUKA2tleRgB
IAEoCUID4EECUgNrZXkSVAoKY29uZGl0aW9ucxgCIAMoCzIvLmdvb2dsZS5haS5nZW5lcmF0
aXZlbGFuZ3VhZ2UudjFhbHBoYS5Db25kaXRpb25CA+BBAlIKY29uZGl0aW9ucyLUAgoJQ29u
ZGl0aW9uEiMKDHN0cmluZ192YWx1ZRgBIAEoCUgAUgtzdHJpbmdWYWx1ZRIlCg1udW1lcmlj
X3ZhbHVlGAYgASgCSABSDG51bWVyaWNWYWx1ZRJbCglvcGVyYXRpb24YBSABKA4yOC5nb29n
bGUuYWkuZ2VuZXJhdGl2ZWxhbmd1YWdlLnYxYWxwaGEuQ29uZGl0aW9uLk9wZXJhdG9yQgPg
QQJSCW9wZXJhdGlvbiKUAQoIT3BlcmF0b3ISGAoUT1BFUkFUT1JfVU5TUEVDSUZJRUQQABII
CgRMRVNTEAESDgoKTEVTU19FUVVBTBACEgkKBUVRVUFMEAMSEQoNR1JFQVRFUl9FUVVBTBAE
EgsKB0dSRUFURVIQBRINCglOT1RfRVFVQUwQBhIMCghJTkNMVURFUxAHEgwKCEVYQ0xVREVT
EAhCBwoFdmFsdWUi+AQKBUNodW5rEhoKBG5hbWUYASABKAlCBuBBCOBBBVIEbmFtZRJICgRk
YXRhGAIgASgLMi8uZ29vZ2xlLmFpLmdlbmVyYXRpdmVsYW5ndWFnZS52MWFscGhhLkNodW5r
RGF0YUID4EECUgRkYXRhEmIKD2N1c3RvbV9tZXRhZGF0YRgDIAMoCzI0Lmdvb2dsZS5haS5n
ZW5lcmF0aXZlbGFuZ3VhZ2UudjFhbHBoYS5DdXN0b21NZXRhZGF0YUID4EEBUg5jdXN0b21N
ZXRhZGF0YRJACgtjcmVhdGVfdGltZRgEIAEoCzIaLmdvb2dsZS5wcm90b2J1Zi5UaW1lc3Rh
bXBCA+BBA1IKY3JlYXRlVGltZRJACgt1cGRhdGVfdGltZRgFIAEoCzIaLmdvb2dsZS5wcm90
b2J1Zi5UaW1lc3RhbXBCA+BBA1IKdXBkYXRlVGltZRJMCgVzdGF0ZRgGIAEoDjIxLmdvb2ds
ZS5haS5nZW5lcmF0aXZlbGFuZ3VhZ2UudjFhbHBoYS5DaHVuay5TdGF0ZUID4EEDUgVzdGF0
ZSJgCgVTdGF0ZRIVChFTVEFURV9VTlNQRUNJRklFRBAAEhwKGFNUQVRFX1BFTkRJTkdfUFJP
Q0VTU0lORxABEhAKDFNUQVRFX0FDVElWRRACEhAKDFNUQVRFX0ZBSUxFRBAKOnHqQW4KJ2dl
bmVyYXRpdmVsYW5ndWFnZS5nb29nbGVhcGlzLmNvbS9DaHVuaxI0Y29ycG9yYS97Y29ycHVz
fS9kb2N1bWVudHMve2RvY3VtZW50fS9jaHVua3Mve2NodW5rfSoGY2h1bmtzMgVjaHVuayI4
CglDaHVua0RhdGESIwoMc3RyaW5nX3ZhbHVlGAEgASgJSABSC3N0cmluZ1ZhbHVlQgYKBGRh
dGFCnAEKKGNvbS5nb29nbGUuYWkuZ2VuZXJhdGl2ZWxhbmd1YWdlLnYxYWxwaGFCDlJldHJp
ZXZlclByb3RvUAFaXmNsb3VkLmdvb2dsZS5jb20vZ28vYWkvZ2VuZXJhdGl2ZWxhbmd1YWdl
L2FwaXYxYWxwaGEvZ2VuZXJhdGl2ZWxhbmd1YWdlcGI7Z2VuZXJhdGl2ZWxhbmd1YWdlcGJK
80cKBxIFDgCDAgEKvAQKAQwSAw4AEjKxBCBDb3B5cmlnaHQgMjAyNSBHb29nbGUgTExDCgog
TGljZW5zZWQgdW5kZXIgdGhlIEFwYWNoZSBMaWNlbnNlLCBWZXJzaW9uIDIuMCAodGhlICJM
aWNlbnNlIik7CiB5b3UgbWF5IG5vdCB1c2UgdGhpcyBmaWxlIGV4Y2VwdCBpbiBjb21wbGlh
bmNlIHdpdGggdGhlIExpY2Vuc2UuCiBZb3UgbWF5IG9idGFpbiBhIGNvcHkgb2YgdGhlIExp
Y2Vuc2UgYXQKCiAgICAgaHR0cDovL3d3dy5hcGFjaGUub3JnL2xpY2Vuc2VzL0xJQ0VOU0Ut
Mi4wCgogVW5sZXNzIHJlcXVpcmVkIGJ5IGFwcGxpY2FibGUgbGF3IG9yIGFncmVlZCB0byBp
biB3cml0aW5nLCBzb2Z0d2FyZQogZGlzdHJpYnV0ZWQgdW5kZXIgdGhlIExpY2Vuc2UgaXMg
ZGlzdHJpYnV0ZWQgb24gYW4gIkFTIElTIiBCQVNJUywKIFdJVEhPVVQgV0FSUkFOVElFUyBP
UiBDT05ESVRJT05TIE9GIEFOWSBLSU5ELCBlaXRoZXIgZXhwcmVzcyBvciBpbXBsaWVkLgog
U2VlIHRoZSBMaWNlbnNlIGZvciB0aGUgc3BlY2lmaWMgbGFuZ3VhZ2UgZ292ZXJuaW5nIHBl
cm1pc3Npb25zIGFuZAogbGltaXRhdGlvbnMgdW5kZXIgdGhlIExpY2Vuc2UuCgoICgECEgMQ
AC0KCQoCAwASAxIAKQoJCgIDARIDEwAjCgkKAgMCEgMUACkKCAoBCBIDFgB1CgkKAggLEgMW
AHUKCAoBCBIDFwAiCgkKAggKEgMXACIKCAoBCBIDGAAvCgkKAggIEgMYAC8KCAoBCBIDGQBB
CgkKAggBEgMZAEEKXwoCBAASBB0APQEaUyBBIGBDb3JwdXNgIGlzIGEgY29sbGVjdGlvbiBv
ZiBgRG9jdW1lbnRgcy4KIEEgcHJvamVjdCBjYW4gY3JlYXRlIHVwIHRvIDUgY29ycG9yYS4K
CgoKAwQAARIDHQgOCgsKAwQABxIEHgIjBAoNCgUEAAedCBIEHgIjBAqcAwoEBAACABIELAIv
BBqNAyBJbW11dGFibGUuIElkZW50aWZpZXIuIFRoZSBgQ29ycHVzYCByZXNvdXJjZSBuYW1l
LiBUaGUgSUQgKG5hbWUgZXhjbHVkaW5nCiB0aGUgImNvcnBvcmEvIiBwcmVmaXgpIGNhbiBj
b250YWluIHVwIHRvIDQwIGNoYXJhY3RlcnMgdGhhdCBhcmUgbG93ZXJjYXNlCiBhbHBoYW51
bWVyaWMgb3IgZGFzaGVzCiAoLSkuIFRoZSBJRCBjYW5ub3Qgc3RhcnQgb3IgZW5kIHdpdGgg
YSBkYXNoLiBJZiB0aGUgbmFtZSBpcyBlbXB0eSBvbgogY3JlYXRlLCBhIHVuaXF1ZSBuYW1l
IHdpbGwgYmUgZGVyaXZlZCBmcm9tIGBkaXNwbGF5X25hbWVgIGFsb25nIHdpdGggYSAxMgog
Y2hhcmFjdGVyIHJhbmRvbSBzdWZmaXguCiBFeGFtcGxlOiBgY29ycG9yYS9teS1hd2Vzb21l
LWNvcnBvcmEtMTIzYTQ1NmI3ODljYAoKDAoFBAACAAUSAywCCAoMCgUEAAIAARIDLAkNCgwK
BQQAAgADEgMsEBEKDQoFBAACAAgSBCwSLwMKDwoIBAACAAicCAASAy0ELAoPCggEAAIACJwI
ARIDLgQrCsUBCgQEAAIBEgM0AkMatwEgT3B0aW9uYWwuIFRoZSBodW1hbi1yZWFkYWJsZSBk
aXNwbGF5IG5hbWUgZm9yIHRoZSBgQ29ycHVzYC4gVGhlIGRpc3BsYXkKIG5hbWUgbXVzdCBi
ZSBubyBtb3JlIHRoYW4gNTEyIGNoYXJhY3RlcnMgaW4gbGVuZ3RoLCBpbmNsdWRpbmcgc3Bh
Y2VzLgogRXhhbXBsZTogIkRvY3Mgb24gU2VtYW50aWMgUmV0cmlldmVyIgoKDAoFBAACAQUS
AzQCCAoMCgUEAAIBARIDNAkVCgwKBQQAAgEDEgM0GBkKDAoFBAACAQgSAzQaQgoPCggEAAIB
CJwIABIDNBtBCkwKBAQAAgISBDcCODIaPiBPdXRwdXQgb25seS4gVGhlIFRpbWVzdGFtcCBv
ZiB3aGVuIHRoZSBgQ29ycHVzYCB3YXMgY3JlYXRlZC4KCgwKBQQAAgIGEgM3AhsKDAoFBAAC
AgESAzccJwoMCgUEAAICAxIDNyorCgwKBQQAAgIIEgM4BjEKDwoIBAACAgicCAASAzgHMApR
CgQEAAIDEgQ7AjwyGkMgT3V0cHV0IG9ubHkuIFRoZSBUaW1lc3RhbXAgb2Ygd2hlbiB0aGUg
YENvcnB1c2Agd2FzIGxhc3QgdXBkYXRlZC4KCgwKBQQAAgMGEgM7AhsKDAoFBAACAwESAzsc
JwoMCgUEAAIDAxIDOyorCgwKBQQAAgMIEgM8BjEKDwoIBAACAwicCAASAzwHMAptCgIEARIE
QQBlARphIEEgYERvY3VtZW50YCBpcyBhIGNvbGxlY3Rpb24gb2YgYENodW5rYHMuCiBBIGBD
b3JwdXNgIGNhbiBoYXZlIGEgbWF4aW11bSBvZiAxMCwwMDAgYERvY3VtZW50YHMuCgoKCgME
AQESA0EIEAoLCgMEAQcSBEICRwQKDQoFBAEHnQgSBEICRwQKuwMKBAQBAgASBE8CUgQarAMg
SW1tdXRhYmxlLiBJZGVudGlmaWVyLiBUaGUgYERvY3VtZW50YCByZXNvdXJjZSBuYW1lLiBU
aGUgSUQgKG5hbWUgZXhjbHVkaW5nCiB0aGUgImNvcnBvcmEvKi9kb2N1bWVudHMvIiBwcmVm
aXgpIGNhbiBjb250YWluIHVwIHRvIDQwIGNoYXJhY3RlcnMgdGhhdCBhcmUKIGxvd2VyY2Fz
ZSBhbHBoYW51bWVyaWMgb3IgZGFzaGVzICgtKS4gVGhlIElEIGNhbm5vdCBzdGFydCBvciBl
bmQgd2l0aCBhCiBkYXNoLiBJZiB0aGUgbmFtZSBpcyBlbXB0eSBvbiBjcmVhdGUsIGEgdW5p
cXVlIG5hbWUgd2lsbCBiZSBkZXJpdmVkIGZyb20KIGBkaXNwbGF5X25hbWVgIGFsb25nIHdp
dGggYSAxMiBjaGFyYWN0ZXIgcmFuZG9tIHN1ZmZpeC4KIEV4YW1wbGU6IGBjb3Jwb3JhL3tj
b3JwdXNfaWR9L2RvY3VtZW50cy9teS1hd2Vzb21lLWRvYy0xMjNhNDU2Yjc4OWNgCgoMCgUE
AQIABRIDTwIICgwKBQQBAgABEgNPCQ0KDAoFBAECAAMSA08QEQoNCgUEAQIACBIETxJSAwoP
CggEAQIACJwIABIDUAQsCg8KCAQBAgAInAgBEgNRBCsKzQEKBAQBAgESA1cCQxq/ASBPcHRp
b25hbC4gVGhlIGh1bWFuLXJlYWRhYmxlIGRpc3BsYXkgbmFtZSBmb3IgdGhlIGBEb2N1bWVu
dGAuIFRoZSBkaXNwbGF5CiBuYW1lIG11c3QgYmUgbm8gbW9yZSB0aGFuIDUxMiBjaGFyYWN0
ZXJzIGluIGxlbmd0aCwgaW5jbHVkaW5nIHNwYWNlcy4KIEV4YW1wbGU6ICJTZW1hbnRpYyBS
ZXRyaWV2ZXIgRG9jdW1lbnRhdGlvbiIKCgwKBQQBAgEFEgNXAggKDAoFBAECAQESA1cJFQoM
CgUEAQIBAxIDVxgZCgwKBQQBAgEIEgNXGkIKDwoIBAECAQicCAASA1cbQQqeAQoEBAECAhIE
WwJcLxqPASBPcHRpb25hbC4gVXNlciBwcm92aWRlZCBjdXN0b20gbWV0YWRhdGEgc3RvcmVk
IGFzIGtleS12YWx1ZSBwYWlycyB1c2VkIGZvcgogcXVlcnlpbmcuIEEgYERvY3VtZW50YCBj
YW4gaGF2ZSBhIG1heGltdW0gb2YgMjAgYEN1c3RvbU1ldGFkYXRhYC4KCgwKBQQBAgIEEgNb
AgoKDAoFBAECAgYSA1sLGQoMCgUEAQICARIDWxopCgwKBQQBAgIDEgNbLC0KDAoFBAECAggS
A1wGLgoPCggEAQICCJwIABIDXActClMKBAQBAgMSBF8CYDIaRSBPdXRwdXQgb25seS4gVGhl
IFRpbWVzdGFtcCBvZiB3aGVuIHRoZSBgRG9jdW1lbnRgIHdhcyBsYXN0IHVwZGF0ZWQuCgoM
CgUEAQIDBhIDXwIbCgwKBQQBAgMBEgNfHCcKDAoFBAECAwMSA18qKwoMCgUEAQIDCBIDYAYx
Cg8KCAQBAgMInAgAEgNgBzAKTgoEBAECBBIEYwJkMhpAIE91dHB1dCBvbmx5LiBUaGUgVGlt
ZXN0YW1wIG9mIHdoZW4gdGhlIGBEb2N1bWVudGAgd2FzIGNyZWF0ZWQuCgoMCgUEAQIEBhID
YwIbCgwKBQQBAgQBEgNjHCcKDAoFBAECBAMSA2MqKwoMCgUEAQIECBIDZAYxCg8KCAQBAgQI
nAgAEgNkBzAKTAoCBAISBGgAawEaQCBVc2VyIHByb3ZpZGVkIHN0cmluZyB2YWx1ZXMgYXNz
aWduZWQgdG8gYSBzaW5nbGUgbWV0YWRhdGEga2V5LgoKCgoDBAIBEgNoCBIKOgoEBAICABID
agIdGi0gVGhlIHN0cmluZyB2YWx1ZXMgb2YgdGhlIG1ldGFkYXRhIHRvIHN0b3JlLgoKDAoF
BAICAAQSA2oCCgoMCgUEAgIABRIDagsRCgwKBQQCAgABEgNqEhgKDAoFBAICAAMSA2obHAo/
CgIEAxIEbgB8ARozIFVzZXIgcHJvdmlkZWQgbWV0YWRhdGEgc3RvcmVkIGFzIGtleS12YWx1
ZSBwYWlycy4KCgoKAwQDARIDbggWCgwKBAQDCAASBG8CeAMKDAoFBAMIAAESA28IDQo5CgQE
AwIAEgNxBBwaLCBUaGUgc3RyaW5nIHZhbHVlIG9mIHRoZSBtZXRhZGF0YSB0byBzdG9yZS4K
CgwKBQQDAgAFEgNxBAoKDAoFBAMCAAESA3ELFwoMCgUEAwIAAxIDcRobCj0KBAQDAgESA3QE
JRowIFRoZSBTdHJpbmdMaXN0IHZhbHVlIG9mIHRoZSBtZXRhZGF0YSB0byBzdG9yZS4KCgwK
BQQDAgEGEgN0BA4KDAoFBAMCAQESA3QPIAoMCgUEAwIBAxIDdCMkCjoKBAQDAgISA3cEHBot
IFRoZSBudW1lcmljIHZhbHVlIG9mIHRoZSBtZXRhZGF0YSB0byBzdG9yZS4KCgwKBQQDAgIF
EgN3BAkKDAoFBAMCAgESA3cKFwoMCgUEAwICAxIDdxobCjoKBAQDAgMSA3sCOhotIFJlcXVp
cmVkLiBUaGUga2V5IG9mIHRoZSBtZXRhZGF0YSB0byBzdG9yZS4KCgwKBQQDAgMFEgN7AggK
DAoFBAMCAwESA3sJDAoMCgUEAwIDAxIDew8QCgwKBQQDAgMIEgN7ETkKDwoIBAMCAwicCAAS
A3sSOArCAgoCBAQSBoQBAIsBARqzAiBVc2VyIHByb3ZpZGVkIGZpbHRlciB0byBsaW1pdCBy
ZXRyaWV2YWwgYmFzZWQgb24gYENodW5rYCBvciBgRG9jdW1lbnRgIGxldmVsCiBtZXRhZGF0
YSB2YWx1ZXMuCiBFeGFtcGxlIChnZW5yZSA9IGRyYW1hIE9SIGdlbnJlID0gYWN0aW9uKToK
ICAga2V5ID0gImRvY3VtZW50LmN1c3RvbV9tZXRhZGF0YS5nZW5yZSIKICAgY29uZGl0aW9u
cyA9IFt7c3RyaW5nX3ZhbHVlID0gImRyYW1hIiwgb3BlcmF0aW9uID0gRVFVQUx9LAogICAg
ICAgICAgICAgICAgIHtzdHJpbmdfdmFsdWUgPSAiYWN0aW9uIiwgb3BlcmF0aW9uID0gRVFV
QUx9XQoKCwoDBAQBEgSEAQgWCj8KBAQEAgASBIYBAjoaMSBSZXF1aXJlZC4gVGhlIGtleSBv
ZiB0aGUgbWV0YWRhdGEgdG8gZmlsdGVyIG9uLgoKDQoFBAQCAAUSBIYBAggKDQoFBAQCAAES
BIYBCQwKDQoFBAQCAAMSBIYBDxAKDQoFBAQCAAgSBIYBETkKEAoIBAQCAAicCAASBIYBEjgK
jQEKBAQEAgESBIoBAk0afyBSZXF1aXJlZC4gVGhlIGBDb25kaXRpb25gcyBmb3IgdGhlIGdp
dmVuIGtleSB0aGF0IHdpbGwgdHJpZ2dlciB0aGlzIGZpbHRlci4KIE11bHRpcGxlIGBDb25k
aXRpb25gcyBhcmUgam9pbmVkIGJ5IGxvZ2ljYWwgT1JzLgoKDQoFBAQCAQQSBIoBAgoKDQoF
BAQCAQYSBIoBCxQKDQoFBAQCAQESBIoBFR8KDQoFBAQCAQMSBIoBIiMKDQoFBAQCAQgSBIoB
JEwKEAoIBAQCAQicCAASBIoBJUsKPAoCBAUSBo4BAMABARouIEZpbHRlciBjb25kaXRpb24g
YXBwbGljYWJsZSB0byBhIHNpbmdsZSBrZXkuCgoLCgMEBQESBI4BCBEKVgoEBAUEABIGkAEC
rQEDGkYgRGVmaW5lcyB0aGUgdmFsaWQgb3BlcmF0b3JzIHRoYXQgY2FuIGJlIGFwcGxpZWQg
dG8gYSBrZXktdmFsdWUgcGFpci4KCg0KBQQFBAABEgSQAQcPCjoKBgQFBAACABIEkgEEHRoq
IFRoZSBkZWZhdWx0IHZhbHVlLiBUaGlzIHZhbHVlIGlzIHVudXNlZC4KCg8KBwQFBAACAAES
BJIBBBgKDwoHBAUEAAIAAhIEkgEbHAonCgYEBQQAAgESBJUBBA0aFyBTdXBwb3J0ZWQgYnkg
bnVtZXJpYy4KCg8KBwQFBAACAQESBJUBBAgKDwoHBAUEAAIBAhIElQELDAonCgYEBQQAAgIS
BJgBBBMaFyBTdXBwb3J0ZWQgYnkgbnVtZXJpYy4KCg8KBwQFBAACAgESBJgBBA4KDwoHBAUE
AAICAhIEmAEREgowCgYEBQQAAgMSBJsBBA4aICBTdXBwb3J0ZWQgYnkgbnVtZXJpYyAmIHN0
cmluZy4KCg8KBwQFBAACAwESBJsBBAkKDwoHBAUEAAIDAhIEmwEMDQonCgYEBQQAAgQSBJ4B
BBYaFyBTdXBwb3J0ZWQgYnkgbnVtZXJpYy4KCg8KBwQFBAACBAESBJ4BBBEKDwoHBAUEAAIE
AhIEngEUFQonCgYEBQQAAgUSBKEBBBAaFyBTdXBwb3J0ZWQgYnkgbnVtZXJpYy4KCg8KBwQF
BAACBQESBKEBBAsKDwoHBAUEAAIFAhIEoQEODwowCgYEBQQAAgYSBKQBBBIaICBTdXBwb3J0
ZWQgYnkgbnVtZXJpYyAmIHN0cmluZy4KCg8KBwQFBAACBgESBKQBBA0KDwoHBAUEAAIGAhIE
pAEQEQp5CgYEBQQAAgcSBKgBBBEaaSBTdXBwb3J0ZWQgYnkgc3RyaW5nIG9ubHkgd2hlbiBg
Q3VzdG9tTWV0YWRhdGFgIHZhbHVlIHR5cGUgZm9yIHRoZSBnaXZlbgoga2V5IGhhcyBhIGBz
dHJpbmdfbGlzdF92YWx1ZWAuCgoPCgcEBQQAAgcBEgSoAQQMCg8KBwQFBAACBwISBKgBDxAK
eQoGBAUEAAIIEgSsAQQRGmkgU3VwcG9ydGVkIGJ5IHN0cmluZyBvbmx5IHdoZW4gYEN1c3Rv
bU1ldGFkYXRhYCB2YWx1ZSB0eXBlIGZvciB0aGUgZ2l2ZW4KIGtleSBoYXMgYSBgc3RyaW5n
X2xpc3RfdmFsdWVgLgoKDwoHBAUEAAIIARIErAEEDAoPCgcEBQQAAggCEgSsAQ8QCowDCgQE
BQgAEga1AQK7AQMa+wIgVGhlIHZhbHVlIHR5cGUgbXVzdCBiZSBjb25zaXN0ZW50IHdpdGgg
dGhlIHZhbHVlIHR5cGUgZGVmaW5lZCBpbiB0aGUgZmllbGQKIGZvciB0aGUgY29ycmVzcG9u
ZGluZyBrZXkuIElmIHRoZSB2YWx1ZSB0eXBlcyBhcmUgbm90IGNvbnNpc3RlbnQsIHRoZQog
cmVzdWx0IHdpbGwgYmUgYW4gZW1wdHkgc2V0LiBXaGVuIHRoZSBgQ3VzdG9tTWV0YWRhdGFg
IGhhcyBhIGBTdHJpbmdMaXN0YAogdmFsdWUgdHlwZSwgdGhlIGZpbHRlcmluZyBjb25kaXRp
b24gc2hvdWxkIHVzZSBgc3RyaW5nX3ZhbHVlYCBwYWlyZWQgd2l0aAogYW4gSU5DTFVERVMv
RVhDTFVERVMgb3BlcmF0aW9uLCBvdGhlcndpc2UgdGhlIHJlc3VsdCB3aWxsIGFsc28gYmUg
YW4gZW1wdHkKIHNldC4KCg0KBQQFCAABEgS1AQgNCjsKBAQFAgASBLcBBBwaLSBUaGUgc3Ry
aW5nIHZhbHVlIHRvIGZpbHRlciB0aGUgbWV0YWRhdGEgb24uCgoNCgUEBQIABRIEtwEECgoN
CgUEBQIAARIEtwELFwoNCgUEBQIAAxIEtwEaGwo8CgQEBQIBEgS6AQQcGi4gVGhlIG51bWVy
aWMgdmFsdWUgdG8gZmlsdGVyIHRoZSBtZXRhZGF0YSBvbi4KCg0KBQQFAgEFEgS6AQQJCg0K
BQQFAgEBEgS6AQoXCg0KBQQFAgEDEgS6ARobCmEKBAQFAgISBL8BAkIaUyBSZXF1aXJlZC4g
T3BlcmF0b3IgYXBwbGllZCB0byB0aGUgZ2l2ZW4ga2V5LXZhbHVlIHBhaXIgdG8gdHJpZ2dl
ciB0aGUKIGNvbmRpdGlvbi4KCg0KBQQFAgIGEgS/AQIKCg0KBQQFAgIBEgS/AQsUCg0KBQQF
AgIDEgS/ARcYCg0KBQQFAgIIEgS/ARlBChAKCAQFAgIInAgAEgS/ARpACswBCgIEBhIGxQEA
+gEBGr0BIEEgYENodW5rYCBpcyBhIHN1YnBhcnQgb2YgYSBgRG9jdW1lbnRgIHRoYXQgaXMg
dHJlYXRlZCBhcyBhbiBpbmRlcGVuZGVudCB1bml0CiBmb3IgdGhlIHB1cnBvc2VzIG9mIHZl
Y3RvciByZXByZXNlbnRhdGlvbiBhbmQgc3RvcmFnZS4KIEEgYENvcnB1c2AgY2FuIGhhdmUg
YSBtYXhpbXVtIG9mIDEgbWlsbGlvbiBgQ2h1bmtgcy4KCgsKAwQGARIExQEIDQoNCgMEBgcS
BsYBAssBBAoPCgUEBgedCBIGxgECywEECjgKBAQGBAASBs4BAtoBAxooIFN0YXRlcyBmb3Ig
dGhlIGxpZmVjeWNsZSBvZiBhIGBDaHVua2AuCgoNCgUEBgQAARIEzgEHDApQCgYEBgQAAgAS
BNABBBoaQCBUaGUgZGVmYXVsdCB2YWx1ZS4gVGhpcyB2YWx1ZSBpcyB1c2VkIGlmIHRoZSBz
dGF0ZSBpcyBvbWl0dGVkLgoKDwoHBAYEAAIAARIE0AEEFQoPCgcEBgQAAgACEgTQARgZCkwK
BgQGBAACARIE0wEEIRo8IGBDaHVua2AgaXMgYmVpbmcgcHJvY2Vzc2VkIChlbWJlZGRpbmcg
YW5kIHZlY3RvciBzdG9yYWdlKS4KCg8KBwQGBAACAQESBNMBBBwKDwoHBAYEAAIBAhIE0wEf
IApCCgYEBgQAAgISBNYBBBUaMiBgQ2h1bmtgIGlzIHByb2Nlc3NlZCBhbmQgYXZhaWxhYmxl
IGZvciBxdWVyeWluZy4KCg8KBwQGBAACAgESBNYBBBAKDwoHBAYEAAICAhIE1gETFAosCgYE
BgQAAgMSBNkBBBYaHCBgQ2h1bmtgIGZhaWxlZCBwcm9jZXNzaW5nLgoKDwoHBAYEAAIDARIE
2QEEEAoPCgcEBgQAAgMCEgTZARMVCqEDCgQEBgIAEgbiAQLlAQQakAMgSW1tdXRhYmxlLiBJ
ZGVudGlmaWVyLiBUaGUgYENodW5rYCByZXNvdXJjZSBuYW1lLiBUaGUgSUQgKG5hbWUgZXhj
bHVkaW5nCiB0aGUgImNvcnBvcmEvKi9kb2N1bWVudHMvKi9jaHVua3MvIiBwcmVmaXgpIGNh
biBjb250YWluIHVwIHRvIDQwIGNoYXJhY3RlcnMKIHRoYXQgYXJlIGxvd2VyY2FzZSBhbHBo
YW51bWVyaWMgb3IgZGFzaGVzICgtKS4gVGhlIElEIGNhbm5vdCBzdGFydCBvciBlbmQKIHdp
dGggYSBkYXNoLiBJZiB0aGUgbmFtZSBpcyBlbXB0eSBvbiBjcmVhdGUsIGEgcmFuZG9tIDEy
LWNoYXJhY3RlciB1bmlxdWUKIElEIHdpbGwgYmUgZ2VuZXJhdGVkLgogRXhhbXBsZTogYGNv
cnBvcmEve2NvcnB1c19pZH0vZG9jdW1lbnRzL3tkb2N1bWVudF9pZH0vY2h1bmtzLzEyM2E0
NTZiNzg5Y2AKCg0KBQQGAgAFEgTiAQIICg0KBQQGAgABEgTiAQkNCg0KBQQGAgADEgTiARAR
Cg8KBQQGAgAIEgbiARLlAQMKEAoIBAYCAAicCAASBOMBBCwKEAoIBAYCAAicCAESBOQBBCsK
gAEKBAQGAgESBOkBAj4aciBSZXF1aXJlZC4gVGhlIGNvbnRlbnQgZm9yIHRoZSBgQ2h1bmtg
LCBzdWNoIGFzIHRoZSB0ZXh0IHN0cmluZy4KIFRoZSBtYXhpbXVtIG51bWJlciBvZiB0b2tl
bnMgcGVyIGNodW5rIGlzIDIwNDMuCgoNCgUEBgIBBhIE6QECCwoNCgUEBgIBARIE6QEMEAoN
CgUEBgIBAxIE6QETFAoNCgUEBgIBCBIE6QEVPQoQCggEBgIBCJwIABIE6QEWPAqNAQoEBAYC
AhIG7QEC7gEvGn0gT3B0aW9uYWwuIFVzZXIgcHJvdmlkZWQgY3VzdG9tIG1ldGFkYXRhIHN0
b3JlZCBhcyBrZXktdmFsdWUgcGFpcnMuCiBUaGUgbWF4aW11bSBudW1iZXIgb2YgYEN1c3Rv
bU1ldGFkYXRhYCBwZXIgY2h1bmsgaXMgMjAuCgoNCgUEBgICBBIE7QECCgoNCgUEBgICBhIE
7QELGQoNCgUEBgICARIE7QEaKQoNCgUEBgICAxIE7QEsLQoNCgUEBgICCBIE7gEGLgoQCggE
BgICCJwIABIE7gEHLQpNCgQEBgIDEgbxAQLyATIaPSBPdXRwdXQgb25seS4gVGhlIFRpbWVz
dGFtcCBvZiB3aGVuIHRoZSBgQ2h1bmtgIHdhcyBjcmVhdGVkLgoKDQoFBAYCAwYSBPEBAhsK
DQoFBAYCAwESBPEBHCcKDQoFBAYCAwMSBPEBKisKDQoFBAYCAwgSBPIBBjEKEAoIBAYCAwic
CAASBPIBBzAKUgoEBAYCBBIG9QEC9gEyGkIgT3V0cHV0IG9ubHkuIFRoZSBUaW1lc3RhbXAg
b2Ygd2hlbiB0aGUgYENodW5rYCB3YXMgbGFzdCB1cGRhdGVkLgoKDQoFBAYCBAYSBPUBAhsK
DQoFBAYCBAESBPUBHCcKDQoFBAYCBAMSBPUBKisKDQoFBAYCBAgSBPYBBjEKEAoIBAYCBAic
CAASBPYBBzAKOgoEBAYCBRIE+QECPhosIE91dHB1dCBvbmx5LiBDdXJyZW50IHN0YXRlIG9m
IHRoZSBgQ2h1bmtgLgoKDQoFBAYCBQYSBPkBAgcKDQoFBAYCBQESBPkBCA0KDQoFBAYCBQMS
BPkBEBEKDQoFBAYCBQgSBPkBEj0KEAoIBAYCBQicCAASBPkBEzwKQwoCBAcSBv0BAIMCARo1
IEV4dHJhY3RlZCBkYXRhIHRoYXQgcmVwcmVzZW50cyB0aGUgYENodW5rYCBjb250ZW50LgoK
CwoDBAcBEgT9AQgRCg4KBAQHCAASBv4BAoICAwoNCgUEBwgAARIE/gEIDAphCgQEBwIAEgSB
AgQcGlMgVGhlIGBDaHVua2AgY29udGVudCBhcyBhIHN0cmluZy4KIFRoZSBtYXhpbXVtIG51
bWJlciBvZiB0b2tlbnMgcGVyIGNodW5rIGlzIDIwNDMuCgoNCgUEBwIABRIEgQIECgoNCgUE
BwIAARIEgQILFwoNCgUEBwIAAxIEgQIaG2IGcHJvdG8z
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Ai::Generativelanguage::V1alpha::Retriever::Corpus ===
    # Fields for Corpus
    # Field: name Type: 9 ()
    # Field: display_name Type: 9 ()
    # Field: create_time Type: 11 (.google.protobuf.Timestamp)
    # Field: update_time Type: 11 (.google.protobuf.Timestamp)

# === Message: Google::Ai::Generativelanguage::V1alpha::Retriever::Document ===
    # Fields for Document
    # Field: name Type: 9 ()
    # Field: display_name Type: 9 ()
    # Field: custom_metadata Type: 11 (.google.ai.generativelanguage.v1alpha.CustomMetadata)
    # Field: update_time Type: 11 (.google.protobuf.Timestamp)
    # Field: create_time Type: 11 (.google.protobuf.Timestamp)

# === Message: Google::Ai::Generativelanguage::V1alpha::Retriever::StringList ===
    # Fields for StringList
    # Field: values Type: 9 ()

# === Message: Google::Ai::Generativelanguage::V1alpha::Retriever::CustomMetadata ===
    # Fields for CustomMetadata
    # Field: string_value Type: 9 ()
    # Field: string_list_value Type: 11 (.google.ai.generativelanguage.v1alpha.StringList)
    # Field: numeric_value Type: 2 ()
    # Field: key Type: 9 ()

# === Message: Google::Ai::Generativelanguage::V1alpha::Retriever::MetadataFilter ===
    # Fields for MetadataFilter
    # Field: key Type: 9 ()
    # Field: conditions Type: 11 (.google.ai.generativelanguage.v1alpha.Condition)

# === Message: Google::Ai::Generativelanguage::V1alpha::Retriever::Condition ===
    # Fields for Condition
    # Field: string_value Type: 9 ()
    # Field: numeric_value Type: 2 ()
    # Field: operation Type: 14 (.google.ai.generativelanguage.v1alpha.Condition.Operator)

# Enum: Condition::Operator
our $Condition_OPERATOR_UNSPECIFIED = 0;
our $Condition_LESS = 1;
our $Condition_LESS_EQUAL = 2;
our $Condition_EQUAL = 3;
our $Condition_GREATER_EQUAL = 4;
our $Condition_GREATER = 5;
our $Condition_NOT_EQUAL = 6;
our $Condition_INCLUDES = 7;
our $Condition_EXCLUDES = 8;

# === Message: Google::Ai::Generativelanguage::V1alpha::Retriever::Chunk ===
    # Fields for Chunk
    # Field: name Type: 9 ()
    # Field: data Type: 11 (.google.ai.generativelanguage.v1alpha.ChunkData)
    # Field: custom_metadata Type: 11 (.google.ai.generativelanguage.v1alpha.CustomMetadata)
    # Field: create_time Type: 11 (.google.protobuf.Timestamp)
    # Field: update_time Type: 11 (.google.protobuf.Timestamp)
    # Field: state Type: 14 (.google.ai.generativelanguage.v1alpha.Chunk.State)

# Enum: Chunk::State
our $Chunk_STATE_UNSPECIFIED = 0;
our $Chunk_STATE_PENDING_PROCESSING = 1;
our $Chunk_STATE_ACTIVE = 2;
our $Chunk_STATE_FAILED = 10;

# === Message: Google::Ai::Generativelanguage::V1alpha::Retriever::ChunkData ===
    # Fields for ChunkData
    # Field: string_value Type: 9 ()

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Ai::Generativelanguage::V1alpha::Retriever - Compiled Protocol Buffers messages for google/ai/generativelanguage/v1alpha/retriever.proto

=head1 SYNOPSIS

    use Google::Ai::Generativelanguage::V1alpha::Retriever;

    my $msg = Google::Ai::Generativelanguage::V1alpha::Retriever::Corpus->new({
        name => $name,
        display_name => $display_name,
        create_time => $create_time,
        update_time => $update_time,
    });

    # Read or update a field
    my $val = $msg->name();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Ai::Generativelanguage::V1alpha::Retriever::Corpus->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/ai/generativelanguage/v1alpha/retriever.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Ai::Generativelanguage::V1alpha::Retriever::Corpus

A `Corpus` is a collection of `Document`s.
A project can create up to 5 corpora.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Immutable. Identifier. The `Corpus` resource name. The ID (name excluding
the "corpora/" prefix) can contain up to 40 characters that are lowercase
alphanumeric or dashes
(-). The ID cannot start or end with a dash. If the name is empty on
create, a unique name will be derived from `display_name` along with a 12
character random suffix.
Example: `corpora/my-awesome-corpora-123a456b789c`

=item * C<< $msg->display_name() >> / C<< $msg->display_name($value) >>

Type: C<String>

Optional. The human-readable display name for the `Corpus`. The display
name must be no more than 512 characters in length, including spaces.
Example: "Docs on Semantic Retriever"

=item * C<< $msg->create_time() >> / C<< $msg->create_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Output only. The Timestamp of when the `Corpus` was created.

=item * C<< $msg->update_time() >> / C<< $msg->update_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Output only. The Timestamp of when the `Corpus` was last updated.

=back

=head2 Google::Ai::Generativelanguage::V1alpha::Retriever::Document

A `Document` is a collection of `Chunk`s.
A `Corpus` can have a maximum of 10,000 `Document`s.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Immutable. Identifier. The `Document` resource name. The ID (name excluding
the "corpora/*/documents/" prefix) can contain up to 40 characters that are
lowercase alphanumeric or dashes (-). The ID cannot start or end with a
dash. If the name is empty on create, a unique name will be derived from
`display_name` along with a 12 character random suffix.
Example: `corpora/{corpus_id}/documents/my-awesome-doc-123a456b789c`

=item * C<< $msg->display_name() >> / C<< $msg->display_name($value) >>

Type: C<String>

Optional. The human-readable display name for the `Document`. The display
name must be no more than 512 characters in length, including spaces.
Example: "Semantic Retriever Documentation"

=item * C<< $msg->custom_metadata() >> / C<< $msg->custom_metadata($value) >>

Type: C<Message> (L<Google::Ai::Generativelanguage::V1alpha::Retriever::CustomMetadata>)

Optional. User provided custom metadata stored as key-value pairs used for
querying. A `Document` can have a maximum of 20 `CustomMetadata`.

=item * C<< $msg->update_time() >> / C<< $msg->update_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Output only. The Timestamp of when the `Document` was last updated.

=item * C<< $msg->create_time() >> / C<< $msg->create_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Output only. The Timestamp of when the `Document` was created.

=back

=head2 Google::Ai::Generativelanguage::V1alpha::Retriever::StringList

User provided string values assigned to a single metadata key.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->values() >> / C<< $msg->values($value) >>

Type: C<String>

The string values of the metadata to store.

=back

=head2 Google::Ai::Generativelanguage::V1alpha::Retriever::CustomMetadata

User provided metadata stored as key-value pairs.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->string_value() >> / C<< $msg->string_value($value) >>

Type: C<String>

The string value of the metadata to store.

=item * C<< $msg->string_list_value() >> / C<< $msg->string_list_value($value) >>

Type: C<Message> (L<Google::Ai::Generativelanguage::V1alpha::Retriever::StringList>)

The StringList value of the metadata to store.

=item * C<< $msg->numeric_value() >> / C<< $msg->numeric_value($value) >>

Type: C<Float>

The numeric value of the metadata to store.

=item * C<< $msg->key() >> / C<< $msg->key($value) >>

Type: C<String>

Required. The key of the metadata to store.

=back

=head2 Google::Ai::Generativelanguage::V1alpha::Retriever::MetadataFilter

User provided filter to limit retrieval based on `Chunk` or `Document` level
metadata values.
Example (genre = drama OR genre = action):
  key = "document.custom_metadata.genre"
  conditions = [{string_value = "drama", operation = EQUAL},
                {string_value = "action", operation = EQUAL}]

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->key() >> / C<< $msg->key($value) >>

Type: C<String>

Required. The key of the metadata to filter on.

=item * C<< $msg->conditions() >> / C<< $msg->conditions($value) >>

Type: C<Message> (L<Google::Ai::Generativelanguage::V1alpha::Retriever::Condition>)

Required. The `Condition`s for the given key that will trigger this filter.
Multiple `Condition`s are joined by logical ORs.

=back

=head2 Google::Ai::Generativelanguage::V1alpha::Retriever::Condition

Filter condition applicable to a single key.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->string_value() >> / C<< $msg->string_value($value) >>

Type: C<String>

The string value to filter the metadata on.

=item * C<< $msg->numeric_value() >> / C<< $msg->numeric_value($value) >>

Type: C<Float>

The numeric value to filter the metadata on.

=item * C<< $msg->operation() >> / C<< $msg->operation($value) >>

Type: C<Enum> (L<Google::Ai::Generativelanguage::V1alpha::Condition::Operator>)

Required. Operator applied to the given key-value pair to trigger the
condition.

=back

=head3 Enum: Condition::Operator

=over 4

=item * C<OPERATOR_UNSPECIFIED> => C<0>

=item * C<LESS> => C<1>

=item * C<LESS_EQUAL> => C<2>

=item * C<EQUAL> => C<3>

=item * C<GREATER_EQUAL> => C<4>

=item * C<GREATER> => C<5>

=item * C<NOT_EQUAL> => C<6>

=item * C<INCLUDES> => C<7>

=item * C<EXCLUDES> => C<8>

=back

=head2 Google::Ai::Generativelanguage::V1alpha::Retriever::Chunk

A `Chunk` is a subpart of a `Document` that is treated as an independent unit
for the purposes of vector representation and storage.
A `Corpus` can have a maximum of 1 million `Chunk`s.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Immutable. Identifier. The `Chunk` resource name. The ID (name excluding
the "corpora/*/documents/*/chunks/" prefix) can contain up to 40 characters
that are lowercase alphanumeric or dashes (-). The ID cannot start or end
with a dash. If the name is empty on create, a random 12-character unique
ID will be generated.
Example: `corpora/{corpus_id}/documents/{document_id}/chunks/123a456b789c`

=item * C<< $msg->data() >> / C<< $msg->data($value) >>

Type: C<Message> (L<Google::Ai::Generativelanguage::V1alpha::Retriever::ChunkData>)

Required. The content for the `Chunk`, such as the text string.
The maximum number of tokens per chunk is 2043.

=item * C<< $msg->custom_metadata() >> / C<< $msg->custom_metadata($value) >>

Type: C<Message> (L<Google::Ai::Generativelanguage::V1alpha::Retriever::CustomMetadata>)

Optional. User provided custom metadata stored as key-value pairs.
The maximum number of `CustomMetadata` per chunk is 20.

=item * C<< $msg->create_time() >> / C<< $msg->create_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Output only. The Timestamp of when the `Chunk` was created.

=item * C<< $msg->update_time() >> / C<< $msg->update_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Output only. The Timestamp of when the `Chunk` was last updated.

=item * C<< $msg->state() >> / C<< $msg->state($value) >>

Type: C<Enum> (L<Google::Ai::Generativelanguage::V1alpha::Chunk::State>)

Output only. Current state of the `Chunk`.

=back

=head3 Enum: Chunk::State

=over 4

=item * C<STATE_UNSPECIFIED> => C<0>

=item * C<STATE_PENDING_PROCESSING> => C<1>

=item * C<STATE_ACTIVE> => C<2>

=item * C<STATE_FAILED> => C<10>

=back

=head2 Google::Ai::Generativelanguage::V1alpha::Retriever::ChunkData

Extracted data that represents the `Chunk` content.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->string_value() >> / C<< $msg->string_value($value) >>

Type: C<String>

The `Chunk` content as a string.
The maximum number of tokens per chunk is 2043.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Ai::Generativelanguage::V1alpha::Retriever::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
