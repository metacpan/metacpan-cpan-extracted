package Google::Cloud::Securitycenter::V1::ToxicCombination;

use strict;
use warnings;

our $VERSION = '0.14';

use Protobuf::Message;
use Protobuf::DescriptorPool;
use Protobuf::Internal qw(:all);
use MIME::Base64;

BEGIN {
    my $descriptor_b64 = <<'EOF';
CjZnb29nbGUvY2xvdWQvc2VjdXJpdHljZW50ZXIvdjEvdG94aWNfY29tYmluYXRpb24ucHJv
dG8SHmdvb2dsZS5jbG91ZC5zZWN1cml0eWNlbnRlci52MSJxChBUb3hpY0NvbWJpbmF0aW9u
EjIKFWF0dGFja19leHBvc3VyZV9zY29yZRgBIAEoAVITYXR0YWNrRXhwb3N1cmVTY29yZRIp
ChByZWxhdGVkX2ZpbmRpbmdzGAIgAygJUg9yZWxhdGVkRmluZGluZ3NC7wEKImNvbS5nb29n
bGUuY2xvdWQuc2VjdXJpdHljZW50ZXIudjFCFVRveGljQ29tYmluYXRpb25Qcm90b1ABWkpj
bG91ZC5nb29nbGUuY29tL2dvL3NlY3VyaXR5Y2VudGVyL2FwaXYxL3NlY3VyaXR5Y2VudGVy
cGI7c2VjdXJpdHljZW50ZXJwYqoCHkdvb2dsZS5DbG91ZC5TZWN1cml0eUNlbnRlci5WMcoC
Hkdvb2dsZVxDbG91ZFxTZWN1cml0eUNlbnRlclxWMeoCIUdvb2dsZTo6Q2xvdWQ6OlNlY3Vy
aXR5Q2VudGVyOjpWMUqADAoGEgQOACgBCrwECgEMEgMOABIysQQgQ29weXJpZ2h0IDIwMjUg
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
bnNlLgoKCAoBAhIDEAAnCggKAQgSAxIAOwoJCgIIJRIDEgA7CggKAQgSAxMAYQoJCgIICxID
EwBhCggKAQgSAxQAIgoJCgIIChIDFAAiCggKAQgSAxUANgoJCgIICBIDFQA2CggKAQgSAxYA
OwoJCgIIARIDFgA7CggKAQgSAxcAOwoJCgIIKRIDFwA7CggKAQgSAxgAOgoJCgIILRIDGAA6
CukBCgIEABIEHQAoARrcASBDb250YWlucyBkZXRhaWxzIGFib3V0IGEgZ3JvdXAgb2Ygc2Vj
dXJpdHkgaXNzdWVzIHRoYXQsIHdoZW4gdGhlIGlzc3Vlcwogb2NjdXIgdG9nZXRoZXIsIHJl
cHJlc2VudCBhIGdyZWF0ZXIgcmlzayB0aGFuIHdoZW4gdGhlIGlzc3VlcyBvY2N1cgogaW5k
ZXBlbmRlbnRseS4gQSBncm91cCBvZiBzdWNoIGlzc3VlcyBpcyByZWZlcnJlZCB0byBhcyBh
IHRveGljIGNvbWJpbmF0aW9uLgoKCgoDBAABEgMdCBgKpgIKBAQAAgASAyMCIxqYAiBUaGUK
IFtBdHRhY2sgZXhwb3N1cmUKIHNjb3JlXShodHRwczovL2Nsb3VkLmdvb2dsZS5jb20vc2Vj
dXJpdHktY29tbWFuZC1jZW50ZXIvZG9jcy9hdHRhY2stZXhwb3N1cmUtbGVhcm4jYXR0YWNr
X2V4cG9zdXJlX3Njb3JlcykKIG9mIHRoaXMgdG94aWMgY29tYmluYXRpb24uIFRoZSBzY29y
ZSBpcyBhIG1lYXN1cmUgb2YgaG93IG11Y2ggdGhpcyB0b3hpYwogY29tYmluYXRpb24gZXhw
b3NlcyBvbmUgb3IgbW9yZSBoaWdoLXZhbHVlIHJlc291cmNlcyB0byBwb3RlbnRpYWwgYXR0
YWNrLgoKDAoFBAACAAUSAyMCCAoMCgUEAAIAARIDIwkeCgwKBQQAAgADEgMjISIKlgEKBAQA
AgESAycCJxqIASBMaXN0IG9mIHJlc291cmNlIG5hbWVzIG9mIGZpbmRpbmdzIGFzc29jaWF0
ZWQgd2l0aCB0aGlzIHRveGljIGNvbWJpbmF0aW9uLgogRm9yIGV4YW1wbGUsIGBvcmdhbml6
YXRpb25zLzEyMy9zb3VyY2VzLzQ1Ni9maW5kaW5ncy83ODlgLgoKDAoFBAACAQQSAycCCgoM
CgUEAAIBBRIDJwsRCgwKBQQAAgEBEgMnEiIKDAoFBAACAQMSAyclJmIGcHJvdG8z
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Securitycenter::V1::ToxicCombination::ToxicCombination ===
    # Fields for ToxicCombination
    # Field: attack_exposure_score Type: 1 ()
    # Field: related_findings Type: 9 ()

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Securitycenter::V1::ToxicCombination - Compiled Protocol Buffers messages for google/cloud/securitycenter/v1/toxic_combination.proto

=head1 SYNOPSIS

    use Google::Cloud::Securitycenter::V1::ToxicCombination;

    my $msg = Google::Cloud::Securitycenter::V1::ToxicCombination::ToxicCombination->new({
        attack_exposure_score => $attack_exposure_score,
        related_findings => $related_findings,
    });

    # Read or update a field
    my $val = $msg->attack_exposure_score();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Securitycenter::V1::ToxicCombination::ToxicCombination->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/securitycenter/v1/toxic_combination.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Securitycenter::V1::ToxicCombination::ToxicCombination

Contains details about a group of security issues that, when the issues
occur together, represent a greater risk than when the issues occur
independently. A group of such issues is referred to as a toxic combination.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->attack_exposure_score() >> / C<< $msg->attack_exposure_score($value) >>

Type: C<Double>

The
[Attack exposure
score](https://cloud.google.com/security-command-center/docs/attack-exposure-learn#attack_exposure_scores)
of this toxic combination. The score is a measure of how much this toxic
combination exposes one or more high-value resources to potential attack.

=item * C<< $msg->related_findings() >> / C<< $msg->related_findings($value) >>

Type: C<String>

List of resource names of findings associated with this toxic combination.
For example, `organizations/123/sources/456/findings/789`.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Securitycenter::V1::ToxicCombination::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
