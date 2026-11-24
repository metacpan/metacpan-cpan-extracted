package Google::Cloud::Servicehealth::V1::EventService;

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
    eval { require Google::Cloud::Servicehealth::V1::EventResources };
    my $descriptor_b64 = <<'EOF';
CjFnb29nbGUvY2xvdWQvc2VydmljZWhlYWx0aC92MS9ldmVudF9zZXJ2aWNlLnByb3RvEh1n
b29nbGUuY2xvdWQuc2VydmljZWhlYWx0aC52MRocZ29vZ2xlL2FwaS9hbm5vdGF0aW9ucy5w
cm90bxoXZ29vZ2xlL2FwaS9jbGllbnQucHJvdG8aM2dvb2dsZS9jbG91ZC9zZXJ2aWNlaGVh
bHRoL3YxL2V2ZW50X3Jlc291cmNlcy5wcm90bzKqCgoNU2VydmljZUhlYWx0aBKuAQoKTGlz
dEV2ZW50cxIwLmdvb2dsZS5jbG91ZC5zZXJ2aWNlaGVhbHRoLnYxLkxpc3RFdmVudHNSZXF1
ZXN0GjEuZ29vZ2xlLmNsb3VkLnNlcnZpY2VoZWFsdGgudjEuTGlzdEV2ZW50c1Jlc3BvbnNl
IjuC0+STAiwSKi92MS97cGFyZW50PXByb2plY3RzLyovbG9jYXRpb25zLyp9L2V2ZW50c9pB
BnBhcmVudBKbAQoIR2V0RXZlbnQSLi5nb29nbGUuY2xvdWQuc2VydmljZWhlYWx0aC52MS5H
ZXRFdmVudFJlcXVlc3QaJC5nb29nbGUuY2xvdWQuc2VydmljZWhlYWx0aC52MS5FdmVudCI5
gtPkkwIsEiovdjEve25hbWU9cHJvamVjdHMvKi9sb2NhdGlvbnMvKi9ldmVudHMvKn3aQQRu
YW1lEuMBChZMaXN0T3JnYW5pemF0aW9uRXZlbnRzEjwuZ29vZ2xlLmNsb3VkLnNlcnZpY2Vo
ZWFsdGgudjEuTGlzdE9yZ2FuaXphdGlvbkV2ZW50c1JlcXVlc3QaPS5nb29nbGUuY2xvdWQu
c2VydmljZWhlYWx0aC52MS5MaXN0T3JnYW5pemF0aW9uRXZlbnRzUmVzcG9uc2UiTILT5JMC
PRI7L3YxL3twYXJlbnQ9b3JnYW5pemF0aW9ucy8qL2xvY2F0aW9ucy8qfS9vcmdhbml6YXRp
b25FdmVudHPaQQZwYXJlbnQS0AEKFEdldE9yZ2FuaXphdGlvbkV2ZW50EjouZ29vZ2xlLmNs
b3VkLnNlcnZpY2VoZWFsdGgudjEuR2V0T3JnYW5pemF0aW9uRXZlbnRSZXF1ZXN0GjAuZ29v
Z2xlLmNsb3VkLnNlcnZpY2VoZWFsdGgudjEuT3JnYW5pemF0aW9uRXZlbnQiSoLT5JMCPRI7
L3YxL3tuYW1lPW9yZ2FuaXphdGlvbnMvKi9sb2NhdGlvbnMvKi9vcmdhbml6YXRpb25FdmVu
dHMvKn3aQQRuYW1lEucBChdMaXN0T3JnYW5pemF0aW9uSW1wYWN0cxI9Lmdvb2dsZS5jbG91
ZC5zZXJ2aWNlaGVhbHRoLnYxLkxpc3RPcmdhbml6YXRpb25JbXBhY3RzUmVxdWVzdBo+Lmdv
b2dsZS5jbG91ZC5zZXJ2aWNlaGVhbHRoLnYxLkxpc3RPcmdhbml6YXRpb25JbXBhY3RzUmVz
cG9uc2UiTYLT5JMCPhI8L3YxL3twYXJlbnQ9b3JnYW5pemF0aW9ucy8qL2xvY2F0aW9ucy8q
fS9vcmdhbml6YXRpb25JbXBhY3Rz2kEGcGFyZW50EtQBChVHZXRPcmdhbml6YXRpb25JbXBh
Y3QSOy5nb29nbGUuY2xvdWQuc2VydmljZWhlYWx0aC52MS5HZXRPcmdhbml6YXRpb25JbXBh
Y3RSZXF1ZXN0GjEuZ29vZ2xlLmNsb3VkLnNlcnZpY2VoZWFsdGgudjEuT3JnYW5pemF0aW9u
SW1wYWN0IkuC0+STAj4SPC92MS97bmFtZT1vcmdhbml6YXRpb25zLyovbG9jYXRpb25zLyov
b3JnYW5pemF0aW9uSW1wYWN0cy8qfdpBBG5hbWUaUMpBHHNlcnZpY2VoZWFsdGguZ29vZ2xl
YXBpcy5jb23SQS5odHRwczovL3d3dy5nb29nbGVhcGlzLmNvbS9hdXRoL2Nsb3VkLXBsYXRm
b3JtQuQBCiFjb20uZ29vZ2xlLmNsb3VkLnNlcnZpY2VoZWFsdGgudjFCEUV2ZW50U2Vydmlj
ZVByb3RvUAFaR2Nsb3VkLmdvb2dsZS5jb20vZ28vc2VydmljZWhlYWx0aC9hcGl2MS9zZXJ2
aWNlaGVhbHRocGI7c2VydmljZWhlYWx0aHBiqgIdR29vZ2xlLkNsb3VkLlNlcnZpY2VIZWFs
dGguVjHKAh1Hb29nbGVcQ2xvdWRcU2VydmljZUhlYWx0aFxWMeoCIEdvb2dsZTo6Q2xvdWQ6
OlNlcnZpY2VIZWFsdGg6OlYxSuQQCgYSBA4AWgEKvAQKAQwSAw4AEjKxBCBDb3B5cmlnaHQg
MjAyNSBHb29nbGUgTExDCgogTGljZW5zZWQgdW5kZXIgdGhlIEFwYWNoZSBMaWNlbnNlLCBW
ZXJzaW9uIDIuMCAodGhlICJMaWNlbnNlIik7CiB5b3UgbWF5IG5vdCB1c2UgdGhpcyBmaWxl
IGV4Y2VwdCBpbiBjb21wbGlhbmNlIHdpdGggdGhlIExpY2Vuc2UuCiBZb3UgbWF5IG9idGFp
biBhIGNvcHkgb2YgdGhlIExpY2Vuc2UgYXQKCiAgICAgaHR0cDovL3d3dy5hcGFjaGUub3Jn
L2xpY2Vuc2VzL0xJQ0VOU0UtMi4wCgogVW5sZXNzIHJlcXVpcmVkIGJ5IGFwcGxpY2FibGUg
bGF3IG9yIGFncmVlZCB0byBpbiB3cml0aW5nLCBzb2Z0d2FyZQogZGlzdHJpYnV0ZWQgdW5k
ZXIgdGhlIExpY2Vuc2UgaXMgZGlzdHJpYnV0ZWQgb24gYW4gIkFTIElTIiBCQVNJUywKIFdJ
VEhPVVQgV0FSUkFOVElFUyBPUiBDT05ESVRJT05TIE9GIEFOWSBLSU5ELCBlaXRoZXIgZXhw
cmVzcyBvciBpbXBsaWVkLgogU2VlIHRoZSBMaWNlbnNlIGZvciB0aGUgc3BlY2lmaWMgbGFu
Z3VhZ2UgZ292ZXJuaW5nIHBlcm1pc3Npb25zIGFuZAogbGltaXRhdGlvbnMgdW5kZXIgdGhl
IExpY2Vuc2UuCgoICgECEgMQACYKCQoCAwASAxIAJgoJCgIDARIDEwAhCgkKAgMCEgMUAD0K
CAoBCBIDFgA6CgkKAgglEgMWADoKCAoBCBIDFwBeCgkKAggLEgMXAF4KCAoBCBIDGAAiCgkK
AggKEgMYACIKCAoBCBIDGQAyCgkKAggIEgMZADIKCAoBCBIDGgA6CgkKAggBEgMaADoKCAoB
CBIDGwA6CgkKAggpEgMbADoKCAoBCBIDHAA5CgkKAggtEgMcADkKUgoCBgASBB8AWgEaRiBS
ZXF1ZXN0IHNlcnZpY2UgaGVhbHRoIGV2ZW50cyByZWxldmFudCB0byB5b3VyIEdvb2dsZSBD
bG91ZCBwcm9qZWN0LgoKCgoDBgABEgMfCBUKCgoDBgADEgMgAkQKDAoFBgADmQgSAyACRAoL
CgMGAAMSBCECIjcKDQoFBgADmggSBCECIjcKQAoEBgACABIEJQIqAxoyIExpc3RzIGV2ZW50
cyB1bmRlciBhIGdpdmVuIHByb2plY3QgYW5kIGxvY2F0aW9uLgoKDAoFBgACAAESAyUGEAoM
CgUGAAIAAhIDJREiCgwKBQYAAgADEgMlLT8KDQoFBgACAAQSBCYEKAYKEQoJBgACAASwyrwi
EgQmBCgGCgwKBQYAAgAEEgMpBDQKDwoIBgACAASbCAASAykENApLCgQGAAIBEgQtAjIDGj0g
UmV0cmlldmVzIGEgcmVzb3VyY2UgY29udGFpbmluZyBpbmZvcm1hdGlvbiBhYm91dCBhbiBl
dmVudC4KCgwKBQYAAgEBEgMtBg4KDAoFBgACAQISAy0PHgoMCgUGAAIBAxIDLSkuCg0KBQYA
AgEEEgQuBDAGChEKCQYAAgEEsMq8IhIELgQwBgoMCgUGAAIBBBIDMQQyCg8KCAYAAgEEmwgA
EgMxBDIKUgoEBgACAhIENQI7AxpEIExpc3RzIG9yZ2FuaXphdGlvbiBldmVudHMgdW5kZXIg
YSBnaXZlbiBvcmdhbml6YXRpb24gYW5kIGxvY2F0aW9uLgoKDAoFBgACAgESAzUGHAoMCgUG
AAICAhIDNR06CgwKBQYAAgIDEgM2Dy0KDQoFBgACAgQSBDcEOQYKEQoJBgACAgSwyrwiEgQ3
BDkGCgwKBQYAAgIEEgM6BDQKDwoIBgACAgSbCAASAzoENApnCgQGAAIDEgQ/AkUDGlkgUmV0
cmlldmVzIGEgcmVzb3VyY2UgY29udGFpbmluZyBpbmZvcm1hdGlvbiBhYm91dCBhbiBldmVu
dCBhZmZlY3RpbmcgYW4KIG9yZ2FuaXphdGlvbiAuCgoMCgUGAAIDARIDPwYaCgwKBQYAAgMC
EgM/GzYKDAoFBgACAwMSA0APIAoNCgUGAAIDBBIEQQRDBgoRCgkGAAIDBLDKvCISBEEEQwYK
DAoFBgACAwQSA0QEMgoPCggGAAIDBJsIABIDRAQyCmYKBAYAAgQSBEkCTwMaWCBMaXN0cyBh
c3NldHMgaW1wYWN0ZWQgYnkgb3JnYW5pemF0aW9uIGV2ZW50cyB1bmRlciBhIGdpdmVuIG9y
Z2FuaXphdGlvbiBhbmQKIGxvY2F0aW9uLgoKDAoFBgACBAESA0kGHQoMCgUGAAIEAhIDSR48
CgwKBQYAAgQDEgNKDy4KDQoFBgACBAQSBEsETQYKEQoJBgACBASwyrwiEgRLBE0GCgwKBQYA
AgQEEgNOBDQKDwoIBgACBASbCAASA04ENAqQAQoEBgACBRIEUwJZAxqBASBSZXRyaWV2ZXMg
YSByZXNvdXJjZSBjb250YWluaW5nIGluZm9ybWF0aW9uIGFib3V0IGltcGFjdCB0byBhbiBh
c3NldCB1bmRlcgogYW4gb3JnYW5pemF0aW9uIGFmZmVjdGVkIGJ5IGEgc2VydmljZSBoZWFs
dGggZXZlbnQuCgoMCgUGAAIFARIDUwYbCgwKBQYAAgUCEgNTHDgKDAoFBgACBQMSA1QPIQoN
CgUGAAIFBBIEVQRXBgoRCgkGAAIFBLDKvCISBFUEVwYKDAoFBgACBQQSA1gEMgoPCggGAAIF
BJsIABIDWAQyYgZwcm90bzM=
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Service Client: Google::Cloud::Servicehealth::V1::EventService::ServiceHealthClient ===
package Google::Cloud::Servicehealth::V1::EventService::ServiceHealthClient;

=pod

=head2 Service Client: Google::Cloud::Servicehealth::V1::EventService::ServiceHealthClient

Client stub representing the remote C<ServiceHealth> gRPC service. Delegates call dispatching to L<Google::gRPC::Client>.

=head3 target

The endpoint target address. Defaults to C<servicehealth.googleapis.com:443>.

=head3 credentials

The authentication credentials provider. Defaults to application default credentials via L<Google::Auth>.

=cut

use Moo;
use Google::Auth;
use Google::gRPC::Client;

has credentials => ( is => 'ro', default => sub { Google::Auth->default() } );
has target      => ( is => 'ro', default => 'servicehealth.googleapis.com:443' );

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

sub list_events {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Servicehealth::V1::EventResources::ListEventsRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.servicehealth.v1.ServiceHealth',
        method         => 'ListEvents',
        request        => $req,
        response_class => 'Google::Cloud::Servicehealth::V1::EventResources::ListEventsResponse',
    });
}

sub get_event {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Servicehealth::V1::EventResources::GetEventRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.servicehealth.v1.ServiceHealth',
        method         => 'GetEvent',
        request        => $req,
        response_class => 'Google::Cloud::Servicehealth::V1::EventResources::Event',
    });
}

sub list_organization_events {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Servicehealth::V1::EventResources::ListOrganizationEventsRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.servicehealth.v1.ServiceHealth',
        method         => 'ListOrganizationEvents',
        request        => $req,
        response_class => 'Google::Cloud::Servicehealth::V1::EventResources::ListOrganizationEventsResponse',
    });
}

sub get_organization_event {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Servicehealth::V1::EventResources::GetOrganizationEventRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.servicehealth.v1.ServiceHealth',
        method         => 'GetOrganizationEvent',
        request        => $req,
        response_class => 'Google::Cloud::Servicehealth::V1::EventResources::OrganizationEvent',
    });
}

sub list_organization_impacts {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Servicehealth::V1::EventResources::ListOrganizationImpactsRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.servicehealth.v1.ServiceHealth',
        method         => 'ListOrganizationImpacts',
        request        => $req,
        response_class => 'Google::Cloud::Servicehealth::V1::EventResources::ListOrganizationImpactsResponse',
    });
}

sub get_organization_impact {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Servicehealth::V1::EventResources::GetOrganizationImpactRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.servicehealth.v1.ServiceHealth',
        method         => 'GetOrganizationImpact',
        request        => $req,
        response_class => 'Google::Cloud::Servicehealth::V1::EventResources::OrganizationImpact',
    });
}

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Servicehealth::V1::EventService - Compiled Protocol Buffers messages for google/cloud/servicehealth/v1/event_service.proto

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/servicehealth/v1/event_service.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Servicehealth::V1::EventService::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
