package Google::Cloud::Sql::V1::CloudSqlSslCerts;

use strict;
use warnings;

our $VERSION = '0.12';

use Protobuf::Message;
use Protobuf::DescriptorPool;
use Protobuf::Internal qw(:all);
use MIME::Base64;

BEGIN {
    eval { require Google::Api::Annotations };
    eval { require Google::Api::Client };
    eval { require Google::Api::FieldBehavior };
    eval { require Google::Cloud::Sql::V1::CloudSqlResources };
    eval { require Google::Protobuf::FieldMask };
    my $descriptor_b64 = <<'EOF';
Ci1nb29nbGUvY2xvdWQvc3FsL3YxL2Nsb3VkX3NxbF9zc2xfY2VydHMucHJvdG8SE2dvb2ds
ZS5jbG91ZC5zcWwudjEaHGdvb2dsZS9hcGkvYW5ub3RhdGlvbnMucHJvdG8aF2dvb2dsZS9h
cGkvY2xpZW50LnByb3RvGh9nb29nbGUvYXBpL2ZpZWxkX2JlaGF2aW9yLnByb3RvGi1nb29n
bGUvY2xvdWQvc3FsL3YxL2Nsb3VkX3NxbF9yZXNvdXJjZXMucHJvdG8aIGdvb2dsZS9wcm90
b2J1Zi9maWVsZF9tYXNrLnByb3RvInsKGFNxbFNzbENlcnRzRGVsZXRlUmVxdWVzdBIaCghp
bnN0YW5jZRgBIAEoCVIIaW5zdGFuY2USGAoHcHJvamVjdBgCIAEoCVIHcHJvamVjdBIpChBz
aGExX2ZpbmdlcnByaW50GAMgASgJUg9zaGExRmluZ2VycHJpbnQieAoVU3FsU3NsQ2VydHNH
ZXRSZXF1ZXN0EhoKCGluc3RhbmNlGAEgASgJUghpbnN0YW5jZRIYCgdwcm9qZWN0GAIgASgJ
Ugdwcm9qZWN0EikKEHNoYTFfZmluZ2VycHJpbnQYAyABKAlSD3NoYTFGaW5nZXJwcmludCKQ
AQoYU3FsU3NsQ2VydHNJbnNlcnRSZXF1ZXN0EhoKCGluc3RhbmNlGAEgASgJUghpbnN0YW5j
ZRIYCgdwcm9qZWN0GAIgASgJUgdwcm9qZWN0Ej4KBGJvZHkYZCABKAsyKi5nb29nbGUuY2xv
dWQuc3FsLnYxLlNzbENlcnRzSW5zZXJ0UmVxdWVzdFIEYm9keSJOChZTcWxTc2xDZXJ0c0xp
c3RSZXF1ZXN0EhoKCGluc3RhbmNlGAEgASgJUghpbnN0YW5jZRIYCgdwcm9qZWN0GAIgASgJ
Ugdwcm9qZWN0IjgKFVNzbENlcnRzSW5zZXJ0UmVxdWVzdBIfCgtjb21tb25fbmFtZRgBIAEo
CVIKY29tbW9uTmFtZSLzAQoWU3NsQ2VydHNJbnNlcnRSZXNwb25zZRISCgRraW5kGAEgASgJ
UgRraW5kEjwKCW9wZXJhdGlvbhgCIAEoCzIeLmdvb2dsZS5jbG91ZC5zcWwudjEuT3BlcmF0
aW9uUglvcGVyYXRpb24SQgoOc2VydmVyX2NhX2NlcnQYAyABKAsyHC5nb29nbGUuY2xvdWQu
c3FsLnYxLlNzbENlcnRSDHNlcnZlckNhQ2VydBJDCgtjbGllbnRfY2VydBgEIAEoCzIiLmdv
b2dsZS5jbG91ZC5zcWwudjEuU3NsQ2VydERldGFpbFIKY2xpZW50Q2VydCJeChRTc2xDZXJ0
c0xpc3RSZXNwb25zZRISCgRraW5kGAEgASgJUgRraW5kEjIKBWl0ZW1zGAIgAygLMhwuZ29v
Z2xlLmNsb3VkLnNxbC52MS5Tc2xDZXJ0UgVpdGVtcyKVAwonVXBkYXRlQ3VzdG9tZXJNYW5h
Z2VkQ2VydGlmaWNhdGVSZXF1ZXN0Eh8KCGluc3RhbmNlGAEgASgJQgPgQQJSCGluc3RhbmNl
Eh0KB3Byb2plY3QYAiABKAlCA+BBAlIHcHJvamVjdBKJAQojY3VzdG9tZXJfbWFuYWdlZF9j
ZXJ0aWZpY2F0ZV9jb25maWcYAyABKAsyNS5nb29nbGUuY2xvdWQuc3FsLnYxLkN1c3RvbWVy
TWFuYWdlZENlcnRpZmljYXRlQ29uZmlnQgPgQQJSIGN1c3RvbWVyTWFuYWdlZENlcnRpZmlj
YXRlQ29uZmlnEkAKC3VwZGF0ZV9tYXNrGAQgASgLMhouZ29vZ2xlLnByb3RvYnVmLkZpZWxk
TWFza0ID4EEBUgp1cGRhdGVNYXNrEigKDWFsbG93X21pc3NpbmcYBSABKAhCA+BBAVIMYWxs
b3dNaXNzaW5nEjIKEmNlcnRpZmljYXRlX2J1bmRsZRgGIAEoCUID4EECUhFjZXJ0aWZpY2F0
ZUJ1bmRsZSKdAQonRGVsZXRlQ3VzdG9tZXJNYW5hZ2VkQ2VydGlmaWNhdGVSZXF1ZXN0Eh8K
CGluc3RhbmNlGAEgASgJQgPgQQJSCGluc3RhbmNlEh0KB3Byb2plY3QYAiABKAlCA+BBAlIH
cHJvamVjdBIyChJjZXJ0aWZpY2F0ZV9idW5kbGUYAyABKAlCA+BBAlIRY2VydGlmaWNhdGVC
dW5kbGUiaAomTGlzdEN1c3RvbWVyTWFuYWdlZENlcnRpZmljYXRlc1JlcXVlc3QSHwoIaW5z
dGFuY2UYASABKAlCA+BBAlIIaW5zdGFuY2USHQoHcHJvamVjdBgCIAEoCUID4EECUgdwcm9q
ZWN0IqkBCidMaXN0Q3VzdG9tZXJNYW5hZ2VkQ2VydGlmaWNhdGVzUmVzcG9uc2USfgodY3Vz
dG9tZXJfbWFuYWdlZF9jZXJ0aWZpY2F0ZXMYASADKAsyNS5nb29nbGUuY2xvdWQuc3FsLnYx
LkN1c3RvbWVyTWFuYWdlZENlcnRpZmljYXRlQ29uZmlnQgPgQQJSG2N1c3RvbWVyTWFuYWdl
ZENlcnRpZmljYXRlczLvCwoSU3FsU3NsQ2VydHNTZXJ2aWNlEqgBCgZEZWxldGUSLS5nb29n
bGUuY2xvdWQuc3FsLnYxLlNxbFNzbENlcnRzRGVsZXRlUmVxdWVzdBoeLmdvb2dsZS5jbG91
ZC5zcWwudjEuT3BlcmF0aW9uIk+C0+STAkkqRy92MS9wcm9qZWN0cy97cHJvamVjdH0vaW5z
dGFuY2VzL3tpbnN0YW5jZX0vc3NsQ2VydHMve3NoYTFfZmluZ2VycHJpbnR9EqABCgNHZXQS
Ki5nb29nbGUuY2xvdWQuc3FsLnYxLlNxbFNzbENlcnRzR2V0UmVxdWVzdBocLmdvb2dsZS5j
bG91ZC5zcWwudjEuU3NsQ2VydCJPgtPkkwJJEkcvdjEvcHJvamVjdHMve3Byb2plY3R9L2lu
c3RhbmNlcy97aW5zdGFuY2V9L3NzbENlcnRzL3tzaGExX2ZpbmdlcnByaW50fRKoAQoGSW5z
ZXJ0Ei0uZ29vZ2xlLmNsb3VkLnNxbC52MS5TcWxTc2xDZXJ0c0luc2VydFJlcXVlc3QaKy5n
b29nbGUuY2xvdWQuc3FsLnYxLlNzbENlcnRzSW5zZXJ0UmVzcG9uc2UiQoLT5JMCPCI0L3Yx
L3Byb2plY3RzL3twcm9qZWN0fS9pbnN0YW5jZXMve2luc3RhbmNlfS9zc2xDZXJ0czoEYm9k
eRKcAQoETGlzdBIrLmdvb2dsZS5jbG91ZC5zcWwudjEuU3FsU3NsQ2VydHNMaXN0UmVxdWVz
dBopLmdvb2dsZS5jbG91ZC5zcWwudjEuU3NsQ2VydHNMaXN0UmVzcG9uc2UiPILT5JMCNhI0
L3YxL3Byb2plY3RzL3twcm9qZWN0fS9pbnN0YW5jZXMve2luc3RhbmNlfS9zc2xDZXJ0cxLp
AQogVXBkYXRlQ3VzdG9tZXJNYW5hZ2VkQ2VydGlmaWNhdGUSPC5nb29nbGUuY2xvdWQuc3Fs
LnYxLlVwZGF0ZUN1c3RvbWVyTWFuYWdlZENlcnRpZmljYXRlUmVxdWVzdBoeLmdvb2dsZS5j
bG91ZC5zcWwudjEuT3BlcmF0aW9uImeC0+STAmEyXC92MS9wcm9qZWN0cy97cHJvamVjdH0v
aW5zdGFuY2VzL3tpbnN0YW5jZX0vY3VzdG9tZXJNYW5hZ2VkQ2VydGlmaWNhdGVzL3tjZXJ0
aWZpY2F0ZV9idW5kbGV9OgEqEuYBCiBEZWxldGVDdXN0b21lck1hbmFnZWRDZXJ0aWZpY2F0
ZRI8Lmdvb2dsZS5jbG91ZC5zcWwudjEuRGVsZXRlQ3VzdG9tZXJNYW5hZ2VkQ2VydGlmaWNh
dGVSZXF1ZXN0Gh4uZ29vZ2xlLmNsb3VkLnNxbC52MS5PcGVyYXRpb24iZILT5JMCXipcL3Yx
L3Byb2plY3RzL3twcm9qZWN0fS9pbnN0YW5jZXMve2luc3RhbmNlfS9jdXN0b21lck1hbmFn
ZWRDZXJ0aWZpY2F0ZXMve2NlcnRpZmljYXRlX2J1bmRsZX0S7QEKH0xpc3RDdXN0b21lck1h
bmFnZWRDZXJ0aWZpY2F0ZXMSOy5nb29nbGUuY2xvdWQuc3FsLnYxLkxpc3RDdXN0b21lck1h
bmFnZWRDZXJ0aWZpY2F0ZXNSZXF1ZXN0GjwuZ29vZ2xlLmNsb3VkLnNxbC52MS5MaXN0Q3Vz
dG9tZXJNYW5hZ2VkQ2VydGlmaWNhdGVzUmVzcG9uc2UiT4LT5JMCSRJHL3YxL3Byb2plY3Rz
L3twcm9qZWN0fS9pbnN0YW5jZXMve2luc3RhbmNlfS9jdXN0b21lck1hbmFnZWRDZXJ0aWZp
Y2F0ZXMafMpBF3NxbGFkbWluLmdvb2dsZWFwaXMuY29t0kFfaHR0cHM6Ly93d3cuZ29vZ2xl
YXBpcy5jb20vYXV0aC9jbG91ZC1wbGF0Zm9ybSxodHRwczovL3d3dy5nb29nbGVhcGlzLmNv
bS9hdXRoL3NxbHNlcnZpY2UuYWRtaW5CXQoXY29tLmdvb2dsZS5jbG91ZC5zcWwudjFCFUNs
b3VkU3FsU3NsQ2VydHNQcm90b1ABWiljbG91ZC5nb29nbGUuY29tL2dvL3NxbC9hcGl2MS9z
cWxwYjtzcWxwYkqfOgoHEgUOAOYBAQq8BAoBDBIDDgASMrEEIENvcHlyaWdodCAyMDI2IEdv
b2dsZSBMTEMKCiBMaWNlbnNlZCB1bmRlciB0aGUgQXBhY2hlIExpY2Vuc2UsIFZlcnNpb24g
Mi4wICh0aGUgIkxpY2Vuc2UiKTsKIHlvdSBtYXkgbm90IHVzZSB0aGlzIGZpbGUgZXhjZXB0
IGluIGNvbXBsaWFuY2Ugd2l0aCB0aGUgTGljZW5zZS4KIFlvdSBtYXkgb2J0YWluIGEgY29w
eSBvZiB0aGUgTGljZW5zZSBhdAoKICAgICBodHRwOi8vd3d3LmFwYWNoZS5vcmcvbGljZW5z
ZXMvTElDRU5TRS0yLjAKCiBVbmxlc3MgcmVxdWlyZWQgYnkgYXBwbGljYWJsZSBsYXcgb3Ig
YWdyZWVkIHRvIGluIHdyaXRpbmcsIHNvZnR3YXJlCiBkaXN0cmlidXRlZCB1bmRlciB0aGUg
TGljZW5zZSBpcyBkaXN0cmlidXRlZCBvbiBhbiAiQVMgSVMiIEJBU0lTLAogV0lUSE9VVCBX
QVJSQU5USUVTIE9SIENPTkRJVElPTlMgT0YgQU5ZIEtJTkQsIGVpdGhlciBleHByZXNzIG9y
IGltcGxpZWQuCiBTZWUgdGhlIExpY2Vuc2UgZm9yIHRoZSBzcGVjaWZpYyBsYW5ndWFnZSBn
b3Zlcm5pbmcgcGVybWlzc2lvbnMgYW5kCiBsaW1pdGF0aW9ucyB1bmRlciB0aGUgTGljZW5z
ZS4KCggKAQISAxAAHAoJCgIDABIDEgAmCgkKAgMBEgMTACEKCQoCAwISAxQAKQoJCgIDAxID
FQA3CgkKAgMEEgMWACoKCAoBCBIDGABACgkKAggLEgMYAEAKCAoBCBIDGQAiCgkKAggKEgMZ
ACIKCAoBCBIDGgA2CgkKAggIEgMaADYKCAoBCBIDGwAwCgkKAggBEgMbADAKQgoCBgASBB4A
YQEaNiBTZXJ2aWNlIHRvIG1hbmFnZSBTU0wgY2VydHMgZm9yIENsb3VkIFNRTCBpbnN0YW5j
ZXMuCgoKCgMGAAESAx4IGgoKCgMGAAMSAx8CPwoMCgUGAAOZCBIDHwI/CgsKAwYAAxIEIAIi
OQoNCgUGAAOaCBIEIAIiOQqMAQoEBgACABIEJgIqAxp+IERlbGV0ZXMgdGhlIFNTTCBjZXJ0
aWZpY2F0ZS4gRm9yIEZpcnN0IEdlbmVyYXRpb24gaW5zdGFuY2VzLCB0aGUKIGNlcnRpZmlj
YXRlIHJlbWFpbnMgdmFsaWQgdW50aWwgdGhlIGluc3RhbmNlIGlzIHJlc3RhcnRlZC4KCgwK
BQYAAgABEgMmBgwKDAoFBgACAAISAyYNJQoMCgUGAAIAAxIDJjA5Cg0KBQYAAgAEEgQnBCkG
ChEKCQYAAgAEsMq8IhIEJwQpBgq4AQoEBgACARIELwIzAxqpASBSZXRyaWV2ZXMgYSBwYXJ0
aWN1bGFyIFNTTCBjZXJ0aWZpY2F0ZS4gIERvZXMgbm90IGluY2x1ZGUgdGhlIHByaXZhdGUg
a2V5CiAocmVxdWlyZWQgZm9yIHVzYWdlKS4gIFRoZSBwcml2YXRlIGtleSBtdXN0IGJlIHNh
dmVkIGZyb20gdGhlIHJlc3BvbnNlIHRvCiBpbml0aWFsIGNyZWF0aW9uLgoKDAoFBgACAQES
Ay8GCQoMCgUGAAIBAhIDLwofCgwKBQYAAgEDEgMvKjEKDQoFBgACAQQSBDAEMgYKEQoJBgAC
AQSwyrwiEgQwBDIGCsIBCgQGAAICEgQ4Aj0DGrMBIENyZWF0ZXMgYW4gU1NMIGNlcnRpZmlj
YXRlIGFuZCByZXR1cm5zIGl0IGFsb25nIHdpdGggdGhlIHByaXZhdGUga2V5IGFuZAogc2Vy
dmVyIGNlcnRpZmljYXRlIGF1dGhvcml0eS4gIFRoZSBuZXcgY2VydGlmaWNhdGUgd2lsbCBu
b3QgYmUgdXNhYmxlIHVudGlsCiB0aGUgaW5zdGFuY2UgaXMgcmVzdGFydGVkLgoKDAoFBgAC
AgESAzgGDAoMCgUGAAICAhIDOA0lCgwKBQYAAgIDEgM4MEYKDQoFBgACAgQSBDkEPAYKEQoJ
BgACAgSwyrwiEgQ5BDwGCksKBAYAAgMSBEACRAMaPSBMaXN0cyBhbGwgb2YgdGhlIGN1cnJl
bnQgU1NMIGNlcnRpZmljYXRlcyBmb3IgdGhlIGluc3RhbmNlLgoKDAoFBgACAwESA0AGCgoM
CgUGAAIDAhIDQAshCgwKBQYAAgMDEgNALEAKDQoFBgACAwQSBEEEQwYKEQoJBgACAwSwyrwi
EgRBBEMGCmoKBAYAAgQSBEgCTgMaXCBVcGxvYWQgYW5kIHVwZGF0ZSBjdXN0b21lciBtYW5h
Z2VkIGNlcnRpZmljYXRlIGJ1bmRsZSBmb3IgYW4gZXhpc3RpbmcgQ2xvdWQKIFNRTCBpbnN0
YW5jZS4KCgwKBQYAAgQBEgNIBiYKDAoFBgACBAISA0gnTgoMCgUGAAIEAxIDSQ8YCg0KBQYA
AgQEEgRKBE0GChEKCQYAAgQEsMq8IhIESgRNBgpfCgQGAAIFEgRSAlcDGlEgRGVsZXRlIGN1
c3RvbWVyIG1hbmFnZWQgY2VydGlmaWNhdGUgYnVuZGxlIGZvciBhbiBleGlzdGluZyBDbG91
ZCBTUUwKIGluc3RhbmNlLgoKDAoFBgACBQESA1IGJgoMCgUGAAIFAhIDUidOCgwKBQYAAgUD
EgNTDxgKDQoFBgACBQQSBFQEVgYKEQoJBgACBQSwyrwiEgRUBFYGCmIKBAYAAgYSBFsCYAMa
VCBMaXN0IGFsbCBjdXN0b21lciBtYW5hZ2VkIGNlcnRpZmljYXRlIGJ1bmRsZXMgZm9yIGFu
IGV4aXN0aW5nIENsb3VkIFNRTAogaW5zdGFuY2UuCgoMCgUGAAIGARIDWwYlCgwKBQYAAgYC
EgNbJkwKDAoFBgACBgMSA1wPNgoNCgUGAAIGBBIEXQRfBgoRCgkGAAIGBLDKvCISBF0EXwYK
CgoCBAASBGMAbAEKCgoDBAABEgNjCCAKSwoEBAACABIDZQIWGj4gQ2xvdWQgU1FMIGluc3Rh
bmNlIElELiBUaGlzIGRvZXMgbm90IGluY2x1ZGUgdGhlIHByb2plY3QgSUQuCgoMCgUEAAIA
BRIDZQIICgwKBQQAAgABEgNlCREKDAoFBAACAAMSA2UUFQpECgQEAAIBEgNoAhUaNyBQcm9q
ZWN0IElEIG9mIHRoZSBwcm9qZWN0IHRoYXQgY29udGFpbnMgdGhlIGluc3RhbmNlLgoKDAoF
BAACAQUSA2gCCAoMCgUEAAIBARIDaAkQCgwKBQQAAgEDEgNoExQKIAoEBAACAhIDawIeGhMg
U2hhMSBGaW5nZXJQcmludC4KCgwKBQQAAgIFEgNrAggKDAoFBAACAgESA2sJGQoMCgUEAAIC
AxIDaxwdCgoKAgQBEgRuAHcBCgoKAwQBARIDbggdCksKBAQBAgASA3ACFho+IENsb3VkIFNR
TCBpbnN0YW5jZSBJRC4gVGhpcyBkb2VzIG5vdCBpbmNsdWRlIHRoZSBwcm9qZWN0IElELgoK
DAoFBAECAAUSA3ACCAoMCgUEAQIAARIDcAkRCgwKBQQBAgADEgNwFBUKRAoEBAECARIDcwIV
GjcgUHJvamVjdCBJRCBvZiB0aGUgcHJvamVjdCB0aGF0IGNvbnRhaW5zIHRoZSBpbnN0YW5j
ZS4KCgwKBQQBAgEFEgNzAggKDAoFBAECAQESA3MJEAoMCgUEAQIBAxIDcxMUCiAKBAQBAgIS
A3YCHhoTIFNoYTEgRmluZ2VyUHJpbnQuCgoMCgUEAQICBRIDdgIICgwKBQQBAgIBEgN2CRkK
DAoFBAECAgMSA3YcHQoLCgIEAhIFeQCBAQEKCgoDBAIBEgN5CCAKSwoEBAICABIDewIWGj4g
Q2xvdWQgU1FMIGluc3RhbmNlIElELiBUaGlzIGRvZXMgbm90IGluY2x1ZGUgdGhlIHByb2pl
Y3QgSUQuCgoMCgUEAgIABRIDewIICgwKBQQCAgABEgN7CREKDAoFBAICAAMSA3sUFQpECgQE
AgIBEgN+AhUaNyBQcm9qZWN0IElEIG9mIHRoZSBwcm9qZWN0IHRoYXQgY29udGFpbnMgdGhl
IGluc3RhbmNlLgoKDAoFBAICAQUSA34CCAoMCgUEAgIBARIDfgkQCgwKBQQCAgEDEgN+ExQK
DAoEBAICAhIEgAECIwoNCgUEAgICBhIEgAECFwoNCgUEAgICARIEgAEYHAoNCgUEAgICAxIE
gAEfIgoMCgIEAxIGgwEAiQEBCgsKAwQDARIEgwEIHgpMCgQEAwIAEgSFAQIWGj4gQ2xvdWQg
U1FMIGluc3RhbmNlIElELiBUaGlzIGRvZXMgbm90IGluY2x1ZGUgdGhlIHByb2plY3QgSUQu
CgoNCgUEAwIABRIEhQECCAoNCgUEAwIAARIEhQEJEQoNCgUEAwIAAxIEhQEUFQpFCgQEAwIB
EgSIAQIVGjcgUHJvamVjdCBJRCBvZiB0aGUgcHJvamVjdCB0aGF0IGNvbnRhaW5zIHRoZSBp
bnN0YW5jZS4KCg0KBQQDAgEFEgSIAQIICg0KBQQDAgEBEgSIAQkQCg0KBQQDAgEDEgSIARMU
CigKAgQEEgaMAQCQAQEaGiBTc2xDZXJ0cyBpbnNlcnQgcmVxdWVzdC4KCgsKAwQEARIEjAEI
HQpsCgQEBAIAEgSPAQIZGl4gVXNlciBzdXBwbGllZCBuYW1lLiAgTXVzdCBiZSBhIGRpc3Rp
bmN0IG5hbWUgZnJvbSB0aGUgb3RoZXIgY2VydGlmaWNhdGVzCiBmb3IgdGhpcyBpbnN0YW5j
ZS4KCg0KBQQEAgAFEgSPAQIICg0KBQQEAgABEgSPAQkUCg0KBQQEAgADEgSPARcYCigKAgQF
EgaTAQChAQEaGiBTc2xDZXJ0IGluc2VydCByZXNwb25zZS4KCgsKAwQFARIEkwEIHgo0CgQE
BQIAEgSVAQISGiYgVGhpcyBpcyBhbHdheXMgYHNxbCNzc2xDZXJ0c0luc2VydGAuCgoNCgUE
BQIABRIElQECCAoNCgUEBQIAARIElQEJDQoNCgUEBQIAAxIElQEQEQpECgQEBQIBEgSYAQIa
GjYgVGhlIG9wZXJhdGlvbiB0byB0cmFjayB0aGUgc3NsIGNlcnRzIGluc2VydCByZXF1ZXN0
LgoKDQoFBAUCAQYSBJgBAgsKDQoFBAUCAQESBJgBDBUKDQoFBAUCAQMSBJgBGBkKtgEKBAQF
AgISBJ0BAh0apwEgVGhlIHNlcnZlciBDZXJ0aWZpY2F0ZSBBdXRob3JpdHkncyBjZXJ0aWZp
Y2F0ZS4gIElmIHRoaXMgaXMgbWlzc2luZyB5b3UgY2FuCiBmb3JjZSBhIG5ldyBvbmUgdG8g
YmUgZ2VuZXJhdGVkIGJ5IGNhbGxpbmcgcmVzZXRTc2xDb25maWcgbWV0aG9kIG9uCiBpbnN0
YW5jZXMgcmVzb3VyY2UuCgoNCgUEBQICBhIEnQECCQoNCgUEBQICARIEnQEKGAoNCgUEBQIC
AxIEnQEbHAo7CgQEBQIDEgSgAQIgGi0gVGhlIG5ldyBjbGllbnQgY2VydGlmaWNhdGUgYW5k
IHByaXZhdGUga2V5LgoKDQoFBAUCAwYSBKABAg8KDQoFBAUCAwESBKABEBsKDQoFBAUCAwMS
BKABHh8KJwoCBAYSBqQBAKoBARoZIFNzbENlcnRzIGxpc3QgcmVzcG9uc2UuCgoLCgMEBgES
BKQBCBwKMgoEBAYCABIEpgECEhokIFRoaXMgaXMgYWx3YXlzIGBzcWwjc3NsQ2VydHNMaXN0
YC4KCg0KBQQGAgAFEgSmAQIICg0KBQQGAgABEgSmAQkNCg0KBQQGAgADEgSmARARCj0KBAQG
AgESBKkBAh0aLyBMaXN0IG9mIGNsaWVudCBjZXJ0aWZpY2F0ZXMgZm9yIHRoZSBpbnN0YW5j
ZS4KCg0KBQQGAgEEEgSpAQIKCg0KBQQGAgEGEgSpAQsSCg0KBQQGAgEBEgSpARMYCg0KBQQG
AgEDEgSpARscClgKAgQHEgatAQDGAQEaSiBSZXF1ZXN0IG1lc3NhZ2UgZm9yIFNxbFNzbENl
cnRzU2VydmljZS5VcGRhdGVDdXN0b21lck1hbmFnZWRDZXJ0aWZpY2F0ZS4KCgsKAwQHARIE
rQEILwpWCgQEBwIAEgSvAQI/GkggUmVxdWlyZWQuIENsb3VkIFNRTCBpbnN0YW5jZSBJRC4g
VGhpcyBkb2VzIG5vdCBpbmNsdWRlIHRoZSBwcm9qZWN0IElELgoKDQoFBAcCAAUSBK8BAggK
DQoFBAcCAAESBK8BCREKDQoFBAcCAAMSBK8BFBUKDQoFBAcCAAgSBK8BFj4KEAoIBAcCAAic
CAASBK8BFz0KTwoEBAcCARIEsgECPhpBIFJlcXVpcmVkLiBQcm9qZWN0IElEIG9mIHRoZSBw
cm9qZWN0IHRoYXQgY29udGFpbnMgdGhlIGluc3RhbmNlLgoKDQoFBAcCAQUSBLIBAggKDQoF
BAcCAQESBLIBCRAKDQoFBAcCAQMSBLIBExQKDQoFBAcCAQgSBLIBFT0KEAoIBAcCAQicCAAS
BLIBFjwKYQoEBAcCAhIGtgECtwEvGlEgUmVxdWlyZWQuIFRoZSBjdXN0b21lciBtYW5hZ2Vk
IGNlcnRpZmljYXRlIGJ1bmRsZSBTU0wgY29uZmlndXJhdGlvbiB0bwogdXBkYXRlLgoKDQoF
BAcCAgYSBLYBAiIKDQoFBAcCAgESBLYBI0YKDQoFBAcCAgMSBLYBSUoKDQoFBAcCAggSBLcB
Bi4KEAoIBAcCAgicCAASBLcBBy0KPQoEBAcCAxIGugECuwEvGi0gT3B0aW9uYWwuIFRoZSBs
aXN0IG9mIGZpZWxkcyB0byBiZSB1cGRhdGVkLgoKDQoFBAcCAwYSBLoBAhsKDQoFBAcCAwES
BLoBHCcKDQoFBAcCAwMSBLoBKisKDQoFBAcCAwgSBLsBBi4KEAoIBAcCAwicCAASBLsBBy0K
6gEKBAQHAgQSBMABAkIa2wEgT3B0aW9uYWwuIElmIHNldCB0byB0cnVlLCBhbmQgdGhlIGN1
c3RvbWVyIG1hbmFnZWQgY2VydGlmaWNhdGUgYnVuZGxlCiBjb25maWd1cmF0aW9uIGlzIG5v
dCBmb3VuZCwgYSBuZXcgY3VzdG9tZXIgbWFuYWdlZCBjZXJ0aWZpY2F0ZSBidW5kbGUKIGNv
bmZpZ3VyYXRpb24gd2lsbCBiZSBjcmVhdGVkLiBJbiB0aGlzIHNpdHVhdGlvbiwgYHVwZGF0
ZV9tYXNrYCBpcyBpZ25vcmVkLgoKDQoFBAcCBAUSBMABAgYKDQoFBAcCBAESBMABBxQKDQoF
BAcCBAMSBMABFxgKDQoFBAcCBAgSBMABGUEKEAoIBAcCBAicCAASBMABGkAKtQEKBAQHAgUS
BMUBAkkapgEgUmVxdWlyZWQuIE5hbWUgdGFnIG9mIHRoZSBjdXN0b21lciBtYW5hZ2VkIGNl
cnRpZmljYXRlIGJ1bmRsZSB0byB1cGRhdGUuIEl0CiBtdXN0IHN0YXJ0IHdpdGggYSBsZXR0
ZXIsIGJlIGFscGhhbnVtZXJpYywgYW5kIGhhdmUgYSBtYXhpbXVtIGxlbmd0aCBvZiAxMAog
Y2hhcmFjdGVycy4KCg0KBQQHAgUFEgTFAQIICg0KBQQHAgUBEgTFAQkbCg0KBQQHAgUDEgTF
AR4fCg0KBQQHAgUIEgTFASBIChAKCAQHAgUInAgAEgTFASFHClgKAgQIEgbJAQDUAQEaSiBS
ZXF1ZXN0IG1lc3NhZ2UgZm9yIFNxbFNzbENlcnRzU2VydmljZS5EZWxldGVDdXN0b21lck1h
bmFnZWRDZXJ0aWZpY2F0ZS4KCgsKAwQIARIEyQEILwpWCgQECAIAEgTLAQI/GkggUmVxdWly
ZWQuIENsb3VkIFNRTCBpbnN0YW5jZSBJRC4gVGhpcyBkb2VzIG5vdCBpbmNsdWRlIHRoZSBw
cm9qZWN0IElELgoKDQoFBAgCAAUSBMsBAggKDQoFBAgCAAESBMsBCREKDQoFBAgCAAMSBMsB
FBUKDQoFBAgCAAgSBMsBFj4KEAoIBAgCAAicCAASBMsBFz0KTwoEBAgCARIEzgECPhpBIFJl
cXVpcmVkLiBQcm9qZWN0IElEIG9mIHRoZSBwcm9qZWN0IHRoYXQgY29udGFpbnMgdGhlIGlu
c3RhbmNlLgoKDQoFBAgCAQUSBM4BAggKDQoFBAgCAQESBM4BCRAKDQoFBAgCAQMSBM4BExQK
DQoFBAgCAQgSBM4BFT0KEAoIBAgCAQicCAASBM4BFjwKtQEKBAQIAgISBNMBAkkapgEgUmVx
dWlyZWQuIE5hbWUgdGFnIG9mIHRoZSBjdXN0b21lciBtYW5hZ2VkIGNlcnRpZmljYXRlIGJ1
bmRsZSB0byBkZWxldGUuIEl0CiBtdXN0IHN0YXJ0IHdpdGggYSBsZXR0ZXIsIGJlIGFscGhh
bnVtZXJpYywgYW5kIGhhdmUgYSBtYXhpbXVtIGxlbmd0aCBvZiAxMAogY2hhcmFjdGVycy4K
Cg0KBQQIAgIFEgTTAQIICg0KBQQIAgIBEgTTAQkbCg0KBQQIAgIDEgTTAR4fCg0KBQQIAgII
EgTTASBIChAKCAQIAgIInAgAEgTTASFHClcKAgQJEgbXAQDdAQEaSSBSZXF1ZXN0IG1lc3Nh
Z2UgZm9yIFNxbFNzbENlcnRzU2VydmljZS5MaXN0Q3VzdG9tZXJNYW5hZ2VkQ2VydGlmaWNh
dGVzLgoKCwoDBAkBEgTXAQguClYKBAQJAgASBNkBAj8aSCBSZXF1aXJlZC4gQ2xvdWQgU1FM
IGluc3RhbmNlIElELiBUaGlzIGRvZXMgbm90IGluY2x1ZGUgdGhlIHByb2plY3QgSUQuCgoN
CgUECQIABRIE2QECCAoNCgUECQIAARIE2QEJEQoNCgUECQIAAxIE2QEUFQoNCgUECQIACBIE
2QEWPgoQCggECQIACJwIABIE2QEXPQpPCgQECQIBEgTcAQI+GkEgUmVxdWlyZWQuIFByb2pl
Y3QgSUQgb2YgdGhlIHByb2plY3QgdGhhdCBjb250YWlucyB0aGUgaW5zdGFuY2UuCgoNCgUE
CQIBBRIE3AECCAoNCgUECQIBARIE3AEJEAoNCgUECQIBAxIE3AETFAoNCgUECQIBCBIE3AEV
PQoQCggECQIBCJwIABIE3AEWPApYCgIEChIG4AEA5gEBGkogUmVzcG9uc2UgbWVzc2FnZSBm
b3IgU3FsU3NsQ2VydHNTZXJ2aWNlLkxpc3RDdXN0b21lck1hbmFnZWRDZXJ0aWZpY2F0ZXMu
CgoLCgMECgESBOABCC8KsAEKBAQKAgASBuQBAuUBLxqfASBSZXF1aXJlZC4gTGlzdCBvZiBj
dXN0b21lciBtYW5hZ2VkIFNTTCBjb25maWd1cmF0aW9ucyBmb3IgdGhlIGluc3RhbmNlLgog
Tm90ZTogU2Vuc2l0aXZlIHByaXZhdGUga2V5cyAoZS5nLiwgUEVFUl9DTElFTlRfS0VZKSBh
cmUgcmVkYWN0ZWQgaW4gdGhpcwogcmVzcG9uc2UuCgoNCgUECgIABBIE5AECCgoNCgUECgIA
BhIE5AELKwoNCgUECgIAARIE5AEsSQoNCgUECgIAAxIE5AFMTQoNCgUECgIACBIE5QEGLgoQ
CggECgIACJwIABIE5QEHLWIGcHJvdG8z
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Sql::V1::CloudSqlSslCerts::SqlSslCertsDeleteRequest ===
    # Fields for SqlSslCertsDeleteRequest
    # Field: instance Type: 9 ()
    # Field: project Type: 9 ()
    # Field: sha1_fingerprint Type: 9 ()

=pod

=head1 NAME

Google::Cloud::Sql::V1::CloudSqlSslCerts::SqlSslCertsDeleteRequest - Compiled Protocol Buffers message class

=head1 SYNOPSIS

    use Google::Cloud::Sql::V1::CloudSqlSslCerts;

    my $msg = Google::Cloud::Sql::V1::CloudSqlSslCerts::SqlSslCertsDeleteRequest->new(
        instance => $value,
    );

=head1 FIELDS

=over 4

=item * B<instance>

Type: String

=item * B<project>

Type: String

=item * B<sha1_fingerprint>

Type: String

=back

=cut

# === Message: Google::Cloud::Sql::V1::CloudSqlSslCerts::SqlSslCertsGetRequest ===
    # Fields for SqlSslCertsGetRequest
    # Field: instance Type: 9 ()
    # Field: project Type: 9 ()
    # Field: sha1_fingerprint Type: 9 ()

=pod

=head1 NAME

Google::Cloud::Sql::V1::CloudSqlSslCerts::SqlSslCertsGetRequest - Compiled Protocol Buffers message class

=head1 SYNOPSIS

    use Google::Cloud::Sql::V1::CloudSqlSslCerts;

    my $msg = Google::Cloud::Sql::V1::CloudSqlSslCerts::SqlSslCertsGetRequest->new(
        instance => $value,
    );

=head1 FIELDS

=over 4

=item * B<instance>

Type: String

=item * B<project>

Type: String

=item * B<sha1_fingerprint>

Type: String

=back

=cut

# === Message: Google::Cloud::Sql::V1::CloudSqlSslCerts::SqlSslCertsInsertRequest ===
    # Fields for SqlSslCertsInsertRequest
    # Field: instance Type: 9 ()
    # Field: project Type: 9 ()
    # Field: body Type: 11 (.google.cloud.sql.v1.SslCertsInsertRequest)

=pod

=head1 NAME

Google::Cloud::Sql::V1::CloudSqlSslCerts::SqlSslCertsInsertRequest - Compiled Protocol Buffers message class

=head1 SYNOPSIS

    use Google::Cloud::Sql::V1::CloudSqlSslCerts;

    my $msg = Google::Cloud::Sql::V1::CloudSqlSslCerts::SqlSslCertsInsertRequest->new(
        instance => $value,
    );

=head1 FIELDS

=over 4

=item * B<instance>

Type: String

=item * B<project>

Type: String

=item * B<body>

Type: Message (.google.cloud.sql.v1.SslCertsInsertRequest)

=back

=cut

# === Message: Google::Cloud::Sql::V1::CloudSqlSslCerts::SqlSslCertsListRequest ===
    # Fields for SqlSslCertsListRequest
    # Field: instance Type: 9 ()
    # Field: project Type: 9 ()

=pod

=head1 NAME

Google::Cloud::Sql::V1::CloudSqlSslCerts::SqlSslCertsListRequest - Compiled Protocol Buffers message class

=head1 SYNOPSIS

    use Google::Cloud::Sql::V1::CloudSqlSslCerts;

    my $msg = Google::Cloud::Sql::V1::CloudSqlSslCerts::SqlSslCertsListRequest->new(
        instance => $value,
    );

=head1 FIELDS

=over 4

=item * B<instance>

Type: String

=item * B<project>

Type: String

=back

=cut

# === Message: Google::Cloud::Sql::V1::CloudSqlSslCerts::SslCertsInsertRequest ===
    # Fields for SslCertsInsertRequest
    # Field: common_name Type: 9 ()

=pod

=head1 NAME

Google::Cloud::Sql::V1::CloudSqlSslCerts::SslCertsInsertRequest - Compiled Protocol Buffers message class

=head1 SYNOPSIS

    use Google::Cloud::Sql::V1::CloudSqlSslCerts;

    my $msg = Google::Cloud::Sql::V1::CloudSqlSslCerts::SslCertsInsertRequest->new(
        common_name => $value,
    );

=head1 FIELDS

=over 4

=item * B<common_name>

Type: String

=back

=cut

# === Message: Google::Cloud::Sql::V1::CloudSqlSslCerts::SslCertsInsertResponse ===
    # Fields for SslCertsInsertResponse
    # Field: kind Type: 9 ()
    # Field: operation Type: 11 (.google.cloud.sql.v1.Operation)
    # Field: server_ca_cert Type: 11 (.google.cloud.sql.v1.SslCert)
    # Field: client_cert Type: 11 (.google.cloud.sql.v1.SslCertDetail)

=pod

=head1 NAME

Google::Cloud::Sql::V1::CloudSqlSslCerts::SslCertsInsertResponse - Compiled Protocol Buffers message class

=head1 SYNOPSIS

    use Google::Cloud::Sql::V1::CloudSqlSslCerts;

    my $msg = Google::Cloud::Sql::V1::CloudSqlSslCerts::SslCertsInsertResponse->new(
        kind => $value,
    );

=head1 FIELDS

=over 4

=item * B<kind>

Type: String

=item * B<operation>

Type: Message (.google.cloud.sql.v1.Operation)

=item * B<server_ca_cert>

Type: Message (.google.cloud.sql.v1.SslCert)

=item * B<client_cert>

Type: Message (.google.cloud.sql.v1.SslCertDetail)

=back

=cut

# === Message: Google::Cloud::Sql::V1::CloudSqlSslCerts::SslCertsListResponse ===
    # Fields for SslCertsListResponse
    # Field: kind Type: 9 ()
    # Field: items Type: 11 (.google.cloud.sql.v1.SslCert)

=pod

=head1 NAME

Google::Cloud::Sql::V1::CloudSqlSslCerts::SslCertsListResponse - Compiled Protocol Buffers message class

=head1 SYNOPSIS

    use Google::Cloud::Sql::V1::CloudSqlSslCerts;

    my $msg = Google::Cloud::Sql::V1::CloudSqlSslCerts::SslCertsListResponse->new(
        kind => $value,
    );

=head1 FIELDS

=over 4

=item * B<kind>

Type: String

=item * B<items>

Type: Message (.google.cloud.sql.v1.SslCert)

=back

=cut

# === Message: Google::Cloud::Sql::V1::CloudSqlSslCerts::UpdateCustomerManagedCertificateRequest ===
    # Fields for UpdateCustomerManagedCertificateRequest
    # Field: instance Type: 9 ()
    # Field: project Type: 9 ()
    # Field: customer_managed_certificate_config Type: 11 (.google.cloud.sql.v1.CustomerManagedCertificateConfig)
    # Field: update_mask Type: 11 (.google.protobuf.FieldMask)
    # Field: allow_missing Type: 8 ()
    # Field: certificate_bundle Type: 9 ()

=pod

=head1 NAME

Google::Cloud::Sql::V1::CloudSqlSslCerts::UpdateCustomerManagedCertificateRequest - Compiled Protocol Buffers message class

=head1 SYNOPSIS

    use Google::Cloud::Sql::V1::CloudSqlSslCerts;

    my $msg = Google::Cloud::Sql::V1::CloudSqlSslCerts::UpdateCustomerManagedCertificateRequest->new(
        instance => $value,
    );

=head1 FIELDS

=over 4

=item * B<instance>

Type: String

=item * B<project>

Type: String

=item * B<customer_managed_certificate_config>

Type: Message (.google.cloud.sql.v1.CustomerManagedCertificateConfig)

=item * B<update_mask>

Type: Message (.google.protobuf.FieldMask)

=item * B<allow_missing>

Type: Bool

=item * B<certificate_bundle>

Type: String

=back

=cut

# === Message: Google::Cloud::Sql::V1::CloudSqlSslCerts::DeleteCustomerManagedCertificateRequest ===
    # Fields for DeleteCustomerManagedCertificateRequest
    # Field: instance Type: 9 ()
    # Field: project Type: 9 ()
    # Field: certificate_bundle Type: 9 ()

=pod

=head1 NAME

Google::Cloud::Sql::V1::CloudSqlSslCerts::DeleteCustomerManagedCertificateRequest - Compiled Protocol Buffers message class

=head1 SYNOPSIS

    use Google::Cloud::Sql::V1::CloudSqlSslCerts;

    my $msg = Google::Cloud::Sql::V1::CloudSqlSslCerts::DeleteCustomerManagedCertificateRequest->new(
        instance => $value,
    );

=head1 FIELDS

=over 4

=item * B<instance>

Type: String

=item * B<project>

Type: String

=item * B<certificate_bundle>

Type: String

=back

=cut

# === Message: Google::Cloud::Sql::V1::CloudSqlSslCerts::ListCustomerManagedCertificatesRequest ===
    # Fields for ListCustomerManagedCertificatesRequest
    # Field: instance Type: 9 ()
    # Field: project Type: 9 ()

=pod

=head1 NAME

Google::Cloud::Sql::V1::CloudSqlSslCerts::ListCustomerManagedCertificatesRequest - Compiled Protocol Buffers message class

=head1 SYNOPSIS

    use Google::Cloud::Sql::V1::CloudSqlSslCerts;

    my $msg = Google::Cloud::Sql::V1::CloudSqlSslCerts::ListCustomerManagedCertificatesRequest->new(
        instance => $value,
    );

=head1 FIELDS

=over 4

=item * B<instance>

Type: String

=item * B<project>

Type: String

=back

=cut

# === Message: Google::Cloud::Sql::V1::CloudSqlSslCerts::ListCustomerManagedCertificatesResponse ===
    # Fields for ListCustomerManagedCertificatesResponse
    # Field: customer_managed_certificates Type: 11 (.google.cloud.sql.v1.CustomerManagedCertificateConfig)

=pod

=head1 NAME

Google::Cloud::Sql::V1::CloudSqlSslCerts::ListCustomerManagedCertificatesResponse - Compiled Protocol Buffers message class

=head1 SYNOPSIS

    use Google::Cloud::Sql::V1::CloudSqlSslCerts;

    my $msg = Google::Cloud::Sql::V1::CloudSqlSslCerts::ListCustomerManagedCertificatesResponse->new(
        customer_managed_certificates => $value,
    );

=head1 FIELDS

=over 4

=item * B<customer_managed_certificates>

Type: Message (.google.cloud.sql.v1.CustomerManagedCertificateConfig)

=back

=cut

# === Service Client: Google::Cloud::Sql::V1::CloudSqlSslCerts::SqlSslCertsServiceClient ===
package Google::Cloud::Sql::V1::CloudSqlSslCerts::SqlSslCertsServiceClient;

=pod

=head1 NAME

Google::Cloud::Sql::V1::CloudSqlSslCerts::SqlSslCertsServiceClient - Client stub representing the remote SqlSslCertsService service

=head1 DESCRIPTION

This class acts as a local client stub for the remote gRPC service.
It delegates call dispatching to an underlying L<Google::gRPC::Client>
instance, ensuring type-safe request parsing and response mapping.

=head1 CONFIGURATION AND ENVIRONMENT

=head2 target

The endpoint target address. Defaults to C<sql.googleapis.com:443>.

=head2 credentials

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

sub delete {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Sql::V1::CloudSqlSslCerts::SqlSslCertsDeleteRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.sql.v1.SqlSslCertsService',
        method         => 'Delete',
        request        => $req,
        response_class => 'Google::Cloud::Sql::V1::CloudSqlResources::Operation',
    });
}

sub get {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Sql::V1::CloudSqlSslCerts::SqlSslCertsGetRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.sql.v1.SqlSslCertsService',
        method         => 'Get',
        request        => $req,
        response_class => 'Google::Cloud::Sql::V1::CloudSqlResources::SslCert',
    });
}

sub insert {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Sql::V1::CloudSqlSslCerts::SqlSslCertsInsertRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.sql.v1.SqlSslCertsService',
        method         => 'Insert',
        request        => $req,
        response_class => 'Google::Cloud::Sql::V1::CloudSqlSslCerts::SslCertsInsertResponse',
    });
}

sub list {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Sql::V1::CloudSqlSslCerts::SqlSslCertsListRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.sql.v1.SqlSslCertsService',
        method         => 'List',
        request        => $req,
        response_class => 'Google::Cloud::Sql::V1::CloudSqlSslCerts::SslCertsListResponse',
    });
}

sub update_customer_managed_certificate {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Sql::V1::CloudSqlSslCerts::UpdateCustomerManagedCertificateRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.sql.v1.SqlSslCertsService',
        method         => 'UpdateCustomerManagedCertificate',
        request        => $req,
        response_class => 'Google::Cloud::Sql::V1::CloudSqlResources::Operation',
    });
}

sub delete_customer_managed_certificate {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Sql::V1::CloudSqlSslCerts::DeleteCustomerManagedCertificateRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.sql.v1.SqlSslCertsService',
        method         => 'DeleteCustomerManagedCertificate',
        request        => $req,
        response_class => 'Google::Cloud::Sql::V1::CloudSqlResources::Operation',
    });
}

sub list_customer_managed_certificates {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Sql::V1::CloudSqlSslCerts::ListCustomerManagedCertificatesRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.sql.v1.SqlSslCertsService',
        method         => 'ListCustomerManagedCertificates',
        request        => $req,
        response_class => 'Google::Cloud::Sql::V1::CloudSqlSslCerts::ListCustomerManagedCertificatesResponse',
    });
}

1;

__END__

=head1 NAME

Google::Cloud::Sql::V1::CloudSqlSslCerts - Protocol Buffers schema definition

=head1 DESCRIPTION

Auto-generated Protocol Buffers schema definition class.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
