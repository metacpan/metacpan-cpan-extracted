package Google::Cloud::Speech::V2::LocationsMetadata;

use strict;
use warnings;

our $VERSION = '0.14';

use Protobuf::Message;
use Protobuf::DescriptorPool;
use Protobuf::Internal qw(:all);
use MIME::Base64;

BEGIN {
    my $descriptor_b64 = <<'EOF';
Ci9nb29nbGUvY2xvdWQvc3BlZWNoL3YyL2xvY2F0aW9uc19tZXRhZGF0YS5wcm90bxIWZ29v
Z2xlLmNsb3VkLnNwZWVjaC52MiJNCgxNb2RlbEZlYXR1cmUSGAoHZmVhdHVyZRgBIAEoCVIH
ZmVhdHVyZRIjCg1yZWxlYXNlX3N0YXRlGAIgASgJUgxyZWxlYXNlU3RhdGUiWgoNTW9kZWxG
ZWF0dXJlcxJJCg1tb2RlbF9mZWF0dXJlGAEgAygLMiQuZ29vZ2xlLmNsb3VkLnNwZWVjaC52
Mi5Nb2RlbEZlYXR1cmVSDG1vZGVsRmVhdHVyZSLZAQoNTW9kZWxNZXRhZGF0YRJfCg5tb2Rl
bF9mZWF0dXJlcxgBIAMoCzI4Lmdvb2dsZS5jbG91ZC5zcGVlY2gudjIuTW9kZWxNZXRhZGF0
YS5Nb2RlbEZlYXR1cmVzRW50cnlSDW1vZGVsRmVhdHVyZXMaZwoSTW9kZWxGZWF0dXJlc0Vu
dHJ5EhAKA2tleRgBIAEoCVIDa2V5EjsKBXZhbHVlGAIgASgLMiUuZ29vZ2xlLmNsb3VkLnNw
ZWVjaC52Mi5Nb2RlbEZlYXR1cmVzUgV2YWx1ZToCOAEiwgEKEExhbmd1YWdlTWV0YWRhdGES
TAoGbW9kZWxzGAEgAygLMjQuZ29vZ2xlLmNsb3VkLnNwZWVjaC52Mi5MYW5ndWFnZU1ldGFk
YXRhLk1vZGVsc0VudHJ5UgZtb2RlbHMaYAoLTW9kZWxzRW50cnkSEAoDa2V5GAEgASgJUgNr
ZXkSOwoFdmFsdWUYAiABKAsyJS5nb29nbGUuY2xvdWQuc3BlZWNoLnYyLk1vZGVsTWV0YWRh
dGFSBXZhbHVlOgI4ASLYAQoOQWNjZXNzTWV0YWRhdGESXgoPY29uc3RyYWludF90eXBlGAEg
ASgOMjUuZ29vZ2xlLmNsb3VkLnNwZWVjaC52Mi5BY2Nlc3NNZXRhZGF0YS5Db25zdHJhaW50
VHlwZVIOY29uc3RyYWludFR5cGUiZgoOQ29uc3RyYWludFR5cGUSHwobQ09OU1RSQUlOVF9U
WVBFX1VOU1BFQ0lGSUVEEAASMwovUkVTT1VSQ0VfTE9DQVRJT05TX09SR19QT0xJQ1lfQ1JF
QVRFX0NPTlNUUkFJTlQQASKsAQoRTG9jYXRpb25zTWV0YWRhdGESRgoJbGFuZ3VhZ2VzGAEg
ASgLMiguZ29vZ2xlLmNsb3VkLnNwZWVjaC52Mi5MYW5ndWFnZU1ldGFkYXRhUglsYW5ndWFn
ZXMSTwoPYWNjZXNzX21ldGFkYXRhGAIgASgLMiYuZ29vZ2xlLmNsb3VkLnNwZWVjaC52Mi5B
Y2Nlc3NNZXRhZGF0YVIOYWNjZXNzTWV0YWRhdGFCagoaY29tLmdvb2dsZS5jbG91ZC5zcGVl
Y2gudjJCFkxvY2F0aW9uc01ldGFkYXRhUHJvdG9QAVoyY2xvdWQuZ29vZ2xlLmNvbS9nby9z
cGVlY2gvYXBpdjIvc3BlZWNocGI7c3BlZWNocGJKmBYKBhIEDgBPAQq8BAoBDBIDDgASMrEE
IENvcHlyaWdodCAyMDI2IEdvb2dsZSBMTEMKCiBMaWNlbnNlZCB1bmRlciB0aGUgQXBhY2hl
IExpY2Vuc2UsIFZlcnNpb24gMi4wICh0aGUgIkxpY2Vuc2UiKTsKIHlvdSBtYXkgbm90IHVz
ZSB0aGlzIGZpbGUgZXhjZXB0IGluIGNvbXBsaWFuY2Ugd2l0aCB0aGUgTGljZW5zZS4KIFlv
dSBtYXkgb2J0YWluIGEgY29weSBvZiB0aGUgTGljZW5zZSBhdAoKICAgICBodHRwOi8vd3d3
LmFwYWNoZS5vcmcvbGljZW5zZXMvTElDRU5TRS0yLjAKCiBVbmxlc3MgcmVxdWlyZWQgYnkg
YXBwbGljYWJsZSBsYXcgb3IgYWdyZWVkIHRvIGluIHdyaXRpbmcsIHNvZnR3YXJlCiBkaXN0
cmlidXRlZCB1bmRlciB0aGUgTGljZW5zZSBpcyBkaXN0cmlidXRlZCBvbiBhbiAiQVMgSVMi
IEJBU0lTLAogV0lUSE9VVCBXQVJSQU5USUVTIE9SIENPTkRJVElPTlMgT0YgQU5ZIEtJTkQs
IGVpdGhlciBleHByZXNzIG9yIGltcGxpZWQuCiBTZWUgdGhlIExpY2Vuc2UgZm9yIHRoZSBz
cGVjaWZpYyBsYW5ndWFnZSBnb3Zlcm5pbmcgcGVybWlzc2lvbnMgYW5kCiBsaW1pdGF0aW9u
cyB1bmRlciB0aGUgTGljZW5zZS4KCggKAQISAxAAHwoICgEIEgMSAEkKCQoCCAsSAxIASQoI
CgEIEgMTACIKCQoCCAoSAxMAIgoICgEIEgMUADcKCQoCCAgSAxQANwoICgEIEgMVADMKCQoC
CAESAxUAMwqkAQoCBAASBBkAHwEalwEgUmVwcmVzZW50cyBhIHNpbmd1bGFyIGZlYXR1cmUg
b2YgYSBtb2RlbC4gSWYgdGhlIGZlYXR1cmUgaXMgYHJlY29nbml6ZXJgLAogdGhlIHJlbGVh
c2Vfc3RhdGUgb2YgdGhlIGZlYXR1cmUgcmVwcmVzZW50cyB0aGUgcmVsZWFzZV9zdGF0ZSBv
ZiB0aGUgbW9kZWwKCgoKAwQAARIDGQgUCk4KBAQAAgASAxsCFRpBIFRoZSBuYW1lIG9mIHRo
ZSBmZWF0dXJlIChOb3RlOiB0aGUgZmVhdHVyZSBjYW4gYmUgYHJlY29nbml6ZXJgKQoKDAoF
BAACAAUSAxsCCAoMCgUEAAIAARIDGwkQCgwKBQQAAgADEgMbExQKLwoEBAACARIDHgIbGiIg
VGhlIHJlbGVhc2Ugc3RhdGUgb2YgdGhlIGZlYXR1cmUKCgwKBQQAAgEFEgMeAggKDAoFBAAC
AQESAx4JFgoMCgUEAAIBAxIDHhkaCkgKAgQBEgQiACUBGjwgUmVwcmVzZW50cyB0aGUgY29s
bGVjdGlvbiBvZiBmZWF0dXJlcyBiZWxvbmdpbmcgdG8gYSBtb2RlbAoKCgoDBAEBEgMiCBUK
RQoEBAECABIDJAIqGjggUmVwZWF0ZWQgZmllbGQgdGhhdCBjb250YWlucyBhbGwgZmVhdHVy
ZXMgb2YgdGhlIG1vZGVsCgoMCgUEAQIABBIDJAIKCgwKBQQBAgAGEgMkCxcKDAoFBAECAAES
AyQYJQoMCgUEAQIAAxIDJCgpCoYBCgIEAhIEKQAsARp6IFRoZSBtZXRhZGF0YSBhYm91dCB0
aGUgbW9kZWxzIGluIGEgZ2l2ZW4gcmVnaW9uIGZvciBhIHNwZWNpZmljIGxvY2FsZS4KIEN1
cnJlbnRseSB0aGlzIGlzIGp1c3QgdGhlIGZlYXR1cmVzIG9mIHRoZSBtb2RlbAoKCgoDBAIB
EgMpCBUKPgoEBAICABIDKwIwGjEgTWFwIG9mIHRoZSBtb2RlbCBuYW1lIC0+IGZlYXR1cmVz
IG9mIHRoYXQgbW9kZWwKCgwKBQQCAgAGEgMrAhwKDAoFBAICAAESAysdKwoMCgUEAgIAAxID
Ky4vCosBCgIEAxIEMAAzARp/IFRoZSBtZXRhZGF0YSBhYm91dCBsb2NhbGVzIGF2YWlsYWJs
ZSBpbiBhIGdpdmVuIHJlZ2lvbi4gQ3VycmVudGx5IHRoaXMgaXMKIGp1c3QgdGhlIG1vZGVs
cyB0aGF0IGFyZSBhdmFpbGFibGUgZm9yIGVhY2ggbG9jYWxlCgoKCgMEAwESAzAIGAo2CgQE
AwIAEgMyAigaKSBNYXAgb2YgbG9jYWxlIChsYW5ndWFnZSBjb2RlKSAtPiBtb2RlbHMKCgwK
BQQDAgAGEgMyAhwKDAoFBAMCAAESAzIdIwoMCgUEAwIAAxIDMiYnCpcBCgIEBBIENwBEARqK
ASBUaGUgYWNjZXNzIG1ldGFkYXRhIGZvciBhIHBhcnRpY3VsYXIgcmVnaW9uLiBUaGlzIGNh
biBiZSBhcHBsaWVkIGlmIHRoZSBvcmcKIHBvbGljeSBmb3IgdGhlIGdpdmVuIHByb2plY3Qg
ZGlzYWxsb3dzIGEgcGFydGljdWxhciByZWdpb24uCgoKCgMEBAESAzcIFgpeCgQEBAQAEgQ6
AkADGlAgRGVzY3JpYmVzIHRoZSBkaWZmZXJlbnQgdHlwZXMgb2YgY29uc3RyYWludHMgdGhh
dCBjYW4gYmUgYXBwbGllZCBvbiBhCiByZWdpb24uCgoMCgUEBAQAARIDOgcVCjAKBgQEBAAC
ABIDPAQkGiEgVW5zcGVjaWZpZWQgY29uc3RyYWludCBhcHBsaWVkLgoKDgoHBAQEAAIAARID
PAQfCg4KBwQEBAACAAISAzwiIwpFCgYEBAQAAgESAz8EOBo2IFRoZSBwcm9qZWN0J3Mgb3Jn
IHBvbGljeSBkaXNhbGxvd3MgdGhlIGdpdmVuIHJlZ2lvbi4KCg4KBwQEBAACAQESAz8EMwoO
CgcEBAQAAgECEgM/NjcKTQoEBAQCABIDQwIlGkAgRGVzY3JpYmVzIHRoZSBkaWZmZXJlbnQg
dHlwZXMgb2YgY29uc3RyYWludHMgdGhhdCBhcmUgYXBwbGllZC4KCgwKBQQEAgAGEgNDAhAK
DAoFBAQCAAESA0MRIAoMCgUEBAIAAxIDQyMkCoYBCgIEBRIESABPARp6IE1haW4gbWV0YWRh
dGEgZm9yIHRoZSBMb2NhdGlvbnMgQVBJIGZvciBTVFQgVjIuIEN1cnJlbnRseSB0aGlzIGlz
IGp1c3QgdGhlCiBtZXRhZGF0YSBhYm91dCBsb2NhbGVzLCBtb2RlbHMsIGFuZCBmZWF0dXJl
cwoKCgoDBAUBEgNICBkKlQEKBAQFAgASA0sCIRqHASBJbmZvcm1hdGlvbiBhYm91dCBhdmFp
bGFibGUgbG9jYWxlcywgbW9kZWxzLCBhbmQgZmVhdHVyZXMgcmVwcmVzZW50ZWQgaW4KIHRo
ZSBoaWVyYXJjaGljYWwgc3RydWN0dXJlIG9mIGxvY2FsZXMgLT4gbW9kZWxzIC0+IGZlYXR1
cmVzCgoMCgUEBQIABhIDSwISCgwKBQQFAgABEgNLExwKDAoFBAUCAAMSA0sfIApSCgQEBQIB
EgNOAiUaRSBJbmZvcm1hdGlvbiBhYm91dCBhY2Nlc3MgbWV0YWRhdGEgZm9yIHRoZSByZWdp
b24gYW5kIGdpdmVuIHByb2plY3QuCgoMCgUEBQIBBhIDTgIQCgwKBQQFAgEBEgNOESAKDAoF
BAUCAQMSA04jJGIGcHJvdG8z
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Speech::V2::LocationsMetadata::ModelFeature ===
    # Fields for ModelFeature
    # Field: feature Type: 9 ()
    # Field: release_state Type: 9 ()

# === Message: Google::Cloud::Speech::V2::LocationsMetadata::ModelFeatures ===
    # Fields for ModelFeatures
    # Field: model_feature Type: 11 (.google.cloud.speech.v2.ModelFeature)

# === Message: Google::Cloud::Speech::V2::LocationsMetadata::ModelMetadata ===
    # Fields for ModelMetadata
    # Field: model_features Type: 11 (.google.cloud.speech.v2.ModelMetadata.ModelFeaturesEntry)

# === Message: Google::Cloud::Speech::V2::LocationsMetadata::LanguageMetadata ===
    # Fields for LanguageMetadata
    # Field: models Type: 11 (.google.cloud.speech.v2.LanguageMetadata.ModelsEntry)

# === Message: Google::Cloud::Speech::V2::LocationsMetadata::AccessMetadata ===
    # Fields for AccessMetadata
    # Field: constraint_type Type: 14 (.google.cloud.speech.v2.AccessMetadata.ConstraintType)

# Enum: AccessMetadata::ConstraintType
our $AccessMetadata_CONSTRAINT_TYPE_UNSPECIFIED = 0;
our $AccessMetadata_RESOURCE_LOCATIONS_ORG_POLICY_CREATE_CONSTRAINT = 1;

# === Message: Google::Cloud::Speech::V2::LocationsMetadata::LocationsMetadata ===
    # Fields for LocationsMetadata
    # Field: languages Type: 11 (.google.cloud.speech.v2.LanguageMetadata)
    # Field: access_metadata Type: 11 (.google.cloud.speech.v2.AccessMetadata)

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Speech::V2::LocationsMetadata - Compiled Protocol Buffers messages for google/cloud/speech/v2/locations_metadata.proto

=head1 SYNOPSIS

    use Google::Cloud::Speech::V2::LocationsMetadata;

    my $msg = Google::Cloud::Speech::V2::LocationsMetadata::ModelFeature->new({
        feature => $feature,
        release_state => $release_state,
    });

    # Read or update a field
    my $val = $msg->feature();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Speech::V2::LocationsMetadata::ModelFeature->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/speech/v2/locations_metadata.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Speech::V2::LocationsMetadata::ModelFeature

Represents a singular feature of a model. If the feature is `recognizer`,
the release_state of the feature represents the release_state of the model

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->feature() >> / C<< $msg->feature($value) >>

Type: C<String>

The name of the feature (Note: the feature can be `recognizer`)

=item * C<< $msg->release_state() >> / C<< $msg->release_state($value) >>

Type: C<String>

The release state of the feature

=back

=head2 Google::Cloud::Speech::V2::LocationsMetadata::ModelFeatures

Represents the collection of features belonging to a model

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->model_feature() >> / C<< $msg->model_feature($value) >>

Type: C<Message> (L<Google::Cloud::Speech::V2::LocationsMetadata::ModelFeature>)

Repeated field that contains all features of the model

=back

=head2 Google::Cloud::Speech::V2::LocationsMetadata::ModelMetadata

The metadata about the models in a given region for a specific locale.
Currently this is just the features of the model

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->model_features() >> / C<< $msg->model_features($value) >>

Type: C<Message> (L<Google::Cloud::Speech::V2::LocationsMetadata::ModelMetadata::ModelFeaturesEntry>)

Map of the model name -> features of that model

=back

=head2 Google::Cloud::Speech::V2::LocationsMetadata::LanguageMetadata

The metadata about locales available in a given region. Currently this is
just the models that are available for each locale

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->models() >> / C<< $msg->models($value) >>

Type: C<Message> (L<Google::Cloud::Speech::V2::LocationsMetadata::LanguageMetadata::ModelsEntry>)

Map of locale (language code) -> models

=back

=head2 Google::Cloud::Speech::V2::LocationsMetadata::AccessMetadata

The access metadata for a particular region. This can be applied if the org
policy for the given project disallows a particular region.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->constraint_type() >> / C<< $msg->constraint_type($value) >>

Type: C<Enum> (L<Google::Cloud::Speech::V2::AccessMetadata::ConstraintType>)

Describes the different types of constraints that are applied.

=back

=head3 Enum: AccessMetadata::ConstraintType

=over 4

=item * C<CONSTRAINT_TYPE_UNSPECIFIED> => C<0>

=item * C<RESOURCE_LOCATIONS_ORG_POLICY_CREATE_CONSTRAINT> => C<1>

=back

=head2 Google::Cloud::Speech::V2::LocationsMetadata::LocationsMetadata

Main metadata for the Locations API for STT V2. Currently this is just the
metadata about locales, models, and features

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->languages() >> / C<< $msg->languages($value) >>

Type: C<Message> (L<Google::Cloud::Speech::V2::LocationsMetadata::LanguageMetadata>)

Information about available locales, models, and features represented in
the hierarchical structure of locales -> models -> features

=item * C<< $msg->access_metadata() >> / C<< $msg->access_metadata($value) >>

Type: C<Message> (L<Google::Cloud::Speech::V2::LocationsMetadata::AccessMetadata>)

Information about access metadata for the region and given project.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Speech::V2::LocationsMetadata::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
