package Google::Appengine::V1::Certificate;

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
CiVnb29nbGUvYXBwZW5naW5lL3YxL2NlcnRpZmljYXRlLnByb3RvEhNnb29nbGUuYXBwZW5n
aW5lLnYxGh9nb29nbGUvcHJvdG9idWYvdGltZXN0YW1wLnByb3RvIt8DChVBdXRob3JpemVk
Q2VydGlmaWNhdGUSEgoEbmFtZRgBIAEoCVIEbmFtZRIOCgJpZBgCIAEoCVICaWQSIQoMZGlz
cGxheV9uYW1lGAMgASgJUgtkaXNwbGF5TmFtZRIhCgxkb21haW5fbmFtZXMYBCADKAlSC2Rv
bWFpbk5hbWVzEjsKC2V4cGlyZV90aW1lGAUgASgLMhouZ29vZ2xlLnByb3RvYnVmLlRpbWVz
dGFtcFIKZXhwaXJlVGltZRJZChRjZXJ0aWZpY2F0ZV9yYXdfZGF0YRgGIAEoCzInLmdvb2ds
ZS5hcHBlbmdpbmUudjEuQ2VydGlmaWNhdGVSYXdEYXRhUhJjZXJ0aWZpY2F0ZVJhd0RhdGES
WAoTbWFuYWdlZF9jZXJ0aWZpY2F0ZRgHIAEoCzInLmdvb2dsZS5hcHBlbmdpbmUudjEuTWFu
YWdlZENlcnRpZmljYXRlUhJtYW5hZ2VkQ2VydGlmaWNhdGUSNgoXdmlzaWJsZV9kb21haW5f
bWFwcGluZ3MYCCADKAlSFXZpc2libGVEb21haW5NYXBwaW5ncxIyChVkb21haW5fbWFwcGlu
Z3NfY291bnQYCSABKAVSE2RvbWFpbk1hcHBpbmdzQ291bnQiZAoSQ2VydGlmaWNhdGVSYXdE
YXRhEi0KEnB1YmxpY19jZXJ0aWZpY2F0ZRgBIAEoCVIRcHVibGljQ2VydGlmaWNhdGUSHwoL
cHJpdmF0ZV9rZXkYAiABKAlSCnByaXZhdGVLZXkimwEKEk1hbmFnZWRDZXJ0aWZpY2F0ZRJG
ChFsYXN0X3JlbmV3YWxfdGltZRgBIAEoCzIaLmdvb2dsZS5wcm90b2J1Zi5UaW1lc3RhbXBS
D2xhc3RSZW5ld2FsVGltZRI9CgZzdGF0dXMYAiABKA4yJS5nb29nbGUuYXBwZW5naW5lLnYx
Lk1hbmFnZW1lbnRTdGF0dXNSBnN0YXR1cyrGAQoQTWFuYWdlbWVudFN0YXR1cxIhCh1NQU5B
R0VNRU5UX1NUQVRVU19VTlNQRUNJRklFRBAAEgYKAk9LEAESCwoHUEVORElORxACEh8KG0ZB
SUxFRF9SRVRSWUlOR19OT1RfVklTSUJMRRAEEhQKEEZBSUxFRF9QRVJNQU5FTlQQBhIhCh1G
QUlMRURfUkVUUllJTkdfQ0FBX0ZPUkJJRERFThAHEiAKHEZBSUxFRF9SRVRSWUlOR19DQUFf
Q0hFQ0tJTkcQCELBAQoXY29tLmdvb2dsZS5hcHBlbmdpbmUudjFCEENlcnRpZmljYXRlUHJv
dG9QAVo7Y2xvdWQuZ29vZ2xlLmNvbS9nby9hcHBlbmdpbmUvYXBpdjEvYXBwZW5naW5lcGI7
YXBwZW5naW5lcGKqAhlHb29nbGUuQ2xvdWQuQXBwRW5naW5lLlYxygIZR29vZ2xlXENsb3Vk
XEFwcEVuZ2luZVxWMeoCHEdvb2dsZTo6Q2xvdWQ6OkFwcEVuZ2luZTo6VjFK8jEKBxIFDgCr
AQEKvAQKAQwSAw4AEjKxBCBDb3B5cmlnaHQgMjAyNSBHb29nbGUgTExDCgogTGljZW5zZWQg
dW5kZXIgdGhlIEFwYWNoZSBMaWNlbnNlLCBWZXJzaW9uIDIuMCAodGhlICJMaWNlbnNlIik7
CiB5b3UgbWF5IG5vdCB1c2UgdGhpcyBmaWxlIGV4Y2VwdCBpbiBjb21wbGlhbmNlIHdpdGgg
dGhlIExpY2Vuc2UuCiBZb3UgbWF5IG9idGFpbiBhIGNvcHkgb2YgdGhlIExpY2Vuc2UgYXQK
CiAgICAgaHR0cDovL3d3dy5hcGFjaGUub3JnL2xpY2Vuc2VzL0xJQ0VOU0UtMi4wCgogVW5s
ZXNzIHJlcXVpcmVkIGJ5IGFwcGxpY2FibGUgbGF3IG9yIGFncmVlZCB0byBpbiB3cml0aW5n
LCBzb2Z0d2FyZQogZGlzdHJpYnV0ZWQgdW5kZXIgdGhlIExpY2Vuc2UgaXMgZGlzdHJpYnV0
ZWQgb24gYW4gIkFTIElTIiBCQVNJUywKIFdJVEhPVVQgV0FSUkFOVElFUyBPUiBDT05ESVRJ
T05TIE9GIEFOWSBLSU5ELCBlaXRoZXIgZXhwcmVzcyBvciBpbXBsaWVkLgogU2VlIHRoZSBM
aWNlbnNlIGZvciB0aGUgc3BlY2lmaWMgbGFuZ3VhZ2UgZ292ZXJuaW5nIHBlcm1pc3Npb25z
IGFuZAogbGltaXRhdGlvbnMgdW5kZXIgdGhlIExpY2Vuc2UuCgoICgECEgMQABwKCQoCAwAS
AxIAKQoICgEIEgMUADYKCQoCCCUSAxQANgoICgEIEgMVAFIKCQoCCAsSAxUAUgoICgEIEgMW
ACIKCQoCCAoSAxYAIgoICgEIEgMXADEKCQoCCAgSAxcAMQoICgEIEgMYADAKCQoCCAESAxgA
MAoICgEIEgMZADYKCQoCCCkSAxkANgoICgEIEgMaADUKCQoCCC0SAxoANQq2AQoCBAASBB8A
XwEaqQEgQW4gU1NMIGNlcnRpZmljYXRlIHRoYXQgYSB1c2VyIGhhcyBiZWVuIGF1dGhvcml6
ZWQgdG8gYWRtaW5pc3Rlci4gQSB1c2VyCiBpcyBhdXRob3JpemVkIHRvIGFkbWluaXN0ZXIg
YW55IGNlcnRpZmljYXRlIHRoYXQgYXBwbGllcyB0byBvbmUgb2YgdGhlaXIKIGF1dGhvcml6
ZWQgZG9tYWlucy4KCgoKAwQAARIDHwgdCpABCgQEAAIAEgMkAhIaggEgRnVsbCBwYXRoIHRv
IHRoZSBgQXV0aG9yaXplZENlcnRpZmljYXRlYCByZXNvdXJjZSBpbiB0aGUgQVBJLiBFeGFt
cGxlOgogYGFwcHMvbXlhcHAvYXV0aG9yaXplZENlcnRpZmljYXRlcy8xMjM0NWAuCgogQE91
dHB1dE9ubHkKCgwKBQQAAgAFEgMkAggKDAoFBAACAAESAyQJDQoMCgUEAAIAAxIDJBARCqUB
CgQEAAIBEgMqAhAalwEgUmVsYXRpdmUgbmFtZSBvZiB0aGUgY2VydGlmaWNhdGUuIFRoaXMg
aXMgYSB1bmlxdWUgdmFsdWUgYXV0b2dlbmVyYXRlZAogb24gYEF1dGhvcml6ZWRDZXJ0aWZp
Y2F0ZWAgcmVzb3VyY2UgY3JlYXRpb24uIEV4YW1wbGU6IGAxMjM0NWAuCgogQE91dHB1dE9u
bHkKCgwKBQQAAgEFEgMqAggKDAoFBAACAQESAyoJCwoMCgUEAAIBAxIDKg4PCoMBCgQEAAIC
EgMuAhoadiBUaGUgdXNlci1zcGVjaWZpZWQgZGlzcGxheSBuYW1lIG9mIHRoZSBjZXJ0aWZp
Y2F0ZS4gVGhpcyBpcyBub3QKIGd1YXJhbnRlZWQgdG8gYmUgdW5pcXVlLiBFeGFtcGxlOiBg
TXkgQ2VydGlmaWNhdGVgLgoKDAoFBAACAgUSAy4CCAoMCgUEAAICARIDLgkVCgwKBQQAAgID
EgMuGBkKpgEKBAQAAgMSAzQCIxqYASBUb3Btb3N0IGFwcGxpY2FibGUgZG9tYWlucyBvZiB0
aGlzIGNlcnRpZmljYXRlLiBUaGlzIGNlcnRpZmljYXRlCiBhcHBsaWVzIHRvIHRoZXNlIGRv
bWFpbnMgYW5kIHRoZWlyIHN1YmRvbWFpbnMuIEV4YW1wbGU6IGBleGFtcGxlLmNvbWAuCgog
QE91dHB1dE9ubHkKCgwKBQQAAgMEEgM0AgoKDAoFBAACAwUSAzQLEQoMCgUEAAIDARIDNBIe
CgwKBQQAAgMDEgM0ISIK8gEKBAQAAgQSAzsCLBrkASBUaGUgdGltZSB3aGVuIHRoaXMgY2Vy
dGlmaWNhdGUgZXhwaXJlcy4gVG8gdXBkYXRlIHRoZSByZW5ld2FsIHRpbWUgb24gdGhpcwog
Y2VydGlmaWNhdGUsIHVwbG9hZCBhbiBTU0wgY2VydGlmaWNhdGUgd2l0aCBhIGRpZmZlcmVu
dCBleHBpcmF0aW9uIHRpbWUKIHVzaW5nIFtgQXV0aG9yaXplZENlcnRpZmljYXRlcy5VcGRh
dGVBdXRob3JpemVkQ2VydGlmaWNhdGVgXSgpLgoKIEBPdXRwdXRPbmx5CgoMCgUEAAIEBhID
OwIbCgwKBQQAAgQBEgM7HCcKDAoFBAACBAMSAzsqKwqUAQoEBAACBRIDPwIuGoYBIFRoZSBT
U0wgY2VydGlmaWNhdGUgc2VydmluZyB0aGUgYEF1dGhvcml6ZWRDZXJ0aWZpY2F0ZWAgcmVz
b3VyY2UuIFRoaXMKIG11c3QgYmUgb2J0YWluZWQgaW5kZXBlbmRlbnRseSBmcm9tIGEgY2Vy
dGlmaWNhdGUgYXV0aG9yaXR5LgoKDAoFBAACBQYSAz8CFAoMCgUEAAIFARIDPxUpCgwKBQQA
AgUDEgM/LC0KvQIKBAQAAgYSA0cCLRqvAiBPbmx5IGFwcGxpY2FibGUgaWYgdGhpcyBjZXJ0
aWZpY2F0ZSBpcyBtYW5hZ2VkIGJ5IEFwcCBFbmdpbmUuIE1hbmFnZWQKIGNlcnRpZmljYXRl
cyBhcmUgdGllZCB0byB0aGUgbGlmZWN5Y2xlIG9mIGEgYERvbWFpbk1hcHBpbmdgIGFuZCBj
YW5ub3QgYmUKIHVwZGF0ZWQgb3IgZGVsZXRlZCB2aWEgdGhlIGBBdXRob3JpemVkQ2VydGlm
aWNhdGVzYCBBUEkuIElmIHRoaXMKIGNlcnRpZmljYXRlIGlzIG1hbnVhbGx5IGFkbWluaXN0
ZXJlZCBieSB0aGUgdXNlciwgdGhpcyBmaWVsZCB3aWxsIGJlIGVtcHR5LgoKIEBPdXRwdXRP
bmx5CgoMCgUEAAIGBhIDRwIUCgwKBQQAAgYBEgNHFSgKDAoFBAACBgMSA0crLAr9AwoEBAAC
BxIDVAIuGu8DIFRoZSBmdWxsIHBhdGhzIHRvIHVzZXIgdmlzaWJsZSBEb21haW4gTWFwcGlu
ZyByZXNvdXJjZXMgdGhhdCBoYXZlIHRoaXMKIGNlcnRpZmljYXRlIG1hcHBlZC4gRXhhbXBs
ZTogYGFwcHMvbXlhcHAvZG9tYWluTWFwcGluZ3MvZXhhbXBsZS5jb21gLgoKIFRoaXMgbWF5
IG5vdCByZXByZXNlbnQgdGhlIGZ1bGwgbGlzdCBvZiBtYXBwZWQgZG9tYWluIG1hcHBpbmdz
IGlmIHRoZSB1c2VyCiBkb2VzIG5vdCBoYXZlIGBWSUVXRVJgIHBlcm1pc3Npb25zIG9uIGFs
bCBvZiB0aGUgYXBwbGljYXRpb25zIHRoYXQgaGF2ZQogdGhpcyBjZXJ0aWZpY2F0ZSBtYXBw
ZWQuIFNlZSBgZG9tYWluX21hcHBpbmdzX2NvdW50YCBmb3IgYSBjb21wbGV0ZSBjb3VudC4K
CiBPbmx5IHJldHVybmVkIGJ5IGBHRVRgIG9yIGBMSVNUYCByZXF1ZXN0cyB3aGVuIHNwZWNp
ZmljYWxseSByZXF1ZXN0ZWQgYnkKIHRoZSBgdmlldz1GVUxMX0NFUlRJRklDQVRFYCBvcHRp
b24uCgogQE91dHB1dE9ubHkKCgwKBQQAAgcEEgNUAgoKDAoFBAACBwUSA1QLEQoMCgUEAAIH
ARIDVBIpCgwKBQQAAgcDEgNULC0KvwIKBAQAAggSA14CIhqxAiBBZ2dyZWdhdGUgY291bnQg
b2YgdGhlIGRvbWFpbiBtYXBwaW5ncyB3aXRoIHRoaXMgY2VydGlmaWNhdGUgbWFwcGVkLiBU
aGlzCiBjb3VudCBpbmNsdWRlcyBkb21haW4gbWFwcGluZ3Mgb24gYXBwbGljYXRpb25zIGZv
ciB3aGljaCB0aGUgdXNlciBkb2VzIG5vdAogaGF2ZSBgVklFV0VSYCBwZXJtaXNzaW9ucy4K
CiBPbmx5IHJldHVybmVkIGJ5IGBHRVRgIG9yIGBMSVNUYCByZXF1ZXN0cyB3aGVuIHNwZWNp
ZmljYWxseSByZXF1ZXN0ZWQgYnkKIHRoZSBgdmlldz1GVUxMX0NFUlRJRklDQVRFYCBvcHRp
b24uCgogQE91dHB1dE9ubHkKCgwKBQQAAggFEgNeAgcKDAoFBAACCAESA14IHQoMCgUEAAII
AxIDXiAhCkcKAgQBEgRiAHYBGjsgQW4gU1NMIGNlcnRpZmljYXRlIG9idGFpbmVkIGZyb20g
YSBjZXJ0aWZpY2F0ZSBhdXRob3JpdHkuCgoKCgMEAQESA2IIGgrzAQoEBAECABIDagIgGuUB
IFBFTSBlbmNvZGVkIHguNTA5IHB1YmxpYyBrZXkgY2VydGlmaWNhdGUuIFRoaXMgZmllbGQg
aXMgc2V0IG9uY2Ugb24KIGNlcnRpZmljYXRlIGNyZWF0aW9uLiBNdXN0IGluY2x1ZGUgdGhl
IGhlYWRlciBhbmQgZm9vdGVyLiBFeGFtcGxlOgogPHByZT4KIC0tLS0tQkVHSU4gQ0VSVElG
SUNBVEUtLS0tLQogPGNlcnRpZmljYXRlX3ZhbHVlPgogLS0tLS1FTkQgQ0VSVElGSUNBVEUt
LS0tLQogPC9wcmU+CgoMCgUEAQIABRIDagIICgwKBQQBAgABEgNqCRsKDAoFBAECAAMSA2oe
HwrHAgoEBAECARIDdQIZGrkCIFVuZW5jcnlwdGVkIFBFTSBlbmNvZGVkIFJTQSBwcml2YXRl
IGtleS4gVGhpcyBmaWVsZCBpcyBzZXQgb25jZSBvbgogY2VydGlmaWNhdGUgY3JlYXRpb24g
YW5kIHRoZW4gZW5jcnlwdGVkLiBUaGUga2V5IHNpemUgbXVzdCBiZSAyMDQ4CiBiaXRzIG9y
IGZld2VyLiBNdXN0IGluY2x1ZGUgdGhlIGhlYWRlciBhbmQgZm9vdGVyLiBFeGFtcGxlOgog
PHByZT4KIC0tLS0tQkVHSU4gUlNBIFBSSVZBVEUgS0VZLS0tLS0KIDx1bmVuY3J5cHRlZF9r
ZXlfdmFsdWU+CiAtLS0tLUVORCBSU0EgUFJJVkFURSBLRVktLS0tLQogPC9wcmU+CiBASW5w
dXRPbmx5CgoMCgUEAQIBBRIDdQIICgwKBQQBAgEBEgN1CRQKDAoFBAECAQMSA3UXGAp2CgIF
ABIFegCbAQEaaSBTdGF0ZSBvZiBjZXJ0aWZpY2F0ZSBtYW5hZ2VtZW50LiBSZWZlcnMgdG8g
dGhlIG1vc3QgcmVjZW50IGNlcnRpZmljYXRlCiBhY3F1aXNpdGlvbiBvciByZW5ld2FsIGF0
dGVtcHQuCgoKCgMFAAESA3oFFQoLCgQFAAIAEgN7AiQKDAoFBQACAAESA3sCHwoMCgUFAAIA
AhIDeyIjClsKBAUAAgESA38CCRpOIENlcnRpZmljYXRlIHdhcyBzdWNjZXNzZnVsbHkgb2J0
YWluZWQgYW5kIGluc2VydGVkIGludG8gdGhlIHNlcnZpbmcKIHN5c3RlbS4KCgwKBQUAAgEB
EgN/AgQKDAoFBQACAQISA38HCApJCgQFAAICEgSCAQIOGjsgQ2VydGlmaWNhdGUgaXMgdW5k
ZXIgYWN0aXZlIGF0dGVtcHRzIHRvIGFjcXVpcmUgb3IgcmVuZXcuCgoNCgUFAAICARIEggEC
CQoNCgUFAAICAhIEggEMDQqFAgoEBQACAxIEiAECIhr2ASBNb3N0IHJlY2VudCByZW5ld2Fs
IGZhaWxlZCBkdWUgdG8gYW4gaW52YWxpZCBETlMgc2V0dXAgYW5kIHdpbGwgYmUKIHJldHJp
ZWQuIFJlbmV3YWwgYXR0ZW1wdHMgd2lsbCBjb250aW51ZSB0byBmYWlsIHVudGlsIHRoZSBj
ZXJ0aWZpY2F0ZQogZG9tYWluJ3MgRE5TIGNvbmZpZ3VyYXRpb24gaXMgZml4ZWQuIFRoZSBs
YXN0IHN1Y2Nlc3NmdWxseSBwcm92aXNpb25lZAogY2VydGlmaWNhdGUgbWF5IHN0aWxsIGJl
IHNlcnZpbmcuCgoNCgUFAAIDARIEiAECHQoNCgUFAAIDAhIEiAEgIQpeCgQFAAIEEgSMAQIX
GlAgQWxsIHJlbmV3YWwgYXR0ZW1wdHMgaGF2ZSBiZWVuIGV4aGF1c3RlZCwgbGlrZWx5IGR1
ZSB0byBhbiBpbnZhbGlkIEROUwogc2V0dXAuCgoNCgUFAAIEARIEjAECEgoNCgUFAAIEAhIE
jAEVFgqZAgoEBQACBRIEkgECJBqKAiBNb3N0IHJlY2VudCByZW5ld2FsIGZhaWxlZCBkdWUg
dG8gYW4gZXhwbGljaXQgQ0FBIHJlY29yZCB0aGF0IGRvZXMgbm90CiBpbmNsdWRlIG9uZSBv
ZiB0aGUgaW4tdXNlIENBcyAoR29vZ2xlIENBIGFuZCBMZXQncyBFbmNyeXB0KS4gUmVuZXdh
bHMgd2lsbAogY29udGludWUgdG8gZmFpbCB1bnRpbCB0aGUgQ0FBIGlzIHJlY29uZmlndXJl
ZC4gVGhlIGxhc3Qgc3VjY2Vzc2Z1bGx5CiBwcm92aXNpb25lZCBjZXJ0aWZpY2F0ZSBtYXkg
c3RpbGwgYmUgc2VydmluZy4KCg0KBQUAAgUBEgSSAQIfCg0KBQUAAgUCEgSSASIjCpYDCgQF
AAIGEgSaAQIjGocDIE1vc3QgcmVjZW50IHJlbmV3YWwgZmFpbGVkIGR1ZSB0byBhIENBQSBy
ZXRyaWV2YWwgZmFpbHVyZS4gVGhpcyBtZWFucyB0aGF0CiB0aGUgZG9tYWluJ3MgRE5TIHBy
b3ZpZGVyIGRvZXMgbm90IHByb3Blcmx5IGhhbmRsZSBDQUEgcmVjb3JkcywgZmFpbGluZwog
cmVxdWVzdHMgZm9yIENBQSByZWNvcmRzIHdoZW4gbm8gQ0FBIHJlY29yZHMgYXJlIGRlZmlu
ZWQuIFJlbmV3YWxzIHdpbGwKIGNvbnRpbnVlIHRvIGZhaWwgdW50aWwgdGhlIEROUyBwcm92
aWRlciBpcyBjaGFuZ2VkIG9yIGEgQ0FBIHJlY29yZCBpcwogYWRkZWQgZm9yIHRoZSBnaXZl
biBkb21haW4uIFRoZSBsYXN0IHN1Y2Nlc3NmdWxseSBwcm92aXNpb25lZCBjZXJ0aWZpY2F0
ZQogbWF5IHN0aWxsIGJlIHNlcnZpbmcuCgoNCgUFAAIGARIEmgECHgoNCgUFAAIGAhIEmgEh
Igo0CgIEAhIGngEAqwEBGiYgQSBjZXJ0aWZpY2F0ZSBtYW5hZ2VkIGJ5IEFwcCBFbmdpbmUu
CgoLCgMEAgESBJ4BCBoK+QEKBAQCAgASBKQBAjIa6gEgVGltZSBhdCB3aGljaCB0aGUgY2Vy
dGlmaWNhdGUgd2FzIGxhc3QgcmVuZXdlZC4gVGhlIHJlbmV3YWwgcHJvY2VzcyBpcwogZnVs
bHkgbWFuYWdlZC4gQ2VydGlmaWNhdGUgcmVuZXdhbCB3aWxsIGF1dG9tYXRpY2FsbHkgb2Nj
dXIgYmVmb3JlIHRoZQogY2VydGlmaWNhdGUgZXhwaXJlcy4gUmVuZXdhbCBlcnJvcnMgY2Fu
IGJlIHRyYWNrZWQgdmlhIGBNYW5hZ2VtZW50U3RhdHVzYC4KCiBAT3V0cHV0T25seQoKDQoF
BAICAAYSBKQBAhsKDQoFBAICAAESBKQBHC0KDQoFBAICAAMSBKQBMDEKhgEKBAQCAgESBKoB
Ah4aeCBTdGF0dXMgb2YgY2VydGlmaWNhdGUgbWFuYWdlbWVudC4gUmVmZXJzIHRvIHRoZSBt
b3N0IHJlY2VudCBjZXJ0aWZpY2F0ZQogYWNxdWlzaXRpb24gb3IgcmVuZXdhbCBhdHRlbXB0
LgoKIEBPdXRwdXRPbmx5CgoNCgUEAgIBBhIEqgECEgoNCgUEAgIBARIEqgETGQoNCgUEAgIB
AxIEqgEcHWIGcHJvdG8z
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Appengine::V1::Certificate::AuthorizedCertificate ===
    # Fields for AuthorizedCertificate
    # Field: name Type: 9 ()
    # Field: id Type: 9 ()
    # Field: display_name Type: 9 ()
    # Field: domain_names Type: 9 ()
    # Field: expire_time Type: 11 (.google.protobuf.Timestamp)
    # Field: certificate_raw_data Type: 11 (.google.appengine.v1.CertificateRawData)
    # Field: managed_certificate Type: 11 (.google.appengine.v1.ManagedCertificate)
    # Field: visible_domain_mappings Type: 9 ()
    # Field: domain_mappings_count Type: 5 ()

# === Message: Google::Appengine::V1::Certificate::CertificateRawData ===
    # Fields for CertificateRawData
    # Field: public_certificate Type: 9 ()
    # Field: private_key Type: 9 ()

# === Message: Google::Appengine::V1::Certificate::ManagedCertificate ===
    # Fields for ManagedCertificate
    # Field: last_renewal_time Type: 11 (.google.protobuf.Timestamp)
    # Field: status Type: 14 (.google.appengine.v1.ManagementStatus)

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Appengine::V1::Certificate - Compiled Protocol Buffers messages for google/appengine/v1/certificate.proto

=head1 SYNOPSIS

    use Google::Appengine::V1::Certificate;

    my $msg = Google::Appengine::V1::Certificate::AuthorizedCertificate->new({
        name => $name,
        id => $id,
        display_name => $display_name,
        domain_names => $domain_names,
    });

    # Read or update a field
    my $val = $msg->name();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Appengine::V1::Certificate::AuthorizedCertificate->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/appengine/v1/certificate.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Appengine::V1::Certificate::AuthorizedCertificate

An SSL certificate that a user has been authorized to administer. A user
is authorized to administer any certificate that applies to one of their
authorized domains.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Full path to the `AuthorizedCertificate` resource in the API. Example:
`apps/myapp/authorizedCertificates/12345`.

@OutputOnly

=item * C<< $msg->id() >> / C<< $msg->id($value) >>

Type: C<String>

Relative name of the certificate. This is a unique value autogenerated
on `AuthorizedCertificate` resource creation. Example: `12345`.

@OutputOnly

=item * C<< $msg->display_name() >> / C<< $msg->display_name($value) >>

Type: C<String>

The user-specified display name of the certificate. This is not
guaranteed to be unique. Example: `My Certificate`.

=item * C<< $msg->domain_names() >> / C<< $msg->domain_names($value) >>

Type: C<String>

Topmost applicable domains of this certificate. This certificate
applies to these domains and their subdomains. Example: `example.com`.

@OutputOnly

=item * C<< $msg->expire_time() >> / C<< $msg->expire_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

The time when this certificate expires. To update the renewal time on this
certificate, upload an SSL certificate with a different expiration time
using [`AuthorizedCertificates.UpdateAuthorizedCertificate`]().

@OutputOnly

=item * C<< $msg->certificate_raw_data() >> / C<< $msg->certificate_raw_data($value) >>

Type: C<Message> (L<Google::Appengine::V1::Certificate::CertificateRawData>)

The SSL certificate serving the `AuthorizedCertificate` resource. This
must be obtained independently from a certificate authority.

=item * C<< $msg->managed_certificate() >> / C<< $msg->managed_certificate($value) >>

Type: C<Message> (L<Google::Appengine::V1::Certificate::ManagedCertificate>)

Only applicable if this certificate is managed by App Engine. Managed
certificates are tied to the lifecycle of a `DomainMapping` and cannot be
updated or deleted via the `AuthorizedCertificates` API. If this
certificate is manually administered by the user, this field will be empty.

@OutputOnly

=item * C<< $msg->visible_domain_mappings() >> / C<< $msg->visible_domain_mappings($value) >>

Type: C<String>

The full paths to user visible Domain Mapping resources that have this
certificate mapped. Example: `apps/myapp/domainMappings/example.com`.

This may not represent the full list of mapped domain mappings if the user
does not have `VIEWER` permissions on all of the applications that have
this certificate mapped. See `domain_mappings_count` for a complete count.

Only returned by `GET` or `LIST` requests when specifically requested by
the `view=FULL_CERTIFICATE` option.

@OutputOnly

=item * C<< $msg->domain_mappings_count() >> / C<< $msg->domain_mappings_count($value) >>

Type: C<Int32>

Aggregate count of the domain mappings with this certificate mapped. This
count includes domain mappings on applications for which the user does not
have `VIEWER` permissions.

Only returned by `GET` or `LIST` requests when specifically requested by
the `view=FULL_CERTIFICATE` option.

@OutputOnly

=back

=head2 Google::Appengine::V1::Certificate::CertificateRawData

An SSL certificate obtained from a certificate authority.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->public_certificate() >> / C<< $msg->public_certificate($value) >>

Type: C<String>

PEM encoded x.509 public key certificate. This field is set once on
certificate creation. Must include the header and footer. Example:
<pre>
-----BEGIN CERTIFICATE-----
<certificate_value>
-----END CERTIFICATE-----
</pre>

=item * C<< $msg->private_key() >> / C<< $msg->private_key($value) >>

Type: C<String>

Unencrypted PEM encoded RSA private key. This field is set once on
certificate creation and then encrypted. The key size must be 2048
bits or fewer. Must include the header and footer. Example:
<pre>
-----BEGIN RSA PRIVATE KEY-----
<unencrypted_key_value>
-----END RSA PRIVATE KEY-----
</pre>
@InputOnly

=back

=head2 Google::Appengine::V1::Certificate::ManagedCertificate

A certificate managed by App Engine.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->last_renewal_time() >> / C<< $msg->last_renewal_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Time at which the certificate was last renewed. The renewal process is
fully managed. Certificate renewal will automatically occur before the
certificate expires. Renewal errors can be tracked via `ManagementStatus`.

@OutputOnly

=item * C<< $msg->status() >> / C<< $msg->status($value) >>

Type: C<Enum> (L<Google::Appengine::V1::ManagementStatus>)

Status of certificate management. Refers to the most recent certificate
acquisition or renewal attempt.

@OutputOnly

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Appengine::V1::Certificate::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
