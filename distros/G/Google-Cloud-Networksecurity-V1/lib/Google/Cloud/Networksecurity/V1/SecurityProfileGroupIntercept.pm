package Google::Cloud::Networksecurity::V1::SecurityProfileGroupIntercept;

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
CkZnb29nbGUvY2xvdWQvbmV0d29ya3NlY3VyaXR5L3YxL3NlY3VyaXR5X3Byb2ZpbGVfZ3Jv
dXBfaW50ZXJjZXB0LnByb3RvEh9nb29nbGUuY2xvdWQubmV0d29ya3NlY3VyaXR5LnYxGh9n
b29nbGUvYXBpL2ZpZWxkX2JlaGF2aW9yLnByb3RvGhlnb29nbGUvYXBpL3Jlc291cmNlLnBy
b3RvIpEBChZDdXN0b21JbnRlcmNlcHRQcm9maWxlEncKGGludGVyY2VwdF9lbmRwb2ludF9n
cm91cBgBIAEoCUI94EEC+kE3CjVuZXR3b3Jrc2VjdXJpdHkuZ29vZ2xlYXBpcy5jb20vSW50
ZXJjZXB0RW5kcG9pbnRHcm91cFIWaW50ZXJjZXB0RW5kcG9pbnRHcm91cEKDAgojY29tLmdv
b2dsZS5jbG91ZC5uZXR3b3Jrc2VjdXJpdHkudjFCIlNlY3VyaXR5UHJvZmlsZUdyb3VwSW50
ZXJjZXB0UHJvdG9QAVpNY2xvdWQuZ29vZ2xlLmNvbS9nby9uZXR3b3Jrc2VjdXJpdHkvYXBp
djEvbmV0d29ya3NlY3VyaXR5cGI7bmV0d29ya3NlY3VyaXR5cGKqAh9Hb29nbGUuQ2xvdWQu
TmV0d29ya1NlY3VyaXR5LlYxygIfR29vZ2xlXENsb3VkXE5ldHdvcmtTZWN1cml0eVxWMeoC
Ikdvb2dsZTo6Q2xvdWQ6Ok5ldHdvcmtTZWN1cml0eTo6VjFK3gkKBhIEDgApAQq8BAoBDBID
DgASMrEEIENvcHlyaWdodCAyMDI2IEdvb2dsZSBMTEMKCiBMaWNlbnNlZCB1bmRlciB0aGUg
QXBhY2hlIExpY2Vuc2UsIFZlcnNpb24gMi4wICh0aGUgIkxpY2Vuc2UiKTsKIHlvdSBtYXkg
bm90IHVzZSB0aGlzIGZpbGUgZXhjZXB0IGluIGNvbXBsaWFuY2Ugd2l0aCB0aGUgTGljZW5z
ZS4KIFlvdSBtYXkgb2J0YWluIGEgY29weSBvZiB0aGUgTGljZW5zZSBhdAoKICAgICBodHRw
Oi8vd3d3LmFwYWNoZS5vcmcvbGljZW5zZXMvTElDRU5TRS0yLjAKCiBVbmxlc3MgcmVxdWly
ZWQgYnkgYXBwbGljYWJsZSBsYXcgb3IgYWdyZWVkIHRvIGluIHdyaXRpbmcsIHNvZnR3YXJl
CiBkaXN0cmlidXRlZCB1bmRlciB0aGUgTGljZW5zZSBpcyBkaXN0cmlidXRlZCBvbiBhbiAi
QVMgSVMiIEJBU0lTLAogV0lUSE9VVCBXQVJSQU5USUVTIE9SIENPTkRJVElPTlMgT0YgQU5Z
IEtJTkQsIGVpdGhlciBleHByZXNzIG9yIGltcGxpZWQuCiBTZWUgdGhlIExpY2Vuc2UgZm9y
IHRoZSBzcGVjaWZpYyBsYW5ndWFnZSBnb3Zlcm5pbmcgcGVybWlzc2lvbnMgYW5kCiBsaW1p
dGF0aW9ucyB1bmRlciB0aGUgTGljZW5zZS4KCggKAQISAxAAKAoJCgIDABIDEgApCgkKAgMB
EgMTACMKCAoBCBIDFQA8CgkKAgglEgMVADwKCAoBCBIDFgBkCgkKAggLEgMWAGQKCAoBCBID
FwAiCgkKAggKEgMXACIKCAoBCBIDGABDCgkKAggIEgMYAEMKCAoBCBIDGQA8CgkKAggBEgMZ
ADwKCAoBCBIDGgA8CgkKAggpEgMaADwKCAoBCBIDGwA7CgkKAggtEgMbADsKogEKAgQAEgQf
ACkBGpUBIEN1c3RvbUludGVyY2VwdFByb2ZpbGUgZGVmaW5lcyBpbi1iYW5kIGludGVncmF0
aW9uIGJlaGF2aW9yIChpbnRlcmNlcHQpLgogSXQgaXMgdXNlZCBieSBmaXJld2FsbCBydWxl
cyB3aXRoIGFuIEFQUExZX1NFQ1VSSVRZX1BST0ZJTEVfR1JPVVAgYWN0aW9uLgoKCgoDBAAB
EgMfCB4K1QEKBAQAAgASBCMCKAQaxgEgUmVxdWlyZWQuIFRoZSB0YXJnZXQgSW50ZXJjZXB0
RW5kcG9pbnRHcm91cC4KIFdoZW4gYSBmaXJld2FsbCBydWxlIHdpdGggdGhpcyBzZWN1cml0
eSBwcm9maWxlIGF0dGFjaGVkIG1hdGNoZXMgYSBwYWNrZXQsCiB0aGUgcGFja2V0IHdpbGwg
YmUgaW50ZXJjZXB0ZWQgdG8gdGhlIGxvY2F0aW9uLWxvY2FsIHRhcmdldCBpbiB0aGlzIGdy
b3VwLgoKDAoFBAACAAUSAyMCCAoMCgUEAAIAARIDIwkhCgwKBQQAAgADEgMjJCUKDQoFBAAC
AAgSBCMmKAMKDwoIBAACAAicCAASAyQEKgoPCgcEAAIACJ8IEgQlBCcFYgZwcm90bzM=
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Networksecurity::V1::SecurityProfileGroupIntercept::CustomInterceptProfile ===
    # Fields for CustomInterceptProfile
    # Field: intercept_endpoint_group Type: 9 ()

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Networksecurity::V1::SecurityProfileGroupIntercept - Compiled Protocol Buffers messages for google/cloud/networksecurity/v1/security_profile_group_intercept.proto

=head1 SYNOPSIS

    use Google::Cloud::Networksecurity::V1::SecurityProfileGroupIntercept;

    my $msg = Google::Cloud::Networksecurity::V1::SecurityProfileGroupIntercept::CustomInterceptProfile->new({
        intercept_endpoint_group => $intercept_endpoint_group,
    });

    # Read or update a field
    my $val = $msg->intercept_endpoint_group();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Networksecurity::V1::SecurityProfileGroupIntercept::CustomInterceptProfile->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/networksecurity/v1/security_profile_group_intercept.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Networksecurity::V1::SecurityProfileGroupIntercept::CustomInterceptProfile

CustomInterceptProfile defines in-band integration behavior (intercept).
It is used by firewall rules with an APPLY_SECURITY_PROFILE_GROUP action.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->intercept_endpoint_group() >> / C<< $msg->intercept_endpoint_group($value) >>

Type: C<String>

Required. The target InterceptEndpointGroup.
When a firewall rule with this security profile attached matches a packet,
the packet will be intercepted to the location-local target in this group.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Networksecurity::V1::SecurityProfileGroupIntercept::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
