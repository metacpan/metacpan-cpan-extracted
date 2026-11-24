package Google::Cloud::Baremetalsolution::V2::Network;

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
    eval { require Google::Protobuf::FieldMask };
    my $descriptor_b64 = <<'EOF';
Ci9nb29nbGUvY2xvdWQvYmFyZW1ldGFsc29sdXRpb24vdjIvbmV0d29yay5wcm90bxIhZ29v
Z2xlLmNsb3VkLmJhcmVtZXRhbHNvbHV0aW9uLnYyGh9nb29nbGUvYXBpL2ZpZWxkX2JlaGF2
aW9yLnByb3RvGhlnb29nbGUvYXBpL3Jlc291cmNlLnByb3RvGiBnb29nbGUvcHJvdG9idWYv
ZmllbGRfbWFzay5wcm90byLKCAoHTmV0d29yaxIXCgRuYW1lGAUgASgJQgPgQQNSBG5hbWUS
DgoCaWQYCiABKAlSAmlkEkMKBHR5cGUYAiABKA4yLy5nb29nbGUuY2xvdWQuYmFyZW1ldGFs
c29sdXRpb24udjIuTmV0d29yay5UeXBlUgR0eXBlEh0KCmlwX2FkZHJlc3MYAyABKAlSCWlw
QWRkcmVzcxIfCgttYWNfYWRkcmVzcxgEIAMoCVIKbWFjQWRkcmVzcxJGCgVzdGF0ZRgGIAEo
DjIwLmdvb2dsZS5jbG91ZC5iYXJlbWV0YWxzb2x1dGlvbi52Mi5OZXR3b3JrLlN0YXRlUgVz
dGF0ZRIXCgd2bGFuX2lkGAcgASgJUgZ2bGFuSWQSEgoEY2lkchgIIAEoCVIEY2lkchI4CgN2
cmYYCSABKAsyJi5nb29nbGUuY2xvdWQuYmFyZW1ldGFsc29sdXRpb24udjIuVlJGUgN2cmYS
TgoGbGFiZWxzGAsgAygLMjYuZ29vZ2xlLmNsb3VkLmJhcmVtZXRhbHNvbHV0aW9uLnYyLk5l
dHdvcmsuTGFiZWxzRW50cnlSBmxhYmVscxIjCg1zZXJ2aWNlc19jaWRyGAwgASgJUgxzZXJ2
aWNlc0NpZHISYAoMcmVzZXJ2YXRpb25zGA0gAygLMjwuZ29vZ2xlLmNsb3VkLmJhcmVtZXRh
bHNvbHV0aW9uLnYyLk5ldHdvcmtBZGRyZXNzUmVzZXJ2YXRpb25SDHJlc2VydmF0aW9ucxIV
CgNwb2QYDiABKAlCA+BBA1IDcG9kElwKDG1vdW50X3BvaW50cxgPIAMoCzI0Lmdvb2dsZS5j
bG91ZC5iYXJlbWV0YWxzb2x1dGlvbi52Mi5OZXR3b3JrTW91bnRQb2ludEID4EEEUgttb3Vu
dFBvaW50cxIwChRqdW1ib19mcmFtZXNfZW5hYmxlZBgQIAEoCFISanVtYm9GcmFtZXNFbmFi
bGVkEiIKCmdhdGV3YXlfaXAYESABKAlCA+BBA1IJZ2F0ZXdheUlwGjkKC0xhYmVsc0VudHJ5
EhAKA2tleRgBIAEoCVIDa2V5EhQKBXZhbHVlGAIgASgJUgV2YWx1ZToCOAEiNQoEVHlwZRIU
ChBUWVBFX1VOU1BFQ0lGSUVEEAASCgoGQ0xJRU5UEAESCwoHUFJJVkFURRACImMKBVN0YXRl
EhUKEVNUQVRFX1VOU1BFQ0lGSUVEEAASEAoMUFJPVklTSU9OSU5HEAESDwoLUFJPVklTSU9O
RUQQAhISCg5ERVBST1ZJU0lPTklORxADEgwKCFVQREFUSU5HEAQ6aepBZgooYmFyZW1ldGFs
c29sdXRpb24uZ29vZ2xlYXBpcy5jb20vTmV0d29yaxI6cHJvamVjdHMve3Byb2plY3R9L2xv
Y2F0aW9ucy97bG9jYXRpb259L25ldHdvcmtzL3tuZXR3b3JrfSJ1ChlOZXR3b3JrQWRkcmVz
c1Jlc2VydmF0aW9uEiMKDXN0YXJ0X2FkZHJlc3MYASABKAlSDHN0YXJ0QWRkcmVzcxIfCgtl
bmRfYWRkcmVzcxgCIAEoCVIKZW5kQWRkcmVzcxISCgRub3RlGAMgASgJUgRub3RlIu4FCgNW
UkYSEgoEbmFtZRgBIAEoCVIEbmFtZRJCCgVzdGF0ZRgFIAEoDjIsLmdvb2dsZS5jbG91ZC5i
YXJlbWV0YWxzb2x1dGlvbi52Mi5WUkYuU3RhdGVSBXN0YXRlEk8KCnFvc19wb2xpY3kYBiAB
KAsyMC5nb29nbGUuY2xvdWQuYmFyZW1ldGFsc29sdXRpb24udjIuVlJGLlFvc1BvbGljeVIJ
cW9zUG9saWN5EmAKEHZsYW5fYXR0YWNobWVudHMYByADKAsyNS5nb29nbGUuY2xvdWQuYmFy
ZW1ldGFsc29sdXRpb24udjIuVlJGLlZsYW5BdHRhY2htZW50Ug92bGFuQXR0YWNobWVudHMa
MgoJUW9zUG9saWN5EiUKDmJhbmR3aWR0aF9nYnBzGAEgASgBUg1iYW5kd2lkdGhHYnBzGuQC
Cg5WbGFuQXR0YWNobWVudBIgCgxwZWVyX3ZsYW5faWQYASABKANSCnBlZXJWbGFuSWQSFwoH
cGVlcl9pcBgCIAEoCVIGcGVlcklwEhsKCXJvdXRlcl9pcBgDIAEoCVIIcm91dGVySXASJAoL
cGFpcmluZ19rZXkYBCABKAlCA+BBBFIKcGFpcmluZ0tleRJPCgpxb3NfcG9saWN5GAUgASgL
MjAuZ29vZ2xlLmNsb3VkLmJhcmVtZXRhbHNvbHV0aW9uLnYyLlZSRi5Rb3NQb2xpY3lSCXFv
c1BvbGljeRITCgJpZBgGIAEoCUID4EEFUgJpZBJuChdpbnRlcmNvbm5lY3RfYXR0YWNobWVu
dBgHIAEoCUI14EEB+kEvCi1jb21wdXRlLmdvb2dsZWFwaXMuY29tL0ludGVyY29ubmVjdEF0
dGFjaG1lbnRSFmludGVyY29ubmVjdEF0dGFjaG1lbnQiQQoFU3RhdGUSFQoRU1RBVEVfVU5T
UEVDSUZJRUQQABIQCgxQUk9WSVNJT05JTkcQARIPCgtQUk9WSVNJT05FRBACIsEDChBMb2dp
Y2FsSW50ZXJmYWNlEokBChpsb2dpY2FsX25ldHdvcmtfaW50ZXJmYWNlcxgBIAMoCzJLLmdv
b2dsZS5jbG91ZC5iYXJlbWV0YWxzb2x1dGlvbi52Mi5Mb2dpY2FsSW50ZXJmYWNlLkxvZ2lj
YWxOZXR3b3JrSW50ZXJmYWNlUhhsb2dpY2FsTmV0d29ya0ludGVyZmFjZXMSEgoEbmFtZRgC
IAEoCVIEbmFtZRIrCg9pbnRlcmZhY2VfaW5kZXgYAyABKAVCAhgBUg5pbnRlcmZhY2VJbmRl
eBrfAQoXTG9naWNhbE5ldHdvcmtJbnRlcmZhY2USGAoHbmV0d29yaxgBIAEoCVIHbmV0d29y
axIdCgppcF9hZGRyZXNzGAIgASgJUglpcEFkZHJlc3MSJwoPZGVmYXVsdF9nYXRld2F5GAMg
ASgIUg5kZWZhdWx0R2F0ZXdheRJSCgxuZXR3b3JrX3R5cGUYBCABKA4yLy5nb29nbGUuY2xv
dWQuYmFyZW1ldGFsc29sdXRpb24udjIuTmV0d29yay5UeXBlUgtuZXR3b3JrVHlwZRIOCgJp
ZBgFIAEoCVICaWQiWQoRR2V0TmV0d29ya1JlcXVlc3QSRAoEbmFtZRgBIAEoCUIw4EEC+kEq
CihiYXJlbWV0YWxzb2x1dGlvbi5nb29nbGVhcGlzLmNvbS9OZXR3b3JrUgRuYW1lIqwBChNM
aXN0TmV0d29ya3NSZXF1ZXN0EkEKBnBhcmVudBgBIAEoCUIp4EEC+kEjCiFsb2NhdGlvbnMu
Z29vZ2xlYXBpcy5jb20vTG9jYXRpb25SBnBhcmVudBIbCglwYWdlX3NpemUYAiABKAVSCHBh
Z2VTaXplEh0KCnBhZ2VfdG9rZW4YAyABKAlSCXBhZ2VUb2tlbhIWCgZmaWx0ZXIYBCABKAlS
BmZpbHRlciKoAQoUTGlzdE5ldHdvcmtzUmVzcG9uc2USRgoIbmV0d29ya3MYASADKAsyKi5n
b29nbGUuY2xvdWQuYmFyZW1ldGFsc29sdXRpb24udjIuTmV0d29ya1IIbmV0d29ya3MSJgoP
bmV4dF9wYWdlX3Rva2VuGAIgASgJUg1uZXh0UGFnZVRva2VuEiAKC3VucmVhY2hhYmxlGAMg
AygJUgt1bnJlYWNoYWJsZSKeAQoUVXBkYXRlTmV0d29ya1JlcXVlc3QSSQoHbmV0d29yaxgB
IAEoCzIqLmdvb2dsZS5jbG91ZC5iYXJlbWV0YWxzb2x1dGlvbi52Mi5OZXR3b3JrQgPgQQJS
B25ldHdvcmsSOwoLdXBkYXRlX21hc2sYAiABKAsyGi5nb29nbGUucHJvdG9idWYuRmllbGRN
YXNrUgp1cGRhdGVNYXNrIm8KDE5ldHdvcmtVc2FnZRJECgduZXR3b3JrGAEgASgLMiouZ29v
Z2xlLmNsb3VkLmJhcmVtZXRhbHNvbHV0aW9uLnYyLk5ldHdvcmtSB25ldHdvcmsSGQoIdXNl
ZF9pcHMYAiADKAlSB3VzZWRJcHMiYAoXTGlzdE5ldHdvcmtVc2FnZVJlcXVlc3QSRQoIbG9j
YXRpb24YASABKAlCKeBBAvpBIwohbG9jYXRpb25zLmdvb2dsZWFwaXMuY29tL0xvY2F0aW9u
Ughsb2NhdGlvbiJnChhMaXN0TmV0d29ya1VzYWdlUmVzcG9uc2USSwoIbmV0d29ya3MYASAD
KAsyLy5nb29nbGUuY2xvdWQuYmFyZW1ldGFsc29sdXRpb24udjIuTmV0d29ya1VzYWdlUghu
ZXR3b3JrcyLUAQoRTmV0d29ya01vdW50UG9pbnQSSgoIaW5zdGFuY2UYASABKAlCLvpBKwop
YmFyZW1ldGFsc29sdXRpb24uZ29vZ2xlYXBpcy5jb20vSW5zdGFuY2VSCGluc3RhbmNlEisK
EWxvZ2ljYWxfaW50ZXJmYWNlGAIgASgJUhBsb2dpY2FsSW50ZXJmYWNlEicKD2RlZmF1bHRf
Z2F0ZXdheRgDIAEoCFIOZGVmYXVsdEdhdGV3YXkSHQoKaXBfYWRkcmVzcxgEIAEoCVIJaXBB
ZGRyZXNzIocBChRSZW5hbWVOZXR3b3JrUmVxdWVzdBJECgRuYW1lGAEgASgJQjDgQQL6QSoK
KGJhcmVtZXRhbHNvbHV0aW9uLmdvb2dsZWFwaXMuY29tL05ldHdvcmtSBG5hbWUSKQoObmV3
X25ldHdvcmtfaWQYAiABKAlCA+BBAlIMbmV3TmV0d29ya0lkQoUDCiVjb20uZ29vZ2xlLmNs
b3VkLmJhcmVtZXRhbHNvbHV0aW9uLnYyQgxOZXR3b3JrUHJvdG9QAVpTY2xvdWQuZ29vZ2xl
LmNvbS9nby9iYXJlbWV0YWxzb2x1dGlvbi9hcGl2Mi9iYXJlbWV0YWxzb2x1dGlvbnBiO2Jh
cmVtZXRhbHNvbHV0aW9ucGKqAiFHb29nbGUuQ2xvdWQuQmFyZU1ldGFsU29sdXRpb24uVjLK
AiFHb29nbGVcQ2xvdWRcQmFyZU1ldGFsU29sdXRpb25cVjLqAiRHb29nbGU6OkNsb3VkOjpC
YXJlTWV0YWxTb2x1dGlvbjo6VjLqQYYBCi1jb21wdXRlLmdvb2dsZWFwaXMuY29tL0ludGVy
Y29ubmVjdEF0dGFjaG1lbnQSVXByb2plY3RzL3twcm9qZWN0fS9yZWdpb25zL3tyZWdpb259
L2ludGVyY29ubmVjdEF0dGFjaG1lbnRzL3tpbnRlcmNvbm5lY3RfYXR0YWNobWVudH1KiFoK
BxIFDgDoAgEKvAQKAQwSAw4AEjKxBCBDb3B5cmlnaHQgMjAyNSBHb29nbGUgTExDCgogTGlj
ZW5zZWQgdW5kZXIgdGhlIEFwYWNoZSBMaWNlbnNlLCBWZXJzaW9uIDIuMCAodGhlICJMaWNl
bnNlIik7CiB5b3UgbWF5IG5vdCB1c2UgdGhpcyBmaWxlIGV4Y2VwdCBpbiBjb21wbGlhbmNl
IHdpdGggdGhlIExpY2Vuc2UuCiBZb3UgbWF5IG9idGFpbiBhIGNvcHkgb2YgdGhlIExpY2Vu
c2UgYXQKCiAgICAgaHR0cDovL3d3dy5hcGFjaGUub3JnL2xpY2Vuc2VzL0xJQ0VOU0UtMi4w
CgogVW5sZXNzIHJlcXVpcmVkIGJ5IGFwcGxpY2FibGUgbGF3IG9yIGFncmVlZCB0byBpbiB3
cml0aW5nLCBzb2Z0d2FyZQogZGlzdHJpYnV0ZWQgdW5kZXIgdGhlIExpY2Vuc2UgaXMgZGlz
dHJpYnV0ZWQgb24gYW4gIkFTIElTIiBCQVNJUywKIFdJVEhPVVQgV0FSUkFOVElFUyBPUiBD
T05ESVRJT05TIE9GIEFOWSBLSU5ELCBlaXRoZXIgZXhwcmVzcyBvciBpbXBsaWVkLgogU2Vl
IHRoZSBMaWNlbnNlIGZvciB0aGUgc3BlY2lmaWMgbGFuZ3VhZ2UgZ292ZXJuaW5nIHBlcm1p
c3Npb25zIGFuZAogbGltaXRhdGlvbnMgdW5kZXIgdGhlIExpY2Vuc2UuCgoICgECEgMQACoK
CQoCAwASAxIAKQoJCgIDARIDEwAjCgkKAgMCEgMUACoKCAoBCBIDFgA+CgkKAgglEgMWAD4K
CAoBCBIDFwBqCgkKAggLEgMXAGoKCAoBCBIDGAAiCgkKAggKEgMYACIKCAoBCBIDGQAtCgkK
AggIEgMZAC0KCAoBCBIDGgA+CgkKAggBEgMaAD4KCAoBCBIDGwA+CgkKAggpEgMbAD4KCAoB
CBIDHAA9CgkKAggtEgMcAD0KCQoBCBIEHQAgAgoMCgQInQgAEgQdACACChgKAgQAEgQjAH0B
GgwgQSBOZXR3b3JrLgoKCgoDBAABEgMjCA8KCwoDBAAHEgQkAicECg0KBQQAB50IEgQkAicE
Ch0KBAQABAASBCoCMwMaDyBOZXR3b3JrIHR5cGUuCgoMCgUEAAQAARIDKgcLCiMKBgQABAAC
ABIDLAQZGhQgVW5zcGVjaWZpZWQgdmFsdWUuCgoOCgcEAAQAAgABEgMsBBQKDgoHBAAEAAIA
AhIDLBcYCkgKBgQABAACARIDLwQPGjkgQ2xpZW50IG5ldHdvcmssIGEgbmV0d29yayBwZWVy
ZWQgdG8gYSBHb29nbGUgQ2xvdWQgVlBDLgoKDgoHBAAEAAIBARIDLwQKCg4KBwQABAACAQIS
Ay8NDgpZCgYEAAQAAgISAzIEEBpKIFByaXZhdGUgbmV0d29yaywgYSBuZXR3b3JrIGxvY2Fs
IHRvIHRoZSBCYXJlIE1ldGFsIFNvbHV0aW9uIGVudmlyb25tZW50LgoKDgoHBAAEAAICARID
MgQLCg4KBwQABAACAgISAzIODwo1CgQEAAQBEgQ2AkUDGicgVGhlIHBvc3NpYmxlIHN0YXRl
cyBmb3IgdGhpcyBOZXR3b3JrLgoKDAoFBAAEAQESAzYHDAo0CgYEAAQBAgASAzgEGholIFRo
ZSBOZXR3b3JrIGlzIGluIGFuIHVua25vd24gc3RhdGUuCgoOCgcEAAQBAgABEgM4BBUKDgoH
BAAEAQIAAhIDOBgZCi0KBgQABAECARIDOwQVGh4gVGhlIE5ldHdvcmsgaXMgcHJvdmlzaW9u
aW5nLgoKDgoHBAAEAQIBARIDOwQQCg4KBwQABAECAQISAzsTFAoyCgYEAAQBAgISAz4EFBoj
IFRoZSBOZXR3b3JrIGhhcyBiZWVuIHByb3Zpc2lvbmVkLgoKDgoHBAAEAQICARIDPgQPCg4K
BwQABAECAgISAz4SEwo0CgYEAAQBAgMSA0EEFxolIFRoZSBOZXR3b3JrIGlzIGJlaW5nIGRl
cHJvdmlzaW9uZWQuCgoOCgcEAAQBAgMBEgNBBBIKDgoHBAAEAQIDAhIDQRUWCi4KBgQABAEC
BBIDRAQRGh8gVGhlIE5ldHdvcmsgaXMgYmVpbmcgdXBkYXRlZC4KCg4KBwQABAECBAESA0QE
DAoOCgcEAAQBAgQCEgNEDxAKgQIKBAQAAgASA0wCPhrzASBPdXRwdXQgb25seS4gVGhlIHJl
c291cmNlIG5hbWUgb2YgdGhpcyBgTmV0d29ya2AuCiBSZXNvdXJjZSBuYW1lcyBhcmUgc2No
ZW1lbGVzcyBVUklzIHRoYXQgZm9sbG93IHRoZSBjb252ZW50aW9ucyBpbgogaHR0cHM6Ly9j
bG91ZC5nb29nbGUuY29tL2FwaXMvZGVzaWduL3Jlc291cmNlX25hbWVzLgogRm9ybWF0Ogog
YHByb2plY3RzL3twcm9qZWN0fS9sb2NhdGlvbnMve2xvY2F0aW9ufS9uZXR3b3Jrcy97bmV0
d29ya31gCgoMCgUEAAIABRIDTAIICgwKBQQAAgABEgNMCQ0KDAoFBAACAAMSA0wQEQoMCgUE
AAIACBIDTBI9Cg8KCAQAAgAInAgAEgNMEzwKSQoEBAACARIDTwIRGjwgQW4gaWRlbnRpZmll
ciBmb3IgdGhlIGBOZXR3b3JrYCwgZ2VuZXJhdGVkIGJ5IHRoZSBiYWNrZW5kLgoKDAoFBAAC
AQUSA08CCAoMCgUEAAIBARIDTwkLCgwKBQQAAgEDEgNPDhAKKAoEBAACAhIDUgIQGhsgVGhl
IHR5cGUgb2YgdGhpcyBuZXR3b3JrLgoKDAoFBAACAgYSA1ICBgoMCgUEAAICARIDUgcLCgwK
BQQAAgIDEgNSDg8KJQoEBAACAxIDVQIYGhggSVAgYWRkcmVzcyBjb25maWd1cmVkLgoKDAoF
BAACAwUSA1UCCAoMCgUEAAIDARIDVQkTCgwKBQQAAgMDEgNVFhcKKwoEBAACBBIDWAIiGh4g
TGlzdCBvZiBwaHlzaWNhbCBpbnRlcmZhY2VzLgoKDAoFBAACBAQSA1gCCgoMCgUEAAIEBRID
WAsRCgwKBQQAAgQBEgNYEh0KDAoFBAACBAMSA1ggIQohCgQEAAIFEgNbAhIaFCBUaGUgTmV0
d29yayBzdGF0ZS4KCgwKBQQAAgUGEgNbAgcKDAoFBAACBQESA1sIDQoMCgUEAAIFAxIDWxAR
CioKBAQAAgYSA14CFRodIFRoZSB2bGFuIGlkIG9mIHRoZSBOZXR3b3JrLgoKDAoFBAACBgUS
A14CCAoMCgUEAAIGARIDXgkQCgwKBQQAAgYDEgNeExQKJwoEBAACBxIDYQISGhogVGhlIGNp
ZHIgb2YgdGhlIE5ldHdvcmsuCgoMCgUEAAIHBRIDYQIICgwKBQQAAgcBEgNhCQ0KDAoFBAAC
BwMSA2EQEQonCgQEAAIIEgNkAg4aGiBUaGUgdnJmIGZvciB0aGUgTmV0d29yay4KCgwKBQQA
AggGEgNkAgUKDAoFBAACCAESA2QGCQoMCgUEAAIIAxIDZAwNCikKBAQAAgkSA2cCIhocIExh
YmVscyBhcyBrZXkgdmFsdWUgcGFpcnMuCgoMCgUEAAIJBhIDZwIVCgwKBQQAAgkBEgNnFhwK
DAoFBAACCQMSA2cfIQo9CgQEAAIKEgNqAhwaMCBJUCByYW5nZSBmb3IgcmVzZXJ2ZWQgZm9y
IHNlcnZpY2VzIChlLmcuIE5GUykuCgoMCgUEAAIKBRIDagIICgwKBQQAAgoBEgNqCRYKDAoF
BAACCgMSA2oZGwrNAQoEBAACCxIDbwI3Gr8BIExpc3Qgb2YgSVAgYWRkcmVzcyByZXNlcnZh
dGlvbnMgaW4gdGhpcyBuZXR3b3JrLgogV2hlbiB1cGRhdGluZyB0aGlzIGZpZWxkLCBhbiBl
cnJvciB3aWxsIGJlIGdlbmVyYXRlZCBpZiBhIHJlc2VydmF0aW9uCiBjb25mbGljdHMgd2l0
aCBhbiBJUCBhZGRyZXNzIGFscmVhZHkgYWxsb2NhdGVkIHRvIGEgcGh5c2ljYWwgc2VydmVy
LgoKDAoFBAACCwQSA28CCgoMCgUEAAILBhIDbwskCgwKBQQAAgsBEgNvJTEKDAoFBAACCwMS
A280NgolCgQEAAIMEgNyAj4aGCBPdXRwdXQgb25seS4gUG9kIG5hbWUuCgoMCgUEAAIMBRID
cgIICgwKBQQAAgwBEgNyCQwKDAoFBAACDAMSA3IPEQoMCgUEAAIMCBIDchI9Cg8KCAQAAgwI
nAgAEgNyEzwKSgoEBAACDRIEdQJ2MRo8IElucHV0IG9ubHkuIExpc3Qgb2YgbW91bnQgcG9p
bnRzIHRvIGF0dGFjaCB0aGUgbmV0d29yayB0by4KCgwKBQQAAg0EEgN1AgoKDAoFBAACDQYS
A3ULHAoMCgUEAAINARIDdR0pCgwKBQQAAg0DEgN1LC4KDAoFBAACDQgSA3YGMAoPCggEAAIN
CJwIABIDdgcvCkIKBAQAAg4SA3kCIRo1IFdoZXRoZXIgbmV0d29yayB1c2VzIHN0YW5kYXJk
IGZyYW1lcyBvciBqdW1ibyBvbmVzLgoKDAoFBAACDgUSA3kCBgoMCgUEAAIOARIDeQcbCgwK
BQQAAg4DEgN5HiAKLwoEBAACDxIDfAJFGiIgT3V0cHV0IG9ubHkuIEdhdGV3YXkgaXAgYWRk
cmVzcy4KCgwKBQQAAg8FEgN8AggKDAoFBAACDwESA3wJEwoMCgUEAAIPAxIDfBYYCgwKBQQA
Ag8IEgN8GUQKDwoIBAACDwicCAASA3waQwpECgIEARIGgAEAjQEBGjYgQSByZXNlcnZhdGlv
biBvZiBvbmUgb3IgbW9yZSBhZGRyZXNzZXMgaW4gYSBuZXR3b3JrLgoKCwoDBAEBEgSAAQgh
CngKBAQBAgASBIMBAhsaaiBUaGUgZmlyc3QgYWRkcmVzcyBvZiB0aGlzIHJlc2VydmF0aW9u
IGJsb2NrLgogTXVzdCBiZSBzcGVjaWZpZWQgYXMgYSBzaW5nbGUgSVB2NCBhZGRyZXNzLCBl
LmcuIDEwLjEuMi4yLgoKDQoFBAECAAUSBIMBAggKDQoFBAECAAESBIMBCRYKDQoFBAECAAMS
BIMBGRoK8gEKBAQBAgESBIkBAhka4wEgVGhlIGxhc3QgYWRkcmVzcyBvZiB0aGlzIHJlc2Vy
dmF0aW9uIGJsb2NrLCBpbmNsdXNpdmUuIEkuZS4sIGZvciBjYXNlcyB3aGVuCiByZXNlcnZh
dGlvbnMgYXJlIG9ubHkgc2luZ2xlIGFkZHJlc3NlcywgZW5kX2FkZHJlc3MgYW5kIHN0YXJ0
X2FkZHJlc3Mgd2lsbAogYmUgdGhlIHNhbWUuCiBNdXN0IGJlIHNwZWNpZmllZCBhcyBhIHNp
bmdsZSBJUHY0IGFkZHJlc3MsIGUuZy4gMTAuMS4yLjIuCgoNCgUEAQIBBRIEiQECCAoNCgUE
AQIBARIEiQEJFAoNCgUEAQIBAxIEiQEXGApOCgQEAQICEgSMAQISGkAgQSBub3RlIGFib3V0
IHRoaXMgcmVzZXJ2YXRpb24sIGludGVuZGVkIGZvciBodW1hbiBjb25zdW1wdGlvbi4KCg0K
BQQBAgIFEgSMAQIICg0KBQQBAgIBEgSMAQkNCg0KBQQBAgIDEgSMARARCh4KAgQCEgaQAQDQ
AQEaECBBIG5ldHdvcmsgVlJGLgoKCwoDBAIBEgSQAQgLCjMKBAQCBAASBpIBApsBAxojIFRo
ZSBwb3NzaWJsZSBzdGF0ZXMgZm9yIHRoaXMgVlJGLgoKDQoFBAIEAAESBJIBBwwKKAoGBAIE
AAIAEgSUAQQaGhggVGhlIHVuc3BlY2lmaWVkIHN0YXRlLgoKDwoHBAIEAAIAARIElAEEFQoP
CgcEAgQAAgACEgSUARgZCioKBgQCBAACARIElwEEFRoaIFRoZSB2cmYgaXMgcHJvdmlzaW9u
aW5nLgoKDwoHBAIEAAIBARIElwEEEAoPCgcEAgQAAgECEgSXARMUCikKBgQCBAACAhIEmgEE
FBoZIFRoZSB2cmYgaXMgcHJvdmlzaW9uZWQuCgoPCgcEAgQAAgIBEgSaAQQPCg8KBwQCBAAC
AgISBJoBEhMKKAoEBAIDABIGngECoQEDGhggUU9TIHBvbGljeSBwYXJhbWV0ZXJzLgoKDQoF
BAIDAAESBJ4BChMKRQoGBAIDAAIAEgSgAQQeGjUgVGhlIGJhbmR3aWR0aCBwZXJtaXR0ZWQg
YnkgdGhlIFFPUyBwb2xpY3ksIGluIGdicHMuCgoPCgcEAgMAAgAFEgSgAQQKCg8KBwQCAwAC
AAESBKABCxkKDwoHBAIDAAIAAxIEoAEcHQoqCgQEAgMBEgakAQLAAQMaGiBWTEFOIGF0dGFj
aG1lbnQgZGV0YWlscy4KCg0KBQQCAwEBEgSkAQoYCjUKBgQCAwECABIEpgEEGxolIFRoZSBw
ZWVyIHZsYW4gSUQgb2YgdGhlIGF0dGFjaG1lbnQuCgoPCgcEAgMBAgAFEgSmAQQJCg8KBwQC
AwECAAESBKYBChYKDwoHBAIDAQIAAxIEpgEZGgowCgYEAgMBAgESBKkBBBcaICBUaGUgcGVl
ciBJUCBvZiB0aGUgYXR0YWNobWVudC4KCg8KBwQCAwECAQUSBKkBBAoKDwoHBAIDAQIBARIE
qQELEgoPCgcEAgMBAgEDEgSpARUWCjIKBgQCAwECAhIErAEEGRoiIFRoZSByb3V0ZXIgSVAg
b2YgdGhlIGF0dGFjaG1lbnQuCgoPCgcEAgMBAgIFEgSsAQQKCg8KBwQCAwECAgESBKwBCxQK
DwoHBAIDAQICAxIErAEXGAoqCgYEAgMBAgMSBK8BBEYaGiBJbnB1dCBvbmx5LiBQYWlyaW5n
IGtleS4KCg8KBwQCAwECAwUSBK8BBAoKDwoHBAIDAQIDARIErwELFgoPCgcEAgMBAgMDEgSv
ARkaCg8KBwQCAwECAwgSBK8BG0UKEgoKBAIDAQIDCJwIABIErwEcRAp8CgYEAgMBAgQSBLMB
BB0abCBUaGUgUU9TIHBvbGljeSBhcHBsaWVkIHRvIHRoaXMgVkxBTiBhdHRhY2htZW50Lgog
VGhpcyB2YWx1ZSBzaG91bGQgYmUgcHJlZmVycmVkIHRvIHVzaW5nIHFvcyBhdCB2cmYgbGV2
ZWwuCgoPCgcEAgMBAgQGEgSzAQQNCg8KBwQCAwECBAESBLMBDhgKDwoHBAIDAQIEAxIEswEb
HApJCgYEAgMBAgUSBLYBBDwaOSBJbW11dGFibGUuIFRoZSBpZGVudGlmaWVyIG9mIHRoZSBh
dHRhY2htZW50IHdpdGhpbiB2cmYuCgoPCgcEAgMBAgUFEgS2AQQKCg8KBwQCAwECBQESBLYB
Cw0KDwoHBAIDAQIFAxIEtgEQEQoPCgcEAgMBAgUIEgS2ARI7ChIKCgQCAwECBQicCAASBLYB
EzoKvAEKBgQCAwECBhIGugEEvwEGGqkBIE9wdGlvbmFsLiBUaGUgbmFtZSBvZiB0aGUgdmxh
biBhdHRhY2htZW50IHdpdGhpbiB2cmYuIFRoaXMgaXMgb2YgdGhlIGZvcm0KIHByb2plY3Rz
L3twcm9qZWN0X251bWJlcn0vcmVnaW9ucy97cmVnaW9ufS9pbnRlcmNvbm5lY3RBdHRhY2ht
ZW50cy97aW50ZXJjb25uZWN0X2F0dGFjaG1lbnR9CgoPCgcEAgMBAgYFEgS6AQQKCg8KBwQC
AwECBgESBLoBCyIKDwoHBAIDAQIGAxIEugElJgoRCgcEAgMBAgYIEga6ASe/AQUKEgoKBAID
AQIGCJwIABIEuwEGLAoTCgkEAgMBAgYInwgSBrwBBr4BBwokCgQEAgIAEgTDAQISGhYgVGhl
IG5hbWUgb2YgdGhlIFZSRi4KCg0KBQQCAgAFEgTDAQIICg0KBQQCAgABEgTDAQkNCg0KBQQC
AgADEgTDARARCioKBAQCAgESBMYBAhIaHCBUaGUgcG9zc2libGUgc3RhdGUgb2YgVlJGLgoK
DQoFBAICAQYSBMYBAgcKDQoFBAICAQESBMYBCA0KDQoFBAICAQMSBMYBEBEKjgIKBAQCAgIS
BMwBAhsa/wEgVGhlIFFPUyBwb2xpY3kgYXBwbGllZCB0byB0aGlzIFZSRi4KIFRoZSB2YWx1
ZSBpcyBvbmx5IG1lYW5pbmdmdWwgd2hlbiBhbGwgdGhlIHZsYW4gYXR0YWNobWVudHMgaGF2
ZSB0aGUgc2FtZQogUW9TLiBUaGlzIGZpZWxkIHNob3VsZCBub3QgYmUgdXNlZCBmb3IgbmV3
IGludGVncmF0aW9ucywgdXNlIHZsYW4KIGF0dGFjaG1lbnQgbGV2ZWwgcW9zIGluc3RlYWQu
IFRoZSBmaWVsZCBpcyBsZWZ0IGZvciBiYWNrd2FyZC1jb21wYXRpYmlsaXR5LgoKDQoFBAIC
AgYSBMwBAgsKDQoFBAICAgESBMwBDBYKDQoFBAICAgMSBMwBGRoKOQoEBAICAxIEzwECLxor
IFRoZSBsaXN0IG9mIFZMQU4gYXR0YWNobWVudHMgZm9yIHRoZSBWUkYuCgoNCgUEAgIDBBIE
zwECCgoNCgUEAgIDBhIEzwELGQoNCgUEAgIDARIEzwEaKgoNCgUEAgIDAxIEzwEtLgqXAgoC
BAMSBtYBAPQBARqIAiBFYWNoIGxvZ2ljYWwgaW50ZXJmYWNlIHJlcHJlc2VudHMgYSBsb2dp
Y2FsIGFic3RyYWN0aW9uIG9mIHRoZSB1bmRlcmx5aW5nCiBwaHlzaWNhbCBpbnRlcmZhY2Ug
KGZvciBlZy4gYm9uZCwgbmljKSBvZiB0aGUgaW5zdGFuY2UuIEVhY2ggbG9naWNhbAogaW50
ZXJmYWNlIGNhbiBlZmZlY3RpdmVseSBtYXAgdG8gbXVsdGlwbGUgbmV0d29yay1JUCBwYWly
cyBhbmQgc3RpbGwgYmUKIG1hcHBlZCB0byBvbmUgdW5kZXJseWluZyBwaHlzaWNhbCBpbnRl
cmZhY2UuCgoLCgMEAwESBNYBCBgKVgoEBAMDABIG2AEC6AEDGkYgRWFjaCBsb2dpY2FsIG5l
dHdvcmsgaW50ZXJmYWNlIGlzIGVmZmVjdGl2ZWx5IGEgbmV0d29yayBhbmQgSVAgcGFpci4K
Cg0KBQQDAwABEgTYAQohCiUKBgQDAwACABIE2gEEFxoVIE5hbWUgb2YgdGhlIG5ldHdvcmsK
Cg8KBwQDAwACAAUSBNoBBAoKDwoHBAMDAAIAARIE2gELEgoPCgcEAwMAAgADEgTaARUWCisK
BgQDAwACARIE3QEEGhobIElQIGFkZHJlc3MgaW4gdGhlIG5ldHdvcmsKCg8KBwQDAwACAQUS
BN0BBAoKDwoHBAMDAAIBARIE3QELFQoPCgcEAwMAAgEDEgTdARgZCpMBCgYEAwMAAgISBOEB
BB0aggEgV2hldGhlciB0aGlzIGludGVyZmFjZSBpcyB0aGUgZGVmYXVsdCBnYXRld2F5IGZv
ciB0aGUgaW5zdGFuY2UuIE9ubHkKIG9uZSBpbnRlcmZhY2UgY2FuIGJlIHRoZSBkZWZhdWx0
IGdhdGV3YXkgZm9yIHRoZSBpbnN0YW5jZS4KCg8KBwQDAwACAgUSBOEBBAgKDwoHBAMDAAIC
ARIE4QEJGAoPCgcEAwMAAgIDEgThARscCiIKBgQDAwACAxIE5AEEIhoSIFR5cGUgb2YgbmV0
d29yay4KCg8KBwQDAwACAwYSBOQBBBAKDwoHBAMDAAIDARIE5AERHQoPCgcEAwMAAgMDEgTk
ASAhCkwKBgQDAwACBBIE5wEEEho8IEFuIGlkZW50aWZpZXIgZm9yIHRoZSBgTmV0d29ya2As
IGdlbmVyYXRlZCBieSB0aGUgYmFja2VuZC4KCg8KBwQDAwACBAUSBOcBBAoKDwoHBAMDAAIE
ARIE5wELDQoPCgcEAwMAAgQDEgTnARARCk4KBAQDAgASBOsBAkIaQCBMaXN0IG9mIGxvZ2lj
YWwgbmV0d29yayBpbnRlcmZhY2VzIHdpdGhpbiBhIGxvZ2ljYWwgaW50ZXJmYWNlLgoKDQoF
BAMCAAQSBOsBAgoKDQoFBAMCAAYSBOsBCyIKDQoFBAMCAAESBOsBIz0KDQoFBAMCAAMSBOsB
QEEKegoEBAMCARIE7wECEhpsIEludGVyZmFjZSBuYW1lLiBUaGlzIGlzIG9mIHN5bnRheCA8
Ym9uZD48Ym9uZF9tb2RlPiBvciA8bmljPiBhbmQKIGZvcm1zIHBhcnQgb2YgdGhlIG5ldHdv
cmsgdGVtcGxhdGUgbmFtZS4KCg0KBQQDAgEFEgTvAQIICg0KBQQDAgEBEgTvAQkNCg0KBQQD
AgEDEgTvARARCp8BCgQEAwICEgTzAQIwGpABIFRoZSBpbmRleCBvZiB0aGUgbG9naWNhbCBp
bnRlcmZhY2UgbWFwcGluZyB0byB0aGUgaW5kZXggb2YgdGhlIGhhcmR3YXJlCiBib25kIG9y
IG5pYyBvbiB0aGUgY2hvc2VuIG5ldHdvcmsgdGVtcGxhdGUuIFRoaXMgZmllbGQgaXMgZGVw
cmVjYXRlZC4KCg0KBQQDAgIFEgTzAQIHCg0KBQQDAgIBEgTzAQgXCg0KBQQDAgIDEgTzARob
Cg0KBQQDAgIIEgTzARwvCg4KBgQDAgIIAxIE8wEdLgo7CgIEBBIG9wEA/wEBGi0gTWVzc2Fn
ZSBmb3IgcmVxdWVzdGluZyBuZXR3b3JrIGluZm9ybWF0aW9uLgoKCwoDBAQBEgT3AQgZCjEK
BAQEAgASBvkBAv4BBBohIFJlcXVpcmVkLiBOYW1lIG9mIHRoZSByZXNvdXJjZS4KCg0KBQQE
AgAFEgT5AQIICg0KBQQEAgABEgT5AQkNCg0KBQQEAgADEgT5ARARCg8KBQQEAgAIEgb5ARL+
AQMKEAoIBAQCAAicCAASBPoBBCoKEQoHBAQCAAifCBIG+wEE/QEFCjoKAgQFEgaCAgCUAgEa
LCBNZXNzYWdlIGZvciByZXF1ZXN0aW5nIGEgbGlzdCBvZiBuZXR3b3Jrcy4KCgsKAwQFARIE
ggIIGwpBCgQEBQIAEgaEAgKJAgQaMSBSZXF1aXJlZC4gUGFyZW50IHZhbHVlIGZvciBMaXN0
TmV0d29ya3NSZXF1ZXN0LgoKDQoFBAUCAAUSBIQCAggKDQoFBAUCAAESBIQCCQ8KDQoFBAUC
AAMSBIQCEhMKDwoFBAUCAAgSBoQCFIkCAwoQCggEBQIACJwIABIEhQIEKgoRCgcEBQIACJ8I
EgaGAgSIAgUKkwEKBAQFAgESBI0CAhYahAEgUmVxdWVzdGVkIHBhZ2Ugc2l6ZS4gVGhlIHNl
cnZlciBtaWdodCByZXR1cm4gZmV3ZXIgaXRlbXMgdGhhbiByZXF1ZXN0ZWQuCiBJZiB1bnNw
ZWNpZmllZCwgc2VydmVyIHdpbGwgcGljayBhbiBhcHByb3ByaWF0ZSBkZWZhdWx0LgoKDQoF
BAUCAQUSBI0CAgcKDQoFBAUCAQESBI0CCBEKDQoFBAUCAQMSBI0CFBUKRgoEBAUCAhIEkAIC
GBo4IEEgdG9rZW4gaWRlbnRpZnlpbmcgYSBwYWdlIG9mIHJlc3VsdHMgZnJvbSB0aGUgc2Vy
dmVyLgoKDQoFBAUCAgUSBJACAggKDQoFBAUCAgESBJACCRMKDQoFBAUCAgMSBJACFhcKHAoE
BAUCAxIEkwICFBoOIExpc3QgZmlsdGVyLgoKDQoFBAUCAwUSBJMCAggKDQoFBAUCAwESBJMC
CQ8KDQoFBAUCAwMSBJMCEhMKQQoCBAYSBpcCAKACARozIFJlc3BvbnNlIG1lc3NhZ2UgY29u
dGFpbmluZyB0aGUgbGlzdCBvZiBuZXR3b3Jrcy4KCgsKAwQGARIElwIIHAolCgQEBgIAEgSZ
AgIgGhcgVGhlIGxpc3Qgb2YgbmV0d29ya3MuCgoNCgUEBgIABBIEmQICCgoNCgUEBgIABhIE
mQILEgoNCgUEBgIAARIEmQITGwoNCgUEBgIAAxIEmQIeHwpGCgQEBgIBEgScAgIdGjggQSB0
b2tlbiBpZGVudGlmeWluZyBhIHBhZ2Ugb2YgcmVzdWx0cyBmcm9tIHRoZSBzZXJ2ZXIuCgoN
CgUEBgIBBRIEnAICCAoNCgUEBgIBARIEnAIJGAoNCgUEBgIBAxIEnAIbHAo0CgQEBgICEgSf
AgIiGiYgTG9jYXRpb25zIHRoYXQgY291bGQgbm90IGJlIHJlYWNoZWQuCgoNCgUEBgICBBIE
nwICCgoNCgUEBgICBRIEnwILEQoNCgUEBgICARIEnwISHQoNCgUEBgICAxIEnwIgIQo5CgIE
BxIGowIArgIBGisgTWVzc2FnZSByZXF1ZXN0aW5nIHRvIHVwZGF0aW5nIGEgbmV0d29yay4K
CgsKAwQHARIEowIIHAq0AQoEBAcCABIEqAICPxqlASBSZXF1aXJlZC4gVGhlIG5ldHdvcmsg
dG8gdXBkYXRlLgoKIFRoZSBgbmFtZWAgZmllbGQgaXMgdXNlZCB0byBpZGVudGlmeSB0aGUg
aW5zdGFuY2UgdG8gdXBkYXRlLgogRm9ybWF0OiBwcm9qZWN0cy97cHJvamVjdH0vbG9jYXRp
b25zL3tsb2NhdGlvbn0vbmV0d29ya3Mve25ldHdvcmt9CgoNCgUEBwIABhIEqAICCQoNCgUE
BwIAARIEqAIKEQoNCgUEBwIAAxIEqAIUFQoNCgUEBwIACBIEqAIWPgoQCggEBwIACJwIABIE
qAIXPQqLAQoEBAcCARIErQICLBp9IFRoZSBsaXN0IG9mIGZpZWxkcyB0byB1cGRhdGUuCiBU
aGUgb25seSBjdXJyZW50bHkgc3VwcG9ydGVkIGZpZWxkcyBhcmU6CiAgIGBsYWJlbHNgLCBg
cmVzZXJ2YXRpb25zYCwgYHZyZi52bGFuX2F0dGFjaG1lbnRzYAoKDQoFBAcCAQYSBK0CAhsK
DQoFBAcCAQESBK0CHCcKDQoFBAcCAQMSBK0CKisKMwoCBAgSBrECALcCARolIE5ldHdvcmsg
d2l0aCBhbGwgdXNlZCBJUCBhZGRyZXNzZXMuCgoLCgMECAESBLECCBQKGAoEBAgCABIEswIC
FhoKIE5ldHdvcmsuCgoNCgUECAIABhIEswICCQoNCgUECAIAARIEswIKEQoNCgUECAIAAxIE
swIUFQo2CgQECAIBEgS2AgIfGiggQWxsIHVzZWQgSVAgYWRkcmVzc2VzIGluIHRoaXMgbmV0
d29yay4KCg0KBQQIAgEEEgS2AgIKCg0KBQQIAgEFEgS2AgsRCg0KBQQIAgEBEgS2AhIaCg0K
BQQIAgEDEgS2Ah0eCjEKAgQJEga6AgDCAgEaIyBSZXF1ZXN0IHRvIGdldCBuZXR3b3JrcyB3
aXRoIElQcy4KCgsKAwQJARIEugIIHwpACgQECQIAEga8AgLBAgQaMCBSZXF1aXJlZC4gUGFy
ZW50IHZhbHVlIChwcm9qZWN0IGFuZCBsb2NhdGlvbikuCgoNCgUECQIABRIEvAICCAoNCgUE
CQIAARIEvAIJEQoNCgUECQIAAxIEvAIUFQoPCgUECQIACBIGvAIWwQIDChAKCAQJAgAInAgA
EgS9AgQqChEKBwQJAgAInwgSBr4CBMACBQovCgIEChIGxQIAyAIBGiEgUmVzcG9uc2Ugd2l0
aCBOZXR3b3JrcyB3aXRoIElQcwoKCwoDBAoBEgTFAgggCiIKBAQKAgASBMcCAiUaFCBOZXR3
b3JrcyB3aXRoIElQcy4KCg0KBQQKAgAEEgTHAgIKCg0KBQQKAgAGEgTHAgsXCg0KBQQKAgAB
EgTHAhggCg0KBQQKAgADEgTHAiMkCioKAgQLEgbLAgDZAgEaHCBNb3VudCBwb2ludCBmb3Ig
YSBuZXR3b3JrLgoKCwoDBAsBEgTLAggZCjAKBAQLAgASBs0CAs8CBRogIEluc3RhbmNlIHRv
IGF0dGFjaCBuZXR3b3JrIHRvLgoKDQoFBAsCAAUSBM0CAggKDQoFBAsCAAESBM0CCREKDQoF
BAsCAAMSBM0CFBUKDwoFBAsCAAgSBs0CFs8CBAoRCgcECwIACJ8IEgbNAhfPAgMKMQoEBAsC
ARIE0gICHxojIExvZ2ljYWwgaW50ZXJmYWNlIHRvIGRldGFjaCBmcm9tLgoKDQoFBAsCAQUS
BNICAggKDQoFBAsCAQESBNICCRoKDQoFBAsCAQMSBNICHR4KNAoEBAsCAhIE1QICGxomIE5l
dHdvcmsgc2hvdWxkIGJlIGEgZGVmYXVsdCBnYXRld2F5LgoKDQoFBAsCAgUSBNUCAgYKDQoF
BAsCAgESBNUCBxYKDQoFBAsCAgMSBNUCGRoKKQoEBAsCAxIE2AICGBobIElwIGFkZHJlc3Mg
b2YgdGhlIHNlcnZlci4KCg0KBQQLAgMFEgTYAgIICg0KBQQLAgMBEgTYAgkTCg0KBQQLAgMD
EgTYAhYXCjYKAgQMEgbcAgDoAgEaKCBNZXNzYWdlIHJlcXVlc3RpbmcgcmVuYW1lIG9mIGEg
c2VydmVyLgoKCwoDBAwBEgTcAggcCpIBCgQEDAIAEgbfAgLkAgQagQEgUmVxdWlyZWQuIFRo
ZSBgbmFtZWAgZmllbGQgaXMgdXNlZCB0byBpZGVudGlmeSB0aGUgbmV0d29yay4KIEZvcm1h
dDogcHJvamVjdHMve3Byb2plY3R9L2xvY2F0aW9ucy97bG9jYXRpb259L25ldHdvcmtzL3tu
ZXR3b3JrfQoKDQoFBAwCAAUSBN8CAggKDQoFBAwCAAESBN8CCQ0KDQoFBAwCAAMSBN8CEBEK
DwoFBAwCAAgSBt8CEuQCAwoQCggEDAIACJwIABIE4AIEKgoRCgcEDAIACJ8IEgbhAgTjAgUK
NgoEBAwCARIE5wICRRooIFJlcXVpcmVkLiBUaGUgbmV3IGBpZGAgb2YgdGhlIG5ldHdvcmsu
CgoNCgUEDAIBBRIE5wICCAoNCgUEDAIBARIE5wIJFwoNCgUEDAIBAxIE5wIaGwoNCgUEDAIB
CBIE5wIcRAoQCggEDAIBCJwIABIE5wIdQ2IGcHJvdG8z
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Baremetalsolution::V2::Network::Network ===
    # Fields for Network
    # Field: name Type: 9 ()
    # Field: id Type: 9 ()
    # Field: type Type: 14 (.google.cloud.baremetalsolution.v2.Network.Type)
    # Field: ip_address Type: 9 ()
    # Field: mac_address Type: 9 ()
    # Field: state Type: 14 (.google.cloud.baremetalsolution.v2.Network.State)
    # Field: vlan_id Type: 9 ()
    # Field: cidr Type: 9 ()
    # Field: vrf Type: 11 (.google.cloud.baremetalsolution.v2.VRF)
    # Field: labels Type: 11 (.google.cloud.baremetalsolution.v2.Network.LabelsEntry)
    # Field: services_cidr Type: 9 ()
    # Field: reservations Type: 11 (.google.cloud.baremetalsolution.v2.NetworkAddressReservation)
    # Field: pod Type: 9 ()
    # Field: mount_points Type: 11 (.google.cloud.baremetalsolution.v2.NetworkMountPoint)
    # Field: jumbo_frames_enabled Type: 8 ()
    # Field: gateway_ip Type: 9 ()

# Enum: Network::Type
our $Network_TYPE_UNSPECIFIED = 0;
our $Network_CLIENT = 1;
our $Network_PRIVATE = 2;

# Enum: Network::State
our $Network_STATE_UNSPECIFIED = 0;
our $Network_PROVISIONING = 1;
our $Network_PROVISIONED = 2;
our $Network_DEPROVISIONING = 3;
our $Network_UPDATING = 4;

# === Message: Google::Cloud::Baremetalsolution::V2::Network::NetworkAddressReservation ===
    # Fields for NetworkAddressReservation
    # Field: start_address Type: 9 ()
    # Field: end_address Type: 9 ()
    # Field: note Type: 9 ()

# === Message: Google::Cloud::Baremetalsolution::V2::Network::VRF ===
    # Fields for VRF
    # Field: name Type: 9 ()
    # Field: state Type: 14 (.google.cloud.baremetalsolution.v2.VRF.State)
    # Field: qos_policy Type: 11 (.google.cloud.baremetalsolution.v2.VRF.QosPolicy)
    # Field: vlan_attachments Type: 11 (.google.cloud.baremetalsolution.v2.VRF.VlanAttachment)

# Enum: VRF::State
our $VRF_STATE_UNSPECIFIED = 0;
our $VRF_PROVISIONING = 1;
our $VRF_PROVISIONED = 2;

# === Message: Google::Cloud::Baremetalsolution::V2::Network::LogicalInterface ===
    # Fields for LogicalInterface
    # Field: logical_network_interfaces Type: 11 (.google.cloud.baremetalsolution.v2.LogicalInterface.LogicalNetworkInterface)
    # Field: name Type: 9 ()
    # Field: interface_index Type: 5 ()

# === Message: Google::Cloud::Baremetalsolution::V2::Network::GetNetworkRequest ===
    # Fields for GetNetworkRequest
    # Field: name Type: 9 ()

# === Message: Google::Cloud::Baremetalsolution::V2::Network::ListNetworksRequest ===
    # Fields for ListNetworksRequest
    # Field: parent Type: 9 ()
    # Field: page_size Type: 5 ()
    # Field: page_token Type: 9 ()
    # Field: filter Type: 9 ()

# === Message: Google::Cloud::Baremetalsolution::V2::Network::ListNetworksResponse ===
    # Fields for ListNetworksResponse
    # Field: networks Type: 11 (.google.cloud.baremetalsolution.v2.Network)
    # Field: next_page_token Type: 9 ()
    # Field: unreachable Type: 9 ()

# === Message: Google::Cloud::Baremetalsolution::V2::Network::UpdateNetworkRequest ===
    # Fields for UpdateNetworkRequest
    # Field: network Type: 11 (.google.cloud.baremetalsolution.v2.Network)
    # Field: update_mask Type: 11 (.google.protobuf.FieldMask)

# === Message: Google::Cloud::Baremetalsolution::V2::Network::NetworkUsage ===
    # Fields for NetworkUsage
    # Field: network Type: 11 (.google.cloud.baremetalsolution.v2.Network)
    # Field: used_ips Type: 9 ()

# === Message: Google::Cloud::Baremetalsolution::V2::Network::ListNetworkUsageRequest ===
    # Fields for ListNetworkUsageRequest
    # Field: location Type: 9 ()

# === Message: Google::Cloud::Baremetalsolution::V2::Network::ListNetworkUsageResponse ===
    # Fields for ListNetworkUsageResponse
    # Field: networks Type: 11 (.google.cloud.baremetalsolution.v2.NetworkUsage)

# === Message: Google::Cloud::Baremetalsolution::V2::Network::NetworkMountPoint ===
    # Fields for NetworkMountPoint
    # Field: instance Type: 9 ()
    # Field: logical_interface Type: 9 ()
    # Field: default_gateway Type: 8 ()
    # Field: ip_address Type: 9 ()

# === Message: Google::Cloud::Baremetalsolution::V2::Network::RenameNetworkRequest ===
    # Fields for RenameNetworkRequest
    # Field: name Type: 9 ()
    # Field: new_network_id Type: 9 ()

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Baremetalsolution::V2::Network - Compiled Protocol Buffers messages for google/cloud/baremetalsolution/v2/network.proto

=head1 SYNOPSIS

    use Google::Cloud::Baremetalsolution::V2::Network;

    my $msg = Google::Cloud::Baremetalsolution::V2::Network::Network->new({
        name => $name,
        id => $id,
        type => $type,
        ip_address => $ip_address,
    });

    # Read or update a field
    my $val = $msg->name();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Baremetalsolution::V2::Network::Network->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/baremetalsolution/v2/network.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Baremetalsolution::V2::Network::Network

A Network.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Output only. The resource name of this `Network`.
Resource names are schemeless URIs that follow the conventions in
https://cloud.google.com/apis/design/resource_names.
Format:
`projects/{project}/locations/{location}/networks/{network}`

=item * C<< $msg->id() >> / C<< $msg->id($value) >>

Type: C<String>

An identifier for the `Network`, generated by the backend.

=item * C<< $msg->type() >> / C<< $msg->type($value) >>

Type: C<Enum> (L<Google::Cloud::Baremetalsolution::V2::Network::Type>)

The type of this network.

=item * C<< $msg->ip_address() >> / C<< $msg->ip_address($value) >>

Type: C<String>

IP address configured.

=item * C<< $msg->mac_address() >> / C<< $msg->mac_address($value) >>

Type: C<String>

List of physical interfaces.

=item * C<< $msg->state() >> / C<< $msg->state($value) >>

Type: C<Enum> (L<Google::Cloud::Baremetalsolution::V2::Network::State>)

The Network state.

=item * C<< $msg->vlan_id() >> / C<< $msg->vlan_id($value) >>

Type: C<String>

The vlan id of the Network.

=item * C<< $msg->cidr() >> / C<< $msg->cidr($value) >>

Type: C<String>

The cidr of the Network.

=item * C<< $msg->vrf() >> / C<< $msg->vrf($value) >>

Type: C<Message> (L<Google::Cloud::Baremetalsolution::V2::Network::VRF>)

The vrf for the Network.

=item * C<< $msg->labels() >> / C<< $msg->labels($value) >>

Type: C<Message> (L<Google::Cloud::Baremetalsolution::V2::Network::Network::LabelsEntry>)

Labels as key value pairs.

=item * C<< $msg->services_cidr() >> / C<< $msg->services_cidr($value) >>

Type: C<String>

IP range for reserved for services (e.g. NFS).

=item * C<< $msg->reservations() >> / C<< $msg->reservations($value) >>

Type: C<Message> (L<Google::Cloud::Baremetalsolution::V2::Network::NetworkAddressReservation>)

List of IP address reservations in this network.
When updating this field, an error will be generated if a reservation
conflicts with an IP address already allocated to a physical server.

=item * C<< $msg->pod() >> / C<< $msg->pod($value) >>

Type: C<String>

Output only. Pod name.

=item * C<< $msg->mount_points() >> / C<< $msg->mount_points($value) >>

Type: C<Message> (L<Google::Cloud::Baremetalsolution::V2::Network::NetworkMountPoint>)

Input only. List of mount points to attach the network to.

=item * C<< $msg->jumbo_frames_enabled() >> / C<< $msg->jumbo_frames_enabled($value) >>

Type: C<Bool>

Whether network uses standard frames or jumbo ones.

=item * C<< $msg->gateway_ip() >> / C<< $msg->gateway_ip($value) >>

Type: C<String>

Output only. Gateway ip address.

=back

=head3 Enum: Network::Type

=over 4

=item * C<TYPE_UNSPECIFIED> => C<0>

=item * C<CLIENT> => C<1>

=item * C<PRIVATE> => C<2>

=back

=head3 Enum: Network::State

=over 4

=item * C<STATE_UNSPECIFIED> => C<0>

=item * C<PROVISIONING> => C<1>

=item * C<PROVISIONED> => C<2>

=item * C<DEPROVISIONING> => C<3>

=item * C<UPDATING> => C<4>

=back

=head2 Google::Cloud::Baremetalsolution::V2::Network::NetworkAddressReservation

A reservation of one or more addresses in a network.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->start_address() >> / C<< $msg->start_address($value) >>

Type: C<String>

The first address of this reservation block.
Must be specified as a single IPv4 address, e.g. 10.1.2.2.

=item * C<< $msg->end_address() >> / C<< $msg->end_address($value) >>

Type: C<String>

The last address of this reservation block, inclusive. I.e., for cases when
reservations are only single addresses, end_address and start_address will
be the same.
Must be specified as a single IPv4 address, e.g. 10.1.2.2.

=item * C<< $msg->note() >> / C<< $msg->note($value) >>

Type: C<String>

A note about this reservation, intended for human consumption.

=back

=head2 Google::Cloud::Baremetalsolution::V2::Network::VRF

A network VRF.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

The name of the VRF.

=item * C<< $msg->state() >> / C<< $msg->state($value) >>

Type: C<Enum> (L<Google::Cloud::Baremetalsolution::V2::VRF::State>)

The possible state of VRF.

=item * C<< $msg->qos_policy() >> / C<< $msg->qos_policy($value) >>

Type: C<Message> (L<Google::Cloud::Baremetalsolution::V2::Network::VRF::QosPolicy>)

The QOS policy applied to this VRF.
The value is only meaningful when all the vlan attachments have the same
QoS. This field should not be used for new integrations, use vlan
attachment level qos instead. The field is left for backward-compatibility.

=item * C<< $msg->vlan_attachments() >> / C<< $msg->vlan_attachments($value) >>

Type: C<Message> (L<Google::Cloud::Baremetalsolution::V2::Network::VRF::VlanAttachment>)

The list of VLAN attachments for the VRF.

=back

=head3 Enum: VRF::State

=over 4

=item * C<STATE_UNSPECIFIED> => C<0>

=item * C<PROVISIONING> => C<1>

=item * C<PROVISIONED> => C<2>

=back

=head2 Google::Cloud::Baremetalsolution::V2::Network::LogicalInterface

Each logical interface represents a logical abstraction of the underlying
physical interface (for eg. bond, nic) of the instance. Each logical
interface can effectively map to multiple network-IP pairs and still be
mapped to one underlying physical interface.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->logical_network_interfaces() >> / C<< $msg->logical_network_interfaces($value) >>

Type: C<Message> (L<Google::Cloud::Baremetalsolution::V2::Network::LogicalInterface::LogicalNetworkInterface>)

List of logical network interfaces within a logical interface.

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Interface name. This is of syntax <bond><bond_mode> or <nic> and
forms part of the network template name.

=item * C<< $msg->interface_index() >> / C<< $msg->interface_index($value) >>

Type: C<Int32>

The index of the logical interface mapping to the index of the hardware
bond or nic on the chosen network template. This field is deprecated.

=back

=head2 Google::Cloud::Baremetalsolution::V2::Network::GetNetworkRequest

Message for requesting network information.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. Name of the resource.

=back

=head2 Google::Cloud::Baremetalsolution::V2::Network::ListNetworksRequest

Message for requesting a list of networks.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->parent() >> / C<< $msg->parent($value) >>

Type: C<String>

Required. Parent value for ListNetworksRequest.

=item * C<< $msg->page_size() >> / C<< $msg->page_size($value) >>

Type: C<Int32>

Requested page size. The server might return fewer items than requested.
If unspecified, server will pick an appropriate default.

=item * C<< $msg->page_token() >> / C<< $msg->page_token($value) >>

Type: C<String>

A token identifying a page of results from the server.

=item * C<< $msg->filter() >> / C<< $msg->filter($value) >>

Type: C<String>

List filter.

=back

=head2 Google::Cloud::Baremetalsolution::V2::Network::ListNetworksResponse

Response message containing the list of networks.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->networks() >> / C<< $msg->networks($value) >>

Type: C<Message> (L<Google::Cloud::Baremetalsolution::V2::Network::Network>)

The list of networks.

=item * C<< $msg->next_page_token() >> / C<< $msg->next_page_token($value) >>

Type: C<String>

A token identifying a page of results from the server.

=item * C<< $msg->unreachable() >> / C<< $msg->unreachable($value) >>

Type: C<String>

Locations that could not be reached.

=back

=head2 Google::Cloud::Baremetalsolution::V2::Network::UpdateNetworkRequest

Message requesting to updating a network.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->network() >> / C<< $msg->network($value) >>

Type: C<Message> (L<Google::Cloud::Baremetalsolution::V2::Network::Network>)

Required. The network to update.

The `name` field is used to identify the instance to update.
Format: projects/{project}/locations/{location}/networks/{network}

=item * C<< $msg->update_mask() >> / C<< $msg->update_mask($value) >>

Type: C<Message> (L<Google::Protobuf::FieldMask::FieldMask>)

The list of fields to update.
The only currently supported fields are:
  `labels`, `reservations`, `vrf.vlan_attachments`

=back

=head2 Google::Cloud::Baremetalsolution::V2::Network::NetworkUsage

Network with all used IP addresses.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->network() >> / C<< $msg->network($value) >>

Type: C<Message> (L<Google::Cloud::Baremetalsolution::V2::Network::Network>)

Network.

=item * C<< $msg->used_ips() >> / C<< $msg->used_ips($value) >>

Type: C<String>

All used IP addresses in this network.

=back

=head2 Google::Cloud::Baremetalsolution::V2::Network::ListNetworkUsageRequest

Request to get networks with IPs.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->location() >> / C<< $msg->location($value) >>

Type: C<String>

Required. Parent value (project and location).

=back

=head2 Google::Cloud::Baremetalsolution::V2::Network::ListNetworkUsageResponse

Response with Networks with IPs

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->networks() >> / C<< $msg->networks($value) >>

Type: C<Message> (L<Google::Cloud::Baremetalsolution::V2::Network::NetworkUsage>)

Networks with IPs.

=back

=head2 Google::Cloud::Baremetalsolution::V2::Network::NetworkMountPoint

Mount point for a network.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->instance() >> / C<< $msg->instance($value) >>

Type: C<String>

Instance to attach network to.

=item * C<< $msg->logical_interface() >> / C<< $msg->logical_interface($value) >>

Type: C<String>

Logical interface to detach from.

=item * C<< $msg->default_gateway() >> / C<< $msg->default_gateway($value) >>

Type: C<Bool>

Network should be a default gateway.

=item * C<< $msg->ip_address() >> / C<< $msg->ip_address($value) >>

Type: C<String>

Ip address of the server.

=back

=head2 Google::Cloud::Baremetalsolution::V2::Network::RenameNetworkRequest

Message requesting rename of a server.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. The `name` field is used to identify the network.
Format: projects/{project}/locations/{location}/networks/{network}

=item * C<< $msg->new_network_id() >> / C<< $msg->new_network_id($value) >>

Type: C<String>

Required. The new `id` of the network.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Baremetalsolution::V2::Network::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
