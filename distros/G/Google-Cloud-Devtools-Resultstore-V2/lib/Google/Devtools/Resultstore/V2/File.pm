package Google::Devtools::Resultstore::V2::File;

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
Cilnb29nbGUvZGV2dG9vbHMvcmVzdWx0c3RvcmUvdjIvZmlsZS5wcm90bxIeZ29vZ2xlLmRl
dnRvb2xzLnJlc3VsdHN0b3JlLnYyGh5nb29nbGUvcHJvdG9idWYvd3JhcHBlcnMucHJvdG8i
4AMKBEZpbGUSEAoDdWlkGAEgASgJUgN1aWQSEAoDdXJpGAIgASgJUgN1cmkSMwoGbGVuZ3Ro
GAMgASgLMhsuZ29vZ2xlLnByb3RvYnVmLkludDY0VmFsdWVSBmxlbmd0aBIhCgxjb250ZW50
X3R5cGUYBCABKAlSC2NvbnRlbnRUeXBlElEKDWFyY2hpdmVfZW50cnkYBSABKAsyLC5nb29n
bGUuZGV2dG9vbHMucmVzdWx0c3RvcmUudjIuQXJjaGl2ZUVudHJ5UgxhcmNoaXZlRW50cnkS
JQoOY29udGVudF92aWV3ZXIYBiABKAlSDWNvbnRlbnRWaWV3ZXISFgoGaGlkZGVuGAcgASgI
UgZoaWRkZW4SIAoLZGVzY3JpcHRpb24YCCABKAlSC2Rlc2NyaXB0aW9uEhYKBmRpZ2VzdBgJ
IAEoCVIGZGlnZXN0EkoKCWhhc2hfdHlwZRgKIAEoDjItLmdvb2dsZS5kZXZ0b29scy5yZXN1
bHRzdG9yZS52Mi5GaWxlLkhhc2hUeXBlUghoYXNoVHlwZSJECghIYXNoVHlwZRIZChVIQVNI
X1RZUEVfVU5TUEVDSUZJRUQQABIHCgNNRDUQARIICgRTSEExEAISCgoGU0hBMjU2EAMiegoM
QXJjaGl2ZUVudHJ5EhIKBHBhdGgYASABKAlSBHBhdGgSMwoGbGVuZ3RoGAIgASgLMhsuZ29v
Z2xlLnByb3RvYnVmLkludDY0VmFsdWVSBmxlbmd0aBIhCgxjb250ZW50X3R5cGUYAyABKAlS
C2NvbnRlbnRUeXBlQnwKImNvbS5nb29nbGUuZGV2dG9vbHMucmVzdWx0c3RvcmUudjJCCUZp
bGVQcm90b1ABWklnb29nbGUuZ29sYW5nLm9yZy9nZW5wcm90by9nb29nbGVhcGlzL2RldnRv
b2xzL3Jlc3VsdHN0b3JlL3YyO3Jlc3VsdHN0b3JlStAeCgYSBA4AZwEKvAQKAQwSAw4AEjKx
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
bnMgdW5kZXIgdGhlIExpY2Vuc2UuCgoICgECEgMQACcKCQoCAwASAxIAKAoICgEIEgMUAGAK
CQoCCAsSAxQAYAoICgEIEgMVACIKCQoCCAoSAxUAIgoICgEIEgMWACoKCQoCCAgSAxYAKgoI
CgEIEgMXADsKCQoCCAESAxcAOwo/CgIEABIEGgBYARozIFRoZSBtZXRhZGF0YSBmb3IgYSBm
aWxlIG9yIGFuIGFyY2hpdmUgZmlsZSBlbnRyeS4KCgoKAwQAARIDGggMCkgKBAQABAASBBwC
KAMaOiBJZiBrbm93biwgdGhlIGhhc2ggZnVuY3Rpb24gdXNlZCB0byBjb21wdXRlIHRoaXMg
ZGlnZXN0LgoKDAoFBAAEAAESAxwHDwoYCgYEAAQAAgASAx4EHhoJIFVua25vd24KCg4KBwQA
BAACAAESAx4EGQoOCgcEAAQAAgACEgMeHB0KFAoGBAAEAAIBEgMhBAwaBSBNRDUKCg4KBwQA
BAACAQESAyEEBwoOCgcEAAQAAgECEgMhCgsKFgoGBAAEAAICEgMkBA0aByBTSEEtMQoKDgoH
BAAEAAICARIDJAQICg4KBwQABAACAgISAyQLDAoYCgYEAAQAAgMSAycEDxoJIFNIQS0yNTYK
Cg4KBwQABAACAwESAycECgoOCgcEAAQAAgMCEgMnDQ4KlwIKBAQAAgASAy4CERqJAiBUaGUg
aWRlbnRpZmllciBvZiB0aGUgZmlsZSBvciBhcmNoaXZlIGVudHJ5LgogVXNlci1wcm92aWRl
ZCwgbXVzdCBiZSB1bmlxdWUgZm9yIHRoZSByZXBlYXRlZCBmaWVsZCBpdCBpcyBpbi4gV2hl
biBhbgogQXBwZW5kIFJQQyBpcyBjYWxsZWQgd2l0aCBhIEZpbGVzIGZpZWxkIHBvcHVsYXRl
ZCwgaWYgYSBGaWxlIGFscmVhZHkgZXhpc3RzCiB3aXRoIHRoaXMgSUQsIHRoYXQgRmlsZSB3
aWxsIGJlIG92ZXJ3cml0dGVuIHdpdGggdGhlIG5ldyBGaWxlIHByb3RvLgoKDAoFBAACAAUS
Ay4CCAoMCgUEAAIAARIDLgkMCgwKBQQAAgADEgMuDxAKgwIKBAQAAgESAzUCERr1ASBUaGUg
VVJJIG9mIGEgZmlsZS4KIFRoaXMgY291bGQgYWxzbyBiZSB0aGUgVVJJIG9mIGFuIGVudGly
ZSBhcmNoaXZlLgogTW9zdCBsb2cgZGF0YSBkb2Vzbid0IG5lZWQgdG8gYmUgc3RvcmVkIGZv
cmV2ZXIsIHNvIGEgdHRsIGlzIHN1Z2dlc3RlZC4KIE5vdGUgdGhhdCBpZiB5b3UgZXZlciBt
b3ZlIG9yIGRlbGV0ZSB0aGUgZmlsZSBhdCB0aGlzIFVSSSwgdGhlIGxpbmsgZnJvbQogdGhl
IHNlcnZlciB3aWxsIGJlIGJyb2tlbi4KCgwKBQQAAgEFEgM1AggKDAoFBAACAQESAzUJDAoM
CgUEAAIBAxIDNQ8QCtABCgQEAAICEgM6AigawgEgVGhlIGxlbmd0aCBvZiB0aGUgZmlsZSBp
biBieXRlcy4gIEFsbG93cyB0aGUgZmlsZXNpemUgdG8gYmUgc2hvd24gaW4gdGhlCiBVSS4g
IE9taXQgaWYgZmlsZSBpcyBzdGlsbCBiZWluZyB3cml0dGVuIG9yIGxlbmd0aCBpcyBub3Qg
a25vd24uICBUaGlzCiBjb3VsZCBhbHNvIGJlIHRoZSBsZW5ndGggb2YgYW4gZW50aXJlIGFy
Y2hpdmUuCgoMCgUEAAICBhIDOgIcCgwKBQQAAgIBEgM6HSMKDAoFBAACAgMSAzomJwrcAQoE
BAACAxIDPwIaGs4BIFRoZSBjb250ZW50LXR5cGUgKGFrYSBNSU1FLXR5cGUpIG9mIHRoZSBm
aWxlLiAgVGhpcyBpcyBzZW50IHRvIHRoZSB3ZWIKIGJyb3dzZXIgc28gaXQga25vd3MgaG93
IHRvIGhhbmRsZSB0aGUgZmlsZS4gKGUuZy4gdGV4dC9wbGFpbiwgaW1hZ2UvanBlZywKIHRl
eHQvaHRtbCwgZXRjKS4gRm9yIHppcCBhcmNoaXZlcywgdXNlICJhcHBsaWNhdGlvbi96aXAi
LgoKDAoFBAACAwUSAz8CCAoMCgUEAAIDARIDPwkVCgwKBQQAAgMDEgM/GBkKxwEKBAQAAgQS
A0QCIRq5ASBJZiB0aGUgYWJvdmUgcGF0aCwgbGVuZ3RoLCBhbmQgY29udGVudF90eXBlIGFy
ZSByZWZlcnJpbmcgdG8gYW4gYXJjaGl2ZSwKIGFuZCB5b3Ugd2lzaCB0byByZWZlciB0byBh
IHBhcnRpY3VsYXIgZW50cnkgd2l0aGluIHRoYXQgYXJjaGl2ZSwgcHV0IHRoZQogcGFydGlj
dWxhciBhcmNoaXZlIGVudHJ5IGRhdGEgaGVyZS4KCgwKBQQAAgQGEgNEAg4KDAoFBAACBAES
A0QPHAoMCgUEAAIEAxIDRB8gClIKBAQAAgUSA0cCHBpFIEEgdXJsIHRvIGEgY29udGVudCBk
aXNwbGF5IGFwcC9zaXRlIGZvciB0aGlzIGZpbGUgb3IgYXJjaGl2ZSBlbnRyeS4KCgwKBQQA
AgUFEgNHAggKDAoFBAACBQESA0cJFwoMCgUEAAIFAxIDRxobCqEBCgQEAAIGEgNLAhIakwEg
V2hldGhlciB0byBoaWRlIHRoaXMgZmlsZSBvciBhcmNoaXZlIGVudHJ5IGluIHRoZSBVSS4g
IERlZmF1bHRzIHRvIGZhbHNlLgogQSBjaGVja2JveCBsZXRzIHVzZXJzIHNlZSBoaWRkZW4g
ZmlsZXMsIGJ1dCB0aGV5J3JlIGhpZGRlbiBieSBkZWZhdWx0LgoKDAoFBAACBgUSA0sCBgoM
CgUEAAIGARIDSwcNCgwKBQQAAgYDEgNLEBEK6AEKBAQAAgcSA1ECGRraASBBIHNob3J0IGRl
c2NyaXB0aW9uIG9mIHdoYXQgdGhpcyBmaWxlIG9yIGFyY2hpdmUgZW50cnkgY29udGFpbnMu
IFRoaXMKIGRlc2NyaXB0aW9uIHNob3VsZCBoZWxwIHNvbWVvbmUgdmlld2luZyB0aGUgbGlz
dCBvZiB0aGVzZSBmaWxlcyB0bwogdW5kZXJzdGFuZCB0aGUgcHVycG9zZSBvZiB0aGlzIGZp
bGUgYW5kIHdoYXQgdGhleSB3b3VsZCB3YW50IHRvIHZpZXcgaXQKIGZvci4KCgwKBQQAAgcF
EgNRAggKDAoFBAACBwESA1EJFAoMCgUEAAIHAxIDURcYCksKBAQAAggSA1QCFBo+IFRoZSBk
aWdlc3Qgb2YgdGhpcyBmaWxlIGluIGhleGFkZWNpbWFsLWxpa2Ugc3RyaW5nIGlmIGtub3du
LgoKDAoFBAACCAUSA1QCCAoMCgUEAAIIARIDVAkPCgwKBQQAAggDEgNUEhMKQgoEBAACCRID
VwIaGjUgVGhlIGFsZ29yaXRobSBjb3JyZXNwb25kaW5nIHRvIHRoZSBkaWdlc3QgaWYga25v
d24uCgoMCgUEAAIJBhIDVwIKCgwKBQQAAgkBEgNXCxQKDAoFBAACCQMSA1cXGQo9CgIEARIE
WwBnARoxIEluZm9ybWF0aW9uIHNwZWNpZmljIHRvIGFuIGVudHJ5IGluIGFuIGFyY2hpdmUu
CgoKCgMEAQESA1sIFApBCgQEAQIAEgNdAhIaNCBUaGUgcmVsYXRpdmUgcGF0aCBvZiB0aGUg
ZW50cnkgd2l0aGluIHRoZSBhcmNoaXZlLgoKDAoFBAECAAUSA10CCAoMCgUEAQIAARIDXQkN
CgwKBQQBAgADEgNdEBEKlwEKBAQBAgESA2ECKBqJASBUaGUgdW5jb21wcmVzc2VkIGxlbmd0
aCBvZiB0aGUgYXJjaGl2ZSBlbnRyeSBpbiBieXRlcy4gIEFsbG93cyB0aGUgZW50cnkKIHNp
emUgdG8gYmUgc2hvd24gaW4gdGhlIFVJLiAgT21pdCBpZiB0aGUgbGVuZ3RoIGlzIG5vdCBr
bm93bi4KCgwKBQQBAgEGEgNhAhwKDAoFBAECAQESA2EdIwoMCgUEAQIBAxIDYSYnCrwBCgQE
AQICEgNmAhoargEgVGhlIGNvbnRlbnQtdHlwZSAoYWthIE1JTUUtdHlwZSkgb2YgdGhlIGFy
Y2hpdmUgZW50cnkuIChlLmcuIHRleHQvcGxhaW4sCiBpbWFnZS9qcGVnLCB0ZXh0L2h0bWws
IGV0YykuIFRoaXMgaXMgc2VudCB0byB0aGUgd2ViIGJyb3dzZXIgc28gaXQga25vd3MKIGhv
dyB0byBoYW5kbGUgdGhlIGVudHJ5LgoKDAoFBAECAgUSA2YCCAoMCgUEAQICARIDZgkVCgwK
BQQBAgIDEgNmGBliBnByb3RvMw==
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Devtools::Resultstore::V2::File::File ===
    # Fields for File
    # Field: uid Type: 9 ()
    # Field: uri Type: 9 ()
    # Field: length Type: 11 (.google.protobuf.Int64Value)
    # Field: content_type Type: 9 ()
    # Field: archive_entry Type: 11 (.google.devtools.resultstore.v2.ArchiveEntry)
    # Field: content_viewer Type: 9 ()
    # Field: hidden Type: 8 ()
    # Field: description Type: 9 ()
    # Field: digest Type: 9 ()
    # Field: hash_type Type: 14 (.google.devtools.resultstore.v2.File.HashType)

# Enum: File::HashType
our $File_HASH_TYPE_UNSPECIFIED = 0;
our $File_MD5 = 1;
our $File_SHA1 = 2;
our $File_SHA256 = 3;

# === Message: Google::Devtools::Resultstore::V2::File::ArchiveEntry ===
    # Fields for ArchiveEntry
    # Field: path Type: 9 ()
    # Field: length Type: 11 (.google.protobuf.Int64Value)
    # Field: content_type Type: 9 ()

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Devtools::Resultstore::V2::File - Compiled Protocol Buffers messages for google/devtools/resultstore/v2/file.proto

=head1 SYNOPSIS

    use Google::Devtools::Resultstore::V2::File;

    my $msg = Google::Devtools::Resultstore::V2::File::File->new({
        uid => $uid,
        uri => $uri,
        length => $length,
        content_type => $content_type,
    });

    # Read or update a field
    my $val = $msg->uid();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Devtools::Resultstore::V2::File::File->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/devtools/resultstore/v2/file.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Devtools::Resultstore::V2::File::File

The metadata for a file or an archive file entry.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->uid() >> / C<< $msg->uid($value) >>

Type: C<String>

The identifier of the file or archive entry.
User-provided, must be unique for the repeated field it is in. When an
Append RPC is called with a Files field populated, if a File already exists
with this ID, that File will be overwritten with the new File proto.

=item * C<< $msg->uri() >> / C<< $msg->uri($value) >>

Type: C<String>

The URI of a file.
This could also be the URI of an entire archive.
Most log data doesn't need to be stored forever, so a ttl is suggested.
Note that if you ever move or delete the file at this URI, the link from
the server will be broken.

=item * C<< $msg->length() >> / C<< $msg->length($value) >>

Type: C<Message> (L<Google::Protobuf::Wrappers::Int64Value>)

The length of the file in bytes.  Allows the filesize to be shown in the
UI.  Omit if file is still being written or length is not known.  This
could also be the length of an entire archive.

=item * C<< $msg->content_type() >> / C<< $msg->content_type($value) >>

Type: C<String>

The content-type (aka MIME-type) of the file.  This is sent to the web
browser so it knows how to handle the file. (e.g. text/plain, image/jpeg,
text/html, etc). For zip archives, use "application/zip".

=item * C<< $msg->archive_entry() >> / C<< $msg->archive_entry($value) >>

Type: C<Message> (L<Google::Devtools::Resultstore::V2::File::ArchiveEntry>)

If the above path, length, and content_type are referring to an archive,
and you wish to refer to a particular entry within that archive, put the
particular archive entry data here.

=item * C<< $msg->content_viewer() >> / C<< $msg->content_viewer($value) >>

Type: C<String>

A url to a content display app/site for this file or archive entry.

=item * C<< $msg->hidden() >> / C<< $msg->hidden($value) >>

Type: C<Bool>

Whether to hide this file or archive entry in the UI.  Defaults to false.
A checkbox lets users see hidden files, but they're hidden by default.

=item * C<< $msg->description() >> / C<< $msg->description($value) >>

Type: C<String>

A short description of what this file or archive entry contains. This
description should help someone viewing the list of these files to
understand the purpose of this file and what they would want to view it
for.

=item * C<< $msg->digest() >> / C<< $msg->digest($value) >>

Type: C<String>

The digest of this file in hexadecimal-like string if known.

=item * C<< $msg->hash_type() >> / C<< $msg->hash_type($value) >>

Type: C<Enum> (L<Google::Devtools::Resultstore::V2::File::HashType>)

The algorithm corresponding to the digest if known.

=back

=head3 Enum: File::HashType

=over 4

=item * C<HASH_TYPE_UNSPECIFIED> => C<0>

=item * C<MD5> => C<1>

=item * C<SHA1> => C<2>

=item * C<SHA256> => C<3>

=back

=head2 Google::Devtools::Resultstore::V2::File::ArchiveEntry

Information specific to an entry in an archive.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->path() >> / C<< $msg->path($value) >>

Type: C<String>

The relative path of the entry within the archive.

=item * C<< $msg->length() >> / C<< $msg->length($value) >>

Type: C<Message> (L<Google::Protobuf::Wrappers::Int64Value>)

The uncompressed length of the archive entry in bytes.  Allows the entry
size to be shown in the UI.  Omit if the length is not known.

=item * C<< $msg->content_type() >> / C<< $msg->content_type($value) >>

Type: C<String>

The content-type (aka MIME-type) of the archive entry. (e.g. text/plain,
image/jpeg, text/html, etc). This is sent to the web browser so it knows
how to handle the entry.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Devtools::Resultstore::V2::File::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
