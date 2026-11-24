package Google::Actions::Sdk::V2::AccountLinking;

use strict;
use warnings;

our $VERSION = '0.14';

use Protobuf::Message;
use Protobuf::DescriptorPool;
use Protobuf::Internal qw(:all);
use MIME::Base64;

BEGIN {
    eval { require Google::Api::FieldBehavior };
    my $descriptor_b64 = <<'EOF';
Citnb29nbGUvYWN0aW9ucy9zZGsvdjIvYWNjb3VudF9saW5raW5nLnByb3RvEhVnb29nbGUu
YWN0aW9ucy5zZGsudjIaH2dvb2dsZS9hcGkvZmllbGRfYmVoYXZpb3IucHJvdG8iwAUKDkFj
Y291bnRMaW5raW5nEjsKF2VuYWJsZV9hY2NvdW50X2NyZWF0aW9uGAEgASgIQgPgQQJSFWVu
YWJsZUFjY291bnRDcmVhdGlvbhJZCgxsaW5raW5nX3R5cGUYAiABKA4yMS5nb29nbGUuYWN0
aW9ucy5zZGsudjIuQWNjb3VudExpbmtpbmcuTGlua2luZ1R5cGVCA+BBAlILbGlua2luZ1R5
cGUSYAoPYXV0aF9ncmFudF90eXBlGAMgASgOMjMuZ29vZ2xlLmFjdGlvbnMuc2RrLnYyLkFj
Y291bnRMaW5raW5nLkF1dGhHcmFudFR5cGVCA+BBAVINYXV0aEdyYW50VHlwZRInCg1hcHBf
Y2xpZW50X2lkGAQgASgJQgPgQQFSC2FwcENsaWVudElkEjAKEWF1dGhvcml6YXRpb25fdXJs
GAUgASgJQgPgQQFSEGF1dGhvcml6YXRpb25VcmwSIAoJdG9rZW5fdXJsGAYgASgJQgPgQQFS
CHRva2VuVXJsEhsKBnNjb3BlcxgHIAMoCUID4EEBUgZzY29wZXMSKQoObGVhcm5fbW9yZV91
cmwYCCABKAlCA+BBAVIMbGVhcm5Nb3JlVXJsEjYKFXVzZV9iYXNpY19hdXRoX2hlYWRlchgJ
IAEoCEID4EEBUhJ1c2VCYXNpY0F1dGhIZWFkZXIiaAoLTGlua2luZ1R5cGUSHAoYTElOS0lO
R19UWVBFX1VOU1BFQ0lGSUVEEAASEgoOR09PR0xFX1NJR05fSU4QARIcChhPQVVUSF9BTkRf
R09PR0xFX1NJR05fSU4QAhIJCgVPQVVUSBADIk0KDUF1dGhHcmFudFR5cGUSHwobQVVUSF9H
UkFOVF9UWVBFX1VOU1BFQ0lGSUVEEAASDQoJQVVUSF9DT0RFEAESDAoISU1QTElDSVQQAkJs
Chljb20uZ29vZ2xlLmFjdGlvbnMuc2RrLnYyQhNBY2NvdW50TGlua2luZ1Byb3RvUAFaOGdv
b2dsZS5nb2xhbmcub3JnL2dlbnByb3RvL2dvb2dsZWFwaXMvYWN0aW9ucy9zZGsvdjI7c2Rr
SsgnCgYSBA4AfQEKvAQKAQwSAw4AEjKxBCBDb3B5cmlnaHQgMjAyNSBHb29nbGUgTExDCgog
TGljZW5zZWQgdW5kZXIgdGhlIEFwYWNoZSBMaWNlbnNlLCBWZXJzaW9uIDIuMCAodGhlICJM
aWNlbnNlIik7CiB5b3UgbWF5IG5vdCB1c2UgdGhpcyBmaWxlIGV4Y2VwdCBpbiBjb21wbGlh
bmNlIHdpdGggdGhlIExpY2Vuc2UuCiBZb3UgbWF5IG9idGFpbiBhIGNvcHkgb2YgdGhlIExp
Y2Vuc2UgYXQKCiAgICAgaHR0cDovL3d3dy5hcGFjaGUub3JnL2xpY2Vuc2VzL0xJQ0VOU0Ut
Mi4wCgogVW5sZXNzIHJlcXVpcmVkIGJ5IGFwcGxpY2FibGUgbGF3IG9yIGFncmVlZCB0byBp
biB3cml0aW5nLCBzb2Z0d2FyZQogZGlzdHJpYnV0ZWQgdW5kZXIgdGhlIExpY2Vuc2UgaXMg
ZGlzdHJpYnV0ZWQgb24gYW4gIkFTIElTIiBCQVNJUywKIFdJVEhPVVQgV0FSUkFOVElFUyBP
UiBDT05ESVRJT05TIE9GIEFOWSBLSU5ELCBlaXRoZXIgZXhwcmVzcyBvciBpbXBsaWVkLgog
U2VlIHRoZSBMaWNlbnNlIGZvciB0aGUgc3BlY2lmaWMgbGFuZ3VhZ2UgZ292ZXJuaW5nIHBl
cm1pc3Npb25zIGFuZAogbGltaXRhdGlvbnMgdW5kZXIgdGhlIExpY2Vuc2UuCgoICgECEgMQ
AB4KCQoCAwASAxIAKQoICgEIEgMUAE8KCQoCCAsSAxQATwoICgEIEgMVACIKCQoCCAoSAxUA
IgoICgEIEgMWADQKCQoCCAgSAxYANAoICgEIEgMXADIKCQoCCAESAxcAMgq/BQoCBAASBCYA
fQEasgUgQWNjb3VudExpbmtpbmcgYWxsb3dzIEdvb2dsZSB0byBndWlkZSB0aGUgdXNlciB0
byBzaWduLWluIHRvIHRoZSBBcHAncyB3ZWIKIHNlcnZpY2VzLgoKIEZvciBHb29nbGUgU2ln
biBJbiBhbmQgT0F1dGggKyBHb29nbGUgU2lnbiBJbiBsaW5raW5nIHR5cGVzLCBHb29nbGUg
Z2VuZXJhdGVzCiBhIGNsaWVudCBJRCBpZGVudGlmeWluZyB5b3VyIEFwcCB0byBHb29nbGUg
KCJDbGllbnQgSUQgaXNzdWVkIGJ5IEdvb2dsZSB0bwogeW91ciBBY3Rpb25zIiBvbiBDb25z
b2xlIFVJKS4gVGhpcyBmaWVsZCBpcyByZWFkLW9ubHkgYW5kIGNhbiBiZSBjaGVja2VkIGJ5
CiBuYXZpZ2F0aW5nIHRvIHRoZSBDb25zb2xlIFVJJ3MgQWNjb3VudCBMaW5raW5nIHBhZ2Uu
CiBTZWU6IGh0dHBzOi8vZGV2ZWxvcGVycy5nb29nbGUuY29tL2Fzc2lzdGFudC9pZGVudGl0
eS9nb29nbGUtc2lnbi1pbgoKIE5vdGU6IEZvciBhbGwgYWNjb3VudCBsaW5raW5nIHNldHRp
bmcgdHlwZXMgKGV4Y2VwdCBmb3IgR29vZ2xlIFNpZ24gSW4pLCB5b3UKIG11c3QgcHJvdmlk
ZSBhIHVzZXJuYW1lIGFuZCBwYXNzd29yZCBmb3IgYSB0ZXN0IGFjY291bnQgaW4KIFNldHRp
bmdzLnRlc3RpbmdfaW5zdHJ1Y3Rpb25zIGZvciB0aGUgcmV2aWV3IHRlYW0gdG8gcmV2aWV3
IHRoZSBhcHAgKHRoZXkKIHdpbGwgbm90IGJlIHZpc2libGUgdG8gdXNlcnMpLgoKCgoDBAAB
EgMmCBYKNwoEBAAEABIEKAI1AxopIFRoZSB0eXBlIG9mIEFjY291bnQgTGlua2luZyB0byBw
ZXJmb3JtLgoKDAoFBAAEAAESAygHEgodCgYEAAQAAgASAyoEIRoOIFVuc3BlY2lmaWVkLgoK
DgoHBAAEAAIAARIDKgQcCg4KBwQABAACAAISAyofIAp4CgYEAAQAAgESAy4EFxppIEdvb2ds
ZSBTaWduIEluIGxpbmtpbmcgdHlwZS4KIElmIHVzaW5nIHRoaXMgbGlua2luZyB0eXBlLCBu
byBPQXV0aC1yZWxhdGVkIGZpZWxkcyBuZWVkIHRvIGJlIHNldCBiZWxvdy4KCg4KBwQABAAC
AQESAy4EEgoOCgcEAAQAAgECEgMuFRYKNwoGBAAEAAICEgMxBCEaKCBPQXV0aCBhbmQgR29v
Z2xlIFNpZ24gSW4gbGlua2luZyB0eXBlLgoKDgoHBAAEAAICARIDMQQcCg4KBwQABAACAgIS
AzEfIAokCgYEAAQAAgMSAzQEDhoVIE9BdXRoIGxpbmtpbmcgdHlwZS4KCg4KBwQABAACAwES
AzQECQoOCgcEAAQAAgMCEgM0DA0KagoEBAAEARIEOQJEAxpcIFRoZSBPQXV0aDIgZ3JhbnQg
dHlwZSBHb29nbGUgdXNlcyB0byBndWlkZSB0aGUgdXNlciB0byBzaWduIGluIHRvIHlvdXIK
IEFwcCdzIHdlYiBzZXJ2aWNlLgoKDAoFBAAEAQESAzkHFAodCgYEAAQBAgASAzsEJBoOIFVu
c3BlY2lmaWVkLgoKDgoHBAAEAQIAARIDOwQfCg4KBwQABAECAAISAzsiIwpxCgYEAAQBAgES
Az8EEhpiIEF1dGhvcml6YXRpb24gY29kZSBncmFudC4gUmVxdWlyZXMgeW91IHRvIHByb3Zp
ZGUgYm90aAogYXV0aGVudGljYXRpb24gVVJMIGFuZCBhY2Nlc3MgdG9rZW4gVVJMLgoKDgoH
BAAEAQIBARIDPwQNCg4KBwQABAECAQISAz8QEQpXCgYEAAQBAgISA0MEERpIIEltcGxpY2l0
IGNvZGUgZ3JhbnQuIE9ubHkgcmVxdWlyZXMgeW91IHRvIHByb3ZpZGUgYXV0aGVudGljYXRp
b24KIFVSTC4KCg4KBwQABAECAgESA0MEDAoOCgcEAAQBAgICEgNDDxAK9gIKBAQAAgASA0wC
TBroAiBSZXF1aXJlZC4gSWYgYHRydWVgLCB1c2VycyBhcmUgYWxsb3dlZCB0byBzaWduIHVw
IGZvciBuZXcgYWNjb3VudHMgdmlhIHZvaWNlLgogSWYgYGZhbHNlYCwgYWNjb3VudCBjcmVh
dGlvbiBpcyBvbmx5IGFsbG93ZWQgb24geW91ciB3ZWJzaXRlLiBTZWxlY3QgdGhpcwogb3B0
aW9uIGlmIHlvdSB3YW50IHRvIGRpc3BsYXkgeW91ciB0ZXJtcyBvZiBzZXJ2aWNlIG9yIG9i
dGFpbiB1c2VyIGNvbnNlbnRzCiBkdXJpbmcgc2lnbi11cC4KIGxpbmtpbmdfdHlwZSBjYW5u
b3QgYmUgR09PR0xFX1NJR05fSU4gd2hlbiB0aGlzIGlzIGBmYWxzZWAuCiBsaW5raW5nX3R5
cGUgY2Fubm90IGJlIE9BVVRIIHdoZW4gdGhpcyBpcyBgdHJ1ZWAuCgoMCgUEAAIABRIDTAIG
CgwKBQQAAgABEgNMBx4KDAoFBAACAAMSA0whIgoMCgUEAAIACBIDTCNLCg8KCAQAAgAInAgA
EgNMJEoKkwEKBAQAAgESA1ECSBqFASBSZXF1aXJlZC4gVGhlIGxpbmtpbmcgdHlwZSB0byB1
c2UuCiBTZWUgaHR0cHM6Ly9kZXZlbG9wZXJzLmdvb2dsZS5jb20vYXNzaXN0YW50L2lkZW50
aXR5IGZvciBmdXJ0aGVyIGRldGFpbHMgb24KIHRoZSBsaW5raW5nIHR5cGVzLgoKDAoFBAAC
AQYSA1ECDQoMCgUEAAIBARIDUQ4aCgwKBQQAAgEDEgNRHR4KDAoFBAACAQgSA1EfRwoPCggE
AAIBCJwIABIDUSBGClUKBAQAAgISA1QCTRpIIE9wdGlvbmFsLiBJbmRpY2F0ZXMgdGhlIHR5
cGUgb2YgYXV0aGVudGljYXRpb24gZm9yIE9BVVRIIGxpbmtpbmdfdHlwZS4KCgwKBQQAAgIG
EgNUAg8KDAoFBAACAgESA1QQHwoMCgUEAAICAxIDVCIjCgwKBQQAAgIIEgNUJEwKDwoIBAAC
AgicCAASA1QlSwqfAQoEBAACAxIDWQJEGpEBIE9wdGlvbmFsLiBDbGllbnQgSUQgaXNzdWVk
IGJ5IHlvdXIgQXBwIHRvIEdvb2dsZS4KIFRoaXMgaXMgdGhlIE9BdXRoMiBDbGllbnQgSUQg
aWRlbnRpZnlpbmcgR29vZ2xlIHRvIHlvdXIgc2VydmljZS4KIE9ubHkgc2V0IHdoZW4gdXNp
bmcgT0F1dGguCgoMCgUEAAIDBRIDWQIICgwKBQQAAgMBEgNZCRYKDAoFBAACAwMSA1kZGgoM
CgUEAAIDCBIDWRtDCg8KCAQAAgMInAgAEgNZHEIKmwEKBAQAAgQSA18CSBqNASBPcHRpb25h
bC4gRW5kcG9pbnQgZm9yIHlvdXIgc2lnbi1pbiB3ZWIgcGFnZSB0aGF0IHN1cHBvcnRzIE9B
dXRoMiBjb2RlIG9yCiBpbXBsaWNpdCBmbG93cy4KIFVSTCBtdXN0IHVzZSBIVFRQUy4KIE9u
bHkgc2V0IHdoZW4gdXNpbmcgT0F1dGguCgoMCgUEAAIEBRIDXwIICgwKBQQAAgQBEgNfCRoK
DAoFBAACBAMSA18dHgoMCgUEAAIECBIDXx9HCg8KCAQAAgQInAgAEgNfIEYKvwEKBAQAAgUS
A2YCQBqxASBPcHRpb25hbC4gT0F1dGgyIGVuZHBvaW50IGZvciB0b2tlbiBleGNoYW5nZS4K
IFVSTCBtdXN0IHVzZSBIVFRQUy4KIFRoaXMgaXMgbm90IHNldCB3aGVuIG9ubHkgdXNpbmcg
T0F1dGggd2l0aCBJTVBMSUNJVCBncmFudCBhcyB0aGUKIGxpbmtpbmcgdHlwZS4KIE9ubHkg
c2V0IHdoZW4gdXNpbmcgT0F1dGguCgoMCgUEAAIFBRIDZgIICgwKBQQAAgUBEgNmCRIKDAoF
BAACBQMSA2YVFgoMCgUEAAIFCBIDZhc/Cg8KCAQAAgUInAgAEgNmGD4KlAIKBAQAAgYSA20C
RhqGAiBPcHRpb25hbC4gTGlzdCBvZiBwZXJtaXNzaW9ucyB0aGUgdXNlciBtdXN0IGNvbnNl
bnQgdG8gaW4gb3JkZXIgdG8gdXNlCiB5b3VyIHNlcnZpY2UuCiBPbmx5IHNldCB3aGVuIHVz
aW5nIE9BdXRoLgogTWFrZSBzdXJlIHRvIHByb3ZpZGUgYSBUZXJtcyBvZiBTZXJ2aWNlIGlu
IHRoZSBkaXJlY3RvcnkgaW5mb3JtYXRpb24gaW4KIExvY2FsaXplZFNldHRpbmdzLnRlcm1z
X29mX3NlcnZpY2VfdXJsIHNlY3Rpb24gaWYgc3BlY2lmeWluZyB0aGlzIGZpZWxkLgoKDAoF
BAACBgQSA20CCgoMCgUEAAIGBRIDbQsRCgwKBQQAAgYBEgNtEhgKDAoFBAACBgMSA20bHAoM
CgUEAAIGCBIDbR1FCg8KCAQAAgYInAgAEgNtHkQKvwIKBAQAAgcSA3QCRRqxAiBPcHRpb25h
bC4gVGhpcyBpcyB0aGUgd2ViIHBhZ2Ugb24geW91ciBzZXJ2aWNlIHdoaWNoIGRlc2NyaWJl
cyB0aGUKIHBlcm1pc3Npb25zIHRoZSB1c2VyIGlzIGdyYW50aW5nIHRvIEdvb2dsZS4KIE9u
bHkgc2V0IGlmIHVzaW5nIE9BdXRoIGFuZCBHb29nbGUgU2lnbiBJbi4KIE1ha2Ugc3VyZSB0
byBwcm92aWRlIGEgVGVybXMgb2YgU2VydmljZSBpbiB0aGUgZGlyZWN0b3J5IGluZm9ybWF0
aW9uIGluCiBMb2NhbGl6ZWRTZXR0aW5ncy50ZXJtc19vZl9zZXJ2aWNlX3VybCBzZWN0aW9u
IGlmIHNwZWNpZnlpbmcgdGhpcyBmaWVsZC4KCgwKBQQAAgcFEgN0AggKDAoFBAACBwESA3QJ
FwoMCgUEAAIHAxIDdBobCgwKBQQAAgcIEgN0HEQKDwoIBAACBwicCAASA3QdQwrjAgoEBAAC
CBIDfAJKGtUCIE9wdGlvbmFsLiBJZiB0cnVlLCBhbGxvdyBHb29nbGUgdG8gdHJhbnNtaXQg
Y2xpZW50IElEIGFuZCBzZWNyZXQgdmlhIEhUVFAKIGJhc2ljIGF1dGggaGVhZGVyLiBPdGhl
cndpc2UsIEdvb2dsZSB1c2VzIHRoZSBjbGllbnQgSUQgYW5kIHNlY3JldCBpbnNpZGUKIHRo
ZSBwb3N0IGJvZHkuCiBPbmx5IHNldCB3aGVuIHVzaW5nIE9BdXRoLgogTWFrZSBzdXJlIHRv
IHByb3ZpZGUgYSBUZXJtcyBvZiBTZXJ2aWNlIGluIHRoZSBkaXJlY3RvcnkgaW5mb3JtYXRp
b24gaW4KIExvY2FsaXplZFNldHRpbmdzLnRlcm1zX29mX3NlcnZpY2VfdXJsIHNlY3Rpb24g
aWYgc3BlY2lmeWluZyB0aGlzIGZpZWxkLgoKDAoFBAACCAUSA3wCBgoMCgUEAAIIARIDfAcc
CgwKBQQAAggDEgN8HyAKDAoFBAACCAgSA3whSQoPCggEAAIICJwIABIDfCJIYgZwcm90bzM=

EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Actions::Sdk::V2::AccountLinking::AccountLinking ===
    # Fields for AccountLinking
    # Field: enable_account_creation Type: 8 ()
    # Field: linking_type Type: 14 (.google.actions.sdk.v2.AccountLinking.LinkingType)
    # Field: auth_grant_type Type: 14 (.google.actions.sdk.v2.AccountLinking.AuthGrantType)
    # Field: app_client_id Type: 9 ()
    # Field: authorization_url Type: 9 ()
    # Field: token_url Type: 9 ()
    # Field: scopes Type: 9 ()
    # Field: learn_more_url Type: 9 ()
    # Field: use_basic_auth_header Type: 8 ()

# Enum: AccountLinking::LinkingType
our $AccountLinking_LINKING_TYPE_UNSPECIFIED = 0;
our $AccountLinking_GOOGLE_SIGN_IN = 1;
our $AccountLinking_OAUTH_AND_GOOGLE_SIGN_IN = 2;
our $AccountLinking_OAUTH = 3;

# Enum: AccountLinking::AuthGrantType
our $AccountLinking_AUTH_GRANT_TYPE_UNSPECIFIED = 0;
our $AccountLinking_AUTH_CODE = 1;
our $AccountLinking_IMPLICIT = 2;

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Actions::Sdk::V2::AccountLinking - Compiled Protocol Buffers messages for google/actions/sdk/v2/account_linking.proto

=head1 SYNOPSIS

    use Google::Actions::Sdk::V2::AccountLinking;

    my $msg = Google::Actions::Sdk::V2::AccountLinking::AccountLinking->new({
        enable_account_creation => $enable_account_creation,
        linking_type => $linking_type,
        auth_grant_type => $auth_grant_type,
        app_client_id => $app_client_id,
    });

    # Read or update a field
    my $val = $msg->enable_account_creation();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Actions::Sdk::V2::AccountLinking::AccountLinking->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/actions/sdk/v2/account_linking.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Actions::Sdk::V2::AccountLinking::AccountLinking

AccountLinking allows Google to guide the user to sign-in to the App's web
services.

For Google Sign In and OAuth + Google Sign In linking types, Google generates
a client ID identifying your App to Google ("Client ID issued by Google to
your Actions" on Console UI). This field is read-only and can be checked by
navigating to the Console UI's Account Linking page.
See: https://developers.google.com/assistant/identity/google-sign-in

Note: For all account linking setting types (except for Google Sign In), you
must provide a username and password for a test account in
Settings.testing_instructions for the review team to review the app (they
will not be visible to users).

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->enable_account_creation() >> / C<< $msg->enable_account_creation($value) >>

Type: C<Bool>

Required. If `true`, users are allowed to sign up for new accounts via voice.
If `false`, account creation is only allowed on your website. Select this
option if you want to display your terms of service or obtain user consents
during sign-up.
linking_type cannot be GOOGLE_SIGN_IN when this is `false`.
linking_type cannot be OAUTH when this is `true`.

=item * C<< $msg->linking_type() >> / C<< $msg->linking_type($value) >>

Type: C<Enum> (L<Google::Actions::Sdk::V2::AccountLinking::LinkingType>)

Required. The linking type to use.
See https://developers.google.com/assistant/identity for further details on
the linking types.

=item * C<< $msg->auth_grant_type() >> / C<< $msg->auth_grant_type($value) >>

Type: C<Enum> (L<Google::Actions::Sdk::V2::AccountLinking::AuthGrantType>)

Optional. Indicates the type of authentication for OAUTH linking_type.

=item * C<< $msg->app_client_id() >> / C<< $msg->app_client_id($value) >>

Type: C<String>

Optional. Client ID issued by your App to Google.
This is the OAuth2 Client ID identifying Google to your service.
Only set when using OAuth.

=item * C<< $msg->authorization_url() >> / C<< $msg->authorization_url($value) >>

Type: C<String>

Optional. Endpoint for your sign-in web page that supports OAuth2 code or
implicit flows.
URL must use HTTPS.
Only set when using OAuth.

=item * C<< $msg->token_url() >> / C<< $msg->token_url($value) >>

Type: C<String>

Optional. OAuth2 endpoint for token exchange.
URL must use HTTPS.
This is not set when only using OAuth with IMPLICIT grant as the
linking type.
Only set when using OAuth.

=item * C<< $msg->scopes() >> / C<< $msg->scopes($value) >>

Type: C<String>

Optional. List of permissions the user must consent to in order to use
your service.
Only set when using OAuth.
Make sure to provide a Terms of Service in the directory information in
LocalizedSettings.terms_of_service_url section if specifying this field.

=item * C<< $msg->learn_more_url() >> / C<< $msg->learn_more_url($value) >>

Type: C<String>

Optional. This is the web page on your service which describes the
permissions the user is granting to Google.
Only set if using OAuth and Google Sign In.
Make sure to provide a Terms of Service in the directory information in
LocalizedSettings.terms_of_service_url section if specifying this field.

=item * C<< $msg->use_basic_auth_header() >> / C<< $msg->use_basic_auth_header($value) >>

Type: C<Bool>

Optional. If true, allow Google to transmit client ID and secret via HTTP
basic auth header. Otherwise, Google uses the client ID and secret inside
the post body.
Only set when using OAuth.
Make sure to provide a Terms of Service in the directory information in
LocalizedSettings.terms_of_service_url section if specifying this field.

=back

=head3 Enum: AccountLinking::LinkingType

=over 4

=item * C<LINKING_TYPE_UNSPECIFIED> => C<0>

=item * C<GOOGLE_SIGN_IN> => C<1>

=item * C<OAUTH_AND_GOOGLE_SIGN_IN> => C<2>

=item * C<OAUTH> => C<3>

=back

=head3 Enum: AccountLinking::AuthGrantType

=over 4

=item * C<AUTH_GRANT_TYPE_UNSPECIFIED> => C<0>

=item * C<AUTH_CODE> => C<1>

=item * C<IMPLICIT> => C<2>

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Actions::Sdk::V2::AccountLinking::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
