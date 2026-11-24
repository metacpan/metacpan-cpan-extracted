package Google::Cloud::Dialogflow::Cx::V3::ValidationMessage;

use strict;
use warnings;

our $VERSION = '0.14';

use Protobuf::Message;
use Protobuf::DescriptorPool;
use Protobuf::Internal qw(:all);
use MIME::Base64;

BEGIN {
    my $descriptor_b64 = <<'EOF';
CjZnb29nbGUvY2xvdWQvZGlhbG9nZmxvdy9jeC92My92YWxpZGF0aW9uX21lc3NhZ2UucHJv
dG8SHWdvb2dsZS5jbG91ZC5kaWFsb2dmbG93LmN4LnYzItQFChFWYWxpZGF0aW9uTWVzc2Fn
ZRJiCg1yZXNvdXJjZV90eXBlGAEgASgOMj0uZ29vZ2xlLmNsb3VkLmRpYWxvZ2Zsb3cuY3gu
djMuVmFsaWRhdGlvbk1lc3NhZ2UuUmVzb3VyY2VUeXBlUgxyZXNvdXJjZVR5cGUSIAoJcmVz
b3VyY2VzGAIgAygJQgIYAVIJcmVzb3VyY2VzElIKDnJlc291cmNlX25hbWVzGAYgAygLMisu
Z29vZ2xlLmNsb3VkLmRpYWxvZ2Zsb3cuY3gudjMuUmVzb3VyY2VOYW1lUg1yZXNvdXJjZU5h
bWVzElUKCHNldmVyaXR5GAMgASgOMjkuZ29vZ2xlLmNsb3VkLmRpYWxvZ2Zsb3cuY3gudjMu
VmFsaWRhdGlvbk1lc3NhZ2UuU2V2ZXJpdHlSCHNldmVyaXR5EhYKBmRldGFpbBgEIAEoCVIG
ZGV0YWlsIq0CCgxSZXNvdXJjZVR5cGUSHQoZUkVTT1VSQ0VfVFlQRV9VTlNQRUNJRklFRBAA
EgkKBUFHRU5UEAESCgoGSU5URU5UEAISGgoWSU5URU5UX1RSQUlOSU5HX1BIUkFTRRAIEhQK
EElOVEVOVF9QQVJBTUVURVIQCRILCgdJTlRFTlRTEAoSGwoXSU5URU5UX1RSQUlOSU5HX1BI
UkFTRVMQCxIPCgtFTlRJVFlfVFlQRRADEhAKDEVOVElUWV9UWVBFUxAMEgsKB1dFQkhPT0sQ
BBIICgRGTE9XEAUSCAoEUEFHRRAGEgkKBVBBR0VTEA0SGgoWVFJBTlNJVElPTl9ST1VURV9H
Uk9VUBAHEiAKHEFHRU5UX1RSQU5TSVRJT05fUk9VVEVfR1JPVVAQDiJGCghTZXZlcml0eRIY
ChRTRVZFUklUWV9VTlNQRUNJRklFRBAAEggKBElORk8QARILCgdXQVJOSU5HEAISCQoFRVJS
T1IQAyJFCgxSZXNvdXJjZU5hbWUSEgoEbmFtZRgBIAEoCVIEbmFtZRIhCgxkaXNwbGF5X25h
bWUYAiABKAlSC2Rpc3BsYXlOYW1lQrkBCiFjb20uZ29vZ2xlLmNsb3VkLmRpYWxvZ2Zsb3cu
Y3gudjNCFlZhbGlkYXRpb25NZXNzYWdlUHJvdG9QAVoxY2xvdWQuZ29vZ2xlLmNvbS9nby9k
aWFsb2dmbG93L2N4L2FwaXYzL2N4cGI7Y3hwYqICAkRGqgIdR29vZ2xlLkNsb3VkLkRpYWxv
Z2Zsb3cuQ3guVjPqAiFHb29nbGU6OkNsb3VkOjpEaWFsb2dmbG93OjpDWDo6VjNKtBcKBhIE
DgByAQq8BAoBDBIDDgASMrEEIENvcHlyaWdodCAyMDI2IEdvb2dsZSBMTEMKCiBMaWNlbnNl
ZCB1bmRlciB0aGUgQXBhY2hlIExpY2Vuc2UsIFZlcnNpb24gMi4wICh0aGUgIkxpY2Vuc2Ui
KTsKIHlvdSBtYXkgbm90IHVzZSB0aGlzIGZpbGUgZXhjZXB0IGluIGNvbXBsaWFuY2Ugd2l0
aCB0aGUgTGljZW5zZS4KIFlvdSBtYXkgb2J0YWluIGEgY29weSBvZiB0aGUgTGljZW5zZSBh
dAoKICAgICBodHRwOi8vd3d3LmFwYWNoZS5vcmcvbGljZW5zZXMvTElDRU5TRS0yLjAKCiBV
bmxlc3MgcmVxdWlyZWQgYnkgYXBwbGljYWJsZSBsYXcgb3IgYWdyZWVkIHRvIGluIHdyaXRp
bmcsIHNvZnR3YXJlCiBkaXN0cmlidXRlZCB1bmRlciB0aGUgTGljZW5zZSBpcyBkaXN0cmli
dXRlZCBvbiBhbiAiQVMgSVMiIEJBU0lTLAogV0lUSE9VVCBXQVJSQU5USUVTIE9SIENPTkRJ
VElPTlMgT0YgQU5ZIEtJTkQsIGVpdGhlciBleHByZXNzIG9yIGltcGxpZWQuCiBTZWUgdGhl
IExpY2Vuc2UgZm9yIHRoZSBzcGVjaWZpYyBsYW5ndWFnZSBnb3Zlcm5pbmcgcGVybWlzc2lv
bnMgYW5kCiBsaW1pdGF0aW9ucyB1bmRlciB0aGUgTGljZW5zZS4KCggKAQISAxAAJgoICgEI
EgMSADoKCQoCCCUSAxIAOgoICgEIEgMTAEgKCQoCCAsSAxMASAoICgEIEgMUACIKCQoCCAoS
AxQAIgoICgEIEgMVADcKCQoCCAgSAxUANwoICgEIEgMWADoKCQoCCAESAxYAOgoICgEIEgMX
ACAKCQoCCCQSAxcAIAoICgEIEgMYADoKCQoCCC0SAxgAOgosCgIEABIEGwBpARogIEFnZW50
L2Zsb3cgdmFsaWRhdGlvbiBtZXNzYWdlLgoKCgoDBAABEgMbCBkKHwoEBAAEABIEHQJKAxoR
IFJlc291cmNlIHR5cGVzLgoKDAoFBAAEAAESAx0HEwodCgYEAAQAAgASAx8EIhoOIFVuc3Bl
Y2lmaWVkLgoKDgoHBAAEAAIAARIDHwQdCg4KBwQABAACAAISAx8gIQoXCgYEAAQAAgESAyIE
DhoIIEFnZW50LgoKDgoHBAAEAAIBARIDIgQJCg4KBwQABAACAQISAyIMDQoYCgYEAAQAAgIS
AyUEDxoJIEludGVudC4KCg4KBwQABAACAgESAyUECgoOCgcEAAQAAgICEgMlDQ4KKAoGBAAE
AAIDEgMoBB8aGSBJbnRlbnQgdHJhaW5pbmcgcGhyYXNlLgoKDgoHBAAEAAIDARIDKAQaCg4K
BwQABAACAwISAygdHgoiCgYEAAQAAgQSAysEGRoTIEludGVudCBwYXJhbWV0ZXIuCgoOCgcE
AAQAAgQBEgMrBBQKDgoHBAAEAAIEAhIDKxcYCiIKBgQABAACBRIDLgQRGhMgTXVsdGlwbGUg
aW50ZW50cy4KCg4KBwQABAACBQESAy4ECwoOCgcEAAQAAgUCEgMuDhAKKwoGBAAEAAIGEgMx
BCEaHCBNdWx0aXBsZSB0cmFpbmluZyBwaHJhc2VzLgoKDgoHBAAEAAIGARIDMQQbCg4KBwQA
BAACBgISAzEeIAodCgYEAAQAAgcSAzQEFBoOIEVudGl0eSB0eXBlLgoKDgoHBAAEAAIHARID
NAQPCg4KBwQABAACBwISAzQSEwonCgYEAAQAAggSAzcEFhoYIE11bHRpcGxlIGVudGl0eSB0
eXBlcy4KCg4KBwQABAACCAESAzcEEAoOCgcEAAQAAggCEgM3ExUKGQoGBAAEAAIJEgM6BBAa
CiBXZWJob29rLgoKDgoHBAAEAAIJARIDOgQLCg4KBwQABAACCQISAzoODwoWCgYEAAQAAgoS
Az0EDRoHIEZsb3cuCgoOCgcEAAQAAgoBEgM9BAgKDgoHBAAEAAIKAhIDPQsMChYKBgQABAAC
CxIDQAQNGgcgUGFnZS4KCg4KBwQABAACCwESA0AECAoOCgcEAAQAAgsCEgNACwwKIAoGBAAE
AAIMEgNDBA8aESBNdWx0aXBsZSBwYWdlcy4KCg4KBwQABAACDAESA0MECQoOCgcEAAQAAgwC
EgNDDA4KKAoGBAAEAAINEgNGBB8aGSBUcmFuc2l0aW9uIHJvdXRlIGdyb3VwLgoKDgoHBAAE
AAINARIDRgQaCg4KBwQABAACDQISA0YdHgouCgYEAAQAAg4SA0kEJhofIEFnZW50IHRyYW5z
aXRpb24gcm91dGUgZ3JvdXAuCgoOCgcEAAQAAg4BEgNJBCAKDgoHBAAEAAIOAhIDSSMlCh8K
BAQABAESBE0CWQMaESBTZXZlcml0eSBsZXZlbC4KCgwKBQQABAEBEgNNBw8KHQoGBAAEAQIA
EgNPBB0aDiBVbnNwZWNpZmllZC4KCg4KBwQABAECAAESA08EGAoOCgcEAAQBAgACEgNPGxwK
RAoGBAAEAQIBEgNSBA0aNSBUaGUgYWdlbnQgZG9lc24ndCBmb2xsb3cgRGlhbG9nZmxvdyBi
ZXN0IHByYWN0aWNlcy4KCg4KBwQABAECAQESA1IECAoOCgcEAAQBAgECEgNSCwwKNgoGBAAE
AQICEgNVBBAaJyBUaGUgYWdlbnQgbWF5IG5vdCBiZWhhdmUgYXMgZXhwZWN0ZWQuCgoOCgcE
AAQBAgIBEgNVBAsKDgoHBAAEAQICAhIDVQ4PCjMKBgQABAECAxIDWAQOGiQgVGhlIGFnZW50
IG1heSBleHBlcmllbmNlIGZhaWx1cmVzLgoKDgoHBAAEAQIDARIDWAQJCg4KBwQABAECAwIS
A1gMDQpECgQEAAIAEgNcAiEaNyBUaGUgdHlwZSBvZiB0aGUgcmVzb3VyY2VzIHdoZXJlIHRo
ZSBtZXNzYWdlIGlzIGZvdW5kLgoKDAoFBAACAAYSA1wCDgoMCgUEAAIAARIDXA8cCgwKBQQA
AgADEgNcHyAKRQoEBAACARIDXwI0GjggVGhlIG5hbWVzIG9mIHRoZSByZXNvdXJjZXMgd2hl
cmUgdGhlIG1lc3NhZ2UgaXMgZm91bmQuCgoMCgUEAAIBBBIDXwIKCgwKBQQAAgEFEgNfCxEK
DAoFBAACAQESA18SGwoMCgUEAAIBAxIDXx4fCgwKBQQAAgEIEgNfIDMKDQoGBAACAQgDEgNf
ITIKTgoEBAACAhIDYgIrGkEgVGhlIHJlc291cmNlIG5hbWVzIG9mIHRoZSByZXNvdXJjZXMg
d2hlcmUgdGhlIG1lc3NhZ2UgaXMgZm91bmQuCgoMCgUEAAICBBIDYgIKCgwKBQQAAgIGEgNi
CxcKDAoFBAACAgESA2IYJgoMCgUEAAICAxIDYikqCjUKBAQAAgMSA2UCGBooIEluZGljYXRl
cyB0aGUgc2V2ZXJpdHkgb2YgdGhlIG1lc3NhZ2UuCgoMCgUEAAIDBhIDZQIKCgwKBQQAAgMB
EgNlCxMKDAoFBAACAwMSA2UWFwoiCgQEAAIEEgNoAhQaFSBUaGUgbWVzc2FnZSBkZXRhaWwu
CgoMCgUEAAIEBRIDaAIICgwKBQQAAgQBEgNoCQ8KDAoFBAACBAMSA2gSEwotCgIEARIEbABy
ARohIFJlc291cmNlIG5hbWUgYW5kIGRpc3BsYXkgbmFtZS4KCgoKAwQBARIDbAgUChQKBAQB
AgASA24CEhoHIE5hbWUuCgoMCgUEAQIABRIDbgIICgwKBQQBAgABEgNuCQ0KDAoFBAECAAMS
A24QEQocCgQEAQIBEgNxAhoaDyBEaXNwbGF5IG5hbWUuCgoMCgUEAQIBBRIDcQIICgwKBQQB
AgEBEgNxCRUKDAoFBAECAQMSA3EYGWIGcHJvdG8z
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Dialogflow::Cx::V3::ValidationMessage::ValidationMessage ===
    # Fields for ValidationMessage
    # Field: resource_type Type: 14 (.google.cloud.dialogflow.cx.v3.ValidationMessage.ResourceType)
    # Field: resources Type: 9 ()
    # Field: resource_names Type: 11 (.google.cloud.dialogflow.cx.v3.ResourceName)
    # Field: severity Type: 14 (.google.cloud.dialogflow.cx.v3.ValidationMessage.Severity)
    # Field: detail Type: 9 ()

# Enum: ValidationMessage::ResourceType
our $ValidationMessage_RESOURCE_TYPE_UNSPECIFIED = 0;
our $ValidationMessage_AGENT = 1;
our $ValidationMessage_INTENT = 2;
our $ValidationMessage_INTENT_TRAINING_PHRASE = 8;
our $ValidationMessage_INTENT_PARAMETER = 9;
our $ValidationMessage_INTENTS = 10;
our $ValidationMessage_INTENT_TRAINING_PHRASES = 11;
our $ValidationMessage_ENTITY_TYPE = 3;
our $ValidationMessage_ENTITY_TYPES = 12;
our $ValidationMessage_WEBHOOK = 4;
our $ValidationMessage_FLOW = 5;
our $ValidationMessage_PAGE = 6;
our $ValidationMessage_PAGES = 13;
our $ValidationMessage_TRANSITION_ROUTE_GROUP = 7;
our $ValidationMessage_AGENT_TRANSITION_ROUTE_GROUP = 14;

# Enum: ValidationMessage::Severity
our $ValidationMessage_SEVERITY_UNSPECIFIED = 0;
our $ValidationMessage_INFO = 1;
our $ValidationMessage_WARNING = 2;
our $ValidationMessage_ERROR = 3;

# === Message: Google::Cloud::Dialogflow::Cx::V3::ValidationMessage::ResourceName ===
    # Fields for ResourceName
    # Field: name Type: 9 ()
    # Field: display_name Type: 9 ()

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Dialogflow::Cx::V3::ValidationMessage - Compiled Protocol Buffers messages for google/cloud/dialogflow/cx/v3/validation_message.proto

=head1 SYNOPSIS

    use Google::Cloud::Dialogflow::Cx::V3::ValidationMessage;

    my $msg = Google::Cloud::Dialogflow::Cx::V3::ValidationMessage::ValidationMessage->new({
        resource_type => $resource_type,
        resources => $resources,
        resource_names => $resource_names,
        severity => $severity,
    });

    # Read or update a field
    my $val = $msg->resource_type();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Dialogflow::Cx::V3::ValidationMessage::ValidationMessage->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/dialogflow/cx/v3/validation_message.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Dialogflow::Cx::V3::ValidationMessage::ValidationMessage

Agent/flow validation message.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->resource_type() >> / C<< $msg->resource_type($value) >>

Type: C<Enum> (L<Google::Cloud::Dialogflow::Cx::V3::ValidationMessage::ResourceType>)

The type of the resources where the message is found.

=item * C<< $msg->resources() >> / C<< $msg->resources($value) >>

Type: C<String>

The names of the resources where the message is found.

=item * C<< $msg->resource_names() >> / C<< $msg->resource_names($value) >>

Type: C<Message> (L<Google::Cloud::Dialogflow::Cx::V3::ValidationMessage::ResourceName>)

The resource names of the resources where the message is found.

=item * C<< $msg->severity() >> / C<< $msg->severity($value) >>

Type: C<Enum> (L<Google::Cloud::Dialogflow::Cx::V3::ValidationMessage::Severity>)

Indicates the severity of the message.

=item * C<< $msg->detail() >> / C<< $msg->detail($value) >>

Type: C<String>

The message detail.

=back

=head3 Enum: ValidationMessage::ResourceType

=over 4

=item * C<RESOURCE_TYPE_UNSPECIFIED> => C<0>

=item * C<AGENT> => C<1>

=item * C<INTENT> => C<2>

=item * C<INTENT_TRAINING_PHRASE> => C<8>

=item * C<INTENT_PARAMETER> => C<9>

=item * C<INTENTS> => C<10>

=item * C<INTENT_TRAINING_PHRASES> => C<11>

=item * C<ENTITY_TYPE> => C<3>

=item * C<ENTITY_TYPES> => C<12>

=item * C<WEBHOOK> => C<4>

=item * C<FLOW> => C<5>

=item * C<PAGE> => C<6>

=item * C<PAGES> => C<13>

=item * C<TRANSITION_ROUTE_GROUP> => C<7>

=item * C<AGENT_TRANSITION_ROUTE_GROUP> => C<14>

=back

=head3 Enum: ValidationMessage::Severity

=over 4

=item * C<SEVERITY_UNSPECIFIED> => C<0>

=item * C<INFO> => C<1>

=item * C<WARNING> => C<2>

=item * C<ERROR> => C<3>

=back

=head2 Google::Cloud::Dialogflow::Cx::V3::ValidationMessage::ResourceName

Resource name and display name.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Name.

=item * C<< $msg->display_name() >> / C<< $msg->display_name($value) >>

Type: C<String>

Display name.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Dialogflow::Cx::V3::ValidationMessage::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
