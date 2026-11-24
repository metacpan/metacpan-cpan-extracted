package Google::Actions::Sdk::V2::Manifest;

use strict;
use warnings;

our $VERSION = '0.14';

use Protobuf::Message;
use Protobuf::DescriptorPool;
use Protobuf::Internal qw(:all);
use MIME::Base64;

BEGIN {
    my $descriptor_b64 = <<'EOF';
CiRnb29nbGUvYWN0aW9ucy9zZGsvdjIvbWFuaWZlc3QucHJvdG8SFWdvb2dsZS5hY3Rpb25z
LnNkay52MiIkCghNYW5pZmVzdBIYCgd2ZXJzaW9uGAEgASgJUgd2ZXJzaW9uQmYKGWNvbS5n
b29nbGUuYWN0aW9ucy5zZGsudjJCDU1hbmlmZXN0UHJvdG9QAVo4Z29vZ2xlLmdvbGFuZy5v
cmcvZ2VucHJvdG8vZ29vZ2xlYXBpcy9hY3Rpb25zL3Nkay92MjtzZGtKxQcKBhIEDgAdAQq8
BAoBDBIDDgASMrEEIENvcHlyaWdodCAyMDI1IEdvb2dsZSBMTEMKCiBMaWNlbnNlZCB1bmRl
ciB0aGUgQXBhY2hlIExpY2Vuc2UsIFZlcnNpb24gMi4wICh0aGUgIkxpY2Vuc2UiKTsKIHlv
dSBtYXkgbm90IHVzZSB0aGlzIGZpbGUgZXhjZXB0IGluIGNvbXBsaWFuY2Ugd2l0aCB0aGUg
TGljZW5zZS4KIFlvdSBtYXkgb2J0YWluIGEgY29weSBvZiB0aGUgTGljZW5zZSBhdAoKICAg
ICBodHRwOi8vd3d3LmFwYWNoZS5vcmcvbGljZW5zZXMvTElDRU5TRS0yLjAKCiBVbmxlc3Mg
cmVxdWlyZWQgYnkgYXBwbGljYWJsZSBsYXcgb3IgYWdyZWVkIHRvIGluIHdyaXRpbmcsIHNv
ZnR3YXJlCiBkaXN0cmlidXRlZCB1bmRlciB0aGUgTGljZW5zZSBpcyBkaXN0cmlidXRlZCBv
biBhbiAiQVMgSVMiIEJBU0lTLAogV0lUSE9VVCBXQVJSQU5USUVTIE9SIENPTkRJVElPTlMg
T0YgQU5ZIEtJTkQsIGVpdGhlciBleHByZXNzIG9yIGltcGxpZWQuCiBTZWUgdGhlIExpY2Vu
c2UgZm9yIHRoZSBzcGVjaWZpYyBsYW5ndWFnZSBnb3Zlcm5pbmcgcGVybWlzc2lvbnMgYW5k
CiBsaW1pdGF0aW9ucyB1bmRlciB0aGUgTGljZW5zZS4KCggKAQISAxAAHgoICgEIEgMSAE8K
CQoCCAsSAxIATwoICgEIEgMTACIKCQoCCAoSAxMAIgoICgEIEgMUAC4KCQoCCAgSAxQALgoI
CgEIEgMVADIKCQoCCAESAxUAMgqEAQoCBAASBBkAHQEaeCBDb250YWlucyBpbmZvcm1hdGlv
biB0aGF0J3MgInRyYW5zcG9ydGFibGUiIGkuZS4gbm90IHNwZWNpZmljIHRvIGFueSBnaXZl
bgogcHJvamVjdCBhbmQgY2FuIGJlIG1vdmVkIGJldHdlZW4gcHJvamVjdHMuCgoKCgMEAAES
AxkIEAphCgQEAAIAEgMcAhUaVCBWZXJzaW9uIG9mIHRoZSBmaWxlIGZvcm1hdC4gVGhlIGN1
cnJlbnQgZmlsZSBmb3JtYXQgdmVyc2lvbiBpcyAxLjAKIEV4YW1wbGU6ICIxLjAiCgoMCgUE
AAIABRIDHAIICgwKBQQAAgABEgMcCRAKDAoFBAACAAMSAxwTFGIGcHJvdG8z
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Actions::Sdk::V2::Manifest::Manifest ===
    # Fields for Manifest
    # Field: version Type: 9 ()

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Actions::Sdk::V2::Manifest - Compiled Protocol Buffers messages for google/actions/sdk/v2/manifest.proto

=head1 SYNOPSIS

    use Google::Actions::Sdk::V2::Manifest;

    my $msg = Google::Actions::Sdk::V2::Manifest::Manifest->new({
        version => $version,
    });

    # Read or update a field
    my $val = $msg->version();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Actions::Sdk::V2::Manifest::Manifest->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/actions/sdk/v2/manifest.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Actions::Sdk::V2::Manifest::Manifest

Contains information that's "transportable" i.e. not specific to any given
project and can be moved between projects.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->version() >> / C<< $msg->version($value) >>

Type: C<String>

Version of the file format. The current file format version is 1.0
Example: "1.0"

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Actions::Sdk::V2::Manifest::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
