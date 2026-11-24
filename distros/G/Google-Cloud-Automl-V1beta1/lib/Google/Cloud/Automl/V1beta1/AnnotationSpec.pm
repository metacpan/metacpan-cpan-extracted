package Google::Cloud::Automl::V1beta1::AnnotationSpec;

use strict;
use warnings;

our $VERSION = '0.14';

use Protobuf::Message;
use Protobuf::DescriptorPool;
use Protobuf::Internal qw(:all);
use MIME::Base64;

BEGIN {
    eval { require Google::Api::Resource };
    my $descriptor_b64 = <<'EOF';
CjFnb29nbGUvY2xvdWQvYXV0b21sL3YxYmV0YTEvYW5ub3RhdGlvbl9zcGVjLnByb3RvEhtn
b29nbGUuY2xvdWQuYXV0b21sLnYxYmV0YTEaGWdvb2dsZS9hcGkvcmVzb3VyY2UucHJvdG8i
9wEKDkFubm90YXRpb25TcGVjEhIKBG5hbWUYASABKAlSBG5hbWUSIQoMZGlzcGxheV9uYW1l
GAIgASgJUgtkaXNwbGF5TmFtZRIjCg1leGFtcGxlX2NvdW50GAkgASgFUgxleGFtcGxlQ291
bnQ6iAHqQYQBCiRhdXRvbWwuZ29vZ2xlYXBpcy5jb20vQW5ub3RhdGlvblNwZWMSXHByb2pl
Y3RzL3twcm9qZWN0fS9sb2NhdGlvbnMve2xvY2F0aW9ufS9kYXRhc2V0cy97ZGF0YXNldH0v
YW5ub3RhdGlvblNwZWNzL3thbm5vdGF0aW9uX3NwZWN9QpsBCh9jb20uZ29vZ2xlLmNsb3Vk
LmF1dG9tbC52MWJldGExUAFaN2Nsb3VkLmdvb2dsZS5jb20vZ28vYXV0b21sL2FwaXYxYmV0
YTEvYXV0b21scGI7YXV0b21scGLKAhtHb29nbGVcQ2xvdWRcQXV0b01sXFYxYmV0YTHqAh5H
b29nbGU6OkNsb3VkOjpBdXRvTUw6OlYxYmV0YTFK7QoKBhIEDgAuAQq8BAoBDBIDDgASMrEE
IENvcHlyaWdodCAyMDI1IEdvb2dsZSBMTEMKCiBMaWNlbnNlZCB1bmRlciB0aGUgQXBhY2hl
IExpY2Vuc2UsIFZlcnNpb24gMi4wICh0aGUgIkxpY2Vuc2UiKTsKIHlvdSBtYXkgbm90IHVz
ZSB0aGlzIGZpbGUgZXhjZXB0IGluIGNvbXBsaWFuY2Ugd2l0aCB0aGUgTGljZW5zZS4KIFlv
dSBtYXkgb2J0YWluIGEgY29weSBvZiB0aGUgTGljZW5zZSBhdAoKICAgICBodHRwOi8vd3d3
LmFwYWNoZS5vcmcvbGljZW5zZXMvTElDRU5TRS0yLjAKCiBVbmxlc3MgcmVxdWlyZWQgYnkg
YXBwbGljYWJsZSBsYXcgb3IgYWdyZWVkIHRvIGluIHdyaXRpbmcsIHNvZnR3YXJlCiBkaXN0
cmlidXRlZCB1bmRlciB0aGUgTGljZW5zZSBpcyBkaXN0cmlidXRlZCBvbiBhbiAiQVMgSVMi
IEJBU0lTLAogV0lUSE9VVCBXQVJSQU5USUVTIE9SIENPTkRJVElPTlMgT0YgQU5ZIEtJTkQs
IGVpdGhlciBleHByZXNzIG9yIGltcGxpZWQuCiBTZWUgdGhlIExpY2Vuc2UgZm9yIHRoZSBz
cGVjaWZpYyBsYW5ndWFnZSBnb3Zlcm5pbmcgcGVybWlzc2lvbnMgYW5kCiBsaW1pdGF0aW9u
cyB1bmRlciB0aGUgTGljZW5zZS4KCggKAQISAxAAJAoJCgIDABIDEgAjCggKAQgSAxQATgoJ
CgIICxIDFABOCggKAQgSAxUAIgoJCgIIChIDFQAiCggKAQgSAxYAOAoJCgIIARIDFgA4CggK
AQgSAxcAOAoJCgIIKRIDFwA4CggKAQgSAxgANwoJCgIILRIDGAA3CjEKAgQAEgQbAC4BGiUg
QSBkZWZpbml0aW9uIG9mIGFuIGFubm90YXRpb24gc3BlYy4KCgoKAwQAARIDGwgWCgsKAwQA
BxIEHAIfBAoNCgUEAAedCBIEHAIfBAq2AQoEBAACABIDJQISGqgBIE91dHB1dCBvbmx5LiBS
ZXNvdXJjZSBuYW1lIG9mIHRoZSBhbm5vdGF0aW9uIHNwZWMuCiBGb3JtOgoKICdwcm9qZWN0
cy97cHJvamVjdF9pZH0vbG9jYXRpb25zL3tsb2NhdGlvbl9pZH0vZGF0YXNldHMve2RhdGFz
ZXRfaWR9L2Fubm90YXRpb25TcGVjcy97YW5ub3RhdGlvbl9zcGVjX2lkfScKCgwKBQQAAgAF
EgMlAggKDAoFBAACAAESAyUJDQoMCgUEAAIAAxIDJRARCqgBCgQEAAIBEgMpAhoamgEgUmVx
dWlyZWQuIFRoZSBuYW1lIG9mIHRoZSBhbm5vdGF0aW9uIHNwZWMgdG8gc2hvdyBpbiB0aGUg
aW50ZXJmYWNlLiBUaGUgbmFtZSBjYW4gYmUKIHVwIHRvIDMyIGNoYXJhY3RlcnMgbG9uZyBh
bmQgbXVzdCBtYXRjaCB0aGUgcmVnZXhwIGBbYS16QS1aMC05X10rYC4KCgwKBQQAAgEFEgMp
AggKDAoFBAACAQESAykJFQoMCgUEAAIBAxIDKRgZCmkKBAQAAgISAy0CGhpcIE91dHB1dCBv
bmx5LiBUaGUgbnVtYmVyIG9mIGV4YW1wbGVzIGluIHRoZSBwYXJlbnQgZGF0YXNldAogbGFi
ZWxlZCBieSB0aGUgYW5ub3RhdGlvbiBzcGVjLgoKDAoFBAACAgUSAy0CBwoMCgUEAAICARID
LQgVCgwKBQQAAgIDEgMtGBliBnByb3RvMw==
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Automl::V1beta1::AnnotationSpec::AnnotationSpec ===
    # Fields for AnnotationSpec
    # Field: name Type: 9 ()
    # Field: display_name Type: 9 ()
    # Field: example_count Type: 5 ()

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Automl::V1beta1::AnnotationSpec - Compiled Protocol Buffers messages for google/cloud/automl/v1beta1/annotation_spec.proto

=head1 SYNOPSIS

    use Google::Cloud::Automl::V1beta1::AnnotationSpec;

    my $msg = Google::Cloud::Automl::V1beta1::AnnotationSpec::AnnotationSpec->new({
        name => $name,
        display_name => $display_name,
        example_count => $example_count,
    });

    # Read or update a field
    my $val = $msg->name();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Automl::V1beta1::AnnotationSpec::AnnotationSpec->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/automl/v1beta1/annotation_spec.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Automl::V1beta1::AnnotationSpec::AnnotationSpec

A definition of an annotation spec.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Output only. Resource name of the annotation spec.
Form:

'projects/{project_id}/locations/{location_id}/datasets/{dataset_id}/annotationSpecs/{annotation_spec_id}'

=item * C<< $msg->display_name() >> / C<< $msg->display_name($value) >>

Type: C<String>

Required. The name of the annotation spec to show in the interface. The name can be
up to 32 characters long and must match the regexp `[a-zA-Z0-9_]+`.

=item * C<< $msg->example_count() >> / C<< $msg->example_count($value) >>

Type: C<Int32>

Output only. The number of examples in the parent dataset
labeled by the annotation spec.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Automl::V1beta1::AnnotationSpec::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
