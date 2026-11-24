package Google::Cloud::Discoveryengine::V1::CollectionService;

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
    eval { require Google::Iam::V1::IamPolicy };
    eval { require Google::Iam::V1::Policy };
    eval { require Google::Longrunning::Operations };
    eval { require Google::Protobuf::Empty };
    eval { require Google::Protobuf::Timestamp };
    my $descriptor_b64 = <<'EOF';
Cjhnb29nbGUvY2xvdWQvZGlzY292ZXJ5ZW5naW5lL3YxL2NvbGxlY3Rpb25fc2VydmljZS5w
cm90bxIfZ29vZ2xlLmNsb3VkLmRpc2NvdmVyeWVuZ2luZS52MRocZ29vZ2xlL2FwaS9hbm5v
dGF0aW9ucy5wcm90bxoXZ29vZ2xlL2FwaS9jbGllbnQucHJvdG8aH2dvb2dsZS9hcGkvZmll
bGRfYmVoYXZpb3IucHJvdG8aGWdvb2dsZS9hcGkvcmVzb3VyY2UucHJvdG8aHmdvb2dsZS9p
YW0vdjEvaWFtX3BvbGljeS5wcm90bxoaZ29vZ2xlL2lhbS92MS9wb2xpY3kucHJvdG8aI2dv
b2dsZS9sb25ncnVubmluZy9vcGVyYXRpb25zLnByb3RvGhtnb29nbGUvcHJvdG9idWYvZW1w
dHkucHJvdG8aH2dvb2dsZS9wcm90b2J1Zi90aW1lc3RhbXAucHJvdG8iYAoXRGVsZXRlQ29s
bGVjdGlvblJlcXVlc3QSRQoEbmFtZRgBIAEoCUIx4EEC+kErCilkaXNjb3ZlcnllbmdpbmUu
Z29vZ2xlYXBpcy5jb20vQ29sbGVjdGlvblIEbmFtZSKUAQoYRGVsZXRlQ29sbGVjdGlvbk1l
dGFkYXRhEjsKC2NyZWF0ZV90aW1lGAEgASgLMhouZ29vZ2xlLnByb3RvYnVmLlRpbWVzdGFt
cFIKY3JlYXRlVGltZRI7Cgt1cGRhdGVfdGltZRgCIAEoCzIaLmdvb2dsZS5wcm90b2J1Zi5U
aW1lc3RhbXBSCnVwZGF0ZVRpbWUytAYKEUNvbGxlY3Rpb25TZXJ2aWNlEoACChBEZWxldGVD
b2xsZWN0aW9uEjguZ29vZ2xlLmNsb3VkLmRpc2NvdmVyeWVuZ2luZS52MS5EZWxldGVDb2xs
ZWN0aW9uUmVxdWVzdBodLmdvb2dsZS5sb25ncnVubmluZy5PcGVyYXRpb24ikgGC0+STAjEq
Ly92MS97bmFtZT1wcm9qZWN0cy8qL2xvY2F0aW9ucy8qL2NvbGxlY3Rpb25zLyp92kEEbmFt
ZcpBUQoVZ29vZ2xlLnByb3RvYnVmLkVtcHR5Ejhnb29nbGUuY2xvdWQuZGlzY292ZXJ5ZW5n
aW5lLnYxLkRlbGV0ZUNvbGxlY3Rpb25NZXRhZGF0YRKeAQoMR2V0SWFtUG9saWN5EiIuZ29v
Z2xlLmlhbS52MS5HZXRJYW1Qb2xpY3lSZXF1ZXN0GhUuZ29vZ2xlLmlhbS52MS5Qb2xpY3ki
U4LT5JMCQhJAL3YxL3tyZXNvdXJjZT1wcm9qZWN0cy8qL2xvY2F0aW9ucy8qL2NvbGxlY3Rp
b25zLyp9OmdldElhbVBvbGljedpBCHJlc291cmNlEqgBCgxTZXRJYW1Qb2xpY3kSIi5nb29n
bGUuaWFtLnYxLlNldElhbVBvbGljeVJlcXVlc3QaFS5nb29nbGUuaWFtLnYxLlBvbGljeSJd
gtPkkwJFIkAvdjEve3Jlc291cmNlPXByb2plY3RzLyovbG9jYXRpb25zLyovY29sbGVjdGlv
bnMvKn06c2V0SWFtUG9saWN5OgEq2kEPcmVzb3VyY2UscG9saWN5Gs8BykEeZGlzY292ZXJ5
ZW5naW5lLmdvb2dsZWFwaXMuY29t0kGqAWh0dHBzOi8vd3d3Lmdvb2dsZWFwaXMuY29tL2F1
dGgvY2xvdWQtcGxhdGZvcm0saHR0cHM6Ly93d3cuZ29vZ2xlYXBpcy5jb20vYXV0aC9kaXNj
b3ZlcnllbmdpbmUucmVhZHdyaXRlLGh0dHBzOi8vd3d3Lmdvb2dsZWFwaXMuY29tL2F1dGgv
ZGlzY292ZXJ5ZW5naW5lLnNlcnZpbmcucmVhZHdyaXRlQokCCiNjb20uZ29vZ2xlLmNsb3Vk
LmRpc2NvdmVyeWVuZ2luZS52MUIWQ29sbGVjdGlvblNlcnZpY2VQcm90b1ABWk1jbG91ZC5n
b29nbGUuY29tL2dvL2Rpc2NvdmVyeWVuZ2luZS9hcGl2MS9kaXNjb3ZlcnllbmdpbmVwYjtk
aXNjb3ZlcnllbmdpbmVwYqICD0RJU0NPVkVSWUVOR0lORaoCH0dvb2dsZS5DbG91ZC5EaXNj
b3ZlcnlFbmdpbmUuVjHKAh9Hb29nbGVcQ2xvdWRcRGlzY292ZXJ5RW5naW5lXFYx6gIiR29v
Z2xlOjpDbG91ZDo6RGlzY292ZXJ5RW5naW5lOjpWMUrZGAoGEgQOAHYBCrwECgEMEgMOABIy
sQQgQ29weXJpZ2h0IDIwMjYgR29vZ2xlIExMQwoKIExpY2Vuc2VkIHVuZGVyIHRoZSBBcGFj
aGUgTGljZW5zZSwgVmVyc2lvbiAyLjAgKHRoZSAiTGljZW5zZSIpOwogeW91IG1heSBub3Qg
dXNlIHRoaXMgZmlsZSBleGNlcHQgaW4gY29tcGxpYW5jZSB3aXRoIHRoZSBMaWNlbnNlLgog
WW91IG1heSBvYnRhaW4gYSBjb3B5IG9mIHRoZSBMaWNlbnNlIGF0CgogICAgIGh0dHA6Ly93
d3cuYXBhY2hlLm9yZy9saWNlbnNlcy9MSUNFTlNFLTIuMAoKIFVubGVzcyByZXF1aXJlZCBi
eSBhcHBsaWNhYmxlIGxhdyBvciBhZ3JlZWQgdG8gaW4gd3JpdGluZywgc29mdHdhcmUKIGRp
c3RyaWJ1dGVkIHVuZGVyIHRoZSBMaWNlbnNlIGlzIGRpc3RyaWJ1dGVkIG9uIGFuICJBUyBJ
UyIgQkFTSVMsCiBXSVRIT1VUIFdBUlJBTlRJRVMgT1IgQ09ORElUSU9OUyBPRiBBTlkgS0lO
RCwgZWl0aGVyIGV4cHJlc3Mgb3IgaW1wbGllZC4KIFNlZSB0aGUgTGljZW5zZSBmb3IgdGhl
IHNwZWNpZmljIGxhbmd1YWdlIGdvdmVybmluZyBwZXJtaXNzaW9ucyBhbmQKIGxpbWl0YXRp
b25zIHVuZGVyIHRoZSBMaWNlbnNlLgoKCAoBAhIDEAAoCgkKAgMAEgMSACYKCQoCAwESAxMA
IQoJCgIDAhIDFAApCgkKAgMDEgMVACMKCQoCAwQSAxYAKAoJCgIDBRIDFwAkCgkKAgMGEgMY
AC0KCQoCAwcSAxkAJQoJCgIDCBIDGgApCggKAQgSAxwAPAoJCgIIJRIDHAA8CggKAQgSAx0A
ZAoJCgIICxIDHQBkCggKAQgSAx4AIgoJCgIIChIDHgAiCggKAQgSAx8ANwoJCgIICBIDHwA3
CggKAQgSAyAAPAoJCgIIARIDIAA8CggKAQgSAyEALQoJCgIIJBIDIQAtCggKAQgSAyIAPAoJ
CgIIKRIDIgA8CggKAQgSAyMAOwoJCgIILRIDIwA7Cl4KAgYAEgQnAFwBGlIgU2VydmljZSBm
b3IgbWFuYWdpbmcKIFtDb2xsZWN0aW9uXVtnb29nbGUuY2xvdWQuZGlzY292ZXJ5ZW5naW5l
LnYxLkNvbGxlY3Rpb25dcy4KCgoKAwYAARIDJwgZCgoKAwYAAxIDKAJGCgwKBQYAA5kIEgMo
AkYKCwoDBgADEgQpAixKCg0KBQYAA5oIEgQpAixKClMKBAYAAgASBC8COQMaRSBEZWxldGVz
IGEgW0NvbGxlY3Rpb25dW2dvb2dsZS5jbG91ZC5kaXNjb3ZlcnllbmdpbmUudjEuQ29sbGVj
dGlvbl0uCgoMCgUGAAIAARIDLwYWCgwKBQYAAgACEgMvFy4KDAoFBgACAAMSAzAPKwoNCgUG
AAIABBIEMQQzBgoRCgkGAAIABLDKvCISBDEEMwYKDAoFBgACAAQSAzQEMgoPCggGAAIABJsI
ABIDNAQyCg0KBQYAAgAEEgQ1BDgGCg8KBwYAAgAEmQgSBDUEOAYKjwIKBAYAAgESBD8CRQMa
gAIgR2V0cyB0aGUgSUFNIGFjY2VzcyBjb250cm9sIHBvbGljeSBmb3IgYQogW0NvbGxlY3Rp
b25dW2dvb2dsZS5jbG91ZC5kaXNjb3ZlcnllbmdpbmUudjEuQ29sbGVjdGlvbl0uIEEgYE5P
VF9GT1VORGAKIGVycm9yIGlzIHJldHVybmVkIGlmIHRoZSByZXNvdXJjZSBkb2VzIG5vdCBl
eGlzdC4gQW4gZW1wdHkgcG9saWN5IGlzCiByZXR1cm5lZCBpZiB0aGUgcmVzb3VyY2UgZXhp
c3RzIGJ1dCBkb2VzIG5vdCBoYXZlIGEgcG9saWN5IHNldCBvbiBpdC4KCgwKBQYAAgEBEgM/
BhIKDAoFBgACAQISAz8TNAoMCgUGAAIBAxIDQA8jCg0KBQYAAgEEEgRBBEMGChEKCQYAAgEE
sMq8IhIEQQRDBgoMCgUGAAIBBBIDRAQ2Cg8KCAYAAgEEmwgAEgNEBDYK0QQKBAYAAgISBFQC
WwMawgQgU2V0cyB0aGUgSUFNIGFjY2VzcyBjb250cm9sIHBvbGljeSBmb3IgYQogW0NvbGxl
Y3Rpb25dW2dvb2dsZS5jbG91ZC5kaXNjb3ZlcnllbmdpbmUudjEuQ29sbGVjdGlvbl0uIEEg
YE5PVF9GT1VORGAKIGVycm9yIGlzIHJldHVybmVkIGlmIHRoZSByZXNvdXJjZSBkb2VzIG5v
dCBleGlzdC4KCiAqKkltcG9ydGFudDoqKiBXaGVuIHNldHRpbmcgYSBwb2xpY3kgZGlyZWN0
bHkgb24gYSBDb2xsZWN0aW9uIHJlc291cmNlLAogdGhlIG9ubHkgcmVjb21tZW5kZWQgcm9s
ZXMgaW4gdGhlIGJpbmRpbmdzIGFyZToKIGByb2xlcy9kaXNjb3ZlcnllbmdpbmUuYWRtaW5g
CiBgcm9sZXMvZGlzY292ZXJ5ZW5naW5lLmFnZW50c3BhY2VBZG1pbmAKIGByb2xlcy9kaXNj
b3ZlcnllbmdpbmUudmlld2VyYAogYHJvbGVzL2Rpc2NvdmVyeWVuZ2luZS5hZ2VudHNwYWNl
Vmlld2VyYAogYHJvbGVzL2Rpc2NvdmVyeWVuZ2luZS51c2VyYAogYHJvbGVzL2Rpc2NvdmVy
eWVuZ2luZS5hZ2VudHNwYWNlVXNlcmAKIEF0dGVtcHRpbmcgdG8gZ3JhbnQgYW55IG90aGVy
IHJvbGUgd2lsbCByZXN1bHQgaW4gYSB3YXJuaW5nIGluIGxvZ2dpbmcuCgoMCgUGAAICARID
VAYSCgwKBQYAAgICEgNUEzQKDAoFBgACAgMSA1UPIwoNCgUGAAICBBIEVgRZBgoRCgkGAAIC
BLDKvCISBFYEWQYKDAoFBgACAgQSA1oEPQoPCggGAAICBJsIABIDWgQ9CpUBCgIEABIEYQBq
ARqIASBSZXF1ZXN0IG1lc3NhZ2UgZm9yCiBbQ29sbGVjdGlvblNlcnZpY2UuRGVsZXRlQ29s
bGVjdGlvbl1bZ29vZ2xlLmNsb3VkLmRpc2NvdmVyeWVuZ2luZS52MS5Db2xsZWN0aW9uU2Vy
dmljZS5EZWxldGVDb2xsZWN0aW9uXQogbWV0aG9kLgoKCgoDBAABEgNhCB8KmgEKBAQAAgAS
BGQCaQQaiwEgUmVxdWlyZWQuIFRoZSBmdWxsIHJlc291cmNlIG5hbWUgb2YgdGhlIENvbGxl
Y3Rpb24sIGluIHRoZSBmb3JtYXQgb2YKIGBwcm9qZWN0cy97cHJvamVjdH0vbG9jYXRpb25z
L3tsb2NhdGlvbn0vY29sbGVjdGlvbnMve2NvbGxlY3Rpb259YC4KCgwKBQQAAgAFEgNkAggK
DAoFBAACAAESA2QJDQoMCgUEAAIAAxIDZBARCg0KBQQAAgAIEgRkEmkDCg8KCAQAAgAInAgA
EgNlBCoKDwoHBAACAAifCBIEZgRoBQq0AQoCBAESBG8AdgEapwEgTWV0YWRhdGEgcmVsYXRl
ZCB0byB0aGUgcHJvZ3Jlc3Mgb2YgdGhlCiBbQ29sbGVjdGlvblNlcnZpY2UuVXBkYXRlQ29s
bGVjdGlvbl1bXSBvcGVyYXRpb24uIFRoaXMgd2lsbCBiZSByZXR1cm5lZCBieQogdGhlIGdv
b2dsZS5sb25ncnVubmluZy5PcGVyYXRpb24ubWV0YWRhdGEgZmllbGQuCgoKCgMEAQESA28I
IAolCgQEAQIAEgNxAiwaGCBPcGVyYXRpb24gY3JlYXRlIHRpbWUuCgoMCgUEAQIABhIDcQIb
CgwKBQQBAgABEgNxHCcKDAoFBAECAAMSA3EqKwpjCgQEAQIBEgN1AiwaViBPcGVyYXRpb24g
bGFzdCB1cGRhdGUgdGltZS4gSWYgdGhlIG9wZXJhdGlvbiBpcyBkb25lLCB0aGlzIGlzIGFs
c28gdGhlCiBmaW5pc2ggdGltZS4KCgwKBQQBAgEGEgN1AhsKDAoFBAECAQESA3UcJwoMCgUE
AQIBAxIDdSorYgZwcm90bzM=
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Discoveryengine::V1::CollectionService::DeleteCollectionRequest ===
    # Fields for DeleteCollectionRequest
    # Field: name Type: 9 ()

# === Message: Google::Cloud::Discoveryengine::V1::CollectionService::DeleteCollectionMetadata ===
    # Fields for DeleteCollectionMetadata
    # Field: create_time Type: 11 (.google.protobuf.Timestamp)
    # Field: update_time Type: 11 (.google.protobuf.Timestamp)

# === Service Client: Google::Cloud::Discoveryengine::V1::CollectionService::CollectionServiceClient ===
package Google::Cloud::Discoveryengine::V1::CollectionService::CollectionServiceClient;

=pod

=head2 Service Client: Google::Cloud::Discoveryengine::V1::CollectionService::CollectionServiceClient

Client stub representing the remote C<CollectionService> gRPC service. Delegates call dispatching to L<Google::gRPC::Client>.

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

sub delete_collection {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Discoveryengine::V1::CollectionService::DeleteCollectionRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.discoveryengine.v1.CollectionService',
        method         => 'DeleteCollection',
        request        => $req,
        response_class => 'Google::Longrunning::Operations::Operation',
    });
}

sub get_iam_policy {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Iam::V1::IamPolicy::GetIamPolicyRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.discoveryengine.v1.CollectionService',
        method         => 'GetIamPolicy',
        request        => $req,
        response_class => 'Google::Iam::V1::Policy::Policy',
    });
}

sub set_iam_policy {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Iam::V1::IamPolicy::SetIamPolicyRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.discoveryengine.v1.CollectionService',
        method         => 'SetIamPolicy',
        request        => $req,
        response_class => 'Google::Iam::V1::Policy::Policy',
    });
}

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Discoveryengine::V1::CollectionService - Compiled Protocol Buffers messages for google/cloud/discoveryengine/v1/collection_service.proto

=head1 SYNOPSIS

    use Google::Cloud::Discoveryengine::V1::CollectionService;

    my $msg = Google::Cloud::Discoveryengine::V1::CollectionService::DeleteCollectionRequest->new({
        name => $name,
    });

    # Read or update a field
    my $val = $msg->name();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Discoveryengine::V1::CollectionService::DeleteCollectionRequest->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/discoveryengine/v1/collection_service.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Discoveryengine::V1::CollectionService::DeleteCollectionRequest

Request message for
[CollectionService.DeleteCollection][google.cloud.discoveryengine.v1.CollectionService.DeleteCollection]
method.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. The full resource name of the Collection, in the format of
`projects/{project}/locations/{location}/collections/{collection}`.

=back

=head2 Google::Cloud::Discoveryengine::V1::CollectionService::DeleteCollectionMetadata

Metadata related to the progress of the
[CollectionService.UpdateCollection][] operation. This will be returned by
the google.longrunning.Operation.metadata field.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->create_time() >> / C<< $msg->create_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Operation create time.

=item * C<< $msg->update_time() >> / C<< $msg->update_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Operation last update time. If the operation is done, this is also the
finish time.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Discoveryengine::V1::CollectionService::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
