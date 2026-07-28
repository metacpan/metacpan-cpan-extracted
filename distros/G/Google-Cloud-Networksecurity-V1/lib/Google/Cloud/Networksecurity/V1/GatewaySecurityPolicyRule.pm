package Google::Cloud::Networksecurity::V1::GatewaySecurityPolicyRule;

use strict;
use warnings;

our $VERSION = '0.11';

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
CkJnb29nbGUvY2xvdWQvbmV0d29ya3NlY3VyaXR5L3YxL2dhdGV3YXlfc2VjdXJpdHlfcG9s
aWN5X3J1bGUucHJvdG8SH2dvb2dsZS5jbG91ZC5uZXR3b3Jrc2VjdXJpdHkudjEaH2dvb2ds
ZS9hcGkvZmllbGRfYmVoYXZpb3IucHJvdG8aGWdvb2dsZS9hcGkvcmVzb3VyY2UucHJvdG8a
IGdvb2dsZS9wcm90b2J1Zi9maWVsZF9tYXNrLnByb3RvGh9nb29nbGUvcHJvdG9idWYvdGlt
ZXN0YW1wLnByb3RvIq4GChlHYXRld2F5U2VjdXJpdHlQb2xpY3lSdWxlEnMKDWJhc2ljX3By
b2ZpbGUYCSABKA4yRy5nb29nbGUuY2xvdWQubmV0d29ya3NlY3VyaXR5LnYxLkdhdGV3YXlT
ZWN1cml0eVBvbGljeVJ1bGUuQmFzaWNQcm9maWxlQgPgQQJIAFIMYmFzaWNQcm9maWxlEhoK
BG5hbWUYASABKAlCBuBBAuBBBVIEbmFtZRJACgtjcmVhdGVfdGltZRgCIAEoCzIaLmdvb2ds
ZS5wcm90b2J1Zi5UaW1lc3RhbXBCA+BBA1IKY3JlYXRlVGltZRJACgt1cGRhdGVfdGltZRgD
IAEoCzIaLmdvb2dsZS5wcm90b2J1Zi5UaW1lc3RhbXBCA+BBA1IKdXBkYXRlVGltZRIdCgdl
bmFibGVkGAQgASgIQgPgQQJSB2VuYWJsZWQSHwoIcHJpb3JpdHkYBSABKAVCA+BBAlIIcHJp
b3JpdHkSJQoLZGVzY3JpcHRpb24YBiABKAlCA+BBAVILZGVzY3JpcHRpb24SLAoPc2Vzc2lv
bl9tYXRjaGVyGAcgASgJQgPgQQJSDnNlc3Npb25NYXRjaGVyEjQKE2FwcGxpY2F0aW9uX21h
dGNoZXIYCCABKAlCA+BBAVISYXBwbGljYXRpb25NYXRjaGVyEjkKFnRsc19pbnNwZWN0aW9u
X2VuYWJsZWQYCiABKAhCA+BBAVIUdGxzSW5zcGVjdGlvbkVuYWJsZWQiQgoMQmFzaWNQcm9m
aWxlEh0KGUJBU0lDX1BST0ZJTEVfVU5TUEVDSUZJRUQQABIJCgVBTExPVxABEggKBERFTlkQ
AjqmAepBogEKOG5ldHdvcmtzZWN1cml0eS5nb29nbGVhcGlzLmNvbS9HYXRld2F5U2VjdXJp
dHlQb2xpY3lSdWxlEmZwcm9qZWN0cy97cHJvamVjdH0vbG9jYXRpb25zL3tsb2NhdGlvbn0v
Z2F0ZXdheVNlY3VyaXR5UG9saWNpZXMve2dhdGV3YXlfc2VjdXJpdHlfcG9saWN5fS9ydWxl
cy97cnVsZX1CCQoHcHJvZmlsZSLLAgomQ3JlYXRlR2F0ZXdheVNlY3VyaXR5UG9saWN5UnVs
ZVJlcXVlc3QSWAoGcGFyZW50GAEgASgJQkDgQQL6QToSOG5ldHdvcmtzZWN1cml0eS5nb29n
bGVhcGlzLmNvbS9HYXRld2F5U2VjdXJpdHlQb2xpY3lSdWxlUgZwYXJlbnQSgAEKHGdhdGV3
YXlfc2VjdXJpdHlfcG9saWN5X3J1bGUYAiABKAsyOi5nb29nbGUuY2xvdWQubmV0d29ya3Nl
Y3VyaXR5LnYxLkdhdGV3YXlTZWN1cml0eVBvbGljeVJ1bGVCA+BBAlIZZ2F0ZXdheVNlY3Vy
aXR5UG9saWN5UnVsZRJECh9nYXRld2F5X3NlY3VyaXR5X3BvbGljeV9ydWxlX2lkGAMgASgJ
UhtnYXRld2F5U2VjdXJpdHlQb2xpY3lSdWxlSWQiewojR2V0R2F0ZXdheVNlY3VyaXR5UG9s
aWN5UnVsZVJlcXVlc3QSVAoEbmFtZRgBIAEoCUJA4EEC+kE6CjhuZXR3b3Jrc2VjdXJpdHku
Z29vZ2xlYXBpcy5jb20vR2F0ZXdheVNlY3VyaXR5UG9saWN5UnVsZVIEbmFtZSLtAQomVXBk
YXRlR2F0ZXdheVNlY3VyaXR5UG9saWN5UnVsZVJlcXVlc3QSQAoLdXBkYXRlX21hc2sYASAB
KAsyGi5nb29nbGUucHJvdG9idWYuRmllbGRNYXNrQgPgQQFSCnVwZGF0ZU1hc2sSgAEKHGdh
dGV3YXlfc2VjdXJpdHlfcG9saWN5X3J1bGUYAiABKAsyOi5nb29nbGUuY2xvdWQubmV0d29y
a3NlY3VyaXR5LnYxLkdhdGV3YXlTZWN1cml0eVBvbGljeVJ1bGVCA+BBAlIZZ2F0ZXdheVNl
Y3VyaXR5UG9saWN5UnVsZSK5AQolTGlzdEdhdGV3YXlTZWN1cml0eVBvbGljeVJ1bGVzUmVx
dWVzdBJUCgZwYXJlbnQYASABKAlCPOBBAvpBNgo0bmV0d29ya3NlY3VyaXR5Lmdvb2dsZWFw
aXMuY29tL0dhdGV3YXlTZWN1cml0eVBvbGljeVIGcGFyZW50EhsKCXBhZ2Vfc2l6ZRgCIAEo
BVIIcGFnZVNpemUSHQoKcGFnZV90b2tlbhgDIAEoCVIJcGFnZVRva2VuIvEBCiZMaXN0R2F0
ZXdheVNlY3VyaXR5UG9saWN5UnVsZXNSZXNwb25zZRJ9Ch1nYXRld2F5X3NlY3VyaXR5X3Bv
bGljeV9ydWxlcxgBIAMoCzI6Lmdvb2dsZS5jbG91ZC5uZXR3b3Jrc2VjdXJpdHkudjEuR2F0
ZXdheVNlY3VyaXR5UG9saWN5UnVsZVIaZ2F0ZXdheVNlY3VyaXR5UG9saWN5UnVsZXMSJgoP
bmV4dF9wYWdlX3Rva2VuGAIgASgJUg1uZXh0UGFnZVRva2VuEiAKC3VucmVhY2hhYmxlGAMg
AygJUgt1bnJlYWNoYWJsZSJ+CiZEZWxldGVHYXRld2F5U2VjdXJpdHlQb2xpY3lSdWxlUmVx
dWVzdBJUCgRuYW1lGAEgASgJQkDgQQL6QToKOG5ldHdvcmtzZWN1cml0eS5nb29nbGVhcGlz
LmNvbS9HYXRld2F5U2VjdXJpdHlQb2xpY3lSdWxlUgRuYW1lQv8BCiNjb20uZ29vZ2xlLmNs
b3VkLm5ldHdvcmtzZWN1cml0eS52MUIeR2F0ZXdheVNlY3VyaXR5UG9saWN5UnVsZVByb3Rv
UAFaTWNsb3VkLmdvb2dsZS5jb20vZ28vbmV0d29ya3NlY3VyaXR5L2FwaXYxL25ldHdvcmtz
ZWN1cml0eXBiO25ldHdvcmtzZWN1cml0eXBiqgIfR29vZ2xlLkNsb3VkLk5ldHdvcmtTZWN1
cml0eS5WMcoCH0dvb2dsZVxDbG91ZFxOZXR3b3JrU2VjdXJpdHlcVjHqAiJHb29nbGU6OkNs
b3VkOjpOZXR3b3JrU2VjdXJpdHk6OlYxSpg1CgcSBQ4AwwEBCrwECgEMEgMOABIysQQgQ29w
eXJpZ2h0IDIwMjYgR29vZ2xlIExMQwoKIExpY2Vuc2VkIHVuZGVyIHRoZSBBcGFjaGUgTGlj
ZW5zZSwgVmVyc2lvbiAyLjAgKHRoZSAiTGljZW5zZSIpOwogeW91IG1heSBub3QgdXNlIHRo
aXMgZmlsZSBleGNlcHQgaW4gY29tcGxpYW5jZSB3aXRoIHRoZSBMaWNlbnNlLgogWW91IG1h
eSBvYnRhaW4gYSBjb3B5IG9mIHRoZSBMaWNlbnNlIGF0CgogICAgIGh0dHA6Ly93d3cuYXBh
Y2hlLm9yZy9saWNlbnNlcy9MSUNFTlNFLTIuMAoKIFVubGVzcyByZXF1aXJlZCBieSBhcHBs
aWNhYmxlIGxhdyBvciBhZ3JlZWQgdG8gaW4gd3JpdGluZywgc29mdHdhcmUKIGRpc3RyaWJ1
dGVkIHVuZGVyIHRoZSBMaWNlbnNlIGlzIGRpc3RyaWJ1dGVkIG9uIGFuICJBUyBJUyIgQkFT
SVMsCiBXSVRIT1VUIFdBUlJBTlRJRVMgT1IgQ09ORElUSU9OUyBPRiBBTlkgS0lORCwgZWl0
aGVyIGV4cHJlc3Mgb3IgaW1wbGllZC4KIFNlZSB0aGUgTGljZW5zZSBmb3IgdGhlIHNwZWNp
ZmljIGxhbmd1YWdlIGdvdmVybmluZyBwZXJtaXNzaW9ucyBhbmQKIGxpbWl0YXRpb25zIHVu
ZGVyIHRoZSBMaWNlbnNlLgoKCAoBAhIDEAAoCgkKAgMAEgMSACkKCQoCAwESAxMAIwoJCgID
AhIDFAAqCgkKAgMDEgMVACkKCAoBCBIDFwA8CgkKAgglEgMXADwKCAoBCBIDGABkCgkKAggL
EgMYAGQKCAoBCBIDGQAiCgkKAggKEgMZACIKCAoBCBIDGgA/CgkKAggIEgMaAD8KCAoBCBID
GwA8CgkKAggBEgMbADwKCAoBCBIDHAA8CgkKAggpEgMcADwKCAoBCBIDHQA7CgkKAggtEgMd
ADsKvgEKAgQAEgQiAF4BGrEBIFRoZSBHYXRld2F5U2VjdXJpdHlQb2xpY3lSdWxlIHJlc291
cmNlIGlzIGluIGEgbmVzdGVkIGNvbGxlY3Rpb24gd2l0aGluIGEKIEdhdGV3YXlTZWN1cml0
eVBvbGljeSBhbmQgcmVwcmVzZW50cyBhIHRyYWZmaWMgbWF0Y2hpbmcgY29uZGl0aW9uIGFu
ZAogYXNzb2NpYXRlZCBhY3Rpb24gdG8gcGVyZm9ybS4KCgoKAwQAARIDIgghCgsKAwQABxIE
IwImBAoNCgUEAAedCBIEIwImBAo0CgQEAAQAEgQpAjIDGiYgZW51bSB0byBkZWZpbmUgdGhl
IHByaW1pdGl2ZSBhY3Rpb24uCgoMCgUEAAQAARIDKQcTCkMKBgQABAACABIDKwQiGjQgSWYg
dGhlcmUgaXMgbm90IGEgbWVudGlvbmVkIGFjdGlvbiBmb3IgdGhlIHRhcmdldC4KCg4KBwQA
BAACAAESAysEHQoOCgcEAAQAAgACEgMrICEKKwoGBAAEAAIBEgMuBA4aHCBBbGxvdyB0aGUg
bWF0Y2hlZCB0cmFmZmljLgoKDgoHBAAEAAIBARIDLgQJCg4KBwQABAACAQISAy4MDQoqCgYE
AAQAAgISAzEEDRobIERlbnkgdGhlIG1hdGNoZWQgdHJhZmZpYy4KCg4KBwQABAACAgESAzEE
CAoOCgcEAAQAAgICEgMxCwwKDAoEBAAIABIENAI3AwoMCgUEAAgAARIDNAgPClEKBAQAAgAS
AzYETBpEIFJlcXVpcmVkLiBQcm9maWxlIHdoaWNoIHRlbGxzIHdoYXQgdGhlIHByaW1pdGl2
ZSBhY3Rpb24gc2hvdWxkIGJlLgoKDAoFBAACAAYSAzYEEAoMCgUEAAIAARIDNhEeCgwKBQQA
AgADEgM2ISIKDAoFBAACAAgSAzYjSwoPCggEAAIACJwIABIDNiRKCooCCgQEAAIBEgQ9AkAE
GvsBIFJlcXVpcmVkLiBJbW11dGFibGUuIE5hbWUgb2YgdGhlIHJlc291cmNlLiBhbWUgaXMg
dGhlIGZ1bGwgcmVzb3VyY2UgbmFtZSBzbwogcHJvamVjdHMve3Byb2plY3R9L2xvY2F0aW9u
cy97bG9jYXRpb259L2dhdGV3YXlTZWN1cml0eVBvbGljaWVzL3tnYXRld2F5X3NlY3VyaXR5
X3BvbGljeX0vcnVsZXMve3J1bGV9CiBydWxlIHNob3VsZCBtYXRjaCB0aGUKIHBhdHRlcm46
ICheW2Etel0oW2EtejAtOS1dezAsNjF9W2EtejAtOV0pPyQpLgoKDAoFBAACAQUSAz0CCAoM
CgUEAAIBARIDPQkNCgwKBQQAAgEDEgM9EBEKDQoFBAACAQgSBD0SQAMKDwoIBAACAQicCAAS
Az4EKgoPCggEAAIBCJwIARIDPwQrCjwKBAQAAgISBEMCRDIaLiBPdXRwdXQgb25seS4gVGlt
ZSB3aGVuIHRoZSBydWxlIHdhcyBjcmVhdGVkLgoKDAoFBAACAgYSA0MCGwoMCgUEAAICARID
QxwnCgwKBQQAAgIDEgNDKisKDAoFBAACAggSA0QGMQoPCggEAAICCJwIABIDRAcwCjwKBAQA
AgMSBEcCSDIaLiBPdXRwdXQgb25seS4gVGltZSB3aGVuIHRoZSBydWxlIHdhcyB1cGRhdGVk
LgoKDAoFBAACAwYSA0cCGwoMCgUEAAIDARIDRxwnCgwKBQQAAgMDEgNHKisKDAoFBAACAwgS
A0gGMQoPCggEAAIDCJwIABIDSAcwCjYKBAQAAgQSA0sCPBopIFJlcXVpcmVkLiBXaGV0aGVy
IHRoZSBydWxlIGlzIGVuZm9yY2VkLgoKDAoFBAACBAUSA0sCBgoMCgUEAAIEARIDSwcOCgwK
BQQAAgQDEgNLERIKDAoFBAACBAgSA0sTOwoPCggEAAIECJwIABIDSxQ6Cl4KBAQAAgUSA08C
PhpRIFJlcXVpcmVkLiBQcmlvcml0eSBvZiB0aGUgcnVsZS4KIExvd2VyIG51bWJlciBjb3Jy
ZXNwb25kcyB0byBoaWdoZXIgcHJlY2VkZW5jZS4KCgwKBQQAAgUFEgNPAgcKDAoFBAACBQES
A08IEAoMCgUEAAIFAxIDTxMUCgwKBQQAAgUIEgNPFT0KDwoIBAACBQicCAASA08WPAo/CgQE
AAIGEgNSAkIaMiBPcHRpb25hbC4gRnJlZS10ZXh0IGRlc2NyaXB0aW9uIG9mIHRoZSByZXNv
dXJjZS4KCgwKBQQAAgYFEgNSAggKDAoFBAACBgESA1IJFAoMCgUEAAIGAxIDUhcYCgwKBQQA
AgYIEgNSGUEKDwoIBAACBgicCAASA1IaQApJCgQEAAIHEgNVAkYaPCBSZXF1aXJlZC4gQ0VM
IGV4cHJlc3Npb24gZm9yIG1hdGNoaW5nIG9uIHNlc3Npb24gY3JpdGVyaWEuCgoMCgUEAAIH
BRIDVQIICgwKBQQAAgcBEgNVCRgKDAoFBAACBwMSA1UbHAoMCgUEAAIHCBIDVR1FCg8KCAQA
AgcInAgAEgNVHkQKVgoEBAACCBIDWAJKGkkgT3B0aW9uYWwuIENFTCBleHByZXNzaW9uIGZv
ciBtYXRjaGluZyBvbiBMNy9hcHBsaWNhdGlvbiBsZXZlbCBjcml0ZXJpYS4KCgwKBQQAAggF
EgNYAggKDAoFBAACCAESA1gJHAoMCgUEAAIIAxIDWB8gCgwKBQQAAggIEgNYIUkKDwoIBAAC
CAicCAASA1giSAq6AQoEBAACCRIDXQJMGqwBIE9wdGlvbmFsLiBGbGFnIHRvIGVuYWJsZSBU
TFMgaW5zcGVjdGlvbiBvZiB0cmFmZmljIG1hdGNoaW5nIG9uCiA8c2Vzc2lvbl9tYXRjaGVy
PiwgY2FuIG9ubHkgYmUgdHJ1ZSBpZiB0aGUgcGFyZW50IEdhdGV3YXlTZWN1cml0eVBvbGlj
eQogcmVmZXJlbmNlcyBhIFRMU0luc3BlY3Rpb25Db25maWcuCgoMCgUEAAIJBRIDXQIGCgwK
BQQAAgkBEgNdBx0KDAoFBAACCQMSA10gIgoMCgUEAAIJCBIDXSNLCg8KCAQAAgkInAgAEgNd
JEoKjwEKAgQBEgRiAHYBGoIBIE1ldGhvZHMgZm9yIEdhdGV3YXlTZWN1cml0eVBvbGljeSBS
VUxFUy9HYXRld2F5U2VjdXJpdHlQb2xpY3lSdWxlcy4KIFJlcXVlc3QgdXNlZCBieSB0aGUg
Q3JlYXRlR2F0ZXdheVNlY3VyaXR5UG9saWN5UnVsZSBtZXRob2QuCgoKCgMEAQESA2IILgqS
AQoEBAECABIEZgJrBBqDASBSZXF1aXJlZC4gVGhlIHBhcmVudCB3aGVyZSB0aGlzIHJ1bGUg
d2lsbCBiZSBjcmVhdGVkLgogRm9ybWF0IDoKIHByb2plY3RzL3twcm9qZWN0fS9sb2NhdGlv
bi97bG9jYXRpb259L2dhdGV3YXlTZWN1cml0eVBvbGljaWVzLyoKCgwKBQQBAgAFEgNmAggK
DAoFBAECAAESA2YJDwoMCgUEAQIAAxIDZhITCg0KBQQBAgAIEgRmFGsDCg8KCAQBAgAInAgA
EgNnBCoKDwoHBAECAAifCBIEaARqBQoxCgQEAQIBEgRuAm8vGiMgUmVxdWlyZWQuIFRoZSBy
dWxlIHRvIGJlIGNyZWF0ZWQuCgoMCgUEAQIBBhIDbgIbCgwKBQQBAgEBEgNuHDgKDAoFBAEC
AQMSA247PAoMCgUEAQIBCBIDbwYuCg8KCAQBAgEInAgAEgNvBy0KvwEKBAQBAgISA3UCLRqx
ASBUaGUgSUQgdG8gdXNlIGZvciB0aGUgcnVsZSwgd2hpY2ggd2lsbCBiZWNvbWUgdGhlIGZp
bmFsIGNvbXBvbmVudCBvZgogdGhlIHJ1bGUncyByZXNvdXJjZSBuYW1lLgogVGhpcyB2YWx1
ZSBzaG91bGQgYmUgNC02MyBjaGFyYWN0ZXJzLCBhbmQgdmFsaWQgY2hhcmFjdGVycwogYXJl
IC9bYS16XVswLTldLS8uCgoMCgUEAQICBRIDdQIICgwKBQQBAgIBEgN1CSgKDAoFBAECAgMS
A3UrLApHCgIEAhIFeQCDAQEaOiBSZXF1ZXN0IHVzZWQgYnkgdGhlIEdldEdhdGV3YXlTZWN1
cml0eVBvbGljeVJ1bGUgbWV0aG9kLgoKCgoDBAIBEgN5CCsKpQEKBAQCAgASBX0CggEEGpUB
IFJlcXVpcmVkLiBUaGUgbmFtZSBvZiB0aGUgR2F0ZXdheVNlY3VyaXR5UG9saWN5UnVsZSB0
byByZXRyaWV2ZS4KIEZvcm1hdDoKIHByb2plY3RzL3twcm9qZWN0fS9sb2NhdGlvbi97bG9j
YXRpb259L2dhdGV3YXlTZWN1cml0eVBvbGljaWVzLyovcnVsZXMvKgoKDAoFBAICAAUSA30C
CAoMCgUEAgIAARIDfQkNCgwKBQQCAgADEgN9EBEKDgoFBAICAAgSBX0SggEDCg8KCAQCAgAI
nAgAEgN+BCoKEAoHBAICAAifCBIFfwSBAQUKSwoCBAMSBoYBAJIBARo9IFJlcXVlc3QgdXNl
ZCBieSB0aGUgVXBkYXRlR2F0ZXdheVNlY3VyaXR5UG9saWN5UnVsZSBtZXRob2QuCgoLCgME
AwESBIYBCC4K5wIKBAQDAgASBowBAo0BLxrWAiBPcHRpb25hbC4gRmllbGQgbWFzayBpcyB1
c2VkIHRvIHNwZWNpZnkgdGhlIGZpZWxkcyB0byBiZSBvdmVyd3JpdHRlbiBpbiB0aGUKIEdh
dGV3YXlTZWN1cml0eVBvbGljeSByZXNvdXJjZSBieSB0aGUgdXBkYXRlLgogVGhlIGZpZWxk
cyBzcGVjaWZpZWQgaW4gdGhlIHVwZGF0ZV9tYXNrIGFyZSByZWxhdGl2ZSB0byB0aGUgcmVz
b3VyY2UsIG5vdAogdGhlIGZ1bGwgcmVxdWVzdC4gQSBmaWVsZCB3aWxsIGJlIG92ZXJ3cml0
dGVuIGlmIGl0IGlzIGluIHRoZSBtYXNrLiBJZiB0aGUKIHVzZXIgZG9lcyBub3QgcHJvdmlk
ZSBhIG1hc2sgdGhlbiBhbGwgZmllbGRzIHdpbGwgYmUgb3ZlcndyaXR0ZW4uCgoNCgUEAwIA
BhIEjAECGwoNCgUEAwIAARIEjAEcJwoNCgUEAwIAAxIEjAEqKwoNCgUEAwIACBIEjQEGLgoQ
CggEAwIACJwIABIEjQEHLQpHCgQEAwIBEgaQAQKRAS8aNyBSZXF1aXJlZC4gVXBkYXRlZCBH
YXRld2F5U2VjdXJpdHlQb2xpY3lSdWxlIHJlc291cmNlLgoKDQoFBAMCAQYSBJABAhsKDQoF
BAMCAQESBJABHDgKDQoFBAMCAQMSBJABOzwKDQoFBAMCAQgSBJEBBi4KEAoIBAMCAQicCAAS
BJEBBy0KTAoCBAQSBpUBAKgBARo+IFJlcXVlc3QgdXNlZCB3aXRoIHRoZSBMaXN0R2F0ZXdh
eVNlY3VyaXR5UG9saWN5UnVsZXMgbWV0aG9kLgoKCwoDBAQBEgSVAQgtCv0BCgQEBAIAEgaZ
AQKeAQQa7AEgUmVxdWlyZWQuIFRoZSBwcm9qZWN0LCBsb2NhdGlvbiBhbmQgR2F0ZXdheVNl
Y3VyaXR5UG9saWN5IGZyb20gd2hpY2ggdGhlCiBHYXRld2F5U2VjdXJpdHlQb2xpY3lSdWxl
cyBzaG91bGQgYmUgbGlzdGVkLCBzcGVjaWZpZWQgaW4gdGhlIGZvcm1hdAogYHByb2plY3Rz
L3twcm9qZWN0fS9sb2NhdGlvbnMve2xvY2F0aW9ufS9nYXRld2F5U2VjdXJpdHlQb2xpY2ll
cy97Z2F0ZXdheVNlY3VyaXR5UG9saWN5fWAuCgoNCgUEBAIABRIEmQECCAoNCgUEBAIAARIE
mQEJDwoNCgUEBAIAAxIEmQESEwoPCgUEBAIACBIGmQEUngEDChAKCAQEAgAInAgAEgSaAQQq
ChEKBwQEAgAInwgSBpsBBJ0BBQpQCgQEBAIBEgShAQIWGkIgTWF4aW11bSBudW1iZXIgb2Yg
R2F0ZXdheVNlY3VyaXR5UG9saWN5UnVsZXMgdG8gcmV0dXJuIHBlciBjYWxsLgoKDQoFBAQC
AQUSBKEBAgcKDQoFBAQCAQESBKEBCBEKDQoFBAQCAQMSBKEBFBUK7AEKBAQEAgISBKcBAhga
3QEgVGhlIHZhbHVlIHJldHVybmVkIGJ5IHRoZSBsYXN0CiAnTGlzdEdhdGV3YXlTZWN1cml0
eVBvbGljeVJ1bGVzUmVzcG9uc2UnIEluZGljYXRlcyB0aGF0IHRoaXMgaXMgYQogY29udGlu
dWF0aW9uIG9mIGEgcHJpb3IgJ0xpc3RHYXRld2F5U2VjdXJpdHlQb2xpY3lSdWxlcycgY2Fs
bCwgYW5kCiB0aGF0IHRoZSBzeXN0ZW0gc2hvdWxkIHJldHVybiB0aGUgbmV4dCBwYWdlIG9m
IGRhdGEuCgoNCgUEBAICBRIEpwECCAoNCgUEBAICARIEpwEJEwoNCgUEBAICAxIEpwEWFwpP
CgIEBRIGqwEAtgEBGkEgUmVzcG9uc2UgcmV0dXJuZWQgYnkgdGhlIExpc3RHYXRld2F5U2Vj
dXJpdHlQb2xpY3lSdWxlcyBtZXRob2QuCgoLCgMEBQESBKsBCC4KPAoEBAUCABIErQECRxou
IExpc3Qgb2YgR2F0ZXdheVNlY3VyaXR5UG9saWN5UnVsZSByZXNvdXJjZXMuCgoNCgUEBQIA
BBIErQECCgoNCgUEBQIABhIErQELJAoNCgUEBQIAARIErQElQgoNCgUEBQIAAxIErQFFRgrp
AQoEBAUCARIEsgECHRraASBJZiB0aGVyZSBtaWdodCBiZSBtb3JlIHJlc3VsdHMgdGhhbiB0
aG9zZSBhcHBlYXJpbmcgaW4gdGhpcyByZXNwb25zZSwgdGhlbgogJ25leHRfcGFnZV90b2tl
bicgaXMgaW5jbHVkZWQuIFRvIGdldCB0aGUgbmV4dCBzZXQgb2YgcmVzdWx0cywgY2FsbCB0
aGlzCiBtZXRob2QgYWdhaW4gdXNpbmcgdGhlIHZhbHVlIG9mICduZXh0X3BhZ2VfdG9rZW4n
IGFzICdwYWdlX3Rva2VuJy4KCg0KBQQFAgEFEgSyAQIICg0KBQQFAgEBEgSyAQkYCg0KBQQF
AgEDEgSyARscCjQKBAQFAgISBLUBAiIaJiBMb2NhdGlvbnMgdGhhdCBjb3VsZCBub3QgYmUg
cmVhY2hlZC4KCg0KBQQFAgIEEgS1AQIKCg0KBQQFAgIFEgS1AQsRCg0KBQQFAgIBEgS1ARId
Cg0KBQQFAgIDEgS1ASAhCksKAgQGEga5AQDDAQEaPSBSZXF1ZXN0IHVzZWQgYnkgdGhlIERl
bGV0ZUdhdGV3YXlTZWN1cml0eVBvbGljeVJ1bGUgbWV0aG9kLgoKCwoDBAYBEgS5AQguCsoB
CgQEBgIAEga9AQLCAQQauQEgUmVxdWlyZWQuIEEgbmFtZSBvZiB0aGUgR2F0ZXdheVNlY3Vy
aXR5UG9saWN5UnVsZSB0byBkZWxldGUuIE11c3QgYmUgaW4gdGhlCiBmb3JtYXQKIGBwcm9q
ZWN0cy97cHJvamVjdH0vbG9jYXRpb25zL3tsb2NhdGlvbn0vZ2F0ZXdheVNlY3VyaXR5UG9s
aWNpZXMve2dhdGV3YXlTZWN1cml0eVBvbGljeX0vcnVsZXMvKmAuCgoNCgUEBgIABRIEvQEC
CAoNCgUEBgIAARIEvQEJDQoNCgUEBgIAAxIEvQEQEQoPCgUEBgIACBIGvQESwgEDChAKCAQG
AgAInAgAEgS+AQQqChEKBwQGAgAInwgSBr8BBMEBBWIGcHJvdG8z
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Networksecurity::V1::GatewaySecurityPolicyRule::GatewaySecurityPolicyRule ===
    # Fields for GatewaySecurityPolicyRule
    # Field: basic_profile Type: 14 (.google.cloud.networksecurity.v1.GatewaySecurityPolicyRule.BasicProfile)
    # Field: name Type: 9 ()
    # Field: create_time Type: 11 (.google.protobuf.Timestamp)
    # Field: update_time Type: 11 (.google.protobuf.Timestamp)
    # Field: enabled Type: 8 ()
    # Field: priority Type: 5 ()
    # Field: description Type: 9 ()
    # Field: session_matcher Type: 9 ()
    # Field: application_matcher Type: 9 ()
    # Field: tls_inspection_enabled Type: 8 ()

=pod

=head1 NAME

Google::Cloud::Networksecurity::V1::GatewaySecurityPolicyRule::GatewaySecurityPolicyRule - Compiled Protocol Buffers message class

=head1 SYNOPSIS

    use Google::Cloud::Networksecurity::V1::GatewaySecurityPolicyRule;

    my $msg = Google::Cloud::Networksecurity::V1::GatewaySecurityPolicyRule::GatewaySecurityPolicyRule->new(
        basic_profile => $value,
    );

=head1 FIELDS

=over 4

=item * B<basic_profile>

Type: Enum (.google.cloud.networksecurity.v1.GatewaySecurityPolicyRule.BasicProfile)

=item * B<name>

Type: String

=item * B<create_time>

Type: Message (.google.protobuf.Timestamp)

=item * B<update_time>

Type: Message (.google.protobuf.Timestamp)

=item * B<enabled>

Type: Bool

=item * B<priority>

Type: Int32

=item * B<description>

Type: String

=item * B<session_matcher>

Type: String

=item * B<application_matcher>

Type: String

=item * B<tls_inspection_enabled>

Type: Bool

=back

=cut

# Enum: GatewaySecurityPolicyRule::BasicProfile
our $GatewaySecurityPolicyRule_BASIC_PROFILE_UNSPECIFIED = 0;
our $GatewaySecurityPolicyRule_ALLOW = 1;
our $GatewaySecurityPolicyRule_DENY = 2;

=pod

=head2 Enum: GatewaySecurityPolicyRule::BasicProfile

Values:

=over 4

=item * C<BASIC_PROFILE_UNSPECIFIED> => 0

=item * C<ALLOW> => 1

=item * C<DENY> => 2

=back

=cut

# === Message: Google::Cloud::Networksecurity::V1::GatewaySecurityPolicyRule::CreateGatewaySecurityPolicyRuleRequest ===
    # Fields for CreateGatewaySecurityPolicyRuleRequest
    # Field: parent Type: 9 ()
    # Field: gateway_security_policy_rule Type: 11 (.google.cloud.networksecurity.v1.GatewaySecurityPolicyRule)
    # Field: gateway_security_policy_rule_id Type: 9 ()

=pod

=head1 NAME

Google::Cloud::Networksecurity::V1::GatewaySecurityPolicyRule::CreateGatewaySecurityPolicyRuleRequest - Compiled Protocol Buffers message class

=head1 SYNOPSIS

    use Google::Cloud::Networksecurity::V1::GatewaySecurityPolicyRule;

    my $msg = Google::Cloud::Networksecurity::V1::GatewaySecurityPolicyRule::CreateGatewaySecurityPolicyRuleRequest->new(
        parent => $value,
    );

=head1 FIELDS

=over 4

=item * B<parent>

Type: String

=item * B<gateway_security_policy_rule>

Type: Message (.google.cloud.networksecurity.v1.GatewaySecurityPolicyRule)

=item * B<gateway_security_policy_rule_id>

Type: String

=back

=cut

# === Message: Google::Cloud::Networksecurity::V1::GatewaySecurityPolicyRule::GetGatewaySecurityPolicyRuleRequest ===
    # Fields for GetGatewaySecurityPolicyRuleRequest
    # Field: name Type: 9 ()

=pod

=head1 NAME

Google::Cloud::Networksecurity::V1::GatewaySecurityPolicyRule::GetGatewaySecurityPolicyRuleRequest - Compiled Protocol Buffers message class

=head1 SYNOPSIS

    use Google::Cloud::Networksecurity::V1::GatewaySecurityPolicyRule;

    my $msg = Google::Cloud::Networksecurity::V1::GatewaySecurityPolicyRule::GetGatewaySecurityPolicyRuleRequest->new(
        name => $value,
    );

=head1 FIELDS

=over 4

=item * B<name>

Type: String

=back

=cut

# === Message: Google::Cloud::Networksecurity::V1::GatewaySecurityPolicyRule::UpdateGatewaySecurityPolicyRuleRequest ===
    # Fields for UpdateGatewaySecurityPolicyRuleRequest
    # Field: update_mask Type: 11 (.google.protobuf.FieldMask)
    # Field: gateway_security_policy_rule Type: 11 (.google.cloud.networksecurity.v1.GatewaySecurityPolicyRule)

=pod

=head1 NAME

Google::Cloud::Networksecurity::V1::GatewaySecurityPolicyRule::UpdateGatewaySecurityPolicyRuleRequest - Compiled Protocol Buffers message class

=head1 SYNOPSIS

    use Google::Cloud::Networksecurity::V1::GatewaySecurityPolicyRule;

    my $msg = Google::Cloud::Networksecurity::V1::GatewaySecurityPolicyRule::UpdateGatewaySecurityPolicyRuleRequest->new(
        update_mask => $value,
    );

=head1 FIELDS

=over 4

=item * B<update_mask>

Type: Message (.google.protobuf.FieldMask)

=item * B<gateway_security_policy_rule>

Type: Message (.google.cloud.networksecurity.v1.GatewaySecurityPolicyRule)

=back

=cut

# === Message: Google::Cloud::Networksecurity::V1::GatewaySecurityPolicyRule::ListGatewaySecurityPolicyRulesRequest ===
    # Fields for ListGatewaySecurityPolicyRulesRequest
    # Field: parent Type: 9 ()
    # Field: page_size Type: 5 ()
    # Field: page_token Type: 9 ()

=pod

=head1 NAME

Google::Cloud::Networksecurity::V1::GatewaySecurityPolicyRule::ListGatewaySecurityPolicyRulesRequest - Compiled Protocol Buffers message class

=head1 SYNOPSIS

    use Google::Cloud::Networksecurity::V1::GatewaySecurityPolicyRule;

    my $msg = Google::Cloud::Networksecurity::V1::GatewaySecurityPolicyRule::ListGatewaySecurityPolicyRulesRequest->new(
        parent => $value,
    );

=head1 FIELDS

=over 4

=item * B<parent>

Type: String

=item * B<page_size>

Type: Int32

=item * B<page_token>

Type: String

=back

=cut

# === Message: Google::Cloud::Networksecurity::V1::GatewaySecurityPolicyRule::ListGatewaySecurityPolicyRulesResponse ===
    # Fields for ListGatewaySecurityPolicyRulesResponse
    # Field: gateway_security_policy_rules Type: 11 (.google.cloud.networksecurity.v1.GatewaySecurityPolicyRule)
    # Field: next_page_token Type: 9 ()
    # Field: unreachable Type: 9 ()

=pod

=head1 NAME

Google::Cloud::Networksecurity::V1::GatewaySecurityPolicyRule::ListGatewaySecurityPolicyRulesResponse - Compiled Protocol Buffers message class

=head1 SYNOPSIS

    use Google::Cloud::Networksecurity::V1::GatewaySecurityPolicyRule;

    my $msg = Google::Cloud::Networksecurity::V1::GatewaySecurityPolicyRule::ListGatewaySecurityPolicyRulesResponse->new(
        gateway_security_policy_rules => $value,
    );

=head1 FIELDS

=over 4

=item * B<gateway_security_policy_rules>

Type: Message (.google.cloud.networksecurity.v1.GatewaySecurityPolicyRule)

=item * B<next_page_token>

Type: String

=item * B<unreachable>

Type: String

=back

=cut

# === Message: Google::Cloud::Networksecurity::V1::GatewaySecurityPolicyRule::DeleteGatewaySecurityPolicyRuleRequest ===
    # Fields for DeleteGatewaySecurityPolicyRuleRequest
    # Field: name Type: 9 ()

=pod

=head1 NAME

Google::Cloud::Networksecurity::V1::GatewaySecurityPolicyRule::DeleteGatewaySecurityPolicyRuleRequest - Compiled Protocol Buffers message class

=head1 SYNOPSIS

    use Google::Cloud::Networksecurity::V1::GatewaySecurityPolicyRule;

    my $msg = Google::Cloud::Networksecurity::V1::GatewaySecurityPolicyRule::DeleteGatewaySecurityPolicyRuleRequest->new(
        name => $value,
    );

=head1 FIELDS

=over 4

=item * B<name>

Type: String

=back

=cut

1;

__END__

=head1 NAME

Google::Cloud::Networksecurity::V1::GatewaySecurityPolicyRule - Protocol Buffers schema definition

=head1 DESCRIPTION

Auto-generated Protocol Buffers schema definition class.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
