package Google::Cloud::Osconfig::Agentendpoint::V1::PatchJobs;

use strict;
use warnings;

our $VERSION = '0.14';

use Protobuf::Message;
use Protobuf::DescriptorPool;
use Protobuf::Internal qw(:all);
use MIME::Base64;

BEGIN {
    my $descriptor_b64 = <<'EOF';
Cjdnb29nbGUvY2xvdWQvb3Njb25maWcvYWdlbnRlbmRwb2ludC92MS9wYXRjaF9qb2JzLnBy
b3RvEiZnb29nbGUuY2xvdWQub3Njb25maWcuYWdlbnRlbmRwb2ludC52MSKABwoLUGF0Y2hD
b25maWcSZQoNcmVib290X2NvbmZpZxgBIAEoDjJALmdvb2dsZS5jbG91ZC5vc2NvbmZpZy5h
Z2VudGVuZHBvaW50LnYxLlBhdGNoQ29uZmlnLlJlYm9vdENvbmZpZ1IMcmVib290Q29uZmln
ElwKDnJldHJ5X3N0cmF0ZWd5GAIgASgLMjUuZ29vZ2xlLmNsb3VkLm9zY29uZmlnLmFnZW50
ZW5kcG9pbnQudjEuUmV0cnlTdHJhdGVneVINcmV0cnlTdHJhdGVneRJFCgNhcHQYAyABKAsy
My5nb29nbGUuY2xvdWQub3Njb25maWcuYWdlbnRlbmRwb2ludC52MS5BcHRTZXR0aW5nc1ID
YXB0EkUKA3l1bRgEIAEoCzIzLmdvb2dsZS5jbG91ZC5vc2NvbmZpZy5hZ2VudGVuZHBvaW50
LnYxLll1bVNldHRpbmdzUgN5dW0SRQoDZ29vGAUgASgLMjMuZ29vZ2xlLmNsb3VkLm9zY29u
ZmlnLmFnZW50ZW5kcG9pbnQudjEuR29vU2V0dGluZ3NSA2dvbxJOCgZ6eXBwZXIYBiABKAsy
Ni5nb29nbGUuY2xvdWQub3Njb25maWcuYWdlbnRlbmRwb2ludC52MS5aeXBwZXJTZXR0aW5n
c1IGenlwcGVyEmQKDndpbmRvd3NfdXBkYXRlGAcgASgLMj0uZ29vZ2xlLmNsb3VkLm9zY29u
ZmlnLmFnZW50ZW5kcG9pbnQudjEuV2luZG93c1VwZGF0ZVNldHRpbmdzUg13aW5kb3dzVXBk
YXRlEksKCHByZV9zdGVwGAggASgLMjAuZ29vZ2xlLmNsb3VkLm9zY29uZmlnLmFnZW50ZW5k
cG9pbnQudjEuRXhlY1N0ZXBSB3ByZVN0ZXASTQoJcG9zdF9zdGVwGAkgASgLMjAuZ29vZ2xl
LmNsb3VkLm9zY29uZmlnLmFnZW50ZW5kcG9pbnQudjEuRXhlY1N0ZXBSCHBvc3RTdGVwEjIK
FW1pZ19pbnN0YW5jZXNfYWxsb3dlZBgKIAEoCFITbWlnSW5zdGFuY2VzQWxsb3dlZCJRCgxS
ZWJvb3RDb25maWcSHQoZUkVCT09UX0NPTkZJR19VTlNQRUNJRklFRBAAEgsKB0RFRkFVTFQQ
ARIKCgZBTFdBWVMQAhIJCgVORVZFUhADItsBCgtBcHRTZXR0aW5ncxJMCgR0eXBlGAEgASgO
MjguZ29vZ2xlLmNsb3VkLm9zY29uZmlnLmFnZW50ZW5kcG9pbnQudjEuQXB0U2V0dGluZ3Mu
VHlwZVIEdHlwZRIaCghleGNsdWRlcxgCIAMoCVIIZXhjbHVkZXMSLQoSZXhjbHVzaXZlX3Bh
Y2thZ2VzGAMgAygJUhFleGNsdXNpdmVQYWNrYWdlcyIzCgRUeXBlEhQKEFRZUEVfVU5TUEVD
SUZJRUQQABIICgRESVNUEAESCwoHVVBHUkFERRACIo4BCgtZdW1TZXR0aW5ncxIaCghzZWN1
cml0eRgBIAEoCFIIc2VjdXJpdHkSGAoHbWluaW1hbBgCIAEoCFIHbWluaW1hbBIaCghleGNs
dWRlcxgDIAMoCVIIZXhjbHVkZXMSLQoSZXhjbHVzaXZlX3BhY2thZ2VzGAQgAygJUhFleGNs
dXNpdmVQYWNrYWdlcyINCgtHb29TZXR0aW5ncyLfAQoOWnlwcGVyU2V0dGluZ3MSIwoNd2l0
aF9vcHRpb25hbBgBIAEoCFIMd2l0aE9wdGlvbmFsEh8KC3dpdGhfdXBkYXRlGAIgASgIUgp3
aXRoVXBkYXRlEh4KCmNhdGVnb3JpZXMYAyADKAlSCmNhdGVnb3JpZXMSHgoKc2V2ZXJpdGll
cxgEIAMoCVIKc2V2ZXJpdGllcxIaCghleGNsdWRlcxgFIAMoCVIIZXhjbHVkZXMSKwoRZXhj
bHVzaXZlX3BhdGNoZXMYBiADKAlSEGV4Y2x1c2l2ZVBhdGNoZXMikAMKFVdpbmRvd3NVcGRh
dGVTZXR0aW5ncxJ2Cg9jbGFzc2lmaWNhdGlvbnMYASADKA4yTC5nb29nbGUuY2xvdWQub3Nj
b25maWcuYWdlbnRlbmRwb2ludC52MS5XaW5kb3dzVXBkYXRlU2V0dGluZ3MuQ2xhc3NpZmlj
YXRpb25SD2NsYXNzaWZpY2F0aW9ucxIaCghleGNsdWRlcxgCIAMoCVIIZXhjbHVkZXMSKwoR
ZXhjbHVzaXZlX3BhdGNoZXMYAyADKAlSEGV4Y2x1c2l2ZVBhdGNoZXMitQEKDkNsYXNzaWZp
Y2F0aW9uEh4KGkNMQVNTSUZJQ0FUSU9OX1VOU1BFQ0lGSUVEEAASDAoIQ1JJVElDQUwQARIM
CghTRUNVUklUWRACEg4KCkRFRklOSVRJT04QAxIKCgZEUklWRVIQBBIQCgxGRUFUVVJFX1BB
Q0sQBRIQCgxTRVJWSUNFX1BBQ0sQBhIICgRUT09MEAcSEQoNVVBEQVRFX1JPTExVUBAIEgoK
BlVQREFURRAJIikKDVJldHJ5U3RyYXRlZ3kSGAoHZW5hYmxlZBgBIAEoCFIHZW5hYmxlZCLo
AQoIRXhlY1N0ZXASawoWbGludXhfZXhlY19zdGVwX2NvbmZpZxgBIAEoCzI2Lmdvb2dsZS5j
bG91ZC5vc2NvbmZpZy5hZ2VudGVuZHBvaW50LnYxLkV4ZWNTdGVwQ29uZmlnUhNsaW51eEV4
ZWNTdGVwQ29uZmlnEm8KGHdpbmRvd3NfZXhlY19zdGVwX2NvbmZpZxgCIAEoCzI2Lmdvb2ds
ZS5jbG91ZC5vc2NvbmZpZy5hZ2VudGVuZHBvaW50LnYxLkV4ZWNTdGVwQ29uZmlnUhV3aW5k
b3dzRXhlY1N0ZXBDb25maWci/gIKDkV4ZWNTdGVwQ29uZmlnEh8KCmxvY2FsX3BhdGgYASAB
KAlIAFIJbG9jYWxQYXRoElIKCmdjc19vYmplY3QYAiABKAsyMS5nb29nbGUuY2xvdWQub3Nj
b25maWcuYWdlbnRlbmRwb2ludC52MS5HY3NPYmplY3RIAFIJZ2NzT2JqZWN0EjIKFWFsbG93
ZWRfc3VjY2Vzc19jb2RlcxgDIAMoBVITYWxsb3dlZFN1Y2Nlc3NDb2RlcxJkCgtpbnRlcnBy
ZXRlchgEIAEoDjJCLmdvb2dsZS5jbG91ZC5vc2NvbmZpZy5hZ2VudGVuZHBvaW50LnYxLkV4
ZWNTdGVwQ29uZmlnLkludGVycHJldGVyUgtpbnRlcnByZXRlciJPCgtJbnRlcnByZXRlchIb
ChdJTlRFUlBSRVRFUl9VTlNQRUNJRklFRBAAEggKBE5PTkUQAxIJCgVTSEVMTBABEg4KClBP
V0VSU0hFTEwQAkIMCgpleGVjdXRhYmxlImgKCUdjc09iamVjdBIWCgZidWNrZXQYASABKAlS
BmJ1Y2tldBIWCgZvYmplY3QYAiABKAlSBm9iamVjdBIrChFnZW5lcmF0aW9uX251bWJlchgD
IAEoA1IQZ2VuZXJhdGlvbk51bWJlckKJAQoqY29tLmdvb2dsZS5jbG91ZC5vc2NvbmZpZy5h
Z2VudGVuZHBvaW50LnYxQglQYXRjaEpvYnNaUGNsb3VkLmdvb2dsZS5jb20vZ28vb3Njb25m
aWcvYWdlbnRlbmRwb2ludC9hcGl2MS9hZ2VudGVuZHBvaW50cGI7YWdlbnRlbmRwb2ludHBi
SsBaCgcSBQ4ApQIBCrwECgEMEgMOABIysQQgQ29weXJpZ2h0IDIwMjYgR29vZ2xlIExMQwoK
IExpY2Vuc2VkIHVuZGVyIHRoZSBBcGFjaGUgTGljZW5zZSwgVmVyc2lvbiAyLjAgKHRoZSAi
TGljZW5zZSIpOwogeW91IG1heSBub3QgdXNlIHRoaXMgZmlsZSBleGNlcHQgaW4gY29tcGxp
YW5jZSB3aXRoIHRoZSBMaWNlbnNlLgogWW91IG1heSBvYnRhaW4gYSBjb3B5IG9mIHRoZSBM
aWNlbnNlIGF0CgogICAgIGh0dHA6Ly93d3cuYXBhY2hlLm9yZy9saWNlbnNlcy9MSUNFTlNF
LTIuMAoKIFVubGVzcyByZXF1aXJlZCBieSBhcHBsaWNhYmxlIGxhdyBvciBhZ3JlZWQgdG8g
aW4gd3JpdGluZywgc29mdHdhcmUKIGRpc3RyaWJ1dGVkIHVuZGVyIHRoZSBMaWNlbnNlIGlz
IGRpc3RyaWJ1dGVkIG9uIGFuICJBUyBJUyIgQkFTSVMsCiBXSVRIT1VUIFdBUlJBTlRJRVMg
T1IgQ09ORElUSU9OUyBPRiBBTlkgS0lORCwgZWl0aGVyIGV4cHJlc3Mgb3IgaW1wbGllZC4K
IFNlZSB0aGUgTGljZW5zZSBmb3IgdGhlIHNwZWNpZmljIGxhbmd1YWdlIGdvdmVybmluZyBw
ZXJtaXNzaW9ucyBhbmQKIGxpbWl0YXRpb25zIHVuZGVyIHRoZSBMaWNlbnNlLgoKCAoBAhID
EAAvCggKAQgSAxIAZwoJCgIICxIDEgBnCggKAQgSAxMAKgoJCgIICBIDEwAqCggKAQgSAxQA
QwoJCgIIARIDFABDCm0KAgQAEgQYAEoBGmEgUGF0Y2ggY29uZmlndXJhdGlvbiBzcGVjaWZp
Y2F0aW9ucy4gQ29udGFpbnMgZGV0YWlscyBvbiBob3cgdG8KIGFwcGx5IHBhdGNoZXMgdG8g
YSBWTSBpbnN0YW5jZS4KCgoKAwQAARIDGAgTCisKBAQABAASBBoCKQMaHSBQb3N0LXBhdGNo
IHJlYm9vdCBzZXR0aW5ncy4KCgwKBQQABAABEgMaBxMKMQoGBAAEAAIAEgMcBCIaIiBUaGUg
ZGVmYXVsdCBiZWhhdmlvciBpcyBERUZBVUxULgoKDgoHBAAEAAIAARIDHAQdCg4KBwQABAAC
AAISAxwgIQqNAgoGBAAEAAIBEgMiBBAa/QEgVGhlIGFnZW50IGRlY2lkZXMgaWYgYSByZWJv
b3QgaXMgbmVjZXNzYXJ5IGJ5IGNoZWNraW5nCiBzaWduYWxzIHN1Y2ggYXMgcmVnaXN0cnkg
a2V5cyBvbiBXaW5kb3dzIG9yIGAvdmFyL3J1bi9yZWJvb3QtcmVxdWlyZWRgIG9uCiBBUFQg
YmFzZWQgc3lzdGVtcy4gT24gUlBNIGJhc2VkIHN5c3RlbXMsIGEgc2V0IG9mIGNvcmUgc3lz
dGVtIHBhY2thZ2UKIGluc3RhbGwgdGltZXMgYXJlIGNvbXBhcmVkIHdpdGggc3lzdGVtIGJv
b3QgdGltZS4KCg4KBwQABAACAQESAyIECwoOCgcEAAQAAgECEgMiDg8KRgoGBAAEAAICEgMl
BA8aNyBBbHdheXMgcmVib290IHRoZSBtYWNoaW5lIGFmdGVyIHRoZSB1cGRhdGUgY29tcGxl
dGVzLgoKDgoHBAAEAAICARIDJQQKCg4KBwQABAACAgISAyUNDgpFCgYEAAQAAgMSAygEDho2
IE5ldmVyIHJlYm9vdCB0aGUgbWFjaGluZSBhZnRlciB0aGUgdXBkYXRlIGNvbXBsZXRlcy4K
Cg4KBwQABAACAwESAygECQoOCgcEAAQAAgMCEgMoDA0KKgoEBAACABIDLAIhGh0gUG9zdC1w
YXRjaCByZWJvb3Qgc2V0dGluZ3MuCgoMCgUEAAIABhIDLAIOCgwKBQQAAgABEgMsDxwKDAoF
BAACAAMSAywfIAqwAQoEBAACARIDMQIjGqIBIFJldHJ5IHN0cmF0ZWd5IGNhbiBiZSBkZWZp
bmVkIHRvIGhhdmUgdGhlIGFnZW50IHJldHJ5IHBhdGNoaW5nCiBkdXJpbmcgdGhlIHdpbmRv
dyBpZiBwYXRjaGluZyBmYWlscy4gSWYgb21pdHRlZCwgdGhlIGFnZW50IHdpbGwgdXNlIGl0
cwogZGVmYXVsdCByZXRyeSBzdHJhdGVneS4KCgwKBQQAAgEGEgMxAg8KDAoFBAACAQESAzEQ
HgoMCgUEAAIBAxIDMSEiClIKBAQAAgISAzQCFhpFIEFwdCB1cGRhdGUgc2V0dGluZ3MuIFVz
ZSB0aGlzIG92ZXJyaWRlIHRoZSBkZWZhdWx0IGFwdCBwYXRjaCBydWxlcy4KCgwKBQQAAgIG
EgM0Ag0KDAoFBAACAgESAzQOEQoMCgUEAAICAxIDNBQVClIKBAQAAgMSAzcCFhpFIFl1bSB1
cGRhdGUgc2V0dGluZ3MuIFVzZSB0aGlzIG92ZXJyaWRlIHRoZSBkZWZhdWx0IHl1bSBwYXRj
aCBydWxlcy4KCgwKBQQAAgMGEgM3Ag0KDAoFBAACAwESAzcOEQoMCgUEAAIDAxIDNxQVClIK
BAQAAgQSAzoCFhpFIEdvbyB1cGRhdGUgc2V0dGluZ3MuIFVzZSB0aGlzIG92ZXJyaWRlIHRo
ZSBkZWZhdWx0IGdvbyBwYXRjaCBydWxlcy4KCgwKBQQAAgQGEgM6Ag0KDAoFBAACBAESAzoO
EQoMCgUEAAIEAxIDOhQVClgKBAQAAgUSAz0CHBpLIFp5cHBlciB1cGRhdGUgc2V0dGluZ3Mu
IFVzZSB0aGlzIG92ZXJyaWRlIHRoZSBkZWZhdWx0IHp5cHBlciBwYXRjaCBydWxlcy4KCgwK
BQQAAgUGEgM9AhAKDAoFBAACBQESAz0RFwoMCgUEAAIFAxIDPRobCloKBAQAAgYSA0ACKxpN
IFdpbmRvd3MgdXBkYXRlIHNldHRpbmdzLiBVc2UgdGhpcyBvdmVycmlkZSB0aGUgZGVmYXVs
dCB3aW5kb3dzIHBhdGNoIHJ1bGVzLgoKDAoFBAACBgYSA0ACFwoMCgUEAAIGARIDQBgmCgwK
BQQAAgYDEgNAKSoKOwoEBAACBxIDQwIYGi4gVGhlIEV4ZWNTdGVwIHRvIHJ1biBiZWZvcmUg
dGhlIHBhdGNoIHVwZGF0ZS4KCgwKBQQAAgcGEgNDAgoKDAoFBAACBwESA0MLEwoMCgUEAAIH
AxIDQxYXCjoKBAQAAggSA0YCGRotIFRoZSBFeGVjU3RlcCB0byBydW4gYWZ0ZXIgdGhlIHBh
dGNoIHVwZGF0ZS4KCgwKBQQAAggGEgNGAgoKDAoFBAACCAESA0YLFAoMCgUEAAIIAxIDRhcY
Ck0KBAQAAgkSA0kCIhpAIEFsbG93cyB0aGUgcGF0Y2ggam9iIHRvIHJ1biBvbiBNYW5hZ2Vk
IGluc3RhbmNlIGdyb3VwcyAoTUlHcykuCgoMCgUEAAIJBRIDSQIGCgwKBQQAAgkBEgNJBxwK
DAoFBAACCQMSA0kfIQqfAQoCBAESBE4AZwEakgEgQXB0IHBhdGNoaW5nIHdpbGwgYmUgcGVy
Zm9ybWVkIGJ5IGV4ZWN1dGluZyBgYXB0LWdldCB1cGRhdGUgJiYgYXB0LWdldAogdXBncmFk
ZWAuIEFkZGl0aW9uYWwgb3B0aW9ucyBjYW4gYmUgc2V0IHRvIGNvbnRyb2wgaG93IHRoaXMg
aXMgZXhlY3V0ZWQuCgoKCgMEAQESA04IEwofCgQEAQQAEgRQAlkDGhEgQXB0IHBhdGNoIHR5
cGUuCgoMCgUEAQQAARIDUAcLCjcKBgQBBAACABIDUgQZGiggQnkgZGVmYXVsdCwgdXBncmFk
ZSB3aWxsIGJlIHBlcmZvcm1lZC4KCg4KBwQBBAACAAESA1IEFAoOCgcEAQQAAgACEgNSFxgK
LQoGBAEEAAIBEgNVBA0aHiBSdW5zIGBhcHQtZ2V0IGRpc3QtdXBncmFkZWAuCgoOCgcEAQQA
AgEBEgNVBAgKDgoHBAEEAAIBAhIDVQsMCigKBgQBBAACAhIDWAQQGhkgUnVucyBgYXB0LWdl
dCB1cGdyYWRlYC4KCg4KBwQBBAACAgESA1gECwoOCgcEAQQAAgICEgNYDg8KcgoEBAECABID
XQIQGmUgQnkgY2hhbmdpbmcgdGhlIHR5cGUgdG8gRElTVCwgdGhlIHBhdGNoaW5nIHdpbGwg
YmUgcGVyZm9ybWVkCiB1c2luZyBgYXB0LWdldCBkaXN0LXVwZ3JhZGVgIGluc3RlYWQuCgoM
CgUEAQIABhIDXQIGCgwKBQQBAgABEgNdBwsKDAoFBAECAAMSA10ODwo3CgQEAQIBEgNgAh8a
KiBMaXN0IG9mIHBhY2thZ2VzIHRvIGV4Y2x1ZGUgZnJvbSB1cGRhdGUuCgoMCgUEAQIBBBID
YAIKCgwKBQQBAgEFEgNgCxEKDAoFBAECAQESA2ASGgoMCgUEAQIBAxIDYB0eCvYBCgQEAQIC
EgNmAika6AEgQW4gZXhjbHVzaXZlIGxpc3Qgb2YgcGFja2FnZXMgdG8gYmUgdXBkYXRlZC4g
VGhlc2UgYXJlIHRoZSBvbmx5IHBhY2thZ2VzCiB0aGF0IHdpbGwgYmUgdXBkYXRlZC4gSWYg
dGhlc2UgcGFja2FnZXMgYXJlIG5vdCBpbnN0YWxsZWQsIHRoZXkgd2lsbCBiZQogaWdub3Jl
ZC4gVGhpcyBmaWVsZCBjYW5ub3QgYmUgc3BlY2lmaWVkIHdpdGggYW55IG90aGVyIHBhdGNo
IGNvbmZpZ3VyYXRpb24KIGZpZWxkcy4KCgwKBQQBAgIEEgNmAgoKDAoFBAECAgUSA2YLEQoM
CgUEAQICARIDZhIkCgwKBQQBAgIDEgNmJygKxQEKAgQCEgRtAH4BGrgBIFl1bSBwYXRjaGlu
ZyB3aWxsIGJlIHBlcmZvcm1lZCBieSBleGVjdXRpbmcgYHl1bSB1cGRhdGVgLiBBZGRpdGlv
bmFsIG9wdGlvbnMKIGNhbiBiZSBzZXQgdG8gY29udHJvbCBob3cgdGhpcyBpcyBleGVjdXRl
ZC4KCiBOb3RlIHRoYXQgbm90IGFsbCBzZXR0aW5ncyBhcmUgc3VwcG9ydGVkIG9uIGFsbCBw
bGF0Zm9ybXMuCgoKCgMEAgESA20IEwpbCgQEAgIAEgNwAhQaTiBBZGRzIHRoZSBgLS1zZWN1
cml0eWAgZmxhZyB0byBgeXVtIHVwZGF0ZWAuIE5vdCBzdXBwb3J0ZWQgb24KIGFsbCBwbGF0
Zm9ybXMuCgoMCgUEAgIABRIDcAIGCgwKBQQCAgABEgNwBw8KDAoFBAICAAMSA3ASEwpECgQE
AgIBEgNzAhMaNyBXaWxsIGNhdXNlIHBhdGNoIHRvIHJ1biBgeXVtIHVwZGF0ZS1taW5pbWFs
YCBpbnN0ZWFkLgoKDAoFBAICAQUSA3MCBgoMCgUEAgIBARIDcwcOCgwKBQQCAgEDEgNzERIK
ewoEBAICAhIDdwIfGm4gTGlzdCBvZiBwYWNrYWdlcyB0byBleGNsdWRlIGZyb20gdXBkYXRl
LiBUaGVzZSBwYWNrYWdlcyB3aWxsIGJlIGV4Y2x1ZGVkIGJ5CiB1c2luZyB0aGUgeXVtIGAt
LWV4Y2x1ZGVgIGZsYWcuCgoMCgUEAgICBBIDdwIKCgwKBQQCAgIFEgN3CxEKDAoFBAICAgES
A3cSGgoMCgUEAgICAxIDdx0eCvgBCgQEAgIDEgN9Aika6gEgQW4gZXhjbHVzaXZlIGxpc3Qg
b2YgcGFja2FnZXMgdG8gYmUgdXBkYXRlZC4gVGhlc2UgYXJlIHRoZSBvbmx5IHBhY2thZ2Vz
CiB0aGF0IHdpbGwgYmUgdXBkYXRlZC4gSWYgdGhlc2UgcGFja2FnZXMgYXJlIG5vdCBpbnN0
YWxsZWQsIHRoZXkgd2lsbCBiZQogaWdub3JlZC4gVGhpcyBmaWVsZCBtdXN0IG5vdCBiZSBz
cGVjaWZpZWQgd2l0aCBhbnkgb3RoZXIgcGF0Y2gKIGNvbmZpZ3VyYXRpb24gZmllbGRzLgoK
DAoFBAICAwQSA30CCgoMCgUEAgIDBRIDfQsRCgwKBQQCAgMBEgN9EiQKDAoFBAICAwMSA30n
KApGCgIEAxIEgQEAFho6IEdvb2dldCBwYXRjaGluZyBpcyBwZXJmb3JtZWQgYnkgcnVubmlu
ZyBgZ29vZ2V0IHVwZGF0ZWAuCgoLCgMEAwESBIEBCBMKfAoCBAQSBoUBAJsBARpuIFp5cHBl
ciBwYXRjaGluZyBpcyBwZXJmb3JtZWQgYnkgcnVubmluZyBgenlwcGVyIHBhdGNoYC4KIFNl
ZSBhbHNvIGh0dHBzOi8vZW4ub3BlbnN1c2Uub3JnL1NEQjpaeXBwZXJfbWFudWFsLgoKCwoD
BAQBEgSFAQgWCkIKBAQEAgASBIcBAhkaNCBBZGRzIHRoZSBgLS13aXRoLW9wdGlvbmFsYCBm
bGFnIHRvIGB6eXBwZXIgcGF0Y2hgLgoKDQoFBAQCAAUSBIcBAgYKDQoFBAQCAAESBIcBBxQK
DQoFBAQCAAMSBIcBFxgKQQoEBAQCARIEigECFxozIEFkZHMgdGhlIGAtLXdpdGgtdXBkYXRl
YCBmbGFnLCB0byBgenlwcGVyIHBhdGNoYC4KCg0KBQQEAgEFEgSKAQIGCg0KBQQEAgEBEgSK
AQcSCg0KBQQEAgEDEgSKARUWCnoKBAQEAgISBI4BAiEabCBJbnN0YWxsIG9ubHkgcGF0Y2hl
cyB3aXRoIHRoZXNlIGNhdGVnb3JpZXMuCiBDb21tb24gY2F0ZWdvcmllcyBpbmNsdWRlIHNl
Y3VyaXR5LCByZWNvbW1lbmRlZCwgYW5kIGZlYXR1cmUuCgoNCgUEBAICBBIEjgECCgoNCgUE
BAICBRIEjgELEQoNCgUEBAICARIEjgESHAoNCgUEBAICAxIEjgEfIAp+CgQEBAIDEgSSAQIh
GnAgSW5zdGFsbCBvbmx5IHBhdGNoZXMgd2l0aCB0aGVzZSBzZXZlcml0aWVzLgogQ29tbW9u
IHNldmVyaXRpZXMgaW5jbHVkZSBjcml0aWNhbCwgaW1wb3J0YW50LCBtb2RlcmF0ZSwgYW5k
IGxvdy4KCg0KBQQEAgMEEgSSAQIKCg0KBQQEAgMFEgSSAQsRCg0KBQQEAgMBEgSSARIcCg0K
BQQEAgMDEgSSAR8gCjcKBAQEAgQSBJUBAh8aKSBMaXN0IG9mIHBhdGNoZXMgdG8gZXhjbHVk
ZSBmcm9tIHVwZGF0ZS4KCg0KBQQEAgQEEgSVAQIKCg0KBQQEAgQFEgSVAQsRCg0KBQQEAgQB
EgSVARIaCg0KBQQEAgQDEgSVAR0eCugBCgQEBAIFEgSaAQIoGtkBIEFuIGV4Y2x1c2l2ZSBs
aXN0IG9mIHBhdGNoZXMgdG8gYmUgdXBkYXRlZC4gVGhlc2UgYXJlIHRoZSBvbmx5IHBhdGNo
ZXMKIHRoYXQgd2lsbCBiZSBpbnN0YWxsZWQgdXNpbmcgJ3p5cHBlciBwYXRjaCBwYXRjaDo8
cGF0Y2hfbmFtZT4nIGNvbW1hbmQuCiBUaGlzIGZpZWxkIG11c3Qgbm90IGJlIHVzZWQgd2l0
aCBhbnkgb3RoZXIgcGF0Y2ggY29uZmlndXJhdGlvbiBmaWVsZHMuCgoNCgUEBAIFBBIEmgEC
CgoNCgUEBAIFBRIEmgELEQoNCgUEBAIFARIEmgESIwoNCgUEBAIFAxIEmgEmJwpNCgIEBRIG
ngEA3gEBGj8gV2luZG93cyBwYXRjaGluZyBpcyBwZXJmb3JtZWQgdXNpbmcgdGhlIFdpbmRv
d3MgVXBkYXRlIEFnZW50LgoKCwoDBAUBEgSeAQgdCsYBCgQEBQQAEgaiAQLRAQMatQEgTWlj
cm9zb2Z0IFdpbmRvd3MgdXBkYXRlIGNsYXNzaWZpY2F0aW9ucyBhcyBkZWZpbmVkIGluCiBb
MV0KIGh0dHBzOi8vc3VwcG9ydC5taWNyb3NvZnQuY29tL2VuLXVzL2hlbHAvODI0Njg0L2Rl
c2NyaXB0aW9uLW9mLXRoZS1zdGFuZGFyZC10ZXJtaW5vbG9neS10aGF0LWlzLXVzZWQtdG8t
ZGVzY3JpYmUtbWljcm8KCg0KBQQFBAABEgSiAQcVClMKBgQFBAACABIEpAEEIxpDIEludmFs
aWQuIElmIGNsYXNzaWZpY2F0aW9ucyBhcmUgaW5jbHVkZWQsIHRoZXkgbXVzdCBiZSBzcGVj
aWZpZWQuCgoPCgcEBQQAAgABEgSkAQQeCg8KBwQFBAACAAISBKQBISIKegoGBAUEAAIBEgSo
AQQRGmogIkEgd2lkZWx5IHJlbGVhc2VkIGZpeCBmb3IgYSBzcGVjaWZpYyBwcm9ibGVtIHRo
YXQgYWRkcmVzc2VzIGEgY3JpdGljYWwsCiBub24tc2VjdXJpdHktcmVsYXRlZCBidWcuIiBb
MV0KCg8KBwQFBAACAQESBKgBBAwKDwoHBAUEAAIBAhIEqAEPEAqNAgoGBAUEAAICEgSuAQQR
GvwBICJBIHdpZGVseSByZWxlYXNlZCBmaXggZm9yIGEgcHJvZHVjdC1zcGVjaWZpYywgc2Vj
dXJpdHktcmVsYXRlZAogdnVsbmVyYWJpbGl0eS4gU2VjdXJpdHkgdnVsbmVyYWJpbGl0aWVz
IGFyZSByYXRlZCBieSB0aGVpciBzZXZlcml0eS4gVGhlCiBzZXZlcml0eSByYXRpbmcgaXMg
aW5kaWNhdGVkIGluIHRoZSBNaWNyb3NvZnQgc2VjdXJpdHkgYnVsbGV0aW4gYXMKIGNyaXRp
Y2FsLCBpbXBvcnRhbnQsIG1vZGVyYXRlLCBvciBsb3cuIiBbMV0KCg8KBwQFBAACAgESBK4B
BAwKDwoHBAUEAAICAhIErgEPEAqUAgoGBAUEAAIDEgS0AQQTGoMCICJBIHdpZGVseSByZWxl
YXNlZCBhbmQgZnJlcXVlbnQgc29mdHdhcmUgdXBkYXRlIHRoYXQgY29udGFpbnMgYWRkaXRp
b25zCiB0byBhIHByb2R1Y3TigJlzIGRlZmluaXRpb24gZGF0YWJhc2UuIERlZmluaXRpb24g
ZGF0YWJhc2VzIGFyZSBvZnRlbiB1c2VkCiB0byBkZXRlY3Qgb2JqZWN0cyB0aGF0IGhhdmUg
c3BlY2lmaWMgYXR0cmlidXRlcywgc3VjaCBhcyBoYXJtZnVsIGNvZGUsCiBwaGlzaGluZyB3
ZWJzaXRlcywgb3IganVuayBtYWlsLiIgWzFdCgoPCgcEBQQAAgMBEgS0AQQOCg8KBwQFBAAC
AwISBLQBERIKUAoGBAUEAAIEEgS3AQQPGkAgIlNvZnR3YXJlIHRoYXQgY29udHJvbHMgdGhl
IGlucHV0IGFuZCBvdXRwdXQgb2YgYSBkZXZpY2UuIiBbMV0KCg8KBwQFBAACBAESBLcBBAoK
DwoHBAUEAAIEAhIEtwENDgq4AQoGBAUEAAIFEgS8AQQVGqcBICJOZXcgcHJvZHVjdCBmdW5j
dGlvbmFsaXR5IHRoYXQgaXMgZmlyc3QgZGlzdHJpYnV0ZWQgb3V0c2lkZSB0aGUgY29udGV4
dAogb2YgYSBwcm9kdWN0IHJlbGVhc2UgYW5kIHRoYXQgaXMgdHlwaWNhbGx5IGluY2x1ZGVk
IGluIHRoZSBuZXh0IGZ1bGwKIHByb2R1Y3QgcmVsZWFzZS4iIFsxXQoKDwoHBAUEAAIFARIE
vAEEEAoPCgcEBQQAAgUCEgS8ARMUCtoCCgYEBQQAAgYSBMMBBBUayQIgIkEgdGVzdGVkLCBj
dW11bGF0aXZlIHNldCBvZiBhbGwgaG90Zml4ZXMsIHNlY3VyaXR5IHVwZGF0ZXMsIGNyaXRp
Y2FsCiB1cGRhdGVzLCBhbmQgdXBkYXRlcy4gQWRkaXRpb25hbGx5LCBzZXJ2aWNlIHBhY2tz
IG1heSBjb250YWluIGFkZGl0aW9uYWwKIGZpeGVzIGZvciBwcm9ibGVtcyB0aGF0IGFyZSBm
b3VuZCBpbnRlcm5hbGx5IHNpbmNlIHRoZSByZWxlYXNlIG9mIHRoZQogcHJvZHVjdC4gU2Vy
dmljZSBwYWNrcyBteSBhbHNvIGNvbnRhaW4gYSBsaW1pdGVkIG51bWJlciBvZgogY3VzdG9t
ZXItcmVxdWVzdGVkIGRlc2lnbiBjaGFuZ2VzIG9yIGZlYXR1cmVzLiIgWzFdCgoPCgcEBQQA
AgYBEgTDAQQQCg8KBwQFBAACBgISBMMBExQKWAoGBAUEAAIHEgTGAQQNGkggIkEgdXRpbGl0
eSBvciBmZWF0dXJlIHRoYXQgaGVscHMgY29tcGxldGUgYSB0YXNrIG9yIHNldCBvZiB0YXNr
cy4iIFsxXQoKDwoHBAUEAAIHARIExgEECAoPCgcEBQQAAgcCEgTGAQsMCqkCCgYEBQQAAggS
BMwBBBYamAIgIkEgdGVzdGVkLCBjdW11bGF0aXZlIHNldCBvZiBob3RmaXhlcywgc2VjdXJp
dHkgdXBkYXRlcywgY3JpdGljYWwKIHVwZGF0ZXMsIGFuZCB1cGRhdGVzIHRoYXQgYXJlIHBh
Y2thZ2VkIHRvZ2V0aGVyIGZvciBlYXN5IGRlcGxveW1lbnQuIEEKIHJvbGx1cCBnZW5lcmFs
bHkgdGFyZ2V0cyBhIHNwZWNpZmljIGFyZWEsIHN1Y2ggYXMgc2VjdXJpdHksIG9yIGEKIGNv
bXBvbmVudCBvZiBhIHByb2R1Y3QsIHN1Y2ggYXMgSW50ZXJuZXQgSW5mb3JtYXRpb24gU2Vy
dmljZXMgKElJUykuIiBbMV0KCg8KBwQFBAACCAESBMwBBBEKDwoHBAUEAAIIAhIEzAEUFQqD
AQoGBAUEAAIJEgTQAQQPGnMgIkEgd2lkZWx5IHJlbGVhc2VkIGZpeCBmb3IgYSBzcGVjaWZp
YyBwcm9ibGVtLiBBbiB1cGRhdGUgYWRkcmVzc2VzIGEKIG5vbmNyaXRpY2FsLCBub24tc2Vj
dXJpdHktcmVsYXRlZCBidWcuIiBbMV0KCg8KBwQFBAACCQESBNABBAoKDwoHBAUEAAIJAhIE
0AENDgpzCgQEBQIAEgTVAQIuGmUgT25seSBhcHBseSB1cGRhdGVzIG9mIHRoZXNlIHdpbmRv
d3MgdXBkYXRlIGNsYXNzaWZpY2F0aW9ucy4gSWYgZW1wdHksIGFsbAogdXBkYXRlcyB3aWxs
IGJlIGFwcGxpZWQuCgoNCgUEBQIABBIE1QECCgoNCgUEBQIABhIE1QELGQoNCgUEBQIAARIE
1QEaKQoNCgUEBQIAAxIE1QEsLQozCgQEBQIBEgTYAQIfGiUgTGlzdCBvZiBLQnMgdG8gZXhj
bHVkZSBmcm9tIHVwZGF0ZS4KCg0KBQQFAgEEEgTYAQIKCg0KBQQFAgEFEgTYAQsRCg0KBQQF
AgEBEgTYARIaCg0KBQQFAgEDEgTYAR0eCqgBCgQEBQICEgTdAQIoGpkBIEFuIGV4Y2x1c2l2
ZSBsaXN0IG9mIGticyB0byBiZSB1cGRhdGVkLiBUaGVzZSBhcmUgdGhlIG9ubHkgcGF0Y2hl
cwogdGhhdCB3aWxsIGJlIHVwZGF0ZWQuIFRoaXMgZmllbGQgbXVzdCBub3QgYmUgdXNlZCB3
aXRoIG90aGVyCiBwYXRjaCBjb25maWd1cmF0aW9ucy4KCg0KBQQFAgIEEgTdAQIKCg0KBQQF
AgIFEgTdAQsRCg0KBQQFAgIBEgTdARIjCg0KBQQFAgIDEgTdASYnClEKAgQGEgbhAQDlAQEa
QyBUaGUgc3RyYXRlZ3kgZm9yIHJldHJ5aW5nIGZhaWxlZCBwYXRjaGVzIGR1cmluZyB0aGUg
cGF0Y2ggd2luZG93LgoKCwoDBAYBEgThAQgVCl4KBAQGAgASBOQBAhMaUCBJZiB0cnVlLCB0
aGUgYWdlbnQgd2lsbCBjb250aW51ZSB0byB0cnkgYW5kIHBhdGNoIHVudGlsIHRoZSB3aW5k
b3cgaGFzCiBlbmRlZC4KCg0KBQQGAgAFEgTkAQIGCg0KBQQGAgABEgTkAQcOCg0KBQQGAgAD
EgTkARESCj4KAgQHEgboAQDuAQEaMCBBIHN0ZXAgdGhhdCBydW5zIGFuIGV4ZWN1dGFibGUg
Zm9yIGEgUGF0Y2hKb2IuCgoLCgMEBwESBOgBCBAKTgoEBAcCABIE6gECLBpAIFRoZSBFeGVj
U3RlcENvbmZpZyBmb3IgYWxsIExpbnV4IFZNcyB0YXJnZXRlZCBieSB0aGUgUGF0Y2hKb2Iu
CgoNCgUEBwIABhIE6gECEAoNCgUEBwIAARIE6gERJwoNCgUEBwIAAxIE6gEqKwpQCgQEBwIB
EgTtAQIuGkIgVGhlIEV4ZWNTdGVwQ29uZmlnIGZvciBhbGwgV2luZG93cyBWTXMgdGFyZ2V0
ZWQgYnkgdGhlIFBhdGNoSm9iLgoKDQoFBAcCAQYSBO0BAhAKDQoFBAcCAQESBO0BESkKDQoF
BAcCAQMSBO0BLC0KNgoCBAgSBvEBAJgCARooIENvbW1vbiBjb25maWd1cmF0aW9ucyBmb3Ig
YW4gRXhlY1N0ZXAuCgoLCgMECAESBPEBCBYKNwoEBAgEABIG8wEChAIDGicgVGhlIGludGVy
cHJldGVyIHVzZWQgdG8gcnVuIHRoZSBmaWxlLgoKDQoFBAgEAAESBPMBBxIKVAoGBAgEAAIA
EgT1AQQgGkQgSWYgdGhlIGludGVycHJldGVyIGlzIG5vdCBzcGVjaWZpZWQsIHRoZSB2YWx1
ZSBkZWZhdWx0cyB0byBgTk9ORWAuCgoPCgcECAQAAgABEgT1AQQbCg8KBwQIBAACAAISBPUB
Hh8KrwIKBgQIBAACARIE/AEEDRqeAiBJbmRpY2F0ZXMgdGhhdCB0aGUgZmlsZSBpcyBydW4g
YXMgZm9sbG93cyBvbiBlYWNoIG9wZXJhdGluZyBzeXN0ZW06CiArIEZvciBMaW51eCBWTXMs
IHRoZSBmaWxlIGlzIHJhbiBhcyBhbiBleGVjdXRhYmxlIGFuZCB0aGUgaW50ZXJwcmV0ZXIK
IG1pZ2h0IGJlIHBhcnNlZCBmcm9tIHRoZSBbc2hlYmFuZwogbGluZV0oaHR0cHM6Ly93aWtp
cGVkaWEub3JnL3dpa2kvU2hlYmFuZ18oVW5peCkpIG9mIHRoZSBmaWxlLgogKyBGb3IgV2lu
ZG93cyBWTSwgdGhpcyB2YWx1ZSBpcyBub3Qgc3VwcG9ydGVkLgoKDwoHBAgEAAIBARIE/AEE
CAoPCgcECAQAAgECEgT8AQsMCl8KBgQIBAACAhIEgAIEDhpPIEluZGljYXRlcyB0aGF0IHRo
ZSBmaWxlIGlzIHJ1biB3aXRoIGAvYmluL3NoYCBvbiBMaW51eCBhbmQgYGNtZGAKIG9uIFdp
bmRvd3MuCgoPCgcECAQAAgIBEgSAAgQJCg8KBwQIBAACAgISBIACDA0KQQoGBAgEAAIDEgSD
AgQTGjEgSW5kaWNhdGVzIHRoYXQgdGhlIGZpbGUgaXMgcnVuIHdpdGggUG93ZXJTaGVsbC4K
Cg8KBwQIBAACAwESBIMCBA4KDwoHBAgEAAIDAhIEgwIREgotCgQECAgAEgaHAgKNAgMaHSBM
b2NhdGlvbiBvZiB0aGUgZXhlY3V0YWJsZS4KCg0KBQQICAABEgSHAggSCj0KBAQIAgASBIkC
BBoaLyBBbiBhYnNvbHV0ZSBwYXRoIHRvIHRoZSBleGVjdXRhYmxlIG9uIHRoZSBWTS4KCg0K
BQQIAgAFEgSJAgQKCg0KBQQIAgABEgSJAgsVCg0KBQQIAgADEgSJAhgZCjcKBAQIAgESBIwC
BB0aKSBBIEdDUyBvYmplY3QgY29udGFpbmluZyB0aGUgZXhlY3V0YWJsZS4KCg0KBQQIAgEG
EgSMAgQNCg0KBQQIAgEBEgSMAg4YCg0KBQQIAgEDEgSMAhscCncKBAQIAgISBJECAisaaSBE
ZWZhdWx0cyB0byBbMF0uIEEgbGlzdCBvZiBwb3NzaWJsZSByZXR1cm4gdmFsdWVzIHRoYXQg
dGhlCiBleGVjdXRpb24gY2FuIHJldHVybiB0byBpbmRpY2F0ZSBhIHN1Y2Nlc3MuCgoNCgUE
CAICBBIEkQICCgoNCgUECAICBRIEkQILEAoNCgUECAICARIEkQIRJgoNCgUECAICAxIEkQIp
KgqLAgoEBAgCAxIElwICHhr8ASBUaGUgc2NyaXB0IGludGVycHJldGVyIHRvIHVzZSB0byBy
dW4gdGhlIHNjcmlwdC4gSWYgbm8gaW50ZXJwcmV0ZXIgaXMKIHNwZWNpZmllZCB0aGUgc2Ny
aXB0IHdpbGwgYmUgZXhlY3V0ZWQgZGlyZWN0bHksIHdoaWNoIHdpbGwgbGlrZWx5CiBvbmx5
IHN1Y2NlZWQgZm9yIHNjcmlwdHMgd2l0aCBzaGViYW5nIGxpbmVzLgogW1dpa2lwZWRpYSBz
aGViYW5nXShodHRwczovL2VuLndpa2lwZWRpYS5vcmcvd2lraS9TaGViYW5nXyhVbml4KSku
CgoNCgUECAIDBhIElwICDQoNCgUECAIDARIElwIOGQoNCgUECAIDAxIElwIcHQoqCgIECRIG
mwIApQIBGhwgR0NTIG9iamVjdCByZXByZXNlbnRhdGlvbi4KCgsKAwQJARIEmwIIEQopCgQE
CQIAEgSdAgIUGhsgQnVja2V0IG9mIHRoZSBHQ1Mgb2JqZWN0LgoKDQoFBAkCAAUSBJ0CAggK
DQoFBAkCAAESBJ0CCQ8KDQoFBAkCAAMSBJ0CEhMKJwoEBAkCARIEoAICFBoZIE5hbWUgb2Yg
dGhlIEdDUyBvYmplY3QuCgoNCgUECQIBBRIEoAICCAoNCgUECQIBARIEoAIJDwoNCgUECQIB
AxIEoAISEwqKAQoEBAkCAhIEpAICHhp8IEdlbmVyYXRpb24gbnVtYmVyIG9mIHRoZSBHQ1Mg
b2JqZWN0LiBUaGlzIGlzIHVzZWQgdG8gZW5zdXJlIHRoYXQgdGhlCiBFeGVjU3RlcCBzcGVj
aWZpZWQgYnkgdGhpcyBQYXRjaEpvYiBkb2VzIG5vdCBjaGFuZ2UuCgoNCgUECQICBRIEpAIC
BwoNCgUECQICARIEpAIIGQoNCgUECQICAxIEpAIcHWIGcHJvdG8z
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Osconfig::Agentendpoint::V1::PatchJobs::PatchConfig ===
    # Fields for PatchConfig
    # Field: reboot_config Type: 14 (.google.cloud.osconfig.agentendpoint.v1.PatchConfig.RebootConfig)
    # Field: retry_strategy Type: 11 (.google.cloud.osconfig.agentendpoint.v1.RetryStrategy)
    # Field: apt Type: 11 (.google.cloud.osconfig.agentendpoint.v1.AptSettings)
    # Field: yum Type: 11 (.google.cloud.osconfig.agentendpoint.v1.YumSettings)
    # Field: goo Type: 11 (.google.cloud.osconfig.agentendpoint.v1.GooSettings)
    # Field: zypper Type: 11 (.google.cloud.osconfig.agentendpoint.v1.ZypperSettings)
    # Field: windows_update Type: 11 (.google.cloud.osconfig.agentendpoint.v1.WindowsUpdateSettings)
    # Field: pre_step Type: 11 (.google.cloud.osconfig.agentendpoint.v1.ExecStep)
    # Field: post_step Type: 11 (.google.cloud.osconfig.agentendpoint.v1.ExecStep)
    # Field: mig_instances_allowed Type: 8 ()

# Enum: PatchConfig::RebootConfig
our $PatchConfig_REBOOT_CONFIG_UNSPECIFIED = 0;
our $PatchConfig_DEFAULT = 1;
our $PatchConfig_ALWAYS = 2;
our $PatchConfig_NEVER = 3;

# === Message: Google::Cloud::Osconfig::Agentendpoint::V1::PatchJobs::AptSettings ===
    # Fields for AptSettings
    # Field: type Type: 14 (.google.cloud.osconfig.agentendpoint.v1.AptSettings.Type)
    # Field: excludes Type: 9 ()
    # Field: exclusive_packages Type: 9 ()

# Enum: AptSettings::Type
our $AptSettings_TYPE_UNSPECIFIED = 0;
our $AptSettings_DIST = 1;
our $AptSettings_UPGRADE = 2;

# === Message: Google::Cloud::Osconfig::Agentendpoint::V1::PatchJobs::YumSettings ===
    # Fields for YumSettings
    # Field: security Type: 8 ()
    # Field: minimal Type: 8 ()
    # Field: excludes Type: 9 ()
    # Field: exclusive_packages Type: 9 ()

# === Message: Google::Cloud::Osconfig::Agentendpoint::V1::PatchJobs::GooSettings ===
    # Fields for GooSettings

# === Message: Google::Cloud::Osconfig::Agentendpoint::V1::PatchJobs::ZypperSettings ===
    # Fields for ZypperSettings
    # Field: with_optional Type: 8 ()
    # Field: with_update Type: 8 ()
    # Field: categories Type: 9 ()
    # Field: severities Type: 9 ()
    # Field: excludes Type: 9 ()
    # Field: exclusive_patches Type: 9 ()

# === Message: Google::Cloud::Osconfig::Agentendpoint::V1::PatchJobs::WindowsUpdateSettings ===
    # Fields for WindowsUpdateSettings
    # Field: classifications Type: 14 (.google.cloud.osconfig.agentendpoint.v1.WindowsUpdateSettings.Classification)
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

# === Message: Google::Cloud::Osconfig::Agentendpoint::V1::PatchJobs::RetryStrategy ===
    # Fields for RetryStrategy
    # Field: enabled Type: 8 ()

# === Message: Google::Cloud::Osconfig::Agentendpoint::V1::PatchJobs::ExecStep ===
    # Fields for ExecStep
    # Field: linux_exec_step_config Type: 11 (.google.cloud.osconfig.agentendpoint.v1.ExecStepConfig)
    # Field: windows_exec_step_config Type: 11 (.google.cloud.osconfig.agentendpoint.v1.ExecStepConfig)

# === Message: Google::Cloud::Osconfig::Agentendpoint::V1::PatchJobs::ExecStepConfig ===
    # Fields for ExecStepConfig
    # Field: local_path Type: 9 ()
    # Field: gcs_object Type: 11 (.google.cloud.osconfig.agentendpoint.v1.GcsObject)
    # Field: allowed_success_codes Type: 5 ()
    # Field: interpreter Type: 14 (.google.cloud.osconfig.agentendpoint.v1.ExecStepConfig.Interpreter)

# Enum: ExecStepConfig::Interpreter
our $ExecStepConfig_INTERPRETER_UNSPECIFIED = 0;
our $ExecStepConfig_NONE = 3;
our $ExecStepConfig_SHELL = 1;
our $ExecStepConfig_POWERSHELL = 2;

# === Message: Google::Cloud::Osconfig::Agentendpoint::V1::PatchJobs::GcsObject ===
    # Fields for GcsObject
    # Field: bucket Type: 9 ()
    # Field: object Type: 9 ()
    # Field: generation_number Type: 3 ()

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Osconfig::Agentendpoint::V1::PatchJobs - Compiled Protocol Buffers messages for google/cloud/osconfig/agentendpoint/v1/patch_jobs.proto

=head1 SYNOPSIS

    use Google::Cloud::Osconfig::Agentendpoint::V1::PatchJobs;

    my $msg = Google::Cloud::Osconfig::Agentendpoint::V1::PatchJobs::PatchConfig->new({
        reboot_config => $reboot_config,
        retry_strategy => $retry_strategy,
        apt => $apt,
        yum => $yum,
    });

    # Read or update a field
    my $val = $msg->reboot_config();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Osconfig::Agentendpoint::V1::PatchJobs::PatchConfig->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/osconfig/agentendpoint/v1/patch_jobs.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Osconfig::Agentendpoint::V1::PatchJobs::PatchConfig

Patch configuration specifications. Contains details on how to
apply patches to a VM instance.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->reboot_config() >> / C<< $msg->reboot_config($value) >>

Type: C<Enum> (L<Google::Cloud::Osconfig::Agentendpoint::V1::PatchConfig::RebootConfig>)

Post-patch reboot settings.

=item * C<< $msg->retry_strategy() >> / C<< $msg->retry_strategy($value) >>

Type: C<Message> (L<Google::Cloud::Osconfig::Agentendpoint::V1::PatchJobs::RetryStrategy>)

Retry strategy can be defined to have the agent retry patching
during the window if patching fails. If omitted, the agent will use its
default retry strategy.

=item * C<< $msg->apt() >> / C<< $msg->apt($value) >>

Type: C<Message> (L<Google::Cloud::Osconfig::Agentendpoint::V1::PatchJobs::AptSettings>)

Apt update settings. Use this override the default apt patch rules.

=item * C<< $msg->yum() >> / C<< $msg->yum($value) >>

Type: C<Message> (L<Google::Cloud::Osconfig::Agentendpoint::V1::PatchJobs::YumSettings>)

Yum update settings. Use this override the default yum patch rules.

=item * C<< $msg->goo() >> / C<< $msg->goo($value) >>

Type: C<Message> (L<Google::Cloud::Osconfig::Agentendpoint::V1::PatchJobs::GooSettings>)

Goo update settings. Use this override the default goo patch rules.

=item * C<< $msg->zypper() >> / C<< $msg->zypper($value) >>

Type: C<Message> (L<Google::Cloud::Osconfig::Agentendpoint::V1::PatchJobs::ZypperSettings>)

Zypper update settings. Use this override the default zypper patch rules.

=item * C<< $msg->windows_update() >> / C<< $msg->windows_update($value) >>

Type: C<Message> (L<Google::Cloud::Osconfig::Agentendpoint::V1::PatchJobs::WindowsUpdateSettings>)

Windows update settings. Use this override the default windows patch rules.

=item * C<< $msg->pre_step() >> / C<< $msg->pre_step($value) >>

Type: C<Message> (L<Google::Cloud::Osconfig::Agentendpoint::V1::PatchJobs::ExecStep>)

The ExecStep to run before the patch update.

=item * C<< $msg->post_step() >> / C<< $msg->post_step($value) >>

Type: C<Message> (L<Google::Cloud::Osconfig::Agentendpoint::V1::PatchJobs::ExecStep>)

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

=head2 Google::Cloud::Osconfig::Agentendpoint::V1::PatchJobs::AptSettings

Apt patching will be performed by executing `apt-get update && apt-get
upgrade`. Additional options can be set to control how this is executed.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->type() >> / C<< $msg->type($value) >>

Type: C<Enum> (L<Google::Cloud::Osconfig::Agentendpoint::V1::AptSettings::Type>)

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

=head2 Google::Cloud::Osconfig::Agentendpoint::V1::PatchJobs::YumSettings

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

=head2 Google::Cloud::Osconfig::Agentendpoint::V1::PatchJobs::GooSettings

Googet patching is performed by running `googet update`.

Inherits from L<Protobuf::Message>.

=head2 Google::Cloud::Osconfig::Agentendpoint::V1::PatchJobs::ZypperSettings

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

=head2 Google::Cloud::Osconfig::Agentendpoint::V1::PatchJobs::WindowsUpdateSettings

Windows patching is performed using the Windows Update Agent.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->classifications() >> / C<< $msg->classifications($value) >>

Type: C<Enum> (L<Google::Cloud::Osconfig::Agentendpoint::V1::WindowsUpdateSettings::Classification>)

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

=head2 Google::Cloud::Osconfig::Agentendpoint::V1::PatchJobs::RetryStrategy

The strategy for retrying failed patches during the patch window.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->enabled() >> / C<< $msg->enabled($value) >>

Type: C<Bool>

If true, the agent will continue to try and patch until the window has
ended.

=back

=head2 Google::Cloud::Osconfig::Agentendpoint::V1::PatchJobs::ExecStep

A step that runs an executable for a PatchJob.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->linux_exec_step_config() >> / C<< $msg->linux_exec_step_config($value) >>

Type: C<Message> (L<Google::Cloud::Osconfig::Agentendpoint::V1::PatchJobs::ExecStepConfig>)

The ExecStepConfig for all Linux VMs targeted by the PatchJob.

=item * C<< $msg->windows_exec_step_config() >> / C<< $msg->windows_exec_step_config($value) >>

Type: C<Message> (L<Google::Cloud::Osconfig::Agentendpoint::V1::PatchJobs::ExecStepConfig>)

The ExecStepConfig for all Windows VMs targeted by the PatchJob.

=back

=head2 Google::Cloud::Osconfig::Agentendpoint::V1::PatchJobs::ExecStepConfig

Common configurations for an ExecStep.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->local_path() >> / C<< $msg->local_path($value) >>

Type: C<String>

An absolute path to the executable on the VM.

=item * C<< $msg->gcs_object() >> / C<< $msg->gcs_object($value) >>

Type: C<Message> (L<Google::Cloud::Osconfig::Agentendpoint::V1::PatchJobs::GcsObject>)

A GCS object containing the executable.

=item * C<< $msg->allowed_success_codes() >> / C<< $msg->allowed_success_codes($value) >>

Type: C<Int32>

Defaults to [0]. A list of possible return values that the
execution can return to indicate a success.

=item * C<< $msg->interpreter() >> / C<< $msg->interpreter($value) >>

Type: C<Enum> (L<Google::Cloud::Osconfig::Agentendpoint::V1::ExecStepConfig::Interpreter>)

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

=head2 Google::Cloud::Osconfig::Agentendpoint::V1::PatchJobs::GcsObject

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

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Osconfig::Agentendpoint::V1::PatchJobs::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
