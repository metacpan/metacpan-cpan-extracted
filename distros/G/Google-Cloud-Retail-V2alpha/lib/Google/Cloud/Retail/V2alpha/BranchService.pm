package Google::Cloud::Retail::V2alpha::BranchService;

use strict;
use warnings;

our $VERSION = '0.14';

use Protobuf::Message;
use Protobuf::DescriptorPool;
use Protobuf::Internal qw(:all);
use MIME::Base64;

BEGIN {
    eval { require Google::Api::Annotations };
    eval { require Google::Api::Client };
    eval { require Google::Api::FieldBehavior };
    eval { require Google::Api::Resource };
    eval { require Google::Cloud::Retail::V2alpha::Branch };
    my $descriptor_b64 = <<'EOF';
CjBnb29nbGUvY2xvdWQvcmV0YWlsL3YyYWxwaGEvYnJhbmNoX3NlcnZpY2UucHJvdG8SG2dv
b2dsZS5jbG91ZC5yZXRhaWwudjJhbHBoYRocZ29vZ2xlL2FwaS9hbm5vdGF0aW9ucy5wcm90
bxoXZ29vZ2xlL2FwaS9jbGllbnQucHJvdG8aH2dvb2dsZS9hcGkvZmllbGRfYmVoYXZpb3Iu
cHJvdG8aGWdvb2dsZS9hcGkvcmVzb3VyY2UucHJvdG8aKGdvb2dsZS9jbG91ZC9yZXRhaWwv
djJhbHBoYS9icmFuY2gucHJvdG8ikQEKE0xpc3RCcmFuY2hlc1JlcXVlc3QSPQoGcGFyZW50
GAEgASgJQiXgQQL6QR8KHXJldGFpbC5nb29nbGVhcGlzLmNvbS9DYXRhbG9nUgZwYXJlbnQS
OwoEdmlldxgCIAEoDjInLmdvb2dsZS5jbG91ZC5yZXRhaWwudjJhbHBoYS5CcmFuY2hWaWV3
UgR2aWV3IlcKFExpc3RCcmFuY2hlc1Jlc3BvbnNlEj8KCGJyYW5jaGVzGAEgAygLMiMuZ29v
Z2xlLmNsb3VkLnJldGFpbC52MmFscGhhLkJyYW5jaFIIYnJhbmNoZXMiiQEKEEdldEJyYW5j
aFJlcXVlc3QSOAoEbmFtZRgBIAEoCUIk4EEC+kEeChxyZXRhaWwuZ29vZ2xlYXBpcy5jb20v
QnJhbmNoUgRuYW1lEjsKBHZpZXcYAiABKA4yJy5nb29nbGUuY2xvdWQucmV0YWlsLnYyYWxw
aGEuQnJhbmNoVmlld1IEdmlldzLOAwoNQnJhbmNoU2VydmljZRLCAQoMTGlzdEJyYW5jaGVz
EjAuZ29vZ2xlLmNsb3VkLnJldGFpbC52MmFscGhhLkxpc3RCcmFuY2hlc1JlcXVlc3QaMS5n
b29nbGUuY2xvdWQucmV0YWlsLnYyYWxwaGEuTGlzdEJyYW5jaGVzUmVzcG9uc2UiTYLT5JMC
PhI8L3YyYWxwaGEve3BhcmVudD1wcm9qZWN0cy8qL2xvY2F0aW9ucy8qL2NhdGFsb2dzLyp9
L2JyYW5jaGVz2kEGcGFyZW50EqwBCglHZXRCcmFuY2gSLS5nb29nbGUuY2xvdWQucmV0YWls
LnYyYWxwaGEuR2V0QnJhbmNoUmVxdWVzdBojLmdvb2dsZS5jbG91ZC5yZXRhaWwudjJhbHBo
YS5CcmFuY2giS4LT5JMCPhI8L3YyYWxwaGEve25hbWU9cHJvamVjdHMvKi9sb2NhdGlvbnMv
Ki9jYXRhbG9ncy8qL2JyYW5jaGVzLyp92kEEbmFtZRpJykEVcmV0YWlsLmdvb2dsZWFwaXMu
Y29t0kEuaHR0cHM6Ly93d3cuZ29vZ2xlYXBpcy5jb20vYXV0aC9jbG91ZC1wbGF0Zm9ybULW
AQofY29tLmdvb2dsZS5jbG91ZC5yZXRhaWwudjJhbHBoYUISQnJhbmNoU2VydmljZVByb3Rv
UAFaN2Nsb3VkLmdvb2dsZS5jb20vZ28vcmV0YWlsL2FwaXYyYWxwaGEvcmV0YWlscGI7cmV0
YWlscGKiAgZSRVRBSUyqAhtHb29nbGUuQ2xvdWQuUmV0YWlsLlYyQWxwaGHKAhtHb29nbGVc
Q2xvdWRcUmV0YWlsXFYyYWxwaGHqAh5Hb29nbGU6OkNsb3VkOjpSZXRhaWw6OlYyYWxwaGFK
uhoKBhIEDgBuAQq8BAoBDBIDDgASMrEEIENvcHlyaWdodCAyMDI1IEdvb2dsZSBMTEMKCiBM
aWNlbnNlZCB1bmRlciB0aGUgQXBhY2hlIExpY2Vuc2UsIFZlcnNpb24gMi4wICh0aGUgIkxp
Y2Vuc2UiKTsKIHlvdSBtYXkgbm90IHVzZSB0aGlzIGZpbGUgZXhjZXB0IGluIGNvbXBsaWFu
Y2Ugd2l0aCB0aGUgTGljZW5zZS4KIFlvdSBtYXkgb2J0YWluIGEgY29weSBvZiB0aGUgTGlj
ZW5zZSBhdAoKICAgICBodHRwOi8vd3d3LmFwYWNoZS5vcmcvbGljZW5zZXMvTElDRU5TRS0y
LjAKCiBVbmxlc3MgcmVxdWlyZWQgYnkgYXBwbGljYWJsZSBsYXcgb3IgYWdyZWVkIHRvIGlu
IHdyaXRpbmcsIHNvZnR3YXJlCiBkaXN0cmlidXRlZCB1bmRlciB0aGUgTGljZW5zZSBpcyBk
aXN0cmlidXRlZCBvbiBhbiAiQVMgSVMiIEJBU0lTLAogV0lUSE9VVCBXQVJSQU5USUVTIE9S
IENPTkRJVElPTlMgT0YgQU5ZIEtJTkQsIGVpdGhlciBleHByZXNzIG9yIGltcGxpZWQuCiBT
ZWUgdGhlIExpY2Vuc2UgZm9yIHRoZSBzcGVjaWZpYyBsYW5ndWFnZSBnb3Zlcm5pbmcgcGVy
bWlzc2lvbnMgYW5kCiBsaW1pdGF0aW9ucyB1bmRlciB0aGUgTGljZW5zZS4KCggKAQISAxAA
JAoJCgIDABIDEgAmCgkKAgMBEgMTACEKCQoCAwISAxQAKQoJCgIDAxIDFQAjCgkKAgMEEgMW
ADIKCAoBCBIDGAA4CgkKAgglEgMYADgKCAoBCBIDGQBOCgkKAggLEgMZAE4KCAoBCBIDGgAi
CgkKAggKEgMaACIKCAoBCBIDGwAzCgkKAggIEgMbADMKCAoBCBIDHAA4CgkKAggBEgMcADgK
CAoBCBIDHQAkCgkKAggkEgMdACQKCAoBCBIDHgA4CgkKAggpEgMeADgKCAoBCBIDHwA3CgkK
AggtEgMfADcKkQMKAgYAEgQoAD0BGoQDIFNlcnZpY2UgZm9yIFtCcmFuY2hdW2dvb2dsZS5j
bG91ZC5yZXRhaWwudjJhbHBoYS5CcmFuY2hdIE1hbmFnZW1lbnQKCiBbQnJhbmNoXVtnb29n
bGUuY2xvdWQucmV0YWlsLnYyYWxwaGEuQnJhbmNoXWVzIGFyZSBhdXRvbWF0aWNhbGx5IGNy
ZWF0ZWQgd2hlbgogYSBbQ2F0YWxvZ11bZ29vZ2xlLmNsb3VkLnJldGFpbC52MmFscGhhLkNh
dGFsb2ddIGlzIGNyZWF0ZWQuIFRoZXJlIGFyZSBmaXhlZAogdGhyZWUgYnJhbmNoZXMgaW4g
ZWFjaCBjYXRhbG9nLCBhbmQgbWF5IHVzZQogW0xpc3RCcmFuY2hlc11bZ29vZ2xlLmNsb3Vk
LnJldGFpbC52MmFscGhhLkJyYW5jaFNlcnZpY2UuTGlzdEJyYW5jaGVzXSBtZXRob2QKIHRv
IGdldCB0aGUgZGV0YWlscyBvZiBhbGwgYnJhbmNoZXMuCgoKCgMGAAESAygIFQoKCgMGAAMS
AykCPQoMCgUGAAOZCBIDKQI9CgsKAwYAAxIEKgIrNwoNCgUGAAOaCBIEKgIrNwqgAQoEBgAC
ABIELwI0AxqRASBMaXN0cyBhbGwgaW5zdGFuY2VzIG9mIFtCcmFuY2hdW2dvb2dsZS5jbG91
ZC5yZXRhaWwudjJhbHBoYS5CcmFuY2hdIHVuZGVyCiB0aGUgc3BlY2lmaWVkIHBhcmVudCBb
Q2F0YWxvZ11bZ29vZ2xlLmNsb3VkLnJldGFpbC52MmFscGhhLkNhdGFsb2ddLgoKDAoFBgAC
AAESAy8GEgoMCgUGAAIAAhIDLxMmCgwKBQYAAgADEgMvMUUKDQoFBgACAAQSBDAEMgYKEQoJ
BgACAASwyrwiEgQwBDIGCgwKBQYAAgAEEgMzBDQKDwoIBgACAASbCAASAzMENApJCgQGAAIB
EgQ3AjwDGjsgUmV0cmlldmVzIGEgW0JyYW5jaF1bZ29vZ2xlLmNsb3VkLnJldGFpbC52MmFs
cGhhLkJyYW5jaF0uCgoMCgUGAAIBARIDNwYPCgwKBQYAAgECEgM3ECAKDAoFBgACAQMSAzcr
MQoNCgUGAAIBBBIEOAQ6BgoRCgkGAAIBBLDKvCISBDgEOgYKDAoFBgACAQQSAzsEMgoPCggG
AAIBBJsIABIDOwQyCngKAgQAEgRCAE8BGmwgUmVxdWVzdCBmb3IKIFtCcmFuY2hTZXJ2aWNl
Lkxpc3RCcmFuY2hlc11bZ29vZ2xlLmNsb3VkLnJldGFpbC52MmFscGhhLkJyYW5jaFNlcnZp
Y2UuTGlzdEJyYW5jaGVzXQogbWV0aG9kLgoKCgoDBAABEgNCCBsKOwoEBAACABIERAJHBBot
IFJlcXVpcmVkLiBUaGUgcGFyZW50IGNhdGFsb2cgcmVzb3VyY2UgbmFtZS4KCgwKBQQAAgAF
EgNEAggKDAoFBAACAAESA0QJDwoMCgUEAAIAAxIDRBITCg0KBQQAAgAIEgREFEcDCg8KCAQA
AgAInAgAEgNFBCoKDgoHBAACAAifCBIDRgRPCpcCCgQEAAIBEgNOAhYaiQIgVGhlIHZpZXcg
dG8gYXBwbHkgdG8gdGhlIHJldHVybmVkCiBbQnJhbmNoXVtnb29nbGUuY2xvdWQucmV0YWls
LnYyYWxwaGEuQnJhbmNoXS4gRGVmYXVsdHMgdG8KIFtCcmFuY2guQnJhbmNoVmlldy5CQVNJ
Q10gaWYgdW5zcGVjaWZpZWQuCiBTZWUgZG9jdW1lbnRhdGlvbiBvZiBmaWVsZHMgb2YgW0Jy
YW5jaF1bZ29vZ2xlLmNsb3VkLnJldGFpbC52MmFscGhhLkJyYW5jaF0KIHRvIGZpbmQgd2hh
dCBmaWVsZHMgYXJlIGV4Y2x1ZGVkIGZyb20gQkFTSUMgdmlldy4KCgwKBQQAAgEGEgNOAgwK
DAoFBAACAQESA04NEQoMCgUEAAIBAxIDThQVCnkKAgQBEgRUAFcBGm0gUmVzcG9uc2UgZm9y
CiBbQnJhbmNoU2VydmljZS5MaXN0QnJhbmNoZXNdW2dvb2dsZS5jbG91ZC5yZXRhaWwudjJh
bHBoYS5CcmFuY2hTZXJ2aWNlLkxpc3RCcmFuY2hlc10KIG1ldGhvZC4KCgoKAwQBARIDVAgc
ChwKBAQBAgASA1YCHxoPIFRoZSBCcmFuY2hlcy4KCgwKBQQBAgAEEgNWAgoKDAoFBAECAAYS
A1YLEQoMCgUEAQIAARIDVhIaCgwKBQQBAgADEgNWHR4KcgoCBAISBFwAbgEaZiBSZXF1ZXN0
IGZvcgogW0JyYW5jaFNlcnZpY2UuR2V0QnJhbmNoXVtnb29nbGUuY2xvdWQucmV0YWlsLnYy
YWxwaGEuQnJhbmNoU2VydmljZS5HZXRCcmFuY2hdCiBtZXRob2QuCgoKCgMEAgESA1wIGAqR
AgoEBAICABIEYwJmBBqCAiBSZXF1aXJlZC4gVGhlIG5hbWUgb2YgdGhlIGJyYW5jaCB0byBy
ZXRyaWV2ZS4KIEZvcm1hdDoKIGBwcm9qZWN0cy8qL2xvY2F0aW9ucy9nbG9iYWwvY2F0YWxv
Z3MvZGVmYXVsdF9jYXRhbG9nL2JyYW5jaGVzL3NvbWVfYnJhbmNoX2lkYC4KCiAiZGVmYXVs
dF9icmFuY2giIGNhbiBiZSB1c2VkIGFzIGEgc3BlY2lhbCBicmFuY2hfaWQsIGl0IHJldHVy
bnMgdGhlCiBkZWZhdWx0IGJyYW5jaCB0aGF0IGhhcyBiZWVuIHNldCBmb3IgdGhlIGNhdGFs
b2cuCgoMCgUEAgIABRIDYwIICgwKBQQCAgABEgNjCQ0KDAoFBAICAAMSA2MQEQoNCgUEAgIA
CBIEYxJmAwoPCggEAgIACJwIABIDZAQqCg4KBwQCAgAInwgSA2UETgqXAgoEBAICARIDbQIW
GokCIFRoZSB2aWV3IHRvIGFwcGx5IHRvIHRoZSByZXR1cm5lZAogW0JyYW5jaF1bZ29vZ2xl
LmNsb3VkLnJldGFpbC52MmFscGhhLkJyYW5jaF0uIERlZmF1bHRzIHRvCiBbQnJhbmNoLkJy
YW5jaFZpZXcuQkFTSUNdIGlmIHVuc3BlY2lmaWVkLgogU2VlIGRvY3VtZW50YXRpb24gb2Yg
ZmllbGRzIG9mIFtCcmFuY2hdW2dvb2dsZS5jbG91ZC5yZXRhaWwudjJhbHBoYS5CcmFuY2hd
CiB0byBmaW5kIHdoYXQgZmllbGRzIGFyZSBleGNsdWRlZCBmcm9tIEJBU0lDIHZpZXcuCgoM
CgUEAgIBBhIDbQIMCgwKBQQCAgEBEgNtDREKDAoFBAICAQMSA20UFWIGcHJvdG8z
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Retail::V2alpha::BranchService::ListBranchesRequest ===
    # Fields for ListBranchesRequest
    # Field: parent Type: 9 ()
    # Field: view Type: 14 (.google.cloud.retail.v2alpha.BranchView)

# === Message: Google::Cloud::Retail::V2alpha::BranchService::ListBranchesResponse ===
    # Fields for ListBranchesResponse
    # Field: branches Type: 11 (.google.cloud.retail.v2alpha.Branch)

# === Message: Google::Cloud::Retail::V2alpha::BranchService::GetBranchRequest ===
    # Fields for GetBranchRequest
    # Field: name Type: 9 ()
    # Field: view Type: 14 (.google.cloud.retail.v2alpha.BranchView)

# === Service Client: Google::Cloud::Retail::V2alpha::BranchService::BranchServiceClient ===
package Google::Cloud::Retail::V2alpha::BranchService::BranchServiceClient;

=pod

=head2 Service Client: Google::Cloud::Retail::V2alpha::BranchService::BranchServiceClient

Client stub representing the remote C<BranchService> gRPC service. Delegates call dispatching to L<Google::gRPC::Client>.

=head3 target

The endpoint target address. Defaults to C<retail.googleapis.com:443>.

=head3 credentials

The authentication credentials provider. Defaults to application default credentials via L<Google::Auth>.

=cut

use Moo;
use Google::Auth;
use Google::gRPC::Client;

has credentials => ( is => 'ro', default => sub { Google::Auth->default() } );
has target      => ( is => 'ro', default => 'retail.googleapis.com:443' );

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

sub list_branches {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Retail::V2alpha::BranchService::ListBranchesRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.retail.v2alpha.BranchService',
        method         => 'ListBranches',
        request        => $req,
        response_class => 'Google::Cloud::Retail::V2alpha::BranchService::ListBranchesResponse',
    });
}

sub get_branch {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Retail::V2alpha::BranchService::GetBranchRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.retail.v2alpha.BranchService',
        method         => 'GetBranch',
        request        => $req,
        response_class => 'Google::Cloud::Retail::V2alpha::Branch::Branch',
    });
}

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Retail::V2alpha::BranchService - Compiled Protocol Buffers messages for google/cloud/retail/v2alpha/branch_service.proto

=head1 SYNOPSIS

    use Google::Cloud::Retail::V2alpha::BranchService;

    my $msg = Google::Cloud::Retail::V2alpha::BranchService::ListBranchesRequest->new({
        parent => $parent,
        view => $view,
    });

    # Read or update a field
    my $val = $msg->parent();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Retail::V2alpha::BranchService::ListBranchesRequest->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/retail/v2alpha/branch_service.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Retail::V2alpha::BranchService::ListBranchesRequest

Request for
[BranchService.ListBranches][google.cloud.retail.v2alpha.BranchService.ListBranches]
method.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->parent() >> / C<< $msg->parent($value) >>

Type: C<String>

Required. The parent catalog resource name.

=item * C<< $msg->view() >> / C<< $msg->view($value) >>

Type: C<Enum> (L<Google::Cloud::Retail::V2alpha::BranchView>)

The view to apply to the returned
[Branch][google.cloud.retail.v2alpha.Branch]. Defaults to
[Branch.BranchView.BASIC] if unspecified.
See documentation of fields of [Branch][google.cloud.retail.v2alpha.Branch]
to find what fields are excluded from BASIC view.

=back

=head2 Google::Cloud::Retail::V2alpha::BranchService::ListBranchesResponse

Response for
[BranchService.ListBranches][google.cloud.retail.v2alpha.BranchService.ListBranches]
method.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->branches() >> / C<< $msg->branches($value) >>

Type: C<Message> (L<Google::Cloud::Retail::V2alpha::Branch::Branch>)

The Branches.

=back

=head2 Google::Cloud::Retail::V2alpha::BranchService::GetBranchRequest

Request for
[BranchService.GetBranch][google.cloud.retail.v2alpha.BranchService.GetBranch]
method.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. The name of the branch to retrieve.
Format:
`projects/*/locations/global/catalogs/default_catalog/branches/some_branch_id`.

"default_branch" can be used as a special branch_id, it returns the
default branch that has been set for the catalog.

=item * C<< $msg->view() >> / C<< $msg->view($value) >>

Type: C<Enum> (L<Google::Cloud::Retail::V2alpha::BranchView>)

The view to apply to the returned
[Branch][google.cloud.retail.v2alpha.Branch]. Defaults to
[Branch.BranchView.BASIC] if unspecified.
See documentation of fields of [Branch][google.cloud.retail.v2alpha.Branch]
to find what fields are excluded from BASIC view.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Retail::V2alpha::BranchService::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
