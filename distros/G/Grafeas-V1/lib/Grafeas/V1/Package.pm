package Grafeas::V1::Package;

use strict;
use warnings;

our $VERSION = '0.14';

use Protobuf::Message;
use Protobuf::DescriptorPool;
use Protobuf::Internal qw(:all);
use MIME::Base64;

BEGIN {
    eval { require Google::Api::FieldBehavior };
    eval { require Grafeas::V1::Common };
    my $descriptor_b64 = <<'EOF';
ChhncmFmZWFzL3YxL3BhY2thZ2UucHJvdG8SCmdyYWZlYXMudjEaH2dvb2dsZS9hcGkvZmll
bGRfYmVoYXZpb3IucHJvdG8aF2dyYWZlYXMvdjEvY29tbW9uLnByb3RvIvoBCgxEaXN0cmli
dXRpb24SHAoHY3BlX3VyaRgBIAEoCUID4EECUgZjcGVVcmkSPAoMYXJjaGl0ZWN0dXJlGAIg
ASgOMhguZ3JhZmVhcy52MS5BcmNoaXRlY3R1cmVSDGFyY2hpdGVjdHVyZRI6Cg5sYXRlc3Rf
dmVyc2lvbhgDIAEoCzITLmdyYWZlYXMudjEuVmVyc2lvblINbGF0ZXN0VmVyc2lvbhIeCgpt
YWludGFpbmVyGAQgASgJUgptYWludGFpbmVyEhAKA3VybBgFIAEoCVIDdXJsEiAKC2Rlc2Ny
aXB0aW9uGAYgASgJUgtkZXNjcmlwdGlvbiJmCghMb2NhdGlvbhIXCgdjcGVfdXJpGAEgASgJ
UgZjcGVVcmkSLQoHdmVyc2lvbhgCIAEoCzITLmdyYWZlYXMudjEuVmVyc2lvblIHdmVyc2lv
bhISCgRwYXRoGAMgASgJUgRwYXRoIr8DCgtQYWNrYWdlTm90ZRIaCgRuYW1lGAEgASgJQgbg
QQLgQQVSBG5hbWUSPAoMZGlzdHJpYnV0aW9uGAogAygLMhguZ3JhZmVhcy52MS5EaXN0cmli
dXRpb25SDGRpc3RyaWJ1dGlvbhIhCgxwYWNrYWdlX3R5cGUYCyABKAlSC3BhY2thZ2VUeXBl
EhcKB2NwZV91cmkYDCABKAlSBmNwZVVyaRI8CgxhcmNoaXRlY3R1cmUYDSABKA4yGC5ncmFm
ZWFzLnYxLkFyY2hpdGVjdHVyZVIMYXJjaGl0ZWN0dXJlEi0KB3ZlcnNpb24YDiABKAsyEy5n
cmFmZWFzLnYxLlZlcnNpb25SB3ZlcnNpb24SHgoKbWFpbnRhaW5lchgPIAEoCVIKbWFpbnRh
aW5lchIQCgN1cmwYECABKAlSA3VybBIgCgtkZXNjcmlwdGlvbhgRIAEoCVILZGVzY3JpcHRp
b24SLQoHbGljZW5zZRgSIAEoCzITLmdyYWZlYXMudjEuTGljZW5zZVIHbGljZW5zZRIqCgZk
aWdlc3QYEyADKAsyEi5ncmFmZWFzLnYxLkRpZ2VzdFIGZGlnZXN0Is0CChFQYWNrYWdlT2Nj
dXJyZW5jZRIaCgRuYW1lGAEgASgJQgbgQQLgQQNSBG5hbWUSMAoIbG9jYXRpb24YAiADKAsy
FC5ncmFmZWFzLnYxLkxvY2F0aW9uUghsb2NhdGlvbhImCgxwYWNrYWdlX3R5cGUYAyABKAlC
A+BBA1ILcGFja2FnZVR5cGUSHAoHY3BlX3VyaRgEIAEoCUID4EEDUgZjcGVVcmkSQQoMYXJj
aGl0ZWN0dXJlGAUgASgOMhguZ3JhZmVhcy52MS5BcmNoaXRlY3R1cmVCA+BBA1IMYXJjaGl0
ZWN0dXJlEi0KB2xpY2Vuc2UYBiABKAsyEy5ncmFmZWFzLnYxLkxpY2Vuc2VSB2xpY2Vuc2US
MgoHdmVyc2lvbhgHIAEoCzITLmdyYWZlYXMudjEuVmVyc2lvbkID4EEDUgd2ZXJzaW9uIpIC
CgdWZXJzaW9uEhQKBWVwb2NoGAEgASgFUgVlcG9jaBISCgRuYW1lGAIgASgJUgRuYW1lEhoK
CHJldmlzaW9uGAMgASgJUghyZXZpc2lvbhIcCglpbmNsdXNpdmUYBiABKAhSCWluY2x1c2l2
ZRIzCgRraW5kGAQgASgOMh8uZ3JhZmVhcy52MS5WZXJzaW9uLlZlcnNpb25LaW5kUgRraW5k
EhsKCWZ1bGxfbmFtZRgFIAEoCVIIZnVsbE5hbWUiUQoLVmVyc2lvbktpbmQSHAoYVkVSU0lP
Tl9LSU5EX1VOU1BFQ0lGSUVEEAASCgoGTk9STUFMEAESCwoHTUlOSU1VTRACEgsKB01BWElN
VU0QAyo+CgxBcmNoaXRlY3R1cmUSHAoYQVJDSElURUNUVVJFX1VOU1BFQ0lGSUVEEAASBwoD
WDg2EAESBwoDWDY0EAJCUQoNaW8uZ3JhZmVhcy52MVABWjhnb29nbGUuZ29sYW5nLm9yZy9n
ZW5wcm90by9nb29nbGVhcGlzL2dyYWZlYXMvdjE7Z3JhZmVhc6ICA0dSQUrWOAoHEgUOAL8B
AQraBAoBDBIDDgASMs8EIENvcHlyaWdodCAyMDE5IFRoZSBHcmFmZWFzIEF1dGhvcnMuIEFs
bCByaWdodHMgcmVzZXJ2ZWQuCgogTGljZW5zZWQgdW5kZXIgdGhlIEFwYWNoZSBMaWNlbnNl
LCBWZXJzaW9uIDIuMCAodGhlICJMaWNlbnNlIik7CiB5b3UgbWF5IG5vdCB1c2UgdGhpcyBm
aWxlIGV4Y2VwdCBpbiBjb21wbGlhbmNlIHdpdGggdGhlIExpY2Vuc2UuCiBZb3UgbWF5IG9i
dGFpbiBhIGNvcHkgb2YgdGhlIExpY2Vuc2UgYXQKCiAgICBodHRwOi8vd3d3LmFwYWNoZS5v
cmcvbGljZW5zZXMvTElDRU5TRS0yLjAKCiBVbmxlc3MgcmVxdWlyZWQgYnkgYXBwbGljYWJs
ZSBsYXcgb3IgYWdyZWVkIHRvIGluIHdyaXRpbmcsIHNvZnR3YXJlCiBkaXN0cmlidXRlZCB1
bmRlciB0aGUgTGljZW5zZSBpcyBkaXN0cmlidXRlZCBvbiBhbiAiQVMgSVMiIEJBU0lTLAog
V0lUSE9VVCBXQVJSQU5USUVTIE9SIENPTkRJVElPTlMgT0YgQU5ZIEtJTkQsIGVpdGhlciBl
eHByZXNzIG9yIGltcGxpZWQuCiBTZWUgdGhlIExpY2Vuc2UgZm9yIHRoZSBzcGVjaWZpYyBs
YW5ndWFnZSBnb3Zlcm5pbmcgcGVybWlzc2lvbnMgYW5kCiBsaW1pdGF0aW9ucyB1bmRlciB0
aGUgTGljZW5zZS4KCggKAQISAxAAEwoJCgIDABIDEgApCgkKAgMBEgMTACEKCAoBCBIDFQBP
CgkKAggLEgMVAE8KCAoBCBIDFgAiCgkKAggKEgMWACIKCAoBCBIDFwAmCgkKAggBEgMXACYK
CAoBCBIDGAAhCgkKAggkEgMYACEKUgoCBQASBBsAIgEaRiBJbnN0cnVjdGlvbiBzZXQgYXJj
aGl0ZWN0dXJlcyBzdXBwb3J0ZWQgYnkgdmFyaW91cyBwYWNrYWdlIG1hbmFnZXJzLgoKCgoD
BQABEgMbBREKJAoEBQACABIDHQIfGhcgVW5rbm93biBhcmNoaXRlY3R1cmUuCgoMCgUFAAIA
ARIDHQIaCgwKBQUAAgACEgMdHR4KIAoEBQACARIDHwIKGhMgWDg2IGFyY2hpdGVjdHVyZS4K
CgwKBQUAAgEBEgMfAgUKDAoFBQACAQISAx8ICQogCgQFAAICEgMhAgoaEyBYNjQgYXJjaGl0
ZWN0dXJlLgoKDAoFBQACAgESAyECBQoMCgUFAAICAhIDIQgJCoUBCgIEABIEJgA6ARp5IFRo
aXMgcmVwcmVzZW50cyBhIHBhcnRpY3VsYXIgY2hhbm5lbCBvZiBkaXN0cmlidXRpb24gZm9y
IGEgZ2l2ZW4gcGFja2FnZS4KIEUuZy4sIERlYmlhbidzIGplc3NpZS1iYWNrcG9ydHMgZHBr
ZyBtaXJyb3IuCgoKCgMEAAESAyYIFAqPAQoEBAACABIDKQI+GoEBIFRoZSBjcGVfdXJpIGlu
IFtDUEUgZm9ybWF0XShodHRwczovL2NwZS5taXRyZS5vcmcvc3BlY2lmaWNhdGlvbi8pCiBk
ZW5vdGluZyB0aGUgcGFja2FnZSBtYW5hZ2VyIHZlcnNpb24gZGlzdHJpYnV0aW5nIGEgcGFj
a2FnZS4KCgwKBQQAAgAFEgMpAggKDAoFBAACAAESAykJEAoMCgUEAAIAAxIDKRMUCgwKBQQA
AgAIEgMpFT0KDwoIBAACAAicCAASAykWPApgCgQEAAIBEgMtAiAaUyBUaGUgQ1BVIGFyY2hp
dGVjdHVyZSBmb3Igd2hpY2ggcGFja2FnZXMgaW4gdGhpcyBkaXN0cmlidXRpb24gY2hhbm5l
bCB3ZXJlCiBidWlsdC4KCgwKBQQAAgEGEgMtAg4KDAoFBAACAQESAy0PGwoMCgUEAAIBAxID
LR4fClkKBAQAAgISAzACHRpMIFRoZSBsYXRlc3QgYXZhaWxhYmxlIHZlcnNpb24gb2YgdGhp
cyBwYWNrYWdlIGluIHRoaXMgZGlzdHJpYnV0aW9uIGNoYW5uZWwuCgoMCgUEAAICBhIDMAIJ
CgwKBQQAAgIBEgMwChgKDAoFBAACAgMSAzAbHApJCgQEAAIDEgMzAhgaPCBBIGZyZWVmb3Jt
IHN0cmluZyBkZW5vdGluZyB0aGUgbWFpbnRhaW5lciBvZiB0aGlzIHBhY2thZ2UuCgoMCgUE
AAIDBRIDMwIICgwKBQQAAgMBEgMzCRMKDAoFBAACAwMSAzMWFwpLCgQEAAIEEgM2AhEaPiBU
aGUgZGlzdHJpYnV0aW9uIGNoYW5uZWwtc3BlY2lmaWMgaG9tZXBhZ2UgZm9yIHRoaXMgcGFj
a2FnZS4KCgwKBQQAAgQFEgM2AggKDAoFBAACBAESAzYJDAoMCgUEAAIEAxIDNg8QCk0KBAQA
AgUSAzkCGRpAIFRoZSBkaXN0cmlidXRpb24gY2hhbm5lbC1zcGVjaWZpYyBkZXNjcmlwdGlv
biBvZiB0aGlzIHBhY2thZ2UuCgoMCgUEAAIFBRIDOQIICgwKBQQAAgUBEgM5CRQKDAoFBAAC
BQMSAzkXGAqXAQoCBAESBD4ASQEaigEgQW4gb2NjdXJyZW5jZSBvZiBhIHBhcnRpY3VsYXIg
cGFja2FnZSBpbnN0YWxsYXRpb24gZm91bmQgd2l0aGluIGEgc3lzdGVtJ3MKIGZpbGVzeXN0
ZW0uIEUuZy4sIGdsaWJjIHdhcyBmb3VuZCBpbiBgL3Zhci9saWIvZHBrZy9zdGF0dXNgLgoK
CgoDBAEBEgM+CBAKXQoEBAECABIDQQIVGlAgRGVwcmVjYXRlZC4KIFRoZSBDUEUgVVJJIGlu
IFtDUEUgZm9ybWF0XShodHRwczovL2NwZS5taXRyZS5vcmcvc3BlY2lmaWNhdGlvbi8pCgoM
CgUEAQIABRIDQQIICgwKBQQBAgABEgNBCRAKDAoFBAECAAMSA0ETFApDCgQEAQIBEgNFAhYa
NiBEZXByZWNhdGVkLgogVGhlIHZlcnNpb24gaW5zdGFsbGVkIGF0IHRoaXMgbG9jYXRpb24u
CgoMCgUEAQIBBhIDRQIJCgwKBQQBAgEBEgNFChEKDAoFBAECAQMSA0UUFQpWCgQEAQICEgNI
AhIaSSBUaGUgcGF0aCBmcm9tIHdoaWNoIHdlIGdhdGhlcmVkIHRoYXQgdGhpcyBwYWNrYWdl
L3ZlcnNpb24gaXMgaW5zdGFsbGVkLgoKDAoFBAECAgUSA0gCCAoMCgUEAQICARIDSAkNCgwK
BQQBAgIDEgNIEBEKQgoCBAISBEwAdgEaNiBQYWNrYWdlTm90ZSByZXByZXNlbnRzIGEgcGFy
dGljdWxhciBwYWNrYWdlIHZlcnNpb24uCgoKCgMEAgESA0wIEwooCgQEAgIAEgROAlEEGhog
VGhlIG5hbWUgb2YgdGhlIHBhY2thZ2UuCgoMCgUEAgIABRIDTgIICgwKBQQCAgABEgNOCQ0K
DAoFBAICAAMSA04QEQoNCgUEAgIACBIEThJRAwoPCggEAgIACJwIABIDTwQqCg8KCAQCAgAI
nAgBEgNQBCsKUwoEBAICARIDVQIqGkYgRGVwcmVjYXRlZC4KIFRoZSB2YXJpb3VzIGNoYW5u
ZWxzIGJ5IHdoaWNoIGEgcGFja2FnZSBpcyBkaXN0cmlidXRlZC4KCgwKBQQCAgEEEgNVAgoK
DAoFBAICAQYSA1ULFwoMCgUEAgIBARIDVRgkCgwKBQQCAgEDEgNVJykKbAoEBAICAhIDWQIb
Gl8gVGhlIHR5cGUgb2YgcGFja2FnZTsgd2hldGhlciBuYXRpdmUgb3Igbm9uIG5hdGl2ZSAo
ZS5nLiwgcnVieSBnZW1zLAogbm9kZS5qcyBwYWNrYWdlcywgZXRjLikuCgoMCgUEAgICBRID
WQIICgwKBQQCAgIBEgNZCRUKDAoFBAICAgMSA1kYGgrBAQoEBAICAxIDXgIWGrMBIFRoZSBj
cGVfdXJpIGluIFtDUEUgZm9ybWF0XShodHRwczovL2NwZS5taXRyZS5vcmcvc3BlY2lmaWNh
dGlvbi8pCiBkZW5vdGluZyB0aGUgcGFja2FnZSBtYW5hZ2VyIHZlcnNpb24gZGlzdHJpYnV0
aW5nIGEgcGFja2FnZS4KIFRoZSBjcGVfdXJpIHdpbGwgYmUgYmxhbmsgZm9yIGxhbmd1YWdl
IHBhY2thZ2VzLgoKDAoFBAICAwUSA14CCAoMCgUEAgIDARIDXgkQCgwKBQQCAgMDEgNeExUK
kwEKBAQCAgQSA2ICIRqFASBUaGUgQ1BVIGFyY2hpdGVjdHVyZSBmb3Igd2hpY2ggcGFja2Fn
ZXMgaW4gdGhpcyBkaXN0cmlidXRpb24gY2hhbm5lbCB3ZXJlCiBidWlsdC4gQXJjaGl0ZWN0
dXJlIHdpbGwgYmUgYmxhbmsgZm9yIGxhbmd1YWdlIHBhY2thZ2VzLgoKDAoFBAICBAYSA2IC
DgoMCgUEAgIEARIDYg8bCgwKBQQCAgQDEgNiHiAKKgoEBAICBRIDZQIXGh0gVGhlIHZlcnNp
b24gb2YgdGhlIHBhY2thZ2UuCgoMCgUEAgIFBhIDZQIJCgwKBQQCAgUBEgNlChEKDAoFBAIC
BQMSA2UUFgpHCgQEAgIGEgNoAhkaOiBBIGZyZWVmb3JtIHRleHQgZGVub3RpbmcgdGhlIG1h
aW50YWluZXIgb2YgdGhpcyBwYWNrYWdlLgoKDAoFBAICBgUSA2gCCAoMCgUEAgIGARIDaAkT
CgwKBQQCAgYDEgNoFhgKLQoEBAICBxIDawISGiAgVGhlIGhvbWVwYWdlIGZvciB0aGlzIHBh
Y2thZ2UuCgoMCgUEAgIHBRIDawIICgwKBQQCAgcBEgNrCQwKDAoFBAICBwMSA2sPEQovCgQE
AgIIEgNuAhoaIiBUaGUgZGVzY3JpcHRpb24gb2YgdGhpcyBwYWNrYWdlLgoKDAoFBAICCAUS
A24CCAoMCgUEAgIIARIDbgkUCgwKBQQCAggDEgNuFxkKTgoEBAICCRIDcQIXGkEgTGljZW5z
ZXMgdGhhdCBoYXZlIGJlZW4gZGVjbGFyZWQgYnkgdGhlIGF1dGhvcnMgb2YgdGhlIHBhY2th
Z2UuCgoMCgUEAgIJBhIDcQIJCgwKBQQCAgkBEgNxChEKDAoFBAICCQMSA3EUFgpqCgQEAgIK
EgN1Ah4aXSBIYXNoIHZhbHVlLCB0eXBpY2FsbHkgYSBmaWxlIGRpZ2VzdCwgdGhhdCBhbGxv
d3MgdW5pcXVlCiBpZGVudGlmaWNhdGlvbiBhIHNwZWNpZmljIHBhY2thZ2UuCgoMCgUEAgIK
BBIDdQIKCgwKBQQCAgoGEgN1CxEKDAoFBAICCgESA3USGAoMCgUEAgIKAxIDdRsdClYKAgQD
EgV5AJYBARpJIERldGFpbHMgb24gaG93IGEgcGFydGljdWxhciBzb2Z0d2FyZSBwYWNrYWdl
IHdhcyBpbnN0YWxsZWQgb24gYSBzeXN0ZW0uCgoKCgMEAwESA3kIGQoyCgQEAwIAEgR7An4E
GiQgVGhlIG5hbWUgb2YgdGhlIGluc3RhbGxlZCBwYWNrYWdlLgoKDAoFBAMCAAUSA3sCCAoM
CgUEAwIAARIDewkNCgwKBQQDAgADEgN7EBEKDQoFBAMCAAgSBHsSfgMKDwoIBAMCAAicCAAS
A3wEKgoPCggEAwIACJwIARIDfQQtCmIKBAQDAgESBIIBAiEaVCBBbGwgb2YgdGhlIHBsYWNl
cyB3aXRoaW4gdGhlIGZpbGVzeXN0ZW0gdmVyc2lvbnMgb2YgdGhpcyBwYWNrYWdlCiBoYXZl
IGJlZW4gZm91bmQuCgoNCgUEAwIBBBIEggECCgoNCgUEAwIBBhIEggELEwoNCgUEAwIBARIE
ggEUHAoNCgUEAwIBAxIEggEfIAptCgQEAwICEgSGAQJGGl8gVGhlIHR5cGUgb2YgcGFja2Fn
ZTsgd2hldGhlciBuYXRpdmUgb3Igbm9uIG5hdGl2ZSAoZS5nLiwgcnVieSBnZW1zLAogbm9k
ZS5qcyBwYWNrYWdlcywgZXRjLikuCgoNCgUEAwICBRIEhgECCAoNCgUEAwICARIEhgEJFQoN
CgUEAwICAxIEhgEYGQoNCgUEAwICCBIEhgEaRQoQCggEAwICCJwIABIEhgEbRArCAQoEBAMC
AxIEiwECQRqzASBUaGUgY3BlX3VyaSBpbiBbQ1BFIGZvcm1hdF0oaHR0cHM6Ly9jcGUubWl0
cmUub3JnL3NwZWNpZmljYXRpb24vKQogZGVub3RpbmcgdGhlIHBhY2thZ2UgbWFuYWdlciB2
ZXJzaW9uIGRpc3RyaWJ1dGluZyBhIHBhY2thZ2UuCiBUaGUgY3BlX3VyaSB3aWxsIGJlIGJs
YW5rIGZvciBsYW5ndWFnZSBwYWNrYWdlcy4KCg0KBQQDAgMFEgSLAQIICg0KBQQDAgMBEgSL
AQkQCg0KBQQDAgMDEgSLARMUCg0KBQQDAgMIEgSLARVAChAKCAQDAgMInAgAEgSLARY/CpQB
CgQEAwIEEgSPAQJMGoUBIFRoZSBDUFUgYXJjaGl0ZWN0dXJlIGZvciB3aGljaCBwYWNrYWdl
cyBpbiB0aGlzIGRpc3RyaWJ1dGlvbiBjaGFubmVsIHdlcmUKIGJ1aWx0LiBBcmNoaXRlY3R1
cmUgd2lsbCBiZSBibGFuayBmb3IgbGFuZ3VhZ2UgcGFja2FnZXMuCgoNCgUEAwIEBhIEjwEC
DgoNCgUEAwIEARIEjwEPGwoNCgUEAwIEAxIEjwEeHwoNCgUEAwIECBIEjwEgSwoQCggEAwIE
CJwIABIEjwEhSgpPCgQEAwIFEgSSAQIWGkEgTGljZW5zZXMgdGhhdCBoYXZlIGJlZW4gZGVj
bGFyZWQgYnkgdGhlIGF1dGhvcnMgb2YgdGhlIHBhY2thZ2UuCgoNCgUEAwIFBhIEkgECCQoN
CgUEAwIFARIEkgEKEQoNCgUEAwIFAxIEkgEUFQorCgQEAwIGEgSVAQJCGh0gVGhlIHZlcnNp
b24gb2YgdGhlIHBhY2thZ2UuCgoNCgUEAwIGBhIElQECCQoNCgUEAwIGARIElQEKEQoNCgUE
AwIGAxIElQEUFQoNCgUEAwIGCBIElQEWQQoQCggEAwIGCJwIABIElQEXQApXCgIEBBIGmQEA
vwEBGkkgVmVyc2lvbiBjb250YWlucyBzdHJ1Y3R1cmVkIGluZm9ybWF0aW9uIGFib3V0IHRo
ZSB2ZXJzaW9uIG9mIGEgcGFja2FnZS4KCgsKAwQEARIEmQEIDwpJCgQEBAIAEgSbAQISGjsg
VXNlZCB0byBjb3JyZWN0IG1pc3Rha2VzIGluIHRoZSB2ZXJzaW9uIG51bWJlcmluZyBzY2hl
bWUuCgoNCgUEBAIABRIEmwECBwoNCgUEBAIAARIEmwEIDQoNCgUEBAIAAxIEmwEQEQpeCgQE
BAIBEgSfAQISGlAgUmVxdWlyZWQgb25seSB3aGVuIHZlcnNpb24ga2luZCBpcyBOT1JNQUwu
IFRoZSBtYWluIHBhcnQgb2YgdGhlIHZlcnNpb24KIG5hbWUuCgoNCgUEBAIBBRIEnwECCAoN
CgUEBAIBARIEnwEJDQoNCgUEBAIBAxIEnwEQEQpKCgQEBAICEgSiAQIWGjwgVGhlIGl0ZXJh
dGlvbiBvZiB0aGUgcGFja2FnZSBidWlsZCBmcm9tIHRoZSBhYm92ZSB2ZXJzaW9uLgoKDQoF
BAQCAgUSBKIBAggKDQoFBAQCAgESBKIBCREKDQoFBAQCAgMSBKIBFBUKsAMKBAQEAgMSBKoB
AhUaoQMgV2hldGhlciB0aGlzIHZlcnNpb24gaXMgc3BlY2lmeWluZyBwYXJ0IG9mIGFuIGlu
Y2x1c2l2ZSByYW5nZS4gR3JhZmVhcwogZG9lcyBub3QgaGF2ZSB0aGUgY2FwYWJpbGl0eSB0
byBzcGVjaWZ5IHZlcnNpb24gcmFuZ2VzOyBpbnN0ZWFkIHdlIGhhdmUKIGZpZWxkcyB0aGF0
IHNwZWNpZnkgc3RhcnQgdmVyc2lvbiBhbmQgZW5kIHZlcnNpb25zLiBBdCB0aW1lcyB0aGlz
IGlzCiBpbnN1ZmZpY2llbnQgLSB3ZSBhbHNvIG5lZWQgdG8gc3BlY2lmeSB3aGV0aGVyIHRo
ZSB2ZXJzaW9uIGlzIGluY2x1ZGVkIGluCiB0aGUgcmFuZ2Ugb3IgaXMgZXhjbHVkZWQgZnJv
bSB0aGUgcmFuZ2UuIFRoaXMgYm9vbGVhbiBpcyBleHBlY3RlZCB0byBiZSBzZXQKIHRvIHRy
dWUgd2hlbiB0aGUgdmVyc2lvbiBpcyBpbmNsdWRlZCBpbiBhIHJhbmdlLgoKDQoFBAQCAwUS
BKoBAgYKDQoFBAQCAwESBKoBBxAKDQoFBAQCAwMSBKoBExQKXAoEBAQEABIGrQECtgEDGkwg
V2hldGhlciB0aGlzIGlzIGFuIG9yZGluYXJ5IHBhY2thZ2UgdmVyc2lvbiBvciBhIHNlbnRp
bmVsIE1JTi9NQVggdmVyc2lvbi4KCg0KBQQEBAABEgStAQcSChoKBgQEBAACABIErwEEIRoK
IFVua25vd24uCgoPCgcEBAQAAgABEgSvAQQcCg8KBwQEBAACAAISBK8BHyAKLQoGBAQEAAIB
EgSxAQQPGh0gQSBzdGFuZGFyZCBwYWNrYWdlIHZlcnNpb24uCgoPCgcEBAQAAgEBEgSxAQQK
Cg8KBwQEBAACAQISBLEBDQ4KQwoGBAQEAAICEgSzAQQQGjMgQSBzcGVjaWFsIHZlcnNpb24g
cmVwcmVzZW50aW5nIG5lZ2F0aXZlIGluZmluaXR5LgoKDwoHBAQEAAICARIEswEECwoPCgcE
BAQAAgICEgSzAQ4PCkMKBgQEBAACAxIEtQEEEBozIEEgc3BlY2lhbCB2ZXJzaW9uIHJlcHJl
c2VudGluZyBwb3NpdGl2ZSBpbmZpbml0eS4KCg8KBwQEBAACAwESBLUBBAsKDwoHBAQEAAID
AhIEtQEODwpfCgQEBAIEEgS6AQIXGlEgUmVxdWlyZWQuIERpc3Rpbmd1aXNoZXMgYmV0d2Vl
biBzZW50aW5lbCBNSU4vTUFYIHZlcnNpb25zIGFuZCBub3JtYWwKIHZlcnNpb25zLgoKDQoF
BAQCBAYSBLoBAg0KDQoFBAQCBAESBLoBDhIKDQoFBAQCBAMSBLoBFRYKiQEKBAQEAgUSBL4B
AhcaeyBIdW1hbiByZWFkYWJsZSB2ZXJzaW9uIHN0cmluZy4gVGhpcyBzdHJpbmcgaXMgb2Yg
dGhlIGZvcm0KIDxlcG9jaD46PG5hbWU+LTxyZXZpc2lvbj4gYW5kIGlzIG9ubHkgc2V0IHdo
ZW4ga2luZCBpcyBOT1JNQUwuCgoNCgUEBAIFBRIEvgECCAoNCgUEBAIFARIEvgEJEgoNCgUE
BAIFAxIEvgEVFmIGcHJvdG8z
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Grafeas::V1::Package::Distribution ===
    # Fields for Distribution
    # Field: cpe_uri Type: 9 ()
    # Field: architecture Type: 14 (.grafeas.v1.Architecture)
    # Field: latest_version Type: 11 (.grafeas.v1.Version)
    # Field: maintainer Type: 9 ()
    # Field: url Type: 9 ()
    # Field: description Type: 9 ()

# === Message: Grafeas::V1::Package::Location ===
    # Fields for Location
    # Field: cpe_uri Type: 9 ()
    # Field: version Type: 11 (.grafeas.v1.Version)
    # Field: path Type: 9 ()

# === Message: Grafeas::V1::Package::PackageNote ===
    # Fields for PackageNote
    # Field: name Type: 9 ()
    # Field: distribution Type: 11 (.grafeas.v1.Distribution)
    # Field: package_type Type: 9 ()
    # Field: cpe_uri Type: 9 ()
    # Field: architecture Type: 14 (.grafeas.v1.Architecture)
    # Field: version Type: 11 (.grafeas.v1.Version)
    # Field: maintainer Type: 9 ()
    # Field: url Type: 9 ()
    # Field: description Type: 9 ()
    # Field: license Type: 11 (.grafeas.v1.License)
    # Field: digest Type: 11 (.grafeas.v1.Digest)

# === Message: Grafeas::V1::Package::PackageOccurrence ===
    # Fields for PackageOccurrence
    # Field: name Type: 9 ()
    # Field: location Type: 11 (.grafeas.v1.Location)
    # Field: package_type Type: 9 ()
    # Field: cpe_uri Type: 9 ()
    # Field: architecture Type: 14 (.grafeas.v1.Architecture)
    # Field: license Type: 11 (.grafeas.v1.License)
    # Field: version Type: 11 (.grafeas.v1.Version)

# === Message: Grafeas::V1::Package::Version ===
    # Fields for Version
    # Field: epoch Type: 5 ()
    # Field: name Type: 9 ()
    # Field: revision Type: 9 ()
    # Field: inclusive Type: 8 ()
    # Field: kind Type: 14 (.grafeas.v1.Version.VersionKind)
    # Field: full_name Type: 9 ()

# Enum: Version::VersionKind
our $Version_VERSION_KIND_UNSPECIFIED = 0;
our $Version_NORMAL = 1;
our $Version_MINIMUM = 2;
our $Version_MAXIMUM = 3;

1;

__END__

=encoding UTF-8

=head1 NAME

Grafeas::V1::Package - Compiled Protocol Buffers messages for grafeas/v1/package.proto

=head1 SYNOPSIS

    use Grafeas::V1::Package;

    my $msg = Grafeas::V1::Package::Distribution->new({
        cpe_uri => $cpe_uri,
        architecture => $architecture,
        latest_version => $latest_version,
        maintainer => $maintainer,
    });

    # Read or update a field
    my $val = $msg->cpe_uri();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Grafeas::V1::Package::Distribution->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<grafeas/v1/package.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Grafeas::V1::Package::Distribution

This represents a particular channel of distribution for a given package.
E.g., Debian's jessie-backports dpkg mirror.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->cpe_uri() >> / C<< $msg->cpe_uri($value) >>

Type: C<String>

The cpe_uri in [CPE format](https://cpe.mitre.org/specification/)
denoting the package manager version distributing a package.

=item * C<< $msg->architecture() >> / C<< $msg->architecture($value) >>

Type: C<Enum> (L<Grafeas::V1::Architecture>)

The CPU architecture for which packages in this distribution channel were
built.

=item * C<< $msg->latest_version() >> / C<< $msg->latest_version($value) >>

Type: C<Message> (L<Grafeas::V1::Package::Version>)

The latest available version of this package in this distribution channel.

=item * C<< $msg->maintainer() >> / C<< $msg->maintainer($value) >>

Type: C<String>

A freeform string denoting the maintainer of this package.

=item * C<< $msg->url() >> / C<< $msg->url($value) >>

Type: C<String>

The distribution channel-specific homepage for this package.

=item * C<< $msg->description() >> / C<< $msg->description($value) >>

Type: C<String>

The distribution channel-specific description of this package.

=back

=head2 Grafeas::V1::Package::Location

An occurrence of a particular package installation found within a system's
filesystem. E.g., glibc was found in `/var/lib/dpkg/status`.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->cpe_uri() >> / C<< $msg->cpe_uri($value) >>

Type: C<String>

Deprecated.
The CPE URI in [CPE format](https://cpe.mitre.org/specification/)

=item * C<< $msg->version() >> / C<< $msg->version($value) >>

Type: C<Message> (L<Grafeas::V1::Package::Version>)

Deprecated.
The version installed at this location.

=item * C<< $msg->path() >> / C<< $msg->path($value) >>

Type: C<String>

The path from which we gathered that this package/version is installed.

=back

=head2 Grafeas::V1::Package::PackageNote

PackageNote represents a particular package version.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

The name of the package.

=item * C<< $msg->distribution() >> / C<< $msg->distribution($value) >>

Type: C<Message> (L<Grafeas::V1::Package::Distribution>)

Deprecated.
The various channels by which a package is distributed.

=item * C<< $msg->package_type() >> / C<< $msg->package_type($value) >>

Type: C<String>

The type of package; whether native or non native (e.g., ruby gems,
node.js packages, etc.).

=item * C<< $msg->cpe_uri() >> / C<< $msg->cpe_uri($value) >>

Type: C<String>

The cpe_uri in [CPE format](https://cpe.mitre.org/specification/)
denoting the package manager version distributing a package.
The cpe_uri will be blank for language packages.

=item * C<< $msg->architecture() >> / C<< $msg->architecture($value) >>

Type: C<Enum> (L<Grafeas::V1::Architecture>)

The CPU architecture for which packages in this distribution channel were
built. Architecture will be blank for language packages.

=item * C<< $msg->version() >> / C<< $msg->version($value) >>

Type: C<Message> (L<Grafeas::V1::Package::Version>)

The version of the package.

=item * C<< $msg->maintainer() >> / C<< $msg->maintainer($value) >>

Type: C<String>

A freeform text denoting the maintainer of this package.

=item * C<< $msg->url() >> / C<< $msg->url($value) >>

Type: C<String>

The homepage for this package.

=item * C<< $msg->description() >> / C<< $msg->description($value) >>

Type: C<String>

The description of this package.

=item * C<< $msg->license() >> / C<< $msg->license($value) >>

Type: C<Message> (L<Grafeas::V1::Common::License>)

Licenses that have been declared by the authors of the package.

=item * C<< $msg->digest() >> / C<< $msg->digest($value) >>

Type: C<Message> (L<Grafeas::V1::Common::Digest>)

Hash value, typically a file digest, that allows unique
identification a specific package.

=back

=head2 Grafeas::V1::Package::PackageOccurrence

Details on how a particular software package was installed on a system.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

The name of the installed package.

=item * C<< $msg->location() >> / C<< $msg->location($value) >>

Type: C<Message> (L<Grafeas::V1::Package::Location>)

All of the places within the filesystem versions of this package
have been found.

=item * C<< $msg->package_type() >> / C<< $msg->package_type($value) >>

Type: C<String>

The type of package; whether native or non native (e.g., ruby gems,
node.js packages, etc.).

=item * C<< $msg->cpe_uri() >> / C<< $msg->cpe_uri($value) >>

Type: C<String>

The cpe_uri in [CPE format](https://cpe.mitre.org/specification/)
denoting the package manager version distributing a package.
The cpe_uri will be blank for language packages.

=item * C<< $msg->architecture() >> / C<< $msg->architecture($value) >>

Type: C<Enum> (L<Grafeas::V1::Architecture>)

The CPU architecture for which packages in this distribution channel were
built. Architecture will be blank for language packages.

=item * C<< $msg->license() >> / C<< $msg->license($value) >>

Type: C<Message> (L<Grafeas::V1::Common::License>)

Licenses that have been declared by the authors of the package.

=item * C<< $msg->version() >> / C<< $msg->version($value) >>

Type: C<Message> (L<Grafeas::V1::Package::Version>)

The version of the package.

=back

=head2 Grafeas::V1::Package::Version

Version contains structured information about the version of a package.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->epoch() >> / C<< $msg->epoch($value) >>

Type: C<Int32>

Used to correct mistakes in the version numbering scheme.

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required only when version kind is NORMAL. The main part of the version
name.

=item * C<< $msg->revision() >> / C<< $msg->revision($value) >>

Type: C<String>

The iteration of the package build from the above version.

=item * C<< $msg->inclusive() >> / C<< $msg->inclusive($value) >>

Type: C<Bool>

Whether this version is specifying part of an inclusive range. Grafeas
does not have the capability to specify version ranges; instead we have
fields that specify start version and end versions. At times this is
insufficient - we also need to specify whether the version is included in
the range or is excluded from the range. This boolean is expected to be set
to true when the version is included in a range.

=item * C<< $msg->kind() >> / C<< $msg->kind($value) >>

Type: C<Enum> (L<Grafeas::V1::Version::VersionKind>)

Required. Distinguishes between sentinel MIN/MAX versions and normal
versions.

=item * C<< $msg->full_name() >> / C<< $msg->full_name($value) >>

Type: C<String>

Human readable version string. This string is of the form
<epoch>:<name>-<revision> and is only set when kind is NORMAL.

=back

=head3 Enum: Version::VersionKind

=over 4

=item * C<VERSION_KIND_UNSPECIFIED> => C<0>

=item * C<NORMAL> => C<1>

=item * C<MINIMUM> => C<2>

=item * C<MAXIMUM> => C<3>

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Grafeas::V1::Package::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
