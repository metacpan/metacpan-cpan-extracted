package Google::Cloud::Securitycenter::V1::GroupMembership;

use strict;
use warnings;

our $VERSION = '0.14';

use Protobuf::Message;
use Protobuf::DescriptorPool;
use Protobuf::Internal qw(:all);
use MIME::Base64;

BEGIN {
    my $descriptor_b64 = <<'EOF';
CjVnb29nbGUvY2xvdWQvc2VjdXJpdHljZW50ZXIvdjEvZ3JvdXBfbWVtYmVyc2hpcC5wcm90
bxIeZ29vZ2xlLmNsb3VkLnNlY3VyaXR5Y2VudGVyLnYxIuwBCg9Hcm91cE1lbWJlcnNoaXAS
WAoKZ3JvdXBfdHlwZRgBIAEoDjI5Lmdvb2dsZS5jbG91ZC5zZWN1cml0eWNlbnRlci52MS5H
cm91cE1lbWJlcnNoaXAuR3JvdXBUeXBlUglncm91cFR5cGUSGQoIZ3JvdXBfaWQYAiABKAlS
B2dyb3VwSWQiZAoJR3JvdXBUeXBlEhoKFkdST1VQX1RZUEVfVU5TUEVDSUZJRUQQABIgChxH
Uk9VUF9UWVBFX1RPWElDX0NPTUJJTkFUSU9OEAESGQoVR1JPVVBfVFlQRV9DSE9LRVBPSU5U
EANC7gEKImNvbS5nb29nbGUuY2xvdWQuc2VjdXJpdHljZW50ZXIudjFCFEdyb3VwTWVtYmVy
c2hpcFByb3RvUAFaSmNsb3VkLmdvb2dsZS5jb20vZ28vc2VjdXJpdHljZW50ZXIvYXBpdjEv
c2VjdXJpdHljZW50ZXJwYjtzZWN1cml0eWNlbnRlcnBiqgIeR29vZ2xlLkNsb3VkLlNlY3Vy
aXR5Q2VudGVyLlYxygIeR29vZ2xlXENsb3VkXFNlY3VyaXR5Q2VudGVyXFYx6gIhR29vZ2xl
OjpDbG91ZDo6U2VjdXJpdHlDZW50ZXI6OlYxSrwKCgYSBA4ALgEKvAQKAQwSAw4AEjKxBCBD
b3B5cmlnaHQgMjAyNiBHb29nbGUgTExDCgogTGljZW5zZWQgdW5kZXIgdGhlIEFwYWNoZSBM
aWNlbnNlLCBWZXJzaW9uIDIuMCAodGhlICJMaWNlbnNlIik7CiB5b3UgbWF5IG5vdCB1c2Ug
dGhpcyBmaWxlIGV4Y2VwdCBpbiBjb21wbGlhbmNlIHdpdGggdGhlIExpY2Vuc2UuCiBZb3Ug
bWF5IG9idGFpbiBhIGNvcHkgb2YgdGhlIExpY2Vuc2UgYXQKCiAgICAgaHR0cDovL3d3dy5h
cGFjaGUub3JnL2xpY2Vuc2VzL0xJQ0VOU0UtMi4wCgogVW5sZXNzIHJlcXVpcmVkIGJ5IGFw
cGxpY2FibGUgbGF3IG9yIGFncmVlZCB0byBpbiB3cml0aW5nLCBzb2Z0d2FyZQogZGlzdHJp
YnV0ZWQgdW5kZXIgdGhlIExpY2Vuc2UgaXMgZGlzdHJpYnV0ZWQgb24gYW4gIkFTIElTIiBC
QVNJUywKIFdJVEhPVVQgV0FSUkFOVElFUyBPUiBDT05ESVRJT05TIE9GIEFOWSBLSU5ELCBl
aXRoZXIgZXhwcmVzcyBvciBpbXBsaWVkLgogU2VlIHRoZSBMaWNlbnNlIGZvciB0aGUgc3Bl
Y2lmaWMgbGFuZ3VhZ2UgZ292ZXJuaW5nIHBlcm1pc3Npb25zIGFuZAogbGltaXRhdGlvbnMg
dW5kZXIgdGhlIExpY2Vuc2UuCgoICgECEgMQACcKCAoBCBIDEgA7CgkKAgglEgMSADsKCAoB
CBIDEwBhCgkKAggLEgMTAGEKCAoBCBIDFAAiCgkKAggKEgMUACIKCAoBCBIDFQA1CgkKAggI
EgMVADUKCAoBCBIDFgA7CgkKAggBEgMWADsKCAoBCBIDFwA7CgkKAggpEgMXADsKCAoBCBID
GAA6CgkKAggtEgMYADoKkgEKAgQAEgQcAC4BGoUBIENvbnRhaW5zIGRldGFpbHMgYWJvdXQg
Z3JvdXBzIG9mIHdoaWNoIHRoaXMgZmluZGluZyBpcyBhIG1lbWJlci4gQSBncm91cCBpcyBh
CiBjb2xsZWN0aW9uIG9mIGZpbmRpbmdzIHRoYXQgYXJlIHJlbGF0ZWQgaW4gc29tZSB3YXku
CgoKCgMEAAESAxwIFwopCgQEAAQAEgQeAicDGhsgUG9zc2libGUgdHlwZXMgb2YgZ3JvdXBz
LgoKDAoFBAAEAAESAx4HEAofCgYEAAQAAgASAyAEHxoQIERlZmF1bHQgdmFsdWUuCgoOCgcE
AAQAAgABEgMgBBoKDgoHBAAEAAIAAhIDIB0eCjYKBgQABAACARIDIwQlGicgR3JvdXAgcmVw
cmVzZW50cyBhIHRveGljIGNvbWJpbmF0aW9uLgoKDgoHBAAEAAIBARIDIwQgCg4KBwQABAAC
AQISAyMjJAovCgYEAAQAAgISAyYEHhogIEdyb3VwIHJlcHJlc2VudHMgYSBjaG9rZXBvaW50
LgoKDgoHBAAEAAICARIDJgQZCg4KBwQABAACAgISAyYcHQodCgQEAAIAEgMqAhsaECBUeXBl
IG9mIGdyb3VwLgoKDAoFBAACAAYSAyoCCwoMCgUEAAIAARIDKgwWCgwKBQQAAgADEgMqGRoK
HwoEBAACARIDLQIWGhIgSUQgb2YgdGhlIGdyb3VwLgoKDAoFBAACAQUSAy0CCAoMCgUEAAIB
ARIDLQkRCgwKBQQAAgEDEgMtFBViBnByb3RvMw==
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Securitycenter::V1::GroupMembership::GroupMembership ===
    # Fields for GroupMembership
    # Field: group_type Type: 14 (.google.cloud.securitycenter.v1.GroupMembership.GroupType)
    # Field: group_id Type: 9 ()

# Enum: GroupMembership::GroupType
our $GroupMembership_GROUP_TYPE_UNSPECIFIED = 0;
our $GroupMembership_GROUP_TYPE_TOXIC_COMBINATION = 1;
our $GroupMembership_GROUP_TYPE_CHOKEPOINT = 3;

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Securitycenter::V1::GroupMembership - Compiled Protocol Buffers messages for google/cloud/securitycenter/v1/group_membership.proto

=head1 SYNOPSIS

    use Google::Cloud::Securitycenter::V1::GroupMembership;

    my $msg = Google::Cloud::Securitycenter::V1::GroupMembership::GroupMembership->new({
        group_type => $group_type,
        group_id => $group_id,
    });

    # Read or update a field
    my $val = $msg->group_type();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Securitycenter::V1::GroupMembership::GroupMembership->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/securitycenter/v1/group_membership.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Securitycenter::V1::GroupMembership::GroupMembership

Contains details about groups of which this finding is a member. A group is a
collection of findings that are related in some way.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->group_type() >> / C<< $msg->group_type($value) >>

Type: C<Enum> (L<Google::Cloud::Securitycenter::V1::GroupMembership::GroupType>)

Type of group.

=item * C<< $msg->group_id() >> / C<< $msg->group_id($value) >>

Type: C<String>

ID of the group.

=back

=head3 Enum: GroupMembership::GroupType

=over 4

=item * C<GROUP_TYPE_UNSPECIFIED> => C<0>

=item * C<GROUP_TYPE_TOXIC_COMBINATION> => C<1>

=item * C<GROUP_TYPE_CHOKEPOINT> => C<3>

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Securitycenter::V1::GroupMembership::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
