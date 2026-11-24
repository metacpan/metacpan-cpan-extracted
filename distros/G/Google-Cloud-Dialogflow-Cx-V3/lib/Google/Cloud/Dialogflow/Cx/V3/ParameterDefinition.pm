package Google::Cloud::Dialogflow::Cx::V3::ParameterDefinition;

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
Cjhnb29nbGUvY2xvdWQvZGlhbG9nZmxvdy9jeC92My9wYXJhbWV0ZXJfZGVmaW5pdGlvbi5w
cm90bxIdZ29vZ2xlLmNsb3VkLmRpYWxvZ2Zsb3cuY3gudjMaH2dvb2dsZS9hcGkvZmllbGRf
YmVoYXZpb3IucHJvdG8i8QIKE1BhcmFtZXRlckRlZmluaXRpb24SFwoEbmFtZRgBIAEoCUID
4EECUgRuYW1lElgKBHR5cGUYAiABKA4yQC5nb29nbGUuY2xvdWQuZGlhbG9nZmxvdy5jeC52
My5QYXJhbWV0ZXJEZWZpbml0aW9uLlBhcmFtZXRlclR5cGVCAhgBUgR0eXBlEk8KC3R5cGVf
c2NoZW1hGAQgASgLMikuZ29vZ2xlLmNsb3VkLmRpYWxvZ2Zsb3cuY3gudjMuVHlwZVNjaGVt
YUID4EEBUgp0eXBlU2NoZW1hEiAKC2Rlc2NyaXB0aW9uGAMgASgJUgtkZXNjcmlwdGlvbiJ0
Cg1QYXJhbWV0ZXJUeXBlEh4KGlBBUkFNRVRFUl9UWVBFX1VOU1BFQ0lGSUVEEAASCgoGU1RS
SU5HEAESCgoGTlVNQkVSEAISCwoHQk9PTEVBThADEggKBE5VTEwQBBIKCgZPQkpFQ1QQBRII
CgRMSVNUEAYikQIKClR5cGVTY2hlbWESUgoNaW5saW5lX3NjaGVtYRgBIAEoCzIrLmdvb2ds
ZS5jbG91ZC5kaWFsb2dmbG93LmN4LnYzLklubGluZVNjaGVtYUgAUgxpbmxpbmVTY2hlbWES
ZgoQc2NoZW1hX3JlZmVyZW5jZRgCIAEoCzI5Lmdvb2dsZS5jbG91ZC5kaWFsb2dmbG93LmN4
LnYzLlR5cGVTY2hlbWEuU2NoZW1hUmVmZXJlbmNlSABSD3NjaGVtYVJlZmVyZW5jZRo9Cg9T
Y2hlbWFSZWZlcmVuY2USEgoEdG9vbBgBIAEoCVIEdG9vbBIWCgZzY2hlbWEYAiABKAlSBnNj
aGVtYUIICgZzY2hlbWEijAEKDElubGluZVNjaGVtYRI7CgR0eXBlGAEgASgOMicuZ29vZ2xl
LmNsb3VkLmRpYWxvZ2Zsb3cuY3gudjMuRGF0YVR5cGVSBHR5cGUSPwoFaXRlbXMYAiABKAsy
KS5nb29nbGUuY2xvdWQuZGlhbG9nZmxvdy5jeC52My5UeXBlU2NoZW1hUgVpdGVtcypVCghE
YXRhVHlwZRIZChVEQVRBX1RZUEVfVU5TUEVDSUZJRUQQABIKCgZTVFJJTkcQARIKCgZOVU1C
RVIQAhILCgdCT09MRUFOEAMSCQoFQVJSQVkQBkKWAQohY29tLmdvb2dsZS5jbG91ZC5kaWFs
b2dmbG93LmN4LnYzQhhQYXJhbWV0ZXJEZWZpbml0aW9uUHJvdG9QAVoxY2xvdWQuZ29vZ2xl
LmNvbS9nby9kaWFsb2dmbG93L2N4L2FwaXYzL2N4cGI7Y3hwYuoCIUdvb2dsZTo6Q2xvdWQ6
OkRpYWxvZ2Zsb3c6OkNYOjpWM0rHHAoGEgQOAHcBCrwECgEMEgMOABIysQQgQ29weXJpZ2h0
IDIwMjYgR29vZ2xlIExMQwoKIExpY2Vuc2VkIHVuZGVyIHRoZSBBcGFjaGUgTGljZW5zZSwg
VmVyc2lvbiAyLjAgKHRoZSAiTGljZW5zZSIpOwogeW91IG1heSBub3QgdXNlIHRoaXMgZmls
ZSBleGNlcHQgaW4gY29tcGxpYW5jZSB3aXRoIHRoZSBMaWNlbnNlLgogWW91IG1heSBvYnRh
aW4gYSBjb3B5IG9mIHRoZSBMaWNlbnNlIGF0CgogICAgIGh0dHA6Ly93d3cuYXBhY2hlLm9y
Zy9saWNlbnNlcy9MSUNFTlNFLTIuMAoKIFVubGVzcyByZXF1aXJlZCBieSBhcHBsaWNhYmxl
IGxhdyBvciBhZ3JlZWQgdG8gaW4gd3JpdGluZywgc29mdHdhcmUKIGRpc3RyaWJ1dGVkIHVu
ZGVyIHRoZSBMaWNlbnNlIGlzIGRpc3RyaWJ1dGVkIG9uIGFuICJBUyBJUyIgQkFTSVMsCiBX
SVRIT1VUIFdBUlJBTlRJRVMgT1IgQ09ORElUSU9OUyBPRiBBTlkgS0lORCwgZWl0aGVyIGV4
cHJlc3Mgb3IgaW1wbGllZC4KIFNlZSB0aGUgTGljZW5zZSBmb3IgdGhlIHNwZWNpZmljIGxh
bmd1YWdlIGdvdmVybmluZyBwZXJtaXNzaW9ucyBhbmQKIGxpbWl0YXRpb25zIHVuZGVyIHRo
ZSBMaWNlbnNlLgoKCAoBAhIDEAAmCgkKAgMAEgMSACkKCAoBCBIDFABICgkKAggLEgMUAEgK
CAoBCBIDFQAiCgkKAggKEgMVACIKCAoBCBIDFgA5CgkKAggIEgMWADkKCAoBCBIDFwA6CgkK
AggBEgMXADoKCAoBCBIDGAA6CgkKAggtEgMYADoKmwEKAgQAEgQdAEMBGo4BIERlZmluZXMg
dGhlIHByb3BlcnRpZXMgb2YgYSBwYXJhbWV0ZXIuCiBVc2VkIHRvIGRlZmluZSBwYXJhbWV0
ZXJzIHVzZWQgaW4gdGhlIGFnZW50IGFuZCB0aGUKIGlucHV0IC8gb3V0cHV0IHBhcmFtZXRl
cnMgZm9yIGVhY2ggZnVsZmlsbG1lbnQuCgoKCgMEAAESAx0IGwqKAQoEBAAEABIEIQI2Axp8
IFBhcmFtZXRlciB0eXBlcyBhcmUgdXNlZCBmb3IgdmFsaWRhdGlvbi4KIFRoZXNlIHR5cGVz
IGFyZSBjb25zaXN0ZW50IHdpdGgKIFtnb29nbGUucHJvdG9idWYuVmFsdWVdW2dvb2dsZS5w
cm90b2J1Zi5WYWx1ZV0uCgoMCgUEAAQAARIDIQcUCkAKBgQABAACABIDIwQjGjEgTm90IHNw
ZWNpZmllZC4gTm8gdmFsaWRhdGlvbiB3aWxsIGJlIHBlcmZvcm1lZC4KCg4KBwQABAACAAES
AyMEHgoOCgcEAAQAAgACEgMjISIKLQoGBAAEAAIBEgMmBA8aHiBSZXByZXNlbnRzIGFueSBz
dHJpbmcgdmFsdWUuCgoOCgcEAAQAAgEBEgMmBAoKDgoHBAAEAAIBAhIDJg0OCi0KBgQABAAC
AhIDKQQPGh4gUmVwcmVzZW50cyBhbnkgbnVtYmVyIHZhbHVlLgoKDgoHBAAEAAICARIDKQQK
Cg4KBwQABAACAgISAykNDgosCgYEAAQAAgMSAywEEBodIFJlcHJlc2VudHMgYSBib29sZWFu
IHZhbHVlLgoKDgoHBAAEAAIDARIDLAQLCg4KBwQABAACAwISAywODwopCgYEAAQAAgQSAy8E
DRoaIFJlcHJlc2VudHMgYSBudWxsIHZhbHVlLgoKDgoHBAAEAAIEARIDLwQICg4KBwQABAAC
BAISAy8LDAotCgYEAAQAAgUSAzIEDxoeIFJlcHJlc2VudHMgYW55IG9iamVjdCB2YWx1ZS4K
Cg4KBwQABAACBQESAzIECgoOCgcEAAQAAgUCEgMyDQ4KLQoGBAAEAAIGEgM1BA0aHiBSZXBy
ZXNlbnRzIGEgcmVwZWF0ZWQgdmFsdWUuCgoOCgcEAAQAAgYBEgM1BAgKDgoHBAAEAAIGAhID
NQsMCisKBAQAAgASAzkCOxoeIFJlcXVpcmVkLiBOYW1lIG9mIHBhcmFtZXRlci4KCgwKBQQA
AgAFEgM5AggKDAoFBAACAAESAzkJDQoMCgUEAAIAAxIDORARCgwKBQQAAgAIEgM5EjoKDwoI
BAACAAicCAASAzkTOQohCgQEAAIBEgM8Ai0aFCBUeXBlIG9mIHBhcmFtZXRlci4KCgwKBQQA
AgEGEgM8Ag8KDAoFBAACAQESAzwQFAoMCgUEAAIBAxIDPBcYCgwKBQQAAgEIEgM8GSwKDQoG
BAACAQgDEgM8GisKMgoEBAACAhIDPwJGGiUgT3B0aW9uYWwuIFR5cGUgc2NoZW1hIG9mIHBh
cmFtZXRlci4KCgwKBQQAAgIGEgM/AgwKDAoFBAACAgESAz8NGAoMCgUEAAICAxIDPxscCgwK
BQQAAgIIEgM/HUUKDwoIBAACAgicCAASAz8eRApWCgQEAAIDEgNCAhkaSSBIdW1hbi1yZWFk
YWJsZSBkZXNjcmlwdGlvbiBvZiB0aGUgcGFyYW1ldGVyLiBMaW1pdGVkIHRvIDMwMCBjaGFy
YWN0ZXJzLgoKDAoFBAACAwUSA0ICCAoMCgUEAAIDARIDQgkUCgwKBQQAAgMDEgNCFxgKmwEK
AgQBEgRHAFsBGo4BIEVuY2Fwc3VsYXRlcyBkaWZmZXJlbnQgdHlwZSBzY2hlbWEgdmFyaWF0
aW9uczogZWl0aGVyIGEgcmVmZXJlbmNlIHRvIGFuCiBhIHNjaGVtYSB0aGF0J3MgYWxyZWFk
eSBkZWZpbmVkIGJ5IGEgdG9vbCwgb3IgYW4gaW5saW5lIGRlZmluaXRpb24uCgoKCgMEAQES
A0cIEgo+CgQEAQMAEgRJAlEDGjAgQSByZWZlcmVuY2UgdG8gdGhlIHNjaGVtYSBvZiBhbiBl
eGlzdGluZyB0b29sLgoKDAoFBAEDAAESA0kKGQqZAQoGBAEDAAIAEgNNBBQaiQEgVGhlIHRv
b2wgdGhhdCBjb250YWlucyB0aGlzIHNjaGVtYSBkZWZpbml0aW9uLgogRm9ybWF0OgogYHBy
b2plY3RzLzxQcm9qZWN0SUQ+L2xvY2F0aW9ucy88TG9jYXRpb25JRD4vYWdlbnRzLzxBZ2Vu
dElEPi90b29scy88VG9vbElEPmAuCgoOCgcEAQMAAgAFEgNNBAoKDgoHBAEDAAIAARIDTQsP
Cg4KBwQBAwACAAMSA00SEwooCgYEAQMAAgESA1AEFhoZIFRoZSBuYW1lIG9mIHRoZSBzY2hl
bWEuCgoOCgcEAQMAAgEFEgNQBAoKDgoHBAEDAAIBARIDUAsRCg4KBwQBAwACAQMSA1AUFQoo
CgQEAQgAEgRUAloDGhogVGhlIGVuY2Fwc3VsYXRlZCBzY2hlbWEuCgoMCgUEAQgAARIDVAgO
CjoKBAQBAgASA1YEIxotIFNldCBpZiB0aGlzIGlzIGFuIGlubGluZSBzY2hlbWEgZGVmaW5p
dGlvbi4KCgwKBQQBAgAGEgNWBBAKDAoFBAECAAESA1YRHgoMCgUEAQIAAxIDViEiCjEKBAQB
AgESA1kEKRokIFNldCBpZiB0aGlzIGlzIGEgc2NoZW1hIHJlZmVyZW5jZS4KCgwKBQQBAgEG
EgNZBBMKDAoFBAECAQESA1kUJAoMCgUEAQIBAxIDWScoCjsKAgQCEgReAGQBGi8gQSB0eXBl
IHNjaGVtYSBvYmplY3QgdGhhdCdzIHNwZWNpZmllZCBpbmxpbmUuCgoKCgMEAgESA14IFAon
CgQEAgIAEgNgAhQaGiBEYXRhIHR5cGUgb2YgdGhlIHNjaGVtYS4KCgwKBQQCAgAGEgNgAgoK
DAoFBAICAAESA2ALDwoMCgUEAgIAAxIDYBITCj8KBAQCAgESA2MCFxoyIFNjaGVtYSBvZiB0
aGUgZWxlbWVudHMgaWYgdGhpcyBpcyBhbiBBUlJBWSB0eXBlLgoKDAoFBAICAQYSA2MCDAoM
CgUEAgIBARIDYw0SCgwKBQQCAgEDEgNjFRYKmgEKAgUAEgRoAHcBGo0BIERlZmluZXMgZGF0
YSB0eXBlcyB0aGF0IGFyZSBzdXBwb3J0ZWQgZm9yIGlubGluZWQgc2NoZW1hcy4gVGhlc2Ug
dHlwZXMgYXJlCiBjb25zaXN0ZW50IHdpdGggW2dvb2dsZS5wcm90b2J1Zi5WYWx1ZV1bZ29v
Z2xlLnByb3RvYnVmLlZhbHVlXS4KCgoKAwUAARIDaAUNCh0KBAUAAgASA2oCHBoQIE5vdCBz
cGVjaWZpZWQuCgoMCgUFAAIAARIDagIXCgwKBQUAAgACEgNqGhsKKwoEBQACARIDbQINGh4g
UmVwcmVzZW50cyBhbnkgc3RyaW5nIHZhbHVlLgoKDAoFBQACAQESA20CCAoMCgUFAAIBAhID
bQsMCisKBAUAAgISA3ACDRoeIFJlcHJlc2VudHMgYW55IG51bWJlciB2YWx1ZS4KCgwKBQUA
AgIBEgNwAggKDAoFBQACAgISA3ALDAoqCgQFAAIDEgNzAg4aHSBSZXByZXNlbnRzIGEgYm9v
bGVhbiB2YWx1ZS4KCgwKBQUAAgMBEgNzAgkKDAoFBQACAwISA3MMDQorCgQFAAIEEgN2Agwa
HiBSZXByZXNlbnRzIGEgcmVwZWF0ZWQgdmFsdWUuCgoMCgUFAAIEARIDdgIHCgwKBQUAAgQC
EgN2CgtiBnByb3RvMw==
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Dialogflow::Cx::V3::ParameterDefinition::ParameterDefinition ===
    # Fields for ParameterDefinition
    # Field: name Type: 9 ()
    # Field: type Type: 14 (.google.cloud.dialogflow.cx.v3.ParameterDefinition.ParameterType)
    # Field: type_schema Type: 11 (.google.cloud.dialogflow.cx.v3.TypeSchema)
    # Field: description Type: 9 ()

# Enum: ParameterDefinition::ParameterType
our $ParameterDefinition_PARAMETER_TYPE_UNSPECIFIED = 0;
our $ParameterDefinition_STRING = 1;
our $ParameterDefinition_NUMBER = 2;
our $ParameterDefinition_BOOLEAN = 3;
our $ParameterDefinition_NULL = 4;
our $ParameterDefinition_OBJECT = 5;
our $ParameterDefinition_LIST = 6;

# === Message: Google::Cloud::Dialogflow::Cx::V3::ParameterDefinition::TypeSchema ===
    # Fields for TypeSchema
    # Field: inline_schema Type: 11 (.google.cloud.dialogflow.cx.v3.InlineSchema)
    # Field: schema_reference Type: 11 (.google.cloud.dialogflow.cx.v3.TypeSchema.SchemaReference)

# === Message: Google::Cloud::Dialogflow::Cx::V3::ParameterDefinition::InlineSchema ===
    # Fields for InlineSchema
    # Field: type Type: 14 (.google.cloud.dialogflow.cx.v3.DataType)
    # Field: items Type: 11 (.google.cloud.dialogflow.cx.v3.TypeSchema)

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Dialogflow::Cx::V3::ParameterDefinition - Compiled Protocol Buffers messages for google/cloud/dialogflow/cx/v3/parameter_definition.proto

=head1 SYNOPSIS

    use Google::Cloud::Dialogflow::Cx::V3::ParameterDefinition;

    my $msg = Google::Cloud::Dialogflow::Cx::V3::ParameterDefinition::ParameterDefinition->new({
        name => $name,
        type => $type,
        type_schema => $type_schema,
        description => $description,
    });

    # Read or update a field
    my $val = $msg->name();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Dialogflow::Cx::V3::ParameterDefinition::ParameterDefinition->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/dialogflow/cx/v3/parameter_definition.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Dialogflow::Cx::V3::ParameterDefinition::ParameterDefinition

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

Type: C<Enum> (L<Google::Cloud::Dialogflow::Cx::V3::ParameterDefinition::ParameterType>)

Type of parameter.

=item * C<< $msg->type_schema() >> / C<< $msg->type_schema($value) >>

Type: C<Message> (L<Google::Cloud::Dialogflow::Cx::V3::ParameterDefinition::TypeSchema>)

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

=head2 Google::Cloud::Dialogflow::Cx::V3::ParameterDefinition::TypeSchema

Encapsulates different type schema variations: either a reference to an
a schema that's already defined by a tool, or an inline definition.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->inline_schema() >> / C<< $msg->inline_schema($value) >>

Type: C<Message> (L<Google::Cloud::Dialogflow::Cx::V3::ParameterDefinition::InlineSchema>)

Set if this is an inline schema definition.

=item * C<< $msg->schema_reference() >> / C<< $msg->schema_reference($value) >>

Type: C<Message> (L<Google::Cloud::Dialogflow::Cx::V3::ParameterDefinition::TypeSchema::SchemaReference>)

Set if this is a schema reference.

=back

=head2 Google::Cloud::Dialogflow::Cx::V3::ParameterDefinition::InlineSchema

A type schema object that's specified inline.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->type() >> / C<< $msg->type($value) >>

Type: C<Enum> (L<Google::Cloud::Dialogflow::Cx::V3::DataType>)

Data type of the schema.

=item * C<< $msg->items() >> / C<< $msg->items($value) >>

Type: C<Message> (L<Google::Cloud::Dialogflow::Cx::V3::ParameterDefinition::TypeSchema>)

Schema of the elements if this is an ARRAY type.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Dialogflow::Cx::V3::ParameterDefinition::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
