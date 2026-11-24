package Grafeas::V1::Risk;

use strict;
use warnings;

our $VERSION = '0.14';

use Protobuf::Message;
use Protobuf::DescriptorPool;
use Protobuf::Internal qw(:all);
use MIME::Base64;

BEGIN {
    my $descriptor_b64 = <<'EOF';
ChVncmFmZWFzL3YxL3Jpc2sucHJvdG8SCmdyYWZlYXMudjEikAEKBFJpc2sSSAoIY2lzYV9r
ZXYYASABKAsyLS5ncmFmZWFzLnYxLkNJU0FLbm93bkV4cGxvaXRlZFZ1bG5lcmFiaWxpdGll
c1IHY2lzYUtldhI+CgRlcHNzGAIgASgLMiouZ3JhZmVhcy52MS5FeHBsb2l0UHJlZGljdGlv
blNjb3JpbmdTeXN0ZW1SBGVwc3MiZgohQ0lTQUtub3duRXhwbG9pdGVkVnVsbmVyYWJpbGl0
aWVzEkEKHWtub3duX3JhbnNvbXdhcmVfY2FtcGFpZ25fdXNlGAEgASgJUhprbm93blJhbnNv
bXdhcmVDYW1wYWlnblVzZSJWCh5FeHBsb2l0UHJlZGljdGlvblNjb3JpbmdTeXN0ZW0SHgoK
cGVyY2VudGlsZRgBIAEoAVIKcGVyY2VudGlsZRIUCgVzY29yZRgCIAEoAVIFc2NvcmVCUQoN
aW8uZ3JhZmVhcy52MVABWjhnb29nbGUuZ29sYW5nLm9yZy9nZW5wcm90by9nb29nbGVhcGlz
L2dyYWZlYXMvdjE7Z3JhZmVhc6ICA0dSQUrbDAoGEgQOAC0BCtoECgEMEgMOABIyzwQgQ29w
eXJpZ2h0IDIwMjUgVGhlIEdyYWZlYXMgQXV0aG9ycy4gQWxsIHJpZ2h0cyByZXNlcnZlZC4K
CiBMaWNlbnNlZCB1bmRlciB0aGUgQXBhY2hlIExpY2Vuc2UsIFZlcnNpb24gMi4wICh0aGUg
IkxpY2Vuc2UiKTsKIHlvdSBtYXkgbm90IHVzZSB0aGlzIGZpbGUgZXhjZXB0IGluIGNvbXBs
aWFuY2Ugd2l0aCB0aGUgTGljZW5zZS4KIFlvdSBtYXkgb2J0YWluIGEgY29weSBvZiB0aGUg
TGljZW5zZSBhdAoKICAgIGh0dHA6Ly93d3cuYXBhY2hlLm9yZy9saWNlbnNlcy9MSUNFTlNF
LTIuMAoKIFVubGVzcyByZXF1aXJlZCBieSBhcHBsaWNhYmxlIGxhdyBvciBhZ3JlZWQgdG8g
aW4gd3JpdGluZywgc29mdHdhcmUKIGRpc3RyaWJ1dGVkIHVuZGVyIHRoZSBMaWNlbnNlIGlz
IGRpc3RyaWJ1dGVkIG9uIGFuICJBUyBJUyIgQkFTSVMsCiBXSVRIT1VUIFdBUlJBTlRJRVMg
T1IgQ09ORElUSU9OUyBPRiBBTlkgS0lORCwgZWl0aGVyIGV4cHJlc3Mgb3IgaW1wbGllZC4K
IFNlZSB0aGUgTGljZW5zZSBmb3IgdGhlIHNwZWNpZmljIGxhbmd1YWdlIGdvdmVybmluZyBw
ZXJtaXNzaW9ucyBhbmQKIGxpbWl0YXRpb25zIHVuZGVyIHRoZSBMaWNlbnNlLgoKCAoBAhID
EAATCggKAQgSAxIATwoJCgIICxIDEgBPCggKAQgSAxMAIgoJCgIIChIDEwAiCggKAQgSAxQA
JgoJCgIIARIDFAAmCggKAQgSAxUAIQoJCgIIJBIDFQAhCgoKAgQAEgQXAB4BCgoKAwQAARID
FwgMCnAKBAQAAgASAxoCMRpjIENJU0EgbWFpbnRhaW5zIHRoZSBhdXRob3JpdGF0aXZlIHNv
dXJjZSBvZiB2dWxuZXJhYmlsaXRpZXMgdGhhdCBoYXZlIGJlZW4KIGV4cGxvaXRlZCBpbiB0
aGUgd2lsZC4KCgwKBQQAAgAGEgMaAiMKDAoFBAACAAESAxokLAoMCgUEAAIAAxIDGi8wCqEB
CgQEAAIBEgMdAioakwEgVGhlIEV4cGxvaXQgUHJlZGljdGlvbiBTY29yaW5nIFN5c3RlbSAo
RVBTUykgZXN0aW1hdGVzIHRoZSBsaWtlbGlob29kCiAocHJvYmFiaWxpdHkpIHRoYXQgYSBz
b2Z0d2FyZSB2dWxuZXJhYmlsaXR5IHdpbGwgYmUgZXhwbG9pdGVkIGluIHRoZSB3aWxkLgoK
DAoFBAACAQYSAx0CIAoMCgUEAAIBARIDHSElCgwKBQQAAgEDEgMdKCkKCgoCBAESBCAAJAEK
CgoDBAEBEgMgCCkKawoEBAECABIDIwIrGl4gV2hldGhlciB0aGUgdnVsbmVyYWJpbGl0eSBp
cyBrbm93biB0byBoYXZlIGJlZW4gbGV2ZXJhZ2VkIGFzIHBhcnQgb2YgYQogcmFuc29td2Fy
ZSBjYW1wYWlnbi4KCgwKBQQBAgAFEgMjAggKDAoFBAECAAESAyMJJgoMCgUEAQIAAxIDIykq
CgoKAgQCEgQmAC0BCgoKAwQCARIDJggmCoUBCgQEAgIAEgMpAhgaeCBUaGUgcGVyY2VudGls
ZSBvZiB0aGUgY3VycmVudCBzY29yZSwgdGhlIHByb3BvcnRpb24gb2YgYWxsIHNjb3JlZAog
dnVsbmVyYWJpbGl0aWVzIHdpdGggdGhlIHNhbWUgb3IgYSBsb3dlciBFUFNTIHNjb3JlCgoM
CgUEAgIABRIDKQIICgwKBQQCAgABEgMpCRMKDAoFBAICAAMSAykWFwpxCgQEAgIBEgMsAhMa
ZCBUaGUgRVBTUyBzY29yZSByZXByZXNlbnRpbmcgdGhlIHByb2JhYmlsaXR5IFswLTFdIG9m
IGV4cGxvaXRhdGlvbiBpbiB0aGUKIHdpbGQgaW4gdGhlIG5leHQgMzAgZGF5cwoKDAoFBAIC
AQUSAywCCAoMCgUEAgIBARIDLAkOCgwKBQQCAgEDEgMsERJiBnByb3RvMw==
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Grafeas::V1::Risk::Risk ===
    # Fields for Risk
    # Field: cisa_kev Type: 11 (.grafeas.v1.CISAKnownExploitedVulnerabilities)
    # Field: epss Type: 11 (.grafeas.v1.ExploitPredictionScoringSystem)

# === Message: Grafeas::V1::Risk::CISAKnownExploitedVulnerabilities ===
    # Fields for CISAKnownExploitedVulnerabilities
    # Field: known_ransomware_campaign_use Type: 9 ()

# === Message: Grafeas::V1::Risk::ExploitPredictionScoringSystem ===
    # Fields for ExploitPredictionScoringSystem
    # Field: percentile Type: 1 ()
    # Field: score Type: 1 ()

1;

__END__

=encoding UTF-8

=head1 NAME

Grafeas::V1::Risk - Compiled Protocol Buffers messages for grafeas/v1/risk.proto

=head1 SYNOPSIS

    use Grafeas::V1::Risk;

    my $msg = Grafeas::V1::Risk::Risk->new({
        cisa_kev => $cisa_kev,
        epss => $epss,
    });

    # Read or update a field
    my $val = $msg->cisa_kev();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Grafeas::V1::Risk::Risk->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<grafeas/v1/risk.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Grafeas::V1::Risk::Risk

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->cisa_kev() >> / C<< $msg->cisa_kev($value) >>

Type: C<Message> (L<Grafeas::V1::Risk::CISAKnownExploitedVulnerabilities>)

CISA maintains the authoritative source of vulnerabilities that have been
exploited in the wild.

=item * C<< $msg->epss() >> / C<< $msg->epss($value) >>

Type: C<Message> (L<Grafeas::V1::Risk::ExploitPredictionScoringSystem>)

The Exploit Prediction Scoring System (EPSS) estimates the likelihood
(probability) that a software vulnerability will be exploited in the wild.

=back

=head2 Grafeas::V1::Risk::CISAKnownExploitedVulnerabilities

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->known_ransomware_campaign_use() >> / C<< $msg->known_ransomware_campaign_use($value) >>

Type: C<String>

Whether the vulnerability is known to have been leveraged as part of a
ransomware campaign.

=back

=head2 Grafeas::V1::Risk::ExploitPredictionScoringSystem

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->percentile() >> / C<< $msg->percentile($value) >>

Type: C<Double>

The percentile of the current score, the proportion of all scored
vulnerabilities with the same or a lower EPSS score

=item * C<< $msg->score() >> / C<< $msg->score($value) >>

Type: C<Double>

The EPSS score representing the probability [0-1] of exploitation in the
wild in the next 30 days

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Grafeas::V1::Risk::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
