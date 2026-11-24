package Google::Cloud::Geminidataanalytics::V1beta::Usage;

use strict;
use warnings;

our $VERSION = '0.14';

use Protobuf::Message;
use Protobuf::DescriptorPool;
use Protobuf::Internal qw(:all);
use MIME::Base64;

BEGIN {
    my $descriptor_b64 = <<'EOF';
CjNnb29nbGUvY2xvdWQvZ2VtaW5pZGF0YWFuYWx5dGljcy92MWJldGEvdXNhZ2UucHJvdG8S
J2dvb2dsZS5jbG91ZC5nZW1pbmlkYXRhYW5hbHl0aWNzLnYxYmV0YSJmCgpUb2tlblVzYWdl
EioKEWlucHV0X3Rva2VuX2NvdW50GAEgASgFUg9pbnB1dFRva2VuQ291bnQSLAoSb3V0cHV0
X3Rva2VuX2NvdW50GAIgASgFUhBvdXRwdXRUb2tlbkNvdW50QpsCCitjb20uZ29vZ2xlLmNs
b3VkLmdlbWluaWRhdGFhbmFseXRpY3MudjFiZXRhQgpVc2FnZVByb3RvUAFaXWNsb3VkLmdv
b2dsZS5jb20vZ28vZ2VtaW5pZGF0YWFuYWx5dGljcy9hcGl2MWJldGEvZ2VtaW5pZGF0YWFu
YWx5dGljc3BiO2dlbWluaWRhdGFhbmFseXRpY3NwYqoCJ0dvb2dsZS5DbG91ZC5HZW1pbmlE
YXRhQW5hbHl0aWNzLlYxQmV0YcoCJ0dvb2dsZVxDbG91ZFxHZW1pbmlEYXRhQW5hbHl0aWNz
XFYxYmV0YeoCKkdvb2dsZTo6Q2xvdWQ6OkdlbWluaURhdGFBbmFseXRpY3M6OlYxYmV0YUqR
CAoGEgQOACEBCrwECgEMEgMOABIysQQgQ29weXJpZ2h0IDIwMjYgR29vZ2xlIExMQwoKIExp
Y2Vuc2VkIHVuZGVyIHRoZSBBcGFjaGUgTGljZW5zZSwgVmVyc2lvbiAyLjAgKHRoZSAiTGlj
ZW5zZSIpOwogeW91IG1heSBub3QgdXNlIHRoaXMgZmlsZSBleGNlcHQgaW4gY29tcGxpYW5j
ZSB3aXRoIHRoZSBMaWNlbnNlLgogWW91IG1heSBvYnRhaW4gYSBjb3B5IG9mIHRoZSBMaWNl
bnNlIGF0CgogICAgIGh0dHA6Ly93d3cuYXBhY2hlLm9yZy9saWNlbnNlcy9MSUNFTlNFLTIu
MAoKIFVubGVzcyByZXF1aXJlZCBieSBhcHBsaWNhYmxlIGxhdyBvciBhZ3JlZWQgdG8gaW4g
d3JpdGluZywgc29mdHdhcmUKIGRpc3RyaWJ1dGVkIHVuZGVyIHRoZSBMaWNlbnNlIGlzIGRp
c3RyaWJ1dGVkIG9uIGFuICJBUyBJUyIgQkFTSVMsCiBXSVRIT1VUIFdBUlJBTlRJRVMgT1Ig
Q09ORElUSU9OUyBPRiBBTlkgS0lORCwgZWl0aGVyIGV4cHJlc3Mgb3IgaW1wbGllZC4KIFNl
ZSB0aGUgTGljZW5zZSBmb3IgdGhlIHNwZWNpZmljIGxhbmd1YWdlIGdvdmVybmluZyBwZXJt
aXNzaW9ucyBhbmQKIGxpbWl0YXRpb25zIHVuZGVyIHRoZSBMaWNlbnNlLgoKCAoBAhIDEAAw
CggKAQgSAxIARAoJCgIIJRIDEgBECggKAQgSAxMAdAoJCgIICxIDEwB0CggKAQgSAxQAIgoJ
CgIIChIDFAAiCggKAQgSAxUAKwoJCgIICBIDFQArCggKAQgSAxYARAoJCgIIARIDFgBECggK
AQgSAxcARAoJCgIIKRIDFwBECggKAQgSAxgAQwoJCgIILRIDGABDCjwKAgQAEgQbACEBGjAg
T3ZlcmFsbCB0b2tlbiB1c2FnZSB0cmFja2luZyBmb3IgdGhlIHJlc3BvbnNlLgoKCgoDBAAB
EgMbCBIKRQoEBAACABIDHQIeGjggVGhlIHRvdGFsIG51bWJlciBvZiBpbnB1dCB0b2tlbnMg
dXNlZCBpbiB0aGlzIHJlcXVlc3QuCgoMCgUEAAIABRIDHQIHCgwKBQQAAgABEgMdCBkKDAoF
BAACAAMSAx0cHQpGCgQEAAIBEgMgAh8aOSBUaGUgdG90YWwgbnVtYmVyIG9mIG91dHB1dCB0
b2tlbnMgdXNlZCBpbiB0aGlzIHJlcXVlc3QuCgoMCgUEAAIBBRIDIAIHCgwKBQQAAgEBEgMg
CBoKDAoFBAACAQMSAyAdHmIGcHJvdG8z
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Geminidataanalytics::V1beta::Usage::TokenUsage ===
    # Fields for TokenUsage
    # Field: input_token_count Type: 5 ()
    # Field: output_token_count Type: 5 ()

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Geminidataanalytics::V1beta::Usage - Compiled Protocol Buffers messages for google/cloud/geminidataanalytics/v1beta/usage.proto

=head1 SYNOPSIS

    use Google::Cloud::Geminidataanalytics::V1beta::Usage;

    my $msg = Google::Cloud::Geminidataanalytics::V1beta::Usage::TokenUsage->new({
        input_token_count => $input_token_count,
        output_token_count => $output_token_count,
    });

    # Read or update a field
    my $val = $msg->input_token_count();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Geminidataanalytics::V1beta::Usage::TokenUsage->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/geminidataanalytics/v1beta/usage.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Geminidataanalytics::V1beta::Usage::TokenUsage

Overall token usage tracking for the response.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->input_token_count() >> / C<< $msg->input_token_count($value) >>

Type: C<Int32>

The total number of input tokens used in this request.

=item * C<< $msg->output_token_count() >> / C<< $msg->output_token_count($value) >>

Type: C<Int32>

The total number of output tokens used in this request.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Geminidataanalytics::V1beta::Usage::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
