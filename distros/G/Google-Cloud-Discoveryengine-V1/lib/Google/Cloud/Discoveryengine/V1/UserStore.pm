package Google::Cloud::Discoveryengine::V1::UserStore;

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
CjBnb29nbGUvY2xvdWQvZGlzY292ZXJ5ZW5naW5lL3YxL3VzZXJfc3RvcmUucHJvdG8SH2dv
b2dsZS5jbG91ZC5kaXNjb3ZlcnllbmdpbmUudjEaH2dvb2dsZS9hcGkvZmllbGRfYmVoYXZp
b3IucHJvdG8aGWdvb2dsZS9hcGkvcmVzb3VyY2UucHJvdG8iugMKCVVzZXJTdG9yZRIXCgRu
YW1lGAEgASgJQgPgQQVSBG5hbWUSIQoMZGlzcGxheV9uYW1lGAIgASgJUgtkaXNwbGF5TmFt
ZRJqChZkZWZhdWx0X2xpY2Vuc2VfY29uZmlnGAUgASgJQjTgQQH6QS4KLGRpc2NvdmVyeWVu
Z2luZS5nb29nbGVhcGlzLmNvbS9MaWNlbnNlQ29uZmlnUhRkZWZhdWx0TGljZW5zZUNvbmZp
ZxJEChxlbmFibGVfbGljZW5zZV9hdXRvX3JlZ2lzdGVyGAYgASgIQgPgQQFSGWVuYWJsZUxp
Y2Vuc2VBdXRvUmVnaXN0ZXISTwoiZW5hYmxlX2V4cGlyZWRfbGljZW5zZV9hdXRvX3VwZGF0
ZRgHIAEoCEID4EEBUh5lbmFibGVFeHBpcmVkTGljZW5zZUF1dG9VcGRhdGU6bupBawooZGlz
Y292ZXJ5ZW5naW5lLmdvb2dsZWFwaXMuY29tL1VzZXJTdG9yZRI/cHJvamVjdHMve3Byb2pl
Y3R9L2xvY2F0aW9ucy97bG9jYXRpb259L3VzZXJTdG9yZXMve3VzZXJfc3RvcmV9QoECCiNj
b20uZ29vZ2xlLmNsb3VkLmRpc2NvdmVyeWVuZ2luZS52MUIOVXNlclN0b3JlUHJvdG9QAVpN
Y2xvdWQuZ29vZ2xlLmNvbS9nby9kaXNjb3ZlcnllbmdpbmUvYXBpdjEvZGlzY292ZXJ5ZW5n
aW5lcGI7ZGlzY292ZXJ5ZW5naW5lcGKiAg9ESVNDT1ZFUllFTkdJTkWqAh9Hb29nbGUuQ2xv
dWQuRGlzY292ZXJ5RW5naW5lLlYxygIfR29vZ2xlXENsb3VkXERpc2NvdmVyeUVuZ2luZVxW
MeoCIkdvb2dsZTo6Q2xvdWQ6OkRpc2NvdmVyeUVuZ2luZTo6VjFK2RQKBhIEDgBNAQq8BAoB
DBIDDgASMrEEIENvcHlyaWdodCAyMDI2IEdvb2dsZSBMTEMKCiBMaWNlbnNlZCB1bmRlciB0
aGUgQXBhY2hlIExpY2Vuc2UsIFZlcnNpb24gMi4wICh0aGUgIkxpY2Vuc2UiKTsKIHlvdSBt
YXkgbm90IHVzZSB0aGlzIGZpbGUgZXhjZXB0IGluIGNvbXBsaWFuY2Ugd2l0aCB0aGUgTGlj
ZW5zZS4KIFlvdSBtYXkgb2J0YWluIGEgY29weSBvZiB0aGUgTGljZW5zZSBhdAoKICAgICBo
dHRwOi8vd3d3LmFwYWNoZS5vcmcvbGljZW5zZXMvTElDRU5TRS0yLjAKCiBVbmxlc3MgcmVx
dWlyZWQgYnkgYXBwbGljYWJsZSBsYXcgb3IgYWdyZWVkIHRvIGluIHdyaXRpbmcsIHNvZnR3
YXJlCiBkaXN0cmlidXRlZCB1bmRlciB0aGUgTGljZW5zZSBpcyBkaXN0cmlidXRlZCBvbiBh
biAiQVMgSVMiIEJBU0lTLAogV0lUSE9VVCBXQVJSQU5USUVTIE9SIENPTkRJVElPTlMgT0Yg
QU5ZIEtJTkQsIGVpdGhlciBleHByZXNzIG9yIGltcGxpZWQuCiBTZWUgdGhlIExpY2Vuc2Ug
Zm9yIHRoZSBzcGVjaWZpYyBsYW5ndWFnZSBnb3Zlcm5pbmcgcGVybWlzc2lvbnMgYW5kCiBs
aW1pdGF0aW9ucyB1bmRlciB0aGUgTGljZW5zZS4KCggKAQISAxAAKAoJCgIDABIDEgApCgkK
AgMBEgMTACMKCAoBCBIDFQA8CgkKAgglEgMVADwKCAoBCBIDFgBkCgkKAggLEgMWAGQKCAoB
CBIDFwAiCgkKAggKEgMXACIKCAoBCBIDGAAvCgkKAggIEgMYAC8KCAoBCBIDGQA8CgkKAggB
EgMZADwKCAoBCBIDGgAtCgkKAggkEgMaAC0KCAoBCBIDGwA8CgkKAggpEgMbADwKCAoBCBID
HAA7CgkKAggtEgMcADsKRQoCBAASBB8ATQEaOSBDb25maWd1cmVzIG1ldGFkYXRhIHRoYXQg
aXMgdXNlZCBmb3IgRW5kIFVzZXIgZW50aXRpZXMuCgoKCgMEAAESAx8IEQoLCgMEAAcSBCAC
IwQKDQoFBAAHnQgSBCACIwQK7gEKBAQAAgASAyoCPBrgASBJbW11dGFibGUuIFRoZSBmdWxs
IHJlc291cmNlIG5hbWUgb2YgdGhlIFVzZXIgU3RvcmUsIGluIHRoZSBmb3JtYXQgb2YKIGBw
cm9qZWN0cy97cHJvamVjdH0vbG9jYXRpb25zL3tsb2NhdGlvbn0vdXNlclN0b3Jlcy97dXNl
cl9zdG9yZX1gLgoKIFRoaXMgZmllbGQgbXVzdCBiZSBhIFVURi04IGVuY29kZWQgc3RyaW5n
IHdpdGggYSBsZW5ndGggbGltaXQgb2YgMTAyNAogY2hhcmFjdGVycy4KCgwKBQQAAgAFEgMq
AggKDAoFBAACAAESAyoJDQoMCgUEAAIAAxIDKhARCgwKBQQAAgAIEgMqEjsKDwoIBAACAAic
CAASAyoTOgoyCgQEAAIBEgMtAhoaJSBUaGUgZGlzcGxheSBuYW1lIG9mIHRoZSBVc2VyIFN0
b3JlLgoKDAoFBAACAQUSAy0CCAoMCgUEAAIBARIDLQkVCgwKBQQAAgEDEgMtGBkK6QQKBAQA
AgISBDoCPwQa2gQgT3B0aW9uYWwuIFRoZSBkZWZhdWx0IHN1YnNjcmlwdGlvbgogW0xpY2Vu
c2VDb25maWddW2dvb2dsZS5jbG91ZC5kaXNjb3ZlcnllbmdpbmUudjEuTGljZW5zZUNvbmZp
Z10gZm9yIHRoZQogVXNlclN0b3JlLCBpZgogW1VzZXJTdG9yZS5lbmFibGVfbGljZW5zZV9h
dXRvX3JlZ2lzdGVyXVtnb29nbGUuY2xvdWQuZGlzY292ZXJ5ZW5naW5lLnYxLlVzZXJTdG9y
ZS5lbmFibGVfbGljZW5zZV9hdXRvX3JlZ2lzdGVyXQogaXMgdHJ1ZSwgbmV3IHVzZXJzIHdp
bGwgYXV0b21hdGljYWxseSByZWdpc3RlciB1bmRlciB0aGUgZGVmYXVsdAogc3Vic2NyaXB0
aW9uLgoKIElmIGRlZmF1bHQgW0xpY2Vuc2VDb25maWddW2dvb2dsZS5jbG91ZC5kaXNjb3Zl
cnllbmdpbmUudjEuTGljZW5zZUNvbmZpZ10KIGRvZXNuJ3QgaGF2ZSByZW1haW5pbmcgbGlj
ZW5zZSBzZWF0cyBsZWZ0LCBuZXcgdXNlcnMgd2lsbCBub3QgYmUgYXNzaWduZWQKIHdpdGgg
bGljZW5zZSBhbmQgd2lsbCBiZSBibG9ja2VkIGZvciBWZXJ0ZXggQUkgU2VhcmNoIGZlYXR1
cmVzLiBUaGlzIGlzCiB1c2VkIGlmIGBsaWNlbnNlX2Fzc2lnbm1lbnRfdGllcl9ydWxlc2Ag
aXMgbm90IGNvbmZpZ3VyZWQuCgoMCgUEAAICBRIDOgIICgwKBQQAAgIBEgM6CR8KDAoFBAAC
AgMSAzoiIwoNCgUEAAICCBIEOiQ/AwoPCggEAAICCJwIABIDOwQqCg8KBwQAAgIInwgSBDwE
PgUK6AEKBAQAAgMSBEQCRS8a2QEgT3B0aW9uYWwuIFdoZXRoZXIgdG8gZW5hYmxlIGxpY2Vu
c2UgYXV0byByZWdpc3RlciBmb3IgdXNlcnMgaW4gdGhpcyBVc2VyCiBTdG9yZS4gSWYgdHJ1
ZSwgbmV3IHVzZXJzIHdpbGwgYXV0b21hdGljYWxseSByZWdpc3RlciB1bmRlciB0aGUgZGVm
YXVsdAogbGljZW5zZSBjb25maWcgYXMgbG9uZyBhcyB0aGUgZGVmYXVsdCBsaWNlbnNlIGNv
bmZpZyBoYXMgc2VhdHMgbGVmdC4KCgwKBQQAAgMFEgNEAgYKDAoFBAACAwESA0QHIwoMCgUE
AAIDAxIDRCYnCgwKBQQAAgMIEgNFBi4KDwoIBAACAwicCAASA0UHLQr8AQoEBAACBBIESwJM
LxrtASBPcHRpb25hbC4gV2hldGhlciB0byBlbmFibGUgbGljZW5zZSBhdXRvIHVwZGF0ZSBm
b3IgdXNlcnMgaW4gdGhpcyBVc2VyCiBTdG9yZS4gSWYgdHJ1ZSwgdXNlcnMgd2l0aCBleHBp
cmVkIGxpY2Vuc2VzIHdpbGwgYXV0b21hdGljYWxseSBiZSB1cGRhdGVkCiB0byB1c2UgdGhl
IGRlZmF1bHQgbGljZW5zZSBjb25maWcgYXMgbG9uZyBhcyB0aGUgZGVmYXVsdCBsaWNlbnNl
IGNvbmZpZyBoYXMKIHNlYXRzIGxlZnQuCgoMCgUEAAIEBRIDSwIGCgwKBQQAAgQBEgNLBykK
DAoFBAACBAMSA0ssLQoMCgUEAAIECBIDTAYuCg8KCAQAAgQInAgAEgNMBy1iBnByb3RvMw==

EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Discoveryengine::V1::UserStore::UserStore ===
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

Google::Cloud::Discoveryengine::V1::UserStore - Compiled Protocol Buffers messages for google/cloud/discoveryengine/v1/user_store.proto

=head1 SYNOPSIS

    use Google::Cloud::Discoveryengine::V1::UserStore;

    my $msg = Google::Cloud::Discoveryengine::V1::UserStore::UserStore->new({
        name => $name,
        display_name => $display_name,
        default_license_config => $default_license_config,
        enable_license_auto_register => $enable_license_auto_register,
    });

    # Read or update a field
    my $val = $msg->name();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Discoveryengine::V1::UserStore::UserStore->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/discoveryengine/v1/user_store.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Discoveryengine::V1::UserStore::UserStore

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
[LicenseConfig][google.cloud.discoveryengine.v1.LicenseConfig] for the
UserStore, if
[UserStore.enable_license_auto_register][google.cloud.discoveryengine.v1.UserStore.enable_license_auto_register]
is true, new users will automatically register under the default
subscription.

If default [LicenseConfig][google.cloud.discoveryengine.v1.LicenseConfig]
doesn't have remaining license seats left, new users will not be assigned
with license and will be blocked for Vertex AI Search features. This is
used if `license_assignment_tier_rules` is not configured.

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

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Discoveryengine::V1::UserStore::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
