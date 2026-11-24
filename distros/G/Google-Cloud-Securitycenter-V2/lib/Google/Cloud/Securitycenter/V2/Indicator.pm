package Google::Cloud::Securitycenter::V2::Indicator;

use strict;
use warnings;

our $VERSION = '0.14';

use Protobuf::Message;
use Protobuf::DescriptorPool;
use Protobuf::Internal qw(:all);
use MIME::Base64;

BEGIN {
    my $descriptor_b64 = <<'EOF';
Ci5nb29nbGUvY2xvdWQvc2VjdXJpdHljZW50ZXIvdjIvaW5kaWNhdG9yLnByb3RvEh5nb29n
bGUuY2xvdWQuc2VjdXJpdHljZW50ZXIudjIi+gcKCUluZGljYXRvchIhCgxpcF9hZGRyZXNz
ZXMYASADKAlSC2lwQWRkcmVzc2VzEhgKB2RvbWFpbnMYAiADKAlSB2RvbWFpbnMSWgoKc2ln
bmF0dXJlcxgDIAMoCzI6Lmdvb2dsZS5jbG91ZC5zZWN1cml0eWNlbnRlci52Mi5JbmRpY2F0
b3IuUHJvY2Vzc1NpZ25hdHVyZVIKc2lnbmF0dXJlcxISCgR1cmlzGAQgAygJUgR1cmlzGr8G
ChBQcm9jZXNzU2lnbmF0dXJlEoQBChVtZW1vcnlfaGFzaF9zaWduYXR1cmUYBiABKAsyTi5n
b29nbGUuY2xvdWQuc2VjdXJpdHljZW50ZXIudjIuSW5kaWNhdG9yLlByb2Nlc3NTaWduYXR1
cmUuTWVtb3J5SGFzaFNpZ25hdHVyZUgAUhNtZW1vcnlIYXNoU2lnbmF0dXJlEn4KE3lhcmFf
cnVsZV9zaWduYXR1cmUYByABKAsyTC5nb29nbGUuY2xvdWQuc2VjdXJpdHljZW50ZXIudjIu
SW5kaWNhdG9yLlByb2Nlc3NTaWduYXR1cmUuWWFyYVJ1bGVTaWduYXR1cmVIAFIReWFyYVJ1
bGVTaWduYXR1cmUSbwoOc2lnbmF0dXJlX3R5cGUYCCABKA4ySC5nb29nbGUuY2xvdWQuc2Vj
dXJpdHljZW50ZXIudjIuSW5kaWNhdG9yLlByb2Nlc3NTaWduYXR1cmUuU2lnbmF0dXJlVHlw
ZVINc2lnbmF0dXJlVHlwZRqNAgoTTWVtb3J5SGFzaFNpZ25hdHVyZRIjCg1iaW5hcnlfZmFt
aWx5GAEgASgJUgxiaW5hcnlGYW1pbHkSeAoKZGV0ZWN0aW9ucxgEIAMoCzJYLmdvb2dsZS5j
bG91ZC5zZWN1cml0eWNlbnRlci52Mi5JbmRpY2F0b3IuUHJvY2Vzc1NpZ25hdHVyZS5NZW1v
cnlIYXNoU2lnbmF0dXJlLkRldGVjdGlvblIKZGV0ZWN0aW9ucxpXCglEZXRlY3Rpb24SFgoG
YmluYXJ5GAIgASgJUgZiaW5hcnkSMgoVcGVyY2VudF9wYWdlc19tYXRjaGVkGAMgASgBUhNw
ZXJjZW50UGFnZXNNYXRjaGVkGjAKEVlhcmFSdWxlU2lnbmF0dXJlEhsKCXlhcmFfcnVsZRgF
IAEoCVIIeWFyYVJ1bGUiZAoNU2lnbmF0dXJlVHlwZRIeChpTSUdOQVRVUkVfVFlQRV9VTlNQ
RUNJRklFRBAAEhoKFlNJR05BVFVSRV9UWVBFX1BST0NFU1MQARIXChNTSUdOQVRVUkVfVFlQ
RV9GSUxFEAJCCwoJc2lnbmF0dXJlQugBCiJjb20uZ29vZ2xlLmNsb3VkLnNlY3VyaXR5Y2Vu
dGVyLnYyQg5JbmRpY2F0b3JQcm90b1ABWkpjbG91ZC5nb29nbGUuY29tL2dvL3NlY3VyaXR5
Y2VudGVyL2FwaXYyL3NlY3VyaXR5Y2VudGVycGI7c2VjdXJpdHljZW50ZXJwYqoCHkdvb2ds
ZS5DbG91ZC5TZWN1cml0eUNlbnRlci5WMsoCHkdvb2dsZVxDbG91ZFxTZWN1cml0eUNlbnRl
clxWMuoCIUdvb2dsZTo6Q2xvdWQ6OlNlY3VyaXR5Q2VudGVyOjpWMkr0GgoGEgQOAGIBCrwE
CgEMEgMOABIysQQgQ29weXJpZ2h0IDIwMjUgR29vZ2xlIExMQwoKIExpY2Vuc2VkIHVuZGVy
IHRoZSBBcGFjaGUgTGljZW5zZSwgVmVyc2lvbiAyLjAgKHRoZSAiTGljZW5zZSIpOwogeW91
IG1heSBub3QgdXNlIHRoaXMgZmlsZSBleGNlcHQgaW4gY29tcGxpYW5jZSB3aXRoIHRoZSBM
aWNlbnNlLgogWW91IG1heSBvYnRhaW4gYSBjb3B5IG9mIHRoZSBMaWNlbnNlIGF0CgogICAg
IGh0dHA6Ly93d3cuYXBhY2hlLm9yZy9saWNlbnNlcy9MSUNFTlNFLTIuMAoKIFVubGVzcyBy
ZXF1aXJlZCBieSBhcHBsaWNhYmxlIGxhdyBvciBhZ3JlZWQgdG8gaW4gd3JpdGluZywgc29m
dHdhcmUKIGRpc3RyaWJ1dGVkIHVuZGVyIHRoZSBMaWNlbnNlIGlzIGRpc3RyaWJ1dGVkIG9u
IGFuICJBUyBJUyIgQkFTSVMsCiBXSVRIT1VUIFdBUlJBTlRJRVMgT1IgQ09ORElUSU9OUyBP
RiBBTlkgS0lORCwgZWl0aGVyIGV4cHJlc3Mgb3IgaW1wbGllZC4KIFNlZSB0aGUgTGljZW5z
ZSBmb3IgdGhlIHNwZWNpZmljIGxhbmd1YWdlIGdvdmVybmluZyBwZXJtaXNzaW9ucyBhbmQK
IGxpbWl0YXRpb25zIHVuZGVyIHRoZSBMaWNlbnNlLgoKCAoBAhIDEAAnCggKAQgSAxIAOwoJ
CgIIJRIDEgA7CggKAQgSAxMAYQoJCgIICxIDEwBhCggKAQgSAxQAIgoJCgIIChIDFAAiCggK
AQgSAxUALwoJCgIICBIDFQAvCggKAQgSAxYAOwoJCgIIARIDFgA7CggKAQgSAxcAOwoJCgII
KRIDFwA7CggKAQgSAxgAOgoJCgIILRIDGAA6CtwCCgIEABIEHwBiARrPAiBSZXByZXNlbnRz
IHdoYXQncyBjb21tb25seSBrbm93biBhcyBhbiBfaW5kaWNhdG9yIG9mIGNvbXByb21pc2Vf
IChJb0MpIGluCiBjb21wdXRlciBmb3JlbnNpY3MuIFRoaXMgaXMgYW4gYXJ0aWZhY3Qgb2Jz
ZXJ2ZWQgb24gYSBuZXR3b3JrIG9yIGluIGFuCiBvcGVyYXRpbmcgc3lzdGVtIHRoYXQsIHdp
dGggaGlnaCBjb25maWRlbmNlLCBpbmRpY2F0ZXMgYSBjb21wdXRlciBpbnRydXNpb24uCiBG
b3IgbW9yZSBpbmZvcm1hdGlvbiwgc2VlIFtJbmRpY2F0b3Igb2YKIGNvbXByb21pc2VdKGh0
dHBzOi8vZW4ud2lraXBlZGlhLm9yZy93aWtpL0luZGljYXRvcl9vZl9jb21wcm9taXNlKS4K
CgoKAwQAARIDHwgRCj4KBAQAAwASBCECVAMaMCBJbmRpY2F0ZXMgd2hhdCBzaWduYXR1cmUg
bWF0Y2hlZCB0aGlzIHByb2Nlc3MuCgoMCgUEAAMAARIDIQoaCkIKBgQAAwADABIEIwQ1BRoy
IEEgc2lnbmF0dXJlIGNvcnJlc3BvbmRpbmcgdG8gbWVtb3J5IHBhZ2UgaGFzaGVzLgoKDgoH
BAADAAMAARIDIwwfClIKCAQAAwADAAMAEgQlBi0HGkAgTWVtb3J5IGhhc2ggZGV0ZWN0aW9u
IGNvbnRyaWJ1dGluZyB0byB0aGUgYmluYXJ5IGZhbWlseSBtYXRjaC4KChAKCQQAAwADAAMA
ARIDJQ4XCmEKCgQAAwADAAMAAgASAygIGhpOIFRoZSBuYW1lIG9mIHRoZSBiaW5hcnkgYXNz
b2NpYXRlZCB3aXRoIHRoZSBtZW1vcnkgaGFzaAogc2lnbmF0dXJlIGRldGVjdGlvbi4KChIK
CwQAAwADAAMAAgAFEgMoCA4KEgoLBAADAAMAAwACAAESAygPFQoSCgsEAAMAAwADAAIAAxID
KBgZCl4KCgQAAwADAAMAAgESAywIKRpLIFRoZSBwZXJjZW50YWdlIG9mIG1lbW9yeSBwYWdl
IGhhc2hlcyBpbiB0aGUgc2lnbmF0dXJlCiB0aGF0IHdlcmUgbWF0Y2hlZC4KChIKCwQAAwAD
AAMAAgEFEgMsCA4KEgoLBAADAAMAAwACAQESAywPJAoSCgsEAAMAAwADAAIBAxIDLCcoCiUK
CAQAAwADAAIAEgMwBh8aFCBUaGUgYmluYXJ5IGZhbWlseS4KChAKCQQAAwADAAIABRIDMAYM
ChAKCQQAAwADAAIAARIDMA0aChAKCQQAAwADAAIAAxIDMB0eCl8KCAQAAwADAAIBEgM0Biga
TiBUaGUgbGlzdCBvZiBtZW1vcnkgaGFzaCBkZXRlY3Rpb25zIGNvbnRyaWJ1dGluZyB0byB0
aGUgYmluYXJ5IGZhbWlseQogbWF0Y2guCgoQCgkEAAMAAwACAQQSAzQGDgoQCgkEAAMAAwAC
AQYSAzQPGAoQCgkEAAMAAwACAQESAzQZIwoQCgkEAAMAAwACAQMSAzQmJwo7CgYEAAMAAwES
BDgEOwUaKyBBIHNpZ25hdHVyZSBjb3JyZXNwb25kaW5nIHRvIGEgWUFSQSBydWxlLgoKDgoH
BAADAAMBARIDOAwdCi0KCAQAAwADAQIAEgM6BhsaHCBUaGUgbmFtZSBvZiB0aGUgWUFSQSBy
dWxlLgoKEAoJBAADAAMBAgAFEgM6BgwKEAoJBAADAAMBAgABEgM6DRYKEAoJBAADAAMBAgAD
EgM6GRoKTAoGBAADAAQAEgQ+BEcFGjwgUG9zc2libGUgcmVzb3VyY2UgdHlwZXMgdG8gYmUg
YXNzb2NpYXRlZCB3aXRoIGEgc2lnbmF0dXJlLgoKDgoHBAADAAQAARIDPgkWCi4KCAQAAwAE
AAIAEgNABiUaHSBUaGUgZGVmYXVsdCBzaWduYXR1cmUgdHlwZS4KChAKCQQAAwAEAAIAARID
QAYgChAKCQQAAwAEAAIAAhIDQCMkCjwKCAQAAwAEAAIBEgNDBiEaKyBVc2VkIGZvciBzaWdu
YXR1cmVzIGNvbmNlcm5pbmcgcHJvY2Vzc2VzLgoKEAoJBAADAAQAAgEBEgNDBhwKEAoJBAAD
AAQAAgECEgNDHyAKOAoIBAADAAQAAgISA0YGHhonIFVzZWQgZm9yIHNpZ25hdHVyZXMgY29u
Y2VybmluZyBkaXNrcy4KChAKCQQAAwAEAAICARIDRgYZChAKCQQAAwAEAAICAhIDRhwdCiAK
BgQAAwAIABIESgRQBRoQIFRoZSBzaWduYXR1cmUuCgoOCgcEAAMACAABEgNKChMKRwoGBAAD
AAIAEgNMBjQaOCBTaWduYXR1cmUgaW5kaWNhdGluZyB0aGF0IGEgYmluYXJ5IGZhbWlseSB3
YXMgbWF0Y2hlZC4KCg4KBwQAAwACAAYSA0wGGQoOCgcEAAMAAgABEgNMGi8KDgoHBAADAAIA
AxIDTDIzCkMKBgQAAwACARIDTwYwGjQgU2lnbmF0dXJlIGluZGljYXRpbmcgdGhhdCBhIFlB
UkEgcnVsZSB3YXMgbWF0Y2hlZC4KCg4KBwQAAwACAQYSA08GFwoOCgcEAAMAAgEBEgNPGCsK
DgoHBAADAAIBAxIDTy4vCk4KBgQAAwACAhIDUwQlGj8gRGVzY3JpYmVzIHRoZSB0eXBlIG9m
IHJlc291cmNlIGFzc29jaWF0ZWQgd2l0aCB0aGUgc2lnbmF0dXJlLgoKDgoHBAADAAICBhID
UwQRCg4KBwQAAwACAgESA1MSIAoOCgcEAAMAAgIDEgNTIyQKTQoEBAACABIDVwIjGkAgVGhl
IGxpc3Qgb2YgSVAgYWRkcmVzc2VzIHRoYXQgYXJlIGFzc29jaWF0ZWQgd2l0aCB0aGUgZmlu
ZGluZy4KCgwKBQQAAgAEEgNXAgoKDAoFBAACAAUSA1cLEQoMCgUEAAIAARIDVxIeCgwKBQQA
AgADEgNXISIKOQoEBAACARIDWgIeGiwgTGlzdCBvZiBkb21haW5zIGFzc29jaWF0ZWQgdG8g
dGhlIEZpbmRpbmcuCgoMCgUEAAIBBBIDWgIKCgwKBQQAAgEFEgNaCxEKDAoFBAACAQESA1oS
GQoMCgUEAAIBAxIDWhwdCm8KBAQAAgISA14CKxpiIFRoZSBsaXN0IG9mIG1hdGNoZWQgc2ln
bmF0dXJlcyBpbmRpY2F0aW5nIHRoYXQgdGhlIGdpdmVuCiBwcm9jZXNzIGlzIHByZXNlbnQg
aW4gdGhlIGVudmlyb25tZW50LgoKDAoFBAACAgQSA14CCgoMCgUEAAICBhIDXgsbCgwKBQQA
AgIBEgNeHCYKDAoFBAACAgMSA14pKgo7CgQEAAIDEgNhAhsaLiBUaGUgbGlzdCBvZiBVUklz
IGFzc29jaWF0ZWQgdG8gdGhlIEZpbmRpbmdzLgoKDAoFBAACAwQSA2ECCgoMCgUEAAIDBRID
YQsRCgwKBQQAAgMBEgNhEhYKDAoFBAACAwMSA2EZGmIGcHJvdG8z
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Securitycenter::V2::Indicator::Indicator ===
    # Fields for Indicator
    # Field: ip_addresses Type: 9 ()
    # Field: domains Type: 9 ()
    # Field: signatures Type: 11 (.google.cloud.securitycenter.v2.Indicator.ProcessSignature)
    # Field: uris Type: 9 ()

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Securitycenter::V2::Indicator - Compiled Protocol Buffers messages for google/cloud/securitycenter/v2/indicator.proto

=head1 SYNOPSIS

    use Google::Cloud::Securitycenter::V2::Indicator;

    my $msg = Google::Cloud::Securitycenter::V2::Indicator::Indicator->new({
        ip_addresses => $ip_addresses,
        domains => $domains,
        signatures => $signatures,
        uris => $uris,
    });

    # Read or update a field
    my $val = $msg->ip_addresses();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Securitycenter::V2::Indicator::Indicator->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/securitycenter/v2/indicator.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Securitycenter::V2::Indicator::Indicator

Represents what's commonly known as an _indicator of compromise_ (IoC) in
computer forensics. This is an artifact observed on a network or in an
operating system that, with high confidence, indicates a computer intrusion.
For more information, see [Indicator of
compromise](https://en.wikipedia.org/wiki/Indicator_of_compromise).

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->ip_addresses() >> / C<< $msg->ip_addresses($value) >>

Type: C<String>

The list of IP addresses that are associated with the finding.

=item * C<< $msg->domains() >> / C<< $msg->domains($value) >>

Type: C<String>

List of domains associated to the Finding.

=item * C<< $msg->signatures() >> / C<< $msg->signatures($value) >>

Type: C<Message> (L<Google::Cloud::Securitycenter::V2::Indicator::Indicator::ProcessSignature>)

The list of matched signatures indicating that the given
process is present in the environment.

=item * C<< $msg->uris() >> / C<< $msg->uris($value) >>

Type: C<String>

The list of URIs associated to the Findings.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Securitycenter::V2::Indicator::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
