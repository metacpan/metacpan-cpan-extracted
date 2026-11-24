package Google::Cloud::Discoveryengine::V1::Feedback;

use strict;
use warnings;

our $VERSION = '0.14';

use Protobuf::Message;
use Protobuf::DescriptorPool;
use Protobuf::Internal qw(:all);
use MIME::Base64;

BEGIN {
    eval { require Google::Api::FieldBehavior };
    eval { require Google::Cloud::Discoveryengine::V1::Session };
    my $descriptor_b64 = <<'EOF';
Ci5nb29nbGUvY2xvdWQvZGlzY292ZXJ5ZW5naW5lL3YxL2ZlZWRiYWNrLnByb3RvEh9nb29n
bGUuY2xvdWQuZGlzY292ZXJ5ZW5naW5lLnYxGh9nb29nbGUvYXBpL2ZpZWxkX2JlaGF2aW9y
LnByb3RvGi1nb29nbGUvY2xvdWQvZGlzY292ZXJ5ZW5naW5lL3YxL3Nlc3Npb24ucHJvdG8i
iQsKCEZlZWRiYWNrEmAKDWZlZWRiYWNrX3R5cGUYASABKA4yNi5nb29nbGUuY2xvdWQuZGlz
Y292ZXJ5ZW5naW5lLnYxLkZlZWRiYWNrLkZlZWRiYWNrVHlwZUID4EECUgxmZWVkYmFja1R5
cGUSTwoHcmVhc29ucxgCIAMoDjIwLmdvb2dsZS5jbG91ZC5kaXNjb3ZlcnllbmdpbmUudjEu
RmVlZGJhY2suUmVhc29uQgPgQQFSB3JlYXNvbnMSHQoHY29tbWVudBgDIAEoCUID4EEBUgdj
b21tZW50EmcKEWNvbnZlcnNhdGlvbl9pbmZvGAQgASgLMjouZ29vZ2xlLmNsb3VkLmRpc2Nv
dmVyeWVuZ2luZS52MS5GZWVkYmFjay5Db252ZXJzYXRpb25JbmZvUhBjb252ZXJzYXRpb25J
bmZvEioKEWxsbV9tb2RlbF92ZXJzaW9uGAUgASgJUg9sbG1Nb2RlbFZlcnNpb24SZgoPZmVl
ZGJhY2tfc291cmNlGAYgASgOMjguZ29vZ2xlLmNsb3VkLmRpc2NvdmVyeWVuZ2luZS52MS5G
ZWVkYmFjay5GZWVkYmFja1NvdXJjZUID4EEBUg5mZWVkYmFja1NvdXJjZRIwChFjb21wb25l
bnRfdmVyc2lvbhgHIAEoCUID4EEBUhBjb21wb25lbnRWZXJzaW9uEjMKE2RhdGFfdGVybXNf
YWNjZXB0ZWQYCCABKAhCA+BBAVIRZGF0YVRlcm1zQWNjZXB0ZWQa5AIKEENvbnZlcnNhdGlv
bkluZm8SJQoOcXVlc3Rpb25faW5kZXgYASABKAVSDXF1ZXN0aW9uSW5kZXgSGAoHc2Vzc2lv
bhgCIAEoCVIHc2Vzc2lvbhJBCgVxdWVyeRgDIAEoCzImLmdvb2dsZS5jbG91ZC5kaXNjb3Zl
cnllbmdpbmUudjEuUXVlcnlCA+BBAlIFcXVlcnkSJgoMYXNzaXN0X3Rva2VuGAQgASgJQgPg
QQFSC2Fzc2lzdFRva2VuEjEKEmFuc3dlcl9xdWVyeV90b2tlbhgFIAEoCUID4EEBUhBhbnN3
ZXJRdWVyeVRva2VuEiAKCXRhc2tfbmFtZRgGIAEoCUID4EEBUgh0YXNrTmFtZRIoCg10cmFq
ZWN0b3J5X2lkGAcgASgJQgPgQQFSDHRyYWplY3RvcnlJZBIlCgxzdGVwX3NlcV9udW0YCCAB
KANCA+BBAVIKc3RlcFNlcU51bSJECgxGZWVkYmFja1R5cGUSHQoZRkVFREJBQ0tfVFlQRV9V
TlNQRUNJRklFRBAAEggKBExJS0UQARILCgdESVNMSUtFEAIi7gEKBlJlYXNvbhIWChJSRUFT
T05fVU5TUEVDSUZJRUQQABIXChNJTkFDQ1VSQVRFX1JFU1BPTlNFEAESEAoMTk9UX1JFTEVW
QU5UEAISEwoPSU5DT01QUkVIRU5TSVZFEAMSFwoTT0ZGRU5TSVZFX09SX1VOU0FGRRAEEhUK
EUZPUk1BVF9BTkRfU1RZTEVTEAYSEAoMQkFEX0NJVEFUSU9OEAcSGAoUQ0FOVkFTX05PVF9H
RU5FUkFURUQQCBIWChJDQU5WQVNfUVVBTElUWV9CQUQQCRIYChRDQU5WQVNfRVhQT1JUX0ZB
SUxFRBAKIqgBCg5GZWVkYmFja1NvdXJjZRIfChtGRUVEQkFDS19TT1VSQ0VfVU5TUEVDSUZJ
RUQQABISCg5HT09HTEVfQ09OU09MRRABEhEKDUdPT0dMRV9XSURHRVQQAhIRCg1HT09HTEVf
V0VCQVBQEAMSHAoYR09PR0xFX0FHRU5UU1BBQ0VfTU9CSUxFEAQSHQoZR09PR0xFX0FHRU5U
U1BBQ0VfREVTS1RPUBAFQoACCiNjb20uZ29vZ2xlLmNsb3VkLmRpc2NvdmVyeWVuZ2luZS52
MUINRmVlZGJhY2tQcm90b1ABWk1jbG91ZC5nb29nbGUuY29tL2dvL2Rpc2NvdmVyeWVuZ2lu
ZS9hcGl2MS9kaXNjb3ZlcnllbmdpbmVwYjtkaXNjb3ZlcnllbmdpbmVwYqICD0RJU0NPVkVS
WUVOR0lORaoCH0dvb2dsZS5DbG91ZC5EaXNjb3ZlcnlFbmdpbmUuVjHKAh9Hb29nbGVcQ2xv
dWRcRGlzY292ZXJ5RW5naW5lXFYx6gIiR29vZ2xlOjpDbG91ZDo6RGlzY292ZXJ5RW5naW5l
OjpWMUrNLgoHEgUOAKEBAQq8BAoBDBIDDgASMrEEIENvcHlyaWdodCAyMDI2IEdvb2dsZSBM
TEMKCiBMaWNlbnNlZCB1bmRlciB0aGUgQXBhY2hlIExpY2Vuc2UsIFZlcnNpb24gMi4wICh0
aGUgIkxpY2Vuc2UiKTsKIHlvdSBtYXkgbm90IHVzZSB0aGlzIGZpbGUgZXhjZXB0IGluIGNv
bXBsaWFuY2Ugd2l0aCB0aGUgTGljZW5zZS4KIFlvdSBtYXkgb2J0YWluIGEgY29weSBvZiB0
aGUgTGljZW5zZSBhdAoKICAgICBodHRwOi8vd3d3LmFwYWNoZS5vcmcvbGljZW5zZXMvTElD
RU5TRS0yLjAKCiBVbmxlc3MgcmVxdWlyZWQgYnkgYXBwbGljYWJsZSBsYXcgb3IgYWdyZWVk
IHRvIGluIHdyaXRpbmcsIHNvZnR3YXJlCiBkaXN0cmlidXRlZCB1bmRlciB0aGUgTGljZW5z
ZSBpcyBkaXN0cmlidXRlZCBvbiBhbiAiQVMgSVMiIEJBU0lTLAogV0lUSE9VVCBXQVJSQU5U
SUVTIE9SIENPTkRJVElPTlMgT0YgQU5ZIEtJTkQsIGVpdGhlciBleHByZXNzIG9yIGltcGxp
ZWQuCiBTZWUgdGhlIExpY2Vuc2UgZm9yIHRoZSBzcGVjaWZpYyBsYW5ndWFnZSBnb3Zlcm5p
bmcgcGVybWlzc2lvbnMgYW5kCiBsaW1pdGF0aW9ucyB1bmRlciB0aGUgTGljZW5zZS4KCggK
AQISAxAAKAoJCgIDABIDEgApCgkKAgMBEgMTADcKCAoBCBIDFQA8CgkKAgglEgMVADwKCAoB
CBIDFgBkCgkKAggLEgMWAGQKCAoBCBIDFwAiCgkKAggKEgMXACIKCAoBCBIDGAAuCgkKAggI
EgMYAC4KCAoBCBIDGQA8CgkKAggBEgMZADwKCAoBCBIDGgAtCgkKAggkEgMaAC0KCAoBCBID
GwA8CgkKAggpEgMbADwKCAoBCBIDHAA7CgkKAggtEgMcADsKcwoCBAASBSAAoQEBGmYgSW5m
b3JtYXRpb24gYWJvdXQgdGhlIHVzZXIgZmVlZGJhY2suIFRoaXMgaW5mb3JtYXRpb24gd2ls
bCBiZSB1c2VkIGZvcgogbG9nZ2luZyBhbmQgbWV0cmljcyBwdXJwb3NlLgoKCgoDBAABEgMg
CBAKWQoEBAADABIEIgJAAxpLIFRoZSBjb252ZXJzYXRpb24gaW5mb3JtYXRpb24gc3VjaCBh
cyB0aGUgcXVlc3Rpb24gaW5kZXggYW5kIHNlc3Npb24gbmFtZS4KCgwKBQQAAwABEgMiChoK
TgoGBAADAAIAEgMkBB0aPyBUaGUgaW5kZXggb2YgdGhlIHVzZXIgaW5wdXQgd2l0aGluIHRo
ZSBjb252ZXJzYXRpb24gbWVzc2FnZXMuCgoOCgcEAAMAAgAFEgMkBAkKDgoHBAADAAIAARID
JAoYCg4KBwQAAwACAAMSAyQbHApCCgYEAAMAAgESAycEFxozIE5hbWUgb2YgdGhlIG5ld2x5
IGdlbmVyYXRlZCBvciBjb250aW51ZWQgc2Vzc2lvbi4KCg4KBwQAAwACAQUSAycECgoOCgcE
AAMAAgEBEgMnCxIKDgoHBAADAAIBAxIDJxUWCjMKBgQAAwACAhIDKgQ9GiQgUmVxdWlyZWQu
IFRoZSB1c2VyJ3Mgc2VhcmNoIHF1ZXJ5LgoKDgoHBAADAAICBhIDKgQJCg4KBwQAAwACAgES
AyoKDwoOCgcEAAMAAgIDEgMqEhMKDgoHBAADAAICCBIDKhQ8ChEKCgQAAwACAgicCAASAyoV
OwpUCgYEAAMAAgMSAy0ERRpFIE9wdGlvbmFsLiBUaGUgdG9rZW4gd2hpY2ggY291bGQgYmUg
dXNlZCB0byBmZXRjaCB0aGUgYXNzaXN0YW50IGxvZy4KCg4KBwQAAwACAwUSAy0ECgoOCgcE
AAMAAgMBEgMtCxcKDgoHBAADAAIDAxIDLRobCg4KBwQAAwACAwgSAy0cRAoRCgoEAAMAAgMI
nAgAEgMtHUMKUQoGBAADAAIEEgMwBEsaQiBPcHRpb25hbC4gVGhlIHRva2VuIHdoaWNoIGNv
dWxkIGJlIHVzZWQgdG8gZmV0Y2ggdGhlIGFuc3dlciBsb2cuCgoOCgcEAAMAAgQFEgMwBAoK
DgoHBAADAAIEARIDMAsdCg4KBwQAAwACBAMSAzAgIQoOCgcEAAMAAgQIEgMwIkoKEQoKBAAD
AAIECJwIABIDMCNJCsQCCgYEAAMAAgUSAzcEQhq0AiBPcHRpb25hbC4gVGhlIGZ1bGwgcmVz
b3VyY2UgbmFtZSBvZiB0aGUgU29iaSB0YXNrIGlmIHRoZSBjb252ZXJzYXRpb24gd2FzCiBo
YW5kbGVkIGJ5IGEgbG9uZy1ydW5uaW5nIGFnZW50IHRhc2suIEZvcm1hdCAoY2Fub25pY2Fs
LCBvciB0aGUgc2hvcnQKIGFsaWFzIHRoZSBUYXNrIEFQSSBhbHNvIGFjY2VwdHMpOgogICBw
cm9qZWN0cy97cHJvamVjdH0vbG9jYXRpb25zL3tsb2NhdGlvbn0vYWdlbnRzL3thZ2VudH0v
dGFza3Mve3Rhc2t9CiAgIHByb2plY3RzL3twcm9qZWN0fS9sb2NhdGlvbnMve2xvY2F0aW9u
fS90YXNrcy97dGFza30KCg4KBwQAAwACBQUSAzcECgoOCgcEAAMAAgUBEgM3CxQKDgoHBAAD
AAIFAxIDNxcYCg4KBwQAAwACBQgSAzcZQQoRCgoEAAMAAgUInAgAEgM3GkAKoAEKBgQAAwAC
BhIDOwRGGpABIE9wdGlvbmFsLiBUaGUgcnVudGltZSB0cmFqZWN0b3J5IGlkIG9mIHRoZSBy
YXRlZCBhZ2VudCB0YXNrIHR1cm4sIGFzIHNldAogb24gYFRhc2tTZXJ2ZXJFdmVudC50cmFq
ZWN0b3J5X2lkYC4gU2hhcmVkIGJ5IGFsbCBzdGVwcyBvZiB0aGUgdHVybi4KCg4KBwQAAwAC
BgUSAzsECgoOCgcEAAMAAgYBEgM7CxgKDgoHBAADAAIGAxIDOxscCg4KBwQAAwACBggSAzsd
RQoRCgoEAAMAAgYInAgAEgM7HkQKbQoGBAADAAIHEgM/BEQaXiBPcHRpb25hbC4gVGhlIGBU
YXNrU2VydmVyRXZlbnQuc2VxX251bWAgb2YgdGhlIHN0ZXAgdGhhdCBvcGVuZWQgdGhlIHJh
dGVkCiBhZ2VudCB0YXNrIHJlcGx5LgoKDgoHBAADAAIHBRIDPwQJCg4KBwQAAwACBwESAz8K
FgoOCgcEAAMAAgcDEgM/GRoKDgoHBAADAAIHCBIDPxtDChEKCgQAAwACBwicCAASAz8cQgo0
CgQEAAQAEgRDAkwDGiYgVGhlIHR5cGUgb2YgdGhlIGZlZWRiYWNrIHVzZXIgZ2l2ZXMuCgoM
CgUEAAQAARIDQwcTCisKBgQABAACABIDRQQiGhwgVW5zcGVjaWZpZWQgZmVlZGJhY2sgdHlw
ZS4KCg4KBwQABAACAAESA0UEHQoOCgcEAAQAAgACEgNFICEKNAoGBAAEAAIBEgNIBA0aJSBU
aGUgdXNlciBnaXZlcyBhIHBvc2l0aXZlIGZlZWRiYWNrLgoKDgoHBAAEAAIBARIDSAQICg4K
BwQABAACAQISA0gLDAo0CgYEAAQAAgISA0sEEBolIFRoZSB1c2VyIGdpdmVzIGEgbmVnYXRp
dmUgZmVlZGJhY2suCgoOCgcEAAQAAgIBEgNLBAsKDgoHBAAEAAICAhIDSw4PCj4KBAQABAES
BE8CbwMaMCBUaGUgcmVhc29uIHdoeSB1c2VyIGdpdmVzIGEgbmVnYXRpdmUgZmVlZGJhY2su
CgoMCgUEAAQBARIDTwcNCiQKBgQABAECABIDUQQbGhUgVW5zcGVjaWZpZWQgcmVhc29uLgoK
DgoHBAAEAQIAARIDUQQWCg4KBwQABAECAAISA1EZGgosCgYEAAQBAgESA1QEHBodIFRoZSBy
ZXNwb25zZSBpcyBpbmFjY3VyYXRlLgoKDgoHBAAEAQIBARIDVAQXCg4KBwQABAECAQISA1Qa
GwouCgYEAAQBAgISA1cEFRofIFRoZSByZXNwb25zZSBpcyBub3QgcmVsZXZhbnQuCgoOCgcE
AAQBAgIBEgNXBBAKDgoHBAAEAQICAhIDVxMUCjEKBgQABAECAxIDWgQYGiIgVGhlIHJlc3Bv
bnNlIGlzIGluY29tcHJlaGVuc2l2ZS4KCg4KBwQABAECAwESA1oEEwoOCgcEAAQBAgMCEgNa
FhcKNQoGBAAEAQIEEgNdBBwaJiBUaGUgcmVzcG9uc2UgaXMgb2ZmZW5zaXZlIG9yIHVuc2Fm
ZS4KCg4KBwQABAECBAESA10EFwoOCgcEAAQBAgQCEgNdGhsKNAoGBAAEAQIFEgNgBBoaJSBU
aGUgcmVzcG9uc2UgaXMgbm90IHdlbGwtZm9ybWF0dGVkLgoKDgoHBAAEAQIFARIDYAQVCg4K
BwQABAECBQISA2AYGQpECgYEAAQBAgYSA2MEFRo1IFRoZSByZXNwb25zZSBpcyBub3Qgd2Vs
bC1hc3NvY2lhdGVkIHdpdGggdGhlIHF1ZXJ5LgoKDgoHBAAEAQIGARIDYwQQCg4KBwQABAEC
BgISA2MTFApICgYEAAQBAgcSA2YEHRo5IFRoZSBleHBlY3RlZCBjYW52YXMgd2FzIG5vdCBn
ZW5lcmF0ZWQgZm9yIHRoZSByZXNwb25zZS4KCg4KBwQABAECBwESA2YEGAoOCgcEAAQBAgcC
EgNmGxwKaQoGBAAEAQIIEgNqBBsaWiBUaGUgZ2VuZXJhdGVkIGNhbnZhcyBpcyBvZiBiYWQg
cXVhbGl0eSAoZS5nLiBpbmFjY3VyYXRlLCBpbmNvbXBsZXRlLAogcG9vcmx5IGZvcm1hdHRl
ZCkuCgoOCgcEAAQBAggBEgNqBBYKDgoHBAAEAQIIAhIDahkaCoABCgYEAAQBAgkSA24EHhpx
IEV4cG9ydGluZyB0aGUgZ2VuZXJhdGVkIGNhbnZhcyBmYWlsZWQgKGUuZy4gZG93bmxvYWQg
b3IgZXh0ZXJuYWwKIGV4cG9ydCBhY3Rpb24gZGlkIG5vdCBjb21wbGV0ZSBzdWNjZXNzZnVs
bHkpLgoKDgoHBAAEAQIJARIDbgQYCg4KBwQABAECCQISA24bHQo7CgQEAAQCEgVyAoQBAxos
IFNvdXJjZSBvZiB0aGUgZmVlZGJhY2sgYXMgcGVyIGludGVncmF0aW9uLgoKDAoFBAAEAgES
A3IHFQotCgYEAAQCAgASA3QEJBoeIFVuc3BlY2lmaWVkIGZlZWRiYWNrIHNvdXJjZS4KCg4K
BwQABAICAAESA3QEHwoOCgcEAAQCAgACEgN0IiMKMwoGBAAEAgIBEgN3BBcaJCBGZWVkYmFj
ayBzb3VyY2UgaXMgR29vZ2xlIENvbnNvbGUuCgoOCgcEAAQCAgEBEgN3BBIKDgoHBAAEAgIB
AhIDdxUWCjIKBgQABAICAhIDegQWGiMgRmVlZGJhY2sgc291cmNlIGlzIEdvb2dsZSBXaWRn
ZXQuCgoOCgcEAAQCAgIBEgN6BBEKDgoHBAAEAgICAhIDehQVCjIKBgQABAICAxIDfQQWGiMg
RmVlZGJhY2sgc291cmNlIGlzIEdvb2dsZSBXZWJhcHAuCgoOCgcEAAQCAgMBEgN9BBEKDgoH
BAAEAgIDAhIDfRQVCkIKBgQABAICBBIEgAEEIRoyIEZlZWRiYWNrIHNvdXJjZSBpcyBHb29n
bGUgQWdlbnRTcGFjZSBNb2JpbGUgYXBwLgoKDwoHBAAEAgIEARIEgAEEHAoPCgcEAAQCAgQC
EgSAAR8gCkMKBgQABAICBRIEgwEEIhozIEZlZWRiYWNrIHNvdXJjZSBpcyBHb29nbGUgQWdl
bnRTcGFjZSBEZXNrdG9wIGFwcC4KCg8KBwQABAICBQESBIMBBB0KDwoHBAAEAgIFAhIEgwEg
IQqqAQoEBAACABIEiQECShqbASBSZXF1aXJlZC4gSW5kaWNhdGUgd2hldGhlciB0aGUgdXNl
ciBnaXZlcyBhIHBvc2l0aXZlIG9yIG5lZ2F0aXZlIGZlZWRiYWNrLgogSWYgdGhlIHVzZXIg
Z2l2ZXMgYSBuZWdhdGl2ZSBmZWVkYmFjaywgdGhlcmUgbWlnaHQgYmUgbW9yZSBmZWVkYmFj
awogZGV0YWlscy4KCg0KBQQAAgAGEgSJAQIOCg0KBQQAAgABEgSJAQ8cCg0KBQQAAgADEgSJ
AR8gCg0KBQQAAgAIEgSJASFJChAKCAQAAgAInAgAEgSJASJICkAKBAQAAgESBIwBAkcaMiBP
cHRpb25hbC4gVGhlIHJlYXNvbiBpZiB1c2VyIGdpdmVzIGEgdGh1bWIgZG93bi4KCg0KBQQA
AgEEEgSMAQIKCg0KBQQAAgEGEgSMAQsRCg0KBQQAAgEBEgSMARIZCg0KBQQAAgEDEgSMARwd
Cg0KBQQAAgEIEgSMAR5GChAKCAQAAgEInAgAEgSMAR9FCmIKBAQAAgISBJABAj4aVCBPcHRp
b25hbC4gVGhlIGFkZGl0aW9uYWwgdXNlciBjb21tZW50IG9mIHRoZSBmZWVkYmFjayBpZiB1
c2VyIGdpdmVzIGEgdGh1bWIKIGRvd24uCgoNCgUEAAICBRIEkAECCAoNCgUEAAICARIEkAEJ
EAoNCgUEAAICAxIEkAETFAoNCgUEAAICCBIEkAEVPQoQCggEAAICCJwIABIEkAEWPApOCgQE
AAIDEgSTAQIpGkAgVGhlIHJlbGF0ZWQgY29udmVyc2F0aW9uIGluZm9ybWF0aW9uIHdoZW4g
dXNlciBnaXZlcyBmZWVkYmFjay4KCg0KBQQAAgMGEgSTAQISCg0KBQQAAgMBEgSTARMkCg0K
BQQAAgMDEgSTAScoClQKBAQAAgQSBJYBAh8aRiBUaGUgdmVyc2lvbiBvZiB0aGUgTExNIG1v
ZGVsIHRoYXQgd2FzIHVzZWQgdG8gZ2VuZXJhdGUgdGhlIHJlc3BvbnNlLgoKDQoFBAACBAUS
BJYBAggKDQoFBAACBAESBJYBCRoKDQoFBAACBAMSBJYBHR4KhgEKBAQAAgUSBJoBAk4aeCBP
cHRpb25hbC4gVGhlIFVJIGNvbXBvbmVudCB0aGUgdXNlciBmZWVkYmFjayBjb21lcyBmcm9t
LCB3aGljaCBjb3VsZCBiZQogR09PR0xFX0NPTlNPTEUsIEdPT0dMRV9XSURHRVQsIEdPT0dM
RV9XRUJBUFAuCgoNCgUEAAIFBhIEmgECEAoNCgUEAAIFARIEmgERIAoNCgUEAAIFAxIEmgEj
JAoNCgUEAAIFCBIEmgElTQoQCggEAAIFCJwIABIEmgEmTApbCgQEAAIGEgSdAQJIGk0gT3B0
aW9uYWwuIFRoZSB2ZXJzaW9uIG9mIHRoZSBjb21wb25lbnQgdGhhdCB0aGlzIHJlcG9ydCBp
cyBiZWluZyBzZW50IGZyb20uCgoNCgUEAAIGBRIEnQECCAoNCgUEAAIGARIEnQEJGgoNCgUE
AAIGAxIEnQEdHgoNCgUEAAIGCBIEnQEfRwoQCggEAAIGCJwIABIEnQEgRgpHCgQEAAIHEgSg
AQJIGjkgT3B0aW9uYWwuIFdoZXRoZXIgdGhlIGN1c3RvbWVyIGFjY2VwdGVkIGRhdGEgdXNl
IHRlcm1zLgoKDQoFBAACBwUSBKABAgYKDQoFBAACBwESBKABBxoKDQoFBAACBwMSBKABHR4K
DQoFBAACBwgSBKABH0cKEAoIBAACBwicCAASBKABIEZiBnByb3RvMw==
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Discoveryengine::V1::Feedback::Feedback ===
    # Fields for Feedback
    # Field: feedback_type Type: 14 (.google.cloud.discoveryengine.v1.Feedback.FeedbackType)
    # Field: reasons Type: 14 (.google.cloud.discoveryengine.v1.Feedback.Reason)
    # Field: comment Type: 9 ()
    # Field: conversation_info Type: 11 (.google.cloud.discoveryengine.v1.Feedback.ConversationInfo)
    # Field: llm_model_version Type: 9 ()
    # Field: feedback_source Type: 14 (.google.cloud.discoveryengine.v1.Feedback.FeedbackSource)
    # Field: component_version Type: 9 ()
    # Field: data_terms_accepted Type: 8 ()

# Enum: Feedback::FeedbackType
our $Feedback_FEEDBACK_TYPE_UNSPECIFIED = 0;
our $Feedback_LIKE = 1;
our $Feedback_DISLIKE = 2;

# Enum: Feedback::Reason
our $Feedback_REASON_UNSPECIFIED = 0;
our $Feedback_INACCURATE_RESPONSE = 1;
our $Feedback_NOT_RELEVANT = 2;
our $Feedback_INCOMPREHENSIVE = 3;
our $Feedback_OFFENSIVE_OR_UNSAFE = 4;
our $Feedback_FORMAT_AND_STYLES = 6;
our $Feedback_BAD_CITATION = 7;
our $Feedback_CANVAS_NOT_GENERATED = 8;
our $Feedback_CANVAS_QUALITY_BAD = 9;
our $Feedback_CANVAS_EXPORT_FAILED = 10;

# Enum: Feedback::FeedbackSource
our $Feedback_FEEDBACK_SOURCE_UNSPECIFIED = 0;
our $Feedback_GOOGLE_CONSOLE = 1;
our $Feedback_GOOGLE_WIDGET = 2;
our $Feedback_GOOGLE_WEBAPP = 3;
our $Feedback_GOOGLE_AGENTSPACE_MOBILE = 4;
our $Feedback_GOOGLE_AGENTSPACE_DESKTOP = 5;

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Discoveryengine::V1::Feedback - Compiled Protocol Buffers messages for google/cloud/discoveryengine/v1/feedback.proto

=head1 SYNOPSIS

    use Google::Cloud::Discoveryengine::V1::Feedback;

    my $msg = Google::Cloud::Discoveryengine::V1::Feedback::Feedback->new({
        feedback_type => $feedback_type,
        reasons => $reasons,
        comment => $comment,
        conversation_info => $conversation_info,
    });

    # Read or update a field
    my $val = $msg->feedback_type();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Discoveryengine::V1::Feedback::Feedback->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/discoveryengine/v1/feedback.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Discoveryengine::V1::Feedback::Feedback

Information about the user feedback. This information will be used for
logging and metrics purpose.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->feedback_type() >> / C<< $msg->feedback_type($value) >>

Type: C<Enum> (L<Google::Cloud::Discoveryengine::V1::Feedback::FeedbackType>)

Required. Indicate whether the user gives a positive or negative feedback.
If the user gives a negative feedback, there might be more feedback
details.

=item * C<< $msg->reasons() >> / C<< $msg->reasons($value) >>

Type: C<Enum> (L<Google::Cloud::Discoveryengine::V1::Feedback::Reason>)

Optional. The reason if user gives a thumb down.

=item * C<< $msg->comment() >> / C<< $msg->comment($value) >>

Type: C<String>

Optional. The additional user comment of the feedback if user gives a thumb
down.

=item * C<< $msg->conversation_info() >> / C<< $msg->conversation_info($value) >>

Type: C<Message> (L<Google::Cloud::Discoveryengine::V1::Feedback::Feedback::ConversationInfo>)

The related conversation information when user gives feedback.

=item * C<< $msg->llm_model_version() >> / C<< $msg->llm_model_version($value) >>

Type: C<String>

The version of the LLM model that was used to generate the response.

=item * C<< $msg->feedback_source() >> / C<< $msg->feedback_source($value) >>

Type: C<Enum> (L<Google::Cloud::Discoveryengine::V1::Feedback::FeedbackSource>)

Optional. The UI component the user feedback comes from, which could be
GOOGLE_CONSOLE, GOOGLE_WIDGET, GOOGLE_WEBAPP.

=item * C<< $msg->component_version() >> / C<< $msg->component_version($value) >>

Type: C<String>

Optional. The version of the component that this report is being sent from.

=item * C<< $msg->data_terms_accepted() >> / C<< $msg->data_terms_accepted($value) >>

Type: C<Bool>

Optional. Whether the customer accepted data use terms.

=back

=head3 Enum: Feedback::FeedbackType

=over 4

=item * C<FEEDBACK_TYPE_UNSPECIFIED> => C<0>

=item * C<LIKE> => C<1>

=item * C<DISLIKE> => C<2>

=back

=head3 Enum: Feedback::Reason

=over 4

=item * C<REASON_UNSPECIFIED> => C<0>

=item * C<INACCURATE_RESPONSE> => C<1>

=item * C<NOT_RELEVANT> => C<2>

=item * C<INCOMPREHENSIVE> => C<3>

=item * C<OFFENSIVE_OR_UNSAFE> => C<4>

=item * C<FORMAT_AND_STYLES> => C<6>

=item * C<BAD_CITATION> => C<7>

=item * C<CANVAS_NOT_GENERATED> => C<8>

=item * C<CANVAS_QUALITY_BAD> => C<9>

=item * C<CANVAS_EXPORT_FAILED> => C<10>

=back

=head3 Enum: Feedback::FeedbackSource

=over 4

=item * C<FEEDBACK_SOURCE_UNSPECIFIED> => C<0>

=item * C<GOOGLE_CONSOLE> => C<1>

=item * C<GOOGLE_WIDGET> => C<2>

=item * C<GOOGLE_WEBAPP> => C<3>

=item * C<GOOGLE_AGENTSPACE_MOBILE> => C<4>

=item * C<GOOGLE_AGENTSPACE_DESKTOP> => C<5>

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Discoveryengine::V1::Feedback::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
