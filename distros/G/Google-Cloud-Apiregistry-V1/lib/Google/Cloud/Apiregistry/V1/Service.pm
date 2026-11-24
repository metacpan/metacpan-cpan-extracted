package Google::Cloud::Apiregistry::V1::Service;

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
    eval { require Google::Cloud::Apiregistry::V1::Resources };
    my $descriptor_b64 = <<'EOF';
Cilnb29nbGUvY2xvdWQvYXBpcmVnaXN0cnkvdjEvc2VydmljZS5wcm90bxIbZ29vZ2xlLmNs
b3VkLmFwaXJlZ2lzdHJ5LnYxGhxnb29nbGUvYXBpL2Fubm90YXRpb25zLnByb3RvGhdnb29n
bGUvYXBpL2NsaWVudC5wcm90bxofZ29vZ2xlL2FwaS9maWVsZF9iZWhhdmlvci5wcm90bxoZ
Z29vZ2xlL2FwaS9yZXNvdXJjZS5wcm90bxorZ29vZ2xlL2Nsb3VkL2FwaXJlZ2lzdHJ5L3Yx
L3Jlc291cmNlcy5wcm90byJcChNHZXRNY3BTZXJ2ZXJSZXF1ZXN0EkUKBG5hbWUYASABKAlC
MeBBAvpBKwopY2xvdWRhcGlyZWdpc3RyeS5nb29nbGVhcGlzLmNvbS9NY3BTZXJ2ZXJSBG5h
bWUi3QEKFUxpc3RNY3BTZXJ2ZXJzUmVxdWVzdBJBCgZwYXJlbnQYASABKAlCKeBBAvpBIwoh
bG9jYXRpb25zLmdvb2dsZWFwaXMuY29tL0xvY2F0aW9uUgZwYXJlbnQSIAoJcGFnZV9zaXpl
GAIgASgFQgPgQQFSCHBhZ2VTaXplEiIKCnBhZ2VfdG9rZW4YAyABKAlCA+BBAVIJcGFnZVRv
a2VuEhsKBmZpbHRlchgEIAEoCUID4EEBUgZmaWx0ZXISHgoIb3JkZXJfYnkYBSABKAlCA+BB
AVIHb3JkZXJCeSKwAQoWTGlzdE1jcFNlcnZlcnNSZXNwb25zZRJHCgttY3Bfc2VydmVycxgB
IAMoCzImLmdvb2dsZS5jbG91ZC5hcGlyZWdpc3RyeS52MS5NY3BTZXJ2ZXJSCm1jcFNlcnZl
cnMSJgoPbmV4dF9wYWdlX3Rva2VuGAIgASgJUg1uZXh0UGFnZVRva2VuEiUKC3VucmVhY2hh
YmxlGAMgAygJQgPgQQZSC3VucmVhY2hhYmxlIlgKEUdldE1jcFRvb2xSZXF1ZXN0EkMKBG5h
bWUYASABKAlCL+BBAvpBKQonY2xvdWRhcGlyZWdpc3RyeS5nb29nbGVhcGlzLmNvbS9NY3BU
b29sUgRuYW1lIuEBChNMaXN0TWNwVG9vbHNSZXF1ZXN0EkcKBnBhcmVudBgBIAEoCUIv4EEC
+kEpEidjbG91ZGFwaXJlZ2lzdHJ5Lmdvb2dsZWFwaXMuY29tL01jcFRvb2xSBnBhcmVudBIg
CglwYWdlX3NpemUYAiABKAVCA+BBAVIIcGFnZVNpemUSIgoKcGFnZV90b2tlbhgDIAEoCUID
4EEBUglwYWdlVG9rZW4SGwoGZmlsdGVyGAQgASgJQgPgQQFSBmZpbHRlchIeCghvcmRlcl9i
eRgFIAEoCUID4EEBUgdvcmRlckJ5IqgBChRMaXN0TWNwVG9vbHNSZXNwb25zZRJBCgltY3Bf
dG9vbHMYASADKAsyJC5nb29nbGUuY2xvdWQuYXBpcmVnaXN0cnkudjEuTWNwVG9vbFIIbWNw
VG9vbHMSJgoPbmV4dF9wYWdlX3Rva2VuGAIgASgJUg1uZXh0UGFnZVRva2VuEiUKC3VucmVh
Y2hhYmxlGAMgAygJQgPgQQZSC3VucmVhY2hhYmxlMr8GChBDbG91ZEFwaVJlZ2lzdHJ5EqcB
CgxHZXRNY3BTZXJ2ZXISMC5nb29nbGUuY2xvdWQuYXBpcmVnaXN0cnkudjEuR2V0TWNwU2Vy
dmVyUmVxdWVzdBomLmdvb2dsZS5jbG91ZC5hcGlyZWdpc3RyeS52MS5NY3BTZXJ2ZXIiPYLT
5JMCMBIuL3YxL3tuYW1lPXByb2plY3RzLyovbG9jYXRpb25zLyovbWNwU2VydmVycy8qfdpB
BG5hbWUSugEKDkxpc3RNY3BTZXJ2ZXJzEjIuZ29vZ2xlLmNsb3VkLmFwaXJlZ2lzdHJ5LnYx
Lkxpc3RNY3BTZXJ2ZXJzUmVxdWVzdBozLmdvb2dsZS5jbG91ZC5hcGlyZWdpc3RyeS52MS5M
aXN0TWNwU2VydmVyc1Jlc3BvbnNlIj+C0+STAjASLi92MS97cGFyZW50PXByb2plY3RzLyov
bG9jYXRpb25zLyp9L21jcFNlcnZlcnPaQQZwYXJlbnQSrAEKCkdldE1jcFRvb2wSLi5nb29n
bGUuY2xvdWQuYXBpcmVnaXN0cnkudjEuR2V0TWNwVG9vbFJlcXVlc3QaJC5nb29nbGUuY2xv
dWQuYXBpcmVnaXN0cnkudjEuTWNwVG9vbCJIgtPkkwI7EjkvdjEve25hbWU9cHJvamVjdHMv
Ki9sb2NhdGlvbnMvKi9tY3BTZXJ2ZXJzLyovbWNwVG9vbHMvKn3aQQRuYW1lEr8BCgxMaXN0
TWNwVG9vbHMSMC5nb29nbGUuY2xvdWQuYXBpcmVnaXN0cnkudjEuTGlzdE1jcFRvb2xzUmVx
dWVzdBoxLmdvb2dsZS5jbG91ZC5hcGlyZWdpc3RyeS52MS5MaXN0TWNwVG9vbHNSZXNwb25z
ZSJKgtPkkwI7EjkvdjEve3BhcmVudD1wcm9qZWN0cy8qL2xvY2F0aW9ucy8qL21jcFNlcnZl
cnMvKn0vbWNwVG9vbHPaQQZwYXJlbnQaU8pBH2Nsb3VkYXBpcmVnaXN0cnkuZ29vZ2xlYXBp
cy5jb23SQS5odHRwczovL3d3dy5nb29nbGVhcGlzLmNvbS9hdXRoL2Nsb3VkLXBsYXRmb3Jt
QskCCh9jb20uZ29vZ2xlLmNsb3VkLmFwaXJlZ2lzdHJ5LnYxQgxTZXJ2aWNlUHJvdG9QAVpB
Y2xvdWQuZ29vZ2xlLmNvbS9nby9hcGlyZWdpc3RyeS9hcGl2MS9hcGlyZWdpc3RyeXBiO2Fw
aXJlZ2lzdHJ5cGKqAhtHb29nbGUuQ2xvdWQuQXBpUmVnaXN0cnkuVjHKAhtHb29nbGVcQ2xv
dWRcQXBpUmVnaXN0cnlcVjHqAh5Hb29nbGU6OkNsb3VkOjpBcGlSZWdpc3RyeTo6VjHqQXUK
LGNsb3VkYXBpcmVnaXN0cnkuZ29vZ2xlYXBpcy5jb20vQXBpTmFtZXNwYWNlEkVwcm9qZWN0
cy97cHJvamVjdH0vbG9jYXRpb25zL3tsb2NhdGlvbn0vYXBpTmFtZXNwYWNlcy97YXBpX25h
bWVzcGFjZX1KiSoKBxIFDgC1AQEKvAQKAQwSAw4AEjKxBCBDb3B5cmlnaHQgMjAyNiBHb29n
bGUgTExDCgogTGljZW5zZWQgdW5kZXIgdGhlIEFwYWNoZSBMaWNlbnNlLCBWZXJzaW9uIDIu
MCAodGhlICJMaWNlbnNlIik7CiB5b3UgbWF5IG5vdCB1c2UgdGhpcyBmaWxlIGV4Y2VwdCBp
biBjb21wbGlhbmNlIHdpdGggdGhlIExpY2Vuc2UuCiBZb3UgbWF5IG9idGFpbiBhIGNvcHkg
b2YgdGhlIExpY2Vuc2UgYXQKCiAgICAgaHR0cDovL3d3dy5hcGFjaGUub3JnL2xpY2Vuc2Vz
L0xJQ0VOU0UtMi4wCgogVW5sZXNzIHJlcXVpcmVkIGJ5IGFwcGxpY2FibGUgbGF3IG9yIGFn
cmVlZCB0byBpbiB3cml0aW5nLCBzb2Z0d2FyZQogZGlzdHJpYnV0ZWQgdW5kZXIgdGhlIExp
Y2Vuc2UgaXMgZGlzdHJpYnV0ZWQgb24gYW4gIkFTIElTIiBCQVNJUywKIFdJVEhPVVQgV0FS
UkFOVElFUyBPUiBDT05ESVRJT05TIE9GIEFOWSBLSU5ELCBlaXRoZXIgZXhwcmVzcyBvciBp
bXBsaWVkLgogU2VlIHRoZSBMaWNlbnNlIGZvciB0aGUgc3BlY2lmaWMgbGFuZ3VhZ2UgZ292
ZXJuaW5nIHBlcm1pc3Npb25zIGFuZAogbGltaXRhdGlvbnMgdW5kZXIgdGhlIExpY2Vuc2Uu
CgoICgECEgMQACQKCQoCAwASAxIAJgoJCgIDARIDEwAhCgkKAgMCEgMUACkKCQoCAwMSAxUA
IwoJCgIDBBIDFgA1CggKAQgSAxgAOAoJCgIIJRIDGAA4CggKAQgSAxkAWAoJCgIICxIDGQBY
CggKAQgSAxoAIgoJCgIIChIDGgAiCggKAQgSAxsALQoJCgIICBIDGwAtCggKAQgSAxwAOAoJ
CgIIARIDHAA4CggKAQgSAx0AOAoJCgIIKRIDHQA4CggKAQgSAx4ANwoJCgIILRIDHgA3CgkK
AQgSBB8AIgIKDAoECJ0IABIEHwAiAgpgCgIGABIEJgBKARpUIFRoZSBDbG91ZCBBUEkgUmVn
aXN0cnkgc2VydmljZSBwcm92aWRlcyBhIGNlbnRyYWwgcmVnaXN0cnkgZm9yIG1hbmFnaW5n
IEFQSQogRGF0YS4KCgoKAwYAARIDJggYCgoKAwYAAxIDJwJHCgwKBQYAA5kIEgMnAkcKCwoD
BgADEgQoAik3Cg0KBQYAA5oIEgQoAik3CigKBAYAAgASBCwCMQMaGiBHZXRzIGEgc2luZ2xl
IE1jcFNlcnZlci4KCgwKBQYAAgABEgMsBhIKDAoFBgACAAISAywTJgoMCgUGAAIAAxIDLDE6
Cg0KBQYAAgAEEgQtBC8GChEKCQYAAgAEsMq8IhIELQQvBgoMCgUGAAIABBIDMAQyCg8KCAYA
AgAEmwgAEgMwBDIKNAoEBgACARIENAI5AxomIExpc3RzIE1jcFNlcnZlcnMgaW4gYSBnaXZl
biBQcm9qZWN0LgoKDAoFBgACAQESAzQGFAoMCgUGAAIBAhIDNBUqCgwKBQYAAgEDEgM0NUsK
DQoFBgACAQQSBDUENwYKEQoJBgACAQSwyrwiEgQ1BDcGCgwKBQYAAgEEEgM4BDQKDwoIBgAC
AQSbCAASAzgENAomCgQGAAICEgQ8AkEDGhggR2V0cyBhIHNpbmdsZSBNY3BUb29sLgoKDAoF
BgACAgESAzwGEAoMCgUGAAICAhIDPBEiCgwKBQYAAgIDEgM8LTQKDQoFBgACAgQSBD0EPwYK
EQoJBgACAgSwyrwiEgQ9BD8GCgwKBQYAAgIEEgNABDIKDwoIBgACAgSbCAASA0AEMgo0CgQG
AAIDEgREAkkDGiYgTGlzdHMgTWNwVG9vbHMgaW4gYSBnaXZlbiBNY3BTZXJ2ZXIuCgoMCgUG
AAIDARIDRAYSCgwKBQYAAgMCEgNEEyYKDAoFBgACAwMSA0QxRQoNCgUGAAIDBBIERQRHBgoR
CgkGAAIDBLDKvCISBEUERwYKDAoFBgACAwQSA0gENAoPCggGAAIDBJsIABIDSAQ0Ci0KAgQA
EgRNAFYBGiEgTWVzc2FnZSBmb3IgZ2V0dGluZyBhIE1jcFNlcnZlcgoKCgoDBAABEgNNCBsK
dwoEBAACABIEUAJVBBppIFJlcXVpcmVkLiBOYW1lIG9mIHRoZSByZXNvdXJjZQogRm9ybWF0
OiBwcm9qZWN0cy97cHJvamVjdH0vbG9jYXRpb25zL3tsb2NhdGlvbn0vbWNwU2VydmVycy97
bWNwX3NlcnZlcn0KCgwKBQQAAgAFEgNQAggKDAoFBAACAAESA1AJDQoMCgUEAAIAAxIDUBAR
Cg0KBQQAAgAIEgRQElUDCg8KCAQAAgAInAgAEgNRBCoKDwoHBAACAAifCBIEUgRUBQo3CgIE
ARIEWQByARorIE1lc3NhZ2UgZm9yIHJlcXVlc3RpbmcgbGlzdCBvZiBNY3BTZXJ2ZXJzCgoK
CgMEAQESA1kIHQpACgQEAQIAEgRbAmAEGjIgUmVxdWlyZWQuIFBhcmVudCB2YWx1ZSBmb3Ig
TGlzdE1jcFNlcnZlcnNSZXF1ZXN0CgoMCgUEAQIABRIDWwIICgwKBQQBAgABEgNbCQ8KDAoF
BAECAAMSA1sSEwoNCgUEAQIACBIEWxRgAwoPCggEAQIACJwIABIDXAQqCg8KBwQBAgAInwgS
BF0EXwUK1AEKBAQBAgESA2UCPxrGASBPcHRpb25hbC4gUmVxdWVzdGVkIHBhZ2Ugc2l6ZS4g
U2VydmVyIG1heSByZXR1cm4gZmV3ZXIgaXRlbXMgdGhhbgogcmVxdWVzdGVkLiBJZiB1bnNw
ZWNpZmllZCwgYXQgbW9zdCA1MCBpdGVtcyB3aWxsIGJlIHJldHVybmVkLiBUaGUgbWF4aW11
bQogdmFsdWUgaXMgMTAwOyB2YWx1ZXMgYWJvdmUgMTAwIHdpbGwgYmUgY29lcmNlZCB0byAx
MDAuCgoMCgUEAQIBBRIDZQIHCgwKBQQBAgEBEgNlCBEKDAoFBAECAQMSA2UUFQoMCgUEAQIB
CBIDZRY+Cg8KCAQBAgEInAgAEgNlFz0KWAoEBAECAhIDaAJBGksgT3B0aW9uYWwuIEEgdG9r
ZW4gaWRlbnRpZnlpbmcgYSBwYWdlIG9mIHJlc3VsdHMgdGhlIHNlcnZlciBzaG91bGQgcmV0
dXJuLgoKDAoFBAECAgUSA2gCCAoMCgUEAQICARIDaAkTCgwKBQQBAgIDEgNoFhcKDAoFBAEC
AggSA2gYQAoPCggEAQICCJwIABIDaBk/Cm0KBAQBAgMSA2wCPRpgIE9wdGlvbmFsLiBBbiBl
eHByZXNzaW9uIHRoYXQgZmlsdGVycyB0aGUgcmVzdWx0cy4KIEZvciBzeW50YXgsIHNlZSBo
dHRwczovL2dvb2dsZS5haXAuZGV2LzE2MC4KCgwKBQQBAgMFEgNsAggKDAoFBAECAwESA2wJ
DwoMCgUEAQIDAxIDbBITCgwKBQQBAgMIEgNsFDwKDwoIBAECAwicCAASA2wVOwrHAQoEBAEC
BBIDcQI/GrkBIE9wdGlvbmFsLiBBIGNvbW1hLXNlcGFyYXRlZCBsaXN0IG9mIGZpZWxkcyB0
byBvcmRlciBieSwgc29ydGVkIGluIGFzY2VuZGluZwogb3JkZXIuIFVzZSAiZGVzYyIgYWZ0
ZXIgYSBmaWVsZCBuYW1lIGZvciBkZXNjZW5kaW5nLiBGb3Igc3ludGF4LCBzZWUKIGh0dHBz
Oi8vZ29vZ2xlLmFpcC5kZXYvMTMyI29yZGVyaW5nLgoKDAoFBAECBAUSA3ECCAoMCgUEAQIE
ARIDcQkRCgwKBQQBAgQDEgNxFBUKDAoFBAECBAgSA3EWPgoPCggEAQIECJwIABIDcRc9CjgK
AgQCEgR1AH8BGiwgTWVzc2FnZSBmb3IgcmVzcG9uc2UgdG8gbGlzdGluZyBNY3BTZXJ2ZXJz
CgoKCgMEAgESA3UIHgokCgQEAgIAEgN3AiUaFyBUaGUgbGlzdCBvZiBNY3BTZXJ2ZXIKCgwK
BQQCAgAEEgN3AgoKDAoFBAICAAYSA3cLFAoMCgUEAgIAARIDdxUgCgwKBQQCAgADEgN3IyQK
TgoEBAICARIDegIdGkEgQSB0b2tlbiBpZGVudGlmeWluZyBhIHBhZ2Ugb2YgcmVzdWx0cyB0
aGUgc2VydmVyIHNob3VsZCByZXR1cm4uCgoMCgUEAgIBBRIDegIICgwKBQQCAgEBEgN6CRgK
DAoFBAICAQMSA3obHApECgQEAgICEgR9An41GjYgVW5vcmRlcmVkIGxpc3QuIExvY2F0aW9u
cyB0aGF0IGNvdWxkIG5vdCBiZSByZWFjaGVkLgoKDAoFBAICAgQSA30CCgoMCgUEAgICBRID
fQsRCgwKBQQCAgIBEgN9Eh0KDAoFBAICAgMSA30gIQoMCgUEAgICCBIDfgY0Cg8KCAQCAgII
nAgAEgN+BzMKLQoCBAMSBoIBAIwBARofIE1lc3NhZ2UgZm9yIGdldHRpbmcgYSBNY3BUb29s
CgoLCgMEAwESBIIBCBkKjgEKBAQDAgASBoYBAosBBBp+IFJlcXVpcmVkLiBOYW1lIG9mIHRo
ZSByZXNvdXJjZQogRm9ybWF0OgogcHJvamVjdHMve3Byb2plY3R9L2xvY2F0aW9ucy97bG9j
YXRpb259L21jcFNlcnZlcnMve21jcF9zZXJ2ZXJ9L21jcFRvb2xzL3ttY3BfdG9vbH0KCg0K
BQQDAgAFEgSGAQIICg0KBQQDAgABEgSGAQkNCg0KBQQDAgADEgSGARARCg8KBQQDAgAIEgaG
ARKLAQMKEAoIBAMCAAicCAASBIcBBCoKEQoHBAMCAAifCBIGiAEEigEFCjcKAgQEEgaPAQCo
AQEaKSBNZXNzYWdlIGZvciByZXF1ZXN0aW5nIGxpc3Qgb2YgTWNwVG9vbHMKCgsKAwQEARIE
jwEIGwpACgQEBAIAEgaRAQKWAQQaMCBSZXF1aXJlZC4gUGFyZW50IHZhbHVlIGZvciBMaXN0
TWNwVG9vbHNSZXF1ZXN0CgoNCgUEBAIABRIEkQECCAoNCgUEBAIAARIEkQEJDwoNCgUEBAIA
AxIEkQESEwoPCgUEBAIACBIGkQEUlgEDChAKCAQEAgAInAgAEgSSAQQqChEKBwQEAgAInwgS
BpMBBJUBBQrVAQoEBAQCARIEmwECPxrGASBPcHRpb25hbC4gUmVxdWVzdGVkIHBhZ2Ugc2l6
ZS4gU2VydmVyIG1heSByZXR1cm4gZmV3ZXIgaXRlbXMgdGhhbgogcmVxdWVzdGVkLiBJZiB1
bnNwZWNpZmllZCwgYXQgbW9zdCA1MCBpdGVtcyB3aWxsIGJlIHJldHVybmVkLiBUaGUgbWF4
aW11bQogdmFsdWUgaXMgMTAwOyB2YWx1ZXMgYWJvdmUgMTAwIHdpbGwgYmUgY29lcmNlZCB0
byAxMDAuCgoNCgUEBAIBBRIEmwECBwoNCgUEBAIBARIEmwEIEQoNCgUEBAIBAxIEmwEUFQoN
CgUEBAIBCBIEmwEWPgoQCggEBAIBCJwIABIEmwEXPQpZCgQEBAICEgSeAQJBGksgT3B0aW9u
YWwuIEEgdG9rZW4gaWRlbnRpZnlpbmcgYSBwYWdlIG9mIHJlc3VsdHMgdGhlIHNlcnZlciBz
aG91bGQgcmV0dXJuLgoKDQoFBAQCAgUSBJ4BAggKDQoFBAQCAgESBJ4BCRMKDQoFBAQCAgMS
BJ4BFhcKDQoFBAQCAggSBJ4BGEAKEAoIBAQCAgicCAASBJ4BGT8KbgoEBAQCAxIEogECPRpg
IE9wdGlvbmFsLiBBbiBleHByZXNzaW9uIHRoYXQgZmlsdGVycyB0aGUgcmVzdWx0cy4KIEZv
ciBzeW50YXgsIHNlZSBodHRwczovL2dvb2dsZS5haXAuZGV2LzE2MC4KCg0KBQQEAgMFEgSi
AQIICg0KBQQEAgMBEgSiAQkPCg0KBQQEAgMDEgSiARITCg0KBQQEAgMIEgSiARQ8ChAKCAQE
AgMInAgAEgSiARU7CsgBCgQEBAIEEgSnAQI/GrkBIE9wdGlvbmFsLiBBIGNvbW1hLXNlcGFy
YXRlZCBsaXN0IG9mIGZpZWxkcyB0byBvcmRlciBieSwgc29ydGVkIGluIGFzY2VuZGluZwog
b3JkZXIuIFVzZSAiZGVzYyIgYWZ0ZXIgYSBmaWVsZCBuYW1lIGZvciBkZXNjZW5kaW5nLiBG
b3Igc3ludGF4LCBzZWUKIGh0dHBzOi8vZ29vZ2xlLmFpcC5kZXYvMTMyI29yZGVyaW5nLgoK
DQoFBAQCBAUSBKcBAggKDQoFBAQCBAESBKcBCREKDQoFBAQCBAMSBKcBFBUKDQoFBAQCBAgS
BKcBFj4KEAoIBAQCBAicCAASBKcBFz0KOAoCBAUSBqsBALUBARoqIE1lc3NhZ2UgZm9yIHJl
c3BvbnNlIHRvIGxpc3RpbmcgTWNwVG9vbHMKCgsKAwQFARIEqwEIHAojCgQEBQIAEgStAQIh
GhUgVGhlIGxpc3Qgb2YgTWNwVG9vbAoKDQoFBAUCAAQSBK0BAgoKDQoFBAUCAAYSBK0BCxIK
DQoFBAUCAAESBK0BExwKDQoFBAUCAAMSBK0BHyAKTwoEBAUCARIEsAECHRpBIEEgdG9rZW4g
aWRlbnRpZnlpbmcgYSBwYWdlIG9mIHJlc3VsdHMgdGhlIHNlcnZlciBzaG91bGQgcmV0dXJu
LgoKDQoFBAUCAQUSBLABAggKDQoFBAUCAQESBLABCRgKDQoFBAUCAQMSBLABGxwKRgoEBAUC
AhIGswECtAE1GjYgVW5vcmRlcmVkIGxpc3QuIExvY2F0aW9ucyB0aGF0IGNvdWxkIG5vdCBi
ZSByZWFjaGVkLgoKDQoFBAUCAgQSBLMBAgoKDQoFBAUCAgUSBLMBCxEKDQoFBAUCAgESBLMB
Eh0KDQoFBAUCAgMSBLMBICEKDQoFBAUCAggSBLQBBjQKEAoIBAUCAgicCAASBLQBBzNiBnBy
b3RvMw==
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Apiregistry::V1::Service::GetMcpServerRequest ===
    # Fields for GetMcpServerRequest
    # Field: name Type: 9 ()

# === Message: Google::Cloud::Apiregistry::V1::Service::ListMcpServersRequest ===
    # Fields for ListMcpServersRequest
    # Field: parent Type: 9 ()
    # Field: page_size Type: 5 ()
    # Field: page_token Type: 9 ()
    # Field: filter Type: 9 ()
    # Field: order_by Type: 9 ()

# === Message: Google::Cloud::Apiregistry::V1::Service::ListMcpServersResponse ===
    # Fields for ListMcpServersResponse
    # Field: mcp_servers Type: 11 (.google.cloud.apiregistry.v1.McpServer)
    # Field: next_page_token Type: 9 ()
    # Field: unreachable Type: 9 ()

# === Message: Google::Cloud::Apiregistry::V1::Service::GetMcpToolRequest ===
    # Fields for GetMcpToolRequest
    # Field: name Type: 9 ()

# === Message: Google::Cloud::Apiregistry::V1::Service::ListMcpToolsRequest ===
    # Fields for ListMcpToolsRequest
    # Field: parent Type: 9 ()
    # Field: page_size Type: 5 ()
    # Field: page_token Type: 9 ()
    # Field: filter Type: 9 ()
    # Field: order_by Type: 9 ()

# === Message: Google::Cloud::Apiregistry::V1::Service::ListMcpToolsResponse ===
    # Fields for ListMcpToolsResponse
    # Field: mcp_tools Type: 11 (.google.cloud.apiregistry.v1.McpTool)
    # Field: next_page_token Type: 9 ()
    # Field: unreachable Type: 9 ()

# === Service Client: Google::Cloud::Apiregistry::V1::Service::CloudApiRegistryClient ===
package Google::Cloud::Apiregistry::V1::Service::CloudApiRegistryClient;

=pod

=head2 Service Client: Google::Cloud::Apiregistry::V1::Service::CloudApiRegistryClient

Client stub representing the remote C<CloudApiRegistry> gRPC service. Delegates call dispatching to L<Google::gRPC::Client>.

=head3 target

The endpoint target address. Defaults to C<apiregistry.googleapis.com:443>.

=head3 credentials

The authentication credentials provider. Defaults to application default credentials via L<Google::Auth>.

=cut

use Moo;
use Google::Auth;
use Google::gRPC::Client;

has credentials => ( is => 'ro', default => sub { Google::Auth->default() } );
has target      => ( is => 'ro', default => 'apiregistry.googleapis.com:443' );

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

sub get_mcp_server {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Apiregistry::V1::Service::GetMcpServerRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.apiregistry.v1.CloudApiRegistry',
        method         => 'GetMcpServer',
        request        => $req,
        response_class => 'Google::Cloud::Apiregistry::V1::Resources::McpServer',
    });
}

sub list_mcp_servers {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Apiregistry::V1::Service::ListMcpServersRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.apiregistry.v1.CloudApiRegistry',
        method         => 'ListMcpServers',
        request        => $req,
        response_class => 'Google::Cloud::Apiregistry::V1::Service::ListMcpServersResponse',
    });
}

sub get_mcp_tool {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Apiregistry::V1::Service::GetMcpToolRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.apiregistry.v1.CloudApiRegistry',
        method         => 'GetMcpTool',
        request        => $req,
        response_class => 'Google::Cloud::Apiregistry::V1::Resources::McpTool',
    });
}

sub list_mcp_tools {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Apiregistry::V1::Service::ListMcpToolsRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.apiregistry.v1.CloudApiRegistry',
        method         => 'ListMcpTools',
        request        => $req,
        response_class => 'Google::Cloud::Apiregistry::V1::Service::ListMcpToolsResponse',
    });
}

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Apiregistry::V1::Service - Compiled Protocol Buffers messages for google/cloud/apiregistry/v1/service.proto

=head1 SYNOPSIS

    use Google::Cloud::Apiregistry::V1::Service;

    my $msg = Google::Cloud::Apiregistry::V1::Service::GetMcpServerRequest->new({
        name => $name,
    });

    # Read or update a field
    my $val = $msg->name();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Apiregistry::V1::Service::GetMcpServerRequest->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/apiregistry/v1/service.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Apiregistry::V1::Service::GetMcpServerRequest

Message for getting a McpServer

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. Name of the resource
Format: projects/{project}/locations/{location}/mcpServers/{mcp_server}

=back

=head2 Google::Cloud::Apiregistry::V1::Service::ListMcpServersRequest

Message for requesting list of McpServers

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->parent() >> / C<< $msg->parent($value) >>

Type: C<String>

Required. Parent value for ListMcpServersRequest

=item * C<< $msg->page_size() >> / C<< $msg->page_size($value) >>

Type: C<Int32>

Optional. Requested page size. Server may return fewer items than
requested. If unspecified, at most 50 items will be returned. The maximum
value is 100; values above 100 will be coerced to 100.

=item * C<< $msg->page_token() >> / C<< $msg->page_token($value) >>

Type: C<String>

Optional. A token identifying a page of results the server should return.

=item * C<< $msg->filter() >> / C<< $msg->filter($value) >>

Type: C<String>

Optional. An expression that filters the results.
For syntax, see https://google.aip.dev/160.

=item * C<< $msg->order_by() >> / C<< $msg->order_by($value) >>

Type: C<String>

Optional. A comma-separated list of fields to order by, sorted in ascending
order. Use "desc" after a field name for descending. For syntax, see
https://google.aip.dev/132#ordering.

=back

=head2 Google::Cloud::Apiregistry::V1::Service::ListMcpServersResponse

Message for response to listing McpServers

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->mcp_servers() >> / C<< $msg->mcp_servers($value) >>

Type: C<Message> (L<Google::Cloud::Apiregistry::V1::Resources::McpServer>)

The list of McpServer

=item * C<< $msg->next_page_token() >> / C<< $msg->next_page_token($value) >>

Type: C<String>

A token identifying a page of results the server should return.

=item * C<< $msg->unreachable() >> / C<< $msg->unreachable($value) >>

Type: C<String>

Unordered list. Locations that could not be reached.

=back

=head2 Google::Cloud::Apiregistry::V1::Service::GetMcpToolRequest

Message for getting a McpTool

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. Name of the resource
Format:
projects/{project}/locations/{location}/mcpServers/{mcp_server}/mcpTools/{mcp_tool}

=back

=head2 Google::Cloud::Apiregistry::V1::Service::ListMcpToolsRequest

Message for requesting list of McpTools

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->parent() >> / C<< $msg->parent($value) >>

Type: C<String>

Required. Parent value for ListMcpToolsRequest

=item * C<< $msg->page_size() >> / C<< $msg->page_size($value) >>

Type: C<Int32>

Optional. Requested page size. Server may return fewer items than
requested. If unspecified, at most 50 items will be returned. The maximum
value is 100; values above 100 will be coerced to 100.

=item * C<< $msg->page_token() >> / C<< $msg->page_token($value) >>

Type: C<String>

Optional. A token identifying a page of results the server should return.

=item * C<< $msg->filter() >> / C<< $msg->filter($value) >>

Type: C<String>

Optional. An expression that filters the results.
For syntax, see https://google.aip.dev/160.

=item * C<< $msg->order_by() >> / C<< $msg->order_by($value) >>

Type: C<String>

Optional. A comma-separated list of fields to order by, sorted in ascending
order. Use "desc" after a field name for descending. For syntax, see
https://google.aip.dev/132#ordering.

=back

=head2 Google::Cloud::Apiregistry::V1::Service::ListMcpToolsResponse

Message for response to listing McpTools

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->mcp_tools() >> / C<< $msg->mcp_tools($value) >>

Type: C<Message> (L<Google::Cloud::Apiregistry::V1::Resources::McpTool>)

The list of McpTool

=item * C<< $msg->next_page_token() >> / C<< $msg->next_page_token($value) >>

Type: C<String>

A token identifying a page of results the server should return.

=item * C<< $msg->unreachable() >> / C<< $msg->unreachable($value) >>

Type: C<String>

Unordered list. Locations that could not be reached.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Apiregistry::V1::Service::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
