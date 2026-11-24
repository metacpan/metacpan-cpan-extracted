package Google::Cloud::Osconfig::Agentendpoint::V1beta::Tasks;

use strict;
use warnings;

our $VERSION = '0.14';

use Protobuf::Message;
use Protobuf::DescriptorPool;
use Protobuf::Internal qw(:all);
use MIME::Base64;

BEGIN {
    eval { require Google::Api::FieldBehavior };
    eval { require Google::Cloud::Osconfig::Agentendpoint::V1beta::PatchJobs };
    my $descriptor_b64 = <<'EOF';
CjZnb29nbGUvY2xvdWQvb3Njb25maWcvYWdlbnRlbmRwb2ludC92MWJldGEvdGFza3MucHJv
dG8SKmdvb2dsZS5jbG91ZC5vc2NvbmZpZy5hZ2VudGVuZHBvaW50LnYxYmV0YRofZ29vZ2xl
L2FwaS9maWVsZF9iZWhhdmlvci5wcm90bxo7Z29vZ2xlL2Nsb3VkL29zY29uZmlnL2FnZW50
ZW5kcG9pbnQvdjFiZXRhL3BhdGNoX2pvYnMucHJvdG8i4gQKBFRhc2sSFwoHdGFza19pZBgB
IAEoCVIGdGFza0lkElEKCXRhc2tfdHlwZRgCIAEoDjI0Lmdvb2dsZS5jbG91ZC5vc2NvbmZp
Zy5hZ2VudGVuZHBvaW50LnYxYmV0YS5UYXNrVHlwZVIIdGFza1R5cGUSYAoOdGFza19kaXJl
Y3RpdmUYAyABKA4yOS5nb29nbGUuY2xvdWQub3Njb25maWcuYWdlbnRlbmRwb2ludC52MWJl
dGEuVGFza0RpcmVjdGl2ZVINdGFza0RpcmVjdGl2ZRJsChJhcHBseV9wYXRjaGVzX3Rhc2sY
BCABKAsyPC5nb29nbGUuY2xvdWQub3Njb25maWcuYWdlbnRlbmRwb2ludC52MWJldGEuQXBw
bHlQYXRjaGVzVGFza0gAUhBhcHBseVBhdGNoZXNUYXNrEmAKDmV4ZWNfc3RlcF90YXNrGAUg
ASgLMjguZ29vZ2xlLmNsb3VkLm9zY29uZmlnLmFnZW50ZW5kcG9pbnQudjFiZXRhLkV4ZWNT
dGVwVGFza0gAUgxleGVjU3RlcFRhc2sSagoOc2VydmljZV9sYWJlbHMYBiADKAsyQy5nb29n
bGUuY2xvdWQub3Njb25maWcuYWdlbnRlbmRwb2ludC52MWJldGEuVGFzay5TZXJ2aWNlTGFi
ZWxzRW50cnlSDXNlcnZpY2VMYWJlbHMaQAoSU2VydmljZUxhYmVsc0VudHJ5EhAKA2tleRgB
IAEoCVIDa2V5EhQKBXZhbHVlGAIgASgJUgV2YWx1ZToCOAFCDgoMdGFza19kZXRhaWxzIocB
ChBBcHBseVBhdGNoZXNUYXNrEloKDHBhdGNoX2NvbmZpZxgBIAEoCzI3Lmdvb2dsZS5jbG91
ZC5vc2NvbmZpZy5hZ2VudGVuZHBvaW50LnYxYmV0YS5QYXRjaENvbmZpZ1ILcGF0Y2hDb25m
aWcSFwoHZHJ5X3J1bhgDIAEoCFIGZHJ5UnVuIuwBChhBcHBseVBhdGNoZXNUYXNrUHJvZ3Jl
c3MSZQoFc3RhdGUYASABKA4ySi5nb29nbGUuY2xvdWQub3Njb25maWcuYWdlbnRlbmRwb2lu
dC52MWJldGEuQXBwbHlQYXRjaGVzVGFza1Byb2dyZXNzLlN0YXRlQgPgQQJSBXN0YXRlImkK
BVN0YXRlEhUKEVNUQVRFX1VOU1BFQ0lGSUVEEAASCwoHU1RBUlRFRBAEEhcKE0RPV05MT0FE
SU5HX1BBVENIRVMQARIUChBBUFBMWUlOR19QQVRDSEVTEAISDQoJUkVCT09USU5HEAMi1wEK
FkFwcGx5UGF0Y2hlc1Rhc2tPdXRwdXQSYwoFc3RhdGUYASABKA4ySC5nb29nbGUuY2xvdWQu
b3Njb25maWcuYWdlbnRlbmRwb2ludC52MWJldGEuQXBwbHlQYXRjaGVzVGFza091dHB1dC5T
dGF0ZUID4EECUgVzdGF0ZSJYCgVTdGF0ZRIVChFTVEFURV9VTlNQRUNJRklFRBAAEg0KCVNV
Q0NFRURFRBABEh0KGVNVQ0NFRURFRF9SRUJPT1RfUkVRVUlSRUQQAhIKCgZGQUlMRUQQAyJh
CgxFeGVjU3RlcFRhc2sSUQoJZXhlY19zdGVwGAEgASgLMjQuZ29vZ2xlLmNsb3VkLm9zY29u
ZmlnLmFnZW50ZW5kcG9pbnQudjFiZXRhLkV4ZWNTdGVwUghleGVjU3RlcCKmAQoURXhlY1N0
ZXBUYXNrUHJvZ3Jlc3MSYQoFc3RhdGUYASABKA4yRi5nb29nbGUuY2xvdWQub3Njb25maWcu
YWdlbnRlbmRwb2ludC52MWJldGEuRXhlY1N0ZXBUYXNrUHJvZ3Jlc3MuU3RhdGVCA+BBAlIF
c3RhdGUiKwoFU3RhdGUSFQoRU1RBVEVfVU5TUEVDSUZJRUQQABILCgdTVEFSVEVEEAEi5AEK
EkV4ZWNTdGVwVGFza091dHB1dBJfCgVzdGF0ZRgBIAEoDjJELmdvb2dsZS5jbG91ZC5vc2Nv
bmZpZy5hZ2VudGVuZHBvaW50LnYxYmV0YS5FeGVjU3RlcFRhc2tPdXRwdXQuU3RhdGVCA+BB
AlIFc3RhdGUSIAoJZXhpdF9jb2RlGAIgASgFQgPgQQJSCGV4aXRDb2RlIksKBVN0YXRlEhUK
EVNUQVRFX1VOU1BFQ0lGSUVEEAASDQoJQ09NUExFVEVEEAESDQoJVElNRURfT1VUEAISDQoJ
Q0FOQ0VMTEVEEAMqRwoNVGFza0RpcmVjdGl2ZRIeChpUQVNLX0RJUkVDVElWRV9VTlNQRUNJ
RklFRBAAEgwKCENPTlRJTlVFEAESCAoEU1RPUBACKkwKCFRhc2tUeXBlEhkKFVRBU0tfVFlQ
RV9VTlNQRUNJRklFRBAAEhEKDUFQUExZX1BBVENIRVMQARISCg5FWEVDX1NURVBfVEFTSxAC
QqwBCi5jb20uZ29vZ2xlLmNsb3VkLm9zY29uZmlnLmFnZW50ZW5kcG9pbnQudjFiZXRhQgVU
YXNrc1pUY2xvdWQuZ29vZ2xlLmNvbS9nby9vc2NvbmZpZy9hZ2VudGVuZHBvaW50L2FwaXYx
YmV0YS9hZ2VudGVuZHBvaW50cGI7YWdlbnRlbmRwb2ludHBiygIcR29vZ2xlXENsb3VkXE9z
Q29uZmlnXFYxYmV0YUrrKwoHEgUOALMBAQq8BAoBDBIDDgASMrEEIENvcHlyaWdodCAyMDI1
IEdvb2dsZSBMTEMKCiBMaWNlbnNlZCB1bmRlciB0aGUgQXBhY2hlIExpY2Vuc2UsIFZlcnNp
b24gMi4wICh0aGUgIkxpY2Vuc2UiKTsKIHlvdSBtYXkgbm90IHVzZSB0aGlzIGZpbGUgZXhj
ZXB0IGluIGNvbXBsaWFuY2Ugd2l0aCB0aGUgTGljZW5zZS4KIFlvdSBtYXkgb2J0YWluIGEg
Y29weSBvZiB0aGUgTGljZW5zZSBhdAoKICAgICBodHRwOi8vd3d3LmFwYWNoZS5vcmcvbGlj
ZW5zZXMvTElDRU5TRS0yLjAKCiBVbmxlc3MgcmVxdWlyZWQgYnkgYXBwbGljYWJsZSBsYXcg
b3IgYWdyZWVkIHRvIGluIHdyaXRpbmcsIHNvZnR3YXJlCiBkaXN0cmlidXRlZCB1bmRlciB0
aGUgTGljZW5zZSBpcyBkaXN0cmlidXRlZCBvbiBhbiAiQVMgSVMiIEJBU0lTLAogV0lUSE9V
VCBXQVJSQU5USUVTIE9SIENPTkRJVElPTlMgT0YgQU5ZIEtJTkQsIGVpdGhlciBleHByZXNz
IG9yIGltcGxpZWQuCiBTZWUgdGhlIExpY2Vuc2UgZm9yIHRoZSBzcGVjaWZpYyBsYW5ndWFn
ZSBnb3Zlcm5pbmcgcGVybWlzc2lvbnMgYW5kCiBsaW1pdGF0aW9ucyB1bmRlciB0aGUgTGlj
ZW5zZS4KCggKAQISAxAAMwoJCgIDABIDEgApCgkKAgMBEgMTAEUKCAoBCBIDFQBrCgkKAggL
EgMVAGsKCAoBCBIDFgAmCgkKAggIEgMWACYKCAoBCBIDFwBHCgkKAggBEgMXAEcKCAoBCBID
GAA5CgkKAggpEgMYADkKMwoCBQASBBsAJgEaJyBTcGVjaWZpZXMgdGhlIGN1cnJlbnQgYWdl
bnQgYmVoYXZpb3IuCgoKCgMFAAESAxsFEgomCgQFAAIAEgMdAiEaGSBVbnNwZWNpZmllZCBp
cyBpbnZhbGlkLgoKDAoFBQACAAESAx0CHAoMCgUFAAIAAhIDHR8gCjQKBAUAAgESAyACDxon
IFRoZSB0YXNrIHNob3VsZCBjb250aW51ZSB0byBwcm9ncmVzcy4KCgwKBQUAAgEBEgMgAgoK
DAoFBQACAQISAyANDgqpAQoEBQACAhIDJQILGpsBIFRhc2sgc2hvdWxkIG5vdCBiZSBzdGFy
dGVkLCBvciBpZiBhbHJlYWR5IGluIHByb2dyZXNzLCBzaG91bGQgc3RvcAogYXQgZmlyc3Qg
c2FmZSBzdG9wcGluZyBwb2ludC4gIFRhc2sgc2hvdWxkIGJlIGNvbnNpZGVyZWQgZG9uZSBh
bmQgd2lsbAogbmV2ZXIgcmVwZWF0LgoKDAoFBQACAgESAyUCBgoMCgUFAAICAhIDJQkKCjQK
AgUBEgQpADIBGiggU3BlY2lmaWVzIHRoZSB0eXBlIG9mIHRhc2sgdG8gcGVyZm9ybS4KCgoK
AwUBARIDKQUNCiYKBAUBAgASAysCHBoZIFVuc3BlY2lmaWVkIGlzIGludmFsaWQuCgoMCgUF
AQIAARIDKwIXCgwKBQUBAgACEgMrGhsKJgoEBQECARIDLgIUGhkgVGhlIGFwcGx5IHBhdGNo
ZXMgdGFzay4KCgwKBQUBAgEBEgMuAg8KDAoFBQECAQISAy4SEwoiCgQFAQICEgMxAhUaFSBU
aGUgZXhlYyBzdGVwIHRhc2suCgoMCgUFAQICARIDMQIQCgwKBQUBAgICEgMxExQKOgoCBAAS
BDUATwEaLiBBIHVuaXQgb2Ygd29yayB0byBiZSBwZXJmb3JtZWQgYnkgdGhlIGFnZW50LgoK
CgoDBAABEgM1CAwKHgoEBAACABIDNwIVGhEgVW5pcXVlIHRhc2sgaWQuCgoMCgUEAAIABRID
NwIICgwKBQQAAgABEgM3CRAKDAoFBAACAAMSAzcTFArFAQoEBAACARIDPwIZGrcBIFRoZSB0
eXBlIG9mIHRhc2sgdG8gcGVyZm9ybS4KCiBUYXNrIGRldGFpbHMgbXVzdCBpbmNsdWRlIHRo
ZSBhcHByb3ByaWF0ZSBtZXNzYWdlIGJhc2VkIG9uIHRoaXMgZW51bSBhcwogc3BlY2lmaWVk
IGJlbG93OgogQVBQTFlfUEFUQ0hFUyA9IEFwcGx5UGF0Y2hlc1Rhc2sKIEVYRUNfU1RFUCA9
IEV4ZWNTdGVwVGFzazsKCgwKBQQAAgEGEgM/AgoKDAoFBAACAQESAz8LFAoMCgUEAAIBAxID
PxcYCi4KBAQAAgISA0ICIxohIEN1cnJlbnQgZGlyZWN0aXZlIHRvIHRoZSBhZ2VudC4KCgwK
BQQAAgIGEgNCAg8KDAoFBAACAgESA0IQHgoMCgUEAAICAxIDQiEiCkMKBAQACAASBEUCSwMa
NSBTcGVjaWZpYyBkZXRhaWxzIGFib3V0IHRoZSBjdXJyZW50IHRhc2sgdG8gcGVyZm9ybS4K
CgwKBQQACAABEgNFCBQKPwoEBAACAxIDRwQsGjIgRGV0YWlscyBhYm91dCB0aGUgYXBwbHkg
cGF0Y2hlcyB0YXNrIHRvIHBlcmZvcm0uCgoMCgUEAAIDBhIDRwQUCgwKBQQAAgMBEgNHFScK
DAoFBAACAwMSA0cqKwo7CgQEAAIEEgNKBCQaLiBEZXRhaWxzIGFib3V0IHRoZSBleGVjIHN0
ZXAgdGFzayB0byBwZXJmb3JtLgoKDAoFBAACBAYSA0oEEAoMCgUEAAIEARIDShEfCgwKBQQA
AgQDEgNKIiMKSgoEBAACBRIDTgIpGj0gTGFiZWxzIGRlc2NyaWJpbmcgdGhlIHRhc2suICBV
c2VkIGZvciBsb2dnaW5nIGJ5IHRoZSBhZ2VudC4KCgwKBQQAAgUGEgNOAhUKDAoFBAACBQES
A04WJAoMCgUEAAIFAxIDTicoCj0KAgQBEgRSAFkBGjEgTWVzc2FnZSB3aGljaCBpbnN0cnVj
dHMgYWdlbnQgdG8gYXBwbHkgcGF0Y2hlcy4KCgoKAwQBARIDUggYCkgKBAQBAgASA1QCHxo7
IFNwZWNpZmljIGluZm9ybWF0aW9uIGFib3V0IGhvdyBwYXRjaGVzIHNob3VsZCBiZSBhcHBs
aWVkLgoKDAoFBAECAAYSA1QCDQoMCgUEAQIAARIDVA4aCgwKBQQBAgADEgNUHR4KlAEKBAQB
AgESA1gCExqGASBJZiB0cnVlLCB0aGUgYWdlbnQgd2lsbCByZXBvcnQgaXRzIHN0YXR1cyBh
cyBpdCBnb2VzIHRocm91Z2ggdGhlIG1vdGlvbnMKIGJ1dCB3b24ndCBhY3R1YWxseSBydW4g
YW55IHVwZGF0ZXMgb3IgcGVyZm9ybSBhbnkgcmVib290cy4KCgwKBQQBAgEFEgNYAgYKDAoF
BAECAQESA1gHDgoMCgUEAQIBAxIDWBESClMKAgQCEgRcAHEBGkcgSW5mb3JtYXRpb24gcmVw
b3J0ZWQgZnJvbSB0aGUgYWdlbnQgYWJvdXQgYXBwbHlpbmcgcGF0Y2hlcyBleGVjdXRpb24u
CgoKCgMEAgESA1wIIAo8CgQEAgQAEgReAm0DGi4gVGhlIGludGVybWVkaWF0ZSBzdGF0ZXMg
b2YgYXBwbHlpbmcgcGF0Y2hlcy4KCgwKBQQCBAABEgNeBwwKKAoGBAIEAAIAEgNgBBoaGSBV
bnNwZWNpZmllZCBpcyBpbnZhbGlkLgoKDgoHBAIEAAIAARIDYAQVCg4KBwQCBAACAAISA2AY
GQo2CgYEAgQAAgESA2MEEBonIFRoZSBhZ2VudCBoYXMgc3RhcnRlZCB0aGUgcGF0Y2ggdGFz
ay4KCg4KBwQCBAACAQESA2MECwoOCgcEAgQAAgECEgNjDg8KPAoGBAIEAAICEgNmBBwaLSBU
aGUgYWdlbnQgaXMgY3VycmVudGx5IGRvd25sb2FkaW5nIHBhdGNoZXMuCgoOCgcEAgQAAgIB
EgNmBBcKDgoHBAIEAAICAhIDZhobCjkKBgQCBAACAxIDaQQZGiogVGhlIGFnZW50IGlzIGN1
cnJlbnRseSBhcHBseWluZyBwYXRjaGVzLgoKDgoHBAIEAAIDARIDaQQUCg4KBwQCBAACAwIS
A2kXGApCCgYEAgQAAgQSA2wEEhozIFRoZSBhZ2VudCBpcyBjdXJyZW50bHkgcmVib290aW5n
IHRoZSBWTSBpbnN0YW5jZS4KCg4KBwQCBAACBAESA2wEDQoOCgcEAgQAAgQCEgNsEBEKQwoE
BAICABIDcAI7GjYgUmVxdWlyZWQuIFRoZSBjdXJyZW50IHN0YXRlIG9mIHRoaXMgcGF0Y2gg
ZXhlY3V0aW9uLgoKDAoFBAICAAYSA3ACBwoMCgUEAgIAARIDcAgNCgwKBQQCAgADEgNwEBEK
DAoFBAICAAgSA3ASOgoPCggEAgIACJwIABIDcBM5ClQKAgQDEgV0AIYBARpHIEluZm9ybWF0
aW9uIHJlcG9ydGVkIGZyb20gdGhlIGFnZW50IGFib3V0IGFwcGx5aW5nIHBhdGNoZXMgZXhl
Y3V0aW9uLgoKCgoDBAMBEgN0CB4KNgoEBAMEABIFdgKCAQMaJyBUaGUgZmluYWwgc3RhdGVz
IG9mIGFwcGx5aW5nIHBhdGNoZXMuCgoMCgUEAwQAARIDdgcMCigKBgQDBAACABIDeAQaGhkg
VW5zcGVjaWZpZWQgaXMgaW52YWxpZC4KCg4KBwQDBAACAAESA3gEFQoOCgcEAwQAAgACEgN4
GBkKOQoGBAMEAAIBEgN7BBIaKiBBcHBseWluZyBwYXRjaGVzIGNvbXBsZXRlZCBzdWNjZXNz
ZnVsbHkuCgoOCgcEAwQAAgEBEgN7BA0KDgoHBAMEAAIBAhIDexARClMKBgQDBAACAhIDfgQi
GkQgQXBwbHlpbmcgcGF0Y2hlcyBjb21wbGV0ZWQgc3VjY2Vzc2Z1bGx5LCBidXQgYSByZWJv
b3QgaXMgcmVxdWlyZWQuCgoOCgcEAwQAAgIBEgN+BB0KDgoHBAMEAAICAhIDfiAhCioKBgQD
BAACAxIEgQEEDxoaIEFwcGx5aW5nIHBhdGNoZXMgZmFpbGVkLgoKDwoHBAMEAAIDARIEgQEE
CgoPCgcEAwQAAgMCEgSBAQ0OCjcKBAQDAgASBIUBAjsaKSBSZXF1aXJlZC4gVGhlIGZpbmFs
IHN0YXRlIG9mIHRoaXMgdGFzay4KCg0KBQQDAgAGEgSFAQIHCg0KBQQDAgABEgSFAQgNCg0K
BQQDAgADEgSFARARCg0KBQQDAgAIEgSFARI6ChAKCAQDAgAInAgAEgSFARM5Ck8KAgQEEgaJ
AQCMAQEaQSBNZXNzYWdlIHdoaWNoIGluc3RydWN0cyBhZ2VudCB0byBleGVjdXRlIHRoZSBm
b2xsb3dpbmcgY29tbWFuZC4KCgsKAwQEARIEiQEIFAowCgQEBAIAEgSLAQIZGiIgRGV0YWls
cyBvZiB0aGUgZXhlYyBzdGVwIHRvIHJ1bi4KCg0KBQQEAgAGEgSLAQIKCg0KBQQEAgABEgSL
AQsUCg0KBQQEAgADEgSLARcYClIKAgQFEgaPAQCbAQEaRCBJbmZvcm1hdGlvbiByZXBvcnRl
ZCBmcm9tIHRoZSBhZ2VudCBhYm91dCB0aGUgZXhlYyBzdGVwIGV4ZWN1dGlvbi4KCgsKAwQF
ARIEjwEIHAo4CgQEBQQAEgaRAQKXAQMaKCBUaGUgaW50ZXJtZWRpYXRlIHN0YXRlcyBvZiBl
eGVjIHN0ZXBzLgoKDQoFBAUEAAESBJEBBwwKKQoGBAUEAAIAEgSTAQQaGhkgVW5zcGVjaWZp
ZWQgaXMgaW52YWxpZC4KCg8KBwQFBAACAAESBJMBBBUKDwoHBAUEAAIAAhIEkwEYGQo7CgYE
BQQAAgESBJYBBBAaKyBUaGUgYWdlbnQgaGFzIHN0YXJ0ZWQgdGhlIGV4ZWMgc3RlcCB0YXNr
LgoKDwoHBAUEAAIBARIElgEECwoPCgcEBQQAAgECEgSWAQ4PCj4KBAQFAgASBJoBAjsaMCBS
ZXF1aXJlZC4gVGhlIGN1cnJlbnQgc3RhdGUgb2YgdGhpcyBleGVjIHN0ZXAuCgoNCgUEBQIA
BhIEmgECBwoNCgUEBQIAARIEmgEIDQoNCgUEBQIAAxIEmgEQEQoNCgUEBQIACBIEmgESOgoQ
CggEBQIACJwIABIEmgETOQpSCgIEBhIGngEAswEBGkQgSW5mb3JtYXRpb24gcmVwb3J0ZWQg
ZnJvbSB0aGUgYWdlbnQgYWJvdXQgdGhlIGV4ZWMgc3RlcCBleGVjdXRpb24uCgoLCgMEBgES
BJ4BCBoKMQoEBAYEABIGoAECrAEDGiEgVGhlIGZpbmFsIHN0YXRlcyBvZiBleGVjIHN0ZXBz
LgoKDQoFBAYEAAESBKABBwwKKQoGBAYEAAIAEgSiAQQaGhkgVW5zcGVjaWZpZWQgaXMgaW52
YWxpZC4KCg8KBwQGBAACAAESBKIBBBUKDwoHBAYEAAIAAhIEogEYGQozCgYEBgQAAgESBKUB
BBIaIyBUaGUgZXhlYyBzdGVwIGNvbXBsZXRlZCBub3JtYWxseS4KCg8KBwQGBAACAQESBKUB
BA0KDwoHBAYEAAIBAhIEpQEQEQpICgYEBgQAAgISBKgBBBIaOCBUaGUgZXhlYyBzdGVwIHdh
cyB0ZXJtaW5hdGVkIGJlY2F1c2UgaXQgdG9vayB0b28gbG9uZy4KCg8KBwQGBAACAgESBKgB
BA0KDwoHBAYEAAICAhIEqAEQEQpFCgYEBgQAAgMSBKsBBBIaNSBUaGUgZXhlYyBzdGVwIHRh
c2sgd2FzIGNhbmNlbGxlZCBiZWZvcmUgaXQgc3RhcnRlZC4KCg8KBwQGBAACAwESBKsBBA0K
DwoHBAYEAAIDAhIEqwEQEQo7CgQEBgIAEgSvAQI7Gi0gUmVxdWlyZWQuIFRoZSBmaW5hbCBz
dGF0ZSBvZiB0aGUgZXhlYyBzdGVwLgoKDQoFBAYCAAYSBK8BAgcKDQoFBAYCAAESBK8BCA0K
DQoFBAYCAAMSBK8BEBEKDQoFBAYCAAgSBK8BEjoKEAoIBAYCAAicCAASBK8BEzkKZAoEBAYC
ARIEsgECPxpWIFJlcXVpcmVkLiBUaGUgZXhpdCBjb2RlIHJlY2VpdmVkIGZyb20gdGhlIHNj
cmlwdCB3aGljaCByYW4gYXMgcGFydCBvZiB0aGUgZXhlYyBzdGVwLgoKDQoFBAYCAQUSBLIB
AgcKDQoFBAYCAQESBLIBCBEKDQoFBAYCAQMSBLIBFBUKDQoFBAYCAQgSBLIBFj4KEAoIBAYC
AQicCAASBLIBFz1iBnByb3RvMw==
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Osconfig::Agentendpoint::V1beta::Tasks::Task ===
    # Fields for Task
    # Field: task_id Type: 9 ()
    # Field: task_type Type: 14 (.google.cloud.osconfig.agentendpoint.v1beta.TaskType)
    # Field: task_directive Type: 14 (.google.cloud.osconfig.agentendpoint.v1beta.TaskDirective)
    # Field: apply_patches_task Type: 11 (.google.cloud.osconfig.agentendpoint.v1beta.ApplyPatchesTask)
    # Field: exec_step_task Type: 11 (.google.cloud.osconfig.agentendpoint.v1beta.ExecStepTask)
    # Field: service_labels Type: 11 (.google.cloud.osconfig.agentendpoint.v1beta.Task.ServiceLabelsEntry)

# === Message: Google::Cloud::Osconfig::Agentendpoint::V1beta::Tasks::ApplyPatchesTask ===
    # Fields for ApplyPatchesTask
    # Field: patch_config Type: 11 (.google.cloud.osconfig.agentendpoint.v1beta.PatchConfig)
    # Field: dry_run Type: 8 ()

# === Message: Google::Cloud::Osconfig::Agentendpoint::V1beta::Tasks::ApplyPatchesTaskProgress ===
    # Fields for ApplyPatchesTaskProgress
    # Field: state Type: 14 (.google.cloud.osconfig.agentendpoint.v1beta.ApplyPatchesTaskProgress.State)

# Enum: ApplyPatchesTaskProgress::State
our $ApplyPatchesTaskProgress_STATE_UNSPECIFIED = 0;
our $ApplyPatchesTaskProgress_STARTED = 4;
our $ApplyPatchesTaskProgress_DOWNLOADING_PATCHES = 1;
our $ApplyPatchesTaskProgress_APPLYING_PATCHES = 2;
our $ApplyPatchesTaskProgress_REBOOTING = 3;

# === Message: Google::Cloud::Osconfig::Agentendpoint::V1beta::Tasks::ApplyPatchesTaskOutput ===
    # Fields for ApplyPatchesTaskOutput
    # Field: state Type: 14 (.google.cloud.osconfig.agentendpoint.v1beta.ApplyPatchesTaskOutput.State)

# Enum: ApplyPatchesTaskOutput::State
our $ApplyPatchesTaskOutput_STATE_UNSPECIFIED = 0;
our $ApplyPatchesTaskOutput_SUCCEEDED = 1;
our $ApplyPatchesTaskOutput_SUCCEEDED_REBOOT_REQUIRED = 2;
our $ApplyPatchesTaskOutput_FAILED = 3;

# === Message: Google::Cloud::Osconfig::Agentendpoint::V1beta::Tasks::ExecStepTask ===
    # Fields for ExecStepTask
    # Field: exec_step Type: 11 (.google.cloud.osconfig.agentendpoint.v1beta.ExecStep)

# === Message: Google::Cloud::Osconfig::Agentendpoint::V1beta::Tasks::ExecStepTaskProgress ===
    # Fields for ExecStepTaskProgress
    # Field: state Type: 14 (.google.cloud.osconfig.agentendpoint.v1beta.ExecStepTaskProgress.State)

# Enum: ExecStepTaskProgress::State
our $ExecStepTaskProgress_STATE_UNSPECIFIED = 0;
our $ExecStepTaskProgress_STARTED = 1;

# === Message: Google::Cloud::Osconfig::Agentendpoint::V1beta::Tasks::ExecStepTaskOutput ===
    # Fields for ExecStepTaskOutput
    # Field: state Type: 14 (.google.cloud.osconfig.agentendpoint.v1beta.ExecStepTaskOutput.State)
    # Field: exit_code Type: 5 ()

# Enum: ExecStepTaskOutput::State
our $ExecStepTaskOutput_STATE_UNSPECIFIED = 0;
our $ExecStepTaskOutput_COMPLETED = 1;
our $ExecStepTaskOutput_TIMED_OUT = 2;
our $ExecStepTaskOutput_CANCELLED = 3;

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Osconfig::Agentendpoint::V1beta::Tasks - Compiled Protocol Buffers messages for google/cloud/osconfig/agentendpoint/v1beta/tasks.proto

=head1 SYNOPSIS

    use Google::Cloud::Osconfig::Agentendpoint::V1beta::Tasks;

    my $msg = Google::Cloud::Osconfig::Agentendpoint::V1beta::Tasks::Task->new({
        task_id => $task_id,
        task_type => $task_type,
        task_directive => $task_directive,
        apply_patches_task => $apply_patches_task,
    });

    # Read or update a field
    my $val = $msg->task_id();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Osconfig::Agentendpoint::V1beta::Tasks::Task->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/osconfig/agentendpoint/v1beta/tasks.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Osconfig::Agentendpoint::V1beta::Tasks::Task

A unit of work to be performed by the agent.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->task_id() >> / C<< $msg->task_id($value) >>

Type: C<String>

Unique task id.

=item * C<< $msg->task_type() >> / C<< $msg->task_type($value) >>

Type: C<Enum> (L<Google::Cloud::Osconfig::Agentendpoint::V1beta::TaskType>)

The type of task to perform.

Task details must include the appropriate message based on this enum as
specified below:
APPLY_PATCHES = ApplyPatchesTask
EXEC_STEP = ExecStepTask;

=item * C<< $msg->task_directive() >> / C<< $msg->task_directive($value) >>

Type: C<Enum> (L<Google::Cloud::Osconfig::Agentendpoint::V1beta::TaskDirective>)

Current directive to the agent.

=item * C<< $msg->apply_patches_task() >> / C<< $msg->apply_patches_task($value) >>

Type: C<Message> (L<Google::Cloud::Osconfig::Agentendpoint::V1beta::Tasks::ApplyPatchesTask>)

Details about the apply patches task to perform.

=item * C<< $msg->exec_step_task() >> / C<< $msg->exec_step_task($value) >>

Type: C<Message> (L<Google::Cloud::Osconfig::Agentendpoint::V1beta::Tasks::ExecStepTask>)

Details about the exec step task to perform.

=item * C<< $msg->service_labels() >> / C<< $msg->service_labels($value) >>

Type: C<Message> (L<Google::Cloud::Osconfig::Agentendpoint::V1beta::Tasks::Task::ServiceLabelsEntry>)

Labels describing the task.  Used for logging by the agent.

=back

=head2 Google::Cloud::Osconfig::Agentendpoint::V1beta::Tasks::ApplyPatchesTask

Message which instructs agent to apply patches.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->patch_config() >> / C<< $msg->patch_config($value) >>

Type: C<Message> (L<Google::Cloud::Osconfig::Agentendpoint::V1beta::PatchJobs::PatchConfig>)

Specific information about how patches should be applied.

=item * C<< $msg->dry_run() >> / C<< $msg->dry_run($value) >>

Type: C<Bool>

If true, the agent will report its status as it goes through the motions
but won't actually run any updates or perform any reboots.

=back

=head2 Google::Cloud::Osconfig::Agentendpoint::V1beta::Tasks::ApplyPatchesTaskProgress

Information reported from the agent about applying patches execution.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->state() >> / C<< $msg->state($value) >>

Type: C<Enum> (L<Google::Cloud::Osconfig::Agentendpoint::V1beta::ApplyPatchesTaskProgress::State>)

Required. The current state of this patch execution.

=back

=head3 Enum: ApplyPatchesTaskProgress::State

=over 4

=item * C<STATE_UNSPECIFIED> => C<0>

=item * C<STARTED> => C<4>

=item * C<DOWNLOADING_PATCHES> => C<1>

=item * C<APPLYING_PATCHES> => C<2>

=item * C<REBOOTING> => C<3>

=back

=head2 Google::Cloud::Osconfig::Agentendpoint::V1beta::Tasks::ApplyPatchesTaskOutput

Information reported from the agent about applying patches execution.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->state() >> / C<< $msg->state($value) >>

Type: C<Enum> (L<Google::Cloud::Osconfig::Agentendpoint::V1beta::ApplyPatchesTaskOutput::State>)

Required. The final state of this task.

=back

=head3 Enum: ApplyPatchesTaskOutput::State

=over 4

=item * C<STATE_UNSPECIFIED> => C<0>

=item * C<SUCCEEDED> => C<1>

=item * C<SUCCEEDED_REBOOT_REQUIRED> => C<2>

=item * C<FAILED> => C<3>

=back

=head2 Google::Cloud::Osconfig::Agentendpoint::V1beta::Tasks::ExecStepTask

Message which instructs agent to execute the following command.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->exec_step() >> / C<< $msg->exec_step($value) >>

Type: C<Message> (L<Google::Cloud::Osconfig::Agentendpoint::V1beta::PatchJobs::ExecStep>)

Details of the exec step to run.

=back

=head2 Google::Cloud::Osconfig::Agentendpoint::V1beta::Tasks::ExecStepTaskProgress

Information reported from the agent about the exec step execution.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->state() >> / C<< $msg->state($value) >>

Type: C<Enum> (L<Google::Cloud::Osconfig::Agentendpoint::V1beta::ExecStepTaskProgress::State>)

Required. The current state of this exec step.

=back

=head3 Enum: ExecStepTaskProgress::State

=over 4

=item * C<STATE_UNSPECIFIED> => C<0>

=item * C<STARTED> => C<1>

=back

=head2 Google::Cloud::Osconfig::Agentendpoint::V1beta::Tasks::ExecStepTaskOutput

Information reported from the agent about the exec step execution.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->state() >> / C<< $msg->state($value) >>

Type: C<Enum> (L<Google::Cloud::Osconfig::Agentendpoint::V1beta::ExecStepTaskOutput::State>)

Required. The final state of the exec step.

=item * C<< $msg->exit_code() >> / C<< $msg->exit_code($value) >>

Type: C<Int32>

Required. The exit code received from the script which ran as part of the exec step.

=back

=head3 Enum: ExecStepTaskOutput::State

=over 4

=item * C<STATE_UNSPECIFIED> => C<0>

=item * C<COMPLETED> => C<1>

=item * C<TIMED_OUT> => C<2>

=item * C<CANCELLED> => C<3>

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Osconfig::Agentendpoint::V1beta::Tasks::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
