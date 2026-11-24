package Google::Cloud::Kms::Inventory::V1::KeyDashboardService;

use strict;
use warnings;

our $VERSION = '0.14';

use Protobuf::Message;
use Protobuf::DescriptorPool;
use Protobuf::Internal qw(:all);
use MIME::Base64;

BEGIN {
    eval { require Google::Api::Annotations };
    eval { require Google::Api::Client };
    eval { require Google::Api::FieldBehavior };
    eval { require Google::Api::Resource };
    eval { require Google::Cloud::Kms::V1::Resources };
    my $descriptor_b64 = <<'EOF';
Cjlnb29nbGUvY2xvdWQva21zL2ludmVudG9yeS92MS9rZXlfZGFzaGJvYXJkX3NlcnZpY2Uu
cHJvdG8SHWdvb2dsZS5jbG91ZC5rbXMuaW52ZW50b3J5LnYxGhxnb29nbGUvYXBpL2Fubm90
YXRpb25zLnByb3RvGhdnb29nbGUvYXBpL2NsaWVudC5wcm90bxofZ29vZ2xlL2FwaS9maWVs
ZF9iZWhhdmlvci5wcm90bxoZZ29vZ2xlL2FwaS9yZXNvdXJjZS5wcm90bxojZ29vZ2xlL2Ns
b3VkL2ttcy92MS9yZXNvdXJjZXMucHJvdG8iqgEKFUxpc3RDcnlwdG9LZXlzUmVxdWVzdBJL
CgZwYXJlbnQYASABKAlCM+BBAvpBLQorY2xvdWRyZXNvdXJjZW1hbmFnZXIuZ29vZ2xlYXBp
cy5jb20vUHJvamVjdFIGcGFyZW50EiAKCXBhZ2Vfc2l6ZRgCIAEoBUID4EEBUghwYWdlU2l6
ZRIiCgpwYWdlX3Rva2VuGAMgASgJQgPgQQFSCXBhZ2VUb2tlbiKBAQoWTGlzdENyeXB0b0tl
eXNSZXNwb25zZRI/CgtjcnlwdG9fa2V5cxgBIAMoCzIeLmdvb2dsZS5jbG91ZC5rbXMudjEu
Q3J5cHRvS2V5UgpjcnlwdG9LZXlzEiYKD25leHRfcGFnZV90b2tlbhgCIAEoCVINbmV4dFBh
Z2VUb2tlbjKbAgoTS2V5RGFzaGJvYXJkU2VydmljZRKyAQoOTGlzdENyeXB0b0tleXMSNC5n
b29nbGUuY2xvdWQua21zLmludmVudG9yeS52MS5MaXN0Q3J5cHRvS2V5c1JlcXVlc3QaNS5n
b29nbGUuY2xvdWQua21zLmludmVudG9yeS52MS5MaXN0Q3J5cHRvS2V5c1Jlc3BvbnNlIjOC
0+STAiQSIi92MS97cGFyZW50PXByb2plY3RzLyp9L2NyeXB0b0tleXPaQQZwYXJlbnQaT8pB
G2ttc2ludmVudG9yeS5nb29nbGVhcGlzLmNvbdJBLmh0dHBzOi8vd3d3Lmdvb2dsZWFwaXMu
Y29tL2F1dGgvY2xvdWQtcGxhdGZvcm1CwAEKIWNvbS5nb29nbGUuY2xvdWQua21zLmludmVu
dG9yeS52MUIYS2V5RGFzaGJvYXJkU2VydmljZVByb3RvUAFaP2Nsb3VkLmdvb2dsZS5jb20v
Z28va21zL2ludmVudG9yeS9hcGl2MS9pbnZlbnRvcnlwYjtpbnZlbnRvcnlwYqoCHUdvb2ds
ZS5DbG91ZC5LbXMuSW52ZW50b3J5LlYxygIdR29vZ2xlXENsb3VkXEttc1xJbnZlbnRvcnlc
VjFK6xMKBhIEDgBPAQq8BAoBDBIDDgASMrEEIENvcHlyaWdodCAyMDI2IEdvb2dsZSBMTEMK
CiBMaWNlbnNlZCB1bmRlciB0aGUgQXBhY2hlIExpY2Vuc2UsIFZlcnNpb24gMi4wICh0aGUg
IkxpY2Vuc2UiKTsKIHlvdSBtYXkgbm90IHVzZSB0aGlzIGZpbGUgZXhjZXB0IGluIGNvbXBs
aWFuY2Ugd2l0aCB0aGUgTGljZW5zZS4KIFlvdSBtYXkgb2J0YWluIGEgY29weSBvZiB0aGUg
TGljZW5zZSBhdAoKICAgICBodHRwOi8vd3d3LmFwYWNoZS5vcmcvbGljZW5zZXMvTElDRU5T
RS0yLjAKCiBVbmxlc3MgcmVxdWlyZWQgYnkgYXBwbGljYWJsZSBsYXcgb3IgYWdyZWVkIHRv
IGluIHdyaXRpbmcsIHNvZnR3YXJlCiBkaXN0cmlidXRlZCB1bmRlciB0aGUgTGljZW5zZSBp
cyBkaXN0cmlidXRlZCBvbiBhbiAiQVMgSVMiIEJBU0lTLAogV0lUSE9VVCBXQVJSQU5USUVT
IE9SIENPTkRJVElPTlMgT0YgQU5ZIEtJTkQsIGVpdGhlciBleHByZXNzIG9yIGltcGxpZWQu
CiBTZWUgdGhlIExpY2Vuc2UgZm9yIHRoZSBzcGVjaWZpYyBsYW5ndWFnZSBnb3Zlcm5pbmcg
cGVybWlzc2lvbnMgYW5kCiBsaW1pdGF0aW9ucyB1bmRlciB0aGUgTGljZW5zZS4KCggKAQIS
AxAAJgoJCgIDABIDEgAmCgkKAgMBEgMTACEKCQoCAwISAxQAKQoJCgIDAxIDFQAjCgkKAgME
EgMWAC0KCAoBCBIDGAA6CgkKAgglEgMYADoKCAoBCBIDGQBWCgkKAggLEgMZAFYKCAoBCBID
GgAiCgkKAggKEgMaACIKCAoBCBIDGwA5CgkKAggIEgMbADkKCAoBCBIDHAA6CgkKAggBEgMc
ADoKCAoBCBIDHQA7CgkKAggpEgMdADsKWgoCBgASBCAALgEaTiBQcm92aWRlcyBhIGNyb3Nz
LXJlZ2lvbiB2aWV3IG9mIGFsbCBDbG91ZCBLTVMga2V5cyBpbiBhIGdpdmVuIENsb3VkIHBy
b2plY3QuCgoKCgMGAAESAyAIGwoKCgMGAAMSAyECQwoMCgUGAAOZCBIDIQJDCgsKAwYAAxIE
IgIjNwoNCgUGAAOaCBIEIgIjNwrgAQoEBgACABIEKAItAxrRASBSZXR1cm5zIGNyeXB0b2dy
YXBoaWMga2V5cyBtYW5hZ2VkIGJ5IENsb3VkIEtNUyBpbiBhIGdpdmVuIENsb3VkIHByb2pl
Y3QuCiBOb3RlIHRoYXQgdGhpcyBkYXRhIGlzIHNvdXJjZWQgZnJvbSBzbmFwc2hvdHMsIG1l
YW5pbmcgaXQgbWF5IG5vdAogY29tcGxldGVseSByZWZsZWN0IHRoZSBhY3R1YWwgc3RhdGUg
b2Yga2V5IG1ldGFkYXRhIGF0IGNhbGwgdGltZS4KCgwKBQYAAgABEgMoBhQKDAoFBgACAAIS
AygVKgoMCgUGAAIAAxIDKDVLCg0KBQYAAgAEEgQpBCsGChEKCQYAAgAEsMq8IhIEKQQrBgoM
CgUGAAIABBIDLAQ0Cg8KCAYAAgAEmwgAEgMsBDQKigEKAgQAEgQyAEQBGn4gUmVxdWVzdCBt
ZXNzYWdlIGZvcgogW0tleURhc2hib2FyZFNlcnZpY2UuTGlzdENyeXB0b0tleXNdW2dvb2ds
ZS5jbG91ZC5rbXMuaW52ZW50b3J5LnYxLktleURhc2hib2FyZFNlcnZpY2UuTGlzdENyeXB0
b0tleXNdLgoKCgoDBAABEgMyCB0KcgoEBAACABIENQI6BBpkIFJlcXVpcmVkLiBUaGUgR29v
Z2xlIENsb3VkIHByb2plY3QgZm9yIHdoaWNoIHRvIHJldHJpZXZlIGtleSBtZXRhZGF0YSwg
aW4KIHRoZSBmb3JtYXQgYHByb2plY3RzLypgCgoMCgUEAAIABRIDNQIICgwKBQQAAgABEgM1
CQ8KDAoFBAACAAMSAzUSEwoNCgUEAAIACBIENRQ6AwoPCggEAAIACJwIABIDNgQqCg8KBwQA
AgAInwgSBDcEOQUK6QEKBAQAAgESAz8CPxrbASBPcHRpb25hbC4gVGhlIG1heGltdW0gbnVt
YmVyIG9mIGtleXMgdG8gcmV0dXJuLiBUaGUgc2VydmljZSBtYXkgcmV0dXJuCiBmZXdlciB0
aGFuIHRoaXMgdmFsdWUuIElmIHVuc3BlY2lmaWVkLCBhdCBtb3N0IDEwMDAga2V5cyB3aWxs
IGJlIHJldHVybmVkLgogVGhlIG1heGltdW0gdmFsdWUgaXMgMTAwMDsgdmFsdWVzIGFib3Zl
IDEwMDAgd2lsbCBiZSBjb2VyY2VkIHRvIDEwMDAuCgoMCgUEAAIBBRIDPwIHCgwKBQQAAgEB
EgM/CBEKDAoFBAACAQMSAz8UFQoMCgUEAAIBCBIDPxY+Cg8KCAQAAgEInAgAEgM/Fz0KawoE
BAACAhIDQwJBGl4gT3B0aW9uYWwuIFBhc3MgdGhpcyBpbnRvIGEgc3Vic2VxdWVudCByZXF1
ZXN0IGluIG9yZGVyIHRvIHJlY2VpdmUgdGhlIG5leHQKIHBhZ2Ugb2YgcmVzdWx0cy4KCgwK
BQQAAgIFEgNDAggKDAoFBAACAgESA0MJEwoMCgUEAAICAxIDQxYXCgwKBQQAAgIIEgNDGEAK
DwoIBAACAgicCAASA0MZPwqLAQoCBAESBEgATwEafyBSZXNwb25zZSBtZXNzYWdlIGZvcgog
W0tleURhc2hib2FyZFNlcnZpY2UuTGlzdENyeXB0b0tleXNdW2dvb2dsZS5jbG91ZC5rbXMu
aW52ZW50b3J5LnYxLktleURhc2hib2FyZFNlcnZpY2UuTGlzdENyeXB0b0tleXNdLgoKCgoD
BAEBEgNICB4KRwoEBAECABIDSgI5GjogVGhlIGxpc3Qgb2YgW0NyeXB0b0tleXNdW2dvb2ds
ZS5jbG91ZC5rbXMudjEuQ3J5cHRvS2V5XS4KCgwKBQQBAgAEEgNKAgoKDAoFBAECAAYSA0oL
KAoMCgUEAQIAARIDSik0CgwKBQQBAgADEgNKNzgKXwoEBAECARIDTgIdGlIgVGhlIHBhZ2Ug
dG9rZW4gcmV0dXJuZWQgZnJvbSB0aGUgcHJldmlvdXMgcmVzcG9uc2UgaWYgdGhlIG5leHQg
cGFnZSBpcwogZGVzaXJlZC4KCgwKBQQBAgEFEgNOAggKDAoFBAECAQESA04JGAoMCgUEAQIB
AxIDThscYgZwcm90bzM=
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Kms::Inventory::V1::KeyDashboardService::ListCryptoKeysRequest ===
    # Fields for ListCryptoKeysRequest
    # Field: parent Type: 9 ()
    # Field: page_size Type: 5 ()
    # Field: page_token Type: 9 ()

# === Message: Google::Cloud::Kms::Inventory::V1::KeyDashboardService::ListCryptoKeysResponse ===
    # Fields for ListCryptoKeysResponse
    # Field: crypto_keys Type: 11 (.google.cloud.kms.v1.CryptoKey)
    # Field: next_page_token Type: 9 ()

# === Service Client: Google::Cloud::Kms::Inventory::V1::KeyDashboardService::KeyDashboardServiceClient ===
package Google::Cloud::Kms::Inventory::V1::KeyDashboardService::KeyDashboardServiceClient;

=pod

=head2 Service Client: Google::Cloud::Kms::Inventory::V1::KeyDashboardService::KeyDashboardServiceClient

Client stub representing the remote C<KeyDashboardService> gRPC service. Delegates call dispatching to L<Google::gRPC::Client>.

=head3 target

The endpoint target address. Defaults to C<kms.googleapis.com:443>.

=head3 credentials

The authentication credentials provider. Defaults to application default credentials via L<Google::Auth>.

=cut

use Moo;
use Google::Auth;
use Google::gRPC::Client;

has credentials => ( is => 'ro', default => sub { Google::Auth->default() } );
has target      => ( is => 'ro', default => 'kms.googleapis.com:443' );

has _grpc_client => (
    is => 'ro',
    lazy => 1,
    builder => sub {
        my $self = shift;
        return Google::gRPC::Client->new(
            target     => $self->target,
            auth_token => $self->credentials->get_token(),
        );
    }
);

sub list_crypto_keys {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Kms::Inventory::V1::KeyDashboardService::ListCryptoKeysRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.kms.inventory.v1.KeyDashboardService',
        method         => 'ListCryptoKeys',
        request        => $req,
        response_class => 'Google::Cloud::Kms::Inventory::V1::KeyDashboardService::ListCryptoKeysResponse',
    });
}

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Kms::Inventory::V1::KeyDashboardService - Compiled Protocol Buffers messages for google/cloud/kms/inventory/v1/key_dashboard_service.proto

=head1 SYNOPSIS

    use Google::Cloud::Kms::Inventory::V1::KeyDashboardService;

    my $msg = Google::Cloud::Kms::Inventory::V1::KeyDashboardService::ListCryptoKeysRequest->new({
        parent => $parent,
        page_size => $page_size,
        page_token => $page_token,
    });

    # Read or update a field
    my $val = $msg->parent();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Kms::Inventory::V1::KeyDashboardService::ListCryptoKeysRequest->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/kms/inventory/v1/key_dashboard_service.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Kms::Inventory::V1::KeyDashboardService::ListCryptoKeysRequest

Request message for
[KeyDashboardService.ListCryptoKeys][google.cloud.kms.inventory.v1.KeyDashboardService.ListCryptoKeys].

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->parent() >> / C<< $msg->parent($value) >>

Type: C<String>

Required. The Google Cloud project for which to retrieve key metadata, in
the format `projects/*`

=item * C<< $msg->page_size() >> / C<< $msg->page_size($value) >>

Type: C<Int32>

Optional. The maximum number of keys to return. The service may return
fewer than this value. If unspecified, at most 1000 keys will be returned.
The maximum value is 1000; values above 1000 will be coerced to 1000.

=item * C<< $msg->page_token() >> / C<< $msg->page_token($value) >>

Type: C<String>

Optional. Pass this into a subsequent request in order to receive the next
page of results.

=back

=head2 Google::Cloud::Kms::Inventory::V1::KeyDashboardService::ListCryptoKeysResponse

Response message for
[KeyDashboardService.ListCryptoKeys][google.cloud.kms.inventory.v1.KeyDashboardService.ListCryptoKeys].

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->crypto_keys() >> / C<< $msg->crypto_keys($value) >>

Type: C<Message> (L<Google::Cloud::Kms::V1::Resources::CryptoKey>)

The list of [CryptoKeys][google.cloud.kms.v1.CryptoKey].

=item * C<< $msg->next_page_token() >> / C<< $msg->next_page_token($value) >>

Type: C<String>

The page token returned from the previous response if the next page is
desired.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Kms::Inventory::V1::KeyDashboardService::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
