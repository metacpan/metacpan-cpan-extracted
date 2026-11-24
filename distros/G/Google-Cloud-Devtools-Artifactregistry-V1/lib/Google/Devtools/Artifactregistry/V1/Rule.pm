package Google::Devtools::Artifactregistry::V1::Rule;

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
    eval { require Google::Type::Expr };
    my $descriptor_b64 = <<'EOF';
Ci5nb29nbGUvZGV2dG9vbHMvYXJ0aWZhY3RyZWdpc3RyeS92MS9ydWxlLnByb3RvEiNnb29n
bGUuZGV2dG9vbHMuYXJ0aWZhY3RyZWdpc3RyeS52MRofZ29vZ2xlL2FwaS9maWVsZF9iZWhh
dmlvci5wcm90bxoZZ29vZ2xlL2FwaS9yZXNvdXJjZS5wcm90bxogZ29vZ2xlL3Byb3RvYnVm
L2ZpZWxkX21hc2sucHJvdG8aFmdvb2dsZS90eXBlL2V4cHIucHJvdG8i9AMKBFJ1bGUSEgoE
bmFtZRgBIAEoCVIEbmFtZRJICgZhY3Rpb24YAiABKA4yMC5nb29nbGUuZGV2dG9vbHMuYXJ0
aWZhY3RyZWdpc3RyeS52MS5SdWxlLkFjdGlvblIGYWN0aW9uElEKCW9wZXJhdGlvbhgDIAEo
DjIzLmdvb2dsZS5kZXZ0b29scy5hcnRpZmFjdHJlZ2lzdHJ5LnYxLlJ1bGUuT3BlcmF0aW9u
UglvcGVyYXRpb24SNAoJY29uZGl0aW9uGAQgASgLMhEuZ29vZ2xlLnR5cGUuRXhwckID4EEB
Ugljb25kaXRpb24SHQoKcGFja2FnZV9pZBgFIAEoCVIJcGFja2FnZUlkIjUKBkFjdGlvbhIW
ChJBQ1RJT05fVU5TUEVDSUZJRUQQABIJCgVBTExPVxABEggKBERFTlkQAiI0CglPcGVyYXRp
b24SGQoVT1BFUkFUSU9OX1VOU1BFQ0lGSUVEEAASDAoIRE9XTkxPQUQQATp56kF2CiRhcnRp
ZmFjdHJlZ2lzdHJ5Lmdvb2dsZWFwaXMuY29tL1J1bGUSTnByb2plY3RzL3twcm9qZWN0fS9s
b2NhdGlvbnMve2xvY2F0aW9ufS9yZXBvc2l0b3JpZXMve3JlcG9zaXRvcnl9L3J1bGVzL3ty
dWxlfSKUAQoQTGlzdFJ1bGVzUmVxdWVzdBJECgZwYXJlbnQYASABKAlCLOBBAvpBJhIkYXJ0
aWZhY3RyZWdpc3RyeS5nb29nbGVhcGlzLmNvbS9SdWxlUgZwYXJlbnQSGwoJcGFnZV9zaXpl
GAIgASgFUghwYWdlU2l6ZRIdCgpwYWdlX3Rva2VuGAMgASgJUglwYWdlVG9rZW4ifAoRTGlz
dFJ1bGVzUmVzcG9uc2USPwoFcnVsZXMYASADKAsyKS5nb29nbGUuZGV2dG9vbHMuYXJ0aWZh
Y3RyZWdpc3RyeS52MS5SdWxlUgVydWxlcxImCg9uZXh0X3BhZ2VfdG9rZW4YAiABKAlSDW5l
eHRQYWdlVG9rZW4iUgoOR2V0UnVsZVJlcXVlc3QSQAoEbmFtZRgBIAEoCUIs4EEC+kEmCiRh
cnRpZmFjdHJlZ2lzdHJ5Lmdvb2dsZWFwaXMuY29tL1J1bGVSBG5hbWUisQEKEUNyZWF0ZVJ1
bGVSZXF1ZXN0EkQKBnBhcmVudBgBIAEoCUIs4EEC+kEmEiRhcnRpZmFjdHJlZ2lzdHJ5Lmdv
b2dsZWFwaXMuY29tL1J1bGVSBnBhcmVudBIXCgdydWxlX2lkGAIgASgJUgZydWxlSWQSPQoE
cnVsZRgDIAEoCzIpLmdvb2dsZS5kZXZ0b29scy5hcnRpZmFjdHJlZ2lzdHJ5LnYxLlJ1bGVS
BHJ1bGUijwEKEVVwZGF0ZVJ1bGVSZXF1ZXN0Ej0KBHJ1bGUYASABKAsyKS5nb29nbGUuZGV2
dG9vbHMuYXJ0aWZhY3RyZWdpc3RyeS52MS5SdWxlUgRydWxlEjsKC3VwZGF0ZV9tYXNrGAIg
ASgLMhouZ29vZ2xlLnByb3RvYnVmLkZpZWxkTWFza1IKdXBkYXRlTWFzayJVChFEZWxldGVS
dWxlUmVxdWVzdBJACgRuYW1lGAEgASgJQizgQQL6QSYKJGFydGlmYWN0cmVnaXN0cnkuZ29v
Z2xlYXBpcy5jb20vUnVsZVIEbmFtZUL0AQonY29tLmdvb2dsZS5kZXZ0b29scy5hcnRpZmFj
dHJlZ2lzdHJ5LnYxQglSdWxlUHJvdG9QAVpQY2xvdWQuZ29vZ2xlLmNvbS9nby9hcnRpZmFj
dHJlZ2lzdHJ5L2FwaXYxL2FydGlmYWN0cmVnaXN0cnlwYjthcnRpZmFjdHJlZ2lzdHJ5cGKq
AiBHb29nbGUuQ2xvdWQuQXJ0aWZhY3RSZWdpc3RyeS5WMcoCIEdvb2dsZVxDbG91ZFxBcnRp
ZmFjdFJlZ2lzdHJ5XFYx6gIjR29vZ2xlOjpDbG91ZDo6QXJ0aWZhY3RSZWdpc3RyeTo6VjFK
jiIKBxIFDgCcAQEKvAQKAQwSAw4AEjKxBCBDb3B5cmlnaHQgMjAyNiBHb29nbGUgTExDCgog
TGljZW5zZWQgdW5kZXIgdGhlIEFwYWNoZSBMaWNlbnNlLCBWZXJzaW9uIDIuMCAodGhlICJM
aWNlbnNlIik7CiB5b3UgbWF5IG5vdCB1c2UgdGhpcyBmaWxlIGV4Y2VwdCBpbiBjb21wbGlh
bmNlIHdpdGggdGhlIExpY2Vuc2UuCiBZb3UgbWF5IG9idGFpbiBhIGNvcHkgb2YgdGhlIExp
Y2Vuc2UgYXQKCiAgICAgaHR0cDovL3d3dy5hcGFjaGUub3JnL2xpY2Vuc2VzL0xJQ0VOU0Ut
Mi4wCgogVW5sZXNzIHJlcXVpcmVkIGJ5IGFwcGxpY2FibGUgbGF3IG9yIGFncmVlZCB0byBp
biB3cml0aW5nLCBzb2Z0d2FyZQogZGlzdHJpYnV0ZWQgdW5kZXIgdGhlIExpY2Vuc2UgaXMg
ZGlzdHJpYnV0ZWQgb24gYW4gIkFTIElTIiBCQVNJUywKIFdJVEhPVVQgV0FSUkFOVElFUyBP
UiBDT05ESVRJT05TIE9GIEFOWSBLSU5ELCBlaXRoZXIgZXhwcmVzcyBvciBpbXBsaWVkLgog
U2VlIHRoZSBMaWNlbnNlIGZvciB0aGUgc3BlY2lmaWMgbGFuZ3VhZ2UgZ292ZXJuaW5nIHBl
cm1pc3Npb25zIGFuZAogbGltaXRhdGlvbnMgdW5kZXIgdGhlIExpY2Vuc2UuCgoICgECEgMQ
ACwKCQoCAwASAxIAKQoJCgIDARIDEwAjCgkKAgMCEgMUACoKCQoCAwMSAxUAIAoICgEIEgMX
AD0KCQoCCCUSAxcAPQoICgEIEgMYAGcKCQoCCAsSAxgAZwoICgEIEgMZACIKCQoCCAoSAxkA
IgoICgEIEgMaACoKCQoCCAgSAxoAKgoICgEIEgMbAEAKCQoCCAESAxsAQAoICgEIEgMcAD0K
CQoCCCkSAxwAPQoICgEIEgMdADwKCQoCCC0SAx0APAreAQoCBAASBCIATQEa0QEgQSBydWxl
IGRlZmluZXMgdGhlIGRlbnkgb3IgYWxsb3cgYWN0aW9uIG9mIHRoZSBvcGVyYXRpb24gaXQg
YXBwbGllcyB0byBhbmQKIHRoZSBjb25kaXRpb25zIHJlcXVpcmVkIGZvciB0aGUgcnVsZSB0
byBhcHBseS4gWW91IGNhbiBzZXQgb25lIHJ1bGUgZm9yIGFuCiBlbnRpcmUgcmVwb3NpdG9y
eSBhbmQgb25lIHJ1bGUgZm9yIGVhY2ggcGFja2FnZSB3aXRoaW4uCgoKCgMEAAESAyIIDAoL
CgMEAAcSBCMCJgQKDQoFBAAHnQgSBCMCJgQKLwoEBAAEABIEKQIyAxohIERlZmluZXMgdGhl
IGFjdGlvbiBvZiB0aGUgcnVsZS4KCgwKBQQABAABEgMpBw0KJgoGBAAEAAIAEgMrBBsaFyBB
Y3Rpb24gbm90IHNwZWNpZmllZC4KCg4KBwQABAACAAESAysEFgoOCgcEAAQAAgACEgMrGRoK
JQoGBAAEAAIBEgMuBA4aFiBBbGxvdyB0aGUgb3BlcmF0aW9uLgoKDgoHBAAEAAIBARIDLgQJ
Cg4KBwQABAACAQISAy4MDQokCgYEAAQAAgISAzEEDRoVIERlbnkgdGhlIG9wZXJhdGlvbi4K
Cg4KBwQABAACAgESAzEECAoOCgcEAAQAAgICEgMxCwwKMgoEBAAEARIENQI7AxokIFRoZSBv
cGVyYXRpb24gdGhlIHJ1bGUgYXBwbGllcyB0by4KCgwKBQQABAEBEgM1BxAKKQoGBAAEAQIA
EgM3BB4aGiBPcGVyYXRpb24gbm90IHNwZWNpZmllZC4KCg4KBwQABAECAAESAzcEGQoOCgcE
AAQBAgACEgM3HB0KJAoGBAAEAQIBEgM6BBEaFSBEb3dubG9hZCBvcGVyYXRpb24uCgoOCgcE
AAQBAgEBEgM6BAwKDgoHBAAEAQIBAhIDOg8QCnYKBAQAAgASAz8CEhppIFRoZSBuYW1lIG9m
IHRoZSBydWxlLCBmb3IgZXhhbXBsZToKIGBwcm9qZWN0cy9wMS9sb2NhdGlvbnMvdXMtY2Vu
dHJhbDEvcmVwb3NpdG9yaWVzL3JlcG8xL3J1bGVzL3J1bGUxYC4KCgwKBQQAAgAFEgM/AggK
DAoFBAACAAESAz8JDQoMCgUEAAIAAxIDPxARCioKBAQAAgESA0ICFBodIFRoZSBhY3Rpb24g
dGhpcyBydWxlIHRha2VzLgoKDAoFBAACAQYSA0ICCAoMCgUEAAIBARIDQgkPCgwKBQQAAgED
EgNCEhMKCwoEBAACAhIDRAIaCgwKBQQAAgIGEgNEAgsKDAoFBAACAgESA0QMFQoMCgUEAAIC
AxIDRBgZCpoBCgQEAAIDEgNIAkoajAEgT3B0aW9uYWwuIEEgQ0VMIGV4cHJlc3Npb24gZm9y
IGNvbmRpdGlvbnMgdGhhdCBtdXN0IGJlIG1ldCBpbiBvcmRlciBmb3IgdGhlCiBydWxlIHRv
IGFwcGx5LiBJZiBub3QgcHJvdmlkZWQsIHRoZSBydWxlIG1hdGNoZXMgYWxsIG9iamVjdHMu
CgoMCgUEAAIDBhIDSAISCgwKBQQAAgMBEgNIExwKDAoFBAACAwMSA0gfIAoMCgUEAAIDCBID
SCFJCg8KCAQAAgMInAgAEgNIIkgKdgoEBAACBBIDTAIYGmkgVGhlIHBhY2thZ2UgSUQgdGhl
IHJ1bGUgYXBwbGllcyB0by4KIElmIGVtcHR5LCB0aGlzIHJ1bGUgYXBwbGllcyB0byBhbGwg
cGFja2FnZXMgaW5zaWRlIHRoZSByZXBvc2l0b3J5LgoKDAoFBAACBAUSA0wCCAoMCgUEAAIE
ARIDTAkTCgwKBQQAAgQDEgNMFhcKKAoCBAESBFAAYAEaHCBUaGUgcmVxdWVzdCB0byBsaXN0
IHJ1bGVzLgoKCgoDBAEBEgNQCBgKnwEKBAQBAgASBFQCWQQakAEgUmVxdWlyZWQuIFRoZSBu
YW1lIG9mIHRoZSBwYXJlbnQgcmVwb3NpdG9yeSB3aG9zZSBydWxlcyB3aWxsIGJlIGxpc3Rl
ZC4KIEZvciBleGFtcGxlOgogYHByb2plY3RzL3AxL2xvY2F0aW9ucy91cy1jZW50cmFsMS9y
ZXBvc2l0b3JpZXMvcmVwbzFgLgoKDAoFBAECAAUSA1QCCAoMCgUEAQIAARIDVAkPCgwKBQQB
AgADEgNUEhMKDQoFBAECAAgSBFQUWQMKDwoIBAECAAicCAASA1UEKgoPCgcEAQIACJ8IEgRW
BFgFClEKBAQBAgESA1wCFhpEIFRoZSBtYXhpbXVtIG51bWJlciBvZiBydWxlcyB0byByZXR1
cm4uIE1heGltdW0gcGFnZSBzaXplIGlzIDEsMDAwLgoKDAoFBAECAQUSA1wCBwoMCgUEAQIB
ARIDXAgRCgwKBQQBAgEDEgNcFBUKVwoEBAECAhIDXwIYGkogVGhlIG5leHRfcGFnZV90b2tl
biB2YWx1ZSByZXR1cm5lZCBmcm9tIGEgcHJldmlvdXMgbGlzdCByZXF1ZXN0LCBpZiBhbnku
CgoMCgUEAQICBRIDXwIICgwKBQQBAgIBEgNfCRMKDAoFBAECAgMSA18WFwouCgIEAhIEYwBq
ARoiIFRoZSByZXNwb25zZSBmcm9tIGxpc3RpbmcgcnVsZXMuCgoKCgMEAgESA2MIGQoiCgQE
AgIAEgNlAhoaFSBUaGUgcnVsZXMgcmV0dXJuZWQuCgoMCgUEAgIABBIDZQIKCgwKBQQCAgAG
EgNlCw8KDAoFBAICAAESA2UQFQoMCgUEAgIAAxIDZRgZCmwKBAQCAgESA2kCHRpfIFRoZSB0
b2tlbiB0byByZXRyaWV2ZSB0aGUgbmV4dCBwYWdlIG9mIHJ1bGVzLCBvciBlbXB0eSBpZiB0
aGVyZSBhcmUgbm8KIG1vcmUgcnVsZXMgdG8gcmV0dXJuLgoKDAoFBAICAQUSA2kCCAoMCgUE
AgIBARIDaQkYCgwKBQQCAgEDEgNpGxwKLQoCBAMSBG0AdQEaISBUaGUgcmVxdWVzdCB0byBy
ZXRyaWV2ZSBhIHJ1bGUuCgoKCgMEAwESA20IFgo7CgQEAwIAEgRvAnQEGi0gUmVxdWlyZWQu
IFRoZSBuYW1lIG9mIHRoZSBydWxlIHRvIHJldHJpZXZlLgoKDAoFBAMCAAUSA28CCAoMCgUE
AwIAARIDbwkNCgwKBQQDAgADEgNvEBEKDQoFBAMCAAgSBG8SdAMKDwoIBAMCAAicCAASA3AE
KgoPCgcEAwIACJ8IEgRxBHMFCjAKAgQEEgV4AIYBARojIFRoZSByZXF1ZXN0IHRvIGNyZWF0
ZSBhIG5ldyBydWxlLgoKCgoDBAQBEgN4CBkKWQoEBAQCABIEegJ/BBpLIFJlcXVpcmVkLiBU
aGUgbmFtZSBvZiB0aGUgcGFyZW50IHJlc291cmNlIHdoZXJlIHRoZSBydWxlIHdpbGwgYmUg
Y3JlYXRlZC4KCgwKBQQEAgAFEgN6AggKDAoFBAQCAAESA3oJDwoMCgUEBAIAAxIDehITCg0K
BQQEAgAIEgR6FH8DCg8KCAQEAgAInAgAEgN7BCoKDwoHBAQCAAifCBIEfAR+BQo3CgQEBAIB
EgSCAQIVGikgVGhlIHJ1bGUgaWQgdG8gdXNlIGZvciB0aGlzIHJlcG9zaXRvcnkuCgoNCgUE
BAIBBRIEggECCAoNCgUEBAIBARIEggEJEAoNCgUEBAIBAxIEggETFAonCgQEBAICEgSFAQIQ
GhkgVGhlIHJ1bGUgdG8gYmUgY3JlYXRlZC4KCg0KBQQEAgIGEgSFAQIGCg0KBQQEAgIBEgSF
AQcLCg0KBQQEAgIDEgSFAQ4PCi0KAgQFEgaJAQCRAQEaHyBUaGUgcmVxdWVzdCB0byB1cGRh
dGUgYSBydWxlLgoKCwoDBAUBEgSJAQgZCkIKBAQFAgASBIsBAhAaNCBUaGUgcnVsZSB0aGF0
IHJlcGxhY2VzIHRoZSByZXNvdXJjZSBvbiB0aGUgc2VydmVyLgoKDQoFBAUCAAYSBIsBAgYK
DQoFBAUCAAESBIsBBwsKDQoFBAUCAAMSBIsBDg8KtwEKBAQFAgESBJABAiwaqAEgVGhlIHVw
ZGF0ZSBtYXNrIGFwcGxpZXMgdG8gdGhlIHJlc291cmNlLiBGb3IgdGhlIGBGaWVsZE1hc2tg
IGRlZmluaXRpb24sCiBzZWUKIGh0dHBzOi8vZGV2ZWxvcGVycy5nb29nbGUuY29tL3Byb3Rv
Y29sLWJ1ZmZlcnMvZG9jcy9yZWZlcmVuY2UvZ29vZ2xlLnByb3RvYnVmI2ZpZWxkbWFzawoK
DQoFBAUCAQYSBJABAhsKDQoFBAUCAQESBJABHCcKDQoFBAUCAQMSBJABKisKLQoCBAYSBpQB
AJwBARofIFRoZSByZXF1ZXN0IHRvIGRlbGV0ZSBhIHJ1bGUuCgoLCgMEBgESBJQBCBkKOwoE
BAYCABIGlgECmwEEGisgUmVxdWlyZWQuIFRoZSBuYW1lIG9mIHRoZSBydWxlIHRvIGRlbGV0
ZS4KCg0KBQQGAgAFEgSWAQIICg0KBQQGAgABEgSWAQkNCg0KBQQGAgADEgSWARARCg8KBQQG
AgAIEgaWARKbAQMKEAoIBAYCAAicCAASBJcBBCoKEQoHBAYCAAifCBIGmAEEmgEFYgZwcm90
bzM=
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Devtools::Artifactregistry::V1::Rule::Rule ===
    # Fields for Rule
    # Field: name Type: 9 ()
    # Field: action Type: 14 (.google.devtools.artifactregistry.v1.Rule.Action)
    # Field: operation Type: 14 (.google.devtools.artifactregistry.v1.Rule.Operation)
    # Field: condition Type: 11 (.google.type.Expr)
    # Field: package_id Type: 9 ()

# Enum: Rule::Action
our $Rule_ACTION_UNSPECIFIED = 0;
our $Rule_ALLOW = 1;
our $Rule_DENY = 2;

# Enum: Rule::Operation
our $Rule_OPERATION_UNSPECIFIED = 0;
our $Rule_DOWNLOAD = 1;

# === Message: Google::Devtools::Artifactregistry::V1::Rule::ListRulesRequest ===
    # Fields for ListRulesRequest
    # Field: parent Type: 9 ()
    # Field: page_size Type: 5 ()
    # Field: page_token Type: 9 ()

# === Message: Google::Devtools::Artifactregistry::V1::Rule::ListRulesResponse ===
    # Fields for ListRulesResponse
    # Field: rules Type: 11 (.google.devtools.artifactregistry.v1.Rule)
    # Field: next_page_token Type: 9 ()

# === Message: Google::Devtools::Artifactregistry::V1::Rule::GetRuleRequest ===
    # Fields for GetRuleRequest
    # Field: name Type: 9 ()

# === Message: Google::Devtools::Artifactregistry::V1::Rule::CreateRuleRequest ===
    # Fields for CreateRuleRequest
    # Field: parent Type: 9 ()
    # Field: rule_id Type: 9 ()
    # Field: rule Type: 11 (.google.devtools.artifactregistry.v1.Rule)

# === Message: Google::Devtools::Artifactregistry::V1::Rule::UpdateRuleRequest ===
    # Fields for UpdateRuleRequest
    # Field: rule Type: 11 (.google.devtools.artifactregistry.v1.Rule)
    # Field: update_mask Type: 11 (.google.protobuf.FieldMask)

# === Message: Google::Devtools::Artifactregistry::V1::Rule::DeleteRuleRequest ===
    # Fields for DeleteRuleRequest
    # Field: name Type: 9 ()

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Devtools::Artifactregistry::V1::Rule - Compiled Protocol Buffers messages for google/devtools/artifactregistry/v1/rule.proto

=head1 SYNOPSIS

    use Google::Devtools::Artifactregistry::V1::Rule;

    my $msg = Google::Devtools::Artifactregistry::V1::Rule::Rule->new({
        name => $name,
        action => $action,
        operation => $operation,
        condition => $condition,
    });

    # Read or update a field
    my $val = $msg->name();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Devtools::Artifactregistry::V1::Rule::Rule->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/devtools/artifactregistry/v1/rule.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Devtools::Artifactregistry::V1::Rule::Rule

A rule defines the deny or allow action of the operation it applies to and
the conditions required for the rule to apply. You can set one rule for an
entire repository and one rule for each package within.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

The name of the rule, for example:
`projects/p1/locations/us-central1/repositories/repo1/rules/rule1`.

=item * C<< $msg->action() >> / C<< $msg->action($value) >>

Type: C<Enum> (L<Google::Devtools::Artifactregistry::V1::Rule::Action>)

The action this rule takes.

=item * C<< $msg->operation() >> / C<< $msg->operation($value) >>

Type: C<Enum> (L<Google::Devtools::Artifactregistry::V1::Rule::Operation>)

=item * C<< $msg->condition() >> / C<< $msg->condition($value) >>

Type: C<Message> (L<Google::Type::Expr::Expr>)

Optional. A CEL expression for conditions that must be met in order for the
rule to apply. If not provided, the rule matches all objects.

=item * C<< $msg->package_id() >> / C<< $msg->package_id($value) >>

Type: C<String>

The package ID the rule applies to.
If empty, this rule applies to all packages inside the repository.

=back

=head3 Enum: Rule::Action

=over 4

=item * C<ACTION_UNSPECIFIED> => C<0>

=item * C<ALLOW> => C<1>

=item * C<DENY> => C<2>

=back

=head3 Enum: Rule::Operation

=over 4

=item * C<OPERATION_UNSPECIFIED> => C<0>

=item * C<DOWNLOAD> => C<1>

=back

=head2 Google::Devtools::Artifactregistry::V1::Rule::ListRulesRequest

The request to list rules.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->parent() >> / C<< $msg->parent($value) >>

Type: C<String>

Required. The name of the parent repository whose rules will be listed.
For example:
`projects/p1/locations/us-central1/repositories/repo1`.

=item * C<< $msg->page_size() >> / C<< $msg->page_size($value) >>

Type: C<Int32>

The maximum number of rules to return. Maximum page size is 1,000.

=item * C<< $msg->page_token() >> / C<< $msg->page_token($value) >>

Type: C<String>

The next_page_token value returned from a previous list request, if any.

=back

=head2 Google::Devtools::Artifactregistry::V1::Rule::ListRulesResponse

The response from listing rules.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->rules() >> / C<< $msg->rules($value) >>

Type: C<Message> (L<Google::Devtools::Artifactregistry::V1::Rule::Rule>)

The rules returned.

=item * C<< $msg->next_page_token() >> / C<< $msg->next_page_token($value) >>

Type: C<String>

The token to retrieve the next page of rules, or empty if there are no
more rules to return.

=back

=head2 Google::Devtools::Artifactregistry::V1::Rule::GetRuleRequest

The request to retrieve a rule.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. The name of the rule to retrieve.

=back

=head2 Google::Devtools::Artifactregistry::V1::Rule::CreateRuleRequest

The request to create a new rule.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->parent() >> / C<< $msg->parent($value) >>

Type: C<String>

Required. The name of the parent resource where the rule will be created.

=item * C<< $msg->rule_id() >> / C<< $msg->rule_id($value) >>

Type: C<String>

The rule id to use for this repository.

=item * C<< $msg->rule() >> / C<< $msg->rule($value) >>

Type: C<Message> (L<Google::Devtools::Artifactregistry::V1::Rule::Rule>)

The rule to be created.

=back

=head2 Google::Devtools::Artifactregistry::V1::Rule::UpdateRuleRequest

The request to update a rule.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->rule() >> / C<< $msg->rule($value) >>

Type: C<Message> (L<Google::Devtools::Artifactregistry::V1::Rule::Rule>)

The rule that replaces the resource on the server.

=item * C<< $msg->update_mask() >> / C<< $msg->update_mask($value) >>

Type: C<Message> (L<Google::Protobuf::FieldMask::FieldMask>)

The update mask applies to the resource. For the `FieldMask` definition,
see
https://developers.google.com/protocol-buffers/docs/reference/google.protobuf#fieldmask

=back

=head2 Google::Devtools::Artifactregistry::V1::Rule::DeleteRuleRequest

The request to delete a rule.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. The name of the rule to delete.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Devtools::Artifactregistry::V1::Rule::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
