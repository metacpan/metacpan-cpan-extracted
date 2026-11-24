package Google::Cloud::Discoveryengine::V1beta::SessionService;

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
    eval { require Google::Cloud::Discoveryengine::V1beta::ConversationalSearchService };
    eval { require Google::Cloud::Discoveryengine::V1beta::Session };
    eval { require Google::Protobuf::Empty };
    my $descriptor_b64 = <<'EOF';
Cjlnb29nbGUvY2xvdWQvZGlzY292ZXJ5ZW5naW5lL3YxYmV0YS9zZXNzaW9uX3NlcnZpY2Uu
cHJvdG8SI2dvb2dsZS5jbG91ZC5kaXNjb3ZlcnllbmdpbmUudjFiZXRhGhxnb29nbGUvYXBp
L2Fubm90YXRpb25zLnByb3RvGhdnb29nbGUvYXBpL2NsaWVudC5wcm90bxofZ29vZ2xlL2Fw
aS9maWVsZF9iZWhhdmlvci5wcm90bxoZZ29vZ2xlL2FwaS9yZXNvdXJjZS5wcm90bxpHZ29v
Z2xlL2Nsb3VkL2Rpc2NvdmVyeWVuZ2luZS92MWJldGEvY29udmVyc2F0aW9uYWxfc2VhcmNo
X3NlcnZpY2UucHJvdG8aMWdvb2dsZS9jbG91ZC9kaXNjb3ZlcnllbmdpbmUvdjFiZXRhL3Nl
c3Npb24ucHJvdG8aG2dvb2dsZS9wcm90b2J1Zi9lbXB0eS5wcm90bzL5EAoOU2Vzc2lvblNl
cnZpY2USiAMKDUNyZWF0ZVNlc3Npb24SOS5nb29nbGUuY2xvdWQuZGlzY292ZXJ5ZW5naW5l
LnYxYmV0YS5DcmVhdGVTZXNzaW9uUmVxdWVzdBosLmdvb2dsZS5jbG91ZC5kaXNjb3Zlcnll
bmdpbmUudjFiZXRhLlNlc3Npb24ijQKC0+STAvUBIj0vdjFiZXRhL3twYXJlbnQ9cHJvamVj
dHMvKi9sb2NhdGlvbnMvKi9kYXRhU3RvcmVzLyp9L3Nlc3Npb25zOgdzZXNzaW9uWlYiSy92
MWJldGEve3BhcmVudD1wcm9qZWN0cy8qL2xvY2F0aW9ucy8qL2NvbGxlY3Rpb25zLyovZGF0
YVN0b3Jlcy8qfS9zZXNzaW9uczoHc2Vzc2lvblpTIkgvdjFiZXRhL3twYXJlbnQ9cHJvamVj
dHMvKi9sb2NhdGlvbnMvKi9jb2xsZWN0aW9ucy8qL2VuZ2luZXMvKn0vc2Vzc2lvbnM6B3Nl
c3Npb27aQQ5wYXJlbnQsc2Vzc2lvbhLNAgoNRGVsZXRlU2Vzc2lvbhI5Lmdvb2dsZS5jbG91
ZC5kaXNjb3ZlcnllbmdpbmUudjFiZXRhLkRlbGV0ZVNlc3Npb25SZXF1ZXN0GhYuZ29vZ2xl
LnByb3RvYnVmLkVtcHR5IugBgtPkkwLaASo9L3YxYmV0YS97bmFtZT1wcm9qZWN0cy8qL2xv
Y2F0aW9ucy8qL2RhdGFTdG9yZXMvKi9zZXNzaW9ucy8qfVpNKksvdjFiZXRhL3tuYW1lPXBy
b2plY3RzLyovbG9jYXRpb25zLyovY29sbGVjdGlvbnMvKi9kYXRhU3RvcmVzLyovc2Vzc2lv
bnMvKn1aSipIL3YxYmV0YS97bmFtZT1wcm9qZWN0cy8qL2xvY2F0aW9ucy8qL2NvbGxlY3Rp
b25zLyovZW5naW5lcy8qL3Nlc3Npb25zLyp92kEEbmFtZRKlAwoNVXBkYXRlU2Vzc2lvbhI5
Lmdvb2dsZS5jbG91ZC5kaXNjb3ZlcnllbmdpbmUudjFiZXRhLlVwZGF0ZVNlc3Npb25SZXF1
ZXN0GiwuZ29vZ2xlLmNsb3VkLmRpc2NvdmVyeWVuZ2luZS52MWJldGEuU2Vzc2lvbiKqAoLT
5JMCjQIyRS92MWJldGEve3Nlc3Npb24ubmFtZT1wcm9qZWN0cy8qL2xvY2F0aW9ucy8qL2Rh
dGFTdG9yZXMvKi9zZXNzaW9ucy8qfToHc2Vzc2lvblpeMlMvdjFiZXRhL3tzZXNzaW9uLm5h
bWU9cHJvamVjdHMvKi9sb2NhdGlvbnMvKi9jb2xsZWN0aW9ucy8qL2RhdGFTdG9yZXMvKi9z
ZXNzaW9ucy8qfToHc2Vzc2lvblpbMlAvdjFiZXRhL3tzZXNzaW9uLm5hbWU9cHJvamVjdHMv
Ki9sb2NhdGlvbnMvKi9jb2xsZWN0aW9ucy8qL2VuZ2luZXMvKi9zZXNzaW9ucy8qfToHc2Vz
c2lvbtpBE3Nlc3Npb24sdXBkYXRlX21hc2sS3QIKCkdldFNlc3Npb24SNi5nb29nbGUuY2xv
dWQuZGlzY292ZXJ5ZW5naW5lLnYxYmV0YS5HZXRTZXNzaW9uUmVxdWVzdBosLmdvb2dsZS5j
bG91ZC5kaXNjb3ZlcnllbmdpbmUudjFiZXRhLlNlc3Npb24i6AGC0+STAtoBEj0vdjFiZXRh
L3tuYW1lPXByb2plY3RzLyovbG9jYXRpb25zLyovZGF0YVN0b3Jlcy8qL3Nlc3Npb25zLyp9
Wk0SSy92MWJldGEve25hbWU9cHJvamVjdHMvKi9sb2NhdGlvbnMvKi9jb2xsZWN0aW9ucy8q
L2RhdGFTdG9yZXMvKi9zZXNzaW9ucy8qfVpKEkgvdjFiZXRhL3tuYW1lPXByb2plY3RzLyov
bG9jYXRpb25zLyovY29sbGVjdGlvbnMvKi9lbmdpbmVzLyovc2Vzc2lvbnMvKn3aQQRuYW1l
EvACCgxMaXN0U2Vzc2lvbnMSOC5nb29nbGUuY2xvdWQuZGlzY292ZXJ5ZW5naW5lLnYxYmV0
YS5MaXN0U2Vzc2lvbnNSZXF1ZXN0GjkuZ29vZ2xlLmNsb3VkLmRpc2NvdmVyeWVuZ2luZS52
MWJldGEuTGlzdFNlc3Npb25zUmVzcG9uc2Ui6gGC0+STAtoBEj0vdjFiZXRhL3twYXJlbnQ9
cHJvamVjdHMvKi9sb2NhdGlvbnMvKi9kYXRhU3RvcmVzLyp9L3Nlc3Npb25zWk0SSy92MWJl
dGEve3BhcmVudD1wcm9qZWN0cy8qL2xvY2F0aW9ucy8qL2NvbGxlY3Rpb25zLyovZGF0YVN0
b3Jlcy8qfS9zZXNzaW9uc1pKEkgvdjFiZXRhL3twYXJlbnQ9cHJvamVjdHMvKi9sb2NhdGlv
bnMvKi9jb2xsZWN0aW9ucy8qL2VuZ2luZXMvKn0vc2Vzc2lvbnPaQQZwYXJlbnQakALKQR5k
aXNjb3ZlcnllbmdpbmUuZ29vZ2xlYXBpcy5jb23SQesBaHR0cHM6Ly93d3cuZ29vZ2xlYXBp
cy5jb20vYXV0aC9jbG91ZC1wbGF0Zm9ybSxodHRwczovL3d3dy5nb29nbGVhcGlzLmNvbS9h
dXRoL2Rpc2NvdmVyeWVuZ2luZS5hc3Npc3QucmVhZHdyaXRlLGh0dHBzOi8vd3d3Lmdvb2ds
ZWFwaXMuY29tL2F1dGgvZGlzY292ZXJ5ZW5naW5lLnJlYWR3cml0ZSxodHRwczovL3d3dy5n
b29nbGVhcGlzLmNvbS9hdXRoL2Rpc2NvdmVyeWVuZ2luZS5zZXJ2aW5nLnJlYWR3cml0ZUKa
AgonY29tLmdvb2dsZS5jbG91ZC5kaXNjb3ZlcnllbmdpbmUudjFiZXRhQhNTZXNzaW9uU2Vy
dmljZVByb3RvUAFaUWNsb3VkLmdvb2dsZS5jb20vZ28vZGlzY292ZXJ5ZW5naW5lL2FwaXYx
YmV0YS9kaXNjb3ZlcnllbmdpbmVwYjtkaXNjb3ZlcnllbmdpbmVwYqICD0RJU0NPVkVSWUVO
R0lORaoCI0dvb2dsZS5DbG91ZC5EaXNjb3ZlcnlFbmdpbmUuVjFCZXRhygIjR29vZ2xlXENs
b3VkXERpc2NvdmVyeUVuZ2luZVxWMWJldGHqAiZHb29nbGU6OkNsb3VkOjpEaXNjb3ZlcnlF
bmdpbmU6OlYxYmV0YUq/EQoHEgUOAIIBAQq8BAoBDBIDDgASMrEEIENvcHlyaWdodCAyMDI2
IEdvb2dsZSBMTEMKCiBMaWNlbnNlZCB1bmRlciB0aGUgQXBhY2hlIExpY2Vuc2UsIFZlcnNp
b24gMi4wICh0aGUgIkxpY2Vuc2UiKTsKIHlvdSBtYXkgbm90IHVzZSB0aGlzIGZpbGUgZXhj
ZXB0IGluIGNvbXBsaWFuY2Ugd2l0aCB0aGUgTGljZW5zZS4KIFlvdSBtYXkgb2J0YWluIGEg
Y29weSBvZiB0aGUgTGljZW5zZSBhdAoKICAgICBodHRwOi8vd3d3LmFwYWNoZS5vcmcvbGlj
ZW5zZXMvTElDRU5TRS0yLjAKCiBVbmxlc3MgcmVxdWlyZWQgYnkgYXBwbGljYWJsZSBsYXcg
b3IgYWdyZWVkIHRvIGluIHdyaXRpbmcsIHNvZnR3YXJlCiBkaXN0cmlidXRlZCB1bmRlciB0
aGUgTGljZW5zZSBpcyBkaXN0cmlidXRlZCBvbiBhbiAiQVMgSVMiIEJBU0lTLAogV0lUSE9V
VCBXQVJSQU5USUVTIE9SIENPTkRJVElPTlMgT0YgQU5ZIEtJTkQsIGVpdGhlciBleHByZXNz
IG9yIGltcGxpZWQuCiBTZWUgdGhlIExpY2Vuc2UgZm9yIHRoZSBzcGVjaWZpYyBsYW5ndWFn
ZSBnb3Zlcm5pbmcgcGVybWlzc2lvbnMgYW5kCiBsaW1pdGF0aW9ucyB1bmRlciB0aGUgTGlj
ZW5zZS4KCggKAQISAxAALAoJCgIDABIDEgAmCgkKAgMBEgMTACEKCQoCAwISAxQAKQoJCgID
AxIDFQAjCgkKAgMEEgMWAFEKCQoCAwUSAxcAOwoJCgIDBhIDGAAlCggKAQgSAxoAQAoJCgII
JRIDGgBACggKAQgSAxsAaAoJCgIICxIDGwBoCggKAQgSAxwAIgoJCgIIChIDHAAiCggKAQgS
Ax0ANAoJCgIICBIDHQA0CggKAQgSAx4AQAoJCgIIARIDHgBACggKAQgSAx8ALQoJCgIIJBID
HwAtCggKAQgSAyAAQAoJCgIIKRIDIABACggKAQgSAyEAPwoJCgIILRIDIQA/CksKAgYAEgUk
AIIBARo+IFNlcnZpY2UgZm9yIG1hbmFnaW5nIFNlc3Npb25zIGFuZCBTZXNzaW9uLXJlbGF0
ZWQgcmVzb3VyY2VzLgoKCgoDBgABEgMkCBYKCgoDBgADEgMlAkYKDAoFBgADmQgSAyUCRgoL
CgMGAAMSBCYCKkoKDQoFBgADmggSBCYCKkoKowEKBAYAAgASBDACPgMalAEgQ3JlYXRlcyBh
IFNlc3Npb24uCgogSWYgdGhlIFtTZXNzaW9uXVtnb29nbGUuY2xvdWQuZGlzY292ZXJ5ZW5n
aW5lLnYxYmV0YS5TZXNzaW9uXSB0byBjcmVhdGUKIGFscmVhZHkgZXhpc3RzLCBhbiBBTFJF
QURZX0VYSVNUUyBlcnJvciBpcyByZXR1cm5lZC4KCgwKBQYAAgABEgMwBhMKDAoFBgACAAIS
AzAUKAoMCgUGAAIAAxIDMDM6Cg0KBQYAAgAEEgQxBDwGChEKCQYAAgAEsMq8IhIEMQQ8BgoM
CgUGAAIABBIDPQQ8Cg8KCAYAAgAEmwgAEgM9BDwKnQEKBAYAAgESBEQCTwMajgEgRGVsZXRl
cyBhIFNlc3Npb24uCgogSWYgdGhlIFtTZXNzaW9uXVtnb29nbGUuY2xvdWQuZGlzY292ZXJ5
ZW5naW5lLnYxYmV0YS5TZXNzaW9uXSB0byBkZWxldGUKIGRvZXMgbm90IGV4aXN0LCBhIE5P
VF9GT1VORCBlcnJvciBpcyByZXR1cm5lZC4KCgwKBQYAAgEBEgNEBhMKDAoFBgACAQISA0QU
KAoMCgUGAAIBAxIDRDNICg0KBQYAAgEEEgRFBE0GChEKCQYAAgEEsMq8IhIERQRNBgoMCgUG
AAIBBBIDTgQyCg8KCAYAAgEEmwgAEgNOBDIK9AEKBAYAAgISBFYCZAMa5QEgVXBkYXRlcyBh
IFNlc3Npb24uCgogW1Nlc3Npb25dW2dvb2dsZS5jbG91ZC5kaXNjb3ZlcnllbmdpbmUudjFi
ZXRhLlNlc3Npb25dIGFjdGlvbiB0eXBlIGNhbm5vdAogYmUgY2hhbmdlZC4gSWYgdGhlIFtT
ZXNzaW9uXVtnb29nbGUuY2xvdWQuZGlzY292ZXJ5ZW5naW5lLnYxYmV0YS5TZXNzaW9uXQog
dG8gdXBkYXRlIGRvZXMgbm90IGV4aXN0LCBhIE5PVF9GT1VORCBlcnJvciBpcyByZXR1cm5l
ZC4KCgwKBQYAAgIBEgNWBhMKDAoFBgACAgISA1YUKAoMCgUGAAICAxIDVjM6Cg0KBQYAAgIE
EgRXBGIGChEKCQYAAgIEsMq8IhIEVwRiBgoMCgUGAAICBBIDYwRBCg8KCAYAAgIEmwgAEgNj
BEEKHwoEBgACAxIEZwJyAxoRIEdldHMgYSBTZXNzaW9uLgoKDAoFBgACAwESA2cGEAoMCgUG
AAIDAhIDZxEiCgwKBQYAAgMDEgNnLTQKDQoFBgACAwQSBGgEcAYKEQoJBgACAwSwyrwiEgRo
BHAGCgwKBQYAAgMEEgNxBDIKDwoIBgACAwSbCAASA3EEMgpwCgQGAAIEEgV2AoEBAxphIExp
c3RzIGFsbCBTZXNzaW9ucyBieSB0aGVpciBwYXJlbnQKIFtEYXRhU3RvcmVdW2dvb2dsZS5j
bG91ZC5kaXNjb3ZlcnllbmdpbmUudjFiZXRhLkRhdGFTdG9yZV0uCgoMCgUGAAIEARIDdgYS
CgwKBQYAAgQCEgN2EyYKDAoFBgACBAMSA3YxRQoNCgUGAAIEBBIEdwR/BgoRCgkGAAIEBLDK
vCISBHcEfwYKDQoFBgACBAQSBIABBDQKEAoIBgACBASbCAASBIABBDRiBnByb3RvMw==
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Service Client: Google::Cloud::Discoveryengine::V1beta::SessionService::SessionServiceClient ===
package Google::Cloud::Discoveryengine::V1beta::SessionService::SessionServiceClient;

=pod

=head2 Service Client: Google::Cloud::Discoveryengine::V1beta::SessionService::SessionServiceClient

Client stub representing the remote C<SessionService> gRPC service. Delegates call dispatching to L<Google::gRPC::Client>.

=head3 target

The endpoint target address. Defaults to C<discoveryengine.googleapis.com:443>.

=head3 credentials

The authentication credentials provider. Defaults to application default credentials via L<Google::Auth>.

=cut

use Moo;
use Google::Auth;
use Google::gRPC::Client;

has credentials => ( is => 'ro', default => sub { Google::Auth->default() } );
has target      => ( is => 'ro', default => 'discoveryengine.googleapis.com:443' );

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

sub create_session {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Discoveryengine::V1beta::ConversationalSearchService::CreateSessionRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.discoveryengine.v1beta.SessionService',
        method         => 'CreateSession',
        request        => $req,
        response_class => 'Google::Cloud::Discoveryengine::V1beta::Session::Session',
    });
}

sub delete_session {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Discoveryengine::V1beta::ConversationalSearchService::DeleteSessionRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.discoveryengine.v1beta.SessionService',
        method         => 'DeleteSession',
        request        => $req,
        response_class => 'Google::Protobuf::Empty::Empty',
    });
}

sub update_session {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Discoveryengine::V1beta::ConversationalSearchService::UpdateSessionRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.discoveryengine.v1beta.SessionService',
        method         => 'UpdateSession',
        request        => $req,
        response_class => 'Google::Cloud::Discoveryengine::V1beta::Session::Session',
    });
}

sub get_session {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Discoveryengine::V1beta::ConversationalSearchService::GetSessionRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.discoveryengine.v1beta.SessionService',
        method         => 'GetSession',
        request        => $req,
        response_class => 'Google::Cloud::Discoveryengine::V1beta::Session::Session',
    });
}

sub list_sessions {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Discoveryengine::V1beta::ConversationalSearchService::ListSessionsRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.discoveryengine.v1beta.SessionService',
        method         => 'ListSessions',
        request        => $req,
        response_class => 'Google::Cloud::Discoveryengine::V1beta::ConversationalSearchService::ListSessionsResponse',
    });
}

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Discoveryengine::V1beta::SessionService - Compiled Protocol Buffers messages for google/cloud/discoveryengine/v1beta/session_service.proto

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/discoveryengine/v1beta/session_service.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Discoveryengine::V1beta::SessionService::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
