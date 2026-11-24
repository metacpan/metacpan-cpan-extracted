package Google::Cloud::Productregistry::V1::CloudProductRegistryReadService;

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
    eval { require Google::Cloud::Productregistry::V1::LogicalProduct };
    eval { require Google::Cloud::Productregistry::V1::LogicalProductVariant };
    eval { require Google::Cloud::Productregistry::V1::ProductSuite };
    my $descriptor_b64 = <<'EOF';
Cklnb29nbGUvY2xvdWQvcHJvZHVjdHJlZ2lzdHJ5L3YxL2Nsb3VkX3Byb2R1Y3RfcmVnaXN0
cnlfcmVhZF9zZXJ2aWNlLnByb3RvEh9nb29nbGUuY2xvdWQucHJvZHVjdHJlZ2lzdHJ5LnYx
Ghxnb29nbGUvYXBpL2Fubm90YXRpb25zLnByb3RvGhdnb29nbGUvYXBpL2NsaWVudC5wcm90
bxofZ29vZ2xlL2FwaS9maWVsZF9iZWhhdmlvci5wcm90bxoZZ29vZ2xlL2FwaS9yZXNvdXJj
ZS5wcm90bxo1Z29vZ2xlL2Nsb3VkL3Byb2R1Y3RyZWdpc3RyeS92MS9sb2dpY2FsX3Byb2R1
Y3QucHJvdG8aPWdvb2dsZS9jbG91ZC9wcm9kdWN0cmVnaXN0cnkvdjEvbG9naWNhbF9wcm9k
dWN0X3ZhcmlhbnQucHJvdG8aM2dvb2dsZS9jbG91ZC9wcm9kdWN0cmVnaXN0cnkvdjEvcHJv
ZHVjdF9zdWl0ZS5wcm90byJmChZHZXRQcm9kdWN0U3VpdGVSZXF1ZXN0EkwKBG5hbWUYASAB
KAlCOOBBAvpBMgowY2xvdWRwcm9kdWN0cmVnaXN0cnkuZ29vZ2xlYXBpcy5jb20vUHJvZHVj
dFN1aXRlUgRuYW1lImoKGEdldExvZ2ljYWxQcm9kdWN0UmVxdWVzdBJOCgRuYW1lGAEgASgJ
QjrgQQL6QTQKMmNsb3VkcHJvZHVjdHJlZ2lzdHJ5Lmdvb2dsZWFwaXMuY29tL0xvZ2ljYWxQ
cm9kdWN0UgRuYW1lIngKH0dldExvZ2ljYWxQcm9kdWN0VmFyaWFudFJlcXVlc3QSVQoEbmFt
ZRgBIAEoCUJB4EEC+kE7CjljbG91ZHByb2R1Y3RyZWdpc3RyeS5nb29nbGVhcGlzLmNvbS9M
b2dpY2FsUHJvZHVjdFZhcmlhbnRSBG5hbWUiYAoYTGlzdFByb2R1Y3RTdWl0ZXNSZXF1ZXN0
EiAKCXBhZ2Vfc2l6ZRgBIAEoBUID4EEBUghwYWdlU2l6ZRIiCgpwYWdlX3Rva2VuGAIgASgJ
QgPgQQFSCXBhZ2VUb2tlbiKZAQoZTGlzdFByb2R1Y3RTdWl0ZXNSZXNwb25zZRJUCg5wcm9k
dWN0X3N1aXRlcxgBIAMoCzItLmdvb2dsZS5jbG91ZC5wcm9kdWN0cmVnaXN0cnkudjEuUHJv
ZHVjdFN1aXRlUg1wcm9kdWN0U3VpdGVzEiYKD25leHRfcGFnZV90b2tlbhgCIAEoCVINbmV4
dFBhZ2VUb2tlbiJ/ChpMaXN0TG9naWNhbFByb2R1Y3RzUmVxdWVzdBIbCgZmaWx0ZXIYASAB
KAlCA+BBAVIGZmlsdGVyEiAKCXBhZ2Vfc2l6ZRgCIAEoBUID4EEBUghwYWdlU2l6ZRIiCgpw
YWdlX3Rva2VuGAMgASgJQgPgQQFSCXBhZ2VUb2tlbiKhAQobTGlzdExvZ2ljYWxQcm9kdWN0
c1Jlc3BvbnNlEloKEGxvZ2ljYWxfcHJvZHVjdHMYASADKAsyLy5nb29nbGUuY2xvdWQucHJv
ZHVjdHJlZ2lzdHJ5LnYxLkxvZ2ljYWxQcm9kdWN0Ug9sb2dpY2FsUHJvZHVjdHMSJgoPbmV4
dF9wYWdlX3Rva2VuGAIgASgJUg1uZXh0UGFnZVRva2VuIsQBCiFMaXN0TG9naWNhbFByb2R1
Y3RWYXJpYW50c1JlcXVlc3QSWQoGcGFyZW50GAEgASgJQkHgQQL6QTsSOWNsb3VkcHJvZHVj
dHJlZ2lzdHJ5Lmdvb2dsZWFwaXMuY29tL0xvZ2ljYWxQcm9kdWN0VmFyaWFudFIGcGFyZW50
EiAKCXBhZ2Vfc2l6ZRgCIAEoBUID4EEBUghwYWdlU2l6ZRIiCgpwYWdlX3Rva2VuGAMgASgJ
QgPgQQFSCXBhZ2VUb2tlbiK+AQoiTGlzdExvZ2ljYWxQcm9kdWN0VmFyaWFudHNSZXNwb25z
ZRJwChhsb2dpY2FsX3Byb2R1Y3RfdmFyaWFudHMYASADKAsyNi5nb29nbGUuY2xvdWQucHJv
ZHVjdHJlZ2lzdHJ5LnYxLkxvZ2ljYWxQcm9kdWN0VmFyaWFudFIWbG9naWNhbFByb2R1Y3RW
YXJpYW50cxImCg9uZXh0X3BhZ2VfdG9rZW4YAiABKAlSDW5leHRQYWdlVG9rZW4iOQoTTG9v
a3VwRW50aXR5UmVxdWVzdBIiCgpsb29rdXBfdXJpGAEgASgJQgPgQQJSCWxvb2t1cFVyaSLE
AgoUTG9va3VwRW50aXR5UmVzcG9uc2USWgoPbG9naWNhbF9wcm9kdWN0GAEgASgLMi8uZ29v
Z2xlLmNsb3VkLnByb2R1Y3RyZWdpc3RyeS52MS5Mb2dpY2FsUHJvZHVjdEgAUg5sb2dpY2Fs
UHJvZHVjdBJwChdsb2dpY2FsX3Byb2R1Y3RfdmFyaWFudBgCIAEoCzI2Lmdvb2dsZS5jbG91
ZC5wcm9kdWN0cmVnaXN0cnkudjEuTG9naWNhbFByb2R1Y3RWYXJpYW50SABSFWxvZ2ljYWxQ
cm9kdWN0VmFyaWFudBJUCg1wcm9kdWN0X3N1aXRlGAMgASgLMi0uZ29vZ2xlLmNsb3VkLnBy
b2R1Y3RyZWdpc3RyeS52MS5Qcm9kdWN0U3VpdGVIAFIMcHJvZHVjdFN1aXRlQggKBmVudGl0
eTLQCwofQ2xvdWRQcm9kdWN0UmVnaXN0cnlSZWFkU2VydmljZRKkAQoPR2V0UHJvZHVjdFN1
aXRlEjcuZ29vZ2xlLmNsb3VkLnByb2R1Y3RyZWdpc3RyeS52MS5HZXRQcm9kdWN0U3VpdGVS
ZXF1ZXN0Gi0uZ29vZ2xlLmNsb3VkLnByb2R1Y3RyZWdpc3RyeS52MS5Qcm9kdWN0U3VpdGUi
KYLT5JMCHBIaL3YxL3tuYW1lPXByb2R1Y3RTdWl0ZXMvKn3aQQRuYW1lEqUBChFMaXN0UHJv
ZHVjdFN1aXRlcxI5Lmdvb2dsZS5jbG91ZC5wcm9kdWN0cmVnaXN0cnkudjEuTGlzdFByb2R1
Y3RTdWl0ZXNSZXF1ZXN0GjouZ29vZ2xlLmNsb3VkLnByb2R1Y3RyZWdpc3RyeS52MS5MaXN0
UHJvZHVjdFN1aXRlc1Jlc3BvbnNlIhmC0+STAhMSES92MS9wcm9kdWN0U3VpdGVzEqwBChFH
ZXRMb2dpY2FsUHJvZHVjdBI5Lmdvb2dsZS5jbG91ZC5wcm9kdWN0cmVnaXN0cnkudjEuR2V0
TG9naWNhbFByb2R1Y3RSZXF1ZXN0Gi8uZ29vZ2xlLmNsb3VkLnByb2R1Y3RyZWdpc3RyeS52
MS5Mb2dpY2FsUHJvZHVjdCIrgtPkkwIeEhwvdjEve25hbWU9bG9naWNhbFByb2R1Y3RzLyp9
2kEEbmFtZRKtAQoTTGlzdExvZ2ljYWxQcm9kdWN0cxI7Lmdvb2dsZS5jbG91ZC5wcm9kdWN0
cmVnaXN0cnkudjEuTGlzdExvZ2ljYWxQcm9kdWN0c1JlcXVlc3QaPC5nb29nbGUuY2xvdWQu
cHJvZHVjdHJlZ2lzdHJ5LnYxLkxpc3RMb2dpY2FsUHJvZHVjdHNSZXNwb25zZSIbgtPkkwIV
EhMvdjEvbG9naWNhbFByb2R1Y3RzEswBChhHZXRMb2dpY2FsUHJvZHVjdFZhcmlhbnQSQC5n
b29nbGUuY2xvdWQucHJvZHVjdHJlZ2lzdHJ5LnYxLkdldExvZ2ljYWxQcm9kdWN0VmFyaWFu
dFJlcXVlc3QaNi5nb29nbGUuY2xvdWQucHJvZHVjdHJlZ2lzdHJ5LnYxLkxvZ2ljYWxQcm9k
dWN0VmFyaWFudCI2gtPkkwIpEicvdjEve25hbWU9bG9naWNhbFByb2R1Y3RzLyovdmFyaWFu
dHMvKn3aQQRuYW1lEt8BChpMaXN0TG9naWNhbFByb2R1Y3RWYXJpYW50cxJCLmdvb2dsZS5j
bG91ZC5wcm9kdWN0cmVnaXN0cnkudjEuTGlzdExvZ2ljYWxQcm9kdWN0VmFyaWFudHNSZXF1
ZXN0GkMuZ29vZ2xlLmNsb3VkLnByb2R1Y3RyZWdpc3RyeS52MS5MaXN0TG9naWNhbFByb2R1
Y3RWYXJpYW50c1Jlc3BvbnNlIjiC0+STAikSJy92MS97cGFyZW50PWxvZ2ljYWxQcm9kdWN0
cy8qfS92YXJpYW50c9pBBnBhcmVudBKlAgoMTG9va3VwRW50aXR5EjQuZ29vZ2xlLmNsb3Vk
LnByb2R1Y3RyZWdpc3RyeS52MS5Mb29rdXBFbnRpdHlSZXF1ZXN0GjUuZ29vZ2xlLmNsb3Vk
LnByb2R1Y3RyZWdpc3RyeS52MS5Mb29rdXBFbnRpdHlSZXNwb25zZSKnAYLT5JMCoAESLy92
MS97bG9va3VwX3VyaT1sb2dpY2FsUHJvZHVjdHMvKn06bG9va3VwRW50aXR5WjwSOi92MS97
bG9va3VwX3VyaT1sb2dpY2FsUHJvZHVjdHMvKi92YXJpYW50cy8qfTpsb29rdXBFbnRpdHla
LxItL3YxL3tsb29rdXBfdXJpPXByb2R1Y3RTdWl0ZXMvKn06bG9va3VwRW50aXR5GibKQSNj
bG91ZHByb2R1Y3RyZWdpc3RyeS5nb29nbGVhcGlzLmNvbUKFAgojY29tLmdvb2dsZS5jbG91
ZC5wcm9kdWN0cmVnaXN0cnkudjFCJENsb3VkUHJvZHVjdFJlZ2lzdHJ5UmVhZFNlcnZpY2VQ
cm90b1ABWk1jbG91ZC5nb29nbGUuY29tL2dvL3Byb2R1Y3RyZWdpc3RyeS9hcGl2MS9wcm9k
dWN0cmVnaXN0cnlwYjtwcm9kdWN0cmVnaXN0cnlwYqoCH0dvb2dsZS5DbG91ZC5Qcm9kdWN0
UmVnaXN0cnkuVjHKAh9Hb29nbGVcQ2xvdWRcUHJvZHVjdFJlZ2lzdHJ5XFYx6gIiR29vZ2xl
OjpDbG91ZDo6UHJvZHVjdFJlZ2lzdHJ5OjpWMUrSOQoHEgUOAP8BAQq8BAoBDBIDDgASMrEE
IENvcHlyaWdodCAyMDI2IEdvb2dsZSBMTEMKCiBMaWNlbnNlZCB1bmRlciB0aGUgQXBhY2hl
IExpY2Vuc2UsIFZlcnNpb24gMi4wICh0aGUgIkxpY2Vuc2UiKTsKIHlvdSBtYXkgbm90IHVz
ZSB0aGlzIGZpbGUgZXhjZXB0IGluIGNvbXBsaWFuY2Ugd2l0aCB0aGUgTGljZW5zZS4KIFlv
dSBtYXkgb2J0YWluIGEgY29weSBvZiB0aGUgTGljZW5zZSBhdAoKICAgICBodHRwOi8vd3d3
LmFwYWNoZS5vcmcvbGljZW5zZXMvTElDRU5TRS0yLjAKCiBVbmxlc3MgcmVxdWlyZWQgYnkg
YXBwbGljYWJsZSBsYXcgb3IgYWdyZWVkIHRvIGluIHdyaXRpbmcsIHNvZnR3YXJlCiBkaXN0
cmlidXRlZCB1bmRlciB0aGUgTGljZW5zZSBpcyBkaXN0cmlidXRlZCBvbiBhbiAiQVMgSVMi
IEJBU0lTLAogV0lUSE9VVCBXQVJSQU5USUVTIE9SIENPTkRJVElPTlMgT0YgQU5ZIEtJTkQs
IGVpdGhlciBleHByZXNzIG9yIGltcGxpZWQuCiBTZWUgdGhlIExpY2Vuc2UgZm9yIHRoZSBz
cGVjaWZpYyBsYW5ndWFnZSBnb3Zlcm5pbmcgcGVybWlzc2lvbnMgYW5kCiBsaW1pdGF0aW9u
cyB1bmRlciB0aGUgTGljZW5zZS4KCggKAQISAxAAKAoJCgIDABIDEgAmCgkKAgMBEgMTACEK
CQoCAwISAxQAKQoJCgIDAxIDFQAjCgkKAgMEEgMWAD8KCQoCAwUSAxcARwoJCgIDBhIDGAA9
CggKAQgSAxoAPAoJCgIIJRIDGgA8CggKAQgSAxsAZAoJCgIICxIDGwBkCggKAQgSAxwAIgoJ
CgIIChIDHAAiCggKAQgSAx0ARQoJCgIICBIDHQBFCggKAQgSAx4APAoJCgIIARIDHgA8CggK
AQgSAx8APAoJCgIIKRIDHwA8CggKAQgSAyAAOwoJCgIILRIDIAA7CoMBCgIGABIEJABlARp3
IENsb3VkIFByb2R1Y3QgUmVnaXN0cnkgUmVhZCBTZXJ2aWNlIHByb3ZpZGVzIGNhcGFiaWxp
dGllcyB0byBhY2Nlc3MgYWxsIGZpcnN0CiBhbmQgdGhpcmQgcGFydHkgR29vZ2xlIENsb3Vk
IHByb2R1Y3RzLgoKCgoDBgABEgMkCCcKCgoDBgADEgMlAksKDAoFBgADmQgSAyUCSwouCgQG
AAIAEgQoAi0DGiAgR2V0IGRldGFpbHMgb2YgYSBQcm9kdWN0U3VpdGUuCgoMCgUGAAIAARID
KAYVCgwKBQYAAgACEgMoFiwKDAoFBgACAAMSAyg3QwoNCgUGAAIABBIEKQQrBgoRCgkGAAIA
BLDKvCISBCkEKwYKDAoFBgACAAQSAywEMgoPCggGAAIABJsIABIDLAQyCiQKBAYAAgESBDAC
NQMaFiBMaXN0cyBQcm9kdWN0U3VpdGVzLgoKDAoFBgACAQESAzAGFwoMCgUGAAIBAhIDMBgw
CgwKBQYAAgEDEgMxDygKDQoFBgACAQQSBDIENAYKEQoJBgACAQSwyrwiEgQyBDQGCjEKBAYA
AgISBDgCPQMaIyBHZXRzIGRldGFpbHMgb2YgYSBMb2dpY2FsUHJvZHVjdC4KCgwKBQYAAgIB
EgM4BhcKDAoFBgACAgISAzgYMAoMCgUGAAICAxIDODtJCg0KBQYAAgIEEgQ5BDsGChEKCQYA
AgIEsMq8IhIEOQQ7BgoMCgUGAAICBBIDPAQyCg8KCAYAAgIEmwgAEgM8BDIKPgoEBgACAxIE
QAJFAxowIExpc3RzIExvZ2ljYWxQcm9kdWN0cyBtYXRjaGluZyBnaXZlbiBjcml0ZXJpYS4K
CgwKBQYAAgMBEgNABhkKDAoFBgACAwISA0AaNAoMCgUGAAIDAxIDQQ8qCg0KBQYAAgMEEgRC
BEQGChEKCQYAAgMEsMq8IhIEQgREBgo3CgQGAAIEEgRIAk4DGikgR2V0IGRldGFpbHMgb2Yg
YSBMb2dpY2FsUHJvZHVjdFZhcmlhbnQuCgoMCgUGAAIEARIDSAYeCgwKBQYAAgQCEgNIHz4K
DAoFBgACBAMSA0kPJAoNCgUGAAIEBBIESgRMBgoRCgkGAAIEBLDKvCISBEoETAYKDAoFBgAC
BAQSA00EMgoPCggGAAIEBJsIABIDTQQyCkUKBAYAAgUSBFECVwMaNyBMaXN0cyBMb2dpY2Fs
UHJvZHVjdFZhcmlhbnRzIG1hdGNoaW5nIGdpdmVuIGNyaXRlcmlhLgoKDAoFBgACBQESA1EG
IAoMCgUGAAIFAhIDUSFCCgwKBQYAAgUDEgNSDzEKDQoFBgACBQQSBFMEVQYKEQoJBgACBQSw
yrwiEgRTBFUGCgwKBQYAAgUEEgNWBDQKDwoIBgACBQSbCAASA1YENAohCgQGAAIGEgRaAmQD
GhMgTG9vayB1cCBlbnRpdGllcy4KCgwKBQYAAgYBEgNaBhIKDAoFBgACBgISA1oTJgoMCgUG
AAIGAxIDWjFFCg0KBQYAAgYEEgRbBGMGChEKCQYAAgYEsMq8IhIEWwRjBgoyCgIEABIEaABx
ARomIFJlcXVlc3QgbWVzc2FnZSBmb3IgR2V0UHJvZHVjdFN1aXRlLgoKCgoDBAABEgNoCB4K
agoEBAACABIEawJwBBpcIFJlcXVpcmVkLiBUaGUgbmFtZSBvZiB0aGUgUHJvZHVjdFN1aXRl
IHRvIHJldHJpZXZlLgogRm9ybWF0OiBwcm9kdWN0U3VpdGVzL3twcm9kdWN0X3N1aXRlfQoK
DAoFBAACAAUSA2sCCAoMCgUEAAIAARIDawkNCgwKBQQAAgADEgNrEBEKDQoFBAACAAgSBGsS
cAMKDwoIBAACAAicCAASA2wEKgoPCgcEAAIACJ8IEgRtBG8FCjQKAgQBEgR0AH0BGiggUmVx
dWVzdCBtZXNzYWdlIGZvciBHZXRMb2dpY2FsUHJvZHVjdC4KCgoKAwQBARIDdAggCnAKBAQB
AgASBHcCfAQaYiBSZXF1aXJlZC4gVGhlIG5hbWUgb2YgdGhlIExvZ2ljYWxQcm9kdWN0IHRv
IHJldHJpZXZlLgogRm9ybWF0OiBsb2dpY2FsUHJvZHVjdHMve2xvZ2ljYWxfcHJvZHVjdH0K
CgwKBQQBAgAFEgN3AggKDAoFBAECAAESA3cJDQoMCgUEAQIAAxIDdxARCg0KBQQBAgAIEgR3
EnwDCg8KCAQBAgAInAgAEgN4BCoKDwoHBAECAAifCBIEeQR7BQo9CgIEAhIGgAEAiQEBGi8g
UmVxdWVzdCBtZXNzYWdlIGZvciBHZXRMb2dpY2FsUHJvZHVjdFZhcmlhbnQuCgoLCgMEAgES
BIABCCcKjAEKBAQCAgASBoMBAogBBBp8IFJlcXVpcmVkLiBUaGUgbmFtZSBvZiB0aGUgTG9n
aWNhbFByb2R1Y3RWYXJpYW50IHRvIHJldHJpZXZlLgogRm9ybWF0OiBsb2dpY2FsUHJvZHVj
dHMve2xvZ2ljYWxfcHJvZHVjdH0vdmFyaWFudHMve3ZhcmlhbnR9CgoNCgUEAgIABRIEgwEC
CAoNCgUEAgIAARIEgwEJDQoNCgUEAgIAAxIEgwEQEQoPCgUEAgIACBIGgwESiAEDChAKCAQC
AgAInAgAEgSEAQQqChEKBwQCAgAInwgSBoUBBIcBBQo2CgIEAxIGjAEAmAEBGiggUmVxdWVz
dCBtZXNzYWdlIGZvciBMaXN0UHJvZHVjdFN1aXRlcy4KCgsKAwQDARIEjAEIIArqAQoEBAMC
ABIEkAECPxrbASBPcHRpb25hbC4gVGhlIG1heGltdW0gbnVtYmVyIG9mIHN1aXRlcyB0byBy
ZXR1cm4uIFRoZSBzZXJ2aWNlIG1heSByZXR1cm4KIGZld2VyIHRoYW4gdGhpcyB2YWx1ZS4g
SWYgdW5zcGVjaWZpZWQsIGF0IG1vc3QgMTAwIHN1aXRlcyB3aWxsIGJlIHJldHVybmVkLgog
VGhlIG1heGltdW0gdmFsdWUgaXMgNTAwOyB2YWx1ZXMgYWJvdmUgNTAwIHdpbGwgYmUgY29l
cmNlZCB0byA1MDAuCgoNCgUEAwIABRIEkAECBwoNCgUEAwIAARIEkAEIEQoNCgUEAwIAAxIE
kAEUFQoNCgUEAwIACBIEkAEWPgoQCggEAwIACJwIABIEkAEXPQqFAgoEBAMCARIElwECQRr2
ASBPcHRpb25hbC4gQSBwYWdlIHRva2VuLCByZWNlaXZlZCBmcm9tIGEgcHJldmlvdXMgYExp
c3RQcm9kdWN0U3VpdGVzYCBjYWxsLgogUHJvdmlkZSB0aGlzIHRvIHJldHJpZXZlIHRoZSBz
dWJzZXF1ZW50IHBhZ2UuCgogV2hlbiBwYWdpbmF0aW5nLCBhbGwgb3RoZXIgcGFyYW1ldGVy
cyBwcm92aWRlZCB0byBgTGlzdFByb2R1Y3RTdWl0ZXNgIG11c3QKIG1hdGNoIHRoZSBjYWxs
IHRoYXQgcHJvdmlkZWQgdGhlIHBhZ2UgdG9rZW4uCgoNCgUEAwIBBRIElwECCAoNCgUEAwIB
ARIElwEJEwoNCgUEAwIBAxIElwEWFwoNCgUEAwIBCBIElwEYQAoQCggEAwIBCJwIABIElwEZ
Pwo3CgIEBBIGmwEAogEBGikgUmVzcG9uc2UgbWVzc2FnZSBmb3IgTGlzdFByb2R1Y3RTdWl0
ZXMuCgoLCgMEBAESBJsBCCEKJQoEBAQCABIEnQECKxoXIE1hdGNoZWQgUHJvZHVjdFN1aXRl
cwoKDQoFBAQCAAQSBJ0BAgoKDQoFBAQCAAYSBJ0BCxcKDQoFBAQCAAESBJ0BGCYKDQoFBAQC
AAMSBJ0BKSoKkAEKBAQEAgESBKEBAh0agQEgQSB0b2tlbiwgd2hpY2ggY2FuIGJlIHNlbnQg
YXMgYHBhZ2VfdG9rZW5gIHRvIHJldHJpZXZlIHRoZSBuZXh0IHBhZ2UuCiBJZiB0aGlzIGZp
ZWxkIGlzIG9taXR0ZWQsIHRoZXJlIGFyZSBubyBzdWJzZXF1ZW50IHBhZ2VzLgoKDQoFBAQC
AQUSBKEBAggKDQoFBAQCAQESBKEBCRgKDQoFBAQCAQMSBKEBGxwKOAoCBAUSBqUBALcBARoq
IFJlcXVlc3QgbWVzc2FnZSBmb3IgTGlzdExvZ2ljYWxQcm9kdWN0cy4KCgsKAwQFARIEpQEI
IgqVAQoEBAUCABIEqQECPRqGASBPcHRpb25hbC4gVGhlIGZpbHRlciBleHByZXNzaW9uIGZv
ciBsaXN0aW5nIGxvZ2ljYWwgcHJvZHVjdHMuCiBGaWx0ZXIgc3ludGF4OiBodHRwczovL2dv
b2dsZS5haXAuZGV2LzE2MAogU3VwcG9ydGVkIGZpZWxkczogc3VpdGVfaWQKCg0KBQQFAgAF
EgSpAQIICg0KBQQFAgABEgSpAQkPCg0KBQQFAgADEgSpARITCg0KBQQFAgAIEgSpARQ8ChAK
CAQFAgAInAgAEgSpARU7Cv8BCgQEBQIBEgSvAQI/GvABIE9wdGlvbmFsLiBUaGUgbWF4aW11
bSBudW1iZXIgb2YgbG9naWNhbCBwcm9kdWN0cyB0byByZXR1cm4uIFRoZSBzZXJ2aWNlIG1h
eQogcmV0dXJuIGZld2VyIHRoYW4gdGhpcyB2YWx1ZS4gSWYgdW5zcGVjaWZpZWQsIGF0IG1v
c3QgMTAwIGxvZ2ljYWwgcHJvZHVjdHMKIHdpbGwgYmUgcmV0dXJuZWQuIFRoZSBtYXhpbXVt
IHZhbHVlIGlzIDUwMDsgdmFsdWVzIGFib3ZlIDUwMCB3aWxsIGJlCiBjb2VyY2VkIHRvIDUw
MC4KCg0KBQQFAgEFEgSvAQIHCg0KBQQFAgEBEgSvAQgRCg0KBQQFAgEDEgSvARQVCg0KBQQF
AgEIEgSvARY+ChAKCAQFAgEInAgAEgSvARc9CokCCgQEBQICEgS2AQJBGvoBIE9wdGlvbmFs
LiBBIHBhZ2UgdG9rZW4sIHJlY2VpdmVkIGZyb20gYSBwcmV2aW91cyBgTGlzdExvZ2ljYWxQ
cm9kdWN0c2AKIGNhbGwuIFByb3ZpZGUgdGhpcyB0byByZXRyaWV2ZSB0aGUgc3Vic2VxdWVu
dCBwYWdlLgoKIFdoZW4gcGFnaW5hdGluZywgYWxsIG90aGVyIHBhcmFtZXRlcnMgcHJvdmlk
ZWQgdG8gYExpc3RMb2dpY2FsUHJvZHVjdHNgCiBtdXN0IG1hdGNoIHRoZSBjYWxsIHRoYXQg
cHJvdmlkZWQgdGhlIHBhZ2UgdG9rZW4uCgoNCgUEBQICBRIEtgECCAoNCgUEBQICARIEtgEJ
EwoNCgUEBQICAxIEtgEWFwoNCgUEBQICCBIEtgEYQAoQCggEBQICCJwIABIEtgEZPwo5CgIE
BhIGugEAwQEBGisgUmVzcG9uc2UgbWVzc2FnZSBmb3IgTGlzdExvZ2ljYWxQcm9kdWN0cy4K
CgsKAwQGARIEugEIIwonCgQEBgIAEgS8AQIvGhkgTWF0Y2hlZCBMb2dpY2FsUHJvZHVjdHMK
Cg0KBQQGAgAEEgS8AQIKCg0KBQQGAgAGEgS8AQsZCg0KBQQGAgABEgS8ARoqCg0KBQQGAgAD
EgS8AS0uCpABCgQEBgIBEgTAAQIdGoEBIEEgdG9rZW4sIHdoaWNoIGNhbiBiZSBzZW50IGFz
IGBwYWdlX3Rva2VuYCB0byByZXRyaWV2ZSB0aGUgbmV4dCBwYWdlLgogSWYgdGhpcyBmaWVs
ZCBpcyBvbWl0dGVkLCB0aGVyZSBhcmUgbm8gc3Vic2VxdWVudCBwYWdlcy4KCg0KBQQGAgEF
EgTAAQIICg0KBQQGAgEBEgTAAQkYCg0KBQQGAgEDEgTAARscCj8KAgQHEgbEAQDcAQEaMSBS
ZXF1ZXN0IG1lc3NhZ2UgZm9yIExpc3RMb2dpY2FsUHJvZHVjdFZhcmlhbnRzLgoKCwoDBAcB
EgTEAQgpCmEKBAQHAgASBscBAswBBBpRIFJlcXVpcmVkLiBQYXJlbnQgbG9naWNhbCBwcm9k
dWN0IGlkLgogRm9ybWF0OiBsb2dpY2FsUHJvZHVjdHMve2xvZ2ljYWxfcHJvZHVjdH0KCg0K
BQQHAgAFEgTHAQIICg0KBQQHAgABEgTHAQkPCg0KBQQHAgADEgTHARITCg8KBQQHAgAIEgbH
ARTMAQMKEAoIBAcCAAicCAASBMgBBCoKEQoHBAcCAAifCBIGyQEEywEFCo8CCgQEBwIBEgTS
AQI/GoACIE9wdGlvbmFsLiBUaGUgbWF4aW11bSBudW1iZXIgb2YgbG9naWNhbCBwcm9kdWN0
IHZhcmlhbnRzIHRvIHJldHVybi4gVGhlCiBzZXJ2aWNlIG1heSByZXR1cm4gZmV3ZXIgdGhh
biB0aGlzIHZhbHVlLiBJZiB1bnNwZWNpZmllZCwgYXQgbW9zdCAxMDAKIGxvZ2ljYWwgcHJv
ZHVjdCB2YXJpYW50cyB3aWxsIGJlIHJldHVybmVkLiBUaGUgbWF4aW11bSB2YWx1ZSBpcyA1
MDA7IHZhbHVlcwogYWJvdmUgNTAwIHdpbGwgYmUgY29lcmNlZCB0byA1MDAuCgoNCgUEBwIB
BRIE0gECBwoNCgUEBwIBARIE0gEIEQoNCgUEBwIBAxIE0gEUFQoNCgUEBwIBCBIE0gEWPgoQ
CggEBwIBCJwIABIE0gEXPQqZAgoEBAcCAhIE2wECQRqKAiBPcHRpb25hbC4gQSBwYWdlIHRv
a2VuLCByZWNlaXZlZCBmcm9tIGEgcHJldmlvdXMKIGBMaXN0TG9naWNhbFByb2R1Y3RWYXJp
YW50c2AgY2FsbC4gUHJvdmlkZSB0aGlzIHRvIHJldHJpZXZlIHRoZSBzdWJzZXF1ZW50CiBw
YWdlLgoKIFdoZW4gcGFnaW5hdGluZywgYWxsIG90aGVyIHBhcmFtZXRlcnMgcHJvdmlkZWQg
dG8KIGBMaXN0TG9naWNhbFByb2R1Y3RWYXJpYW50c2AgbXVzdCBtYXRjaCB0aGUgY2FsbCB0
aGF0IHByb3ZpZGVkIHRoZSBwYWdlCiB0b2tlbi4KCg0KBQQHAgIFEgTbAQIICg0KBQQHAgIB
EgTbAQkTCg0KBQQHAgIDEgTbARYXCg0KBQQHAgIIEgTbARhAChAKCAQHAgIInAgAEgTbARk/
CkAKAgQIEgbfAQDmAQEaMiBSZXNwb25zZSBtZXNzYWdlIGZvciBMaXN0TG9naWNhbFByb2R1
Y3RWYXJpYW50cy4KCgsKAwQIARIE3wEIKgouCgQECAIAEgThAQI+GiAgTWF0Y2hlZCBMb2dp
Y2FsUHJvZHVjdFZhcmlhbnRzCgoNCgUECAIABBIE4QECCgoNCgUECAIABhIE4QELIAoNCgUE
CAIAARIE4QEhOQoNCgUECAIAAxIE4QE8PQqQAQoEBAgCARIE5QECHRqBASBBIHRva2VuLCB3
aGljaCBjYW4gYmUgc2VudCBhcyBgcGFnZV90b2tlbmAgdG8gcmV0cmlldmUgdGhlIG5leHQg
cGFnZS4KIElmIHRoaXMgZmllbGQgaXMgb21pdHRlZCwgdGhlcmUgYXJlIG5vIHN1YnNlcXVl
bnQgcGFnZXMuCgoNCgUECAIBBRIE5QECCAoNCgUECAIBARIE5QEJGAoNCgUECAIBAxIE5QEb
HAoxCgIECRIG6QEA8AEBGiMgUmVxdWVzdCBtZXNzYWdlIGZvciBMb29rdXBFbnRpdHkuCgoL
CgMECQESBOkBCBsKvQEKBAQJAgASBO8BAkEargEgUmVxdWlyZWQuIEVudGl0eSB1cmkgdG8g
bG9vayB1cC4KIFN1cHBvcnRlZCBGb3JtYXRzOgogbG9naWNhbFByb2R1Y3RzL3tsb2dpY2Fs
X3Byb2R1Y3R9CiBsb2dpY2FsUHJvZHVjdHMve2xvZ2ljYWxfcHJvZHVjdH0vdmFyaWFudHMv
e3ZhcmlhbnR9CiBwcm9kdWN0U3VpdGVzL3twcm9kdWN0X3N1aXRlfQoKDQoFBAkCAAUSBO8B
AggKDQoFBAkCAAESBO8BCRMKDQoFBAkCAAMSBO8BFhcKDQoFBAkCAAgSBO8BGEAKEAoIBAkC
AAicCAASBO8BGT8KMgoCBAoSBvMBAP8BARokIFJlc3BvbnNlIG1lc3NhZ2UgZm9yIExvb2t1
cEVudGl0eS4KCgsKAwQKARIE8wEIHAohCgQECggAEgb1AQL+AQMaESBNYXRjaGVkIGVudGl0
eS4KCg0KBQQKCAABEgT1AQgOCicKBAQKAgASBPcBBCcaGSBNYXRjaGVkIExvZ2ljYWxQcm9k
dWN0LgoKDQoFBAoCAAYSBPcBBBIKDQoFBAoCAAESBPcBEyIKDQoFBAoCAAMSBPcBJSYKLgoE
BAoCARIE+gEENhogIE1hdGNoZWQgTG9naWNhbFByb2R1Y3RWYXJpYW50LgoKDQoFBAoCAQYS
BPoBBBkKDQoFBAoCAQESBPoBGjEKDQoFBAoCAQMSBPoBNDUKJQoEBAoCAhIE/QEEIxoXIE1h
dGNoZWQgUHJvZHVjdFN1aXRlLgoKDQoFBAoCAgYSBP0BBBAKDQoFBAoCAgESBP0BER4KDQoF
BAoCAgMSBP0BISJiBnByb3RvMw==
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Productregistry::V1::CloudProductRegistryReadService::GetProductSuiteRequest ===
    # Fields for GetProductSuiteRequest
    # Field: name Type: 9 ()

# === Message: Google::Cloud::Productregistry::V1::CloudProductRegistryReadService::GetLogicalProductRequest ===
    # Fields for GetLogicalProductRequest
    # Field: name Type: 9 ()

# === Message: Google::Cloud::Productregistry::V1::CloudProductRegistryReadService::GetLogicalProductVariantRequest ===
    # Fields for GetLogicalProductVariantRequest
    # Field: name Type: 9 ()

# === Message: Google::Cloud::Productregistry::V1::CloudProductRegistryReadService::ListProductSuitesRequest ===
    # Fields for ListProductSuitesRequest
    # Field: page_size Type: 5 ()
    # Field: page_token Type: 9 ()

# === Message: Google::Cloud::Productregistry::V1::CloudProductRegistryReadService::ListProductSuitesResponse ===
    # Fields for ListProductSuitesResponse
    # Field: product_suites Type: 11 (.google.cloud.productregistry.v1.ProductSuite)
    # Field: next_page_token Type: 9 ()

# === Message: Google::Cloud::Productregistry::V1::CloudProductRegistryReadService::ListLogicalProductsRequest ===
    # Fields for ListLogicalProductsRequest
    # Field: filter Type: 9 ()
    # Field: page_size Type: 5 ()
    # Field: page_token Type: 9 ()

# === Message: Google::Cloud::Productregistry::V1::CloudProductRegistryReadService::ListLogicalProductsResponse ===
    # Fields for ListLogicalProductsResponse
    # Field: logical_products Type: 11 (.google.cloud.productregistry.v1.LogicalProduct)
    # Field: next_page_token Type: 9 ()

# === Message: Google::Cloud::Productregistry::V1::CloudProductRegistryReadService::ListLogicalProductVariantsRequest ===
    # Fields for ListLogicalProductVariantsRequest
    # Field: parent Type: 9 ()
    # Field: page_size Type: 5 ()
    # Field: page_token Type: 9 ()

# === Message: Google::Cloud::Productregistry::V1::CloudProductRegistryReadService::ListLogicalProductVariantsResponse ===
    # Fields for ListLogicalProductVariantsResponse
    # Field: logical_product_variants Type: 11 (.google.cloud.productregistry.v1.LogicalProductVariant)
    # Field: next_page_token Type: 9 ()

# === Message: Google::Cloud::Productregistry::V1::CloudProductRegistryReadService::LookupEntityRequest ===
    # Fields for LookupEntityRequest
    # Field: lookup_uri Type: 9 ()

# === Message: Google::Cloud::Productregistry::V1::CloudProductRegistryReadService::LookupEntityResponse ===
    # Fields for LookupEntityResponse
    # Field: logical_product Type: 11 (.google.cloud.productregistry.v1.LogicalProduct)
    # Field: logical_product_variant Type: 11 (.google.cloud.productregistry.v1.LogicalProductVariant)
    # Field: product_suite Type: 11 (.google.cloud.productregistry.v1.ProductSuite)

# === Service Client: Google::Cloud::Productregistry::V1::CloudProductRegistryReadService::CloudProductRegistryReadServiceClient ===
package Google::Cloud::Productregistry::V1::CloudProductRegistryReadService::CloudProductRegistryReadServiceClient;

=pod

=head2 Service Client: Google::Cloud::Productregistry::V1::CloudProductRegistryReadService::CloudProductRegistryReadServiceClient

Client stub representing the remote C<CloudProductRegistryReadService> gRPC service. Delegates call dispatching to L<Google::gRPC::Client>.

=head3 target

The endpoint target address. Defaults to C<productregistry.googleapis.com:443>.

=head3 credentials

The authentication credentials provider. Defaults to application default credentials via L<Google::Auth>.

=cut

use Moo;
use Google::Auth;
use Google::gRPC::Client;

has credentials => ( is => 'ro', default => sub { Google::Auth->default() } );
has target      => ( is => 'ro', default => 'productregistry.googleapis.com:443' );

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

sub get_product_suite {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Productregistry::V1::CloudProductRegistryReadService::GetProductSuiteRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.productregistry.v1.CloudProductRegistryReadService',
        method         => 'GetProductSuite',
        request        => $req,
        response_class => 'Google::Cloud::Productregistry::V1::ProductSuite::ProductSuite',
    });
}

sub list_product_suites {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Productregistry::V1::CloudProductRegistryReadService::ListProductSuitesRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.productregistry.v1.CloudProductRegistryReadService',
        method         => 'ListProductSuites',
        request        => $req,
        response_class => 'Google::Cloud::Productregistry::V1::CloudProductRegistryReadService::ListProductSuitesResponse',
    });
}

sub get_logical_product {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Productregistry::V1::CloudProductRegistryReadService::GetLogicalProductRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.productregistry.v1.CloudProductRegistryReadService',
        method         => 'GetLogicalProduct',
        request        => $req,
        response_class => 'Google::Cloud::Productregistry::V1::LogicalProduct::LogicalProduct',
    });
}

sub list_logical_products {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Productregistry::V1::CloudProductRegistryReadService::ListLogicalProductsRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.productregistry.v1.CloudProductRegistryReadService',
        method         => 'ListLogicalProducts',
        request        => $req,
        response_class => 'Google::Cloud::Productregistry::V1::CloudProductRegistryReadService::ListLogicalProductsResponse',
    });
}

sub get_logical_product_variant {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Productregistry::V1::CloudProductRegistryReadService::GetLogicalProductVariantRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.productregistry.v1.CloudProductRegistryReadService',
        method         => 'GetLogicalProductVariant',
        request        => $req,
        response_class => 'Google::Cloud::Productregistry::V1::LogicalProductVariant::LogicalProductVariant',
    });
}

sub list_logical_product_variants {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Productregistry::V1::CloudProductRegistryReadService::ListLogicalProductVariantsRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.productregistry.v1.CloudProductRegistryReadService',
        method         => 'ListLogicalProductVariants',
        request        => $req,
        response_class => 'Google::Cloud::Productregistry::V1::CloudProductRegistryReadService::ListLogicalProductVariantsResponse',
    });
}

sub lookup_entity {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Productregistry::V1::CloudProductRegistryReadService::LookupEntityRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.productregistry.v1.CloudProductRegistryReadService',
        method         => 'LookupEntity',
        request        => $req,
        response_class => 'Google::Cloud::Productregistry::V1::CloudProductRegistryReadService::LookupEntityResponse',
    });
}

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Productregistry::V1::CloudProductRegistryReadService - Compiled Protocol Buffers messages for google/cloud/productregistry/v1/cloud_product_registry_read_service.proto

=head1 SYNOPSIS

    use Google::Cloud::Productregistry::V1::CloudProductRegistryReadService;

    my $msg = Google::Cloud::Productregistry::V1::CloudProductRegistryReadService::GetProductSuiteRequest->new({
        name => $name,
    });

    # Read or update a field
    my $val = $msg->name();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Productregistry::V1::CloudProductRegistryReadService::GetProductSuiteRequest->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/productregistry/v1/cloud_product_registry_read_service.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Productregistry::V1::CloudProductRegistryReadService::GetProductSuiteRequest

Request message for GetProductSuite.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. The name of the ProductSuite to retrieve.
Format: productSuites/{product_suite}

=back

=head2 Google::Cloud::Productregistry::V1::CloudProductRegistryReadService::GetLogicalProductRequest

Request message for GetLogicalProduct.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. The name of the LogicalProduct to retrieve.
Format: logicalProducts/{logical_product}

=back

=head2 Google::Cloud::Productregistry::V1::CloudProductRegistryReadService::GetLogicalProductVariantRequest

Request message for GetLogicalProductVariant.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. The name of the LogicalProductVariant to retrieve.
Format: logicalProducts/{logical_product}/variants/{variant}

=back

=head2 Google::Cloud::Productregistry::V1::CloudProductRegistryReadService::ListProductSuitesRequest

Request message for ListProductSuites.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->page_size() >> / C<< $msg->page_size($value) >>

Type: C<Int32>

Optional. The maximum number of suites to return. The service may return
fewer than this value. If unspecified, at most 100 suites will be returned.
The maximum value is 500; values above 500 will be coerced to 500.

=item * C<< $msg->page_token() >> / C<< $msg->page_token($value) >>

Type: C<String>

Optional. A page token, received from a previous `ListProductSuites` call.
Provide this to retrieve the subsequent page.

When paginating, all other parameters provided to `ListProductSuites` must
match the call that provided the page token.

=back

=head2 Google::Cloud::Productregistry::V1::CloudProductRegistryReadService::ListProductSuitesResponse

Response message for ListProductSuites.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->product_suites() >> / C<< $msg->product_suites($value) >>

Type: C<Message> (L<Google::Cloud::Productregistry::V1::ProductSuite::ProductSuite>)

Matched ProductSuites

=item * C<< $msg->next_page_token() >> / C<< $msg->next_page_token($value) >>

Type: C<String>

A token, which can be sent as `page_token` to retrieve the next page.
If this field is omitted, there are no subsequent pages.

=back

=head2 Google::Cloud::Productregistry::V1::CloudProductRegistryReadService::ListLogicalProductsRequest

Request message for ListLogicalProducts.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->filter() >> / C<< $msg->filter($value) >>

Type: C<String>

Optional. The filter expression for listing logical products.
Filter syntax: https://google.aip.dev/160
Supported fields: suite_id

=item * C<< $msg->page_size() >> / C<< $msg->page_size($value) >>

Type: C<Int32>

Optional. The maximum number of logical products to return. The service may
return fewer than this value. If unspecified, at most 100 logical products
will be returned. The maximum value is 500; values above 500 will be
coerced to 500.

=item * C<< $msg->page_token() >> / C<< $msg->page_token($value) >>

Type: C<String>

Optional. A page token, received from a previous `ListLogicalProducts`
call. Provide this to retrieve the subsequent page.

When paginating, all other parameters provided to `ListLogicalProducts`
must match the call that provided the page token.

=back

=head2 Google::Cloud::Productregistry::V1::CloudProductRegistryReadService::ListLogicalProductsResponse

Response message for ListLogicalProducts.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->logical_products() >> / C<< $msg->logical_products($value) >>

Type: C<Message> (L<Google::Cloud::Productregistry::V1::LogicalProduct::LogicalProduct>)

Matched LogicalProducts

=item * C<< $msg->next_page_token() >> / C<< $msg->next_page_token($value) >>

Type: C<String>

A token, which can be sent as `page_token` to retrieve the next page.
If this field is omitted, there are no subsequent pages.

=back

=head2 Google::Cloud::Productregistry::V1::CloudProductRegistryReadService::ListLogicalProductVariantsRequest

Request message for ListLogicalProductVariants.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->parent() >> / C<< $msg->parent($value) >>

Type: C<String>

Required. Parent logical product id.
Format: logicalProducts/{logical_product}

=item * C<< $msg->page_size() >> / C<< $msg->page_size($value) >>

Type: C<Int32>

Optional. The maximum number of logical product variants to return. The
service may return fewer than this value. If unspecified, at most 100
logical product variants will be returned. The maximum value is 500; values
above 500 will be coerced to 500.

=item * C<< $msg->page_token() >> / C<< $msg->page_token($value) >>

Type: C<String>

Optional. A page token, received from a previous
`ListLogicalProductVariants` call. Provide this to retrieve the subsequent
page.

When paginating, all other parameters provided to
`ListLogicalProductVariants` must match the call that provided the page
token.

=back

=head2 Google::Cloud::Productregistry::V1::CloudProductRegistryReadService::ListLogicalProductVariantsResponse

Response message for ListLogicalProductVariants.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->logical_product_variants() >> / C<< $msg->logical_product_variants($value) >>

Type: C<Message> (L<Google::Cloud::Productregistry::V1::LogicalProductVariant::LogicalProductVariant>)

Matched LogicalProductVariants

=item * C<< $msg->next_page_token() >> / C<< $msg->next_page_token($value) >>

Type: C<String>

A token, which can be sent as `page_token` to retrieve the next page.
If this field is omitted, there are no subsequent pages.

=back

=head2 Google::Cloud::Productregistry::V1::CloudProductRegistryReadService::LookupEntityRequest

Request message for LookupEntity.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->lookup_uri() >> / C<< $msg->lookup_uri($value) >>

Type: C<String>

Required. Entity uri to look up.
Supported Formats:
logicalProducts/{logical_product}
logicalProducts/{logical_product}/variants/{variant}
productSuites/{product_suite}

=back

=head2 Google::Cloud::Productregistry::V1::CloudProductRegistryReadService::LookupEntityResponse

Response message for LookupEntity.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->logical_product() >> / C<< $msg->logical_product($value) >>

Type: C<Message> (L<Google::Cloud::Productregistry::V1::LogicalProduct::LogicalProduct>)

Matched LogicalProduct.

=item * C<< $msg->logical_product_variant() >> / C<< $msg->logical_product_variant($value) >>

Type: C<Message> (L<Google::Cloud::Productregistry::V1::LogicalProductVariant::LogicalProductVariant>)

Matched LogicalProductVariant.

=item * C<< $msg->product_suite() >> / C<< $msg->product_suite($value) >>

Type: C<Message> (L<Google::Cloud::Productregistry::V1::ProductSuite::ProductSuite>)

Matched ProductSuite.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Productregistry::V1::CloudProductRegistryReadService::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
