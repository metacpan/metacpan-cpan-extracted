package Google::Cloud::Alloydb::V1alpha::CsqlResources;

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
CjFnb29nbGUvY2xvdWQvYWxsb3lkYi92MWFscGhhL2NzcWxfcmVzb3VyY2VzLnByb3RvEhxn
b29nbGUuY2xvdWQuYWxsb3lkYi52MWFscGhhGh9nb29nbGUvYXBpL2ZpZWxkX2JlaGF2aW9y
LnByb3RvIoIBChdDbG91ZFNRTEJhY2t1cFJ1blNvdXJjZRIYCgdwcm9qZWN0GAEgASgJUgdw
cm9qZWN0EiQKC2luc3RhbmNlX2lkGAIgASgJQgPgQQJSCmluc3RhbmNlSWQSJwoNYmFja3Vw
X3J1bl9pZBgDIAEoA0ID4EECUgtiYWNrdXBSdW5JZELUAQogY29tLmdvb2dsZS5jbG91ZC5h
bGxveWRiLnYxYWxwaGFCEkNzcWxSZXNvdXJjZXNQcm90b1ABWjpjbG91ZC5nb29nbGUuY29t
L2dvL2FsbG95ZGIvYXBpdjFhbHBoYS9hbGxveWRicGI7YWxsb3lkYnBiqgIcR29vZ2xlLkNs
b3VkLkFsbG95RGIuVjFBbHBoYcoCHEdvb2dsZVxDbG91ZFxBbGxveURiXFYxYWxwaGHqAh9H
b29nbGU6OkNsb3VkOjpBbGxveURCOjpWMWFscGhhStAJCgYSBA4AJwEKvAQKAQwSAw4AEjKx
BCBDb3B5cmlnaHQgMjAyNSBHb29nbGUgTExDCgogTGljZW5zZWQgdW5kZXIgdGhlIEFwYWNo
ZSBMaWNlbnNlLCBWZXJzaW9uIDIuMCAodGhlICJMaWNlbnNlIik7CiB5b3UgbWF5IG5vdCB1
c2UgdGhpcyBmaWxlIGV4Y2VwdCBpbiBjb21wbGlhbmNlIHdpdGggdGhlIExpY2Vuc2UuCiBZ
b3UgbWF5IG9idGFpbiBhIGNvcHkgb2YgdGhlIExpY2Vuc2UgYXQKCiAgICAgaHR0cDovL3d3
dy5hcGFjaGUub3JnL2xpY2Vuc2VzL0xJQ0VOU0UtMi4wCgogVW5sZXNzIHJlcXVpcmVkIGJ5
IGFwcGxpY2FibGUgbGF3IG9yIGFncmVlZCB0byBpbiB3cml0aW5nLCBzb2Z0d2FyZQogZGlz
dHJpYnV0ZWQgdW5kZXIgdGhlIExpY2Vuc2UgaXMgZGlzdHJpYnV0ZWQgb24gYW4gIkFTIElT
IiBCQVNJUywKIFdJVEhPVVQgV0FSUkFOVElFUyBPUiBDT05ESVRJT05TIE9GIEFOWSBLSU5E
LCBlaXRoZXIgZXhwcmVzcyBvciBpbXBsaWVkLgogU2VlIHRoZSBMaWNlbnNlIGZvciB0aGUg
c3BlY2lmaWMgbGFuZ3VhZ2UgZ292ZXJuaW5nIHBlcm1pc3Npb25zIGFuZAogbGltaXRhdGlv
bnMgdW5kZXIgdGhlIExpY2Vuc2UuCgoICgECEgMQACUKCQoCAwASAxIAKQoICgEIEgMUADkK
CQoCCCUSAxQAOQoICgEIEgMVAFEKCQoCCAsSAxUAUQoICgEIEgMWACIKCQoCCAoSAxYAIgoI
CgEIEgMXADMKCQoCCAgSAxcAMwoICgEIEgMYADkKCQoCCAESAxgAOQoICgEIEgMZADkKCQoC
CCkSAxkAOQoICgEIEgMaADgKCQoCCC0SAxoAOAoyCgIEABIEHQAnARomIFRoZSBzb3VyY2Ug
Q2xvdWRTUUwgYmFja3VwIHJlc291cmNlLgoKCgoDBAABEgMdCB8KeQoEBAACABIDIAIVGmwg
VGhlIHByb2plY3QgSUQgb2YgdGhlIHNvdXJjZSBDbG91ZFNRTCBpbnN0YW5jZS4gVGhpcyBz
aG91bGQgYmUgdGhlIHNhbWUgYXMKIHRoZSBBbGxveURCIGNsdXN0ZXIncyBwcm9qZWN0LgoK
DAoFBAACAAUSAyACCAoMCgUEAAIAARIDIAkQCgwKBQQAAgADEgMgExQKMgoEBAACARIDIwJC
GiUgUmVxdWlyZWQuIFRoZSBDbG91ZFNRTCBpbnN0YW5jZSBJRC4KCgwKBQQAAgEFEgMjAggK
DAoFBAACAQESAyMJFAoMCgUEAAIBAxIDIxcYCgwKBQQAAgEIEgMjGUEKDwoIBAACAQicCAAS
AyMaQAo0CgQEAAICEgMmAkMaJyBSZXF1aXJlZC4gVGhlIENsb3VkU1FMIGJhY2t1cCBydW4g
SUQuCgoMCgUEAAICBRIDJgIHCgwKBQQAAgIBEgMmCBUKDAoFBAACAgMSAyYYGQoMCgUEAAIC
CBIDJhpCCg8KCAQAAgIInAgAEgMmG0FiBnByb3RvMw==
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Alloydb::V1alpha::CsqlResources::CloudSQLBackupRunSource ===
    # Fields for CloudSQLBackupRunSource
    # Field: project Type: 9 ()
    # Field: instance_id Type: 9 ()
    # Field: backup_run_id Type: 3 ()

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Alloydb::V1alpha::CsqlResources - Compiled Protocol Buffers messages for google/cloud/alloydb/v1alpha/csql_resources.proto

=head1 SYNOPSIS

    use Google::Cloud::Alloydb::V1alpha::CsqlResources;

    my $msg = Google::Cloud::Alloydb::V1alpha::CsqlResources::CloudSQLBackupRunSource->new({
        project => $project,
        instance_id => $instance_id,
        backup_run_id => $backup_run_id,
    });

    # Read or update a field
    my $val = $msg->project();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Alloydb::V1alpha::CsqlResources::CloudSQLBackupRunSource->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/alloydb/v1alpha/csql_resources.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Alloydb::V1alpha::CsqlResources::CloudSQLBackupRunSource

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

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Alloydb::V1alpha::CsqlResources::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
