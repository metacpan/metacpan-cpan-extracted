package Google::Cloud::Run::V2::Sandbox;

use strict;
use warnings;

our $VERSION = '0.14';

use Protobuf::Message;
use Protobuf::DescriptorPool;
use Protobuf::Internal qw(:all);
use MIME::Base64;

BEGIN {
    eval { require Google::Api::FieldBehavior };
    eval { require Google::Cloud::Run::V2::K8sMin };
    my $descriptor_b64 = <<'EOF';
CiFnb29nbGUvY2xvdWQvcnVuL3YyL3NhbmRib3gucHJvdG8SE2dvb2dsZS5jbG91ZC5ydW4u
djIaH2dvb2dsZS9hcGkvZmllbGRfYmVoYXZpb3IucHJvdG8aIWdvb2dsZS9jbG91ZC9ydW4v
djIvazhzLm1pbi5wcm90byJfChRTYW5kYm94Q29uZmlndXJhdGlvbhJHCgl0ZW1wbGF0ZXMY
BCADKAsyJC5nb29nbGUuY2xvdWQucnVuLnYyLlNhbmRib3hUZW1wbGF0ZUID4EECUgl0ZW1w
bGF0ZXMiowIKD1NhbmRib3hUZW1wbGF0ZRIXCgRuYW1lGAEgASgJQgPgQQJSBG5hbWUSGQoF
aW1hZ2UYAiABKAlCA+BBAlIFaW1hZ2USHQoHY29tbWFuZBgDIAMoCUID4EEBUgdjb21tYW5k
EhcKBGFyZ3MYBCADKAlCA+BBAVIEYXJncxIyCgNlbnYYBSADKAsyGy5nb29nbGUuY2xvdWQu
cnVuLnYyLkVudlZhckID4EEBUgNlbnYSSgoNdm9sdW1lX21vdW50cxgHIAMoCzIgLmdvb2ds
ZS5jbG91ZC5ydW4udjIuVm9sdW1lTW91bnRCA+BBAVIMdm9sdW1lTW91bnRzEiQKC3dvcmtp
bmdfZGlyGAggASgJQgPgQQFSCndvcmtpbmdEaXJCVAoXY29tLmdvb2dsZS5jbG91ZC5ydW4u
djJCDFNhbmRib3hQcm90b1ABWiljbG91ZC5nb29nbGUuY29tL2dvL3J1bi9hcGl2Mi9ydW5w
YjtydW5wYkq9EgoGEgQOAD0BCrwECgEMEgMOABIysQQgQ29weXJpZ2h0IDIwMjYgR29vZ2xl
IExMQwoKIExpY2Vuc2VkIHVuZGVyIHRoZSBBcGFjaGUgTGljZW5zZSwgVmVyc2lvbiAyLjAg
KHRoZSAiTGljZW5zZSIpOwogeW91IG1heSBub3QgdXNlIHRoaXMgZmlsZSBleGNlcHQgaW4g
Y29tcGxpYW5jZSB3aXRoIHRoZSBMaWNlbnNlLgogWW91IG1heSBvYnRhaW4gYSBjb3B5IG9m
IHRoZSBMaWNlbnNlIGF0CgogICAgIGh0dHA6Ly93d3cuYXBhY2hlLm9yZy9saWNlbnNlcy9M
SUNFTlNFLTIuMAoKIFVubGVzcyByZXF1aXJlZCBieSBhcHBsaWNhYmxlIGxhdyBvciBhZ3Jl
ZWQgdG8gaW4gd3JpdGluZywgc29mdHdhcmUKIGRpc3RyaWJ1dGVkIHVuZGVyIHRoZSBMaWNl
bnNlIGlzIGRpc3RyaWJ1dGVkIG9uIGFuICJBUyBJUyIgQkFTSVMsCiBXSVRIT1VUIFdBUlJB
TlRJRVMgT1IgQ09ORElUSU9OUyBPRiBBTlkgS0lORCwgZWl0aGVyIGV4cHJlc3Mgb3IgaW1w
bGllZC4KIFNlZSB0aGUgTGljZW5zZSBmb3IgdGhlIHNwZWNpZmljIGxhbmd1YWdlIGdvdmVy
bmluZyBwZXJtaXNzaW9ucyBhbmQKIGxpbWl0YXRpb25zIHVuZGVyIHRoZSBMaWNlbnNlLgoK
CAoBAhIDEAAcCgkKAgMAEgMSACkKCQoCAwESAxMAKwoICgEIEgMVAEAKCQoCCAsSAxUAQAoI
CgEIEgMWACIKCQoCCAoSAxYAIgoICgEIEgMXAC0KCQoCCAgSAxcALQoICgEIEgMYADAKCQoC
CAESAxgAMAoqCgIEABIEGwAfARoeIENvbmZpZ3VyYXRpb24gZm9yIHNhbmRib3hlcy4KCgoK
AwQAARIDGwgcClsKBAQAAgASBB0CHi8aTSBSZXF1aXJlZC4gU2FuZGJveCB0ZW1wbGF0ZXMg
dGhhdCBjYW4gYmUgbGF1bmNoZWQgdGhyb3VnaCB0aGUgYHNhbmRib3hgIENMSS4KCgwKBQQA
AgAEEgMdAgoKDAoFBAACAAYSAx0LGgoMCgUEAAIAARIDHRskCgwKBQQAAgADEgMdJygKDAoF
BAACAAgSAx4GLgoPCggEAAIACJwIABIDHgctCiwKAgQBEgQiAD0BGiAgVGVtcGxhdGUgZm9y
IGEgc2luZ2xlIHNhbmRib3guCgoKCgMEAQESAyIIFwpRCgQEAQIAEgMkAjsaRCBSZXF1aXJl
ZC4gTmFtZSBvZiB0aGUgc2FuZGJveCBzcGVjaWZpZWQgYXMgYSBETlNfTEFCRUwgKFJGQyAx
MTIzKS4KCgwKBQQBAgAFEgMkAggKDAoFBAECAAESAyQJDQoMCgUEAQIAAxIDJBARCgwKBQQB
AgAIEgMkEjoKDwoIBAECAAicCAASAyQTOQqLAQoEBAECARIDKAI8Gn4gUmVxdWlyZWQuIE5h
bWUgb2YgdGhlIGNvbnRhaW5lciBpbWFnZSBpbiBEb2NrZXJodWIgb3IgQXJ0aWZhY3QgUmVn
aXN0cnkuIElmCiB0aGUgaG9zdCBpcyBub3QgcHJvdmlkZWQsIERvY2tlcmh1YiBpcyBhc3N1
bWVkLgoKDAoFBAECAQUSAygCCAoMCgUEAQIBARIDKAkOCgwKBQQBAgEDEgMoERIKDAoFBAEC
AQgSAygTOwoPCggEAQIBCJwIABIDKBQ6CocBCgQEAQICEgMsAkcaeiBPcHRpb25hbC4gRW50
cnlwb2ludCBhcnJheS4gTm90IGV4ZWN1dGVkIHdpdGhpbiBhIHNoZWxsLgogVGhlIGRvY2tl
ciBpbWFnZSdzIEVOVFJZUE9JTlQgaXMgdXNlZCBpZiB0aGlzIGlzIG5vdCBwcm92aWRlZC4K
CgwKBQQBAgIEEgMsAgoKDAoFBAECAgUSAywLEQoMCgUEAQICARIDLBIZCgwKBQQBAgIDEgMs
HB0KDAoFBAECAggSAyweRgoPCggEAQICCJwIABIDLB9FCm4KBAQBAgMSAzACRBphIE9wdGlv
bmFsLiBBcmd1bWVudHMgdG8gdGhlIGVudHJ5cG9pbnQuCiBUaGUgZG9ja2VyIGltYWdlJ3Mg
Q01EIGlzIHVzZWQgaWYgdGhpcyBpcyBub3QgcHJvdmlkZWQuCgoMCgUEAQIDBBIDMAIKCgwK
BQQBAgMFEgMwCxEKDAoFBAECAwESAzASFgoMCgUEAQIDAxIDMBkaCgwKBQQBAgMIEgMwG0MK
DwoIBAECAwicCAASAzAcQgpNCgQEAQIEEgMzAkMaQCBPcHRpb25hbC4gTGlzdCBvZiBlbnZp
cm9ubWVudCB2YXJpYWJsZXMgdG8gc2V0IGluIHRoZSBzYW5kYm94LgoKDAoFBAECBAQSAzMC
CgoMCgUEAQIEBhIDMwsRCgwKBQQBAgQBEgMzEhUKDAoFBAECBAMSAzMYGQoMCgUEAQIECBID
MxpCCg8KCAQBAgQInAgAEgMzG0EKSgoEBAECBRIENgI3Lxo8IE9wdGlvbmFsLiBWb2x1bWUg
dG8gbW91bnQgaW50byB0aGUgY29udGFpbmVyJ3MgZmlsZXN5c3RlbS4KCgwKBQQBAgUEEgM2
AgoKDAoFBAECBQYSAzYLFgoMCgUEAQIFARIDNhckCgwKBQQBAgUDEgM2JygKDAoFBAECBQgS
AzcGLgoPCggEAQIFCJwIABIDNwctCqwBCgQEAQIGEgM8AkIangEgT3B0aW9uYWwuIENvbnRh
aW5lcidzIHdvcmtpbmcgZGlyZWN0b3J5LgogSWYgbm90IHNwZWNpZmllZCwgdGhlIGNvbnRh
aW5lciBydW50aW1lJ3MgZGVmYXVsdCB3aWxsIGJlIHVzZWQsIHdoaWNoCiBtaWdodCBiZSBj
b25maWd1cmVkIGluIHRoZSBjb250YWluZXIgaW1hZ2UuCgoMCgUEAQIGBRIDPAIICgwKBQQB
AgYBEgM8CRQKDAoFBAECBgMSAzwXGAoMCgUEAQIGCBIDPBlBCg8KCAQBAgYInAgAEgM8GkBi
BnByb3RvMw==
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Run::V2::Sandbox::SandboxConfiguration ===
    # Fields for SandboxConfiguration
    # Field: templates Type: 11 (.google.cloud.run.v2.SandboxTemplate)

# === Message: Google::Cloud::Run::V2::Sandbox::SandboxTemplate ===
    # Fields for SandboxTemplate
    # Field: name Type: 9 ()
    # Field: image Type: 9 ()
    # Field: command Type: 9 ()
    # Field: args Type: 9 ()
    # Field: env Type: 11 (.google.cloud.run.v2.EnvVar)
    # Field: volume_mounts Type: 11 (.google.cloud.run.v2.VolumeMount)
    # Field: working_dir Type: 9 ()

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Run::V2::Sandbox - Compiled Protocol Buffers messages for google/cloud/run/v2/sandbox.proto

=head1 SYNOPSIS

    use Google::Cloud::Run::V2::Sandbox;

    my $msg = Google::Cloud::Run::V2::Sandbox::SandboxConfiguration->new({
        templates => $templates,
    });

    # Read or update a field
    my $val = $msg->templates();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Run::V2::Sandbox::SandboxConfiguration->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/run/v2/sandbox.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Run::V2::Sandbox::SandboxConfiguration

Configuration for sandboxes.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->templates() >> / C<< $msg->templates($value) >>

Type: C<Message> (L<Google::Cloud::Run::V2::Sandbox::SandboxTemplate>)

Required. Sandbox templates that can be launched through the `sandbox` CLI.

=back

=head2 Google::Cloud::Run::V2::Sandbox::SandboxTemplate

Template for a single sandbox.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. Name of the sandbox specified as a DNS_LABEL (RFC 1123).

=item * C<< $msg->image() >> / C<< $msg->image($value) >>

Type: C<String>

Required. Name of the container image in Dockerhub or Artifact Registry. If
the host is not provided, Dockerhub is assumed.

=item * C<< $msg->command() >> / C<< $msg->command($value) >>

Type: C<String>

Optional. Entrypoint array. Not executed within a shell.
The docker image's ENTRYPOINT is used if this is not provided.

=item * C<< $msg->args() >> / C<< $msg->args($value) >>

Type: C<String>

Optional. Arguments to the entrypoint.
The docker image's CMD is used if this is not provided.

=item * C<< $msg->env() >> / C<< $msg->env($value) >>

Type: C<Message> (L<Google::Cloud::Run::V2::K8sMin::EnvVar>)

Optional. List of environment variables to set in the sandbox.

=item * C<< $msg->volume_mounts() >> / C<< $msg->volume_mounts($value) >>

Type: C<Message> (L<Google::Cloud::Run::V2::K8sMin::VolumeMount>)

Optional. Volume to mount into the container's filesystem.

=item * C<< $msg->working_dir() >> / C<< $msg->working_dir($value) >>

Type: C<String>

Optional. Container's working directory.
If not specified, the container runtime's default will be used, which
might be configured in the container image.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Run::V2::Sandbox::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
