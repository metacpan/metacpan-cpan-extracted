package Google::Cloud::Securitycenter::V2::ToxicCombination;

use strict;
use warnings;

our $VERSION = '0.14';

use Protobuf::Message;
use Protobuf::DescriptorPool;
use Protobuf::Internal qw(:all);
use MIME::Base64;

BEGIN {
    my $descriptor_b64 = <<'EOF';
CjZnb29nbGUvY2xvdWQvc2VjdXJpdHljZW50ZXIvdjIvdG94aWNfY29tYmluYXRpb24ucHJv
dG8SHmdvb2dsZS5jbG91ZC5zZWN1cml0eWNlbnRlci52MiJxChBUb3hpY0NvbWJpbmF0aW9u
EjIKFWF0dGFja19leHBvc3VyZV9zY29yZRgBIAEoAVITYXR0YWNrRXhwb3N1cmVTY29yZRIp
ChByZWxhdGVkX2ZpbmRpbmdzGAIgAygJUg9yZWxhdGVkRmluZGluZ3NC7wEKImNvbS5nb29n
bGUuY2xvdWQuc2VjdXJpdHljZW50ZXIudjJCFVRveGljQ29tYmluYXRpb25Qcm90b1ABWkpj
bG91ZC5nb29nbGUuY29tL2dvL3NlY3VyaXR5Y2VudGVyL2FwaXYyL3NlY3VyaXR5Y2VudGVy
cGI7c2VjdXJpdHljZW50ZXJwYqoCHkdvb2dsZS5DbG91ZC5TZWN1cml0eUNlbnRlci5WMsoC
Hkdvb2dsZVxDbG91ZFxTZWN1cml0eUNlbnRlclxWMuoCIUdvb2dsZTo6Q2xvdWQ6OlNlY3Vy
aXR5Q2VudGVyOjpWMkqBDAoGEgQOACkBCrwECgEMEgMOABIysQQgQ29weXJpZ2h0IDIwMjUg
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
CuoBCgIEABIEHgApARrdASBDb250YWlucyBkZXRhaWxzIGFib3V0IGEgZ3JvdXAgb2Ygc2Vj
dXJpdHkgaXNzdWVzIHRoYXQsIHdoZW4gdGhlIGlzc3Vlcwogb2NjdXIgdG9nZXRoZXIsIHJl
cHJlc2VudCBhIGdyZWF0ZXIgcmlzayB0aGFuIHdoZW4gdGhlIGlzc3VlcyBvY2N1cgogaW5k
ZXBlbmRlbnRseS4gQSBncm91cCBvZiBzdWNoIGlzc3VlcyBpcyByZWZlcnJlZCB0byBhcyBh
IHRveGljCiBjb21iaW5hdGlvbi4KCgoKAwQAARIDHggYCqYCCgQEAAIAEgMkAiMamAIgVGhl
CiBbQXR0YWNrIGV4cG9zdXJlCiBzY29yZV0oaHR0cHM6Ly9jbG91ZC5nb29nbGUuY29tL3Nl
Y3VyaXR5LWNvbW1hbmQtY2VudGVyL2RvY3MvYXR0YWNrLWV4cG9zdXJlLWxlYXJuI2F0dGFj
a19leHBvc3VyZV9zY29yZXMpCiBvZiB0aGlzIHRveGljIGNvbWJpbmF0aW9uLiBUaGUgc2Nv
cmUgaXMgYSBtZWFzdXJlIG9mIGhvdyBtdWNoIHRoaXMgdG94aWMKIGNvbWJpbmF0aW9uIGV4
cG9zZXMgb25lIG9yIG1vcmUgaGlnaC12YWx1ZSByZXNvdXJjZXMgdG8gcG90ZW50aWFsIGF0
dGFjay4KCgwKBQQAAgAFEgMkAggKDAoFBAACAAESAyQJHgoMCgUEAAIAAxIDJCEiCpYBCgQE
AAIBEgMoAicaiAEgTGlzdCBvZiByZXNvdXJjZSBuYW1lcyBvZiBmaW5kaW5ncyBhc3NvY2lh
dGVkIHdpdGggdGhpcyB0b3hpYyBjb21iaW5hdGlvbi4KIEZvciBleGFtcGxlLCBgb3JnYW5p
emF0aW9ucy8xMjMvc291cmNlcy80NTYvZmluZGluZ3MvNzg5YC4KCgwKBQQAAgEEEgMoAgoK
DAoFBAACAQUSAygLEQoMCgUEAAIBARIDKBIiCgwKBQQAAgEDEgMoJSZiBnByb3RvMw==
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Securitycenter::V2::ToxicCombination::ToxicCombination ===
    # Fields for ToxicCombination
    # Field: attack_exposure_score Type: 1 ()
    # Field: related_findings Type: 9 ()

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Securitycenter::V2::ToxicCombination - Compiled Protocol Buffers messages for google/cloud/securitycenter/v2/toxic_combination.proto

=head1 SYNOPSIS

    use Google::Cloud::Securitycenter::V2::ToxicCombination;

    my $msg = Google::Cloud::Securitycenter::V2::ToxicCombination::ToxicCombination->new({
        attack_exposure_score => $attack_exposure_score,
        related_findings => $related_findings,
    });

    # Read or update a field
    my $val = $msg->attack_exposure_score();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Securitycenter::V2::ToxicCombination::ToxicCombination->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/securitycenter/v2/toxic_combination.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Securitycenter::V2::ToxicCombination::ToxicCombination

Contains details about a group of security issues that, when the issues
occur together, represent a greater risk than when the issues occur
independently. A group of such issues is referred to as a toxic
combination.

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

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Securitycenter::V2::ToxicCombination::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
