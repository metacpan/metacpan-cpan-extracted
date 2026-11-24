package Google::Cloud::Ces::V1::SystemTool;

use strict;
use warnings;

our $VERSION = '0.14';

use Protobuf::Message;
use Protobuf::DescriptorPool;
use Protobuf::Internal qw(:all);
use MIME::Base64;

BEGIN {
    eval { require Google::Api::FieldBehavior };
    my $descriptor_b64 = <<'EOF';
CiVnb29nbGUvY2xvdWQvY2VzL3YxL3N5c3RlbV90b29sLnByb3RvEhNnb29nbGUuY2xvdWQu
Y2VzLnYxGh9nb29nbGUvYXBpL2ZpZWxkX2JlaGF2aW9yLnByb3RvIkwKClN5c3RlbVRvb2wS
FwoEbmFtZRgBIAEoCUID4EECUgRuYW1lEiUKC2Rlc2NyaXB0aW9uGAIgASgJQgPgQQNSC2Rl
c2NyaXB0aW9uQlcKF2NvbS5nb29nbGUuY2xvdWQuY2VzLnYxQg9TeXN0ZW1Ub29sUHJvdG9Q
AVopY2xvdWQuZ29vZ2xlLmNvbS9nby9jZXMvYXBpdjEvY2VzcGI7Y2VzcGJK7gcKBhIEDgAg
AQq8BAoBDBIDDgASMrEEIENvcHlyaWdodCAyMDI2IEdvb2dsZSBMTEMKCiBMaWNlbnNlZCB1
bmRlciB0aGUgQXBhY2hlIExpY2Vuc2UsIFZlcnNpb24gMi4wICh0aGUgIkxpY2Vuc2UiKTsK
IHlvdSBtYXkgbm90IHVzZSB0aGlzIGZpbGUgZXhjZXB0IGluIGNvbXBsaWFuY2Ugd2l0aCB0
aGUgTGljZW5zZS4KIFlvdSBtYXkgb2J0YWluIGEgY29weSBvZiB0aGUgTGljZW5zZSBhdAoK
ICAgICBodHRwOi8vd3d3LmFwYWNoZS5vcmcvbGljZW5zZXMvTElDRU5TRS0yLjAKCiBVbmxl
c3MgcmVxdWlyZWQgYnkgYXBwbGljYWJsZSBsYXcgb3IgYWdyZWVkIHRvIGluIHdyaXRpbmcs
IHNvZnR3YXJlCiBkaXN0cmlidXRlZCB1bmRlciB0aGUgTGljZW5zZSBpcyBkaXN0cmlidXRl
ZCBvbiBhbiAiQVMgSVMiIEJBU0lTLAogV0lUSE9VVCBXQVJSQU5USUVTIE9SIENPTkRJVElP
TlMgT0YgQU5ZIEtJTkQsIGVpdGhlciBleHByZXNzIG9yIGltcGxpZWQuCiBTZWUgdGhlIExp
Y2Vuc2UgZm9yIHRoZSBzcGVjaWZpYyBsYW5ndWFnZSBnb3Zlcm5pbmcgcGVybWlzc2lvbnMg
YW5kCiBsaW1pdGF0aW9ucyB1bmRlciB0aGUgTGljZW5zZS4KCggKAQISAxAAHAoJCgIDABID
EgApCggKAQgSAxQAQAoJCgIICxIDFABACggKAQgSAxUAIgoJCgIIChIDFQAiCggKAQgSAxYA
MAoJCgIICBIDFgAwCggKAQgSAxcAMAoJCgIIARIDFwAwCiYKAgQAEgQaACABGhogUHJlLWRl
ZmluZWQgc3lzdGVtIHRvb2wuCgoKCgMEAAESAxoIEgo1CgQEAAIAEgMcAjsaKCBSZXF1aXJl
ZC4gVGhlIG5hbWUgb2YgdGhlIHN5c3RlbSB0b29sLgoKDAoFBAACAAUSAxwCCAoMCgUEAAIA
ARIDHAkNCgwKBQQAAgADEgMcEBEKDAoFBAACAAgSAxwSOgoPCggEAAIACJwIABIDHBM5Cj8K
BAQAAgESAx8CRRoyIE91dHB1dCBvbmx5LiBUaGUgZGVzY3JpcHRpb24gb2YgdGhlIHN5c3Rl
bSB0b29sLgoKDAoFBAACAQUSAx8CCAoMCgUEAAIBARIDHwkUCgwKBQQAAgEDEgMfFxgKDAoF
BAACAQgSAx8ZRAoPCggEAAIBCJwIABIDHxpDYgZwcm90bzM=
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Ces::V1::SystemTool::SystemTool ===
    # Fields for SystemTool
    # Field: name Type: 9 ()
    # Field: description Type: 9 ()

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Ces::V1::SystemTool - Compiled Protocol Buffers messages for google/cloud/ces/v1/system_tool.proto

=head1 SYNOPSIS

    use Google::Cloud::Ces::V1::SystemTool;

    my $msg = Google::Cloud::Ces::V1::SystemTool::SystemTool->new({
        name => $name,
        description => $description,
    });

    # Read or update a field
    my $val = $msg->name();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Ces::V1::SystemTool::SystemTool->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/ces/v1/system_tool.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Ces::V1::SystemTool::SystemTool

Pre-defined system tool.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. The name of the system tool.

=item * C<< $msg->description() >> / C<< $msg->description($value) >>

Type: C<String>

Output only. The description of the system tool.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Ces::V1::SystemTool::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
