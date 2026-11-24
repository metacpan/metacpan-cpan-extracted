package Google::Iam::V1::ResourcePolicyMember;

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
Cipnb29nbGUvaWFtL3YxL3Jlc291cmNlX3BvbGljeV9tZW1iZXIucHJvdG8SDWdvb2dsZS5p
YW0udjEaH2dvb2dsZS9hcGkvZmllbGRfYmVoYXZpb3IucHJvdG8ilAEKFFJlc291cmNlUG9s
aWN5TWVtYmVyEj4KGWlhbV9wb2xpY3lfbmFtZV9wcmluY2lwYWwYASABKAlCA+BBA1IWaWFt
UG9saWN5TmFtZVByaW5jaXBhbBI8ChhpYW1fcG9saWN5X3VpZF9wcmluY2lwYWwYAiABKAlC
A+BBA1IVaWFtUG9saWN5VWlkUHJpbmNpcGFsQocBChFjb20uZ29vZ2xlLmlhbS52MUIZUmVz
b3VyY2VQb2xpY3lNZW1iZXJQcm90b1ABWiljbG91ZC5nb29nbGUuY29tL2dvL2lhbS9hcGl2
MS9pYW1wYjtpYW1wYqoCE0dvb2dsZS5DbG91ZC5JYW0uVjHKAhNHb29nbGVcQ2xvdWRcSWFt
XFYxStcNCgYSBA4AMQEKvAQKAQwSAw4AEjKxBCBDb3B5cmlnaHQgMjAyNSBHb29nbGUgTExD
CgogTGljZW5zZWQgdW5kZXIgdGhlIEFwYWNoZSBMaWNlbnNlLCBWZXJzaW9uIDIuMCAodGhl
ICJMaWNlbnNlIik7CiB5b3UgbWF5IG5vdCB1c2UgdGhpcyBmaWxlIGV4Y2VwdCBpbiBjb21w
bGlhbmNlIHdpdGggdGhlIExpY2Vuc2UuCiBZb3UgbWF5IG9idGFpbiBhIGNvcHkgb2YgdGhl
IExpY2Vuc2UgYXQKCiAgICAgaHR0cDovL3d3dy5hcGFjaGUub3JnL2xpY2Vuc2VzL0xJQ0VO
U0UtMi4wCgogVW5sZXNzIHJlcXVpcmVkIGJ5IGFwcGxpY2FibGUgbGF3IG9yIGFncmVlZCB0
byBpbiB3cml0aW5nLCBzb2Z0d2FyZQogZGlzdHJpYnV0ZWQgdW5kZXIgdGhlIExpY2Vuc2Ug
aXMgZGlzdHJpYnV0ZWQgb24gYW4gIkFTIElTIiBCQVNJUywKIFdJVEhPVVQgV0FSUkFOVElF
UyBPUiBDT05ESVRJT05TIE9GIEFOWSBLSU5ELCBlaXRoZXIgZXhwcmVzcyBvciBpbXBsaWVk
LgogU2VlIHRoZSBMaWNlbnNlIGZvciB0aGUgc3BlY2lmaWMgbGFuZ3VhZ2UgZ292ZXJuaW5n
IHBlcm1pc3Npb25zIGFuZAogbGltaXRhdGlvbnMgdW5kZXIgdGhlIExpY2Vuc2UuCgoICgEC
EgMQABYKCQoCAwASAxIAKQoICgEIEgMUADAKCQoCCCUSAxQAMAoICgEIEgMVAEAKCQoCCAsS
AxUAQAoICgEIEgMWADAKCQoCCCkSAxYAMAoICgEIEgMXACIKCQoCCAoSAxcAIgoICgEIEgMY
ADoKCQoCCAgSAxgAOgoICgEIEgMZACoKCQoCCAESAxkAKgpgCgIEABIEHQAxARpUIE91dHB1
dC1vbmx5IHBvbGljeSBtZW1iZXIgc3RyaW5ncyBvZiBhIEdvb2dsZSBDbG91ZCByZXNvdXJj
ZSdzIGJ1aWx0LWluCiBpZGVudGl0eS4KCgoKAwQAARIDHQgcCvMCCgQEAAIAEgQlAiYyGuQC
IElBTSBwb2xpY3kgYmluZGluZyBtZW1iZXIgcmVmZXJyaW5nIHRvIGEgR29vZ2xlIENsb3Vk
IHJlc291cmNlIGJ5CiB1c2VyLWFzc2lnbmVkIG5hbWUgKGh0dHBzOi8vZ29vZ2xlLmFpcC5k
ZXYvMTIyKS4gSWYgYSByZXNvdXJjZSBpcyBkZWxldGVkCiBhbmQgcmVjcmVhdGVkIHdpdGgg
dGhlIHNhbWUgbmFtZSwgdGhlIGJpbmRpbmcgd2lsbCBiZSBhcHBsaWNhYmxlIHRvIHRoZSBu
ZXcKIHJlc291cmNlLgoKIEV4YW1wbGU6CiBgcHJpbmNpcGFsOi8vcGFyYW1ldGVybWFuYWdl
ci5nb29nbGVhcGlzLmNvbS9wcm9qZWN0cy8xMjM0NS9uYW1lL2xvY2F0aW9ucy91cy1jZW50
cmFsMS1hL3BhcmFtZXRlcnMvbXktcGFyYW1ldGVyYAoKDAoFBAACAAUSAyUCCAoMCgUEAAIA
ARIDJQkiCgwKBQQAAgADEgMlJSYKDAoFBAACAAgSAyYGMQoPCggEAAIACJwIABIDJgcwCoQD
CgQEAAIBEgQvAjAyGvUCIElBTSBwb2xpY3kgYmluZGluZyBtZW1iZXIgcmVmZXJyaW5nIHRv
IGEgR29vZ2xlIENsb3VkIHJlc291cmNlIGJ5CiBzeXN0ZW0tYXNzaWduZWQgdW5pcXVlIGlk
ZW50aWZpZXIgKGh0dHBzOi8vZ29vZ2xlLmFpcC5kZXYvMTQ4I3VpZCkuIElmIGEKIHJlc291
cmNlIGlzIGRlbGV0ZWQgYW5kIHJlY3JlYXRlZCB3aXRoIHRoZSBzYW1lIG5hbWUsIHRoZSBi
aW5kaW5nIHdpbGwgbm90CiBiZSBhcHBsaWNhYmxlIHRvIHRoZSBuZXcgcmVzb3VyY2UKCiBF
eGFtcGxlOgogYHByaW5jaXBhbDovL3BhcmFtZXRlcm1hbmFnZXIuZ29vZ2xlYXBpcy5jb20v
cHJvamVjdHMvMTIzNDUvdWlkL2xvY2F0aW9ucy91cy1jZW50cmFsMS1hL3BhcmFtZXRlcnMv
YTkxOGZlZDVgCgoMCgUEAAIBBRIDLwIICgwKBQQAAgEBEgMvCSEKDAoFBAACAQMSAy8kJQoM
CgUEAAIBCBIDMAYxCg8KCAQAAgEInAgAEgMwBzBiBnByb3RvMw==
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Iam::V1::ResourcePolicyMember::ResourcePolicyMember ===
    # Fields for ResourcePolicyMember
    # Field: iam_policy_name_principal Type: 9 ()
    # Field: iam_policy_uid_principal Type: 9 ()

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Iam::V1::ResourcePolicyMember - Compiled Protocol Buffers messages for google/iam/v1/resource_policy_member.proto

=head1 SYNOPSIS

    use Google::Iam::V1::ResourcePolicyMember;

    my $msg = Google::Iam::V1::ResourcePolicyMember::ResourcePolicyMember->new({
        iam_policy_name_principal => $iam_policy_name_principal,
        iam_policy_uid_principal => $iam_policy_uid_principal,
    });

    # Read or update a field
    my $val = $msg->iam_policy_name_principal();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Iam::V1::ResourcePolicyMember::ResourcePolicyMember->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/iam/v1/resource_policy_member.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Iam::V1::ResourcePolicyMember::ResourcePolicyMember

Output-only policy member strings of a Google Cloud resource's built-in
identity.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->iam_policy_name_principal() >> / C<< $msg->iam_policy_name_principal($value) >>

Type: C<String>

IAM policy binding member referring to a Google Cloud resource by
user-assigned name (https://google.aip.dev/122). If a resource is deleted
and recreated with the same name, the binding will be applicable to the new
resource.

Example:
`principal://parametermanager.googleapis.com/projects/12345/name/locations/us-central1-a/parameters/my-parameter`

=item * C<< $msg->iam_policy_uid_principal() >> / C<< $msg->iam_policy_uid_principal($value) >>

Type: C<String>

IAM policy binding member referring to a Google Cloud resource by
system-assigned unique identifier (https://google.aip.dev/148#uid). If a
resource is deleted and recreated with the same name, the binding will not
be applicable to the new resource

Example:
`principal://parametermanager.googleapis.com/projects/12345/uid/locations/us-central1-a/parameters/a918fed5`

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Iam::V1::ResourcePolicyMember::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
