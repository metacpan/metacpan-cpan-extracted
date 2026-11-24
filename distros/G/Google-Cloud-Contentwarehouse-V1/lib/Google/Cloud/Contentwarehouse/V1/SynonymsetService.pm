package Google::Cloud::Contentwarehouse::V1::SynonymsetService;

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
    eval { require Google::Cloud::Contentwarehouse::V1::Synonymset };
    eval { require Google::Cloud::Contentwarehouse::V1::SynonymsetServiceRequest };
    eval { require Google::Protobuf::Empty };
    my $descriptor_b64 = <<'EOF';
Cjlnb29nbGUvY2xvdWQvY29udGVudHdhcmVob3VzZS92MS9zeW5vbnltc2V0X3NlcnZpY2Uu
cHJvdG8SIGdvb2dsZS5jbG91ZC5jb250ZW50d2FyZWhvdXNlLnYxGhxnb29nbGUvYXBpL2Fu
bm90YXRpb25zLnByb3RvGhdnb29nbGUvYXBpL2NsaWVudC5wcm90bxoxZ29vZ2xlL2Nsb3Vk
L2NvbnRlbnR3YXJlaG91c2UvdjEvc3lub255bXNldC5wcm90bxpBZ29vZ2xlL2Nsb3VkL2Nv
bnRlbnR3YXJlaG91c2UvdjEvc3lub255bXNldF9zZXJ2aWNlX3JlcXVlc3QucHJvdG8aG2dv
b2dsZS9wcm90b2J1Zi9lbXB0eS5wcm90bzLDCAoRU3lub255bVNldFNlcnZpY2US1gEKEENy
ZWF0ZVN5bm9ueW1TZXQSOS5nb29nbGUuY2xvdWQuY29udGVudHdhcmVob3VzZS52MS5DcmVh
dGVTeW5vbnltU2V0UmVxdWVzdBosLmdvb2dsZS5jbG91ZC5jb250ZW50d2FyZWhvdXNlLnYx
LlN5bm9ueW1TZXQiWYLT5JMCPiIvL3YxL3twYXJlbnQ9cHJvamVjdHMvKi9sb2NhdGlvbnMv
Kn0vc3lub255bVNldHM6C3N5bm9ueW1fc2V02kEScGFyZW50LHN5bm9ueW1fc2V0ErUBCg1H
ZXRTeW5vbnltU2V0EjYuZ29vZ2xlLmNsb3VkLmNvbnRlbnR3YXJlaG91c2UudjEuR2V0U3lu
b255bVNldFJlcXVlc3QaLC5nb29nbGUuY2xvdWQuY29udGVudHdhcmVob3VzZS52MS5TeW5v
bnltU2V0Ij6C0+STAjESLy92MS97bmFtZT1wcm9qZWN0cy8qL2xvY2F0aW9ucy8qL3N5bm9u
eW1TZXRzLyp92kEEbmFtZRLUAQoQVXBkYXRlU3lub255bVNldBI5Lmdvb2dsZS5jbG91ZC5j
b250ZW50d2FyZWhvdXNlLnYxLlVwZGF0ZVN5bm9ueW1TZXRSZXF1ZXN0GiwuZ29vZ2xlLmNs
b3VkLmNvbnRlbnR3YXJlaG91c2UudjEuU3lub255bVNldCJXgtPkkwI+Mi8vdjEve25hbWU9
cHJvamVjdHMvKi9sb2NhdGlvbnMvKi9zeW5vbnltU2V0cy8qfToLc3lub255bV9zZXTaQRBu
YW1lLHN5bm9ueW1fc2V0EqUBChBEZWxldGVTeW5vbnltU2V0EjkuZ29vZ2xlLmNsb3VkLmNv
bnRlbnR3YXJlaG91c2UudjEuRGVsZXRlU3lub255bVNldFJlcXVlc3QaFi5nb29nbGUucHJv
dG9idWYuRW1wdHkiPoLT5JMCMSovL3YxL3tuYW1lPXByb2plY3RzLyovbG9jYXRpb25zLyov
c3lub255bVNldHMvKn3aQQRuYW1lEsgBCg9MaXN0U3lub255bVNldHMSOC5nb29nbGUuY2xv
dWQuY29udGVudHdhcmVob3VzZS52MS5MaXN0U3lub255bVNldHNSZXF1ZXN0GjkuZ29vZ2xl
LmNsb3VkLmNvbnRlbnR3YXJlaG91c2UudjEuTGlzdFN5bm9ueW1TZXRzUmVzcG9uc2UiQILT
5JMCMRIvL3YxL3twYXJlbnQ9cHJvamVjdHMvKi9sb2NhdGlvbnMvKn0vc3lub255bVNldHPa
QQZwYXJlbnQaU8pBH2NvbnRlbnR3YXJlaG91c2UuZ29vZ2xlYXBpcy5jb23SQS5odHRwczov
L3d3dy5nb29nbGVhcGlzLmNvbS9hdXRoL2Nsb3VkLXBsYXRmb3JtQv4BCiRjb20uZ29vZ2xl
LmNsb3VkLmNvbnRlbnR3YXJlaG91c2UudjFCFlN5bm9ueW1TZXRTZXJ2aWNlUHJvdG9QAVpQ
Y2xvdWQuZ29vZ2xlLmNvbS9nby9jb250ZW50d2FyZWhvdXNlL2FwaXYxL2NvbnRlbnR3YXJl
aG91c2VwYjtjb250ZW50d2FyZWhvdXNlcGKqAiBHb29nbGUuQ2xvdWQuQ29udGVudFdhcmVo
b3VzZS5WMcoCIEdvb2dsZVxDbG91ZFxDb250ZW50V2FyZWhvdXNlXFYx6gIjR29vZ2xlOjpD
bG91ZDo6Q29udGVudFdhcmVob3VzZTo6VjFKwhAKBhIEDgBYAQq8BAoBDBIDDgASMrEEIENv
cHlyaWdodCAyMDI1IEdvb2dsZSBMTEMKCiBMaWNlbnNlZCB1bmRlciB0aGUgQXBhY2hlIExp
Y2Vuc2UsIFZlcnNpb24gMi4wICh0aGUgIkxpY2Vuc2UiKTsKIHlvdSBtYXkgbm90IHVzZSB0
aGlzIGZpbGUgZXhjZXB0IGluIGNvbXBsaWFuY2Ugd2l0aCB0aGUgTGljZW5zZS4KIFlvdSBt
YXkgb2J0YWluIGEgY29weSBvZiB0aGUgTGljZW5zZSBhdAoKICAgICBodHRwOi8vd3d3LmFw
YWNoZS5vcmcvbGljZW5zZXMvTElDRU5TRS0yLjAKCiBVbmxlc3MgcmVxdWlyZWQgYnkgYXBw
bGljYWJsZSBsYXcgb3IgYWdyZWVkIHRvIGluIHdyaXRpbmcsIHNvZnR3YXJlCiBkaXN0cmli
dXRlZCB1bmRlciB0aGUgTGljZW5zZSBpcyBkaXN0cmlidXRlZCBvbiBhbiAiQVMgSVMiIEJB
U0lTLAogV0lUSE9VVCBXQVJSQU5USUVTIE9SIENPTkRJVElPTlMgT0YgQU5ZIEtJTkQsIGVp
dGhlciBleHByZXNzIG9yIGltcGxpZWQuCiBTZWUgdGhlIExpY2Vuc2UgZm9yIHRoZSBzcGVj
aWZpYyBsYW5ndWFnZSBnb3Zlcm5pbmcgcGVybWlzc2lvbnMgYW5kCiBsaW1pdGF0aW9ucyB1
bmRlciB0aGUgTGljZW5zZS4KCggKAQISAxAAKQoJCgIDABIDEgAmCgkKAgMBEgMTACEKCQoC
AwISAxQAOwoJCgIDAxIDFQBLCgkKAgMEEgMWACUKCAoBCBIDGAA9CgkKAgglEgMYAD0KCAoB
CBIDGQBnCgkKAggLEgMZAGcKCAoBCBIDGgAiCgkKAggKEgMaACIKCAoBCBIDGwA3CgkKAggI
EgMbADcKCAoBCBIDHAA9CgkKAggBEgMcAD0KCAoBCBIDHQA9CgkKAggpEgMdAD0KCAoBCBID
HgA8CgkKAggtEgMeADwKSgoCBgASBCEAWAEaPiBBIFNlcnZpY2UgdGhhdCBtYW5hZ2UvY3Vz
dG9tIGN1c3RvbWVyIHNwZWNpZmllZCBTeW5vbnltU2V0cy4KCgoKAwYAARIDIQgZCgoKAwYA
AxIDIgJHCgwKBQYAA5kIEgMiAkcKCwoDBgADEgQjAiQ3Cg0KBQYAA5oIEgQjAiQ3CpABCgQG
AAIAEgQpAi8DGoEBIENyZWF0ZXMgYSBTeW5vbnltU2V0IGZvciBhIHNpbmdsZSBjb250ZXh0
LgogVGhyb3dzIGFuIEFMUkVBRFlfRVhJU1RTIGV4Y2VwdGlvbiBpZiBhIHN5bm9ueW1zZXQg
YWxyZWFkeSBleGlzdHMKIGZvciB0aGUgY29udGV4dC4KCgwKBQYAAgABEgMpBhYKDAoFBgAC
AAISAykXLgoMCgUGAAIAAxIDKTlDCg0KBQYAAgAEEgQqBC0GChEKCQYAAgAEsMq8IhIEKgQt
BgoMCgUGAAIABBIDLgRACg8KCAYAAgAEmwgAEgMuBEAKewoEBgACARIENAI5AxptIEdldHMg
YSBTeW5vbnltU2V0IGZvciBhIHBhcnRpY3VsYXIgY29udGV4dC4KIFRocm93cyBhIE5PVF9G
T1VORCBleGNlcHRpb24gaWYgdGhlIFN5bm9ueW1zZXQKIGRvZXMgbm90IGV4aXN0CgoMCgUG
AAIBARIDNAYTCgwKBQYAAgECEgM0FCgKDAoFBgACAQMSAzQzPQoNCgUGAAIBBBIENQQ3BgoR
CgkGAAIBBLDKvCISBDUENwYKDAoFBgACAQQSAzgEMgoPCggGAAIBBJsIABIDOAQyCp4BCgQG
AAICEgQ+AkQDGo8BIFJlbW92ZSB0aGUgZXhpc3RpbmcgU3lub255bVNldCBmb3IgdGhlIGNv
bnRleHQgYW5kIHJlcGxhY2VzIGl0CiB3aXRoIGEgbmV3IG9uZS4KIFRocm93cyBhIE5PVF9G
T1VORCBleGNlcHRpb24gaWYgdGhlIFN5bm9ueW1TZXQgaXMgbm90IGZvdW5kLgoKDAoFBgAC
AgESAz4GFgoMCgUGAAICAhIDPhcuCgwKBQYAAgIDEgM+OUMKDQoFBgACAgQSBD8EQgYKEQoJ
BgACAgSwyrwiEgQ/BEIGCgwKBQYAAgIEEgNDBD4KDwoIBgACAgSbCAASA0MEPgp3CgQGAAID
EgRIAk4DGmkgRGVsZXRlcyBhIFN5bm9ueW1TZXQgZm9yIGEgZ2l2ZW4gY29udGV4dC4KIFRo
cm93cyBhIE5PVF9GT1VORCBleGNlcHRpb24gaWYgdGhlIFN5bm9ueW1TZXQgaXMgbm90IGZv
dW5kLgoKDAoFBgACAwESA0gGFgoMCgUGAAIDAhIDSBcuCgwKBQYAAgMDEgNJDyQKDQoFBgAC
AwQSBEoETAYKEQoJBgACAwSwyrwiEgRKBEwGCgwKBQYAAgMEEgNNBDIKDwoIBgACAwSbCAAS
A00EMgpWCgQGAAIEEgRRAlcDGkggUmV0dXJucyBhbGwgU3lub255bVNldHMgKGZvciBhbGwg
Y29udGV4dHMpIGZvciB0aGUgc3BlY2lmaWVkIGxvY2F0aW9uLgoKDAoFBgACBAESA1EGFQoM
CgUGAAIEAhIDURYsCgwKBQYAAgQDEgNSDyYKDQoFBgACBAQSBFMEVQYKEQoJBgACBASwyrwi
EgRTBFUGCgwKBQYAAgQEEgNWBDQKDwoIBgACBASbCAASA1YENGIGcHJvdG8z
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Service Client: Google::Cloud::Contentwarehouse::V1::SynonymsetService::SynonymSetServiceClient ===
package Google::Cloud::Contentwarehouse::V1::SynonymsetService::SynonymSetServiceClient;

=pod

=head2 Service Client: Google::Cloud::Contentwarehouse::V1::SynonymsetService::SynonymSetServiceClient

Client stub representing the remote C<SynonymSetService> gRPC service. Delegates call dispatching to L<Google::gRPC::Client>.

=head3 target

The endpoint target address. Defaults to C<contentwarehouse.googleapis.com:443>.

=head3 credentials

The authentication credentials provider. Defaults to application default credentials via L<Google::Auth>.

=cut

use Moo;
use Google::Auth;
use Google::gRPC::Client;

has credentials => ( is => 'ro', default => sub { Google::Auth->default() } );
has target      => ( is => 'ro', default => 'contentwarehouse.googleapis.com:443' );

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

sub create_synonym_set {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Contentwarehouse::V1::SynonymsetServiceRequest::CreateSynonymSetRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.contentwarehouse.v1.SynonymSetService',
        method         => 'CreateSynonymSet',
        request        => $req,
        response_class => 'Google::Cloud::Contentwarehouse::V1::Synonymset::SynonymSet',
    });
}

sub get_synonym_set {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Contentwarehouse::V1::SynonymsetServiceRequest::GetSynonymSetRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.contentwarehouse.v1.SynonymSetService',
        method         => 'GetSynonymSet',
        request        => $req,
        response_class => 'Google::Cloud::Contentwarehouse::V1::Synonymset::SynonymSet',
    });
}

sub update_synonym_set {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Contentwarehouse::V1::SynonymsetServiceRequest::UpdateSynonymSetRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.contentwarehouse.v1.SynonymSetService',
        method         => 'UpdateSynonymSet',
        request        => $req,
        response_class => 'Google::Cloud::Contentwarehouse::V1::Synonymset::SynonymSet',
    });
}

sub delete_synonym_set {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Contentwarehouse::V1::SynonymsetServiceRequest::DeleteSynonymSetRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.contentwarehouse.v1.SynonymSetService',
        method         => 'DeleteSynonymSet',
        request        => $req,
        response_class => 'Google::Protobuf::Empty::Empty',
    });
}

sub list_synonym_sets {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Contentwarehouse::V1::SynonymsetServiceRequest::ListSynonymSetsRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.contentwarehouse.v1.SynonymSetService',
        method         => 'ListSynonymSets',
        request        => $req,
        response_class => 'Google::Cloud::Contentwarehouse::V1::SynonymsetServiceRequest::ListSynonymSetsResponse',
    });
}

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Contentwarehouse::V1::SynonymsetService - Compiled Protocol Buffers messages for google/cloud/contentwarehouse/v1/synonymset_service.proto

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/contentwarehouse/v1/synonymset_service.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Contentwarehouse::V1::SynonymsetService::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
