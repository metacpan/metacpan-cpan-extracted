package Google::Cloud::Securitycenter::V1::CloudDlpDataProfile;

use strict;
use warnings;

our $VERSION = '0.14';

use Protobuf::Message;
use Protobuf::DescriptorPool;
use Protobuf::Internal qw(:all);
use MIME::Base64;

BEGIN {
    eval { require Google::Api::Resource };
    my $descriptor_b64 = <<'EOF';
Cjtnb29nbGUvY2xvdWQvc2VjdXJpdHljZW50ZXIvdjEvY2xvdWRfZGxwX2RhdGFfcHJvZmls
ZS5wcm90bxIeZ29vZ2xlLmNsb3VkLnNlY3VyaXR5Y2VudGVyLnYxGhlnb29nbGUvYXBpL3Jl
c291cmNlLnByb3RvItYCChNDbG91ZERscERhdGFQcm9maWxlEksKDGRhdGFfcHJvZmlsZRgB
IAEoCUIo+kElCiNkbHAuZ29vZ2xlYXBpcy5jb20vVGFibGVEYXRhUHJvZmlsZVILZGF0YVBy
b2ZpbGUSXwoLcGFyZW50X3R5cGUYAiABKA4yPi5nb29nbGUuY2xvdWQuc2VjdXJpdHljZW50
ZXIudjEuQ2xvdWREbHBEYXRhUHJvZmlsZS5QYXJlbnRUeXBlUgpwYXJlbnRUeXBlEkcKCmlu
Zm9fdHlwZXMYAyADKAsyKC5nb29nbGUuY2xvdWQuc2VjdXJpdHljZW50ZXIudjEuSW5mb1R5
cGVSCWluZm9UeXBlcyJICgpQYXJlbnRUeXBlEhsKF1BBUkVOVF9UWVBFX1VOU1BFQ0lGSUVE
EAASEAoMT1JHQU5JWkFUSU9OEAESCwoHUFJPSkVDVBACIpcBCghJbmZvVHlwZRISCgRuYW1l
GAEgASgJUgRuYW1lEhgKB3ZlcnNpb24YAiABKAlSB3ZlcnNpb24SXQoRc2Vuc2l0aXZpdHlf
c2NvcmUYAyABKAsyMC5nb29nbGUuY2xvdWQuc2VjdXJpdHljZW50ZXIudjEuU2Vuc2l0aXZp
dHlTY29yZVIQc2Vuc2l0aXZpdHlTY29yZSKRAgoQU2Vuc2l0aXZpdHlTY29yZRJcCgVzY29y
ZRgBIAEoDjJGLmdvb2dsZS5jbG91ZC5zZWN1cml0eWNlbnRlci52MS5TZW5zaXRpdml0eVNj
b3JlLlNlbnNpdGl2aXR5U2NvcmVMZXZlbFIFc2NvcmUingEKFVNlbnNpdGl2aXR5U2NvcmVM
ZXZlbBInCiNTRU5TSVRJVklUWV9TQ09SRV9MRVZFTF9VTlNQRUNJRklFRBAAEhMKD1NFTlNJ
VElWSVRZX0xPVxAKEhcKE1NFTlNJVElWSVRZX1VOS05PV04QDBIYChRTRU5TSVRJVklUWV9N
T0RFUkFURRAUEhQKEFNFTlNJVElWSVRZX0hJR0gQHkKUAwoiY29tLmdvb2dsZS5jbG91ZC5z
ZWN1cml0eWNlbnRlci52MUIYQ2xvdWREbHBEYXRhUHJvZmlsZVByb3RvUAFaSmNsb3VkLmdv
b2dsZS5jb20vZ28vc2VjdXJpdHljZW50ZXIvYXBpdjEvc2VjdXJpdHljZW50ZXJwYjtzZWN1
cml0eWNlbnRlcnBiqgIeR29vZ2xlLkNsb3VkLlNlY3VyaXR5Q2VudGVyLlYxygIeR29vZ2xl
XENsb3VkXFNlY3VyaXR5Q2VudGVyXFYx6gIhR29vZ2xlOjpDbG91ZDo6U2VjdXJpdHlDZW50
ZXI6OlYx6kGeAQojZGxwLmdvb2dsZWFwaXMuY29tL1RhYmxlRGF0YVByb2ZpbGUSMHByb2pl
Y3RzL3twcm9qZWN0fS90YWJsZVByb2ZpbGVzL3t0YWJsZV9wcm9maWxlfRJFcHJvamVjdHMv
e3Byb2plY3R9L2xvY2F0aW9ucy97bG9jYXRpb259L3RhYmxlUHJvZmlsZXMve3RhYmxlX3By
b2ZpbGV9SpUcCgYSBA4AcAEKvAQKAQwSAw4AEjKxBCBDb3B5cmlnaHQgMjAyNiBHb29nbGUg
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
CgECEgMQACcKCQoCAwASAxIAIwoICgEIEgMUADsKCQoCCCUSAxQAOwoICgEIEgMVAGEKCQoC
CAsSAxUAYQoICgEIEgMWACIKCQoCCAoSAxYAIgoICgEIEgMXADkKCQoCCAgSAxcAOQoICgEI
EgMYADsKCQoCCAESAxgAOwoICgEIEgMZADsKCQoCCCkSAxkAOwoICgEIEgMaADoKCQoCCC0S
AxoAOgoJCgEIEgQbAB8CCgwKBAidCAASBBsAHwIKbwoCBAASBCMAPQEaYyBUaGUgW2RhdGEg
cHJvZmlsZV0oaHR0cHM6Ly9jbG91ZC5nb29nbGUuY29tL2RscC9kb2NzL2RhdGEtcHJvZmls
ZXMpCiBhc3NvY2lhdGVkIHdpdGggdGhlIGZpbmRpbmcuCgoKCgMEAAESAyMIGwpOCgQEAAQA
EgQlAi4DGkAgUGFyZW50cyBmb3IgY29uZmlndXJhdGlvbnMgdGhhdCBwcm9kdWNlIGRhdGEg
cHJvZmlsZSBmaW5kaW5ncy4KCgwKBQQABAABEgMlBxEKKQoGBAAEAAIAEgMnBCAaGiBVbnNw
ZWNpZmllZCBwYXJlbnQgdHlwZS4KCg4KBwQABAACAAESAycEGwoOCgcEAAQAAgACEgMnHh8K
MwoGBAAEAAIBEgMqBBUaJCBPcmdhbml6YXRpb24tbGV2ZWwgY29uZmlndXJhdGlvbnMuCgoO
CgcEAAQAAgEBEgMqBBAKDgoHBAAEAAIBAhIDKhMUCi4KBgQABAACAhIDLQQQGh8gUHJvamVj
dC1sZXZlbCBjb25maWd1cmF0aW9ucy4KCg4KBwQABAACAgESAy0ECwoOCgcEAAQAAgICEgMt
Dg8KbgoEBAACABIEMgI0BRpgIE5hbWUgb2YgdGhlIGRhdGEgcHJvZmlsZSwgZm9yIGV4YW1w
bGUsCiBgcHJvamVjdHMvMTIzL2xvY2F0aW9ucy9ldXJvcGUvdGFibGVQcm9maWxlcy84Mzgz
OTI5YC4KCgwKBQQAAgAFEgMyAggKDAoFBAACAAESAzIJFQoMCgUEAAIAAxIDMhgZCg0KBQQA
AgAIEgQyGjQECg8KBwQAAgAInwgSBDIbNAMKVAoEBAACARIDNwIdGkcgVGhlIHJlc291cmNl
IGhpZXJhcmNoeSBsZXZlbCBhdCB3aGljaCB0aGUgZGF0YSBwcm9maWxlIHdhcyBnZW5lcmF0
ZWQuCgoMCgUEAAIBBhIDNwIMCgwKBQQAAgEBEgM3DRgKDAoFBAACAQMSAzcbHAqIAQoEBAAC
AhIDPAIjGnsgVHlwZSBvZiBpbmZvcm1hdGlvbiBkZXRlY3RlZCBieSBTRFAuCiBJbmZvIHR5
cGUgaW5jbHVkZXMgbmFtZSwgdmVyc2lvbiBhbmQgc2Vuc2l0aXZpdHkgb2YgdGhlIGRldGVj
dGVkCiBpbmZvcm1hdGlvbiB0eXBlLgoKDAoFBAACAgQSAzwCCgoMCgUEAAICBhIDPAsTCgwK
BQQAAgIBEgM8FB4KDAoFBAACAgMSAzwhIgo2CgIEARIEQABQARoqIFR5cGUgb2YgaW5mb3Jt
YXRpb24gZGV0ZWN0ZWQgYnkgdGhlIEFQSS4KCgoKAwQBARIDQAgQCvMCCgQEAQIAEgNIAhIa
5QIgTmFtZSBvZiB0aGUgaW5mb3JtYXRpb24gdHlwZS4gRWl0aGVyIGEgbmFtZSBvZiB5b3Vy
IGNob29zaW5nIHdoZW4KIGNyZWF0aW5nIGEgQ3VzdG9tSW5mb1R5cGUsIG9yIG9uZSBvZiB0
aGUgbmFtZXMgbGlzdGVkCiBhdAogaHR0cHM6Ly9jbG91ZC5nb29nbGUuY29tL3NlbnNpdGl2
ZS1kYXRhLXByb3RlY3Rpb24vZG9jcy9pbmZvdHlwZXMtcmVmZXJlbmNlCiB3aGVuIHNwZWNp
ZnlpbmcgYSBidWlsdC1pbiB0eXBlLiAgV2hlbiBzZW5kaW5nIENsb3VkIERMUCByZXN1bHRz
IHRvIERhdGEKIENhdGFsb2csIGluZm9UeXBlIG5hbWVzIHNob3VsZCBjb25mb3JtIHRvIHRo
ZSBwYXR0ZXJuCiBgW0EtWmEtejAtOSRfLV17MSw2NH1gLgoKDAoFBAECAAUSA0gCCAoMCgUE
AQIAARIDSAkNCgwKBQQBAgADEgNIEBEKNwoEBAECARIDSwIVGiogT3B0aW9uYWwgdmVyc2lv
biBuYW1lIGZvciB0aGlzIEluZm9UeXBlLgoKDAoFBAECAQUSA0sCCAoMCgUEAQIBARIDSwkQ
CgwKBQQBAgEDEgNLExQKYwoEBAECAhIDTwIpGlYgT3B0aW9uYWwgY3VzdG9tIHNlbnNpdGl2
aXR5IGZvciB0aGlzIEluZm9UeXBlLgogVGhpcyBvbmx5IGFwcGxpZXMgdG8gZGF0YSBwcm9m
aWxpbmcuCgoMCgUEAQICBhIDTwISCgwKBQQBAgIBEgNPEyQKDAoFBAECAgMSA08nKAp9CgIE
AhIEVABwARpxIFNjb3JlIGlzIGNhbGN1bGF0ZWQgZnJvbSBvZiBhbGwgZWxlbWVudHMgaW4g
dGhlIGRhdGEgcHJvZmlsZS4KIEEgaGlnaGVyIGxldmVsIG1lYW5zIHRoZSBkYXRhIGlzIG1v
cmUgc2Vuc2l0aXZlLgoKCgoDBAIBEgNUCBgKPwoEBAIEABIEVgJsAxoxIFZhcmlvdXMgc2Vu
c2l0aXZpdHkgc2NvcmUgbGV2ZWxzIGZvciByZXNvdXJjZXMuCgoMCgUEAgQAARIDVgccChgK
BgQCBAACABIDWAQsGgkgVW51c2VkLgoKDgoHBAIEAAIAARIDWAQnCg4KBwQCBAACAAISA1gq
KwpcCgYEAgQAAgESA1wEGRpNIE5vIHNlbnNpdGl2ZSBpbmZvcm1hdGlvbiBkZXRlY3RlZC4g
VGhlIHJlc291cmNlIGlzbid0IHB1YmxpY2x5CiBhY2Nlc3NpYmxlLgoKDgoHBAIEAAIBARID
XAQTCg4KBwQCBAACAQISA1wWGAoxCgYEAgQAAgISA18EHRoiIFVuYWJsZSB0byBkZXRlcm1p
bmUgc2Vuc2l0aXZpdHkuCgoOCgcEAgQAAgIBEgNfBBcKDgoHBAIEAAICAhIDXxocCuoBCgYE
AgQAAgMSA2UEHhraASBNZWRpdW0gcmlzay4gQ29udGFpbnMgcGVyc29uYWxseSBpZGVudGlm
aWFibGUgaW5mb3JtYXRpb24gKFBJSSksCiBwb3RlbnRpYWxseSBzZW5zaXRpdmUgZGF0YSwg
b3IgZmllbGRzIHdpdGggZnJlZS10ZXh0IGRhdGEgdGhhdCBhcmUgYXQgYQogaGlnaGVyIHJp
c2sgb2YgaGF2aW5nIGludGVybWl0dGVudCBzZW5zaXRpdmUgZGF0YS4gQ29uc2lkZXIgbGlt
aXRpbmcKIGFjY2Vzcy4KCg4KBwQCBAACAwESA2UEGAoOCgcEAgQAAgMCEgNlGx0K8QEKBgQC
BAACBBIDawQaGuEBIEhpZ2ggcmlzay4gU2Vuc2l0aXZlIHBlcnNvbmFsbHkgaWRlbnRpZmlh
YmxlIGluZm9ybWF0aW9uIChTUElJKSBjYW4gYmUKIHByZXNlbnQuIEV4ZmlsdHJhdGlvbiBv
ZiBkYXRhIGNhbiBsZWFkIHRvIHVzZXIgZGF0YSBsb3NzLgogUmUtaWRlbnRpZmljYXRpb24g
b2YgdXNlcnMgbWlnaHQgYmUgcG9zc2libGUuIENvbnNpZGVyIGxpbWl0aW5nIHVzYWdlIGFu
ZAogb3IgcmVtb3ZpbmcgU1BJSS4KCg4KBwQCBAACBAESA2sEFAoOCgcEAgQAAgQCEgNrFxkK
PQoEBAICABIDbwIiGjAgVGhlIHNlbnNpdGl2aXR5IHNjb3JlIGFwcGxpZWQgdG8gdGhlIHJl
c291cmNlLgoKDAoFBAICAAYSA28CFwoMCgUEAgIAARIDbxgdCgwKBQQCAgADEgNvICFiBnBy
b3RvMw==
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Securitycenter::V1::CloudDlpDataProfile::CloudDlpDataProfile ===
    # Fields for CloudDlpDataProfile
    # Field: data_profile Type: 9 ()
    # Field: parent_type Type: 14 (.google.cloud.securitycenter.v1.CloudDlpDataProfile.ParentType)
    # Field: info_types Type: 11 (.google.cloud.securitycenter.v1.InfoType)

# Enum: CloudDlpDataProfile::ParentType
our $CloudDlpDataProfile_PARENT_TYPE_UNSPECIFIED = 0;
our $CloudDlpDataProfile_ORGANIZATION = 1;
our $CloudDlpDataProfile_PROJECT = 2;

# === Message: Google::Cloud::Securitycenter::V1::CloudDlpDataProfile::InfoType ===
    # Fields for InfoType
    # Field: name Type: 9 ()
    # Field: version Type: 9 ()
    # Field: sensitivity_score Type: 11 (.google.cloud.securitycenter.v1.SensitivityScore)

# === Message: Google::Cloud::Securitycenter::V1::CloudDlpDataProfile::SensitivityScore ===
    # Fields for SensitivityScore
    # Field: score Type: 14 (.google.cloud.securitycenter.v1.SensitivityScore.SensitivityScoreLevel)

# Enum: SensitivityScore::SensitivityScoreLevel
our $SensitivityScore_SENSITIVITY_SCORE_LEVEL_UNSPECIFIED = 0;
our $SensitivityScore_SENSITIVITY_LOW = 10;
our $SensitivityScore_SENSITIVITY_UNKNOWN = 12;
our $SensitivityScore_SENSITIVITY_MODERATE = 20;
our $SensitivityScore_SENSITIVITY_HIGH = 30;

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Securitycenter::V1::CloudDlpDataProfile - Compiled Protocol Buffers messages for google/cloud/securitycenter/v1/cloud_dlp_data_profile.proto

=head1 SYNOPSIS

    use Google::Cloud::Securitycenter::V1::CloudDlpDataProfile;

    my $msg = Google::Cloud::Securitycenter::V1::CloudDlpDataProfile::CloudDlpDataProfile->new({
        data_profile => $data_profile,
        parent_type => $parent_type,
        info_types => $info_types,
    });

    # Read or update a field
    my $val = $msg->data_profile();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Securitycenter::V1::CloudDlpDataProfile::CloudDlpDataProfile->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/securitycenter/v1/cloud_dlp_data_profile.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Securitycenter::V1::CloudDlpDataProfile::CloudDlpDataProfile

The [data profile](https://cloud.google.com/dlp/docs/data-profiles)
associated with the finding.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->data_profile() >> / C<< $msg->data_profile($value) >>

Type: C<String>

Name of the data profile, for example,
`projects/123/locations/europe/tableProfiles/8383929`.

=item * C<< $msg->parent_type() >> / C<< $msg->parent_type($value) >>

Type: C<Enum> (L<Google::Cloud::Securitycenter::V1::CloudDlpDataProfile::ParentType>)

The resource hierarchy level at which the data profile was generated.

=item * C<< $msg->info_types() >> / C<< $msg->info_types($value) >>

Type: C<Message> (L<Google::Cloud::Securitycenter::V1::CloudDlpDataProfile::InfoType>)

Type of information detected by SDP.
Info type includes name, version and sensitivity of the detected
information type.

=back

=head3 Enum: CloudDlpDataProfile::ParentType

=over 4

=item * C<PARENT_TYPE_UNSPECIFIED> => C<0>

=item * C<ORGANIZATION> => C<1>

=item * C<PROJECT> => C<2>

=back

=head2 Google::Cloud::Securitycenter::V1::CloudDlpDataProfile::InfoType

Type of information detected by the API.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Name of the information type. Either a name of your choosing when
creating a CustomInfoType, or one of the names listed
at
https://cloud.google.com/sensitive-data-protection/docs/infotypes-reference
when specifying a built-in type.  When sending Cloud DLP results to Data
Catalog, infoType names should conform to the pattern
`[A-Za-z0-9$_-]{1,64}`.

=item * C<< $msg->version() >> / C<< $msg->version($value) >>

Type: C<String>

Optional version name for this InfoType.

=item * C<< $msg->sensitivity_score() >> / C<< $msg->sensitivity_score($value) >>

Type: C<Message> (L<Google::Cloud::Securitycenter::V1::CloudDlpDataProfile::SensitivityScore>)

Optional custom sensitivity for this InfoType.
This only applies to data profiling.

=back

=head2 Google::Cloud::Securitycenter::V1::CloudDlpDataProfile::SensitivityScore

Score is calculated from of all elements in the data profile.
A higher level means the data is more sensitive.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->score() >> / C<< $msg->score($value) >>

Type: C<Enum> (L<Google::Cloud::Securitycenter::V1::SensitivityScore::SensitivityScoreLevel>)

The sensitivity score applied to the resource.

=back

=head3 Enum: SensitivityScore::SensitivityScoreLevel

=over 4

=item * C<SENSITIVITY_SCORE_LEVEL_UNSPECIFIED> => C<0>

=item * C<SENSITIVITY_LOW> => C<10>

=item * C<SENSITIVITY_UNKNOWN> => C<12>

=item * C<SENSITIVITY_MODERATE> => C<20>

=item * C<SENSITIVITY_HIGH> => C<30>

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Securitycenter::V1::CloudDlpDataProfile::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
