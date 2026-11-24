package Google::Cloud::Run::V2::Build;

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
    eval { require Google::Api::LaunchStage };
    eval { require Google::Api::Resource };
    eval { require Google::Longrunning::Operations };
    my $descriptor_b64 = <<'EOF';
Ch9nb29nbGUvY2xvdWQvcnVuL3YyL2J1aWxkLnByb3RvEhNnb29nbGUuY2xvdWQucnVuLnYy
Ghxnb29nbGUvYXBpL2Fubm90YXRpb25zLnByb3RvGhdnb29nbGUvYXBpL2NsaWVudC5wcm90
bxofZ29vZ2xlL2FwaS9maWVsZF9iZWhhdmlvci5wcm90bxodZ29vZ2xlL2FwaS9sYXVuY2hf
c3RhZ2UucHJvdG8aGWdvb2dsZS9hcGkvcmVzb3VyY2UucHJvdG8aI2dvb2dsZS9sb25ncnVu
bmluZy9vcGVyYXRpb25zLnByb3RvIqgJChJTdWJtaXRCdWlsZFJlcXVlc3QSGwoGcGFyZW50
GAEgASgJQgPgQQJSBnBhcmVudBJQCg5zdG9yYWdlX3NvdXJjZRgCIAEoCzIiLmdvb2dsZS5j
bG91ZC5ydW4udjIuU3RvcmFnZVNvdXJjZUID4EECSABSDXN0b3JhZ2VTb3VyY2USIAoJaW1h
Z2VfdXJpGAMgASgJQgPgQQJSCGltYWdlVXJpEmIKD2J1aWxkcGFja19idWlsZBgEIAEoCzI3
Lmdvb2dsZS5jbG91ZC5ydW4udjIuU3VibWl0QnVpbGRSZXF1ZXN0LkJ1aWxkcGFja3NCdWls
ZEgBUg5idWlsZHBhY2tCdWlsZBJYCgxkb2NrZXJfYnVpbGQYBSABKAsyMy5nb29nbGUuY2xv
dWQucnVuLnYyLlN1Ym1pdEJ1aWxkUmVxdWVzdC5Eb2NrZXJCdWlsZEgBUgtkb2NrZXJCdWls
ZBIsCg9zZXJ2aWNlX2FjY291bnQYBiABKAlCA+BBAVIOc2VydmljZUFjY291bnQSUgoLd29y
a2VyX3Bvb2wYByABKAlCMeBBAfpBKwopY2xvdWRidWlsZC5nb29nbGVhcGlzLmNvbS9CdWls
ZFdvcmtlclBvb2xSCndvcmtlclBvb2wSFwoEdGFncxgIIAMoCUID4EEBUgR0YWdzEiYKDG1h
Y2hpbmVfdHlwZRgJIAEoCUID4EEBUgttYWNoaW5lVHlwZRJBCg1yZWxlYXNlX3RyYWNrGAog
ASgOMhcuZ29vZ2xlLmFwaS5MYXVuY2hTdGFnZUID4EEBUgxyZWxlYXNlVHJhY2sSGwoGY2xp
ZW50GAsgASgJQgPgQQFSBmNsaWVudBoNCgtEb2NrZXJCdWlsZBr4AwoPQnVpbGRwYWNrc0J1
aWxkEhwKB3J1bnRpbWUYASABKAlCAhgBUgdydW50aW1lEiwKD2Z1bmN0aW9uX3RhcmdldBgC
IAEoCUID4EEBUg5mdW5jdGlvblRhcmdldBIrCg9jYWNoZV9pbWFnZV91cmkYAyABKAlCA+BB
AVINY2FjaGVJbWFnZVVyaRIiCgpiYXNlX2ltYWdlGAQgASgJQgPgQQFSCWJhc2VJbWFnZRKL
AQoVZW52aXJvbm1lbnRfdmFyaWFibGVzGAUgAygLMlEuZ29vZ2xlLmNsb3VkLnJ1bi52Mi5T
dWJtaXRCdWlsZFJlcXVlc3QuQnVpbGRwYWNrc0J1aWxkLkVudmlyb25tZW50VmFyaWFibGVz
RW50cnlCA+BBAVIUZW52aXJvbm1lbnRWYXJpYWJsZXMSPQoYZW5hYmxlX2F1dG9tYXRpY191
cGRhdGVzGAYgASgIQgPgQQFSFmVuYWJsZUF1dG9tYXRpY1VwZGF0ZXMSMgoScHJvamVjdF9k
ZXNjcmlwdG9yGAcgASgJQgPgQQFSEXByb2plY3REZXNjcmlwdG9yGkcKGUVudmlyb25tZW50
VmFyaWFibGVzRW50cnkSEAoDa2V5GAEgASgJUgNrZXkSFAoFdmFsdWUYAiABKAlSBXZhbHVl
OgI4AUIICgZzb3VyY2VCDAoKYnVpbGRfdHlwZSKxAQoTU3VibWl0QnVpbGRSZXNwb25zZRJG
Cg9idWlsZF9vcGVyYXRpb24YASABKAsyHS5nb29nbGUubG9uZ3J1bm5pbmcuT3BlcmF0aW9u
Ug5idWlsZE9wZXJhdGlvbhIkCg5iYXNlX2ltYWdlX3VyaRgCIAEoCVIMYmFzZUltYWdlVXJp
EiwKEmJhc2VfaW1hZ2Vfd2FybmluZxgDIAEoCVIQYmFzZUltYWdlV2FybmluZyJuCg1TdG9y
YWdlU291cmNlEhsKBmJ1Y2tldBgBIAEoCUID4EECUgZidWNrZXQSGwoGb2JqZWN0GAIgASgJ
QgPgQQJSBm9iamVjdBIjCgpnZW5lcmF0aW9uGAMgASgDQgPgQQFSCmdlbmVyYXRpb24ylQIK
BkJ1aWxkcxKeAQoLU3VibWl0QnVpbGQSJy5nb29nbGUuY2xvdWQucnVuLnYyLlN1Ym1pdEJ1
aWxkUmVxdWVzdBooLmdvb2dsZS5jbG91ZC5ydW4udjIuU3VibWl0QnVpbGRSZXNwb25zZSI8
gtPkkwI2IjEvdjIve3BhcmVudD1wcm9qZWN0cy8qL2xvY2F0aW9ucy8qfS9idWlsZHM6c3Vi
bWl0OgEqGmrKQRJydW4uZ29vZ2xlYXBpcy5jb23SQVJodHRwczovL3d3dy5nb29nbGVhcGlz
LmNvbS9hdXRoL2Nsb3VkLXBsYXRmb3JtLGh0dHBzOi8vd3d3Lmdvb2dsZWFwaXMuY29tL2F1
dGgvcnVuQsMBChdjb20uZ29vZ2xlLmNsb3VkLnJ1bi52MkIKQnVpbGRQcm90b1ABWiljbG91
ZC5nb29nbGUuY29tL2dvL3J1bi9hcGl2Mi9ydW5wYjtydW5wYupBbgopY2xvdWRidWlsZC5n
b29nbGVhcGlzLmNvbS9CdWlsZFdvcmtlclBvb2wSQXByb2plY3RzL3twcm9qZWN0fS9sb2Nh
dGlvbnMve2xvY2F0aW9ufS93b3JrZXJQb29scy97d29ya2VyX3Bvb2x9SvQzCgcSBQ4ArwEB
CrwECgEMEgMOABIysQQgQ29weXJpZ2h0IDIwMjYgR29vZ2xlIExMQwoKIExpY2Vuc2VkIHVu
ZGVyIHRoZSBBcGFjaGUgTGljZW5zZSwgVmVyc2lvbiAyLjAgKHRoZSAiTGljZW5zZSIpOwog
eW91IG1heSBub3QgdXNlIHRoaXMgZmlsZSBleGNlcHQgaW4gY29tcGxpYW5jZSB3aXRoIHRo
ZSBMaWNlbnNlLgogWW91IG1heSBvYnRhaW4gYSBjb3B5IG9mIHRoZSBMaWNlbnNlIGF0Cgog
ICAgIGh0dHA6Ly93d3cuYXBhY2hlLm9yZy9saWNlbnNlcy9MSUNFTlNFLTIuMAoKIFVubGVz
cyByZXF1aXJlZCBieSBhcHBsaWNhYmxlIGxhdyBvciBhZ3JlZWQgdG8gaW4gd3JpdGluZywg
c29mdHdhcmUKIGRpc3RyaWJ1dGVkIHVuZGVyIHRoZSBMaWNlbnNlIGlzIGRpc3RyaWJ1dGVk
IG9uIGFuICJBUyBJUyIgQkFTSVMsCiBXSVRIT1VUIFdBUlJBTlRJRVMgT1IgQ09ORElUSU9O
UyBPRiBBTlkgS0lORCwgZWl0aGVyIGV4cHJlc3Mgb3IgaW1wbGllZC4KIFNlZSB0aGUgTGlj
ZW5zZSBmb3IgdGhlIHNwZWNpZmljIGxhbmd1YWdlIGdvdmVybmluZyBwZXJtaXNzaW9ucyBh
bmQKIGxpbWl0YXRpb25zIHVuZGVyIHRoZSBMaWNlbnNlLgoKCAoBAhIDEAAcCgkKAgMAEgMS
ACYKCQoCAwESAxMAIQoJCgIDAhIDFAApCgkKAgMDEgMVACcKCQoCAwQSAxYAIwoJCgIDBRID
FwAtCggKAQgSAxkAQAoJCgIICxIDGQBACggKAQgSAxoAIgoJCgIIChIDGgAiCggKAQgSAxsA
KwoJCgIICBIDGwArCggKAQgSAxwAMAoJCgIIARIDHAAwCgkKAQgSBB0AIAIKDAoECJ0IABIE
HQAgAgovCgIGABIEIwAwARojIENsb3VkIFJ1biBCdWlsZCBDb250cm9sIFBsYW5lIEFQSQoK
CgoDBgABEgMjCA4KCgoDBgADEgMkAjoKDAoFBgADmQgSAyQCOgoLCgMGAAMSBCUCJywKDQoF
BgADmggSBCUCJywKMwoEBgACABIEKgIvAxolIFN1Ym1pdHMgYSBidWlsZCBpbiBhIGdpdmVu
IHByb2plY3QuCgoMCgUGAAIAARIDKgYRCgwKBQYAAgACEgMqEiQKDAoFBgACAAMSAyovQgoN
CgUGAAIABBIEKwQuBgoRCgkGAAIABLDKvCISBCsELgYKNgoCBAASBTMAkAEBGikgUmVxdWVz
dCBtZXNzYWdlIGZvciBzdWJtaXR0aW5nIGEgQnVpbGQuCgoKCgMEAAESAzMIGgpVCgQEAAMA
EgM1AhgaSCBCdWlsZCB0aGUgc291cmNlIHVzaW5nIERvY2tlci4gVGhpcyBtZWFucyB0aGUg
c291cmNlIGhhcyBhIERvY2tlcmZpbGUuCgoMCgUEAAMAARIDNQoVCjIKBAQAAwESBDgCVwMa
JCBCdWlsZCB0aGUgc291cmNlIHVzaW5nIEJ1aWxkcGFja3MuCgoMCgUEAAMBARIDOAoZClAK
BgQAAwECABIDOgQrGkEgVGhlIHJ1bnRpbWUgbmFtZSwgZS5nLiAnZ28xMTMnLiBMZWF2ZSBi
bGFuayBmb3IgZ2VuZXJpYyBidWlsZHMuCgoOCgcEAAMBAgAFEgM6BAoKDgoHBAADAQIAARID
OgsSCg4KBwQAAwECAAMSAzoVFgoOCgcEAAMBAgAIEgM6FyoKDwoIBAADAQIACAMSAzoYKQp5
CgYEAAMBAgESAz4ESBpqIE9wdGlvbmFsLiBOYW1lIG9mIHRoZSBmdW5jdGlvbiB0YXJnZXQg
aWYgdGhlIHNvdXJjZSBpcyBhIGZ1bmN0aW9uIHNvdXJjZS4KIFJlcXVpcmVkIGZvciBmdW5j
dGlvbiBidWlsZHMuCgoOCgcEAAMBAgEFEgM+BAoKDgoHBAADAQIBARIDPgsaCg4KBwQAAwEC
AQMSAz4dHgoOCgcEAAMBAgEIEgM+H0cKEQoKBAADAQIBCJwIABIDPiBGCvMCCgYEAAMBAgIS
A0UESBrjAiBPcHRpb25hbC4gY2FjaGVfaW1hZ2VfdXJpIGlzIHRoZSBHQ1IvQVIgVVJMIHdo
ZXJlIHRoZSBjYWNoZSBpbWFnZSB3aWxsIGJlCiBzdG9yZWQuIGNhY2hlX2ltYWdlX3VyaSBp
cyBvcHRpb25hbCBhbmQgb21pdHRpbmcgaXQgd2lsbCBkaXNhYmxlIGNhY2hpbmcuCiBUaGlz
IFVSTCBtdXN0IGJlIHN0YWJsZSBhY3Jvc3MgYnVpbGRzLiBJdCBpcyB1c2VkIHRvIGRlcml2
ZSBhCiBidWlsZC1zcGVjaWZpYyB0ZW1wb3JhcnkgVVJMIGJ5IHN1YnN0aXR1dGluZyB0aGUg
dGFnIHdpdGggdGhlIGJ1aWxkIElELgogVGhlIGJ1aWxkIHdpbGwgY2xlYW4gdXAgdGhlIHRl
bXBvcmFyeSBpbWFnZSBvbiBhIGJlc3QtZWZmb3J0IGJhc2lzLgoKDgoHBAADAQICBRIDRQQK
Cg4KBwQAAwECAgESA0ULGgoOCgcEAAMBAgIDEgNFHR4KDgoHBAADAQICCBIDRR9HChEKCgQA
AwECAgicCAASA0UgRgo/CgYEAAMBAgMSA0gEQxowIE9wdGlvbmFsLiBUaGUgYmFzZSBpbWFn
ZSB0byB1c2UgZm9yIHRoZSBidWlsZC4KCg4KBwQAAwECAwUSA0gECgoOCgcEAAMBAgMBEgNI
CxUKDgoHBAADAQIDAxIDSBgZCg4KBwQAAwECAwgSA0gaQgoRCgoEAAMBAgMInAgAEgNIG0EK
SwoGBAADAQIEEgRLBEwxGjsgT3B0aW9uYWwuIFVzZXItcHJvdmlkZWQgYnVpbGQtdGltZSBl
bnZpcm9ubWVudCB2YXJpYWJsZXMuCgoOCgcEAAMBAgQGEgNLBBcKDgoHBAADAQIEARIDSxgt
Cg4KBwQAAwECBAMSA0swMQoOCgcEAAMBAgQIEgNMCDAKEQoKBAADAQIECJwIABIDTAkvCuoB
CgYEAAMBAgUSA1EETxraASBPcHRpb25hbC4gV2hldGhlciBvciBub3QgdGhlIGFwcGxpY2F0
aW9uIGNvbnRhaW5lciB3aWxsIGJlIGVucm9sbGVkIGluCiBhdXRvbWF0aWMgYmFzZSBpbWFn
ZSB1cGRhdGVzLiBXaGVuIHRydWUsIHRoZSBhcHBsaWNhdGlvbiB3aWxsIGJlIGJ1aWx0IG9u
CiBhIHNjcmF0Y2ggYmFzZSBpbWFnZSwgc28gdGhlIGJhc2UgbGF5ZXJzIGNhbiBiZSBhcHBl
bmRlZCBhdCBydW4gdGltZS4KCg4KBwQAAwECBQUSA1EECAoOCgcEAAMBAgUBEgNRCSEKDgoH
BAADAQIFAxIDUSQlCg4KBwQAAwECBQgSA1EmTgoRCgoEAAMBAgUInAgAEgNRJ00KrQEKBgQA
AwECBhIDVgRLGp0BIE9wdGlvbmFsLiBwcm9qZWN0X2Rlc2NyaXB0b3Igc3RvcmVzIHRoZSBw
YXRoIHRvIHRoZSBwcm9qZWN0IGRlc2NyaXB0b3IKIGZpbGUuIFdoZW4gZW1wdHksIGl0IG1l
YW5zIHRoYXQgdGhlcmUgaXMgbm8gcHJvamVjdCBkZXNjcmlwdG9yIGZpbGUgaW4KIHRoZSBz
b3VyY2UuCgoOCgcEAAMBAgYFEgNWBAoKDgoHBAADAQIGARIDVgsdCg4KBwQAAwECBgMSA1Yg
IQoOCgcEAAMBAgYIEgNWIkoKEQoKBAADAQIGCJwIABIDViNJCtQBCgQEAAIAEgNdAj0axgEg
UmVxdWlyZWQuIFRoZSBwcm9qZWN0IGFuZCBsb2NhdGlvbiB0byBidWlsZCBpbi4gTG9jYXRp
b24gbXVzdCBiZSBhIHJlZ2lvbiwKIGUuZy4sICd1cy1jZW50cmFsMScgb3IgJ2dsb2JhbCcg
aWYgdGhlIGdsb2JhbCBidWlsZGVyIGlzIHRvIGJlIHVzZWQuCiBGb3JtYXQ6CiBgcHJvamVj
dHMve3Byb2plY3R9L2xvY2F0aW9ucy97bG9jYXRpb259YAoKDAoFBAACAAUSA10CCAoMCgUE
AAIAARIDXQkPCgwKBQQAAgADEgNdEhMKDAoFBAACAAgSA10UPAoPCggEAAIACJwIABIDXRU7
CiMKBAQACAASBGACYwMaFSBMb2NhdGlvbiBvZiBzb3VyY2UuCgoMCgUEAAgAARIDYAgOCi4K
BAQAAgESA2IEThohIFJlcXVpcmVkLiBTb3VyY2UgZm9yIHRoZSBidWlsZC4KCgwKBQQAAgEG
EgNiBBEKDAoFBAACAQESA2ISIAoMCgUEAAIBAxIDYiMkCgwKBQQAAgEIEgNiJU0KDwoIBAAC
AQicCAASA2ImTApICgQEAAICEgNmAkAaOyBSZXF1aXJlZC4gQXJ0aWZhY3QgUmVnaXN0cnkg
VVJJIHRvIHN0b3JlIHRoZSBidWlsdCBpbWFnZS4KCgwKBQQAAgIFEgNmAggKDAoFBAACAgES
A2YJEgoMCgUEAAICAxIDZhUWCgwKBQQAAgIIEgNmFz8KDwoIBAACAgicCAASA2YYPgo4CgQE
AAgBEgRpAm8DGiogQnVpbGQgdHlwZSBtdXN0IGJlIG9uZSBvZiB0aGUgZm9sbG93aW5nLgoK
DAoFBAAIAQESA2kIEgoxCgQEAAIDEgNrBCgaJCBCdWlsZCB0aGUgc291cmNlIHVzaW5nIEJ1
aWxkcGFja3MuCgoMCgUEAAIDBhIDawQTCgwKBQQAAgMBEgNrFCMKDAoFBAACAwMSA2smJwpV
CgQEAAIEEgNuBCEaSCBCdWlsZCB0aGUgc291cmNlIHVzaW5nIERvY2tlci4gVGhpcyBtZWFu
cyB0aGUgc291cmNlIGhhcyBhIERvY2tlcmZpbGUuCgoMCgUEAAIEBhIDbgQPCgwKBQQAAgQB
EgNuEBwKDAoFBAACBAMSA24fIAqWAQoEBAACBRIDcwJGGogBIE9wdGlvbmFsLiBUaGUgc2Vy
dmljZSBhY2NvdW50IHRvIHVzZSBmb3IgdGhlIGJ1aWxkLiBJZiBub3Qgc2V0LCB0aGUgZGVm
YXVsdAogQ2xvdWQgQnVpbGQgc2VydmljZSBhY2NvdW50IGZvciB0aGUgcHJvamVjdCB3aWxs
IGJlIHVzZWQuCgoMCgUEAAIFBRIDcwIICgwKBQQAAgUBEgNzCRgKDAoFBAACBQMSA3MbHAoM
CgUEAAIFCBIDcx1FCg8KCAQAAgUInAgAEgNzHkQK8wIKBAQAAgYSBXsCgAEEGuMCIE9wdGlv
bmFsLiBOYW1lIG9mIHRoZSBDbG91ZCBCdWlsZCBwcml2YXRlIHBvb2wgdGhhdCBzaG91bGQg
YmUgdXNlZCB0byBidWlsZAogdGhlIGZ1bmN0aW9uLiBUaGUgZm9ybWF0IG9mIHRoaXMgZmll
bGQgaXMKIGBwcm9qZWN0cy97cHJvamVjdH0vbG9jYXRpb25zL3tyZWdpb259L3dvcmtlclBv
b2xzL3t3b3JrZXJQb29sfWAgd2hlcmUKIGB7cHJvamVjdH1gIGFuZCBge3JlZ2lvbn1gIGFy
ZSB0aGUgcHJvamVjdCBpZCBhbmQgcmVnaW9uIHJlc3BlY3RpdmVseSB3aGVyZQogdGhlIHdv
cmtlciBwb29sIGlzIGRlZmluZWQgYW5kIGB7d29ya2VyUG9vbH1gIGlzIHRoZSBzaG9ydCBu
YW1lIG9mIHRoZQogd29ya2VyIHBvb2wuCgoMCgUEAAIGBRIDewIICgwKBQQAAgYBEgN7CRQK
DAoFBAACBgMSA3sXGAoOCgUEAAIGCBIFexmAAQMKDwoIBAACBgicCAASA3wEKgoPCgcEAAIG
CJ8IEgR9BH8FCkAKBAQAAgcSBIMBAkQaMiBPcHRpb25hbC4gQWRkaXRpb25hbCB0YWdzIHRv
IGFubm90YXRlIHRoZSBidWlsZC4KCg0KBQQAAgcEEgSDAQIKCg0KBQQAAgcFEgSDAQsRCg0K
BQQAAgcBEgSDARIWCg0KBQQAAgcDEgSDARkaCg0KBQQAAgcIEgSDARtDChAKCAQAAgcInAgA
EgSDARxCCukBCgQEAAIIEgSIAQJDGtoBIE9wdGlvbmFsLiBUaGUgbWFjaGluZSB0eXBlIGZy
b20gZGVmYXVsdCBwb29sIHRvIHVzZSBmb3IgdGhlIGJ1aWxkLiBJZiBsZWZ0CiBibGFuaywg
Y2xvdWRidWlsZCB3aWxsIHVzZSBhIHNlbnNpYmxlIGRlZmF1bHQuIEN1cnJlbnRseSBvbmx5
IEUyX0hJR0hDUFVfOAogaXMgc3VwcG9ydGVkLiBJZiB3b3JrZXJfcG9vbCBpcyBzZXQsIHRo
aXMgZmllbGQgd2lsbCBiZSBpZ25vcmVkLgoKDQoFBAACCAUSBIgBAggKDQoFBAACCAESBIgB
CRUKDQoFBAACCAMSBIgBGBkKDQoFBAACCAgSBIgBGkIKEAoIBAACCAicCAASBIgBG0EKXQoE
BAACCRIGiwECjAEvGk0gT3B0aW9uYWwuIFRoZSByZWxlYXNlIHRyYWNrIG9mIHRoZSBjbGll
bnQgdGhhdCBpbml0aWF0ZWQgdGhlIGJ1aWxkIHJlcXVlc3QuCgoNCgUEAAIJBhIEiwECGAoN
CgUEAAIJARIEiwEZJgoNCgUEAAIJAxIEiwEpKwoNCgUEAAIJCBIEjAEGLgoQCggEAAIJCJwI
ABIEjAEHLQpGCgQEAAIKEgSPAQI+GjggT3B0aW9uYWwuIFRoZSBjbGllbnQgdGhhdCBpbml0
aWF0ZWQgdGhlIGJ1aWxkIHJlcXVlc3QuCgoNCgUEAAIKBRIEjwECCAoNCgUEAAIKARIEjwEJ
DwoNCgUEAAIKAxIEjwESFAoNCgUEAAIKCBIEjwEVPQoQCggEAAIKCJwIABIEjwEWPAo4CgIE
ARIGkwEAnQEBGiogUmVzcG9uc2UgbWVzc2FnZSBmb3Igc3VibWl0dGluZyBhIEJ1aWxkLgoK
CwoDBAEBEgSTAQgbCkYKBAQBAgASBJUBAjMaOCBDbG91ZCBCdWlsZCBvcGVyYXRpb24gdG8g
YmUgcG9sbGVkIHZpYSBDbG91ZEJ1aWxkIEFQSS4KCg0KBQQBAgAGEgSVAQIeCg0KBQQBAgAB
EgSVAR8uCg0KBQQBAgADEgSVATEyCosBCgQEAQIBEgSZAQIcGn0gVVJJIG9mIHRoZSBiYXNl
IGJ1aWxkZXIgaW1hZ2UgaW4gQXJ0aWZhY3QgUmVnaXN0cnkgYmVpbmcgdXNlZCBpbiB0aGUg
YnVpbGQuCiBVc2VkIHRvIG9wdCBpbnRvIGF1dG9tYXRpYyBiYXNlIGltYWdlIHVwZGF0ZXMu
CgoNCgUEAQIBBRIEmQECCAoNCgUEAQIBARIEmQEJFwoNCgUEAQIBAxIEmQEaGwozCgQEAQIC
EgScAQIgGiUgV2FybmluZyBtZXNzYWdlIGZvciB0aGUgYmFzZSBpbWFnZS4KCg0KBQQBAgIF
EgScAQIICg0KBQQBAgIBEgScAQkbCg0KBQQBAgIDEgScAR4fClIKAgQCEgagAQCvAQEaRCBM
b2NhdGlvbiBvZiB0aGUgc291cmNlIGluIGFuIGFyY2hpdmUgZmlsZSBpbiBHb29nbGUgQ2xv
dWQgU3RvcmFnZS4KCgsKAwQCARIEoAEIFQqyAQoEBAICABIEpAECPRqjASBSZXF1aXJlZC4g
R29vZ2xlIENsb3VkIFN0b3JhZ2UgYnVja2V0IGNvbnRhaW5pbmcgdGhlIHNvdXJjZSAoc2Vl
CiBbQnVja2V0IE5hbWUKIFJlcXVpcmVtZW50c10oaHR0cHM6Ly9jbG91ZC5nb29nbGUuY29t
L3N0b3JhZ2UvZG9jcy9idWNrZXQtbmFtaW5nI3JlcXVpcmVtZW50cykpLgoKDQoFBAICAAUS
BKQBAggKDQoFBAICAAESBKQBCQ8KDQoFBAICAAMSBKQBEhMKDQoFBAICAAgSBKQBFDwKEAoI
BAICAAicCAASBKQBFTsKowEKBAQCAgESBKoBAj0alAEgUmVxdWlyZWQuIEdvb2dsZSBDbG91
ZCBTdG9yYWdlIG9iamVjdCBjb250YWluaW5nIHRoZSBzb3VyY2UuCgogVGhpcyBvYmplY3Qg
bXVzdCBiZSBhIGd6aXBwZWQgYXJjaGl2ZSBmaWxlIChgLnRhci5nemApIGNvbnRhaW5pbmcg
c291cmNlIHRvCiBidWlsZC4KCg0KBQQCAgEFEgSqAQIICg0KBQQCAgEBEgSqAQkPCg0KBQQC
AgEDEgSqARITCg0KBQQCAgEIEgSqARQ8ChAKCAQCAgEInAgAEgSqARU7CowBCgQEAgICEgSu
AQJAGn4gT3B0aW9uYWwuIEdvb2dsZSBDbG91ZCBTdG9yYWdlIGdlbmVyYXRpb24gZm9yIHRo
ZSBvYmplY3QuIElmIHRoZSBnZW5lcmF0aW9uCiBpcyBvbWl0dGVkLCB0aGUgbGF0ZXN0IGdl
bmVyYXRpb24gd2lsbCBiZSB1c2VkLgoKDQoFBAICAgUSBK4BAgcKDQoFBAICAgESBK4BCBIK
DQoFBAICAgMSBK4BFRYKDQoFBAICAggSBK4BFz8KEAoIBAICAgicCAASBK4BGD5iBnByb3Rv
Mw==
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Run::V2::Build::SubmitBuildRequest ===
    # Fields for SubmitBuildRequest
    # Field: parent Type: 9 ()
    # Field: storage_source Type: 11 (.google.cloud.run.v2.StorageSource)
    # Field: image_uri Type: 9 ()
    # Field: buildpack_build Type: 11 (.google.cloud.run.v2.SubmitBuildRequest.BuildpacksBuild)
    # Field: docker_build Type: 11 (.google.cloud.run.v2.SubmitBuildRequest.DockerBuild)
    # Field: service_account Type: 9 ()
    # Field: worker_pool Type: 9 ()
    # Field: tags Type: 9 ()
    # Field: machine_type Type: 9 ()
    # Field: release_track Type: 14 (.google.api.LaunchStage)
    # Field: client Type: 9 ()

# === Message: Google::Cloud::Run::V2::Build::SubmitBuildResponse ===
    # Fields for SubmitBuildResponse
    # Field: build_operation Type: 11 (.google.longrunning.Operation)
    # Field: base_image_uri Type: 9 ()
    # Field: base_image_warning Type: 9 ()

# === Message: Google::Cloud::Run::V2::Build::StorageSource ===
    # Fields for StorageSource
    # Field: bucket Type: 9 ()
    # Field: object Type: 9 ()
    # Field: generation Type: 3 ()

# === Service Client: Google::Cloud::Run::V2::Build::BuildsClient ===
package Google::Cloud::Run::V2::Build::BuildsClient;

=pod

=head2 Service Client: Google::Cloud::Run::V2::Build::BuildsClient

Client stub representing the remote C<Builds> gRPC service. Delegates call dispatching to L<Google::gRPC::Client>.

=head3 target

The endpoint target address. Defaults to C<run.googleapis.com:443>.

=head3 credentials

The authentication credentials provider. Defaults to application default credentials via L<Google::Auth>.

=cut

use Moo;
use Google::Auth;
use Google::gRPC::Client;

has credentials => ( is => 'ro', default => sub { Google::Auth->default() } );
has target      => ( is => 'ro', default => 'run.googleapis.com:443' );

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

sub submit_build {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Run::V2::Build::SubmitBuildRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.run.v2.Builds',
        method         => 'SubmitBuild',
        request        => $req,
        response_class => 'Google::Cloud::Run::V2::Build::SubmitBuildResponse',
    });
}

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Run::V2::Build - Compiled Protocol Buffers messages for google/cloud/run/v2/build.proto

=head1 SYNOPSIS

    use Google::Cloud::Run::V2::Build;

    my $msg = Google::Cloud::Run::V2::Build::SubmitBuildRequest->new({
        parent => $parent,
        storage_source => $storage_source,
        image_uri => $image_uri,
        buildpack_build => $buildpack_build,
    });

    # Read or update a field
    my $val = $msg->parent();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Run::V2::Build::SubmitBuildRequest->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/run/v2/build.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Run::V2::Build::SubmitBuildRequest

Request message for submitting a Build.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->parent() >> / C<< $msg->parent($value) >>

Type: C<String>

Required. The project and location to build in. Location must be a region,
e.g., 'us-central1' or 'global' if the global builder is to be used.
Format:
`projects/{project}/locations/{location}`

=item * C<< $msg->storage_source() >> / C<< $msg->storage_source($value) >>

Type: C<Message> (L<Google::Cloud::Run::V2::Build::StorageSource>)

Required. Source for the build.

=item * C<< $msg->image_uri() >> / C<< $msg->image_uri($value) >>

Type: C<String>

Required. Artifact Registry URI to store the built image.

=item * C<< $msg->buildpack_build() >> / C<< $msg->buildpack_build($value) >>

Type: C<Message> (L<Google::Cloud::Run::V2::Build::SubmitBuildRequest::BuildpacksBuild>)

Build the source using Buildpacks.

=item * C<< $msg->docker_build() >> / C<< $msg->docker_build($value) >>

Type: C<Message> (L<Google::Cloud::Run::V2::Build::SubmitBuildRequest::DockerBuild>)

Build the source using Docker. This means the source has a Dockerfile.

=item * C<< $msg->service_account() >> / C<< $msg->service_account($value) >>

Type: C<String>

Optional. The service account to use for the build. If not set, the default
Cloud Build service account for the project will be used.

=item * C<< $msg->worker_pool() >> / C<< $msg->worker_pool($value) >>

Type: C<String>

Optional. Name of the Cloud Build private pool that should be used to build
the function. The format of this field is
`projects/{project}/locations/{region}/workerPools/{workerPool}` where
`{project}` and `{region}` are the project id and region respectively where
the worker pool is defined and `{workerPool}` is the short name of the
worker pool.

=item * C<< $msg->tags() >> / C<< $msg->tags($value) >>

Type: C<String>

Optional. Additional tags to annotate the build.

=item * C<< $msg->machine_type() >> / C<< $msg->machine_type($value) >>

Type: C<String>

Optional. The machine type from default pool to use for the build. If left
blank, cloudbuild will use a sensible default. Currently only E2_HIGHCPU_8
is supported. If worker_pool is set, this field will be ignored.

=item * C<< $msg->release_track() >> / C<< $msg->release_track($value) >>

Type: C<Enum> (L<Google::Api::LaunchStage>)

Optional. The release track of the client that initiated the build request.

=item * C<< $msg->client() >> / C<< $msg->client($value) >>

Type: C<String>

Optional. The client that initiated the build request.

=back

=head2 Google::Cloud::Run::V2::Build::SubmitBuildResponse

Response message for submitting a Build.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->build_operation() >> / C<< $msg->build_operation($value) >>

Type: C<Message> (L<Google::Longrunning::Operations::Operation>)

Cloud Build operation to be polled via CloudBuild API.

=item * C<< $msg->base_image_uri() >> / C<< $msg->base_image_uri($value) >>

Type: C<String>

URI of the base builder image in Artifact Registry being used in the build.
Used to opt into automatic base image updates.

=item * C<< $msg->base_image_warning() >> / C<< $msg->base_image_warning($value) >>

Type: C<String>

Warning message for the base image.

=back

=head2 Google::Cloud::Run::V2::Build::StorageSource

Location of the source in an archive file in Google Cloud Storage.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->bucket() >> / C<< $msg->bucket($value) >>

Type: C<String>

Required. Google Cloud Storage bucket containing the source (see
[Bucket Name
Requirements](https://cloud.google.com/storage/docs/bucket-naming#requirements)).

=item * C<< $msg->object() >> / C<< $msg->object($value) >>

Type: C<String>

Required. Google Cloud Storage object containing the source.

This object must be a gzipped archive file (`.tar.gz`) containing source to
build.

=item * C<< $msg->generation() >> / C<< $msg->generation($value) >>

Type: C<Int64>

Optional. Google Cloud Storage generation for the object. If the generation
is omitted, the latest generation will be used.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Run::V2::Build::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
