package Google::Cloud::Channel::V1::Common;

use strict;
use warnings;

our $VERSION = '0.14';

use Protobuf::Message;
use Protobuf::DescriptorPool;
use Protobuf::Internal qw(:all);
use MIME::Base64;

BEGIN {
    eval { require Google::Api::FieldBehavior };
    eval { require Google::Protobuf::Any };
    my $descriptor_b64 = <<'EOF';
CiRnb29nbGUvY2xvdWQvY2hhbm5lbC92MS9jb21tb24ucHJvdG8SF2dvb2dsZS5jbG91ZC5j
aGFubmVsLnYxGh9nb29nbGUvYXBpL2ZpZWxkX2JlaGF2aW9yLnByb3RvGhlnb29nbGUvcHJv
dG9idWYvYW55LnByb3RvItcDCgdFZHVEYXRhElUKDmluc3RpdHV0ZV90eXBlGAEgASgOMi4u
Z29vZ2xlLmNsb3VkLmNoYW5uZWwudjEuRWR1RGF0YS5JbnN0aXR1dGVUeXBlUg1pbnN0aXR1
dGVUeXBlElUKDmluc3RpdHV0ZV9zaXplGAIgASgOMi4uZ29vZ2xlLmNsb3VkLmNoYW5uZWwu
djEuRWR1RGF0YS5JbnN0aXR1dGVTaXplUg1pbnN0aXR1dGVTaXplEhgKB3dlYnNpdGUYAyAB
KAlSB3dlYnNpdGUiSAoNSW5zdGl0dXRlVHlwZRIeChpJTlNUSVRVVEVfVFlQRV9VTlNQRUNJ
RklFRBAAEgcKA0sxMhABEg4KClVOSVZFUlNJVFkQAiK5AQoNSW5zdGl0dXRlU2l6ZRIeChpJ
TlNUSVRVVEVfU0laRV9VTlNQRUNJRklFRBAAEg4KClNJWkVfMV8xMDAQARIQCgxTSVpFXzEw
MV81MDAQAhIRCg1TSVpFXzUwMV8xMDAwEAMSEgoOU0laRV8xMDAxXzIwMDAQBBISCg5TSVpF
XzIwMDFfNTAwMBAFEhMKD1NJWkVfNTAwMV8xMDAwMBAGEhYKElNJWkVfMTAwMDFfT1JfTU9S
RRAHIvQDChFDbG91ZElkZW50aXR5SW5mbxJcCg1jdXN0b21lcl90eXBlGAEgASgOMjcuZ29v
Z2xlLmNsb3VkLmNoYW5uZWwudjEuQ2xvdWRJZGVudGl0eUluZm8uQ3VzdG9tZXJUeXBlUgxj
dXN0b21lclR5cGUSKgoOcHJpbWFyeV9kb21haW4YCSABKAlCA+BBA1INcHJpbWFyeURvbWFp
bhIxChJpc19kb21haW5fdmVyaWZpZWQYBCABKAhCA+BBA1IQaXNEb21haW5WZXJpZmllZBIn
Cg9hbHRlcm5hdGVfZW1haWwYBiABKAlSDmFsdGVybmF0ZUVtYWlsEiEKDHBob25lX251bWJl
chgHIAEoCVILcGhvbmVOdW1iZXISIwoNbGFuZ3VhZ2VfY29kZRgIIAEoCVIMbGFuZ3VhZ2VD
b2RlEi8KEWFkbWluX2NvbnNvbGVfdXJpGAogASgJQgPgQQNSD2FkbWluQ29uc29sZVVyaRI7
CghlZHVfZGF0YRgWIAEoCzIgLmdvb2dsZS5jbG91ZC5jaGFubmVsLnYxLkVkdURhdGFSB2Vk
dURhdGEiQwoMQ3VzdG9tZXJUeXBlEh0KGUNVU1RPTUVSX1RZUEVfVU5TUEVDSUZJRUQQABIK
CgZET01BSU4QARIICgRURUFNEAIi1gEKBVZhbHVlEiEKC2ludDY0X3ZhbHVlGAEgASgDSABS
CmludDY0VmFsdWUSIwoMc3RyaW5nX3ZhbHVlGAIgASgJSABSC3N0cmluZ1ZhbHVlEiMKDGRv
dWJsZV92YWx1ZRgDIAEoAUgAUgtkb3VibGVWYWx1ZRI3Cgtwcm90b192YWx1ZRgEIAEoCzIU
Lmdvb2dsZS5wcm90b2J1Zi5BbnlIAFIKcHJvdG9WYWx1ZRIfCgpib29sX3ZhbHVlGAUgASgI
SABSCWJvb2xWYWx1ZUIGCgRraW5kImEKCUFkbWluVXNlchIUCgVlbWFpbBgBIAEoCVIFZW1h
aWwSHQoKZ2l2ZW5fbmFtZRgCIAEoCVIJZ2l2ZW5OYW1lEh8KC2ZhbWlseV9uYW1lGAMgASgJ
UgpmYW1pbHlOYW1lQmMKG2NvbS5nb29nbGUuY2xvdWQuY2hhbm5lbC52MUILQ29tbW9uUHJv
dG9QAVo1Y2xvdWQuZ29vZ2xlLmNvbS9nby9jaGFubmVsL2FwaXYxL2NoYW5uZWxwYjtjaGFu
bmVscGJK7yIKBxIFDgCXAQEKvAQKAQwSAw4AEjKxBCBDb3B5cmlnaHQgMjAyNSBHb29nbGUg
TExDCgogTGljZW5zZWQgdW5kZXIgdGhlIEFwYWNoZSBMaWNlbnNlLCBWZXJzaW9uIDIuMCAo
dGhlICJMaWNlbnNlIik7CiB5b3UgbWF5IG5vdCB1c2UgdGhpcyBmaWxlIGV4Y2VwdCBpbiBj
b21wbGlhbmNlIHdpdGggdGhlIExpY2Vuc2UuCiBZb3UgbWF5IG9idGFpbiBhIGNvcHkgb2Yg
dGhlIExpY2Vuc2UgYXQKCiAgICAgaHR0cDovL3d3dy5hcGFjaGUub3JnL2xpY2Vuc2VzL0xJ
Q0VOU0UtMi4wCgogVW5sZXNzIHJlcXVpcmVkIGJ5IGFwcGxpY2FibGUgbGF3IG9yIGFncmVl
ZCB0byBpbiB3cml0aW5nLCBzb2Z0d2FyZQogZGlzdHJpYnV0ZWQgdW5kZXIgdGhlIExpY2Vu
c2UgaXMgZGlzdHJpYnV0ZWQgb24gYW4gIkFTIElTIiBCQVNJUywKIFdJVEhPVVQgV0FSUkFO
VElFUyBPUiBDT05ESVRJT05TIE9GIEFOWSBLSU5ELCBlaXRoZXIgZXhwcmVzcyBvciBpbXBs
aWVkLgogU2VlIHRoZSBMaWNlbnNlIGZvciB0aGUgc3BlY2lmaWMgbGFuZ3VhZ2UgZ292ZXJu
aW5nIHBlcm1pc3Npb25zIGFuZAogbGltaXRhdGlvbnMgdW5kZXIgdGhlIExpY2Vuc2UuCgoI
CgECEgMQACAKCQoCAwASAxIAKQoJCgIDARIDEwAjCggKAQgSAxUATAoJCgIICxIDFQBMCggK
AQgSAxYAIgoJCgIIChIDFgAiCggKAQgSAxcALAoJCgIICBIDFwAsCggKAQgSAxgANAoJCgII
ARIDGAA0CiUKAgQAEgQbAEsBGhkgUmVxdWlyZWQgRWR1IEF0dHJpYnV0ZXMKCgoKAwQAARID
GwgPCjMKBAQABAASBB0CJgMaJSBFbnVtIHRvIHNwZWNpZnkgdGhlIGluc3RpdHV0ZSB0eXBl
LgoKDAoFBAAEAAESAx0HFAoaCgYEAAQAAgASAx8EIxoLIE5vdCB1c2VkLgoKDgoHBAAEAAIA
ARIDHwQeCg4KBwQABAACAAISAx8hIgo5CgYEAAQAAgESAyIEDBoqIEVsZW1lbnRhcnkvU2Vj
b25kYXJ5IFNjaG9vbHMgJiBEaXN0cmljdHMKCg4KBwQABAACAQESAyIEBwoOCgcEAAQAAgEC
EgMiCgsKOQoGBAAEAAICEgMlBBMaKiBIaWdoZXIgRWR1Y2F0aW9uIFVuaXZlcnNpdGllcyAm
IENvbGxlZ2VzCgoOCgcEAAQAAgIBEgMlBA4KDgoHBAAEAAICAhIDJRESCj8KBAQABAESBCkC
QQMaMSBOdW1iZXIgb2Ygc3R1ZGVudHMgYW5kIHN0YWZmIHRoZSBpbnN0aXR1dGUgaGFzLgoK
DAoFBAAEAQESAykHFAoaCgYEAAQBAgASAysEIxoLIE5vdCB1c2VkLgoKDgoHBAAEAQIAARID
KwQeCg4KBwQABAECAAISAyshIgoYCgYEAAQBAgESAy4EExoJIDEgLSAxMDAKCg4KBwQABAEC
AQESAy4EDgoOCgcEAAQBAgECEgMuERIKGgoGBAAEAQICEgMxBBUaCyAxMDEgLSA1MDAKCg4K
BwQABAECAgESAzEEEAoOCgcEAAQBAgICEgMxExQKHAoGBAAEAQIDEgM0BBYaDSA1MDEgLSAx
LDAwMAoKDgoHBAAEAQIDARIDNAQRCg4KBwQABAECAwISAzQUFQoeCgYEAAQBAgQSAzcEFxoP
IDEsMDAxIC0gMiwwMDAKCg4KBwQABAECBAESAzcEEgoOCgcEAAQBAgQCEgM3FRYKHgoGBAAE
AQIFEgM6BBcaDyAyLDAwMSAtIDUsMDAwCgoOCgcEAAQBAgUBEgM6BBIKDgoHBAAEAQIFAhID
OhUWCh8KBgQABAECBhIDPQQYGhAgNSwwMDEgLSAxMCwwMDAKCg4KBwQABAECBgESAz0EEwoO
CgcEAAQBAgYCEgM9FhcKGQoGBAAEAQIHEgNABBsaCiAxMCwwMDEgKwoKDgoHBAAEAQIHARID
QAQWCg4KBwQABAECBwISA0AZGgo1CgQEAAIAEgNEAiMaKCBEZXNpZ25hdGVkIGluc3RpdHV0
ZSB0eXBlIG9mIGN1c3RvbWVyLgoKDAoFBAACAAYSA0QCDwoMCgUEAAIAARIDRBAeCgwKBQQA
AgADEgNEISIKJQoEBAACARIDRwIjGhggU2l6ZSBvZiB0aGUgaW5zdGl0dXRlLgoKDAoFBAAC
AQYSA0cCDwoMCgUEAAIBARIDRxAeCgwKBQQAAgEDEgNHISIKPgoEBAACAhIDSgIVGjEgV2Vi
IGFkZHJlc3MgZm9yIHRoZSBlZHUgY3VzdG9tZXIncyBpbnN0aXR1dGlvbi4KCgwKBQQAAgIF
EgNKAggKDAoFBAACAgESA0oJEAoMCgUEAAICAxIDShMUCkgKAgQBEgROAHYBGjwgQ2xvdWQg
SWRlbnRpdHkgaW5mb3JtYXRpb24gZm9yIHRoZSBDbG91ZCBDaGFubmVsIEN1c3RvbWVyLgoK
CgoDBAEBEgNOCBkKLAoEBAEEABIEUAJZAxoeIEN1c3RvbWVyVHlwZSBvZiB0aGUgY3VzdG9t
ZXIKCgwKBQQBBAABEgNQBxMKGgoGBAEEAAIAEgNSBCIaCyBOb3QgdXNlZC4KCg4KBwQBBAAC
AAESA1IEHQoOCgcEAQQAAgACEgNSICEKWAoGBAEEAAIBEgNVBA8aSSBEb21haW4tb3duaW5n
IGN1c3RvbWVyIHdoaWNoIG5lZWRzIGRvbWFpbiB2ZXJpZmljYXRpb24gdG8gdXNlIHNlcnZp
Y2VzLgoKDgoHBAEEAAIBARIDVQQKCg4KBwQBBAACAQISA1UNDgpOCgYEAQQAAgISA1gEDRo/
IFRlYW0gY3VzdG9tZXIgd2hpY2ggbmVlZHMgZW1haWwgdmVyaWZpY2F0aW9uIHRvIHVzZSBz
ZXJ2aWNlcy4KCg4KBwQBBAACAgESA1gECAoOCgcEAQQAAgICEgNYCwwKUgoEBAECABIDXAIh
GkUgQ3VzdG9tZXJUeXBlIGluZGljYXRlcyB2ZXJpZmljYXRpb24gdHlwZSBuZWVkZWQgZm9y
IHVzaW5nIHNlcnZpY2VzLgoKDAoFBAECAAYSA1wCDgoMCgUEAQIAARIDXA8cCgwKBQQBAgAD
EgNcHyAKNAoEBAECARIDXwJIGicgT3V0cHV0IG9ubHkuIFRoZSBwcmltYXJ5IGRvbWFpbiBu
YW1lLgoKDAoFBAECAQUSA18CCAoMCgUEAQIBARIDXwkXCgwKBQQBAgEDEgNfGhsKDAoFBAEC
AQgSA18cRwoPCggEAQIBCJwIABIDXx1GCtcCCgQEAQICEgNmAkoayQIgT3V0cHV0IG9ubHku
IFdoZXRoZXIgdGhlIGRvbWFpbiBpcyB2ZXJpZmllZC4KIFRoaXMgZmllbGQgaXMgbm90IHJl
dHVybmVkIGZvciBhIEN1c3RvbWVyJ3MgY2xvdWRfaWRlbnRpdHlfaW5mbyByZXNvdXJjZS4K
IFBhcnRuZXJzIGNhbiB1c2UgdGhlIGRvbWFpbnMuZ2V0KCkgbWV0aG9kIG9mIHRoZSBXb3Jr
c3BhY2UgU0RLJ3MKIERpcmVjdG9yeSBBUEksIG9yIGxpc3RlbiB0byB0aGUgUFJJTUFSWV9E
T01BSU5fVkVSSUZJRUQgUHViL1N1YiBldmVudCBpbgogdG8gdHJhY2sgZG9tYWluIHZlcmlm
aWNhdGlvbiBvZiB0aGVpciByZXNvbHZlIFdvcmtzcGFjZSBjdXN0b21lcnMuCgoMCgUEAQIC
BRIDZgIGCgwKBQQBAgIBEgNmBxkKDAoFBAECAgMSA2YcHQoMCgUEAQICCBIDZh5JCg8KCAQB
AgIInAgAEgNmH0gKIwoEBAECAxIDaQIdGhYgVGhlIGFsdGVybmF0ZSBlbWFpbC4KCgwKBQQB
AgMFEgNpAggKDAoFBAECAwESA2kJGAoMCgUEAQIDAxIDaRscCj8KBAQBAgQSA2wCGhoyIFBo
b25lIG51bWJlciBhc3NvY2lhdGVkIHdpdGggdGhlIENsb3VkIElkZW50aXR5LgoKDAoFBAEC
BAUSA2wCCAoMCgUEAQIEARIDbAkVCgwKBQQBAgQDEgNsGBkKHQoEBAECBRIDbwIbGhAgTGFu
Z3VhZ2UgY29kZS4KCgwKBQQBAgUFEgNvAggKDAoFBAECBQESA28JFgoMCgUEAQIFAxIDbxka
CkYKBAQBAgYSA3ICTBo5IE91dHB1dCBvbmx5LiBVUkkgb2YgQ3VzdG9tZXIncyBBZG1pbiBj
b25zb2xlIGRhc2hib2FyZC4KCgwKBQQBAgYFEgNyAggKDAoFBAECBgESA3IJGgoMCgUEAQIG
AxIDch0fCgwKBQQBAgYIEgNyIEsKDwoIBAECBgicCAASA3IhSgoyCgQEAQIHEgN1AhgaJSBF
ZHUgaW5mb3JtYXRpb24gYWJvdXQgdGhlIGN1c3RvbWVyLgoKDAoFBAECBwYSA3UCCQoMCgUE
AQIHARIDdQoSCgwKBQQBAgcDEgN1FRcKMgoCBAISBXkAiwEBGiUgRGF0YSB0eXBlIGFuZCB2
YWx1ZSBvZiBhIHBhcmFtZXRlci4KCgoKAwQCARIDeQgNCiMKBAQCCAASBXsCigEDGhQgVGhl
IGtpbmQgb2YgdmFsdWUuCgoMCgUEAggAARIDewgMCikKBAQCAgASA30EGhocIFJlcHJlc2Vu
dHMgYW4gaW50NjQgdmFsdWUuCgoMCgUEAgIABRIDfQQJCgwKBQQCAgABEgN9ChUKDAoFBAIC
AAMSA30YGQoqCgQEAgIBEgSAAQQcGhwgUmVwcmVzZW50cyBhIHN0cmluZyB2YWx1ZS4KCg0K
BQQCAgEFEgSAAQQKCg0KBQQCAgEBEgSAAQsXCg0KBQQCAgEDEgSAARobCioKBAQCAgISBIMB
BBwaHCBSZXByZXNlbnRzIGEgZG91YmxlIHZhbHVlLgoKDQoFBAICAgUSBIMBBAoKDQoFBAIC
AgESBIMBCxcKDQoFBAICAgMSBIMBGhsKMAoEBAICAxIEhgEEKBoiIFJlcHJlc2VudHMgYW4g
J0FueScgcHJvdG8gdmFsdWUuCgoNCgUEAgIDBhIEhgEEFwoNCgUEAgIDARIEhgEYIwoNCgUE
AgIDAxIEhgEmJworCgQEAgIEEgSJAQQYGh0gUmVwcmVzZW50cyBhIGJvb2xlYW4gdmFsdWUu
CgoNCgUEAgIEBRIEiQEECAoNCgUEAgIEARIEiQEJEwoNCgUEAgIEAxIEiQEWFwpQCgIEAxIG
jgEAlwEBGkIgSW5mb3JtYXRpb24gbmVlZGVkIHRvIGNyZWF0ZSBhbiBBZG1pbiBVc2VyIGZv
ciBHb29nbGUgV29ya3NwYWNlLgoKCwoDBAMBEgSOAQgRCjAKBAQDAgASBJABAhMaIiBQcmlt
YXJ5IGVtYWlsIG9mIHRoZSBhZG1pbiB1c2VyLgoKDQoFBAMCAAUSBJABAggKDQoFBAMCAAES
BJABCQ4KDQoFBAMCAAMSBJABERIKLQoEBAMCARIEkwECGBofIEdpdmVuIG5hbWUgb2YgdGhl
IGFkbWluIHVzZXIuCgoNCgUEAwIBBRIEkwECCAoNCgUEAwIBARIEkwEJEwoNCgUEAwIBAxIE
kwEWFwouCgQEAwICEgSWAQIZGiAgRmFtaWx5IG5hbWUgb2YgdGhlIGFkbWluIHVzZXIuCgoN
CgUEAwICBRIElgECCAoNCgUEAwICARIElgEJFAoNCgUEAwICAxIElgEXGGIGcHJvdG8z
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Channel::V1::Common::EduData ===
    # Fields for EduData
    # Field: institute_type Type: 14 (.google.cloud.channel.v1.EduData.InstituteType)
    # Field: institute_size Type: 14 (.google.cloud.channel.v1.EduData.InstituteSize)
    # Field: website Type: 9 ()

# Enum: EduData::InstituteType
our $EduData_INSTITUTE_TYPE_UNSPECIFIED = 0;
our $EduData_K12 = 1;
our $EduData_UNIVERSITY = 2;

# Enum: EduData::InstituteSize
our $EduData_INSTITUTE_SIZE_UNSPECIFIED = 0;
our $EduData_SIZE_1_100 = 1;
our $EduData_SIZE_101_500 = 2;
our $EduData_SIZE_501_1000 = 3;
our $EduData_SIZE_1001_2000 = 4;
our $EduData_SIZE_2001_5000 = 5;
our $EduData_SIZE_5001_10000 = 6;
our $EduData_SIZE_10001_OR_MORE = 7;

# === Message: Google::Cloud::Channel::V1::Common::CloudIdentityInfo ===
    # Fields for CloudIdentityInfo
    # Field: customer_type Type: 14 (.google.cloud.channel.v1.CloudIdentityInfo.CustomerType)
    # Field: primary_domain Type: 9 ()
    # Field: is_domain_verified Type: 8 ()
    # Field: alternate_email Type: 9 ()
    # Field: phone_number Type: 9 ()
    # Field: language_code Type: 9 ()
    # Field: admin_console_uri Type: 9 ()
    # Field: edu_data Type: 11 (.google.cloud.channel.v1.EduData)

# Enum: CloudIdentityInfo::CustomerType
our $CloudIdentityInfo_CUSTOMER_TYPE_UNSPECIFIED = 0;
our $CloudIdentityInfo_DOMAIN = 1;
our $CloudIdentityInfo_TEAM = 2;

# === Message: Google::Cloud::Channel::V1::Common::Value ===
    # Fields for Value
    # Field: int64_value Type: 3 ()
    # Field: string_value Type: 9 ()
    # Field: double_value Type: 1 ()
    # Field: proto_value Type: 11 (.google.protobuf.Any)
    # Field: bool_value Type: 8 ()

# === Message: Google::Cloud::Channel::V1::Common::AdminUser ===
    # Fields for AdminUser
    # Field: email Type: 9 ()
    # Field: given_name Type: 9 ()
    # Field: family_name Type: 9 ()

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Channel::V1::Common - Compiled Protocol Buffers messages for google/cloud/channel/v1/common.proto

=head1 SYNOPSIS

    use Google::Cloud::Channel::V1::Common;

    my $msg = Google::Cloud::Channel::V1::Common::EduData->new({
        institute_type => $institute_type,
        institute_size => $institute_size,
        website => $website,
    });

    # Read or update a field
    my $val = $msg->institute_type();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Channel::V1::Common::EduData->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/channel/v1/common.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Channel::V1::Common::EduData

Required Edu Attributes

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->institute_type() >> / C<< $msg->institute_type($value) >>

Type: C<Enum> (L<Google::Cloud::Channel::V1::EduData::InstituteType>)

Designated institute type of customer.

=item * C<< $msg->institute_size() >> / C<< $msg->institute_size($value) >>

Type: C<Enum> (L<Google::Cloud::Channel::V1::EduData::InstituteSize>)

Size of the institute.

=item * C<< $msg->website() >> / C<< $msg->website($value) >>

Type: C<String>

Web address for the edu customer's institution.

=back

=head3 Enum: EduData::InstituteType

=over 4

=item * C<INSTITUTE_TYPE_UNSPECIFIED> => C<0>

=item * C<K12> => C<1>

=item * C<UNIVERSITY> => C<2>

=back

=head3 Enum: EduData::InstituteSize

=over 4

=item * C<INSTITUTE_SIZE_UNSPECIFIED> => C<0>

=item * C<SIZE_1_100> => C<1>

=item * C<SIZE_101_500> => C<2>

=item * C<SIZE_501_1000> => C<3>

=item * C<SIZE_1001_2000> => C<4>

=item * C<SIZE_2001_5000> => C<5>

=item * C<SIZE_5001_10000> => C<6>

=item * C<SIZE_10001_OR_MORE> => C<7>

=back

=head2 Google::Cloud::Channel::V1::Common::CloudIdentityInfo

Cloud Identity information for the Cloud Channel Customer.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->customer_type() >> / C<< $msg->customer_type($value) >>

Type: C<Enum> (L<Google::Cloud::Channel::V1::CloudIdentityInfo::CustomerType>)

CustomerType indicates verification type needed for using services.

=item * C<< $msg->primary_domain() >> / C<< $msg->primary_domain($value) >>

Type: C<String>

Output only. The primary domain name.

=item * C<< $msg->is_domain_verified() >> / C<< $msg->is_domain_verified($value) >>

Type: C<Bool>

Output only. Whether the domain is verified.
This field is not returned for a Customer's cloud_identity_info resource.
Partners can use the domains.get() method of the Workspace SDK's
Directory API, or listen to the PRIMARY_DOMAIN_VERIFIED Pub/Sub event in
to track domain verification of their resolve Workspace customers.

=item * C<< $msg->alternate_email() >> / C<< $msg->alternate_email($value) >>

Type: C<String>

The alternate email.

=item * C<< $msg->phone_number() >> / C<< $msg->phone_number($value) >>

Type: C<String>

Phone number associated with the Cloud Identity.

=item * C<< $msg->language_code() >> / C<< $msg->language_code($value) >>

Type: C<String>

Language code.

=item * C<< $msg->admin_console_uri() >> / C<< $msg->admin_console_uri($value) >>

Type: C<String>

Output only. URI of Customer's Admin console dashboard.

=item * C<< $msg->edu_data() >> / C<< $msg->edu_data($value) >>

Type: C<Message> (L<Google::Cloud::Channel::V1::Common::EduData>)

Edu information about the customer.

=back

=head3 Enum: CloudIdentityInfo::CustomerType

=over 4

=item * C<CUSTOMER_TYPE_UNSPECIFIED> => C<0>

=item * C<DOMAIN> => C<1>

=item * C<TEAM> => C<2>

=back

=head2 Google::Cloud::Channel::V1::Common::Value

Data type and value of a parameter.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->int64_value() >> / C<< $msg->int64_value($value) >>

Type: C<Int64>

Represents an int64 value.

=item * C<< $msg->string_value() >> / C<< $msg->string_value($value) >>

Type: C<String>

Represents a string value.

=item * C<< $msg->double_value() >> / C<< $msg->double_value($value) >>

Type: C<Double>

Represents a double value.

=item * C<< $msg->proto_value() >> / C<< $msg->proto_value($value) >>

Type: C<Message> (L<Google::Protobuf::Any::Any>)

Represents an 'Any' proto value.

=item * C<< $msg->bool_value() >> / C<< $msg->bool_value($value) >>

Type: C<Bool>

Represents a boolean value.

=back

=head2 Google::Cloud::Channel::V1::Common::AdminUser

Information needed to create an Admin User for Google Workspace.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->email() >> / C<< $msg->email($value) >>

Type: C<String>

Primary email of the admin user.

=item * C<< $msg->given_name() >> / C<< $msg->given_name($value) >>

Type: C<String>

Given name of the admin user.

=item * C<< $msg->family_name() >> / C<< $msg->family_name($value) >>

Type: C<String>

Family name of the admin user.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Channel::V1::Common::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
