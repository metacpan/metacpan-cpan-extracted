package Google::Firestore::Admin::V1::UserCreds;

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
Cipnb29nbGUvZmlyZXN0b3JlL2FkbWluL3YxL3VzZXJfY3JlZHMucHJvdG8SGWdvb2dsZS5m
aXJlc3RvcmUuYWRtaW4udjEaH2dvb2dsZS9hcGkvZmllbGRfYmVoYXZpb3IucHJvdG8aGWdv
b2dsZS9hcGkvcmVzb3VyY2UucHJvdG8aH2dvb2dsZS9wcm90b2J1Zi90aW1lc3RhbXAucHJv
dG8iiQUKCVVzZXJDcmVkcxIXCgRuYW1lGAEgASgJQgPgQQhSBG5hbWUSQAoLY3JlYXRlX3Rp
bWUYAiABKAsyGi5nb29nbGUucHJvdG9idWYuVGltZXN0YW1wQgPgQQNSCmNyZWF0ZVRpbWUS
QAoLdXBkYXRlX3RpbWUYAyABKAsyGi5nb29nbGUucHJvdG9idWYuVGltZXN0YW1wQgPgQQNS
CnVwZGF0ZVRpbWUSRQoFc3RhdGUYBCABKA4yKi5nb29nbGUuZmlyZXN0b3JlLmFkbWluLnYx
LlVzZXJDcmVkcy5TdGF0ZUID4EEDUgVzdGF0ZRIsCg9zZWN1cmVfcGFzc3dvcmQYBSABKAlC
A+BBA1IOc2VjdXJlUGFzc3dvcmQSZAoRcmVzb3VyY2VfaWRlbnRpdHkYBiABKAsyNS5nb29n
bGUuZmlyZXN0b3JlLmFkbWluLnYxLlVzZXJDcmVkcy5SZXNvdXJjZUlkZW50aXR5SABSEHJl
c291cmNlSWRlbnRpdHkaNQoQUmVzb3VyY2VJZGVudGl0eRIhCglwcmluY2lwYWwYASABKAlC
A+BBA1IJcHJpbmNpcGFsIjkKBVN0YXRlEhUKEVNUQVRFX1VOU1BFQ0lGSUVEEAASCwoHRU5B
QkxFRBABEgwKCERJU0FCTEVEEAI6fepBegoiZmlyZXN0b3JlLmdvb2dsZWFwaXMuY29tL1Vz
ZXJDcmVkcxI+cHJvamVjdHMve3Byb2plY3R9L2RhdGFiYXNlcy97ZGF0YWJhc2V9L3VzZXJD
cmVkcy97dXNlcl9jcmVkc30qCXVzZXJDcmVkczIJdXNlckNyZWRzQhMKEVVzZXJDcmVkc0lk
ZW50aXR5Qt0BCh1jb20uZ29vZ2xlLmZpcmVzdG9yZS5hZG1pbi52MUIOVXNlckNyZWRzUHJv
dG9QAVo5Y2xvdWQuZ29vZ2xlLmNvbS9nby9maXJlc3RvcmUvYXBpdjEvYWRtaW4vYWRtaW5w
YjthZG1pbnBiogIER0NGU6oCH0dvb2dsZS5DbG91ZC5GaXJlc3RvcmUuQWRtaW4uVjHKAh9H
b29nbGVcQ2xvdWRcRmlyZXN0b3JlXEFkbWluXFYx6gIjR29vZ2xlOjpDbG91ZDo6RmlyZXN0
b3JlOjpBZG1pbjo6VjFKhRQKBhIEDgBVAQq8BAoBDBIDDgASMrEEIENvcHlyaWdodCAyMDI2
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
ZW5zZS4KCggKAQISAxAAIgoJCgIDABIDEgApCgkKAgMBEgMTACMKCQoCAwISAxQAKQoICgEI
EgMWADwKCQoCCCUSAxYAPAoICgEIEgMXAFAKCQoCCAsSAxcAUAoICgEIEgMYACIKCQoCCAoS
AxgAIgoICgEIEgMZAC8KCQoCCAgSAxkALwoICgEIEgMaADYKCQoCCAESAxoANgoICgEIEgMb
ACIKCQoCCCQSAxsAIgoICgEIEgMcAD0KCQoCCCkSAxwAPQoICgEIEgMdADwKCQoCCC0SAx0A
PAorCgIEABIEIABVARofIEEgQ2xvdWQgRmlyZXN0b3JlIFVzZXIgQ3JlZHMuCgoKCgMEAAES
AyAIEQoLCgMEAAcSBCECJgQKDQoFBAAHnQgSBCECJgQKQgoEBAAEABIEKQIyAxo0IFRoZSBz
dGF0ZSBvZiB0aGUgdXNlciBjcmVkcyAoRU5BQkxFRCBvciBESVNBQkxFRCkuCgoMCgUEAAQA
ARIDKQcMCjcKBgQABAACABIDKwQaGiggVGhlIGRlZmF1bHQgdmFsdWUuIFNob3VsZCBub3Qg
YmUgdXNlZC4KCg4KBwQABAACAAESAysEFQoOCgcEAAQAAgACEgMrGBkKLAoGBAAEAAIBEgMu
BBAaHSBUaGUgdXNlciBjcmVkcyBhcmUgZW5hYmxlZC4KCg4KBwQABAACAQESAy4ECwoOCgcE
AAQAAgECEgMuDg8KLQoGBAAEAAICEgMxBBEaHiBUaGUgdXNlciBjcmVkcyBhcmUgZGlzYWJs
ZWQuCgoOCgcEAAQAAgIBEgMxBAwKDgoHBAAEAAICAhIDMQ8QCjgKBAQAAwASBDUCOQMaKiBE
ZXNjcmliZXMgYSBSZXNvdXJjZSBJZGVudGl0eSBwcmluY2lwYWwuCgoMCgUEAAMAARIDNQoa
CngKBgQAAwACABIDOARFGmkgT3V0cHV0IG9ubHkuIFByaW5jaXBhbCBpZGVudGlmaWVyIHN0
cmluZy4KIFNlZTogaHR0cHM6Ly9jbG91ZC5nb29nbGUuY29tL2lhbS9kb2NzL3ByaW5jaXBh
bC1pZGVudGlmaWVycwoKDgoHBAADAAIABRIDOAQKCg4KBwQAAwACAAESAzgLFAoOCgcEAAMA
AgADEgM4FxgKDgoHBAADAAIACBIDOBlEChEKCgQAAwACAAicCAASAzgaQwqJAQoEBAACABID
PgI9GnwgSWRlbnRpZmllci4gVGhlIHJlc291cmNlIG5hbWUgb2YgdGhlIFVzZXJDcmVkcy4K
IEZvcm1hdDoKIGBwcm9qZWN0cy97cHJvamVjdH0vZGF0YWJhc2VzL3tkYXRhYmFzZX0vdXNl
ckNyZWRzL3t1c2VyX2NyZWRzfWAKCgwKBQQAAgAFEgM+AggKDAoFBAACAAESAz4JDQoMCgUE
AAIAAxIDPhARCgwKBQQAAgAIEgM+EjwKDwoIBAACAAicCAASAz4TOwpCCgQEAAIBEgRBAkIy
GjQgT3V0cHV0IG9ubHkuIFRoZSB0aW1lIHRoZSB1c2VyIGNyZWRzIHdlcmUgY3JlYXRlZC4K
CgwKBQQAAgEGEgNBAhsKDAoFBAACAQESA0EcJwoMCgUEAAIBAxIDQSorCgwKBQQAAgEIEgNC
BjEKDwoIBAACAQicCAASA0IHMApHCgQEAAICEgRFAkYyGjkgT3V0cHV0IG9ubHkuIFRoZSB0
aW1lIHRoZSB1c2VyIGNyZWRzIHdlcmUgbGFzdCB1cGRhdGVkLgoKDAoFBAACAgYSA0UCGwoM
CgUEAAICARIDRRwnCgwKBQQAAgIDEgNFKisKDAoFBAACAggSA0YGMQoPCggEAAICCJwIABID
RgcwCm0KBAQAAgMSA0oCPhpgIE91dHB1dCBvbmx5LiBXaGV0aGVyIHRoZSB1c2VyIGNyZWRz
IGFyZSBlbmFibGVkIG9yIGRpc2FibGVkLiBEZWZhdWx0cyB0bwogRU5BQkxFRCBvbiBjcmVh
dGlvbi4KCgwKBQQAAgMGEgNKAgcKDAoFBAACAwESA0oIDQoMCgUEAAIDAxIDShARCgwKBQQA
AgMIEgNKEj0KDwoIBAACAwicCAASA0oTPAqgAQoEBAACBBIDTgJJGpIBIE91dHB1dCBvbmx5
LiBUaGUgcGxhaW50ZXh0IHNlcnZlci1nZW5lcmF0ZWQgcGFzc3dvcmQgZm9yIHRoZSB1c2Vy
IGNyZWRzLgogT25seSBwb3B1bGF0ZWQgaW4gcmVzcG9uc2VzIGZvciBDcmVhdGVVc2VyQ3Jl
ZHMgYW5kIFJlc2V0VXNlclBhc3N3b3JkLgoKDAoFBAACBAUSA04CCAoMCgUEAAIEARIDTgkY
CgwKBQQAAgQDEgNOGxwKDAoFBAACBAgSA04dSAoPCggEAAIECJwIABIDTh5HCjkKBAQACAAS
BFECVAMaKyBJZGVudGl0eSBhc3NvY2lhdGVkIHdpdGggdGhpcyBVc2VyIENyZWRzLgoKDAoF
BAAIAAESA1EIGQosCgQEAAIFEgNTBCsaHyBSZXNvdXJjZSBJZGVudGl0eSBkZXNjcmlwdG9y
LgoKDAoFBAACBQYSA1MEFAoMCgUEAAIFARIDUxUmCgwKBQQAAgUDEgNTKSpiBnByb3RvMw==

EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Firestore::Admin::V1::UserCreds::UserCreds ===
    # Fields for UserCreds
    # Field: name Type: 9 ()
    # Field: create_time Type: 11 (.google.protobuf.Timestamp)
    # Field: update_time Type: 11 (.google.protobuf.Timestamp)
    # Field: state Type: 14 (.google.firestore.admin.v1.UserCreds.State)
    # Field: secure_password Type: 9 ()
    # Field: resource_identity Type: 11 (.google.firestore.admin.v1.UserCreds.ResourceIdentity)

# Enum: UserCreds::State
our $UserCreds_STATE_UNSPECIFIED = 0;
our $UserCreds_ENABLED = 1;
our $UserCreds_DISABLED = 2;

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Firestore::Admin::V1::UserCreds - Compiled Protocol Buffers messages for google/firestore/admin/v1/user_creds.proto

=head1 SYNOPSIS

    use Google::Firestore::Admin::V1::UserCreds;

    my $msg = Google::Firestore::Admin::V1::UserCreds::UserCreds->new({
        name => $name,
        create_time => $create_time,
        update_time => $update_time,
        state => $state,
    });

    # Read or update a field
    my $val = $msg->name();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Firestore::Admin::V1::UserCreds::UserCreds->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/firestore/admin/v1/user_creds.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Firestore::Admin::V1::UserCreds::UserCreds

A Cloud Firestore User Creds.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Identifier. The resource name of the UserCreds.
Format:
`projects/{project}/databases/{database}/userCreds/{user_creds}`

=item * C<< $msg->create_time() >> / C<< $msg->create_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Output only. The time the user creds were created.

=item * C<< $msg->update_time() >> / C<< $msg->update_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Output only. The time the user creds were last updated.

=item * C<< $msg->state() >> / C<< $msg->state($value) >>

Type: C<Enum> (L<Google::Firestore::Admin::V1::UserCreds::State>)

Output only. Whether the user creds are enabled or disabled. Defaults to
ENABLED on creation.

=item * C<< $msg->secure_password() >> / C<< $msg->secure_password($value) >>

Type: C<String>

Output only. The plaintext server-generated password for the user creds.
Only populated in responses for CreateUserCreds and ResetUserPassword.

=item * C<< $msg->resource_identity() >> / C<< $msg->resource_identity($value) >>

Type: C<Message> (L<Google::Firestore::Admin::V1::UserCreds::UserCreds::ResourceIdentity>)

Resource Identity descriptor.

=back

=head3 Enum: UserCreds::State

=over 4

=item * C<STATE_UNSPECIFIED> => C<0>

=item * C<ENABLED> => C<1>

=item * C<DISABLED> => C<2>

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Firestore::Admin::V1::UserCreds::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
