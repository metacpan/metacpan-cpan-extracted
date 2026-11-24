package Google::Cloud::Ces::V1::Schema;

use strict;
use warnings;

our $VERSION = '0.14';

use Protobuf::Message;
use Protobuf::DescriptorPool;
use Protobuf::Internal qw(:all);
use MIME::Base64;

BEGIN {
    eval { require Google::Api::FieldBehavior };
    eval { require Google::Protobuf::Struct };
    my $descriptor_b64 = <<'EOF';
CiBnb29nbGUvY2xvdWQvY2VzL3YxL3NjaGVtYS5wcm90bxITZ29vZ2xlLmNsb3VkLmNlcy52
MRofZ29vZ2xlL2FwaS9maWVsZF9iZWhhdmlvci5wcm90bxocZ29vZ2xlL3Byb3RvYnVmL3N0
cnVjdC5wcm90byKyCQoGU2NoZW1hEjkKBHR5cGUYASABKA4yIC5nb29nbGUuY2xvdWQuY2Vz
LnYxLlNjaGVtYS5UeXBlQgPgQQJSBHR5cGUSUAoKcHJvcGVydGllcxgCIAMoCzIrLmdvb2ds
ZS5jbG91ZC5jZXMudjEuU2NoZW1hLlByb3BlcnRpZXNFbnRyeUID4EEBUgpwcm9wZXJ0aWVz
Eh8KCHJlcXVpcmVkGAMgAygJQgPgQQFSCHJlcXVpcmVkEiUKC2Rlc2NyaXB0aW9uGAQgASgJ
QgPgQQFSC2Rlc2NyaXB0aW9uEjYKBWl0ZW1zGAUgASgLMhsuZ29vZ2xlLmNsb3VkLmNlcy52
MS5TY2hlbWFCA+BBAVIFaXRlbXMSHwoIbnVsbGFibGUYBiABKAhCA+BBAVIIbnVsbGFibGUS
JgoMdW5pcXVlX2l0ZW1zGAcgASgIQgPgQQFSC3VuaXF1ZUl0ZW1zEkMKDHByZWZpeF9pdGVt
cxgIIAMoCzIbLmdvb2dsZS5jbG91ZC5jZXMudjEuU2NoZW1hQgPgQQFSC3ByZWZpeEl0ZW1z
ElUKFWFkZGl0aW9uYWxfcHJvcGVydGllcxgJIAEoCzIbLmdvb2dsZS5jbG91ZC5jZXMudjEu
U2NoZW1hQgPgQQFSFGFkZGl0aW9uYWxQcm9wZXJ0aWVzEjcKBmFueV9vZhgKIAMoCzIbLmdv
b2dsZS5jbG91ZC5jZXMudjEuU2NoZW1hQgPgQQFSBWFueU9mEhcKBGVudW0YCyADKAlCA+BB
AVIEZW51bRI1CgdkZWZhdWx0GAwgASgLMhYuZ29vZ2xlLnByb3RvYnVmLlZhbHVlQgPgQQFS
B2RlZmF1bHQSFQoDcmVmGA0gASgJQgPgQQFSA3JlZhI+CgRkZWZzGA4gAygLMiUuZ29vZ2xl
LmNsb3VkLmNlcy52MS5TY2hlbWEuRGVmc0VudHJ5QgPgQQFSBGRlZnMSGQoFdGl0bGUYDyAB
KAlCA+BBAVIFdGl0bGUSIAoJbWluX2l0ZW1zGBAgASgDQgPgQQFSCG1pbkl0ZW1zEiAKCW1h
eF9pdGVtcxgRIAEoA0ID4EEBUghtYXhJdGVtcxIiCgdtaW5pbXVtGBIgASgBQgPgQQFIAFIH
bWluaW11bYgBARIiCgdtYXhpbXVtGBMgASgBQgPgQQFIAVIHbWF4aW11bYgBARpaCg9Qcm9w
ZXJ0aWVzRW50cnkSEAoDa2V5GAEgASgJUgNrZXkSMQoFdmFsdWUYAiABKAsyGy5nb29nbGUu
Y2xvdWQuY2VzLnYxLlNjaGVtYVIFdmFsdWU6AjgBGlQKCURlZnNFbnRyeRIQCgNrZXkYASAB
KAlSA2tleRIxCgV2YWx1ZRgCIAEoCzIbLmdvb2dsZS5jbG91ZC5jZXMudjEuU2NoZW1hUgV2
YWx1ZToCOAEiZQoEVHlwZRIUChBUWVBFX1VOU1BFQ0lGSUVEEAASCgoGU1RSSU5HEAESCwoH
SU5URUdFUhACEgoKBk5VTUJFUhADEgsKB0JPT0xFQU4QBBIKCgZPQkpFQ1QQBRIJCgVBUlJB
WRAGQgoKCF9taW5pbXVtQgoKCF9tYXhpbXVtQlMKF2NvbS5nb29nbGUuY2xvdWQuY2VzLnYx
QgtTY2hlbWFQcm90b1ABWiljbG91ZC5nb29nbGUuY29tL2dvL2Nlcy9hcGl2MS9jZXNwYjtj
ZXNwYkqSJgoHEgUOAIsBAQq8BAoBDBIDDgASMrEEIENvcHlyaWdodCAyMDI2IEdvb2dsZSBM
TEMKCiBMaWNlbnNlZCB1bmRlciB0aGUgQXBhY2hlIExpY2Vuc2UsIFZlcnNpb24gMi4wICh0
aGUgIkxpY2Vuc2UiKTsKIHlvdSBtYXkgbm90IHVzZSB0aGlzIGZpbGUgZXhjZXB0IGluIGNv
bXBsaWFuY2Ugd2l0aCB0aGUgTGljZW5zZS4KIFlvdSBtYXkgb2J0YWluIGEgY29weSBvZiB0
aGUgTGljZW5zZSBhdAoKICAgICBodHRwOi8vd3d3LmFwYWNoZS5vcmcvbGljZW5zZXMvTElD
RU5TRS0yLjAKCiBVbmxlc3MgcmVxdWlyZWQgYnkgYXBwbGljYWJsZSBsYXcgb3IgYWdyZWVk
IHRvIGluIHdyaXRpbmcsIHNvZnR3YXJlCiBkaXN0cmlidXRlZCB1bmRlciB0aGUgTGljZW5z
ZSBpcyBkaXN0cmlidXRlZCBvbiBhbiAiQVMgSVMiIEJBU0lTLAogV0lUSE9VVCBXQVJSQU5U
SUVTIE9SIENPTkRJVElPTlMgT0YgQU5ZIEtJTkQsIGVpdGhlciBleHByZXNzIG9yIGltcGxp
ZWQuCiBTZWUgdGhlIExpY2Vuc2UgZm9yIHRoZSBzcGVjaWZpYyBsYW5ndWFnZSBnb3Zlcm5p
bmcgcGVybWlzc2lvbnMgYW5kCiBsaW1pdGF0aW9ucyB1bmRlciB0aGUgTGljZW5zZS4KCggK
AQISAxAAHAoJCgIDABIDEgApCgkKAgMBEgMTACYKCAoBCBIDFQBACgkKAggLEgMVAEAKCAoB
CBIDFgAiCgkKAggKEgMWACIKCAoBCBIDFwAsCgkKAggIEgMXACwKCAoBCBIDGAAwCgkKAggB
EgMYADAKSgoCBAASBRsAiwEBGj0gUmVwcmVzZW50cyBhIHNlbGVjdCBzdWJzZXQgb2YgYW4g
T3BlbkFQSSAzLjAgc2NoZW1hIG9iamVjdC4KCgoKAwQAARIDGwgOCiMKBAQABAASBB0CMgMa
FSBPcGVuQVBJIGRhdGEgdHlwZXMuCgoMCgUEAAQAARIDHQcLCiIKBgQABAACABIDHwQZGhMg
VHlwZSB1bnNwZWNpZmllZC4KCg4KBwQABAACAAESAx8EFAoOCgcEAAQAAgACEgMfFxgKHQoG
BAAEAAIBEgMiBA8aDiBTdHJpbmcgdHlwZS4KCg4KBwQABAACAQESAyIECgoOCgcEAAQAAgEC
EgMiDQ4KHgoGBAAEAAICEgMlBBAaDyBJbnRlZ2VyIHR5cGUuCgoOCgcEAAQAAgIBEgMlBAsK
DgoHBAAEAAICAhIDJQ4PCh0KBgQABAACAxIDKAQPGg4gTnVtYmVyIHR5cGUuCgoOCgcEAAQA
AgMBEgMoBAoKDgoHBAAEAAIDAhIDKA0OCh4KBgQABAACBBIDKwQQGg8gQm9vbGVhbiB0eXBl
LgoKDgoHBAAEAAIEARIDKwQLCg4KBwQABAACBAISAysODwodCgYEAAQAAgUSAy4EDxoOIE9i
amVjdCB0eXBlLgoKDgoHBAAEAAIFARIDLgQKCg4KBwQABAACBQISAy4NDgocCgYEAAQAAgYS
AzEEDhoNIEFycmF5IHR5cGUuCgoOCgcEAAQAAgYBEgMxBAkKDgoHBAAEAAIGAhIDMQwNCi4K
BAQAAgASAzUCORohIFJlcXVpcmVkLiBUaGUgdHlwZSBvZiB0aGUgZGF0YS4KCgwKBQQAAgAG
EgM1AgYKDAoFBAACAAESAzUHCwoMCgUEAAIAAxIDNQ4PCgwKBQQAAgAIEgM1EDgKDwoIBAAC
AAicCAASAzURNwozCgQEAAIBEgM4Ak4aJiBPcHRpb25hbC4gUHJvcGVydGllcyBvZiBUeXBl
Lk9CSkVDVC4KCgwKBQQAAgEGEgM4AhUKDAoFBAACAQESAzgWIAoMCgUEAAIBAxIDOCMkCgwK
BQQAAgEIEgM4JU0KDwoIBAACAQicCAASAzgmTAo8CgQEAAICEgM7AkgaLyBPcHRpb25hbC4g
UmVxdWlyZWQgcHJvcGVydGllcyBvZiBUeXBlLk9CSkVDVC4KCgwKBQQAAgIEEgM7AgoKDAoF
BAACAgUSAzsLEQoMCgUEAAICARIDOxIaCgwKBQQAAgIDEgM7HR4KDAoFBAACAggSAzsfRwoP
CggEAAICCJwIABIDOyBGCjUKBAQAAgMSAz4CQhooIE9wdGlvbmFsLiBUaGUgZGVzY3JpcHRp
b24gb2YgdGhlIGRhdGEuCgoMCgUEAAIDBRIDPgIICgwKBQQAAgMBEgM+CRQKDAoFBAACAwMS
Az4XGAoMCgUEAAIDCBIDPhlBCg8KCAQAAgMInAgAEgM+GkAKPgoEBAACBBIDQQI8GjEgT3B0
aW9uYWwuIFNjaGVtYSBvZiB0aGUgZWxlbWVudHMgb2YgVHlwZS5BUlJBWS4KCgwKBQQAAgQG
EgNBAggKDAoFBAACBAESA0EJDgoMCgUEAAIEAxIDQRESCgwKBQQAAgQIEgNBEzsKDwoIBAAC
BAicCAASA0EUOgo8CgQEAAIFEgNEAj0aLyBPcHRpb25hbC4gSW5kaWNhdGVzIGlmIHRoZSB2
YWx1ZSBtYXkgYmUgbnVsbC4KCgwKBQQAAgUFEgNEAgYKDAoFBAACBQESA0QHDwoMCgUEAAIF
AxIDRBITCgwKBQQAAgUIEgNEFDwKDwoIBAACBQicCAASA0QVOwplCgQEAAIGEgNIAkEaWCBP
cHRpb25hbC4gSW5kaWNhdGUgdGhlIGl0ZW1zIGluIHRoZSBhcnJheSBtdXN0IGJlIHVuaXF1
ZS4gT25seSBhcHBsaWVzIHRvCiBUWVBFLkFSUkFZLgoKDAoFBAACBgUSA0gCBgoMCgUEAAIG
ARIDSAcTCgwKBQQAAgYDEgNIFhcKDAoFBAACBggSA0gYQAoPCggEAAIGCJwIABIDSBk/CkMK
BAQAAgcSA0sCTBo2IE9wdGlvbmFsLiBTY2hlbWFzIG9mIGluaXRpYWwgZWxlbWVudHMgb2Yg
VHlwZS5BUlJBWS4KCgwKBQQAAgcEEgNLAgoKDAoFBAACBwYSA0sLEQoMCgUEAAIHARIDSxIe
CgwKBQQAAgcDEgNLISIKDAoFBAACBwgSA0sjSwoPCggEAAIHCJwIABIDSyRKCm8KBAQAAggS
A08CTBpiIE9wdGlvbmFsLiBDYW4gZWl0aGVyIGJlIGEgYm9vbGVhbiBvciBhbiBvYmplY3Qs
IGNvbnRyb2xzIHRoZSBwcmVzZW5jZSBvZgogYWRkaXRpb25hbCBwcm9wZXJ0aWVzLgoKDAoF
BAACCAYSA08CCAoMCgUEAAIIARIDTwkeCgwKBQQAAggDEgNPISIKDAoFBAACCAgSA08jSwoP
CggEAAIICJwIABIDTyRKCnAKBAQAAgkSA1MCRxpjIE9wdGlvbmFsLiBUaGUgdmFsdWUgc2hv
dWxkIGJlIHZhbGlkYXRlZCBhZ2FpbnN0IGFueSAob25lIG9yIG1vcmUpIG9mIHRoZQogc3Vi
c2NoZW1hcyBpbiB0aGUgbGlzdC4KCgwKBQQAAgkEEgNTAgoKDAoFBAACCQYSA1MLEQoMCgUE
AAIJARIDUxIYCgwKBQQAAgkDEgNTGx0KDAoFBAACCQgSA1MeRgoPCggEAAIJCJwIABIDUx9F
Cq0CCgQEAAIKEgNbAkUanwIgT3B0aW9uYWwuIFBvc3NpYmxlIHZhbHVlcyBvZiB0aGUgZWxl
bWVudCBvZiBwcmltaXRpdmUgdHlwZSB3aXRoIGVudW0KIGZvcm1hdC4gRXhhbXBsZXM6CiAx
LiBXZSBjYW4gZGVmaW5lIGRpcmVjdGlvbiBhcyA6CiB7dHlwZTpTVFJJTkcsIGZvcm1hdDpl
bnVtLCBlbnVtOlsiRUFTVCIsIE5PUlRIIiwgIlNPVVRIIiwgIldFU1QiXX0KIDIuIFdlIGNh
biBkZWZpbmUgYXBhcnRtZW50IG51bWJlciBhcyA6CiB7dHlwZTpJTlRFR0VSLCBmb3JtYXQ6
ZW51bSwgZW51bTpbIjEwMSIsICIyMDEiLCAiMzAxIl19CgoMCgUEAAIKBBIDWwIKCgwKBQQA
AgoFEgNbCxEKDAoFBAACCgESA1sSFgoMCgUEAAIKAxIDWxkbCgwKBQQAAgoIEgNbHEQKDwoI
BAACCgicCAASA1sdQwozCgQEAAILEgNeAk4aJiBPcHRpb25hbC4gRGVmYXVsdCB2YWx1ZSBv
ZiB0aGUgZGF0YS4KCgwKBQQAAgsGEgNeAhcKDAoFBAACCwESA14YHwoMCgUEAAILAxIDXiIk
CgwKBQQAAgsIEgNeJU0KDwoIBAACCwicCAASA14mTAqhBAoEBAACDBIDdwI7GpMEIE9wdGlv
bmFsLiBBbGxvd3MgaW5kaXJlY3QgcmVmZXJlbmNlcyBiZXR3ZWVuIHNjaGVtYSBub2Rlcy4g
VGhlIHZhbHVlIHNob3VsZAogYmUgYSB2YWxpZCByZWZlcmVuY2UgdG8gYSBjaGlsZCBvZiB0
aGUgcm9vdCBgZGVmc2AuCgogRm9yIGV4YW1wbGUsIHRoZSBmb2xsb3dpbmcgc2NoZW1hIGRl
ZmluZXMgYSByZWZlcmVuY2UgdG8gYSBzY2hlbWEgbm9kZQogbmFtZWQgIlBldCI6CgogYGBg
CiB0eXBlOiBvYmplY3QKIHByb3BlcnRpZXM6CiAgIHBldDoKICAgICByZWY6ICMvZGVmcy9Q
ZXQKIGRlZnM6CiAgIFBldDoKICAgICB0eXBlOiBvYmplY3QKICAgICBwcm9wZXJ0aWVzOgog
ICAgICAgbmFtZToKICAgICAgICAgdHlwZTogc3RyaW5nCiBgYGAKCiBUaGUgdmFsdWUgb2Yg
dGhlICJwZXQiIHByb3BlcnR5IGlzIGEgcmVmZXJlbmNlIHRvIHRoZSBzY2hlbWEgbm9kZQog
bmFtZWQgIlBldCIuCiBTZWUgZGV0YWlscyBpbgogaHR0cHM6Ly9qc29uLXNjaGVtYS5vcmcv
dW5kZXJzdGFuZGluZy1qc29uLXNjaGVtYS9zdHJ1Y3R1cmluZy4KCgwKBQQAAgwFEgN3AggK
DAoFBAACDAESA3cJDAoMCgUEAAIMAxIDdw8RCgwKBQQAAgwIEgN3EjoKDwoIBAACDAicCAAS
A3cTOQpoCgQEAAINEgN7AkkaWyBPcHRpb25hbC4gQSBtYXAgb2YgZGVmaW5pdGlvbnMgZm9y
IHVzZSBieSBgcmVmYC4gT25seSBhbGxvd2VkIGF0IHRoZSByb290CiBvZiB0aGUgc2NoZW1h
LgoKDAoFBAACDQYSA3sCFQoMCgUEAAINARIDexYaCgwKBQQAAg0DEgN7HR8KDAoFBAACDQgS
A3sgSAoPCggEAAINCJwIABIDeyFHCjEKBAQAAg4SA34CPRokIE9wdGlvbmFsLiBUaGUgdGl0
bGUgb2YgdGhlIHNjaGVtYS4KCgwKBQQAAg4FEgN+AggKDAoFBAACDgESA34JDgoMCgUEAAIO
AxIDfhETCgwKBQQAAg4IEgN+FDwKDwoIBAACDgicCAASA34VOwpICgQEAAIPEgSBAQJAGjog
T3B0aW9uYWwuIE1pbmltdW0gbnVtYmVyIG9mIHRoZSBlbGVtZW50cyBmb3IgVHlwZS5BUlJB
WS4KCg0KBQQAAg8FEgSBAQIHCg0KBQQAAg8BEgSBAQgRCg0KBQQAAg8DEgSBARQWCg0KBQQA
Ag8IEgSBARc/ChAKCAQAAg8InAgAEgSBARg+CkgKBAQAAhASBIQBAkAaOiBPcHRpb25hbC4g
TWF4aW11bSBudW1iZXIgb2YgdGhlIGVsZW1lbnRzIGZvciBUeXBlLkFSUkFZLgoKDQoFBAAC
EAUSBIQBAgcKDQoFBAACEAESBIQBCBEKDQoFBAACEAMSBIQBFBYKDQoFBAACEAgSBIQBFz8K
EAoIBAACEAicCAASBIQBGD4KSQoEBAACERIEhwECSBo7IE9wdGlvbmFsLiBNaW5pbXVtIHZh
bHVlIGZvciBUeXBlLklOVEVHRVIgYW5kIFR5cGUuTlVNQkVSLgoKDQoFBAACEQQSBIcBAgoK
DQoFBAACEQUSBIcBCxEKDQoFBAACEQESBIcBEhkKDQoFBAACEQMSBIcBHB4KDQoFBAACEQgS
BIcBH0cKEAoIBAACEQicCAASBIcBIEYKSQoEBAACEhIEigECSBo7IE9wdGlvbmFsLiBNYXhp
bXVtIHZhbHVlIGZvciBUeXBlLklOVEVHRVIgYW5kIFR5cGUuTlVNQkVSLgoKDQoFBAACEgQS
BIoBAgoKDQoFBAACEgUSBIoBCxEKDQoFBAACEgESBIoBEhkKDQoFBAACEgMSBIoBHB4KDQoF
BAACEggSBIoBH0cKEAoIBAACEgicCAASBIoBIEZiBnByb3RvMw==
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Ces::V1::Schema::Schema ===
    # Fields for Schema
    # Field: type Type: 14 (.google.cloud.ces.v1.Schema.Type)
    # Field: properties Type: 11 (.google.cloud.ces.v1.Schema.PropertiesEntry)
    # Field: required Type: 9 ()
    # Field: description Type: 9 ()
    # Field: items Type: 11 (.google.cloud.ces.v1.Schema)
    # Field: nullable Type: 8 ()
    # Field: unique_items Type: 8 ()
    # Field: prefix_items Type: 11 (.google.cloud.ces.v1.Schema)
    # Field: additional_properties Type: 11 (.google.cloud.ces.v1.Schema)
    # Field: any_of Type: 11 (.google.cloud.ces.v1.Schema)
    # Field: enum Type: 9 ()
    # Field: default Type: 11 (.google.protobuf.Value)
    # Field: ref Type: 9 ()
    # Field: defs Type: 11 (.google.cloud.ces.v1.Schema.DefsEntry)
    # Field: title Type: 9 ()
    # Field: min_items Type: 3 ()
    # Field: max_items Type: 3 ()
    # Field: minimum Type: 1 ()
    # Field: maximum Type: 1 ()

# Enum: Schema::Type
our $Schema_TYPE_UNSPECIFIED = 0;
our $Schema_STRING = 1;
our $Schema_INTEGER = 2;
our $Schema_NUMBER = 3;
our $Schema_BOOLEAN = 4;
our $Schema_OBJECT = 5;
our $Schema_ARRAY = 6;

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Ces::V1::Schema - Compiled Protocol Buffers messages for google/cloud/ces/v1/schema.proto

=head1 SYNOPSIS

    use Google::Cloud::Ces::V1::Schema;

    my $msg = Google::Cloud::Ces::V1::Schema::Schema->new({
        type => $type,
        properties => $properties,
        required => $required,
        description => $description,
    });

    # Read or update a field
    my $val = $msg->type();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Ces::V1::Schema::Schema->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/ces/v1/schema.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Ces::V1::Schema::Schema

Represents a select subset of an OpenAPI 3.0 schema object.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->type() >> / C<< $msg->type($value) >>

Type: C<Enum> (L<Google::Cloud::Ces::V1::Schema::Type>)

Required. The type of the data.

=item * C<< $msg->properties() >> / C<< $msg->properties($value) >>

Type: C<Message> (L<Google::Cloud::Ces::V1::Schema::Schema::PropertiesEntry>)

Optional. Properties of Type.OBJECT.

=item * C<< $msg->required() >> / C<< $msg->required($value) >>

Type: C<String>

Optional. Required properties of Type.OBJECT.

=item * C<< $msg->description() >> / C<< $msg->description($value) >>

Type: C<String>

Optional. The description of the data.

=item * C<< $msg->items() >> / C<< $msg->items($value) >>

Type: C<Message> (L<Google::Cloud::Ces::V1::Schema::Schema>)

Optional. Schema of the elements of Type.ARRAY.

=item * C<< $msg->nullable() >> / C<< $msg->nullable($value) >>

Type: C<Bool>

Optional. Indicates if the value may be null.

=item * C<< $msg->unique_items() >> / C<< $msg->unique_items($value) >>

Type: C<Bool>

Optional. Indicate the items in the array must be unique. Only applies to
TYPE.ARRAY.

=item * C<< $msg->prefix_items() >> / C<< $msg->prefix_items($value) >>

Type: C<Message> (L<Google::Cloud::Ces::V1::Schema::Schema>)

Optional. Schemas of initial elements of Type.ARRAY.

=item * C<< $msg->additional_properties() >> / C<< $msg->additional_properties($value) >>

Type: C<Message> (L<Google::Cloud::Ces::V1::Schema::Schema>)

Optional. Can either be a boolean or an object, controls the presence of
additional properties.

=item * C<< $msg->any_of() >> / C<< $msg->any_of($value) >>

Type: C<Message> (L<Google::Cloud::Ces::V1::Schema::Schema>)

Optional. The value should be validated against any (one or more) of the
subschemas in the list.

=item * C<< $msg->enum() >> / C<< $msg->enum($value) >>

Type: C<String>

Optional. Possible values of the element of primitive type with enum
format. Examples:
1. We can define direction as :
{type:STRING, format:enum, enum:["EAST", NORTH", "SOUTH", "WEST"]}
2. We can define apartment number as :
{type:INTEGER, format:enum, enum:["101", "201", "301"]}

=item * C<< $msg->default() >> / C<< $msg->default($value) >>

Type: C<Message> (L<Google::Protobuf::Struct::Value>)

Optional. Default value of the data.

=item * C<< $msg->ref() >> / C<< $msg->ref($value) >>

Type: C<String>

Optional. Allows indirect references between schema nodes. The value should
be a valid reference to a child of the root `defs`.

For example, the following schema defines a reference to a schema node
named "Pet":

```
type: object
properties:
  pet:
    ref: #/defs/Pet
defs:
  Pet:
    type: object
    properties:
      name:
        type: string
```

The value of the "pet" property is a reference to the schema node
named "Pet".
See details in
https://json-schema.org/understanding-json-schema/structuring.

=item * C<< $msg->defs() >> / C<< $msg->defs($value) >>

Type: C<Message> (L<Google::Cloud::Ces::V1::Schema::Schema::DefsEntry>)

Optional. A map of definitions for use by `ref`. Only allowed at the root
of the schema.

=item * C<< $msg->title() >> / C<< $msg->title($value) >>

Type: C<String>

Optional. The title of the schema.

=item * C<< $msg->min_items() >> / C<< $msg->min_items($value) >>

Type: C<Int64>

Optional. Minimum number of the elements for Type.ARRAY.

=item * C<< $msg->max_items() >> / C<< $msg->max_items($value) >>

Type: C<Int64>

Optional. Maximum number of the elements for Type.ARRAY.

=item * C<< $msg->minimum() >> / C<< $msg->minimum($value) >>

Type: C<Double>

Optional. Minimum value for Type.INTEGER and Type.NUMBER.

=item * C<< $msg->maximum() >> / C<< $msg->maximum($value) >>

Type: C<Double>

Optional. Maximum value for Type.INTEGER and Type.NUMBER.

=back

=head3 Enum: Schema::Type

=over 4

=item * C<TYPE_UNSPECIFIED> => C<0>

=item * C<STRING> => C<1>

=item * C<INTEGER> => C<2>

=item * C<NUMBER> => C<3>

=item * C<BOOLEAN> => C<4>

=item * C<OBJECT> => C<5>

=item * C<ARRAY> => C<6>

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Ces::V1::Schema::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
