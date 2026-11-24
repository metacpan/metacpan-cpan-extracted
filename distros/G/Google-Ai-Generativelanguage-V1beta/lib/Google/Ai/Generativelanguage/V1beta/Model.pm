package Google::Ai::Generativelanguage::V1beta::Model;

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
Ci9nb29nbGUvYWkvZ2VuZXJhdGl2ZWxhbmd1YWdlL3YxYmV0YS9tb2RlbC5wcm90bxIjZ29v
Z2xlLmFpLmdlbmVyYXRpdmVsYW5ndWFnZS52MWJldGEaH2dvb2dsZS9hcGkvZmllbGRfYmVo
YXZpb3IucHJvdG8aGWdvb2dsZS9hcGkvcmVzb3VyY2UucHJvdG8i5AQKBU1vZGVsEhcKBG5h
bWUYASABKAlCA+BBAlIEbmFtZRInCg1iYXNlX21vZGVsX2lkGAIgASgJQgPgQQJSC2Jhc2VN
b2RlbElkEh0KB3ZlcnNpb24YAyABKAlCA+BBAlIHdmVyc2lvbhIhCgxkaXNwbGF5X25hbWUY
BCABKAlSC2Rpc3BsYXlOYW1lEiAKC2Rlc2NyaXB0aW9uGAUgASgJUgtkZXNjcmlwdGlvbhIq
ChFpbnB1dF90b2tlbl9saW1pdBgGIAEoBVIPaW5wdXRUb2tlbkxpbWl0EiwKEm91dHB1dF90
b2tlbl9saW1pdBgHIAEoBVIQb3V0cHV0VG9rZW5MaW1pdBJAChxzdXBwb3J0ZWRfZ2VuZXJh
dGlvbl9tZXRob2RzGAggAygJUhpzdXBwb3J0ZWRHZW5lcmF0aW9uTWV0aG9kcxIlCgt0ZW1w
ZXJhdHVyZRgJIAEoAkgAUgt0ZW1wZXJhdHVyZYgBARIsCg9tYXhfdGVtcGVyYXR1cmUYDSAB
KAJIAVIObWF4VGVtcGVyYXR1cmWIAQESGAoFdG9wX3AYCiABKAJIAlIEdG9wUIgBARIYCgV0
b3BfaxgLIAEoBUgDUgR0b3BLiAEBEhoKCHRoaW5raW5nGA8gASgIUgh0aGlua2luZzo86kE5
CidnZW5lcmF0aXZlbGFuZ3VhZ2UuZ29vZ2xlYXBpcy5jb20vTW9kZWwSDm1vZGVscy97bW9k
ZWx9Qg4KDF90ZW1wZXJhdHVyZUISChBfbWF4X3RlbXBlcmF0dXJlQggKBl90b3BfcEIICgZf
dG9wX2tClgEKJ2NvbS5nb29nbGUuYWkuZ2VuZXJhdGl2ZWxhbmd1YWdlLnYxYmV0YUIKTW9k
ZWxQcm90b1ABWl1jbG91ZC5nb29nbGUuY29tL2dvL2FpL2dlbmVyYXRpdmVsYW5ndWFnZS9h
cGl2MWJldGEvZ2VuZXJhdGl2ZWxhbmd1YWdlcGI7Z2VuZXJhdGl2ZWxhbmd1YWdlcGJKhR0K
BhIEDgBvAQq8BAoBDBIDDgASMrEEIENvcHlyaWdodCAyMDI1IEdvb2dsZSBMTEMKCiBMaWNl
bnNlZCB1bmRlciB0aGUgQXBhY2hlIExpY2Vuc2UsIFZlcnNpb24gMi4wICh0aGUgIkxpY2Vu
c2UiKTsKIHlvdSBtYXkgbm90IHVzZSB0aGlzIGZpbGUgZXhjZXB0IGluIGNvbXBsaWFuY2Ug
d2l0aCB0aGUgTGljZW5zZS4KIFlvdSBtYXkgb2J0YWluIGEgY29weSBvZiB0aGUgTGljZW5z
ZSBhdAoKICAgICBodHRwOi8vd3d3LmFwYWNoZS5vcmcvbGljZW5zZXMvTElDRU5TRS0yLjAK
CiBVbmxlc3MgcmVxdWlyZWQgYnkgYXBwbGljYWJsZSBsYXcgb3IgYWdyZWVkIHRvIGluIHdy
aXRpbmcsIHNvZnR3YXJlCiBkaXN0cmlidXRlZCB1bmRlciB0aGUgTGljZW5zZSBpcyBkaXN0
cmlidXRlZCBvbiBhbiAiQVMgSVMiIEJBU0lTLAogV0lUSE9VVCBXQVJSQU5USUVTIE9SIENP
TkRJVElPTlMgT0YgQU5ZIEtJTkQsIGVpdGhlciBleHByZXNzIG9yIGltcGxpZWQuCiBTZWUg
dGhlIExpY2Vuc2UgZm9yIHRoZSBzcGVjaWZpYyBsYW5ndWFnZSBnb3Zlcm5pbmcgcGVybWlz
c2lvbnMgYW5kCiBsaW1pdGF0aW9ucyB1bmRlciB0aGUgTGljZW5zZS4KCggKAQISAxAALAoJ
CgIDABIDEgApCgkKAgMBEgMTACMKCAoBCBIDFQB0CgkKAggLEgMVAHQKCAoBCBIDFgAiCgkK
AggKEgMWACIKCAoBCBIDFwArCgkKAggIEgMXACsKCAoBCBIDGABACgkKAggBEgMYAEAKPAoC
BAASBBsAbwEaMCBJbmZvcm1hdGlvbiBhYm91dCBhIEdlbmVyYXRpdmUgTGFuZ3VhZ2UgTW9k
ZWwuCgoKCgMEAAESAxsIDQoLCgMEAAcSBBwCHwQKDQoFBAAHnQgSBBwCHwQKxQIKBAQAAgAS
AywCOxq3AiBSZXF1aXJlZC4gVGhlIHJlc291cmNlIG5hbWUgb2YgdGhlIGBNb2RlbGAuIFJl
ZmVyIHRvIFtNb2RlbAogdmFyaWFudHNdKGh0dHBzOi8vYWkuZ29vZ2xlLmRldi9nZW1pbmkt
YXBpL2RvY3MvbW9kZWxzL2dlbWluaSNtb2RlbC12YXJpYXRpb25zKQogZm9yIGFsbCBhbGxv
d2VkIHZhbHVlcy4KCiBGb3JtYXQ6IGBtb2RlbHMve21vZGVsfWAgd2l0aCBhIGB7bW9kZWx9
YCBuYW1pbmcgY29udmVudGlvbiBvZjoKCiAqICJ7YmFzZV9tb2RlbF9pZH0te3ZlcnNpb259
IgoKIEV4YW1wbGVzOgoKICogYG1vZGVscy9nZW1pbmktMS41LWZsYXNoLTAwMWAKCgwKBQQA
AgAFEgMsAggKDAoFBAACAAESAywJDQoMCgUEAAIAAxIDLBARCgwKBQQAAgAIEgMsEjoKDwoI
BAACAAicCAASAywTOQp8CgQEAAIBEgMzAkQabyBSZXF1aXJlZC4gVGhlIG5hbWUgb2YgdGhl
IGJhc2UgbW9kZWwsIHBhc3MgdGhpcyB0byB0aGUgZ2VuZXJhdGlvbiByZXF1ZXN0LgoKIEV4
YW1wbGVzOgoKICogYGdlbWluaS0xLjUtZmxhc2hgCgoMCgUEAAIBBRIDMwIICgwKBQQAAgEB
EgMzCRYKDAoFBAACAQMSAzMZGgoMCgUEAAIBCBIDMxtDCg8KCAQAAgEInAgAEgMzHEIKbgoE
BAACAhIDOAI+GmEgUmVxdWlyZWQuIFRoZSB2ZXJzaW9uIG51bWJlciBvZiB0aGUgbW9kZWwu
CgogVGhpcyByZXByZXNlbnRzIHRoZSBtYWpvciB2ZXJzaW9uIChgMS4wYCBvciBgMS41YCkK
CgwKBQQAAgIFEgM4AggKDAoFBAACAgESAzgJEAoMCgUEAAICAxIDOBMUCgwKBQQAAgIIEgM4
FT0KDwoIBAACAgicCAASAzgWPAqkAQoEBAACAxIDPgIaGpYBIFRoZSBodW1hbi1yZWFkYWJs
ZSBuYW1lIG9mIHRoZSBtb2RlbC4gRS5nLiAiR2VtaW5pIDEuNSBGbGFzaCIuCgogVGhlIG5h
bWUgY2FuIGJlIHVwIHRvIDEyOCBjaGFyYWN0ZXJzIGxvbmcgYW5kIGNhbiBjb25zaXN0IG9m
IGFueSBVVEYtOAogY2hhcmFjdGVycy4KCgwKBQQAAgMFEgM+AggKDAoFBAACAwESAz4JFQoM
CgUEAAIDAxIDPhgZCjAKBAQAAgQSA0ECGRojIEEgc2hvcnQgZGVzY3JpcHRpb24gb2YgdGhl
IG1vZGVsLgoKDAoFBAACBAUSA0ECCAoMCgUEAAIEARIDQQkUCgwKBQQAAgQDEgNBFxgKRQoE
BAACBRIDRAIeGjggTWF4aW11bSBudW1iZXIgb2YgaW5wdXQgdG9rZW5zIGFsbG93ZWQgZm9y
IHRoaXMgbW9kZWwuCgoMCgUEAAIFBRIDRAIHCgwKBQQAAgUBEgNECBkKDAoFBAACBQMSA0Qc
HQpICgQEAAIGEgNHAh8aOyBNYXhpbXVtIG51bWJlciBvZiBvdXRwdXQgdG9rZW5zIGF2YWls
YWJsZSBmb3IgdGhpcyBtb2RlbC4KCgwKBQQAAgYFEgNHAgcKDAoFBAACBgESA0cIGgoMCgUE
AAIGAxIDRx0eCrQBCgQEAAIHEgNNAjMapgEgVGhlIG1vZGVsJ3Mgc3VwcG9ydGVkIGdlbmVy
YXRpb24gbWV0aG9kcy4KCiBUaGUgY29ycmVzcG9uZGluZyBBUEkgbWV0aG9kIG5hbWVzIGFy
ZSBkZWZpbmVkIGFzIFBhc2NhbCBjYXNlCiBzdHJpbmdzLCBzdWNoIGFzIGBnZW5lcmF0ZU1l
c3NhZ2VgIGFuZCBgZ2VuZXJhdGVDb250ZW50YC4KCgwKBQQAAgcEEgNNAgoKDAoFBAACBwUS
A00LEQoMCgUEAAIHARIDTRIuCgwKBQQAAgcDEgNNMTIK7gIKBAQAAggSA1YCIRrgAiBDb250
cm9scyB0aGUgcmFuZG9tbmVzcyBvZiB0aGUgb3V0cHV0LgoKIFZhbHVlcyBjYW4gcmFuZ2Ug
b3ZlciBgWzAuMCxtYXhfdGVtcGVyYXR1cmVdYCwgaW5jbHVzaXZlLiBBIGhpZ2hlciB2YWx1
ZQogd2lsbCBwcm9kdWNlIHJlc3BvbnNlcyB0aGF0IGFyZSBtb3JlIHZhcmllZCwgd2hpbGUg
YSB2YWx1ZSBjbG9zZXIgdG8gYDAuMGAKIHdpbGwgdHlwaWNhbGx5IHJlc3VsdCBpbiBsZXNz
IHN1cnByaXNpbmcgcmVzcG9uc2VzIGZyb20gdGhlIG1vZGVsLgogVGhpcyB2YWx1ZSBzcGVj
aWZpZXMgZGVmYXVsdCB0byBiZSB1c2VkIGJ5IHRoZSBiYWNrZW5kIHdoaWxlIG1ha2luZyB0
aGUKIGNhbGwgdG8gdGhlIG1vZGVsLgoKDAoFBAACCAQSA1YCCgoMCgUEAAIIBRIDVgsQCgwK
BQQAAggBEgNWERwKDAoFBAACCAMSA1YfIAo6CgQEAAIJEgNZAiYaLSBUaGUgbWF4aW11bSB0
ZW1wZXJhdHVyZSB0aGlzIG1vZGVsIGNhbiB1c2UuCgoMCgUEAAIJBBIDWQIKCgwKBQQAAgkF
EgNZCxAKDAoFBAACCQESA1kRIAoMCgUEAAIJAxIDWSMlCqsCCgQEAAIKEgNiAhwanQIgRm9y
IFtOdWNsZXVzCiBzYW1wbGluZ10oaHR0cHM6Ly9haS5nb29nbGUuZGV2L2dlbWluaS1hcGkv
ZG9jcy9wcm9tcHRpbmctc3RyYXRlZ2llcyN0b3AtcCkuCgogTnVjbGV1cyBzYW1wbGluZyBj
b25zaWRlcnMgdGhlIHNtYWxsZXN0IHNldCBvZiB0b2tlbnMgd2hvc2UgcHJvYmFiaWxpdHkK
IHN1bSBpcyBhdCBsZWFzdCBgdG9wX3BgLgogVGhpcyB2YWx1ZSBzcGVjaWZpZXMgZGVmYXVs
dCB0byBiZSB1c2VkIGJ5IHRoZSBiYWNrZW5kIHdoaWxlIG1ha2luZyB0aGUKIGNhbGwgdG8g
dGhlIG1vZGVsLgoKDAoFBAACCgQSA2ICCgoMCgUEAAIKBRIDYgsQCgwKBQQAAgoBEgNiERYK
DAoFBAACCgMSA2IZGwq1AgoEBAACCxIDawIcGqcCIEZvciBUb3AtayBzYW1wbGluZy4KCiBU
b3AtayBzYW1wbGluZyBjb25zaWRlcnMgdGhlIHNldCBvZiBgdG9wX2tgIG1vc3QgcHJvYmFi
bGUgdG9rZW5zLgogVGhpcyB2YWx1ZSBzcGVjaWZpZXMgZGVmYXVsdCB0byBiZSB1c2VkIGJ5
IHRoZSBiYWNrZW5kIHdoaWxlIG1ha2luZyB0aGUKIGNhbGwgdG8gdGhlIG1vZGVsLgogSWYg
ZW1wdHksIGluZGljYXRlcyB0aGUgbW9kZWwgZG9lc24ndCB1c2UgdG9wLWsgc2FtcGxpbmcs
IGFuZCBgdG9wX2tgIGlzbid0CiBhbGxvd2VkIGFzIGEgZ2VuZXJhdGlvbiBwYXJhbWV0ZXIu
CgoMCgUEAAILBBIDawIKCgwKBQQAAgsFEgNrCxAKDAoFBAACCwESA2sRFgoMCgUEAAILAxID
axkbCjMKBAQAAgwSA24CFRomIFdoZXRoZXIgdGhlIG1vZGVsIHN1cHBvcnRzIHRoaW5raW5n
LgoKDAoFBAACDAUSA24CBgoMCgUEAAIMARIDbgcPCgwKBQQAAgwDEgNuEhRiBnByb3RvMw==

EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Ai::Generativelanguage::V1beta::Model::Model ===
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

Google::Ai::Generativelanguage::V1beta::Model - Compiled Protocol Buffers messages for google/ai/generativelanguage/v1beta/model.proto

=head1 SYNOPSIS

    use Google::Ai::Generativelanguage::V1beta::Model;

    my $msg = Google::Ai::Generativelanguage::V1beta::Model::Model->new({
        name => $name,
        base_model_id => $base_model_id,
        version => $version,
        display_name => $display_name,
    });

    # Read or update a field
    my $val = $msg->name();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Ai::Generativelanguage::V1beta::Model::Model->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/ai/generativelanguage/v1beta/model.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Ai::Generativelanguage::V1beta::Model::Model

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

L<Protobuf>, L<Protobuf::Message>, L<Google::Ai::Generativelanguage::V1beta::Model::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
