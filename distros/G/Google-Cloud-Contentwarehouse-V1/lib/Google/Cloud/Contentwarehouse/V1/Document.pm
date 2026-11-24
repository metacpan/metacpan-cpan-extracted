package Google::Cloud::Contentwarehouse::V1::Document;

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
    eval { require Google::Cloud::Documentai::V1::Document };
    eval { require Google::Protobuf::Timestamp };
    eval { require Google::Type::Datetime };
    my $descriptor_b64 = <<'EOF';
Ci9nb29nbGUvY2xvdWQvY29udGVudHdhcmVob3VzZS92MS9kb2N1bWVudC5wcm90bxIgZ29v
Z2xlLmNsb3VkLmNvbnRlbnR3YXJlaG91c2UudjEaH2dvb2dsZS9hcGkvZmllbGRfYmVoYXZp
b3IucHJvdG8aGWdvb2dsZS9hcGkvcmVzb3VyY2UucHJvdG8aKWdvb2dsZS9jbG91ZC9kb2N1
bWVudGFpL3YxL2RvY3VtZW50LnByb3RvGh9nb29nbGUvcHJvdG9idWYvdGltZXN0YW1wLnBy
b3RvGhpnb29nbGUvdHlwZS9kYXRldGltZS5wcm90byLWCwoIRG9jdW1lbnQSEgoEbmFtZRgB
IAEoCVIEbmFtZRIhCgxyZWZlcmVuY2VfaWQYCyABKAlSC3JlZmVyZW5jZUlkEiYKDGRpc3Bs
YXlfbmFtZRgCIAEoCUID4EECUgtkaXNwbGF5TmFtZRIUCgV0aXRsZRgSIAEoCVIFdGl0bGUS
HwoLZGlzcGxheV91cmkYESABKAlSCmRpc3BsYXlVcmkSZQoUZG9jdW1lbnRfc2NoZW1hX25h
bWUYAyABKAlCM/pBMAouY29udGVudHdhcmVob3VzZS5nb29nbGVhcGlzLmNvbS9Eb2N1bWVu
dFNjaGVtYVISZG9jdW1lbnRTY2hlbWFOYW1lEh8KCnBsYWluX3RleHQYDyABKAlIAFIJcGxh
aW5UZXh0ElIKEWNsb3VkX2FpX2RvY3VtZW50GAQgASgLMiQuZ29vZ2xlLmNsb3VkLmRvY3Vt
ZW50YWkudjEuRG9jdW1lbnRIAFIPY2xvdWRBaURvY3VtZW50EjgKFnN0cnVjdHVyZWRfY29u
dGVudF91cmkYECABKAlCAhgBUhRzdHJ1Y3R1cmVkQ29udGVudFVyaRIsChFyYXdfZG9jdW1l
bnRfcGF0aBgFIAEoCUgBUg9yYXdEb2N1bWVudFBhdGgSMAoTaW5saW5lX3Jhd19kb2N1bWVu
dBgGIAEoDEgBUhFpbmxpbmVSYXdEb2N1bWVudBJKCgpwcm9wZXJ0aWVzGAcgAygLMiouZ29v
Z2xlLmNsb3VkLmNvbnRlbnR3YXJlaG91c2UudjEuUHJvcGVydHlSCnByb3BlcnRpZXMSQAoL
dXBkYXRlX3RpbWUYCCABKAsyGi5nb29nbGUucHJvdG9idWYuVGltZXN0YW1wQgPgQQNSCnVw
ZGF0ZVRpbWUSQAoLY3JlYXRlX3RpbWUYCSABKAsyGi5nb29nbGUucHJvdG9idWYuVGltZXN0
YW1wQgPgQQNSCmNyZWF0ZVRpbWUSagoWcmF3X2RvY3VtZW50X2ZpbGVfdHlwZRgKIAEoDjI1
Lmdvb2dsZS5jbG91ZC5jb250ZW50d2FyZWhvdXNlLnYxLlJhd0RvY3VtZW50RmlsZVR5cGVS
E3Jhd0RvY3VtZW50RmlsZVR5cGUSJwoNYXN5bmNfZW5hYmxlZBgMIAEoCEICGAFSDGFzeW5j
RW5hYmxlZBJcChBjb250ZW50X2NhdGVnb3J5GBQgASgOMjEuZ29vZ2xlLmNsb3VkLmNvbnRl
bnR3YXJlaG91c2UudjEuQ29udGVudENhdGVnb3J5Ug9jb250ZW50Q2F0ZWdvcnkSPAoYdGV4
dF9leHRyYWN0aW9uX2Rpc2FibGVkGBMgASgIQgIYAVIWdGV4dEV4dHJhY3Rpb25EaXNhYmxl
ZBI2Chd0ZXh0X2V4dHJhY3Rpb25fZW5hYmxlZBgVIAEoCFIVdGV4dEV4dHJhY3Rpb25FbmFi
bGVkEhgKB2NyZWF0b3IYDSABKAlSB2NyZWF0b3ISGAoHdXBkYXRlchgOIAEoCVIHdXBkYXRl
chJKChBkaXNwb3NpdGlvbl90aW1lGBYgASgLMhouZ29vZ2xlLnByb3RvYnVmLlRpbWVzdGFt
cEID4EEDUg9kaXNwb3NpdGlvblRpbWUSIgoKbGVnYWxfaG9sZBgXIAEoCEID4EEDUglsZWdh
bEhvbGQ6ugHqQbYBCihjb250ZW50d2FyZWhvdXNlLmdvb2dsZWFwaXMuY29tL0RvY3VtZW50
Ejxwcm9qZWN0cy97cHJvamVjdH0vbG9jYXRpb25zL3tsb2NhdGlvbn0vZG9jdW1lbnRzL3tk
b2N1bWVudH0STHByb2plY3RzL3twcm9qZWN0fS9sb2NhdGlvbnMve2xvY2F0aW9ufS9kb2N1
bWVudHMvcmVmZXJlbmNlSWQve3JlZmVyZW5jZV9pZH1CFAoSc3RydWN0dXJlZF9jb250ZW50
Qg4KDHJhd19kb2N1bWVudCKeBAoRRG9jdW1lbnRSZWZlcmVuY2USVQoNZG9jdW1lbnRfbmFt
ZRgBIAEoCUIw4EEC+kEqCihjb250ZW50d2FyZWhvdXNlLmdvb2dsZWFwaXMuY29tL0RvY3Vt
ZW50Ugxkb2N1bWVudE5hbWUSIQoMZGlzcGxheV9uYW1lGAIgASgJUgtkaXNwbGF5TmFtZRIY
CgdzbmlwcGV0GAMgASgJUgdzbmlwcGV0EiwKEmRvY3VtZW50X2lzX2ZvbGRlchgEIAEoCFIQ
ZG9jdW1lbnRJc0ZvbGRlchJACgt1cGRhdGVfdGltZRgFIAEoCzIaLmdvb2dsZS5wcm90b2J1
Zi5UaW1lc3RhbXBCA+BBA1IKdXBkYXRlVGltZRJACgtjcmVhdGVfdGltZRgGIAEoCzIaLmdv
b2dsZS5wcm90b2J1Zi5UaW1lc3RhbXBCA+BBA1IKY3JlYXRlVGltZRJACgtkZWxldGVfdGlt
ZRgHIAEoCzIaLmdvb2dsZS5wcm90b2J1Zi5UaW1lc3RhbXBCA+BBA1IKZGVsZXRlVGltZRI/
Chxkb2N1bWVudF9pc19yZXRlbnRpb25fZm9sZGVyGAggASgIUhlkb2N1bWVudElzUmV0ZW50
aW9uRm9sZGVyEkAKHWRvY3VtZW50X2lzX2xlZ2FsX2hvbGRfZm9sZGVyGAkgASgIUhlkb2N1
bWVudElzTGVnYWxIb2xkRm9sZGVyIuUFCghQcm9wZXJ0eRIXCgRuYW1lGAEgASgJQgPgQQJS
BG5hbWUSVwoOaW50ZWdlcl92YWx1ZXMYAiABKAsyLi5nb29nbGUuY2xvdWQuY29udGVudHdh
cmVob3VzZS52MS5JbnRlZ2VyQXJyYXlIAFINaW50ZWdlclZhbHVlcxJRCgxmbG9hdF92YWx1
ZXMYAyABKAsyLC5nb29nbGUuY2xvdWQuY29udGVudHdhcmVob3VzZS52MS5GbG9hdEFycmF5
SABSC2Zsb2F0VmFsdWVzEk4KC3RleHRfdmFsdWVzGAQgASgLMisuZ29vZ2xlLmNsb3VkLmNv
bnRlbnR3YXJlaG91c2UudjEuVGV4dEFycmF5SABSCnRleHRWYWx1ZXMSTgoLZW51bV92YWx1
ZXMYBSABKAsyKy5nb29nbGUuY2xvdWQuY29udGVudHdhcmVob3VzZS52MS5FbnVtQXJyYXlI
AFIKZW51bVZhbHVlcxJaCg9wcm9wZXJ0eV92YWx1ZXMYBiABKAsyLy5nb29nbGUuY2xvdWQu
Y29udGVudHdhcmVob3VzZS52MS5Qcm9wZXJ0eUFycmF5SABSDnByb3BlcnR5VmFsdWVzElsK
EGRhdGVfdGltZV92YWx1ZXMYByABKAsyLy5nb29nbGUuY2xvdWQuY29udGVudHdhcmVob3Vz
ZS52MS5EYXRlVGltZUFycmF5SABSDmRhdGVUaW1lVmFsdWVzElIKDG1hcF9wcm9wZXJ0eRgI
IAEoCzItLmdvb2dsZS5jbG91ZC5jb250ZW50d2FyZWhvdXNlLnYxLk1hcFByb3BlcnR5SABS
C21hcFByb3BlcnR5El0KEHRpbWVzdGFtcF92YWx1ZXMYCSABKAsyMC5nb29nbGUuY2xvdWQu
Y29udGVudHdhcmVob3VzZS52MS5UaW1lc3RhbXBBcnJheUgAUg90aW1lc3RhbXBWYWx1ZXNC
CAoGdmFsdWVzIiYKDEludGVnZXJBcnJheRIWCgZ2YWx1ZXMYASADKAVSBnZhbHVlcyIkCgpG
bG9hdEFycmF5EhYKBnZhbHVlcxgBIAMoAlIGdmFsdWVzIiMKCVRleHRBcnJheRIWCgZ2YWx1
ZXMYASADKAlSBnZhbHVlcyIjCglFbnVtQXJyYXkSFgoGdmFsdWVzGAEgAygJUgZ2YWx1ZXMi
PgoNRGF0ZVRpbWVBcnJheRItCgZ2YWx1ZXMYASADKAsyFS5nb29nbGUudHlwZS5EYXRlVGlt
ZVIGdmFsdWVzIloKDlRpbWVzdGFtcEFycmF5EkgKBnZhbHVlcxgBIAMoCzIwLmdvb2dsZS5j
bG91ZC5jb250ZW50d2FyZWhvdXNlLnYxLlRpbWVzdGFtcFZhbHVlUgZ2YWx1ZXMigQEKDlRp
bWVzdGFtcFZhbHVlEkUKD3RpbWVzdGFtcF92YWx1ZRgBIAEoCzIaLmdvb2dsZS5wcm90b2J1
Zi5UaW1lc3RhbXBIAFIOdGltZXN0YW1wVmFsdWUSHwoKdGV4dF92YWx1ZRgCIAEoCUgAUgl0
ZXh0VmFsdWVCBwoFdmFsdWUiWwoNUHJvcGVydHlBcnJheRJKCgpwcm9wZXJ0aWVzGAEgAygL
MiouZ29vZ2xlLmNsb3VkLmNvbnRlbnR3YXJlaG91c2UudjEuUHJvcGVydHlSCnByb3BlcnRp
ZXMixAEKC01hcFByb3BlcnR5ElEKBmZpZWxkcxgBIAMoCzI5Lmdvb2dsZS5jbG91ZC5jb250
ZW50d2FyZWhvdXNlLnYxLk1hcFByb3BlcnR5LkZpZWxkc0VudHJ5UgZmaWVsZHMaYgoLRmll
bGRzRW50cnkSEAoDa2V5GAEgASgJUgNrZXkSPQoFdmFsdWUYAiABKAsyJy5nb29nbGUuY2xv
dWQuY29udGVudHdhcmVob3VzZS52MS5WYWx1ZVIFdmFsdWU6AjgBIogDCgVWYWx1ZRIhCgtm
bG9hdF92YWx1ZRgBIAEoAkgAUgpmbG9hdFZhbHVlEh0KCWludF92YWx1ZRgCIAEoBUgAUghp
bnRWYWx1ZRIjCgxzdHJpbmdfdmFsdWUYAyABKAlIAFILc3RyaW5nVmFsdWUSTAoKZW51bV92
YWx1ZRgEIAEoCzIrLmdvb2dsZS5jbG91ZC5jb250ZW50d2FyZWhvdXNlLnYxLkVudW1WYWx1
ZUgAUgllbnVtVmFsdWUSPgoOZGF0ZXRpbWVfdmFsdWUYBSABKAsyFS5nb29nbGUudHlwZS5E
YXRlVGltZUgAUg1kYXRldGltZVZhbHVlElsKD3RpbWVzdGFtcF92YWx1ZRgGIAEoCzIwLmdv
b2dsZS5jbG91ZC5jb250ZW50d2FyZWhvdXNlLnYxLlRpbWVzdGFtcFZhbHVlSABSDnRpbWVz
dGFtcFZhbHVlEiUKDWJvb2xlYW5fdmFsdWUYByABKAhIAFIMYm9vbGVhblZhbHVlQgYKBGtp
bmQiIQoJRW51bVZhbHVlEhQKBXZhbHVlGAEgASgJUgV2YWx1ZSqCAgoTUmF3RG9jdW1lbnRG
aWxlVHlwZRImCiJSQVdfRE9DVU1FTlRfRklMRV9UWVBFX1VOU1BFQ0lGSUVEEAASHgoaUkFX
X0RPQ1VNRU5UX0ZJTEVfVFlQRV9QREYQARIfChtSQVdfRE9DVU1FTlRfRklMRV9UWVBFX0RP
Q1gQAhIfChtSQVdfRE9DVU1FTlRfRklMRV9UWVBFX1hMU1gQAxIfChtSQVdfRE9DVU1FTlRf
RklMRV9UWVBFX1BQVFgQBBIfChtSQVdfRE9DVU1FTlRfRklMRV9UWVBFX1RFWFQQBRIfChtS
QVdfRE9DVU1FTlRfRklMRV9UWVBFX1RJRkYQBiqHAQoPQ29udGVudENhdGVnb3J5EiAKHENP
TlRFTlRfQ0FURUdPUllfVU5TUEVDSUZJRUQQABIaChZDT05URU5UX0NBVEVHT1JZX0lNQUdF
EAESGgoWQ09OVEVOVF9DQVRFR09SWV9BVURJTxACEhoKFkNPTlRFTlRfQ0FURUdPUllfVklE
RU8QA0L1AQokY29tLmdvb2dsZS5jbG91ZC5jb250ZW50d2FyZWhvdXNlLnYxQg1Eb2N1bWVu
dFByb3RvUAFaUGNsb3VkLmdvb2dsZS5jb20vZ28vY29udGVudHdhcmVob3VzZS9hcGl2MS9j
b250ZW50d2FyZWhvdXNlcGI7Y29udGVudHdhcmVob3VzZXBiqgIgR29vZ2xlLkNsb3VkLkNv
bnRlbnRXYXJlaG91c2UuVjHKAiBHb29nbGVcQ2xvdWRcQ29udGVudFdhcmVob3VzZVxWMeoC
I0dvb2dsZTo6Q2xvdWQ6OkNvbnRlbnRXYXJlaG91c2U6OlYxSsRXCgcSBQ4A4wIBCrwECgEM
EgMOABIysQQgQ29weXJpZ2h0IDIwMjUgR29vZ2xlIExMQwoKIExpY2Vuc2VkIHVuZGVyIHRo
ZSBBcGFjaGUgTGljZW5zZSwgVmVyc2lvbiAyLjAgKHRoZSAiTGljZW5zZSIpOwogeW91IG1h
eSBub3QgdXNlIHRoaXMgZmlsZSBleGNlcHQgaW4gY29tcGxpYW5jZSB3aXRoIHRoZSBMaWNl
bnNlLgogWW91IG1heSBvYnRhaW4gYSBjb3B5IG9mIHRoZSBMaWNlbnNlIGF0CgogICAgIGh0
dHA6Ly93d3cuYXBhY2hlLm9yZy9saWNlbnNlcy9MSUNFTlNFLTIuMAoKIFVubGVzcyByZXF1
aXJlZCBieSBhcHBsaWNhYmxlIGxhdyBvciBhZ3JlZWQgdG8gaW4gd3JpdGluZywgc29mdHdh
cmUKIGRpc3RyaWJ1dGVkIHVuZGVyIHRoZSBMaWNlbnNlIGlzIGRpc3RyaWJ1dGVkIG9uIGFu
ICJBUyBJUyIgQkFTSVMsCiBXSVRIT1VUIFdBUlJBTlRJRVMgT1IgQ09ORElUSU9OUyBPRiBB
TlkgS0lORCwgZWl0aGVyIGV4cHJlc3Mgb3IgaW1wbGllZC4KIFNlZSB0aGUgTGljZW5zZSBm
b3IgdGhlIHNwZWNpZmljIGxhbmd1YWdlIGdvdmVybmluZyBwZXJtaXNzaW9ucyBhbmQKIGxp
bWl0YXRpb25zIHVuZGVyIHRoZSBMaWNlbnNlLgoKCAoBAhIDEAApCgkKAgMAEgMSACkKCQoC
AwESAxMAIwoJCgIDAhIDFAAzCgkKAgMDEgMVACkKCQoCAwQSAxYAJAoICgEIEgMYAD0KCQoC
CCUSAxgAPQoICgEIEgMZAGcKCQoCCAsSAxkAZwoICgEIEgMaACIKCQoCCAoSAxoAIgoICgEI
EgMbAC4KCQoCCAgSAxsALgoICgEIEgMcAD0KCQoCCAESAxwAPQoICgEIEgMdAD0KCQoCCCkS
Ax0APQoICgEIEgMeADwKCQoCCC0SAx4APApKCgIEABIFIQCEAQEaPSBEZWZpbmVzIHRoZSBz
dHJ1Y3R1cmUgZm9yIGNvbnRlbnQgd2FyZWhvdXNlIGRvY3VtZW50IHByb3RvLgoKCgoDBAAB
EgMhCBAKCwoDBAAHEgQiAiYECg0KBQQAB50IEgQiAiYECrQBCgQEAAIAEgMtAhIapgEgVGhl
IHJlc291cmNlIG5hbWUgb2YgdGhlIGRvY3VtZW50LgogRm9ybWF0OgogcHJvamVjdHMve3By
b2plY3RfbnVtYmVyfS9sb2NhdGlvbnMve2xvY2F0aW9ufS9kb2N1bWVudHMve2RvY3VtZW50
X2lkfS4KCiBUaGUgbmFtZSBpcyBpZ25vcmVkIHdoZW4gY3JlYXRpbmcgYSBkb2N1bWVudC4K
CgwKBQQAAgAFEgMtAggKDAoFBAACAAESAy0JDQoMCgUEAAIAAxIDLRARCloKBAQAAgESAzAC
GxpNIFRoZSByZWZlcmVuY2UgSUQgc2V0IGJ5IGN1c3RvbWVycy4gTXVzdCBiZSB1bmlxdWUg
cGVyIHByb2plY3QgYW5kIGxvY2F0aW9uLgoKDAoFBAACAQUSAzACCAoMCgUEAAIBARIDMAkV
CgwKBQQAAgEDEgMwGBoKmgIKBAQAAgISAzYCQxqMAiBSZXF1aXJlZC4gRGlzcGxheSBuYW1l
IG9mIHRoZSBkb2N1bWVudCBnaXZlbiBieSB0aGUgdXNlci4gVGhpcyBuYW1lIHdpbGwgYmUK
IGRpc3BsYXllZCBpbiB0aGUgVUkuIEN1c3RvbWVyIGNhbiBwb3B1bGF0ZSB0aGlzIGZpZWxk
IHdpdGggdGhlIG5hbWUgb2YgdGhlCiBkb2N1bWVudC4gVGhpcyBkaWZmZXJzIGZyb20gdGhl
ICd0aXRsZScgZmllbGQgYXMgJ3RpdGxlJyBpcyBvcHRpb25hbCBhbmQKIHN0b3JlcyB0aGUg
dG9wIGhlYWRpbmcgaW4gdGhlIGRvY3VtZW50LgoKDAoFBAACAgUSAzYCCAoMCgUEAAICARID
NgkVCgwKBQQAAgIDEgM2GBkKDAoFBAACAggSAzYaQgoPCggEAAICCJwIABIDNhtBCnMKBAQA
AgMSAzoCFBpmIFRpdGxlIHRoYXQgZGVzY3JpYmVzIHRoZSBkb2N1bWVudC4KIFRoaXMgY2Fu
IGJlIHRoZSB0b3AgaGVhZGluZyBvciB0ZXh0IHRoYXQgZGVzY3JpYmVzIHRoZSBkb2N1bWVu
dC4KCgwKBQQAAgMFEgM6AggKDAoFBAACAwESAzoJDgoMCgUEAAIDAxIDOhETCkMKBAQAAgQS
Az0CGho2IFVyaSB0byBkaXNwbGF5IHRoZSBkb2N1bWVudCwgZm9yIGV4YW1wbGUsIGluIHRo
ZSBVSS4KCgwKBQQAAgQFEgM9AggKDAoFBAACBAESAz0JFAoMCgUEAAIEAxIDPRcZCogBCgQE
AAIFEgRCAkQFGnogVGhlIERvY3VtZW50IHNjaGVtYSBuYW1lLgogRm9ybWF0OgogcHJvamVj
dHMve3Byb2plY3RfbnVtYmVyfS9sb2NhdGlvbnMve2xvY2F0aW9ufS9kb2N1bWVudFNjaGVt
YXMve2RvY3VtZW50X3NjaGVtYV9pZH0uCgoMCgUEAAIFBRIDQgIICgwKBQQAAgUBEgNCCR0K
DAoFBAACBQMSA0IgIQoNCgUEAAIFCBIEQiJEBAoPCgcEAAIFCJ8IEgRCI0QDCgwKBAQACAAS
BEYCTAMKDAoFBAAIAAESA0YIGgo4CgQEAAIGEgNIBBsaKyBPdGhlciBkb2N1bWVudCBmb3Jt
YXQsIHN1Y2ggYXMgUFBUWCwgWExYUwoKDAoFBAACBgUSA0gECgoMCgUEAAIGARIDSAsVCgwK
BQQAAgYDEgNIGBoKUAoEBAACBxIDSwQ+GkMgRG9jdW1lbnQgQUkgZm9ybWF0IHRvIHNhdmUg
dGhlIHN0cnVjdHVyZWQgY29udGVudCwgaW5jbHVkaW5nIE9DUi4KCgwKBQQAAgcGEgNLBCcK
DAoFBAACBwESA0soOQoMCgUEAAIHAxIDSzw9CjgKBAQAAggSA08CORorIEEgcGF0aCBsaW5r
ZWQgdG8gc3RydWN0dXJlZCBjb250ZW50IGZpbGUuCgoMCgUEAAIIBRIDTwIICgwKBQQAAggB
EgNPCR8KDAoFBAACCAMSA08iJAoMCgUEAAIICBIDTyU4Cg0KBgQAAggIAxIDTyY3CiIKBAQA
CAESBFICWAMaFCBSYXcgZG9jdW1lbnQgZmlsZS4KCgwKBQQACAEBEgNSCBQKNwoEBAACCRID
VAQhGiogUmF3IGRvY3VtZW50IGZpbGUgaW4gQ2xvdWQgU3RvcmFnZSBwYXRoLgoKDAoFBAAC
CQUSA1QECgoMCgUEAAIJARIDVAscCgwKBQQAAgkDEgNUHyAKJAoEBAACChIDVwQiGhcgUmF3
IGRvY3VtZW50IGNvbnRlbnQuCgoMCgUEAAIKBRIDVwQJCgwKBQQAAgoBEgNXCh0KDAoFBAAC
CgMSA1cgIQo+CgQEAAILEgNbAiMaMSBMaXN0IG9mIHZhbHVlcyB0aGF0IGFyZSB1c2VyIHN1
cHBsaWVkIG1ldGFkYXRhLgoKDAoFBAACCwQSA1sCCgoMCgUEAAILBhIDWwsTCgwKBQQAAgsB
EgNbFB4KDAoFBAACCwMSA1shIgpICgQEAAIMEgReAl8yGjogT3V0cHV0IG9ubHkuIFRoZSB0
aW1lIHdoZW4gdGhlIGRvY3VtZW50IGlzIGxhc3QgdXBkYXRlZC4KCgwKBQQAAgwGEgNeAhsK
DAoFBAACDAESA14cJwoMCgUEAAIMAxIDXiorCgwKBQQAAgwIEgNfBjEKDwoIBAACDAicCAAS
A18HMApDCgQEAAINEgRiAmMyGjUgT3V0cHV0IG9ubHkuIFRoZSB0aW1lIHdoZW4gdGhlIGRv
Y3VtZW50IGlzIGNyZWF0ZWQuCgoMCgUEAAINBhIDYgIbCgwKBQQAAg0BEgNiHCcKDAoFBAAC
DQMSA2IqKwoMCgUEAAINCBIDYwYxCg8KCAQAAg0InAgAEgNjBzAKkgIKBAQAAg4SA2kCMhqE
AiBUaGlzIGlzIHVzZWQgd2hlbiBEb2NBSSB3YXMgbm90IHVzZWQgdG8gbG9hZCB0aGUgZG9j
dW1lbnQgYW5kIHBhcnNpbmcvCiBleHRyYWN0aW5nIGlzIG5lZWRlZCBmb3IgdGhlIGlubGlu
ZV9yYXdfZG9jdW1lbnQuICBGb3IgZXhhbXBsZSwgaWYKIGlubGluZV9yYXdfZG9jdW1lbnQg
aXMgdGhlIGJ5dGUgcmVwcmVzZW50YXRpb24gb2YgYSBQREYgZmlsZSwgdGhlbgogdGhpcyBz
aG91bGQgYmUgc2V0IHRvOiBSQVdfRE9DVU1FTlRfRklMRV9UWVBFX1BERi4KCgwKBQQAAg4G
EgNpAhUKDAoFBAACDgESA2kWLAoMCgUEAAIOAxIDaS8xClYKBAQAAg8SA2wCLhpJIElmIHRy
dWUsIG1ha2VzIHRoZSBkb2N1bWVudCB2aXNpYmxlIHRvIGFzeW5jaHJvbm91cyBwb2xpY2ll
cyBhbmQgcnVsZXMuCgoMCgUEAAIPBRIDbAIGCgwKBQQAAg8BEgNsBxQKDAoFBAACDwMSA2wX
GQoMCgUEAAIPCBIDbBotCg0KBgQAAg8IAxIDbBssClkKBAQAAhASA28CKBpMIEluZGljYXRl
cyB0aGUgY2F0ZWdvcnkgKGltYWdlLCBhdWRpbywgdmlkZW8gZXRjLikgb2YgdGhlIG9yaWdp
bmFsIGNvbnRlbnQuCgoMCgUEAAIQBhIDbwIRCgwKBQQAAhABEgNvEiIKDAoFBAACEAMSA28l
Jwo+CgQEAAIREgNyAjkaMSBJZiB0cnVlLCB0ZXh0IGV4dHJhY3Rpb24gd2lsbCBub3QgYmUg
cGVyZm9ybWVkLgoKDAoFBAACEQUSA3ICBgoMCgUEAAIRARIDcgcfCgwKBQQAAhEDEgNyIiQK
DAoFBAACEQgSA3IlOAoNCgYEAAIRCAMSA3ImNwo6CgQEAAISEgN1AiQaLSBJZiB0cnVlLCB0
ZXh0IGV4dHJhY3Rpb24gd2lsbCBiZSBwZXJmb3JtZWQuCgoMCgUEAAISBRIDdQIGCgwKBQQA
AhIBEgN1Bx4KDAoFBAACEgMSA3UhIwoxCgQEAAITEgN4AhYaJCBUaGUgdXNlciB3aG8gY3Jl
YXRlcyB0aGUgZG9jdW1lbnQuCgoMCgUEAAITBRIDeAIICgwKBQQAAhMBEgN4CRAKDAoFBAAC
EwMSA3gTFQo4CgQEAAIUEgN7AhYaKyBUaGUgdXNlciB3aG8gbGFzdGx5IHVwZGF0ZXMgdGhl
IGRvY3VtZW50LgoKDAoFBAACFAUSA3sCCAoMCgUEAAIUARIDewkQCgwKBQQAAhQDEgN7ExUK
egoEBAACFRIFfwKAATIaayBPdXRwdXQgb25seS4gSWYgbGlua2VkIHRvIGEgQ29sbGVjdGlv
biB3aXRoIFJldGVudGlvblBvbGljeSwgdGhlIGRhdGUgd2hlbgogdGhlIGRvY3VtZW50IGJl
Y29tZXMgbXV0YWJsZS4KCgwKBQQAAhUGEgN/AhsKDAoFBAACFQESA38cLAoMCgUEAAIVAxID
fy8xCg0KBQQAAhUIEgSAAQYxChAKCAQAAhUInAgAEgSAAQcwCk4KBAQAAhYSBIMBAkMaQCBP
dXRwdXQgb25seS4gSW5kaWNhdGVzIGlmIHRoZSBkb2N1bWVudCBoYXMgYSBsZWdhbCBob2xk
IG9uIGl0LgoKDQoFBAACFgUSBIMBAgYKDQoFBAACFgESBIMBBxEKDQoFBAACFgMSBIMBFBYK
DQoFBAACFggSBIMBF0IKEAoIBAACFgicCAASBIMBGEEKLAoCBAESBocBAK4BARoeIFJlZmVy
ZW5jZXMgdG8gdGhlIGRvY3VtZW50cy4KCgsKAwQBARIEhwEIGQo8CgQEAQIAEgaJAQKOAQQa
LCBSZXF1aXJlZC4gTmFtZSBvZiB0aGUgcmVmZXJlbmNlZCBkb2N1bWVudC4KCg0KBQQBAgAF
EgSJAQIICg0KBQQBAgABEgSJAQkWCg0KBQQBAgADEgSJARkaCg8KBQQBAgAIEgaJARuOAQMK
EAoIBAECAAicCAASBIoBBCoKEQoHBAECAAifCBIGiwEEjQEFCrABCgQEAQIBEgSTAQIaGqEB
IGRpc3BsYXlfbmFtZSBvZiB0aGUgcmVmZXJlbmNlZCBkb2N1bWVudDsgdGhpcyBuYW1lIGRv
ZXMgbm90IG5lZWQgdG8gYmUKIGNvbnNpc3RlbnQgdG8gdGhlIGRpc3BsYXlfbmFtZSBpbiB0
aGUgRG9jdW1lbnQgcHJvdG8sIGRlcGVuZGluZyBvbiB0aGUgQUNMCiBjb25zdHJhaW50LgoK
DQoFBAECAQUSBJMBAggKDQoFBAECAQESBJMBCRUKDQoFBAECAQMSBJMBGBkKmAEKBAQBAgIS
BJgBAhUaiQEgU3RvcmVzIHRoZSBzdWJzZXQgb2YgdGhlIHJlZmVyZW5jZWQgZG9jdW1lbnQn
cyBjb250ZW50LgogVGhpcyBpcyB1c2VmdWwgdG8gYWxsb3cgdXNlciBwZWVrIHRoZSBpbmZv
cm1hdGlvbiBvZiB0aGUgcmVmZXJlbmNlZAogZG9jdW1lbnQuCgoNCgUEAQICBRIEmAECCAoN
CgUEAQICARIEmAEJEAoNCgUEAQICAxIEmAETFApDCgQEAQIDEgSbAQIeGjUgVGhlIGRvY3Vt
ZW50IHR5cGUgb2YgdGhlIGRvY3VtZW50IGJlaW5nIHJlZmVyZW5jZWQuCgoNCgUEAQIDBRIE
mwECBgoNCgUEAQIDARIEmwEHGQoNCgUEAQIDAxIEmwEcHQpKCgQEAQIEEgaeAQKfATIaOiBP
dXRwdXQgb25seS4gVGhlIHRpbWUgd2hlbiB0aGUgZG9jdW1lbnQgaXMgbGFzdCB1cGRhdGVk
LgoKDQoFBAECBAYSBJ4BAhsKDQoFBAECBAESBJ4BHCcKDQoFBAECBAMSBJ4BKisKDQoFBAEC
BAgSBJ8BBjEKEAoIBAECBAicCAASBJ8BBzAKRQoEBAECBRIGogECowEyGjUgT3V0cHV0IG9u
bHkuIFRoZSB0aW1lIHdoZW4gdGhlIGRvY3VtZW50IGlzIGNyZWF0ZWQuCgoNCgUEAQIFBhIE
ogECGwoNCgUEAQIFARIEogEcJwoNCgUEAQIFAxIEogEqKwoNCgUEAQIFCBIEowEGMQoQCggE
AQIFCJwIABIEowEHMApFCgQEAQIGEgamAQKnATIaNSBPdXRwdXQgb25seS4gVGhlIHRpbWUg
d2hlbiB0aGUgZG9jdW1lbnQgaXMgZGVsZXRlZC4KCg0KBQQBAgYGEgSmAQIbCg0KBQQBAgYB
EgSmARwnCg0KBQQBAgYDEgSmASorCg0KBQQBAgYIEgSnAQYxChAKCAQBAgYInAgAEgSnAQcw
CjsKBAQBAgcSBKoBAigaLSBEb2N1bWVudCBpcyBhIGZvbGRlciB3aXRoIHJldGVudGlvbiBw
b2xpY3kuCgoNCgUEAQIHBRIEqgECBgoNCgUEAQIHARIEqgEHIwoNCgUEAQIHAxIEqgEmJwo1
CgQEAQIIEgStAQIpGicgRG9jdW1lbnQgaXMgYSBmb2xkZXIgd2l0aCBsZWdhbCBob2xkLgoK
DQoFBAECCAUSBK0BAgYKDQoFBAECCAESBK0BByQKDQoFBAECCAMSBK0BJygKJwoCBAISBrEB
ANYBARoZIFByb3BlcnR5IG9mIGEgZG9jdW1lbnQuCgoLCgMEAgESBLEBCBAKXQoEBAICABIE
tAECOxpPIFJlcXVpcmVkLiBNdXN0IG1hdGNoIHRoZSBuYW1lIG9mIGEgUHJvcGVydHlEZWZp
bml0aW9uIGluIHRoZQogRG9jdW1lbnRTY2hlbWEuCgoNCgUEAgIABRIEtAECCAoNCgUEAgIA
ARIEtAEJDQoNCgUEAgIAAxIEtAEQEQoNCgUEAgIACBIEtAESOgoQCggEAgIACJwIABIEtAET
OQr8AQoEBAIIABIGuwEC1QEDGusBIFR5cGUgb2YgdGhlIHByb3BlcnR5LgogTXVzdCBtYXRj
aCB0aGUgcHJvcGVydHlfb3B0aW9ucyB0eXBlIG9mIHRoZSBtYXRjaGluZyBQcm9wZXJ0eURl
ZmluaXRpb24uCiBWYWx1ZSBvZiB0aGUgUHJvcGVydHkgcGFyc2VkIGludG8gYSBzcGVjaWZp
YyBkYXRhIHR5cGUuCiBTcGVjaWZpYyB0eXBlIHZhbHVlKHMpIG9idGFpbmVkIGZyb20gRG9j
dW1lbnQgQUlzIFByb3BlcnR5Lm1lbnRpb25fdGV4dAogZmllbGQuCgoNCgUEAggAARIEuwEI
DgooCgQEAgIBEgS9AQQkGhogSW50ZWdlciBwcm9wZXJ0eSB2YWx1ZXMuCgoNCgUEAgIBBhIE
vQEEEAoNCgUEAgIBARIEvQERHwoNCgUEAgIBAxIEvQEiIwomCgQEAgICEgTAAQQgGhggRmxv
YXQgcHJvcGVydHkgdmFsdWVzLgoKDQoFBAICAgYSBMABBA4KDQoFBAICAgESBMABDxsKDQoF
BAICAgMSBMABHh8KLAoEBAICAxIEwwEEHhoeIFN0cmluZy90ZXh0IHByb3BlcnR5IHZhbHVl
cy4KCg0KBQQCAgMGEgTDAQQNCg0KBQQCAgMBEgTDAQ4ZCg0KBQQCAgMDEgTDARwdCiUKBAQC
AgQSBMYBBB4aFyBFbnVtIHByb3BlcnR5IHZhbHVlcy4KCg0KBQQCAgQGEgTGAQQNCg0KBQQC
AgQBEgTGAQ4ZCg0KBQQCAgQDEgTGARwdCjcKBAQCAgUSBMkBBCYaKSBOZXN0ZWQgc3RydWN0
dXJlZCBkYXRhIHByb3BlcnR5IHZhbHVlcy4KCg0KBQQCAgUGEgTJAQQRCg0KBQQCAgUBEgTJ
ARIhCg0KBQQCAgUDEgTJASQlCl0KBAQCAgYSBM0BBCcaTyBEYXRlIHRpbWUgcHJvcGVydHkg
dmFsdWVzLgogSXQgaXMgbm90IHN1cHBvcnRlZCBieSBDTUVLIGNvbXBsaWFudCBkZXBsb3lt
ZW50LgoKDQoFBAICBgYSBM0BBBEKDQoFBAICBgESBM0BEiIKDQoFBAICBgMSBM0BJSYKJAoE
BAICBxIE0AEEIRoWIE1hcCBwcm9wZXJ0eSB2YWx1ZXMuCgoNCgUEAgIHBhIE0AEEDwoNCgUE
AgIHARIE0AEQHAoNCgUEAgIHAxIE0AEfIApdCgQEAgIIEgTUAQQoGk8gVGltZXN0YW1wIHBy
b3BlcnR5IHZhbHVlcy4KIEl0IGlzIG5vdCBzdXBwb3J0ZWQgYnkgQ01FSyBjb21wbGlhbnQg
ZGVwbG95bWVudC4KCg0KBQQCAggGEgTUAQQSCg0KBQQCAggBEgTUARMjCg0KBQQCAggDEgTU
ASYnCh8KAgQDEgbZAQDcAQEaESBJbnRlZ2VyIHZhbHVlcy4KCgsKAwQDARIE2QEIFAonCgQE
AwIAEgTbAQIcGhkgTGlzdCBvZiBpbnRlZ2VyIHZhbHVlcy4KCg0KBQQDAgAEEgTbAQIKCg0K
BQQDAgAFEgTbAQsQCg0KBQQDAgABEgTbAREXCg0KBQQDAgADEgTbARobCh0KAgQEEgbfAQDi
AQEaDyBGbG9hdCB2YWx1ZXMuCgoLCgMEBAESBN8BCBIKJQoEBAQCABIE4QECHBoXIExpc3Qg
b2YgZmxvYXQgdmFsdWVzLgoKDQoFBAQCAAQSBOEBAgoKDQoFBAQCAAUSBOEBCxAKDQoFBAQC
AAESBOEBERcKDQoFBAQCAAMSBOEBGhsKIwoCBAUSBuUBAOgBARoVIFN0cmluZy90ZXh0IHZh
bHVlcy4KCgsKAwQFARIE5QEIEQokCgQEBQIAEgTnAQIdGhYgTGlzdCBvZiB0ZXh0IHZhbHVl
cy4KCg0KBQQFAgAEEgTnAQIKCg0KBQQFAgAFEgTnAQsRCg0KBQQFAgABEgTnARIYCg0KBQQF
AgADEgTnARscChwKAgQGEgbrAQDuAQEaDiBFbnVtIHZhbHVlcy4KCgsKAwQGARIE6wEIEQok
CgQEBgIAEgTtAQIdGhYgTGlzdCBvZiBlbnVtIHZhbHVlcy4KCg0KBQQGAgAEEgTtAQIKCg0K
BQQGAgAFEgTtAQsRCg0KBQQGAgABEgTtARIYCg0KBQQGAgADEgTtARscCiAKAgQHEgbxAQD1
AQEaEiBEYXRlVGltZSB2YWx1ZXMuCgoLCgMEBwESBPEBCBUKXgoEBAcCABIE9AECKxpQIExp
c3Qgb2YgZGF0ZXRpbWUgdmFsdWVzLgogQm90aCBPZmZzZXREYXRlVGltZSBhbmQgWm9uZWRE
YXRlVGltZSBhcmUgc3VwcG9ydGVkLgoKDQoFBAcCAAQSBPQBAgoKDQoFBAcCAAYSBPQBCx8K
DQoFBAcCAAESBPQBICYKDQoFBAcCAAMSBPQBKSoKIQoCBAgSBvgBAPsBARoTIFRpbWVzdGFt
cCB2YWx1ZXMuCgoLCgMECAESBPgBCBYKKQoEBAgCABIE+gECJRobIExpc3Qgb2YgdGltZXN0
YW1wIHZhbHVlcy4KCg0KBQQIAgAEEgT6AQIKCg0KBQQIAgAGEgT6AQsZCg0KBQQIAgABEgT6
ARogCg0KBQQIAgADEgT6ASMkCiUKAgQJEgb+AQCIAgEaFyBUaW1lc3RhbXAgdmFsdWUgdHlw
ZS4KCgsKAwQJARIE/gEIFgoOCgQECQgAEgb/AQKHAgMKDQoFBAkIAAESBP8BCA0KHwoEBAkC
ABIEgQIEMhoRIFRpbWVzdGFtcCB2YWx1ZQoKDQoFBAkCAAYSBIECBB0KDQoFBAkCAAESBIEC
Hi0KDQoFBAkCAAMSBIECMDEKowEKBAQJAgESBIYCBBoalAEgVGhlIHN0cmluZyBtdXN0IHJl
cHJlc2VudCBhIHZhbGlkIGluc3RhbnQgaW4gVVRDIGFuZCBpcyBwYXJzZWQgdXNpbmcKIGph
dmEudGltZS5mb3JtYXQuRGF0ZVRpbWVGb3JtYXR0ZXIuSVNPX0lOU1RBTlQuCiBlLmcuICIy
MDEzLTA5LTI5VDE4OjQ2OjE5WiIKCg0KBQQJAgEFEgSGAgQKCg0KBQQJAgEBEgSGAgsVCg0K
BQQJAgEDEgSGAhgZCiAKAgQKEgaLAgCOAgEaEiBQcm9wZXJ0eSB2YWx1ZXMuCgoLCgMECgES
BIsCCBUKKAoEBAoCABIEjQICIxoaIExpc3Qgb2YgcHJvcGVydHkgdmFsdWVzLgoKDQoFBAoC
AAQSBI0CAgoKDQoFBAoCAAYSBI0CCxMKDQoFBAoCAAESBI0CFB4KDQoFBAoCAAMSBI0CISIK
mwEKAgQLEgaTAgCWAgEajAEgTWFwIHByb3BlcnR5IHZhbHVlLgogUmVwcmVzZW50cyBhIHN0
cnVjdHVyZWQgZW50cmllcyBvZiBrZXkgdmFsdWUgcGFpcnMsIGNvbnNpc3Rpbmcgb2YgZmll
bGQgbmFtZXMKIHdoaWNoIG1hcCB0byBkeW5hbWljYWxseSB0eXBlZCB2YWx1ZXMuCgoLCgME
CwESBJMCCBMKOgoEBAsCABIElQICIBosIFVub3JkZXJlZCBtYXAgb2YgZHluYW1pY2FsbHkg
dHlwZWQgdmFsdWVzLgoKDQoFBAsCAAYSBJUCAhQKDQoFBAsCAAESBJUCFRsKDQoFBAsCAAMS
BJUCHh8K8wEKAgQMEgacAgC0AgEa5AEgYFZhbHVlYCByZXByZXNlbnRzIGEgZHluYW1pY2Fs
bHkgdHlwZWQgdmFsdWUgd2hpY2ggY2FuIGJlIGVpdGhlciBiZQogYSBmbG9hdCwgYSBpbnRl
Z2VyLCBhIHN0cmluZywgb3IgYSBkYXRldGltZSB2YWx1ZS4gQSBwcm9kdWNlciBvZiB2YWx1
ZSBpcwogZXhwZWN0ZWQgdG8gc2V0IG9uZSBvZiB0aGVzZSB2YXJpYW50cy4gQWJzZW5jZSBv
ZiBhbnkgdmFyaWFudCBpbmRpY2F0ZXMgYW4KIGVycm9yLgoKCwoDBAwBEgScAggNCiQKBAQM
CAASBp4CArMCAxoUIFRoZSBraW5kIG9mIHZhbHVlLgoKDQoFBAwIAAESBJ4CCAwKKQoEBAwC
ABIEoAIEGhobIFJlcHJlc2VudHMgYSBmbG9hdCB2YWx1ZS4KCg0KBQQMAgAFEgSgAgQJCg0K
BQQMAgABEgSgAgoVCg0KBQQMAgADEgSgAhgZCisKBAQMAgESBKMCBBgaHSBSZXByZXNlbnRz
IGEgaW50ZWdlciB2YWx1ZS4KCg0KBQQMAgEFEgSjAgQJCg0KBQQMAgEBEgSjAgoTCg0KBQQM
AgEDEgSjAhYXCioKBAQMAgISBKYCBBwaHCBSZXByZXNlbnRzIGEgc3RyaW5nIHZhbHVlLgoK
DQoFBAwCAgUSBKYCBAoKDQoFBAwCAgESBKYCCxcKDQoFBAwCAgMSBKYCGhsKKQoEBAwCAxIE
qQIEHRobIFJlcHJlc2VudHMgYW4gZW51bSB2YWx1ZS4KCg0KBQQMAgMGEgSpAgQNCg0KBQQM
AgMBEgSpAg4YCg0KBQQMAgMDEgSpAhscCiwKBAQMAgQSBKwCBCwaHiBSZXByZXNlbnRzIGEg
ZGF0ZXRpbWUgdmFsdWUuCgoNCgUEDAIEBhIErAIEGAoNCgUEDAIEARIErAIZJwoNCgUEDAIE
AxIErAIqKwotCgQEDAIFEgSvAgQnGh8gUmVwcmVzZW50cyBhIHRpbWVzdGFtcCB2YWx1ZS4K
Cg0KBQQMAgUGEgSvAgQSCg0KBQQMAgUBEgSvAhMiCg0KBQQMAgUDEgSvAiUmCisKBAQMAgYS
BLICBBsaHSBSZXByZXNlbnRzIGEgYm9vbGVhbiB2YWx1ZS4KCg0KBQQMAgYFEgSyAgQICg0K
BQQMAgYBEgSyAgkWCg0KBQQMAgYDEgSyAhkaCj4KAgQNEga3AgC7AgEaMCBSZXByZXNlbnRz
IHRoZSBzdHJpbmcgdmFsdWUgb2YgdGhlIGVudW0gZmllbGQuCgoLCgMEDQESBLcCCBEKfwoE
BA0CABIEugICExpxIFN0cmluZyB2YWx1ZSBvZiB0aGUgZW51bSBmaWVsZC4gVGhpcyBtdXN0
IG1hdGNoIGRlZmluZWQgc2V0IG9mIGVudW1zCiBpbiBkb2N1bWVudCBzY2hlbWEgdXNpbmcg
RW51bVR5cGVPcHRpb25zLgoKDQoFBA0CAAUSBLoCAggKDQoFBA0CAAESBLoCCQ4KDQoFBA0C
AAMSBLoCERIKTwoCBQASBr4CANMCARpBIFdoZW4gYSByYXcgZG9jdW1lbnQgaXMgc3VwcGxp
ZWQsIHRoaXMgaW5kaWNhdGVzIHRoZSBmaWxlIGZvcm1hdAoKCwoDBQABEgS+AgUYCj8KBAUA
AgASBMACAikaMSBObyByYXcgZG9jdW1lbnQgc3BlY2lmaWVkIG9yIGl0IGlzIG5vbi1wYXJz
YWJsZQoKDQoFBQACAAESBMACAiQKDQoFBQACAAISBMACJygKIAoEBQACARIEwwICIRoSIEFk
b2JlIFBERiBmb3JtYXQKCg0KBQUAAgEBEgTDAgIcCg0KBQUAAgECEgTDAh8gCiUKBAUAAgIS
BMYCAiIaFyBNaWNyb3NvZnQgV29yZCBmb3JtYXQKCg0KBQUAAgIBEgTGAgIdCg0KBQUAAgIC
EgTGAiAhCiYKBAUAAgMSBMkCAiIaGCBNaWNyb3NvZnQgRXhjZWwgZm9ybWF0CgoNCgUFAAID
ARIEyQICHQoNCgUFAAIDAhIEyQIgIQorCgQFAAIEEgTMAgIiGh0gTWljcm9zb2Z0IFBvd2Vy
cG9pbnQgZm9ybWF0CgoNCgUFAAIEARIEzAICHQoNCgUFAAIEAhIEzAIgIQopCgQFAAIFEgTP
AgIiGhsgVVRGLTggZW5jb2RlZCB0ZXh0IGZvcm1hdAoKDQoFBQACBQESBM8CAh0KDQoFBQAC
BQISBM8CICEKLQoEBQACBhIE0gICIhofIFRJRkYgb3IgVElGIGltYWdlIGZpbGUgZm9ybWF0
CgoNCgUFAAIGARIE0gICHQoNCgUFAAIGAhIE0gIgIQppCgIFARIG1wIA4wIBGlsgV2hlbiBh
IHJhdyBkb2N1bWVudCBvciBzdHJ1Y3R1cmVkIGNvbnRlbnQgaXMgc3VwcGxpZWQsIHRoaXMg
c3RvcmVzIHRoZQogY29udGVudCBjYXRlZ29yeS4KCgsKAwUBARIE1wIFFAopCgQFAQIAEgTZ
AgIjGhsgTm8gY2F0ZWdvcnkgaXMgc3BlY2lmaWVkLgoKDQoFBQECAAESBNkCAh4KDQoFBQEC
AAISBNkCISIKKQoEBQECARIE3AICHRobIENvbnRlbnQgaXMgb2YgaW1hZ2UgdHlwZS4KCg0K
BQUBAgEBEgTcAgIYCg0KBQUBAgECEgTcAhscCikKBAUBAgISBN8CAh0aGyBDb250ZW50IGlz
IG9mIGF1ZGlvIHR5cGUuCgoNCgUFAQICARIE3wICGAoNCgUFAQICAhIE3wIbHAopCgQFAQID
EgTiAgIdGhsgQ29udGVudCBpcyBvZiB2aWRlbyB0eXBlLgoKDQoFBQECAwESBOICAhgKDQoF
BQECAwISBOICGxxiBnByb3RvMw==
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Contentwarehouse::V1::Document::Document ===
    # Fields for Document
    # Field: name Type: 9 ()
    # Field: reference_id Type: 9 ()
    # Field: display_name Type: 9 ()
    # Field: title Type: 9 ()
    # Field: display_uri Type: 9 ()
    # Field: document_schema_name Type: 9 ()
    # Field: plain_text Type: 9 ()
    # Field: cloud_ai_document Type: 11 (.google.cloud.documentai.v1.Document)
    # Field: structured_content_uri Type: 9 ()
    # Field: raw_document_path Type: 9 ()
    # Field: inline_raw_document Type: 12 ()
    # Field: properties Type: 11 (.google.cloud.contentwarehouse.v1.Property)
    # Field: update_time Type: 11 (.google.protobuf.Timestamp)
    # Field: create_time Type: 11 (.google.protobuf.Timestamp)
    # Field: raw_document_file_type Type: 14 (.google.cloud.contentwarehouse.v1.RawDocumentFileType)
    # Field: async_enabled Type: 8 ()
    # Field: content_category Type: 14 (.google.cloud.contentwarehouse.v1.ContentCategory)
    # Field: text_extraction_disabled Type: 8 ()
    # Field: text_extraction_enabled Type: 8 ()
    # Field: creator Type: 9 ()
    # Field: updater Type: 9 ()
    # Field: disposition_time Type: 11 (.google.protobuf.Timestamp)
    # Field: legal_hold Type: 8 ()

# === Message: Google::Cloud::Contentwarehouse::V1::Document::DocumentReference ===
    # Fields for DocumentReference
    # Field: document_name Type: 9 ()
    # Field: display_name Type: 9 ()
    # Field: snippet Type: 9 ()
    # Field: document_is_folder Type: 8 ()
    # Field: update_time Type: 11 (.google.protobuf.Timestamp)
    # Field: create_time Type: 11 (.google.protobuf.Timestamp)
    # Field: delete_time Type: 11 (.google.protobuf.Timestamp)
    # Field: document_is_retention_folder Type: 8 ()
    # Field: document_is_legal_hold_folder Type: 8 ()

# === Message: Google::Cloud::Contentwarehouse::V1::Document::Property ===
    # Fields for Property
    # Field: name Type: 9 ()
    # Field: integer_values Type: 11 (.google.cloud.contentwarehouse.v1.IntegerArray)
    # Field: float_values Type: 11 (.google.cloud.contentwarehouse.v1.FloatArray)
    # Field: text_values Type: 11 (.google.cloud.contentwarehouse.v1.TextArray)
    # Field: enum_values Type: 11 (.google.cloud.contentwarehouse.v1.EnumArray)
    # Field: property_values Type: 11 (.google.cloud.contentwarehouse.v1.PropertyArray)
    # Field: date_time_values Type: 11 (.google.cloud.contentwarehouse.v1.DateTimeArray)
    # Field: map_property Type: 11 (.google.cloud.contentwarehouse.v1.MapProperty)
    # Field: timestamp_values Type: 11 (.google.cloud.contentwarehouse.v1.TimestampArray)

# === Message: Google::Cloud::Contentwarehouse::V1::Document::IntegerArray ===
    # Fields for IntegerArray
    # Field: values Type: 5 ()

# === Message: Google::Cloud::Contentwarehouse::V1::Document::FloatArray ===
    # Fields for FloatArray
    # Field: values Type: 2 ()

# === Message: Google::Cloud::Contentwarehouse::V1::Document::TextArray ===
    # Fields for TextArray
    # Field: values Type: 9 ()

# === Message: Google::Cloud::Contentwarehouse::V1::Document::EnumArray ===
    # Fields for EnumArray
    # Field: values Type: 9 ()

# === Message: Google::Cloud::Contentwarehouse::V1::Document::DateTimeArray ===
    # Fields for DateTimeArray
    # Field: values Type: 11 (.google.type.DateTime)

# === Message: Google::Cloud::Contentwarehouse::V1::Document::TimestampArray ===
    # Fields for TimestampArray
    # Field: values Type: 11 (.google.cloud.contentwarehouse.v1.TimestampValue)

# === Message: Google::Cloud::Contentwarehouse::V1::Document::TimestampValue ===
    # Fields for TimestampValue
    # Field: timestamp_value Type: 11 (.google.protobuf.Timestamp)
    # Field: text_value Type: 9 ()

# === Message: Google::Cloud::Contentwarehouse::V1::Document::PropertyArray ===
    # Fields for PropertyArray
    # Field: properties Type: 11 (.google.cloud.contentwarehouse.v1.Property)

# === Message: Google::Cloud::Contentwarehouse::V1::Document::MapProperty ===
    # Fields for MapProperty
    # Field: fields Type: 11 (.google.cloud.contentwarehouse.v1.MapProperty.FieldsEntry)

# === Message: Google::Cloud::Contentwarehouse::V1::Document::Value ===
    # Fields for Value
    # Field: float_value Type: 2 ()
    # Field: int_value Type: 5 ()
    # Field: string_value Type: 9 ()
    # Field: enum_value Type: 11 (.google.cloud.contentwarehouse.v1.EnumValue)
    # Field: datetime_value Type: 11 (.google.type.DateTime)
    # Field: timestamp_value Type: 11 (.google.cloud.contentwarehouse.v1.TimestampValue)
    # Field: boolean_value Type: 8 ()

# === Message: Google::Cloud::Contentwarehouse::V1::Document::EnumValue ===
    # Fields for EnumValue
    # Field: value Type: 9 ()

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Contentwarehouse::V1::Document - Compiled Protocol Buffers messages for google/cloud/contentwarehouse/v1/document.proto

=head1 SYNOPSIS

    use Google::Cloud::Contentwarehouse::V1::Document;

    my $msg = Google::Cloud::Contentwarehouse::V1::Document::Document->new({
        name => $name,
        reference_id => $reference_id,
        display_name => $display_name,
        title => $title,
    });

    # Read or update a field
    my $val = $msg->name();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Contentwarehouse::V1::Document::Document->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/contentwarehouse/v1/document.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Contentwarehouse::V1::Document::Document

Defines the structure for content warehouse document proto.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

The resource name of the document.
Format:
projects/{project_number}/locations/{location}/documents/{document_id}.

The name is ignored when creating a document.

=item * C<< $msg->reference_id() >> / C<< $msg->reference_id($value) >>

Type: C<String>

The reference ID set by customers. Must be unique per project and location.

=item * C<< $msg->display_name() >> / C<< $msg->display_name($value) >>

Type: C<String>

Required. Display name of the document given by the user. This name will be
displayed in the UI. Customer can populate this field with the name of the
document. This differs from the 'title' field as 'title' is optional and
stores the top heading in the document.

=item * C<< $msg->title() >> / C<< $msg->title($value) >>

Type: C<String>

Title that describes the document.
This can be the top heading or text that describes the document.

=item * C<< $msg->display_uri() >> / C<< $msg->display_uri($value) >>

Type: C<String>

Uri to display the document, for example, in the UI.

=item * C<< $msg->document_schema_name() >> / C<< $msg->document_schema_name($value) >>

Type: C<String>

The Document schema name.
Format:
projects/{project_number}/locations/{location}/documentSchemas/{document_schema_id}.

=item * C<< $msg->plain_text() >> / C<< $msg->plain_text($value) >>

Type: C<String>

Other document format, such as PPTX, XLXS

=item * C<< $msg->cloud_ai_document() >> / C<< $msg->cloud_ai_document($value) >>

Type: C<Message> (L<Google::Cloud::Documentai::V1::Document::Document>)

Document AI format to save the structured content, including OCR.

=item * C<< $msg->structured_content_uri() >> / C<< $msg->structured_content_uri($value) >>

Type: C<String>

A path linked to structured content file.

=item * C<< $msg->raw_document_path() >> / C<< $msg->raw_document_path($value) >>

Type: C<String>

Raw document file in Cloud Storage path.

=item * C<< $msg->inline_raw_document() >> / C<< $msg->inline_raw_document($value) >>

Type: C<Bytes>

Raw document content.

=item * C<< $msg->properties() >> / C<< $msg->properties($value) >>

Type: C<Message> (L<Google::Cloud::Contentwarehouse::V1::Document::Property>)

List of values that are user supplied metadata.

=item * C<< $msg->update_time() >> / C<< $msg->update_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Output only. The time when the document is last updated.

=item * C<< $msg->create_time() >> / C<< $msg->create_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Output only. The time when the document is created.

=item * C<< $msg->raw_document_file_type() >> / C<< $msg->raw_document_file_type($value) >>

Type: C<Enum> (L<Google::Cloud::Contentwarehouse::V1::RawDocumentFileType>)

This is used when DocAI was not used to load the document and parsing/
extracting is needed for the inline_raw_document.  For example, if
inline_raw_document is the byte representation of a PDF file, then
this should be set to: RAW_DOCUMENT_FILE_TYPE_PDF.

=item * C<< $msg->async_enabled() >> / C<< $msg->async_enabled($value) >>

Type: C<Bool>

If true, makes the document visible to asynchronous policies and rules.

=item * C<< $msg->content_category() >> / C<< $msg->content_category($value) >>

Type: C<Enum> (L<Google::Cloud::Contentwarehouse::V1::ContentCategory>)

Indicates the category (image, audio, video etc.) of the original content.

=item * C<< $msg->text_extraction_disabled() >> / C<< $msg->text_extraction_disabled($value) >>

Type: C<Bool>

If true, text extraction will not be performed.

=item * C<< $msg->text_extraction_enabled() >> / C<< $msg->text_extraction_enabled($value) >>

Type: C<Bool>

If true, text extraction will be performed.

=item * C<< $msg->creator() >> / C<< $msg->creator($value) >>

Type: C<String>

The user who creates the document.

=item * C<< $msg->updater() >> / C<< $msg->updater($value) >>

Type: C<String>

The user who lastly updates the document.

=item * C<< $msg->disposition_time() >> / C<< $msg->disposition_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Output only. If linked to a Collection with RetentionPolicy, the date when
the document becomes mutable.

=item * C<< $msg->legal_hold() >> / C<< $msg->legal_hold($value) >>

Type: C<Bool>

Output only. Indicates if the document has a legal hold on it.

=back

=head2 Google::Cloud::Contentwarehouse::V1::Document::DocumentReference

References to the documents.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->document_name() >> / C<< $msg->document_name($value) >>

Type: C<String>

Required. Name of the referenced document.

=item * C<< $msg->display_name() >> / C<< $msg->display_name($value) >>

Type: C<String>

display_name of the referenced document; this name does not need to be
consistent to the display_name in the Document proto, depending on the ACL
constraint.

=item * C<< $msg->snippet() >> / C<< $msg->snippet($value) >>

Type: C<String>

Stores the subset of the referenced document's content.
This is useful to allow user peek the information of the referenced
document.

=item * C<< $msg->document_is_folder() >> / C<< $msg->document_is_folder($value) >>

Type: C<Bool>

The document type of the document being referenced.

=item * C<< $msg->update_time() >> / C<< $msg->update_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Output only. The time when the document is last updated.

=item * C<< $msg->create_time() >> / C<< $msg->create_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Output only. The time when the document is created.

=item * C<< $msg->delete_time() >> / C<< $msg->delete_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Output only. The time when the document is deleted.

=item * C<< $msg->document_is_retention_folder() >> / C<< $msg->document_is_retention_folder($value) >>

Type: C<Bool>

Document is a folder with retention policy.

=item * C<< $msg->document_is_legal_hold_folder() >> / C<< $msg->document_is_legal_hold_folder($value) >>

Type: C<Bool>

Document is a folder with legal hold.

=back

=head2 Google::Cloud::Contentwarehouse::V1::Document::Property

Property of a document.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. Must match the name of a PropertyDefinition in the
DocumentSchema.

=item * C<< $msg->integer_values() >> / C<< $msg->integer_values($value) >>

Type: C<Message> (L<Google::Cloud::Contentwarehouse::V1::Document::IntegerArray>)

Integer property values.

=item * C<< $msg->float_values() >> / C<< $msg->float_values($value) >>

Type: C<Message> (L<Google::Cloud::Contentwarehouse::V1::Document::FloatArray>)

Float property values.

=item * C<< $msg->text_values() >> / C<< $msg->text_values($value) >>

Type: C<Message> (L<Google::Cloud::Contentwarehouse::V1::Document::TextArray>)

String/text property values.

=item * C<< $msg->enum_values() >> / C<< $msg->enum_values($value) >>

Type: C<Message> (L<Google::Cloud::Contentwarehouse::V1::Document::EnumArray>)

Enum property values.

=item * C<< $msg->property_values() >> / C<< $msg->property_values($value) >>

Type: C<Message> (L<Google::Cloud::Contentwarehouse::V1::Document::PropertyArray>)

Nested structured data property values.

=item * C<< $msg->date_time_values() >> / C<< $msg->date_time_values($value) >>

Type: C<Message> (L<Google::Cloud::Contentwarehouse::V1::Document::DateTimeArray>)

Date time property values.
It is not supported by CMEK compliant deployment.

=item * C<< $msg->map_property() >> / C<< $msg->map_property($value) >>

Type: C<Message> (L<Google::Cloud::Contentwarehouse::V1::Document::MapProperty>)

Map property values.

=item * C<< $msg->timestamp_values() >> / C<< $msg->timestamp_values($value) >>

Type: C<Message> (L<Google::Cloud::Contentwarehouse::V1::Document::TimestampArray>)

Timestamp property values.
It is not supported by CMEK compliant deployment.

=back

=head2 Google::Cloud::Contentwarehouse::V1::Document::IntegerArray

Integer values.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->values() >> / C<< $msg->values($value) >>

Type: C<Int32>

List of integer values.

=back

=head2 Google::Cloud::Contentwarehouse::V1::Document::FloatArray

Float values.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->values() >> / C<< $msg->values($value) >>

Type: C<Float>

List of float values.

=back

=head2 Google::Cloud::Contentwarehouse::V1::Document::TextArray

String/text values.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->values() >> / C<< $msg->values($value) >>

Type: C<String>

List of text values.

=back

=head2 Google::Cloud::Contentwarehouse::V1::Document::EnumArray

Enum values.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->values() >> / C<< $msg->values($value) >>

Type: C<String>

List of enum values.

=back

=head2 Google::Cloud::Contentwarehouse::V1::Document::DateTimeArray

DateTime values.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->values() >> / C<< $msg->values($value) >>

Type: C<Message> (L<Google::Type::Datetime::DateTime>)

List of datetime values.
Both OffsetDateTime and ZonedDateTime are supported.

=back

=head2 Google::Cloud::Contentwarehouse::V1::Document::TimestampArray

Timestamp values.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->values() >> / C<< $msg->values($value) >>

Type: C<Message> (L<Google::Cloud::Contentwarehouse::V1::Document::TimestampValue>)

List of timestamp values.

=back

=head2 Google::Cloud::Contentwarehouse::V1::Document::TimestampValue

Timestamp value type.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->timestamp_value() >> / C<< $msg->timestamp_value($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Timestamp value

=item * C<< $msg->text_value() >> / C<< $msg->text_value($value) >>

Type: C<String>

The string must represent a valid instant in UTC and is parsed using
java.time.format.DateTimeFormatter.ISO_INSTANT.
e.g. "2013-09-29T18:46:19Z"

=back

=head2 Google::Cloud::Contentwarehouse::V1::Document::PropertyArray

Property values.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->properties() >> / C<< $msg->properties($value) >>

Type: C<Message> (L<Google::Cloud::Contentwarehouse::V1::Document::Property>)

List of property values.

=back

=head2 Google::Cloud::Contentwarehouse::V1::Document::MapProperty

Map property value.
Represents a structured entries of key value pairs, consisting of field names
which map to dynamically typed values.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->fields() >> / C<< $msg->fields($value) >>

Type: C<Message> (L<Google::Cloud::Contentwarehouse::V1::Document::MapProperty::FieldsEntry>)

Unordered map of dynamically typed values.

=back

=head2 Google::Cloud::Contentwarehouse::V1::Document::Value

`Value` represents a dynamically typed value which can be either be
a float, a integer, a string, or a datetime value. A producer of value is
expected to set one of these variants. Absence of any variant indicates an
error.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->float_value() >> / C<< $msg->float_value($value) >>

Type: C<Float>

Represents a float value.

=item * C<< $msg->int_value() >> / C<< $msg->int_value($value) >>

Type: C<Int32>

Represents a integer value.

=item * C<< $msg->string_value() >> / C<< $msg->string_value($value) >>

Type: C<String>

Represents a string value.

=item * C<< $msg->enum_value() >> / C<< $msg->enum_value($value) >>

Type: C<Message> (L<Google::Cloud::Contentwarehouse::V1::Document::EnumValue>)

Represents an enum value.

=item * C<< $msg->datetime_value() >> / C<< $msg->datetime_value($value) >>

Type: C<Message> (L<Google::Type::Datetime::DateTime>)

Represents a datetime value.

=item * C<< $msg->timestamp_value() >> / C<< $msg->timestamp_value($value) >>

Type: C<Message> (L<Google::Cloud::Contentwarehouse::V1::Document::TimestampValue>)

Represents a timestamp value.

=item * C<< $msg->boolean_value() >> / C<< $msg->boolean_value($value) >>

Type: C<Bool>

Represents a boolean value.

=back

=head2 Google::Cloud::Contentwarehouse::V1::Document::EnumValue

Represents the string value of the enum field.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->value() >> / C<< $msg->value($value) >>

Type: C<String>

String value of the enum field. This must match defined set of enums
in document schema using EnumTypeOptions.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Contentwarehouse::V1::Document::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
