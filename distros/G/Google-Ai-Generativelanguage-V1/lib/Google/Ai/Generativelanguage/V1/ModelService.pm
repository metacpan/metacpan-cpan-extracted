package Google::Ai::Generativelanguage::V1::ModelService;

use strict;
use warnings;

our $VERSION = '0.11';

use Protobuf::Message;
use Protobuf::DescriptorPool;
use Protobuf::Internal qw(:all);
use MIME::Base64;

BEGIN {
    eval { require Google::Ai::Generativelanguage::V1::Model };
    eval { require Google::Api::Annotations };
    eval { require Google::Api::Client };
    eval { require Google::Api::FieldBehavior };
    eval { require Google::Api::Resource };
    my $descriptor_b64 = <<'EOF';
CjNnb29nbGUvYWkvZ2VuZXJhdGl2ZWxhbmd1YWdlL3YxL21vZGVsX3NlcnZpY2UucHJvdG8S
H2dvb2dsZS5haS5nZW5lcmF0aXZlbGFuZ3VhZ2UudjEaK2dvb2dsZS9haS9nZW5lcmF0aXZl
bGFuZ3VhZ2UvdjEvbW9kZWwucHJvdG8aHGdvb2dsZS9hcGkvYW5ub3RhdGlvbnMucHJvdG8a
F2dvb2dsZS9hcGkvY2xpZW50LnByb3RvGh9nb29nbGUvYXBpL2ZpZWxkX2JlaGF2aW9yLnBy
b3RvGhlnb29nbGUvYXBpL3Jlc291cmNlLnByb3RvIlYKD0dldE1vZGVsUmVxdWVzdBJDCgRu
YW1lGAEgASgJQi/gQQL6QSkKJ2dlbmVyYXRpdmVsYW5ndWFnZS5nb29nbGVhcGlzLmNvbS9N
b2RlbFIEbmFtZSJPChFMaXN0TW9kZWxzUmVxdWVzdBIbCglwYWdlX3NpemUYAiABKAVSCHBh
Z2VTaXplEh0KCnBhZ2VfdG9rZW4YAyABKAlSCXBhZ2VUb2tlbiJ8ChJMaXN0TW9kZWxzUmVz
cG9uc2USPgoGbW9kZWxzGAEgAygLMiYuZ29vZ2xlLmFpLmdlbmVyYXRpdmVsYW5ndWFnZS52
MS5Nb2RlbFIGbW9kZWxzEiYKD25leHRfcGFnZV90b2tlbhgCIAEoCVINbmV4dFBhZ2VUb2tl
bjLiAgoMTW9kZWxTZXJ2aWNlEogBCghHZXRNb2RlbBIwLmdvb2dsZS5haS5nZW5lcmF0aXZl
bGFuZ3VhZ2UudjEuR2V0TW9kZWxSZXF1ZXN0GiYuZ29vZ2xlLmFpLmdlbmVyYXRpdmVsYW5n
dWFnZS52MS5Nb2RlbCIigtPkkwIVEhMvdjEve25hbWU9bW9kZWxzLyp92kEEbmFtZRKgAQoK
TGlzdE1vZGVscxIyLmdvb2dsZS5haS5nZW5lcmF0aXZlbGFuZ3VhZ2UudjEuTGlzdE1vZGVs
c1JlcXVlc3QaMy5nb29nbGUuYWkuZ2VuZXJhdGl2ZWxhbmd1YWdlLnYxLkxpc3RNb2RlbHNS
ZXNwb25zZSIpgtPkkwIMEgovdjEvbW9kZWxz2kEUcGFnZV9zaXplLHBhZ2VfdG9rZW4aJMpB
IWdlbmVyYXRpdmVsYW5ndWFnZS5nb29nbGVhcGlzLmNvbUKVAQojY29tLmdvb2dsZS5haS5n
ZW5lcmF0aXZlbGFuZ3VhZ2UudjFCEU1vZGVsU2VydmljZVByb3RvUAFaWWNsb3VkLmdvb2ds
ZS5jb20vZ28vYWkvZ2VuZXJhdGl2ZWxhbmd1YWdlL2FwaXYxL2dlbmVyYXRpdmVsYW5ndWFn
ZXBiO2dlbmVyYXRpdmVsYW5ndWFnZXBiSt4WCgYSBA4AYwEKvAQKAQwSAw4AEjKxBCBDb3B5
cmlnaHQgMjAyNSBHb29nbGUgTExDCgogTGljZW5zZWQgdW5kZXIgdGhlIEFwYWNoZSBMaWNl
bnNlLCBWZXJzaW9uIDIuMCAodGhlICJMaWNlbnNlIik7CiB5b3UgbWF5IG5vdCB1c2UgdGhp
cyBmaWxlIGV4Y2VwdCBpbiBjb21wbGlhbmNlIHdpdGggdGhlIExpY2Vuc2UuCiBZb3UgbWF5
IG9idGFpbiBhIGNvcHkgb2YgdGhlIExpY2Vuc2UgYXQKCiAgICAgaHR0cDovL3d3dy5hcGFj
aGUub3JnL2xpY2Vuc2VzL0xJQ0VOU0UtMi4wCgogVW5sZXNzIHJlcXVpcmVkIGJ5IGFwcGxp
Y2FibGUgbGF3IG9yIGFncmVlZCB0byBpbiB3cml0aW5nLCBzb2Z0d2FyZQogZGlzdHJpYnV0
ZWQgdW5kZXIgdGhlIExpY2Vuc2UgaXMgZGlzdHJpYnV0ZWQgb24gYW4gIkFTIElTIiBCQVNJ
UywKIFdJVEhPVVQgV0FSUkFOVElFUyBPUiBDT05ESVRJT05TIE9GIEFOWSBLSU5ELCBlaXRo
ZXIgZXhwcmVzcyBvciBpbXBsaWVkLgogU2VlIHRoZSBMaWNlbnNlIGZvciB0aGUgc3BlY2lm
aWMgbGFuZ3VhZ2UgZ292ZXJuaW5nIHBlcm1pc3Npb25zIGFuZAogbGltaXRhdGlvbnMgdW5k
ZXIgdGhlIExpY2Vuc2UuCgoICgECEgMQACgKCQoCAwASAxIANQoJCgIDARIDEwAmCgkKAgMC
EgMUACEKCQoCAwMSAxUAKQoJCgIDBBIDFgAjCggKAQgSAxgAcAoJCgIICxIDGABwCggKAQgS
AxkAIgoJCgIIChIDGQAiCggKAQgSAxoAMgoJCgIICBIDGgAyCggKAQgSAxsAPAoJCgIIARID
GwA8ClgKAgYAEgQeADYBGkwgUHJvdmlkZXMgbWV0aG9kcyBmb3IgZ2V0dGluZyBtZXRhZGF0
YSBpbmZvcm1hdGlvbiBhYm91dCBHZW5lcmF0aXZlIE1vZGVscy4KCgoKAwYAARIDHggUCgoK
AwYAAxIDHwJJCgwKBQYAA5kIEgMfAkkK0wIKBAYAAgASBCcCLAMaxAIgR2V0cyBpbmZvcm1h
dGlvbiBhYm91dCBhIHNwZWNpZmljIGBNb2RlbGAgc3VjaCBhcyBpdHMgdmVyc2lvbiBudW1i
ZXIsIHRva2VuCiBsaW1pdHMsCiBbcGFyYW1ldGVyc10oaHR0cHM6Ly9haS5nb29nbGUuZGV2
L2dlbWluaS1hcGkvZG9jcy9tb2RlbHMvZ2VuZXJhdGl2ZS1tb2RlbHMjbW9kZWwtcGFyYW1l
dGVycykKIGFuZCBvdGhlciBtZXRhZGF0YS4gUmVmZXIgdG8gdGhlIFtHZW1pbmkgbW9kZWxz
CiBndWlkZV0oaHR0cHM6Ly9haS5nb29nbGUuZGV2L2dlbWluaS1hcGkvZG9jcy9tb2RlbHMv
Z2VtaW5pKSBmb3IgZGV0YWlsZWQKIG1vZGVsIGluZm9ybWF0aW9uLgoKDAoFBgACAAESAycG
DgoMCgUGAAIAAhIDJw8eCgwKBQYAAgADEgMnKS4KDQoFBgACAAQSBCgEKgYKEQoJBgACAASw
yrwiEgQoBCoGCgwKBQYAAgAEEgMrBDIKDwoIBgACAASbCAASAysEMgp8CgQGAAIBEgQwAjUD
Gm4gTGlzdHMgdGhlIFtgTW9kZWxgc10oaHR0cHM6Ly9haS5nb29nbGUuZGV2L2dlbWluaS1h
cGkvZG9jcy9tb2RlbHMvZ2VtaW5pKQogYXZhaWxhYmxlIHRocm91Z2ggdGhlIEdlbWluaSBB
UEkuCgoMCgUGAAIBARIDMAYQCgwKBQYAAgECEgMwESIKDAoFBgACAQMSAzAtPwoNCgUGAAIB
BBIEMQQzBgoRCgkGAAIBBLDKvCISBDEEMwYKDAoFBgACAQQSAzQEQgoPCggGAAIBBJsIABID
NARCCkUKAgQAEgQ5AEUBGjkgUmVxdWVzdCBmb3IgZ2V0dGluZyBpbmZvcm1hdGlvbiBhYm91
dCBhIHNwZWNpZmljIE1vZGVsLgoKCgoDBAABEgM5CBcKoAEKBAQAAgASBD8CRAQakQEgUmVx
dWlyZWQuIFRoZSByZXNvdXJjZSBuYW1lIG9mIHRoZSBtb2RlbC4KCiBUaGlzIG5hbWUgc2hv
dWxkIG1hdGNoIGEgbW9kZWwgbmFtZSByZXR1cm5lZCBieSB0aGUgYExpc3RNb2RlbHNgIG1l
dGhvZC4KCiBGb3JtYXQ6IGBtb2RlbHMve21vZGVsfWAKCgwKBQQAAgAFEgM/AggKDAoFBAAC
AAESAz8JDQoMCgUEAAIAAxIDPxARCg0KBQQAAgAIEgQ/EkQDCg8KCAQAAgAInAgAEgNABCoK
DwoHBAACAAifCBIEQQRDBQotCgIEARIESABYARohIFJlcXVlc3QgZm9yIGxpc3RpbmcgYWxs
IE1vZGVscy4KCgoKAwQBARIDSAgZCtQBCgQEAQIAEgNOAhYaxgEgVGhlIG1heGltdW0gbnVt
YmVyIG9mIGBNb2RlbHNgIHRvIHJldHVybiAocGVyIHBhZ2UpLgoKIElmIHVuc3BlY2lmaWVk
LCA1MCBtb2RlbHMgd2lsbCBiZSByZXR1cm5lZCBwZXIgcGFnZS4KIFRoaXMgbWV0aG9kIHJl
dHVybnMgYXQgbW9zdCAxMDAwIG1vZGVscyBwZXIgcGFnZSwgZXZlbiBpZiB5b3UgcGFzcyBh
IGxhcmdlcgogcGFnZV9zaXplLgoKDAoFBAECAAUSA04CBwoMCgUEAQIAARIDTggRCgwKBQQB
AgADEgNOFBUKrwIKBAQBAgESA1cCGBqhAiBBIHBhZ2UgdG9rZW4sIHJlY2VpdmVkIGZyb20g
YSBwcmV2aW91cyBgTGlzdE1vZGVsc2AgY2FsbC4KCiBQcm92aWRlIHRoZSBgcGFnZV90b2tl
bmAgcmV0dXJuZWQgYnkgb25lIHJlcXVlc3QgYXMgYW4gYXJndW1lbnQgdG8gdGhlIG5leHQK
IHJlcXVlc3QgdG8gcmV0cmlldmUgdGhlIG5leHQgcGFnZS4KCiBXaGVuIHBhZ2luYXRpbmcs
IGFsbCBvdGhlciBwYXJhbWV0ZXJzIHByb3ZpZGVkIHRvIGBMaXN0TW9kZWxzYCBtdXN0IG1h
dGNoCiB0aGUgY2FsbCB0aGF0IHByb3ZpZGVkIHRoZSBwYWdlIHRva2VuLgoKDAoFBAECAQUS
A1cCCAoMCgUEAQIBARIDVwkTCgwKBQQBAgEDEgNXFhcKTgoCBAISBFsAYwEaQiBSZXNwb25z
ZSBmcm9tIGBMaXN0TW9kZWxgIGNvbnRhaW5pbmcgYSBwYWdpbmF0ZWQgbGlzdCBvZiBNb2Rl
bHMuCgoKCgMEAgESA1sIGgojCgQEAgIAEgNdAhwaFiBUaGUgcmV0dXJuZWQgTW9kZWxzLgoK
DAoFBAICAAQSA10CCgoMCgUEAgIABhIDXQsQCgwKBQQCAgABEgNdERcKDAoFBAICAAMSA10a
GwqJAQoEBAICARIDYgIdGnwgQSB0b2tlbiwgd2hpY2ggY2FuIGJlIHNlbnQgYXMgYHBhZ2Vf
dG9rZW5gIHRvIHJldHJpZXZlIHRoZSBuZXh0IHBhZ2UuCgogSWYgdGhpcyBmaWVsZCBpcyBv
bWl0dGVkLCB0aGVyZSBhcmUgbm8gbW9yZSBwYWdlcy4KCgwKBQQCAgEFEgNiAggKDAoFBAIC
AQESA2IJGAoMCgUEAgIBAxIDYhscYgZwcm90bzM=
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Ai::Generativelanguage::V1::ModelService::GetModelRequest ===
    # Fields for GetModelRequest
    # Field: name Type: 9 ()

=pod

=head1 NAME

Google::Ai::Generativelanguage::V1::ModelService::GetModelRequest - Compiled Protocol Buffers message class

=head1 SYNOPSIS

    use Google::Ai::Generativelanguage::V1::ModelService;

    my $msg = Google::Ai::Generativelanguage::V1::ModelService::GetModelRequest->new(
        name => $value,
    );

=head1 FIELDS

=over 4

=item * B<name>

Type: String

=back

=cut

# === Message: Google::Ai::Generativelanguage::V1::ModelService::ListModelsRequest ===
    # Fields for ListModelsRequest
    # Field: page_size Type: 5 ()
    # Field: page_token Type: 9 ()

=pod

=head1 NAME

Google::Ai::Generativelanguage::V1::ModelService::ListModelsRequest - Compiled Protocol Buffers message class

=head1 SYNOPSIS

    use Google::Ai::Generativelanguage::V1::ModelService;

    my $msg = Google::Ai::Generativelanguage::V1::ModelService::ListModelsRequest->new(
        page_size => $value,
    );

=head1 FIELDS

=over 4

=item * B<page_size>

Type: Int32

=item * B<page_token>

Type: String

=back

=cut

# === Message: Google::Ai::Generativelanguage::V1::ModelService::ListModelsResponse ===
    # Fields for ListModelsResponse
    # Field: models Type: 11 (.google.ai.generativelanguage.v1.Model)
    # Field: next_page_token Type: 9 ()

=pod

=head1 NAME

Google::Ai::Generativelanguage::V1::ModelService::ListModelsResponse - Compiled Protocol Buffers message class

=head1 SYNOPSIS

    use Google::Ai::Generativelanguage::V1::ModelService;

    my $msg = Google::Ai::Generativelanguage::V1::ModelService::ListModelsResponse->new(
        models => $value,
    );

=head1 FIELDS

=over 4

=item * B<models>

Type: Message (.google.ai.generativelanguage.v1.Model)

=item * B<next_page_token>

Type: String

=back

=cut

# === Service Client: Google::Ai::Generativelanguage::V1::ModelService::ModelServiceClient ===
package Google::Ai::Generativelanguage::V1::ModelService::ModelServiceClient;

=pod

=head1 NAME

Google::Ai::Generativelanguage::V1::ModelService::ModelServiceClient - Client stub representing the remote ModelService service

=head1 DESCRIPTION

This class acts as a local client stub for the remote gRPC service.
It delegates call dispatching to an underlying L<Google::gRPC::Client>
instance, ensuring type-safe request parsing and response mapping.

=head1 CONFIGURATION AND ENVIRONMENT

=head2 target

The endpoint target address. Defaults to C<ai.googleapis.com:443>.

=head2 credentials

The authentication credentials provider. Defaults to application default credentials via L<Google::Auth>.

=cut

use Moo;
use Google::Auth;
use Google::gRPC::Client;

has credentials => ( is => 'ro', default => sub { Google::Auth->default() } );
has target      => ( is => 'ro', default => 'ai.googleapis.com:443' );

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

sub get_model {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Ai::Generativelanguage::V1::ModelService::GetModelRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.ai.generativelanguage.v1.ModelService',
        method         => 'GetModel',
        request        => $req,
        response_class => 'Google::Ai::Generativelanguage::V1::Model::Model',
    });
}

sub list_models {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Ai::Generativelanguage::V1::ModelService::ListModelsRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.ai.generativelanguage.v1.ModelService',
        method         => 'ListModels',
        request        => $req,
        response_class => 'Google::Ai::Generativelanguage::V1::ModelService::ListModelsResponse',
    });
}

1;

__END__

=head1 NAME

Google::Ai::Generativelanguage::V1::ModelService - Protocol Buffers schema definition

=head1 DESCRIPTION

Auto-generated Protocol Buffers schema definition class.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
