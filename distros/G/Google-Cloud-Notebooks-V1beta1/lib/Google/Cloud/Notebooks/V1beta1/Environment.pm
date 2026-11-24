package Google::Cloud::Notebooks::V1beta1::Environment;

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
    eval { require Google::Protobuf::Timestamp };
    my $descriptor_b64 = <<'EOF';
CjBnb29nbGUvY2xvdWQvbm90ZWJvb2tzL3YxYmV0YTEvZW52aXJvbm1lbnQucHJvdG8SHmdv
b2dsZS5jbG91ZC5ub3RlYm9va3MudjFiZXRhMRofZ29vZ2xlL2FwaS9maWVsZF9iZWhhdmlv
ci5wcm90bxoZZ29vZ2xlL2FwaS9yZXNvdXJjZS5wcm90bxofZ29vZ2xlL3Byb3RvYnVmL3Rp
bWVzdGFtcC5wcm90byLmAwoLRW52aXJvbm1lbnQSFwoEbmFtZRgBIAEoCUID4EEDUgRuYW1l
EiEKDGRpc3BsYXlfbmFtZRgCIAEoCVILZGlzcGxheU5hbWUSIAoLZGVzY3JpcHRpb24YAyAB
KAlSC2Rlc2NyaXB0aW9uEkQKCHZtX2ltYWdlGAYgASgLMicuZ29vZ2xlLmNsb3VkLm5vdGVi
b29rcy52MWJldGExLlZtSW1hZ2VIAFIHdm1JbWFnZRJZCg9jb250YWluZXJfaW1hZ2UYByAB
KAsyLi5nb29nbGUuY2xvdWQubm90ZWJvb2tzLnYxYmV0YTEuQ29udGFpbmVySW1hZ2VIAFIO
Y29udGFpbmVySW1hZ2USLgoTcG9zdF9zdGFydHVwX3NjcmlwdBgIIAEoCVIRcG9zdFN0YXJ0
dXBTY3JpcHQSQAoLY3JlYXRlX3RpbWUYCSABKAsyGi5nb29nbGUucHJvdG9idWYuVGltZXN0
YW1wQgPgQQNSCmNyZWF0ZVRpbWU6WOpBVQokbm90ZWJvb2tzLmdvb2dsZWFwaXMuY29tL0Vu
dmlyb25tZW50Ei1wcm9qZWN0cy97cHJvamVjdH0vZW52aXJvbm1lbnRzL3tlbnZpcm9ubWVu
dH1CDAoKaW1hZ2VfdHlwZSJ3CgdWbUltYWdlEh0KB3Byb2plY3QYASABKAlCA+BBAlIHcHJv
amVjdBIfCgppbWFnZV9uYW1lGAIgASgJSABSCWltYWdlTmFtZRIjCgxpbWFnZV9mYW1pbHkY
AyABKAlIAFILaW1hZ2VGYW1pbHlCBwoFaW1hZ2UiRwoOQ29udGFpbmVySW1hZ2USIwoKcmVw
b3NpdG9yeRgBIAEoCUID4EECUgpyZXBvc2l0b3J5EhAKA3RhZxgCIAEoCVIDdGFnQuABCiJj
b20uZ29vZ2xlLmNsb3VkLm5vdGVib29rcy52MWJldGExQhBFbnZpcm9ubWVudFByb3RvUAFa
QGNsb3VkLmdvb2dsZS5jb20vZ28vbm90ZWJvb2tzL2FwaXYxYmV0YTEvbm90ZWJvb2tzcGI7
bm90ZWJvb2tzcGKqAh5Hb29nbGUuQ2xvdWQuTm90ZWJvb2tzLlYxQmV0YTHKAh5Hb29nbGVc
Q2xvdWRcTm90ZWJvb2tzXFYxYmV0YTHqAiFHb29nbGU6OkNsb3VkOjpOb3RlYm9va3M6OlYx
YmV0YTFKlRkKBhIEDgBfAQq8BAoBDBIDDgASMrEEIENvcHlyaWdodCAyMDI1IEdvb2dsZSBM
TEMKCiBMaWNlbnNlZCB1bmRlciB0aGUgQXBhY2hlIExpY2Vuc2UsIFZlcnNpb24gMi4wICh0
aGUgIkxpY2Vuc2UiKTsKIHlvdSBtYXkgbm90IHVzZSB0aGlzIGZpbGUgZXhjZXB0IGluIGNv
bXBsaWFuY2Ugd2l0aCB0aGUgTGljZW5zZS4KIFlvdSBtYXkgb2J0YWluIGEgY29weSBvZiB0
aGUgTGljZW5zZSBhdAoKICAgICBodHRwOi8vd3d3LmFwYWNoZS5vcmcvbGljZW5zZXMvTElD
RU5TRS0yLjAKCiBVbmxlc3MgcmVxdWlyZWQgYnkgYXBwbGljYWJsZSBsYXcgb3IgYWdyZWVk
IHRvIGluIHdyaXRpbmcsIHNvZnR3YXJlCiBkaXN0cmlidXRlZCB1bmRlciB0aGUgTGljZW5z
ZSBpcyBkaXN0cmlidXRlZCBvbiBhbiAiQVMgSVMiIEJBU0lTLAogV0lUSE9VVCBXQVJSQU5U
SUVTIE9SIENPTkRJVElPTlMgT0YgQU5ZIEtJTkQsIGVpdGhlciBleHByZXNzIG9yIGltcGxp
ZWQuCiBTZWUgdGhlIExpY2Vuc2UgZm9yIHRoZSBzcGVjaWZpYyBsYW5ndWFnZSBnb3Zlcm5p
bmcgcGVybWlzc2lvbnMgYW5kCiBsaW1pdGF0aW9ucyB1bmRlciB0aGUgTGljZW5zZS4KCggK
AQISAxAAJwoJCgIDABIDEgApCgkKAgMBEgMTACMKCQoCAwISAxQAKQoICgEIEgMWADsKCQoC
CCUSAxYAOwoICgEIEgMXAFcKCQoCCAsSAxcAVwoICgEIEgMYACIKCQoCCAoSAxgAIgoICgEI
EgMZADEKCQoCCAgSAxkAMQoICgEIEgMaADsKCQoCCAESAxoAOwoICgEIEgMbADsKCQoCCCkS
AxsAOwoICgEIEgMcADoKCQoCCC0SAxwAOgpeCgIEABIEIABBARpSIERlZmluaXRpb24gb2Yg
YSBzb2Z0d2FyZSBlbnZpcm9ubWVudCB0aGF0IGlzIHVzZWQgdG8gc3RhcnQgYSBub3RlYm9v
awogaW5zdGFuY2UuCgoKCgMEAAESAyAIEwoLCgMEAAcSBCECJAQKDQoFBAAHnQgSBCECJAQK
igEKBAQAAgASAykCPhp9IE91dHB1dCBvbmx5LiBOYW1lIG9mIHRoaXMgZW52aXJvbm1lbnQu
CiBGb3JtYXQ6CiBgcHJvamVjdHMve3Byb2plY3RfaWR9L2xvY2F0aW9ucy97bG9jYXRpb259
L2Vudmlyb25tZW50cy97ZW52aXJvbm1lbnRfaWR9YAoKDAoFBAACAAUSAykCCAoMCgUEAAIA
ARIDKQkNCgwKBQQAAgADEgMpEBEKDAoFBAACAAgSAykSPQoPCggEAAIACJwIABIDKRM8CjsK
BAQAAgESAywCGhouIERpc3BsYXkgbmFtZSBvZiB0aGlzIGVudmlyb25tZW50IGZvciB0aGUg
VUkuCgoMCgUEAAIBBRIDLAIICgwKBQQAAgEBEgMsCRUKDAoFBAACAQMSAywYGQo3CgQEAAIC
EgMvAhkaKiBBIGJyaWVmIGRlc2NyaXB0aW9uIG9mIHRoaXMgZW52aXJvbm1lbnQuCgoMCgUE
AAICBRIDLwIICgwKBQQAAgIBEgMvCRQKDAoFBAACAgMSAy8XGApUCgQEAAgAEgQyAjgDGkYg
VHlwZSBvZiB0aGUgZW52aXJvbm1lbnQ7IGNhbiBiZSBvbmUgb2YgVk0gaW1hZ2UsIG9yIGNv
bnRhaW5lciBpbWFnZS4KCgwKBQQACAABEgMyCBIKTAoEBAACAxIDNAQZGj8gVXNlIGEgQ29t
cHV0ZSBFbmdpbmUgVk0gaW1hZ2UgdG8gc3RhcnQgdGhlIG5vdGVib29rIGluc3RhbmNlLgoK
DAoFBAACAwYSAzQECwoMCgUEAAIDARIDNAwUCgwKBQQAAgMDEgM0FxgKRAoEBAACBBIDNwQn
GjcgVXNlIGEgY29udGFpbmVyIGltYWdlIHRvIHN0YXJ0IHRoZSBub3RlYm9vayBpbnN0YW5j
ZS4KCgwKBQQAAgQGEgM3BBIKDAoFBAACBAESAzcTIgoMCgUEAAIEAxIDNyUmCsABCgQEAAIF
EgM9AiEasgEgUGF0aCB0byBhIEJhc2ggc2NyaXB0IHRoYXQgYXV0b21hdGljYWxseSBydW5z
IGFmdGVyIGEgbm90ZWJvb2sgaW5zdGFuY2UKIGZ1bGx5IGJvb3RzIHVwLiBUaGUgcGF0aCBt
dXN0IGJlIGEgVVJMIG9yCiBDbG91ZCBTdG9yYWdlIHBhdGguIEV4YW1wbGU6IGAiZ3M6Ly9w
YXRoLXRvLWZpbGUvZmlsZS1uYW1lImAKCgwKBQQAAgUFEgM9AggKDAoFBAACBQESAz0JHAoM
CgUEAAIFAxIDPR8gCksKBAQAAgYSA0ACWBo+IE91dHB1dCBvbmx5LiBUaGUgdGltZSBhdCB3
aGljaCB0aGlzIGVudmlyb25tZW50IHdhcyBjcmVhdGVkLgoKDAoFBAACBgYSA0ACGwoMCgUE
AAIGARIDQBwnCgwKBQQAAgYDEgNAKisKDAoFBAACBggSA0AsVwoPCggEAAIGCJwIABIDQC1W
Cp8BCgIEARIERQBTARqSASBEZWZpbml0aW9uIG9mIGEgY3VzdG9tIENvbXB1dGUgRW5naW5l
IHZpcnR1YWwgbWFjaGluZSBpbWFnZSBmb3Igc3RhcnRpbmcgYQogbm90ZWJvb2sgaW5zdGFu
Y2Ugd2l0aCB0aGUgZW52aXJvbm1lbnQgaW5zdGFsbGVkIGRpcmVjdGx5IG9uIHRoZSBWTS4K
CgoKAwQBARIDRQgPCn0KBAQBAgASA0gCPhpwIFJlcXVpcmVkLiBUaGUgbmFtZSBvZiB0aGUg
R29vZ2xlIENsb3VkIHByb2plY3QgdGhhdCB0aGlzIFZNIGltYWdlIGJlbG9uZ3MgdG8uCiBG
b3JtYXQ6IGBwcm9qZWN0cy97cHJvamVjdF9pZH1gCgoMCgUEAQIABRIDSAIICgwKBQQBAgAB
EgNICRAKDAoFBAECAAMSA0gTFAoMCgUEAQIACBIDSBU9Cg8KCAQBAgAInAgAEgNIFjwKRQoE
BAEIABIESwJSAxo3IFRoZSByZWZlcmVuY2UgdG8gYW4gZXh0ZXJuYWwgQ29tcHV0ZSBFbmdp
bmUgVk0gaW1hZ2UuCgoMCgUEAQgAARIDSwgNCjMKBAQBAgESA00EGhomIFVzZSBWTSBpbWFn
ZSBuYW1lIHRvIGZpbmQgdGhlIGltYWdlLgoKDAoFBAECAQUSA00ECgoMCgUEAQIBARIDTQsV
CgwKBQQBAgEDEgNNGBkKaQoEBAECAhIDUQQcGlwgVXNlIHRoaXMgVk0gaW1hZ2UgZmFtaWx5
IHRvIGZpbmQgdGhlIGltYWdlOyB0aGUgbmV3ZXN0IGltYWdlIGluIHRoaXMKIGZhbWlseSB3
aWxsIGJlIHVzZWQuCgoMCgUEAQICBRIDUQQKCgwKBQQBAgIBEgNRCxcKDAoFBAECAgMSA1Ea
Gwp+CgIEAhIEVwBfARpyIERlZmluaXRpb24gb2YgYSBjb250YWluZXIgaW1hZ2UgZm9yIHN0
YXJ0aW5nIGEgbm90ZWJvb2sgaW5zdGFuY2Ugd2l0aCB0aGUKIGVudmlyb25tZW50IGluc3Rh
bGxlZCBpbiBhIGNvbnRhaW5lci4KCgoKAwQCARIDVwgWCnUKBAQCAgASA1oCQRpoIFJlcXVp
cmVkLiBUaGUgcGF0aCB0byB0aGUgY29udGFpbmVyIGltYWdlIHJlcG9zaXRvcnkuIEZvciBl
eGFtcGxlOgogYGdjci5pby97cHJvamVjdF9pZH0ve2ltYWdlX25hbWV9YAoKDAoFBAICAAUS
A1oCCAoMCgUEAgIAARIDWgkTCgwKBQQCAgADEgNaFhcKDAoFBAICAAgSA1oYQAoPCggEAgIA
CJwIABIDWhk/CmIKBAQCAgESA14CERpVIFRoZSB0YWcgb2YgdGhlIGNvbnRhaW5lciBpbWFn
ZS4gSWYgbm90IHNwZWNpZmllZCwgdGhpcyBkZWZhdWx0cwogdG8gdGhlIGxhdGVzdCB0YWcu
CgoMCgUEAgIBBRIDXgIICgwKBQQCAgEBEgNeCQwKDAoFBAICAQMSA14PEGIGcHJvdG8z
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Notebooks::V1beta1::Environment::Environment ===
    # Fields for Environment
    # Field: name Type: 9 ()
    # Field: display_name Type: 9 ()
    # Field: description Type: 9 ()
    # Field: vm_image Type: 11 (.google.cloud.notebooks.v1beta1.VmImage)
    # Field: container_image Type: 11 (.google.cloud.notebooks.v1beta1.ContainerImage)
    # Field: post_startup_script Type: 9 ()
    # Field: create_time Type: 11 (.google.protobuf.Timestamp)

# === Message: Google::Cloud::Notebooks::V1beta1::Environment::VmImage ===
    # Fields for VmImage
    # Field: project Type: 9 ()
    # Field: image_name Type: 9 ()
    # Field: image_family Type: 9 ()

# === Message: Google::Cloud::Notebooks::V1beta1::Environment::ContainerImage ===
    # Fields for ContainerImage
    # Field: repository Type: 9 ()
    # Field: tag Type: 9 ()

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Notebooks::V1beta1::Environment - Compiled Protocol Buffers messages for google/cloud/notebooks/v1beta1/environment.proto

=head1 SYNOPSIS

    use Google::Cloud::Notebooks::V1beta1::Environment;

    my $msg = Google::Cloud::Notebooks::V1beta1::Environment::Environment->new({
        name => $name,
        display_name => $display_name,
        description => $description,
        vm_image => $vm_image,
    });

    # Read or update a field
    my $val = $msg->name();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Notebooks::V1beta1::Environment::Environment->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/notebooks/v1beta1/environment.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Notebooks::V1beta1::Environment::Environment

Definition of a software environment that is used to start a notebook
instance.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Output only. Name of this environment.
Format:
`projects/{project_id}/locations/{location}/environments/{environment_id}`

=item * C<< $msg->display_name() >> / C<< $msg->display_name($value) >>

Type: C<String>

Display name of this environment for the UI.

=item * C<< $msg->description() >> / C<< $msg->description($value) >>

Type: C<String>

A brief description of this environment.

=item * C<< $msg->vm_image() >> / C<< $msg->vm_image($value) >>

Type: C<Message> (L<Google::Cloud::Notebooks::V1beta1::Environment::VmImage>)

Use a Compute Engine VM image to start the notebook instance.

=item * C<< $msg->container_image() >> / C<< $msg->container_image($value) >>

Type: C<Message> (L<Google::Cloud::Notebooks::V1beta1::Environment::ContainerImage>)

Use a container image to start the notebook instance.

=item * C<< $msg->post_startup_script() >> / C<< $msg->post_startup_script($value) >>

Type: C<String>

Path to a Bash script that automatically runs after a notebook instance
fully boots up. The path must be a URL or
Cloud Storage path. Example: `"gs://path-to-file/file-name"`

=item * C<< $msg->create_time() >> / C<< $msg->create_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Output only. The time at which this environment was created.

=back

=head2 Google::Cloud::Notebooks::V1beta1::Environment::VmImage

Definition of a custom Compute Engine virtual machine image for starting a
notebook instance with the environment installed directly on the VM.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->project() >> / C<< $msg->project($value) >>

Type: C<String>

Required. The name of the Google Cloud project that this VM image belongs to.
Format: `projects/{project_id}`

=item * C<< $msg->image_name() >> / C<< $msg->image_name($value) >>

Type: C<String>

Use VM image name to find the image.

=item * C<< $msg->image_family() >> / C<< $msg->image_family($value) >>

Type: C<String>

Use this VM image family to find the image; the newest image in this
family will be used.

=back

=head2 Google::Cloud::Notebooks::V1beta1::Environment::ContainerImage

Definition of a container image for starting a notebook instance with the
environment installed in a container.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->repository() >> / C<< $msg->repository($value) >>

Type: C<String>

Required. The path to the container image repository. For example:
`gcr.io/{project_id}/{image_name}`

=item * C<< $msg->tag() >> / C<< $msg->tag($value) >>

Type: C<String>

The tag of the container image. If not specified, this defaults
to the latest tag.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Notebooks::V1beta1::Environment::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
