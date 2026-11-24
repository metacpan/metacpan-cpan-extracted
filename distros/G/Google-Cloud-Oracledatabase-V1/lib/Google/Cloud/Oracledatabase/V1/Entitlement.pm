package Google::Cloud::Oracledatabase::V1::Entitlement;

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
    my $descriptor_b64 = <<'EOF';
CjBnb29nbGUvY2xvdWQvb3JhY2xlZGF0YWJhc2UvdjEvZW50aXRsZW1lbnQucHJvdG8SHmdv
b2dsZS5jbG91ZC5vcmFjbGVkYXRhYmFzZS52MRofZ29vZ2xlL2FwaS9maWVsZF9iZWhhdmlv
ci5wcm90bxoZZ29vZ2xlL2FwaS9yZXNvdXJjZS5wcm90byK3BAoLRW50aXRsZW1lbnQSFwoE
bmFtZRgBIAEoCUID4EEIUgRuYW1lEmcKFWNsb3VkX2FjY291bnRfZGV0YWlscxgCIAEoCzIz
Lmdvb2dsZS5jbG91ZC5vcmFjbGVkYXRhYmFzZS52MS5DbG91ZEFjY291bnREZXRhaWxzUhNj
bG91ZEFjY291bnREZXRhaWxzEioKDmVudGl0bGVtZW50X2lkGAMgASgJQgPgQQNSDWVudGl0
bGVtZW50SWQSTAoFc3RhdGUYBCABKA4yMS5nb29nbGUuY2xvdWQub3JhY2xlZGF0YWJhc2Uu
djEuRW50aXRsZW1lbnQuU3RhdGVCA+BBA1IFc3RhdGUimgEKBVN0YXRlEhUKEVNUQVRFX1VO
U1BFQ0lGSUVEEAASFgoSQUNDT1VOVF9OT1RfTElOS0VEEAESFgoSQUNDT1VOVF9OT1RfQUNU
SVZFEAISCgoGQUNUSVZFEAMSFQoRQUNDT1VOVF9TVVNQRU5ERUQQBBInCiNOT1RfQVBQUk9W
RURfSU5fUFJJVkFURV9NQVJLRVRQTEFDRRAFOo4B6kGKAQopb3JhY2xlZGF0YWJhc2UuZ29v
Z2xlYXBpcy5jb20vRW50aXRsZW1lbnQSQnByb2plY3RzL3twcm9qZWN0fS9sb2NhdGlvbnMv
e2xvY2F0aW9ufS9lbnRpdGxlbWVudHMve2VudGl0bGVtZW50fSoMZW50aXRsZW1lbnRzMgtl
bnRpdGxlbWVudCK3AgoTQ2xvdWRBY2NvdW50RGV0YWlscxIoCg1jbG91ZF9hY2NvdW50GAEg
ASgJQgPgQQNSDGNsb3VkQWNjb3VudBI+ChljbG91ZF9hY2NvdW50X2hvbWVfcmVnaW9uGAIg
ASgJQgPgQQNSFmNsb3VkQWNjb3VudEhvbWVSZWdpb24SQwoZbGlua19leGlzdGluZ19hY2Nv
dW50X3VyaRgDIAEoCUID4EEDSABSFmxpbmtFeGlzdGluZ0FjY291bnRVcmmIAQESOgoUYWNj
b3VudF9jcmVhdGlvbl91cmkYBCABKAlCA+BBA0gBUhJhY2NvdW50Q3JlYXRpb25VcmmIAQFC
HAoaX2xpbmtfZXhpc3RpbmdfYWNjb3VudF91cmlCFwoVX2FjY291bnRfY3JlYXRpb25fdXJp
QuoBCiJjb20uZ29vZ2xlLmNsb3VkLm9yYWNsZWRhdGFiYXNlLnYxQhBFbnRpdGxlbWVudFBy
b3RvUAFaSmNsb3VkLmdvb2dsZS5jb20vZ28vb3JhY2xlZGF0YWJhc2UvYXBpdjEvb3JhY2xl
ZGF0YWJhc2VwYjtvcmFjbGVkYXRhYmFzZXBiqgIeR29vZ2xlLkNsb3VkLk9yYWNsZURhdGFi
YXNlLlYxygIeR29vZ2xlXENsb3VkXE9yYWNsZURhdGFiYXNlXFYx6gIhR29vZ2xlOjpDbG91
ZDo6T3JhY2xlRGF0YWJhc2U6OlYxSskUCgYSBA4AWQEKvAQKAQwSAw4AEjKxBCBDb3B5cmln
aHQgMjAyNiBHb29nbGUgTExDCgogTGljZW5zZWQgdW5kZXIgdGhlIEFwYWNoZSBMaWNlbnNl
LCBWZXJzaW9uIDIuMCAodGhlICJMaWNlbnNlIik7CiB5b3UgbWF5IG5vdCB1c2UgdGhpcyBm
aWxlIGV4Y2VwdCBpbiBjb21wbGlhbmNlIHdpdGggdGhlIExpY2Vuc2UuCiBZb3UgbWF5IG9i
dGFpbiBhIGNvcHkgb2YgdGhlIExpY2Vuc2UgYXQKCiAgICAgaHR0cDovL3d3dy5hcGFjaGUu
b3JnL2xpY2Vuc2VzL0xJQ0VOU0UtMi4wCgogVW5sZXNzIHJlcXVpcmVkIGJ5IGFwcGxpY2Fi
bGUgbGF3IG9yIGFncmVlZCB0byBpbiB3cml0aW5nLCBzb2Z0d2FyZQogZGlzdHJpYnV0ZWQg
dW5kZXIgdGhlIExpY2Vuc2UgaXMgZGlzdHJpYnV0ZWQgb24gYW4gIkFTIElTIiBCQVNJUywK
IFdJVEhPVVQgV0FSUkFOVElFUyBPUiBDT05ESVRJT05TIE9GIEFOWSBLSU5ELCBlaXRoZXIg
ZXhwcmVzcyBvciBpbXBsaWVkLgogU2VlIHRoZSBMaWNlbnNlIGZvciB0aGUgc3BlY2lmaWMg
bGFuZ3VhZ2UgZ292ZXJuaW5nIHBlcm1pc3Npb25zIGFuZAogbGltaXRhdGlvbnMgdW5kZXIg
dGhlIExpY2Vuc2UuCgoICgECEgMQACcKCQoCAwASAxIAKQoJCgIDARIDEwAjCggKAQgSAxUA
OwoJCgIIJRIDFQA7CggKAQgSAxYAYQoJCgIICxIDFgBhCggKAQgSAxcAIgoJCgIIChIDFwAi
CggKAQgSAxgAMQoJCgIICBIDGAAxCggKAQgSAxkAOwoJCgIIARIDGQA7CggKAQgSAxoAOwoJ
CgIIKRIDGgA7CggKAQgSAxsAOgoJCgIILRIDGwA6CjIKAgQAEgQeAEcBGiYgRGV0YWlscyBv
ZiB0aGUgRW50aXRsZW1lbnQgcmVzb3VyY2UuCgoKCgMEAAESAx4IEwoLCgMEAAcSBB8CJAQK
DQoFBAAHnQgSBB8CJAQKQQoEBAAEABIEJwI5AxozIFRoZSB2YXJpb3VzIGxpZmVjeWNsZSBz
dGF0ZXMgb2YgdGhlIHN1YnNjcmlwdGlvbi4KCgwKBQQABAABEgMnBwwKKwoGBAAEAAIAEgMp
BBoaHCBEZWZhdWx0IHVuc3BlY2lmaWVkIHZhbHVlLgoKDgoHBAAEAAIAARIDKQQVCg4KBwQA
BAACAAISAykYGQokCgYEAAQAAgESAywEGxoVIEFjY291bnQgbm90IGxpbmtlZC4KCg4KBwQA
BAACAQESAywEFgoOCgcEAAQAAgECEgMsGRoKMgoGBAAEAAICEgMvBBsaIyBBY2NvdW50IGlz
IGxpbmtlZCBidXQgbm90IGFjdGl2ZS4KCg4KBwQABAACAgESAy8EFgoOCgcEAAQAAgICEgMv
GRoKNAoGBAAEAAIDEgMyBA8aJSBFbnRpdGxlbWVudCBhbmQgQWNjb3VudCBhcmUgYWN0aXZl
LgoKDgoHBAAEAAIDARIDMgQKCg4KBwQABAACAwISAzINDgomCgYEAAQAAgQSAzUEGhoXIEFj
Y291bnQgaXMgc3VzcGVuZGVkLgoKDgoHBAAEAAIEARIDNQQVCg4KBwQABAACBAISAzUYGQpE
CgYEAAQAAgUSAzgELBo1IEVudGl0bGVtZW50IGlzIG5vdCBhcHByb3ZlZCBpbiBwcml2YXRl
IG1hcmtldHBsYWNlLgoKDgoHBAAEAAIFARIDOAQnCg4KBwQABAACBQISAzgqKwqTAQoEBAAC
ABIDPQI9GoUBIElkZW50aWZpZXIuIFRoZSBuYW1lIG9mIHRoZSBFbnRpdGxlbWVudCByZXNv
dXJjZSB3aXRoIHRoZSBmb3JtYXQ6CiBwcm9qZWN0cy97cHJvamVjdH0vbG9jYXRpb25zL3ty
ZWdpb259L2VudGl0bGVtZW50cy97ZW50aXRsZW1lbnR9CgoMCgUEAAIABRIDPQIICgwKBQQA
AgABEgM9CQ0KDAoFBAACAAMSAz0QEQoMCgUEAAIACBIDPRI8Cg8KCAQAAgAInAgAEgM9EzsK
MAoEBAACARIDQAIwGiMgRGV0YWlscyBvZiB0aGUgT0NJIENsb3VkIEFjY291bnQuCgoMCgUE
AAIBBhIDQAIVCgwKBQQAAgEBEgNAFisKDAoFBAACAQMSA0AuLwpSCgQEAAICEgNDAkgaRSBP
dXRwdXQgb25seS4gR29vZ2xlIENsb3VkIE1hcmtldHBsYWNlIG9yZGVyIElEIChha2EgZW50
aXRsZW1lbnQgSUQpCgoMCgUEAAICBRIDQwIICgwKBQQAAgIBEgNDCRcKDAoFBAACAgMSA0Ma
GwoMCgUEAAICCBIDQxxHCg8KCAQAAgIInAgAEgNDHUYKLgoEBAACAxIDRgI+GiEgT3V0cHV0
IG9ubHkuIEVudGl0bGVtZW50IFN0YXRlLgoKDAoFBAACAwYSA0YCBwoMCgUEAAIDARIDRggN
CgwKBQQAAgMDEgNGEBEKDAoFBAACAwgSA0YSPQoPCggEAAIDCJwIABIDRhM8Ci8KAgQBEgRK
AFkBGiMgRGV0YWlscyBvZiB0aGUgT0NJIENsb3VkIEFjY291bnQuCgoKCgMEAQESA0oIGwot
CgQEAQIAEgNMAkcaICBPdXRwdXQgb25seS4gT0NJIGFjY291bnQgbmFtZS4KCgwKBQQBAgAF
EgNMAggKDAoFBAECAAESA0wJFgoMCgUEAQIAAxIDTBkaCgwKBQQBAgAIEgNMG0YKDwoIBAEC
AAicCAASA0wcRQo1CgQEAQIBEgRPAlAyGicgT3V0cHV0IG9ubHkuIE9DSSBhY2NvdW50IGhv
bWUgcmVnaW9uLgoKDAoFBAECAQUSA08CCAoMCgUEAQIBARIDTwkiCgwKBQQBAgEDEgNPJSYK
DAoFBAECAQgSA1AGMQoPCggEAQIBCJwIABIDUAcwCj0KBAQBAgISBFMCVDIaLyBPdXRwdXQg
b25seS4gVVJMIHRvIGxpbmsgYW4gZXhpc3RpbmcgYWNjb3VudC4KCgwKBQQBAgIEEgNTAgoK
DAoFBAECAgUSA1MLEQoMCgUEAQICARIDUxIrCgwKBQQBAgIDEgNTLi8KDAoFBAECAggSA1QG
MQoPCggEAQICCJwIABIDVAcwCkIKBAQBAgMSBFcCWDIaNCBPdXRwdXQgb25seS4gVVJMIHRv
IGNyZWF0ZSBhIG5ldyBhY2NvdW50IGFuZCBsaW5rLgoKDAoFBAECAwQSA1cCCgoMCgUEAQID
BRIDVwsRCgwKBQQBAgMBEgNXEiYKDAoFBAECAwMSA1cpKgoMCgUEAQIDCBIDWAYxCg8KCAQB
AgMInAgAEgNYBzBiBnByb3RvMw==
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Oracledatabase::V1::Entitlement::Entitlement ===
    # Fields for Entitlement
    # Field: name Type: 9 ()
    # Field: cloud_account_details Type: 11 (.google.cloud.oracledatabase.v1.CloudAccountDetails)
    # Field: entitlement_id Type: 9 ()
    # Field: state Type: 14 (.google.cloud.oracledatabase.v1.Entitlement.State)

# Enum: Entitlement::State
our $Entitlement_STATE_UNSPECIFIED = 0;
our $Entitlement_ACCOUNT_NOT_LINKED = 1;
our $Entitlement_ACCOUNT_NOT_ACTIVE = 2;
our $Entitlement_ACTIVE = 3;
our $Entitlement_ACCOUNT_SUSPENDED = 4;
our $Entitlement_NOT_APPROVED_IN_PRIVATE_MARKETPLACE = 5;

# === Message: Google::Cloud::Oracledatabase::V1::Entitlement::CloudAccountDetails ===
    # Fields for CloudAccountDetails
    # Field: cloud_account Type: 9 ()
    # Field: cloud_account_home_region Type: 9 ()
    # Field: link_existing_account_uri Type: 9 ()
    # Field: account_creation_uri Type: 9 ()

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Oracledatabase::V1::Entitlement - Compiled Protocol Buffers messages for google/cloud/oracledatabase/v1/entitlement.proto

=head1 SYNOPSIS

    use Google::Cloud::Oracledatabase::V1::Entitlement;

    my $msg = Google::Cloud::Oracledatabase::V1::Entitlement::Entitlement->new({
        name => $name,
        cloud_account_details => $cloud_account_details,
        entitlement_id => $entitlement_id,
        state => $state,
    });

    # Read or update a field
    my $val = $msg->name();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Oracledatabase::V1::Entitlement::Entitlement->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/oracledatabase/v1/entitlement.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Oracledatabase::V1::Entitlement::Entitlement

Details of the Entitlement resource.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Identifier. The name of the Entitlement resource with the format:
projects/{project}/locations/{region}/entitlements/{entitlement}

=item * C<< $msg->cloud_account_details() >> / C<< $msg->cloud_account_details($value) >>

Type: C<Message> (L<Google::Cloud::Oracledatabase::V1::Entitlement::CloudAccountDetails>)

Details of the OCI Cloud Account.

=item * C<< $msg->entitlement_id() >> / C<< $msg->entitlement_id($value) >>

Type: C<String>

Output only. Google Cloud Marketplace order ID (aka entitlement ID)

=item * C<< $msg->state() >> / C<< $msg->state($value) >>

Type: C<Enum> (L<Google::Cloud::Oracledatabase::V1::Entitlement::State>)

Output only. Entitlement State.

=back

=head3 Enum: Entitlement::State

=over 4

=item * C<STATE_UNSPECIFIED> => C<0>

=item * C<ACCOUNT_NOT_LINKED> => C<1>

=item * C<ACCOUNT_NOT_ACTIVE> => C<2>

=item * C<ACTIVE> => C<3>

=item * C<ACCOUNT_SUSPENDED> => C<4>

=item * C<NOT_APPROVED_IN_PRIVATE_MARKETPLACE> => C<5>

=back

=head2 Google::Cloud::Oracledatabase::V1::Entitlement::CloudAccountDetails

Details of the OCI Cloud Account.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->cloud_account() >> / C<< $msg->cloud_account($value) >>

Type: C<String>

Output only. OCI account name.

=item * C<< $msg->cloud_account_home_region() >> / C<< $msg->cloud_account_home_region($value) >>

Type: C<String>

Output only. OCI account home region.

=item * C<< $msg->link_existing_account_uri() >> / C<< $msg->link_existing_account_uri($value) >>

Type: C<String>

Output only. URL to link an existing account.

=item * C<< $msg->account_creation_uri() >> / C<< $msg->account_creation_uri($value) >>

Type: C<String>

Output only. URL to create a new account and link.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Oracledatabase::V1::Entitlement::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
