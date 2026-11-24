package Google::Cloud::Designcenter::V1::Parameters;

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
    eval { require Google::Protobuf::Struct };
    my $descriptor_b64 = <<'EOF';
Ci1nb29nbGUvY2xvdWQvZGVzaWduY2VudGVyL3YxL3BhcmFtZXRlcnMucHJvdG8SHGdvb2ds
ZS5jbG91ZC5kZXNpZ25jZW50ZXIudjEaH2dvb2dsZS9hcGkvZmllbGRfYmVoYXZpb3IucHJv
dG8aGWdvb2dsZS9hcGkvcmVzb3VyY2UucHJvdG8aHGdvb2dsZS9wcm90b2J1Zi9zdHJ1Y3Qu
cHJvdG8iXgoRQ29tcG9uZW50VmFyaWFibGUSHwoIdmFyaWFibGUYASABKAlCA+BBAlIIdmFy
aWFibGUSKAoNY29tcG9uZW50X3VyaRgCIAEoCUID4EECUgxjb21wb25lbnRVcmkiOAoSU2Fh
U1J1bnRpbWVDb250ZXh0EiIKCnNhYXNfbmFtZXMYASADKAlCA+BBAVIJc2Fhc05hbWVzIokB
ChRDb25uZWN0aW9uUGFyYW1ldGVycxIjCgpjb25uZWN0aW9uGAEgASgJQgPgQQJSCmNvbm5l
Y3Rpb24STAoKcGFyYW1ldGVycxgCIAMoCzInLmdvb2dsZS5jbG91ZC5kZXNpZ25jZW50ZXIu
djEuUGFyYW1ldGVyQgPgQQFSCnBhcmFtZXRlcnMisgEKGENvbXBvbmVudFBhcmFtZXRlclNj
aGVtYRIVCgNrZXkYASABKAlCA+BBA1IDa2V5EkAKDWRlZmF1bHRfdmFsdWUYAiABKAsyFi5n
b29nbGUucHJvdG9idWYuVmFsdWVCA+BBA1IMZGVmYXVsdFZhbHVlEiQKC2lzX3JlcXVpcmVk
GAMgASgIQgPgQQNSCmlzUmVxdWlyZWQSFwoEdHlwZRgEIAEoCUID4EEDUgR0eXBlIncKCVBh
cmFtZXRlchIVCgNrZXkYASABKAlCA+BBAlIDa2V5EjEKBXZhbHVlGAIgASgLMhYuZ29vZ2xl
LnByb3RvYnVmLlZhbHVlQgPgQQFSBXZhbHVlEiAKCXJlYWRfb25seRgEIAEoCEID4EEDUghy
ZWFkT25seSLEAQoSQ2xvdWRDb250cm9sQ29uZmlnEmAKDWNsb3VkX2NvbnRyb2wYASABKAlC
O+BBAvpBNQozY2xvdWRzZWN1cml0eWNvbXBsaWFuY2UuZ29vZ2xlYXBpcy5jb20vQ2xvdWRD
b250cm9sUgxjbG91ZENvbnRyb2wSTAoKcGFyYW1ldGVycxgCIAMoCzInLmdvb2dsZS5jbG91
ZC5kZXNpZ25jZW50ZXIudjEuUGFyYW1ldGVyQgPgQQFSCnBhcmFtZXRlcnNC2wEKIGNvbS5n
b29nbGUuY2xvdWQuZGVzaWduY2VudGVyLnYxQg9QYXJhbWV0ZXJzUHJvdG9QAVpEY2xvdWQu
Z29vZ2xlLmNvbS9nby9kZXNpZ25jZW50ZXIvYXBpdjEvZGVzaWduY2VudGVycGI7ZGVzaWdu
Y2VudGVycGKqAhxHb29nbGUuQ2xvdWQuRGVzaWduQ2VudGVyLlYxygIcR29vZ2xlXENsb3Vk
XERlc2lnbkNlbnRlclxWMeoCH0dvb2dsZTo6Q2xvdWQ6OkRlc2lnbkNlbnRlcjo6VjFKwxsK
BhIEDgBmAQq8BAoBDBIDDgASMrEEIENvcHlyaWdodCAyMDI2IEdvb2dsZSBMTEMKCiBMaWNl
bnNlZCB1bmRlciB0aGUgQXBhY2hlIExpY2Vuc2UsIFZlcnNpb24gMi4wICh0aGUgIkxpY2Vu
c2UiKTsKIHlvdSBtYXkgbm90IHVzZSB0aGlzIGZpbGUgZXhjZXB0IGluIGNvbXBsaWFuY2Ug
d2l0aCB0aGUgTGljZW5zZS4KIFlvdSBtYXkgb2J0YWluIGEgY29weSBvZiB0aGUgTGljZW5z
ZSBhdAoKICAgICBodHRwOi8vd3d3LmFwYWNoZS5vcmcvbGljZW5zZXMvTElDRU5TRS0yLjAK
CiBVbmxlc3MgcmVxdWlyZWQgYnkgYXBwbGljYWJsZSBsYXcgb3IgYWdyZWVkIHRvIGluIHdy
aXRpbmcsIHNvZnR3YXJlCiBkaXN0cmlidXRlZCB1bmRlciB0aGUgTGljZW5zZSBpcyBkaXN0
cmlidXRlZCBvbiBhbiAiQVMgSVMiIEJBU0lTLAogV0lUSE9VVCBXQVJSQU5USUVTIE9SIENP
TkRJVElPTlMgT0YgQU5ZIEtJTkQsIGVpdGhlciBleHByZXNzIG9yIGltcGxpZWQuCiBTZWUg
dGhlIExpY2Vuc2UgZm9yIHRoZSBzcGVjaWZpYyBsYW5ndWFnZSBnb3Zlcm5pbmcgcGVybWlz
c2lvbnMgYW5kCiBsaW1pdGF0aW9ucyB1bmRlciB0aGUgTGljZW5zZS4KCggKAQISAxAAJQoJ
CgIDABIDEgApCgkKAgMBEgMTACMKCQoCAwISAxQAJgoICgEIEgMWADkKCQoCCCUSAxYAOQoI
CgEIEgMXAFsKCQoCCAsSAxcAWwoICgEIEgMYACIKCQoCCAoSAxgAIgoICgEIEgMZADAKCQoC
CAgSAxkAMAoICgEIEgMaADkKCQoCCAESAxoAOQoICgEIEgMbADkKCQoCCCkSAxsAOQoICgEI
EgMcADgKCQoCCC0SAxwAOAphCgIEABIEIAAmARpVIFRoZSBkZXRhaWxzIG9mIGFuIGlucHV0
L291dHB1dCB2YXJpYWJsZTogdGhlIHZhcmlhYmxlIGFuZCB0aGUgY29tcG9uZW50IFVyaS4K
IG5hbWUuCgoKCgMEAAESAyAIGQouCgQEAAIAEgMiAj8aISBSZXF1aXJlZC4gTmFtZSBvZiB0
aGUgdmFyaWFibGUuCgoMCgUEAAIABRIDIgIICgwKBQQAAgABEgMiCREKDAoFBAACAAMSAyIU
FQoMCgUEAAIACBIDIhY+Cg8KCAQAAgAInAgAEgMiFz0KQgoEBAACARIDJQJEGjUgUmVxdWly
ZWQuIENvbXBvbmVudCB0byB3aGljaCB0aGlzIHZhcmlhYmxlIGJlbG9uZ3MuCgoMCgUEAAIB
BRIDJQIICgwKBQQAAgEBEgMlCRYKDAoFBAACAQMSAyUZGgoMCgUEAAIBCBIDJRtDCg8KCAQA
AgEInAgAEgMlHEIKIwoCBAESBCkALQEaFyBTYWFTIHJ1bnRpbWUgY29udGV4dC4KCgoKAwQB
ARIDKQgaCnMKBAQBAgASAywCShpmIE9wdGlvbmFsLiBUaGUgU2FhUyBuYW1lcy4gRm9ybWF0
IGZvciBlYWNoIFNhYVM6CiBwcm9qZWN0cy97cHJvamVjdH0vbG9jYXRpb25zL3tsb2NhdGlv
bn0vc2Fhcy97c2Fhc30KCgwKBQQBAgAEEgMsAgoKDAoFBAECAAUSAywLEQoMCgUEAQIAARID
LBIcCgwKBQQBAgADEgMsHyAKDAoFBAECAAgSAywhSQoPCggEAQIACJwIABIDLCJICmAKAgQC
EgQxADcBGlQgQ29ubmVjdGlvbiBsZXZlbCBwYXJhbWV0ZXJzIGFzc29jaWF0ZWQgd2l0aCBl
YWNoIGNvbXBvbmVudCB3aXRoaW4gYW4KIGFwcGxpY2F0aW9uLgoKCgoDBAIBEgMxCBwKPgoE
BAICABIDMwJBGjEgUmVxdWlyZWQuIFRoZSBuYW1lIG9mIHRoZSBjb25uZWN0aW9uIHBhcmFt
ZXRlci4KCgwKBQQCAgAFEgMzAggKDAoFBAICAAESAzMJEwoMCgUEAgIAAxIDMxYXCgwKBQQC
AgAIEgMzGEAKDwoIBAICAAicCAASAzMZPwpNCgQEAgIBEgM2Ak0aQCBPcHRpb25hbC4gQSBs
aXN0IG9mIHBhcmFtZXRlcnMgYXNzb2NpYXRlZCB3aXRoIHRoZSBjb25uZWN0aW9uLgoKDAoF
BAICAQQSAzYCCgoMCgUEAgIBBhIDNgsUCgwKBQQCAgEBEgM2FR8KDAoFBAICAQMSAzYiIwoM
CgUEAgIBCBIDNiRMCg8KCAQCAgEInAgAEgM2JUsKXQoCBAMSBDsASAEaUSBDb21wb25lbnQg
cGFyYW1ldGVyIHNjaGVtYSwgd2hpY2ggY29udGFpbnMgYSBsaXN0IG9mIGFsbCBjb21wb25l
bnQKIHBhcmFtZXRlcnMuCgoKCgMEAwESAzsIIAo1CgQEAwIAEgM9Aj0aKCBPdXRwdXQgb25s
eS4gVGhlIGtleSBvZiB0aGUgcGFyYW1ldGVyLgoKDAoFBAMCAAUSAz0CCAoMCgUEAwIAARID
PQkMCgwKBQQDAgADEgM9DxAKDAoFBAMCAAgSAz0RPAoPCggEAwIACJwIABIDPRI7CkAKBAQD
AgESBEACQTIaMiBPdXRwdXQgb25seS4gVGhlIGRlZmF1bHQgdmFsdWUgb2YgdGhlIHBhcmFt
ZXRlci4KCgwKBQQDAgEGEgNAAhcKDAoFBAMCAQESA0AYJQoMCgUEAwIBAxIDQCgpCgwKBQQD
AgEIEgNBBjEKDwoIBAMCAQicCAASA0EHMAo+CgQEAwICEgNEAkMaMSBPdXRwdXQgb25seS4g
V2hldGhlciB0aGUgcGFyYW1ldGVyIGlzIHJlcXVpcmVkLgoKDAoFBAMCAgUSA0QCBgoMCgUE
AwICARIDRAcSCgwKBQQDAgIDEgNEFRYKDAoFBAMCAggSA0QXQgoPCggEAwICCJwIABIDRBhB
CjYKBAQDAgMSA0cCPhopIE91dHB1dCBvbmx5LiBUaGUgdHlwZSBvZiB0aGUgcGFyYW1ldGVy
LgoKDAoFBAMCAwUSA0cCCAoMCgUEAwIDARIDRwkNCgwKBQQDAgMDEgNHEBEKDAoFBAMCAwgS
A0cSPQoPCggEAwIDCJwIABIDRxM8CiEKAgQEEgRLAFUBGhUgUGFyYW1ldGVyIHJlc291cmNl
LgoKCgoDBAQBEgNLCBEKMgoEBAQCABIDTQI6GiUgUmVxdWlyZWQuIFRoZSBrZXkgb2YgdGhl
IHBhcmFtZXRlci4KCgwKBQQEAgAFEgNNAggKDAoFBAQCAAESA00JDAoMCgUEBAIAAxIDTQ8Q
CgwKBQQEAgAIEgNNETkKDwoIBAQCAAicCAASA00SOAo0CgQEBAIBEgNQAksaJyBPcHRpb25h
bC4gVGhlIHZhbHVlIG9mIHRoZSBwYXJhbWV0ZXIuCgoMCgUEBAIBBhIDUAIXCgwKBQQEAgEB
EgNQGB0KDAoFBAQCAQMSA1AgIQoMCgUEBAIBCBIDUCJKCg8KCAQEAgEInAgAEgNQI0kKXAoE
BAQCAhIDVAJBGk8gT3V0cHV0IG9ubHkuIEluZGljYXRlcyBpZiB0aGUgcGFyYW1ldGVyIGlz
IHJlYWQtb25seSAoZHJpdmVuIGJ5CiBleHByZXNzaW9uKS4KCgwKBQQEAgIFEgNUAgYKDAoF
BAQCAgESA1QHEAoMCgUEBAICAxIDVBMUCgwKBQQEAgIIEgNUFUAKDwoIBAQCAgicCAASA1QW
PwpNCgIEBRIEWABmARpBIFBhcmFtZXRlciB2YWx1ZXMgc3RvcmVkIGZvciBhIHNpbmdsZSBj
bG91ZCBjb250cm9sIG9mIGEgcG9saWN5LgoKCgoDBAUBEgNYCBoKhwIKBAQFAgASBF0CYgQa
+AEgUmVxdWlyZWQuIFJlc291cmNlIG5hbWUgb2YgdGhlIGNsb3VkIGNvbnRyb2wgdGhhdCB0
aGVzZSBwYXJhbWV0ZXIgdmFsdWVzCiBhcHBseSB0by4gRm9ybWF0Ogogb3JnYW5pemF0aW9u
cy97b3JnYW5pemF0aW9ufS9sb2NhdGlvbnMve2xvY2F0aW9ufS9jbG91ZENvbnRyb2xzL3tj
bG91ZF9jb250cm9sfQogb3IgcHJvamVjdHMve3Byb2plY3R9L2xvY2F0aW9ucy97bG9jYXRp
b259L2Nsb3VkQ29udHJvbHMve2Nsb3VkX2NvbnRyb2x9CgoMCgUEBQIABRIDXQIICgwKBQQF
AgABEgNdCRYKDAoFBAUCAAMSA10ZGgoNCgUEBQIACBIEXRtiAwoPCggEBQIACJwIABIDXgQq
Cg8KBwQFAgAInwgSBF8EYQUKRAoEBAUCARIDZQJNGjcgT3B0aW9uYWwuIFBhcmFtZXRlciB2
YWx1ZXMgZm9yIHRoaXMgc3BlY2lmaWMgY29udHJvbC4KCgwKBQQFAgEEEgNlAgoKDAoFBAUC
AQYSA2ULFAoMCgUEBQIBARIDZRUfCgwKBQQFAgEDEgNlIiMKDAoFBAUCAQgSA2UkTAoPCggE
BQIBCJwIABIDZSVLYgZwcm90bzM=
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Designcenter::V1::Parameters::ComponentVariable ===
    # Fields for ComponentVariable
    # Field: variable Type: 9 ()
    # Field: component_uri Type: 9 ()

# === Message: Google::Cloud::Designcenter::V1::Parameters::SaaSRuntimeContext ===
    # Fields for SaaSRuntimeContext
    # Field: saas_names Type: 9 ()

# === Message: Google::Cloud::Designcenter::V1::Parameters::ConnectionParameters ===
    # Fields for ConnectionParameters
    # Field: connection Type: 9 ()
    # Field: parameters Type: 11 (.google.cloud.designcenter.v1.Parameter)

# === Message: Google::Cloud::Designcenter::V1::Parameters::ComponentParameterSchema ===
    # Fields for ComponentParameterSchema
    # Field: key Type: 9 ()
    # Field: default_value Type: 11 (.google.protobuf.Value)
    # Field: is_required Type: 8 ()
    # Field: type Type: 9 ()

# === Message: Google::Cloud::Designcenter::V1::Parameters::Parameter ===
    # Fields for Parameter
    # Field: key Type: 9 ()
    # Field: value Type: 11 (.google.protobuf.Value)
    # Field: read_only Type: 8 ()

# === Message: Google::Cloud::Designcenter::V1::Parameters::CloudControlConfig ===
    # Fields for CloudControlConfig
    # Field: cloud_control Type: 9 ()
    # Field: parameters Type: 11 (.google.cloud.designcenter.v1.Parameter)

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Designcenter::V1::Parameters - Compiled Protocol Buffers messages for google/cloud/designcenter/v1/parameters.proto

=head1 SYNOPSIS

    use Google::Cloud::Designcenter::V1::Parameters;

    my $msg = Google::Cloud::Designcenter::V1::Parameters::ComponentVariable->new({
        variable => $variable,
        component_uri => $component_uri,
    });

    # Read or update a field
    my $val = $msg->variable();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Designcenter::V1::Parameters::ComponentVariable->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/designcenter/v1/parameters.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Designcenter::V1::Parameters::ComponentVariable

The details of an input/output variable: the variable and the component Uri.
name.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->variable() >> / C<< $msg->variable($value) >>

Type: C<String>

Required. Name of the variable.

=item * C<< $msg->component_uri() >> / C<< $msg->component_uri($value) >>

Type: C<String>

Required. Component to which this variable belongs.

=back

=head2 Google::Cloud::Designcenter::V1::Parameters::SaaSRuntimeContext

SaaS runtime context.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->saas_names() >> / C<< $msg->saas_names($value) >>

Type: C<String>

Optional. The SaaS names. Format for each SaaS:
projects/{project}/locations/{location}/saas/{saas}

=back

=head2 Google::Cloud::Designcenter::V1::Parameters::ConnectionParameters

Connection level parameters associated with each component within an
application.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->connection() >> / C<< $msg->connection($value) >>

Type: C<String>

Required. The name of the connection parameter.

=item * C<< $msg->parameters() >> / C<< $msg->parameters($value) >>

Type: C<Message> (L<Google::Cloud::Designcenter::V1::Parameters::Parameter>)

Optional. A list of parameters associated with the connection.

=back

=head2 Google::Cloud::Designcenter::V1::Parameters::ComponentParameterSchema

Component parameter schema, which contains a list of all component
parameters.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->key() >> / C<< $msg->key($value) >>

Type: C<String>

Output only. The key of the parameter.

=item * C<< $msg->default_value() >> / C<< $msg->default_value($value) >>

Type: C<Message> (L<Google::Protobuf::Struct::Value>)

Output only. The default value of the parameter.

=item * C<< $msg->is_required() >> / C<< $msg->is_required($value) >>

Type: C<Bool>

Output only. Whether the parameter is required.

=item * C<< $msg->type() >> / C<< $msg->type($value) >>

Type: C<String>

Output only. The type of the parameter.

=back

=head2 Google::Cloud::Designcenter::V1::Parameters::Parameter

Parameter resource.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->key() >> / C<< $msg->key($value) >>

Type: C<String>

Required. The key of the parameter.

=item * C<< $msg->value() >> / C<< $msg->value($value) >>

Type: C<Message> (L<Google::Protobuf::Struct::Value>)

Optional. The value of the parameter.

=item * C<< $msg->read_only() >> / C<< $msg->read_only($value) >>

Type: C<Bool>

Output only. Indicates if the parameter is read-only (driven by
expression).

=back

=head2 Google::Cloud::Designcenter::V1::Parameters::CloudControlConfig

Parameter values stored for a single cloud control of a policy.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->cloud_control() >> / C<< $msg->cloud_control($value) >>

Type: C<String>

Required. Resource name of the cloud control that these parameter values
apply to. Format:
organizations/{organization}/locations/{location}/cloudControls/{cloud_control}
or projects/{project}/locations/{location}/cloudControls/{cloud_control}

=item * C<< $msg->parameters() >> / C<< $msg->parameters($value) >>

Type: C<Message> (L<Google::Cloud::Designcenter::V1::Parameters::Parameter>)

Optional. Parameter values for this specific control.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Designcenter::V1::Parameters::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
