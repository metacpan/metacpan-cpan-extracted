package Google::Cloud::Dialogflow::Cx::V3beta1::ValidationMessage;

use strict;
use warnings;

our $VERSION = '0.14';

use Protobuf::Message;
use Protobuf::DescriptorPool;
use Protobuf::Internal qw(:all);
use MIME::Base64;

BEGIN {
    my $descriptor_b64 = <<'EOF';
Cjtnb29nbGUvY2xvdWQvZGlhbG9nZmxvdy9jeC92M2JldGExL3ZhbGlkYXRpb25fbWVzc2Fn
ZS5wcm90bxIiZ29vZ2xlLmNsb3VkLmRpYWxvZ2Zsb3cuY3gudjNiZXRhMSLjBQoRVmFsaWRh
dGlvbk1lc3NhZ2USZwoNcmVzb3VyY2VfdHlwZRgBIAEoDjJCLmdvb2dsZS5jbG91ZC5kaWFs
b2dmbG93LmN4LnYzYmV0YTEuVmFsaWRhdGlvbk1lc3NhZ2UuUmVzb3VyY2VUeXBlUgxyZXNv
dXJjZVR5cGUSIAoJcmVzb3VyY2VzGAIgAygJQgIYAVIJcmVzb3VyY2VzElcKDnJlc291cmNl
X25hbWVzGAYgAygLMjAuZ29vZ2xlLmNsb3VkLmRpYWxvZ2Zsb3cuY3gudjNiZXRhMS5SZXNv
dXJjZU5hbWVSDXJlc291cmNlTmFtZXMSWgoIc2V2ZXJpdHkYAyABKA4yPi5nb29nbGUuY2xv
dWQuZGlhbG9nZmxvdy5jeC52M2JldGExLlZhbGlkYXRpb25NZXNzYWdlLlNldmVyaXR5Ughz
ZXZlcml0eRIWCgZkZXRhaWwYBCABKAlSBmRldGFpbCKtAgoMUmVzb3VyY2VUeXBlEh0KGVJF
U09VUkNFX1RZUEVfVU5TUEVDSUZJRUQQABIJCgVBR0VOVBABEgoKBklOVEVOVBACEhoKFklO
VEVOVF9UUkFJTklOR19QSFJBU0UQCBIUChBJTlRFTlRfUEFSQU1FVEVSEAkSCwoHSU5URU5U
UxAKEhsKF0lOVEVOVF9UUkFJTklOR19QSFJBU0VTEAsSDwoLRU5USVRZX1RZUEUQAxIQCgxF
TlRJVFlfVFlQRVMQDBILCgdXRUJIT09LEAQSCAoERkxPVxAFEggKBFBBR0UQBhIJCgVQQUdF
UxANEhoKFlRSQU5TSVRJT05fUk9VVEVfR1JPVVAQBxIgChxBR0VOVF9UUkFOU0lUSU9OX1JP
VVRFX0dST1VQEA4iRgoIU2V2ZXJpdHkSGAoUU0VWRVJJVFlfVU5TUEVDSUZJRUQQABIICgRJ
TkZPEAESCwoHV0FSTklORxACEgkKBUVSUk9SEAMiRQoMUmVzb3VyY2VOYW1lEhIKBG5hbWUY
ASABKAlSBG5hbWUSIQoMZGlzcGxheV9uYW1lGAIgASgJUgtkaXNwbGF5TmFtZULNAQomY29t
Lmdvb2dsZS5jbG91ZC5kaWFsb2dmbG93LmN4LnYzYmV0YTFCFlZhbGlkYXRpb25NZXNzYWdl
UHJvdG9QAVo2Y2xvdWQuZ29vZ2xlLmNvbS9nby9kaWFsb2dmbG93L2N4L2FwaXYzYmV0YTEv
Y3hwYjtjeHBiogICREaqAiJHb29nbGUuQ2xvdWQuRGlhbG9nZmxvdy5DeC5WM0JldGEx6gIm
R29vZ2xlOjpDbG91ZDo6RGlhbG9nZmxvdzo6Q1g6OlYzYmV0YTFKtBcKBhIEDgByAQq8BAoB
DBIDDgASMrEEIENvcHlyaWdodCAyMDI2IEdvb2dsZSBMTEMKCiBMaWNlbnNlZCB1bmRlciB0
aGUgQXBhY2hlIExpY2Vuc2UsIFZlcnNpb24gMi4wICh0aGUgIkxpY2Vuc2UiKTsKIHlvdSBt
YXkgbm90IHVzZSB0aGlzIGZpbGUgZXhjZXB0IGluIGNvbXBsaWFuY2Ugd2l0aCB0aGUgTGlj
ZW5zZS4KIFlvdSBtYXkgb2J0YWluIGEgY29weSBvZiB0aGUgTGljZW5zZSBhdAoKICAgICBo
dHRwOi8vd3d3LmFwYWNoZS5vcmcvbGljZW5zZXMvTElDRU5TRS0yLjAKCiBVbmxlc3MgcmVx
dWlyZWQgYnkgYXBwbGljYWJsZSBsYXcgb3IgYWdyZWVkIHRvIGluIHdyaXRpbmcsIHNvZnR3
YXJlCiBkaXN0cmlidXRlZCB1bmRlciB0aGUgTGljZW5zZSBpcyBkaXN0cmlidXRlZCBvbiBh
biAiQVMgSVMiIEJBU0lTLAogV0lUSE9VVCBXQVJSQU5USUVTIE9SIENPTkRJVElPTlMgT0Yg
QU5ZIEtJTkQsIGVpdGhlciBleHByZXNzIG9yIGltcGxpZWQuCiBTZWUgdGhlIExpY2Vuc2Ug
Zm9yIHRoZSBzcGVjaWZpYyBsYW5ndWFnZSBnb3Zlcm5pbmcgcGVybWlzc2lvbnMgYW5kCiBs
aW1pdGF0aW9ucyB1bmRlciB0aGUgTGljZW5zZS4KCggKAQISAxAAKwoICgEIEgMSAD8KCQoC
CCUSAxIAPwoICgEIEgMTAE0KCQoCCAsSAxMATQoICgEIEgMUACIKCQoCCAoSAxQAIgoICgEI
EgMVADcKCQoCCAgSAxUANwoICgEIEgMWAD8KCQoCCAESAxYAPwoICgEIEgMXACAKCQoCCCQS
AxcAIAoICgEIEgMYAD8KCQoCCC0SAxgAPwosCgIEABIEGwBpARogIEFnZW50L2Zsb3cgdmFs
aWRhdGlvbiBtZXNzYWdlLgoKCgoDBAABEgMbCBkKHwoEBAAEABIEHQJKAxoRIFJlc291cmNl
IHR5cGVzLgoKDAoFBAAEAAESAx0HEwodCgYEAAQAAgASAx8EIhoOIFVuc3BlY2lmaWVkLgoK
DgoHBAAEAAIAARIDHwQdCg4KBwQABAACAAISAx8gIQoXCgYEAAQAAgESAyIEDhoIIEFnZW50
LgoKDgoHBAAEAAIBARIDIgQJCg4KBwQABAACAQISAyIMDQoYCgYEAAQAAgISAyUEDxoJIElu
dGVudC4KCg4KBwQABAACAgESAyUECgoOCgcEAAQAAgICEgMlDQ4KKAoGBAAEAAIDEgMoBB8a
GSBJbnRlbnQgdHJhaW5pbmcgcGhyYXNlLgoKDgoHBAAEAAIDARIDKAQaCg4KBwQABAACAwIS
AygdHgoiCgYEAAQAAgQSAysEGRoTIEludGVudCBwYXJhbWV0ZXIuCgoOCgcEAAQAAgQBEgMr
BBQKDgoHBAAEAAIEAhIDKxcYCiIKBgQABAACBRIDLgQRGhMgTXVsdGlwbGUgaW50ZW50cy4K
Cg4KBwQABAACBQESAy4ECwoOCgcEAAQAAgUCEgMuDhAKKwoGBAAEAAIGEgMxBCEaHCBNdWx0
aXBsZSB0cmFpbmluZyBwaHJhc2VzLgoKDgoHBAAEAAIGARIDMQQbCg4KBwQABAACBgISAzEe
IAodCgYEAAQAAgcSAzQEFBoOIEVudGl0eSB0eXBlLgoKDgoHBAAEAAIHARIDNAQPCg4KBwQA
BAACBwISAzQSEwonCgYEAAQAAggSAzcEFhoYIE11bHRpcGxlIGVudGl0eSB0eXBlcy4KCg4K
BwQABAACCAESAzcEEAoOCgcEAAQAAggCEgM3ExUKGQoGBAAEAAIJEgM6BBAaCiBXZWJob29r
LgoKDgoHBAAEAAIJARIDOgQLCg4KBwQABAACCQISAzoODwoWCgYEAAQAAgoSAz0EDRoHIEZs
b3cuCgoOCgcEAAQAAgoBEgM9BAgKDgoHBAAEAAIKAhIDPQsMChYKBgQABAACCxIDQAQNGgcg
UGFnZS4KCg4KBwQABAACCwESA0AECAoOCgcEAAQAAgsCEgNACwwKIAoGBAAEAAIMEgNDBA8a
ESBNdWx0aXBsZSBwYWdlcy4KCg4KBwQABAACDAESA0MECQoOCgcEAAQAAgwCEgNDDA4KKAoG
BAAEAAINEgNGBB8aGSBUcmFuc2l0aW9uIHJvdXRlIGdyb3VwLgoKDgoHBAAEAAINARIDRgQa
Cg4KBwQABAACDQISA0YdHgouCgYEAAQAAg4SA0kEJhofIEFnZW50IHRyYW5zaXRpb24gcm91
dGUgZ3JvdXAuCgoOCgcEAAQAAg4BEgNJBCAKDgoHBAAEAAIOAhIDSSMlCh8KBAQABAESBE0C
WQMaESBTZXZlcml0eSBsZXZlbC4KCgwKBQQABAEBEgNNBw8KHQoGBAAEAQIAEgNPBB0aDiBV
bnNwZWNpZmllZC4KCg4KBwQABAECAAESA08EGAoOCgcEAAQBAgACEgNPGxwKRAoGBAAEAQIB
EgNSBA0aNSBUaGUgYWdlbnQgZG9lc24ndCBmb2xsb3cgRGlhbG9nZmxvdyBiZXN0IHByYWN0
aWNlcy4KCg4KBwQABAECAQESA1IECAoOCgcEAAQBAgECEgNSCwwKNgoGBAAEAQICEgNVBBAa
JyBUaGUgYWdlbnQgbWF5IG5vdCBiZWhhdmUgYXMgZXhwZWN0ZWQuCgoOCgcEAAQBAgIBEgNV
BAsKDgoHBAAEAQICAhIDVQ4PCjMKBgQABAECAxIDWAQOGiQgVGhlIGFnZW50IG1heSBleHBl
cmllbmNlIGZhaWx1cmVzLgoKDgoHBAAEAQIDARIDWAQJCg4KBwQABAECAwISA1gMDQpECgQE
AAIAEgNcAiEaNyBUaGUgdHlwZSBvZiB0aGUgcmVzb3VyY2VzIHdoZXJlIHRoZSBtZXNzYWdl
IGlzIGZvdW5kLgoKDAoFBAACAAYSA1wCDgoMCgUEAAIAARIDXA8cCgwKBQQAAgADEgNcHyAK
RQoEBAACARIDXwI0GjggVGhlIG5hbWVzIG9mIHRoZSByZXNvdXJjZXMgd2hlcmUgdGhlIG1l
c3NhZ2UgaXMgZm91bmQuCgoMCgUEAAIBBBIDXwIKCgwKBQQAAgEFEgNfCxEKDAoFBAACAQES
A18SGwoMCgUEAAIBAxIDXx4fCgwKBQQAAgEIEgNfIDMKDQoGBAACAQgDEgNfITIKTgoEBAAC
AhIDYgIrGkEgVGhlIHJlc291cmNlIG5hbWVzIG9mIHRoZSByZXNvdXJjZXMgd2hlcmUgdGhl
IG1lc3NhZ2UgaXMgZm91bmQuCgoMCgUEAAICBBIDYgIKCgwKBQQAAgIGEgNiCxcKDAoFBAAC
AgESA2IYJgoMCgUEAAICAxIDYikqCjUKBAQAAgMSA2UCGBooIEluZGljYXRlcyB0aGUgc2V2
ZXJpdHkgb2YgdGhlIG1lc3NhZ2UuCgoMCgUEAAIDBhIDZQIKCgwKBQQAAgMBEgNlCxMKDAoF
BAACAwMSA2UWFwoiCgQEAAIEEgNoAhQaFSBUaGUgbWVzc2FnZSBkZXRhaWwuCgoMCgUEAAIE
BRIDaAIICgwKBQQAAgQBEgNoCQ8KDAoFBAACBAMSA2gSEwotCgIEARIEbAByARohIFJlc291
cmNlIG5hbWUgYW5kIGRpc3BsYXkgbmFtZS4KCgoKAwQBARIDbAgUChQKBAQBAgASA24CEhoH
IE5hbWUuCgoMCgUEAQIABRIDbgIICgwKBQQBAgABEgNuCQ0KDAoFBAECAAMSA24QEQocCgQE
AQIBEgNxAhoaDyBEaXNwbGF5IG5hbWUuCgoMCgUEAQIBBRIDcQIICgwKBQQBAgEBEgNxCRUK
DAoFBAECAQMSA3EYGWIGcHJvdG8z
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Dialogflow::Cx::V3beta1::ValidationMessage::ValidationMessage ===
    # Fields for ValidationMessage
    # Field: resource_type Type: 14 (.google.cloud.dialogflow.cx.v3beta1.ValidationMessage.ResourceType)
    # Field: resources Type: 9 ()
    # Field: resource_names Type: 11 (.google.cloud.dialogflow.cx.v3beta1.ResourceName)
    # Field: severity Type: 14 (.google.cloud.dialogflow.cx.v3beta1.ValidationMessage.Severity)
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

# === Message: Google::Cloud::Dialogflow::Cx::V3beta1::ValidationMessage::ResourceName ===
    # Fields for ResourceName
    # Field: name Type: 9 ()
    # Field: display_name Type: 9 ()

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Dialogflow::Cx::V3beta1::ValidationMessage - Compiled Protocol Buffers messages for google/cloud/dialogflow/cx/v3beta1/validation_message.proto

=head1 SYNOPSIS

    use Google::Cloud::Dialogflow::Cx::V3beta1::ValidationMessage;

    my $msg = Google::Cloud::Dialogflow::Cx::V3beta1::ValidationMessage::ValidationMessage->new({
        resource_type => $resource_type,
        resources => $resources,
        resource_names => $resource_names,
        severity => $severity,
    });

    # Read or update a field
    my $val = $msg->resource_type();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Dialogflow::Cx::V3beta1::ValidationMessage::ValidationMessage->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/dialogflow/cx/v3beta1/validation_message.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Dialogflow::Cx::V3beta1::ValidationMessage::ValidationMessage

Agent/flow validation message.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->resource_type() >> / C<< $msg->resource_type($value) >>

Type: C<Enum> (L<Google::Cloud::Dialogflow::Cx::V3beta1::ValidationMessage::ResourceType>)

The type of the resources where the message is found.

=item * C<< $msg->resources() >> / C<< $msg->resources($value) >>

Type: C<String>

The names of the resources where the message is found.

=item * C<< $msg->resource_names() >> / C<< $msg->resource_names($value) >>

Type: C<Message> (L<Google::Cloud::Dialogflow::Cx::V3beta1::ValidationMessage::ResourceName>)

The resource names of the resources where the message is found.

=item * C<< $msg->severity() >> / C<< $msg->severity($value) >>

Type: C<Enum> (L<Google::Cloud::Dialogflow::Cx::V3beta1::ValidationMessage::Severity>)

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

=head2 Google::Cloud::Dialogflow::Cx::V3beta1::ValidationMessage::ResourceName

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

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Dialogflow::Cx::V3beta1::ValidationMessage::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
