package Google::Cloud::Networksecurity::V1::AuthorizationPolicy;

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
    eval { require Google::Protobuf::FieldMask };
    eval { require Google::Protobuf::Timestamp };
    my $descriptor_b64 = <<'EOF';
Cjpnb29nbGUvY2xvdWQvbmV0d29ya3NlY3VyaXR5L3YxL2F1dGhvcml6YXRpb25fcG9saWN5
LnByb3RvEh9nb29nbGUuY2xvdWQubmV0d29ya3NlY3VyaXR5LnYxGh9nb29nbGUvYXBpL2Zp
ZWxkX2JlaGF2aW9yLnByb3RvGhlnb29nbGUvYXBpL3Jlc291cmNlLnByb3RvGiBnb29nbGUv
cHJvdG9idWYvZmllbGRfbWFzay5wcm90bxofZ29vZ2xlL3Byb3RvYnVmL3RpbWVzdGFtcC5w
cm90byLtCgoTQXV0aG9yaXphdGlvblBvbGljeRIXCgRuYW1lGAEgASgJQgPgQQJSBG5hbWUS
JQoLZGVzY3JpcHRpb24YAiABKAlCA+BBAVILZGVzY3JpcHRpb24SQAoLY3JlYXRlX3RpbWUY
AyABKAsyGi5nb29nbGUucHJvdG9idWYuVGltZXN0YW1wQgPgQQNSCmNyZWF0ZVRpbWUSQAoL
dXBkYXRlX3RpbWUYBCABKAsyGi5nb29nbGUucHJvdG9idWYuVGltZXN0YW1wQgPgQQNSCnVw
ZGF0ZVRpbWUSXQoGbGFiZWxzGAUgAygLMkAuZ29vZ2xlLmNsb3VkLm5ldHdvcmtzZWN1cml0
eS52MS5BdXRob3JpemF0aW9uUG9saWN5LkxhYmVsc0VudHJ5QgPgQQFSBmxhYmVscxJYCgZh
Y3Rpb24YBiABKA4yOy5nb29nbGUuY2xvdWQubmV0d29ya3NlY3VyaXR5LnYxLkF1dGhvcml6
YXRpb25Qb2xpY3kuQWN0aW9uQgPgQQJSBmFjdGlvbhJUCgVydWxlcxgHIAMoCzI5Lmdvb2ds
ZS5jbG91ZC5uZXR3b3Jrc2VjdXJpdHkudjEuQXV0aG9yaXphdGlvblBvbGljeS5SdWxlQgPg
QQFSBXJ1bGVzGv8ECgRSdWxlEl8KB3NvdXJjZXMYASADKAsyQC5nb29nbGUuY2xvdWQubmV0
d29ya3NlY3VyaXR5LnYxLkF1dGhvcml6YXRpb25Qb2xpY3kuUnVsZS5Tb3VyY2VCA+BBAVIH
c291cmNlcxJuCgxkZXN0aW5hdGlvbnMYAiADKAsyRS5nb29nbGUuY2xvdWQubmV0d29ya3Nl
Y3VyaXR5LnYxLkF1dGhvcml6YXRpb25Qb2xpY3kuUnVsZS5EZXN0aW5hdGlvbkID4EEBUgxk
ZXN0aW5hdGlvbnMaTwoGU291cmNlEiMKCnByaW5jaXBhbHMYASADKAlCA+BBAVIKcHJpbmNp
cGFscxIgCglpcF9ibG9ja3MYAiADKAlCA+BBAVIIaXBCbG9ja3Ma1AIKC0Rlc3RpbmF0aW9u
EhkKBWhvc3RzGAEgAygJQgPgQQJSBWhvc3RzEhkKBXBvcnRzGAIgAygNQgPgQQJSBXBvcnRz
Eh0KB21ldGhvZHMYBCADKAlCA+BBAVIHbWV0aG9kcxKGAQoRaHR0cF9oZWFkZXJfbWF0Y2gY
BSABKAsyVS5nb29nbGUuY2xvdWQubmV0d29ya3NlY3VyaXR5LnYxLkF1dGhvcml6YXRpb25Q
b2xpY3kuUnVsZS5EZXN0aW5hdGlvbi5IdHRwSGVhZGVyTWF0Y2hCA+BBAVIPaHR0cEhlYWRl
ck1hdGNoGmcKD0h0dHBIZWFkZXJNYXRjaBImCgtyZWdleF9tYXRjaBgCIAEoCUID4EECSABS
CnJlZ2V4TWF0Y2gSJAoLaGVhZGVyX25hbWUYASABKAlCA+BBAlIKaGVhZGVyTmFtZUIGCgR0
eXBlGjkKC0xhYmVsc0VudHJ5EhAKA2tleRgBIAEoCVIDa2V5EhQKBXZhbHVlGAIgASgJUgV2
YWx1ZToCOAEiNQoGQWN0aW9uEhYKEkFDVElPTl9VTlNQRUNJRklFRBAAEgkKBUFMTE9XEAES
CAoEREVOWRACOo4B6kGKAQoybmV0d29ya3NlY3VyaXR5Lmdvb2dsZWFwaXMuY29tL0F1dGhv
cml6YXRpb25Qb2xpY3kSVHByb2plY3RzL3twcm9qZWN0fS9sb2NhdGlvbnMve2xvY2F0aW9u
fS9hdXRob3JpemF0aW9uUG9saWNpZXMve2F1dGhvcml6YXRpb25fcG9saWN5fSKhAQogTGlz
dEF1dGhvcml6YXRpb25Qb2xpY2llc1JlcXVlc3QSQQoGcGFyZW50GAEgASgJQingQQL6QSMK
IWxvY2F0aW9ucy5nb29nbGVhcGlzLmNvbS9Mb2NhdGlvblIGcGFyZW50EhsKCXBhZ2Vfc2l6
ZRgCIAEoBVIIcGFnZVNpemUSHQoKcGFnZV90b2tlbhgDIAEoCVIJcGFnZVRva2VuIrgBCiFM
aXN0QXV0aG9yaXphdGlvblBvbGljaWVzUmVzcG9uc2USawoWYXV0aG9yaXphdGlvbl9wb2xp
Y2llcxgBIAMoCzI0Lmdvb2dsZS5jbG91ZC5uZXR3b3Jrc2VjdXJpdHkudjEuQXV0aG9yaXph
dGlvblBvbGljeVIVYXV0aG9yaXphdGlvblBvbGljaWVzEiYKD25leHRfcGFnZV90b2tlbhgC
IAEoCVINbmV4dFBhZ2VUb2tlbiJvCh1HZXRBdXRob3JpemF0aW9uUG9saWN5UmVxdWVzdBJO
CgRuYW1lGAEgASgJQjrgQQL6QTQKMm5ldHdvcmtzZWN1cml0eS5nb29nbGVhcGlzLmNvbS9B
dXRob3JpemF0aW9uUG9saWN5UgRuYW1lIqECCiBDcmVhdGVBdXRob3JpemF0aW9uUG9saWN5
UmVxdWVzdBJSCgZwYXJlbnQYASABKAlCOuBBAvpBNBIybmV0d29ya3NlY3VyaXR5Lmdvb2ds
ZWFwaXMuY29tL0F1dGhvcml6YXRpb25Qb2xpY3lSBnBhcmVudBI7ChdhdXRob3JpemF0aW9u
X3BvbGljeV9pZBgCIAEoCUID4EECUhVhdXRob3JpemF0aW9uUG9saWN5SWQSbAoUYXV0aG9y
aXphdGlvbl9wb2xpY3kYAyABKAsyNC5nb29nbGUuY2xvdWQubmV0d29ya3NlY3VyaXR5LnYx
LkF1dGhvcml6YXRpb25Qb2xpY3lCA+BBAlITYXV0aG9yaXphdGlvblBvbGljeSLSAQogVXBk
YXRlQXV0aG9yaXphdGlvblBvbGljeVJlcXVlc3QSQAoLdXBkYXRlX21hc2sYASABKAsyGi5n
b29nbGUucHJvdG9idWYuRmllbGRNYXNrQgPgQQFSCnVwZGF0ZU1hc2sSbAoUYXV0aG9yaXph
dGlvbl9wb2xpY3kYAiABKAsyNC5nb29nbGUuY2xvdWQubmV0d29ya3NlY3VyaXR5LnYxLkF1
dGhvcml6YXRpb25Qb2xpY3lCA+BBAlITYXV0aG9yaXphdGlvblBvbGljeSJyCiBEZWxldGVB
dXRob3JpemF0aW9uUG9saWN5UmVxdWVzdBJOCgRuYW1lGAEgASgJQjrgQQL6QTQKMm5ldHdv
cmtzZWN1cml0eS5nb29nbGVhcGlzLmNvbS9BdXRob3JpemF0aW9uUG9saWN5UgRuYW1lQvkB
CiNjb20uZ29vZ2xlLmNsb3VkLm5ldHdvcmtzZWN1cml0eS52MUIYQXV0aG9yaXphdGlvblBv
bGljeVByb3RvUAFaTWNsb3VkLmdvb2dsZS5jb20vZ28vbmV0d29ya3NlY3VyaXR5L2FwaXYx
L25ldHdvcmtzZWN1cml0eXBiO25ldHdvcmtzZWN1cml0eXBiqgIfR29vZ2xlLkNsb3VkLk5l
dHdvcmtTZWN1cml0eS5WMcoCH0dvb2dsZVxDbG91ZFxOZXR3b3JrU2VjdXJpdHlcVjHqAiJH
b29nbGU6OkNsb3VkOjpOZXR3b3JrU2VjdXJpdHk6OlYxSqpTCgcSBQ4AggIBCrwECgEMEgMO
ABIysQQgQ29weXJpZ2h0IDIwMjYgR29vZ2xlIExMQwoKIExpY2Vuc2VkIHVuZGVyIHRoZSBB
cGFjaGUgTGljZW5zZSwgVmVyc2lvbiAyLjAgKHRoZSAiTGljZW5zZSIpOwogeW91IG1heSBu
b3QgdXNlIHRoaXMgZmlsZSBleGNlcHQgaW4gY29tcGxpYW5jZSB3aXRoIHRoZSBMaWNlbnNl
LgogWW91IG1heSBvYnRhaW4gYSBjb3B5IG9mIHRoZSBMaWNlbnNlIGF0CgogICAgIGh0dHA6
Ly93d3cuYXBhY2hlLm9yZy9saWNlbnNlcy9MSUNFTlNFLTIuMAoKIFVubGVzcyByZXF1aXJl
ZCBieSBhcHBsaWNhYmxlIGxhdyBvciBhZ3JlZWQgdG8gaW4gd3JpdGluZywgc29mdHdhcmUK
IGRpc3RyaWJ1dGVkIHVuZGVyIHRoZSBMaWNlbnNlIGlzIGRpc3RyaWJ1dGVkIG9uIGFuICJB
UyBJUyIgQkFTSVMsCiBXSVRIT1VUIFdBUlJBTlRJRVMgT1IgQ09ORElUSU9OUyBPRiBBTlkg
S0lORCwgZWl0aGVyIGV4cHJlc3Mgb3IgaW1wbGllZC4KIFNlZSB0aGUgTGljZW5zZSBmb3Ig
dGhlIHNwZWNpZmljIGxhbmd1YWdlIGdvdmVybmluZyBwZXJtaXNzaW9ucyBhbmQKIGxpbWl0
YXRpb25zIHVuZGVyIHRoZSBMaWNlbnNlLgoKCAoBAhIDEAAoCgkKAgMAEgMSACkKCQoCAwES
AxMAIwoJCgIDAhIDFAAqCgkKAgMDEgMVACkKCAoBCBIDFwA8CgkKAgglEgMXADwKCAoBCBID
GABkCgkKAggLEgMYAGQKCAoBCBIDGQAiCgkKAggKEgMZACIKCAoBCBIDGgA5CgkKAggIEgMa
ADkKCAoBCBIDGwA8CgkKAggBEgMbADwKCAoBCBIDHAA8CgkKAggpEgMcADwKCAoBCBIDHQA7
CgkKAggtEgMdADsKhAIKAgQAEgUjAKQBARr2ASBBdXRob3JpemF0aW9uUG9saWN5IGlzIGEg
cmVzb3VyY2UgdGhhdCBzcGVjaWZpZXMgaG93IGEgc2VydmVyCiBzaG91bGQgYXV0aG9yaXpl
IGluY29taW5nIGNvbm5lY3Rpb25zLiBUaGlzIHJlc291cmNlIGluIGl0c2VsZiBkb2VzCiBu
b3QgY2hhbmdlIHRoZSBjb25maWd1cmF0aW9uIHVubGVzcyBpdCdzIGF0dGFjaGVkIHRvIGEg
dGFyZ2V0IGh0dHBzCiBwcm94eSBvciBlbmRwb2ludCBjb25maWcgc2VsZWN0b3IgcmVzb3Vy
Y2UuCgoKCgMEAAESAyMIGwoLCgMEAAcSBCQCJwQKDQoFBAAHnQgSBCQCJwQKJwoEBAADABIE
KgJ3AxoZIFNwZWNpZmljYXRpb24gb2YgcnVsZXMuCgoMCgUEAAMAARIDKgoOCj0KBgQAAwAD
ABIELAQ7BRotIFNwZWNpZmljYXRpb24gb2YgdHJhZmZpYyBzb3VyY2UgYXR0cmlidXRlcy4K
Cg4KBwQAAwADAAESAywMEgqbAwoIBAADAAMAAgASAzMGThqJAyBPcHRpb25hbC4gTGlzdCBv
ZiBwZWVyIGlkZW50aXRpZXMgdG8gbWF0Y2ggZm9yIGF1dGhvcml6YXRpb24uIEF0IGxlYXN0
CiBvbmUgcHJpbmNpcGFsIHNob3VsZCBtYXRjaC4gRWFjaCBwZWVyIGNhbiBiZSBhbiBleGFj
dCBtYXRjaCwgb3IgYQogcHJlZml4IG1hdGNoIChleGFtcGxlLCAibmFtZXNwYWNlLyoiKSBv
ciBhIHN1ZmZpeCBtYXRjaCAoZXhhbXBsZSwKICIqL3NlcnZpY2UtYWNjb3VudCIpIG9yIGEg
cHJlc2VuY2UgbWF0Y2ggIioiLiBBdXRob3JpemF0aW9uIGJhc2VkIG9uCiB0aGUgcHJpbmNp
cGFsIG5hbWUgd2l0aG91dCBjZXJ0aWZpY2F0ZSB2YWxpZGF0aW9uIChjb25maWd1cmVkIGJ5
CiBTZXJ2ZXJUbHNQb2xpY3kgcmVzb3VyY2UpIGlzIGNvbnNpZGVyZWQgaW5zZWN1cmUuCgoQ
CgkEAAMAAwACAAQSAzMGDgoQCgkEAAMAAwACAAUSAzMPFQoQCgkEAAMAAwACAAESAzMWIAoQ
CgkEAAMAAwACAAMSAzMjJAoQCgkEAAMAAwACAAgSAzMlTQoTCgwEAAMAAwACAAicCAASAzMm
TArTAgoIBAADAAMAAgESAzoGTRrBAiBPcHRpb25hbC4gTGlzdCBvZiBDSURSIHJhbmdlcyB0
byBtYXRjaCBiYXNlZCBvbiBzb3VyY2UgSVAgYWRkcmVzcy4gQXQKIGxlYXN0IG9uZSBJUCBi
bG9jayBzaG91bGQgbWF0Y2guIFNpbmdsZSBJUCAoZS5nLiwgIjEuMi4zLjQiKSBhbmQgQ0lE
UgogKGUuZy4sICIxLjIuMy4wLzI0IikgYXJlIHN1cHBvcnRlZC4gQXV0aG9yaXphdGlvbiBi
YXNlZCBvbiBzb3VyY2UgSVAKIGFsb25lIHNob3VsZCBiZSBhdm9pZGVkLiBUaGUgSVAgYWRk
cmVzc2VzIG9mIGFueSBsb2FkIGJhbGFuY2VycyBvcgogcHJveGllcyBzaG91bGQgYmUgY29u
c2lkZXJlZCB1bnRydXN0ZWQuCgoQCgkEAAMAAwACAQQSAzoGDgoQCgkEAAMAAwACAQUSAzoP
FQoQCgkEAAMAAwACAQESAzoWHwoQCgkEAAMAAwACAQMSAzoiIwoQCgkEAAMAAwACAQgSAzok
TAoTCgwEAAMAAwACAQicCAASAzolSwpCCgYEAAMAAwESBD4EaAUaMiBTcGVjaWZpY2F0aW9u
IG9mIHRyYWZmaWMgZGVzdGluYXRpb24gYXR0cmlidXRlcy4KCg4KBwQAAwADAQESAz4MFwpC
CggEAAMAAwEDABIEQAZRBxowIFNwZWNpZmljYXRpb24gb2YgSFRUUCBoZWFkZXIgbWF0Y2gg
YXR0cmlidXRlcy4KChAKCQQAAwADAQMAARIDQA4dChIKCgQAAwADAQMACAASBEEISgkKEgoL
BAADAAMBAwAIAAESA0EOEgqKAwoKBAADAAMBAwACABIDSQpKGvYCIFJlcXVpcmVkLiBUaGUg
dmFsdWUgb2YgdGhlIGhlYWRlciBtdXN0IG1hdGNoIHRoZSByZWd1bGFyIGV4cHJlc3Npb24K
IHNwZWNpZmllZCBpbiByZWdleE1hdGNoLiBGb3IgcmVndWxhciBleHByZXNzaW9uIGdyYW1t
YXIsCiBwbGVhc2Ugc2VlOiBlbi5jcHByZWZlcmVuY2UuY29tL3cvY3BwL3JlZ2V4L2VjbWFz
Y3JpcHQKIEZvciBtYXRjaGluZyBhZ2FpbnN0IGEgcG9ydCBzcGVjaWZpZWQgaW4gdGhlIEhU
VFAKIHJlcXVlc3QsIHVzZSBhIGhlYWRlck1hdGNoIHdpdGggaGVhZGVyTmFtZSBzZXQgdG8g
SG9zdAogYW5kIGEgcmVndWxhciBleHByZXNzaW9uIHRoYXQgc2F0aXNmaWVzIHRoZSBSRkMy
NjE2IEhvc3QKIGhlYWRlcidzIHBvcnQgc3BlY2lmaWVyLgoKEgoLBAADAAMBAwACAAUSA0kK
EAoSCgsEAAMAAwEDAAIAARIDSREcChIKCwQAAwADAQMAAgADEgNJHyAKEgoLBAADAAMBAwAC
AAgSA0khSQoVCg4EAAMAAwEDAAIACJwIABIDSSJICu8BCgoEAAMAAwEDAAIBEgNQCEga2wEg
UmVxdWlyZWQuIFRoZSBuYW1lIG9mIHRoZSBIVFRQIGhlYWRlciB0byBtYXRjaC4gRm9yIG1h
dGNoaW5nCiBhZ2FpbnN0IHRoZSBIVFRQIHJlcXVlc3QncyBhdXRob3JpdHksIHVzZSBhIGhl
YWRlck1hdGNoCiB3aXRoIHRoZSBoZWFkZXIgbmFtZSAiOmF1dGhvcml0eSIuIEZvciBtYXRj
aGluZyBhCiByZXF1ZXN0J3MgbWV0aG9kLCB1c2UgdGhlIGhlYWRlck5hbWUgIjptZXRob2Qi
LgoKEgoLBAADAAMBAwACAQUSA1AIDgoSCgsEAAMAAwEDAAIBARIDUA8aChIKCwQAAwADAQMA
AgEDEgNQHR4KEgoLBAADAAMBAwACAQgSA1AfRwoVCg4EAAMAAwEDAAIBCJwIABIDUCBGCqoC
CggEAAMAAwECABIDVwZJGpgCIFJlcXVpcmVkLiBMaXN0IG9mIGhvc3QgbmFtZXMgdG8gbWF0
Y2guIE1hdGNoZWQgYWdhaW5zdCB0aGUgIjphdXRob3JpdHkiCiBoZWFkZXIgaW4gaHR0cCBy
ZXF1ZXN0cy4gQXQgbGVhc3Qgb25lIGhvc3Qgc2hvdWxkIG1hdGNoLiBFYWNoIGhvc3QgY2Fu
CiBiZSBhbiBleGFjdCBtYXRjaCwgb3IgYSBwcmVmaXggbWF0Y2ggKGV4YW1wbGUgIm15ZG9t
YWluLioiKSBvciBhIHN1ZmZpeAogbWF0Y2ggKGV4YW1wbGUgIioubXlvcmcuY29tIikgb3Ig
YSBwcmVzZW5jZSAoYW55KSBtYXRjaCAiKiIuCgoQCgkEAAMAAwECAAQSA1cGDgoQCgkEAAMA
AwECAAUSA1cPFQoQCgkEAAMAAwECAAESA1cWGwoQCgkEAAMAAwECAAMSA1ceHwoQCgkEAAMA
AwECAAgSA1cgSAoTCgwEAAMAAwECAAicCAASA1chRwphCggEAAMAAwECARIDWwZJGlAgUmVx
dWlyZWQuIExpc3Qgb2YgZGVzdGluYXRpb24gcG9ydHMgdG8gbWF0Y2guIEF0IGxlYXN0IG9u
ZSBwb3J0IHNob3VsZAogbWF0Y2guCgoQCgkEAAMAAwECAQQSA1sGDgoQCgkEAAMAAwECAQUS
A1sPFQoQCgkEAAMAAwECAQESA1sWGwoQCgkEAAMAAwECAQMSA1seHwoQCgkEAAMAAwECAQgS
A1sgSAoTCgwEAAMAAwECAQicCAASA1shRwqFAQoIBAADAAMBAgISA18GSxp0IE9wdGlvbmFs
LiBBIGxpc3Qgb2YgSFRUUCBtZXRob2RzIHRvIG1hdGNoLiBBdCBsZWFzdCBvbmUgbWV0aG9k
IHNob3VsZAogbWF0Y2guIFNob3VsZCBub3QgYmUgc2V0IGZvciBnUlBDIHNlcnZpY2VzLgoK
EAoJBAADAAMBAgIEEgNfBg4KEAoJBAADAAMBAgIFEgNfDxUKEAoJBAADAAMBAgIBEgNfFh0K
EAoJBAADAAMBAgIDEgNfICEKEAoJBAADAAMBAgIIEgNfIkoKEwoMBAADAAMBAgIInAgAEgNf
I0kK3AIKCAQAAwADAQIDEgRmBmczGskCIE9wdGlvbmFsLiBNYXRjaCBhZ2FpbnN0IGtleTp2
YWx1ZSBwYWlyIGluIGh0dHAgaGVhZGVyLiBQcm92aWRlcyBhCiBmbGV4aWJsZSBtYXRjaCBi
YXNlZCBvbiBIVFRQIGhlYWRlcnMsIGZvciBwb3RlbnRpYWxseSBhZHZhbmNlZCB1c2UKIGNh
c2VzLiBBdCBsZWFzdCBvbmUgaGVhZGVyIHNob3VsZCBtYXRjaC4gQXZvaWQgdXNpbmcgaGVh
ZGVyIG1hdGNoZXMgdG8KIG1ha2UgYXV0aG9yaXphdGlvbiBkZWNpc2lvbnMgdW5sZXNzIHRo
ZXJlIGlzIGEgc3Ryb25nIGd1YXJhbnRlZSB0aGF0CiByZXF1ZXN0cyBhcnJpdmUgdGhyb3Vn
aCBhIHRydXN0ZWQgY2xpZW50IG9yIHByb3h5LgoKEAoJBAADAAMBAgMGEgNmBhUKEAoJBAAD
AAMBAgMBEgNmFicKEAoJBAADAAMBAgMDEgNmKisKEAoJBAADAAMBAgMIEgNnCjIKEwoMBAAD
AAMBAgMInAgAEgNnCzEKkwIKBgQAAwACABIDbgRJGoMCIE9wdGlvbmFsLiBMaXN0IG9mIGF0
dHJpYnV0ZXMgZm9yIHRoZSB0cmFmZmljIHNvdXJjZS4gQWxsIG9mIHRoZSBzb3VyY2VzCiBt
dXN0IG1hdGNoLiBBIHNvdXJjZSBpcyBhIG1hdGNoIGlmIGJvdGggcHJpbmNpcGFscyBhbmQg
aXBfYmxvY2tzIG1hdGNoLgogSWYgbm90IHNldCwgdGhlIGFjdGlvbiBzcGVjaWZpZWQgaW4g
dGhlICdhY3Rpb24nIGZpZWxkIHdpbGwgYmUgYXBwbGllZAogd2l0aG91dCBhbnkgcnVsZSBj
aGVja3MgZm9yIHRoZSBzb3VyY2UuCgoOCgcEAAMAAgAEEgNuBAwKDgoHBAADAAIABhIDbg0T
Cg4KBwQAAwACAAESA24UGwoOCgcEAAMAAgADEgNuHh8KDgoHBAADAAIACBIDbiBIChEKCgQA
AwACAAicCAASA24hRwrLAgoGBAADAAIBEgR1BHYxGroCIE9wdGlvbmFsLiBMaXN0IG9mIGF0
dHJpYnV0ZXMgZm9yIHRoZSB0cmFmZmljIGRlc3RpbmF0aW9uLiBBbGwgb2YgdGhlCiBkZXN0
aW5hdGlvbnMgbXVzdCBtYXRjaC4gQSBkZXN0aW5hdGlvbiBpcyBhIG1hdGNoIGlmIGEgcmVx
dWVzdCBtYXRjaGVzCiBhbGwgdGhlIHNwZWNpZmllZCBob3N0cywgcG9ydHMsIG1ldGhvZHMg
YW5kIGhlYWRlcnMuIElmIG5vdCBzZXQsIHRoZQogYWN0aW9uIHNwZWNpZmllZCBpbiB0aGUg
J2FjdGlvbicgZmllbGQgd2lsbCBiZSBhcHBsaWVkIHdpdGhvdXQgYW55IHJ1bGUKIGNoZWNr
cyBmb3IgdGhlIGRlc3RpbmF0aW9uLgoKDgoHBAADAAIBBBIDdQQMCg4KBwQAAwACAQYSA3UN
GAoOCgcEAAMAAgEBEgN1GSUKDgoHBAADAAIBAxIDdSgpCg4KBwQAAwACAQgSA3YIMAoRCgoE
AAMAAgEInAgAEgN2CS8KQQoEBAAEABIFegKFAQMaMiBQb3NzaWJsZSB2YWx1ZXMgdGhhdCBk
ZWZpbmUgd2hhdCBhY3Rpb24gdG8gdGFrZS4KCgwKBQQABAABEgN6Bw0KHwoGBAAEAAIAEgN8
BBsaECBEZWZhdWx0IHZhbHVlLgoKDgoHBAAEAAIAARIDfAQWCg4KBwQABAACAAISA3wZGgoe
CgYEAAQAAgESA38EDhoPIEdyYW50IGFjY2Vzcy4KCg4KBwQABAACAQESA38ECQoOCgcEAAQA
AgECEgN/DA0KfAoGBAAEAAICEgSEAQQNGmwgRGVueSBhY2Nlc3MuCiBEZW55IHJ1bGVzIHNo
b3VsZCBiZSBhdm9pZGVkIHVubGVzcyB0aGV5IGFyZSB1c2VkIHRvIHByb3ZpZGUgYSBkZWZh
dWx0CiAiZGVueSBhbGwiIGZhbGxiYWNrLgoKDwoHBAAEAAICARIEhAEECAoPCgcEAAQAAgIC
EgSEAQsMCrABCgQEAAIAEgSJAQI7GqEBIFJlcXVpcmVkLiBOYW1lIG9mIHRoZSBBdXRob3Jp
emF0aW9uUG9saWN5IHJlc291cmNlLiBJdCBtYXRjaGVzIHBhdHRlcm4KIGBwcm9qZWN0cy97
cHJvamVjdH0vbG9jYXRpb25zL3tsb2NhdGlvbn0vYXV0aG9yaXphdGlvblBvbGljaWVzLzxh
dXRob3JpemF0aW9uX3BvbGljeT5gLgoKDQoFBAACAAUSBIkBAggKDQoFBAACAAESBIkBCQ0K
DQoFBAACAAMSBIkBEBEKDQoFBAACAAgSBIkBEjoKEAoIBAACAAicCAASBIkBEzkKQAoEBAAC
ARIEjAECQhoyIE9wdGlvbmFsLiBGcmVlLXRleHQgZGVzY3JpcHRpb24gb2YgdGhlIHJlc291
cmNlLgoKDQoFBAACAQUSBIwBAggKDQoFBAACAQESBIwBCRQKDQoFBAACAQMSBIwBFxgKDQoF
BAACAQgSBIwBGUEKEAoIBAACAQicCAASBIwBGkAKSwoEBAACAhIGjwECkAEyGjsgT3V0cHV0
IG9ubHkuIFRoZSB0aW1lc3RhbXAgd2hlbiB0aGUgcmVzb3VyY2Ugd2FzIGNyZWF0ZWQuCgoN
CgUEAAICBhIEjwECGwoNCgUEAAICARIEjwEcJwoNCgUEAAICAxIEjwEqKwoNCgUEAAICCBIE
kAEGMQoQCggEAAICCJwIABIEkAEHMApLCgQEAAIDEgaTAQKUATIaOyBPdXRwdXQgb25seS4g
VGhlIHRpbWVzdGFtcCB3aGVuIHRoZSByZXNvdXJjZSB3YXMgdXBkYXRlZC4KCg0KBQQAAgMG
EgSTAQIbCg0KBQQAAgMBEgSTARwnCg0KBQQAAgMDEgSTASorCg0KBQQAAgMIEgSUAQYxChAK
CAQAAgMInAgAEgSUAQcwCl4KBAQAAgQSBJgBAkoaUCBPcHRpb25hbC4gU2V0IG9mIGxhYmVs
IHRhZ3MgYXNzb2NpYXRlZCB3aXRoIHRoZSBBdXRob3JpemF0aW9uUG9saWN5CiByZXNvdXJj
ZS4KCg0KBQQAAgQGEgSYAQIVCg0KBQQAAgQBEgSYARYcCg0KBQQAAgQDEgSYAR8gCg0KBQQA
AgQIEgSYASFJChAKCAQAAgQInAgAEgSYASJICnAKBAQAAgUSBJwBAj0aYiBSZXF1aXJlZC4g
VGhlIGFjdGlvbiB0byB0YWtlIHdoZW4gYSBydWxlIG1hdGNoIGlzIGZvdW5kLiBQb3NzaWJs
ZSB2YWx1ZXMKIGFyZSAiQUxMT1ciIG9yICJERU5ZIi4KCg0KBQQAAgUGEgScAQIICg0KBQQA
AgUBEgScAQkPCg0KBQQAAgUDEgScARITCg0KBQQAAgUIEgScARQ8ChAKCAQAAgUInAgAEgSc
ARU7CscCCgQEAAIGEgSjAQJDGrgCIE9wdGlvbmFsLiBMaXN0IG9mIHJ1bGVzIHRvIG1hdGNo
LiBOb3RlIHRoYXQgYXQgbGVhc3Qgb25lIG9mIHRoZSBydWxlcyBtdXN0CiBtYXRjaCBpbiBv
cmRlciBmb3IgdGhlIGFjdGlvbiBzcGVjaWZpZWQgaW4gdGhlICdhY3Rpb24nIGZpZWxkIHRv
IGJlIHRha2VuLgogQSBydWxlIGlzIGEgbWF0Y2ggaWYgdGhlcmUgaXMgYSBtYXRjaGluZyBz
b3VyY2UgYW5kIGRlc3RpbmF0aW9uLiBJZiBsZWZ0CiBibGFuaywgdGhlIGFjdGlvbiBzcGVj
aWZpZWQgaW4gdGhlIGBhY3Rpb25gIGZpZWxkIHdpbGwgYmUgYXBwbGllZCBvbiBldmVyeQog
cmVxdWVzdC4KCg0KBQQAAgYEEgSjAQIKCg0KBQQAAgYGEgSjAQsPCg0KBQQAAgYBEgSjARAV
Cg0KBQQAAgYDEgSjARgZCg0KBQQAAgYIEgSjARpCChAKCAQAAgYInAgAEgSjARtBCkcKAgQB
EganAQC6AQEaOSBSZXF1ZXN0IHVzZWQgd2l0aCB0aGUgTGlzdEF1dGhvcml6YXRpb25Qb2xp
Y2llcyBtZXRob2QuCgoLCgMEAQESBKcBCCgKsQEKBAQBAgASBqsBArABBBqgASBSZXF1aXJl
ZC4gVGhlIHByb2plY3QgYW5kIGxvY2F0aW9uIGZyb20gd2hpY2ggdGhlIEF1dGhvcml6YXRp
b25Qb2xpY2llcwogc2hvdWxkIGJlIGxpc3RlZCwgc3BlY2lmaWVkIGluIHRoZSBmb3JtYXQK
IGBwcm9qZWN0cy97cHJvamVjdH0vbG9jYXRpb25zL3tsb2NhdGlvbn1gLgoKDQoFBAECAAUS
BKsBAggKDQoFBAECAAESBKsBCQ8KDQoFBAECAAMSBKsBEhMKDwoFBAECAAgSBqsBFLABAwoQ
CggEAQIACJwIABIErAEEKgoRCgcEAQIACJ8IEgatAQSvAQUKSwoEBAECARIEswECFho9IE1h
eGltdW0gbnVtYmVyIG9mIEF1dGhvcml6YXRpb25Qb2xpY2llcyB0byByZXR1cm4gcGVyIGNh
bGwuCgoNCgUEAQIBBRIEswECBwoNCgUEAQIBARIEswEIEQoNCgUEAQIBAxIEswEUFQriAQoE
BAECAhIEuQECGBrTASBUaGUgdmFsdWUgcmV0dXJuZWQgYnkgdGhlIGxhc3QKIGBMaXN0QXV0
aG9yaXphdGlvblBvbGljaWVzUmVzcG9uc2VgIEluZGljYXRlcyB0aGF0IHRoaXMgaXMgYQog
Y29udGludWF0aW9uIG9mIGEgcHJpb3IgYExpc3RBdXRob3JpemF0aW9uUG9saWNpZXNgIGNh
bGwsIGFuZAogdGhhdCB0aGUgc3lzdGVtIHNob3VsZCByZXR1cm4gdGhlIG5leHQgcGFnZSBv
ZiBkYXRhLgoKDQoFBAECAgUSBLkBAggKDQoFBAECAgESBLkBCRMKDQoFBAECAgMSBLkBFhcK
SgoCBAISBr0BAMUBARo8IFJlc3BvbnNlIHJldHVybmVkIGJ5IHRoZSBMaXN0QXV0aG9yaXph
dGlvblBvbGljaWVzIG1ldGhvZC4KCgsKAwQCARIEvQEIKQo4CgQEAgIAEgS/AQI6GiogTGlz
dCBvZiBBdXRob3JpemF0aW9uUG9saWNpZXMgcmVzb3VyY2VzLgoKDQoFBAICAAQSBL8BAgoK
DQoFBAICAAYSBL8BCx4KDQoFBAICAAESBL8BHzUKDQoFBAICAAMSBL8BODkK6QEKBAQCAgES
BMQBAh0a2gEgSWYgdGhlcmUgbWlnaHQgYmUgbW9yZSByZXN1bHRzIHRoYW4gdGhvc2UgYXBw
ZWFyaW5nIGluIHRoaXMgcmVzcG9uc2UsIHRoZW4KIGBuZXh0X3BhZ2VfdG9rZW5gIGlzIGlu
Y2x1ZGVkLiBUbyBnZXQgdGhlIG5leHQgc2V0IG9mIHJlc3VsdHMsIGNhbGwgdGhpcwogbWV0
aG9kIGFnYWluIHVzaW5nIHRoZSB2YWx1ZSBvZiBgbmV4dF9wYWdlX3Rva2VuYCBhcyBgcGFn
ZV90b2tlbmAuCgoNCgUEAgIBBRIExAECCAoNCgUEAgIBARIExAEJGAoNCgUEAgIBAxIExAEb
HApCCgIEAxIGyAEA0QEBGjQgUmVxdWVzdCB1c2VkIGJ5IHRoZSBHZXRBdXRob3JpemF0aW9u
UG9saWN5IG1ldGhvZC4KCgsKAwQDARIEyAEIJQqgAQoEBAMCABIGywEC0AEEGo8BIFJlcXVp
cmVkLiBBIG5hbWUgb2YgdGhlIEF1dGhvcml6YXRpb25Qb2xpY3kgdG8gZ2V0LiBNdXN0IGJl
IGluIHRoZSBmb3JtYXQKIGBwcm9qZWN0cy97cHJvamVjdH0vbG9jYXRpb25zL3tsb2NhdGlv
bn0vYXV0aG9yaXphdGlvblBvbGljaWVzLypgLgoKDQoFBAMCAAUSBMsBAggKDQoFBAMCAAES
BMsBCQ0KDQoFBAMCAAMSBMsBEBEKDwoFBAMCAAgSBssBEtABAwoQCggEAwIACJwIABIEzAEE
KgoRCgcEAwIACJ8IEgbNAQTPAQUKRQoCBAQSBtQBAOcBARo3IFJlcXVlc3QgdXNlZCBieSB0
aGUgQ3JlYXRlQXV0aG9yaXphdGlvblBvbGljeSBtZXRob2QuCgoLCgMEBAESBNQBCCgKjQEK
BAQEAgASBtcBAtwBBBp9IFJlcXVpcmVkLiBUaGUgcGFyZW50IHJlc291cmNlIG9mIHRoZSBB
dXRob3JpemF0aW9uUG9saWN5LiBNdXN0IGJlIGluIHRoZQogZm9ybWF0IGBwcm9qZWN0cy97
cHJvamVjdH0vbG9jYXRpb25zL3tsb2NhdGlvbn1gLgoKDQoFBAQCAAUSBNcBAggKDQoFBAQC
AAESBNcBCQ8KDQoFBAQCAAMSBNcBEhMKDwoFBAQCAAgSBtcBFNwBAwoQCggEBAIACJwIABIE
2AEEKgoRCgcEBAIACJ8IEgbZAQTbAQUK+wEKBAQEAgESBOIBAk4a7AEgUmVxdWlyZWQuIFNo
b3J0IG5hbWUgb2YgdGhlIEF1dGhvcml6YXRpb25Qb2xpY3kgcmVzb3VyY2UgdG8gYmUgY3Jl
YXRlZC4KIFRoaXMgdmFsdWUgc2hvdWxkIGJlIDEtNjMgY2hhcmFjdGVycyBsb25nLCBjb250
YWluaW5nIG9ubHkKIGxldHRlcnMsIG51bWJlcnMsIGh5cGhlbnMsIGFuZCB1bmRlcnNjb3Jl
cywgYW5kIHNob3VsZCBub3Qgc3RhcnQKIHdpdGggYSBudW1iZXIuIEUuZy4gImF1dGh6X3Bv
bGljeSIuCgoNCgUEBAIBBRIE4gECCAoNCgUEBAIBARIE4gEJIAoNCgUEBAIBAxIE4gEjJAoN
CgUEBAIBCBIE4gElTQoQCggEBAIBCJwIABIE4gEmTApHCgQEBAICEgblAQLmAS8aNyBSZXF1
aXJlZC4gQXV0aG9yaXphdGlvblBvbGljeSByZXNvdXJjZSB0byBiZSBjcmVhdGVkLgoKDQoF
BAQCAgYSBOUBAhUKDQoFBAQCAgESBOUBFioKDQoFBAQCAgMSBOUBLS4KDQoFBAQCAggSBOYB
Bi4KEAoIBAQCAgicCAASBOYBBy0KRQoCBAUSBuoBAPYBARo3IFJlcXVlc3QgdXNlZCBieSB0
aGUgVXBkYXRlQXV0aG9yaXphdGlvblBvbGljeSBtZXRob2QuCgoLCgMEBQESBOoBCCgK5QIK
BAQFAgASBvABAvEBLxrUAiBPcHRpb25hbC4gRmllbGQgbWFzayBpcyB1c2VkIHRvIHNwZWNp
ZnkgdGhlIGZpZWxkcyB0byBiZSBvdmVyd3JpdHRlbiBpbiB0aGUKIEF1dGhvcml6YXRpb25Q
b2xpY3kgcmVzb3VyY2UgYnkgdGhlIHVwZGF0ZS4KIFRoZSBmaWVsZHMgc3BlY2lmaWVkIGlu
IHRoZSB1cGRhdGVfbWFzayBhcmUgcmVsYXRpdmUgdG8gdGhlIHJlc291cmNlLCBub3QKIHRo
ZSBmdWxsIHJlcXVlc3QuIEEgZmllbGQgd2lsbCBiZSBvdmVyd3JpdHRlbiBpZiBpdCBpcyBp
biB0aGUgbWFzay4gSWYgdGhlCiB1c2VyIGRvZXMgbm90IHByb3ZpZGUgYSBtYXNrIHRoZW4g
YWxsIGZpZWxkcyB3aWxsIGJlIG92ZXJ3cml0dGVuLgoKDQoFBAUCAAYSBPABAhsKDQoFBAUC
AAESBPABHCcKDQoFBAUCAAMSBPABKisKDQoFBAUCAAgSBPEBBi4KEAoIBAUCAAicCAASBPEB
By0KQQoEBAUCARIG9AEC9QEvGjEgUmVxdWlyZWQuIFVwZGF0ZWQgQXV0aG9yaXphdGlvblBv
bGljeSByZXNvdXJjZS4KCg0KBQQFAgEGEgT0AQIVCg0KBQQFAgEBEgT0ARYqCg0KBQQFAgED
EgT0AS0uCg0KBQQFAgEIEgT1AQYuChAKCAQFAgEInAgAEgT1AQctCkUKAgQGEgb5AQCCAgEa
NyBSZXF1ZXN0IHVzZWQgYnkgdGhlIERlbGV0ZUF1dGhvcml6YXRpb25Qb2xpY3kgbWV0aG9k
LgoKCwoDBAYBEgT5AQgoCqMBCgQEBgIAEgb8AQKBAgQakgEgUmVxdWlyZWQuIEEgbmFtZSBv
ZiB0aGUgQXV0aG9yaXphdGlvblBvbGljeSB0byBkZWxldGUuIE11c3QgYmUgaW4gdGhlCiBm
b3JtYXQgYHByb2plY3RzL3twcm9qZWN0fS9sb2NhdGlvbnMve2xvY2F0aW9ufS9hdXRob3Jp
emF0aW9uUG9saWNpZXMvKmAuCgoNCgUEBgIABRIE/AECCAoNCgUEBgIAARIE/AEJDQoNCgUE
BgIAAxIE/AEQEQoPCgUEBgIACBIG/AESgQIDChAKCAQGAgAInAgAEgT9AQQqChEKBwQGAgAI
nwgSBv4BBIACBWIGcHJvdG8z
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Networksecurity::V1::AuthorizationPolicy::AuthorizationPolicy ===
    # Fields for AuthorizationPolicy
    # Field: name Type: 9 ()
    # Field: description Type: 9 ()
    # Field: create_time Type: 11 (.google.protobuf.Timestamp)
    # Field: update_time Type: 11 (.google.protobuf.Timestamp)
    # Field: labels Type: 11 (.google.cloud.networksecurity.v1.AuthorizationPolicy.LabelsEntry)
    # Field: action Type: 14 (.google.cloud.networksecurity.v1.AuthorizationPolicy.Action)
    # Field: rules Type: 11 (.google.cloud.networksecurity.v1.AuthorizationPolicy.Rule)

# Enum: AuthorizationPolicy::Action
our $AuthorizationPolicy_ACTION_UNSPECIFIED = 0;
our $AuthorizationPolicy_ALLOW = 1;
our $AuthorizationPolicy_DENY = 2;

# === Message: Google::Cloud::Networksecurity::V1::AuthorizationPolicy::ListAuthorizationPoliciesRequest ===
    # Fields for ListAuthorizationPoliciesRequest
    # Field: parent Type: 9 ()
    # Field: page_size Type: 5 ()
    # Field: page_token Type: 9 ()

# === Message: Google::Cloud::Networksecurity::V1::AuthorizationPolicy::ListAuthorizationPoliciesResponse ===
    # Fields for ListAuthorizationPoliciesResponse
    # Field: authorization_policies Type: 11 (.google.cloud.networksecurity.v1.AuthorizationPolicy)
    # Field: next_page_token Type: 9 ()

# === Message: Google::Cloud::Networksecurity::V1::AuthorizationPolicy::GetAuthorizationPolicyRequest ===
    # Fields for GetAuthorizationPolicyRequest
    # Field: name Type: 9 ()

# === Message: Google::Cloud::Networksecurity::V1::AuthorizationPolicy::CreateAuthorizationPolicyRequest ===
    # Fields for CreateAuthorizationPolicyRequest
    # Field: parent Type: 9 ()
    # Field: authorization_policy_id Type: 9 ()
    # Field: authorization_policy Type: 11 (.google.cloud.networksecurity.v1.AuthorizationPolicy)

# === Message: Google::Cloud::Networksecurity::V1::AuthorizationPolicy::UpdateAuthorizationPolicyRequest ===
    # Fields for UpdateAuthorizationPolicyRequest
    # Field: update_mask Type: 11 (.google.protobuf.FieldMask)
    # Field: authorization_policy Type: 11 (.google.cloud.networksecurity.v1.AuthorizationPolicy)

# === Message: Google::Cloud::Networksecurity::V1::AuthorizationPolicy::DeleteAuthorizationPolicyRequest ===
    # Fields for DeleteAuthorizationPolicyRequest
    # Field: name Type: 9 ()

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Networksecurity::V1::AuthorizationPolicy - Compiled Protocol Buffers messages for google/cloud/networksecurity/v1/authorization_policy.proto

=head1 SYNOPSIS

    use Google::Cloud::Networksecurity::V1::AuthorizationPolicy;

    my $msg = Google::Cloud::Networksecurity::V1::AuthorizationPolicy::AuthorizationPolicy->new({
        name => $name,
        description => $description,
        create_time => $create_time,
        update_time => $update_time,
    });

    # Read or update a field
    my $val = $msg->name();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Networksecurity::V1::AuthorizationPolicy::AuthorizationPolicy->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/networksecurity/v1/authorization_policy.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Networksecurity::V1::AuthorizationPolicy::AuthorizationPolicy

AuthorizationPolicy is a resource that specifies how a server
should authorize incoming connections. This resource in itself does
not change the configuration unless it's attached to a target https
proxy or endpoint config selector resource.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. Name of the AuthorizationPolicy resource. It matches pattern
`projects/{project}/locations/{location}/authorizationPolicies/<authorization_policy>`.

=item * C<< $msg->description() >> / C<< $msg->description($value) >>

Type: C<String>

Optional. Free-text description of the resource.

=item * C<< $msg->create_time() >> / C<< $msg->create_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Output only. The timestamp when the resource was created.

=item * C<< $msg->update_time() >> / C<< $msg->update_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Output only. The timestamp when the resource was updated.

=item * C<< $msg->labels() >> / C<< $msg->labels($value) >>

Type: C<Message> (L<Google::Cloud::Networksecurity::V1::AuthorizationPolicy::AuthorizationPolicy::LabelsEntry>)

Optional. Set of label tags associated with the AuthorizationPolicy
resource.

=item * C<< $msg->action() >> / C<< $msg->action($value) >>

Type: C<Enum> (L<Google::Cloud::Networksecurity::V1::AuthorizationPolicy::Action>)

Required. The action to take when a rule match is found. Possible values
are "ALLOW" or "DENY".

=item * C<< $msg->rules() >> / C<< $msg->rules($value) >>

Type: C<Message> (L<Google::Cloud::Networksecurity::V1::AuthorizationPolicy::AuthorizationPolicy::Rule>)

Optional. List of rules to match. Note that at least one of the rules must
match in order for the action specified in the 'action' field to be taken.
A rule is a match if there is a matching source and destination. If left
blank, the action specified in the `action` field will be applied on every
request.

=back

=head3 Enum: AuthorizationPolicy::Action

=over 4

=item * C<ACTION_UNSPECIFIED> => C<0>

=item * C<ALLOW> => C<1>

=item * C<DENY> => C<2>

=back

=head2 Google::Cloud::Networksecurity::V1::AuthorizationPolicy::ListAuthorizationPoliciesRequest

Request used with the ListAuthorizationPolicies method.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->parent() >> / C<< $msg->parent($value) >>

Type: C<String>

Required. The project and location from which the AuthorizationPolicies
should be listed, specified in the format
`projects/{project}/locations/{location}`.

=item * C<< $msg->page_size() >> / C<< $msg->page_size($value) >>

Type: C<Int32>

Maximum number of AuthorizationPolicies to return per call.

=item * C<< $msg->page_token() >> / C<< $msg->page_token($value) >>

Type: C<String>

The value returned by the last
`ListAuthorizationPoliciesResponse` Indicates that this is a
continuation of a prior `ListAuthorizationPolicies` call, and
that the system should return the next page of data.

=back

=head2 Google::Cloud::Networksecurity::V1::AuthorizationPolicy::ListAuthorizationPoliciesResponse

Response returned by the ListAuthorizationPolicies method.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->authorization_policies() >> / C<< $msg->authorization_policies($value) >>

Type: C<Message> (L<Google::Cloud::Networksecurity::V1::AuthorizationPolicy::AuthorizationPolicy>)

List of AuthorizationPolicies resources.

=item * C<< $msg->next_page_token() >> / C<< $msg->next_page_token($value) >>

Type: C<String>

If there might be more results than those appearing in this response, then
`next_page_token` is included. To get the next set of results, call this
method again using the value of `next_page_token` as `page_token`.

=back

=head2 Google::Cloud::Networksecurity::V1::AuthorizationPolicy::GetAuthorizationPolicyRequest

Request used by the GetAuthorizationPolicy method.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. A name of the AuthorizationPolicy to get. Must be in the format
`projects/{project}/locations/{location}/authorizationPolicies/*`.

=back

=head2 Google::Cloud::Networksecurity::V1::AuthorizationPolicy::CreateAuthorizationPolicyRequest

Request used by the CreateAuthorizationPolicy method.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->parent() >> / C<< $msg->parent($value) >>

Type: C<String>

Required. The parent resource of the AuthorizationPolicy. Must be in the
format `projects/{project}/locations/{location}`.

=item * C<< $msg->authorization_policy_id() >> / C<< $msg->authorization_policy_id($value) >>

Type: C<String>

Required. Short name of the AuthorizationPolicy resource to be created.
This value should be 1-63 characters long, containing only
letters, numbers, hyphens, and underscores, and should not start
with a number. E.g. "authz_policy".

=item * C<< $msg->authorization_policy() >> / C<< $msg->authorization_policy($value) >>

Type: C<Message> (L<Google::Cloud::Networksecurity::V1::AuthorizationPolicy::AuthorizationPolicy>)

Required. AuthorizationPolicy resource to be created.

=back

=head2 Google::Cloud::Networksecurity::V1::AuthorizationPolicy::UpdateAuthorizationPolicyRequest

Request used by the UpdateAuthorizationPolicy method.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->update_mask() >> / C<< $msg->update_mask($value) >>

Type: C<Message> (L<Google::Protobuf::FieldMask::FieldMask>)

Optional. Field mask is used to specify the fields to be overwritten in the
AuthorizationPolicy resource by the update.
The fields specified in the update_mask are relative to the resource, not
the full request. A field will be overwritten if it is in the mask. If the
user does not provide a mask then all fields will be overwritten.

=item * C<< $msg->authorization_policy() >> / C<< $msg->authorization_policy($value) >>

Type: C<Message> (L<Google::Cloud::Networksecurity::V1::AuthorizationPolicy::AuthorizationPolicy>)

Required. Updated AuthorizationPolicy resource.

=back

=head2 Google::Cloud::Networksecurity::V1::AuthorizationPolicy::DeleteAuthorizationPolicyRequest

Request used by the DeleteAuthorizationPolicy method.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. A name of the AuthorizationPolicy to delete. Must be in the
format `projects/{project}/locations/{location}/authorizationPolicies/*`.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Networksecurity::V1::AuthorizationPolicy::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
