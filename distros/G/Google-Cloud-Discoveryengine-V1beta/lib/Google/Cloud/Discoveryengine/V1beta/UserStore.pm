package Google::Cloud::Discoveryengine::V1beta::UserStore;

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
CjRnb29nbGUvY2xvdWQvZGlzY292ZXJ5ZW5naW5lL3YxYmV0YS91c2VyX3N0b3JlLnByb3Rv
EiNnb29nbGUuY2xvdWQuZGlzY292ZXJ5ZW5naW5lLnYxYmV0YRofZ29vZ2xlL2FwaS9maWVs
ZF9iZWhhdmlvci5wcm90bxoZZ29vZ2xlL2FwaS9yZXNvdXJjZS5wcm90byK6AwoJVXNlclN0
b3JlEhcKBG5hbWUYASABKAlCA+BBBVIEbmFtZRIhCgxkaXNwbGF5X25hbWUYAiABKAlSC2Rp
c3BsYXlOYW1lEmoKFmRlZmF1bHRfbGljZW5zZV9jb25maWcYBSABKAlCNOBBAfpBLgosZGlz
Y292ZXJ5ZW5naW5lLmdvb2dsZWFwaXMuY29tL0xpY2Vuc2VDb25maWdSFGRlZmF1bHRMaWNl
bnNlQ29uZmlnEkQKHGVuYWJsZV9saWNlbnNlX2F1dG9fcmVnaXN0ZXIYBiABKAhCA+BBAVIZ
ZW5hYmxlTGljZW5zZUF1dG9SZWdpc3RlchJPCiJlbmFibGVfZXhwaXJlZF9saWNlbnNlX2F1
dG9fdXBkYXRlGAcgASgIQgPgQQFSHmVuYWJsZUV4cGlyZWRMaWNlbnNlQXV0b1VwZGF0ZTpu
6kFrCihkaXNjb3ZlcnllbmdpbmUuZ29vZ2xlYXBpcy5jb20vVXNlclN0b3JlEj9wcm9qZWN0
cy97cHJvamVjdH0vbG9jYXRpb25zL3tsb2NhdGlvbn0vdXNlclN0b3Jlcy97dXNlcl9zdG9y
ZX1ClQIKJ2NvbS5nb29nbGUuY2xvdWQuZGlzY292ZXJ5ZW5naW5lLnYxYmV0YUIOVXNlclN0
b3JlUHJvdG9QAVpRY2xvdWQuZ29vZ2xlLmNvbS9nby9kaXNjb3ZlcnllbmdpbmUvYXBpdjFi
ZXRhL2Rpc2NvdmVyeWVuZ2luZXBiO2Rpc2NvdmVyeWVuZ2luZXBiogIPRElTQ09WRVJZRU5H
SU5FqgIjR29vZ2xlLkNsb3VkLkRpc2NvdmVyeUVuZ2luZS5WMUJldGHKAiNHb29nbGVcQ2xv
dWRcRGlzY292ZXJ5RW5naW5lXFYxYmV0YeoCJkdvb2dsZTo6Q2xvdWQ6OkRpc2NvdmVyeUVu
Z2luZTo6VjFiZXRhSuYUCgYSBA4ATgEKvAQKAQwSAw4AEjKxBCBDb3B5cmlnaHQgMjAyNiBH
b29nbGUgTExDCgogTGljZW5zZWQgdW5kZXIgdGhlIEFwYWNoZSBMaWNlbnNlLCBWZXJzaW9u
IDIuMCAodGhlICJMaWNlbnNlIik7CiB5b3UgbWF5IG5vdCB1c2UgdGhpcyBmaWxlIGV4Y2Vw
dCBpbiBjb21wbGlhbmNlIHdpdGggdGhlIExpY2Vuc2UuCiBZb3UgbWF5IG9idGFpbiBhIGNv
cHkgb2YgdGhlIExpY2Vuc2UgYXQKCiAgICAgaHR0cDovL3d3dy5hcGFjaGUub3JnL2xpY2Vu
c2VzL0xJQ0VOU0UtMi4wCgogVW5sZXNzIHJlcXVpcmVkIGJ5IGFwcGxpY2FibGUgbGF3IG9y
IGFncmVlZCB0byBpbiB3cml0aW5nLCBzb2Z0d2FyZQogZGlzdHJpYnV0ZWQgdW5kZXIgdGhl
IExpY2Vuc2UgaXMgZGlzdHJpYnV0ZWQgb24gYW4gIkFTIElTIiBCQVNJUywKIFdJVEhPVVQg
V0FSUkFOVElFUyBPUiBDT05ESVRJT05TIE9GIEFOWSBLSU5ELCBlaXRoZXIgZXhwcmVzcyBv
ciBpbXBsaWVkLgogU2VlIHRoZSBMaWNlbnNlIGZvciB0aGUgc3BlY2lmaWMgbGFuZ3VhZ2Ug
Z292ZXJuaW5nIHBlcm1pc3Npb25zIGFuZAogbGltaXRhdGlvbnMgdW5kZXIgdGhlIExpY2Vu
c2UuCgoICgECEgMQACwKCQoCAwASAxIAKQoJCgIDARIDEwAjCggKAQgSAxUAQAoJCgIIJRID
FQBACggKAQgSAxYAaAoJCgIICxIDFgBoCggKAQgSAxcAIgoJCgIIChIDFwAiCggKAQgSAxgA
LwoJCgIICBIDGAAvCggKAQgSAxkAQAoJCgIIARIDGQBACggKAQgSAxoALQoJCgIIJBIDGgAt
CggKAQgSAxsAQAoJCgIIKRIDGwBACggKAQgSAxwAPwoJCgIILRIDHAA/CkUKAgQAEgQfAE4B
GjkgQ29uZmlndXJlcyBtZXRhZGF0YSB0aGF0IGlzIHVzZWQgZm9yIEVuZCBVc2VyIGVudGl0
aWVzLgoKCgoDBAABEgMfCBEKCwoDBAAHEgQgAiMECg0KBQQAB50IEgQgAiMECu4BCgQEAAIA
EgMqAjwa4AEgSW1tdXRhYmxlLiBUaGUgZnVsbCByZXNvdXJjZSBuYW1lIG9mIHRoZSBVc2Vy
IFN0b3JlLCBpbiB0aGUgZm9ybWF0IG9mCiBgcHJvamVjdHMve3Byb2plY3R9L2xvY2F0aW9u
cy97bG9jYXRpb259L3VzZXJTdG9yZXMve3VzZXJfc3RvcmV9YC4KCiBUaGlzIGZpZWxkIG11
c3QgYmUgYSBVVEYtOCBlbmNvZGVkIHN0cmluZyB3aXRoIGEgbGVuZ3RoIGxpbWl0IG9mIDEw
MjQKIGNoYXJhY3RlcnMuCgoMCgUEAAIABRIDKgIICgwKBQQAAgABEgMqCQ0KDAoFBAACAAMS
AyoQEQoMCgUEAAIACBIDKhI7Cg8KCAQAAgAInAgAEgMqEzoKMgoEBAACARIDLQIaGiUgVGhl
IGRpc3BsYXkgbmFtZSBvZiB0aGUgVXNlciBTdG9yZS4KCgwKBQQAAgEFEgMtAggKDAoFBAAC
AQESAy0JFQoMCgUEAAIBAxIDLRgZCvYECgQEAAICEgQ7AkAEGucEIE9wdGlvbmFsLiBUaGUg
ZGVmYXVsdCBzdWJzY3JpcHRpb24KIFtMaWNlbnNlQ29uZmlnXVtnb29nbGUuY2xvdWQuZGlz
Y292ZXJ5ZW5naW5lLnYxYmV0YS5MaWNlbnNlQ29uZmlnXSBmb3IgdGhlCiBVc2VyU3RvcmUs
IGlmCiBbVXNlclN0b3JlLmVuYWJsZV9saWNlbnNlX2F1dG9fcmVnaXN0ZXJdW2dvb2dsZS5j
bG91ZC5kaXNjb3ZlcnllbmdpbmUudjFiZXRhLlVzZXJTdG9yZS5lbmFibGVfbGljZW5zZV9h
dXRvX3JlZ2lzdGVyXQogaXMgdHJ1ZSwgbmV3IHVzZXJzIHdpbGwgYXV0b21hdGljYWxseSBy
ZWdpc3RlciB1bmRlciB0aGUgZGVmYXVsdAogc3Vic2NyaXB0aW9uLgoKIElmIGRlZmF1bHQK
IFtMaWNlbnNlQ29uZmlnXVtnb29nbGUuY2xvdWQuZGlzY292ZXJ5ZW5naW5lLnYxYmV0YS5M
aWNlbnNlQ29uZmlnXSBkb2Vzbid0CiBoYXZlIHJlbWFpbmluZyBsaWNlbnNlIHNlYXRzIGxl
ZnQsIG5ldyB1c2VycyB3aWxsIG5vdCBiZSBhc3NpZ25lZCB3aXRoCiBsaWNlbnNlIGFuZCB3
aWxsIGJlIGJsb2NrZWQgZm9yIFZlcnRleCBBSSBTZWFyY2ggZmVhdHVyZXMuIFRoaXMgaXMg
dXNlZCBpZgogYGxpY2Vuc2VfYXNzaWdubWVudF90aWVyX3J1bGVzYCBpcyBub3QgY29uZmln
dXJlZC4KCgwKBQQAAgIFEgM7AggKDAoFBAACAgESAzsJHwoMCgUEAAICAxIDOyIjCg0KBQQA
AgIIEgQ7JEADCg8KCAQAAgIInAgAEgM8BCoKDwoHBAACAgifCBIEPQQ/BQroAQoEBAACAxIE
RQJGLxrZASBPcHRpb25hbC4gV2hldGhlciB0byBlbmFibGUgbGljZW5zZSBhdXRvIHJlZ2lz
dGVyIGZvciB1c2VycyBpbiB0aGlzIFVzZXIKIFN0b3JlLiBJZiB0cnVlLCBuZXcgdXNlcnMg
d2lsbCBhdXRvbWF0aWNhbGx5IHJlZ2lzdGVyIHVuZGVyIHRoZSBkZWZhdWx0CiBsaWNlbnNl
IGNvbmZpZyBhcyBsb25nIGFzIHRoZSBkZWZhdWx0IGxpY2Vuc2UgY29uZmlnIGhhcyBzZWF0
cyBsZWZ0LgoKDAoFBAACAwUSA0UCBgoMCgUEAAIDARIDRQcjCgwKBQQAAgMDEgNFJicKDAoF
BAACAwgSA0YGLgoPCggEAAIDCJwIABIDRgctCvwBCgQEAAIEEgRMAk0vGu0BIE9wdGlvbmFs
LiBXaGV0aGVyIHRvIGVuYWJsZSBsaWNlbnNlIGF1dG8gdXBkYXRlIGZvciB1c2VycyBpbiB0
aGlzIFVzZXIKIFN0b3JlLiBJZiB0cnVlLCB1c2VycyB3aXRoIGV4cGlyZWQgbGljZW5zZXMg
d2lsbCBhdXRvbWF0aWNhbGx5IGJlIHVwZGF0ZWQKIHRvIHVzZSB0aGUgZGVmYXVsdCBsaWNl
bnNlIGNvbmZpZyBhcyBsb25nIGFzIHRoZSBkZWZhdWx0IGxpY2Vuc2UgY29uZmlnIGhhcwog
c2VhdHMgbGVmdC4KCgwKBQQAAgQFEgNMAgYKDAoFBAACBAESA0wHKQoMCgUEAAIEAxIDTCwt
CgwKBQQAAgQIEgNNBi4KDwoIBAACBAicCAASA00HLWIGcHJvdG8z
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Discoveryengine::V1beta::UserStore::UserStore ===
    # Fields for UserStore
    # Field: name Type: 9 ()
    # Field: display_name Type: 9 ()
    # Field: default_license_config Type: 9 ()
    # Field: enable_license_auto_register Type: 8 ()
    # Field: enable_expired_license_auto_update Type: 8 ()

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Discoveryengine::V1beta::UserStore - Compiled Protocol Buffers messages for google/cloud/discoveryengine/v1beta/user_store.proto

=head1 SYNOPSIS

    use Google::Cloud::Discoveryengine::V1beta::UserStore;

    my $msg = Google::Cloud::Discoveryengine::V1beta::UserStore::UserStore->new({
        name => $name,
        display_name => $display_name,
        default_license_config => $default_license_config,
        enable_license_auto_register => $enable_license_auto_register,
    });

    # Read or update a field
    my $val = $msg->name();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Discoveryengine::V1beta::UserStore::UserStore->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/discoveryengine/v1beta/user_store.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Discoveryengine::V1beta::UserStore::UserStore

Configures metadata that is used for End User entities.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Immutable. The full resource name of the User Store, in the format of
`projects/{project}/locations/{location}/userStores/{user_store}`.

This field must be a UTF-8 encoded string with a length limit of 1024
characters.

=item * C<< $msg->display_name() >> / C<< $msg->display_name($value) >>

Type: C<String>

The display name of the User Store.

=item * C<< $msg->default_license_config() >> / C<< $msg->default_license_config($value) >>

Type: C<String>

Optional. The default subscription
[LicenseConfig][google.cloud.discoveryengine.v1beta.LicenseConfig] for the
UserStore, if
[UserStore.enable_license_auto_register][google.cloud.discoveryengine.v1beta.UserStore.enable_license_auto_register]
is true, new users will automatically register under the default
subscription.

If default
[LicenseConfig][google.cloud.discoveryengine.v1beta.LicenseConfig] doesn't
have remaining license seats left, new users will not be assigned with
license and will be blocked for Vertex AI Search features. This is used if
`license_assignment_tier_rules` is not configured.

=item * C<< $msg->enable_license_auto_register() >> / C<< $msg->enable_license_auto_register($value) >>

Type: C<Bool>

Optional. Whether to enable license auto register for users in this User
Store. If true, new users will automatically register under the default
license config as long as the default license config has seats left.

=item * C<< $msg->enable_expired_license_auto_update() >> / C<< $msg->enable_expired_license_auto_update($value) >>

Type: C<Bool>

Optional. Whether to enable license auto update for users in this User
Store. If true, users with expired licenses will automatically be updated
to use the default license config as long as the default license config has
seats left.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Discoveryengine::V1beta::UserStore::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
