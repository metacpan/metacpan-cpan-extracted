package Google::Cloud::Chronicle::V1::FeaturedContentNativeDashboard;

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
    eval { require Google::Cloud::Chronicle::V1::FeaturedContentMetadata };
    eval { require Google::Cloud::Chronicle::V1::NativeDashboard };
    my $descriptor_b64 = <<'EOF';
CkFnb29nbGUvY2xvdWQvY2hyb25pY2xlL3YxL2ZlYXR1cmVkX2NvbnRlbnRfbmF0aXZlX2Rh
c2hib2FyZC5wcm90bxIZZ29vZ2xlLmNsb3VkLmNocm9uaWNsZS52MRocZ29vZ2xlL2FwaS9h
bm5vdGF0aW9ucy5wcm90bxoXZ29vZ2xlL2FwaS9jbGllbnQucHJvdG8aH2dvb2dsZS9hcGkv
ZmllbGRfYmVoYXZpb3IucHJvdG8aGWdvb2dsZS9hcGkvcmVzb3VyY2UucHJvdG8aOWdvb2ds
ZS9jbG91ZC9jaHJvbmljbGUvdjEvZmVhdHVyZWRfY29udGVudF9tZXRhZGF0YS5wcm90bxow
Z29vZ2xlL2Nsb3VkL2Nocm9uaWNsZS92MS9uYXRpdmVfZGFzaGJvYXJkLnByb3RvIp4ECh5G
ZWF0dXJlZENvbnRlbnROYXRpdmVEYXNoYm9hcmQSFwoEbmFtZRgBIAEoCUID4EEIUgRuYW1l
EmIKEGNvbnRlbnRfbWV0YWRhdGEYAiABKAsyMi5nb29nbGUuY2xvdWQuY2hyb25pY2xlLnYx
LkZlYXR1cmVkQ29udGVudE1ldGFkYXRhQgPgQQNSD2NvbnRlbnRNZXRhZGF0YRJwChFkYXNo
Ym9hcmRfY29udGVudBgDIAEoCzI+Lmdvb2dsZS5jbG91ZC5jaHJvbmljbGUudjEuTmF0aXZl
RGFzaGJvYXJkV2l0aENoYXJ0c0FuZFF1ZXJpZXNCA+BBAVIQZGFzaGJvYXJkQ29udGVudDqM
AupBiAIKN2Nocm9uaWNsZS5nb29nbGVhcGlzLmNvbS9GZWF0dXJlZENvbnRlbnROYXRpdmVE
YXNoYm9hcmQSiwFwcm9qZWN0cy97cHJvamVjdH0vbG9jYXRpb25zL3tsb2NhdGlvbn0vaW5z
dGFuY2VzL3tpbnN0YW5jZX0vY29udGVudEh1Yi9mZWF0dXJlZENvbnRlbnROYXRpdmVEYXNo
Ym9hcmRzL3tmZWF0dXJlZF9jb250ZW50X25hdGl2ZV9kYXNoYm9hcmR9Kh9mZWF0dXJlZENv
bnRlbnROYXRpdmVEYXNoYm9hcmRzMh5mZWF0dXJlZENvbnRlbnROYXRpdmVEYXNoYm9hcmQi
fwooR2V0RmVhdHVyZWRDb250ZW50TmF0aXZlRGFzaGJvYXJkUmVxdWVzdBJTCgRuYW1lGAEg
ASgJQj/gQQL6QTkKN2Nocm9uaWNsZS5nb29nbGVhcGlzLmNvbS9GZWF0dXJlZENvbnRlbnRO
YXRpdmVEYXNoYm9hcmRSBG5hbWUi6AEKKkxpc3RGZWF0dXJlZENvbnRlbnROYXRpdmVEYXNo
Ym9hcmRzUmVxdWVzdBJXCgZwYXJlbnQYASABKAlCP+BBAvpBORI3Y2hyb25pY2xlLmdvb2ds
ZWFwaXMuY29tL0ZlYXR1cmVkQ29udGVudE5hdGl2ZURhc2hib2FyZFIGcGFyZW50EiAKCXBh
Z2Vfc2l6ZRgCIAEoBUID4EEBUghwYWdlU2l6ZRIiCgpwYWdlX3Rva2VuGAMgASgJQgPgQQFS
CXBhZ2VUb2tlbhIbCgZmaWx0ZXIYBCABKAlCA+BBAVIGZmlsdGVyIt4BCitMaXN0RmVhdHVy
ZWRDb250ZW50TmF0aXZlRGFzaGJvYXJkc1Jlc3BvbnNlEoYBCiJmZWF0dXJlZF9jb250ZW50
X25hdGl2ZV9kYXNoYm9hcmRzGAEgAygLMjkuZ29vZ2xlLmNsb3VkLmNocm9uaWNsZS52MS5G
ZWF0dXJlZENvbnRlbnROYXRpdmVEYXNoYm9hcmRSH2ZlYXR1cmVkQ29udGVudE5hdGl2ZURh
c2hib2FyZHMSJgoPbmV4dF9wYWdlX3Rva2VuGAIgASgJUg1uZXh0UGFnZVRva2VuIo8CCixJ
bnN0YWxsRmVhdHVyZWRDb250ZW50TmF0aXZlRGFzaGJvYXJkUmVxdWVzdBJTCgRuYW1lGAEg
ASgJQj/gQQL6QTkKN2Nocm9uaWNsZS5nb29nbGVhcGlzLmNvbS9GZWF0dXJlZENvbnRlbnRO
YXRpdmVEYXNoYm9hcmRSBG5hbWUSiQEKIWZlYXR1cmVkX2NvbnRlbnRfbmF0aXZlX2Rhc2hi
b2FyZBgCIAEoCzI5Lmdvb2dsZS5jbG91ZC5jaHJvbmljbGUudjEuRmVhdHVyZWRDb250ZW50
TmF0aXZlRGFzaGJvYXJkQgPgQQFSHmZlYXR1cmVkQ29udGVudE5hdGl2ZURhc2hib2FyZCKM
AQotSW5zdGFsbEZlYXR1cmVkQ29udGVudE5hdGl2ZURhc2hib2FyZFJlc3BvbnNlElsKEG5h
dGl2ZV9kYXNoYm9hcmQYASABKAlCMOBBAfpBKgooY2hyb25pY2xlLmdvb2dsZWFwaXMuY29t
L05hdGl2ZURhc2hib2FyZFIPbmF0aXZlRGFzaGJvYXJkMrwICiVGZWF0dXJlZENvbnRlbnRO
YXRpdmVEYXNoYm9hcmRTZXJ2aWNlEo4CCiFHZXRGZWF0dXJlZENvbnRlbnROYXRpdmVEYXNo
Ym9hcmQSQy5nb29nbGUuY2xvdWQuY2hyb25pY2xlLnYxLkdldEZlYXR1cmVkQ29udGVudE5h
dGl2ZURhc2hib2FyZFJlcXVlc3QaOS5nb29nbGUuY2xvdWQuY2hyb25pY2xlLnYxLkZlYXR1
cmVkQ29udGVudE5hdGl2ZURhc2hib2FyZCJpgtPkkwJcElovdjEve25hbWU9cHJvamVjdHMv
Ki9sb2NhdGlvbnMvKi9pbnN0YW5jZXMvKi9jb250ZW50SHViL2ZlYXR1cmVkQ29udGVudE5h
dGl2ZURhc2hib2FyZHMvKn3aQQRuYW1lEqECCiNMaXN0RmVhdHVyZWRDb250ZW50TmF0aXZl
RGFzaGJvYXJkcxJFLmdvb2dsZS5jbG91ZC5jaHJvbmljbGUudjEuTGlzdEZlYXR1cmVkQ29u
dGVudE5hdGl2ZURhc2hib2FyZHNSZXF1ZXN0GkYuZ29vZ2xlLmNsb3VkLmNocm9uaWNsZS52
MS5MaXN0RmVhdHVyZWRDb250ZW50TmF0aXZlRGFzaGJvYXJkc1Jlc3BvbnNlImuC0+STAlwS
Wi92MS97cGFyZW50PXByb2plY3RzLyovbG9jYXRpb25zLyovaW5zdGFuY2VzLyovY29udGVu
dEh1Yn0vZmVhdHVyZWRDb250ZW50TmF0aXZlRGFzaGJvYXJkc9pBBnBhcmVudBKwAgolSW5z
dGFsbEZlYXR1cmVkQ29udGVudE5hdGl2ZURhc2hib2FyZBJHLmdvb2dsZS5jbG91ZC5jaHJv
bmljbGUudjEuSW5zdGFsbEZlYXR1cmVkQ29udGVudE5hdGl2ZURhc2hib2FyZFJlcXVlc3Qa
SC5nb29nbGUuY2xvdWQuY2hyb25pY2xlLnYxLkluc3RhbGxGZWF0dXJlZENvbnRlbnROYXRp
dmVEYXNoYm9hcmRSZXNwb25zZSJ0gtPkkwJnImIvdjEve25hbWU9cHJvamVjdHMvKi9sb2Nh
dGlvbnMvKi9pbnN0YW5jZXMvKi9jb250ZW50SHViL2ZlYXR1cmVkQ29udGVudE5hdGl2ZURh
c2hib2FyZHMvKn06aW5zdGFsbDoBKtpBBG5hbWUaqgHKQRhjaHJvbmljbGUuZ29vZ2xlYXBp
cy5jb23SQYsBaHR0cHM6Ly93d3cuZ29vZ2xlYXBpcy5jb20vYXV0aC9jaHJvbmljbGUsaHR0
cHM6Ly93d3cuZ29vZ2xlYXBpcy5jb20vYXV0aC9jaHJvbmljbGUucmVhZG9ubHksaHR0cHM6
Ly93d3cuZ29vZ2xlYXBpcy5jb20vYXV0aC9jbG91ZC1wbGF0Zm9ybULkAgodY29tLmdvb2ds
ZS5jbG91ZC5jaHJvbmljbGUudjFCI0ZlYXR1cmVkQ29udGVudE5hdGl2ZURhc2hib2FyZFBy
b3RvUAFaO2Nsb3VkLmdvb2dsZS5jb20vZ28vY2hyb25pY2xlL2FwaXYxL2Nocm9uaWNsZXBi
O2Nocm9uaWNsZXBiqgIZR29vZ2xlLkNsb3VkLkNocm9uaWNsZS5WMcoCGUdvb2dsZVxDbG91
ZFxDaHJvbmljbGVcVjHqAhxHb29nbGU6OkNsb3VkOjpDaHJvbmljbGU6OlYx6kGGAQojY2hy
b25pY2xlLmdvb2dsZWFwaXMuY29tL0NvbnRlbnRIdWISR3Byb2plY3RzL3twcm9qZWN0fS9s
b2NhdGlvbnMve2xvY2F0aW9ufS9pbnN0YW5jZXMve2luc3RhbmNlfS9jb250ZW50SHViKgpj
b250ZW50SHViMgpjb250ZW50SHViSvcuCgcSBQ4AzgEBCrwECgEMEgMOABIysQQgQ29weXJp
Z2h0IDIwMjYgR29vZ2xlIExMQwoKIExpY2Vuc2VkIHVuZGVyIHRoZSBBcGFjaGUgTGljZW5z
ZSwgVmVyc2lvbiAyLjAgKHRoZSAiTGljZW5zZSIpOwogeW91IG1heSBub3QgdXNlIHRoaXMg
ZmlsZSBleGNlcHQgaW4gY29tcGxpYW5jZSB3aXRoIHRoZSBMaWNlbnNlLgogWW91IG1heSBv
YnRhaW4gYSBjb3B5IG9mIHRoZSBMaWNlbnNlIGF0CgogICAgIGh0dHA6Ly93d3cuYXBhY2hl
Lm9yZy9saWNlbnNlcy9MSUNFTlNFLTIuMAoKIFVubGVzcyByZXF1aXJlZCBieSBhcHBsaWNh
YmxlIGxhdyBvciBhZ3JlZWQgdG8gaW4gd3JpdGluZywgc29mdHdhcmUKIGRpc3RyaWJ1dGVk
IHVuZGVyIHRoZSBMaWNlbnNlIGlzIGRpc3RyaWJ1dGVkIG9uIGFuICJBUyBJUyIgQkFTSVMs
CiBXSVRIT1VUIFdBUlJBTlRJRVMgT1IgQ09ORElUSU9OUyBPRiBBTlkgS0lORCwgZWl0aGVy
IGV4cHJlc3Mgb3IgaW1wbGllZC4KIFNlZSB0aGUgTGljZW5zZSBmb3IgdGhlIHNwZWNpZmlj
IGxhbmd1YWdlIGdvdmVybmluZyBwZXJtaXNzaW9ucyBhbmQKIGxpbWl0YXRpb25zIHVuZGVy
IHRoZSBMaWNlbnNlLgoKCAoBAhIDEAAiCgkKAgMAEgMSACYKCQoCAwESAxMAIQoJCgIDAhID
FAApCgkKAgMDEgMVACMKCQoCAwQSAxYAQwoJCgIDBRIDFwA6CggKAQgSAxkANgoJCgIIJRID
GQA2CggKAQgSAxoAUgoJCgIICxIDGgBSCggKAQgSAxsAIgoJCgIIChIDGwAiCggKAQgSAxwA
RAoJCgIICBIDHABECggKAQgSAx0ANgoJCgIIARIDHQA2CggKAQgSAx4ANgoJCgIIKRIDHgA2
CggKAQgSAx8ANQoJCgIILRIDHwA1CgkKAQgSBCAAJQIKDAoECJ0IABIEIAAlAgpfCgIGABIE
KQBOARpTIFRoaXMgc2VydmljZSBwcm92aWRlcyBmdW5jdGlvbmFsaXR5IGZvciBtYW5hZ2lu
ZwogRmVhdHVyZWRDb250ZW50TmF0aXZlRGFzaGJvYXJkLgoKCgoDBgABEgMpCC0KCgoDBgAD
EgMqAkAKDAoFBgADmQgSAyoCQAoLCgMGAAMSBCsCLjcKDQoFBgADmggSBCsCLjcKOAoEBgAC
ABIEMQI4AxoqIEdldCBhIG5hdGl2ZSBkYXNoYm9hcmQgZmVhdHVyZWQgY29udGVudC4KCgwK
BQYAAgABEgMxBicKDAoFBgACAAISAzIGLgoMCgUGAAIAAxIDMw8tCg0KBQYAAgAEEgQ0BDYG
ChEKCQYAAgAEsMq8IhIENAQ2BgoMCgUGAAIABBIDNwQyCg8KCAYAAgAEmwgAEgM3BDIKPAoE
BgACARIEOwJCAxouIExpc3QgYWxsIG5hdGl2ZSBkYXNoYm9hcmRzIGZlYXR1cmVkIGNvbnRl
bnQuCgoMCgUGAAIBARIDOwYpCgwKBQYAAgECEgM8BjAKDAoFBgACAQMSAz0POgoNCgUGAAIB
BBIEPgRABgoRCgkGAAIBBLDKvCISBD4EQAYKDAoFBgACAQQSA0EENAoPCggGAAIBBJsIABID
QQQ0CjwKBAYAAgISBEUCTQMaLiBJbnN0YWxsIGEgbmF0aXZlIGRhc2hib2FyZCBmZWF0dXJl
ZCBjb250ZW50LgoKDAoFBgACAgESA0UGKwoMCgUGAAICAhIDRgYyCgwKBQYAAgIDEgNHDzwK
DQoFBgACAgQSBEgESwYKEQoJBgACAgSwyrwiEgRIBEsGCgwKBQYAAgIEEgNMBDIKDwoIBgAC
AgSbCAASA0wEMgo2CgIEABIEUQBlARoqIEZlYXR1cmVkQ29udGVudE5hdGl2ZURhc2hib2Fy
ZCByZXNvdXJjZS4KCgoKAwQAARIDUQgmCgsKAwQABxIEUgJXBAoNCgUEAAedCBIEUgJXBArq
AQoEBAACABIDXAI9GtwBIElkZW50aWZpZXIuIFRoZSByZXNvdXJjZSBuYW1lIG9mIHRoZSBG
ZWF0dXJlZENvbnRlbnROYXRpdmVEYXNoYm9hcmQuCiBGb3JtYXQ6CiBwcm9qZWN0cy97cHJv
amVjdH0vbG9jYXRpb25zL3tsb2NhdGlvbn0vaW5zdGFuY2VzL3tpbnN0YW5jZX0vY29udGVu
dEh1Yi9mZWF0dXJlZENvbnRlbnROYXRpdmVEYXNoYm9hcmRzL3tmZWF0dXJlZF9jb250ZW50
X25hdGl2ZV9kYXNoYm9hcmR9CgoMCgUEAAIABRIDXAIICgwKBQQAAgABEgNcCQ0KDAoFBAAC
AAMSA1wQEQoMCgUEAAIACBIDXBI8Cg8KCAQAAgAInAgAEgNcEzsKTwoEBAACARIEXwJgMhpB
IE91dHB1dCBvbmx5LiBNZXRhZGF0YSBhYm91dCB0aGUgRmVhdHVyZWRDb250ZW50TmF0aXZl
RGFzaGJvYXJkLgoKDAoFBAACAQYSA18CGQoMCgUEAAIBARIDXxoqCgwKBQQAAgEDEgNfLS4K
DAoFBAACAQgSA2AGMQoPCggEAAIBCJwIABIDYAcwCjAKBAQAAgISBGMCZC8aIiBPcHRpb25h
bC4gVGhlIGRhc2hib2FyZCBjb250ZW50LgoKDAoFBAACAgYSA2MCJQoMCgUEAAICARIDYyY3
CgwKBQQAAgIDEgNjOjsKDAoFBAACAggSA2QGLgoPCggEAAICCJwIABIDZActCkYKAgQBEgRo
AHIBGjogUmVxdWVzdCBtZXNzYWdlIHRvIGdldCBhIEZlYXR1cmVkQ29udGVudE5hdGl2ZURh
c2hib2FyZC4KCgoKAwQBARIDaAgwCvUBCgQEAQIAEgRsAnEEGuYBIFJlcXVpcmVkLiBUaGUg
cmVzb3VyY2UgbmFtZSBvZiB0aGUgRmVhdHVyZWRDb250ZW50TmF0aXZlRGFzaGJvYXJkIHRv
CiByZXRyaWV2ZS4gRm9ybWF0OgogcHJvamVjdHMve3Byb2plY3R9L2xvY2F0aW9ucy97bG9j
YXRpb259L2luc3RhbmNlcy97aW5zdGFuY2V9L2NvbnRlbnRIdWIvZmVhdHVyZWRDb250ZW50
TmF0aXZlRGFzaGJvYXJkcy97ZmVhdHVyZWRfY29udGVudF9uYXRpdmVfZGFzaGJvYXJkfQoK
DAoFBAECAAUSA2wCCAoMCgUEAQIAARIDbAkNCgwKBQQBAgADEgNsEBEKDQoFBAECAAgSBGwS
cQMKDwoIBAECAAicCAASA20EKgoPCgcEAQIACJ8IEgRuBHAFCkcKAgQCEgV1AKQBARo6IFJl
cXVlc3QgbWVzc2FnZSB0byBsaXN0IEZlYXR1cmVkQ29udGVudE5hdGl2ZURhc2hib2FyZHMu
CgoKCgMEAgESA3UIMgq3AQoEBAICABIEeQJ+BBqoASBSZXF1aXJlZC4gVGhlIHBhcmVudCwg
d2hpY2ggb3ducyB0aGlzIGNvbGxlY3Rpb24gb2YKIEZlYXR1cmVkQ29udGVudE5hdGl2ZURh
c2hib2FyZHMuIEZvcm1hdDoKIHByb2plY3RzL3twcm9qZWN0fS9sb2NhdGlvbnMve2xvY2F0
aW9ufS9pbnN0YW5jZXMve2luc3RhbmNlfS9jb250ZW50SHViCgoMCgUEAgIABRIDeQIICgwK
BQQCAgABEgN5CQ8KDAoFBAICAAMSA3kSEwoNCgUEAgIACBIEeRR+AwoPCggEAgIACJwIABID
egQqCg8KBwQCAgAInwgSBHsEfQUKnQIKBAQCAgESBIQBAj8ajgIgT3B0aW9uYWwuIFRoZSBt
YXhpbXVtIG51bWJlciBvZiBGZWF0dXJlZENvbnRlbnROYXRpdmVEYXNoYm9hcmRzIHRvIHJl
dHVybi4KIFRoZSBzZXJ2aWNlIG1heSByZXR1cm4gZmV3ZXIgdGhhbiB0aGlzIHZhbHVlLiBJ
ZiB1bnNwZWNpZmllZCwgYXQgbW9zdCAxMDAKIEZlYXR1cmVkQ29udGVudE5hdGl2ZURhc2hi
b2FyZHMgd2lsbCBiZSByZXR1cm5lZC4gVGhlIG1heGltdW0gdmFsdWUgaXMgMTAwOwogdmFs
dWVzIGFib3ZlIDEwMCB3aWxsIGJlIGNvZXJjZWQgdG8gMTAwLgoKDQoFBAICAQUSBIQBAgcK
DQoFBAICAQESBIQBCBEKDQoFBAICAQMSBIQBFBUKDQoFBAICAQgSBIQBFj4KEAoIBAICAQic
CAASBIQBFz0KqwIKBAQCAgISBI0BAkEanAIgT3B0aW9uYWwuIEEgcGFnZSB0b2tlbiwgcmVj
ZWl2ZWQgZnJvbSBhIHByZXZpb3VzCiBgTGlzdEZlYXR1cmVkQ29udGVudE5hdGl2ZURhc2hi
b2FyZHNgIGNhbGwuIFByb3ZpZGUgdGhpcyB0byByZXRyaWV2ZSB0aGUKIHN1YnNlcXVlbnQg
cGFnZS4KCiBXaGVuIHBhZ2luYXRpbmcsIGFsbCBvdGhlciBwYXJhbWV0ZXJzIHByb3ZpZGVk
IHRvCiBgTGlzdEZlYXR1cmVkQ29udGVudE5hdGl2ZURhc2hib2FyZHNgIG11c3QgbWF0Y2gg
dGhlIGNhbGwgdGhhdCBwcm92aWRlZCB0aGUKIHBhZ2UgdG9rZW4uCgoNCgUEAgICBRIEjQEC
CAoNCgUEAgICARIEjQEJEwoNCgUEAgICAxIEjQEWFwoNCgUEAgICCBIEjQEYQAoQCggEAgIC
CJwIABIEjQEZPwqeBgoEBAICAxIEowECPRqPBiBPcHRpb25hbC4gVGhlIGZpbHRlciB0byBh
cHBseSB0byBsaXN0IHRoZSBGZWF0dXJlZENvbnRlbnROYXRpdmVEYXNoYm9hcmRzLgoKIFRo
ZSBmaWx0ZXIgc3ludGF4IGZvbGxvd3MgR29vZ2xlIENsb3VkIHN5bnRheDogaHR0cHM6Ly9n
b29nbGUuYWlwLmRldi8xNjAuCgogU3VwcG9ydGVkIGZpZWxkcyBmb3IgZmlsdGVyaW5nOgoK
ICogICBgbmFtZWA6IFRoZSByZXNvdXJjZSBuYW1lIG9mIHRoZSBmZWF0dXJlZCBjb250ZW50
LgogKiAgIGBjb250ZW50X21ldGFkYXRhLmRlc2NyaXB0aW9uYDogVGhlIGRlc2NyaXB0aW9u
IG9mIHRoZSBmZWF0dXJlZAogY29udGVudC4KCiBXaGVuIGEgbGl0ZXJhbCB2YWx1ZSBpcyBw
cm92aWRlZCB3aXRob3V0IGEgZmllbGQsIGl0IHdpbGwgcGVyZm9ybSBhCiBzdWJzdHJpbmcg
c2VhcmNoIGFjcm9zcyBib3RoIGBuYW1lYCBhbmQgYGNvbnRlbnRfbWV0YWRhdGEuZGVzY3Jp
cHRpb25gLgoKIEV4YW1wbGVzOgoKICogICBgInRlc3QiYDogTWF0Y2hlcyBmZWF0dXJlZCBj
b250ZW50IHdoZXJlIGVpdGhlciB0aGUgbmFtZSBvciBkZXNjcmlwdGlvbgogICAgIGNvbnRh
aW5zICJ0ZXN0IiBhcyBhIHN1YnN0cmluZy4KICogICBgbmFtZT0idGVzdCJgOiBNYXRjaGVz
IGZlYXR1cmVkIGNvbnRlbnQgd2hlcmUgdGhlIG5hbWUgY29udGFpbnMgInRlc3QiLgogKiAg
IGBjb250ZW50X21ldGFkYXRhLmRlc2NyaXB0aW9uPSJ0ZXN0ImA6IE1hdGNoZXMgZmVhdHVy
ZWQgY29udGVudCB3aGVyZQogICAgIHRoZSBkZXNjcmlwdGlvbiBjb250YWlucyAidGVzdCIu
CgoNCgUEAgIDBRIEowECCAoNCgUEAgIDARIEowEJDwoNCgUEAgIDAxIEowESEwoNCgUEAgID
CBIEowEUPAoQCggEAgIDCJwIABIEowEVOwpNCgIEAxIGpwEAsAEBGj8gUmVzcG9uc2UgbWVz
c2FnZSBmb3IgbGlzdGluZyBGZWF0dXJlZENvbnRlbnROYXRpdmVEYXNoYm9hcmRzLgoKCwoD
BAMBEgSnAQgzClsKBAQDAgASBqoBAqsBCBpLIFRoZSBsaXN0IG9mIEZlYXR1cmVkQ29udGVu
dE5hdGl2ZURhc2hib2FyZHMuCiBPcmRlcmVkIGJ5IG5hbWUgYnkgZGVmYXVsdC4KCg0KBQQD
AgAEEgSqAQIKCg0KBQQDAgAGEgSqAQspCg0KBQQDAgABEgSqASpMCg0KBQQDAgADEgSrAQYH
CpABCgQEAwIBEgSvAQIdGoEBIEEgdG9rZW4sIHdoaWNoIGNhbiBiZSBzZW50IGFzIGBwYWdl
X3Rva2VuYCB0byByZXRyaWV2ZSB0aGUgbmV4dCBwYWdlLgogSWYgdGhpcyBmaWVsZCBpcyBv
bWl0dGVkLCB0aGVyZSBhcmUgbm8gc3Vic2VxdWVudCBwYWdlcy4KCg0KBQQDAgEFEgSvAQII
Cg0KBQQDAgEBEgSvAQkYCg0KBQQDAgEDEgSvARscCkwKAgQEEgazAQDBAQEaPiBSZXF1ZXN0
IG1lc3NhZ2UgdG8gaW5zdGFsbCBhIEZlYXR1cmVkQ29udGVudE5hdGl2ZURhc2hib2FyZC4K
CgsKAwQEARIEswEINAr2AQoEBAQCABIGtwECvAEEGuUBIFJlcXVpcmVkLiBUaGUgcmVzb3Vy
Y2UgbmFtZSBvZiB0aGUgRmVhdHVyZWRDb250ZW50TmF0aXZlRGFzaGJvYXJkIHRvCiBpbnN0
YWxsLiBGb3JtYXQ6CiBwcm9qZWN0cy97cHJvamVjdH0vbG9jYXRpb25zL3tsb2NhdGlvbn0v
aW5zdGFuY2VzL3tpbnN0YW5jZX0vY29udGVudEh1Yi9mZWF0dXJlZENvbnRlbnROYXRpdmVE
YXNoYm9hcmRzL3tmZWF0dXJlZF9jb250ZW50X25hdGl2ZV9kYXNoYm9hcmR9CgoNCgUEBAIA
BRIEtwECCAoNCgUEBAIAARIEtwEJDQoNCgUEBAIAAxIEtwEQEQoPCgUEBAIACBIGtwESvAED
ChAKCAQEAgAInAgAEgS4AQQqChEKBwQEAgAInwgSBrkBBLsBBQpKCgQEBAIBEga/AQLAAS8a
OiBPcHRpb25hbC4gVGhlIEZlYXR1cmVkQ29udGVudE5hdGl2ZURhc2hib2FyZCB0byBpbnN0
YWxsLgoKDQoFBAQCAQYSBL8BAiAKDQoFBAQCAQESBL8BIUIKDQoFBAQCAQMSBL8BRUYKDQoF
BAQCAQgSBMABBi4KEAoIBAQCAQicCAASBMABBy0KUQoCBAUSBsQBAM4BARpDIFJlc3BvbnNl
IG1lc3NhZ2UgZm9yIGluc3RhbGxpbmcgYSBGZWF0dXJlZENvbnRlbnROYXRpdmVEYXNoYm9h
cmQuCgoLCgMEBQESBMQBCDUKvAEKBAQFAgASBsgBAs0BBBqrASBPcHRpb25hbC4gVGhlIHJl
c291cmNlIG5hbWUgb2YgdGhlIE5hdGl2ZURhc2hib2FyZCBjcmVhdGVkLgogRm9ybWF0Ogog
cHJvamVjdHMve3Byb2plY3R9L2xvY2F0aW9ucy97bG9jYXRpb259L2luc3RhbmNlcy97aW5z
dGFuY2V9L25hdGl2ZURhc2hib2FyZHMve25hdGl2ZV9kYXNoYm9hcmRfaWR9CgoNCgUEBQIA
BRIEyAECCAoNCgUEBQIAARIEyAEJGQoNCgUEBQIAAxIEyAEcHQoPCgUEBQIACBIGyAEezQED
ChAKCAQFAgAInAgAEgTJAQQqChEKBwQFAgAInwgSBsoBBMwBBWIGcHJvdG8z
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Chronicle::V1::FeaturedContentNativeDashboard::FeaturedContentNativeDashboard ===
    # Fields for FeaturedContentNativeDashboard
    # Field: name Type: 9 ()
    # Field: content_metadata Type: 11 (.google.cloud.chronicle.v1.FeaturedContentMetadata)
    # Field: dashboard_content Type: 11 (.google.cloud.chronicle.v1.NativeDashboardWithChartsAndQueries)

# === Message: Google::Cloud::Chronicle::V1::FeaturedContentNativeDashboard::GetFeaturedContentNativeDashboardRequest ===
    # Fields for GetFeaturedContentNativeDashboardRequest
    # Field: name Type: 9 ()

# === Message: Google::Cloud::Chronicle::V1::FeaturedContentNativeDashboard::ListFeaturedContentNativeDashboardsRequest ===
    # Fields for ListFeaturedContentNativeDashboardsRequest
    # Field: parent Type: 9 ()
    # Field: page_size Type: 5 ()
    # Field: page_token Type: 9 ()
    # Field: filter Type: 9 ()

# === Message: Google::Cloud::Chronicle::V1::FeaturedContentNativeDashboard::ListFeaturedContentNativeDashboardsResponse ===
    # Fields for ListFeaturedContentNativeDashboardsResponse
    # Field: featured_content_native_dashboards Type: 11 (.google.cloud.chronicle.v1.FeaturedContentNativeDashboard)
    # Field: next_page_token Type: 9 ()

# === Message: Google::Cloud::Chronicle::V1::FeaturedContentNativeDashboard::InstallFeaturedContentNativeDashboardRequest ===
    # Fields for InstallFeaturedContentNativeDashboardRequest
    # Field: name Type: 9 ()
    # Field: featured_content_native_dashboard Type: 11 (.google.cloud.chronicle.v1.FeaturedContentNativeDashboard)

# === Message: Google::Cloud::Chronicle::V1::FeaturedContentNativeDashboard::InstallFeaturedContentNativeDashboardResponse ===
    # Fields for InstallFeaturedContentNativeDashboardResponse
    # Field: native_dashboard Type: 9 ()

# === Service Client: Google::Cloud::Chronicle::V1::FeaturedContentNativeDashboard::FeaturedContentNativeDashboardServiceClient ===
package Google::Cloud::Chronicle::V1::FeaturedContentNativeDashboard::FeaturedContentNativeDashboardServiceClient;

=pod

=head2 Service Client: Google::Cloud::Chronicle::V1::FeaturedContentNativeDashboard::FeaturedContentNativeDashboardServiceClient

Client stub representing the remote C<FeaturedContentNativeDashboardService> gRPC service. Delegates call dispatching to L<Google::gRPC::Client>.

=head3 target

The endpoint target address. Defaults to C<chronicle.googleapis.com:443>.

=head3 credentials

The authentication credentials provider. Defaults to application default credentials via L<Google::Auth>.

=cut

use Moo;
use Google::Auth;
use Google::gRPC::Client;

has credentials => ( is => 'ro', default => sub { Google::Auth->default() } );
has target      => ( is => 'ro', default => 'chronicle.googleapis.com:443' );

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

sub get_featured_content_native_dashboard {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Chronicle::V1::FeaturedContentNativeDashboard::GetFeaturedContentNativeDashboardRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.chronicle.v1.FeaturedContentNativeDashboardService',
        method         => 'GetFeaturedContentNativeDashboard',
        request        => $req,
        response_class => 'Google::Cloud::Chronicle::V1::FeaturedContentNativeDashboard::FeaturedContentNativeDashboard',
    });
}

sub list_featured_content_native_dashboards {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Chronicle::V1::FeaturedContentNativeDashboard::ListFeaturedContentNativeDashboardsRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.chronicle.v1.FeaturedContentNativeDashboardService',
        method         => 'ListFeaturedContentNativeDashboards',
        request        => $req,
        response_class => 'Google::Cloud::Chronicle::V1::FeaturedContentNativeDashboard::ListFeaturedContentNativeDashboardsResponse',
    });
}

sub install_featured_content_native_dashboard {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Chronicle::V1::FeaturedContentNativeDashboard::InstallFeaturedContentNativeDashboardRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.chronicle.v1.FeaturedContentNativeDashboardService',
        method         => 'InstallFeaturedContentNativeDashboard',
        request        => $req,
        response_class => 'Google::Cloud::Chronicle::V1::FeaturedContentNativeDashboard::InstallFeaturedContentNativeDashboardResponse',
    });
}

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Chronicle::V1::FeaturedContentNativeDashboard - Compiled Protocol Buffers messages for google/cloud/chronicle/v1/featured_content_native_dashboard.proto

=head1 SYNOPSIS

    use Google::Cloud::Chronicle::V1::FeaturedContentNativeDashboard;

    my $msg = Google::Cloud::Chronicle::V1::FeaturedContentNativeDashboard::FeaturedContentNativeDashboard->new({
        name => $name,
        content_metadata => $content_metadata,
        dashboard_content => $dashboard_content,
    });

    # Read or update a field
    my $val = $msg->name();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Chronicle::V1::FeaturedContentNativeDashboard::FeaturedContentNativeDashboard->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/chronicle/v1/featured_content_native_dashboard.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Chronicle::V1::FeaturedContentNativeDashboard::FeaturedContentNativeDashboard

FeaturedContentNativeDashboard resource.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Identifier. The resource name of the FeaturedContentNativeDashboard.
Format:
projects/{project}/locations/{location}/instances/{instance}/contentHub/featuredContentNativeDashboards/{featured_content_native_dashboard}

=item * C<< $msg->content_metadata() >> / C<< $msg->content_metadata($value) >>

Type: C<Message> (L<Google::Cloud::Chronicle::V1::FeaturedContentMetadata::FeaturedContentMetadata>)

Output only. Metadata about the FeaturedContentNativeDashboard.

=item * C<< $msg->dashboard_content() >> / C<< $msg->dashboard_content($value) >>

Type: C<Message> (L<Google::Cloud::Chronicle::V1::NativeDashboard::NativeDashboardWithChartsAndQueries>)

Optional. The dashboard content.

=back

=head2 Google::Cloud::Chronicle::V1::FeaturedContentNativeDashboard::GetFeaturedContentNativeDashboardRequest

Request message to get a FeaturedContentNativeDashboard.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. The resource name of the FeaturedContentNativeDashboard to
retrieve. Format:
projects/{project}/locations/{location}/instances/{instance}/contentHub/featuredContentNativeDashboards/{featured_content_native_dashboard}

=back

=head2 Google::Cloud::Chronicle::V1::FeaturedContentNativeDashboard::ListFeaturedContentNativeDashboardsRequest

Request message to list FeaturedContentNativeDashboards.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->parent() >> / C<< $msg->parent($value) >>

Type: C<String>

Required. The parent, which owns this collection of
FeaturedContentNativeDashboards. Format:
projects/{project}/locations/{location}/instances/{instance}/contentHub

=item * C<< $msg->page_size() >> / C<< $msg->page_size($value) >>

Type: C<Int32>

Optional. The maximum number of FeaturedContentNativeDashboards to return.
The service may return fewer than this value. If unspecified, at most 100
FeaturedContentNativeDashboards will be returned. The maximum value is 100;
values above 100 will be coerced to 100.

=item * C<< $msg->page_token() >> / C<< $msg->page_token($value) >>

Type: C<String>

Optional. A page token, received from a previous
`ListFeaturedContentNativeDashboards` call. Provide this to retrieve the
subsequent page.

When paginating, all other parameters provided to
`ListFeaturedContentNativeDashboards` must match the call that provided the
page token.

=item * C<< $msg->filter() >> / C<< $msg->filter($value) >>

Type: C<String>

Optional. The filter to apply to list the FeaturedContentNativeDashboards.

The filter syntax follows Google Cloud syntax: https://google.aip.dev/160.

Supported fields for filtering:

*   `name`: The resource name of the featured content.
*   `content_metadata.description`: The description of the featured
content.

When a literal value is provided without a field, it will perform a
substring search across both `name` and `content_metadata.description`.

Examples:

*   `"test"`: Matches featured content where either the name or description
    contains "test" as a substring.
*   `name="test"`: Matches featured content where the name contains "test".
*   `content_metadata.description="test"`: Matches featured content where
    the description contains "test".

=back

=head2 Google::Cloud::Chronicle::V1::FeaturedContentNativeDashboard::ListFeaturedContentNativeDashboardsResponse

Response message for listing FeaturedContentNativeDashboards.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->featured_content_native_dashboards() >> / C<< $msg->featured_content_native_dashboards($value) >>

Type: C<Message> (L<Google::Cloud::Chronicle::V1::FeaturedContentNativeDashboard::FeaturedContentNativeDashboard>)

The list of FeaturedContentNativeDashboards.
Ordered by name by default.

=item * C<< $msg->next_page_token() >> / C<< $msg->next_page_token($value) >>

Type: C<String>

A token, which can be sent as `page_token` to retrieve the next page.
If this field is omitted, there are no subsequent pages.

=back

=head2 Google::Cloud::Chronicle::V1::FeaturedContentNativeDashboard::InstallFeaturedContentNativeDashboardRequest

Request message to install a FeaturedContentNativeDashboard.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. The resource name of the FeaturedContentNativeDashboard to
install. Format:
projects/{project}/locations/{location}/instances/{instance}/contentHub/featuredContentNativeDashboards/{featured_content_native_dashboard}

=item * C<< $msg->featured_content_native_dashboard() >> / C<< $msg->featured_content_native_dashboard($value) >>

Type: C<Message> (L<Google::Cloud::Chronicle::V1::FeaturedContentNativeDashboard::FeaturedContentNativeDashboard>)

Optional. The FeaturedContentNativeDashboard to install.

=back

=head2 Google::Cloud::Chronicle::V1::FeaturedContentNativeDashboard::InstallFeaturedContentNativeDashboardResponse

Response message for installing a FeaturedContentNativeDashboard.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->native_dashboard() >> / C<< $msg->native_dashboard($value) >>

Type: C<String>

Optional. The resource name of the NativeDashboard created.
Format:
projects/{project}/locations/{location}/instances/{instance}/nativeDashboards/{native_dashboard_id}

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Chronicle::V1::FeaturedContentNativeDashboard::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
