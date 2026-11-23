package Google::Ai::Generativelanguage::V1beta::Retriever;

use strict;
use warnings;

our $VERSION = '0.12';

use Protobuf::Message;
use Protobuf::DescriptorPool;
use Protobuf::Internal qw(:all);
use MIME::Base64;

BEGIN {
    eval { require Google::Api::FieldBehavior };
    eval { require Google::Api::Resource };
    eval { require Google::Protobuf::Timestamp };
    my $descriptor_b64 = <<'EOF';
CjNnb29nbGUvYWkvZ2VuZXJhdGl2ZWxhbmd1YWdlL3YxYmV0YS9yZXRyaWV2ZXIucHJvdG8S
I2dvb2dsZS5haS5nZW5lcmF0aXZlbGFuZ3VhZ2UudjFiZXRhGh9nb29nbGUvYXBpL2ZpZWxk
X2JlaGF2aW9yLnByb3RvGhlnb29nbGUvYXBpL3Jlc291cmNlLnByb3RvGh9nb29nbGUvcHJv
dG9idWYvdGltZXN0YW1wLnByb3RvIqICCgZDb3JwdXMSGgoEbmFtZRgBIAEoCUIG4EEI4EEF
UgRuYW1lEiYKDGRpc3BsYXlfbmFtZRgCIAEoCUID4EEBUgtkaXNwbGF5TmFtZRJACgtjcmVh
dGVfdGltZRgDIAEoCzIaLmdvb2dsZS5wcm90b2J1Zi5UaW1lc3RhbXBCA+BBA1IKY3JlYXRl
VGltZRJACgt1cGRhdGVfdGltZRgEIAEoCzIaLmdvb2dsZS5wcm90b2J1Zi5UaW1lc3RhbXBC
A+BBA1IKdXBkYXRlVGltZTpQ6kFNCihnZW5lcmF0aXZlbGFuZ3VhZ2UuZ29vZ2xlYXBpcy5j
b20vQ29ycHVzEhBjb3Jwb3JhL3tjb3JwdXN9Kgdjb3Jwb3JhMgZjb3JwdXMiogMKCERvY3Vt
ZW50EhoKBG5hbWUYASABKAlCBuBBCOBBBVIEbmFtZRImCgxkaXNwbGF5X25hbWUYAiABKAlC
A+BBAVILZGlzcGxheU5hbWUSYQoPY3VzdG9tX21ldGFkYXRhGAMgAygLMjMuZ29vZ2xlLmFp
LmdlbmVyYXRpdmVsYW5ndWFnZS52MWJldGEuQ3VzdG9tTWV0YWRhdGFCA+BBAVIOY3VzdG9t
TWV0YWRhdGESQAoLdXBkYXRlX3RpbWUYBCABKAsyGi5nb29nbGUucHJvdG9idWYuVGltZXN0
YW1wQgPgQQNSCnVwZGF0ZVRpbWUSQAoLY3JlYXRlX3RpbWUYBSABKAsyGi5nb29nbGUucHJv
dG9idWYuVGltZXN0YW1wQgPgQQNSCmNyZWF0ZVRpbWU6a+pBaAoqZ2VuZXJhdGl2ZWxhbmd1
YWdlLmdvb2dsZWFwaXMuY29tL0RvY3VtZW50EiVjb3Jwb3JhL3tjb3JwdXN9L2RvY3VtZW50
cy97ZG9jdW1lbnR9Kglkb2N1bWVudHMyCGRvY3VtZW50IiQKClN0cmluZ0xpc3QSFgoGdmFs
dWVzGAEgAygJUgZ2YWx1ZXMi2wEKDkN1c3RvbU1ldGFkYXRhEiMKDHN0cmluZ192YWx1ZRgC
IAEoCUgAUgtzdHJpbmdWYWx1ZRJdChFzdHJpbmdfbGlzdF92YWx1ZRgGIAEoCzIvLmdvb2ds
ZS5haS5nZW5lcmF0aXZlbGFuZ3VhZ2UudjFiZXRhLlN0cmluZ0xpc3RIAFIPc3RyaW5nTGlz
dFZhbHVlEiUKDW51bWVyaWNfdmFsdWUYByABKAJIAFIMbnVtZXJpY1ZhbHVlEhUKA2tleRgB
IAEoCUID4EECUgNrZXlCBwoFdmFsdWUifAoOTWV0YWRhdGFGaWx0ZXISFQoDa2V5GAEgASgJ
QgPgQQJSA2tleRJTCgpjb25kaXRpb25zGAIgAygLMi4uZ29vZ2xlLmFpLmdlbmVyYXRpdmVs
YW5ndWFnZS52MWJldGEuQ29uZGl0aW9uQgPgQQJSCmNvbmRpdGlvbnMi0wIKCUNvbmRpdGlv
bhIjCgxzdHJpbmdfdmFsdWUYASABKAlIAFILc3RyaW5nVmFsdWUSJQoNbnVtZXJpY192YWx1
ZRgGIAEoAkgAUgxudW1lcmljVmFsdWUSWgoJb3BlcmF0aW9uGAUgASgOMjcuZ29vZ2xlLmFp
LmdlbmVyYXRpdmVsYW5ndWFnZS52MWJldGEuQ29uZGl0aW9uLk9wZXJhdG9yQgPgQQJSCW9w
ZXJhdGlvbiKUAQoIT3BlcmF0b3ISGAoUT1BFUkFUT1JfVU5TUEVDSUZJRUQQABIICgRMRVNT
EAESDgoKTEVTU19FUVVBTBACEgkKBUVRVUFMEAMSEQoNR1JFQVRFUl9FUVVBTBAEEgsKB0dS
RUFURVIQBRINCglOT1RfRVFVQUwQBhIMCghJTkNMVURFUxAHEgwKCEVYQ0xVREVTEAhCBwoF
dmFsdWUi9QQKBUNodW5rEhoKBG5hbWUYASABKAlCBuBBCOBBBVIEbmFtZRJHCgRkYXRhGAIg
ASgLMi4uZ29vZ2xlLmFpLmdlbmVyYXRpdmVsYW5ndWFnZS52MWJldGEuQ2h1bmtEYXRhQgPg
QQJSBGRhdGESYQoPY3VzdG9tX21ldGFkYXRhGAMgAygLMjMuZ29vZ2xlLmFpLmdlbmVyYXRp
dmVsYW5ndWFnZS52MWJldGEuQ3VzdG9tTWV0YWRhdGFCA+BBAVIOY3VzdG9tTWV0YWRhdGES
QAoLY3JlYXRlX3RpbWUYBCABKAsyGi5nb29nbGUucHJvdG9idWYuVGltZXN0YW1wQgPgQQNS
CmNyZWF0ZVRpbWUSQAoLdXBkYXRlX3RpbWUYBSABKAsyGi5nb29nbGUucHJvdG9idWYuVGlt
ZXN0YW1wQgPgQQNSCnVwZGF0ZVRpbWUSSwoFc3RhdGUYBiABKA4yMC5nb29nbGUuYWkuZ2Vu
ZXJhdGl2ZWxhbmd1YWdlLnYxYmV0YS5DaHVuay5TdGF0ZUID4EEDUgVzdGF0ZSJgCgVTdGF0
ZRIVChFTVEFURV9VTlNQRUNJRklFRBAAEhwKGFNUQVRFX1BFTkRJTkdfUFJPQ0VTU0lORxAB
EhAKDFNUQVRFX0FDVElWRRACEhAKDFNUQVRFX0ZBSUxFRBAKOnHqQW4KJ2dlbmVyYXRpdmVs
YW5ndWFnZS5nb29nbGVhcGlzLmNvbS9DaHVuaxI0Y29ycG9yYS97Y29ycHVzfS9kb2N1bWVu
dHMve2RvY3VtZW50fS9jaHVua3Mve2NodW5rfSoGY2h1bmtzMgVjaHVuayI4CglDaHVua0Rh
dGESIwoMc3RyaW5nX3ZhbHVlGAEgASgJSABSC3N0cmluZ1ZhbHVlQgYKBGRhdGFCmgEKJ2Nv
bS5nb29nbGUuYWkuZ2VuZXJhdGl2ZWxhbmd1YWdlLnYxYmV0YUIOUmV0cmlldmVyUHJvdG9Q
AVpdY2xvdWQuZ29vZ2xlLmNvbS9nby9haS9nZW5lcmF0aXZlbGFuZ3VhZ2UvYXBpdjFiZXRh
L2dlbmVyYXRpdmVsYW5ndWFnZXBiO2dlbmVyYXRpdmVsYW5ndWFnZXBiSvNHCgcSBQ4AgwIB
CrwECgEMEgMOABIysQQgQ29weXJpZ2h0IDIwMjUgR29vZ2xlIExMQwoKIExpY2Vuc2VkIHVu
ZGVyIHRoZSBBcGFjaGUgTGljZW5zZSwgVmVyc2lvbiAyLjAgKHRoZSAiTGljZW5zZSIpOwog
eW91IG1heSBub3QgdXNlIHRoaXMgZmlsZSBleGNlcHQgaW4gY29tcGxpYW5jZSB3aXRoIHRo
ZSBMaWNlbnNlLgogWW91IG1heSBvYnRhaW4gYSBjb3B5IG9mIHRoZSBMaWNlbnNlIGF0Cgog
ICAgIGh0dHA6Ly93d3cuYXBhY2hlLm9yZy9saWNlbnNlcy9MSUNFTlNFLTIuMAoKIFVubGVz
cyByZXF1aXJlZCBieSBhcHBsaWNhYmxlIGxhdyBvciBhZ3JlZWQgdG8gaW4gd3JpdGluZywg
c29mdHdhcmUKIGRpc3RyaWJ1dGVkIHVuZGVyIHRoZSBMaWNlbnNlIGlzIGRpc3RyaWJ1dGVk
IG9uIGFuICJBUyBJUyIgQkFTSVMsCiBXSVRIT1VUIFdBUlJBTlRJRVMgT1IgQ09ORElUSU9O
UyBPRiBBTlkgS0lORCwgZWl0aGVyIGV4cHJlc3Mgb3IgaW1wbGllZC4KIFNlZSB0aGUgTGlj
ZW5zZSBmb3IgdGhlIHNwZWNpZmljIGxhbmd1YWdlIGdvdmVybmluZyBwZXJtaXNzaW9ucyBh
bmQKIGxpbWl0YXRpb25zIHVuZGVyIHRoZSBMaWNlbnNlLgoKCAoBAhIDEAAsCgkKAgMAEgMS
ACkKCQoCAwESAxMAIwoJCgIDAhIDFAApCggKAQgSAxYAdAoJCgIICxIDFgB0CggKAQgSAxcA
IgoJCgIIChIDFwAiCggKAQgSAxgALwoJCgIICBIDGAAvCggKAQgSAxkAQAoJCgIIARIDGQBA
Cl8KAgQAEgQdAD0BGlMgQSBgQ29ycHVzYCBpcyBhIGNvbGxlY3Rpb24gb2YgYERvY3VtZW50
YHMuCiBBIHByb2plY3QgY2FuIGNyZWF0ZSB1cCB0byA1IGNvcnBvcmEuCgoKCgMEAAESAx0I
DgoLCgMEAAcSBB4CIwQKDQoFBAAHnQgSBB4CIwQKnAMKBAQAAgASBCwCLwQajQMgSW1tdXRh
YmxlLiBJZGVudGlmaWVyLiBUaGUgYENvcnB1c2AgcmVzb3VyY2UgbmFtZS4gVGhlIElEIChu
YW1lIGV4Y2x1ZGluZwogdGhlICJjb3Jwb3JhLyIgcHJlZml4KSBjYW4gY29udGFpbiB1cCB0
byA0MCBjaGFyYWN0ZXJzIHRoYXQgYXJlIGxvd2VyY2FzZQogYWxwaGFudW1lcmljIG9yIGRh
c2hlcwogKC0pLiBUaGUgSUQgY2Fubm90IHN0YXJ0IG9yIGVuZCB3aXRoIGEgZGFzaC4gSWYg
dGhlIG5hbWUgaXMgZW1wdHkgb24KIGNyZWF0ZSwgYSB1bmlxdWUgbmFtZSB3aWxsIGJlIGRl
cml2ZWQgZnJvbSBgZGlzcGxheV9uYW1lYCBhbG9uZyB3aXRoIGEgMTIKIGNoYXJhY3RlciBy
YW5kb20gc3VmZml4LgogRXhhbXBsZTogYGNvcnBvcmEvbXktYXdlc29tZS1jb3Jwb3JhLTEy
M2E0NTZiNzg5Y2AKCgwKBQQAAgAFEgMsAggKDAoFBAACAAESAywJDQoMCgUEAAIAAxIDLBAR
Cg0KBQQAAgAIEgQsEi8DCg8KCAQAAgAInAgAEgMtBCwKDwoIBAACAAicCAESAy4EKwrFAQoE
BAACARIDNAJDGrcBIE9wdGlvbmFsLiBUaGUgaHVtYW4tcmVhZGFibGUgZGlzcGxheSBuYW1l
IGZvciB0aGUgYENvcnB1c2AuIFRoZSBkaXNwbGF5CiBuYW1lIG11c3QgYmUgbm8gbW9yZSB0
aGFuIDUxMiBjaGFyYWN0ZXJzIGluIGxlbmd0aCwgaW5jbHVkaW5nIHNwYWNlcy4KIEV4YW1w
bGU6ICJEb2NzIG9uIFNlbWFudGljIFJldHJpZXZlciIKCgwKBQQAAgEFEgM0AggKDAoFBAAC
AQESAzQJFQoMCgUEAAIBAxIDNBgZCgwKBQQAAgEIEgM0GkIKDwoIBAACAQicCAASAzQbQQpM
CgQEAAICEgQ3AjgyGj4gT3V0cHV0IG9ubHkuIFRoZSBUaW1lc3RhbXAgb2Ygd2hlbiB0aGUg
YENvcnB1c2Agd2FzIGNyZWF0ZWQuCgoMCgUEAAICBhIDNwIbCgwKBQQAAgIBEgM3HCcKDAoF
BAACAgMSAzcqKwoMCgUEAAICCBIDOAYxCg8KCAQAAgIInAgAEgM4BzAKUQoEBAACAxIEOwI8
MhpDIE91dHB1dCBvbmx5LiBUaGUgVGltZXN0YW1wIG9mIHdoZW4gdGhlIGBDb3JwdXNgIHdh
cyBsYXN0IHVwZGF0ZWQuCgoMCgUEAAIDBhIDOwIbCgwKBQQAAgMBEgM7HCcKDAoFBAACAwMS
AzsqKwoMCgUEAAIDCBIDPAYxCg8KCAQAAgMInAgAEgM8BzAKbQoCBAESBEEAZQEaYSBBIGBE
b2N1bWVudGAgaXMgYSBjb2xsZWN0aW9uIG9mIGBDaHVua2BzLgogQSBgQ29ycHVzYCBjYW4g
aGF2ZSBhIG1heGltdW0gb2YgMTAsMDAwIGBEb2N1bWVudGBzLgoKCgoDBAEBEgNBCBAKCwoD
BAEHEgRCAkcECg0KBQQBB50IEgRCAkcECrsDCgQEAQIAEgRPAlIEGqwDIEltbXV0YWJsZS4g
SWRlbnRpZmllci4gVGhlIGBEb2N1bWVudGAgcmVzb3VyY2UgbmFtZS4gVGhlIElEIChuYW1l
IGV4Y2x1ZGluZwogdGhlICJjb3Jwb3JhLyovZG9jdW1lbnRzLyIgcHJlZml4KSBjYW4gY29u
dGFpbiB1cCB0byA0MCBjaGFyYWN0ZXJzIHRoYXQgYXJlCiBsb3dlcmNhc2UgYWxwaGFudW1l
cmljIG9yIGRhc2hlcyAoLSkuIFRoZSBJRCBjYW5ub3Qgc3RhcnQgb3IgZW5kIHdpdGggYQog
ZGFzaC4gSWYgdGhlIG5hbWUgaXMgZW1wdHkgb24gY3JlYXRlLCBhIHVuaXF1ZSBuYW1lIHdp
bGwgYmUgZGVyaXZlZCBmcm9tCiBgZGlzcGxheV9uYW1lYCBhbG9uZyB3aXRoIGEgMTIgY2hh
cmFjdGVyIHJhbmRvbSBzdWZmaXguCiBFeGFtcGxlOiBgY29ycG9yYS97Y29ycHVzX2lkfS9k
b2N1bWVudHMvbXktYXdlc29tZS1kb2MtMTIzYTQ1NmI3ODljYAoKDAoFBAECAAUSA08CCAoM
CgUEAQIAARIDTwkNCgwKBQQBAgADEgNPEBEKDQoFBAECAAgSBE8SUgMKDwoIBAECAAicCAAS
A1AELAoPCggEAQIACJwIARIDUQQrCs0BCgQEAQIBEgNXAkMavwEgT3B0aW9uYWwuIFRoZSBo
dW1hbi1yZWFkYWJsZSBkaXNwbGF5IG5hbWUgZm9yIHRoZSBgRG9jdW1lbnRgLiBUaGUgZGlz
cGxheQogbmFtZSBtdXN0IGJlIG5vIG1vcmUgdGhhbiA1MTIgY2hhcmFjdGVycyBpbiBsZW5n
dGgsIGluY2x1ZGluZyBzcGFjZXMuCiBFeGFtcGxlOiAiU2VtYW50aWMgUmV0cmlldmVyIERv
Y3VtZW50YXRpb24iCgoMCgUEAQIBBRIDVwIICgwKBQQBAgEBEgNXCRUKDAoFBAECAQMSA1cY
GQoMCgUEAQIBCBIDVxpCCg8KCAQBAgEInAgAEgNXG0EKngEKBAQBAgISBFsCXC8ajwEgT3B0
aW9uYWwuIFVzZXIgcHJvdmlkZWQgY3VzdG9tIG1ldGFkYXRhIHN0b3JlZCBhcyBrZXktdmFs
dWUgcGFpcnMgdXNlZCBmb3IKIHF1ZXJ5aW5nLiBBIGBEb2N1bWVudGAgY2FuIGhhdmUgYSBt
YXhpbXVtIG9mIDIwIGBDdXN0b21NZXRhZGF0YWAuCgoMCgUEAQICBBIDWwIKCgwKBQQBAgIG
EgNbCxkKDAoFBAECAgESA1saKQoMCgUEAQICAxIDWywtCgwKBQQBAgIIEgNcBi4KDwoIBAEC
AgicCAASA1wHLQpTCgQEAQIDEgRfAmAyGkUgT3V0cHV0IG9ubHkuIFRoZSBUaW1lc3RhbXAg
b2Ygd2hlbiB0aGUgYERvY3VtZW50YCB3YXMgbGFzdCB1cGRhdGVkLgoKDAoFBAECAwYSA18C
GwoMCgUEAQIDARIDXxwnCgwKBQQBAgMDEgNfKisKDAoFBAECAwgSA2AGMQoPCggEAQIDCJwI
ABIDYAcwCk4KBAQBAgQSBGMCZDIaQCBPdXRwdXQgb25seS4gVGhlIFRpbWVzdGFtcCBvZiB3
aGVuIHRoZSBgRG9jdW1lbnRgIHdhcyBjcmVhdGVkLgoKDAoFBAECBAYSA2MCGwoMCgUEAQIE
ARIDYxwnCgwKBQQBAgQDEgNjKisKDAoFBAECBAgSA2QGMQoPCggEAQIECJwIABIDZAcwCkwK
AgQCEgRoAGsBGkAgVXNlciBwcm92aWRlZCBzdHJpbmcgdmFsdWVzIGFzc2lnbmVkIHRvIGEg
c2luZ2xlIG1ldGFkYXRhIGtleS4KCgoKAwQCARIDaAgSCjoKBAQCAgASA2oCHRotIFRoZSBz
dHJpbmcgdmFsdWVzIG9mIHRoZSBtZXRhZGF0YSB0byBzdG9yZS4KCgwKBQQCAgAEEgNqAgoK
DAoFBAICAAUSA2oLEQoMCgUEAgIAARIDahIYCgwKBQQCAgADEgNqGxwKPwoCBAMSBG4AfAEa
MyBVc2VyIHByb3ZpZGVkIG1ldGFkYXRhIHN0b3JlZCBhcyBrZXktdmFsdWUgcGFpcnMuCgoK
CgMEAwESA24IFgoMCgQEAwgAEgRvAngDCgwKBQQDCAABEgNvCA0KOQoEBAMCABIDcQQcGiwg
VGhlIHN0cmluZyB2YWx1ZSBvZiB0aGUgbWV0YWRhdGEgdG8gc3RvcmUuCgoMCgUEAwIABRID
cQQKCgwKBQQDAgABEgNxCxcKDAoFBAMCAAMSA3EaGwo9CgQEAwIBEgN0BCUaMCBUaGUgU3Ry
aW5nTGlzdCB2YWx1ZSBvZiB0aGUgbWV0YWRhdGEgdG8gc3RvcmUuCgoMCgUEAwIBBhIDdAQO
CgwKBQQDAgEBEgN0DyAKDAoFBAMCAQMSA3QjJAo6CgQEAwICEgN3BBwaLSBUaGUgbnVtZXJp
YyB2YWx1ZSBvZiB0aGUgbWV0YWRhdGEgdG8gc3RvcmUuCgoMCgUEAwICBRIDdwQJCgwKBQQD
AgIBEgN3ChcKDAoFBAMCAgMSA3caGwo6CgQEAwIDEgN7AjoaLSBSZXF1aXJlZC4gVGhlIGtl
eSBvZiB0aGUgbWV0YWRhdGEgdG8gc3RvcmUuCgoMCgUEAwIDBRIDewIICgwKBQQDAgMBEgN7
CQwKDAoFBAMCAwMSA3sPEAoMCgUEAwIDCBIDexE5Cg8KCAQDAgMInAgAEgN7EjgKwgIKAgQE
EgaEAQCLAQEaswIgVXNlciBwcm92aWRlZCBmaWx0ZXIgdG8gbGltaXQgcmV0cmlldmFsIGJh
c2VkIG9uIGBDaHVua2Agb3IgYERvY3VtZW50YCBsZXZlbAogbWV0YWRhdGEgdmFsdWVzLgog
RXhhbXBsZSAoZ2VucmUgPSBkcmFtYSBPUiBnZW5yZSA9IGFjdGlvbik6CiAgIGtleSA9ICJk
b2N1bWVudC5jdXN0b21fbWV0YWRhdGEuZ2VucmUiCiAgIGNvbmRpdGlvbnMgPSBbe3N0cmlu
Z192YWx1ZSA9ICJkcmFtYSIsIG9wZXJhdGlvbiA9IEVRVUFMfSwKICAgICAgICAgICAgICAg
ICB7c3RyaW5nX3ZhbHVlID0gImFjdGlvbiIsIG9wZXJhdGlvbiA9IEVRVUFMfV0KCgsKAwQE
ARIEhAEIFgo/CgQEBAIAEgSGAQI6GjEgUmVxdWlyZWQuIFRoZSBrZXkgb2YgdGhlIG1ldGFk
YXRhIHRvIGZpbHRlciBvbi4KCg0KBQQEAgAFEgSGAQIICg0KBQQEAgABEgSGAQkMCg0KBQQE
AgADEgSGAQ8QCg0KBQQEAgAIEgSGARE5ChAKCAQEAgAInAgAEgSGARI4Co0BCgQEBAIBEgSK
AQJNGn8gUmVxdWlyZWQuIFRoZSBgQ29uZGl0aW9uYHMgZm9yIHRoZSBnaXZlbiBrZXkgdGhh
dCB3aWxsIHRyaWdnZXIgdGhpcyBmaWx0ZXIuCiBNdWx0aXBsZSBgQ29uZGl0aW9uYHMgYXJl
IGpvaW5lZCBieSBsb2dpY2FsIE9Scy4KCg0KBQQEAgEEEgSKAQIKCg0KBQQEAgEGEgSKAQsU
Cg0KBQQEAgEBEgSKARUfCg0KBQQEAgEDEgSKASIjCg0KBQQEAgEIEgSKASRMChAKCAQEAgEI
nAgAEgSKASVLCjwKAgQFEgaOAQDAAQEaLiBGaWx0ZXIgY29uZGl0aW9uIGFwcGxpY2FibGUg
dG8gYSBzaW5nbGUga2V5LgoKCwoDBAUBEgSOAQgRClYKBAQFBAASBpABAq0BAxpGIERlZmlu
ZXMgdGhlIHZhbGlkIG9wZXJhdG9ycyB0aGF0IGNhbiBiZSBhcHBsaWVkIHRvIGEga2V5LXZh
bHVlIHBhaXIuCgoNCgUEBQQAARIEkAEHDwo6CgYEBQQAAgASBJIBBB0aKiBUaGUgZGVmYXVs
dCB2YWx1ZS4gVGhpcyB2YWx1ZSBpcyB1bnVzZWQuCgoPCgcEBQQAAgABEgSSAQQYCg8KBwQF
BAACAAISBJIBGxwKJwoGBAUEAAIBEgSVAQQNGhcgU3VwcG9ydGVkIGJ5IG51bWVyaWMuCgoP
CgcEBQQAAgEBEgSVAQQICg8KBwQFBAACAQISBJUBCwwKJwoGBAUEAAICEgSYAQQTGhcgU3Vw
cG9ydGVkIGJ5IG51bWVyaWMuCgoPCgcEBQQAAgIBEgSYAQQOCg8KBwQFBAACAgISBJgBERIK
MAoGBAUEAAIDEgSbAQQOGiAgU3VwcG9ydGVkIGJ5IG51bWVyaWMgJiBzdHJpbmcuCgoPCgcE
BQQAAgMBEgSbAQQJCg8KBwQFBAACAwISBJsBDA0KJwoGBAUEAAIEEgSeAQQWGhcgU3VwcG9y
dGVkIGJ5IG51bWVyaWMuCgoPCgcEBQQAAgQBEgSeAQQRCg8KBwQFBAACBAISBJ4BFBUKJwoG
BAUEAAIFEgShAQQQGhcgU3VwcG9ydGVkIGJ5IG51bWVyaWMuCgoPCgcEBQQAAgUBEgShAQQL
Cg8KBwQFBAACBQISBKEBDg8KMAoGBAUEAAIGEgSkAQQSGiAgU3VwcG9ydGVkIGJ5IG51bWVy
aWMgJiBzdHJpbmcuCgoPCgcEBQQAAgYBEgSkAQQNCg8KBwQFBAACBgISBKQBEBEKeQoGBAUE
AAIHEgSoAQQRGmkgU3VwcG9ydGVkIGJ5IHN0cmluZyBvbmx5IHdoZW4gYEN1c3RvbU1ldGFk
YXRhYCB2YWx1ZSB0eXBlIGZvciB0aGUgZ2l2ZW4KIGtleSBoYXMgYSBgc3RyaW5nX2xpc3Rf
dmFsdWVgLgoKDwoHBAUEAAIHARIEqAEEDAoPCgcEBQQAAgcCEgSoAQ8QCnkKBgQFBAACCBIE
rAEEERppIFN1cHBvcnRlZCBieSBzdHJpbmcgb25seSB3aGVuIGBDdXN0b21NZXRhZGF0YWAg
dmFsdWUgdHlwZSBmb3IgdGhlIGdpdmVuCiBrZXkgaGFzIGEgYHN0cmluZ19saXN0X3ZhbHVl
YC4KCg8KBwQFBAACCAESBKwBBAwKDwoHBAUEAAIIAhIErAEPEAqMAwoEBAUIABIGtQECuwED
GvsCIFRoZSB2YWx1ZSB0eXBlIG11c3QgYmUgY29uc2lzdGVudCB3aXRoIHRoZSB2YWx1ZSB0
eXBlIGRlZmluZWQgaW4gdGhlIGZpZWxkCiBmb3IgdGhlIGNvcnJlc3BvbmRpbmcga2V5LiBJ
ZiB0aGUgdmFsdWUgdHlwZXMgYXJlIG5vdCBjb25zaXN0ZW50LCB0aGUKIHJlc3VsdCB3aWxs
IGJlIGFuIGVtcHR5IHNldC4gV2hlbiB0aGUgYEN1c3RvbU1ldGFkYXRhYCBoYXMgYSBgU3Ry
aW5nTGlzdGAKIHZhbHVlIHR5cGUsIHRoZSBmaWx0ZXJpbmcgY29uZGl0aW9uIHNob3VsZCB1
c2UgYHN0cmluZ192YWx1ZWAgcGFpcmVkIHdpdGgKIGFuIElOQ0xVREVTL0VYQ0xVREVTIG9w
ZXJhdGlvbiwgb3RoZXJ3aXNlIHRoZSByZXN1bHQgd2lsbCBhbHNvIGJlIGFuIGVtcHR5CiBz
ZXQuCgoNCgUEBQgAARIEtQEIDQo7CgQEBQIAEgS3AQQcGi0gVGhlIHN0cmluZyB2YWx1ZSB0
byBmaWx0ZXIgdGhlIG1ldGFkYXRhIG9uLgoKDQoFBAUCAAUSBLcBBAoKDQoFBAUCAAESBLcB
CxcKDQoFBAUCAAMSBLcBGhsKPAoEBAUCARIEugEEHBouIFRoZSBudW1lcmljIHZhbHVlIHRv
IGZpbHRlciB0aGUgbWV0YWRhdGEgb24uCgoNCgUEBQIBBRIEugEECQoNCgUEBQIBARIEugEK
FwoNCgUEBQIBAxIEugEaGwphCgQEBQICEgS/AQJCGlMgUmVxdWlyZWQuIE9wZXJhdG9yIGFw
cGxpZWQgdG8gdGhlIGdpdmVuIGtleS12YWx1ZSBwYWlyIHRvIHRyaWdnZXIgdGhlCiBjb25k
aXRpb24uCgoNCgUEBQICBhIEvwECCgoNCgUEBQICARIEvwELFAoNCgUEBQICAxIEvwEXGAoN
CgUEBQICCBIEvwEZQQoQCggEBQICCJwIABIEvwEaQArMAQoCBAYSBsUBAPoBARq9ASBBIGBD
aHVua2AgaXMgYSBzdWJwYXJ0IG9mIGEgYERvY3VtZW50YCB0aGF0IGlzIHRyZWF0ZWQgYXMg
YW4gaW5kZXBlbmRlbnQgdW5pdAogZm9yIHRoZSBwdXJwb3NlcyBvZiB2ZWN0b3IgcmVwcmVz
ZW50YXRpb24gYW5kIHN0b3JhZ2UuCiBBIGBDb3JwdXNgIGNhbiBoYXZlIGEgbWF4aW11bSBv
ZiAxIG1pbGxpb24gYENodW5rYHMuCgoLCgMEBgESBMUBCA0KDQoDBAYHEgbGAQLLAQQKDwoF
BAYHnQgSBsYBAssBBAo4CgQEBgQAEgbOAQLaAQMaKCBTdGF0ZXMgZm9yIHRoZSBsaWZlY3lj
bGUgb2YgYSBgQ2h1bmtgLgoKDQoFBAYEAAESBM4BBwwKUAoGBAYEAAIAEgTQAQQaGkAgVGhl
IGRlZmF1bHQgdmFsdWUuIFRoaXMgdmFsdWUgaXMgdXNlZCBpZiB0aGUgc3RhdGUgaXMgb21p
dHRlZC4KCg8KBwQGBAACAAESBNABBBUKDwoHBAYEAAIAAhIE0AEYGQpMCgYEBgQAAgESBNMB
BCEaPCBgQ2h1bmtgIGlzIGJlaW5nIHByb2Nlc3NlZCAoZW1iZWRkaW5nIGFuZCB2ZWN0b3Ig
c3RvcmFnZSkuCgoPCgcEBgQAAgEBEgTTAQQcCg8KBwQGBAACAQISBNMBHyAKQgoGBAYEAAIC
EgTWAQQVGjIgYENodW5rYCBpcyBwcm9jZXNzZWQgYW5kIGF2YWlsYWJsZSBmb3IgcXVlcnlp
bmcuCgoPCgcEBgQAAgIBEgTWAQQQCg8KBwQGBAACAgISBNYBExQKLAoGBAYEAAIDEgTZAQQW
GhwgYENodW5rYCBmYWlsZWQgcHJvY2Vzc2luZy4KCg8KBwQGBAACAwESBNkBBBAKDwoHBAYE
AAIDAhIE2QETFQqhAwoEBAYCABIG4gEC5QEEGpADIEltbXV0YWJsZS4gSWRlbnRpZmllci4g
VGhlIGBDaHVua2AgcmVzb3VyY2UgbmFtZS4gVGhlIElEIChuYW1lIGV4Y2x1ZGluZwogdGhl
ICJjb3Jwb3JhLyovZG9jdW1lbnRzLyovY2h1bmtzLyIgcHJlZml4KSBjYW4gY29udGFpbiB1
cCB0byA0MCBjaGFyYWN0ZXJzCiB0aGF0IGFyZSBsb3dlcmNhc2UgYWxwaGFudW1lcmljIG9y
IGRhc2hlcyAoLSkuIFRoZSBJRCBjYW5ub3Qgc3RhcnQgb3IgZW5kCiB3aXRoIGEgZGFzaC4g
SWYgdGhlIG5hbWUgaXMgZW1wdHkgb24gY3JlYXRlLCBhIHJhbmRvbSAxMi1jaGFyYWN0ZXIg
dW5pcXVlCiBJRCB3aWxsIGJlIGdlbmVyYXRlZC4KIEV4YW1wbGU6IGBjb3Jwb3JhL3tjb3Jw
dXNfaWR9L2RvY3VtZW50cy97ZG9jdW1lbnRfaWR9L2NodW5rcy8xMjNhNDU2Yjc4OWNgCgoN
CgUEBgIABRIE4gECCAoNCgUEBgIAARIE4gEJDQoNCgUEBgIAAxIE4gEQEQoPCgUEBgIACBIG
4gES5QEDChAKCAQGAgAInAgAEgTjAQQsChAKCAQGAgAInAgBEgTkAQQrCoABCgQEBgIBEgTp
AQI+GnIgUmVxdWlyZWQuIFRoZSBjb250ZW50IGZvciB0aGUgYENodW5rYCwgc3VjaCBhcyB0
aGUgdGV4dCBzdHJpbmcuCiBUaGUgbWF4aW11bSBudW1iZXIgb2YgdG9rZW5zIHBlciBjaHVu
ayBpcyAyMDQzLgoKDQoFBAYCAQYSBOkBAgsKDQoFBAYCAQESBOkBDBAKDQoFBAYCAQMSBOkB
ExQKDQoFBAYCAQgSBOkBFT0KEAoIBAYCAQicCAASBOkBFjwKjQEKBAQGAgISBu0BAu4BLxp9
IE9wdGlvbmFsLiBVc2VyIHByb3ZpZGVkIGN1c3RvbSBtZXRhZGF0YSBzdG9yZWQgYXMga2V5
LXZhbHVlIHBhaXJzLgogVGhlIG1heGltdW0gbnVtYmVyIG9mIGBDdXN0b21NZXRhZGF0YWAg
cGVyIGNodW5rIGlzIDIwLgoKDQoFBAYCAgQSBO0BAgoKDQoFBAYCAgYSBO0BCxkKDQoFBAYC
AgESBO0BGikKDQoFBAYCAgMSBO0BLC0KDQoFBAYCAggSBO4BBi4KEAoIBAYCAgicCAASBO4B
By0KTQoEBAYCAxIG8QEC8gEyGj0gT3V0cHV0IG9ubHkuIFRoZSBUaW1lc3RhbXAgb2Ygd2hl
biB0aGUgYENodW5rYCB3YXMgY3JlYXRlZC4KCg0KBQQGAgMGEgTxAQIbCg0KBQQGAgMBEgTx
ARwnCg0KBQQGAgMDEgTxASorCg0KBQQGAgMIEgTyAQYxChAKCAQGAgMInAgAEgTyAQcwClIK
BAQGAgQSBvUBAvYBMhpCIE91dHB1dCBvbmx5LiBUaGUgVGltZXN0YW1wIG9mIHdoZW4gdGhl
IGBDaHVua2Agd2FzIGxhc3QgdXBkYXRlZC4KCg0KBQQGAgQGEgT1AQIbCg0KBQQGAgQBEgT1
ARwnCg0KBQQGAgQDEgT1ASorCg0KBQQGAgQIEgT2AQYxChAKCAQGAgQInAgAEgT2AQcwCjoK
BAQGAgUSBPkBAj4aLCBPdXRwdXQgb25seS4gQ3VycmVudCBzdGF0ZSBvZiB0aGUgYENodW5r
YC4KCg0KBQQGAgUGEgT5AQIHCg0KBQQGAgUBEgT5AQgNCg0KBQQGAgUDEgT5ARARCg0KBQQG
AgUIEgT5ARI9ChAKCAQGAgUInAgAEgT5ARM8CkMKAgQHEgb9AQCDAgEaNSBFeHRyYWN0ZWQg
ZGF0YSB0aGF0IHJlcHJlc2VudHMgdGhlIGBDaHVua2AgY29udGVudC4KCgsKAwQHARIE/QEI
EQoOCgQEBwgAEgb+AQKCAgMKDQoFBAcIAAESBP4BCAwKYQoEBAcCABIEgQIEHBpTIFRoZSBg
Q2h1bmtgIGNvbnRlbnQgYXMgYSBzdHJpbmcuCiBUaGUgbWF4aW11bSBudW1iZXIgb2YgdG9r
ZW5zIHBlciBjaHVuayBpcyAyMDQzLgoKDQoFBAcCAAUSBIECBAoKDQoFBAcCAAESBIECCxcK
DQoFBAcCAAMSBIECGhtiBnByb3RvMw==
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Ai::Generativelanguage::V1beta::Retriever::Corpus ===
    # Fields for Corpus
    # Field: name Type: 9 ()
    # Field: display_name Type: 9 ()
    # Field: create_time Type: 11 (.google.protobuf.Timestamp)
    # Field: update_time Type: 11 (.google.protobuf.Timestamp)

=pod

=head1 NAME

Google::Ai::Generativelanguage::V1beta::Retriever::Corpus - Compiled Protocol Buffers message class

=head1 SYNOPSIS

    use Google::Ai::Generativelanguage::V1beta::Retriever;

    my $msg = Google::Ai::Generativelanguage::V1beta::Retriever::Corpus->new(
        name => $value,
    );

=head1 FIELDS

=over 4

=item * B<name>

Type: String

=item * B<display_name>

Type: String

=item * B<create_time>

Type: Message (.google.protobuf.Timestamp)

=item * B<update_time>

Type: Message (.google.protobuf.Timestamp)

=back

=cut

# === Message: Google::Ai::Generativelanguage::V1beta::Retriever::Document ===
    # Fields for Document
    # Field: name Type: 9 ()
    # Field: display_name Type: 9 ()
    # Field: custom_metadata Type: 11 (.google.ai.generativelanguage.v1beta.CustomMetadata)
    # Field: update_time Type: 11 (.google.protobuf.Timestamp)
    # Field: create_time Type: 11 (.google.protobuf.Timestamp)

=pod

=head1 NAME

Google::Ai::Generativelanguage::V1beta::Retriever::Document - Compiled Protocol Buffers message class

=head1 SYNOPSIS

    use Google::Ai::Generativelanguage::V1beta::Retriever;

    my $msg = Google::Ai::Generativelanguage::V1beta::Retriever::Document->new(
        name => $value,
    );

=head1 FIELDS

=over 4

=item * B<name>

Type: String

=item * B<display_name>

Type: String

=item * B<custom_metadata>

Type: Message (.google.ai.generativelanguage.v1beta.CustomMetadata)

=item * B<update_time>

Type: Message (.google.protobuf.Timestamp)

=item * B<create_time>

Type: Message (.google.protobuf.Timestamp)

=back

=cut

# === Message: Google::Ai::Generativelanguage::V1beta::Retriever::StringList ===
    # Fields for StringList
    # Field: values Type: 9 ()

=pod

=head1 NAME

Google::Ai::Generativelanguage::V1beta::Retriever::StringList - Compiled Protocol Buffers message class

=head1 SYNOPSIS

    use Google::Ai::Generativelanguage::V1beta::Retriever;

    my $msg = Google::Ai::Generativelanguage::V1beta::Retriever::StringList->new(
        values => $value,
    );

=head1 FIELDS

=over 4

=item * B<values>

Type: String

=back

=cut

# === Message: Google::Ai::Generativelanguage::V1beta::Retriever::CustomMetadata ===
    # Fields for CustomMetadata
    # Field: string_value Type: 9 ()
    # Field: string_list_value Type: 11 (.google.ai.generativelanguage.v1beta.StringList)
    # Field: numeric_value Type: 2 ()
    # Field: key Type: 9 ()

=pod

=head1 NAME

Google::Ai::Generativelanguage::V1beta::Retriever::CustomMetadata - Compiled Protocol Buffers message class

=head1 SYNOPSIS

    use Google::Ai::Generativelanguage::V1beta::Retriever;

    my $msg = Google::Ai::Generativelanguage::V1beta::Retriever::CustomMetadata->new(
        string_value => $value,
    );

=head1 FIELDS

=over 4

=item * B<string_value>

Type: String

=item * B<string_list_value>

Type: Message (.google.ai.generativelanguage.v1beta.StringList)

=item * B<numeric_value>

Type: Float

=item * B<key>

Type: String

=back

=cut

# === Message: Google::Ai::Generativelanguage::V1beta::Retriever::MetadataFilter ===
    # Fields for MetadataFilter
    # Field: key Type: 9 ()
    # Field: conditions Type: 11 (.google.ai.generativelanguage.v1beta.Condition)

=pod

=head1 NAME

Google::Ai::Generativelanguage::V1beta::Retriever::MetadataFilter - Compiled Protocol Buffers message class

=head1 SYNOPSIS

    use Google::Ai::Generativelanguage::V1beta::Retriever;

    my $msg = Google::Ai::Generativelanguage::V1beta::Retriever::MetadataFilter->new(
        key => $value,
    );

=head1 FIELDS

=over 4

=item * B<key>

Type: String

=item * B<conditions>

Type: Message (.google.ai.generativelanguage.v1beta.Condition)

=back

=cut

# === Message: Google::Ai::Generativelanguage::V1beta::Retriever::Condition ===
    # Fields for Condition
    # Field: string_value Type: 9 ()
    # Field: numeric_value Type: 2 ()
    # Field: operation Type: 14 (.google.ai.generativelanguage.v1beta.Condition.Operator)

=pod

=head1 NAME

Google::Ai::Generativelanguage::V1beta::Retriever::Condition - Compiled Protocol Buffers message class

=head1 SYNOPSIS

    use Google::Ai::Generativelanguage::V1beta::Retriever;

    my $msg = Google::Ai::Generativelanguage::V1beta::Retriever::Condition->new(
        string_value => $value,
    );

=head1 FIELDS

=over 4

=item * B<string_value>

Type: String

=item * B<numeric_value>

Type: Float

=item * B<operation>

Type: Enum (.google.ai.generativelanguage.v1beta.Condition.Operator)

=back

=cut

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

=pod

=head2 Enum: Condition::Operator

Values:

=over 4

=item * C<OPERATOR_UNSPECIFIED> => 0

=item * C<LESS> => 1

=item * C<LESS_EQUAL> => 2

=item * C<EQUAL> => 3

=item * C<GREATER_EQUAL> => 4

=item * C<GREATER> => 5

=item * C<NOT_EQUAL> => 6

=item * C<INCLUDES> => 7

=item * C<EXCLUDES> => 8

=back

=cut

# === Message: Google::Ai::Generativelanguage::V1beta::Retriever::Chunk ===
    # Fields for Chunk
    # Field: name Type: 9 ()
    # Field: data Type: 11 (.google.ai.generativelanguage.v1beta.ChunkData)
    # Field: custom_metadata Type: 11 (.google.ai.generativelanguage.v1beta.CustomMetadata)
    # Field: create_time Type: 11 (.google.protobuf.Timestamp)
    # Field: update_time Type: 11 (.google.protobuf.Timestamp)
    # Field: state Type: 14 (.google.ai.generativelanguage.v1beta.Chunk.State)

=pod

=head1 NAME

Google::Ai::Generativelanguage::V1beta::Retriever::Chunk - Compiled Protocol Buffers message class

=head1 SYNOPSIS

    use Google::Ai::Generativelanguage::V1beta::Retriever;

    my $msg = Google::Ai::Generativelanguage::V1beta::Retriever::Chunk->new(
        name => $value,
    );

=head1 FIELDS

=over 4

=item * B<name>

Type: String

=item * B<data>

Type: Message (.google.ai.generativelanguage.v1beta.ChunkData)

=item * B<custom_metadata>

Type: Message (.google.ai.generativelanguage.v1beta.CustomMetadata)

=item * B<create_time>

Type: Message (.google.protobuf.Timestamp)

=item * B<update_time>

Type: Message (.google.protobuf.Timestamp)

=item * B<state>

Type: Enum (.google.ai.generativelanguage.v1beta.Chunk.State)

=back

=cut

# Enum: Chunk::State
our $Chunk_STATE_UNSPECIFIED = 0;
our $Chunk_STATE_PENDING_PROCESSING = 1;
our $Chunk_STATE_ACTIVE = 2;
our $Chunk_STATE_FAILED = 10;

=pod

=head2 Enum: Chunk::State

Values:

=over 4

=item * C<STATE_UNSPECIFIED> => 0

=item * C<STATE_PENDING_PROCESSING> => 1

=item * C<STATE_ACTIVE> => 2

=item * C<STATE_FAILED> => 10

=back

=cut

# === Message: Google::Ai::Generativelanguage::V1beta::Retriever::ChunkData ===
    # Fields for ChunkData
    # Field: string_value Type: 9 ()

=pod

=head1 NAME

Google::Ai::Generativelanguage::V1beta::Retriever::ChunkData - Compiled Protocol Buffers message class

=head1 SYNOPSIS

    use Google::Ai::Generativelanguage::V1beta::Retriever;

    my $msg = Google::Ai::Generativelanguage::V1beta::Retriever::ChunkData->new(
        string_value => $value,
    );

=head1 FIELDS

=over 4

=item * B<string_value>

Type: String

=back

=cut

1;

__END__

=head1 NAME

Google::Ai::Generativelanguage::V1beta::Retriever - Protocol Buffers schema definition

=head1 DESCRIPTION

Auto-generated Protocol Buffers schema definition class.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
