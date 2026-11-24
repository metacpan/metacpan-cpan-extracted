package Google::Cloud::Commerceproducer::V1beta::SkuGroup;

use strict;
use warnings;

our $VERSION = '0.14';

use Protobuf::Message;
use Protobuf::DescriptorPool;
use Protobuf::Internal qw(:all);
use MIME::Base64;

BEGIN {
    eval { require Google::Api::FieldBehavior };
    eval { require Google::Api::Resource };
    my $descriptor_b64 = <<'EOF';
CjRnb29nbGUvY2xvdWQvY29tbWVyY2Vwcm9kdWNlci92MWJldGEvc2t1X2dyb3VwLnByb3Rv
EiRnb29nbGUuY2xvdWQuY29tbWVyY2Vwcm9kdWNlci52MWJldGEaH2dvb2dsZS9hcGkvZmll
bGRfYmVoYXZpb3IucHJvdG8aGWdvb2dsZS9hcGkvcmVzb3VyY2UucHJvdG8ingIKCFNrdUdy
b3VwEhoKBG5hbWUYASABKAlCBuBBA+BBCFIEbmFtZRI/CgRza3VzGAIgAygJQivgQQP6QSUK
I2NvbW1lcmNlcHJvZHVjZXIuZ29vZ2xlYXBpcy5jb20vU2t1UgRza3VzEjEKEmNsb3VkX2Jp
bGxpbmdfc2t1cxgDIAMoCUID4EEDUhBjbG91ZEJpbGxpbmdTa3VzOoEB6kF+Cihjb21tZXJj
ZXByb2R1Y2VyLmdvb2dsZWFwaXMuY29tL1NrdUdyb3VwEj1wcm9qZWN0cy97cHJvamVjdH0v
bG9jYXRpb25zL3tsb2NhdGlvbn0vc2t1R3JvdXBzL3tza3VfZ3JvdXB9Kglza3VHcm91cHMy
CHNrdUdyb3VwQokCCihjb20uZ29vZ2xlLmNsb3VkLmNvbW1lcmNlcHJvZHVjZXIudjFiZXRh
Qg1Ta3VHcm91cFByb3RvUAFaVGNsb3VkLmdvb2dsZS5jb20vZ28vY29tbWVyY2Vwcm9kdWNl
ci9hcGl2MWJldGEvY29tbWVyY2Vwcm9kdWNlcnBiO2NvbW1lcmNlcHJvZHVjZXJwYqoCJEdv
b2dsZS5DbG91ZC5Db21tZXJjZVByb2R1Y2VyLlYxQmV0YcoCJEdvb2dsZVxDbG91ZFxDb21t
ZXJjZVByb2R1Y2VyXFYxYmV0YeoCJ0dvb2dsZTo6Q2xvdWQ6OkNvbW1lcmNlUHJvZHVjZXI6
OlYxYmV0YUrKDQoGEgQOAEABCrwECgEMEgMOABIysQQgQ29weXJpZ2h0IDIwMjYgR29vZ2xl
IExMQwoKIExpY2Vuc2VkIHVuZGVyIHRoZSBBcGFjaGUgTGljZW5zZSwgVmVyc2lvbiAyLjAg
KHRoZSAiTGljZW5zZSIpOwogeW91IG1heSBub3QgdXNlIHRoaXMgZmlsZSBleGNlcHQgaW4g
Y29tcGxpYW5jZSB3aXRoIHRoZSBMaWNlbnNlLgogWW91IG1heSBvYnRhaW4gYSBjb3B5IG9m
IHRoZSBMaWNlbnNlIGF0CgogICAgIGh0dHA6Ly93d3cuYXBhY2hlLm9yZy9saWNlbnNlcy9M
SUNFTlNFLTIuMAoKIFVubGVzcyByZXF1aXJlZCBieSBhcHBsaWNhYmxlIGxhdyBvciBhZ3Jl
ZWQgdG8gaW4gd3JpdGluZywgc29mdHdhcmUKIGRpc3RyaWJ1dGVkIHVuZGVyIHRoZSBMaWNl
bnNlIGlzIGRpc3RyaWJ1dGVkIG9uIGFuICJBUyBJUyIgQkFTSVMsCiBXSVRIT1VUIFdBUlJB
TlRJRVMgT1IgQ09ORElUSU9OUyBPRiBBTlkgS0lORCwgZWl0aGVyIGV4cHJlc3Mgb3IgaW1w
bGllZC4KIFNlZSB0aGUgTGljZW5zZSBmb3IgdGhlIHNwZWNpZmljIGxhbmd1YWdlIGdvdmVy
bmluZyBwZXJtaXNzaW9ucyBhbmQKIGxpbWl0YXRpb25zIHVuZGVyIHRoZSBMaWNlbnNlLgoK
CAoBAhIDEAAtCgkKAgMAEgMSACkKCQoCAwESAxMAIwoICgEIEgMVAEEKCQoCCCUSAxUAQQoI
CgEIEgMWAGsKCQoCCAsSAxYAawoICgEIEgMXACIKCQoCCAoSAxcAIgoICgEIEgMYAC4KCQoC
CAgSAxgALgoICgEIEgMZAEEKCQoCCAESAxkAQQoICgEIEgMaAEEKCQoCCCkSAxoAQQoICgEI
EgMbAEAKCQoCCC0SAxsAQAoyCgIEABIEHgBAARomIE1lc3NhZ2UgZGVzY3JpYmluZyBTa3VH
cm91cCByZXNvdXJjZQoKCgoDBAABEgMeCBAKCwoDBAAHEgQfAiQECg0KBQQAB50IEgQfAiQE
Cj4KBAQAAgASBCcCKgQaMCBPdXRwdXQgb25seS4gSWRlbnRpZmllci4gTmFtZSBvZiB0aGUg
U2t1R3JvdXAuCgoMCgUEAAIABRIDJwIICgwKBQQAAgABEgMnCQ0KDAoFBAACAAMSAycQEQoN
CgUEAAIACBIEJxIqAwoPCggEAAIACJwIABIDKAQtCg8KCAQAAgAInAgBEgMpBCwKlgEKBAQA
AgESBC8CNAQahwEgT3V0cHV0IG9ubHkuIFBhcnRuZXIgU0tVcyBpbmNsdWRlZCBpbiB0aGUg
U2t1R3JvdXAuCiBGb3JtYXQ6CiBgcHJvamVjdHMve3Byb2plY3R9L2xvY2F0aW9ucy97bG9j
YXRpb259L3NlcnZpY2VzL3tzZXJ2aWNlfS9za3VzL3tza3V9YAoKDAoFBAACAQQSAy8CCgoM
CgUEAAIBBRIDLwsRCgwKBQQAAgEBEgMvEhYKDAoFBAACAQMSAy8ZGgoNCgUEAAIBCBIELxs0
AwoPCggEAAIBCJwIABIDMAQtCg8KBwQAAgEInwgSBDEEMwUK/QIKBAQAAgISBD4CPzIa7gIg
T3V0cHV0IG9ubHkuIEdvb2dsZSBTS1VzIGluY2x1ZGVkIGluIHRoZSBTa3VHcm91cC4KCiBV
c2VkIGZvciBwYXJ0bmVyIHByb2R1Y3RzIHNvbGQgYnkgR29vZ2xlLCBzdWNoIGFzIFByZW1p
dW0gT3BlcmF0aW5nIFN5c3RlbQogSW1hZ2VzIHNvbGQgZm9yIHVzZSBpbiBDb21wdXRlIEVu
Z2luZS4gVGhpcyBpcyBub3QgY29tbW9uLgogU0tVcyBvZiB0aGlzIHR5cGUgYXJlIG5vdCBw
cmVzZW50IG9uIHRoaXMgQVBJIGFuZCBjYW4gaW5zdGVhZCBiZSBmb3VuZCBvbgogdGhlIENs
b3VkIEJpbGxpbmcgQVBJIG9yIGF0IGh0dHBzOi8vY2xvdWQuZ29vZ2xlLmNvbS9za3VzLgoK
IEZvcm1hdDogYHNlcnZpY2VzL3tzZXJ2aWNlfS9za3VzL3tza3V9YAoKDAoFBAACAgQSAz4C
CgoMCgUEAAICBRIDPgsRCgwKBQQAAgIBEgM+EiQKDAoFBAACAgMSAz4nKAoMCgUEAAICCBID
PwYxCg8KCAQAAgIInAgAEgM/BzBiBnByb3RvMw==
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Commerceproducer::V1beta::SkuGroup::SkuGroup ===
    # Fields for SkuGroup
    # Field: name Type: 9 ()
    # Field: skus Type: 9 ()
    # Field: cloud_billing_skus Type: 9 ()

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Commerceproducer::V1beta::SkuGroup - Compiled Protocol Buffers messages for google/cloud/commerceproducer/v1beta/sku_group.proto

=head1 SYNOPSIS

    use Google::Cloud::Commerceproducer::V1beta::SkuGroup;

    my $msg = Google::Cloud::Commerceproducer::V1beta::SkuGroup::SkuGroup->new({
        name => $name,
        skus => $skus,
        cloud_billing_skus => $cloud_billing_skus,
    });

    # Read or update a field
    my $val = $msg->name();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Commerceproducer::V1beta::SkuGroup::SkuGroup->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/commerceproducer/v1beta/sku_group.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Commerceproducer::V1beta::SkuGroup::SkuGroup

Message describing SkuGroup resource

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Output only. Identifier. Name of the SkuGroup.

=item * C<< $msg->skus() >> / C<< $msg->skus($value) >>

Type: C<String>

Output only. Partner SKUs included in the SkuGroup.
Format:
`projects/{project}/locations/{location}/services/{service}/skus/{sku}`

=item * C<< $msg->cloud_billing_skus() >> / C<< $msg->cloud_billing_skus($value) >>

Type: C<String>

Output only. Google SKUs included in the SkuGroup.

Used for partner products sold by Google, such as Premium Operating System
Images sold for use in Compute Engine. This is not common.
SKUs of this type are not present on this API and can instead be found on
the Cloud Billing API or at https://cloud.google.com/skus.

Format: `services/{service}/skus/{sku}`

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Commerceproducer::V1beta::SkuGroup::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
