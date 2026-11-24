package Google::Cloud::Discoveryengine::V1::Schema;

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
Cixnb29nbGUvY2xvdWQvZGlzY292ZXJ5ZW5naW5lL3YxL3NjaGVtYS5wcm90bxIfZ29vZ2xl
LmNsb3VkLmRpc2NvdmVyeWVuZ2luZS52MRofZ29vZ2xlL2FwaS9maWVsZF9iZWhhdmlvci5w
cm90bxoZZ29vZ2xlL2FwaS9yZXNvdXJjZS5wcm90bxocZ29vZ2xlL3Byb3RvYnVmL3N0cnVj
dC5wcm90byL5AgoGU2NoZW1hEj4KDXN0cnVjdF9zY2hlbWEYAiABKAsyFy5nb29nbGUucHJv
dG9idWYuU3RydWN0SABSDHN0cnVjdFNjaGVtYRIhCgtqc29uX3NjaGVtYRgDIAEoCUgAUgpq
c29uU2NoZW1hEhcKBG5hbWUYASABKAlCA+BBBVIEbmFtZTroAepB5AEKJWRpc2NvdmVyeWVu
Z2luZS5nb29nbGVhcGlzLmNvbS9TY2hlbWESUHByb2plY3RzL3twcm9qZWN0fS9sb2NhdGlv
bnMve2xvY2F0aW9ufS9kYXRhU3RvcmVzL3tkYXRhX3N0b3JlfS9zY2hlbWFzL3tzY2hlbWF9
Emlwcm9qZWN0cy97cHJvamVjdH0vbG9jYXRpb25zL3tsb2NhdGlvbn0vY29sbGVjdGlvbnMv
e2NvbGxlY3Rpb259L2RhdGFTdG9yZXMve2RhdGFfc3RvcmV9L3NjaGVtYXMve3NjaGVtYX1C
CAoGc2NoZW1hQv4BCiNjb20uZ29vZ2xlLmNsb3VkLmRpc2NvdmVyeWVuZ2luZS52MUILU2No
ZW1hUHJvdG9QAVpNY2xvdWQuZ29vZ2xlLmNvbS9nby9kaXNjb3ZlcnllbmdpbmUvYXBpdjEv
ZGlzY292ZXJ5ZW5naW5lcGI7ZGlzY292ZXJ5ZW5naW5lcGKiAg9ESVNDT1ZFUllFTkdJTkWq
Ah9Hb29nbGUuQ2xvdWQuRGlzY292ZXJ5RW5naW5lLlYxygIfR29vZ2xlXENsb3VkXERpc2Nv
dmVyeUVuZ2luZVxWMeoCIkdvb2dsZTo6Q2xvdWQ6OkRpc2NvdmVyeUVuZ2luZTo6VjFKxw0K
BhIEDgA5AQq8BAoBDBIDDgASMrEEIENvcHlyaWdodCAyMDI2IEdvb2dsZSBMTEMKCiBMaWNl
bnNlZCB1bmRlciB0aGUgQXBhY2hlIExpY2Vuc2UsIFZlcnNpb24gMi4wICh0aGUgIkxpY2Vu
c2UiKTsKIHlvdSBtYXkgbm90IHVzZSB0aGlzIGZpbGUgZXhjZXB0IGluIGNvbXBsaWFuY2Ug
d2l0aCB0aGUgTGljZW5zZS4KIFlvdSBtYXkgb2J0YWluIGEgY29weSBvZiB0aGUgTGljZW5z
ZSBhdAoKICAgICBodHRwOi8vd3d3LmFwYWNoZS5vcmcvbGljZW5zZXMvTElDRU5TRS0yLjAK
CiBVbmxlc3MgcmVxdWlyZWQgYnkgYXBwbGljYWJsZSBsYXcgb3IgYWdyZWVkIHRvIGluIHdy
aXRpbmcsIHNvZnR3YXJlCiBkaXN0cmlidXRlZCB1bmRlciB0aGUgTGljZW5zZSBpcyBkaXN0
cmlidXRlZCBvbiBhbiAiQVMgSVMiIEJBU0lTLAogV0lUSE9VVCBXQVJSQU5USUVTIE9SIENP
TkRJVElPTlMgT0YgQU5ZIEtJTkQsIGVpdGhlciBleHByZXNzIG9yIGltcGxpZWQuCiBTZWUg
dGhlIExpY2Vuc2UgZm9yIHRoZSBzcGVjaWZpYyBsYW5ndWFnZSBnb3Zlcm5pbmcgcGVybWlz
c2lvbnMgYW5kCiBsaW1pdGF0aW9ucyB1bmRlciB0aGUgTGljZW5zZS4KCggKAQISAxAAKAoJ
CgIDABIDEgApCgkKAgMBEgMTACMKCQoCAwISAxQAJgoICgEIEgMWADwKCQoCCCUSAxYAPAoI
CgEIEgMXAGQKCQoCCAsSAxcAZAoICgEIEgMYACIKCQoCCAoSAxgAIgoICgEIEgMZACwKCQoC
CAgSAxkALAoICgEIEgMaADwKCQoCCAESAxoAPAoICgEIEgMbAC0KCQoCCCQSAxsALQoICgEI
EgMcADwKCQoCCCkSAxwAPAoICgEIEgMdADsKCQoCCC0SAx0AOwpKCgIEABIEIAA5ARo+IERl
ZmluZXMgdGhlIHN0cnVjdHVyZSBhbmQgbGF5b3V0IG9mIGEgdHlwZSBvZiBkb2N1bWVudCBk
YXRhLgoKCgoDBAABEgMgCA4KCwoDBAAHEgQhAiUECg0KBQQAB50IEgQhAiUECoACCgQEAAgA
EgQrAjEDGvEBIFNjaGVtYSByZXByZXNlbnRhdGlvbi4gT25lIG9mCiBbc3RydWN0X3NjaGVt
YV1bZ29vZ2xlLmNsb3VkLmRpc2NvdmVyeWVuZ2luZS52MS5TY2hlbWEuc3RydWN0X3NjaGVt
YV0gb3IKIFtqc29uX3NjaGVtYV1bZ29vZ2xlLmNsb3VkLmRpc2NvdmVyeWVuZ2luZS52MS5T
Y2hlbWEuanNvbl9zY2hlbWFdIHNob3VsZCBiZQogcHJvdmlkZWQgb3RoZXJ3aXNlIGFuIGBJ
TlZBTElEX0FSR1VNRU5UYCBlcnJvciBpcyB0aHJvd24uCgoMCgUEAAgAARIDKwgOCjsKBAQA
AgASAy0ELRouIFRoZSBzdHJ1Y3R1cmVkIHJlcHJlc2VudGF0aW9uIG9mIHRoZSBzY2hlbWEu
CgoMCgUEAAIABhIDLQQaCgwKBQQAAgABEgMtGygKDAoFBAACAAMSAy0rLAo1CgQEAAIBEgMw
BBsaKCBUaGUgSlNPTiByZXByZXNlbnRhdGlvbiBvZiB0aGUgc2NoZW1hLgoKDAoFBAACAQUS
AzAECgoMCgUEAAIBARIDMAsWCgwKBQQAAgEDEgMwGRoKlAIKBAQAAgISAzgCPBqGAiBJbW11
dGFibGUuIFRoZSBmdWxsIHJlc291cmNlIG5hbWUgb2YgdGhlIHNjaGVtYSwgaW4gdGhlIGZv
cm1hdCBvZgogYHByb2plY3RzL3twcm9qZWN0fS9sb2NhdGlvbnMve2xvY2F0aW9ufS9jb2xs
ZWN0aW9ucy97Y29sbGVjdGlvbn0vZGF0YVN0b3Jlcy97ZGF0YV9zdG9yZX0vc2NoZW1hcy97
c2NoZW1hfWAuCgogVGhpcyBmaWVsZCBtdXN0IGJlIGEgVVRGLTggZW5jb2RlZCBzdHJpbmcg
d2l0aCBhIGxlbmd0aCBsaW1pdCBvZiAxMDI0CiBjaGFyYWN0ZXJzLgoKDAoFBAACAgUSAzgC
CAoMCgUEAAICARIDOAkNCgwKBQQAAgIDEgM4EBEKDAoFBAACAggSAzgSOwoPCggEAAICCJwI
ABIDOBM6YgZwcm90bzM=
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Discoveryengine::V1::Schema::Schema ===
    # Fields for Schema
    # Field: struct_schema Type: 11 (.google.protobuf.Struct)
    # Field: json_schema Type: 9 ()
    # Field: name Type: 9 ()

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Discoveryengine::V1::Schema - Compiled Protocol Buffers messages for google/cloud/discoveryengine/v1/schema.proto

=head1 SYNOPSIS

    use Google::Cloud::Discoveryengine::V1::Schema;

    my $msg = Google::Cloud::Discoveryengine::V1::Schema::Schema->new({
        struct_schema => $struct_schema,
        json_schema => $json_schema,
        name => $name,
    });

    # Read or update a field
    my $val = $msg->struct_schema();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Discoveryengine::V1::Schema::Schema->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/discoveryengine/v1/schema.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Discoveryengine::V1::Schema::Schema

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

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Discoveryengine::V1::Schema::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
