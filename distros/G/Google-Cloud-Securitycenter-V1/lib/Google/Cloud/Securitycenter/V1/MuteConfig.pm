package Google::Cloud::Securitycenter::V1::MuteConfig;

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
    my $descriptor_b64 = <<'EOF';
CjBnb29nbGUvY2xvdWQvc2VjdXJpdHljZW50ZXIvdjEvbXV0ZV9jb25maWcucHJvdG8SHmdv
b2dsZS5jbG91ZC5zZWN1cml0eWNlbnRlci52MRofZ29vZ2xlL2FwaS9maWVsZF9iZWhhdmlv
ci5wcm90bxoZZ29vZ2xlL2FwaS9yZXNvdXJjZS5wcm90bxofZ29vZ2xlL3Byb3RvYnVmL3Rp
bWVzdGFtcC5wcm90byLNBwoKTXV0ZUNvbmZpZxISCgRuYW1lGAEgASgJUgRuYW1lEiUKDGRp
c3BsYXlfbmFtZRgCIAEoCUICGAFSC2Rpc3BsYXlOYW1lEiAKC2Rlc2NyaXB0aW9uGAMgASgJ
UgtkZXNjcmlwdGlvbhIbCgZmaWx0ZXIYBCABKAlCA+BBAlIGZmlsdGVyEkAKC2NyZWF0ZV90
aW1lGAUgASgLMhouZ29vZ2xlLnByb3RvYnVmLlRpbWVzdGFtcEID4EEDUgpjcmVhdGVUaW1l
EkAKC3VwZGF0ZV90aW1lGAYgASgLMhouZ29vZ2xlLnByb3RvYnVmLlRpbWVzdGFtcEID4EED
Ugp1cGRhdGVUaW1lEjEKEm1vc3RfcmVjZW50X2VkaXRvchgHIAEoCUID4EEDUhBtb3N0UmVj
ZW50RWRpdG9yElIKBHR5cGUYCCABKA4yOS5nb29nbGUuY2xvdWQuc2VjdXJpdHljZW50ZXIu
djEuTXV0ZUNvbmZpZy5NdXRlQ29uZmlnVHlwZUID4EEBUgR0eXBlEkAKC2V4cGlyeV90aW1l
GAkgASgLMhouZ29vZ2xlLnByb3RvYnVmLlRpbWVzdGFtcEID4EEBUgpleHBpcnlUaW1lIksK
Dk11dGVDb25maWdUeXBlEiAKHE1VVEVfQ09ORklHX1RZUEVfVU5TUEVDSUZJRUQQABIKCgZT
VEFUSUMQARILCgdEWU5BTUlDEAI6qgPqQaYDCihzZWN1cml0eWNlbnRlci5nb29nbGVhcGlz
LmNvbS9NdXRlQ29uZmlnEjZvcmdhbml6YXRpb25zL3tvcmdhbml6YXRpb259L211dGVDb25m
aWdzL3ttdXRlX2NvbmZpZ30SKmZvbGRlcnMve2ZvbGRlcn0vbXV0ZUNvbmZpZ3Mve211dGVf
Y29uZmlnfRIscHJvamVjdHMve3Byb2plY3R9L211dGVDb25maWdzL3ttdXRlX2NvbmZpZ30S
S29yZ2FuaXphdGlvbnMve29yZ2FuaXphdGlvbn0vbG9jYXRpb25zL3tsb2NhdGlvbn0vbXV0
ZUNvbmZpZ3Mve211dGVfY29uZmlnfRI/Zm9sZGVycy97Zm9sZGVyfS9sb2NhdGlvbnMve2xv
Y2F0aW9ufS9tdXRlQ29uZmlncy97bXV0ZV9jb25maWd9EkFwcm9qZWN0cy97cHJvamVjdH0v
bG9jYXRpb25zL3tsb2NhdGlvbn0vbXV0ZUNvbmZpZ3Mve211dGVfY29uZmlnfSoLbXV0ZUNv
bmZpZ3MyCm11dGVDb25maWdC6QEKImNvbS5nb29nbGUuY2xvdWQuc2VjdXJpdHljZW50ZXIu
djFCD011dGVDb25maWdQcm90b1ABWkpjbG91ZC5nb29nbGUuY29tL2dvL3NlY3VyaXR5Y2Vu
dGVyL2FwaXYxL3NlY3VyaXR5Y2VudGVycGI7c2VjdXJpdHljZW50ZXJwYqoCHkdvb2dsZS5D
bG91ZC5TZWN1cml0eUNlbnRlci5WMcoCHkdvb2dsZVxDbG91ZFxTZWN1cml0eUNlbnRlclxW
MeoCIUdvb2dsZTo6Q2xvdWQ6OlNlY3VyaXR5Q2VudGVyOjpWMUrLJAoHEgUOAIEBAQq8BAoB
DBIDDgASMrEEIENvcHlyaWdodCAyMDI1IEdvb2dsZSBMTEMKCiBMaWNlbnNlZCB1bmRlciB0
aGUgQXBhY2hlIExpY2Vuc2UsIFZlcnNpb24gMi4wICh0aGUgIkxpY2Vuc2UiKTsKIHlvdSBt
YXkgbm90IHVzZSB0aGlzIGZpbGUgZXhjZXB0IGluIGNvbXBsaWFuY2Ugd2l0aCB0aGUgTGlj
ZW5zZS4KIFlvdSBtYXkgb2J0YWluIGEgY29weSBvZiB0aGUgTGljZW5zZSBhdAoKICAgICBo
dHRwOi8vd3d3LmFwYWNoZS5vcmcvbGljZW5zZXMvTElDRU5TRS0yLjAKCiBVbmxlc3MgcmVx
dWlyZWQgYnkgYXBwbGljYWJsZSBsYXcgb3IgYWdyZWVkIHRvIGluIHdyaXRpbmcsIHNvZnR3
YXJlCiBkaXN0cmlidXRlZCB1bmRlciB0aGUgTGljZW5zZSBpcyBkaXN0cmlidXRlZCBvbiBh
biAiQVMgSVMiIEJBU0lTLAogV0lUSE9VVCBXQVJSQU5USUVTIE9SIENPTkRJVElPTlMgT0Yg
QU5ZIEtJTkQsIGVpdGhlciBleHByZXNzIG9yIGltcGxpZWQuCiBTZWUgdGhlIExpY2Vuc2Ug
Zm9yIHRoZSBzcGVjaWZpYyBsYW5ndWFnZSBnb3Zlcm5pbmcgcGVybWlzc2lvbnMgYW5kCiBs
aW1pdGF0aW9ucyB1bmRlciB0aGUgTGljZW5zZS4KCggKAQISAxAAJwoJCgIDABIDEgApCgkK
AgMBEgMTACMKCQoCAwISAxQAKQoICgEIEgMWADsKCQoCCCUSAxYAOwoICgEIEgMXAGEKCQoC
CAsSAxcAYQoICgEIEgMYACIKCQoCCAoSAxgAIgoICgEIEgMZADAKCQoCCAgSAxkAMAoICgEI
EgMaADsKCQoCCAESAxoAOwoICgEIEgMbADsKCQoCCCkSAxsAOwoICgEIEgMcADoKCQoCCC0S
AxwAOgp/CgIEABIFIACBAQEaciBBIG11dGUgY29uZmlnIGlzIGEgQ2xvdWQgU0NDIHJlc291
cmNlIHRoYXQgY29udGFpbnMgdGhlIGNvbmZpZ3VyYXRpb24KIHRvIG11dGUgY3JlYXRlL3Vw
ZGF0ZSBldmVudHMgb2YgZmluZGluZ3MuCgoKCgMEAAESAyAIEgoLCgMEAAcSBCECKwQKDQoF
BAAHnQgSBCECKwQKJwoEBAAEABIELgI+AxoZIFRoZSB0eXBlIG9mIE11dGVDb25maWcuCgoM
CgUEAAQAARIDLgcVChgKBgQABAACABIDMAQlGgkgVW51c2VkLgoKDgoHBAAEAAIAARIDMAQg
Cg4KBwQABAACAAISAzAjJArUAQoGBAAEAAIBEgM1BA8axAEgQSBzdGF0aWMgbXV0ZSBjb25m
aWcsIHdoaWNoIHNldHMgdGhlIHN0YXRpYyBtdXRlIHN0YXRlIG9mIGZ1dHVyZSBtYXRjaGlu
ZwogZmluZGluZ3MgdG8gbXV0ZWQuIE9uY2UgdGhlIHN0YXRpYyBtdXRlIHN0YXRlIGhhcyBi
ZWVuIHNldCwgZmluZGluZyBvcgogY29uZmlnIG1vZGlmaWNhdGlvbnMgd2lsbCBub3QgYWZm
ZWN0IHRoZSBzdGF0ZS4KCg4KBwQABAACAQESAzUECgoOCgcEAAQAAgECEgM1DQ4KlwMKBgQA
BAACAhIDPQQQGocDIEEgZHluYW1pYyBtdXRlIGNvbmZpZywgd2hpY2ggaXMgYXBwbGllZCB0
byBleGlzdGluZyBhbmQgZnV0dXJlIG1hdGNoaW5nCiBmaW5kaW5ncywgc2V0dGluZyB0aGVp
ciBkeW5hbWljIG11dGUgc3RhdGUgdG8gIm11dGVkIi4gSWYgdGhlIGNvbmZpZyBpcwogdXBk
YXRlZCBvciBkZWxldGVkLCBvciBhIG1hdGNoaW5nIGZpbmRpbmcgaXMgdXBkYXRlZCwgc3Vj
aCB0aGF0IHRoZQogZmluZGluZyBkb2Vzbid0IG1hdGNoIHRoZSBjb25maWcsIHRoZSBjb25m
aWcgd2lsbCBiZSByZW1vdmVkIGZyb20gdGhlCiBmaW5kaW5nLCBhbmQgdGhlIGZpbmRpbmcn
cyBkeW5hbWljIG11dGUgc3RhdGUgbWF5IGJlY29tZSAidW5tdXRlZCIKICh1bmxlc3Mgb3Ro
ZXIgY29uZmlncyBzdGlsbCBtYXRjaCkuCgoOCgcEAAQAAgIBEgM9BAsKDgoHBAAEAAICAhID
PQ4PCrQDCgQEAAIAEgNHAhIapgMgVGhpcyBmaWVsZCB3aWxsIGJlIGlnbm9yZWQgaWYgcHJv
dmlkZWQgb24gY29uZmlnIGNyZWF0aW9uLiBGb3JtYXQKIGBvcmdhbml6YXRpb25zL3tvcmdh
bml6YXRpb259L211dGVDb25maWdzL3ttdXRlX2NvbmZpZ31gCiBgZm9sZGVycy97Zm9sZGVy
fS9tdXRlQ29uZmlncy97bXV0ZV9jb25maWd9YAogYHByb2plY3RzL3twcm9qZWN0fS9tdXRl
Q29uZmlncy97bXV0ZV9jb25maWd9YAogYG9yZ2FuaXphdGlvbnMve29yZ2FuaXphdGlvbn0v
bG9jYXRpb25zL2dsb2JhbC9tdXRlQ29uZmlncy97bXV0ZV9jb25maWd9YAogYGZvbGRlcnMv
e2ZvbGRlcn0vbG9jYXRpb25zL2dsb2JhbC9tdXRlQ29uZmlncy97bXV0ZV9jb25maWd9YAog
YHByb2plY3RzL3twcm9qZWN0fS9sb2NhdGlvbnMvZ2xvYmFsL211dGVDb25maWdzL3ttdXRl
X2NvbmZpZ31gCgoMCgUEAAIABRIDRwIICgwKBQQAAgABEgNHCQ0KDAoFBAACAAMSA0cQEQpL
CgQEAAIBEgNKAi4aPiBUaGUgaHVtYW4gcmVhZGFibGUgbmFtZSB0byBiZSBkaXNwbGF5ZWQg
Zm9yIHRoZSBtdXRlIGNvbmZpZy4KCgwKBQQAAgEFEgNKAggKDAoFBAACAQESA0oJFQoMCgUE
AAIBAxIDShgZCgwKBQQAAgEIEgNKGi0KDQoGBAACAQgDEgNKGywKMAoEBAACAhIDTQIZGiMg
QSBkZXNjcmlwdGlvbiBvZiB0aGUgbXV0ZSBjb25maWcuCgoMCgUEAAICBRIDTQIICgwKBQQA
AgIBEgNNCRQKDAoFBAACAgMSA00XGAqbBgoEBAACAxIDYwI9Go0GIFJlcXVpcmVkLiBBbiBl
eHByZXNzaW9uIHRoYXQgZGVmaW5lcyB0aGUgZmlsdGVyIHRvIGFwcGx5IGFjcm9zcwogY3Jl
YXRlL3VwZGF0ZSBldmVudHMgb2YgZmluZGluZ3MuIFdoaWxlIGNyZWF0aW5nIGEgZmlsdGVy
IHN0cmluZywgYmUKIG1pbmRmdWwgb2YgdGhlIHNjb3BlIGluIHdoaWNoIHRoZSBtdXRlIGNv
bmZpZ3VyYXRpb24gaXMgYmVpbmcgY3JlYXRlZC4KIEUuZy4sIElmIGEgZmlsdGVyIGNvbnRh
aW5zIHByb2plY3QgPSBYIGJ1dCBpcyBjcmVhdGVkIHVuZGVyIHRoZSBwcm9qZWN0ID0gWQog
c2NvcGUsIGl0IG1pZ2h0IG5vdCBtYXRjaCBhbnkgZmluZGluZ3MuCgogVGhlIGZvbGxvd2lu
ZyBmaWVsZCBhbmQgb3BlcmF0b3IgY29tYmluYXRpb25zIGFyZSBzdXBwb3J0ZWQ6CgogKiBz
ZXZlcml0eTogYD1gLCBgOmAKICogY2F0ZWdvcnk6IGA9YCwgYDpgCiAqIHJlc291cmNlLm5h
bWU6IGA9YCwgYDpgCiAqIHJlc291cmNlLnByb2plY3RfbmFtZTogYD1gLCBgOmAKICogcmVz
b3VyY2UucHJvamVjdF9kaXNwbGF5X25hbWU6IGA9YCwgYDpgCiAqIHJlc291cmNlLmZvbGRl
cnMucmVzb3VyY2VfZm9sZGVyOiBgPWAsIGA6YAogKiByZXNvdXJjZS5wYXJlbnRfbmFtZTog
YD1gLCBgOmAKICogcmVzb3VyY2UucGFyZW50X2Rpc3BsYXlfbmFtZTogYD1gLCBgOmAKICog
cmVzb3VyY2UudHlwZTogYD1gLCBgOmAKICogZmluZGluZ19jbGFzczogYD1gLCBgOmAKICog
aW5kaWNhdG9yLmlwX2FkZHJlc3NlczogYD1gLCBgOmAKICogaW5kaWNhdG9yLmRvbWFpbnM6
IGA9YCwgYDpgCgoMCgUEAAIDBRIDYwIICgwKBQQAAgMBEgNjCQ8KDAoFBAACAwMSA2MSEwoM
CgUEAAIDCBIDYxQ8Cg8KCAQAAgMInAgAEgNjFTsKogEKBAQAAgQSBGgCaTIakwEgT3V0cHV0
IG9ubHkuIFRoZSB0aW1lIGF0IHdoaWNoIHRoZSBtdXRlIGNvbmZpZyB3YXMgY3JlYXRlZC4K
IFRoaXMgZmllbGQgaXMgc2V0IGJ5IHRoZSBzZXJ2ZXIgYW5kIHdpbGwgYmUgaWdub3JlZCBp
ZiBwcm92aWRlZCBvbiBjb25maWcKIGNyZWF0aW9uLgoKDAoFBAACBAYSA2gCGwoMCgUEAAIE
ARIDaBwnCgwKBQQAAgQDEgNoKisKDAoFBAACBAgSA2kGMQoPCggEAAIECJwIABIDaQcwCrgB
CgQEAAIFEgRuAm8yGqkBIE91dHB1dCBvbmx5LiBUaGUgbW9zdCByZWNlbnQgdGltZSBhdCB3
aGljaCB0aGUgbXV0ZSBjb25maWcgd2FzIHVwZGF0ZWQuCiBUaGlzIGZpZWxkIGlzIHNldCBi
eSB0aGUgc2VydmVyIGFuZCB3aWxsIGJlIGlnbm9yZWQgaWYgcHJvdmlkZWQgb24gY29uZmln
CiBjcmVhdGlvbiBvciB1cGRhdGUuCgoMCgUEAAIFBhIDbgIbCgwKBQQAAgUBEgNuHCcKDAoF
BAACBQMSA24qKwoMCgUEAAIFCBIDbwYxCg8KCAQAAgUInAgAEgNvBzAKtwEKBAQAAgYSA3QC
TBqpASBPdXRwdXQgb25seS4gRW1haWwgYWRkcmVzcyBvZiB0aGUgdXNlciB3aG8gbGFzdCBl
ZGl0ZWQgdGhlIG11dGUgY29uZmlnLgogVGhpcyBmaWVsZCBpcyBzZXQgYnkgdGhlIHNlcnZl
ciBhbmQgd2lsbCBiZSBpZ25vcmVkIGlmIHByb3ZpZGVkIG9uIGNvbmZpZwogY3JlYXRpb24g
b3IgdXBkYXRlLgoKDAoFBAACBgUSA3QCCAoMCgUEAAIGARIDdAkbCgwKBQQAAgYDEgN0Hh8K
DAoFBAACBggSA3QgSwoPCggEAAIGCJwIABIDdCFKCoICCgQEAAIHEgN6AkMa9AEgT3B0aW9u
YWwuIFRoZSB0eXBlIG9mIHRoZSBtdXRlIGNvbmZpZywgd2hpY2ggZGV0ZXJtaW5lcyB3aGF0
IHR5cGUgb2YgbXV0ZQogc3RhdGUgdGhlIGNvbmZpZyBhZmZlY3RzLiBUaGUgc3RhdGljIG11
dGUgc3RhdGUgdGFrZXMgcHJlY2VkZW5jZSBvdmVyIHRoZQogZHluYW1pYyBtdXRlIHN0YXRl
LiBJbW11dGFibGUgYWZ0ZXIgY3JlYXRpb24uIFNUQVRJQyBieSBkZWZhdWx0IGlmIG5vdCBz
ZXQKIGR1cmluZyBjcmVhdGlvbi4KCgwKBQQAAgcGEgN6AhAKDAoFBAACBwESA3oRFQoMCgUE
AAIHAxIDehgZCgwKBQQAAgcIEgN6GkIKDwoIBAACBwicCAASA3obQQqxAQoEBAACCBIFfwKA
AS8aoQEgT3B0aW9uYWwuIFRoZSBleHBpcnkgb2YgdGhlIG11dGUgY29uZmlnLiBPbmx5IGFw
cGxpY2FibGUgZm9yIGR5bmFtaWMKIGNvbmZpZ3MuIElmIHRoZSBleHBpcnkgaXMgc2V0LCB3
aGVuIHRoZSBjb25maWcgZXhwaXJlcywgaXQgaXMgcmVtb3ZlZCBmcm9tCiBhbGwgZmluZGlu
Z3MuCgoMCgUEAAIIBhIDfwIbCgwKBQQAAggBEgN/HCcKDAoFBAACCAMSA38qKwoNCgUEAAII
CBIEgAEGLgoQCggEAAIICJwIABIEgAEHLWIGcHJvdG8z
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Securitycenter::V1::MuteConfig::MuteConfig ===
    # Fields for MuteConfig
    # Field: name Type: 9 ()
    # Field: display_name Type: 9 ()
    # Field: description Type: 9 ()
    # Field: filter Type: 9 ()
    # Field: create_time Type: 11 (.google.protobuf.Timestamp)
    # Field: update_time Type: 11 (.google.protobuf.Timestamp)
    # Field: most_recent_editor Type: 9 ()
    # Field: type Type: 14 (.google.cloud.securitycenter.v1.MuteConfig.MuteConfigType)
    # Field: expiry_time Type: 11 (.google.protobuf.Timestamp)

# Enum: MuteConfig::MuteConfigType
our $MuteConfig_MUTE_CONFIG_TYPE_UNSPECIFIED = 0;
our $MuteConfig_STATIC = 1;
our $MuteConfig_DYNAMIC = 2;

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Securitycenter::V1::MuteConfig - Compiled Protocol Buffers messages for google/cloud/securitycenter/v1/mute_config.proto

=head1 SYNOPSIS

    use Google::Cloud::Securitycenter::V1::MuteConfig;

    my $msg = Google::Cloud::Securitycenter::V1::MuteConfig::MuteConfig->new({
        name => $name,
        display_name => $display_name,
        description => $description,
        filter => $filter,
    });

    # Read or update a field
    my $val = $msg->name();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Securitycenter::V1::MuteConfig::MuteConfig->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/securitycenter/v1/mute_config.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Securitycenter::V1::MuteConfig::MuteConfig

A mute config is a Cloud SCC resource that contains the configuration
to mute create/update events of findings.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

This field will be ignored if provided on config creation. Format
`organizations/{organization}/muteConfigs/{mute_config}`
`folders/{folder}/muteConfigs/{mute_config}`
`projects/{project}/muteConfigs/{mute_config}`
`organizations/{organization}/locations/global/muteConfigs/{mute_config}`
`folders/{folder}/locations/global/muteConfigs/{mute_config}`
`projects/{project}/locations/global/muteConfigs/{mute_config}`

=item * C<< $msg->display_name() >> / C<< $msg->display_name($value) >>

Type: C<String>

The human readable name to be displayed for the mute config.

=item * C<< $msg->description() >> / C<< $msg->description($value) >>

Type: C<String>

A description of the mute config.

=item * C<< $msg->filter() >> / C<< $msg->filter($value) >>

Type: C<String>

Required. An expression that defines the filter to apply across
create/update events of findings. While creating a filter string, be
mindful of the scope in which the mute configuration is being created.
E.g., If a filter contains project = X but is created under the project = Y
scope, it might not match any findings.

The following field and operator combinations are supported:

* severity: `=`, `:`
* category: `=`, `:`
* resource.name: `=`, `:`
* resource.project_name: `=`, `:`
* resource.project_display_name: `=`, `:`
* resource.folders.resource_folder: `=`, `:`
* resource.parent_name: `=`, `:`
* resource.parent_display_name: `=`, `:`
* resource.type: `=`, `:`
* finding_class: `=`, `:`
* indicator.ip_addresses: `=`, `:`
* indicator.domains: `=`, `:`

=item * C<< $msg->create_time() >> / C<< $msg->create_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Output only. The time at which the mute config was created.
This field is set by the server and will be ignored if provided on config
creation.

=item * C<< $msg->update_time() >> / C<< $msg->update_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Output only. The most recent time at which the mute config was updated.
This field is set by the server and will be ignored if provided on config
creation or update.

=item * C<< $msg->most_recent_editor() >> / C<< $msg->most_recent_editor($value) >>

Type: C<String>

Output only. Email address of the user who last edited the mute config.
This field is set by the server and will be ignored if provided on config
creation or update.

=item * C<< $msg->type() >> / C<< $msg->type($value) >>

Type: C<Enum> (L<Google::Cloud::Securitycenter::V1::MuteConfig::MuteConfigType>)

Optional. The type of the mute config, which determines what type of mute
state the config affects. The static mute state takes precedence over the
dynamic mute state. Immutable after creation. STATIC by default if not set
during creation.

=item * C<< $msg->expiry_time() >> / C<< $msg->expiry_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Optional. The expiry of the mute config. Only applicable for dynamic
configs. If the expiry is set, when the config expires, it is removed from
all findings.

=back

=head3 Enum: MuteConfig::MuteConfigType

=over 4

=item * C<MUTE_CONFIG_TYPE_UNSPECIFIED> => C<0>

=item * C<STATIC> => C<1>

=item * C<DYNAMIC> => C<2>

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Securitycenter::V1::MuteConfig::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
