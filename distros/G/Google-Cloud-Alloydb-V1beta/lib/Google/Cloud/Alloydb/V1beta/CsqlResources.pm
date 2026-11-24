package Google::Cloud::Alloydb::V1beta::CsqlResources;

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
CjBnb29nbGUvY2xvdWQvYWxsb3lkYi92MWJldGEvY3NxbF9yZXNvdXJjZXMucHJvdG8SG2dv
b2dsZS5jbG91ZC5hbGxveWRiLnYxYmV0YRofZ29vZ2xlL2FwaS9maWVsZF9iZWhhdmlvci5w
cm90byKCAQoXQ2xvdWRTUUxCYWNrdXBSdW5Tb3VyY2USGAoHcHJvamVjdBgBIAEoCVIHcHJv
amVjdBIkCgtpbnN0YW5jZV9pZBgCIAEoCUID4EECUgppbnN0YW5jZUlkEicKDWJhY2t1cF9y
dW5faWQYAyABKANCA+BBAlILYmFja3VwUnVuSWRCzwEKH2NvbS5nb29nbGUuY2xvdWQuYWxs
b3lkYi52MWJldGFCEkNzcWxSZXNvdXJjZXNQcm90b1ABWjljbG91ZC5nb29nbGUuY29tL2dv
L2FsbG95ZGIvYXBpdjFiZXRhL2FsbG95ZGJwYjthbGxveWRicGKqAhtHb29nbGUuQ2xvdWQu
QWxsb3lEYi5WMUJldGHKAhtHb29nbGVcQ2xvdWRcQWxsb3lEYlxWMWJldGHqAh5Hb29nbGU6
OkNsb3VkOjpBbGxveURCOjpWMWJldGFK0AkKBhIEDgAnAQq8BAoBDBIDDgASMrEEIENvcHly
aWdodCAyMDI1IEdvb2dsZSBMTEMKCiBMaWNlbnNlZCB1bmRlciB0aGUgQXBhY2hlIExpY2Vu
c2UsIFZlcnNpb24gMi4wICh0aGUgIkxpY2Vuc2UiKTsKIHlvdSBtYXkgbm90IHVzZSB0aGlz
IGZpbGUgZXhjZXB0IGluIGNvbXBsaWFuY2Ugd2l0aCB0aGUgTGljZW5zZS4KIFlvdSBtYXkg
b2J0YWluIGEgY29weSBvZiB0aGUgTGljZW5zZSBhdAoKICAgICBodHRwOi8vd3d3LmFwYWNo
ZS5vcmcvbGljZW5zZXMvTElDRU5TRS0yLjAKCiBVbmxlc3MgcmVxdWlyZWQgYnkgYXBwbGlj
YWJsZSBsYXcgb3IgYWdyZWVkIHRvIGluIHdyaXRpbmcsIHNvZnR3YXJlCiBkaXN0cmlidXRl
ZCB1bmRlciB0aGUgTGljZW5zZSBpcyBkaXN0cmlidXRlZCBvbiBhbiAiQVMgSVMiIEJBU0lT
LAogV0lUSE9VVCBXQVJSQU5USUVTIE9SIENPTkRJVElPTlMgT0YgQU5ZIEtJTkQsIGVpdGhl
ciBleHByZXNzIG9yIGltcGxpZWQuCiBTZWUgdGhlIExpY2Vuc2UgZm9yIHRoZSBzcGVjaWZp
YyBsYW5ndWFnZSBnb3Zlcm5pbmcgcGVybWlzc2lvbnMgYW5kCiBsaW1pdGF0aW9ucyB1bmRl
ciB0aGUgTGljZW5zZS4KCggKAQISAxAAJAoJCgIDABIDEgApCggKAQgSAxQAOAoJCgIIJRID
FAA4CggKAQgSAxUAUAoJCgIICxIDFQBQCggKAQgSAxYAIgoJCgIIChIDFgAiCggKAQgSAxcA
MwoJCgIICBIDFwAzCggKAQgSAxgAOAoJCgIIARIDGAA4CggKAQgSAxkAOAoJCgIIKRIDGQA4
CggKAQgSAxoANwoJCgIILRIDGgA3CjIKAgQAEgQdACcBGiYgVGhlIHNvdXJjZSBDbG91ZFNR
TCBiYWNrdXAgcmVzb3VyY2UuCgoKCgMEAAESAx0IHwp5CgQEAAIAEgMgAhUabCBUaGUgcHJv
amVjdCBJRCBvZiB0aGUgc291cmNlIENsb3VkU1FMIGluc3RhbmNlLiBUaGlzIHNob3VsZCBi
ZSB0aGUgc2FtZSBhcwogdGhlIEFsbG95REIgY2x1c3RlcidzIHByb2plY3QuCgoMCgUEAAIA
BRIDIAIICgwKBQQAAgABEgMgCRAKDAoFBAACAAMSAyATFAoyCgQEAAIBEgMjAkIaJSBSZXF1
aXJlZC4gVGhlIENsb3VkU1FMIGluc3RhbmNlIElELgoKDAoFBAACAQUSAyMCCAoMCgUEAAIB
ARIDIwkUCgwKBQQAAgEDEgMjFxgKDAoFBAACAQgSAyMZQQoPCggEAAIBCJwIABIDIxpACjQK
BAQAAgISAyYCQxonIFJlcXVpcmVkLiBUaGUgQ2xvdWRTUUwgYmFja3VwIHJ1biBJRC4KCgwK
BQQAAgIFEgMmAgcKDAoFBAACAgESAyYIFQoMCgUEAAICAxIDJhgZCgwKBQQAAgIIEgMmGkIK
DwoIBAACAgicCAASAyYbQWIGcHJvdG8z
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Alloydb::V1beta::CsqlResources::CloudSQLBackupRunSource ===
    # Fields for CloudSQLBackupRunSource
    # Field: project Type: 9 ()
    # Field: instance_id Type: 9 ()
    # Field: backup_run_id Type: 3 ()

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Alloydb::V1beta::CsqlResources - Compiled Protocol Buffers messages for google/cloud/alloydb/v1beta/csql_resources.proto

=head1 SYNOPSIS

    use Google::Cloud::Alloydb::V1beta::CsqlResources;

    my $msg = Google::Cloud::Alloydb::V1beta::CsqlResources::CloudSQLBackupRunSource->new({
        project => $project,
        instance_id => $instance_id,
        backup_run_id => $backup_run_id,
    });

    # Read or update a field
    my $val = $msg->project();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Alloydb::V1beta::CsqlResources::CloudSQLBackupRunSource->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/alloydb/v1beta/csql_resources.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Alloydb::V1beta::CsqlResources::CloudSQLBackupRunSource

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

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Alloydb::V1beta::CsqlResources::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
