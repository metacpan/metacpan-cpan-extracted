package Google::Cloud::Retail::V2beta::ProjectService;

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
    eval { require Google::Cloud::Retail::V2beta::Project };
    eval { require Google::Protobuf::FieldMask };
    my $descriptor_b64 = <<'EOF';
CjBnb29nbGUvY2xvdWQvcmV0YWlsL3YyYmV0YS9wcm9qZWN0X3NlcnZpY2UucHJvdG8SGmdv
b2dsZS5jbG91ZC5yZXRhaWwudjJiZXRhGhxnb29nbGUvYXBpL2Fubm90YXRpb25zLnByb3Rv
Ghdnb29nbGUvYXBpL2NsaWVudC5wcm90bxofZ29vZ2xlL2FwaS9maWVsZF9iZWhhdmlvci5w
cm90bxoZZ29vZ2xlL2FwaS9yZXNvdXJjZS5wcm90bxooZ29vZ2xlL2Nsb3VkL3JldGFpbC92
MmJldGEvcHJvamVjdC5wcm90bxogZ29vZ2xlL3Byb3RvYnVmL2ZpZWxkX21hc2sucHJvdG8i
VgoVR2V0QWxlcnRDb25maWdSZXF1ZXN0Ej0KBG5hbWUYASABKAlCKeBBAvpBIwohcmV0YWls
Lmdvb2dsZWFwaXMuY29tL0FsZXJ0Q29uZmlnUgRuYW1lIqgBChhVcGRhdGVBbGVydENvbmZp
Z1JlcXVlc3QSTwoMYWxlcnRfY29uZmlnGAEgASgLMicuZ29vZ2xlLmNsb3VkLnJldGFpbC52
MmJldGEuQWxlcnRDb25maWdCA+BBAlILYWxlcnRDb25maWcSOwoLdXBkYXRlX21hc2sYAiAB
KAsyGi5nb29nbGUucHJvdG9idWYuRmllbGRNYXNrUgp1cGRhdGVNYXNrMtoDCg5Qcm9qZWN0
U2VydmljZRKiAQoOR2V0QWxlcnRDb25maWcSMS5nb29nbGUuY2xvdWQucmV0YWlsLnYyYmV0
YS5HZXRBbGVydENvbmZpZ1JlcXVlc3QaJy5nb29nbGUuY2xvdWQucmV0YWlsLnYyYmV0YS5B
bGVydENvbmZpZyI0gtPkkwInEiUvdjJiZXRhL3tuYW1lPXByb2plY3RzLyovYWxlcnRDb25m
aWd92kEEbmFtZRLXAQoRVXBkYXRlQWxlcnRDb25maWcSNC5nb29nbGUuY2xvdWQucmV0YWls
LnYyYmV0YS5VcGRhdGVBbGVydENvbmZpZ1JlcXVlc3QaJy5nb29nbGUuY2xvdWQucmV0YWls
LnYyYmV0YS5BbGVydENvbmZpZyJjgtPkkwJCMjIvdjJiZXRhL3thbGVydF9jb25maWcubmFt
ZT1wcm9qZWN0cy8qL2FsZXJ0Q29uZmlnfToMYWxlcnRfY29uZmln2kEYYWxlcnRfY29uZmln
LHVwZGF0ZV9tYXNrGknKQRVyZXRhaWwuZ29vZ2xlYXBpcy5jb23SQS5odHRwczovL3d3dy5n
b29nbGVhcGlzLmNvbS9hdXRoL2Nsb3VkLXBsYXRmb3JtQtIBCh5jb20uZ29vZ2xlLmNsb3Vk
LnJldGFpbC52MmJldGFCE1Byb2plY3RTZXJ2aWNlUHJvdG9QAVo2Y2xvdWQuZ29vZ2xlLmNv
bS9nby9yZXRhaWwvYXBpdjJiZXRhL3JldGFpbHBiO3JldGFpbHBiogIGUkVUQUlMqgIaR29v
Z2xlLkNsb3VkLlJldGFpbC5WMkJldGHKAhpHb29nbGVcQ2xvdWRcUmV0YWlsXFYyYmV0YeoC
HUdvb2dsZTo6Q2xvdWQ6OlJldGFpbDo6VjJiZXRhSqwTCgYSBA4AXAEKvAQKAQwSAw4AEjKx
BCBDb3B5cmlnaHQgMjAyNSBHb29nbGUgTExDCgogTGljZW5zZWQgdW5kZXIgdGhlIEFwYWNo
ZSBMaWNlbnNlLCBWZXJzaW9uIDIuMCAodGhlICJMaWNlbnNlIik7CiB5b3UgbWF5IG5vdCB1
c2UgdGhpcyBmaWxlIGV4Y2VwdCBpbiBjb21wbGlhbmNlIHdpdGggdGhlIExpY2Vuc2UuCiBZ
b3UgbWF5IG9idGFpbiBhIGNvcHkgb2YgdGhlIExpY2Vuc2UgYXQKCiAgICAgaHR0cDovL3d3
dy5hcGFjaGUub3JnL2xpY2Vuc2VzL0xJQ0VOU0UtMi4wCgogVW5sZXNzIHJlcXVpcmVkIGJ5
IGFwcGxpY2FibGUgbGF3IG9yIGFncmVlZCB0byBpbiB3cml0aW5nLCBzb2Z0d2FyZQogZGlz
dHJpYnV0ZWQgdW5kZXIgdGhlIExpY2Vuc2UgaXMgZGlzdHJpYnV0ZWQgb24gYW4gIkFTIElT
IiBCQVNJUywKIFdJVEhPVVQgV0FSUkFOVElFUyBPUiBDT05ESVRJT05TIE9GIEFOWSBLSU5E
LCBlaXRoZXIgZXhwcmVzcyBvciBpbXBsaWVkLgogU2VlIHRoZSBMaWNlbnNlIGZvciB0aGUg
c3BlY2lmaWMgbGFuZ3VhZ2UgZ292ZXJuaW5nIHBlcm1pc3Npb25zIGFuZAogbGltaXRhdGlv
bnMgdW5kZXIgdGhlIExpY2Vuc2UuCgoICgECEgMQACMKCQoCAwASAxIAJgoJCgIDARIDEwAh
CgkKAgMCEgMUACkKCQoCAwMSAxUAIwoJCgIDBBIDFgAyCgkKAgMFEgMXACoKCAoBCBIDGQA3
CgkKAgglEgMZADcKCAoBCBIDGgBNCgkKAggLEgMaAE0KCAoBCBIDGwAiCgkKAggKEgMbACIK
CAoBCBIDHAA0CgkKAggIEgMcADQKCAoBCBIDHQA3CgkKAggBEgMdADcKCAoBCBIDHgAkCgkK
AggkEgMeACQKCAoBCBIDHwA3CgkKAggpEgMfADcKCAoBCBIDIAA2CgkKAggtEgMgADYKNAoC
BgASBCMAOQEaKCBTZXJ2aWNlIGZvciBzZXR0aW5ncyBhdCBQcm9qZWN0IGxldmVsLgoKCgoD
BgABEgMjCBYKCgoDBgADEgMkAj0KDAoFBgADmQgSAyQCPQoLCgMGAAMSBCUCJjcKDQoFBgAD
mggSBCUCJjcKaAoEBgACABIEKgIvAxpaIEdldCB0aGUgW0FsZXJ0Q29uZmlnXVtnb29nbGUu
Y2xvdWQucmV0YWlsLnYyYmV0YS5BbGVydENvbmZpZ10gb2YgdGhlCiByZXF1ZXN0ZWQgcHJv
amVjdC4KCgwKBQYAAgABEgMqBhQKDAoFBgACAAISAyoVKgoMCgUGAAIAAxIDKjVACg0KBQYA
AgAEEgQrBC0GChEKCQYAAgAEsMq8IhIEKwQtBgoMCgUGAAIABBIDLgQyCg8KCAYAAgAEmwgA
EgMuBDIKQQoEBgACARIEMgI4AxozIFVwZGF0ZSB0aGUgYWxlcnQgY29uZmlnIG9mIHRoZSBy
ZXF1ZXN0ZWQgcHJvamVjdC4KCgwKBQYAAgEBEgMyBhcKDAoFBgACAQISAzIYMAoMCgUGAAIB
AxIDMjtGCg0KBQYAAgEEEgQzBDYGChEKCQYAAgEEsMq8IhIEMwQ2BgoMCgUGAAIBBBIDNwRG
Cg8KCAYAAgEEmwgAEgM3BEYKfQoCBAASBD4ARwEacSBSZXF1ZXN0IGZvcgogW1Byb2plY3RT
ZXJ2aWNlLkdldEFsZXJ0Q29uZmlnXVtnb29nbGUuY2xvdWQucmV0YWlsLnYyYmV0YS5Qcm9q
ZWN0U2VydmljZS5HZXRBbGVydENvbmZpZ10KIG1ldGhvZC4KCgoKAwQAARIDPggdCmgKBAQA
AgASBEECRgQaWiBSZXF1aXJlZC4gRnVsbCBBbGVydENvbmZpZyByZXNvdXJjZSBuYW1lLiBG
b3JtYXQ6CiBwcm9qZWN0cy97cHJvamVjdF9udW1iZXJ9L2FsZXJ0Q29uZmlnCgoMCgUEAAIA
BRIDQQIICgwKBQQAAgABEgNBCQ0KDAoFBAACAAMSA0EQEQoNCgUEAAIACBIEQRJGAwoPCggE
AAIACJwIABIDQgQqCg8KBwQAAgAInwgSBEMERQUKgwEKAgQBEgRMAFwBGncgUmVxdWVzdCBm
b3IKIFtQcm9qZWN0U2VydmljZS5VcGRhdGVBbGVydENvbmZpZ11bZ29vZ2xlLmNsb3VkLnJl
dGFpbC52MmJldGEuUHJvamVjdFNlcnZpY2UuVXBkYXRlQWxlcnRDb25maWddCiBtZXRob2Qu
CgoKCgMEAQESA0wIIAr0AgoEBAECABIDVgJIGuYCIFJlcXVpcmVkLiBUaGUgW0FsZXJ0Q29u
ZmlnXVtnb29nbGUuY2xvdWQucmV0YWlsLnYyYmV0YS5BbGVydENvbmZpZ10gdG8KIHVwZGF0
ZS4KCiBJZiB0aGUgY2FsbGVyIGRvZXMgbm90IGhhdmUgcGVybWlzc2lvbiB0byB1cGRhdGUg
dGhlCiBbQWxlcnRDb25maWddW2dvb2dsZS5jbG91ZC5yZXRhaWwudjJiZXRhLkFsZXJ0Q29u
ZmlnXSwgdGhlbiBhCiBQRVJNSVNTSU9OX0RFTklFRCBlcnJvciBpcyByZXR1cm5lZC4KCiBJ
ZiB0aGUgW0FsZXJ0Q29uZmlnXVtnb29nbGUuY2xvdWQucmV0YWlsLnYyYmV0YS5BbGVydENv
bmZpZ10gdG8gdXBkYXRlIGRvZXMKIG5vdCBleGlzdCwgYSBOT1RfRk9VTkQgZXJyb3IgaXMg
cmV0dXJuZWQuCgoMCgUEAQIABhIDVgINCgwKBQQBAgABEgNWDhoKDAoFBAECAAMSA1YdHgoM
CgUEAQIACBIDVh9HCg8KCAQBAgAInAgAEgNWIEYKpwEKBAQBAgESA1sCLBqZASBJbmRpY2F0
ZXMgd2hpY2ggZmllbGRzIGluIHRoZSBwcm92aWRlZAogW0FsZXJ0Q29uZmlnXVtnb29nbGUu
Y2xvdWQucmV0YWlsLnYyYmV0YS5BbGVydENvbmZpZ10gdG8gdXBkYXRlLiBJZiBub3QKIHNl
dCwgYWxsIHN1cHBvcnRlZCBmaWVsZHMgYXJlIHVwZGF0ZWQuCgoMCgUEAQIBBhIDWwIbCgwK
BQQBAgEBEgNbHCcKDAoFBAECAQMSA1sqK2IGcHJvdG8z
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Retail::V2beta::ProjectService::GetAlertConfigRequest ===
    # Fields for GetAlertConfigRequest
    # Field: name Type: 9 ()

# === Message: Google::Cloud::Retail::V2beta::ProjectService::UpdateAlertConfigRequest ===
    # Fields for UpdateAlertConfigRequest
    # Field: alert_config Type: 11 (.google.cloud.retail.v2beta.AlertConfig)
    # Field: update_mask Type: 11 (.google.protobuf.FieldMask)

# === Service Client: Google::Cloud::Retail::V2beta::ProjectService::ProjectServiceClient ===
package Google::Cloud::Retail::V2beta::ProjectService::ProjectServiceClient;

=pod

=head2 Service Client: Google::Cloud::Retail::V2beta::ProjectService::ProjectServiceClient

Client stub representing the remote C<ProjectService> gRPC service. Delegates call dispatching to L<Google::gRPC::Client>.

=head3 target

The endpoint target address. Defaults to C<retail.googleapis.com:443>.

=head3 credentials

The authentication credentials provider. Defaults to application default credentials via L<Google::Auth>.

=cut

use Moo;
use Google::Auth;
use Google::gRPC::Client;

has credentials => ( is => 'ro', default => sub { Google::Auth->default() } );
has target      => ( is => 'ro', default => 'retail.googleapis.com:443' );

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

sub get_alert_config {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Retail::V2beta::ProjectService::GetAlertConfigRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.retail.v2beta.ProjectService',
        method         => 'GetAlertConfig',
        request        => $req,
        response_class => 'Google::Cloud::Retail::V2beta::Project::AlertConfig',
    });
}

sub update_alert_config {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Retail::V2beta::ProjectService::UpdateAlertConfigRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.retail.v2beta.ProjectService',
        method         => 'UpdateAlertConfig',
        request        => $req,
        response_class => 'Google::Cloud::Retail::V2beta::Project::AlertConfig',
    });
}

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Retail::V2beta::ProjectService - Compiled Protocol Buffers messages for google/cloud/retail/v2beta/project_service.proto

=head1 SYNOPSIS

    use Google::Cloud::Retail::V2beta::ProjectService;

    my $msg = Google::Cloud::Retail::V2beta::ProjectService::GetAlertConfigRequest->new({
        name => $name,
    });

    # Read or update a field
    my $val = $msg->name();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Retail::V2beta::ProjectService::GetAlertConfigRequest->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/retail/v2beta/project_service.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Retail::V2beta::ProjectService::GetAlertConfigRequest

Request for
[ProjectService.GetAlertConfig][google.cloud.retail.v2beta.ProjectService.GetAlertConfig]
method.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. Full AlertConfig resource name. Format:
projects/{project_number}/alertConfig

=back

=head2 Google::Cloud::Retail::V2beta::ProjectService::UpdateAlertConfigRequest

Request for
[ProjectService.UpdateAlertConfig][google.cloud.retail.v2beta.ProjectService.UpdateAlertConfig]
method.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->alert_config() >> / C<< $msg->alert_config($value) >>

Type: C<Message> (L<Google::Cloud::Retail::V2beta::Project::AlertConfig>)

Required. The [AlertConfig][google.cloud.retail.v2beta.AlertConfig] to
update.

If the caller does not have permission to update the
[AlertConfig][google.cloud.retail.v2beta.AlertConfig], then a
PERMISSION_DENIED error is returned.

If the [AlertConfig][google.cloud.retail.v2beta.AlertConfig] to update does
not exist, a NOT_FOUND error is returned.

=item * C<< $msg->update_mask() >> / C<< $msg->update_mask($value) >>

Type: C<Message> (L<Google::Protobuf::FieldMask::FieldMask>)

Indicates which fields in the provided
[AlertConfig][google.cloud.retail.v2beta.AlertConfig] to update. If not
set, all supported fields are updated.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Retail::V2beta::ProjectService::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
