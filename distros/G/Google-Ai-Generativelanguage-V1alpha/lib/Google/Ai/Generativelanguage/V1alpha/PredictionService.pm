package Google::Ai::Generativelanguage::V1alpha::PredictionService;

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
    eval { require Google::Protobuf::Struct };
    my $descriptor_b64 = <<'EOF';
Cj1nb29nbGUvYWkvZ2VuZXJhdGl2ZWxhbmd1YWdlL3YxYWxwaGEvcHJlZGljdGlvbl9zZXJ2
aWNlLnByb3RvEiRnb29nbGUuYWkuZ2VuZXJhdGl2ZWxhbmd1YWdlLnYxYWxwaGEaHGdvb2ds
ZS9hcGkvYW5ub3RhdGlvbnMucHJvdG8aF2dvb2dsZS9hcGkvY2xpZW50LnByb3RvGh9nb29n
bGUvYXBpL2ZpZWxkX2JlaGF2aW9yLnByb3RvGhlnb29nbGUvYXBpL3Jlc291cmNlLnByb3Rv
Ghxnb29nbGUvcHJvdG9idWYvc3RydWN0LnByb3RvIs8BCg5QcmVkaWN0UmVxdWVzdBJFCgVt
b2RlbBgBIAEoCUIv4EEC+kEpCidnZW5lcmF0aXZlbGFuZ3VhZ2UuZ29vZ2xlYXBpcy5jb20v
TW9kZWxSBW1vZGVsEjkKCWluc3RhbmNlcxgCIAMoCzIWLmdvb2dsZS5wcm90b2J1Zi5WYWx1
ZUID4EECUglpbnN0YW5jZXMSOwoKcGFyYW1ldGVycxgDIAEoCzIWLmdvb2dsZS5wcm90b2J1
Zi5WYWx1ZUID4EEBUgpwYXJhbWV0ZXJzIksKD1ByZWRpY3RSZXNwb25zZRI4CgtwcmVkaWN0
aW9ucxgBIAMoCzIWLmdvb2dsZS5wcm90b2J1Zi5WYWx1ZVILcHJlZGljdGlvbnMy8gEKEVBy
ZWRpY3Rpb25TZXJ2aWNlErYBCgdQcmVkaWN0EjQuZ29vZ2xlLmFpLmdlbmVyYXRpdmVsYW5n
dWFnZS52MWFscGhhLlByZWRpY3RSZXF1ZXN0GjUuZ29vZ2xlLmFpLmdlbmVyYXRpdmVsYW5n
dWFnZS52MWFscGhhLlByZWRpY3RSZXNwb25zZSI+gtPkkwImIiEvdjFhbHBoYS97bW9kZWw9
bW9kZWxzLyp9OnByZWRpY3Q6ASraQQ9tb2RlbCxpbnN0YW5jZXMaJMpBIWdlbmVyYXRpdmVs
YW5ndWFnZS5nb29nbGVhcGlzLmNvbUKkAQooY29tLmdvb2dsZS5haS5nZW5lcmF0aXZlbGFu
Z3VhZ2UudjFhbHBoYUIWUHJlZGljdGlvblNlcnZpY2VQcm90b1ABWl5jbG91ZC5nb29nbGUu
Y29tL2dvL2FpL2dlbmVyYXRpdmVsYW5ndWFnZS9hcGl2MWFscGhhL2dlbmVyYXRpdmVsYW5n
dWFnZXBiO2dlbmVyYXRpdmVsYW5ndWFnZXBiSp8OCgYSBA4AQwEKvAQKAQwSAw4AEjKxBCBD
b3B5cmlnaHQgMjAyNSBHb29nbGUgTExDCgogTGljZW5zZWQgdW5kZXIgdGhlIEFwYWNoZSBM
aWNlbnNlLCBWZXJzaW9uIDIuMCAodGhlICJMaWNlbnNlIik7CiB5b3UgbWF5IG5vdCB1c2Ug
dGhpcyBmaWxlIGV4Y2VwdCBpbiBjb21wbGlhbmNlIHdpdGggdGhlIExpY2Vuc2UuCiBZb3Ug
bWF5IG9idGFpbiBhIGNvcHkgb2YgdGhlIExpY2Vuc2UgYXQKCiAgICAgaHR0cDovL3d3dy5h
cGFjaGUub3JnL2xpY2Vuc2VzL0xJQ0VOU0UtMi4wCgogVW5sZXNzIHJlcXVpcmVkIGJ5IGFw
cGxpY2FibGUgbGF3IG9yIGFncmVlZCB0byBpbiB3cml0aW5nLCBzb2Z0d2FyZQogZGlzdHJp
YnV0ZWQgdW5kZXIgdGhlIExpY2Vuc2UgaXMgZGlzdHJpYnV0ZWQgb24gYW4gIkFTIElTIiBC
QVNJUywKIFdJVEhPVVQgV0FSUkFOVElFUyBPUiBDT05ESVRJT05TIE9GIEFOWSBLSU5ELCBl
aXRoZXIgZXhwcmVzcyBvciBpbXBsaWVkLgogU2VlIHRoZSBMaWNlbnNlIGZvciB0aGUgc3Bl
Y2lmaWMgbGFuZ3VhZ2UgZ292ZXJuaW5nIHBlcm1pc3Npb25zIGFuZAogbGltaXRhdGlvbnMg
dW5kZXIgdGhlIExpY2Vuc2UuCgoICgECEgMQAC0KCQoCAwASAxIAJgoJCgIDARIDEwAhCgkK
AgMCEgMUACkKCQoCAwMSAxUAIwoJCgIDBBIDFgAmCggKAQgSAxgAdQoJCgIICxIDGAB1CggK
AQgSAxkAIgoJCgIIChIDGQAiCggKAQgSAxoANwoJCgIICBIDGgA3CggKAQgSAxsAQQoJCgII
ARIDGwBBCkAKAgYAEgQeACkBGjQgQSBzZXJ2aWNlIGZvciBvbmxpbmUgcHJlZGljdGlvbnMg
YW5kIGV4cGxhbmF0aW9ucy4KCgoKAwYAARIDHggZCgoKAwYAAxIDHwJJCgwKBQYAA5kIEgMf
AkkKLgoEBgACABIEIgIoAxogIFBlcmZvcm1zIGEgcHJlZGljdGlvbiByZXF1ZXN0LgoKDAoF
BgACAAESAyIGDQoMCgUGAAIAAhIDIg4cCgwKBQYAAgADEgMiJzYKDQoFBgACAAQSBCMEJgYK
EQoJBgACAASwyrwiEgQjBCYGCgwKBQYAAgAEEgMnBD0KDwoIBgACAASbCAASAycEPQp/CgIE
ABIELQA9ARpzIFJlcXVlc3QgbWVzc2FnZSBmb3IKIFtQcmVkaWN0aW9uU2VydmljZS5QcmVk
aWN0XVtnb29nbGUuYWkuZ2VuZXJhdGl2ZWxhbmd1YWdlLnYxYWxwaGEuUHJlZGljdGlvblNl
cnZpY2UuUHJlZGljdF0uCgoKCgMEAAESAy0IFgpfCgQEAAIAEgQwAjUEGlEgUmVxdWlyZWQu
IFRoZSBuYW1lIG9mIHRoZSBtb2RlbCBmb3IgcHJlZGljdGlvbi4KIEZvcm1hdDogYG5hbWU9
bW9kZWxzL3ttb2RlbH1gLgoKDAoFBAACAAUSAzACCAoMCgUEAAIAARIDMAkOCgwKBQQAAgAD
EgMwERIKDQoFBAACAAgSBDATNQMKDwoIBAACAAicCAASAzEEKgoPCgcEAAIACJ8IEgQyBDQF
ClIKBAQAAgESBDgCOS8aRCBSZXF1aXJlZC4gVGhlIGluc3RhbmNlcyB0aGF0IGFyZSB0aGUg
aW5wdXQgdG8gdGhlIHByZWRpY3Rpb24gY2FsbC4KCgwKBQQAAgEEEgM4AgoKDAoFBAACAQYS
AzgLIAoMCgUEAAIBARIDOCEqCgwKBQQAAgEDEgM4LS4KDAoFBAACAQgSAzkGLgoPCggEAAIB
CJwIABIDOQctCkgKBAQAAgISAzwCUBo7IE9wdGlvbmFsLiBUaGUgcGFyYW1ldGVycyB0aGF0
IGdvdmVybiB0aGUgcHJlZGljdGlvbiBjYWxsLgoKDAoFBAACAgYSAzwCFwoMCgUEAAICARID
PBgiCgwKBQQAAgIDEgM8JSYKDAoFBAACAggSAzwnTwoPCggEAAICCJwIABIDPChOCj8KAgQB
EgRAAEMBGjMgUmVzcG9uc2UgbWVzc2FnZSBmb3IgW1ByZWRpY3Rpb25TZXJ2aWNlLlByZWRp
Y3RdLgoKCgoDBAEBEgNACBcKMgoEBAECABIDQgIxGiUgVGhlIG91dHB1dHMgb2YgdGhlIHBy
ZWRpY3Rpb24gY2FsbC4KCgwKBQQBAgAEEgNCAgoKDAoFBAECAAYSA0ILIAoMCgUEAQIAARID
QiEsCgwKBQQBAgADEgNCLzBiBnByb3RvMw==
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Ai::Generativelanguage::V1alpha::PredictionService::PredictRequest ===
    # Fields for PredictRequest
    # Field: model Type: 9 ()
    # Field: instances Type: 11 (.google.protobuf.Value)
    # Field: parameters Type: 11 (.google.protobuf.Value)

# === Message: Google::Ai::Generativelanguage::V1alpha::PredictionService::PredictResponse ===
    # Fields for PredictResponse
    # Field: predictions Type: 11 (.google.protobuf.Value)

# === Service Client: Google::Ai::Generativelanguage::V1alpha::PredictionService::PredictionServiceClient ===
package Google::Ai::Generativelanguage::V1alpha::PredictionService::PredictionServiceClient;

=pod

=head2 Service Client: Google::Ai::Generativelanguage::V1alpha::PredictionService::PredictionServiceClient

Client stub representing the remote C<PredictionService> gRPC service. Delegates call dispatching to L<Google::gRPC::Client>.

=head3 target

The endpoint target address. Defaults to C<ai.googleapis.com:443>.

=head3 credentials

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

sub predict {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Ai::Generativelanguage::V1alpha::PredictionService::PredictRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.ai.generativelanguage.v1alpha.PredictionService',
        method         => 'Predict',
        request        => $req,
        response_class => 'Google::Ai::Generativelanguage::V1alpha::PredictionService::PredictResponse',
    });
}

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Ai::Generativelanguage::V1alpha::PredictionService - Compiled Protocol Buffers messages for google/ai/generativelanguage/v1alpha/prediction_service.proto

=head1 SYNOPSIS

    use Google::Ai::Generativelanguage::V1alpha::PredictionService;

    my $msg = Google::Ai::Generativelanguage::V1alpha::PredictionService::PredictRequest->new({
        model => $model,
        instances => $instances,
        parameters => $parameters,
    });

    # Read or update a field
    my $val = $msg->model();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Ai::Generativelanguage::V1alpha::PredictionService::PredictRequest->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/ai/generativelanguage/v1alpha/prediction_service.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Ai::Generativelanguage::V1alpha::PredictionService::PredictRequest

Request message for
[PredictionService.Predict][google.ai.generativelanguage.v1alpha.PredictionService.Predict].

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->model() >> / C<< $msg->model($value) >>

Type: C<String>

Required. The name of the model for prediction.
Format: `name=models/{model}`.

=item * C<< $msg->instances() >> / C<< $msg->instances($value) >>

Type: C<Message> (L<Google::Protobuf::Struct::Value>)

Required. The instances that are the input to the prediction call.

=item * C<< $msg->parameters() >> / C<< $msg->parameters($value) >>

Type: C<Message> (L<Google::Protobuf::Struct::Value>)

Optional. The parameters that govern the prediction call.

=back

=head2 Google::Ai::Generativelanguage::V1alpha::PredictionService::PredictResponse

Response message for [PredictionService.Predict].

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->predictions() >> / C<< $msg->predictions($value) >>

Type: C<Message> (L<Google::Protobuf::Struct::Value>)

The outputs of the prediction call.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Ai::Generativelanguage::V1alpha::PredictionService::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
