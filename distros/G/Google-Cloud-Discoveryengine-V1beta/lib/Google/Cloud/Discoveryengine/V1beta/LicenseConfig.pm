package Google::Cloud::Discoveryengine::V1beta::LicenseConfig;

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
    eval { require Google::Cloud::Discoveryengine::V1beta::Common };
    eval { require Google::Type::Date };
    my $descriptor_b64 = <<'EOF';
Cjhnb29nbGUvY2xvdWQvZGlzY292ZXJ5ZW5naW5lL3YxYmV0YS9saWNlbnNlX2NvbmZpZy5w
cm90bxIjZ29vZ2xlLmNsb3VkLmRpc2NvdmVyeWVuZ2luZS52MWJldGEaH2dvb2dsZS9hcGkv
ZmllbGRfYmVoYXZpb3IucHJvdG8aGWdvb2dsZS9hcGkvcmVzb3VyY2UucHJvdG8aMGdvb2ds
ZS9jbG91ZC9kaXNjb3ZlcnllbmdpbmUvdjFiZXRhL2NvbW1vbi5wcm90bxoWZ29vZ2xlL3R5
cGUvZGF0ZS5wcm90byLeBwoNTGljZW5zZUNvbmZpZxIaCgRuYW1lGAEgASgJQgbgQQXgQQhS
BG5hbWUSKAoNbGljZW5zZV9jb3VudBgCIAEoA0ID4EECUgxsaWNlbnNlQ291bnQSZwoRc3Vi
c2NyaXB0aW9uX3RpZXIYAyABKA4yNS5nb29nbGUuY2xvdWQuZGlzY292ZXJ5ZW5naW5lLnYx
YmV0YS5TdWJzY3JpcHRpb25UaWVyQgPgQQJSEHN1YnNjcmlwdGlvblRpZXISUwoFc3RhdGUY
BCABKA4yOC5nb29nbGUuY2xvdWQuZGlzY292ZXJ5ZW5naW5lLnYxYmV0YS5MaWNlbnNlQ29u
ZmlnLlN0YXRlQgPgQQNSBXN0YXRlEiIKCmF1dG9fcmVuZXcYBSABKAhCA+BBAVIJYXV0b1Jl
bmV3EjUKCnN0YXJ0X2RhdGUYBiABKAsyES5nb29nbGUudHlwZS5EYXRlQgPgQQJSCXN0YXJ0
RGF0ZRIxCghlbmRfZGF0ZRgHIAEoCzIRLmdvb2dsZS50eXBlLkRhdGVCA+BBAVIHZW5kRGF0
ZRJnChFzdWJzY3JpcHRpb25fdGVybRgIIAEoDjI1Lmdvb2dsZS5jbG91ZC5kaXNjb3Zlcnll
bmdpbmUudjFiZXRhLlN1YnNjcmlwdGlvblRlcm1CA+BBAlIQc3Vic2NyaXB0aW9uVGVybRIi
CgpmcmVlX3RyaWFsGAkgASgIQgPgQQFSCWZyZWVUcmlhbBIoCg1nZW1pbmlfYnVuZGxlGAsg
ASgIQgPgQQNSDGdlbWluaUJ1bmRsZRIuChBlYXJseV90ZXJtaW5hdGVkGAwgASgIQgPgQQNS
D2Vhcmx5VGVybWluYXRlZBJMChZlYXJseV90ZXJtaW5hdGlvbl9kYXRlGA0gASgLMhEuZ29v
Z2xlLnR5cGUuRGF0ZUID4EEDUhRlYXJseVRlcm1pbmF0aW9uRGF0ZSJpCgVTdGF0ZRIVChFT
VEFURV9VTlNQRUNJRklFRBAAEgoKBkFDVElWRRABEgsKB0VYUElSRUQQAhIPCgtOT1RfU1RB
UlRFRBADEg0KCVdJVEhEUkFXThAEEhAKDERFQUNUSVZBVElORxAFOpoB6kGWAQosZGlzY292
ZXJ5ZW5naW5lLmdvb2dsZWFwaXMuY29tL0xpY2Vuc2VDb25maWcSR3Byb2plY3RzL3twcm9q
ZWN0fS9sb2NhdGlvbnMve2xvY2F0aW9ufS9saWNlbnNlQ29uZmlncy97bGljZW5zZV9jb25m
aWd9Kg5saWNlbnNlQ29uZmlnczINbGljZW5zZUNvbmZpZ0KZAgonY29tLmdvb2dsZS5jbG91
ZC5kaXNjb3ZlcnllbmdpbmUudjFiZXRhQhJMaWNlbnNlQ29uZmlnUHJvdG9QAVpRY2xvdWQu
Z29vZ2xlLmNvbS9nby9kaXNjb3ZlcnllbmdpbmUvYXBpdjFiZXRhL2Rpc2NvdmVyeWVuZ2lu
ZXBiO2Rpc2NvdmVyeWVuZ2luZXBiogIPRElTQ09WRVJZRU5HSU5FqgIjR29vZ2xlLkNsb3Vk
LkRpc2NvdmVyeUVuZ2luZS5WMUJldGHKAiNHb29nbGVcQ2xvdWRcRGlzY292ZXJ5RW5naW5l
XFYxYmV0YeoCJkdvb2dsZTo6Q2xvdWQ6OkRpc2NvdmVyeUVuZ2luZTo6VjFiZXRhSqQeCgYS
BA4AcwEKvAQKAQwSAw4AEjKxBCBDb3B5cmlnaHQgMjAyNiBHb29nbGUgTExDCgogTGljZW5z
ZWQgdW5kZXIgdGhlIEFwYWNoZSBMaWNlbnNlLCBWZXJzaW9uIDIuMCAodGhlICJMaWNlbnNl
Iik7CiB5b3UgbWF5IG5vdCB1c2UgdGhpcyBmaWxlIGV4Y2VwdCBpbiBjb21wbGlhbmNlIHdp
dGggdGhlIExpY2Vuc2UuCiBZb3UgbWF5IG9idGFpbiBhIGNvcHkgb2YgdGhlIExpY2Vuc2Ug
YXQKCiAgICAgaHR0cDovL3d3dy5hcGFjaGUub3JnL2xpY2Vuc2VzL0xJQ0VOU0UtMi4wCgog
VW5sZXNzIHJlcXVpcmVkIGJ5IGFwcGxpY2FibGUgbGF3IG9yIGFncmVlZCB0byBpbiB3cml0
aW5nLCBzb2Z0d2FyZQogZGlzdHJpYnV0ZWQgdW5kZXIgdGhlIExpY2Vuc2UgaXMgZGlzdHJp
YnV0ZWQgb24gYW4gIkFTIElTIiBCQVNJUywKIFdJVEhPVVQgV0FSUkFOVElFUyBPUiBDT05E
SVRJT05TIE9GIEFOWSBLSU5ELCBlaXRoZXIgZXhwcmVzcyBvciBpbXBsaWVkLgogU2VlIHRo
ZSBMaWNlbnNlIGZvciB0aGUgc3BlY2lmaWMgbGFuZ3VhZ2UgZ292ZXJuaW5nIHBlcm1pc3Np
b25zIGFuZAogbGltaXRhdGlvbnMgdW5kZXIgdGhlIExpY2Vuc2UuCgoICgECEgMQACwKCQoC
AwASAxIAKQoJCgIDARIDEwAjCgkKAgMCEgMUADoKCQoCAwMSAxUAIAoICgEIEgMXAEAKCQoC
CCUSAxcAQAoICgEIEgMYAGgKCQoCCAsSAxgAaAoICgEIEgMZACIKCQoCCAoSAxkAIgoICgEI
EgMaADMKCQoCCAgSAxoAMwoICgEIEgMbAEAKCQoCCAESAxsAQAoICgEIEgMcAC0KCQoCCCQS
AxwALQoICgEIEgMdAEAKCQoCCCkSAx0AQAoICgEIEgMeAD8KCQoCCC0SAx4APwowCgIEABIE
IQBzARokIEluZm9ybWF0aW9uIGFib3V0IHVzZXJzJyBsaWNlbnNlcy4KCgoKAwQAARIDIQgV
CgsKAwQABxIEIgInBAoNCgUEAAedCBIEIgInBAoxCgQEAAQAEgQqAkIDGiMgTGljZW5zZSBj
b25maWcgc3RhdGUgZW51bWVyYXRpb24uCgoMCgUEAAQAARIDKgcMCkIKBgQABAACABIDLAQa
GjMgRGVmYXVsdCB2YWx1ZS4gVGhlIGxpY2Vuc2UgY29uZmlnIGRvZXMgbm90IGV4aXN0LgoK
DgoHBAAEAAIAARIDLAQVCg4KBwQABAACAAISAywYGQpACgYEAAQAAgESAy8EDxoxIFRoZSBs
aWNlbnNlIGNvbmZpZyBpcyBlZmZlY3RpdmUgYW5kIGJlaW5nIHVzZWQuCgoOCgcEAAQAAgEB
EgMvBAoKDgoHBAAEAAIBAhIDLw0OCjAKBgQABAACAhIDMgQQGiEgVGhlIGxpY2Vuc2UgY29u
ZmlnIGhhcyBleHBpcmVkLgoKDgoHBAAEAAICARIDMgQLCg4KBwQABAACAgISAzIODwpeCgYE
AAQAAgMSAzYEFBpPIFRoZSBsaWNlbnNlIGNvbmZpZyBoYXMgbm90IHN0YXJ0ZWQgeWV0LCBh
bmQgaXRzIHN0YXJ0IGRhdGUgaXMgaW4gdGhlCiBmdXR1cmUuCgoOCgcEAAQAAgMBEgM2BA8K
DgoHBAAEAAIDAhIDNhITCpwBCgYEAAQAAgQSAzsEEhqMASBUaGlzIGlzIHdoZW4gYSBzdWIg
bGljZW5zZSBjb25maWcgaGFzIHJldHVybmVkIGFsbCBpdHMgc2VhdHMgYmFjayB0bwogQmls
bGluZ0FjY291bnRMaWNlbnNlQ29uZmlnIHRoYXQgaXQgYmVsb25ncyB0by4KIFNpbWlsYXIg
dG8gRVhQSVJFRC4KCg4KBwQABAACBAESAzsEDQoOCgcEAAQAAgQCEgM7EBEKpgIKBgQABAAC
BRIDQQQVGpYCIFRoZSBsaWNlbnNlIGNvbmZpZyBpcyB0ZXJtaW5hdGVkIGVhcmxpZXIgdGhh
biB0aGUgZXhwaXJhdGlvbiBkYXRlIGFuZCBpdAogaXMgZGVhY3RpdmF0aW5nLiBUaGUgY3Vz
dG9tZXIgd2lsbCBzdGlsbCBoYXZlIGFjY2VzcyBpbiB0aGlzIHN0YXRlLiBJdAogd2lsbCBi
ZSBjb252ZXJ0ZWQgdG8gRVhQSVJFRCBhZnRlciB0aGUgZGVhY3RpdmF0aW5nIHBlcmlvZCBl
bmRzICgxNCBkYXlzKQogb3Igd2hlbiB0aGUgZW5kIGRhdGUgaXMgcmVhY2hlZCwgd2hpY2hl
dmVyIGNvbWVzIGZpcnN0LgoKDgoHBAAEAAIFARIDQQQQCg4KBwQABAACBQISA0ETFAq0AQoE
BAACABIERwJKBBqlASBJbW11dGFibGUuIElkZW50aWZpZXIuIFRoZSBmdWxseSBxdWFsaWZp
ZWQgcmVzb3VyY2UgbmFtZSBvZiB0aGUgbGljZW5zZQogY29uZmlnLiBGb3JtYXQ6CiBgcHJv
amVjdHMve3Byb2plY3R9L2xvY2F0aW9ucy97bG9jYXRpb259L2xpY2Vuc2VDb25maWdzL3ts
aWNlbnNlX2NvbmZpZ31gCgoMCgUEAAIABRIDRwIICgwKBQQAAgABEgNHCQ0KDAoFBAACAAMS
A0cQEQoNCgUEAAIACBIERxJKAwoPCggEAAIACJwIABIDSAQrCg8KCAQAAgAInAgBEgNJBCwK
NgoEBAACARIDTQJDGikgUmVxdWlyZWQuIE51bWJlciBvZiBsaWNlbnNlcyBwdXJjaGFzZWQu
CgoMCgUEAAIBBRIDTQIHCgwKBQQAAgEBEgNNCBUKDAoFBAACAQMSA00YGQoMCgUEAAIBCBID
TRpCCg8KCAQAAgEInAgAEgNNG0EKTwoEBAACAhIEUAJRLxpBIFJlcXVpcmVkLiBTdWJzY3Jp
cHRpb24gdGllciBpbmZvcm1hdGlvbiBmb3IgdGhlIGxpY2Vuc2UgY29uZmlnLgoKDAoFBAAC
AgYSA1ACEgoMCgUEAAICARIDUBMkCgwKBQQAAgIDEgNQJygKDAoFBAACAggSA1EGLgoPCggE
AAICCJwIABIDUQctCjwKBAQAAgMSA1QCPhovIE91dHB1dCBvbmx5LiBUaGUgc3RhdGUgb2Yg
dGhlIGxpY2Vuc2UgY29uZmlnLgoKDAoFBAACAwYSA1QCBwoMCgUEAAIDARIDVAgNCgwKBQQA
AgMDEgNUEBEKDAoFBAACAwgSA1QSPQoPCggEAAIDCJwIABIDVBM8CmkKBAQAAgQSA1gCPxpc
IE9wdGlvbmFsLiBXaGV0aGVyIHRoZSBsaWNlbnNlIGNvbmZpZyBzaG91bGQgYmUgYXV0byBy
ZW5ld2VkIHdoZW4gaXQgcmVhY2hlcwogdGhlIGVuZCBkYXRlLgoKDAoFBAACBAUSA1gCBgoM
CgUEAAIEARIDWAcRCgwKBQQAAgQDEgNYFBUKDAoFBAACBAgSA1gWPgoPCggEAAIECJwIABID
WBc9CigKBAQAAgUSA1sCSxobIFJlcXVpcmVkLiBUaGUgc3RhcnQgZGF0ZS4KCgwKBQQAAgUG
EgNbAhIKDAoFBAACBQESA1sTHQoMCgUEAAIFAxIDWyAhCgwKBQQAAgUIEgNbIkoKDwoIBAAC
BQicCAASA1sjSQotCgQEAAIGEgNeAkkaICBPcHRpb25hbC4gVGhlIHBsYW5lZCBlbmQgZGF0
ZS4KCgwKBQQAAgYGEgNeAhIKDAoFBAACBgESA14TGwoMCgUEAAIGAxIDXh4fCgwKBQQAAgYI
EgNeIEgKDwoIBAACBgicCAASA14hRwosCgQEAAIHEgRhAmIvGh4gUmVxdWlyZWQuIFN1YnNj
cmlwdGlvbiB0ZXJtLgoKDAoFBAACBwYSA2ECEgoMCgUEAAIHARIDYRMkCgwKBQQAAgcDEgNh
JygKDAoFBAACBwgSA2IGLgoPCggEAAIHCJwIABIDYgctCkYKBAQAAggSA2UCPxo5IE9wdGlv
bmFsLiBXaGV0aGVyIHRoZSBsaWNlbnNlIGNvbmZpZyBpcyBmb3IgZnJlZSB0cmlhbC4KCgwK
BQQAAggFEgNlAgYKDAoFBAACCAESA2UHEQoMCgUEAAIIAxIDZRQVCgwKBQQAAggIEgNlFj4K
DwoIBAACCAicCAASA2UXPQpMCgQEAAIJEgNoAkYaPyBPdXRwdXQgb25seS4gV2hldGhlciB0
aGUgbGljZW5zZSBjb25maWcgaXMgZm9yIEdlbWluaSBidW5kbGUuCgoMCgUEAAIJBRIDaAIG
CgwKBQQAAgkBEgNoBxQKDAoFBAACCQMSA2gXGQoMCgUEAAIJCBIDaBpFCg8KCAQAAgkInAgA
EgNoG0QKzwEKBAQAAgoSA20CSRrBASBPdXRwdXQgb25seS4gSW5kaWNhdGlvbiBvZiB3aGV0
aGVyIHRoZSBzdWJzY3JpcHRpb24gaXMgdGVybWluYXRlZCBlYXJsaWVyCiB0aGFuIHRoZSBl
eHBpcmF0aW9uIGRhdGUuIFRoaXMgaXMgdXN1YWxseSB0ZXJtaW5hdGVkIGJ5IHBpcGVsaW5l
IG9uY2UgdGhlCiBzdWJzY3JpcHRpb24gZ2V0cyB0ZXJtaW5hdGVkIGZyb20gc3Vic3YzLgoK
DAoFBAACCgUSA20CBgoMCgUEAAIKARIDbQcXCgwKBQQAAgoDEgNtGhwKDAoFBAACCggSA20d
SAoPCggEAAIKCJwIABIDbR5HCmwKBAQAAgsSBHECcjIaXiBPdXRwdXQgb25seS4gVGhlIGRh
dGUgd2hlbiB0aGUgc3Vic2NyaXB0aW9uIGlzIHRlcm1pbmF0ZWQgZWFybGllciB0aGFuIHRo
ZQogZXhwaXJhdGlvbiBkYXRlLgoKDAoFBAACCwYSA3ECEgoMCgUEAAILARIDcRMpCgwKBQQA
AgsDEgNxLC4KDAoFBAACCwgSA3IGMQoPCggEAAILCJwIABIDcgcwYgZwcm90bzM=
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Discoveryengine::V1beta::LicenseConfig::LicenseConfig ===
    # Fields for LicenseConfig
    # Field: name Type: 9 ()
    # Field: license_count Type: 3 ()
    # Field: subscription_tier Type: 14 (.google.cloud.discoveryengine.v1beta.SubscriptionTier)
    # Field: state Type: 14 (.google.cloud.discoveryengine.v1beta.LicenseConfig.State)
    # Field: auto_renew Type: 8 ()
    # Field: start_date Type: 11 (.google.type.Date)
    # Field: end_date Type: 11 (.google.type.Date)
    # Field: subscription_term Type: 14 (.google.cloud.discoveryengine.v1beta.SubscriptionTerm)
    # Field: free_trial Type: 8 ()
    # Field: gemini_bundle Type: 8 ()
    # Field: early_terminated Type: 8 ()
    # Field: early_termination_date Type: 11 (.google.type.Date)

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

Google::Cloud::Discoveryengine::V1beta::LicenseConfig - Compiled Protocol Buffers messages for google/cloud/discoveryengine/v1beta/license_config.proto

=head1 SYNOPSIS

    use Google::Cloud::Discoveryengine::V1beta::LicenseConfig;

    my $msg = Google::Cloud::Discoveryengine::V1beta::LicenseConfig::LicenseConfig->new({
        name => $name,
        license_count => $license_count,
        subscription_tier => $subscription_tier,
        state => $state,
    });

    # Read or update a field
    my $val = $msg->name();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Discoveryengine::V1beta::LicenseConfig::LicenseConfig->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/discoveryengine/v1beta/license_config.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Discoveryengine::V1beta::LicenseConfig::LicenseConfig

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

Type: C<Enum> (L<Google::Cloud::Discoveryengine::V1beta::SubscriptionTier>)

Required. Subscription tier information for the license config.

=item * C<< $msg->state() >> / C<< $msg->state($value) >>

Type: C<Enum> (L<Google::Cloud::Discoveryengine::V1beta::LicenseConfig::State>)

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

Type: C<Enum> (L<Google::Cloud::Discoveryengine::V1beta::SubscriptionTerm>)

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
than the expiration date. This is usually terminated by pipeline once the
subscription gets terminated from subsv3.

=item * C<< $msg->early_termination_date() >> / C<< $msg->early_termination_date($value) >>

Type: C<Message> (L<Google::Type::Date::Date>)

Output only. The date when the subscription is terminated earlier than the
expiration date.

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

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Discoveryengine::V1beta::LicenseConfig::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
