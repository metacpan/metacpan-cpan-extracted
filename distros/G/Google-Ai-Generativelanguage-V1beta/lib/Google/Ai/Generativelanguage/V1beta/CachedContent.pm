package Google::Ai::Generativelanguage::V1beta::CachedContent;

use strict;
use warnings;

our $VERSION = '0.14';

use Protobuf::Message;
use Protobuf::DescriptorPool;
use Protobuf::Internal qw(:all);
use MIME::Base64;

BEGIN {
    eval { require Google::Ai::Generativelanguage::V1beta::Content };
    eval { require Google::Api::FieldBehavior };
    eval { require Google::Api::Resource };
    eval { require Google::Protobuf::Duration };
    eval { require Google::Protobuf::Timestamp };
    my $descriptor_b64 = <<'EOF';
Cjhnb29nbGUvYWkvZ2VuZXJhdGl2ZWxhbmd1YWdlL3YxYmV0YS9jYWNoZWRfY29udGVudC5w
cm90bxIjZ29vZ2xlLmFpLmdlbmVyYXRpdmVsYW5ndWFnZS52MWJldGEaMWdvb2dsZS9haS9n
ZW5lcmF0aXZlbGFuZ3VhZ2UvdjFiZXRhL2NvbnRlbnQucHJvdG8aH2dvb2dsZS9hcGkvZmll
bGRfYmVoYXZpb3IucHJvdG8aGWdvb2dsZS9hcGkvcmVzb3VyY2UucHJvdG8aHmdvb2dsZS9w
cm90b2J1Zi9kdXJhdGlvbi5wcm90bxofZ29vZ2xlL3Byb3RvYnVmL3RpbWVzdGFtcC5wcm90
byKECQoNQ2FjaGVkQ29udGVudBI9CgtleHBpcmVfdGltZRgJIAEoCzIaLmdvb2dsZS5wcm90
b2J1Zi5UaW1lc3RhbXBIAFIKZXhwaXJlVGltZRIyCgN0dGwYCiABKAsyGS5nb29nbGUucHJv
dG9idWYuRHVyYXRpb25CA+BBBEgAUgN0dGwSHwoEbmFtZRgBIAEoCUIG4EEI4EEDSAFSBG5h
bWWIAQESLgoMZGlzcGxheV9uYW1lGAsgASgJQgbgQQHgQQVIAlILZGlzcGxheU5hbWWIAQES
TQoFbW9kZWwYAiABKAlCMuBBBeBBAvpBKQonZ2VuZXJhdGl2ZWxhbmd1YWdlLmdvb2dsZWFw
aXMuY29tL01vZGVsSANSBW1vZGVsiAEBEmsKEnN5c3RlbV9pbnN0cnVjdGlvbhgDIAEoCzIs
Lmdvb2dsZS5haS5nZW5lcmF0aXZlbGFuZ3VhZ2UudjFiZXRhLkNvbnRlbnRCCeBBAeBBBeBB
BEgEUhFzeXN0ZW1JbnN0cnVjdGlvbogBARJTCghjb250ZW50cxgEIAMoCzIsLmdvb2dsZS5h
aS5nZW5lcmF0aXZlbGFuZ3VhZ2UudjFiZXRhLkNvbnRlbnRCCeBBAeBBBeBBBFIIY29udGVu
dHMSSgoFdG9vbHMYBSADKAsyKS5nb29nbGUuYWkuZ2VuZXJhdGl2ZWxhbmd1YWdlLnYxYmV0
YS5Ub29sQgngQQHgQQXgQQRSBXRvb2xzEmAKC3Rvb2xfY29uZmlnGAYgASgLMi8uZ29vZ2xl
LmFpLmdlbmVyYXRpdmVsYW5ndWFnZS52MWJldGEuVG9vbENvbmZpZ0IJ4EEB4EEF4EEESAVS
CnRvb2xDb25maWeIAQESQAoLY3JlYXRlX3RpbWUYByABKAsyGi5nb29nbGUucHJvdG9idWYu
VGltZXN0YW1wQgPgQQNSCmNyZWF0ZVRpbWUSQAoLdXBkYXRlX3RpbWUYCCABKAsyGi5nb29n
bGUucHJvdG9idWYuVGltZXN0YW1wQgPgQQNSCnVwZGF0ZVRpbWUSbAoOdXNhZ2VfbWV0YWRh
dGEYDCABKAsyQC5nb29nbGUuYWkuZ2VuZXJhdGl2ZWxhbmd1YWdlLnYxYmV0YS5DYWNoZWRD
b250ZW50LlVzYWdlTWV0YWRhdGFCA+BBA1INdXNhZ2VNZXRhZGF0YRo7Cg1Vc2FnZU1ldGFk
YXRhEioKEXRvdGFsX3Rva2VuX2NvdW50GAEgASgFUg90b3RhbFRva2VuQ291bnQ6aOpBZQov
Z2VuZXJhdGl2ZWxhbmd1YWdlLmdvb2dsZWFwaXMuY29tL0NhY2hlZENvbnRlbnQSE2NhY2hl
ZENvbnRlbnRzL3tpZH0qDmNhY2hlZENvbnRlbnRzMg1jYWNoZWRDb250ZW50QgwKCmV4cGly
YXRpb25CBwoFX25hbWVCDwoNX2Rpc3BsYXlfbmFtZUIICgZfbW9kZWxCFQoTX3N5c3RlbV9p
bnN0cnVjdGlvbkIOCgxfdG9vbF9jb25maWdCngEKJ2NvbS5nb29nbGUuYWkuZ2VuZXJhdGl2
ZWxhbmd1YWdlLnYxYmV0YUISQ2FjaGVkQ29udGVudFByb3RvUAFaXWNsb3VkLmdvb2dsZS5j
b20vZ28vYWkvZ2VuZXJhdGl2ZWxhbmd1YWdlL2FwaXYxYmV0YS9nZW5lcmF0aXZlbGFuZ3Vh
Z2VwYjtnZW5lcmF0aXZlbGFuZ3VhZ2VwYkqIHAoGEgQOAHwBCrwECgEMEgMOABIysQQgQ29w
eXJpZ2h0IDIwMjUgR29vZ2xlIExMQwoKIExpY2Vuc2VkIHVuZGVyIHRoZSBBcGFjaGUgTGlj
ZW5zZSwgVmVyc2lvbiAyLjAgKHRoZSAiTGljZW5zZSIpOwogeW91IG1heSBub3QgdXNlIHRo
aXMgZmlsZSBleGNlcHQgaW4gY29tcGxpYW5jZSB3aXRoIHRoZSBMaWNlbnNlLgogWW91IG1h
eSBvYnRhaW4gYSBjb3B5IG9mIHRoZSBMaWNlbnNlIGF0CgogICAgIGh0dHA6Ly93d3cuYXBh
Y2hlLm9yZy9saWNlbnNlcy9MSUNFTlNFLTIuMAoKIFVubGVzcyByZXF1aXJlZCBieSBhcHBs
aWNhYmxlIGxhdyBvciBhZ3JlZWQgdG8gaW4gd3JpdGluZywgc29mdHdhcmUKIGRpc3RyaWJ1
dGVkIHVuZGVyIHRoZSBMaWNlbnNlIGlzIGRpc3RyaWJ1dGVkIG9uIGFuICJBUyBJUyIgQkFT
SVMsCiBXSVRIT1VUIFdBUlJBTlRJRVMgT1IgQ09ORElUSU9OUyBPRiBBTlkgS0lORCwgZWl0
aGVyIGV4cHJlc3Mgb3IgaW1wbGllZC4KIFNlZSB0aGUgTGljZW5zZSBmb3IgdGhlIHNwZWNp
ZmljIGxhbmd1YWdlIGdvdmVybmluZyBwZXJtaXNzaW9ucyBhbmQKIGxpbWl0YXRpb25zIHVu
ZGVyIHRoZSBMaWNlbnNlLgoKCAoBAhIDEAAsCgkKAgMAEgMSADsKCQoCAwESAxMAKQoJCgID
AhIDFAAjCgkKAgMDEgMVACgKCQoCAwQSAxYAKQoICgEIEgMYAHQKCQoCCAsSAxgAdAoICgEI
EgMZACIKCQoCCAoSAxkAIgoICgEIEgMaADMKCQoCCAgSAxoAMwoICgEIEgMbAEAKCQoCCAES
AxsAQAqvAQoCBAASBCEAfAEaogEgQ29udGVudCB0aGF0IGhhcyBiZWVuIHByZXByb2Nlc3Nl
ZCBhbmQgY2FuIGJlIHVzZWQgaW4gc3Vic2VxdWVudCByZXF1ZXN0CiB0byBHZW5lcmF0aXZl
U2VydmljZS4KCiBDYWNoZWQgY29udGVudCBjYW4gYmUgb25seSB1c2VkIHdpdGggbW9kZWwg
aXQgd2FzIGNyZWF0ZWQgZm9yLgoKCgoDBAABEgMhCBUKCwoDBAAHEgQiAicECg0KBQQAB50I
EgQiAicECjwKBAQAAwASBCoCLQMaLiBNZXRhZGF0YSBvbiB0aGUgdXNhZ2Ugb2YgdGhlIGNh
Y2hlZCBjb250ZW50LgoKDAoFBAADAAESAyoKFwpJCgYEAAMAAgASAywEIBo6IFRvdGFsIG51
bWJlciBvZiB0b2tlbnMgdGhhdCB0aGUgY2FjaGVkIGNvbnRlbnQgY29uc3VtZXMuCgoOCgcE
AAMAAgAFEgMsBAkKDgoHBAADAAIAARIDLAobCg4KBwQAAwACAAMSAyweHwo5CgQEAAgAEgQw
AjkDGisgU3BlY2lmaWVzIHdoZW4gdGhpcyByZXNvdXJjZSB3aWxsIGV4cGlyZS4KCgwKBQQA
CAABEgMwCBIKmgEKBAQAAgASAzQELhqMASBUaW1lc3RhbXAgaW4gVVRDIG9mIHdoZW4gdGhp
cyByZXNvdXJjZSBpcyBjb25zaWRlcmVkIGV4cGlyZWQuCiBUaGlzIGlzICphbHdheXMqIHBy
b3ZpZGVkIG9uIG91dHB1dCwgcmVnYXJkbGVzcyBvZiB3aGF0IHdhcyBzZW50CiBvbiBpbnB1
dC4KCgwKBQQAAgAGEgM0BB0KDAoFBAACAAESAzQeKQoMCgUEAAIAAxIDNCwtCkIKBAQAAgES
BDcEODMaNCBJbnB1dCBvbmx5LiBOZXcgVFRMIGZvciB0aGlzIHJlc291cmNlLCBpbnB1dCBv
bmx5LgoKDAoFBAACAQYSAzcEHAoMCgUEAAIBARIDNx0gCgwKBQQAAgEDEgM3IyUKDAoFBAAC
AQgSAzgIMgoPCggEAAIBCJwIABIDOAkxCnoKBAQAAgISBD0CQAQabCBPdXRwdXQgb25seS4g
SWRlbnRpZmllci4gVGhlIHJlc291cmNlIG5hbWUgcmVmZXJyaW5nIHRvIHRoZSBjYWNoZWQg
Y29udGVudC4KIEZvcm1hdDogYGNhY2hlZENvbnRlbnRzL3tpZH1gCgoMCgUEAAICBBIDPQIK
CgwKBQQAAgIFEgM9CxEKDAoFBAACAgESAz0SFgoMCgUEAAICAxIDPRkaCg0KBQQAAgIIEgQ9
G0ADCg8KCAQAAgIInAgAEgM+BCwKDwoIBAACAgicCAESAz8ELQqHAQoEBAACAxIERAJHBBp5
IE9wdGlvbmFsLiBJbW11dGFibGUuIFRoZSB1c2VyLWdlbmVyYXRlZCBtZWFuaW5nZnVsIGRp
c3BsYXkgbmFtZSBvZiB0aGUKIGNhY2hlZCBjb250ZW50LiBNYXhpbXVtIDEyOCBVbmljb2Rl
IGNoYXJhY3RlcnMuCgoMCgUEAAIDBBIDRAIKCgwKBQQAAgMFEgNECxEKDAoFBAACAwESA0QS
HgoMCgUEAAIDAxIDRCEjCg0KBQQAAgMIEgREJEcDCg8KCAQAAgMInAgAEgNFBCoKDwoIBAAC
AwicCAESA0YEKwpwCgQEAAIEEgRLAlEEGmIgUmVxdWlyZWQuIEltbXV0YWJsZS4gVGhlIG5h
bWUgb2YgdGhlIGBNb2RlbGAgdG8gdXNlIGZvciBjYWNoZWQgY29udGVudAogRm9ybWF0OiBg
bW9kZWxzL3ttb2RlbH1gCgoMCgUEAAIEBBIDSwIKCgwKBQQAAgQFEgNLCxEKDAoFBAACBAES
A0sSFwoMCgUEAAIEAxIDSxobCg0KBQQAAgQIEgRLHFEDCg8KCAQAAgQInAgAEgNMBCsKDwoI
BAACBAicCAESA00EKgoPCgcEAAIECJ8IEgROBFAFCmgKBAQAAgUSBFUCWQQaWiBPcHRpb25h
bC4gSW5wdXQgb25seS4gSW1tdXRhYmxlLiBEZXZlbG9wZXIgc2V0IHN5c3RlbSBpbnN0cnVj
dGlvbi4KIEN1cnJlbnRseSB0ZXh0IG9ubHkuCgoMCgUEAAIFBBIDVQIKCgwKBQQAAgUGEgNV
CxIKDAoFBAACBQESA1UTJQoMCgUEAAIFAxIDVSgpCg0KBQQAAgUIEgRVKlkDCg8KCAQAAgUI
nAgAEgNWBCoKDwoIBAACBQicCAESA1cEKwoPCggEAAIFCJwIAhIDWAQsCkYKBAQAAgYSBFwC
YAQaOCBPcHRpb25hbC4gSW5wdXQgb25seS4gSW1tdXRhYmxlLiBUaGUgY29udGVudCB0byBj
YWNoZS4KCgwKBQQAAgYEEgNcAgoKDAoFBAACBgYSA1wLEgoMCgUEAAIGARIDXBMbCgwKBQQA
AgYDEgNcHh8KDQoFBAACBggSBFwgYAMKDwoIBAACBgicCAASA10EKgoPCggEAAIGCJwIARID
XgQrCg8KCAQAAgYInAgCEgNfBCwKcwoEBAACBxIEZAJoBBplIE9wdGlvbmFsLiBJbnB1dCBv
bmx5LiBJbW11dGFibGUuIEEgbGlzdCBvZiBgVG9vbHNgIHRoZSBtb2RlbCBtYXkgdXNlIHRv
CiBnZW5lcmF0ZSB0aGUgbmV4dCByZXNwb25zZQoKDAoFBAACBwQSA2QCCgoMCgUEAAIHBhID
ZAsPCgwKBQQAAgcBEgNkEBUKDAoFBAACBwMSA2QYGQoNCgUEAAIHCBIEZBpoAwoPCggEAAIH
CJwIABIDZQQqCg8KCAQAAgcInAgBEgNmBCsKDwoIBAACBwicCAISA2cELApjCgQEAAIIEgRs
AnAEGlUgT3B0aW9uYWwuIElucHV0IG9ubHkuIEltbXV0YWJsZS4gVG9vbCBjb25maWcuIFRo
aXMgY29uZmlnIGlzIHNoYXJlZCBmb3IgYWxsCiB0b29scy4KCgwKBQQAAggEEgNsAgoKDAoF
BAACCAYSA2wLFQoMCgUEAAIIARIDbBYhCgwKBQQAAggDEgNsJCUKDQoFBAACCAgSBGwmcAMK
DwoIBAACCAicCAASA20EKgoPCggEAAIICJwIARIDbgQrCg8KCAQAAggInAgCEgNvBCwKPgoE
BAACCRIEcwJ0MhowIE91dHB1dCBvbmx5LiBDcmVhdGlvbiB0aW1lIG9mIHRoZSBjYWNoZSBl
bnRyeS4KCgwKBQQAAgkGEgNzAhsKDAoFBAACCQESA3McJwoMCgUEAAIJAxIDcyorCgwKBQQA
AgkIEgN0BjEKDwoIBAACCQicCAASA3QHMApPCgQEAAIKEgR3AngyGkEgT3V0cHV0IG9ubHku
IFdoZW4gdGhlIGNhY2hlIGVudHJ5IHdhcyBsYXN0IHVwZGF0ZWQgaW4gVVRDIHRpbWUuCgoM
CgUEAAIKBhIDdwIbCgwKBQQAAgoBEgN3HCcKDAoFBAACCgMSA3cqKwoMCgUEAAIKCBIDeAYx
Cg8KCAQAAgoInAgAEgN4BzAKSAoEBAACCxIDewJQGjsgT3V0cHV0IG9ubHkuIE1ldGFkYXRh
IG9uIHRoZSB1c2FnZSBvZiB0aGUgY2FjaGVkIGNvbnRlbnQuCgoMCgUEAAILBhIDewIPCgwK
BQQAAgsBEgN7EB4KDAoFBAACCwMSA3shIwoMCgUEAAILCBIDeyRPCg8KCAQAAgsInAgAEgN7
JU5iBnByb3RvMw==
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Ai::Generativelanguage::V1beta::CachedContent::CachedContent ===
    # Fields for CachedContent
    # Field: expire_time Type: 11 (.google.protobuf.Timestamp)
    # Field: ttl Type: 11 (.google.protobuf.Duration)
    # Field: name Type: 9 ()
    # Field: display_name Type: 9 ()
    # Field: model Type: 9 ()
    # Field: system_instruction Type: 11 (.google.ai.generativelanguage.v1beta.Content)
    # Field: contents Type: 11 (.google.ai.generativelanguage.v1beta.Content)
    # Field: tools Type: 11 (.google.ai.generativelanguage.v1beta.Tool)
    # Field: tool_config Type: 11 (.google.ai.generativelanguage.v1beta.ToolConfig)
    # Field: create_time Type: 11 (.google.protobuf.Timestamp)
    # Field: update_time Type: 11 (.google.protobuf.Timestamp)
    # Field: usage_metadata Type: 11 (.google.ai.generativelanguage.v1beta.CachedContent.UsageMetadata)

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Ai::Generativelanguage::V1beta::CachedContent - Compiled Protocol Buffers messages for google/ai/generativelanguage/v1beta/cached_content.proto

=head1 SYNOPSIS

    use Google::Ai::Generativelanguage::V1beta::CachedContent;

    my $msg = Google::Ai::Generativelanguage::V1beta::CachedContent::CachedContent->new({
        expire_time => $expire_time,
        ttl => $ttl,
        name => $name,
        display_name => $display_name,
    });

    # Read or update a field
    my $val = $msg->expire_time();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Ai::Generativelanguage::V1beta::CachedContent::CachedContent->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/ai/generativelanguage/v1beta/cached_content.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Ai::Generativelanguage::V1beta::CachedContent::CachedContent

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

Output only. Identifier. The resource name referring to the cached content.
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

Type: C<Message> (L<Google::Ai::Generativelanguage::V1beta::Content::Content>)

Optional. Input only. Immutable. Developer set system instruction.
Currently text only.

=item * C<< $msg->contents() >> / C<< $msg->contents($value) >>

Type: C<Message> (L<Google::Ai::Generativelanguage::V1beta::Content::Content>)

Optional. Input only. Immutable. The content to cache.

=item * C<< $msg->tools() >> / C<< $msg->tools($value) >>

Type: C<Message> (L<Google::Ai::Generativelanguage::V1beta::Content::Tool>)

Optional. Input only. Immutable. A list of `Tools` the model may use to
generate the next response

=item * C<< $msg->tool_config() >> / C<< $msg->tool_config($value) >>

Type: C<Message> (L<Google::Ai::Generativelanguage::V1beta::Content::ToolConfig>)

Optional. Input only. Immutable. Tool config. This config is shared for all
tools.

=item * C<< $msg->create_time() >> / C<< $msg->create_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Output only. Creation time of the cache entry.

=item * C<< $msg->update_time() >> / C<< $msg->update_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Output only. When the cache entry was last updated in UTC time.

=item * C<< $msg->usage_metadata() >> / C<< $msg->usage_metadata($value) >>

Type: C<Message> (L<Google::Ai::Generativelanguage::V1beta::CachedContent::CachedContent::UsageMetadata>)

Output only. Metadata on the usage of the cached content.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Ai::Generativelanguage::V1beta::CachedContent::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
