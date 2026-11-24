package Google::Iam::V2beta::Deny;

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
Chxnb29nbGUvaWFtL3YyYmV0YS9kZW55LnByb3RvEhFnb29nbGUuaWFtLnYyYmV0YRoWZ29v
Z2xlL3R5cGUvZXhwci5wcm90byKMAgoIRGVueVJ1bGUSKwoRZGVuaWVkX3ByaW5jaXBhbHMY
ASADKAlSEGRlbmllZFByaW5jaXBhbHMSMQoUZXhjZXB0aW9uX3ByaW5jaXBhbHMYAiADKAlS
E2V4Y2VwdGlvblByaW5jaXBhbHMSLQoSZGVuaWVkX3Blcm1pc3Npb25zGAMgAygJUhFkZW5p
ZWRQZXJtaXNzaW9ucxIzChVleGNlcHRpb25fcGVybWlzc2lvbnMYBCADKAlSFGV4Y2VwdGlv
blBlcm1pc3Npb25zEjwKEGRlbmlhbF9jb25kaXRpb24YBSABKAsyES5nb29nbGUudHlwZS5F
eHByUg9kZW5pYWxDb25kaXRpb25CiwEKFWNvbS5nb29nbGUuaWFtLnYyYmV0YUINRGVueVJ1
bGVQcm90b1ABWi1jbG91ZC5nb29nbGUuY29tL2dvL2lhbS9hcGl2MmJldGEvaWFtcGI7aWFt
cGKqAhdHb29nbGUuQ2xvdWQuSWFtLlYyQmV0YcoCF0dvb2dsZVxDbG91ZFxJYW1cVjJiZXRh
SsclCgYSBA4AbAEKvAQKAQwSAw4AEjKxBCBDb3B5cmlnaHQgMjAyNSBHb29nbGUgTExDCgog
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
ABoKCQoCAwASAxIAIAoICgEIEgMUADQKCQoCCCUSAxQANAoICgEIEgMVAEQKCQoCCAsSAxUA
RAoICgEIEgMWACIKCQoCCAoSAxYAIgoICgEIEgMXAC4KCQoCCAgSAxcALgoICgEIEgMYAC4K
CQoCCAESAxgALgoICgEIEgMZADQKCQoCCCkSAxkANAowCgIEABIEHABsARokIEEgZGVueSBy
dWxlIGluIGFuIElBTSBkZW55IHBvbGljeS4KCgoKAwQAARIDHAgQCpYRCgQEAAIAEgNFAiga
iBEgVGhlIGlkZW50aXRpZXMgdGhhdCBhcmUgcHJldmVudGVkIGZyb20gdXNpbmcgb25lIG9y
IG1vcmUgcGVybWlzc2lvbnMgb24KIEdvb2dsZSBDbG91ZCByZXNvdXJjZXMuIFRoaXMgZmll
bGQgY2FuIGNvbnRhaW4gdGhlIGZvbGxvd2luZyB2YWx1ZXM6CgogKiBgcHJpbmNpcGFsU2V0
Oi8vZ29vZy9wdWJsaWM6YWxsYDogQSBzcGVjaWFsIGlkZW50aWZpZXIgdGhhdCByZXByZXNl
bnRzCiAgIGFueSBwcmluY2lwYWwgdGhhdCBpcyBvbiB0aGUgaW50ZXJuZXQsIGV2ZW4gaWYg
dGhleSBkbyBub3QgaGF2ZSBhIEdvb2dsZQogICBBY2NvdW50IG9yIGFyZSBub3QgbG9nZ2Vk
IGluLgoKICogYHByaW5jaXBhbDovL2dvb2cvc3ViamVjdC97ZW1haWxfaWR9YDogQSBzcGVj
aWZpYyBHb29nbGUgQWNjb3VudC4KICAgSW5jbHVkZXMgR21haWwsIENsb3VkIElkZW50aXR5
LCBhbmQgR29vZ2xlIFdvcmtzcGFjZSB1c2VyIGFjY291bnRzLiBGb3IKICAgZXhhbXBsZSwg
YHByaW5jaXBhbDovL2dvb2cvc3ViamVjdC9hbGljZUBleGFtcGxlLmNvbWAuCgogKiBgZGVs
ZXRlZDpwcmluY2lwYWw6Ly9nb29nL3N1YmplY3Qve2VtYWlsX2lkfT91aWQ9e3VpZH1gOiBB
IHNwZWNpZmljCiAgIEdvb2dsZSBBY2NvdW50IHRoYXQgd2FzIGRlbGV0ZWQgcmVjZW50bHku
IEZvciBleGFtcGxlLAogICBgZGVsZXRlZDpwcmluY2lwYWw6Ly9nb29nL3N1YmplY3QvYWxp
Y2VAZXhhbXBsZS5jb20/dWlkPTEyMzQ1Njc4OTBgLiBJZgogICB0aGUgR29vZ2xlIEFjY291
bnQgaXMgcmVjb3ZlcmVkLCB0aGlzIGlkZW50aWZpZXIgcmV2ZXJ0cyB0byB0aGUgc3RhbmRh
cmQKICAgaWRlbnRpZmllciBmb3IgYSBHb29nbGUgQWNjb3VudC4KCiAqIGBwcmluY2lwYWxT
ZXQ6Ly9nb29nL2dyb3VwL3tncm91cF9pZH1gOiBBIEdvb2dsZSBncm91cC4gRm9yIGV4YW1w
bGUsCiAgIGBwcmluY2lwYWxTZXQ6Ly9nb29nL2dyb3VwL2FkbWluc0BleGFtcGxlLmNvbWAu
CgogKiBgZGVsZXRlZDpwcmluY2lwYWxTZXQ6Ly9nb29nL2dyb3VwL3tncm91cF9pZH0/dWlk
PXt1aWR9YDogQSBHb29nbGUgZ3JvdXAKICAgdGhhdCB3YXMgZGVsZXRlZCByZWNlbnRseS4g
Rm9yIGV4YW1wbGUsCiAgIGBkZWxldGVkOnByaW5jaXBhbFNldDovL2dvb2cvZ3JvdXAvYWRt
aW5zQGV4YW1wbGUuY29tP3VpZD0xMjM0NTY3ODkwYC4gSWYKICAgdGhlIEdvb2dsZSBncm91
cCBpcyByZXN0b3JlZCwgdGhpcyBpZGVudGlmaWVyIHJldmVydHMgdG8gdGhlIHN0YW5kYXJk
CiAgIGlkZW50aWZpZXIgZm9yIGEgR29vZ2xlIGdyb3VwLgoKICogYHByaW5jaXBhbDovL2lh
bS5nb29nbGVhcGlzLmNvbS9wcm9qZWN0cy8tL3NlcnZpY2VBY2NvdW50cy97c2VydmljZV9h
Y2NvdW50X2lkfWA6CiAgIEEgR29vZ2xlIENsb3VkIHNlcnZpY2UgYWNjb3VudC4gRm9yIGV4
YW1wbGUsCiAgIGBwcmluY2lwYWw6Ly9pYW0uZ29vZ2xlYXBpcy5jb20vcHJvamVjdHMvLS9z
ZXJ2aWNlQWNjb3VudHMvbXktc2VydmljZS1hY2NvdW50QGlhbS5nc2VydmljZWFjY291bnQu
Y29tYC4KCiAqIGBkZWxldGVkOnByaW5jaXBhbDovL2lhbS5nb29nbGVhcGlzLmNvbS9wcm9q
ZWN0cy8tL3NlcnZpY2VBY2NvdW50cy97c2VydmljZV9hY2NvdW50X2lkfT91aWQ9e3VpZH1g
OgogICBBIEdvb2dsZSBDbG91ZCBzZXJ2aWNlIGFjY291bnQgdGhhdCB3YXMgZGVsZXRlZCBy
ZWNlbnRseS4gRm9yIGV4YW1wbGUsCiAgIGBkZWxldGVkOnByaW5jaXBhbDovL2lhbS5nb29n
bGVhcGlzLmNvbS9wcm9qZWN0cy8tL3NlcnZpY2VBY2NvdW50cy9teS1zZXJ2aWNlLWFjY291
bnRAaWFtLmdzZXJ2aWNlYWNjb3VudC5jb20/dWlkPTEyMzQ1Njc4OTBgLgogICBJZiB0aGUg
c2VydmljZSBhY2NvdW50IGlzIHVuZGVsZXRlZCwgdGhpcyBpZGVudGlmaWVyIHJldmVydHMg
dG8gdGhlCiAgIHN0YW5kYXJkIGlkZW50aWZpZXIgZm9yIGEgc2VydmljZSBhY2NvdW50LgoK
ICogYHByaW5jaXBhbFNldDovL2dvb2cvY2xvdWRJZGVudGl0eUN1c3RvbWVySWQve2N1c3Rv
bWVyX2lkfWA6IEFsbCBvZiB0aGUKICAgcHJpbmNpcGFscyBhc3NvY2lhdGVkIHdpdGggdGhl
IHNwZWNpZmllZCBHb29nbGUgV29ya3NwYWNlIG9yIENsb3VkCiAgIElkZW50aXR5IGN1c3Rv
bWVyIElELiBGb3IgZXhhbXBsZSwKICAgYHByaW5jaXBhbFNldDovL2dvb2cvY2xvdWRJZGVu
dGl0eUN1c3RvbWVySWQvQzAxQWJjMzVgLgoKDAoFBAACAAQSA0UCCgoMCgUEAAIABRIDRQsR
CgwKBQQAAgABEgNFEiMKDAoFBAACAAMSA0UmJwqcAwoEBAACARIDTwIrGo4DIFRoZSBpZGVu
dGl0aWVzIHRoYXQgYXJlIGV4Y2x1ZGVkIGZyb20gdGhlIGRlbnkgcnVsZSwgZXZlbiBpZiB0
aGV5IGFyZQogbGlzdGVkIGluIHRoZSBgZGVuaWVkX3ByaW5jaXBhbHNgLiBGb3IgZXhhbXBs
ZSwgeW91IGNvdWxkIGFkZCBhIEdvb2dsZQogZ3JvdXAgdG8gdGhlIGBkZW5pZWRfcHJpbmNp
cGFsc2AsIHRoZW4gZXhjbHVkZSBzcGVjaWZpYyB1c2VycyB3aG8gYmVsb25nIHRvCiB0aGF0
IGdyb3VwLgoKIFRoaXMgZmllbGQgY2FuIGNvbnRhaW4gdGhlIHNhbWUgdmFsdWVzIGFzIHRo
ZSBgZGVuaWVkX3ByaW5jaXBhbHNgIGZpZWxkLAogZXhjbHVkaW5nIGBwcmluY2lwYWxTZXQ6
Ly9nb29nL3B1YmxpYzphbGxgLCB3aGljaCByZXByZXNlbnRzIGFsbCB1c2VycyBvbgogdGhl
IGludGVybmV0LgoKDAoFBAACAQQSA08CCgoMCgUEAAIBBRIDTwsRCgwKBQQAAgEBEgNPEiYK
DAoFBAACAQMSA08pKgqIAgoEBAACAhIDVQIpGvoBIFRoZSBwZXJtaXNzaW9ucyB0aGF0IGFy
ZSBleHBsaWNpdGx5IGRlbmllZCBieSB0aGlzIHJ1bGUuIEVhY2ggcGVybWlzc2lvbgogdXNl
cyB0aGUgZm9ybWF0IGB7c2VydmljZV9mcWRufS97cmVzb3VyY2V9Lnt2ZXJifWAsIHdoZXJl
IGB7c2VydmljZV9mcWRufWAKIGlzIHRoZSBmdWxseSBxdWFsaWZpZWQgZG9tYWluIG5hbWUg
Zm9yIHRoZSBzZXJ2aWNlLiBGb3IgZXhhbXBsZSwKIGBpYW0uZ29vZ2xlYXBpcy5jb20vcm9s
ZXMubGlzdGAuCgoMCgUEAAICBBIDVQIKCgwKBQQAAgIFEgNVCxEKDAoFBAACAgESA1USJAoM
CgUEAAICAxIDVScoCtECCgQEAAIDEgNeAiwawwIgU3BlY2lmaWVzIHRoZSBwZXJtaXNzaW9u
cyB0aGF0IHRoaXMgcnVsZSBleGNsdWRlcyBmcm9tIHRoZSBzZXQgb2YgZGVuaWVkCiBwZXJt
aXNzaW9ucyBnaXZlbiBieSBgZGVuaWVkX3Blcm1pc3Npb25zYC4gSWYgYSBwZXJtaXNzaW9u
IGFwcGVhcnMgaW4KIGBkZW5pZWRfcGVybWlzc2lvbnNgIF9hbmRfIGluIGBleGNlcHRpb25f
cGVybWlzc2lvbnNgIHRoZW4gaXQgd2lsbCBfbm90XyBiZQogZGVuaWVkLgoKIFRoZSBleGNs
dWRlZCBwZXJtaXNzaW9ucyBjYW4gYmUgc3BlY2lmaWVkIHVzaW5nIHRoZSBzYW1lIHN5bnRh
eCBhcwogYGRlbmllZF9wZXJtaXNzaW9uc2AuCgoMCgUEAAIDBBIDXgIKCgwKBQQAAgMFEgNe
CxEKDAoFBAACAwESA14SJwoMCgUEAAIDAxIDXiorCosECgQEAAIEEgNrAiga/QMgVGhlIGNv
bmRpdGlvbiB0aGF0IGRldGVybWluZXMgd2hldGhlciB0aGlzIGRlbnkgcnVsZSBhcHBsaWVz
IHRvIGEgcmVxdWVzdC4KIElmIHRoZSBjb25kaXRpb24gZXhwcmVzc2lvbiBldmFsdWF0ZXMg
dG8gYHRydWVgLCB0aGVuIHRoZSBkZW55IHJ1bGUgaXMKIGFwcGxpZWQ7IG90aGVyd2lzZSwg
dGhlIGRlbnkgcnVsZSBpcyBub3QgYXBwbGllZC4KCiBFYWNoIGRlbnkgcnVsZSBpcyBldmFs
dWF0ZWQgaW5kZXBlbmRlbnRseS4gSWYgdGhpcyBkZW55IHJ1bGUgZG9lcyBub3QgYXBwbHkK
IHRvIGEgcmVxdWVzdCwgb3RoZXIgZGVueSBydWxlcyBtaWdodCBzdGlsbCBhcHBseS4KCiBU
aGUgY29uZGl0aW9uIGNhbiB1c2UgQ0VMIGZ1bmN0aW9ucyB0aGF0IGV2YWx1YXRlCiBbcmVz
b3VyY2UKIHRhZ3NdKGh0dHBzOi8vY2xvdWQuZ29vZ2xlLmNvbS9pYW0vaGVscC9jb25kaXRp
b25zL3Jlc291cmNlLXRhZ3MpLiBPdGhlcgogZnVuY3Rpb25zIGFuZCBvcGVyYXRvcnMgYXJl
IG5vdCBzdXBwb3J0ZWQuCgoMCgUEAAIEBhIDawISCgwKBQQAAgQBEgNrEyMKDAoFBAACBAMS
A2smJ2IGcHJvdG8z
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Iam::V2beta::Deny::DenyRule ===
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

Google::Iam::V2beta::Deny - Compiled Protocol Buffers messages for google/iam/v2beta/deny.proto

=head1 SYNOPSIS

    use Google::Iam::V2beta::Deny;

    my $msg = Google::Iam::V2beta::Deny::DenyRule->new({
        denied_principals => $denied_principals,
        exception_principals => $exception_principals,
        denied_permissions => $denied_permissions,
        exception_permissions => $exception_permissions,
    });

    # Read or update a field
    my $val = $msg->denied_principals();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Iam::V2beta::Deny::DenyRule->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/iam/v2beta/deny.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Iam::V2beta::Deny::DenyRule

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

L<Protobuf>, L<Protobuf::Message>, L<Google::Iam::V2beta::Deny::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
