package Google::Cloud::Policytroubleshooter::V1::Checker;

use strict;
use warnings;

our $VERSION = '0.14';

use Protobuf::Message;
use Protobuf::DescriptorPool;
use Protobuf::Internal qw(:all);
use MIME::Base64;

BEGIN {
    eval { require Google::Cloud::Policytroubleshooter::V1::Explanations };
    eval { require Google::Api::Annotations };
    eval { require Google::Api::Client };
    eval { require Google::Rpc::Status };
    my $descriptor_b64 = <<'EOF';
CjJnb29nbGUvY2xvdWQvcG9saWN5dHJvdWJsZXNob290ZXIvdjEvY2hlY2tlci5wcm90bxIk
Z29vZ2xlLmNsb3VkLnBvbGljeXRyb3VibGVzaG9vdGVyLnYxGjdnb29nbGUvY2xvdWQvcG9s
aWN5dHJvdWJsZXNob290ZXIvdjEvZXhwbGFuYXRpb25zLnByb3RvGhxnb29nbGUvYXBpL2Fu
bm90YXRpb25zLnByb3RvGhdnb29nbGUvYXBpL2NsaWVudC5wcm90bxoXZ29vZ2xlL3JwYy9z
dGF0dXMucHJvdG8idAocVHJvdWJsZXNob290SWFtUG9saWN5UmVxdWVzdBJUCgxhY2Nlc3Nf
dHVwbGUYASABKAsyMS5nb29nbGUuY2xvdWQucG9saWN5dHJvdWJsZXNob290ZXIudjEuQWNj
ZXNzVHVwbGVSC2FjY2Vzc1R1cGxlIvwBCh1Ucm91Ymxlc2hvb3RJYW1Qb2xpY3lSZXNwb25z
ZRJJCgZhY2Nlc3MYASABKA4yMS5nb29nbGUuY2xvdWQucG9saWN5dHJvdWJsZXNob290ZXIu
djEuQWNjZXNzU3RhdGVSBmFjY2VzcxJkChJleHBsYWluZWRfcG9saWNpZXMYAiADKAsyNS5n
b29nbGUuY2xvdWQucG9saWN5dHJvdWJsZXNob290ZXIudjEuRXhwbGFpbmVkUG9saWN5UhFl
eHBsYWluZWRQb2xpY2llcxIqCgZlcnJvcnMYAyADKAsyEi5nb29nbGUucnBjLlN0YXR1c1IG
ZXJyb3JzMqkCCgpJYW1DaGVja2VyEsEBChVUcm91Ymxlc2hvb3RJYW1Qb2xpY3kSQi5nb29n
bGUuY2xvdWQucG9saWN5dHJvdWJsZXNob290ZXIudjEuVHJvdWJsZXNob290SWFtUG9saWN5
UmVxdWVzdBpDLmdvb2dsZS5jbG91ZC5wb2xpY3l0cm91Ymxlc2hvb3Rlci52MS5Ucm91Ymxl
c2hvb3RJYW1Qb2xpY3lSZXNwb25zZSIfgtPkkwIZIhQvdjEvaWFtOnRyb3VibGVzaG9vdDoB
KhpXykEjcG9saWN5dHJvdWJsZXNob290ZXIuZ29vZ2xlYXBpcy5jb23SQS5odHRwczovL3d3
dy5nb29nbGVhcGlzLmNvbS9hdXRoL2Nsb3VkLXBsYXRmb3JtQpYCCihjb20uZ29vZ2xlLmNs
b3VkLnBvbGljeXRyb3VibGVzaG9vdGVyLnYxQg9JQU1DaGVja2VyUHJvdG9QAVpcY2xvdWQu
Z29vZ2xlLmNvbS9nby9wb2xpY3l0cm91Ymxlc2hvb3Rlci9hcGl2MS9wb2xpY3l0cm91Ymxl
c2hvb3RlcnBiO3BvbGljeXRyb3VibGVzaG9vdGVycGL4AQGqAiRHb29nbGUuQ2xvdWQuUG9s
aWN5VHJvdWJsZXNob290ZXIuVjHKAiRHb29nbGVcQ2xvdWRcUG9saWN5VHJvdWJsZXNob290
ZXJcVjHqAidHb29nbGU6OkNsb3VkOjpQb2xpY3lUcm91Ymxlc2hvb3Rlcjo6VjFKlRQKBhIE
DgBSAQq8BAoBDBIDDgASMrEEIENvcHlyaWdodCAyMDI1IEdvb2dsZSBMTEMKCiBMaWNlbnNl
ZCB1bmRlciB0aGUgQXBhY2hlIExpY2Vuc2UsIFZlcnNpb24gMi4wICh0aGUgIkxpY2Vuc2Ui
KTsKIHlvdSBtYXkgbm90IHVzZSB0aGlzIGZpbGUgZXhjZXB0IGluIGNvbXBsaWFuY2Ugd2l0
aCB0aGUgTGljZW5zZS4KIFlvdSBtYXkgb2J0YWluIGEgY29weSBvZiB0aGUgTGljZW5zZSBh
dAoKICAgICBodHRwOi8vd3d3LmFwYWNoZS5vcmcvbGljZW5zZXMvTElDRU5TRS0yLjAKCiBV
bmxlc3MgcmVxdWlyZWQgYnkgYXBwbGljYWJsZSBsYXcgb3IgYWdyZWVkIHRvIGluIHdyaXRp
bmcsIHNvZnR3YXJlCiBkaXN0cmlidXRlZCB1bmRlciB0aGUgTGljZW5zZSBpcyBkaXN0cmli
dXRlZCBvbiBhbiAiQVMgSVMiIEJBU0lTLAogV0lUSE9VVCBXQVJSQU5USUVTIE9SIENPTkRJ
VElPTlMgT0YgQU5ZIEtJTkQsIGVpdGhlciBleHByZXNzIG9yIGltcGxpZWQuCiBTZWUgdGhl
IExpY2Vuc2UgZm9yIHRoZSBzcGVjaWZpYyBsYW5ndWFnZSBnb3Zlcm5pbmcgcGVybWlzc2lv
bnMgYW5kCiBsaW1pdGF0aW9ucyB1bmRlciB0aGUgTGljZW5zZS4KCggKAQISAxAALQoJCgID
ABIDEgBICgkKAgoAEgMSBw0KCQoCAwESAxQAJgoJCgIDAhIDFQAhCgkKAgMDEgMWACEKCAoB
CBIDGAAfCgkKAggfEgMYAB8KCAoBCBIDGQBBCgkKAgglEgMZAEEKCAoBCBIDGgBzCgkKAggL
EgMaAHMKCAoBCBIDGwAiCgkKAggKEgMbACIKCAoBCBIDHAAwCgkKAggIEgMcADAKCAoBCBID
HQBBCgkKAggBEgMdAEEKCAoBCBIDHgBBCgkKAggpEgMeAEEKCAoBCBIDHwBACgkKAggtEgMf
AEAKgAEKAgYAEgQkADMBGnQgSUFNIFBvbGljeSBUcm91Ymxlc2hvb3RlciBzZXJ2aWNlLgoK
IFRoaXMgc2VydmljZSBoZWxwcyB5b3UgdHJvdWJsZXNob290IGFjY2VzcyBpc3N1ZXMgZm9y
IEdvb2dsZSBDbG91ZCByZXNvdXJjZXMuCgoKCgMGAAESAyQIEgoKCgMGAAMSAyUCSwoMCgUG
AAOZCBIDJQJLCgsKAwYAAxIEJgInNwoNCgUGAAOaCBIEJgInNwqmAQoEBgACABIELAIyAxqX
ASBDaGVja3Mgd2hldGhlciBhIHByaW5jaXBhbCBoYXMgYSBzcGVjaWZpYyBwZXJtaXNzaW9u
IGZvciBhIHNwZWNpZmljCiByZXNvdXJjZSwgYW5kIGV4cGxhaW5zIHdoeSB0aGUgcHJpbmNp
cGFsIGRvZXMgb3IgZG9lcyBub3QgaGF2ZSB0aGF0CiBwZXJtaXNzaW9uLgoKDAoFBgACAAES
AywGGwoMCgUGAAIAAhIDLBw4CgwKBQYAAgADEgMtDywKDQoFBgACAAQSBC4EMQYKEQoJBgAC
AASwyrwiEgQuBDEGCnoKAgQAEgQ3ADsBGm4gUmVxdWVzdCBmb3IKIFtUcm91Ymxlc2hvb3RJ
YW1Qb2xpY3ldW2dvb2dsZS5jbG91ZC5wb2xpY3l0cm91Ymxlc2hvb3Rlci52MS5JYW1DaGVj
a2VyLlRyb3VibGVzaG9vdElhbVBvbGljeV0uCgoKCgMEAAESAzcIJApoCgQEAAIAEgM6Ah8a
WyBUaGUgaW5mb3JtYXRpb24gdG8gdXNlIGZvciBjaGVja2luZyB3aGV0aGVyIGEgcHJpbmNp
cGFsIGhhcyBhIHBlcm1pc3Npb24KIGZvciBhIHJlc291cmNlLgoKDAoFBAACAAYSAzoCDQoM
CgUEAAIAARIDOg4aCgwKBQQAAgADEgM6HR4KewoCBAESBD8AUgEabyBSZXNwb25zZSBmb3IK
IFtUcm91Ymxlc2hvb3RJYW1Qb2xpY3ldW2dvb2dsZS5jbG91ZC5wb2xpY3l0cm91Ymxlc2hv
b3Rlci52MS5JYW1DaGVja2VyLlRyb3VibGVzaG9vdElhbVBvbGljeV0uCgoKCgMEAQESAz8I
JQqhAQoEBAECABIDQgIZGpMBIEluZGljYXRlcyB3aGV0aGVyIHRoZSBwcmluY2lwYWwgaGFz
IHRoZSBzcGVjaWZpZWQgcGVybWlzc2lvbiBmb3IgdGhlCiBzcGVjaWZpZWQgcmVzb3VyY2Us
IGJhc2VkIG9uIGV2YWx1YXRpbmcgYWxsIG9mIHRoZSBhcHBsaWNhYmxlIElBTSBwb2xpY2ll
cy4KCgwKBQQBAgAGEgNCAg0KDAoFBAECAAESA0IOFAoMCgUEAQIAAxIDQhcYCvcDCgQEAQIB
EgNOAjIa6QMgTGlzdCBvZiBJQU0gcG9saWNpZXMgdGhhdCB3ZXJlIGV2YWx1YXRlZCB0byBj
aGVjayB0aGUgcHJpbmNpcGFsJ3MKIHBlcm1pc3Npb25zLCB3aXRoIGFubm90YXRpb25zIHRv
IGluZGljYXRlIGhvdyBlYWNoIHBvbGljeSBjb250cmlidXRlZCB0bwogdGhlIGZpbmFsIHJl
c3VsdC4KCiBUaGUgbGlzdCBvZiBwb2xpY2llcyBjYW4gaW5jbHVkZSB0aGUgcG9saWN5IGZv
ciB0aGUgcmVzb3VyY2UgaXRzZWxmLiBJdCBjYW4KIGFsc28gaW5jbHVkZSBwb2xpY2llcyB0
aGF0IGFyZSBpbmhlcml0ZWQgZnJvbSBoaWdoZXIgbGV2ZWxzIG9mIHRoZSByZXNvdXJjZQog
aGllcmFyY2h5LCBpbmNsdWRpbmcgdGhlIG9yZ2FuaXphdGlvbiwgdGhlIGZvbGRlciwgYW5k
IHRoZSBwcm9qZWN0LgoKIFRvIGxlYXJuIG1vcmUgYWJvdXQgdGhlIHJlc291cmNlIGhpZXJh
cmNoeSwgc2VlCiBodHRwczovL2Nsb3VkLmdvb2dsZS5jb20vaWFtL2hlbHAvcmVzb3VyY2Ut
aGllcmFyY2h5LgoKDAoFBAECAQQSA04CCgoMCgUEAQIBBhIDTgsaCgwKBQQBAgEBEgNOGy0K
DAoFBAECAQMSA04wMQpMCgQEAQICEgNRAigaPyBUaGUgZ2VuZXJhbCBlcnJvcnMgY29udGFp
bmVkIGluIHRoZSB0cm91Ymxlc2hvb3RpbmcgcmVzcG9uc2UuCgoMCgUEAQICBBIDUQIKCgwK
BQQBAgIGEgNRCxwKDAoFBAECAgESA1EdIwoMCgUEAQICAxIDUSYnUABiBnByb3RvMw==
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Policytroubleshooter::V1::Checker::TroubleshootIamPolicyRequest ===
    # Fields for TroubleshootIamPolicyRequest
    # Field: access_tuple Type: 11 (.google.cloud.policytroubleshooter.v1.AccessTuple)

# === Message: Google::Cloud::Policytroubleshooter::V1::Checker::TroubleshootIamPolicyResponse ===
    # Fields for TroubleshootIamPolicyResponse
    # Field: access Type: 14 (.google.cloud.policytroubleshooter.v1.AccessState)
    # Field: explained_policies Type: 11 (.google.cloud.policytroubleshooter.v1.ExplainedPolicy)
    # Field: errors Type: 11 (.google.rpc.Status)

# === Service Client: Google::Cloud::Policytroubleshooter::V1::Checker::IamCheckerClient ===
package Google::Cloud::Policytroubleshooter::V1::Checker::IamCheckerClient;

=pod

=head2 Service Client: Google::Cloud::Policytroubleshooter::V1::Checker::IamCheckerClient

Client stub representing the remote C<IamChecker> gRPC service. Delegates call dispatching to L<Google::gRPC::Client>.

=head3 target

The endpoint target address. Defaults to C<policytroubleshooter.googleapis.com:443>.

=head3 credentials

The authentication credentials provider. Defaults to application default credentials via L<Google::Auth>.

=cut

use Moo;
use Google::Auth;
use Google::gRPC::Client;

has credentials => ( is => 'ro', default => sub { Google::Auth->default() } );
has target      => ( is => 'ro', default => 'policytroubleshooter.googleapis.com:443' );

has _grpc_client => (
    is => 'ro',
    lazy => 1,
    builder => sub {
        my $self = shift;
        return Google::gRPC::Client->new(
            target     => $self->target,
            auth_token => $self->credentials->get_token(),
        );
    }
);

sub troubleshoot_iam_policy {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Policytroubleshooter::V1::Checker::TroubleshootIamPolicyRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.policytroubleshooter.v1.IamChecker',
        method         => 'TroubleshootIamPolicy',
        request        => $req,
        response_class => 'Google::Cloud::Policytroubleshooter::V1::Checker::TroubleshootIamPolicyResponse',
    });
}

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Policytroubleshooter::V1::Checker - Compiled Protocol Buffers messages for google/cloud/policytroubleshooter/v1/checker.proto

=head1 SYNOPSIS

    use Google::Cloud::Policytroubleshooter::V1::Checker;

    my $msg = Google::Cloud::Policytroubleshooter::V1::Checker::TroubleshootIamPolicyRequest->new({
        access_tuple => $access_tuple,
    });

    # Read or update a field
    my $val = $msg->access_tuple();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Policytroubleshooter::V1::Checker::TroubleshootIamPolicyRequest->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/policytroubleshooter/v1/checker.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Policytroubleshooter::V1::Checker::TroubleshootIamPolicyRequest

Request for
[TroubleshootIamPolicy][google.cloud.policytroubleshooter.v1.IamChecker.TroubleshootIamPolicy].

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->access_tuple() >> / C<< $msg->access_tuple($value) >>

Type: C<Message> (L<Google::Cloud::Policytroubleshooter::V1::Explanations::AccessTuple>)

The information to use for checking whether a principal has a permission
for a resource.

=back

=head2 Google::Cloud::Policytroubleshooter::V1::Checker::TroubleshootIamPolicyResponse

Response for
[TroubleshootIamPolicy][google.cloud.policytroubleshooter.v1.IamChecker.TroubleshootIamPolicy].

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->access() >> / C<< $msg->access($value) >>

Type: C<Enum> (L<Google::Cloud::Policytroubleshooter::V1::AccessState>)

Indicates whether the principal has the specified permission for the
specified resource, based on evaluating all of the applicable IAM policies.

=item * C<< $msg->explained_policies() >> / C<< $msg->explained_policies($value) >>

Type: C<Message> (L<Google::Cloud::Policytroubleshooter::V1::Explanations::ExplainedPolicy>)

List of IAM policies that were evaluated to check the principal's
permissions, with annotations to indicate how each policy contributed to
the final result.

The list of policies can include the policy for the resource itself. It can
also include policies that are inherited from higher levels of the resource
hierarchy, including the organization, the folder, and the project.

To learn more about the resource hierarchy, see
https://cloud.google.com/iam/help/resource-hierarchy.

=item * C<< $msg->errors() >> / C<< $msg->errors($value) >>

Type: C<Message> (L<Google::Rpc::Status::Status>)

The general errors contained in the troubleshooting response.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Policytroubleshooter::V1::Checker::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
