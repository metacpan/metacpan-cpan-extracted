package Google::Ai::Generativelanguage::V1beta::Permission;

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
CjRnb29nbGUvYWkvZ2VuZXJhdGl2ZWxhbmd1YWdlL3YxYmV0YS9wZXJtaXNzaW9uLnByb3Rv
EiNnb29nbGUuYWkuZ2VuZXJhdGl2ZWxhbmd1YWdlLnYxYmV0YRofZ29vZ2xlL2FwaS9maWVs
ZF9iZWhhdmlvci5wcm90bxoZZ29vZ2xlL2FwaS9yZXNvdXJjZS5wcm90byKFBQoKUGVybWlz
c2lvbhIaCgRuYW1lGAEgASgJQgbgQQPgQQhSBG5hbWUSawoMZ3JhbnRlZV90eXBlGAIgASgO
MjsuZ29vZ2xlLmFpLmdlbmVyYXRpdmVsYW5ndWFnZS52MWJldGEuUGVybWlzc2lvbi5HcmFu
dGVlVHlwZUIG4EEB4EEFSABSC2dyYW50ZWVUeXBliAEBEjAKDWVtYWlsX2FkZHJlc3MYAyAB
KAlCBuBBAeBBBUgBUgxlbWFpbEFkZHJlc3OIAQESUgoEcm9sZRgEIAEoDjI0Lmdvb2dsZS5h
aS5nZW5lcmF0aXZlbGFuZ3VhZ2UudjFiZXRhLlBlcm1pc3Npb24uUm9sZUID4EECSAJSBHJv
bGWIAQEiTgoLR3JhbnRlZVR5cGUSHAoYR1JBTlRFRV9UWVBFX1VOU1BFQ0lGSUVEEAASCAoE
VVNFUhABEgkKBUdST1VQEAISDAoIRVZFUllPTkUQAyI/CgRSb2xlEhQKEFJPTEVfVU5TUEVD
SUZJRUQQABIJCgVPV05FUhABEgoKBldSSVRFUhACEgoKBlJFQURFUhADOqoB6kGmAQosZ2Vu
ZXJhdGl2ZWxhbmd1YWdlLmdvb2dsZWFwaXMuY29tL1Blcm1pc3Npb24SMnR1bmVkTW9kZWxz
L3t0dW5lZF9tb2RlbH0vcGVybWlzc2lvbnMve3Blcm1pc3Npb259Eiljb3Jwb3JhL3tjb3Jw
dXN9L3Blcm1pc3Npb25zL3twZXJtaXNzaW9ufSoLcGVybWlzc2lvbnMyCnBlcm1pc3Npb25C
DwoNX2dyYW50ZWVfdHlwZUIQCg5fZW1haWxfYWRkcmVzc0IHCgVfcm9sZUKbAQonY29tLmdv
b2dsZS5haS5nZW5lcmF0aXZlbGFuZ3VhZ2UudjFiZXRhQg9QZXJtaXNzaW9uUHJvdG9QAVpd
Y2xvdWQuZ29vZ2xlLmNvbS9nby9haS9nZW5lcmF0aXZlbGFuZ3VhZ2UvYXBpdjFiZXRhL2dl
bmVyYXRpdmVsYW5ndWFnZXBiO2dlbmVyYXRpdmVsYW5ndWFnZXBiSqwaCgYSBA4AagEKvAQK
AQwSAw4AEjKxBCBDb3B5cmlnaHQgMjAyNSBHb29nbGUgTExDCgogTGljZW5zZWQgdW5kZXIg
dGhlIEFwYWNoZSBMaWNlbnNlLCBWZXJzaW9uIDIuMCAodGhlICJMaWNlbnNlIik7CiB5b3Ug
bWF5IG5vdCB1c2UgdGhpcyBmaWxlIGV4Y2VwdCBpbiBjb21wbGlhbmNlIHdpdGggdGhlIExp
Y2Vuc2UuCiBZb3UgbWF5IG9idGFpbiBhIGNvcHkgb2YgdGhlIExpY2Vuc2UgYXQKCiAgICAg
aHR0cDovL3d3dy5hcGFjaGUub3JnL2xpY2Vuc2VzL0xJQ0VOU0UtMi4wCgogVW5sZXNzIHJl
cXVpcmVkIGJ5IGFwcGxpY2FibGUgbGF3IG9yIGFncmVlZCB0byBpbiB3cml0aW5nLCBzb2Z0
d2FyZQogZGlzdHJpYnV0ZWQgdW5kZXIgdGhlIExpY2Vuc2UgaXMgZGlzdHJpYnV0ZWQgb24g
YW4gIkFTIElTIiBCQVNJUywKIFdJVEhPVVQgV0FSUkFOVElFUyBPUiBDT05ESVRJT05TIE9G
IEFOWSBLSU5ELCBlaXRoZXIgZXhwcmVzcyBvciBpbXBsaWVkLgogU2VlIHRoZSBMaWNlbnNl
IGZvciB0aGUgc3BlY2lmaWMgbGFuZ3VhZ2UgZ292ZXJuaW5nIHBlcm1pc3Npb25zIGFuZAog
bGltaXRhdGlvbnMgdW5kZXIgdGhlIExpY2Vuc2UuCgoICgECEgMQACwKCQoCAwASAxIAKQoJ
CgIDARIDEwAjCggKAQgSAxUAdAoJCgIICxIDFQB0CggKAQgSAxYAIgoJCgIIChIDFgAiCggK
AQgSAxcAMAoJCgIICBIDFwAwCggKAQgSAxgAQAoJCgIIARIDGABACtQFCgIEABIEKABqARrH
BSBQZXJtaXNzaW9uIHJlc291cmNlIGdyYW50cyB1c2VyLCBncm91cCBvciB0aGUgcmVzdCBv
ZiB0aGUgd29ybGQgYWNjZXNzIHRvIHRoZQogUGFMTSBBUEkgcmVzb3VyY2UgKGUuZy4gYSB0
dW5lZCBtb2RlbCwgY29ycHVzKS4KCiBBIHJvbGUgaXMgYSBjb2xsZWN0aW9uIG9mIHBlcm1p
dHRlZCBvcGVyYXRpb25zIHRoYXQgYWxsb3dzIHVzZXJzIHRvIHBlcmZvcm0KIHNwZWNpZmlj
IGFjdGlvbnMgb24gUGFMTSBBUEkgcmVzb3VyY2VzLiBUbyBtYWtlIHRoZW0gYXZhaWxhYmxl
IHRvIHVzZXJzLAogZ3JvdXBzLCBvciBzZXJ2aWNlIGFjY291bnRzLCB5b3UgYXNzaWduIHJv
bGVzLiBXaGVuIHlvdSBhc3NpZ24gYSByb2xlLCB5b3UKIGdyYW50IHBlcm1pc3Npb25zIHRo
YXQgdGhlIHJvbGUgY29udGFpbnMuCgogVGhlcmUgYXJlIHRocmVlIGNvbmNlbnRyaWMgcm9s
ZXMuIEVhY2ggcm9sZSBpcyBhIHN1cGVyc2V0IG9mIHRoZSBwcmV2aW91cwogcm9sZSdzIHBl
cm1pdHRlZCBvcGVyYXRpb25zOgoKIC0gcmVhZGVyIGNhbiB1c2UgdGhlIHJlc291cmNlIChl
LmcuIHR1bmVkIG1vZGVsLCBjb3JwdXMpIGZvciBpbmZlcmVuY2UKIC0gd3JpdGVyIGhhcyBy
ZWFkZXIncyBwZXJtaXNzaW9ucyBhbmQgYWRkaXRpb25hbGx5IGNhbiBlZGl0IGFuZCBzaGFy
ZQogLSBvd25lciBoYXMgd3JpdGVyJ3MgcGVybWlzc2lvbnMgYW5kIGFkZGl0aW9uYWxseSBj
YW4gZGVsZXRlCgoKCgMEAAESAygIEgoLCgMEAAcSBCkCLwQKDQoFBAAHnQgSBCkCLwQKQAoE
BAAEABIEMgI/AxoyIERlZmluZXMgdHlwZXMgb2YgdGhlIGdyYW50ZWUgb2YgdGhpcyBwZXJt
aXNzaW9uLgoKDAoFBAAEAAESAzIHEgo5CgYEAAQAAgASAzQEIRoqIFRoZSBkZWZhdWx0IHZh
bHVlLiBUaGlzIHZhbHVlIGlzIHVudXNlZC4KCg4KBwQABAACAAESAzQEHAoOCgcEAAQAAgAC
EgM0HyAKWgoGBAAEAAIBEgM3BA0aSyBSZXByZXNlbnRzIGEgdXNlci4gV2hlbiBzZXQsIHlv
dSBtdXN0IHByb3ZpZGUgZW1haWxfYWRkcmVzcyBmb3IgdGhlIHVzZXIuCgoOCgcEAAQAAgEB
EgM3BAgKDgoHBAAEAAIBAhIDNwsMCl0KBgQABAACAhIDOwQOGk4gUmVwcmVzZW50cyBhIGdy
b3VwLiBXaGVuIHNldCwgeW91IG11c3QgcHJvdmlkZSBlbWFpbF9hZGRyZXNzIGZvciB0aGUK
IGdyb3VwLgoKDgoHBAAEAAICARIDOwQJCg4KBwQABAACAgISAzsMDQpRCgYEAAQAAgMSAz4E
ERpCIFJlcHJlc2VudHMgYWNjZXNzIHRvIGV2ZXJ5b25lLiBObyBleHRyYSBpbmZvcm1hdGlv
biBpcyByZXF1aXJlZC4KCg4KBwQABAACAwESAz4EDAoOCgcEAAQAAgMCEgM+DxAKPAoEBAAE
ARIEQgJOAxouIERlZmluZXMgdGhlIHJvbGUgZ3JhbnRlZCBieSB0aGlzIHBlcm1pc3Npb24u
CgoMCgUEAAQBARIDQgcLCjkKBgQABAECABIDRAQZGiogVGhlIGRlZmF1bHQgdmFsdWUuIFRo
aXMgdmFsdWUgaXMgdW51c2VkLgoKDgoHBAAEAQIAARIDRAQUCg4KBwQABAECAAISA0QXGApG
CgYEAAQBAgESA0cEDho3IE93bmVyIGNhbiB1c2UsIHVwZGF0ZSwgc2hhcmUgYW5kIGRlbGV0
ZSB0aGUgcmVzb3VyY2UuCgoOCgcEAAQBAgEBEgNHBAkKDgoHBAAEAQIBAhIDRwwNCj8KBgQA
BAECAhIDSgQPGjAgV3JpdGVyIGNhbiB1c2UsIHVwZGF0ZSBhbmQgc2hhcmUgdGhlIHJlc291
cmNlLgoKDgoHBAAEAQICARIDSgQKCg4KBwQABAECAgISA0oNDgotCgYEAAQBAgMSA00EDxoe
IFJlYWRlciBjYW4gdXNlIHRoZSByZXNvdXJjZS4KCg4KBwQABAECAwESA00ECgoOCgcEAAQB
AgMCEgNNDQ4K6QEKBAQAAgASBFUCWAQa2gEgT3V0cHV0IG9ubHkuIElkZW50aWZpZXIuIFRo
ZSBwZXJtaXNzaW9uIG5hbWUuIEEgdW5pcXVlIG5hbWUgd2lsbCBiZQogZ2VuZXJhdGVkIG9u
IGNyZWF0ZS4gRXhhbXBsZXM6CiAgICAgdHVuZWRNb2RlbHMve3R1bmVkX21vZGVsfS9wZXJt
aXNzaW9ucy97cGVybWlzc2lvbn0KICAgICBjb3Jwb3JhL3tjb3JwdXN9L3Blcm1pc3Npb25z
L3twZXJtaXNzaW9ufQogT3V0cHV0IG9ubHkuCgoMCgUEAAIABRIDVQIICgwKBQQAAgABEgNV
CQ0KDAoFBAACAAMSA1UQEQoNCgUEAAIACBIEVRJYAwoPCggEAAIACJwIABIDVgQtCg8KCAQA
AgAInAgBEgNXBCwKPQoEBAACARIEWwJeBBovIE9wdGlvbmFsLiBJbW11dGFibGUuIFRoZSB0
eXBlIG9mIHRoZSBncmFudGVlLgoKDAoFBAACAQQSA1sCCgoMCgUEAAIBBhIDWwsWCgwKBQQA
AgEBEgNbFyMKDAoFBAACAQMSA1smJwoNCgUEAAIBCBIEWyheAwoPCggEAAIBCJwIABIDXAQq
Cg8KCAQAAgEInAgBEgNdBCsKqQEKBAQAAgISBGMCZgQamgEgT3B0aW9uYWwuIEltbXV0YWJs
ZS4gVGhlIGVtYWlsIGFkZHJlc3Mgb2YgdGhlIHVzZXIgb2YgZ3JvdXAgd2hpY2ggdGhpcwog
cGVybWlzc2lvbiByZWZlcnMuIEZpZWxkIGlzIG5vdCBzZXQgd2hlbiBwZXJtaXNzaW9uJ3Mg
Z3JhbnRlZSB0eXBlIGlzCiBFVkVSWU9ORS4KCgwKBQQAAgIEEgNjAgoKDAoFBAACAgUSA2ML
EQoMCgUEAAICARIDYxIfCgwKBQQAAgIDEgNjIiMKDQoFBAACAggSBGMkZgMKDwoIBAACAgic
CAASA2QEKgoPCggEAAICCJwIARIDZQQrCj0KBAQAAgMSA2kCQhowIFJlcXVpcmVkLiBUaGUg
cm9sZSBncmFudGVkIGJ5IHRoaXMgcGVybWlzc2lvbi4KCgwKBQQAAgMEEgNpAgoKDAoFBAAC
AwYSA2kLDwoMCgUEAAIDARIDaRAUCgwKBQQAAgMDEgNpFxgKDAoFBAACAwgSA2kZQQoPCggE
AAIDCJwIABIDaRpAYgZwcm90bzM=
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Ai::Generativelanguage::V1beta::Permission::Permission ===
    # Fields for Permission
    # Field: name Type: 9 ()
    # Field: grantee_type Type: 14 (.google.ai.generativelanguage.v1beta.Permission.GranteeType)
    # Field: email_address Type: 9 ()
    # Field: role Type: 14 (.google.ai.generativelanguage.v1beta.Permission.Role)

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

Google::Ai::Generativelanguage::V1beta::Permission - Compiled Protocol Buffers messages for google/ai/generativelanguage/v1beta/permission.proto

=head1 SYNOPSIS

    use Google::Ai::Generativelanguage::V1beta::Permission;

    my $msg = Google::Ai::Generativelanguage::V1beta::Permission::Permission->new({
        name => $name,
        grantee_type => $grantee_type,
        email_address => $email_address,
        role => $role,
    });

    # Read or update a field
    my $val = $msg->name();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Ai::Generativelanguage::V1beta::Permission::Permission->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/ai/generativelanguage/v1beta/permission.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Ai::Generativelanguage::V1beta::Permission::Permission

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

Type: C<Enum> (L<Google::Ai::Generativelanguage::V1beta::Permission::GranteeType>)

Optional. Immutable. The type of the grantee.

=item * C<< $msg->email_address() >> / C<< $msg->email_address($value) >>

Type: C<String>

Optional. Immutable. The email address of the user of group which this
permission refers. Field is not set when permission's grantee type is
EVERYONE.

=item * C<< $msg->role() >> / C<< $msg->role($value) >>

Type: C<Enum> (L<Google::Ai::Generativelanguage::V1beta::Permission::Role>)

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

L<Protobuf>, L<Protobuf::Message>, L<Google::Ai::Generativelanguage::V1beta::Permission::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
