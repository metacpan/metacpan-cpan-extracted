package Google::Cloud::Run::V2::VendorSettings;

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
    my $descriptor_b64 = <<'EOF';
Cilnb29nbGUvY2xvdWQvcnVuL3YyL3ZlbmRvcl9zZXR0aW5ncy5wcm90bxITZ29vZ2xlLmNs
b3VkLnJ1bi52MhofZ29vZ2xlL2FwaS9maWVsZF9iZWhhdmlvci5wcm90bxoZZ29vZ2xlL2Fw
aS9yZXNvdXJjZS5wcm90byLCAwoJVnBjQWNjZXNzEkUKCWNvbm5lY3RvchgBIAEoCUIn+kEk
CiJ2cGNhY2Nlc3MuZ29vZ2xlYXBpcy5jb20vQ29ubmVjdG9yUgljb25uZWN0b3ISRQoGZWdy
ZXNzGAIgASgOMiguZ29vZ2xlLmNsb3VkLnJ1bi52Mi5WcGNBY2Nlc3MuVnBjRWdyZXNzQgPg
QQFSBmVncmVzcxJjChJuZXR3b3JrX2ludGVyZmFjZXMYAyADKAsyLy5nb29nbGUuY2xvdWQu
cnVuLnYyLlZwY0FjY2Vzcy5OZXR3b3JrSW50ZXJmYWNlQgPgQQFSEW5ldHdvcmtJbnRlcmZh
Y2VzGm8KEE5ldHdvcmtJbnRlcmZhY2USHQoHbmV0d29yaxgBIAEoCUID4EEBUgduZXR3b3Jr
EiMKCnN1Ym5ldHdvcmsYAiABKAlCA+BBAVIKc3VibmV0d29yaxIXCgR0YWdzGAMgAygJQgPg
QQFSBHRhZ3MiUQoJVnBjRWdyZXNzEhoKFlZQQ19FR1JFU1NfVU5TUEVDSUZJRUQQABIPCgtB
TExfVFJBRkZJQxABEhcKE1BSSVZBVEVfUkFOR0VTX09OTFkQAiLdAQoTQmluYXJ5QXV0aG9y
aXphdGlvbhImCgt1c2VfZGVmYXVsdBgBIAEoCEID4EEBSABSCnVzZURlZmF1bHQSSwoGcG9s
aWN5GAMgASgJQjHgQQH6QSsKKWJpbmFyeWF1dGhvcml6YXRpb24uZ29vZ2xlYXBpcy5jb20v
UG9saWN5SABSBnBvbGljeRI+ChhicmVha2dsYXNzX2p1c3RpZmljYXRpb24YAiABKAlCA+BB
AVIXYnJlYWtnbGFzc0p1c3RpZmljYXRpb25CEQoPYmluYXV0aHpfbWV0aG9kIp0CCg9SZXZp
c2lvblNjYWxpbmcSMQoSbWluX2luc3RhbmNlX2NvdW50GAEgASgFQgPgQQFSEG1pbkluc3Rh
bmNlQ291bnQSMQoSbWF4X2luc3RhbmNlX2NvdW50GAIgASgFQgPgQQFSEG1heEluc3RhbmNl
Q291bnQSMQoPY3B1X3V0aWxpemF0aW9uGAQgASgCQgPgQQFIAFIOY3B1VXRpbGl6YXRpb26I
AQESQQoXY29uY3VycmVuY3lfdXRpbGl6YXRpb24YBSABKAJCA+BBAUgBUhZjb25jdXJyZW5j
eVV0aWxpemF0aW9uiAEBQhIKEF9jcHVfdXRpbGl6YXRpb25CGgoYX2NvbmN1cnJlbmN5X3V0
aWxpemF0aW9uIksKC1NlcnZpY2VNZXNoEjwKBG1lc2gYASABKAlCKPpBJQojbmV0d29ya3Nl
cnZpY2VzLmdvb2dsZWFwaXMuY29tL01lc2hSBG1lc2giiwEKEUFtYmllbnROZXR3b3JraW5n
EiIKB2VuYWJsZWQYASABKAhCA+BBAUgAUgdlbmFibGVkiAEBEkYKDWFtYmllbnRfc2NvcGUY
AiABKA4yIS5nb29nbGUuY2xvdWQucnVuLnYyLkFtYmllbnRTY29wZVIMYW1iaWVudFNjb3Bl
QgoKCF9lbmFibGVkIu8CCg5TZXJ2aWNlU2NhbGluZxIxChJtaW5faW5zdGFuY2VfY291bnQY
ASABKAVCA+BBAVIQbWluSW5zdGFuY2VDb3VudBJXCgxzY2FsaW5nX21vZGUYAyABKA4yLy5n
b29nbGUuY2xvdWQucnVuLnYyLlNlcnZpY2VTY2FsaW5nLlNjYWxpbmdNb2RlQgPgQQFSC3Nj
YWxpbmdNb2RlEjEKEm1heF9pbnN0YW5jZV9jb3VudBgEIAEoBUID4EEBUhBtYXhJbnN0YW5j
ZUNvdW50EjwKFW1hbnVhbF9pbnN0YW5jZV9jb3VudBgGIAEoBUID4EEBSABSE21hbnVhbElu
c3RhbmNlQ291bnSIAQEiRgoLU2NhbGluZ01vZGUSHAoYU0NBTElOR19NT0RFX1VOU1BFQ0lG
SUVEEAASDQoJQVVUT01BVElDEAESCgoGTUFOVUFMEAJCGAoWX21hbnVhbF9pbnN0YW5jZV9j
b3VudCJrChFXb3JrZXJQb29sU2NhbGluZxI8ChVtYW51YWxfaW5zdGFuY2VfY291bnQYBiAB
KAVCA+BBAUgAUhNtYW51YWxJbnN0YW5jZUNvdW50iAEBQhgKFl9tYW51YWxfaW5zdGFuY2Vf
Y291bnQiNQoMTm9kZVNlbGVjdG9yEiUKC2FjY2VsZXJhdG9yGAEgASgJQgPgQQJSC2FjY2Vs
ZXJhdG9yIucECgtCdWlsZENvbmZpZxI7CgRuYW1lGAEgASgJQifgQQP6QSEKH2Nsb3VkYnVp
bGQuZ29vZ2xlYXBpcy5jb20vQnVpbGRSBG5hbWUSJwoPc291cmNlX2xvY2F0aW9uGAIgASgJ
Ug5zb3VyY2VMb2NhdGlvbhIsCg9mdW5jdGlvbl90YXJnZXQYAyABKAlCA+BBAVIOZnVuY3Rp
b25UYXJnZXQSIAoJaW1hZ2VfdXJpGAQgASgJQgPgQQFSCGltYWdlVXJpEiIKCmJhc2VfaW1h
Z2UYBSABKAlCA+BBAVIJYmFzZUltYWdlEj0KGGVuYWJsZV9hdXRvbWF0aWNfdXBkYXRlcxgG
IAEoCEID4EEBUhZlbmFibGVBdXRvbWF0aWNVcGRhdGVzElIKC3dvcmtlcl9wb29sGAcgASgJ
QjHgQQH6QSsKKWNsb3VkYnVpbGQuZ29vZ2xlYXBpcy5jb20vQnVpbGRXb3JrZXJQb29sUgp3
b3JrZXJQb29sEnQKFWVudmlyb25tZW50X3ZhcmlhYmxlcxgIIAMoCzI6Lmdvb2dsZS5jbG91
ZC5ydW4udjIuQnVpbGRDb25maWcuRW52aXJvbm1lbnRWYXJpYWJsZXNFbnRyeUID4EEBUhRl
bnZpcm9ubWVudFZhcmlhYmxlcxIsCg9zZXJ2aWNlX2FjY291bnQYCSABKAlCA+BBAVIOc2Vy
dmljZUFjY291bnQaRwoZRW52aXJvbm1lbnRWYXJpYWJsZXNFbnRyeRIQCgNrZXkYASABKAlS
A2tleRIUCgV2YWx1ZRgCIAEoCVIFdmFsdWU6AjgBIvMBChZXb3JrbG9hZElkZW50aXR5Q29u
ZmlnEh8KCGlkZW50aXR5GAEgASgJQgPgQQFSCGlkZW50aXR5EksKDWlkZW50aXR5X3R5cGUY
AiABKA4yIS5nb29nbGUuY2xvdWQucnVuLnYyLklkZW50aXR5VHlwZUID4EEBUgxpZGVudGl0
eVR5cGUSSgocaWRlbnRpdHlfY2VydGlmaWNhdGVfZW5hYmxlZBgDIAEoCEID4EEBSABSGmlk
ZW50aXR5Q2VydGlmaWNhdGVFbmFibGVkiAEBQh8KHV9pZGVudGl0eV9jZXJ0aWZpY2F0ZV9l
bmFibGVkKmMKDEFtYmllbnRTY29wZRIdChlBTUJJRU5UX1NDT1BFX1VOU1BFQ0lGSUVEEAAS
GgoWQU1CSUVOVF9TQ09QRV9SRUdJT05BTBABEhgKFEFNQklFTlRfU0NPUEVfR0xPQkFMEAIq
swEKDkluZ3Jlc3NUcmFmZmljEh8KG0lOR1JFU1NfVFJBRkZJQ19VTlNQRUNJRklFRBAAEhcK
E0lOR1JFU1NfVFJBRkZJQ19BTEwQARIhCh1JTkdSRVNTX1RSQUZGSUNfSU5URVJOQUxfT05M
WRACEioKJklOR1JFU1NfVFJBRkZJQ19JTlRFUk5BTF9MT0FEX0JBTEFOQ0VSEAMSGAoUSU5H
UkVTU19UUkFGRklDX05PTkUQBCp9ChRFeGVjdXRpb25FbnZpcm9ubWVudBIlCiFFWEVDVVRJ
T05fRU5WSVJPTk1FTlRfVU5TUEVDSUZJRUQQABIeChpFWEVDVVRJT05fRU5WSVJPTk1FTlRf
R0VOMRABEh4KGkVYRUNVVElPTl9FTlZJUk9OTUVOVF9HRU4yEAIqcAodRW5jcnlwdGlvbktl
eVJldm9jYXRpb25BY3Rpb24SMAosRU5DUllQVElPTl9LRVlfUkVWT0NBVElPTl9BQ1RJT05f
VU5TUEVDSUZJRUQQABIPCgtQUkVWRU5UX05FVxABEgwKCFNIVVRET1dOEAIqcgoMSWRlbnRp
dHlUeXBlEh0KGUlERU5USVRZX1RZUEVfVU5TUEVDSUZJRUQQABIhCh1JREVOVElUWV9UWVBF
X1NFUlZJQ0VfQUNDT1VOVBABEiAKHElERU5USVRZX1RZUEVfQUdFTlRfSURFTlRJVFkQAyps
Cg5GdW5jdGlvbmFsVHlwZRIfChtGVU5DVElPTkFMX1RZUEVfVU5TUEVDSUZJRUQQABIZChVG
VU5DVElPTkFMX1RZUEVfQUdFTlQQARIeChpGVU5DVElPTkFMX1RZUEVfTUNQX1NFUlZFUhAC
QvwCChdjb20uZ29vZ2xlLmNsb3VkLnJ1bi52MkITVmVuZG9yU2V0dGluZ3NQcm90b1ABWilj
bG91ZC5nb29nbGUuY29tL2dvL3J1bi9hcGl2Mi9ydW5wYjtydW5wYupBYwopYmluYXJ5YXV0
aG9yaXphdGlvbi5nb29nbGVhcGlzLmNvbS9Qb2xpY3kSGXByb2plY3RzL3twcm9qZWN0fS9w
b2xpY3kSG2xvY2F0aW9ucy97bG9jYXRpb259L3BvbGljeepBXAojbmV0d29ya3NlcnZpY2Vz
Lmdvb2dsZWFwaXMuY29tL01lc2gSNXByb2plY3RzL3twcm9qZWN0fS9sb2NhdGlvbnMve2xv
Y2F0aW9ufS9tZXNoZXMve21lc2h96kFZCh9jbG91ZGJ1aWxkLmdvb2dsZWFwaXMuY29tL0J1
aWxkEjZwcm9qZWN0cy97cHJvamVjdH0vbG9jYXRpb25zL3tsb2NhdGlvbn0vYnVpbGRzL3ti
dWlsZH1K+mQKBxIFDgDmAgEKvAQKAQwSAw4AEjKxBCBDb3B5cmlnaHQgMjAyNiBHb29nbGUg
TExDCgogTGljZW5zZWQgdW5kZXIgdGhlIEFwYWNoZSBMaWNlbnNlLCBWZXJzaW9uIDIuMCAo
dGhlICJMaWNlbnNlIik7CiB5b3UgbWF5IG5vdCB1c2UgdGhpcyBmaWxlIGV4Y2VwdCBpbiBj
b21wbGlhbmNlIHdpdGggdGhlIExpY2Vuc2UuCiBZb3UgbWF5IG9idGFpbiBhIGNvcHkgb2Yg
dGhlIExpY2Vuc2UgYXQKCiAgICAgaHR0cDovL3d3dy5hcGFjaGUub3JnL2xpY2Vuc2VzL0xJ
Q0VOU0UtMi4wCgogVW5sZXNzIHJlcXVpcmVkIGJ5IGFwcGxpY2FibGUgbGF3IG9yIGFncmVl
ZCB0byBpbiB3cml0aW5nLCBzb2Z0d2FyZQogZGlzdHJpYnV0ZWQgdW5kZXIgdGhlIExpY2Vu
c2UgaXMgZGlzdHJpYnV0ZWQgb24gYW4gIkFTIElTIiBCQVNJUywKIFdJVEhPVVQgV0FSUkFO
VElFUyBPUiBDT05ESVRJT05TIE9GIEFOWSBLSU5ELCBlaXRoZXIgZXhwcmVzcyBvciBpbXBs
aWVkLgogU2VlIHRoZSBMaWNlbnNlIGZvciB0aGUgc3BlY2lmaWMgbGFuZ3VhZ2UgZ292ZXJu
aW5nIHBlcm1pc3Npb25zIGFuZAogbGltaXRhdGlvbnMgdW5kZXIgdGhlIExpY2Vuc2UuCgoI
CgECEgMQABwKCQoCAwASAxIAKQoJCgIDARIDEwAjCggKAQgSAxUAQAoJCgIICxIDFQBACggK
AQgSAxYAIgoJCgIIChIDFgAiCggKAQgSAxcANAoJCgIICBIDFwA0CggKAQgSAxgAMAoJCgII
ARIDGAAwCgkKAQgSBBkAHQIKDAoECJ0IABIEGQAdAgoJCgEIEgQeACECCgwKBAidCAESBB4A
IQIKCQoBCBIEIgAlAgoMCgQInQgCEgQiACUCCqIBCgIEABIEKQBbARqVASBWUEMgQWNjZXNz
IHNldHRpbmdzLiBGb3IgbW9yZSBpbmZvcm1hdGlvbiBvbiBzZW5kaW5nIHRyYWZmaWMgdG8g
YSBWUEMKIG5ldHdvcmssIHZpc2l0IGh0dHBzOi8vY2xvdWQuZ29vZ2xlLmNvbS9ydW4vZG9j
cy9jb25maWd1cmluZy9jb25uZWN0aW5nLXZwYy4KCgoKAwQAARIDKQgRCi4KBAQABAASBCsC
NAMaICBFZ3Jlc3Mgb3B0aW9ucyBmb3IgVlBDIGFjY2Vzcy4KCgwKBQQABAABEgMrBxAKHAoG
BAAEAAIAEgMtBB8aDSBVbnNwZWNpZmllZAoKDgoHBAAEAAIAARIDLQQaCg4KBwQABAACAAIS
Ay0dHgpKCgYEAAQAAgESAzAEFBo7IEFsbCBvdXRib3VuZCB0cmFmZmljIGlzIHJvdXRlZCB0
aHJvdWdoIHRoZSBWUEMgY29ubmVjdG9yLgoKDgoHBAAEAAIBARIDMAQPCg4KBwQABAACAQIS
AzASEwpNCgYEAAQAAgISAzMEHBo+IE9ubHkgcHJpdmF0ZSBJUCByYW5nZXMgYXJlIHJvdXRl
ZCB0aHJvdWdoIHRoZSBWUEMgY29ubmVjdG9yLgoKDgoHBAAEAAICARIDMwQXCg4KBwQABAAC
AgISAzMaGworCgQEAAMAEgQ3AkgDGh0gRGlyZWN0IFZQQyBlZ3Jlc3Mgc2V0dGluZ3MuCgoM
CgUEAAMAARIDNwoaCtkCCgYEAAMAAgASAz0EQBrJAiBPcHRpb25hbC4gVGhlIFZQQyBuZXR3
b3JrIHRoYXQgdGhlIENsb3VkIFJ1biByZXNvdXJjZSB3aWxsIGJlIGFibGUgdG8KIHNlbmQg
dHJhZmZpYyB0by4gQXQgbGVhc3Qgb25lIG9mIG5ldHdvcmsgb3Igc3VibmV0d29yayBtdXN0
IGJlIHNwZWNpZmllZC4KIElmIGJvdGggbmV0d29yayBhbmQgc3VibmV0d29yayBhcmUgc3Bl
Y2lmaWVkLCB0aGUgZ2l2ZW4gVlBDIHN1Ym5ldHdvcmsKIG11c3QgYmVsb25nIHRvIHRoZSBn
aXZlbiBWUEMgbmV0d29yay4gSWYgbmV0d29yayBpcyBub3Qgc3BlY2lmaWVkLCBpdAogd2ls
bCBiZSBsb29rZWQgdXAgZnJvbSB0aGUgc3VibmV0d29yay4KCg4KBwQAAwACAAUSAz0ECgoO
CgcEAAMAAgABEgM9CxIKDgoHBAADAAIAAxIDPRUWCg4KBwQAAwACAAgSAz0XPwoRCgoEAAMA
AgAInAgAEgM9GD4K6AIKBgQAAwACARIDRARDGtgCIE9wdGlvbmFsLiBUaGUgVlBDIHN1Ym5l
dHdvcmsgdGhhdCB0aGUgQ2xvdWQgUnVuIHJlc291cmNlIHdpbGwgZ2V0IElQcwogZnJvbS4g
QXQgbGVhc3Qgb25lIG9mIG5ldHdvcmsgb3Igc3VibmV0d29yayBtdXN0IGJlIHNwZWNpZmll
ZC4gSWYgYm90aAogbmV0d29yayBhbmQgc3VibmV0d29yayBhcmUgc3BlY2lmaWVkLCB0aGUg
Z2l2ZW4gVlBDIHN1Ym5ldHdvcmsgbXVzdAogYmVsb25nIHRvIHRoZSBnaXZlbiBWUEMgbmV0
d29yay4gSWYgc3VibmV0d29yayBpcyBub3Qgc3BlY2lmaWVkLCB0aGUKIHN1Ym5ldHdvcmsg
d2l0aCB0aGUgc2FtZSBuYW1lIHdpdGggdGhlIG5ldHdvcmsgd2lsbCBiZSB1c2VkLgoKDgoH
BAADAAIBBRIDRAQKCg4KBwQAAwACAQESA0QLFQoOCgcEAAMAAgEDEgNEGBkKDgoHBAADAAIB
CBIDRBpCChEKCgQAAwACAQicCAASA0QbQQpLCgYEAAMAAgISA0cERho8IE9wdGlvbmFsLiBO
ZXR3b3JrIHRhZ3MgYXBwbGllZCB0byB0aGlzIENsb3VkIFJ1biByZXNvdXJjZS4KCg4KBwQA
AwACAgQSA0cEDAoOCgcEAAMAAgIFEgNHDRMKDgoHBAADAAICARIDRxQYCg4KBwQAAwACAgMS
A0cbHAoOCgcEAAMAAgIIEgNHHUUKEQoKBAADAAICCJwIABIDRx5ECrYCCgQEAAIAEgRPAlEF
GqcCIFZQQyBBY2Nlc3MgY29ubmVjdG9yIG5hbWUuCiBGb3JtYXQ6IGBwcm9qZWN0cy97cHJv
amVjdH0vbG9jYXRpb25zL3tsb2NhdGlvbn0vY29ubmVjdG9ycy97Y29ubmVjdG9yfWAsCiB3
aGVyZSBge3Byb2plY3R9YCBjYW4gYmUgcHJvamVjdCBpZCBvciBudW1iZXIuCiBGb3IgbW9y
ZSBpbmZvcm1hdGlvbiBvbiBzZW5kaW5nIHRyYWZmaWMgdG8gYSBWUEMgbmV0d29yayB2aWEg
YSBjb25uZWN0b3IsCiB2aXNpdCBodHRwczovL2Nsb3VkLmdvb2dsZS5jb20vcnVuL2RvY3Mv
Y29uZmlndXJpbmcvdnBjLWNvbm5lY3RvcnMuCgoMCgUEAAIABRIDTwIICgwKBQQAAgABEgNP
CRIKDAoFBAACAAMSA08VFgoNCgUEAAIACBIETxdRBAoPCgcEAAIACJ8IEgRPGFEDCmsKBAQA
AgESA1UCQBpeIE9wdGlvbmFsLiBUcmFmZmljIFZQQyBlZ3Jlc3Mgc2V0dGluZ3MuIElmIG5v
dCBwcm92aWRlZCwgaXQgZGVmYXVsdHMgdG8KIFBSSVZBVEVfUkFOR0VTX09OTFkuCgoMCgUE
AAIBBhIDVQILCgwKBQQAAgEBEgNVDBIKDAoFBAACAQMSA1UVFgoMCgUEAAIBCBIDVRc/Cg8K
CAQAAgEInAgAEgNVGD4KbAoEBAACAhIEWQJaLxpeIE9wdGlvbmFsLiBEaXJlY3QgVlBDIGVn
cmVzcyBzZXR0aW5ncy4gQ3VycmVudGx5IG9ubHkgc2luZ2xlIG5ldHdvcmsKIGludGVyZmFj
ZSBpcyBzdXBwb3J0ZWQuCgoMCgUEAAICBBIDWQIKCgwKBQQAAgIGEgNZCxsKDAoFBAACAgES
A1kcLgoMCgUEAAICAxIDWTEyCgwKBQQAAgIIEgNaBi4KDwoIBAACAgicCAASA1oHLQo4CgIE
ARIEXgBzARosIFNldHRpbmdzIGZvciBCaW5hcnkgQXV0aG9yaXphdGlvbiBmZWF0dXJlLgoK
CgoDBAEBEgNeCBsKDAoEBAEIABIEXwJsAwoMCgUEAQgAARIDXwgXCpgBCgQEAQIAEgNiBEIa
igEgT3B0aW9uYWwuIElmIFRydWUsIGluZGljYXRlcyB0byB1c2UgdGhlIGRlZmF1bHQgcHJv
amVjdCdzIGJpbmFyeQogYXV0aG9yaXphdGlvbiBwb2xpY3kuIElmIEZhbHNlLCBiaW5hcnkg
YXV0aG9yaXphdGlvbiB3aWxsIGJlIGRpc2FibGVkLgoKDAoFBAECAAUSA2IECAoMCgUEAQIA
ARIDYgkUCgwKBQQBAgADEgNiFxgKDAoFBAECAAgSA2IZQQoPCggEAQIACJwIABIDYhpACoMB
CgQEAQIBEgRmBGsGGnUgT3B0aW9uYWwuIFRoZSBwYXRoIHRvIGEgYmluYXJ5IGF1dGhvcml6
YXRpb24gcG9saWN5LgogRm9ybWF0OiBgcHJvamVjdHMve3Byb2plY3R9L3BsYXRmb3Jtcy9j
bG91ZFJ1bi97cG9saWN5LW5hbWV9YAoKDAoFBAECAQUSA2YECgoMCgUEAQIBARIDZgsRCgwK
BQQBAgEDEgNmFBUKDQoFBAECAQgSBGYWawUKDwoIBAECAQicCAASA2cGLAoPCgcEAQIBCJ8I
EgRoBmoHCvoBCgQEAQICEgNyAk8a7AEgT3B0aW9uYWwuIElmIHByZXNlbnQsIGluZGljYXRl
cyB0byB1c2UgQnJlYWtnbGFzcyB1c2luZyB0aGlzIGp1c3RpZmljYXRpb24uCiBJZiB1c2Vf
ZGVmYXVsdCBpcyBGYWxzZSwgdGhlbiBpdCBtdXN0IGJlIGVtcHR5LgogRm9yIG1vcmUgaW5m
b3JtYXRpb24gb24gYnJlYWtnbGFzcywgc2VlCiBodHRwczovL2Nsb3VkLmdvb2dsZS5jb20v
YmluYXJ5LWF1dGhvcml6YXRpb24vZG9jcy91c2luZy1icmVha2dsYXNzCgoMCgUEAQICBRID
cgIICgwKBQQBAgIBEgNyCSEKDAoFBAECAgMSA3IkJQoMCgUEAQICCBIDciZOCg8KCAQBAgII
nAgAEgNyJ00KPAoCBAISBXYAjQEBGi8gU2V0dGluZ3MgZm9yIHJldmlzaW9uLWxldmVsIHNj
YWxpbmcgc2V0dGluZ3MuCgoKCgMEAgESA3YIFwpdCgQEAgIAEgN5AkgaUCBPcHRpb25hbC4g
TWluaW11bSBudW1iZXIgb2Ygc2VydmluZyBpbnN0YW5jZXMgdGhhdCB0aGlzIHJlc291cmNl
IHNob3VsZAogaGF2ZS4KCgwKBQQCAgAFEgN5AgcKDAoFBAICAAESA3kIGgoMCgUEAgIAAxID
eR0eCgwKBQQCAgAIEgN5H0cKDwoIBAICAAicCAASA3kgRgr8AQoEBAICARIDfwJIGu4BIE9w
dGlvbmFsLiBNYXhpbXVtIG51bWJlciBvZiBzZXJ2aW5nIGluc3RhbmNlcyB0aGF0IHRoaXMg
cmVzb3VyY2Ugc2hvdWxkCiBoYXZlLiBXaGVuIHVuc3BlY2lmaWVkLCB0aGUgZmllbGQgaXMg
c2V0IHRvIHRoZSBzZXJ2ZXIgZGVmYXVsdCB2YWx1ZSBvZgogMTAwLiBGb3IgbW9yZSBpbmZv
cm1hdGlvbiBzZWUKIGh0dHBzOi8vY2xvdWQuZ29vZ2xlLmNvbS9ydW4vZG9jcy9jb25maWd1
cmluZy9tYXgtaW5zdGFuY2VzCgoMCgUEAgIBBRIDfwIHCgwKBQQCAgEBEgN/CBoKDAoFBAIC
AQMSA38dHgoMCgUEAgIBCBIDfx9HCg8KCAQCAgEInAgAEgN/IEYKiwIKBAQCAgISBIUBAk4a
/AEgT3B0aW9uYWwuIERldGVybWluZXMgYSB0aHJlc2hvbGQgZm9yIENQVSB1dGlsaXphdGlv
biBiZWZvcmUgc2NhbGluZyBiZWdpbnMuCiBBY2NlcHRlZCB2YWx1ZXMgYXJlIGJldHdlZW4g
YDAuMWAgYW5kIGAwLjkwYCAoaW5jbHVzaXZlKSBvciBgMC4wYCB0bwogZGlzYWJsZSBDUFUg
dXRpbGl6YXRpb24gYXMgdGhyZXNob2xkIGZvciBzY2FsaW5nLiBDUFUgYW5kIGNvbmN1cnJl
bmN5CiBzY2FsaW5nIGNhbm5vdCBib3RoIGJlIGRpc2FibGVkLgoKDQoFBAICAgQSBIUBAgoK
DQoFBAICAgUSBIUBCxAKDQoFBAICAgESBIUBESAKDQoFBAICAgMSBIUBIyQKDQoFBAICAggS
BIUBJU0KEAoIBAICAgicCAASBIUBJkwKnQIKBAQCAgMSBosBAowBLxqMAiBPcHRpb25hbC4g
RGV0ZXJtaW5lcyBhIHRocmVzaG9sZCBmb3IgY29uY3VycmVuY3kgdXRpbGl6YXRpb24gYmVm
b3JlIHNjYWxpbmcKIGJlZ2lucy4gQWNjZXB0ZWQgdmFsdWVzIGFyZSBiZXR3ZWVuIGAwLjFg
IGFuZCBgMC45NWAgKGluY2x1c2l2ZSkgb3IgYDAuMGAKIHRvIGRpc2FibGUgY29uY3VycmVu
Y3kgdXRpbGl6YXRpb24gYXMgdGhyZXNob2xkIGZvciBzY2FsaW5nLiBDUFUgYW5kCiBjb25j
dXJyZW5jeSBzY2FsaW5nIGNhbm5vdCBib3RoIGJlIGRpc2FibGVkLgoKDQoFBAICAwQSBIsB
AgoKDQoFBAICAwUSBIsBCxAKDQoFBAICAwESBIsBESgKDQoFBAICAwMSBIsBKywKDQoFBAIC
AwgSBIwBBi4KEAoIBAICAwicCAASBIwBBy0KfwoCBAMSBpEBAJgBARpxIFNldHRpbmdzIGZv
ciBDbG91ZCBTZXJ2aWNlIE1lc2guIEZvciBtb3JlIGluZm9ybWF0aW9uIHNlZQogaHR0cHM6
Ly9jbG91ZC5nb29nbGUuY29tL3NlcnZpY2UtbWVzaC9kb2NzL292ZXJ2aWV3LgoKCwoDBAMB
EgSRAQgTCpgBCgQEAwIAEgaVAQKXAQUahwEgVGhlIE1lc2ggcmVzb3VyY2UgbmFtZS4gRm9y
bWF0OgogYHByb2plY3RzL3twcm9qZWN0fS9sb2NhdGlvbnMvZ2xvYmFsL21lc2hlcy97bWVz
aH1gLCB3aGVyZSBge3Byb2plY3R9YCBjYW4KIGJlIHByb2plY3QgaWQgb3IgbnVtYmVyLgoK
DQoFBAMCAAUSBJUBAggKDQoFBAMCAAESBJUBCQ0KDQoFBAMCAAMSBJUBEBEKDwoFBAMCAAgS
BpUBEpcBBAoRCgcEAwIACJ8IEgaVAROXAQMKPgoCBQASBpsBAKQBARowIFRoZSBhbWJpZW50
IG5ldHdvcmtpbmcgc2NvcGVzIG9mIHRoZSBpbnN0YW5jZS4KCgsKAwUAARIEmwEFEQocCgQF
AAIAEgSdAQIgGg4gVW5zcGVjaWZpZWQuCgoNCgUFAAIAARIEnQECGwoNCgUFAAIAAhIEnQEe
HwosCgQFAAIBEgSgAQIdGh4gUmVnaW9uYWwgYW1iaWVudCBuZXR3b3JraW5nLgoKDQoFBQAC
AQESBKABAhgKDQoFBQACAQISBKABGxwKKgoEBQACAhIEowECGxocIEdsb2JhbCBhbWJpZW50
IG5ldHdvcmtpbmcuCgoNCgUFAAICARIEowECFgoNCgUFAAICAhIEowEZGgo1CgIEBBIGpwEA
rQEBGicgQ29uZmlndXJhdGlvbiBmb3IgQW1iaWVudCBOZXR3b3JraW5nLgoKCwoDBAQBEgSn
AQgZCkAKBAQEAgASBKkBAkUaMiBPcHRpb25hbC4gV2hldGhlciBhbWJpZW50IG5ldHdvcmtp
bmcgaXMgZW5hYmxlZC4KCg0KBQQEAgAEEgSpAQIKCg0KBQQEAgAFEgSpAQsPCg0KBQQEAgAB
EgSpARAXCg0KBQQEAgADEgSpARobCg0KBQQEAgAIEgSpARxEChAKCAQEAgAInAgAEgSpAR1D
Cj0KBAQEAgESBKwBAiEaLyBUaGUgYW1iaWVudCBuZXR3b3JraW5nIHNjb3BlIG9mIHRoZSBp
bnN0YW5jZS4KCg0KBQQEAgEGEgSsAQIOCg0KBQQEAgEBEgSsAQ8cCg0KBQQEAgEDEgSsAR8g
CmEKAgQFEgaxAQDRAQEaUyBTY2FsaW5nIHNldHRpbmdzIGFwcGxpZWQgYXQgdGhlIHNlcnZp
Y2UgbGV2ZWwgcmF0aGVyIHRoYW4KIGF0IHRoZSByZXZpc2lvbiBsZXZlbC4KCgsKAwQFARIE
sQEIFgpfCgQEBQQAEga0AQK9AQMaTyBUaGUgc2NhbGluZyBtb2RlIGZvciB0aGUgc2Vydmlj
ZS4gSWYgbm90IHByb3ZpZGVkLCBpdCBkZWZhdWx0cyB0bwogQVVUT01BVElDLgoKDQoFBAUE
AAESBLQBBxIKHgoGBAUEAAIAEgS2AQQhGg4gVW5zcGVjaWZpZWQuCgoPCgcEBQQAAgABEgS2
AQQcCg8KBwQFBAACAAISBLYBHyAKRwoGBAUEAAIBEgS5AQQSGjcgU2NhbGUgYmFzZWQgb24g
dHJhZmZpYyBiZXR3ZWVuIG1pbiBhbmQgbWF4IGluc3RhbmNlcy4KCg8KBwQFBAACAQESBLkB
BA0KDwoHBAUEAAIBAhIEuQEQEQpKCgYEBQQAAgISBLwBBA8aOiBTY2FsZSB0byBleGFjdGx5
IG1pbiBpbnN0YW5jZXMgYW5kIGlnbm9yZSBtYXggaW5zdGFuY2VzLgoKDwoHBAUEAAICARIE
vAEECgoPCgcEBQQAAgICEgS8AQ0OCsQBCgQEBQIAEgTCAQJIGrUBIE9wdGlvbmFsLiB0b3Rh
bCBtaW4gaW5zdGFuY2VzIGZvciB0aGUgc2VydmljZS4gVGhpcyBudW1iZXIgb2YgaW5zdGFu
Y2VzIGlzCiBkaXZpZGVkIGFtb25nIGFsbCByZXZpc2lvbnMgd2l0aCBzcGVjaWZpZWQgdHJh
ZmZpYyBiYXNlZCBvbiB0aGUgcGVyY2VudAogb2YgdHJhZmZpYyB0aGV5IGFyZSByZWNlaXZp
bmcuCgoNCgUEBQIABRIEwgECBwoNCgUEBQIAARIEwgEIGgoNCgUEBQIAAxIEwgEdHgoNCgUE
BQIACBIEwgEfRwoQCggEBQIACJwIABIEwgEgRgo7CgQEBQIBEgTFAQJIGi0gT3B0aW9uYWwu
IFRoZSBzY2FsaW5nIG1vZGUgZm9yIHRoZSBzZXJ2aWNlLgoKDQoFBAUCAQYSBMUBAg0KDQoF
BAUCAQESBMUBDhoKDQoFBAUCAQMSBMUBHR4KDQoFBAUCAQgSBMUBH0cKEAoIBAUCAQicCAAS
BMUBIEYKxAEKBAQFAgISBMoBAkgatQEgT3B0aW9uYWwuIHRvdGFsIG1heCBpbnN0YW5jZXMg
Zm9yIHRoZSBzZXJ2aWNlLiBUaGlzIG51bWJlciBvZiBpbnN0YW5jZXMgaXMKIGRpdmlkZWQg
YW1vbmcgYWxsIHJldmlzaW9ucyB3aXRoIHNwZWNpZmllZCB0cmFmZmljIGJhc2VkIG9uIHRo
ZSBwZXJjZW50CiBvZiB0cmFmZmljIHRoZXkgYXJlIHJlY2VpdmluZy4KCg0KBQQFAgIFEgTK
AQIHCg0KBQQFAgIBEgTKAQgaCg0KBQQFAgIDEgTKAR0eCg0KBQQFAgIIEgTKAR9HChAKCAQF
AgIInAgAEgTKASBGCt4BCgQEBQIDEgbPAQLQAS8azQEgT3B0aW9uYWwuIHRvdGFsIGluc3Rh
bmNlIGNvdW50IGZvciB0aGUgc2VydmljZSBpbiBtYW51YWwgc2NhbGluZyBtb2RlLiBUaGlz
CiBudW1iZXIgb2YgaW5zdGFuY2VzIGlzIGRpdmlkZWQgYW1vbmcgYWxsIHJldmlzaW9ucyB3
aXRoIHNwZWNpZmllZCB0cmFmZmljCiBiYXNlZCBvbiB0aGUgcGVyY2VudCBvZiB0cmFmZmlj
IHRoZXkgYXJlIHJlY2VpdmluZy4KCg0KBQQFAgMEEgTPAQIKCg0KBQQFAgMFEgTPAQsQCg0K
BQQFAgMBEgTPAREmCg0KBQQFAgMDEgTPASkqCg0KBQQFAgMIEgTQAQYuChAKCAQFAgMInAgA
EgTQAQctCi0KAgQGEgbUAQDYAQEaHyBXb3JrZXIgcG9vbCBzY2FsaW5nIHNldHRpbmdzLgoK
CwoDBAYBEgTUAQgZClEKBAQGAgASBtYBAtcBLxpBIE9wdGlvbmFsLiBUaGUgdG90YWwgbnVt
YmVyIG9mIGluc3RhbmNlcyBpbiBtYW51YWwgc2NhbGluZyBtb2RlLgoKDQoFBAYCAAQSBNYB
AgoKDQoFBAYCAAUSBNYBCxAKDQoFBAYCAAESBNYBESYKDQoFBAYCAAMSBNYBKSoKDQoFBAYC
AAgSBNcBBi4KEAoIBAYCAAicCAASBNcBBy0KMwoCBAcSBtsBAN4BARolIEhhcmR3YXJlIGNv
bnN0cmFpbnRzIGNvbmZpZ3VyYXRpb24uCgoLCgMEBwESBNsBCBQKSAoEBAcCABIE3QECQho6
IFJlcXVpcmVkLiBHUFUgYWNjZWxlcmF0b3IgdHlwZSB0byBhdHRhY2ggdG8gYW4gaW5zdGFu
Y2UuCgoNCgUEBwIABRIE3QECCAoNCgUEBwIAARIE3QEJFAoNCgUEBwIAAxIE3QEXGAoNCgUE
BwIACBIE3QEZQQoQCggEBwIACJwIABIE3QEaQApoCgIECBIG4gEAlAIBGlogRGVzY3JpYmVz
IHRoZSBCdWlsZCBzdGVwIG9mIHRoZSBmdW5jdGlvbiB0aGF0IGJ1aWxkcyBhIGNvbnRhaW5l
ciBmcm9tIHRoZQogZ2l2ZW4gc291cmNlLgoKCwoDBAgBEgTiAQgTCmkKBAQIAgASBuUBAuoB
BBpZIE91dHB1dCBvbmx5LiBUaGUgQ2xvdWQgQnVpbGQgbmFtZSBvZiB0aGUgbGF0ZXN0IHN1
Y2Nlc3NmdWwgZGVwbG95bWVudCBvZgogdGhlIGZ1bmN0aW9uLgoKDQoFBAgCAAUSBOUBAggK
DQoFBAgCAAESBOUBCQ0KDQoFBAgCAAMSBOUBEBEKDwoFBAgCAAgSBuUBEuoBAwoQCggECAIA
CJwIABIE5gEELQoRCgcECAIACJ8IEgbnAQTpAQUKVwoEBAgCARIE7QECHRpJIFRoZSBDbG91
ZCBTdG9yYWdlIGJ1Y2tldCBVUkkgd2hlcmUgdGhlIGZ1bmN0aW9uIHNvdXJjZSBjb2RlIGlz
IGxvY2F0ZWQuCgoNCgUECAIBBRIE7QECCAoNCgUECAIBARIE7QEJGAoNCgUECAIBAxIE7QEb
HAqiAgoEBAgCAhIE8wECRhqTAiBPcHRpb25hbC4gVGhlIG5hbWUgb2YgdGhlIGZ1bmN0aW9u
IChhcyBkZWZpbmVkIGluIHNvdXJjZSBjb2RlKSB0aGF0IHdpbGwgYmUKIGV4ZWN1dGVkLiBE
ZWZhdWx0cyB0byB0aGUgcmVzb3VyY2UgbmFtZSBzdWZmaXgsIGlmIG5vdCBzcGVjaWZpZWQu
IEZvcgogYmFja3dhcmQgY29tcGF0aWJpbGl0eSwgaWYgZnVuY3Rpb24gd2l0aCBnaXZlbiBu
YW1lIGlzIG5vdCBmb3VuZCwgdGhlbiB0aGUKIHN5c3RlbSB3aWxsIHRyeSB0byB1c2UgZnVu
Y3Rpb24gbmFtZWQgImZ1bmN0aW9uIi4KCg0KBQQIAgIFEgTzAQIICg0KBQQIAgIBEgTzAQkY
Cg0KBQQIAgIDEgTzARscCg0KBQQIAgIIEgTzAR1FChAKCAQIAgIInAgAEgTzAR5ECkkKBAQI
AgMSBPYBAkAaOyBPcHRpb25hbC4gQXJ0aWZhY3QgUmVnaXN0cnkgVVJJIHRvIHN0b3JlIHRo
ZSBidWlsdCBpbWFnZS4KCg0KBQQIAgMFEgT2AQIICg0KBQQIAgMBEgT2AQkSCg0KBQQIAgMD
EgT2ARUWCg0KBQQIAgMIEgT2ARc/ChAKCAQIAgMInAgAEgT2ARg+CkQKBAQIAgQSBPkBAkEa
NiBPcHRpb25hbC4gVGhlIGJhc2UgaW1hZ2UgdXNlZCB0byBidWlsZCB0aGUgZnVuY3Rpb24u
CgoNCgUECAIEBRIE+QECCAoNCgUECAIEARIE+QEJEwoNCgUECAIEAxIE+QEWFwoNCgUECAIE
CBIE+QEYQAoQCggECAIECJwIABIE+QEZPwpfCgQECAIFEgT9AQJNGlEgT3B0aW9uYWwuIFNl
dHMgd2hldGhlciB0aGUgZnVuY3Rpb24gd2lsbCByZWNlaXZlIGF1dG9tYXRpYyBiYXNlIGlt
YWdlCiB1cGRhdGVzLgoKDQoFBAgCBQUSBP0BAgYKDQoFBAgCBQESBP0BBx8KDQoFBAgCBQMS
BP0BIiMKDQoFBAgCBQgSBP0BJEwKEAoIBAgCBQicCAASBP0BJUsK/gIKBAQIAgYSBoUCAooC
BBrtAiBPcHRpb25hbC4gTmFtZSBvZiB0aGUgQ2xvdWQgQnVpbGQgcHJpdmF0ZSBwb29sIHRo
YXQgc2hvdWxkIGJlIHVzZWQgdG8gYnVpbGQKIHRoZSBDbG91ZCBSdW4gZnVuY3Rpb24uIFRo
ZSBmb3JtYXQgb2YgdGhpcyBmaWVsZCBpcwogYHByb2plY3RzL3twcm9qZWN0fS9sb2NhdGlv
bnMve3JlZ2lvbn0vd29ya2VyUG9vbHMve3dvcmtlclBvb2x9YCB3aGVyZQogYHtwcm9qZWN0
fWAgYW5kIGB7cmVnaW9ufWAgYXJlIHRoZSBwcm9qZWN0IGlkIGFuZCByZWdpb24gcmVzcGVj
dGl2ZWx5IHdoZXJlCiB0aGUgd29ya2VyIHBvb2wgaXMgZGVmaW5lZCBhbmQgYHt3b3JrZXJQ
b29sfWAgaXMgdGhlIHNob3J0IG5hbWUgb2YgdGhlCiB3b3JrZXIgcG9vbC4KCg0KBQQIAgYF
EgSFAgIICg0KBQQIAgYBEgSFAgkUCg0KBQQIAgYDEgSFAhcYCg8KBQQIAgYIEgaFAhmKAgMK
EAoIBAgCBgicCAASBIYCBCoKEQoHBAgCBgifCBIGhwIEiQIFClsKBAQIAgcSBo0CAo4CLxpL
IE9wdGlvbmFsLiBVc2VyLXByb3ZpZGVkIGJ1aWxkLXRpbWUgZW52aXJvbm1lbnQgdmFyaWFi
bGVzIGZvciB0aGUgZnVuY3Rpb24KCg0KBQQIAgcGEgSNAgIVCg0KBQQIAgcBEgSNAhYrCg0K
BQQIAgcDEgSNAi4vCg0KBQQIAgcIEgSOAgYuChAKCAQIAgcInAgAEgSOAgctCq0BCgQECAII
EgSTAgJGGp4BIE9wdGlvbmFsLiBTZXJ2aWNlIGFjY291bnQgdG8gYmUgdXNlZCBmb3IgYnVp
bGRpbmcgdGhlIGNvbnRhaW5lci4gVGhlIGZvcm1hdAogb2YgdGhpcyBmaWVsZCBpcwogYHBy
b2plY3RzL3twcm9qZWN0SWR9L3NlcnZpY2VBY2NvdW50cy97c2VydmljZUFjY291bnRFbWFp
bH1gLgoKDQoFBAgCCAUSBJMCAggKDQoFBAgCCAESBJMCCRgKDQoFBAgCCAMSBJMCGxwKDQoF
BAgCCAgSBJMCHUUKEAoIBAgCCAicCAASBJMCHkQKOgoCBQESBpcCAKYCARosIEFsbG93ZWQg
aW5ncmVzcyB0cmFmZmljIGZvciB0aGUgQ29udGFpbmVyLgoKCwoDBQEBEgSXAgUTChsKBAUB
AgASBJkCAiIaDSBVbnNwZWNpZmllZAoKDQoFBQECAAESBJkCAh0KDQoFBQECAAISBJkCICEK
LwoEBQECARIEnAICGhohIEFsbCBpbmJvdW5kIHRyYWZmaWMgaXMgYWxsb3dlZC4KCg0KBQUB
AgEBEgScAgIVCg0KBQUBAgECEgScAhgZCjEKBAUBAgISBJ8CAiQaIyBPbmx5IGludGVybmFs
IHRyYWZmaWMgaXMgYWxsb3dlZC4KCg0KBQUBAgIBEgSfAgIfCg0KBQUBAgICEgSfAiIjClAK
BAUBAgMSBKICAi0aQiBCb3RoIGludGVybmFsIGFuZCBHb29nbGUgQ2xvdWQgTG9hZCBCYWxh
bmNlciB0cmFmZmljIGlzIGFsbG93ZWQuCgoNCgUFAQIDARIEogICKAoNCgUFAQIDAhIEogIr
LAouCgQFAQIEEgSlAgIbGiAgTm8gaW5ncmVzcyB0cmFmZmljIGlzIGFsbG93ZWQuCgoNCgUF
AQIEARIEpQICFgoNCgUFAQIEAhIEpQIZGgo4CgIFAhIGqQIAsgIBGiogQWx0ZXJuYXRpdmVz
IGZvciBleGVjdXRpb24gZW52aXJvbm1lbnRzLgoKCwoDBQIBEgSpAgUZChsKBAUCAgASBKsC
AigaDSBVbnNwZWNpZmllZAoKDQoFBQICAAESBKsCAiMKDQoFBQICAAISBKsCJicKNgoEBQIC
ARIErgICIRooIFVzZXMgdGhlIEZpcnN0IEdlbmVyYXRpb24gZW52aXJvbm1lbnQuCgoNCgUF
AgIBARIErgICHAoNCgUFAgIBAhIErgIfIAozCgQFAgICEgSxAgIhGiUgVXNlcyBTZWNvbmQg
R2VuZXJhdGlvbiBlbnZpcm9ubWVudC4KCg0KBQUCAgIBEgSxAgIcCg0KBQUCAgICEgSxAh8g
ClYKAgUDEga1AgC+AgEaSCBTcGVjaWZpZXMgYmVoYXZpb3IgaWYgYW4gZW5jcnlwdGlvbiBr
ZXkgdXNlZCBieSBhIHJlc291cmNlIGlzIHJldm9rZWQuCgoLCgMFAwESBLUCBSIKGwoEBQMC
ABIEtwICMxoNIFVuc3BlY2lmaWVkCgoNCgUFAwIAARIEtwICLgoNCgUFAwIAAhIEtwIxMgo3
CgQFAwIBEgS6AgISGikgUHJldmVudHMgdGhlIGNyZWF0aW9uIG9mIG5ldyBpbnN0YW5jZXMu
CgoNCgUFAwIBARIEugICDQoNCgUFAwIBAhIEugIQEQpRCgQFAwICEgS9AgIPGkMgU2h1dHMg
ZG93biBleGlzdGluZyBpbnN0YW5jZXMsIGFuZCBwcmV2ZW50cyBjcmVhdGlvbiBvZiBuZXcg
b25lcy4KCg0KBQUDAgIBEgS9AgIKCg0KBQUDAgICEgS9Ag0OCh4KAgUEEgbBAgDKAgEaECBJ
ZGVudGl0eSB0eXBlLgoKCwoDBQQBEgTBAgURChsKBAUEAgASBMMCAiAaDSBVbnNwZWNpZmll
ZAoKDQoFBQQCAAESBMMCAhsKDQoFBQQCAAISBMMCHh8KKQoEBQQCARIExgICJBobIFNlcnZp
Y2UgYWNjb3VudCBpZGVudGl0eS4KCg0KBQUEAgEBEgTGAgIfCg0KBQUEAgECEgTGAiIjCh8K
BAUEAgISBMkCAiMaESBBZ2VudCBpZGVudGl0eS4KCg0KBQUEAgIBEgTJAgIeCg0KBQUEAgIC
EgTJAiEiCisKAgQJEgbNAgDaAgEaHSBXb3JrbG9hZCBpZGVudGl0eSBzZXR0aW5ncy4KCgsK
AwQJARIEzQIIHgp5CgQECQIAEgTQAgI/GmsgT3B0aW9uYWwuIFRoZSBSZXZpc2lvbidzIFNQ
SUZGRSB3b3JrbG9hZCBpZGVudGl0eS4gRW5hYmxlcyBwcm92aXNpb25pbmcgb2YKIFNQSUZG
RSB3b3JrbG9hZCBjZXJ0aWZpY2F0ZXMuCgoNCgUECQIABRIE0AICCAoNCgUECQIAARIE0AIJ
EQoNCgUECQIAAxIE0AIUFQoNCgUECQIACBIE0AIWPgoQCggECQIACJwIABIE0AIXPQo2CgQE
CQIBEgTTAgJKGiggT3B0aW9uYWwuIFRoZSB0eXBlIG9mIGlkZW50aXR5IHRvIHVzZS4KCg0K
BQQJAgEGEgTTAgIOCg0KBQQJAgEBEgTTAg8cCg0KBQQJAgEDEgTTAh8gCg0KBQQJAgEIEgTT
AiFJChAKCAQJAgEInAgAEgTTAiJICqgBCgQECQICEgbYAgLZAi8alwEgT3B0aW9uYWwuIENv
bnRyb2xzIHdoZXRoZXIgYW4gaW5zdGFuY2UgcmVjZWl2ZXMgYSBNV0xJRCBjZXJ0aWZpY2F0
ZS4KIENvcnJlc3BvbmRzIHRvIHRoZSBpbnRlbnRpb24gb2YgdGhlIG9yaWdpbmFsIC0tW25v
LV1pZGVudGl0eS1jZXJ0aWZpY2F0ZQogZmxhZy4KCg0KBQQJAgIEEgTYAgIKCg0KBQQJAgIF
EgTYAgsPCg0KBQQJAgIBEgTYAhAsCg0KBQQJAgIDEgTYAi8wCg0KBQQJAgIIEgTZAgYuChAK
CAQJAgIInAgAEgTZAgctCi8KAgUFEgbdAgDmAgEaISBSZXByZXNlbnRzIHRoZSBmdW5jdGlv
bmFsIHR5cGUuCgoLCgMFBQESBN0CBRMKQgoEBQUCABIE3wICIho0IFNwZWNpZmllcyB0aGF0
IHRoZSBmdW5jdGlvbmFsIHR5cGUgaXMgdW5zcGVjaWZpZWQuCgoNCgUFBQIAARIE3wICHQoN
CgUFBQIAAhIE3wIgIQo0CgQFBQIBEgTiAgIcGiYgUmVwcmVzZW50cyBhbiBBR0VOVCBmdW5j
dGlvbmFsIHR5cGUuCgoNCgUFBQIBARIE4gICFwoNCgUFBQIBAhIE4gIaGwo5CgQFBQICEgTl
AgIhGisgUmVwcmVzZW50cyBhbiBNQ1BfU0VSVkVSIGZ1bmN0aW9uYWwgdHlwZS4KCg0KBQUF
AgIBEgTlAgIcCg0KBQUFAgICEgTlAh8gYgZwcm90bzM=
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Run::V2::VendorSettings::VpcAccess ===
    # Fields for VpcAccess
    # Field: connector Type: 9 ()
    # Field: egress Type: 14 (.google.cloud.run.v2.VpcAccess.VpcEgress)
    # Field: network_interfaces Type: 11 (.google.cloud.run.v2.VpcAccess.NetworkInterface)

# Enum: VpcAccess::VpcEgress
our $VpcAccess_VPC_EGRESS_UNSPECIFIED = 0;
our $VpcAccess_ALL_TRAFFIC = 1;
our $VpcAccess_PRIVATE_RANGES_ONLY = 2;

# === Message: Google::Cloud::Run::V2::VendorSettings::BinaryAuthorization ===
    # Fields for BinaryAuthorization
    # Field: use_default Type: 8 ()
    # Field: policy Type: 9 ()
    # Field: breakglass_justification Type: 9 ()

# === Message: Google::Cloud::Run::V2::VendorSettings::RevisionScaling ===
    # Fields for RevisionScaling
    # Field: min_instance_count Type: 5 ()
    # Field: max_instance_count Type: 5 ()
    # Field: cpu_utilization Type: 2 ()
    # Field: concurrency_utilization Type: 2 ()

# === Message: Google::Cloud::Run::V2::VendorSettings::ServiceMesh ===
    # Fields for ServiceMesh
    # Field: mesh Type: 9 ()

# === Message: Google::Cloud::Run::V2::VendorSettings::AmbientNetworking ===
    # Fields for AmbientNetworking
    # Field: enabled Type: 8 ()
    # Field: ambient_scope Type: 14 (.google.cloud.run.v2.AmbientScope)

# === Message: Google::Cloud::Run::V2::VendorSettings::ServiceScaling ===
    # Fields for ServiceScaling
    # Field: min_instance_count Type: 5 ()
    # Field: scaling_mode Type: 14 (.google.cloud.run.v2.ServiceScaling.ScalingMode)
    # Field: max_instance_count Type: 5 ()
    # Field: manual_instance_count Type: 5 ()

# Enum: ServiceScaling::ScalingMode
our $ServiceScaling_SCALING_MODE_UNSPECIFIED = 0;
our $ServiceScaling_AUTOMATIC = 1;
our $ServiceScaling_MANUAL = 2;

# === Message: Google::Cloud::Run::V2::VendorSettings::WorkerPoolScaling ===
    # Fields for WorkerPoolScaling
    # Field: manual_instance_count Type: 5 ()

# === Message: Google::Cloud::Run::V2::VendorSettings::NodeSelector ===
    # Fields for NodeSelector
    # Field: accelerator Type: 9 ()

# === Message: Google::Cloud::Run::V2::VendorSettings::BuildConfig ===
    # Fields for BuildConfig
    # Field: name Type: 9 ()
    # Field: source_location Type: 9 ()
    # Field: function_target Type: 9 ()
    # Field: image_uri Type: 9 ()
    # Field: base_image Type: 9 ()
    # Field: enable_automatic_updates Type: 8 ()
    # Field: worker_pool Type: 9 ()
    # Field: environment_variables Type: 11 (.google.cloud.run.v2.BuildConfig.EnvironmentVariablesEntry)
    # Field: service_account Type: 9 ()

# === Message: Google::Cloud::Run::V2::VendorSettings::WorkloadIdentityConfig ===
    # Fields for WorkloadIdentityConfig
    # Field: identity Type: 9 ()
    # Field: identity_type Type: 14 (.google.cloud.run.v2.IdentityType)
    # Field: identity_certificate_enabled Type: 8 ()

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Run::V2::VendorSettings - Compiled Protocol Buffers messages for google/cloud/run/v2/vendor_settings.proto

=head1 SYNOPSIS

    use Google::Cloud::Run::V2::VendorSettings;

    my $msg = Google::Cloud::Run::V2::VendorSettings::VpcAccess->new({
        connector => $connector,
        egress => $egress,
        network_interfaces => $network_interfaces,
    });

    # Read or update a field
    my $val = $msg->connector();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Run::V2::VendorSettings::VpcAccess->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/run/v2/vendor_settings.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Run::V2::VendorSettings::VpcAccess

VPC Access settings. For more information on sending traffic to a VPC
network, visit https://cloud.google.com/run/docs/configuring/connecting-vpc.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->connector() >> / C<< $msg->connector($value) >>

Type: C<String>

VPC Access connector name.
Format: `projects/{project}/locations/{location}/connectors/{connector}`,
where `{project}` can be project id or number.
For more information on sending traffic to a VPC network via a connector,
visit https://cloud.google.com/run/docs/configuring/vpc-connectors.

=item * C<< $msg->egress() >> / C<< $msg->egress($value) >>

Type: C<Enum> (L<Google::Cloud::Run::V2::VpcAccess::VpcEgress>)

Optional. Traffic VPC egress settings. If not provided, it defaults to
PRIVATE_RANGES_ONLY.

=item * C<< $msg->network_interfaces() >> / C<< $msg->network_interfaces($value) >>

Type: C<Message> (L<Google::Cloud::Run::V2::VendorSettings::VpcAccess::NetworkInterface>)

Optional. Direct VPC egress settings. Currently only single network
interface is supported.

=back

=head3 Enum: VpcAccess::VpcEgress

=over 4

=item * C<VPC_EGRESS_UNSPECIFIED> => C<0>

=item * C<ALL_TRAFFIC> => C<1>

=item * C<PRIVATE_RANGES_ONLY> => C<2>

=back

=head2 Google::Cloud::Run::V2::VendorSettings::BinaryAuthorization

Settings for Binary Authorization feature.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->use_default() >> / C<< $msg->use_default($value) >>

Type: C<Bool>

Optional. If True, indicates to use the default project's binary
authorization policy. If False, binary authorization will be disabled.

=item * C<< $msg->policy() >> / C<< $msg->policy($value) >>

Type: C<String>

Optional. The path to a binary authorization policy.
Format: `projects/{project}/platforms/cloudRun/{policy-name}`

=item * C<< $msg->breakglass_justification() >> / C<< $msg->breakglass_justification($value) >>

Type: C<String>

Optional. If present, indicates to use Breakglass using this justification.
If use_default is False, then it must be empty.
For more information on breakglass, see
https://cloud.google.com/binary-authorization/docs/using-breakglass

=back

=head2 Google::Cloud::Run::V2::VendorSettings::RevisionScaling

Settings for revision-level scaling settings.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->min_instance_count() >> / C<< $msg->min_instance_count($value) >>

Type: C<Int32>

Optional. Minimum number of serving instances that this resource should
have.

=item * C<< $msg->max_instance_count() >> / C<< $msg->max_instance_count($value) >>

Type: C<Int32>

Optional. Maximum number of serving instances that this resource should
have. When unspecified, the field is set to the server default value of
100. For more information see
https://cloud.google.com/run/docs/configuring/max-instances

=item * C<< $msg->cpu_utilization() >> / C<< $msg->cpu_utilization($value) >>

Type: C<Float>

Optional. Determines a threshold for CPU utilization before scaling begins.
Accepted values are between `0.1` and `0.90` (inclusive) or `0.0` to
disable CPU utilization as threshold for scaling. CPU and concurrency
scaling cannot both be disabled.

=item * C<< $msg->concurrency_utilization() >> / C<< $msg->concurrency_utilization($value) >>

Type: C<Float>

Optional. Determines a threshold for concurrency utilization before scaling
begins. Accepted values are between `0.1` and `0.95` (inclusive) or `0.0`
to disable concurrency utilization as threshold for scaling. CPU and
concurrency scaling cannot both be disabled.

=back

=head2 Google::Cloud::Run::V2::VendorSettings::ServiceMesh

Settings for Cloud Service Mesh. For more information see
https://cloud.google.com/service-mesh/docs/overview.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->mesh() >> / C<< $msg->mesh($value) >>

Type: C<String>

The Mesh resource name. Format:
`projects/{project}/locations/global/meshes/{mesh}`, where `{project}` can
be project id or number.

=back

=head2 Google::Cloud::Run::V2::VendorSettings::AmbientNetworking

Configuration for Ambient Networking.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->enabled() >> / C<< $msg->enabled($value) >>

Type: C<Bool>

Optional. Whether ambient networking is enabled.

=item * C<< $msg->ambient_scope() >> / C<< $msg->ambient_scope($value) >>

Type: C<Enum> (L<Google::Cloud::Run::V2::AmbientScope>)

The ambient networking scope of the instance.

=back

=head2 Google::Cloud::Run::V2::VendorSettings::ServiceScaling

Scaling settings applied at the service level rather than
at the revision level.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->min_instance_count() >> / C<< $msg->min_instance_count($value) >>

Type: C<Int32>

Optional. total min instances for the service. This number of instances is
divided among all revisions with specified traffic based on the percent
of traffic they are receiving.

=item * C<< $msg->scaling_mode() >> / C<< $msg->scaling_mode($value) >>

Type: C<Enum> (L<Google::Cloud::Run::V2::ServiceScaling::ScalingMode>)

Optional. The scaling mode for the service.

=item * C<< $msg->max_instance_count() >> / C<< $msg->max_instance_count($value) >>

Type: C<Int32>

Optional. total max instances for the service. This number of instances is
divided among all revisions with specified traffic based on the percent
of traffic they are receiving.

=item * C<< $msg->manual_instance_count() >> / C<< $msg->manual_instance_count($value) >>

Type: C<Int32>

Optional. total instance count for the service in manual scaling mode. This
number of instances is divided among all revisions with specified traffic
based on the percent of traffic they are receiving.

=back

=head3 Enum: ServiceScaling::ScalingMode

=over 4

=item * C<SCALING_MODE_UNSPECIFIED> => C<0>

=item * C<AUTOMATIC> => C<1>

=item * C<MANUAL> => C<2>

=back

=head2 Google::Cloud::Run::V2::VendorSettings::WorkerPoolScaling

Worker pool scaling settings.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->manual_instance_count() >> / C<< $msg->manual_instance_count($value) >>

Type: C<Int32>

Optional. The total number of instances in manual scaling mode.

=back

=head2 Google::Cloud::Run::V2::VendorSettings::NodeSelector

Hardware constraints configuration.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->accelerator() >> / C<< $msg->accelerator($value) >>

Type: C<String>

Required. GPU accelerator type to attach to an instance.

=back

=head2 Google::Cloud::Run::V2::VendorSettings::BuildConfig

Describes the Build step of the function that builds a container from the
given source.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Output only. The Cloud Build name of the latest successful deployment of
the function.

=item * C<< $msg->source_location() >> / C<< $msg->source_location($value) >>

Type: C<String>

The Cloud Storage bucket URI where the function source code is located.

=item * C<< $msg->function_target() >> / C<< $msg->function_target($value) >>

Type: C<String>

Optional. The name of the function (as defined in source code) that will be
executed. Defaults to the resource name suffix, if not specified. For
backward compatibility, if function with given name is not found, then the
system will try to use function named "function".

=item * C<< $msg->image_uri() >> / C<< $msg->image_uri($value) >>

Type: C<String>

Optional. Artifact Registry URI to store the built image.

=item * C<< $msg->base_image() >> / C<< $msg->base_image($value) >>

Type: C<String>

Optional. The base image used to build the function.

=item * C<< $msg->enable_automatic_updates() >> / C<< $msg->enable_automatic_updates($value) >>

Type: C<Bool>

Optional. Sets whether the function will receive automatic base image
updates.

=item * C<< $msg->worker_pool() >> / C<< $msg->worker_pool($value) >>

Type: C<String>

Optional. Name of the Cloud Build private pool that should be used to build
the Cloud Run function. The format of this field is
`projects/{project}/locations/{region}/workerPools/{workerPool}` where
`{project}` and `{region}` are the project id and region respectively where
the worker pool is defined and `{workerPool}` is the short name of the
worker pool.

=item * C<< $msg->environment_variables() >> / C<< $msg->environment_variables($value) >>

Type: C<Message> (L<Google::Cloud::Run::V2::VendorSettings::BuildConfig::EnvironmentVariablesEntry>)

Optional. User-provided build-time environment variables for the function

=item * C<< $msg->service_account() >> / C<< $msg->service_account($value) >>

Type: C<String>

Optional. Service account to be used for building the container. The format
of this field is
`projects/{projectId}/serviceAccounts/{serviceAccountEmail}`.

=back

=head2 Google::Cloud::Run::V2::VendorSettings::WorkloadIdentityConfig

Workload identity settings.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->identity() >> / C<< $msg->identity($value) >>

Type: C<String>

Optional. The Revision's SPIFFE workload identity. Enables provisioning of
SPIFFE workload certificates.

=item * C<< $msg->identity_type() >> / C<< $msg->identity_type($value) >>

Type: C<Enum> (L<Google::Cloud::Run::V2::IdentityType>)

Optional. The type of identity to use.

=item * C<< $msg->identity_certificate_enabled() >> / C<< $msg->identity_certificate_enabled($value) >>

Type: C<Bool>

Optional. Controls whether an instance receives a MWLID certificate.
Corresponds to the intention of the original --[no-]identity-certificate
flag.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Run::V2::VendorSettings::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
