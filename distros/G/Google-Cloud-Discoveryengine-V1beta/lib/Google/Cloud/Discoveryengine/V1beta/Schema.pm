package Google::Cloud::Discoveryengine::V1beta::Schema;

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
    eval { require Google::Protobuf::Struct };
    my $descriptor_b64 = <<'EOF';
CjBnb29nbGUvY2xvdWQvZGlzY292ZXJ5ZW5naW5lL3YxYmV0YS9zY2hlbWEucHJvdG8SI2dv
b2dsZS5jbG91ZC5kaXNjb3ZlcnllbmdpbmUudjFiZXRhGh9nb29nbGUvYXBpL2ZpZWxkX2Jl
aGF2aW9yLnByb3RvGhlnb29nbGUvYXBpL3Jlc291cmNlLnByb3RvGhxnb29nbGUvcHJvdG9i
dWYvc3RydWN0LnByb3RvIvkCCgZTY2hlbWESPgoNc3RydWN0X3NjaGVtYRgCIAEoCzIXLmdv
b2dsZS5wcm90b2J1Zi5TdHJ1Y3RIAFIMc3RydWN0U2NoZW1hEiEKC2pzb25fc2NoZW1hGAMg
ASgJSABSCmpzb25TY2hlbWESFwoEbmFtZRgBIAEoCUID4EEFUgRuYW1lOugB6kHkAQolZGlz
Y292ZXJ5ZW5naW5lLmdvb2dsZWFwaXMuY29tL1NjaGVtYRJQcHJvamVjdHMve3Byb2plY3R9
L2xvY2F0aW9ucy97bG9jYXRpb259L2RhdGFTdG9yZXMve2RhdGFfc3RvcmV9L3NjaGVtYXMv
e3NjaGVtYX0SaXByb2plY3RzL3twcm9qZWN0fS9sb2NhdGlvbnMve2xvY2F0aW9ufS9jb2xs
ZWN0aW9ucy97Y29sbGVjdGlvbn0vZGF0YVN0b3Jlcy97ZGF0YV9zdG9yZX0vc2NoZW1hcy97
c2NoZW1hfUIICgZzY2hlbWFCkgIKJ2NvbS5nb29nbGUuY2xvdWQuZGlzY292ZXJ5ZW5naW5l
LnYxYmV0YUILU2NoZW1hUHJvdG9QAVpRY2xvdWQuZ29vZ2xlLmNvbS9nby9kaXNjb3Zlcnll
bmdpbmUvYXBpdjFiZXRhL2Rpc2NvdmVyeWVuZ2luZXBiO2Rpc2NvdmVyeWVuZ2luZXBiogIP
RElTQ09WRVJZRU5HSU5FqgIjR29vZ2xlLkNsb3VkLkRpc2NvdmVyeUVuZ2luZS5WMUJldGHK
AiNHb29nbGVcQ2xvdWRcRGlzY292ZXJ5RW5naW5lXFYxYmV0YeoCJkdvb2dsZTo6Q2xvdWQ6
OkRpc2NvdmVyeUVuZ2luZTo6VjFiZXRhSs8NCgYSBA4AOQEKvAQKAQwSAw4AEjKxBCBDb3B5
cmlnaHQgMjAyNiBHb29nbGUgTExDCgogTGljZW5zZWQgdW5kZXIgdGhlIEFwYWNoZSBMaWNl
bnNlLCBWZXJzaW9uIDIuMCAodGhlICJMaWNlbnNlIik7CiB5b3UgbWF5IG5vdCB1c2UgdGhp
cyBmaWxlIGV4Y2VwdCBpbiBjb21wbGlhbmNlIHdpdGggdGhlIExpY2Vuc2UuCiBZb3UgbWF5
IG9idGFpbiBhIGNvcHkgb2YgdGhlIExpY2Vuc2UgYXQKCiAgICAgaHR0cDovL3d3dy5hcGFj
aGUub3JnL2xpY2Vuc2VzL0xJQ0VOU0UtMi4wCgogVW5sZXNzIHJlcXVpcmVkIGJ5IGFwcGxp
Y2FibGUgbGF3IG9yIGFncmVlZCB0byBpbiB3cml0aW5nLCBzb2Z0d2FyZQogZGlzdHJpYnV0
ZWQgdW5kZXIgdGhlIExpY2Vuc2UgaXMgZGlzdHJpYnV0ZWQgb24gYW4gIkFTIElTIiBCQVNJ
UywKIFdJVEhPVVQgV0FSUkFOVElFUyBPUiBDT05ESVRJT05TIE9GIEFOWSBLSU5ELCBlaXRo
ZXIgZXhwcmVzcyBvciBpbXBsaWVkLgogU2VlIHRoZSBMaWNlbnNlIGZvciB0aGUgc3BlY2lm
aWMgbGFuZ3VhZ2UgZ292ZXJuaW5nIHBlcm1pc3Npb25zIGFuZAogbGltaXRhdGlvbnMgdW5k
ZXIgdGhlIExpY2Vuc2UuCgoICgECEgMQACwKCQoCAwASAxIAKQoJCgIDARIDEwAjCgkKAgMC
EgMUACYKCAoBCBIDFgBACgkKAgglEgMWAEAKCAoBCBIDFwBoCgkKAggLEgMXAGgKCAoBCBID
GAAiCgkKAggKEgMYACIKCAoBCBIDGQAsCgkKAggIEgMZACwKCAoBCBIDGgBACgkKAggBEgMa
AEAKCAoBCBIDGwAtCgkKAggkEgMbAC0KCAoBCBIDHABACgkKAggpEgMcAEAKCAoBCBIDHQA/
CgkKAggtEgMdAD8KSgoCBAASBCAAOQEaPiBEZWZpbmVzIHRoZSBzdHJ1Y3R1cmUgYW5kIGxh
eW91dCBvZiBhIHR5cGUgb2YgZG9jdW1lbnQgZGF0YS4KCgoKAwQAARIDIAgOCgsKAwQABxIE
IQIlBAoNCgUEAAedCBIEIQIlBAqIAgoEBAAIABIEKwIxAxr5ASBTY2hlbWEgcmVwcmVzZW50
YXRpb24uIE9uZSBvZgogW3N0cnVjdF9zY2hlbWFdW2dvb2dsZS5jbG91ZC5kaXNjb3Zlcnll
bmdpbmUudjFiZXRhLlNjaGVtYS5zdHJ1Y3Rfc2NoZW1hXQogb3IgW2pzb25fc2NoZW1hXVtn
b29nbGUuY2xvdWQuZGlzY292ZXJ5ZW5naW5lLnYxYmV0YS5TY2hlbWEuanNvbl9zY2hlbWFd
CiBzaG91bGQgYmUgcHJvdmlkZWQgb3RoZXJ3aXNlIGFuIGBJTlZBTElEX0FSR1VNRU5UYCBl
cnJvciBpcyB0aHJvd24uCgoMCgUEAAgAARIDKwgOCjsKBAQAAgASAy0ELRouIFRoZSBzdHJ1
Y3R1cmVkIHJlcHJlc2VudGF0aW9uIG9mIHRoZSBzY2hlbWEuCgoMCgUEAAIABhIDLQQaCgwK
BQQAAgABEgMtGygKDAoFBAACAAMSAy0rLAo1CgQEAAIBEgMwBBsaKCBUaGUgSlNPTiByZXBy
ZXNlbnRhdGlvbiBvZiB0aGUgc2NoZW1hLgoKDAoFBAACAQUSAzAECgoMCgUEAAIBARIDMAsW
CgwKBQQAAgEDEgMwGRoKlAIKBAQAAgISAzgCPBqGAiBJbW11dGFibGUuIFRoZSBmdWxsIHJl
c291cmNlIG5hbWUgb2YgdGhlIHNjaGVtYSwgaW4gdGhlIGZvcm1hdCBvZgogYHByb2plY3Rz
L3twcm9qZWN0fS9sb2NhdGlvbnMve2xvY2F0aW9ufS9jb2xsZWN0aW9ucy97Y29sbGVjdGlv
bn0vZGF0YVN0b3Jlcy97ZGF0YV9zdG9yZX0vc2NoZW1hcy97c2NoZW1hfWAuCgogVGhpcyBm
aWVsZCBtdXN0IGJlIGEgVVRGLTggZW5jb2RlZCBzdHJpbmcgd2l0aCBhIGxlbmd0aCBsaW1p
dCBvZiAxMDI0CiBjaGFyYWN0ZXJzLgoKDAoFBAACAgUSAzgCCAoMCgUEAAICARIDOAkNCgwK
BQQAAgIDEgM4EBEKDAoFBAACAggSAzgSOwoPCggEAAICCJwIABIDOBM6YgZwcm90bzM=
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Discoveryengine::V1beta::Schema::Schema ===
    # Fields for Schema
    # Field: struct_schema Type: 11 (.google.protobuf.Struct)
    # Field: json_schema Type: 9 ()
    # Field: name Type: 9 ()

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Discoveryengine::V1beta::Schema - Compiled Protocol Buffers messages for google/cloud/discoveryengine/v1beta/schema.proto

=head1 SYNOPSIS

    use Google::Cloud::Discoveryengine::V1beta::Schema;

    my $msg = Google::Cloud::Discoveryengine::V1beta::Schema::Schema->new({
        struct_schema => $struct_schema,
        json_schema => $json_schema,
        name => $name,
    });

    # Read or update a field
    my $val = $msg->struct_schema();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Discoveryengine::V1beta::Schema::Schema->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/discoveryengine/v1beta/schema.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Discoveryengine::V1beta::Schema::Schema

Defines the structure and layout of a type of document data.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->struct_schema() >> / C<< $msg->struct_schema($value) >>

Type: C<Message> (L<Google::Protobuf::Struct::Struct>)

The structured representation of the schema.

=item * C<< $msg->json_schema() >> / C<< $msg->json_schema($value) >>

Type: C<String>

The JSON representation of the schema.

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Immutable. The full resource name of the schema, in the format of
`projects/{project}/locations/{location}/collections/{collection}/dataStores/{data_store}/schemas/{schema}`.

This field must be a UTF-8 encoded string with a length limit of 1024
characters.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Discoveryengine::V1beta::Schema::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
