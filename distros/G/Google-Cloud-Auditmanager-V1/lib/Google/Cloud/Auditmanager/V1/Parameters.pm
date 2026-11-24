package Google::Cloud::Auditmanager::V1::Parameters;

use strict;
use warnings;

our $VERSION = '0.14';

use Protobuf::Message;
use Protobuf::DescriptorPool;
use Protobuf::Internal qw(:all);
use MIME::Base64;

BEGIN {
    eval { require Google::Api::FieldBehavior };
    eval { require Google::Api::Resource };
    my $descriptor_b64 = <<'EOF';
Ci1nb29nbGUvY2xvdWQvYXVkaXRtYW5hZ2VyL3YxL3BhcmFtZXRlcnMucHJvdG8SHGdvb2ds
ZS5jbG91ZC5hdWRpdG1hbmFnZXIudjEaH2dvb2dsZS9hcGkvZmllbGRfYmVoYXZpb3IucHJv
dG8aGWdvb2dsZS9hcGkvcmVzb3VyY2UucHJvdG8ifAoJUGFyYW1ldGVyEhcKBG5hbWUYASAB
KAlCA+BBAlIEbmFtZRJWCg9wYXJhbWV0ZXJfdmFsdWUYAiABKAsyKC5nb29nbGUuY2xvdWQu
YXVkaXRtYW5hZ2VyLnYxLlBhcmFtVmFsdWVCA+BBAlIOcGFyYW1ldGVyVmFsdWUiKQoKU3Ry
aW5nTGlzdBIbCgZ2YWx1ZXMYASADKAlCA+BBAlIGdmFsdWVzIrwCCgpQYXJhbVZhbHVlEigK
DHN0cmluZ192YWx1ZRgDIAEoCUID4EEBSABSC3N0cmluZ1ZhbHVlEiQKCmJvb2xfdmFsdWUY
BCABKAhCA+BBAUgAUglib29sVmFsdWUSWwoRc3RyaW5nX2xpc3RfdmFsdWUYBSABKAsyKC5n
b29nbGUuY2xvdWQuYXVkaXRtYW5hZ2VyLnYxLlN0cmluZ0xpc3RCA+BBAUgAUg9zdHJpbmdM
aXN0VmFsdWUSKAoMbnVtYmVyX3ZhbHVlGAYgASgBQgPgQQFIAFILbnVtYmVyVmFsdWUSTwoL
b25lb2ZfdmFsdWUYByABKAsyJy5nb29nbGUuY2xvdWQuYXVkaXRtYW5hZ2VyLnYxLlBhcmFt
ZXRlckID4EEBSABSCm9uZW9mVmFsdWVCBgoEa2luZCJdChJQYXJhbWV0ZXJPdmVycmlkZXMS
RwoKcGFyYW1ldGVycxgBIAMoCzInLmdvb2dsZS5jbG91ZC5hdWRpdG1hbmFnZXIudjEuUGFy
YW1ldGVyUgpwYXJhbWV0ZXJzIoYBCg5QYXJhbWV0ZXJTdGF0ZRJKCglwYXJhbWV0ZXIYASAB
KAsyJy5nb29nbGUuY2xvdWQuYXVkaXRtYW5hZ2VyLnYxLlBhcmFtZXRlckID4EEDUglwYXJh
bWV0ZXISKAoNaXNfb3ZlcnJpZGRlbhgCIAEoCEID4EEDUgxpc092ZXJyaWRkZW4iewobQ2xv
dWRDb250cm9sUGFyYW1ldGVyU3RhdGVzElwKEHBhcmFtZXRlcl9zdGF0ZXMYASADKAsyLC5n
b29nbGUuY2xvdWQuYXVkaXRtYW5hZ2VyLnYxLlBhcmFtZXRlclN0YXRlQgPgQQNSD3BhcmFt
ZXRlclN0YXRlc0LbAQogY29tLmdvb2dsZS5jbG91ZC5hdWRpdG1hbmFnZXIudjFCD1BhcmFt
ZXRlcnNQcm90b1ABWkRjbG91ZC5nb29nbGUuY29tL2dvL2F1ZGl0bWFuYWdlci9hcGl2MS9h
dWRpdG1hbmFnZXJwYjthdWRpdG1hbmFnZXJwYqoCHEdvb2dsZS5DbG91ZC5BdWRpdE1hbmFn
ZXIuVjHKAhxHb29nbGVcQ2xvdWRcQXVkaXRNYW5hZ2VyXFYx6gIfR29vZ2xlOjpDbG91ZDo6
QXVkaXRNYW5hZ2VyOjpWMUqeFwoGEgQOAFgBCrwECgEMEgMOABIysQQgQ29weXJpZ2h0IDIw
MjYgR29vZ2xlIExMQwoKIExpY2Vuc2VkIHVuZGVyIHRoZSBBcGFjaGUgTGljZW5zZSwgVmVy
c2lvbiAyLjAgKHRoZSAiTGljZW5zZSIpOwogeW91IG1heSBub3QgdXNlIHRoaXMgZmlsZSBl
eGNlcHQgaW4gY29tcGxpYW5jZSB3aXRoIHRoZSBMaWNlbnNlLgogWW91IG1heSBvYnRhaW4g
YSBjb3B5IG9mIHRoZSBMaWNlbnNlIGF0CgogICAgIGh0dHA6Ly93d3cuYXBhY2hlLm9yZy9s
aWNlbnNlcy9MSUNFTlNFLTIuMAoKIFVubGVzcyByZXF1aXJlZCBieSBhcHBsaWNhYmxlIGxh
dyBvciBhZ3JlZWQgdG8gaW4gd3JpdGluZywgc29mdHdhcmUKIGRpc3RyaWJ1dGVkIHVuZGVy
IHRoZSBMaWNlbnNlIGlzIGRpc3RyaWJ1dGVkIG9uIGFuICJBUyBJUyIgQkFTSVMsCiBXSVRI
T1VUIFdBUlJBTlRJRVMgT1IgQ09ORElUSU9OUyBPRiBBTlkgS0lORCwgZWl0aGVyIGV4cHJl
c3Mgb3IgaW1wbGllZC4KIFNlZSB0aGUgTGljZW5zZSBmb3IgdGhlIHNwZWNpZmljIGxhbmd1
YWdlIGdvdmVybmluZyBwZXJtaXNzaW9ucyBhbmQKIGxpbWl0YXRpb25zIHVuZGVyIHRoZSBM
aWNlbnNlLgoKCAoBAhIDEAAlCgkKAgMAEgMSACkKCQoCAwESAxMAIwoICgEIEgMVADkKCQoC
CCUSAxUAOQoICgEIEgMWAFsKCQoCCAsSAxYAWwoICgEIEgMXACIKCQoCCAoSAxcAIgoICgEI
EgMYADAKCQoCCAgSAxgAMAoICgEIEgMZADkKCQoCCAESAxkAOQoICgEIEgMaADkKCQoCCCkS
AxoAOQoICgEIEgMbADgKCQoCCC0SAxsAOAq7AQoCBAASBCAAJgEargEgUGFyYW1ldGVycyBh
cmUga2V5LXZhbHVlIHBhaXJzIHRoYXQgbGV0IHlvdSBwcm92aWRlIHlvdXIgY3VzdG9tIGxv
Y2F0aW9uCiByZXF1aXJlbWVudHMsIGVudmlyb25tZW50IHJlcXVpcmVtZW50cywgb3Igb3Ro
ZXIgc2V0dGluZ3MgdGhhdCBhcmUKIHJlbGV2YW50IHRvIHRoZSBjbG91ZCBjb250cm9sLgoK
CgoDBAABEgMgCBEKOgoEBAACABIDIgI7Gi0gUmVxdWlyZWQuIFRoZSBuYW1lIG9yIGtleSBv
ZiB0aGUgcGFyYW1ldGVyLgoKDAoFBAACAAUSAyICCAoMCgUEAAIAARIDIgkNCgwKBQQAAgAD
EgMiEBEKDAoFBAACAAgSAyISOgoPCggEAAIACJwIABIDIhM5CjQKBAQAAgESAyUCShonIFJl
cXVpcmVkLiBUaGUgdmFsdWUgb2YgdGhlIHBhcmFtZXRlci4KCgwKBQQAAgEGEgMlAgwKDAoF
BAACAQESAyUNHAoMCgUEAAIBAxIDJR8gCgwKBQQAAgEIEgMlIUkKDwoIBAACAQicCAASAyUi
SAo4CgIEARIEKQAsARosIEEgbGlzdCBvZiBzdHJpbmdzIGZvciB0aGUgcGFyYW1ldGVyIHZh
bHVlLgoKCgoDBAEBEgMpCBIKMQoEBAECABIDKwJGGiQgUmVxdWlyZWQuIFRoZSBzdHJpbmdz
IGluIHRoZSBsaXN0LgoKDAoFBAECAAQSAysCCgoMCgUEAQIABRIDKwsRCgwKBQQBAgABEgMr
EhgKDAoFBAECAAMSAysbHAoMCgUEAQIACBIDKx1FCg8KCAQBAgAInAgAEgMrHkQKMQoCBAIS
BC8AQQEaJSBUaGUgcG9zc2libGUgcGFyYW1ldGVyIHZhbHVlIHR5cGVzLgoKCgoDBAIBEgMv
CBIKOwoEBAIIABIEMQJAAxotIFRoZSBsaXN0IG9mIHBvc3NpYmxlIHBhcmFtZXRlciB2YWx1
ZSB0eXBlcy4KCgwKBQQCCAABEgMxCAwKKAoEBAICABIDMwRFGhsgT3B0aW9uYWwuIEEgc3Ry
aW5nIHZhbHVlLgoKDAoFBAICAAUSAzMECgoMCgUEAgIAARIDMwsXCgwKBQQCAgADEgMzGhsK
DAoFBAICAAgSAzMcRAoPCggEAgIACJwIABIDMx1DCikKBAQCAgESAzYEQRocIE9wdGlvbmFs
LiBBIGJvb2xlYW4gdmFsdWUuCgoMCgUEAgIBBRIDNgQICgwKBQQCAgEBEgM2CRMKDAoFBAIC
AQMSAzYWFwoMCgUEAgIBCBIDNhhACg8KCAQCAgEInAgAEgM2GT8KKwoEBAICAhIDOQROGh4g
T3B0aW9uYWwuIEEgcmVwZWF0ZWQgc3RyaW5nLgoKDAoFBAICAgYSAzkEDgoMCgUEAgICARID
OQ8gCgwKBQQCAgIDEgM5IyQKDAoFBAICAggSAzklTQoPCggEAgICCJwIABIDOSZMCigKBAQC
AgMSAzwERRobIE9wdGlvbmFsLiBBIGRvdWJsZSB2YWx1ZS4KCgwKBQQCAgMFEgM8BAoKDAoF
BAICAwESAzwLFwoMCgUEAgIDAxIDPBobCgwKBQQCAgMIEgM8HEQKDwoIBAICAwicCAASAzwd
QwouCgQEAgIEEgM/BEcaISBPcHRpb25hbC4gU3ViLXBhcmFtZXRlciB2YWx1ZXMuCgoMCgUE
AgIEBhIDPwQNCgwKBQQCAgQBEgM/DhkKDAoFBAICBAMSAz8cHQoMCgUEAgIECBIDPx5GCg8K
CAQCAgQInAgAEgM/H0UKawoCBAMSBEUASAEaXyBXcmFwcGVyIG1lc3NhZ2UgdG8gYXNzb2Np
YXRlIGEgbGlzdCBvZiBDU0MgaW50ZXJuYWwgcGFyYW1ldGVyIG92ZXJyaWRlcyB3aXRoCiBh
IGNvbnRyb2wgbmFtZS4KCgoKAwQDARIDRQgaCi8KBAQDAgASA0cCJBoiIFRoZSBsaXN0IG9m
IHBhcmFtZXRlciBvdmVycmlkZXMuCgoMCgUEAwIABBIDRwIKCgwKBQQDAgAGEgNHCxQKDAoF
BAMCAAESA0cVHwoMCgUEAwIAAxIDRyIjCjcKAgQEEgRLAFEBGisgU3RhdGUgb2YgYSBwYXJh
bWV0ZXIgZm9yIGEgY2xvdWQgY29udHJvbC4KCgoKAwQEARIDSwgWCjgKBAQEAgASA00CRhor
IE91dHB1dCBvbmx5LiBUaGUgcGFyYW1ldGVyIGtleSBhbmQgdmFsdWUuCgoMCgUEBAIABhID
TQILCgwKBQQEAgABEgNNDBUKDAoFBAQCAAMSA00YGQoMCgUEBAIACBIDTRpFCg8KCAQEAgAI
nAgAEgNNG0QKTgoEBAQCARIDUAJFGkEgT3V0cHV0IG9ubHkuIFdoZXRoZXIgdGhpcyBwYXJh
bWV0ZXIgd2FzIG92ZXJyaWRkZW4gYnkgdGhlIHVzZXIuCgoMCgUEBAIBBRIDUAIGCgwKBQQE
AgEBEgNQBxQKDAoFBAQCAQMSA1AXGAoMCgUEBAIBCBIDUBlECg8KCAQEAgEInAgAEgNQGkMK
QQoCBAUSBFQAWAEaNSBDb2xsZWN0aW9uIG9mIHBhcmFtZXRlciBzdGF0ZXMgZm9yIGEgY2xv
dWQgY29udHJvbC4KCgoKAwQFARIDVAgjCkgKBAQFAgASBFYCVzIaOiBPdXRwdXQgb25seS4g
VGhlIHBhcmFtZXRlciBzdGF0ZXMgZm9yIHRoZSBjbG91ZCBjb250cm9sLgoKDAoFBAUCAAQS
A1YCCgoMCgUEBQIABhIDVgsZCgwKBQQFAgABEgNWGioKDAoFBAUCAAMSA1YtLgoMCgUEBQIA
CBIDVwYxCg8KCAQFAgAInAgAEgNXBzBiBnByb3RvMw==
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Auditmanager::V1::Parameters::Parameter ===
    # Fields for Parameter
    # Field: name Type: 9 ()
    # Field: parameter_value Type: 11 (.google.cloud.auditmanager.v1.ParamValue)

# === Message: Google::Cloud::Auditmanager::V1::Parameters::StringList ===
    # Fields for StringList
    # Field: values Type: 9 ()

# === Message: Google::Cloud::Auditmanager::V1::Parameters::ParamValue ===
    # Fields for ParamValue
    # Field: string_value Type: 9 ()
    # Field: bool_value Type: 8 ()
    # Field: string_list_value Type: 11 (.google.cloud.auditmanager.v1.StringList)
    # Field: number_value Type: 1 ()
    # Field: oneof_value Type: 11 (.google.cloud.auditmanager.v1.Parameter)

# === Message: Google::Cloud::Auditmanager::V1::Parameters::ParameterOverrides ===
    # Fields for ParameterOverrides
    # Field: parameters Type: 11 (.google.cloud.auditmanager.v1.Parameter)

# === Message: Google::Cloud::Auditmanager::V1::Parameters::ParameterState ===
    # Fields for ParameterState
    # Field: parameter Type: 11 (.google.cloud.auditmanager.v1.Parameter)
    # Field: is_overridden Type: 8 ()

# === Message: Google::Cloud::Auditmanager::V1::Parameters::CloudControlParameterStates ===
    # Fields for CloudControlParameterStates
    # Field: parameter_states Type: 11 (.google.cloud.auditmanager.v1.ParameterState)

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Auditmanager::V1::Parameters - Compiled Protocol Buffers messages for google/cloud/auditmanager/v1/parameters.proto

=head1 SYNOPSIS

    use Google::Cloud::Auditmanager::V1::Parameters;

    my $msg = Google::Cloud::Auditmanager::V1::Parameters::Parameter->new({
        name => $name,
        parameter_value => $parameter_value,
    });

    # Read or update a field
    my $val = $msg->name();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Auditmanager::V1::Parameters::Parameter->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/auditmanager/v1/parameters.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Auditmanager::V1::Parameters::Parameter

Parameters are key-value pairs that let you provide your custom location
requirements, environment requirements, or other settings that are
relevant to the cloud control.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. The name or key of the parameter.

=item * C<< $msg->parameter_value() >> / C<< $msg->parameter_value($value) >>

Type: C<Message> (L<Google::Cloud::Auditmanager::V1::Parameters::ParamValue>)

Required. The value of the parameter.

=back

=head2 Google::Cloud::Auditmanager::V1::Parameters::StringList

A list of strings for the parameter value.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->values() >> / C<< $msg->values($value) >>

Type: C<String>

Required. The strings in the list.

=back

=head2 Google::Cloud::Auditmanager::V1::Parameters::ParamValue

The possible parameter value types.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->string_value() >> / C<< $msg->string_value($value) >>

Type: C<String>

Optional. A string value.

=item * C<< $msg->bool_value() >> / C<< $msg->bool_value($value) >>

Type: C<Bool>

Optional. A boolean value.

=item * C<< $msg->string_list_value() >> / C<< $msg->string_list_value($value) >>

Type: C<Message> (L<Google::Cloud::Auditmanager::V1::Parameters::StringList>)

Optional. A repeated string.

=item * C<< $msg->number_value() >> / C<< $msg->number_value($value) >>

Type: C<Double>

Optional. A double value.

=item * C<< $msg->oneof_value() >> / C<< $msg->oneof_value($value) >>

Type: C<Message> (L<Google::Cloud::Auditmanager::V1::Parameters::Parameter>)

Optional. Sub-parameter values.

=back

=head2 Google::Cloud::Auditmanager::V1::Parameters::ParameterOverrides

Wrapper message to associate a list of CSC internal parameter overrides with
a control name.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->parameters() >> / C<< $msg->parameters($value) >>

Type: C<Message> (L<Google::Cloud::Auditmanager::V1::Parameters::Parameter>)

The list of parameter overrides.

=back

=head2 Google::Cloud::Auditmanager::V1::Parameters::ParameterState

State of a parameter for a cloud control.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->parameter() >> / C<< $msg->parameter($value) >>

Type: C<Message> (L<Google::Cloud::Auditmanager::V1::Parameters::Parameter>)

Output only. The parameter key and value.

=item * C<< $msg->is_overridden() >> / C<< $msg->is_overridden($value) >>

Type: C<Bool>

Output only. Whether this parameter was overridden by the user.

=back

=head2 Google::Cloud::Auditmanager::V1::Parameters::CloudControlParameterStates

Collection of parameter states for a cloud control.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->parameter_states() >> / C<< $msg->parameter_states($value) >>

Type: C<Message> (L<Google::Cloud::Auditmanager::V1::Parameters::ParameterState>)

Output only. The parameter states for the cloud control.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Auditmanager::V1::Parameters::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
