package Google::Devtools::Resultstore::V2::FileSet;

use strict;
use warnings;

our $VERSION = '0.14';

use Protobuf::Message;
use Protobuf::DescriptorPool;
use Protobuf::Internal qw(:all);
use MIME::Base64;

BEGIN {
    eval { require Google::Api::Resource };
    eval { require Google::Devtools::Resultstore::V2::File };
    my $descriptor_b64 = <<'EOF';
Ci1nb29nbGUvZGV2dG9vbHMvcmVzdWx0c3RvcmUvdjIvZmlsZV9zZXQucHJvdG8SHmdvb2ds
ZS5kZXZ0b29scy5yZXN1bHRzdG9yZS52MhoZZ29vZ2xlL2FwaS9yZXNvdXJjZS5wcm90bxop
Z29vZ2xlL2RldnRvb2xzL3Jlc3VsdHN0b3JlL3YyL2ZpbGUucHJvdG8i1AIKB0ZpbGVTZXQS
EgoEbmFtZRgBIAEoCVIEbmFtZRI6CgJpZBgCIAEoCzIqLmdvb2dsZS5kZXZ0b29scy5yZXN1
bHRzdG9yZS52Mi5GaWxlU2V0LklkUgJpZBIbCglmaWxlX3NldHMYAyADKAlSCGZpbGVTZXRz
EjoKBWZpbGVzGAQgAygLMiQuZ29vZ2xlLmRldnRvb2xzLnJlc3VsdHN0b3JlLnYyLkZpbGVS
BWZpbGVzGkkKAklkEiMKDWludm9jYXRpb25faWQYASABKAlSDGludm9jYXRpb25JZBIeCgtm
aWxlX3NldF9pZBgCIAEoCVIJZmlsZVNldElkOlXqQVIKInJlc3VsdHN0b3JlLmdvb2dsZWFw
aXMuY29tL0ZpbGVTZXQSLGludm9jYXRpb25zL3tpbnZvY2F0aW9ufS9maWxlU2V0cy97Zmls
ZV9zZXR9Qn8KImNvbS5nb29nbGUuZGV2dG9vbHMucmVzdWx0c3RvcmUudjJCDEZpbGVTZXRQ
cm90b1ABWklnb29nbGUuZ29sYW5nLm9yZy9nZW5wcm90by9nb29nbGVhcGlzL2RldnRvb2xz
L3Jlc3VsdHN0b3JlL3YyO3Jlc3VsdHN0b3JlSuATCgYSBA4ARgEKvAQKAQwSAw4AEjKxBCBD
b3B5cmlnaHQgMjAyNSBHb29nbGUgTExDCgogTGljZW5zZWQgdW5kZXIgdGhlIEFwYWNoZSBM
aWNlbnNlLCBWZXJzaW9uIDIuMCAodGhlICJMaWNlbnNlIik7CiB5b3UgbWF5IG5vdCB1c2Ug
dGhpcyBmaWxlIGV4Y2VwdCBpbiBjb21wbGlhbmNlIHdpdGggdGhlIExpY2Vuc2UuCiBZb3Ug
bWF5IG9idGFpbiBhIGNvcHkgb2YgdGhlIExpY2Vuc2UgYXQKCiAgICAgaHR0cDovL3d3dy5h
cGFjaGUub3JnL2xpY2Vuc2VzL0xJQ0VOU0UtMi4wCgogVW5sZXNzIHJlcXVpcmVkIGJ5IGFw
cGxpY2FibGUgbGF3IG9yIGFncmVlZCB0byBpbiB3cml0aW5nLCBzb2Z0d2FyZQogZGlzdHJp
YnV0ZWQgdW5kZXIgdGhlIExpY2Vuc2UgaXMgZGlzdHJpYnV0ZWQgb24gYW4gIkFTIElTIiBC
QVNJUywKIFdJVEhPVVQgV0FSUkFOVElFUyBPUiBDT05ESVRJT05TIE9GIEFOWSBLSU5ELCBl
aXRoZXIgZXhwcmVzcyBvciBpbXBsaWVkLgogU2VlIHRoZSBMaWNlbnNlIGZvciB0aGUgc3Bl
Y2lmaWMgbGFuZ3VhZ2UgZ292ZXJuaW5nIHBlcm1pc3Npb25zIGFuZAogbGltaXRhdGlvbnMg
dW5kZXIgdGhlIExpY2Vuc2UuCgoICgECEgMQACcKCQoCAwASAxIAIwoJCgIDARIDEwAzCggK
AQgSAxUAYAoJCgIICxIDFQBgCggKAQgSAxYAIgoJCgIIChIDFgAiCggKAQgSAxcALQoJCgII
CBIDFwAtCggKAQgSAxgAOwoJCgIIARIDGAA7CtEFCgIEABIEJwBGARrEBSBUaGlzIHJlc291
cmNlIHJlcHJlc2VudHMgYSBzZXQgb2YgRmlsZXMgYW5kIG90aGVyIChuZXN0ZWQpIEZpbGVT
ZXRzLgogQSBGaWxlU2V0IGlzIGEgbm9kZSBpbiB0aGUgZ3JhcGgsIGFuZCB0aGUgZmlsZV9z
ZXRzIGZpZWxkIHJlcHJlc2VudHMgdGhlCiBvdXRnb2luZyBlZGdlcy4gQSByZXNvdXJjZSBt
YXkgcmVmZXJlbmNlIHZhcmlvdXMgbm9kZXMgaW4gdGhlIGdyYXBoIHRvCiByZXByZXNlbnQg
dGhlIHRyYW5zaXRpdmUgY2xvc3VyZSBvZiBhbGwgZmlsZXMgZnJvbSB0aG9zZSBub2Rlcy4K
IFRoZSBGaWxlU2V0cyBtdXN0IGZvcm0gYSBkaXJlY3RlZCBhY3ljbGljIGdyYXBoLiBUaGUg
VXBsb2FkIEFQSSBpcyB1bmFibGUgdG8KIGVuZm9yY2UgdGhhdCB0aGUgZ3JhcGggaXMgYWN5
Y2xpYyBhdCB3cml0ZSB0aW1lLCBhbmQgaWYgY3ljbGVzIGFyZSB3cml0dGVuLAogaXQgbWF5
IGNhdXNlIGlzc3VlcyBhdCByZWFkIHRpbWUuCgogQSBGaWxlU2V0IG1heSBiZSByZWZlcmVu
Y2VkIGJ5IG90aGVyIHJlc291cmNlcyBpbiBjb25qdW5jdGlvbiB3aXRoIEZpbGVzLgoKIENs
aWVudHMgc2hvdWxkIHByZWZlciB1c2luZyBGaWxlcyBkaXJlY3RseSB1bmRlciByZXNvdXJj
ZXMuIENsaWVudHMgc2hvdWxkCiBub3QgdXNlIEZpbGVTZXRzIHVubGVzcyB0aGVpciB1c2Vj
YXNlIHJlcXVpcmVzIGEgZGlyZWN0ZWQgYWN5Y2xpYyBncmFwaCBvZgogRmlsZXMuCgoKCgME
AAESAycIDwoLCgMEAAcSBCgCKwQKDQoFBAAHnQgSBCgCKwQKRQoEBAADABIELgI0Axo3IFRo
ZSByZXNvdXJjZSBJRCBjb21wb25lbnRzIHRoYXQgaWRlbnRpZnkgdGhlIEZpbGVTZXQuCgoM
CgUEAAMAARIDLgoMCiMKBgQAAwACABIDMAQdGhQgVGhlIEludm9jYXRpb24gSUQuCgoOCgcE
AAMAAgAFEgMwBAoKDgoHBAADAAIAARIDMAsYCg4KBwQAAwACAAMSAzAbHAogCgYEAAMAAgES
AzMEGxoRIFRoZSBGaWxlU2V0IElELgoKDgoHBAADAAIBBRIDMwQKCg4KBwQAAwACAQESAzML
FgoOCgcEAAMAAgEDEgMzGRoKggEKBAQAAgASAzgCEhp1IFRoZSBmb3JtYXQgb2YgdGhpcyBG
aWxlU2V0IHJlc291cmNlIG5hbWUgbXVzdCBiZToKIGludm9jYXRpb25zLyR7SU5WT0NBVElP
Tl9JRH0vZmlsZVNldHMvJHt1cmxfZW5jb2RlKEZJTEVfU0VUX0lEKX0KCgwKBQQAAgAFEgM4
AggKDAoFBAACAAESAzgJDQoMCgUEAAIAAxIDOBARCn8KBAQAAgESAzwCDBpyIFRoZSByZXNv
dXJjZSBJRCBjb21wb25lbnRzIHRoYXQgaWRlbnRpZnkgdGhlIGZpbGUgc2V0LiBUaGV5IG11
c3QgbWF0Y2ggdGhlCiByZXNvdXJjZSBuYW1lIGFmdGVyIHByb3BlciBlbmNvZGluZy4KCgwK
BQQAAgEGEgM8AgQKDAoFBAACAQESAzwFBwoMCgUEAAIBAxIDPAoLCuEBCgQEAAICEgNBAiAa
0wEgTGlzdCBvZiBuYW1lcyBvZiBvdGhlciBmaWxlIHNldHMgdGhhdCBhcmUgcmVmZXJlbmNl
ZCBmcm9tIHRoaXMgb25lLgogRWFjaCBuYW1lIG11c3QgcG9pbnQgdG8gYSBmaWxlIHNldCB1
bmRlciB0aGUgc2FtZSBpbnZvY2F0aW9uLiBUaGUgbmFtZQogZm9ybWF0IG11c3QgYmU6IGlu
dm9jYXRpb25zLyR7SU5WT0NBVElPTl9JRH0vZmlsZVNldHMvJHtGSUxFX1NFVF9JRH0KCgwK
BQQAAgIEEgNBAgoKDAoFBAACAgUSA0ELEQoMCgUEAAICARIDQRIbCgwKBQQAAgIDEgNBHh8K
fQoEBAACAxIDRQIaGnAgRmlsZXMgdGhhdCBhcmUgY29udGFpbmVkIHdpdGhpbiB0aGlzIGZp
bGUgc2V0LgogVGhlIHVpZCBmaWVsZCBpbiB0aGUgZmlsZSBzaG91bGQgYmUgdW5pcXVlIGZv
ciB0aGUgSW52b2NhdGlvbi4KCgwKBQQAAgMEEgNFAgoKDAoFBAACAwYSA0ULDwoMCgUEAAID
ARIDRRAVCgwKBQQAAgMDEgNFGBliBnByb3RvMw==
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Devtools::Resultstore::V2::FileSet::FileSet ===
    # Fields for FileSet
    # Field: name Type: 9 ()
    # Field: id Type: 11 (.google.devtools.resultstore.v2.FileSet.Id)
    # Field: file_sets Type: 9 ()
    # Field: files Type: 11 (.google.devtools.resultstore.v2.File)

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Devtools::Resultstore::V2::FileSet - Compiled Protocol Buffers messages for google/devtools/resultstore/v2/file_set.proto

=head1 SYNOPSIS

    use Google::Devtools::Resultstore::V2::FileSet;

    my $msg = Google::Devtools::Resultstore::V2::FileSet::FileSet->new({
        name => $name,
        id => $id,
        file_sets => $file_sets,
        files => $files,
    });

    # Read or update a field
    my $val = $msg->name();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Devtools::Resultstore::V2::FileSet::FileSet->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/devtools/resultstore/v2/file_set.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Devtools::Resultstore::V2::FileSet::FileSet

This resource represents a set of Files and other (nested) FileSets.
A FileSet is a node in the graph, and the file_sets field represents the
outgoing edges. A resource may reference various nodes in the graph to
represent the transitive closure of all files from those nodes.
The FileSets must form a directed acyclic graph. The Upload API is unable to
enforce that the graph is acyclic at write time, and if cycles are written,
it may cause issues at read time.

A FileSet may be referenced by other resources in conjunction with Files.

Clients should prefer using Files directly under resources. Clients should
not use FileSets unless their usecase requires a directed acyclic graph of
Files.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

The format of this FileSet resource name must be:
invocations/${INVOCATION_ID}/fileSets/${url_encode(FILE_SET_ID)}

=item * C<< $msg->id() >> / C<< $msg->id($value) >>

Type: C<Message> (L<Google::Devtools::Resultstore::V2::FileSet::FileSet::Id>)

The resource ID components that identify the file set. They must match the
resource name after proper encoding.

=item * C<< $msg->file_sets() >> / C<< $msg->file_sets($value) >>

Type: C<String>

List of names of other file sets that are referenced from this one.
Each name must point to a file set under the same invocation. The name
format must be: invocations/${INVOCATION_ID}/fileSets/${FILE_SET_ID}

=item * C<< $msg->files() >> / C<< $msg->files($value) >>

Type: C<Message> (L<Google::Devtools::Resultstore::V2::File::File>)

Files that are contained within this file set.
The uid field in the file should be unique for the Invocation.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Devtools::Resultstore::V2::FileSet::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
