package Google::Iam::V1::Options;

use strict;
use warnings;

our $VERSION = '0.14';

use Protobuf::Message;
use Protobuf::DescriptorPool;
use Protobuf::Internal qw(:all);
use MIME::Base64;

BEGIN {
    my $descriptor_b64 = <<'EOF';
Chtnb29nbGUvaWFtL3YxL29wdGlvbnMucHJvdG8SDWdvb2dsZS5pYW0udjEiTAoQR2V0UG9s
aWN5T3B0aW9ucxI4ChhyZXF1ZXN0ZWRfcG9saWN5X3ZlcnNpb24YASABKAVSFnJlcXVlc3Rl
ZFBvbGljeVZlcnNpb25CfQoRY29tLmdvb2dsZS5pYW0udjFCDE9wdGlvbnNQcm90b1ABWilj
bG91ZC5nb29nbGUuY29tL2dvL2lhbS9hcGl2MS9pYW1wYjtpYW1wYvgBAaoCE0dvb2dsZS5D
bG91ZC5JYW0uVjHKAhNHb29nbGVcQ2xvdWRcSWFtXFYxStkMCgYSBA4ALwEKvAQKAQwSAw4A
EjKxBCBDb3B5cmlnaHQgMjAyNSBHb29nbGUgTExDCgogTGljZW5zZWQgdW5kZXIgdGhlIEFw
YWNoZSBMaWNlbnNlLCBWZXJzaW9uIDIuMCAodGhlICJMaWNlbnNlIik7CiB5b3UgbWF5IG5v
dCB1c2UgdGhpcyBmaWxlIGV4Y2VwdCBpbiBjb21wbGlhbmNlIHdpdGggdGhlIExpY2Vuc2Uu
CiBZb3UgbWF5IG9idGFpbiBhIGNvcHkgb2YgdGhlIExpY2Vuc2UgYXQKCiAgICAgaHR0cDov
L3d3dy5hcGFjaGUub3JnL2xpY2Vuc2VzL0xJQ0VOU0UtMi4wCgogVW5sZXNzIHJlcXVpcmVk
IGJ5IGFwcGxpY2FibGUgbGF3IG9yIGFncmVlZCB0byBpbiB3cml0aW5nLCBzb2Z0d2FyZQog
ZGlzdHJpYnV0ZWQgdW5kZXIgdGhlIExpY2Vuc2UgaXMgZGlzdHJpYnV0ZWQgb24gYW4gIkFT
IElTIiBCQVNJUywKIFdJVEhPVVQgV0FSUkFOVElFUyBPUiBDT05ESVRJT05TIE9GIEFOWSBL
SU5ELCBlaXRoZXIgZXhwcmVzcyBvciBpbXBsaWVkLgogU2VlIHRoZSBMaWNlbnNlIGZvciB0
aGUgc3BlY2lmaWMgbGFuZ3VhZ2UgZ292ZXJuaW5nIHBlcm1pc3Npb25zIGFuZAogbGltaXRh
dGlvbnMgdW5kZXIgdGhlIExpY2Vuc2UuCgoICgECEgMQABYKCAoBCBIDEgAfCgkKAggfEgMS
AB8KCAoBCBIDEwAwCgkKAgglEgMTADAKCAoBCBIDFABACgkKAggLEgMUAEAKCAoBCBIDFQAi
CgkKAggKEgMVACIKCAoBCBIDFgAtCgkKAggIEgMWAC0KCAoBCBIDFwAqCgkKAggBEgMXACoK
CAoBCBIDGAAwCgkKAggpEgMYADAKPQoCBAASBBsALwEaMSBFbmNhcHN1bGF0ZXMgc2V0dGlu
Z3MgcHJvdmlkZWQgdG8gR2V0SWFtUG9saWN5LgoKCgoDBAABEgMbCBgK/QUKBAQAAgASAy4C
JRrvBSBPcHRpb25hbC4gVGhlIG1heGltdW0gcG9saWN5IHZlcnNpb24gdGhhdCB3aWxsIGJl
IHVzZWQgdG8gZm9ybWF0IHRoZQogcG9saWN5LgoKIFZhbGlkIHZhbHVlcyBhcmUgMCwgMSwg
YW5kIDMuIFJlcXVlc3RzIHNwZWNpZnlpbmcgYW4gaW52YWxpZCB2YWx1ZSB3aWxsIGJlCiBy
ZWplY3RlZC4KCiBSZXF1ZXN0cyBmb3IgcG9saWNpZXMgd2l0aCBhbnkgY29uZGl0aW9uYWwg
cm9sZSBiaW5kaW5ncyBtdXN0IHNwZWNpZnkKIHZlcnNpb24gMy4gUG9saWNpZXMgd2l0aCBu
byBjb25kaXRpb25hbCByb2xlIGJpbmRpbmdzIG1heSBzcGVjaWZ5IGFueSB2YWxpZAogdmFs
dWUgb3IgbGVhdmUgdGhlIGZpZWxkIHVuc2V0LgoKIFRoZSBwb2xpY3kgaW4gdGhlIHJlc3Bv
bnNlIG1pZ2h0IHVzZSB0aGUgcG9saWN5IHZlcnNpb24gdGhhdCB5b3Ugc3BlY2lmaWVkLAog
b3IgaXQgbWlnaHQgdXNlIGEgbG93ZXIgcG9saWN5IHZlcnNpb24uIEZvciBleGFtcGxlLCBp
ZiB5b3Ugc3BlY2lmeSB2ZXJzaW9uCiAzLCBidXQgdGhlIHBvbGljeSBoYXMgbm8gY29uZGl0
aW9uYWwgcm9sZSBiaW5kaW5ncywgdGhlIHJlc3BvbnNlIHVzZXMKIHZlcnNpb24gMS4KCiBU
byBsZWFybiB3aGljaCByZXNvdXJjZXMgc3VwcG9ydCBjb25kaXRpb25zIGluIHRoZWlyIElB
TSBwb2xpY2llcywgc2VlIHRoZQogW0lBTQogZG9jdW1lbnRhdGlvbl0oaHR0cHM6Ly9jbG91
ZC5nb29nbGUuY29tL2lhbS9oZWxwL2NvbmRpdGlvbnMvcmVzb3VyY2UtcG9saWNpZXMpLgoK
DAoFBAACAAUSAy4CBwoMCgUEAAIAARIDLgggCgwKBQQAAgADEgMuIyRiBnByb3RvMw==
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Iam::V1::Options::GetPolicyOptions ===
    # Fields for GetPolicyOptions
    # Field: requested_policy_version Type: 5 ()

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Iam::V1::Options - Compiled Protocol Buffers messages for google/iam/v1/options.proto

=head1 SYNOPSIS

    use Google::Iam::V1::Options;

    my $msg = Google::Iam::V1::Options::GetPolicyOptions->new({
        requested_policy_version => $requested_policy_version,
    });

    # Read or update a field
    my $val = $msg->requested_policy_version();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Iam::V1::Options::GetPolicyOptions->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/iam/v1/options.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Iam::V1::Options::GetPolicyOptions

Encapsulates settings provided to GetIamPolicy.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->requested_policy_version() >> / C<< $msg->requested_policy_version($value) >>

Type: C<Int32>

Optional. The maximum policy version that will be used to format the
policy.

Valid values are 0, 1, and 3. Requests specifying an invalid value will be
rejected.

Requests for policies with any conditional role bindings must specify
version 3. Policies with no conditional role bindings may specify any valid
value or leave the field unset.

The policy in the response might use the policy version that you specified,
or it might use a lower policy version. For example, if you specify version
3, but the policy has no conditional role bindings, the response uses
version 1.

To learn which resources support conditions in their IAM policies, see the
[IAM
documentation](https://cloud.google.com/iam/help/conditions/resource-policies).

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Iam::V1::Options::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
