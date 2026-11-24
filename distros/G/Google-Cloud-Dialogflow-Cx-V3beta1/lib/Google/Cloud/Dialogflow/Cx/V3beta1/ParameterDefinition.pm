package Google::Cloud::Dialogflow::Cx::V3beta1::ParameterDefinition;

use strict;
use warnings;

our $VERSION = '0.14';

use Protobuf::Message;
use Protobuf::DescriptorPool;
use Protobuf::Internal qw(:all);
use MIME::Base64;

BEGIN {
    eval { require Google::Api::FieldBehavior };
    my $descriptor_b64 = <<'EOF';
Cj1nb29nbGUvY2xvdWQvZGlhbG9nZmxvdy9jeC92M2JldGExL3BhcmFtZXRlcl9kZWZpbml0
aW9uLnByb3RvEiJnb29nbGUuY2xvdWQuZGlhbG9nZmxvdy5jeC52M2JldGExGh9nb29nbGUv
YXBpL2ZpZWxkX2JlaGF2aW9yLnByb3RvIvsCChNQYXJhbWV0ZXJEZWZpbml0aW9uEhcKBG5h
bWUYASABKAlCA+BBAlIEbmFtZRJdCgR0eXBlGAIgASgOMkUuZ29vZ2xlLmNsb3VkLmRpYWxv
Z2Zsb3cuY3gudjNiZXRhMS5QYXJhbWV0ZXJEZWZpbml0aW9uLlBhcmFtZXRlclR5cGVCAhgB
UgR0eXBlElQKC3R5cGVfc2NoZW1hGAQgASgLMi4uZ29vZ2xlLmNsb3VkLmRpYWxvZ2Zsb3cu
Y3gudjNiZXRhMS5UeXBlU2NoZW1hQgPgQQFSCnR5cGVTY2hlbWESIAoLZGVzY3JpcHRpb24Y
AyABKAlSC2Rlc2NyaXB0aW9uInQKDVBhcmFtZXRlclR5cGUSHgoaUEFSQU1FVEVSX1RZUEVf
VU5TUEVDSUZJRUQQABIKCgZTVFJJTkcQARIKCgZOVU1CRVIQAhILCgdCT09MRUFOEAMSCAoE
TlVMTBAEEgoKBk9CSkVDVBAFEggKBExJU1QQBiKbAgoKVHlwZVNjaGVtYRJXCg1pbmxpbmVf
c2NoZW1hGAEgASgLMjAuZ29vZ2xlLmNsb3VkLmRpYWxvZ2Zsb3cuY3gudjNiZXRhMS5Jbmxp
bmVTY2hlbWFIAFIMaW5saW5lU2NoZW1hEmsKEHNjaGVtYV9yZWZlcmVuY2UYAiABKAsyPi5n
b29nbGUuY2xvdWQuZGlhbG9nZmxvdy5jeC52M2JldGExLlR5cGVTY2hlbWEuU2NoZW1hUmVm
ZXJlbmNlSABSD3NjaGVtYVJlZmVyZW5jZRo9Cg9TY2hlbWFSZWZlcmVuY2USEgoEdG9vbBgB
IAEoCVIEdG9vbBIWCgZzY2hlbWEYAiABKAlSBnNjaGVtYUIICgZzY2hlbWEilgEKDElubGlu
ZVNjaGVtYRJACgR0eXBlGAEgASgOMiwuZ29vZ2xlLmNsb3VkLmRpYWxvZ2Zsb3cuY3gudjNi
ZXRhMS5EYXRhVHlwZVIEdHlwZRJECgVpdGVtcxgCIAEoCzIuLmdvb2dsZS5jbG91ZC5kaWFs
b2dmbG93LmN4LnYzYmV0YTEuVHlwZVNjaGVtYVIFaXRlbXMqVQoIRGF0YVR5cGUSGQoVREFU
QV9UWVBFX1VOU1BFQ0lGSUVEEAASCgoGU1RSSU5HEAESCgoGTlVNQkVSEAISCwoHQk9PTEVB
ThADEgkKBUFSUkFZEAZCfAomY29tLmdvb2dsZS5jbG91ZC5kaWFsb2dmbG93LmN4LnYzYmV0
YTFCGFBhcmFtZXRlckRlZmluaXRpb25Qcm90b1ABWjZjbG91ZC5nb29nbGUuY29tL2dvL2Rp
YWxvZ2Zsb3cvY3gvYXBpdjNiZXRhMS9jeHBiO2N4cGJKshwKBhIEDgB2AQq8BAoBDBIDDgAS
MrEEIENvcHlyaWdodCAyMDI2IEdvb2dsZSBMTEMKCiBMaWNlbnNlZCB1bmRlciB0aGUgQXBh
Y2hlIExpY2Vuc2UsIFZlcnNpb24gMi4wICh0aGUgIkxpY2Vuc2UiKTsKIHlvdSBtYXkgbm90
IHVzZSB0aGlzIGZpbGUgZXhjZXB0IGluIGNvbXBsaWFuY2Ugd2l0aCB0aGUgTGljZW5zZS4K
IFlvdSBtYXkgb2J0YWluIGEgY29weSBvZiB0aGUgTGljZW5zZSBhdAoKICAgICBodHRwOi8v
d3d3LmFwYWNoZS5vcmcvbGljZW5zZXMvTElDRU5TRS0yLjAKCiBVbmxlc3MgcmVxdWlyZWQg
YnkgYXBwbGljYWJsZSBsYXcgb3IgYWdyZWVkIHRvIGluIHdyaXRpbmcsIHNvZnR3YXJlCiBk
aXN0cmlidXRlZCB1bmRlciB0aGUgTGljZW5zZSBpcyBkaXN0cmlidXRlZCBvbiBhbiAiQVMg
SVMiIEJBU0lTLAogV0lUSE9VVCBXQVJSQU5USUVTIE9SIENPTkRJVElPTlMgT0YgQU5ZIEtJ
TkQsIGVpdGhlciBleHByZXNzIG9yIGltcGxpZWQuCiBTZWUgdGhlIExpY2Vuc2UgZm9yIHRo
ZSBzcGVjaWZpYyBsYW5ndWFnZSBnb3Zlcm5pbmcgcGVybWlzc2lvbnMgYW5kCiBsaW1pdGF0
aW9ucyB1bmRlciB0aGUgTGljZW5zZS4KCggKAQISAxAAKwoJCgIDABIDEgApCggKAQgSAxQA
TQoJCgIICxIDFABNCggKAQgSAxUAIgoJCgIIChIDFQAiCggKAQgSAxYAOQoJCgIICBIDFgA5
CggKAQgSAxcAPwoJCgIIARIDFwA/CpsBCgIEABIEHABCARqOASBEZWZpbmVzIHRoZSBwcm9w
ZXJ0aWVzIG9mIGEgcGFyYW1ldGVyLgogVXNlZCB0byBkZWZpbmUgcGFyYW1ldGVycyB1c2Vk
IGluIHRoZSBhZ2VudCBhbmQgdGhlCiBpbnB1dCAvIG91dHB1dCBwYXJhbWV0ZXJzIGZvciBl
YWNoIGZ1bGZpbGxtZW50LgoKCgoDBAABEgMcCBsKigEKBAQABAASBCACNQMafCBQYXJhbWV0
ZXIgdHlwZXMgYXJlIHVzZWQgZm9yIHZhbGlkYXRpb24uCiBUaGVzZSB0eXBlcyBhcmUgY29u
c2lzdGVudCB3aXRoCiBbZ29vZ2xlLnByb3RvYnVmLlZhbHVlXVtnb29nbGUucHJvdG9idWYu
VmFsdWVdLgoKDAoFBAAEAAESAyAHFApACgYEAAQAAgASAyIEIxoxIE5vdCBzcGVjaWZpZWQu
IE5vIHZhbGlkYXRpb24gd2lsbCBiZSBwZXJmb3JtZWQuCgoOCgcEAAQAAgABEgMiBB4KDgoH
BAAEAAIAAhIDIiEiCi0KBgQABAACARIDJQQPGh4gUmVwcmVzZW50cyBhbnkgc3RyaW5nIHZh
bHVlLgoKDgoHBAAEAAIBARIDJQQKCg4KBwQABAACAQISAyUNDgotCgYEAAQAAgISAygEDxoe
IFJlcHJlc2VudHMgYW55IG51bWJlciB2YWx1ZS4KCg4KBwQABAACAgESAygECgoOCgcEAAQA
AgICEgMoDQ4KLAoGBAAEAAIDEgMrBBAaHSBSZXByZXNlbnRzIGEgYm9vbGVhbiB2YWx1ZS4K
Cg4KBwQABAACAwESAysECwoOCgcEAAQAAgMCEgMrDg8KKQoGBAAEAAIEEgMuBA0aGiBSZXBy
ZXNlbnRzIGEgbnVsbCB2YWx1ZS4KCg4KBwQABAACBAESAy4ECAoOCgcEAAQAAgQCEgMuCwwK
LQoGBAAEAAIFEgMxBA8aHiBSZXByZXNlbnRzIGFueSBvYmplY3QgdmFsdWUuCgoOCgcEAAQA
AgUBEgMxBAoKDgoHBAAEAAIFAhIDMQ0OCi0KBgQABAACBhIDNAQNGh4gUmVwcmVzZW50cyBh
IHJlcGVhdGVkIHZhbHVlLgoKDgoHBAAEAAIGARIDNAQICg4KBwQABAACBgISAzQLDAorCgQE
AAIAEgM4AjsaHiBSZXF1aXJlZC4gTmFtZSBvZiBwYXJhbWV0ZXIuCgoMCgUEAAIABRIDOAII
CgwKBQQAAgABEgM4CQ0KDAoFBAACAAMSAzgQEQoMCgUEAAIACBIDOBI6Cg8KCAQAAgAInAgA
EgM4EzkKIQoEBAACARIDOwItGhQgVHlwZSBvZiBwYXJhbWV0ZXIuCgoMCgUEAAIBBhIDOwIP
CgwKBQQAAgEBEgM7EBQKDAoFBAACAQMSAzsXGAoMCgUEAAIBCBIDOxksCg0KBgQAAgEIAxID
OxorCjIKBAQAAgISAz4CRholIE9wdGlvbmFsLiBUeXBlIHNjaGVtYSBvZiBwYXJhbWV0ZXIu
CgoMCgUEAAICBhIDPgIMCgwKBQQAAgIBEgM+DRgKDAoFBAACAgMSAz4bHAoMCgUEAAICCBID
Ph1FCg8KCAQAAgIInAgAEgM+HkQKVgoEBAACAxIDQQIZGkkgSHVtYW4tcmVhZGFibGUgZGVz
Y3JpcHRpb24gb2YgdGhlIHBhcmFtZXRlci4gTGltaXRlZCB0byAzMDAgY2hhcmFjdGVycy4K
CgwKBQQAAgMFEgNBAggKDAoFBAACAwESA0EJFAoMCgUEAAIDAxIDQRcYCpsBCgIEARIERgBa
ARqOASBFbmNhcHN1bGF0ZXMgZGlmZmVyZW50IHR5cGUgc2NoZW1hIHZhcmlhdGlvbnM6IGVp
dGhlciBhIHJlZmVyZW5jZSB0byBhbgogYSBzY2hlbWEgdGhhdCdzIGFscmVhZHkgZGVmaW5l
ZCBieSBhIHRvb2wsIG9yIGFuIGlubGluZSBkZWZpbml0aW9uLgoKCgoDBAEBEgNGCBIKPgoE
BAEDABIESAJQAxowIEEgcmVmZXJlbmNlIHRvIHRoZSBzY2hlbWEgb2YgYW4gZXhpc3Rpbmcg
dG9vbC4KCgwKBQQBAwABEgNIChkKmQEKBgQBAwACABIDTAQUGokBIFRoZSB0b29sIHRoYXQg
Y29udGFpbnMgdGhpcyBzY2hlbWEgZGVmaW5pdGlvbi4KIEZvcm1hdDoKIGBwcm9qZWN0cy88
UHJvamVjdElEPi9sb2NhdGlvbnMvPExvY2F0aW9uSUQ+L2FnZW50cy88QWdlbnRJRD4vdG9v
bHMvPFRvb2xJRD5gLgoKDgoHBAEDAAIABRIDTAQKCg4KBwQBAwACAAESA0wLDwoOCgcEAQMA
AgADEgNMEhMKKAoGBAEDAAIBEgNPBBYaGSBUaGUgbmFtZSBvZiB0aGUgc2NoZW1hLgoKDgoH
BAEDAAIBBRIDTwQKCg4KBwQBAwACAQESA08LEQoOCgcEAQMAAgEDEgNPFBUKKAoEBAEIABIE
UwJZAxoaIFRoZSBlbmNhcHN1bGF0ZWQgc2NoZW1hLgoKDAoFBAEIAAESA1MIDgo6CgQEAQIA
EgNVBCMaLSBTZXQgaWYgdGhpcyBpcyBhbiBpbmxpbmUgc2NoZW1hIGRlZmluaXRpb24uCgoM
CgUEAQIABhIDVQQQCgwKBQQBAgABEgNVER4KDAoFBAECAAMSA1UhIgoxCgQEAQIBEgNYBCka
JCBTZXQgaWYgdGhpcyBpcyBhIHNjaGVtYSByZWZlcmVuY2UuCgoMCgUEAQIBBhIDWAQTCgwK
BQQBAgEBEgNYFCQKDAoFBAECAQMSA1gnKAo7CgIEAhIEXQBjARovIEEgdHlwZSBzY2hlbWEg
b2JqZWN0IHRoYXQncyBzcGVjaWZpZWQgaW5saW5lLgoKCgoDBAIBEgNdCBQKJwoEBAICABID
XwIUGhogRGF0YSB0eXBlIG9mIHRoZSBzY2hlbWEuCgoMCgUEAgIABhIDXwIKCgwKBQQCAgAB
EgNfCw8KDAoFBAICAAMSA18SEwo/CgQEAgIBEgNiAhcaMiBTY2hlbWEgb2YgdGhlIGVsZW1l
bnRzIGlmIHRoaXMgaXMgYW4gQVJSQVkgdHlwZS4KCgwKBQQCAgEGEgNiAgwKDAoFBAICAQES
A2INEgoMCgUEAgIBAxIDYhUWCpoBCgIFABIEZwB2ARqNASBEZWZpbmVzIGRhdGEgdHlwZXMg
dGhhdCBhcmUgc3VwcG9ydGVkIGZvciBpbmxpbmVkIHNjaGVtYXMuIFRoZXNlIHR5cGVzIGFy
ZQogY29uc2lzdGVudCB3aXRoIFtnb29nbGUucHJvdG9idWYuVmFsdWVdW2dvb2dsZS5wcm90
b2J1Zi5WYWx1ZV0uCgoKCgMFAAESA2cFDQodCgQFAAIAEgNpAhwaECBOb3Qgc3BlY2lmaWVk
LgoKDAoFBQACAAESA2kCFwoMCgUFAAIAAhIDaRobCisKBAUAAgESA2wCDRoeIFJlcHJlc2Vu
dHMgYW55IHN0cmluZyB2YWx1ZS4KCgwKBQUAAgEBEgNsAggKDAoFBQACAQISA2wLDAorCgQF
AAICEgNvAg0aHiBSZXByZXNlbnRzIGFueSBudW1iZXIgdmFsdWUuCgoMCgUFAAICARIDbwII
CgwKBQUAAgICEgNvCwwKKgoEBQACAxIDcgIOGh0gUmVwcmVzZW50cyBhIGJvb2xlYW4gdmFs
dWUuCgoMCgUFAAIDARIDcgIJCgwKBQUAAgMCEgNyDA0KKwoEBQACBBIDdQIMGh4gUmVwcmVz
ZW50cyBhIHJlcGVhdGVkIHZhbHVlLgoKDAoFBQACBAESA3UCBwoMCgUFAAIEAhIDdQoLYgZw
cm90bzM=
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Dialogflow::Cx::V3beta1::ParameterDefinition::ParameterDefinition ===
    # Fields for ParameterDefinition
    # Field: name Type: 9 ()
    # Field: type Type: 14 (.google.cloud.dialogflow.cx.v3beta1.ParameterDefinition.ParameterType)
    # Field: type_schema Type: 11 (.google.cloud.dialogflow.cx.v3beta1.TypeSchema)
    # Field: description Type: 9 ()

# Enum: ParameterDefinition::ParameterType
our $ParameterDefinition_PARAMETER_TYPE_UNSPECIFIED = 0;
our $ParameterDefinition_STRING = 1;
our $ParameterDefinition_NUMBER = 2;
our $ParameterDefinition_BOOLEAN = 3;
our $ParameterDefinition_NULL = 4;
our $ParameterDefinition_OBJECT = 5;
our $ParameterDefinition_LIST = 6;

# === Message: Google::Cloud::Dialogflow::Cx::V3beta1::ParameterDefinition::TypeSchema ===
    # Fields for TypeSchema
    # Field: inline_schema Type: 11 (.google.cloud.dialogflow.cx.v3beta1.InlineSchema)
    # Field: schema_reference Type: 11 (.google.cloud.dialogflow.cx.v3beta1.TypeSchema.SchemaReference)

# === Message: Google::Cloud::Dialogflow::Cx::V3beta1::ParameterDefinition::InlineSchema ===
    # Fields for InlineSchema
    # Field: type Type: 14 (.google.cloud.dialogflow.cx.v3beta1.DataType)
    # Field: items Type: 11 (.google.cloud.dialogflow.cx.v3beta1.TypeSchema)

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Dialogflow::Cx::V3beta1::ParameterDefinition - Compiled Protocol Buffers messages for google/cloud/dialogflow/cx/v3beta1/parameter_definition.proto

=head1 SYNOPSIS

    use Google::Cloud::Dialogflow::Cx::V3beta1::ParameterDefinition;

    my $msg = Google::Cloud::Dialogflow::Cx::V3beta1::ParameterDefinition::ParameterDefinition->new({
        name => $name,
        type => $type,
        type_schema => $type_schema,
        description => $description,
    });

    # Read or update a field
    my $val = $msg->name();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Dialogflow::Cx::V3beta1::ParameterDefinition::ParameterDefinition->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/dialogflow/cx/v3beta1/parameter_definition.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Dialogflow::Cx::V3beta1::ParameterDefinition::ParameterDefinition

Defines the properties of a parameter.
Used to define parameters used in the agent and the
input / output parameters for each fulfillment.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. Name of parameter.

=item * C<< $msg->type() >> / C<< $msg->type($value) >>

Type: C<Enum> (L<Google::Cloud::Dialogflow::Cx::V3beta1::ParameterDefinition::ParameterType>)

Type of parameter.

=item * C<< $msg->type_schema() >> / C<< $msg->type_schema($value) >>

Type: C<Message> (L<Google::Cloud::Dialogflow::Cx::V3beta1::ParameterDefinition::TypeSchema>)

Optional. Type schema of parameter.

=item * C<< $msg->description() >> / C<< $msg->description($value) >>

Type: C<String>

Human-readable description of the parameter. Limited to 300 characters.

=back

=head3 Enum: ParameterDefinition::ParameterType

=over 4

=item * C<PARAMETER_TYPE_UNSPECIFIED> => C<0>

=item * C<STRING> => C<1>

=item * C<NUMBER> => C<2>

=item * C<BOOLEAN> => C<3>

=item * C<NULL> => C<4>

=item * C<OBJECT> => C<5>

=item * C<LIST> => C<6>

=back

=head2 Google::Cloud::Dialogflow::Cx::V3beta1::ParameterDefinition::TypeSchema

Encapsulates different type schema variations: either a reference to an
a schema that's already defined by a tool, or an inline definition.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->inline_schema() >> / C<< $msg->inline_schema($value) >>

Type: C<Message> (L<Google::Cloud::Dialogflow::Cx::V3beta1::ParameterDefinition::InlineSchema>)

Set if this is an inline schema definition.

=item * C<< $msg->schema_reference() >> / C<< $msg->schema_reference($value) >>

Type: C<Message> (L<Google::Cloud::Dialogflow::Cx::V3beta1::ParameterDefinition::TypeSchema::SchemaReference>)

Set if this is a schema reference.

=back

=head2 Google::Cloud::Dialogflow::Cx::V3beta1::ParameterDefinition::InlineSchema

A type schema object that's specified inline.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->type() >> / C<< $msg->type($value) >>

Type: C<Enum> (L<Google::Cloud::Dialogflow::Cx::V3beta1::DataType>)

Data type of the schema.

=item * C<< $msg->items() >> / C<< $msg->items($value) >>

Type: C<Message> (L<Google::Cloud::Dialogflow::Cx::V3beta1::ParameterDefinition::TypeSchema>)

Schema of the elements if this is an ARRAY type.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Dialogflow::Cx::V3beta1::ParameterDefinition::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
