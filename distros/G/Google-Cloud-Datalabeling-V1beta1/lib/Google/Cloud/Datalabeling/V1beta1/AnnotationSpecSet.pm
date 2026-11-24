package Google::Cloud::Datalabeling::V1beta1::AnnotationSpecSet;

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
Cjtnb29nbGUvY2xvdWQvZGF0YWxhYmVsaW5nL3YxYmV0YTEvYW5ub3RhdGlvbl9zcGVjX3Nl
dC5wcm90bxIhZ29vZ2xlLmNsb3VkLmRhdGFsYWJlbGluZy52MWJldGExGhlnb29nbGUvYXBp
L3Jlc291cmNlLnByb3RvIuoCChFBbm5vdGF0aW9uU3BlY1NldBISCgRuYW1lGAEgASgJUgRu
YW1lEiEKDGRpc3BsYXlfbmFtZRgCIAEoCVILZGlzcGxheU5hbWUSIAoLZGVzY3JpcHRpb24Y
AyABKAlSC2Rlc2NyaXB0aW9uElwKEGFubm90YXRpb25fc3BlY3MYBCADKAsyMS5nb29nbGUu
Y2xvdWQuZGF0YWxhYmVsaW5nLnYxYmV0YTEuQW5ub3RhdGlvblNwZWNSD2Fubm90YXRpb25T
cGVjcxItChJibG9ja2luZ19yZXNvdXJjZXMYBSADKAlSEWJsb2NraW5nUmVzb3VyY2VzOm/q
QWwKLWRhdGFsYWJlbGluZy5nb29nbGVhcGlzLmNvbS9Bbm5vdGF0aW9uU3BlY1NldBI7cHJv
amVjdHMve3Byb2plY3R9L2Fubm90YXRpb25TcGVjU2V0cy97YW5ub3RhdGlvbl9zcGVjX3Nl
dH0iVQoOQW5ub3RhdGlvblNwZWMSIQoMZGlzcGxheV9uYW1lGAEgASgJUgtkaXNwbGF5TmFt
ZRIgCgtkZXNjcmlwdGlvbhgCIAEoCVILZGVzY3JpcHRpb25C4wEKJWNvbS5nb29nbGUuY2xv
dWQuZGF0YWxhYmVsaW5nLnYxYmV0YTFQAVpJY2xvdWQuZ29vZ2xlLmNvbS9nby9kYXRhbGFi
ZWxpbmcvYXBpdjFiZXRhMS9kYXRhbGFiZWxpbmdwYjtkYXRhbGFiZWxpbmdwYqoCIUdvb2ds
ZS5DbG91ZC5EYXRhTGFiZWxpbmcuVjFCZXRhMcoCIUdvb2dsZVxDbG91ZFxEYXRhTGFiZWxp
bmdcVjFiZXRhMeoCJEdvb2dsZTo6Q2xvdWQ6OkRhdGFMYWJlbGluZzo6VjFiZXRhMUqoFAoG
EgQPAEYBCr0ECgEMEgMPABIysgQgQ29weXJpZ2h0IDIwMjUgR29vZ2xlIExMQwoKIExpY2Vu
c2VkIHVuZGVyIHRoZSBBcGFjaGUgTGljZW5zZSwgVmVyc2lvbiAyLjAgKHRoZSAiTGljZW5z
ZSIpOwogeW91IG1heSBub3QgdXNlIHRoaXMgZmlsZSBleGNlcHQgaW4gY29tcGxpYW5jZSB3
aXRoIHRoZSBMaWNlbnNlLgogWW91IG1heSBvYnRhaW4gYSBjb3B5IG9mIHRoZSBMaWNlbnNl
IGF0CgogICAgIGh0dHA6Ly93d3cuYXBhY2hlLm9yZy9saWNlbnNlcy9MSUNFTlNFLTIuMAoK
IFVubGVzcyByZXF1aXJlZCBieSBhcHBsaWNhYmxlIGxhdyBvciBhZ3JlZWQgdG8gaW4gd3Jp
dGluZywgc29mdHdhcmUKIGRpc3RyaWJ1dGVkIHVuZGVyIHRoZSBMaWNlbnNlIGlzIGRpc3Ry
aWJ1dGVkIG9uIGFuICJBUyBJUyIgQkFTSVMsCiBXSVRIT1VUIFdBUlJBTlRJRVMgT1IgQ09O
RElUSU9OUyBPRiBBTlkgS0lORCwgZWl0aGVyIGV4cHJlc3Mgb3IgaW1wbGllZC4KIFNlZSB0
aGUgTGljZW5zZSBmb3IgdGhlIHNwZWNpZmljIGxhbmd1YWdlIGdvdmVybmluZyBwZXJtaXNz
aW9ucyBhbmQKIGxpbWl0YXRpb25zIHVuZGVyIHRoZSBMaWNlbnNlLgoKCggKAQISAxEAKgoJ
CgIDABIDEwAjCggKAQgSAxUAPgoJCgIIJRIDFQA+CggKAQgSAxYAYAoJCgIICxIDFgBgCggK
AQgSAxcAIgoJCgIIChIDFwAiCggKAQgSAxgAPgoJCgIIARIDGAA+CggKAQgSAxkAPgoJCgII
KRIDGQA+CggKAQgSAxoAPQoJCgIILRIDGgA9CvABCgIEABIEHwA5ARrjASBBbiBBbm5vdGF0
aW9uU3BlY1NldCBpcyBhIGNvbGxlY3Rpb24gb2YgbGFiZWwgZGVmaW5pdGlvbnMuIEZvciBl
eGFtcGxlLCBpbgogaW1hZ2UgY2xhc3NpZmljYXRpb24gdGFza3MsIHlvdSBkZWZpbmUgYSBz
ZXQgb2YgcG9zc2libGUgbGFiZWxzIGZvciBpbWFnZXMgYXMKIGFuIEFubm90YXRpb25TcGVj
U2V0LiBBbiBBbm5vdGF0aW9uU3BlY1NldCBpcyBpbW11dGFibGUgdXBvbiBjcmVhdGlvbi4K
CgoKAwQAARIDHwgZCgsKAwQABxIEIAIjBAoNCgUEAAedCBIEIAIjBAq1AQoEBAACABIDKAIS
GqcBIE91dHB1dCBvbmx5LiBUaGUgQW5ub3RhdGlvblNwZWNTZXQgcmVzb3VyY2UgbmFtZSBp
biB0aGUgZm9sbG93aW5nIGZvcm1hdDoKCiAicHJvamVjdHMvPHZhcj57cHJvamVjdF9pZH08
L3Zhcj4vYW5ub3RhdGlvblNwZWNTZXRzLzx2YXI+e2Fubm90YXRpb25fc3BlY19zZXRfaWR9
PC92YXI+IgoKDAoFBAACAAUSAygCCAoMCgUEAAIAARIDKAkNCgwKBQQAAgADEgMoEBEKfgoE
BAACARIDLAIaGnEgUmVxdWlyZWQuIFRoZSBkaXNwbGF5IG5hbWUgZm9yIEFubm90YXRpb25T
cGVjU2V0IHRoYXQgeW91IGRlZmluZSB3aGVuIHlvdQogY3JlYXRlIGl0LiBNYXhpbXVtIG9m
IDY0IGNoYXJhY3RlcnMuCgoMCgUEAAIBBRIDLAIICgwKBQQAAgEBEgMsCRUKDAoFBAACAQMS
AywYGQqOAQoEBAACAhIDMAIZGoABIE9wdGlvbmFsLiBVc2VyLXByb3ZpZGVkIGRlc2NyaXB0
aW9uIG9mIHRoZSBhbm5vdGF0aW9uIHNwZWNpZmljYXRpb24gc2V0LgogVGhlIGRlc2NyaXB0
aW9uIGNhbiBiZSB1cCB0byAxMCwwMDAgY2hhcmFjdGVycyBsb25nLgoKDAoFBAACAgUSAzAC
CAoMCgUEAAICARIDMAkUCgwKBQQAAgIDEgMwFxgKowEKBAQAAgMSAzQCLxqVASBSZXF1aXJl
ZC4gVGhlIGFycmF5IG9mIEFubm90YXRpb25TcGVjcyB0aGF0IHlvdSBkZWZpbmUgd2hlbiB5
b3UgY3JlYXRlIHRoZQogQW5ub3RhdGlvblNwZWNTZXQuIFRoZXNlIGFyZSB0aGUgcG9zc2li
bGUgbGFiZWxzIGZvciB0aGUgbGFiZWxpbmcgdGFzay4KCgwKBQQAAgMEEgM0AgoKDAoFBAAC
AwYSAzQLGQoMCgUEAAIDARIDNBoqCgwKBQQAAgMDEgM0LS4KdQoEBAACBBIDOAIpGmggT3V0
cHV0IG9ubHkuIFRoZSBuYW1lcyBvZiBhbnkgcmVsYXRlZCByZXNvdXJjZXMgdGhhdCBhcmUg
YmxvY2tpbmcgY2hhbmdlcwogdG8gdGhlIGFubm90YXRpb24gc3BlYyBzZXQuCgoMCgUEAAIE
BBIDOAIKCgwKBQQAAgQFEgM4CxEKDAoFBAACBAESAzgSJAoMCgUEAAIEAxIDOCcoCpMCCgIE
ARIEPwBGARqGAiBDb250YWluZXIgb2YgaW5mb3JtYXRpb24gcmVsYXRlZCB0byBvbmUgcG9z
c2libGUgYW5ub3RhdGlvbiB0aGF0IGNhbiBiZSB1c2VkCiBpbiBhIGxhYmVsaW5nIHRhc2su
IEZvciBleGFtcGxlLCBhbiBpbWFnZSBjbGFzc2lmaWNhdGlvbiB0YXNrIHdoZXJlIGltYWdl
cwogYXJlIGxhYmVsZWQgYXMgYGRvZ2Agb3IgYGNhdGAgbXVzdCByZWZlcmVuY2UgYW4gQW5u
b3RhdGlvblNwZWMgZm9yIGBkb2dgIGFuZAogYW4gQW5ub3RhdGlvblNwZWMgZm9yIGBjYXRg
LgoKCgoDBAEBEgM/CBYKWgoEBAECABIDQQIaGk0gUmVxdWlyZWQuIFRoZSBkaXNwbGF5IG5h
bWUgb2YgdGhlIEFubm90YXRpb25TcGVjLiBNYXhpbXVtIG9mIDY0IGNoYXJhY3RlcnMuCgoM
CgUEAQIABRIDQQIICgwKBQQBAgABEgNBCRUKDAoFBAECAAMSA0EYGQqJAQoEBAECARIDRQIZ
GnwgT3B0aW9uYWwuIFVzZXItcHJvdmlkZWQgZGVzY3JpcHRpb24gb2YgdGhlIGFubm90YXRp
b24gc3BlY2lmaWNhdGlvbi4KIFRoZSBkZXNjcmlwdGlvbiBjYW4gYmUgdXAgdG8gMTAsMDAw
IGNoYXJhY3RlcnMgbG9uZy4KCgwKBQQBAgEFEgNFAggKDAoFBAECAQESA0UJFAoMCgUEAQIB
AxIDRRcYYgZwcm90bzM=
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Datalabeling::V1beta1::AnnotationSpecSet::AnnotationSpecSet ===
    # Fields for AnnotationSpecSet
    # Field: name Type: 9 ()
    # Field: display_name Type: 9 ()
    # Field: description Type: 9 ()
    # Field: annotation_specs Type: 11 (.google.cloud.datalabeling.v1beta1.AnnotationSpec)
    # Field: blocking_resources Type: 9 ()

# === Message: Google::Cloud::Datalabeling::V1beta1::AnnotationSpecSet::AnnotationSpec ===
    # Fields for AnnotationSpec
    # Field: display_name Type: 9 ()
    # Field: description Type: 9 ()

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Datalabeling::V1beta1::AnnotationSpecSet - Compiled Protocol Buffers messages for google/cloud/datalabeling/v1beta1/annotation_spec_set.proto

=head1 SYNOPSIS

    use Google::Cloud::Datalabeling::V1beta1::AnnotationSpecSet;

    my $msg = Google::Cloud::Datalabeling::V1beta1::AnnotationSpecSet::AnnotationSpecSet->new({
        name => $name,
        display_name => $display_name,
        description => $description,
        annotation_specs => $annotation_specs,
    });

    # Read or update a field
    my $val = $msg->name();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Datalabeling::V1beta1::AnnotationSpecSet::AnnotationSpecSet->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/datalabeling/v1beta1/annotation_spec_set.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Datalabeling::V1beta1::AnnotationSpecSet::AnnotationSpecSet

An AnnotationSpecSet is a collection of label definitions. For example, in
image classification tasks, you define a set of possible labels for images as
an AnnotationSpecSet. An AnnotationSpecSet is immutable upon creation.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Output only. The AnnotationSpecSet resource name in the following format:

"projects/<var>{project_id}</var>/annotationSpecSets/<var>{annotation_spec_set_id}</var>"

=item * C<< $msg->display_name() >> / C<< $msg->display_name($value) >>

Type: C<String>

Required. The display name for AnnotationSpecSet that you define when you
create it. Maximum of 64 characters.

=item * C<< $msg->description() >> / C<< $msg->description($value) >>

Type: C<String>

Optional. User-provided description of the annotation specification set.
The description can be up to 10,000 characters long.

=item * C<< $msg->annotation_specs() >> / C<< $msg->annotation_specs($value) >>

Type: C<Message> (L<Google::Cloud::Datalabeling::V1beta1::AnnotationSpecSet::AnnotationSpec>)

Required. The array of AnnotationSpecs that you define when you create the
AnnotationSpecSet. These are the possible labels for the labeling task.

=item * C<< $msg->blocking_resources() >> / C<< $msg->blocking_resources($value) >>

Type: C<String>

Output only. The names of any related resources that are blocking changes
to the annotation spec set.

=back

=head2 Google::Cloud::Datalabeling::V1beta1::AnnotationSpecSet::AnnotationSpec

Container of information related to one possible annotation that can be used
in a labeling task. For example, an image classification task where images
are labeled as `dog` or `cat` must reference an AnnotationSpec for `dog` and
an AnnotationSpec for `cat`.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->display_name() >> / C<< $msg->display_name($value) >>

Type: C<String>

Required. The display name of the AnnotationSpec. Maximum of 64 characters.

=item * C<< $msg->description() >> / C<< $msg->description($value) >>

Type: C<String>

Optional. User-provided description of the annotation specification.
The description can be up to 10,000 characters long.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Datalabeling::V1beta1::AnnotationSpecSet::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
