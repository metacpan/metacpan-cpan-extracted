package Google::Cloud::Ces::V1::ConnectorTool;

use strict;
use warnings;

our $VERSION = '0.14';

use Protobuf::Message;
use Protobuf::DescriptorPool;
use Protobuf::Internal qw(:all);
use MIME::Base64;

BEGIN {
    eval { require Google::Api::FieldBehavior };
    eval { require Google::Cloud::Ces::V1::Auth };
    my $descriptor_b64 = <<'EOF';
Cihnb29nbGUvY2xvdWQvY2VzL3YxL2Nvbm5lY3Rvcl90b29sLnByb3RvEhNnb29nbGUuY2xv
dWQuY2VzLnYxGh9nb29nbGUvYXBpL2ZpZWxkX2JlaGF2aW9yLnByb3RvGh5nb29nbGUvY2xv
dWQvY2VzL3YxL2F1dGgucHJvdG8i8wMKBkFjdGlvbhIyChRjb25uZWN0aW9uX2FjdGlvbl9p
ZBgEIAEoCUgAUhJjb25uZWN0aW9uQWN0aW9uSWQSWAoQZW50aXR5X29wZXJhdGlvbhgFIAEo
CzIrLmdvb2dsZS5jbG91ZC5jZXMudjEuQWN0aW9uLkVudGl0eU9wZXJhdGlvbkgAUg9lbnRp
dHlPcGVyYXRpb24SJgoMaW5wdXRfZmllbGRzGAIgAygJQgPgQQFSC2lucHV0RmllbGRzEigK
DW91dHB1dF9maWVsZHMYAyADKAlCA+BBAVIMb3V0cHV0RmllbGRzGvkBCg9FbnRpdHlPcGVy
YXRpb24SIAoJZW50aXR5X2lkGAEgASgJQgPgQQJSCGVudGl0eUlkElwKCW9wZXJhdGlvbhgC
IAEoDjI5Lmdvb2dsZS5jbG91ZC5jZXMudjEuQWN0aW9uLkVudGl0eU9wZXJhdGlvbi5PcGVy
YXRpb25UeXBlQgPgQQJSCW9wZXJhdGlvbiJmCg1PcGVyYXRpb25UeXBlEh4KGk9QRVJBVElP
Tl9UWVBFX1VOU1BFQ0lGSUVEEAASCAoETElTVBABEgcKA0dFVBACEgoKBkNSRUFURRADEgoK
BlVQREFURRAEEgoKBkRFTEVURRAFQg0KC2FjdGlvbl9zcGVjIvwBCg1Db25uZWN0b3JUb29s
EiMKCmNvbm5lY3Rpb24YASABKAlCA+BBAlIKY29ubmVjdGlvbhI4CgZhY3Rpb24YAiABKAsy
Gy5nb29nbGUuY2xvdWQuY2VzLnYxLkFjdGlvbkID4EECUgZhY3Rpb24STAoLYXV0aF9jb25m
aWcYAyABKAsyJi5nb29nbGUuY2xvdWQuY2VzLnYxLkVuZFVzZXJBdXRoQ29uZmlnQgPgQQFS
CmF1dGhDb25maWcSFwoEbmFtZRgEIAEoCUID4EEBUgRuYW1lEiUKC2Rlc2NyaXB0aW9uGAUg
ASgJQgPgQQFSC2Rlc2NyaXB0aW9uQloKF2NvbS5nb29nbGUuY2xvdWQuY2VzLnYxQhJDb25u
ZWN0b3JUb29sUHJvdG9QAVopY2xvdWQuZ29vZ2xlLmNvbS9nby9jZXMvYXBpdjEvY2VzcGI7
Y2VzcGJK3iAKBhIEDgBuAQq8BAoBDBIDDgASMrEEIENvcHlyaWdodCAyMDI2IEdvb2dsZSBM
TEMKCiBMaWNlbnNlZCB1bmRlciB0aGUgQXBhY2hlIExpY2Vuc2UsIFZlcnNpb24gMi4wICh0
aGUgIkxpY2Vuc2UiKTsKIHlvdSBtYXkgbm90IHVzZSB0aGlzIGZpbGUgZXhjZXB0IGluIGNv
bXBsaWFuY2Ugd2l0aCB0aGUgTGljZW5zZS4KIFlvdSBtYXkgb2J0YWluIGEgY29weSBvZiB0
aGUgTGljZW5zZSBhdAoKICAgICBodHRwOi8vd3d3LmFwYWNoZS5vcmcvbGljZW5zZXMvTElD
RU5TRS0yLjAKCiBVbmxlc3MgcmVxdWlyZWQgYnkgYXBwbGljYWJsZSBsYXcgb3IgYWdyZWVk
IHRvIGluIHdyaXRpbmcsIHNvZnR3YXJlCiBkaXN0cmlidXRlZCB1bmRlciB0aGUgTGljZW5z
ZSBpcyBkaXN0cmlidXRlZCBvbiBhbiAiQVMgSVMiIEJBU0lTLAogV0lUSE9VVCBXQVJSQU5U
SUVTIE9SIENPTkRJVElPTlMgT0YgQU5ZIEtJTkQsIGVpdGhlciBleHByZXNzIG9yIGltcGxp
ZWQuCiBTZWUgdGhlIExpY2Vuc2UgZm9yIHRoZSBzcGVjaWZpYyBsYW5ndWFnZSBnb3Zlcm5p
bmcgcGVybWlzc2lvbnMgYW5kCiBsaW1pdGF0aW9ucyB1bmRlciB0aGUgTGljZW5zZS4KCggK
AQISAxAAHAoJCgIDABIDEgApCgkKAgMBEgMTACgKCAoBCBIDFQBACgkKAggLEgMVAEAKCAoB
CBIDFgAiCgkKAggKEgMWACIKCAoBCBIDFwAzCgkKAggIEgMXADMKCAoBCBIDGAAwCgkKAggB
EgMYADAK1QEKAgQAEgQeAE4BGsgBIENvbmZpZ3VyYXRpb24gb2YgYW4gQWN0aW9uIGZvciB0
aGUgdG9vbCB0byB1c2UuCiBOb3RlOiBUaGlzIGNhbiBiZSBlaXRoZXIgYW4gQWN0aW9uIG9y
IGFuIE9wZXJhdGlvbi4gU2VlCiBodHRwczovL2Nsb3VkLmdvb2dsZS5jb20vaW50ZWdyYXRp
b24tY29ubmVjdG9ycy9kb2NzL2VudGl0aWVzLW9wZXJhdGlvbi1hY3Rpb24KIGZvciBkZXRh
aWxzLgoKCgoDBAABEgMeCA4KNAoEBAADABIEIAI8AxomIEVudGl0eSBDUlVEIG9wZXJhdGlv
biBzcGVjaWZpY2F0aW9uLgoKDAoFBAADAAESAyAKGQo5CgYEAAMABAASBCIENQUaKSBUaGUg
b3BlcmF0aW9uIHRvIHBlcmZvcm0gb24gdGhlIGVudGl0eS4KCg4KBwQAAwAEAAESAyIJFgpf
CggEAAMABAACABIDJQYlGk4gT3BlcmF0aW9uIHR5cGUgdW5zcGVjaWZpZWQuIEludmFsaWQs
IENvbm5lY3RvclRvb2wgY3JlYXRlL3VwZGF0ZQogd2lsbCBmYWlsLgoKEAoJBAADAAQAAgAB
EgMlBiAKEAoJBAADAAQAAgACEgMlIyQKIgoIBAADAAQAAgESAygGDxoRIExpc3Qgb3BlcmF0
aW9uLgoKEAoJBAADAAQAAgEBEgMoBgoKEAoJBAADAAQAAgECEgMoDQ4KIQoIBAADAAQAAgIS
AysGDhoQIEdldCBvcGVyYXRpb24uCgoQCgkEAAMABAACAgESAysGCQoQCgkEAAMABAACAgIS
AysMDQokCggEAAMABAACAxIDLgYRGhMgQ3JlYXRlIG9wZXJhdGlvbi4KChAKCQQAAwAEAAID
ARIDLgYMChAKCQQAAwAEAAIDAhIDLg8QCiQKCAQAAwAEAAIEEgMxBhEaEyBVcGRhdGUgb3Bl
cmF0aW9uLgoKEAoJBAADAAQAAgQBEgMxBgwKEAoJBAADAAQAAgQCEgMxDxAKJAoIBAADAAQA
AgUSAzQGERoTIERlbGV0ZSBvcGVyYXRpb24uCgoQCgkEAAMABAACBQESAzQGDAoQCgkEAAMA
BAACBQISAzQPEAosCgYEAAMAAgASAzgEQhodIFJlcXVpcmVkLiBJRCBvZiB0aGUgZW50aXR5
LgoKDgoHBAADAAIABRIDOAQKCg4KBwQAAwACAAESAzgLFAoOCgcEAAMAAgADEgM4FxgKDgoH
BAADAAIACBIDOBlBChEKCgQAAwACAAicCAASAzgaQAo+CgYEAAMAAgESAzsESRovIFJlcXVp
cmVkLiBPcGVyYXRpb24gdG8gcGVyZm9ybSBvbiB0aGUgZW50aXR5LgoKDgoHBAADAAIBBhID
OwQRCg4KBwQAAwACAQESAzsSGwoOCgcEAAMAAgEDEgM7Hh8KDgoHBAADAAIBCBIDOyBIChEK
CgQAAwACAQicCAASAzshRwpNCgQEAAgAEgQ/AkUDGj8gU3BlY2lmaWNhdGlvbiBmb3IgYW4g
YWN0aW9uIHRvIGNvbmZpZ3VyZSBmb3IgdGhlIHRvb2wgdG8gdXNlLgoKDAoFBAAIAAESAz8I
Ewo9CgQEAAIAEgNBBCQaMCBJRCBvZiBhIENvbm5lY3Rpb24gYWN0aW9uIGZvciB0aGUgdG9v
bCB0byB1c2UuCgoMCgUEAAIABRIDQQQKCgwKBQQAAgABEgNBCx8KDAoFBAACAAMSA0EiIwpC
CgQEAAIBEgNEBCkaNSBFbnRpdHkgb3BlcmF0aW9uIGNvbmZpZ3VyYXRpb24gZm9yIHRoZSB0
b29sIHRvIHVzZS4KCgwKBQQAAgEGEgNEBBMKDAoFBAACAQESA0QUJAoMCgUEAAIBAxIDRCco
Co8BCgQEAAICEgNJAkwagQEgT3B0aW9uYWwuIEVudGl0eSBmaWVsZHMgdG8gdXNlIGFzIGlu
cHV0cyBmb3IgdGhlIG9wZXJhdGlvbi4KIElmIG5vIGZpZWxkcyBhcmUgc3BlY2lmaWVkLCBh
bGwgZmllbGRzIG9mIHRoZSBFbnRpdHkgd2lsbCBiZSB1c2VkLgoKDAoFBAACAgQSA0kCCgoM
CgUEAAICBRIDSQsRCgwKBQQAAgIBEgNJEh4KDAoFBAACAgMSA0khIgoMCgUEAAICCBIDSSNL
Cg8KCAQAAgIInAgAEgNJJEoKjAEKBAQAAgMSA00CTRp/IE9wdGlvbmFsLiBFbnRpdHkgZmll
bGRzIHRvIHJldHVybiBmcm9tIHRoZSBvcGVyYXRpb24uCiBJZiBubyBmaWVsZHMgYXJlIHNw
ZWNpZmllZCwgYWxsIGZpZWxkcyBvZiB0aGUgRW50aXR5IHdpbGwgYmUgcmV0dXJuZWQuCgoM
CgUEAAIDBBIDTQIKCgwKBQQAAgMFEgNNCxEKDAoFBAACAwESA00SHwoMCgUEAAIDAxIDTSIj
CgwKBQQAAgMIEgNNJEwKDwoIBAACAwicCAASA00lSwqRAQoCBAESBFIAbgEahAEgQSBDb25u
ZWN0b3JUb29sIGFsbG93cyBjb25uZWN0aW9ucyB0byBkaWZmZXJlbnQgaW50ZWdyYXRpb25z
LgogU2VlOiBodHRwczovL2Nsb3VkLmdvb2dsZS5jb20vaW50ZWdyYXRpb24tY29ubmVjdG9y
cy9kb2NzL292ZXJ2aWV3LgoKCgoDBAEBEgNSCBUKswEKBAQBAgASA1cCQRqlASBSZXF1aXJl
ZC4gVGhlIGZ1bGwgcmVzb3VyY2UgbmFtZSBvZiB0aGUgcmVmZXJlbmNlZCBJbnRlZ3JhdGlv
biBDb25uZWN0b3JzCiBDb25uZWN0aW9uLgogRm9ybWF0OgogYHByb2plY3RzL3twcm9qZWN0
fS9sb2NhdGlvbnMve2xvY2F0aW9ufS9jb25uZWN0aW9ucy97Y29ubmVjdGlvbn1gCgoMCgUE
AQIABRIDVwIICgwKBQQBAgABEgNXCRMKDAoFBAECAAMSA1cWFwoMCgUEAQIACBIDVxhACg8K
CAQBAgAInAgAEgNXGT8KNAoEBAECARIDWgI9GicgUmVxdWlyZWQuIEFjdGlvbiBmb3IgdGhl
IHRvb2wgdG8gdXNlLgoKDAoFBAECAQYSA1oCCAoMCgUEAQIBARIDWgkPCgwKBQQBAgEDEgNa
EhMKDAoFBAECAQgSA1oUPAoPCggEAQIBCJwIABIDWhU7CqsECgQEAQICEgNlAk0anQQgT3B0
aW9uYWwuIENvbmZpZ3VyZXMgaG93IGF1dGhlbnRpY2F0aW9uIGlzIGhhbmRsZWQgaW4gSW50
ZWdyYXRpb24KIENvbm5lY3RvcnMuIEJ5IGRlZmF1bHQsIGFuIGFkbWluIGF1dGhlbnRpY2F0
aW9uIGlzIHBhc3NlZCBpbiB0aGUKIEludGVncmF0aW9uIENvbm5lY3RvcnMgQVBJIHJlcXVl
c3RzLiBZb3UgY2FuIG92ZXJyaWRlIGl0IHdpdGggYSBkaWZmZXJlbnQKIGVuZC11c2VyIGF1
dGhlbnRpY2F0aW9uIGNvbmZpZy4KICoqTm90ZSoqOiBUaGUgQ29ubmVjdGlvbiBtdXN0IGhh
dmUgYXV0aGVudGljYXRpb24gb3ZlcnJpZGUgZW5hYmxlZCBpbgogb3JkZXIgdG8gc3BlY2lm
eSBhbiBFVUMgY29uZmlndXJhdGlvbiBoZXJlIC0gb3RoZXJ3aXNlLCB0aGUgQ29ubmVjdG9y
VG9vbAogY3JlYXRpb24gd2lsbCBmYWlsLiBTZWUKIGh0dHBzOi8vY2xvdWQuZ29vZ2xlLmNv
bS9hcHBsaWNhdGlvbi1pbnRlZ3JhdGlvbi9kb2NzL2NvbmZpZ3VyZS1jb25uZWN0b3JzLXRh
c2sjY29uZmlndXJlLWF1dGhlbnRpY2F0aW9uLW92ZXJyaWRlCiBmb3IgZGV0YWlscy4KCgwK
BQQBAgIGEgNlAhMKDAoFBAECAgESA2UUHwoMCgUEAQICAxIDZSIjCgwKBQQBAgIIEgNlJEwK
DwoIBAECAgicCAASA2UlSwp6CgQEAQIDEgNpAjsabSBPcHRpb25hbC4gVGhlIG5hbWUgb2Yg
dGhlIHRvb2wgdGhhdCBjYW4gYmUgdXNlZCBieSB0aGUgQWdlbnQgdG8gZGVjaWRlCiB3aGV0
aGVyIHRvIGNhbGwgdGhpcyBDb25uZWN0b3JUb29sLgoKDAoFBAECAwUSA2kCCAoMCgUEAQID
ARIDaQkNCgwKBQQBAgMDEgNpEBEKDAoFBAECAwgSA2kSOgoPCggEAQIDCJwIABIDaRM5CoEB
CgQEAQIEEgNtAkIadCBPcHRpb25hbC4gVGhlIGRlc2NyaXB0aW9uIG9mIHRoZSB0b29sIHRo
YXQgY2FuIGJlIHVzZWQgYnkgdGhlIEFnZW50IHRvCiBkZWNpZGUgd2hldGhlciB0byBjYWxs
IHRoaXMgQ29ubmVjdG9yVG9vbC4KCgwKBQQBAgQFEgNtAggKDAoFBAECBAESA20JFAoMCgUE
AQIEAxIDbRcYCgwKBQQBAgQIEgNtGUEKDwoIBAECBAicCAASA20aQGIGcHJvdG8z
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Ces::V1::ConnectorTool::Action ===
    # Fields for Action
    # Field: connection_action_id Type: 9 ()
    # Field: entity_operation Type: 11 (.google.cloud.ces.v1.Action.EntityOperation)
    # Field: input_fields Type: 9 ()
    # Field: output_fields Type: 9 ()

# === Message: Google::Cloud::Ces::V1::ConnectorTool::ConnectorTool ===
    # Fields for ConnectorTool
    # Field: connection Type: 9 ()
    # Field: action Type: 11 (.google.cloud.ces.v1.Action)
    # Field: auth_config Type: 11 (.google.cloud.ces.v1.EndUserAuthConfig)
    # Field: name Type: 9 ()
    # Field: description Type: 9 ()

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Ces::V1::ConnectorTool - Compiled Protocol Buffers messages for google/cloud/ces/v1/connector_tool.proto

=head1 SYNOPSIS

    use Google::Cloud::Ces::V1::ConnectorTool;

    my $msg = Google::Cloud::Ces::V1::ConnectorTool::Action->new({
        connection_action_id => $connection_action_id,
        entity_operation => $entity_operation,
        input_fields => $input_fields,
        output_fields => $output_fields,
    });

    # Read or update a field
    my $val = $msg->connection_action_id();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Ces::V1::ConnectorTool::Action->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/ces/v1/connector_tool.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Ces::V1::ConnectorTool::Action

Configuration of an Action for the tool to use.
Note: This can be either an Action or an Operation. See
https://cloud.google.com/integration-connectors/docs/entities-operation-action
for details.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->connection_action_id() >> / C<< $msg->connection_action_id($value) >>

Type: C<String>

ID of a Connection action for the tool to use.

=item * C<< $msg->entity_operation() >> / C<< $msg->entity_operation($value) >>

Type: C<Message> (L<Google::Cloud::Ces::V1::ConnectorTool::Action::EntityOperation>)

Entity operation configuration for the tool to use.

=item * C<< $msg->input_fields() >> / C<< $msg->input_fields($value) >>

Type: C<String>

Optional. Entity fields to use as inputs for the operation.
If no fields are specified, all fields of the Entity will be used.

=item * C<< $msg->output_fields() >> / C<< $msg->output_fields($value) >>

Type: C<String>

Optional. Entity fields to return from the operation.
If no fields are specified, all fields of the Entity will be returned.

=back

=head2 Google::Cloud::Ces::V1::ConnectorTool::ConnectorTool

A ConnectorTool allows connections to different integrations.
See: https://cloud.google.com/integration-connectors/docs/overview.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->connection() >> / C<< $msg->connection($value) >>

Type: C<String>

Required. The full resource name of the referenced Integration Connectors
Connection.
Format:
`projects/{project}/locations/{location}/connections/{connection}`

=item * C<< $msg->action() >> / C<< $msg->action($value) >>

Type: C<Message> (L<Google::Cloud::Ces::V1::ConnectorTool::Action>)

Required. Action for the tool to use.

=item * C<< $msg->auth_config() >> / C<< $msg->auth_config($value) >>

Type: C<Message> (L<Google::Cloud::Ces::V1::Auth::EndUserAuthConfig>)

Optional. Configures how authentication is handled in Integration
Connectors. By default, an admin authentication is passed in the
Integration Connectors API requests. You can override it with a different
end-user authentication config.
B<Note>: The Connection must have authentication override enabled in
order to specify an EUC configuration here - otherwise, the ConnectorTool
creation will fail. See
https://cloud.google.com/application-integration/docs/configure-connectors-task#configure-authentication-override
for details.

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Optional. The name of the tool that can be used by the Agent to decide
whether to call this ConnectorTool.

=item * C<< $msg->description() >> / C<< $msg->description($value) >>

Type: C<String>

Optional. The description of the tool that can be used by the Agent to
decide whether to call this ConnectorTool.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Ces::V1::ConnectorTool::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
