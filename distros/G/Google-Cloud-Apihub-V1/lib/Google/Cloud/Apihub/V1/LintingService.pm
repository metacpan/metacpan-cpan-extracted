package Google::Cloud::Apihub::V1::LintingService;

use strict;
use warnings;

our $VERSION = '0.14';

use Protobuf::Message;
use Protobuf::DescriptorPool;
use Protobuf::Internal qw(:all);
use MIME::Base64;

BEGIN {
    eval { require Google::Api::Annotations };
    eval { require Google::Api::Client };
    eval { require Google::Api::FieldBehavior };
    eval { require Google::Api::Resource };
    eval { require Google::Cloud::Apihub::V1::CommonFields };
    eval { require Google::Protobuf::Empty };
    eval { require Google::Protobuf::FieldMask };
    my $descriptor_b64 = <<'EOF';
Cixnb29nbGUvY2xvdWQvYXBpaHViL3YxL2xpbnRpbmdfc2VydmljZS5wcm90bxIWZ29vZ2xl
LmNsb3VkLmFwaWh1Yi52MRocZ29vZ2xlL2FwaS9hbm5vdGF0aW9ucy5wcm90bxoXZ29vZ2xl
L2FwaS9jbGllbnQucHJvdG8aH2dvb2dsZS9hcGkvZmllbGRfYmVoYXZpb3IucHJvdG8aGWdv
b2dsZS9hcGkvcmVzb3VyY2UucHJvdG8aKmdvb2dsZS9jbG91ZC9hcGlodWIvdjEvY29tbW9u
X2ZpZWxkcy5wcm90bxobZ29vZ2xlL3Byb3RvYnVmL2VtcHR5LnByb3RvGiBnb29nbGUvcHJv
dG9idWYvZmllbGRfbWFzay5wcm90byJUChRHZXRTdHlsZUd1aWRlUmVxdWVzdBI8CgRuYW1l
GAEgASgJQijgQQL6QSIKIGFwaWh1Yi5nb29nbGVhcGlzLmNvbS9TdHlsZUd1aWRlUgRuYW1l
IqUBChdVcGRhdGVTdHlsZUd1aWRlUmVxdWVzdBJICgtzdHlsZV9ndWlkZRgBIAEoCzIiLmdv
b2dsZS5jbG91ZC5hcGlodWIudjEuU3R5bGVHdWlkZUID4EECUgpzdHlsZUd1aWRlEkAKC3Vw
ZGF0ZV9tYXNrGAIgASgLMhouZ29vZ2xlLnByb3RvYnVmLkZpZWxkTWFza0ID4EEBUgp1cGRh
dGVNYXNrIlwKHEdldFN0eWxlR3VpZGVDb250ZW50c1JlcXVlc3QSPAoEbmFtZRgBIAEoCUIo
4EEC+kEiCiBhcGlodWIuZ29vZ2xlYXBpcy5jb20vU3R5bGVHdWlkZVIEbmFtZSJJCg9MaW50
U3BlY1JlcXVlc3QSNgoEbmFtZRgBIAEoCUIi4EEC+kEcChphcGlodWIuZ29vZ2xlYXBpcy5j
b20vU3BlY1IEbmFtZSJXChJTdHlsZUd1aWRlQ29udGVudHMSHwoIY29udGVudHMYASABKAxC
A+BBAlIIY29udGVudHMSIAoJbWltZV90eXBlGAIgASgJQgPgQQJSCG1pbWVUeXBlIrkCCgpT
dHlsZUd1aWRlEhcKBG5hbWUYASABKAlCA+BBCFIEbmFtZRI7CgZsaW50ZXIYAiABKA4yHi5n
b29nbGUuY2xvdWQuYXBpaHViLnYxLkxpbnRlckID4EECUgZsaW50ZXISTgoIY29udGVudHMY
AyABKAsyKi5nb29nbGUuY2xvdWQuYXBpaHViLnYxLlN0eWxlR3VpZGVDb250ZW50c0IG4EEC
4EEEUghjb250ZW50czqEAepBgAEKIGFwaWh1Yi5nb29nbGVhcGlzLmNvbS9TdHlsZUd1aWRl
EkNwcm9qZWN0cy97cHJvamVjdH0vbG9jYXRpb25zL3tsb2NhdGlvbn0vcGx1Z2lucy97cGx1
Z2lufS9zdHlsZUd1aWRlKgtzdHlsZUd1aWRlczIKc3R5bGVHdWlkZTLKBgoOTGludGluZ1Nl
cnZpY2USqAEKDUdldFN0eWxlR3VpZGUSLC5nb29nbGUuY2xvdWQuYXBpaHViLnYxLkdldFN0
eWxlR3VpZGVSZXF1ZXN0GiIuZ29vZ2xlLmNsb3VkLmFwaWh1Yi52MS5TdHlsZUd1aWRlIkWC
0+STAjgSNi92MS97bmFtZT1wcm9qZWN0cy8qL2xvY2F0aW9ucy8qL3BsdWdpbnMvKi9zdHls
ZUd1aWRlfdpBBG5hbWUS2gEKEFVwZGF0ZVN0eWxlR3VpZGUSLy5nb29nbGUuY2xvdWQuYXBp
aHViLnYxLlVwZGF0ZVN0eWxlR3VpZGVSZXF1ZXN0GiIuZ29vZ2xlLmNsb3VkLmFwaWh1Yi52
MS5TdHlsZUd1aWRlInGC0+STAlEyQi92MS97c3R5bGVfZ3VpZGUubmFtZT1wcm9qZWN0cy8q
L2xvY2F0aW9ucy8qL3BsdWdpbnMvKi9zdHlsZUd1aWRlfToLc3R5bGVfZ3VpZGXaQRdzdHls
ZV9ndWlkZSx1cGRhdGVfbWFzaxLJAQoVR2V0U3R5bGVHdWlkZUNvbnRlbnRzEjQuZ29vZ2xl
LmNsb3VkLmFwaWh1Yi52MS5HZXRTdHlsZUd1aWRlQ29udGVudHNSZXF1ZXN0GiouZ29vZ2xl
LmNsb3VkLmFwaWh1Yi52MS5TdHlsZUd1aWRlQ29udGVudHMiToLT5JMCQRI/L3YxL3tuYW1l
PXByb2plY3RzLyovbG9jYXRpb25zLyovcGx1Z2lucy8qL3N0eWxlR3VpZGV9OmNvbnRlbnRz
2kEEbmFtZRKYAQoITGludFNwZWMSJy5nb29nbGUuY2xvdWQuYXBpaHViLnYxLkxpbnRTcGVj
UmVxdWVzdBoWLmdvb2dsZS5wcm90b2J1Zi5FbXB0eSJLgtPkkwJFIkAvdjEve25hbWU9cHJv
amVjdHMvKi9sb2NhdGlvbnMvKi9hcGlzLyovdmVyc2lvbnMvKi9zcGVjcy8qfTpsaW50OgEq
GknKQRVhcGlodWIuZ29vZ2xlYXBpcy5jb23SQS5odHRwczovL3d3dy5nb29nbGVhcGlzLmNv
bS9hdXRoL2Nsb3VkLXBsYXRmb3JtQrUBChpjb20uZ29vZ2xlLmNsb3VkLmFwaWh1Yi52MUIT
TGludGluZ1NlcnZpY2VQcm90b1ABWjJjbG91ZC5nb29nbGUuY29tL2dvL2FwaWh1Yi9hcGl2
MS9hcGlodWJwYjthcGlodWJwYqoCFkdvb2dsZS5DbG91ZC5BcGlIdWIuVjHKAhZHb29nbGVc
Q2xvdWRcQXBpSHViXFYx6gIZR29vZ2xlOjpDbG91ZDo6QXBpSHViOjpWMUqGIgoHEgUOAKQB
AQq8BAoBDBIDDgASMrEEIENvcHlyaWdodCAyMDI1IEdvb2dsZSBMTEMKCiBMaWNlbnNlZCB1
bmRlciB0aGUgQXBhY2hlIExpY2Vuc2UsIFZlcnNpb24gMi4wICh0aGUgIkxpY2Vuc2UiKTsK
IHlvdSBtYXkgbm90IHVzZSB0aGlzIGZpbGUgZXhjZXB0IGluIGNvbXBsaWFuY2Ugd2l0aCB0
aGUgTGljZW5zZS4KIFlvdSBtYXkgb2J0YWluIGEgY29weSBvZiB0aGUgTGljZW5zZSBhdAoK
ICAgICBodHRwOi8vd3d3LmFwYWNoZS5vcmcvbGljZW5zZXMvTElDRU5TRS0yLjAKCiBVbmxl
c3MgcmVxdWlyZWQgYnkgYXBwbGljYWJsZSBsYXcgb3IgYWdyZWVkIHRvIGluIHdyaXRpbmcs
IHNvZnR3YXJlCiBkaXN0cmlidXRlZCB1bmRlciB0aGUgTGljZW5zZSBpcyBkaXN0cmlidXRl
ZCBvbiBhbiAiQVMgSVMiIEJBU0lTLAogV0lUSE9VVCBXQVJSQU5USUVTIE9SIENPTkRJVElP
TlMgT0YgQU5ZIEtJTkQsIGVpdGhlciBleHByZXNzIG9yIGltcGxpZWQuCiBTZWUgdGhlIExp
Y2Vuc2UgZm9yIHRoZSBzcGVjaWZpYyBsYW5ndWFnZSBnb3Zlcm5pbmcgcGVybWlzc2lvbnMg
YW5kCiBsaW1pdGF0aW9ucyB1bmRlciB0aGUgTGljZW5zZS4KCggKAQISAxAAHwoJCgIDABID
EgAmCgkKAgMBEgMTACEKCQoCAwISAxQAKQoJCgIDAxIDFQAjCgkKAgMEEgMWADQKCQoCAwUS
AxcAJQoJCgIDBhIDGAAqCggKAQgSAxoAMwoJCgIIJRIDGgAzCggKAQgSAxsASQoJCgIICxID
GwBJCggKAQgSAxwAIgoJCgIIChIDHAAiCggKAQgSAx0ANAoJCgIICBIDHQA0CggKAQgSAx4A
MwoJCgIIARIDHgAzCggKAQgSAx8AMwoJCgIIKRIDHwAzCggKAQgSAyAAMgoJCgIILRIDIAAy
CkkKAgYAEgQjAEsBGj0gVGhpcyBzZXJ2aWNlIHByb3ZpZGVzIGFsbCBtZXRob2RzIHJlbGF0
ZWQgdG8gdGhlIDFwIExpbnRlci4KCgoKAwYAARIDIwgWCgoKAwYAAxIDJAI9CgwKBQYAA5kI
EgMkAj0KCwoDBgADEgQlAiY3Cg0KBQYAA5oIEgQlAiY3CjsKBAYAAgASBCkCLgMaLSBHZXQg
dGhlIHN0eWxlIGd1aWRlIGJlaW5nIHVzZWQgZm9yIGxpbnRpbmcuCgoMCgUGAAIAARIDKQYT
CgwKBQYAAgACEgMpFCgKDAoFBgACAAMSAykzPQoNCgUGAAIABBIEKgQsBgoRCgkGAAIABLDK
vCISBCoELAYKDAoFBgACAAQSAy0EMgoPCggGAAIABJsIABIDLQQyCkwKBAYAAgESBDECNwMa
PiBVcGRhdGUgdGhlIHN0eWxlR3VpZGUgdG8gYmUgdXNlZCBmb3IgbGluaXRpbmcgaW4gYnkg
QVBJIGh1Yi4KCgwKBQYAAgEBEgMxBhYKDAoFBgACAQISAzEXLgoMCgUGAAIBAxIDMTlDCg0K
BQYAAgEEEgQyBDUGChEKCQYAAgEEsMq8IhIEMgQ1BgoMCgUGAAIBBBIDNgRFCg8KCAYAAgEE
mwgAEgM2BEUKNAoEBgACAhIEOgJAAxomIEdldCB0aGUgY29udGVudHMgb2YgdGhlIHN0eWxl
IGd1aWRlLgoKDAoFBgACAgESAzoGGwoMCgUGAAICAhIDOhw4CgwKBQYAAgIDEgM7DyEKDQoF
BgACAgQSBDwEPgYKEQoJBgACAgSwyrwiEgQ8BD4GCgwKBQYAAgIEEgM/BDIKDwoIBgACAgSb
CAASAz8EMgrKAQoEBgACAxIERQJKAxq7ASBMaW50cyB0aGUgcmVxdWVzdGVkIHNwZWMgYW5k
IHVwZGF0ZXMgdGhlIGNvcnJlc3BvbmRpbmcgQVBJIFNwZWMgd2l0aCB0aGUKIGxpbnQgcmVz
cG9uc2UuIFRoaXMgbGludCByZXNwb25zZSB3aWxsIGJlIGF2YWlsYWJsZSBpbiBhbGwgc3Vi
c2VxdWVudAogR2V0IGFuZCBMaXN0IFNwZWMgY2FsbHMgdG8gQ29yZSBzZXJ2aWNlLgoKDAoF
BgACAwESA0UGDgoMCgUGAAIDAhIDRQ8eCgwKBQYAAgMDEgNFKT4KDQoFBgACAwQSBEYESQYK
EQoJBgACAwSwyrwiEgRGBEkGCmkKAgQAEgRPAFkBGl0gVGhlIFtHZXRTdHlsZUd1aWRlXVtn
b29nbGUuY2xvdWQuYXBpaHViLnYxLkxpbnRpbmdTZXJ2aWNlLkdldFN0eWxlR3VpZGVdCiBt
ZXRob2QncyByZXF1ZXN0LgoKCgoDBAABEgNPCBwKjAEKBAQAAgASBFMCWAQafiBSZXF1aXJl
ZC4gVGhlIG5hbWUgb2YgdGhlIHNwZWMgdG8gcmV0cmlldmUuCiBGb3JtYXQ6CiBgcHJvamVj
dHMve3Byb2plY3R9L2xvY2F0aW9ucy97bG9jYXRpb259L3BsdWdpbnMve3BsdWdpbn0vc3R5
bGVHdWlkZWAuCgoMCgUEAAIABRIDUwIICgwKBQQAAgABEgNTCQ0KDAoFBAACAAMSA1MQEQoN
CgUEAAIACBIEUxJYAwoPCggEAAIACJwIABIDVAQqCg8KBwQAAgAInwgSBFUEVwUKcAoCBAES
BF4AZQEaZCBUaGUKIFtVcGRhdGVTdHlsZUd1aWRlXVtnb29nbGUuY2xvdWQuYXBpaHViLnYx
LkxpbnRpbmdTZXJ2aWNlLlVwZGF0ZVN0eWxlR3VpZGVdCiBtZXRob2QncyByZXF1ZXN0LgoK
CgoDBAEBEgNeCB8KPAoEBAECABIDYAJGGi8gUmVxdWlyZWQuIFRoZSBTdHlsZSBndWlkZSBy
ZXNvdXJjZSB0byB1cGRhdGUuCgoMCgUEAQIABhIDYAIMCgwKBQQBAgABEgNgDRgKDAoFBAEC
AAMSA2AbHAoMCgUEAQIACBIDYB1FCg8KCAQBAgAInAgAEgNgHkQKNwoEBAECARIEYwJkLxop
IE9wdGlvbmFsLiBUaGUgbGlzdCBvZiBmaWVsZHMgdG8gdXBkYXRlLgoKDAoFBAECAQYSA2MC
GwoMCgUEAQIBARIDYxwnCgwKBQQBAgEDEgNjKisKDAoFBAECAQgSA2QGLgoPCggEAQIBCJwI
ABIDZActCnoKAgQCEgRqAHUBGm4gVGhlCiBbR2V0U3R5bGVHdWlkZUNvbnRlbnRzXVtnb29n
bGUuY2xvdWQuYXBpaHViLnYxLkxpbnRpbmdTZXJ2aWNlLkdldFN0eWxlR3VpZGVDb250ZW50
c10KIG1ldGhvZCdzIHJlcXVlc3QuCgoKCgMEAgESA2oIJAr/AQoEBAICABIEbwJ0BBrwASBS
ZXF1aXJlZC4gVGhlIG5hbWUgb2YgdGhlIFN0eWxlR3VpZGUgd2hvc2UgY29udGVudHMgbmVl
ZCB0byBiZSByZXRyaWV2ZWQuCiBUaGVyZSBpcyBleGFjdGx5IG9uZSBzdHlsZSBndWlkZSBy
ZXNvdXJjZSBwZXIgcHJvamVjdCBwZXIgbG9jYXRpb24uCiBUaGUgZXhwZWN0ZWQgZm9ybWF0
IGlzCiBgcHJvamVjdHMve3Byb2plY3R9L2xvY2F0aW9ucy97bG9jYXRpb259L3BsdWdpbnMv
e3BsdWdpbn0vc3R5bGVHdWlkZWAuCgoMCgUEAgIABRIDbwIICgwKBQQCAgABEgNvCQ0KDAoF
BAICAAMSA28QEQoNCgUEAgIACBIEbxJ0AwoPCggEAgIACJwIABIDcAQqCg8KBwQCAgAInwgS
BHEEcwUKYAoCBAMSBXkAgQEBGlMgVGhlIFtMaW50U3BlY11bZ29vZ2xlLmNsb3VkLmFwaWh1
Yi52MS5MaW50aW5nU2VydmljZS5MaW50U3BlY10gbWV0aG9kJ3MKIHJlcXVlc3QuCgoKCgME
AwESA3kIFwqdAQoEBAMCABIFfQKAAQQajQEgUmVxdWlyZWQuIFRoZSBuYW1lIG9mIHRoZSBz
cGVjIHRvIGJlIGxpbnRlZC4KIEZvcm1hdDoKIGBwcm9qZWN0cy97cHJvamVjdH0vbG9jYXRp
b25zL3tsb2NhdGlvbn0vYXBpcy97YXBpfS92ZXJzaW9ucy97dmVyc2lvbn0vc3BlY3Mve3Nw
ZWN9YAoKDAoFBAMCAAUSA30CCAoMCgUEAwIAARIDfQkNCgwKBQQDAgADEgN9EBEKDgoFBAMC
AAgSBX0SgAEDCg8KCAQDAgAInAgAEgN+BCoKDgoHBAMCAAifCBIDfwRMCikKAgQEEgaEAQCK
AQEaGyBUaGUgc3R5bGUgZ3VpZGUgY29udGVudHMuCgoLCgMEBAESBIQBCBoKOgoEBAQCABIE
hgECPhosIFJlcXVpcmVkLiBUaGUgY29udGVudHMgb2YgdGhlIHN0eWxlIGd1aWRlLgoKDQoF
BAQCAAUSBIYBAgcKDQoFBAQCAAESBIYBCBAKDQoFBAQCAAMSBIYBExQKDQoFBAQCAAgSBIYB
FT0KEAoIBAQCAAicCAASBIYBFjwKNwoEBAQCARIEiQECQBopIFJlcXVpcmVkLiBUaGUgbWlt
ZSB0eXBlIG9mIHRoZSBjb250ZW50LgoKDQoFBAQCAQUSBIkBAggKDQoFBAQCAQESBIkBCRIK
DQoFBAQCAQMSBIkBFRYKDQoFBAQCAQgSBIkBFz8KEAoIBAQCAQicCAASBIkBGD4KYwoCBAUS
Bo4BAKQBARpVIFJlcHJlc2VudHMgYSBzaW5nbGV0b24gc3R5bGUgZ3VpZGUgcmVzb3VyY2Ug
dG8gYmUgdXNlZCBmb3IgbGludGluZyBPcGVuIEFQSQogc3BlY3MuCgoLCgMEBQESBI4BCBIK
DQoDBAUHEgaPAQKUAQQKDwoFBAUHnQgSBo8BApQBBAqJAQoEBAUCABIEmgECPRp7IElkZW50
aWZpZXIuIFRoZSBuYW1lIG9mIHRoZSBzdHlsZSBndWlkZS4KCiBGb3JtYXQ6CiBgcHJvamVj
dHMve3Byb2plY3R9L2xvY2F0aW9ucy97bG9jYXRpb259L3BsdWdpbnMve3BsdWdpbn0vc3R5
bGVHdWlkZWAKCg0KBQQFAgAFEgSaAQIICg0KBQQFAgABEgSaAQkNCg0KBQQFAgADEgSaARAR
Cg0KBQQFAgAIEgSaARI8ChAKCAQFAgAInAgAEgSaARM7CjwKBAQFAgESBJ0BAj0aLiBSZXF1
aXJlZC4gVGFyZ2V0IGxpbnRlciBmb3IgdGhlIHN0eWxlIGd1aWRlLgoKDQoFBAUCAQYSBJ0B
AggKDQoFBAUCAQESBJ0BCQ8KDQoFBAUCAQMSBJ0BEhMKDQoFBAUCAQgSBJ0BFDwKEAoIBAUC
AQicCAASBJ0BFTsKUQoEBAUCAhIGoAECowEEGkEgUmVxdWlyZWQuIElucHV0IG9ubHkuIFRo
ZSBjb250ZW50cyBvZiB0aGUgdXBsb2FkZWQgc3R5bGUgZ3VpZGUuCgoNCgUEBQICBhIEoAEC
FAoNCgUEBQICARIEoAEVHQoNCgUEBQICAxIEoAEgIQoPCgUEBQICCBIGoAEiowEDChAKCAQF
AgIInAgAEgShAQQqChAKCAQFAgIInAgBEgSiAQQsYgZwcm90bzM=
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Apihub::V1::LintingService::GetStyleGuideRequest ===
    # Fields for GetStyleGuideRequest
    # Field: name Type: 9 ()

# === Message: Google::Cloud::Apihub::V1::LintingService::UpdateStyleGuideRequest ===
    # Fields for UpdateStyleGuideRequest
    # Field: style_guide Type: 11 (.google.cloud.apihub.v1.StyleGuide)
    # Field: update_mask Type: 11 (.google.protobuf.FieldMask)

# === Message: Google::Cloud::Apihub::V1::LintingService::GetStyleGuideContentsRequest ===
    # Fields for GetStyleGuideContentsRequest
    # Field: name Type: 9 ()

# === Message: Google::Cloud::Apihub::V1::LintingService::LintSpecRequest ===
    # Fields for LintSpecRequest
    # Field: name Type: 9 ()

# === Message: Google::Cloud::Apihub::V1::LintingService::StyleGuideContents ===
    # Fields for StyleGuideContents
    # Field: contents Type: 12 ()
    # Field: mime_type Type: 9 ()

# === Message: Google::Cloud::Apihub::V1::LintingService::StyleGuide ===
    # Fields for StyleGuide
    # Field: name Type: 9 ()
    # Field: linter Type: 14 (.google.cloud.apihub.v1.Linter)
    # Field: contents Type: 11 (.google.cloud.apihub.v1.StyleGuideContents)

# === Service Client: Google::Cloud::Apihub::V1::LintingService::LintingServiceClient ===
package Google::Cloud::Apihub::V1::LintingService::LintingServiceClient;

=pod

=head2 Service Client: Google::Cloud::Apihub::V1::LintingService::LintingServiceClient

Client stub representing the remote C<LintingService> gRPC service. Delegates call dispatching to L<Google::gRPC::Client>.

=head3 target

The endpoint target address. Defaults to C<apihub.googleapis.com:443>.

=head3 credentials

The authentication credentials provider. Defaults to application default credentials via L<Google::Auth>.

=cut

use Moo;
use Google::Auth;
use Google::gRPC::Client;

has credentials => ( is => 'ro', default => sub { Google::Auth->default() } );
has target      => ( is => 'ro', default => 'apihub.googleapis.com:443' );

has _grpc_client => (
    is => 'ro',
    lazy => 1,
    builder => sub {
        my $self = shift;
        return Google::gRPC::Client->new(
            target     => $self->target,
            auth_token => $self->credentials->get_token(),
        );
    }
);

sub get_style_guide {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Apihub::V1::LintingService::GetStyleGuideRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.apihub.v1.LintingService',
        method         => 'GetStyleGuide',
        request        => $req,
        response_class => 'Google::Cloud::Apihub::V1::LintingService::StyleGuide',
    });
}

sub update_style_guide {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Apihub::V1::LintingService::UpdateStyleGuideRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.apihub.v1.LintingService',
        method         => 'UpdateStyleGuide',
        request        => $req,
        response_class => 'Google::Cloud::Apihub::V1::LintingService::StyleGuide',
    });
}

sub get_style_guide_contents {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Apihub::V1::LintingService::GetStyleGuideContentsRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.apihub.v1.LintingService',
        method         => 'GetStyleGuideContents',
        request        => $req,
        response_class => 'Google::Cloud::Apihub::V1::LintingService::StyleGuideContents',
    });
}

sub lint_spec {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Apihub::V1::LintingService::LintSpecRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.apihub.v1.LintingService',
        method         => 'LintSpec',
        request        => $req,
        response_class => 'Google::Protobuf::Empty::Empty',
    });
}

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Apihub::V1::LintingService - Compiled Protocol Buffers messages for google/cloud/apihub/v1/linting_service.proto

=head1 SYNOPSIS

    use Google::Cloud::Apihub::V1::LintingService;

    my $msg = Google::Cloud::Apihub::V1::LintingService::GetStyleGuideRequest->new({
        name => $name,
    });

    # Read or update a field
    my $val = $msg->name();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Apihub::V1::LintingService::GetStyleGuideRequest->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/apihub/v1/linting_service.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Apihub::V1::LintingService::GetStyleGuideRequest

The [GetStyleGuide][google.cloud.apihub.v1.LintingService.GetStyleGuide]
method's request.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. The name of the spec to retrieve.
Format:
`projects/{project}/locations/{location}/plugins/{plugin}/styleGuide`.

=back

=head2 Google::Cloud::Apihub::V1::LintingService::UpdateStyleGuideRequest

The
[UpdateStyleGuide][google.cloud.apihub.v1.LintingService.UpdateStyleGuide]
method's request.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->style_guide() >> / C<< $msg->style_guide($value) >>

Type: C<Message> (L<Google::Cloud::Apihub::V1::LintingService::StyleGuide>)

Required. The Style guide resource to update.

=item * C<< $msg->update_mask() >> / C<< $msg->update_mask($value) >>

Type: C<Message> (L<Google::Protobuf::FieldMask::FieldMask>)

Optional. The list of fields to update.

=back

=head2 Google::Cloud::Apihub::V1::LintingService::GetStyleGuideContentsRequest

The
[GetStyleGuideContents][google.cloud.apihub.v1.LintingService.GetStyleGuideContents]
method's request.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. The name of the StyleGuide whose contents need to be retrieved.
There is exactly one style guide resource per project per location.
The expected format is
`projects/{project}/locations/{location}/plugins/{plugin}/styleGuide`.

=back

=head2 Google::Cloud::Apihub::V1::LintingService::LintSpecRequest

The [LintSpec][google.cloud.apihub.v1.LintingService.LintSpec] method's
request.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. The name of the spec to be linted.
Format:
`projects/{project}/locations/{location}/apis/{api}/versions/{version}/specs/{spec}`

=back

=head2 Google::Cloud::Apihub::V1::LintingService::StyleGuideContents

The style guide contents.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->contents() >> / C<< $msg->contents($value) >>

Type: C<Bytes>

Required. The contents of the style guide.

=item * C<< $msg->mime_type() >> / C<< $msg->mime_type($value) >>

Type: C<String>

Required. The mime type of the content.

=back

=head2 Google::Cloud::Apihub::V1::LintingService::StyleGuide

Represents a singleton style guide resource to be used for linting Open API
specs.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Identifier. The name of the style guide.

Format:
`projects/{project}/locations/{location}/plugins/{plugin}/styleGuide`

=item * C<< $msg->linter() >> / C<< $msg->linter($value) >>

Type: C<Enum> (L<Google::Cloud::Apihub::V1::Linter>)

Required. Target linter for the style guide.

=item * C<< $msg->contents() >> / C<< $msg->contents($value) >>

Type: C<Message> (L<Google::Cloud::Apihub::V1::LintingService::StyleGuideContents>)

Required. Input only. The contents of the uploaded style guide.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Apihub::V1::LintingService::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
