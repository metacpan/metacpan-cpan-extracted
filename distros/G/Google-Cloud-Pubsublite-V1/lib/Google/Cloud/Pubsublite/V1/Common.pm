package Google::Cloud::Pubsublite::V1::Common;

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
    eval { require Google::Protobuf::Duration };
    eval { require Google::Protobuf::Timestamp };
    my $descriptor_b64 = <<'EOF';
Cidnb29nbGUvY2xvdWQvcHVic3VibGl0ZS92MS9jb21tb24ucHJvdG8SGmdvb2dsZS5jbG91
ZC5wdWJzdWJsaXRlLnYxGh9nb29nbGUvYXBpL2ZpZWxkX2JlaGF2aW9yLnByb3RvGhlnb29n
bGUvYXBpL3Jlc291cmNlLnByb3RvGh5nb29nbGUvcHJvdG9idWYvZHVyYXRpb24ucHJvdG8a
H2dvb2dsZS9wcm90b2J1Zi90aW1lc3RhbXAucHJvdG8iKQoPQXR0cmlidXRlVmFsdWVzEhYK
BnZhbHVlcxgBIAMoDFIGdmFsdWVzIrcCCg1QdWJTdWJNZXNzYWdlEhAKA2tleRgBIAEoDFID
a2V5EhIKBGRhdGEYAiABKAxSBGRhdGESWQoKYXR0cmlidXRlcxgDIAMoCzI5Lmdvb2dsZS5j
bG91ZC5wdWJzdWJsaXRlLnYxLlB1YlN1Yk1lc3NhZ2UuQXR0cmlidXRlc0VudHJ5UgphdHRy
aWJ1dGVzEjkKCmV2ZW50X3RpbWUYBCABKAsyGi5nb29nbGUucHJvdG9idWYuVGltZXN0YW1w
UglldmVudFRpbWUaagoPQXR0cmlidXRlc0VudHJ5EhAKA2tleRgBIAEoCVIDa2V5EkEKBXZh
bHVlGAIgASgLMisuZ29vZ2xlLmNsb3VkLnB1YnN1YmxpdGUudjEuQXR0cmlidXRlVmFsdWVz
UgV2YWx1ZToCOAEiIAoGQ3Vyc29yEhYKBm9mZnNldBgBIAEoA1IGb2Zmc2V0IvEBChBTZXF1
ZW5jZWRNZXNzYWdlEjoKBmN1cnNvchgBIAEoCzIiLmdvb2dsZS5jbG91ZC5wdWJzdWJsaXRl
LnYxLkN1cnNvclIGY3Vyc29yEj0KDHB1Ymxpc2hfdGltZRgCIAEoCzIaLmdvb2dsZS5wcm90
b2J1Zi5UaW1lc3RhbXBSC3B1Ymxpc2hUaW1lEkMKB21lc3NhZ2UYAyABKAsyKS5nb29nbGUu
Y2xvdWQucHVic3VibGl0ZS52MS5QdWJTdWJNZXNzYWdlUgdtZXNzYWdlEh0KCnNpemVfYnl0
ZXMYBCABKANSCXNpemVCeXRlcyLCAQoLUmVzZXJ2YXRpb24SEgoEbmFtZRgBIAEoCVIEbmFt
ZRIvChN0aHJvdWdocHV0X2NhcGFjaXR5GAIgASgDUhJ0aHJvdWdocHV0Q2FwYWNpdHk6bupB
awolcHVic3VibGl0ZS5nb29nbGVhcGlzLmNvbS9SZXNlcnZhdGlvbhJCcHJvamVjdHMve3By
b2plY3R9L2xvY2F0aW9ucy97bG9jYXRpb259L3Jlc2VydmF0aW9ucy97cmVzZXJ2YXRpb259
IqIHCgVUb3BpYxISCgRuYW1lGAEgASgJUgRuYW1lElwKEHBhcnRpdGlvbl9jb25maWcYAiAB
KAsyMS5nb29nbGUuY2xvdWQucHVic3VibGl0ZS52MS5Ub3BpYy5QYXJ0aXRpb25Db25maWdS
D3BhcnRpdGlvbkNvbmZpZxJcChByZXRlbnRpb25fY29uZmlnGAMgASgLMjEuZ29vZ2xlLmNs
b3VkLnB1YnN1YmxpdGUudjEuVG9waWMuUmV0ZW50aW9uQ29uZmlnUg9yZXRlbnRpb25Db25m
aWcSYgoScmVzZXJ2YXRpb25fY29uZmlnGAQgASgLMjMuZ29vZ2xlLmNsb3VkLnB1YnN1Ymxp
dGUudjEuVG9waWMuUmVzZXJ2YXRpb25Db25maWdSEXJlc2VydmF0aW9uQ29uZmlnGpgCCg9Q
YXJ0aXRpb25Db25maWcSFAoFY291bnQYASABKANSBWNvdW50EhoKBXNjYWxlGAIgASgFQgIY
AUgAUgVzY2FsZRJYCghjYXBhY2l0eRgDIAEoCzI6Lmdvb2dsZS5jbG91ZC5wdWJzdWJsaXRl
LnYxLlRvcGljLlBhcnRpdGlvbkNvbmZpZy5DYXBhY2l0eUgAUghjYXBhY2l0eRpsCghDYXBh
Y2l0eRItChNwdWJsaXNoX21pYl9wZXJfc2VjGAEgASgFUhBwdWJsaXNoTWliUGVyU2VjEjEK
FXN1YnNjcmliZV9taWJfcGVyX3NlYxgCIAEoBVISc3Vic2NyaWJlTWliUGVyU2VjQgsKCWRp
bWVuc2lvbhp0Cg9SZXRlbnRpb25Db25maWcSLgoTcGVyX3BhcnRpdGlvbl9ieXRlcxgBIAEo
A1IRcGVyUGFydGl0aW9uQnl0ZXMSMQoGcGVyaW9kGAIgASgLMhkuZ29vZ2xlLnByb3RvYnVm
LkR1cmF0aW9uUgZwZXJpb2QadgoRUmVzZXJ2YXRpb25Db25maWcSYQoWdGhyb3VnaHB1dF9y
ZXNlcnZhdGlvbhgBIAEoCUIq+kEnCiVwdWJzdWJsaXRlLmdvb2dsZWFwaXMuY29tL1Jlc2Vy
dmF0aW9uUhV0aHJvdWdocHV0UmVzZXJ2YXRpb246XOpBWQofcHVic3VibGl0ZS5nb29nbGVh
cGlzLmNvbS9Ub3BpYxI2cHJvamVjdHMve3Byb2plY3R9L2xvY2F0aW9ucy97bG9jYXRpb259
L3RvcGljcy97dG9waWN9IoUFCgxTdWJzY3JpcHRpb24SEgoEbmFtZRgBIAEoCVIEbmFtZRI6
CgV0b3BpYxgCIAEoCUIk+kEhCh9wdWJzdWJsaXRlLmdvb2dsZWFwaXMuY29tL1RvcGljUgV0
b3BpYxJgCg9kZWxpdmVyeV9jb25maWcYAyABKAsyNy5nb29nbGUuY2xvdWQucHVic3VibGl0
ZS52MS5TdWJzY3JpcHRpb24uRGVsaXZlcnlDb25maWdSDmRlbGl2ZXJ5Q29uZmlnEk0KDWV4
cG9ydF9jb25maWcYBCABKAsyKC5nb29nbGUuY2xvdWQucHVic3VibGl0ZS52MS5FeHBvcnRD
b25maWdSDGV4cG9ydENvbmZpZxqAAgoORGVsaXZlcnlDb25maWcSfgoUZGVsaXZlcnlfcmVx
dWlyZW1lbnQYAyABKA4ySy5nb29nbGUuY2xvdWQucHVic3VibGl0ZS52MS5TdWJzY3JpcHRp
b24uRGVsaXZlcnlDb25maWcuRGVsaXZlcnlSZXF1aXJlbWVudFITZGVsaXZlcnlSZXF1aXJl
bWVudCJuChNEZWxpdmVyeVJlcXVpcmVtZW50EiQKIERFTElWRVJZX1JFUVVJUkVNRU5UX1VO
U1BFQ0lGSUVEEAASFwoTREVMSVZFUl9JTU1FRElBVEVMWRABEhgKFERFTElWRVJfQUZURVJf
U1RPUkVEEAI6cepBbgomcHVic3VibGl0ZS5nb29nbGVhcGlzLmNvbS9TdWJzY3JpcHRpb24S
RHByb2plY3RzL3twcm9qZWN0fS9sb2NhdGlvbnMve2xvY2F0aW9ufS9zdWJzY3JpcHRpb25z
L3tzdWJzY3JpcHRpb259IoMECgxFeHBvcnRDb25maWcSUwoNZGVzaXJlZF9zdGF0ZRgBIAEo
DjIuLmdvb2dsZS5jbG91ZC5wdWJzdWJsaXRlLnYxLkV4cG9ydENvbmZpZy5TdGF0ZVIMZGVz
aXJlZFN0YXRlElgKDWN1cnJlbnRfc3RhdGUYBiABKA4yLi5nb29nbGUuY2xvdWQucHVic3Vi
bGl0ZS52MS5FeHBvcnRDb25maWcuU3RhdGVCA+BBA1IMY3VycmVudFN0YXRlElMKEWRlYWRf
bGV0dGVyX3RvcGljGAUgASgJQifgQQH6QSEKH3B1YnN1YmxpdGUuZ29vZ2xlYXBpcy5jb20v
VG9waWNSD2RlYWRMZXR0ZXJUb3BpYxJcCg1wdWJzdWJfY29uZmlnGAMgASgLMjUuZ29vZ2xl
LmNsb3VkLnB1YnN1YmxpdGUudjEuRXhwb3J0Q29uZmlnLlB1YlN1YkNvbmZpZ0gAUgxwdWJz
dWJDb25maWcaJAoMUHViU3ViQ29uZmlnEhQKBXRvcGljGAEgASgJUgV0b3BpYyJcCgVTdGF0
ZRIVChFTVEFURV9VTlNQRUNJRklFRBAAEgoKBkFDVElWRRABEgoKBlBBVVNFRBACEhUKEVBF
Uk1JU1NJT05fREVOSUVEEAMSDQoJTk9UX0ZPVU5EEARCDQoLZGVzdGluYXRpb24ikgEKClRp
bWVUYXJnZXQSPwoMcHVibGlzaF90aW1lGAEgASgLMhouZ29vZ2xlLnByb3RvYnVmLlRpbWVz
dGFtcEgAUgtwdWJsaXNoVGltZRI7CgpldmVudF90aW1lGAIgASgLMhouZ29vZ2xlLnByb3Rv
YnVmLlRpbWVzdGFtcEgAUglldmVudFRpbWVCBgoEdGltZULPAQohY29tLmdvb2dsZS5jbG91
ZC5wdWJzdWJsaXRlLnByb3RvQgtDb21tb25Qcm90b1ABWj5jbG91ZC5nb29nbGUuY29tL2dv
L3B1YnN1YmxpdGUvYXBpdjEvcHVic3VibGl0ZXBiO3B1YnN1YmxpdGVwYvgBAaoCGkdvb2ds
ZS5DbG91ZC5QdWJTdWJMaXRlLlYxygIaR29vZ2xlXENsb3VkXFB1YlN1YkxpdGVcVjHqAh1H
b29nbGU6OkNsb3VkOjpQdWJTdWJMaXRlOjpWMUqWVwoHEgUOALgCAQq8BAoBDBIDDgASMrEE
IENvcHlyaWdodCAyMDI1IEdvb2dsZSBMTEMKCiBMaWNlbnNlZCB1bmRlciB0aGUgQXBhY2hl
IExpY2Vuc2UsIFZlcnNpb24gMi4wICh0aGUgIkxpY2Vuc2UiKTsKIHlvdSBtYXkgbm90IHVz
ZSB0aGlzIGZpbGUgZXhjZXB0IGluIGNvbXBsaWFuY2Ugd2l0aCB0aGUgTGljZW5zZS4KIFlv
dSBtYXkgb2J0YWluIGEgY29weSBvZiB0aGUgTGljZW5zZSBhdAoKICAgICBodHRwOi8vd3d3
LmFwYWNoZS5vcmcvbGljZW5zZXMvTElDRU5TRS0yLjAKCiBVbmxlc3MgcmVxdWlyZWQgYnkg
YXBwbGljYWJsZSBsYXcgb3IgYWdyZWVkIHRvIGluIHdyaXRpbmcsIHNvZnR3YXJlCiBkaXN0
cmlidXRlZCB1bmRlciB0aGUgTGljZW5zZSBpcyBkaXN0cmlidXRlZCBvbiBhbiAiQVMgSVMi
IEJBU0lTLAogV0lUSE9VVCBXQVJSQU5USUVTIE9SIENPTkRJVElPTlMgT0YgQU5ZIEtJTkQs
IGVpdGhlciBleHByZXNzIG9yIGltcGxpZWQuCiBTZWUgdGhlIExpY2Vuc2UgZm9yIHRoZSBz
cGVjaWZpYyBsYW5ndWFnZSBnb3Zlcm5pbmcgcGVybWlzc2lvbnMgYW5kCiBsaW1pdGF0aW9u
cyB1bmRlciB0aGUgTGljZW5zZS4KCggKAQISAxAAIwoJCgIDABIDEgApCgkKAgMBEgMTACMK
CQoCAwISAxQAKAoJCgIDAxIDFQApCggKAQgSAxcAHwoJCgIIHxIDFwAfCggKAQgSAxgANwoJ
CgIIJRIDGAA3CggKAQgSAxkAVQoJCgIICxIDGQBVCggKAQgSAxoAIgoJCgIIChIDGgAiCggK
AQgSAxsALAoJCgIICBIDGwAsCggKAQgSAxwAOgoJCgIIARIDHAA6CggKAQgSAx0ANwoJCgII
KRIDHQA3CggKAQgSAx4ANgoJCgIILRIDHgA2Cj8KAgQAEgQhACQBGjMgVGhlIHZhbHVlcyBh
c3NvY2lhdGVkIHdpdGggYSBrZXkgb2YgYW4gYXR0cmlidXRlLgoKCgoDBAABEgMhCBcKOAoE
BAACABIDIwIcGisgVGhlIGxpc3Qgb2YgdmFsdWVzIGFzc29jaWF0ZWQgd2l0aCBhIGtleS4K
CgwKBQQAAgAEEgMjAgoKDAoFBAACAAUSAyMLEAoMCgUEAAIAARIDIxEXCgwKBQQAAgADEgMj
GhsKVQoCBAESBCcANQEaSSBBIG1lc3NhZ2UgdGhhdCBpcyBwdWJsaXNoZWQgYnkgcHVibGlz
aGVycyBhbmQgZGVsaXZlcmVkIHRvIHN1YnNjcmliZXJzLgoKCgoDBAEBEgMnCBUKwwEKBAQB
AgASAysCEBq1ASBUaGUga2V5IHVzZWQgZm9yIHJvdXRpbmcgbWVzc2FnZXMgdG8gcGFydGl0
aW9ucyBvciBmb3IgY29tcGFjdGlvbiAoZS5nLiwKIGtlZXAgdGhlIGxhc3QgTiBtZXNzYWdl
cyBwZXIga2V5KS4gSWYgdGhlIGtleSBpcyBlbXB0eSwgdGhlIG1lc3NhZ2UgaXMKIHJvdXRl
ZCB0byBhbiBhcmJpdHJhcnkgcGFydGl0aW9uLgoKDAoFBAECAAUSAysCBwoMCgUEAQIAARID
KwgLCgwKBQQBAgADEgMrDg8KKgoEBAECARIDLgIRGh0gVGhlIHBheWxvYWQgb2YgdGhlIG1l
c3NhZ2UuCgoMCgUEAQIBBRIDLgIHCgwKBQQBAgEBEgMuCAwKDAoFBAECAQMSAy4PEApRCgQE
AQICEgMxAi4aRCBPcHRpb25hbCBhdHRyaWJ1dGVzIHRoYXQgY2FuIGJlIHVzZWQgZm9yIG1l
c3NhZ2UgbWV0YWRhdGEvaGVhZGVycy4KCgwKBQQBAgIGEgMxAh4KDAoFBAECAgESAzEfKQoM
CgUEAQICAxIDMSwtCjYKBAQBAgMSAzQCKxopIEFuIG9wdGlvbmFsLCB1c2VyLXNwZWNpZmll
ZCBldmVudCB0aW1lLgoKDAoFBAECAwYSAzQCGwoMCgUEAQIDARIDNBwmCgwKBQQBAgMDEgM0
KSoKWQoCBAISBDgAPAEaTSBBIGN1cnNvciB0aGF0IGRlc2NyaWJlcyB0aGUgcG9zaXRpb24g
b2YgYSBtZXNzYWdlIHdpdGhpbiBhIHRvcGljIHBhcnRpdGlvbi4KCgoKAwQCARIDOAgOCmIK
BAQCAgASAzsCExpVIFRoZSBvZmZzZXQgb2YgYSBtZXNzYWdlIHdpdGhpbiBhIHRvcGljIHBh
cnRpdGlvbi4gTXVzdCBiZSBncmVhdGVyIHRoYW4gb3IKIGVxdWFsIDAuCgoMCgUEAgIABRID
OwIHCgwKBQQCAgABEgM7CA4KDAoFBAICAAMSAzsREgpWCgIEAxIEPwBMARpKIEEgbWVzc2Fn
ZSB0aGF0IGhhcyBiZWVuIHN0b3JlZCBhbmQgc2VxdWVuY2VkIGJ5IHRoZSBQdWIvU3ViIExp
dGUgc3lzdGVtLgoKCgoDBAMBEgM/CBgKUQoEBAMCABIDQQIUGkQgVGhlIHBvc2l0aW9uIG9m
IGEgbWVzc2FnZSB3aXRoaW4gdGhlIHBhcnRpdGlvbiB3aGVyZSBpdCBpcyBzdG9yZWQuCgoM
CgUEAwIABhIDQQIICgwKBQQDAgABEgNBCQ8KDAoFBAMCAAMSA0ESEwphCgQEAwIBEgNFAi0a
VCBUaGUgdGltZSB3aGVuIHRoZSBtZXNzYWdlIHdhcyByZWNlaXZlZCBieSB0aGUgc2VydmVy
IHdoZW4gaXQgd2FzIGZpcnN0CiBwdWJsaXNoZWQuCgoMCgUEAwIBBhIDRQIbCgwKBQQDAgEB
EgNFHCgKDAoFBAMCAQMSA0UrLAogCgQEAwICEgNIAhwaEyBUaGUgdXNlciBtZXNzYWdlLgoK
DAoFBAMCAgYSA0gCDwoMCgUEAwICARIDSBAXCgwKBQQDAgIDEgNIGhsKVQoEBAMCAxIDSwIX
GkggVGhlIHNpemUgaW4gYnl0ZXMgb2YgdGhpcyBtZXNzYWdlIGZvciBmbG93IGNvbnRyb2wg
YW5kIHF1b3RhIHB1cnBvc2VzLgoKDAoFBAMCAwUSA0sCBwoMCgUEAwIDARIDSwgSCgwKBQQD
AgMDEgNLFRYKNAoCBAQSBE8AYgEaKCBNZXRhZGF0YSBhYm91dCBhIHJlc2VydmF0aW9uIHJl
c291cmNlLgoKCgoDBAQBEgNPCBMKCwoDBAQHEgRQAlMECg0KBQQEB50IEgRQAlMECosBCgQE
BAIAEgNYAhIafiBUaGUgbmFtZSBvZiB0aGUgcmVzZXJ2YXRpb24uCiBTdHJ1Y3R1cmVkIGxp
a2U6CiBwcm9qZWN0cy97cHJvamVjdF9udW1iZXJ9L2xvY2F0aW9ucy97bG9jYXRpb259L3Jl
c2VydmF0aW9ucy97cmVzZXJ2YXRpb25faWR9CgoMCgUEBAIABRIDWAIICgwKBQQEAgABEgNY
CQ0KDAoFBAQCAAMSA1gQEQrCAgoEBAQCARIDYQIgGrQCIFRoZSByZXNlcnZlZCB0aHJvdWdo
cHV0IGNhcGFjaXR5LiBFdmVyeSB1bml0IG9mIHRocm91Z2hwdXQgY2FwYWNpdHkgaXMKIGVx
dWl2YWxlbnQgdG8gMSBNaUIvcyBvZiBwdWJsaXNoZWQgbWVzc2FnZXMgb3IgMiBNaUIvcyBv
ZiBzdWJzY3JpYmVkCiBtZXNzYWdlcy4KCiBBbnkgdG9waWNzIHdoaWNoIGFyZSBkZWNsYXJl
ZCBhcyB1c2luZyBjYXBhY2l0eSBmcm9tIGEgUmVzZXJ2YXRpb24gd2lsbAogY29uc3VtZSBy
ZXNvdXJjZXMgZnJvbSB0aGlzIHJlc2VydmF0aW9uIGluc3RlYWQgb2YgYmVpbmcgY2hhcmdl
ZAogaW5kaXZpZHVhbGx5LgoKDAoFBAQCAQUSA2ECBwoMCgUEBAIBARIDYQgbCgwKBQQEAgED
EgNhHh8KLwoCBAUSBWUAtgEBGiIgTWV0YWRhdGEgYWJvdXQgYSB0b3BpYyByZXNvdXJjZS4K
CgoKAwQFARIDZQgNCgsKAwQFBxIEZgJpBAoNCgUEBQedCBIEZgJpBAo3CgQEBQMAEgVsAo8B
AxooIFRoZSBzZXR0aW5ncyBmb3IgYSB0b3BpYydzIHBhcnRpdGlvbnMuCgoMCgUEBQMAARID
bAoZCksKBgQFAwADABIEbgR2BRo7IFRoZSB0aHJvdWdocHV0IGNhcGFjaXR5IGNvbmZpZ3Vy
YXRpb24gZm9yIGVhY2ggcGFydGl0aW9uLgoKDgoHBAUDAAMAARIDbgwUCl8KCAQFAwADAAIA
EgNxBiQaTiBQdWJsaXNoIHRocm91Z2hwdXQgY2FwYWNpdHkgcGVyIHBhcnRpdGlvbiBpbiBN
aUIvcy4KIE11c3QgYmUgPj0gNCBhbmQgPD0gMTYuCgoQCgkEBQMAAwACAAUSA3EGCwoQCgkE
BQMAAwACAAESA3EMHwoQCgkEBQMAAwACAAMSA3EiIwphCggEBQMAAwACARIDdQYmGlAgU3Vi
c2NyaWJlIHRocm91Z2hwdXQgY2FwYWNpdHkgcGVyIHBhcnRpdGlvbiBpbiBNaUIvcy4KIE11
c3QgYmUgPj0gNCBhbmQgPD0gMzIuCgoQCgkEBQMAAwACAQUSA3UGCwoQCgkEBQMAAwACAQES
A3UMIQoQCgkEBQMAAwACAQMSA3UkJQrBAgoGBAUDAAIAEgN+BBQasQIgVGhlIG51bWJlciBv
ZiBwYXJ0aXRpb25zIGluIHRoZSB0b3BpYy4gTXVzdCBiZSBhdCBsZWFzdCAxLgoKIE9uY2Ug
YSB0b3BpYyBoYXMgYmVlbiBjcmVhdGVkIHRoZSBudW1iZXIgb2YgcGFydGl0aW9ucyBjYW4g
YmUgaW5jcmVhc2VkCiBidXQgbm90IGRlY3JlYXNlZC4gTWVzc2FnZSBvcmRlcmluZyBpcyBu
b3QgZ3VhcmFudGVlZCBhY3Jvc3MgYSB0b3BpYwogcmVzaXplLiBGb3IgbW9yZSBpbmZvcm1h
dGlvbiBzZWUKIGh0dHBzOi8vY2xvdWQuZ29vZ2xlLmNvbS9wdWJzdWIvbGl0ZS9kb2NzL3Rv
cGljcyNzY2FsaW5nX2NhcGFjaXR5CgoOCgcEBQMAAgAFEgN+BAkKDgoHBAUDAAIAARIDfgoP
Cg4KBwQFAwACAAMSA34SEwo7CgYEBQMACAASBoEBBI4BBRopIFRoZSB0aHJvdWdocHV0IGRp
bWVuc2lvbiBvZiB0aGlzIHRvcGljLgoKDwoHBAUDAAgAARIEgQEKEwqJAwoGBAUDAAIBEgSK
AQYqGvgCIERFUFJFQ0FURUQ6IFVzZSBjYXBhY2l0eSBpbnN0ZWFkIHdoaWNoIGNhbiBleHBy
ZXNzIGEgc3VwZXJzZXQgb2YKIGNvbmZpZ3VyYXRpb25zLgoKIEV2ZXJ5IHBhcnRpdGlvbiBp
biB0aGUgdG9waWMgaXMgYWxsb2NhdGVkIHRocm91Z2hwdXQgZXF1aXZhbGVudCB0bwogYHNj
YWxlYCB0aW1lcyB0aGUgc3RhbmRhcmQgcGFydGl0aW9uIHRocm91Z2hwdXQgKDQgTWlCL3Mp
LiBUaGlzIGlzIGFsc28KIHJlZmxlY3RlZCBpbiB0aGUgY29zdCBvZiB0aGlzIHRvcGljOyBh
IHRvcGljIHdpdGggYHNjYWxlYCBvZiAyIGFuZAogY291bnQgb2YgMTAgaXMgY2hhcmdlZCBm
b3IgMjAgcGFydGl0aW9ucy4gVGhpcyB2YWx1ZSBtdXN0IGJlIGluIHRoZQogcmFuZ2UgWzEs
NF0uCgoPCgcEBQMAAgEFEgSKAQYLCg8KBwQFAwACAQESBIoBDBEKDwoHBAUDAAIBAxIEigEU
FQoPCgcEBQMAAgEIEgSKARYpChAKCAQFAwACAQgDEgSKARcoCi0KBgQFAwACAhIEjQEGHBod
IFRoZSBjYXBhY2l0eSBjb25maWd1cmF0aW9uLgoKDwoHBAUDAAICBhIEjQEGDgoPCgcEBQMA
AgIBEgSNAQ8XCg8KBwQFAwACAgMSBI0BGhsKPwoEBAUDARIGkgECnQEDGi8gVGhlIHNldHRp
bmdzIGZvciBhIHRvcGljJ3MgbWVzc2FnZSByZXRlbnRpb24uCgoNCgUEBQMBARIEkgEKGQqA
AgoGBAUDAQIAEgSXAQQiGu8BIFRoZSBwcm92aXNpb25lZCBzdG9yYWdlLCBpbiBieXRlcywg
cGVyIHBhcnRpdGlvbi4gSWYgdGhlIG51bWJlciBvZiBieXRlcwogc3RvcmVkIGluIGFueSBv
ZiB0aGUgdG9waWMncyBwYXJ0aXRpb25zIGdyb3dzIGJleW9uZCB0aGlzIHZhbHVlLCBvbGRl
cgogbWVzc2FnZXMgd2lsbCBiZSBkcm9wcGVkIHRvIG1ha2Ugcm9vbSBmb3IgbmV3ZXIgb25l
cywgcmVnYXJkbGVzcyBvZiB0aGUKIHZhbHVlIG9mIGBwZXJpb2RgLgoKDwoHBAUDAQIABRIE
lwEECQoPCgcEBQMBAgABEgSXAQodCg8KBwQFAwECAAMSBJcBICEKswEKBgQFAwECARIEnAEE
KBqiASBIb3cgbG9uZyBhIHB1Ymxpc2hlZCBtZXNzYWdlIGlzIHJldGFpbmVkLiBJZiB1bnNl
dCwgbWVzc2FnZXMgd2lsbCBiZQogcmV0YWluZWQgYXMgbG9uZyBhcyB0aGUgYnl0ZXMgcmV0
YWluZWQgZm9yIGVhY2ggcGFydGl0aW9uIGlzIGJlbG93CiBgcGVyX3BhcnRpdGlvbl9ieXRl
c2AuCgoPCgcEBQMBAgEGEgScAQQcCg8KBwQFAwECAQESBJwBHSMKDwoHBAUDAQIBAxIEnAEm
JwpCCgQEBQMCEgagAQKnAQMaMiBUaGUgc2V0dGluZ3MgZm9yIHRoaXMgdG9waWMncyBSZXNl
cnZhdGlvbiB1c2FnZS4KCg0KBQQFAwIBEgSgAQobCrEBCgYEBQMCAgASBqQBBKYBBxqeASBU
aGUgUmVzZXJ2YXRpb24gdG8gdXNlIGZvciB0aGlzIHRvcGljJ3MgdGhyb3VnaHB1dCBjYXBh
Y2l0eS4KIFN0cnVjdHVyZWQgbGlrZToKIHByb2plY3RzL3twcm9qZWN0X251bWJlcn0vbG9j
YXRpb25zL3tsb2NhdGlvbn0vcmVzZXJ2YXRpb25zL3tyZXNlcnZhdGlvbl9pZH0KCg8KBwQF
AwICAAUSBKQBBAoKDwoHBAUDAgIAARIEpAELIQoPCgcEBQMCAgADEgSkASQlChEKBwQFAwIC
AAgSBqQBJqYBBgoTCgkEBQMCAgAInwgSBqQBJ6YBBQp6CgQEBQIAEgSsAQISGmwgVGhlIG5h
bWUgb2YgdGhlIHRvcGljLgogU3RydWN0dXJlZCBsaWtlOgogcHJvamVjdHMve3Byb2plY3Rf
bnVtYmVyfS9sb2NhdGlvbnMve2xvY2F0aW9ufS90b3BpY3Mve3RvcGljX2lkfQoKDQoFBAUC
AAUSBKwBAggKDQoFBAUCAAESBKwBCQ0KDQoFBAUCAAMSBKwBEBEKOQoEBAUCARIErwECJxor
IFRoZSBzZXR0aW5ncyBmb3IgdGhpcyB0b3BpYydzIHBhcnRpdGlvbnMuCgoNCgUEBQIBBhIE
rwECEQoNCgUEBQIBARIErwESIgoNCgUEBQIBAxIErwElJgpACgQEBQICEgSyAQInGjIgVGhl
IHNldHRpbmdzIGZvciB0aGlzIHRvcGljJ3MgbWVzc2FnZSByZXRlbnRpb24uCgoNCgUEBQIC
BhIEsgECEQoNCgUEBQICARIEsgESIgoNCgUEBQICAxIEsgElJgpACgQEBQIDEgS1AQIrGjIg
VGhlIHNldHRpbmdzIGZvciB0aGlzIHRvcGljJ3MgUmVzZXJ2YXRpb24gdXNhZ2UuCgoNCgUE
BQIDBhIEtQECEwoNCgUEBQIDARIEtQEUJgoNCgUEBQIDAxIEtQEpKgo3CgIEBhIGuQEA6AEB
GikgTWV0YWRhdGEgYWJvdXQgYSBzdWJzY3JpcHRpb24gcmVzb3VyY2UuCgoLCgMEBgESBLkB
CBQKDQoDBAYHEga6AQK9AQQKDwoFBAYHnQgSBroBAr0BBApFCgQEBgMAEgbAAQLUAQMaNSBU
aGUgc2V0dGluZ3MgZm9yIGEgc3Vic2NyaXB0aW9uJ3MgbWVzc2FnZSBkZWxpdmVyeS4KCg0K
BQQGAwABEgTAAQoYCoMCCgYEBgMABAASBsQBBNABBRrwASBXaGVuIHRoaXMgc3Vic2NyaXB0
aW9uIHNob3VsZCBzZW5kIG1lc3NhZ2VzIHRvIHN1YnNjcmliZXJzIHJlbGF0aXZlIHRvCiBt
ZXNzYWdlcyBwZXJzaXN0ZW5jZSBpbiBzdG9yYWdlLiBGb3IgZGV0YWlscywgc2VlIFtDcmVh
dGluZyBMaXRlCiBzdWJzY3JpcHRpb25zXShodHRwczovL2Nsb3VkLmdvb2dsZS5jb20vcHVi
c3ViL2xpdGUvZG9jcy9zdWJzY3JpcHRpb25zI2NyZWF0aW5nX2xpdGVfc3Vic2NyaXB0aW9u
cykuCgoPCgcEBgMABAABEgTEAQkcCjgKCAQGAwAEAAIAEgTGAQYrGiYgRGVmYXVsdCB2YWx1
ZS4gVGhpcyB2YWx1ZSBpcyB1bnVzZWQuCgoRCgkEBgMABAACAAESBMYBBiYKEQoJBAYDAAQA
AgACEgTGASkqCpABCggEBgMABAACARIEygEGHhp+IFRoZSBzZXJ2ZXIgZG9lcyBub3Qgd2Fp
dCBmb3IgYSBwdWJsaXNoZWQgbWVzc2FnZSB0byBiZSBzdWNjZXNzZnVsbHkKIHdyaXR0ZW4g
dG8gc3RvcmFnZSBiZWZvcmUgZGVsaXZlcmluZyBpdCB0byBzdWJzY3JpYmVycy4KChEKCQQG
AwAEAAIBARIEygEGGQoRCgkEBgMABAACAQISBMoBHB0K2QEKCAQGAwAEAAICEgTPAQYfGsYB
IFRoZSBzZXJ2ZXIgd2lsbCBub3QgZGVsaXZlciBhIHB1Ymxpc2hlZCBtZXNzYWdlIHRvIHN1
YnNjcmliZXJzIHVudGlsCiB0aGUgbWVzc2FnZSBoYXMgYmVlbiBzdWNjZXNzZnVsbHkgd3Jp
dHRlbiB0byBzdG9yYWdlLiBUaGlzIHdpbGwgcmVzdWx0CiBpbiBoaWdoZXIgZW5kLXRvLWVu
ZCBsYXRlbmN5LCBidXQgY29uc2lzdGVudCBkZWxpdmVyeS4KChEKCQQGAwAEAAICARIEzwEG
GgoRCgkEBgMABAACAgISBM8BHR4KQAoGBAYDAAIAEgTTAQQxGjAgVGhlIERlbGl2ZXJ5UmVx
dWlyZW1lbnQgZm9yIHRoaXMgc3Vic2NyaXB0aW9uLgoKDwoHBAYDAAIABhIE0wEEFwoPCgcE
BgMAAgABEgTTARgsCg8KBwQGAwACAAMSBNMBLzAKkAEKBAQGAgASBNkBAhIagQEgVGhlIG5h
bWUgb2YgdGhlIHN1YnNjcmlwdGlvbi4KIFN0cnVjdHVyZWQgbGlrZToKIHByb2plY3RzL3tw
cm9qZWN0X251bWJlcn0vbG9jYXRpb25zL3tsb2NhdGlvbn0vc3Vic2NyaXB0aW9ucy97c3Vi
c2NyaXB0aW9uX2lkfQoKDQoFBAYCAAUSBNkBAggKDQoFBAYCAAESBNkBCQ0KDQoFBAYCAAMS
BNkBEBEKngEKBAQGAgESBt4BAuABBRqNASBUaGUgbmFtZSBvZiB0aGUgdG9waWMgdGhpcyBz
dWJzY3JpcHRpb24gaXMgYXR0YWNoZWQgdG8uCiBTdHJ1Y3R1cmVkIGxpa2U6CiBwcm9qZWN0
cy97cHJvamVjdF9udW1iZXJ9L2xvY2F0aW9ucy97bG9jYXRpb259L3RvcGljcy97dG9waWNf
aWR9CgoNCgUEBgIBBRIE3gECCAoNCgUEBgIBARIE3gEJDgoNCgUEBgIBAxIE3gEREgoPCgUE
BgIBCBIG3gET4AEEChEKBwQGAgEInwgSBt4BFOABAwpGCgQEBgICEgTjAQIlGjggVGhlIHNl
dHRpbmdzIGZvciB0aGlzIHN1YnNjcmlwdGlvbidzIG1lc3NhZ2UgZGVsaXZlcnkuCgoNCgUE
BgICBhIE4wECEAoNCgUEBgICARIE4wERIAoNCgUEBgICAxIE4wEjJAqQAQoEBAYCAxIE5wEC
IRqBASBJZiBwcmVzZW50LCBtZXNzYWdlcyBhcmUgYXV0b21hdGljYWxseSB3cml0dGVuIGZy
b20gdGhlIFB1Yi9TdWIgTGl0ZSB0b3BpYwogYXNzb2NpYXRlZCB3aXRoIHRoaXMgc3Vic2Ny
aXB0aW9uIHRvIGEgZGVzdGluYXRpb24uCgoNCgUEBgIDBhIE5wECDgoNCgUEBgIDARIE5wEP
HAoNCgUEBgIDAxIE5wEfIAqlAQoCBAcSBuwBAKUCARqWASBDb25maWd1cmF0aW9uIGZvciBh
IFB1Yi9TdWIgTGl0ZSBzdWJzY3JpcHRpb24gdGhhdCB3cml0ZXMgbWVzc2FnZXMgdG8gYQog
ZGVzdGluYXRpb24uIFVzZXIgc3Vic2NyaWJlciBjbGllbnRzIG11c3Qgbm90IGNvbm5lY3Qg
dG8gdGhpcyBzdWJzY3JpcHRpb24uCgoLCgMEBwESBOwBCBQKKwoEBAcEABIG7gEC/QEDGhsg
VGhlIGRlc2lyZWQgZXhwb3J0IHN0YXRlLgoKDQoFBAcEAAESBO4BBwwKNgoGBAcEAAIAEgTw
AQQaGiYgRGVmYXVsdCB2YWx1ZS4gVGhpcyB2YWx1ZSBpcyB1bnVzZWQuCgoPCgcEBwQAAgAB
EgTwAQQVCg8KBwQHBAACAAISBPABGBkKLgoGBAcEAAIBEgTzAQQPGh4gTWVzc2FnZXMgYXJl
IGJlaW5nIGV4cG9ydGVkLgoKDwoHBAcEAAIBARIE8wEECgoPCgcEBwQAAgECEgTzAQ0OCjIK
BgQHBAACAhIE9gEEDxoiIEV4cG9ydGluZyBtZXNzYWdlcyBpcyBzdXNwZW5kZWQuCgoPCgcE
BwQAAgIBEgT2AQQKCg8KBwQHBAACAgISBPYBDQ4KWwoGBAcEAAIDEgT5AQQaGksgTWVzc2Fn
ZXMgY2Fubm90IGJlIGV4cG9ydGVkIGR1ZSB0byBwZXJtaXNzaW9uIGRlbmllZCBlcnJvcnMu
IE91dHB1dCBvbmx5LgoKDwoHBAcEAAIDARIE+QEEFQoPCgcEBwQAAgMCEgT5ARgZClQKBgQH
BAACBBIE/AEEEhpEIE1lc3NhZ2VzIGNhbm5vdCBiZSBleHBvcnRlZCBkdWUgdG8gbWlzc2lu
ZyByZXNvdXJjZXMuIE91dHB1dCBvbmx5LgoKDwoHBAcEAAIEARIE/AEEDQoPCgcEBwQAAgQC
EgT8ARARCkEKBAQHAwASBoACAoUCAxoxIENvbmZpZ3VyYXRpb24gZm9yIGV4cG9ydGluZyB0
byBhIFB1Yi9TdWIgdG9waWMuCgoNCgUEBwMAARIEgAIKFgqKAQoGBAcDAAIAEgSEAgQVGnog
VGhlIG5hbWUgb2YgdGhlIFB1Yi9TdWIgdG9waWMuCiBTdHJ1Y3R1cmVkIGxpa2U6IHByb2pl
Y3RzL3twcm9qZWN0X251bWJlcn0vdG9waWNzL3t0b3BpY19pZH0uCiBUaGUgdG9waWMgbWF5
IGJlIGNoYW5nZWQuCgoPCgcEBwMAAgAFEgSEAgQKCg8KBwQHAwACAAESBIQCCxAKDwoHBAcD
AAIAAxIEhAITFAqDAQoEBAcCABIEiQICGhp1IFRoZSBkZXNpcmVkIHN0YXRlIG9mIHRoaXMg
ZXhwb3J0LiBTZXR0aW5nIHRoaXMgdG8gdmFsdWVzIG90aGVyIHRoYW4KIGBBQ1RJVkVgIGFu
ZCBgUEFVU0VEYCB3aWxsIHJlc3VsdCBpbiBhbiBlcnJvci4KCg0KBQQHAgAGEgSJAgIHCg0K
BQQHAgABEgSJAggVCg0KBQQHAgADEgSJAhgZCpUBCgQEBwIBEgSNAgJGGoYBIE91dHB1dCBv
bmx5LiBUaGUgY3VycmVudCBzdGF0ZSBvZiB0aGUgZXhwb3J0LCB3aGljaCBtYXkgYmUgZGlm
ZmVyZW50IHRvIHRoZQogZGVzaXJlZCBzdGF0ZSBkdWUgdG8gZXJyb3JzLiBUaGlzIGZpZWxk
IGlzIG91dHB1dCBvbmx5LgoKDQoFBAcCAQYSBI0CAgcKDQoFBAcCAQESBI0CCBUKDQoFBAcC
AQMSBI0CGBkKDQoFBAcCAQgSBI0CGkUKEAoIBAcCAQicCAASBI0CG0QK+QMKBAQHAgISBpgC
Ap0CBBroAyBPcHRpb25hbC4gVGhlIG5hbWUgb2YgYW4gb3B0aW9uYWwgUHViL1N1YiBMaXRl
IHRvcGljIHRvIHB1Ymxpc2ggbWVzc2FnZXMKIHRoYXQgY2FuIG5vdCBiZSBleHBvcnRlZCB0
byB0aGUgZGVzdGluYXRpb24uIEZvciBleGFtcGxlLCB0aGUgbWVzc2FnZSBjYW4KIG5vdCBi
ZSBwdWJsaXNoZWQgdG8gdGhlIFB1Yi9TdWIgc2VydmljZSBiZWNhdXNlIGl0IGRvZXMgbm90
IHNhdGlzZnkgdGhlCiBjb25zdHJhaW50cyBkb2N1bWVudGVkIGF0IGh0dHBzOi8vY2xvdWQu
Z29vZ2xlLmNvbS9wdWJzdWIvZG9jcy9wdWJsaXNoZXIuCgogU3RydWN0dXJlZCBsaWtlOgog
cHJvamVjdHMve3Byb2plY3RfbnVtYmVyfS9sb2NhdGlvbnMve2xvY2F0aW9ufS90b3BpY3Mv
e3RvcGljX2lkfS4KIE11c3QgYmUgd2l0aGluIHRoZSBzYW1lIHByb2plY3QgYW5kIGxvY2F0
aW9uIGFzIHRoZSBzdWJzY3JpcHRpb24uIFRoZSB0b3BpYwogbWF5IGJlIGNoYW5nZWQgb3Ig
cmVtb3ZlZC4KCg0KBQQHAgIFEgSYAgIICg0KBQQHAgIBEgSYAgkaCg0KBQQHAgIDEgSYAh0e
Cg8KBQQHAgIIEgaYAh+dAgMKEAoIBAcCAgicCAASBJkCBCoKEQoHBAcCAgifCBIGmgIEnAIF
CjkKBAQHCAASBqACAqQCAxopIFRoZSBkZXN0aW5hdGlvbiB0byBleHBvcnQgdG8uIFJlcXVp
cmVkLgoKDQoFBAcIAAESBKACCBMKhQEKBAQHAgMSBKMCBCMadyBNZXNzYWdlcyBhcmUgYXV0
b21hdGljYWxseSB3cml0dGVuIGZyb20gdGhlIFB1Yi9TdWIgTGl0ZSB0b3BpYyBhc3NvY2lh
dGVkCiB3aXRoIHRoaXMgc3Vic2NyaXB0aW9uIHRvIGEgUHViL1N1YiB0b3BpYy4KCg0KBQQH
AgMGEgSjAgQQCg0KBQQHAgMBEgSjAhEeCg0KBQQHAgMDEgSjAiEiCnMKAgQIEgapAgC4AgEa
ZSBBIHRhcmdldCBwdWJsaXNoIG9yIGV2ZW50IHRpbWUuIENhbiBiZSB1c2VkIGZvciBzZWVr
aW5nIHRvIG9yIHJldHJpZXZpbmcgdGhlCiBjb3JyZXNwb25kaW5nIGN1cnNvci4KCgsKAwQI
ARIEqQIIEgo0CgQECAgAEgarAgK3AgMaJCBUaGUgdHlwZSBvZiBtZXNzYWdlIHRpbWUgdG8g
cXVlcnkuCgoNCgUECAgAARIEqwIIDArFAQoEBAgCABIErwIELxq2ASBSZXF1ZXN0IHRoZSBj
dXJzb3Igb2YgdGhlIGZpcnN0IG1lc3NhZ2Ugd2l0aCBwdWJsaXNoIHRpbWUgZ3JlYXRlciB0
aGFuIG9yCiBlcXVhbCB0byBgcHVibGlzaF90aW1lYC4gQWxsIG1lc3NhZ2VzIHRoZXJlYWZ0
ZXIgYXJlIGd1YXJhbnRlZWQgdG8gaGF2ZQogcHVibGlzaCB0aW1lcyA+PSBgcHVibGlzaF90
aW1lYC4KCg0KBQQIAgAGEgSvAgQdCg0KBQQIAgABEgSvAh4qCg0KBQQIAgADEgSvAi0uCtgC
CgQECAIBEgS2AgQtGskCIFJlcXVlc3QgdGhlIGN1cnNvciBvZiB0aGUgZmlyc3QgbWVzc2Fn
ZSB3aXRoIGV2ZW50IHRpbWUgZ3JlYXRlciB0aGFuIG9yCiBlcXVhbCB0byBgZXZlbnRfdGlt
ZWAuIElmIG1lc3NhZ2VzIGFyZSBtaXNzaW5nIGFuIGV2ZW50IHRpbWUsIHRoZSBwdWJsaXNo
CiB0aW1lIGlzIHVzZWQgYXMgYSBmYWxsYmFjay4gQXMgZXZlbnQgdGltZXMgYXJlIHVzZXIg
c3VwcGxpZWQsIHN1YnNlcXVlbnQKIG1lc3NhZ2VzIG1heSBoYXZlIGV2ZW50IHRpbWVzIGxl
c3MgdGhhbiBgZXZlbnRfdGltZWAgYW5kIHNob3VsZCBiZQogZmlsdGVyZWQgYnkgdGhlIGNs
aWVudCwgaWYgbmVjZXNzYXJ5LgoKDQoFBAgCAQYSBLYCBB0KDQoFBAgCAQESBLYCHigKDQoF
BAgCAQMSBLYCKyxiBnByb3RvMw==
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Pubsublite::V1::Common::AttributeValues ===
    # Fields for AttributeValues
    # Field: values Type: 12 ()

# === Message: Google::Cloud::Pubsublite::V1::Common::PubSubMessage ===
    # Fields for PubSubMessage
    # Field: key Type: 12 ()
    # Field: data Type: 12 ()
    # Field: attributes Type: 11 (.google.cloud.pubsublite.v1.PubSubMessage.AttributesEntry)
    # Field: event_time Type: 11 (.google.protobuf.Timestamp)

# === Message: Google::Cloud::Pubsublite::V1::Common::Cursor ===
    # Fields for Cursor
    # Field: offset Type: 3 ()

# === Message: Google::Cloud::Pubsublite::V1::Common::SequencedMessage ===
    # Fields for SequencedMessage
    # Field: cursor Type: 11 (.google.cloud.pubsublite.v1.Cursor)
    # Field: publish_time Type: 11 (.google.protobuf.Timestamp)
    # Field: message Type: 11 (.google.cloud.pubsublite.v1.PubSubMessage)
    # Field: size_bytes Type: 3 ()

# === Message: Google::Cloud::Pubsublite::V1::Common::Reservation ===
    # Fields for Reservation
    # Field: name Type: 9 ()
    # Field: throughput_capacity Type: 3 ()

# === Message: Google::Cloud::Pubsublite::V1::Common::Topic ===
    # Fields for Topic
    # Field: name Type: 9 ()
    # Field: partition_config Type: 11 (.google.cloud.pubsublite.v1.Topic.PartitionConfig)
    # Field: retention_config Type: 11 (.google.cloud.pubsublite.v1.Topic.RetentionConfig)
    # Field: reservation_config Type: 11 (.google.cloud.pubsublite.v1.Topic.ReservationConfig)

# === Message: Google::Cloud::Pubsublite::V1::Common::Subscription ===
    # Fields for Subscription
    # Field: name Type: 9 ()
    # Field: topic Type: 9 ()
    # Field: delivery_config Type: 11 (.google.cloud.pubsublite.v1.Subscription.DeliveryConfig)
    # Field: export_config Type: 11 (.google.cloud.pubsublite.v1.ExportConfig)

# === Message: Google::Cloud::Pubsublite::V1::Common::ExportConfig ===
    # Fields for ExportConfig
    # Field: desired_state Type: 14 (.google.cloud.pubsublite.v1.ExportConfig.State)
    # Field: current_state Type: 14 (.google.cloud.pubsublite.v1.ExportConfig.State)
    # Field: dead_letter_topic Type: 9 ()
    # Field: pubsub_config Type: 11 (.google.cloud.pubsublite.v1.ExportConfig.PubSubConfig)

# Enum: ExportConfig::State
our $ExportConfig_STATE_UNSPECIFIED = 0;
our $ExportConfig_ACTIVE = 1;
our $ExportConfig_PAUSED = 2;
our $ExportConfig_PERMISSION_DENIED = 3;
our $ExportConfig_NOT_FOUND = 4;

# === Message: Google::Cloud::Pubsublite::V1::Common::TimeTarget ===
    # Fields for TimeTarget
    # Field: publish_time Type: 11 (.google.protobuf.Timestamp)
    # Field: event_time Type: 11 (.google.protobuf.Timestamp)

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Pubsublite::V1::Common - Compiled Protocol Buffers messages for google/cloud/pubsublite/v1/common.proto

=head1 SYNOPSIS

    use Google::Cloud::Pubsublite::V1::Common;

    my $msg = Google::Cloud::Pubsublite::V1::Common::AttributeValues->new({
        values => $values,
    });

    # Read or update a field
    my $val = $msg->values();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Pubsublite::V1::Common::AttributeValues->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/pubsublite/v1/common.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Pubsublite::V1::Common::AttributeValues

The values associated with a key of an attribute.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->values() >> / C<< $msg->values($value) >>

Type: C<Bytes>

The list of values associated with a key.

=back

=head2 Google::Cloud::Pubsublite::V1::Common::PubSubMessage

A message that is published by publishers and delivered to subscribers.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->key() >> / C<< $msg->key($value) >>

Type: C<Bytes>

The key used for routing messages to partitions or for compaction (e.g.,
keep the last N messages per key). If the key is empty, the message is
routed to an arbitrary partition.

=item * C<< $msg->data() >> / C<< $msg->data($value) >>

Type: C<Bytes>

The payload of the message.

=item * C<< $msg->attributes() >> / C<< $msg->attributes($value) >>

Type: C<Message> (L<Google::Cloud::Pubsublite::V1::Common::PubSubMessage::AttributesEntry>)

Optional attributes that can be used for message metadata/headers.

=item * C<< $msg->event_time() >> / C<< $msg->event_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

An optional, user-specified event time.

=back

=head2 Google::Cloud::Pubsublite::V1::Common::Cursor

A cursor that describes the position of a message within a topic partition.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->offset() >> / C<< $msg->offset($value) >>

Type: C<Int64>

The offset of a message within a topic partition. Must be greater than or
equal 0.

=back

=head2 Google::Cloud::Pubsublite::V1::Common::SequencedMessage

A message that has been stored and sequenced by the Pub/Sub Lite system.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->cursor() >> / C<< $msg->cursor($value) >>

Type: C<Message> (L<Google::Cloud::Pubsublite::V1::Common::Cursor>)

The position of a message within the partition where it is stored.

=item * C<< $msg->publish_time() >> / C<< $msg->publish_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

The time when the message was received by the server when it was first
published.

=item * C<< $msg->message() >> / C<< $msg->message($value) >>

Type: C<Message> (L<Google::Cloud::Pubsublite::V1::Common::PubSubMessage>)

The user message.

=item * C<< $msg->size_bytes() >> / C<< $msg->size_bytes($value) >>

Type: C<Int64>

The size in bytes of this message for flow control and quota purposes.

=back

=head2 Google::Cloud::Pubsublite::V1::Common::Reservation

Metadata about a reservation resource.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

The name of the reservation.
Structured like:
projects/{project_number}/locations/{location}/reservations/{reservation_id}

=item * C<< $msg->throughput_capacity() >> / C<< $msg->throughput_capacity($value) >>

Type: C<Int64>

The reserved throughput capacity. Every unit of throughput capacity is
equivalent to 1 MiB/s of published messages or 2 MiB/s of subscribed
messages.

Any topics which are declared as using capacity from a Reservation will
consume resources from this reservation instead of being charged
individually.

=back

=head2 Google::Cloud::Pubsublite::V1::Common::Topic

Metadata about a topic resource.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

The name of the topic.
Structured like:
projects/{project_number}/locations/{location}/topics/{topic_id}

=item * C<< $msg->partition_config() >> / C<< $msg->partition_config($value) >>

Type: C<Message> (L<Google::Cloud::Pubsublite::V1::Common::Topic::PartitionConfig>)

The settings for this topic's partitions.

=item * C<< $msg->retention_config() >> / C<< $msg->retention_config($value) >>

Type: C<Message> (L<Google::Cloud::Pubsublite::V1::Common::Topic::RetentionConfig>)

The settings for this topic's message retention.

=item * C<< $msg->reservation_config() >> / C<< $msg->reservation_config($value) >>

Type: C<Message> (L<Google::Cloud::Pubsublite::V1::Common::Topic::ReservationConfig>)

The settings for this topic's Reservation usage.

=back

=head2 Google::Cloud::Pubsublite::V1::Common::Subscription

Metadata about a subscription resource.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

The name of the subscription.
Structured like:
projects/{project_number}/locations/{location}/subscriptions/{subscription_id}

=item * C<< $msg->topic() >> / C<< $msg->topic($value) >>

Type: C<String>

The name of the topic this subscription is attached to.
Structured like:
projects/{project_number}/locations/{location}/topics/{topic_id}

=item * C<< $msg->delivery_config() >> / C<< $msg->delivery_config($value) >>

Type: C<Message> (L<Google::Cloud::Pubsublite::V1::Common::Subscription::DeliveryConfig>)

The settings for this subscription's message delivery.

=item * C<< $msg->export_config() >> / C<< $msg->export_config($value) >>

Type: C<Message> (L<Google::Cloud::Pubsublite::V1::Common::ExportConfig>)

If present, messages are automatically written from the Pub/Sub Lite topic
associated with this subscription to a destination.

=back

=head2 Google::Cloud::Pubsublite::V1::Common::ExportConfig

Configuration for a Pub/Sub Lite subscription that writes messages to a
destination. User subscriber clients must not connect to this subscription.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->desired_state() >> / C<< $msg->desired_state($value) >>

Type: C<Enum> (L<Google::Cloud::Pubsublite::V1::ExportConfig::State>)

The desired state of this export. Setting this to values other than
`ACTIVE` and `PAUSED` will result in an error.

=item * C<< $msg->current_state() >> / C<< $msg->current_state($value) >>

Type: C<Enum> (L<Google::Cloud::Pubsublite::V1::ExportConfig::State>)

Output only. The current state of the export, which may be different to the
desired state due to errors. This field is output only.

=item * C<< $msg->dead_letter_topic() >> / C<< $msg->dead_letter_topic($value) >>

Type: C<String>

Optional. The name of an optional Pub/Sub Lite topic to publish messages
that can not be exported to the destination. For example, the message can
not be published to the Pub/Sub service because it does not satisfy the
constraints documented at https://cloud.google.com/pubsub/docs/publisher.

Structured like:
projects/{project_number}/locations/{location}/topics/{topic_id}.
Must be within the same project and location as the subscription. The topic
may be changed or removed.

=item * C<< $msg->pubsub_config() >> / C<< $msg->pubsub_config($value) >>

Type: C<Message> (L<Google::Cloud::Pubsublite::V1::Common::ExportConfig::PubSubConfig>)

Messages are automatically written from the Pub/Sub Lite topic associated
with this subscription to a Pub/Sub topic.

=back

=head3 Enum: ExportConfig::State

=over 4

=item * C<STATE_UNSPECIFIED> => C<0>

=item * C<ACTIVE> => C<1>

=item * C<PAUSED> => C<2>

=item * C<PERMISSION_DENIED> => C<3>

=item * C<NOT_FOUND> => C<4>

=back

=head2 Google::Cloud::Pubsublite::V1::Common::TimeTarget

A target publish or event time. Can be used for seeking to or retrieving the
corresponding cursor.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->publish_time() >> / C<< $msg->publish_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Request the cursor of the first message with publish time greater than or
equal to `publish_time`. All messages thereafter are guaranteed to have
publish times >= `publish_time`.

=item * C<< $msg->event_time() >> / C<< $msg->event_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Request the cursor of the first message with event time greater than or
equal to `event_time`. If messages are missing an event time, the publish
time is used as a fallback. As event times are user supplied, subsequent
messages may have event times less than `event_time` and should be
filtered by the client, if necessary.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Pubsublite::V1::Common::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
