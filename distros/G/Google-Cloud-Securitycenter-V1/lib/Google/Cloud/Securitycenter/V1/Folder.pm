package Google::Cloud::Securitycenter::V1::Folder;

use strict;
use warnings;

our $VERSION = '0.14';

use Protobuf::Message;
use Protobuf::DescriptorPool;
use Protobuf::Internal qw(:all);
use MIME::Base64;

BEGIN {
    my $descriptor_b64 = <<'EOF';
Citnb29nbGUvY2xvdWQvc2VjdXJpdHljZW50ZXIvdjEvZm9sZGVyLnByb3RvEh5nb29nbGUu
Y2xvdWQuc2VjdXJpdHljZW50ZXIudjEicgoGRm9sZGVyEicKD3Jlc291cmNlX2ZvbGRlchgB
IAEoCVIOcmVzb3VyY2VGb2xkZXISPwoccmVzb3VyY2VfZm9sZGVyX2Rpc3BsYXlfbmFtZRgC
IAEoCVIZcmVzb3VyY2VGb2xkZXJEaXNwbGF5TmFtZULlAQoiY29tLmdvb2dsZS5jbG91ZC5z
ZWN1cml0eWNlbnRlci52MUILRm9sZGVyUHJvdG9QAVpKY2xvdWQuZ29vZ2xlLmNvbS9nby9z
ZWN1cml0eWNlbnRlci9hcGl2MS9zZWN1cml0eWNlbnRlcnBiO3NlY3VyaXR5Y2VudGVycGKq
Ah5Hb29nbGUuQ2xvdWQuU2VjdXJpdHlDZW50ZXIuVjHKAh5Hb29nbGVcQ2xvdWRcU2VjdXJp
dHlDZW50ZXJcVjHqAiFHb29nbGU6OkNsb3VkOjpTZWN1cml0eUNlbnRlcjo6VjFK4ggKBhIE
DgAjAQq8BAoBDBIDDgASMrEEIENvcHlyaWdodCAyMDI1IEdvb2dsZSBMTEMKCiBMaWNlbnNl
ZCB1bmRlciB0aGUgQXBhY2hlIExpY2Vuc2UsIFZlcnNpb24gMi4wICh0aGUgIkxpY2Vuc2Ui
KTsKIHlvdSBtYXkgbm90IHVzZSB0aGlzIGZpbGUgZXhjZXB0IGluIGNvbXBsaWFuY2Ugd2l0
aCB0aGUgTGljZW5zZS4KIFlvdSBtYXkgb2J0YWluIGEgY29weSBvZiB0aGUgTGljZW5zZSBh
dAoKICAgICBodHRwOi8vd3d3LmFwYWNoZS5vcmcvbGljZW5zZXMvTElDRU5TRS0yLjAKCiBV
bmxlc3MgcmVxdWlyZWQgYnkgYXBwbGljYWJsZSBsYXcgb3IgYWdyZWVkIHRvIGluIHdyaXRp
bmcsIHNvZnR3YXJlCiBkaXN0cmlidXRlZCB1bmRlciB0aGUgTGljZW5zZSBpcyBkaXN0cmli
dXRlZCBvbiBhbiAiQVMgSVMiIEJBU0lTLAogV0lUSE9VVCBXQVJSQU5USUVTIE9SIENPTkRJ
VElPTlMgT0YgQU5ZIEtJTkQsIGVpdGhlciBleHByZXNzIG9yIGltcGxpZWQuCiBTZWUgdGhl
IExpY2Vuc2UgZm9yIHRoZSBzcGVjaWZpYyBsYW5ndWFnZSBnb3Zlcm5pbmcgcGVybWlzc2lv
bnMgYW5kCiBsaW1pdGF0aW9ucyB1bmRlciB0aGUgTGljZW5zZS4KCggKAQISAxAAJwoICgEI
EgMSADsKCQoCCCUSAxIAOwoICgEIEgMTAGEKCQoCCAsSAxMAYQoICgEIEgMUACIKCQoCCAoS
AxQAIgoICgEIEgMVACwKCQoCCAgSAxUALAoICgEIEgMWADsKCQoCCAESAxYAOwoICgEIEgMX
ADsKCQoCCCkSAxcAOwoICgEIEgMYADoKCQoCCC0SAxgAOgpdCgIEABIEHAAjARpRIE1lc3Nh
Z2UgdGhhdCBjb250YWlucyB0aGUgcmVzb3VyY2UgbmFtZSBhbmQgZGlzcGxheSBuYW1lIG9m
IGEgZm9sZGVyCiByZXNvdXJjZS4KCgoKAwQAARIDHAgOCn4KBAQAAgASAx8CHRpxIEZ1bGwg
cmVzb3VyY2UgbmFtZSBvZiB0aGlzIGZvbGRlci4gU2VlOgogaHR0cHM6Ly9jbG91ZC5nb29n
bGUuY29tL2FwaXMvZGVzaWduL3Jlc291cmNlX25hbWVzI2Z1bGxfcmVzb3VyY2VfbmFtZQoK
DAoFBAACAAUSAx8CCAoMCgUEAAIAARIDHwkYCgwKBQQAAgADEgMfGxwKPQoEBAACARIDIgIq
GjAgVGhlIHVzZXIgZGVmaW5lZCBkaXNwbGF5IG5hbWUgZm9yIHRoaXMgZm9sZGVyLgoKDAoF
BAACAQUSAyICCAoMCgUEAAIBARIDIgklCgwKBQQAAgEDEgMiKCliBnByb3RvMw==
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Securitycenter::V1::Folder::Folder ===
    # Fields for Folder
    # Field: resource_folder Type: 9 ()
    # Field: resource_folder_display_name Type: 9 ()

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Securitycenter::V1::Folder - Compiled Protocol Buffers messages for google/cloud/securitycenter/v1/folder.proto

=head1 SYNOPSIS

    use Google::Cloud::Securitycenter::V1::Folder;

    my $msg = Google::Cloud::Securitycenter::V1::Folder::Folder->new({
        resource_folder => $resource_folder,
        resource_folder_display_name => $resource_folder_display_name,
    });

    # Read or update a field
    my $val = $msg->resource_folder();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Securitycenter::V1::Folder::Folder->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/securitycenter/v1/folder.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Securitycenter::V1::Folder::Folder

Message that contains the resource name and display name of a folder
resource.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->resource_folder() >> / C<< $msg->resource_folder($value) >>

Type: C<String>

Full resource name of this folder. See:
https://cloud.google.com/apis/design/resource_names#full_resource_name

=item * C<< $msg->resource_folder_display_name() >> / C<< $msg->resource_folder_display_name($value) >>

Type: C<String>

The user defined display name for this folder.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Securitycenter::V1::Folder::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
