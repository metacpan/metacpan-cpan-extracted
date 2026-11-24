package Google::Cloud::Bigquery::V2::UdfResource;

use strict;
use warnings;

our $VERSION = '0.14';

use Protobuf::Message;
use Protobuf::DescriptorPool;
use Protobuf::Internal qw(:all);
use MIME::Base64;

BEGIN {
    eval { require Google::Protobuf::Wrappers };
    my $descriptor_b64 = <<'EOF';
Citnb29nbGUvY2xvdWQvYmlncXVlcnkvdjIvdWRmX3Jlc291cmNlLnByb3RvEhhnb29nbGUu
Y2xvdWQuYmlncXVlcnkudjIaHmdvb2dsZS9wcm90b2J1Zi93cmFwcGVycy5wcm90byKdAQob
VXNlckRlZmluZWRGdW5jdGlvblJlc291cmNlEj8KDHJlc291cmNlX3VyaRgBIAEoCzIcLmdv
b2dsZS5wcm90b2J1Zi5TdHJpbmdWYWx1ZVILcmVzb3VyY2VVcmkSPQoLaW5saW5lX2NvZGUY
AiABKAsyHC5nb29nbGUucHJvdG9idWYuU3RyaW5nVmFsdWVSCmlubGluZUNvZGVCZQocY29t
Lmdvb2dsZS5jbG91ZC5iaWdxdWVyeS52MkIIVWRmUHJvdG9aO2Nsb3VkLmdvb2dsZS5jb20v
Z28vYmlncXVlcnkvdjIvYXBpdjIvYmlncXVlcnlwYjtiaWdxdWVyeXBiSuELCgYSBA4AKQEK
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
ZAogbGltaXRhdGlvbnMgdW5kZXIgdGhlIExpY2Vuc2UuCgoICgECEgMQACEKCQoCAwASAxIA
KAoICgEIEgMUAFIKCQoCCAsSAxQAUgoICgEIEgMVACkKCQoCCAgSAxUAKQoICgEIEgMWADUK
CQoCCAESAxYANQqsAwoCBAASBCAAKQEanwMKIFRoaXMgaXMgdXNlZCBmb3IgZGVmaW5pbmcg
VXNlciBEZWZpbmVkIEZ1bmN0aW9uIChVREYpIHJlc291cmNlcyBvbmx5IHdoZW4KIHVzaW5n
IGxlZ2FjeSBTUUwuICBVc2VycyBvZiBHb29nbGVTUUwgc2hvdWxkIGxldmVyYWdlIGVpdGhl
ciBEREwgKGUuZy4KIENSRUFURSBbVEVNUE9SQVJZXSBGVU5DVElPTiAuLi4gKSBvciB0aGUg
Um91dGluZXMgQVBJIHRvIGRlZmluZSBVREYKIHJlc291cmNlcy4KCiBGb3IgYWRkaXRpb25h
bCBpbmZvcm1hdGlvbiBvbiBtaWdyYXRpbmcsIHNlZToKIGh0dHBzOi8vY2xvdWQuZ29vZ2xl
LmNvbS9iaWdxdWVyeS9kb2NzL3JlZmVyZW5jZS9zdGFuZGFyZC1zcWwvbWlncmF0aW5nLWZy
b20tbGVnYWN5LXNxbCNkaWZmZXJlbmNlc19pbl91c2VyLWRlZmluZWRfamF2YXNjcmlwdF9m
dW5jdGlvbnMKCgoKAwQAARIDIAgjCmYKBAQAAgASAyMCLxpZIFtQaWNrIG9uZV0gQSBjb2Rl
IHJlc291cmNlIHRvIGxvYWQgZnJvbSBhIEdvb2dsZSBDbG91ZCBTdG9yYWdlIFVSSQogKGdz
Oi8vYnVja2V0L3BhdGgpLgoKDAoFBAACAAYSAyMCHQoMCgUEAAIAARIDIx4qCgwKBQQAAgAD
EgMjLS4KzAEKBAQAAgESAygCLhq+ASBbUGljayBvbmVdIEFuIGlubGluZSByZXNvdXJjZSB0
aGF0IGNvbnRhaW5zIGNvZGUgZm9yIGEgdXNlci1kZWZpbmVkCiBmdW5jdGlvbiAoVURGKS4g
UHJvdmlkaW5nIGEgaW5saW5lIGNvZGUgcmVzb3VyY2UgaXMgZXF1aXZhbGVudCB0byBwcm92
aWRpbmcKIGEgVVJJIGZvciBhIGZpbGUgY29udGFpbmluZyB0aGUgc2FtZSBjb2RlLgoKDAoF
BAACAQYSAygCHQoMCgUEAAIBARIDKB4pCgwKBQQAAgEDEgMoLC1iBnByb3RvMw==
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Bigquery::V2::UdfResource::UserDefinedFunctionResource ===
    # Fields for UserDefinedFunctionResource
    # Field: resource_uri Type: 11 (.google.protobuf.StringValue)
    # Field: inline_code Type: 11 (.google.protobuf.StringValue)

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Bigquery::V2::UdfResource - Compiled Protocol Buffers messages for google/cloud/bigquery/v2/udf_resource.proto

=head1 SYNOPSIS

    use Google::Cloud::Bigquery::V2::UdfResource;

    my $msg = Google::Cloud::Bigquery::V2::UdfResource::UserDefinedFunctionResource->new({
        resource_uri => $resource_uri,
        inline_code => $inline_code,
    });

    # Read or update a field
    my $val = $msg->resource_uri();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Bigquery::V2::UdfResource::UserDefinedFunctionResource->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/bigquery/v2/udf_resource.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Bigquery::V2::UdfResource::UserDefinedFunctionResource


This is used for defining User Defined Function (UDF) resources only when
using legacy SQL.  Users of GoogleSQL should leverage either DDL (e.g.
CREATE [TEMPORARY] FUNCTION ... ) or the Routines API to define UDF
resources.

For additional information on migrating, see:
https://cloud.google.com/bigquery/docs/reference/standard-sql/migrating-from-legacy-sql#differences_in_user-defined_javascript_functions

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->resource_uri() >> / C<< $msg->resource_uri($value) >>

Type: C<Message> (L<Google::Protobuf::Wrappers::StringValue>)

[Pick one] A code resource to load from a Google Cloud Storage URI
(gs://bucket/path).

=item * C<< $msg->inline_code() >> / C<< $msg->inline_code($value) >>

Type: C<Message> (L<Google::Protobuf::Wrappers::StringValue>)

[Pick one] An inline resource that contains code for a user-defined
function (UDF). Providing a inline code resource is equivalent to providing
a URI for a file containing the same code.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Bigquery::V2::UdfResource::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
