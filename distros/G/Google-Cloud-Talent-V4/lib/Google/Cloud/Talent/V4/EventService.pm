package Google::Cloud::Talent::V4::EventService;

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
    eval { require Google::Cloud::Talent::V4::Event };
    my $descriptor_b64 = <<'EOF';
Cipnb29nbGUvY2xvdWQvdGFsZW50L3Y0L2V2ZW50X3NlcnZpY2UucHJvdG8SFmdvb2dsZS5j
bG91ZC50YWxlbnQudjQaHGdvb2dsZS9hcGkvYW5ub3RhdGlvbnMucHJvdG8aF2dvb2dsZS9h
cGkvY2xpZW50LnByb3RvGh9nb29nbGUvYXBpL2ZpZWxkX2JlaGF2aW9yLnByb3RvGhlnb29n
bGUvYXBpL3Jlc291cmNlLnByb3RvGiJnb29nbGUvY2xvdWQvdGFsZW50L3Y0L2V2ZW50LnBy
b3RvIqMBChhDcmVhdGVDbGllbnRFdmVudFJlcXVlc3QSOgoGcGFyZW50GAEgASgJQiLgQQL6
QRwKGmpvYnMuZ29vZ2xlYXBpcy5jb20vVGVuYW50UgZwYXJlbnQSSwoMY2xpZW50X2V2ZW50
GAIgASgLMiMuZ29vZ2xlLmNsb3VkLnRhbGVudC52NC5DbGllbnRFdmVudEID4EECUgtjbGll
bnRFdmVudDLFAgoMRXZlbnRTZXJ2aWNlEsYBChFDcmVhdGVDbGllbnRFdmVudBIwLmdvb2ds
ZS5jbG91ZC50YWxlbnQudjQuQ3JlYXRlQ2xpZW50RXZlbnRSZXF1ZXN0GiMuZ29vZ2xlLmNs
b3VkLnRhbGVudC52NC5DbGllbnRFdmVudCJagtPkkwI+Ii4vdjQve3BhcmVudD1wcm9qZWN0
cy8qL3RlbmFudHMvKn0vY2xpZW50RXZlbnRzOgxjbGllbnRfZXZlbnTaQRNwYXJlbnQsY2xp
ZW50X2V2ZW50GmzKQRNqb2JzLmdvb2dsZWFwaXMuY29t0kFTaHR0cHM6Ly93d3cuZ29vZ2xl
YXBpcy5jb20vYXV0aC9jbG91ZC1wbGF0Zm9ybSxodHRwczovL3d3dy5nb29nbGVhcGlzLmNv
bS9hdXRoL2pvYnNCawoaY29tLmdvb2dsZS5jbG91ZC50YWxlbnQudjRCEUV2ZW50U2Vydmlj
ZVByb3RvUAFaMmNsb3VkLmdvb2dsZS5jb20vZ28vdGFsZW50L2FwaXY0L3RhbGVudHBiO3Rh
bGVudHBiogIDQ1RTSs0OCgYSBA4AQwEKvAQKAQwSAw4AEjKxBCBDb3B5cmlnaHQgMjAyNSBH
b29nbGUgTExDCgogTGljZW5zZWQgdW5kZXIgdGhlIEFwYWNoZSBMaWNlbnNlLCBWZXJzaW9u
IDIuMCAodGhlICJMaWNlbnNlIik7CiB5b3UgbWF5IG5vdCB1c2UgdGhpcyBmaWxlIGV4Y2Vw
dCBpbiBjb21wbGlhbmNlIHdpdGggdGhlIExpY2Vuc2UuCiBZb3UgbWF5IG9idGFpbiBhIGNv
cHkgb2YgdGhlIExpY2Vuc2UgYXQKCiAgICAgaHR0cDovL3d3dy5hcGFjaGUub3JnL2xpY2Vu
c2VzL0xJQ0VOU0UtMi4wCgogVW5sZXNzIHJlcXVpcmVkIGJ5IGFwcGxpY2FibGUgbGF3IG9y
IGFncmVlZCB0byBpbiB3cml0aW5nLCBzb2Z0d2FyZQogZGlzdHJpYnV0ZWQgdW5kZXIgdGhl
IExpY2Vuc2UgaXMgZGlzdHJpYnV0ZWQgb24gYW4gIkFTIElTIiBCQVNJUywKIFdJVEhPVVQg
V0FSUkFOVElFUyBPUiBDT05ESVRJT05TIE9GIEFOWSBLSU5ELCBlaXRoZXIgZXhwcmVzcyBv
ciBpbXBsaWVkLgogU2VlIHRoZSBMaWNlbnNlIGZvciB0aGUgc3BlY2lmaWMgbGFuZ3VhZ2Ug
Z292ZXJuaW5nIHBlcm1pc3Npb25zIGFuZAogbGltaXRhdGlvbnMgdW5kZXIgdGhlIExpY2Vu
c2UuCgoICgECEgMQAB8KCQoCAwASAxIAJgoJCgIDARIDEwAhCgkKAgMCEgMUACkKCQoCAwMS
AxUAIwoJCgIDBBIDFgAsCggKAQgSAxgASQoJCgIICxIDGABJCggKAQgSAxkAIgoJCgIIChID
GQAiCggKAQgSAxoAMgoJCgIICBIDGgAyCggKAQgSAxsAMwoJCgIIARIDGwAzCggKAQgSAxwA
IQoJCgIIJBIDHAAhCjQKAgYAEgQfADMBGiggQSBzZXJ2aWNlIGhhbmRsZXMgY2xpZW50IGV2
ZW50IHJlcG9ydC4KCgoKAwYAARIDHwgUCgoKAwYAAxIDIAI7CgwKBQYAA5kIEgMgAjsKCwoD
BgADEgQhAiMtCg0KBQYAA5oIEgQhAiMtCt4CCgQGAAIAEgQsAjIDGs8CIFJlcG9ydCBldmVu
dHMgaXNzdWVkIHdoZW4gZW5kIHVzZXIgaW50ZXJhY3RzIHdpdGggY3VzdG9tZXIncyBhcHBs
aWNhdGlvbgogdGhhdCB1c2VzIENsb3VkIFRhbGVudCBTb2x1dGlvbi4gWW91IG1heSBpbnNw
ZWN0IHRoZSBjcmVhdGVkIGV2ZW50cyBpbgogW3NlbGYgc2VydmljZQogdG9vbHNdKGh0dHBz
Oi8vY29uc29sZS5jbG91ZC5nb29nbGUuY29tL3RhbGVudC1zb2x1dGlvbi9vdmVydmlldyku
CiBbTGVhcm4KIG1vcmVdKGh0dHBzOi8vY2xvdWQuZ29vZ2xlLmNvbS90YWxlbnQtc29sdXRp
b24vZG9jcy9tYW5hZ2VtZW50LXRvb2xzKQogYWJvdXQgc2VsZiBzZXJ2aWNlIHRvb2xzLgoK
DAoFBgACAAESAywGFwoMCgUGAAIAAhIDLBgwCgwKBQYAAgADEgMsO0YKDQoFBgACAAQSBC0E
MAYKEQoJBgACAASwyrwiEgQtBDAGCgwKBQYAAgAEEgMxBEEKDwoIBgACAASbCAASAzEEQQon
CgIEABIENgBDARobIFRoZSByZXBvcnQgZXZlbnQgcmVxdWVzdC4KCgoKAwQAARIDNgggCr8B
CgQEAAIAEgQ7Aj4EGrABIFJlcXVpcmVkLiBSZXNvdXJjZSBuYW1lIG9mIHRoZSB0ZW5hbnQg
dW5kZXIgd2hpY2ggdGhlIGV2ZW50IGlzIGNyZWF0ZWQuCgogVGhlIGZvcm1hdCBpcyAicHJv
amVjdHMve3Byb2plY3RfaWR9L3RlbmFudHMve3RlbmFudF9pZH0iLCBmb3IgZXhhbXBsZSwK
ICJwcm9qZWN0cy9mb28vdGVuYW50cy9iYXIiLgoKDAoFBAACAAUSAzsCCAoMCgUEAAIAARID
OwkPCgwKBQQAAgADEgM7EhMKDQoFBAACAAgSBDsUPgMKDwoIBAACAAicCAASAzwEKgoOCgcE
AAIACJ8IEgM9BEwKfAoEBAACARIDQgJIGm8gUmVxdWlyZWQuIEV2ZW50cyBpc3N1ZWQgd2hl
biBlbmQgdXNlciBpbnRlcmFjdHMgd2l0aCBjdXN0b21lcidzIGFwcGxpY2F0aW9uCiB0aGF0
IHVzZXMgQ2xvdWQgVGFsZW50IFNvbHV0aW9uLgoKDAoFBAACAQYSA0ICDQoMCgUEAAIBARID
Qg4aCgwKBQQAAgEDEgNCHR4KDAoFBAACAQgSA0IfRwoPCggEAAIBCJwIABIDQiBGYgZwcm90
bzM=
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Talent::V4::EventService::CreateClientEventRequest ===
    # Fields for CreateClientEventRequest
    # Field: parent Type: 9 ()
    # Field: client_event Type: 11 (.google.cloud.talent.v4.ClientEvent)

# === Service Client: Google::Cloud::Talent::V4::EventService::EventServiceClient ===
package Google::Cloud::Talent::V4::EventService::EventServiceClient;

=pod

=head2 Service Client: Google::Cloud::Talent::V4::EventService::EventServiceClient

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
        ? Google::Cloud::Talent::V4::EventService::CreateClientEventRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.talent.v4.EventService',
        method         => 'CreateClientEvent',
        request        => $req,
        response_class => 'Google::Cloud::Talent::V4::Event::ClientEvent',
    });
}

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Talent::V4::EventService - Compiled Protocol Buffers messages for google/cloud/talent/v4/event_service.proto

=head1 SYNOPSIS

    use Google::Cloud::Talent::V4::EventService;

    my $msg = Google::Cloud::Talent::V4::EventService::CreateClientEventRequest->new({
        parent => $parent,
        client_event => $client_event,
    });

    # Read or update a field
    my $val = $msg->parent();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Talent::V4::EventService::CreateClientEventRequest->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/talent/v4/event_service.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Talent::V4::EventService::CreateClientEventRequest

The report event request.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->parent() >> / C<< $msg->parent($value) >>

Type: C<String>

Required. Resource name of the tenant under which the event is created.

The format is "projects/{project_id}/tenants/{tenant_id}", for example,
"projects/foo/tenants/bar".

=item * C<< $msg->client_event() >> / C<< $msg->client_event($value) >>

Type: C<Message> (L<Google::Cloud::Talent::V4::Event::ClientEvent>)

Required. Events issued when end user interacts with customer's application
that uses Cloud Talent Solution.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Talent::V4::EventService::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
