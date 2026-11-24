package Google::Cloud::Ces::V1beta::ConnectorTool;

use strict;
use warnings;

our $VERSION = '0.14';

use Protobuf::Message;
use Protobuf::DescriptorPool;
use Protobuf::Internal qw(:all);
use MIME::Base64;

BEGIN {
    eval { require Google::Api::FieldBehavior };
    eval { require Google::Cloud::Ces::V1beta::Auth };
    my $descriptor_b64 = <<'EOF';
Cixnb29nbGUvY2xvdWQvY2VzL3YxYmV0YS9jb25uZWN0b3JfdG9vbC5wcm90bxIXZ29vZ2xl
LmNsb3VkLmNlcy52MWJldGEaH2dvb2dsZS9hcGkvZmllbGRfYmVoYXZpb3IucHJvdG8aImdv
b2dsZS9jbG91ZC9jZXMvdjFiZXRhL2F1dGgucHJvdG8i+wMKBkFjdGlvbhIyChRjb25uZWN0
aW9uX2FjdGlvbl9pZBgEIAEoCUgAUhJjb25uZWN0aW9uQWN0aW9uSWQSXAoQZW50aXR5X29w
ZXJhdGlvbhgFIAEoCzIvLmdvb2dsZS5jbG91ZC5jZXMudjFiZXRhLkFjdGlvbi5FbnRpdHlP
cGVyYXRpb25IAFIPZW50aXR5T3BlcmF0aW9uEiYKDGlucHV0X2ZpZWxkcxgCIAMoCUID4EEB
UgtpbnB1dEZpZWxkcxIoCg1vdXRwdXRfZmllbGRzGAMgAygJQgPgQQFSDG91dHB1dEZpZWxk
cxr9AQoPRW50aXR5T3BlcmF0aW9uEiAKCWVudGl0eV9pZBgBIAEoCUID4EECUghlbnRpdHlJ
ZBJgCglvcGVyYXRpb24YAiABKA4yPS5nb29nbGUuY2xvdWQuY2VzLnYxYmV0YS5BY3Rpb24u
RW50aXR5T3BlcmF0aW9uLk9wZXJhdGlvblR5cGVCA+BBAlIJb3BlcmF0aW9uImYKDU9wZXJh
dGlvblR5cGUSHgoaT1BFUkFUSU9OX1RZUEVfVU5TUEVDSUZJRUQQABIICgRMSVNUEAESBwoD
R0VUEAISCgoGQ1JFQVRFEAMSCgoGVVBEQVRFEAQSCgoGREVMRVRFEAVCDQoLYWN0aW9uX3Nw
ZWMihAIKDUNvbm5lY3RvclRvb2wSIwoKY29ubmVjdGlvbhgBIAEoCUID4EECUgpjb25uZWN0
aW9uEjwKBmFjdGlvbhgCIAEoCzIfLmdvb2dsZS5jbG91ZC5jZXMudjFiZXRhLkFjdGlvbkID
4EECUgZhY3Rpb24SUAoLYXV0aF9jb25maWcYAyABKAsyKi5nb29nbGUuY2xvdWQuY2VzLnYx
YmV0YS5FbmRVc2VyQXV0aENvbmZpZ0ID4EEBUgphdXRoQ29uZmlnEhcKBG5hbWUYBCABKAlC
A+BBAVIEbmFtZRIlCgtkZXNjcmlwdGlvbhgFIAEoCUID4EEBUgtkZXNjcmlwdGlvbkJiChtj
b20uZ29vZ2xlLmNsb3VkLmNlcy52MWJldGFCEkNvbm5lY3RvclRvb2xQcm90b1ABWi1jbG91
ZC5nb29nbGUuY29tL2dvL2Nlcy9hcGl2MWJldGEvY2VzcGI7Y2VzcGJK3iAKBhIEDgBuAQq8
BAoBDBIDDgASMrEEIENvcHlyaWdodCAyMDI2IEdvb2dsZSBMTEMKCiBMaWNlbnNlZCB1bmRl
ciB0aGUgQXBhY2hlIExpY2Vuc2UsIFZlcnNpb24gMi4wICh0aGUgIkxpY2Vuc2UiKTsKIHlv
dSBtYXkgbm90IHVzZSB0aGlzIGZpbGUgZXhjZXB0IGluIGNvbXBsaWFuY2Ugd2l0aCB0aGUg
TGljZW5zZS4KIFlvdSBtYXkgb2J0YWluIGEgY29weSBvZiB0aGUgTGljZW5zZSBhdAoKICAg
ICBodHRwOi8vd3d3LmFwYWNoZS5vcmcvbGljZW5zZXMvTElDRU5TRS0yLjAKCiBVbmxlc3Mg
cmVxdWlyZWQgYnkgYXBwbGljYWJsZSBsYXcgb3IgYWdyZWVkIHRvIGluIHdyaXRpbmcsIHNv
ZnR3YXJlCiBkaXN0cmlidXRlZCB1bmRlciB0aGUgTGljZW5zZSBpcyBkaXN0cmlidXRlZCBv
biBhbiAiQVMgSVMiIEJBU0lTLAogV0lUSE9VVCBXQVJSQU5USUVTIE9SIENPTkRJVElPTlMg
T0YgQU5ZIEtJTkQsIGVpdGhlciBleHByZXNzIG9yIGltcGxpZWQuCiBTZWUgdGhlIExpY2Vu
c2UgZm9yIHRoZSBzcGVjaWZpYyBsYW5ndWFnZSBnb3Zlcm5pbmcgcGVybWlzc2lvbnMgYW5k
CiBsaW1pdGF0aW9ucyB1bmRlciB0aGUgTGljZW5zZS4KCggKAQISAxAAIAoJCgIDABIDEgAp
CgkKAgMBEgMTACwKCAoBCBIDFQBECgkKAggLEgMVAEQKCAoBCBIDFgAiCgkKAggKEgMWACIK
CAoBCBIDFwAzCgkKAggIEgMXADMKCAoBCBIDGAA0CgkKAggBEgMYADQK1QEKAgQAEgQeAE4B
GsgBIENvbmZpZ3VyYXRpb24gb2YgYW4gQWN0aW9uIGZvciB0aGUgdG9vbCB0byB1c2UuCiBO
b3RlOiBUaGlzIGNhbiBiZSBlaXRoZXIgYW4gQWN0aW9uIG9yIGFuIE9wZXJhdGlvbi4gU2Vl
CiBodHRwczovL2Nsb3VkLmdvb2dsZS5jb20vaW50ZWdyYXRpb24tY29ubmVjdG9ycy9kb2Nz
L2VudGl0aWVzLW9wZXJhdGlvbi1hY3Rpb24KIGZvciBkZXRhaWxzLgoKCgoDBAABEgMeCA4K
NAoEBAADABIEIAI8AxomIEVudGl0eSBDUlVEIG9wZXJhdGlvbiBzcGVjaWZpY2F0aW9uLgoK
DAoFBAADAAESAyAKGQo5CgYEAAMABAASBCIENQUaKSBUaGUgb3BlcmF0aW9uIHRvIHBlcmZv
cm0gb24gdGhlIGVudGl0eS4KCg4KBwQAAwAEAAESAyIJFgpfCggEAAMABAACABIDJQYlGk4g
T3BlcmF0aW9uIHR5cGUgdW5zcGVjaWZpZWQuIEludmFsaWQsIENvbm5lY3RvclRvb2wgY3Jl
YXRlL3VwZGF0ZQogd2lsbCBmYWlsLgoKEAoJBAADAAQAAgABEgMlBiAKEAoJBAADAAQAAgAC
EgMlIyQKIgoIBAADAAQAAgESAygGDxoRIExpc3Qgb3BlcmF0aW9uLgoKEAoJBAADAAQAAgEB
EgMoBgoKEAoJBAADAAQAAgECEgMoDQ4KIQoIBAADAAQAAgISAysGDhoQIEdldCBvcGVyYXRp
b24uCgoQCgkEAAMABAACAgESAysGCQoQCgkEAAMABAACAgISAysMDQokCggEAAMABAACAxID
LgYRGhMgQ3JlYXRlIG9wZXJhdGlvbi4KChAKCQQAAwAEAAIDARIDLgYMChAKCQQAAwAEAAID
AhIDLg8QCiQKCAQAAwAEAAIEEgMxBhEaEyBVcGRhdGUgb3BlcmF0aW9uLgoKEAoJBAADAAQA
AgQBEgMxBgwKEAoJBAADAAQAAgQCEgMxDxAKJAoIBAADAAQAAgUSAzQGERoTIERlbGV0ZSBv
cGVyYXRpb24uCgoQCgkEAAMABAACBQESAzQGDAoQCgkEAAMABAACBQISAzQPEAosCgYEAAMA
AgASAzgEQhodIFJlcXVpcmVkLiBJRCBvZiB0aGUgZW50aXR5LgoKDgoHBAADAAIABRIDOAQK
Cg4KBwQAAwACAAESAzgLFAoOCgcEAAMAAgADEgM4FxgKDgoHBAADAAIACBIDOBlBChEKCgQA
AwACAAicCAASAzgaQAo+CgYEAAMAAgESAzsESRovIFJlcXVpcmVkLiBPcGVyYXRpb24gdG8g
cGVyZm9ybSBvbiB0aGUgZW50aXR5LgoKDgoHBAADAAIBBhIDOwQRCg4KBwQAAwACAQESAzsS
GwoOCgcEAAMAAgEDEgM7Hh8KDgoHBAADAAIBCBIDOyBIChEKCgQAAwACAQicCAASAzshRwpN
CgQEAAgAEgQ/AkUDGj8gU3BlY2lmaWNhdGlvbiBmb3IgYW4gYWN0aW9uIHRvIGNvbmZpZ3Vy
ZSBmb3IgdGhlIHRvb2wgdG8gdXNlLgoKDAoFBAAIAAESAz8IEwo9CgQEAAIAEgNBBCQaMCBJ
RCBvZiBhIENvbm5lY3Rpb24gYWN0aW9uIGZvciB0aGUgdG9vbCB0byB1c2UuCgoMCgUEAAIA
BRIDQQQKCgwKBQQAAgABEgNBCx8KDAoFBAACAAMSA0EiIwpCCgQEAAIBEgNEBCkaNSBFbnRp
dHkgb3BlcmF0aW9uIGNvbmZpZ3VyYXRpb24gZm9yIHRoZSB0b29sIHRvIHVzZS4KCgwKBQQA
AgEGEgNEBBMKDAoFBAACAQESA0QUJAoMCgUEAAIBAxIDRCcoCo8BCgQEAAICEgNJAkwagQEg
T3B0aW9uYWwuIEVudGl0eSBmaWVsZHMgdG8gdXNlIGFzIGlucHV0cyBmb3IgdGhlIG9wZXJh
dGlvbi4KIElmIG5vIGZpZWxkcyBhcmUgc3BlY2lmaWVkLCBhbGwgZmllbGRzIG9mIHRoZSBF
bnRpdHkgd2lsbCBiZSB1c2VkLgoKDAoFBAACAgQSA0kCCgoMCgUEAAICBRIDSQsRCgwKBQQA
AgIBEgNJEh4KDAoFBAACAgMSA0khIgoMCgUEAAICCBIDSSNLCg8KCAQAAgIInAgAEgNJJEoK
jAEKBAQAAgMSA00CTRp/IE9wdGlvbmFsLiBFbnRpdHkgZmllbGRzIHRvIHJldHVybiBmcm9t
IHRoZSBvcGVyYXRpb24uCiBJZiBubyBmaWVsZHMgYXJlIHNwZWNpZmllZCwgYWxsIGZpZWxk
cyBvZiB0aGUgRW50aXR5IHdpbGwgYmUgcmV0dXJuZWQuCgoMCgUEAAIDBBIDTQIKCgwKBQQA
AgMFEgNNCxEKDAoFBAACAwESA00SHwoMCgUEAAIDAxIDTSIjCgwKBQQAAgMIEgNNJEwKDwoI
BAACAwicCAASA00lSwqRAQoCBAESBFIAbgEahAEgQSBDb25uZWN0b3JUb29sIGFsbG93cyBj
b25uZWN0aW9ucyB0byBkaWZmZXJlbnQgaW50ZWdyYXRpb25zLgogU2VlOiBodHRwczovL2Ns
b3VkLmdvb2dsZS5jb20vaW50ZWdyYXRpb24tY29ubmVjdG9ycy9kb2NzL292ZXJ2aWV3LgoK
CgoDBAEBEgNSCBUKswEKBAQBAgASA1cCQRqlASBSZXF1aXJlZC4gVGhlIGZ1bGwgcmVzb3Vy
Y2UgbmFtZSBvZiB0aGUgcmVmZXJlbmNlZCBJbnRlZ3JhdGlvbiBDb25uZWN0b3JzCiBDb25u
ZWN0aW9uLgogRm9ybWF0OgogYHByb2plY3RzL3twcm9qZWN0fS9sb2NhdGlvbnMve2xvY2F0
aW9ufS9jb25uZWN0aW9ucy97Y29ubmVjdGlvbn1gCgoMCgUEAQIABRIDVwIICgwKBQQBAgAB
EgNXCRMKDAoFBAECAAMSA1cWFwoMCgUEAQIACBIDVxhACg8KCAQBAgAInAgAEgNXGT8KNAoE
BAECARIDWgI9GicgUmVxdWlyZWQuIEFjdGlvbiBmb3IgdGhlIHRvb2wgdG8gdXNlLgoKDAoF
BAECAQYSA1oCCAoMCgUEAQIBARIDWgkPCgwKBQQBAgEDEgNaEhMKDAoFBAECAQgSA1oUPAoP
CggEAQIBCJwIABIDWhU7CqsECgQEAQICEgNlAk0anQQgT3B0aW9uYWwuIENvbmZpZ3VyZXMg
aG93IGF1dGhlbnRpY2F0aW9uIGlzIGhhbmRsZWQgaW4gSW50ZWdyYXRpb24KIENvbm5lY3Rv
cnMuIEJ5IGRlZmF1bHQsIGFuIGFkbWluIGF1dGhlbnRpY2F0aW9uIGlzIHBhc3NlZCBpbiB0
aGUKIEludGVncmF0aW9uIENvbm5lY3RvcnMgQVBJIHJlcXVlc3RzLiBZb3UgY2FuIG92ZXJy
aWRlIGl0IHdpdGggYSBkaWZmZXJlbnQKIGVuZC11c2VyIGF1dGhlbnRpY2F0aW9uIGNvbmZp
Zy4KICoqTm90ZSoqOiBUaGUgQ29ubmVjdGlvbiBtdXN0IGhhdmUgYXV0aGVudGljYXRpb24g
b3ZlcnJpZGUgZW5hYmxlZCBpbgogb3JkZXIgdG8gc3BlY2lmeSBhbiBFVUMgY29uZmlndXJh
dGlvbiBoZXJlIC0gb3RoZXJ3aXNlLCB0aGUgQ29ubmVjdG9yVG9vbAogY3JlYXRpb24gd2ls
bCBmYWlsLiBTZWUKIGh0dHBzOi8vY2xvdWQuZ29vZ2xlLmNvbS9hcHBsaWNhdGlvbi1pbnRl
Z3JhdGlvbi9kb2NzL2NvbmZpZ3VyZS1jb25uZWN0b3JzLXRhc2sjY29uZmlndXJlLWF1dGhl
bnRpY2F0aW9uLW92ZXJyaWRlCiBmb3IgZGV0YWlscy4KCgwKBQQBAgIGEgNlAhMKDAoFBAEC
AgESA2UUHwoMCgUEAQICAxIDZSIjCgwKBQQBAgIIEgNlJEwKDwoIBAECAgicCAASA2UlSwp6
CgQEAQIDEgNpAjsabSBPcHRpb25hbC4gVGhlIG5hbWUgb2YgdGhlIHRvb2wgdGhhdCBjYW4g
YmUgdXNlZCBieSB0aGUgQWdlbnQgdG8gZGVjaWRlCiB3aGV0aGVyIHRvIGNhbGwgdGhpcyBD
b25uZWN0b3JUb29sLgoKDAoFBAECAwUSA2kCCAoMCgUEAQIDARIDaQkNCgwKBQQBAgMDEgNp
EBEKDAoFBAECAwgSA2kSOgoPCggEAQIDCJwIABIDaRM5CoEBCgQEAQIEEgNtAkIadCBPcHRp
b25hbC4gVGhlIGRlc2NyaXB0aW9uIG9mIHRoZSB0b29sIHRoYXQgY2FuIGJlIHVzZWQgYnkg
dGhlIEFnZW50IHRvCiBkZWNpZGUgd2hldGhlciB0byBjYWxsIHRoaXMgQ29ubmVjdG9yVG9v
bC4KCgwKBQQBAgQFEgNtAggKDAoFBAECBAESA20JFAoMCgUEAQIEAxIDbRcYCgwKBQQBAgQI
EgNtGUEKDwoIBAECBAicCAASA20aQGIGcHJvdG8z
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Ces::V1beta::ConnectorTool::Action ===
    # Fields for Action
    # Field: connection_action_id Type: 9 ()
    # Field: entity_operation Type: 11 (.google.cloud.ces.v1beta.Action.EntityOperation)
    # Field: input_fields Type: 9 ()
    # Field: output_fields Type: 9 ()

# === Message: Google::Cloud::Ces::V1beta::ConnectorTool::ConnectorTool ===
    # Fields for ConnectorTool
    # Field: connection Type: 9 ()
    # Field: action Type: 11 (.google.cloud.ces.v1beta.Action)
    # Field: auth_config Type: 11 (.google.cloud.ces.v1beta.EndUserAuthConfig)
    # Field: name Type: 9 ()
    # Field: description Type: 9 ()

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Ces::V1beta::ConnectorTool - Compiled Protocol Buffers messages for google/cloud/ces/v1beta/connector_tool.proto

=head1 SYNOPSIS

    use Google::Cloud::Ces::V1beta::ConnectorTool;

    my $msg = Google::Cloud::Ces::V1beta::ConnectorTool::Action->new({
        connection_action_id => $connection_action_id,
        entity_operation => $entity_operation,
        input_fields => $input_fields,
        output_fields => $output_fields,
    });

    # Read or update a field
    my $val = $msg->connection_action_id();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Ces::V1beta::ConnectorTool::Action->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/ces/v1beta/connector_tool.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Ces::V1beta::ConnectorTool::Action

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

Type: C<Message> (L<Google::Cloud::Ces::V1beta::ConnectorTool::Action::EntityOperation>)

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

=head2 Google::Cloud::Ces::V1beta::ConnectorTool::ConnectorTool

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

Type: C<Message> (L<Google::Cloud::Ces::V1beta::ConnectorTool::Action>)

Required. Action for the tool to use.

=item * C<< $msg->auth_config() >> / C<< $msg->auth_config($value) >>

Type: C<Message> (L<Google::Cloud::Ces::V1beta::Auth::EndUserAuthConfig>)

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

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Ces::V1beta::ConnectorTool::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
