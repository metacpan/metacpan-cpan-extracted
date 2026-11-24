package Google::Cloud::Notebooks::V2::Instance;

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
    eval { require Google::Cloud::Notebooks::V2::GceSetup };
    eval { require Google::Protobuf::Timestamp };
    my $descriptor_b64 = <<'EOF';
Cihnb29nbGUvY2xvdWQvbm90ZWJvb2tzL3YyL2luc3RhbmNlLnByb3RvEhlnb29nbGUuY2xv
dWQubm90ZWJvb2tzLnYyGh9nb29nbGUvYXBpL2ZpZWxkX2JlaGF2aW9yLnByb3RvGhlnb29n
bGUvYXBpL3Jlc291cmNlLnByb3RvGilnb29nbGUvY2xvdWQvbm90ZWJvb2tzL3YyL2djZV9z
ZXR1cC5wcm90bxofZ29vZ2xlL3Byb3RvYnVmL3RpbWVzdGFtcC5wcm90byLeBAoTVXBncmFk
ZUhpc3RvcnlFbnRyeRIfCghzbmFwc2hvdBgBIAEoCUID4EEBUghzbmFwc2hvdBIeCgh2bV9p
bWFnZRgCIAEoCUID4EEBUgd2bUltYWdlEiwKD2NvbnRhaW5lcl9pbWFnZRgDIAEoCUID4EEB
Ug5jb250YWluZXJJbWFnZRIhCglmcmFtZXdvcmsYBCABKAlCA+BBAVIJZnJhbWV3b3JrEh0K
B3ZlcnNpb24YBSABKAlCA+BBAVIHdmVyc2lvbhJPCgVzdGF0ZRgGIAEoDjI0Lmdvb2dsZS5j
bG91ZC5ub3RlYm9va3MudjIuVXBncmFkZUhpc3RvcnlFbnRyeS5TdGF0ZUID4EEDUgVzdGF0
ZRJACgtjcmVhdGVfdGltZRgHIAEoCzIaLmdvb2dsZS5wcm90b2J1Zi5UaW1lc3RhbXBCA+BB
BVIKY3JlYXRlVGltZRJSCgZhY3Rpb24YCCABKA4yNS5nb29nbGUuY2xvdWQubm90ZWJvb2tz
LnYyLlVwZ3JhZGVIaXN0b3J5RW50cnkuQWN0aW9uQgPgQQFSBmFjdGlvbhIqCg50YXJnZXRf
dmVyc2lvbhgJIAEoCUID4EEBUg10YXJnZXRWZXJzaW9uIkYKBVN0YXRlEhUKEVNUQVRFX1VO
U1BFQ0lGSUVEEAASCwoHU1RBUlRFRBABEg0KCVNVQ0NFRURFRBACEgoKBkZBSUxFRBADIjsK
BkFjdGlvbhIWChJBQ1RJT05fVU5TUEVDSUZJRUQQABILCgdVUEdSQURFEAESDAoIUk9MTEJB
Q0sQAiLJCAoISW5zdGFuY2USFwoEbmFtZRgBIAEoCUID4EEDUgRuYW1lEkcKCWdjZV9zZXR1
cBgCIAEoCzIjLmdvb2dsZS5jbG91ZC5ub3RlYm9va3MudjIuR2NlU2V0dXBCA+BBAUgAUghn
Y2VTZXR1cBIgCglwcm94eV91cmkYAyABKAlCA+BBA1IIcHJveHlVcmkSLwoPaW5zdGFuY2Vf
b3duZXJzGAQgAygJQgbgQQTgQQFSDmluc3RhbmNlT3duZXJzEh0KB2NyZWF0b3IYBSABKAlC
A+BBA1IHY3JlYXRvchI7CgVzdGF0ZRgGIAEoDjIgLmdvb2dsZS5jbG91ZC5ub3RlYm9va3Mu
djIuU3RhdGVCA+BBA1IFc3RhdGUSXAoPdXBncmFkZV9oaXN0b3J5GAcgAygLMi4uZ29vZ2xl
LmNsb3VkLm5vdGVib29rcy52Mi5VcGdyYWRlSGlzdG9yeUVudHJ5QgPgQQNSDnVwZ3JhZGVI
aXN0b3J5EhMKAmlkGAggASgJQgPgQQNSAmlkEk4KDGhlYWx0aF9zdGF0ZRgJIAEoDjImLmdv
b2dsZS5jbG91ZC5ub3RlYm9va3MudjIuSGVhbHRoU3RhdGVCA+BBA1ILaGVhbHRoU3RhdGUS
WQoLaGVhbHRoX2luZm8YCiADKAsyMy5nb29nbGUuY2xvdWQubm90ZWJvb2tzLnYyLkluc3Rh
bmNlLkhlYWx0aEluZm9FbnRyeUID4EEDUgpoZWFsdGhJbmZvEkAKC2NyZWF0ZV90aW1lGAsg
ASgLMhouZ29vZ2xlLnByb3RvYnVmLlRpbWVzdGFtcEID4EEDUgpjcmVhdGVUaW1lEkAKC3Vw
ZGF0ZV90aW1lGAwgASgLMhouZ29vZ2xlLnByb3RvYnVmLlRpbWVzdGFtcEID4EEDUgp1cGRh
dGVUaW1lEjUKFGRpc2FibGVfcHJveHlfYWNjZXNzGA0gASgIQgPgQQFSEmRpc2FibGVQcm94
eUFjY2VzcxJMCgZsYWJlbHMYDiADKAsyLy5nb29nbGUuY2xvdWQubm90ZWJvb2tzLnYyLklu
c3RhbmNlLkxhYmVsc0VudHJ5QgPgQQFSBmxhYmVscxo9Cg9IZWFsdGhJbmZvRW50cnkSEAoD
a2V5GAEgASgJUgNrZXkSFAoFdmFsdWUYAiABKAlSBXZhbHVlOgI4ARo5CgtMYWJlbHNFbnRy
eRIQCgNrZXkYASABKAlSA2tleRIUCgV2YWx1ZRgCIAEoCVIFdmFsdWU6AjgBOnnqQXYKIW5v
dGVib29rcy5nb29nbGVhcGlzLmNvbS9JbnN0YW5jZRI8cHJvamVjdHMve3Byb2plY3R9L2xv
Y2F0aW9ucy97bG9jYXRpb259L2luc3RhbmNlcy97aW5zdGFuY2V9KglpbnN0YW5jZXMyCGlu
c3RhbmNlQhAKDmluZnJhc3RydWN0dXJlKrIBCgVTdGF0ZRIVChFTVEFURV9VTlNQRUNJRklF
RBAAEgwKCFNUQVJUSU5HEAESEAoMUFJPVklTSU9OSU5HEAISCgoGQUNUSVZFEAMSDAoIU1RP
UFBJTkcQBBILCgdTVE9QUEVEEAUSCwoHREVMRVRFRBAGEg0KCVVQR1JBRElORxAHEhAKDElO
SVRJQUxJWklORxAIEg4KClNVU1BFTkRJTkcQCRINCglTVVNQRU5ERUQQCip3CgtIZWFsdGhT
dGF0ZRIcChhIRUFMVEhfU1RBVEVfVU5TUEVDSUZJRUQQABILCgdIRUFMVEhZEAESDQoJVU5I
RUFMVEhZEAISFwoTQUdFTlRfTk9UX0lOU1RBTExFRBADEhUKEUFHRU5UX05PVF9SVU5OSU5H
EARCxAEKHWNvbS5nb29nbGUuY2xvdWQubm90ZWJvb2tzLnYyQg1JbnN0YW5jZVByb3RvUAFa
O2Nsb3VkLmdvb2dsZS5jb20vZ28vbm90ZWJvb2tzL2FwaXYyL25vdGVib29rc3BiO25vdGVi
b29rc3BiqgIZR29vZ2xlLkNsb3VkLk5vdGVib29rcy5WMsoCGUdvb2dsZVxDbG91ZFxOb3Rl
Ym9va3NcVjLqAhxHb29nbGU6OkNsb3VkOjpOb3RlYm9va3M6OlYySpo6CgcSBQ4A5gEBCrwE
CgEMEgMOABIysQQgQ29weXJpZ2h0IDIwMjUgR29vZ2xlIExMQwoKIExpY2Vuc2VkIHVuZGVy
IHRoZSBBcGFjaGUgTGljZW5zZSwgVmVyc2lvbiAyLjAgKHRoZSAiTGljZW5zZSIpOwogeW91
IG1heSBub3QgdXNlIHRoaXMgZmlsZSBleGNlcHQgaW4gY29tcGxpYW5jZSB3aXRoIHRoZSBM
aWNlbnNlLgogWW91IG1heSBvYnRhaW4gYSBjb3B5IG9mIHRoZSBMaWNlbnNlIGF0CgogICAg
IGh0dHA6Ly93d3cuYXBhY2hlLm9yZy9saWNlbnNlcy9MSUNFTlNFLTIuMAoKIFVubGVzcyBy
ZXF1aXJlZCBieSBhcHBsaWNhYmxlIGxhdyBvciBhZ3JlZWQgdG8gaW4gd3JpdGluZywgc29m
dHdhcmUKIGRpc3RyaWJ1dGVkIHVuZGVyIHRoZSBMaWNlbnNlIGlzIGRpc3RyaWJ1dGVkIG9u
IGFuICJBUyBJUyIgQkFTSVMsCiBXSVRIT1VUIFdBUlJBTlRJRVMgT1IgQ09ORElUSU9OUyBP
RiBBTlkgS0lORCwgZWl0aGVyIGV4cHJlc3Mgb3IgaW1wbGllZC4KIFNlZSB0aGUgTGljZW5z
ZSBmb3IgdGhlIHNwZWNpZmljIGxhbmd1YWdlIGdvdmVybmluZyBwZXJtaXNzaW9ucyBhbmQK
IGxpbWl0YXRpb25zIHVuZGVyIHRoZSBMaWNlbnNlLgoKCAoBAhIDEAAiCgkKAgMAEgMSACkK
CQoCAwESAxMAIwoJCgIDAhIDFAAzCgkKAgMDEgMVACkKCAoBCBIDFwA2CgkKAgglEgMXADYK
CAoBCBIDGABSCgkKAggLEgMYAFIKCAoBCBIDGQAiCgkKAggKEgMZACIKCAoBCBIDGgAuCgkK
AggIEgMaAC4KCAoBCBIDGwA2CgkKAggBEgMbADYKCAoBCBIDHAA2CgkKAggpEgMcADYKCAoB
CBIDHQA1CgkKAggtEgMdADUKNAoCBAASBCAAWAEaKCBUaGUgZW50cnkgb2YgVk0gaW1hZ2Ug
dXBncmFkZSBoaXN0b3J5LgoKCgoDBAABEgMgCBsKSwoEBAAEABIEIgIuAxo9IFRoZSBkZWZp
bml0aW9uIG9mIHRoZSBzdGF0ZXMgb2YgdGhpcyB1cGdyYWRlIGhpc3RvcnkgZW50cnkuCgoM
CgUEAAQAARIDIgcMCigKBgQABAACABIDJAQaGhkgU3RhdGUgaXMgbm90IHNwZWNpZmllZC4K
Cg4KBwQABAACAAESAyQEFQoOCgcEAAQAAgACEgMkGBkKMQoGBAAEAAIBEgMnBBAaIiBUaGUg
aW5zdGFuY2UgdXBncmFkZSBpcyBzdGFydGVkLgoKDgoHBAAEAAIBARIDJwQLCg4KBwQABAAC
AQISAycODwozCgYEAAQAAgISAyoEEhokIFRoZSBpbnN0YW5jZSB1cGdyYWRlIGlzIHN1Y2Nl
ZWRlZC4KCg4KBwQABAACAgESAyoEDQoOCgcEAAQAAgICEgMqEBEKMAoGBAAEAAIDEgMtBA8a
ISBUaGUgaW5zdGFuY2UgdXBncmFkZSBpcyBmYWlsZWQuCgoOCgcEAAQAAgMBEgMtBAoKDgoH
BAAEAAIDAhIDLQ0OCksKBAQABAESBDECOgMaPSBUaGUgZGVmaW5pdGlvbiBvZiBvcGVyYXRp
b25zIG9mIHRoaXMgdXBncmFkZSBoaXN0b3J5IGVudHJ5LgoKDAoFBAAEAQESAzEHDQosCgYE
AAQBAgASAzMEGxodIE9wZXJhdGlvbiBpcyBub3Qgc3BlY2lmaWVkLgoKDgoHBAAEAQIAARID
MwQWCg4KBwQABAECAAISAzMZGgoZCgYEAAQBAgESAzYEEBoKIFVwZ3JhZGUuCgoOCgcEAAQB
AgEBEgM2BAsKDgoHBAAEAQIBAhIDNg4PChoKBgQABAECAhIDOQQRGgsgUm9sbGJhY2suCgoO
CgcEAAQBAgIBEgM5BAwKDgoHBAAEAQICAhIDOQ8QCmEKBAQAAgASAz4CPxpUIE9wdGlvbmFs
LiBUaGUgc25hcHNob3Qgb2YgdGhlIGJvb3QgZGlzayBvZiB0aGlzIG5vdGVib29rIGluc3Rh
bmNlIGJlZm9yZQogdXBncmFkZS4KCgwKBQQAAgAFEgM+AggKDAoFBAACAAESAz4JEQoMCgUE
AAIAAxIDPhQVCgwKBQQAAgAIEgM+Fj4KDwoIBAACAAicCAASAz4XPQpDCgQEAAIBEgNBAj8a
NiBPcHRpb25hbC4gVGhlIFZNIGltYWdlIGJlZm9yZSB0aGlzIGluc3RhbmNlIHVwZ3JhZGUu
CgoMCgUEAAIBBRIDQQIICgwKBQQAAgEBEgNBCREKDAoFBAACAQMSA0EUFQoMCgUEAAIBCBID
QRY+Cg8KCAQAAgEInAgAEgNBFz0KSgoEBAACAhIDRAJGGj0gT3B0aW9uYWwuIFRoZSBjb250
YWluZXIgaW1hZ2UgYmVmb3JlIHRoaXMgaW5zdGFuY2UgdXBncmFkZS4KCgwKBQQAAgIFEgNE
AggKDAoFBAACAgESA0QJGAoMCgUEAAICAxIDRBscCgwKBQQAAgIIEgNEHUUKDwoIBAACAgic
CAASA0QeRApBCgQEAAIDEgNHAkAaNCBPcHRpb25hbC4gVGhlIGZyYW1ld29yayBvZiB0aGlz
IG5vdGVib29rIGluc3RhbmNlLgoKDAoFBAACAwUSA0cCCAoMCgUEAAIDARIDRwkSCgwKBQQA
AgMDEgNHFRYKDAoFBAACAwgSA0cXPwoPCggEAAIDCJwIABIDRxg+ClIKBAQAAgQSA0oCPhpF
IE9wdGlvbmFsLiBUaGUgdmVyc2lvbiBvZiB0aGUgbm90ZWJvb2sgaW5zdGFuY2UgYmVmb3Jl
IHRoaXMgdXBncmFkZS4KCgwKBQQAAgQFEgNKAggKDAoFBAACBAESA0oJEAoMCgUEAAIEAxID
ShMUCgwKBQQAAgQIEgNKFT0KDwoIBAACBAicCAASA0oWPApNCgQEAAIFEgNNAj4aQCBPdXRw
dXQgb25seS4gVGhlIHN0YXRlIG9mIHRoaXMgaW5zdGFuY2UgdXBncmFkZSBoaXN0b3J5IGVu
dHJ5LgoKDAoFBAACBQYSA00CBwoMCgUEAAIFARIDTQgNCgwKBQQAAgUDEgNNEBEKDAoFBAAC
BQgSA00SPQoPCggEAAIFCJwIABIDTRM8ClgKBAQAAgYSBFACUTAaSiBJbW11dGFibGUuIFRo
ZSB0aW1lIHRoYXQgdGhpcyBpbnN0YW5jZSB1cGdyYWRlIGhpc3RvcnkgZW50cnkgaXMgY3Jl
YXRlZC4KCgwKBQQAAgYGEgNQAhsKDAoFBAACBgESA1AcJwoMCgUEAAIGAxIDUCorCgwKBQQA
AgYIEgNRBi8KDwoIBAACBgicCAASA1EHLgo2CgQEAAIHEgNUAj0aKSBPcHRpb25hbC4gQWN0
aW9uLiBSb2xsb2JhY2sgb3IgVXBncmFkZS4KCgwKBQQAAgcGEgNUAggKDAoFBAACBwESA1QJ
DwoMCgUEAAIHAxIDVBITCgwKBQQAAgcIEgNUFDwKDwoIBAACBwicCAASA1QVOwo1CgQEAAII
EgNXAkUaKCBPcHRpb25hbC4gVGFyZ2V0IFZNIFZlcnNpb24sIGxpa2UgbTYzLgoKDAoFBAAC
CAUSA1cCCAoMCgUEAAIIARIDVwkXCgwKBQQAAggDEgNXGhsKDAoFBAACCAgSA1ccRAoPCggE
AAIICJwIABIDVx1DCjUKAgQBEgVbAKkBARooIFRoZSBkZWZpbml0aW9uIG9mIGEgbm90ZWJv
b2sgaW5zdGFuY2UuCgoKCgMEAQESA1sIEAoLCgMEAQcSBFwCYQQKDQoFBAEHnQgSBFwCYQQK
jgEKBAQBAgASA2UCPhqAASBPdXRwdXQgb25seS4gVGhlIG5hbWUgb2YgdGhpcyBub3RlYm9v
ayBpbnN0YW5jZS4gRm9ybWF0OgogYHByb2plY3RzL3twcm9qZWN0X2lkfS9sb2NhdGlvbnMv
e2xvY2F0aW9ufS9pbnN0YW5jZXMve2luc3RhbmNlX2lkfWAKCgwKBQQBAgAFEgNlAggKDAoF
BAECAAESA2UJDQoMCgUEAQIAAxIDZRARCgwKBQQBAgAIEgNlEj0KDwoIBAECAAicCAASA2UT
PAowCgQEAQgAEgRoAmwDGiIgU2V0dXAgZm9yIHRoZSBOb3RlYm9vayBpbnN0YW5jZS4KCgwK
BQQBCAABEgNoCBYKXgoEBAECARIDawREGlEgT3B0aW9uYWwuIENvbXB1dGUgRW5naW5lIHNl
dHVwIGZvciB0aGUgbm90ZWJvb2suIFVzZXMgbm90ZWJvb2stZGVmaW5lZAogZmllbGRzLgoK
DAoFBAECAQYSA2sEDAoMCgUEAQIBARIDaw0WCgwKBQQBAgEDEgNrGRoKDAoFBAECAQgSA2sb
QwoPCggEAQIBCJwIABIDaxxCClwKBAQBAgISA3ACQxpPIE91dHB1dCBvbmx5LiBUaGUgcHJv
eHkgZW5kcG9pbnQgdGhhdCBpcyB1c2VkIHRvIGFjY2VzcyB0aGUgSnVweXRlcgogbm90ZWJv
b2suCgoMCgUEAQICBRIDcAIICgwKBQQBAgIBEgNwCRIKDAoFBAECAgMSA3AVFgoMCgUEAQIC
CBIDcBdCCg8KCAQBAgIInAgAEgNwGEEKhAIKBAQBAgMSBHgCewQa9QEgT3B0aW9uYWwuIElu
cHV0IG9ubHkuIFRoZSBvd25lciBvZiB0aGlzIGluc3RhbmNlIGFmdGVyIGNyZWF0aW9uLiBG
b3JtYXQ6CiBgYWxpYXNAZXhhbXBsZS5jb21gCgogQ3VycmVudGx5IHN1cHBvcnRzIG9uZSBv
d25lciBvbmx5LiBJZiBub3Qgc3BlY2lmaWVkLCBhbGwgb2YgdGhlIHNlcnZpY2UKIGFjY291
bnQgdXNlcnMgb2YgeW91ciBWTSBpbnN0YW5jZSdzIHNlcnZpY2UgYWNjb3VudCBjYW4gdXNl
CiB0aGUgaW5zdGFuY2UuCgoMCgUEAQIDBBIDeAIKCgwKBQQBAgMFEgN4CxEKDAoFBAECAwES
A3gSIQoMCgUEAQIDAxIDeCQlCg0KBQQBAgMIEgR4JnsDCg8KCAQBAgMInAgAEgN5BCwKDwoI
BAECAwicCAESA3oEKgpfCgQEAQIEEgN/AkEaUiBPdXRwdXQgb25seS4gRW1haWwgYWRkcmVz
cyBvZiBlbnRpdHkgdGhhdCBzZW50IG9yaWdpbmFsIENyZWF0ZUluc3RhbmNlCiByZXF1ZXN0
LgoKDAoFBAECBAUSA38CCAoMCgUEAQIEARIDfwkQCgwKBQQBAgQDEgN/ExQKDAoFBAECBAgS
A38VQAoPCggEAQIECJwIABIDfxY/CjgKBAQBAgUSBIIBAj4aKiBPdXRwdXQgb25seS4gVGhl
IHN0YXRlIG9mIHRoaXMgaW5zdGFuY2UuCgoNCgUEAQIFBhIEggECBwoNCgUEAQIFARIEggEI
DQoNCgUEAQIFAxIEggEQEQoNCgUEAQIFCBIEggESPQoQCggEAQIFCJwIABIEggETPApECgQE
AQIGEgaFAQKGATIaNCBPdXRwdXQgb25seS4gVGhlIHVwZ3JhZGUgaGlzdG9yeSBvZiB0aGlz
IGluc3RhbmNlLgoKDQoFBAECBgQSBIUBAgoKDQoFBAECBgYSBIUBCx4KDQoFBAECBgESBIUB
Hy4KDQoFBAECBgMSBIUBMTIKDQoFBAECBggSBIYBBjEKEAoIBAECBgicCAASBIYBBzAKNwoE
BAECBxIEiQECPBopIE91dHB1dCBvbmx5LiBVbmlxdWUgSUQgb2YgdGhlIHJlc291cmNlLgoK
DQoFBAECBwUSBIkBAggKDQoFBAECBwESBIkBCQsKDQoFBAECBwMSBIkBDg8KDQoFBAECBwgS
BIkBEDsKEAoIBAECBwicCAASBIkBEToKMwoEBAECCBIEjAECSxolIE91dHB1dCBvbmx5LiBJ
bnN0YW5jZSBoZWFsdGhfc3RhdGUuCgoNCgUEAQIIBhIEjAECDQoNCgUEAQIIARIEjAEOGgoN
CgUEAQIIAxIEjAEdHgoNCgUEAQIICBIEjAEfSgoQCggEAQIICJwIABIEjAEgSQqwAgoEBAEC
CRIGmAECmQEyGp8CIE91dHB1dCBvbmx5LiBBZGRpdGlvbmFsIGluZm9ybWF0aW9uIGFib3V0
IGluc3RhbmNlIGhlYWx0aC4KIEV4YW1wbGU6CgogICAgIGhlYWx0aEluZm8iOiB7CiAgICAg
ICAiZG9ja2VyX3Byb3h5X2FnZW50X3N0YXR1cyI6ICIxIiwKICAgICAgICJkb2NrZXJfc3Rh
dHVzIjogIjEiLAogICAgICAgImp1cHl0ZXJsYWJfYXBpX3N0YXR1cyI6ICItMSIsCiAgICAg
ICAianVweXRlcmxhYl9zdGF0dXMiOiAiLTEiLAogICAgICAgInVwZGF0ZWQiOiAiMjAyMC0x
MC0xOCAwOTo0MDowMy41NzM0MDkiCiAgICAgfQoKDQoFBAECCQYSBJgBAhUKDQoFBAECCQES
BJgBFiEKDQoFBAECCQMSBJgBJCYKDQoFBAECCQgSBJkBBjEKEAoIBAECCQicCAASBJkBBzAK
NgoEBAECChIGnAECnQEyGiYgT3V0cHV0IG9ubHkuIEluc3RhbmNlIGNyZWF0aW9uIHRpbWUu
CgoNCgUEAQIKBhIEnAECGwoNCgUEAQIKARIEnAEcJwoNCgUEAQIKAxIEnAEqLAoNCgUEAQIK
CBIEnQEGMQoQCggEAQIKCJwIABIEnQEHMAo0CgQEAQILEgagAQKhATIaJCBPdXRwdXQgb25s
eS4gSW5zdGFuY2UgdXBkYXRlIHRpbWUuCgoNCgUEAQILBhIEoAECGwoNCgUEAQILARIEoAEc
JwoNCgUEAQILAxIEoAEqLAoNCgUEAQILCBIEoQEGMQoQCggEAQILCJwIABIEoQEHMApaCgQE
AQIMEgSkAQJKGkwgT3B0aW9uYWwuIElmIHRydWUsIHRoZSBub3RlYm9vayBpbnN0YW5jZSB3
aWxsIG5vdCByZWdpc3RlciB3aXRoIHRoZSBwcm94eS4KCg0KBQQBAgwFEgSkAQIGCg0KBQQB
AgwBEgSkAQcbCg0KBQQBAgwDEgSkAR4gCg0KBQQBAgwIEgSkASFJChAKCAQBAgwInAgAEgSk
ASJICnYKBAQBAg0SBKgBAksaaCBPcHRpb25hbC4gTGFiZWxzIHRvIGFwcGx5IHRvIHRoaXMg
aW5zdGFuY2UuCiBUaGVzZSBjYW4gYmUgbGF0ZXIgbW9kaWZpZWQgYnkgdGhlIFVwZGF0ZUlu
c3RhbmNlIG1ldGhvZC4KCg0KBQQBAg0GEgSoAQIVCg0KBQQBAg0BEgSoARYcCg0KBQQBAg0D
EgSoAR8hCg0KBQQBAg0IEgSoASJKChAKCAQBAg0InAgAEgSoASNJCj4KAgUAEgasAQDOAQEa
MCBUaGUgZGVmaW5pdGlvbiBvZiB0aGUgc3RhdGVzIG9mIHRoaXMgaW5zdGFuY2UuCgoLCgMF
AAESBKwBBQoKJwoEBQACABIErgECGBoZIFN0YXRlIGlzIG5vdCBzcGVjaWZpZWQuCgoNCgUF
AAIAARIErgECEwoNCgUFAAIAAhIErgEWFwo7CgQFAAIBEgSxAQIPGi0gVGhlIGNvbnRyb2wg
bG9naWMgaXMgc3RhcnRpbmcgdGhlIGluc3RhbmNlLgoKDQoFBQACAQESBLEBAgoKDQoFBQAC
AQISBLEBDQ4KdQoEBQACAhIEtQECExpnIFRoZSBjb250cm9sIGxvZ2ljIGlzIGluc3RhbGxp
bmcgcmVxdWlyZWQgZnJhbWV3b3JrcyBhbmQgcmVnaXN0ZXJpbmcgdGhlCiBpbnN0YW5jZSB3
aXRoIG5vdGVib29rIHByb3h5CgoNCgUFAAICARIEtQECDgoNCgUFAAICAhIEtQEREgooCgQF
AAIDEgS4AQINGhogVGhlIGluc3RhbmNlIGlzIHJ1bm5pbmcuCgoNCgUFAAIDARIEuAECCAoN
CgUFAAIDAhIEuAELDAo7CgQFAAIEEgS7AQIPGi0gVGhlIGNvbnRyb2wgbG9naWMgaXMgc3Rv
cHBpbmcgdGhlIGluc3RhbmNlLgoKDQoFBQACBAESBLsBAgoKDQoFBQACBAISBLsBDQ4KKAoE
BQACBRIEvgECDhoaIFRoZSBpbnN0YW5jZSBpcyBzdG9wcGVkLgoKDQoFBQACBQESBL4BAgkK
DQoFBQACBQISBL4BDA0KKAoEBQACBhIEwQECDhoaIFRoZSBpbnN0YW5jZSBpcyBkZWxldGVk
LgoKDQoFBQACBgESBMEBAgkKDQoFBQACBgISBMEBDA0KKgoEBQACBxIExAECEBocIFRoZSBp
bnN0YW5jZSBpcyB1cGdyYWRpbmcuCgoNCgUFAAIHARIExAECCwoNCgUFAAIHAhIExAEODwou
CgQFAAIIEgTHAQITGiAgVGhlIGluc3RhbmNlIGlzIGJlaW5nIGNyZWF0ZWQuCgoNCgUFAAII
ARIExwECDgoNCgUFAAIIAhIExwEREgorCgQFAAIJEgTKAQIRGh0gVGhlIGluc3RhbmNlIGlz
IHN1c3BlbmRpbmcuCgoNCgUFAAIJARIEygECDAoNCgUFAAIJAhIEygEPEAoqCgQFAAIKEgTN
AQIRGhwgVGhlIGluc3RhbmNlIGlzIHN1c3BlbmRlZC4KCg0KBQUAAgoBEgTNAQILCg0KBQUA
AgoCEgTNAQ4QCioKAgUBEgbRAQDmAQEaHCBUaGUgaW5zdGFuY2UgaGVhbHRoIHN0YXRlLgoK
CwoDBQEBEgTRAQUQCjEKBAUBAgASBNMBAh8aIyBUaGUgaW5zdGFuY2Ugc3Vic3RhdGUgaXMg
dW5rbm93bi4KCg0KBQUBAgABEgTTAQIaCg0KBQUBAgACEgTTAR0eCoYBCgQFAQIBEgTYAQIO
GnggVGhlIGluc3RhbmNlIGlzIGtub3duIHRvIGJlIGluIGFuIGhlYWx0aHkgc3RhdGUKIChm
b3IgZXhhbXBsZSwgY3JpdGljYWwgZGFlbW9ucyBhcmUgcnVubmluZykKIEFwcGxpZXMgdG8g
QUNUSVZFIHN0YXRlLgoKDQoFBQECAQESBNgBAgkKDQoFBQECAQISBNgBDA0KjAEKBAUBAgIS
BN0BAhAafiBUaGUgaW5zdGFuY2UgaXMga25vd24gdG8gYmUgaW4gYW4gdW5oZWFsdGh5IHN0
YXRlCiAoZm9yIGV4YW1wbGUsIGNyaXRpY2FsIGRhZW1vbnMgYXJlIG5vdCBydW5uaW5nKQog
QXBwbGllcyB0byBBQ1RJVkUgc3RhdGUuCgoNCgUFAQICARIE3QECCwoNCgUFAQICAhIE3QEO
DwphCgQFAQIDEgThAQIaGlMgVGhlIGluc3RhbmNlIGhhcyBub3QgaW5zdGFsbGVkIGhlYWx0
aCBtb25pdG9yaW5nIGFnZW50LgogQXBwbGllcyB0byBBQ1RJVkUgc3RhdGUuCgoNCgUFAQID
ARIE4QECFQoNCgUFAQIDAhIE4QEYGQpeCgQFAQIEEgTlAQIYGlAgVGhlIGluc3RhbmNlIGhl
YWx0aCBtb25pdG9yaW5nIGFnZW50IGlzIG5vdCBydW5uaW5nLgogQXBwbGllcyB0byBBQ1RJ
VkUgc3RhdGUuCgoNCgUFAQIEARIE5QECEwoNCgUFAQIEAhIE5QEWF2IGcHJvdG8z
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Notebooks::V2::Instance::UpgradeHistoryEntry ===
    # Fields for UpgradeHistoryEntry
    # Field: snapshot Type: 9 ()
    # Field: vm_image Type: 9 ()
    # Field: container_image Type: 9 ()
    # Field: framework Type: 9 ()
    # Field: version Type: 9 ()
    # Field: state Type: 14 (.google.cloud.notebooks.v2.UpgradeHistoryEntry.State)
    # Field: create_time Type: 11 (.google.protobuf.Timestamp)
    # Field: action Type: 14 (.google.cloud.notebooks.v2.UpgradeHistoryEntry.Action)
    # Field: target_version Type: 9 ()

# Enum: UpgradeHistoryEntry::State
our $UpgradeHistoryEntry_STATE_UNSPECIFIED = 0;
our $UpgradeHistoryEntry_STARTED = 1;
our $UpgradeHistoryEntry_SUCCEEDED = 2;
our $UpgradeHistoryEntry_FAILED = 3;

# Enum: UpgradeHistoryEntry::Action
our $UpgradeHistoryEntry_ACTION_UNSPECIFIED = 0;
our $UpgradeHistoryEntry_UPGRADE = 1;
our $UpgradeHistoryEntry_ROLLBACK = 2;

# === Message: Google::Cloud::Notebooks::V2::Instance::Instance ===
    # Fields for Instance
    # Field: name Type: 9 ()
    # Field: gce_setup Type: 11 (.google.cloud.notebooks.v2.GceSetup)
    # Field: proxy_uri Type: 9 ()
    # Field: instance_owners Type: 9 ()
    # Field: creator Type: 9 ()
    # Field: state Type: 14 (.google.cloud.notebooks.v2.State)
    # Field: upgrade_history Type: 11 (.google.cloud.notebooks.v2.UpgradeHistoryEntry)
    # Field: id Type: 9 ()
    # Field: health_state Type: 14 (.google.cloud.notebooks.v2.HealthState)
    # Field: health_info Type: 11 (.google.cloud.notebooks.v2.Instance.HealthInfoEntry)
    # Field: create_time Type: 11 (.google.protobuf.Timestamp)
    # Field: update_time Type: 11 (.google.protobuf.Timestamp)
    # Field: disable_proxy_access Type: 8 ()
    # Field: labels Type: 11 (.google.cloud.notebooks.v2.Instance.LabelsEntry)

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Notebooks::V2::Instance - Compiled Protocol Buffers messages for google/cloud/notebooks/v2/instance.proto

=head1 SYNOPSIS

    use Google::Cloud::Notebooks::V2::Instance;

    my $msg = Google::Cloud::Notebooks::V2::Instance::UpgradeHistoryEntry->new({
        snapshot => $snapshot,
        vm_image => $vm_image,
        container_image => $container_image,
        framework => $framework,
    });

    # Read or update a field
    my $val = $msg->snapshot();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Notebooks::V2::Instance::UpgradeHistoryEntry->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/notebooks/v2/instance.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Notebooks::V2::Instance::UpgradeHistoryEntry

The entry of VM image upgrade history.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->snapshot() >> / C<< $msg->snapshot($value) >>

Type: C<String>

Optional. The snapshot of the boot disk of this notebook instance before
upgrade.

=item * C<< $msg->vm_image() >> / C<< $msg->vm_image($value) >>

Type: C<String>

Optional. The VM image before this instance upgrade.

=item * C<< $msg->container_image() >> / C<< $msg->container_image($value) >>

Type: C<String>

Optional. The container image before this instance upgrade.

=item * C<< $msg->framework() >> / C<< $msg->framework($value) >>

Type: C<String>

Optional. The framework of this notebook instance.

=item * C<< $msg->version() >> / C<< $msg->version($value) >>

Type: C<String>

Optional. The version of the notebook instance before this upgrade.

=item * C<< $msg->state() >> / C<< $msg->state($value) >>

Type: C<Enum> (L<Google::Cloud::Notebooks::V2::UpgradeHistoryEntry::State>)

Output only. The state of this instance upgrade history entry.

=item * C<< $msg->create_time() >> / C<< $msg->create_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Immutable. The time that this instance upgrade history entry is created.

=item * C<< $msg->action() >> / C<< $msg->action($value) >>

Type: C<Enum> (L<Google::Cloud::Notebooks::V2::UpgradeHistoryEntry::Action>)

Optional. Action. Rolloback or Upgrade.

=item * C<< $msg->target_version() >> / C<< $msg->target_version($value) >>

Type: C<String>

Optional. Target VM Version, like m63.

=back

=head3 Enum: UpgradeHistoryEntry::State

=over 4

=item * C<STATE_UNSPECIFIED> => C<0>

=item * C<STARTED> => C<1>

=item * C<SUCCEEDED> => C<2>

=item * C<FAILED> => C<3>

=back

=head3 Enum: UpgradeHistoryEntry::Action

=over 4

=item * C<ACTION_UNSPECIFIED> => C<0>

=item * C<UPGRADE> => C<1>

=item * C<ROLLBACK> => C<2>

=back

=head2 Google::Cloud::Notebooks::V2::Instance::Instance

The definition of a notebook instance.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Output only. The name of this notebook instance. Format:
`projects/{project_id}/locations/{location}/instances/{instance_id}`

=item * C<< $msg->gce_setup() >> / C<< $msg->gce_setup($value) >>

Type: C<Message> (L<Google::Cloud::Notebooks::V2::GceSetup::GceSetup>)

Optional. Compute Engine setup for the notebook. Uses notebook-defined
fields.

=item * C<< $msg->proxy_uri() >> / C<< $msg->proxy_uri($value) >>

Type: C<String>

Output only. The proxy endpoint that is used to access the Jupyter
notebook.

=item * C<< $msg->instance_owners() >> / C<< $msg->instance_owners($value) >>

Type: C<String>

Optional. Input only. The owner of this instance after creation. Format:
`alias@example.com`

Currently supports one owner only. If not specified, all of the service
account users of your VM instance's service account can use
the instance.

=item * C<< $msg->creator() >> / C<< $msg->creator($value) >>

Type: C<String>

Output only. Email address of entity that sent original CreateInstance
request.

=item * C<< $msg->state() >> / C<< $msg->state($value) >>

Type: C<Enum> (L<Google::Cloud::Notebooks::V2::State>)

Output only. The state of this instance.

=item * C<< $msg->upgrade_history() >> / C<< $msg->upgrade_history($value) >>

Type: C<Message> (L<Google::Cloud::Notebooks::V2::Instance::UpgradeHistoryEntry>)

Output only. The upgrade history of this instance.

=item * C<< $msg->id() >> / C<< $msg->id($value) >>

Type: C<String>

Output only. Unique ID of the resource.

=item * C<< $msg->health_state() >> / C<< $msg->health_state($value) >>

Type: C<Enum> (L<Google::Cloud::Notebooks::V2::HealthState>)

Output only. Instance health_state.

=item * C<< $msg->health_info() >> / C<< $msg->health_info($value) >>

Type: C<Message> (L<Google::Cloud::Notebooks::V2::Instance::Instance::HealthInfoEntry>)

Output only. Additional information about instance health.
Example:

    healthInfo": {
      "docker_proxy_agent_status": "1",
      "docker_status": "1",
      "jupyterlab_api_status": "-1",
      "jupyterlab_status": "-1",
      "updated": "2020-10-18 09:40:03.573409"
    }

=item * C<< $msg->create_time() >> / C<< $msg->create_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Output only. Instance creation time.

=item * C<< $msg->update_time() >> / C<< $msg->update_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Output only. Instance update time.

=item * C<< $msg->disable_proxy_access() >> / C<< $msg->disable_proxy_access($value) >>

Type: C<Bool>

Optional. If true, the notebook instance will not register with the proxy.

=item * C<< $msg->labels() >> / C<< $msg->labels($value) >>

Type: C<Message> (L<Google::Cloud::Notebooks::V2::Instance::Instance::LabelsEntry>)

Optional. Labels to apply to this instance.
These can be later modified by the UpdateInstance method.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Notebooks::V2::Instance::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
