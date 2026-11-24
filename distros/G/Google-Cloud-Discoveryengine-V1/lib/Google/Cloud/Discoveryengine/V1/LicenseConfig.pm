package Google::Cloud::Discoveryengine::V1::LicenseConfig;

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
    eval { require Google::Cloud::Discoveryengine::V1::Common };
    eval { require Google::Protobuf::Timestamp };
    eval { require Google::Type::Date };
    my $descriptor_b64 = <<'EOF';
CjRnb29nbGUvY2xvdWQvZGlzY292ZXJ5ZW5naW5lL3YxL2xpY2Vuc2VfY29uZmlnLnByb3Rv
Eh9nb29nbGUuY2xvdWQuZGlzY292ZXJ5ZW5naW5lLnYxGh9nb29nbGUvYXBpL2ZpZWxkX2Jl
aGF2aW9yLnByb3RvGhlnb29nbGUvYXBpL3Jlc291cmNlLnByb3RvGixnb29nbGUvY2xvdWQv
ZGlzY292ZXJ5ZW5naW5lL3YxL2NvbW1vbi5wcm90bxofZ29vZ2xlL3Byb3RvYnVmL3RpbWVz
dGFtcC5wcm90bxoWZ29vZ2xlL3R5cGUvZGF0ZS5wcm90byKmCAoNTGljZW5zZUNvbmZpZxIa
CgRuYW1lGAEgASgJQgbgQQXgQQhSBG5hbWUSKAoNbGljZW5zZV9jb3VudBgCIAEoA0ID4EEC
UgxsaWNlbnNlQ291bnQSYwoRc3Vic2NyaXB0aW9uX3RpZXIYAyABKA4yMS5nb29nbGUuY2xv
dWQuZGlzY292ZXJ5ZW5naW5lLnYxLlN1YnNjcmlwdGlvblRpZXJCA+BBAlIQc3Vic2NyaXB0
aW9uVGllchJPCgVzdGF0ZRgEIAEoDjI0Lmdvb2dsZS5jbG91ZC5kaXNjb3ZlcnllbmdpbmUu
djEuTGljZW5zZUNvbmZpZy5TdGF0ZUID4EEDUgVzdGF0ZRIiCgphdXRvX3JlbmV3GAUgASgI
QgPgQQFSCWF1dG9SZW5ldxI1CgpzdGFydF9kYXRlGAYgASgLMhEuZ29vZ2xlLnR5cGUuRGF0
ZUID4EECUglzdGFydERhdGUSMQoIZW5kX2RhdGUYByABKAsyES5nb29nbGUudHlwZS5EYXRl
QgPgQQFSB2VuZERhdGUSYwoRc3Vic2NyaXB0aW9uX3Rlcm0YCCABKA4yMS5nb29nbGUuY2xv
dWQuZGlzY292ZXJ5ZW5naW5lLnYxLlN1YnNjcmlwdGlvblRlcm1CA+BBAlIQc3Vic2NyaXB0
aW9uVGVybRIiCgpmcmVlX3RyaWFsGAkgASgIQgPgQQFSCWZyZWVUcmlhbBIoCg1nZW1pbmlf
YnVuZGxlGAsgASgIQgPgQQNSDGdlbWluaUJ1bmRsZRIuChBlYXJseV90ZXJtaW5hdGVkGAwg
ASgIQgPgQQNSD2Vhcmx5VGVybWluYXRlZBJMChZlYXJseV90ZXJtaW5hdGlvbl9kYXRlGA0g
ASgLMhEuZ29vZ2xlLnR5cGUuRGF0ZUID4EEDUhRlYXJseVRlcm1pbmF0aW9uRGF0ZRJSChVs
YXN0X3VzZXJfdXBkYXRlX3RpbWUYECABKAsyGi5nb29nbGUucHJvdG9idWYuVGltZXN0YW1w
QgPgQQFSEmxhc3RVc2VyVXBkYXRlVGltZSJpCgVTdGF0ZRIVChFTVEFURV9VTlNQRUNJRklF
RBAAEgoKBkFDVElWRRABEgsKB0VYUElSRUQQAhIPCgtOT1RfU1RBUlRFRBADEg0KCVdJVEhE
UkFXThAEEhAKDERFQUNUSVZBVElORxAFOpoB6kGWAQosZGlzY292ZXJ5ZW5naW5lLmdvb2ds
ZWFwaXMuY29tL0xpY2Vuc2VDb25maWcSR3Byb2plY3RzL3twcm9qZWN0fS9sb2NhdGlvbnMv
e2xvY2F0aW9ufS9saWNlbnNlQ29uZmlncy97bGljZW5zZV9jb25maWd9Kg5saWNlbnNlQ29u
ZmlnczINbGljZW5zZUNvbmZpZ0KFAgojY29tLmdvb2dsZS5jbG91ZC5kaXNjb3Zlcnllbmdp
bmUudjFCEkxpY2Vuc2VDb25maWdQcm90b1ABWk1jbG91ZC5nb29nbGUuY29tL2dvL2Rpc2Nv
dmVyeWVuZ2luZS9hcGl2MS9kaXNjb3ZlcnllbmdpbmVwYjtkaXNjb3ZlcnllbmdpbmVwYqIC
D0RJU0NPVkVSWUVOR0lORaoCH0dvb2dsZS5DbG91ZC5EaXNjb3ZlcnlFbmdpbmUuVjHKAh9H
b29nbGVcQ2xvdWRcRGlzY292ZXJ5RW5naW5lXFYx6gIiR29vZ2xlOjpDbG91ZDo6RGlzY292
ZXJ5RW5naW5lOjpWMUrBIAoGEgQOAHsBCrwECgEMEgMOABIysQQgQ29weXJpZ2h0IDIwMjYg
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
bnNlLgoKCAoBAhIDEAAoCgkKAgMAEgMSACkKCQoCAwESAxMAIwoJCgIDAhIDFAA2CgkKAgMD
EgMVACkKCQoCAwQSAxYAIAoICgEIEgMYADwKCQoCCCUSAxgAPAoICgEIEgMZAGQKCQoCCAsS
AxkAZAoICgEIEgMaACIKCQoCCAoSAxoAIgoICgEIEgMbADMKCQoCCAgSAxsAMwoICgEIEgMc
ADwKCQoCCAESAxwAPAoICgEIEgMdAC0KCQoCCCQSAx0ALQoICgEIEgMeADwKCQoCCCkSAx4A
PAoICgEIEgMfADsKCQoCCC0SAx8AOwowCgIEABIEIgB7ARokIEluZm9ybWF0aW9uIGFib3V0
IHVzZXJzJyBsaWNlbnNlcy4KCgoKAwQAARIDIggVCgsKAwQABxIEIwIoBAoNCgUEAAedCBIE
IwIoBAoxCgQEAAQAEgQrAkMDGiMgTGljZW5zZSBjb25maWcgc3RhdGUgZW51bWVyYXRpb24u
CgoMCgUEAAQAARIDKwcMCkIKBgQABAACABIDLQQaGjMgRGVmYXVsdCB2YWx1ZS4gVGhlIGxp
Y2Vuc2UgY29uZmlnIGRvZXMgbm90IGV4aXN0LgoKDgoHBAAEAAIAARIDLQQVCg4KBwQABAAC
AAISAy0YGQpACgYEAAQAAgESAzAEDxoxIFRoZSBsaWNlbnNlIGNvbmZpZyBpcyBlZmZlY3Rp
dmUgYW5kIGJlaW5nIHVzZWQuCgoOCgcEAAQAAgEBEgMwBAoKDgoHBAAEAAIBAhIDMA0OCjAK
BgQABAACAhIDMwQQGiEgVGhlIGxpY2Vuc2UgY29uZmlnIGhhcyBleHBpcmVkLgoKDgoHBAAE
AAICARIDMwQLCg4KBwQABAACAgISAzMODwpeCgYEAAQAAgMSAzcEFBpPIFRoZSBsaWNlbnNl
IGNvbmZpZyBoYXMgbm90IHN0YXJ0ZWQgeWV0LCBhbmQgaXRzIHN0YXJ0IGRhdGUgaXMgaW4g
dGhlCiBmdXR1cmUuCgoOCgcEAAQAAgMBEgM3BA8KDgoHBAAEAAIDAhIDNxITCpwBCgYEAAQA
AgQSAzwEEhqMASBUaGlzIGlzIHdoZW4gYSBzdWIgbGljZW5zZSBjb25maWcgaGFzIHJldHVy
bmVkIGFsbCBpdHMgc2VhdHMgYmFjayB0bwogQmlsbGluZ0FjY291bnRMaWNlbnNlQ29uZmln
IHRoYXQgaXQgYmVsb25ncyB0by4KIFNpbWlsYXIgdG8gRVhQSVJFRC4KCg4KBwQABAACBAES
AzwEDQoOCgcEAAQAAgQCEgM8EBEK+AEKBgQABAACBRIDQgQVGugBIFRoZSBsaWNlbnNlIGNv
bmZpZyBpcyBpbiBhIGdyYWNlIHBlcmlvZC4gSXRzIHN1YnNjcmlwdGlvbiBoYXMgZW5kZWQs
CiBlaXRoZXIgdGhyb3VnaCBlYXJseSB0ZXJtaW5hdGlvbiBvciBieSByZWFjaGluZyBpdHMg
ZW5kIGRhdGUsIGJ1dCB0aGUKIGN1c3RvbWVyIGtlZXBzIGFjY2VzcyBmb3IgYSBsaW1pdGVk
IHRpbWUuIEl0IGJlY29tZXMgRVhQSVJFRCB3aGVuIHRoZQogZ3JhY2UgcGVyaW9kIGVuZHMu
CgoOCgcEAAQAAgUBEgNCBBAKDgoHBAAEAAIFAhIDQhMUCrQBCgQEAAIAEgRIAksEGqUBIElt
bXV0YWJsZS4gSWRlbnRpZmllci4gVGhlIGZ1bGx5IHF1YWxpZmllZCByZXNvdXJjZSBuYW1l
IG9mIHRoZSBsaWNlbnNlCiBjb25maWcuIEZvcm1hdDoKIGBwcm9qZWN0cy97cHJvamVjdH0v
bG9jYXRpb25zL3tsb2NhdGlvbn0vbGljZW5zZUNvbmZpZ3Mve2xpY2Vuc2VfY29uZmlnfWAK
CgwKBQQAAgAFEgNIAggKDAoFBAACAAESA0gJDQoMCgUEAAIAAxIDSBARCg0KBQQAAgAIEgRI
EksDCg8KCAQAAgAInAgAEgNJBCsKDwoIBAACAAicCAESA0oELAo2CgQEAAIBEgNOAkMaKSBS
ZXF1aXJlZC4gTnVtYmVyIG9mIGxpY2Vuc2VzIHB1cmNoYXNlZC4KCgwKBQQAAgEFEgNOAgcK
DAoFBAACAQESA04IFQoMCgUEAAIBAxIDThgZCgwKBQQAAgEIEgNOGkIKDwoIBAACAQicCAAS
A04bQQpPCgQEAAICEgRRAlIvGkEgUmVxdWlyZWQuIFN1YnNjcmlwdGlvbiB0aWVyIGluZm9y
bWF0aW9uIGZvciB0aGUgbGljZW5zZSBjb25maWcuCgoMCgUEAAICBhIDUQISCgwKBQQAAgIB
EgNREyQKDAoFBAACAgMSA1EnKAoMCgUEAAICCBIDUgYuCg8KCAQAAgIInAgAEgNSBy0KPAoE
BAACAxIDVQI+Gi8gT3V0cHV0IG9ubHkuIFRoZSBzdGF0ZSBvZiB0aGUgbGljZW5zZSBjb25m
aWcuCgoMCgUEAAIDBhIDVQIHCgwKBQQAAgMBEgNVCA0KDAoFBAACAwMSA1UQEQoMCgUEAAID
CBIDVRI9Cg8KCAQAAgMInAgAEgNVEzwKaQoEBAACBBIDWQI/GlwgT3B0aW9uYWwuIFdoZXRo
ZXIgdGhlIGxpY2Vuc2UgY29uZmlnIHNob3VsZCBiZSBhdXRvIHJlbmV3ZWQgd2hlbiBpdCBy
ZWFjaGVzCiB0aGUgZW5kIGRhdGUuCgoMCgUEAAIEBRIDWQIGCgwKBQQAAgQBEgNZBxEKDAoF
BAACBAMSA1kUFQoMCgUEAAIECBIDWRY+Cg8KCAQAAgQInAgAEgNZFz0KKAoEBAACBRIDXAJL
GhsgUmVxdWlyZWQuIFRoZSBzdGFydCBkYXRlLgoKDAoFBAACBQYSA1wCEgoMCgUEAAIFARID
XBMdCgwKBQQAAgUDEgNcICEKDAoFBAACBQgSA1wiSgoPCggEAAIFCJwIABIDXCNJCi0KBAQA
AgYSA18CSRogIE9wdGlvbmFsLiBUaGUgcGxhbmVkIGVuZCBkYXRlLgoKDAoFBAACBgYSA18C
EgoMCgUEAAIGARIDXxMbCgwKBQQAAgYDEgNfHh8KDAoFBAACBggSA18gSAoPCggEAAIGCJwI
ABIDXyFHCiwKBAQAAgcSBGICYy8aHiBSZXF1aXJlZC4gU3Vic2NyaXB0aW9uIHRlcm0uCgoM
CgUEAAIHBhIDYgISCgwKBQQAAgcBEgNiEyQKDAoFBAACBwMSA2InKAoMCgUEAAIHCBIDYwYu
Cg8KCAQAAgcInAgAEgNjBy0KRgoEBAACCBIDZgI/GjkgT3B0aW9uYWwuIFdoZXRoZXIgdGhl
IGxpY2Vuc2UgY29uZmlnIGlzIGZvciBmcmVlIHRyaWFsLgoKDAoFBAACCAUSA2YCBgoMCgUE
AAIIARIDZgcRCgwKBQQAAggDEgNmFBUKDAoFBAACCAgSA2YWPgoPCggEAAIICJwIABIDZhc9
CkwKBAQAAgkSA2kCRho/IE91dHB1dCBvbmx5LiBXaGV0aGVyIHRoZSBsaWNlbnNlIGNvbmZp
ZyBpcyBmb3IgR2VtaW5pIGJ1bmRsZS4KCgwKBQQAAgkFEgNpAgYKDAoFBAACCQESA2kHFAoM
CgUEAAIJAxIDaRcZCgwKBQQAAgkIEgNpGkUKDwoIBAACCQicCAASA2kbRApzCgQEAAIKEgNt
AkkaZiBPdXRwdXQgb25seS4gSW5kaWNhdGlvbiBvZiB3aGV0aGVyIHRoZSBzdWJzY3JpcHRp
b24gaXMgdGVybWluYXRlZCBlYXJsaWVyCiB0aGFuIHRoZSBleHBpcmF0aW9uIGRhdGUuCgoM
CgUEAAIKBRIDbQIGCgwKBQQAAgoBEgNtBxcKDAoFBAACCgMSA20aHAoMCgUEAAIKCBIDbR1I
Cg8KCAQAAgoInAgAEgNtHkcKbAoEBAACCxIEcQJyMhpeIE91dHB1dCBvbmx5LiBUaGUgZGF0
ZSB3aGVuIHRoZSBzdWJzY3JpcHRpb24gaXMgdGVybWluYXRlZCBlYXJsaWVyIHRoYW4gdGhl
CiBleHBpcmF0aW9uIGRhdGUuCgoMCgUEAAILBhIDcQISCgwKBQQAAgsBEgNxEykKDAoFBAAC
CwMSA3EsLgoMCgUEAAILCBIDcgYxCg8KCAQAAgsInAgAEgNyBzAK0QIKBAQAAgwSBHkCei8a
wgIgT3B0aW9uYWwuIFRpbWVzdGFtcCBvZiB0aGUgbW9zdCByZWNlbnQgdXNlci1pbml0aWF0
ZWQgdXBkYXRlIChzZWF0IGNvdW50CiBjaGFuZ2Ugb3Igc3Vic2NyaXB0aW9uIHRlcm0gY2hh
bmdlKS4gVW5saWtlIGB1cGRhdGVfdGltZWAsIHRoaXMgZmllbGQgaXMKIG9ubHkgc3RhbXBl
ZCB3aGVuIGEgY3VzdG9tZXIgZXhwbGljaXRseSB1cGRhdGVzIHRoZSBsaWNlbnNlIChlLmcu
IHZpYSB0aGUKIFVJKSwgYW5kIGlzIG5vdCB0b3VjaGVkIGJ5IHN5c3RlbS1kcml2ZW4gd3Jp
dGVzIChzdWJzY3JpcHRpb24gcGlwZWxpbmUsCiBCQUxDIHByb3BhZ2F0aW9uLCBldGMuKS4K
CgwKBQQAAgwGEgN5AhsKDAoFBAACDAESA3kcMQoMCgUEAAIMAxIDeTQ2CgwKBQQAAgwIEgN6
Bi4KDwoIBAACDAicCAASA3oHLWIGcHJvdG8z
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Discoveryengine::V1::LicenseConfig::LicenseConfig ===
    # Fields for LicenseConfig
    # Field: name Type: 9 ()
    # Field: license_count Type: 3 ()
    # Field: subscription_tier Type: 14 (.google.cloud.discoveryengine.v1.SubscriptionTier)
    # Field: state Type: 14 (.google.cloud.discoveryengine.v1.LicenseConfig.State)
    # Field: auto_renew Type: 8 ()
    # Field: start_date Type: 11 (.google.type.Date)
    # Field: end_date Type: 11 (.google.type.Date)
    # Field: subscription_term Type: 14 (.google.cloud.discoveryengine.v1.SubscriptionTerm)
    # Field: free_trial Type: 8 ()
    # Field: gemini_bundle Type: 8 ()
    # Field: early_terminated Type: 8 ()
    # Field: early_termination_date Type: 11 (.google.type.Date)
    # Field: last_user_update_time Type: 11 (.google.protobuf.Timestamp)

# Enum: LicenseConfig::State
our $LicenseConfig_STATE_UNSPECIFIED = 0;
our $LicenseConfig_ACTIVE = 1;
our $LicenseConfig_EXPIRED = 2;
our $LicenseConfig_NOT_STARTED = 3;
our $LicenseConfig_WITHDRAWN = 4;
our $LicenseConfig_DEACTIVATING = 5;

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Discoveryengine::V1::LicenseConfig - Compiled Protocol Buffers messages for google/cloud/discoveryengine/v1/license_config.proto

=head1 SYNOPSIS

    use Google::Cloud::Discoveryengine::V1::LicenseConfig;

    my $msg = Google::Cloud::Discoveryengine::V1::LicenseConfig::LicenseConfig->new({
        name => $name,
        license_count => $license_count,
        subscription_tier => $subscription_tier,
        state => $state,
    });

    # Read or update a field
    my $val = $msg->name();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Discoveryengine::V1::LicenseConfig::LicenseConfig->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/discoveryengine/v1/license_config.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Discoveryengine::V1::LicenseConfig::LicenseConfig

Information about users' licenses.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Immutable. Identifier. The fully qualified resource name of the license
config. Format:
`projects/{project}/locations/{location}/licenseConfigs/{license_config}`

=item * C<< $msg->license_count() >> / C<< $msg->license_count($value) >>

Type: C<Int64>

Required. Number of licenses purchased.

=item * C<< $msg->subscription_tier() >> / C<< $msg->subscription_tier($value) >>

Type: C<Enum> (L<Google::Cloud::Discoveryengine::V1::SubscriptionTier>)

Required. Subscription tier information for the license config.

=item * C<< $msg->state() >> / C<< $msg->state($value) >>

Type: C<Enum> (L<Google::Cloud::Discoveryengine::V1::LicenseConfig::State>)

Output only. The state of the license config.

=item * C<< $msg->auto_renew() >> / C<< $msg->auto_renew($value) >>

Type: C<Bool>

Optional. Whether the license config should be auto renewed when it reaches
the end date.

=item * C<< $msg->start_date() >> / C<< $msg->start_date($value) >>

Type: C<Message> (L<Google::Type::Date::Date>)

Required. The start date.

=item * C<< $msg->end_date() >> / C<< $msg->end_date($value) >>

Type: C<Message> (L<Google::Type::Date::Date>)

Optional. The planed end date.

=item * C<< $msg->subscription_term() >> / C<< $msg->subscription_term($value) >>

Type: C<Enum> (L<Google::Cloud::Discoveryengine::V1::SubscriptionTerm>)

Required. Subscription term.

=item * C<< $msg->free_trial() >> / C<< $msg->free_trial($value) >>

Type: C<Bool>

Optional. Whether the license config is for free trial.

=item * C<< $msg->gemini_bundle() >> / C<< $msg->gemini_bundle($value) >>

Type: C<Bool>

Output only. Whether the license config is for Gemini bundle.

=item * C<< $msg->early_terminated() >> / C<< $msg->early_terminated($value) >>

Type: C<Bool>

Output only. Indication of whether the subscription is terminated earlier
than the expiration date.

=item * C<< $msg->early_termination_date() >> / C<< $msg->early_termination_date($value) >>

Type: C<Message> (L<Google::Type::Date::Date>)

Output only. The date when the subscription is terminated earlier than the
expiration date.

=item * C<< $msg->last_user_update_time() >> / C<< $msg->last_user_update_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Optional. Timestamp of the most recent user-initiated update (seat count
change or subscription term change). Unlike `update_time`, this field is
only stamped when a customer explicitly updates the license (e.g. via the
UI), and is not touched by system-driven writes (subscription pipeline,
BALC propagation, etc.).

=back

=head3 Enum: LicenseConfig::State

=over 4

=item * C<STATE_UNSPECIFIED> => C<0>

=item * C<ACTIVE> => C<1>

=item * C<EXPIRED> => C<2>

=item * C<NOT_STARTED> => C<3>

=item * C<WITHDRAWN> => C<4>

=item * C<DEACTIVATING> => C<5>

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Discoveryengine::V1::LicenseConfig::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
