package Google::Cloud::Automl::V1beta1::DataItems;

use strict;
use warnings;

our $VERSION = '0.14';

use Protobuf::Message;
use Protobuf::DescriptorPool;
use Protobuf::Internal qw(:all);
use MIME::Base64;

BEGIN {
    eval { require Google::Cloud::Automl::V1beta1::Geometry };
    eval { require Google::Cloud::Automl::V1beta1::Io };
    eval { require Google::Cloud::Automl::V1beta1::Temporal };
    eval { require Google::Cloud::Automl::V1beta1::TextSegment };
    eval { require Google::Protobuf::Struct };
    my $descriptor_b64 = <<'EOF';
Cixnb29nbGUvY2xvdWQvYXV0b21sL3YxYmV0YTEvZGF0YV9pdGVtcy5wcm90bxIbZ29vZ2xl
LmNsb3VkLmF1dG9tbC52MWJldGExGipnb29nbGUvY2xvdWQvYXV0b21sL3YxYmV0YTEvZ2Vv
bWV0cnkucHJvdG8aJGdvb2dsZS9jbG91ZC9hdXRvbWwvdjFiZXRhMS9pby5wcm90bxoqZ29v
Z2xlL2Nsb3VkL2F1dG9tbC92MWJldGExL3RlbXBvcmFsLnByb3RvGi5nb29nbGUvY2xvdWQv
YXV0b21sL3YxYmV0YTEvdGV4dF9zZWdtZW50LnByb3RvGhxnb29nbGUvcHJvdG9idWYvc3Ry
dWN0LnByb3RvIqYBCgVJbWFnZRIhCgtpbWFnZV9ieXRlcxgBIAEoDEgAUgppbWFnZUJ5dGVz
Ek0KDGlucHV0X2NvbmZpZxgGIAEoCzIoLmdvb2dsZS5jbG91ZC5hdXRvbWwudjFiZXRhMS5J
bnB1dENvbmZpZ0gAUgtpbnB1dENvbmZpZxIjCg10aHVtYm5haWxfdXJpGAQgASgJUgx0aHVt
Ym5haWxVcmlCBgoEZGF0YSJlCgtUZXh0U25pcHBldBIYCgdjb250ZW50GAEgASgJUgdjb250
ZW50EhsKCW1pbWVfdHlwZRgCIAEoCVIIbWltZVR5cGUSHwoLY29udGVudF91cmkYBCABKAlS
CmNvbnRlbnRVcmkihAIKEkRvY3VtZW50RGltZW5zaW9ucxJZCgR1bml0GAEgASgOMkUuZ29v
Z2xlLmNsb3VkLmF1dG9tbC52MWJldGExLkRvY3VtZW50RGltZW5zaW9ucy5Eb2N1bWVudERp
bWVuc2lvblVuaXRSBHVuaXQSFAoFd2lkdGgYAiABKAJSBXdpZHRoEhYKBmhlaWdodBgDIAEo
AlIGaGVpZ2h0ImUKFURvY3VtZW50RGltZW5zaW9uVW5pdBInCiNET0NVTUVOVF9ESU1FTlNJ
T05fVU5JVF9VTlNQRUNJRklFRBAAEggKBElOQ0gQARIOCgpDRU5USU1FVEVSEAISCQoFUE9J
TlQQAyLzBgoIRG9jdW1lbnQSUwoMaW5wdXRfY29uZmlnGAEgASgLMjAuZ29vZ2xlLmNsb3Vk
LmF1dG9tbC52MWJldGExLkRvY3VtZW50SW5wdXRDb25maWdSC2lucHV0Q29uZmlnEk0KDWRv
Y3VtZW50X3RleHQYAiABKAsyKC5nb29nbGUuY2xvdWQuYXV0b21sLnYxYmV0YTEuVGV4dFNu
aXBwZXRSDGRvY3VtZW50VGV4dBJECgZsYXlvdXQYAyADKAsyLC5nb29nbGUuY2xvdWQuYXV0
b21sLnYxYmV0YTEuRG9jdW1lbnQuTGF5b3V0UgZsYXlvdXQSYAoTZG9jdW1lbnRfZGltZW5z
aW9ucxgEIAEoCzIvLmdvb2dsZS5jbG91ZC5hdXRvbWwudjFiZXRhMS5Eb2N1bWVudERpbWVu
c2lvbnNSEmRvY3VtZW50RGltZW5zaW9ucxIdCgpwYWdlX2NvdW50GAUgASgFUglwYWdlQ291
bnQa+wMKBkxheW91dBJLCgx0ZXh0X3NlZ21lbnQYASABKAsyKC5nb29nbGUuY2xvdWQuYXV0
b21sLnYxYmV0YTEuVGV4dFNlZ21lbnRSC3RleHRTZWdtZW50Eh8KC3BhZ2VfbnVtYmVyGAIg
ASgFUgpwYWdlTnVtYmVyEk4KDWJvdW5kaW5nX3BvbHkYAyABKAsyKS5nb29nbGUuY2xvdWQu
YXV0b21sLnYxYmV0YTEuQm91bmRpbmdQb2x5Ugxib3VuZGluZ1BvbHkSaAoRdGV4dF9zZWdt
ZW50X3R5cGUYBCABKA4yPC5nb29nbGUuY2xvdWQuYXV0b21sLnYxYmV0YTEuRG9jdW1lbnQu
TGF5b3V0LlRleHRTZWdtZW50VHlwZVIPdGV4dFNlZ21lbnRUeXBlIsgBCg9UZXh0U2VnbWVu
dFR5cGUSIQodVEVYVF9TRUdNRU5UX1RZUEVfVU5TUEVDSUZJRUQQABIJCgVUT0tFThABEg0K
CVBBUkFHUkFQSBACEg4KCkZPUk1fRklFTEQQAxITCg9GT1JNX0ZJRUxEX05BTUUQBBIXChNG
T1JNX0ZJRUxEX0NPTlRFTlRTEAUSCQoFVEFCTEUQBhIQCgxUQUJMRV9IRUFERVIQBxINCglU
QUJMRV9ST1cQCBIOCgpUQUJMRV9DRUxMEAkiXQoDUm93EiYKD2NvbHVtbl9zcGVjX2lkcxgC
IAMoCVINY29sdW1uU3BlY0lkcxIuCgZ2YWx1ZXMYAyADKAsyFi5nb29nbGUucHJvdG9idWYu
VmFsdWVSBnZhbHVlcyKhAgoORXhhbXBsZVBheWxvYWQSOgoFaW1hZ2UYASABKAsyIi5nb29n
bGUuY2xvdWQuYXV0b21sLnYxYmV0YTEuSW1hZ2VIAFIFaW1hZ2USTQoMdGV4dF9zbmlwcGV0
GAIgASgLMiguZ29vZ2xlLmNsb3VkLmF1dG9tbC52MWJldGExLlRleHRTbmlwcGV0SABSC3Rl
eHRTbmlwcGV0EkMKCGRvY3VtZW50GAQgASgLMiUuZ29vZ2xlLmNsb3VkLmF1dG9tbC52MWJl
dGExLkRvY3VtZW50SABSCGRvY3VtZW50EjQKA3JvdxgDIAEoCzIgLmdvb2dsZS5jbG91ZC5h
dXRvbWwudjFiZXRhMS5Sb3dIAFIDcm93QgkKB3BheWxvYWRCmwEKH2NvbS5nb29nbGUuY2xv
dWQuYXV0b21sLnYxYmV0YTFQAVo3Y2xvdWQuZ29vZ2xlLmNvbS9nby9hdXRvbWwvYXBpdjFi
ZXRhMS9hdXRvbWxwYjthdXRvbWxwYsoCG0dvb2dsZVxDbG91ZFxBdXRvTWxcVjFiZXRhMeoC
Hkdvb2dsZTo6Q2xvdWQ6OkF1dG9NTDo6VjFiZXRhMUr1PwoHEgUOANkBAQq8BAoBDBIDDgAS
MrEEIENvcHlyaWdodCAyMDI1IEdvb2dsZSBMTEMKCiBMaWNlbnNlZCB1bmRlciB0aGUgQXBh
Y2hlIExpY2Vuc2UsIFZlcnNpb24gMi4wICh0aGUgIkxpY2Vuc2UiKTsKIHlvdSBtYXkgbm90
IHVzZSB0aGlzIGZpbGUgZXhjZXB0IGluIGNvbXBsaWFuY2Ugd2l0aCB0aGUgTGljZW5zZS4K
IFlvdSBtYXkgb2J0YWluIGEgY29weSBvZiB0aGUgTGljZW5zZSBhdAoKICAgICBodHRwOi8v
d3d3LmFwYWNoZS5vcmcvbGljZW5zZXMvTElDRU5TRS0yLjAKCiBVbmxlc3MgcmVxdWlyZWQg
YnkgYXBwbGljYWJsZSBsYXcgb3IgYWdyZWVkIHRvIGluIHdyaXRpbmcsIHNvZnR3YXJlCiBk
aXN0cmlidXRlZCB1bmRlciB0aGUgTGljZW5zZSBpcyBkaXN0cmlidXRlZCBvbiBhbiAiQVMg
SVMiIEJBU0lTLAogV0lUSE9VVCBXQVJSQU5USUVTIE9SIENPTkRJVElPTlMgT0YgQU5ZIEtJ
TkQsIGVpdGhlciBleHByZXNzIG9yIGltcGxpZWQuCiBTZWUgdGhlIExpY2Vuc2UgZm9yIHRo
ZSBzcGVjaWZpYyBsYW5ndWFnZSBnb3Zlcm5pbmcgcGVybWlzc2lvbnMgYW5kCiBsaW1pdGF0
aW9ucyB1bmRlciB0aGUgTGljZW5zZS4KCggKAQISAxAAJAoJCgIDABIDEgA0CgkKAgMBEgMT
AC4KCQoCAwISAxQANAoJCgIDAxIDFQA4CgkKAgMEEgMWACYKCAoBCBIDGABOCgkKAggLEgMY
AE4KCAoBCBIDGQAiCgkKAggKEgMZACIKCAoBCBIDGgA4CgkKAggBEgMaADgKCAoBCBIDGwA4
CgkKAggpEgMbADgKCAoBCBIDHAA3CgkKAggtEgMcADcKWgoCBAASBCAAMQEaTiBBIHJlcHJl
c2VudGF0aW9uIG9mIGFuIGltYWdlLgogT25seSBpbWFnZXMgdXAgdG8gMzBNQiBpbiBzaXpl
IGFyZSBzdXBwb3J0ZWQuCgoKCgMEAAESAyAIDQrcAgoEBAAIABIEJQItAxrNAiBJbnB1dCBv
bmx5LiBUaGUgZGF0YSByZXByZXNlbnRpbmcgdGhlIGltYWdlLgogRm9yIFByZWRpY3QgY2Fs
bHMgW2ltYWdlX2J5dGVzXVtnb29nbGUuY2xvdWQuYXV0b21sLnYxYmV0YTEuSW1hZ2UuaW1h
Z2VfYnl0ZXNdIG11c3QgYmUgc2V0LCBhcyBvdGhlciBvcHRpb25zIGFyZSBub3QKIGN1cnJl
bnRseSBzdXBwb3J0ZWQgYnkgcHJlZGljdGlvbiBBUEkuIFlvdSBjYW4gcmVhZCB0aGUgY29u
dGVudHMgb2YgYW4KIHVwbG9hZGVkIGltYWdlIGJ5IHVzaW5nIHRoZSBbY29udGVudF91cmld
W2dvb2dsZS5jbG91ZC5hdXRvbWwudjFiZXRhMS5JbWFnZS5jb250ZW50X3VyaV0gZmllbGQu
CgoMCgUEAAgAARIDJQgMCrsBCgQEAAIAEgMpBBoarQEgSW1hZ2UgY29udGVudCByZXByZXNl
bnRlZCBhcyBhIHN0cmVhbSBvZiBieXRlcy4KIE5vdGU6IEFzIHdpdGggYWxsIGBieXRlc2Ag
ZmllbGRzLCBwcm90b2J1ZmZlcnMgdXNlIGEgcHVyZSBiaW5hcnkKIHJlcHJlc2VudGF0aW9u
LCB3aGVyZWFzIEpTT04gcmVwcmVzZW50YXRpb25zIHVzZSBiYXNlNjQuCgoMCgUEAAIABRID
KQQJCgwKBQQAAgABEgMpChUKDAoFBAACAAMSAykYGQpDCgQEAAIBEgMsBCEaNiBBbiBpbnB1
dCBjb25maWcgc3BlY2lmeWluZyB0aGUgY29udGVudCBvZiB0aGUgaW1hZ2UuCgoMCgUEAAIB
BhIDLAQPCgwKBQQAAgEBEgMsEBwKDAoFBAACAQMSAywfIAo8CgQEAAICEgMwAhsaLyBPdXRw
dXQgb25seS4gSFRUUCBVUkkgdG8gdGhlIHRodW1ibmFpbCBpbWFnZS4KCgwKBQQAAgIFEgMw
AggKDAoFBAACAgESAzAJFgoMCgUEAAICAxIDMBkaCjEKAgQBEgQ0AEABGiUgQSByZXByZXNl
bnRhdGlvbiBvZiBhIHRleHQgc25pcHBldC4KCgoKAwQBARIDNAgTCmQKBAQBAgASAzcCFRpX
IFJlcXVpcmVkLiBUaGUgY29udGVudCBvZiB0aGUgdGV4dCBzbmlwcGV0IGFzIGEgc3RyaW5n
LiBVcCB0byAyNTAwMDAKIGNoYXJhY3RlcnMgbG9uZy4KCgwKBQQBAgAFEgM3AggKDAoFBAEC
AAESAzcJEAoMCgUEAQIAAxIDNxMUCr0CCgQEAQIBEgM8AhcarwIgT3B0aW9uYWwuIFRoZSBm
b3JtYXQgb2YgW2NvbnRlbnRdW2dvb2dsZS5jbG91ZC5hdXRvbWwudjFiZXRhMS5UZXh0U25p
cHBldC5jb250ZW50XS4gQ3VycmVudGx5IHRoZSBvbmx5IHR3byBhbGxvd2VkCiB2YWx1ZXMg
YXJlICJ0ZXh0L2h0bWwiIGFuZCAidGV4dC9wbGFpbiIuIElmIGxlZnQgYmxhbmssIHRoZSBm
b3JtYXQgaXMKIGF1dG9tYXRpY2FsbHkgZGV0ZXJtaW5lZCBmcm9tIHRoZSB0eXBlIG9mIHRo
ZSB1cGxvYWRlZCBbY29udGVudF1bZ29vZ2xlLmNsb3VkLmF1dG9tbC52MWJldGExLlRleHRT
bmlwcGV0LmNvbnRlbnRdLgoKDAoFBAECAQUSAzwCCAoMCgUEAQIBARIDPAkSCgwKBQQBAgED
EgM8FRYKSAoEBAECAhIDPwIZGjsgT3V0cHV0IG9ubHkuIEhUVFAgVVJJIHdoZXJlIHlvdSBj
YW4gZG93bmxvYWQgdGhlIGNvbnRlbnQuCgoMCgUEAQICBRIDPwIICgwKBQQBAgIBEgM/CRQK
DAoFBAECAgMSAz8XGAo9CgIEAhIEQwBbARoxIE1lc3NhZ2UgdGhhdCBkZXNjcmliZXMgZGlt
ZW5zaW9uIG9mIGEgZG9jdW1lbnQuCgoKCgMEAgESA0MIGgovCgQEAgQAEgRFAlEDGiEgVW5p
dCBvZiB0aGUgZG9jdW1lbnQgZGltZW5zaW9uLgoKDAoFBAIEAAESA0UHHAokCgYEAgQAAgAS
A0cELBoVIFNob3VsZCBub3QgYmUgdXNlZC4KCg4KBwQCBAACAAESA0cEJwoOCgcEAgQAAgAC
EgNHKisKOgoGBAIEAAIBEgNKBA0aKyBEb2N1bWVudCBkaW1lbnNpb24gaXMgbWVhc3VyZWQg
aW4gaW5jaGVzLgoKDgoHBAIEAAIBARIDSgQICg4KBwQCBAACAQISA0oLDAo/CgYEAgQAAgIS
A00EExowIERvY3VtZW50IGRpbWVuc2lvbiBpcyBtZWFzdXJlZCBpbiBjZW50aW1ldGVycy4K
Cg4KBwQCBAACAgESA00EDgoOCgcEAgQAAgICEgNNERIKTgoGBAIEAAIDEgNQBA4aPyBEb2N1
bWVudCBkaW1lbnNpb24gaXMgbWVhc3VyZWQgaW4gcG9pbnRzLiA3MiBwb2ludHMgPSAxIGlu
Y2guCgoOCgcEAgQAAgMBEgNQBAkKDgoHBAIEAAIDAhIDUAwNCiUKBAQCAgASA1QCIRoYIFVu
aXQgb2YgdGhlIGRpbWVuc2lvbi4KCgwKBQQCAgAGEgNUAhcKDAoFBAICAAESA1QYHAoMCgUE
AgIAAxIDVB8gCkkKBAQCAgESA1cCEho8IFdpZHRoIHZhbHVlIG9mIHRoZSBkb2N1bWVudCwg
d29ya3MgdG9nZXRoZXIgd2l0aCB0aGUgdW5pdC4KCgwKBQQCAgEFEgNXAgcKDAoFBAICAQES
A1cIDQoMCgUEAgIBAxIDVxARCkoKBAQCAgISA1oCExo9IEhlaWdodCB2YWx1ZSBvZiB0aGUg
ZG9jdW1lbnQsIHdvcmtzIHRvZ2V0aGVyIHdpdGggdGhlIHVuaXQuCgoMCgUEAgICBRIDWgIH
CgwKBQQCAgIBEgNaCA4KDAoFBAICAgMSA1oREgo1CgIEAxIFXgCyAQEaKCBBIHN0cnVjdHVy
ZWQgdGV4dCBkb2N1bWVudCBlLmcuIGEgUERGLgoKCgoDBAMBEgNeCBAKkQEKBAQDAwASBWAC
oQEDGoEBIERlc2NyaWJlcyB0aGUgbGF5b3V0IGluZm9ybWF0aW9uIG9mIGEgW3RleHRfc2Vn
bWVudF1bZ29vZ2xlLmNsb3VkLmF1dG9tbC52MWJldGExLkRvY3VtZW50LkxheW91dC50ZXh0
X3NlZ21lbnRdIGluIHRoZSBkb2N1bWVudC4KCgwKBQQDAwABEgNgChAKUwoGBAMDAAQAEgVi
BIoBBRpCIFRoZSB0eXBlIG9mIFRleHRTZWdtZW50IGluIHRoZSBjb250ZXh0IG9mIHRoZSBv
cmlnaW5hbCBkb2N1bWVudC4KCg4KBwQDAwAEAAESA2IJGAomCggEAwMABAACABIDZAYoGhUg
U2hvdWxkIG5vdCBiZSB1c2VkLgoKEAoJBAMDAAQAAgABEgNkBiMKEAoJBAMDAAQAAgACEgNk
JicKOgoIBAMDAAQAAgESA2cGEBopIFRoZSB0ZXh0IHNlZ21lbnQgaXMgYSB0b2tlbi4gZS5n
LiB3b3JkLgoKEAoJBAMDAAQAAgEBEgNnBgsKEAoJBAMDAAQAAgECEgNnDg8KMwoIBAMDAAQA
AgISA2oGFBoiIFRoZSB0ZXh0IHNlZ21lbnQgaXMgYSBwYXJhZ3JhcGguCgoQCgkEAwMABAAC
AgESA2oGDwoQCgkEAwMABAACAgISA2oSEwo0CggEAwMABAACAxIDbQYVGiMgVGhlIHRleHQg
c2VnbWVudCBpcyBhIGZvcm0gZmllbGQuCgoQCgkEAwMABAACAwESA20GEAoQCgkEAwMABAAC
AwISA20TFArKAQoIBAMDAAQAAgQSA3IGGhq4ASBUaGUgdGV4dCBzZWdtZW50IGlzIHRoZSBu
YW1lIHBhcnQgb2YgYSBmb3JtIGZpZWxkLiBJdCB3aWxsIGJlIHRyZWF0ZWQKIGFzIGNoaWxk
IG9mIGFub3RoZXIgRk9STV9GSUVMRCBUZXh0U2VnbWVudCBpZiBpdHMgc3BhbiBpcyBzdWJz
cGFuIG9mCiBhbm90aGVyIFRleHRTZWdtZW50IHdpdGggdHlwZSBGT1JNX0ZJRUxELgoKEAoJ
BAMDAAQAAgQBEgNyBhUKEAoJBAMDAAQAAgQCEgNyGBkK0gEKCAQDAwAEAAIFEgN3Bh4awAEg
VGhlIHRleHQgc2VnbWVudCBpcyB0aGUgdGV4dCBjb250ZW50IHBhcnQgb2YgYSBmb3JtIGZp
ZWxkLiBJdCB3aWxsIGJlCiB0cmVhdGVkIGFzIGNoaWxkIG9mIGFub3RoZXIgRk9STV9GSUVM
RCBUZXh0U2VnbWVudCBpZiBpdHMgc3BhbiBpcwogc3Vic3BhbiBvZiBhbm90aGVyIFRleHRT
ZWdtZW50IHdpdGggdHlwZSBGT1JNX0ZJRUxELgoKEAoJBAMDAAQAAgUBEgN3BhkKEAoJBAMD
AAQAAgUCEgN3HB0KVgoIBAMDAAQAAgYSA3oGEBpFIFRoZSB0ZXh0IHNlZ21lbnQgaXMgYSB3
aG9sZSB0YWJsZSwgaW5jbHVkaW5nIGhlYWRlcnMsIGFuZCBhbGwgcm93cy4KChAKCQQDAwAE
AAIGARIDegYLChAKCQQDAwAEAAIGAhIDeg4PCrQBCggEAwMABAACBxIDfwYXGqIBIFRoZSB0
ZXh0IHNlZ21lbnQgaXMgYSB0YWJsZSdzIGhlYWRlcnMuIEl0IHdpbGwgYmUgdHJlYXRlZCBh
cyBjaGlsZCBvZgogYW5vdGhlciBUQUJMRSBUZXh0U2VnbWVudCBpZiBpdHMgc3BhbiBpcyBz
dWJzcGFuIG9mIGFub3RoZXIgVGV4dFNlZ21lbnQKIHdpdGggdHlwZSBUQUJMRS4KChAKCQQD
AwAEAAIHARIDfwYSChAKCQQDAwAEAAIHAhIDfxUWCrIBCggEAwMABAACCBIEhAEGFBqfASBU
aGUgdGV4dCBzZWdtZW50IGlzIGEgcm93IGluIHRhYmxlLiBJdCB3aWxsIGJlIHRyZWF0ZWQg
YXMgY2hpbGQgb2YKIGFub3RoZXIgVEFCTEUgVGV4dFNlZ21lbnQgaWYgaXRzIHNwYW4gaXMg
c3Vic3BhbiBvZiBhbm90aGVyIFRleHRTZWdtZW50CiB3aXRoIHR5cGUgVEFCTEUuCgoRCgkE
AwMABAACCAESBIQBBg8KEQoJBAMDAAQAAggCEgSEARITCrsBCggEAwMABAACCRIEiQEGFRqo
ASBUaGUgdGV4dCBzZWdtZW50IGlzIGEgY2VsbCBpbiB0YWJsZS4gSXQgd2lsbCBiZSB0cmVh
dGVkIGFzIGNoaWxkIG9mCiBhbm90aGVyIFRBQkxFX1JPVyBUZXh0U2VnbWVudCBpZiBpdHMg
c3BhbiBpcyBzdWJzcGFuIG9mIGFub3RoZXIKIFRleHRTZWdtZW50IHdpdGggdHlwZSBUQUJM
RV9ST1cuCgoRCgkEAwMABAACCQESBIkBBhAKEQoJBAMDAAQAAgkCEgSJARMUCoEBCgYEAwMA
AgASBI4BBCEacSBUZXh0IFNlZ21lbnQgdGhhdCByZXByZXNlbnRzIGEgc2VnbWVudCBpbgog
W2RvY3VtZW50X3RleHRdW2dvb2dsZS5jbG91ZC5hdXRvbWwudjFiZXRhMS5Eb2N1bWVudC5k
b2N1bWVudF90ZXh0XS4KCg8KBwQDAwACAAYSBI4BBA8KDwoHBAMDAAIAARIEjgEQHAoPCgcE
AwMAAgADEgSOAR8gCpgBCgYEAwMAAgESBJIBBBoahwEgUGFnZSBudW1iZXIgb2YgdGhlIFt0
ZXh0X3NlZ21lbnRdW2dvb2dsZS5jbG91ZC5hdXRvbWwudjFiZXRhMS5Eb2N1bWVudC5MYXlv
dXQudGV4dF9zZWdtZW50XSBpbiB0aGUgb3JpZ2luYWwgZG9jdW1lbnQsIHN0YXJ0cwogZnJv
bSAxLgoKDwoHBAMDAAIBBRIEkgEECQoPCgcEAwMAAgEBEgSSAQoVCg8KBwQDAwACAQMSBJIB
GBkK7QMKBgQDAwACAhIEnQEEIxrcAyBUaGUgcG9zaXRpb24gb2YgdGhlIFt0ZXh0X3NlZ21l
bnRdW2dvb2dsZS5jbG91ZC5hdXRvbWwudjFiZXRhMS5Eb2N1bWVudC5MYXlvdXQudGV4dF9z
ZWdtZW50XSBpbiB0aGUgcGFnZS4KIENvbnRhaW5zIGV4YWN0bHkgNAoKIFtub3JtYWxpemVk
X3ZlcnRpY2VzXVtnb29nbGUuY2xvdWQuYXV0b21sLnYxYmV0YTEuQm91bmRpbmdQb2x5Lm5v
cm1hbGl6ZWRfdmVydGljZXNdCiBhbmQgdGhleSBhcmUgY29ubmVjdGVkIGJ5IGVkZ2VzIGlu
IHRoZSBvcmRlciBwcm92aWRlZCwgd2hpY2ggd2lsbAogcmVwcmVzZW50IGEgcmVjdGFuZ2xl
IHBhcmFsbGVsIHRvIHRoZSBmcmFtZS4gVGhlCiBbTm9ybWFsaXplZFZlcnRleC1zXVtnb29n
bGUuY2xvdWQuYXV0b21sLnYxYmV0YTEuTm9ybWFsaXplZFZlcnRleF0gYXJlCiByZWxhdGl2
ZSB0byB0aGUgcGFnZS4KIENvb3JkaW5hdGVzIGFyZSBiYXNlZCBvbiB0b3AtbGVmdCBhcyBw
b2ludCAoMCwwKS4KCg8KBwQDAwACAgYSBJ0BBBAKDwoHBAMDAAICARIEnQERHgoPCgcEAwMA
AgIDEgSdASEiCncKBgQDAwACAxIEoAEEKhpnIFRoZSB0eXBlIG9mIHRoZSBbdGV4dF9zZWdt
ZW50XVtnb29nbGUuY2xvdWQuYXV0b21sLnYxYmV0YTEuRG9jdW1lbnQuTGF5b3V0LnRleHRf
c2VnbWVudF0gaW4gZG9jdW1lbnQuCgoPCgcEAwMAAgMGEgSgAQQTCg8KBwQDAwACAwESBKAB
FCUKDwoHBAMDAAIDAxIEoAEoKQpHCgQEAwIAEgSkAQInGjkgQW4gaW5wdXQgY29uZmlnIHNw
ZWNpZnlpbmcgdGhlIGNvbnRlbnQgb2YgdGhlIGRvY3VtZW50LgoKDQoFBAMCAAYSBKQBAhUK
DQoFBAMCAAESBKQBFiIKDQoFBAMCAAMSBKQBJSYKOAoEBAMCARIEpwECIBoqIFRoZSBwbGFp
biB0ZXh0IHZlcnNpb24gb2YgdGhpcyBkb2N1bWVudC4KCg0KBQQDAgEGEgSnAQINCg0KBQQD
AgEBEgSnAQ4bCg0KBQQDAgEDEgSnAR4fClEKBAQDAgISBKsBAh0aQyBEZXNjcmliZXMgdGhl
IGxheW91dCBvZiB0aGUgZG9jdW1lbnQuCiBTb3J0ZWQgYnkgW3BhZ2VfbnVtYmVyXVtdLgoK
DQoFBAMCAgQSBKsBAgoKDQoFBAMCAgYSBKsBCxEKDQoFBAMCAgESBKsBEhgKDQoFBAMCAgMS
BKsBGxwKOwoEBAMCAxIErgECLRotIFRoZSBkaW1lbnNpb25zIG9mIHRoZSBwYWdlIGluIHRo
ZSBkb2N1bWVudC4KCg0KBQQDAgMGEgSuAQIUCg0KBQQDAgMBEgSuARUoCg0KBQQDAgMDEgSu
ASssCjAKBAQDAgQSBLEBAhcaIiBOdW1iZXIgb2YgcGFnZXMgaW4gdGhlIGRvY3VtZW50LgoK
DQoFBAMCBAUSBLEBAgcKDQoFBAMCBAESBLEBCBIKDQoFBAMCBAMSBLEBFRYKQAoCBAQSBrUB
AMcBARoyIEEgcmVwcmVzZW50YXRpb24gb2YgYSByb3cgaW4gYSByZWxhdGlvbmFsIHRhYmxl
LgoKCwoDBAQBEgS1AQgLCoYDCgQEBAIAEgS+AQImGvcCIFRoZSByZXNvdXJjZSBJRHMgb2Yg
dGhlIGNvbHVtbiBzcGVjcyBkZXNjcmliaW5nIHRoZSBjb2x1bW5zIG9mIHRoZSByb3cuCiBJ
ZiBzZXQgbXVzdCBjb250YWluLCBidXQgcG9zc2libHkgaW4gYSBkaWZmZXJlbnQgb3JkZXIs
IGFsbCBpbnB1dAogZmVhdHVyZQoKIFtjb2x1bW5fc3BlY19pZHNdW2dvb2dsZS5jbG91ZC5h
dXRvbWwudjFiZXRhMS5UYWJsZXNNb2RlbE1ldGFkYXRhLmlucHV0X2ZlYXR1cmVfY29sdW1u
X3NwZWNzXQogb2YgdGhlIE1vZGVsIHRoaXMgcm93IGlzIGJlaW5nIHBhc3NlZCB0by4KIE5v
dGU6IFRoZSBiZWxvdyBgdmFsdWVzYCBmaWVsZCBtdXN0IG1hdGNoIG9yZGVyIG9mIHRoaXMg
ZmllbGQsIGlmIHRoaXMKIGZpZWxkIGlzIHNldC4KCg0KBQQEAgAEEgS+AQIKCg0KBQQEAgAF
EgS+AQsRCg0KBQQEAgABEgS+ARIhCg0KBQQEAgADEgS+ASQlCqkCCgQEBAIBEgTGAQIsGpoC
IFJlcXVpcmVkLiBUaGUgdmFsdWVzIG9mIHRoZSByb3cgY2VsbHMsIGdpdmVuIGluIHRoZSBz
YW1lIG9yZGVyIGFzIHRoZQogY29sdW1uX3NwZWNfaWRzLCBvciwgaWYgbm90IHNldCwgdGhl
biBpbiB0aGUgc2FtZSBvcmRlciBhcyBpbnB1dAogZmVhdHVyZQoKIFtjb2x1bW5fc3BlY3Nd
W2dvb2dsZS5jbG91ZC5hdXRvbWwudjFiZXRhMS5UYWJsZXNNb2RlbE1ldGFkYXRhLmlucHV0
X2ZlYXR1cmVfY29sdW1uX3NwZWNzXQogb2YgdGhlIE1vZGVsIHRoaXMgcm93IGlzIGJlaW5n
IHBhc3NlZCB0by4KCg0KBQQEAgEEEgTGAQIKCg0KBQQEAgEGEgTGAQsgCg0KBQQEAgEBEgTG
ASEnCg0KBQQEAgEDEgTGASorCj0KAgQFEgbKAQDZAQEaLyBFeGFtcGxlIGRhdGEgdXNlZCBm
b3IgdHJhaW5pbmcgb3IgcHJlZGljdGlvbi4KCgsKAwQFARIEygEIFgo5CgQEBQgAEgbMAQLY
AQMaKSBSZXF1aXJlZC4gSW5wdXQgb25seS4gVGhlIGV4YW1wbGUgZGF0YS4KCg0KBQQFCAAB
EgTMAQgPCh4KBAQFAgASBM4BBBQaECBFeGFtcGxlIGltYWdlLgoKDQoFBAUCAAYSBM4BBAkK
DQoFBAUCAAESBM4BCg8KDQoFBAUCAAMSBM4BEhMKHQoEBAUCARIE0QEEIRoPIEV4YW1wbGUg
dGV4dC4KCg0KBQQFAgEGEgTRAQQPCg0KBQQFAgEBEgTRARAcCg0KBQQFAgEDEgTRAR8gCiEK
BAQFAgISBNQBBBoaEyBFeGFtcGxlIGRvY3VtZW50LgoKDQoFBAUCAgYSBNQBBAwKDQoFBAUC
AgESBNQBDRUKDQoFBAUCAgMSBNQBGBkKLQoEBAUCAxIE1wEEEBofIEV4YW1wbGUgcmVsYXRp
b25hbCB0YWJsZSByb3cuCgoNCgUEBQIDBhIE1wEEBwoNCgUEBQIDARIE1wEICwoNCgUEBQID
AxIE1wEOD2IGcHJvdG8z
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Automl::V1beta1::DataItems::Image ===
    # Fields for Image
    # Field: image_bytes Type: 12 ()
    # Field: input_config Type: 11 (.google.cloud.automl.v1beta1.InputConfig)
    # Field: thumbnail_uri Type: 9 ()

# === Message: Google::Cloud::Automl::V1beta1::DataItems::TextSnippet ===
    # Fields for TextSnippet
    # Field: content Type: 9 ()
    # Field: mime_type Type: 9 ()
    # Field: content_uri Type: 9 ()

# === Message: Google::Cloud::Automl::V1beta1::DataItems::DocumentDimensions ===
    # Fields for DocumentDimensions
    # Field: unit Type: 14 (.google.cloud.automl.v1beta1.DocumentDimensions.DocumentDimensionUnit)
    # Field: width Type: 2 ()
    # Field: height Type: 2 ()

# Enum: DocumentDimensions::DocumentDimensionUnit
our $DocumentDimensions_DOCUMENT_DIMENSION_UNIT_UNSPECIFIED = 0;
our $DocumentDimensions_INCH = 1;
our $DocumentDimensions_CENTIMETER = 2;
our $DocumentDimensions_POINT = 3;

# === Message: Google::Cloud::Automl::V1beta1::DataItems::Document ===
    # Fields for Document
    # Field: input_config Type: 11 (.google.cloud.automl.v1beta1.DocumentInputConfig)
    # Field: document_text Type: 11 (.google.cloud.automl.v1beta1.TextSnippet)
    # Field: layout Type: 11 (.google.cloud.automl.v1beta1.Document.Layout)
    # Field: document_dimensions Type: 11 (.google.cloud.automl.v1beta1.DocumentDimensions)
    # Field: page_count Type: 5 ()

# === Message: Google::Cloud::Automl::V1beta1::DataItems::Row ===
    # Fields for Row
    # Field: column_spec_ids Type: 9 ()
    # Field: values Type: 11 (.google.protobuf.Value)

# === Message: Google::Cloud::Automl::V1beta1::DataItems::ExamplePayload ===
    # Fields for ExamplePayload
    # Field: image Type: 11 (.google.cloud.automl.v1beta1.Image)
    # Field: text_snippet Type: 11 (.google.cloud.automl.v1beta1.TextSnippet)
    # Field: document Type: 11 (.google.cloud.automl.v1beta1.Document)
    # Field: row Type: 11 (.google.cloud.automl.v1beta1.Row)

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Automl::V1beta1::DataItems - Compiled Protocol Buffers messages for google/cloud/automl/v1beta1/data_items.proto

=head1 SYNOPSIS

    use Google::Cloud::Automl::V1beta1::DataItems;

    my $msg = Google::Cloud::Automl::V1beta1::DataItems::Image->new({
        image_bytes => $image_bytes,
        input_config => $input_config,
        thumbnail_uri => $thumbnail_uri,
    });

    # Read or update a field
    my $val = $msg->image_bytes();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Automl::V1beta1::DataItems::Image->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/automl/v1beta1/data_items.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Automl::V1beta1::DataItems::Image

A representation of an image.
Only images up to 30MB in size are supported.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->image_bytes() >> / C<< $msg->image_bytes($value) >>

Type: C<Bytes>

Image content represented as a stream of bytes.
Note: As with all `bytes` fields, protobuffers use a pure binary
representation, whereas JSON representations use base64.

=item * C<< $msg->input_config() >> / C<< $msg->input_config($value) >>

Type: C<Message> (L<Google::Cloud::Automl::V1beta1::Io::InputConfig>)

An input config specifying the content of the image.

=item * C<< $msg->thumbnail_uri() >> / C<< $msg->thumbnail_uri($value) >>

Type: C<String>

Output only. HTTP URI to the thumbnail image.

=back

=head2 Google::Cloud::Automl::V1beta1::DataItems::TextSnippet

A representation of a text snippet.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->content() >> / C<< $msg->content($value) >>

Type: C<String>

Required. The content of the text snippet as a string. Up to 250000
characters long.

=item * C<< $msg->mime_type() >> / C<< $msg->mime_type($value) >>

Type: C<String>

Optional. The format of [content][google.cloud.automl.v1beta1.TextSnippet.content]. Currently the only two allowed
values are "text/html" and "text/plain". If left blank, the format is
automatically determined from the type of the uploaded [content][google.cloud.automl.v1beta1.TextSnippet.content].

=item * C<< $msg->content_uri() >> / C<< $msg->content_uri($value) >>

Type: C<String>

Output only. HTTP URI where you can download the content.

=back

=head2 Google::Cloud::Automl::V1beta1::DataItems::DocumentDimensions

Message that describes dimension of a document.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->unit() >> / C<< $msg->unit($value) >>

Type: C<Enum> (L<Google::Cloud::Automl::V1beta1::DocumentDimensions::DocumentDimensionUnit>)

Unit of the dimension.

=item * C<< $msg->width() >> / C<< $msg->width($value) >>

Type: C<Float>

Width value of the document, works together with the unit.

=item * C<< $msg->height() >> / C<< $msg->height($value) >>

Type: C<Float>

Height value of the document, works together with the unit.

=back

=head3 Enum: DocumentDimensions::DocumentDimensionUnit

=over 4

=item * C<DOCUMENT_DIMENSION_UNIT_UNSPECIFIED> => C<0>

=item * C<INCH> => C<1>

=item * C<CENTIMETER> => C<2>

=item * C<POINT> => C<3>

=back

=head2 Google::Cloud::Automl::V1beta1::DataItems::Document

A structured text document e.g. a PDF.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->input_config() >> / C<< $msg->input_config($value) >>

Type: C<Message> (L<Google::Cloud::Automl::V1beta1::Io::DocumentInputConfig>)

An input config specifying the content of the document.

=item * C<< $msg->document_text() >> / C<< $msg->document_text($value) >>

Type: C<Message> (L<Google::Cloud::Automl::V1beta1::DataItems::TextSnippet>)

The plain text version of this document.

=item * C<< $msg->layout() >> / C<< $msg->layout($value) >>

Type: C<Message> (L<Google::Cloud::Automl::V1beta1::DataItems::Document::Layout>)

Describes the layout of the document.
Sorted by [page_number][].

=item * C<< $msg->document_dimensions() >> / C<< $msg->document_dimensions($value) >>

Type: C<Message> (L<Google::Cloud::Automl::V1beta1::DataItems::DocumentDimensions>)

The dimensions of the page in the document.

=item * C<< $msg->page_count() >> / C<< $msg->page_count($value) >>

Type: C<Int32>

Number of pages in the document.

=back

=head2 Google::Cloud::Automl::V1beta1::DataItems::Row

A representation of a row in a relational table.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->column_spec_ids() >> / C<< $msg->column_spec_ids($value) >>

Type: C<String>

The resource IDs of the column specs describing the columns of the row.
If set must contain, but possibly in a different order, all input
feature

[column_spec_ids][google.cloud.automl.v1beta1.TablesModelMetadata.input_feature_column_specs]
of the Model this row is being passed to.
Note: The below `values` field must match order of this field, if this
field is set.

=item * C<< $msg->values() >> / C<< $msg->values($value) >>

Type: C<Message> (L<Google::Protobuf::Struct::Value>)

Required. The values of the row cells, given in the same order as the
column_spec_ids, or, if not set, then in the same order as input
feature

[column_specs][google.cloud.automl.v1beta1.TablesModelMetadata.input_feature_column_specs]
of the Model this row is being passed to.

=back

=head2 Google::Cloud::Automl::V1beta1::DataItems::ExamplePayload

Example data used for training or prediction.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->image() >> / C<< $msg->image($value) >>

Type: C<Message> (L<Google::Cloud::Automl::V1beta1::DataItems::Image>)

Example image.

=item * C<< $msg->text_snippet() >> / C<< $msg->text_snippet($value) >>

Type: C<Message> (L<Google::Cloud::Automl::V1beta1::DataItems::TextSnippet>)

Example text.

=item * C<< $msg->document() >> / C<< $msg->document($value) >>

Type: C<Message> (L<Google::Cloud::Automl::V1beta1::DataItems::Document>)

Example document.

=item * C<< $msg->row() >> / C<< $msg->row($value) >>

Type: C<Message> (L<Google::Cloud::Automl::V1beta1::DataItems::Row>)

Example relational table row.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Automl::V1beta1::DataItems::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
