package Google::Ai::Generativelanguage::V1::Model;

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
Citnb29nbGUvYWkvZ2VuZXJhdGl2ZWxhbmd1YWdlL3YxL21vZGVsLnByb3RvEh9nb29nbGUu
YWkuZ2VuZXJhdGl2ZWxhbmd1YWdlLnYxGh9nb29nbGUvYXBpL2ZpZWxkX2JlaGF2aW9yLnBy
b3RvGhlnb29nbGUvYXBpL3Jlc291cmNlLnByb3RvIuQECgVNb2RlbBIXCgRuYW1lGAEgASgJ
QgPgQQJSBG5hbWUSJwoNYmFzZV9tb2RlbF9pZBgCIAEoCUID4EECUgtiYXNlTW9kZWxJZBId
Cgd2ZXJzaW9uGAMgASgJQgPgQQJSB3ZlcnNpb24SIQoMZGlzcGxheV9uYW1lGAQgASgJUgtk
aXNwbGF5TmFtZRIgCgtkZXNjcmlwdGlvbhgFIAEoCVILZGVzY3JpcHRpb24SKgoRaW5wdXRf
dG9rZW5fbGltaXQYBiABKAVSD2lucHV0VG9rZW5MaW1pdBIsChJvdXRwdXRfdG9rZW5fbGlt
aXQYByABKAVSEG91dHB1dFRva2VuTGltaXQSQAocc3VwcG9ydGVkX2dlbmVyYXRpb25fbWV0
aG9kcxgIIAMoCVIac3VwcG9ydGVkR2VuZXJhdGlvbk1ldGhvZHMSJQoLdGVtcGVyYXR1cmUY
CSABKAJIAFILdGVtcGVyYXR1cmWIAQESLAoPbWF4X3RlbXBlcmF0dXJlGA0gASgCSAFSDm1h
eFRlbXBlcmF0dXJliAEBEhgKBXRvcF9wGAogASgCSAJSBHRvcFCIAQESGAoFdG9wX2sYCyAB
KAVIA1IEdG9wS4gBARIaCgh0aGlua2luZxgPIAEoCFIIdGhpbmtpbmc6POpBOQonZ2VuZXJh
dGl2ZWxhbmd1YWdlLmdvb2dsZWFwaXMuY29tL01vZGVsEg5tb2RlbHMve21vZGVsfUIOCgxf
dGVtcGVyYXR1cmVCEgoQX21heF90ZW1wZXJhdHVyZUIICgZfdG9wX3BCCAoGX3RvcF9rQo4B
CiNjb20uZ29vZ2xlLmFpLmdlbmVyYXRpdmVsYW5ndWFnZS52MUIKTW9kZWxQcm90b1ABWllj
bG91ZC5nb29nbGUuY29tL2dvL2FpL2dlbmVyYXRpdmVsYW5ndWFnZS9hcGl2MS9nZW5lcmF0
aXZlbGFuZ3VhZ2VwYjtnZW5lcmF0aXZlbGFuZ3VhZ2VwYkqFHQoGEgQOAG8BCrwECgEMEgMO
ABIysQQgQ29weXJpZ2h0IDIwMjUgR29vZ2xlIExMQwoKIExpY2Vuc2VkIHVuZGVyIHRoZSBB
cGFjaGUgTGljZW5zZSwgVmVyc2lvbiAyLjAgKHRoZSAiTGljZW5zZSIpOwogeW91IG1heSBu
b3QgdXNlIHRoaXMgZmlsZSBleGNlcHQgaW4gY29tcGxpYW5jZSB3aXRoIHRoZSBMaWNlbnNl
LgogWW91IG1heSBvYnRhaW4gYSBjb3B5IG9mIHRoZSBMaWNlbnNlIGF0CgogICAgIGh0dHA6
Ly93d3cuYXBhY2hlLm9yZy9saWNlbnNlcy9MSUNFTlNFLTIuMAoKIFVubGVzcyByZXF1aXJl
ZCBieSBhcHBsaWNhYmxlIGxhdyBvciBhZ3JlZWQgdG8gaW4gd3JpdGluZywgc29mdHdhcmUK
IGRpc3RyaWJ1dGVkIHVuZGVyIHRoZSBMaWNlbnNlIGlzIGRpc3RyaWJ1dGVkIG9uIGFuICJB
UyBJUyIgQkFTSVMsCiBXSVRIT1VUIFdBUlJBTlRJRVMgT1IgQ09ORElUSU9OUyBPRiBBTlkg
S0lORCwgZWl0aGVyIGV4cHJlc3Mgb3IgaW1wbGllZC4KIFNlZSB0aGUgTGljZW5zZSBmb3Ig
dGhlIHNwZWNpZmljIGxhbmd1YWdlIGdvdmVybmluZyBwZXJtaXNzaW9ucyBhbmQKIGxpbWl0
YXRpb25zIHVuZGVyIHRoZSBMaWNlbnNlLgoKCAoBAhIDEAAoCgkKAgMAEgMSACkKCQoCAwES
AxMAIwoICgEIEgMVAHAKCQoCCAsSAxUAcAoICgEIEgMWACIKCQoCCAoSAxYAIgoICgEIEgMX
ACsKCQoCCAgSAxcAKwoICgEIEgMYADwKCQoCCAESAxgAPAo8CgIEABIEGwBvARowIEluZm9y
bWF0aW9uIGFib3V0IGEgR2VuZXJhdGl2ZSBMYW5ndWFnZSBNb2RlbC4KCgoKAwQAARIDGwgN
CgsKAwQABxIEHAIfBAoNCgUEAAedCBIEHAIfBArFAgoEBAACABIDLAI7GrcCIFJlcXVpcmVk
LiBUaGUgcmVzb3VyY2UgbmFtZSBvZiB0aGUgYE1vZGVsYC4gUmVmZXIgdG8gW01vZGVsCiB2
YXJpYW50c10oaHR0cHM6Ly9haS5nb29nbGUuZGV2L2dlbWluaS1hcGkvZG9jcy9tb2RlbHMv
Z2VtaW5pI21vZGVsLXZhcmlhdGlvbnMpCiBmb3IgYWxsIGFsbG93ZWQgdmFsdWVzLgoKIEZv
cm1hdDogYG1vZGVscy97bW9kZWx9YCB3aXRoIGEgYHttb2RlbH1gIG5hbWluZyBjb252ZW50
aW9uIG9mOgoKICogIntiYXNlX21vZGVsX2lkfS17dmVyc2lvbn0iCgogRXhhbXBsZXM6Cgog
KiBgbW9kZWxzL2dlbWluaS0xLjUtZmxhc2gtMDAxYAoKDAoFBAACAAUSAywCCAoMCgUEAAIA
ARIDLAkNCgwKBQQAAgADEgMsEBEKDAoFBAACAAgSAywSOgoPCggEAAIACJwIABIDLBM5CnwK
BAQAAgESAzMCRBpvIFJlcXVpcmVkLiBUaGUgbmFtZSBvZiB0aGUgYmFzZSBtb2RlbCwgcGFz
cyB0aGlzIHRvIHRoZSBnZW5lcmF0aW9uIHJlcXVlc3QuCgogRXhhbXBsZXM6CgogKiBgZ2Vt
aW5pLTEuNS1mbGFzaGAKCgwKBQQAAgEFEgMzAggKDAoFBAACAQESAzMJFgoMCgUEAAIBAxID
MxkaCgwKBQQAAgEIEgMzG0MKDwoIBAACAQicCAASAzMcQgpuCgQEAAICEgM4Aj4aYSBSZXF1
aXJlZC4gVGhlIHZlcnNpb24gbnVtYmVyIG9mIHRoZSBtb2RlbC4KCiBUaGlzIHJlcHJlc2Vu
dHMgdGhlIG1ham9yIHZlcnNpb24gKGAxLjBgIG9yIGAxLjVgKQoKDAoFBAACAgUSAzgCCAoM
CgUEAAICARIDOAkQCgwKBQQAAgIDEgM4ExQKDAoFBAACAggSAzgVPQoPCggEAAICCJwIABID
OBY8CqQBCgQEAAIDEgM+AhoalgEgVGhlIGh1bWFuLXJlYWRhYmxlIG5hbWUgb2YgdGhlIG1v
ZGVsLiBFLmcuICJHZW1pbmkgMS41IEZsYXNoIi4KCiBUaGUgbmFtZSBjYW4gYmUgdXAgdG8g
MTI4IGNoYXJhY3RlcnMgbG9uZyBhbmQgY2FuIGNvbnNpc3Qgb2YgYW55IFVURi04CiBjaGFy
YWN0ZXJzLgoKDAoFBAACAwUSAz4CCAoMCgUEAAIDARIDPgkVCgwKBQQAAgMDEgM+GBkKMAoE
BAACBBIDQQIZGiMgQSBzaG9ydCBkZXNjcmlwdGlvbiBvZiB0aGUgbW9kZWwuCgoMCgUEAAIE
BRIDQQIICgwKBQQAAgQBEgNBCRQKDAoFBAACBAMSA0EXGApFCgQEAAIFEgNEAh4aOCBNYXhp
bXVtIG51bWJlciBvZiBpbnB1dCB0b2tlbnMgYWxsb3dlZCBmb3IgdGhpcyBtb2RlbC4KCgwK
BQQAAgUFEgNEAgcKDAoFBAACBQESA0QIGQoMCgUEAAIFAxIDRBwdCkgKBAQAAgYSA0cCHxo7
IE1heGltdW0gbnVtYmVyIG9mIG91dHB1dCB0b2tlbnMgYXZhaWxhYmxlIGZvciB0aGlzIG1v
ZGVsLgoKDAoFBAACBgUSA0cCBwoMCgUEAAIGARIDRwgaCgwKBQQAAgYDEgNHHR4KtAEKBAQA
AgcSA00CMxqmASBUaGUgbW9kZWwncyBzdXBwb3J0ZWQgZ2VuZXJhdGlvbiBtZXRob2RzLgoK
IFRoZSBjb3JyZXNwb25kaW5nIEFQSSBtZXRob2QgbmFtZXMgYXJlIGRlZmluZWQgYXMgUGFz
Y2FsIGNhc2UKIHN0cmluZ3MsIHN1Y2ggYXMgYGdlbmVyYXRlTWVzc2FnZWAgYW5kIGBnZW5l
cmF0ZUNvbnRlbnRgLgoKDAoFBAACBwQSA00CCgoMCgUEAAIHBRIDTQsRCgwKBQQAAgcBEgNN
Ei4KDAoFBAACBwMSA00xMgruAgoEBAACCBIDVgIhGuACIENvbnRyb2xzIHRoZSByYW5kb21u
ZXNzIG9mIHRoZSBvdXRwdXQuCgogVmFsdWVzIGNhbiByYW5nZSBvdmVyIGBbMC4wLG1heF90
ZW1wZXJhdHVyZV1gLCBpbmNsdXNpdmUuIEEgaGlnaGVyIHZhbHVlCiB3aWxsIHByb2R1Y2Ug
cmVzcG9uc2VzIHRoYXQgYXJlIG1vcmUgdmFyaWVkLCB3aGlsZSBhIHZhbHVlIGNsb3NlciB0
byBgMC4wYAogd2lsbCB0eXBpY2FsbHkgcmVzdWx0IGluIGxlc3Mgc3VycHJpc2luZyByZXNw
b25zZXMgZnJvbSB0aGUgbW9kZWwuCiBUaGlzIHZhbHVlIHNwZWNpZmllcyBkZWZhdWx0IHRv
IGJlIHVzZWQgYnkgdGhlIGJhY2tlbmQgd2hpbGUgbWFraW5nIHRoZQogY2FsbCB0byB0aGUg
bW9kZWwuCgoMCgUEAAIIBBIDVgIKCgwKBQQAAggFEgNWCxAKDAoFBAACCAESA1YRHAoMCgUE
AAIIAxIDVh8gCjoKBAQAAgkSA1kCJhotIFRoZSBtYXhpbXVtIHRlbXBlcmF0dXJlIHRoaXMg
bW9kZWwgY2FuIHVzZS4KCgwKBQQAAgkEEgNZAgoKDAoFBAACCQUSA1kLEAoMCgUEAAIJARID
WREgCgwKBQQAAgkDEgNZIyUKqwIKBAQAAgoSA2ICHBqdAiBGb3IgW051Y2xldXMKIHNhbXBs
aW5nXShodHRwczovL2FpLmdvb2dsZS5kZXYvZ2VtaW5pLWFwaS9kb2NzL3Byb21wdGluZy1z
dHJhdGVnaWVzI3RvcC1wKS4KCiBOdWNsZXVzIHNhbXBsaW5nIGNvbnNpZGVycyB0aGUgc21h
bGxlc3Qgc2V0IG9mIHRva2VucyB3aG9zZSBwcm9iYWJpbGl0eQogc3VtIGlzIGF0IGxlYXN0
IGB0b3BfcGAuCiBUaGlzIHZhbHVlIHNwZWNpZmllcyBkZWZhdWx0IHRvIGJlIHVzZWQgYnkg
dGhlIGJhY2tlbmQgd2hpbGUgbWFraW5nIHRoZQogY2FsbCB0byB0aGUgbW9kZWwuCgoMCgUE
AAIKBBIDYgIKCgwKBQQAAgoFEgNiCxAKDAoFBAACCgESA2IRFgoMCgUEAAIKAxIDYhkbCrUC
CgQEAAILEgNrAhwapwIgRm9yIFRvcC1rIHNhbXBsaW5nLgoKIFRvcC1rIHNhbXBsaW5nIGNv
bnNpZGVycyB0aGUgc2V0IG9mIGB0b3Bfa2AgbW9zdCBwcm9iYWJsZSB0b2tlbnMuCiBUaGlz
IHZhbHVlIHNwZWNpZmllcyBkZWZhdWx0IHRvIGJlIHVzZWQgYnkgdGhlIGJhY2tlbmQgd2hp
bGUgbWFraW5nIHRoZQogY2FsbCB0byB0aGUgbW9kZWwuCiBJZiBlbXB0eSwgaW5kaWNhdGVz
IHRoZSBtb2RlbCBkb2Vzbid0IHVzZSB0b3AtayBzYW1wbGluZywgYW5kIGB0b3Bfa2AgaXNu
J3QKIGFsbG93ZWQgYXMgYSBnZW5lcmF0aW9uIHBhcmFtZXRlci4KCgwKBQQAAgsEEgNrAgoK
DAoFBAACCwUSA2sLEAoMCgUEAAILARIDaxEWCgwKBQQAAgsDEgNrGRsKMwoEBAACDBIDbgIV
GiYgV2hldGhlciB0aGUgbW9kZWwgc3VwcG9ydHMgdGhpbmtpbmcuCgoMCgUEAAIMBRIDbgIG
CgwKBQQAAgwBEgNuBw8KDAoFBAACDAMSA24SFGIGcHJvdG8z
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Ai::Generativelanguage::V1::Model::Model ===
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
    # Field: max_temperature Type: 2 ()
    # Field: top_p Type: 2 ()
    # Field: top_k Type: 5 ()
    # Field: thinking Type: 8 ()

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Ai::Generativelanguage::V1::Model - Compiled Protocol Buffers messages for google/ai/generativelanguage/v1/model.proto

=head1 SYNOPSIS

    use Google::Ai::Generativelanguage::V1::Model;

    my $msg = Google::Ai::Generativelanguage::V1::Model::Model->new({
        name => $name,
        base_model_id => $base_model_id,
        version => $version,
        display_name => $display_name,
    });

    # Read or update a field
    my $val = $msg->name();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Ai::Generativelanguage::V1::Model::Model->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/ai/generativelanguage/v1/model.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Ai::Generativelanguage::V1::Model::Model

Information about a Generative Language Model.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. The resource name of the `Model`. Refer to [Model
variants](https://ai.google.dev/gemini-api/docs/models/gemini#model-variations)
for all allowed values.

Format: `models/{model}` with a `{model}` naming convention of:

* "{base_model_id}-{version}"

Examples:

* `models/gemini-1.5-flash-001`

=item * C<< $msg->base_model_id() >> / C<< $msg->base_model_id($value) >>

Type: C<String>

Required. The name of the base model, pass this to the generation request.

Examples:

* `gemini-1.5-flash`

=item * C<< $msg->version() >> / C<< $msg->version($value) >>

Type: C<String>

Required. The version number of the model.

This represents the major version (`1.0` or `1.5`)

=item * C<< $msg->display_name() >> / C<< $msg->display_name($value) >>

Type: C<String>

The human-readable name of the model. E.g. "Gemini 1.5 Flash".

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

The corresponding API method names are defined as Pascal case
strings, such as `generateMessage` and `generateContent`.

=item * C<< $msg->temperature() >> / C<< $msg->temperature($value) >>

Type: C<Float>

Controls the randomness of the output.

Values can range over `[0.0,max_temperature]`, inclusive. A higher value
will produce responses that are more varied, while a value closer to `0.0`
will typically result in less surprising responses from the model.
This value specifies default to be used by the backend while making the
call to the model.

=item * C<< $msg->max_temperature() >> / C<< $msg->max_temperature($value) >>

Type: C<Float>

The maximum temperature this model can use.

=item * C<< $msg->top_p() >> / C<< $msg->top_p($value) >>

Type: C<Float>

For [Nucleus
sampling](https://ai.google.dev/gemini-api/docs/prompting-strategies#top-p).

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
If empty, indicates the model doesn't use top-k sampling, and `top_k` isn't
allowed as a generation parameter.

=item * C<< $msg->thinking() >> / C<< $msg->thinking($value) >>

Type: C<Bool>

Whether the model supports thinking.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Ai::Generativelanguage::V1::Model::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
