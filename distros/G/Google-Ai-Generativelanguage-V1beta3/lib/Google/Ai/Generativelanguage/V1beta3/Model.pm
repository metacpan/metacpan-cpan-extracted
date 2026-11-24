package Google::Ai::Generativelanguage::V1beta3::Model;

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
    my $descriptor_b64 = <<'EOF';
CjBnb29nbGUvYWkvZ2VuZXJhdGl2ZWxhbmd1YWdlL3YxYmV0YTMvbW9kZWwucHJvdG8SJGdv
b2dsZS5haS5nZW5lcmF0aXZlbGFuZ3VhZ2UudjFiZXRhMxofZ29vZ2xlL2FwaS9maWVsZF9i
ZWhhdmlvci5wcm90bxoZZ29vZ2xlL2FwaS9yZXNvdXJjZS5wcm90byKGBAoFTW9kZWwSFwoE
bmFtZRgBIAEoCUID4EECUgRuYW1lEicKDWJhc2VfbW9kZWxfaWQYAiABKAlCA+BBAlILYmFz
ZU1vZGVsSWQSHQoHdmVyc2lvbhgDIAEoCUID4EECUgd2ZXJzaW9uEiEKDGRpc3BsYXlfbmFt
ZRgEIAEoCVILZGlzcGxheU5hbWUSIAoLZGVzY3JpcHRpb24YBSABKAlSC2Rlc2NyaXB0aW9u
EioKEWlucHV0X3Rva2VuX2xpbWl0GAYgASgFUg9pbnB1dFRva2VuTGltaXQSLAoSb3V0cHV0
X3Rva2VuX2xpbWl0GAcgASgFUhBvdXRwdXRUb2tlbkxpbWl0EkAKHHN1cHBvcnRlZF9nZW5l
cmF0aW9uX21ldGhvZHMYCCADKAlSGnN1cHBvcnRlZEdlbmVyYXRpb25NZXRob2RzEiUKC3Rl
bXBlcmF0dXJlGAkgASgCSABSC3RlbXBlcmF0dXJliAEBEhgKBXRvcF9wGAogASgCSAFSBHRv
cFCIAQESGAoFdG9wX2sYCyABKAVIAlIEdG9wS4gBATo86kE5CidnZW5lcmF0aXZlbGFuZ3Vh
Z2UuZ29vZ2xlYXBpcy5jb20vTW9kZWwSDm1vZGVscy97bW9kZWx9Qg4KDF90ZW1wZXJhdHVy
ZUIICgZfdG9wX3BCCAoGX3RvcF9rQpgBCihjb20uZ29vZ2xlLmFpLmdlbmVyYXRpdmVsYW5n
dWFnZS52MWJldGEzQgpNb2RlbFByb3RvUAFaXmNsb3VkLmdvb2dsZS5jb20vZ28vYWkvZ2Vu
ZXJhdGl2ZWxhbmd1YWdlL2FwaXYxYmV0YTMvZ2VuZXJhdGl2ZWxhbmd1YWdlcGI7Z2VuZXJh
dGl2ZWxhbmd1YWdlcGJK1BgKBhIEDgBkAQq8BAoBDBIDDgASMrEEIENvcHlyaWdodCAyMDI1
IEdvb2dsZSBMTEMKCiBMaWNlbnNlZCB1bmRlciB0aGUgQXBhY2hlIExpY2Vuc2UsIFZlcnNp
b24gMi4wICh0aGUgIkxpY2Vuc2UiKTsKIHlvdSBtYXkgbm90IHVzZSB0aGlzIGZpbGUgZXhj
ZXB0IGluIGNvbXBsaWFuY2Ugd2l0aCB0aGUgTGljZW5zZS4KIFlvdSBtYXkgb2J0YWluIGEg
Y29weSBvZiB0aGUgTGljZW5zZSBhdAoKICAgICBodHRwOi8vd3d3LmFwYWNoZS5vcmcvbGlj
ZW5zZXMvTElDRU5TRS0yLjAKCiBVbmxlc3MgcmVxdWlyZWQgYnkgYXBwbGljYWJsZSBsYXcg
b3IgYWdyZWVkIHRvIGluIHdyaXRpbmcsIHNvZnR3YXJlCiBkaXN0cmlidXRlZCB1bmRlciB0
aGUgTGljZW5zZSBpcyBkaXN0cmlidXRlZCBvbiBhbiAiQVMgSVMiIEJBU0lTLAogV0lUSE9V
VCBXQVJSQU5USUVTIE9SIENPTkRJVElPTlMgT0YgQU5ZIEtJTkQsIGVpdGhlciBleHByZXNz
IG9yIGltcGxpZWQuCiBTZWUgdGhlIExpY2Vuc2UgZm9yIHRoZSBzcGVjaWZpYyBsYW5ndWFn
ZSBnb3Zlcm5pbmcgcGVybWlzc2lvbnMgYW5kCiBsaW1pdGF0aW9ucyB1bmRlciB0aGUgTGlj
ZW5zZS4KCggKAQISAxAALQoJCgIDABIDEgApCgkKAgMBEgMTACMKCAoBCBIDFQB1CgkKAggL
EgMVAHUKCAoBCBIDFgAiCgkKAggKEgMWACIKCAoBCBIDFwArCgkKAggIEgMXACsKCAoBCBID
GABBCgkKAggBEgMYAEEKPAoCBAASBBsAZAEaMCBJbmZvcm1hdGlvbiBhYm91dCBhIEdlbmVy
YXRpdmUgTGFuZ3VhZ2UgTW9kZWwuCgoKCgMEAAESAxsIDQoLCgMEAAcSBBwCHwQKDQoFBAAH
nQgSBBwCHwQKxQEKBAQAAgASAyoCOxq3ASBSZXF1aXJlZC4gVGhlIHJlc291cmNlIG5hbWUg
b2YgdGhlIGBNb2RlbGAuCgogRm9ybWF0OiBgbW9kZWxzL3ttb2RlbH1gIHdpdGggYSBge21v
ZGVsfWAgbmFtaW5nIGNvbnZlbnRpb24gb2Y6CgogKiAie2Jhc2VfbW9kZWxfaWR9LXt2ZXJz
aW9ufSIKCiBFeGFtcGxlczoKCiAqIGBtb2RlbHMvY2hhdC1iaXNvbi0wMDFgCgoMCgUEAAIA
BRIDKgIICgwKBQQAAgABEgMqCQ0KDAoFBAACAAMSAyoQEQoMCgUEAAIACBIDKhI6Cg8KCAQA
AgAInAgAEgMqEzkKdgoEBAACARIDMQJEGmkgUmVxdWlyZWQuIFRoZSBuYW1lIG9mIHRoZSBi
YXNlIG1vZGVsLCBwYXNzIHRoaXMgdG8gdGhlIGdlbmVyYXRpb24gcmVxdWVzdC4KCiBFeGFt
cGxlczoKCiAqIGBjaGF0LWJpc29uYAoKDAoFBAACAQUSAzECCAoMCgUEAAIBARIDMQkWCgwK
BQQAAgEDEgMxGRoKDAoFBAACAQgSAzEbQwoPCggEAAIBCJwIABIDMRxCCl0KBAQAAgISAzYC
PhpQIFJlcXVpcmVkLiBUaGUgdmVyc2lvbiBudW1iZXIgb2YgdGhlIG1vZGVsLgoKIFRoaXMg
cmVwcmVzZW50cyB0aGUgbWFqb3IgdmVyc2lvbgoKDAoFBAACAgUSAzYCCAoMCgUEAAICARID
NgkQCgwKBQQAAgIDEgM2ExQKDAoFBAACAggSAzYVPQoPCggEAAICCJwIABIDNhY8Cp4BCgQE
AAIDEgM8AhoakAEgVGhlIGh1bWFuLXJlYWRhYmxlIG5hbWUgb2YgdGhlIG1vZGVsLiBFLmcu
ICJDaGF0IEJpc29uIi4KCiBUaGUgbmFtZSBjYW4gYmUgdXAgdG8gMTI4IGNoYXJhY3RlcnMg
bG9uZyBhbmQgY2FuIGNvbnNpc3Qgb2YgYW55IFVURi04CiBjaGFyYWN0ZXJzLgoKDAoFBAAC
AwUSAzwCCAoMCgUEAAIDARIDPAkVCgwKBQQAAgMDEgM8GBkKMAoEBAACBBIDPwIZGiMgQSBz
aG9ydCBkZXNjcmlwdGlvbiBvZiB0aGUgbW9kZWwuCgoMCgUEAAIEBRIDPwIICgwKBQQAAgQB
EgM/CRQKDAoFBAACBAMSAz8XGApFCgQEAAIFEgNCAh4aOCBNYXhpbXVtIG51bWJlciBvZiBp
bnB1dCB0b2tlbnMgYWxsb3dlZCBmb3IgdGhpcyBtb2RlbC4KCgwKBQQAAgUFEgNCAgcKDAoF
BAACBQESA0IIGQoMCgUEAAIFAxIDQhwdCkgKBAQAAgYSA0UCHxo7IE1heGltdW0gbnVtYmVy
IG9mIG91dHB1dCB0b2tlbnMgYXZhaWxhYmxlIGZvciB0aGlzIG1vZGVsLgoKDAoFBAACBgUS
A0UCBwoMCgUEAAIGARIDRQgaCgwKBQQAAgYDEgNFHR4KrAEKBAQAAgcSA0sCMxqeASBUaGUg
bW9kZWwncyBzdXBwb3J0ZWQgZ2VuZXJhdGlvbiBtZXRob2RzLgoKIFRoZSBtZXRob2QgbmFt
ZXMgYXJlIGRlZmluZWQgYXMgUGFzY2FsIGNhc2UKIHN0cmluZ3MsIHN1Y2ggYXMgYGdlbmVy
YXRlTWVzc2FnZWAgd2hpY2ggY29ycmVzcG9uZCB0byBBUEkgbWV0aG9kcy4KCgwKBQQAAgcE
EgNLAgoKDAoFBAACBwUSA0sLEQoMCgUEAAIHARIDSxIuCgwKBQQAAgcDEgNLMTIK6wIKBAQA
AggSA1QCIRrdAiBDb250cm9scyB0aGUgcmFuZG9tbmVzcyBvZiB0aGUgb3V0cHV0LgoKIFZh
bHVlcyBjYW4gcmFuZ2Ugb3ZlciBgWzAuMCwxLjBdYCwgaW5jbHVzaXZlLiBBIHZhbHVlIGNs
b3NlciB0byBgMS4wYCB3aWxsCiBwcm9kdWNlIHJlc3BvbnNlcyB0aGF0IGFyZSBtb3JlIHZh
cmllZCwgd2hpbGUgYSB2YWx1ZSBjbG9zZXIgdG8gYDAuMGAgd2lsbAogdHlwaWNhbGx5IHJl
c3VsdCBpbiBsZXNzIHN1cnByaXNpbmcgcmVzcG9uc2VzIGZyb20gdGhlIG1vZGVsLgogVGhp
cyB2YWx1ZSBzcGVjaWZpZXMgZGVmYXVsdCB0byBiZSB1c2VkIGJ5IHRoZSBiYWNrZW5kIHdo
aWxlIG1ha2luZyB0aGUKIGNhbGwgdG8gdGhlIG1vZGVsLgoKDAoFBAACCAQSA1QCCgoMCgUE
AAIIBRIDVAsQCgwKBQQAAggBEgNUERwKDAoFBAACCAMSA1QfIArmAQoEBAACCRIDXAIcGtgB
IEZvciBOdWNsZXVzIHNhbXBsaW5nLgoKIE51Y2xldXMgc2FtcGxpbmcgY29uc2lkZXJzIHRo
ZSBzbWFsbGVzdCBzZXQgb2YgdG9rZW5zIHdob3NlIHByb2JhYmlsaXR5CiBzdW0gaXMgYXQg
bGVhc3QgYHRvcF9wYC4KIFRoaXMgdmFsdWUgc3BlY2lmaWVzIGRlZmF1bHQgdG8gYmUgdXNl
ZCBieSB0aGUgYmFja2VuZCB3aGlsZSBtYWtpbmcgdGhlCiBjYWxsIHRvIHRoZSBtb2RlbC4K
CgwKBQQAAgkEEgNcAgoKDAoFBAACCQUSA1wLEAoMCgUEAAIJARIDXBEWCgwKBQQAAgkDEgNc
GRsKxAEKBAQAAgoSA2MCHBq2ASBGb3IgVG9wLWsgc2FtcGxpbmcuCgogVG9wLWsgc2FtcGxp
bmcgY29uc2lkZXJzIHRoZSBzZXQgb2YgYHRvcF9rYCBtb3N0IHByb2JhYmxlIHRva2Vucy4K
IFRoaXMgdmFsdWUgc3BlY2lmaWVzIGRlZmF1bHQgdG8gYmUgdXNlZCBieSB0aGUgYmFja2Vu
ZCB3aGlsZSBtYWtpbmcgdGhlCiBjYWxsIHRvIHRoZSBtb2RlbC4KCgwKBQQAAgoEEgNjAgoK
DAoFBAACCgUSA2MLEAoMCgUEAAIKARIDYxEWCgwKBQQAAgoDEgNjGRtiBnByb3RvMw==
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Ai::Generativelanguage::V1beta3::Model::Model ===
    # Fields for Model
    # Field: name Type: 9 ()
    # Field: base_model_id Type: 9 ()
    # Field: version Type: 9 ()
    # Field: display_name Type: 9 ()
    # Field: description Type: 9 ()
    # Field: input_token_limit Type: 5 ()
    # Field: output_token_limit Type: 5 ()
    # Field: supported_generation_methods Type: 9 ()
    # Field: temperature Type: 2 ()
    # Field: top_p Type: 2 ()
    # Field: top_k Type: 5 ()

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Ai::Generativelanguage::V1beta3::Model - Compiled Protocol Buffers messages for google/ai/generativelanguage/v1beta3/model.proto

=head1 SYNOPSIS

    use Google::Ai::Generativelanguage::V1beta3::Model;

    my $msg = Google::Ai::Generativelanguage::V1beta3::Model::Model->new({
        name => $name,
        base_model_id => $base_model_id,
        version => $version,
        display_name => $display_name,
    });

    # Read or update a field
    my $val = $msg->name();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Ai::Generativelanguage::V1beta3::Model::Model->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/ai/generativelanguage/v1beta3/model.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Ai::Generativelanguage::V1beta3::Model::Model

Information about a Generative Language Model.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. The resource name of the `Model`.

Format: `models/{model}` with a `{model}` naming convention of:

* "{base_model_id}-{version}"

Examples:

* `models/chat-bison-001`

=item * C<< $msg->base_model_id() >> / C<< $msg->base_model_id($value) >>

Type: C<String>

Required. The name of the base model, pass this to the generation request.

Examples:

* `chat-bison`

=item * C<< $msg->version() >> / C<< $msg->version($value) >>

Type: C<String>

Required. The version number of the model.

This represents the major version

=item * C<< $msg->display_name() >> / C<< $msg->display_name($value) >>

Type: C<String>

The human-readable name of the model. E.g. "Chat Bison".

The name can be up to 128 characters long and can consist of any UTF-8
characters.

=item * C<< $msg->description() >> / C<< $msg->description($value) >>

Type: C<String>

A short description of the model.

=item * C<< $msg->input_token_limit() >> / C<< $msg->input_token_limit($value) >>

Type: C<Int32>

Maximum number of input tokens allowed for this model.

=item * C<< $msg->output_token_limit() >> / C<< $msg->output_token_limit($value) >>

Type: C<Int32>

Maximum number of output tokens available for this model.

=item * C<< $msg->supported_generation_methods() >> / C<< $msg->supported_generation_methods($value) >>

Type: C<String>

The model's supported generation methods.

The method names are defined as Pascal case
strings, such as `generateMessage` which correspond to API methods.

=item * C<< $msg->temperature() >> / C<< $msg->temperature($value) >>

Type: C<Float>

Controls the randomness of the output.

Values can range over `[0.0,1.0]`, inclusive. A value closer to `1.0` will
produce responses that are more varied, while a value closer to `0.0` will
typically result in less surprising responses from the model.
This value specifies default to be used by the backend while making the
call to the model.

=item * C<< $msg->top_p() >> / C<< $msg->top_p($value) >>

Type: C<Float>

For Nucleus sampling.

Nucleus sampling considers the smallest set of tokens whose probability
sum is at least `top_p`.
This value specifies default to be used by the backend while making the
call to the model.

=item * C<< $msg->top_k() >> / C<< $msg->top_k($value) >>

Type: C<Int32>

For Top-k sampling.

Top-k sampling considers the set of `top_k` most probable tokens.
This value specifies default to be used by the backend while making the
call to the model.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Ai::Generativelanguage::V1beta3::Model::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
