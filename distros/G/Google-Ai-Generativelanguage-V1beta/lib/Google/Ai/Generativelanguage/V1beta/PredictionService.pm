package Google::Ai::Generativelanguage::V1beta::PredictionService;

use strict;
use warnings;

our $VERSION = '0.12';

use Protobuf::Message;
use Protobuf::DescriptorPool;
use Protobuf::Internal qw(:all);
use MIME::Base64;

BEGIN {
    eval { require Google::Api::Annotations };
    eval { require Google::Api::Client };
    eval { require Google::Api::FieldBehavior };
    eval { require Google::Api::Resource };
    eval { require Google::Longrunning::Operations };
    eval { require Google::Protobuf::Struct };
    my $descriptor_b64 = <<'EOF';
Cjxnb29nbGUvYWkvZ2VuZXJhdGl2ZWxhbmd1YWdlL3YxYmV0YS9wcmVkaWN0aW9uX3NlcnZp
Y2UucHJvdG8SI2dvb2dsZS5haS5nZW5lcmF0aXZlbGFuZ3VhZ2UudjFiZXRhGhxnb29nbGUv
YXBpL2Fubm90YXRpb25zLnByb3RvGhdnb29nbGUvYXBpL2NsaWVudC5wcm90bxofZ29vZ2xl
L2FwaS9maWVsZF9iZWhhdmlvci5wcm90bxoZZ29vZ2xlL2FwaS9yZXNvdXJjZS5wcm90bxoj
Z29vZ2xlL2xvbmdydW5uaW5nL29wZXJhdGlvbnMucHJvdG8aHGdvb2dsZS9wcm90b2J1Zi9z
dHJ1Y3QucHJvdG8izwEKDlByZWRpY3RSZXF1ZXN0EkUKBW1vZGVsGAEgASgJQi/gQQL6QSkK
J2dlbmVyYXRpdmVsYW5ndWFnZS5nb29nbGVhcGlzLmNvbS9Nb2RlbFIFbW9kZWwSOQoJaW5z
dGFuY2VzGAIgAygLMhYuZ29vZ2xlLnByb3RvYnVmLlZhbHVlQgPgQQJSCWluc3RhbmNlcxI7
CgpwYXJhbWV0ZXJzGAMgASgLMhYuZ29vZ2xlLnByb3RvYnVmLlZhbHVlQgPgQQFSCnBhcmFt
ZXRlcnMi2gEKGVByZWRpY3RMb25nUnVubmluZ1JlcXVlc3QSRQoFbW9kZWwYASABKAlCL+BB
AvpBKQonZ2VuZXJhdGl2ZWxhbmd1YWdlLmdvb2dsZWFwaXMuY29tL01vZGVsUgVtb2RlbBI5
CglpbnN0YW5jZXMYAiADKAsyFi5nb29nbGUucHJvdG9idWYuVmFsdWVCA+BBAlIJaW5zdGFu
Y2VzEjsKCnBhcmFtZXRlcnMYAyABKAsyFi5nb29nbGUucHJvdG9idWYuVmFsdWVCA+BBAVIK
cGFyYW1ldGVycyJLCg9QcmVkaWN0UmVzcG9uc2USOAoLcHJlZGljdGlvbnMYASADKAsyFi5n
b29nbGUucHJvdG9idWYuVmFsdWVSC3ByZWRpY3Rpb25zIrIBChpQcmVkaWN0TG9uZ1J1bm5p
bmdSZXNwb25zZRKHAQoXZ2VuZXJhdGVfdmlkZW9fcmVzcG9uc2UYASABKAsyTS5nb29nbGUu
YWkuZ2VuZXJhdGl2ZWxhbmd1YWdlLnYxYmV0YS5QcmVkaWN0TG9uZ1J1bm5pbmdHZW5lcmF0
ZWRWaWRlb1Jlc3BvbnNlSABSFWdlbmVyYXRlVmlkZW9SZXNwb25zZUIKCghyZXNwb25zZSIc
ChpQcmVkaWN0TG9uZ1J1bm5pbmdNZXRhZGF0YSJTCgVNZWRpYRJCCgV2aWRlbxgBIAEoCzIq
Lmdvb2dsZS5haS5nZW5lcmF0aXZlbGFuZ3VhZ2UudjFiZXRhLlZpZGVvSABSBXZpZGVvQgYK
BHR5cGUiPgoFVmlkZW8SFgoFdmlkZW8YASABKAxIAFIFdmlkZW8SEgoDdXJpGAIgASgJSABS
A3VyaUIJCgdjb250ZW50IvkBCihQcmVkaWN0TG9uZ1J1bm5pbmdHZW5lcmF0ZWRWaWRlb1Jl
c3BvbnNlElcKEWdlbmVyYXRlZF9zYW1wbGVzGAEgAygLMiouZ29vZ2xlLmFpLmdlbmVyYXRp
dmVsYW5ndWFnZS52MWJldGEuTWVkaWFSEGdlbmVyYXRlZFNhbXBsZXMSNwoYcmFpX21lZGlh
X2ZpbHRlcmVkX2NvdW50GAIgASgFUhVyYWlNZWRpYUZpbHRlcmVkQ291bnQSOwoacmFpX21l
ZGlhX2ZpbHRlcmVkX3JlYXNvbnMYAyADKAlSF3JhaU1lZGlhRmlsdGVyZWRSZWFzb25zMusD
ChFQcmVkaWN0aW9uU2VydmljZRKzAQoHUHJlZGljdBIzLmdvb2dsZS5haS5nZW5lcmF0aXZl
bGFuZ3VhZ2UudjFiZXRhLlByZWRpY3RSZXF1ZXN0GjQuZ29vZ2xlLmFpLmdlbmVyYXRpdmVs
YW5ndWFnZS52MWJldGEuUHJlZGljdFJlc3BvbnNlIj2C0+STAiUiIC92MWJldGEve21vZGVs
PW1vZGVscy8qfTpwcmVkaWN0OgEq2kEPbW9kZWwsaW5zdGFuY2VzEvkBChJQcmVkaWN0TG9u
Z1J1bm5pbmcSPi5nb29nbGUuYWkuZ2VuZXJhdGl2ZWxhbmd1YWdlLnYxYmV0YS5QcmVkaWN0
TG9uZ1J1bm5pbmdSZXF1ZXN0Gh0uZ29vZ2xlLmxvbmdydW5uaW5nLk9wZXJhdGlvbiKDAYLT
5JMCMCIrL3YxYmV0YS97bW9kZWw9bW9kZWxzLyp9OnByZWRpY3RMb25nUnVubmluZzoBKtpB
D21vZGVsLGluc3RhbmNlc8pBOAoaUHJlZGljdExvbmdSdW5uaW5nUmVzcG9uc2USGlByZWRp
Y3RMb25nUnVubmluZ01ldGFkYXRhGiTKQSFnZW5lcmF0aXZlbGFuZ3VhZ2UuZ29vZ2xlYXBp
cy5jb21CogEKJ2NvbS5nb29nbGUuYWkuZ2VuZXJhdGl2ZWxhbmd1YWdlLnYxYmV0YUIWUHJl
ZGljdGlvblNlcnZpY2VQcm90b1ABWl1jbG91ZC5nb29nbGUuY29tL2dvL2FpL2dlbmVyYXRp
dmVsYW5ndWFnZS9hcGl2MWJldGEvZ2VuZXJhdGl2ZWxhbmd1YWdlcGI7Z2VuZXJhdGl2ZWxh
bmd1YWdlcGJKlB4KBxIFDgCSAQEKvAQKAQwSAw4AEjKxBCBDb3B5cmlnaHQgMjAyNSBHb29n
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
CgoICgECEgMQACwKCQoCAwASAxIAJgoJCgIDARIDEwAhCgkKAgMCEgMUACkKCQoCAwMSAxUA
IwoJCgIDBBIDFgAtCgkKAgMFEgMXACYKCAoBCBIDGQB0CgkKAggLEgMZAHQKCAoBCBIDGgAi
CgkKAggKEgMaACIKCAoBCBIDGwA3CgkKAggIEgMbADcKCAoBCBIDHABACgkKAggBEgMcAEAK
QAoCBgASBB8AOAEaNCBBIHNlcnZpY2UgZm9yIG9ubGluZSBwcmVkaWN0aW9ucyBhbmQgZXhw
bGFuYXRpb25zLgoKCgoDBgABEgMfCBkKCgoDBgADEgMgAkkKDAoFBgADmQgSAyACSQouCgQG
AAIAEgQjAikDGiAgUGVyZm9ybXMgYSBwcmVkaWN0aW9uIHJlcXVlc3QuCgoMCgUGAAIAARID
IwYNCgwKBQYAAgACEgMjDhwKDAoFBgACAAMSAyMnNgoNCgUGAAIABBIEJAQnBgoRCgkGAAIA
BLDKvCISBCQEJwYKDAoFBgACAAQSAygEPQoPCggGAAIABJsIABIDKAQ9CjMKBAYAAgESBCwC
NwMaJSBTYW1lIGFzIFByZWRpY3QgYnV0IHJldHVybnMgYW4gTFJPLgoKDAoFBgACAQESAywG
GAoMCgUGAAIBAhIDLBkyCgwKBQYAAgEDEgMtDysKDQoFBgACAQQSBC4EMQYKEQoJBgACAQSw
yrwiEgQuBDEGCgwKBQYAAgEEEgMyBD0KDwoIBgACAQSbCAASAzIEPQoNCgUGAAIBBBIEMwQ2
BgoPCgcGAAIBBJkIEgQzBDYGCn4KAgQAEgQ8AEwBGnIgUmVxdWVzdCBtZXNzYWdlIGZvcgog
W1ByZWRpY3Rpb25TZXJ2aWNlLlByZWRpY3RdW2dvb2dsZS5haS5nZW5lcmF0aXZlbGFuZ3Vh
Z2UudjFiZXRhLlByZWRpY3Rpb25TZXJ2aWNlLlByZWRpY3RdLgoKCgoDBAABEgM8CBYKXwoE
BAACABIEPwJEBBpRIFJlcXVpcmVkLiBUaGUgbmFtZSBvZiB0aGUgbW9kZWwgZm9yIHByZWRp
Y3Rpb24uCiBGb3JtYXQ6IGBuYW1lPW1vZGVscy97bW9kZWx9YC4KCgwKBQQAAgAFEgM/AggK
DAoFBAACAAESAz8JDgoMCgUEAAIAAxIDPxESCg0KBQQAAgAIEgQ/E0QDCg8KCAQAAgAInAgA
EgNABCoKDwoHBAACAAifCBIEQQRDBQpSCgQEAAIBEgRHAkgvGkQgUmVxdWlyZWQuIFRoZSBp
bnN0YW5jZXMgdGhhdCBhcmUgdGhlIGlucHV0IHRvIHRoZSBwcmVkaWN0aW9uIGNhbGwuCgoM
CgUEAAIBBBIDRwIKCgwKBQQAAgEGEgNHCyAKDAoFBAACAQESA0chKgoMCgUEAAIBAxIDRy0u
CgwKBQQAAgEIEgNIBi4KDwoIBAACAQicCAASA0gHLQpICgQEAAICEgNLAlAaOyBPcHRpb25h
bC4gVGhlIHBhcmFtZXRlcnMgdGhhdCBnb3Zlcm4gdGhlIHByZWRpY3Rpb24gY2FsbC4KCgwK
BQQAAgIGEgNLAhcKDAoFBAACAgESA0sYIgoMCgUEAAICAxIDSyUmCgwKBQQAAgIIEgNLJ08K
DwoIBAACAgicCAASA0soTgpJCgIEARIETwBfARo9IFJlcXVlc3QgbWVzc2FnZSBmb3IgW1By
ZWRpY3Rpb25TZXJ2aWNlLlByZWRpY3RMb25nUnVubmluZ10uCgoKCgMEAQESA08IIQpfCgQE
AQIAEgRSAlcEGlEgUmVxdWlyZWQuIFRoZSBuYW1lIG9mIHRoZSBtb2RlbCBmb3IgcHJlZGlj
dGlvbi4KIEZvcm1hdDogYG5hbWU9bW9kZWxzL3ttb2RlbH1gLgoKDAoFBAECAAUSA1ICCAoM
CgUEAQIAARIDUgkOCgwKBQQBAgADEgNSERIKDQoFBAECAAgSBFITVwMKDwoIBAECAAicCAAS
A1MEKgoPCgcEAQIACJ8IEgRUBFYFClIKBAQBAgESBFoCWy8aRCBSZXF1aXJlZC4gVGhlIGlu
c3RhbmNlcyB0aGF0IGFyZSB0aGUgaW5wdXQgdG8gdGhlIHByZWRpY3Rpb24gY2FsbC4KCgwK
BQQBAgEEEgNaAgoKDAoFBAECAQYSA1oLIAoMCgUEAQIBARIDWiEqCgwKBQQBAgEDEgNaLS4K
DAoFBAECAQgSA1sGLgoPCggEAQIBCJwIABIDWwctCkgKBAQBAgISA14CUBo7IE9wdGlvbmFs
LiBUaGUgcGFyYW1ldGVycyB0aGF0IGdvdmVybiB0aGUgcHJlZGljdGlvbiBjYWxsLgoKDAoF
BAECAgYSA14CFwoMCgUEAQICARIDXhgiCgwKBQQBAgIDEgNeJSYKDAoFBAECAggSA14nTwoP
CggEAQICCJwIABIDXihOCj8KAgQCEgRiAGUBGjMgUmVzcG9uc2UgbWVzc2FnZSBmb3IgW1By
ZWRpY3Rpb25TZXJ2aWNlLlByZWRpY3RdLgoKCgoDBAIBEgNiCBcKMgoEBAICABIDZAIxGiUg
VGhlIG91dHB1dHMgb2YgdGhlIHByZWRpY3Rpb24gY2FsbC4KCgwKBQQCAgAEEgNkAgoKDAoF
BAICAAYSA2QLIAoMCgUEAgIAARIDZCEsCgwKBQQCAgADEgNkLzAKSQoCBAMSBGgAbgEaPSBS
ZXNwb25zZSBtZXNzYWdlIGZvciBbUHJlZGljdGlvblNlcnZpY2UuUHJlZGljdExvbmdSdW5u
aW5nXQoKCgoDBAMBEgNoCCIKOwoEBAMIABIEagJtAxotIFRoZSByZXNwb25zZSBvZiB0aGUg
bG9uZyBydW5uaW5nIG9wZXJhdGlvbi4KCgwKBQQDCAABEgNqCBAKPwoEBAMCABIDbARJGjIg
VGhlIHJlc3BvbnNlIG9mIHRoZSB2aWRlbyBnZW5lcmF0aW9uIHByZWRpY3Rpb24uCgoMCgUE
AwIABhIDbAQsCgwKBQQDAgABEgNsLUQKDAoFBAMCAAMSA2xHSApFCgIEBBIDcQAlGjogTWV0
YWRhdGEgZm9yIFByZWRpY3RMb25nUnVubmluZyBsb25nIHJ1bm5pbmcgb3BlcmF0aW9ucy4K
CgoKAwQEARIDcQgiCjgKAgQFEgR0AHoBGiwgQSBwcm90byBlbmNhcHN1bGF0ZSB2YXJpb3Vz
IHR5cGUgb2YgbWVkaWEuCgoKCgMEBQESA3QIDQoeCgQEBQgAEgR2AnkDGhAgVHlwZSBvZiBt
ZWRpYS4KCgwKBQQFCAABEgN2CAwKTgoEBAUCABIDeAQUGkEgVmlkZW8gYXMgdGhlIG9ubHkg
b25lIGZvciBub3cuICBUaGlzIGlzIG1pbWlja2luZyBWZXJ0ZXggcHJvdG8uCgoMCgUEBQIA
BhIDeAQJCgwKBQQFAgABEgN4Cg8KDAoFBAUCAAMSA3gSEwopCgIEBhIFfQCGAQEaHCBSZXBy
ZXNlbnRhdGlvbiBvZiBhIHZpZGVvLgoKCgoDBAYBEgN9CA0KLAoEBAYIABIFfwKFAQMaHSBX
aGVyZSB0aGUgdmlkZW8gY29udGVudCBpcy4KCgwKBQQGCAABEgN/CA8KGgoEBAYCABIEgQEE
FBoMIFJhdyBieXRlcy4KCg0KBQQGAgAFEgSBAQQJCg0KBQQGAgABEgSBAQoPCg0KBQQGAgAD
EgSBARITCigKBAQGAgESBIQBBBMaGiBQYXRoIHRvIGFub3RoZXIgc3RvcmFnZS4KCg0KBQQG
AgEFEgSEAQQKCg0KBQQGAgEBEgSEAQsOCg0KBQQGAgEDEgSEARESCh0KAgQHEgaJAQCSAQEa
DyBWZW8gcmVzcG9uc2UuCgoLCgMEBwESBIkBCDAKJgoEBAcCABIEiwECJxoYIFRoZSBnZW5l
cmF0ZWQgc2FtcGxlcy4KCg0KBQQHAgAEEgSLAQIKCg0KBQQHAgAGEgSLAQsQCg0KBQQHAgAB
EgSLAREiCg0KBQQHAgADEgSLASUmCkgKBAQHAgESBI4BAiUaOiBSZXR1cm5zIGlmIGFueSB2
aWRlb3Mgd2VyZSBmaWx0ZXJlZCBkdWUgdG8gUkFJIHBvbGljaWVzLgoKDQoFBAcCAQUSBI4B
AgcKDQoFBAcCAQESBI4BCCAKDQoFBAcCAQMSBI4BIyQKMwoEBAcCAhIEkQECMRolIFJldHVy
bnMgcmFpIGZhaWx1cmUgcmVhc29ucyBpZiBhbnkuCgoNCgUEBwICBBIEkQECCgoNCgUEBwIC
BRIEkQELEQoNCgUEBwICARIEkQESLAoNCgUEBwICAxIEkQEvMGIGcHJvdG8z
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Ai::Generativelanguage::V1beta::PredictionService::PredictRequest ===
    # Fields for PredictRequest
    # Field: model Type: 9 ()
    # Field: instances Type: 11 (.google.protobuf.Value)
    # Field: parameters Type: 11 (.google.protobuf.Value)

=pod

=head1 NAME

Google::Ai::Generativelanguage::V1beta::PredictionService::PredictRequest - Compiled Protocol Buffers message class

=head1 SYNOPSIS

    use Google::Ai::Generativelanguage::V1beta::PredictionService;

    my $msg = Google::Ai::Generativelanguage::V1beta::PredictionService::PredictRequest->new(
        model => $value,
    );

=head1 FIELDS

=over 4

=item * B<model>

Type: String

=item * B<instances>

Type: Message (.google.protobuf.Value)

=item * B<parameters>

Type: Message (.google.protobuf.Value)

=back

=cut

# === Message: Google::Ai::Generativelanguage::V1beta::PredictionService::PredictLongRunningRequest ===
    # Fields for PredictLongRunningRequest
    # Field: model Type: 9 ()
    # Field: instances Type: 11 (.google.protobuf.Value)
    # Field: parameters Type: 11 (.google.protobuf.Value)

=pod

=head1 NAME

Google::Ai::Generativelanguage::V1beta::PredictionService::PredictLongRunningRequest - Compiled Protocol Buffers message class

=head1 SYNOPSIS

    use Google::Ai::Generativelanguage::V1beta::PredictionService;

    my $msg = Google::Ai::Generativelanguage::V1beta::PredictionService::PredictLongRunningRequest->new(
        model => $value,
    );

=head1 FIELDS

=over 4

=item * B<model>

Type: String

=item * B<instances>

Type: Message (.google.protobuf.Value)

=item * B<parameters>

Type: Message (.google.protobuf.Value)

=back

=cut

# === Message: Google::Ai::Generativelanguage::V1beta::PredictionService::PredictResponse ===
    # Fields for PredictResponse
    # Field: predictions Type: 11 (.google.protobuf.Value)

=pod

=head1 NAME

Google::Ai::Generativelanguage::V1beta::PredictionService::PredictResponse - Compiled Protocol Buffers message class

=head1 SYNOPSIS

    use Google::Ai::Generativelanguage::V1beta::PredictionService;

    my $msg = Google::Ai::Generativelanguage::V1beta::PredictionService::PredictResponse->new(
        predictions => $value,
    );

=head1 FIELDS

=over 4

=item * B<predictions>

Type: Message (.google.protobuf.Value)

=back

=cut

# === Message: Google::Ai::Generativelanguage::V1beta::PredictionService::PredictLongRunningResponse ===
    # Fields for PredictLongRunningResponse
    # Field: generate_video_response Type: 11 (.google.ai.generativelanguage.v1beta.PredictLongRunningGeneratedVideoResponse)

=pod

=head1 NAME

Google::Ai::Generativelanguage::V1beta::PredictionService::PredictLongRunningResponse - Compiled Protocol Buffers message class

=head1 SYNOPSIS

    use Google::Ai::Generativelanguage::V1beta::PredictionService;

    my $msg = Google::Ai::Generativelanguage::V1beta::PredictionService::PredictLongRunningResponse->new(
        generate_video_response => $value,
    );

=head1 FIELDS

=over 4

=item * B<generate_video_response>

Type: Message (.google.ai.generativelanguage.v1beta.PredictLongRunningGeneratedVideoResponse)

=back

=cut

# === Message: Google::Ai::Generativelanguage::V1beta::PredictionService::PredictLongRunningMetadata ===
    # Fields for PredictLongRunningMetadata

=pod

=head1 NAME

Google::Ai::Generativelanguage::V1beta::PredictionService::PredictLongRunningMetadata - Compiled Protocol Buffers message class

=head1 SYNOPSIS

    use Google::Ai::Generativelanguage::V1beta::PredictionService;

    my $msg = Google::Ai::Generativelanguage::V1beta::PredictionService::PredictLongRunningMetadata->new(
    );

=head1 FIELDS

=over 4

=back

=cut

# === Message: Google::Ai::Generativelanguage::V1beta::PredictionService::Media ===
    # Fields for Media
    # Field: video Type: 11 (.google.ai.generativelanguage.v1beta.Video)

=pod

=head1 NAME

Google::Ai::Generativelanguage::V1beta::PredictionService::Media - Compiled Protocol Buffers message class

=head1 SYNOPSIS

    use Google::Ai::Generativelanguage::V1beta::PredictionService;

    my $msg = Google::Ai::Generativelanguage::V1beta::PredictionService::Media->new(
        video => $value,
    );

=head1 FIELDS

=over 4

=item * B<video>

Type: Message (.google.ai.generativelanguage.v1beta.Video)

=back

=cut

# === Message: Google::Ai::Generativelanguage::V1beta::PredictionService::Video ===
    # Fields for Video
    # Field: video Type: 12 ()
    # Field: uri Type: 9 ()

=pod

=head1 NAME

Google::Ai::Generativelanguage::V1beta::PredictionService::Video - Compiled Protocol Buffers message class

=head1 SYNOPSIS

    use Google::Ai::Generativelanguage::V1beta::PredictionService;

    my $msg = Google::Ai::Generativelanguage::V1beta::PredictionService::Video->new(
        video => $value,
    );

=head1 FIELDS

=over 4

=item * B<video>

Type: Bytes

=item * B<uri>

Type: String

=back

=cut

# === Message: Google::Ai::Generativelanguage::V1beta::PredictionService::PredictLongRunningGeneratedVideoResponse ===
    # Fields for PredictLongRunningGeneratedVideoResponse
    # Field: generated_samples Type: 11 (.google.ai.generativelanguage.v1beta.Media)
    # Field: rai_media_filtered_count Type: 5 ()
    # Field: rai_media_filtered_reasons Type: 9 ()

=pod

=head1 NAME

Google::Ai::Generativelanguage::V1beta::PredictionService::PredictLongRunningGeneratedVideoResponse - Compiled Protocol Buffers message class

=head1 SYNOPSIS

    use Google::Ai::Generativelanguage::V1beta::PredictionService;

    my $msg = Google::Ai::Generativelanguage::V1beta::PredictionService::PredictLongRunningGeneratedVideoResponse->new(
        generated_samples => $value,
    );

=head1 FIELDS

=over 4

=item * B<generated_samples>

Type: Message (.google.ai.generativelanguage.v1beta.Media)

=item * B<rai_media_filtered_count>

Type: Int32

=item * B<rai_media_filtered_reasons>

Type: String

=back

=cut

# === Service Client: Google::Ai::Generativelanguage::V1beta::PredictionService::PredictionServiceClient ===
package Google::Ai::Generativelanguage::V1beta::PredictionService::PredictionServiceClient;

=pod

=head1 NAME

Google::Ai::Generativelanguage::V1beta::PredictionService::PredictionServiceClient - Client stub representing the remote PredictionService service

=head1 DESCRIPTION

This class acts as a local client stub for the remote gRPC service.
It delegates call dispatching to an underlying L<Google::gRPC::Client>
instance, ensuring type-safe request parsing and response mapping.

=head1 CONFIGURATION AND ENVIRONMENT

=head2 target

The endpoint target address. Defaults to C<ai.googleapis.com:443>.

=head2 credentials

The authentication credentials provider. Defaults to application default credentials via L<Google::Auth>.

=cut

use Moo;
use Google::Auth;
use Google::gRPC::Client;

has credentials => ( is => 'ro', default => sub { Google::Auth->default() } );
has target      => ( is => 'ro', default => 'ai.googleapis.com:443' );

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

sub predict {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Ai::Generativelanguage::V1beta::PredictionService::PredictRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.ai.generativelanguage.v1beta.PredictionService',
        method         => 'Predict',
        request        => $req,
        response_class => 'Google::Ai::Generativelanguage::V1beta::PredictionService::PredictResponse',
    });
}

sub predict_long_running {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Ai::Generativelanguage::V1beta::PredictionService::PredictLongRunningRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.ai.generativelanguage.v1beta.PredictionService',
        method         => 'PredictLongRunning',
        request        => $req,
        response_class => 'Google::Longrunning::Operations::Operation',
    });
}

1;

__END__

=head1 NAME

Google::Ai::Generativelanguage::V1beta::PredictionService - Protocol Buffers schema definition

=head1 DESCRIPTION

Auto-generated Protocol Buffers schema definition class.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
