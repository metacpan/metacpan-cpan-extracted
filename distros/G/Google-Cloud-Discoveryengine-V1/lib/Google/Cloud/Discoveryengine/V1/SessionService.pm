package Google::Cloud::Discoveryengine::V1::SessionService;

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
    eval { require Google::Cloud::Discoveryengine::V1::ConversationalSearchService };
    eval { require Google::Cloud::Discoveryengine::V1::Session };
    eval { require Google::Protobuf::Empty };
    my $descriptor_b64 = <<'EOF';
CjVnb29nbGUvY2xvdWQvZGlzY292ZXJ5ZW5naW5lL3YxL3Nlc3Npb25fc2VydmljZS5wcm90
bxIfZ29vZ2xlLmNsb3VkLmRpc2NvdmVyeWVuZ2luZS52MRocZ29vZ2xlL2FwaS9hbm5vdGF0
aW9ucy5wcm90bxoXZ29vZ2xlL2FwaS9jbGllbnQucHJvdG8aH2dvb2dsZS9hcGkvZmllbGRf
YmVoYXZpb3IucHJvdG8aGWdvb2dsZS9hcGkvcmVzb3VyY2UucHJvdG8aQ2dvb2dsZS9jbG91
ZC9kaXNjb3ZlcnllbmdpbmUvdjEvY29udmVyc2F0aW9uYWxfc2VhcmNoX3NlcnZpY2UucHJv
dG8aLWdvb2dsZS9jbG91ZC9kaXNjb3ZlcnllbmdpbmUvdjEvc2Vzc2lvbi5wcm90bxobZ29v
Z2xlL3Byb3RvYnVmL2VtcHR5LnByb3RvMpkQCg5TZXNzaW9uU2VydmljZRL0AgoNQ3JlYXRl
U2Vzc2lvbhI1Lmdvb2dsZS5jbG91ZC5kaXNjb3ZlcnllbmdpbmUudjEuQ3JlYXRlU2Vzc2lv
blJlcXVlc3QaKC5nb29nbGUuY2xvdWQuZGlzY292ZXJ5ZW5naW5lLnYxLlNlc3Npb24igQKC
0+STAukBIjkvdjEve3BhcmVudD1wcm9qZWN0cy8qL2xvY2F0aW9ucy8qL2RhdGFTdG9yZXMv
Kn0vc2Vzc2lvbnM6B3Nlc3Npb25aUiJHL3YxL3twYXJlbnQ9cHJvamVjdHMvKi9sb2NhdGlv
bnMvKi9jb2xsZWN0aW9ucy8qL2RhdGFTdG9yZXMvKn0vc2Vzc2lvbnM6B3Nlc3Npb25aTyJE
L3YxL3twYXJlbnQ9cHJvamVjdHMvKi9sb2NhdGlvbnMvKi9jb2xsZWN0aW9ucy8qL2VuZ2lu
ZXMvKn0vc2Vzc2lvbnM6B3Nlc3Npb27aQQ5wYXJlbnQsc2Vzc2lvbhK9AgoNRGVsZXRlU2Vz
c2lvbhI1Lmdvb2dsZS5jbG91ZC5kaXNjb3ZlcnllbmdpbmUudjEuRGVsZXRlU2Vzc2lvblJl
cXVlc3QaFi5nb29nbGUucHJvdG9idWYuRW1wdHki3AGC0+STAs4BKjkvdjEve25hbWU9cHJv
amVjdHMvKi9sb2NhdGlvbnMvKi9kYXRhU3RvcmVzLyovc2Vzc2lvbnMvKn1aSSpHL3YxL3tu
YW1lPXByb2plY3RzLyovbG9jYXRpb25zLyovY29sbGVjdGlvbnMvKi9kYXRhU3RvcmVzLyov
c2Vzc2lvbnMvKn1aRipEL3YxL3tuYW1lPXByb2plY3RzLyovbG9jYXRpb25zLyovY29sbGVj
dGlvbnMvKi9lbmdpbmVzLyovc2Vzc2lvbnMvKn3aQQRuYW1lEpEDCg1VcGRhdGVTZXNzaW9u
EjUuZ29vZ2xlLmNsb3VkLmRpc2NvdmVyeWVuZ2luZS52MS5VcGRhdGVTZXNzaW9uUmVxdWVz
dBooLmdvb2dsZS5jbG91ZC5kaXNjb3ZlcnllbmdpbmUudjEuU2Vzc2lvbiKeAoLT5JMCgQIy
QS92MS97c2Vzc2lvbi5uYW1lPXByb2plY3RzLyovbG9jYXRpb25zLyovZGF0YVN0b3Jlcy8q
L3Nlc3Npb25zLyp9OgdzZXNzaW9uWloyTy92MS97c2Vzc2lvbi5uYW1lPXByb2plY3RzLyov
bG9jYXRpb25zLyovY29sbGVjdGlvbnMvKi9kYXRhU3RvcmVzLyovc2Vzc2lvbnMvKn06B3Nl
c3Npb25aVzJML3YxL3tzZXNzaW9uLm5hbWU9cHJvamVjdHMvKi9sb2NhdGlvbnMvKi9jb2xs
ZWN0aW9ucy8qL2VuZ2luZXMvKi9zZXNzaW9ucy8qfToHc2Vzc2lvbtpBE3Nlc3Npb24sdXBk
YXRlX21hc2sSyQIKCkdldFNlc3Npb24SMi5nb29nbGUuY2xvdWQuZGlzY292ZXJ5ZW5naW5l
LnYxLkdldFNlc3Npb25SZXF1ZXN0GiguZ29vZ2xlLmNsb3VkLmRpc2NvdmVyeWVuZ2luZS52
MS5TZXNzaW9uItwBgtPkkwLOARI5L3YxL3tuYW1lPXByb2plY3RzLyovbG9jYXRpb25zLyov
ZGF0YVN0b3Jlcy8qL3Nlc3Npb25zLyp9WkkSRy92MS97bmFtZT1wcm9qZWN0cy8qL2xvY2F0
aW9ucy8qL2NvbGxlY3Rpb25zLyovZGF0YVN0b3Jlcy8qL3Nlc3Npb25zLyp9WkYSRC92MS97
bmFtZT1wcm9qZWN0cy8qL2xvY2F0aW9ucy8qL2NvbGxlY3Rpb25zLyovZW5naW5lcy8qL3Nl
c3Npb25zLyp92kEEbmFtZRLcAgoMTGlzdFNlc3Npb25zEjQuZ29vZ2xlLmNsb3VkLmRpc2Nv
dmVyeWVuZ2luZS52MS5MaXN0U2Vzc2lvbnNSZXF1ZXN0GjUuZ29vZ2xlLmNsb3VkLmRpc2Nv
dmVyeWVuZ2luZS52MS5MaXN0U2Vzc2lvbnNSZXNwb25zZSLeAYLT5JMCzgESOS92MS97cGFy
ZW50PXByb2plY3RzLyovbG9jYXRpb25zLyovZGF0YVN0b3Jlcy8qfS9zZXNzaW9uc1pJEkcv
djEve3BhcmVudD1wcm9qZWN0cy8qL2xvY2F0aW9ucy8qL2NvbGxlY3Rpb25zLyovZGF0YVN0
b3Jlcy8qfS9zZXNzaW9uc1pGEkQvdjEve3BhcmVudD1wcm9qZWN0cy8qL2xvY2F0aW9ucy8q
L2NvbGxlY3Rpb25zLyovZW5naW5lcy8qfS9zZXNzaW9uc9pBBnBhcmVudBqQAspBHmRpc2Nv
dmVyeWVuZ2luZS5nb29nbGVhcGlzLmNvbdJB6wFodHRwczovL3d3dy5nb29nbGVhcGlzLmNv
bS9hdXRoL2Nsb3VkLXBsYXRmb3JtLGh0dHBzOi8vd3d3Lmdvb2dsZWFwaXMuY29tL2F1dGgv
ZGlzY292ZXJ5ZW5naW5lLmFzc2lzdC5yZWFkd3JpdGUsaHR0cHM6Ly93d3cuZ29vZ2xlYXBp
cy5jb20vYXV0aC9kaXNjb3ZlcnllbmdpbmUucmVhZHdyaXRlLGh0dHBzOi8vd3d3Lmdvb2ds
ZWFwaXMuY29tL2F1dGgvZGlzY292ZXJ5ZW5naW5lLnNlcnZpbmcucmVhZHdyaXRlQoYCCiNj
b20uZ29vZ2xlLmNsb3VkLmRpc2NvdmVyeWVuZ2luZS52MUITU2Vzc2lvblNlcnZpY2VQcm90
b1ABWk1jbG91ZC5nb29nbGUuY29tL2dvL2Rpc2NvdmVyeWVuZ2luZS9hcGl2MS9kaXNjb3Zl
cnllbmdpbmVwYjtkaXNjb3ZlcnllbmdpbmVwYqICD0RJU0NPVkVSWUVOR0lORaoCH0dvb2ds
ZS5DbG91ZC5EaXNjb3ZlcnlFbmdpbmUuVjHKAh9Hb29nbGVcQ2xvdWRcRGlzY292ZXJ5RW5n
aW5lXFYx6gIiR29vZ2xlOjpDbG91ZDo6RGlzY292ZXJ5RW5naW5lOjpWMUqrEQoHEgUOAIIB
AQq8BAoBDBIDDgASMrEEIENvcHlyaWdodCAyMDI2IEdvb2dsZSBMTEMKCiBMaWNlbnNlZCB1
bmRlciB0aGUgQXBhY2hlIExpY2Vuc2UsIFZlcnNpb24gMi4wICh0aGUgIkxpY2Vuc2UiKTsK
IHlvdSBtYXkgbm90IHVzZSB0aGlzIGZpbGUgZXhjZXB0IGluIGNvbXBsaWFuY2Ugd2l0aCB0
aGUgTGljZW5zZS4KIFlvdSBtYXkgb2J0YWluIGEgY29weSBvZiB0aGUgTGljZW5zZSBhdAoK
ICAgICBodHRwOi8vd3d3LmFwYWNoZS5vcmcvbGljZW5zZXMvTElDRU5TRS0yLjAKCiBVbmxl
c3MgcmVxdWlyZWQgYnkgYXBwbGljYWJsZSBsYXcgb3IgYWdyZWVkIHRvIGluIHdyaXRpbmcs
IHNvZnR3YXJlCiBkaXN0cmlidXRlZCB1bmRlciB0aGUgTGljZW5zZSBpcyBkaXN0cmlidXRl
ZCBvbiBhbiAiQVMgSVMiIEJBU0lTLAogV0lUSE9VVCBXQVJSQU5USUVTIE9SIENPTkRJVElP
TlMgT0YgQU5ZIEtJTkQsIGVpdGhlciBleHByZXNzIG9yIGltcGxpZWQuCiBTZWUgdGhlIExp
Y2Vuc2UgZm9yIHRoZSBzcGVjaWZpYyBsYW5ndWFnZSBnb3Zlcm5pbmcgcGVybWlzc2lvbnMg
YW5kCiBsaW1pdGF0aW9ucyB1bmRlciB0aGUgTGljZW5zZS4KCggKAQISAxAAKAoJCgIDABID
EgAmCgkKAgMBEgMTACEKCQoCAwISAxQAKQoJCgIDAxIDFQAjCgkKAgMEEgMWAE0KCQoCAwUS
AxcANwoJCgIDBhIDGAAlCggKAQgSAxoAPAoJCgIIJRIDGgA8CggKAQgSAxsAZAoJCgIICxID
GwBkCggKAQgSAxwAIgoJCgIIChIDHAAiCggKAQgSAx0ANAoJCgIICBIDHQA0CggKAQgSAx4A
PAoJCgIIARIDHgA8CggKAQgSAx8ALQoJCgIIJBIDHwAtCggKAQgSAyAAPAoJCgIIKRIDIAA8
CggKAQgSAyEAOwoJCgIILRIDIQA7CksKAgYAEgUkAIIBARo+IFNlcnZpY2UgZm9yIG1hbmFn
aW5nIFNlc3Npb25zIGFuZCBTZXNzaW9uLXJlbGF0ZWQgcmVzb3VyY2VzLgoKCgoDBgABEgMk
CBYKCgoDBgADEgMlAkYKDAoFBgADmQgSAyUCRgoLCgMGAAMSBCYCKkoKDQoFBgADmggSBCYC
KkoKnwEKBAYAAgASBDACPgMakAEgQ3JlYXRlcyBhIFNlc3Npb24uCgogSWYgdGhlIFtTZXNz
aW9uXVtnb29nbGUuY2xvdWQuZGlzY292ZXJ5ZW5naW5lLnYxLlNlc3Npb25dIHRvIGNyZWF0
ZSBhbHJlYWR5CiBleGlzdHMsIGFuIEFMUkVBRFlfRVhJU1RTIGVycm9yIGlzIHJldHVybmVk
LgoKDAoFBgACAAESAzAGEwoMCgUGAAIAAhIDMBQoCgwKBQYAAgADEgMwMzoKDQoFBgACAAQS
BDEEPAYKEQoJBgACAASwyrwiEgQxBDwGCgwKBQYAAgAEEgM9BDwKDwoIBgACAASbCAASAz0E
PAqZAQoEBgACARIERAJPAxqKASBEZWxldGVzIGEgU2Vzc2lvbi4KCiBJZiB0aGUgW1Nlc3Np
b25dW2dvb2dsZS5jbG91ZC5kaXNjb3ZlcnllbmdpbmUudjEuU2Vzc2lvbl0gdG8gZGVsZXRl
IGRvZXMKIG5vdCBleGlzdCwgYSBOT1RfRk9VTkQgZXJyb3IgaXMgcmV0dXJuZWQuCgoMCgUG
AAIBARIDRAYTCgwKBQYAAgECEgNEFCgKDAoFBgACAQMSA0QzSAoNCgUGAAIBBBIERQRNBgoR
CgkGAAIBBLDKvCISBEUETQYKDAoFBgACAQQSA04EMgoPCggGAAIBBJsIABIDTgQyCuwBCgQG
AAICEgRWAmQDGt0BIFVwZGF0ZXMgYSBTZXNzaW9uLgoKIFtTZXNzaW9uXVtnb29nbGUuY2xv
dWQuZGlzY292ZXJ5ZW5naW5lLnYxLlNlc3Npb25dIGFjdGlvbiB0eXBlIGNhbm5vdCBiZQog
Y2hhbmdlZC4gSWYgdGhlIFtTZXNzaW9uXVtnb29nbGUuY2xvdWQuZGlzY292ZXJ5ZW5naW5l
LnYxLlNlc3Npb25dIHRvCiB1cGRhdGUgZG9lcyBub3QgZXhpc3QsIGEgTk9UX0ZPVU5EIGVy
cm9yIGlzIHJldHVybmVkLgoKDAoFBgACAgESA1YGEwoMCgUGAAICAhIDVhQoCgwKBQYAAgID
EgNWMzoKDQoFBgACAgQSBFcEYgYKEQoJBgACAgSwyrwiEgRXBGIGCgwKBQYAAgIEEgNjBEEK
DwoIBgACAgSbCAASA2MEQQofCgQGAAIDEgRnAnIDGhEgR2V0cyBhIFNlc3Npb24uCgoMCgUG
AAIDARIDZwYQCgwKBQYAAgMCEgNnESIKDAoFBgACAwMSA2ctNAoNCgUGAAIDBBIEaARwBgoR
CgkGAAIDBLDKvCISBGgEcAYKDAoFBgACAwQSA3EEMgoPCggGAAIDBJsIABIDcQQyCmwKBAYA
AgQSBXYCgQEDGl0gTGlzdHMgYWxsIFNlc3Npb25zIGJ5IHRoZWlyIHBhcmVudAogW0RhdGFT
dG9yZV1bZ29vZ2xlLmNsb3VkLmRpc2NvdmVyeWVuZ2luZS52MS5EYXRhU3RvcmVdLgoKDAoF
BgACBAESA3YGEgoMCgUGAAIEAhIDdhMmCgwKBQYAAgQDEgN2MUUKDQoFBgACBAQSBHcEfwYK
EQoJBgACBASwyrwiEgR3BH8GCg0KBQYAAgQEEgSAAQQ0ChAKCAYAAgQEmwgAEgSAAQQ0YgZw
cm90bzM=
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Service Client: Google::Cloud::Discoveryengine::V1::SessionService::SessionServiceClient ===
package Google::Cloud::Discoveryengine::V1::SessionService::SessionServiceClient;

=pod

=head2 Service Client: Google::Cloud::Discoveryengine::V1::SessionService::SessionServiceClient

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
        ? Google::Cloud::Discoveryengine::V1::ConversationalSearchService::CreateSessionRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.discoveryengine.v1.SessionService',
        method         => 'CreateSession',
        request        => $req,
        response_class => 'Google::Cloud::Discoveryengine::V1::Session::Session',
    });
}

sub delete_session {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Discoveryengine::V1::ConversationalSearchService::DeleteSessionRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.discoveryengine.v1.SessionService',
        method         => 'DeleteSession',
        request        => $req,
        response_class => 'Google::Protobuf::Empty::Empty',
    });
}

sub update_session {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Discoveryengine::V1::ConversationalSearchService::UpdateSessionRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.discoveryengine.v1.SessionService',
        method         => 'UpdateSession',
        request        => $req,
        response_class => 'Google::Cloud::Discoveryengine::V1::Session::Session',
    });
}

sub get_session {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Discoveryengine::V1::ConversationalSearchService::GetSessionRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.discoveryengine.v1.SessionService',
        method         => 'GetSession',
        request        => $req,
        response_class => 'Google::Cloud::Discoveryengine::V1::Session::Session',
    });
}

sub list_sessions {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Discoveryengine::V1::ConversationalSearchService::ListSessionsRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.discoveryengine.v1.SessionService',
        method         => 'ListSessions',
        request        => $req,
        response_class => 'Google::Cloud::Discoveryengine::V1::ConversationalSearchService::ListSessionsResponse',
    });
}

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Discoveryengine::V1::SessionService - Compiled Protocol Buffers messages for google/cloud/discoveryengine/v1/session_service.proto

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/discoveryengine/v1/session_service.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Discoveryengine::V1::SessionService::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
