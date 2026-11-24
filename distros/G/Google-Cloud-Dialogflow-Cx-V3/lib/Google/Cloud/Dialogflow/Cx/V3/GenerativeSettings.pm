package Google::Cloud::Dialogflow::Cx::V3::GenerativeSettings;

use strict;
use warnings;

our $VERSION = '0.14';

use Protobuf::Message;
use Protobuf::DescriptorPool;
use Protobuf::Internal qw(:all);
use MIME::Base64;

BEGIN {
    eval { require Google::Api::Resource };
    eval { require Google::Cloud::Dialogflow::Cx::V3::SafetySettings };
    my $descriptor_b64 = <<'EOF';
Cjdnb29nbGUvY2xvdWQvZGlhbG9nZmxvdy9jeC92My9nZW5lcmF0aXZlX3NldHRpbmdzLnBy
b3RvEh1nb29nbGUuY2xvdWQuZGlhbG9nZmxvdy5jeC52MxoZZ29vZ2xlL2FwaS9yZXNvdXJj
ZS5wcm90bxozZ29vZ2xlL2Nsb3VkL2RpYWxvZ2Zsb3cvY3gvdjMvc2FmZXR5X3NldHRpbmdz
LnByb3RvItQJChJHZW5lcmF0aXZlU2V0dGluZ3MSEgoEbmFtZRgFIAEoCVIEbmFtZRJvChFm
YWxsYmFja19zZXR0aW5ncxgBIAEoCzJCLmdvb2dsZS5jbG91ZC5kaWFsb2dmbG93LmN4LnYz
LkdlbmVyYXRpdmVTZXR0aW5ncy5GYWxsYmFja1NldHRpbmdzUhBmYWxsYmFja1NldHRpbmdz
EmsKGmdlbmVyYXRpdmVfc2FmZXR5X3NldHRpbmdzGAMgASgLMi0uZ29vZ2xlLmNsb3VkLmRp
YWxvZ2Zsb3cuY3gudjMuU2FmZXR5U2V0dGluZ3NSGGdlbmVyYXRpdmVTYWZldHlTZXR0aW5n
cxKOAQoca25vd2xlZGdlX2Nvbm5lY3Rvcl9zZXR0aW5ncxgHIAEoCzJMLmdvb2dsZS5jbG91
ZC5kaWFsb2dmbG93LmN4LnYzLkdlbmVyYXRpdmVTZXR0aW5ncy5Lbm93bGVkZ2VDb25uZWN0
b3JTZXR0aW5nc1Iaa25vd2xlZGdlQ29ubmVjdG9yU2V0dGluZ3MSIwoNbGFuZ3VhZ2VfY29k
ZRgEIAEoCVIMbGFuZ3VhZ2VDb2RlEl0KEmxsbV9tb2RlbF9zZXR0aW5ncxgIIAEoCzIvLmdv
b2dsZS5jbG91ZC5kaWFsb2dmbG93LmN4LnYzLkxsbU1vZGVsU2V0dGluZ3NSEGxsbU1vZGVs
U2V0dGluZ3MapwIKEEZhbGxiYWNrU2V0dGluZ3MSJwoPc2VsZWN0ZWRfcHJvbXB0GAMgASgJ
Ug5zZWxlY3RlZFByb21wdBJ8ChBwcm9tcHRfdGVtcGxhdGVzGAQgAygLMlEuZ29vZ2xlLmNs
b3VkLmRpYWxvZ2Zsb3cuY3gudjMuR2VuZXJhdGl2ZVNldHRpbmdzLkZhbGxiYWNrU2V0dGlu
Z3MuUHJvbXB0VGVtcGxhdGVSD3Byb21wdFRlbXBsYXRlcxpsCg5Qcm9tcHRUZW1wbGF0ZRIh
CgxkaXNwbGF5X25hbWUYASABKAlSC2Rpc3BsYXlOYW1lEh8KC3Byb21wdF90ZXh0GAIgASgJ
Ugpwcm9tcHRUZXh0EhYKBmZyb3plbhgDIAEoCFIGZnJvemVuGogCChpLbm93bGVkZ2VDb25u
ZWN0b3JTZXR0aW5ncxIaCghidXNpbmVzcxgBIAEoCVIIYnVzaW5lc3MSFAoFYWdlbnQYAiAB
KAlSBWFnZW50EiUKDmFnZW50X2lkZW50aXR5GAMgASgJUg1hZ2VudElkZW50aXR5EjEKFGJ1
c2luZXNzX2Rlc2NyaXB0aW9uGAQgASgJUhNidXNpbmVzc0Rlc2NyaXB0aW9uEh8KC2FnZW50
X3Njb3BlGAUgASgJUgphZ2VudFNjb3BlEj0KG2Rpc2FibGVfZGF0YV9zdG9yZV9mYWxsYmFj
axgIIAEoCFIYZGlzYWJsZURhdGFTdG9yZUZhbGxiYWNrOoEB6kF+CjFkaWFsb2dmbG93Lmdv
b2dsZWFwaXMuY29tL0FnZW50R2VuZXJhdGl2ZVNldHRpbmdzEklwcm9qZWN0cy97cHJvamVj
dH0vbG9jYXRpb25zL3tsb2NhdGlvbn0vYWdlbnRzL3thZ2VudH0vZ2VuZXJhdGl2ZVNldHRp
bmdzIkkKEExsbU1vZGVsU2V0dGluZ3MSFAoFbW9kZWwYASABKAlSBW1vZGVsEh8KC3Byb21w
dF90ZXh0GAIgASgJUgpwcm9tcHRUZXh0QroBCiFjb20uZ29vZ2xlLmNsb3VkLmRpYWxvZ2Zs
b3cuY3gudjNCF0dlbmVyYXRpdmVTZXR0aW5nc1Byb3RvUAFaMWNsb3VkLmdvb2dsZS5jb20v
Z28vZGlhbG9nZmxvdy9jeC9hcGl2My9jeHBiO2N4cGKiAgJERqoCHUdvb2dsZS5DbG91ZC5E
aWFsb2dmbG93LkN4LlYz6gIhR29vZ2xlOjpDbG91ZDo6RGlhbG9nZmxvdzo6Q1g6OlYzSpQe
CgYSBA4AdQEKvAQKAQwSAw4AEjKxBCBDb3B5cmlnaHQgMjAyNiBHb29nbGUgTExDCgogTGlj
ZW5zZWQgdW5kZXIgdGhlIEFwYWNoZSBMaWNlbnNlLCBWZXJzaW9uIDIuMCAodGhlICJMaWNl
bnNlIik7CiB5b3UgbWF5IG5vdCB1c2UgdGhpcyBmaWxlIGV4Y2VwdCBpbiBjb21wbGlhbmNl
IHdpdGggdGhlIExpY2Vuc2UuCiBZb3UgbWF5IG9idGFpbiBhIGNvcHkgb2YgdGhlIExpY2Vu
c2UgYXQKCiAgICAgaHR0cDovL3d3dy5hcGFjaGUub3JnL2xpY2Vuc2VzL0xJQ0VOU0UtMi4w
CgogVW5sZXNzIHJlcXVpcmVkIGJ5IGFwcGxpY2FibGUgbGF3IG9yIGFncmVlZCB0byBpbiB3
cml0aW5nLCBzb2Z0d2FyZQogZGlzdHJpYnV0ZWQgdW5kZXIgdGhlIExpY2Vuc2UgaXMgZGlz
dHJpYnV0ZWQgb24gYW4gIkFTIElTIiBCQVNJUywKIFdJVEhPVVQgV0FSUkFOVElFUyBPUiBD
T05ESVRJT05TIE9GIEFOWSBLSU5ELCBlaXRoZXIgZXhwcmVzcyBvciBpbXBsaWVkLgogU2Vl
IHRoZSBMaWNlbnNlIGZvciB0aGUgc3BlY2lmaWMgbGFuZ3VhZ2UgZ292ZXJuaW5nIHBlcm1p
c3Npb25zIGFuZAogbGltaXRhdGlvbnMgdW5kZXIgdGhlIExpY2Vuc2UuCgoICgECEgMQACYK
CQoCAwASAxIAIwoJCgIDARIDEwA9CggKAQgSAxUAOgoJCgIIJRIDFQA6CggKAQgSAxYASAoJ
CgIICxIDFgBICggKAQgSAxcAIgoJCgIIChIDFwAiCggKAQgSAxgAOAoJCgIICBIDGAA4CggK
AQgSAxkAOgoJCgIIARIDGQA6CggKAQgSAxoAIAoJCgIIJBIDGgAgCggKAQgSAxsAOgoJCgII
LRIDGwA6CikKAgQAEgQeAGwBGh0gU2V0dGluZ3MgZm9yIEdlbmVyYXRpdmUgQUkuCgoKCgME
AAESAx4IGgoLCgMEAAcSBB8CIgQKDQoFBAAHnQgSBB8CIgQKMQoEBAADABIEJQI7AxojIFNl
dHRpbmdzIGZvciBHZW5lcmF0aXZlIEZhbGxiYWNrLgoKDAoFBAADAAESAyUKGgoiCgYEAAMA
AwASBCcEMwUaEiBQcm9tcHQgdGVtcGxhdGUuCgoOCgcEAAMAAwABEgMnDBoKHwoIBAADAAMA
AgASAykGHhoOIFByb21wdCBuYW1lLgoKEAoJBAADAAMAAgAFEgMpBgwKEAoJBAADAAMAAgAB
EgMpDRkKEAoJBAADAAMAAgADEgMpHB0KtQEKCAQAAwADAAIBEgMuBh0aowEgUHJvbXB0IHRl
eHQgdGhhdCBpcyBzZW50IHRvIGEgTExNIG9uIG5vLW1hdGNoIGRlZmF1bHQsIHBsYWNlaG9s
ZGVycyBhcmUKIGZpbGxlZCBkb3duc3RyZWFtLiBGb3IgZXhhbXBsZTogIkhlcmUgaXMgYSBj
b252ZXJzYXRpb24gJGNvbnZlcnNhdGlvbiwKIGEgcmVzcG9uc2UgaXM6ICIKChAKCQQAAwAD
AAIBBRIDLgYMChAKCQQAAwADAAIBARIDLg0YChAKCQQAAwADAAIBAxIDLhscCl4KCAQAAwAD
AAICEgMyBhYaTSBJZiB0aGUgZmxhZyBpcyB0cnVlLCB0aGUgcHJvbXB0IGlzIGZyb3plbiBh
bmQgY2Fubm90IGJlIG1vZGlmaWVkIGJ5CiB1c2Vycy4KChAKCQQAAwADAAICBRIDMgYKChAK
CQQAAwADAAICARIDMgsRChAKCQQAAwADAAICAxIDMhQVCjUKBgQAAwACABIDNgQfGiYgRGlz
cGxheSBuYW1lIG9mIHRoZSBzZWxlY3RlZCBwcm9tcHQuCgoOCgcEAAMAAgAFEgM2BAoKDgoH
BAADAAIAARIDNgsaCg4KBwQAAwACAAMSAzYdHgqLAQoGBAADAAIBEgM6BDEafCBTdG9yZWQg
cHJvbXB0cyB0aGF0IGNhbiBiZSBzZWxlY3RlZCwgZm9yIGV4YW1wbGUgZGVmYXVsdCB0ZW1w
bGF0ZXMgbGlrZQogImNvbnNlcnZhdGl2ZSIgb3IgImNoYXR0eSIsIG9yIHVzZXIgZGVmaW5l
ZCBvbmVzLgoKDgoHBAADAAIBBBIDOgQMCg4KBwQAAwACAQYSAzoNGwoOCgcEAAMAAgEBEgM6
HCwKDgoHBAADAAIBAxIDOi8wCvoBCgQEAAMBEgRBAlgDGusBIFNldHRpbmdzIGZvciBrbm93
bGVkZ2UgY29ubmVjdG9yLiBUaGVzZSBwYXJhbWV0ZXJzIGFyZSB1c2VkIGZvciBMTE0gcHJv
bXB0CiBsaWtlICJZb3UgYXJlIDxhZ2VudD4uIFlvdSBhcmUgYSBoZWxwZnVsIGFuZCB2ZXJi
b3NlIDxhZ2VudF9pZGVudGl0eT4gYXQKIDxidXNpbmVzcz4sIDxidXNpbmVzc19kZXNjcmlw
dGlvbj4uIFlvdXIgdGFzayBpcyB0byBoZWxwIGh1bWFucyBvbgogPGFnZW50X3Njb3BlPiIu
CgoMCgUEAAMBARIDQQokCqIBCgYEAAMBAgASA0UEGBqSASBOYW1lIG9mIHRoZSBjb21wYW55
LCBvcmdhbml6YXRpb24gb3Igb3RoZXIgZW50aXR5IHRoYXQgdGhlIGFnZW50CiByZXByZXNl
bnRzLiBVc2VkIGZvciBrbm93bGVkZ2UgY29ubmVjdG9yIExMTSBwcm9tcHQgYW5kIGZvciBr
bm93bGVkZ2UKIHNlYXJjaC4KCg4KBwQAAwECAAUSA0UECgoOCgcEAAMBAgABEgNFCxMKDgoH
BAADAQIAAxIDRRYXClMKBgQAAwECARIDSAQVGkQgTmFtZSBvZiB0aGUgdmlydHVhbCBhZ2Vu
dC4gVXNlZCBmb3IgTExNIHByb21wdC4gQ2FuIGJlIGxlZnQgZW1wdHkuCgoOCgcEAAMBAgEF
EgNIBAoKDgoHBAADAQIBARIDSAsQCg4KBwQAAwECAQMSA0gTFApNCgYEAAMBAgISA0sEHho+
IElkZW50aXR5IG9mIHRoZSBhZ2VudCwgZS5nLiAidmlydHVhbCBhZ2VudCIsICJBSSBhc3Np
c3RhbnQiLgoKDgoHBAADAQICBRIDSwQKCg4KBwQAAwECAgESA0sLGQoOCgcEAAMBAgIDEgNL
HB0KeQoGBAADAQIDEgNPBCQaaiBDb21wYW55IGRlc2NyaXB0aW9uLCB1c2VkIGZvciBMTE0g
cHJvbXB0LCBlLmcuICJhIGZhbWlseSBjb21wYW55IHNlbGxpbmcKIGZyZXNobHkgcm9hc3Rl
ZCBjb2ZmZWUgYmVhbnMiLgoKDgoHBAADAQIDBRIDTwQKCg4KBwQAAwECAwESA08LHwoOCgcE
AAMBAgMDEgNPIiMKhwEKBgQAAwECBBIDUwQbGnggQWdlbnQgc2NvcGUsIGUuZy4gIkV4YW1w
bGUgY29tcGFueSB3ZWJzaXRlIiwgImludGVybmFsIEV4YW1wbGUKIGNvbXBhbnkgd2Vic2l0
ZSBmb3IgZW1wbG95ZWVzIiwgIm1hbnVhbCBvZiBjYXIgb3duZXIiLgoKDgoHBAADAQIEBRID
UwQKCg4KBwQAAwECBAESA1MLFgoOCgcEAAMBAgQDEgNTGRoKoAEKBgQAAwECBRIDVwQpGpAB
IFdoZXRoZXIgdG8gZGlzYWJsZSBmYWxsYmFjayB0byBEYXRhIFN0b3JlIHNlYXJjaCByZXN1
bHRzIChpbiBjYXNlIHRoZSBMTE0KIGNvdWxkbid0IHBpY2sgYSBwcm9wZXIgYW5zd2VyKS4g
UGVyIGRlZmF1bHQgdGhlIGZlYXR1cmUgaXMgZW5hYmxlZC4KCg4KBwQAAwECBQUSA1cECAoO
CgcEAAMBAgUBEgNXCSQKDgoHBAADAQIFAxIDVycoCmoKBAQAAgASA1wCEhpdIEZvcm1hdDoK
IGBwcm9qZWN0cy88UHJvamVjdElEPi9sb2NhdGlvbnMvPExvY2F0aW9uSUQ+L2FnZW50cy88
QWdlbnRJRD4vZ2VuZXJhdGl2ZVNldHRpbmdzYC4KCgwKBQQAAgAFEgNcAggKDAoFBAACAAES
A1wJDQoMCgUEAAIAAxIDXBARCjAKBAQAAgESA18CKRojIFNldHRpbmdzIGZvciBHZW5lcmF0
aXZlIEZhbGxiYWNrLgoKDAoFBAACAQYSA18CEgoMCgUEAAIBARIDXxMkCgwKBQQAAgEDEgNf
JygKLgoEBAACAhIDYgIwGiEgU2V0dGluZ3MgZm9yIEdlbmVyYXRpdmUgU2FmZXR5LgoKDAoF
BAACAgYSA2ICEAoMCgUEAAICARIDYhErCgwKBQQAAgIDEgNiLi8KMAoEBAACAxIDZQI+GiMg
U2V0dGluZ3MgZm9yIGtub3dsZWRnZSBjb25uZWN0b3IuCgoMCgUEAAIDBhIDZQIcCgwKBQQA
AgMBEgNlHTkKDAoFBAACAwMSA2U8PQoqCgQEAAIEEgNoAhsaHSBMYW5ndWFnZSBmb3IgdGhp
cyBzZXR0aW5ncy4KCgwKBQQAAgQFEgNoAggKDAoFBAACBAESA2gJFgoMCgUEAAIEAxIDaBka
CiIKBAQAAgUSA2sCKhoVIExMTSBtb2RlbCBzZXR0aW5ncy4KCgwKBQQAAgUGEgNrAhIKDAoF
BAACBQESA2sTJQoMCgUEAAIFAxIDaygpCiYKAgQBEgRvAHUBGhogU2V0dGluZ3MgZm9yIExM
TSBtb2RlbHMuCgoKCgMEAQESA28IGAomCgQEAQIAEgNxAhMaGSBUaGUgc2VsZWN0ZWQgTExN
IG1vZGVsLgoKDAoFBAECAAUSA3ECCAoMCgUEAQIAARIDcQkOCgwKBQQBAgADEgNxERIKKAoE
BAECARIDdAIZGhsgVGhlIGN1c3RvbSBwcm9tcHQgdG8gdXNlLgoKDAoFBAECAQUSA3QCCAoM
CgUEAQIBARIDdAkUCgwKBQQBAgEDEgN0FxhiBnByb3RvMw==
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Dialogflow::Cx::V3::GenerativeSettings::GenerativeSettings ===
    # Fields for GenerativeSettings
    # Field: name Type: 9 ()
    # Field: fallback_settings Type: 11 (.google.cloud.dialogflow.cx.v3.GenerativeSettings.FallbackSettings)
    # Field: generative_safety_settings Type: 11 (.google.cloud.dialogflow.cx.v3.SafetySettings)
    # Field: knowledge_connector_settings Type: 11 (.google.cloud.dialogflow.cx.v3.GenerativeSettings.KnowledgeConnectorSettings)
    # Field: language_code Type: 9 ()
    # Field: llm_model_settings Type: 11 (.google.cloud.dialogflow.cx.v3.LlmModelSettings)

# === Message: Google::Cloud::Dialogflow::Cx::V3::GenerativeSettings::LlmModelSettings ===
    # Fields for LlmModelSettings
    # Field: model Type: 9 ()
    # Field: prompt_text Type: 9 ()

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Dialogflow::Cx::V3::GenerativeSettings - Compiled Protocol Buffers messages for google/cloud/dialogflow/cx/v3/generative_settings.proto

=head1 SYNOPSIS

    use Google::Cloud::Dialogflow::Cx::V3::GenerativeSettings;

    my $msg = Google::Cloud::Dialogflow::Cx::V3::GenerativeSettings::GenerativeSettings->new({
        name => $name,
        fallback_settings => $fallback_settings,
        generative_safety_settings => $generative_safety_settings,
        knowledge_connector_settings => $knowledge_connector_settings,
    });

    # Read or update a field
    my $val = $msg->name();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Dialogflow::Cx::V3::GenerativeSettings::GenerativeSettings->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/dialogflow/cx/v3/generative_settings.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Dialogflow::Cx::V3::GenerativeSettings::GenerativeSettings

Settings for Generative AI.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Format:
`projects/<ProjectID>/locations/<LocationID>/agents/<AgentID>/generativeSettings`.

=item * C<< $msg->fallback_settings() >> / C<< $msg->fallback_settings($value) >>

Type: C<Message> (L<Google::Cloud::Dialogflow::Cx::V3::GenerativeSettings::GenerativeSettings::FallbackSettings>)

Settings for Generative Fallback.

=item * C<< $msg->generative_safety_settings() >> / C<< $msg->generative_safety_settings($value) >>

Type: C<Message> (L<Google::Cloud::Dialogflow::Cx::V3::SafetySettings::SafetySettings>)

Settings for Generative Safety.

=item * C<< $msg->knowledge_connector_settings() >> / C<< $msg->knowledge_connector_settings($value) >>

Type: C<Message> (L<Google::Cloud::Dialogflow::Cx::V3::GenerativeSettings::GenerativeSettings::KnowledgeConnectorSettings>)

Settings for knowledge connector.

=item * C<< $msg->language_code() >> / C<< $msg->language_code($value) >>

Type: C<String>

Language for this settings.

=item * C<< $msg->llm_model_settings() >> / C<< $msg->llm_model_settings($value) >>

Type: C<Message> (L<Google::Cloud::Dialogflow::Cx::V3::GenerativeSettings::LlmModelSettings>)

LLM model settings.

=back

=head2 Google::Cloud::Dialogflow::Cx::V3::GenerativeSettings::LlmModelSettings

Settings for LLM models.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->model() >> / C<< $msg->model($value) >>

Type: C<String>

The selected LLM model.

=item * C<< $msg->prompt_text() >> / C<< $msg->prompt_text($value) >>

Type: C<String>

The custom prompt to use.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Dialogflow::Cx::V3::GenerativeSettings::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
