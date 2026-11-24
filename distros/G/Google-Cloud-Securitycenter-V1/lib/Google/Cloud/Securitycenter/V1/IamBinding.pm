package Google::Cloud::Securitycenter::V1::IamBinding;

use strict;
use warnings;

our $VERSION = '0.14';

use Protobuf::Message;
use Protobuf::DescriptorPool;
use Protobuf::Internal qw(:all);
use MIME::Base64;

BEGIN {
    my $descriptor_b64 = <<'EOF';
CjBnb29nbGUvY2xvdWQvc2VjdXJpdHljZW50ZXIvdjEvaWFtX2JpbmRpbmcucHJvdG8SHmdv
b2dsZS5jbG91ZC5zZWN1cml0eWNlbnRlci52MSK6AQoKSWFtQmluZGluZxJJCgZhY3Rpb24Y
ASABKA4yMS5nb29nbGUuY2xvdWQuc2VjdXJpdHljZW50ZXIudjEuSWFtQmluZGluZy5BY3Rp
b25SBmFjdGlvbhISCgRyb2xlGAIgASgJUgRyb2xlEhYKBm1lbWJlchgDIAEoCVIGbWVtYmVy
IjUKBkFjdGlvbhIWChJBQ1RJT05fVU5TUEVDSUZJRUQQABIHCgNBREQQARIKCgZSRU1PVkUQ
AkLpAQoiY29tLmdvb2dsZS5jbG91ZC5zZWN1cml0eWNlbnRlci52MUIPSWFtQmluZGluZ1By
b3RvUAFaSmNsb3VkLmdvb2dsZS5jb20vZ28vc2VjdXJpdHljZW50ZXIvYXBpdjEvc2VjdXJp
dHljZW50ZXJwYjtzZWN1cml0eWNlbnRlcnBiqgIeR29vZ2xlLkNsb3VkLlNlY3VyaXR5Q2Vu
dGVyLlYxygIeR29vZ2xlXENsb3VkXFNlY3VyaXR5Q2VudGVyXFYx6gIhR29vZ2xlOjpDbG91
ZDo6U2VjdXJpdHlDZW50ZXI6OlYxSqgMCgYSBA4AMwEKvAQKAQwSAw4AEjKxBCBDb3B5cmln
aHQgMjAyNSBHb29nbGUgTExDCgogTGljZW5zZWQgdW5kZXIgdGhlIEFwYWNoZSBMaWNlbnNl
LCBWZXJzaW9uIDIuMCAodGhlICJMaWNlbnNlIik7CiB5b3UgbWF5IG5vdCB1c2UgdGhpcyBm
aWxlIGV4Y2VwdCBpbiBjb21wbGlhbmNlIHdpdGggdGhlIExpY2Vuc2UuCiBZb3UgbWF5IG9i
dGFpbiBhIGNvcHkgb2YgdGhlIExpY2Vuc2UgYXQKCiAgICAgaHR0cDovL3d3dy5hcGFjaGUu
b3JnL2xpY2Vuc2VzL0xJQ0VOU0UtMi4wCgogVW5sZXNzIHJlcXVpcmVkIGJ5IGFwcGxpY2Fi
bGUgbGF3IG9yIGFncmVlZCB0byBpbiB3cml0aW5nLCBzb2Z0d2FyZQogZGlzdHJpYnV0ZWQg
dW5kZXIgdGhlIExpY2Vuc2UgaXMgZGlzdHJpYnV0ZWQgb24gYW4gIkFTIElTIiBCQVNJUywK
IFdJVEhPVVQgV0FSUkFOVElFUyBPUiBDT05ESVRJT05TIE9GIEFOWSBLSU5ELCBlaXRoZXIg
ZXhwcmVzcyBvciBpbXBsaWVkLgogU2VlIHRoZSBMaWNlbnNlIGZvciB0aGUgc3BlY2lmaWMg
bGFuZ3VhZ2UgZ292ZXJuaW5nIHBlcm1pc3Npb25zIGFuZAogbGltaXRhdGlvbnMgdW5kZXIg
dGhlIExpY2Vuc2UuCgoICgECEgMQACcKCAoBCBIDEgA7CgkKAgglEgMSADsKCAoBCBIDEwBh
CgkKAggLEgMTAGEKCAoBCBIDFAAiCgkKAggKEgMUACIKCAoBCBIDFQAwCgkKAggIEgMVADAK
CAoBCBIDFgA7CgkKAggBEgMWADsKCAoBCBIDFwA7CgkKAggpEgMXADsKCAoBCBIDGAA6CgkK
AggtEgMYADoKbwoCBAASBBwAMwEaYyBSZXByZXNlbnRzIGEgcGFydGljdWxhciBJQU0gYmlu
ZGluZywgd2hpY2ggY2FwdHVyZXMgYSBtZW1iZXIncyByb2xlIGFkZGl0aW9uLAogcmVtb3Zh
bCwgb3Igc3RhdGUuCgoKCgMEAAESAxwIEgpGCgQEAAQAEgQeAicDGjggVGhlIHR5cGUgb2Yg
YWN0aW9uIHBlcmZvcm1lZCBvbiBhIEJpbmRpbmcgaW4gYSBwb2xpY3kuCgoMCgUEAAQAARID
HgcNCh0KBgQABAACABIDIAQbGg4gVW5zcGVjaWZpZWQuCgoOCgcEAAQAAgABEgMgBBYKDgoH
BAAEAAIAAhIDIBkaCicKBgQABAACARIDIwQMGhggQWRkaXRpb24gb2YgYSBCaW5kaW5nLgoK
DgoHBAAEAAIBARIDIwQHCg4KBwQABAACAQISAyMKCwomCgYEAAQAAgISAyYEDxoXIFJlbW92
YWwgb2YgYSBCaW5kaW5nLgoKDgoHBAAEAAICARIDJgQKCg4KBwQABAACAgISAyYNDgo6CgQE
AAIAEgMqAhQaLSBUaGUgYWN0aW9uIHRoYXQgd2FzIHBlcmZvcm1lZCBvbiBhIEJpbmRpbmcu
CgoMCgUEAAIABhIDKgIICgwKBQQAAgABEgMqCQ8KDAoFBAACAAMSAyoSEwpyCgQEAAIBEgMu
AhIaZSBSb2xlIHRoYXQgaXMgYXNzaWduZWQgdG8gIm1lbWJlcnMiLgogRm9yIGV4YW1wbGUs
ICJyb2xlcy92aWV3ZXIiLCAicm9sZXMvZWRpdG9yIiwgb3IgInJvbGVzL293bmVyIi4KCgwK
BQQAAgEFEgMuAggKDAoFBAACAQESAy4JDQoMCgUEAAIBAxIDLhARCnEKBAQAAgISAzICFBpk
IEEgc2luZ2xlIGlkZW50aXR5IHJlcXVlc3RpbmcgYWNjZXNzIGZvciBhIENsb3VkIFBsYXRm
b3JtIHJlc291cmNlLCBmb3IKIGV4YW1wbGUsICJmb29AZ29vZ2xlLmNvbSIuCgoMCgUEAAIC
BRIDMgIICgwKBQQAAgIBEgMyCQ8KDAoFBAACAgMSAzISE2IGcHJvdG8z
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Securitycenter::V1::IamBinding::IamBinding ===
    # Fields for IamBinding
    # Field: action Type: 14 (.google.cloud.securitycenter.v1.IamBinding.Action)
    # Field: role Type: 9 ()
    # Field: member Type: 9 ()

# Enum: IamBinding::Action
our $IamBinding_ACTION_UNSPECIFIED = 0;
our $IamBinding_ADD = 1;
our $IamBinding_REMOVE = 2;

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Securitycenter::V1::IamBinding - Compiled Protocol Buffers messages for google/cloud/securitycenter/v1/iam_binding.proto

=head1 SYNOPSIS

    use Google::Cloud::Securitycenter::V1::IamBinding;

    my $msg = Google::Cloud::Securitycenter::V1::IamBinding::IamBinding->new({
        action => $action,
        role => $role,
        member => $member,
    });

    # Read or update a field
    my $val = $msg->action();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Securitycenter::V1::IamBinding::IamBinding->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/securitycenter/v1/iam_binding.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Securitycenter::V1::IamBinding::IamBinding

Represents a particular IAM binding, which captures a member's role addition,
removal, or state.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->action() >> / C<< $msg->action($value) >>

Type: C<Enum> (L<Google::Cloud::Securitycenter::V1::IamBinding::Action>)

The action that was performed on a Binding.

=item * C<< $msg->role() >> / C<< $msg->role($value) >>

Type: C<String>

Role that is assigned to "members".
For example, "roles/viewer", "roles/editor", or "roles/owner".

=item * C<< $msg->member() >> / C<< $msg->member($value) >>

Type: C<String>

A single identity requesting access for a Cloud Platform resource, for
example, "foo@google.com".

=back

=head3 Enum: IamBinding::Action

=over 4

=item * C<ACTION_UNSPECIFIED> => C<0>

=item * C<ADD> => C<1>

=item * C<REMOVE> => C<2>

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Securitycenter::V1::IamBinding::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
