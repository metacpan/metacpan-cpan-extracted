package Google::Cloud::Video::Livestream::Logging::V1::Logs;

use strict;
use warnings;

our $VERSION = '0.14';

use Protobuf::Message;
use Protobuf::DescriptorPool;
use Protobuf::Internal qw(:all);
use MIME::Base64;

BEGIN {
    eval { require Google::Cloud::Video::Livestream::V1::Resources };
    eval { require Google::Rpc::Status };
    my $descriptor_b64 = <<'EOF';
CjNnb29nbGUvY2xvdWQvdmlkZW8vbGl2ZXN0cmVhbS9sb2dnaW5nL3YxL2xvZ3MucHJvdG8S
KGdvb2dsZS5jbG91ZC52aWRlby5saXZlc3RyZWFtLmxvZ2dpbmcudjEaMGdvb2dsZS9jbG91
ZC92aWRlby9saXZlc3RyZWFtL3YxL3Jlc291cmNlcy5wcm90bxoXZ29vZ2xlL3JwYy9zdGF0
dXMucHJvdG8ilQYKD0NoYW5uZWxBY3Rpdml0eRIYCgdtZXNzYWdlGAEgASgJUgdtZXNzYWdl
EnYKFnN0cmVhbWluZ19zdGF0ZV9jaGFuZ2UYAiABKAsyPi5nb29nbGUuY2xvdWQudmlkZW8u
bGl2ZXN0cmVhbS5sb2dnaW5nLnYxLlN0cmVhbWluZ1N0YXRlQ2hhbmdlSABSFHN0cmVhbWlu
Z1N0YXRlQ2hhbmdlEmMKD3N0cmVhbWluZ19lcnJvchgDIAEoCzI4Lmdvb2dsZS5jbG91ZC52
aWRlby5saXZlc3RyZWFtLmxvZ2dpbmcudjEuU3RyZWFtaW5nRXJyb3JIAFIOc3RyZWFtaW5n
RXJyb3ISWgoMaW5wdXRfYWNjZXB0GAQgASgLMjUuZ29vZ2xlLmNsb3VkLnZpZGVvLmxpdmVz
dHJlYW0ubG9nZ2luZy52MS5JbnB1dEFjY2VwdEgAUgtpbnB1dEFjY2VwdBJXCgtpbnB1dF9l
cnJvchgFIAEoCzI0Lmdvb2dsZS5jbG91ZC52aWRlby5saXZlc3RyZWFtLmxvZ2dpbmcudjEu
SW5wdXRFcnJvckgAUgppbnB1dEVycm9yEmYKEGlucHV0X2Rpc2Nvbm5lY3QYBiABKAsyOS5n
b29nbGUuY2xvdWQudmlkZW8ubGl2ZXN0cmVhbS5sb2dnaW5nLnYxLklucHV0RGlzY29ubmVj
dEgAUg9pbnB1dERpc2Nvbm5lY3QSagoSZXZlbnRfc3RhdGVfY2hhbmdlGAcgASgLMjouZ29v
Z2xlLmNsb3VkLnZpZGVvLmxpdmVzdHJlYW0ubG9nZ2luZy52MS5FdmVudFN0YXRlQ2hhbmdl
SABSEGV2ZW50U3RhdGVDaGFuZ2UScQoXc2N0ZTM1X2NvbW1hbmRfcmVjZWl2ZWQYCCABKAsy
Ny5nb29nbGUuY2xvdWQudmlkZW8ubGl2ZXN0cmVhbS5sb2dnaW5nLnYxLlNjdGUzNUNvbW1h
bmRIAFIVc2N0ZTM1Q29tbWFuZFJlY2VpdmVkQg8KDWFjdGl2aXR5X3R5cGUizgEKFFN0cmVh
bWluZ1N0YXRlQ2hhbmdlElUKCW5ld19zdGF0ZRgBIAEoDjI4Lmdvb2dsZS5jbG91ZC52aWRl
by5saXZlc3RyZWFtLnYxLkNoYW5uZWwuU3RyZWFtaW5nU3RhdGVSCG5ld1N0YXRlEl8KDnBy
ZXZpb3VzX3N0YXRlGAIgASgOMjguZ29vZ2xlLmNsb3VkLnZpZGVvLmxpdmVzdHJlYW0udjEu
Q2hhbm5lbC5TdHJlYW1pbmdTdGF0ZVINcHJldmlvdXNTdGF0ZSI6Cg5TdHJlYW1pbmdFcnJv
chIoCgVlcnJvchgBIAEoCzISLmdvb2dsZS5ycGMuU3RhdHVzUgVlcnJvciLIAQoLSW5wdXRB
Y2NlcHQSGwoJc3RyZWFtX2lkGAEgASgJUghzdHJlYW1JZBIpChBpbnB1dF9hdHRhY2htZW50
GAIgASgJUg9pbnB1dEF0dGFjaG1lbnQScQoVaW5wdXRfc3RyZWFtX3Byb3BlcnR5GAMgASgL
Mj0uZ29vZ2xlLmNsb3VkLnZpZGVvLmxpdmVzdHJlYW0ubG9nZ2luZy52MS5JbnB1dFN0cmVh
bVByb3BlcnR5UhNpbnB1dFN0cmVhbVByb3BlcnR5IvEBCgpJbnB1dEVycm9yEhsKCXN0cmVh
bV9pZBgBIAEoCVIIc3RyZWFtSWQSKQoQaW5wdXRfYXR0YWNobWVudBgCIAEoCVIPaW5wdXRB
dHRhY2htZW50EnEKFWlucHV0X3N0cmVhbV9wcm9wZXJ0eRgDIAEoCzI9Lmdvb2dsZS5jbG91
ZC52aWRlby5saXZlc3RyZWFtLmxvZ2dpbmcudjEuSW5wdXRTdHJlYW1Qcm9wZXJ0eVITaW5w
dXRTdHJlYW1Qcm9wZXJ0eRIoCgVlcnJvchgEIAEoCzISLmdvb2dsZS5ycGMuU3RhdHVzUgVl
cnJvciLNAQoTSW5wdXRTdHJlYW1Qcm9wZXJ0eRJaCg12aWRlb19zdHJlYW1zGAEgAygLMjUu
Z29vZ2xlLmNsb3VkLnZpZGVvLmxpdmVzdHJlYW0ubG9nZ2luZy52MS5WaWRlb1N0cmVhbVIM
dmlkZW9TdHJlYW1zEloKDWF1ZGlvX3N0cmVhbXMYAiADKAsyNS5nb29nbGUuY2xvdWQudmlk
ZW8ubGl2ZXN0cmVhbS5sb2dnaW5nLnYxLkF1ZGlvU3RyZWFtUgxhdWRpb1N0cmVhbXMifQoL
VmlkZW9TdHJlYW0SFAoFaW5kZXgYASABKAVSBWluZGV4ElgKDHZpZGVvX2Zvcm1hdBgCIAEo
CzI1Lmdvb2dsZS5jbG91ZC52aWRlby5saXZlc3RyZWFtLmxvZ2dpbmcudjEuVmlkZW9Gb3Jt
YXRSC3ZpZGVvRm9ybWF0IooBCgtWaWRlb0Zvcm1hdBIUCgVjb2RlYxgBIAEoCVIFY29kZWMS
IQoMd2lkdGhfcGl4ZWxzGAIgASgFUgt3aWR0aFBpeGVscxIjCg1oZWlnaHRfcGl4ZWxzGAMg
ASgFUgxoZWlnaHRQaXhlbHMSHQoKZnJhbWVfcmF0ZRgEIAEoAVIJZnJhbWVSYXRlIn0KC0F1
ZGlvU3RyZWFtEhQKBWluZGV4GAEgASgFUgVpbmRleBJYCgxhdWRpb19mb3JtYXQYAiABKAsy
NS5nb29nbGUuY2xvdWQudmlkZW8ubGl2ZXN0cmVhbS5sb2dnaW5nLnYxLkF1ZGlvRm9ybWF0
UgthdWRpb0Zvcm1hdCJvCgtBdWRpb0Zvcm1hdBIUCgVjb2RlYxgBIAEoCVIFY29kZWMSIwoN
Y2hhbm5lbF9jb3VudBgCIAEoBVIMY2hhbm5lbENvdW50EiUKDmNoYW5uZWxfbGF5b3V0GAMg
AygJUg1jaGFubmVsTGF5b3V0IlkKD0lucHV0RGlzY29ubmVjdBIbCglzdHJlYW1faWQYASAB
KAlSCHN0cmVhbUlkEikKEGlucHV0X2F0dGFjaG1lbnQYAiABKAlSD2lucHV0QXR0YWNobWVu
dCLPAQoQRXZlbnRTdGF0ZUNoYW5nZRIZCghldmVudF9pZBgBIAEoCVIHZXZlbnRJZBJKCglu
ZXdfc3RhdGUYAiABKA4yLS5nb29nbGUuY2xvdWQudmlkZW8ubGl2ZXN0cmVhbS52MS5FdmVu
dC5TdGF0ZVIIbmV3U3RhdGUSVAoOcHJldmlvdXNfc3RhdGUYAyABKA4yLS5nb29nbGUuY2xv
dWQudmlkZW8ubGl2ZXN0cmVhbS52MS5FdmVudC5TdGF0ZVINcHJldmlvdXNTdGF0ZSKACwoN
U2N0ZTM1Q29tbWFuZBJ5ChNzcGxpY2VfaW5mb19zZWN0aW9uGAEgASgLMkkuZ29vZ2xlLmNs
b3VkLnZpZGVvLmxpdmVzdHJlYW0ubG9nZ2luZy52MS5TY3RlMzVDb21tYW5kLlNwbGljZUlu
Zm9TZWN0aW9uUhFzcGxpY2VJbmZvU2VjdGlvbhpXCgpTcGxpY2VUaW1lEi4KE3RpbWVfc3Bl
Y2lmaWVkX2ZsYWcYASABKAhSEXRpbWVTcGVjaWZpZWRGbGFnEhkKCHB0c190aW1lGAIgASgD
UgdwdHNUaW1lGkwKDUJyZWFrRHVyYXRpb24SHwoLYXV0b19yZXR1cm4YASABKAhSCmF1dG9S
ZXR1cm4SGgoIZHVyYXRpb24YAiABKANSCGR1cmF0aW9uGpUBCglDb21wb25lbnQSIwoNY29t
cG9uZW50X3RhZxgBIAEoBVIMY29tcG9uZW50VGFnEmMKC3NwbGljZV90aW1lGAIgASgLMkIu
Z29vZ2xlLmNsb3VkLnZpZGVvLmxpdmVzdHJlYW0ubG9nZ2luZy52MS5TY3RlMzVDb21tYW5k
LlNwbGljZVRpbWVSCnNwbGljZVRpbWUajAYKDFNwbGljZUluc2VydBImCg9zcGxpY2VfZXZl
bnRfaWQYASABKAVSDXNwbGljZUV2ZW50SWQSQQodc3BsaWNlX2V2ZW50X2NhbmNlbF9pbmRp
Y2F0b3IYAiABKAhSGnNwbGljZUV2ZW50Q2FuY2VsSW5kaWNhdG9yEjcKGG91dF9vZl9uZXR3
b3JrX2luZGljYXRvchgDIAEoCFIVb3V0T2ZOZXR3b3JrSW5kaWNhdG9yEi4KE3Byb2dyYW1f
c3BsaWNlX2ZsYWcYBCABKAhSEXByb2dyYW1TcGxpY2VGbGFnEiMKDWR1cmF0aW9uX2ZsYWcY
BSABKAhSDGR1cmF0aW9uRmxhZxIyChVzcGxpY2VfaW1tZWRpYXRlX2ZsYWcYBiABKAhSE3Nw
bGljZUltbWVkaWF0ZUZsYWcSYwoLc3BsaWNlX3RpbWUYByABKAsyQi5nb29nbGUuY2xvdWQu
dmlkZW8ubGl2ZXN0cmVhbS5sb2dnaW5nLnYxLlNjdGUzNUNvbW1hbmQuU3BsaWNlVGltZVIK
c3BsaWNlVGltZRJsCg5icmVha19kdXJhdGlvbhgIIAEoCzJFLmdvb2dsZS5jbG91ZC52aWRl
by5saXZlc3RyZWFtLmxvZ2dpbmcudjEuU2N0ZTM1Q29tbWFuZC5CcmVha0R1cmF0aW9uUg1i
cmVha0R1cmF0aW9uEioKEXVuaXF1ZV9wcm9ncmFtX2lkGAkgASgFUg91bmlxdWVQcm9ncmFt
SWQSGwoJYXZhaWxfbnVtGAogASgFUghhdmFpbE51bRInCg9hdmFpbHNfZXhwZWN0ZWQYCyAB
KAVSDmF2YWlsc0V4cGVjdGVkEicKD2NvbXBvbmVudF9jb3VudBgMIAEoBVIOY29tcG9uZW50
Q291bnQSYQoKY29tcG9uZW50cxgNIAMoCzJBLmdvb2dsZS5jbG91ZC52aWRlby5saXZlc3Ry
ZWFtLmxvZ2dpbmcudjEuU2N0ZTM1Q29tbWFuZC5Db21wb25lbnRSCmNvbXBvbmVudHMapQEK
EVNwbGljZUluZm9TZWN0aW9uEiUKDnB0c19hZGp1c3RtZW50GAEgASgDUg1wdHNBZGp1c3Rt
ZW50EmkKDXNwbGljZV9pbnNlcnQYAiABKAsyRC5nb29nbGUuY2xvdWQudmlkZW8ubGl2ZXN0
cmVhbS5sb2dnaW5nLnYxLlNjdGUzNUNvbW1hbmQuU3BsaWNlSW5zZXJ0UgxzcGxpY2VJbnNl
cnRCgwEKLGNvbS5nb29nbGUuY2xvdWQudmlkZW8ubGl2ZXN0cmVhbS5sb2dnaW5nLnYxQglM
b2dzUHJvdG9QAVpGY2xvdWQuZ29vZ2xlLmNvbS9nby92aWRlby9saXZlc3RyZWFtL2xvZ2dp
bmcvYXBpdjEvbG9nZ2luZ3BiO2xvZ2dpbmdwYkrxQgoHEgUOAIQCAQq8BAoBDBIDDgASMrEE
IENvcHlyaWdodCAyMDI1IEdvb2dsZSBMTEMKCiBMaWNlbnNlZCB1bmRlciB0aGUgQXBhY2hl
IExpY2Vuc2UsIFZlcnNpb24gMi4wICh0aGUgIkxpY2Vuc2UiKTsKIHlvdSBtYXkgbm90IHVz
ZSB0aGlzIGZpbGUgZXhjZXB0IGluIGNvbXBsaWFuY2Ugd2l0aCB0aGUgTGljZW5zZS4KIFlv
dSBtYXkgb2J0YWluIGEgY29weSBvZiB0aGUgTGljZW5zZSBhdAoKICAgICBodHRwOi8vd3d3
LmFwYWNoZS5vcmcvbGljZW5zZXMvTElDRU5TRS0yLjAKCiBVbmxlc3MgcmVxdWlyZWQgYnkg
YXBwbGljYWJsZSBsYXcgb3IgYWdyZWVkIHRvIGluIHdyaXRpbmcsIHNvZnR3YXJlCiBkaXN0
cmlidXRlZCB1bmRlciB0aGUgTGljZW5zZSBpcyBkaXN0cmlidXRlZCBvbiBhbiAiQVMgSVMi
IEJBU0lTLAogV0lUSE9VVCBXQVJSQU5USUVTIE9SIENPTkRJVElPTlMgT0YgQU5ZIEtJTkQs
IGVpdGhlciBleHByZXNzIG9yIGltcGxpZWQuCiBTZWUgdGhlIExpY2Vuc2UgZm9yIHRoZSBz
cGVjaWZpYyBsYW5ndWFnZSBnb3Zlcm5pbmcgcGVybWlzc2lvbnMgYW5kCiBsaW1pdGF0aW9u
cyB1bmRlciB0aGUgTGljZW5zZS4KCggKAQISAxAAMQoJCgIDABIDEgA6CgkKAgMBEgMTACEK
CAoBCBIDFQBdCgkKAggLEgMVAF0KCAoBCBIDFgAiCgkKAggKEgMWACIKCAoBCBIDFwAqCgkK
AggIEgMXACoKCAoBCBIDGABFCgkKAggBEgMYAEUKOQoCBAASBBsANgEaLSBMb2dzIG9mIGFj
dGl2aXRpZXMgcmVsYXRlZCB0byB0aGUgQ2hhbm5lbHMuCgoKCgMEAAESAxsIFwpQCgQEAAIA
EgMdAhUaQyBNZXNzYWdlIGlzIGZvciBtb3JlIGRldGFpbHMgb2YgdGhlIGxvZyBhbmQgaW5z
dHJ1Y3Rpb25zIHRvIHVzZXJzLgoKDAoFBAACAAUSAx0CCAoMCgUEAAIAARIDHQkQCgwKBQQA
AgADEgMdExQKLAoEBAAIABIEIAI1AxoeIERpZmZlcmVudCB0eXBlcyBvZiB0aGUgbG9ncy4K
CgwKBQQACAABEgMgCBUKMwoEBAACARIDIgQ0GiYgVGhlIGNoYW5uZWwgc3RyZWFtaW5nIHN0
YXRlIGNoYW5nZXMuCgoMCgUEAAIBBhIDIgQYCgwKBQQAAgEBEgMiGS8KDAoFBAACAQMSAyIy
Mwo4CgQEAAICEgMlBCcaKyBBbiBlcnJvciBoYXBwZW5zIHdpdGggdGhlIHZpZGVvIHBpcGVs
aW5lLgoKDAoFBAACAgYSAyUEEgoMCgUEAAICARIDJRMiCgwKBQQAAgIDEgMlJSYKOAoEBAAC
AxIDKAQhGisgVGhlIGNoYW5uZWwgaGFzIGFjY2VwdGVkIGFuIGlucHV0IHN0cmVhbS4KCgwK
BQQAAgMGEgMoBA8KDAoFBAACAwESAygQHAoMCgUEAAIDAxIDKB8gCjYKBAQAAgQSAysEHxop
IEFuIGVycm9yIGhhcHBlbnMgd2l0aCB0aGUgaW5wdXQgc3RyZWFtLgoKDAoFBAACBAYSAysE
DgoMCgUEAAIEARIDKw8aCgwKBQQAAgQDEgMrHR4KKwoEBAACBRIDLgQpGh4gQW4gaW5wdXQg
c3RyZWFtIGRpc2Nvbm5lY3RzLgoKDAoFBAACBQYSAy4EEwoMCgUEAAIFARIDLhQkCgwKBQQA
AgUDEgMuJygKJgoEBAACBhIDMQQsGhkgQW4gZXZlbnQgc3RhdGUgY2hhbmdlcy4KCgwKBQQA
AgYGEgMxBBQKDAoFBAACBgESAzEVJwoMCgUEAAIGAxIDMSorCiwKBAQAAgcSAzQELhofIEEg
U0NURTM1IGNvbW1hbmQgaXMgcmVjZWl2ZWQuCgoMCgUEAAIHBhIDNAQRCgwKBQQAAgcBEgM0
EikKDAoFBAACBwMSAzQsLQpUCgIEARIEOQA/ARpIIFN0cmVhbWluZ1N0YXRlQ2hhbmdlIHJl
Y29yZHMgd2hlbiB0aGUgY2hhbm5lbCBzdHJlYW1pbmcgc3RhdGUgY2hhbmdlcy4KCgoKAwQB
ARIDOQgcCjIKBAQBAgASAzsCSBolIE5ldyBzdHJlYW1pbmcgc3RhdGUgb2YgdGhlIGNoYW5u
ZWwuCgoMCgUEAQIABhIDOwI5CgwKBQQBAgABEgM7OkMKDAoFBAECAAMSAztGRwo3CgQEAQIB
EgM+Ak0aKiBQcmV2aW91cyBzdHJlYW1pbmcgc3RhdGUgb2YgdGhlIGNoYW5uZWwuCgoMCgUE
AQIBBhIDPgI5CgwKBQQBAgEBEgM+OkgKDAoFBAECAQMSAz5LTApTCgIEAhIEQgBFARpHIFN0
cmVhbWluZ0Vycm9yIHJlY29yZHMgd2hlbiBhbiBlcnJvciBoYXBwZW5zIHdpdGggdGhlIHZp
ZGVvIHBpcGVsaW5lLgoKCgoDBAIBEgNCCBYKQwoEBAICABIDRAIeGjYgQSBkZXNjcmlwdGlv
biBvZiB0aGUgcmVhc29uIGZvciB0aGUgc3RyZWFtaW5nIGVycm9yLgoKDAoFBAICAAYSA0QC
EwoMCgUEAgIAARIDRBQZCgwKBQQCAgADEgNEHB0KUAoCBAMSBEgAUQEaRCBJbnB1dEFjY2Vw
dCByZWNvcmRzIHdoZW4gdGhlIGNoYW5uZWwgaGFzIGFjY2VwdGVkIGFuIGlucHV0IHN0cmVh
bS4KCgoKAwQDARIDSAgTCiYKBAQDAgASA0oCFxoZIElEIG9mIHRoZSBpbnB1dCBzdHJlYW0u
CgoMCgUEAwIABRIDSgIICgwKBQQDAgABEgNKCRIKDAoFBAMCAAMSA0oVFgo9CgQEAwIBEgNN
Ah4aMCBUaGUgdXNlci1kZWZpbmVkIGtleSBmb3IgdGhlIGlucHV0IGF0dGFjaG1lbnQuCgoM
CgUEAwIBBRIDTQIICgwKBQQDAgEBEgNNCRkKDAoFBAMCAQMSA00cHQouCgQEAwICEgNQAjAa
ISBQcm9wZXJ0aWVzIG9mIHRoZSBpbnB1dCBzdHJlYW0uCgoMCgUEAwICBhIDUAIVCgwKBQQD
AgIBEgNQFisKDAoFBAMCAgMSA1AuLwpNCgIEBBIEVABhARpBIElucHV0RXJyb3IgcmVjb3Jk
cyB3aGVuIGFuIGVycm9yIGhhcHBlbnMgd2l0aCB0aGUgaW5wdXQgc3RyZWFtLgoKCgoDBAQB
EgNUCBIKJgoEBAQCABIDVgIXGhkgSUQgb2YgdGhlIGlucHV0IHN0cmVhbS4KCgwKBQQEAgAF
EgNWAggKDAoFBAQCAAESA1YJEgoMCgUEBAIAAxIDVhUWCosBCgQEBAIBEgNaAh4afiBUaGUg
dXNlci1kZWZpbmVkIGtleSBmb3IgdGhlIGlucHV0IGF0dGFjaG1lbnQuIElmIHRoZSBzdHJl
YW0gZG9lc27igJl0IGJlbG9uZwogdG8gYW55IGlucHV0IGF0dGFjaG1lbnQsIHRoaXMgZmll
bGQgaXMgZW1wdHkuCgoMCgUEBAIBBRIDWgIICgwKBQQEAgEBEgNaCRkKDAoFBAQCAQMSA1oc
HQouCgQEBAICEgNdAjAaISBQcm9wZXJ0aWVzIG9mIHRoZSBpbnB1dCBzdHJlYW0uCgoMCgUE
BAICBhIDXQIVCgwKBQQEAgIBEgNdFisKDAoFBAQCAgMSA10uLwpPCgQEBAIDEgNgAh4aQiBB
IGRlc2NyaXB0aW9uIG9mIHRoZSByZWFzb24gZm9yIHRoZSBlcnJvciB3aXRoIHRoZSBpbnB1
dCBzdHJlYW0uCgoMCgUEBAIDBhIDYAITCgwKBQQEAgMBEgNgFBkKDAoFBAQCAwMSA2AcHQot
CgIEBRIEZABqARohIFByb3BlcnRpZXMgb2YgdGhlIGlucHV0IHN0cmVhbS4KCgoKAwQFARID
ZAgbCi8KBAQFAgASA2YCKRoiIFByb3BlcnRpZXMgb2YgdGhlIHZpZGVvIHN0cmVhbXMuCgoM
CgUEBQIABBIDZgIKCgwKBQQFAgAGEgNmCxYKDAoFBAUCAAESA2YXJAoMCgUEBQIAAxIDZico
Ci8KBAQFAgESA2kCKRoiIFByb3BlcnRpZXMgb2YgdGhlIGF1ZGlvIHN0cmVhbXMuCgoMCgUE
BQIBBBIDaQIKCgwKBQQFAgEGEgNpCxYKDAoFBAUCAQESA2kXJAoMCgUEBQIBAxIDaScoCi0K
AgQGEgRtAHMBGiEgUHJvcGVydGllcyBvZiB0aGUgdmlkZW8gc3RyZWFtLgoKCgoDBAYBEgNt
CBMKKgoEBAYCABIDbwISGh0gSW5kZXggb2YgdGhpcyB2aWRlbyBzdHJlYW0uCgoMCgUEBgIA
BRIDbwIHCgwKBQQGAgABEgNvCA0KDAoFBAYCAAMSA28QEQouCgQEBgIBEgNyAh8aISBQcm9w
ZXJ0aWVzIG9mIHRoZSB2aWRlbyBmb3JtYXQuCgoMCgUEBgIBBhIDcgINCgwKBQQGAgEBEgNy
DhoKDAoFBAYCAQMSA3IdHgouCgIEBxIFdgCCAQEaISBQcm9wZXJ0aWVzIG9mIHRoZSB2aWRl
byBmb3JtYXQuCgoKCgMEBwESA3YIEwo1CgQEBwIAEgN4AhMaKCBWaWRlbyBjb2RlYyB1c2Vk
IGluIHRoaXMgdmlkZW8gc3RyZWFtLgoKDAoFBAcCAAUSA3gCCAoMCgUEBwIAARIDeAkOCgwK
BQQHAgADEgN4ERIKNwoEBAcCARIDewIZGiogVGhlIHdpZHRoIG9mIHRoZSB2aWRlbyBzdHJl
YW0gaW4gcGl4ZWxzLgoKDAoFBAcCAQUSA3sCBwoMCgUEBwIBARIDewgUCgwKBQQHAgEDEgN7
FxgKOAoEBAcCAhIDfgIaGisgVGhlIGhlaWdodCBvZiB0aGUgdmlkZW8gc3RyZWFtIGluIHBp
eGVscy4KCgwKBQQHAgIFEgN+AgcKDAoFBAcCAgESA34IFQoMCgUEBwICAxIDfhgZCjkKBAQH
AgMSBIEBAhgaKyBUaGUgZnJhbWUgcmF0ZSBvZiB0aGUgaW5wdXQgdmlkZW8gc3RyZWFtLgoK
DQoFBAcCAwUSBIEBAggKDQoFBAcCAwESBIEBCRMKDQoFBAcCAwMSBIEBFhcKLwoCBAgSBoUB
AIsBARohIFByb3BlcnRpZXMgb2YgdGhlIGF1ZGlvIHN0cmVhbS4KCgsKAwQIARIEhQEIEwor
CgQECAIAEgSHAQISGh0gSW5kZXggb2YgdGhpcyBhdWRpbyBzdHJlYW0uCgoNCgUECAIABRIE
hwECBwoNCgUECAIAARIEhwEIDQoNCgUECAIAAxIEhwEQEQovCgQECAIBEgSKAQIfGiEgUHJv
cGVydGllcyBvZiB0aGUgYXVkaW8gZm9ybWF0LgoKDQoFBAgCAQYSBIoBAg0KDQoFBAgCAQES
BIoBDhoKDQoFBAgCAQMSBIoBHR4KLwoCBAkSBo4BAJcBARohIFByb3BlcnRpZXMgb2YgdGhl
IGF1ZGlvIGZvcm1hdC4KCgsKAwQJARIEjgEIEwo2CgQECQIAEgSQAQITGiggQXVkaW8gY29k
ZWMgdXNlZCBpbiB0aGlzIGF1ZGlvIHN0cmVhbS4KCg0KBQQJAgAFEgSQAQIICg0KBQQJAgAB
EgSQAQkOCg0KBQQJAgADEgSQARESCi0KBAQJAgESBJMBAhoaHyBUaGUgbnVtYmVyIG9mIGF1
ZGlvIGNoYW5uZWxzLgoKDQoFBAkCAQUSBJMBAgcKDQoFBAkCAQESBJMBCBUKDQoFBAkCAQMS
BJMBGBkKVAoEBAkCAhIElgECJRpGIEEgbGlzdCBvZiBjaGFubmVsIG5hbWVzIHNwZWNpZnlp
bmcgdGhlIGxheW91dCBvZiB0aGUgYXVkaW8gY2hhbm5lbHMuCgoNCgUECQICBBIElgECCgoN
CgUECQICBRIElgELEQoNCgUECQICARIElgESIAoNCgUECQICAxIElgEjJApJCgIEChIGmgEA
oAEBGjsgSW5wdXREaXNjb25uZWN0IHJlY29yZHMgd2hlbiBhbiBpbnB1dCBzdHJlYW0gZGlz
Y29ubmVjdHMuCgoLCgMECgESBJoBCBcKJwoEBAoCABIEnAECFxoZIElEIG9mIHRoZSBpbnB1
dCBzdHJlYW0uCgoNCgUECgIABRIEnAECCAoNCgUECgIAARIEnAEJEgoNCgUECgIAAxIEnAEV
Fgo+CgQECgIBEgSfAQIeGjAgVGhlIHVzZXItZGVmaW5lZCBrZXkgZm9yIHRoZSBpbnB1dCBh
dHRhY2htZW50LgoKDQoFBAoCAQUSBJ8BAggKDQoFBAoCAQESBJ8BCRkKDQoFBAoCAQMSBJ8B
HB0KRQoCBAsSBqMBAKwBARo3IEV2ZW50U3RhdGVDaGFuZ2UgcmVjb3JkcyB3aGVuIGFuIEV2
ZW50IHN0YXRlIGNoYW5nZXMuCgoLCgMECwESBKMBCBgKKwoEBAsCABIEpQECFhodIFJlc291
cmNlIG5hbWUgb2YgdGhlIGV2ZW50LgoKDQoFBAsCAAUSBKUBAggKDQoFBAsCAAESBKUBCREK
DQoFBAsCAAMSBKUBFBUKJwoEBAsCARIEqAECPRoZIE5ldyBzdGF0ZSBvZiB0aGUgZXZlbnQu
CgoNCgUECwIBBhIEqAECLgoNCgUECwIBARIEqAEvOAoNCgUECwIBAxIEqAE7PAosCgQECwIC
EgSrAQJCGh4gUHJldmlvdXMgc3RhdGUgb2YgdGhlIGV2ZW50LgoKDQoFBAsCAgYSBKsBAi4K
DQoFBAsCAgESBKsBLz0KDQoFBAsCAgMSBKsBQEEKTAoCBAwSBq8BAIQCARo+IFNjdGUzNUNv
bW1hbmQgaW5jbHVkZXMgZGV0YWlscyBvZiBhIHJlY2VpdmVkIFNDVEUzNSBjb21tYW5kLgoK
CwoDBAwBEgSvAQgVCmEKBAQMAwASBrIBArgBAxpRIFNwbGljZVRpbWUgY29udGFpbnMgaW5m
b3JtYXRpb24gYWJvdXQgdGhlIGV4ZWN1dGlvbiB0aW1lIG9mIHRoZSBzcGxpY2UKIGluc2Vy
dC4KCg0KBQQMAwABEgSyAQoUClAKBgQMAwACABIEtAEEIRpAIElmIHRydWUsIHRoZSBleGVj
dXRpb24gdGltZSBvZiB0aGUgc3BsaWNlIGluc2VydCBpcyBzcGVjaWZpZWQuCgoPCgcEDAMA
AgAFEgS0AQQICg8KBwQMAwACAAESBLQBCRwKDwoHBAwDAAIAAxIEtAEfIAowCgYEDAMAAgES
BLcBBBcaICBUaGUgdGltZSBvZiB0aGUgc3BsaWNlIGluc2VydC4KCg8KBwQMAwACAQUSBLcB
BAkKDwoHBAwDAAIBARIEtwEKEgoPCgcEDAMAAgEDEgS3ARUWCl4KBAQMAwESBrwBAsIBAxpO
IEJyZWFrRHVyYXRpb24gY29udGFpbnMgaW5mb3JtYXRpb24gYWJvdXQgdGhlIGR1cmF0aW9u
IG9mIHRoZSBzcGxpY2UKIGluc2VydC4KCg0KBQQMAwEBEgS8AQoXClYKBgQMAwECABIEvgEE
GRpGIElmIHRydWUsIHRoZSBzcGxpY2UgaW5zZXJ0IHdpbGwgYXV0b21hdGljYWxseSByZXR1
cm4gdXBvbiBmaW5pc2hpbmcuCgoPCgcEDAMBAgAFEgS+AQQICg8KBwQMAwECAAESBL4BCRQK
DwoHBAwDAQIAAxIEvgEXGAowCgYEDAMBAgESBMEBBBcaICBEdXJhdGlvbiBvZiB0aGUgc3Bs
aWNlIGluc2VydC4KCg8KBwQMAwECAQUSBMEBBAkKDwoHBAwDAQIBARIEwQEKEgoPCgcEDAMB
AgEDEgTBARUWCpgBCgQEDAMCEgbGAQLMAQMahwEgRmluZSBncmFpbmVkIGNvbnRyb2wgb24g
dGhlIHNjdGUgY29tbWFuZCBpbnNlcnRpb24gZm9yIGEgc3BlY2lmaWMKIGVsZW1lbnRhcnkg
c3RyZWFtLiBUaGlzIGlzIGlnbm9yZWQgaWYgcHJvZ3JhbV9zcGxpY2VfZmxhZyBpcyB0cnVl
LgoKDQoFBAwDAgESBMYBChMKVgoGBAwDAgIAEgTIAQQcGkYgRWxlbWVudGFyeSBzdHJlYW0g
UElEIHRoYXQgdGhlIHNjdGUgY29tbWFuZCBzaG91bGQgYmUgaW5zZXJ0ZWQgaW50by4KCg8K
BwQMAwICAAUSBMgBBAkKDwoHBAwDAgIAARIEyAEKFwoPCgcEDAMCAgADEgTIARobCikKBgQM
AwICARIEywEEHxoZIFRoZSB0aW1lIG9mIHRoZSBpbnNlcnQuCgoPCgcEDAMCAgEGEgTLAQQO
Cg8KBwQMAwICAQESBMsBDxoKDwoHBAwDAgIBAxIEywEdHgpMCgQEDAMDEgbPAQL2AQMaPCBT
cGxpY2VJbnNlcnQgY29udGFpbnMgaW5mb3JtYXRpb24gYWJvdXQgdGhlIHNwbGljZSBpbnNl
cnQuCgoNCgUEDAMDARIEzwEKFgovCgYEDAMDAgASBNEBBB4aHyBFdmVudCBJRCBvZiB0aGUg
c2N0ZSBjb21tYW5kLgoKDwoHBAwDAwIABRIE0QEECQoPCgcEDAMDAgABEgTRAQoZCg8KBwQM
AwMCAAMSBNEBHB0KWAoGBAwDAwIBEgTUAQQrGkggV2hldGhlciB0aGlzIHNjdGUgY29tbWFu
ZCBpcyB0byBjYW5jZWwgYW5vdGhlciBzY2hlZHVsZWQgc2N0ZSBjb21tYW5kLgoKDwoHBAwD
AwIBBRIE1AEECAoPCgcEDAMDAgEBEgTUAQkmCg8KBwQMAwMCAQMSBNQBKSoKTgoGBAwDAwIC
EgTXAQQmGj4gV2hldGhlciB0aGlzIHNjdGUgY29tbWFuZCBpcyBjdWVpbmcgb3V0IHRoZSBj
dXJyZW50IHByb2dyYW0uCgoPCgcEDAMDAgIFEgTXAQQICg8KBwQMAwMCAgESBNcBCSEKDwoH
BAwDAwICAxIE1wEkJQo9CgYEDAMDAgMSBNoBBCEaLSBJZiB0cnVlLCBzZW5kIHNwbGljZSBp
bnNlcnQgdG8gYWxsIHN0cmVhbXMuCgoPCgcEDAMDAgMFEgTaAQQICg8KBwQMAwMCAwESBNoB
CRwKDwoHBAwDAwIDAxIE2gEfIApCCgYEDAMDAgQSBN0BBBsaMiBJZiB0cnVlLCB0aGUgZHVy
YXRpb24gb2YgdGhlIGV2ZW50IGlzIHNwZWNpZmllZC4KCg8KBwQMAwMCBAUSBN0BBAgKDwoH
BAwDAwIEARIE3QEJFgoPCgcEDAMDAgQDEgTdARkaCkQKBgQMAwMCBRIE4AEEIxo0IElmIHRy
dWUsIHRoZSBldmVudCBzaG91bGQgYmUgZXhlY3V0ZWQgaW1tZWRpYXRlbHkuCgoPCgcEDAMD
AgUFEgTgAQQICg8KBwQMAwMCBQESBOABCR4KDwoHBAwDAwIFAxIE4AEhIgpMCgYEDAMDAgYS
BOMBBB8aPCBJbmZvcm1hdGlvbiBhYm91dCB0aGUgZXhlY3V0aW9uIHRpbWUgb2YgdGhlIHNw
bGljZSBpbnNlcnQuCgoPCgcEDAMDAgYGEgTjAQQOCg8KBwQMAwMCBgESBOMBDxoKDwoHBAwD
AwIGAxIE4wEdHgpGCgYEDAMDAgcSBOYBBCUaNiBJbmZvcm1hdGlvbiBhYm91dCB0aGUgZHVy
YXRpb24gb2YgdGhlIHNwbGljZSBpbnNlcnQuCgoPCgcEDAMDAgcGEgTmAQQRCg8KBwQMAwMC
BwESBOYBEiAKDwoHBAwDAwIHAxIE5gEjJAowCgYEDAMDAggSBOkBBCAaICBVbmlxdWUgSUQg
Zm9yIGEgdmlld2luZyBldmVudC4KCg8KBwQMAwMCCAUSBOkBBAkKDwoHBAwDAwIIARIE6QEK
GwoPCgcEDAMDAggDEgTpAR4fCj8KBgQMAwMCCRIE7AEEGRovIElEIGZvciBhbiBhdmFpbCB3
aXRoaW4gb25lIHVuaXF1ZV9wcm9ncmFtX2lkLgoKDwoHBAwDAwIJBRIE7AEECQoPCgcEDAMD
AgkBEgTsAQoTCg8KBwQMAwMCCQMSBOwBFhgKSAoGBAwDAwIKEgTvAQQfGjggVGhlIG51bWJl
ciBvZiBhdmFpbHMgd2l0aGluIHRoZSBjdXJyZW50IHZpZXdpbmcgZXZlbnQuCgoPCgcEDAMD
AgoFEgTvAQQJCg8KBwQMAwMCCgESBO8BChkKDwoHBAwDAwIKAxIE7wEcHgonCgYEDAMDAgsS
BPIBBB8aFyBOdW1iZXIgb2YgY29tcG9uZW50cy4KCg8KBwQMAwMCCwUSBPIBBAkKDwoHBAwD
AwILARIE8gEKGQoPCgcEDAMDAgsDEgTyARweCiwKBgQMAwMCDBIE9QEEJxocIENvbXBvbmVu
dHMgb2YgdGhlIHByb2dyYW0uCgoPCgcEDAMDAgwEEgT1AQQMCg8KBwQMAwMCDAYSBPUBDRYK
DwoHBAwDAwIMARIE9QEXIQoPCgcEDAMDAgwDEgT1ASQmClEKBAQMAwQSBvkBAoACAxpBIFNw
bGljZUluZm9TZWN0aW9uIGNvbnRhaW5zIGluZm9ybWF0aW9uIGFib3V0IHRoZSBzcGxpY2Ug
aW5zZXJ0LgoKDQoFBAwDBAESBPkBChsKZgoGBAwDBAIAEgT8AQQdGlYgT3ZlcmZsb3cgb2Yg
cHRzX3RpbWUsIHdoZW4gcHRzX3RpbWUgZG9lc24ndCBoYXZlIGVub3VnaCBiaXRzCiB0byBy
ZXByZXNlbnQgdGhlIHRpbWUuCgoPCgcEDAMEAgAFEgT8AQQJCg8KBwQMAwQCAAESBPwBChgK
DwoHBAwDBAIAAxIE/AEbHAo2CgYEDAMEAgESBP8BBCMaJiBJbmZvcm1hdGlvbiBhYm91dCB0
aGUgc3BsaWNlIGluc2VydC4KCg8KBwQMAwQCAQYSBP8BBBAKDwoHBAwDBAIBARIE/wERHgoP
CgcEDAMEAgEDEgT/ASEiCjQKBAQMAgASBIMCAiwaJiBJbmZvcm1hdGlvbiBhYm91dCB0aGUg
c3BsaWNlIGluc2VydC4KCg0KBQQMAgAGEgSDAgITCg0KBQQMAgABEgSDAhQnCg0KBQQMAgAD
EgSDAiorYgZwcm90bzM=
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Video::Livestream::Logging::V1::Logs::ChannelActivity ===
    # Fields for ChannelActivity
    # Field: message Type: 9 ()
    # Field: streaming_state_change Type: 11 (.google.cloud.video.livestream.logging.v1.StreamingStateChange)
    # Field: streaming_error Type: 11 (.google.cloud.video.livestream.logging.v1.StreamingError)
    # Field: input_accept Type: 11 (.google.cloud.video.livestream.logging.v1.InputAccept)
    # Field: input_error Type: 11 (.google.cloud.video.livestream.logging.v1.InputError)
    # Field: input_disconnect Type: 11 (.google.cloud.video.livestream.logging.v1.InputDisconnect)
    # Field: event_state_change Type: 11 (.google.cloud.video.livestream.logging.v1.EventStateChange)
    # Field: scte35_command_received Type: 11 (.google.cloud.video.livestream.logging.v1.Scte35Command)

# === Message: Google::Cloud::Video::Livestream::Logging::V1::Logs::StreamingStateChange ===
    # Fields for StreamingStateChange
    # Field: new_state Type: 14 (.google.cloud.video.livestream.v1.Channel.StreamingState)
    # Field: previous_state Type: 14 (.google.cloud.video.livestream.v1.Channel.StreamingState)

# === Message: Google::Cloud::Video::Livestream::Logging::V1::Logs::StreamingError ===
    # Fields for StreamingError
    # Field: error Type: 11 (.google.rpc.Status)

# === Message: Google::Cloud::Video::Livestream::Logging::V1::Logs::InputAccept ===
    # Fields for InputAccept
    # Field: stream_id Type: 9 ()
    # Field: input_attachment Type: 9 ()
    # Field: input_stream_property Type: 11 (.google.cloud.video.livestream.logging.v1.InputStreamProperty)

# === Message: Google::Cloud::Video::Livestream::Logging::V1::Logs::InputError ===
    # Fields for InputError
    # Field: stream_id Type: 9 ()
    # Field: input_attachment Type: 9 ()
    # Field: input_stream_property Type: 11 (.google.cloud.video.livestream.logging.v1.InputStreamProperty)
    # Field: error Type: 11 (.google.rpc.Status)

# === Message: Google::Cloud::Video::Livestream::Logging::V1::Logs::InputStreamProperty ===
    # Fields for InputStreamProperty
    # Field: video_streams Type: 11 (.google.cloud.video.livestream.logging.v1.VideoStream)
    # Field: audio_streams Type: 11 (.google.cloud.video.livestream.logging.v1.AudioStream)

# === Message: Google::Cloud::Video::Livestream::Logging::V1::Logs::VideoStream ===
    # Fields for VideoStream
    # Field: index Type: 5 ()
    # Field: video_format Type: 11 (.google.cloud.video.livestream.logging.v1.VideoFormat)

# === Message: Google::Cloud::Video::Livestream::Logging::V1::Logs::VideoFormat ===
    # Fields for VideoFormat
    # Field: codec Type: 9 ()
    # Field: width_pixels Type: 5 ()
    # Field: height_pixels Type: 5 ()
    # Field: frame_rate Type: 1 ()

# === Message: Google::Cloud::Video::Livestream::Logging::V1::Logs::AudioStream ===
    # Fields for AudioStream
    # Field: index Type: 5 ()
    # Field: audio_format Type: 11 (.google.cloud.video.livestream.logging.v1.AudioFormat)

# === Message: Google::Cloud::Video::Livestream::Logging::V1::Logs::AudioFormat ===
    # Fields for AudioFormat
    # Field: codec Type: 9 ()
    # Field: channel_count Type: 5 ()
    # Field: channel_layout Type: 9 ()

# === Message: Google::Cloud::Video::Livestream::Logging::V1::Logs::InputDisconnect ===
    # Fields for InputDisconnect
    # Field: stream_id Type: 9 ()
    # Field: input_attachment Type: 9 ()

# === Message: Google::Cloud::Video::Livestream::Logging::V1::Logs::EventStateChange ===
    # Fields for EventStateChange
    # Field: event_id Type: 9 ()
    # Field: new_state Type: 14 (.google.cloud.video.livestream.v1.Event.State)
    # Field: previous_state Type: 14 (.google.cloud.video.livestream.v1.Event.State)

# === Message: Google::Cloud::Video::Livestream::Logging::V1::Logs::Scte35Command ===
    # Fields for Scte35Command
    # Field: splice_info_section Type: 11 (.google.cloud.video.livestream.logging.v1.Scte35Command.SpliceInfoSection)

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Video::Livestream::Logging::V1::Logs - Compiled Protocol Buffers messages for google/cloud/video/livestream/logging/v1/logs.proto

=head1 SYNOPSIS

    use Google::Cloud::Video::Livestream::Logging::V1::Logs;

    my $msg = Google::Cloud::Video::Livestream::Logging::V1::Logs::ChannelActivity->new({
        message => $message,
        streaming_state_change => $streaming_state_change,
        streaming_error => $streaming_error,
        input_accept => $input_accept,
    });

    # Read or update a field
    my $val = $msg->message();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Video::Livestream::Logging::V1::Logs::ChannelActivity->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/video/livestream/logging/v1/logs.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Video::Livestream::Logging::V1::Logs::ChannelActivity

Logs of activities related to the Channels.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->message() >> / C<< $msg->message($value) >>

Type: C<String>

Message is for more details of the log and instructions to users.

=item * C<< $msg->streaming_state_change() >> / C<< $msg->streaming_state_change($value) >>

Type: C<Message> (L<Google::Cloud::Video::Livestream::Logging::V1::Logs::StreamingStateChange>)

The channel streaming state changes.

=item * C<< $msg->streaming_error() >> / C<< $msg->streaming_error($value) >>

Type: C<Message> (L<Google::Cloud::Video::Livestream::Logging::V1::Logs::StreamingError>)

An error happens with the video pipeline.

=item * C<< $msg->input_accept() >> / C<< $msg->input_accept($value) >>

Type: C<Message> (L<Google::Cloud::Video::Livestream::Logging::V1::Logs::InputAccept>)

The channel has accepted an input stream.

=item * C<< $msg->input_error() >> / C<< $msg->input_error($value) >>

Type: C<Message> (L<Google::Cloud::Video::Livestream::Logging::V1::Logs::InputError>)

An error happens with the input stream.

=item * C<< $msg->input_disconnect() >> / C<< $msg->input_disconnect($value) >>

Type: C<Message> (L<Google::Cloud::Video::Livestream::Logging::V1::Logs::InputDisconnect>)

An input stream disconnects.

=item * C<< $msg->event_state_change() >> / C<< $msg->event_state_change($value) >>

Type: C<Message> (L<Google::Cloud::Video::Livestream::Logging::V1::Logs::EventStateChange>)

An event state changes.

=item * C<< $msg->scte35_command_received() >> / C<< $msg->scte35_command_received($value) >>

Type: C<Message> (L<Google::Cloud::Video::Livestream::Logging::V1::Logs::Scte35Command>)

A SCTE35 command is received.

=back

=head2 Google::Cloud::Video::Livestream::Logging::V1::Logs::StreamingStateChange

StreamingStateChange records when the channel streaming state changes.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->new_state() >> / C<< $msg->new_state($value) >>

Type: C<Enum> (L<Google::Cloud::Video::Livestream::V1::Channel::StreamingState>)

New streaming state of the channel.

=item * C<< $msg->previous_state() >> / C<< $msg->previous_state($value) >>

Type: C<Enum> (L<Google::Cloud::Video::Livestream::V1::Channel::StreamingState>)

Previous streaming state of the channel.

=back

=head2 Google::Cloud::Video::Livestream::Logging::V1::Logs::StreamingError

StreamingError records when an error happens with the video pipeline.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->error() >> / C<< $msg->error($value) >>

Type: C<Message> (L<Google::Rpc::Status::Status>)

A description of the reason for the streaming error.

=back

=head2 Google::Cloud::Video::Livestream::Logging::V1::Logs::InputAccept

InputAccept records when the channel has accepted an input stream.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->stream_id() >> / C<< $msg->stream_id($value) >>

Type: C<String>

ID of the input stream.

=item * C<< $msg->input_attachment() >> / C<< $msg->input_attachment($value) >>

Type: C<String>

The user-defined key for the input attachment.

=item * C<< $msg->input_stream_property() >> / C<< $msg->input_stream_property($value) >>

Type: C<Message> (L<Google::Cloud::Video::Livestream::Logging::V1::Logs::InputStreamProperty>)

Properties of the input stream.

=back

=head2 Google::Cloud::Video::Livestream::Logging::V1::Logs::InputError

InputError records when an error happens with the input stream.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->stream_id() >> / C<< $msg->stream_id($value) >>

Type: C<String>

ID of the input stream.

=item * C<< $msg->input_attachment() >> / C<< $msg->input_attachment($value) >>

Type: C<String>

The user-defined key for the input attachment. If the stream doesn’t belong
to any input attachment, this field is empty.

=item * C<< $msg->input_stream_property() >> / C<< $msg->input_stream_property($value) >>

Type: C<Message> (L<Google::Cloud::Video::Livestream::Logging::V1::Logs::InputStreamProperty>)

Properties of the input stream.

=item * C<< $msg->error() >> / C<< $msg->error($value) >>

Type: C<Message> (L<Google::Rpc::Status::Status>)

A description of the reason for the error with the input stream.

=back

=head2 Google::Cloud::Video::Livestream::Logging::V1::Logs::InputStreamProperty

Properties of the input stream.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->video_streams() >> / C<< $msg->video_streams($value) >>

Type: C<Message> (L<Google::Cloud::Video::Livestream::Logging::V1::Logs::VideoStream>)

Properties of the video streams.

=item * C<< $msg->audio_streams() >> / C<< $msg->audio_streams($value) >>

Type: C<Message> (L<Google::Cloud::Video::Livestream::Logging::V1::Logs::AudioStream>)

Properties of the audio streams.

=back

=head2 Google::Cloud::Video::Livestream::Logging::V1::Logs::VideoStream

Properties of the video stream.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->index() >> / C<< $msg->index($value) >>

Type: C<Int32>

Index of this video stream.

=item * C<< $msg->video_format() >> / C<< $msg->video_format($value) >>

Type: C<Message> (L<Google::Cloud::Video::Livestream::Logging::V1::Logs::VideoFormat>)

Properties of the video format.

=back

=head2 Google::Cloud::Video::Livestream::Logging::V1::Logs::VideoFormat

Properties of the video format.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->codec() >> / C<< $msg->codec($value) >>

Type: C<String>

Video codec used in this video stream.

=item * C<< $msg->width_pixels() >> / C<< $msg->width_pixels($value) >>

Type: C<Int32>

The width of the video stream in pixels.

=item * C<< $msg->height_pixels() >> / C<< $msg->height_pixels($value) >>

Type: C<Int32>

The height of the video stream in pixels.

=item * C<< $msg->frame_rate() >> / C<< $msg->frame_rate($value) >>

Type: C<Double>

The frame rate of the input video stream.

=back

=head2 Google::Cloud::Video::Livestream::Logging::V1::Logs::AudioStream

Properties of the audio stream.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->index() >> / C<< $msg->index($value) >>

Type: C<Int32>

Index of this audio stream.

=item * C<< $msg->audio_format() >> / C<< $msg->audio_format($value) >>

Type: C<Message> (L<Google::Cloud::Video::Livestream::Logging::V1::Logs::AudioFormat>)

Properties of the audio format.

=back

=head2 Google::Cloud::Video::Livestream::Logging::V1::Logs::AudioFormat

Properties of the audio format.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->codec() >> / C<< $msg->codec($value) >>

Type: C<String>

Audio codec used in this audio stream.

=item * C<< $msg->channel_count() >> / C<< $msg->channel_count($value) >>

Type: C<Int32>

The number of audio channels.

=item * C<< $msg->channel_layout() >> / C<< $msg->channel_layout($value) >>

Type: C<String>

A list of channel names specifying the layout of the audio channels.

=back

=head2 Google::Cloud::Video::Livestream::Logging::V1::Logs::InputDisconnect

InputDisconnect records when an input stream disconnects.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->stream_id() >> / C<< $msg->stream_id($value) >>

Type: C<String>

ID of the input stream.

=item * C<< $msg->input_attachment() >> / C<< $msg->input_attachment($value) >>

Type: C<String>

The user-defined key for the input attachment.

=back

=head2 Google::Cloud::Video::Livestream::Logging::V1::Logs::EventStateChange

EventStateChange records when an Event state changes.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->event_id() >> / C<< $msg->event_id($value) >>

Type: C<String>

Resource name of the event.

=item * C<< $msg->new_state() >> / C<< $msg->new_state($value) >>

Type: C<Enum> (L<Google::Cloud::Video::Livestream::V1::Event::State>)

New state of the event.

=item * C<< $msg->previous_state() >> / C<< $msg->previous_state($value) >>

Type: C<Enum> (L<Google::Cloud::Video::Livestream::V1::Event::State>)

Previous state of the event.

=back

=head2 Google::Cloud::Video::Livestream::Logging::V1::Logs::Scte35Command

Scte35Command includes details of a received SCTE35 command.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->splice_info_section() >> / C<< $msg->splice_info_section($value) >>

Type: C<Message> (L<Google::Cloud::Video::Livestream::Logging::V1::Logs::Scte35Command::SpliceInfoSection>)

Information about the splice insert.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Video::Livestream::Logging::V1::Logs::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
