package Google::Cloud::Datacatalog::V1::Timestamps;

use strict;
use warnings;

our $VERSION = '0.14';

use Protobuf::Message;
use Protobuf::DescriptorPool;
use Protobuf::Internal qw(:all);
use MIME::Base64;

BEGIN {
    eval { require Google::Api::FieldBehavior };
    eval { require Google::Protobuf::Timestamp };
    my $descriptor_b64 = <<'EOF';
Cixnb29nbGUvY2xvdWQvZGF0YWNhdGFsb2cvdjEvdGltZXN0YW1wcy5wcm90bxIbZ29vZ2xl
LmNsb3VkLmRhdGFjYXRhbG9nLnYxGh9nb29nbGUvYXBpL2ZpZWxkX2JlaGF2aW9yLnByb3Rv
Gh9nb29nbGUvcHJvdG9idWYvdGltZXN0YW1wLnByb3RvIs4BChBTeXN0ZW1UaW1lc3RhbXBz
EjsKC2NyZWF0ZV90aW1lGAEgASgLMhouZ29vZ2xlLnByb3RvYnVmLlRpbWVzdGFtcFIKY3Jl
YXRlVGltZRI7Cgt1cGRhdGVfdGltZRgCIAEoCzIaLmdvb2dsZS5wcm90b2J1Zi5UaW1lc3Rh
bXBSCnVwZGF0ZVRpbWUSQAoLZXhwaXJlX3RpbWUYAyABKAsyGi5nb29nbGUucHJvdG9idWYu
VGltZXN0YW1wQgPgQQNSCmV4cGlyZVRpbWVCwwEKH2NvbS5nb29nbGUuY2xvdWQuZGF0YWNh
dGFsb2cudjFQAVpBY2xvdWQuZ29vZ2xlLmNvbS9nby9kYXRhY2F0YWxvZy9hcGl2MS9kYXRh
Y2F0YWxvZ3BiO2RhdGFjYXRhbG9ncGKqAhtHb29nbGUuQ2xvdWQuRGF0YUNhdGFsb2cuVjHK
AhtHb29nbGVcQ2xvdWRcRGF0YUNhdGFsb2dcVjHqAh5Hb29nbGU6OkNsb3VkOjpEYXRhQ2F0
YWxvZzo6VjFK4gsKBhIEDgAvAQq8BAoBDBIDDgASMrEEIENvcHlyaWdodCAyMDI1IEdvb2ds
ZSBMTEMKCiBMaWNlbnNlZCB1bmRlciB0aGUgQXBhY2hlIExpY2Vuc2UsIFZlcnNpb24gMi4w
ICh0aGUgIkxpY2Vuc2UiKTsKIHlvdSBtYXkgbm90IHVzZSB0aGlzIGZpbGUgZXhjZXB0IGlu
IGNvbXBsaWFuY2Ugd2l0aCB0aGUgTGljZW5zZS4KIFlvdSBtYXkgb2J0YWluIGEgY29weSBv
ZiB0aGUgTGljZW5zZSBhdAoKICAgICBodHRwOi8vd3d3LmFwYWNoZS5vcmcvbGljZW5zZXMv
TElDRU5TRS0yLjAKCiBVbmxlc3MgcmVxdWlyZWQgYnkgYXBwbGljYWJsZSBsYXcgb3IgYWdy
ZWVkIHRvIGluIHdyaXRpbmcsIHNvZnR3YXJlCiBkaXN0cmlidXRlZCB1bmRlciB0aGUgTGlj
ZW5zZSBpcyBkaXN0cmlidXRlZCBvbiBhbiAiQVMgSVMiIEJBU0lTLAogV0lUSE9VVCBXQVJS
QU5USUVTIE9SIENPTkRJVElPTlMgT0YgQU5ZIEtJTkQsIGVpdGhlciBleHByZXNzIG9yIGlt
cGxpZWQuCiBTZWUgdGhlIExpY2Vuc2UgZm9yIHRoZSBzcGVjaWZpYyBsYW5ndWFnZSBnb3Zl
cm5pbmcgcGVybWlzc2lvbnMgYW5kCiBsaW1pdGF0aW9ucyB1bmRlciB0aGUgTGljZW5zZS4K
CggKAQISAxAAJAoJCgIDABIDEgApCgkKAgMBEgMTACkKCAoBCBIDFQA4CgkKAgglEgMVADgK
CAoBCBIDFgBYCgkKAggLEgMWAFgKCAoBCBIDFwAiCgkKAggKEgMXACIKCAoBCBIDGAA4CgkK
AggBEgMYADgKCAoBCBIDGQA4CgkKAggpEgMZADgKCAoBCBIDGgA3CgkKAggtEgMaADcKTgoC
BAASBB0ALwEaQiBUaW1lc3RhbXBzIGFzc29jaWF0ZWQgd2l0aCB0aGlzIHJlc291cmNlIGlu
IGEgcGFydGljdWxhciBzeXN0ZW0uCgoKCgMEAAESAx0IGApKCgQEAAIAEgMfAiwaPSBDcmVh
dGlvbiB0aW1lc3RhbXAgb2YgdGhlIHJlc291cmNlIHdpdGhpbiB0aGUgZ2l2ZW4gc3lzdGVt
LgoKDAoFBAACAAYSAx8CGwoMCgUEAAIAARIDHxwnCgwKBQQAAgADEgMfKisKpQIKBAQAAgES
AygCLBqXAiBUaW1lc3RhbXAgb2YgdGhlIGxhc3QgbW9kaWZpY2F0aW9uIG9mIHRoZSByZXNv
dXJjZSBvciBpdHMgbWV0YWRhdGEgd2l0aGluCiBhIGdpdmVuIHN5c3RlbS4KCiBOb3RlOiBE
ZXBlbmRpbmcgb24gdGhlIHNvdXJjZSBzeXN0ZW0sIG5vdCBldmVyeSBtb2RpZmljYXRpb24g
dXBkYXRlcyB0aGlzCiB0aW1lc3RhbXAuCiBGb3IgZXhhbXBsZSwgQmlnUXVlcnkgdGltZXN0
YW1wcyBldmVyeSBtZXRhZGF0YSBtb2RpZmljYXRpb24gYnV0IG5vdCBkYXRhCiBvciBwZXJt
aXNzaW9uIGNoYW5nZXMuCgoMCgUEAAIBBhIDKAIbCgwKBQQAAgEBEgMoHCcKDAoFBAACAQMS
AygqKwqNAQoEBAACAhIELQIuMhp/IE91dHB1dCBvbmx5LiBFeHBpcmF0aW9uIHRpbWVzdGFt
cCBvZiB0aGUgcmVzb3VyY2Ugd2l0aGluIHRoZSBnaXZlbiBzeXN0ZW0uCgogQ3VycmVudGx5
IG9ubHkgYXBwbGljYWJsZSB0byBCaWdRdWVyeSByZXNvdXJjZXMuCgoMCgUEAAICBhIDLQIb
CgwKBQQAAgIBEgMtHCcKDAoFBAACAgMSAy0qKwoMCgUEAAICCBIDLgYxCg8KCAQAAgIInAgA
EgMuBzBiBnByb3RvMw==
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Datacatalog::V1::Timestamps::SystemTimestamps ===
    # Fields for SystemTimestamps
    # Field: create_time Type: 11 (.google.protobuf.Timestamp)
    # Field: update_time Type: 11 (.google.protobuf.Timestamp)
    # Field: expire_time Type: 11 (.google.protobuf.Timestamp)

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Datacatalog::V1::Timestamps - Compiled Protocol Buffers messages for google/cloud/datacatalog/v1/timestamps.proto

=head1 SYNOPSIS

    use Google::Cloud::Datacatalog::V1::Timestamps;

    my $msg = Google::Cloud::Datacatalog::V1::Timestamps::SystemTimestamps->new({
        create_time => $create_time,
        update_time => $update_time,
        expire_time => $expire_time,
    });

    # Read or update a field
    my $val = $msg->create_time();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Datacatalog::V1::Timestamps::SystemTimestamps->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/datacatalog/v1/timestamps.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Datacatalog::V1::Timestamps::SystemTimestamps

Timestamps associated with this resource in a particular system.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->create_time() >> / C<< $msg->create_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Creation timestamp of the resource within the given system.

=item * C<< $msg->update_time() >> / C<< $msg->update_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Timestamp of the last modification of the resource or its metadata within
a given system.

Note: Depending on the source system, not every modification updates this
timestamp.
For example, BigQuery timestamps every metadata modification but not data
or permission changes.

=item * C<< $msg->expire_time() >> / C<< $msg->expire_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Output only. Expiration timestamp of the resource within the given system.

Currently only applicable to BigQuery resources.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Datacatalog::V1::Timestamps::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
