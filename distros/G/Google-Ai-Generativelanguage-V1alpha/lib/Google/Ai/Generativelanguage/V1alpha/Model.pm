package Google::Ai::Generativelanguage::V1alpha::Model;

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
CjBnb29nbGUvYWkvZ2VuZXJhdGl2ZWxhbmd1YWdlL3YxYWxwaGEvbW9kZWwucHJvdG8SJGdv
b2dsZS5haS5nZW5lcmF0aXZlbGFuZ3VhZ2UudjFhbHBoYRofZ29vZ2xlL2FwaS9maWVsZF9i
ZWhhdmlvci5wcm90bxoZZ29vZ2xlL2FwaS9yZXNvdXJjZS5wcm90byLIBAoFTW9kZWwSFwoE
bmFtZRgBIAEoCUID4EECUgRuYW1lEicKDWJhc2VfbW9kZWxfaWQYAiABKAlCA+BBAlILYmFz
ZU1vZGVsSWQSHQoHdmVyc2lvbhgDIAEoCUID4EECUgd2ZXJzaW9uEiEKDGRpc3BsYXlfbmFt
ZRgEIAEoCVILZGlzcGxheU5hbWUSIAoLZGVzY3JpcHRpb24YBSABKAlSC2Rlc2NyaXB0aW9u
EioKEWlucHV0X3Rva2VuX2xpbWl0GAYgASgFUg9pbnB1dFRva2VuTGltaXQSLAoSb3V0cHV0
X3Rva2VuX2xpbWl0GAcgASgFUhBvdXRwdXRUb2tlbkxpbWl0EkAKHHN1cHBvcnRlZF9nZW5l
cmF0aW9uX21ldGhvZHMYCCADKAlSGnN1cHBvcnRlZEdlbmVyYXRpb25NZXRob2RzEiUKC3Rl
bXBlcmF0dXJlGAkgASgCSABSC3RlbXBlcmF0dXJliAEBEiwKD21heF90ZW1wZXJhdHVyZRgN
IAEoAkgBUg5tYXhUZW1wZXJhdHVyZYgBARIYCgV0b3BfcBgKIAEoAkgCUgR0b3BQiAEBEhgK
BXRvcF9rGAsgASgFSANSBHRvcEuIAQE6POpBOQonZ2VuZXJhdGl2ZWxhbmd1YWdlLmdvb2ds
ZWFwaXMuY29tL01vZGVsEg5tb2RlbHMve21vZGVsfUIOCgxfdGVtcGVyYXR1cmVCEgoQX21h
eF90ZW1wZXJhdHVyZUIICgZfdG9wX3BCCAoGX3RvcF9rQpgBCihjb20uZ29vZ2xlLmFpLmdl
bmVyYXRpdmVsYW5ndWFnZS52MWFscGhhQgpNb2RlbFByb3RvUAFaXmNsb3VkLmdvb2dsZS5j
b20vZ28vYWkvZ2VuZXJhdGl2ZWxhbmd1YWdlL2FwaXYxYWxwaGEvZ2VuZXJhdGl2ZWxhbmd1
YWdlcGI7Z2VuZXJhdGl2ZWxhbmd1YWdlcGJKphwKBhIEDgBsAQq8BAoBDBIDDgASMrEEIENv
cHlyaWdodCAyMDI1IEdvb2dsZSBMTEMKCiBMaWNlbnNlZCB1bmRlciB0aGUgQXBhY2hlIExp
Y2Vuc2UsIFZlcnNpb24gMi4wICh0aGUgIkxpY2Vuc2UiKTsKIHlvdSBtYXkgbm90IHVzZSB0
aGlzIGZpbGUgZXhjZXB0IGluIGNvbXBsaWFuY2Ugd2l0aCB0aGUgTGljZW5zZS4KIFlvdSBt
YXkgb2J0YWluIGEgY29weSBvZiB0aGUgTGljZW5zZSBhdAoKICAgICBodHRwOi8vd3d3LmFw
YWNoZS5vcmcvbGljZW5zZXMvTElDRU5TRS0yLjAKCiBVbmxlc3MgcmVxdWlyZWQgYnkgYXBw
bGljYWJsZSBsYXcgb3IgYWdyZWVkIHRvIGluIHdyaXRpbmcsIHNvZnR3YXJlCiBkaXN0cmli
dXRlZCB1bmRlciB0aGUgTGljZW5zZSBpcyBkaXN0cmlidXRlZCBvbiBhbiAiQVMgSVMiIEJB
U0lTLAogV0lUSE9VVCBXQVJSQU5USUVTIE9SIENPTkRJVElPTlMgT0YgQU5ZIEtJTkQsIGVp
dGhlciBleHByZXNzIG9yIGltcGxpZWQuCiBTZWUgdGhlIExpY2Vuc2UgZm9yIHRoZSBzcGVj
aWZpYyBsYW5ndWFnZSBnb3Zlcm5pbmcgcGVybWlzc2lvbnMgYW5kCiBsaW1pdGF0aW9ucyB1
bmRlciB0aGUgTGljZW5zZS4KCggKAQISAxAALQoJCgIDABIDEgApCgkKAgMBEgMTACMKCAoB
CBIDFQB1CgkKAggLEgMVAHUKCAoBCBIDFgAiCgkKAggKEgMWACIKCAoBCBIDFwArCgkKAggI
EgMXACsKCAoBCBIDGABBCgkKAggBEgMYAEEKPAoCBAASBBsAbAEaMCBJbmZvcm1hdGlvbiBh
Ym91dCBhIEdlbmVyYXRpdmUgTGFuZ3VhZ2UgTW9kZWwuCgoKCgMEAAESAxsIDQoLCgMEAAcS
BBwCHwQKDQoFBAAHnQgSBBwCHwQKxQIKBAQAAgASAywCOxq3AiBSZXF1aXJlZC4gVGhlIHJl
c291cmNlIG5hbWUgb2YgdGhlIGBNb2RlbGAuIFJlZmVyIHRvIFtNb2RlbAogdmFyaWFudHNd
KGh0dHBzOi8vYWkuZ29vZ2xlLmRldi9nZW1pbmktYXBpL2RvY3MvbW9kZWxzL2dlbWluaSNt
b2RlbC12YXJpYXRpb25zKQogZm9yIGFsbCBhbGxvd2VkIHZhbHVlcy4KCiBGb3JtYXQ6IGBt
b2RlbHMve21vZGVsfWAgd2l0aCBhIGB7bW9kZWx9YCBuYW1pbmcgY29udmVudGlvbiBvZjoK
CiAqICJ7YmFzZV9tb2RlbF9pZH0te3ZlcnNpb259IgoKIEV4YW1wbGVzOgoKICogYG1vZGVs
cy9nZW1pbmktMS41LWZsYXNoLTAwMWAKCgwKBQQAAgAFEgMsAggKDAoFBAACAAESAywJDQoM
CgUEAAIAAxIDLBARCgwKBQQAAgAIEgMsEjoKDwoIBAACAAicCAASAywTOQp8CgQEAAIBEgMz
AkQabyBSZXF1aXJlZC4gVGhlIG5hbWUgb2YgdGhlIGJhc2UgbW9kZWwsIHBhc3MgdGhpcyB0
byB0aGUgZ2VuZXJhdGlvbiByZXF1ZXN0LgoKIEV4YW1wbGVzOgoKICogYGdlbWluaS0xLjUt
Zmxhc2hgCgoMCgUEAAIBBRIDMwIICgwKBQQAAgEBEgMzCRYKDAoFBAACAQMSAzMZGgoMCgUE
AAIBCBIDMxtDCg8KCAQAAgEInAgAEgMzHEIKbgoEBAACAhIDOAI+GmEgUmVxdWlyZWQuIFRo
ZSB2ZXJzaW9uIG51bWJlciBvZiB0aGUgbW9kZWwuCgogVGhpcyByZXByZXNlbnRzIHRoZSBt
YWpvciB2ZXJzaW9uIChgMS4wYCBvciBgMS41YCkKCgwKBQQAAgIFEgM4AggKDAoFBAACAgES
AzgJEAoMCgUEAAICAxIDOBMUCgwKBQQAAgIIEgM4FT0KDwoIBAACAgicCAASAzgWPAqkAQoE
BAACAxIDPgIaGpYBIFRoZSBodW1hbi1yZWFkYWJsZSBuYW1lIG9mIHRoZSBtb2RlbC4gRS5n
LiAiR2VtaW5pIDEuNSBGbGFzaCIuCgogVGhlIG5hbWUgY2FuIGJlIHVwIHRvIDEyOCBjaGFy
YWN0ZXJzIGxvbmcgYW5kIGNhbiBjb25zaXN0IG9mIGFueSBVVEYtOAogY2hhcmFjdGVycy4K
CgwKBQQAAgMFEgM+AggKDAoFBAACAwESAz4JFQoMCgUEAAIDAxIDPhgZCjAKBAQAAgQSA0EC
GRojIEEgc2hvcnQgZGVzY3JpcHRpb24gb2YgdGhlIG1vZGVsLgoKDAoFBAACBAUSA0ECCAoM
CgUEAAIEARIDQQkUCgwKBQQAAgQDEgNBFxgKRQoEBAACBRIDRAIeGjggTWF4aW11bSBudW1i
ZXIgb2YgaW5wdXQgdG9rZW5zIGFsbG93ZWQgZm9yIHRoaXMgbW9kZWwuCgoMCgUEAAIFBRID
RAIHCgwKBQQAAgUBEgNECBkKDAoFBAACBQMSA0QcHQpICgQEAAIGEgNHAh8aOyBNYXhpbXVt
IG51bWJlciBvZiBvdXRwdXQgdG9rZW5zIGF2YWlsYWJsZSBmb3IgdGhpcyBtb2RlbC4KCgwK
BQQAAgYFEgNHAgcKDAoFBAACBgESA0cIGgoMCgUEAAIGAxIDRx0eCrQBCgQEAAIHEgNNAjMa
pgEgVGhlIG1vZGVsJ3Mgc3VwcG9ydGVkIGdlbmVyYXRpb24gbWV0aG9kcy4KCiBUaGUgY29y
cmVzcG9uZGluZyBBUEkgbWV0aG9kIG5hbWVzIGFyZSBkZWZpbmVkIGFzIFBhc2NhbCBjYXNl
CiBzdHJpbmdzLCBzdWNoIGFzIGBnZW5lcmF0ZU1lc3NhZ2VgIGFuZCBgZ2VuZXJhdGVDb250
ZW50YC4KCgwKBQQAAgcEEgNNAgoKDAoFBAACBwUSA00LEQoMCgUEAAIHARIDTRIuCgwKBQQA
AgcDEgNNMTIK7gIKBAQAAggSA1YCIRrgAiBDb250cm9scyB0aGUgcmFuZG9tbmVzcyBvZiB0
aGUgb3V0cHV0LgoKIFZhbHVlcyBjYW4gcmFuZ2Ugb3ZlciBgWzAuMCxtYXhfdGVtcGVyYXR1
cmVdYCwgaW5jbHVzaXZlLiBBIGhpZ2hlciB2YWx1ZQogd2lsbCBwcm9kdWNlIHJlc3BvbnNl
cyB0aGF0IGFyZSBtb3JlIHZhcmllZCwgd2hpbGUgYSB2YWx1ZSBjbG9zZXIgdG8gYDAuMGAK
IHdpbGwgdHlwaWNhbGx5IHJlc3VsdCBpbiBsZXNzIHN1cnByaXNpbmcgcmVzcG9uc2VzIGZy
b20gdGhlIG1vZGVsLgogVGhpcyB2YWx1ZSBzcGVjaWZpZXMgZGVmYXVsdCB0byBiZSB1c2Vk
IGJ5IHRoZSBiYWNrZW5kIHdoaWxlIG1ha2luZyB0aGUKIGNhbGwgdG8gdGhlIG1vZGVsLgoK
DAoFBAACCAQSA1YCCgoMCgUEAAIIBRIDVgsQCgwKBQQAAggBEgNWERwKDAoFBAACCAMSA1Yf
IAo6CgQEAAIJEgNZAiYaLSBUaGUgbWF4aW11bSB0ZW1wZXJhdHVyZSB0aGlzIG1vZGVsIGNh
biB1c2UuCgoMCgUEAAIJBBIDWQIKCgwKBQQAAgkFEgNZCxAKDAoFBAACCQESA1kRIAoMCgUE
AAIJAxIDWSMlCqsCCgQEAAIKEgNiAhwanQIgRm9yIFtOdWNsZXVzCiBzYW1wbGluZ10oaHR0
cHM6Ly9haS5nb29nbGUuZGV2L2dlbWluaS1hcGkvZG9jcy9wcm9tcHRpbmctc3RyYXRlZ2ll
cyN0b3AtcCkuCgogTnVjbGV1cyBzYW1wbGluZyBjb25zaWRlcnMgdGhlIHNtYWxsZXN0IHNl
dCBvZiB0b2tlbnMgd2hvc2UgcHJvYmFiaWxpdHkKIHN1bSBpcyBhdCBsZWFzdCBgdG9wX3Bg
LgogVGhpcyB2YWx1ZSBzcGVjaWZpZXMgZGVmYXVsdCB0byBiZSB1c2VkIGJ5IHRoZSBiYWNr
ZW5kIHdoaWxlIG1ha2luZyB0aGUKIGNhbGwgdG8gdGhlIG1vZGVsLgoKDAoFBAACCgQSA2IC
CgoMCgUEAAIKBRIDYgsQCgwKBQQAAgoBEgNiERYKDAoFBAACCgMSA2IZGwq1AgoEBAACCxID
awIcGqcCIEZvciBUb3AtayBzYW1wbGluZy4KCiBUb3AtayBzYW1wbGluZyBjb25zaWRlcnMg
dGhlIHNldCBvZiBgdG9wX2tgIG1vc3QgcHJvYmFibGUgdG9rZW5zLgogVGhpcyB2YWx1ZSBz
cGVjaWZpZXMgZGVmYXVsdCB0byBiZSB1c2VkIGJ5IHRoZSBiYWNrZW5kIHdoaWxlIG1ha2lu
ZyB0aGUKIGNhbGwgdG8gdGhlIG1vZGVsLgogSWYgZW1wdHksIGluZGljYXRlcyB0aGUgbW9k
ZWwgZG9lc24ndCB1c2UgdG9wLWsgc2FtcGxpbmcsIGFuZCBgdG9wX2tgIGlzbid0CiBhbGxv
d2VkIGFzIGEgZ2VuZXJhdGlvbiBwYXJhbWV0ZXIuCgoMCgUEAAILBBIDawIKCgwKBQQAAgsF
EgNrCxAKDAoFBAACCwESA2sRFgoMCgUEAAILAxIDaxkbYgZwcm90bzM=
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Ai::Generativelanguage::V1alpha::Model::Model ===
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

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Ai::Generativelanguage::V1alpha::Model - Compiled Protocol Buffers messages for google/ai/generativelanguage/v1alpha/model.proto

=head1 SYNOPSIS

    use Google::Ai::Generativelanguage::V1alpha::Model;

    my $msg = Google::Ai::Generativelanguage::V1alpha::Model::Model->new({
        name => $name,
        base_model_id => $base_model_id,
        version => $version,
        display_name => $display_name,
    });

    # Read or update a field
    my $val = $msg->name();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Ai::Generativelanguage::V1alpha::Model::Model->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/ai/generativelanguage/v1alpha/model.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Ai::Generativelanguage::V1alpha::Model::Model

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

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Ai::Generativelanguage::V1alpha::Model::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
