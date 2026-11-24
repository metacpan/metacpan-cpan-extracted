package Google::Cloud::Bigquery::V2::Clustering;

use strict;
use warnings;

our $VERSION = '0.14';

use Protobuf::Message;
use Protobuf::DescriptorPool;
use Protobuf::Internal qw(:all);
use MIME::Base64;

BEGIN {
    my $descriptor_b64 = <<'EOF';
Cilnb29nbGUvY2xvdWQvYmlncXVlcnkvdjIvY2x1c3RlcmluZy5wcm90bxIYZ29vZ2xlLmNs
b3VkLmJpZ3F1ZXJ5LnYyIiQKCkNsdXN0ZXJpbmcSFgoGZmllbGRzGAEgAygJUgZmaWVsZHNC
bAocY29tLmdvb2dsZS5jbG91ZC5iaWdxdWVyeS52MkIPQ2x1c3RlcmluZ1Byb3RvWjtjbG91
ZC5nb29nbGUuY29tL2dvL2JpZ3F1ZXJ5L3YyL2FwaXYyL2JpZ3F1ZXJ5cGI7YmlncXVlcnlw
YkqJCQoGEgQOACEBCrwECgEMEgMOABIysQQgQ29weXJpZ2h0IDIwMjYgR29vZ2xlIExMQwoK
IExpY2Vuc2VkIHVuZGVyIHRoZSBBcGFjaGUgTGljZW5zZSwgVmVyc2lvbiAyLjAgKHRoZSAi
TGljZW5zZSIpOwogeW91IG1heSBub3QgdXNlIHRoaXMgZmlsZSBleGNlcHQgaW4gY29tcGxp
YW5jZSB3aXRoIHRoZSBMaWNlbnNlLgogWW91IG1heSBvYnRhaW4gYSBjb3B5IG9mIHRoZSBM
aWNlbnNlIGF0CgogICAgIGh0dHA6Ly93d3cuYXBhY2hlLm9yZy9saWNlbnNlcy9MSUNFTlNF
LTIuMAoKIFVubGVzcyByZXF1aXJlZCBieSBhcHBsaWNhYmxlIGxhdyBvciBhZ3JlZWQgdG8g
aW4gd3JpdGluZywgc29mdHdhcmUKIGRpc3RyaWJ1dGVkIHVuZGVyIHRoZSBMaWNlbnNlIGlz
IGRpc3RyaWJ1dGVkIG9uIGFuICJBUyBJUyIgQkFTSVMsCiBXSVRIT1VUIFdBUlJBTlRJRVMg
T1IgQ09ORElUSU9OUyBPRiBBTlkgS0lORCwgZWl0aGVyIGV4cHJlc3Mgb3IgaW1wbGllZC4K
IFNlZSB0aGUgTGljZW5zZSBmb3IgdGhlIHNwZWNpZmljIGxhbmd1YWdlIGdvdmVybmluZyBw
ZXJtaXNzaW9ucyBhbmQKIGxpbWl0YXRpb25zIHVuZGVyIHRoZSBMaWNlbnNlLgoKCAoBAhID
EAAhCggKAQgSAxIAUgoJCgIICxIDEgBSCggKAQgSAxMAMAoJCgIICBIDEwAwCggKAQgSAxQA
NQoJCgIIARIDFAA1CioKAgQAEgQXACEBGh4gQ29uZmlndXJlcyB0YWJsZSBjbHVzdGVyaW5n
LgoKCgoDBAABEgMXCBIKhgMKBAQAAgASAyACHRr4AiBPbmUgb3IgbW9yZSBmaWVsZHMgb24g
d2hpY2ggZGF0YSBzaG91bGQgYmUgY2x1c3RlcmVkLiBPbmx5IHRvcC1sZXZlbCwKIG5vbi1y
ZXBlYXRlZCwgc2ltcGxlLXR5cGUgZmllbGRzIGFyZSBzdXBwb3J0ZWQuIFRoZSBvcmRlcmlu
ZyBvZiB0aGUKIGNsdXN0ZXJpbmcgZmllbGRzIHNob3VsZCBiZSBwcmlvcml0aXplZCBmcm9t
IG1vc3QgdG8gbGVhc3QgaW1wb3J0YW50CiBmb3IgZmlsdGVyaW5nIHB1cnBvc2VzLgoKIEZv
ciBhZGRpdGlvbmFsIGluZm9ybWF0aW9uLCBzZWUKIFtJbnRyb2R1Y3Rpb24gdG8gY2x1c3Rl
cmVkCiB0YWJsZXNdKGh0dHBzOi8vY2xvdWQuZ29vZ2xlLmNvbS9iaWdxdWVyeS9kb2NzL2Ns
dXN0ZXJlZC10YWJsZXMjbGltaXRhdGlvbnMpLgoKDAoFBAACAAQSAyACCgoMCgUEAAIABRID
IAsRCgwKBQQAAgABEgMgEhgKDAoFBAACAAMSAyAbHGIGcHJvdG8z
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Bigquery::V2::Clustering::Clustering ===
    # Fields for Clustering
    # Field: fields Type: 9 ()

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Bigquery::V2::Clustering - Compiled Protocol Buffers messages for google/cloud/bigquery/v2/clustering.proto

=head1 SYNOPSIS

    use Google::Cloud::Bigquery::V2::Clustering;

    my $msg = Google::Cloud::Bigquery::V2::Clustering::Clustering->new({
        fields => $fields,
    });

    # Read or update a field
    my $val = $msg->fields();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Bigquery::V2::Clustering::Clustering->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/bigquery/v2/clustering.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Bigquery::V2::Clustering::Clustering

Configures table clustering.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->fields() >> / C<< $msg->fields($value) >>

Type: C<String>

One or more fields on which data should be clustered. Only top-level,
non-repeated, simple-type fields are supported. The ordering of the
clustering fields should be prioritized from most to least important
for filtering purposes.

For additional information, see
[Introduction to clustered
tables](https://cloud.google.com/bigquery/docs/clustered-tables#limitations).

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Bigquery::V2::Clustering::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
