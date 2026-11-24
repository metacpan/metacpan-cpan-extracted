package Google::Cloud::Channel::V1::Repricing;

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
    eval { require Google::Type::Date };
    eval { require Google::Type::Decimal };
    my $descriptor_b64 = <<'EOF';
Cidnb29nbGUvY2xvdWQvY2hhbm5lbC92MS9yZXByaWNpbmcucHJvdG8SF2dvb2dsZS5jbG91
ZC5jaGFubmVsLnYxGh9nb29nbGUvYXBpL2ZpZWxkX2JlaGF2aW9yLnByb3RvGhlnb29nbGUv
YXBpL3Jlc291cmNlLnByb3RvGh9nb29nbGUvcHJvdG9idWYvdGltZXN0YW1wLnByb3RvGhZn
b29nbGUvdHlwZS9kYXRlLnByb3RvGhlnb29nbGUvdHlwZS9kZWNpbWFsLnByb3RvIugCChdD
dXN0b21lclJlcHJpY2luZ0NvbmZpZxIXCgRuYW1lGAEgASgJQgPgQQNSBG5hbWUSWAoQcmVw
cmljaW5nX2NvbmZpZxgCIAEoCzIoLmdvb2dsZS5jbG91ZC5jaGFubmVsLnYxLlJlcHJpY2lu
Z0NvbmZpZ0ID4EECUg9yZXByaWNpbmdDb25maWcSQAoLdXBkYXRlX3RpbWUYAyABKAsyGi5n
b29nbGUucHJvdG9idWYuVGltZXN0YW1wQgPgQQNSCnVwZGF0ZVRpbWU6lwHqQZMBCjNjbG91
ZGNoYW5uZWwuZ29vZ2xlYXBpcy5jb20vQ3VzdG9tZXJSZXByaWNpbmdDb25maWcSXGFjY291
bnRzL3thY2NvdW50fS9jdXN0b21lcnMve2N1c3RvbWVyfS9jdXN0b21lclJlcHJpY2luZ0Nv
bmZpZ3Mve2N1c3RvbWVyX3JlcHJpY2luZ19jb25maWd9IpIDCh1DaGFubmVsUGFydG5lclJl
cHJpY2luZ0NvbmZpZxIXCgRuYW1lGAEgASgJQgPgQQNSBG5hbWUSWAoQcmVwcmljaW5nX2Nv
bmZpZxgCIAEoCzIoLmdvb2dsZS5jbG91ZC5jaGFubmVsLnYxLlJlcHJpY2luZ0NvbmZpZ0ID
4EECUg9yZXByaWNpbmdDb25maWcSQAoLdXBkYXRlX3RpbWUYAyABKAsyGi5nb29nbGUucHJv
dG9idWYuVGltZXN0YW1wQgPgQQNSCnVwZGF0ZVRpbWU6uwHqQbcBCjljbG91ZGNoYW5uZWwu
Z29vZ2xlYXBpcy5jb20vQ2hhbm5lbFBhcnRuZXJSZXByaWNpbmdDb25maWcSemFjY291bnRz
L3thY2NvdW50fS9jaGFubmVsUGFydG5lckxpbmtzL3tjaGFubmVsX3BhcnRuZXJ9L2NoYW5u
ZWxQYXJ0bmVyUmVwcmljaW5nQ29uZmlncy97Y2hhbm5lbF9wYXJ0bmVyX3JlcHJpY2luZ19j
b25maWd9IpQGCg9SZXByaWNpbmdDb25maWcSfwoXZW50aXRsZW1lbnRfZ3JhbnVsYXJpdHkY
BCABKAsyPy5nb29nbGUuY2xvdWQuY2hhbm5lbC52MS5SZXByaWNpbmdDb25maWcuRW50aXRs
ZW1lbnRHcmFudWxhcml0eUID4EECSABSFmVudGl0bGVtZW50R3JhbnVsYXJpdHkSiAEKG2No
YW5uZWxfcGFydG5lcl9ncmFudWxhcml0eRgFIAEoCzJCLmdvb2dsZS5jbG91ZC5jaGFubmVs
LnYxLlJlcHJpY2luZ0NvbmZpZy5DaGFubmVsUGFydG5lckdyYW51bGFyaXR5QgIYAUgAUhlj
aGFubmVsUGFydG5lckdyYW51bGFyaXR5Ek4KF2VmZmVjdGl2ZV9pbnZvaWNlX21vbnRoGAEg
ASgLMhEuZ29vZ2xlLnR5cGUuRGF0ZUID4EECUhVlZmZlY3RpdmVJbnZvaWNlTW9udGgSUQoK
YWRqdXN0bWVudBgCIAEoCzIsLmdvb2dsZS5jbG91ZC5jaGFubmVsLnYxLlJlcHJpY2luZ0Fk
anVzdG1lbnRCA+BBAlIKYWRqdXN0bWVudBJVCg9yZWJpbGxpbmdfYmFzaXMYAyABKA4yJy5n
b29nbGUuY2xvdWQuY2hhbm5lbC52MS5SZWJpbGxpbmdCYXNpc0ID4EECUg5yZWJpbGxpbmdC
YXNpcxJhChVjb25kaXRpb25hbF9vdmVycmlkZXMYBiADKAsyLC5nb29nbGUuY2xvdWQuY2hh
bm5lbC52MS5Db25kaXRpb25hbE92ZXJyaWRlUhRjb25kaXRpb25hbE92ZXJyaWRlcxpoChZF
bnRpdGxlbWVudEdyYW51bGFyaXR5Ek4KC2VudGl0bGVtZW50GAEgASgJQiz6QSkKJ2Nsb3Vk
Y2hhbm5lbC5nb29nbGVhcGlzLmNvbS9FbnRpdGxlbWVudFILZW50aXRsZW1lbnQaHwoZQ2hh
bm5lbFBhcnRuZXJHcmFudWxhcml0eToCGAFCDQoLZ3JhbnVsYXJpdHkiiQEKE1JlcHJpY2lu
Z0FkanVzdG1lbnQSZAoVcGVyY2VudGFnZV9hZGp1c3RtZW50GAIgASgLMi0uZ29vZ2xlLmNs
b3VkLmNoYW5uZWwudjEuUGVyY2VudGFnZUFkanVzdG1lbnRIAFIUcGVyY2VudGFnZUFkanVz
dG1lbnRCDAoKYWRqdXN0bWVudCJMChRQZXJjZW50YWdlQWRqdXN0bWVudBI0CgpwZXJjZW50
YWdlGAIgASgLMhQuZ29vZ2xlLnR5cGUuRGVjaW1hbFIKcGVyY2VudGFnZSKiAgoTQ29uZGl0
aW9uYWxPdmVycmlkZRJRCgphZGp1c3RtZW50GAEgASgLMiwuZ29vZ2xlLmNsb3VkLmNoYW5u
ZWwudjEuUmVwcmljaW5nQWRqdXN0bWVudEID4EECUgphZGp1c3RtZW50ElUKD3JlYmlsbGlu
Z19iYXNpcxgCIAEoDjInLmdvb2dsZS5jbG91ZC5jaGFubmVsLnYxLlJlYmlsbGluZ0Jhc2lz
QgPgQQJSDnJlYmlsbGluZ0Jhc2lzEmEKE3JlcHJpY2luZ19jb25kaXRpb24YAyABKAsyKy5n
b29nbGUuY2xvdWQuY2hhbm5lbC52MS5SZXByaWNpbmdDb25kaXRpb25CA+BBAlIScmVwcmlj
aW5nQ29uZGl0aW9uIn8KElJlcHJpY2luZ0NvbmRpdGlvbhJcChNza3VfZ3JvdXBfY29uZGl0
aW9uGAEgASgLMiouZ29vZ2xlLmNsb3VkLmNoYW5uZWwudjEuU2t1R3JvdXBDb25kaXRpb25I
AFIRc2t1R3JvdXBDb25kaXRpb25CCwoJY29uZGl0aW9uIjAKEVNrdUdyb3VwQ29uZGl0aW9u
EhsKCXNrdV9ncm91cBgBIAEoCVIIc2t1R3JvdXAqXQoOUmViaWxsaW5nQmFzaXMSHwobUkVC
SUxMSU5HX0JBU0lTX1VOU1BFQ0lGSUVEEAASEAoMQ09TVF9BVF9MSVNUEAESGAoURElSRUNU
X0NVU1RPTUVSX0NPU1QQAkJmChtjb20uZ29vZ2xlLmNsb3VkLmNoYW5uZWwudjFCDlJlcHJp
Y2luZ1Byb3RvUAFaNWNsb3VkLmdvb2dsZS5jb20vZ28vY2hhbm5lbC9hcGl2MS9jaGFubmVs
cGI7Y2hhbm5lbHBiSqtACgcSBQ4A2AEBCrwECgEMEgMOABIysQQgQ29weXJpZ2h0IDIwMjUg
R29vZ2xlIExMQwoKIExpY2Vuc2VkIHVuZGVyIHRoZSBBcGFjaGUgTGljZW5zZSwgVmVyc2lv
biAyLjAgKHRoZSAiTGljZW5zZSIpOwogeW91IG1heSBub3QgdXNlIHRoaXMgZmlsZSBleGNl
cHQgaW4gY29tcGxpYW5jZSB3aXRoIHRoZSBMaWNlbnNlLgogWW91IG1heSBvYnRhaW4gYSBj
b3B5IG9mIHRoZSBMaWNlbnNlIGF0CgogICAgIGh0dHA6Ly93d3cuYXBhY2hlLm9yZy9saWNl
bnNlcy9MSUNFTlNFLTIuMAoKIFVubGVzcyByZXF1aXJlZCBieSBhcHBsaWNhYmxlIGxhdyBv
ciBhZ3JlZWQgdG8gaW4gd3JpdGluZywgc29mdHdhcmUKIGRpc3RyaWJ1dGVkIHVuZGVyIHRo
ZSBMaWNlbnNlIGlzIGRpc3RyaWJ1dGVkIG9uIGFuICJBUyBJUyIgQkFTSVMsCiBXSVRIT1VU
IFdBUlJBTlRJRVMgT1IgQ09ORElUSU9OUyBPRiBBTlkgS0lORCwgZWl0aGVyIGV4cHJlc3Mg
b3IgaW1wbGllZC4KIFNlZSB0aGUgTGljZW5zZSBmb3IgdGhlIHNwZWNpZmljIGxhbmd1YWdl
IGdvdmVybmluZyBwZXJtaXNzaW9ucyBhbmQKIGxpbWl0YXRpb25zIHVuZGVyIHRoZSBMaWNl
bnNlLgoKCAoBAhIDEAAgCgkKAgMAEgMSACkKCQoCAwESAxMAIwoJCgIDAhIDFAApCgkKAgMD
EgMVACAKCQoCAwQSAxYAIwoICgEIEgMYAEwKCQoCCAsSAxgATAoICgEIEgMZACIKCQoCCAoS
AxkAIgoICgEIEgMaAC8KCQoCCAgSAxoALwoICgEIEgMbADQKCQoCCAESAxsANApTCgIFABIE
HgAqARpHIFNwZWNpZmllcyB0aGUgZGlmZmVyZW50IGNvc3RzIHRoYXQgdGhlIG1vZGlmaWVk
IGJpbGwgY2FuIGJlIGJhc2VkIG9uLgoKCgoDBQABEgMeBRMKGAoEBQACABIDIAIiGgsgTm90
IHVzZWQuCgoMCgUFAAIAARIDIAIdCgwKBQUAAgACEgMgICEKOQoEBQACARIDIwITGiwgVXNl
IHRoZSBsaXN0IGNvc3QsIGFsc28ga25vd24gYXMgdGhlIE1TUlAuCgoMCgUFAAIBARIDIwIO
CgwKBQUAAgECEgMjERIKhwIKBAUAAgISAykCGxr5ASBQYXNzIHRocm91Z2ggYWxsIGRpc2Nv
dW50cyBleGNlcHQgdGhlIFJlc2VsbGVyIFByb2dyYW0gRGlzY291bnQuIElmIHRoaXMgaXMK
IHRoZSBkZWZhdWx0IGNvc3QgYmFzZSBhbmQgbm8gYWRqdXN0bWVudHMgYXJlIHNwZWNpZmll
ZCwgdGhlIG91dHB1dCBjb3N0CiB3aWxsIGJlIGV4YWN0bHkgd2hhdCB0aGUgY3VzdG9tZXIg
d291bGQgc2VlIGlmIHRoZXkgdmlld2VkIHRoZSBiaWxsIGluIHRoZQogR29vZ2xlIENsb3Vk
IENvbnNvbGUuCgoMCgUFAAICARIDKQIWCgwKBQUAAgICEgMpGRoKRwoCBAASBC0AQgEaOyBD
b25maWd1cmF0aW9uIGZvciBob3cgYSByZXNlbGxlciB3aWxsIHJlcHJpY2UgYSBDdXN0b21l
ci4KCgoKAwQAARIDLQgfCgsKAwQABxIELgIxBAoNCgUEAAedCBIELgIxBAqhAQoEBAACABID
NgI+GpMBIE91dHB1dCBvbmx5LiBSZXNvdXJjZSBuYW1lIG9mIHRoZSBDdXN0b21lclJlcHJp
Y2luZ0NvbmZpZy4KIEZvcm1hdDoKIGFjY291bnRzL3thY2NvdW50X2lkfS9jdXN0b21lcnMv
e2N1c3RvbWVyX2lkfS9jdXN0b21lclJlcHJpY2luZ0NvbmZpZ3Mve2lkfS4KCgwKBQQAAgAF
EgM2AggKDAoFBAACAAESAzYJDQoMCgUEAAIAAxIDNhARCgwKBQQAAgAIEgM2Ej0KDwoIBAAC
AAicCAASAzYTPAp1CgQEAAIBEgM6AlAaaCBSZXF1aXJlZC4gVGhlIGNvbmZpZ3VyYXRpb24g
Zm9yIGJpbGwgbW9kaWZpY2F0aW9ucyBtYWRlIGJ5IGEgcmVzZWxsZXIKIGJlZm9yZSBzZW5k
aW5nIGl0IHRvIGN1c3RvbWVycy4KCgwKBQQAAgEGEgM6AhEKDAoFBAACAQESAzoSIgoMCgUE
AAIBAxIDOiUmCgwKBQQAAgEIEgM6J08KDwoIBAACAQicCAASAzooTgr9AQoEBAACAhIEQAJB
MhruASBPdXRwdXQgb25seS4gVGltZXN0YW1wIG9mIGFuIHVwZGF0ZSB0byB0aGUgcmVwcmlj
aW5nIHJ1bGUuIElmIGB1cGRhdGVfdGltZWAKIGlzIGFmdGVyCiBbUmVwcmljaW5nQ29uZmln
LmVmZmVjdGl2ZV9pbnZvaWNlX21vbnRoXVtnb29nbGUuY2xvdWQuY2hhbm5lbC52MS5SZXBy
aWNpbmdDb25maWcuZWZmZWN0aXZlX2ludm9pY2VfbW9udGhdCiB0aGVuIGl0IGluZGljYXRl
cyB0aGlzIHdhcyBzZXQgbWlkLW1vbnRoLgoKDAoFBAACAgYSA0ACGwoMCgUEAAICARIDQBwn
CgwKBQQAAgIDEgNAKisKDAoFBAACAggSA0EGMQoPCggEAAICCJwIABIDQQcwCoMBCgIEARIE
RgBbARp3IENvbmZpZ3VyYXRpb24gZm9yIGhvdyBhIGRpc3RyaWJ1dG9yIHdpbGwgcmViaWxs
IGEgY2hhbm5lbCBwYXJ0bmVyCiAoYWxzbyBrbm93biBhcyBhIGRpc3RyaWJ1dG9yLWF1dGhv
cml6ZWQgcmVzZWxsZXIpLgoKCgoDBAEBEgNGCCUKCwoDBAEHEgRHAkoECg0KBQQBB50IEgRH
AkoECr4BCgQEAQIAEgNPAj4asAEgT3V0cHV0IG9ubHkuIFJlc291cmNlIG5hbWUgb2YgdGhl
IENoYW5uZWxQYXJ0bmVyUmVwcmljaW5nQ29uZmlnLgogRm9ybWF0OgogYWNjb3VudHMve2Fj
Y291bnRfaWR9L2NoYW5uZWxQYXJ0bmVyTGlua3Mve2NoYW5uZWxfcGFydG5lcl9pZH0vY2hh
bm5lbFBhcnRuZXJSZXByaWNpbmdDb25maWdzL3tpZH0uCgoMCgUEAQIABRIDTwIICgwKBQQB
AgABEgNPCQ0KDAoFBAECAAMSA08QEQoMCgUEAQIACBIDTxI9Cg8KCAQBAgAInAgAEgNPEzwK
egoEBAECARIDUwJQGm0gUmVxdWlyZWQuIFRoZSBjb25maWd1cmF0aW9uIGZvciBiaWxsIG1v
ZGlmaWNhdGlvbnMgbWFkZSBieSBhIHJlc2VsbGVyCiBiZWZvcmUgc2VuZGluZyBpdCB0byBD
aGFubmVsUGFydG5lci4KCgwKBQQBAgEGEgNTAhEKDAoFBAECAQESA1MSIgoMCgUEAQIBAxID
UyUmCgwKBQQBAgEIEgNTJ08KDwoIBAECAQicCAASA1MoTgr9AQoEBAECAhIEWQJaMhruASBP
dXRwdXQgb25seS4gVGltZXN0YW1wIG9mIGFuIHVwZGF0ZSB0byB0aGUgcmVwcmljaW5nIHJ1
bGUuIElmIGB1cGRhdGVfdGltZWAKIGlzIGFmdGVyCiBbUmVwcmljaW5nQ29uZmlnLmVmZmVj
dGl2ZV9pbnZvaWNlX21vbnRoXVtnb29nbGUuY2xvdWQuY2hhbm5lbC52MS5SZXByaWNpbmdD
b25maWcuZWZmZWN0aXZlX2ludm9pY2VfbW9udGhdCiB0aGVuIGl0IGluZGljYXRlcyB0aGlz
IHdhcyBzZXQgbWlkLW1vbnRoLgoKDAoFBAECAgYSA1kCGwoMCgUEAQICARIDWRwnCgwKBQQB
AgIDEgNZKisKDAoFBAECAggSA1oGMQoPCggEAQICCJwIABIDWgcwCk8KAgQCEgVeAKEBARpC
IENvbmZpZ3VyYXRpb24gZm9yIHJlcHJpY2luZyBhIEdvb2dsZSBiaWxsIG92ZXIgYSBwZXJp
b2Qgb2YgdGltZS4KCgoKAwQCARIDXggXCk0KBAQCAwASBGACZwMaPyBBcHBsaWVzIHRoZSBy
ZXByaWNpbmcgY29uZmlndXJhdGlvbiBhdCB0aGUgZW50aXRsZW1lbnQgbGV2ZWwuCgoMCgUE
AgMAARIDYAogCokBCgYEAgMAAgASBGQEZgcaeSBSZXNvdXJjZSBuYW1lIG9mIHRoZSBlbnRp
dGxlbWVudC4KIEZvcm1hdDoKIGFjY291bnRzL3thY2NvdW50X2lkfS9jdXN0b21lcnMve2N1
c3RvbWVyX2lkfS9lbnRpdGxlbWVudHMve2VudGl0bGVtZW50X2lkfQoKDgoHBAIDAAIABRID
ZAQKCg4KBwQCAwACAAESA2QLFgoOCgcEAgMAAgADEgNkGRoKDwoHBAIDAAIACBIEZBtmBgoR
CgkEAgMAAgAInwgSBGQcZgUKzwIKBAQCAwESBG8CcQMawAIgQXBwbGllcyB0aGUgcmVwcmlj
aW5nIGNvbmZpZ3VyYXRpb24gYXQgdGhlIGNoYW5uZWwgcGFydG5lciBsZXZlbC4KIFRoZSBj
aGFubmVsIHBhcnRuZXIgdmFsdWUgaXMgZGVyaXZlZCBmcm9tIHRoZSByZXNvdXJjZSBuYW1l
LiBUYWtlcyBhbgogZW1wdHkganNvbiBvYmplY3QuCiBEZXByZWNhdGVkOiBUaGlzIGlzIG5v
IGxvbmdlciBzdXBwb3J0ZWQuIFVzZQogW1JlcHJpY2luZ0NvbmZpZy5FbnRpdGxlbWVudEdy
YW51bGFyaXR5XVtnb29nbGUuY2xvdWQuY2hhbm5lbC52MS5SZXByaWNpbmdDb25maWcuRW50
aXRsZW1lbnRHcmFudWxhcml0eV0KIGluc3RlYWQuCgoMCgUEAgMBARIDbwojCgwKBQQCAwEH
EgNwBB0KDQoGBAIDAQcDEgNwBB0KQQoEBAIIABIFdAKOAQMaMiBSZXF1aXJlZC4gRGVmaW5l
cyB0aGUgZ3JhbnVsYXJpdHkgZm9yIHJlcHJpY2luZy4KCgwKBQQCCAABEgN0CBMKtwYKBAQC
AgASBoMBBIQBMRqmBiBSZXF1aXJlZC4gQXBwbGllcyB0aGUgcmVwcmljaW5nIGNvbmZpZ3Vy
YXRpb24gYXQgdGhlIGVudGl0bGVtZW50IGxldmVsLgoKIE5vdGU6IElmIGEKIFtDaGFubmVs
UGFydG5lclJlcHJpY2luZ0NvbmZpZ11bZ29vZ2xlLmNsb3VkLmNoYW5uZWwudjEuQ2hhbm5l
bFBhcnRuZXJSZXByaWNpbmdDb25maWddCiB1c2luZwogW1JlcHJpY2luZ0NvbmZpZy5FbnRp
dGxlbWVudEdyYW51bGFyaXR5XVtnb29nbGUuY2xvdWQuY2hhbm5lbC52MS5SZXByaWNpbmdD
b25maWcuRW50aXRsZW1lbnRHcmFudWxhcml0eV0KIGJlY29tZXMgZWZmZWN0aXZlLCB0aGVu
IG5vIGV4aXN0aW5nIG9yIGZ1dHVyZQogW1JlcHJpY2luZ0NvbmZpZy5DaGFubmVsUGFydG5l
ckdyYW51bGFyaXR5XVtnb29nbGUuY2xvdWQuY2hhbm5lbC52MS5SZXByaWNpbmdDb25maWcu
Q2hhbm5lbFBhcnRuZXJHcmFudWxhcml0eV0KIHdpbGwgYXBwbHkgdG8gdGhlCiBbUmVwcmlj
aW5nQ29uZmlnLkVudGl0bGVtZW50R3JhbnVsYXJpdHkuZW50aXRsZW1lbnRdW2dvb2dsZS5j
bG91ZC5jaGFubmVsLnYxLlJlcHJpY2luZ0NvbmZpZy5FbnRpdGxlbWVudEdyYW51bGFyaXR5
LmVudGl0bGVtZW50XS4KIFRoaXMgaXMgdGhlIHJlY29tbWVuZGVkIHZhbHVlIGZvciBib3Ro
CiBbQ3VzdG9tZXJSZXByaWNpbmdDb25maWddW2dvb2dsZS5jbG91ZC5jaGFubmVsLnYxLkN1
c3RvbWVyUmVwcmljaW5nQ29uZmlnXQogYW5kCiBbQ2hhbm5lbFBhcnRuZXJSZXByaWNpbmdD
b25maWddW2dvb2dsZS5jbG91ZC5jaGFubmVsLnYxLkNoYW5uZWxQYXJ0bmVyUmVwcmljaW5n
Q29uZmlnXS4KCg0KBQQCAgAGEgSDAQQaCg0KBQQCAgABEgSDARsyCg0KBQQCAgADEgSDATU2
Cg0KBQQCAgAIEgSEAQgwChAKCAQCAgAInAgAEgSEAQkvCusCCgQEAgIBEgaMAQSNARwa2gIg
QXBwbGllcyB0aGUgcmVwcmljaW5nIGNvbmZpZ3VyYXRpb24gYXQgdGhlIGNoYW5uZWwgcGFy
dG5lciBsZXZlbC4KIE9ubHkKIFtDaGFubmVsUGFydG5lclJlcHJpY2luZ0NvbmZpZ11bZ29v
Z2xlLmNsb3VkLmNoYW5uZWwudjEuQ2hhbm5lbFBhcnRuZXJSZXByaWNpbmdDb25maWddCiBz
dXBwb3J0cyB0aGlzIHZhbHVlLiBEZXByZWNhdGVkOiBUaGlzIGlzIG5vIGxvbmdlciBzdXBw
b3J0ZWQuIFVzZQogW1JlcHJpY2luZ0NvbmZpZy5lbnRpdGxlbWVudF9ncmFudWxhcml0eV1b
Z29vZ2xlLmNsb3VkLmNoYW5uZWwudjEuUmVwcmljaW5nQ29uZmlnLmVudGl0bGVtZW50X2dy
YW51bGFyaXR5XQogaW5zdGVhZC4KCg0KBQQCAgEGEgSMAQQdCg0KBQQCAgEBEgSMAR45Cg0K
BQQCAgEDEgSMATw9Cg0KBQQCAgEIEgSNAQgbCg4KBgQCAgEIAxIEjQEJGgqfAQoEBAICAhIG
kgECkwEvGo4BIFJlcXVpcmVkLiBUaGUgWWVhck1vbnRoIHdoZW4gdGhlc2UgYWRqdXN0bWVu
dHMgYWN0aXZhdGUuIFRoZSBEYXkgZmllbGQKIG5lZWRzIHRvIGJlICIwIiBzaW5jZSB3ZSBv
bmx5IGFjY2VwdCBZZWFyTW9udGggcmVwcmljaW5nIGJvdW5kYXJpZXMuCgoNCgUEAgICBhIE
kgECEgoNCgUEAgICARIEkgETKgoNCgUEAgICAxIEkgEtLgoNCgUEAgICCBIEkwEGLgoQCggE
AgICCJwIABIEkwEHLQo7CgQEAgIDEgSWAQJOGi0gUmVxdWlyZWQuIEluZm9ybWF0aW9uIGFi
b3V0IHRoZSBhZGp1c3RtZW50LgoKDQoFBAICAwYSBJYBAhUKDQoFBAICAwESBJYBFiAKDQoF
BAICAwMSBJYBIyQKDQoFBAICAwgSBJYBJU0KEAoIBAICAwicCAASBJYBJkwKtAEKBAQCAgQS
BJsBAk4apQEgUmVxdWlyZWQuIFRoZSBbUmViaWxsaW5nQmFzaXNdW2dvb2dsZS5jbG91ZC5j
aGFubmVsLnYxLlJlYmlsbGluZ0Jhc2lzXSB0bwogdXNlIGZvciB0aGlzIGJpbGwuIFNwZWNp
ZmllcyB0aGUgcmVsYXRpdmUgY29zdCBiYXNlZCBvbiByZXByaWNpbmcgY29zdHMgeW91CiB3
aWxsIGFwcGx5LgoKDQoFBAICBAYSBJsBAhAKDQoFBAICBAESBJsBESAKDQoFBAICBAMSBJsB
IyQKDQoFBAICBAgSBJsBJU0KEAoIBAICBAicCAASBJsBJkwK7gEKBAQCAgUSBKABAjka3wEg
VGhlIGNvbmRpdGlvbmFsIG92ZXJyaWRlcyB0byBhcHBseSBmb3IgdGhpcyBjb25maWd1cmF0
aW9uLiBJZiB5b3UgbGlzdAogbXVsdGlwbGUgb3ZlcnJpZGVzLCBvbmx5IHRoZSBmaXJzdCB2
YWxpZCBvdmVycmlkZSBpcyB1c2VkLiAgSWYgeW91IGRvbid0CiBsaXN0IGFueSBvdmVycmlk
ZXMsIHRoZSBBUEkgdXNlcyB0aGUgbm9ybWFsIGFkanVzdG1lbnQgYW5kIHJlYmlsbGluZyBi
YXNpcy4KCg0KBQQCAgUEEgSgAQIKCg0KBQQCAgUGEgSgAQseCg0KBQQCAgUBEgSgAR80Cg0K
BQQCAgUDEgSgATc4ClcKAgQDEgakAQCqAQEaSSBBIHR5cGUgdGhhdCByZXByZXNlbnRzIHRo
ZSB2YXJpb3VzIGFkanVzdG1lbnRzIHlvdSBjYW4gYXBwbHkgdG8gYSBiaWxsLgoKCwoDBAMB
EgSkAQgbClIKBAQDCAASBqYBAqkBAxpCIEEgb25lb2YgdGhhdCByZXByZXNlbnRzIHRoZSBk
aWZmZXJlbnQgdHlwZXMgZm9yIHRoaXMgYWRqdXN0bWVudC4KCg0KBQQDCAABEgSmAQgSCjoK
BAQDAgASBKgBBDMaLCBGbGF0IG1hcmt1cCBvciBtYXJrZG93biBvbiBhbiBlbnRpcmUgYmls
bC4KCg0KBQQDAgAGEgSoAQQYCg0KBQQDAgABEgSoARkuCg0KBQQDAgADEgSoATEyClcKAgQE
EgatAQC0AQEaSSBBbiBhZGp1c3RtZW50IHRoYXQgYXBwbGllcyBhIGZsYXQgbWFya3VwIG9y
IG1hcmtkb3duIHRvIGFuIGVudGlyZSBiaWxsLgoKCwoDBAQBEgStAQgcCpYBCgQEBAIAEgSz
AQIlGocBIFRoZSBwZXJjZW50YWdlIG9mIHRoZSBiaWxsIHRvIGFkanVzdC4KIEZvciBleGFt
cGxlOgogTWFyayBkb3duIGJ5IDElID0+ICItMS4wMCIKIE1hcmsgdXAgYnkgMSUgICA9PiAi
MS4wMCIKIFBhc3MtVGhyb3VnaCAgICA9PiAiMC4wMCIKCg0KBQQEAgAGEgSzAQIVCg0KBQQE
AgABEgSzARYgCg0KBQQEAgADEgSzASMkCj4KAgQFEga3AQDDAQEaMCBTcGVjaWZpZXMgdGhl
IG92ZXJyaWRlIHRvIGNvbmRpdGlvbmFsbHkgYXBwbHkuCgoLCgMEBQESBLcBCBsKTgoEBAUC
ABIEuQECThpAIFJlcXVpcmVkLiBJbmZvcm1hdGlvbiBhYm91dCB0aGUgYXBwbGllZCBvdmVy
cmlkZSdzIGFkanVzdG1lbnQuCgoNCgUEBQIABhIEuQECFQoNCgUEBQIAARIEuQEWIAoNCgUE
BQIAAxIEuQEjJAoNCgUEBQIACBIEuQElTQoQCggEBQIACJwIABIEuQEmTAqxAQoEBAUCARIE
vgECThqiASBSZXF1aXJlZC4gVGhlIFtSZWJpbGxpbmdCYXNpc11bZ29vZ2xlLmNsb3VkLmNo
YW5uZWwudjEuUmViaWxsaW5nQmFzaXNdIHRvCiB1c2UgZm9yIHRoZSBhcHBsaWVkIG92ZXJy
aWRlLiBTaG93cyB0aGUgcmVsYXRpdmUgY29zdCBiYXNlZCBvbiB5b3VyCiByZXByaWNpbmcg
Y29zdHMuCgoNCgUEBQIBBhIEvgECEAoNCgUEBQIBARIEvgERIAoNCgUEBQIBAxIEvgEjJAoN
CgUEBQIBCBIEvgElTQoQCggEBQIBCJwIABIEvgEmTApbCgQEBQICEgbBAQLCAS8aSyBSZXF1
aXJlZC4gU3BlY2lmaWVzIHRoZSBjb25kaXRpb24gd2hpY2gsIGlmIG1ldCwgd2lsbCBhcHBs
eSB0aGUgb3ZlcnJpZGUuCgoNCgUEBQICBhIEwQECFAoNCgUEBQICARIEwQEVKAoNCgUEBQIC
AxIEwQErLAoNCgUEBQICCBIEwgEGLgoQCggEBQICCJwIABIEwgEHLQpkCgIEBhIGxwEAzQEB
GlYgUmVwcmVzZW50cyB0aGUgdmFyaW91cyByZXByaWNpbmcgY29uZGl0aW9ucyB5b3UgY2Fu
IHVzZSBmb3IgYSBjb25kaXRpb25hbAogb3ZlcnJpZGUuCgoLCgMEBgESBMcBCBoKSgoEBAYI
ABIGyQECzAEDGjogUmVwcmVzZW50cyB0aGUgdHlwZXMgb2YgZXhpc3RpbmcgY29uZGl0aW9u
YWwgc3RhdGVtZW50cy4KCg0KBQQGCAABEgTJAQgRCjEKBAQGAgASBMsBBC4aIyBTS1UgR3Jv
dXAgY29uZGl0aW9uIGZvciBvdmVycmlkZS4KCg0KBQQGAgAGEgTLAQQVCg0KBQQGAgABEgTL
ARYpCg0KBQQGAgADEgTLASwtCmQKAgQHEgbRAQDYAQEaViBBIGNvbmRpdGlvbiB0aGF0IGFw
cGxpZXMgdGhlIG92ZXJyaWRlIGlmIGEgbGluZSBpdGVtIFNLVSBpcyBmb3VuZCBpbiB0aGUg
U0tVCiBncm91cC4KCgsKAwQHARIE0QEIGQrvAQoEBAcCABIE1wECFxrgASBTcGVjaWZpZXMg
YSBTS1UgZ3JvdXAgKGh0dHBzOi8vY2xvdWQuZ29vZ2xlLmNvbS9za3VzL3NrdS1ncm91cHMp
LgogUmVzb3VyY2UgbmFtZSBvZiBTS1UgZ3JvdXAuIEZvcm1hdDoKIGFjY291bnRzL3thY2Nv
dW50fS9za3VHcm91cHMve3NrdV9ncm91cH0uCiBFeGFtcGxlOgogImFjY291bnRzL0MwMTIz
NC9za3VHcm91cHMvM2Q1MGZkNTctMzE1Ny00NTc3LWE1YTktYTIxOWI4NDkwMDQxIi4KCg0K
BQQHAgAFEgTXAQIICg0KBQQHAgABEgTXAQkSCg0KBQQHAgADEgTXARUWYgZwcm90bzM=
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Channel::V1::Repricing::CustomerRepricingConfig ===
    # Fields for CustomerRepricingConfig
    # Field: name Type: 9 ()
    # Field: repricing_config Type: 11 (.google.cloud.channel.v1.RepricingConfig)
    # Field: update_time Type: 11 (.google.protobuf.Timestamp)

# === Message: Google::Cloud::Channel::V1::Repricing::ChannelPartnerRepricingConfig ===
    # Fields for ChannelPartnerRepricingConfig
    # Field: name Type: 9 ()
    # Field: repricing_config Type: 11 (.google.cloud.channel.v1.RepricingConfig)
    # Field: update_time Type: 11 (.google.protobuf.Timestamp)

# === Message: Google::Cloud::Channel::V1::Repricing::RepricingConfig ===
    # Fields for RepricingConfig
    # Field: entitlement_granularity Type: 11 (.google.cloud.channel.v1.RepricingConfig.EntitlementGranularity)
    # Field: channel_partner_granularity Type: 11 (.google.cloud.channel.v1.RepricingConfig.ChannelPartnerGranularity)
    # Field: effective_invoice_month Type: 11 (.google.type.Date)
    # Field: adjustment Type: 11 (.google.cloud.channel.v1.RepricingAdjustment)
    # Field: rebilling_basis Type: 14 (.google.cloud.channel.v1.RebillingBasis)
    # Field: conditional_overrides Type: 11 (.google.cloud.channel.v1.ConditionalOverride)

# === Message: Google::Cloud::Channel::V1::Repricing::RepricingAdjustment ===
    # Fields for RepricingAdjustment
    # Field: percentage_adjustment Type: 11 (.google.cloud.channel.v1.PercentageAdjustment)

# === Message: Google::Cloud::Channel::V1::Repricing::PercentageAdjustment ===
    # Fields for PercentageAdjustment
    # Field: percentage Type: 11 (.google.type.Decimal)

# === Message: Google::Cloud::Channel::V1::Repricing::ConditionalOverride ===
    # Fields for ConditionalOverride
    # Field: adjustment Type: 11 (.google.cloud.channel.v1.RepricingAdjustment)
    # Field: rebilling_basis Type: 14 (.google.cloud.channel.v1.RebillingBasis)
    # Field: repricing_condition Type: 11 (.google.cloud.channel.v1.RepricingCondition)

# === Message: Google::Cloud::Channel::V1::Repricing::RepricingCondition ===
    # Fields for RepricingCondition
    # Field: sku_group_condition Type: 11 (.google.cloud.channel.v1.SkuGroupCondition)

# === Message: Google::Cloud::Channel::V1::Repricing::SkuGroupCondition ===
    # Fields for SkuGroupCondition
    # Field: sku_group Type: 9 ()

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Channel::V1::Repricing - Compiled Protocol Buffers messages for google/cloud/channel/v1/repricing.proto

=head1 SYNOPSIS

    use Google::Cloud::Channel::V1::Repricing;

    my $msg = Google::Cloud::Channel::V1::Repricing::CustomerRepricingConfig->new({
        name => $name,
        repricing_config => $repricing_config,
        update_time => $update_time,
    });

    # Read or update a field
    my $val = $msg->name();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Channel::V1::Repricing::CustomerRepricingConfig->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/channel/v1/repricing.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Channel::V1::Repricing::CustomerRepricingConfig

Configuration for how a reseller will reprice a Customer.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Output only. Resource name of the CustomerRepricingConfig.
Format:
accounts/{account_id}/customers/{customer_id}/customerRepricingConfigs/{id}.

=item * C<< $msg->repricing_config() >> / C<< $msg->repricing_config($value) >>

Type: C<Message> (L<Google::Cloud::Channel::V1::Repricing::RepricingConfig>)

Required. The configuration for bill modifications made by a reseller
before sending it to customers.

=item * C<< $msg->update_time() >> / C<< $msg->update_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Output only. Timestamp of an update to the repricing rule. If `update_time`
is after
[RepricingConfig.effective_invoice_month][google.cloud.channel.v1.RepricingConfig.effective_invoice_month]
then it indicates this was set mid-month.

=back

=head2 Google::Cloud::Channel::V1::Repricing::ChannelPartnerRepricingConfig

Configuration for how a distributor will rebill a channel partner
(also known as a distributor-authorized reseller).

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Output only. Resource name of the ChannelPartnerRepricingConfig.
Format:
accounts/{account_id}/channelPartnerLinks/{channel_partner_id}/channelPartnerRepricingConfigs/{id}.

=item * C<< $msg->repricing_config() >> / C<< $msg->repricing_config($value) >>

Type: C<Message> (L<Google::Cloud::Channel::V1::Repricing::RepricingConfig>)

Required. The configuration for bill modifications made by a reseller
before sending it to ChannelPartner.

=item * C<< $msg->update_time() >> / C<< $msg->update_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Output only. Timestamp of an update to the repricing rule. If `update_time`
is after
[RepricingConfig.effective_invoice_month][google.cloud.channel.v1.RepricingConfig.effective_invoice_month]
then it indicates this was set mid-month.

=back

=head2 Google::Cloud::Channel::V1::Repricing::RepricingConfig

Configuration for repricing a Google bill over a period of time.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->entitlement_granularity() >> / C<< $msg->entitlement_granularity($value) >>

Type: C<Message> (L<Google::Cloud::Channel::V1::Repricing::RepricingConfig::EntitlementGranularity>)

Required. Applies the repricing configuration at the entitlement level.

Note: If a
[ChannelPartnerRepricingConfig][google.cloud.channel.v1.ChannelPartnerRepricingConfig]
using
[RepricingConfig.EntitlementGranularity][google.cloud.channel.v1.RepricingConfig.EntitlementGranularity]
becomes effective, then no existing or future
[RepricingConfig.ChannelPartnerGranularity][google.cloud.channel.v1.RepricingConfig.ChannelPartnerGranularity]
will apply to the
[RepricingConfig.EntitlementGranularity.entitlement][google.cloud.channel.v1.RepricingConfig.EntitlementGranularity.entitlement].
This is the recommended value for both
[CustomerRepricingConfig][google.cloud.channel.v1.CustomerRepricingConfig]
and
[ChannelPartnerRepricingConfig][google.cloud.channel.v1.ChannelPartnerRepricingConfig].

=item * C<< $msg->channel_partner_granularity() >> / C<< $msg->channel_partner_granularity($value) >>

Type: C<Message> (L<Google::Cloud::Channel::V1::Repricing::RepricingConfig::ChannelPartnerGranularity>)

Applies the repricing configuration at the channel partner level.
Only
[ChannelPartnerRepricingConfig][google.cloud.channel.v1.ChannelPartnerRepricingConfig]
supports this value. Deprecated: This is no longer supported. Use
[RepricingConfig.entitlement_granularity][google.cloud.channel.v1.RepricingConfig.entitlement_granularity]
instead.

=item * C<< $msg->effective_invoice_month() >> / C<< $msg->effective_invoice_month($value) >>

Type: C<Message> (L<Google::Type::Date::Date>)

Required. The YearMonth when these adjustments activate. The Day field
needs to be "0" since we only accept YearMonth repricing boundaries.

=item * C<< $msg->adjustment() >> / C<< $msg->adjustment($value) >>

Type: C<Message> (L<Google::Cloud::Channel::V1::Repricing::RepricingAdjustment>)

Required. Information about the adjustment.

=item * C<< $msg->rebilling_basis() >> / C<< $msg->rebilling_basis($value) >>

Type: C<Enum> (L<Google::Cloud::Channel::V1::RebillingBasis>)

Required. The [RebillingBasis][google.cloud.channel.v1.RebillingBasis] to
use for this bill. Specifies the relative cost based on repricing costs you
will apply.

=item * C<< $msg->conditional_overrides() >> / C<< $msg->conditional_overrides($value) >>

Type: C<Message> (L<Google::Cloud::Channel::V1::Repricing::ConditionalOverride>)

The conditional overrides to apply for this configuration. If you list
multiple overrides, only the first valid override is used.  If you don't
list any overrides, the API uses the normal adjustment and rebilling basis.

=back

=head2 Google::Cloud::Channel::V1::Repricing::RepricingAdjustment

A type that represents the various adjustments you can apply to a bill.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->percentage_adjustment() >> / C<< $msg->percentage_adjustment($value) >>

Type: C<Message> (L<Google::Cloud::Channel::V1::Repricing::PercentageAdjustment>)

Flat markup or markdown on an entire bill.

=back

=head2 Google::Cloud::Channel::V1::Repricing::PercentageAdjustment

An adjustment that applies a flat markup or markdown to an entire bill.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->percentage() >> / C<< $msg->percentage($value) >>

Type: C<Message> (L<Google::Type::Decimal::Decimal>)

The percentage of the bill to adjust.
For example:
Mark down by 1% => "-1.00"
Mark up by 1%   => "1.00"
Pass-Through    => "0.00"

=back

=head2 Google::Cloud::Channel::V1::Repricing::ConditionalOverride

Specifies the override to conditionally apply.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->adjustment() >> / C<< $msg->adjustment($value) >>

Type: C<Message> (L<Google::Cloud::Channel::V1::Repricing::RepricingAdjustment>)

Required. Information about the applied override's adjustment.

=item * C<< $msg->rebilling_basis() >> / C<< $msg->rebilling_basis($value) >>

Type: C<Enum> (L<Google::Cloud::Channel::V1::RebillingBasis>)

Required. The [RebillingBasis][google.cloud.channel.v1.RebillingBasis] to
use for the applied override. Shows the relative cost based on your
repricing costs.

=item * C<< $msg->repricing_condition() >> / C<< $msg->repricing_condition($value) >>

Type: C<Message> (L<Google::Cloud::Channel::V1::Repricing::RepricingCondition>)

Required. Specifies the condition which, if met, will apply the override.

=back

=head2 Google::Cloud::Channel::V1::Repricing::RepricingCondition

Represents the various repricing conditions you can use for a conditional
override.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->sku_group_condition() >> / C<< $msg->sku_group_condition($value) >>

Type: C<Message> (L<Google::Cloud::Channel::V1::Repricing::SkuGroupCondition>)

SKU Group condition for override.

=back

=head2 Google::Cloud::Channel::V1::Repricing::SkuGroupCondition

A condition that applies the override if a line item SKU is found in the SKU
group.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->sku_group() >> / C<< $msg->sku_group($value) >>

Type: C<String>

Specifies a SKU group (https://cloud.google.com/skus/sku-groups).
Resource name of SKU group. Format:
accounts/{account}/skuGroups/{sku_group}.
Example:
"accounts/C01234/skuGroups/3d50fd57-3157-4577-a5a9-a219b8490041".

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Channel::V1::Repricing::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
