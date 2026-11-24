package Google::Cloud::Commerceproducer::V1beta::StandardOffer;

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
    eval { require Google::Protobuf::Timestamp };
    my $descriptor_b64 = <<'EOF';
Cjlnb29nbGUvY2xvdWQvY29tbWVyY2Vwcm9kdWNlci92MWJldGEvc3RhbmRhcmRfb2ZmZXIu
cHJvdG8SJGdvb2dsZS5jbG91ZC5jb21tZXJjZXByb2R1Y2VyLnYxYmV0YRofZ29vZ2xlL2Fw
aS9maWVsZF9iZWhhdmlvci5wcm90bxoZZ29vZ2xlL2FwaS9yZXNvdXJjZS5wcm90bxofZ29v
Z2xlL3Byb3RvYnVmL3RpbWVzdGFtcC5wcm90byLcCwoNU3RhbmRhcmRPZmZlchI3ChR0ZXJt
X2R1cmF0aW9uX21vbnRocxgHIAEoBUID4EEDSABSEnRlcm1EdXJhdGlvbk1vbnRocxIXCgRu
YW1lGAEgASgJQgPgQQhSBG5hbWUSQAoLY3JlYXRlX3RpbWUYAiABKAsyGi5nb29nbGUucHJv
dG9idWYuVGltZXN0YW1wQgPgQQNSCmNyZWF0ZVRpbWUSQAoLdXBkYXRlX3RpbWUYAyABKAsy
Gi5nb29nbGUucHJvdG9idWYuVGltZXN0YW1wQgPgQQNSCnVwZGF0ZVRpbWUSRgoOZWZmZWN0
aXZlX3RpbWUYBCABKAsyGi5nb29nbGUucHJvdG9idWYuVGltZXN0YW1wQgPgQQNSDWVmZmVj
dGl2ZVRpbWUSQAoLZXhwaXJlX3RpbWUYBSABKAsyGi5nb29nbGUucHJvdG9idWYuVGltZXN0
YW1wQgPgQQNSCmV4cGlyZVRpbWUSKAoNc2VydmljZV9sZXZlbBgGIAEoCUID4EEDUgxzZXJ2
aWNlTGV2ZWwSMwoTc2VydmljZV9sZXZlbF90aXRsZRgJIAEoCUID4EEDUhFzZXJ2aWNlTGV2
ZWxUaXRsZRJkCgtwcmljZV9tb2RlbBgIIAEoCzI+Lmdvb2dsZS5jbG91ZC5jb21tZXJjZXBy
b2R1Y2VyLnYxYmV0YS5TdGFuZGFyZE9mZmVyLlByaWNlTW9kZWxCA+BBA1IKcHJpY2VNb2Rl
bBrsBQoKUHJpY2VNb2RlbBJ0CghmbGF0X2ZlZRgCIAEoCzJSLmdvb2dsZS5jbG91ZC5jb21t
ZXJjZXByb2R1Y2VyLnYxYmV0YS5TdGFuZGFyZE9mZmVyLlByaWNlTW9kZWwuRmxhdEZlZVN1
YnNjcmlwdGlvbkID4EEDSABSB2ZsYXRGZWUSXwoFdXNhZ2UYASABKAsyRC5nb29nbGUuY2xv
dWQuY29tbWVyY2Vwcm9kdWNlci52MWJldGEuU3RhbmRhcmRPZmZlci5QcmljZU1vZGVsLlVz
YWdlQgPgQQNSBXVzYWdlGkoKB1NrdUxpc3QSPwoEc2t1cxgBIAMoCUIr4EED+kElCiNjb21t
ZXJjZXByb2R1Y2VyLmdvb2dsZWFwaXMuY29tL1NrdVIEc2t1cxpfCgxTa3VHcm91cExpc3QS
TwoKc2t1X2dyb3VwcxgBIAMoCUIw4EED+kEqCihjb21tZXJjZXByb2R1Y2VyLmdvb2dsZWFw
aXMuY29tL1NrdUdyb3VwUglza3VHcm91cHMa8wEKBVVzYWdlEmgKCHNrdV9saXN0GAEgASgL
MkYuZ29vZ2xlLmNsb3VkLmNvbW1lcmNlcHJvZHVjZXIudjFiZXRhLlN0YW5kYXJkT2ZmZXIu
UHJpY2VNb2RlbC5Ta3VMaXN0QgPgQQNIAFIHc2t1TGlzdBJ4Cg5za3VfZ3JvdXBfbGlzdBgC
IAEoCzJLLmdvb2dsZS5jbG91ZC5jb21tZXJjZXByb2R1Y2VyLnYxYmV0YS5TdGFuZGFyZE9m
ZmVyLlByaWNlTW9kZWwuU2t1R3JvdXBMaXN0QgPgQQNIAFIMc2t1R3JvdXBMaXN0QgYKBHNr
dXMaVAoTRmxhdEZlZVN1YnNjcmlwdGlvbhI9CgNza3UYASABKAlCK+BBA/pBJQojY29tbWVy
Y2Vwcm9kdWNlci5nb29nbGVhcGlzLmNvbS9Ta3VSA3NrdUIOCgxzdWJzY3JpcHRpb246rgHq
QaoBCi1jb21tZXJjZXByb2R1Y2VyLmdvb2dsZWFwaXMuY29tL1N0YW5kYXJkT2ZmZXISWnBy
b2plY3RzL3twcm9qZWN0fS9sb2NhdGlvbnMve2xvY2F0aW9ufS9zZXJ2aWNlcy97c2Vydmlj
ZX0vc3RhbmRhcmRPZmZlcnMve3N0YW5kYXJkX29mZmVyfSoOc3RhbmRhcmRPZmZlcnMyDXN0
YW5kYXJkT2ZmZXJCBgoEdGVybUKOAgooY29tLmdvb2dsZS5jbG91ZC5jb21tZXJjZXByb2R1
Y2VyLnYxYmV0YUISU3RhbmRhcmRPZmZlclByb3RvUAFaVGNsb3VkLmdvb2dsZS5jb20vZ28v
Y29tbWVyY2Vwcm9kdWNlci9hcGl2MWJldGEvY29tbWVyY2Vwcm9kdWNlcnBiO2NvbW1lcmNl
cHJvZHVjZXJwYqoCJEdvb2dsZS5DbG91ZC5Db21tZXJjZVByb2R1Y2VyLlYxQmV0YcoCJEdv
b2dsZVxDbG91ZFxDb21tZXJjZVByb2R1Y2VyXFYxYmV0YeoCJ0dvb2dsZTo6Q2xvdWQ6OkNv
bW1lcmNlUHJvZHVjZXI6OlYxYmV0YUrlJQoHEgUOAJcBAQq8BAoBDBIDDgASMrEEIENvcHly
aWdodCAyMDI2IEdvb2dsZSBMTEMKCiBMaWNlbnNlZCB1bmRlciB0aGUgQXBhY2hlIExpY2Vu
c2UsIFZlcnNpb24gMi4wICh0aGUgIkxpY2Vuc2UiKTsKIHlvdSBtYXkgbm90IHVzZSB0aGlz
IGZpbGUgZXhjZXB0IGluIGNvbXBsaWFuY2Ugd2l0aCB0aGUgTGljZW5zZS4KIFlvdSBtYXkg
b2J0YWluIGEgY29weSBvZiB0aGUgTGljZW5zZSBhdAoKICAgICBodHRwOi8vd3d3LmFwYWNo
ZS5vcmcvbGljZW5zZXMvTElDRU5TRS0yLjAKCiBVbmxlc3MgcmVxdWlyZWQgYnkgYXBwbGlj
YWJsZSBsYXcgb3IgYWdyZWVkIHRvIGluIHdyaXRpbmcsIHNvZnR3YXJlCiBkaXN0cmlidXRl
ZCB1bmRlciB0aGUgTGljZW5zZSBpcyBkaXN0cmlidXRlZCBvbiBhbiAiQVMgSVMiIEJBU0lT
LAogV0lUSE9VVCBXQVJSQU5USUVTIE9SIENPTkRJVElPTlMgT0YgQU5ZIEtJTkQsIGVpdGhl
ciBleHByZXNzIG9yIGltcGxpZWQuCiBTZWUgdGhlIExpY2Vuc2UgZm9yIHRoZSBzcGVjaWZp
YyBsYW5ndWFnZSBnb3Zlcm5pbmcgcGVybWlzc2lvbnMgYW5kCiBsaW1pdGF0aW9ucyB1bmRl
ciB0aGUgTGljZW5zZS4KCggKAQISAxAALQoJCgIDABIDEgApCgkKAgMBEgMTACMKCQoCAwIS
AxQAKQoICgEIEgMWAEEKCQoCCCUSAxYAQQoICgEIEgMXAGsKCQoCCAsSAxcAawoICgEIEgMY
ACIKCQoCCAoSAxgAIgoICgEIEgMZADMKCQoCCAgSAxkAMwoICgEIEgMaAEEKCQoCCAESAxoA
QQoICgEIEgMbAEEKCQoCCCkSAxsAQQoICgEIEgMcAEAKCQoCCC0SAxwAQAo9CgIEABIFHwCX
AQEaMCBNZXNzYWdlIGRlc2NyaWJpbmcgdGhlIFN0YW5kYXJkT2ZmZXIgcmVzb3VyY2UuCgoK
CgMEAAESAx8IFQoLCgMEAAcSBCACJQQKDQoFBAAHnQgSBCACJQQKKQoEBAADABIEKAJhAxob
IFByaWNlIG1vZGVsIG9mIHRoZSBvZmZlci4KCgwKBQQAAwABEgMoChQKJwoGBAADAAMAEgQq
BDIFGhcgQSBjb2xsZWN0aW9uIG9mIFNLVXMuCgoOCgcEAAMAAwABEgMqDBMKNgoIBAADAAMA
AgASBCwGMQgaJCBPdXRwdXQgb25seS4gTGlzdCBvZiBTS1VzIGJ5IG5hbWUuCgoQCgkEAAMA
AwACAAQSAywGDgoQCgkEAAMAAwACAAUSAywPFQoQCgkEAAMAAwACAAESAywWGgoQCgkEAAMA
AwACAAMSAywdHgoRCgkEAAMAAwACAAgSBCwfMQcKEwoMBAADAAMAAgAInAgAEgMtCDEKEwoL
BAADAAMAAgAInwgSBC4IMAkKLAoGBAADAAMBEgQ1BD0FGhwgQSBjb2xsZWN0aW9uIG9mIFNr
dUdyb3Vwcy4KCg4KBwQAAwADAQESAzUMGAo7CggEAAMAAwECABIENwY8CBopIE91dHB1dCBv
bmx5LiBMaXN0IG9mIFNrdUdyb3VwcyBieSBuYW1lLgoKEAoJBAADAAMBAgAEEgM3Bg4KEAoJ
BAADAAMBAgAFEgM3DxUKEAoJBAADAAMBAgABEgM3FiAKEAoJBAADAAMBAgADEgM3IyQKEQoJ
BAADAAMBAgAIEgQ3JTwHChMKDAQAAwADAQIACJwIABIDOAgxChMKCwQAAwADAQIACJ8IEgQ5
CDsJCjoKBgQAAwADAhIEQARLBRoqIFByaWNlIGNvbmZpZ3VyYXRpb25zIGZvciB0aGUgdXNh
Z2UgcGFydC4KCg4KBwQAAwADAgESA0AMEQpNCggEAAMAAwIIABIEQgZKBxo7IFRoZSBTS1Vz
IHRoYXQgdGhlIG9mZmVyJ3MgdXNhZ2UgZmVlcyBhcmUgY2hhcmdlZCBhZ2FpbnN0LgoKEAoJ
BAADAAMCCAABEgNCDBAKVgoIBAADAAMCAgASA0QISRpFIE91dHB1dCBvbmx5LiBUaGUgb2Zm
ZXIncyB1c2FnZSBmZWVzIGFyZSBjaGFyZ2VkIGFnYWluc3QgdGhlc2UgU0tVcy4KChAKCQQA
AwADAgIABhIDRAgPChAKCQQAAwADAgIAARIDRBAYChAKCQQAAwADAgIAAxIDRBscChAKCQQA
AwADAgIACBIDRB1IChMKDAQAAwADAgIACJwIABIDRB5HCmYKCAQAAwADAgIBEgRICEk4GlQg
T3V0cHV0IG9ubHkuIFRoZSBvZmZlcidzIHVzYWdlIGZlZXMgYXJlIGNoYXJnZWQgYWdhaW5z
dCB0aGUgU0tVcyBpbgogdGhlc2UgZ3JvdXBzLgoKEAoJBAADAAMCAgEGEgNICBQKEAoJBAAD
AAMCAgEBEgNIFSMKEAoJBAADAAMCAgEDEgNIJicKEAoJBAADAAMCAgEIEgNJDDcKEwoMBAAD
AAMCAgEInAgAEgNJDTYKQgoGBAADAAMDEgROBFYFGjIgUHJpY2UgY29uZmlndXJhdGlvbnMg
Zm9yIGZsYXQgZmVlIHN1YnNjcmlwdGlvbnMuCgoOCgcEAAMAAwMBEgNODB8KSQoIBAADAAMD
AgASBFAGVQgaNyBPdXRwdXQgb25seS4gRmxhdCBmZWUgc3Vic2NyaXB0aW9uIFNLVSBmb3Ig
dGhlIG9mZmVyLgoKEAoJBAADAAMDAgAFEgNQBgwKEAoJBAADAAMDAgABEgNQDRAKEAoJBAAD
AAMDAgADEgNQExQKEQoJBAADAAMDAgAIEgRQFVUHChMKDAQAAwADAwIACJwIABIDUQgxChMK
CwQAAwADAwIACJ8IEgRSCFQJCkEKBgQAAwAIABIEWQRdBRoxIFByaWNlIGNvbmZpZ3VyYXRp
b25zIGZvciB0aGUgc3Vic2NyaXB0aW9uIHBhcnQuCgoOCgcEAAMACAABEgNZChYKUgoGBAAD
AAIAEgRbBlw2GkIgT3V0cHV0IG9ubHkuIFByaWNlIGNvbmZpZ3VyYXRpb25zIGZvciB0aGUg
ZmxhdCBmZWUgc3Vic2NyaXB0aW9uLgoKDgoHBAADAAIABhIDWwYZCg4KBwQAAwACAAESA1sa
IgoOCgcEAAMAAgADEgNbJSYKDgoHBAADAAIACBIDXAo1ChEKCgQAAwACAAicCAASA1wLNApG
CgYEAAMAAgESA2AEQBo3IE91dHB1dCBvbmx5LiBQcmljZSBjb25maWd1cmF0aW9ucyBmb3Ig
dGhlIHVzYWdlIHBhcnQuCgoOCgcEAAMAAgEGEgNgBAkKDgoHBAADAAIBARIDYAoPCg4KBwQA
AwACAQMSA2ASEwoOCgcEAAMAAgEIEgNgFD8KEQoKBAADAAIBCJwIABIDYBU+CksKBAQACAAS
BGUCagMaPSBUZXJtIG9mIHRoZSBvZmZlci4KIEFwcGxpY2FibGUgb25seSB0byBzdWJzY3Jp
cHRpb24gb2ZmZXJzLgoKDAoFBAAIAAESA2UIDAq6AQoEBAACABIDaQRPGqwBIE91dHB1dCBv
bmx5LiBUZXJtIGR1cmF0aW9uIG9mIHRoZSBvZmZlciBpbiBtb250aHMuCiBBcHBsaWNhYmxl
IG9ubHkgdG8gb2ZmZXJzIHdpdGggYSBzdWJzY3JpcHRpb24gcHJpY2UgbW9kZWwuCiBBZGRp
dGlvbmFsIGZvcm1zIG9mIG9mZmVyIHRlcm0gbWF5IGJlIGFkZGVkIGluIHRoZSBmdXR1cmUu
CgoMCgUEAAIABRIDaQQJCgwKBQQAAgABEgNpCh4KDAoFBAACAAMSA2khIgoMCgUEAAIACBID
aSNOCg8KCAQAAgAInAgAEgNpJE0KLAoEBAACARIDbQI9Gh8gSWRlbnRpZmllci4gTmFtZSBv
ZiByZXNvdXJjZS4KCgwKBQQAAgEFEgNtAggKDAoFBAACAQESA20JDQoMCgUEAAIBAxIDbRAR
CgwKBQQAAgEIEgNtEjwKDwoIBAACAQicCAASA20TOwo4CgQEAAICEgRwAnEyGiogT3V0cHV0
IG9ubHkuIENyZWF0aW9uIHRpbWUgb2YgdGhlIG9mZmVyLgoKDAoFBAACAgYSA3ACGwoMCgUE
AAICARIDcBwnCgwKBQQAAgIDEgNwKisKDAoFBAACAggSA3EGMQoPCggEAAICCJwIABIDcQcw
CjsKBAQAAgMSBHQCdTIaLSBPdXRwdXQgb25seS4gTGFzdCB1cGRhdGUgdGltZSBvZiB0aGUg
b2ZmZXIuCgoMCgUEAAIDBhIDdAIbCgwKBQQAAgMBEgN0HCcKDAoFBAACAwMSA3QqKwoMCgUE
AAIDCBIDdQYxCg8KCAQAAgMInAgAEgN1BzAKpQEKBAQAAgQSBHoCezIalgEgT3V0cHV0IG9u
bHkuIEVmZmVjdGl2ZSB0aW1lIG9mIHRoZSBvZmZlci4KIFByaW9yIHRvIHRoaXMgdGltZSwg
dGhlIG9mZmVyIGNhbm5vdCBiZSBwdXJjaGFzZWQgb3IgdXNlZCBhcyB0aGUgYmFzZQogc3Rh
bmRhcmQgb2ZmZXIgb2YgYSBwcml2YXRlIG9mZmVyLgoKDAoFBAACBAYSA3oCGwoMCgUEAAIE
ARIDehwqCgwKBQQAAgQDEgN6LS4KDAoFBAACBAgSA3sGMQoPCggEAAIECJwIABIDewcwCtgB
CgQEAAIFEgaBAQKCATIaxwEgT3V0cHV0IG9ubHkuIEV4cGlyZSB0aW1lIG9mIHRoZSBvZmZl
ci4KIEFuIG9mZmVyIGlzIGV4cGlyZWQgaWYgaXRzIGV4cGlyZSB0aW1lIGlzIGluIHRoZSBw
YXN0LgogQW4gZXhwaXJlZCBzdGFuZGFyZCBvZmZlciBjYW5ub3QgYmUgcHVyY2hhc2VkIG9y
IHVzZWQgYXMgdGhlIGJhc2Ugc3RhbmRhcmQKIG9mZmVyIG9mIGEgcHJpdmF0ZSBvZmZlci4K
Cg0KBQQAAgUGEgSBAQIbCg0KBQQAAgUBEgSBARwnCg0KBQQAAgUDEgSBASorCg0KBQQAAgUI
EgSCAQYxChAKCAQAAgUInAgAEgSCAQcwCvEDCgQEAAIGEgSOAQJHGuIDIE91dHB1dCBvbmx5
LiBJZGVudGlmaWVyIHRoYXQgZGlzdGluZ3Vpc2hlcyBiZXR3ZWVuIGRpZmZlcmVudCBzZXJ2
aWNlIGxldmVscwogb2YgdGhlIHNhbWUgcHJvZHVjdCB0aGF0IGNvbnN0aXR1dGUgZGlzdGlu
Y3Qgb2ZmZXJpbmdzIHRvIGN1c3RvbWVycyB3aXRoCiBkaWZmZXJlbnQgcHJpY2luZy4KCiBU
aGUgc2VydmljZSBsZXZlbHMgb2YgYSBwcm9kdWN0IGFyZSBhbHNvIHJlZmVycmVkIHRvIGlu
IHNvbWUgY2FzZXMgYXMgdGhlCiBwcm9kdWN0J3MgJ3BsYW5zJywgYW5kIHRoZSBgc2Vydmlj
ZV9sZXZlbGAgdmFsdWUgaXMgcmVmZXJyZWQgdG8gaW4gc29tZQogY2FzZXMgYXMgdGhlICJw
bGFuIElEIi4KCiBNdWx0aXBsZSBub24tZXhwaXJlZCBzdGFuZGFyZCBvZmZlcnMgY2FuIHNo
YXJlIHRoZSBzYW1lIHNlcnZpY2UgbGV2ZWwgd2hlbgogdGhleSBhcmUgc3Vic2NyaXB0aW9u
IG9mZmVycyBmb3IgZGlmZmVyZW50IHRlcm0gZHVyYXRpb25zLgoKDQoFBAACBgUSBI4BAggK
DQoFBAACBgESBI4BCRYKDQoFBAACBgMSBI4BGRoKDQoFBAACBggSBI4BG0YKEAoIBAACBgic
CAASBI4BHEUKaAoEBAACBxIEkwECTRpaIE91dHB1dCBvbmx5LiBUaXRsZSBvZiB0aGUgc2Vy
dmljZSBsZXZlbC4KCiBOb3QgaW5jbHVkZWQgZm9yIGBTVEFOREFSRF9PRkZFUl9WSUVXX0JB
U0lDYC4KCg0KBQQAAgcFEgSTAQIICg0KBQQAAgcBEgSTAQkcCg0KBQQAAgcDEgSTAR8gCg0K
BQQAAgcIEgSTASFMChAKCAQAAgcInAgAEgSTASJLCjYKBAQAAggSBJYBAkkaKCBPdXRwdXQg
b25seS4gUHJpY2UgbW9kZWwgb2YgdGhlIG9mZmVyLgoKDQoFBAACCAYSBJYBAgwKDQoFBAAC
CAESBJYBDRgKDQoFBAACCAMSBJYBGxwKDQoFBAACCAgSBJYBHUgKEAoIBAACCAicCAASBJYB
HkdiBnByb3RvMw==
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Commerceproducer::V1beta::StandardOffer::StandardOffer ===
    # Fields for StandardOffer
    # Field: term_duration_months Type: 5 ()
    # Field: name Type: 9 ()
    # Field: create_time Type: 11 (.google.protobuf.Timestamp)
    # Field: update_time Type: 11 (.google.protobuf.Timestamp)
    # Field: effective_time Type: 11 (.google.protobuf.Timestamp)
    # Field: expire_time Type: 11 (.google.protobuf.Timestamp)
    # Field: service_level Type: 9 ()
    # Field: service_level_title Type: 9 ()
    # Field: price_model Type: 11 (.google.cloud.commerceproducer.v1beta.StandardOffer.PriceModel)

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Commerceproducer::V1beta::StandardOffer - Compiled Protocol Buffers messages for google/cloud/commerceproducer/v1beta/standard_offer.proto

=head1 SYNOPSIS

    use Google::Cloud::Commerceproducer::V1beta::StandardOffer;

    my $msg = Google::Cloud::Commerceproducer::V1beta::StandardOffer::StandardOffer->new({
        term_duration_months => $term_duration_months,
        name => $name,
        create_time => $create_time,
        update_time => $update_time,
    });

    # Read or update a field
    my $val = $msg->term_duration_months();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Commerceproducer::V1beta::StandardOffer::StandardOffer->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/commerceproducer/v1beta/standard_offer.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Commerceproducer::V1beta::StandardOffer::StandardOffer

Message describing the StandardOffer resource.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->term_duration_months() >> / C<< $msg->term_duration_months($value) >>

Type: C<Int32>

Output only. Term duration of the offer in months.
Applicable only to offers with a subscription price model.
Additional forms of offer term may be added in the future.

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Identifier. Name of resource.

=item * C<< $msg->create_time() >> / C<< $msg->create_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Output only. Creation time of the offer.

=item * C<< $msg->update_time() >> / C<< $msg->update_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Output only. Last update time of the offer.

=item * C<< $msg->effective_time() >> / C<< $msg->effective_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Output only. Effective time of the offer.
Prior to this time, the offer cannot be purchased or used as the base
standard offer of a private offer.

=item * C<< $msg->expire_time() >> / C<< $msg->expire_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Output only. Expire time of the offer.
An offer is expired if its expire time is in the past.
An expired standard offer cannot be purchased or used as the base standard
offer of a private offer.

=item * C<< $msg->service_level() >> / C<< $msg->service_level($value) >>

Type: C<String>

Output only. Identifier that distinguishes between different service levels
of the same product that constitute distinct offerings to customers with
different pricing.

The service levels of a product are also referred to in some cases as the
product's 'plans', and the `service_level` value is referred to in some
cases as the "plan ID".

Multiple non-expired standard offers can share the same service level when
they are subscription offers for different term durations.

=item * C<< $msg->service_level_title() >> / C<< $msg->service_level_title($value) >>

Type: C<String>

Output only. Title of the service level.

Not included for `STANDARD_OFFER_VIEW_BASIC`.

=item * C<< $msg->price_model() >> / C<< $msg->price_model($value) >>

Type: C<Message> (L<Google::Cloud::Commerceproducer::V1beta::StandardOffer::StandardOffer::PriceModel>)

Output only. Price model of the offer.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Commerceproducer::V1beta::StandardOffer::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
