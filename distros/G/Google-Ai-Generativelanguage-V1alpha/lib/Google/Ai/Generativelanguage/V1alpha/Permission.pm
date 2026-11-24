package Google::Ai::Generativelanguage::V1alpha::Permission;

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
CjVnb29nbGUvYWkvZ2VuZXJhdGl2ZWxhbmd1YWdlL3YxYWxwaGEvcGVybWlzc2lvbi5wcm90
bxIkZ29vZ2xlLmFpLmdlbmVyYXRpdmVsYW5ndWFnZS52MWFscGhhGh9nb29nbGUvYXBpL2Zp
ZWxkX2JlaGF2aW9yLnByb3RvGhlnb29nbGUvYXBpL3Jlc291cmNlLnByb3RvIocFCgpQZXJt
aXNzaW9uEhoKBG5hbWUYASABKAlCBuBBA+BBCFIEbmFtZRJsCgxncmFudGVlX3R5cGUYAiAB
KA4yPC5nb29nbGUuYWkuZ2VuZXJhdGl2ZWxhbmd1YWdlLnYxYWxwaGEuUGVybWlzc2lvbi5H
cmFudGVlVHlwZUIG4EEB4EEFSABSC2dyYW50ZWVUeXBliAEBEjAKDWVtYWlsX2FkZHJlc3MY
AyABKAlCBuBBAeBBBUgBUgxlbWFpbEFkZHJlc3OIAQESUwoEcm9sZRgEIAEoDjI1Lmdvb2ds
ZS5haS5nZW5lcmF0aXZlbGFuZ3VhZ2UudjFhbHBoYS5QZXJtaXNzaW9uLlJvbGVCA+BBAkgC
UgRyb2xliAEBIk4KC0dyYW50ZWVUeXBlEhwKGEdSQU5URUVfVFlQRV9VTlNQRUNJRklFRBAA
EggKBFVTRVIQARIJCgVHUk9VUBACEgwKCEVWRVJZT05FEAMiPwoEUm9sZRIUChBST0xFX1VO
U1BFQ0lGSUVEEAASCQoFT1dORVIQARIKCgZXUklURVIQAhIKCgZSRUFERVIQAzqqAepBpgEK
LGdlbmVyYXRpdmVsYW5ndWFnZS5nb29nbGVhcGlzLmNvbS9QZXJtaXNzaW9uEjJ0dW5lZE1v
ZGVscy97dHVuZWRfbW9kZWx9L3Blcm1pc3Npb25zL3twZXJtaXNzaW9ufRIpY29ycG9yYS97
Y29ycHVzfS9wZXJtaXNzaW9ucy97cGVybWlzc2lvbn0qC3Blcm1pc3Npb25zMgpwZXJtaXNz
aW9uQg8KDV9ncmFudGVlX3R5cGVCEAoOX2VtYWlsX2FkZHJlc3NCBwoFX3JvbGVCnQEKKGNv
bS5nb29nbGUuYWkuZ2VuZXJhdGl2ZWxhbmd1YWdlLnYxYWxwaGFCD1Blcm1pc3Npb25Qcm90
b1ABWl5jbG91ZC5nb29nbGUuY29tL2dvL2FpL2dlbmVyYXRpdmVsYW5ndWFnZS9hcGl2MWFs
cGhhL2dlbmVyYXRpdmVsYW5ndWFnZXBiO2dlbmVyYXRpdmVsYW5ndWFnZXBiSqwaCgYSBA4A
agEKvAQKAQwSAw4AEjKxBCBDb3B5cmlnaHQgMjAyNSBHb29nbGUgTExDCgogTGljZW5zZWQg
dW5kZXIgdGhlIEFwYWNoZSBMaWNlbnNlLCBWZXJzaW9uIDIuMCAodGhlICJMaWNlbnNlIik7
CiB5b3UgbWF5IG5vdCB1c2UgdGhpcyBmaWxlIGV4Y2VwdCBpbiBjb21wbGlhbmNlIHdpdGgg
dGhlIExpY2Vuc2UuCiBZb3UgbWF5IG9idGFpbiBhIGNvcHkgb2YgdGhlIExpY2Vuc2UgYXQK
CiAgICAgaHR0cDovL3d3dy5hcGFjaGUub3JnL2xpY2Vuc2VzL0xJQ0VOU0UtMi4wCgogVW5s
ZXNzIHJlcXVpcmVkIGJ5IGFwcGxpY2FibGUgbGF3IG9yIGFncmVlZCB0byBpbiB3cml0aW5n
LCBzb2Z0d2FyZQogZGlzdHJpYnV0ZWQgdW5kZXIgdGhlIExpY2Vuc2UgaXMgZGlzdHJpYnV0
ZWQgb24gYW4gIkFTIElTIiBCQVNJUywKIFdJVEhPVVQgV0FSUkFOVElFUyBPUiBDT05ESVRJ
T05TIE9GIEFOWSBLSU5ELCBlaXRoZXIgZXhwcmVzcyBvciBpbXBsaWVkLgogU2VlIHRoZSBM
aWNlbnNlIGZvciB0aGUgc3BlY2lmaWMgbGFuZ3VhZ2UgZ292ZXJuaW5nIHBlcm1pc3Npb25z
IGFuZAogbGltaXRhdGlvbnMgdW5kZXIgdGhlIExpY2Vuc2UuCgoICgECEgMQAC0KCQoCAwAS
AxIAKQoJCgIDARIDEwAjCggKAQgSAxUAdQoJCgIICxIDFQB1CggKAQgSAxYAIgoJCgIIChID
FgAiCggKAQgSAxcAMAoJCgIICBIDFwAwCggKAQgSAxgAQQoJCgIIARIDGABBCtQFCgIEABIE
KABqARrHBSBQZXJtaXNzaW9uIHJlc291cmNlIGdyYW50cyB1c2VyLCBncm91cCBvciB0aGUg
cmVzdCBvZiB0aGUgd29ybGQgYWNjZXNzIHRvIHRoZQogUGFMTSBBUEkgcmVzb3VyY2UgKGUu
Zy4gYSB0dW5lZCBtb2RlbCwgY29ycHVzKS4KCiBBIHJvbGUgaXMgYSBjb2xsZWN0aW9uIG9m
IHBlcm1pdHRlZCBvcGVyYXRpb25zIHRoYXQgYWxsb3dzIHVzZXJzIHRvIHBlcmZvcm0KIHNw
ZWNpZmljIGFjdGlvbnMgb24gUGFMTSBBUEkgcmVzb3VyY2VzLiBUbyBtYWtlIHRoZW0gYXZh
aWxhYmxlIHRvIHVzZXJzLAogZ3JvdXBzLCBvciBzZXJ2aWNlIGFjY291bnRzLCB5b3UgYXNz
aWduIHJvbGVzLiBXaGVuIHlvdSBhc3NpZ24gYSByb2xlLCB5b3UKIGdyYW50IHBlcm1pc3Np
b25zIHRoYXQgdGhlIHJvbGUgY29udGFpbnMuCgogVGhlcmUgYXJlIHRocmVlIGNvbmNlbnRy
aWMgcm9sZXMuIEVhY2ggcm9sZSBpcyBhIHN1cGVyc2V0IG9mIHRoZSBwcmV2aW91cwogcm9s
ZSdzIHBlcm1pdHRlZCBvcGVyYXRpb25zOgoKIC0gcmVhZGVyIGNhbiB1c2UgdGhlIHJlc291
cmNlIChlLmcuIHR1bmVkIG1vZGVsLCBjb3JwdXMpIGZvciBpbmZlcmVuY2UKIC0gd3JpdGVy
IGhhcyByZWFkZXIncyBwZXJtaXNzaW9ucyBhbmQgYWRkaXRpb25hbGx5IGNhbiBlZGl0IGFu
ZCBzaGFyZQogLSBvd25lciBoYXMgd3JpdGVyJ3MgcGVybWlzc2lvbnMgYW5kIGFkZGl0aW9u
YWxseSBjYW4gZGVsZXRlCgoKCgMEAAESAygIEgoLCgMEAAcSBCkCLwQKDQoFBAAHnQgSBCkC
LwQKQAoEBAAEABIEMgI/AxoyIERlZmluZXMgdHlwZXMgb2YgdGhlIGdyYW50ZWUgb2YgdGhp
cyBwZXJtaXNzaW9uLgoKDAoFBAAEAAESAzIHEgo5CgYEAAQAAgASAzQEIRoqIFRoZSBkZWZh
dWx0IHZhbHVlLiBUaGlzIHZhbHVlIGlzIHVudXNlZC4KCg4KBwQABAACAAESAzQEHAoOCgcE
AAQAAgACEgM0HyAKWgoGBAAEAAIBEgM3BA0aSyBSZXByZXNlbnRzIGEgdXNlci4gV2hlbiBz
ZXQsIHlvdSBtdXN0IHByb3ZpZGUgZW1haWxfYWRkcmVzcyBmb3IgdGhlIHVzZXIuCgoOCgcE
AAQAAgEBEgM3BAgKDgoHBAAEAAIBAhIDNwsMCl0KBgQABAACAhIDOwQOGk4gUmVwcmVzZW50
cyBhIGdyb3VwLiBXaGVuIHNldCwgeW91IG11c3QgcHJvdmlkZSBlbWFpbF9hZGRyZXNzIGZv
ciB0aGUKIGdyb3VwLgoKDgoHBAAEAAICARIDOwQJCg4KBwQABAACAgISAzsMDQpRCgYEAAQA
AgMSAz4EERpCIFJlcHJlc2VudHMgYWNjZXNzIHRvIGV2ZXJ5b25lLiBObyBleHRyYSBpbmZv
cm1hdGlvbiBpcyByZXF1aXJlZC4KCg4KBwQABAACAwESAz4EDAoOCgcEAAQAAgMCEgM+DxAK
PAoEBAAEARIEQgJOAxouIERlZmluZXMgdGhlIHJvbGUgZ3JhbnRlZCBieSB0aGlzIHBlcm1p
c3Npb24uCgoMCgUEAAQBARIDQgcLCjkKBgQABAECABIDRAQZGiogVGhlIGRlZmF1bHQgdmFs
dWUuIFRoaXMgdmFsdWUgaXMgdW51c2VkLgoKDgoHBAAEAQIAARIDRAQUCg4KBwQABAECAAIS
A0QXGApGCgYEAAQBAgESA0cEDho3IE93bmVyIGNhbiB1c2UsIHVwZGF0ZSwgc2hhcmUgYW5k
IGRlbGV0ZSB0aGUgcmVzb3VyY2UuCgoOCgcEAAQBAgEBEgNHBAkKDgoHBAAEAQIBAhIDRwwN
Cj8KBgQABAECAhIDSgQPGjAgV3JpdGVyIGNhbiB1c2UsIHVwZGF0ZSBhbmQgc2hhcmUgdGhl
IHJlc291cmNlLgoKDgoHBAAEAQICARIDSgQKCg4KBwQABAECAgISA0oNDgotCgYEAAQBAgMS
A00EDxoeIFJlYWRlciBjYW4gdXNlIHRoZSByZXNvdXJjZS4KCg4KBwQABAECAwESA00ECgoO
CgcEAAQBAgMCEgNNDQ4K6QEKBAQAAgASBFUCWAQa2gEgT3V0cHV0IG9ubHkuIElkZW50aWZp
ZXIuIFRoZSBwZXJtaXNzaW9uIG5hbWUuIEEgdW5pcXVlIG5hbWUgd2lsbCBiZQogZ2VuZXJh
dGVkIG9uIGNyZWF0ZS4gRXhhbXBsZXM6CiAgICAgdHVuZWRNb2RlbHMve3R1bmVkX21vZGVs
fS9wZXJtaXNzaW9ucy97cGVybWlzc2lvbn0KICAgICBjb3Jwb3JhL3tjb3JwdXN9L3Blcm1p
c3Npb25zL3twZXJtaXNzaW9ufQogT3V0cHV0IG9ubHkuCgoMCgUEAAIABRIDVQIICgwKBQQA
AgABEgNVCQ0KDAoFBAACAAMSA1UQEQoNCgUEAAIACBIEVRJYAwoPCggEAAIACJwIABIDVgQt
Cg8KCAQAAgAInAgBEgNXBCwKPQoEBAACARIEWwJeBBovIE9wdGlvbmFsLiBJbW11dGFibGUu
IFRoZSB0eXBlIG9mIHRoZSBncmFudGVlLgoKDAoFBAACAQQSA1sCCgoMCgUEAAIBBhIDWwsW
CgwKBQQAAgEBEgNbFyMKDAoFBAACAQMSA1smJwoNCgUEAAIBCBIEWyheAwoPCggEAAIBCJwI
ABIDXAQqCg8KCAQAAgEInAgBEgNdBCsKqQEKBAQAAgISBGMCZgQamgEgT3B0aW9uYWwuIElt
bXV0YWJsZS4gVGhlIGVtYWlsIGFkZHJlc3Mgb2YgdGhlIHVzZXIgb2YgZ3JvdXAgd2hpY2gg
dGhpcwogcGVybWlzc2lvbiByZWZlcnMuIEZpZWxkIGlzIG5vdCBzZXQgd2hlbiBwZXJtaXNz
aW9uJ3MgZ3JhbnRlZSB0eXBlIGlzCiBFVkVSWU9ORS4KCgwKBQQAAgIEEgNjAgoKDAoFBAAC
AgUSA2MLEQoMCgUEAAICARIDYxIfCgwKBQQAAgIDEgNjIiMKDQoFBAACAggSBGMkZgMKDwoI
BAACAgicCAASA2QEKgoPCggEAAICCJwIARIDZQQrCj0KBAQAAgMSA2kCQhowIFJlcXVpcmVk
LiBUaGUgcm9sZSBncmFudGVkIGJ5IHRoaXMgcGVybWlzc2lvbi4KCgwKBQQAAgMEEgNpAgoK
DAoFBAACAwYSA2kLDwoMCgUEAAIDARIDaRAUCgwKBQQAAgMDEgNpFxgKDAoFBAACAwgSA2kZ
QQoPCggEAAIDCJwIABIDaRpAYgZwcm90bzM=
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Ai::Generativelanguage::V1alpha::Permission::Permission ===
    # Fields for Permission
    # Field: name Type: 9 ()
    # Field: grantee_type Type: 14 (.google.ai.generativelanguage.v1alpha.Permission.GranteeType)
    # Field: email_address Type: 9 ()
    # Field: role Type: 14 (.google.ai.generativelanguage.v1alpha.Permission.Role)

# Enum: Permission::GranteeType
our $Permission_GRANTEE_TYPE_UNSPECIFIED = 0;
our $Permission_USER = 1;
our $Permission_GROUP = 2;
our $Permission_EVERYONE = 3;

# Enum: Permission::Role
our $Permission_ROLE_UNSPECIFIED = 0;
our $Permission_OWNER = 1;
our $Permission_WRITER = 2;
our $Permission_READER = 3;

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Ai::Generativelanguage::V1alpha::Permission - Compiled Protocol Buffers messages for google/ai/generativelanguage/v1alpha/permission.proto

=head1 SYNOPSIS

    use Google::Ai::Generativelanguage::V1alpha::Permission;

    my $msg = Google::Ai::Generativelanguage::V1alpha::Permission::Permission->new({
        name => $name,
        grantee_type => $grantee_type,
        email_address => $email_address,
        role => $role,
    });

    # Read or update a field
    my $val = $msg->name();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Ai::Generativelanguage::V1alpha::Permission::Permission->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/ai/generativelanguage/v1alpha/permission.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Ai::Generativelanguage::V1alpha::Permission::Permission

Permission resource grants user, group or the rest of the world access to the
PaLM API resource (e.g. a tuned model, corpus).

A role is a collection of permitted operations that allows users to perform
specific actions on PaLM API resources. To make them available to users,
groups, or service accounts, you assign roles. When you assign a role, you
grant permissions that the role contains.

There are three concentric roles. Each role is a superset of the previous
role's permitted operations:

- reader can use the resource (e.g. tuned model, corpus) for inference
- writer has reader's permissions and additionally can edit and share
- owner has writer's permissions and additionally can delete

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Output only. Identifier. The permission name. A unique name will be
generated on create. Examples:
    tunedModels/{tuned_model}/permissions/{permission}
    corpora/{corpus}/permissions/{permission}
Output only.

=item * C<< $msg->grantee_type() >> / C<< $msg->grantee_type($value) >>

Type: C<Enum> (L<Google::Ai::Generativelanguage::V1alpha::Permission::GranteeType>)

Optional. Immutable. The type of the grantee.

=item * C<< $msg->email_address() >> / C<< $msg->email_address($value) >>

Type: C<String>

Optional. Immutable. The email address of the user of group which this
permission refers. Field is not set when permission's grantee type is
EVERYONE.

=item * C<< $msg->role() >> / C<< $msg->role($value) >>

Type: C<Enum> (L<Google::Ai::Generativelanguage::V1alpha::Permission::Role>)

Required. The role granted by this permission.

=back

=head3 Enum: Permission::GranteeType

=over 4

=item * C<GRANTEE_TYPE_UNSPECIFIED> => C<0>

=item * C<USER> => C<1>

=item * C<GROUP> => C<2>

=item * C<EVERYONE> => C<3>

=back

=head3 Enum: Permission::Role

=over 4

=item * C<ROLE_UNSPECIFIED> => C<0>

=item * C<OWNER> => C<1>

=item * C<WRITER> => C<2>

=item * C<READER> => C<3>

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Ai::Generativelanguage::V1alpha::Permission::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
