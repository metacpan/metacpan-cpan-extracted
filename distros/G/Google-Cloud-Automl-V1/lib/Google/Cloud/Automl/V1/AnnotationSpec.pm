package Google::Cloud::Automl::V1::AnnotationSpec;

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
Cixnb29nbGUvY2xvdWQvYXV0b21sL3YxL2Fubm90YXRpb25fc3BlYy5wcm90bxIWZ29vZ2xl
LmNsb3VkLmF1dG9tbC52MRoZZ29vZ2xlL2FwaS9yZXNvdXJjZS5wcm90byL3AQoOQW5ub3Rh
dGlvblNwZWMSEgoEbmFtZRgBIAEoCVIEbmFtZRIhCgxkaXNwbGF5X25hbWUYAiABKAlSC2Rp
c3BsYXlOYW1lEiMKDWV4YW1wbGVfY291bnQYCSABKAVSDGV4YW1wbGVDb3VudDqIAepBhAEK
JGF1dG9tbC5nb29nbGVhcGlzLmNvbS9Bbm5vdGF0aW9uU3BlYxJccHJvamVjdHMve3Byb2pl
Y3R9L2xvY2F0aW9ucy97bG9jYXRpb259L2RhdGFzZXRzL3tkYXRhc2V0fS9hbm5vdGF0aW9u
U3BlY3Mve2Fubm90YXRpb25fc3BlY31CoAEKGmNvbS5nb29nbGUuY2xvdWQuYXV0b21sLnYx
UAFaMmNsb3VkLmdvb2dsZS5jb20vZ28vYXV0b21sL2FwaXYxL2F1dG9tbHBiO2F1dG9tbHBi
qgIWR29vZ2xlLkNsb3VkLkF1dG9NTC5WMcoCFkdvb2dsZVxDbG91ZFxBdXRvTWxcVjHqAhlH
b29nbGU6OkNsb3VkOjpBdXRvTUw6OlYxSoELCgYSBA4ALgEKvAQKAQwSAw4AEjKxBCBDb3B5
cmlnaHQgMjAyNSBHb29nbGUgTExDCgogTGljZW5zZWQgdW5kZXIgdGhlIEFwYWNoZSBMaWNl
bnNlLCBWZXJzaW9uIDIuMCAodGhlICJMaWNlbnNlIik7CiB5b3UgbWF5IG5vdCB1c2UgdGhp
cyBmaWxlIGV4Y2VwdCBpbiBjb21wbGlhbmNlIHdpdGggdGhlIExpY2Vuc2UuCiBZb3UgbWF5
IG9idGFpbiBhIGNvcHkgb2YgdGhlIExpY2Vuc2UgYXQKCiAgICAgaHR0cDovL3d3dy5hcGFj
aGUub3JnL2xpY2Vuc2VzL0xJQ0VOU0UtMi4wCgogVW5sZXNzIHJlcXVpcmVkIGJ5IGFwcGxp
Y2FibGUgbGF3IG9yIGFncmVlZCB0byBpbiB3cml0aW5nLCBzb2Z0d2FyZQogZGlzdHJpYnV0
ZWQgdW5kZXIgdGhlIExpY2Vuc2UgaXMgZGlzdHJpYnV0ZWQgb24gYW4gIkFTIElTIiBCQVNJ
UywKIFdJVEhPVVQgV0FSUkFOVElFUyBPUiBDT05ESVRJT05TIE9GIEFOWSBLSU5ELCBlaXRo
ZXIgZXhwcmVzcyBvciBpbXBsaWVkLgogU2VlIHRoZSBMaWNlbnNlIGZvciB0aGUgc3BlY2lm
aWMgbGFuZ3VhZ2UgZ292ZXJuaW5nIHBlcm1pc3Npb25zIGFuZAogbGltaXRhdGlvbnMgdW5k
ZXIgdGhlIExpY2Vuc2UuCgoICgECEgMQAB8KCQoCAwASAxIAIwoICgEIEgMUADMKCQoCCCUS
AxQAMwoICgEIEgMVAEkKCQoCCAsSAxUASQoICgEIEgMWACIKCQoCCAoSAxYAIgoICgEIEgMX
ADMKCQoCCAESAxcAMwoICgEIEgMYADMKCQoCCCkSAxgAMwoICgEIEgMZADIKCQoCCC0SAxkA
MgoxCgIEABIEHAAuARolIEEgZGVmaW5pdGlvbiBvZiBhbiBhbm5vdGF0aW9uIHNwZWMuCgoK
CgMEAAESAxwIFgoLCgMEAAcSBB0CIAQKDQoFBAAHnQgSBB0CIAQKtQEKBAQAAgASAyUCEhqn
ASBPdXRwdXQgb25seS4gUmVzb3VyY2UgbmFtZSBvZiB0aGUgYW5ub3RhdGlvbiBzcGVjLgog
Rm9ybToKICdwcm9qZWN0cy97cHJvamVjdF9pZH0vbG9jYXRpb25zL3tsb2NhdGlvbl9pZH0v
ZGF0YXNldHMve2RhdGFzZXRfaWR9L2Fubm90YXRpb25TcGVjcy97YW5ub3RhdGlvbl9zcGVj
X2lkfScKCgwKBQQAAgAFEgMlAggKDAoFBAACAAESAyUJDQoMCgUEAAIAAxIDJRARCqgBCgQE
AAIBEgMpAhoamgEgUmVxdWlyZWQuIFRoZSBuYW1lIG9mIHRoZSBhbm5vdGF0aW9uIHNwZWMg
dG8gc2hvdyBpbiB0aGUgaW50ZXJmYWNlLiBUaGUgbmFtZSBjYW4gYmUKIHVwIHRvIDMyIGNo
YXJhY3RlcnMgbG9uZyBhbmQgbXVzdCBtYXRjaCB0aGUgcmVnZXhwIGBbYS16QS1aMC05X10r
YC4KCgwKBQQAAgEFEgMpAggKDAoFBAACAQESAykJFQoMCgUEAAIBAxIDKRgZCmkKBAQAAgIS
Ay0CGhpcIE91dHB1dCBvbmx5LiBUaGUgbnVtYmVyIG9mIGV4YW1wbGVzIGluIHRoZSBwYXJl
bnQgZGF0YXNldAogbGFiZWxlZCBieSB0aGUgYW5ub3RhdGlvbiBzcGVjLgoKDAoFBAACAgUS
Ay0CBwoMCgUEAAICARIDLQgVCgwKBQQAAgIDEgMtGBliBnByb3RvMw==
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Automl::V1::AnnotationSpec::AnnotationSpec ===
    # Fields for AnnotationSpec
    # Field: name Type: 9 ()
    # Field: display_name Type: 9 ()
    # Field: example_count Type: 5 ()

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Automl::V1::AnnotationSpec - Compiled Protocol Buffers messages for google/cloud/automl/v1/annotation_spec.proto

=head1 SYNOPSIS

    use Google::Cloud::Automl::V1::AnnotationSpec;

    my $msg = Google::Cloud::Automl::V1::AnnotationSpec::AnnotationSpec->new({
        name => $name,
        display_name => $display_name,
        example_count => $example_count,
    });

    # Read or update a field
    my $val = $msg->name();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Automl::V1::AnnotationSpec::AnnotationSpec->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/automl/v1/annotation_spec.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Automl::V1::AnnotationSpec::AnnotationSpec

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

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Automl::V1::AnnotationSpec::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
