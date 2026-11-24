package Grafeas::V1::Common;

use strict;
use warnings;

our $VERSION = '0.14';

use Protobuf::Message;
use Protobuf::DescriptorPool;
use Protobuf::Internal qw(:all);
use MIME::Base64;

BEGIN {
    my $descriptor_b64 = <<'EOF';
ChdncmFmZWFzL3YxL2NvbW1vbi5wcm90bxIKZ3JhZmVhcy52MSI0CgpSZWxhdGVkVXJsEhAK
A3VybBgBIAEoCVIDdXJsEhQKBWxhYmVsGAIgASgJUgVsYWJlbCJNCglTaWduYXR1cmUSHAoJ
c2lnbmF0dXJlGAEgASgMUglzaWduYXR1cmUSIgoNcHVibGljX2tleV9pZBgCIAEoCVILcHVi
bGljS2V5SWQihgEKCEVudmVsb3BlEhgKB3BheWxvYWQYASABKAxSB3BheWxvYWQSIQoMcGF5
bG9hZF90eXBlGAIgASgJUgtwYXlsb2FkVHlwZRI9CgpzaWduYXR1cmVzGAMgAygLMh0uZ3Jh
ZmVhcy52MS5FbnZlbG9wZVNpZ25hdHVyZVIKc2lnbmF0dXJlcyI7ChFFbnZlbG9wZVNpZ25h
dHVyZRIQCgNzaWcYASABKAxSA3NpZxIUCgVrZXlpZBgCIAEoCVIFa2V5aWQiiwEKDEZpbGVM
b2NhdGlvbhIbCglmaWxlX3BhdGgYASABKAlSCGZpbGVQYXRoEj0KDWxheWVyX2RldGFpbHMY
AiABKAsyGC5ncmFmZWFzLnYxLkxheWVyRGV0YWlsc1IMbGF5ZXJEZXRhaWxzEh8KC2xpbmVf
bnVtYmVyGAMgASgFUgpsaW5lTnVtYmVyInwKCUJhc2VJbWFnZRISCgRuYW1lGAEgASgJUgRu
YW1lEh4KCnJlcG9zaXRvcnkYAiABKAlSCnJlcG9zaXRvcnkSHwoLbGF5ZXJfY291bnQYAyAB
KAVSCmxheWVyQ291bnQSGgoIcmVnaXN0cnkYBCABKAlSCHJlZ2lzdHJ5IqoBCgxMYXllckRl
dGFpbHMSFAoFaW5kZXgYASABKAVSBWluZGV4EhcKB2RpZmZfaWQYAiABKAlSBmRpZmZJZBIZ
CghjaGFpbl9pZBgFIAEoCVIHY2hhaW5JZBIYCgdjb21tYW5kGAMgASgJUgdjb21tYW5kEjYK
C2Jhc2VfaW1hZ2VzGAQgAygLMhUuZ3JhZmVhcy52MS5CYXNlSW1hZ2VSCmJhc2VJbWFnZXMi
RQoHTGljZW5zZRIeCgpleHByZXNzaW9uGAEgASgJUgpleHByZXNzaW9uEhoKCGNvbW1lbnRz
GAIgASgJUghjb21tZW50cyI/CgZEaWdlc3QSEgoEYWxnbxgBIAEoCVIEYWxnbxIhCgxkaWdl
c3RfYnl0ZXMYAiABKAxSC2RpZ2VzdEJ5dGVzKvwBCghOb3RlS2luZBIZChVOT1RFX0tJTkRf
VU5TUEVDSUZJRUQQABIRCg1WVUxORVJBQklMSVRZEAESCQoFQlVJTEQQAhIJCgVJTUFHRRAD
EgsKB1BBQ0tBR0UQBBIOCgpERVBMT1lNRU5UEAUSDQoJRElTQ09WRVJZEAYSDwoLQVRURVNU
QVRJT04QBxILCgdVUEdSQURFEAgSDgoKQ09NUExJQU5DRRAJEhQKEERTU0VfQVRURVNUQVRJ
T04QChIcChhWVUxORVJBQklMSVRZX0FTU0VTU01FTlQQCxISCg5TQk9NX1JFRkVSRU5DRRAM
EgoKBlNFQ1JFVBANQlEKDWlvLmdyYWZlYXMudjFQAVo4Z29vZ2xlLmdvbGFuZy5vcmcvZ2Vu
cHJvdG8vZ29vZ2xlYXBpcy9ncmFmZWFzL3YxO2dyYWZlYXOiAgNHUkFKgD8KBxIFDgC9AQEK
2gQKAQwSAw4AEjLPBCBDb3B5cmlnaHQgMjAxOSBUaGUgR3JhZmVhcyBBdXRob3JzLiBBbGwg
cmlnaHRzIHJlc2VydmVkLgoKIExpY2Vuc2VkIHVuZGVyIHRoZSBBcGFjaGUgTGljZW5zZSwg
VmVyc2lvbiAyLjAgKHRoZSAiTGljZW5zZSIpOwogeW91IG1heSBub3QgdXNlIHRoaXMgZmls
ZSBleGNlcHQgaW4gY29tcGxpYW5jZSB3aXRoIHRoZSBMaWNlbnNlLgogWW91IG1heSBvYnRh
aW4gYSBjb3B5IG9mIHRoZSBMaWNlbnNlIGF0CgogICAgaHR0cDovL3d3dy5hcGFjaGUub3Jn
L2xpY2Vuc2VzL0xJQ0VOU0UtMi4wCgogVW5sZXNzIHJlcXVpcmVkIGJ5IGFwcGxpY2FibGUg
bGF3IG9yIGFncmVlZCB0byBpbiB3cml0aW5nLCBzb2Z0d2FyZQogZGlzdHJpYnV0ZWQgdW5k
ZXIgdGhlIExpY2Vuc2UgaXMgZGlzdHJpYnV0ZWQgb24gYW4gIkFTIElTIiBCQVNJUywKIFdJ
VEhPVVQgV0FSUkFOVElFUyBPUiBDT05ESVRJT05TIE9GIEFOWSBLSU5ELCBlaXRoZXIgZXhw
cmVzcyBvciBpbXBsaWVkLgogU2VlIHRoZSBMaWNlbnNlIGZvciB0aGUgc3BlY2lmaWMgbGFu
Z3VhZ2UgZ292ZXJuaW5nIHBlcm1pc3Npb25zIGFuZAogbGltaXRhdGlvbnMgdW5kZXIgdGhl
IExpY2Vuc2UuCgoICgECEgMQABMKCAoBCBIDEgBPCgkKAggLEgMSAE8KCAoBCBIDEwAiCgkK
AggKEgMTACIKCAoBCBIDFAAmCgkKAggBEgMUACYKCAoBCBIDFQAhCgkKAggkEgMVACEKOwoC
BQASBBgANQEaLyBLaW5kIHJlcHJlc2VudHMgdGhlIGtpbmRzIG9mIG5vdGVzIHN1cHBvcnRl
ZC4KCgoKAwUAARIDGAUNCjMKBAUAAgASAxoCHBomIERlZmF1bHQgdmFsdWUuIFRoaXMgdmFs
dWUgaXMgdW51c2VkLgoKDAoFBQACAAESAxoCFwoMCgUFAAIAAhIDGhobCkkKBAUAAgESAxwC
FBo8IFRoZSBub3RlIGFuZCBvY2N1cnJlbmNlIHJlcHJlc2VudCBhIHBhY2thZ2UgdnVsbmVy
YWJpbGl0eS4KCgwKBQUAAgEBEgMcAg8KDAoFBQACAQISAxwSEwo/CgQFAAICEgMeAgwaMiBU
aGUgbm90ZSBhbmQgb2NjdXJyZW5jZSBhc3NlcnQgYnVpbGQgcHJvdmVuYW5jZS4KCgwKBQUA
AgIBEgMeAgcKDAoFBQACAgISAx4KCwo7CgQFAAIDEgMgAgwaLiBUaGlzIHJlcHJlc2VudHMg
YW4gaW1hZ2UgYmFzaXMgcmVsYXRpb25zaGlwLgoKDAoFBQACAwESAyACBwoMCgUFAAIDAhID
IAoLCkkKBAUAAgQSAyICDho8IFRoaXMgcmVwcmVzZW50cyBhIHBhY2thZ2UgaW5zdGFsbGVk
IHZpYSBhIHBhY2thZ2UgbWFuYWdlci4KCgwKBQUAAgQBEgMiAgkKDAoFBQACBAISAyIMDQo/
CgQFAAIFEgMkAhEaMiBUaGUgbm90ZSBhbmQgb2NjdXJyZW5jZSB0cmFjayBkZXBsb3ltZW50
IGV2ZW50cy4KCgwKBQUAAgUBEgMkAgwKDAoFBQACBQISAyQPEApYCgQFAAIGEgMmAhAaSyBU
aGUgbm90ZSBhbmQgb2NjdXJyZW5jZSB0cmFjayB0aGUgaW5pdGlhbCBkaXNjb3Zlcnkgc3Rh
dHVzIG9mIGEgcmVzb3VyY2UuCgoMCgUFAAIGARIDJgILCgwKBQUAAgYCEgMmDg8KTQoEBQAC
BxIDKAISGkAgVGhpcyByZXByZXNlbnRzIGEgbG9naWNhbCAicm9sZSIgdGhhdCBjYW4gYXR0
ZXN0IHRvIGFydGlmYWN0cy4KCgwKBQUAAgcBEgMoAg0KDAoFBQACBwISAygQEQo8CgQFAAII
EgMqAg4aLyBUaGlzIHJlcHJlc2VudHMgYW4gYXZhaWxhYmxlIHBhY2thZ2UgdXBncmFkZS4K
CgwKBQUAAggBEgMqAgkKDAoFBQACCAISAyoMDQowCgQFAAIJEgMsAhEaIyBUaGlzIHJlcHJl
c2VudHMgYSBDb21wbGlhbmNlIE5vdGUKCgwKBQUAAgkBEgMsAgwKDAoFBQACCQISAywPEAo2
CgQFAAIKEgMuAhgaKSBUaGlzIHJlcHJlc2VudHMgYSBEU1NFIGF0dGVzdGF0aW9uIE5vdGUK
CgwKBQUAAgoBEgMuAhIKDAoFBQACCgISAy4VFwo6CgQFAAILEgMwAiAaLSBUaGlzIHJlcHJl
c2VudHMgYSBWdWxuZXJhYmlsaXR5IEFzc2Vzc21lbnQuCgoMCgUFAAILARIDMAIaCgwKBQUA
AgsCEgMwHR8KMQoEBQACDBIDMgIWGiQgVGhpcyByZXByZXNlbnRzIGFuIFNCT00gUmVmZXJl
bmNlLgoKDAoFBQACDAESAzICEAoMCgUFAAIMAhIDMhMVCigKBAUAAg0SAzQCDhobIFRoaXMg
cmVwcmVzZW50cyBhIHNlY3JldC4KCgwKBQUAAg0BEgM0AggKDAoFBQACDQISAzQLDQo3CgIE
ABIEOAA9ARorIE1ldGFkYXRhIGZvciBhbnkgcmVsYXRlZCBVUkwgaW5mb3JtYXRpb24uCgoK
CgMEAAESAzgIEgo5CgQEAAIAEgM6AhEaLCBTcGVjaWZpYyBVUkwgYXNzb2NpYXRlZCB3aXRo
IHRoZSByZXNvdXJjZS4KCgwKBQQAAgAFEgM6AggKDAoFBAACAAESAzoJDAoMCgUEAAIAAxID
Og8QCjIKBAQAAgESAzwCExolIExhYmVsIHRvIGRlc2NyaWJlIHVzYWdlIG9mIHRoZSBVUkwu
CgoMCgUEAAIBBRIDPAIICgwKBQQAAgEBEgM8CQ4KDAoFBAACAQMSAzwREgqnCgoCBAESBFUA
cAEamgogVmVyaWZpZXJzIChlLmcuIEtyaXRpcyBpbXBsZW1lbnRhdGlvbnMpIE1VU1QgdmVy
aWZ5IHNpZ25hdHVyZXMKIHdpdGggcmVzcGVjdCB0byB0aGUgdHJ1c3QgYW5jaG9ycyBkZWZp
bmVkIGluIHBvbGljeSAoZS5nLiBhIEtyaXRpcyBwb2xpY3kpLgogVHlwaWNhbGx5IHRoaXMg
bWVhbnMgdGhhdCB0aGUgdmVyaWZpZXIgaGFzIGJlZW4gY29uZmlndXJlZCB3aXRoIGEgbWFw
IGZyb20KIGBwdWJsaWNfa2V5X2lkYCB0byBwdWJsaWMga2V5IG1hdGVyaWFsIChhbmQgYW55
IHJlcXVpcmVkIHBhcmFtZXRlcnMsIGUuZy4KIHNpZ25pbmcgYWxnb3JpdGhtKS4KCiBJbiBw
YXJ0aWN1bGFyLCB2ZXJpZmljYXRpb24gaW1wbGVtZW50YXRpb25zIE1VU1QgTk9UIHRyZWF0
IHRoZSBzaWduYXR1cmUKIGBwdWJsaWNfa2V5X2lkYCBhcyBhbnl0aGluZyBtb3JlIHRoYW4g
YSBrZXkgbG9va3VwIGhpbnQuIFRoZSBgcHVibGljX2tleV9pZGAKIERPRVMgTk9UIHZhbGlk
YXRlIG9yIGF1dGhlbnRpY2F0ZSBhIHB1YmxpYyBrZXk7IGl0IG9ubHkgcHJvdmlkZXMgYSBt
ZWNoYW5pc20KIGZvciBxdWlja2x5IHNlbGVjdGluZyBhIHB1YmxpYyBrZXkgQUxSRUFEWSBD
T05GSUdVUkVEIG9uIHRoZSB2ZXJpZmllciB0aHJvdWdoCiBhIHRydXN0ZWQgY2hhbm5lbC4g
VmVyaWZpY2F0aW9uIGltcGxlbWVudGF0aW9ucyBNVVNUIHJlamVjdCBzaWduYXR1cmVzIGlu
IGFueQogb2YgdGhlIGZvbGxvd2luZyBjaXJjdW1zdGFuY2VzOgogICAqIFRoZSBgcHVibGlj
X2tleV9pZGAgaXMgbm90IHJlY29nbml6ZWQgYnkgdGhlIHZlcmlmaWVyLgogICAqIFRoZSBw
dWJsaWMga2V5IHRoYXQgYHB1YmxpY19rZXlfaWRgIHJlZmVycyB0byBkb2VzIG5vdCB2ZXJp
ZnkgdGhlCiAgICAgc2lnbmF0dXJlIHdpdGggcmVzcGVjdCB0byB0aGUgcGF5bG9hZC4KCiBU
aGUgYHNpZ25hdHVyZWAgY29udGVudHMgU0hPVUxEIE5PVCBiZSAiYXR0YWNoZWQiICh3aGVy
ZSB0aGUgcGF5bG9hZCBpcwogaW5jbHVkZWQgd2l0aCB0aGUgc2VyaWFsaXplZCBgc2lnbmF0
dXJlYCBieXRlcykuIFZlcmlmaWVycyBNVVNUIGlnbm9yZSBhbnkKICJhdHRhY2hlZCIgcGF5
bG9hZCBhbmQgb25seSB2ZXJpZnkgc2lnbmF0dXJlcyB3aXRoIHJlc3BlY3QgdG8gZXhwbGlj
aXRseQogcHJvdmlkZWQgcGF5bG9hZCAoZS5nLiBhIGBwYXlsb2FkYCBmaWVsZCBvbiB0aGUg
cHJvdG8gbWVzc2FnZSB0aGF0IGhvbGRzCiB0aGlzIFNpZ25hdHVyZSwgb3IgdGhlIGNhbm9u
aWNhbCBzZXJpYWxpemF0aW9uIG9mIHRoZSBwcm90byBtZXNzYWdlIHRoYXQKIGhvbGRzIHRo
aXMgc2lnbmF0dXJlKS4KCgoKAwQBARIDVQgRCu8CCgQEAQIAEgNcAhYa4QIgVGhlIGNvbnRl
bnQgb2YgdGhlIHNpZ25hdHVyZSwgYW4gb3BhcXVlIGJ5dGVzdHJpbmcuCiBUaGUgcGF5bG9h
ZCB0aGF0IHRoaXMgc2lnbmF0dXJlIHZlcmlmaWVzIE1VU1QgYmUgdW5hbWJpZ3VvdXNseSBw
cm92aWRlZAogd2l0aCB0aGUgU2lnbmF0dXJlIGR1cmluZyB2ZXJpZmljYXRpb24uIEEgd3Jh
cHBlciBtZXNzYWdlIG1pZ2h0IHByb3ZpZGUKIHRoZSBwYXlsb2FkIGV4cGxpY2l0bHkuIEFs
dGVybmF0aXZlbHksIGEgbWVzc2FnZSBtaWdodCBoYXZlIGEgY2Fub25pY2FsCiBzZXJpYWxp
emF0aW9uIHRoYXQgY2FuIGFsd2F5cyBiZSB1bmFtYmlndW91c2x5IGNvbXB1dGVkIHRvIGRl
cml2ZSB0aGUKIHBheWxvYWQuCgoMCgUEAQIABRIDXAIHCgwKBQQBAgABEgNcCBEKDAoFBAEC
AAMSA1wUFQr2BQoEBAECARIDbwIbGugFIFRoZSBpZGVudGlmaWVyIGZvciB0aGUgcHVibGlj
IGtleSB0aGF0IHZlcmlmaWVzIHRoaXMgc2lnbmF0dXJlLgogICAqIFRoZSBgcHVibGljX2tl
eV9pZGAgaXMgcmVxdWlyZWQuCiAgICogVGhlIGBwdWJsaWNfa2V5X2lkYCBTSE9VTEQgYmUg
YW4gUkZDMzk4NiBjb25mb3JtYW50IFVSSS4KICAgKiBXaGVuIHBvc3NpYmxlLCB0aGUgYHB1
YmxpY19rZXlfaWRgIFNIT1VMRCBiZSBhbiBpbW11dGFibGUgcmVmZXJlbmNlLAogICAgIHN1
Y2ggYXMgYSBjcnlwdG9ncmFwaGljIGRpZ2VzdC4KCiBFeGFtcGxlcyBvZiB2YWxpZCBgcHVi
bGljX2tleV9pZGBzOgoKIE9wZW5QR1AgVjQgcHVibGljIGtleSBmaW5nZXJwcmludDoKICAg
KiAib3BlbnBncDRmcHI6NzRGQUYzQjg2MUJEQTA4NzBDN0I2REVGNjA3RTQ4RDJBNjYzQUVF
QSIKIFNlZSBodHRwczovL3d3dy5pYW5hLm9yZy9hc3NpZ25tZW50cy91cmktc2NoZW1lcy9w
cm92L29wZW5wZ3A0ZnByIGZvciBtb3JlCiBkZXRhaWxzIG9uIHRoaXMgc2NoZW1lLgoKIFJG
QzY5MjAgZGlnZXN0LW5hbWVkIFN1YmplY3RQdWJsaWNLZXlJbmZvIChkaWdlc3Qgb2YgdGhl
IERFUgogc2VyaWFsaXphdGlvbik6CiAgICogIm5pOi8vL3NoYS0yNTY7Y0Q5bzlDcTZMRzNq
RDBpS1hxRWlfdmRqSkdlY21faVhrYnFWb1NjVmlhVSIKICAgKiAibmloOi8vL3NoYS0yNTY7
NzAzZjY4ZjQyYWJhMmM2ZGUzMGY0ODhhNWVhMTIyZmVmNzYzMjQ2NzljOWJmODk3OTFiYTk1
YTEyNzE1ODlhNSIKCgwKBQQBAgEFEgNvAggKDAoFBAECAQESA28JFgoMCgUEAQIBAxIDbxka
Co4BCgIEAhIEdQB5ARqBASBNVVNUIG1hdGNoCiBodHRwczovL2dpdGh1Yi5jb20vc2VjdXJl
LXN5c3RlbXMtbGFiL2Rzc2UvYmxvYi9tYXN0ZXIvZW52ZWxvcGUucHJvdG8uIEFuCiBhdXRo
ZW50aWNhdGVkIG1lc3NhZ2Ugb2YgYXJiaXRyYXJ5IHR5cGUuCgoKCgMEAgESA3UIEAoLCgQE
AgIAEgN2AhQKDAoFBAICAAUSA3YCBwoMCgUEAgIAARIDdggPCgwKBQQCAgADEgN2EhMKCwoE
BAICARIDdwIaCgwKBQQCAgEFEgN3AggKDAoFBAICAQESA3cJFQoMCgUEAgIBAxIDdxgZCgsK
BAQCAgISA3gCLAoMCgUEAgICBBIDeAIKCgwKBQQCAgIGEgN4CxwKDAoFBAICAgESA3gdJwoM
CgUEAgICAxIDeCorCgoKAgQDEgR7AH4BCgoKAwQDARIDewgZCgsKBAQDAgASA3wCEAoMCgUE
AwIABRIDfAIHCgwKBQQDAgABEgN8CAsKDAoFBAMCAAMSA3wODwoLCgQEAwIBEgN9AhMKDAoF
BAMCAQUSA30CCAoMCgUEAwIBARIDfQkOCgwKBQQDAgEDEgN9ERIKRAoCBAQSBoEBAIsBARo2
IEluZGljYXRlcyB0aGUgbG9jYXRpb24gYXQgd2hpY2ggYSBwYWNrYWdlIHdhcyBmb3VuZC4K
CgsKAwQEARIEgQEIFAqUAQoEBAQCABIEhAECFxqFASBGb3IgamFycyB0aGF0IGFyZSBjb250
YWluZWQgaW5zaWRlIC53YXIgZmlsZXMsIHRoaXMgZmlsZXBhdGgKIGNhbiBpbmRpY2F0ZSB0
aGUgcGF0aCB0byB3YXIgZmlsZSBjb21iaW5lZCB3aXRoIHRoZSBwYXRoIHRvIGphciBmaWxl
LgoKDQoFBAQCAAUSBIQBAggKDQoFBAQCAAESBIQBCRIKDQoFBAQCAAMSBIQBFRYKjQEKBAQE
AgESBIcBAiEafyBFYWNoIHBhY2thZ2UgZm91bmQgaW4gYSBmaWxlIHNob3VsZCBoYXZlIGl0
cyBvd24gbGF5ZXIgbWV0YWRhdGEgKHRoYXQgaXMsCiBpbmZvcm1hdGlvbiBmcm9tIHRoZSBv
cmlnaW4gbGF5ZXIgb2YgdGhlIHBhY2thZ2UpLgoKDQoFBAQCAQYSBIcBAg4KDQoFBAQCAQES
BIcBDxwKDQoFBAQCAQMSBIcBHyAKhQEKBAQEAgISBIoBAhgadyBMaW5lIG51bWJlciBpbiB0
aGUgZmlsZSB3aGVyZSB0aGUgcGFja2FnZSB3YXMgZm91bmQuCiBPcHRpb25hbCBmaWVsZCB0
aGF0IG9ubHkgYXBwbGllcyB0byBzb3VyY2UgcmVwb3NpdG9yeSBzY2FubmluZy4KCg0KBQQE
AgIFEgSKAQIHCg0KBQQEAgIBEgSKAQgTCg0KBQQEAgIDEgSKARYXCkYKAgQFEgaOAQCXAQEa
OCBCYXNlSW1hZ2UgZGVzY3JpYmVzIGEgYmFzZSBpbWFnZSBvZiBhIGNvbnRhaW5lciBpbWFn
ZS4KCgsKAwQFARIEjgEIEQorCgQEBQIAEgSQAQISGh0gVGhlIG5hbWUgb2YgdGhlIGJhc2Ug
aW1hZ2UuCgoNCgUEBQIABRIEkAECCAoNCgUEBQIAARIEkAEJDQoNCgUEBQIAAxIEkAEQEQpE
CgQEBQIBEgSSAQIYGjYgVGhlIHJlcG9zaXRvcnkgbmFtZSBpbiB3aGljaCB0aGUgYmFzZSBp
bWFnZSBpcyBmcm9tLgoKDQoFBAUCAQUSBJIBAggKDQoFBAUCAQESBJIBCRMKDQoFBAUCAQMS
BJIBFhcKSAoEBAUCAhIElAECGBo6IFRoZSBudW1iZXIgb2YgbGF5ZXJzIHRoYXQgdGhlIGJh
c2UgaW1hZ2UgaXMgY29tcG9zZWQgb2YuCgoNCgUEBQICBRIElAECBwoNCgUEBQICARIElAEI
EwoNCgUEBQICAxIElAEWFwo9CgQEBQIDEgSWAQIWGi8gVGhlIHJlZ2lzdHJ5IGluIHdoaWNo
IHRoZSBiYXNlIGltYWdlIGlzIGZyb20uCgoNCgUEBQIDBRIElgECCAoNCgUEBQIDARIElgEJ
EQoNCgUEBQIDAxIElgEUFQo/CgIEBhIGmgEApwEBGjEgRGV0YWlscyBhYm91dCB0aGUgbGF5
ZXIgYSBwYWNrYWdlIHdhcyBmb3VuZCBpbi4KCgsKAwQGARIEmgEIFAo+CgQEBgIAEgScAQIS
GjAgVGhlIGluZGV4IG9mIHRoZSBsYXllciBpbiB0aGUgY29udGFpbmVyIGltYWdlLgoKDQoF
BAYCAAUSBJwBAgcKDQoFBAYCAAESBJwBCA0KDQoFBAYCAAMSBJwBEBEKWgoEBAYCARIEngEC
FRpMIFRoZSBkaWZmIElEICh0eXBpY2FsbHkgYSBzaGEyNTYgaGFzaCkgb2YgdGhlIGxheWVy
IGluIHRoZSBjb250YWluZXIgaW1hZ2UuCgoNCgUEBgIBBRIEngECCAoNCgUEBgIBARIEngEJ
EAoNCgUEBgIBAxIEngETFAqmAQoEBAYCAhIEoQECFhqXASBUaGUgbGF5ZXIgY2hhaW4gSUQg
KHNoYTI1NiBoYXNoKSBvZiB0aGUgbGF5ZXIgaW4gdGhlIGNvbnRhaW5lciBpbWFnZS4KIGh0
dHBzOi8vZ2l0aHViLmNvbS9vcGVuY29udGFpbmVycy9pbWFnZS1zcGVjL2Jsb2IvbWFpbi9j
b25maWcubWQjbGF5ZXItY2hhaW5pZAoKDQoFBAYCAgUSBKEBAggKDQoFBAYCAgESBKEBCREK
DQoFBAYCAgMSBKEBFBUKngEKBAQGAgMSBKQBAhUajwEgVGhlIGxheWVyIGJ1aWxkIGNvbW1h
bmQgdGhhdCB3YXMgdXNlZCB0byBidWlsZCB0aGUgbGF5ZXIuIFRoaXMgbWF5IG5vdCBiZQog
Zm91bmQgaW4gYWxsIGxheWVycyBkZXBlbmRpbmcgb24gaG93IHRoZSBjb250YWluZXIgaW1h
Z2UgaXMgYnVpbHQuCgoNCgUEBgIDBRIEpAECCAoNCgUEBgIDARIEpAEJEAoNCgUEBgIDAxIE
pAETFAo6CgQEBgIEEgSmAQIlGiwgVGhlIGJhc2UgaW1hZ2VzIHRoZSBsYXllciBpcyBmb3Vu
ZCB3aXRoaW4uCgoNCgUEBgIEBBIEpgECCgoNCgUEBgIEBhIEpgELFAoNCgUEBgIEARIEpgEV
IAoNCgUEBgIEAxIEpgEjJAokCgIEBxIGqgEAtAEBGhYgTGljZW5zZSBpbmZvcm1hdGlvbi4K
CgsKAwQHARIEqgEIDwqzAgoEBAcCABIEsAECGBqkAiBPZnRlbiBhIHNpbmdsZSBsaWNlbnNl
IGNhbiBiZSB1c2VkIHRvIHJlcHJlc2VudCB0aGUgbGljZW5zaW5nIHRlcm1zLgogU29tZXRp
bWVzIGl0IGlzIG5lY2Vzc2FyeSB0byBpbmNsdWRlIGEgY2hvaWNlIG9mIG9uZSBvciBtb3Jl
IGxpY2Vuc2VzCiBvciBzb21lIGNvbWJpbmF0aW9uIG9mIGxpY2Vuc2UgaWRlbnRpZmllcnMu
CiBFeGFtcGxlczogIkxHUEwtMi4xLW9ubHkgT1IgTUlUIiwgIkxHUEwtMi4xLW9ubHkgQU5E
IE1JVCIsCiAiR1BMLTIuMC1vci1sYXRlciBXSVRIIEJpc29uLWV4Y2VwdGlvbi0yLjIiLgoK
DQoFBAcCAAUSBLABAggKDQoFBAcCAAESBLABCRMKDQoFBAcCAAMSBLABFhcKGAoEBAcCARIE
swECFhoKIENvbW1lbnRzCgoNCgUEBwIBBRIEswECCAoNCgUEBwIBARIEswEJEQoNCgUEBwIB
AxIEswEUFQojCgIECBIGtwEAvQEBGhUgRGlnZXN0IGluZm9ybWF0aW9uLgoKCwoDBAgBEgS3
AQgOCiUKBAQIAgASBLkBAhIaFyBgU0hBMWAsIGBTSEE1MTJgIGV0Yy4KCg0KBQQIAgAFEgS5
AQIICg0KBQQIAgABEgS5AQkNCg0KBQQIAgADEgS5ARARCiQKBAQIAgESBLwBAhkaFiBWYWx1
ZSBvZiB0aGUgZGlnZXN0LgoKDQoFBAgCAQUSBLwBAgcKDQoFBAgCAQESBLwBCBQKDQoFBAgC
AQMSBLwBFxhiBnByb3RvMw==
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Grafeas::V1::Common::RelatedUrl ===
    # Fields for RelatedUrl
    # Field: url Type: 9 ()
    # Field: label Type: 9 ()

# === Message: Grafeas::V1::Common::Signature ===
    # Fields for Signature
    # Field: signature Type: 12 ()
    # Field: public_key_id Type: 9 ()

# === Message: Grafeas::V1::Common::Envelope ===
    # Fields for Envelope
    # Field: payload Type: 12 ()
    # Field: payload_type Type: 9 ()
    # Field: signatures Type: 11 (.grafeas.v1.EnvelopeSignature)

# === Message: Grafeas::V1::Common::EnvelopeSignature ===
    # Fields for EnvelopeSignature
    # Field: sig Type: 12 ()
    # Field: keyid Type: 9 ()

# === Message: Grafeas::V1::Common::FileLocation ===
    # Fields for FileLocation
    # Field: file_path Type: 9 ()
    # Field: layer_details Type: 11 (.grafeas.v1.LayerDetails)
    # Field: line_number Type: 5 ()

# === Message: Grafeas::V1::Common::BaseImage ===
    # Fields for BaseImage
    # Field: name Type: 9 ()
    # Field: repository Type: 9 ()
    # Field: layer_count Type: 5 ()
    # Field: registry Type: 9 ()

# === Message: Grafeas::V1::Common::LayerDetails ===
    # Fields for LayerDetails
    # Field: index Type: 5 ()
    # Field: diff_id Type: 9 ()
    # Field: chain_id Type: 9 ()
    # Field: command Type: 9 ()
    # Field: base_images Type: 11 (.grafeas.v1.BaseImage)

# === Message: Grafeas::V1::Common::License ===
    # Fields for License
    # Field: expression Type: 9 ()
    # Field: comments Type: 9 ()

# === Message: Grafeas::V1::Common::Digest ===
    # Fields for Digest
    # Field: algo Type: 9 ()
    # Field: digest_bytes Type: 12 ()

1;

__END__

=encoding UTF-8

=head1 NAME

Grafeas::V1::Common - Compiled Protocol Buffers messages for grafeas/v1/common.proto

=head1 SYNOPSIS

    use Grafeas::V1::Common;

    my $msg = Grafeas::V1::Common::RelatedUrl->new({
        url => $url,
        label => $label,
    });

    # Read or update a field
    my $val = $msg->url();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Grafeas::V1::Common::RelatedUrl->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<grafeas/v1/common.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Grafeas::V1::Common::RelatedUrl

Metadata for any related URL information.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->url() >> / C<< $msg->url($value) >>

Type: C<String>

Specific URL associated with the resource.

=item * C<< $msg->label() >> / C<< $msg->label($value) >>

Type: C<String>

Label to describe usage of the URL.

=back

=head2 Grafeas::V1::Common::Signature

Verifiers (e.g. Kritis implementations) MUST verify signatures
with respect to the trust anchors defined in policy (e.g. a Kritis policy).
Typically this means that the verifier has been configured with a map from
`public_key_id` to public key material (and any required parameters, e.g.
signing algorithm).

In particular, verification implementations MUST NOT treat the signature
`public_key_id` as anything more than a key lookup hint. The `public_key_id`
DOES NOT validate or authenticate a public key; it only provides a mechanism
for quickly selecting a public key ALREADY CONFIGURED on the verifier through
a trusted channel. Verification implementations MUST reject signatures in any
of the following circumstances:
  * The `public_key_id` is not recognized by the verifier.
  * The public key that `public_key_id` refers to does not verify the
    signature with respect to the payload.

The `signature` contents SHOULD NOT be "attached" (where the payload is
included with the serialized `signature` bytes). Verifiers MUST ignore any
"attached" payload and only verify signatures with respect to explicitly
provided payload (e.g. a `payload` field on the proto message that holds
this Signature, or the canonical serialization of the proto message that
holds this signature).

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->signature() >> / C<< $msg->signature($value) >>

Type: C<Bytes>

The content of the signature, an opaque bytestring.
The payload that this signature verifies MUST be unambiguously provided
with the Signature during verification. A wrapper message might provide
the payload explicitly. Alternatively, a message might have a canonical
serialization that can always be unambiguously computed to derive the
payload.

=item * C<< $msg->public_key_id() >> / C<< $msg->public_key_id($value) >>

Type: C<String>

The identifier for the public key that verifies this signature.
  * The `public_key_id` is required.
  * The `public_key_id` SHOULD be an RFC3986 conformant URI.
  * When possible, the `public_key_id` SHOULD be an immutable reference,
    such as a cryptographic digest.

Examples of valid `public_key_id`s:

OpenPGP V4 public key fingerprint:
  * "openpgp4fpr:74FAF3B861BDA0870C7B6DEF607E48D2A663AEEA"
See https://www.iana.org/assignments/uri-schemes/prov/openpgp4fpr for more
details on this scheme.

RFC6920 digest-named SubjectPublicKeyInfo (digest of the DER
serialization):
  * "ni:///sha-256;cD9o9Cq6LG3jD0iKXqEi_vdjJGecm_iXkbqVoScViaU"
  * "nih:///sha-256;703f68f42aba2c6de30f488a5ea122fef76324679c9bf89791ba95a1271589a5"

=back

=head2 Grafeas::V1::Common::Envelope

MUST match
https://github.com/secure-systems-lab/dsse/blob/master/envelope.proto. An
authenticated message of arbitrary type.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->payload() >> / C<< $msg->payload($value) >>

Type: C<Bytes>

=item * C<< $msg->payload_type() >> / C<< $msg->payload_type($value) >>

Type: C<String>

=item * C<< $msg->signatures() >> / C<< $msg->signatures($value) >>

Type: C<Message> (L<Grafeas::V1::Common::EnvelopeSignature>)

=back

=head2 Grafeas::V1::Common::EnvelopeSignature

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->sig() >> / C<< $msg->sig($value) >>

Type: C<Bytes>

=item * C<< $msg->keyid() >> / C<< $msg->keyid($value) >>

Type: C<String>

=back

=head2 Grafeas::V1::Common::FileLocation

Indicates the location at which a package was found.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->file_path() >> / C<< $msg->file_path($value) >>

Type: C<String>

For jars that are contained inside .war files, this filepath
can indicate the path to war file combined with the path to jar file.

=item * C<< $msg->layer_details() >> / C<< $msg->layer_details($value) >>

Type: C<Message> (L<Grafeas::V1::Common::LayerDetails>)

Each package found in a file should have its own layer metadata (that is,
information from the origin layer of the package).

=item * C<< $msg->line_number() >> / C<< $msg->line_number($value) >>

Type: C<Int32>

Line number in the file where the package was found.
Optional field that only applies to source repository scanning.

=back

=head2 Grafeas::V1::Common::BaseImage

BaseImage describes a base image of a container image.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

The name of the base image.

=item * C<< $msg->repository() >> / C<< $msg->repository($value) >>

Type: C<String>

The repository name in which the base image is from.

=item * C<< $msg->layer_count() >> / C<< $msg->layer_count($value) >>

Type: C<Int32>

The number of layers that the base image is composed of.

=item * C<< $msg->registry() >> / C<< $msg->registry($value) >>

Type: C<String>

The registry in which the base image is from.

=back

=head2 Grafeas::V1::Common::LayerDetails

Details about the layer a package was found in.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->index() >> / C<< $msg->index($value) >>

Type: C<Int32>

The index of the layer in the container image.

=item * C<< $msg->diff_id() >> / C<< $msg->diff_id($value) >>

Type: C<String>

The diff ID (typically a sha256 hash) of the layer in the container image.

=item * C<< $msg->chain_id() >> / C<< $msg->chain_id($value) >>

Type: C<String>

The layer chain ID (sha256 hash) of the layer in the container image.
https://github.com/opencontainers/image-spec/blob/main/config.md#layer-chainid

=item * C<< $msg->command() >> / C<< $msg->command($value) >>

Type: C<String>

The layer build command that was used to build the layer. This may not be
found in all layers depending on how the container image is built.

=item * C<< $msg->base_images() >> / C<< $msg->base_images($value) >>

Type: C<Message> (L<Grafeas::V1::Common::BaseImage>)

The base images the layer is found within.

=back

=head2 Grafeas::V1::Common::License

License information.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->expression() >> / C<< $msg->expression($value) >>

Type: C<String>

Often a single license can be used to represent the licensing terms.
Sometimes it is necessary to include a choice of one or more licenses
or some combination of license identifiers.
Examples: "LGPL-2.1-only OR MIT", "LGPL-2.1-only AND MIT",
"GPL-2.0-or-later WITH Bison-exception-2.2".

=item * C<< $msg->comments() >> / C<< $msg->comments($value) >>

Type: C<String>

Comments

=back

=head2 Grafeas::V1::Common::Digest

Digest information.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->algo() >> / C<< $msg->algo($value) >>

Type: C<String>

`SHA1`, `SHA512` etc.

=item * C<< $msg->digest_bytes() >> / C<< $msg->digest_bytes($value) >>

Type: C<Bytes>

Value of the digest.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Grafeas::V1::Common::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
