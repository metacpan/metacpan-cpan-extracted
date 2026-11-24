package Google::Cloud::Contentwarehouse::V1::RulesetServiceRequest;

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
    eval { require Google::Cloud::Contentwarehouse::V1::RuleEngine };
    my $descriptor_b64 = <<'EOF';
Cj5nb29nbGUvY2xvdWQvY29udGVudHdhcmVob3VzZS92MS9ydWxlc2V0X3NlcnZpY2VfcmVx
dWVzdC5wcm90bxIgZ29vZ2xlLmNsb3VkLmNvbnRlbnR3YXJlaG91c2UudjEaH2dvb2dsZS9h
cGkvZmllbGRfYmVoYXZpb3IucHJvdG8aGWdvb2dsZS9hcGkvcmVzb3VyY2UucHJvdG8aMmdv
b2dsZS9jbG91ZC9jb250ZW50d2FyZWhvdXNlL3YxL3J1bGVfZW5naW5lLnByb3RvIqsBChRD
cmVhdGVSdWxlU2V0UmVxdWVzdBJICgZwYXJlbnQYASABKAlCMOBBAvpBKgooY29udGVudHdh
cmVob3VzZS5nb29nbGVhcGlzLmNvbS9Mb2NhdGlvblIGcGFyZW50EkkKCHJ1bGVfc2V0GAIg
ASgLMikuZ29vZ2xlLmNsb3VkLmNvbnRlbnR3YXJlaG91c2UudjEuUnVsZVNldEID4EECUgdy
dWxlU2V0IlgKEUdldFJ1bGVTZXRSZXF1ZXN0EkMKBG5hbWUYASABKAlCL+BBAvpBKQonY29u
dGVudHdhcmVob3VzZS5nb29nbGVhcGlzLmNvbS9SdWxlU2V0UgRuYW1lIqYBChRVcGRhdGVS
dWxlU2V0UmVxdWVzdBJDCgRuYW1lGAEgASgJQi/gQQL6QSkKJ2NvbnRlbnR3YXJlaG91c2Uu
Z29vZ2xlYXBpcy5jb20vUnVsZVNldFIEbmFtZRJJCghydWxlX3NldBgCIAEoCzIpLmdvb2ds
ZS5jbG91ZC5jb250ZW50d2FyZWhvdXNlLnYxLlJ1bGVTZXRCA+BBAlIHcnVsZVNldCJbChRE
ZWxldGVSdWxlU2V0UmVxdWVzdBJDCgRuYW1lGAEgASgJQi/gQQL6QSkKJ2NvbnRlbnR3YXJl
aG91c2UuZ29vZ2xlYXBpcy5jb20vUnVsZVNldFIEbmFtZSKbAQoTTGlzdFJ1bGVTZXRzUmVx
dWVzdBJICgZwYXJlbnQYASABKAlCMOBBAvpBKgooY29udGVudHdhcmVob3VzZS5nb29nbGVh
cGlzLmNvbS9Mb2NhdGlvblIGcGFyZW50EhsKCXBhZ2Vfc2l6ZRgCIAEoBVIIcGFnZVNpemUS
HQoKcGFnZV90b2tlbhgDIAEoCVIJcGFnZVRva2VuIoYBChRMaXN0UnVsZVNldHNSZXNwb25z
ZRJGCglydWxlX3NldHMYASADKAsyKS5nb29nbGUuY2xvdWQuY29udGVudHdhcmVob3VzZS52
MS5SdWxlU2V0UghydWxlU2V0cxImCg9uZXh0X3BhZ2VfdG9rZW4YAiABKAlSDW5leHRQYWdl
VG9rZW5CggIKJGNvbS5nb29nbGUuY2xvdWQuY29udGVudHdhcmVob3VzZS52MUIaUnVsZVNl
dFNlcnZpY2VSZXF1ZXN0UHJvdG9QAVpQY2xvdWQuZ29vZ2xlLmNvbS9nby9jb250ZW50d2Fy
ZWhvdXNlL2FwaXYxL2NvbnRlbnR3YXJlaG91c2VwYjtjb250ZW50d2FyZWhvdXNlcGKqAiBH
b29nbGUuQ2xvdWQuQ29udGVudFdhcmVob3VzZS5WMcoCIEdvb2dsZVxDbG91ZFxDb250ZW50
V2FyZWhvdXNlXFYx6gIjR29vZ2xlOjpDbG91ZDo6Q29udGVudFdhcmVob3VzZTo6VjFKkRsK
BhIEDgB4AQq8BAoBDBIDDgASMrEEIENvcHlyaWdodCAyMDI1IEdvb2dsZSBMTEMKCiBMaWNl
bnNlZCB1bmRlciB0aGUgQXBhY2hlIExpY2Vuc2UsIFZlcnNpb24gMi4wICh0aGUgIkxpY2Vu
c2UiKTsKIHlvdSBtYXkgbm90IHVzZSB0aGlzIGZpbGUgZXhjZXB0IGluIGNvbXBsaWFuY2Ug
d2l0aCB0aGUgTGljZW5zZS4KIFlvdSBtYXkgb2J0YWluIGEgY29weSBvZiB0aGUgTGljZW5z
ZSBhdAoKICAgICBodHRwOi8vd3d3LmFwYWNoZS5vcmcvbGljZW5zZXMvTElDRU5TRS0yLjAK
CiBVbmxlc3MgcmVxdWlyZWQgYnkgYXBwbGljYWJsZSBsYXcgb3IgYWdyZWVkIHRvIGluIHdy
aXRpbmcsIHNvZnR3YXJlCiBkaXN0cmlidXRlZCB1bmRlciB0aGUgTGljZW5zZSBpcyBkaXN0
cmlidXRlZCBvbiBhbiAiQVMgSVMiIEJBU0lTLAogV0lUSE9VVCBXQVJSQU5USUVTIE9SIENP
TkRJVElPTlMgT0YgQU5ZIEtJTkQsIGVpdGhlciBleHByZXNzIG9yIGltcGxpZWQuCiBTZWUg
dGhlIExpY2Vuc2UgZm9yIHRoZSBzcGVjaWZpYyBsYW5ndWFnZSBnb3Zlcm5pbmcgcGVybWlz
c2lvbnMgYW5kCiBsaW1pdGF0aW9ucyB1bmRlciB0aGUgTGljZW5zZS4KCggKAQISAxAAKQoJ
CgIDABIDEgApCgkKAgMBEgMTACMKCQoCAwISAxQAPAoICgEIEgMWAD0KCQoCCCUSAxYAPQoI
CgEIEgMXAGcKCQoCCAsSAxcAZwoICgEIEgMYACIKCQoCCAoSAxgAIgoICgEIEgMZADsKCQoC
CAgSAxkAOwoICgEIEgMaAD0KCQoCCAESAxoAPQoICgEIEgMbAD0KCQoCCCkSAxsAPQoICgEI
EgMcADwKCQoCCC0SAxwAPAo/CgIEABIEHwArARozIFJlcXVlc3QgbWVzc2FnZSBmb3IgUnVs
ZVNldFNlcnZpY2UuQ3JlYXRlUnVsZVNldC4KCgoKAwQAARIDHwgcCmMKBAQAAgASBCICJwQa
VSBSZXF1aXJlZC4gVGhlIHBhcmVudCBuYW1lLgogRm9ybWF0OiBwcm9qZWN0cy97cHJvamVj
dF9udW1iZXJ9L2xvY2F0aW9ucy97bG9jYXRpb259LgoKDAoFBAACAAUSAyICCAoMCgUEAAIA
ARIDIgkPCgwKBQQAAgADEgMiEhMKDQoFBAACAAgSBCIUJwMKDwoIBAACAAicCAASAyMEKgoP
CgcEAAIACJ8IEgQkBCYFCjAKBAQAAgESAyoCQBojIFJlcXVpcmVkLiBUaGUgcnVsZSBzZXQg
dG8gY3JlYXRlLgoKDAoFBAACAQYSAyoCCQoMCgUEAAIBARIDKgoSCgwKBQQAAgEDEgMqFRYK
DAoFBAACAQgSAyoXPwoPCggEAAIBCJwIABIDKhg+CjwKAgQBEgQuADgBGjAgUmVxdWVzdCBt
ZXNzYWdlIGZvciBSdWxlU2V0U2VydmljZS5HZXRSdWxlU2V0LgoKCgoDBAEBEgMuCBkKkQEK
BAQBAgASBDICNwQaggEgUmVxdWlyZWQuIFRoZSBuYW1lIG9mIHRoZSBydWxlIHNldCB0byBy
ZXRyaWV2ZS4KIEZvcm1hdDoKIHByb2plY3RzL3twcm9qZWN0X251bWJlcn0vbG9jYXRpb25z
L3tsb2NhdGlvbn0vcnVsZVNldHMve3J1bGVfc2V0X2lkfS4KCgwKBQQBAgAFEgMyAggKDAoF
BAECAAESAzIJDQoMCgUEAQIAAxIDMhARCg0KBQQBAgAIEgQyEjcDCg8KCAQBAgAInAgAEgMz
BCoKDwoHBAECAAifCBIENAQ2BQo/CgIEAhIEOwBIARozIFJlcXVlc3QgbWVzc2FnZSBmb3Ig
UnVsZVNldFNlcnZpY2UuVXBkYXRlUnVsZVNldC4KCgoKAwQCARIDOwgcCo8BCgQEAgIAEgQ/
AkQEGoABIFJlcXVpcmVkLiBUaGUgbmFtZSBvZiB0aGUgcnVsZSBzZXQgdG8gdXBkYXRlLgog
Rm9ybWF0OgogcHJvamVjdHMve3Byb2plY3RfbnVtYmVyfS9sb2NhdGlvbnMve2xvY2F0aW9u
fS9ydWxlU2V0cy97cnVsZV9zZXRfaWR9LgoKDAoFBAICAAUSAz8CCAoMCgUEAgIAARIDPwkN
CgwKBQQCAgADEgM/EBEKDQoFBAICAAgSBD8SRAMKDwoIBAICAAicCAASA0AEKgoPCgcEAgIA
CJ8IEgRBBEMFCjAKBAQCAgESA0cCQBojIFJlcXVpcmVkLiBUaGUgcnVsZSBzZXQgdG8gdXBk
YXRlLgoKDAoFBAICAQYSA0cCCQoMCgUEAgIBARIDRwoSCgwKBQQCAgEDEgNHFRYKDAoFBAIC
AQgSA0cXPwoPCggEAgIBCJwIABIDRxg+Cj8KAgQDEgRLAFUBGjMgUmVxdWVzdCBtZXNzYWdl
IGZvciBSdWxlU2V0U2VydmljZS5EZWxldGVSdWxlU2V0LgoKCgoDBAMBEgNLCBwKjwEKBAQD
AgASBE8CVAQagAEgUmVxdWlyZWQuIFRoZSBuYW1lIG9mIHRoZSBydWxlIHNldCB0byBkZWxl
dGUuCiBGb3JtYXQ6CiBwcm9qZWN0cy97cHJvamVjdF9udW1iZXJ9L2xvY2F0aW9ucy97bG9j
YXRpb259L3J1bGVTZXRzL3tydWxlX3NldF9pZH0uCgoMCgUEAwIABRIDTwIICgwKBQQDAgAB
EgNPCQ0KDAoFBAMCAAMSA08QEQoNCgUEAwIACBIETxJUAwoPCggEAwIACJwIABIDUAQqCg8K
BwQDAgAInwgSBFEEUwUKPgoCBAQSBFgAbgEaMiBSZXF1ZXN0IG1lc3NhZ2UgZm9yIFJ1bGVT
ZXRTZXJ2aWNlLkxpc3RSdWxlU2V0cy4KCgoKAwQEARIDWAgbCoYBCgQEBAIAEgRbAmAEGngg
UmVxdWlyZWQuIFRoZSBwYXJlbnQsIHdoaWNoIG93bnMgdGhpcyBjb2xsZWN0aW9uIG9mIGRv
Y3VtZW50LgogRm9ybWF0OiBwcm9qZWN0cy97cHJvamVjdF9udW1iZXJ9L2xvY2F0aW9ucy97
bG9jYXRpb259LgoKDAoFBAQCAAUSA1sCCAoMCgUEBAIAARIDWwkPCgwKBQQEAgADEgNbEhMK
DQoFBAQCAAgSBFsUYAMKDwoIBAQCAAicCAASA1wEKgoPCgcEBAIACJ8IEgRdBF8FCugBCgQE
BAIBEgNmAhYa2gEgVGhlIG1heGltdW0gbnVtYmVyIG9mIHJ1bGUgc2V0cyB0byByZXR1cm4u
IFRoZSBzZXJ2aWNlIG1heSByZXR1cm4KIGZld2VyIHRoYW4gdGhpcyB2YWx1ZS4KIElmIHVu
c3BlY2lmaWVkLCBhdCBtb3N0IDUwIHJ1bGUgc2V0cyB3aWxsIGJlIHJldHVybmVkLgogVGhl
IG1heGltdW0gdmFsdWUgaXMgMTAwMDsgdmFsdWVzIGFib3ZlIDEwMDAgd2lsbCBiZSBjb2Vy
Y2VkIHRvIDEwMDAuCgoMCgUEBAIBBRIDZgIHCgwKBQQEAgEBEgNmCBEKDAoFBAQCAQMSA2YU
FQrwAQoEBAQCAhIDbQIYGuIBIEEgcGFnZSB0b2tlbiwgcmVjZWl2ZWQgZnJvbSBhIHByZXZp
b3VzIGBMaXN0UnVsZVNldHNgIGNhbGwuCiBQcm92aWRlIHRoaXMgdG8gcmV0cmlldmUgdGhl
IHN1YnNlcXVlbnQgcGFnZS4KCiBXaGVuIHBhZ2luYXRpbmcsIGFsbCBvdGhlciBwYXJhbWV0
ZXJzIHByb3ZpZGVkIHRvIGBMaXN0UnVsZVNldHNgCiBtdXN0IG1hdGNoIHRoZSBjYWxsIHRo
YXQgcHJvdmlkZWQgdGhlIHBhZ2UgdG9rZW4uCgoMCgUEBAICBRIDbQIICgwKBQQEAgIBEgNt
CRMKDAoFBAQCAgMSA20WFwo/CgIEBRIEcQB4ARozIFJlc3BvbnNlIG1lc3NhZ2UgZm9yIFJ1
bGVTZXRTZXJ2aWNlLkxpc3RSdWxlU2V0cy4KCgoKAwQFARIDcQgcCjcKBAQFAgASA3MCIRoq
IFRoZSBydWxlIHNldHMgZnJvbSB0aGUgc3BlY2lmaWVkIHBhcmVudC4KCgwKBQQFAgAEEgNz
AgoKDAoFBAUCAAYSA3MLEgoMCgUEBQIAARIDcxMcCgwKBQQFAgADEgNzHyAKjwEKBAQFAgES
A3cCHRqBASBBIHRva2VuLCB3aGljaCBjYW4gYmUgc2VudCBhcyBgcGFnZV90b2tlbmAgdG8g
cmV0cmlldmUgdGhlIG5leHQgcGFnZS4KIElmIHRoaXMgZmllbGQgaXMgb21pdHRlZCwgdGhl
cmUgYXJlIG5vIHN1YnNlcXVlbnQgcGFnZXMuCgoMCgUEBQIBBRIDdwIICgwKBQQFAgEBEgN3
CRgKDAoFBAUCAQMSA3cbHGIGcHJvdG8z
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Contentwarehouse::V1::RulesetServiceRequest::CreateRuleSetRequest ===
    # Fields for CreateRuleSetRequest
    # Field: parent Type: 9 ()
    # Field: rule_set Type: 11 (.google.cloud.contentwarehouse.v1.RuleSet)

# === Message: Google::Cloud::Contentwarehouse::V1::RulesetServiceRequest::GetRuleSetRequest ===
    # Fields for GetRuleSetRequest
    # Field: name Type: 9 ()

# === Message: Google::Cloud::Contentwarehouse::V1::RulesetServiceRequest::UpdateRuleSetRequest ===
    # Fields for UpdateRuleSetRequest
    # Field: name Type: 9 ()
    # Field: rule_set Type: 11 (.google.cloud.contentwarehouse.v1.RuleSet)

# === Message: Google::Cloud::Contentwarehouse::V1::RulesetServiceRequest::DeleteRuleSetRequest ===
    # Fields for DeleteRuleSetRequest
    # Field: name Type: 9 ()

# === Message: Google::Cloud::Contentwarehouse::V1::RulesetServiceRequest::ListRuleSetsRequest ===
    # Fields for ListRuleSetsRequest
    # Field: parent Type: 9 ()
    # Field: page_size Type: 5 ()
    # Field: page_token Type: 9 ()

# === Message: Google::Cloud::Contentwarehouse::V1::RulesetServiceRequest::ListRuleSetsResponse ===
    # Fields for ListRuleSetsResponse
    # Field: rule_sets Type: 11 (.google.cloud.contentwarehouse.v1.RuleSet)
    # Field: next_page_token Type: 9 ()

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Contentwarehouse::V1::RulesetServiceRequest - Compiled Protocol Buffers messages for google/cloud/contentwarehouse/v1/ruleset_service_request.proto

=head1 SYNOPSIS

    use Google::Cloud::Contentwarehouse::V1::RulesetServiceRequest;

    my $msg = Google::Cloud::Contentwarehouse::V1::RulesetServiceRequest::CreateRuleSetRequest->new({
        parent => $parent,
        rule_set => $rule_set,
    });

    # Read or update a field
    my $val = $msg->parent();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Contentwarehouse::V1::RulesetServiceRequest::CreateRuleSetRequest->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/contentwarehouse/v1/ruleset_service_request.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Contentwarehouse::V1::RulesetServiceRequest::CreateRuleSetRequest

Request message for RuleSetService.CreateRuleSet.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->parent() >> / C<< $msg->parent($value) >>

Type: C<String>

Required. The parent name.
Format: projects/{project_number}/locations/{location}.

=item * C<< $msg->rule_set() >> / C<< $msg->rule_set($value) >>

Type: C<Message> (L<Google::Cloud::Contentwarehouse::V1::RuleEngine::RuleSet>)

Required. The rule set to create.

=back

=head2 Google::Cloud::Contentwarehouse::V1::RulesetServiceRequest::GetRuleSetRequest

Request message for RuleSetService.GetRuleSet.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. The name of the rule set to retrieve.
Format:
projects/{project_number}/locations/{location}/ruleSets/{rule_set_id}.

=back

=head2 Google::Cloud::Contentwarehouse::V1::RulesetServiceRequest::UpdateRuleSetRequest

Request message for RuleSetService.UpdateRuleSet.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. The name of the rule set to update.
Format:
projects/{project_number}/locations/{location}/ruleSets/{rule_set_id}.

=item * C<< $msg->rule_set() >> / C<< $msg->rule_set($value) >>

Type: C<Message> (L<Google::Cloud::Contentwarehouse::V1::RuleEngine::RuleSet>)

Required. The rule set to update.

=back

=head2 Google::Cloud::Contentwarehouse::V1::RulesetServiceRequest::DeleteRuleSetRequest

Request message for RuleSetService.DeleteRuleSet.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. The name of the rule set to delete.
Format:
projects/{project_number}/locations/{location}/ruleSets/{rule_set_id}.

=back

=head2 Google::Cloud::Contentwarehouse::V1::RulesetServiceRequest::ListRuleSetsRequest

Request message for RuleSetService.ListRuleSets.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->parent() >> / C<< $msg->parent($value) >>

Type: C<String>

Required. The parent, which owns this collection of document.
Format: projects/{project_number}/locations/{location}.

=item * C<< $msg->page_size() >> / C<< $msg->page_size($value) >>

Type: C<Int32>

The maximum number of rule sets to return. The service may return
fewer than this value.
If unspecified, at most 50 rule sets will be returned.
The maximum value is 1000; values above 1000 will be coerced to 1000.

=item * C<< $msg->page_token() >> / C<< $msg->page_token($value) >>

Type: C<String>

A page token, received from a previous `ListRuleSets` call.
Provide this to retrieve the subsequent page.

When paginating, all other parameters provided to `ListRuleSets`
must match the call that provided the page token.

=back

=head2 Google::Cloud::Contentwarehouse::V1::RulesetServiceRequest::ListRuleSetsResponse

Response message for RuleSetService.ListRuleSets.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->rule_sets() >> / C<< $msg->rule_sets($value) >>

Type: C<Message> (L<Google::Cloud::Contentwarehouse::V1::RuleEngine::RuleSet>)

The rule sets from the specified parent.

=item * C<< $msg->next_page_token() >> / C<< $msg->next_page_token($value) >>

Type: C<String>

A token, which can be sent as `page_token` to retrieve the next page.
If this field is omitted, there are no subsequent pages.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Contentwarehouse::V1::RulesetServiceRequest::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
