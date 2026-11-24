package Google::Cloud::Gkehub::Rbacrolebindingactuation::V1::Rbacrolebindingactuation;

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
Ck5nb29nbGUvY2xvdWQvZ2tlaHViL3YxL3JiYWNyb2xlYmluZGluZ2FjdHVhdGlvbi9yYmFj
cm9sZWJpbmRpbmdhY3R1YXRpb24ucHJvdG8SL2dvb2dsZS5jbG91ZC5na2VodWIucmJhY3Jv
bGViaW5kaW5nYWN0dWF0aW9uLnYxGh9nb29nbGUvYXBpL2ZpZWxkX2JlaGF2aW9yLnByb3Rv
Ij8KC0ZlYXR1cmVTcGVjEjAKFGFsbG93ZWRfY3VzdG9tX3JvbGVzGAIgAygJUhJhbGxvd2Vk
Q3VzdG9tUm9sZXMiDgoMRmVhdHVyZVN0YXRlQuECCjNjb20uZ29vZ2xlLmNsb3VkLmdrZWh1
Yi5yYmFjcm9sZWJpbmRpbmdhY3R1YXRpb24udjFCHVJCQUNSb2xlQmluZGluZ0FjdHVhdGlv
blByb3RvUAFab2Nsb3VkLmdvb2dsZS5jb20vZ28vZ2tlaHViL3JiYWNyb2xlYmluZGluZ2Fj
dHVhdGlvbi9hcGl2MS9yYmFjcm9sZWJpbmRpbmdhY3R1YXRpb25wYjtyYmFjcm9sZWJpbmRp
bmdhY3R1YXRpb25wYqoCL0dvb2dsZS5DbG91ZC5Ha2VIdWIuUmJhY1JvbGVCaW5kaW5nQWN0
dWF0aW9uLlYxygIvR29vZ2xlXENsb3VkXEdrZUh1YlxSYmFjUm9sZUJpbmRpbmdBY3R1YXRp
b25cVjHqAjNHb29nbGU6OkNsb3VkOjpHa2VIdWI6OlJiYWNSb2xlQmluZGluZ0FjdHVhdGlv
bjo6VjFKggoKBhIEDgAnFwq8BAoBDBIDDgASMrEEIENvcHlyaWdodCAyMDI2IEdvb2dsZSBM
TEMKCiBMaWNlbnNlZCB1bmRlciB0aGUgQXBhY2hlIExpY2Vuc2UsIFZlcnNpb24gMi4wICh0
aGUgIkxpY2Vuc2UiKTsKIHlvdSBtYXkgbm90IHVzZSB0aGlzIGZpbGUgZXhjZXB0IGluIGNv
bXBsaWFuY2Ugd2l0aCB0aGUgTGljZW5zZS4KIFlvdSBtYXkgb2J0YWluIGEgY29weSBvZiB0
aGUgTGljZW5zZSBhdAoKICAgICBodHRwOi8vd3d3LmFwYWNoZS5vcmcvbGljZW5zZXMvTElD
RU5TRS0yLjAKCiBVbmxlc3MgcmVxdWlyZWQgYnkgYXBwbGljYWJsZSBsYXcgb3IgYWdyZWVk
IHRvIGluIHdyaXRpbmcsIHNvZnR3YXJlCiBkaXN0cmlidXRlZCB1bmRlciB0aGUgTGljZW5z
ZSBpcyBkaXN0cmlidXRlZCBvbiBhbiAiQVMgSVMiIEJBU0lTLAogV0lUSE9VVCBXQVJSQU5U
SUVTIE9SIENPTkRJVElPTlMgT0YgQU5ZIEtJTkQsIGVpdGhlciBleHByZXNzIG9yIGltcGxp
ZWQuCiBTZWUgdGhlIExpY2Vuc2UgZm9yIHRoZSBzcGVjaWZpYyBsYW5ndWFnZSBnb3Zlcm5p
bmcgcGVybWlzc2lvbnMgYW5kCiBsaW1pdGF0aW9ucyB1bmRlciB0aGUgTGljZW5zZS4KCggK
AQISAxAAOAoJCgIDABIDEgApCggKAQgSAxQATAoJCgIIJRIDFABMCgkKAQgSBBUAhgEKCgoC
CAsSBBUAhgEKCAoBCBIDFgAiCgkKAggKEgMWACIKCAoBCBIDFwA+CgkKAggIEgMXAD4KCAoB
CBIDGABMCgkKAggBEgMYAEwKCAoBCBIDGQBNCgkKAggpEgMZAE0KCAoBCBIDGgBMCgkKAggt
EgMaAEwKawoCBAASBB4AIwEaXyAqKlJCQUMgUm9sZUJpbmRpbmcgQWN0dWF0aW9uKio6IFRo
ZSBIdWItd2lkZSBpbnB1dCBmb3IgdGhlCiBSQkFDUm9sZUJpbmRpbmdBY3R1YXRpb24gZmVh
dHVyZS4KCgoKAwQAARIDHggTCugBCgQEAAIAEgMiAisa2gEgVGhlIGxpc3Qgb2YgYWxsb3dl
ZCBjdXN0b20gcm9sZXMgKENsdXN0ZXJSb2xlcykuIElmIGEgQ2x1c3RlclJvbGUgaXMgbm90
CiBwYXJ0IG9mIHRoaXMgbGlzdCwgaXQgY2Fubm90IGJlIHVzZWQgaW4gYSBTY29wZSBSQkFD
Um9sZUJpbmRpbmcuIElmIGEKIENsdXN0ZXJSb2xlIGluIHRoaXMgbGlzdCBpcyBpbiB1c2Us
IGl0IGNhbm5vdCBiZSByZW1vdmVkIGZyb20gdGhlIGxpc3QuCgoMCgUEAAIABBIDIgIKCgwK
BQQAAgAFEgMiCxEKDAoFBAACAAESAyISJgoMCgUEAAIAAxIDIikqCmcKAgQBEgMnABcaXCAq
KlJCQUMgUm9sZUJpbmRpbmcgQWN0dWF0aW9uKio6IEFuIGVtcHR5IHN0YXRlIGxlZnQgYXMg
YW4gZXhhbXBsZSBIdWItd2lkZQogRmVhdHVyZSBzdGF0ZS4KCgoKAwQBARIDJwgUYgZwcm90
bzM=
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Gkehub::Rbacrolebindingactuation::V1::Rbacrolebindingactuation::FeatureSpec ===
    # Fields for FeatureSpec
    # Field: allowed_custom_roles Type: 9 ()

# === Message: Google::Cloud::Gkehub::Rbacrolebindingactuation::V1::Rbacrolebindingactuation::FeatureState ===
    # Fields for FeatureState

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Gkehub::Rbacrolebindingactuation::V1::Rbacrolebindingactuation - Compiled Protocol Buffers messages for google/cloud/gkehub/v1/rbacrolebindingactuation/rbacrolebindingactuation.proto

=head1 SYNOPSIS

    use Google::Cloud::Gkehub::Rbacrolebindingactuation::V1::Rbacrolebindingactuation;

    my $msg = Google::Cloud::Gkehub::Rbacrolebindingactuation::V1::Rbacrolebindingactuation::FeatureSpec->new({
        allowed_custom_roles => $allowed_custom_roles,
    });

    # Read or update a field
    my $val = $msg->allowed_custom_roles();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Gkehub::Rbacrolebindingactuation::V1::Rbacrolebindingactuation::FeatureSpec->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/gkehub/v1/rbacrolebindingactuation/rbacrolebindingactuation.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Gkehub::Rbacrolebindingactuation::V1::Rbacrolebindingactuation::FeatureSpec

B<RBAC RoleBinding Actuation>: The Hub-wide input for the
RBACRoleBindingActuation feature.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->allowed_custom_roles() >> / C<< $msg->allowed_custom_roles($value) >>

Type: C<String>

The list of allowed custom roles (ClusterRoles). If a ClusterRole is not
part of this list, it cannot be used in a Scope RBACRoleBinding. If a
ClusterRole in this list is in use, it cannot be removed from the list.

=back

=head2 Google::Cloud::Gkehub::Rbacrolebindingactuation::V1::Rbacrolebindingactuation::FeatureState

B<RBAC RoleBinding Actuation>: An empty state left as an example Hub-wide
Feature state.

Inherits from L<Protobuf::Message>.

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Gkehub::Rbacrolebindingactuation::V1::Rbacrolebindingactuation::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
