package Google::Cloud::Gkebackup::V1::RestorePlan;

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
    eval { require Google::Cloud::Gkebackup::V1::Restore };
    eval { require Google::Protobuf::Timestamp };
    my $descriptor_b64 = <<'EOF';
Cixnb29nbGUvY2xvdWQvZ2tlYmFja3VwL3YxL3Jlc3RvcmVfcGxhbi5wcm90bxIZZ29vZ2xl
LmNsb3VkLmdrZWJhY2t1cC52MRofZ29vZ2xlL2FwaS9maWVsZF9iZWhhdmlvci5wcm90bxoZ
Z29vZ2xlL2FwaS9yZXNvdXJjZS5wcm90bxonZ29vZ2xlL2Nsb3VkL2drZWJhY2t1cC92MS9y
ZXN0b3JlLnByb3RvGh9nb29nbGUvcHJvdG9idWYvdGltZXN0YW1wLnByb3RvIpAICgtSZXN0
b3JlUGxhbhIXCgRuYW1lGAEgASgJQgPgQQNSBG5hbWUSFQoDdWlkGAIgASgJQgPgQQNSA3Vp
ZBJACgtjcmVhdGVfdGltZRgDIAEoCzIaLmdvb2dsZS5wcm90b2J1Zi5UaW1lc3RhbXBCA+BB
A1IKY3JlYXRlVGltZRJACgt1cGRhdGVfdGltZRgEIAEoCzIaLmdvb2dsZS5wcm90b2J1Zi5U
aW1lc3RhbXBCA+BBA1IKdXBkYXRlVGltZRIlCgtkZXNjcmlwdGlvbhgFIAEoCUID4EEBUgtk
ZXNjcmlwdGlvbhJPCgtiYWNrdXBfcGxhbhgGIAEoCUIu4EEF4EEC+kElCiNna2ViYWNrdXAu
Z29vZ2xlYXBpcy5jb20vQmFja3VwUGxhblIKYmFja3VwUGxhbhJFCgdjbHVzdGVyGAcgASgJ
QivgQQXgQQL6QSIKIGNvbnRhaW5lci5nb29nbGVhcGlzLmNvbS9DbHVzdGVyUgdjbHVzdGVy
ElQKDnJlc3RvcmVfY29uZmlnGAggASgLMiguZ29vZ2xlLmNsb3VkLmdrZWJhY2t1cC52MS5S
ZXN0b3JlQ29uZmlnQgPgQQJSDXJlc3RvcmVDb25maWcSTwoGbGFiZWxzGAkgAygLMjIuZ29v
Z2xlLmNsb3VkLmdrZWJhY2t1cC52MS5SZXN0b3JlUGxhbi5MYWJlbHNFbnRyeUID4EEBUgZs
YWJlbHMSFwoEZXRhZxgKIAEoCUID4EEDUgRldGFnEkcKBXN0YXRlGAsgASgOMiwuZ29vZ2xl
LmNsb3VkLmdrZWJhY2t1cC52MS5SZXN0b3JlUGxhbi5TdGF0ZUID4EEDUgVzdGF0ZRImCgxz
dGF0ZV9yZWFzb24YDCABKAlCA+BBA1ILc3RhdGVSZWFzb24SWAoPcmVzdG9yZV9jaGFubmVs
GA0gASgJQi/gQQP6QSkKJ2drZWJhY2t1cC5nb29nbGVhcGlzLmNvbS9SZXN0b3JlQ2hhbm5l
bFIOcmVzdG9yZUNoYW5uZWwaOQoLTGFiZWxzRW50cnkSEAoDa2V5GAEgASgJUgNrZXkSFAoF
dmFsdWUYAiABKAlSBXZhbHVlOgI4ASJYCgVTdGF0ZRIVChFTVEFURV9VTlNQRUNJRklFRBAA
EhMKD0NMVVNURVJfUEVORElORxABEgkKBVJFQURZEAISCgoGRkFJTEVEEAMSDAoIREVMRVRJ
TkcQBDpu6kFrCiRna2ViYWNrdXAuZ29vZ2xlYXBpcy5jb20vUmVzdG9yZVBsYW4SQ3Byb2pl
Y3RzL3twcm9qZWN0fS9sb2NhdGlvbnMve2xvY2F0aW9ufS9yZXN0b3JlUGxhbnMve3Jlc3Rv
cmVfcGxhbn1CxwEKHWNvbS5nb29nbGUuY2xvdWQuZ2tlYmFja3VwLnYxQhBSZXN0b3JlUGxh
blByb3RvUAFaO2Nsb3VkLmdvb2dsZS5jb20vZ28vZ2tlYmFja3VwL2FwaXYxL2drZWJhY2t1
cHBiO2drZWJhY2t1cHBiqgIZR29vZ2xlLkNsb3VkLkdrZUJhY2t1cC5WMcoCGUdvb2dsZVxD
bG91ZFxHa2VCYWNrdXBcVjHqAhxHb29nbGU6OkNsb3VkOjpHa2VCYWNrdXA6OlYxSosnCgcS
BQ4AjQEBCrwECgEMEgMOABIysQQgQ29weXJpZ2h0IDIwMjUgR29vZ2xlIExMQwoKIExpY2Vu
c2VkIHVuZGVyIHRoZSBBcGFjaGUgTGljZW5zZSwgVmVyc2lvbiAyLjAgKHRoZSAiTGljZW5z
ZSIpOwogeW91IG1heSBub3QgdXNlIHRoaXMgZmlsZSBleGNlcHQgaW4gY29tcGxpYW5jZSB3
aXRoIHRoZSBMaWNlbnNlLgogWW91IG1heSBvYnRhaW4gYSBjb3B5IG9mIHRoZSBMaWNlbnNl
IGF0CgogICAgIGh0dHA6Ly93d3cuYXBhY2hlLm9yZy9saWNlbnNlcy9MSUNFTlNFLTIuMAoK
IFVubGVzcyByZXF1aXJlZCBieSBhcHBsaWNhYmxlIGxhdyBvciBhZ3JlZWQgdG8gaW4gd3Jp
dGluZywgc29mdHdhcmUKIGRpc3RyaWJ1dGVkIHVuZGVyIHRoZSBMaWNlbnNlIGlzIGRpc3Ry
aWJ1dGVkIG9uIGFuICJBUyBJUyIgQkFTSVMsCiBXSVRIT1VUIFdBUlJBTlRJRVMgT1IgQ09O
RElUSU9OUyBPRiBBTlkgS0lORCwgZWl0aGVyIGV4cHJlc3Mgb3IgaW1wbGllZC4KIFNlZSB0
aGUgTGljZW5zZSBmb3IgdGhlIHNwZWNpZmljIGxhbmd1YWdlIGdvdmVybmluZyBwZXJtaXNz
aW9ucyBhbmQKIGxpbWl0YXRpb25zIHVuZGVyIHRoZSBMaWNlbnNlLgoKCAoBAhIDEAAiCgkK
AgMAEgMSACkKCQoCAwESAxMAIwoJCgIDAhIDFAAxCgkKAgMDEgMVACkKCAoBCBIDFwA2CgkK
AgglEgMXADYKCAoBCBIDGABSCgkKAggLEgMYAFIKCAoBCBIDGQAiCgkKAggKEgMZACIKCAoB
CBIDGgAxCgkKAggIEgMaADEKCAoBCBIDGwA2CgkKAggBEgMbADYKCAoBCBIDHAA2CgkKAggp
EgMcADYKCAoBCBIDHQA1CgkKAggtEgMdADUKkQEKAgQAEgUhAI0BARqDASBUaGUgY29uZmln
dXJhdGlvbiBvZiBhIHBvdGVudGlhbCBzZXJpZXMgb2YgUmVzdG9yZSBvcGVyYXRpb25zIHRv
IGJlIHBlcmZvcm1lZAogYWdhaW5zdCBCYWNrdXBzIGJlbG9uZyB0byBhIHBhcnRpY3VsYXIg
QmFja3VwUGxhbi4KCgoKAwQAARIDIQgTCgsKAwQABxIEIgIlBAoNCgUEAAedCBIEIgIlBAoV
CgQEAAQAEgQoAjcDGgcgU3RhdGUKCgwKBQQABAABEgMoBwwKLwoGBAAEAAIAEgMqBBoaICBE
ZWZhdWx0IGZpcnN0IHZhbHVlIGZvciBFbnVtcy4KCg4KBwQABAACAAESAyoEFQoOCgcEAAQA
AgACEgMqGBkKOQoGBAAEAAIBEgMtBBgaKiBXYWl0aW5nIGZvciBjbHVzdGVyIHN0YXRlIHRv
IGJlIFJVTk5JTkcuCgoOCgcEAAQAAgEBEgMtBBMKDgoHBAAEAAIBAhIDLRYXClkKBgQABAAC
AhIDMAQOGkogVGhlIFJlc3RvcmVQbGFuIGhhcyBzdWNjZXNzZnVsbHkgYmVlbiBjcmVhdGVk
IGFuZCBpcyByZWFkeSBmb3IgUmVzdG9yZXMuCgoOCgcEAAQAAgIBEgMwBAkKDgoHBAAEAAIC
AhIDMAwNCjEKBgQABAACAxIDMwQPGiIgUmVzdG9yZVBsYW4gY3JlYXRpb24gaGFzIGZhaWxl
ZC4KCg4KBwQABAACAwESAzMECgoOCgcEAAQAAgMCEgMzDQ4KRAoGBAAEAAIEEgM2BBEaNSBU
aGUgUmVzdG9yZVBsYW4gaXMgaW4gdGhlIHByb2Nlc3Mgb2YgYmVpbmcgZGVsZXRlZC4KCg4K
BwQABAACBAESAzYEDAoOCgcEAAQAAgQCEgM2DxAKeAoEBAACABIDOwI+GmsgT3V0cHV0IG9u
bHkuIFRoZSBmdWxsIG5hbWUgb2YgdGhlIFJlc3RvcmVQbGFuIHJlc291cmNlLgogRm9ybWF0
OiBgcHJvamVjdHMvKi9sb2NhdGlvbnMvKi9yZXN0b3JlUGxhbnMvKmAuCgoMCgUEAAIABRID
OwIICgwKBQQAAgABEgM7CQ0KDAoFBAACAAMSAzsQEQoMCgUEAAIACBIDOxI9Cg8KCAQAAgAI
nAgAEgM7EzwKlgEKBAQAAgESAz8CPRqIASBPdXRwdXQgb25seS4gU2VydmVyIGdlbmVyYXRl
ZCBnbG9iYWwgdW5pcXVlIGlkZW50aWZpZXIgb2YKIFtVVUlEXShodHRwczovL2VuLndpa2lw
ZWRpYS5vcmcvd2lraS9Vbml2ZXJzYWxseV91bmlxdWVfaWRlbnRpZmllcikgZm9ybWF0LgoK
DAoFBAACAQUSAz8CCAoMCgUEAAIBARIDPwkMCgwKBQQAAgEDEgM/DxAKDAoFBAACAQgSAz8R
PAoPCggEAAIBCJwIABIDPxI7ClcKBAQAAgISBEMCRDIaSSBPdXRwdXQgb25seS4gVGhlIHRp
bWVzdGFtcCB3aGVuIHRoaXMgUmVzdG9yZVBsYW4gcmVzb3VyY2Ugd2FzCiBjcmVhdGVkLgoK
DAoFBAACAgYSA0MCGwoMCgUEAAICARIDQxwnCgwKBQQAAgIDEgNDKisKDAoFBAACAggSA0QG
MQoPCggEAAICCJwIABIDRAcwClwKBAQAAgMSBEgCSTIaTiBPdXRwdXQgb25seS4gVGhlIHRp
bWVzdGFtcCB3aGVuIHRoaXMgUmVzdG9yZVBsYW4gcmVzb3VyY2Ugd2FzIGxhc3QKIHVwZGF0
ZWQuCgoMCgUEAAIDBhIDSAIbCgwKBQQAAgMBEgNIHCcKDAoFBAACAwMSA0gqKwoMCgUEAAID
CBIDSQYxCg8KCAQAAgMInAgAEgNJBzAKUAoEBAACBBIDTAJCGkMgT3B0aW9uYWwuIFVzZXIg
c3BlY2lmaWVkIGRlc2NyaXB0aXZlIHN0cmluZyBmb3IgdGhpcyBSZXN0b3JlUGxhbi4KCgwK
BQQAAgQFEgNMAggKDAoFBAACBAESA0wJFAoMCgUEAAIEAxIDTBcYCgwKBQQAAgQIEgNMGUEK
DwoIBAACBAicCAASA0waQAr2AQoEBAACBRIEUgJYBBrnASBSZXF1aXJlZC4gSW1tdXRhYmxl
LiBBIHJlZmVyZW5jZSB0byB0aGUKIFtCYWNrdXBQbGFuXVtnb29nbGUuY2xvdWQuZ2tlYmFj
a3VwLnYxLkJhY2t1cFBsYW5dIGZyb20gd2hpY2ggQmFja3VwcyBtYXkKIGJlIHVzZWQgYXMg
dGhlIHNvdXJjZSBmb3IgUmVzdG9yZXMgY3JlYXRlZCB2aWEgdGhpcyBSZXN0b3JlUGxhbi4g
Rm9ybWF0OgogYHByb2plY3RzLyovbG9jYXRpb25zLyovYmFja3VwUGxhbnMvKmAuCgoMCgUE
AAIFBRIDUgIICgwKBQQAAgUBEgNSCRQKDAoFBAACBQMSA1IXGAoNCgUEAAIFCBIEUhlYAwoP
CggEAAIFCJwIABIDUwQrCg8KCAQAAgUInAgBEgNUBCoKDwoHBAACBQifCBIEVQRXBQqcAgoE
BAACBhIEYAJmBBqNAiBSZXF1aXJlZC4gSW1tdXRhYmxlLiBUaGUgdGFyZ2V0IGNsdXN0ZXIg
aW50byB3aGljaCBSZXN0b3JlcyBjcmVhdGVkIHZpYQogdGhpcyBSZXN0b3JlUGxhbiB3aWxs
IHJlc3RvcmUgZGF0YS4gTk9URTogdGhlIGNsdXN0ZXIncyByZWdpb24gbXVzdCBiZSB0aGUK
IHNhbWUgYXMgdGhlIFJlc3RvcmVQbGFuLiBWYWxpZCBmb3JtYXRzOgoKICAgLSBgcHJvamVj
dHMvKi9sb2NhdGlvbnMvKi9jbHVzdGVycy8qYAogICAtIGBwcm9qZWN0cy8qL3pvbmVzLyov
Y2x1c3RlcnMvKmAKCgwKBQQAAgYFEgNgAggKDAoFBAACBgESA2AJEAoMCgUEAAIGAxIDYBMU
Cg0KBQQAAgYIEgRgFWYDCg8KCAQAAgYInAgAEgNhBCsKDwoIBAACBgicCAESA2IEKgoPCgcE
AAIGCJ8IEgRjBGUFClAKBAQAAgcSA2kCTBpDIFJlcXVpcmVkLiBDb25maWd1cmF0aW9uIG9m
IFJlc3RvcmVzIGNyZWF0ZWQgdmlhIHRoaXMgUmVzdG9yZVBsYW4uCgoMCgUEAAIHBhIDaQIP
CgwKBQQAAgcBEgNpEB4KDAoFBAACBwMSA2khIgoMCgUEAAIHCBIDaSNLCg8KCAQAAgcInAgA
EgNpJEoKQQoEBAACCBIDbAJKGjQgT3B0aW9uYWwuIEEgc2V0IG9mIGN1c3RvbSBsYWJlbHMg
c3VwcGxpZWQgYnkgdXNlci4KCgwKBQQAAggGEgNsAhUKDAoFBAACCAESA2wWHAoMCgUEAAII
AxIDbB8gCgwKBQQAAggIEgNsIUkKDwoIBAACCAicCAASA2wiSAq6BAoEBAACCRIDdgI/GqwE
IE91dHB1dCBvbmx5LiBgZXRhZ2AgaXMgdXNlZCBmb3Igb3B0aW1pc3RpYyBjb25jdXJyZW5j
eSBjb250cm9sIGFzIGEgd2F5IHRvCiBoZWxwIHByZXZlbnQgc2ltdWx0YW5lb3VzIHVwZGF0
ZXMgb2YgYSByZXN0b3JlIGZyb20gb3ZlcndyaXRpbmcgZWFjaCBvdGhlci4KIEl0IGlzIHN0
cm9uZ2x5IHN1Z2dlc3RlZCB0aGF0IHN5c3RlbXMgbWFrZSB1c2Ugb2YgdGhlIGBldGFnYCBp
biB0aGUKIHJlYWQtbW9kaWZ5LXdyaXRlIGN5Y2xlIHRvIHBlcmZvcm0gcmVzdG9yZSB1cGRh
dGVzIGluIG9yZGVyIHRvIGF2b2lkCiByYWNlIGNvbmRpdGlvbnM6IEFuIGBldGFnYCBpcyBy
ZXR1cm5lZCBpbiB0aGUgcmVzcG9uc2UgdG8gYEdldFJlc3RvcmVQbGFuYCwKIGFuZCBzeXN0
ZW1zIGFyZSBleHBlY3RlZCB0byBwdXQgdGhhdCBldGFnIGluIHRoZSByZXF1ZXN0IHRvCiBg
VXBkYXRlUmVzdG9yZVBsYW5gIG9yIGBEZWxldGVSZXN0b3JlUGxhbmAgdG8gZW5zdXJlIHRo
YXQgdGhlaXIgY2hhbmdlCiB3aWxsIGJlIGFwcGxpZWQgdG8gdGhlIHNhbWUgdmVyc2lvbiBv
ZiB0aGUgcmVzb3VyY2UuCgoMCgUEAAIJBRIDdgIICgwKBQQAAgkBEgN2CQ0KDAoFBAACCQMS
A3YQEgoMCgUEAAIJCBIDdhM+Cg8KCAQAAgkInAgAEgN2FD0KmgEKBAQAAgoSA3sCPxqMASBP
dXRwdXQgb25seS4gU3RhdGUgb2YgdGhlIFJlc3RvcmVQbGFuLiBUaGlzIFN0YXRlIGZpZWxk
IHJlZmxlY3RzIHRoZQogdmFyaW91cyBzdGFnZXMgYSBSZXN0b3JlUGxhbiBjYW4gYmUgaW4K
IGR1cmluZyB0aGUgQ3JlYXRlIG9wZXJhdGlvbi4KCgwKBQQAAgoGEgN7AgcKDAoFBAACCgES
A3sIDQoMCgUEAAIKAxIDexASCgwKBQQAAgoIEgN7Ez4KDwoIBAACCgicCAASA3sUPQryAQoE
BAACCxIEgQECRxrjASBPdXRwdXQgb25seS4gSHVtYW4tcmVhZGFibGUgZGVzY3JpcHRpb24g
b2Ygd2h5IFJlc3RvcmVQbGFuIGlzIGluIHRoZQogY3VycmVudCBgc3RhdGVgLiBUaGlzIGZp
ZWxkIGlzIG9ubHkgbWVhbnQgZm9yIGh1bWFuIHJlYWRhYmlsaXR5IGFuZCBzaG91bGQKIG5v
dCBiZSB1c2VkIHByb2dyYW1tYXRpY2FsbHkgYXMgdGhpcyBmaWVsZCBpcyBub3QgZ3VhcmFu
dGVlZCB0byBiZQogY29uc2lzdGVudC4KCg0KBQQAAgsFEgSBAQIICg0KBQQAAgsBEgSBAQkV
Cg0KBQQAAgsDEgSBARgaCg0KBQQAAgsIEgSBARtGChAKCAQAAgsInAgAEgSBARxFCoQCCgQE
AAIMEgaHAQKMAQQa8wEgT3V0cHV0IG9ubHkuIFRoZSBmdWxseSBxdWFsaWZpZWQgbmFtZSBv
ZiB0aGUgUmVzdG9yZUNoYW5uZWwgdG8gYmUgdXNlZCB0bwogY3JlYXRlIGEgUmVzdG9yZVBs
YW4uIFRoaXMgZmllbGQgaXMgc2V0IG9ubHkgaWYgdGhlIGBiYWNrdXBfcGxhbmAgaXMgaW4g
YQogZGlmZmVyZW50IHByb2plY3QgdGhhbiB0aGUgUmVzdG9yZVBsYW4uIEZvcm1hdDoKIGBw
cm9qZWN0cy8qL2xvY2F0aW9ucy8qL3Jlc3RvcmVDaGFubmVscy8qYAoKDQoFBAACDAUSBIcB
AggKDQoFBAACDAESBIcBCRgKDQoFBAACDAMSBIcBGx0KDwoFBAACDAgSBocBHowBAwoQCggE
AAIMCJwIABIEiAEELQoRCgcEAAIMCJ8IEgaJAQSLAQViBnByb3RvMw==
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Gkebackup::V1::RestorePlan::RestorePlan ===
    # Fields for RestorePlan
    # Field: name Type: 9 ()
    # Field: uid Type: 9 ()
    # Field: create_time Type: 11 (.google.protobuf.Timestamp)
    # Field: update_time Type: 11 (.google.protobuf.Timestamp)
    # Field: description Type: 9 ()
    # Field: backup_plan Type: 9 ()
    # Field: cluster Type: 9 ()
    # Field: restore_config Type: 11 (.google.cloud.gkebackup.v1.RestoreConfig)
    # Field: labels Type: 11 (.google.cloud.gkebackup.v1.RestorePlan.LabelsEntry)
    # Field: etag Type: 9 ()
    # Field: state Type: 14 (.google.cloud.gkebackup.v1.RestorePlan.State)
    # Field: state_reason Type: 9 ()
    # Field: restore_channel Type: 9 ()

# Enum: RestorePlan::State
our $RestorePlan_STATE_UNSPECIFIED = 0;
our $RestorePlan_CLUSTER_PENDING = 1;
our $RestorePlan_READY = 2;
our $RestorePlan_FAILED = 3;
our $RestorePlan_DELETING = 4;

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Gkebackup::V1::RestorePlan - Compiled Protocol Buffers messages for google/cloud/gkebackup/v1/restore_plan.proto

=head1 SYNOPSIS

    use Google::Cloud::Gkebackup::V1::RestorePlan;

    my $msg = Google::Cloud::Gkebackup::V1::RestorePlan::RestorePlan->new({
        name => $name,
        uid => $uid,
        create_time => $create_time,
        update_time => $update_time,
    });

    # Read or update a field
    my $val = $msg->name();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Gkebackup::V1::RestorePlan::RestorePlan->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/gkebackup/v1/restore_plan.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Gkebackup::V1::RestorePlan::RestorePlan

The configuration of a potential series of Restore operations to be performed
against Backups belong to a particular BackupPlan.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Output only. The full name of the RestorePlan resource.
Format: `projects/*/locations/*/restorePlans/*`.

=item * C<< $msg->uid() >> / C<< $msg->uid($value) >>

Type: C<String>

Output only. Server generated global unique identifier of
[UUID](https://en.wikipedia.org/wiki/Universally_unique_identifier) format.

=item * C<< $msg->create_time() >> / C<< $msg->create_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Output only. The timestamp when this RestorePlan resource was
created.

=item * C<< $msg->update_time() >> / C<< $msg->update_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Output only. The timestamp when this RestorePlan resource was last
updated.

=item * C<< $msg->description() >> / C<< $msg->description($value) >>

Type: C<String>

Optional. User specified descriptive string for this RestorePlan.

=item * C<< $msg->backup_plan() >> / C<< $msg->backup_plan($value) >>

Type: C<String>

Required. Immutable. A reference to the
[BackupPlan][google.cloud.gkebackup.v1.BackupPlan] from which Backups may
be used as the source for Restores created via this RestorePlan. Format:
`projects/*/locations/*/backupPlans/*`.

=item * C<< $msg->cluster() >> / C<< $msg->cluster($value) >>

Type: C<String>

Required. Immutable. The target cluster into which Restores created via
this RestorePlan will restore data. NOTE: the cluster's region must be the
same as the RestorePlan. Valid formats:

  - `projects/*/locations/*/clusters/*`
  - `projects/*/zones/*/clusters/*`

=item * C<< $msg->restore_config() >> / C<< $msg->restore_config($value) >>

Type: C<Message> (L<Google::Cloud::Gkebackup::V1::Restore::RestoreConfig>)

Required. Configuration of Restores created via this RestorePlan.

=item * C<< $msg->labels() >> / C<< $msg->labels($value) >>

Type: C<Message> (L<Google::Cloud::Gkebackup::V1::RestorePlan::RestorePlan::LabelsEntry>)

Optional. A set of custom labels supplied by user.

=item * C<< $msg->etag() >> / C<< $msg->etag($value) >>

Type: C<String>

Output only. `etag` is used for optimistic concurrency control as a way to
help prevent simultaneous updates of a restore from overwriting each other.
It is strongly suggested that systems make use of the `etag` in the
read-modify-write cycle to perform restore updates in order to avoid
race conditions: An `etag` is returned in the response to `GetRestorePlan`,
and systems are expected to put that etag in the request to
`UpdateRestorePlan` or `DeleteRestorePlan` to ensure that their change
will be applied to the same version of the resource.

=item * C<< $msg->state() >> / C<< $msg->state($value) >>

Type: C<Enum> (L<Google::Cloud::Gkebackup::V1::RestorePlan::State>)

Output only. State of the RestorePlan. This State field reflects the
various stages a RestorePlan can be in
during the Create operation.

=item * C<< $msg->state_reason() >> / C<< $msg->state_reason($value) >>

Type: C<String>

Output only. Human-readable description of why RestorePlan is in the
current `state`. This field is only meant for human readability and should
not be used programmatically as this field is not guaranteed to be
consistent.

=item * C<< $msg->restore_channel() >> / C<< $msg->restore_channel($value) >>

Type: C<String>

Output only. The fully qualified name of the RestoreChannel to be used to
create a RestorePlan. This field is set only if the `backup_plan` is in a
different project than the RestorePlan. Format:
`projects/*/locations/*/restoreChannels/*`

=back

=head3 Enum: RestorePlan::State

=over 4

=item * C<STATE_UNSPECIFIED> => C<0>

=item * C<CLUSTER_PENDING> => C<1>

=item * C<READY> => C<2>

=item * C<FAILED> => C<3>

=item * C<DELETING> => C<4>

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Gkebackup::V1::RestorePlan::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
