package Google::Cloud::Financialservices::V1::EngineVersion;

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
    eval { require Google::Cloud::Financialservices::V1::LineOfBusiness };
    eval { require Google::Protobuf::Timestamp };
    my $descriptor_b64 = <<'EOF';
CjZnb29nbGUvY2xvdWQvZmluYW5jaWFsc2VydmljZXMvdjEvZW5naW5lX3ZlcnNpb24ucHJv
dG8SIWdvb2dsZS5jbG91ZC5maW5hbmNpYWxzZXJ2aWNlcy52MRofZ29vZ2xlL2FwaS9maWVs
ZF9iZWhhdmlvci5wcm90bxoZZ29vZ2xlL2FwaS9yZXNvdXJjZS5wcm90bxo4Z29vZ2xlL2Ns
b3VkL2ZpbmFuY2lhbHNlcnZpY2VzL3YxL2xpbmVfb2ZfYnVzaW5lc3MucHJvdG8aH2dvb2ds
ZS9wcm90b2J1Zi90aW1lc3RhbXAucHJvdG8iiwUKDUVuZ2luZVZlcnNpb24SGgoEbmFtZRgB
IAEoCUIG4EED4EEIUgRuYW1lElEKBXN0YXRlGAIgASgOMjYuZ29vZ2xlLmNsb3VkLmZpbmFu
Y2lhbHNlcnZpY2VzLnYxLkVuZ2luZVZlcnNpb24uU3RhdGVCA+BBA1IFc3RhdGUSZAoeZXhw
ZWN0ZWRfbGltaXRhdGlvbl9zdGFydF90aW1lGAMgASgLMhouZ29vZ2xlLnByb3RvYnVmLlRp
bWVzdGFtcEID4EEDUhtleHBlY3RlZExpbWl0YXRpb25TdGFydFRpbWUSXQoaZXhwZWN0ZWRf
ZGVjb21taXNzaW9uX3RpbWUYBCABKAsyGi5nb29nbGUucHJvdG9idWYuVGltZXN0YW1wQgPg
QQNSGGV4cGVjdGVkRGVjb21taXNzaW9uVGltZRJgChBsaW5lX29mX2J1c2luZXNzGAUgASgO
MjEuZ29vZ2xlLmNsb3VkLmZpbmFuY2lhbHNlcnZpY2VzLnYxLkxpbmVPZkJ1c2luZXNzQgPg
QQNSDmxpbmVPZkJ1c2luZXNzIksKBVN0YXRlEhUKEVNUQVRFX1VOU1BFQ0lGSUVEEAASCgoG
QUNUSVZFEAESCwoHTElNSVRFRBACEhIKDkRFQ09NTUlTU0lPTkVEEAM6lgHqQZIBCi5maW5h
bmNpYWxzZXJ2aWNlcy5nb29nbGVhcGlzLmNvbS9FbmdpbmVWZXJzaW9uEmBwcm9qZWN0cy97
cHJvamVjdF9udW19L2xvY2F0aW9ucy97bG9jYXRpb259L2luc3RhbmNlcy97aW5zdGFuY2V9
L2VuZ2luZVZlcnNpb25zL3tlbmdpbmVfdmVyc2lvbn0i6QEKGUxpc3RFbmdpbmVWZXJzaW9u
c1JlcXVlc3QSSQoGcGFyZW50GAEgASgJQjHgQQL6QSsKKWZpbmFuY2lhbHNlcnZpY2VzLmdv
b2dsZWFwaXMuY29tL0luc3RhbmNlUgZwYXJlbnQSIAoJcGFnZV9zaXplGAIgASgFQgPgQQFS
CHBhZ2VTaXplEiIKCnBhZ2VfdG9rZW4YAyABKAlCA+BBAVIJcGFnZVRva2VuEhsKBmZpbHRl
chgEIAEoCUID4EEBUgZmaWx0ZXISHgoIb3JkZXJfYnkYBSABKAlCA+BBAVIHb3JkZXJCeSLB
AQoaTGlzdEVuZ2luZVZlcnNpb25zUmVzcG9uc2USWQoPZW5naW5lX3ZlcnNpb25zGAEgAygL
MjAuZ29vZ2xlLmNsb3VkLmZpbmFuY2lhbHNlcnZpY2VzLnYxLkVuZ2luZVZlcnNpb25SDmVu
Z2luZVZlcnNpb25zEiYKD25leHRfcGFnZV90b2tlbhgCIAEoCVINbmV4dFBhZ2VUb2tlbhIg
Cgt1bnJlYWNoYWJsZRgDIAMoCVILdW5yZWFjaGFibGUiZQoXR2V0RW5naW5lVmVyc2lvblJl
cXVlc3QSSgoEbmFtZRgBIAEoCUI24EEC+kEwCi5maW5hbmNpYWxzZXJ2aWNlcy5nb29nbGVh
cGlzLmNvbS9FbmdpbmVWZXJzaW9uUgRuYW1lQoECCiVjb20uZ29vZ2xlLmNsb3VkLmZpbmFu
Y2lhbHNlcnZpY2VzLnYxQhJFbmdpbmVWZXJzaW9uUHJvdG9QAVpTY2xvdWQuZ29vZ2xlLmNv
bS9nby9maW5hbmNpYWxzZXJ2aWNlcy9hcGl2MS9maW5hbmNpYWxzZXJ2aWNlc3BiO2ZpbmFu
Y2lhbHNlcnZpY2VzcGKqAiFHb29nbGUuQ2xvdWQuRmluYW5jaWFsU2VydmljZXMuVjHKAiFH
b29nbGVcQ2xvdWRcRmluYW5jaWFsU2VydmljZXNcVjHqAiRHb29nbGU6OkNsb3VkOjpGaW5h
bmNpYWxTZXJ2aWNlczo6VjFK0CQKBxIFDgCKAQEKvAQKAQwSAw4AEjKxBCBDb3B5cmlnaHQg
MjAyNSBHb29nbGUgTExDCgogTGljZW5zZWQgdW5kZXIgdGhlIEFwYWNoZSBMaWNlbnNlLCBW
ZXJzaW9uIDIuMCAodGhlICJMaWNlbnNlIik7CiB5b3UgbWF5IG5vdCB1c2UgdGhpcyBmaWxl
IGV4Y2VwdCBpbiBjb21wbGlhbmNlIHdpdGggdGhlIExpY2Vuc2UuCiBZb3UgbWF5IG9idGFp
biBhIGNvcHkgb2YgdGhlIExpY2Vuc2UgYXQKCiAgICAgaHR0cDovL3d3dy5hcGFjaGUub3Jn
L2xpY2Vuc2VzL0xJQ0VOU0UtMi4wCgogVW5sZXNzIHJlcXVpcmVkIGJ5IGFwcGxpY2FibGUg
bGF3IG9yIGFncmVlZCB0byBpbiB3cml0aW5nLCBzb2Z0d2FyZQogZGlzdHJpYnV0ZWQgdW5k
ZXIgdGhlIExpY2Vuc2UgaXMgZGlzdHJpYnV0ZWQgb24gYW4gIkFTIElTIiBCQVNJUywKIFdJ
VEhPVVQgV0FSUkFOVElFUyBPUiBDT05ESVRJT05TIE9GIEFOWSBLSU5ELCBlaXRoZXIgZXhw
cmVzcyBvciBpbXBsaWVkLgogU2VlIHRoZSBMaWNlbnNlIGZvciB0aGUgc3BlY2lmaWMgbGFu
Z3VhZ2UgZ292ZXJuaW5nIHBlcm1pc3Npb25zIGFuZAogbGltaXRhdGlvbnMgdW5kZXIgdGhl
IExpY2Vuc2UuCgoICgECEgMQACoKCQoCAwASAxIAKQoJCgIDARIDEwAjCgkKAgMCEgMUAEIK
CQoCAwMSAxUAKQoICgEIEgMXAD4KCQoCCCUSAxcAPgoICgEIEgMYAGoKCQoCCAsSAxgAagoI
CgEIEgMZACIKCQoCCAoSAxkAIgoICgEIEgMaADMKCQoCCAgSAxoAMwoICgEIEgMbAD4KCQoC
CAESAxsAPgoICgEIEgMcAD4KCQoCCCkSAxwAPgoICgEIEgMdAD0KCQoCCC0SAx0APQpsCgIE
ABIEIQBSARpgIEVuZ2luZVZlcnNpb24gY29udHJvbHMgd2hpY2ggdmVyc2lvbiBvZiB0aGUg
ZW5naW5lIGlzIHVzZWQgdG8gdHVuZSwgdHJhaW4sCiBhbmQgcnVuIHRoZSBtb2RlbC4KCgoK
AwQAARIDIQgVCgsKAwQABxIEIgIlBAoNCgUEAAedCBIEIgIlBAprCgQEAAQAEgQpAjYDGl0g
U3RhdGUgZGV0ZXJtaW5lcyB0aGUgbGlmZWN5Y2xlIG9mIGEgdmVyc2lvbiBhbmQgdGhlIG1v
ZGVscy9lbmdpbmUgY29uZmlncwogdHJhaW5lZCB3aXRoIGl0LgoKDAoFBAAEAAESAykHDAo1
CgYEAAQAAgASAysEGhomIERlZmF1bHQgc3RhdGUsIHNob3VsZCBuZXZlciBiZSB1c2VkLgoK
DgoHBAAEAAIAARIDKwQVCg4KBwQABAACAAISAysYGQpBCgYEAAQAAgESAy4EDxoyIFZlcnNp
b24gaXMgYXZhaWxhYmxlIGZvciB0cmFpbmluZyBhbmQgaW5mZXJlbmNlLgoKDgoHBAAEAAIB
ARIDLgQKCg4KBwQABAACAQISAy4NDgpdCgYEAAQAAgISAzIEEBpOIE1vZGVscyB1c2luZyB0
aGlzIHZlcnNpb24gY2FuIHN0aWxsIGJlIHJ1biwgYnV0IG5ldyBvbmVzIGNhbm5vdCBiZQog
dHJhaW5lZC4KCg4KBwQABAACAgESAzIECwoOCgcEAAQAAgICEgMyDg8KTwoGBAAEAAIDEgM1
BBcaQCBWZXJzaW9uIGlzIGRlcHJlY2F0ZWQsIGxpc3RlZCBmb3IgaW5mb3JtYXRpb25hbCBw
dXJwb3NlcyBvbmx5LgoKDgoHBAAEAAIDARIDNQQSCg4KBwQABAACAwISAzUVFgq+AQoEBAAC
ABIEOwI+BBqvASBPdXRwdXQgb25seS4gSWRlbnRpZmllci4gVGhlIHJlc291cmNlIG5hbWUg
b2YgdGhlIEVuZ2luZVZlcnNpb24KIGZvcm1hdDoKIGAvcHJvamVjdHMve3Byb2plY3RfbnVt
fS9sb2NhdGlvbnMve2xvY2F0aW9ufS9pbnN0YW5jZXMve2luc3RhbmNlfS9lbmdpbmVWZXJz
aW9ucy97ZW5naW5lX3ZlcnNpb259YAoKDAoFBAACAAUSAzsCCAoMCgUEAAIAARIDOwkNCgwK
BQQAAgADEgM7EBEKDQoFBAACAAgSBDsSPgMKDwoIBAACAAicCAASAzwELQoPCggEAAIACJwI
ARIDPQQsCjUKBAQAAgESA0ECPhooIE91dHB1dCBvbmx5LiBUaGUgc3RhdGUgb2YgdGhlIHZl
cnNpb24uCgoMCgUEAAIBBhIDQQIHCgwKBQQAAgEBEgNBCA0KDAoFBAACAQMSA0EQEQoMCgUE
AAIBCBIDQRI9Cg8KCAQAAgEInAgAEgNBEzwKowEKBAQAAgISBEUCRjIalAEgT3V0cHV0IG9u
bHkuIFBsYW5uZWQgdGltZSB0byBzdG9wIGFsbG93aW5nIHRyYWluaW5nL3R1bmluZyB1c2lu
ZyB0aGlzCiB2ZXJzaW9uLiBFeGlzdGluZyB0cmFpbmVkIG1vZGVscyBjYW4gc3RpbGwgYmUg
dXNlZCBmb3IgcHJlZGljdGlvbi9iYWNrdGVzdC4KCgwKBQQAAgIGEgNFAhsKDAoFBAACAgES
A0UcOgoMCgUEAAICAxIDRT0+CgwKBQQAAgIIEgNGBjEKDwoIBAACAgicCAASA0YHMArAAQoE
BAACAxIESwJMMhqxASBPdXRwdXQgb25seS4gUGxhbm5lZCB0aW1lIHRvIHN0b3Agc3VwcG9y
dGluZyB0aGUgdmVyc2lvbiwgaW4gYWRkaXRpb24KIHRvIG5vIHRyYWluaW5nIG9yIHR1bmlu
ZywgbW9kZWxzIHRyYWluZWQgb24gdGhpcyB2ZXJzaW9uCiBjYW4gbm8gbG9uZ2VyIGJlIHVz
ZWQgZm9yIHByZWRpY3Rpb24vYmFja3Rlc3QuCgoMCgUEAAIDBhIDSwIbCgwKBQQAAgMBEgNL
HDYKDAoFBAACAwMSA0s5OgoMCgUEAAIDCBIDTAYxCg8KCAQAAgMInAgAEgNMBzAKZwoEBAAC
BBIEUAJRMhpZIE91dHB1dCBvbmx5LiBUaGUgbGluZSBvZiBidXNpbmVzcyAoUmV0YWlsL0Nv
bW1lcmNpYWwpIHRoaXMgZW5naW5lIHZlcnNpb24KIGlzIHVzZWQgZm9yLgoKDAoFBAACBAYS
A1ACEAoMCgUEAAIEARIDUBEhCgwKBQQAAgQDEgNQJCUKDAoFBAACBAgSA1EGMQoPCggEAAIE
CJwIABIDUQcwCnMKAgQBEgRWAHIBGmcgUmVxdWVzdCBmb3IgcmV0cmlldmluZyBhIHBhZ2lu
YXRlZCBsaXN0IG9mIEVuZ2luZVZlcnNpb24gcmVzb3VyY2VzIHRoYXQgbWVldAogdGhlIHNw
ZWNpZmllZCBjcml0ZXJpYS4KCgoKAwQBARIDVgghCkoKBAQBAgASBFgCXQQaPCBSZXF1aXJl
ZC4gVGhlIHBhcmVudCBvZiB0aGUgRW5naW5lVmVyc2lvbiBpcyB0aGUgSW5zdGFuY2UuCgoM
CgUEAQIABRIDWAIICgwKBQQBAgABEgNYCQ8KDAoFBAECAAMSA1gSEwoNCgUEAQIACBIEWBRd
AwoPCggEAQIACJwIABIDWQQqCg8KBwQBAgAInwgSBFoEXAUKtgEKBAQBAgESA2ICPxqoASBP
cHRpb25hbC4gVGhlIG51bWJlciBvZiByZXNvdXJjZXMgdG8gYmUgaW5jbHVkZWQgaW4gdGhl
IHJlc3BvbnNlLiBUaGUKIHJlc3BvbnNlIGNvbnRhaW5zIGEgbmV4dF9wYWdlX3Rva2VuLCB3
aGljaCBjYW4gYmUgdXNlZCB0byByZXRyaWV2ZSB0aGUgbmV4dAogcGFnZSBvZiByZXNvdXJj
ZXMuCgoMCgUEAQIBBRIDYgIHCgwKBQQBAgEBEgNiCBEKDAoFBAECAQMSA2IUFQoMCgUEAQIB
CBIDYhY+Cg8KCAQBAgEInAgAEgNiFz0KvAIKBAQBAgISA2kCQRquAiBPcHRpb25hbC4gSW4g
Y2FzZSBvZiBwYWdpbmF0ZWQgcmVzdWx0cywgdGhpcyBpcyB0aGUgdG9rZW4gdGhhdCB3YXMg
cmV0dXJuZWQKIGluIHRoZSBwcmV2aW91cyBMaXN0RW5naW5lVmVyc2lvbnNSZXNwb25zZS4g
SXQgc2hvdWxkIGJlIGNvcGllZCBoZXJlIHRvCiByZXRyaWV2ZSB0aGUgbmV4dCBwYWdlIG9m
IHJlc291cmNlcy4gRW1wdHkgd2lsbCBnaXZlIHRoZSBmaXJzdCBwYWdlIG9mCiBMaXN0RW5n
aW5lVmVyc2lvbnNSZXF1ZXN0LCBhbmQgdGhlIGxhc3QgcGFnZSB3aWxsIHJldHVybiBhbiBl
bXB0eQogcGFnZV90b2tlbi4KCgwKBQQBAgIFEgNpAggKDAoFBAECAgESA2kJEwoMCgUEAQIC
AxIDaRYXCgwKBQQBAgIIEgNpGEAKDwoIBAECAgicCAASA2kZPwq8AQoEBAECAxIDbgI9Gq4B
IE9wdGlvbmFsLiBTcGVjaWZ5IGEgZmlsdGVyIHRvIG5hcnJvdyBzZWFyY2ggcmVzdWx0cy4K
IElmIGVtcHR5IG9yIHVuc2V0IHdpbGwgZGVmYXVsdCB0byAic3RhdGUhPURFUFJFQ0FURUQi
LAogdG8gdmlldyBkZXByZWNhdGVkIHZlcnNpb25zIHVzZSAic3RhdGU6KiIgb3IgYW55IG90
aGVyIGZpbHRlci4KCgwKBQQBAgMFEgNuAggKDAoFBAECAwESA24JDwoMCgUEAQIDAxIDbhIT
CgwKBQQBAgMIEgNuFDwKDwoIBAECAwicCAASA24VOwo9CgQEAQIEEgNxAj8aMCBPcHRpb25h
bC4gU3BlY2lmeSBhIGZpZWxkIHRvIHVzZSBmb3Igb3JkZXJpbmcuCgoMCgUEAQIEBRIDcQII
CgwKBQQBAgQBEgNxCREKDAoFBAECBAMSA3EUFQoMCgUEAQIECBIDcRY+Cg8KCAQBAgQInAgA
EgNxFz0KUQoCBAISBHUAfwEaRSBUaGUgcmVzcG9uc2UgdG8gYSBsaXN0IGNhbGwgY29udGFp
bmluZyB0aGUgbGlzdCBvZiBlbmdpbmUgdmVyc2lvbnMuCgoKCgMEAgESA3UIIgouCgQEAgIA
EgN3Ai0aISBMaXN0IG9mIEVuZ2luZVZlcnNpb24gcmVzb3VyY2VzCgoMCgUEAgIABBIDdwIK
CgwKBQQCAgAGEgN3CxgKDAoFBAICAAESA3cZKAoMCgUEAgIAAxIDdyssCpkBCgQEAgIBEgN7
Ah0aiwEgVGhpcyB0b2tlbiBzaG91bGQgYmUgcGFzc2VkIHRvIHRoZSBuZXh0IEVuZ2luZVZl
cnNpb25zUmVxdWVzdCB0byByZXRyaWV2ZQogdGhlIG5leHQgcGFnZSBvZiBFbmdpbmVWZXJz
aW9ucyAoZW1wdHkgaW5kaWNhdGVzIHdlIGFyZSBkb25lKS4KCgwKBQQCAgEFEgN7AggKDAoF
BAICAQESA3sJGAoMCgUEAgIBAxIDexscCjMKBAQCAgISA34CIhomIExvY2F0aW9ucyB0aGF0
IGNvdWxkIG5vdCBiZSByZWFjaGVkLgoKDAoFBAICAgQSA34CCgoMCgUEAgICBRIDfgsRCgwK
BQQCAgIBEgN+Eh0KDAoFBAICAgMSA34gIQpJCgIEAxIGggEAigEBGjsgUmVxdWVzdCBmb3Ig
cmV0cmlldmluZyBhIHNwZWNpZmljIEVuZ2luZVZlcnNpb24gcmVzb3VyY2UuCgoLCgMEAwES
BIIBCB8KQgoEBAMCABIGhAECiQEEGjIgUmVxdWlyZWQuIFRoZSByZXNvdXJjZSBuYW1lIG9m
IHRoZSBFbmdpbmVWZXJzaW9uCgoNCgUEAwIABRIEhAECCAoNCgUEAwIAARIEhAEJDQoNCgUE
AwIAAxIEhAEQEQoPCgUEAwIACBIGhAESiQEDChAKCAQDAgAInAgAEgSFAQQqChEKBwQDAgAI
nwgSBoYBBIgBBWIGcHJvdG8z
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Financialservices::V1::EngineVersion::EngineVersion ===
    # Fields for EngineVersion
    # Field: name Type: 9 ()
    # Field: state Type: 14 (.google.cloud.financialservices.v1.EngineVersion.State)
    # Field: expected_limitation_start_time Type: 11 (.google.protobuf.Timestamp)
    # Field: expected_decommission_time Type: 11 (.google.protobuf.Timestamp)
    # Field: line_of_business Type: 14 (.google.cloud.financialservices.v1.LineOfBusiness)

# Enum: EngineVersion::State
our $EngineVersion_STATE_UNSPECIFIED = 0;
our $EngineVersion_ACTIVE = 1;
our $EngineVersion_LIMITED = 2;
our $EngineVersion_DECOMMISSIONED = 3;

# === Message: Google::Cloud::Financialservices::V1::EngineVersion::ListEngineVersionsRequest ===
    # Fields for ListEngineVersionsRequest
    # Field: parent Type: 9 ()
    # Field: page_size Type: 5 ()
    # Field: page_token Type: 9 ()
    # Field: filter Type: 9 ()
    # Field: order_by Type: 9 ()

# === Message: Google::Cloud::Financialservices::V1::EngineVersion::ListEngineVersionsResponse ===
    # Fields for ListEngineVersionsResponse
    # Field: engine_versions Type: 11 (.google.cloud.financialservices.v1.EngineVersion)
    # Field: next_page_token Type: 9 ()
    # Field: unreachable Type: 9 ()

# === Message: Google::Cloud::Financialservices::V1::EngineVersion::GetEngineVersionRequest ===
    # Fields for GetEngineVersionRequest
    # Field: name Type: 9 ()

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Financialservices::V1::EngineVersion - Compiled Protocol Buffers messages for google/cloud/financialservices/v1/engine_version.proto

=head1 SYNOPSIS

    use Google::Cloud::Financialservices::V1::EngineVersion;

    my $msg = Google::Cloud::Financialservices::V1::EngineVersion::EngineVersion->new({
        name => $name,
        state => $state,
        expected_limitation_start_time => $expected_limitation_start_time,
        expected_decommission_time => $expected_decommission_time,
    });

    # Read or update a field
    my $val = $msg->name();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Financialservices::V1::EngineVersion::EngineVersion->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/financialservices/v1/engine_version.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Financialservices::V1::EngineVersion::EngineVersion

EngineVersion controls which version of the engine is used to tune, train,
and run the model.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Output only. Identifier. The resource name of the EngineVersion
format:
`/projects/{project_num}/locations/{location}/instances/{instance}/engineVersions/{engine_version}`

=item * C<< $msg->state() >> / C<< $msg->state($value) >>

Type: C<Enum> (L<Google::Cloud::Financialservices::V1::EngineVersion::State>)

Output only. The state of the version.

=item * C<< $msg->expected_limitation_start_time() >> / C<< $msg->expected_limitation_start_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Output only. Planned time to stop allowing training/tuning using this
version. Existing trained models can still be used for prediction/backtest.

=item * C<< $msg->expected_decommission_time() >> / C<< $msg->expected_decommission_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Output only. Planned time to stop supporting the version, in addition
to no training or tuning, models trained on this version
can no longer be used for prediction/backtest.

=item * C<< $msg->line_of_business() >> / C<< $msg->line_of_business($value) >>

Type: C<Enum> (L<Google::Cloud::Financialservices::V1::LineOfBusiness>)

Output only. The line of business (Retail/Commercial) this engine version
is used for.

=back

=head3 Enum: EngineVersion::State

=over 4

=item * C<STATE_UNSPECIFIED> => C<0>

=item * C<ACTIVE> => C<1>

=item * C<LIMITED> => C<2>

=item * C<DECOMMISSIONED> => C<3>

=back

=head2 Google::Cloud::Financialservices::V1::EngineVersion::ListEngineVersionsRequest

Request for retrieving a paginated list of EngineVersion resources that meet
the specified criteria.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->parent() >> / C<< $msg->parent($value) >>

Type: C<String>

Required. The parent of the EngineVersion is the Instance.

=item * C<< $msg->page_size() >> / C<< $msg->page_size($value) >>

Type: C<Int32>

Optional. The number of resources to be included in the response. The
response contains a next_page_token, which can be used to retrieve the next
page of resources.

=item * C<< $msg->page_token() >> / C<< $msg->page_token($value) >>

Type: C<String>

Optional. In case of paginated results, this is the token that was returned
in the previous ListEngineVersionsResponse. It should be copied here to
retrieve the next page of resources. Empty will give the first page of
ListEngineVersionsRequest, and the last page will return an empty
page_token.

=item * C<< $msg->filter() >> / C<< $msg->filter($value) >>

Type: C<String>

Optional. Specify a filter to narrow search results.
If empty or unset will default to "state!=DEPRECATED",
to view deprecated versions use "state:*" or any other filter.

=item * C<< $msg->order_by() >> / C<< $msg->order_by($value) >>

Type: C<String>

Optional. Specify a field to use for ordering.

=back

=head2 Google::Cloud::Financialservices::V1::EngineVersion::ListEngineVersionsResponse

The response to a list call containing the list of engine versions.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->engine_versions() >> / C<< $msg->engine_versions($value) >>

Type: C<Message> (L<Google::Cloud::Financialservices::V1::EngineVersion::EngineVersion>)

List of EngineVersion resources

=item * C<< $msg->next_page_token() >> / C<< $msg->next_page_token($value) >>

Type: C<String>

This token should be passed to the next EngineVersionsRequest to retrieve
the next page of EngineVersions (empty indicates we are done).

=item * C<< $msg->unreachable() >> / C<< $msg->unreachable($value) >>

Type: C<String>

Locations that could not be reached.

=back

=head2 Google::Cloud::Financialservices::V1::EngineVersion::GetEngineVersionRequest

Request for retrieving a specific EngineVersion resource.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. The resource name of the EngineVersion

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Financialservices::V1::EngineVersion::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
