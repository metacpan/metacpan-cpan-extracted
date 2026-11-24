package Google::Cloud::Alloydb::V1::CsqlResources;

use strict;
use warnings;

our $VERSION = '0.14';

use Protobuf::Message;
use Protobuf::DescriptorPool;
use Protobuf::Internal qw(:all);
use MIME::Base64;

BEGIN {
    eval { require Google::Api::FieldBehavior };
    my $descriptor_b64 = <<'EOF';
Cixnb29nbGUvY2xvdWQvYWxsb3lkYi92MS9jc3FsX3Jlc291cmNlcy5wcm90bxIXZ29vZ2xl
LmNsb3VkLmFsbG95ZGIudjEaH2dvb2dsZS9hcGkvZmllbGRfYmVoYXZpb3IucHJvdG8iggEK
F0Nsb3VkU1FMQmFja3VwUnVuU291cmNlEhgKB3Byb2plY3QYASABKAlSB3Byb2plY3QSJAoL
aW5zdGFuY2VfaWQYAiABKAlCA+BBAlIKaW5zdGFuY2VJZBInCg1iYWNrdXBfcnVuX2lkGAMg
ASgDQgPgQQJSC2JhY2t1cFJ1bklkQrsBChtjb20uZ29vZ2xlLmNsb3VkLmFsbG95ZGIudjFC
EkNzcWxSZXNvdXJjZXNQcm90b1ABWjVjbG91ZC5nb29nbGUuY29tL2dvL2FsbG95ZGIvYXBp
djEvYWxsb3lkYnBiO2FsbG95ZGJwYqoCF0dvb2dsZS5DbG91ZC5BbGxveURiLlYxygIXR29v
Z2xlXENsb3VkXEFsbG95RGJcVjHqAhpHb29nbGU6OkNsb3VkOjpBbGxveURCOjpWMUrQCQoG
EgQOACcBCrwECgEMEgMOABIysQQgQ29weXJpZ2h0IDIwMjUgR29vZ2xlIExMQwoKIExpY2Vu
c2VkIHVuZGVyIHRoZSBBcGFjaGUgTGljZW5zZSwgVmVyc2lvbiAyLjAgKHRoZSAiTGljZW5z
ZSIpOwogeW91IG1heSBub3QgdXNlIHRoaXMgZmlsZSBleGNlcHQgaW4gY29tcGxpYW5jZSB3
aXRoIHRoZSBMaWNlbnNlLgogWW91IG1heSBvYnRhaW4gYSBjb3B5IG9mIHRoZSBMaWNlbnNl
IGF0CgogICAgIGh0dHA6Ly93d3cuYXBhY2hlLm9yZy9saWNlbnNlcy9MSUNFTlNFLTIuMAoK
IFVubGVzcyByZXF1aXJlZCBieSBhcHBsaWNhYmxlIGxhdyBvciBhZ3JlZWQgdG8gaW4gd3Jp
dGluZywgc29mdHdhcmUKIGRpc3RyaWJ1dGVkIHVuZGVyIHRoZSBMaWNlbnNlIGlzIGRpc3Ry
aWJ1dGVkIG9uIGFuICJBUyBJUyIgQkFTSVMsCiBXSVRIT1VUIFdBUlJBTlRJRVMgT1IgQ09O
RElUSU9OUyBPRiBBTlkgS0lORCwgZWl0aGVyIGV4cHJlc3Mgb3IgaW1wbGllZC4KIFNlZSB0
aGUgTGljZW5zZSBmb3IgdGhlIHNwZWNpZmljIGxhbmd1YWdlIGdvdmVybmluZyBwZXJtaXNz
aW9ucyBhbmQKIGxpbWl0YXRpb25zIHVuZGVyIHRoZSBMaWNlbnNlLgoKCAoBAhIDEAAgCgkK
AgMAEgMSACkKCAoBCBIDFAA0CgkKAgglEgMUADQKCAoBCBIDFQBMCgkKAggLEgMVAEwKCAoB
CBIDFgAiCgkKAggKEgMWACIKCAoBCBIDFwAzCgkKAggIEgMXADMKCAoBCBIDGAA0CgkKAggB
EgMYADQKCAoBCBIDGQA0CgkKAggpEgMZADQKCAoBCBIDGgAzCgkKAggtEgMaADMKMgoCBAAS
BB0AJwEaJiBUaGUgc291cmNlIENsb3VkU1FMIGJhY2t1cCByZXNvdXJjZS4KCgoKAwQAARID
HQgfCnkKBAQAAgASAyACFRpsIFRoZSBwcm9qZWN0IElEIG9mIHRoZSBzb3VyY2UgQ2xvdWRT
UUwgaW5zdGFuY2UuIFRoaXMgc2hvdWxkIGJlIHRoZSBzYW1lIGFzCiB0aGUgQWxsb3lEQiBj
bHVzdGVyJ3MgcHJvamVjdC4KCgwKBQQAAgAFEgMgAggKDAoFBAACAAESAyAJEAoMCgUEAAIA
AxIDIBMUCjIKBAQAAgESAyMCQholIFJlcXVpcmVkLiBUaGUgQ2xvdWRTUUwgaW5zdGFuY2Ug
SUQuCgoMCgUEAAIBBRIDIwIICgwKBQQAAgEBEgMjCRQKDAoFBAACAQMSAyMXGAoMCgUEAAIB
CBIDIxlBCg8KCAQAAgEInAgAEgMjGkAKNAoEBAACAhIDJgJDGicgUmVxdWlyZWQuIFRoZSBD
bG91ZFNRTCBiYWNrdXAgcnVuIElELgoKDAoFBAACAgUSAyYCBwoMCgUEAAICARIDJggVCgwK
BQQAAgIDEgMmGBkKDAoFBAACAggSAyYaQgoPCggEAAICCJwIABIDJhtBYgZwcm90bzM=
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Alloydb::V1::CsqlResources::CloudSQLBackupRunSource ===
    # Fields for CloudSQLBackupRunSource
    # Field: project Type: 9 ()
    # Field: instance_id Type: 9 ()
    # Field: backup_run_id Type: 3 ()

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Alloydb::V1::CsqlResources - Compiled Protocol Buffers messages for google/cloud/alloydb/v1/csql_resources.proto

=head1 SYNOPSIS

    use Google::Cloud::Alloydb::V1::CsqlResources;

    my $msg = Google::Cloud::Alloydb::V1::CsqlResources::CloudSQLBackupRunSource->new({
        project => $project,
        instance_id => $instance_id,
        backup_run_id => $backup_run_id,
    });

    # Read or update a field
    my $val = $msg->project();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Alloydb::V1::CsqlResources::CloudSQLBackupRunSource->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/alloydb/v1/csql_resources.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Alloydb::V1::CsqlResources::CloudSQLBackupRunSource

The source CloudSQL backup resource.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->project() >> / C<< $msg->project($value) >>

Type: C<String>

The project ID of the source CloudSQL instance. This should be the same as
the AlloyDB cluster's project.

=item * C<< $msg->instance_id() >> / C<< $msg->instance_id($value) >>

Type: C<String>

Required. The CloudSQL instance ID.

=item * C<< $msg->backup_run_id() >> / C<< $msg->backup_run_id($value) >>

Type: C<Int64>

Required. The CloudSQL backup run ID.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Alloydb::V1::CsqlResources::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
