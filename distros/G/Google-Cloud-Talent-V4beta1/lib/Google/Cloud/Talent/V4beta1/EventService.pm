package Google::Cloud::Talent::V4beta1::EventService;

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
    eval { require Google::Cloud::Talent::V4beta1::Event };
    my $descriptor_b64 = <<'EOF';
Ci9nb29nbGUvY2xvdWQvdGFsZW50L3Y0YmV0YTEvZXZlbnRfc2VydmljZS5wcm90bxIbZ29v
Z2xlLmNsb3VkLnRhbGVudC52NGJldGExGhxnb29nbGUvYXBpL2Fubm90YXRpb25zLnByb3Rv
Ghdnb29nbGUvYXBpL2NsaWVudC5wcm90bxofZ29vZ2xlL2FwaS9maWVsZF9iZWhhdmlvci5w
cm90bxoZZ29vZ2xlL2FwaS9yZXNvdXJjZS5wcm90bxonZ29vZ2xlL2Nsb3VkL3RhbGVudC92
NGJldGExL2V2ZW50LnByb3RvIqkBChhDcmVhdGVDbGllbnRFdmVudFJlcXVlc3QSOwoGcGFy
ZW50GAEgASgJQiPgQQL6QR0SG2pvYnMuZ29vZ2xlYXBpcy5jb20vQ29tcGFueVIGcGFyZW50
ElAKDGNsaWVudF9ldmVudBgCIAEoCzIoLmdvb2dsZS5jbG91ZC50YWxlbnQudjRiZXRhMS5D
bGllbnRFdmVudEID4EECUgtjbGllbnRFdmVudDL6AgoMRXZlbnRTZXJ2aWNlEvsBChFDcmVh
dGVDbGllbnRFdmVudBI1Lmdvb2dsZS5jbG91ZC50YWxlbnQudjRiZXRhMS5DcmVhdGVDbGll
bnRFdmVudFJlcXVlc3QaKC5nb29nbGUuY2xvdWQudGFsZW50LnY0YmV0YTEuQ2xpZW50RXZl
bnQihAGC0+STAmgiMy92NGJldGExL3twYXJlbnQ9cHJvamVjdHMvKi90ZW5hbnRzLyp9L2Ns
aWVudEV2ZW50czoBKlouIikvdjRiZXRhMS97cGFyZW50PXByb2plY3RzLyp9L2NsaWVudEV2
ZW50czoBKtpBE3BhcmVudCxjbGllbnRfZXZlbnQabMpBE2pvYnMuZ29vZ2xlYXBpcy5jb23S
QVNodHRwczovL3d3dy5nb29nbGVhcGlzLmNvbS9hdXRoL2Nsb3VkLXBsYXRmb3JtLGh0dHBz
Oi8vd3d3Lmdvb2dsZWFwaXMuY29tL2F1dGgvam9ic0J1Ch9jb20uZ29vZ2xlLmNsb3VkLnRh
bGVudC52NGJldGExQhFFdmVudFNlcnZpY2VQcm90b1ABWjdjbG91ZC5nb29nbGUuY29tL2dv
L3RhbGVudC9hcGl2NGJldGExL3RhbGVudHBiO3RhbGVudHBiogIDQ1RTSqUPCgYSBA4ASgEK
vAQKAQwSAw4AEjKxBCBDb3B5cmlnaHQgMjAyNSBHb29nbGUgTExDCgogTGljZW5zZWQgdW5k
ZXIgdGhlIEFwYWNoZSBMaWNlbnNlLCBWZXJzaW9uIDIuMCAodGhlICJMaWNlbnNlIik7CiB5
b3UgbWF5IG5vdCB1c2UgdGhpcyBmaWxlIGV4Y2VwdCBpbiBjb21wbGlhbmNlIHdpdGggdGhl
IExpY2Vuc2UuCiBZb3UgbWF5IG9idGFpbiBhIGNvcHkgb2YgdGhlIExpY2Vuc2UgYXQKCiAg
ICAgaHR0cDovL3d3dy5hcGFjaGUub3JnL2xpY2Vuc2VzL0xJQ0VOU0UtMi4wCgogVW5sZXNz
IHJlcXVpcmVkIGJ5IGFwcGxpY2FibGUgbGF3IG9yIGFncmVlZCB0byBpbiB3cml0aW5nLCBz
b2Z0d2FyZQogZGlzdHJpYnV0ZWQgdW5kZXIgdGhlIExpY2Vuc2UgaXMgZGlzdHJpYnV0ZWQg
b24gYW4gIkFTIElTIiBCQVNJUywKIFdJVEhPVVQgV0FSUkFOVElFUyBPUiBDT05ESVRJT05T
IE9GIEFOWSBLSU5ELCBlaXRoZXIgZXhwcmVzcyBvciBpbXBsaWVkLgogU2VlIHRoZSBMaWNl
bnNlIGZvciB0aGUgc3BlY2lmaWMgbGFuZ3VhZ2UgZ292ZXJuaW5nIHBlcm1pc3Npb25zIGFu
ZAogbGltaXRhdGlvbnMgdW5kZXIgdGhlIExpY2Vuc2UuCgoICgECEgMQACQKCQoCAwASAxIA
JgoJCgIDARIDEwAhCgkKAgMCEgMUACkKCQoCAwMSAxUAIwoJCgIDBBIDFgAxCggKAQgSAxgA
TgoJCgIICxIDGABOCggKAQgSAxkAIgoJCgIIChIDGQAiCggKAQgSAxoAMgoJCgIICBIDGgAy
CggKAQgSAxsAOAoJCgIIARIDGwA4CggKAQgSAxwAIQoJCgIIJBIDHAAhCjQKAgYAEgQfADcB
GiggQSBzZXJ2aWNlIGhhbmRsZXMgY2xpZW50IGV2ZW50IHJlcG9ydC4KCgoKAwYAARIDHwgU
CgoKAwYAAxIDIAI7CgwKBQYAA5kIEgMgAjsKCwoDBgADEgQhAiMtCg0KBQYAA5oIEgQhAiMt
Ct4CCgQGAAIAEgQsAjYDGs8CIFJlcG9ydCBldmVudHMgaXNzdWVkIHdoZW4gZW5kIHVzZXIg
aW50ZXJhY3RzIHdpdGggY3VzdG9tZXIncyBhcHBsaWNhdGlvbgogdGhhdCB1c2VzIENsb3Vk
IFRhbGVudCBTb2x1dGlvbi4gWW91IG1heSBpbnNwZWN0IHRoZSBjcmVhdGVkIGV2ZW50cyBp
bgogW3NlbGYgc2VydmljZQogdG9vbHNdKGh0dHBzOi8vY29uc29sZS5jbG91ZC5nb29nbGUu
Y29tL3RhbGVudC1zb2x1dGlvbi9vdmVydmlldykuCiBbTGVhcm4KIG1vcmVdKGh0dHBzOi8v
Y2xvdWQuZ29vZ2xlLmNvbS90YWxlbnQtc29sdXRpb24vZG9jcy9tYW5hZ2VtZW50LXRvb2xz
KQogYWJvdXQgc2VsZiBzZXJ2aWNlIHRvb2xzLgoKDAoFBgACAAESAywGFwoMCgUGAAIAAhID
LBgwCgwKBQYAAgADEgMsO0YKDQoFBgACAAQSBC0ENAYKEQoJBgACAASwyrwiEgQtBDQGCgwK
BQYAAgAEEgM1BEEKDwoIBgACAASbCAASAzUEQQonCgIEABIEOgBKARobIFRoZSByZXBvcnQg
ZXZlbnQgcmVxdWVzdC4KCgoKAwQAARIDOgggCpYCCgQEAAIAEgRAAkUEGocCIFJlcXVpcmVk
LiBSZXNvdXJjZSBuYW1lIG9mIHRoZSB0ZW5hbnQgdW5kZXIgd2hpY2ggdGhlIGV2ZW50IGlz
IGNyZWF0ZWQuCgogVGhlIGZvcm1hdCBpcyAicHJvamVjdHMve3Byb2plY3RfaWR9L3RlbmFu
dHMve3RlbmFudF9pZH0iLCBmb3IgZXhhbXBsZSwKICJwcm9qZWN0cy9mb28vdGVuYW50L2Jh
ciIuIElmIHRlbmFudCBpZCBpcyB1bnNwZWNpZmllZCwgYSBkZWZhdWx0IHRlbmFudAogaXMg
Y3JlYXRlZCwgZm9yIGV4YW1wbGUsICJwcm9qZWN0cy9mb28iLgoKDAoFBAACAAUSA0ACCAoM
CgUEAAIAARIDQAkPCgwKBQQAAgADEgNAEhMKDQoFBAACAAgSBEAURQMKDwoIBAACAAicCAAS
A0EEKgoPCgcEAAIACJ8IEgRCBEQFCnwKBAQAAgESA0kCSBpvIFJlcXVpcmVkLiBFdmVudHMg
aXNzdWVkIHdoZW4gZW5kIHVzZXIgaW50ZXJhY3RzIHdpdGggY3VzdG9tZXIncyBhcHBsaWNh
dGlvbgogdGhhdCB1c2VzIENsb3VkIFRhbGVudCBTb2x1dGlvbi4KCgwKBQQAAgEGEgNJAg0K
DAoFBAACAQESA0kOGgoMCgUEAAIBAxIDSR0eCgwKBQQAAgEIEgNJH0cKDwoIBAACAQicCAAS
A0kgRmIGcHJvdG8z
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Talent::V4beta1::EventService::CreateClientEventRequest ===
    # Fields for CreateClientEventRequest
    # Field: parent Type: 9 ()
    # Field: client_event Type: 11 (.google.cloud.talent.v4beta1.ClientEvent)

# === Service Client: Google::Cloud::Talent::V4beta1::EventService::EventServiceClient ===
package Google::Cloud::Talent::V4beta1::EventService::EventServiceClient;

=pod

=head2 Service Client: Google::Cloud::Talent::V4beta1::EventService::EventServiceClient

Client stub representing the remote C<EventService> gRPC service. Delegates call dispatching to L<Google::gRPC::Client>.

=head3 target

The endpoint target address. Defaults to C<talent.googleapis.com:443>.

=head3 credentials

The authentication credentials provider. Defaults to application default credentials via L<Google::Auth>.

=cut

use Moo;
use Google::Auth;
use Google::gRPC::Client;

has credentials => ( is => 'ro', default => sub { Google::Auth->default() } );
has target      => ( is => 'ro', default => 'talent.googleapis.com:443' );

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

sub create_client_event {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Talent::V4beta1::EventService::CreateClientEventRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.talent.v4beta1.EventService',
        method         => 'CreateClientEvent',
        request        => $req,
        response_class => 'Google::Cloud::Talent::V4beta1::Event::ClientEvent',
    });
}

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Talent::V4beta1::EventService - Compiled Protocol Buffers messages for google/cloud/talent/v4beta1/event_service.proto

=head1 SYNOPSIS

    use Google::Cloud::Talent::V4beta1::EventService;

    my $msg = Google::Cloud::Talent::V4beta1::EventService::CreateClientEventRequest->new({
        parent => $parent,
        client_event => $client_event,
    });

    # Read or update a field
    my $val = $msg->parent();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Talent::V4beta1::EventService::CreateClientEventRequest->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/talent/v4beta1/event_service.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Talent::V4beta1::EventService::CreateClientEventRequest

The report event request.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->parent() >> / C<< $msg->parent($value) >>

Type: C<String>

Required. Resource name of the tenant under which the event is created.

The format is "projects/{project_id}/tenants/{tenant_id}", for example,
"projects/foo/tenant/bar". If tenant id is unspecified, a default tenant
is created, for example, "projects/foo".

=item * C<< $msg->client_event() >> / C<< $msg->client_event($value) >>

Type: C<Message> (L<Google::Cloud::Talent::V4beta1::Event::ClientEvent>)

Required. Events issued when end user interacts with customer's application
that uses Cloud Talent Solution.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Talent::V4beta1::EventService::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
