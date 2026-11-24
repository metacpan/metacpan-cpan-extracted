package Grafeas::V1::Provenance;

use strict;
use warnings;

our $VERSION = '0.14';

use Protobuf::Message;
use Protobuf::DescriptorPool;
use Protobuf::Internal qw(:all);
use MIME::Base64;

BEGIN {
    eval { require Google::Protobuf::Timestamp };
    my $descriptor_b64 = <<'EOF';
ChtncmFmZWFzL3YxL3Byb3ZlbmFuY2UucHJvdG8SCmdyYWZlYXMudjEaH2dvb2dsZS9wcm90
b2J1Zi90aW1lc3RhbXAucHJvdG8isgUKD0J1aWxkUHJvdmVuYW5jZRIOCgJpZBgBIAEoCVIC
aWQSHQoKcHJvamVjdF9pZBgCIAEoCVIJcHJvamVjdElkEi8KCGNvbW1hbmRzGAMgAygLMhMu
Z3JhZmVhcy52MS5Db21tYW5kUghjb21tYW5kcxI9Cg9idWlsdF9hcnRpZmFjdHMYBCADKAsy
FC5ncmFmZWFzLnYxLkFydGlmYWN0Ug5idWlsdEFydGlmYWN0cxI7CgtjcmVhdGVfdGltZRgF
IAEoCzIaLmdvb2dsZS5wcm90b2J1Zi5UaW1lc3RhbXBSCmNyZWF0ZVRpbWUSOQoKc3RhcnRf
dGltZRgGIAEoCzIaLmdvb2dsZS5wcm90b2J1Zi5UaW1lc3RhbXBSCXN0YXJ0VGltZRI1Cghl
bmRfdGltZRgHIAEoCzIaLmdvb2dsZS5wcm90b2J1Zi5UaW1lc3RhbXBSB2VuZFRpbWUSGAoH
Y3JlYXRvchgIIAEoCVIHY3JlYXRvchIZCghsb2dzX3VyaRgJIAEoCVIHbG9nc1VyaRI/ChFz
b3VyY2VfcHJvdmVuYW5jZRgKIAEoCzISLmdyYWZlYXMudjEuU291cmNlUhBzb3VyY2VQcm92
ZW5hbmNlEh0KCnRyaWdnZXJfaWQYCyABKAlSCXRyaWdnZXJJZBJSCg1idWlsZF9vcHRpb25z
GAwgAygLMi0uZ3JhZmVhcy52MS5CdWlsZFByb3ZlbmFuY2UuQnVpbGRPcHRpb25zRW50cnlS
DGJ1aWxkT3B0aW9ucxInCg9idWlsZGVyX3ZlcnNpb24YDSABKAlSDmJ1aWxkZXJWZXJzaW9u
Gj8KEUJ1aWxkT3B0aW9uc0VudHJ5EhAKA2tleRgBIAEoCVIDa2V5EhQKBXZhbHVlGAIgASgJ
UgV2YWx1ZToCOAEi5AIKBlNvdXJjZRI9ChthcnRpZmFjdF9zdG9yYWdlX3NvdXJjZV91cmkY
ASABKAlSGGFydGlmYWN0U3RvcmFnZVNvdXJjZVVyaRJDCgtmaWxlX2hhc2hlcxgCIAMoCzIi
LmdyYWZlYXMudjEuU291cmNlLkZpbGVIYXNoZXNFbnRyeVIKZmlsZUhhc2hlcxIzCgdjb250
ZXh0GAMgASgLMhkuZ3JhZmVhcy52MS5Tb3VyY2VDb250ZXh0Ugdjb250ZXh0EkoKE2FkZGl0
aW9uYWxfY29udGV4dHMYBCADKAsyGS5ncmFmZWFzLnYxLlNvdXJjZUNvbnRleHRSEmFkZGl0
aW9uYWxDb250ZXh0cxpVCg9GaWxlSGFzaGVzRW50cnkSEAoDa2V5GAEgASgJUgNrZXkSLAoF
dmFsdWUYAiABKAsyFi5ncmFmZWFzLnYxLkZpbGVIYXNoZXNSBXZhbHVlOgI4ASI7CgpGaWxl
SGFzaGVzEi0KCWZpbGVfaGFzaBgBIAMoCzIQLmdyYWZlYXMudjEuSGFzaFIIZmlsZUhhc2gi
MAoESGFzaBISCgR0eXBlGAEgASgJUgR0eXBlEhQKBXZhbHVlGAIgASgMUgV2YWx1ZSKAAQoH
Q29tbWFuZBISCgRuYW1lGAEgASgJUgRuYW1lEhAKA2VudhgCIAMoCVIDZW52EhIKBGFyZ3MY
AyADKAlSBGFyZ3MSEAoDZGlyGAQgASgJUgNkaXISDgoCaWQYBSABKAlSAmlkEhkKCHdhaXRf
Zm9yGAYgAygJUgd3YWl0Rm9yIkwKCEFydGlmYWN0EhoKCGNoZWNrc3VtGAEgASgJUghjaGVj
a3N1bRIOCgJpZBgCIAEoCVICaWQSFAoFbmFtZXMYAyADKAlSBW5hbWVzIsYCCg1Tb3VyY2VD
b250ZXh0EkMKCmNsb3VkX3JlcG8YASABKAsyIi5ncmFmZWFzLnYxLkNsb3VkUmVwb1NvdXJj
ZUNvbnRleHRIAFIJY2xvdWRSZXBvEjkKBmdlcnJpdBgCIAEoCzIfLmdyYWZlYXMudjEuR2Vy
cml0U291cmNlQ29udGV4dEgAUgZnZXJyaXQSMAoDZ2l0GAMgASgLMhwuZ3JhZmVhcy52MS5H
aXRTb3VyY2VDb250ZXh0SABSA2dpdBI9CgZsYWJlbHMYBCADKAsyJS5ncmFmZWFzLnYxLlNv
dXJjZUNvbnRleHQuTGFiZWxzRW50cnlSBmxhYmVscxo5CgtMYWJlbHNFbnRyeRIQCgNrZXkY
ASABKAlSA2tleRIUCgV2YWx1ZRgCIAEoCVIFdmFsdWU6AjgBQgkKB2NvbnRleHQilgEKDEFs
aWFzQ29udGV4dBIxCgRraW5kGAEgASgOMh0uZ3JhZmVhcy52MS5BbGlhc0NvbnRleHQuS2lu
ZFIEa2luZBISCgRuYW1lGAIgASgJUgRuYW1lIj8KBEtpbmQSFAoQS0lORF9VTlNQRUNJRklF
RBAAEgkKBUZJWEVEEAESCwoHTU9WQUJMRRACEgkKBU9USEVSEAQitQEKFkNsb3VkUmVwb1Nv
dXJjZUNvbnRleHQSKwoHcmVwb19pZBgBIAEoCzISLmdyYWZlYXMudjEuUmVwb0lkUgZyZXBv
SWQSIQoLcmV2aXNpb25faWQYAiABKAlIAFIKcmV2aXNpb25JZBI/Cg1hbGlhc19jb250ZXh0
GAMgASgLMhguZ3JhZmVhcy52MS5BbGlhc0NvbnRleHRIAFIMYWxpYXNDb250ZXh0QgoKCHJl
dmlzaW9uIscBChNHZXJyaXRTb3VyY2VDb250ZXh0EhkKCGhvc3RfdXJpGAEgASgJUgdob3N0
VXJpEiUKDmdlcnJpdF9wcm9qZWN0GAIgASgJUg1nZXJyaXRQcm9qZWN0EiEKC3JldmlzaW9u
X2lkGAMgASgJSABSCnJldmlzaW9uSWQSPwoNYWxpYXNfY29udGV4dBgEIAEoCzIYLmdyYWZl
YXMudjEuQWxpYXNDb250ZXh0SABSDGFsaWFzQ29udGV4dEIKCghyZXZpc2lvbiJFChBHaXRT
b3VyY2VDb250ZXh0EhAKA3VybBgBIAEoCVIDdXJsEh8KC3JldmlzaW9uX2lkGAIgASgJUgpy
ZXZpc2lvbklkImcKBlJlcG9JZBJDCg9wcm9qZWN0X3JlcG9faWQYASABKAsyGS5ncmFmZWFz
LnYxLlByb2plY3RSZXBvSWRIAFINcHJvamVjdFJlcG9JZBISCgN1aWQYAiABKAlIAFIDdWlk
QgQKAmlkIksKDVByb2plY3RSZXBvSWQSHQoKcHJvamVjdF9pZBgBIAEoCVIJcHJvamVjdElk
EhsKCXJlcG9fbmFtZRgCIAEoCVIIcmVwb05hbWVCUQoNaW8uZ3JhZmVhcy52MVABWjhnb29n
bGUuZ29sYW5nLm9yZy9nZW5wcm90by9nb29nbGVhcGlzL2dyYWZlYXMvdjE7Z3JhZmVhc6IC
A0dSQUr0SgoHEgUOAIgCAQraBAoBDBIDDgASMs8EIENvcHlyaWdodCAyMDE5IFRoZSBHcmFm
ZWFzIEF1dGhvcnMuIEFsbCByaWdodHMgcmVzZXJ2ZWQuCgogTGljZW5zZWQgdW5kZXIgdGhl
IEFwYWNoZSBMaWNlbnNlLCBWZXJzaW9uIDIuMCAodGhlICJMaWNlbnNlIik7CiB5b3UgbWF5
IG5vdCB1c2UgdGhpcyBmaWxlIGV4Y2VwdCBpbiBjb21wbGlhbmNlIHdpdGggdGhlIExpY2Vu
c2UuCiBZb3UgbWF5IG9idGFpbiBhIGNvcHkgb2YgdGhlIExpY2Vuc2UgYXQKCiAgICBodHRw
Oi8vd3d3LmFwYWNoZS5vcmcvbGljZW5zZXMvTElDRU5TRS0yLjAKCiBVbmxlc3MgcmVxdWly
ZWQgYnkgYXBwbGljYWJsZSBsYXcgb3IgYWdyZWVkIHRvIGluIHdyaXRpbmcsIHNvZnR3YXJl
CiBkaXN0cmlidXRlZCB1bmRlciB0aGUgTGljZW5zZSBpcyBkaXN0cmlidXRlZCBvbiBhbiAi
QVMgSVMiIEJBU0lTLAogV0lUSE9VVCBXQVJSQU5USUVTIE9SIENPTkRJVElPTlMgT0YgQU5Z
IEtJTkQsIGVpdGhlciBleHByZXNzIG9yIGltcGxpZWQuCiBTZWUgdGhlIExpY2Vuc2UgZm9y
IHRoZSBzcGVjaWZpYyBsYW5ndWFnZSBnb3Zlcm5pbmcgcGVybWlzc2lvbnMgYW5kCiBsaW1p
dGF0aW9ucyB1bmRlciB0aGUgTGljZW5zZS4KCggKAQISAxAAEwoJCgIDABIDEgApCggKAQgS
AxQATwoJCgIICxIDFABPCggKAQgSAxUAIgoJCgIIChIDFQAiCggKAQgSAxYAJgoJCgIIARID
FgAmCggKAQgSAxcAIQoJCgIIJBIDFwAhCosBCgIEABIEGwBFARp/IFByb3ZlbmFuY2Ugb2Yg
YSBidWlsZC4gQ29udGFpbnMgYWxsIGluZm9ybWF0aW9uIG5lZWRlZCB0byB2ZXJpZnkgdGhl
IGZ1bGwKIGRldGFpbHMgYWJvdXQgdGhlIGJ1aWxkIGZyb20gc291cmNlIHRvIGNvbXBsZXRp
b24uCgoKCgMEAAESAxsIFwo4CgQEAAIAEgMdAhAaKyBSZXF1aXJlZC4gVW5pcXVlIGlkZW50
aWZpZXIgb2YgdGhlIGJ1aWxkLgoKDAoFBAACAAUSAx0CCAoMCgUEAAIAARIDHQkLCgwKBQQA
AgADEgMdDg8KIQoEBAACARIDIAIYGhQgSUQgb2YgdGhlIHByb2plY3QuCgoMCgUEAAIBBRID
IAIICgwKBQQAAgEBEgMgCRMKDAoFBAACAQMSAyAWFwovCgQEAAICEgMjAiAaIiBDb21tYW5k
cyByZXF1ZXN0ZWQgYnkgdGhlIGJ1aWxkLgoKDAoFBAACAgQSAyMCCgoMCgUEAAICBhIDIwsS
CgwKBQQAAgIBEgMjExsKDAoFBAACAgMSAyMeHwojCgQEAAIDEgMmAigaFiBPdXRwdXQgb2Yg
dGhlIGJ1aWxkLgoKDAoFBAACAwQSAyYCCgoMCgUEAAIDBhIDJgsTCgwKBQQAAgMBEgMmFCMK
DAoFBAACAwMSAyYmJwozCgQEAAIEEgMpAiwaJiBUaW1lIGF0IHdoaWNoIHRoZSBidWlsZCB3
YXMgY3JlYXRlZC4KCgwKBQQAAgQGEgMpAhsKDAoFBAACBAESAykcJwoMCgUEAAIEAxIDKSor
CkAKBAQAAgUSAywCKxozIFRpbWUgYXQgd2hpY2ggZXhlY3V0aW9uIG9mIHRoZSBidWlsZCB3
YXMgc3RhcnRlZC4KCgwKBQQAAgUGEgMsAhsKDAoFBAACBQESAywcJgoMCgUEAAIFAxIDLCkq
CkEKBAQAAgYSAy8CKRo0IFRpbWUgYXQgd2hpY2ggZXhlY3V0aW9uIG9mIHRoZSBidWlsZCB3
YXMgZmluaXNoZWQuCgoMCgUEAAIGBhIDLwIbCgwKBQQAAgYBEgMvHCQKDAoFBAACBgMSAy8n
KArXAQoEBAACBxIDNAIVGskBIEUtbWFpbCBhZGRyZXNzIG9mIHRoZSB1c2VyIHdobyBpbml0
aWF0ZWQgdGhpcyBidWlsZC4gTm90ZSB0aGF0IHRoaXMgd2FzIHRoZQogdXNlcidzIGUtbWFp
bCBhZGRyZXNzIGF0IHRoZSB0aW1lIHRoZSBidWlsZCB3YXMgaW5pdGlhdGVkOyB0aGlzIGFk
ZHJlc3MgbWF5CiBub3QgcmVwcmVzZW50IHRoZSBzYW1lIGVuZC11c2VyIGZvciBhbGwgdGlt
ZS4KCgwKBQQAAgcFEgM0AggKDAoFBAACBwESAzQJEAoMCgUEAAIHAxIDNBMUCkMKBAQAAggS
AzcCFho2IFVSSSB3aGVyZSBhbnkgbG9ncyBmb3IgdGhpcyBwcm92ZW5hbmNlIHdlcmUgd3Jp
dHRlbi4KCgwKBQQAAggFEgM3AggKDAoFBAACCAESAzcJEQoMCgUEAAIIAxIDNxQVCjgKBAQA
AgkSAzoCIBorIERldGFpbHMgb2YgdGhlIFNvdXJjZSBpbnB1dCB0byB0aGUgYnVpbGQuCgoM
CgUEAAIJBhIDOgIICgwKBQQAAgkBEgM6CRoKDAoFBAACCQMSAzodHwpZCgQEAAIKEgM9Ahka
TCBUcmlnZ2VyIGlkZW50aWZpZXIgaWYgdGhlIGJ1aWxkIHdhcyB0cmlnZ2VyZWQgYXV0b21h
dGljYWxseTsgZW1wdHkgaWYgbm90LgoKDAoFBAACCgUSAz0CCAoMCgUEAAIKARIDPQkTCgwK
BQQAAgoDEgM9FhgKkQEKBAQAAgsSA0ECKRqDASBTcGVjaWFsIG9wdGlvbnMgYXBwbGllZCB0
byB0aGlzIGJ1aWxkLiBUaGlzIGlzIGEgY2F0Y2gtYWxsIGZpZWxkIHdoZXJlCiBidWlsZCBw
cm92aWRlcnMgY2FuIGVudGVyIGFueSBkZXNpcmVkIGFkZGl0aW9uYWwgZGV0YWlscy4KCgwK
BQQAAgsGEgNBAhUKDAoFBAACCwESA0EWIwoMCgUEAAILAxIDQSYoClEKBAQAAgwSA0QCHhpE
IFZlcnNpb24gc3RyaW5nIG9mIHRoZSBidWlsZGVyIGF0IHRoZSB0aW1lIHRoaXMgYnVpbGQg
d2FzIGV4ZWN1dGVkLgoKDAoFBAACDAUSA0QCCAoMCgUEAAIMARIDRAkYCgwKBQQAAgwDEgNE
Gx0KTQoCBAESBEgAXwEaQSBTb3VyY2UgZGVzY3JpYmVzIHRoZSBsb2NhdGlvbiBvZiB0aGUg
c291cmNlIHVzZWQgZm9yIHRoZSBidWlsZC4KCgoKAwQBARIDSAgOCl4KBAQBAgASA0sCKRpR
IElmIHByb3ZpZGVkLCB0aGUgaW5wdXQgYmluYXJ5IGFydGlmYWN0cyBmb3IgdGhlIGJ1aWxk
IGNhbWUgZnJvbSB0aGlzCiBsb2NhdGlvbi4KCgwKBQQBAgAFEgNLAggKDAoFBAECAAESA0sJ
JAoMCgUEAQIAAxIDSycoCooDCgQEAQIBEgNVAioa/AIgSGFzaChlcykgb2YgdGhlIGJ1aWxk
IHNvdXJjZSwgd2hpY2ggY2FuIGJlIHVzZWQgdG8gdmVyaWZ5IHRoYXQgdGhlIG9yaWdpbmFs
CiBzb3VyY2UgaW50ZWdyaXR5IHdhcyBtYWludGFpbmVkIGluIHRoZSBidWlsZC4KCiBUaGUg
a2V5cyB0byB0aGlzIG1hcCBhcmUgZmlsZSBwYXRocyB1c2VkIGFzIGJ1aWxkIHNvdXJjZSBh
bmQgdGhlIHZhbHVlcwogY29udGFpbiB0aGUgaGFzaCB2YWx1ZXMgZm9yIHRob3NlIGZpbGVz
LgoKIElmIHRoZSBidWlsZCBzb3VyY2UgY2FtZSBpbiBhIHNpbmdsZSBwYWNrYWdlIHN1Y2gg
YXMgYSBnemlwcGVkIHRhcmZpbGUKICgudGFyLmd6KSwgdGhlIEZpbGVIYXNoIHdpbGwgYmUg
Zm9yIHRoZSBzaW5nbGUgcGF0aCB0byB0aGF0IGZpbGUuCgoMCgUEAQIBBhIDVQIZCgwKBQQB
AgEBEgNVGiUKDAoFBAECAQMSA1UoKQpXCgQEAQICEgNYAhwaSiBJZiBwcm92aWRlZCwgdGhl
IHNvdXJjZSBjb2RlIHVzZWQgZm9yIHRoZSBidWlsZCBjYW1lIGZyb20gdGhpcyBsb2NhdGlv
bi4KCgwKBQQBAgIGEgNYAg8KDAoFBAECAgESA1gQFwoMCgUEAQICAxIDWBobCv4BCgQEAQID
EgNeAjEa8AEgSWYgcHJvdmlkZWQsIHNvbWUgb2YgdGhlIHNvdXJjZSBjb2RlIHVzZWQgZm9y
IHRoZSBidWlsZCBtYXkgYmUgZm91bmQgaW4KIHRoZXNlIGxvY2F0aW9ucywgaW4gdGhlIGNh
c2Ugd2hlcmUgdGhlIHNvdXJjZSByZXBvc2l0b3J5IGhhZCBtdWx0aXBsZQogcmVtb3RlcyBv
ciBzdWJtb2R1bGVzLiBUaGlzIGxpc3Qgd2lsbCBub3QgaW5jbHVkZSB0aGUgY29udGV4dCBz
cGVjaWZpZWQgaW4KIHRoZSBjb250ZXh0IGZpZWxkLgoKDAoFBAECAwQSA14CCgoMCgUEAQID
BhIDXgsYCgwKBQQBAgMBEgNeGSwKDAoFBAECAwMSA14vMAqQAQoCBAISBGMAZgEagwEgQ29u
dGFpbmVyIG1lc3NhZ2UgZm9yIGhhc2hlcyBvZiBieXRlIGNvbnRlbnQgb2YgZmlsZXMsIHVz
ZWQgaW4gc291cmNlCiBtZXNzYWdlcyB0byB2ZXJpZnkgaW50ZWdyaXR5IG9mIHNvdXJjZSBp
bnB1dCB0byB0aGUgYnVpbGQuCgoKCgMEAgESA2MIEgozCgQEAgIAEgNlAh4aJiBSZXF1aXJl
ZC4gQ29sbGVjdGlvbiBvZiBmaWxlIGhhc2hlcy4KCgwKBQQCAgAEEgNlAgoKDAoFBAICAAYS
A2ULDwoMCgUEAgIAARIDZRAZCgwKBQQCAgADEgNlHB0KMAoCBAMSBGkAbgEaJCBDb250YWlu
ZXIgbWVzc2FnZSBmb3IgaGFzaCB2YWx1ZXMuCgoKCgMEAwESA2kIDApNCgQEAwIAEgNrAhIa
QCBSZXF1aXJlZC4gVGhlIHR5cGUgb2YgaGFzaCB0aGF0IHdhcyBwZXJmb3JtZWQsIGUuZy4g
IlNIQS0yNTYiLgoKDAoFBAMCAAUSA2sCCAoMCgUEAwIAARIDawkNCgwKBQQDAgADEgNrEBEK
KAoEBAMCARIDbQISGhsgUmVxdWlyZWQuIFRoZSBoYXNoIHZhbHVlLgoKDAoFBAMCAQUSA20C
BwoMCgUEAwIBARIDbQgNCgwKBQQDAgEDEgNtEBEKUAoCBAQSBXEAhgEBGkMgQ29tbWFuZCBk
ZXNjcmliZXMgYSBzdGVwIHBlcmZvcm1lZCBhcyBwYXJ0IG9mIHRoZSBidWlsZCBwaXBlbGlu
ZS4KCgoKAwQEARIDcQgPCqUBCgQEBAIAEgN0AhIalwEgUmVxdWlyZWQuIE5hbWUgb2YgdGhl
IGNvbW1hbmQsIGFzIHByZXNlbnRlZCBvbiB0aGUgY29tbWFuZCBsaW5lLCBvciBpZiB0aGUK
IGNvbW1hbmQgaXMgcGFja2FnZWQgYXMgYSBEb2NrZXIgY29udGFpbmVyLCBhcyBwcmVzZW50
ZWQgdG8gYGRvY2tlciBwdWxsYC4KCgwKBQQEAgAFEgN0AggKDAoFBAQCAAESA3QJDQoMCgUE
BAIAAxIDdBARCkUKBAQEAgESA3cCGho4IEVudmlyb25tZW50IHZhcmlhYmxlcyBzZXQgYmVm
b3JlIHJ1bm5pbmcgdGhpcyBjb21tYW5kLgoKDAoFBAQCAQQSA3cCCgoMCgUEBAIBBRIDdwsR
CgwKBQQEAgEBEgN3EhUKDAoFBAQCAQMSA3cYGQpHCgQEBAICEgN6AhsaOiBDb21tYW5kLWxp
bmUgYXJndW1lbnRzIHVzZWQgd2hlbiBleGVjdXRpbmcgdGhpcyBjb21tYW5kLgoKDAoFBAQC
AgQSA3oCCgoMCgUEBAICBRIDegsRCgwKBQQEAgIBEgN6EhYKDAoFBAQCAgMSA3oZGgpjCgQE
BAIDEgN+AhEaViBXb3JraW5nIGRpcmVjdG9yeSAocmVsYXRpdmUgdG8gcHJvamVjdCBzb3Vy
Y2Ugcm9vdCkgdXNlZCB3aGVuIHJ1bm5pbmcgdGhpcwogY29tbWFuZC4KCgwKBQQEAgMFEgN+
AggKDAoFBAQCAwESA34JDAoMCgUEBAIDAxIDfg8QCnkKBAQEAgQSBIIBAhAaayBPcHRpb25h
bCB1bmlxdWUgaWRlbnRpZmllciBmb3IgdGhpcyBjb21tYW5kLCB1c2VkIGluIHdhaXRfZm9y
IHRvIHJlZmVyZW5jZQogdGhpcyBjb21tYW5kIGFzIGEgZGVwZW5kZW5jeS4KCg0KBQQEAgQF
EgSCAQIICg0KBQQEAgQBEgSCAQkLCg0KBQQEAgQDEgSCAQ4PCkkKBAQEAgUSBIUBAh8aOyBU
aGUgSUQocykgb2YgdGhlIGNvbW1hbmQocykgdGhhdCB0aGlzIGNvbW1hbmQgZGVwZW5kcyBv
bi4KCg0KBQQEAgUEEgSFAQIKCg0KBQQEAgUFEgSFAQsRCg0KBQQEAgUBEgSFARIaCg0KBQQE
AgUDEgSFAR0eCjMKAgQFEgaJAQCYAQEaJSBBcnRpZmFjdCBkZXNjcmliZXMgYSBidWlsZCBw
cm9kdWN0LgoKCwoDBAUBEgSJAQgQCmIKBAQFAgASBIwBAhYaVCBIYXNoIG9yIGNoZWNrc3Vt
IHZhbHVlIG9mIGEgYmluYXJ5LCBvciBEb2NrZXIgUmVnaXN0cnkgMi4wIGRpZ2VzdCBvZiBh
CiBjb250YWluZXIuCgoNCgUEBQIABRIEjAECCAoNCgUEBQIAARIEjAEJEQoNCgUEBQIAAxIE
jAEUFQqJAQoEBAUCARIEkAECEBp7IEFydGlmYWN0IElELCBpZiBhbnk7IGZvciBjb250YWlu
ZXIgaW1hZ2VzLCB0aGlzIHdpbGwgYmUgYSBVUkwgYnkgZGlnZXN0CiBsaWtlIGBnY3IuaW8v
cHJvamVjdElEL2ltYWdlbmFtZUBzaGEyNTY6MTIzNDU2YC4KCg0KBQQFAgEFEgSQAQIICg0K
BQQFAgEBEgSQAQkLCg0KBQQFAgEDEgSQAQ4PCtACCgQEBQICEgSXAQIcGsECIFJlbGF0ZWQg
YXJ0aWZhY3QgbmFtZXMuIFRoaXMgbWF5IGJlIHRoZSBwYXRoIHRvIGEgYmluYXJ5IG9yIGph
ciBmaWxlLCBvciBpbgogdGhlIGNhc2Ugb2YgYSBjb250YWluZXIgYnVpbGQsIHRoZSBuYW1l
IHVzZWQgdG8gcHVzaCB0aGUgY29udGFpbmVyIGltYWdlIHRvCiBHb29nbGUgQ29udGFpbmVy
IFJlZ2lzdHJ5LCBhcyBwcmVzZW50ZWQgdG8gYGRvY2tlciBwdXNoYC4gTm90ZSB0aGF0IGEK
IHNpbmdsZSBBcnRpZmFjdCBJRCBjYW4gaGF2ZSBtdWx0aXBsZSBuYW1lcywgZm9yIGV4YW1w
bGUgaWYgdHdvIHRhZ3MgYXJlCiBhcHBsaWVkIHRvIG9uZSBpbWFnZS4KCg0KBQQFAgIEEgSX
AQIKCg0KBQQFAgIFEgSXAQsRCg0KBQQFAgIBEgSXARIXCg0KBQQFAgIDEgSXARobCqMBCgIE
BhIGnAEAqwEBGpQBIEEgU291cmNlQ29udGV4dCBpcyBhIHJlZmVyZW5jZSB0byBhIHRyZWUg
b2YgZmlsZXMuIEEgU291cmNlQ29udGV4dCB0b2dldGhlcgogd2l0aCBhIHBhdGggcG9pbnQg
dG8gYSB1bmlxdWUgcmV2aXNpb24gb2YgYSBzaW5nbGUgZmlsZSBvciBkaXJlY3RvcnkuCgoL
CgMEBgESBJwBCBUKWwoEBAYIABIGngECpwEDGksgQSBTb3VyY2VDb250ZXh0IGNhbiByZWZl
ciBhbnkgb25lIG9mIHRoZSBmb2xsb3dpbmcgdHlwZXMgb2YgcmVwb3NpdG9yaWVzLgoKDQoF
BAYIAAESBJ4BCA8KVgoEBAYCABIEoAEEKhpIIEEgU291cmNlQ29udGV4dCByZWZlcnJpbmcg
dG8gYSByZXZpc2lvbiBpbiBhIEdvb2dsZSBDbG91ZCBTb3VyY2UgUmVwby4KCg0KBQQGAgAG
EgSgAQQaCg0KBQQGAgABEgSgARslCg0KBQQGAgADEgSgASgpCj4KBAQGAgESBKMBBCMaMCBB
IFNvdXJjZUNvbnRleHQgcmVmZXJyaW5nIHRvIGEgR2Vycml0IHByb2plY3QuCgoNCgUEBgIB
BhIEowEEFwoNCgUEBgIBARIEowEYHgoNCgUEBgIBAxIEowEhIgpVCgQEBgICEgSmAQQdGkcg
QSBTb3VyY2VDb250ZXh0IHJlZmVycmluZyB0byBhbnkgdGhpcmQgcGFydHkgR2l0IHJlcG8g
KGUuZy4sIEdpdEh1YikuCgoNCgUEBgICBhIEpgEEFAoNCgUEBgICARIEpgEVGAoNCgUEBgIC
AxIEpgEbHAoyCgQEBgIDEgSqAQIhGiQgTGFiZWxzIHdpdGggdXNlciBkZWZpbmVkIG1ldGFk
YXRhLgoKDQoFBAYCAwYSBKoBAhUKDQoFBAYCAwESBKoBFhwKDQoFBAYCAwMSBKoBHyAKLAoC
BAcSBq4BAMEBARoeIEFuIGFsaWFzIHRvIGEgcmVwbyByZXZpc2lvbi4KCgsKAwQHARIErgEI
FAonCgQEBwQAEgawAQK6AQMaFyBUaGUgdHlwZSBvZiBhbiBhbGlhcy4KCg0KBQQHBAABEgSw
AQcLChoKBgQHBAACABIEsgEEGRoKIFVua25vd24uCgoPCgcEBwQAAgABEgSyAQQUCg8KBwQH
BAACAAISBLIBFxgKGgoGBAcEAAIBEgS0AQQOGgogR2l0IHRhZy4KCg8KBwQHBAACAQESBLQB
BAkKDwoHBAcEAAIBAhIEtAEMDQodCgYEBwQAAgISBLYBBBAaDSBHaXQgYnJhbmNoLgoKDwoH
BAcEAAICARIEtgEECwoPCgcEBwQAAgICEgS2AQ4PCnMKBgQHBAACAxIEuQEEDhpjIFVzZWQg
dG8gc3BlY2lmeSBub24tc3RhbmRhcmQgYWxpYXNlcy4gRm9yIGV4YW1wbGUsIGlmIGEgR2l0
IHJlcG8gaGFzIGEKIHJlZiBuYW1lZCAicmVmcy9mb28vYmFyIi4KCg8KBwQHBAACAwESBLkB
BAkKDwoHBAcEAAIDAhIEuQEMDQofCgQEBwIAEgS9AQIQGhEgVGhlIGFsaWFzIGtpbmQuCgoN
CgUEBwIABhIEvQECBgoNCgUEBwIAARIEvQEHCwoNCgUEBwIAAxIEvQEODwofCgQEBwIBEgTA
AQISGhEgVGhlIGFsaWFzIG5hbWUuCgoNCgUEBwIBBRIEwAECCAoNCgUEBwIBARIEwAEJDQoN
CgUEBwIBAxIEwAEQEQpmCgIECBIGxQEA0gEBGlggQSBDbG91ZFJlcG9Tb3VyY2VDb250ZXh0
IGRlbm90ZXMgYSBwYXJ0aWN1bGFyIHJldmlzaW9uIGluIGEgR29vZ2xlIENsb3VkCiBTb3Vy
Y2UgUmVwby4KCgsKAwQIARIExQEIHgojCgQECAIAEgTHAQIVGhUgVGhlIElEIG9mIHRoZSBy
ZXBvLgoKDQoFBAgCAAYSBMcBAggKDQoFBAgCAAESBMcBCRAKDQoFBAgCAAMSBMcBExQKZwoE
BAgIABIGywEC0QEDGlcgQSByZXZpc2lvbiBpbiBhIENsb3VkIFJlcG8gY2FuIGJlIGlkZW50
aWZpZWQgYnkgZWl0aGVyIGl0cyByZXZpc2lvbiBJRCBvcgogaXRzIGFsaWFzLgoKDQoFBAgI
AAESBMsBCBAKHgoEBAgCARIEzQEEGxoQIEEgcmV2aXNpb24gSUQuCgoNCgUECAIBBRIEzQEE
CgoNCgUECAIBARIEzQELFgoNCgUECAIBAxIEzQEZGgo3CgQECAICEgTQAQQjGikgQW4gYWxp
YXMsIHdoaWNoIG1heSBiZSBhIGJyYW5jaCBvciB0YWcuCgoNCgUECAICBhIE0AEEEAoNCgUE
CAICARIE0AERHgoNCgUECAICAxIE0AEhIgo+CgIECRIG1QEA5wEBGjAgQSBTb3VyY2VDb250
ZXh0IHJlZmVycmluZyB0byBhIEdlcnJpdCBwcm9qZWN0LgoKCwoDBAkBEgTVAQgbCjUKBAQJ
AgASBNcBAhYaJyBUaGUgVVJJIG9mIGEgcnVubmluZyBHZXJyaXQgaW5zdGFuY2UuCgoNCgUE
CQIABRIE1wECCAoNCgUECQIAARIE1wEJEQoNCgUECQIAAxIE1wEUFQqqAQoEBAkCARIE3AEC
HBqbASBUaGUgZnVsbCBwcm9qZWN0IG5hbWUgd2l0aGluIHRoZSBob3N0LiBQcm9qZWN0cyBt
YXkgYmUgbmVzdGVkLCBzbwogInByb2plY3Qvc3VicHJvamVjdCIgaXMgYSB2YWxpZCBwcm9q
ZWN0IG5hbWUuIFRoZSAicmVwbyBuYW1lIiBpcyB0aGUKIGhvc3RVUkkvcHJvamVjdC4KCg0K
BQQJAgEFEgTcAQIICg0KBQQJAgEBEgTcAQkXCg0KBQQJAgEDEgTcARobCmsKBAQJCAASBuAB
AuYBAxpbIEEgcmV2aXNpb24gaW4gYSBHZXJyaXQgcHJvamVjdCBjYW4gYmUgaWRlbnRpZmll
ZCBieSBlaXRoZXIgaXRzIHJldmlzaW9uIElECiBvciBpdHMgYWxpYXMuCgoNCgUECQgAARIE
4AEIEAonCgQECQICEgTiAQQbGhkgQSByZXZpc2lvbiAoY29tbWl0KSBJRC4KCg0KBQQJAgIF
EgTiAQQKCg0KBQQJAgIBEgTiAQsWCg0KBQQJAgIDEgTiARkaCjcKBAQJAgMSBOUBBCMaKSBB
biBhbGlhcywgd2hpY2ggbWF5IGJlIGEgYnJhbmNoIG9yIHRhZy4KCg0KBQQJAgMGEgTlAQQQ
Cg0KBQQJAgMBEgTlAREeCg0KBQQJAgMDEgTlASEiCnEKAgQKEgbrAQDxAQEaYyBBIEdpdFNv
dXJjZUNvbnRleHQgZGVub3RlcyBhIHBhcnRpY3VsYXIgcmV2aXNpb24gaW4gYSB0aGlyZCBw
YXJ0eSBHaXQKIHJlcG9zaXRvcnkgKGUuZy4sIEdpdEh1YikuCgoLCgMECgESBOsBCBgKIwoE
BAoCABIE7QECERoVIEdpdCByZXBvc2l0b3J5IFVSTC4KCg0KBQQKAgAFEgTtAQIICg0KBQQK
AgABEgTtAQkMCg0KBQQKAgADEgTtAQ8QCiAKBAQKAgESBPABAhkaEiBHaXQgY29tbWl0IGhh
c2guCgoNCgUECgIBBRIE8AECCAoNCgUECgIBARIE8AEJFAoNCgUECgIBAxIE8AEXGAo1CgIE
CxIG9AEA/gEBGicgQSB1bmlxdWUgaWRlbnRpZmllciBmb3IgYSBDbG91ZCBSZXBvLgoKCwoD
BAsBEgT0AQgOCo4BCgQECwgAEgb3AQL9AQMafiBBIGNsb3VkIHJlcG8gY2FuIGJlIGlkZW50
aWZpZWQgYnkgZWl0aGVyIGl0cyBwcm9qZWN0IElEIGFuZCByZXBvc2l0b3J5IG5hbWUKIGNv
bWJpbmF0aW9uLCBvciBpdHMgZ2xvYmFsbHkgdW5pcXVlIGlkZW50aWZpZXIuCgoNCgUECwgA
ARIE9wEICgo+CgQECwIAEgT5AQQmGjAgQSBjb21iaW5hdGlvbiBvZiBhIHByb2plY3QgSUQg
YW5kIGEgcmVwbyBuYW1lLgoKDQoFBAsCAAYSBPkBBBEKDQoFBAsCAAESBPkBEiEKDQoFBAsC
AAMSBPkBJCUKPgoEBAsCARIE/AEEExowIEEgc2VydmVyLWFzc2lnbmVkLCBnbG9iYWxseSB1
bmlxdWUgaWRlbnRpZmllci4KCg0KBQQLAgEFEgT8AQQKCg0KBQQLAgEBEgT8AQsOCg0KBQQL
AgEDEgT8ARESCoUBCgIEDBIGggIAiAIBGncgU2VsZWN0cyBhIHJlcG8gdXNpbmcgYSBHb29n
bGUgQ2xvdWQgUGxhdGZvcm0gcHJvamVjdCBJRCAoZS5nLiwKIHdpbmdlZC1jYXJnby0zMSkg
YW5kIGEgcmVwbyBuYW1lIHdpdGhpbiB0aGF0IHByb2plY3QuCgoLCgMEDAESBIICCBUKJgoE
BAwCABIEhAICGBoYIFRoZSBJRCBvZiB0aGUgcHJvamVjdC4KCg0KBQQMAgAFEgSEAgIICg0K
BQQMAgABEgSEAgkTCg0KBQQMAgADEgSEAhYXCkcKBAQMAgESBIcCAhcaOSBUaGUgbmFtZSBv
ZiB0aGUgcmVwby4gTGVhdmUgZW1wdHkgZm9yIHRoZSBkZWZhdWx0IHJlcG8uCgoNCgUEDAIB
BRIEhwICCAoNCgUEDAIBARIEhwIJEgoNCgUEDAIBAxIEhwIVFmIGcHJvdG8z
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Grafeas::V1::Provenance::BuildProvenance ===
    # Fields for BuildProvenance
    # Field: id Type: 9 ()
    # Field: project_id Type: 9 ()
    # Field: commands Type: 11 (.grafeas.v1.Command)
    # Field: built_artifacts Type: 11 (.grafeas.v1.Artifact)
    # Field: create_time Type: 11 (.google.protobuf.Timestamp)
    # Field: start_time Type: 11 (.google.protobuf.Timestamp)
    # Field: end_time Type: 11 (.google.protobuf.Timestamp)
    # Field: creator Type: 9 ()
    # Field: logs_uri Type: 9 ()
    # Field: source_provenance Type: 11 (.grafeas.v1.Source)
    # Field: trigger_id Type: 9 ()
    # Field: build_options Type: 11 (.grafeas.v1.BuildProvenance.BuildOptionsEntry)
    # Field: builder_version Type: 9 ()

# === Message: Grafeas::V1::Provenance::Source ===
    # Fields for Source
    # Field: artifact_storage_source_uri Type: 9 ()
    # Field: file_hashes Type: 11 (.grafeas.v1.Source.FileHashesEntry)
    # Field: context Type: 11 (.grafeas.v1.SourceContext)
    # Field: additional_contexts Type: 11 (.grafeas.v1.SourceContext)

# === Message: Grafeas::V1::Provenance::FileHashes ===
    # Fields for FileHashes
    # Field: file_hash Type: 11 (.grafeas.v1.Hash)

# === Message: Grafeas::V1::Provenance::Hash ===
    # Fields for Hash
    # Field: type Type: 9 ()
    # Field: value Type: 12 ()

# === Message: Grafeas::V1::Provenance::Command ===
    # Fields for Command
    # Field: name Type: 9 ()
    # Field: env Type: 9 ()
    # Field: args Type: 9 ()
    # Field: dir Type: 9 ()
    # Field: id Type: 9 ()
    # Field: wait_for Type: 9 ()

# === Message: Grafeas::V1::Provenance::Artifact ===
    # Fields for Artifact
    # Field: checksum Type: 9 ()
    # Field: id Type: 9 ()
    # Field: names Type: 9 ()

# === Message: Grafeas::V1::Provenance::SourceContext ===
    # Fields for SourceContext
    # Field: cloud_repo Type: 11 (.grafeas.v1.CloudRepoSourceContext)
    # Field: gerrit Type: 11 (.grafeas.v1.GerritSourceContext)
    # Field: git Type: 11 (.grafeas.v1.GitSourceContext)
    # Field: labels Type: 11 (.grafeas.v1.SourceContext.LabelsEntry)

# === Message: Grafeas::V1::Provenance::AliasContext ===
    # Fields for AliasContext
    # Field: kind Type: 14 (.grafeas.v1.AliasContext.Kind)
    # Field: name Type: 9 ()

# Enum: AliasContext::Kind
our $AliasContext_KIND_UNSPECIFIED = 0;
our $AliasContext_FIXED = 1;
our $AliasContext_MOVABLE = 2;
our $AliasContext_OTHER = 4;

# === Message: Grafeas::V1::Provenance::CloudRepoSourceContext ===
    # Fields for CloudRepoSourceContext
    # Field: repo_id Type: 11 (.grafeas.v1.RepoId)
    # Field: revision_id Type: 9 ()
    # Field: alias_context Type: 11 (.grafeas.v1.AliasContext)

# === Message: Grafeas::V1::Provenance::GerritSourceContext ===
    # Fields for GerritSourceContext
    # Field: host_uri Type: 9 ()
    # Field: gerrit_project Type: 9 ()
    # Field: revision_id Type: 9 ()
    # Field: alias_context Type: 11 (.grafeas.v1.AliasContext)

# === Message: Grafeas::V1::Provenance::GitSourceContext ===
    # Fields for GitSourceContext
    # Field: url Type: 9 ()
    # Field: revision_id Type: 9 ()

# === Message: Grafeas::V1::Provenance::RepoId ===
    # Fields for RepoId
    # Field: project_repo_id Type: 11 (.grafeas.v1.ProjectRepoId)
    # Field: uid Type: 9 ()

# === Message: Grafeas::V1::Provenance::ProjectRepoId ===
    # Fields for ProjectRepoId
    # Field: project_id Type: 9 ()
    # Field: repo_name Type: 9 ()

1;

__END__

=encoding UTF-8

=head1 NAME

Grafeas::V1::Provenance - Compiled Protocol Buffers messages for grafeas/v1/provenance.proto

=head1 SYNOPSIS

    use Grafeas::V1::Provenance;

    my $msg = Grafeas::V1::Provenance::BuildProvenance->new({
        id => $id,
        project_id => $project_id,
        commands => $commands,
        built_artifacts => $built_artifacts,
    });

    # Read or update a field
    my $val = $msg->id();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Grafeas::V1::Provenance::BuildProvenance->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<grafeas/v1/provenance.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Grafeas::V1::Provenance::BuildProvenance

Provenance of a build. Contains all information needed to verify the full
details about the build from source to completion.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->id() >> / C<< $msg->id($value) >>

Type: C<String>

Required. Unique identifier of the build.

=item * C<< $msg->project_id() >> / C<< $msg->project_id($value) >>

Type: C<String>

ID of the project.

=item * C<< $msg->commands() >> / C<< $msg->commands($value) >>

Type: C<Message> (L<Grafeas::V1::Provenance::Command>)

Commands requested by the build.

=item * C<< $msg->built_artifacts() >> / C<< $msg->built_artifacts($value) >>

Type: C<Message> (L<Grafeas::V1::Provenance::Artifact>)

Output of the build.

=item * C<< $msg->create_time() >> / C<< $msg->create_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Time at which the build was created.

=item * C<< $msg->start_time() >> / C<< $msg->start_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Time at which execution of the build was started.

=item * C<< $msg->end_time() >> / C<< $msg->end_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Time at which execution of the build was finished.

=item * C<< $msg->creator() >> / C<< $msg->creator($value) >>

Type: C<String>

E-mail address of the user who initiated this build. Note that this was the
user's e-mail address at the time the build was initiated; this address may
not represent the same end-user for all time.

=item * C<< $msg->logs_uri() >> / C<< $msg->logs_uri($value) >>

Type: C<String>

URI where any logs for this provenance were written.

=item * C<< $msg->source_provenance() >> / C<< $msg->source_provenance($value) >>

Type: C<Message> (L<Grafeas::V1::Provenance::Source>)

Details of the Source input to the build.

=item * C<< $msg->trigger_id() >> / C<< $msg->trigger_id($value) >>

Type: C<String>

Trigger identifier if the build was triggered automatically; empty if not.

=item * C<< $msg->build_options() >> / C<< $msg->build_options($value) >>

Type: C<Message> (L<Grafeas::V1::Provenance::BuildProvenance::BuildOptionsEntry>)

Special options applied to this build. This is a catch-all field where
build providers can enter any desired additional details.

=item * C<< $msg->builder_version() >> / C<< $msg->builder_version($value) >>

Type: C<String>

Version string of the builder at the time this build was executed.

=back

=head2 Grafeas::V1::Provenance::Source

Source describes the location of the source used for the build.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->artifact_storage_source_uri() >> / C<< $msg->artifact_storage_source_uri($value) >>

Type: C<String>

If provided, the input binary artifacts for the build came from this
location.

=item * C<< $msg->file_hashes() >> / C<< $msg->file_hashes($value) >>

Type: C<Message> (L<Grafeas::V1::Provenance::Source::FileHashesEntry>)

Hash(es) of the build source, which can be used to verify that the original
source integrity was maintained in the build.

The keys to this map are file paths used as build source and the values
contain the hash values for those files.

If the build source came in a single package such as a gzipped tarfile
(.tar.gz), the FileHash will be for the single path to that file.

=item * C<< $msg->context() >> / C<< $msg->context($value) >>

Type: C<Message> (L<Grafeas::V1::Provenance::SourceContext>)

If provided, the source code used for the build came from this location.

=item * C<< $msg->additional_contexts() >> / C<< $msg->additional_contexts($value) >>

Type: C<Message> (L<Grafeas::V1::Provenance::SourceContext>)

If provided, some of the source code used for the build may be found in
these locations, in the case where the source repository had multiple
remotes or submodules. This list will not include the context specified in
the context field.

=back

=head2 Grafeas::V1::Provenance::FileHashes

Container message for hashes of byte content of files, used in source
messages to verify integrity of source input to the build.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->file_hash() >> / C<< $msg->file_hash($value) >>

Type: C<Message> (L<Grafeas::V1::Provenance::Hash>)

Required. Collection of file hashes.

=back

=head2 Grafeas::V1::Provenance::Hash

Container message for hash values.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->type() >> / C<< $msg->type($value) >>

Type: C<String>

Required. The type of hash that was performed, e.g. "SHA-256".

=item * C<< $msg->value() >> / C<< $msg->value($value) >>

Type: C<Bytes>

Required. The hash value.

=back

=head2 Grafeas::V1::Provenance::Command

Command describes a step performed as part of the build pipeline.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. Name of the command, as presented on the command line, or if the
command is packaged as a Docker container, as presented to `docker pull`.

=item * C<< $msg->env() >> / C<< $msg->env($value) >>

Type: C<String>

Environment variables set before running this command.

=item * C<< $msg->args() >> / C<< $msg->args($value) >>

Type: C<String>

Command-line arguments used when executing this command.

=item * C<< $msg->dir() >> / C<< $msg->dir($value) >>

Type: C<String>

Working directory (relative to project source root) used when running this
command.

=item * C<< $msg->id() >> / C<< $msg->id($value) >>

Type: C<String>

Optional unique identifier for this command, used in wait_for to reference
this command as a dependency.

=item * C<< $msg->wait_for() >> / C<< $msg->wait_for($value) >>

Type: C<String>

The ID(s) of the command(s) that this command depends on.

=back

=head2 Grafeas::V1::Provenance::Artifact

Artifact describes a build product.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->checksum() >> / C<< $msg->checksum($value) >>

Type: C<String>

Hash or checksum value of a binary, or Docker Registry 2.0 digest of a
container.

=item * C<< $msg->id() >> / C<< $msg->id($value) >>

Type: C<String>

Artifact ID, if any; for container images, this will be a URL by digest
like `gcr.io/projectID/imagename@sha256:123456`.

=item * C<< $msg->names() >> / C<< $msg->names($value) >>

Type: C<String>

Related artifact names. This may be the path to a binary or jar file, or in
the case of a container build, the name used to push the container image to
Google Container Registry, as presented to `docker push`. Note that a
single Artifact ID can have multiple names, for example if two tags are
applied to one image.

=back

=head2 Grafeas::V1::Provenance::SourceContext

A SourceContext is a reference to a tree of files. A SourceContext together
with a path point to a unique revision of a single file or directory.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->cloud_repo() >> / C<< $msg->cloud_repo($value) >>

Type: C<Message> (L<Grafeas::V1::Provenance::CloudRepoSourceContext>)

A SourceContext referring to a revision in a Google Cloud Source Repo.

=item * C<< $msg->gerrit() >> / C<< $msg->gerrit($value) >>

Type: C<Message> (L<Grafeas::V1::Provenance::GerritSourceContext>)

A SourceContext referring to a Gerrit project.

=item * C<< $msg->git() >> / C<< $msg->git($value) >>

Type: C<Message> (L<Grafeas::V1::Provenance::GitSourceContext>)

A SourceContext referring to any third party Git repo (e.g., GitHub).

=item * C<< $msg->labels() >> / C<< $msg->labels($value) >>

Type: C<Message> (L<Grafeas::V1::Provenance::SourceContext::LabelsEntry>)

Labels with user defined metadata.

=back

=head2 Grafeas::V1::Provenance::AliasContext

An alias to a repo revision.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->kind() >> / C<< $msg->kind($value) >>

Type: C<Enum> (L<Grafeas::V1::AliasContext::Kind>)

The alias kind.

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

The alias name.

=back

=head3 Enum: AliasContext::Kind

=over 4

=item * C<KIND_UNSPECIFIED> => C<0>

=item * C<FIXED> => C<1>

=item * C<MOVABLE> => C<2>

=item * C<OTHER> => C<4>

=back

=head2 Grafeas::V1::Provenance::CloudRepoSourceContext

A CloudRepoSourceContext denotes a particular revision in a Google Cloud
Source Repo.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->repo_id() >> / C<< $msg->repo_id($value) >>

Type: C<Message> (L<Grafeas::V1::Provenance::RepoId>)

The ID of the repo.

=item * C<< $msg->revision_id() >> / C<< $msg->revision_id($value) >>

Type: C<String>

A revision ID.

=item * C<< $msg->alias_context() >> / C<< $msg->alias_context($value) >>

Type: C<Message> (L<Grafeas::V1::Provenance::AliasContext>)

An alias, which may be a branch or tag.

=back

=head2 Grafeas::V1::Provenance::GerritSourceContext

A SourceContext referring to a Gerrit project.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->host_uri() >> / C<< $msg->host_uri($value) >>

Type: C<String>

The URI of a running Gerrit instance.

=item * C<< $msg->gerrit_project() >> / C<< $msg->gerrit_project($value) >>

Type: C<String>

The full project name within the host. Projects may be nested, so
"project/subproject" is a valid project name. The "repo name" is the
hostURI/project.

=item * C<< $msg->revision_id() >> / C<< $msg->revision_id($value) >>

Type: C<String>

A revision (commit) ID.

=item * C<< $msg->alias_context() >> / C<< $msg->alias_context($value) >>

Type: C<Message> (L<Grafeas::V1::Provenance::AliasContext>)

An alias, which may be a branch or tag.

=back

=head2 Grafeas::V1::Provenance::GitSourceContext

A GitSourceContext denotes a particular revision in a third party Git
repository (e.g., GitHub).

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->url() >> / C<< $msg->url($value) >>

Type: C<String>

Git repository URL.

=item * C<< $msg->revision_id() >> / C<< $msg->revision_id($value) >>

Type: C<String>

Git commit hash.

=back

=head2 Grafeas::V1::Provenance::RepoId

A unique identifier for a Cloud Repo.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->project_repo_id() >> / C<< $msg->project_repo_id($value) >>

Type: C<Message> (L<Grafeas::V1::Provenance::ProjectRepoId>)

A combination of a project ID and a repo name.

=item * C<< $msg->uid() >> / C<< $msg->uid($value) >>

Type: C<String>

A server-assigned, globally unique identifier.

=back

=head2 Grafeas::V1::Provenance::ProjectRepoId

Selects a repo using a Google Cloud Platform project ID (e.g.,
winged-cargo-31) and a repo name within that project.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->project_id() >> / C<< $msg->project_id($value) >>

Type: C<String>

The ID of the project.

=item * C<< $msg->repo_name() >> / C<< $msg->repo_name($value) >>

Type: C<String>

The name of the repo. Leave empty for the default repo.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Grafeas::V1::Provenance::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
