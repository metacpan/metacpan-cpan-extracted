package Google::Devtools::Artifactregistry::V1::Generic;

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
CjFnb29nbGUvZGV2dG9vbHMvYXJ0aWZhY3RyZWdpc3RyeS92MS9nZW5lcmljLnByb3RvEiNn
b29nbGUuZGV2dG9vbHMuYXJ0aWZhY3RyZWdpc3RyeS52MRofZ29vZ2xlL2FwaS9maWVsZF9i
ZWhhdmlvci5wcm90bxoZZ29vZ2xlL2FwaS9yZXNvdXJjZS5wcm90bxofZ29vZ2xlL3Byb3Rv
YnVmL3RpbWVzdGFtcC5wcm90byLiAgoPR2VuZXJpY0FydGlmYWN0EhIKBG5hbWUYASABKAlS
BG5hbWUSGAoHdmVyc2lvbhgCIAEoCVIHdmVyc2lvbhJACgtjcmVhdGVfdGltZRgDIAEoCzIa
Lmdvb2dsZS5wcm90b2J1Zi5UaW1lc3RhbXBCA+BBA1IKY3JlYXRlVGltZRJACgt1cGRhdGVf
dGltZRgEIAEoCzIaLmdvb2dsZS5wcm90b2J1Zi5UaW1lc3RhbXBCA+BBA1IKdXBkYXRlVGlt
ZTqcAepBmAEKL2FydGlmYWN0cmVnaXN0cnkuZ29vZ2xlYXBpcy5jb20vR2VuZXJpY0FydGlm
YWN0EmVwcm9qZWN0cy97cHJvamVjdH0vbG9jYXRpb25zL3tsb2NhdGlvbn0vcmVwb3NpdG9y
aWVzL3tyZXBvc2l0b3J5fS9nZW5lcmljQXJ0aWZhY3RzL3tnZW5lcmljX2FydGlmYWN0fUL3
AQonY29tLmdvb2dsZS5kZXZ0b29scy5hcnRpZmFjdHJlZ2lzdHJ5LnYxQgxHZW5lcmljUHJv
dG9QAVpQY2xvdWQuZ29vZ2xlLmNvbS9nby9hcnRpZmFjdHJlZ2lzdHJ5L2FwaXYxL2FydGlm
YWN0cmVnaXN0cnlwYjthcnRpZmFjdHJlZ2lzdHJ5cGKqAiBHb29nbGUuQ2xvdWQuQXJ0aWZh
Y3RSZWdpc3RyeS5WMcoCIEdvb2dsZVxDbG91ZFxBcnRpZmFjdFJlZ2lzdHJ5XFYx6gIjR29v
Z2xlOjpDbG91ZDo6QXJ0aWZhY3RSZWdpc3RyeTo6VjFKogwKBhIEDgA2AQq8BAoBDBIDDgAS
MrEEIENvcHlyaWdodCAyMDI2IEdvb2dsZSBMTEMKCiBMaWNlbnNlZCB1bmRlciB0aGUgQXBh
Y2hlIExpY2Vuc2UsIFZlcnNpb24gMi4wICh0aGUgIkxpY2Vuc2UiKTsKIHlvdSBtYXkgbm90
IHVzZSB0aGlzIGZpbGUgZXhjZXB0IGluIGNvbXBsaWFuY2Ugd2l0aCB0aGUgTGljZW5zZS4K
IFlvdSBtYXkgb2J0YWluIGEgY29weSBvZiB0aGUgTGljZW5zZSBhdAoKICAgICBodHRwOi8v
d3d3LmFwYWNoZS5vcmcvbGljZW5zZXMvTElDRU5TRS0yLjAKCiBVbmxlc3MgcmVxdWlyZWQg
YnkgYXBwbGljYWJsZSBsYXcgb3IgYWdyZWVkIHRvIGluIHdyaXRpbmcsIHNvZnR3YXJlCiBk
aXN0cmlidXRlZCB1bmRlciB0aGUgTGljZW5zZSBpcyBkaXN0cmlidXRlZCBvbiBhbiAiQVMg
SVMiIEJBU0lTLAogV0lUSE9VVCBXQVJSQU5USUVTIE9SIENPTkRJVElPTlMgT0YgQU5ZIEtJ
TkQsIGVpdGhlciBleHByZXNzIG9yIGltcGxpZWQuCiBTZWUgdGhlIExpY2Vuc2UgZm9yIHRo
ZSBzcGVjaWZpYyBsYW5ndWFnZSBnb3Zlcm5pbmcgcGVybWlzc2lvbnMgYW5kCiBsaW1pdGF0
aW9ucyB1bmRlciB0aGUgTGljZW5zZS4KCggKAQISAxAALAoJCgIDABIDEgApCgkKAgMBEgMT
ACMKCQoCAwISAxQAKQoICgEIEgMWAD0KCQoCCCUSAxYAPQoICgEIEgMXAGcKCQoCCAsSAxcA
ZwoICgEIEgMYACIKCQoCCAoSAxgAIgoICgEIEgMZAC0KCQoCCAgSAxkALQoICgEIEgMaAEAK
CQoCCAESAxoAQAoICgEIEgMbAD0KCQoCCCkSAxsAPQoICgEIEgMcADwKCQoCCC0SAxwAPAo7
CgIEABIEHwA2ARovIEdlbmVyaWNBcnRpZmFjdCByZXByZXNlbnRzIGEgZ2VuZXJpYyBhcnRp
ZmFjdAoKCgoDBAABEgMfCBcKCwoDBAAHEgQgAiMECg0KBQQAB50IEgQgAiMECoQCCgQEAAIA
EgMqAhIa9gEgUmVzb3VyY2UgbmFtZSBvZiB0aGUgZ2VuZXJpYyBhcnRpZmFjdC4KIHByb2pl
Y3QsIGxvY2F0aW9uLCByZXBvc2l0b3J5LCBwYWNrYWdlX2lkIGFuZCB2ZXJzaW9uX2lkCiBj
cmVhdGUgYSB1bmlxdWUgZ2VuZXJpYyBhcnRpZmFjdC4KIGkuZS4gInByb2plY3RzL3Rlc3Qt
cHJvamVjdC9sb2NhdGlvbnMvdXMtd2VzdDQvcmVwb3NpdG9yaWVzL3Rlc3QtcmVwby8KIGdl
bmVyaWNBcnRpZmFjdHMvcGFja2FnZV9pZDp2ZXJzaW9uX2lkIgoKDAoFBAACAAUSAyoCCAoM
CgUEAAIAARIDKgkNCgwKBQQAAgADEgMqEBEKMwoEBAACARIDLQIVGiYgVGhlIHZlcnNpb24g
b2YgdGhlIGdlbmVyaWMgYXJ0aWZhY3QuCgoMCgUEAAIBBRIDLQIICgwKBQQAAgEBEgMtCRAK
DAoFBAACAQMSAy0TFApJCgQEAAICEgQwAjEyGjsgT3V0cHV0IG9ubHkuIFRoZSB0aW1lIHdo
ZW4gdGhlIEdlbmVyaWMgbW9kdWxlIGlzIGNyZWF0ZWQuCgoMCgUEAAICBhIDMAIbCgwKBQQA
AgIBEgMwHCcKDAoFBAACAgMSAzAqKwoMCgUEAAICCBIDMQYxCg8KCAQAAgIInAgAEgMxBzAK
SQoEBAACAxIENAI1Mho7IE91dHB1dCBvbmx5LiBUaGUgdGltZSB3aGVuIHRoZSBHZW5lcmlj
IG1vZHVsZSBpcyB1cGRhdGVkLgoKDAoFBAACAwYSAzQCGwoMCgUEAAIDARIDNBwnCgwKBQQA
AgMDEgM0KisKDAoFBAACAwgSAzUGMQoPCggEAAIDCJwIABIDNQcwYgZwcm90bzM=
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Devtools::Artifactregistry::V1::Generic::GenericArtifact ===
    # Fields for GenericArtifact
    # Field: name Type: 9 ()
    # Field: version Type: 9 ()
    # Field: create_time Type: 11 (.google.protobuf.Timestamp)
    # Field: update_time Type: 11 (.google.protobuf.Timestamp)

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Devtools::Artifactregistry::V1::Generic - Compiled Protocol Buffers messages for google/devtools/artifactregistry/v1/generic.proto

=head1 SYNOPSIS

    use Google::Devtools::Artifactregistry::V1::Generic;

    my $msg = Google::Devtools::Artifactregistry::V1::Generic::GenericArtifact->new({
        name => $name,
        version => $version,
        create_time => $create_time,
        update_time => $update_time,
    });

    # Read or update a field
    my $val = $msg->name();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Devtools::Artifactregistry::V1::Generic::GenericArtifact->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/devtools/artifactregistry/v1/generic.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Devtools::Artifactregistry::V1::Generic::GenericArtifact

GenericArtifact represents a generic artifact

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Resource name of the generic artifact.
project, location, repository, package_id and version_id
create a unique generic artifact.
i.e. "projects/test-project/locations/us-west4/repositories/test-repo/
genericArtifacts/package_id:version_id"

=item * C<< $msg->version() >> / C<< $msg->version($value) >>

Type: C<String>

The version of the generic artifact.

=item * C<< $msg->create_time() >> / C<< $msg->create_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Output only. The time when the Generic module is created.

=item * C<< $msg->update_time() >> / C<< $msg->update_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Output only. The time when the Generic module is updated.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Devtools::Artifactregistry::V1::Generic::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
