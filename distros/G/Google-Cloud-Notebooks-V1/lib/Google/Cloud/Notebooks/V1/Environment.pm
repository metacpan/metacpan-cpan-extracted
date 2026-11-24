package Google::Cloud::Notebooks::V1::Environment;

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
Citnb29nbGUvY2xvdWQvbm90ZWJvb2tzL3YxL2Vudmlyb25tZW50LnByb3RvEhlnb29nbGUu
Y2xvdWQubm90ZWJvb2tzLnYxGh9nb29nbGUvYXBpL2ZpZWxkX2JlaGF2aW9yLnByb3RvGhln
b29nbGUvYXBpL3Jlc291cmNlLnByb3RvGh9nb29nbGUvcHJvdG9idWYvdGltZXN0YW1wLnBy
b3RvItwDCgtFbnZpcm9ubWVudBIXCgRuYW1lGAEgASgJQgPgQQNSBG5hbWUSIQoMZGlzcGxh
eV9uYW1lGAIgASgJUgtkaXNwbGF5TmFtZRIgCgtkZXNjcmlwdGlvbhgDIAEoCVILZGVzY3Jp
cHRpb24SPwoIdm1faW1hZ2UYBiABKAsyIi5nb29nbGUuY2xvdWQubm90ZWJvb2tzLnYxLlZt
SW1hZ2VIAFIHdm1JbWFnZRJUCg9jb250YWluZXJfaW1hZ2UYByABKAsyKS5nb29nbGUuY2xv
dWQubm90ZWJvb2tzLnYxLkNvbnRhaW5lckltYWdlSABSDmNvbnRhaW5lckltYWdlEi4KE3Bv
c3Rfc3RhcnR1cF9zY3JpcHQYCCABKAlSEXBvc3RTdGFydHVwU2NyaXB0EkAKC2NyZWF0ZV90
aW1lGAkgASgLMhouZ29vZ2xlLnByb3RvYnVmLlRpbWVzdGFtcEID4EEDUgpjcmVhdGVUaW1l
OljqQVUKJG5vdGVib29rcy5nb29nbGVhcGlzLmNvbS9FbnZpcm9ubWVudBItcHJvamVjdHMv
e3Byb2plY3R9L2Vudmlyb25tZW50cy97ZW52aXJvbm1lbnR9QgwKCmltYWdlX3R5cGUidwoH
Vm1JbWFnZRIdCgdwcm9qZWN0GAEgASgJQgPgQQJSB3Byb2plY3QSHwoKaW1hZ2VfbmFtZRgC
IAEoCUgAUglpbWFnZU5hbWUSIwoMaW1hZ2VfZmFtaWx5GAMgASgJSABSC2ltYWdlRmFtaWx5
QgcKBWltYWdlIkcKDkNvbnRhaW5lckltYWdlEiMKCnJlcG9zaXRvcnkYASABKAlCA+BBAlIK
cmVwb3NpdG9yeRIQCgN0YWcYAiABKAlSA3RhZ0LHAQodY29tLmdvb2dsZS5jbG91ZC5ub3Rl
Ym9va3MudjFCEEVudmlyb25tZW50UHJvdG9QAVo7Y2xvdWQuZ29vZ2xlLmNvbS9nby9ub3Rl
Ym9va3MvYXBpdjEvbm90ZWJvb2tzcGI7bm90ZWJvb2tzcGKqAhlHb29nbGUuQ2xvdWQuTm90
ZWJvb2tzLlYxygIZR29vZ2xlXENsb3VkXE5vdGVib29rc1xWMeoCHEdvb2dsZTo6Q2xvdWQ6
Ok5vdGVib29rczo6VjFKjBkKBhIEDgBfAQq8BAoBDBIDDgASMrEEIENvcHlyaWdodCAyMDI1
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
ZW5zZS4KCggKAQISAxAAIgoJCgIDABIDEgApCgkKAgMBEgMTACMKCQoCAwISAxQAKQoICgEI
EgMWADYKCQoCCCUSAxYANgoICgEIEgMXAFIKCQoCCAsSAxcAUgoICgEIEgMYACIKCQoCCAoS
AxgAIgoICgEIEgMZADEKCQoCCAgSAxkAMQoICgEIEgMaADYKCQoCCAESAxoANgoICgEIEgMb
ADYKCQoCCCkSAxsANgoICgEIEgMcADUKCQoCCC0SAxwANQpeCgIEABIEIABBARpSIERlZmlu
aXRpb24gb2YgYSBzb2Z0d2FyZSBlbnZpcm9ubWVudCB0aGF0IGlzIHVzZWQgdG8gc3RhcnQg
YSBub3RlYm9vawogaW5zdGFuY2UuCgoKCgMEAAESAyAIEwoLCgMEAAcSBCECJAQKDQoFBAAH
nQgSBCECJAQKigEKBAQAAgASAykCPhp9IE91dHB1dCBvbmx5LiBOYW1lIG9mIHRoaXMgZW52
aXJvbm1lbnQuCiBGb3JtYXQ6CiBgcHJvamVjdHMve3Byb2plY3RfaWR9L2xvY2F0aW9ucy97
bG9jYXRpb259L2Vudmlyb25tZW50cy97ZW52aXJvbm1lbnRfaWR9YAoKDAoFBAACAAUSAykC
CAoMCgUEAAIAARIDKQkNCgwKBQQAAgADEgMpEBEKDAoFBAACAAgSAykSPQoPCggEAAIACJwI
ABIDKRM8CjsKBAQAAgESAywCGhouIERpc3BsYXkgbmFtZSBvZiB0aGlzIGVudmlyb25tZW50
IGZvciB0aGUgVUkuCgoMCgUEAAIBBRIDLAIICgwKBQQAAgEBEgMsCRUKDAoFBAACAQMSAywY
GQo3CgQEAAICEgMvAhkaKiBBIGJyaWVmIGRlc2NyaXB0aW9uIG9mIHRoaXMgZW52aXJvbm1l
bnQuCgoMCgUEAAICBRIDLwIICgwKBQQAAgIBEgMvCRQKDAoFBAACAgMSAy8XGApUCgQEAAgA
EgQyAjgDGkYgVHlwZSBvZiB0aGUgZW52aXJvbm1lbnQ7IGNhbiBiZSBvbmUgb2YgVk0gaW1h
Z2UsIG9yIGNvbnRhaW5lciBpbWFnZS4KCgwKBQQACAABEgMyCBIKTAoEBAACAxIDNAQZGj8g
VXNlIGEgQ29tcHV0ZSBFbmdpbmUgVk0gaW1hZ2UgdG8gc3RhcnQgdGhlIG5vdGVib29rIGlu
c3RhbmNlLgoKDAoFBAACAwYSAzQECwoMCgUEAAIDARIDNAwUCgwKBQQAAgMDEgM0FxgKRAoE
BAACBBIDNwQnGjcgVXNlIGEgY29udGFpbmVyIGltYWdlIHRvIHN0YXJ0IHRoZSBub3RlYm9v
ayBpbnN0YW5jZS4KCgwKBQQAAgQGEgM3BBIKDAoFBAACBAESAzcTIgoMCgUEAAIEAxIDNyUm
CsABCgQEAAIFEgM9AiEasgEgUGF0aCB0byBhIEJhc2ggc2NyaXB0IHRoYXQgYXV0b21hdGlj
YWxseSBydW5zIGFmdGVyIGEgbm90ZWJvb2sgaW5zdGFuY2UKIGZ1bGx5IGJvb3RzIHVwLiBU
aGUgcGF0aCBtdXN0IGJlIGEgVVJMIG9yCiBDbG91ZCBTdG9yYWdlIHBhdGguIEV4YW1wbGU6
IGAiZ3M6Ly9wYXRoLXRvLWZpbGUvZmlsZS1uYW1lImAKCgwKBQQAAgUFEgM9AggKDAoFBAAC
BQESAz0JHAoMCgUEAAIFAxIDPR8gCksKBAQAAgYSA0ACWBo+IE91dHB1dCBvbmx5LiBUaGUg
dGltZSBhdCB3aGljaCB0aGlzIGVudmlyb25tZW50IHdhcyBjcmVhdGVkLgoKDAoFBAACBgYS
A0ACGwoMCgUEAAIGARIDQBwnCgwKBQQAAgYDEgNAKisKDAoFBAACBggSA0AsVwoPCggEAAIG
CJwIABIDQC1WCp8BCgIEARIERQBTARqSASBEZWZpbml0aW9uIG9mIGEgY3VzdG9tIENvbXB1
dGUgRW5naW5lIHZpcnR1YWwgbWFjaGluZSBpbWFnZSBmb3Igc3RhcnRpbmcgYQogbm90ZWJv
b2sgaW5zdGFuY2Ugd2l0aCB0aGUgZW52aXJvbm1lbnQgaW5zdGFsbGVkIGRpcmVjdGx5IG9u
IHRoZSBWTS4KCgoKAwQBARIDRQgPCnQKBAQBAgASA0gCPhpnIFJlcXVpcmVkLiBUaGUgbmFt
ZSBvZiB0aGUgR29vZ2xlIENsb3VkIHByb2plY3QgdGhhdCB0aGlzIFZNIGltYWdlIGJlbG9u
Z3MgdG8uCiBGb3JtYXQ6IGB7cHJvamVjdF9pZH1gCgoMCgUEAQIABRIDSAIICgwKBQQBAgAB
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

# === Message: Google::Cloud::Notebooks::V1::Environment::Environment ===
    # Fields for Environment
    # Field: name Type: 9 ()
    # Field: display_name Type: 9 ()
    # Field: description Type: 9 ()
    # Field: vm_image Type: 11 (.google.cloud.notebooks.v1.VmImage)
    # Field: container_image Type: 11 (.google.cloud.notebooks.v1.ContainerImage)
    # Field: post_startup_script Type: 9 ()
    # Field: create_time Type: 11 (.google.protobuf.Timestamp)

# === Message: Google::Cloud::Notebooks::V1::Environment::VmImage ===
    # Fields for VmImage
    # Field: project Type: 9 ()
    # Field: image_name Type: 9 ()
    # Field: image_family Type: 9 ()

# === Message: Google::Cloud::Notebooks::V1::Environment::ContainerImage ===
    # Fields for ContainerImage
    # Field: repository Type: 9 ()
    # Field: tag Type: 9 ()

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Notebooks::V1::Environment - Compiled Protocol Buffers messages for google/cloud/notebooks/v1/environment.proto

=head1 SYNOPSIS

    use Google::Cloud::Notebooks::V1::Environment;

    my $msg = Google::Cloud::Notebooks::V1::Environment::Environment->new({
        name => $name,
        display_name => $display_name,
        description => $description,
        vm_image => $vm_image,
    });

    # Read or update a field
    my $val = $msg->name();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Notebooks::V1::Environment::Environment->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/notebooks/v1/environment.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Notebooks::V1::Environment::Environment

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

Type: C<Message> (L<Google::Cloud::Notebooks::V1::Environment::VmImage>)

Use a Compute Engine VM image to start the notebook instance.

=item * C<< $msg->container_image() >> / C<< $msg->container_image($value) >>

Type: C<Message> (L<Google::Cloud::Notebooks::V1::Environment::ContainerImage>)

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

=head2 Google::Cloud::Notebooks::V1::Environment::VmImage

Definition of a custom Compute Engine virtual machine image for starting a
notebook instance with the environment installed directly on the VM.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->project() >> / C<< $msg->project($value) >>

Type: C<String>

Required. The name of the Google Cloud project that this VM image belongs to.
Format: `{project_id}`

=item * C<< $msg->image_name() >> / C<< $msg->image_name($value) >>

Type: C<String>

Use VM image name to find the image.

=item * C<< $msg->image_family() >> / C<< $msg->image_family($value) >>

Type: C<String>

Use this VM image family to find the image; the newest image in this
family will be used.

=back

=head2 Google::Cloud::Notebooks::V1::Environment::ContainerImage

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

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Notebooks::V1::Environment::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
