package Google::Cloud::Discoveryengine::V1beta::UserLicense;

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
CjZnb29nbGUvY2xvdWQvZGlzY292ZXJ5ZW5naW5lL3YxYmV0YS91c2VyX2xpY2Vuc2UucHJv
dG8SI2dvb2dsZS5jbG91ZC5kaXNjb3ZlcnllbmdpbmUudjFiZXRhGh9nb29nbGUvYXBpL2Zp
ZWxkX2JlaGF2aW9yLnByb3RvGhlnb29nbGUvYXBpL3Jlc291cmNlLnByb3RvGh9nb29nbGUv
cHJvdG9idWYvdGltZXN0YW1wLnByb3RvIrcFCgtVc2VyTGljZW5zZRItCg51c2VyX3ByaW5j
aXBhbBgBIAEoCUIG4EEF4EECUg11c2VyUHJpbmNpcGFsEiYKDHVzZXJfcHJvZmlsZRgDIAEo
CUID4EEBUgt1c2VyUHJvZmlsZRKGAQoYbGljZW5zZV9hc3NpZ25tZW50X3N0YXRlGAQgASgO
MkcuZ29vZ2xlLmNsb3VkLmRpc2NvdmVyeWVuZ2luZS52MWJldGEuVXNlckxpY2Vuc2UuTGlj
ZW5zZUFzc2lnbm1lbnRTdGF0ZUID4EEDUhZsaWNlbnNlQXNzaWdubWVudFN0YXRlElsKDmxp
Y2Vuc2VfY29uZmlnGAUgASgJQjTgQQH6QS4KLGRpc2NvdmVyeWVuZ2luZS5nb29nbGVhcGlz
LmNvbS9MaWNlbnNlQ29uZmlnUg1saWNlbnNlQ29uZmlnEkAKC2NyZWF0ZV90aW1lGAYgASgL
MhouZ29vZ2xlLnByb3RvYnVmLlRpbWVzdGFtcEID4EEDUgpjcmVhdGVUaW1lEkAKC3VwZGF0
ZV90aW1lGAcgASgLMhouZ29vZ2xlLnByb3RvYnVmLlRpbWVzdGFtcEID4EEDUgp1cGRhdGVU
aW1lEkcKD2xhc3RfbG9naW5fdGltZRgIIAEoCzIaLmdvb2dsZS5wcm90b2J1Zi5UaW1lc3Rh
bXBCA+BBA1INbGFzdExvZ2luVGltZSKdAQoWTGljZW5zZUFzc2lnbm1lbnRTdGF0ZRIoCiRM
SUNFTlNFX0FTU0lHTk1FTlRfU1RBVEVfVU5TUEVDSUZJRUQQABIMCghBU1NJR05FRBABEg4K
ClVOQVNTSUdORUQQAhIOCgpOT19MSUNFTlNFEAMSHgoaTk9fTElDRU5TRV9BVFRFTVBURURf
TE9HSU4QBBILCgdCTE9DS0VEEAUieAoXTGljZW5zZUNvbmZpZ1VzYWdlU3RhdHMSKgoObGlj
ZW5zZV9jb25maWcYASABKAlCA+BBAlINbGljZW5zZUNvbmZpZxIxChJ1c2VkX2xpY2Vuc2Vf
Y291bnQYAiABKANCA+BBAlIQdXNlZExpY2Vuc2VDb3VudEKXAgonY29tLmdvb2dsZS5jbG91
ZC5kaXNjb3ZlcnllbmdpbmUudjFiZXRhQhBVc2VyTGljZW5zZVByb3RvUAFaUWNsb3VkLmdv
b2dsZS5jb20vZ28vZGlzY292ZXJ5ZW5naW5lL2FwaXYxYmV0YS9kaXNjb3ZlcnllbmdpbmVw
YjtkaXNjb3ZlcnllbmdpbmVwYqICD0RJU0NPVkVSWUVOR0lORaoCI0dvb2dsZS5DbG91ZC5E
aXNjb3ZlcnlFbmdpbmUuVjFCZXRhygIjR29vZ2xlXENsb3VkXERpc2NvdmVyeUVuZ2luZVxW
MWJldGHqAiZHb29nbGU6OkNsb3VkOjpEaXNjb3ZlcnlFbmdpbmU6OlYxYmV0YUq1GwoGEgQO
AG0BCrwECgEMEgMOABIysQQgQ29weXJpZ2h0IDIwMjYgR29vZ2xlIExMQwoKIExpY2Vuc2Vk
IHVuZGVyIHRoZSBBcGFjaGUgTGljZW5zZSwgVmVyc2lvbiAyLjAgKHRoZSAiTGljZW5zZSIp
OwogeW91IG1heSBub3QgdXNlIHRoaXMgZmlsZSBleGNlcHQgaW4gY29tcGxpYW5jZSB3aXRo
IHRoZSBMaWNlbnNlLgogWW91IG1heSBvYnRhaW4gYSBjb3B5IG9mIHRoZSBMaWNlbnNlIGF0
CgogICAgIGh0dHA6Ly93d3cuYXBhY2hlLm9yZy9saWNlbnNlcy9MSUNFTlNFLTIuMAoKIFVu
bGVzcyByZXF1aXJlZCBieSBhcHBsaWNhYmxlIGxhdyBvciBhZ3JlZWQgdG8gaW4gd3JpdGlu
Zywgc29mdHdhcmUKIGRpc3RyaWJ1dGVkIHVuZGVyIHRoZSBMaWNlbnNlIGlzIGRpc3RyaWJ1
dGVkIG9uIGFuICJBUyBJUyIgQkFTSVMsCiBXSVRIT1VUIFdBUlJBTlRJRVMgT1IgQ09ORElU
SU9OUyBPRiBBTlkgS0lORCwgZWl0aGVyIGV4cHJlc3Mgb3IgaW1wbGllZC4KIFNlZSB0aGUg
TGljZW5zZSBmb3IgdGhlIHNwZWNpZmljIGxhbmd1YWdlIGdvdmVybmluZyBwZXJtaXNzaW9u
cyBhbmQKIGxpbWl0YXRpb25zIHVuZGVyIHRoZSBMaWNlbnNlLgoKCAoBAhIDEAAsCgkKAgMA
EgMSACkKCQoCAwESAxMAIwoJCgIDAhIDFAApCggKAQgSAxYAQAoJCgIIJRIDFgBACggKAQgS
AxcAaAoJCgIICxIDFwBoCggKAQgSAxgAIgoJCgIIChIDGAAiCggKAQgSAxkAMQoJCgIICBID
GQAxCggKAQgSAxoAQAoJCgIIARIDGgBACggKAQgSAxsALQoJCgIIJBIDGwAtCggKAQgSAxwA
QAoJCgIIKRIDHABACggKAQgSAx0APwoJCgIILRIDHQA/Cj0KAgQAEgQgAGQBGjEgVXNlciBM
aWNlbnNlIGluZm9ybWF0aW9uIGFzc2lnbmVkIGJ5IHRoZSBhZG1pbi4KCgoKAwQAARIDIAgT
CjUKBAQABAASBCICOQMaJyBMaWNlbnNlIGFzc2lnbm1lbnQgc3RhdGUgZW51bWVyYXRpb24u
CgoMCgUEAAQAARIDIgcdCh8KBgQABAACABIDJAQtGhAgRGVmYXVsdCB2YWx1ZS4KCg4KBwQA
BAACAAESAyQEKAoOCgcEAAQAAgACEgMkKywKLgoGBAAEAAIBEgMnBBEaHyBMaWNlbnNlIGFz
c2lnbmVkIHRvIHRoZSB1c2VyLgoKDgoHBAAEAAIBARIDJwQMCg4KBwQABAACAQISAycPEApY
CgYEAAQAAgISAysEExpJIE5vIGxpY2Vuc2UgYXNzaWduZWQgdG8gdGhlIHVzZXIuCiBEZXBy
ZWNhdGVkLCB0cmFuc2xhdGVkIHRvIE5PX0xJQ0VOU0UuCgoOCgcEAAQAAgIBEgMrBA4KDgoH
BAAEAAICAhIDKxESCjEKBgQABAACAxIDLgQTGiIgTm8gbGljZW5zZSBhc3NpZ25lZCB0byB0
aGUgdXNlci4KCg4KBwQABAACAwESAy4EDgoOCgcEAAQAAgMCEgMuERIKsQIKBgQABAACBBID
NQQjGqECIFVzZXIgYXR0ZW1wdGVkIHRvIGxvZ2luIGJ1dCBubyBsaWNlbnNlIGFzc2lnbmVk
IHRvIHRoZSB1c2VyLgogVGhpcyBzdGF0ZSBpcyBvbmx5IHVzZWQgZm9yIG5vIHVzZXIgZmly
c3QgdGltZSBsb2dpbiBhdHRlbXB0IGJ1dCBjYW5ub3QKIGdldCBsaWNlbnNlIGFzc2lnbmVk
LgogVXNlcnMgYWxyZWFkeSBsb2dnZWQgaW4gYnV0IGNhbm5vdCBnZXQgbGljZW5zZSBhc3Np
Z25lZCB3aWxsIGJlIGFzc2lnbmVkCiBOT19MSUNFTlNFIHN0YXRlKExpY2Vuc2UgY291bGQg
YmUgdW5hc3NpZ25lZCBieSBhZG1pbikuCgoOCgcEAAQAAgQBEgM1BB4KDgoHBAAEAAIEAhID
NSEiCjoKBgQABAACBRIDOAQQGisgVXNlciBpcyBibG9ja2VkIGZyb20gYXNzaWduaW5nIGEg
bGljZW5zZS4KCg4KBwQABAACBQESAzgECwoOCgcEAAQAAgUCEgM4Dg8KyAEKBAQAAgASBD4C
QQQauQEgUmVxdWlyZWQuIEltbXV0YWJsZS4gVGhlIHVzZXIgcHJpbmNpcGFsIG9mIHRoZSBV
c2VyLCBjb3VsZCBiZSBlbWFpbCBhZGRyZXNzCiBvciBvdGhlciBwcmluaWNhbCBpZGVudGlm
aWVyLiBUaGlzIGZpZWxkIGlzIGltbXV0YWJsZS4gQWRtaW4gYXNzaWduCiBsaWNlbnNlcyBi
YXNlZCBvbiB0aGUgdXNlciBwcmluY2lwYWwuCgoMCgUEAAIABRIDPgIICgwKBQQAAgABEgM+
CRcKDAoFBAACAAMSAz4aGwoNCgUEAAIACBIEPhxBAwoPCggEAAIACJwIABIDPwQrCg8KCAQA
AgAInAgBEgNABCoKawoEBAACARIDRQJDGl4gT3B0aW9uYWwuIFRoZSB1c2VyIHByb2ZpbGUu
CiBXZSB1c2VyIHVzZXIgZnVsbCBuYW1lKEZpcnN0IG5hbWUgKyBMYXN0IG5hbWUpIGFzIHVz
ZXIgcHJvZmlsZS4KCgwKBQQAAgEFEgNFAggKDAoFBAACAQESA0UJFQoMCgUEAAIBAxIDRRgZ
CgwKBQQAAgEIEgNFGkIKDwoIBAACAQicCAASA0UbQQqfAgoEBAACAhIETAJNMhqQAiBPdXRw
dXQgb25seS4gTGljZW5zZSBhc3NpZ25tZW50IHN0YXRlIG9mIHRoZSB1c2VyLgogSWYgdGhl
IHVzZXIgaXMgYXNzaWduZWQgd2l0aCBhIGxpY2Vuc2UgY29uZmlnLCB0aGUgdXNlciBsb2dp
biB3aWxsIGJlCiBhc3NpZ25lZCB3aXRoIHRoZSBsaWNlbnNlOwogSWYgdGhlIHVzZXIncyBs
aWNlbnNlIGFzc2lnbm1lbnQgc3RhdGUgaXMgdW5hc3NpZ25lZCBvciB1bnNwZWNpZmllZCwg
bm8KIGxpY2Vuc2UgY29uZmlnIHdpbGwgYmUgYXNzb2NpYXRlZCB0byB0aGUgdXNlcjsKCgwK
BQQAAgIGEgNMAhgKDAoFBAACAgESA0wZMQoMCgUEAAICAxIDTDQ1CgwKBQQAAgIIEgNNBjEK
DwoIBAACAgicCAASA00HMApqCgQEAAIDEgRRAlYEGlwgT3B0aW9uYWwuIFRoZSBmdWxsIHJl
c291cmNlIG5hbWUgb2YgdGhlIFN1YnNjcmlwdGlvbihMaWNlbnNlQ29uZmlnKQogYXNzaWdu
ZWQgdG8gdGhlIHVzZXIuCgoMCgUEAAIDBRIDUQIICgwKBQQAAgMBEgNRCRcKDAoFBAACAwMS
A1EaGwoNCgUEAAIDCBIEURxWAwoPCggEAAIDCJwIABIDUgQqCg8KBwQAAgMInwgSBFMEVQUK
NAoEBAACBBIEWQJaMhomIE91dHB1dCBvbmx5LiBVc2VyIGNyZWF0ZWQgdGltZXN0YW1wLgoK
DAoFBAACBAYSA1kCGwoMCgUEAAIEARIDWRwnCgwKBQQAAgQDEgNZKisKDAoFBAACBAgSA1oG
MQoPCggEAAIECJwIABIDWgcwCjMKBAQAAgUSBF0CXjIaJSBPdXRwdXQgb25seS4gVXNlciB1
cGRhdGUgdGltZXN0YW1wLgoKDAoFBAACBQYSA10CGwoMCgUEAAIFARIDXRwnCgwKBQQAAgUD
EgNdKisKDAoFBAACBQgSA14GMQoPCggEAAIFCJwIABIDXgcwCnQKBAQAAgYSBGICYzIaZiBP
dXRwdXQgb25seS4gVXNlciBsYXN0IGxvZ2dlZCBpbiB0aW1lLgogSWYgdGhlIHVzZXIgaGFz
IG5vdCBsb2dnZWQgaW4geWV0LCB0aGlzIGZpZWxkIHdpbGwgYmUgZW1wdHkuCgoMCgUEAAIG
BhIDYgIbCgwKBQQAAgYBEgNiHCsKDAoFBAACBgMSA2IuLwoMCgUEAAIGCBIDYwYxCg8KCAQA
AgYInAgAEgNjBzAKKgoCBAESBGcAbQEaHiBTdGF0cyBhYm91dCB1c2VycycgbGljZW5zZXMu
CgoKCgMEAQESA2cIHwowCgQEAQIAEgNpAkUaIyBSZXF1aXJlZC4gVGhlIExpY2Vuc2VDb25m
aWcgbmFtZS4KCgwKBQQBAgAFEgNpAggKDAoFBAECAAESA2kJFwoMCgUEAQIAAxIDaRobCgwK
BQQBAgAIEgNpHEQKDwoIBAECAAicCAASA2kdQwo1CgQEAQIBEgNsAkgaKCBSZXF1aXJlZC4g
VGhlIG51bWJlciBvZiBsaWNlbnNlcyB1c2VkLgoKDAoFBAECAQUSA2wCBwoMCgUEAQIBARID
bAgaCgwKBQQBAgEDEgNsHR4KDAoFBAECAQgSA2wfRwoPCggEAQIBCJwIABIDbCBGYgZwcm90
bzM=
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Discoveryengine::V1beta::UserLicense::UserLicense ===
    # Fields for UserLicense
    # Field: user_principal Type: 9 ()
    # Field: user_profile Type: 9 ()
    # Field: license_assignment_state Type: 14 (.google.cloud.discoveryengine.v1beta.UserLicense.LicenseAssignmentState)
    # Field: license_config Type: 9 ()
    # Field: create_time Type: 11 (.google.protobuf.Timestamp)
    # Field: update_time Type: 11 (.google.protobuf.Timestamp)
    # Field: last_login_time Type: 11 (.google.protobuf.Timestamp)

# Enum: UserLicense::LicenseAssignmentState
our $UserLicense_LICENSE_ASSIGNMENT_STATE_UNSPECIFIED = 0;
our $UserLicense_ASSIGNED = 1;
our $UserLicense_UNASSIGNED = 2;
our $UserLicense_NO_LICENSE = 3;
our $UserLicense_NO_LICENSE_ATTEMPTED_LOGIN = 4;
our $UserLicense_BLOCKED = 5;

# === Message: Google::Cloud::Discoveryengine::V1beta::UserLicense::LicenseConfigUsageStats ===
    # Fields for LicenseConfigUsageStats
    # Field: license_config Type: 9 ()
    # Field: used_license_count Type: 3 ()

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Discoveryengine::V1beta::UserLicense - Compiled Protocol Buffers messages for google/cloud/discoveryengine/v1beta/user_license.proto

=head1 SYNOPSIS

    use Google::Cloud::Discoveryengine::V1beta::UserLicense;

    my $msg = Google::Cloud::Discoveryengine::V1beta::UserLicense::UserLicense->new({
        user_principal => $user_principal,
        user_profile => $user_profile,
        license_assignment_state => $license_assignment_state,
        license_config => $license_config,
    });

    # Read or update a field
    my $val = $msg->user_principal();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Discoveryengine::V1beta::UserLicense::UserLicense->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/discoveryengine/v1beta/user_license.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Discoveryengine::V1beta::UserLicense::UserLicense

User License information assigned by the admin.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->user_principal() >> / C<< $msg->user_principal($value) >>

Type: C<String>

Required. Immutable. The user principal of the User, could be email address
or other prinical identifier. This field is immutable. Admin assign
licenses based on the user principal.

=item * C<< $msg->user_profile() >> / C<< $msg->user_profile($value) >>

Type: C<String>

Optional. The user profile.
We user user full name(First name + Last name) as user profile.

=item * C<< $msg->license_assignment_state() >> / C<< $msg->license_assignment_state($value) >>

Type: C<Enum> (L<Google::Cloud::Discoveryengine::V1beta::UserLicense::LicenseAssignmentState>)

Output only. License assignment state of the user.
If the user is assigned with a license config, the user login will be
assigned with the license;
If the user's license assignment state is unassigned or unspecified, no
license config will be associated to the user;

=item * C<< $msg->license_config() >> / C<< $msg->license_config($value) >>

Type: C<String>

Optional. The full resource name of the Subscription(LicenseConfig)
assigned to the user.

=item * C<< $msg->create_time() >> / C<< $msg->create_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Output only. User created timestamp.

=item * C<< $msg->update_time() >> / C<< $msg->update_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Output only. User update timestamp.

=item * C<< $msg->last_login_time() >> / C<< $msg->last_login_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Output only. User last logged in time.
If the user has not logged in yet, this field will be empty.

=back

=head3 Enum: UserLicense::LicenseAssignmentState

=over 4

=item * C<LICENSE_ASSIGNMENT_STATE_UNSPECIFIED> => C<0>

=item * C<ASSIGNED> => C<1>

=item * C<UNASSIGNED> => C<2>

=item * C<NO_LICENSE> => C<3>

=item * C<NO_LICENSE_ATTEMPTED_LOGIN> => C<4>

=item * C<BLOCKED> => C<5>

=back

=head2 Google::Cloud::Discoveryengine::V1beta::UserLicense::LicenseConfigUsageStats

Stats about users' licenses.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->license_config() >> / C<< $msg->license_config($value) >>

Type: C<String>

Required. The LicenseConfig name.

=item * C<< $msg->used_license_count() >> / C<< $msg->used_license_count($value) >>

Type: C<Int64>

Required. The number of licenses used.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Discoveryengine::V1beta::UserLicense::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
