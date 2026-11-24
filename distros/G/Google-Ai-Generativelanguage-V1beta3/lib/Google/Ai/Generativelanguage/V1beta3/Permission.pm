package Google::Ai::Generativelanguage::V1beta3::Permission;

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
CjVnb29nbGUvYWkvZ2VuZXJhdGl2ZWxhbmd1YWdlL3YxYmV0YTMvcGVybWlzc2lvbi5wcm90
bxIkZ29vZ2xlLmFpLmdlbmVyYXRpdmVsYW5ndWFnZS52MWJldGEzGh9nb29nbGUvYXBpL2Zp
ZWxkX2JlaGF2aW9yLnByb3RvGhlnb29nbGUvYXBpL3Jlc291cmNlLnByb3RvItcECgpQZXJt
aXNzaW9uEhcKBG5hbWUYASABKAlCA+BBA1IEbmFtZRJsCgxncmFudGVlX3R5cGUYAiABKA4y
PC5nb29nbGUuYWkuZ2VuZXJhdGl2ZWxhbmd1YWdlLnYxYmV0YTMuUGVybWlzc2lvbi5HcmFu
dGVlVHlwZUIG4EEC4EEFSABSC2dyYW50ZWVUeXBliAEBEjAKDWVtYWlsX2FkZHJlc3MYAyAB
KAlCBuBBAeBBBUgBUgxlbWFpbEFkZHJlc3OIAQESUwoEcm9sZRgEIAEoDjI1Lmdvb2dsZS5h
aS5nZW5lcmF0aXZlbGFuZ3VhZ2UudjFiZXRhMy5QZXJtaXNzaW9uLlJvbGVCA+BBAkgCUgRy
b2xliAEBIk4KC0dyYW50ZWVUeXBlEhwKGEdSQU5URUVfVFlQRV9VTlNQRUNJRklFRBAAEggK
BFVTRVIQARIJCgVHUk9VUBACEgwKCEVWRVJZT05FEAMiPwoEUm9sZRIUChBST0xFX1VOU1BF
Q0lGSUVEEAASCQoFT1dORVIQARIKCgZXUklURVIQAhIKCgZSRUFERVIQAzp+6kF7CixnZW5l
cmF0aXZlbGFuZ3VhZ2UuZ29vZ2xlYXBpcy5jb20vUGVybWlzc2lvbhIydHVuZWRNb2RlbHMv
e3R1bmVkX21vZGVsfS9wZXJtaXNzaW9ucy97cGVybWlzc2lvbn0qC3Blcm1pc3Npb25zMgpw
ZXJtaXNzaW9uQg8KDV9ncmFudGVlX3R5cGVCEAoOX2VtYWlsX2FkZHJlc3NCBwoFX3JvbGVC
nQEKKGNvbS5nb29nbGUuYWkuZ2VuZXJhdGl2ZWxhbmd1YWdlLnYxYmV0YTNCD1Blcm1pc3Np
b25Qcm90b1ABWl5jbG91ZC5nb29nbGUuY29tL2dvL2FpL2dlbmVyYXRpdmVsYW5ndWFnZS9h
cGl2MWJldGEzL2dlbmVyYXRpdmVsYW5ndWFnZXBiO2dlbmVyYXRpdmVsYW5ndWFnZXBiSs4Z
CgYSBA4AYwEKvAQKAQwSAw4AEjKxBCBDb3B5cmlnaHQgMjAyNSBHb29nbGUgTExDCgogTGlj
ZW5zZWQgdW5kZXIgdGhlIEFwYWNoZSBMaWNlbnNlLCBWZXJzaW9uIDIuMCAodGhlICJMaWNl
bnNlIik7CiB5b3UgbWF5IG5vdCB1c2UgdGhpcyBmaWxlIGV4Y2VwdCBpbiBjb21wbGlhbmNl
IHdpdGggdGhlIExpY2Vuc2UuCiBZb3UgbWF5IG9idGFpbiBhIGNvcHkgb2YgdGhlIExpY2Vu
c2UgYXQKCiAgICAgaHR0cDovL3d3dy5hcGFjaGUub3JnL2xpY2Vuc2VzL0xJQ0VOU0UtMi4w
CgogVW5sZXNzIHJlcXVpcmVkIGJ5IGFwcGxpY2FibGUgbGF3IG9yIGFncmVlZCB0byBpbiB3
cml0aW5nLCBzb2Z0d2FyZQogZGlzdHJpYnV0ZWQgdW5kZXIgdGhlIExpY2Vuc2UgaXMgZGlz
dHJpYnV0ZWQgb24gYW4gIkFTIElTIiBCQVNJUywKIFdJVEhPVVQgV0FSUkFOVElFUyBPUiBD
T05ESVRJT05TIE9GIEFOWSBLSU5ELCBlaXRoZXIgZXhwcmVzcyBvciBpbXBsaWVkLgogU2Vl
IHRoZSBMaWNlbnNlIGZvciB0aGUgc3BlY2lmaWMgbGFuZ3VhZ2UgZ292ZXJuaW5nIHBlcm1p
c3Npb25zIGFuZAogbGltaXRhdGlvbnMgdW5kZXIgdGhlIExpY2Vuc2UuCgoICgECEgMQAC0K
CQoCAwASAxIAKQoJCgIDARIDEwAjCggKAQgSAxUAdQoJCgIICxIDFQB1CggKAQgSAxYAIgoJ
CgIIChIDFgAiCggKAQgSAxcAMAoJCgIICBIDFwAwCggKAQgSAxgAQQoJCgIIARIDGABBCswF
CgIEABIEJwBjARq/BSBQZXJtaXNzaW9uIHJlc291cmNlIGdyYW50cyB1c2VyLCBncm91cCBv
ciB0aGUgcmVzdCBvZiB0aGUgd29ybGQgYWNjZXNzIHRvIHRoZQogUGFMTSBBUEkgcmVzb3Vy
Y2UgKGUuZy4gYSB0dW5lZCBtb2RlbCwgZmlsZSkuCgogQSByb2xlIGlzIGEgY29sbGVjdGlv
biBvZiBwZXJtaXR0ZWQgb3BlcmF0aW9ucyB0aGF0IGFsbG93cyB1c2VycyB0byBwZXJmb3Jt
CiBzcGVjaWZpYyBhY3Rpb25zIG9uIFBhTE0gQVBJIHJlc291cmNlcy4gVG8gbWFrZSB0aGVt
IGF2YWlsYWJsZSB0byB1c2VycywKIGdyb3Vwcywgb3Igc2VydmljZSBhY2NvdW50cywgeW91
IGFzc2lnbiByb2xlcy4gV2hlbiB5b3UgYXNzaWduIGEgcm9sZSwgeW91CiBncmFudCBwZXJt
aXNzaW9ucyB0aGF0IHRoZSByb2xlIGNvbnRhaW5zLgoKIFRoZXJlIGFyZSB0aHJlZSBjb25j
ZW50cmljIHJvbGVzLiBFYWNoIHJvbGUgaXMgYSBzdXBlcnNldCBvZiB0aGUgcHJldmlvdXMK
IHJvbGUncyBwZXJtaXR0ZWQgb3BlcmF0aW9uczoKICAtIHJlYWRlciBjYW4gdXNlIHRoZSBy
ZXNvdXJjZSAoZS5nLiB0dW5lZCBtb2RlbCkgZm9yIGluZmVyZW5jZQogIC0gd3JpdGVyIGhh
cyByZWFkZXIncyBwZXJtaXNzaW9ucyBhbmQgYWRkaXRpb25hbGx5IGNhbiBlZGl0IGFuZCBz
aGFyZQogIC0gb3duZXIgaGFzIHdyaXRlcidzIHBlcm1pc3Npb25zIGFuZCBhZGRpdGlvbmFs
bHkgY2FuIGRlbGV0ZQoKCgoDBAABEgMnCBIKCwoDBAAHEgQoAi0ECg0KBQQAB50IEgQoAi0E
CkAKBAQABAASBDACPQMaMiBEZWZpbmVzIHR5cGVzIG9mIHRoZSBncmFudGVlIG9mIHRoaXMg
cGVybWlzc2lvbi4KCgwKBQQABAABEgMwBxIKOQoGBAAEAAIAEgMyBCEaKiBUaGUgZGVmYXVs
dCB2YWx1ZS4gVGhpcyB2YWx1ZSBpcyB1bnVzZWQuCgoOCgcEAAQAAgABEgMyBBwKDgoHBAAE
AAIAAhIDMh8gCloKBgQABAACARIDNQQNGksgUmVwcmVzZW50cyBhIHVzZXIuIFdoZW4gc2V0
LCB5b3UgbXVzdCBwcm92aWRlIGVtYWlsX2FkZHJlc3MgZm9yIHRoZSB1c2VyLgoKDgoHBAAE
AAIBARIDNQQICg4KBwQABAACAQISAzULDApdCgYEAAQAAgISAzkEDhpOIFJlcHJlc2VudHMg
YSBncm91cC4gV2hlbiBzZXQsIHlvdSBtdXN0IHByb3ZpZGUgZW1haWxfYWRkcmVzcyBmb3Ig
dGhlCiBncm91cC4KCg4KBwQABAACAgESAzkECQoOCgcEAAQAAgICEgM5DA0KUQoGBAAEAAID
EgM8BBEaQiBSZXByZXNlbnRzIGFjY2VzcyB0byBldmVyeW9uZS4gTm8gZXh0cmEgaW5mb3Jt
YXRpb24gaXMgcmVxdWlyZWQuCgoOCgcEAAQAAgMBEgM8BAwKDgoHBAAEAAIDAhIDPA8QCjwK
BAQABAESBEACTAMaLiBEZWZpbmVzIHRoZSByb2xlIGdyYW50ZWQgYnkgdGhpcyBwZXJtaXNz
aW9uLgoKDAoFBAAEAQESA0AHCwo5CgYEAAQBAgASA0IEGRoqIFRoZSBkZWZhdWx0IHZhbHVl
LiBUaGlzIHZhbHVlIGlzIHVudXNlZC4KCg4KBwQABAECAAESA0IEFAoOCgcEAAQBAgACEgNC
FxgKRgoGBAAEAQIBEgNFBA4aNyBPd25lciBjYW4gdXNlLCB1cGRhdGUsIHNoYXJlIGFuZCBk
ZWxldGUgdGhlIHJlc291cmNlLgoKDgoHBAAEAQIBARIDRQQJCg4KBwQABAECAQISA0UMDQo/
CgYEAAQBAgISA0gEDxowIFdyaXRlciBjYW4gdXNlLCB1cGRhdGUgYW5kIHNoYXJlIHRoZSBy
ZXNvdXJjZS4KCg4KBwQABAECAgESA0gECgoOCgcEAAQBAgICEgNIDQ4KLQoGBAAEAQIDEgNL
BA8aHiBSZWFkZXIgY2FuIHVzZSB0aGUgcmVzb3VyY2UuCgoOCgcEAAQBAgMBEgNLBAoKDgoH
BAAEAQIDAhIDSw0OCqUBCgQEAAIAEgNRAj4alwEgT3V0cHV0IG9ubHkuIFRoZSBwZXJtaXNz
aW9uIG5hbWUuIEEgdW5pcXVlIG5hbWUgd2lsbCBiZSBnZW5lcmF0ZWQgb24KIGNyZWF0ZS4g
RXhhbXBsZTogdHVuZWRNb2RlbHMve3R1bmVkX21vZGVsfXBlcm1zc2lvbnMve3Blcm1pc3Np
b259IE91dHB1dAogb25seS4KCgwKBQQAAgAFEgNRAggKDAoFBAACAAESA1EJDQoMCgUEAAIA
AxIDURARCgwKBQQAAgAIEgNREj0KDwoIBAACAAicCAASA1ETPAo9CgQEAAIBEgRUAlcEGi8g
UmVxdWlyZWQuIEltbXV0YWJsZS4gVGhlIHR5cGUgb2YgdGhlIGdyYW50ZWUuCgoMCgUEAAIB
BBIDVAIKCgwKBQQAAgEGEgNUCxYKDAoFBAACAQESA1QXIwoMCgUEAAIBAxIDVCYnCg0KBQQA
AgEIEgRUKFcDCg8KCAQAAgEInAgAEgNVBCoKDwoIBAACAQicCAESA1YEKwqpAQoEBAACAhIE
XAJfBBqaASBPcHRpb25hbC4gSW1tdXRhYmxlLiBUaGUgZW1haWwgYWRkcmVzcyBvZiB0aGUg
dXNlciBvZiBncm91cCB3aGljaCB0aGlzCiBwZXJtaXNzaW9uIHJlZmVycy4gRmllbGQgaXMg
bm90IHNldCB3aGVuIHBlcm1pc3Npb24ncyBncmFudGVlIHR5cGUgaXMKIEVWRVJZT05FLgoK
DAoFBAACAgQSA1wCCgoMCgUEAAICBRIDXAsRCgwKBQQAAgIBEgNcEh8KDAoFBAACAgMSA1wi
IwoNCgUEAAICCBIEXCRfAwoPCggEAAICCJwIABIDXQQqCg8KCAQAAgIInAgBEgNeBCsKPQoE
BAACAxIDYgJCGjAgUmVxdWlyZWQuIFRoZSByb2xlIGdyYW50ZWQgYnkgdGhpcyBwZXJtaXNz
aW9uLgoKDAoFBAACAwQSA2ICCgoMCgUEAAIDBhIDYgsPCgwKBQQAAgMBEgNiEBQKDAoFBAAC
AwMSA2IXGAoMCgUEAAIDCBIDYhlBCg8KCAQAAgMInAgAEgNiGkBiBnByb3RvMw==
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Ai::Generativelanguage::V1beta3::Permission::Permission ===
    # Fields for Permission
    # Field: name Type: 9 ()
    # Field: grantee_type Type: 14 (.google.ai.generativelanguage.v1beta3.Permission.GranteeType)
    # Field: email_address Type: 9 ()
    # Field: role Type: 14 (.google.ai.generativelanguage.v1beta3.Permission.Role)

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

Google::Ai::Generativelanguage::V1beta3::Permission - Compiled Protocol Buffers messages for google/ai/generativelanguage/v1beta3/permission.proto

=head1 SYNOPSIS

    use Google::Ai::Generativelanguage::V1beta3::Permission;

    my $msg = Google::Ai::Generativelanguage::V1beta3::Permission::Permission->new({
        name => $name,
        grantee_type => $grantee_type,
        email_address => $email_address,
        role => $role,
    });

    # Read or update a field
    my $val = $msg->name();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Ai::Generativelanguage::V1beta3::Permission::Permission->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/ai/generativelanguage/v1beta3/permission.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Ai::Generativelanguage::V1beta3::Permission::Permission

Permission resource grants user, group or the rest of the world access to the
PaLM API resource (e.g. a tuned model, file).

A role is a collection of permitted operations that allows users to perform
specific actions on PaLM API resources. To make them available to users,
groups, or service accounts, you assign roles. When you assign a role, you
grant permissions that the role contains.

There are three concentric roles. Each role is a superset of the previous
role's permitted operations:
 - reader can use the resource (e.g. tuned model) for inference
 - writer has reader's permissions and additionally can edit and share
 - owner has writer's permissions and additionally can delete

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Output only. The permission name. A unique name will be generated on
create. Example: tunedModels/{tuned_model}permssions/{permission} Output
only.

=item * C<< $msg->grantee_type() >> / C<< $msg->grantee_type($value) >>

Type: C<Enum> (L<Google::Ai::Generativelanguage::V1beta3::Permission::GranteeType>)

Required. Immutable. The type of the grantee.

=item * C<< $msg->email_address() >> / C<< $msg->email_address($value) >>

Type: C<String>

Optional. Immutable. The email address of the user of group which this
permission refers. Field is not set when permission's grantee type is
EVERYONE.

=item * C<< $msg->role() >> / C<< $msg->role($value) >>

Type: C<Enum> (L<Google::Ai::Generativelanguage::V1beta3::Permission::Role>)

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

L<Protobuf>, L<Protobuf::Message>, L<Google::Ai::Generativelanguage::V1beta3::Permission::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
