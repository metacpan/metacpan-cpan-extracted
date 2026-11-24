package Google::Cloud::Lustre::V1::DirectoryPolicy;

use strict;
use warnings;

our $VERSION = '0.14';

use Protobuf::Message;
use Protobuf::DescriptorPool;
use Protobuf::Internal qw(:all);
use MIME::Base64;

BEGIN {
    eval { require Google::Api::FieldBehavior };
    eval { require Google::Api::FieldInfo };
    eval { require Google::Api::Resource };
    my $descriptor_b64 = <<'EOF';
Ci1nb29nbGUvY2xvdWQvbHVzdHJlL3YxL2RpcmVjdG9yeV9wb2xpY3kucHJvdG8SFmdvb2ds
ZS5jbG91ZC5sdXN0cmUudjEaH2dvb2dsZS9hcGkvZmllbGRfYmVoYXZpb3IucHJvdG8aG2dv
b2dsZS9hcGkvZmllbGRfaW5mby5wcm90bxoZZ29vZ2xlL2FwaS9yZXNvdXJjZS5wcm90byLz
AwoPRGlyZWN0b3J5UG9saWN5EhoKBG5hbWUYASABKAlCBuBBCOBBBVIEbmFtZRItCg5kaXJl
Y3RvcnlfcGF0aBgCIAEoCUIG4EEC4EEFUg1kaXJlY3RvcnlQYXRoEi8KEWx1c3RyZV9wcm9q
ZWN0X2lkGAMgASgDQgPgQQNSD2x1c3RyZVByb2plY3RJZBIdCgN1aWQYBCABKAlCC+KMz9cI
AggB4EEDUgN1aWQSSAoFc3RhdGUYBSABKA4yLS5nb29nbGUuY2xvdWQubHVzdHJlLnYxLkRp
cmVjdG9yeVBvbGljeS5TdGF0ZUID4EEDUgVzdGF0ZSJGCgVTdGF0ZRIVChFTVEFURV9VTlNQ
RUNJRklFRBAAEgwKCENSRUFUSU5HEAESCgoGQUNUSVZFEAISDAoIREVMRVRJTkcQAzqyAepB
rgEKJWx1c3RyZS5nb29nbGVhcGlzLmNvbS9EaXJlY3RvcnlQb2xpY3kSYXByb2plY3RzL3tw
cm9qZWN0fS9sb2NhdGlvbnMve2xvY2F0aW9ufS9pbnN0YW5jZXMve2luc3RhbmNlfS9kaXJl
Y3RvcnlQb2xpY2llcy97ZGlyZWN0b3J5X3BvbGljeX0qEWRpcmVjdG9yeVBvbGljaWVzMg9k
aXJlY3RvcnlQb2xpY3ki8wEKHENyZWF0ZURpcmVjdG9yeVBvbGljeVJlcXVlc3QSRQoGcGFy
ZW50GAEgASgJQi3gQQL6QScSJWx1c3RyZS5nb29nbGVhcGlzLmNvbS9EaXJlY3RvcnlQb2xp
Y3lSBnBhcmVudBIzChNkaXJlY3RvcnlfcG9saWN5X2lkGAIgASgJQgPgQQJSEWRpcmVjdG9y
eVBvbGljeUlkElcKEGRpcmVjdG9yeV9wb2xpY3kYAyABKAsyJy5nb29nbGUuY2xvdWQubHVz
dHJlLnYxLkRpcmVjdG9yeVBvbGljeUID4EECUg9kaXJlY3RvcnlQb2xpY3kiYQocRGVsZXRl
RGlyZWN0b3J5UG9saWN5UmVxdWVzdBJBCgRuYW1lGAEgASgJQi3gQQL6QScKJWx1c3RyZS5n
b29nbGVhcGlzLmNvbS9EaXJlY3RvcnlQb2xpY3lSBG5hbWUiXgoZR2V0RGlyZWN0b3J5UG9s
aWN5UmVxdWVzdBJBCgRuYW1lGAEgASgJQi3gQQL6QScKJWx1c3RyZS5nb29nbGVhcGlzLmNv
bS9EaXJlY3RvcnlQb2xpY3lSBG5hbWUiqwEKHExpc3REaXJlY3RvcnlQb2xpY2llc1JlcXVl
c3QSRQoGcGFyZW50GAEgASgJQi3gQQL6QScSJWx1c3RyZS5nb29nbGVhcGlzLmNvbS9EaXJl
Y3RvcnlQb2xpY3lSBnBhcmVudBIgCglwYWdlX3NpemUYAiABKAVCA+BBAVIIcGFnZVNpemUS
IgoKcGFnZV90b2tlbhgDIAEoCUID4EEBUglwYWdlVG9rZW4inwEKHUxpc3REaXJlY3RvcnlQ
b2xpY2llc1Jlc3BvbnNlElYKEmRpcmVjdG9yeV9wb2xpY2llcxgBIAMoCzInLmdvb2dsZS5j
bG91ZC5sdXN0cmUudjEuRGlyZWN0b3J5UG9saWN5UhFkaXJlY3RvcnlQb2xpY2llcxImCg9u
ZXh0X3BhZ2VfdG9rZW4YAiABKAlSDW5leHRQYWdlVG9rZW5CaAoaY29tLmdvb2dsZS5jbG91
ZC5sdXN0cmUudjFCFERpcmVjdG9yeVBvbGljeVByb3RvUAFaMmNsb3VkLmdvb2dsZS5jb20v
Z28vbHVzdHJlL2FwaXYxL2x1c3RyZXBiO2x1c3RyZXBiSu8mCgcSBQ4AnwEBCrwECgEMEgMO
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
YXRpb25zIHVuZGVyIHRoZSBMaWNlbnNlLgoKCAoBAhIDEAAfCgkKAgMAEgMSACkKCQoCAwES
AxMAJQoJCgIDAhIDFAAjCggKAQgSAxYASQoJCgIICxIDFgBJCggKAQgSAxcAIgoJCgIIChID
FwAiCggKAQgSAxgANQoJCgIICBIDGAA1CggKAQgSAxkAMwoJCgIIARIDGQAzCj8KAgQAEgQc
AFEBGjMgQSBkaXJlY3RvcnkgcG9saWN5IGZvciBhIE1hbmFnZWQgTHVzdHJlIGluc3RhbmNl
LgoKCgoDBAABEgMcCBcKCwoDBAAHEgQdAiIECg0KBQQAB50IEgQdAiIECi4KBAQABAASBCUC
MQMaICBTdGF0ZSBvZiB0aGUgZGlyZWN0b3J5IHBvbGljeS4KCgwKBQQABAABEgMlBwwKJgoG
BAAEAAIAEgMnBBoaFyBTdGF0ZSBpcyB1bnNwZWNpZmllZC4KCg4KBwQABAACAAESAycEFQoO
CgcEAAQAAgACEgMnGBkKMwoGBAAEAAIBEgMqBBEaJCBEaXJlY3RvcnkgcG9saWN5IGlzIGJl
aW5nIGNyZWF0ZWQuCgoOCgcEAAQAAgEBEgMqBAwKDgoHBAAEAAIBAhIDKg8QCkEKBgQABAAC
AhIDLQQPGjIgRGlyZWN0b3J5IHBvbGljeSBpcyBhY3RpdmUgYW5kIHJlYWR5IHRvIGJlIHVz
ZWQuCgoOCgcEAAQAAgIBEgMtBAoKDgoHBAAEAAICAhIDLQ0OCjMKBgQABAACAxIDMAQRGiQg
RGlyZWN0b3J5IHBvbGljeSBpcyBiZWluZyBkZWxldGVkLgoKDgoHBAAEAAIDARIDMAQMCg4K
BwQABAACAwISAzAPEArnAQoEBAACABIENwI6BBrYASBJbW11dGFibGUuIElkZW50aWZpZXIu
IFRoZSByZXNvdXJjZSBuYW1lIG9mIHRoZSBkaXJlY3RvcnkgcG9saWN5LgogRGlyZWN0b3J5
UG9saWN5IG5hbWVzIGhhdmUgdGhlIGZvcm0KIGBwcm9qZWN0cy97cHJvamVjdH0vbG9jYXRp
b25zL3tsb2NhdGlvbn0vaW5zdGFuY2VzL3tpbnN0YW5jZX0vZGlyZWN0b3J5UG9saWNpZXMv
e2lkfWAuCiB7aWR9IGlzIHVzZXIgcHJvdmlkZWQuCgoMCgUEAAIABRIDNwIICgwKBQQAAgAB
EgM3CQ0KDAoFBAACAAMSAzcQEQoNCgUEAAIACBIENxI6AwoPCggEAAIACJwIABIDOAQsCg8K
CAQAAgAInAgBEgM5BCsKlQEKBAQAAgESBD4CQQQahgEgUmVxdWlyZWQuIEltbXV0YWJsZS4g
VGhlIGx1c3RyZSBpbnN0YW5jZSBmaWxlc3lzdGVtIGZ1bGwgcGF0aCBvZiB0aGUKIGRpcmVj
dG9yeS4gSXQgbXVzdCBzdGFydCB3aXRoIGEgc2xhc2guIGUuZy4gL2x1c3RyZS90ZXN0Rm9s
ZGVyCgoMCgUEAAIBBRIDPgIICgwKBQQAAgEBEgM+CRcKDAoFBAACAQMSAz4aGwoNCgUEAAIB
CBIEPhxBAwoPCggEAAIBCJwIABIDPwQqCg8KCAQAAgEInAgBEgNABCsK9AEKBAQAAgISA0cC
ShrmASBPdXRwdXQgb25seS4gVGhlIGx1c3RyZSBwcm9qZWN0IElEIGFzc2lnbmVkIGZvciB0
aGUgZGlyZWN0b3J5IGJ5IHRoZQogc2VydmljZS4gVGhpcyByZWFkLW9ubHkgSUQgY2FuIGJl
IHVzZWQgdG8gbWFuYWdlIHF1b3Rhcy4gU2VlIG1vcmUgZGV0YWlscwogaW4KIGh0dHBzOi8v
ZG9jcy5jbG91ZC5nb29nbGUuY29tL21hbmFnZWQtbHVzdHJlL2RvY3MvZmlsZS1zeXN0ZW0t
cXVvdGFzI3NldF9xdW90YXMKCgwKBQQAAgIFEgNHAgcKDAoFBAACAgESA0cIGQoMCgUEAAIC
AxIDRxwdCgwKBQQAAgIIEgNHHkkKDwoIBAACAgicCAASA0cfSAo3CgQEAAIDEgRKAk0EGikg
T3V0cHV0IG9ubHkuIFVuaXF1ZSBJRCBvZiB0aGUgcmVzb3VyY2UuCgoMCgUEAAIDBRIDSgII
CgwKBQQAAgMBEgNKCQwKDAoFBAACAwMSA0oPEAoNCgUEAAIDCBIEShFNAwoSCgsEAAIDCMzx
+YoBARIDSwQqCg8KCAQAAgMInAgAEgNMBC0KRgoEBAACBBIDUAI+GjkgT3V0cHV0IG9ubHku
IFRoZSBjdXJyZW50IHN0YXRlIG9mIHRoZSBkaXJlY3RvcnkgcG9saWN5LgoKDAoFBAACBAYS
A1ACBwoMCgUEAAIEARIDUAgNCgwKBQQAAgQDEgNQEBEKDAoFBAACBAgSA1ASPQoPCggEAAIE
CJwIABIDUBM8CjgKAgQBEgRUAGQBGiwgUmVxdWVzdCBtZXNzYWdlIGZvciBDcmVhdGVEaXJl
Y3RvcnlQb2xpY3kuCgoKCgMEAQESA1QIJAqMAQoEBAECABIEWAJdBBp+IFJlcXVpcmVkLiBU
aGUgcGFyZW50IGluc3RhbmNlLgogSXQgbXVzdCBiZSBpbiB0aGUgZm9ybWF0IG9mCiBgcHJv
amVjdHMve3Byb2plY3R9L2xvY2F0aW9ucy97bG9jYXRpb259L2luc3RhbmNlcy97aW5zdGFu
Y2V9YC4KCgwKBQQBAgAFEgNYAggKDAoFBAECAAESA1gJDwoMCgUEAQIAAxIDWBITCg0KBQQB
AgAIEgRYFF0DCg8KCAQBAgAInAgAEgNZBCoKDwoHBAECAAifCBIEWgRcBQpCCgQEAQIBEgNg
AkoaNSBSZXF1aXJlZC4gVGhlIElEIGZvciB0aGUgRGlyZWN0b3J5UG9saWN5IHRvIGNyZWF0
ZS4KCgwKBQQBAgEFEgNgAggKDAoFBAECAQESA2AJHAoMCgUEAQIBAxIDYB8gCgwKBQQBAgEI
EgNgIUkKDwoIBAECAQicCAASA2AiSAo4CgQEAQICEgNjAlAaKyBSZXF1aXJlZC4gVGhlIGRp
cmVjdG9yeSBwb2xpY3kgdG8gY3JlYXRlLgoKDAoFBAECAgYSA2MCEQoMCgUEAQICARIDYxIi
CgwKBQQBAgIDEgNjJSYKDAoFBAECAggSA2MnTwoPCggEAQICCJwIABIDYyhOCjgKAgQCEgRn
AHEBGiwgUmVxdWVzdCBtZXNzYWdlIGZvciBEZWxldGVEaXJlY3RvcnlQb2xpY3kuCgoKCgME
AgESA2cIJArCAQoEBAICABIEawJwBBqzASBSZXF1aXJlZC4gVGhlIHJlc291cmNlIG5hbWUg
b2YgdGhlIGRpcmVjdG9yeSBwb2xpY3kuCiBEaXJlY3RvcnlQb2xpY3kgbmFtZXMgaGF2ZSB0
aGUgZm9ybQogYHByb2plY3RzL3twcm9qZWN0fS9sb2NhdGlvbnMve2xvY2F0aW9ufS9pbnN0
YW5jZXMve2luc3RhbmNlfS9kaXJlY3RvcnlQb2xpY2llcy97aWR9YC4KCgwKBQQCAgAFEgNr
AggKDAoFBAICAAESA2sJDQoMCgUEAgIAAxIDaxARCg0KBQQCAgAIEgRrEnADCg8KCAQCAgAI
nAgAEgNsBCoKDwoHBAICAAifCBIEbQRvBQo1CgIEAxIEdAB+ARopIFJlcXVlc3QgbWVzc2Fn
ZSBmb3IgR2V0RGlyZWN0b3J5UG9saWN5LgoKCgoDBAMBEgN0CCEKwgEKBAQDAgASBHgCfQQa
swEgUmVxdWlyZWQuIFRoZSByZXNvdXJjZSBuYW1lIG9mIHRoZSBkaXJlY3RvcnkgcG9saWN5
LgogRGlyZWN0b3J5UG9saWN5IG5hbWVzIGhhdmUgdGhlIGZvcm0KIGBwcm9qZWN0cy97cHJv
amVjdH0vbG9jYXRpb25zL3tsb2NhdGlvbn0vaW5zdGFuY2VzL3tpbnN0YW5jZX0vZGlyZWN0
b3J5UG9saWNpZXMve2lkfWAuCgoMCgUEAwIABRIDeAIICgwKBQQDAgABEgN4CQ0KDAoFBAMC
AAMSA3gQEQoNCgUEAwIACBIEeBJ9AwoPCggEAwIACJwIABIDeQQqCg8KBwQDAgAInwgSBHoE
fAUKOgoCBAQSBoEBAJYBARosIFJlcXVlc3QgbWVzc2FnZSBmb3IgTGlzdERpcmVjdG9yeVBv
bGljaWVzLgoKCwoDBAQBEgSBAQgkCo4BCgQEBAIAEgaFAQKKAQQafiBSZXF1aXJlZC4gVGhl
IHBhcmVudCBpbnN0YW5jZS4KIEl0IG11c3QgYmUgaW4gdGhlIGZvcm1hdCBvZgogYHByb2pl
Y3RzL3twcm9qZWN0fS9sb2NhdGlvbnMve2xvY2F0aW9ufS9pbnN0YW5jZXMve2luc3RhbmNl
fWAuCgoNCgUEBAIABRIEhQECCAoNCgUEBAIAARIEhQEJDwoNCgUEBAIAAxIEhQESEwoPCgUE
BAIACBIGhQEUigEDChAKCAQEAgAInAgAEgSGAQQqChEKBwQEAgAInwgSBocBBIkBBQrkAQoE
BAQCARIEjwECPxrVASBPcHRpb25hbC4gUmVxdWVzdGVkIHBhZ2Ugc2l6ZS4gU2VydmVyIG1p
Z2h0IHJldHVybiBmZXdlciBpdGVtcyB0aGFuCiByZXF1ZXN0ZWQuIElmIHVuc3BlY2lmaWVk
LCB0aGUgc2VydmVyIHdpbGwgcGljayBhbiBhcHByb3ByaWF0ZSBkZWZhdWx0LiBUaGUKIG1h
eGltdW0gdmFsdWUgaXMgMTAwMDsgdmFsdWVzIGFib3ZlIDEwMDAgd2lsbCBiZSBjb2VyY2Vk
IHRvIDEwMDAuCgoNCgUEBAIBBRIEjwECBwoNCgUEBAIBARIEjwEIEQoNCgUEBAIBAxIEjwEU
FQoNCgUEBAIBCBIEjwEWPgoQCggEBAIBCJwIABIEjwEXPQqMAgoEBAQCAhIElQECQRr9ASBP
cHRpb25hbC4gQSBwYWdlIHRva2VuLCByZWNlaXZlZCBmcm9tIGEgcHJldmlvdXMgYExpc3RE
aXJlY3RvcnlQb2xpY2llc2AKIGNhbGwuIFByb3ZpZGUgdGhpcyB0byByZXRyaWV2ZSB0aGUg
c3Vic2VxdWVudCBwYWdlLiBXaGVuIHBhZ2luYXRpbmcsIGFsbAogb3RoZXIgcGFyYW1ldGVy
cyBwcm92aWRlZCB0byBgTGlzdERpcmVjdG9yeVBvbGljaWVzYCBtdXN0IG1hdGNoIHRoZSBj
YWxsCiB0aGF0IHByb3ZpZGVkIHRoZSBwYWdlIHRva2VuLgoKDQoFBAQCAgUSBJUBAggKDQoF
BAQCAgESBJUBCRMKDQoFBAQCAgMSBJUBFhcKDQoFBAQCAggSBJUBGEAKEAoIBAQCAgicCAAS
BJUBGT8KOwoCBAUSBpkBAJ8BARotIFJlc3BvbnNlIG1lc3NhZ2UgZm9yIExpc3REaXJlY3Rv
cnlQb2xpY2llcy4KCgsKAwQFARIEmQEIJQouCgQEBQIAEgSbAQIyGiAgVGhlIGxpc3Qgb2Yg
RGlyZWN0b3J5UG9saWNpZXMuCgoNCgUEBQIABBIEmwECCgoNCgUEBQIABhIEmwELGgoNCgUE
BQIAARIEmwEbLQoNCgUEBQIAAxIEmwEwMQpPCgQEBQIBEgSeAQIdGkEgQSB0b2tlbiBpZGVu
dGlmeWluZyBhIHBhZ2Ugb2YgcmVzdWx0cyB0aGUgc2VydmVyIHNob3VsZCByZXR1cm4uCgoN
CgUEBQIBBRIEngECCAoNCgUEBQIBARIEngEJGAoNCgUEBQIBAxIEngEbHGIGcHJvdG8z
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Lustre::V1::DirectoryPolicy::DirectoryPolicy ===
    # Fields for DirectoryPolicy
    # Field: name Type: 9 ()
    # Field: directory_path Type: 9 ()
    # Field: lustre_project_id Type: 3 ()
    # Field: uid Type: 9 ()
    # Field: state Type: 14 (.google.cloud.lustre.v1.DirectoryPolicy.State)

# Enum: DirectoryPolicy::State
our $DirectoryPolicy_STATE_UNSPECIFIED = 0;
our $DirectoryPolicy_CREATING = 1;
our $DirectoryPolicy_ACTIVE = 2;
our $DirectoryPolicy_DELETING = 3;

# === Message: Google::Cloud::Lustre::V1::DirectoryPolicy::CreateDirectoryPolicyRequest ===
    # Fields for CreateDirectoryPolicyRequest
    # Field: parent Type: 9 ()
    # Field: directory_policy_id Type: 9 ()
    # Field: directory_policy Type: 11 (.google.cloud.lustre.v1.DirectoryPolicy)

# === Message: Google::Cloud::Lustre::V1::DirectoryPolicy::DeleteDirectoryPolicyRequest ===
    # Fields for DeleteDirectoryPolicyRequest
    # Field: name Type: 9 ()

# === Message: Google::Cloud::Lustre::V1::DirectoryPolicy::GetDirectoryPolicyRequest ===
    # Fields for GetDirectoryPolicyRequest
    # Field: name Type: 9 ()

# === Message: Google::Cloud::Lustre::V1::DirectoryPolicy::ListDirectoryPoliciesRequest ===
    # Fields for ListDirectoryPoliciesRequest
    # Field: parent Type: 9 ()
    # Field: page_size Type: 5 ()
    # Field: page_token Type: 9 ()

# === Message: Google::Cloud::Lustre::V1::DirectoryPolicy::ListDirectoryPoliciesResponse ===
    # Fields for ListDirectoryPoliciesResponse
    # Field: directory_policies Type: 11 (.google.cloud.lustre.v1.DirectoryPolicy)
    # Field: next_page_token Type: 9 ()

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Lustre::V1::DirectoryPolicy - Compiled Protocol Buffers messages for google/cloud/lustre/v1/directory_policy.proto

=head1 SYNOPSIS

    use Google::Cloud::Lustre::V1::DirectoryPolicy;

    my $msg = Google::Cloud::Lustre::V1::DirectoryPolicy::DirectoryPolicy->new({
        name => $name,
        directory_path => $directory_path,
        lustre_project_id => $lustre_project_id,
        uid => $uid,
    });

    # Read or update a field
    my $val = $msg->name();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Lustre::V1::DirectoryPolicy::DirectoryPolicy->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/lustre/v1/directory_policy.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Lustre::V1::DirectoryPolicy::DirectoryPolicy

A directory policy for a Managed Lustre instance.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Immutable. Identifier. The resource name of the directory policy.
DirectoryPolicy names have the form
`projects/{project}/locations/{location}/instances/{instance}/directoryPolicies/{id}`.
{id} is user provided.

=item * C<< $msg->directory_path() >> / C<< $msg->directory_path($value) >>

Type: C<String>

Required. Immutable. The lustre instance filesystem full path of the
directory. It must start with a slash. e.g. /lustre/testFolder

=item * C<< $msg->lustre_project_id() >> / C<< $msg->lustre_project_id($value) >>

Type: C<Int64>

Output only. The lustre project ID assigned for the directory by the
service. This read-only ID can be used to manage quotas. See more details
in
https://docs.cloud.google.com/managed-lustre/docs/file-system-quotas#set_quotas

=item * C<< $msg->uid() >> / C<< $msg->uid($value) >>

Type: C<String>

Output only. Unique ID of the resource.

=item * C<< $msg->state() >> / C<< $msg->state($value) >>

Type: C<Enum> (L<Google::Cloud::Lustre::V1::DirectoryPolicy::State>)

Output only. The current state of the directory policy.

=back

=head3 Enum: DirectoryPolicy::State

=over 4

=item * C<STATE_UNSPECIFIED> => C<0>

=item * C<CREATING> => C<1>

=item * C<ACTIVE> => C<2>

=item * C<DELETING> => C<3>

=back

=head2 Google::Cloud::Lustre::V1::DirectoryPolicy::CreateDirectoryPolicyRequest

Request message for CreateDirectoryPolicy.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->parent() >> / C<< $msg->parent($value) >>

Type: C<String>

Required. The parent instance.
It must be in the format of
`projects/{project}/locations/{location}/instances/{instance}`.

=item * C<< $msg->directory_policy_id() >> / C<< $msg->directory_policy_id($value) >>

Type: C<String>

Required. The ID for the DirectoryPolicy to create.

=item * C<< $msg->directory_policy() >> / C<< $msg->directory_policy($value) >>

Type: C<Message> (L<Google::Cloud::Lustre::V1::DirectoryPolicy::DirectoryPolicy>)

Required. The directory policy to create.

=back

=head2 Google::Cloud::Lustre::V1::DirectoryPolicy::DeleteDirectoryPolicyRequest

Request message for DeleteDirectoryPolicy.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. The resource name of the directory policy.
DirectoryPolicy names have the form
`projects/{project}/locations/{location}/instances/{instance}/directoryPolicies/{id}`.

=back

=head2 Google::Cloud::Lustre::V1::DirectoryPolicy::GetDirectoryPolicyRequest

Request message for GetDirectoryPolicy.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. The resource name of the directory policy.
DirectoryPolicy names have the form
`projects/{project}/locations/{location}/instances/{instance}/directoryPolicies/{id}`.

=back

=head2 Google::Cloud::Lustre::V1::DirectoryPolicy::ListDirectoryPoliciesRequest

Request message for ListDirectoryPolicies.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->parent() >> / C<< $msg->parent($value) >>

Type: C<String>

Required. The parent instance.
It must be in the format of
`projects/{project}/locations/{location}/instances/{instance}`.

=item * C<< $msg->page_size() >> / C<< $msg->page_size($value) >>

Type: C<Int32>

Optional. Requested page size. Server might return fewer items than
requested. If unspecified, the server will pick an appropriate default. The
maximum value is 1000; values above 1000 will be coerced to 1000.

=item * C<< $msg->page_token() >> / C<< $msg->page_token($value) >>

Type: C<String>

Optional. A page token, received from a previous `ListDirectoryPolicies`
call. Provide this to retrieve the subsequent page. When paginating, all
other parameters provided to `ListDirectoryPolicies` must match the call
that provided the page token.

=back

=head2 Google::Cloud::Lustre::V1::DirectoryPolicy::ListDirectoryPoliciesResponse

Response message for ListDirectoryPolicies.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->directory_policies() >> / C<< $msg->directory_policies($value) >>

Type: C<Message> (L<Google::Cloud::Lustre::V1::DirectoryPolicy::DirectoryPolicy>)

The list of DirectoryPolicies.

=item * C<< $msg->next_page_token() >> / C<< $msg->next_page_token($value) >>

Type: C<String>

A token identifying a page of results the server should return.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Lustre::V1::DirectoryPolicy::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
