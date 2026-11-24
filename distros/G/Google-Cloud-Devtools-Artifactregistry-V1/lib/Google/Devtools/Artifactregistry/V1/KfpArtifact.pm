package Google::Devtools::Artifactregistry::V1::KfpArtifact;

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
CjZnb29nbGUvZGV2dG9vbHMvYXJ0aWZhY3RyZWdpc3RyeS92MS9rZnBfYXJ0aWZhY3QucHJv
dG8SI2dvb2dsZS5kZXZ0b29scy5hcnRpZmFjdHJlZ2lzdHJ5LnYxGh9nb29nbGUvYXBpL2Zp
ZWxkX2JlaGF2aW9yLnByb3RvGhlnb29nbGUvYXBpL3Jlc291cmNlLnByb3RvItMBCgtLZnBB
cnRpZmFjdBIXCgRuYW1lGAEgASgJQgPgQQNSBG5hbWUSGAoHdmVyc2lvbhgCIAEoCVIHdmVy
c2lvbjqQAepBjAEKK2FydGlmYWN0cmVnaXN0cnkuZ29vZ2xlYXBpcy5jb20vS2ZwQXJ0aWZh
Y3QSXXByb2plY3RzL3twcm9qZWN0fS9sb2NhdGlvbnMve2xvY2F0aW9ufS9yZXBvc2l0b3Jp
ZXMve3JlcG9zaXRvcnl9L2tmcEFydGlmYWN0cy97a2ZwX2FydGlmYWN0fUL7AQonY29tLmdv
b2dsZS5kZXZ0b29scy5hcnRpZmFjdHJlZ2lzdHJ5LnYxQhBLZnBBcnRpZmFjdFByb3RvUAFa
UGNsb3VkLmdvb2dsZS5jb20vZ28vYXJ0aWZhY3RyZWdpc3RyeS9hcGl2MS9hcnRpZmFjdHJl
Z2lzdHJ5cGI7YXJ0aWZhY3RyZWdpc3RyeXBiqgIgR29vZ2xlLkNsb3VkLkFydGlmYWN0UmVn
aXN0cnkuVjHKAiBHb29nbGVcQ2xvdWRcQXJ0aWZhY3RSZWdpc3RyeVxWMeoCI0dvb2dsZTo6
Q2xvdWQ6OkFydGlmYWN0UmVnaXN0cnk6OlYxSuQKCgYSBA4ALQEKvAQKAQwSAw4AEjKxBCBD
b3B5cmlnaHQgMjAyNiBHb29nbGUgTExDCgogTGljZW5zZWQgdW5kZXIgdGhlIEFwYWNoZSBM
aWNlbnNlLCBWZXJzaW9uIDIuMCAodGhlICJMaWNlbnNlIik7CiB5b3UgbWF5IG5vdCB1c2Ug
dGhpcyBmaWxlIGV4Y2VwdCBpbiBjb21wbGlhbmNlIHdpdGggdGhlIExpY2Vuc2UuCiBZb3Ug
bWF5IG9idGFpbiBhIGNvcHkgb2YgdGhlIExpY2Vuc2UgYXQKCiAgICAgaHR0cDovL3d3dy5h
cGFjaGUub3JnL2xpY2Vuc2VzL0xJQ0VOU0UtMi4wCgogVW5sZXNzIHJlcXVpcmVkIGJ5IGFw
cGxpY2FibGUgbGF3IG9yIGFncmVlZCB0byBpbiB3cml0aW5nLCBzb2Z0d2FyZQogZGlzdHJp
YnV0ZWQgdW5kZXIgdGhlIExpY2Vuc2UgaXMgZGlzdHJpYnV0ZWQgb24gYW4gIkFTIElTIiBC
QVNJUywKIFdJVEhPVVQgV0FSUkFOVElFUyBPUiBDT05ESVRJT05TIE9GIEFOWSBLSU5ELCBl
aXRoZXIgZXhwcmVzcyBvciBpbXBsaWVkLgogU2VlIHRoZSBMaWNlbnNlIGZvciB0aGUgc3Bl
Y2lmaWMgbGFuZ3VhZ2UgZ292ZXJuaW5nIHBlcm1pc3Npb25zIGFuZAogbGltaXRhdGlvbnMg
dW5kZXIgdGhlIExpY2Vuc2UuCgoICgECEgMQACwKCQoCAwASAxIAKQoJCgIDARIDEwAjCggK
AQgSAxUAPQoJCgIIJRIDFQA9CggKAQgSAxYAZwoJCgIICxIDFgBnCggKAQgSAxcAIgoJCgII
ChIDFwAiCggKAQgSAxgAMQoJCgIICBIDGAAxCggKAQgSAxkAQAoJCgIIARIDGQBACggKAQgS
AxoAPQoJCgIIKRIDGgA9CggKAQgSAxsAPAoJCgIILRIDGwA8CjoKAgQAEgQeAC0BGi4gQSBk
ZXRhaWxlZCByZXByZXNlbnRhdGlvbiBvZiBhIEtGUCBhcnRpZmFjdC4KCgoKAwQAARIDHggT
CgsKAwQABxIEHwIiBAoNCgUEAAedCBIEHwIiBAqjAgoEBAACABIDKAI+GpUCIE91dHB1dCBv
bmx5LiBSZXNvdXJjZSBuYW1lIG9mIHRoZSBLRlAgYXJ0aWZhY3QuIFNpbmNlIHVzZXJzIGRv
bid0IGRpcmVjdGx5CiBpbnRlcmFjdCB3aXRoIHRoaXMgcmVzb3VyY2UsIHRoZSBuYW1lIHdp
bGwgYmUgZGVyaXZlZCBmcm9tIHRoZSBhc3NvY2lhdGVkCiB2ZXJzaW9uLiBGb3IgZXhhbXBs
ZSwgd2hlbiB2ZXJzaW9uID0gIi4uLi92ZXJzaW9ucy9zaGEyNTY6YWJjZGVmLi4uIiwgdGhl
CiBuYW1lIHdpbGwgYmUgIi4uLi9rZnBBcnRpZmFjdHMvc2hhMjU2OmFiY2RlZi4uLiIuCgoM
CgUEAAIABRIDKAIICgwKBQQAAgABEgMoCQ0KDAoFBAACAAMSAygQEQoMCgUEAAIACBIDKBI9
Cg8KCAQAAgAInAgAEgMoEzwKawoEBAACARIDLAIVGl4gVGhlIHZlcnNpb24gYXNzb2NpYXRl
ZCB3aXRoIHRoZSBLRlAgYXJ0aWZhY3QuIE11c3QgZm9sbG93IHRoZSBTZW1hbnRpYwogVmVy
c2lvbmluZyBzdGFuZGFyZC4KCgwKBQQAAgEFEgMsAggKDAoFBAACAQESAywJEAoMCgUEAAIB
AxIDLBMUYgZwcm90bzM=
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Devtools::Artifactregistry::V1::KfpArtifact::KfpArtifact ===
    # Fields for KfpArtifact
    # Field: name Type: 9 ()
    # Field: version Type: 9 ()

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Devtools::Artifactregistry::V1::KfpArtifact - Compiled Protocol Buffers messages for google/devtools/artifactregistry/v1/kfp_artifact.proto

=head1 SYNOPSIS

    use Google::Devtools::Artifactregistry::V1::KfpArtifact;

    my $msg = Google::Devtools::Artifactregistry::V1::KfpArtifact::KfpArtifact->new({
        name => $name,
        version => $version,
    });

    # Read or update a field
    my $val = $msg->name();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Devtools::Artifactregistry::V1::KfpArtifact::KfpArtifact->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/devtools/artifactregistry/v1/kfp_artifact.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Devtools::Artifactregistry::V1::KfpArtifact::KfpArtifact

A detailed representation of a KFP artifact.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Output only. Resource name of the KFP artifact. Since users don't directly
interact with this resource, the name will be derived from the associated
version. For example, when version = ".../versions/sha256:abcdef...", the
name will be ".../kfpArtifacts/sha256:abcdef...".

=item * C<< $msg->version() >> / C<< $msg->version($value) >>

Type: C<String>

The version associated with the KFP artifact. Must follow the Semantic
Versioning standard.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Devtools::Artifactregistry::V1::KfpArtifact::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
