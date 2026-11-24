package Google::Cloud::Assuredworkloads::V1beta1::AssuredworkloadsService;

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
    eval { require Google::Cloud::Assuredworkloads::V1beta1::Assuredworkloads };
    eval { require Google::Longrunning::Operations };
    eval { require Google::Protobuf::Empty };
    my $descriptor_b64 = <<'EOF';
CkRnb29nbGUvY2xvdWQvYXNzdXJlZHdvcmtsb2Fkcy92MWJldGExL2Fzc3VyZWR3b3JrbG9h
ZHNfc2VydmljZS5wcm90bxIlZ29vZ2xlLmNsb3VkLmFzc3VyZWR3b3JrbG9hZHMudjFiZXRh
MRocZ29vZ2xlL2FwaS9hbm5vdGF0aW9ucy5wcm90bxoXZ29vZ2xlL2FwaS9jbGllbnQucHJv
dG8aPGdvb2dsZS9jbG91ZC9hc3N1cmVkd29ya2xvYWRzL3YxYmV0YTEvYXNzdXJlZHdvcmts
b2Fkcy5wcm90bxojZ29vZ2xlL2xvbmdydW5uaW5nL29wZXJhdGlvbnMucHJvdG8aG2dvb2ds
ZS9wcm90b2J1Zi9lbXB0eS5wcm90bzKQCwoXQXNzdXJlZFdvcmtsb2Fkc1NlcnZpY2US+QEK
DkNyZWF0ZVdvcmtsb2FkEjwuZ29vZ2xlLmNsb3VkLmFzc3VyZWR3b3JrbG9hZHMudjFiZXRh
MS5DcmVhdGVXb3JrbG9hZFJlcXVlc3QaHS5nb29nbGUubG9uZ3J1bm5pbmcuT3BlcmF0aW9u
IokBgtPkkwJDIjcvdjFiZXRhMS97cGFyZW50PW9yZ2FuaXphdGlvbnMvKi9sb2NhdGlvbnMv
Kn0vd29ya2xvYWRzOgh3b3JrbG9hZNpBD3BhcmVudCx3b3JrbG9hZMpBKwoIV29ya2xvYWQS
H0NyZWF0ZVdvcmtsb2FkT3BlcmF0aW9uTWV0YWRhdGESmAEKDlVwZGF0ZVdvcmtsb2FkEjwu
Z29vZ2xlLmNsb3VkLmFzc3VyZWR3b3JrbG9hZHMudjFiZXRhMS5VcGRhdGVXb3JrbG9hZFJl
cXVlc3QaLy5nb29nbGUuY2xvdWQuYXNzdXJlZHdvcmtsb2Fkcy52MWJldGExLldvcmtsb2Fk
IhfaQRR3b3JrbG9hZCx1cGRhdGVfbWFzaxKIAgoYUmVzdHJpY3RBbGxvd2VkUmVzb3VyY2Vz
EkYuZ29vZ2xlLmNsb3VkLmFzc3VyZWR3b3JrbG9hZHMudjFiZXRhMS5SZXN0cmljdEFsbG93
ZWRSZXNvdXJjZXNSZXF1ZXN0GkcuZ29vZ2xlLmNsb3VkLmFzc3VyZWR3b3JrbG9hZHMudjFi
ZXRhMS5SZXN0cmljdEFsbG93ZWRSZXNvdXJjZXNSZXNwb25zZSJbgtPkkwJVIlAvdjFiZXRh
MS97bmFtZT1vcmdhbml6YXRpb25zLyovbG9jYXRpb25zLyovd29ya2xvYWRzLyp9OnJlc3Ry
aWN0QWxsb3dlZFJlc291cmNlczoBKhKuAQoORGVsZXRlV29ya2xvYWQSPC5nb29nbGUuY2xv
dWQuYXNzdXJlZHdvcmtsb2Fkcy52MWJldGExLkRlbGV0ZVdvcmtsb2FkUmVxdWVzdBoWLmdv
b2dsZS5wcm90b2J1Zi5FbXB0eSJGgtPkkwI5KjcvdjFiZXRhMS97bmFtZT1vcmdhbml6YXRp
b25zLyovbG9jYXRpb25zLyovd29ya2xvYWRzLyp92kEEbmFtZRKCAQoLR2V0V29ya2xvYWQS
OS5nb29nbGUuY2xvdWQuYXNzdXJlZHdvcmtsb2Fkcy52MWJldGExLkdldFdvcmtsb2FkUmVx
dWVzdBovLmdvb2dsZS5jbG91ZC5hc3N1cmVkd29ya2xvYWRzLnYxYmV0YTEuV29ya2xvYWQi
B9pBBG5hbWUSrwEKE0FuYWx5emVXb3JrbG9hZE1vdmUSQS5nb29nbGUuY2xvdWQuYXNzdXJl
ZHdvcmtsb2Fkcy52MWJldGExLkFuYWx5emVXb3JrbG9hZE1vdmVSZXF1ZXN0GkIuZ29vZ2xl
LmNsb3VkLmFzc3VyZWR3b3JrbG9hZHMudjFiZXRhMS5BbmFseXplV29ya2xvYWRNb3ZlUmVz
cG9uc2UiEdpBDnByb2plY3QsdGFyZ2V0EpUBCg1MaXN0V29ya2xvYWRzEjsuZ29vZ2xlLmNs
b3VkLmFzc3VyZWR3b3JrbG9hZHMudjFiZXRhMS5MaXN0V29ya2xvYWRzUmVxdWVzdBo8Lmdv
b2dsZS5jbG91ZC5hc3N1cmVkd29ya2xvYWRzLnYxYmV0YTEuTGlzdFdvcmtsb2Fkc1Jlc3Bv
bnNlIgnaQQZwYXJlbnQaU8pBH2Fzc3VyZWR3b3JrbG9hZHMuZ29vZ2xlYXBpcy5jb23SQS5o
dHRwczovL3d3dy5nb29nbGVhcGlzLmNvbS9hdXRoL2Nsb3VkLXBsYXRmb3JtQp0CCiljb20u
Z29vZ2xlLmNsb3VkLmFzc3VyZWR3b3JrbG9hZHMudjFiZXRhMUIcQXNzdXJlZHdvcmtsb2Fk
c1NlcnZpY2VQcm90b1ABWlVjbG91ZC5nb29nbGUuY29tL2dvL2Fzc3VyZWR3b3JrbG9hZHMv
YXBpdjFiZXRhMS9hc3N1cmVkd29ya2xvYWRzcGI7YXNzdXJlZHdvcmtsb2Fkc3BiqgIlR29v
Z2xlLkNsb3VkLkFzc3VyZWRXb3JrbG9hZHMuVjFCZXRhMcoCJUdvb2dsZVxDbG91ZFxBc3N1
cmVkV29ya2xvYWRzXFYxYmV0YTHqAihHb29nbGU6OkNsb3VkOjpBc3N1cmVkV29ya2xvYWRz
OjpWMWJldGExStMVCgYSBA4AYwEKvAQKAQwSAw4AEjKxBCBDb3B5cmlnaHQgMjAyNSBHb29n
bGUgTExDCgogTGljZW5zZWQgdW5kZXIgdGhlIEFwYWNoZSBMaWNlbnNlLCBWZXJzaW9uIDIu
MCAodGhlICJMaWNlbnNlIik7CiB5b3UgbWF5IG5vdCB1c2UgdGhpcyBmaWxlIGV4Y2VwdCBp
biBjb21wbGlhbmNlIHdpdGggdGhlIExpY2Vuc2UuCiBZb3UgbWF5IG9idGFpbiBhIGNvcHkg
b2YgdGhlIExpY2Vuc2UgYXQKCiAgICAgaHR0cDovL3d3dy5hcGFjaGUub3JnL2xpY2Vuc2Vz
L0xJQ0VOU0UtMi4wCgogVW5sZXNzIHJlcXVpcmVkIGJ5IGFwcGxpY2FibGUgbGF3IG9yIGFn
cmVlZCB0byBpbiB3cml0aW5nLCBzb2Z0d2FyZQogZGlzdHJpYnV0ZWQgdW5kZXIgdGhlIExp
Y2Vuc2UgaXMgZGlzdHJpYnV0ZWQgb24gYW4gIkFTIElTIiBCQVNJUywKIFdJVEhPVVQgV0FS
UkFOVElFUyBPUiBDT05ESVRJT05TIE9GIEFOWSBLSU5ELCBlaXRoZXIgZXhwcmVzcyBvciBp
bXBsaWVkLgogU2VlIHRoZSBMaWNlbnNlIGZvciB0aGUgc3BlY2lmaWMgbGFuZ3VhZ2UgZ292
ZXJuaW5nIHBlcm1pc3Npb25zIGFuZAogbGltaXRhdGlvbnMgdW5kZXIgdGhlIExpY2Vuc2Uu
CgoICgECEgMQAC4KCQoCAwASAxIAJgoJCgIDARIDEwAhCgkKAgMCEgMUAEYKCQoCAwMSAxUA
LQoJCgIDBBIDFgAlCggKAQgSAxgAQgoJCgIIJRIDGABCCggKAQgSAxkAbAoJCgIICxIDGQBs
CggKAQgSAxoAIgoJCgIIChIDGgAiCggKAQgSAxsAPQoJCgIICBIDGwA9CggKAQgSAxwAQgoJ
CgIIARIDHABCCggKAQgSAx0AQgoJCgIIKRIDHQBCCggKAQgSAx4AQQoJCgIILRIDHgBBCjEK
AgYAEgQhAGMBGiUgU2VydmljZSB0byBtYW5hZ2UgQXNzdXJlZFdvcmtsb2Fkcy4KCgoKAwYA
ARIDIQgfCgoKAwYAAxIDIgJHCgwKBQYAA5kIEgMiAkcKCgoDBgADEgMjAlYKDAoFBgADmggS
AyMCVgopCgQGAAIAEgQmAjADGhsgQ3JlYXRlcyBBc3N1cmVkIFdvcmtsb2FkLgoKDAoFBgAC
AAESAyYGFAoMCgUGAAIAAhIDJhUqCgwKBQYAAgADEgMmNVEKDQoFBgACAAQSBCcEKgYKEQoJ
BgACAASwyrwiEgQnBCoGCgwKBQYAAgAEEgMrBD0KDwoIBgACAASbCAASAysEPQoNCgUGAAIA
BBIELAQvBgoPCgcGAAIABJkIEgQsBC8GCuMBCgQGAAIBEgQ2AjgDGtQBIFVwZGF0ZXMgYW4g
ZXhpc3Rpbmcgd29ya2xvYWQuCiBDdXJyZW50bHkgYWxsb3dzIHVwZGF0aW5nIG9mIHdvcmts
b2FkIGRpc3BsYXlfbmFtZSBhbmQgbGFiZWxzLgogRm9yIGZvcmNlIHVwZGF0ZXMgZG9uJ3Qg
c2V0IGV0YWcgZmllbGQgaW4gdGhlIFdvcmtsb2FkLgogT25seSBvbmUgdXBkYXRlIG9wZXJh
dGlvbiBwZXIgd29ya2xvYWQgY2FuIGJlIGluIHByb2dyZXNzLgoKDAoFBgACAQESAzYGFAoM
CgUGAAIBAhIDNhUqCgwKBQYAAgEDEgM2NT0KDAoFBgACAQQSAzcEQgoPCggGAAIBBJsIABID
NwRCCvkCCgQGAAICEgRAAkUDGuoCIFJlc3RyaWN0IHRoZSBsaXN0IG9mIHJlc291cmNlcyBh
bGxvd2VkIGluIHRoZSBXb3JrbG9hZCBlbnZpcm9ubWVudC4KIFRoZSBjdXJyZW50IGxpc3Qg
b2YgYWxsb3dlZCBwcm9kdWN0cyBjYW4gYmUgZm91bmQgYXQKIGh0dHBzOi8vY2xvdWQuZ29v
Z2xlLmNvbS9hc3N1cmVkLXdvcmtsb2Fkcy9kb2NzL3N1cHBvcnRlZC1wcm9kdWN0cwogSW4g
YWRkaXRpb24gdG8gYXNzdXJlZHdvcmtsb2Fkcy53b3JrbG9hZC51cGRhdGUgcGVybWlzc2lv
biwgdGhlIHVzZXIgc2hvdWxkCiBhbHNvIGhhdmUgb3JncG9saWN5LnBvbGljeS5zZXQgcGVy
bWlzc2lvbiBvbiB0aGUgZm9sZGVyIHJlc291cmNlCiB0byB1c2UgdGhpcyBmdW5jdGlvbmFs
aXR5LgoKDAoFBgACAgESA0AGHgoMCgUGAAICAhIDQB8+CgwKBQYAAgIDEgNASWkKDQoFBgAC
AgQSBEEERAYKEQoJBgACAgSwyrwiEgRBBEQGCuwCCgQGAAIDEgRNAlIDGt0CIERlbGV0ZXMg
dGhlIHdvcmtsb2FkLiBNYWtlIHN1cmUgdGhhdCB3b3JrbG9hZCdzIGRpcmVjdCBjaGlsZHJl
biBhcmUgYWxyZWFkeQogaW4gYSBkZWxldGVkIHN0YXRlLCBvdGhlcndpc2UgdGhlIHJlcXVl
c3Qgd2lsbCBmYWlsIHdpdGggYQogRkFJTEVEX1BSRUNPTkRJVElPTiBlcnJvci4KIEluIGFk
ZGl0aW9uIHRvIGFzc3VyZWR3b3JrbG9hZHMud29ya2xvYWQuZGVsZXRlIHBlcm1pc3Npb24s
IHRoZSB1c2VyIHNob3VsZAogYWxzbyBoYXZlIG9yZ3BvbGljeS5wb2xpY3kuc2V0IHBlcm1p
c3Npb24gb24gdGhlIGRlbGV0ZWQgZm9sZGVyIHRvIHJlbW92ZQogQXNzdXJlZCBXb3JrbG9h
ZHMgT3JnUG9saWNpZXMuCgoMCgUGAAIDARIDTQYUCgwKBQYAAgMCEgNNFSoKDAoFBgACAwMS
A001SgoNCgUGAAIDBBIETgRQBgoRCgkGAAIDBLDKvCISBE4EUAYKDAoFBgACAwQSA1EEMgoP
CggGAAIDBJsIABIDUQQyCkAKBAYAAgQSBFUCVwMaMiBHZXRzIEFzc3VyZWQgV29ya2xvYWQg
YXNzb2NpYXRlZCB3aXRoIGEgQ1JNIE5vZGUKCgwKBQYAAgQBEgNVBhEKDAoFBgACBAISA1US
JAoMCgUGAAIEAxIDVS83CgwKBQYAAgQEEgNWBDIKDwoIBgACBASbCAASA1YEMgpkCgQGAAIF
EgRbAl0DGlYgQW5hbHl6ZSBpZiB0aGUgc291cmNlIEFzc3VyZWQgV29ya2xvYWRzIGNhbiBi
ZSBtb3ZlZCB0byB0aGUgdGFyZ2V0IEFzc3VyZWQKIFdvcmtsb2FkCgoMCgUGAAIFARIDWwYZ
CgwKBQYAAgUCEgNbGjQKDAoFBgACBQMSA1s/WgoMCgUGAAIFBBIDXAQ8Cg8KCAYAAgUEmwgA
EgNcBDwKOQoEBgACBhIEYAJiAxorIExpc3RzIEFzc3VyZWQgV29ya2xvYWRzIHVuZGVyIGEg
Q1JNIE5vZGUuCgoMCgUGAAIGARIDYAYTCgwKBQYAAgYCEgNgFCgKDAoFBgACBgMSA2AzSAoM
CgUGAAIGBBIDYQQ0Cg8KCAYAAgYEmwgAEgNhBDRiBnByb3RvMw==
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Service Client: Google::Cloud::Assuredworkloads::V1beta1::AssuredworkloadsService::AssuredWorkloadsServiceClient ===
package Google::Cloud::Assuredworkloads::V1beta1::AssuredworkloadsService::AssuredWorkloadsServiceClient;

=pod

=head2 Service Client: Google::Cloud::Assuredworkloads::V1beta1::AssuredworkloadsService::AssuredWorkloadsServiceClient

Client stub representing the remote C<AssuredWorkloadsService> gRPC service. Delegates call dispatching to L<Google::gRPC::Client>.

=head3 target

The endpoint target address. Defaults to C<assuredworkloads.googleapis.com:443>.

=head3 credentials

The authentication credentials provider. Defaults to application default credentials via L<Google::Auth>.

=cut

use Moo;
use Google::Auth;
use Google::gRPC::Client;

has credentials => ( is => 'ro', default => sub { Google::Auth->default() } );
has target      => ( is => 'ro', default => 'assuredworkloads.googleapis.com:443' );

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

sub create_workload {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Assuredworkloads::V1beta1::Assuredworkloads::CreateWorkloadRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.assuredworkloads.v1beta1.AssuredWorkloadsService',
        method         => 'CreateWorkload',
        request        => $req,
        response_class => 'Google::Longrunning::Operations::Operation',
    });
}

sub update_workload {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Assuredworkloads::V1beta1::Assuredworkloads::UpdateWorkloadRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.assuredworkloads.v1beta1.AssuredWorkloadsService',
        method         => 'UpdateWorkload',
        request        => $req,
        response_class => 'Google::Cloud::Assuredworkloads::V1beta1::Assuredworkloads::Workload',
    });
}

sub restrict_allowed_resources {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Assuredworkloads::V1beta1::Assuredworkloads::RestrictAllowedResourcesRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.assuredworkloads.v1beta1.AssuredWorkloadsService',
        method         => 'RestrictAllowedResources',
        request        => $req,
        response_class => 'Google::Cloud::Assuredworkloads::V1beta1::Assuredworkloads::RestrictAllowedResourcesResponse',
    });
}

sub delete_workload {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Assuredworkloads::V1beta1::Assuredworkloads::DeleteWorkloadRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.assuredworkloads.v1beta1.AssuredWorkloadsService',
        method         => 'DeleteWorkload',
        request        => $req,
        response_class => 'Google::Protobuf::Empty::Empty',
    });
}

sub get_workload {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Assuredworkloads::V1beta1::Assuredworkloads::GetWorkloadRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.assuredworkloads.v1beta1.AssuredWorkloadsService',
        method         => 'GetWorkload',
        request        => $req,
        response_class => 'Google::Cloud::Assuredworkloads::V1beta1::Assuredworkloads::Workload',
    });
}

sub analyze_workload_move {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Assuredworkloads::V1beta1::Assuredworkloads::AnalyzeWorkloadMoveRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.assuredworkloads.v1beta1.AssuredWorkloadsService',
        method         => 'AnalyzeWorkloadMove',
        request        => $req,
        response_class => 'Google::Cloud::Assuredworkloads::V1beta1::Assuredworkloads::AnalyzeWorkloadMoveResponse',
    });
}

sub list_workloads {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Assuredworkloads::V1beta1::Assuredworkloads::ListWorkloadsRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.assuredworkloads.v1beta1.AssuredWorkloadsService',
        method         => 'ListWorkloads',
        request        => $req,
        response_class => 'Google::Cloud::Assuredworkloads::V1beta1::Assuredworkloads::ListWorkloadsResponse',
    });
}

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Assuredworkloads::V1beta1::AssuredworkloadsService - Compiled Protocol Buffers messages for google/cloud/assuredworkloads/v1beta1/assuredworkloads_service.proto

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/assuredworkloads/v1beta1/assuredworkloads_service.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Assuredworkloads::V1beta1::AssuredworkloadsService::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
