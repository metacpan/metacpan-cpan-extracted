package Google::Cloud::Billing::Budgets::V1beta1::BudgetModel;

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
    eval { require Google::Protobuf::Struct };
    eval { require Google::Type::Date };
    eval { require Google::Type::Money };
    my $descriptor_b64 = <<'EOF';
Cjdnb29nbGUvY2xvdWQvYmlsbGluZy9idWRnZXRzL3YxYmV0YTEvYnVkZ2V0X21vZGVsLnBy
b3RvEiRnb29nbGUuY2xvdWQuYmlsbGluZy5idWRnZXRzLnYxYmV0YTEaH2dvb2dsZS9hcGkv
ZmllbGRfYmVoYXZpb3IucHJvdG8aGWdvb2dsZS9hcGkvcmVzb3VyY2UucHJvdG8aHGdvb2ds
ZS9wcm90b2J1Zi9zdHJ1Y3QucHJvdG8aFmdvb2dsZS90eXBlL2RhdGUucHJvdG8aF2dvb2ds
ZS90eXBlL21vbmV5LnByb3RvIq0ECgZCdWRnZXQSFwoEbmFtZRgBIAEoCUID4EEDUgRuYW1l
EiEKDGRpc3BsYXlfbmFtZRgCIAEoCVILZGlzcGxheU5hbWUSVgoNYnVkZ2V0X2ZpbHRlchgD
IAEoCzIsLmdvb2dsZS5jbG91ZC5iaWxsaW5nLmJ1ZGdldHMudjFiZXRhMS5GaWx0ZXJCA+BB
AVIMYnVkZ2V0RmlsdGVyEk8KBmFtb3VudBgEIAEoCzIyLmdvb2dsZS5jbG91ZC5iaWxsaW5n
LmJ1ZGdldHMudjFiZXRhMS5CdWRnZXRBbW91bnRCA+BBAlIGYW1vdW50EmEKD3RocmVzaG9s
ZF9ydWxlcxgFIAMoCzIzLmdvb2dsZS5jbG91ZC5iaWxsaW5nLmJ1ZGdldHMudjFiZXRhMS5U
aHJlc2hvbGRSdWxlQgPgQQFSDnRocmVzaG9sZFJ1bGVzEmMKEGFsbF91cGRhdGVzX3J1bGUY
BiABKAsyNC5nb29nbGUuY2xvdWQuYmlsbGluZy5idWRnZXRzLnYxYmV0YTEuQWxsVXBkYXRl
c1J1bGVCA+BBAVIOYWxsVXBkYXRlc1J1bGUSFwoEZXRhZxgHIAEoCUID4EEBUgRldGFnOl3q
QVoKJGJpbGxpbmdidWRnZXRzLmdvb2dsZWFwaXMuY29tL0J1ZGdldBIyYmlsbGluZ0FjY291
bnRzL3tiaWxsaW5nX2FjY291bnR9L2J1ZGdldHMve2J1ZGdldH0iyAEKDEJ1ZGdldEFtb3Vu
dBI/ChBzcGVjaWZpZWRfYW1vdW50GAEgASgLMhIuZ29vZ2xlLnR5cGUuTW9uZXlIAFIPc3Bl
Y2lmaWVkQW1vdW50EmYKEmxhc3RfcGVyaW9kX2Ftb3VudBgCIAEoCzI2Lmdvb2dsZS5jbG91
ZC5iaWxsaW5nLmJ1ZGdldHMudjFiZXRhMS5MYXN0UGVyaW9kQW1vdW50SABSEGxhc3RQZXJp
b2RBbW91bnRCDwoNYnVkZ2V0X2Ftb3VudCISChBMYXN0UGVyaW9kQW1vdW50IusBCg1UaHJl
c2hvbGRSdWxlEjAKEXRocmVzaG9sZF9wZXJjZW50GAEgASgBQgPgQQJSEHRocmVzaG9sZFBl
cmNlbnQSXwoLc3BlbmRfYmFzaXMYAiABKA4yOS5nb29nbGUuY2xvdWQuYmlsbGluZy5idWRn
ZXRzLnYxYmV0YTEuVGhyZXNob2xkUnVsZS5CYXNpc0ID4EEBUgpzcGVuZEJhc2lzIkcKBUJh
c2lzEhUKEUJBU0lTX1VOU1BFQ0lGSUVEEAASEQoNQ1VSUkVOVF9TUEVORBABEhQKEEZPUkVD
QVNURURfU1BFTkQQAiLJAgoOQWxsVXBkYXRlc1J1bGUSJgoMcHVic3ViX3RvcGljGAEgASgJ
QgPgQQFSC3B1YnN1YlRvcGljEioKDnNjaGVtYV92ZXJzaW9uGAIgASgJQgPgQQFSDXNjaGVt
YVZlcnNpb24STQogbW9uaXRvcmluZ19ub3RpZmljYXRpb25fY2hhbm5lbHMYAyADKAlCA+BB
AVIebW9uaXRvcmluZ05vdGlmaWNhdGlvbkNoYW5uZWxzEkgKHmRpc2FibGVfZGVmYXVsdF9p
YW1fcmVjaXBpZW50cxgEIAEoCEID4EEBUhtkaXNhYmxlRGVmYXVsdElhbVJlY2lwaWVudHMS
SgofZW5hYmxlX3Byb2plY3RfbGV2ZWxfcmVjaXBpZW50cxgFIAEoCEID4EEBUhxlbmFibGVQ
cm9qZWN0TGV2ZWxSZWNpcGllbnRzIuEGCgZGaWx0ZXISHwoIcHJvamVjdHMYASADKAlCA+BB
AVIIcHJvamVjdHMSMgoScmVzb3VyY2VfYW5jZXN0b3JzGAIgAygJQgPgQQFSEXJlc291cmNl
QW5jZXN0b3JzEiYKDGNyZWRpdF90eXBlcxgHIAMoCUID4EEBUgtjcmVkaXRUeXBlcxJ8ChZj
cmVkaXRfdHlwZXNfdHJlYXRtZW50GAQgASgOMkEuZ29vZ2xlLmNsb3VkLmJpbGxpbmcuYnVk
Z2V0cy52MWJldGExLkZpbHRlci5DcmVkaXRUeXBlc1RyZWF0bWVudEID4EEBUhRjcmVkaXRU
eXBlc1RyZWF0bWVudBIfCghzZXJ2aWNlcxgDIAMoCUID4EEBUghzZXJ2aWNlcxIlCgtzdWJh
Y2NvdW50cxgFIAMoCUID4EEBUgtzdWJhY2NvdW50cxJVCgZsYWJlbHMYBiADKAsyOC5nb29n
bGUuY2xvdWQuYmlsbGluZy5idWRnZXRzLnYxYmV0YTEuRmlsdGVyLkxhYmVsc0VudHJ5QgPg
QQFSBmxhYmVscxJkCg9jYWxlbmRhcl9wZXJpb2QYCCABKA4yNC5nb29nbGUuY2xvdWQuYmls
bGluZy5idWRnZXRzLnYxYmV0YTEuQ2FsZW5kYXJQZXJpb2RCA+BBAUgAUg5jYWxlbmRhclBl
cmlvZBJeCg1jdXN0b21fcGVyaW9kGAkgASgLMjIuZ29vZ2xlLmNsb3VkLmJpbGxpbmcuYnVk
Z2V0cy52MWJldGExLkN1c3RvbVBlcmlvZEID4EEBSABSDGN1c3RvbVBlcmlvZBpVCgtMYWJl
bHNFbnRyeRIQCgNrZXkYASABKAlSA2tleRIwCgV2YWx1ZRgCIAEoCzIaLmdvb2dsZS5wcm90
b2J1Zi5MaXN0VmFsdWVSBXZhbHVlOgI4ASKPAQoUQ3JlZGl0VHlwZXNUcmVhdG1lbnQSJgoi
Q1JFRElUX1RZUEVTX1RSRUFUTUVOVF9VTlNQRUNJRklFRBAAEhcKE0lOQ0xVREVfQUxMX0NS
RURJVFMQARIXChNFWENMVURFX0FMTF9DUkVESVRTEAISHQoZSU5DTFVERV9TUEVDSUZJRURf
Q1JFRElUUxADQg4KDHVzYWdlX3BlcmlvZCJ4CgxDdXN0b21QZXJpb2QSNQoKc3RhcnRfZGF0
ZRgBIAEoCzIRLmdvb2dsZS50eXBlLkRhdGVCA+BBAlIJc3RhcnREYXRlEjEKCGVuZF9kYXRl
GAIgASgLMhEuZ29vZ2xlLnR5cGUuRGF0ZUID4EEBUgdlbmREYXRlKlMKDkNhbGVuZGFyUGVy
aW9kEh8KG0NBTEVOREFSX1BFUklPRF9VTlNQRUNJRklFRBAAEgkKBU1PTlRIEAESCwoHUVVB
UlRFUhACEggKBFlFQVIQA0JwCihjb20uZ29vZ2xlLmNsb3VkLmJpbGxpbmcuYnVkZ2V0cy52
MWJldGExUAFaQmNsb3VkLmdvb2dsZS5jb20vZ28vYmlsbGluZy9idWRnZXRzL2FwaXYxYmV0
YTEvYnVkZ2V0c3BiO2J1ZGdldHNwYkqEegoHEgUOANYCAQq8BAoBDBIDDgASMrEEIENvcHly
aWdodCAyMDI1IEdvb2dsZSBMTEMKCiBMaWNlbnNlZCB1bmRlciB0aGUgQXBhY2hlIExpY2Vu
c2UsIFZlcnNpb24gMi4wICh0aGUgIkxpY2Vuc2UiKTsKIHlvdSBtYXkgbm90IHVzZSB0aGlz
IGZpbGUgZXhjZXB0IGluIGNvbXBsaWFuY2Ugd2l0aCB0aGUgTGljZW5zZS4KIFlvdSBtYXkg
b2J0YWluIGEgY29weSBvZiB0aGUgTGljZW5zZSBhdAoKICAgICBodHRwOi8vd3d3LmFwYWNo
ZS5vcmcvbGljZW5zZXMvTElDRU5TRS0yLjAKCiBVbmxlc3MgcmVxdWlyZWQgYnkgYXBwbGlj
YWJsZSBsYXcgb3IgYWdyZWVkIHRvIGluIHdyaXRpbmcsIHNvZnR3YXJlCiBkaXN0cmlidXRl
ZCB1bmRlciB0aGUgTGljZW5zZSBpcyBkaXN0cmlidXRlZCBvbiBhbiAiQVMgSVMiIEJBU0lT
LAogV0lUSE9VVCBXQVJSQU5USUVTIE9SIENPTkRJVElPTlMgT0YgQU5ZIEtJTkQsIGVpdGhl
ciBleHByZXNzIG9yIGltcGxpZWQuCiBTZWUgdGhlIExpY2Vuc2UgZm9yIHRoZSBzcGVjaWZp
YyBsYW5ndWFnZSBnb3Zlcm5pbmcgcGVybWlzc2lvbnMgYW5kCiBsaW1pdGF0aW9ucyB1bmRl
ciB0aGUgTGljZW5zZS4KCggKAQISAxAALQoJCgIDABIDEgApCgkKAgMBEgMTACMKCQoCAwIS
AxQAJgoJCgIDAxIDFQAgCgkKAgMEEgMWACEKCAoBCBIDGABZCgkKAggLEgMYAFkKCAoBCBID
GQAiCgkKAggKEgMZACIKCAoBCBIDGgBBCgkKAggBEgMaAEEK1wIKAgQAEgQhAEkBGsoCIEEg
YnVkZ2V0IGlzIGEgcGxhbiB0aGF0IGRlc2NyaWJlcyB3aGF0IHlvdSBleHBlY3QgdG8gc3Bl
bmQgb24gQ2xvdWQKIHByb2plY3RzLCBwbHVzIHRoZSBydWxlcyB0byBleGVjdXRlIGFzIHNw
ZW5kIGlzIHRyYWNrZWQgYWdhaW5zdCB0aGF0IHBsYW4sCiAoZm9yIGV4YW1wbGUsIHNlbmQg
YW4gYWxlcnQgd2hlbiA5MCUgb2YgdGhlIHRhcmdldCBzcGVuZCBpcyBtZXQpLgogVGhlIGJ1
ZGdldCB0aW1lIHBlcmlvZCBpcyBjb25maWd1cmFibGUsIHdpdGggb3B0aW9ucyBzdWNoIGFz
IG1vbnRoIChkZWZhdWx0KSwKIHF1YXJ0ZXIsIHllYXIsIG9yIGN1c3RvbSB0aW1lIHBlcmlv
ZC4KCgoKAwQAARIDIQgOCgsKAwQABxIEIgIlBAoNCgUEAAedCBIEIgIlBAq8AQoEBAACABID
KgI+Gq4BIE91dHB1dCBvbmx5LiBSZXNvdXJjZSBuYW1lIG9mIHRoZSBidWRnZXQuCiBUaGUg
cmVzb3VyY2UgbmFtZSBpbXBsaWVzIHRoZSBzY29wZSBvZiBhIGJ1ZGdldC4gVmFsdWVzIGFy
ZSBvZiB0aGUgZm9ybQogYGJpbGxpbmdBY2NvdW50cy97YmlsbGluZ0FjY291bnRJZH0vYnVk
Z2V0cy97YnVkZ2V0SWR9YC4KCgwKBQQAAgAFEgMqAggKDAoFBAACAAESAyoJDQoMCgUEAAIA
AxIDKhARCgwKBQQAAgAIEgMqEj0KDwoIBAACAAicCAASAyoTPApKCgQEAAIBEgMuAhoaPSBV
c2VyIGRhdGEgZm9yIGRpc3BsYXkgbmFtZSBpbiBVSS4KIFZhbGlkYXRpb246IDw9IDYwIGNo
YXJzLgoKDAoFBAACAQUSAy4CCAoMCgUEAAIBARIDLgkVCgwKBQQAAgEDEgMuGBkK0wEKBAQA
AgISAzMCRBrFASBPcHRpb25hbC4gRmlsdGVycyB0aGF0IGRlZmluZSB3aGljaCByZXNvdXJj
ZXMgYXJlIHVzZWQgdG8gY29tcHV0ZSB0aGUKIGFjdHVhbCBzcGVuZCBhZ2FpbnN0IHRoZSBi
dWRnZXQgYW1vdW50LCBzdWNoIGFzIHByb2plY3RzLCBzZXJ2aWNlcywgYW5kIHRoZQogYnVk
Z2V0J3MgdGltZSBwZXJpb2QsIGFzIHdlbGwgYXMgb3RoZXIgZmlsdGVycy4KCgwKBQQAAgIG
EgMzAggKDAoFBAACAgESAzMJFgoMCgUEAAICAxIDMxkaCgwKBQQAAgIIEgMzG0MKDwoIBAAC
AgicCAASAzMcQgopCgQEAAIDEgM2AkMaHCBSZXF1aXJlZC4gQnVkZ2V0ZWQgYW1vdW50LgoK
DAoFBAACAwYSAzYCDgoMCgUEAAIDARIDNg8VCgwKBQQAAgMDEgM2GBkKDAoFBAACAwgSAzYa
QgoPCggEAAIDCJwIABIDNhtBCvIBCgQEAAIEEgQ+Aj8vGuMBIE9wdGlvbmFsLiBSdWxlcyB0
aGF0IHRyaWdnZXIgYWxlcnRzIChub3RpZmljYXRpb25zIG9mIHRocmVzaG9sZHMKIGJlaW5n
IGNyb3NzZWQpIHdoZW4gc3BlbmQgZXhjZWVkcyB0aGUgc3BlY2lmaWVkIHBlcmNlbnRhZ2Vz
IG9mIHRoZSBidWRnZXQuCgogT3B0aW9uYWwgZm9yIGBwdWJzdWJUb3BpY2Agbm90aWZpY2F0
aW9ucy4KCiBSZXF1aXJlZCBpZiB1c2luZyBlbWFpbCBub3RpZmljYXRpb25zLgoKDAoFBAAC
BAQSAz4CCgoMCgUEAAIEBhIDPgsYCgwKBQQAAgQBEgM+GSgKDAoFBAACBAMSAz4rLAoMCgUE
AAIECBIDPwYuCg8KCAQAAgQInAgAEgM/By0KZAoEBAACBRIDQwJPGlcgT3B0aW9uYWwuIFJ1
bGVzIHRvIGFwcGx5IHRvIG5vdGlmaWNhdGlvbnMgc2VudCBiYXNlZCBvbiBidWRnZXQgc3Bl
bmQgYW5kCiB0aHJlc2hvbGRzLgoKDAoFBAACBQYSA0MCEAoMCgUEAAIFARIDQxEhCgwKBQQA
AgUDEgNDJCUKDAoFBAACBQgSA0MmTgoPCggEAAIFCJwIABIDQydNCqsBCgQEAAIGEgNIAjsa
nQEgT3B0aW9uYWwuIEV0YWcgdG8gdmFsaWRhdGUgdGhhdCB0aGUgb2JqZWN0IGlzIHVuY2hh
bmdlZCBmb3IgYQogcmVhZC1tb2RpZnktd3JpdGUgb3BlcmF0aW9uLgogQW4gZW1wdHkgZXRh
ZyB3aWxsIGNhdXNlIGFuIHVwZGF0ZSB0byBvdmVyd3JpdGUgb3RoZXIgY2hhbmdlcy4KCgwK
BQQAAgYFEgNIAggKDAoFBAACBgESA0gJDQoMCgUEAAIGAxIDSBARCgwKBQQAAgYIEgNIEjoK
DwoIBAACBgicCAASA0gTOQo4CgIEARIETABdARosIFRoZSBidWRnZXRlZCBhbW91bnQgZm9y
IGVhY2ggdXNhZ2UgcGVyaW9kLgoKCgoDBAEBEgNMCBQKQwoEBAEIABIETgJcAxo1IFNwZWNp
ZmljYXRpb24gZm9yIHdoYXQgYW1vdW50IHRvIHVzZSBhcyB0aGUgYnVkZ2V0LgoKDAoFBAEI
AAESA04IFQq5AgoEBAECABIDVAQrGqsCIEEgc3BlY2lmaWVkIGFtb3VudCB0byB1c2UgYXMg
dGhlIGJ1ZGdldC4KIGBjdXJyZW5jeV9jb2RlYCBpcyBvcHRpb25hbC4gSWYgc3BlY2lmaWVk
IHdoZW4gY3JlYXRpbmcgYSBidWRnZXQsIGl0IG11c3QKIG1hdGNoIHRoZSBjdXJyZW5jeSBv
ZiB0aGUgYmlsbGluZyBhY2NvdW50LiBJZiBzcGVjaWZpZWQgd2hlbiB1cGRhdGluZyBhCiBi
dWRnZXQsIGl0IG11c3QgbWF0Y2ggdGhlIGN1cnJlbmN5X2NvZGUgb2YgdGhlIGV4aXN0aW5n
IGJ1ZGdldC4KIFRoZSBgY3VycmVuY3lfY29kZWAgaXMgcHJvdmlkZWQgb24gb3V0cHV0LgoK
DAoFBAECAAYSA1QEFQoMCgUEAQIAARIDVBYmCgwKBQQBAgADEgNUKSoK7wIKBAQBAgESA1sE
LBrhAiBVc2UgdGhlIGxhc3QgcGVyaW9kJ3MgYWN0dWFsIHNwZW5kIGFzIHRoZSBidWRnZXQg
Zm9yIHRoZSBwcmVzZW50IHBlcmlvZC4KIExhc3RQZXJpb2RBbW91bnQgY2FuIG9ubHkgYmUg
c2V0IHdoZW4gdGhlIGJ1ZGdldCdzIHRpbWUgcGVyaW9kIGlzIGEKIFtGaWx0ZXIuY2FsZW5k
YXJfcGVyaW9kXVtnb29nbGUuY2xvdWQuYmlsbGluZy5idWRnZXRzLnYxYmV0YTEuRmlsdGVy
LmNhbGVuZGFyX3BlcmlvZF0uCiBJdCBjYW5ub3QgYmUgc2V0IGluIGNvbWJpbmF0aW9uIHdp
dGgKIFtGaWx0ZXIuY3VzdG9tX3BlcmlvZF1bZ29vZ2xlLmNsb3VkLmJpbGxpbmcuYnVkZ2V0
cy52MWJldGExLkZpbHRlci5jdXN0b21fcGVyaW9kXS4KCgwKBQQBAgEGEgNbBBQKDAoFBAEC
AQESA1sVJwoMCgUEAQIBAxIDWyorCqMECgIEAhIDaAAbGpcEIERlc2NyaWJlcyBhIGJ1ZGdl
dCBhbW91bnQgdGFyZ2V0ZWQgdG8gdGhlIGxhc3QKIFtGaWx0ZXIuY2FsZW5kYXJfcGVyaW9k
XVtnb29nbGUuY2xvdWQuYmlsbGluZy5idWRnZXRzLnYxYmV0YTEuRmlsdGVyLmNhbGVuZGFy
X3BlcmlvZF0KIHNwZW5kLiBBdCB0aGlzIHRpbWUsIHRoZSBhbW91bnQgaXMgYXV0b21hdGlj
YWxseSAxMDAlIG9mIHRoZSBsYXN0IGNhbGVuZGFyCiBwZXJpb2QncyBzcGVuZDsgdGhhdCBp
cywgdGhlcmUgYXJlIG5vIG90aGVyIG9wdGlvbnMgeWV0LgogRnV0dXJlIGNvbmZpZ3VyYXRp
b24gb3B0aW9ucyB3aWxsIGJlIGRlc2NyaWJlZCBoZXJlIChmb3IgZXhhbXBsZSwgY29uZmln
dXJpbmcKIGEgcGVyY2VudGFnZSBvZiBsYXN0IHBlcmlvZCdzIHNwZW5kKS4KIExhc3RQZXJp
b2RBbW91bnQgY2Fubm90IGJlIHNldCBmb3IgYSBidWRnZXQgY29uZmlndXJlZCB3aXRoCiBh
CiBbRmlsdGVyLmN1c3RvbV9wZXJpb2RdW2dvb2dsZS5jbG91ZC5iaWxsaW5nLmJ1ZGdldHMu
djFiZXRhMS5GaWx0ZXIuY3VzdG9tX3BlcmlvZF0uCgoKCgMEAgESA2gIGArGBwoCBAMSBoAB
AJoBARq3ByBUaHJlc2hvbGRSdWxlIGNvbnRhaW5zIHRoZSBkZWZpbml0aW9uIG9mIGEgdGhy
ZXNob2xkLiBUaHJlc2hvbGQgcnVsZXMgZGVmaW5lCiB0aGUgdHJpZ2dlcmluZyBldmVudHMg
dXNlZCB0byBnZW5lcmF0ZSBhIGJ1ZGdldCBub3RpZmljYXRpb24gZW1haWwuIFdoZW4gYQog
dGhyZXNob2xkIGlzIGNyb3NzZWQgKHNwZW5kIGV4Y2VlZHMgdGhlIHNwZWNpZmllZCBwZXJj
ZW50YWdlcyBvZiB0aGUKIGJ1ZGdldCksIGJ1ZGdldCBhbGVydCBlbWFpbHMgYXJlIHNlbnQg
dG8gdGhlIGVtYWlsIHJlY2lwaWVudHMgeW91IHNwZWNpZnkKIGluIHRoZQogW05vdGlmaWNh
dGlvbnNSdWxlXSgjbm90aWZpY2F0aW9uc3J1bGUpLgoKIFRocmVzaG9sZCBydWxlcyBhbHNv
IGFmZmVjdCB0aGUgZmllbGRzIGluY2x1ZGVkIGluIHRoZQogW0pTT04gZGF0YQogb2JqZWN0
XShodHRwczovL2Nsb3VkLmdvb2dsZS5jb20vYmlsbGluZy9kb2NzL2hvdy10by9idWRnZXRz
LXByb2dyYW1tYXRpYy1ub3RpZmljYXRpb25zI25vdGlmaWNhdGlvbl9mb3JtYXQpCiBzZW50
IHRvIGEgUHViL1N1YiB0b3BpYy4KCiBUaHJlc2hvbGQgcnVsZXMgYXJlIF9yZXF1aXJlZF8g
aWYgdXNpbmcgZW1haWwgbm90aWZpY2F0aW9ucy4KCiBUaHJlc2hvbGQgcnVsZXMgYXJlIF9v
cHRpb25hbF8gaWYgb25seSBzZXR0aW5nIGEKIFtgcHVic3ViVG9waWNgIE5vdGlmaWNhdGlv
bnNSdWxlXSgjTm90aWZpY2F0aW9uc1J1bGUpLAogdW5sZXNzIHlvdSB3YW50IHlvdXIgSlNP
TiBkYXRhIG9iamVjdCB0byBpbmNsdWRlIGRhdGEgYWJvdXQgdGhlIHRocmVzaG9sZHMKIHlv
dSBzZXQuCgogRm9yIG1vcmUgaW5mb3JtYXRpb24sIHNlZQogW3NldCBidWRnZXQgdGhyZXNo
b2xkIHJ1bGVzIGFuZAogYWN0aW9uc10oaHR0cHM6Ly9jbG91ZC5nb29nbGUuY29tL2JpbGxp
bmcvZG9jcy9ob3ctdG8vYnVkZ2V0cyNidWRnZXQtYWN0aW9ucykuCgoLCgMEAwESBIABCBUK
WAoEBAMEABIGggECkAEDGkggVGhlIHR5cGUgb2YgYmFzaXMgdXNlZCB0byBkZXRlcm1pbmUg
aWYgc3BlbmQgaGFzIHBhc3NlZCB0aGUgdGhyZXNob2xkLgoKDQoFBAMEAAESBIIBBwwKLgoG
BAMEAAIAEgSEAQQaGh4gVW5zcGVjaWZpZWQgdGhyZXNob2xkIGJhc2lzLgoKDwoHBAMEAAIA
ARIEhAEEFQoPCgcEAwQAAgACEgSEARgZClYKBgQDBAACARIEhwEEFhpGIFVzZSBjdXJyZW50
IHNwZW5kIGFzIHRoZSBiYXNpcyBmb3IgY29tcGFyaXNvbiBhZ2FpbnN0IHRoZSB0aHJlc2hv
bGQuCgoPCgcEAwQAAgEBEgSHAQQRCg8KBwQDBAACAQISBIcBFBUKgQMKBgQDBAACAhIEjwEE
GRrwAiBVc2UgZm9yZWNhc3RlZCBzcGVuZCBmb3IgdGhlIHBlcmlvZCBhcyB0aGUgYmFzaXMg
Zm9yIGNvbXBhcmlzb24gYWdhaW5zdAogdGhlIHRocmVzaG9sZC4KIEZPUkVDQVNURURfU1BF
TkQgY2FuIG9ubHkgYmUgc2V0IHdoZW4gdGhlIGJ1ZGdldCdzIHRpbWUgcGVyaW9kIGlzIGEK
IFtGaWx0ZXIuY2FsZW5kYXJfcGVyaW9kXVtnb29nbGUuY2xvdWQuYmlsbGluZy5idWRnZXRz
LnYxYmV0YTEuRmlsdGVyLmNhbGVuZGFyX3BlcmlvZF0uCiBJdCBjYW5ub3QgYmUgc2V0IGlu
IGNvbWJpbmF0aW9uIHdpdGgKIFtGaWx0ZXIuY3VzdG9tX3BlcmlvZF1bZ29vZ2xlLmNsb3Vk
LmJpbGxpbmcuYnVkZ2V0cy52MWJldGExLkZpbHRlci5jdXN0b21fcGVyaW9kXS4KCg8KBwQD
BAACAgESBI8BBBQKDwoHBAMEAAICAhIEjwEXGAqaAQoEBAMCABIElQECSBqLASBSZXF1aXJl
ZC4gU2VuZCBhbiBhbGVydCB3aGVuIHRoaXMgdGhyZXNob2xkIGlzIGV4Y2VlZGVkLgogVGhp
cyBpcyBhIDEuMC1iYXNlZCBwZXJjZW50YWdlLCBzbyAwLjUgPSA1MCUuCiBWYWxpZGF0aW9u
OiBub24tbmVnYXRpdmUgbnVtYmVyLgoKDQoFBAMCAAUSBJUBAggKDQoFBAMCAAESBJUBCRoK
DQoFBAMCAAMSBJUBHR4KDQoFBAMCAAgSBJUBH0cKEAoIBAMCAAicCAASBJUBIEYKkQEKBAQD
AgESBJkBAkEaggEgT3B0aW9uYWwuIFRoZSB0eXBlIG9mIGJhc2lzIHVzZWQgdG8gZGV0ZXJt
aW5lIGlmIHNwZW5kIGhhcyBwYXNzZWQgdGhlCiB0aHJlc2hvbGQuIEJlaGF2aW9yIGRlZmF1
bHRzIHRvIENVUlJFTlRfU1BFTkQgaWYgbm90IHNldC4KCg0KBQQDAgEGEgSZAQIHCg0KBQQD
AgEBEgSZAQgTCg0KBQQDAgEDEgSZARYXCg0KBQQDAgEIEgSZARhAChAKCAQDAgEInAgAEgSZ
ARk/CmkKAgQEEgaeAQDPAQEaWyBBbGxVcGRhdGVzUnVsZSBkZWZpbmVzIG5vdGlmaWNhdGlv
bnMgdGhhdCBhcmUgc2VudCBiYXNlZCBvbiBidWRnZXQgc3BlbmQKIGFuZCB0aHJlc2hvbGRz
LgoKCwoDBAQBEgSeAQgWCtAFCgQEBAIAEgSqAQJDGsEFIE9wdGlvbmFsLiBUaGUgbmFtZSBv
ZiB0aGUgUHViL1N1YiB0b3BpYyB3aGVyZSBidWRnZXQgcmVsYXRlZCBtZXNzYWdlcyB3aWxs
CiBiZSBwdWJsaXNoZWQsIGluIHRoZSBmb3JtIGBwcm9qZWN0cy97cHJvamVjdF9pZH0vdG9w
aWNzL3t0b3BpY19pZH1gLgogVXBkYXRlcyBhcmUgc2VudCBhdCByZWd1bGFyIGludGVydmFs
cyB0byB0aGUgdG9waWMuIFRoZSB0b3BpYyBuZWVkcyB0byBiZQogY3JlYXRlZCBiZWZvcmUg
dGhlIGJ1ZGdldCBpcyBjcmVhdGVkOyBzZWUKIGh0dHBzOi8vY2xvdWQuZ29vZ2xlLmNvbS9i
aWxsaW5nL2RvY3MvaG93LXRvL2J1ZGdldHMtcHJvZ3JhbW1hdGljLW5vdGlmaWNhdGlvbnMK
IGZvciBtb3JlIGRldGFpbHMuCiBDYWxsZXIgaXMgZXhwZWN0ZWQgdG8gaGF2ZQogYHB1YnN1
Yi50b3BpY3Muc2V0SWFtUG9saWN5YCBwZXJtaXNzaW9uIG9uIHRoZSB0b3BpYyB3aGVuIGl0
J3Mgc2V0IGZvciBhCiBidWRnZXQsIG90aGVyd2lzZSwgdGhlIEFQSSBjYWxsIHdpbGwgZmFp
bCB3aXRoIFBFUk1JU1NJT05fREVOSUVELiBTZWUKIGh0dHBzOi8vY2xvdWQuZ29vZ2xlLmNv
bS9iaWxsaW5nL2RvY3MvaG93LXRvL2J1ZGdldHMtcHJvZ3JhbW1hdGljLW5vdGlmaWNhdGlv
bnMjcGVybWlzc2lvbnNfcmVxdWlyZWRfZm9yX3RoaXNfdGFzawogZm9yIG1vcmUgZGV0YWls
cyBvbiBQdWIvU3ViIHJvbGVzIGFuZCBwZXJtaXNzaW9ucy4KCg0KBQQEAgAFEgSqAQIICg0K
BQQEAgABEgSqAQkVCg0KBQQEAgADEgSqARgZCg0KBQQEAgAIEgSqARpCChAKCAQEAgAInAgA
EgSqARtBCs4DCgQEBAIBEgSyAQJFGr8DIE9wdGlvbmFsLiBSZXF1aXJlZCB3aGVuCiBbQWxs
VXBkYXRlc1J1bGUucHVic3ViX3RvcGljXVtnb29nbGUuY2xvdWQuYmlsbGluZy5idWRnZXRz
LnYxYmV0YTEuQWxsVXBkYXRlc1J1bGUucHVic3ViX3RvcGljXQogaXMgc2V0LiBUaGUgc2No
ZW1hIHZlcnNpb24gb2YgdGhlIG5vdGlmaWNhdGlvbiBzZW50IHRvCiBbQWxsVXBkYXRlc1J1
bGUucHVic3ViX3RvcGljXVtnb29nbGUuY2xvdWQuYmlsbGluZy5idWRnZXRzLnYxYmV0YTEu
QWxsVXBkYXRlc1J1bGUucHVic3ViX3RvcGljXS4KIE9ubHkgIjEuMCIgaXMgYWNjZXB0ZWQu
IEl0IHJlcHJlc2VudHMgdGhlIEpTT04gc2NoZW1hIGFzIGRlZmluZWQgaW4KIGh0dHBzOi8v
Y2xvdWQuZ29vZ2xlLmNvbS9iaWxsaW5nL2RvY3MvaG93LXRvL2J1ZGdldHMtcHJvZ3JhbW1h
dGljLW5vdGlmaWNhdGlvbnMjbm90aWZpY2F0aW9uX2Zvcm1hdC4KCg0KBQQEAgEFEgSyAQII
Cg0KBQQEAgEBEgSyAQkXCg0KBQQEAgEDEgSyARobCg0KBQQEAgEIEgSyARxEChAKCAQEAgEI
nAgAEgSyAR1DCs8DCgQEBAICEga8AQK9AS8avgMgT3B0aW9uYWwuIFRhcmdldHMgdG8gc2Vu
ZCBub3RpZmljYXRpb25zIHRvIHdoZW4gYSB0aHJlc2hvbGQgaXMgZXhjZWVkZWQuCiBUaGlz
IGlzIGluIGFkZGl0aW9uIHRvIGRlZmF1bHQgcmVjaXBpZW50cyB3aG8gaGF2ZSBiaWxsaW5n
IGFjY291bnQgSUFNCiByb2xlcy4gVGhlIHZhbHVlIGlzIHRoZSBmdWxsIFJFU1QgcmVzb3Vy
Y2UgbmFtZSBvZiBhIG1vbml0b3JpbmcKIG5vdGlmaWNhdGlvbiBjaGFubmVsIHdpdGggdGhl
IGZvcm0KIGBwcm9qZWN0cy97cHJvamVjdF9pZH0vbm90aWZpY2F0aW9uQ2hhbm5lbHMve2No
YW5uZWxfaWR9YC4gQSBtYXhpbXVtIG9mIDUKIGNoYW5uZWxzIGFyZSBhbGxvd2VkLiBTZWUK
IGh0dHBzOi8vY2xvdWQuZ29vZ2xlLmNvbS9iaWxsaW5nL2RvY3MvaG93LXRvL2J1ZGdldHMt
bm90aWZpY2F0aW9uLXJlY2lwaWVudHMKIGZvciBtb3JlIGRldGFpbHMuCgoNCgUEBAICBBIE
vAECCgoNCgUEBAICBRIEvAELEQoNCgUEBAICARIEvAESMgoNCgUEBAICAxIEvAE1NgoNCgUE
BAICCBIEvQEGLgoQCggEBAICCJwIABIEvQEHLQr5AQoEBAQCAxIGwwECxAEvGugBIE9wdGlv
bmFsLiBXaGVuIHNldCB0byB0cnVlLCBkaXNhYmxlcyBkZWZhdWx0IG5vdGlmaWNhdGlvbnMg
c2VudCB3aGVuIGEKIHRocmVzaG9sZCBpcyBleGNlZWRlZC4gRGVmYXVsdCBub3RpZmljYXRp
b25zIGFyZSBzZW50IHRvIHRob3NlIHdpdGggQmlsbGluZwogQWNjb3VudCBBZG1pbmlzdHJh
dG9yIGFuZCBCaWxsaW5nIEFjY291bnQgVXNlciBJQU0gcm9sZXMgZm9yIHRoZSB0YXJnZXQK
IGFjY291bnQuCgoNCgUEBAIDBRIEwwECBgoNCgUEBAIDARIEwwEHJQoNCgUEBAIDAxIEwwEo
KQoNCgUEBAIDCBIExAEGLgoQCggEBAIDCJwIABIExAEHLQrZAgoEBAQCBBIGzQECzgEvGsgC
IE9wdGlvbmFsLiBXaGVuIHNldCB0byB0cnVlLCBhbmQgd2hlbiB0aGUgYnVkZ2V0IGhhcyBh
IHNpbmdsZSBwcm9qZWN0CiBjb25maWd1cmVkLCBub3RpZmljYXRpb25zIHdpbGwgYmUgc2Vu
dCB0byBwcm9qZWN0IGxldmVsIHJlY2lwaWVudHMgb2YgdGhhdAogcHJvamVjdC4gVGhpcyBm
aWVsZCB3aWxsIGJlIGlnbm9yZWQgaWYgdGhlIGJ1ZGdldCBoYXMgbXVsdGlwbGUgb3Igbm8K
IHByb2plY3QgY29uZmlndXJlZC4KCiBDdXJyZW50bHksIHByb2plY3QgbGV2ZWwgcmVjaXBp
ZW50cyBhcmUgdGhlIHVzZXJzIHdpdGggYE93bmVyYCByb2xlIG9uIGEKIGNsb3VkIHByb2pl
Y3QuCgoNCgUEBAIEBRIEzQECBgoNCgUEBAIEARIEzQEHJgoNCgUEBAIEAxIEzQEpKgoNCgUE
BAIECBIEzgEGLgoQCggEBAIECJwIABIEzgEHLQpTCgIEBRIG0gEAtgIBGkUgQSBmaWx0ZXIg
Zm9yIGEgYnVkZ2V0LCBsaW1pdGluZyB0aGUgc2NvcGUgb2YgdGhlIGNvc3QgdG8gY2FsY3Vs
YXRlLgoKCwoDBAUBEgTSAQgOCr4CCgQEBQQAEgbYAQLoAQMarQIgU3BlY2lmaWVzIGhvdyBj
cmVkaXRzIGFyZSBhcHBsaWVkIHdoZW4gZGV0ZXJtaW5pbmcgdGhlIHNwZW5kIGZvcgogdGhy
ZXNob2xkIGNhbGN1bGF0aW9ucy4gQnVkZ2V0cyB0cmFjayB0aGUgdG90YWwgY29zdCBtaW51
cyBhbnkgYXBwbGljYWJsZQogc2VsZWN0ZWQgY3JlZGl0cy4KIFtTZWUgdGhlIGRvY3VtZW50
YXRpb24gZm9yIGEgbGlzdCBvZiBjcmVkaXQKIHR5cGVzXShodHRwczovL2Nsb3VkLmdvb2ds
ZS5jb20vYmlsbGluZy9kb2NzL2hvdy10by9leHBvcnQtZGF0YS1iaWdxdWVyeS10YWJsZXMj
Y3JlZGl0cy10eXBlKS4KCg0KBQQFBAABEgTYAQcbCg4KBgQFBAACABIE2QEEKwoPCgcEBQQA
AgABEgTZAQQmCg8KBwQFBAACAAISBNkBKSoKfAoGBAUEAAIBEgTdAQQcGmwgQWxsIHR5cGVz
IG9mIGNyZWRpdCBhcmUgc3VidHJhY3RlZCBmcm9tIHRoZSBncm9zcyBjb3N0IHRvIGRldGVy
bWluZSB0aGUKIHNwZW5kIGZvciB0aHJlc2hvbGQgY2FsY3VsYXRpb25zLgoKDwoHBAUEAAIB
ARIE3QEEFwoPCgcEBQQAAgECEgTdARobCnMKBgQFBAACAhIE4QEEHBpjIEFsbCB0eXBlcyBv
ZiBjcmVkaXQgYXJlIGFkZGVkIHRvIHRoZSBuZXQgY29zdCB0byBkZXRlcm1pbmUgdGhlIHNw
ZW5kIGZvcgogdGhyZXNob2xkIGNhbGN1bGF0aW9ucy4KCg8KBwQFBAACAgESBOEBBBcKDwoH
BAUEAAICAhIE4QEaGwr1AQoGBAUEAAIDEgTnAQQiGuQBIFtDcmVkaXQKIHR5cGVzXShodHRw
czovL2Nsb3VkLmdvb2dsZS5jb20vYmlsbGluZy9kb2NzL2hvdy10by9leHBvcnQtZGF0YS1i
aWdxdWVyeS10YWJsZXMjY3JlZGl0cy10eXBlKQogc3BlY2lmaWVkIGluIHRoZSBjcmVkaXRf
dHlwZXMgZmllbGQgYXJlIHN1YnRyYWN0ZWQgZnJvbSB0aGUKIGdyb3NzIGNvc3QgdG8gZGV0
ZXJtaW5lIHRoZSBzcGVuZCBmb3IgdGhyZXNob2xkIGNhbGN1bGF0aW9ucy4KCg8KBwQFBAAC
AwESBOcBBB0KDwoHBAUEAAIDAhIE5wEgIQqiAgoEBAUCABIE7gECSBqTAiBPcHRpb25hbC4g
QSBzZXQgb2YgcHJvamVjdHMgb2YgdGhlIGZvcm0gYHByb2plY3RzL3twcm9qZWN0fWAsCiBz
cGVjaWZ5aW5nIHRoYXQgdXNhZ2UgZnJvbSBvbmx5IHRoaXMgc2V0IG9mIHByb2plY3RzIHNo
b3VsZCBiZQogaW5jbHVkZWQgaW4gdGhlIGJ1ZGdldC4gSWYgb21pdHRlZCwgdGhlIHJlcG9y
dCB3aWxsIGluY2x1ZGUgYWxsIHVzYWdlIGZvcgogdGhlIGJpbGxpbmcgYWNjb3VudCwgcmVn
YXJkbGVzcyBvZiB3aGljaCBwcm9qZWN0IHRoZSB1c2FnZSBvY2N1cnJlZCBvbi4KCg0KBQQF
AgAEEgTuAQIKCg0KBQQFAgAFEgTuAQsRCg0KBQQFAgABEgTuARIaCg0KBQQFAgADEgTuAR0e
Cg0KBQQFAgAIEgTuAR9HChAKCAQFAgAInAgAEgTuASBGCtoDCgQEBQIBEgb3AQL4AS8ayQMg
T3B0aW9uYWwuIEEgc2V0IG9mIGZvbGRlciBhbmQgb3JnYW5pemF0aW9uIG5hbWVzIG9mIHRo
ZSBmb3JtCiBgZm9sZGVycy97Zm9sZGVySWR9YCBvciBgb3JnYW5pemF0aW9ucy97b3JnYW5p
emF0aW9uSWR9YCwgc3BlY2lmeWluZyB0aGF0CiB1c2FnZSBmcm9tIG9ubHkgdGhpcyBzZXQg
b2YgZm9sZGVycyBhbmQgb3JnYW5pemF0aW9ucyBzaG91bGQgYmUgaW5jbHVkZWQgaW4KIHRo
ZSBidWRnZXQuIElmIG9taXR0ZWQsIHRoZSBidWRnZXQgaW5jbHVkZXMgYWxsIHVzYWdlIHRo
YXQgdGhlIGJpbGxpbmcKIGFjY291bnQgcGF5cyBmb3IuIElmIHRoZSBmb2xkZXIgb3Igb3Jn
YW5pemF0aW9uIGNvbnRhaW5zIHByb2plY3RzIHRoYXQgYXJlCiBwYWlkIGZvciBieSBhIGRp
ZmZlcmVudCBDbG91ZCBCaWxsaW5nIGFjY291bnQsIHRoZSBidWRnZXQgKmRvZXNuJ3QqIGFw
cGx5CiB0byB0aG9zZSBwcm9qZWN0cy4KCg0KBQQFAgEEEgT3AQIKCg0KBQQFAgEFEgT3AQsR
Cg0KBQQFAgEBEgT3ARIkCg0KBQQFAgEDEgT3AScoCg0KBQQFAgEIEgT4AQYuChAKCAQFAgEI
nAgAEgT4AQctCsgECgQEBQICEgSEAgJMGrkEIE9wdGlvbmFsLiBJZgogW0ZpbHRlci5jcmVk
aXRfdHlwZXNfdHJlYXRtZW50XVtnb29nbGUuY2xvdWQuYmlsbGluZy5idWRnZXRzLnYxYmV0
YTEuRmlsdGVyLmNyZWRpdF90eXBlc190cmVhdG1lbnRdCiBpcyBJTkNMVURFX1NQRUNJRklF
RF9DUkVESVRTLCB0aGlzIGlzIGEgbGlzdCBvZiBjcmVkaXQgdHlwZXMgdG8gYmUKIHN1YnRy
YWN0ZWQgZnJvbSBncm9zcyBjb3N0IHRvIGRldGVybWluZSB0aGUgc3BlbmQgZm9yIHRocmVz
aG9sZAogY2FsY3VsYXRpb25zLiBTZWUgW2EgbGlzdCBvZiBhY2NlcHRhYmxlIGNyZWRpdCB0
eXBlCiB2YWx1ZXNdKGh0dHBzOi8vY2xvdWQuZ29vZ2xlLmNvbS9iaWxsaW5nL2RvY3MvaG93
LXRvL2V4cG9ydC1kYXRhLWJpZ3F1ZXJ5LXRhYmxlcyNjcmVkaXRzLXR5cGUpLgoKIElmCiBb
RmlsdGVyLmNyZWRpdF90eXBlc190cmVhdG1lbnRdW2dvb2dsZS5jbG91ZC5iaWxsaW5nLmJ1
ZGdldHMudjFiZXRhMS5GaWx0ZXIuY3JlZGl0X3R5cGVzX3RyZWF0bWVudF0KIGlzICoqbm90
KiogSU5DTFVERV9TUEVDSUZJRURfQ1JFRElUUywgdGhpcyBmaWVsZCBtdXN0IGJlIGVtcHR5
LgoKDQoFBAUCAgQSBIQCAgoKDQoFBAUCAgUSBIQCCxEKDQoFBAUCAgESBIQCEh4KDQoFBAUC
AgMSBIQCISIKDQoFBAUCAggSBIQCI0sKEAoIBAUCAgicCAASBIQCJEoKUgoEBAUCAxIGhwIC
iAIvGkIgT3B0aW9uYWwuIElmIG5vdCBzZXQsIGRlZmF1bHQgYmVoYXZpb3IgaXMgYElOQ0xV
REVfQUxMX0NSRURJVFNgLgoKDQoFBAUCAwYSBIcCAhYKDQoFBAUCAwESBIcCFy0KDQoFBAUC
AwMSBIcCMDEKDQoFBAUCAwgSBIgCBi4KEAoIBAUCAwicCAASBIgCBy0K3wIKBAQFAgQSBJAC
Akga0AIgT3B0aW9uYWwuIEEgc2V0IG9mIHNlcnZpY2VzIG9mIHRoZSBmb3JtIGBzZXJ2aWNl
cy97c2VydmljZV9pZH1gLAogc3BlY2lmeWluZyB0aGF0IHVzYWdlIGZyb20gb25seSB0aGlz
IHNldCBvZiBzZXJ2aWNlcyBzaG91bGQgYmUKIGluY2x1ZGVkIGluIHRoZSBidWRnZXQuIElm
IG9taXR0ZWQsIHRoZSByZXBvcnQgd2lsbCBpbmNsdWRlIHVzYWdlIGZvcgogYWxsIHRoZSBz
ZXJ2aWNlcy4KIFRoZSBzZXJ2aWNlIG5hbWVzIGFyZSBhdmFpbGFibGUgdGhyb3VnaCB0aGUg
Q2F0YWxvZyBBUEk6CiBodHRwczovL2Nsb3VkLmdvb2dsZS5jb20vYmlsbGluZy92MS9ob3ct
dG9zL2NhdGFsb2ctYXBpLgoKDQoFBAUCBAQSBJACAgoKDQoFBAUCBAUSBJACCxEKDQoFBAUC
BAESBJACEhoKDQoFBAUCBAMSBJACHR4KDQoFBAUCBAgSBJACH0cKEAoIBAUCBAicCAASBJAC
IEYKigMKBAQFAgUSBJgCAksa+wIgT3B0aW9uYWwuIEEgc2V0IG9mIHN1YmFjY291bnRzIG9m
IHRoZSBmb3JtIGBiaWxsaW5nQWNjb3VudHMve2FjY291bnRfaWR9YCwKIHNwZWNpZnlpbmcg
dGhhdCB1c2FnZSBmcm9tIG9ubHkgdGhpcyBzZXQgb2Ygc3ViYWNjb3VudHMgc2hvdWxkIGJl
IGluY2x1ZGVkCiBpbiB0aGUgYnVkZ2V0LiBJZiBhIHN1YmFjY291bnQgaXMgc2V0IHRvIHRo
ZSBuYW1lIG9mIHRoZSBwYXJlbnQgYWNjb3VudCwKIHVzYWdlIGZyb20gdGhlIHBhcmVudCBh
Y2NvdW50IHdpbGwgYmUgaW5jbHVkZWQuIElmIG9taXR0ZWQsIHRoZQogcmVwb3J0IHdpbGwg
aW5jbHVkZSB1c2FnZSBmcm9tIHRoZSBwYXJlbnQgYWNjb3VudCBhbmQgYWxsCiBzdWJhY2Nv
dW50cywgaWYgdGhleSBleGlzdC4KCg0KBQQFAgUEEgSYAgIKCg0KBQQFAgUFEgSYAgsRCg0K
BQQFAgUBEgSYAhIdCg0KBQQFAgUDEgSYAiAhCg0KBQQFAgUIEgSYAiJKChAKCAQFAgUInAgA
EgSYAiNJCokDCgQEBQIGEgajAgKkAi8a+AIgT3B0aW9uYWwuIEEgc2luZ2xlIGxhYmVsIGFu
ZCB2YWx1ZSBwYWlyIHNwZWNpZnlpbmcgdGhhdCB1c2FnZSBmcm9tIG9ubHkKIHRoaXMgc2V0
IG9mIGxhYmVsZWQgcmVzb3VyY2VzIHNob3VsZCBiZSBpbmNsdWRlZCBpbiB0aGUgYnVkZ2V0
LiBJZiBvbWl0dGVkLAogdGhlIHJlcG9ydCB3aWxsIGluY2x1ZGUgYWxsIGxhYmVsZWQgYW5k
IHVubGFiZWxlZCB1c2FnZS4KCiBBbiBvYmplY3QgY29udGFpbmluZyBhIHNpbmdsZSBgImtl
eSI6IHZhbHVlYCBwYWlyLiBFeGFtcGxlOiBgeyAibmFtZSI6CiAid3JlbmNoIiB9YC4KCiAg
X0N1cnJlbnRseSwgbXVsdGlwbGUgZW50cmllcyBvciBtdWx0aXBsZSB2YWx1ZXMgcGVyIGVu
dHJ5IGFyZSBub3QKICBhbGxvd2VkLl8KCg0KBQQFAgYGEgSjAgIoCg0KBQQFAgYBEgSjAikv
Cg0KBQQFAgYDEgSjAjIzCg0KBQQFAgYIEgSkAgYuChAKCAQFAgYInAgAEgSkAgctCvYBCgQE
BQgAEgapAgK1AgMa5QEgTXVsdGlwbGUgb3B0aW9ucyB0byBjaG9vc2UgdGhlIGJ1ZGdldCdz
IHRpbWUgcGVyaW9kLCBzcGVjaWZ5aW5nIHRoYXQgb25seQogdXNhZ2UgdGhhdCBvY2N1cnMg
ZHVyaW5nIHRoaXMgdGltZSBwZXJpb2Qgc2hvdWxkIGJlIGluY2x1ZGVkIGluIHRoZSBidWRn
ZXQuCiBJZiBub3Qgc2V0LCB0aGUgPGNvZGU+dXNhZ2VfcGVyaW9kPC9jb2RlPiBkZWZhdWx0
cyB0byBDYWxlbmRhclBlcmlvZC5NT05USC4KCg0KBQQFCAABEgSpAggUCvgCCgQEBQIHEgSw
AgRQGukCIE9wdGlvbmFsLiBTcGVjaWZpZXMgdG8gdHJhY2sgdXNhZ2UgZm9yIHJlY3Vycmlu
ZyBjYWxlbmRhciBwZXJpb2QuCiBGb3IgZXhhbXBsZSwgYXNzdW1lIHRoYXQgQ2FsZW5kYXJQ
ZXJpb2QuUVVBUlRFUiBpcyBzZXQuIFRoZSBidWRnZXQgd2lsbAogdHJhY2sgdXNhZ2UgZnJv
bSBBcHJpbCAxIHRvIEp1bmUgMzAsIHdoZW4gdGhlIGN1cnJlbnQgY2FsZW5kYXIgbW9udGgg
aXMKIEFwcmlsLCBNYXksIEp1bmUuIEFmdGVyIHRoYXQsIGl0IHdpbGwgdHJhY2sgdXNhZ2Ug
ZnJvbSBKdWx5IDEgdG8KIFNlcHRlbWJlciAzMCB3aGVuIHRoZSBjdXJyZW50IGNhbGVuZGFy
IG1vbnRoIGlzIEp1bHksIEF1Z3VzdCwgU2VwdGVtYmVyLAogc28gb24uCgoNCgUEBQIHBhIE
sAIEEgoNCgUEBQIHARIEsAITIgoNCgUEBQIHAxIEsAIlJgoNCgUEBQIHCBIEsAInTwoQCggE
BQIHCJwIABIEsAIoTgqeAQoEBAUCCBIEtAIETBqPASBPcHRpb25hbC4gU3BlY2lmaWVzIHRv
IHRyYWNrIHVzYWdlIGZyb20gYW55IHN0YXJ0IGRhdGUgKHJlcXVpcmVkKSB0byBhbnkKIGVu
ZCBkYXRlIChvcHRpb25hbCkuIFRoaXMgdGltZSBwZXJpb2QgaXMgc3RhdGljLCBpdCBkb2Vz
IG5vdCByZWN1ci4KCg0KBQQFAggGEgS0AgQQCg0KBQQFAggBEgS0AhEeCg0KBQQFAggDEgS0
AiEiCg0KBQQFAggIEgS0AiNLChAKCAQFAggInAgAEgS0AiRKClMKAgQGEga5AgDBAgEaRSBB
bGwgZGF0ZSB0aW1lcyBiZWdpbiBhdCAxMiBBTSBVUyBhbmQgQ2FuYWRpYW4gUGFjaWZpYyBU
aW1lIChVVEMtOCkuCgoLCgMEBgESBLkCCBQKRwoEBAYCABIEuwICSxo5IFJlcXVpcmVkLiBU
aGUgc3RhcnQgZGF0ZSBtdXN0IGJlIGFmdGVyIEphbnVhcnkgMSwgMjAxNy4KCg0KBQQGAgAG
EgS7AgISCg0KBQQGAgABEgS7AhMdCg0KBQQGAgADEgS7AiAhCg0KBQQGAgAIEgS7AiJKChAK
CAQGAgAInAgAEgS7AiNJCrUBCgQEBgIBEgTAAgJJGqYBIE9wdGlvbmFsLiBUaGUgZW5kIGRh
dGUgb2YgdGhlIHRpbWUgcGVyaW9kLiBCdWRnZXRzIHdpdGggZWxhcHNlZCBlbmQgZGF0ZQog
d29uJ3QgYmUgcHJvY2Vzc2VkLiBJZiB1bnNldCwgc3BlY2lmaWVzIHRvIHRyYWNrIGFsbCB1
c2FnZSBpbmN1cnJlZCBzaW5jZQogdGhlIHN0YXJ0X2RhdGUuCgoNCgUEBgIBBhIEwAICEgoN
CgUEBgIBARIEwAITGwoNCgUEBgIBAxIEwAIeHwoNCgUEBgIBCBIEwAIgSAoQCggEBgIBCJwI
ABIEwAIhRwr3AQoCBQASBscCANYCARroASBBIGBDYWxlbmRhclBlcmlvZGAgcmVwcmVzZW50
cyB0aGUgYWJzdHJhY3QgY29uY2VwdCBvZiBhIHRpbWUgcGVyaW9kIHRoYXQKIGhhcyBhIGNh
bm9uaWNhbCBzdGFydC4gR3JhbW1hdGljYWxseSwgInRoZSBzdGFydCBvZiB0aGUgY3VycmVu
dAogYENhbGVuZGFyUGVyaW9kYCIuIEFsbCBjYWxlbmRhciB0aW1lcyBiZWdpbiBhdCAxMiBB
TSBVUyBhbmQgQ2FuYWRpYW4KIFBhY2lmaWMgVGltZSAoVVRDLTgpLgoKCwoDBQABEgTHAgUT
CngKBAUAAgASBMoCAiIaaiBDYWxlbmRhciBwZXJpb2QgaXMgdW5zZXQuIFRoaXMgaXMgdGhl
IGRlZmF1bHQgaWYgdGhlIGJ1ZGdldCBpcyBmb3IgYQogY3VzdG9tIHRpbWUgcGVyaW9kIChD
dXN0b21QZXJpb2QpLgoKDQoFBQACAAESBMoCAh0KDQoFBQACAAISBMoCICEKeQoEBQACARIE
zgICDBprIEEgbW9udGguIE1vbnRoIHN0YXJ0cyBvbiB0aGUgZmlyc3QgZGF5IG9mIGVhY2gg
bW9udGgsIHN1Y2ggYXMgSmFudWFyeSAxLAogRmVicnVhcnkgMSwgTWFyY2ggMSwgYW5kIHNv
IG9uLgoKDQoFBQACAQESBM4CAgcKDQoFBQACAQISBM4CCgsKawoEBQACAhIE0gICDhpdIEEg
cXVhcnRlci4gUXVhcnRlcnMgc3RhcnQgb24gZGF0ZXMgSmFudWFyeSAxLCBBcHJpbCAxLCBK
dWx5IDEsIGFuZCBPY3RvYmVyCiAxIG9mIGVhY2ggeWVhci4KCg0KBQUAAgIBEgTSAgIJCg0K
BQUAAgICEgTSAgwNCjEKBAUAAgMSBNUCAgsaIyBBIHllYXIuIFllYXIgc3RhcnRzIG9uIEph
bnVhcnkgMS4KCg0KBQUAAgMBEgTVAgIGCg0KBQUAAgMCEgTVAgkKYgZwcm90bzM=
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Billing::Budgets::V1beta1::BudgetModel::Budget ===
    # Fields for Budget
    # Field: name Type: 9 ()
    # Field: display_name Type: 9 ()
    # Field: budget_filter Type: 11 (.google.cloud.billing.budgets.v1beta1.Filter)
    # Field: amount Type: 11 (.google.cloud.billing.budgets.v1beta1.BudgetAmount)
    # Field: threshold_rules Type: 11 (.google.cloud.billing.budgets.v1beta1.ThresholdRule)
    # Field: all_updates_rule Type: 11 (.google.cloud.billing.budgets.v1beta1.AllUpdatesRule)
    # Field: etag Type: 9 ()

# === Message: Google::Cloud::Billing::Budgets::V1beta1::BudgetModel::BudgetAmount ===
    # Fields for BudgetAmount
    # Field: specified_amount Type: 11 (.google.type.Money)
    # Field: last_period_amount Type: 11 (.google.cloud.billing.budgets.v1beta1.LastPeriodAmount)

# === Message: Google::Cloud::Billing::Budgets::V1beta1::BudgetModel::LastPeriodAmount ===
    # Fields for LastPeriodAmount

# === Message: Google::Cloud::Billing::Budgets::V1beta1::BudgetModel::ThresholdRule ===
    # Fields for ThresholdRule
    # Field: threshold_percent Type: 1 ()
    # Field: spend_basis Type: 14 (.google.cloud.billing.budgets.v1beta1.ThresholdRule.Basis)

# Enum: ThresholdRule::Basis
our $ThresholdRule_BASIS_UNSPECIFIED = 0;
our $ThresholdRule_CURRENT_SPEND = 1;
our $ThresholdRule_FORECASTED_SPEND = 2;

# === Message: Google::Cloud::Billing::Budgets::V1beta1::BudgetModel::AllUpdatesRule ===
    # Fields for AllUpdatesRule
    # Field: pubsub_topic Type: 9 ()
    # Field: schema_version Type: 9 ()
    # Field: monitoring_notification_channels Type: 9 ()
    # Field: disable_default_iam_recipients Type: 8 ()
    # Field: enable_project_level_recipients Type: 8 ()

# === Message: Google::Cloud::Billing::Budgets::V1beta1::BudgetModel::Filter ===
    # Fields for Filter
    # Field: projects Type: 9 ()
    # Field: resource_ancestors Type: 9 ()
    # Field: credit_types Type: 9 ()
    # Field: credit_types_treatment Type: 14 (.google.cloud.billing.budgets.v1beta1.Filter.CreditTypesTreatment)
    # Field: services Type: 9 ()
    # Field: subaccounts Type: 9 ()
    # Field: labels Type: 11 (.google.cloud.billing.budgets.v1beta1.Filter.LabelsEntry)
    # Field: calendar_period Type: 14 (.google.cloud.billing.budgets.v1beta1.CalendarPeriod)
    # Field: custom_period Type: 11 (.google.cloud.billing.budgets.v1beta1.CustomPeriod)

# Enum: Filter::CreditTypesTreatment
our $Filter_CREDIT_TYPES_TREATMENT_UNSPECIFIED = 0;
our $Filter_INCLUDE_ALL_CREDITS = 1;
our $Filter_EXCLUDE_ALL_CREDITS = 2;
our $Filter_INCLUDE_SPECIFIED_CREDITS = 3;

# === Message: Google::Cloud::Billing::Budgets::V1beta1::BudgetModel::CustomPeriod ===
    # Fields for CustomPeriod
    # Field: start_date Type: 11 (.google.type.Date)
    # Field: end_date Type: 11 (.google.type.Date)

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Billing::Budgets::V1beta1::BudgetModel - Compiled Protocol Buffers messages for google/cloud/billing/budgets/v1beta1/budget_model.proto

=head1 SYNOPSIS

    use Google::Cloud::Billing::Budgets::V1beta1::BudgetModel;

    my $msg = Google::Cloud::Billing::Budgets::V1beta1::BudgetModel::Budget->new({
        name => $name,
        display_name => $display_name,
        budget_filter => $budget_filter,
        amount => $amount,
    });

    # Read or update a field
    my $val = $msg->name();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Billing::Budgets::V1beta1::BudgetModel::Budget->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/billing/budgets/v1beta1/budget_model.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Billing::Budgets::V1beta1::BudgetModel::Budget

A budget is a plan that describes what you expect to spend on Cloud
projects, plus the rules to execute as spend is tracked against that plan,
(for example, send an alert when 90% of the target spend is met).
The budget time period is configurable, with options such as month (default),
quarter, year, or custom time period.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Output only. Resource name of the budget.
The resource name implies the scope of a budget. Values are of the form
`billingAccounts/{billingAccountId}/budgets/{budgetId}`.

=item * C<< $msg->display_name() >> / C<< $msg->display_name($value) >>

Type: C<String>

User data for display name in UI.
Validation: <= 60 chars.

=item * C<< $msg->budget_filter() >> / C<< $msg->budget_filter($value) >>

Type: C<Message> (L<Google::Cloud::Billing::Budgets::V1beta1::BudgetModel::Filter>)

Optional. Filters that define which resources are used to compute the
actual spend against the budget amount, such as projects, services, and the
budget's time period, as well as other filters.

=item * C<< $msg->amount() >> / C<< $msg->amount($value) >>

Type: C<Message> (L<Google::Cloud::Billing::Budgets::V1beta1::BudgetModel::BudgetAmount>)

Required. Budgeted amount.

=item * C<< $msg->threshold_rules() >> / C<< $msg->threshold_rules($value) >>

Type: C<Message> (L<Google::Cloud::Billing::Budgets::V1beta1::BudgetModel::ThresholdRule>)

Optional. Rules that trigger alerts (notifications of thresholds
being crossed) when spend exceeds the specified percentages of the budget.

Optional for `pubsubTopic` notifications.

Required if using email notifications.

=item * C<< $msg->all_updates_rule() >> / C<< $msg->all_updates_rule($value) >>

Type: C<Message> (L<Google::Cloud::Billing::Budgets::V1beta1::BudgetModel::AllUpdatesRule>)

Optional. Rules to apply to notifications sent based on budget spend and
thresholds.

=item * C<< $msg->etag() >> / C<< $msg->etag($value) >>

Type: C<String>

Optional. Etag to validate that the object is unchanged for a
read-modify-write operation.
An empty etag will cause an update to overwrite other changes.

=back

=head2 Google::Cloud::Billing::Budgets::V1beta1::BudgetModel::BudgetAmount

The budgeted amount for each usage period.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->specified_amount() >> / C<< $msg->specified_amount($value) >>

Type: C<Message> (L<Google::Type::Money::Money>)

A specified amount to use as the budget.
`currency_code` is optional. If specified when creating a budget, it must
match the currency of the billing account. If specified when updating a
budget, it must match the currency_code of the existing budget.
The `currency_code` is provided on output.

=item * C<< $msg->last_period_amount() >> / C<< $msg->last_period_amount($value) >>

Type: C<Message> (L<Google::Cloud::Billing::Budgets::V1beta1::BudgetModel::LastPeriodAmount>)

Use the last period's actual spend as the budget for the present period.
LastPeriodAmount can only be set when the budget's time period is a
[Filter.calendar_period][google.cloud.billing.budgets.v1beta1.Filter.calendar_period].
It cannot be set in combination with
[Filter.custom_period][google.cloud.billing.budgets.v1beta1.Filter.custom_period].

=back

=head2 Google::Cloud::Billing::Budgets::V1beta1::BudgetModel::LastPeriodAmount

Describes a budget amount targeted to the last
[Filter.calendar_period][google.cloud.billing.budgets.v1beta1.Filter.calendar_period]
spend. At this time, the amount is automatically 100% of the last calendar
period's spend; that is, there are no other options yet.
Future configuration options will be described here (for example, configuring
a percentage of last period's spend).
LastPeriodAmount cannot be set for a budget configured with
a
[Filter.custom_period][google.cloud.billing.budgets.v1beta1.Filter.custom_period].

Inherits from L<Protobuf::Message>.

=head2 Google::Cloud::Billing::Budgets::V1beta1::BudgetModel::ThresholdRule

ThresholdRule contains the definition of a threshold. Threshold rules define
the triggering events used to generate a budget notification email. When a
threshold is crossed (spend exceeds the specified percentages of the
budget), budget alert emails are sent to the email recipients you specify
in the
[NotificationsRule](#notificationsrule).

Threshold rules also affect the fields included in the
[JSON data
object](https://cloud.google.com/billing/docs/how-to/budgets-programmatic-notifications#notification_format)
sent to a Pub/Sub topic.

Threshold rules are _required_ if using email notifications.

Threshold rules are _optional_ if only setting a
[`pubsubTopic` NotificationsRule](#NotificationsRule),
unless you want your JSON data object to include data about the thresholds
you set.

For more information, see
[set budget threshold rules and
actions](https://cloud.google.com/billing/docs/how-to/budgets#budget-actions).

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->threshold_percent() >> / C<< $msg->threshold_percent($value) >>

Type: C<Double>

Required. Send an alert when this threshold is exceeded.
This is a 1.0-based percentage, so 0.5 = 50%.
Validation: non-negative number.

=item * C<< $msg->spend_basis() >> / C<< $msg->spend_basis($value) >>

Type: C<Enum> (L<Google::Cloud::Billing::Budgets::V1beta1::ThresholdRule::Basis>)

Optional. The type of basis used to determine if spend has passed the
threshold. Behavior defaults to CURRENT_SPEND if not set.

=back

=head3 Enum: ThresholdRule::Basis

=over 4

=item * C<BASIS_UNSPECIFIED> => C<0>

=item * C<CURRENT_SPEND> => C<1>

=item * C<FORECASTED_SPEND> => C<2>

=back

=head2 Google::Cloud::Billing::Budgets::V1beta1::BudgetModel::AllUpdatesRule

AllUpdatesRule defines notifications that are sent based on budget spend
and thresholds.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->pubsub_topic() >> / C<< $msg->pubsub_topic($value) >>

Type: C<String>

Optional. The name of the Pub/Sub topic where budget related messages will
be published, in the form `projects/{project_id}/topics/{topic_id}`.
Updates are sent at regular intervals to the topic. The topic needs to be
created before the budget is created; see
https://cloud.google.com/billing/docs/how-to/budgets-programmatic-notifications
for more details.
Caller is expected to have
`pubsub.topics.setIamPolicy` permission on the topic when it's set for a
budget, otherwise, the API call will fail with PERMISSION_DENIED. See
https://cloud.google.com/billing/docs/how-to/budgets-programmatic-notifications#permissions_required_for_this_task
for more details on Pub/Sub roles and permissions.

=item * C<< $msg->schema_version() >> / C<< $msg->schema_version($value) >>

Type: C<String>

Optional. Required when
[AllUpdatesRule.pubsub_topic][google.cloud.billing.budgets.v1beta1.AllUpdatesRule.pubsub_topic]
is set. The schema version of the notification sent to
[AllUpdatesRule.pubsub_topic][google.cloud.billing.budgets.v1beta1.AllUpdatesRule.pubsub_topic].
Only "1.0" is accepted. It represents the JSON schema as defined in
https://cloud.google.com/billing/docs/how-to/budgets-programmatic-notifications#notification_format.

=item * C<< $msg->monitoring_notification_channels() >> / C<< $msg->monitoring_notification_channels($value) >>

Type: C<String>

Optional. Targets to send notifications to when a threshold is exceeded.
This is in addition to default recipients who have billing account IAM
roles. The value is the full REST resource name of a monitoring
notification channel with the form
`projects/{project_id}/notificationChannels/{channel_id}`. A maximum of 5
channels are allowed. See
https://cloud.google.com/billing/docs/how-to/budgets-notification-recipients
for more details.

=item * C<< $msg->disable_default_iam_recipients() >> / C<< $msg->disable_default_iam_recipients($value) >>

Type: C<Bool>

Optional. When set to true, disables default notifications sent when a
threshold is exceeded. Default notifications are sent to those with Billing
Account Administrator and Billing Account User IAM roles for the target
account.

=item * C<< $msg->enable_project_level_recipients() >> / C<< $msg->enable_project_level_recipients($value) >>

Type: C<Bool>

Optional. When set to true, and when the budget has a single project
configured, notifications will be sent to project level recipients of that
project. This field will be ignored if the budget has multiple or no
project configured.

Currently, project level recipients are the users with `Owner` role on a
cloud project.

=back

=head2 Google::Cloud::Billing::Budgets::V1beta1::BudgetModel::Filter

A filter for a budget, limiting the scope of the cost to calculate.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->projects() >> / C<< $msg->projects($value) >>

Type: C<String>

Optional. A set of projects of the form `projects/{project}`,
specifying that usage from only this set of projects should be
included in the budget. If omitted, the report will include all usage for
the billing account, regardless of which project the usage occurred on.

=item * C<< $msg->resource_ancestors() >> / C<< $msg->resource_ancestors($value) >>

Type: C<String>

Optional. A set of folder and organization names of the form
`folders/{folderId}` or `organizations/{organizationId}`, specifying that
usage from only this set of folders and organizations should be included in
the budget. If omitted, the budget includes all usage that the billing
account pays for. If the folder or organization contains projects that are
paid for by a different Cloud Billing account, the budget *doesn't* apply
to those projects.

=item * C<< $msg->credit_types() >> / C<< $msg->credit_types($value) >>

Type: C<String>

Optional. If
[Filter.credit_types_treatment][google.cloud.billing.budgets.v1beta1.Filter.credit_types_treatment]
is INCLUDE_SPECIFIED_CREDITS, this is a list of credit types to be
subtracted from gross cost to determine the spend for threshold
calculations. See [a list of acceptable credit type
values](https://cloud.google.com/billing/docs/how-to/export-data-bigquery-tables#credits-type).

If
[Filter.credit_types_treatment][google.cloud.billing.budgets.v1beta1.Filter.credit_types_treatment]
is B<not> INCLUDE_SPECIFIED_CREDITS, this field must be empty.

=item * C<< $msg->credit_types_treatment() >> / C<< $msg->credit_types_treatment($value) >>

Type: C<Enum> (L<Google::Cloud::Billing::Budgets::V1beta1::Filter::CreditTypesTreatment>)

Optional. If not set, default behavior is `INCLUDE_ALL_CREDITS`.

=item * C<< $msg->services() >> / C<< $msg->services($value) >>

Type: C<String>

Optional. A set of services of the form `services/{service_id}`,
specifying that usage from only this set of services should be
included in the budget. If omitted, the report will include usage for
all the services.
The service names are available through the Catalog API:
https://cloud.google.com/billing/v1/how-tos/catalog-api.

=item * C<< $msg->subaccounts() >> / C<< $msg->subaccounts($value) >>

Type: C<String>

Optional. A set of subaccounts of the form `billingAccounts/{account_id}`,
specifying that usage from only this set of subaccounts should be included
in the budget. If a subaccount is set to the name of the parent account,
usage from the parent account will be included. If omitted, the
report will include usage from the parent account and all
subaccounts, if they exist.

=item * C<< $msg->labels() >> / C<< $msg->labels($value) >>

Type: C<Message> (L<Google::Cloud::Billing::Budgets::V1beta1::BudgetModel::Filter::LabelsEntry>)

Optional. A single label and value pair specifying that usage from only
this set of labeled resources should be included in the budget. If omitted,
the report will include all labeled and unlabeled usage.

An object containing a single `"key": value` pair. Example: `{ "name":
"wrench" }`.

 _Currently, multiple entries or multiple values per entry are not
 allowed._

=item * C<< $msg->calendar_period() >> / C<< $msg->calendar_period($value) >>

Type: C<Enum> (L<Google::Cloud::Billing::Budgets::V1beta1::CalendarPeriod>)

Optional. Specifies to track usage for recurring calendar period.
For example, assume that CalendarPeriod.QUARTER is set. The budget will
track usage from April 1 to June 30, when the current calendar month is
April, May, June. After that, it will track usage from July 1 to
September 30 when the current calendar month is July, August, September,
so on.

=item * C<< $msg->custom_period() >> / C<< $msg->custom_period($value) >>

Type: C<Message> (L<Google::Cloud::Billing::Budgets::V1beta1::BudgetModel::CustomPeriod>)

Optional. Specifies to track usage from any start date (required) to any
end date (optional). This time period is static, it does not recur.

=back

=head3 Enum: Filter::CreditTypesTreatment

=over 4

=item * C<CREDIT_TYPES_TREATMENT_UNSPECIFIED> => C<0>

=item * C<INCLUDE_ALL_CREDITS> => C<1>

=item * C<EXCLUDE_ALL_CREDITS> => C<2>

=item * C<INCLUDE_SPECIFIED_CREDITS> => C<3>

=back

=head2 Google::Cloud::Billing::Budgets::V1beta1::BudgetModel::CustomPeriod

All date times begin at 12 AM US and Canadian Pacific Time (UTC-8).

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->start_date() >> / C<< $msg->start_date($value) >>

Type: C<Message> (L<Google::Type::Date::Date>)

Required. The start date must be after January 1, 2017.

=item * C<< $msg->end_date() >> / C<< $msg->end_date($value) >>

Type: C<Message> (L<Google::Type::Date::Date>)

Optional. The end date of the time period. Budgets with elapsed end date
won't be processed. If unset, specifies to track all usage incurred since
the start_date.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Billing::Budgets::V1beta1::BudgetModel::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
