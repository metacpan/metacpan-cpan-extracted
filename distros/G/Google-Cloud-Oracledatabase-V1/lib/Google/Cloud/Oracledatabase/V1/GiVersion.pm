package Google::Cloud::Oracledatabase::V1::GiVersion;

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
Ci9nb29nbGUvY2xvdWQvb3JhY2xlZGF0YWJhc2UvdjEvZ2lfdmVyc2lvbi5wcm90bxIeZ29v
Z2xlLmNsb3VkLm9yYWNsZWRhdGFiYXNlLnYxGh9nb29nbGUvYXBpL2ZpZWxkX2JlaGF2aW9y
LnByb3RvGhlnb29nbGUvYXBpL3Jlc291cmNlLnByb3RvIssBCglHaVZlcnNpb24SFwoEbmFt
ZRgBIAEoCUID4EEIUgRuYW1lEh0KB3ZlcnNpb24YAiABKAlCA+BBAVIHdmVyc2lvbjqFAepB
gQEKJ29yYWNsZWRhdGFiYXNlLmdvb2dsZWFwaXMuY29tL0dpVmVyc2lvbhI/cHJvamVjdHMv
e3Byb2plY3R9L2xvY2F0aW9ucy97bG9jYXRpb259L2dpVmVyc2lvbnMve2dpX3ZlcnNpb259
KgpnaVZlcnNpb25zMglnaVZlcnNpb25C6AEKImNvbS5nb29nbGUuY2xvdWQub3JhY2xlZGF0
YWJhc2UudjFCDkdpVmVyc2lvblByb3RvUAFaSmNsb3VkLmdvb2dsZS5jb20vZ28vb3JhY2xl
ZGF0YWJhc2UvYXBpdjEvb3JhY2xlZGF0YWJhc2VwYjtvcmFjbGVkYXRhYmFzZXBiqgIeR29v
Z2xlLkNsb3VkLk9yYWNsZURhdGFiYXNlLlYxygIeR29vZ2xlXENsb3VkXE9yYWNsZURhdGFi
YXNlXFYx6gIhR29vZ2xlOjpDbG91ZDo6T3JhY2xlRGF0YWJhc2U6OlYxSqoKCgYSBA4ALgEK
vAQKAQwSAw4AEjKxBCBDb3B5cmlnaHQgMjAyNiBHb29nbGUgTExDCgogTGljZW5zZWQgdW5k
ZXIgdGhlIEFwYWNoZSBMaWNlbnNlLCBWZXJzaW9uIDIuMCAodGhlICJMaWNlbnNlIik7CiB5
b3UgbWF5IG5vdCB1c2UgdGhpcyBmaWxlIGV4Y2VwdCBpbiBjb21wbGlhbmNlIHdpdGggdGhl
IExpY2Vuc2UuCiBZb3UgbWF5IG9idGFpbiBhIGNvcHkgb2YgdGhlIExpY2Vuc2UgYXQKCiAg
ICAgaHR0cDovL3d3dy5hcGFjaGUub3JnL2xpY2Vuc2VzL0xJQ0VOU0UtMi4wCgogVW5sZXNz
IHJlcXVpcmVkIGJ5IGFwcGxpY2FibGUgbGF3IG9yIGFncmVlZCB0byBpbiB3cml0aW5nLCBz
b2Z0d2FyZQogZGlzdHJpYnV0ZWQgdW5kZXIgdGhlIExpY2Vuc2UgaXMgZGlzdHJpYnV0ZWQg
b24gYW4gIkFTIElTIiBCQVNJUywKIFdJVEhPVVQgV0FSUkFOVElFUyBPUiBDT05ESVRJT05T
IE9GIEFOWSBLSU5ELCBlaXRoZXIgZXhwcmVzcyBvciBpbXBsaWVkLgogU2VlIHRoZSBMaWNl
bnNlIGZvciB0aGUgc3BlY2lmaWMgbGFuZ3VhZ2UgZ292ZXJuaW5nIHBlcm1pc3Npb25zIGFu
ZAogbGltaXRhdGlvbnMgdW5kZXIgdGhlIExpY2Vuc2UuCgoICgECEgMQACcKCQoCAwASAxIA
KQoJCgIDARIDEwAjCggKAQgSAxUAOwoJCgIIJRIDFQA7CggKAQgSAxYAYQoJCgIICxIDFgBh
CggKAQgSAxcAIgoJCgIIChIDFwAiCggKAQgSAxgALwoJCgIICBIDGAAvCggKAQgSAxkAOwoJ
CgIIARIDGQA7CggKAQgSAxoAOwoJCgIIKRIDGgA7CggKAQgSAxsAOgoJCgIILRIDGwA6CqAB
CgIEABIEHwAuARqTASBEZXRhaWxzIG9mIHRoZSBPcmFjbGUgR3JpZCBJbmZyYXN0cnVjdHVy
ZSAoR0kpIHZlcnNpb24gcmVzb3VyY2UuCiBodHRwczovL2RvY3Mub3JhY2xlLmNvbS9lbi11
cy9pYWFzL2FwaS8jL2VuL2RhdGFiYXNlLzIwMTYwOTE4L0dpVmVyc2lvblN1bW1hcnkvCgoK
CgMEAAESAx8IEQoLCgMEAAcSBCACJQQKDQoFBAAHnQgSBCACJQQKrgEKBAQAAgASAyoCPRqg
ASBJZGVudGlmaWVyLiBUaGUgbmFtZSBvZiB0aGUgT3JhY2xlIEdyaWQgSW5mcmFzdHJ1Y3R1
cmUgKEdJKSB2ZXJzaW9uCiByZXNvdXJjZSB3aXRoIHRoZSBmb3JtYXQ6CiBwcm9qZWN0cy97
cHJvamVjdH0vbG9jYXRpb25zL3tyZWdpb259L2dpVmVyc2lvbnMve2dpX3ZlcnNpb25zfQoK
DAoFBAACAAUSAyoCCAoMCgUEAAIAARIDKgkNCgwKBQQAAgADEgMqEBEKDAoFBAACAAgSAyoS
PAoPCggEAAIACJwIABIDKhM7CiAKBAQAAgESAy0CPhoTIE9wdGlvbmFsLiB2ZXJzaW9uCgoM
CgUEAAIBBRIDLQIICgwKBQQAAgEBEgMtCRAKDAoFBAACAQMSAy0TFAoMCgUEAAIBCBIDLRU9
Cg8KCAQAAgEInAgAEgMtFjxiBnByb3RvMw==
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Oracledatabase::V1::GiVersion::GiVersion ===
    # Fields for GiVersion
    # Field: name Type: 9 ()
    # Field: version Type: 9 ()

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Oracledatabase::V1::GiVersion - Compiled Protocol Buffers messages for google/cloud/oracledatabase/v1/gi_version.proto

=head1 SYNOPSIS

    use Google::Cloud::Oracledatabase::V1::GiVersion;

    my $msg = Google::Cloud::Oracledatabase::V1::GiVersion::GiVersion->new({
        name => $name,
        version => $version,
    });

    # Read or update a field
    my $val = $msg->name();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Oracledatabase::V1::GiVersion::GiVersion->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/oracledatabase/v1/gi_version.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Oracledatabase::V1::GiVersion::GiVersion

Details of the Oracle Grid Infrastructure (GI) version resource.
https://docs.oracle.com/en-us/iaas/api/#/en/database/20160918/GiVersionSummary/

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Identifier. The name of the Oracle Grid Infrastructure (GI) version
resource with the format:
projects/{project}/locations/{region}/giVersions/{gi_versions}

=item * C<< $msg->version() >> / C<< $msg->version($value) >>

Type: C<String>

Optional. version

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Oracledatabase::V1::GiVersion::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
