package Google::Cloud::Dialogflow::Cx::V3::SafetySettings;

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
CjNnb29nbGUvY2xvdWQvZGlhbG9nZmxvdy9jeC92My9zYWZldHlfc2V0dGluZ3MucHJvdG8S
HWdvb2dsZS5jbG91ZC5kaWFsb2dmbG93LmN4LnYzGh9nb29nbGUvYXBpL2ZpZWxkX2JlaGF2
aW9yLnByb3RvIt4LCg5TYWZldHlTZXR0aW5ncxKWAQokZGVmYXVsdF9iYW5uZWRfcGhyYXNl
X21hdGNoX3N0cmF0ZWd5GAQgASgOMkEuZ29vZ2xlLmNsb3VkLmRpYWxvZ2Zsb3cuY3gudjMu
U2FmZXR5U2V0dGluZ3MuUGhyYXNlTWF0Y2hTdHJhdGVneUID4EEBUiBkZWZhdWx0QmFubmVk
UGhyYXNlTWF0Y2hTdHJhdGVneRJbCg5iYW5uZWRfcGhyYXNlcxgBIAMoCzI0Lmdvb2dsZS5j
bG91ZC5kaWFsb2dmbG93LmN4LnYzLlNhZmV0eVNldHRpbmdzLlBocmFzZVINYmFubmVkUGhy
YXNlcxJhCgxyYWlfc2V0dGluZ3MYAiABKAsyOS5nb29nbGUuY2xvdWQuZGlhbG9nZmxvdy5j
eC52My5TYWZldHlTZXR0aW5ncy5SYWlTZXR0aW5nc0ID4EEBUgtyYWlTZXR0aW5ncxJzChRk
ZWZhdWx0X3JhaV9zZXR0aW5ncxgDIAEoCzI5Lmdvb2dsZS5jbG91ZC5kaWFsb2dmbG93LmN4
LnYzLlNhZmV0eVNldHRpbmdzLlJhaVNldHRpbmdzQgbgQQHgQQVSEmRlZmF1bHRSYWlTZXR0
aW5ncxKDAQoYcHJvbXB0X3NlY3VyaXR5X3NldHRpbmdzGAggASgLMkQuZ29vZ2xlLmNsb3Vk
LmRpYWxvZ2Zsb3cuY3gudjMuU2FmZXR5U2V0dGluZ3MuUHJvbXB0U2VjdXJpdHlTZXR0aW5n
c0ID4EEBUhZwcm9tcHRTZWN1cml0eVNldHRpbmdzGksKBlBocmFzZRIXCgR0ZXh0GAEgASgJ
QgPgQQJSBHRleHQSKAoNbGFuZ3VhZ2VfY29kZRgCIAEoCUID4EECUgxsYW5ndWFnZUNvZGUa
9AQKC1JhaVNldHRpbmdzEngKEGNhdGVnb3J5X2ZpbHRlcnMYAyADKAsySC5nb29nbGUuY2xv
dWQuZGlhbG9nZmxvdy5jeC52My5TYWZldHlTZXR0aW5ncy5SYWlTZXR0aW5ncy5DYXRlZ29y
eUZpbHRlckID4EEBUg9jYXRlZ29yeUZpbHRlcnMa5gEKDkNhdGVnb3J5RmlsdGVyEmQKCGNh
dGVnb3J5GAEgASgOMkguZ29vZ2xlLmNsb3VkLmRpYWxvZ2Zsb3cuY3gudjMuU2FmZXR5U2V0
dGluZ3MuUmFpU2V0dGluZ3MuU2FmZXR5Q2F0ZWdvcnlSCGNhdGVnb3J5Em4KDGZpbHRlcl9s
ZXZlbBgCIAEoDjJLLmdvb2dsZS5jbG91ZC5kaWFsb2dmbG93LmN4LnYzLlNhZmV0eVNldHRp
bmdzLlJhaVNldHRpbmdzLlNhZmV0eUZpbHRlckxldmVsUgtmaWx0ZXJMZXZlbCJ3ChFTYWZl
dHlGaWx0ZXJMZXZlbBIjCh9TQUZFVFlfRklMVEVSX0xFVkVMX1VOU1BFQ0lGSUVEEAASDgoK
QkxPQ0tfTk9ORRABEg0KCUJMT0NLX0ZFVxACEg4KCkJMT0NLX1NPTUUQAxIOCgpCTE9DS19N
T1NUEAQiiAEKDlNhZmV0eUNhdGVnb3J5Eh8KG1NBRkVUWV9DQVRFR09SWV9VTlNQRUNJRklF
RBAAEhUKEURBTkdFUk9VU19DT05URU5UEAESDwoLSEFURV9TUEVFQ0gQAhIOCgpIQVJBU1NN
RU5UEAMSHQoZU0VYVUFMTFlfRVhQTElDSVRfQ09OVEVOVBAEGlMKFlByb21wdFNlY3VyaXR5
U2V0dGluZ3MSOQoWZW5hYmxlX3Byb21wdF9zZWN1cml0eRgBIAEoCEID4EEBUhRlbmFibGVQ
cm9tcHRTZWN1cml0eSJfChNQaHJhc2VNYXRjaFN0cmF0ZWd5EiUKIVBIUkFTRV9NQVRDSF9T
VFJBVEVHWV9VTlNQRUNJRklFRBAAEhEKDVBBUlRJQUxfTUFUQ0gQARIOCgpXT1JEX01BVENI
EAJCtgEKIWNvbS5nb29nbGUuY2xvdWQuZGlhbG9nZmxvdy5jeC52M0ITU2FmZXR5U2V0dGlu
Z3NQcm90b1ABWjFjbG91ZC5nb29nbGUuY29tL2dvL2RpYWxvZ2Zsb3cvY3gvYXBpdjMvY3hw
YjtjeHBiogICREaqAh1Hb29nbGUuQ2xvdWQuRGlhbG9nZmxvdy5DeC5WM+oCIUdvb2dsZTo6
Q2xvdWQ6OkRpYWxvZ2Zsb3c6OkNYOjpWM0q9IQoHEgUOAIQBAQq8BAoBDBIDDgASMrEEIENv
cHlyaWdodCAyMDI2IEdvb2dsZSBMTEMKCiBMaWNlbnNlZCB1bmRlciB0aGUgQXBhY2hlIExp
Y2Vuc2UsIFZlcnNpb24gMi4wICh0aGUgIkxpY2Vuc2UiKTsKIHlvdSBtYXkgbm90IHVzZSB0
aGlzIGZpbGUgZXhjZXB0IGluIGNvbXBsaWFuY2Ugd2l0aCB0aGUgTGljZW5zZS4KIFlvdSBt
YXkgb2J0YWluIGEgY29weSBvZiB0aGUgTGljZW5zZSBhdAoKICAgICBodHRwOi8vd3d3LmFw
YWNoZS5vcmcvbGljZW5zZXMvTElDRU5TRS0yLjAKCiBVbmxlc3MgcmVxdWlyZWQgYnkgYXBw
bGljYWJsZSBsYXcgb3IgYWdyZWVkIHRvIGluIHdyaXRpbmcsIHNvZnR3YXJlCiBkaXN0cmli
dXRlZCB1bmRlciB0aGUgTGljZW5zZSBpcyBkaXN0cmlidXRlZCBvbiBhbiAiQVMgSVMiIEJB
U0lTLAogV0lUSE9VVCBXQVJSQU5USUVTIE9SIENPTkRJVElPTlMgT0YgQU5ZIEtJTkQsIGVp
dGhlciBleHByZXNzIG9yIGltcGxpZWQuCiBTZWUgdGhlIExpY2Vuc2UgZm9yIHRoZSBzcGVj
aWZpYyBsYW5ndWFnZSBnb3Zlcm5pbmcgcGVybWlzc2lvbnMgYW5kCiBsaW1pdGF0aW9ucyB1
bmRlciB0aGUgTGljZW5zZS4KCggKAQISAxAAJgoJCgIDABIDEgApCggKAQgSAxQAOgoJCgII
JRIDFAA6CggKAQgSAxUASAoJCgIICxIDFQBICggKAQgSAxYAIgoJCgIIChIDFgAiCggKAQgS
AxcANAoJCgIICBIDFwA0CggKAQgSAxgAOgoJCgIIARIDGAA6CggKAQgSAxkAIAoJCgIIJBID
GQAgCggKAQgSAxoAOgoJCgIILRIDGgA6Ci4KAgQAEgUdAIQBARohIFNldHRpbmdzIGZvciBH
ZW5lcmF0aXZlIFNhZmV0eS4KCgoKAwQAARIDHQgWCkoKBAQAAwASBB8CJQMaPCBUZXh0IGlu
cHV0IHdoaWNoIGNhbiBiZSB1c2VkIGZvciBwcm9tcHQgb3IgYmFubmVkIHBocmFzZXMuCgoM
CgUEAAMAARIDHwoQClUKBgQAAwACABIDIQQ9GkYgUmVxdWlyZWQuIFRleHQgaW5wdXQgd2hp
Y2ggY2FuIGJlIHVzZWQgZm9yIHByb21wdCBvciBiYW5uZWQgcGhyYXNlcy4KCg4KBwQAAwAC
AAUSAyEECgoOCgcEAAMAAgABEgMhCw8KDgoHBAADAAIAAxIDIRITCg4KBwQAAwACAAgSAyEU
PAoRCgoEAAMAAgAInAgAEgMhFTsKNwoGBAADAAIBEgMkBEYaKCBSZXF1aXJlZC4gTGFuZ3Vh
Z2UgY29kZSBvZiB0aGUgcGhyYXNlLgoKDgoHBAADAAIBBRIDJAQKCg4KBwQAAwACAQESAyQL
GAoOCgcEAAMAAgEDEgMkGxwKDgoHBAADAAIBCBIDJB1FChEKCgQAAwACAQicCAASAyQeRAou
CgQEAAQAEgQoAjMDGiAgU3RyYXRlZ3kgZm9yIG1hdGNoaW5nIHBocmFzZXMuCgoMCgUEAAQA
ARIDKAcaCjgKBgQABAACABIDKgQqGikgVW5zcGVjaWZpZWQsIGRlZmF1bHRzIHRvIFBBUlRJ
QUxfTUFUQ0guCgoOCgcEAAQAAgABEgMqBCUKDgoHBAAEAAIAAhIDKigpCnAKBgQABAACARID
LgQWGmEgVGV4dCB0aGF0IGNvbnRhaW5zIHRoZSBwaHJhc2UgYXMgYSBzdWJzdHJpbmcgd2ls
bCBiZSBtYXRjaGVkLCBlLmcuICJmb28iCiB3aWxsIG1hdGNoICJhZm9vYmFyIi4KCg4KBwQA
BAACAQESAy4EEQoOCgcEAAQAAgECEgMuFBUKmwEKBgQABAACAhIDMgQTGosBIFRleHQgdGhh
dCBjb250YWlucyB0aGUgdG9rZW5pemVkIHdvcmRzIG9mIHRoZSBwaHJhc2Ugd2lsbCBiZSBt
YXRjaGVkLAogZS5nLiAiZm9vIiB3aWxsIG1hdGNoICJhIGZvbyBiYXIiIGFuZCAiZm9vIGJh
ciIsIGJ1dCBub3QgImZvb2JhciIuCgoOCgcEAAQAAgIBEgMyBA4KDgoHBAAEAAICAhIDMhES
CiwKBAQAAwESBDYCZwMaHiBTZXR0aW5ncyBmb3IgUmVzcG9uc2libGUgQUkuCgoMCgUEAAMB
ARIDNgoVCjcKBgQAAwEEABIEOARHBRonIFNlbnNpdGl2aXR5IGxldmVsIGZvciBSQUkgY2F0
ZWdvcmllcy4KCg4KBwQAAwEEAAESAzgJGgpCCggEAAMBBAACABIDOgYqGjEgVW5zcGVjaWZp
ZWQgLS0gdXNlcyBkZWZhdWx0IHNlbnNpdGl2aXR5IGxldmVscy4KChAKCQQAAwEEAAIAARID
OgYlChAKCQQAAwEEAAIAAhIDOigpCkYKCAQAAwEEAAIBEgM9BhUaNSBCbG9jayBubyB0ZXh0
IC0tIGVmZmVjdGl2ZWx5IGRpc2FibGVzIHRoZSBjYXRlZ29yeS4KChAKCQQAAwEEAAIBARID
PQYQChAKCQQAAwEEAAIBAhIDPRMUCjAKCAQAAwEEAAICEgNABhQaHyBCbG9jayBhIGZldyBz
dXNwaWNpb3VzIHRleHRzLgoKEAoJBAADAQQAAgIBEgNABg8KEAoJBAADAQQAAgICEgNAEhMK
LwoIBAADAQQAAgMSA0MGFRoeIEJsb2NrIHNvbWUgc3VzcGljaW91cyB0ZXh0cy4KChAKCQQA
AwEEAAIDARIDQwYQChAKCQQAAwEEAAIDAhIDQxMUCi8KCAQAAwEEAAIEEgNGBhUaHiBCbG9j
ayBtb3N0IHN1c3BpY2lvdXMgdGV4dHMuCgoQCgkEAAMBBAACBAESA0YGEAoQCgkEAAMBBAAC
BAISA0YTFAouCgYEAAMBBAESBEoEWQUaHiBSQUkgY2F0ZWdvcmllcyB0byBjb25maWd1cmUu
CgoOCgcEAAMBBAEBEgNKCRcKHwoIBAADAQQBAgASA0wGJhoOIFVuc3BlY2lmaWVkLgoKEAoJ
BAADAQQBAgABEgNMBiEKEAoJBAADAQQBAgACEgNMJCUKJQoIBAADAQQBAgESA08GHBoUIERh
bmdlcm91cyBjb250ZW50LgoKEAoJBAADAQQBAgEBEgNPBhcKEAoJBAADAQQBAgECEgNPGhsK
HwoIBAADAQQBAgISA1IGFhoOIEhhdGUgc3BlZWNoLgoKEAoJBAADAQQBAgIBEgNSBhEKEAoJ
BAADAQQBAgICEgNSFBUKHgoIBAADAQQBAgMSA1UGFRoNIEhhcmFzc21lbnQuCgoQCgkEAAMB
BAECAwESA1UGEAoQCgkEAAMBBAECAwISA1UTFAotCggEAAMBBAECBBIDWAYkGhwgU2V4dWFs
bHkgZXhwbGljaXQgY29udGVudC4KChAKCQQAAwEEAQIEARIDWAYfChAKCQQAAwEEAQIEAhID
WCIjClYKBgQAAwEDABIEXARiBRpGIENvbmZpZ3VyYXRpb24gb2YgdGhlIHNlbnNpdGl2aXR5
IGxldmVsIGZvciBibG9ja2luZyBhbiBSQUkgY2F0ZWdvcnkuCgoOCgcEAAMBAwABEgNcDBoK
LQoIBAADAQMAAgASA14GIhocIFJBSSBjYXRlZ29yeSB0byBjb25maWd1cmUuCgoQCgkEAAMB
AwACAAYSA14GFAoQCgkEAAMBAwACAAESA14VHQoQCgkEAAMBAwACAAMSA14gIQpQCggEAAMB
AwACARIDYQYpGj8gQmxvY2tpbmcgc2Vuc2l0aXZpdHkgbGV2ZWwgdG8gY29uZmlndXJlIGZv
ciB0aGUgUkFJIGNhdGVnb3J5LgoKEAoJBAADAQMAAgEGEgNhBhcKEAoJBAADAQMAAgEBEgNh
GCQKEAoJBAADAQMAAgEDEgNhJygKOAoGBAADAQIAEgRlBGYxGiggT3B0aW9uYWwuIFJBSSBi
bG9ja2luZyBjb25maWd1cmF0aW9ucy4KCg4KBwQAAwECAAQSA2UEDAoOCgcEAAMBAgAGEgNl
DRsKDgoHBAADAQIAARIDZRwsCg4KBwQAAwECAAMSA2UvMAoOCgcEAAMBAgAIEgNmCDAKEQoK
BAADAQIACJwIABIDZgkvCjQKBAQAAwISBGoCbQMaJiBTZXR0aW5ncyBmb3IgcHJvbXB0IHNl
Y3VyaXR5IGNoZWNrcy4KCgwKBQQAAwIBEgNqCiAKOQoGBAADAgIAEgNsBE0aKiBPcHRpb25h
bC4gRW5hYmxlIHByb21wdCBzZWN1cml0eSBjaGVja3MuCgoOCgcEAAMCAgAFEgNsBAgKDgoH
BAADAgIAARIDbAkfCg4KBwQAAwICAAMSA2wiIwoOCgcEAAMCAgAIEgNsJEwKEQoKBAADAgIA
CJwIABIDbCVLCksKBAQAAgASBHACcS8aPSBPcHRpb25hbC4gRGVmYXVsdCBwaHJhc2UgbWF0
Y2ggc3RyYXRlZ3kgZm9yIGJhbm5lZCBwaHJhc2VzLgoKDAoFBAACAAYSA3ACFQoMCgUEAAIA
ARIDcBY6CgwKBQQAAgADEgNwPT4KDAoFBAACAAgSA3EGLgoPCggEAAIACJwIABIDcQctCjEK
BAQAAgESA3QCJRokIEJhbm5lZCBwaHJhc2VzIGZvciBnZW5lcmF0ZWQgdGV4dC4KCgwKBQQA
AgEEEgN0AgoKDAoFBAACAQYSA3QLEQoMCgUEAAIBARIDdBIgCgwKBQQAAgEDEgN0IyQKPAoE
BAACAhIDdwJIGi8gT3B0aW9uYWwuIFNldHRpbmdzIGZvciBSZXNwb25zaWJsZSBBSSBjaGVj
a3MuCgoMCgUEAAICBhIDdwINCgwKBQQAAgIBEgN3DhoKDAoFBAACAgMSA3cdHgoMCgUEAAIC
CBIDdx9HCg8KCAQAAgIInAgAEgN3IEYK2gEKBAQAAgMSBHwCfwQaywEgT3B0aW9uYWwuIElt
bXV0YWJsZS4gRGVmYXVsdCBSQUkgc2V0dGluZ3MgdG8gYmUgYW5ub3RhdGVkIG9uIHRoZSBh
Z2VudCwgc28KIHRoYXQgdXNlcnMgd2lsbCBiZSBhYmxlIHRvIHJlc3RvcmUgdGhlaXIgUkFJ
IGNvbmZpZ3VyYXRpb25zIHRvIHRoZSBkZWZhdWx0CiBzZXR0aW5ncy4gUmVhZC1vbmx5IGZp
ZWxkIGZvciB0aGUgQVBJIHByb3RvIG9ubHkuCgoMCgUEAAIDBhIDfAINCgwKBQQAAgMBEgN8
DiIKDAoFBAACAwMSA3wlJgoNCgUEAAIDCBIEfCd/AwoPCggEAAIDCJwIABIDfQQqCg8KCAQA
AgMInAgBEgN+BCsKQAoEBAACBBIGggECgwEvGjAgT3B0aW9uYWwuIFNldHRpbmdzIGZvciBw
cm9tcHQgc2VjdXJpdHkgY2hlY2tzLgoKDQoFBAACBAYSBIIBAhgKDQoFBAACBAESBIIBGTEK
DQoFBAACBAMSBIIBNDUKDQoFBAACBAgSBIMBBi4KEAoIBAACBAicCAASBIMBBy1iBnByb3Rv
Mw==
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Dialogflow::Cx::V3::SafetySettings::SafetySettings ===
    # Fields for SafetySettings
    # Field: default_banned_phrase_match_strategy Type: 14 (.google.cloud.dialogflow.cx.v3.SafetySettings.PhraseMatchStrategy)
    # Field: banned_phrases Type: 11 (.google.cloud.dialogflow.cx.v3.SafetySettings.Phrase)
    # Field: rai_settings Type: 11 (.google.cloud.dialogflow.cx.v3.SafetySettings.RaiSettings)
    # Field: default_rai_settings Type: 11 (.google.cloud.dialogflow.cx.v3.SafetySettings.RaiSettings)
    # Field: prompt_security_settings Type: 11 (.google.cloud.dialogflow.cx.v3.SafetySettings.PromptSecuritySettings)

# Enum: SafetySettings::PhraseMatchStrategy
our $SafetySettings_PHRASE_MATCH_STRATEGY_UNSPECIFIED = 0;
our $SafetySettings_PARTIAL_MATCH = 1;
our $SafetySettings_WORD_MATCH = 2;

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Dialogflow::Cx::V3::SafetySettings - Compiled Protocol Buffers messages for google/cloud/dialogflow/cx/v3/safety_settings.proto

=head1 SYNOPSIS

    use Google::Cloud::Dialogflow::Cx::V3::SafetySettings;

    my $msg = Google::Cloud::Dialogflow::Cx::V3::SafetySettings::SafetySettings->new({
        default_banned_phrase_match_strategy => $default_banned_phrase_match_strategy,
        banned_phrases => $banned_phrases,
        rai_settings => $rai_settings,
        default_rai_settings => $default_rai_settings,
    });

    # Read or update a field
    my $val = $msg->default_banned_phrase_match_strategy();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Dialogflow::Cx::V3::SafetySettings::SafetySettings->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/dialogflow/cx/v3/safety_settings.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Dialogflow::Cx::V3::SafetySettings::SafetySettings

Settings for Generative Safety.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->default_banned_phrase_match_strategy() >> / C<< $msg->default_banned_phrase_match_strategy($value) >>

Type: C<Enum> (L<Google::Cloud::Dialogflow::Cx::V3::SafetySettings::PhraseMatchStrategy>)

Optional. Default phrase match strategy for banned phrases.

=item * C<< $msg->banned_phrases() >> / C<< $msg->banned_phrases($value) >>

Type: C<Message> (L<Google::Cloud::Dialogflow::Cx::V3::SafetySettings::SafetySettings::Phrase>)

Banned phrases for generated text.

=item * C<< $msg->rai_settings() >> / C<< $msg->rai_settings($value) >>

Type: C<Message> (L<Google::Cloud::Dialogflow::Cx::V3::SafetySettings::SafetySettings::RaiSettings>)

Optional. Settings for Responsible AI checks.

=item * C<< $msg->default_rai_settings() >> / C<< $msg->default_rai_settings($value) >>

Type: C<Message> (L<Google::Cloud::Dialogflow::Cx::V3::SafetySettings::SafetySettings::RaiSettings>)

Optional. Immutable. Default RAI settings to be annotated on the agent, so
that users will be able to restore their RAI configurations to the default
settings. Read-only field for the API proto only.

=item * C<< $msg->prompt_security_settings() >> / C<< $msg->prompt_security_settings($value) >>

Type: C<Message> (L<Google::Cloud::Dialogflow::Cx::V3::SafetySettings::SafetySettings::PromptSecuritySettings>)

Optional. Settings for prompt security checks.

=back

=head3 Enum: SafetySettings::PhraseMatchStrategy

=over 4

=item * C<PHRASE_MATCH_STRATEGY_UNSPECIFIED> => C<0>

=item * C<PARTIAL_MATCH> => C<1>

=item * C<WORD_MATCH> => C<2>

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Dialogflow::Cx::V3::SafetySettings::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
