package Google::Cloud::Securitycenter::V1::LoadBalancer;

use strict;
use warnings;

our $VERSION = '0.14';

use Protobuf::Message;
use Protobuf::DescriptorPool;
use Protobuf::Internal qw(:all);
use MIME::Base64;

BEGIN {
    my $descriptor_b64 = <<'EOF';
CjJnb29nbGUvY2xvdWQvc2VjdXJpdHljZW50ZXIvdjEvbG9hZF9iYWxhbmNlci5wcm90bxIe
Z29vZ2xlLmNsb3VkLnNlY3VyaXR5Y2VudGVyLnYxIiIKDExvYWRCYWxhbmNlchISCgRuYW1l
GAEgASgJUgRuYW1lQusBCiJjb20uZ29vZ2xlLmNsb3VkLnNlY3VyaXR5Y2VudGVyLnYxQhFM
b2FkQmFsYW5jZXJQcm90b1ABWkpjbG91ZC5nb29nbGUuY29tL2dvL3NlY3VyaXR5Y2VudGVy
L2FwaXYxL3NlY3VyaXR5Y2VudGVycGI7c2VjdXJpdHljZW50ZXJwYqoCHkdvb2dsZS5DbG91
ZC5TZWN1cml0eUNlbnRlci5WMcoCHkdvb2dsZVxDbG91ZFxTZWN1cml0eUNlbnRlclxWMeoC
IUdvb2dsZTo6Q2xvdWQ6OlNlY3VyaXR5Q2VudGVyOjpWMUrEBwoGEgQOAB8BCrwECgEMEgMO
ABIysQQgQ29weXJpZ2h0IDIwMjUgR29vZ2xlIExMQwoKIExpY2Vuc2VkIHVuZGVyIHRoZSBB
cGFjaGUgTGljZW5zZSwgVmVyc2lvbiAyLjAgKHRoZSAiTGljZW5zZSIpOwogeW91IG1heSBu
b3QgdXNlIHRoaXMgZmlsZSBleGNlcHQgaW4gY29tcGxpYW5jZSB3aXRoIHRoZSBMaWNlbnNl
LgogWW91IG1heSBvYnRhaW4gYSBjb3B5IG9mIHRoZSBMaWNlbnNlIGF0CgogICAgIGh0dHA6
Ly93d3cuYXBhY2hlLm9yZy9saWNlbnNlcy9MSUNFTlNFLTIuMAoKIFVubGVzcyByZXF1aXJl
ZCBieSBhcHBsaWNhYmxlIGxhdyBvciBhZ3JlZWQgdG8gaW4gd3JpdGluZywgc29mdHdhcmUK
IGRpc3RyaWJ1dGVkIHVuZGVyIHRoZSBMaWNlbnNlIGlzIGRpc3RyaWJ1dGVkIG9uIGFuICJB
UyBJUyIgQkFTSVMsCiBXSVRIT1VUIFdBUlJBTlRJRVMgT1IgQ09ORElUSU9OUyBPRiBBTlkg
S0lORCwgZWl0aGVyIGV4cHJlc3Mgb3IgaW1wbGllZC4KIFNlZSB0aGUgTGljZW5zZSBmb3Ig
dGhlIHNwZWNpZmljIGxhbmd1YWdlIGdvdmVybmluZyBwZXJtaXNzaW9ucyBhbmQKIGxpbWl0
YXRpb25zIHVuZGVyIHRoZSBMaWNlbnNlLgoKCAoBAhIDEAAnCggKAQgSAxIAOwoJCgIIJRID
EgA7CggKAQgSAxMAYQoJCgIICxIDEwBhCggKAQgSAxQAIgoJCgIIChIDFAAiCggKAQgSAxUA
MgoJCgIICBIDFQAyCggKAQgSAxYAOwoJCgIIARIDFgA7CggKAQgSAxcAOwoJCgIIKRIDFwA7
CggKAQgSAxgAOgoJCgIILRIDGAA6Cl0KAgQAEgQcAB8BGlEgQ29udGFpbnMgaW5mb3JtYXRp
b24gcmVsYXRlZCB0byB0aGUgbG9hZCBiYWxhbmNlciBhc3NvY2lhdGVkIHdpdGggdGhlCiBm
aW5kaW5nLgoKCgoDBAABEgMcCBQKSQoEBAACABIDHgISGjwgVGhlIG5hbWUgb2YgdGhlIGxv
YWQgYmFsYW5jZXIgYXNzb2NpYXRlZCB3aXRoIHRoZSBmaW5kaW5nLgoKDAoFBAACAAUSAx4C
CAoMCgUEAAIAARIDHgkNCgwKBQQAAgADEgMeEBFiBnByb3RvMw==
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Securitycenter::V1::LoadBalancer::LoadBalancer ===
    # Fields for LoadBalancer
    # Field: name Type: 9 ()

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Securitycenter::V1::LoadBalancer - Compiled Protocol Buffers messages for google/cloud/securitycenter/v1/load_balancer.proto

=head1 SYNOPSIS

    use Google::Cloud::Securitycenter::V1::LoadBalancer;

    my $msg = Google::Cloud::Securitycenter::V1::LoadBalancer::LoadBalancer->new({
        name => $name,
    });

    # Read or update a field
    my $val = $msg->name();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Securitycenter::V1::LoadBalancer::LoadBalancer->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/securitycenter/v1/load_balancer.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Securitycenter::V1::LoadBalancer::LoadBalancer

Contains information related to the load balancer associated with the
finding.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

The name of the load balancer associated with the finding.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Securitycenter::V1::LoadBalancer::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
