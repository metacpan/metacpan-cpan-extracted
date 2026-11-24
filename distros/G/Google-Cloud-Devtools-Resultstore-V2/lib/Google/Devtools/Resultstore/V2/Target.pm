package Google::Devtools::Resultstore::V2::Target;

use strict;
use warnings;

our $VERSION = '0.14';

use Protobuf::Message;
use Protobuf::DescriptorPool;
use Protobuf::Internal qw(:all);
use MIME::Base64;

BEGIN {
    eval { require Google::Api::Resource };
    eval { require Google::Devtools::Resultstore::V2::Common };
    eval { require Google::Devtools::Resultstore::V2::File };
    my $descriptor_b64 = <<'EOF';
Citnb29nbGUvZGV2dG9vbHMvcmVzdWx0c3RvcmUvdjIvdGFyZ2V0LnByb3RvEh5nb29nbGUu
ZGV2dG9vbHMucmVzdWx0c3RvcmUudjIaGWdvb2dsZS9hcGkvcmVzb3VyY2UucHJvdG8aK2dv
b2dsZS9kZXZ0b29scy9yZXN1bHRzdG9yZS92Mi9jb21tb24ucHJvdG8aKWdvb2dsZS9kZXZ0
b29scy9yZXN1bHRzdG9yZS92Mi9maWxlLnByb3RvIu0FCgZUYXJnZXQSEgoEbmFtZRgBIAEo
CVIEbmFtZRI5CgJpZBgCIAEoCzIpLmdvb2dsZS5kZXZ0b29scy5yZXN1bHRzdG9yZS52Mi5U
YXJnZXQuSWRSAmlkEmEKEXN0YXR1c19hdHRyaWJ1dGVzGAMgASgLMjAuZ29vZ2xlLmRldnRv
b2xzLnJlc3VsdHN0b3JlLnYyLlN0YXR1c0F0dHJpYnV0ZXNCAhgBUhBzdGF0dXNBdHRyaWJ1
dGVzEj4KBnRpbWluZxgEIAEoCzImLmdvb2dsZS5kZXZ0b29scy5yZXN1bHRzdG9yZS52Mi5U
aW1pbmdSBnRpbWluZxJdChF0YXJnZXRfYXR0cmlidXRlcxgFIAEoCzIwLmdvb2dsZS5kZXZ0
b29scy5yZXN1bHRzdG9yZS52Mi5UYXJnZXRBdHRyaWJ1dGVzUhB0YXJnZXRBdHRyaWJ1dGVz
ElcKD3Rlc3RfYXR0cmlidXRlcxgGIAEoCzIuLmdvb2dsZS5kZXZ0b29scy5yZXN1bHRzdG9y
ZS52Mi5UZXN0QXR0cmlidXRlc1IOdGVzdEF0dHJpYnV0ZXMSSAoKcHJvcGVydGllcxgHIAMo
CzIoLmdvb2dsZS5kZXZ0b29scy5yZXN1bHRzdG9yZS52Mi5Qcm9wZXJ0eVIKcHJvcGVydGll
cxI6CgVmaWxlcxgIIAMoCzIkLmdvb2dsZS5kZXZ0b29scy5yZXN1bHRzdG9yZS52Mi5GaWxl
UgVmaWxlcxIYCgd2aXNpYmxlGAogASgIUgd2aXNpYmxlGkYKAklkEiMKDWludm9jYXRpb25f
aWQYASABKAlSDGludm9jYXRpb25JZBIbCgl0YXJnZXRfaWQYAiABKAlSCHRhcmdldElkOlHq
QU4KIXJlc3VsdHN0b3JlLmdvb2dsZWFwaXMuY29tL1RhcmdldBIpaW52b2NhdGlvbnMve2lu
dm9jYXRpb259L3RhcmdldHMve3RhcmdldH0irAEKEFRhcmdldEF0dHJpYnV0ZXMSPgoEdHlw
ZRgBIAEoDjIqLmdvb2dsZS5kZXZ0b29scy5yZXN1bHRzdG9yZS52Mi5UYXJnZXRUeXBlUgR0
eXBlEkQKCGxhbmd1YWdlGAIgASgOMiguZ29vZ2xlLmRldnRvb2xzLnJlc3VsdHN0b3JlLnYy
Lkxhbmd1YWdlUghsYW5ndWFnZRISCgR0YWdzGAMgAygJUgR0YWdzIk4KDlRlc3RBdHRyaWJ1
dGVzEjwKBHNpemUYASABKA4yKC5nb29nbGUuZGV2dG9vbHMucmVzdWx0c3RvcmUudjIuVGVz
dFNpemVSBHNpemUqagoKVGFyZ2V0VHlwZRIbChdUQVJHRVRfVFlQRV9VTlNQRUNJRklFRBAA
Eg8KC0FQUExJQ0FUSU9OEAESCgoGQklOQVJZEAISCwoHTElCUkFSWRADEgsKB1BBQ0tBR0UQ
BBIICgRURVNUEAUqZQoIVGVzdFNpemUSGQoVVEVTVF9TSVpFX1VOU1BFQ0lGSUVEEAASCQoF
U01BTEwQARIKCgZNRURJVU0QAhIJCgVMQVJHRRADEgwKCEVOT1JNT1VTEAQSDgoKT1RIRVJf
U0laRRAFQn4KImNvbS5nb29nbGUuZGV2dG9vbHMucmVzdWx0c3RvcmUudjJCC1RhcmdldFBy
b3RvUAFaSWdvb2dsZS5nb2xhbmcub3JnL2dlbnByb3RvL2dvb2dsZWFwaXMvZGV2dG9vbHMv
cmVzdWx0c3RvcmUvdjI7cmVzdWx0c3RvcmVKviYKBxIFDgCRAQEKvAQKAQwSAw4AEjKxBCBD
b3B5cmlnaHQgMjAyNSBHb29nbGUgTExDCgogTGljZW5zZWQgdW5kZXIgdGhlIEFwYWNoZSBM
aWNlbnNlLCBWZXJzaW9uIDIuMCAodGhlICJMaWNlbnNlIik7CiB5b3UgbWF5IG5vdCB1c2Ug
dGhpcyBmaWxlIGV4Y2VwdCBpbiBjb21wbGlhbmNlIHdpdGggdGhlIExpY2Vuc2UuCiBZb3Ug
bWF5IG9idGFpbiBhIGNvcHkgb2YgdGhlIExpY2Vuc2UgYXQKCiAgICAgaHR0cDovL3d3dy5h
cGFjaGUub3JnL2xpY2Vuc2VzL0xJQ0VOU0UtMi4wCgogVW5sZXNzIHJlcXVpcmVkIGJ5IGFw
cGxpY2FibGUgbGF3IG9yIGFncmVlZCB0byBpbiB3cml0aW5nLCBzb2Z0d2FyZQogZGlzdHJp
YnV0ZWQgdW5kZXIgdGhlIExpY2Vuc2UgaXMgZGlzdHJpYnV0ZWQgb24gYW4gIkFTIElTIiBC
QVNJUywKIFdJVEhPVVQgV0FSUkFOVElFUyBPUiBDT05ESVRJT05TIE9GIEFOWSBLSU5ELCBl
aXRoZXIgZXhwcmVzcyBvciBpbXBsaWVkLgogU2VlIHRoZSBMaWNlbnNlIGZvciB0aGUgc3Bl
Y2lmaWMgbGFuZ3VhZ2UgZ292ZXJuaW5nIHBlcm1pc3Npb25zIGFuZAogbGltaXRhdGlvbnMg
dW5kZXIgdGhlIExpY2Vuc2UuCgoICgECEgMQACcKCQoCAwASAxIAIwoJCgIDARIDEwA1CgkK
AgMCEgMUADMKCAoBCBIDFgBgCgkKAggLEgMWAGAKCAoBCBIDFwAiCgkKAggKEgMXACIKCAoB
CBIDGAAsCgkKAggIEgMYACwKCAoBCBIDGQA7CgkKAggBEgMZADsKrAEKAgQAEgQeAFEBGp8B
IEVhY2ggVGFyZ2V0IHJlcHJlc2VudHMgZGF0YSBmb3IgYSBnaXZlbiB0YXJnZXQgaW4gYSBn
aXZlbiBJbnZvY2F0aW9uLgogQ29uZmlndXJlZFRhcmdldCBhbmQgQWN0aW9uIHJlc291cmNl
cyB1bmRlciBlYWNoIFRhcmdldCBjb250YWluIHRoZSBidWxrIG9mCiB0aGUgZGF0YS4KCgoK
AwQAARIDHggOCgsKAwQABxIEHwIiBAoNCgUEAAedCBIEHwIiBApECgQEAAMAEgQlAisDGjYg
VGhlIHJlc291cmNlIElEIGNvbXBvbmVudHMgdGhhdCBpZGVudGlmeSB0aGUgVGFyZ2V0LgoK
DAoFBAADAAESAyUKDAojCgYEAAMAAgASAycEHRoUIFRoZSBJbnZvY2F0aW9uIElELgoKDgoH
BAADAAIABRIDJwQKCg4KBwQAAwACAAESAycLGAoOCgcEAAMAAgADEgMnGxwKHwoGBAADAAIB
EgMqBBkaECBUaGUgVGFyZ2V0IElELgoKDgoHBAADAAIBBRIDKgQKCg4KBwQAAwACAQESAyoL
FAoOCgcEAAMAAgEDEgMqFxgKdQoEBAACABIDLwISGmggVGhlIHJlc291cmNlIG5hbWUuICBJ
dHMgZm9ybWF0IG11c3QgYmU6CiBpbnZvY2F0aW9ucy8ke0lOVk9DQVRJT05fSUR9L3Rhcmdl
dHMvJHt1cmxfZW5jb2RlKFRBUkdFVF9JRCl9CgoMCgUEAAIABRIDLwIICgwKBQQAAgABEgMv
CQ0KDAoFBAACAAMSAy8QEQp9CgQEAAIBEgMzAgwacCBUaGUgcmVzb3VyY2UgSUQgY29tcG9u
ZW50cyB0aGF0IGlkZW50aWZ5IHRoZSBUYXJnZXQuIFRoZXkgbXVzdCBtYXRjaCB0aGUKIHJl
c291cmNlIG5hbWUgYWZ0ZXIgcHJvcGVyIGVuY29kaW5nLgoKDAoFBAACAQYSAzMCBAoMCgUE
AAIBARIDMwUHCgwKBQQAAgEDEgMzCgsKdwoEBAACAhIDNwI9GmogVGhpcyBpcyB0aGUgYWdn
cmVnYXRlIHN0YXR1cyBvZiB0aGUgdGFyZ2V0LgogREVQUkVDQVRFRCAtIHVzZSBDb25maWd1
cmVkVGFyZ2V0LnN0YXR1c19hdHRyaWJ1dGVzIGluc3RlYWQKCgwKBQQAAgIGEgM3AhIKDAoF
BAACAgESAzcTJAoMCgUEAAICAxIDNycoCgwKBQQAAgIIEgM3KTwKDQoGBAACAggDEgM3KjsK
OQoEBAACAxIDOgIUGiwgV2hlbiB0aGlzIHRhcmdldCBzdGFydGVkIGFuZCBpdHMgZHVyYXRp
b24uCgoMCgUEAAIDBhIDOgIICgwKBQQAAgMBEgM6CQ8KDAoFBAACAwMSAzoSEwo0CgQEAAIE
EgM9AikaJyBBdHRyaWJ1dGVzIHRoYXQgYXBwbHkgdG8gYWxsIHRhcmdldHMuCgoMCgUEAAIE
BhIDPQISCgwKBQQAAgQBEgM9EyQKDAoFBAACBAMSAz0nKApLCgQEAAIFEgNAAiUaPiBBdHRy
aWJ1dGVzIHRoYXQgYXBwbHkgdG8gYWxsIHRlc3QgYWN0aW9ucyB1bmRlciB0aGlzIHRhcmdl
dC4KCgwKBQQAAgUGEgNAAhAKDAoFBAACBQESA0ARIAoMCgUEAAIFAxIDQCMkCsEBCgQEAAIG
EgNFAiMaswEgQXJiaXRyYXJ5IG5hbWUtdmFsdWUgcGFpcnMuCiBUaGlzIGlzIGltcGxlbWVu
dGVkIGFzIGEgbXVsdGktbWFwLiBNdWx0aXBsZSBwcm9wZXJ0aWVzIGFyZSBhbGxvd2VkIHdp
dGgKIHRoZSBzYW1lIGtleS4gUHJvcGVydGllcyB3aWxsIGJlIHJldHVybmVkIGluIGxleGlj
b2dyYXBoaWNhbCBvcmRlciBieSBrZXkuCgoMCgUEAAIGBBIDRQIKCgwKBQQAAgYGEgNFCxMK
DAoFBAACBgESA0UUHgoMCgUEAAIGAxIDRSEiCpcCCgQEAAIHEgNLAhoaiQIgQSBsaXN0IG9m
IGZpbGUgcmVmZXJlbmNlcyBmb3IgdGFyZ2V0IGxldmVsIGZpbGVzLgogVGhlIGZpbGUgSURz
IG11c3QgYmUgdW5pcXVlIHdpdGhpbiB0aGlzIGxpc3QuIER1cGxpY2F0ZSBmaWxlIElEcyB3
aWxsCiByZXN1bHQgaW4gYW4gZXJyb3IuIEZpbGVzIHdpbGwgYmUgcmV0dXJuZWQgaW4gbGV4
aWNvZ3JhcGhpY2FsIG9yZGVyIGJ5IElELgogVXNlIHRoaXMgZmllbGQgdG8gc3BlY2lmeSBv
dXRwdXRzIG5vdCByZWxhdGVkIHRvIGEgY29uZmlndXJhdGlvbi4KCgwKBQQAAgcEEgNLAgoK
DAoFBAACBwYSA0sLDwoMCgUEAAIHARIDSxAVCgwKBQQAAgcDEgNLGBkK0gEKBAQAAggSA1AC
FBrEASBQcm92aWRlcyBhIGhpbnQgdG8gY2xpZW50cyBhcyB0byB3aGV0aGVyIHRvIGRpc3Bs
YXkgdGhlIFRhcmdldCB0byB1c2Vycy4KIElmIHRydWUgdGhlbiBjbGllbnRzIGxpa2VseSB3
YW50IHRvIGRpc3BsYXkgdGhlIFRhcmdldCBieSBkZWZhdWx0LgogT25jZSBzZXQgdG8gdHJ1
ZSwgdGhpcyBtYXkgbm90IGJlIHNldCBiYWNrIHRvIGZhbHNlLgoKDAoFBAACCAUSA1ACBgoM
CgUEAAIIARIDUAcOCgwKBQQAAggDEgNQERMKMwoCBAESBFQAYQEaJyBBdHRyaWJ1dGVzIHRo
YXQgYXBwbHkgdG8gYWxsIHRhcmdldHMuCgoKCgMEAQESA1QIGAprCgQEAQIAEgNXAhYaXiBJ
ZiBrbm93biwgaW5kaWNhdGVzIHRoZSB0eXBlIG9mIHRoaXMgdGFyZ2V0LiAgSW4gYmF6ZWwg
dGhpcyBjb3JyZXNwb25kcwogdG8gdGhlIHJ1bGUtc3VmZml4LgoKDAoFBAECAAYSA1cCDAoM
CgUEAQIAARIDVw0RCgwKBQQBAgADEgNXFBUKVgoEBAECARIDWgIYGkkgSWYga25vd24sIHRo
ZSBtYWluIGxhbmd1YWdlIG9mIHRoaXMgdGFyZ2V0LCBlLmcuIGphdmEsIGNjLCBweXRob24s
IGV0Yy4KCgwKBQQBAgEGEgNaAgoKDAoFBAECAQESA1oLEwoMCgUEAQIBAxIDWhYXCpUCCgQE
AQICEgNgAhsahwIgVGhlIHRhZ3MgYXR0cmlidXRlIG9mIHRoZSBidWlsZCBydWxlLiBUaGVz
ZSBzaG91bGQgYmUgc2hvcnQsIGRlc2NyaXB0aXZlCiB3b3JkcywgYW5kIHRoZXJlIHNob3Vs
ZCBvbmx5IGJlIGEgZmV3IG9mIHRoZW0uCiBUaGlzIGlzIGltcGxlbWVudGVkIGFzIGEgc2V0
LiBBbGwgdGFncyB3aWxsIGJlIHVuaXF1ZS4gQW55IGR1cGxpY2F0ZSB0YWdzCiB3aWxsIGJl
IGlnbm9yZWQuIFRhZ3Mgd2lsbCBiZSByZXR1cm5lZCBpbiBsZXhpY29ncmFwaGljYWwgb3Jk
ZXIuCgoMCgUEAQICBBIDYAIKCgwKBQQBAgIFEgNgCxEKDAoFBAECAgESA2ASFgoMCgUEAQIC
AxIDYBkaCksKAgQCEgRkAGcBGj8gQXR0cmlidXRlcyB0aGF0IGFwcGx5IG9ubHkgdG8gdGVz
dCBhY3Rpb25zIHVuZGVyIHRoaXMgdGFyZ2V0LgoKCgoDBAIBEgNkCBYKSAoEBAICABIDZgIU
GjsgSW5kaWNhdGVzIGhvdyBiaWcgdGhlIHVzZXIgaW5kaWNhdGVkIHRoZSB0ZXN0IGFjdGlv
biB3YXMuCgoMCgUEAgIABhIDZgIKCgwKBQQCAgABEgNmCw8KDAoFBAICAAMSA2YSEwpYCgIF
ABIEagB8ARpMIFRoZXNlIGNvcnJlc3BvbmQgdG8gdGhlIHN1ZmZpeCBvZiB0aGUgcnVsZSBu
YW1lLiBFZyBjY190ZXN0IGhhcyB0eXBlIFRFU1QuCgoKCgMFAAESA2oFDwovCgQFAAIAEgNs
Ah4aIiBVbnNwZWNpZmllZCBieSB0aGUgYnVpbGQgc3lzdGVtLgoKDAoFBQACAAESA2wCGQoM
CgUFAAIAAhIDbBwdCjMKBAUAAgESA28CEhomIEFuIGFwcGxpY2F0aW9uIGUuZy4gaW9zX2Fw
cGxpY2F0aW9uLgoKDAoFBQACAQESA28CDQoMCgUFAAIBAhIDbxARCi4KBAUAAgISA3ICDRoh
IEEgYmluYXJ5IHRhcmdldCBlLmcuIGNjX2JpbmFyeS4KCgwKBQUAAgIBEgNyAggKDAoFBQAC
AgISA3ILDAoxCgQFAAIDEgN1Ag4aJCBBIGxpYnJhcnkgdGFyZ2V0IGUuZy4gamF2YV9saWJy
YXJ5CgoMCgUFAAIDARIDdQIJCgwKBQUAAgMCEgN1DA0KGAoEBQACBBIDeAIOGgsgQSBwYWNr
YWdlCgoMCgUFAAIEARIDeAIJCgwKBQUAAgQCEgN4DA0KUQoEBQACBRIDewILGkQgQW55IHRl
c3QgdGFyZ2V0LCBpbiBiYXplbCB0aGF0IG1lYW5zIGEgcnVsZSB3aXRoIGEgJ190ZXN0JyBz
dWZmaXguCgoMCgUFAAIFARIDewIGCgwKBQUAAgUCEgN7CQoKSAoCBQESBX8AkQEBGjsgSW5k
aWNhdGVzIGhvdyBiaWcgdGhlIHVzZXIgaW5kaWNhdGVkIHRoZSB0ZXN0IGFjdGlvbiB3YXMu
CgoKCgMFAQESA38FDQooCgQFAQIAEgSBAQIcGhogVW5zcGVjaWZpZWQgYnkgdGhlIHVzZXIu
CgoNCgUFAQIAARIEgQECFwoNCgUFAQIAAhIEgQEaGwo0CgQFAQIBEgSEAQIMGiYgVW5pdCB0
ZXN0IHRha2luZyBsZXNzIHRoYW4gMSBtaW51dGUuCgoNCgUFAQIBARIEhAECBwoNCgUFAQIB
AhIEhAEKCwo9CgQFAQICEgSHAQINGi8gSW50ZWdyYXRpb24gdGVzdHMgdGFraW5nIGxlc3Mg
dGhhbiA1IG1pbnV0ZXMuCgoNCgUFAQICARIEhwECCAoNCgUFAQICAhIEhwELDAo9CgQFAQID
EgSKAQIMGi8gRW5kLXRvLWVuZCB0ZXN0cyB0YWtpbmcgbGVzcyB0aGFuIDE1IG1pbnV0ZXMu
CgoNCgUFAQIDARIEigECBwoNCgUFAQIDAhIEigEKCwonCgQFAQIEEgSNAQIPGhkgRXZlbiBi
aWdnZXIgdGhhbiBMQVJHRS4KCg0KBQUBAgQBEgSNAQIKCg0KBQUBAgQCEgSNAQ0OCkUKBAUB
AgUSBJABAhEaNyBTb21ldGhpbmcgdGhhdCBkb2Vzbid0IGZpdCBpbnRvIHRoZSBhYm92ZSBj
YXRlZ29yaWVzLgoKDQoFBQECBQESBJABAgwKDQoFBQECBQISBJABDxBiBnByb3RvMw==
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Devtools::Resultstore::V2::Target::Target ===
    # Fields for Target
    # Field: name Type: 9 ()
    # Field: id Type: 11 (.google.devtools.resultstore.v2.Target.Id)
    # Field: status_attributes Type: 11 (.google.devtools.resultstore.v2.StatusAttributes)
    # Field: timing Type: 11 (.google.devtools.resultstore.v2.Timing)
    # Field: target_attributes Type: 11 (.google.devtools.resultstore.v2.TargetAttributes)
    # Field: test_attributes Type: 11 (.google.devtools.resultstore.v2.TestAttributes)
    # Field: properties Type: 11 (.google.devtools.resultstore.v2.Property)
    # Field: files Type: 11 (.google.devtools.resultstore.v2.File)
    # Field: visible Type: 8 ()

# === Message: Google::Devtools::Resultstore::V2::Target::TargetAttributes ===
    # Fields for TargetAttributes
    # Field: type Type: 14 (.google.devtools.resultstore.v2.TargetType)
    # Field: language Type: 14 (.google.devtools.resultstore.v2.Language)
    # Field: tags Type: 9 ()

# === Message: Google::Devtools::Resultstore::V2::Target::TestAttributes ===
    # Fields for TestAttributes
    # Field: size Type: 14 (.google.devtools.resultstore.v2.TestSize)

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Devtools::Resultstore::V2::Target - Compiled Protocol Buffers messages for google/devtools/resultstore/v2/target.proto

=head1 SYNOPSIS

    use Google::Devtools::Resultstore::V2::Target;

    my $msg = Google::Devtools::Resultstore::V2::Target::Target->new({
        name => $name,
        id => $id,
        status_attributes => $status_attributes,
        timing => $timing,
    });

    # Read or update a field
    my $val = $msg->name();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Devtools::Resultstore::V2::Target::Target->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/devtools/resultstore/v2/target.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Devtools::Resultstore::V2::Target::Target

Each Target represents data for a given target in a given Invocation.
ConfiguredTarget and Action resources under each Target contain the bulk of
the data.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

The resource name.  Its format must be:
invocations/${INVOCATION_ID}/targets/${url_encode(TARGET_ID)}

=item * C<< $msg->id() >> / C<< $msg->id($value) >>

Type: C<Message> (L<Google::Devtools::Resultstore::V2::Target::Target::Id>)

The resource ID components that identify the Target. They must match the
resource name after proper encoding.

=item * C<< $msg->status_attributes() >> / C<< $msg->status_attributes($value) >>

Type: C<Message> (L<Google::Devtools::Resultstore::V2::Common::StatusAttributes>)

This is the aggregate status of the target.
DEPRECATED - use ConfiguredTarget.status_attributes instead

=item * C<< $msg->timing() >> / C<< $msg->timing($value) >>

Type: C<Message> (L<Google::Devtools::Resultstore::V2::Common::Timing>)

When this target started and its duration.

=item * C<< $msg->target_attributes() >> / C<< $msg->target_attributes($value) >>

Type: C<Message> (L<Google::Devtools::Resultstore::V2::Target::TargetAttributes>)

Attributes that apply to all targets.

=item * C<< $msg->test_attributes() >> / C<< $msg->test_attributes($value) >>

Type: C<Message> (L<Google::Devtools::Resultstore::V2::Target::TestAttributes>)

Attributes that apply to all test actions under this target.

=item * C<< $msg->properties() >> / C<< $msg->properties($value) >>

Type: C<Message> (L<Google::Devtools::Resultstore::V2::Common::Property>)

Arbitrary name-value pairs.
This is implemented as a multi-map. Multiple properties are allowed with
the same key. Properties will be returned in lexicographical order by key.

=item * C<< $msg->files() >> / C<< $msg->files($value) >>

Type: C<Message> (L<Google::Devtools::Resultstore::V2::File::File>)

A list of file references for target level files.
The file IDs must be unique within this list. Duplicate file IDs will
result in an error. Files will be returned in lexicographical order by ID.
Use this field to specify outputs not related to a configuration.

=item * C<< $msg->visible() >> / C<< $msg->visible($value) >>

Type: C<Bool>

Provides a hint to clients as to whether to display the Target to users.
If true then clients likely want to display the Target by default.
Once set to true, this may not be set back to false.

=back

=head2 Google::Devtools::Resultstore::V2::Target::TargetAttributes

Attributes that apply to all targets.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->type() >> / C<< $msg->type($value) >>

Type: C<Enum> (L<Google::Devtools::Resultstore::V2::TargetType>)

If known, indicates the type of this target.  In bazel this corresponds
to the rule-suffix.

=item * C<< $msg->language() >> / C<< $msg->language($value) >>

Type: C<Enum> (L<Google::Devtools::Resultstore::V2::Language>)

If known, the main language of this target, e.g. java, cc, python, etc.

=item * C<< $msg->tags() >> / C<< $msg->tags($value) >>

Type: C<String>

The tags attribute of the build rule. These should be short, descriptive
words, and there should only be a few of them.
This is implemented as a set. All tags will be unique. Any duplicate tags
will be ignored. Tags will be returned in lexicographical order.

=back

=head2 Google::Devtools::Resultstore::V2::Target::TestAttributes

Attributes that apply only to test actions under this target.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->size() >> / C<< $msg->size($value) >>

Type: C<Enum> (L<Google::Devtools::Resultstore::V2::TestSize>)

Indicates how big the user indicated the test action was.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Devtools::Resultstore::V2::Target::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
