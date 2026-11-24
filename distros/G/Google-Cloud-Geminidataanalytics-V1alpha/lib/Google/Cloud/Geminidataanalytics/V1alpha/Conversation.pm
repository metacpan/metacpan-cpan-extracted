package Google::Cloud::Geminidataanalytics::V1alpha::Conversation;

use strict;
use warnings;

our $VERSION = '0.14';

use Protobuf::Message;
use Protobuf::DescriptorPool;
use Protobuf::Internal qw(:all);
use MIME::Base64;

BEGIN {
    eval { require Google::Api::FieldBehavior };
    eval { require Google::Api::FieldInfo };
    eval { require Google::Api::Resource };
    eval { require Google::Protobuf::FieldMask };
    eval { require Google::Protobuf::Timestamp };
    my $descriptor_b64 = <<'EOF';
Cjtnb29nbGUvY2xvdWQvZ2VtaW5pZGF0YWFuYWx5dGljcy92MWFscGhhL2NvbnZlcnNhdGlv
bi5wcm90bxIoZ29vZ2xlLmNsb3VkLmdlbWluaWRhdGFhbmFseXRpY3MudjFhbHBoYRofZ29v
Z2xlL2FwaS9maWVsZF9iZWhhdmlvci5wcm90bxobZ29vZ2xlL2FwaS9maWVsZF9pbmZvLnBy
b3RvGhlnb29nbGUvYXBpL3Jlc291cmNlLnByb3RvGiBnb29nbGUvcHJvdG9idWYvZmllbGRf
bWFzay5wcm90bxofZ29vZ2xlL3Byb3RvYnVmL3RpbWVzdGFtcC5wcm90byL3BAoMQ29udmVy
c2F0aW9uEhoKBG5hbWUYASABKAlCBuBBAeBBCFIEbmFtZRIbCgZhZ2VudHMYAiADKAlCA+BB
AlIGYWdlbnRzEkAKC2NyZWF0ZV90aW1lGAMgASgLMhouZ29vZ2xlLnByb3RvYnVmLlRpbWVz
dGFtcEID4EEDUgpjcmVhdGVUaW1lEkUKDmxhc3RfdXNlZF90aW1lGAQgASgLMhouZ29vZ2xl
LnByb3RvYnVmLlRpbWVzdGFtcEID4EEDUgxsYXN0VXNlZFRpbWUSXwoGbGFiZWxzGAkgAygL
MkIuZ29vZ2xlLmNsb3VkLmdlbWluaWRhdGFhbmFseXRpY3MudjFhbHBoYS5Db252ZXJzYXRp
b24uTGFiZWxzRW50cnlCA+BBAVIGbGFiZWxzEhkKBXRpdGxlGAYgASgJQgPgQQFSBXRpdGxl
EkcKB2ttc19rZXkYCiABKAlCKeBBAfpBIwohY2xvdWRrbXMuZ29vZ2xlYXBpcy5jb20vQ3J5
cHRvS2V5SABSBmttc0tleYgBARo5CgtMYWJlbHNFbnRyeRIQCgNrZXkYASABKAlSA2tleRIU
CgV2YWx1ZRgCIAEoCVIFdmFsdWU6AjgBOpgB6kGUAQovZ2VtaW5pZGF0YWFuYWx5dGljcy5n
b29nbGVhcGlzLmNvbS9Db252ZXJzYXRpb24SRHByb2plY3RzL3twcm9qZWN0fS9sb2NhdGlv
bnMve2xvY2F0aW9ufS9jb252ZXJzYXRpb25zL3tjb252ZXJzYXRpb259Kg1jb252ZXJzYXRp
b25zMgxjb252ZXJzYXRpb25CCgoIX2ttc19rZXkipwIKGUNyZWF0ZUNvbnZlcnNhdGlvblJl
cXVlc3QSTwoGcGFyZW50GAEgASgJQjfgQQL6QTESL2dlbWluaWRhdGFhbmFseXRpY3MuZ29v
Z2xlYXBpcy5jb20vQ29udmVyc2F0aW9uUgZwYXJlbnQSLAoPY29udmVyc2F0aW9uX2lkGAIg
ASgJQgPgQQFSDmNvbnZlcnNhdGlvbklkEl8KDGNvbnZlcnNhdGlvbhgDIAEoCzI2Lmdvb2ds
ZS5jbG91ZC5nZW1pbmlkYXRhYW5hbHl0aWNzLnYxYWxwaGEuQ29udmVyc2F0aW9uQgPgQQJS
DGNvbnZlcnNhdGlvbhIqCgpyZXF1ZXN0X2lkGAQgASgJQgvijM/XCAIIAeBBAVIJcmVxdWVz
dElkIuoBChlVcGRhdGVDb252ZXJzYXRpb25SZXF1ZXN0El8KDGNvbnZlcnNhdGlvbhgBIAEo
CzI2Lmdvb2dsZS5jbG91ZC5nZW1pbmlkYXRhYW5hbHl0aWNzLnYxYWxwaGEuQ29udmVyc2F0
aW9uQgPgQQJSDGNvbnZlcnNhdGlvbhJACgt1cGRhdGVfbWFzaxgCIAEoCzIaLmdvb2dsZS5w
cm90b2J1Zi5GaWVsZE1hc2tCA+BBAVIKdXBkYXRlTWFzaxIqCgpyZXF1ZXN0X2lkGAMgASgJ
QgvijM/XCAIIAeBBAVIJcmVxdWVzdElkImUKFkdldENvbnZlcnNhdGlvblJlcXVlc3QSSwoE
bmFtZRgBIAEoCUI34EEC+kExCi9nZW1pbmlkYXRhYW5hbHl0aWNzLmdvb2dsZWFwaXMuY29t
L0NvbnZlcnNhdGlvblIEbmFtZSLOAQoYTGlzdENvbnZlcnNhdGlvbnNSZXF1ZXN0Ek8KBnBh
cmVudBgBIAEoCUI34EEC+kExEi9nZW1pbmlkYXRhYW5hbHl0aWNzLmdvb2dsZWFwaXMuY29t
L0NvbnZlcnNhdGlvblIGcGFyZW50EiAKCXBhZ2Vfc2l6ZRgCIAEoBUID4EEBUghwYWdlU2l6
ZRIiCgpwYWdlX3Rva2VuGAMgASgJQgPgQQFSCXBhZ2VUb2tlbhIbCgZmaWx0ZXIYBCABKAlC
A+BBAVIGZmlsdGVyIqEBChlMaXN0Q29udmVyc2F0aW9uc1Jlc3BvbnNlElwKDWNvbnZlcnNh
dGlvbnMYASADKAsyNi5nb29nbGUuY2xvdWQuZ2VtaW5pZGF0YWFuYWx5dGljcy52MWFscGhh
LkNvbnZlcnNhdGlvblINY29udmVyc2F0aW9ucxImCg9uZXh0X3BhZ2VfdG9rZW4YAiABKAlS
DW5leHRQYWdlVG9rZW4iaAoZRGVsZXRlQ29udmVyc2F0aW9uUmVxdWVzdBJLCgRuYW1lGAEg
ASgJQjfgQQL6QTEKL2dlbWluaWRhdGFhbmFseXRpY3MuZ29vZ2xlYXBpcy5jb20vQ29udmVy
c2F0aW9uUgRuYW1lQroDCixjb20uZ29vZ2xlLmNsb3VkLmdlbWluaWRhdGFhbmFseXRpY3Mu
djFhbHBoYUIRQ29udmVyc2F0aW9uUHJvdG9QAVpeY2xvdWQuZ29vZ2xlLmNvbS9nby9nZW1p
bmlkYXRhYW5hbHl0aWNzL2FwaXYxYWxwaGEvZ2VtaW5pZGF0YWFuYWx5dGljc3BiO2dlbWlu
aWRhdGFhbmFseXRpY3NwYqoCKEdvb2dsZS5DbG91ZC5HZW1pbmlEYXRhQW5hbHl0aWNzLlYx
QWxwaGHKAihHb29nbGVcQ2xvdWRcR2VtaW5pRGF0YUFuYWx5dGljc1xWMWFscGhh6gIrR29v
Z2xlOjpDbG91ZDo6R2VtaW5pRGF0YUFuYWx5dGljczo6VjFhbHBoYepBjwEKIWNsb3Vka21z
Lmdvb2dsZWFwaXMuY29tL0NyeXB0b0tleRJTcHJvamVjdHMve3Byb2plY3R9L2xvY2F0aW9u
cy97bG9jYXRpb259L2tleVJpbmdzL3trZXlfcmluZ30vY3J5cHRvS2V5cy97Y3J5cHRvX2tl
eX0qCmNyeXB0b0tleXMyCWNyeXB0b0tleUr1OAoHEgUOANcBAQq8BAoBDBIDDgASMrEEIENv
cHlyaWdodCAyMDI2IEdvb2dsZSBMTEMKCiBMaWNlbnNlZCB1bmRlciB0aGUgQXBhY2hlIExp
Y2Vuc2UsIFZlcnNpb24gMi4wICh0aGUgIkxpY2Vuc2UiKTsKIHlvdSBtYXkgbm90IHVzZSB0
aGlzIGZpbGUgZXhjZXB0IGluIGNvbXBsaWFuY2Ugd2l0aCB0aGUgTGljZW5zZS4KIFlvdSBt
YXkgb2J0YWluIGEgY29weSBvZiB0aGUgTGljZW5zZSBhdAoKICAgICBodHRwOi8vd3d3LmFw
YWNoZS5vcmcvbGljZW5zZXMvTElDRU5TRS0yLjAKCiBVbmxlc3MgcmVxdWlyZWQgYnkgYXBw
bGljYWJsZSBsYXcgb3IgYWdyZWVkIHRvIGluIHdyaXRpbmcsIHNvZnR3YXJlCiBkaXN0cmli
dXRlZCB1bmRlciB0aGUgTGljZW5zZSBpcyBkaXN0cmlidXRlZCBvbiBhbiAiQVMgSVMiIEJB
U0lTLAogV0lUSE9VVCBXQVJSQU5USUVTIE9SIENPTkRJVElPTlMgT0YgQU5ZIEtJTkQsIGVp
dGhlciBleHByZXNzIG9yIGltcGxpZWQuCiBTZWUgdGhlIExpY2Vuc2UgZm9yIHRoZSBzcGVj
aWZpYyBsYW5ndWFnZSBnb3Zlcm5pbmcgcGVybWlzc2lvbnMgYW5kCiBsaW1pdGF0aW9ucyB1
bmRlciB0aGUgTGljZW5zZS4KCggKAQISAxAAMQoJCgIDABIDEgApCgkKAgMBEgMTACUKCQoC
AwISAxQAIwoJCgIDAxIDFQAqCgkKAgMEEgMWACkKCAoBCBIDGABFCgkKAgglEgMYAEUKCAoB
CBIDGQB1CgkKAggLEgMZAHUKCAoBCBIDGgAiCgkKAggKEgMaACIKCAoBCBIDGwAyCgkKAggI
EgMbADIKCAoBCBIDHABFCgkKAggBEgMcAEUKCAoBCBIDHQBFCgkKAggpEgMdAEUKCAoBCBID
HgBECgkKAggtEgMeAEQKCQoBCBIEHwAkAgoMCgQInQgAEgQfACQCCikKAgQAEgQnAGIBGh0g
TWVzc2FnZSBmb3IgYSBjb252ZXJzYXRpb24uCgoKCgMEAAESAycIFAoLCgMEAAcSBCgCLQQK
DQoFBAAHnQgSBCgCLQQK0gQKBAQAAgASBDsCPgQawwQgT3B0aW9uYWwuIElkZW50aWZpZXIu
IFRoZSB1bmlxdWUgcmVzb3VyY2UgbmFtZSBvZiBhIGNvbnZlcnNhdGlvbi4gRm9ybWF0Ogog
YHByb2plY3RzL3twcm9qZWN0fS9sb2NhdGlvbnMve2xvY2F0aW9ufS9jb252ZXJzYXRpb25z
L3tjb252ZXJzYXRpb25faWR9YAogYHtjb252ZXJzYXRpb25faWR9YCBpcyB0aGUgcmVzb3Vy
Y2UgaWQgYW5kIHNob3VsZCBiZSA2MyBjaGFyYWN0ZXJzIG9yIGxlc3MKIGFuZCBtdXN0IG1h
dGNoIHRoZSBmb3JtYXQgZGVzY3JpYmVkIGluCiBodHRwczovL2dvb2dsZS5haXAuZGV2LzEy
MiNyZXNvdXJjZS1pZC1zZWdtZW50cwoKIEV4YW1wbGU6CiBgcHJvamVjdHMvMTIzNDU2Nzg5
MC9sb2NhdGlvbnMvZ2xvYmFsL2NvbnZlcnNhdGlvbnMvbXktY29udmVyc2F0aW9uYC4KCiBJ
dCBpcyByZWNvbW1lbmRlZCB0byBza2lwIHNldHRpbmcgdGhpcyBmaWVsZCBkdXJpbmcgY29u
dmVyc2F0aW9uIGNyZWF0aW9uCiBhcyBpdCB3aWxsIGJlIGluZmVycmVkIGF1dG9tYXRpY2Fs
bHkgYW5kIG92ZXJ3cml0dGVuIHdpdGggdGhlCiB7cGFyZW50fS9jb252ZXJzYXRpb25zL3tj
b252ZXJzYXRpb25faWR9LgoKDAoFBAACAAUSAzsCCAoMCgUEAAIAARIDOwkNCgwKBQQAAgAD
EgM7EBEKDQoFBAACAAgSBDsSPgMKDwoIBAACAAicCAASAzwEKgoPCggEAAIACJwIARIDPQQs
CoACCgQEAAIBEgNEAkYa8gEgUmVxdWlyZWQuIEFnZW50KHMpIGluIHRoZSBjb252ZXJzYXRp
b24uCiBDdXJyZW50bHksIG9ubHkgb25lIGFnZW50IGlzIHN1cHBvcnRlZC4gVGhpcyBmaWVs
ZCBpcyByZXBlYXRlZCB0byBhbGxvdwogZm9yIGZ1dHVyZSBzdXBwb3J0IG9mIG11bHRpcGxl
IGFnZW50cyBpbiBhIGNvbnZlcnNhdGlvbi4KIEZvcm1hdDogYHByb2plY3RzL3twcm9qZWN0
fS9sb2NhdGlvbnMve2xvY2F0aW9ufS9kYXRhQWdlbnRzL3thZ2VudH1gCgoMCgUEAAIBBBID
RAIKCgwKBQQAAgEFEgNECxEKDAoFBAACAQESA0QSGAoMCgUEAAIBAxIDRBscCgwKBQQAAgEI
EgNEHUUKDwoIBAACAQicCAASA0QeRAowCgQEAAICEgRHAkgyGiIgT3V0cHV0IG9ubHkuIENy
ZWF0aW9uIHRpbWVzdGFtcC4KCgwKBQQAAgIGEgNHAhsKDAoFBAACAgESA0ccJwoMCgUEAAIC
AxIDRyorCgwKBQQAAgIIEgNIBjEKDwoIBAACAgicCAASA0gHMApFCgQEAAIDEgRLAkwyGjcg
T3V0cHV0IG9ubHkuIFRpbWVzdGFtcCBvZiB0aGUgbGFzdCB1c2VkIGNvbnZlcnNhdGlvbi4K
CgwKBQQAAgMGEgNLAhsKDAoFBAACAwESA0scKgoMCgUEAAIDAxIDSy0uCgwKBQQAAgMIEgNM
BjEKDwoIBAACAwicCAASA0wHMAqxAQoEBAACBBIDUQJKGqMBIE9wdGlvbmFsLiBPcGVuLWVu
ZGVkIGFuZCB1c2VyLWRlZmluZWQgbGFiZWxzIHRoYXQgY2FuIGJlIHNldCBieSB0aGUgY2xp
ZW50CiB0byB0YWcgYSBjb252ZXJzYXRpb24gKGUuZy4gdG8gZmlsdGVyIGNvbnZlcnNhdGlv
bnMgZm9yIHNwZWNpZmljCiBzdXJmYWNlcy9wcm9kdWN0cykuCgoMCgUEAAIEBhIDUQIVCgwK
BQQAAgQBEgNRFhwKDAoFBAACBAMSA1EfIAoMCgUEAAIECBIDUSFJCg8KCAQAAgQInAgAEgNR
IkgKTgoEBAACBRIDVAI8GkEgT3B0aW9uYWwuIFRoZSBkaXNwbGF5IG5hbWUgZm9yIHRoZSBj
b252ZXJzYXRpb24gKG1heCA2MyBjaGFycykuCgoMCgUEAAIFBRIDVAIICgwKBQQAAgUBEgNU
CQ4KDAoFBAACBQMSA1QREgoMCgUEAAIFCBIDVBM7Cg8KCAQAAgUInAgAEgNUFDoKpQIKBAQA
AgYSBFwCYQQalgIgT3B0aW9uYWwuIEN1c3RvbWVyIG1hbmFnZWQgZW5jcnlwdGlvbiBrZXkg
KENNRUspIHRvIHVzZSBmb3IgZW5jcnlwdGluZyB0aGUKIENvbnZlcnNhdGlvbiByZXNvdXJj
ZXMuIEVuY3J5cHRpb24gd2lsbCBoYXBwZW4gYXQgVGl0YW4gbGF5ZXIsIHdlIHdpbGwgcGFz
cwogdGhlIEtNUyBrZXkgdG8gVGl0YW4uCgogRm9ybWF0OgogcHJvamVjdHMve3Byb2plY3Rf
aWR9L2xvY2F0aW9ucy97bG9jYXRpb259L2tleVJpbmdzL3trZXlfcmluZ19uYW1lfS9jcnlw
dG9LZXlzL3trZXlfbmFtZX0uCgoMCgUEAAIGBBIDXAIKCgwKBQQAAgYFEgNcCxEKDAoFBAAC
BgESA1wSGQoMCgUEAAIGAxIDXBweCg0KBQQAAgYIEgRcH2EDCg8KCAQAAgYInAgAEgNdBCoK
DwoHBAACBgifCBIEXgRgBQozCgIEARIFZQCAAQEaJiBSZXF1ZXN0IGZvciBjcmVhdGluZyBh
IGNvbnZlcnNhdGlvbi4KCgoKAwQBARIDZQghCngKBAQBAgASBGgCbQQaaiBSZXF1aXJlZC4g
UGFyZW50IHZhbHVlIGZvciBDcmVhdGVDb252ZXJzYXRpb25SZXF1ZXN0LgogRm9ybWF0OiBg
cHJvamVjdHMve3Byb2plY3R9L2xvY2F0aW9ucy97bG9jYXRpb259YAoKDAoFBAECAAUSA2gC
CAoMCgUEAQIAARIDaAkPCgwKBQQBAgADEgNoEhMKDQoFBAECAAgSBGgUbQMKDwoIBAECAAic
CAASA2kEKgoPCgcEAQIACJ8IEgRqBGwFCvABCgQEAQIBEgNzAkYa4gEgT3B0aW9uYWwuIFRo
ZSBjb252ZXJzYXRpb24gaWQgb2YgdGhlIGNvbnZlcnNhdGlvbiB0byBjcmVhdGUuCiBNdXN0
IGJlIHVuaXF1ZSB3aXRoaW4gdGhlIHBhcmVudC4KIFRoZSBhbGxvd2VkIGZvcm1hdCBpczog
YF5bYS16XShbYS16MC05LV17MCw2MX1bYS16MC05XSk/JGAuCiBJZiBub3QgcHJvdmlkZWQs
IHRoZSBzZXJ2ZXIgd2lsbCBhdXRvLWdlbmVyYXRlIGEgdmFsdWUgZm9yIHRoZSBpZC4KCgwK
BQQBAgEFEgNzAggKDAoFBAECAQESA3MJGAoMCgUEAQIBAxIDcxscCgwKBQQBAgEIEgNzHUUK
DwoIBAECAQicCAASA3MeRAo0CgQEAQICEgN2AkkaJyBSZXF1aXJlZC4gVGhlIGNvbnZlcnNh
dGlvbiB0byBjcmVhdGUuCgoMCgUEAQICBhIDdgIOCgwKBQQBAgIBEgN2DxsKDAoFBAECAgMS
A3YeHwoMCgUEAQICCBIDdiBICg8KCAQBAgIInAgAEgN2IUcKqwIKBAQBAgMSBHwCfwQanAIg
T3B0aW9uYWwuIEFuIG9wdGlvbmFsIHJlcXVlc3QgSUQgdG8gaWRlbnRpZnkgcmVxdWVzdHMu
IFNwZWNpZnkgYSB1bmlxdWUKIHJlcXVlc3QgSUQgc28gdGhhdCBpZiB5b3UgbXVzdCByZXRy
eSB5b3VyIHJlcXVlc3QsIHRoZSBzZXJ2ZXIgd2lsbCBrbm93IHRvCiBpZ25vcmUgdGhlIHJl
cXVlc3QgaWYgaXQgaGFzIGFscmVhZHkgYmVlbiBjb21wbGV0ZWQuIFRoZSBzZXJ2ZXIgd2ls
bAogZ3VhcmFudGVlIHRoYXQgZm9yIGF0IGxlYXN0IDYwIG1pbnV0ZXMgc2luY2UgdGhlIGZp
cnN0IHJlcXVlc3QuCgoMCgUEAQIDBRIDfAIICgwKBQQBAgMBEgN8CRMKDAoFBAECAwMSA3wW
FwoNCgUEAQIDCBIEfBh/AwoSCgsEAQIDCMzx+YoBARIDfQQqCg8KCAQBAgMInAgAEgN+BCoK
NAoCBAISBoMBAJkBARomIFJlcXVlc3QgZm9yIHVwZGF0aW5nIGEgY29udmVyc2F0aW9uLgoK
CwoDBAIBEgSDAQghCjUKBAQCAgASBIUBAkkaJyBSZXF1aXJlZC4gVGhlIHJlc291cmNlIGJl
aW5nIHVwZGF0ZWQuCgoNCgUEAgIABhIEhQECDgoNCgUEAgIAARIEhQEPGwoNCgUEAgIAAxIE
hQEeHwoNCgUEAgIACBIEhQEgSAoQCggEAgIACJwIABIEhQEhRwrPAwoEBAICARIGjgECjwEv
Gr4DIE9wdGlvbmFsLiBGaWVsZCBtYXNrIGlzIHVzZWQgdG8gc3BlY2lmeSB0aGUgZmllbGRz
IHRvIGJlIG92ZXJ3cml0dGVuIGluIHRoZQogQ29udmVyc2F0aW9uIHJlc291cmNlIGJ5IHRo
ZSB1cGRhdGUuCiBUaGUgZmllbGRzIHNwZWNpZmllZCBpbiB0aGUgdXBkYXRlX21hc2sgYXJl
IHJlbGF0aXZlIHRvIHRoZSByZXNvdXJjZSwgbm90CiB0aGUgZnVsbCByZXF1ZXN0LiBBIGZp
ZWxkIHdpbGwgYmUgb3ZlcndyaXR0ZW4gaWYgaXQgaXMgaW4gdGhlIG1hc2suIElmIHRoZQog
dXNlciBkb2VzIG5vdCBwcm92aWRlIGEgbWFzayB0aGVuIGFsbCBmaWVsZHMgd2l0aCBub24t
ZGVmYXVsdCB2YWx1ZXMKIHByZXNlbnQgaW4gdGhlIHJlcXVlc3Qgd2lsbCBiZSBvdmVyd3Jp
dHRlbi4gSWYgYSB3aWxkY2FyZCBtYXNrIGlzIHByb3ZpZGVkLAogYWxsIGZpZWxkcyB3aWxs
IGJlIG92ZXJ3cml0dGVuLgoKDQoFBAICAQYSBI4BAhsKDQoFBAICAQESBI4BHCcKDQoFBAIC
AQMSBI4BKisKDQoFBAICAQgSBI8BBi4KEAoIBAICAQicCAASBI8BBy0KrQIKBAQCAgISBpUB
ApgBBBqcAiBPcHRpb25hbC4gQW4gb3B0aW9uYWwgcmVxdWVzdCBJRCB0byBpZGVudGlmeSBy
ZXF1ZXN0cy4gU3BlY2lmeSBhIHVuaXF1ZQogcmVxdWVzdCBJRCBzbyB0aGF0IGlmIHlvdSBt
dXN0IHJldHJ5IHlvdXIgcmVxdWVzdCwgdGhlIHNlcnZlciB3aWxsIGtub3cgdG8KIGlnbm9y
ZSB0aGUgcmVxdWVzdCBpZiBpdCBoYXMgYWxyZWFkeSBiZWVuIGNvbXBsZXRlZC4gVGhlIHNl
cnZlciB3aWxsCiBndWFyYW50ZWUgdGhhdCBmb3IgYXQgbGVhc3QgNjAgbWludXRlcyBzaW5j
ZSB0aGUgZmlyc3QgcmVxdWVzdC4KCg0KBQQCAgIFEgSVAQIICg0KBQQCAgIBEgSVAQkTCg0K
BQQCAgIDEgSVARYXCg8KBQQCAgIIEgaVARiYAQMKEwoLBAICAgjM8fmKAQESBJYBBCoKEAoI
BAICAgicCAASBJcBBCoKVwoCBAMSBpwBAKYBARpJIFJlcXVlc3QgZm9yIGdldHRpbmcgYSBj
b252ZXJzYXRpb24gYmFzZWQgb24gcGFyZW50IGFuZCBjb252ZXJzYXRpb24gaWQuCgoLCgME
AwESBJwBCB4KggEKBAQDAgASBqABAqUBBBpyIFJlcXVpcmVkLiBOYW1lIG9mIHRoZSByZXNv
dXJjZS4KIEZvcm1hdDoKIGBwcm9qZWN0cy97cHJvamVjdH0vbG9jYXRpb25zL3tsb2NhdGlv
bn0vY29udmVyc2F0aW9ucy97Y29udmVyc2F0aW9ufWAKCg0KBQQDAgAFEgSgAQIICg0KBQQD
AgABEgSgAQkNCg0KBQQDAgADEgSgARARCg8KBQQDAgAIEgagARKlAQMKEAoIBAMCAAicCAAS
BKEBBCoKEQoHBAMCAAifCBIGogEEpAEFCkIKAgQEEgapAQDBAQEaNCBSZXF1ZXN0IGZvciBs
aXN0aW5nIGNvbnZlcnNhdGlvbnMgYmFzZWQgb24gcGFyZW50LgoKCwoDBAQBEgSpAQggCnkK
BAQEAgASBqwBArEBBBppIFJlcXVpcmVkLiBQYXJlbnQgdmFsdWUgZm9yIExpc3RDb252ZXJz
YXRpb25zUmVxdWVzdC4KIEZvcm1hdDogYHByb2plY3RzL3twcm9qZWN0fS9sb2NhdGlvbnMv
e2xvY2F0aW9ufWAKCg0KBQQEAgAFEgSsAQIICg0KBQQEAgABEgSsAQkPCg0KBQQEAgADEgSs
ARITCg8KBQQEAgAIEgasARSxAQMKEAoIBAQCAAicCAASBK0BBCoKEQoHBAQCAAifCBIGrgEE
sAEFCu0BCgQEBAIBEgS3AQI/Gt4BIE9wdGlvbmFsLiBSZXF1ZXN0ZWQgcGFnZSBzaXplLiBT
ZXJ2ZXIgbWF5IHJldHVybiBmZXdlciBpdGVtcyB0aGFuCiByZXF1ZXN0ZWQuIFRoZSBtYXgg
cGFnZSBzaXplIGlzIGAxMDBgLiBBbGwgbGFyZ2VyIHBhZ2Ugc2l6ZXMgd2lsbCBiZQogY29l
cmNlZCB0byBgMTAwYC4gSWYgdW5zcGVjaWZpZWQsIHNlcnZlciB3aWxsIHBpY2sgYDUwYCBh
cyBhbiBhcHByb3ByaWF0ZQogZGVmYXVsdC4KCg0KBQQEAgEFEgS3AQIHCg0KBQQEAgEBEgS3
AQgRCg0KBQQEAgEDEgS3ARQVCg0KBQQEAgEIEgS3ARY+ChAKCAQEAgEInAgAEgS3ARc9ClkK
BAQEAgISBLoBAkEaSyBPcHRpb25hbC4gQSB0b2tlbiBpZGVudGlmeWluZyBhIHBhZ2Ugb2Yg
cmVzdWx0cyB0aGUgc2VydmVyIHNob3VsZCByZXR1cm4uCgoNCgUEBAICBRIEugECCAoNCgUE
BAICARIEugEJEwoNCgUEBAICAxIEugEWFwoNCgUEBAICCBIEugEYQAoQCggEBAICCJwIABIE
ugEZPwqgAQoEBAQCAxIEwAECPRqRASBPcHRpb25hbC4gUmV0dXJuZWQgY29udmVyc2F0aW9u
cyB3aWxsIG1hdGNoIGNyaXRlcmlhIHNwZWNpZmllZCB3aXRoaW4gdGhlCiBmaWx0ZXIuIExp
c3RDb252ZXJzYXRpb25zIGFsbG93cyBmaWx0ZXJpbmcgYnk6CiAgKiBhZ2VudHMKICAqIGxh
YmVscwoKDQoFBAQCAwUSBMABAggKDQoFBAQCAwESBMABCQ8KDQoFBAQCAwMSBMABEhMKDQoF
BAQCAwgSBMABFDwKEAoIBAQCAwicCAASBMABFTsKPgoCBAUSBsQBAMoBARowIE1lc3NhZ2Ug
Zm9yIHJlc3BvbnNlIHRvIGxpc3RpbmcgY29udmVyc2F0aW9ucy4KCgsKAwQFARIExAEIIQoq
CgQEBQIAEgTGAQIqGhwgVGhlIGxpc3Qgb2YgY29udmVyc2F0aW9ucy4KCg0KBQQFAgAEEgTG
AQIKCg0KBQQFAgAGEgTGAQsXCg0KBQQFAgABEgTGARglCg0KBQQFAgADEgTGASgpCk8KBAQF
AgESBMkBAh0aQSBBIHRva2VuIGlkZW50aWZ5aW5nIGEgcGFnZSBvZiByZXN1bHRzIHRoZSBz
ZXJ2ZXIgc2hvdWxkIHJldHVybi4KCg0KBQQFAgEFEgTJAQIICg0KBQQFAgEBEgTJAQkYCg0K
BQQFAgEDEgTJARscClgKAgQGEgbNAQDXAQEaSiBSZXF1ZXN0IGZvciBkZWxldGluZyBhIGNv
bnZlcnNhdGlvbiBiYXNlZCBvbiBwYXJlbnQgYW5kIGNvbnZlcnNhdGlvbiBpZC4KCgsKAwQG
ARIEzQEIIQqCAQoEBAYCABIG0QEC1gEEGnIgUmVxdWlyZWQuIE5hbWUgb2YgdGhlIHJlc291
cmNlLgogRm9ybWF0OgogYHByb2plY3RzL3twcm9qZWN0fS9sb2NhdGlvbnMve2xvY2F0aW9u
fS9jb252ZXJzYXRpb25zL3tjb252ZXJzYXRpb259YAoKDQoFBAYCAAUSBNEBAggKDQoFBAYC
AAESBNEBCQ0KDQoFBAYCAAMSBNEBEBEKDwoFBAYCAAgSBtEBEtYBAwoQCggEBgIACJwIABIE
0gEEKgoRCgcEBgIACJ8IEgbTAQTVAQViBnByb3RvMw==
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Geminidataanalytics::V1alpha::Conversation::Conversation ===
    # Fields for Conversation
    # Field: name Type: 9 ()
    # Field: agents Type: 9 ()
    # Field: create_time Type: 11 (.google.protobuf.Timestamp)
    # Field: last_used_time Type: 11 (.google.protobuf.Timestamp)
    # Field: labels Type: 11 (.google.cloud.geminidataanalytics.v1alpha.Conversation.LabelsEntry)
    # Field: title Type: 9 ()
    # Field: kms_key Type: 9 ()

# === Message: Google::Cloud::Geminidataanalytics::V1alpha::Conversation::CreateConversationRequest ===
    # Fields for CreateConversationRequest
    # Field: parent Type: 9 ()
    # Field: conversation_id Type: 9 ()
    # Field: conversation Type: 11 (.google.cloud.geminidataanalytics.v1alpha.Conversation)
    # Field: request_id Type: 9 ()

# === Message: Google::Cloud::Geminidataanalytics::V1alpha::Conversation::UpdateConversationRequest ===
    # Fields for UpdateConversationRequest
    # Field: conversation Type: 11 (.google.cloud.geminidataanalytics.v1alpha.Conversation)
    # Field: update_mask Type: 11 (.google.protobuf.FieldMask)
    # Field: request_id Type: 9 ()

# === Message: Google::Cloud::Geminidataanalytics::V1alpha::Conversation::GetConversationRequest ===
    # Fields for GetConversationRequest
    # Field: name Type: 9 ()

# === Message: Google::Cloud::Geminidataanalytics::V1alpha::Conversation::ListConversationsRequest ===
    # Fields for ListConversationsRequest
    # Field: parent Type: 9 ()
    # Field: page_size Type: 5 ()
    # Field: page_token Type: 9 ()
    # Field: filter Type: 9 ()

# === Message: Google::Cloud::Geminidataanalytics::V1alpha::Conversation::ListConversationsResponse ===
    # Fields for ListConversationsResponse
    # Field: conversations Type: 11 (.google.cloud.geminidataanalytics.v1alpha.Conversation)
    # Field: next_page_token Type: 9 ()

# === Message: Google::Cloud::Geminidataanalytics::V1alpha::Conversation::DeleteConversationRequest ===
    # Fields for DeleteConversationRequest
    # Field: name Type: 9 ()

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Geminidataanalytics::V1alpha::Conversation - Compiled Protocol Buffers messages for google/cloud/geminidataanalytics/v1alpha/conversation.proto

=head1 SYNOPSIS

    use Google::Cloud::Geminidataanalytics::V1alpha::Conversation;

    my $msg = Google::Cloud::Geminidataanalytics::V1alpha::Conversation::Conversation->new({
        name => $name,
        agents => $agents,
        create_time => $create_time,
        last_used_time => $last_used_time,
    });

    # Read or update a field
    my $val = $msg->name();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Geminidataanalytics::V1alpha::Conversation::Conversation->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/geminidataanalytics/v1alpha/conversation.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Geminidataanalytics::V1alpha::Conversation::Conversation

Message for a conversation.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Optional. Identifier. The unique resource name of a conversation. Format:
`projects/{project}/locations/{location}/conversations/{conversation_id}`
`{conversation_id}` is the resource id and should be 63 characters or less
and must match the format described in
https://google.aip.dev/122#resource-id-segments

Example:
`projects/1234567890/locations/global/conversations/my-conversation`.

It is recommended to skip setting this field during conversation creation
as it will be inferred automatically and overwritten with the
{parent}/conversations/{conversation_id}.

=item * C<< $msg->agents() >> / C<< $msg->agents($value) >>

Type: C<String>

Required. Agent(s) in the conversation.
Currently, only one agent is supported. This field is repeated to allow
for future support of multiple agents in a conversation.
Format: `projects/{project}/locations/{location}/dataAgents/{agent}`

=item * C<< $msg->create_time() >> / C<< $msg->create_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Output only. Creation timestamp.

=item * C<< $msg->last_used_time() >> / C<< $msg->last_used_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Output only. Timestamp of the last used conversation.

=item * C<< $msg->labels() >> / C<< $msg->labels($value) >>

Type: C<Message> (L<Google::Cloud::Geminidataanalytics::V1alpha::Conversation::Conversation::LabelsEntry>)

Optional. Open-ended and user-defined labels that can be set by the client
to tag a conversation (e.g. to filter conversations for specific
surfaces/products).

=item * C<< $msg->title() >> / C<< $msg->title($value) >>

Type: C<String>

Optional. The display name for the conversation (max 63 chars).

=item * C<< $msg->kms_key() >> / C<< $msg->kms_key($value) >>

Type: C<String>

Optional. Customer managed encryption key (CMEK) to use for encrypting the
Conversation resources. Encryption will happen at Titan layer, we will pass
the KMS key to Titan.

Format:
projects/{project_id}/locations/{location}/keyRings/{key_ring_name}/cryptoKeys/{key_name}.

=back

=head2 Google::Cloud::Geminidataanalytics::V1alpha::Conversation::CreateConversationRequest

Request for creating a conversation.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->parent() >> / C<< $msg->parent($value) >>

Type: C<String>

Required. Parent value for CreateConversationRequest.
Format: `projects/{project}/locations/{location}`

=item * C<< $msg->conversation_id() >> / C<< $msg->conversation_id($value) >>

Type: C<String>

Optional. The conversation id of the conversation to create.
Must be unique within the parent.
The allowed format is: `^[a-z]([a-z0-9-]{0,61}[a-z0-9])?$`.
If not provided, the server will auto-generate a value for the id.

=item * C<< $msg->conversation() >> / C<< $msg->conversation($value) >>

Type: C<Message> (L<Google::Cloud::Geminidataanalytics::V1alpha::Conversation::Conversation>)

Required. The conversation to create.

=item * C<< $msg->request_id() >> / C<< $msg->request_id($value) >>

Type: C<String>

Optional. An optional request ID to identify requests. Specify a unique
request ID so that if you must retry your request, the server will know to
ignore the request if it has already been completed. The server will
guarantee that for at least 60 minutes since the first request.

=back

=head2 Google::Cloud::Geminidataanalytics::V1alpha::Conversation::UpdateConversationRequest

Request for updating a conversation.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->conversation() >> / C<< $msg->conversation($value) >>

Type: C<Message> (L<Google::Cloud::Geminidataanalytics::V1alpha::Conversation::Conversation>)

Required. The resource being updated.

=item * C<< $msg->update_mask() >> / C<< $msg->update_mask($value) >>

Type: C<Message> (L<Google::Protobuf::FieldMask::FieldMask>)

Optional. Field mask is used to specify the fields to be overwritten in the
Conversation resource by the update.
The fields specified in the update_mask are relative to the resource, not
the full request. A field will be overwritten if it is in the mask. If the
user does not provide a mask then all fields with non-default values
present in the request will be overwritten. If a wildcard mask is provided,
all fields will be overwritten.

=item * C<< $msg->request_id() >> / C<< $msg->request_id($value) >>

Type: C<String>

Optional. An optional request ID to identify requests. Specify a unique
request ID so that if you must retry your request, the server will know to
ignore the request if it has already been completed. The server will
guarantee that for at least 60 minutes since the first request.

=back

=head2 Google::Cloud::Geminidataanalytics::V1alpha::Conversation::GetConversationRequest

Request for getting a conversation based on parent and conversation id.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. Name of the resource.
Format:
`projects/{project}/locations/{location}/conversations/{conversation}`

=back

=head2 Google::Cloud::Geminidataanalytics::V1alpha::Conversation::ListConversationsRequest

Request for listing conversations based on parent.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->parent() >> / C<< $msg->parent($value) >>

Type: C<String>

Required. Parent value for ListConversationsRequest.
Format: `projects/{project}/locations/{location}`

=item * C<< $msg->page_size() >> / C<< $msg->page_size($value) >>

Type: C<Int32>

Optional. Requested page size. Server may return fewer items than
requested. The max page size is `100`. All larger page sizes will be
coerced to `100`. If unspecified, server will pick `50` as an appropriate
default.

=item * C<< $msg->page_token() >> / C<< $msg->page_token($value) >>

Type: C<String>

Optional. A token identifying a page of results the server should return.

=item * C<< $msg->filter() >> / C<< $msg->filter($value) >>

Type: C<String>

Optional. Returned conversations will match criteria specified within the
filter. ListConversations allows filtering by:
 * agents
 * labels

=back

=head2 Google::Cloud::Geminidataanalytics::V1alpha::Conversation::ListConversationsResponse

Message for response to listing conversations.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->conversations() >> / C<< $msg->conversations($value) >>

Type: C<Message> (L<Google::Cloud::Geminidataanalytics::V1alpha::Conversation::Conversation>)

The list of conversations.

=item * C<< $msg->next_page_token() >> / C<< $msg->next_page_token($value) >>

Type: C<String>

A token identifying a page of results the server should return.

=back

=head2 Google::Cloud::Geminidataanalytics::V1alpha::Conversation::DeleteConversationRequest

Request for deleting a conversation based on parent and conversation id.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. Name of the resource.
Format:
`projects/{project}/locations/{location}/conversations/{conversation}`

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Geminidataanalytics::V1alpha::Conversation::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
