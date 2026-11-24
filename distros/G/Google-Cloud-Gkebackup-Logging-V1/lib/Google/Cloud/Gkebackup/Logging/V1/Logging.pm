package Google::Cloud::Gkebackup::Logging::V1::Logging;

use strict;
use warnings;

our $VERSION = '0.14';

use Protobuf::Message;
use Protobuf::DescriptorPool;
use Protobuf::Internal qw(:all);
use MIME::Base64;

BEGIN {
    eval { require Google::Cloud::Gkebackup::Logging::V1::LoggedBackup };
    eval { require Google::Cloud::Gkebackup::Logging::V1::LoggedBackupChannel };
    eval { require Google::Cloud::Gkebackup::Logging::V1::LoggedBackupPlan };
    eval { require Google::Cloud::Gkebackup::Logging::V1::LoggedBackupPlanMetadata };
    eval { require Google::Cloud::Gkebackup::Logging::V1::LoggedRestore };
    eval { require Google::Cloud::Gkebackup::Logging::V1::LoggedRestoreChannel };
    eval { require Google::Cloud::Gkebackup::Logging::V1::LoggedRestorePlan };
    eval { require Google::Cloud::Gkebackup::Logging::V1::LoggedRestorePlanMetadata };
    eval { require Google::Protobuf::FieldMask };
    eval { require Google::Rpc::Status };
    my $descriptor_b64 = <<'EOF';
Ci9nb29nbGUvY2xvdWQvZ2tlYmFja3VwL2xvZ2dpbmcvdjEvbG9nZ2luZy5wcm90bxIhZ29v
Z2xlLmNsb3VkLmdrZWJhY2t1cC5sb2dnaW5nLnYxGjVnb29nbGUvY2xvdWQvZ2tlYmFja3Vw
L2xvZ2dpbmcvdjEvbG9nZ2VkX2JhY2t1cC5wcm90bxo9Z29vZ2xlL2Nsb3VkL2drZWJhY2t1
cC9sb2dnaW5nL3YxL2xvZ2dlZF9iYWNrdXBfY2hhbm5lbC5wcm90bxo6Z29vZ2xlL2Nsb3Vk
L2drZWJhY2t1cC9sb2dnaW5nL3YxL2xvZ2dlZF9iYWNrdXBfcGxhbi5wcm90bxpDZ29vZ2xl
L2Nsb3VkL2drZWJhY2t1cC9sb2dnaW5nL3YxL2xvZ2dlZF9iYWNrdXBfcGxhbl9tZXRhZGF0
YS5wcm90bxo2Z29vZ2xlL2Nsb3VkL2drZWJhY2t1cC9sb2dnaW5nL3YxL2xvZ2dlZF9yZXN0
b3JlLnByb3RvGj5nb29nbGUvY2xvdWQvZ2tlYmFja3VwL2xvZ2dpbmcvdjEvbG9nZ2VkX3Jl
c3RvcmVfY2hhbm5lbC5wcm90bxo7Z29vZ2xlL2Nsb3VkL2drZWJhY2t1cC9sb2dnaW5nL3Yx
L2xvZ2dlZF9yZXN0b3JlX3BsYW4ucHJvdG8aRGdvb2dsZS9jbG91ZC9na2ViYWNrdXAvbG9n
Z2luZy92MS9sb2dnZWRfcmVzdG9yZV9wbGFuX21ldGFkYXRhLnByb3RvGiBnb29nbGUvcHJv
dG9idWYvZmllbGRfbWFzay5wcm90bxoXZ29vZ2xlL3JwYy9zdGF0dXMucHJvdG8iugMKEEJh
Y2t1cFBsYW5DaGFuZ2USHwoLYmFja3VwX3BsYW4YASABKAlSCmJhY2t1cFBsYW4STgoLY2hh
bmdlX3R5cGUYAiABKA4yLS5nb29nbGUuY2xvdWQuZ2tlYmFja3VwLmxvZ2dpbmcudjEuQ2hh
bmdlVHlwZVIKY2hhbmdlVHlwZRI7Cgt1cGRhdGVfbWFzaxgDIAEoCzIaLmdvb2dsZS5wcm90
b2J1Zi5GaWVsZE1hc2tSCnVwZGF0ZU1hc2sSXwoRaW5wdXRfYmFja3VwX3BsYW4YBCABKAsy
My5nb29nbGUuY2xvdWQuZ2tlYmFja3VwLmxvZ2dpbmcudjEuTG9nZ2VkQmFja3VwUGxhblIP
aW5wdXRCYWNrdXBQbGFuEigKBWVycm9yGAUgASgLMhIuZ29vZ2xlLnJwYy5TdGF0dXNSBWVy
cm9yEm0KFGJhY2t1cF9wbGFuX21ldGFkYXRhGAYgASgLMjsuZ29vZ2xlLmNsb3VkLmdrZWJh
Y2t1cC5sb2dnaW5nLnYxLkxvZ2dlZEJhY2t1cFBsYW5NZXRhZGF0YVISYmFja3VwUGxhbk1l
dGFkYXRhIs8CCgxCYWNrdXBDaGFuZ2USFgoGYmFja3VwGAEgASgJUgZiYWNrdXASTgoLY2hh
bmdlX3R5cGUYAiABKA4yLS5nb29nbGUuY2xvdWQuZ2tlYmFja3VwLmxvZ2dpbmcudjEuQ2hh
bmdlVHlwZVIKY2hhbmdlVHlwZRIcCglzY2hlZHVsZWQYAyABKAhSCXNjaGVkdWxlZBI7Cgt1
cGRhdGVfbWFzaxgEIAEoCzIaLmdvb2dsZS5wcm90b2J1Zi5GaWVsZE1hc2tSCnVwZGF0ZU1h
c2sSUgoMaW5wdXRfYmFja3VwGAUgASgLMi8uZ29vZ2xlLmNsb3VkLmdrZWJhY2t1cC5sb2dn
aW5nLnYxLkxvZ2dlZEJhY2t1cFILaW5wdXRCYWNrdXASKAoFZXJyb3IYBiABKAsyEi5nb29n
bGUucnBjLlN0YXR1c1IFZXJyb3IiwwMKEVJlc3RvcmVQbGFuQ2hhbmdlEiEKDHJlc3RvcmVf
cGxhbhgBIAEoCVILcmVzdG9yZVBsYW4STgoLY2hhbmdlX3R5cGUYAiABKA4yLS5nb29nbGUu
Y2xvdWQuZ2tlYmFja3VwLmxvZ2dpbmcudjEuQ2hhbmdlVHlwZVIKY2hhbmdlVHlwZRI7Cgt1
cGRhdGVfbWFzaxgDIAEoCzIaLmdvb2dsZS5wcm90b2J1Zi5GaWVsZE1hc2tSCnVwZGF0ZU1h
c2sSYgoSaW5wdXRfcmVzdG9yZV9wbGFuGAQgASgLMjQuZ29vZ2xlLmNsb3VkLmdrZWJhY2t1
cC5sb2dnaW5nLnYxLkxvZ2dlZFJlc3RvcmVQbGFuUhBpbnB1dFJlc3RvcmVQbGFuEigKBWVy
cm9yGAUgASgLMhIuZ29vZ2xlLnJwYy5TdGF0dXNSBWVycm9yEnAKFXJlc3RvcmVfcGxhbl9t
ZXRhZGF0YRgGIAEoCzI8Lmdvb2dsZS5jbG91ZC5na2ViYWNrdXAubG9nZ2luZy52MS5Mb2dn
ZWRSZXN0b3JlUGxhbk1ldGFkYXRhUhNyZXN0b3JlUGxhbk1ldGFkYXRhIrcCCg1SZXN0b3Jl
Q2hhbmdlEhgKB3Jlc3RvcmUYASABKAlSB3Jlc3RvcmUSTgoLY2hhbmdlX3R5cGUYAiABKA4y
LS5nb29nbGUuY2xvdWQuZ2tlYmFja3VwLmxvZ2dpbmcudjEuQ2hhbmdlVHlwZVIKY2hhbmdl
VHlwZRI7Cgt1cGRhdGVfbWFzaxgDIAEoCzIaLmdvb2dsZS5wcm90b2J1Zi5GaWVsZE1hc2tS
CnVwZGF0ZU1hc2sSVQoNaW5wdXRfcmVzdG9yZRgEIAEoCzIwLmdvb2dsZS5jbG91ZC5na2Vi
YWNrdXAubG9nZ2luZy52MS5Mb2dnZWRSZXN0b3JlUgxpbnB1dFJlc3RvcmUSKAoFZXJyb3IY
BSABKAsyEi5nb29nbGUucnBjLlN0YXR1c1IFZXJyb3Ii3QIKE0JhY2t1cENoYW5uZWxDaGFu
Z2USJQoOYmFja3VwX2NoYW5uZWwYASABKAlSDWJhY2t1cENoYW5uZWwSTgoLY2hhbmdlX3R5
cGUYAiABKA4yLS5nb29nbGUuY2xvdWQuZ2tlYmFja3VwLmxvZ2dpbmcudjEuQ2hhbmdlVHlw
ZVIKY2hhbmdlVHlwZRI7Cgt1cGRhdGVfbWFzaxgDIAEoCzIaLmdvb2dsZS5wcm90b2J1Zi5G
aWVsZE1hc2tSCnVwZGF0ZU1hc2sSaAoUaW5wdXRfYmFja3VwX2NoYW5uZWwYBCABKAsyNi5n
b29nbGUuY2xvdWQuZ2tlYmFja3VwLmxvZ2dpbmcudjEuTG9nZ2VkQmFja3VwQ2hhbm5lbFIS
aW5wdXRCYWNrdXBDaGFubmVsEigKBWVycm9yGAUgASgLMhIuZ29vZ2xlLnJwYy5TdGF0dXNS
BWVycm9yIuMCChRSZXN0b3JlQ2hhbm5lbENoYW5nZRInCg9yZXN0b3JlX2NoYW5uZWwYASAB
KAlSDnJlc3RvcmVDaGFubmVsEk4KC2NoYW5nZV90eXBlGAIgASgOMi0uZ29vZ2xlLmNsb3Vk
LmdrZWJhY2t1cC5sb2dnaW5nLnYxLkNoYW5nZVR5cGVSCmNoYW5nZVR5cGUSOwoLdXBkYXRl
X21hc2sYAyABKAsyGi5nb29nbGUucHJvdG9idWYuRmllbGRNYXNrUgp1cGRhdGVNYXNrEmsK
FWlucHV0X3Jlc3RvcmVfY2hhbm5lbBgEIAEoCzI3Lmdvb2dsZS5jbG91ZC5na2ViYWNrdXAu
bG9nZ2luZy52MS5Mb2dnZWRSZXN0b3JlQ2hhbm5lbFITaW5wdXRSZXN0b3JlQ2hhbm5lbBIo
CgVlcnJvchgFIAEoCzISLmdvb2dsZS5ycGMuU3RhdHVzUgVlcnJvcipRCgpDaGFuZ2VUeXBl
EhsKF0NIQU5HRV9UWVBFX1VOU1BFQ0lGSUVEEAASDAoIQ1JFQVRJT04QARIKCgZVUERBVEUQ
AhIMCghERUxFVElPThADQuQBCiFnb29nbGUuY2xvdWQuZ2tlYmFja3VwLmxvZ2dpbmcudjFC
DExvZ2dpbmdQcm90b1ABWj9jbG91ZC5nb29nbGUuY29tL2dvL2drZWJhY2t1cC9sb2dnaW5n
L2FwaXYxL2xvZ2dpbmdwYjtsb2dnaW5ncGKqAiFHb29nbGUuQ2xvdWQuR2tlQmFja3VwLkxv
Z2dpbmcuVjHKAiFHb29nbGVcQ2xvdWRcR2tlQmFja3VwXExvZ2dpbmdcVjHqAiVHb29nbGU6
OkNsb3VkOjpHa2VCYWNrdXA6OkxvZ2dpbmc6OlYxSpcwCgcSBQ4AyAEBCrwECgEMEgMOABIy
sQQgQ29weXJpZ2h0IDIwMjUgR29vZ2xlIExMQwoKIExpY2Vuc2VkIHVuZGVyIHRoZSBBcGFj
aGUgTGljZW5zZSwgVmVyc2lvbiAyLjAgKHRoZSAiTGljZW5zZSIpOwogeW91IG1heSBub3Qg
dXNlIHRoaXMgZmlsZSBleGNlcHQgaW4gY29tcGxpYW5jZSB3aXRoIHRoZSBMaWNlbnNlLgog
WW91IG1heSBvYnRhaW4gYSBjb3B5IG9mIHRoZSBMaWNlbnNlIGF0CgogICAgIGh0dHA6Ly93
d3cuYXBhY2hlLm9yZy9saWNlbnNlcy9MSUNFTlNFLTIuMAoKIFVubGVzcyByZXF1aXJlZCBi
eSBhcHBsaWNhYmxlIGxhdyBvciBhZ3JlZWQgdG8gaW4gd3JpdGluZywgc29mdHdhcmUKIGRp
c3RyaWJ1dGVkIHVuZGVyIHRoZSBMaWNlbnNlIGlzIGRpc3RyaWJ1dGVkIG9uIGFuICJBUyBJ
UyIgQkFTSVMsCiBXSVRIT1VUIFdBUlJBTlRJRVMgT1IgQ09ORElUSU9OUyBPRiBBTlkgS0lO
RCwgZWl0aGVyIGV4cHJlc3Mgb3IgaW1wbGllZC4KIFNlZSB0aGUgTGljZW5zZSBmb3IgdGhl
IHNwZWNpZmljIGxhbmd1YWdlIGdvdmVybmluZyBwZXJtaXNzaW9ucyBhbmQKIGxpbWl0YXRp
b25zIHVuZGVyIHRoZSBMaWNlbnNlLgoKCAoBAhIDEAAqCgkKAgMAEgMSAD8KCQoCAwESAxMA
RwoJCgIDAhIDFABECgkKAgMDEgMVAE0KCQoCAwQSAxYAQAoJCgIDBRIDFwBICgkKAgMGEgMY
AEUKCQoCAwcSAxkATgoJCgIDCBIDGgAqCgkKAgMJEgMbACEKCAoBCBIDHQA+CgkKAgglEgMd
AD4KCAoBCBIDHgBWCgkKAggLEgMeAFYKCAoBCBIDHwAiCgkKAggKEgMfACIKCAoBCBIDIAAt
CgkKAggIEgMgAC0KCAoBCBIDIQA6CgkKAggBEgMhADoKCAoBCBIDIgA/CgkKAggpEgMiAD8K
CAoBCBIDIwA+CgkKAggtEgMjAD4KbAoCBAASBCgAPQEaYCB1c2UgY2FzZSAxCiBBIGxvZyBl
bnRyeSB3aGVuIG1vZGlmaWNhdGlvbihjcmVhdGlvbiwgdXBkYXRlLCBkZWxldGlvbikgaXMg
bWFkZSB0byBhCiBCYWNrdXBQbGFuCgoKCgMEAAESAygIGAq0AQoEBAACABIDLAIZGqYBIFRo
ZSBmdWxsIG5hbWUgb2YgdGhlIG9sZCBCYWNrdXBQbGFuIHJlc291cmNlIHRoYXQgaXMgYmVp
bmcgbW9kaWZpZWQuCiBFbXB0eSBmb3IgY3JlYXRpb24uCiBGb3JtYXQ6IHByb2plY3RzL3tw
cm9qZWN0fS9sb2NhdGlvbnMve2xvY2F0aW9ufS9iYWNrdXBQbGFucy97YmFja3VwX3BsYW59
CgoMCgUEAAIABRIDLAIICgwKBQQAAgABEgMsCRQKDAoFBAACAAMSAywXGAowCgQEAAIBEgMv
Ah0aIyBUeXBlIG9mIHRoZSBjaGFuZ2UgaXMgYmVpbmcgbWFkZS4KCgwKBQQAAgEGEgMvAgwK
DAoFBAACAQESAy8NGAoMCgUEAAIBAxIDLxscCiQKBAQAAgISAzICLBoXIE1vZGlmaWNhdGlv
biBkZXRhaWxzLgoKDAoFBAACAgYSAzICGwoMCgUEAAICARIDMhwnCgwKBQQAAgIDEgMyKisK
cwoEBAACAxIDNgIpGmYgVGhlIGlucHV0IEJhY2t1cFBsYW4gcmVzb3VyY2Ugd2l0aCB0aGUg
dXBkYXRlZCBmaWVsZHMgcG9wdWxhdGVkIHRvIHVwZGF0ZQogdGhlIHNvdXJjZSBCYWNrdXBQ
bGFuIHRvLgoKDAoFBAACAwYSAzYCEgoMCgUEAAIDARIDNhMkCgwKBQQAAgMDEgM2JygKKgoE
BAACBBIDOQIeGh0gVGhlIGVycm9yIGNvZGUgYW5kIG1lc3NhZ2UuCgoMCgUEAAIEBhIDOQIT
CgwKBQQAAgQBEgM5FBkKDAoFBAACBAMSAzkcHQouCgQEAAIFEgM8AjQaISBUaGUgbWV0YWRh
dGEgb2YgdGhlIEJhY2t1cFBsYW4uCgoMCgUEAAIFBhIDPAIaCgwKBQQAAgUBEgM8Gy8KDAoF
BAACBQMSAzwyMwpoCgIEARIEQgBYARpcIHVzZSBjYXNlIDIKIEEgbG9nIGVudHJ5IHdoZW4g
bW9kaWZpY2F0aW9uKGNyZWF0aW9uLCB1cGRhdGUsIGRlbGV0aW9uKSBpcyBtYWRlIHRvIGEK
IEJhY2t1cAoKCgoDBAEBEgNCCBQKqQEKBAQBAgASA0YCFBqbASBUaGUgZnVsbCBuYW1lIG9m
IHRoZSBCYWNrdXAgcmVzb3VyY2UgdGhhdCBpcyBiZWluZyBtb2RpZmllZC4KIEZvcm1hdDoK
IHByb2plY3RzL3twcm9qZWN0fS9sb2NhdGlvbnMve2xvY2F0aW9ufS9iYWNrdXBQbGFucy97
YmFja3VwX3BsYW59L2JhY2t1cHMve2JhY2t1cH0KCgwKBQQBAgAFEgNGAggKDAoFBAECAAES
A0YJDwoMCgUEAQIAAxIDRhITCjAKBAQBAgESA0kCHRojIFR5cGUgb2YgdGhlIGNoYW5nZSBp
cyBiZWluZyBtYWRlLgoKDAoFBAECAQYSA0kCDAoMCgUEAQIBARIDSQ0YCgwKBQQBAgEDEgNJ
GxwKRAoEBAECAhIDTAIVGjcgV2hldGhlciB0aGUgY2hhbmdlIGlzIG1hZGUgbWFudWFsbHkg
b3IgYXV0b21hdGljYWxseS4KCgwKBQQBAgIFEgNMAgYKDAoFBAECAgESA0wHEAoMCgUEAQIC
AxIDTBMUCiQKBAQBAgMSA08CLBoXIE1vZGlmaWNhdGlvbiBkZXRhaWxzLgoKDAoFBAECAwYS
A08CGwoMCgUEAQIDARIDTxwnCgwKBQQBAgMDEgNPKisKqAEKBAQBAgQSA1QCIBqaASBUaGUg
aW5wdXQgQmFja3VwIHJlc291cmNlIHdpdGggdGhlIHVwZGF0ZWQgZmllbGRzIHBvcHVsYXRl
ZCB0byB1cGRhdGUKIHRoZSBzb3VyY2UgQmFja3VwIHRvLCBvciB0aGUgYmFja3VwIGNyZWF0
ZWQgYXV0b21hdGljYWxseSBmcm9tIHJldGVudGlvbgogcG9saWN5LgoKDAoFBAECBAYSA1QC
DgoMCgUEAQIEARIDVA8bCgwKBQQBAgQDEgNUHh8KKgoEBAECBRIDVwIeGh0gVGhlIGVycm9y
IGNvZGUgYW5kIG1lc3NhZ2UuCgoMCgUEAQIFBhIDVwITCgwKBQQBAgUBEgNXFBkKDAoFBAEC
BQMSA1ccHQpuCgIEAhIEXQByARpiIHVzZSBjYXNlIDMKIEEgbG9nIGVudHJ5IHdoZW4gbW9k
aWZpY2F0aW9uKGNyZWF0aW9uLCB1cGRhdGUsIGRlbGV0aW9uKSBpcyBtYWRlIHRvIGEKIHJl
c3RvcmVQbGFuLgoKCgoDBAIBEgNdCBkKlQEKBAQCAgASA2ECGhqHASBUaGUgZnVsbCBuYW1l
IG9mIHRoZSBSZXN0b3JlUGxhbiByZXNvdXJjZSB0aGF0IGlzIGJlaW5nIG1vZGlmaWVkLgog
RW1wdHkgZm9yIGNyZWF0aW9uLgogRm9ybWF0OiBwcm9qZWN0cy8qL2xvY2F0aW9ucy8qL3Jl
c3RvcmVQbGFucy8qCgoMCgUEAgIABRIDYQIICgwKBQQCAgABEgNhCRUKDAoFBAICAAMSA2EY
GQowCgQEAgIBEgNkAh0aIyBUeXBlIG9mIHRoZSBjaGFuZ2UgaXMgYmVpbmcgbWFkZS4KCgwK
BQQCAgEGEgNkAgwKDAoFBAICAQESA2QNGAoMCgUEAgIBAxIDZBscCiQKBAQCAgISA2cCLBoX
IE1vZGlmaWNhdGlvbiBkZXRhaWxzLgoKDAoFBAICAgYSA2cCGwoMCgUEAgICARIDZxwnCgwK
BQQCAgIDEgNnKisKdQoEBAICAxIDawIrGmggVGhlIGlucHV0IFJlc3RvcmVQbGFuIHJlc291
cmNlIHdpdGggdGhlIHVwZGF0ZWQgZmllbGRzIHBvcHVsYXRlZCB0byB1cGRhdGUKIHRoZSBz
b3VyY2UgUmVzdG9yZVBsYW4gdG8uCgoMCgUEAgIDBhIDawITCgwKBQQCAgMBEgNrFCYKDAoF
BAICAwMSA2spKgoqCgQEAgIEEgNuAh4aHSBUaGUgZXJyb3IgY29kZSBhbmQgbWVzc2FnZS4K
CgwKBQQCAgQGEgNuAhMKDAoFBAICBAESA24UGQoMCgUEAgIEAxIDbhwdCi8KBAQCAgUSA3EC
NhoiIFRoZSBtZXRhZGF0YSBvZiB0aGUgUmVzdG9yZVBsYW4uCgoMCgUEAgIFBhIDcQIbCgwK
BQQCAgUBEgNxHDEKDAoFBAICBQMSA3E0NQprCgIEAxIFdwCJAQEaXiB1c2UgY2FzZSA0CiBB
IGxvZyBlbnRyeSB3aGVuIG1vZGlmaWNhdGlvbihjcmVhdGlvbiwgdXBkYXRlLCBkZWxldGlv
bikgaXMgbWFkZSB0byBhCiByZXN0b3JlLgoKCgoDBAMBEgN3CBUKnAEKBAQDAgASA3sCFRqO
ASBUaGUgZnVsbCBuYW1lIG9mIHRoZSBSZXN0b3JlIHJlc291cmNlIHRoYXQgaXMgYmVpbmcg
bW9kaWZpZWQuCiBFbXB0eSBmb3IgY3JlYXRpb24uCiBGb3JtYXQ6IHByb2plY3RzLyovbG9j
YXRpb25zLyovcmVzdG9yZVBsYW5zLyovcmVzdG9yZXMvKgoKDAoFBAMCAAUSA3sCCAoMCgUE
AwIAARIDewkQCgwKBQQDAgADEgN7ExQKMAoEBAMCARIDfgIdGiMgVHlwZSBvZiB0aGUgY2hh
bmdlIGlzIGJlaW5nIG1hZGUuCgoMCgUEAwIBBhIDfgIMCgwKBQQDAgEBEgN+DRgKDAoFBAMC
AQMSA34bHAolCgQEAwICEgSBAQIsGhcgTW9kaWZpY2F0aW9uIGRldGFpbHMuCgoNCgUEAwIC
BhIEgQECGwoNCgUEAwICARIEgQEcJwoNCgUEAwICAxIEgQEqKwpuCgQEAwIDEgSFAQIiGmAg
VGhlIGlucHV0IFJlc3RvcmUgcmVzb3VyY2Ugd2l0aCB0aGUgdXBkYXRlZCBmaWVsZHMgcG9w
dWxhdGVkIHRvIHVwZGF0ZQogdGhlIHNvdXJjZSBSZXN0b3JlIHRvLgoKDQoFBAMCAwYSBIUB
Ag8KDQoFBAMCAwESBIUBEB0KDQoFBAMCAwMSBIUBICEKKwoEBAMCBBIEiAECHhodIFRoZSBl
cnJvciBjb2RlIGFuZCBtZXNzYWdlLgoKDQoFBAMCBAYSBIgBAhMKDQoFBAMCBAESBIgBFBkK
DQoFBAMCBAMSBIgBHB0KcgoCBAQSBo4BAKEBARpkIHVzZSBjYXNlIDUKIEEgbG9nIGVudHJ5
IHdoZW4gbW9kaWZpY2F0aW9uKGNyZWF0aW9uLCB1cGRhdGUsIGRlbGV0aW9uKSBpcyBtYWRl
IHRvIGEKIGJhY2t1cENoYW5uZWwuCgoLCgMEBAESBI4BCBsKuwEKBAQEAgASBJMBAhwarAEg
VGhlIGZ1bGwgbmFtZSBvZiB0aGUgQmFja3VwQ2hhbm5lbCByZXNvdXJjZSB0aGF0IGlzIGJl
aW5nIG1vZGlmaWVkLgogRW1wdHkgZm9yIGNyZWF0aW9uLgogRm9ybWF0OgogcHJvamVjdHMv
e3Byb2plY3R9L2xvY2F0aW9ucy97bG9jYXRpb259L2JhY2t1cENoYW5uZWxzL3tiYWNrdXBf
Y2hhbm5lbH0KCg0KBQQEAgAFEgSTAQIICg0KBQQEAgABEgSTAQkXCg0KBQQEAgADEgSTARob
CjEKBAQEAgESBJYBAh0aIyBUaGUgdHlwZSBvZiBjaGFuZ2UgaXMgYmVpbmcgbWFkZS4KCg0K
BQQEAgEGEgSWAQIMCg0KBQQEAgEBEgSWAQ0YCg0KBQQEAgEDEgSWARscCiUKBAQEAgISBJkB
AiwaFyBNb2RpZmljYXRpb24gZGV0YWlscy4KCg0KBQQEAgIGEgSZAQIbCg0KBQQEAgIBEgSZ
ARwnCg0KBQQEAgIDEgSZASorCnoKBAQEAgMSBJ0BAi8abCBUaGUgaW5wdXQgQmFja3VwQ2hh
bm5lbCByZXNvdXJjZSB3aXRoIHRoZSB1cGRhdGVkIGZpZWxkcyBwb3B1bGF0ZWQgdG8KIHVw
ZGF0ZSB0aGUgc291cmNlIEJhY2t1cENoYW5uZWwgdG8uCgoNCgUEBAIDBhIEnQECFQoNCgUE
BAIDARIEnQEWKgoNCgUEBAIDAxIEnQEtLgorCgQEBAIEEgSgAQIeGh0gVGhlIGVycm9yIGNv
ZGUgYW5kIG1lc3NhZ2UuCgoNCgUEBAIEBhIEoAECEwoNCgUEBAIEARIEoAEUGQoNCgUEBAIE
AxIEoAEcHQpzCgIEBRIGpgEAuQEBGmUgdXNlIGNhc2UgNgogQSBsb2cgZW50cnkgd2hlbiBt
b2RpZmljYXRpb24oY3JlYXRpb24sIHVwZGF0ZSwgZGVsZXRpb24pIGlzIG1hZGUgdG8gYQog
cmVzdG9yZUNoYW5uZWwuCgoLCgMEBQESBKYBCBwKvgEKBAQFAgASBKsBAh0arwEgVGhlIGZ1
bGwgbmFtZSBvZiB0aGUgUmVzdG9yZUNoYW5uZWwgcmVzb3VyY2UgdGhhdCBpcyBiZWluZyBt
b2RpZmllZC4KIEVtcHR5IGZvciBjcmVhdGlvbi4KIEZvcm1hdDoKIHByb2plY3RzL3twcm9q
ZWN0fS9sb2NhdGlvbnMve2xvY2F0aW9ufS9yZXN0b3JlQ2hhbm5lbHMve3Jlc3RvcmVfY2hh
bm5lbH0KCg0KBQQFAgAFEgSrAQIICg0KBQQFAgABEgSrAQkYCg0KBQQFAgADEgSrARscCjEK
BAQFAgESBK4BAh0aIyBUaGUgdHlwZSBvZiBjaGFuZ2UgaXMgYmVpbmcgbWFkZS4KCg0KBQQF
AgEGEgSuAQIMCg0KBQQFAgEBEgSuAQ0YCg0KBQQFAgEDEgSuARscCiUKBAQFAgISBLEBAiwa
FyBNb2RpZmljYXRpb24gZGV0YWlscy4KCg0KBQQFAgIGEgSxAQIbCg0KBQQFAgIBEgSxARwn
Cg0KBQQFAgIDEgSxASorCnwKBAQFAgMSBLUBAjEabiBUaGUgaW5wdXQgUmVzdG9yZUNoYW5u
ZWwgcmVzb3VyY2Ugd2l0aCB0aGUgdXBkYXRlZCBmaWVsZHMgcG9wdWxhdGVkIHRvCiB1cGRh
dGUgdGhlIHNvdXJjZSBSZXN0b3JlQ2hhbm5lbCB0by4KCg0KBQQFAgMGEgS1AQIWCg0KBQQF
AgMBEgS1ARcsCg0KBQQFAgMDEgS1AS8wCisKBAQFAgQSBLgBAh4aHSBUaGUgZXJyb3IgY29k
ZSBhbmQgbWVzc2FnZS4KCg0KBQQFAgQGEgS4AQITCg0KBQQFAgQBEgS4ARQZCg0KBQQFAgQD
EgS4ARwdCjYKAgUAEga8AQDIAQEaKCBUaGUgdHlwZSBvZiBjaGFuZ2VzIHRoaXMgbG9nIGlz
IGFib3V0LgoKCwoDBQABEgS8AQUPCi0KBAUAAgASBL4BAh4aHyBEZWZhdWx0IHZhbHVlLCBu
b3Qgc3BlY2lmaWVkLgoKDQoFBQACAAESBL4BAhkKDQoFBQACAAISBL4BHB0KKAoEBQACARIE
wQECDxoaIFRoZSByZXNvdXJjZSBpcyBjcmVhdGVkLgoKDQoFBQACAQESBMEBAgoKDQoFBQAC
AQISBMEBDQ4KKAoEBQACAhIExAECDRoaIFRoZSByZXNvdXJjZSBpcyB1cGRhdGVkLgoKDQoF
BQACAgESBMQBAggKDQoFBQACAgISBMQBCwwKKAoEBQACAxIExwECDxoaIFRoZSByZXNvdXJj
ZSBpcyBkZWxldGVkLgoKDQoFBQACAwESBMcBAgoKDQoFBQACAwISBMcBDQ5iBnByb3RvMw==

EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Gkebackup::Logging::V1::Logging::BackupPlanChange ===
    # Fields for BackupPlanChange
    # Field: backup_plan Type: 9 ()
    # Field: change_type Type: 14 (.google.cloud.gkebackup.logging.v1.ChangeType)
    # Field: update_mask Type: 11 (.google.protobuf.FieldMask)
    # Field: input_backup_plan Type: 11 (.google.cloud.gkebackup.logging.v1.LoggedBackupPlan)
    # Field: error Type: 11 (.google.rpc.Status)
    # Field: backup_plan_metadata Type: 11 (.google.cloud.gkebackup.logging.v1.LoggedBackupPlanMetadata)

# === Message: Google::Cloud::Gkebackup::Logging::V1::Logging::BackupChange ===
    # Fields for BackupChange
    # Field: backup Type: 9 ()
    # Field: change_type Type: 14 (.google.cloud.gkebackup.logging.v1.ChangeType)
    # Field: scheduled Type: 8 ()
    # Field: update_mask Type: 11 (.google.protobuf.FieldMask)
    # Field: input_backup Type: 11 (.google.cloud.gkebackup.logging.v1.LoggedBackup)
    # Field: error Type: 11 (.google.rpc.Status)

# === Message: Google::Cloud::Gkebackup::Logging::V1::Logging::RestorePlanChange ===
    # Fields for RestorePlanChange
    # Field: restore_plan Type: 9 ()
    # Field: change_type Type: 14 (.google.cloud.gkebackup.logging.v1.ChangeType)
    # Field: update_mask Type: 11 (.google.protobuf.FieldMask)
    # Field: input_restore_plan Type: 11 (.google.cloud.gkebackup.logging.v1.LoggedRestorePlan)
    # Field: error Type: 11 (.google.rpc.Status)
    # Field: restore_plan_metadata Type: 11 (.google.cloud.gkebackup.logging.v1.LoggedRestorePlanMetadata)

# === Message: Google::Cloud::Gkebackup::Logging::V1::Logging::RestoreChange ===
    # Fields for RestoreChange
    # Field: restore Type: 9 ()
    # Field: change_type Type: 14 (.google.cloud.gkebackup.logging.v1.ChangeType)
    # Field: update_mask Type: 11 (.google.protobuf.FieldMask)
    # Field: input_restore Type: 11 (.google.cloud.gkebackup.logging.v1.LoggedRestore)
    # Field: error Type: 11 (.google.rpc.Status)

# === Message: Google::Cloud::Gkebackup::Logging::V1::Logging::BackupChannelChange ===
    # Fields for BackupChannelChange
    # Field: backup_channel Type: 9 ()
    # Field: change_type Type: 14 (.google.cloud.gkebackup.logging.v1.ChangeType)
    # Field: update_mask Type: 11 (.google.protobuf.FieldMask)
    # Field: input_backup_channel Type: 11 (.google.cloud.gkebackup.logging.v1.LoggedBackupChannel)
    # Field: error Type: 11 (.google.rpc.Status)

# === Message: Google::Cloud::Gkebackup::Logging::V1::Logging::RestoreChannelChange ===
    # Fields for RestoreChannelChange
    # Field: restore_channel Type: 9 ()
    # Field: change_type Type: 14 (.google.cloud.gkebackup.logging.v1.ChangeType)
    # Field: update_mask Type: 11 (.google.protobuf.FieldMask)
    # Field: input_restore_channel Type: 11 (.google.cloud.gkebackup.logging.v1.LoggedRestoreChannel)
    # Field: error Type: 11 (.google.rpc.Status)

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Gkebackup::Logging::V1::Logging - Compiled Protocol Buffers messages for google/cloud/gkebackup/logging/v1/logging.proto

=head1 SYNOPSIS

    use Google::Cloud::Gkebackup::Logging::V1::Logging;

    my $msg = Google::Cloud::Gkebackup::Logging::V1::Logging::BackupPlanChange->new({
        backup_plan => $backup_plan,
        change_type => $change_type,
        update_mask => $update_mask,
        input_backup_plan => $input_backup_plan,
    });

    # Read or update a field
    my $val = $msg->backup_plan();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Gkebackup::Logging::V1::Logging::BackupPlanChange->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/gkebackup/logging/v1/logging.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Gkebackup::Logging::V1::Logging::BackupPlanChange

use case 1
A log entry when modification(creation, update, deletion) is made to a
BackupPlan

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->backup_plan() >> / C<< $msg->backup_plan($value) >>

Type: C<String>

The full name of the old BackupPlan resource that is being modified.
Empty for creation.
Format: projects/{project}/locations/{location}/backupPlans/{backup_plan}

=item * C<< $msg->change_type() >> / C<< $msg->change_type($value) >>

Type: C<Enum> (L<Google::Cloud::Gkebackup::Logging::V1::ChangeType>)

Type of the change is being made.

=item * C<< $msg->update_mask() >> / C<< $msg->update_mask($value) >>

Type: C<Message> (L<Google::Protobuf::FieldMask::FieldMask>)

Modification details.

=item * C<< $msg->input_backup_plan() >> / C<< $msg->input_backup_plan($value) >>

Type: C<Message> (L<Google::Cloud::Gkebackup::Logging::V1::LoggedBackupPlan::LoggedBackupPlan>)

The input BackupPlan resource with the updated fields populated to update
the source BackupPlan to.

=item * C<< $msg->error() >> / C<< $msg->error($value) >>

Type: C<Message> (L<Google::Rpc::Status::Status>)

The error code and message.

=item * C<< $msg->backup_plan_metadata() >> / C<< $msg->backup_plan_metadata($value) >>

Type: C<Message> (L<Google::Cloud::Gkebackup::Logging::V1::LoggedBackupPlanMetadata::LoggedBackupPlanMetadata>)

The metadata of the BackupPlan.

=back

=head2 Google::Cloud::Gkebackup::Logging::V1::Logging::BackupChange

use case 2
A log entry when modification(creation, update, deletion) is made to a
Backup

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->backup() >> / C<< $msg->backup($value) >>

Type: C<String>

The full name of the Backup resource that is being modified.
Format:
projects/{project}/locations/{location}/backupPlans/{backup_plan}/backups/{backup}

=item * C<< $msg->change_type() >> / C<< $msg->change_type($value) >>

Type: C<Enum> (L<Google::Cloud::Gkebackup::Logging::V1::ChangeType>)

Type of the change is being made.

=item * C<< $msg->scheduled() >> / C<< $msg->scheduled($value) >>

Type: C<Bool>

Whether the change is made manually or automatically.

=item * C<< $msg->update_mask() >> / C<< $msg->update_mask($value) >>

Type: C<Message> (L<Google::Protobuf::FieldMask::FieldMask>)

Modification details.

=item * C<< $msg->input_backup() >> / C<< $msg->input_backup($value) >>

Type: C<Message> (L<Google::Cloud::Gkebackup::Logging::V1::LoggedBackup::LoggedBackup>)

The input Backup resource with the updated fields populated to update
the source Backup to, or the backup created automatically from retention
policy.

=item * C<< $msg->error() >> / C<< $msg->error($value) >>

Type: C<Message> (L<Google::Rpc::Status::Status>)

The error code and message.

=back

=head2 Google::Cloud::Gkebackup::Logging::V1::Logging::RestorePlanChange

use case 3
A log entry when modification(creation, update, deletion) is made to a
restorePlan.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->restore_plan() >> / C<< $msg->restore_plan($value) >>

Type: C<String>

The full name of the RestorePlan resource that is being modified.
Empty for creation.
Format: projects/*/locations/*/restorePlans/*

=item * C<< $msg->change_type() >> / C<< $msg->change_type($value) >>

Type: C<Enum> (L<Google::Cloud::Gkebackup::Logging::V1::ChangeType>)

Type of the change is being made.

=item * C<< $msg->update_mask() >> / C<< $msg->update_mask($value) >>

Type: C<Message> (L<Google::Protobuf::FieldMask::FieldMask>)

Modification details.

=item * C<< $msg->input_restore_plan() >> / C<< $msg->input_restore_plan($value) >>

Type: C<Message> (L<Google::Cloud::Gkebackup::Logging::V1::LoggedRestorePlan::LoggedRestorePlan>)

The input RestorePlan resource with the updated fields populated to update
the source RestorePlan to.

=item * C<< $msg->error() >> / C<< $msg->error($value) >>

Type: C<Message> (L<Google::Rpc::Status::Status>)

The error code and message.

=item * C<< $msg->restore_plan_metadata() >> / C<< $msg->restore_plan_metadata($value) >>

Type: C<Message> (L<Google::Cloud::Gkebackup::Logging::V1::LoggedRestorePlanMetadata::LoggedRestorePlanMetadata>)

The metadata of the RestorePlan.

=back

=head2 Google::Cloud::Gkebackup::Logging::V1::Logging::RestoreChange

use case 4
A log entry when modification(creation, update, deletion) is made to a
restore.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->restore() >> / C<< $msg->restore($value) >>

Type: C<String>

The full name of the Restore resource that is being modified.
Empty for creation.
Format: projects/*/locations/*/restorePlans/*/restores/*

=item * C<< $msg->change_type() >> / C<< $msg->change_type($value) >>

Type: C<Enum> (L<Google::Cloud::Gkebackup::Logging::V1::ChangeType>)

Type of the change is being made.

=item * C<< $msg->update_mask() >> / C<< $msg->update_mask($value) >>

Type: C<Message> (L<Google::Protobuf::FieldMask::FieldMask>)

Modification details.

=item * C<< $msg->input_restore() >> / C<< $msg->input_restore($value) >>

Type: C<Message> (L<Google::Cloud::Gkebackup::Logging::V1::LoggedRestore::LoggedRestore>)

The input Restore resource with the updated fields populated to update
the source Restore to.

=item * C<< $msg->error() >> / C<< $msg->error($value) >>

Type: C<Message> (L<Google::Rpc::Status::Status>)

The error code and message.

=back

=head2 Google::Cloud::Gkebackup::Logging::V1::Logging::BackupChannelChange

use case 5
A log entry when modification(creation, update, deletion) is made to a
backupChannel.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->backup_channel() >> / C<< $msg->backup_channel($value) >>

Type: C<String>

The full name of the BackupChannel resource that is being modified.
Empty for creation.
Format:
projects/{project}/locations/{location}/backupChannels/{backup_channel}

=item * C<< $msg->change_type() >> / C<< $msg->change_type($value) >>

Type: C<Enum> (L<Google::Cloud::Gkebackup::Logging::V1::ChangeType>)

The type of change is being made.

=item * C<< $msg->update_mask() >> / C<< $msg->update_mask($value) >>

Type: C<Message> (L<Google::Protobuf::FieldMask::FieldMask>)

Modification details.

=item * C<< $msg->input_backup_channel() >> / C<< $msg->input_backup_channel($value) >>

Type: C<Message> (L<Google::Cloud::Gkebackup::Logging::V1::LoggedBackupChannel::LoggedBackupChannel>)

The input BackupChannel resource with the updated fields populated to
update the source BackupChannel to.

=item * C<< $msg->error() >> / C<< $msg->error($value) >>

Type: C<Message> (L<Google::Rpc::Status::Status>)

The error code and message.

=back

=head2 Google::Cloud::Gkebackup::Logging::V1::Logging::RestoreChannelChange

use case 6
A log entry when modification(creation, update, deletion) is made to a
restoreChannel.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->restore_channel() >> / C<< $msg->restore_channel($value) >>

Type: C<String>

The full name of the RestoreChannel resource that is being modified.
Empty for creation.
Format:
projects/{project}/locations/{location}/restoreChannels/{restore_channel}

=item * C<< $msg->change_type() >> / C<< $msg->change_type($value) >>

Type: C<Enum> (L<Google::Cloud::Gkebackup::Logging::V1::ChangeType>)

The type of change is being made.

=item * C<< $msg->update_mask() >> / C<< $msg->update_mask($value) >>

Type: C<Message> (L<Google::Protobuf::FieldMask::FieldMask>)

Modification details.

=item * C<< $msg->input_restore_channel() >> / C<< $msg->input_restore_channel($value) >>

Type: C<Message> (L<Google::Cloud::Gkebackup::Logging::V1::LoggedRestoreChannel::LoggedRestoreChannel>)

The input RestoreChannel resource with the updated fields populated to
update the source RestoreChannel to.

=item * C<< $msg->error() >> / C<< $msg->error($value) >>

Type: C<Message> (L<Google::Rpc::Status::Status>)

The error code and message.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Gkebackup::Logging::V1::Logging::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
