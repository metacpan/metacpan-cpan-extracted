package Google::Cloud::Identitytoolkit::V2::MfaInfo;

use strict;
use warnings;

our $VERSION = '0.14';

use Protobuf::Message;
use Protobuf::DescriptorPool;
use Protobuf::Internal qw(:all);
use MIME::Base64;

BEGIN {
    eval { require Google::Protobuf::Timestamp };
    my $descriptor_b64 = <<'EOF';
Ci5nb29nbGUvY2xvdWQvaWRlbnRpdHl0b29sa2l0L3YyL21mYV9pbmZvLnByb3RvEh9nb29n
bGUuY2xvdWQuaWRlbnRpdHl0b29sa2l0LnYyGh9nb29nbGUvcHJvdG9idWYvdGltZXN0YW1w
LnByb3RvIkEKEUF1dG9SZXRyaWV2YWxJbmZvEiwKEmFwcF9zaWduYXR1cmVfaGFzaBgBIAEo
CVIQYXBwU2lnbmF0dXJlSGFzaCK0AgoYU3RhcnRNZmFQaG9uZVJlcXVlc3RJbmZvEiEKDHBo
b25lX251bWJlchgBIAEoCVILcGhvbmVOdW1iZXISHwoLaW9zX3JlY2VpcHQYAiABKAlSCmlv
c1JlY2VpcHQSHQoKaW9zX3NlY3JldBgDIAEoCVIJaW9zU2VjcmV0EicKD3JlY2FwdGNoYV90
b2tlbhgEIAEoCVIOcmVjYXB0Y2hhVG9rZW4SYgoTYXV0b19yZXRyaWV2YWxfaW5mbxgFIAEo
CzIyLmdvb2dsZS5jbG91ZC5pZGVudGl0eXRvb2xraXQudjIuQXV0b1JldHJpZXZhbEluZm9S
EWF1dG9SZXRyaWV2YWxJbmZvEigKEHNhZmV0eV9uZXRfdG9rZW4YBiABKAlSDnNhZmV0eU5l
dFRva2VuIj4KGVN0YXJ0TWZhUGhvbmVSZXNwb25zZUluZm8SIQoMc2Vzc2lvbl9pbmZvGAEg
ASgJUgtzZXNzaW9uSW5mbyK1AQobRmluYWxpemVNZmFQaG9uZVJlcXVlc3RJbmZvEiEKDHNl
c3Npb25faW5mbxgBIAEoCVILc2Vzc2lvbkluZm8SEgoEY29kZRgCIAEoCVIEY29kZRI8Chph
bmRyb2lkX3ZlcmlmaWNhdGlvbl9wcm9vZhgDIAEoCVIYYW5kcm9pZFZlcmlmaWNhdGlvblBy
b29mEiEKDHBob25lX251bWJlchgEIAEoCVILcGhvbmVOdW1iZXIi7wEKHEZpbmFsaXplTWZh
UGhvbmVSZXNwb25zZUluZm8SPAoaYW5kcm9pZF92ZXJpZmljYXRpb25fcHJvb2YYASABKAlS
GGFuZHJvaWRWZXJpZmljYXRpb25Qcm9vZhJuCiZhbmRyb2lkX3ZlcmlmaWNhdGlvbl9wcm9v
Zl9leHBpcmVfdGltZRgCIAEoCzIaLmdvb2dsZS5wcm90b2J1Zi5UaW1lc3RhbXBSImFuZHJv
aWRWZXJpZmljYXRpb25Qcm9vZkV4cGlyZVRpbWUSIQoMcGhvbmVfbnVtYmVyGAMgASgJUgtw
aG9uZU51bWJlckLfAQojY29tLmdvb2dsZS5jbG91ZC5pZGVudGl0eXRvb2xraXQudjJQAVpN
Y2xvdWQuZ29vZ2xlLmNvbS9nby9pZGVudGl0eXRvb2xraXQvYXBpdjIvaWRlbnRpdHl0b29s
a2l0cGI7aWRlbnRpdHl0b29sa2l0cGKqAh9Hb29nbGUuQ2xvdWQuSWRlbnRpdHlUb29sa2l0
LlYyygIfR29vZ2xlXENsb3VkXElkZW50aXR5VG9vbGtpdFxWMuoCIkdvb2dsZTo6Q2xvdWQ6
OklkZW50aXR5VG9vbGtpdDo6VjJKmBgKBhIEDgBbAQq8BAoBDBIDDgASMrEEIENvcHlyaWdo
dCAyMDI1IEdvb2dsZSBMTEMKCiBMaWNlbnNlZCB1bmRlciB0aGUgQXBhY2hlIExpY2Vuc2Us
IFZlcnNpb24gMi4wICh0aGUgIkxpY2Vuc2UiKTsKIHlvdSBtYXkgbm90IHVzZSB0aGlzIGZp
bGUgZXhjZXB0IGluIGNvbXBsaWFuY2Ugd2l0aCB0aGUgTGljZW5zZS4KIFlvdSBtYXkgb2J0
YWluIGEgY29weSBvZiB0aGUgTGljZW5zZSBhdAoKICAgICBodHRwOi8vd3d3LmFwYWNoZS5v
cmcvbGljZW5zZXMvTElDRU5TRS0yLjAKCiBVbmxlc3MgcmVxdWlyZWQgYnkgYXBwbGljYWJs
ZSBsYXcgb3IgYWdyZWVkIHRvIGluIHdyaXRpbmcsIHNvZnR3YXJlCiBkaXN0cmlidXRlZCB1
bmRlciB0aGUgTGljZW5zZSBpcyBkaXN0cmlidXRlZCBvbiBhbiAiQVMgSVMiIEJBU0lTLAog
V0lUSE9VVCBXQVJSQU5USUVTIE9SIENPTkRJVElPTlMgT0YgQU5ZIEtJTkQsIGVpdGhlciBl
eHByZXNzIG9yIGltcGxpZWQuCiBTZWUgdGhlIExpY2Vuc2UgZm9yIHRoZSBzcGVjaWZpYyBs
YW5ndWFnZSBnb3Zlcm5pbmcgcGVybWlzc2lvbnMgYW5kCiBsaW1pdGF0aW9ucyB1bmRlciB0
aGUgTGljZW5zZS4KCggKAQISAxAAKAoJCgIDABIDEgApCggKAQgSAxQAPAoJCgIIJRIDFAA8
CggKAQgSAxUAZAoJCgIICxIDFQBkCggKAQgSAxYAIgoJCgIIChIDFgAiCggKAQgSAxcAPAoJ
CgIIARIDFwA8CggKAQgSAxgAPAoJCgIIKRIDGAA8CggKAQgSAxkAOwoJCgIILRIDGQA7Cj8K
AgQAEgQcACABGjMgVGhlIGluZm9ybWF0aW9uIHJlcXVpcmVkIHRvIGF1dG8tcmV0cmlldmUg
YW4gU01TLgoKCgoDBAABEgMcCBkKXQoEBAACABIDHwIgGlAgVGhlIEFuZHJvaWQgYXBwJ3Mg
c2lnbmF0dXJlIGhhc2ggZm9yIEdvb2dsZSBQbGF5IFNlcnZpY2UncwogU01TIFJldHJpZXZl
ciBBUEkuCgoMCgUEAAIABRIDHwIICgwKBQQAAgABEgMfCRsKDAoFBAACAAMSAx8eHwo7CgIE
ARIEIwA6ARovIEFwcCBWZXJpZmljYXRpb24gaW5mbyBmb3IgYSBTdGFydE1mYSByZXF1ZXN0
LgoKCgoDBAEBEgMjCCAKSwoEBAECABIDJQIaGj4gUmVxdWlyZWQgZm9yIGVucm9sbG1lbnQu
IFBob25lIG51bWJlciB0byBiZSBlbnJvbGxlZCBhcyBNRkEuCgoMCgUEAQIABRIDJQIICgwK
BQQBAgABEgMlCRUKDAoFBAECAAMSAyUYGQpOCgQEAQIBEgMoAhkaQSBpT1Mgb25seS4gUmVj
ZWlwdCBvZiBzdWNjZXNzZnVsIGFwcCB0b2tlbiB2YWxpZGF0aW9uIHdpdGggQVBOUy4KCgwK
BQQBAgEFEgMoAggKDAoFBAECAQESAygJFAoMCgUEAQIBAxIDKBcYCj4KBAQBAgISAysCGBox
IGlPUyBvbmx5LiBTZWNyZXQgZGVsaXZlcmVkIHRvIGlPUyBhcHAgdmlhIEFQTlMuCgoMCgUE
AQICBRIDKwIICgwKBQQBAgIBEgMrCRMKDAoFBAECAgMSAysWFwosCgQEAQIDEgMuAh0aHyBX
ZWIgb25seS4gUmVjYXB0Y2hhIHNvbHV0aW9uLgoKDAoFBAECAwUSAy4CCAoMCgUEAQIDARID
LgkYCgwKBQQBAgMDEgMuGxwKYgoEBAECBBIDMgIsGlUgQW5kcm9pZCBvbmx5LiBVc2VkIGJ5
IEdvb2dsZSBQbGF5IFNlcnZpY2VzIHRvIGlkZW50aWZ5IHRoZSBhcHAgZm9yCiBhdXRvLXJl
dHJpZXZhbC4KCgwKBQQBAgQGEgMyAhMKDAoFBAECBAESAzIUJwoMCgUEAQIEAxIDMiorCroC
CgQEAQIFEgM5Ah4arAIgQW5kcm9pZCBvbmx5LiBVc2VkIHRvIGFzc2VydCBhcHBsaWNhdGlv
biBpZGVudGl0eSBpbiBwbGFjZSBvZiBhCiByZWNhcHRjaGEgdG9rZW4uIEEgU2FmZXR5TmV0
IFRva2VuIGNhbiBiZSBnZW5lcmF0ZWQgdmlhIHRoZQogW1NhZmV0eU5ldCBBbmRyb2lkIEF0
dGVzdGF0aW9uCiBBUEldKGh0dHBzOi8vZGV2ZWxvcGVyLmFuZHJvaWQuY29tL3RyYWluaW5n
L3NhZmV0eW5ldC9hdHRlc3RhdGlvbi5odG1sKSwKIHdpdGggdGhlIEJhc2U2NCBlbmNvZGlu
ZyBvZiB0aGUgYHBob25lX251bWJlcmAgZmllbGQgYXMgdGhlIG5vbmNlLgoKDAoFBAECBQUS
AzkCCAoMCgUEAQIFARIDOQkZCgwKBQQBAgUDEgM5HB0KPgoCBAISBD0AQAEaMiBQaG9uZSBW
ZXJpZmljYXRpb24gaW5mbyBmb3IgYSBTdGFydE1mYSByZXNwb25zZS4KCgoKAwQCARIDPQgh
CkcKBAQCAgASAz8CGho6IEFuIG9wYXF1ZSBzdHJpbmcgdGhhdCByZXByZXNlbnRzIHRoZSBl
bnJvbGxtZW50IHNlc3Npb24uCgoMCgUEAgIABRIDPwIICgwKBQQCAgABEgM/CRUKDAoFBAIC
AAMSAz8YGQpACgIEAxIEQwBPARo0IFBob25lIFZlcmlmaWNhdGlvbiBpbmZvIGZvciBhIEZp
bmFsaXplTWZhIHJlcXVlc3QuCgoKCgMEAwESA0MIIwpHCgQEAwIAEgNFAhoaOiBBbiBvcGFx
dWUgc3RyaW5nIHRoYXQgcmVwcmVzZW50cyB0aGUgZW5yb2xsbWVudCBzZXNzaW9uLgoKDAoF
BAMCAAUSA0UCCAoMCgUEAwIAARIDRQkVCgwKBQQDAgADEgNFGBkKLgoEBAMCARIDSAISGiEg
VXNlci1lbnRlcmVkIHZlcmlmaWNhdGlvbiBjb2RlLgoKDAoFBAMCAQUSA0gCCAoMCgUEAwIB
ARIDSAkNCgwKBQQDAgEDEgNIEBEKWQoEBAMCAhIDSwIoGkwgQW5kcm9pZCBvbmx5LiBVc2Vz
IGZvciAiaW5zdGFudCIgcGhvbmUgbnVtYmVyIHZlcmlmaWNhdGlvbiB0aG91Z2ggR21zQ29y
ZS4KCgwKBQQDAgIFEgNLAggKDAoFBAMCAgESA0sJIwoMCgUEAwICAxIDSyYnCkMKBAQDAgMS
A04CGho2IFJlcXVpcmVkIGlmIEFuZHJvaWQgdmVyaWZpY2F0aW9uIHByb29mIGlzIHByZXNl
bnRlZC4KCgwKBQQDAgMFEgNOAggKDAoFBAMCAwESA04JFQoMCgUEAwIDAxIDThgZCkEKAgQE
EgRSAFsBGjUgUGhvbmUgVmVyaWZpY2F0aW9uIGluZm8gZm9yIGEgRmluYWxpemVNZmEgcmVz
cG9uc2UuCgoKCgMEBAESA1IIJApaCgQEBAIAEgNUAigaTSBBbmRyb2lkIG9ubHkuIExvbmct
bGl2ZWQgcmVwbGFjZW1lbnQgZm9yIHZhbGlkIGNvZGUgdGllZCB0byBhbmRyb2lkIGRldmlj
ZS4KCgwKBQQEAgAFEgNUAggKDAoFBAQCAAESA1QJIwoMCgUEBAIAAxIDVCYnCk4KBAQEAgES
A1cCRxpBIEFuZHJvaWQgb25seS4gRXhwaXJhdGlvbiB0aW1lIG9mIHZlcmlmaWNhdGlvbiBw
cm9vZiBpbiBzZWNvbmRzLgoKDAoFBAQCAQYSA1cCGwoMCgUEBAIBARIDVxxCCgwKBQQEAgED
EgNXRUYKLgoEBAQCAhIDWgIaGiEgRm9yIEFuZHJvaWQgdmVyaWZpY2F0aW9uIHByb29mLgoK
DAoFBAQCAgUSA1oCCAoMCgUEBAICARIDWgkVCgwKBQQEAgIDEgNaGBliBnByb3RvMw==
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Identitytoolkit::V2::MfaInfo::AutoRetrievalInfo ===
    # Fields for AutoRetrievalInfo
    # Field: app_signature_hash Type: 9 ()

# === Message: Google::Cloud::Identitytoolkit::V2::MfaInfo::StartMfaPhoneRequestInfo ===
    # Fields for StartMfaPhoneRequestInfo
    # Field: phone_number Type: 9 ()
    # Field: ios_receipt Type: 9 ()
    # Field: ios_secret Type: 9 ()
    # Field: recaptcha_token Type: 9 ()
    # Field: auto_retrieval_info Type: 11 (.google.cloud.identitytoolkit.v2.AutoRetrievalInfo)
    # Field: safety_net_token Type: 9 ()

# === Message: Google::Cloud::Identitytoolkit::V2::MfaInfo::StartMfaPhoneResponseInfo ===
    # Fields for StartMfaPhoneResponseInfo
    # Field: session_info Type: 9 ()

# === Message: Google::Cloud::Identitytoolkit::V2::MfaInfo::FinalizeMfaPhoneRequestInfo ===
    # Fields for FinalizeMfaPhoneRequestInfo
    # Field: session_info Type: 9 ()
    # Field: code Type: 9 ()
    # Field: android_verification_proof Type: 9 ()
    # Field: phone_number Type: 9 ()

# === Message: Google::Cloud::Identitytoolkit::V2::MfaInfo::FinalizeMfaPhoneResponseInfo ===
    # Fields for FinalizeMfaPhoneResponseInfo
    # Field: android_verification_proof Type: 9 ()
    # Field: android_verification_proof_expire_time Type: 11 (.google.protobuf.Timestamp)
    # Field: phone_number Type: 9 ()

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Identitytoolkit::V2::MfaInfo - Compiled Protocol Buffers messages for google/cloud/identitytoolkit/v2/mfa_info.proto

=head1 SYNOPSIS

    use Google::Cloud::Identitytoolkit::V2::MfaInfo;

    my $msg = Google::Cloud::Identitytoolkit::V2::MfaInfo::AutoRetrievalInfo->new({
        app_signature_hash => $app_signature_hash,
    });

    # Read or update a field
    my $val = $msg->app_signature_hash();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Identitytoolkit::V2::MfaInfo::AutoRetrievalInfo->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/identitytoolkit/v2/mfa_info.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Identitytoolkit::V2::MfaInfo::AutoRetrievalInfo

The information required to auto-retrieve an SMS.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->app_signature_hash() >> / C<< $msg->app_signature_hash($value) >>

Type: C<String>

The Android app's signature hash for Google Play Service's
SMS Retriever API.

=back

=head2 Google::Cloud::Identitytoolkit::V2::MfaInfo::StartMfaPhoneRequestInfo

App Verification info for a StartMfa request.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->phone_number() >> / C<< $msg->phone_number($value) >>

Type: C<String>

Required for enrollment. Phone number to be enrolled as MFA.

=item * C<< $msg->ios_receipt() >> / C<< $msg->ios_receipt($value) >>

Type: C<String>

iOS only. Receipt of successful app token validation with APNS.

=item * C<< $msg->ios_secret() >> / C<< $msg->ios_secret($value) >>

Type: C<String>

iOS only. Secret delivered to iOS app via APNS.

=item * C<< $msg->recaptcha_token() >> / C<< $msg->recaptcha_token($value) >>

Type: C<String>

Web only. Recaptcha solution.

=item * C<< $msg->auto_retrieval_info() >> / C<< $msg->auto_retrieval_info($value) >>

Type: C<Message> (L<Google::Cloud::Identitytoolkit::V2::MfaInfo::AutoRetrievalInfo>)

Android only. Used by Google Play Services to identify the app for
auto-retrieval.

=item * C<< $msg->safety_net_token() >> / C<< $msg->safety_net_token($value) >>

Type: C<String>

Android only. Used to assert application identity in place of a
recaptcha token. A SafetyNet Token can be generated via the
[SafetyNet Android Attestation
API](https://developer.android.com/training/safetynet/attestation.html),
with the Base64 encoding of the `phone_number` field as the nonce.

=back

=head2 Google::Cloud::Identitytoolkit::V2::MfaInfo::StartMfaPhoneResponseInfo

Phone Verification info for a StartMfa response.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->session_info() >> / C<< $msg->session_info($value) >>

Type: C<String>

An opaque string that represents the enrollment session.

=back

=head2 Google::Cloud::Identitytoolkit::V2::MfaInfo::FinalizeMfaPhoneRequestInfo

Phone Verification info for a FinalizeMfa request.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->session_info() >> / C<< $msg->session_info($value) >>

Type: C<String>

An opaque string that represents the enrollment session.

=item * C<< $msg->code() >> / C<< $msg->code($value) >>

Type: C<String>

User-entered verification code.

=item * C<< $msg->android_verification_proof() >> / C<< $msg->android_verification_proof($value) >>

Type: C<String>

Android only. Uses for "instant" phone number verification though GmsCore.

=item * C<< $msg->phone_number() >> / C<< $msg->phone_number($value) >>

Type: C<String>

Required if Android verification proof is presented.

=back

=head2 Google::Cloud::Identitytoolkit::V2::MfaInfo::FinalizeMfaPhoneResponseInfo

Phone Verification info for a FinalizeMfa response.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->android_verification_proof() >> / C<< $msg->android_verification_proof($value) >>

Type: C<String>

Android only. Long-lived replacement for valid code tied to android device.

=item * C<< $msg->android_verification_proof_expire_time() >> / C<< $msg->android_verification_proof_expire_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Android only. Expiration time of verification proof in seconds.

=item * C<< $msg->phone_number() >> / C<< $msg->phone_number($value) >>

Type: C<String>

For Android verification proof.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Identitytoolkit::V2::MfaInfo::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
