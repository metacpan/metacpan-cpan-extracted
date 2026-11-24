package Google::Devtools::Artifactregistry::V1::Go;

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
Cixnb29nbGUvZGV2dG9vbHMvYXJ0aWZhY3RyZWdpc3RyeS92MS9nby5wcm90bxIjZ29vZ2xl
LmRldnRvb2xzLmFydGlmYWN0cmVnaXN0cnkudjEaH2dvb2dsZS9hcGkvZmllbGRfYmVoYXZp
b3IucHJvdG8aGWdvb2dsZS9hcGkvcmVzb3VyY2UucHJvdG8aH2dvb2dsZS9wcm90b2J1Zi90
aW1lc3RhbXAucHJvdG8ixgIKCEdvTW9kdWxlEhIKBG5hbWUYASABKAlSBG5hbWUSGAoHdmVy
c2lvbhgCIAEoCVIHdmVyc2lvbhJACgtjcmVhdGVfdGltZRgDIAEoCzIaLmdvb2dsZS5wcm90
b2J1Zi5UaW1lc3RhbXBCA+BBA1IKY3JlYXRlVGltZRJACgt1cGRhdGVfdGltZRgEIAEoCzIa
Lmdvb2dsZS5wcm90b2J1Zi5UaW1lc3RhbXBCA+BBA1IKdXBkYXRlVGltZTqHAepBgwEKKGFy
dGlmYWN0cmVnaXN0cnkuZ29vZ2xlYXBpcy5jb20vR29Nb2R1bGUSV3Byb2plY3RzL3twcm9q
ZWN0fS9sb2NhdGlvbnMve2xvY2F0aW9ufS9yZXBvc2l0b3JpZXMve3JlcG9zaXRvcnl9L2dv
TW9kdWxlcy97Z29fbW9kdWxlfULyAQonY29tLmdvb2dsZS5kZXZ0b29scy5hcnRpZmFjdHJl
Z2lzdHJ5LnYxQgdHb1Byb3RvUAFaUGNsb3VkLmdvb2dsZS5jb20vZ28vYXJ0aWZhY3RyZWdp
c3RyeS9hcGl2MS9hcnRpZmFjdHJlZ2lzdHJ5cGI7YXJ0aWZhY3RyZWdpc3RyeXBiqgIgR29v
Z2xlLkNsb3VkLkFydGlmYWN0UmVnaXN0cnkuVjHKAiBHb29nbGVcQ2xvdWRcQXJ0aWZhY3RS
ZWdpc3RyeVxWMeoCI0dvb2dsZTo6Q2xvdWQ6OkFydGlmYWN0UmVnaXN0cnk6OlYxSpALCgYS
BA4AMwEKvAQKAQwSAw4AEjKxBCBDb3B5cmlnaHQgMjAyNiBHb29nbGUgTExDCgogTGljZW5z
ZWQgdW5kZXIgdGhlIEFwYWNoZSBMaWNlbnNlLCBWZXJzaW9uIDIuMCAodGhlICJMaWNlbnNl
Iik7CiB5b3UgbWF5IG5vdCB1c2UgdGhpcyBmaWxlIGV4Y2VwdCBpbiBjb21wbGlhbmNlIHdp
dGggdGhlIExpY2Vuc2UuCiBZb3UgbWF5IG9idGFpbiBhIGNvcHkgb2YgdGhlIExpY2Vuc2Ug
YXQKCiAgICAgaHR0cDovL3d3dy5hcGFjaGUub3JnL2xpY2Vuc2VzL0xJQ0VOU0UtMi4wCgog
VW5sZXNzIHJlcXVpcmVkIGJ5IGFwcGxpY2FibGUgbGF3IG9yIGFncmVlZCB0byBpbiB3cml0
aW5nLCBzb2Z0d2FyZQogZGlzdHJpYnV0ZWQgdW5kZXIgdGhlIExpY2Vuc2UgaXMgZGlzdHJp
YnV0ZWQgb24gYW4gIkFTIElTIiBCQVNJUywKIFdJVEhPVVQgV0FSUkFOVElFUyBPUiBDT05E
SVRJT05TIE9GIEFOWSBLSU5ELCBlaXRoZXIgZXhwcmVzcyBvciBpbXBsaWVkLgogU2VlIHRo
ZSBMaWNlbnNlIGZvciB0aGUgc3BlY2lmaWMgbGFuZ3VhZ2UgZ292ZXJuaW5nIHBlcm1pc3Np
b25zIGFuZAogbGltaXRhdGlvbnMgdW5kZXIgdGhlIExpY2Vuc2UuCgoICgECEgMQACwKCQoC
AwASAxIAKQoJCgIDARIDEwAjCgkKAgMCEgMUACkKCAoBCBIDFgA9CgkKAgglEgMWAD0KCAoB
CBIDFwBnCgkKAggLEgMXAGcKCAoBCBIDGAAiCgkKAggKEgMYACIKCAoBCBIDGQAoCgkKAggI
EgMZACgKCAoBCBIDGgBACgkKAggBEgMaAEAKCAoBCBIDGwA9CgkKAggpEgMbAD0KCAoBCBID
HAA8CgkKAggtEgMcADwKLgoCBAASBB8AMwEaIiBHb01vZHVsZSByZXByZXNlbnRzIGEgR28g
bW9kdWxlLgoKCgoDBAABEgMfCBAKCwoDBAAHEgQgAiMECg0KBQQAB50IEgQgAiMECjAKBAQA
AgASAyYCEhojIFRoZSByZXNvdXJjZSBuYW1lIG9mIGEgR28gbW9kdWxlLgoKDAoFBAACAAUS
AyYCCAoMCgUEAAIAARIDJgkNCgwKBQQAAgADEgMmEBEKjAEKBAQAAgESAyoCFRp/IFRoZSB2
ZXJzaW9uIG9mIHRoZSBHbyBtb2R1bGUuIE11c3QgYmUgYSB2YWxpZCBjYW5vbmljYWwgdmVy
c2lvbiBhcyBkZWZpbmVkCiBpbiBodHRwczovL2dvLmRldi9yZWYvbW9kI2dsb3MtY2Fub25p
Y2FsLXZlcnNpb24uCgoMCgUEAAIBBRIDKgIICgwKBQQAAgEBEgMqCRAKDAoFBAACAQMSAyoT
FApECgQEAAICEgQtAi4yGjYgT3V0cHV0IG9ubHkuIFRoZSB0aW1lIHdoZW4gdGhlIEdvIG1v
ZHVsZSBpcyBjcmVhdGVkLgoKDAoFBAACAgYSAy0CGwoMCgUEAAICARIDLRwnCgwKBQQAAgID
EgMtKisKDAoFBAACAggSAy4GMQoPCggEAAICCJwIABIDLgcwCkQKBAQAAgMSBDECMjIaNiBP
dXRwdXQgb25seS4gVGhlIHRpbWUgd2hlbiB0aGUgR28gbW9kdWxlIGlzIHVwZGF0ZWQuCgoM
CgUEAAIDBhIDMQIbCgwKBQQAAgMBEgMxHCcKDAoFBAACAwMSAzEqKwoMCgUEAAIDCBIDMgYx
Cg8KCAQAAgMInAgAEgMyBzBiBnByb3RvMw==
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Devtools::Artifactregistry::V1::Go::GoModule ===
    # Fields for GoModule
    # Field: name Type: 9 ()
    # Field: version Type: 9 ()
    # Field: create_time Type: 11 (.google.protobuf.Timestamp)
    # Field: update_time Type: 11 (.google.protobuf.Timestamp)

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Devtools::Artifactregistry::V1::Go - Compiled Protocol Buffers messages for google/devtools/artifactregistry/v1/go.proto

=head1 SYNOPSIS

    use Google::Devtools::Artifactregistry::V1::Go;

    my $msg = Google::Devtools::Artifactregistry::V1::Go::GoModule->new({
        name => $name,
        version => $version,
        create_time => $create_time,
        update_time => $update_time,
    });

    # Read or update a field
    my $val = $msg->name();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Devtools::Artifactregistry::V1::Go::GoModule->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/devtools/artifactregistry/v1/go.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Devtools::Artifactregistry::V1::Go::GoModule

GoModule represents a Go module.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

The resource name of a Go module.

=item * C<< $msg->version() >> / C<< $msg->version($value) >>

Type: C<String>

The version of the Go module. Must be a valid canonical version as defined
in https://go.dev/ref/mod#glos-canonical-version.

=item * C<< $msg->create_time() >> / C<< $msg->create_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Output only. The time when the Go module is created.

=item * C<< $msg->update_time() >> / C<< $msg->update_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Output only. The time when the Go module is updated.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Devtools::Artifactregistry::V1::Go::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
