package Google::Cloud::Osconfig::Agentendpoint::V1beta::PatchJobs;

use strict;
use warnings;

our $VERSION = '0.14';

use Protobuf::Message;
use Protobuf::DescriptorPool;
use Protobuf::Internal qw(:all);
use MIME::Base64;

BEGIN {
    my $descriptor_b64 = <<'EOF';
Cjtnb29nbGUvY2xvdWQvb3Njb25maWcvYWdlbnRlbmRwb2ludC92MWJldGEvcGF0Y2hfam9i
cy5wcm90bxIqZ29vZ2xlLmNsb3VkLm9zY29uZmlnLmFnZW50ZW5kcG9pbnQudjFiZXRhIqQH
CgtQYXRjaENvbmZpZxJpCg1yZWJvb3RfY29uZmlnGAEgASgOMkQuZ29vZ2xlLmNsb3VkLm9z
Y29uZmlnLmFnZW50ZW5kcG9pbnQudjFiZXRhLlBhdGNoQ29uZmlnLlJlYm9vdENvbmZpZ1IM
cmVib290Q29uZmlnEmAKDnJldHJ5X3N0cmF0ZWd5GAIgASgLMjkuZ29vZ2xlLmNsb3VkLm9z
Y29uZmlnLmFnZW50ZW5kcG9pbnQudjFiZXRhLlJldHJ5U3RyYXRlZ3lSDXJldHJ5U3RyYXRl
Z3kSSQoDYXB0GAMgASgLMjcuZ29vZ2xlLmNsb3VkLm9zY29uZmlnLmFnZW50ZW5kcG9pbnQu
djFiZXRhLkFwdFNldHRpbmdzUgNhcHQSSQoDeXVtGAQgASgLMjcuZ29vZ2xlLmNsb3VkLm9z
Y29uZmlnLmFnZW50ZW5kcG9pbnQudjFiZXRhLll1bVNldHRpbmdzUgN5dW0SSQoDZ29vGAUg
ASgLMjcuZ29vZ2xlLmNsb3VkLm9zY29uZmlnLmFnZW50ZW5kcG9pbnQudjFiZXRhLkdvb1Nl
dHRpbmdzUgNnb28SUgoGenlwcGVyGAYgASgLMjouZ29vZ2xlLmNsb3VkLm9zY29uZmlnLmFn
ZW50ZW5kcG9pbnQudjFiZXRhLlp5cHBlclNldHRpbmdzUgZ6eXBwZXISaAoOd2luZG93c191
cGRhdGUYByABKAsyQS5nb29nbGUuY2xvdWQub3Njb25maWcuYWdlbnRlbmRwb2ludC52MWJl
dGEuV2luZG93c1VwZGF0ZVNldHRpbmdzUg13aW5kb3dzVXBkYXRlEk8KCHByZV9zdGVwGAgg
ASgLMjQuZ29vZ2xlLmNsb3VkLm9zY29uZmlnLmFnZW50ZW5kcG9pbnQudjFiZXRhLkV4ZWNT
dGVwUgdwcmVTdGVwElEKCXBvc3Rfc3RlcBgJIAEoCzI0Lmdvb2dsZS5jbG91ZC5vc2NvbmZp
Zy5hZ2VudGVuZHBvaW50LnYxYmV0YS5FeGVjU3RlcFIIcG9zdFN0ZXASMgoVbWlnX2luc3Rh
bmNlc19hbGxvd2VkGAogASgIUhNtaWdJbnN0YW5jZXNBbGxvd2VkIlEKDFJlYm9vdENvbmZp
ZxIdChlSRUJPT1RfQ09ORklHX1VOU1BFQ0lGSUVEEAASCwoHREVGQVVMVBABEgoKBkFMV0FZ
UxACEgkKBU5FVkVSEAMi3wEKC0FwdFNldHRpbmdzElAKBHR5cGUYASABKA4yPC5nb29nbGUu
Y2xvdWQub3Njb25maWcuYWdlbnRlbmRwb2ludC52MWJldGEuQXB0U2V0dGluZ3MuVHlwZVIE
dHlwZRIaCghleGNsdWRlcxgCIAMoCVIIZXhjbHVkZXMSLQoSZXhjbHVzaXZlX3BhY2thZ2Vz
GAMgAygJUhFleGNsdXNpdmVQYWNrYWdlcyIzCgRUeXBlEhQKEFRZUEVfVU5TUEVDSUZJRUQQ
ABIICgRESVNUEAESCwoHVVBHUkFERRACIo4BCgtZdW1TZXR0aW5ncxIaCghzZWN1cml0eRgB
IAEoCFIIc2VjdXJpdHkSGAoHbWluaW1hbBgCIAEoCFIHbWluaW1hbBIaCghleGNsdWRlcxgD
IAMoCVIIZXhjbHVkZXMSLQoSZXhjbHVzaXZlX3BhY2thZ2VzGAQgAygJUhFleGNsdXNpdmVQ
YWNrYWdlcyINCgtHb29TZXR0aW5ncyLfAQoOWnlwcGVyU2V0dGluZ3MSIwoNd2l0aF9vcHRp
b25hbBgBIAEoCFIMd2l0aE9wdGlvbmFsEh8KC3dpdGhfdXBkYXRlGAIgASgIUgp3aXRoVXBk
YXRlEh4KCmNhdGVnb3JpZXMYAyADKAlSCmNhdGVnb3JpZXMSHgoKc2V2ZXJpdGllcxgEIAMo
CVIKc2V2ZXJpdGllcxIaCghleGNsdWRlcxgFIAMoCVIIZXhjbHVkZXMSKwoRZXhjbHVzaXZl
X3BhdGNoZXMYBiADKAlSEGV4Y2x1c2l2ZVBhdGNoZXMilAMKFVdpbmRvd3NVcGRhdGVTZXR0
aW5ncxJ6Cg9jbGFzc2lmaWNhdGlvbnMYASADKA4yUC5nb29nbGUuY2xvdWQub3Njb25maWcu
YWdlbnRlbmRwb2ludC52MWJldGEuV2luZG93c1VwZGF0ZVNldHRpbmdzLkNsYXNzaWZpY2F0
aW9uUg9jbGFzc2lmaWNhdGlvbnMSGgoIZXhjbHVkZXMYAiADKAlSCGV4Y2x1ZGVzEisKEWV4
Y2x1c2l2ZV9wYXRjaGVzGAMgAygJUhBleGNsdXNpdmVQYXRjaGVzIrUBCg5DbGFzc2lmaWNh
dGlvbhIeChpDTEFTU0lGSUNBVElPTl9VTlNQRUNJRklFRBAAEgwKCENSSVRJQ0FMEAESDAoI
U0VDVVJJVFkQAhIOCgpERUZJTklUSU9OEAMSCgoGRFJJVkVSEAQSEAoMRkVBVFVSRV9QQUNL
EAUSEAoMU0VSVklDRV9QQUNLEAYSCAoEVE9PTBAHEhEKDVVQREFURV9ST0xMVVAQCBIKCgZV
UERBVEUQCSIpCg1SZXRyeVN0cmF0ZWd5EhgKB2VuYWJsZWQYASABKAhSB2VuYWJsZWQi8AEK
CEV4ZWNTdGVwEm8KFmxpbnV4X2V4ZWNfc3RlcF9jb25maWcYASABKAsyOi5nb29nbGUuY2xv
dWQub3Njb25maWcuYWdlbnRlbmRwb2ludC52MWJldGEuRXhlY1N0ZXBDb25maWdSE2xpbnV4
RXhlY1N0ZXBDb25maWcScwoYd2luZG93c19leGVjX3N0ZXBfY29uZmlnGAIgASgLMjouZ29v
Z2xlLmNsb3VkLm9zY29uZmlnLmFnZW50ZW5kcG9pbnQudjFiZXRhLkV4ZWNTdGVwQ29uZmln
UhV3aW5kb3dzRXhlY1N0ZXBDb25maWcihgMKDkV4ZWNTdGVwQ29uZmlnEh8KCmxvY2FsX3Bh
dGgYASABKAlIAFIJbG9jYWxQYXRoElYKCmdjc19vYmplY3QYAiABKAsyNS5nb29nbGUuY2xv
dWQub3Njb25maWcuYWdlbnRlbmRwb2ludC52MWJldGEuR2NzT2JqZWN0SABSCWdjc09iamVj
dBIyChVhbGxvd2VkX3N1Y2Nlc3NfY29kZXMYAyADKAVSE2FsbG93ZWRTdWNjZXNzQ29kZXMS
aAoLaW50ZXJwcmV0ZXIYBCABKA4yRi5nb29nbGUuY2xvdWQub3Njb25maWcuYWdlbnRlbmRw
b2ludC52MWJldGEuRXhlY1N0ZXBDb25maWcuSW50ZXJwcmV0ZXJSC2ludGVycHJldGVyIk8K
C0ludGVycHJldGVyEhsKF0lOVEVSUFJFVEVSX1VOU1BFQ0lGSUVEEAASCAoETk9ORRADEgkK
BVNIRUxMEAESDgoKUE9XRVJTSEVMTBACQgwKCmV4ZWN1dGFibGUiaAoJR2NzT2JqZWN0EhYK
BmJ1Y2tldBgBIAEoCVIGYnVja2V0EhYKBm9iamVjdBgCIAEoCVIGb2JqZWN0EisKEWdlbmVy
YXRpb25fbnVtYmVyGAMgASgDUhBnZW5lcmF0aW9uTnVtYmVyQrABCi5jb20uZ29vZ2xlLmNs
b3VkLm9zY29uZmlnLmFnZW50ZW5kcG9pbnQudjFiZXRhQglQYXRjaEpvYnNaVGNsb3VkLmdv
b2dsZS5jb20vZ28vb3Njb25maWcvYWdlbnRlbmRwb2ludC9hcGl2MWJldGEvYWdlbnRlbmRw
b2ludHBiO2FnZW50ZW5kcG9pbnRwYsoCHEdvb2dsZVxDbG91ZFxPc0NvbmZpZ1xWMWJldGFK
11kKBxIFDgCnAgEKvAQKAQwSAw4AEjKxBCBDb3B5cmlnaHQgMjAyNSBHb29nbGUgTExDCgog
TGljZW5zZWQgdW5kZXIgdGhlIEFwYWNoZSBMaWNlbnNlLCBWZXJzaW9uIDIuMCAodGhlICJM
aWNlbnNlIik7CiB5b3UgbWF5IG5vdCB1c2UgdGhpcyBmaWxlIGV4Y2VwdCBpbiBjb21wbGlh
bmNlIHdpdGggdGhlIExpY2Vuc2UuCiBZb3UgbWF5IG9idGFpbiBhIGNvcHkgb2YgdGhlIExp
Y2Vuc2UgYXQKCiAgICAgaHR0cDovL3d3dy5hcGFjaGUub3JnL2xpY2Vuc2VzL0xJQ0VOU0Ut
Mi4wCgogVW5sZXNzIHJlcXVpcmVkIGJ5IGFwcGxpY2FibGUgbGF3IG9yIGFncmVlZCB0byBp
biB3cml0aW5nLCBzb2Z0d2FyZQogZGlzdHJpYnV0ZWQgdW5kZXIgdGhlIExpY2Vuc2UgaXMg
ZGlzdHJpYnV0ZWQgb24gYW4gIkFTIElTIiBCQVNJUywKIFdJVEhPVVQgV0FSUkFOVElFUyBP
UiBDT05ESVRJT05TIE9GIEFOWSBLSU5ELCBlaXRoZXIgZXhwcmVzcyBvciBpbXBsaWVkLgog
U2VlIHRoZSBMaWNlbnNlIGZvciB0aGUgc3BlY2lmaWMgbGFuZ3VhZ2UgZ292ZXJuaW5nIHBl
cm1pc3Npb25zIGFuZAogbGltaXRhdGlvbnMgdW5kZXIgdGhlIExpY2Vuc2UuCgoICgECEgMQ
ADMKCAoBCBIDEwBrCgkKAggLEgMTAGsKCAoBCBIDFAAqCgkKAggIEgMUACoKCAoBCBIDFQBH
CgkKAggBEgMVAEcKCAoBCBIDFgA5CgkKAggpEgMWADkKbQoCBAASBBoATAEaYSBQYXRjaCBj
b25maWd1cmF0aW9uIHNwZWNpZmljYXRpb25zLiBDb250YWlucyBkZXRhaWxzIG9uIGhvdyB0
bwogYXBwbHkgcGF0Y2hlcyB0byBhIFZNIGluc3RhbmNlLgoKCgoDBAABEgMaCBMKKwoEBAAE
ABIEHAIrAxodIFBvc3QtcGF0Y2ggcmVib290IHNldHRpbmdzLgoKDAoFBAAEAAESAxwHEwox
CgYEAAQAAgASAx4EIhoiIFRoZSBkZWZhdWx0IGJlaGF2aW9yIGlzIERFRkFVTFQuCgoOCgcE
AAQAAgABEgMeBB0KDgoHBAAEAAIAAhIDHiAhCo0CCgYEAAQAAgESAyQEEBr9ASBUaGUgYWdl
bnQgZGVjaWRlcyBpZiBhIHJlYm9vdCBpcyBuZWNlc3NhcnkgYnkgY2hlY2tpbmcKIHNpZ25h
bHMgc3VjaCBhcyByZWdpc3RyeSBrZXlzIG9uIFdpbmRvd3Mgb3IgYC92YXIvcnVuL3JlYm9v
dC1yZXF1aXJlZGAgb24KIEFQVCBiYXNlZCBzeXN0ZW1zLiBPbiBSUE0gYmFzZWQgc3lzdGVt
cywgYSBzZXQgb2YgY29yZSBzeXN0ZW0gcGFja2FnZQogaW5zdGFsbCB0aW1lcyBhcmUgY29t
cGFyZWQgd2l0aCBzeXN0ZW0gYm9vdCB0aW1lLgoKDgoHBAAEAAIBARIDJAQLCg4KBwQABAAC
AQISAyQODwpGCgYEAAQAAgISAycEDxo3IEFsd2F5cyByZWJvb3QgdGhlIG1hY2hpbmUgYWZ0
ZXIgdGhlIHVwZGF0ZSBjb21wbGV0ZXMuCgoOCgcEAAQAAgIBEgMnBAoKDgoHBAAEAAICAhID
Jw0OCkUKBgQABAACAxIDKgQOGjYgTmV2ZXIgcmVib290IHRoZSBtYWNoaW5lIGFmdGVyIHRo
ZSB1cGRhdGUgY29tcGxldGVzLgoKDgoHBAAEAAIDARIDKgQJCg4KBwQABAACAwISAyoMDQoq
CgQEAAIAEgMuAiEaHSBQb3N0LXBhdGNoIHJlYm9vdCBzZXR0aW5ncy4KCgwKBQQAAgAGEgMu
Ag4KDAoFBAACAAESAy4PHAoMCgUEAAIAAxIDLh8gCrABCgQEAAIBEgMzAiMaogEgUmV0cnkg
c3RyYXRlZ3kgY2FuIGJlIGRlZmluZWQgdG8gaGF2ZSB0aGUgYWdlbnQgcmV0cnkgcGF0Y2hp
bmcKIGR1cmluZyB0aGUgd2luZG93IGlmIHBhdGNoaW5nIGZhaWxzLiBJZiBvbWl0dGVkLCB0
aGUgYWdlbnQgd2lsbCB1c2UgaXRzCiBkZWZhdWx0IHJldHJ5IHN0cmF0ZWd5LgoKDAoFBAAC
AQYSAzMCDwoMCgUEAAIBARIDMxAeCgwKBQQAAgEDEgMzISIKUgoEBAACAhIDNgIWGkUgQXB0
IHVwZGF0ZSBzZXR0aW5ncy4gVXNlIHRoaXMgb3ZlcnJpZGUgdGhlIGRlZmF1bHQgYXB0IHBh
dGNoIHJ1bGVzLgoKDAoFBAACAgYSAzYCDQoMCgUEAAICARIDNg4RCgwKBQQAAgIDEgM2FBUK
UgoEBAACAxIDOQIWGkUgWXVtIHVwZGF0ZSBzZXR0aW5ncy4gVXNlIHRoaXMgb3ZlcnJpZGUg
dGhlIGRlZmF1bHQgeXVtIHBhdGNoIHJ1bGVzLgoKDAoFBAACAwYSAzkCDQoMCgUEAAIDARID
OQ4RCgwKBQQAAgMDEgM5FBUKUgoEBAACBBIDPAIWGkUgR29vIHVwZGF0ZSBzZXR0aW5ncy4g
VXNlIHRoaXMgb3ZlcnJpZGUgdGhlIGRlZmF1bHQgZ29vIHBhdGNoIHJ1bGVzLgoKDAoFBAAC
BAYSAzwCDQoMCgUEAAIEARIDPA4RCgwKBQQAAgQDEgM8FBUKWAoEBAACBRIDPwIcGksgWnlw
cGVyIHVwZGF0ZSBzZXR0aW5ncy4gVXNlIHRoaXMgb3ZlcnJpZGUgdGhlIGRlZmF1bHQgenlw
cGVyIHBhdGNoIHJ1bGVzLgoKDAoFBAACBQYSAz8CEAoMCgUEAAIFARIDPxEXCgwKBQQAAgUD
EgM/GhsKWgoEBAACBhIDQgIrGk0gV2luZG93cyB1cGRhdGUgc2V0dGluZ3MuIFVzZSB0aGlz
IG92ZXJyaWRlIHRoZSBkZWZhdWx0IHdpbmRvd3MgcGF0Y2ggcnVsZXMuCgoMCgUEAAIGBhID
QgIXCgwKBQQAAgYBEgNCGCYKDAoFBAACBgMSA0IpKgo7CgQEAAIHEgNFAhgaLiBUaGUgRXhl
Y1N0ZXAgdG8gcnVuIGJlZm9yZSB0aGUgcGF0Y2ggdXBkYXRlLgoKDAoFBAACBwYSA0UCCgoM
CgUEAAIHARIDRQsTCgwKBQQAAgcDEgNFFhcKOgoEBAACCBIDSAIZGi0gVGhlIEV4ZWNTdGVw
IHRvIHJ1biBhZnRlciB0aGUgcGF0Y2ggdXBkYXRlLgoKDAoFBAACCAYSA0gCCgoMCgUEAAII
ARIDSAsUCgwKBQQAAggDEgNIFxgKTQoEBAACCRIDSwIiGkAgQWxsb3dzIHRoZSBwYXRjaCBq
b2IgdG8gcnVuIG9uIE1hbmFnZWQgaW5zdGFuY2UgZ3JvdXBzIChNSUdzKS4KCgwKBQQAAgkF
EgNLAgYKDAoFBAACCQESA0sHHAoMCgUEAAIJAxIDSx8hCp8BCgIEARIEUABpARqSASBBcHQg
cGF0Y2hpbmcgd2lsbCBiZSBwZXJmb3JtZWQgYnkgZXhlY3V0aW5nIGBhcHQtZ2V0IHVwZGF0
ZSAmJiBhcHQtZ2V0CiB1cGdyYWRlYC4gQWRkaXRpb25hbCBvcHRpb25zIGNhbiBiZSBzZXQg
dG8gY29udHJvbCBob3cgdGhpcyBpcyBleGVjdXRlZC4KCgoKAwQBARIDUAgTCh8KBAQBBAAS
BFICWwMaESBBcHQgcGF0Y2ggdHlwZS4KCgwKBQQBBAABEgNSBwsKNwoGBAEEAAIAEgNUBBka
KCBCeSBkZWZhdWx0LCB1cGdyYWRlIHdpbGwgYmUgcGVyZm9ybWVkLgoKDgoHBAEEAAIAARID
VAQUCg4KBwQBBAACAAISA1QXGAotCgYEAQQAAgESA1cEDRoeIFJ1bnMgYGFwdC1nZXQgZGlz
dC11cGdyYWRlYC4KCg4KBwQBBAACAQESA1cECAoOCgcEAQQAAgECEgNXCwwKKAoGBAEEAAIC
EgNaBBAaGSBSdW5zIGBhcHQtZ2V0IHVwZ3JhZGVgLgoKDgoHBAEEAAICARIDWgQLCg4KBwQB
BAACAgISA1oODwpyCgQEAQIAEgNfAhAaZSBCeSBjaGFuZ2luZyB0aGUgdHlwZSB0byBESVNU
LCB0aGUgcGF0Y2hpbmcgd2lsbCBiZSBwZXJmb3JtZWQKIHVzaW5nIGBhcHQtZ2V0IGRpc3Qt
dXBncmFkZWAgaW5zdGVhZC4KCgwKBQQBAgAGEgNfAgYKDAoFBAECAAESA18HCwoMCgUEAQIA
AxIDXw4PCjcKBAQBAgESA2ICHxoqIExpc3Qgb2YgcGFja2FnZXMgdG8gZXhjbHVkZSBmcm9t
IHVwZGF0ZS4KCgwKBQQBAgEEEgNiAgoKDAoFBAECAQUSA2ILEQoMCgUEAQIBARIDYhIaCgwK
BQQBAgEDEgNiHR4K9gEKBAQBAgISA2gCKRroASBBbiBleGNsdXNpdmUgbGlzdCBvZiBwYWNr
YWdlcyB0byBiZSB1cGRhdGVkLiBUaGVzZSBhcmUgdGhlIG9ubHkgcGFja2FnZXMKIHRoYXQg
d2lsbCBiZSB1cGRhdGVkLiBJZiB0aGVzZSBwYWNrYWdlcyBhcmUgbm90IGluc3RhbGxlZCwg
dGhleSB3aWxsIGJlCiBpZ25vcmVkLiBUaGlzIGZpZWxkIGNhbm5vdCBiZSBzcGVjaWZpZWQg
d2l0aCBhbnkgb3RoZXIgcGF0Y2ggY29uZmlndXJhdGlvbgogZmllbGRzLgoKDAoFBAECAgQS
A2gCCgoMCgUEAQICBRIDaAsRCgwKBQQBAgIBEgNoEiQKDAoFBAECAgMSA2gnKArGAQoCBAIS
BW8AgAEBGrgBIFl1bSBwYXRjaGluZyB3aWxsIGJlIHBlcmZvcm1lZCBieSBleGVjdXRpbmcg
YHl1bSB1cGRhdGVgLiBBZGRpdGlvbmFsIG9wdGlvbnMKIGNhbiBiZSBzZXQgdG8gY29udHJv
bCBob3cgdGhpcyBpcyBleGVjdXRlZC4KCiBOb3RlIHRoYXQgbm90IGFsbCBzZXR0aW5ncyBh
cmUgc3VwcG9ydGVkIG9uIGFsbCBwbGF0Zm9ybXMuCgoKCgMEAgESA28IEwpbCgQEAgIAEgNy
AhQaTiBBZGRzIHRoZSBgLS1zZWN1cml0eWAgZmxhZyB0byBgeXVtIHVwZGF0ZWAuIE5vdCBz
dXBwb3J0ZWQgb24KIGFsbCBwbGF0Zm9ybXMuCgoMCgUEAgIABRIDcgIGCgwKBQQCAgABEgNy
Bw8KDAoFBAICAAMSA3ISEwpECgQEAgIBEgN1AhMaNyBXaWxsIGNhdXNlIHBhdGNoIHRvIHJ1
biBgeXVtIHVwZGF0ZS1taW5pbWFsYCBpbnN0ZWFkLgoKDAoFBAICAQUSA3UCBgoMCgUEAgIB
ARIDdQcOCgwKBQQCAgEDEgN1ERIKewoEBAICAhIDeQIfGm4gTGlzdCBvZiBwYWNrYWdlcyB0
byBleGNsdWRlIGZyb20gdXBkYXRlLiBUaGVzZSBwYWNrYWdlcyB3aWxsIGJlIGV4Y2x1ZGVk
IGJ5CiB1c2luZyB0aGUgeXVtIGAtLWV4Y2x1ZGVgIGZsYWcuCgoMCgUEAgICBBIDeQIKCgwK
BQQCAgIFEgN5CxEKDAoFBAICAgESA3kSGgoMCgUEAgICAxIDeR0eCvgBCgQEAgIDEgN/Aika
6gEgQW4gZXhjbHVzaXZlIGxpc3Qgb2YgcGFja2FnZXMgdG8gYmUgdXBkYXRlZC4gVGhlc2Ug
YXJlIHRoZSBvbmx5IHBhY2thZ2VzCiB0aGF0IHdpbGwgYmUgdXBkYXRlZC4gSWYgdGhlc2Ug
cGFja2FnZXMgYXJlIG5vdCBpbnN0YWxsZWQsIHRoZXkgd2lsbCBiZQogaWdub3JlZC4gVGhp
cyBmaWVsZCBtdXN0IG5vdCBiZSBzcGVjaWZpZWQgd2l0aCBhbnkgb3RoZXIgcGF0Y2gKIGNv
bmZpZ3VyYXRpb24gZmllbGRzLgoKDAoFBAICAwQSA38CCgoMCgUEAgIDBRIDfwsRCgwKBQQC
AgMBEgN/EiQKDAoFBAICAwMSA38nKApICgIEAxIGgwEAhQEBGjogR29vZ2V0IHBhdGNoaW5n
IGlzIHBlcmZvcm1lZCBieSBydW5uaW5nIGBnb29nZXQgdXBkYXRlYC4KCgsKAwQDARIEgwEI
Ewp8CgIEBBIGiQEAnwEBGm4gWnlwcGVyIHBhdGNoaW5nIGlzIHBlcmZvcm1lZCBieSBydW5u
aW5nIGB6eXBwZXIgcGF0Y2hgLgogU2VlIGFsc28gaHR0cHM6Ly9lbi5vcGVuc3VzZS5vcmcv
U0RCOlp5cHBlcl9tYW51YWwuCgoLCgMEBAESBIkBCBYKQgoEBAQCABIEiwECGRo0IEFkZHMg
dGhlIGAtLXdpdGgtb3B0aW9uYWxgIGZsYWcgdG8gYHp5cHBlciBwYXRjaGAuCgoNCgUEBAIA
BRIEiwECBgoNCgUEBAIAARIEiwEHFAoNCgUEBAIAAxIEiwEXGApBCgQEBAIBEgSOAQIXGjMg
QWRkcyB0aGUgYC0td2l0aC11cGRhdGVgIGZsYWcsIHRvIGB6eXBwZXIgcGF0Y2hgLgoKDQoF
BAQCAQUSBI4BAgYKDQoFBAQCAQESBI4BBxIKDQoFBAQCAQMSBI4BFRYKegoEBAQCAhIEkgEC
IRpsIEluc3RhbGwgb25seSBwYXRjaGVzIHdpdGggdGhlc2UgY2F0ZWdvcmllcy4KIENvbW1v
biBjYXRlZ29yaWVzIGluY2x1ZGUgc2VjdXJpdHksIHJlY29tbWVuZGVkLCBhbmQgZmVhdHVy
ZS4KCg0KBQQEAgIEEgSSAQIKCg0KBQQEAgIFEgSSAQsRCg0KBQQEAgIBEgSSARIcCg0KBQQE
AgIDEgSSAR8gCn4KBAQEAgMSBJYBAiEacCBJbnN0YWxsIG9ubHkgcGF0Y2hlcyB3aXRoIHRo
ZXNlIHNldmVyaXRpZXMuCiBDb21tb24gc2V2ZXJpdGllcyBpbmNsdWRlIGNyaXRpY2FsLCBp
bXBvcnRhbnQsIG1vZGVyYXRlLCBhbmQgbG93LgoKDQoFBAQCAwQSBJYBAgoKDQoFBAQCAwUS
BJYBCxEKDQoFBAQCAwESBJYBEhwKDQoFBAQCAwMSBJYBHyAKNwoEBAQCBBIEmQECHxopIExp
c3Qgb2YgcGF0Y2hlcyB0byBleGNsdWRlIGZyb20gdXBkYXRlLgoKDQoFBAQCBAQSBJkBAgoK
DQoFBAQCBAUSBJkBCxEKDQoFBAQCBAESBJkBEhoKDQoFBAQCBAMSBJkBHR4K6AEKBAQEAgUS
BJ4BAiga2QEgQW4gZXhjbHVzaXZlIGxpc3Qgb2YgcGF0Y2hlcyB0byBiZSB1cGRhdGVkLiBU
aGVzZSBhcmUgdGhlIG9ubHkgcGF0Y2hlcwogdGhhdCB3aWxsIGJlIGluc3RhbGxlZCB1c2lu
ZyAnenlwcGVyIHBhdGNoIHBhdGNoOjxwYXRjaF9uYW1lPicgY29tbWFuZC4KIFRoaXMgZmll
bGQgbXVzdCBub3QgYmUgdXNlZCB3aXRoIGFueSBvdGhlciBwYXRjaCBjb25maWd1cmF0aW9u
IGZpZWxkcy4KCg0KBQQEAgUEEgSeAQIKCg0KBQQEAgUFEgSeAQsRCg0KBQQEAgUBEgSeARIj
Cg0KBQQEAgUDEgSeASYnCk0KAgQFEgaiAQDiAQEaPyBXaW5kb3dzIHBhdGNoaW5nIGlzIHBl
cmZvcm1lZCB1c2luZyB0aGUgV2luZG93cyBVcGRhdGUgQWdlbnQuCgoLCgMEBQESBKIBCB0K
xgEKBAQFBAASBqYBAtUBAxq1ASBNaWNyb3NvZnQgV2luZG93cyB1cGRhdGUgY2xhc3NpZmlj
YXRpb25zIGFzIGRlZmluZWQgaW4KIFsxXQogaHR0cHM6Ly9zdXBwb3J0Lm1pY3Jvc29mdC5j
b20vZW4tdXMvaGVscC84MjQ2ODQvZGVzY3JpcHRpb24tb2YtdGhlLXN0YW5kYXJkLXRlcm1p
bm9sb2d5LXRoYXQtaXMtdXNlZC10by1kZXNjcmliZS1taWNybwoKDQoFBAUEAAESBKYBBxUK
UwoGBAUEAAIAEgSoAQQjGkMgSW52YWxpZC4gSWYgY2xhc3NpZmljYXRpb25zIGFyZSBpbmNs
dWRlZCwgdGhleSBtdXN0IGJlIHNwZWNpZmllZC4KCg8KBwQFBAACAAESBKgBBB4KDwoHBAUE
AAIAAhIEqAEhIgp6CgYEBQQAAgESBKwBBBEaaiAiQSB3aWRlbHkgcmVsZWFzZWQgZml4IGZv
ciBhIHNwZWNpZmljIHByb2JsZW0gdGhhdCBhZGRyZXNzZXMgYSBjcml0aWNhbCwKIG5vbi1z
ZWN1cml0eS1yZWxhdGVkIGJ1Zy4iIFsxXQoKDwoHBAUEAAIBARIErAEEDAoPCgcEBQQAAgEC
EgSsAQ8QCo0CCgYEBQQAAgISBLIBBBEa/AEgIkEgd2lkZWx5IHJlbGVhc2VkIGZpeCBmb3Ig
YSBwcm9kdWN0LXNwZWNpZmljLCBzZWN1cml0eS1yZWxhdGVkCiB2dWxuZXJhYmlsaXR5LiBT
ZWN1cml0eSB2dWxuZXJhYmlsaXRpZXMgYXJlIHJhdGVkIGJ5IHRoZWlyIHNldmVyaXR5LiBU
aGUKIHNldmVyaXR5IHJhdGluZyBpcyBpbmRpY2F0ZWQgaW4gdGhlIE1pY3Jvc29mdCBzZWN1
cml0eSBidWxsZXRpbiBhcwogY3JpdGljYWwsIGltcG9ydGFudCwgbW9kZXJhdGUsIG9yIGxv
dy4iIFsxXQoKDwoHBAUEAAICARIEsgEEDAoPCgcEBQQAAgICEgSyAQ8QCpYCCgYEBQQAAgMS
BLgBBBMahQIgIkEgd2lkZWx5IHJlbGVhc2VkIGFuZCBmcmVxdWVudCBzb2Z0d2FyZSB1cGRh
dGUgdGhhdCBjb250YWlucyBhZGRpdGlvbnMKIHRvIGEgcHJvZHVjdOKAmXMgZGVmaW5pdGlv
biBkYXRhYmFzZS4gRGVmaW5pdGlvbiBkYXRhYmFzZXMgYXJlIG9mdGVuIHVzZWQKIHRvIGRl
dGVjdCBvYmplY3RzIHRoYXQgaGF2ZSBzcGVjaWZpYyBhdHRyaWJ1dGVzLCBzdWNoIGFzIG1h
bGljaW91cyBjb2RlLAogcGhpc2hpbmcgd2Vic2l0ZXMsIG9yIGp1bmsgbWFpbC4iIFsxXQoK
DwoHBAUEAAIDARIEuAEEDgoPCgcEBQQAAgMCEgS4ARESClAKBgQFBAACBBIEuwEEDxpAICJT
b2Z0d2FyZSB0aGF0IGNvbnRyb2xzIHRoZSBpbnB1dCBhbmQgb3V0cHV0IG9mIGEgZGV2aWNl
LiIgWzFdCgoPCgcEBQQAAgQBEgS7AQQKCg8KBwQFBAACBAISBLsBDQ4KuAEKBgQFBAACBRIE
wAEEFRqnASAiTmV3IHByb2R1Y3QgZnVuY3Rpb25hbGl0eSB0aGF0IGlzIGZpcnN0IGRpc3Ry
aWJ1dGVkIG91dHNpZGUgdGhlIGNvbnRleHQKIG9mIGEgcHJvZHVjdCByZWxlYXNlIGFuZCB0
aGF0IGlzIHR5cGljYWxseSBpbmNsdWRlZCBpbiB0aGUgbmV4dCBmdWxsCiBwcm9kdWN0IHJl
bGVhc2UuIiBbMV0KCg8KBwQFBAACBQESBMABBBAKDwoHBAUEAAIFAhIEwAETFAraAgoGBAUE
AAIGEgTHAQQVGskCICJBIHRlc3RlZCwgY3VtdWxhdGl2ZSBzZXQgb2YgYWxsIGhvdGZpeGVz
LCBzZWN1cml0eSB1cGRhdGVzLCBjcml0aWNhbAogdXBkYXRlcywgYW5kIHVwZGF0ZXMuIEFk
ZGl0aW9uYWxseSwgc2VydmljZSBwYWNrcyBtYXkgY29udGFpbiBhZGRpdGlvbmFsCiBmaXhl
cyBmb3IgcHJvYmxlbXMgdGhhdCBhcmUgZm91bmQgaW50ZXJuYWxseSBzaW5jZSB0aGUgcmVs
ZWFzZSBvZiB0aGUKIHByb2R1Y3QuIFNlcnZpY2UgcGFja3MgbXkgYWxzbyBjb250YWluIGEg
bGltaXRlZCBudW1iZXIgb2YKIGN1c3RvbWVyLXJlcXVlc3RlZCBkZXNpZ24gY2hhbmdlcyBv
ciBmZWF0dXJlcy4iIFsxXQoKDwoHBAUEAAIGARIExwEEEAoPCgcEBQQAAgYCEgTHARMUClgK
BgQFBAACBxIEygEEDRpIICJBIHV0aWxpdHkgb3IgZmVhdHVyZSB0aGF0IGhlbHBzIGNvbXBs
ZXRlIGEgdGFzayBvciBzZXQgb2YgdGFza3MuIiBbMV0KCg8KBwQFBAACBwESBMoBBAgKDwoH
BAUEAAIHAhIEygELDAqpAgoGBAUEAAIIEgTQAQQWGpgCICJBIHRlc3RlZCwgY3VtdWxhdGl2
ZSBzZXQgb2YgaG90Zml4ZXMsIHNlY3VyaXR5IHVwZGF0ZXMsIGNyaXRpY2FsCiB1cGRhdGVz
LCBhbmQgdXBkYXRlcyB0aGF0IGFyZSBwYWNrYWdlZCB0b2dldGhlciBmb3IgZWFzeSBkZXBs
b3ltZW50LiBBCiByb2xsdXAgZ2VuZXJhbGx5IHRhcmdldHMgYSBzcGVjaWZpYyBhcmVhLCBz
dWNoIGFzIHNlY3VyaXR5LCBvciBhCiBjb21wb25lbnQgb2YgYSBwcm9kdWN0LCBzdWNoIGFz
IEludGVybmV0IEluZm9ybWF0aW9uIFNlcnZpY2VzIChJSVMpLiIgWzFdCgoPCgcEBQQAAggB
EgTQAQQRCg8KBwQFBAACCAISBNABFBUKgwEKBgQFBAACCRIE1AEEDxpzICJBIHdpZGVseSBy
ZWxlYXNlZCBmaXggZm9yIGEgc3BlY2lmaWMgcHJvYmxlbS4gQW4gdXBkYXRlIGFkZHJlc3Nl
cyBhCiBub25jcml0aWNhbCwgbm9uLXNlY3VyaXR5LXJlbGF0ZWQgYnVnLiIgWzFdCgoPCgcE
BQQAAgkBEgTUAQQKCg8KBwQFBAACCQISBNQBDQ4KcwoEBAUCABIE2QECLhplIE9ubHkgYXBw
bHkgdXBkYXRlcyBvZiB0aGVzZSB3aW5kb3dzIHVwZGF0ZSBjbGFzc2lmaWNhdGlvbnMuIElm
IGVtcHR5LCBhbGwKIHVwZGF0ZXMgd2lsbCBiZSBhcHBsaWVkLgoKDQoFBAUCAAQSBNkBAgoK
DQoFBAUCAAYSBNkBCxkKDQoFBAUCAAESBNkBGikKDQoFBAUCAAMSBNkBLC0KMwoEBAUCARIE
3AECHxolIExpc3Qgb2YgS0JzIHRvIGV4Y2x1ZGUgZnJvbSB1cGRhdGUuCgoNCgUEBQIBBBIE
3AECCgoNCgUEBQIBBRIE3AELEQoNCgUEBQIBARIE3AESGgoNCgUEBQIBAxIE3AEdHgqoAQoE
BAUCAhIE4QECKBqZASBBbiBleGNsdXNpdmUgbGlzdCBvZiBrYnMgdG8gYmUgdXBkYXRlZC4g
VGhlc2UgYXJlIHRoZSBvbmx5IHBhdGNoZXMKIHRoYXQgd2lsbCBiZSB1cGRhdGVkLiBUaGlz
IGZpZWxkIG11c3Qgbm90IGJlIHVzZWQgd2l0aCBvdGhlcgogcGF0Y2ggY29uZmlndXJhdGlv
bnMuCgoNCgUEBQICBBIE4QECCgoNCgUEBQICBRIE4QELEQoNCgUEBQICARIE4QESIwoNCgUE
BQICAxIE4QEmJwpRCgIEBhIG5QEA6QEBGkMgVGhlIHN0cmF0ZWd5IGZvciByZXRyeWluZyBm
YWlsZWQgcGF0Y2hlcyBkdXJpbmcgdGhlIHBhdGNoIHdpbmRvdy4KCgsKAwQGARIE5QEIFQpe
CgQEBgIAEgToAQITGlAgSWYgdHJ1ZSwgdGhlIGFnZW50IHdpbGwgY29udGludWUgdG8gdHJ5
IGFuZCBwYXRjaCB1bnRpbCB0aGUgd2luZG93IGhhcwogZW5kZWQuCgoNCgUEBgIABRIE6AEC
BgoNCgUEBgIAARIE6AEHDgoNCgUEBgIAAxIE6AEREgo+CgIEBxIG7AEA8gEBGjAgQSBzdGVw
IHRoYXQgcnVucyBhbiBleGVjdXRhYmxlIGZvciBhIFBhdGNoSm9iLgoKCwoDBAcBEgTsAQgQ
Ck4KBAQHAgASBO4BAiwaQCBUaGUgRXhlY1N0ZXBDb25maWcgZm9yIGFsbCBMaW51eCBWTXMg
dGFyZ2V0ZWQgYnkgdGhlIFBhdGNoSm9iLgoKDQoFBAcCAAYSBO4BAhAKDQoFBAcCAAESBO4B
EScKDQoFBAcCAAMSBO4BKisKUAoEBAcCARIE8QECLhpCIFRoZSBFeGVjU3RlcENvbmZpZyBm
b3IgYWxsIFdpbmRvd3MgVk1zIHRhcmdldGVkIGJ5IHRoZSBQYXRjaEpvYi4KCg0KBQQHAgEG
EgTxAQIQCg0KBQQHAgEBEgTxAREpCg0KBQQHAgEDEgTxASwtCjYKAgQIEgb1AQCaAgEaKCBD
b21tb24gY29uZmlndXJhdGlvbnMgZm9yIGFuIEV4ZWNTdGVwLgoKCwoDBAgBEgT1AQgWCj0K
BAQIBAASBvcBAoYCAxotIFRoZSBpbnRlcnByZXRlciB1c2VkIHRvIGV4ZWN1dGUgdGhlIGEg
ZmlsZS4KCg0KBQQIBAABEgT3AQcSCkkKBgQIBAACABIE+QEEIBo5IERlcHJlY2F0ZWQsIGRl
ZmF1bHRzIHRvIE5PTkUgZm9yIGNvbXBhdGliaWxpdHkgcmVhc29ucy4KCg8KBwQIBAACAAES
BPkBBBsKDwoHBAgEAAIAAhIE+QEeHwqpAQoGBAgEAAIBEgT+AQQNGpgBIEludmFsaWQgZm9y
IGEgV2luZG93cyBFeGVjU3RlcENvbmZpZy4gRm9yIGEgTGludXggRXhlY1N0ZXBDb25maWcs
IHRoZQogaW50ZXJwcmV0ZXIgd2lsbCBiZSBwYXJzZWQgZnJvbSB0aGUgc2hlYmFuZyBsaW5l
IG9mIHRoZSBzY3JpcHQgaWYKIHVuc3BlY2lmaWVkLgoKDwoHBAgEAAIBARIE/gEECAoPCgcE
CAQAAgECEgT+AQsMCmIKBgQIBAACAhIEggIEDhpSIEluZGljYXRlcyB0aGF0IHRoZSBzY3Jp
cHQgd2lsbCBiZSBydW4gd2l0aCAvYmluL3NoIG9uIExpbnV4IGFuZCBjbWQKIG9uIHdpbmRv
d3MuCgoPCgcECAQAAgIBEgSCAgQJCg8KBwQIBAACAgISBIICDA0KRgoGBAgEAAIDEgSFAgQT
GjYgSW5kaWNhdGVzIHRoYXQgdGhlIGZpbGUgd2lsbCBiZSBydW4gd2l0aCBQb3dlclNoZWxs
LgoKDwoHBAgEAAIDARIEhQIEDgoPCgcECAQAAgMCEgSFAhESCi0KBAQICAASBokCAo8CAxod
IExvY2F0aW9uIG9mIHRoZSBleGVjdXRhYmxlLgoKDQoFBAgIAAESBIkCCBIKPQoEBAgCABIE
iwIEGhovIEFuIGFic29sdXRlIHBhdGggdG8gdGhlIGV4ZWN1dGFibGUgb24gdGhlIFZNLgoK
DQoFBAgCAAUSBIsCBAoKDQoFBAgCAAESBIsCCxUKDQoFBAgCAAMSBIsCGBkKNwoEBAgCARIE
jgIEHRopIEEgR0NTIG9iamVjdCBjb250YWluaW5nIHRoZSBleGVjdXRhYmxlLgoKDQoFBAgC
AQYSBI4CBA0KDQoFBAgCAQESBI4CDhgKDQoFBAgCAQMSBI4CGxwKdwoEBAgCAhIEkwICKxpp
IERlZmF1bHRzIHRvIFswXS4gQSBsaXN0IG9mIHBvc3NpYmxlIHJldHVybiB2YWx1ZXMgdGhh
dCB0aGUKIGV4ZWN1dGlvbiBjYW4gcmV0dXJuIHRvIGluZGljYXRlIGEgc3VjY2Vzcy4KCg0K
BQQIAgIEEgSTAgIKCg0KBQQIAgIFEgSTAgsQCg0KBQQIAgIBEgSTAhEmCg0KBQQIAgIDEgST
AikqCosCCgQECAIDEgSZAgIeGvwBIFRoZSBzY3JpcHQgaW50ZXJwcmV0ZXIgdG8gdXNlIHRv
IHJ1biB0aGUgc2NyaXB0LiBJZiBubyBpbnRlcnByZXRlciBpcwogc3BlY2lmaWVkIHRoZSBz
Y3JpcHQgd2lsbCBiZSBleGVjdXRlZCBkaXJlY3RseSwgd2hpY2ggd2lsbCBsaWtlbHkKIG9u
bHkgc3VjY2VlZCBmb3Igc2NyaXB0cyB3aXRoIHNoZWJhbmcgbGluZXMuCiBbV2lraXBlZGlh
IHNoZWJhbmddKGh0dHBzOi8vZW4ud2lraXBlZGlhLm9yZy93aWtpL1NoZWJhbmdfKFVuaXgp
KS4KCg0KBQQIAgMGEgSZAgINCg0KBQQIAgMBEgSZAg4ZCg0KBQQIAgMDEgSZAhwdCioKAgQJ
EgadAgCnAgEaHCBHQ1Mgb2JqZWN0IHJlcHJlc2VudGF0aW9uLgoKCwoDBAkBEgSdAggRCikK
BAQJAgASBJ8CAhQaGyBCdWNrZXQgb2YgdGhlIEdDUyBvYmplY3QuCgoNCgUECQIABRIEnwIC
CAoNCgUECQIAARIEnwIJDwoNCgUECQIAAxIEnwISEwonCgQECQIBEgSiAgIUGhkgTmFtZSBv
ZiB0aGUgR0NTIG9iamVjdC4KCg0KBQQJAgEFEgSiAgIICg0KBQQJAgEBEgSiAgkPCg0KBQQJ
AgEDEgSiAhITCooBCgQECQICEgSmAgIeGnwgR2VuZXJhdGlvbiBudW1iZXIgb2YgdGhlIEdD
UyBvYmplY3QuIFRoaXMgaXMgdXNlZCB0byBlbnN1cmUgdGhhdCB0aGUKIEV4ZWNTdGVwIHNw
ZWNpZmllZCBieSB0aGlzIFBhdGNoSm9iIGRvZXMgbm90IGNoYW5nZS4KCg0KBQQJAgIFEgSm
AgIHCg0KBQQJAgIBEgSmAggZCg0KBQQJAgIDEgSmAhwdYgZwcm90bzM=
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Osconfig::Agentendpoint::V1beta::PatchJobs::PatchConfig ===
    # Fields for PatchConfig
    # Field: reboot_config Type: 14 (.google.cloud.osconfig.agentendpoint.v1beta.PatchConfig.RebootConfig)
    # Field: retry_strategy Type: 11 (.google.cloud.osconfig.agentendpoint.v1beta.RetryStrategy)
    # Field: apt Type: 11 (.google.cloud.osconfig.agentendpoint.v1beta.AptSettings)
    # Field: yum Type: 11 (.google.cloud.osconfig.agentendpoint.v1beta.YumSettings)
    # Field: goo Type: 11 (.google.cloud.osconfig.agentendpoint.v1beta.GooSettings)
    # Field: zypper Type: 11 (.google.cloud.osconfig.agentendpoint.v1beta.ZypperSettings)
    # Field: windows_update Type: 11 (.google.cloud.osconfig.agentendpoint.v1beta.WindowsUpdateSettings)
    # Field: pre_step Type: 11 (.google.cloud.osconfig.agentendpoint.v1beta.ExecStep)
    # Field: post_step Type: 11 (.google.cloud.osconfig.agentendpoint.v1beta.ExecStep)
    # Field: mig_instances_allowed Type: 8 ()

# Enum: PatchConfig::RebootConfig
our $PatchConfig_REBOOT_CONFIG_UNSPECIFIED = 0;
our $PatchConfig_DEFAULT = 1;
our $PatchConfig_ALWAYS = 2;
our $PatchConfig_NEVER = 3;

# === Message: Google::Cloud::Osconfig::Agentendpoint::V1beta::PatchJobs::AptSettings ===
    # Fields for AptSettings
    # Field: type Type: 14 (.google.cloud.osconfig.agentendpoint.v1beta.AptSettings.Type)
    # Field: excludes Type: 9 ()
    # Field: exclusive_packages Type: 9 ()

# Enum: AptSettings::Type
our $AptSettings_TYPE_UNSPECIFIED = 0;
our $AptSettings_DIST = 1;
our $AptSettings_UPGRADE = 2;

# === Message: Google::Cloud::Osconfig::Agentendpoint::V1beta::PatchJobs::YumSettings ===
    # Fields for YumSettings
    # Field: security Type: 8 ()
    # Field: minimal Type: 8 ()
    # Field: excludes Type: 9 ()
    # Field: exclusive_packages Type: 9 ()

# === Message: Google::Cloud::Osconfig::Agentendpoint::V1beta::PatchJobs::GooSettings ===
    # Fields for GooSettings

# === Message: Google::Cloud::Osconfig::Agentendpoint::V1beta::PatchJobs::ZypperSettings ===
    # Fields for ZypperSettings
    # Field: with_optional Type: 8 ()
    # Field: with_update Type: 8 ()
    # Field: categories Type: 9 ()
    # Field: severities Type: 9 ()
    # Field: excludes Type: 9 ()
    # Field: exclusive_patches Type: 9 ()

# === Message: Google::Cloud::Osconfig::Agentendpoint::V1beta::PatchJobs::WindowsUpdateSettings ===
    # Fields for WindowsUpdateSettings
    # Field: classifications Type: 14 (.google.cloud.osconfig.agentendpoint.v1beta.WindowsUpdateSettings.Classification)
    # Field: excludes Type: 9 ()
    # Field: exclusive_patches Type: 9 ()

# Enum: WindowsUpdateSettings::Classification
our $WindowsUpdateSettings_CLASSIFICATION_UNSPECIFIED = 0;
our $WindowsUpdateSettings_CRITICAL = 1;
our $WindowsUpdateSettings_SECURITY = 2;
our $WindowsUpdateSettings_DEFINITION = 3;
our $WindowsUpdateSettings_DRIVER = 4;
our $WindowsUpdateSettings_FEATURE_PACK = 5;
our $WindowsUpdateSettings_SERVICE_PACK = 6;
our $WindowsUpdateSettings_TOOL = 7;
our $WindowsUpdateSettings_UPDATE_ROLLUP = 8;
our $WindowsUpdateSettings_UPDATE = 9;

# === Message: Google::Cloud::Osconfig::Agentendpoint::V1beta::PatchJobs::RetryStrategy ===
    # Fields for RetryStrategy
    # Field: enabled Type: 8 ()

# === Message: Google::Cloud::Osconfig::Agentendpoint::V1beta::PatchJobs::ExecStep ===
    # Fields for ExecStep
    # Field: linux_exec_step_config Type: 11 (.google.cloud.osconfig.agentendpoint.v1beta.ExecStepConfig)
    # Field: windows_exec_step_config Type: 11 (.google.cloud.osconfig.agentendpoint.v1beta.ExecStepConfig)

# === Message: Google::Cloud::Osconfig::Agentendpoint::V1beta::PatchJobs::ExecStepConfig ===
    # Fields for ExecStepConfig
    # Field: local_path Type: 9 ()
    # Field: gcs_object Type: 11 (.google.cloud.osconfig.agentendpoint.v1beta.GcsObject)
    # Field: allowed_success_codes Type: 5 ()
    # Field: interpreter Type: 14 (.google.cloud.osconfig.agentendpoint.v1beta.ExecStepConfig.Interpreter)

# Enum: ExecStepConfig::Interpreter
our $ExecStepConfig_INTERPRETER_UNSPECIFIED = 0;
our $ExecStepConfig_NONE = 3;
our $ExecStepConfig_SHELL = 1;
our $ExecStepConfig_POWERSHELL = 2;

# === Message: Google::Cloud::Osconfig::Agentendpoint::V1beta::PatchJobs::GcsObject ===
    # Fields for GcsObject
    # Field: bucket Type: 9 ()
    # Field: object Type: 9 ()
    # Field: generation_number Type: 3 ()

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Osconfig::Agentendpoint::V1beta::PatchJobs - Compiled Protocol Buffers messages for google/cloud/osconfig/agentendpoint/v1beta/patch_jobs.proto

=head1 SYNOPSIS

    use Google::Cloud::Osconfig::Agentendpoint::V1beta::PatchJobs;

    my $msg = Google::Cloud::Osconfig::Agentendpoint::V1beta::PatchJobs::PatchConfig->new({
        reboot_config => $reboot_config,
        retry_strategy => $retry_strategy,
        apt => $apt,
        yum => $yum,
    });

    # Read or update a field
    my $val = $msg->reboot_config();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Osconfig::Agentendpoint::V1beta::PatchJobs::PatchConfig->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/osconfig/agentendpoint/v1beta/patch_jobs.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Osconfig::Agentendpoint::V1beta::PatchJobs::PatchConfig

Patch configuration specifications. Contains details on how to
apply patches to a VM instance.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->reboot_config() >> / C<< $msg->reboot_config($value) >>

Type: C<Enum> (L<Google::Cloud::Osconfig::Agentendpoint::V1beta::PatchConfig::RebootConfig>)

Post-patch reboot settings.

=item * C<< $msg->retry_strategy() >> / C<< $msg->retry_strategy($value) >>

Type: C<Message> (L<Google::Cloud::Osconfig::Agentendpoint::V1beta::PatchJobs::RetryStrategy>)

Retry strategy can be defined to have the agent retry patching
during the window if patching fails. If omitted, the agent will use its
default retry strategy.

=item * C<< $msg->apt() >> / C<< $msg->apt($value) >>

Type: C<Message> (L<Google::Cloud::Osconfig::Agentendpoint::V1beta::PatchJobs::AptSettings>)

Apt update settings. Use this override the default apt patch rules.

=item * C<< $msg->yum() >> / C<< $msg->yum($value) >>

Type: C<Message> (L<Google::Cloud::Osconfig::Agentendpoint::V1beta::PatchJobs::YumSettings>)

Yum update settings. Use this override the default yum patch rules.

=item * C<< $msg->goo() >> / C<< $msg->goo($value) >>

Type: C<Message> (L<Google::Cloud::Osconfig::Agentendpoint::V1beta::PatchJobs::GooSettings>)

Goo update settings. Use this override the default goo patch rules.

=item * C<< $msg->zypper() >> / C<< $msg->zypper($value) >>

Type: C<Message> (L<Google::Cloud::Osconfig::Agentendpoint::V1beta::PatchJobs::ZypperSettings>)

Zypper update settings. Use this override the default zypper patch rules.

=item * C<< $msg->windows_update() >> / C<< $msg->windows_update($value) >>

Type: C<Message> (L<Google::Cloud::Osconfig::Agentendpoint::V1beta::PatchJobs::WindowsUpdateSettings>)

Windows update settings. Use this override the default windows patch rules.

=item * C<< $msg->pre_step() >> / C<< $msg->pre_step($value) >>

Type: C<Message> (L<Google::Cloud::Osconfig::Agentendpoint::V1beta::PatchJobs::ExecStep>)

The ExecStep to run before the patch update.

=item * C<< $msg->post_step() >> / C<< $msg->post_step($value) >>

Type: C<Message> (L<Google::Cloud::Osconfig::Agentendpoint::V1beta::PatchJobs::ExecStep>)

The ExecStep to run after the patch update.

=item * C<< $msg->mig_instances_allowed() >> / C<< $msg->mig_instances_allowed($value) >>

Type: C<Bool>

Allows the patch job to run on Managed instance groups (MIGs).

=back

=head3 Enum: PatchConfig::RebootConfig

=over 4

=item * C<REBOOT_CONFIG_UNSPECIFIED> => C<0>

=item * C<DEFAULT> => C<1>

=item * C<ALWAYS> => C<2>

=item * C<NEVER> => C<3>

=back

=head2 Google::Cloud::Osconfig::Agentendpoint::V1beta::PatchJobs::AptSettings

Apt patching will be performed by executing `apt-get update && apt-get
upgrade`. Additional options can be set to control how this is executed.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->type() >> / C<< $msg->type($value) >>

Type: C<Enum> (L<Google::Cloud::Osconfig::Agentendpoint::V1beta::AptSettings::Type>)

By changing the type to DIST, the patching will be performed
using `apt-get dist-upgrade` instead.

=item * C<< $msg->excludes() >> / C<< $msg->excludes($value) >>

Type: C<String>

List of packages to exclude from update.

=item * C<< $msg->exclusive_packages() >> / C<< $msg->exclusive_packages($value) >>

Type: C<String>

An exclusive list of packages to be updated. These are the only packages
that will be updated. If these packages are not installed, they will be
ignored. This field cannot be specified with any other patch configuration
fields.

=back

=head3 Enum: AptSettings::Type

=over 4

=item * C<TYPE_UNSPECIFIED> => C<0>

=item * C<DIST> => C<1>

=item * C<UPGRADE> => C<2>

=back

=head2 Google::Cloud::Osconfig::Agentendpoint::V1beta::PatchJobs::YumSettings

Yum patching will be performed by executing `yum update`. Additional options
can be set to control how this is executed.

Note that not all settings are supported on all platforms.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->security() >> / C<< $msg->security($value) >>

Type: C<Bool>

Adds the `--security` flag to `yum update`. Not supported on
all platforms.

=item * C<< $msg->minimal() >> / C<< $msg->minimal($value) >>

Type: C<Bool>

Will cause patch to run `yum update-minimal` instead.

=item * C<< $msg->excludes() >> / C<< $msg->excludes($value) >>

Type: C<String>

List of packages to exclude from update. These packages will be excluded by
using the yum `--exclude` flag.

=item * C<< $msg->exclusive_packages() >> / C<< $msg->exclusive_packages($value) >>

Type: C<String>

An exclusive list of packages to be updated. These are the only packages
that will be updated. If these packages are not installed, they will be
ignored. This field must not be specified with any other patch
configuration fields.

=back

=head2 Google::Cloud::Osconfig::Agentendpoint::V1beta::PatchJobs::GooSettings

Googet patching is performed by running `googet update`.

Inherits from L<Protobuf::Message>.

=head2 Google::Cloud::Osconfig::Agentendpoint::V1beta::PatchJobs::ZypperSettings

Zypper patching is performed by running `zypper patch`.
See also https://en.opensuse.org/SDB:Zypper_manual.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->with_optional() >> / C<< $msg->with_optional($value) >>

Type: C<Bool>

Adds the `--with-optional` flag to `zypper patch`.

=item * C<< $msg->with_update() >> / C<< $msg->with_update($value) >>

Type: C<Bool>

Adds the `--with-update` flag, to `zypper patch`.

=item * C<< $msg->categories() >> / C<< $msg->categories($value) >>

Type: C<String>

Install only patches with these categories.
Common categories include security, recommended, and feature.

=item * C<< $msg->severities() >> / C<< $msg->severities($value) >>

Type: C<String>

Install only patches with these severities.
Common severities include critical, important, moderate, and low.

=item * C<< $msg->excludes() >> / C<< $msg->excludes($value) >>

Type: C<String>

List of patches to exclude from update.

=item * C<< $msg->exclusive_patches() >> / C<< $msg->exclusive_patches($value) >>

Type: C<String>

An exclusive list of patches to be updated. These are the only patches
that will be installed using 'zypper patch patch:<patch_name>' command.
This field must not be used with any other patch configuration fields.

=back

=head2 Google::Cloud::Osconfig::Agentendpoint::V1beta::PatchJobs::WindowsUpdateSettings

Windows patching is performed using the Windows Update Agent.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->classifications() >> / C<< $msg->classifications($value) >>

Type: C<Enum> (L<Google::Cloud::Osconfig::Agentendpoint::V1beta::WindowsUpdateSettings::Classification>)

Only apply updates of these windows update classifications. If empty, all
updates will be applied.

=item * C<< $msg->excludes() >> / C<< $msg->excludes($value) >>

Type: C<String>

List of KBs to exclude from update.

=item * C<< $msg->exclusive_patches() >> / C<< $msg->exclusive_patches($value) >>

Type: C<String>

An exclusive list of kbs to be updated. These are the only patches
that will be updated. This field must not be used with other
patch configurations.

=back

=head3 Enum: WindowsUpdateSettings::Classification

=over 4

=item * C<CLASSIFICATION_UNSPECIFIED> => C<0>

=item * C<CRITICAL> => C<1>

=item * C<SECURITY> => C<2>

=item * C<DEFINITION> => C<3>

=item * C<DRIVER> => C<4>

=item * C<FEATURE_PACK> => C<5>

=item * C<SERVICE_PACK> => C<6>

=item * C<TOOL> => C<7>

=item * C<UPDATE_ROLLUP> => C<8>

=item * C<UPDATE> => C<9>

=back

=head2 Google::Cloud::Osconfig::Agentendpoint::V1beta::PatchJobs::RetryStrategy

The strategy for retrying failed patches during the patch window.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->enabled() >> / C<< $msg->enabled($value) >>

Type: C<Bool>

If true, the agent will continue to try and patch until the window has
ended.

=back

=head2 Google::Cloud::Osconfig::Agentendpoint::V1beta::PatchJobs::ExecStep

A step that runs an executable for a PatchJob.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->linux_exec_step_config() >> / C<< $msg->linux_exec_step_config($value) >>

Type: C<Message> (L<Google::Cloud::Osconfig::Agentendpoint::V1beta::PatchJobs::ExecStepConfig>)

The ExecStepConfig for all Linux VMs targeted by the PatchJob.

=item * C<< $msg->windows_exec_step_config() >> / C<< $msg->windows_exec_step_config($value) >>

Type: C<Message> (L<Google::Cloud::Osconfig::Agentendpoint::V1beta::PatchJobs::ExecStepConfig>)

The ExecStepConfig for all Windows VMs targeted by the PatchJob.

=back

=head2 Google::Cloud::Osconfig::Agentendpoint::V1beta::PatchJobs::ExecStepConfig

Common configurations for an ExecStep.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->local_path() >> / C<< $msg->local_path($value) >>

Type: C<String>

An absolute path to the executable on the VM.

=item * C<< $msg->gcs_object() >> / C<< $msg->gcs_object($value) >>

Type: C<Message> (L<Google::Cloud::Osconfig::Agentendpoint::V1beta::PatchJobs::GcsObject>)

A GCS object containing the executable.

=item * C<< $msg->allowed_success_codes() >> / C<< $msg->allowed_success_codes($value) >>

Type: C<Int32>

Defaults to [0]. A list of possible return values that the
execution can return to indicate a success.

=item * C<< $msg->interpreter() >> / C<< $msg->interpreter($value) >>

Type: C<Enum> (L<Google::Cloud::Osconfig::Agentendpoint::V1beta::ExecStepConfig::Interpreter>)

The script interpreter to use to run the script. If no interpreter is
specified the script will be executed directly, which will likely
only succeed for scripts with shebang lines.
[Wikipedia shebang](https://en.wikipedia.org/wiki/Shebang_(Unix)).

=back

=head3 Enum: ExecStepConfig::Interpreter

=over 4

=item * C<INTERPRETER_UNSPECIFIED> => C<0>

=item * C<NONE> => C<3>

=item * C<SHELL> => C<1>

=item * C<POWERSHELL> => C<2>

=back

=head2 Google::Cloud::Osconfig::Agentendpoint::V1beta::PatchJobs::GcsObject

GCS object representation.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->bucket() >> / C<< $msg->bucket($value) >>

Type: C<String>

Bucket of the GCS object.

=item * C<< $msg->object() >> / C<< $msg->object($value) >>

Type: C<String>

Name of the GCS object.

=item * C<< $msg->generation_number() >> / C<< $msg->generation_number($value) >>

Type: C<Int64>

Generation number of the GCS object. This is used to ensure that the
ExecStep specified by this PatchJob does not change.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Osconfig::Agentendpoint::V1beta::PatchJobs::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
