package Google::Cloud::Securitycenter::V1::Chokepoint;

use strict;
use warnings;

our $VERSION = '0.14';

use Protobuf::Message;
use Protobuf::DescriptorPool;
use Protobuf::Internal qw(:all);
use MIME::Base64;

BEGIN {
    my $descriptor_b64 = <<'EOF';
Ci9nb29nbGUvY2xvdWQvc2VjdXJpdHljZW50ZXIvdjEvY2hva2Vwb2ludC5wcm90bxIeZ29v
Z2xlLmNsb3VkLnNlY3VyaXR5Y2VudGVyLnYxIjcKCkNob2tlcG9pbnQSKQoQcmVsYXRlZF9m
aW5kaW5ncxgBIAMoCVIPcmVsYXRlZEZpbmRpbmdzQukBCiJjb20uZ29vZ2xlLmNsb3VkLnNl
Y3VyaXR5Y2VudGVyLnYxQg9DaG9rZXBvaW50UHJvdG9QAVpKY2xvdWQuZ29vZ2xlLmNvbS9n
by9zZWN1cml0eWNlbnRlci9hcGl2MS9zZWN1cml0eWNlbnRlcnBiO3NlY3VyaXR5Y2VudGVy
cGKqAh5Hb29nbGUuQ2xvdWQuU2VjdXJpdHlDZW50ZXIuVjHKAh5Hb29nbGVcQ2xvdWRcU2Vj
dXJpdHlDZW50ZXJcVjHqAiFHb29nbGU6OkNsb3VkOjpTZWN1cml0eUNlbnRlcjo6VjFK8gkK
BhIEDgAiAQq8BAoBDBIDDgASMrEEIENvcHlyaWdodCAyMDI2IEdvb2dsZSBMTEMKCiBMaWNl
bnNlZCB1bmRlciB0aGUgQXBhY2hlIExpY2Vuc2UsIFZlcnNpb24gMi4wICh0aGUgIkxpY2Vu
c2UiKTsKIHlvdSBtYXkgbm90IHVzZSB0aGlzIGZpbGUgZXhjZXB0IGluIGNvbXBsaWFuY2Ug
d2l0aCB0aGUgTGljZW5zZS4KIFlvdSBtYXkgb2J0YWluIGEgY29weSBvZiB0aGUgTGljZW5z
ZSBhdAoKICAgICBodHRwOi8vd3d3LmFwYWNoZS5vcmcvbGljZW5zZXMvTElDRU5TRS0yLjAK
CiBVbmxlc3MgcmVxdWlyZWQgYnkgYXBwbGljYWJsZSBsYXcgb3IgYWdyZWVkIHRvIGluIHdy
aXRpbmcsIHNvZnR3YXJlCiBkaXN0cmlidXRlZCB1bmRlciB0aGUgTGljZW5zZSBpcyBkaXN0
cmlidXRlZCBvbiBhbiAiQVMgSVMiIEJBU0lTLAogV0lUSE9VVCBXQVJSQU5USUVTIE9SIENP
TkRJVElPTlMgT0YgQU5ZIEtJTkQsIGVpdGhlciBleHByZXNzIG9yIGltcGxpZWQuCiBTZWUg
dGhlIExpY2Vuc2UgZm9yIHRoZSBzcGVjaWZpYyBsYW5ndWFnZSBnb3Zlcm5pbmcgcGVybWlz
c2lvbnMgYW5kCiBsaW1pdGF0aW9ucyB1bmRlciB0aGUgTGljZW5zZS4KCggKAQISAxAAJwoI
CgEIEgMSADsKCQoCCCUSAxIAOwoICgEIEgMTAGEKCQoCCAsSAxMAYQoICgEIEgMUACIKCQoC
CAoSAxQAIgoICgEIEgMVADAKCQoCCAgSAxUAMAoICgEIEgMWADsKCQoCCAESAxYAOwoICgEI
EgMXADsKCQoCCCkSAxcAOwoICgEIEgMYADoKCQoCCC0SAxgAOgqMAgoCBAASBB0AIgEa/wEg
Q29udGFpbnMgZGV0YWlscyBhYm91dCBhIGNob2tlcG9pbnQsIHdoaWNoIGlzIGEgcmVzb3Vy
Y2Ugb3IgcmVzb3VyY2UgZ3JvdXAKIHdoZXJlIGhpZ2gtcmlzayBhdHRhY2sgcGF0aHMgY29u
dmVyZ2UsIGJhc2VkIG9uIFthdHRhY2sgcGF0aCBzaW11bGF0aW9uc10KIChodHRwczovL2Ns
b3VkLmdvb2dsZS5jb20vc2VjdXJpdHktY29tbWFuZC1jZW50ZXIvZG9jcy9hdHRhY2stZXhw
b3N1cmUtbGVhcm4jYXR0YWNrX3BhdGhfc2ltdWxhdGlvbnMpLgoKCgoDBAABEgMdCBIKuAEK
BAQAAgASAyECJxqqASBMaXN0IG9mIHJlc291cmNlIG5hbWVzIG9mIGZpbmRpbmdzIGFzc29j
aWF0ZWQgd2l0aCB0aGlzIGNob2tlcG9pbnQuCiBGb3IgZXhhbXBsZSwgb3JnYW5pemF0aW9u
cy8xMjMvc291cmNlcy80NTYvZmluZGluZ3MvNzg5LgogVGhpcyBsaXN0IHdpbGwgaGF2ZSBh
dCBtb3N0IDEwMCBmaW5kaW5ncy4KCgwKBQQAAgAEEgMhAgoKDAoFBAACAAUSAyELEQoMCgUE
AAIAARIDIRIiCgwKBQQAAgADEgMhJSZiBnByb3RvMw==
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Securitycenter::V1::Chokepoint::Chokepoint ===
    # Fields for Chokepoint
    # Field: related_findings Type: 9 ()

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Securitycenter::V1::Chokepoint - Compiled Protocol Buffers messages for google/cloud/securitycenter/v1/chokepoint.proto

=head1 SYNOPSIS

    use Google::Cloud::Securitycenter::V1::Chokepoint;

    my $msg = Google::Cloud::Securitycenter::V1::Chokepoint::Chokepoint->new({
        related_findings => $related_findings,
    });

    # Read or update a field
    my $val = $msg->related_findings();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Securitycenter::V1::Chokepoint::Chokepoint->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/securitycenter/v1/chokepoint.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Securitycenter::V1::Chokepoint::Chokepoint

Contains details about a chokepoint, which is a resource or resource group
where high-risk attack paths converge, based on [attack path simulations]
(https://cloud.google.com/security-command-center/docs/attack-exposure-learn#attack_path_simulations).

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->related_findings() >> / C<< $msg->related_findings($value) >>

Type: C<String>

List of resource names of findings associated with this chokepoint.
For example, organizations/123/sources/456/findings/789.
This list will have at most 100 findings.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Securitycenter::V1::Chokepoint::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
