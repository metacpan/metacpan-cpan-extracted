package Google::Cloud::Securitycenter::V1::ResourceValueConfig;

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
    eval { require Google::Cloud::Securitycenter::V1::Resource };
    eval { require Google::Protobuf::Timestamp };
    my $descriptor_b64 = <<'EOF';
Cjpnb29nbGUvY2xvdWQvc2VjdXJpdHljZW50ZXIvdjEvcmVzb3VyY2VfdmFsdWVfY29uZmln
LnByb3RvEh5nb29nbGUuY2xvdWQuc2VjdXJpdHljZW50ZXIudjEaH2dvb2dsZS9hcGkvZmll
bGRfYmVoYXZpb3IucHJvdG8aGWdvb2dsZS9hcGkvcmVzb3VyY2UucHJvdG8aLWdvb2dsZS9j
bG91ZC9zZWN1cml0eWNlbnRlci92MS9yZXNvdXJjZS5wcm90bxofZ29vZ2xlL3Byb3RvYnVm
L3RpbWVzdGFtcC5wcm90byL/CQoTUmVzb3VyY2VWYWx1ZUNvbmZpZxISCgRuYW1lGAEgASgJ
UgRuYW1lElkKDnJlc291cmNlX3ZhbHVlGAIgASgOMi0uZ29vZ2xlLmNsb3VkLnNlY3VyaXR5
Y2VudGVyLnYxLlJlc291cmNlVmFsdWVCA+BBAlINcmVzb3VyY2VWYWx1ZRIiCgp0YWdfdmFs
dWVzGAMgAygJQgPgQQJSCXRhZ1ZhbHVlcxIjCg1yZXNvdXJjZV90eXBlGAQgASgJUgxyZXNv
dXJjZVR5cGUSFAoFc2NvcGUYBSABKAlSBXNjb3BlEokBChhyZXNvdXJjZV9sYWJlbHNfc2Vs
ZWN0b3IYBiADKAsyTy5nb29nbGUuY2xvdWQuc2VjdXJpdHljZW50ZXIudjEuUmVzb3VyY2VW
YWx1ZUNvbmZpZy5SZXNvdXJjZUxhYmVsc1NlbGVjdG9yRW50cnlSFnJlc291cmNlTGFiZWxz
U2VsZWN0b3ISIAoLZGVzY3JpcHRpb24YByABKAlSC2Rlc2NyaXB0aW9uEkAKC2NyZWF0ZV90
aW1lGAggASgLMhouZ29vZ2xlLnByb3RvYnVmLlRpbWVzdGFtcEID4EEDUgpjcmVhdGVUaW1l
EkAKC3VwZGF0ZV90aW1lGAkgASgLMhouZ29vZ2xlLnByb3RvYnVmLlRpbWVzdGFtcEID4EED
Ugp1cGRhdGVUaW1lElQKDmNsb3VkX3Byb3ZpZGVyGAogASgOMi0uZ29vZ2xlLmNsb3VkLnNl
Y3VyaXR5Y2VudGVyLnYxLkNsb3VkUHJvdmlkZXJSDWNsb3VkUHJvdmlkZXISnQEKIXNlbnNp
dGl2ZV9kYXRhX3Byb3RlY3Rpb25fbWFwcGluZxgLIAEoCzJSLmdvb2dsZS5jbG91ZC5zZWN1
cml0eWNlbnRlci52MS5SZXNvdXJjZVZhbHVlQ29uZmlnLlNlbnNpdGl2ZURhdGFQcm90ZWN0
aW9uTWFwcGluZ1Iec2Vuc2l0aXZlRGF0YVByb3RlY3Rpb25NYXBwaW5nGvYBCh5TZW5zaXRp
dmVEYXRhUHJvdGVjdGlvbk1hcHBpbmcSZwoYaGlnaF9zZW5zaXRpdml0eV9tYXBwaW5nGAEg
ASgOMi0uZ29vZ2xlLmNsb3VkLnNlY3VyaXR5Y2VudGVyLnYxLlJlc291cmNlVmFsdWVSFmhp
Z2hTZW5zaXRpdml0eU1hcHBpbmcSawoabWVkaXVtX3NlbnNpdGl2aXR5X21hcHBpbmcYAiAB
KA4yLS5nb29nbGUuY2xvdWQuc2VjdXJpdHljZW50ZXIudjEuUmVzb3VyY2VWYWx1ZVIYbWVk
aXVtU2Vuc2l0aXZpdHlNYXBwaW5nGkkKG1Jlc291cmNlTGFiZWxzU2VsZWN0b3JFbnRyeRIQ
CgNrZXkYASABKAlSA2tleRIUCgV2YWx1ZRgCIAEoCVIFdmFsdWU6AjgBOq0B6kGpAQoxc2Vj
dXJpdHljZW50ZXIuZ29vZ2xlYXBpcy5jb20vUmVzb3VyY2VWYWx1ZUNvbmZpZxJJb3JnYW5p
emF0aW9ucy97b3JnYW5pemF0aW9ufS9yZXNvdXJjZVZhbHVlQ29uZmlncy97cmVzb3VyY2Vf
dmFsdWVfY29uZmlnfSoUcmVzb3VyY2VWYWx1ZUNvbmZpZ3MyE3Jlc291cmNlVmFsdWVDb25m
aWcqWAoNUmVzb3VyY2VWYWx1ZRIeChpSRVNPVVJDRV9WQUxVRV9VTlNQRUNJRklFRBAAEggK
BEhJR0gQARIKCgZNRURJVU0QAhIHCgNMT1cQAxIICgROT05FEARC8gEKImNvbS5nb29nbGUu
Y2xvdWQuc2VjdXJpdHljZW50ZXIudjFCGFJlc291cmNlVmFsdWVDb25maWdQcm90b1ABWkpj
bG91ZC5nb29nbGUuY29tL2dvL3NlY3VyaXR5Y2VudGVyL2FwaXYxL3NlY3VyaXR5Y2VudGVy
cGI7c2VjdXJpdHljZW50ZXJwYqoCHkdvb2dsZS5DbG91ZC5TZWN1cml0eUNlbnRlci5WMcoC
Hkdvb2dsZVxDbG91ZFxTZWN1cml0eUNlbnRlclxWMeoCIUdvb2dsZTo6Q2xvdWQ6OlNlY3Vy
aXR5Q2VudGVyOjpWMUqsIQoGEgQOAHoBCrwECgEMEgMOABIysQQgQ29weXJpZ2h0IDIwMjUg
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
bnNlLgoKCAoBAhIDEAAnCgkKAgMAEgMSACkKCQoCAwESAxMAIwoJCgIDAhIDFAA3CgkKAgMD
EgMVACkKCAoBCBIDFwA7CgkKAgglEgMXADsKCAoBCBIDGABhCgkKAggLEgMYAGEKCAoBCBID
GQAiCgkKAggKEgMZACIKCAoBCBIDGgA5CgkKAggIEgMaADkKCAoBCBIDGwA7CgkKAggBEgMb
ADsKCAoBCBIDHAA7CgkKAggpEgMcADsKCAoBCBIDHQA6CgkKAggtEgMdADoKmAEKAgQAEgQh
AGgBGosBIEEgcmVzb3VyY2UgdmFsdWUgY29uZmlndXJhdGlvbiAoUlZDKSBpcyBhIG1hcHBp
bmcgY29uZmlndXJhdGlvbiBvZiB1c2VyJ3MKIHJlc291cmNlcyB0byByZXNvdXJjZSB2YWx1
ZXMuIFVzZWQgaW4gQXR0YWNrIHBhdGggc2ltdWxhdGlvbnMuCgoKCgMEAAESAyEIGwoLCgME
AAcSBCICJwQKDQoFBAAHnQgSBCICJwQK4wEKBAQAAwASBCwCNAMa1AEgUmVzb3VyY2UgdmFs
dWUgbWFwcGluZyBmb3IgU2Vuc2l0aXZlIERhdGEgUHJvdGVjdGlvbiBmaW5kaW5ncy4KIElm
IGFueSBvZiB0aGVzZSBtYXBwaW5ncyBoYXZlIGEgcmVzb3VyY2UgdmFsdWUgdGhhdCBpcyBu
b3QgdW5zcGVjaWZpZWQsCiB0aGUgcmVzb3VyY2VfdmFsdWUgZmllbGQgd2lsbCBiZSBpZ25v
cmVkIHdoZW4gcmVhZGluZyB0aGlzIGNvbmZpZ3VyYXRpb24uCgoMCgUEAAMAARIDLAooCmAK
BgQAAwACABIDLwQvGlEgUmVzb3VyY2UgdmFsdWUgbWFwcGluZyBmb3IgaGlnaC1zZW5zaXRp
dml0eSBTZW5zaXRpdmUgRGF0YSBQcm90ZWN0aW9uCiBmaW5kaW5ncwoKDgoHBAADAAIABhID
LwQRCg4KBwQAAwACAAESAy8SKgoOCgcEAAMAAgADEgMvLS4KYgoGBAADAAIBEgMzBDEaUyBS
ZXNvdXJjZSB2YWx1ZSBtYXBwaW5nIGZvciBtZWRpdW0tc2Vuc2l0aXZpdHkgU2Vuc2l0aXZl
IERhdGEgUHJvdGVjdGlvbgogZmluZGluZ3MKCg4KBwQAAwACAQYSAzMEEQoOCgcEAAMAAgEB
EgMzEiwKDgoHBAADAAIBAxIDMy8wCjgKBAQAAgASAzcCEhorIE5hbWUgZm9yIHRoZSByZXNv
dXJjZSB2YWx1ZSBjb25maWd1cmF0aW9uCgoMCgUEAAIABRIDNwIICgwKBQQAAgABEgM3CQ0K
DAoFBAACAAMSAzcQEQpICgQEAAIBEgM6AkwaOyBSZXF1aXJlZC4gUmVzb3VyY2UgdmFsdWUg
bGV2ZWwgdGhpcyBleHByZXNzaW9uIHJlcHJlc2VudHMKCgwKBQQAAgEGEgM6Ag8KDAoFBAAC
AQESAzoQHgoMCgUEAAIBAxIDOiEiCgwKBQQAAgEIEgM6I0sKDwoIBAACAQicCAASAzokSgqA
AgoEBAACAhIDQAJKGvIBIFJlcXVpcmVkLiBUYWcgdmFsdWVzIGNvbWJpbmVkIHdpdGggYEFO
RGAgdG8gY2hlY2sgYWdhaW5zdC4KIFZhbHVlcyBpbiB0aGUgZm9ybSAidGFnVmFsdWVzLzEy
MyIKIEV4YW1wbGU6IGBbICJ0YWdWYWx1ZXMvMTIzIiwgInRhZ1ZhbHVlcy80NTYiLCAidGFn
VmFsdWVzLzc4OSIgXWAKIGh0dHBzOi8vY2xvdWQuZ29vZ2xlLmNvbS9yZXNvdXJjZS1tYW5h
Z2VyL2RvY3MvdGFncy90YWdzLWNyZWF0aW5nLWFuZC1tYW5hZ2luZwoKDAoFBAACAgQSA0AC
CgoMCgUEAAICBRIDQAsRCgwKBQQAAgIBEgNAEhwKDAoFBAACAgMSA0AfIAoMCgUEAAICCBID
QCFJCg8KCAQAAgIInAgAEgNAIkgKowIKBAQAAgMSA0YCGxqVAiBBcHBseSByZXNvdXJjZV92
YWx1ZSBvbmx5IHRvIHJlc291cmNlcyB0aGF0IG1hdGNoIHJlc291cmNlX3R5cGUuCiByZXNv
dXJjZV90eXBlIHdpbGwgYmUgY2hlY2tlZCB3aXRoIGBBTkRgIG9mIG90aGVyIHJlc291cmNl
cy4KIEZvciBleGFtcGxlLCAic3RvcmFnZS5nb29nbGVhcGlzLmNvbS9CdWNrZXQiIHdpdGgg
cmVzb3VyY2VfdmFsdWUgIkhJR0giCiB3aWxsIGFwcGx5ICJISUdIIiB2YWx1ZSBvbmx5IHRv
ICJzdG9yYWdlLmdvb2dsZWFwaXMuY29tL0J1Y2tldCIgcmVzb3VyY2VzLgoKDAoFBAACAwUS
A0YCCAoMCgUEAAIDARIDRgkWCgwKBQQAAgMDEgNGGRoK1gEKBAQAAgQSA0wCExrIASBQcm9q
ZWN0IG9yIGZvbGRlciB0byBzY29wZSB0aGlzIGNvbmZpZ3VyYXRpb24gdG8uCiBGb3IgZXhh
bXBsZSwgInByb2plY3QvNDU2IiB3b3VsZCBhcHBseSB0aGlzIGNvbmZpZ3VyYXRpb24gb25s
eSB0byByZXNvdXJjZXMKIGluICJwcm9qZWN0LzQ1NiIgc2NvcGUgd2lsbCBiZSBjaGVja2Vk
IHdpdGggYEFORGAgb2Ygb3RoZXIKIHJlc291cmNlcy4KCgwKBQQAAgQFEgNMAggKDAoFBAAC
BAESA0wJDgoMCgUEAAIEAxIDTBESCqcCCgQEAAIFEgNTAjMamQIgTGlzdCBvZiByZXNvdXJj
ZSBsYWJlbHMgdG8gc2VhcmNoIGZvciwgZXZhbHVhdGVkIHdpdGggYEFORGAuCiBGb3IgZXhh
bXBsZSwgYCJyZXNvdXJjZV9sYWJlbHNfc2VsZWN0b3IiOiB7ImtleSI6ICJ2YWx1ZSIsICJl
bnYiOiAicHJvZCJ9YAogd2lsbCBtYXRjaCByZXNvdXJjZXMgd2l0aCBsYWJlbHMgImtleSI6
ICJ2YWx1ZSIgYEFORGAgImVudiI6CiAicHJvZCIKIGh0dHBzOi8vY2xvdWQuZ29vZ2xlLmNv
bS9yZXNvdXJjZS1tYW5hZ2VyL2RvY3MvY3JlYXRpbmctbWFuYWdpbmctbGFiZWxzCgoMCgUE
AAIFBhIDUwIVCgwKBQQAAgUBEgNTFi4KDAoFBAACBQMSA1MxMgo/CgQEAAIGEgNWAhkaMiBE
ZXNjcmlwdGlvbiBvZiB0aGUgcmVzb3VyY2UgdmFsdWUgY29uZmlndXJhdGlvbi4KCgwKBQQA
AgYFEgNWAggKDAoFBAACBgESA1YJFAoMCgUEAAIGAxIDVhcYClUKBAQAAgcSBFkCWjIaRyBP
dXRwdXQgb25seS4gVGltZXN0YW1wIHRoaXMgcmVzb3VyY2UgdmFsdWUgY29uZmlndXJhdGlv
biB3YXMgY3JlYXRlZC4KCgwKBQQAAgcGEgNZAhsKDAoFBAACBwESA1kcJwoMCgUEAAIHAxID
WSorCgwKBQQAAgcIEgNaBjEKDwoIBAACBwicCAASA1oHMApaCgQEAAIIEgRdAl4yGkwgT3V0
cHV0IG9ubHkuIFRpbWVzdGFtcCB0aGlzIHJlc291cmNlIHZhbHVlIGNvbmZpZ3VyYXRpb24g
d2FzIGxhc3QgdXBkYXRlZC4KCgwKBQQAAggGEgNdAhsKDAoFBAACCAESA10cJwoMCgUEAAII
AxIDXSorCgwKBQQAAggIEgNeBjEKDwoIBAACCAicCAASA14HMAo7CgQEAAIJEgNhAiQaLiBD
bG91ZCBwcm92aWRlciB0aGlzIGNvbmZpZ3VyYXRpb24gYXBwbGllcyB0bwoKDAoFBAACCQYS
A2ECDwoMCgUEAAIJARIDYRAeCgwKBQQAAgkDEgNhISMK7wEKBAQAAgoSA2cCSBrhASBBIG1h
cHBpbmcgb2YgdGhlIHNlbnNpdGl2aXR5IG9uIFNlbnNpdGl2ZSBEYXRhIFByb3RlY3Rpb24g
ZmluZGluZyB0bwogcmVzb3VyY2UgdmFsdWVzLiBUaGlzIG1hcHBpbmcgY2FuIG9ubHkgYmUg
dXNlZCBpbiBjb21iaW5hdGlvbiB3aXRoIGEKIHJlc291cmNlX3R5cGUgdGhhdCBpcyByZWxh
dGVkIHRvIEJpZ1F1ZXJ5LCBlLmcuCiAiYmlncXVlcnkuZ29vZ2xlYXBpcy5jb20vRGF0YXNl
dCIuCgoMCgUEAAIKBhIDZwIgCgwKBQQAAgoBEgNnIUIKDAoFBAACCgMSA2dFRwotCgIFABIE
awB6ARohIFZhbHVlIGVudW0gdG8gbWFwIHRvIGEgcmVzb3VyY2UKCgoKAwUAARIDawUSCh8K
BAUAAgASA20CIRoSIFVuc3BlY2lmaWMgdmFsdWUKCgwKBQUAAgABEgNtAhwKDAoFBQACAAIS
A20fIAoiCgQFAAIBEgNwAgsaFSBIaWdoIHJlc291cmNlIHZhbHVlCgoMCgUFAAIBARIDcAIG
CgwKBQUAAgECEgNwCQoKJAoEBQACAhIDcwINGhcgTWVkaXVtIHJlc291cmNlIHZhbHVlCgoM
CgUFAAICARIDcwIICgwKBQUAAgICEgNzCwwKIQoEBQACAxIDdgIKGhQgTG93IHJlc291cmNl
IHZhbHVlCgoMCgUFAAIDARIDdgIFCgwKBQUAAgMCEgN2CAkKPQoEBQACBBIDeQILGjAgTm8g
cmVzb3VyY2UgdmFsdWUsIGUuZy4gaWdub3JlIHRoZXNlIHJlc291cmNlcwoKDAoFBQACBAES
A3kCBgoMCgUFAAIEAhIDeQkKYgZwcm90bzM=
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Securitycenter::V1::ResourceValueConfig::ResourceValueConfig ===
    # Fields for ResourceValueConfig
    # Field: name Type: 9 ()
    # Field: resource_value Type: 14 (.google.cloud.securitycenter.v1.ResourceValue)
    # Field: tag_values Type: 9 ()
    # Field: resource_type Type: 9 ()
    # Field: scope Type: 9 ()
    # Field: resource_labels_selector Type: 11 (.google.cloud.securitycenter.v1.ResourceValueConfig.ResourceLabelsSelectorEntry)
    # Field: description Type: 9 ()
    # Field: create_time Type: 11 (.google.protobuf.Timestamp)
    # Field: update_time Type: 11 (.google.protobuf.Timestamp)
    # Field: cloud_provider Type: 14 (.google.cloud.securitycenter.v1.CloudProvider)
    # Field: sensitive_data_protection_mapping Type: 11 (.google.cloud.securitycenter.v1.ResourceValueConfig.SensitiveDataProtectionMapping)

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Securitycenter::V1::ResourceValueConfig - Compiled Protocol Buffers messages for google/cloud/securitycenter/v1/resource_value_config.proto

=head1 SYNOPSIS

    use Google::Cloud::Securitycenter::V1::ResourceValueConfig;

    my $msg = Google::Cloud::Securitycenter::V1::ResourceValueConfig::ResourceValueConfig->new({
        name => $name,
        resource_value => $resource_value,
        tag_values => $tag_values,
        resource_type => $resource_type,
    });

    # Read or update a field
    my $val = $msg->name();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Securitycenter::V1::ResourceValueConfig::ResourceValueConfig->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/securitycenter/v1/resource_value_config.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Securitycenter::V1::ResourceValueConfig::ResourceValueConfig

A resource value configuration (RVC) is a mapping configuration of user's
resources to resource values. Used in Attack path simulations.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Name for the resource value configuration

=item * C<< $msg->resource_value() >> / C<< $msg->resource_value($value) >>

Type: C<Enum> (L<Google::Cloud::Securitycenter::V1::ResourceValue>)

Required. Resource value level this expression represents

=item * C<< $msg->tag_values() >> / C<< $msg->tag_values($value) >>

Type: C<String>

Required. Tag values combined with `AND` to check against.
Values in the form "tagValues/123"
Example: `[ "tagValues/123", "tagValues/456", "tagValues/789" ]`
https://cloud.google.com/resource-manager/docs/tags/tags-creating-and-managing

=item * C<< $msg->resource_type() >> / C<< $msg->resource_type($value) >>

Type: C<String>

Apply resource_value only to resources that match resource_type.
resource_type will be checked with `AND` of other resources.
For example, "storage.googleapis.com/Bucket" with resource_value "HIGH"
will apply "HIGH" value only to "storage.googleapis.com/Bucket" resources.

=item * C<< $msg->scope() >> / C<< $msg->scope($value) >>

Type: C<String>

Project or folder to scope this configuration to.
For example, "project/456" would apply this configuration only to resources
in "project/456" scope will be checked with `AND` of other
resources.

=item * C<< $msg->resource_labels_selector() >> / C<< $msg->resource_labels_selector($value) >>

Type: C<Message> (L<Google::Cloud::Securitycenter::V1::ResourceValueConfig::ResourceValueConfig::ResourceLabelsSelectorEntry>)

List of resource labels to search for, evaluated with `AND`.
For example, `"resource_labels_selector": {"key": "value", "env": "prod"}`
will match resources with labels "key": "value" `AND` "env":
"prod"
https://cloud.google.com/resource-manager/docs/creating-managing-labels

=item * C<< $msg->description() >> / C<< $msg->description($value) >>

Type: C<String>

Description of the resource value configuration.

=item * C<< $msg->create_time() >> / C<< $msg->create_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Output only. Timestamp this resource value configuration was created.

=item * C<< $msg->update_time() >> / C<< $msg->update_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Output only. Timestamp this resource value configuration was last updated.

=item * C<< $msg->cloud_provider() >> / C<< $msg->cloud_provider($value) >>

Type: C<Enum> (L<Google::Cloud::Securitycenter::V1::CloudProvider>)

Cloud provider this configuration applies to

=item * C<< $msg->sensitive_data_protection_mapping() >> / C<< $msg->sensitive_data_protection_mapping($value) >>

Type: C<Message> (L<Google::Cloud::Securitycenter::V1::ResourceValueConfig::ResourceValueConfig::SensitiveDataProtectionMapping>)

A mapping of the sensitivity on Sensitive Data Protection finding to
resource values. This mapping can only be used in combination with a
resource_type that is related to BigQuery, e.g.
"bigquery.googleapis.com/Dataset".

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Securitycenter::V1::ResourceValueConfig::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
