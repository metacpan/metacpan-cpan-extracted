package Google::Ai::Generativelanguage::V1alpha::CachedContent;

use strict;
use warnings;

our $VERSION = '0.14';

use Protobuf::Message;
use Protobuf::DescriptorPool;
use Protobuf::Internal qw(:all);
use MIME::Base64;

BEGIN {
    eval { require Google::Ai::Generativelanguage::V1alpha::Content };
    eval { require Google::Api::FieldBehavior };
    eval { require Google::Api::Resource };
    eval { require Google::Protobuf::Duration };
    eval { require Google::Protobuf::Timestamp };
    my $descriptor_b64 = <<'EOF';
Cjlnb29nbGUvYWkvZ2VuZXJhdGl2ZWxhbmd1YWdlL3YxYWxwaGEvY2FjaGVkX2NvbnRlbnQu
cHJvdG8SJGdvb2dsZS5haS5nZW5lcmF0aXZlbGFuZ3VhZ2UudjFhbHBoYRoyZ29vZ2xlL2Fp
L2dlbmVyYXRpdmVsYW5ndWFnZS92MWFscGhhL2NvbnRlbnQucHJvdG8aH2dvb2dsZS9hcGkv
ZmllbGRfYmVoYXZpb3IucHJvdG8aGWdvb2dsZS9hcGkvcmVzb3VyY2UucHJvdG8aHmdvb2ds
ZS9wcm90b2J1Zi9kdXJhdGlvbi5wcm90bxofZ29vZ2xlL3Byb3RvYnVmL3RpbWVzdGFtcC5w
cm90byKJCQoNQ2FjaGVkQ29udGVudBI9CgtleHBpcmVfdGltZRgJIAEoCzIaLmdvb2dsZS5w
cm90b2J1Zi5UaW1lc3RhbXBIAFIKZXhwaXJlVGltZRIyCgN0dGwYCiABKAsyGS5nb29nbGUu
cHJvdG9idWYuRHVyYXRpb25CA+BBBEgAUgN0dGwSHwoEbmFtZRgBIAEoCUIG4EEI4EEBSAFS
BG5hbWWIAQESLgoMZGlzcGxheV9uYW1lGAsgASgJQgbgQQHgQQVIAlILZGlzcGxheU5hbWWI
AQESTQoFbW9kZWwYAiABKAlCMuBBBeBBAvpBKQonZ2VuZXJhdGl2ZWxhbmd1YWdlLmdvb2ds
ZWFwaXMuY29tL01vZGVsSANSBW1vZGVsiAEBEmwKEnN5c3RlbV9pbnN0cnVjdGlvbhgDIAEo
CzItLmdvb2dsZS5haS5nZW5lcmF0aXZlbGFuZ3VhZ2UudjFhbHBoYS5Db250ZW50QgngQQHg
QQXgQQRIBFIRc3lzdGVtSW5zdHJ1Y3Rpb26IAQESVAoIY29udGVudHMYBCADKAsyLS5nb29n
bGUuYWkuZ2VuZXJhdGl2ZWxhbmd1YWdlLnYxYWxwaGEuQ29udGVudEIJ4EEB4EEF4EEEUghj
b250ZW50cxJLCgV0b29scxgFIAMoCzIqLmdvb2dsZS5haS5nZW5lcmF0aXZlbGFuZ3VhZ2Uu
djFhbHBoYS5Ub29sQgngQQHgQQXgQQRSBXRvb2xzEmEKC3Rvb2xfY29uZmlnGAYgASgLMjAu
Z29vZ2xlLmFpLmdlbmVyYXRpdmVsYW5ndWFnZS52MWFscGhhLlRvb2xDb25maWdCCeBBAeBB
BeBBBEgFUgp0b29sQ29uZmlniAEBEkAKC2NyZWF0ZV90aW1lGAcgASgLMhouZ29vZ2xlLnBy
b3RvYnVmLlRpbWVzdGFtcEID4EEDUgpjcmVhdGVUaW1lEkAKC3VwZGF0ZV90aW1lGAggASgL
MhouZ29vZ2xlLnByb3RvYnVmLlRpbWVzdGFtcEID4EEDUgp1cGRhdGVUaW1lEm0KDnVzYWdl
X21ldGFkYXRhGAwgASgLMkEuZ29vZ2xlLmFpLmdlbmVyYXRpdmVsYW5ndWFnZS52MWFscGhh
LkNhY2hlZENvbnRlbnQuVXNhZ2VNZXRhZGF0YUID4EEDUg11c2FnZU1ldGFkYXRhGjsKDVVz
YWdlTWV0YWRhdGESKgoRdG90YWxfdG9rZW5fY291bnQYASABKAVSD3RvdGFsVG9rZW5Db3Vu
dDpo6kFlCi9nZW5lcmF0aXZlbGFuZ3VhZ2UuZ29vZ2xlYXBpcy5jb20vQ2FjaGVkQ29udGVu
dBITY2FjaGVkQ29udGVudHMve2lkfSoOY2FjaGVkQ29udGVudHMyDWNhY2hlZENvbnRlbnRC
DAoKZXhwaXJhdGlvbkIHCgVfbmFtZUIPCg1fZGlzcGxheV9uYW1lQggKBl9tb2RlbEIVChNf
c3lzdGVtX2luc3RydWN0aW9uQg4KDF90b29sX2NvbmZpZ0KgAQooY29tLmdvb2dsZS5haS5n
ZW5lcmF0aXZlbGFuZ3VhZ2UudjFhbHBoYUISQ2FjaGVkQ29udGVudFByb3RvUAFaXmNsb3Vk
Lmdvb2dsZS5jb20vZ28vYWkvZ2VuZXJhdGl2ZWxhbmd1YWdlL2FwaXYxYWxwaGEvZ2VuZXJh
dGl2ZWxhbmd1YWdlcGI7Z2VuZXJhdGl2ZWxhbmd1YWdlcGJKhRwKBhIEDgB8AQq8BAoBDBID
DgASMrEEIENvcHlyaWdodCAyMDI1IEdvb2dsZSBMTEMKCiBMaWNlbnNlZCB1bmRlciB0aGUg
QXBhY2hlIExpY2Vuc2UsIFZlcnNpb24gMi4wICh0aGUgIkxpY2Vuc2UiKTsKIHlvdSBtYXkg
bm90IHVzZSB0aGlzIGZpbGUgZXhjZXB0IGluIGNvbXBsaWFuY2Ugd2l0aCB0aGUgTGljZW5z
ZS4KIFlvdSBtYXkgb2J0YWluIGEgY29weSBvZiB0aGUgTGljZW5zZSBhdAoKICAgICBodHRw
Oi8vd3d3LmFwYWNoZS5vcmcvbGljZW5zZXMvTElDRU5TRS0yLjAKCiBVbmxlc3MgcmVxdWly
ZWQgYnkgYXBwbGljYWJsZSBsYXcgb3IgYWdyZWVkIHRvIGluIHdyaXRpbmcsIHNvZnR3YXJl
CiBkaXN0cmlidXRlZCB1bmRlciB0aGUgTGljZW5zZSBpcyBkaXN0cmlidXRlZCBvbiBhbiAi
QVMgSVMiIEJBU0lTLAogV0lUSE9VVCBXQVJSQU5USUVTIE9SIENPTkRJVElPTlMgT0YgQU5Z
IEtJTkQsIGVpdGhlciBleHByZXNzIG9yIGltcGxpZWQuCiBTZWUgdGhlIExpY2Vuc2UgZm9y
IHRoZSBzcGVjaWZpYyBsYW5ndWFnZSBnb3Zlcm5pbmcgcGVybWlzc2lvbnMgYW5kCiBsaW1p
dGF0aW9ucyB1bmRlciB0aGUgTGljZW5zZS4KCggKAQISAxAALQoJCgIDABIDEgA8CgkKAgMB
EgMTACkKCQoCAwISAxQAIwoJCgIDAxIDFQAoCgkKAgMEEgMWACkKCAoBCBIDGAB1CgkKAggL
EgMYAHUKCAoBCBIDGQAiCgkKAggKEgMZACIKCAoBCBIDGgAzCgkKAggIEgMaADMKCAoBCBID
GwBBCgkKAggBEgMbAEEKrwEKAgQAEgQhAHwBGqIBIENvbnRlbnQgdGhhdCBoYXMgYmVlbiBw
cmVwcm9jZXNzZWQgYW5kIGNhbiBiZSB1c2VkIGluIHN1YnNlcXVlbnQgcmVxdWVzdAogdG8g
R2VuZXJhdGl2ZVNlcnZpY2UuCgogQ2FjaGVkIGNvbnRlbnQgY2FuIGJlIG9ubHkgdXNlZCB3
aXRoIG1vZGVsIGl0IHdhcyBjcmVhdGVkIGZvci4KCgoKAwQAARIDIQgVCgsKAwQABxIEIgIn
BAoNCgUEAAedCBIEIgInBAo8CgQEAAMAEgQqAi0DGi4gTWV0YWRhdGEgb24gdGhlIHVzYWdl
IG9mIHRoZSBjYWNoZWQgY29udGVudC4KCgwKBQQAAwABEgMqChcKSQoGBAADAAIAEgMsBCAa
OiBUb3RhbCBudW1iZXIgb2YgdG9rZW5zIHRoYXQgdGhlIGNhY2hlZCBjb250ZW50IGNvbnN1
bWVzLgoKDgoHBAADAAIABRIDLAQJCg4KBwQAAwACAAESAywKGwoOCgcEAAMAAgADEgMsHh8K
OQoEBAAIABIEMAI5AxorIFNwZWNpZmllcyB3aGVuIHRoaXMgcmVzb3VyY2Ugd2lsbCBleHBp
cmUuCgoMCgUEAAgAARIDMAgSCpoBCgQEAAIAEgM0BC4ajAEgVGltZXN0YW1wIGluIFVUQyBv
ZiB3aGVuIHRoaXMgcmVzb3VyY2UgaXMgY29uc2lkZXJlZCBleHBpcmVkLgogVGhpcyBpcyAq
YWx3YXlzKiBwcm92aWRlZCBvbiBvdXRwdXQsIHJlZ2FyZGxlc3Mgb2Ygd2hhdCB3YXMgc2Vu
dAogb24gaW5wdXQuCgoMCgUEAAIABhIDNAQdCgwKBQQAAgABEgM0HikKDAoFBAACAAMSAzQs
LQpCCgQEAAIBEgQ3BDgzGjQgSW5wdXQgb25seS4gTmV3IFRUTCBmb3IgdGhpcyByZXNvdXJj
ZSwgaW5wdXQgb25seS4KCgwKBQQAAgEGEgM3BBwKDAoFBAACAQESAzcdIAoMCgUEAAIBAxID
NyMlCgwKBQQAAgEIEgM4CDIKDwoIBAACAQicCAASAzgJMQp3CgQEAAICEgQ9AkAEGmkgT3B0
aW9uYWwuIElkZW50aWZpZXIuIFRoZSByZXNvdXJjZSBuYW1lIHJlZmVycmluZyB0byB0aGUg
Y2FjaGVkIGNvbnRlbnQuCiBGb3JtYXQ6IGBjYWNoZWRDb250ZW50cy97aWR9YAoKDAoFBAAC
AgQSAz0CCgoMCgUEAAICBRIDPQsRCgwKBQQAAgIBEgM9EhYKDAoFBAACAgMSAz0ZGgoNCgUE
AAICCBIEPRtAAwoPCggEAAICCJwIABIDPgQsCg8KCAQAAgIInAgBEgM/BCoKhwEKBAQAAgMS
BEQCRwQaeSBPcHRpb25hbC4gSW1tdXRhYmxlLiBUaGUgdXNlci1nZW5lcmF0ZWQgbWVhbmlu
Z2Z1bCBkaXNwbGF5IG5hbWUgb2YgdGhlCiBjYWNoZWQgY29udGVudC4gTWF4aW11bSAxMjgg
VW5pY29kZSBjaGFyYWN0ZXJzLgoKDAoFBAACAwQSA0QCCgoMCgUEAAIDBRIDRAsRCgwKBQQA
AgMBEgNEEh4KDAoFBAACAwMSA0QhIwoNCgUEAAIDCBIERCRHAwoPCggEAAIDCJwIABIDRQQq
Cg8KCAQAAgMInAgBEgNGBCsKcAoEBAACBBIESwJRBBpiIFJlcXVpcmVkLiBJbW11dGFibGUu
IFRoZSBuYW1lIG9mIHRoZSBgTW9kZWxgIHRvIHVzZSBmb3IgY2FjaGVkIGNvbnRlbnQKIEZv
cm1hdDogYG1vZGVscy97bW9kZWx9YAoKDAoFBAACBAQSA0sCCgoMCgUEAAIEBRIDSwsRCgwK
BQQAAgQBEgNLEhcKDAoFBAACBAMSA0saGwoNCgUEAAIECBIESxxRAwoPCggEAAIECJwIABID
TAQrCg8KCAQAAgQInAgBEgNNBCoKDwoHBAACBAifCBIETgRQBQpoCgQEAAIFEgRVAlkEGlog
T3B0aW9uYWwuIElucHV0IG9ubHkuIEltbXV0YWJsZS4gRGV2ZWxvcGVyIHNldCBzeXN0ZW0g
aW5zdHJ1Y3Rpb24uCiBDdXJyZW50bHkgdGV4dCBvbmx5LgoKDAoFBAACBQQSA1UCCgoMCgUE
AAIFBhIDVQsSCgwKBQQAAgUBEgNVEyUKDAoFBAACBQMSA1UoKQoNCgUEAAIFCBIEVSpZAwoP
CggEAAIFCJwIABIDVgQqCg8KCAQAAgUInAgBEgNXBCsKDwoIBAACBQicCAISA1gELApGCgQE
AAIGEgRcAmAEGjggT3B0aW9uYWwuIElucHV0IG9ubHkuIEltbXV0YWJsZS4gVGhlIGNvbnRl
bnQgdG8gY2FjaGUuCgoMCgUEAAIGBBIDXAIKCgwKBQQAAgYGEgNcCxIKDAoFBAACBgESA1wT
GwoMCgUEAAIGAxIDXB4fCg0KBQQAAgYIEgRcIGADCg8KCAQAAgYInAgAEgNdBCoKDwoIBAAC
BgicCAESA14EKwoPCggEAAIGCJwIAhIDXwQsCnMKBAQAAgcSBGQCaAQaZSBPcHRpb25hbC4g
SW5wdXQgb25seS4gSW1tdXRhYmxlLiBBIGxpc3Qgb2YgYFRvb2xzYCB0aGUgbW9kZWwgbWF5
IHVzZSB0bwogZ2VuZXJhdGUgdGhlIG5leHQgcmVzcG9uc2UKCgwKBQQAAgcEEgNkAgoKDAoF
BAACBwYSA2QLDwoMCgUEAAIHARIDZBAVCgwKBQQAAgcDEgNkGBkKDQoFBAACBwgSBGQaaAMK
DwoIBAACBwicCAASA2UEKgoPCggEAAIHCJwIARIDZgQrCg8KCAQAAgcInAgCEgNnBCwKYwoE
BAACCBIEbAJwBBpVIE9wdGlvbmFsLiBJbnB1dCBvbmx5LiBJbW11dGFibGUuIFRvb2wgY29u
ZmlnLiBUaGlzIGNvbmZpZyBpcyBzaGFyZWQgZm9yIGFsbAogdG9vbHMuCgoMCgUEAAIIBBID
bAIKCgwKBQQAAggGEgNsCxUKDAoFBAACCAESA2wWIQoMCgUEAAIIAxIDbCQlCg0KBQQAAggI
EgRsJnADCg8KCAQAAggInAgAEgNtBCoKDwoIBAACCAicCAESA24EKwoPCggEAAIICJwIAhID
bwQsCj4KBAQAAgkSBHMCdDIaMCBPdXRwdXQgb25seS4gQ3JlYXRpb24gdGltZSBvZiB0aGUg
Y2FjaGUgZW50cnkuCgoMCgUEAAIJBhIDcwIbCgwKBQQAAgkBEgNzHCcKDAoFBAACCQMSA3Mq
KwoMCgUEAAIJCBIDdAYxCg8KCAQAAgkInAgAEgN0BzAKTwoEBAACChIEdwJ4MhpBIE91dHB1
dCBvbmx5LiBXaGVuIHRoZSBjYWNoZSBlbnRyeSB3YXMgbGFzdCB1cGRhdGVkIGluIFVUQyB0
aW1lLgoKDAoFBAACCgYSA3cCGwoMCgUEAAIKARIDdxwnCgwKBQQAAgoDEgN3KisKDAoFBAAC
CggSA3gGMQoPCggEAAIKCJwIABIDeAcwCkgKBAQAAgsSA3sCUBo7IE91dHB1dCBvbmx5LiBN
ZXRhZGF0YSBvbiB0aGUgdXNhZ2Ugb2YgdGhlIGNhY2hlZCBjb250ZW50LgoKDAoFBAACCwYS
A3sCDwoMCgUEAAILARIDexAeCgwKBQQAAgsDEgN7ISMKDAoFBAACCwgSA3skTwoPCggEAAIL
CJwIABIDeyVOYgZwcm90bzM=
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Ai::Generativelanguage::V1alpha::CachedContent::CachedContent ===
    # Fields for CachedContent
    # Field: expire_time Type: 11 (.google.protobuf.Timestamp)
    # Field: ttl Type: 11 (.google.protobuf.Duration)
    # Field: name Type: 9 ()
    # Field: display_name Type: 9 ()
    # Field: model Type: 9 ()
    # Field: system_instruction Type: 11 (.google.ai.generativelanguage.v1alpha.Content)
    # Field: contents Type: 11 (.google.ai.generativelanguage.v1alpha.Content)
    # Field: tools Type: 11 (.google.ai.generativelanguage.v1alpha.Tool)
    # Field: tool_config Type: 11 (.google.ai.generativelanguage.v1alpha.ToolConfig)
    # Field: create_time Type: 11 (.google.protobuf.Timestamp)
    # Field: update_time Type: 11 (.google.protobuf.Timestamp)
    # Field: usage_metadata Type: 11 (.google.ai.generativelanguage.v1alpha.CachedContent.UsageMetadata)

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Ai::Generativelanguage::V1alpha::CachedContent - Compiled Protocol Buffers messages for google/ai/generativelanguage/v1alpha/cached_content.proto

=head1 SYNOPSIS

    use Google::Ai::Generativelanguage::V1alpha::CachedContent;

    my $msg = Google::Ai::Generativelanguage::V1alpha::CachedContent::CachedContent->new({
        expire_time => $expire_time,
        ttl => $ttl,
        name => $name,
        display_name => $display_name,
    });

    # Read or update a field
    my $val = $msg->expire_time();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Ai::Generativelanguage::V1alpha::CachedContent::CachedContent->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/ai/generativelanguage/v1alpha/cached_content.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Ai::Generativelanguage::V1alpha::CachedContent::CachedContent

Content that has been preprocessed and can be used in subsequent request
to GenerativeService.

Cached content can be only used with model it was created for.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->expire_time() >> / C<< $msg->expire_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Timestamp in UTC of when this resource is considered expired.
This is *always* provided on output, regardless of what was sent
on input.

=item * C<< $msg->ttl() >> / C<< $msg->ttl($value) >>

Type: C<Message> (L<Google::Protobuf::Duration::Duration>)

Input only. New TTL for this resource, input only.

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Optional. Identifier. The resource name referring to the cached content.
Format: `cachedContents/{id}`

=item * C<< $msg->display_name() >> / C<< $msg->display_name($value) >>

Type: C<String>

Optional. Immutable. The user-generated meaningful display name of the
cached content. Maximum 128 Unicode characters.

=item * C<< $msg->model() >> / C<< $msg->model($value) >>

Type: C<String>

Required. Immutable. The name of the `Model` to use for cached content
Format: `models/{model}`

=item * C<< $msg->system_instruction() >> / C<< $msg->system_instruction($value) >>

Type: C<Message> (L<Google::Ai::Generativelanguage::V1alpha::Content::Content>)

Optional. Input only. Immutable. Developer set system instruction.
Currently text only.

=item * C<< $msg->contents() >> / C<< $msg->contents($value) >>

Type: C<Message> (L<Google::Ai::Generativelanguage::V1alpha::Content::Content>)

Optional. Input only. Immutable. The content to cache.

=item * C<< $msg->tools() >> / C<< $msg->tools($value) >>

Type: C<Message> (L<Google::Ai::Generativelanguage::V1alpha::Content::Tool>)

Optional. Input only. Immutable. A list of `Tools` the model may use to
generate the next response

=item * C<< $msg->tool_config() >> / C<< $msg->tool_config($value) >>

Type: C<Message> (L<Google::Ai::Generativelanguage::V1alpha::Content::ToolConfig>)

Optional. Input only. Immutable. Tool config. This config is shared for all
tools.

=item * C<< $msg->create_time() >> / C<< $msg->create_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Output only. Creation time of the cache entry.

=item * C<< $msg->update_time() >> / C<< $msg->update_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Output only. When the cache entry was last updated in UTC time.

=item * C<< $msg->usage_metadata() >> / C<< $msg->usage_metadata($value) >>

Type: C<Message> (L<Google::Ai::Generativelanguage::V1alpha::CachedContent::CachedContent::UsageMetadata>)

Output only. Metadata on the usage of the cached content.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Ai::Generativelanguage::V1alpha::CachedContent::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
