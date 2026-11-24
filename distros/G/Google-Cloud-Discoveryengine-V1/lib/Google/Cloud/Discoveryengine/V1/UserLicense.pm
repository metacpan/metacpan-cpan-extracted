package Google::Cloud::Discoveryengine::V1::UserLicense;

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
CjJnb29nbGUvY2xvdWQvZGlzY292ZXJ5ZW5naW5lL3YxL3VzZXJfbGljZW5zZS5wcm90bxIf
Z29vZ2xlLmNsb3VkLmRpc2NvdmVyeWVuZ2luZS52MRofZ29vZ2xlL2FwaS9maWVsZF9iZWhh
dmlvci5wcm90bxoZZ29vZ2xlL2FwaS9yZXNvdXJjZS5wcm90bxofZ29vZ2xlL3Byb3RvYnVm
L3RpbWVzdGFtcC5wcm90byKzBQoLVXNlckxpY2Vuc2USLQoOdXNlcl9wcmluY2lwYWwYASAB
KAlCBuBBBeBBAlINdXNlclByaW5jaXBhbBImCgx1c2VyX3Byb2ZpbGUYAyABKAlCA+BBAVIL
dXNlclByb2ZpbGUSggEKGGxpY2Vuc2VfYXNzaWdubWVudF9zdGF0ZRgEIAEoDjJDLmdvb2ds
ZS5jbG91ZC5kaXNjb3ZlcnllbmdpbmUudjEuVXNlckxpY2Vuc2UuTGljZW5zZUFzc2lnbm1l
bnRTdGF0ZUID4EEDUhZsaWNlbnNlQXNzaWdubWVudFN0YXRlElsKDmxpY2Vuc2VfY29uZmln
GAUgASgJQjTgQQH6QS4KLGRpc2NvdmVyeWVuZ2luZS5nb29nbGVhcGlzLmNvbS9MaWNlbnNl
Q29uZmlnUg1saWNlbnNlQ29uZmlnEkAKC2NyZWF0ZV90aW1lGAYgASgLMhouZ29vZ2xlLnBy
b3RvYnVmLlRpbWVzdGFtcEID4EEDUgpjcmVhdGVUaW1lEkAKC3VwZGF0ZV90aW1lGAcgASgL
MhouZ29vZ2xlLnByb3RvYnVmLlRpbWVzdGFtcEID4EEDUgp1cGRhdGVUaW1lEkcKD2xhc3Rf
bG9naW5fdGltZRgIIAEoCzIaLmdvb2dsZS5wcm90b2J1Zi5UaW1lc3RhbXBCA+BBA1INbGFz
dExvZ2luVGltZSKdAQoWTGljZW5zZUFzc2lnbm1lbnRTdGF0ZRIoCiRMSUNFTlNFX0FTU0lH
Tk1FTlRfU1RBVEVfVU5TUEVDSUZJRUQQABIMCghBU1NJR05FRBABEg4KClVOQVNTSUdORUQQ
AhIOCgpOT19MSUNFTlNFEAMSHgoaTk9fTElDRU5TRV9BVFRFTVBURURfTE9HSU4QBBILCgdC
TE9DS0VEEAUieAoXTGljZW5zZUNvbmZpZ1VzYWdlU3RhdHMSKgoObGljZW5zZV9jb25maWcY
ASABKAlCA+BBAlINbGljZW5zZUNvbmZpZxIxChJ1c2VkX2xpY2Vuc2VfY291bnQYAiABKANC
A+BBAlIQdXNlZExpY2Vuc2VDb3VudEKDAgojY29tLmdvb2dsZS5jbG91ZC5kaXNjb3Zlcnll
bmdpbmUudjFCEFVzZXJMaWNlbnNlUHJvdG9QAVpNY2xvdWQuZ29vZ2xlLmNvbS9nby9kaXNj
b3ZlcnllbmdpbmUvYXBpdjEvZGlzY292ZXJ5ZW5naW5lcGI7ZGlzY292ZXJ5ZW5naW5lcGKi
Ag9ESVNDT1ZFUllFTkdJTkWqAh9Hb29nbGUuQ2xvdWQuRGlzY292ZXJ5RW5naW5lLlYxygIf
R29vZ2xlXENsb3VkXERpc2NvdmVyeUVuZ2luZVxWMeoCIkdvb2dsZTo6Q2xvdWQ6OkRpc2Nv
dmVyeUVuZ2luZTo6VjFKtRsKBhIEDgBtAQq8BAoBDBIDDgASMrEEIENvcHlyaWdodCAyMDI2
IEdvb2dsZSBMTEMKCiBMaWNlbnNlZCB1bmRlciB0aGUgQXBhY2hlIExpY2Vuc2UsIFZlcnNp
b24gMi4wICh0aGUgIkxpY2Vuc2UiKTsKIHlvdSBtYXkgbm90IHVzZSB0aGlzIGZpbGUgZXhj
ZXB0IGluIGNvbXBsaWFuY2Ugd2l0aCB0aGUgTGljZW5zZS4KIFlvdSBtYXkgb2J0YWluIGEg
Y29weSBvZiB0aGUgTGljZW5zZSBhdAoKICAgICBodHRwOi8vd3d3LmFwYWNoZS5vcmcvbGlj
ZW5zZXMvTElDRU5TRS0yLjAKCiBVbmxlc3MgcmVxdWlyZWQgYnkgYXBwbGljYWJsZSBsYXcg
b3IgYWdyZWVkIHRvIGluIHdyaXRpbmcsIHNvZnR3YXJlCiBkaXN0cmlidXRlZCB1bmRlciB0
aGUgTGljZW5zZSBpcyBkaXN0cmlidXRlZCBvbiBhbiAiQVMgSVMiIEJBU0lTLAogV0lUSE9V
VCBXQVJSQU5USUVTIE9SIENPTkRJVElPTlMgT0YgQU5ZIEtJTkQsIGVpdGhlciBleHByZXNz
IG9yIGltcGxpZWQuCiBTZWUgdGhlIExpY2Vuc2UgZm9yIHRoZSBzcGVjaWZpYyBsYW5ndWFn
ZSBnb3Zlcm5pbmcgcGVybWlzc2lvbnMgYW5kCiBsaW1pdGF0aW9ucyB1bmRlciB0aGUgTGlj
ZW5zZS4KCggKAQISAxAAKAoJCgIDABIDEgApCgkKAgMBEgMTACMKCQoCAwISAxQAKQoICgEI
EgMWADwKCQoCCCUSAxYAPAoICgEIEgMXAGQKCQoCCAsSAxcAZAoICgEIEgMYACIKCQoCCAoS
AxgAIgoICgEIEgMZADEKCQoCCAgSAxkAMQoICgEIEgMaADwKCQoCCAESAxoAPAoICgEIEgMb
AC0KCQoCCCQSAxsALQoICgEIEgMcADwKCQoCCCkSAxwAPAoICgEIEgMdADsKCQoCCC0SAx0A
Owo9CgIEABIEIABkARoxIFVzZXIgTGljZW5zZSBpbmZvcm1hdGlvbiBhc3NpZ25lZCBieSB0
aGUgYWRtaW4uCgoKCgMEAAESAyAIEwo1CgQEAAQAEgQiAjkDGicgTGljZW5zZSBhc3NpZ25t
ZW50IHN0YXRlIGVudW1lcmF0aW9uLgoKDAoFBAAEAAESAyIHHQofCgYEAAQAAgASAyQELRoQ
IERlZmF1bHQgdmFsdWUuCgoOCgcEAAQAAgABEgMkBCgKDgoHBAAEAAIAAhIDJCssCi4KBgQA
BAACARIDJwQRGh8gTGljZW5zZSBhc3NpZ25lZCB0byB0aGUgdXNlci4KCg4KBwQABAACAQES
AycEDAoOCgcEAAQAAgECEgMnDxAKWAoGBAAEAAICEgMrBBMaSSBObyBsaWNlbnNlIGFzc2ln
bmVkIHRvIHRoZSB1c2VyLgogRGVwcmVjYXRlZCwgdHJhbnNsYXRlZCB0byBOT19MSUNFTlNF
LgoKDgoHBAAEAAICARIDKwQOCg4KBwQABAACAgISAysREgoxCgYEAAQAAgMSAy4EExoiIE5v
IGxpY2Vuc2UgYXNzaWduZWQgdG8gdGhlIHVzZXIuCgoOCgcEAAQAAgMBEgMuBA4KDgoHBAAE
AAIDAhIDLhESCrECCgYEAAQAAgQSAzUEIxqhAiBVc2VyIGF0dGVtcHRlZCB0byBsb2dpbiBi
dXQgbm8gbGljZW5zZSBhc3NpZ25lZCB0byB0aGUgdXNlci4KIFRoaXMgc3RhdGUgaXMgb25s
eSB1c2VkIGZvciBubyB1c2VyIGZpcnN0IHRpbWUgbG9naW4gYXR0ZW1wdCBidXQgY2Fubm90
CiBnZXQgbGljZW5zZSBhc3NpZ25lZC4KIFVzZXJzIGFscmVhZHkgbG9nZ2VkIGluIGJ1dCBj
YW5ub3QgZ2V0IGxpY2Vuc2UgYXNzaWduZWQgd2lsbCBiZSBhc3NpZ25lZAogTk9fTElDRU5T
RSBzdGF0ZShMaWNlbnNlIGNvdWxkIGJlIHVuYXNzaWduZWQgYnkgYWRtaW4pLgoKDgoHBAAE
AAIEARIDNQQeCg4KBwQABAACBAISAzUhIgo6CgYEAAQAAgUSAzgEEBorIFVzZXIgaXMgYmxv
Y2tlZCBmcm9tIGFzc2lnbmluZyBhIGxpY2Vuc2UuCgoOCgcEAAQAAgUBEgM4BAsKDgoHBAAE
AAIFAhIDOA4PCsgBCgQEAAIAEgQ+AkEEGrkBIFJlcXVpcmVkLiBJbW11dGFibGUuIFRoZSB1
c2VyIHByaW5jaXBhbCBvZiB0aGUgVXNlciwgY291bGQgYmUgZW1haWwgYWRkcmVzcwogb3Ig
b3RoZXIgcHJpbmljYWwgaWRlbnRpZmllci4gVGhpcyBmaWVsZCBpcyBpbW11dGFibGUuIEFk
bWluIGFzc2lnbgogbGljZW5zZXMgYmFzZWQgb24gdGhlIHVzZXIgcHJpbmNpcGFsLgoKDAoF
BAACAAUSAz4CCAoMCgUEAAIAARIDPgkXCgwKBQQAAgADEgM+GhsKDQoFBAACAAgSBD4cQQMK
DwoIBAACAAicCAASAz8EKwoPCggEAAIACJwIARIDQAQqCmsKBAQAAgESA0UCQxpeIE9wdGlv
bmFsLiBUaGUgdXNlciBwcm9maWxlLgogV2UgdXNlciB1c2VyIGZ1bGwgbmFtZShGaXJzdCBu
YW1lICsgTGFzdCBuYW1lKSBhcyB1c2VyIHByb2ZpbGUuCgoMCgUEAAIBBRIDRQIICgwKBQQA
AgEBEgNFCRUKDAoFBAACAQMSA0UYGQoMCgUEAAIBCBIDRRpCCg8KCAQAAgEInAgAEgNFG0EK
nwIKBAQAAgISBEwCTTIakAIgT3V0cHV0IG9ubHkuIExpY2Vuc2UgYXNzaWdubWVudCBzdGF0
ZSBvZiB0aGUgdXNlci4KIElmIHRoZSB1c2VyIGlzIGFzc2lnbmVkIHdpdGggYSBsaWNlbnNl
IGNvbmZpZywgdGhlIHVzZXIgbG9naW4gd2lsbCBiZQogYXNzaWduZWQgd2l0aCB0aGUgbGlj
ZW5zZTsKIElmIHRoZSB1c2VyJ3MgbGljZW5zZSBhc3NpZ25tZW50IHN0YXRlIGlzIHVuYXNz
aWduZWQgb3IgdW5zcGVjaWZpZWQsIG5vCiBsaWNlbnNlIGNvbmZpZyB3aWxsIGJlIGFzc29j
aWF0ZWQgdG8gdGhlIHVzZXI7CgoMCgUEAAICBhIDTAIYCgwKBQQAAgIBEgNMGTEKDAoFBAAC
AgMSA0w0NQoMCgUEAAICCBIDTQYxCg8KCAQAAgIInAgAEgNNBzAKagoEBAACAxIEUQJWBBpc
IE9wdGlvbmFsLiBUaGUgZnVsbCByZXNvdXJjZSBuYW1lIG9mIHRoZSBTdWJzY3JpcHRpb24o
TGljZW5zZUNvbmZpZykKIGFzc2lnbmVkIHRvIHRoZSB1c2VyLgoKDAoFBAACAwUSA1ECCAoM
CgUEAAIDARIDUQkXCgwKBQQAAgMDEgNRGhsKDQoFBAACAwgSBFEcVgMKDwoIBAACAwicCAAS
A1IEKgoPCgcEAAIDCJ8IEgRTBFUFCjQKBAQAAgQSBFkCWjIaJiBPdXRwdXQgb25seS4gVXNl
ciBjcmVhdGVkIHRpbWVzdGFtcC4KCgwKBQQAAgQGEgNZAhsKDAoFBAACBAESA1kcJwoMCgUE
AAIEAxIDWSorCgwKBQQAAgQIEgNaBjEKDwoIBAACBAicCAASA1oHMAozCgQEAAIFEgRdAl4y
GiUgT3V0cHV0IG9ubHkuIFVzZXIgdXBkYXRlIHRpbWVzdGFtcC4KCgwKBQQAAgUGEgNdAhsK
DAoFBAACBQESA10cJwoMCgUEAAIFAxIDXSorCgwKBQQAAgUIEgNeBjEKDwoIBAACBQicCAAS
A14HMAp0CgQEAAIGEgRiAmMyGmYgT3V0cHV0IG9ubHkuIFVzZXIgbGFzdCBsb2dnZWQgaW4g
dGltZS4KIElmIHRoZSB1c2VyIGhhcyBub3QgbG9nZ2VkIGluIHlldCwgdGhpcyBmaWVsZCB3
aWxsIGJlIGVtcHR5LgoKDAoFBAACBgYSA2ICGwoMCgUEAAIGARIDYhwrCgwKBQQAAgYDEgNi
Li8KDAoFBAACBggSA2MGMQoPCggEAAIGCJwIABIDYwcwCioKAgQBEgRnAG0BGh4gU3RhdHMg
YWJvdXQgdXNlcnMnIGxpY2Vuc2VzLgoKCgoDBAEBEgNnCB8KMAoEBAECABIDaQJFGiMgUmVx
dWlyZWQuIFRoZSBMaWNlbnNlQ29uZmlnIG5hbWUuCgoMCgUEAQIABRIDaQIICgwKBQQBAgAB
EgNpCRcKDAoFBAECAAMSA2kaGwoMCgUEAQIACBIDaRxECg8KCAQBAgAInAgAEgNpHUMKNQoE
BAECARIDbAJIGiggUmVxdWlyZWQuIFRoZSBudW1iZXIgb2YgbGljZW5zZXMgdXNlZC4KCgwK
BQQBAgEFEgNsAgcKDAoFBAECAQESA2wIGgoMCgUEAQIBAxIDbB0eCgwKBQQBAgEIEgNsH0cK
DwoIBAECAQicCAASA2wgRmIGcHJvdG8z
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Discoveryengine::V1::UserLicense::UserLicense ===
    # Fields for UserLicense
    # Field: user_principal Type: 9 ()
    # Field: user_profile Type: 9 ()
    # Field: license_assignment_state Type: 14 (.google.cloud.discoveryengine.v1.UserLicense.LicenseAssignmentState)
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

# === Message: Google::Cloud::Discoveryengine::V1::UserLicense::LicenseConfigUsageStats ===
    # Fields for LicenseConfigUsageStats
    # Field: license_config Type: 9 ()
    # Field: used_license_count Type: 3 ()

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Discoveryengine::V1::UserLicense - Compiled Protocol Buffers messages for google/cloud/discoveryengine/v1/user_license.proto

=head1 SYNOPSIS

    use Google::Cloud::Discoveryengine::V1::UserLicense;

    my $msg = Google::Cloud::Discoveryengine::V1::UserLicense::UserLicense->new({
        user_principal => $user_principal,
        user_profile => $user_profile,
        license_assignment_state => $license_assignment_state,
        license_config => $license_config,
    });

    # Read or update a field
    my $val = $msg->user_principal();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Discoveryengine::V1::UserLicense::UserLicense->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/discoveryengine/v1/user_license.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Discoveryengine::V1::UserLicense::UserLicense

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

Type: C<Enum> (L<Google::Cloud::Discoveryengine::V1::UserLicense::LicenseAssignmentState>)

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

=head2 Google::Cloud::Discoveryengine::V1::UserLicense::LicenseConfigUsageStats

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

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Discoveryengine::V1::UserLicense::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
