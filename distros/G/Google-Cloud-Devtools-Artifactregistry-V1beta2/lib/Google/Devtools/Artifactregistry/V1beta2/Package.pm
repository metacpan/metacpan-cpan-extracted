package Google::Devtools::Artifactregistry::V1beta2::Package;

use strict;
use warnings;

our $VERSION = '0.14';

use Protobuf::Message;
use Protobuf::DescriptorPool;
use Protobuf::Internal qw(:all);
use MIME::Base64;

BEGIN {
    eval { require Google::Protobuf::Timestamp };
    my $descriptor_b64 = <<'EOF';
CjZnb29nbGUvZGV2dG9vbHMvYXJ0aWZhY3RyZWdpc3RyeS92MWJldGEyL3BhY2thZ2UucHJv
dG8SKGdvb2dsZS5kZXZ0b29scy5hcnRpZmFjdHJlZ2lzdHJ5LnYxYmV0YTIaH2dvb2dsZS9w
cm90b2J1Zi90aW1lc3RhbXAucHJvdG8iugEKB1BhY2thZ2USEgoEbmFtZRgBIAEoCVIEbmFt
ZRIhCgxkaXNwbGF5X25hbWUYAiABKAlSC2Rpc3BsYXlOYW1lEjsKC2NyZWF0ZV90aW1lGAUg
ASgLMhouZ29vZ2xlLnByb3RvYnVmLlRpbWVzdGFtcFIKY3JlYXRlVGltZRI7Cgt1cGRhdGVf
dGltZRgGIAEoCzIaLmdvb2dsZS5wcm90b2J1Zi5UaW1lc3RhbXBSCnVwZGF0ZVRpbWUiaQoT
TGlzdFBhY2thZ2VzUmVxdWVzdBIWCgZwYXJlbnQYASABKAlSBnBhcmVudBIbCglwYWdlX3Np
emUYAiABKAVSCHBhZ2VTaXplEh0KCnBhZ2VfdG9rZW4YAyABKAlSCXBhZ2VUb2tlbiKNAQoU
TGlzdFBhY2thZ2VzUmVzcG9uc2USTQoIcGFja2FnZXMYASADKAsyMS5nb29nbGUuZGV2dG9v
bHMuYXJ0aWZhY3RyZWdpc3RyeS52MWJldGEyLlBhY2thZ2VSCHBhY2thZ2VzEiYKD25leHRf
cGFnZV90b2tlbhgCIAEoCVINbmV4dFBhZ2VUb2tlbiInChFHZXRQYWNrYWdlUmVxdWVzdBIS
CgRuYW1lGAEgASgJUgRuYW1lIioKFERlbGV0ZVBhY2thZ2VSZXF1ZXN0EhIKBG5hbWUYASAB
KAlSBG5hbWVCkAIKLGNvbS5nb29nbGUuZGV2dG9vbHMuYXJ0aWZhY3RyZWdpc3RyeS52MWJl
dGEyQgxQYWNrYWdlUHJvdG9QAVpVY2xvdWQuZ29vZ2xlLmNvbS9nby9hcnRpZmFjdHJlZ2lz
dHJ5L2FwaXYxYmV0YTIvYXJ0aWZhY3RyZWdpc3RyeXBiO2FydGlmYWN0cmVnaXN0cnlwYqoC
JUdvb2dsZS5DbG91ZC5BcnRpZmFjdFJlZ2lzdHJ5LlYxQmV0YTLKAiVHb29nbGVcQ2xvdWRc
QXJ0aWZhY3RSZWdpc3RyeVxWMWJldGEy6gIoR29vZ2xlOjpDbG91ZDo6QXJ0aWZhY3RSZWdp
c3RyeTo6VjFiZXRhMkrgEgoGEgQOAE4BCrwECgEMEgMOABIysQQgQ29weXJpZ2h0IDIwMjUg
R29vZ2xlIExMQwoKIExpY2Vuc2VkIHVuZGVyIHRoZSBBcGFjaGUgTGljZW5zZSwgVmVyc2lv
biAyLjAgKHRoZSAiTGljZW5zZSIpOwogeW91IG1heSBub3QgdXNlIHRoaXMgZmlsZSBleGNl
cHQgaW4gY29tcGxpYW5jZSB3aXRoIHRoZSBMaWNlbnNlLgogWW91IG1heSBvYnRhaW4gYSBj
b3B5IG9mIHRoZSBMaWNlbnNlIGF0CgogICAgIGh0dHA6Ly93d3cuYXBhY2hlLm9yZy9saWNl
bnNlcy9MSUNFTlNFLTIuMAoKIFVubGVzcyByZXF1aXJlZCBieSBhcHBsaWNhYmxlIGxhdyBv
ciBhZ3JlZWQgdG8gaW4gd3JpdGluZywgc29mdHdhcmUKIGRpc3RyaWJ1dGVkIHVuZGVyIHRo
ZSBMaWNlbnNlIGlzIGRpc3RyaWJ1dGVkIG9uIGFuICJBUyBJUyIgQkFTSVMsCiBXSVRIT1VU
IFdBUlJBTlRJRVMgT1IgQ09ORElUSU9OUyBPRiBBTlkgS0lORCwgZWl0aGVyIGV4cHJlc3Mg
b3IgaW1wbGllZC4KIFNlZSB0aGUgTGljZW5zZSBmb3IgdGhlIHNwZWNpZmljIGxhbmd1YWdl
IGdvdmVybmluZyBwZXJtaXNzaW9ucyBhbmQKIGxpbWl0YXRpb25zIHVuZGVyIHRoZSBMaWNl
bnNlLgoKCAoBAhIDEAAxCgkKAgMAEgMSACkKCAoBCBIDFABCCgkKAgglEgMUAEIKCAoBCBID
FQBsCgkKAggLEgMVAGwKCAoBCBIDFgAiCgkKAggKEgMWACIKCAoBCBIDFwAtCgkKAggIEgMX
AC0KCAoBCBIDGABFCgkKAggBEgMYAEUKCAoBCBIDGQBCCgkKAggpEgMZAEIKCAoBCBIDGgBB
CgkKAggtEgMaAEEKOQoCBAASBB0AKwEaLSBQYWNrYWdlcyBhcmUgbmFtZWQgY29sbGVjdGlv
bnMgb2YgdmVyc2lvbnMuCgoKCgMEAAESAx0IDwp7CgQEAAIAEgMgAhIabiBUaGUgbmFtZSBv
ZiB0aGUgcGFja2FnZSwgZm9yIGV4YW1wbGU6CiAicHJvamVjdHMvcDEvbG9jYXRpb25zL3Vz
LWNlbnRyYWwxL3JlcG9zaXRvcmllcy9yZXBvMS9wYWNrYWdlcy9wa2cxIi4KCgwKBQQAAgAF
EgMgAggKDAoFBAACAAESAyAJDQoMCgUEAAIAAxIDIBARCi8KBAQAAgESAyMCGhoiIFRoZSBk
aXNwbGF5IG5hbWUgb2YgdGhlIHBhY2thZ2UuCgoMCgUEAAIBBRIDIwIICgwKBQQAAgEBEgMj
CRUKDAoFBAACAQMSAyMYGQo1CgQEAAICEgMmAiwaKCBUaGUgdGltZSB3aGVuIHRoZSBwYWNr
YWdlIHdhcyBjcmVhdGVkLgoKDAoFBAACAgYSAyYCGwoMCgUEAAICARIDJhwnCgwKBQQAAgID
EgMmKisKcgoEBAACAxIDKgIsGmUgVGhlIHRpbWUgd2hlbiB0aGUgcGFja2FnZSB3YXMgbGFz
dCB1cGRhdGVkLiBUaGlzIGluY2x1ZGVzIHB1Ymxpc2hpbmcgYSBuZXcKIHZlcnNpb24gb2Yg
dGhlIHBhY2thZ2UuCgoMCgUEAAIDBhIDKgIbCgwKBQQAAgMBEgMqHCcKDAoFBAACAwMSAyoq
KworCgIEARIELgA4ARofIFRoZSByZXF1ZXN0IHRvIGxpc3QgcGFja2FnZXMuCgoKCgMEAQES
Ay4IGwpNCgQEAQIAEgMwAhQaQCBUaGUgbmFtZSBvZiB0aGUgcGFyZW50IHJlc291cmNlIHdo
b3NlIHBhY2thZ2VzIHdpbGwgYmUgbGlzdGVkLgoKDAoFBAECAAUSAzACCAoMCgUEAQIAARID
MAkPCgwKBQQBAgADEgMwEhMKVgoEBAECARIDNAIWGkkgVGhlIG1heGltdW0gbnVtYmVyIG9m
IHBhY2thZ2VzIHRvIHJldHVybi4KIE1heGltdW0gcGFnZSBzaXplIGlzIDEwLDAwMC4KCgwK
BQQBAgEFEgM0AgcKDAoFBAECAQESAzQIEQoMCgUEAQIBAxIDNBQVClcKBAQBAgISAzcCGBpK
IFRoZSBuZXh0X3BhZ2VfdG9rZW4gdmFsdWUgcmV0dXJuZWQgZnJvbSBhIHByZXZpb3VzIGxp
c3QgcmVxdWVzdCwgaWYgYW55LgoKDAoFBAECAgUSAzcCCAoMCgUEAQICARIDNwkTCgwKBQQB
AgIDEgM3FhcKMQoCBAISBDsAQgEaJSBUaGUgcmVzcG9uc2UgZnJvbSBsaXN0aW5nIHBhY2th
Z2VzLgoKCgoDBAIBEgM7CBwKJQoEBAICABIDPQIgGhggVGhlIHBhY2thZ2VzIHJldHVybmVk
LgoKDAoFBAICAAQSAz0CCgoMCgUEAgIABhIDPQsSCgwKBQQCAgABEgM9ExsKDAoFBAICAAMS
Az0eHwpyCgQEAgIBEgNBAh0aZSBUaGUgdG9rZW4gdG8gcmV0cmlldmUgdGhlIG5leHQgcGFn
ZSBvZiBwYWNrYWdlcywgb3IgZW1wdHkgaWYgdGhlcmUgYXJlIG5vCiBtb3JlIHBhY2thZ2Vz
IHRvIHJldHVybi4KCgwKBQQCAgEFEgNBAggKDAoFBAICAQESA0EJGAoMCgUEAgIBAxIDQRsc
CjAKAgQDEgRFAEgBGiQgVGhlIHJlcXVlc3QgdG8gcmV0cmlldmUgYSBwYWNrYWdlLgoKCgoD
BAMBEgNFCBkKMwoEBAMCABIDRwISGiYgVGhlIG5hbWUgb2YgdGhlIHBhY2thZ2UgdG8gcmV0
cmlldmUuCgoMCgUEAwIABRIDRwIICgwKBQQDAgABEgNHCQ0KDAoFBAMCAAMSA0cQEQouCgIE
BBIESwBOARoiIFRoZSByZXF1ZXN0IHRvIGRlbGV0ZSBhIHBhY2thZ2UuCgoKCgMEBAESA0sI
HAoxCgQEBAIAEgNNAhIaJCBUaGUgbmFtZSBvZiB0aGUgcGFja2FnZSB0byBkZWxldGUuCgoM
CgUEBAIABRIDTQIICgwKBQQEAgABEgNNCQ0KDAoFBAQCAAMSA00QEWIGcHJvdG8z
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Devtools::Artifactregistry::V1beta2::Package::Package ===
    # Fields for Package
    # Field: name Type: 9 ()
    # Field: display_name Type: 9 ()
    # Field: create_time Type: 11 (.google.protobuf.Timestamp)
    # Field: update_time Type: 11 (.google.protobuf.Timestamp)

# === Message: Google::Devtools::Artifactregistry::V1beta2::Package::ListPackagesRequest ===
    # Fields for ListPackagesRequest
    # Field: parent Type: 9 ()
    # Field: page_size Type: 5 ()
    # Field: page_token Type: 9 ()

# === Message: Google::Devtools::Artifactregistry::V1beta2::Package::ListPackagesResponse ===
    # Fields for ListPackagesResponse
    # Field: packages Type: 11 (.google.devtools.artifactregistry.v1beta2.Package)
    # Field: next_page_token Type: 9 ()

# === Message: Google::Devtools::Artifactregistry::V1beta2::Package::GetPackageRequest ===
    # Fields for GetPackageRequest
    # Field: name Type: 9 ()

# === Message: Google::Devtools::Artifactregistry::V1beta2::Package::DeletePackageRequest ===
    # Fields for DeletePackageRequest
    # Field: name Type: 9 ()

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Devtools::Artifactregistry::V1beta2::Package - Compiled Protocol Buffers messages for google/devtools/artifactregistry/v1beta2/package.proto

=head1 SYNOPSIS

    use Google::Devtools::Artifactregistry::V1beta2::Package;

    my $msg = Google::Devtools::Artifactregistry::V1beta2::Package::Package->new({
        name => $name,
        display_name => $display_name,
        create_time => $create_time,
        update_time => $update_time,
    });

    # Read or update a field
    my $val = $msg->name();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Devtools::Artifactregistry::V1beta2::Package::Package->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/devtools/artifactregistry/v1beta2/package.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Devtools::Artifactregistry::V1beta2::Package::Package

Packages are named collections of versions.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

The name of the package, for example:
"projects/p1/locations/us-central1/repositories/repo1/packages/pkg1".

=item * C<< $msg->display_name() >> / C<< $msg->display_name($value) >>

Type: C<String>

The display name of the package.

=item * C<< $msg->create_time() >> / C<< $msg->create_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

The time when the package was created.

=item * C<< $msg->update_time() >> / C<< $msg->update_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

The time when the package was last updated. This includes publishing a new
version of the package.

=back

=head2 Google::Devtools::Artifactregistry::V1beta2::Package::ListPackagesRequest

The request to list packages.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->parent() >> / C<< $msg->parent($value) >>

Type: C<String>

The name of the parent resource whose packages will be listed.

=item * C<< $msg->page_size() >> / C<< $msg->page_size($value) >>

Type: C<Int32>

The maximum number of packages to return.
Maximum page size is 10,000.

=item * C<< $msg->page_token() >> / C<< $msg->page_token($value) >>

Type: C<String>

The next_page_token value returned from a previous list request, if any.

=back

=head2 Google::Devtools::Artifactregistry::V1beta2::Package::ListPackagesResponse

The response from listing packages.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->packages() >> / C<< $msg->packages($value) >>

Type: C<Message> (L<Google::Devtools::Artifactregistry::V1beta2::Package::Package>)

The packages returned.

=item * C<< $msg->next_page_token() >> / C<< $msg->next_page_token($value) >>

Type: C<String>

The token to retrieve the next page of packages, or empty if there are no
more packages to return.

=back

=head2 Google::Devtools::Artifactregistry::V1beta2::Package::GetPackageRequest

The request to retrieve a package.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

The name of the package to retrieve.

=back

=head2 Google::Devtools::Artifactregistry::V1beta2::Package::DeletePackageRequest

The request to delete a package.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

The name of the package to delete.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Devtools::Artifactregistry::V1beta2::Package::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
