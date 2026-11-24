package Google::Iam::V2::Deny;

use strict;
use warnings;

our $VERSION = '0.14';

use Protobuf::Message;
use Protobuf::DescriptorPool;
use Protobuf::Internal qw(:all);
use MIME::Base64;

BEGIN {
    eval { require Google::Type::Expr };
    my $descriptor_b64 = <<'EOF';
Chhnb29nbGUvaWFtL3YyL2RlbnkucHJvdG8SDWdvb2dsZS5pYW0udjIaFmdvb2dsZS90eXBl
L2V4cHIucHJvdG8ijAIKCERlbnlSdWxlEisKEWRlbmllZF9wcmluY2lwYWxzGAEgAygJUhBk
ZW5pZWRQcmluY2lwYWxzEjEKFGV4Y2VwdGlvbl9wcmluY2lwYWxzGAIgAygJUhNleGNlcHRp
b25QcmluY2lwYWxzEi0KEmRlbmllZF9wZXJtaXNzaW9ucxgDIAMoCVIRZGVuaWVkUGVybWlz
c2lvbnMSMwoVZXhjZXB0aW9uX3Blcm1pc3Npb25zGAQgAygJUhRleGNlcHRpb25QZXJtaXNz
aW9ucxI8ChBkZW5pYWxfY29uZGl0aW9uGAUgASgLMhEuZ29vZ2xlLnR5cGUuRXhwclIPZGVu
aWFsQ29uZGl0aW9uQnsKEWNvbS5nb29nbGUuaWFtLnYyQg1EZW55UnVsZVByb3RvUAFaKWNs
b3VkLmdvb2dsZS5jb20vZ28vaWFtL2FwaXYyL2lhbXBiO2lhbXBiqgITR29vZ2xlLkNsb3Vk
LklhbS5WMsoCE0dvb2dsZVxDbG91ZFxJYW1cVjJKxyUKBhIEDgBsAQq8BAoBDBIDDgASMrEE
IENvcHlyaWdodCAyMDI1IEdvb2dsZSBMTEMKCiBMaWNlbnNlZCB1bmRlciB0aGUgQXBhY2hl
IExpY2Vuc2UsIFZlcnNpb24gMi4wICh0aGUgIkxpY2Vuc2UiKTsKIHlvdSBtYXkgbm90IHVz
ZSB0aGlzIGZpbGUgZXhjZXB0IGluIGNvbXBsaWFuY2Ugd2l0aCB0aGUgTGljZW5zZS4KIFlv
dSBtYXkgb2J0YWluIGEgY29weSBvZiB0aGUgTGljZW5zZSBhdAoKICAgICBodHRwOi8vd3d3
LmFwYWNoZS5vcmcvbGljZW5zZXMvTElDRU5TRS0yLjAKCiBVbmxlc3MgcmVxdWlyZWQgYnkg
YXBwbGljYWJsZSBsYXcgb3IgYWdyZWVkIHRvIGluIHdyaXRpbmcsIHNvZnR3YXJlCiBkaXN0
cmlidXRlZCB1bmRlciB0aGUgTGljZW5zZSBpcyBkaXN0cmlidXRlZCBvbiBhbiAiQVMgSVMi
IEJBU0lTLAogV0lUSE9VVCBXQVJSQU5USUVTIE9SIENPTkRJVElPTlMgT0YgQU5ZIEtJTkQs
IGVpdGhlciBleHByZXNzIG9yIGltcGxpZWQuCiBTZWUgdGhlIExpY2Vuc2UgZm9yIHRoZSBz
cGVjaWZpYyBsYW5ndWFnZSBnb3Zlcm5pbmcgcGVybWlzc2lvbnMgYW5kCiBsaW1pdGF0aW9u
cyB1bmRlciB0aGUgTGljZW5zZS4KCggKAQISAxAAFgoJCgIDABIDEgAgCggKAQgSAxQAMAoJ
CgIIJRIDFAAwCggKAQgSAxUAQAoJCgIICxIDFQBACggKAQgSAxYAIgoJCgIIChIDFgAiCggK
AQgSAxcALgoJCgIICBIDFwAuCggKAQgSAxgAKgoJCgIIARIDGAAqCggKAQgSAxkAMAoJCgII
KRIDGQAwCjAKAgQAEgQcAGwBGiQgQSBkZW55IHJ1bGUgaW4gYW4gSUFNIGRlbnkgcG9saWN5
LgoKCgoDBAABEgMcCBAKlhEKBAQAAgASA0UCKBqIESBUaGUgaWRlbnRpdGllcyB0aGF0IGFy
ZSBwcmV2ZW50ZWQgZnJvbSB1c2luZyBvbmUgb3IgbW9yZSBwZXJtaXNzaW9ucyBvbgogR29v
Z2xlIENsb3VkIHJlc291cmNlcy4gVGhpcyBmaWVsZCBjYW4gY29udGFpbiB0aGUgZm9sbG93
aW5nIHZhbHVlczoKCiAqIGBwcmluY2lwYWxTZXQ6Ly9nb29nL3B1YmxpYzphbGxgOiBBIHNw
ZWNpYWwgaWRlbnRpZmllciB0aGF0IHJlcHJlc2VudHMKICAgYW55IHByaW5jaXBhbCB0aGF0
IGlzIG9uIHRoZSBpbnRlcm5ldCwgZXZlbiBpZiB0aGV5IGRvIG5vdCBoYXZlIGEgR29vZ2xl
CiAgIEFjY291bnQgb3IgYXJlIG5vdCBsb2dnZWQgaW4uCgogKiBgcHJpbmNpcGFsOi8vZ29v
Zy9zdWJqZWN0L3tlbWFpbF9pZH1gOiBBIHNwZWNpZmljIEdvb2dsZSBBY2NvdW50LgogICBJ
bmNsdWRlcyBHbWFpbCwgQ2xvdWQgSWRlbnRpdHksIGFuZCBHb29nbGUgV29ya3NwYWNlIHVz
ZXIgYWNjb3VudHMuIEZvcgogICBleGFtcGxlLCBgcHJpbmNpcGFsOi8vZ29vZy9zdWJqZWN0
L2FsaWNlQGV4YW1wbGUuY29tYC4KCiAqIGBkZWxldGVkOnByaW5jaXBhbDovL2dvb2cvc3Vi
amVjdC97ZW1haWxfaWR9P3VpZD17dWlkfWA6IEEgc3BlY2lmaWMKICAgR29vZ2xlIEFjY291
bnQgdGhhdCB3YXMgZGVsZXRlZCByZWNlbnRseS4gRm9yIGV4YW1wbGUsCiAgIGBkZWxldGVk
OnByaW5jaXBhbDovL2dvb2cvc3ViamVjdC9hbGljZUBleGFtcGxlLmNvbT91aWQ9MTIzNDU2
Nzg5MGAuIElmCiAgIHRoZSBHb29nbGUgQWNjb3VudCBpcyByZWNvdmVyZWQsIHRoaXMgaWRl
bnRpZmllciByZXZlcnRzIHRvIHRoZSBzdGFuZGFyZAogICBpZGVudGlmaWVyIGZvciBhIEdv
b2dsZSBBY2NvdW50LgoKICogYHByaW5jaXBhbFNldDovL2dvb2cvZ3JvdXAve2dyb3VwX2lk
fWA6IEEgR29vZ2xlIGdyb3VwLiBGb3IgZXhhbXBsZSwKICAgYHByaW5jaXBhbFNldDovL2dv
b2cvZ3JvdXAvYWRtaW5zQGV4YW1wbGUuY29tYC4KCiAqIGBkZWxldGVkOnByaW5jaXBhbFNl
dDovL2dvb2cvZ3JvdXAve2dyb3VwX2lkfT91aWQ9e3VpZH1gOiBBIEdvb2dsZSBncm91cAog
ICB0aGF0IHdhcyBkZWxldGVkIHJlY2VudGx5LiBGb3IgZXhhbXBsZSwKICAgYGRlbGV0ZWQ6
cHJpbmNpcGFsU2V0Oi8vZ29vZy9ncm91cC9hZG1pbnNAZXhhbXBsZS5jb20/dWlkPTEyMzQ1
Njc4OTBgLiBJZgogICB0aGUgR29vZ2xlIGdyb3VwIGlzIHJlc3RvcmVkLCB0aGlzIGlkZW50
aWZpZXIgcmV2ZXJ0cyB0byB0aGUgc3RhbmRhcmQKICAgaWRlbnRpZmllciBmb3IgYSBHb29n
bGUgZ3JvdXAuCgogKiBgcHJpbmNpcGFsOi8vaWFtLmdvb2dsZWFwaXMuY29tL3Byb2plY3Rz
Ly0vc2VydmljZUFjY291bnRzL3tzZXJ2aWNlX2FjY291bnRfaWR9YDoKICAgQSBHb29nbGUg
Q2xvdWQgc2VydmljZSBhY2NvdW50LiBGb3IgZXhhbXBsZSwKICAgYHByaW5jaXBhbDovL2lh
bS5nb29nbGVhcGlzLmNvbS9wcm9qZWN0cy8tL3NlcnZpY2VBY2NvdW50cy9teS1zZXJ2aWNl
LWFjY291bnRAaWFtLmdzZXJ2aWNlYWNjb3VudC5jb21gLgoKICogYGRlbGV0ZWQ6cHJpbmNp
cGFsOi8vaWFtLmdvb2dsZWFwaXMuY29tL3Byb2plY3RzLy0vc2VydmljZUFjY291bnRzL3tz
ZXJ2aWNlX2FjY291bnRfaWR9P3VpZD17dWlkfWA6CiAgIEEgR29vZ2xlIENsb3VkIHNlcnZp
Y2UgYWNjb3VudCB0aGF0IHdhcyBkZWxldGVkIHJlY2VudGx5LiBGb3IgZXhhbXBsZSwKICAg
YGRlbGV0ZWQ6cHJpbmNpcGFsOi8vaWFtLmdvb2dsZWFwaXMuY29tL3Byb2plY3RzLy0vc2Vy
dmljZUFjY291bnRzL215LXNlcnZpY2UtYWNjb3VudEBpYW0uZ3NlcnZpY2VhY2NvdW50LmNv
bT91aWQ9MTIzNDU2Nzg5MGAuCiAgIElmIHRoZSBzZXJ2aWNlIGFjY291bnQgaXMgdW5kZWxl
dGVkLCB0aGlzIGlkZW50aWZpZXIgcmV2ZXJ0cyB0byB0aGUKICAgc3RhbmRhcmQgaWRlbnRp
ZmllciBmb3IgYSBzZXJ2aWNlIGFjY291bnQuCgogKiBgcHJpbmNpcGFsU2V0Oi8vZ29vZy9j
bG91ZElkZW50aXR5Q3VzdG9tZXJJZC97Y3VzdG9tZXJfaWR9YDogQWxsIG9mIHRoZQogICBw
cmluY2lwYWxzIGFzc29jaWF0ZWQgd2l0aCB0aGUgc3BlY2lmaWVkIEdvb2dsZSBXb3Jrc3Bh
Y2Ugb3IgQ2xvdWQKICAgSWRlbnRpdHkgY3VzdG9tZXIgSUQuIEZvciBleGFtcGxlLAogICBg
cHJpbmNpcGFsU2V0Oi8vZ29vZy9jbG91ZElkZW50aXR5Q3VzdG9tZXJJZC9DMDFBYmMzNWAu
CgoMCgUEAAIABBIDRQIKCgwKBQQAAgAFEgNFCxEKDAoFBAACAAESA0USIwoMCgUEAAIAAxID
RSYnCpwDCgQEAAIBEgNPAisajgMgVGhlIGlkZW50aXRpZXMgdGhhdCBhcmUgZXhjbHVkZWQg
ZnJvbSB0aGUgZGVueSBydWxlLCBldmVuIGlmIHRoZXkgYXJlCiBsaXN0ZWQgaW4gdGhlIGBk
ZW5pZWRfcHJpbmNpcGFsc2AuIEZvciBleGFtcGxlLCB5b3UgY291bGQgYWRkIGEgR29vZ2xl
CiBncm91cCB0byB0aGUgYGRlbmllZF9wcmluY2lwYWxzYCwgdGhlbiBleGNsdWRlIHNwZWNp
ZmljIHVzZXJzIHdobyBiZWxvbmcgdG8KIHRoYXQgZ3JvdXAuCgogVGhpcyBmaWVsZCBjYW4g
Y29udGFpbiB0aGUgc2FtZSB2YWx1ZXMgYXMgdGhlIGBkZW5pZWRfcHJpbmNpcGFsc2AgZmll
bGQsCiBleGNsdWRpbmcgYHByaW5jaXBhbFNldDovL2dvb2cvcHVibGljOmFsbGAsIHdoaWNo
IHJlcHJlc2VudHMgYWxsIHVzZXJzIG9uCiB0aGUgaW50ZXJuZXQuCgoMCgUEAAIBBBIDTwIK
CgwKBQQAAgEFEgNPCxEKDAoFBAACAQESA08SJgoMCgUEAAIBAxIDTykqCogCCgQEAAICEgNV
Aika+gEgVGhlIHBlcm1pc3Npb25zIHRoYXQgYXJlIGV4cGxpY2l0bHkgZGVuaWVkIGJ5IHRo
aXMgcnVsZS4gRWFjaCBwZXJtaXNzaW9uCiB1c2VzIHRoZSBmb3JtYXQgYHtzZXJ2aWNlX2Zx
ZG59L3tyZXNvdXJjZX0ue3ZlcmJ9YCwgd2hlcmUgYHtzZXJ2aWNlX2ZxZG59YAogaXMgdGhl
IGZ1bGx5IHF1YWxpZmllZCBkb21haW4gbmFtZSBmb3IgdGhlIHNlcnZpY2UuIEZvciBleGFt
cGxlLAogYGlhbS5nb29nbGVhcGlzLmNvbS9yb2xlcy5saXN0YC4KCgwKBQQAAgIEEgNVAgoK
DAoFBAACAgUSA1ULEQoMCgUEAAICARIDVRIkCgwKBQQAAgIDEgNVJygK0QIKBAQAAgMSA14C
LBrDAiBTcGVjaWZpZXMgdGhlIHBlcm1pc3Npb25zIHRoYXQgdGhpcyBydWxlIGV4Y2x1ZGVz
IGZyb20gdGhlIHNldCBvZiBkZW5pZWQKIHBlcm1pc3Npb25zIGdpdmVuIGJ5IGBkZW5pZWRf
cGVybWlzc2lvbnNgLiBJZiBhIHBlcm1pc3Npb24gYXBwZWFycyBpbgogYGRlbmllZF9wZXJt
aXNzaW9uc2AgX2FuZF8gaW4gYGV4Y2VwdGlvbl9wZXJtaXNzaW9uc2AgdGhlbiBpdCB3aWxs
IF9ub3RfIGJlCiBkZW5pZWQuCgogVGhlIGV4Y2x1ZGVkIHBlcm1pc3Npb25zIGNhbiBiZSBz
cGVjaWZpZWQgdXNpbmcgdGhlIHNhbWUgc3ludGF4IGFzCiBgZGVuaWVkX3Blcm1pc3Npb25z
YC4KCgwKBQQAAgMEEgNeAgoKDAoFBAACAwUSA14LEQoMCgUEAAIDARIDXhInCgwKBQQAAgMD
EgNeKisKiwQKBAQAAgQSA2sCKBr9AyBUaGUgY29uZGl0aW9uIHRoYXQgZGV0ZXJtaW5lcyB3
aGV0aGVyIHRoaXMgZGVueSBydWxlIGFwcGxpZXMgdG8gYSByZXF1ZXN0LgogSWYgdGhlIGNv
bmRpdGlvbiBleHByZXNzaW9uIGV2YWx1YXRlcyB0byBgdHJ1ZWAsIHRoZW4gdGhlIGRlbnkg
cnVsZSBpcwogYXBwbGllZDsgb3RoZXJ3aXNlLCB0aGUgZGVueSBydWxlIGlzIG5vdCBhcHBs
aWVkLgoKIEVhY2ggZGVueSBydWxlIGlzIGV2YWx1YXRlZCBpbmRlcGVuZGVudGx5LiBJZiB0
aGlzIGRlbnkgcnVsZSBkb2VzIG5vdCBhcHBseQogdG8gYSByZXF1ZXN0LCBvdGhlciBkZW55
IHJ1bGVzIG1pZ2h0IHN0aWxsIGFwcGx5LgoKIFRoZSBjb25kaXRpb24gY2FuIHVzZSBDRUwg
ZnVuY3Rpb25zIHRoYXQgZXZhbHVhdGUKIFtyZXNvdXJjZQogdGFnc10oaHR0cHM6Ly9jbG91
ZC5nb29nbGUuY29tL2lhbS9oZWxwL2NvbmRpdGlvbnMvcmVzb3VyY2UtdGFncykuIE90aGVy
CiBmdW5jdGlvbnMgYW5kIG9wZXJhdG9ycyBhcmUgbm90IHN1cHBvcnRlZC4KCgwKBQQAAgQG
EgNrAhIKDAoFBAACBAESA2sTIwoMCgUEAAIEAxIDayYnYgZwcm90bzM=
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Iam::V2::Deny::DenyRule ===
    # Fields for DenyRule
    # Field: denied_principals Type: 9 ()
    # Field: exception_principals Type: 9 ()
    # Field: denied_permissions Type: 9 ()
    # Field: exception_permissions Type: 9 ()
    # Field: denial_condition Type: 11 (.google.type.Expr)

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Iam::V2::Deny - Compiled Protocol Buffers messages for google/iam/v2/deny.proto

=head1 SYNOPSIS

    use Google::Iam::V2::Deny;

    my $msg = Google::Iam::V2::Deny::DenyRule->new({
        denied_principals => $denied_principals,
        exception_principals => $exception_principals,
        denied_permissions => $denied_permissions,
        exception_permissions => $exception_permissions,
    });

    # Read or update a field
    my $val = $msg->denied_principals();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Iam::V2::Deny::DenyRule->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/iam/v2/deny.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Iam::V2::Deny::DenyRule

A deny rule in an IAM deny policy.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->denied_principals() >> / C<< $msg->denied_principals($value) >>

Type: C<String>

The identities that are prevented from using one or more permissions on
Google Cloud resources. This field can contain the following values:

* `principalSet://goog/public:all`: A special identifier that represents
  any principal that is on the internet, even if they do not have a Google
  Account or are not logged in.

* `principal://goog/subject/{email_id}`: A specific Google Account.
  Includes Gmail, Cloud Identity, and Google Workspace user accounts. For
  example, `principal://goog/subject/alice@example.com`.

* `deleted:principal://goog/subject/{email_id}?uid={uid}`: A specific
  Google Account that was deleted recently. For example,
  `deleted:principal://goog/subject/alice@example.com?uid=1234567890`. If
  the Google Account is recovered, this identifier reverts to the standard
  identifier for a Google Account.

* `principalSet://goog/group/{group_id}`: A Google group. For example,
  `principalSet://goog/group/admins@example.com`.

* `deleted:principalSet://goog/group/{group_id}?uid={uid}`: A Google group
  that was deleted recently. For example,
  `deleted:principalSet://goog/group/admins@example.com?uid=1234567890`. If
  the Google group is restored, this identifier reverts to the standard
  identifier for a Google group.

* `principal://iam.googleapis.com/projects/-/serviceAccounts/{service_account_id}`:
  A Google Cloud service account. For example,
  `principal://iam.googleapis.com/projects/-/serviceAccounts/my-service-account@iam.gserviceaccount.com`.

* `deleted:principal://iam.googleapis.com/projects/-/serviceAccounts/{service_account_id}?uid={uid}`:
  A Google Cloud service account that was deleted recently. For example,
  `deleted:principal://iam.googleapis.com/projects/-/serviceAccounts/my-service-account@iam.gserviceaccount.com?uid=1234567890`.
  If the service account is undeleted, this identifier reverts to the
  standard identifier for a service account.

* `principalSet://goog/cloudIdentityCustomerId/{customer_id}`: All of the
  principals associated with the specified Google Workspace or Cloud
  Identity customer ID. For example,
  `principalSet://goog/cloudIdentityCustomerId/C01Abc35`.

=item * C<< $msg->exception_principals() >> / C<< $msg->exception_principals($value) >>

Type: C<String>

The identities that are excluded from the deny rule, even if they are
listed in the `denied_principals`. For example, you could add a Google
group to the `denied_principals`, then exclude specific users who belong to
that group.

This field can contain the same values as the `denied_principals` field,
excluding `principalSet://goog/public:all`, which represents all users on
the internet.

=item * C<< $msg->denied_permissions() >> / C<< $msg->denied_permissions($value) >>

Type: C<String>

The permissions that are explicitly denied by this rule. Each permission
uses the format `{service_fqdn}/{resource}.{verb}`, where `{service_fqdn}`
is the fully qualified domain name for the service. For example,
`iam.googleapis.com/roles.list`.

=item * C<< $msg->exception_permissions() >> / C<< $msg->exception_permissions($value) >>

Type: C<String>

Specifies the permissions that this rule excludes from the set of denied
permissions given by `denied_permissions`. If a permission appears in
`denied_permissions` _and_ in `exception_permissions` then it will _not_ be
denied.

The excluded permissions can be specified using the same syntax as
`denied_permissions`.

=item * C<< $msg->denial_condition() >> / C<< $msg->denial_condition($value) >>

Type: C<Message> (L<Google::Type::Expr::Expr>)

The condition that determines whether this deny rule applies to a request.
If the condition expression evaluates to `true`, then the deny rule is
applied; otherwise, the deny rule is not applied.

Each deny rule is evaluated independently. If this deny rule does not apply
to a request, other deny rules might still apply.

The condition can use CEL functions that evaluate
[resource
tags](https://cloud.google.com/iam/help/conditions/resource-tags). Other
functions and operators are not supported.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Iam::V2::Deny::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
