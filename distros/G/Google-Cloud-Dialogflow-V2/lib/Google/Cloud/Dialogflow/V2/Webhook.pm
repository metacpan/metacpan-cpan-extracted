package Google::Cloud::Dialogflow::V2::Webhook;

use strict;
use warnings;

our $VERSION = '0.14';

use Protobuf::Message;
use Protobuf::DescriptorPool;
use Protobuf::Internal qw(:all);
use MIME::Base64;

BEGIN {
    eval { require Google::Api::Resource };
    eval { require Google::Cloud::Dialogflow::V2::Context };
    eval { require Google::Cloud::Dialogflow::V2::Intent };
    eval { require Google::Cloud::Dialogflow::V2::Session };
    eval { require Google::Cloud::Dialogflow::V2::SessionEntityType };
    eval { require Google::Protobuf::Struct };
    my $descriptor_b64 = <<'EOF';
Cihnb29nbGUvY2xvdWQvZGlhbG9nZmxvdy92Mi93ZWJob29rLnByb3RvEhpnb29nbGUuY2xv
dWQuZGlhbG9nZmxvdy52MhoZZ29vZ2xlL2FwaS9yZXNvdXJjZS5wcm90bxooZ29vZ2xlL2Ns
b3VkL2RpYWxvZ2Zsb3cvdjIvY29udGV4dC5wcm90bxonZ29vZ2xlL2Nsb3VkL2RpYWxvZ2Zs
b3cvdjIvaW50ZW50LnByb3RvGihnb29nbGUvY2xvdWQvZGlhbG9nZmxvdy92Mi9zZXNzaW9u
LnByb3RvGjRnb29nbGUvY2xvdWQvZGlhbG9nZmxvdy92Mi9zZXNzaW9uX2VudGl0eV90eXBl
LnByb3RvGhxnb29nbGUvcHJvdG9idWYvc3RydWN0LnByb3RvIpUCCg5XZWJob29rUmVxdWVz
dBIYCgdzZXNzaW9uGAQgASgJUgdzZXNzaW9uEh8KC3Jlc3BvbnNlX2lkGAEgASgJUgpyZXNw
b25zZUlkEkoKDHF1ZXJ5X3Jlc3VsdBgCIAEoCzInLmdvb2dsZS5jbG91ZC5kaWFsb2dmbG93
LnYyLlF1ZXJ5UmVzdWx0UgtxdWVyeVJlc3VsdBJ8Ch5vcmlnaW5hbF9kZXRlY3RfaW50ZW50
X3JlcXVlc3QYAyABKAsyNy5nb29nbGUuY2xvdWQuZGlhbG9nZmxvdy52Mi5PcmlnaW5hbERl
dGVjdEludGVudFJlcXVlc3RSG29yaWdpbmFsRGV0ZWN0SW50ZW50UmVxdWVzdCLvAwoPV2Vi
aG9va1Jlc3BvbnNlEikKEGZ1bGZpbGxtZW50X3RleHQYASABKAlSD2Z1bGZpbGxtZW50VGV4
dBJdChRmdWxmaWxsbWVudF9tZXNzYWdlcxgCIAMoCzIqLmdvb2dsZS5jbG91ZC5kaWFsb2dm
bG93LnYyLkludGVudC5NZXNzYWdlUhNmdWxmaWxsbWVudE1lc3NhZ2VzEhYKBnNvdXJjZRgD
IAEoCVIGc291cmNlEjEKB3BheWxvYWQYBCABKAsyFy5nb29nbGUucHJvdG9idWYuU3RydWN0
UgdwYXlsb2FkEkwKD291dHB1dF9jb250ZXh0cxgFIAMoCzIjLmdvb2dsZS5jbG91ZC5kaWFs
b2dmbG93LnYyLkNvbnRleHRSDm91dHB1dENvbnRleHRzElgKFGZvbGxvd3VwX2V2ZW50X2lu
cHV0GAYgASgLMiYuZ29vZ2xlLmNsb3VkLmRpYWxvZ2Zsb3cudjIuRXZlbnRJbnB1dFISZm9s
bG93dXBFdmVudElucHV0El8KFHNlc3Npb25fZW50aXR5X3R5cGVzGAogAygLMi0uZ29vZ2xl
LmNsb3VkLmRpYWxvZ2Zsb3cudjIuU2Vzc2lvbkVudGl0eVR5cGVSEnNlc3Npb25FbnRpdHlU
eXBlcyKCAQobT3JpZ2luYWxEZXRlY3RJbnRlbnRSZXF1ZXN0EhYKBnNvdXJjZRgBIAEoCVIG
c291cmNlEhgKB3ZlcnNpb24YAiABKAlSB3ZlcnNpb24SMQoHcGF5bG9hZBgDIAEoCzIXLmdv
b2dsZS5wcm90b2J1Zi5TdHJ1Y3RSB3BheWxvYWRCkQIKHmNvbS5nb29nbGUuY2xvdWQuZGlh
bG9nZmxvdy52MkIMV2ViaG9va1Byb3RvUAFaPmNsb3VkLmdvb2dsZS5jb20vZ28vZGlhbG9n
Zmxvdy9hcGl2Mi9kaWFsb2dmbG93cGI7ZGlhbG9nZmxvd3BiogICREaqAhpHb29nbGUuQ2xv
dWQuRGlhbG9nZmxvdy5WMupBfAonc2VydmljZWRpcmVjdG9yeS5nb29nbGVhcGlzLmNvbS9T
ZXJ2aWNlElFwcm9qZWN0cy97cHJvamVjdH0vbG9jYXRpb25zL3tsb2NhdGlvbn0vbmFtZXNw
YWNlcy97bmFtZXNwYWNlfS9zZXJ2aWNlcy97c2VydmljZX1K+TAKBxIFDgCaAQEKvAQKAQwS
Aw4AEjKxBCBDb3B5cmlnaHQgMjAyNiBHb29nbGUgTExDCgogTGljZW5zZWQgdW5kZXIgdGhl
IEFwYWNoZSBMaWNlbnNlLCBWZXJzaW9uIDIuMCAodGhlICJMaWNlbnNlIik7CiB5b3UgbWF5
IG5vdCB1c2UgdGhpcyBmaWxlIGV4Y2VwdCBpbiBjb21wbGlhbmNlIHdpdGggdGhlIExpY2Vu
c2UuCiBZb3UgbWF5IG9idGFpbiBhIGNvcHkgb2YgdGhlIExpY2Vuc2UgYXQKCiAgICAgaHR0
cDovL3d3dy5hcGFjaGUub3JnL2xpY2Vuc2VzL0xJQ0VOU0UtMi4wCgogVW5sZXNzIHJlcXVp
cmVkIGJ5IGFwcGxpY2FibGUgbGF3IG9yIGFncmVlZCB0byBpbiB3cml0aW5nLCBzb2Z0d2Fy
ZQogZGlzdHJpYnV0ZWQgdW5kZXIgdGhlIExpY2Vuc2UgaXMgZGlzdHJpYnV0ZWQgb24gYW4g
IkFTIElTIiBCQVNJUywKIFdJVEhPVVQgV0FSUkFOVElFUyBPUiBDT05ESVRJT05TIE9GIEFO
WSBLSU5ELCBlaXRoZXIgZXhwcmVzcyBvciBpbXBsaWVkLgogU2VlIHRoZSBMaWNlbnNlIGZv
ciB0aGUgc3BlY2lmaWMgbGFuZ3VhZ2UgZ292ZXJuaW5nIHBlcm1pc3Npb25zIGFuZAogbGlt
aXRhdGlvbnMgdW5kZXIgdGhlIExpY2Vuc2UuCgoICgECEgMQACMKCQoCAwASAxIAIwoJCgID
ARIDEwAyCgkKAgMCEgMUADEKCQoCAwMSAxUAMgoJCgIDBBIDFgA+CgkKAgMFEgMXACYKCAoB
CBIDGQA3CgkKAgglEgMZADcKCAoBCBIDGgBVCgkKAggLEgMaAFUKCAoBCBIDGwAiCgkKAggK
EgMbACIKCAoBCBIDHAAtCgkKAggIEgMcAC0KCAoBCBIDHQA3CgkKAggBEgMdADcKCAoBCBID
HgAgCgkKAggkEgMeACAKCQoBCBIEHwAiAgoMCgQInQgAEgQfACICCjUKAgQAEgQlADgBGikg
VGhlIHJlcXVlc3QgbWVzc2FnZSBmb3IgYSB3ZWJob29rIGNhbGwuCgoKCgMEAAESAyUIFgqt
AgoEBAACABIDKwIVGp8CIFRoZSB1bmlxdWUgaWRlbnRpZmllciBvZiBkZXRlY3RJbnRlbnQg
cmVxdWVzdCBzZXNzaW9uLgogQ2FuIGJlIHVzZWQgdG8gaWRlbnRpZnkgZW5kLXVzZXIgaW5z
aWRlIHdlYmhvb2sgaW1wbGVtZW50YXRpb24uCiBGb3JtYXQ6IGBwcm9qZWN0cy88UHJvamVj
dCBJRD4vYWdlbnQvc2Vzc2lvbnMvPFNlc3Npb24gSUQ+YCwgb3IKIGBwcm9qZWN0cy88UHJv
amVjdCBJRD4vYWdlbnQvZW52aXJvbm1lbnRzLzxFbnZpcm9ubWVudCBJRD4vdXNlcnMvPFVz
ZXIKIElEPi9zZXNzaW9ucy88U2Vzc2lvbiBJRD5gLgoKDAoFBAACAAUSAysCCAoMCgUEAAIA
ARIDKwkQCgwKBQQAAgADEgMrExQKgAEKBAQAAgESAy8CGRpzIFRoZSB1bmlxdWUgaWRlbnRp
ZmllciBvZiB0aGUgcmVzcG9uc2UuIENvbnRhaW5zIHRoZSBzYW1lIHZhbHVlIGFzCiBgW1N0
cmVhbWluZ11EZXRlY3RJbnRlbnRSZXNwb25zZS5yZXNwb25zZV9pZGAuCgoMCgUEAAIBBRID
LwIICgwKBQQAAgEBEgMvCRQKDAoFBAACAQMSAy8XGAqXAQoEBAACAhIDMwIfGokBIFRoZSBy
ZXN1bHQgb2YgdGhlIGNvbnZlcnNhdGlvbmFsIHF1ZXJ5IG9yIGV2ZW50IHByb2Nlc3Npbmcu
IENvbnRhaW5zIHRoZQogc2FtZSB2YWx1ZSBhcyBgW1N0cmVhbWluZ11EZXRlY3RJbnRlbnRS
ZXNwb25zZS5xdWVyeV9yZXN1bHRgLgoKDAoFBAACAgYSAzMCDQoMCgUEAAICARIDMw4aCgwK
BQQAAgIDEgMzHR4KcQoEBAACAxIDNwJBGmQgT3B0aW9uYWwuIFRoZSBjb250ZW50cyBvZiB0
aGUgb3JpZ2luYWwgcmVxdWVzdCB0aGF0IHdhcyBwYXNzZWQgdG8KIGBbU3RyZWFtaW5nXURl
dGVjdEludGVudGAgY2FsbC4KCgwKBQQAAgMGEgM3Ah0KDAoFBAACAwESAzcePAoMCgUEAAID
AxIDNz9ACtsECgIEARIESQB+ARrOBCBUaGUgcmVzcG9uc2UgbWVzc2FnZSBmb3IgYSB3ZWJo
b29rIGNhbGwuCgogVGhpcyByZXNwb25zZSBpcyB2YWxpZGF0ZWQgYnkgdGhlIERpYWxvZ2Zs
b3cgc2VydmVyLiBJZiB2YWxpZGF0aW9uIGZhaWxzLAogYW4gZXJyb3Igd2lsbCBiZSByZXR1
cm5lZCBpbiB0aGUKIFtRdWVyeVJlc3VsdC5kaWFnbm9zdGljX2luZm9dW2dvb2dsZS5jbG91
ZC5kaWFsb2dmbG93LnYyLlF1ZXJ5UmVzdWx0LmRpYWdub3N0aWNfaW5mb10KIGZpZWxkLiBT
ZXR0aW5nIEpTT04gZmllbGRzIHRvIGFuIGVtcHR5IHZhbHVlIHdpdGggdGhlIHdyb25nIHR5
cGUgaXMgYSBjb21tb24KIGVycm9yLiBUbyBhdm9pZCB0aGlzIGVycm9yOgoKIC0gVXNlIGAi
ImAgZm9yIGVtcHR5IHN0cmluZ3MKIC0gVXNlIGB7fWAgb3IgYG51bGxgIGZvciBlbXB0eSBv
YmplY3RzCiAtIFVzZSBgW11gIG9yIGBudWxsYCBmb3IgZW1wdHkgYXJyYXlzCgogRm9yIG1v
cmUgaW5mb3JtYXRpb24sIHNlZSB0aGUKIFtQcm90b2NvbCBCdWZmZXJzIExhbmd1YWdlCiBH
dWlkZV0oaHR0cHM6Ly9kZXZlbG9wZXJzLmdvb2dsZS5jb20vcHJvdG9jb2wtYnVmZmVycy9k
b2NzL3Byb3RvMyNqc29uKS4KCgoKAwQBARIDSQgXCs0CCgQEAQIAEgNPAh4avwIgT3B0aW9u
YWwuIFRoZSB0ZXh0IHJlc3BvbnNlIG1lc3NhZ2UgaW50ZW5kZWQgZm9yIHRoZSBlbmQtdXNl
ci4KIEl0IGlzIHJlY29tbWVuZGVkIHRvIHVzZSBgZnVsZmlsbG1lbnRfbWVzc2FnZXMudGV4
dC50ZXh0WzBdYCBpbnN0ZWFkLgogV2hlbiBwcm92aWRlZCwgRGlhbG9nZmxvdyB1c2VzIHRo
aXMgZmllbGQgdG8gcG9wdWxhdGUKIFtRdWVyeVJlc3VsdC5mdWxmaWxsbWVudF90ZXh0XVtn
b29nbGUuY2xvdWQuZGlhbG9nZmxvdy52Mi5RdWVyeVJlc3VsdC5mdWxmaWxsbWVudF90ZXh0
XQogc2VudCB0byB0aGUgaW50ZWdyYXRpb24gb3IgQVBJIGNhbGxlci4KCgwKBQQBAgAFEgNP
AggKDAoFBAECAAESA08JGQoMCgUEAQIAAxIDTxwdCo8CCgQEAQIBEgNVAjMagQIgT3B0aW9u
YWwuIFRoZSByaWNoIHJlc3BvbnNlIG1lc3NhZ2VzIGludGVuZGVkIGZvciB0aGUgZW5kLXVz
ZXIuCiBXaGVuIHByb3ZpZGVkLCBEaWFsb2dmbG93IHVzZXMgdGhpcyBmaWVsZCB0byBwb3B1
bGF0ZQogW1F1ZXJ5UmVzdWx0LmZ1bGZpbGxtZW50X21lc3NhZ2VzXVtnb29nbGUuY2xvdWQu
ZGlhbG9nZmxvdy52Mi5RdWVyeVJlc3VsdC5mdWxmaWxsbWVudF9tZXNzYWdlc10KIHNlbnQg
dG8gdGhlIGludGVncmF0aW9uIG9yIEFQSSBjYWxsZXIuCgoMCgUEAQIBBBIDVQIKCgwKBQQB
AgEGEgNVCxkKDAoFBAECAQESA1UaLgoMCgUEAQIBAxIDVTEyCqMCCgQEAQICEgNcAhQalQIg
T3B0aW9uYWwuIEEgY3VzdG9tIGZpZWxkIHVzZWQgdG8gaWRlbnRpZnkgdGhlIHdlYmhvb2sg
c291cmNlLgogQXJiaXRyYXJ5IHN0cmluZ3MgYXJlIHN1cHBvcnRlZC4KIFdoZW4gcHJvdmlk
ZWQsIERpYWxvZ2Zsb3cgdXNlcyB0aGlzIGZpZWxkIHRvIHBvcHVsYXRlCiBbUXVlcnlSZXN1
bHQud2ViaG9va19zb3VyY2VdW2dvb2dsZS5jbG91ZC5kaWFsb2dmbG93LnYyLlF1ZXJ5UmVz
dWx0LndlYmhvb2tfc291cmNlXQogc2VudCB0byB0aGUgaW50ZWdyYXRpb24gb3IgQVBJIGNh
bGxlci4KCgwKBQQBAgIFEgNcAggKDAoFBAECAgESA1wJDwoMCgUEAQICAxIDXBITCo0FCgQE
AQIDEgNoAiUa/wQgT3B0aW9uYWwuIFRoaXMgZmllbGQgY2FuIGJlIHVzZWQgdG8gcGFzcyBj
dXN0b20gZGF0YSBmcm9tIHlvdXIgd2ViaG9vayB0bwogdGhlIGludGVncmF0aW9uIG9yIEFQ
SSBjYWxsZXIuIEFyYml0cmFyeSBKU09OIG9iamVjdHMgYXJlIHN1cHBvcnRlZC4gV2hlbgog
cHJvdmlkZWQsIERpYWxvZ2Zsb3cgdXNlcyB0aGlzIGZpZWxkIHRvIHBvcHVsYXRlCiBbUXVl
cnlSZXN1bHQud2ViaG9va19wYXlsb2FkXVtnb29nbGUuY2xvdWQuZGlhbG9nZmxvdy52Mi5R
dWVyeVJlc3VsdC53ZWJob29rX3BheWxvYWRdCiBzZW50IHRvIHRoZSBpbnRlZ3JhdGlvbiBv
ciBBUEkgY2FsbGVyLiBUaGlzIGZpZWxkIGlzIGFsc28gdXNlZCBieSB0aGUKIFtHb29nbGUg
QXNzaXN0YW50CiBpbnRlZ3JhdGlvbl0oaHR0cHM6Ly9jbG91ZC5nb29nbGUuY29tL2RpYWxv
Z2Zsb3cvZG9jcy9pbnRlZ3JhdGlvbnMvYW9nKQogZm9yIHJpY2ggcmVzcG9uc2UgbWVzc2Fn
ZXMuCiBTZWUgdGhlIGZvcm1hdCBkZWZpbml0aW9uIGF0IFtHb29nbGUgQXNzaXN0YW50IERp
YWxvZ2Zsb3cgd2ViaG9vawogZm9ybWF0XShodHRwczovL2RldmVsb3BlcnMuZ29vZ2xlLmNv
bS9hc3Npc3RhbnQvYWN0aW9ucy9idWlsZC9qc29uL2RpYWxvZ2Zsb3ctd2ViaG9vay1qc29u
KQoKDAoFBAECAwYSA2gCGAoMCgUEAQIDARIDaBkgCgwKBQQBAgMDEgNoIyQKywIKBAQBAgQS
A28CJxq9AiBPcHRpb25hbC4gVGhlIGNvbGxlY3Rpb24gb2Ygb3V0cHV0IGNvbnRleHRzIHRo
YXQgd2lsbCBvdmVyd3JpdGUgY3VycmVudGx5CiBhY3RpdmUgY29udGV4dHMgZm9yIHRoZSBz
ZXNzaW9uIGFuZCByZXNldCB0aGVpciBsaWZlc3BhbnMuCiBXaGVuIHByb3ZpZGVkLCBEaWFs
b2dmbG93IHVzZXMgdGhpcyBmaWVsZCB0byBwb3B1bGF0ZQogW1F1ZXJ5UmVzdWx0Lm91dHB1
dF9jb250ZXh0c11bZ29vZ2xlLmNsb3VkLmRpYWxvZ2Zsb3cudjIuUXVlcnlSZXN1bHQub3V0
cHV0X2NvbnRleHRzXQogc2VudCB0byB0aGUgaW50ZWdyYXRpb24gb3IgQVBJIGNhbGxlci4K
CgwKBQQBAgQEEgNvAgoKDAoFBAECBAYSA28LEgoMCgUEAQIEARIDbxMiCgwKBQQBAgQDEgNv
JSYKqQEKBAQBAgUSA3QCJhqbASBPcHRpb25hbC4gSW52b2tlcyB0aGUgc3VwcGxpZWQgZXZl
bnRzLgogV2hlbiB0aGlzIGZpZWxkIGlzIHNldCwgRGlhbG9nZmxvdyBpZ25vcmVzIHRoZSBg
ZnVsZmlsbG1lbnRfdGV4dGAsCiBgZnVsZmlsbG1lbnRfbWVzc2FnZXNgLCBhbmQgYHBheWxv
YWRgIGZpZWxkcy4KCgwKBQQBAgUGEgN0AgwKDAoFBAECBQESA3QNIQoMCgUEAQIFAxIDdCQl
CpgDCgQEAQIGEgN9AjcaigMgT3B0aW9uYWwuIEFkZGl0aW9uYWwgc2Vzc2lvbiBlbnRpdHkg
dHlwZXMgdG8gcmVwbGFjZSBvciBleHRlbmQgZGV2ZWxvcGVyCiBlbnRpdHkgdHlwZXMgd2l0
aC4gVGhlIGVudGl0eSBzeW5vbnltcyBhcHBseSB0byBhbGwgbGFuZ3VhZ2VzIGFuZCBwZXJz
aXN0CiBmb3IgdGhlIHNlc3Npb24uIFNldHRpbmcgdGhpcyBkYXRhIGZyb20gYSB3ZWJob29r
IG92ZXJ3cml0ZXMKIHRoZSBzZXNzaW9uIGVudGl0eSB0eXBlcyB0aGF0IGhhdmUgYmVlbiBz
ZXQgdXNpbmcgYGRldGVjdEludGVudGAsCiBgc3RyZWFtaW5nRGV0ZWN0SW50ZW50YCBvcgog
W1Nlc3Npb25FbnRpdHlUeXBlXVtnb29nbGUuY2xvdWQuZGlhbG9nZmxvdy52Mi5TZXNzaW9u
RW50aXR5VHlwZV0KIG1hbmFnZW1lbnQgbWV0aG9kcy4KCgwKBQQBAgYEEgN9AgoKDAoFBAEC
BgYSA30LHAoMCgUEAQIGARIDfR0xCgwKBQQBAgYDEgN9NDYKdwoCBAISBoIBAJoBARppIFJl
cHJlc2VudHMgdGhlIGNvbnRlbnRzIG9mIHRoZSBvcmlnaW5hbCByZXF1ZXN0IHRoYXQgd2Fz
IHBhc3NlZCB0bwogdGhlIGBbU3RyZWFtaW5nXURldGVjdEludGVudGAgY2FsbC4KCgsKAwQC
ARIEggEIIwp4CgQEAgIAEgSFAQIUGmogVGhlIHNvdXJjZSBvZiB0aGlzIHJlcXVlc3QsIGUu
Zy4sIGBnb29nbGVgLCBgZmFjZWJvb2tgLCBgc2xhY2tgLiBJdCBpcyBzZXQKIGJ5IERpYWxv
Z2Zsb3ctb3duZWQgc2VydmVycy4KCg0KBQQCAgAFEgSFAQIICg0KBQQCAgABEgSFAQkPCg0K
BQQCAgADEgSFARITCmkKBAQCAgESBIkBAhUaWyBPcHRpb25hbC4gVGhlIHZlcnNpb24gb2Yg
dGhlIHByb3RvY29sIHVzZWQgZm9yIHRoaXMgcmVxdWVzdC4KIFRoaXMgZmllbGQgaXMgQW9H
LXNwZWNpZmljLgoKDQoFBAICAQUSBIkBAggKDQoFBAICAQESBIkBCRAKDQoFBAICAQMSBIkB
ExQKxwQKBAQCAgISBJkBAiUauAQgT3B0aW9uYWwuIFRoaXMgZmllbGQgaXMgc2V0IHRvIHRo
ZSB2YWx1ZSBvZiB0aGUgYFF1ZXJ5UGFyYW1ldGVycy5wYXlsb2FkYAogZmllbGQgcGFzc2Vk
IGluIHRoZSByZXF1ZXN0LiBTb21lIGludGVncmF0aW9ucyB0aGF0IHF1ZXJ5IGEgRGlhbG9n
ZmxvdwogYWdlbnQgbWF5IHByb3ZpZGUgYWRkaXRpb25hbCBpbmZvcm1hdGlvbiBpbiB0aGUg
cGF5bG9hZC4KCiBJbiBwYXJ0aWN1bGFyLCBmb3IgdGhlIERpYWxvZ2Zsb3cgUGhvbmUgR2F0
ZXdheSBpbnRlZ3JhdGlvbiwgdGhpcyBmaWVsZCBoYXMKIHRoZSBmb3JtOgogPHByZT57CiAg
InRlbGVwaG9ueSI6IHsKICAgICJjYWxsZXJfaWQiOiAiKzE4NTU4MzYzOTg3IgogIH0KIH08
L3ByZT4KIE5vdGU6IFRoZSBjYWxsZXIgSUQgZmllbGQgKGBjYWxsZXJfaWRgKSB3aWxsIGJl
IHJlZGFjdGVkIGZvciBUcmlhbAogRWRpdGlvbiBhZ2VudHMgYW5kIHBvcHVsYXRlZCB3aXRo
IHRoZSBjYWxsZXIgSUQgaW4gW0UuMTY0CiBmb3JtYXRdKGh0dHBzOi8vZW4ud2lraXBlZGlh
Lm9yZy93aWtpL0UuMTY0KSBmb3IgRXNzZW50aWFscyBFZGl0aW9uIGFnZW50cy4KCg0KBQQC
AgIGEgSZAQIYCg0KBQQCAgIBEgSZARkgCg0KBQQCAgIDEgSZASMkYgZwcm90bzM=
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Dialogflow::V2::Webhook::WebhookRequest ===
    # Fields for WebhookRequest
    # Field: session Type: 9 ()
    # Field: response_id Type: 9 ()
    # Field: query_result Type: 11 (.google.cloud.dialogflow.v2.QueryResult)
    # Field: original_detect_intent_request Type: 11 (.google.cloud.dialogflow.v2.OriginalDetectIntentRequest)

# === Message: Google::Cloud::Dialogflow::V2::Webhook::WebhookResponse ===
    # Fields for WebhookResponse
    # Field: fulfillment_text Type: 9 ()
    # Field: fulfillment_messages Type: 11 (.google.cloud.dialogflow.v2.Intent.Message)
    # Field: source Type: 9 ()
    # Field: payload Type: 11 (.google.protobuf.Struct)
    # Field: output_contexts Type: 11 (.google.cloud.dialogflow.v2.Context)
    # Field: followup_event_input Type: 11 (.google.cloud.dialogflow.v2.EventInput)
    # Field: session_entity_types Type: 11 (.google.cloud.dialogflow.v2.SessionEntityType)

# === Message: Google::Cloud::Dialogflow::V2::Webhook::OriginalDetectIntentRequest ===
    # Fields for OriginalDetectIntentRequest
    # Field: source Type: 9 ()
    # Field: version Type: 9 ()
    # Field: payload Type: 11 (.google.protobuf.Struct)

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Dialogflow::V2::Webhook - Compiled Protocol Buffers messages for google/cloud/dialogflow/v2/webhook.proto

=head1 SYNOPSIS

    use Google::Cloud::Dialogflow::V2::Webhook;

    my $msg = Google::Cloud::Dialogflow::V2::Webhook::WebhookRequest->new({
        session => $session,
        response_id => $response_id,
        query_result => $query_result,
        original_detect_intent_request => $original_detect_intent_request,
    });

    # Read or update a field
    my $val = $msg->session();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Dialogflow::V2::Webhook::WebhookRequest->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/dialogflow/v2/webhook.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Dialogflow::V2::Webhook::WebhookRequest

The request message for a webhook call.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->session() >> / C<< $msg->session($value) >>

Type: C<String>

The unique identifier of detectIntent request session.
Can be used to identify end-user inside webhook implementation.
Format: `projects/<Project ID>/agent/sessions/<Session ID>`, or
`projects/<Project ID>/agent/environments/<Environment ID>/users/<User
ID>/sessions/<Session ID>`.

=item * C<< $msg->response_id() >> / C<< $msg->response_id($value) >>

Type: C<String>

The unique identifier of the response. Contains the same value as
`[Streaming]DetectIntentResponse.response_id`.

=item * C<< $msg->query_result() >> / C<< $msg->query_result($value) >>

Type: C<Message> (L<Google::Cloud::Dialogflow::V2::Session::QueryResult>)

The result of the conversational query or event processing. Contains the
same value as `[Streaming]DetectIntentResponse.query_result`.

=item * C<< $msg->original_detect_intent_request() >> / C<< $msg->original_detect_intent_request($value) >>

Type: C<Message> (L<Google::Cloud::Dialogflow::V2::Webhook::OriginalDetectIntentRequest>)

Optional. The contents of the original request that was passed to
`[Streaming]DetectIntent` call.

=back

=head2 Google::Cloud::Dialogflow::V2::Webhook::WebhookResponse

The response message for a webhook call.

This response is validated by the Dialogflow server. If validation fails,
an error will be returned in the
[QueryResult.diagnostic_info][google.cloud.dialogflow.v2.QueryResult.diagnostic_info]
field. Setting JSON fields to an empty value with the wrong type is a common
error. To avoid this error:

- Use `""` for empty strings
- Use `{}` or `null` for empty objects
- Use `[]` or `null` for empty arrays

For more information, see the
[Protocol Buffers Language
Guide](https://developers.google.com/protocol-buffers/docs/proto3#json).

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->fulfillment_text() >> / C<< $msg->fulfillment_text($value) >>

Type: C<String>

Optional. The text response message intended for the end-user.
It is recommended to use `fulfillment_messages.text.text[0]` instead.
When provided, Dialogflow uses this field to populate
[QueryResult.fulfillment_text][google.cloud.dialogflow.v2.QueryResult.fulfillment_text]
sent to the integration or API caller.

=item * C<< $msg->fulfillment_messages() >> / C<< $msg->fulfillment_messages($value) >>

Type: C<Message> (L<Google::Cloud::Dialogflow::V2::Intent::Intent::Message>)

Optional. The rich response messages intended for the end-user.
When provided, Dialogflow uses this field to populate
[QueryResult.fulfillment_messages][google.cloud.dialogflow.v2.QueryResult.fulfillment_messages]
sent to the integration or API caller.

=item * C<< $msg->source() >> / C<< $msg->source($value) >>

Type: C<String>

Optional. A custom field used to identify the webhook source.
Arbitrary strings are supported.
When provided, Dialogflow uses this field to populate
[QueryResult.webhook_source][google.cloud.dialogflow.v2.QueryResult.webhook_source]
sent to the integration or API caller.

=item * C<< $msg->payload() >> / C<< $msg->payload($value) >>

Type: C<Message> (L<Google::Protobuf::Struct::Struct>)

Optional. This field can be used to pass custom data from your webhook to
the integration or API caller. Arbitrary JSON objects are supported. When
provided, Dialogflow uses this field to populate
[QueryResult.webhook_payload][google.cloud.dialogflow.v2.QueryResult.webhook_payload]
sent to the integration or API caller. This field is also used by the
[Google Assistant
integration](https://cloud.google.com/dialogflow/docs/integrations/aog)
for rich response messages.
See the format definition at [Google Assistant Dialogflow webhook
format](https://developers.google.com/assistant/actions/build/json/dialogflow-webhook-json)

=item * C<< $msg->output_contexts() >> / C<< $msg->output_contexts($value) >>

Type: C<Message> (L<Google::Cloud::Dialogflow::V2::Context::Context>)

Optional. The collection of output contexts that will overwrite currently
active contexts for the session and reset their lifespans.
When provided, Dialogflow uses this field to populate
[QueryResult.output_contexts][google.cloud.dialogflow.v2.QueryResult.output_contexts]
sent to the integration or API caller.

=item * C<< $msg->followup_event_input() >> / C<< $msg->followup_event_input($value) >>

Type: C<Message> (L<Google::Cloud::Dialogflow::V2::Session::EventInput>)

Optional. Invokes the supplied events.
When this field is set, Dialogflow ignores the `fulfillment_text`,
`fulfillment_messages`, and `payload` fields.

=item * C<< $msg->session_entity_types() >> / C<< $msg->session_entity_types($value) >>

Type: C<Message> (L<Google::Cloud::Dialogflow::V2::SessionEntityType::SessionEntityType>)

Optional. Additional session entity types to replace or extend developer
entity types with. The entity synonyms apply to all languages and persist
for the session. Setting this data from a webhook overwrites
the session entity types that have been set using `detectIntent`,
`streamingDetectIntent` or
[SessionEntityType][google.cloud.dialogflow.v2.SessionEntityType]
management methods.

=back

=head2 Google::Cloud::Dialogflow::V2::Webhook::OriginalDetectIntentRequest

Represents the contents of the original request that was passed to
the `[Streaming]DetectIntent` call.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->source() >> / C<< $msg->source($value) >>

Type: C<String>

The source of this request, e.g., `google`, `facebook`, `slack`. It is set
by Dialogflow-owned servers.

=item * C<< $msg->version() >> / C<< $msg->version($value) >>

Type: C<String>

Optional. The version of the protocol used for this request.
This field is AoG-specific.

=item * C<< $msg->payload() >> / C<< $msg->payload($value) >>

Type: C<Message> (L<Google::Protobuf::Struct::Struct>)

Optional. This field is set to the value of the `QueryParameters.payload`
field passed in the request. Some integrations that query a Dialogflow
agent may provide additional information in the payload.

In particular, for the Dialogflow Phone Gateway integration, this field has
the form:
<pre>{
 "telephony": {
   "caller_id": "+18558363987"
 }
}</pre>
Note: The caller ID field (`caller_id`) will be redacted for Trial
Edition agents and populated with the caller ID in [E.164
format](https://en.wikipedia.org/wiki/E.164) for Essentials Edition agents.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Dialogflow::V2::Webhook::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
